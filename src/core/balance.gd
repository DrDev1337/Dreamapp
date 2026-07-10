class_name Balance
## Central balanstabell. Alla siffror som styr spelkänslan bor här,
## så att tuning aldrig kräver ändringar i logikfiler.

# --- Run-struktur (US-1.2, US-7.1) ---
const RUN_ROOM_COUNT := 8
const CHECKPOINT_AFTER_ROOMS: Array[int] = [3, 6]
const MINIBOSS_ROOM := 4
const BOSS_ROOM := 8

# --- Djupgräns (US-1.3): segment låses upp med karaktärsnivå.
# Gaten ligger vid checkpoints så att en run alltid kan avslutas snyggt:
# rum 1-3 alltid, rum 4-6 kräver nivå 2, rum 7-8 kräver nivå 4.
const DEPTH_LEVEL_GATES := {4: 2, 7: 4}


static func required_level_for_depth(depth: int) -> int:
	var required := 1
	for gate_depth in DEPTH_LEVEL_GATES:
		if depth >= gate_depth:
			required = maxi(required, DEPTH_LEVEL_GATES[gate_depth])
	return required


static func max_depth_for_level(level: int) -> int:
	var max_depth := 0
	for depth in range(1, RUN_ROOM_COUNT + 1):
		if level >= required_level_for_depth(depth):
			max_depth = depth
	return max_depth


# --- Essens (US-2.1) ---
const ESSENCE_BASE_PER_ENEMY := 10
const ESSENCE_DEPTH_MULT := 0.5  # +50% per djupnivå
const ESSENCE_MINIBOSS_MULT := 3.0
const ESSENCE_BOSS_MULT := 8.0


static func essence_for_enemy(depth: int, mult: float = 1.0) -> int:
	return int(ESSENCE_BASE_PER_ENEMY * (1.0 + ESSENCE_DEPTH_MULT * (depth - 1)) * mult)


# --- Fiendeskalning (US-1.2) ---
const ENEMY_HP_DEPTH_MULT := 0.25
const ENEMY_DMG_DEPTH_MULT := 0.15

# --- Spelarens grundvärden (US-4.1: svag start) ---
const PLAYER_BASE_HP := 50
const PLAYER_BASE_ATTACK := 6
const PLAYER_BASE_MAGIC := 4
const PLAYER_BASE_SPEED := 5
const PLAYER_BASE_ARMOR := 0
const PLAYER_BASE_MANA := 10
const PLAYER_MANA_REGEN := 2

# --- Level och klassning (US-4.2) ---
const XP_PER_LEVEL_BASE := 40
const XP_LEVEL_GROWTH := 1.4
const CLASS_UNLOCK_PICKS := 3  # val i samma riktning innan klassidentitet


static func xp_for_level(level: int) -> int:
	return int(XP_PER_LEVEL_BASE * pow(XP_LEVEL_GROWTH, level - 1))


static func xp_for_enemy(depth: int, mult: float = 1.0) -> int:
	return int((8 + 4 * depth) * mult)


# --- Strid ---
const MIN_DAMAGE := 1
const MAGIC_ARMOR_PENETRATION := 0.5  # magi ignorerar halva rustningen

# --- Loot (US-5.1) ---
const CHEST_ROOM_CHANCE := 0.35
const LOOT_DROP_CHANCE_NORMAL := 0.25  # vanliga fiender
const RARITY_WEIGHTS := {"common": 70, "rare": 25, "epic": 5}

# --- Karaktärsslots (US-4.4) ---
const CHARACTER_SLOTS := 3
