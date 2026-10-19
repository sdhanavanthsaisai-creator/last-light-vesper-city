--!strict
--[[
	MissionDefinitions.luau
	Server-authoritative mission definitions for Milestone 1 Vertical Slice ("Missing Records")
	and the Finale Stealth Mission ("Operation BLACKOUT").
	Location: ReplicatedStorage/Shared/MissionDefinitions
]]

export type ObjectiveDef = {
	id: string,
	title: string,
	description: string,
	targetId: string,
	requiredCount: number,
	locationHint: string,
}

export type MissionDef = {
	id: string,
	chapter: string,
	title: string,
	subtitle: string,
	summary: string,
	prerequisiteMissionId: string?,
	rewardCurrency: number,
	rewardFlag: string,
	objectives: { ObjectiveDef },
}

local MissionDefinitions: { [string]: MissionDef } = {
	-- MILESTONE 1 VERTICAL SLICE MISSION (From LAST LIGHT Master Plan Section 7)
	M1_MissingRecords = {
		id = "M1_MissingRecords",
		chapter = "Prologue & Chapter 1",
		title = "Missing Records",
		subtitle = "Old Quarter Investigation",
		summary = "Noah returns to Old Quarter after receiving an anonymous message: 'The blackout wasn't an accident.' Speak with journalist Maya Cross, drive to the Archive Relay, collect three pieces of evidence, and return to the garage.",
		prerequisiteMissionId = nil,
		rewardCurrency = 350,
		rewardFlag = "Completed_M1_MissingRecords",
		objectives = {
			{
				id = "inspect_notice",
				title = "Inspect the Redevelopment Notice",
				description = "Check the Second Dawn notice posted outside Noah's Old Quarter apartment.",
				targetId = "Clue_RedevelopmentNotice",
				requiredCount = 1,
				locationHint = "Old Quarter Apartment Entrance",
			},
			{
				id = "talk_to_maya",
				title = "Speak with Maya Cross",
				description = "Meet investigative journalist Maya Cross under the Old Quarter streetlamp.",
				targetId = "NPC_MayaCross",
				requiredCount = 1,
				locationHint = "Corner of Vesper Ave & 4th",
			},
			{
				id = "drive_to_archive",
				title = "Drive to the Municipal Archive Relay",
				description = "Spawn or enter your Vesper Coupe at the Garage and reach the Archive Relay checkpoint.",
				targetId = "Zone_ArchiveRelay",
				requiredCount = 1,
				locationHint = "East Old Quarter / Archive Street",
			},
			{
				id = "collect_three_clues",
				title = "Collect 3 Blackout Evidence Clues",
				description = "Search the Archive Relay exterior and alley for altered grid logs and Ethan's badge.",
				targetId = "Clue_ArchiveEvidence",
				requiredCount = 3,
				locationHint = "Municipal Archive Relay",
			},
			{
				id = "return_to_garage",
				title = "Return to Noah's Garage",
				description = "Bring the recovered records back to the Old Quarter safehouse garage to secure your progress.",
				targetId = "Zone_NoahGarage",
				requiredCount = 1,
				locationHint = "Old Quarter Garage",
			},
		},
	},

	-- FINALE MISSION: SILENT CONTRACT / OPERATION BLACKOUT
	M5_Blackout = {
		id = "M5_Blackout",
		chapter = "Finale — 11:42 PM",
		title = "Operation: BLACKOUT",
		subtitle = "Neon Harbor Power Grid & Rooftop Confrontation",
		summary = "Infiltrate the Neon Harbor Power Grid without raising alert, collect the three Power Keys (Generator Hall, Break Room, Server Vault), overload the master switch to cut city-wide surveillance, and confront the Architect on the rooftop.",
		prerequisiteMissionId = "M1_MissingRecords",
		rewardCurrency = 1000,
		rewardFlag = "Completed_M5_Blackout",
		objectives = {
			{
				id = "infiltrate_perimeter",
				title = "Infiltrate the Grid Perimeter",
				description = "Enter the Power Grid via Maintenance Disguise, Sewer Tunnel, or Rooftop Grapple.",
				targetId = "Zone_GridInterior",
				requiredCount = 1,
				locationHint = "Neon Harbor Outer Fence",
			},
			{
				id = "collect_power_keys",
				title = "Acquire the 3 Power Keys",
				description = "Recover Key 1 (Generator Hall), Key 2 (Break Room), and Key 3 (Server Vault).",
				targetId = "Item_PowerKey",
				requiredCount = 3,
				locationHint = "Power Grid Control Building",
			},
			{
				id = "trap_shade_lift",
				title = "Evade Shade & Seal the Cargo Lift",
				description = "Lure the hunter Shade into the cargo elevator so Raven/Maya can seal the doors.",
				targetId = "Interact_CargoLiftLock",
				requiredCount = 1,
				locationHint = "Lower Cargo Lift",
			},
			{
				id = "pull_master_switch",
				title = "Insert Keys & Pull the Master Switch",
				description = "Charge all three keys at the central console and trigger the city-wide Blackout.",
				targetId = "Interact_MasterSwitch",
				requiredCount = 1,
				locationHint = "Main Control Room",
			},
			{
				id = "rooftop_choice",
				title = "Confront the Director on the Rooftop",
				description = "Seize the backup remote before it hits 100% and make the final choice for the city.",
				targetId = "Interact_FinalChoice",
				requiredCount = 1,
				locationHint = "Tower Rooftop Broadcast Room",
			},
		},
	},
}

return table.freeze(MissionDefinitions)
