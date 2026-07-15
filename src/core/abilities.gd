class_name Abilities
## Förmågekatalog för partyt (party_design.md). En förmåga är ett Dictionary:
##   id, name, desc, axis ("tank"/"healer"/"mage"/"rogue"/"none"),
##   mana_cost, cooldown, power, kind, target, status (valfri).
## kind styr exekveringen i CombatEngine:
##   "physical"/"magic" – skada mot fiender (target enemy/all_enemies)
##   "heal"   – helar automatiskt mest skadad levande hjälte
##   "buff"   – status på användaren (target self) eller auto-allierad (ally)
##   "taunt"  – status på alla levande fiender: de måste slå användaren
##   "revive" – väcker första fallna hjälten

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
	# Universell (alla hjältar): blockbeslutet + mana-motorn. Att avstå
	# skada för att stå emot en intent ELLER ladda mana är kärnvalet
	# varje runda (Slay the Spire-block / Slice & Dice-pips).
	"defend":
	{
		"id": "defend",
		"name": "Defend",
		"desc": "Halve the next hit taken and focus: +3 mana.",
		"axis": "none",
		"mana_cost": 0,
		"cooldown": 0,
		"power": 0.0,
		"kind": "defend",
		"target": "self",
	},
	# --- Tank ---
	"taunt":
	{
		"id": "taunt",
		"name": "Taunt",
		"desc": "Forces all enemies to attack you for 2 turns.",
		"axis": "tank",
		"mana_cost": 3,
		"cooldown": 2,
		"power": 0.0,
		"kind": "taunt",
		"target": "all_enemies",
		"status": {"id": "taunt", "duration": 2},
	},
	"shield_bash":
	{
		"id": "shield_bash",
		"name": "Shield Bash",
		"desc": "Damages and stuns the enemy for a turn.",
		"axis": "tank",
		"mana_cost": 4,
		"cooldown": 2,
		"power": 0.9,
		"kind": "physical",
		"target": "enemy",
		"status": {"id": "stun", "duration": 1},
	},
	"fortify":
	{
		"id": "fortify",
		"name": "Fortify",
		"desc": "Shield yourself, absorbing 12 damage.",
		"axis": "tank",
		"mana_cost": 3,
		"cooldown": 2,
		"power": 0.0,
		"kind": "buff",
		"target": "self",
		"status": {"id": "shield", "duration": 3, "amount": 12},
	},
	"bulwark":
	{
		"id": "bulwark",
		"name": "Bulwark",
		"desc": "Signature: massive shield and taunts all enemies.",
		"axis": "tank",
		"mana_cost": 8,
		"cooldown": 4,
		"power": 0.0,
		"kind": "taunt",
		"target": "all_enemies",
		"status": {"id": "taunt", "duration": 2},
		"self_status": {"id": "shield", "duration": 3, "amount": 24},
		"signature": true,
	},
	# --- Healer ---
	"mend":
	{
		"id": "mend",
		"name": "Mend",
		"desc": "Heal the most wounded ally.",
		"axis": "healer",
		"mana_cost": 3,
		"cooldown": 0,
		"power": 2.2,
		"kind": "heal",
		"target": "ally",
	},
	"radiance":
	{
		"id": "radiance",
		"name": "Radiance",
		"desc": "Heal the whole party a little.",
		"axis": "healer",
		"mana_cost": 6,
		"cooldown": 2,
		"power": 0.9,
		"kind": "heal",
		"target": "all_allies",
	},
	"smite":
	{
		"id": "smite",
		"name": "Smite",
		"desc": "Light magic damage.",
		"axis": "healer",
		"mana_cost": 2,
		"cooldown": 0,
		"power": 1.1,
		"kind": "magic",
		"target": "enemy",
	},
	"resurrect":
	{
		"id": "resurrect",
		"name": "Resurrect",
		"desc": "Signature: revive a fallen ally at half strength.",
		"axis": "healer",
		"mana_cost": 8,
		"cooldown": 6,
		"power": 0.5,
		"kind": "revive",
		"target": "ally",
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
		"desc": "Shield the most wounded ally.",
		"axis": "mage",
		"mana_cost": 4,
		"cooldown": 2,
		"power": 0.0,
		"kind": "buff",
		"target": "ally",
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
	# Exposed är combo-motorn: rogue öppnar, resten av partyt slår
	# hårdare på samma mål – handlingsordningen (fritt vald) får payoff.
	"backstab":
	{
		"id": "backstab",
		"name": "Backstab",
		"desc": "Double damage to unharmed enemies. Exposes the target: +35% damage taken.",
		"axis": "rogue",
		"mana_cost": 3,
		"cooldown": 0,
		"power": 1.3,
		"kind": "physical",
		"target": "enemy",
		"bonus_vs_full_hp": 2.0,
		"status": {"id": "exposed", "duration": 2, "mult": 1.35},
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
		"mana_cost": 3,
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
	# --- Barbarian (raseri och AoE-yxa) ---
	"cleave":
	{
		"id": "cleave",
		"name": "Cleave",
		"desc": "Sweep your weapon through all enemies.",
		"axis": "barbarian",
		"mana_cost": 4,
		"cooldown": 1,
		"power": 0.7,
		"kind": "physical",
		"target": "all_enemies",
	},
	"rage":
	{
		"id": "rage",
		"name": "Rage",
		"desc": "+60% damage for 2 rounds.",
		"axis": "barbarian",
		"mana_cost": 3,
		"cooldown": 3,
		"power": 0.0,
		"kind": "buff",
		"target": "self",
		"status": {"id": "atk_up", "duration": 2, "mult": 1.6},
	},
	"reckless_swing":
	{
		"id": "reckless_swing",
		"name": "Reckless Swing",
		"desc": "A wild, heavy blow.",
		"axis": "barbarian",
		"mana_cost": 3,
		"cooldown": 1,
		"power": 1.7,
		"kind": "physical",
		"target": "enemy",
	},
	"rampage":
	{
		"id": "rampage",
		"name": "Rampage",
		"desc": "Signature: a devastating sweep through every enemy.",
		"axis": "barbarian",
		"mana_cost": 8,
		"cooldown": 4,
		"power": 1.2,
		"kind": "physical",
		"target": "all_enemies",
		"signature": true,
	},
	# --- Ranger (märkta mål – combo som förbrukas av nästa träff) ---
	"marked_shot":
	{
		"id": "marked_shot",
		"name": "Hunter's Mark",
		"desc": "Damage and mark the target: the next hit on it deals +75%.",
		"axis": "ranger",
		"mana_cost": 3,
		"cooldown": 1,
		"power": 0.6,
		"kind": "physical",
		"target": "enemy",
		"status": {"id": "marked", "duration": 3, "mult": 1.75},
	},
	"piercing_shot":
	{
		"id": "piercing_shot",
		"name": "Piercing Shot",
		"desc": "An arrow that ignores armor.",
		"axis": "ranger",
		"mana_cost": 3,
		"cooldown": 0,
		"power": 1.2,
		"kind": "physical",
		"target": "enemy",
		"armor_pierce": true,
	},
	"volley":
	{
		"id": "volley",
		"name": "Volley",
		"desc": "Arrows rain over all enemies.",
		"axis": "ranger",
		"mana_cost": 5,
		"cooldown": 2,
		"power": 0.8,
		"kind": "physical",
		"target": "all_enemies",
	},
	"deadeye":
	{
		"id": "deadeye",
		"name": "Deadeye",
		"desc": "Signature: one perfect shot.",
		"axis": "ranger",
		"mana_cost": 8,
		"cooldown": 4,
		"power": 2.6,
		"kind": "physical",
		"target": "enemy",
		"armor_pierce": true,
		"signature": true,
	},
	# --- Warlock (förbannelser och livsstöld) ---
	"curse_of_frailty":
	{
		"id": "curse_of_frailty",
		"name": "Curse of Frailty",
		"desc": "Weakens the target: it deals -30% damage for 2 rounds.",
		"axis": "warlock",
		"mana_cost": 3,
		"cooldown": 1,
		"power": 0.3,
		"kind": "magic",
		"target": "enemy",
		"status": {"id": "weakened", "duration": 2, "mult": 0.7},
	},
	"life_drain":
	{
		"id": "life_drain",
		"name": "Life Drain",
		"desc": "Magic damage; heal yourself for half of it.",
		"axis": "warlock",
		"mana_cost": 4,
		"cooldown": 1,
		"power": 1.2,
		"kind": "magic",
		"target": "enemy",
		"leech": 0.5,
	},
	"eldritch_blast":
	{
		"id": "eldritch_blast",
		"name": "Eldritch Blast",
		"desc": "Raw otherworldly damage.",
		"axis": "warlock",
		"mana_cost": 3,
		"cooldown": 0,
		"power": 1.4,
		"kind": "magic",
		"target": "enemy",
	},
	"doom":
	{
		"id": "doom",
		"name": "Doom",
		"desc": "Signature: blast and weaken every enemy.",
		"axis": "warlock",
		"mana_cost": 9,
		"cooldown": 4,
		"power": 1.1,
		"kind": "magic",
		"target": "all_enemies",
		"status": {"id": "weakened", "duration": 2, "mult": 0.7},
		"signature": true,
	},
	# --- Bard (sånger: buffar hela partyt) ---
	"cutting_words":
	{
		"id": "cutting_words",
		"name": "Cutting Words",
		"desc": "Mock an enemy: damage and -30% damage dealt.",
		"axis": "bard",
		"mana_cost": 3,
		"cooldown": 1,
		"power": 0.8,
		"kind": "magic",
		"target": "enemy",
		"status": {"id": "weakened", "duration": 2, "mult": 0.7},
	},
	"rest_song":
	{
		"id": "rest_song",
		"name": "Song of Rest",
		"desc": "A soothing song heals the whole party a little.",
		"axis": "bard",
		"mana_cost": 5,
		"cooldown": 2,
		"power": 0.5,
		"kind": "heal",
		"target": "all_allies",
	},
	"inspire":
	{
		"id": "inspire",
		"name": "Inspire",
		"desc": "The whole party deals +30% damage for 2 rounds.",
		"axis": "bard",
		"mana_cost": 5,
		"cooldown": 3,
		"power": 0.0,
		"kind": "buff",
		"target": "all_allies",
		"status": {"id": "atk_up", "duration": 2, "mult": 1.3},
	},
	"grand_finale":
	{
		"id": "grand_finale",
		"name": "Grand Finale",
		"desc": "Signature: the party deals +50% damage for 2 rounds.",
		"axis": "bard",
		"mana_cost": 8,
		"cooldown": 5,
		"power": 0.0,
		"kind": "buff",
		"target": "all_allies",
		"status": {"id": "atk_up", "duration": 2, "mult": 1.5},
		"signature": true,
	},
}

const AXES := ["tank", "healer", "mage", "rogue", "barbarian", "ranger", "warlock", "bard"]
const SIGNATURE_BY_AXIS := {
	"tank": "bulwark",
	"healer": "resurrect",
	"mage": "meteor",
	"rogue": "shadow_dance",
	"barbarian": "rampage",
	"ranger": "deadeye",
	"warlock": "doom",
	"bard": "grand_finale",
}


static func get_ability(id: String) -> Dictionary:
	return CATALOG.get(id, {})


static func abilities_for_axis(axis: String) -> Array:
	var result: Array = []
	for id in CATALOG:
		var ability: Dictionary = CATALOG[id]
		if ability.get("axis", "") == axis and not ability.get("signature", false):
			result.append(id)
	return result
