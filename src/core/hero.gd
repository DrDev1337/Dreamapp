class_name Hero
extends RefCounted
## En hjälte i partyt. Ren data + regler, serialiseras med to_dict/from_dict.
## Klassidentitet växer ur uppgraderingsval (party_design.md): 3 val åt
## samma håll låser klassen och ger signaturförmågan.

var hero_name := "Nameless"
var axis_points := {"tank": 0, "healer": 0, "mage": 0, "rogue": 0}
var class_identity := ""
var ability_ids: Array = ["basic_attack"]
var bonus_stats := {"max_hp": 0, "attack": 0, "magic": 0, "speed": 0, "armor": 0, "max_mana": 0}
var equipment := {"weapon": {}, "armor": {}, "trinket": {}}


## Registrerar ett klassval. Returnerar true om klassidentitet just låstes.
func apply_class_pick(axis: String) -> bool:
	if axis not in axis_points:
		return false
	axis_points[axis] += 1
	if class_identity == "" and axis_points[axis] >= Balance.CLASS_UNLOCK_PICKS:
		class_identity = axis
		var signature: String = Abilities.SIGNATURE_BY_AXIS[axis]
		if signature not in ability_ids:
			ability_ids.append(signature)
		return true
	return false


func learn_ability(id: String) -> void:
	if id not in ability_ids:
		ability_ids.append(id)


## Aktiva förmågor i strid: basattack + max 3 övriga (mobilskärm).
func combat_ability_ids() -> Array:
	var actives: Array = ["basic_attack"]
	for id in ability_ids:
		if id != "basic_attack" and actives.size() < 4:
			actives.append(id)
	return actives


## Total stat: hjältebas + party-level + egna val + utrustning + hubbköp.
func total_stat(stat: String, party) -> int:
	var base := 0
	var level: int = party.level
	match stat:
		"max_hp":
			base = Balance.HERO_BASE_HP + (level - 1) * 2
		"attack":
			base = Balance.HERO_BASE_ATTACK
		"magic":
			base = Balance.HERO_BASE_MAGIC
		"speed":
			base = Balance.HERO_BASE_SPEED
		"armor":
			base = Balance.HERO_BASE_ARMOR
		"max_mana":
			base = Balance.HERO_BASE_MANA
	var total: int = base + int(bonus_stats.get(stat, 0))
	total += Upgrades.permanent_stat_bonus(party.permanent_upgrades, stat)
	for slot in equipment:
		var item: Dictionary = equipment[slot]
		if not item.is_empty():
			total += int(item.get("stats", {}).get(stat, 0))
	return total


func to_dict() -> Dictionary:
	return {
		"hero_name": hero_name,
		"axis_points": axis_points,
		"class_identity": class_identity,
		"ability_ids": ability_ids,
		"bonus_stats": bonus_stats,
		"equipment": equipment,
	}


static func from_dict(data: Dictionary) -> Hero:
	var hero := Hero.new()
	hero.hero_name = data.get("hero_name", "Nameless")
	hero.axis_points = data.get("axis_points", {"tank": 0, "healer": 0, "mage": 0, "rogue": 0})
	hero.class_identity = data.get("class_identity", "")
	hero.ability_ids = data.get("ability_ids", ["basic_attack"])
	hero.bonus_stats = data.get("bonus_stats", hero.bonus_stats)
	hero.equipment = data.get("equipment", {"weapon": {}, "armor": {}, "trinket": {}})
	return hero
