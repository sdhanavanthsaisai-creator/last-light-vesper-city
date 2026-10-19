--!strict
--[[
	StealthGuardService.luau
	Implements Syndicate Grid Guards for Operation BLACKOUT:
	- State Machine: Patrol -> Suspicious -> Chase -> Search -> KnockedOut (non-graphic Zzz effect)
	- Raycast light-cone detection (3s to full alert; crouching halves notice speed; disguise bypasses outside restricted zones)
	- BillboardGui Suspicion Meter above each guard's head
	Location: ServerScriptService/Services/StealthGuardService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

export type GuardState = "Patrol" | "Suspicious" | "Chase" | "Search" | "KnockedOut"

export type GuardController = {
	id: string,
	model: Model,
	rootPart: BasePart,
	state: GuardState,
	suspicion: number, -- 0 to 100
	waypoints: { Vector3 },
	currentWaypointIndex: number,
	meterFill: Frame,
	stateLabel: TextLabel,
}

local StealthGuardService = {}
local guards: { GuardController } = {}

local function createSuspicionBillboard(adornee: BasePart): (BillboardGui, Frame, TextLabel)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SuspicionBillboard"
	billboard.Adornee = adornee
	billboard.Size = UDim2.fromOffset(110, 36)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.AlwaysOnTop = true

	local bg = Instance.new("Frame")
	bg.Name = "BarBackground"
	bg.Size = UDim2.new(1, 0, 0, 10)
	bg.Position = UDim2.new(0, 0, 1, -12)
	bg.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = bg

	local fill = Instance.new("Frame")
	fill.Name = "MeterFill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 205, 60)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")
	label.Name = "StateLabel"
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(220, 230, 245)
	label.Text = "PATROL"
	label.Parent = billboard

	billboard.Parent = adornee
	return billboard, fill, label
end

function StealthGuardService.SpawnGuard(id: string, name: string, waypoints: { Vector3 }): GuardController
	local model = Instance.new("Model")
	model.Name = name

	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2.2, 4.8, 1.4)
	torso.Position = waypoints[1]
	torso.Anchored = true
	torso.Color = Color3.fromRGB(32, 40, 56)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = model
	model.PrimaryPart = torso

	-- Flashlight cone indicator
	local spotLight = Instance.new("SpotLight")
	spotLight.Name = "FlashlightCone"
	spotLight.Brightness = 3.5
	spotLight.Range = Config.STEALTH_LIGHT_CONE_RANGE
	spotLight.Angle = 55
	spotLight.Color = Color3.fromRGB(190, 230, 255)
	spotLight.Face = Enum.NormalId.Front
	spotLight.Parent = torso

	-- Non-graphic stun prompt (when sneaking behind guard)
	local stunPrompt = Instance.new("ProximityPrompt")
	stunPrompt.ActionText = "Stun Takedown (Non-Lethal)"
	stunPrompt.ObjectText = name
	stunPrompt.HoldDuration = 0.6
	stunPrompt.MaxActivationDistance = 7
	stunPrompt.Parent = torso

	local _, fill, stateLabel = createSuspicionBillboard(torso)

	local controller: GuardController = {
		id = id,
		model = model,
		rootPart = torso,
		state = "Patrol",
		suspicion = 0,
		waypoints = waypoints,
		currentWaypointIndex = 1,
		meterFill = fill,
		stateLabel = stateLabel,
	}

	stunPrompt.Triggered:Connect(function(_player: Player)
		if controller.state ~= "KnockedOut" then
			controller.state = "KnockedOut"
			controller.suspicion = 0
			controller.stateLabel.Text = "KNOCKED OUT (Zzz...)"
			controller.stateLabel.TextColor3 = Color3.fromRGB(130, 200, 255)
			controller.meterFill.Size = UDim2.new(0, 0, 1, 0)
			spotLight.Enabled = false
			stunPrompt.Enabled = false
		end
	end)

	model.Parent = Workspace
	table.insert(guards, controller)
	return controller
end

function StealthGuardService.Init()
	RunService.Heartbeat:Connect(function(dt: number)
		for _, guard in ipairs(guards) do
			if guard.state == "KnockedOut" or not guard.rootPart.Parent then
				continue
			end

			-- Move along patrol waypoints
			local targetWaypoint = guard.waypoints[guard.currentWaypointIndex]
			local toWaypoint = targetWaypoint - guard.rootPart.Position
			local flatOffset = Vector3.new(toWaypoint.X, 0, toWaypoint.Z)

			if flatOffset.Magnitude < 1.2 then
				guard.currentWaypointIndex = (guard.currentWaypointIndex % #guard.waypoints) + 1
			else
				local speed = if guard.state == "Chase" then 13 else 7.5
				local dir = flatOffset.Unit
				local nextPos = guard.rootPart.Position + dir * speed * dt
				guard.rootPart.CFrame = CFrame.lookAt(nextPos, nextPos + dir)
			end

			-- Check vision cone against players
			local detectedAnyPlayer = false
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if not hrp then
					continue
				end

				local offset = hrp.Position - guard.rootPart.Position
				local dist = offset.Magnitude
				if dist <= Config.STEALTH_LIGHT_CONE_RANGE then
					local forward = guard.rootPart.CFrame.LookVector
					local dot = forward:Dot(offset.Unit)
					-- Inside ~55 degree cone
					if dot >= 0.72 then
						detectedAnyPlayer = true
						local isCrouching = char:GetAttribute("IsCrouching") == true
						local hasDisguise = char:GetAttribute("HasMaintenanceDisguise") == true
						local inRestricted = char:GetAttribute("InRestrictedZone") == true

						if not (hasDisguise and not inRestricted) then
							local rate = (100 / Config.STEALTH_DETECTION_SECONDS)
							if isCrouching then
								rate *= Config.STEALTH_CROUCH_MULTIPLIER
							end
							guard.suspicion = math.clamp(guard.suspicion + rate * dt, 0, 100)

							if guard.suspicion >= 100 and guard.state ~= "Chase" then
								guard.state = "Chase"
								PlayerDataService.RecordDetection(player)
							elseif guard.suspicion >= 35 and guard.state == "Patrol" then
								guard.state = "Suspicious"
							end
						end
					end
				end
			end

			if not detectedAnyPlayer then
				guard.suspicion = math.clamp(guard.suspicion - 22 * dt, 0, 100)
				if guard.suspicion == 0 and guard.state ~= "Patrol" then
					guard.state = "Patrol"
				elseif guard.suspicion < 45 and guard.state == "Chase" then
					guard.state = "Search"
				end
			end

			-- Update Billboard UI
			local ratio = guard.suspicion / 100
			guard.meterFill.Size = UDim2.new(ratio, 0, 1, 0)
			if guard.state == "Chase" then
				guard.meterFill.BackgroundColor3 = Color3.fromRGB(255, 72, 72)
				guard.stateLabel.Text = "! ALERT: CHASE !"
			elseif guard.state == "Suspicious" or guard.state == "Search" then
				guard.meterFill.BackgroundColor3 = Color3.fromRGB(255, 195, 55)
				guard.stateLabel.Text = "? SUSPICIOUS (" .. math.floor(guard.suspicion) .. "%)"
			else
				guard.meterFill.BackgroundColor3 = Color3.fromRGB(80, 210, 150)
				guard.stateLabel.Text = "PATROL"
			end
		end
	end)
end

return StealthGuardService
