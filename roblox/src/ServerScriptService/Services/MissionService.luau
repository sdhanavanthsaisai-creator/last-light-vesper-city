--!strict
--[[
	MissionService.luau
	Server-validated mission progression, clue collection, objective verification,
	and Blackout ending vote resolution.
	Location: ServerScriptService/Services/MissionService
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DialogueDefinitions = require(Shared:WaitForChild("DialogueDefinitions"))
local ItemDefinitions = require(Shared:WaitForChild("ItemDefinitions"))
local MissionDefinitions = require(Shared:WaitForChild("MissionDefinitions"))
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local MissionService = {}
local finalChoiceVotes: { [number]: string } = {}

-- Validate distance between player character and a target world object if present
local function isPlayerNearTarget(player: Player, targetName: string, maxDist: number): boolean
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end

	local worldTarget = Workspace:FindFirstChild(targetName, true)
	if not worldTarget then
		-- Allow virtual progression if map part is being tested via prompt
		return true
	end

	local targetPos: Vector3? = nil
	if worldTarget:IsA("BasePart") then
		targetPos = worldTarget.Position
	elseif worldTarget:IsA("Model") then
		targetPos = worldTarget:GetPivot().Position
	end

	if targetPos then
		return (root.Position - targetPos).Magnitude <= maxDist
	end
	return true
end

function MissionService.GetActiveObjective(player: Player): (MissionDefinitions.MissionDef?, MissionDefinitions.ObjectiveDef?, number)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return nil, nil, 0
	end

	local missionDef = MissionDefinitions[profile.activeMissionId]
	if not missionDef then
		return nil, nil, 0
	end

	for index, obj in ipairs(missionDef.objectives) do
		local currentCount = profile.missionObjectiveProgress[obj.id] or 0
		if currentCount < obj.requiredCount then
			return missionDef, obj, index
		end
	end

	return missionDef, nil, #missionDef.objectives + 1
end

function MissionService.SendMissionState(player: Player, bannerText: string?)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return
	end
	local missionDef, activeObj, stepIndex = MissionService.GetActiveObjective(player)
	local event = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.MissionStateUpdated)
	event:FireClient(player, {
		activeMissionId = profile.activeMissionId,
		mission = missionDef,
		currentObjective = activeObj,
		stepIndex = stepIndex,
		progressTable = profile.missionObjectiveProgress,
		completedMissions = profile.completedMissions,
		bannerText = bannerText,
	})
end

function MissionService.AdvanceObjectiveByTarget(player: Player, targetId: string, amount: number?)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return false
	end

	local missionDef, activeObj = MissionService.GetActiveObjective(player)
	if not missionDef or not activeObj then
		return false
	end

	if activeObj.targetId ~= targetId then
		return false
	end

	local increment = amount or 1
	local current = profile.missionObjectiveProgress[activeObj.id] or 0
	local updated = math.clamp(current + increment, 0, activeObj.requiredCount)
	profile.missionObjectiveProgress[activeObj.id] = updated

	local _, nextObj = MissionService.GetActiveObjective(player)
	if not nextObj then
		-- Mission Complete!
		profile.completedMissions[missionDef.id] = true
		profile.storyFlags[missionDef.rewardFlag] = true
		PlayerDataService.AddCurrency(player, missionDef.rewardCurrency, "Completed " .. missionDef.title)

		-- Automatically unlock Operation BLACKOUT after completing Missing Records
		if missionDef.id == "M1_MissingRecords" then
			profile.activeMissionId = "M5_Blackout"
			profile.missionObjectiveProgress = {
				infiltrate_perimeter = 0,
				collect_power_keys = 0,
				trap_shade_lift = 0,
				pull_master_switch = 0,
				rooftop_choice = 0,
			}
			MissionService.SendMissionState(
				player,
				string.format("MISSION COMPLETE: %s (+$%d) — Next: Operation BLACKOUT", missionDef.title, missionDef.rewardCurrency)
			)
		else
			MissionService.SendMissionState(
				player,
				string.format("CAMPAIGN FINALE COMPLETE: %s (+$%d)", missionDef.title, missionDef.rewardCurrency)
			)
		end

		PlayerDataService.SaveProfile(player)
		PlayerDataService.SyncToClient(player)
		return true
	else
		MissionService.SendMissionState(player, "Objective Updated: " .. nextObj.title)
		PlayerDataService.SyncToClient(player)
		return true
	end
end

function MissionService.CollectClue(player: Player, clueId: string): boolean
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return false
	end

	local clueDef = (ItemDefinitions.Clues :: any)[clueId]
	if not clueDef then
		warn("[MissionService] Unknown clueId requested:", clueId)
		return false
	end

	if not isPlayerNearTarget(player, clueId, Config.INTERACTION_MAX_DISTANCE * 2.5) then
		warn("[MissionService] Player too far from clue:", clueId)
		return false
	end

	if profile.collectedClues[clueId] then
		return false
	end

	profile.collectedClues[clueId] = true
	PlayerDataService.AddCurrency(player, 25, "Discovered " .. clueDef.title)

	local journalEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.JournalUpdated)
	journalEvent:FireClient(player, {
		clue = clueDef,
		collectedClues = profile.collectedClues,
	})

	if clueId == "Clue_RedevelopmentNotice" then
		MissionService.AdvanceObjectiveByTarget(player, "Clue_RedevelopmentNotice", 1)
	elseif clueDef.category == "Clue" then
		MissionService.AdvanceObjectiveByTarget(player, "Clue_ArchiveEvidence", 1)
	elseif clueDef.category == "PowerKey" then
		MissionService.AdvanceObjectiveByTarget(player, "Item_PowerKey", 1)
	end

	PlayerDataService.SyncToClient(player)
	return true
end

-- Trigger the city-wide BLACKOUT event (from Silent Contract Script Notes)
function MissionService.ExecuteCityBlackout(triggeringPlayer: Player)
	MissionService.AdvanceObjectiveByTarget(triggeringPlayer, "Interact_MasterSwitch", 1)

	-- Tween Lighting to deep blue blackout state
	local targetPreset = Config.LIGHTING.BlackoutActive
	TweenService:Create(Lighting, TweenInfo.new(3.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Ambient = targetPreset.Ambient,
		OutdoorAmbient = targetPreset.OutdoorAmbient,
		Brightness = targetPreset.Brightness,
		FogColor = targetPreset.FogColor,
		FogEnd = targetPreset.FogEnd,
	}):Play()

	-- Loop through all Lights and Neon parts in Workspace and tween to dark, then warm window lights
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
			if desc.Name ~= "CandleWindowLight" then
				TweenService:Create(desc, TweenInfo.new(1.8), { Brightness = 0 }):Play()
			else
				task.delay(2.5, function()
					desc.Enabled = true
					TweenService:Create(desc, TweenInfo.new(2.0), {
						Brightness = 1.5,
						Color = Color3.fromRGB(255, 195, 120),
					}):Play()
				end)
			end
		elseif desc:IsA("BasePart") and desc.Material == Enum.Material.Neon then
			if desc:GetAttribute("IsCandleWindow") then
				task.delay(2.5, function()
					TweenService:Create(desc, TweenInfo.new(2.0), {
						Color = Color3.fromRGB(255, 198, 125),
					}):Play()
				end)
			else
				TweenService:Create(desc, TweenInfo.new(1.8), {
					Color = Color3.fromRGB(18, 22, 32),
				}):Play()
			end
		end
	end

	local blackoutEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.TriggerBlackoutEvent)
	blackoutEvent:FireAllClients({
		triggeredBy = triggeringPlayer.Name,
		dialogue = DialogueDefinitions.Blackout_MasterSwitchCutscene,
	})
end

-- Tally co-op or solo final choice votes; ties go to highest Mercy score
function MissionService.ResolveFinalChoiceVote(player: Player, choiceId: string)
	local validChoices = {
		Ending_ExposePublicly = true,
		Ending_TakeHisPlace = true,
		Ending_Disappear = true,
	}
	if not validChoices[choiceId] then
		return
	end

	finalChoiceVotes[player.UserId] = choiceId
	MissionService.AdvanceObjectiveByTarget(player, "Interact_FinalChoice", 1)

	-- Tally across active players
	local counts: { [string]: number } = {}
	local highestMercyForChoice: { [string]: number } = {}

	for _, activePlayer in ipairs(Players:GetPlayers()) do
		local vote = finalChoiceVotes[activePlayer.UserId] or choiceId
		counts[vote] = (counts[vote] or 0) + 1
		local prof = PlayerDataService.GetProfile(activePlayer)
		local mercy = if prof then prof.mercyScore else 50
		if not highestMercyForChoice[vote] or mercy > highestMercyForChoice[vote] then
			highestMercyForChoice[vote] = mercy
		end
	end

	local winningChoice = choiceId
	local bestVotes = -1
	local bestMercy = -1

	for option, total in pairs(counts) do
		local mercyTieBreaker = highestMercyForChoice[option] or 0
		if total > bestVotes or (total == bestVotes and mercyTieBreaker > bestMercy) then
			bestVotes = total
			bestMercy = mercyTieBreaker
			winningChoice = option
		end
	end

	local profile = PlayerDataService.GetProfile(player)
	local rating = "Silent Ghost"
	if profile then
		if profile.timesDetected == 0 then
			rating = "Silent Ghost"
		elseif profile.timesDetected <= 2 then
			rating = "Shadow Fox"
		else
			rating = "Loud Wolf"
		end
		PlayerDataService.SetStoryFlag(player, winningChoice, true)
		PlayerDataService.SaveProfile(player)
	end

	if winningChoice == "Ending_ExposePublicly" then
		local dawnPreset = Config.LIGHTING.DawnEnding
		TweenService:Create(Lighting, TweenInfo.new(4.0), {
			Ambient = dawnPreset.Ambient,
			OutdoorAmbient = dawnPreset.OutdoorAmbient,
			Brightness = dawnPreset.Brightness,
			ClockTime = dawnPreset.ClockTime,
			FogColor = dawnPreset.FogColor,
		}):Play()
	end

	local resolvedEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.FinalChoiceResolved)
	resolvedEvent:FireAllClients({
		winningChoice = winningChoice,
		rating = rating,
		timesDetected = if profile then profile.timesDetected else 0,
		mercyScore = if profile then profile.mercyScore else 100,
	})
end

function MissionService.Init()
	local collectClueEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestCollectClue)
	collectClueEvent.OnServerEvent:Connect(function(player: Player, clueId: unknown)
		if type(clueId) == "string" then
			MissionService.CollectClue(player, clueId)
		end
	end)

	local dialogueEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestDialogueNPCTalk)
	dialogueEvent.OnServerEvent:Connect(function(player: Player, npcId: unknown, choiceFlag: unknown)
		if type(npcId) ~= "string" then
			return
		end
		if type(choiceFlag) == "string" and #choiceFlag > 0 then
			PlayerDataService.SetStoryFlag(player, choiceFlag, true)
		end
		if npcId == "NPC_MayaCross" then
			MissionService.AdvanceObjectiveByTarget(player, "NPC_MayaCross", 1)
			local startDlg = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.DialogueStarted)
			startDlg:FireClient(player, DialogueDefinitions.NPC_MayaCross_Intro)
		elseif npcId == "NPC_MarcusHale" then
			local startDlg = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.DialogueStarted)
			startDlg:FireClient(player, DialogueDefinitions.Blackout_RooftopConfrontation)
		end
	end)

	local actionEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestObjectiveAction)
	actionEvent.OnServerEvent:Connect(function(player: Player, actionId: unknown)
		if type(actionId) ~= "string" then
			return
		end
		if actionId == "Interact_MasterSwitch" then
			MissionService.ExecuteCityBlackout(player)
		else
			MissionService.AdvanceObjectiveByTarget(player, actionId, 1)
		end
	end)

	local startMissionEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestStartMission)
	startMissionEvent.OnServerEvent:Connect(function(player: Player, missionId: unknown)
		if type(missionId) ~= "string" then
			return
		end
		local profile = PlayerDataService.GetProfile(player)
		if not profile or not MissionDefinitions[missionId] then
			return
		end
		profile.activeMissionId = missionId
		profile.missionObjectiveProgress = {}
		MissionService.SendMissionState(player, "Mission Started: " .. MissionDefinitions[missionId].title)
	end)

	local voteEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.SubmitFinalChoiceVote)
	voteEvent.OnServerEvent:Connect(function(player: Player, choiceId: unknown)
		if type(choiceId) == "string" then
			MissionService.ResolveFinalChoiceVote(player, choiceId)
		end
	end)
end

return MissionService
