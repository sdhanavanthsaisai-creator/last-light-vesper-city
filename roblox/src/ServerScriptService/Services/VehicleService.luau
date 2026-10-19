--!strict
--[[
	VehicleService.luau
	Spawns and manages the player's 1989 Vesper Coupe GT at the Old Quarter Garage,
	with working headlights, VehicleSeat driving loop, and zone checkpoint detection.
	Location: ServerScriptService/Services/VehicleService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemDefinitions = require(Shared:WaitForChild("ItemDefinitions"))
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

local MissionService = require(script.Parent:WaitForChild("MissionService"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local VehicleService = {}
local spawnedVehicles: { [number]: Model } = {}

local function buildVesperCoupeModel(owner: Player, spawnCFrame: CFrame): Model
	local vehicleSpec = ItemDefinitions.Vehicles.vesper_coupe_89
	local model = Instance.new("Model")
	model.Name = owner.Name .. "_VesperCoupe"

	-- Primary chassis
	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(7, 2.2, 14)
	chassis.CFrame = spawnCFrame
	chassis.Color = vehicleSpec.bodyColor
	chassis.Material = Enum.Material.Metal
	chassis.TopSurface = Enum.SurfaceType.Smooth
	chassis.BottomSurface = Enum.SurfaceType.Smooth
	chassis.Parent = model
	model.PrimaryPart = chassis

	-- Cabin roof
	local cabin = Instance.new("Part")
	cabin.Name = "Cabin"
	cabin.Size = Vector3.new(6.2, 1.8, 6.5)
	cabin.CFrame = spawnCFrame * CFrame.new(0, 1.8, -0.5)
	cabin.Color = Color3.fromRGB(20, 26, 36)
	cabin.Material = Enum.Material.Glass
	cabin.Transparency = 0.25
	cabin.CanCollide = false
	cabin.Parent = model

	local cabinWeld = Instance.new("WeldConstraint")
	cabinWeld.Part0 = chassis
	cabinWeld.Part1 = cabin
	cabinWeld.Parent = chassis

	-- Headlights (Neon + SpotLight)
	for _, xOffset in ipairs({ -2.4, 2.4 }) do
		local lamp = Instance.new("Part")
		lamp.Name = "Headlight"
		lamp.Size = Vector3.new(1.1, 0.6, 0.2)
		lamp.CFrame = spawnCFrame * CFrame.new(xOffset, 0.2, -7.05)
		lamp.Material = Enum.Material.Neon
		lamp.Color = Color3.fromRGB(255, 234, 185)
		lamp.CanCollide = false
		lamp.Parent = model

		local spot = Instance.new("SpotLight")
		spot.Name = "HeadlightBeam"
		spot.Brightness = 3
		spot.Range = 48
		spot.Angle = 60
		spot.Face = Enum.NormalId.Front
		spot.Color = Color3.fromRGB(255, 238, 200)
		spot.Parent = lamp

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = chassis
		weld.Part1 = lamp
		weld.Parent = chassis
	end

	-- Driver VehicleSeat
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2.2, 0.8, 2.2)
	seat.CFrame = spawnCFrame * CFrame.new(-1.5, 0.8, -0.5)
	seat.MaxSpeed = vehicleSpec.maxSpeed
	seat.Torque = vehicleSpec.acceleration
	seat.TurnSpeed = vehicleSpec.turnSpeed
	seat.Parent = model

	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = chassis
	seatWeld.Part1 = seat
	seatWeld.Parent = chassis

	-- ProximityPrompt for easy entering
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Drive 1989 Vesper Coupe"
	prompt.ObjectText = "Noah's Vehicle"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.2
	prompt.Parent = seat

	prompt.Triggered:Connect(function(triggerPlayer: Player)
		local char = triggerPlayer.Character
		local humanoid = if char then char:FindFirstChildOfClass("Humanoid") else nil
		if humanoid and not seat.Occupant then
			seat:Sit(humanoid)
		end
	end)

	-- Physics forces for smooth arcade-realistic driving on flat roads
	local attachment = Instance.new("Attachment")
	attachment.Parent = chassis

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 45000
	linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	linearVelocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	linearVelocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	linearVelocity.PlaneVelocity = Vector2.zero
	linearVelocity.Enabled = false
	linearVelocity.Parent = chassis

	local angularVelocity = Instance.new("AngularVelocity")
	angularVelocity.Attachment0 = attachment
	angularVelocity.MaxTorque = 35000
	angularVelocity.AngularVelocity = Vector3.zero
	angularVelocity.Enabled = false
	angularVelocity.Parent = chassis

	local currentSpeed = 0

	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local isOccupied = seat.Occupant ~= nil
		linearVelocity.Enabled = isOccupied
		angularVelocity.Enabled = isOccupied
		prompt.Enabled = not isOccupied
		if not isOccupied then
			currentSpeed = 0
			linearVelocity.PlaneVelocity = Vector2.zero
			angularVelocity.AngularVelocity = Vector3.zero
		end
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		if not model.Parent or not seat.Occupant then
			return
		end

		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat

		if math.abs(throttle) > 0.05 then
			currentSpeed = math.clamp(
				currentSpeed + throttle * vehicleSpec.acceleration * dt * 2.2,
				-vehicleSpec.maxSpeed * 0.45,
				vehicleSpec.maxSpeed
			)
		else
			currentSpeed = currentSpeed * math.max(0, 1 - dt * 3.5)
		end

		local look = chassis.CFrame.LookVector
		local forwardVelocity = look * currentSpeed
		linearVelocity.PlaneVelocity = Vector2.new(forwardVelocity.X, forwardVelocity.Z)

		if math.abs(currentSpeed) > 1.5 then
			local steerDir = if currentSpeed >= 0 then -steer else steer
			angularVelocity.AngularVelocity = Vector3.new(0, steerDir * vehicleSpec.turnSpeed, 0)
		else
			angularVelocity.AngularVelocity = Vector3.zero
		end
	end)

	return model
end

function VehicleService.SpawnPlayerVehicle(player: Player, customCFrame: CFrame?): Model
	if spawnedVehicles[player.UserId] then
		spawnedVehicles[player.UserId]:Destroy()
		spawnedVehicles[player.UserId] = nil
	end

	local spawnLocation = Workspace:FindFirstChild("GarageVehicleSpawn", true) :: BasePart?
	local targetCFrame = customCFrame or (if spawnLocation then spawnLocation.CFrame + Vector3.new(0, 3, 0) else CFrame.new(0, 4, 28))

	local vehicle = buildVesperCoupeModel(player, targetCFrame)
	vehicle.Parent = Workspace
	spawnedVehicles[player.UserId] = vehicle

	local notify = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.VehicleNotification)
	notify:FireClient(player, {
		message = "1989 Vesper Coupe ready at Old Quarter Garage.",
		vehicleName = vehicle.Name,
	})

	return vehicle
end

function VehicleService.Init()
	local spawnEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestSpawnVehicle)
	spawnEvent.OnServerEvent:Connect(function(player: Player)
		local profile = PlayerDataService.GetProfile(player)
		if not profile then
			return
		end
		VehicleService.SpawnPlayerVehicle(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		if spawnedVehicles[player.UserId] then
			spawnedVehicles[player.UserId]:Destroy()
			spawnedVehicles[player.UserId] = nil
		end
	end)

	-- Monitor Archive Relay & Garage checkpoint zones for driving objectives
	RunService.Heartbeat:Connect(function()
		local archiveZone = Workspace:FindFirstChild("Zone_ArchiveRelay", true) :: BasePart?
		local garageZone = Workspace:FindFirstChild("Zone_NoahGarage", true) :: BasePart?

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if root then
				if archiveZone and (root.Position - archiveZone.Position).Magnitude <= 22 then
					MissionService.AdvanceObjectiveByTarget(player, "Zone_ArchiveRelay", 1)
				end
				if garageZone and (root.Position - garageZone.Position).Magnitude <= 18 then
					MissionService.AdvanceObjectiveByTarget(player, "Zone_NoahGarage", 1)
				end
			end
		end
	end)
end

return VehicleService
