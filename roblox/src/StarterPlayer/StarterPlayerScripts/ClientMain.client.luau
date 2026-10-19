--!strict
--[[
	ClientMain.client.luau
	Initializes client-side UI, Dialogue, Cutscenes, and Stealth input controllers.
	Location: StarterPlayer/StarterPlayerScripts/ClientMain.client.luau
]]

local Controllers = script.Parent:WaitForChild("ClientControllers")
local DialogueController = require(Controllers:WaitForChild("DialogueController"))
local MissionUIController = require(Controllers:WaitForChild("MissionUIController"))

DialogueController.Init()
MissionUIController.Init()

print("[LAST LIGHT] Client controllers initialized.")
