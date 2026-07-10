class_name Enemies
## Fiendekatalog (US-3.3): minst 5 typer med distinkta beteenden.
## behavior styr AI:n i CombatEngine:
##   "melee"    – attackerar varje tur
##   "ranged"   – attackerar, ignorerar delar av rustning
##   "healer"   – helar skadad allierad, annars attack
##   "tank"     – växlar mellan sköld och attack
##   "berserker"– dubbel skada under 50% hp
##   "miniboss" / "boss" – egna mönster (US-6.x)

const CATALOG := {
	"cave_rat":
	{
		"id": "cave_rat",
		"name": "Grottråtta",
		"behavior": "melee",
		"hp": 18,
		"attack": 5,
		"speed": 6,
		"armor": 0,
		"essence_mult": 0.8,
		"xp_mult": 0.8,
	},
	"skeleton_archer":
	{
		"id": "skeleton_archer",
		"name": "Skelettskytt",
		"behavior": "ranged",
		"hp": 14,
		"attack": 7,
		"speed": 5,
		"armor": 0,
		"essence_mult": 1.0,
		"xp_mult": 1.0,
	},
	"cultist_healer":
	{
		"id": "cultist_healer",
		"name": "Kultist",
		"behavior": "healer",
		"hp": 16,
		"attack": 4,
		"speed": 4,
		"armor": 0,
		"heal_power": 8,
		"essence_mult": 1.2,
		"xp_mult": 1.2,
	},
	"stone_golem":
	{
		"id": "stone_golem",
		"name": "Stengolem",
		"behavior": "tank",
		"hp": 34,
		"attack": 6,
		"speed": 2,
		"armor": 3,
		"essence_mult": 1.3,
		"xp_mult": 1.3,
	},
	"imp":
	{
		"id": "imp",
		"name": "Vätte",
		"behavior": "berserker",
		"hp": 15,
		"attack": 6,
		"speed": 7,
		"armor": 0,
		"essence_mult": 1.0,
		"xp_mult": 1.0,
	},
	"grave_warden":
	{
		"id": "grave_warden",
		"name": "Gravväktaren",
		"behavior": "miniboss",
		"hp": 70,
		"attack": 9,
		"speed": 4,
		"armor": 2,
		"essence_mult": Balance.ESSENCE_MINIBOSS_MULT,
		"xp_mult": 3.0,
		"is_miniboss": true,
	},
	"heart_of_depths":
	{
		"id": "heart_of_depths",
		"name": "Djupets Hjärta",
		"behavior": "boss",
		"hp": 140,
		"attack": 11,
		"speed": 5,
		"armor": 2,
		"essence_mult": Balance.ESSENCE_BOSS_MULT,
		"xp_mult": 8.0,
		"is_boss": true,
	},
}

# Vilka vanliga fiender som kan dyka upp per djupintervall.
const SPAWN_POOL := {
	1: ["cave_rat", "cave_rat", "imp"],
	2: ["cave_rat", "skeleton_archer", "imp"],
	3: ["skeleton_archer", "imp", "cultist_healer"],
	5: ["skeleton_archer", "cultist_healer", "stone_golem", "imp"],
	7: ["stone_golem", "cultist_healer", "skeleton_archer", "imp"],
}


static func get_enemy(id: String) -> Dictionary:
	return CATALOG.get(id, {})


static func pool_for_depth(depth: int) -> Array:
	var best_key := 1
	for key in SPAWN_POOL:
		if key <= depth and key > best_key:
			best_key = key
	return SPAWN_POOL[best_key]


## Skapar en skalad fiendeinstans för ett givet djup (US-1.2).
static func spawn(id: String, depth: int) -> Dictionary:
	var base: Dictionary = get_enemy(id)
	if base.is_empty():
		return {}
	var hp_scale := 1.0 + Balance.ENEMY_HP_DEPTH_MULT * (depth - 1)
	var dmg_scale := 1.0 + Balance.ENEMY_DMG_DEPTH_MULT * (depth - 1)
	return {
		"id": base["id"],
		"name": base["name"],
		"behavior": base["behavior"],
		"max_hp": int(base["hp"] * hp_scale),
		"hp": int(base["hp"] * hp_scale),
		"attack": int(base["attack"] * dmg_scale),
		"speed": base["speed"],
		"armor": base.get("armor", 0),
		"heal_power": base.get("heal_power", 0),
		"essence": Balance.essence_for_enemy(depth, base.get("essence_mult", 1.0)),
		"xp": Balance.xp_for_enemy(depth, base.get("xp_mult", 1.0)),
		"is_miniboss": base.get("is_miniboss", false),
		"is_boss": base.get("is_boss", false),
		"phase": 1,
		"statuses": [],
		"guard_next": false,
	}
