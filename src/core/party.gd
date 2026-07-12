class_name PartyState
extends RefCounted
## Partyt – savefilens rot (ersätter den gamla solo-CharacterState).
## Äger de fem hjältarna, gemensam XP/nivå, bankad Essens, permanenta
## uppgraderingar, dödshögen och onboarding-flaggor.

var party_name := "Nameless"
var heroes: Array = []  # Array[Hero], index 0-1 = frontrad
var level := 1
var xp := 0
var banked_essence := 0
var permanent_upgrades := {}
var pending_boosts: Array = []
var death_pile := {}  # {depth, essence, loot, dungeon_id} – max en aktiv hög (US-2.5)
var bosses_defeated := 0
var dungeon_clears := {}  # dungeon_id -> antal bossar besegrade där
var tutorial_flags := {}
var runs_completed := 0
var deaths := 0  # partywipes


## Skapar ett party. Varje element är en String (bara namn) eller en
## Dictionary {name, ability_id} – startförmågan ger val från strid 1.
static func create(hero_specs: Array) -> PartyState:
	var party := PartyState.new()
	for spec in hero_specs:
		var hero := Hero.new()
		if spec is Dictionary:
			hero.hero_name = String(spec.get("name", "Hero"))
			var ability_id := String(spec.get("ability_id", ""))
			if ability_id != "":
				hero.learn_ability(ability_id)
		else:
			hero.hero_name = String(spec)
		party.heroes.append(hero)
	party.party_name = party.heroes[0].hero_name if not party.heroes.is_empty() else "Party"
	return party


func xp_to_next() -> int:
	return Balance.xp_for_level(level)


## Ger XP till partyt; returnerar antal nya nivåer (uppgraderingsval).
func gain_xp(amount: int) -> int:
	xp += amount
	var levels_gained := 0
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		levels_gained += 1
	return levels_gained


func essence_gain_multiplier() -> float:
	return 1.0 + Upgrades.permanent_essence_bonus(permanent_upgrades)


func has_death_pile() -> bool:
	return not death_pile.is_empty()


func hero_row(index: int) -> String:
	return "front" if index < Balance.FRONT_ROW_SIZE else "back"


func clears_of(dungeon_id: String) -> int:
	return int(dungeon_clears.get(dungeon_id, 0))


func to_dict() -> Dictionary:
	return {
		"party_name": party_name,
		"heroes": heroes.map(func(hero): return hero.to_dict()),
		"level": level,
		"xp": xp,
		"banked_essence": banked_essence,
		"permanent_upgrades": permanent_upgrades,
		"pending_boosts": pending_boosts,
		"death_pile": death_pile,
		"bosses_defeated": bosses_defeated,
		"dungeon_clears": dungeon_clears,
		"tutorial_flags": tutorial_flags,
		"runs_completed": runs_completed,
		"deaths": deaths,
	}


static func from_dict(data: Dictionary) -> PartyState:
	var party := PartyState.new()
	party.party_name = data.get("party_name", "Party")
	for hero_data in data.get("heroes", []):
		party.heroes.append(Hero.from_dict(hero_data))
	party.level = int(data.get("level", 1))
	party.xp = int(data.get("xp", 0))
	party.banked_essence = int(data.get("banked_essence", 0))
	party.permanent_upgrades = data.get("permanent_upgrades", {})
	party.pending_boosts = data.get("pending_boosts", [])
	party.death_pile = data.get("death_pile", {})
	party.bosses_defeated = int(data.get("bosses_defeated", 0))
	party.dungeon_clears = data.get("dungeon_clears", {})
	party.tutorial_flags = data.get("tutorial_flags", {})
	party.runs_completed = int(data.get("runs_completed", 0))
	party.deaths = int(data.get("deaths", 0))
	return party
