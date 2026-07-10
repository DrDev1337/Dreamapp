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
		"desc": "Ett enkelt hugg.",
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
		"name": "Fokuserat slag",
		"desc": "Ett kraftfullt slag. Kostar mana.",
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
		"name": "Kraftslag",
		"desc": "Tungt slag med hög skada.",
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
		"name": "Sköldstöt",
		"desc": "Skadar och bedövar fienden en tur.",
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
		"name": "Stridsrop",
		"desc": "+50% attack i 3 turer.",
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
		"name": "Bärsärk",
		"desc": "Signatur: enormt slag mot alla fiender.",
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
		"name": "Eldpil",
		"desc": "Magisk skada som delvis ignorerar rustning.",
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
		"name": "Frostnova",
		"desc": "Skadar alla fiender och sänker deras fart.",
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
		"name": "Arkan sköld",
		"desc": "Absorberar skada i 3 turer.",
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
		"desc": "Signatur: förödande magi mot alla fiender.",
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
		"name": "Ryggdolk",
		"desc": "Dubbel skada mot oskadda fiender.",
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
		"name": "Giftklinga",
		"desc": "Skadar och förgiftar i 3 turer.",
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
		"name": "Undanglidning",
		"desc": "Undviker nästa attack.",
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
		"name": "Skuggdans",
		"desc": "Signatur: slå två gånger denna tur.",
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
