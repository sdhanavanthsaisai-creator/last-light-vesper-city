--!strict
--[[
	ItemDefinitions.luau
	Definitions for investigation clues, keycards, gadgets, and vehicles.
	Location: ReplicatedStorage/Shared/ItemDefinitions
]]

export type ClueDefinition = {
	id: string,
	title: string,
	district: string,
	category: "Clue" | "PowerKey" | "SecretCollectible",
	description: string,
	journalEntry: string,
}

export type VehicleDefinition = {
	id: string,
	name: string,
	maxSpeed: number,
	acceleration: number,
	turnSpeed: number,
	brakingForce: number,
	bodyColor: Color3,
}

local ItemDefinitions = {
	Clues = {
		Clue_RedevelopmentNotice = {
			id = "Clue_RedevelopmentNotice",
			title = "Second Dawn Redevelopment Notice",
			district = "OldQuarter",
			category = "Clue",
			description = "An eviction & infrastructure modernization notice signed by Vale Corp.",
			journalEntry = "Notice #409: Old Quarter substation slated for complete memory wipe under Second Dawn rollout.",
		},
		Clue_SubstationLog = {
			id = "Clue_SubstationLog",
			title = "Altered Substation Load Log (11:42 PM)",
			district = "OldQuarter",
			category = "Clue",
			description = "Hardcopy printout showing manual override commands disguised as a fault.",
			journalEntry = "Archive Drive 1/3: Someone injected an override key using Noah's maintenance credentials.",
		},
		Clue_EthanBadge = {
			id = "Clue_EthanBadge",
			title = "Ethan Reed's Grid Inspector Badge",
			district = "OldQuarter",
			category = "Clue",
			description = "Found hidden behind the Municipal Archive Relay transformer box.",
			journalEntry = "Archive Drive 2/3: Ethan was here three nights after the blackout trying to back up the raw telemetry.",
		},
		Clue_ValeDirective = {
			id = "Clue_ValeDirective",
			title = "Encrypted Second Dawn Directive",
			district = "OldQuarter",
			category = "Clue",
			description = "A magnetic tape canister labeled 'PROJECT BLACKOUT — PHASE ZERO'.",
			journalEntry = "Archive Drive 3/3: Confirms the blackout cleared property titles across Blackwater Docks and Old Quarter.",
		},

		-- Operation BLACKOUT Power Keys
		Key_GeneratorHall = {
			id = "Key_GeneratorHall",
			title = "Power Key 1 — Generator Hall",
			district = "BlackwaterDocks",
			category = "PowerKey",
			description = "Recovered past the spinning turbine blades.",
			journalEntry = "Power Key 1 acquired from the Generator Hall.",
		},
		Key_BreakRoom = {
			id = "Key_BreakRoom",
			title = "Power Key 2 — Break Room",
			district = "BlackwaterDocks",
			category = "PowerKey",
			description = "Pickpocketed quietly from the sleeping shift supervisor.",
			journalEntry = "Power Key 2 acquired from the Break Room without raising an alarm.",
		},
		Key_ServerVault = {
			id = "Key_ServerVault",
			title = "Power Key 3 — Server Vault",
			district = "BlackwaterDocks",
			category = "PowerKey",
			description = "Extracted after bypassing the laser grid panel.",
			journalEntry = "Power Key 3 acquired from the Server Vault.",
		},

		-- Secret Replay Collectibles
		Secret_MarcusAgencyBadge = {
			id = "Secret_MarcusAgencyBadge",
			title = "Marcus's Original Agency Badge",
			district = "BlackwaterDocks",
			category = "SecretCollectible",
			description = "Tarnished silver badge hidden in the Break Room locker.",
			journalEntry = "Secret Collectible: Proves Marcus founded both the Agency and the Syndicate.",
		},
	},

	Vehicles = {
		vesper_coupe_89 = {
			id = "vesper_coupe_89",
			name = "1989 Vesper Coupe GT",
			maxSpeed = 68,
			acceleration = 28,
			turnSpeed = 2.4,
			brakingForce = 55,
			bodyColor = Color3.fromRGB(34, 42, 58),
		},
	},
}

return table.freeze(ItemDefinitions)
