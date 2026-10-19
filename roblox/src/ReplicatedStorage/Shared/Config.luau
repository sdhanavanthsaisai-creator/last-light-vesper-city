--!strict
--[[
	Config.luau
	Shared configuration for LAST LIGHT: The City That Forgot You & Episode Finale: BLACKOUT
	Location: ReplicatedStorage/Shared/Config
]]

export type DistrictConfig = {
	id: string,
	name: string,
	description: string,
	ambientColor: Color3,
	fogEnd: number,
}

local Config = {
	GAME_TITLE = "LAST LIGHT: The City That Forgot You",
	SUBTITLE = "Vesper City — Vertical Slice & Operation BLACKOUT",
	VERSION = "0.1.0-milestone1",

	-- DataStore settings
	DATASTORE_NAME = "LastLight_PlayerData_v1",
	AUTOSAVE_INTERVAL_SECONDS = 120,
	MAX_SAVE_RETRIES = 3,

	-- Player & Economy defaults
	STARTING_CURRENCY = 250,
	DEFAULT_DISTRICT = "OldQuarter",
	DEFAULT_VEHICLE_ID = "vesper_coupe_89",

	-- Interaction & Stealth settings
	INTERACTION_MAX_DISTANCE = 14,
	STEALTH_LIGHT_CONE_RANGE = 32,
	STEALTH_DETECTION_SECONDS = 3.0,
	STEALTH_CROUCH_MULTIPLIER = 0.5,
	POWER_KEY_CHARGE_SECONDS = 10.0,

	-- Lighting Presets
	LIGHTING = {
		NormalNight = {
			Ambient = Color3.fromRGB(24, 30, 48),
			OutdoorAmbient = Color3.fromRGB(36, 44, 68),
			Brightness = 1.6,
			ClockTime = 23.7, -- 11:42 PM
			FogEnd = 450,
			FogColor = Color3.fromRGB(14, 18, 30),
		},
		BlackoutActive = {
			Ambient = Color3.fromRGB(8, 14, 28),
			OutdoorAmbient = Color3.fromRGB(12, 20, 42),
			Brightness = 0.45,
			ClockTime = 0.2,
			FogEnd = 700,
			FogColor = Color3.fromRGB(6, 10, 20),
		},
		DawnEnding = {
			Ambient = Color3.fromRGB(85, 72, 68),
			OutdoorAmbient = Color3.fromRGB(140, 110, 95),
			Brightness = 2.2,
			ClockTime = 6.3,
			FogEnd = 900,
			FogColor = Color3.fromRGB(185, 140, 110),
		},
	},

	-- 5 Districts from Master Plan
	DISTRICTS = {
		OldQuarter = {
			id = "OldQuarter",
			name = "Old Quarter",
			description = "Older apartments, corner shops, Noah's garage and early investigation leads.",
			ambientColor = Color3.fromRGB(28, 34, 52),
			fogEnd = 420,
		},
		CrownCity = {
			id = "CrownCity",
			name = "Crown City",
			description = "Skyscrapers, Vale Tower rooftop, and corporate Second Dawn plazas.",
			ambientColor = Color3.fromRGB(32, 42, 68),
			fogEnd = 550,
		},
		BlackwaterDocks = {
			id = "BlackwaterDocks",
			name = "Blackwater Docks / Neon Harbor Grid",
			description = "Cargo yards, waterfront power grid, and abandoned network relays.",
			ambientColor = Color3.fromRGB(20, 32, 46),
			fogEnd = 380,
		},
		Undercity = {
			id = "Undercity",
			name = "Undercity",
			description = "Utility tunnels, drain pipes, steam vents, and decommissioned control vaults.",
			ambientColor = Color3.fromRGB(15, 22, 30),
			fogEnd = 240,
		},
		MeridianHeights = {
			id = "MeridianHeights",
			name = "Meridian Heights",
			description = "Modern apartments, parks, safehouses, and shopping streets.",
			ambientColor = Color3.fromRGB(38, 44, 64),
			fogEnd = 600,
		},
	},

	-- Optional Fair Cosmetic GamePasses (Section 10 of Master Plan)
	GAME_PASSES = {
		SupporterPass = {
			key = "SupporterPass",
			passId = 0, -- Replace with published Roblox GamePass ID
			priceRobux = 149,
			title = "Supporter Pass",
			description = "Supports ongoing development and unlocks the golden Vesper Citizen badge & sunrise lantern trail.",
		},
		PremiumGarageTheme = {
			key = "PremiumGarageTheme",
			passId = 0,
			priceRobux = 79,
			title = "Neon Harbor Garage Theme",
			description = "Cosmetic cyber-noir lighting and tool rack upgrade for your Old Quarter Garage.",
		},
		VehicleCosmeticPack = {
			key = "VehicleCosmeticPack",
			passId = 0,
			priceRobux = 49,
			title = "Vesper Coupe Midnight Trim",
			description = "Cosmetic matte-obsidian paint and amber fog headlights for your vehicle.",
		},
		CosmeticBundle = {
			key = "CosmeticBundle",
			passId = 0,
			priceRobux = 39,
			title = "Ghost & Investigator Outfits",
			description = "Unlocks the Free City Trenchcoat and Wanderer Jacket cosmetic outfits.",
		},
	},
}

return table.freeze(Config)
