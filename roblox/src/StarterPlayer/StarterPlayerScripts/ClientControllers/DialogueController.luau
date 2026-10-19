--!strict
--[[
	DialogueController.luau
	Client-side ScreenGui dialogue & cutscene typewriter controller with camera tweening
	and interactive player choice voting (including the 3 endings).
	Location: StarterPlayer/StarterPlayerScripts/ClientControllers/DialogueController
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

local DialogueController = {}
local localPlayer = Players.LocalPlayer
local isPlayingDialogue = false
local skipRequested = false

local dialogueFrame: Frame
local speakerLabel: TextLabel
local bodyLabel: TextLabel
local choicesContainer: Frame
local skipButton: TextButton

local function createDialogueGui()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("LastLightDialogueGui") :: ScreenGui?
	if not screenGui then
		local newGui = Instance.new("ScreenGui")
		newGui.Name = "LastLightDialogueGui"
		newGui.ResetOnSpawn = false
		newGui.IgnoreGuiInset = true
		newGui.Parent = playerGui
		screenGui = newGui
	end

	dialogueFrame = Instance.new("Frame")
	dialogueFrame.Name = "DialoguePanel"
	dialogueFrame.Size = UDim2.new(0.68, 0, 0, 165)
	dialogueFrame.Position = UDim2.new(0.16, 0, 1, -195)
	dialogueFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	dialogueFrame.BackgroundTransparency = 0.12
	dialogueFrame.BorderSizePixel = 0
	dialogueFrame.Visible = false
	dialogueFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = dialogueFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 165, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.35
	stroke.Parent = dialogueFrame

	speakerLabel = Instance.new("TextLabel")
	speakerLabel.Name = "SpeakerLabel"
	speakerLabel.Size = UDim2.new(1, -140, 0, 28)
	speakerLabel.Position = UDim2.new(0, 20, 0, 12)
	speakerLabel.BackgroundTransparency = 1
	speakerLabel.Font = Enum.Font.GothamBold
	speakerLabel.TextSize = 16
	speakerLabel.TextColor3 = Color3.fromRGB(95, 195, 255)
	speakerLabel.TextXAlignment = Enum.TextXAlignment.Left
	speakerLabel.Text = "MAYA CROSS"
	speakerLabel.Parent = dialogueFrame

	bodyLabel = Instance.new("TextLabel")
	bodyLabel.Name = "BodyLabel"
	bodyLabel.Size = UDim2.new(1, -40, 0, 68)
	bodyLabel.Position = UDim2.new(0, 20, 0, 42)
	bodyLabel.BackgroundTransparency = 1
	bodyLabel.Font = Enum.Font.Gotham
	bodyLabel.TextSize = 15
	bodyLabel.TextColor3 = Color3.fromRGB(235, 240, 250)
	bodyLabel.TextWrapped = true
	bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	bodyLabel.Text = ""
	bodyLabel.Parent = dialogueFrame

	skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.fromOffset(96, 28)
	skipButton.Position = UDim2.new(1, -112, 0, 12)
	skipButton.BackgroundColor3 = Color3.fromRGB(26, 34, 52)
	skipButton.Font = Enum.Font.GothamMedium
	skipButton.TextSize = 12
	skipButton.TextColor3 = Color3.fromRGB(185, 205, 235)
	skipButton.Text = "Skip [Space]"
	skipButton.Parent = dialogueFrame

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 6)
	skipCorner.Parent = skipButton

	skipButton.Activated:Connect(function()
		skipRequested = true
	end)

	choicesContainer = Instance.new("Frame")
	choicesContainer.Name = "ChoicesContainer"
	choicesContainer.Size = UDim2.new(1, -40, 0, 44)
	choicesContainer.Position = UDim2.new(0, 20, 1, -52)
	choicesContainer.BackgroundTransparency = 1
	choicesContainer.Parent = dialogueFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.Parent = choicesContainer
end

local function typewriteText(fullText: string, duration: number)
	skipRequested = false
	bodyLabel.Text = fullText
	bodyLabel.MaxVisibleGraphemes = 0

	local length = utf8.len(fullText) or #fullText
	local charDelay = math.clamp((duration * 0.55) / math.max(length, 1), 0.012, 0.04)

	for i = 1, length do
		if skipRequested then
			break
		end
		bodyLabel.MaxVisibleGraphemes = i
		task.wait(charDelay)
	end

	bodyLabel.MaxVisibleGraphemes = -1
	local remainingWait = math.max(0.8, duration * 0.45)
	local elapsed = 0
	while elapsed < remainingWait and not skipRequested do
		elapsed += task.wait(0.1)
	end
end

function DialogueController.PlaySequence(sequence: any, useScriptableCamera: boolean?)
	if isPlayingDialogue or not sequence or not sequence.lines then
		return
	end
	isPlayingDialogue = true
	dialogueFrame.Visible = true

	-- Clear old choice buttons
	for _, child in ipairs(choicesContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local camera = Workspace.CurrentCamera
	local originalCameraType = if camera then camera.CameraType else Enum.CameraType.Custom

	if useScriptableCamera and camera then
		camera.CameraType = Enum.CameraType.Scriptable
		local startCF = CFrame.new(Vector3.new(0, 26, 65), Vector3.new(0, 6, -40))
		local endCF = CFrame.new(Vector3.new(-12, 12, 32), Vector3.new(-25, 5, 0))
		camera.CFrame = startCF
		TweenService:Create(camera, TweenInfo.new(8.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			CFrame = endCF,
		}):Play()
	end

	for _, line in ipairs(sequence.lines) do
		local roleSuffix = if line.Role and #line.Role > 0 then "  •  " .. line.Role else ""
		speakerLabel.Text = tostring(line.Speaker) .. roleSuffix
		typewriteText(tostring(line.Text), tonumber(line.Duration) or 3.5)
	end

	if sequence.choices and #sequence.choices > 0 then
		local chosenEvent = Instance.new("BindableEvent")
		for _, choice in ipairs(sequence.choices) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1 / #sequence.choices, -8, 1, 0)
			btn.BackgroundColor3 = Color3.fromRGB(28, 48, 82)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 12
			btn.TextColor3 = Color3.fromRGB(240, 246, 255)
			btn.TextWrapped = true
			btn.Text = choice.label
			btn.Parent = choicesContainer

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = btn

			btn.Activated:Connect(function()
				if string.find(choice.id, "Ending_") then
					local voteEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.SubmitFinalChoiceVote)
					voteEvent:FireServer(choice.id)
				else
					local talkEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.RequestDialogueNPCTalk)
					talkEvent:FireServer("ChoiceCommit", choice.setsFlag)
				end
				chosenEvent:Fire(choice)
			end)
		end

		local selected = chosenEvent.Event:Wait()
		chosenEvent:Destroy()

		for _, child in ipairs(choicesContainer:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		if selected and selected.outcomeText then
			speakerLabel.Text = "DECISION RECORDED"
			typewriteText(selected.outcomeText, 3.2)
		end
	end

	if useScriptableCamera and camera then
		camera.CameraType = originalCameraType
	end

	dialogueFrame.Visible = false
	isPlayingDialogue = false
end

function DialogueController.Init()
	createDialogueGui()

	local dlgEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.DialogueStarted)
	dlgEvent.OnClientEvent:Connect(function(sequence: any)
		DialogueController.PlaySequence(sequence, false)
	end)

	local cutsceneEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.TriggerCutscene)
	cutsceneEvent.OnClientEvent:Connect(function(sequence: any)
		DialogueController.PlaySequence(sequence, true)
	end)

	local blackoutEvent = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.TriggerBlackoutEvent)
	blackoutEvent.OnClientEvent:Connect(function(payload: any)
		if payload and payload.dialogue then
			DialogueController.PlaySequence(payload.dialogue, false)
		end
	end)
end

return DialogueController
