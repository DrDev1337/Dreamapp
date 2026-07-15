class_name Icons
## Ikonkatalog (game-icons.net, CC BY 3.0 – se assets/icons/LICENSE).
## Alla SVG:er är vita och tintas med modulate/ikonfärg där de används.

# Delade texturer (används i flera roller nedan).
const _SWORD := preload("res://assets/icons/sword.svg")
const _FIREBALL := preload("res://assets/icons/fireball.svg")
const _GRAVEYARD := preload("res://assets/icons/graveyard.svg")
const _FIST := preload("res://assets/icons/fist.svg")
const _MAGIC_SHIELD := preload("res://assets/icons/magic_shield.svg")
const _WAR_CRY := preload("res://assets/icons/war_cry.svg")
const _HEALING := preload("res://assets/icons/healing.svg")
const _CRYSTAL := preload("res://assets/icons/crystal.svg")
const _KNOCKOUT := preload("res://assets/icons/knockout.svg")
const _BERSERK := preload("res://assets/icons/berserk.svg")
const _CROSSED_SWORDS := preload("res://assets/icons/crossed_swords.svg")
const _BOWMAN := preload("res://assets/icons/bowman.svg")
const _CROWNED_SKULL := preload("res://assets/icons/crowned_skull.svg")
const _STRIKE := preload("res://assets/icons/strike.svg")
const _SHADOW := preload("res://assets/icons/shadow.svg")
const _HEART := preload("res://assets/icons/heart.svg")
const _CAMPFIRE := preload("res://assets/icons/campfire.svg")
const _SKULL := preload("res://assets/icons/skull.svg")

const ABILITY := {
	"basic_attack": _SWORD,
	"defend": _MAGIC_SHIELD,
	"taunt": _WAR_CRY,
	"shield_bash": preload("res://assets/icons/shield_bash.svg"),
	"fortify": _MAGIC_SHIELD,
	"bulwark": _BERSERK,
	"mend": _HEALING,
	"radiance": _CRYSTAL,
	"smite": _STRIKE,
	"resurrect": _KNOCKOUT,
	"firebolt": _FIREBALL,
	"frost_nova": preload("res://assets/icons/frost.svg"),
	"arcane_shield": _MAGIC_SHIELD,
	"meteor": preload("res://assets/icons/meteor.svg"),
	"backstab": preload("res://assets/icons/backstab.svg"),
	"poison_blade": preload("res://assets/icons/poison.svg"),
	"evasion": preload("res://assets/icons/dodge.svg"),
	"shadow_dance": _SHADOW,
	"cleave": _CROSSED_SWORDS,
	"rage": _WAR_CRY,
	"reckless_swing": _STRIKE,
	"rampage": _BERSERK,
	"marked_shot": _BOWMAN,
	"piercing_shot": _STRIKE,
	"volley": _CROSSED_SWORDS,
	"deadeye": _CROWNED_SKULL,
	"curse_of_frailty": _SKULL,
	"life_drain": _HEART,
	"eldritch_blast": _SHADOW,
	"doom": _CROWNED_SKULL,
	"cutting_words": _KNOCKOUT,
	"rest_song": _CAMPFIRE,
	"inspire": _WAR_CRY,
	"grand_finale": _CRYSTAL,
}

# Fiende-intentioner (US-3.4): ikon + färg per handlingstyp.
const INTENT := {
	"attack": _SWORD,
	"heavy": _FIST,
	"guard": _MAGIC_SHIELD,
	"heal": _HEALING,
	"frenzy": _WAR_CRY,
	"double": _CROSSED_SWORDS,
	"stunned": _KNOCKOUT,
}

const INTENT_TINT := {
	"attack": Color("e08585"),
	"heavy": Color("e05555"),
	"guard": Color("7ea5e8"),
	"heal": Color("6fdb8f"),
	"frenzy": Color("e0a437"),
	"double": Color("e05555"),
	"stunned": Color("9a94a8"),
}

const ENEMY := {
	"cave_rat": preload("res://assets/icons/rat.svg"),
	"skeleton_archer": _BOWMAN,
	"cultist_healer": preload("res://assets/icons/cowled.svg"),
	"stone_golem": preload("res://assets/icons/golem.svg"),
	"imp": preload("res://assets/icons/imp.svg"),
	"grave_warden": _GRAVEYARD,
	"heart_of_depths": _HEART,
}

# Färgton per fiendetyp – ger varje siluett en egen identitet.
const ENEMY_TINT := {
	"cave_rat": Color("b8a58c"),
	"skeleton_archer": Color("d8d8c8"),
	"cultist_healer": Color("c98fdb"),
	"stone_golem": Color("9aa5b1"),
	"imp": Color("e0885f"),
	"grave_warden": Color("8fd0b8"),
	"heart_of_depths": Color("e06a6a"),
}

const ROOM := {
	"combat": _SWORD,
	"chest": preload("res://assets/icons/chest.svg"),
	"miniboss": _GRAVEYARD,
	"boss": _CROWNED_SKULL,
}

# 8 klasser (D&D-inspirerade axlar).
const CLASS_EMBLEM := {
	"tank": _MAGIC_SHIELD,
	"healer": _HEALING,
	"mage": _FIREBALL,
	"rogue": preload("res://assets/icons/ninja_mask.svg"),
	"barbarian": _BERSERK,
	"ranger": _BOWMAN,
	"warlock": _SHADOW,
	"bard": _WAR_CRY,
}

const ESSENCE := _CRYSTAL
const CAMPFIRE := _CAMPFIRE
const SKULL := _SKULL
const LOCK := preload("res://assets/icons/lock.svg")
const STAIRS := preload("res://assets/icons/stairs.svg")
const ANVIL := preload("res://assets/icons/anvil.svg")
const COINS := preload("res://assets/icons/coins.svg")


## Liten ikonbild för rader och paneler.
static func image(texture: Texture2D, size := 28, tint := Color.WHITE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = tint
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Rad med ikon + text, för kartor och listor.
static func labeled(
	texture: Texture2D, label: Control, size := 26, tint := Color.WHITE
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(image(texture, size, tint))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row
