--!strict
--[[
	MissionUIController.luau
	Displays the Mission Tracker HUD, Vesper Credits balance, Investigation Journal,
	Quick Action Controls (Crouch, Disguise, Spawn Car), and Ending Results Screen.
	Location: StarterPlayer/StarterPlayerScripts/ClientControllers/MissionUIController
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

local MissionUIController = {}
local localPlayer = Players.LocalPlayer

local missionTitleLabel: TextLabel
local objectiveTextLabel: TextLabel
local locationHintLabel: TextLabel
local currencyLabel: TextLabel
local bannerLabel: TextLabel
local journalFrame: Frame
local journalListLabel: TextLabel
local endingModal: Frame
local endingDetailsLabel: TextLabel

local discoveredClueTitles: { string } = {}
local isCrouching = false
local hasDisguise = false

local function createHUD()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LastLightHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Top-Right Mission Tracker Card
	local trackerCard = Instance.new("Frame")
	trackerCard.Name = "MissionTrackerCard"
	trackerCard.Size = UDim2.fromOffset(330, 130)
	trackerCard.Position = UDim2.new(1, -348, 0, 18)
	trackerCard.BackgroundColor3 = Color3.fromRGB(11, 15, 25)
	trackerCard.BackgroundTransparency = 0.14
	trackerCard.BorderSizePixel = 0
	trackerCard.Parent = screenGui

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = trackerCard

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(64, 156, 255)
	cardStroke.Thickness = 1.2
	cardStroke.Transparency = 0.4
	cardStroke.Parent = trackerCard

	missionTitleLabel = Instance.new("TextLabel")
	missionTitleLabel.Size = UDim2.new(1, -24, 0, 24)
	missionTitleLabel.Position = UDim2.fromOffset(12, 10)
	missionTitleLabel.BackgroundTransparency = 1
	missionTitleLabel.Font = Enum.Font.GothamBold
	missionTitleLabel.TextSize = 14
	missionTitleLabel.TextColor3 = Color3.fromRGB(90, 195, 255)
	missionTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	missionTitleLabel.Text = "MISSION: Missing Records"
	missionTitleLabel.Parent = trackerCard

	objectiveTextLabel = Instance.new("TextLabel")
	objectiveTextLabel.Size = UDim2.new(1, -24, 0, 52)
	objectiveTextLabel.Position = UDim2.fromOffset(12, 36)
	objectiveTextLabel.BackgroundTransparency = 1
	missionTitleLabel.Name = "MissionTitle"
	objectiveTextLabel.Font = Enum.Font.GothamMedium
	objectiveTextLabel.TextSize = 13
	objectiveTextLabel.TextColor3 = Color3.fromRGB(235, 242, 252)
	objectiveTextLabel.TextWrapped = true
	objectiveTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	objectiveTextLabel.TextYAlignment = Enum.TextYAlignment.Top
	objectiveTextLabel.Text = "Loading objective..."
	objectiveTextLabel.Parent = trackerCard

	locationHintLabel = Instance.new("TextLabel")
	locationHintLabel.Size = UDim2.new(1, -24, 0, 20)
	locationHintLabel.Position = UDim2.fromOffset(12, 96)
	locationHintLabel.BackgroundTransparency = 1
	locationHintLabel.Font = Enum.Font.Gotham
	locationHintLabel.TextSize = 12
	locationHintLabel.TextColor3 = Color3.fromRGB(160, 180, 210)
	locationHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	locationHintLabel.Text = "Location: Old Quarter"
	locationHintLabel.Parent = trackerCard

	-- Top-Left Status & Quick Controls Bar
	local statusCard = Instance.new("Frame")
	statusCard.Name = "PlayerStatusCard"
	statusCard.Size = UDim2.fromOffset(290, 92)
	statusCard.Position = UDim2.fromOffset(18, 18)
	statusCard.BackgroundColor3 = Color3.fromRGB(11, 15, 25)
	statusCard.BackgroundTransparency = 0.14
	statusCard.BorderSizePixel = 0
	statusCard.Parent = screenGui

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 10)
	statusCorner.Parent = statusCard

	currencyLabel = Instance.new("TextLabel")
	currencyLabel.Size = UDim2.new(1, -24, 0, 24)
	currencyLabel.Position = UDim2.fromOffset(12, 10)
	currencyLabel.BackgroundTransparency = 1
	currencyLabel.Font = Enum.Font.GothamBold
	currencyLabel.TextSize = 14
	currencyLabel.TextColor3 = Color3.fromRGB(110, 235, 165)
	currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
	currencyLabel.Text = "VESPER CREDITS: $250"
	currencyLabel.Parent = statusCard

	local spawnCarBtn = Instance.new("TextButton")
	spawnCarBtn.Size = UDim2.fromOffset(125, 32)
	spawnCarBtn.Position = UDim2.fromOffset(12, 44)
	spawnCarBtn.BackgroundColor3 = Color3.fromRGB(32, 68, 118)
	spawnCarBtn.Font = Enum.Font.GothamBold
	spawnCarBtn.TextSize = 12
	spawnCarBtn.TextColor3 = Color3.fromRGB(240, 248, 255)
	spawnCarBtn.Text = "Spawn Coupe [V]"
	spawnCarBtn.Parent = statusCard

	local carBtnCorner = Instance.new("UICorner")
	carBtnCorner.CornerRadius = UDim.new(0, 6)
	carBtnCorner.Parent = spawnCarBtn

	spawnCarBtn.Activated:Connect(function()
		RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestSpawnVehicle):FireServer()
	end)

	local journalBtn = Instance.new("TextButton")
	journalBtn.Size = UDim2.fromOffset(125, 32)
	journalBtn.Position = UDim2.fromOffset(148, 44)
	journalBtn.BackgroundColor3 = Color3.fromRGB(36, 46, 68)
	journalBtn.Font = Enum.Font.GothamBold
	journalBtn.TextSize = 12
	journalBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
	journalBtn.Text = "Journal [J]"
	journalBtn.Parent = statusCard

	local jBtnCorner = Instance.new("UICorner")
	jBtnCorner.CornerRadius = UDim.new(0, 6)
	jBtnCorner.Parent = journalBtn

	-- Investigation Journal Drawer
	journalFrame = Instance.new("Frame")
	journalFrame.Name = "JournalDrawer"
	journalFrame.Size = UDim2.fromOffset(340, 220)
	journalFrame.Position = UDim2.fromOffset(18, 120)
	journalFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
	journalFrame.BackgroundTransparency = 0.08
	journalFrame.Visible = false
	journalFrame.Parent = screenGui

	local jCorner = Instance.new("UICorner")
	jCorner.CornerRadius = UDim.new(0, 10)
	jCorner.Parent = journalFrame

	journalListLabel = Instance.new("TextLabel")
	journalListLabel.Size = UDim2.new(1, -24, 1, -24)
	journalListLabel.Position = UDim2.fromOffset(12, 12)
	journalListLabel.BackgroundTransparency = 1
	journalListLabel.Font = Enum.Font.Gotham
	journalListLabel.TextSize = 13
	journalListLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
	journalListLabel.TextWrapped = true
	journalListLabel.TextXAlignment = Enum.TextXAlignment.Left
	journalListLabel.TextYAlignment = Enum.TextYAlignment.Top
	journalListLabel.Text = "INVESTIGATION JOURNAL\n\nNo clues collected yet. Inspect Noah's apartment notice to begin."
	journalListLabel.Parent = journalFrame

	journalBtn.Activated:Connect(function()
		journalFrame.Visible = not journalFrame.Visible
	end)

	-- Center Notification Banner
	bannerLabel = Instance.new("TextLabel")
	bannerLabel.Size = UDim2.fromOffset(480, 36)
	bannerLabel.Position = UDim2.new(0.5, -240, 0, 22)
	bannerLabel.BackgroundColor3 = Color3.fromRGB(16, 24, 42)
	bannerLabel.BackgroundTransparency = 0.2
	bannerLabel.Font = Enum.Font.GothamBold
	bannerLabel.TextSize = 14
	bannerLabel.TextColor3 = Color3.fromRGB(255, 215, 110)
	bannerLabel.Visible = false
	bannerLabel.Parent = screenGui

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = bannerLabel

	-- Final Mission Results Modal
	endingModal = Instance.new("Frame")
	endingModal.Size = UDim2.fromOffset(420, 230)
	endingModal.Position = UDim2.new(0.5, -210, 0.5, -115)
	endingModal.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	endingModal.Visible = false
	endingModal.Parent = screenGui

	local eCorner = Instance.new("UICorner")
	eCorner.CornerRadius = UDim.new(0, 12)
	eCorner.Parent = endingModal

	endingDetailsLabel = Instance.new("TextLabel")
	endingDetailsLabel.Size = UDim2.new(1, -32, 1, -32)
	endingDetailsLabel.Position = UDim2.fromOffset(16, 16)
	endingDetailsLabel.BackgroundTransparency = 1
	endingDetailsLabel.Font = Enum.Font.GothamBold
	endingDetailsLabel.TextSize = 15
	endingDetailsLabel.TextColor3 = Color3.fromRGB(235, 242, 255)
	endingDetailsLabel.TextWrapped = true
	endingDetailsLabel.Parent = endingModal
end

local function showBanner(text: string)
	bannerLabel.Text = text
	bannerLabel.Visible = true
	task.delay(4.0, function()
		if bannerLabel.Text == text then
			bannerLabel.Visible = false
		end
	end)
end

function MissionUIController.Init()
	createHUD()

	-- Keyboard shortcuts: C to Crouch (stealth), J for Journal, V to Spawn Car
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.J then
			journalFrame.Visible = not journalFrame.Visible
		elseif input.KeyCode == Enum.KeyCode.V then
			RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestSpawnVehicle):FireServer()
		elseif input.KeyCode == Enum.KeyCode.C then
			isCrouching = not isCrouching
			local char = localPlayer.Character
			if char then
				char:SetAttribute("IsCrouching", isCrouching)
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = if isCrouching then 10 else 16
				end
			end
			showBanner(if isCrouching then "Stealth Mode: Crouching (50% lower guard detection)" else "Standing Mode")
		elseif input.KeyCode == Enum.KeyCode.G then
			hasDisguise = not hasDisguise
			local char = localPlayer.Character
			if char then
				char:SetAttribute("HasMaintenanceDisguise", hasDisguise)
			end
			showBanner(if hasDisguise then "Equipped Maintenance Worker Disguise" else "Removed Disguise")
		end
	end)

	RemoteDefinitions.GetEvent(RemoteDefinitions.Events.MissionStateUpdated).OnClientEvent:Connect(function(data: any)
		if data.mission then
			missionTitleLabel.Text = "MISSION: " .. tostring(data.mission.title)
		end
		if data.currentObjective then
			local progress = (data.progressTable and data.progressTable[data.currentObjective.id]) or 0
			objectiveTextLabel.Text = string.format(
				"%s (%d/%d)\n%s",
				data.currentObjective.title,
				progress,
				data.currentObjective.requiredCount,
				data.currentObjective.description
			)
			locationHintLabel.Text = "Location: " .. tostring(data.currentObjective.locationHint)
		else
			objectiveTextLabel.Text = "All objectives completed!"
			locationHintLabel.Text = "Status: Complete"
		end

		if data.bannerText then
			showBanner(tostring(data.bannerText))
		end
	end)

	RemoteDefinitions.GetEvent(RemoteDefinitions.Events.PlayerStateSynced).OnClientEvent:Connect(function(profile: any)
		if profile and profile.currency then
			currencyLabel.Text = "VESPER CREDITS: $" .. tostring(profile.currency)
		end
	end)

	RemoteDefinitions.GetEvent(RemoteDefinitions.Events.JournalUpdated).OnClientEvent:Connect(function(payload: any)
		if payload and payload.clue then
			table.insert(discoveredClueTitles, "• " .. payload.clue.title .. ": " .. payload.clue.journalEntry)
			journalListLabel.Text = "INVESTIGATION JOURNAL\n\n" .. table.concat(discoveredClueTitles, "\n\n")
			showBanner("Clue Logged: " .. payload.clue.title)
		end
	end)

	RemoteDefinitions.GetEvent(RemoteDefinitions.Events.SaveStatusNotification).OnClientEvent:Connect(function(status: any)
		if status and status.message then
			showBanner(tostring(status.message))
		end
	end)

	RemoteDefinitions.GetEvent(RemoteDefinitions.Events.FinalChoiceResolved).OnClientEvent:Connect(function(result: any)
		endingModal.Visible = true
		endingDetailsLabel.Text = string.format(
			"FINAL MISSION COMPLETE — BLACKOUT\n\nChosen Ending: %s\nStealth Rating: %s\nTimes Detected: %d\nMercy Score: %d\n\n'The best agent isn't the one who wins the fight. It's the one who's never seen.'",
			tostring(result.winningChoice),
			tostring(result.rating),
			tonumber(result.timesDetected) or 0,
			tonumber(result.mercyScore) or 100
		)
	end)
end

return MissionUIController
