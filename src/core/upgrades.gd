class_name Upgrades
## Uppgraderingskatalog (US-2.6): permanenta (överlever döden, US-4.5)
## och tillfälliga boosts. Designbeslut (öppen fråga 1): boosts köpta
## vid checkpoint gäller resten av nuvarande run, köpta i hubben gäller
## nästa run.

# 6 permanenta uppgraderingar (kravet är minst 5).
const PERMANENT := {
	"vitality":
	{
		"name": "Vitality",
		"desc": "+4 max HP per rank (all heroes)",
		"stat": "max_hp",
		"per_rank": 4,
		"base_cost": 50,
		"max_rank": 10,
	},
	"strength":
	{
		"name": "Strength",
		"desc": "+1 attack per rank (all heroes)",
		"stat": "attack",
		"per_rank": 1,
		"base_cost": 60,
		"max_rank": 10,
	},
	"wisdom":
	{
		"name": "Wisdom",
		"desc": "+1 magic per rank (all heroes)",
		"stat": "magic",
		"per_rank": 1,
		"base_cost": 60,
		"max_rank": 10,
	},
	"clarity":
	{
		"name": "Clarity",
		"desc": "+2 max mana per rank (all heroes)",
		"stat": "max_mana",
		"per_rank": 2,
		"base_cost": 50,
		"max_rank": 8,
	},
	"toughness":
	{
		"name": "Toughness",
		"desc": "+1 armor per rank (all heroes)",
		"stat": "armor",
		"per_rank": 1,
		"base_cost": 80,
		"max_rank": 5,
	},
	"essence_catcher":
	{
		"name": "Essence Catcher",
		"desc": "+10% Essence per rank",
		"essence_bonus": 0.10,
		"base_cost": 70,
		"max_rank": 5,
	},
}

# 4 tillfälliga boosts (kravet är minst 3).
const TEMPORARY := {
	"battle_luck":
	{
		"name": "Battle Luck",
		"desc": "+25% damage this run",
		"cost": 40,
		"effect": {"damage_mult": 1.25},
	},
	"lucky_amulet":
	{
		"name": "Lucky Amulet",
		"desc": "Better odds of rare loot",
		"cost": 35,
		"effect": {"bonus_rarity": true},
	},
	"essence_rush":
	{
		"name": "Essence Rush",
		"desc": "+50% Essence this run",
		"cost": 45,
		"effect": {"essence_mult": 1.5},
	},
	"blessing":
	{
		"name": "Blessing",
		"desc": "+8 max HP per hero this run",
		"cost": 30,
		"effect": {"start_hp_bonus": 8},
	},
}


static func permanent_cost(id: String, current_rank: int) -> int:
	var up: Dictionary = PERMANENT.get(id, {})
	if up.is_empty():
		return 0
	return int(int(up["base_cost"]) * pow(1.7, current_rank))


static func permanent_stat_bonus(owned: Dictionary, stat: String) -> int:
	var bonus := 0
	for id in owned:
		var up: Dictionary = PERMANENT.get(id, {})
		if up.get("stat", "") == stat:
			bonus += int(up["per_rank"]) * int(owned[id])
	return bonus


static func permanent_essence_bonus(owned: Dictionary) -> float:
	var bonus := 0.0
	for id in owned:
		var up: Dictionary = PERMANENT.get(id, {})
		if up.has("essence_bonus"):
			bonus += float(up["essence_bonus"]) * int(owned[id])
	return bonus


## Köper permanent uppgradering med given valuta-pool.
## pool = "banked" (hubben) eller "carried" (checkpoint).
## Returnerar true om köpet gick igenom.
static func buy_permanent(party: PartyState, id: String, run: RunState = null) -> bool:
	var rank := int(party.permanent_upgrades.get(id, 0))
	var up: Dictionary = PERMANENT.get(id, {})
	if up.is_empty() or rank >= int(up["max_rank"]):
		return false
	var cost := permanent_cost(id, rank)
	if not _spend(party, run, cost):
		return false
	party.permanent_upgrades[id] = rank + 1
	return true


## Köper en tillfällig boost. Vid checkpoint (run != null och fortsätter)
## aktiveras den direkt i pågående run, annars läggs den till nästa run.
static func buy_temporary(
	party: PartyState, id: String, run: RunState = null, apply_now := false
) -> bool:
	var boost: Dictionary = TEMPORARY.get(id, {})
	if boost.is_empty():
		return false
	if not _spend(party, run, int(boost["cost"])):
		return false
	var effect: Dictionary = boost["effect"].duplicate()
	effect["id"] = id
	if apply_now and run != null:
		run.active_boosts.append(effect)
		for hero_combat in run.heroes_combat:
			if effect.has("start_hp_bonus"):
				hero_combat["max_hp"] = int(hero_combat["max_hp"]) + int(effect["start_hp_bonus"])
				if int(hero_combat["hp"]) > 0:
					hero_combat["hp"] = int(hero_combat["hp"]) + int(effect["start_hp_bonus"])
			if effect.has("damage_mult"):
				hero_combat["damage_mult"] = (
					float(hero_combat.get("damage_mult", 1.0)) * float(effect["damage_mult"])
				)
	else:
		party.pending_boosts.append(effect)
	return true


## Vid checkpoint spenderas buren Essens, i hubben bankad (US-2.2, US-2.6).
static func _spend(party: PartyState, run: RunState, cost: int) -> bool:
	if run != null and not run.finished:
		if run.carried_essence < cost:
			return false
		run.carried_essence -= cost
	else:
		if party.banked_essence < cost:
			return false
		party.banked_essence -= cost
	return true
