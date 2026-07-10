class_name LevelUp
## Genererar level-up-val (US-4.2): 2-3 alternativ som drar mot
## fighter, mage eller rogue. Ett val = statbonus och/eller ny ability.

const AXIS_LABELS := {"fighter": "Fighter", "mage": "Mage", "rogue": "Rogue"}

const STAT_CHOICES := {
	"fighter": {"stats": {"max_hp": 8, "attack": 2}, "desc": "+8 HP, +2 attack"},
	"mage": {"stats": {"magic": 3, "max_mana": 3}, "desc": "+3 magic, +3 mana"},
	"rogue":
	{"stats": {"speed": 1, "attack": 1, "max_hp": 4}, "desc": "+1 speed, +1 attack, +4 HP"},
}


## Returnerar 3 val, ett per riktning. Varje val:
## {axis, label, desc, stats, ability_id (kan vara "")}
static func generate_choices(character: CharacterState, rng: RandomNumberGenerator) -> Array:
	var choices: Array = []
	for axis in ["fighter", "mage", "rogue"]:
		var choice := {
			"axis": axis,
			"label": AXIS_LABELS[axis],
			"stats": STAT_CHOICES[axis]["stats"],
			"desc": STAT_CHOICES[axis]["desc"],
			"ability_id": "",
		}
		# Erbjud en ny ability från riktningen om någon saknas.
		var unlearned: Array = []
		for id in Abilities.abilities_for_axis(axis):
			if id not in character.ability_ids:
				unlearned.append(id)
		if not unlearned.is_empty():
			var ability_id: String = unlearned[rng.randi_range(0, unlearned.size() - 1)]
			choice["ability_id"] = ability_id
			var ab := Abilities.get_ability(ability_id)
			choice["desc"] = String(choice["desc"]) + " + new ability: " + String(ab["name"])
		choices.append(choice)
	return choices


## Applicerar ett val. Returnerar true om klassidentitet låstes upp.
static func apply_choice(character: CharacterState, choice: Dictionary) -> bool:
	var stats: Dictionary = choice.get("stats", {})
	for stat in stats:
		character.bonus_stats[stat] = int(character.bonus_stats.get(stat, 0)) + int(stats[stat])
	var ability_id: String = choice.get("ability_id", "")
	if ability_id != "":
		character.learn_ability(ability_id)
	return character.apply_class_pick(choice.get("axis", ""))
