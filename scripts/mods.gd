class_name MapMods
extends RefCounted

enum Target { World, All, Enemies, Human }

enum Mod {
	Conscription,
	TotalWar,
	Godless,
	GodForsaken,
	Famine,
	Scarcity,
	NeptuneCurse,
	NeptunePrison,
	Treason,
	Populous,
	Guarded
}

const mods = {
	Mod.Treason:
	{
		"level": 4,
		"name": "Treason",
		"effects":
		[
			{"target": Target.Human, "effect": {"id": "treason", "tier": 1}},
		],
		"description":
		"At the end of your turn, one of your regions is converted to an enemy's side."
	},
	Mod.NeptunePrison:
	{
		"level": 2,
		"name": "Neptune's Prison",
		"effects":
		[
			{
				"target": Target.Human,
				"effect": {"id": "prison", "tier": 2},
			},
		],
		"description": "Only play up to 4 cards per turn."
	},
	Mod.NeptuneCurse:
	{
		"level": 3,
		"name": "Neptune's Curse",
		"effects":
		[
			{"target": Target.Human, "effect": {"id": "sink_random_self_tiles", "tier": 2}},
		],
		"description": "Every time you play a card, Neptune randomly sinks one of your tiles."
	},
	Mod.Conscription:
	{
		"level": 1,
		"name": "Conscription",
		"effects":
		[
			{
				"target": Target.Enemies,
				"effect": {"id": "conscription", "tier": 1},
			}
		],
		"description": "Enemy troops regenerate twice as fast."
	},
	Mod.TotalWar:
	{
		"level": 2,
		"name": "Total War",
		"effects":
		[
			{
				"target": Target.Enemies,
				"effect": {"id": "conscription", "tier": 2},
			}
		],
		"description": "Enemy troops regenerate three times as fast."
	},
	Mod.Godless:
	{
		"level": 2,
		"name": "Godless",
		"effects": [{"target": Target.Human, "effect": {"id": "godless", "tier": 1}}],
		"description": "Generate one less faith per turn."
	},
	Mod.GodForsaken:
	{
		"level": 3,
		"name": "Godforsaken",
		"effects": [{"target": Target.Human, "effect": {"id": "godless", "tier": 2}}],
		"description": "Generate two less faith per turn."
	},
	Mod.Populous:
	{
		"level": 1,
		"name": "Populous",
		"effects":
		[
			{"target": Target.World, "effect": {"id": "initial_neutral_units", "tier": 1}},
		],
		"description": "Neutral regions start with a few units."
	},
	Mod.Guarded:
	{
		"level": 2,
		"name": "Guarded",
		"effects":
		[
			{"target": Target.World, "effect": {"id": "initial_neutral_units", "tier": 2}},
		],
		"description": "Neutral regions start with many units."
	},
	Mod.Famine:
	{
		"level": 1,
		"name": "Famine",
		"effects":
		[
			{
				"target": Target.Human,
				"effect": {"id": "famine", "tier": 1},
			}
		],
		"description": "Your troops regenerate half as fast."
	},
	Mod.Scarcity:
	{
		"level": 2,
		"name": "Scarcity",
		"effects":
		[
			{
				"target": Target.Human,
				"effect": {"id": "cardless", "tier": 2},
			}
		],
		"description": "Draw two less cards per turn."
	},
}
