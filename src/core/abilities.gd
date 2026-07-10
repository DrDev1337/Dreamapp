class_name Abilities
## Katalog över alla abilities (US-3.2). En ability är ett Dictionary med:
##   id, name, desc, axis ("fighter"/"mage"/"rogue"/"none"),
##   mana_cost, cooldown, power (multiplikator på attack/magic),
##   kind ("physical"/"magic"/"heal"/"buff"), target ("enemy"/"all_enemies"/"self"),
##   status: valfri statuseffekt {id, duration, ...} som läggs på målet.

const CATALOG := {
	"basic_attack":
	{
		"id": "basic_attack",
		"name": "Attack",
		"desc": "A simple strike.",
		"axis": "none",
		"mana_cost": 0,
		"cooldown": 0,
		"power": 1.0,
		"kind": "physical",
		"target": "enemy",
	},
	"focus_strike":
	{
		"id": "focus_strike",
		"name": "Focused Strike",
		"desc": "A powerful blow. Costs mana.",
		"axis": "none",
		"mana_cost": 3,
		"cooldown": 0,
		"power": 1.6,
		"kind": "physical",
		"target": "enemy",
	},
	# --- Fighter ---
	"power_strike":
	{
		"id": "power_strike",
		"name": "Power Strike",
		"desc": "A heavy blow with high damage.",
		"axis": "fighter",
		"mana_cost": 4,
		"cooldown": 0,
		"power": 2.0,
		"kind": "physical",
		"target": "enemy",
	},
	"shield_bash":
	{
		"id": "shield_bash",
		"name": "Shield Bash",
		"desc": "Damages and stuns the enemy for a turn.",
		"axis": "fighter",
		"mana_cost": 5,
		"cooldown": 2,
		"power": 0.8,
		"kind": "physical",
		"target": "enemy",
		"status": {"id": "stun", "duration": 1},
	},
	"war_cry":
	{
		"id": "war_cry",
		"name": "War Cry",
		"desc": "+50% attack for 3 turns.",
		"axis": "fighter",
		"mana_cost": 4,
		"cooldown": 3,
		"power": 0.0,
		"kind": "buff",
		"target": "self",
		"status": {"id": "atk_up", "duration": 3, "mult": 1.5},
	},
	"berserk":
	{
		"id": "berserk",
		"name": "Berserk",
		"desc": "Signature: a massive blow against all enemies.",
		"axis": "fighter",
		"mana_cost": 8,
		"cooldown": 4,
		"power": 1.5,
		"kind": "physical",
		"target": "all_enemies",
		"signature": true,
	},
	# --- Mage ---
	"firebolt":
	{
		"id": "firebolt",
		"name": "Firebolt",
		"desc": "Magic damage that partly ignores armor.",
		"axis": "mage",
		"mana_cost": 3,
		"cooldown": 0,
		"power": 1.6,
		"kind": "magic",
		"target": "enemy",
	},
	"frost_nova":
	{
		"id": "frost_nova",
		"name": "Frost Nova",
		"desc": "Damages all enemies and slows them.",
		"axis": "mage",
		"mana_cost": 6,
		"cooldown": 2,
		"power": 0.9,
		"kind": "magic",
		"target": "all_enemies",
		"status": {"id": "slow", "duration": 2},
	},
	"arcane_shield":
	{
		"id": "arcane_shield",
		"name": "Arcane Shield",
		"desc": "Absorbs damage for 3 turns.",
		"axis": "mage",
		"mana_cost": 5,
		"cooldown": 3,
		"power": 0.0,
		"kind": "buff",
		"target": "self",
		"status": {"id": "shield", "duration": 3, "amount": 15},
	},
	"meteor":
	{
		"id": "meteor",
		"name": "Meteor",
		"desc": "Signature: devastating magic against all enemies.",
		"axis": "mage",
		"mana_cost": 10,
		"cooldown": 4,
		"power": 2.2,
		"kind": "magic",
		"target": "all_enemies",
		"signature": true,
	},
	# --- Rogue ---
	"backstab":
	{
		"id": "backstab",
		"name": "Backstab",
		"desc": "Double damage against unharmed enemies.",
		"axis": "rogue",
		"mana_cost": 3,
		"cooldown": 0,
		"power": 1.3,
		"kind": "physical",
		"target": "enemy",
		"bonus_vs_full_hp": 2.0,
	},
	"poison_blade":
	{
		"id": "poison_blade",
		"name": "Poison Blade",
		"desc": "Damages and poisons for 3 turns.",
		"axis": "rogue",
		"mana_cost": 4,
		"cooldown": 1,
		"power": 0.8,
		"kind": "physical",
		"target": "enemy",
		"status": {"id": "poison", "duration": 3, "amount": 4},
	},
	"evasion":
	{
		"id": "evasion",
		"name": "Evasion",
		"desc": "Evades the next attack.",
		"axis": "rogue",
		"mana_cost": 4,
		"cooldown": 3,
		"power": 0.0,
		"kind": "buff",
		"target": "self",
		"status": {"id": "evade", "duration": 1},
	},
	"shadow_dance":
	{
		"id": "shadow_dance",
		"name": "Shadow Dance",
		"desc": "Signature: strike twice this turn.",
		"axis": "rogue",
		"mana_cost": 8,
		"cooldown": 4,
		"power": 1.2,
		"kind": "physical",
		"target": "enemy",
		"hits": 2,
		"signature": true,
	},
}

const SIGNATURE_BY_AXIS := {"fighter": "berserk", "mage": "meteor", "rogue": "shadow_dance"}


static func get_ability(id: String) -> Dictionary:
	return CATALOG.get(id, {})


static func abilities_for_axis(axis: String) -> Array:
	var result: Array = []
	for id in CATALOG:
		var ab: Dictionary = CATALOG[id]
		if ab.get("axis", "") == axis and not ab.get("signature", false):
			result.append(id)
	return result
