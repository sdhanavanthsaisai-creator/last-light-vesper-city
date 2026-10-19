--!strict
--[[
	WorldBuilderService.luau
	Procedurally builds the Milestone 1 Old Quarter Street, Noah's Garage, Apartment Entrance,
	Municipal Archive Relay, Maya Cross NPC, Clues, and the Neon Harbor Power Grid slice
	directly in Workspace if not already authored in Roblox Studio.
	Location: ServerScriptService/Services/WorldBuilderService
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ItemDefinitions = require(Shared:WaitForChild("ItemDefinitions"))
local RemoteDefinitions = require(Shared:WaitForChild("RemoteDefinitions"))

local MissionService = require(script.Parent:WaitForChild("MissionService"))
local StealthGuardService = require(script.Parent:WaitForChild("StealthGuardService"))

local WorldBuilderService = {}

local function makePart(props: {
	Name: string,
	Size: Vector3,
	Position: Vector3,
	Color: Color3,
	Material: Enum.Material?,
	Parent: Instance,
	Anchored: boolean?,
	CanCollide: boolean?,
	Transparency: number?,
}): Part
	local part = Instance.new("Part")
	part.Name = props.Name
	part.Size = props.Size
	part.Position = props.Position
	part.Color = props.Color
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Anchored = if props.Anchored ~= nil then props.Anchored else true
	part.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	part.Transparency = props.Transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.Parent
	return part
end

local function attachCluePrompt(part: BasePart, clueId: string)
	local clueDef = (ItemDefinitions.Clues :: any)[clueId]
	if not clueDef then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Inspect / Collect"
	prompt.ObjectText = clueDef.title
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.Parent = part

	prompt.Triggered:Connect(function(player: Player)
		MissionService.CollectClue(player, clueId)
	end)
end

function WorldBuilderService.ApplyCinematicLighting()
	local preset = Config.LIGHTING.NormalNight
	Lighting.Ambient = preset.Ambient
	Lighting.OutdoorAmbient = preset.OutdoorAmbient
	Lighting.Brightness = preset.Brightness
	Lighting.ClockTime = preset.ClockTime
	Lighting.FogEnd = preset.FogEnd
	Lighting.FogColor = preset.FogColor
end

function WorldBuilderService.BuildVerticalSliceMap()
	if Workspace:FindFirstChild("LastLightWorld") then
		return
	end

	WorldBuilderService.ApplyCinematicLighting()

	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "LastLightWorld"
	worldFolder.Parent = Workspace

	-- 1. Main Street & Sidewalks (Old Quarter -> Municipal Archive -> Neon Harbor Grid)
	makePart({
		Name = "OldQuarter_AsphaltRoad",
		Size = Vector3.new(36, 1, 340),
		Position = Vector3.new(0, -0.5, -90),
		Color = Color3.fromRGB(28, 30, 36),
		Material = Enum.Material.Asphalt,
		Parent = worldFolder,
	})

	makePart({
		Name = "Sidewalk_West",
		Size = Vector3.new(14, 1.4, 340),
		Position = Vector3.new(-25, -0.3, -90),
		Color = Color3.fromRGB(64, 68, 76),
		Material = Enum.Material.Concrete,
		Parent = worldFolder,
	})

	makePart({
		Name = "Sidewalk_East",
		Size = Vector3.new(14, 1.4, 340),
		Position = Vector3.new(25, -0.3, -90),
		Color = Color3.fromRGB(64, 68, 76),
		Material = Enum.Material.Concrete,
		Parent = worldFolder,
	})

	-- 2. Noah's Apartment Building & Entrance (West Side)
	makePart({
		Name = "NoahApartment_Building",
		Size = Vector3.new(26, 38, 34),
		Position = Vector3.new(-45, 19, 25),
		Color = Color3.fromRGB(48, 42, 46),
		Material = Enum.Material.Brick,
		Parent = worldFolder,
	})

	-- Warm candle-ready window parts for Blackout Cutscene
	for row = 1, 3 do
		local win = makePart({
			Name = "ApartmentWindow_" .. tostring(row),
			Size = Vector3.new(0.4, 4, 6),
			Position = Vector3.new(-31.8, 8 + row * 8, 25),
			Color = Color3.fromRGB(85, 120, 165),
			Material = Enum.Material.Neon,
			Parent = worldFolder,
		})
		win:SetAttribute("IsCandleWindow", true)
	end

	-- Clue 0: Redevelopment Notice on Noah's Apartment Door
	local noticeBoard = makePart({
		Name = "Clue_RedevelopmentNotice",
		Size = Vector3.new(0.5, 3.2, 2.4),
		Position = Vector3.new(-31.6, 4.5, 18),
		Color = Color3.fromRGB(255, 196, 85),
		Material = Enum.Material.Neon,
		Parent = worldFolder,
	})
	attachCluePrompt(noticeBoard, "Clue_RedevelopmentNotice")

	-- 3. Noah's Garage (East Side) + Vehicle Spawn + Checkpoint
	makePart({
		Name = "NoahGarage_Structure",
		Size = Vector3.new(28, 16, 32),
		Position = Vector3.new(46, 8, 24),
		Color = Color3.fromRGB(38, 44, 54),
		Material = Enum.Material.Concrete,
		Parent = worldFolder,
	})

	makePart({
		Name = "GarageVehicleSpawn",
		Size = Vector3.new(10, 0.4, 16),
		Position = Vector3.new(10, 0.2, 24),
		Color = Color3.fromRGB(55, 140, 220),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.65,
		Parent = worldFolder,
	})

	makePart({
		Name = "Zone_NoahGarage",
		Size = Vector3.new(18, 8, 18),
		Position = Vector3.new(28, 4, 24),
		Color = Color3.fromRGB(60, 220, 140),
		Material = Enum.Material.ForceField,
		CanCollide = false,
		Transparency = 0.75,
		Parent = worldFolder,
	})

	-- 4. Maya Cross Interactive NPC
	local mayaPart = makePart({
		Name = "NPC_MayaCross",
		Size = Vector3.new(2.4, 5.2, 1.6),
		Position = Vector3.new(-21, 3.0, -5),
		Color = Color3.fromRGB(70, 165, 235),
		Material = Enum.Material.SmoothPlastic,
		Parent = worldFolder,
	})
	local mayaPrompt = Instance.new("ProximityPrompt")
	mayaPrompt.ActionText = "Talk to Maya Cross"
	mayaPrompt.ObjectText = "Investigative Journalist"
	mayaPrompt.HoldDuration = 0.2
	mayaPrompt.MaxActivationDistance = 12
	mayaPrompt.Parent = mayaPart
	mayaPrompt.Triggered:Connect(function(player: Player)
		MissionService.AdvanceObjectiveByTarget(player, "NPC_MayaCross", 1)
		local startDlg = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.DialogueStarted)
		local DialogueDefinitions = require(Shared:WaitForChild("DialogueDefinitions"))
		startDlg:FireClient(player, DialogueDefinitions.NPC_MayaCross_Intro)
	end)

	-- 5. Municipal Archive Relay (Middle District Stop) + 3 Investigation Clues
	makePart({
		Name = "MunicipalArchive_Building",
		Size = Vector3.new(32, 26, 40),
		Position = Vector3.new(-48, 13, -110),
		Color = Color3.fromRGB(36, 44, 62),
		Material = Enum.Material.Concrete,
		Parent = worldFolder,
	})

	makePart({
		Name = "Zone_ArchiveRelay",
		Size = Vector3.new(22, 10, 22),
		Position = Vector3.new(-10, 5, -110),
		Color = Color3.fromRGB(95, 195, 255),
		Material = Enum.Material.ForceField,
		CanCollide = false,
		Transparency = 0.7,
		Parent = worldFolder,
	})

	local archiveClues = {
		{ id = "Clue_SubstationLog", pos = Vector3.new(-28, 2.5, -96) },
		{ id = "Clue_EthanBadge", pos = Vector3.new(-30, 2.5, -110) },
		{ id = "Clue_ValeDirective", pos = Vector3.new(-28, 2.5, -124) },
	}
	for _, info in ipairs(archiveClues) do
		local cluePart = makePart({
			Name = info.id,
			Size = Vector3.new(1.8, 1.4, 1.8),
			Position = info.pos,
			Color = Color3.fromRGB(0, 225, 255),
			Material = Enum.Material.Neon,
			Parent = worldFolder,
		})
		attachCluePrompt(cluePart, info.id)
	end

	-- 6. Neon Harbor Power Grid & Finale Rooftop (North End of Slice)
	makePart({
		Name = "NeonHarbor_PowerGridCore",
		Size = Vector3.new(54, 24, 48),
		Position = Vector3.new(0, 12, -230),
		Color = Color3.fromRGB(22, 28, 42),
		Material = Enum.Material.Metal,
		Parent = worldFolder,
	})

	local gridZone = makePart({
		Name = "Zone_GridInterior",
		Size = Vector3.new(18, 8, 12),
		Position = Vector3.new(0, 4, -195),
		Color = Color3.fromRGB(140, 95, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.65,
		Parent = worldFolder,
	})
	local gridPrompt = Instance.new("ProximityPrompt")
	gridPrompt.ActionText = "Infiltrate Power Grid Perimeter"
	gridPrompt.ObjectText = "Neon Harbor Facility"
	gridPrompt.Parent = gridZone
	gridPrompt.Triggered:Connect(function(player: Player)
		MissionService.AdvanceObjectiveByTarget(player, "Zone_GridInterior", 1)
	end)

	-- 3 Power Keys inside the Grid
	local powerKeys = {
		{ id = "Key_GeneratorHall", pos = Vector3.new(-16, 3, -212) },
		{ id = "Key_BreakRoom", pos = Vector3.new(0, 3, -218) },
		{ id = "Key_ServerVault", pos = Vector3.new(16, 3, -212) },
	}
	for _, keyInfo in ipairs(powerKeys) do
		local keyPart = makePart({
			Name = keyInfo.id,
			Size = Vector3.new(1.4, 2.2, 0.8),
			Position = keyInfo.pos,
			Color = Color3.fromRGB(255, 85, 190),
			Material = Enum.Material.Neon,
			Parent = worldFolder,
		})
		attachCluePrompt(keyPart, keyInfo.id)
	end

	-- Cargo Lift Trap for Shade
	local cargoLift = makePart({
		Name = "Interact_CargoLiftLock",
		Size = Vector3.new(3, 5, 2),
		Position = Vector3.new(-18, 3, -236),
		Color = Color3.fromRGB(255, 145, 50),
		Material = Enum.Material.Neon,
		Parent = worldFolder,
	})
	local shadePrompt = Instance.new("ProximityPrompt")
	shadePrompt.ActionText = "Seal Cargo Lift (Trap Shade)"
	shadePrompt.ObjectText = "Cargo Elevator Controls"
	shadePrompt.Parent = cargoLift
	shadePrompt.Triggered:Connect(function(player: Player)
		MissionService.AdvanceObjectiveByTarget(player, "Interact_CargoLiftLock", 1)
	end)

	-- Master Switch Console
	local masterSwitch = makePart({
		Name = "Interact_MasterSwitch",
		Size = Vector3.new(4, 4.5, 2.5),
		Position = Vector3.new(0, 3, -242),
		Color = Color3.fromRGB(255, 60, 85),
		Material = Enum.Material.Neon,
		Parent = worldFolder,
	})
	local switchPrompt = Instance.new("ProximityPrompt")
	switchPrompt.ActionText = "Pull Master Switch (TRIGGER BLACKOUT)"
	switchPrompt.ObjectText = "Neon Harbor Master Console"
	switchPrompt.HoldDuration = 1.0
	switchPrompt.Parent = masterSwitch
	switchPrompt.Triggered:Connect(function(player: Player)
		MissionService.ExecuteCityBlackout(player)
	end)

	-- Marcus Hale / Final Choice Terminal
	local marcusPart = makePart({
		Name = "NPC_MarcusHale",
		Size = Vector3.new(2.4, 5.4, 1.6),
		Position = Vector3.new(16, 3, -242),
		Color = Color3.fromRGB(220, 65, 85),
		Material = Enum.Material.SmoothPlastic,
		Parent = worldFolder,
	})
	local marcusPrompt = Instance.new("ProximityPrompt")
	marcusPrompt.ActionText = "Confront Marcus & Make Final Choice"
	marcusPrompt.ObjectText = "Director Marcus Hale"
	marcusPrompt.Parent = marcusPart
	marcusPrompt.Triggered:Connect(function(player: Player)
		local startDlg = RemoteDefinitions.GetEvent(RemoteDefinitions.Events.DialogueStarted)
		local DialogueDefinitions = require(Shared:WaitForChild("DialogueDefinitions"))
		startDlg:FireClient(player, DialogueDefinitions.Blackout_RooftopConfrontation)
	end)

	-- Spawn 2 Patrolling Syndicate Grid Guards
	StealthGuardService.SpawnGuard("Guard_Perimeter_1", "Grid Guard Alpha", {
		Vector3.new(-12, 2.6, -185),
		Vector3.new(12, 2.6, -185),
	})
	StealthGuardService.SpawnGuard("Guard_Perimeter_2", "Grid Guard Bravo", {
		Vector3.new(14, 2.6, -205),
		Vector3.new(-14, 2.6, -205),
	})
end

return WorldBuilderService
