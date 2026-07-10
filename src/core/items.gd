class_name Items
## Loot-generering (US-5.1): 3 rariteter, tre slots.
## Designbeslut (öppen fråga 3 i specen): episka föremål säkras
## omedelbart vid upphämtning – att tappa dem vore för hårt.

const RARITIES := ["common", "rare", "epic"]
const RARITY_LABELS := {"common": "Vanlig", "rare": "Sällsynt", "epic": "Episk"}
const RARITY_STAT_MULT := {"common": 1.0, "rare": 1.6, "epic": 2.5}

const BASES := [
	{"slot": "weapon", "name": "Svärd", "stat": "attack", "base": 3},
	{"slot": "weapon", "name": "Stav", "stat": "magic", "base": 3},
	{"slot": "weapon", "name": "Dolk", "stat": "attack", "base": 2, "extra": {"speed": 1}},
	{"slot": "armor", "name": "Läderharnesk", "stat": "armor", "base": 1, "extra": {"max_hp": 6}},
	{"slot": "armor", "name": "Ringbrynja", "stat": "armor", "base": 2},
	{"slot": "trinket", "name": "Amulett", "stat": "max_mana", "base": 3},
	{"slot": "trinket", "name": "Ring", "stat": "max_hp", "base": 8},
]


static func roll_rarity(rng: RandomNumberGenerator, bonus_rarity := false) -> String:
	var weights := Balance.RARITY_WEIGHTS.duplicate()
	if bonus_rarity:  # Lyckoamulett-boost (US-2.6)
		weights = {"common": 45, "rare": 40, "epic": 15}
	var total := 0
	for r in weights:
		total += int(weights[r])
	var roll := rng.randi_range(1, total)
	var acc := 0
	for r in RARITIES:
		acc += int(weights[r])
		if roll <= acc:
			return r
	return "common"


## Genererar ett föremål skalat efter djup.
static func generate(
	rng: RandomNumberGenerator, depth: int, bonus_rarity := false, force_rarity := ""
) -> Dictionary:
	var base: Dictionary = BASES[rng.randi_range(0, BASES.size() - 1)]
	var rarity := force_rarity if force_rarity != "" else roll_rarity(rng, bonus_rarity)
	var mult: float = RARITY_STAT_MULT[rarity] * (1.0 + 0.15 * (depth - 1))
	var stats := {}
	stats[base["stat"]] = maxi(1, int(base["base"] * mult))
	for extra_stat in base.get("extra", {}):
		stats[extra_stat] = maxi(1, int(int(base["extra"][extra_stat]) * mult))
	return {
		"name": "%s %s" % [RARITY_LABELS[rarity], String(base["name"]).to_lower()],
		"slot": base["slot"],
		"rarity": rarity,
		"stats": stats,
		"secured": rarity == "epic",  # episkt säkras direkt
	}


static func describe(item: Dictionary) -> String:
	if item.is_empty():
		return "–"
	var parts: Array = []
	for stat in item.get("stats", {}):
		parts.append("+%d %s" % [int(item["stats"][stat]), stat_label(stat)])
	return "%s (%s)" % [item["name"], ", ".join(parts)]


static func stat_label(stat: String) -> String:
	match stat:
		"max_hp":
			return "HP"
		"attack":
			return "attack"
		"magic":
			return "magi"
		"speed":
			return "fart"
		"armor":
			return "rustning"
		"max_mana":
			return "mana"
	return stat


## Enkel jämförelse: summan av statvärden. Räcker för MVP-auto-förslag.
static func power_score(item: Dictionary) -> int:
	var score := 0
	for stat in item.get("stats", {}):
		score += int(item["stats"][stat])
	return score
