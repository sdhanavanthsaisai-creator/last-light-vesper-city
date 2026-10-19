--!strict
--[[
	DialogueDefinitions.luau
	Stores dialogue trees, cutscene subtitles, and speaker timings.
	Used by DialogueController (ScreenGui typewriter effect) and server validation.
	Location: ReplicatedStorage/Shared/DialogueDefinitions
]]

export type DialogueLine = {
	Speaker: string,
	Role: string,
	Text: string,
	Duration: number,
	CameraShot: string?,
}

export type DialogueChoice = {
	id: string,
	label: string,
	outcomeText: string,
	setsFlag: string,
}

export type DialogueSequence = {
	id: string,
	title: string,
	lines: { DialogueLine },
	choices: { DialogueChoice }?,
}

local DialogueDefinitions: { [string]: DialogueSequence } = {
	-- MILESTONE 1 OPENING CUTSCENE (LAST LIGHT Master Plan Section 7)
	Opening_ComingHome = {
		id = "Opening_ComingHome",
		title = "Prologue: Coming Home",
		lines = {
			{
				Speaker = "SYSTEM",
				Role = "Vesper City Transit",
				Text = "OLD QUARTER STATION — 11:18 PM. Seven years since the Great Blackout.",
				Duration = 4.0,
				CameraShot = "Cam_StreetOverview",
			},
			{
				Speaker = "PHONE MESSAGE",
				Role = "Encrypted Sender",
				Text = "Noah — if you're back in Vesper City, check your old apartment door. The blackout wasn't an accident.",
				Duration = 4.5,
				CameraShot = "Cam_ApartmentDoor",
			},
			{
				Speaker = "NOAH REED",
				Role = "Protagonist",
				Text = "Ethan used this frequency before he vanished. Somebody kept the old relay alive.",
				Duration = 4.0,
				CameraShot = "Cam_NoahClose",
			},
			{
				Speaker = "NOAH REED",
				Role = "Protagonist",
				Text = "Maya said she'd be waiting down the street by the garage. Time to see what Victor Vale buried.",
				Duration = 4.2,
				CameraShot = "Cam_GarageStreet",
			},
		},
	},

	-- MAYA CROSS DIALOGUE (Old Quarter NPC)
	NPC_MayaCross_Intro = {
		id = "NPC_MayaCross_Intro",
		title = "Maya Cross — Old Quarter Lead",
		lines = {
			{
				Speaker = "MAYA CROSS",
				Role = "Investigative Journalist",
				Text = "Noah? You actually came back. Half the Old Quarter is already plastered with Second Dawn buyout notices.",
				Duration = 4.2,
			},
			{
				Speaker = "NOAH REED",
				Role = "Former Grid Technician",
				Text = "Someone texted me on Ethan's old channel, Maya. Said the blackout seven years ago wasn't an electrical fault.",
				Duration = 4.5,
			},
			{
				Speaker = "MAYA CROSS",
				Role = "Investigative Journalist",
				Text = "Because it wasn't. I pulled two versions of the municipal report from your old department. Someone rewrote the load logs at 11:42 PM.",
				Duration = 4.8,
			},
			{
				Speaker = "NOAH REED",
				Role = "Former Grid Technician",
				Text = "My diagnostic patch went live that night... If they used my code to mask a manual shutdown, the original buffer is still at the Archive Relay.",
				Duration = 5.0,
			},
			{
				Speaker = "MAYA CROSS",
				Role = "Investigative Journalist",
				Text = "Take your coupe from the garage. Collect the three physical log drives at the Archive Relay and bring them back before Vale's scanners sweep the block.",
				Duration = 4.8,
			},
		},
		choices = {
			{
				id = "choice_promise_truth",
				label = "We expose everything — even my own mistake.",
				outcomeText = "MAYA: That's the Noah I trusted. Be careful out there.",
				setsFlag = "Flag_HonestWithMaya",
			},
			{
				id = "choice_protect_ethan",
				label = "Ethan comes first. The press comes second.",
				outcomeText = "MAYA: Fair enough. Find those drives and we'll track Ethan's last login.",
				setsFlag = "Flag_FocusedOnEthan",
			},
		},
	},

	-- SILENT CONTRACT / BLACKOUT OPENING CUTSCENE
	Blackout_TheLastNight = {
		id = "Blackout_TheLastNight",
		title = "Opening Cutscene: The Last Night",
		lines = {
			{
				Speaker = "RAVEN",
				Role = "Handler (Earpiece)",
				Text = "Ghost, can you hear me?",
				Duration = 2.5,
				CameraShot = "Cam_HarborRooftop",
			},
			{
				Speaker = "GHOST",
				Role = "Agent",
				Text = "Loud and clear.",
				Duration = 2.2,
			},
			{
				Speaker = "RAVEN",
				Role = "Handler (Earpiece)",
				Text = "Good. Everything Marcus built runs through that power grid. Every camera, every scanner, every lock in the city. Cut the grid, and his eyes go dark.",
				Duration = 5.2,
			},
			{
				Speaker = "RAVEN",
				Role = "Handler (Earpiece)",
				Text = "But the grid is guarded. Marcus knows you're coming.",
				Duration = 3.2,
			},
			{
				Speaker = "GHOST",
				Role = "Agent",
				Text = "He always knows. That's why we do it differently this time.",
				Duration = 3.5,
			},
			{
				Speaker = "RAVEN",
				Role = "Handler (Earpiece)",
				Text = "(small laugh) There's the Ghost I remember. One night. One chance. Let's end this.",
				Duration = 4.0,
			},
		},
	},

	-- SHADE ENCOUNTER
	Blackout_ShadeEncounter = {
		id = "Blackout_ShadeEncounter",
		title = "Mid-Mission Encounter: Shade",
		lines = {
			{
				Speaker = "SHADE",
				Role = "Mercenary Hunter (Loudspeaker)",
				Text = "Ghost. I've been following your footsteps all night. Quiet ones. Impressive.",
				Duration = 4.0,
			},
			{
				Speaker = "GHOST",
				Role = "Agent",
				Text = "Let me guess. Marcus sent you.",
				Duration = 2.5,
			},
			{
				Speaker = "SHADE",
				Role = "Mercenary Hunter (Loudspeaker)",
				Text = "Marcus pays well. And I don't lose.",
				Duration = 3.0,
			},
			{
				Speaker = "RAVEN",
				Role = "Handler (Earpiece)",
				Text = "Don't fight him! Lead him to the cargo lift. I'll seal him inside.",
				Duration = 3.8,
			},
		},
	},

	-- THE BLACKOUT CUTSCENE
	Blackout_MasterSwitchCutscene = {
		id = "Blackout_MasterSwitchCutscene",
		title = "The Blackout",
		lines = {
			{
				Speaker = "RAVEN",
				Role = "Handler (Earpiece)",
				Text = "Now, Ghost. Pull it.",
				Duration = 2.5,
			},
			{
				Speaker = "GHOST",
				Role = "Agent",
				Text = "For everyone in this city.",
				Duration = 2.8,
			},
			{
				Speaker = "RAVEN",
				Role = "Handler (Earpiece)",
				Text = "Look at that. Real stars.",
				Duration = 3.8,
			},
		},
	},

	-- ROOFTOP CONFRONTATION & FINAL CHOICE
	Blackout_RooftopConfrontation = {
		id = "Blackout_RooftopConfrontation",
		title = "Act 4: The Confrontation",
		lines = {
			{
				Speaker = "MARCUS HALE",
				Role = "Director / Architect",
				Text = "Ghost. I always wondered which of my agents would make it this far.",
				Duration = 3.8,
			},
			{
				Speaker = "GHOST",
				Role = "Agent",
				Text = "You built the Agency to fight the Syndicate.",
				Duration = 3.0,
			},
			{
				Speaker = "MARCUS HALE",
				Role = "Director / Architect",
				Text = "I built the Agency to replace the Syndicate. Every target you took down was a rival I couldn't remove myself. You were my best weapon, and you never even knew it.",
				Duration = 5.5,
			},
			{
				Speaker = "RAVEN",
				Role = "Handler",
				Text = "He used all of us, Ghost. I'd rather be a nobody than be you.",
				Duration = 4.0,
			},
			{
				Speaker = "MARCUS HALE",
				Role = "Director / Architect",
				Text = "So what now, Ghost? Do you finish it?",
				Duration = 3.5,
			},
		},
		choices = {
			{
				id = "Ending_ExposePublicly",
				label = "CHOICE 1: EXPOSE HIM PUBLICLY (The City Remembers / Dawn Over Neon Harbor)",
				outcomeText = "GHOST: No. The city deserves the truth, and you deserve a trial.",
				setsFlag = "Ending_DawnOverNeonHarbor",
			},
			{
				id = "Ending_TakeHisPlace",
				label = "CHOICE 2: TAKE HIS PLACE (The New Director / The New Architect)",
				outcomeText = "GHOST: ...Maybe the city needs someone strong to hold it together.",
				setsFlag = "Ending_TheNewDirector",
			},
			{
				id = "Ending_Disappear",
				label = "CHOICE 3: DISAPPEAR (The Quiet Exit / No Fixed Address)",
				outcomeText = "GHOST: It's not my fight anymore. Let the city decide.",
				setsFlag = "Ending_TheQuietExit",
			},
		},
	},
}

return table.freeze(DialogueDefinitions)
