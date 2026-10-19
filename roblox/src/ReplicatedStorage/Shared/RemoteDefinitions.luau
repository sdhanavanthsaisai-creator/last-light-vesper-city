--!strict
--[[
	RemoteDefinitions.luau
	Central registry of RemoteEvents and RemoteFunctions used between Server and Client.
	Location: ReplicatedStorage/Shared/RemoteDefinitions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = {
	Events = {
		-- Mission & Story Progression
		RequestStartMission = "RequestStartMission",
		RequestObjectiveAction = "RequestObjectiveAction",
		MissionStateUpdated = "MissionStateUpdated",

		-- Investigation & Clues
		RequestCollectClue = "RequestCollectClue",
		JournalUpdated = "JournalUpdated",

		-- Dialogue & Cutscenes
		RequestDialogueNPCTalk = "RequestDialogueNPCTalk",
		DialogueStarted = "DialogueStarted",
		TriggerCutscene = "TriggerCutscene",

		-- Vehicle System
		RequestSpawnVehicle = "RequestSpawnVehicle",
		VehicleNotification = "VehicleNotification",

		-- Stealth, Suspicion & Blackout Event
		GuardSuspicionUpdated = "GuardSuspicionUpdated",
		TriggerBlackoutEvent = "TriggerBlackoutEvent",
		SubmitFinalChoiceVote = "SubmitFinalChoiceVote",
		FinalChoiceResolved = "FinalChoiceResolved",

		-- Player Data Sync
		PlayerStateSynced = "PlayerStateSynced",
		SaveStatusNotification = "SaveStatusNotification",
	},
	Functions = {
		GetPlayerProfile = "GetPlayerProfile",
	},
}

function RemoteDefinitions.EnsureRemotesFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "Remotes"
		newFolder.Parent = ReplicatedStorage
		folder = newFolder
	end

	for _, eventName in pairs(RemoteDefinitions.Events) do
		if not (folder :: Folder):FindFirstChild(eventName) then
			local remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = eventName
			remoteEvent.Parent = folder
		end
	end

	for _, funcName in pairs(RemoteDefinitions.Functions) do
		if not (folder :: Folder):FindFirstChild(funcName) then
			local remoteFunc = Instance.new("RemoteFunction")
			remoteFunc.Name = funcName
			remoteFunc.Parent = folder
		end
	end

	return folder :: Folder
end

function RemoteDefinitions.GetEvent(name: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return folder:WaitForChild(name) :: RemoteEvent
end

function RemoteDefinitions.GetFunction(name: string): RemoteFunction
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return folder:WaitForChild(name) :: RemoteFunction
end

return table.freeze(RemoteDefinitions)
