class_name Dungeons
## Dungeonkatalog: spelet växer på djupet genom nya, svårare dungeons.
## En dungeon låses upp genom att besegra bossen i den föregående plus
## ett nivåkrav. depth_offset matas in i fiendeskalningen så att samma
## kurva fortsätter: dungeon 2 börjar där dungeon 1 slutade – både
## fiender och belöningar (Essens/XP) skalar automatiskt vidare.

const CATALOG := {
	"cave_depths":
	{
		"id": "cave_depths",
		"tier": 1,
		"name": "The Cave Depths",
		"tagline": "Where every descent begins.",
		"depth_offset": 0,
		"entry_level": 1,
		"gates": {4: 3, 7: 5},
	},
	"sunken_crypt":
	{
		"id": "sunken_crypt",
		"tier": 2,
		"name": "The Sunken Crypt",
		"tagline": "Drowned halls, restless dead.",
		"depth_offset": 8,
		"entry_level": 6,
		"gates": {4: 8, 7: 10},
	},
	"ember_halls":
	{
		"id": "ember_halls",
		"tier": 3,
		"name": "The Ember Halls",
		"tagline": "The heat of the world's forge.",
		"depth_offset": 16,
		"entry_level": 11,
		"gates": {4: 13, 7: 15},
	},
}

const ORDER := ["cave_depths", "sunken_crypt", "ember_halls"]
const DEFAULT := "cave_depths"


static func get_dungeon(id: String) -> Dictionary:
	return CATALOG.get(id, CATALOG[DEFAULT])


## Dungeonen före denna i progressionen, "" för den första.
static func previous_id(id: String) -> String:
	var index := ORDER.find(id)
	return ORDER[index - 1] if index > 0 else ""


static func is_unlocked(party: PartyState, id: String) -> bool:
	var dungeon := get_dungeon(id)
	if party.level < int(dungeon["entry_level"]):
		return false
	var previous := previous_id(id)
	return previous == "" or party.clears_of(previous) > 0


## UI-text som förklarar vad som saknas för en låst dungeon.
static func lock_reason(party: PartyState, id: String) -> String:
	var dungeon := get_dungeon(id)
	var parts: Array = []
	var previous := previous_id(id)
	if previous != "" and party.clears_of(previous) == 0:
		parts.append("clear %s" % get_dungeon(previous)["name"])
	if party.level < int(dungeon["entry_level"]):
		parts.append("reach party level %d" % int(dungeon["entry_level"]))
	return "Locked: " + " and ".join(parts) if not parts.is_empty() else ""


## Den djupaste upplåsta dungeonen – rimlig default i hubben.
static func highest_unlocked(party: PartyState) -> String:
	var best := DEFAULT
	for id in ORDER:
		if is_unlocked(party, id):
			best = id
	return best
