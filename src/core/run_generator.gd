class_name RunGenerator
## Procedurgenerering av runs (US-7.1). Slumpade rum från pooler,
## men fasta regler: checkpoint efter rum 3 och 6, miniboss i rum 4,
## boss i rum 8. Dödsplatsen definieras av djup (US-7.2), så högen
## placeras på motsvarande djup oavsett ny layout.


## Returnerar en Array av rum:
## {depth, type ("combat"/"chest"/"miniboss"/"boss"), enemy_ids: [],
##  checkpoint_after: bool, has_pile: bool}
static func generate(rng: RandomNumberGenerator, pile_depth: int = -1) -> Array:
	var rooms: Array = []
	for depth in range(1, Balance.RUN_ROOM_COUNT + 1):
		var room := {
			"depth": depth,
			"type": "combat",
			"enemy_ids": [],
			"checkpoint_after": depth in Balance.CHECKPOINT_AFTER_ROOMS,
			"has_pile": depth == pile_depth,
		}
		if depth == Balance.BOSS_ROOM:
			room["type"] = "boss"
			room["enemy_ids"] = ["heart_of_depths"]
		elif depth == Balance.MINIBOSS_ROOM:
			room["type"] = "miniboss"
			room["enemy_ids"] = ["grave_warden"]
		elif depth > 1 and rng.randf() < Balance.CHEST_ROOM_CHANCE and _last_type(rooms) != "chest":
			room["type"] = "chest"
		else:
			room["enemy_ids"] = _roll_enemies(rng, depth)
		rooms.append(room)
	return rooms


static func _last_type(rooms: Array) -> String:
	return rooms[-1]["type"] if not rooms.is_empty() else ""


static func _roll_enemies(rng: RandomNumberGenerator, depth: int) -> Array:
	var pool := Enemies.pool_for_depth(depth)
	var count := 1
	if depth >= 6:
		count = rng.randi_range(2, 3)
	elif depth >= 3:
		count = 2
	elif depth >= 2:
		count = rng.randi_range(1, 2)
	var ids: Array = []
	for i in count:
		ids.append(pool[rng.randi_range(0, pool.size() - 1)])
	return ids


static func room_label(room: Dictionary) -> String:
	match String(room["type"]):
		"combat":
			return "Strid"
		"chest":
			return "Skattkammare"
		"miniboss":
			return "Miniboss"
		"boss":
			return "BOSS"
	return "?"
