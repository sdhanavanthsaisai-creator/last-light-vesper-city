--!strict
--[[
	Main.server.luau
	Primary server bootstrap for LAST LIGHT: The City That Forgot You & Operation BLACKOUT.
	Location: ServerScriptService/Main.server.luau
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DialogueDefinitions = require(Shared:WaitForChild("DialogueDefinitions"))
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

-- Ensure all RemoteEvents and RemoteFunctions exist before initializing services
RemoteDefinitions.EnsureRemotesFolder()

local Services = script.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local MissionService = require(Services:WaitForChild("MissionService"))
local VehicleService = require(Services:WaitForChild("VehicleService"))
local StealthGuardService = require(Services:WaitForChild("StealthGuardService"))
local PurchaseService = require(Services:WaitForChild("PurchaseService"))
local WorldBuilderService = require(Services:WaitForChild("WorldBuilderService"))

-- Initialize all core systems
WorldBuilderService.BuildVerticalSliceMap()
PlayerDataService.Init()
MissionService.Init()
VehicleService.Init()
StealthGuardService.Init()
PurchaseService.Init()

local function onPlayerAdded(player: Player)
	local profile, loadedFromCloud = PlayerDataService.LoadProfile(player)
	PurchaseService.CheckOwnedGamePasses(player)

	player.CharacterAdded:Connect(function(character: Model)
		character:SetAttribute("IsCrouching", false)
		character:SetAttribute("HasMaintenanceDisguise", false)
		character:SetAttribute("InRestrictedZone", false)

		task.wait(0.8)
		PlayerDataService.SyncToClient(player)
		MissionService.SendMissionState(player, "Welcome to Vesper City — " .. profile.currentDistrict)
	end)

	-- Spawn Noah's 1989 Vesper Coupe at the Old Quarter Garage
	task.delay(1.2, function()
		if player.Parent then
			VehicleService.SpawnPlayerVehicle(player)
			PlayerDataService.SyncToClient(player)
			MissionService.SendMissionState(
				player,
				if loadedFromCloud then "Loaded saved progress from Cloud" else "New Session — Old Quarter"
			)

			-- Trigger opening cutscene if player is on the very first objective
			if
				profile.activeMissionId == "M1_MissingRecords"
				and (profile.missionObjectiveProgress.inspect_notice or 0) == 0
			then
				local cutsceneEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.TriggerCutscene)
				cutsceneEvent:FireClient(player, DialogueDefinitions.Opening_ComingHome)
			end
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, existingPlayer)
end

print("[LAST LIGHT] Server initialized successfully.")
