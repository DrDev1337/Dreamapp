class_name LevelUp
## Party-level-up (party_design.md): vid varje ny partynivå väljs EN
## uppgradering av tre, kopplade till tre olika hjältar. Valen driver
## hjältarna mot tank/healer/mage/rogue; CLASS_UNLOCK_PICKS val åt samma
## håll på samma hjälte låser klassidentitet + signaturförmåga.

const AXIS_LABELS := {"tank": "Tank", "healer": "Healer", "mage": "Mage", "rogue": "Rogue"}

const STAT_CHOICES := {
	"tank": {"stats": {"max_hp": 8, "armor": 1}, "desc": "+8 HP, +1 armor"},
	"healer":
	{"stats": {"magic": 2, "max_mana": 3, "max_hp": 3}, "desc": "+2 magic, +3 mana, +3 HP"},
	"mage": {"stats": {"magic": 3, "max_mana": 2}, "desc": "+3 magic, +2 mana"},
	"rogue": {"stats": {"attack": 2, "speed": 1}, "desc": "+2 attack, +1 speed"},
}


## Returnerar 3 val för 3 olika hjältar. Varje val:
## {hero_index, hero_name, axis, label, desc, stats, ability_id}
static func generate_choices(party: PartyState, rng: RandomNumberGenerator) -> Array:
	var indices: Array = range(party.heroes.size())
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = indices[i]
		indices[i] = indices[j]
		indices[j] = swap
	var choices: Array = []
	for k in mini(3, indices.size()):
		var hero_index: int = indices[k]
		var hero: Hero = party.heroes[hero_index]
		var axis := _pick_axis(hero, rng)
		var choice := {
			"hero_index": hero_index,
			"hero_name": hero.hero_name,
			"axis": axis,
			"label": "%s – %s" % [hero.hero_name, AXIS_LABELS[axis]],
			"stats": STAT_CHOICES[axis]["stats"],
			"desc": STAT_CHOICES[axis]["desc"],
			"ability_id": "",
		}
		var unlearned: Array = []
		for id in Abilities.abilities_for_axis(axis):
			if id not in hero.ability_ids:
				unlearned.append(id)
		if not unlearned.is_empty():
			var ability_id: String = unlearned[rng.randi_range(0, unlearned.size() - 1)]
			choice["ability_id"] = ability_id
			var ability := Abilities.get_ability(ability_id)
			choice["desc"] = String(choice["desc"]) + " + new ability: " + String(ability["name"])
		choices.append(choice)
	return choices


## En hjälte med påbörjad riktning fortsätter oftast åt samma håll –
## identitet ska kännas, men avstickare ska vara möjliga.
static func _pick_axis(hero: Hero, rng: RandomNumberGenerator) -> String:
	if hero.class_identity != "":
		return hero.class_identity
	var best_axis := ""
	var best := 0
	for axis in Abilities.AXES:
		if int(hero.axis_points[axis]) > best:
			best = int(hero.axis_points[axis])
			best_axis = axis
	if best_axis != "" and rng.randf() < 0.85:
		return best_axis
	return Abilities.AXES[rng.randi_range(0, Abilities.AXES.size() - 1)]


## Applicerar ett val. Returnerar true om klassidentitet låstes upp.
static func apply_choice(party: PartyState, choice: Dictionary) -> bool:
	var hero: Hero = party.heroes[int(choice["hero_index"])]
	var stats: Dictionary = choice.get("stats", {})
	for stat in stats:
		hero.bonus_stats[stat] = int(hero.bonus_stats.get(stat, 0)) + int(stats[stat])
	var ability_id: String = choice.get("ability_id", "")
	if ability_id != "":
		hero.learn_ability(ability_id)
	return hero.apply_class_pick(choice.get("axis", ""))
