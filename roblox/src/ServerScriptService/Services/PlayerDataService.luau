--!strict
--[[
	PlayerDataService.luau
	Server-authoritative persistence using DataStoreService with safe retries,
	in-memory Studio fallback, session locking basics, and honest failure reporting.
	Location: ServerScriptService/Services/PlayerDataService
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

export type PlayerProfile = {
	version: number,
	currency: number,
	currentDistrict: string,
	activeMissionId: string,
	missionObjectiveProgress: { [string]: number },
	completedMissions: { [string]: boolean },
	collectedClues: { [string]: boolean },
	storyFlags: { [string]: boolean },
	ownedCosmetics: { [string]: boolean },
	processedReceipts: { [string]: boolean },
	selectedVehicle: string,
	timesDetected: number,
	mercyScore: number,
}

local PlayerDataService = {}
local profiles: { [number]: PlayerProfile } = {}
local dataStore: DataStore? = nil

-- Initialize DataStore safely (handles unpublished Studio places gracefully)
local function getStore(): DataStore?
	if dataStore then
		return dataStore
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok and result then
		dataStore = result
		return dataStore
	end
	warn("[PlayerDataService] DataStore unavailable (Studio API access disabled or offline). Using session memory.")
	return nil
end

function PlayerDataService.CreateDefaultProfile(): PlayerProfile
	return {
		version = 1,
		currency = Config.STARTING_CURRENCY,
		currentDistrict = Config.DEFAULT_DISTRICT,
		activeMissionId = "M1_MissingRecords",
		missionObjectiveProgress = {
			inspect_notice = 0,
			talk_to_maya = 0,
			drive_to_archive = 0,
			collect_three_clues = 0,
			return_to_garage = 0,
		},
		completedMissions = {},
		collectedClues = {},
		storyFlags = {
			TrustedKade_Mission5 = true,
		},
		ownedCosmetics = {},
		processedReceipts = {},
		selectedVehicle = Config.DEFAULT_VEHICLE_ID,
		timesDetected = 0,
		mercyScore = 100,
	}
end

local function reconcileProfile(saved: any): PlayerProfile
	local defaultProfile = PlayerDataService.CreateDefaultProfile()
	if type(saved) ~= "table" then
		return defaultProfile
	end

	for key, defaultVal in pairs(defaultProfile :: any) do
		if saved[key] == nil then
			saved[key] = defaultVal
		elseif type(defaultVal) == "table" and type(saved[key]) == "table" then
			for subKey, subVal in pairs(defaultVal) do
				if saved[key][subKey] == nil then
					saved[key][subKey] = subVal
				end
			end
		end
	end

	return saved :: PlayerProfile
end

function PlayerDataService.LoadProfile(player: Player): (PlayerProfile, boolean)
	local store = getStore()
	local key = "Player_" .. tostring(player.UserId)

	if not store then
		local fallback = PlayerDataService.CreateDefaultProfile()
		profiles[player.UserId] = fallback
		return fallback, false
	end

	for attempt = 1, Config.MAX_SAVE_RETRIES do
		local ok, rawData = pcall(function()
			return store:GetAsync(key)
		end)
		if ok then
			local profile = reconcileProfile(rawData)
			profiles[player.UserId] = profile
			return profile, true
		else
			warn(string.format("[PlayerDataService] Load attempt %d failed for %s: %s", attempt, player.Name, tostring(rawData)))
			task.wait(1.2 * attempt)
		end
	end

	local emergencyProfile = PlayerDataService.CreateDefaultProfile()
	profiles[player.UserId] = emergencyProfile
	return emergencyProfile, false
end

function PlayerDataService.SaveProfile(player: Player): (boolean, string)
	local profile = profiles[player.UserId]
	if not profile then
		return false, "No profile loaded in memory"
	end

	local store = getStore()
	local notifyEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.SaveStatusNotification)

	if not store then
		if RunService:IsStudio() then
			notifyEvent:FireClient(player, {
				success = false,
				isStudioFallback = true,
				message = "Session saved in memory only (Enable Studio Access to API Services for cloud DataStore).",
			})
		end
		return false, "DataStore unavailable"
	end

	local key = "Player_" .. tostring(player.UserId)
	for attempt = 1, Config.MAX_SAVE_RETRIES do
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(_oldValue)
				return profile
			end)
		end)
		if ok then
			notifyEvent:FireClient(player, {
				success = true,
				isStudioFallback = false,
				message = "Progress saved to Vesper City Cloud.",
			})
			return true, "Saved"
		else
			warn(string.format("[PlayerDataService] Save attempt %d failed for %s: %s", attempt, player.Name, tostring(err)))
			task.wait(1.0 * attempt)
		end
	end

	notifyEvent:FireClient(player, {
		success = false,
		isStudioFallback = false,
		message = "Warning: Cloud save failed after retries. Progress kept in session memory.",
	})
	return false, "DataStore write failed after retries"
end

function PlayerDataService.GetProfile(player: Player): PlayerProfile?
	return profiles[player.UserId]
end

function PlayerDataService.SyncToClient(player: Player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	local syncEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.PlayerStateSynced)
	syncEvent:FireClient(player, profile)
end

function PlayerDataService.AddCurrency(player: Player, amount: number, reason: string): number
	assert(amount >= 0, "AddCurrency amount must be non-negative")
	local profile = profiles[player.UserId]
	if not profile then
		return 0
	end
	profile.currency += math.floor(amount)
	print(string.format("[Economy] +%d Vesper Credits to %s (%s). Total: %d", amount, player.Name, reason, profile.currency))
	PlayerDataService.SyncToClient(player)
	return profile.currency
end

function PlayerDataService.SetStoryFlag(player: Player, flag: string, value: boolean)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	profile.storyFlags[flag] = value
	PlayerDataService.SyncToClient(player)
end

function PlayerDataService.RecordDetection(player: Player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	profile.timesDetected += 1
	PlayerDataService.SyncToClient(player)
end

function PlayerDataService.Init()
	local getProfileFunc = RemoteDefinitions.GetFunction(RemoteDefinitions.Functions.GetPlayerProfile)
	getProfileFunc.OnServerInvoke = function(player: Player)
		return profiles[player.UserId]
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		PlayerDataService.SaveProfile(player)
		profiles[player.UserId] = nil
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				PlayerDataService.SaveProfile(player)
			end)
		end
		task.wait(2)
	end)

	-- Periodic autosave loop
	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_INTERVAL_SECONDS)
			for _, player in ipairs(Players:GetPlayers()) do
				PlayerDataService.SaveProfile(player)
			end
		end
	end)
end

return PlayerDataService
