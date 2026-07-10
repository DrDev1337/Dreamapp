class_name CharacterState
## Persistent karaktärsdata (US-4.x). Ren data + regler, ingen UI.
## Serialiseras med to_dict/from_dict för save-systemet (US-11.2).

var character_name := "Namnlös"
var level := 1
var xp := 0
var class_axis_points := {"fighter": 0, "mage": 0, "rogue": 0}
var class_identity := ""  # "" tills 3 val i samma riktning (US-4.2)
var ability_ids: Array = ["basic_attack", "focus_strike"]  # svag start (US-4.1)
var bonus_stats := {"max_hp": 0, "attack": 0, "magic": 0, "speed": 0, "armor": 0, "max_mana": 0}
var banked_essence := 0  # säkrad Essens, spenderbar i hubben
var permanent_upgrades := {}  # upgrade_id -> rank (US-4.5)
var pending_boosts: Array = []  # tillfälliga boosts inför nästa run (US-2.6)
var equipment := {"weapon": {}, "armor": {}, "trinket": {}}  # säkrad utrustning
var death_pile := {}  # {depth, essence, loot: []} – max en aktiv hög (US-2.5)
var bosses_defeated := 0
var tutorial_flags := {}  # onboarding, max 3 popups (US-9.1)
var runs_completed := 0
var deaths := 0


func xp_to_next() -> int:
	return Balance.xp_for_level(level)


## Ger XP; returnerar antal nya levels (level-up-val hanteras av UI-lagret).
func gain_xp(amount: int) -> int:
	xp += amount
	var levels_gained := 0
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		levels_gained += 1
	return levels_gained


## Registrerar ett klassval (US-4.2). Returnerar true om klassidentitet just låstes upp.
func apply_class_pick(axis: String) -> bool:
	if axis in class_axis_points:
		class_axis_points[axis] += 1
		if class_identity == "" and class_axis_points[axis] >= Balance.CLASS_UNLOCK_PICKS:
			class_identity = axis
			var signature: String = Abilities.SIGNATURE_BY_AXIS[axis]
			if signature not in ability_ids:
				ability_ids.append(signature)
			return true
	return false


func learn_ability(id: String) -> void:
	if id not in ability_ids:
		ability_ids.append(id)


## Aktiva abilities i strid: basattack + max 4 övriga (US-3.2).
func combat_ability_ids() -> Array:
	var actives: Array = ["basic_attack"]
	for id in ability_ids:
		if id != "basic_attack" and actives.size() < 5:
			actives.append(id)
	return actives


# --- Beräknade stats: bas + permanenta uppgraderingar + bonusar + utrustning ---


func total_stat(stat: String) -> int:
	var base := 0
	match stat:
		"max_hp":
			base = Balance.PLAYER_BASE_HP + (level - 1) * 6
		"attack":
			base = Balance.PLAYER_BASE_ATTACK + (level - 1) * 1
		"magic":
			base = Balance.PLAYER_BASE_MAGIC + (level - 1) * 1
		"speed":
			base = Balance.PLAYER_BASE_SPEED
		"armor":
			base = Balance.PLAYER_BASE_ARMOR
		"max_mana":
			base = Balance.PLAYER_BASE_MANA + (level - 1) * 1
	var total: int = base + int(bonus_stats.get(stat, 0))
	total += Upgrades.permanent_stat_bonus(permanent_upgrades, stat)
	for slot in equipment:
		var item: Dictionary = equipment[slot]
		if not item.is_empty():
			total += int(item.get("stats", {}).get(stat, 0))
	return total


func essence_gain_multiplier() -> float:
	return 1.0 + Upgrades.permanent_essence_bonus(permanent_upgrades)


func has_death_pile() -> bool:
	return not death_pile.is_empty()


# --- Serialisering ---


func to_dict() -> Dictionary:
	return {
		"character_name": character_name,
		"level": level,
		"xp": xp,
		"class_axis_points": class_axis_points,
		"class_identity": class_identity,
		"ability_ids": ability_ids,
		"bonus_stats": bonus_stats,
		"banked_essence": banked_essence,
		"permanent_upgrades": permanent_upgrades,
		"pending_boosts": pending_boosts,
		"equipment": equipment,
		"death_pile": death_pile,
		"bosses_defeated": bosses_defeated,
		"tutorial_flags": tutorial_flags,
		"runs_completed": runs_completed,
		"deaths": deaths,
	}


static func from_dict(data: Dictionary) -> CharacterState:
	var c := CharacterState.new()
	c.character_name = data.get("character_name", "Namnlös")
	c.level = int(data.get("level", 1))
	c.xp = int(data.get("xp", 0))
	c.class_axis_points = data.get("class_axis_points", {"fighter": 0, "mage": 0, "rogue": 0})
	c.class_identity = data.get("class_identity", "")
	c.ability_ids = data.get("ability_ids", ["basic_attack", "focus_strike"])
	c.bonus_stats = data.get("bonus_stats", c.bonus_stats)
	c.banked_essence = int(data.get("banked_essence", 0))
	c.permanent_upgrades = data.get("permanent_upgrades", {})
	c.pending_boosts = data.get("pending_boosts", [])
	c.equipment = data.get("equipment", {"weapon": {}, "armor": {}, "trinket": {}})
	c.death_pile = data.get("death_pile", {})
	c.bosses_defeated = int(data.get("bosses_defeated", 0))
	c.tutorial_flags = data.get("tutorial_flags", {})
	c.runs_completed = int(data.get("runs_completed", 0))
	c.deaths = int(data.get("deaths", 0))
	return c
