class_name Icons
## Ikonkatalog (game-icons.net, CC BY 3.0 – se assets/icons/LICENSE).
## Alla SVG:er är vita och tintas med modulate/ikonfärg där de används.

# Delade texturer (används i flera roller nedan).
const _SWORD := preload("res://assets/icons/sword.svg")
const _FIREBALL := preload("res://assets/icons/fireball.svg")
const _GRAVEYARD := preload("res://assets/icons/graveyard.svg")

const ABILITY := {
	"basic_attack": _SWORD,
	"focus_strike": preload("res://assets/icons/strike.svg"),
	"power_strike": preload("res://assets/icons/fist.svg"),
	"shield_bash": preload("res://assets/icons/shield_bash.svg"),
	"war_cry": preload("res://assets/icons/war_cry.svg"),
	"berserk": preload("res://assets/icons/berserk.svg"),
	"firebolt": _FIREBALL,
	"frost_nova": preload("res://assets/icons/frost.svg"),
	"arcane_shield": preload("res://assets/icons/magic_shield.svg"),
	"meteor": preload("res://assets/icons/meteor.svg"),
	"backstab": preload("res://assets/icons/backstab.svg"),
	"poison_blade": preload("res://assets/icons/poison.svg"),
	"evasion": preload("res://assets/icons/dodge.svg"),
	"shadow_dance": preload("res://assets/icons/shadow.svg"),
}

const ENEMY := {
	"cave_rat": preload("res://assets/icons/rat.svg"),
	"skeleton_archer": preload("res://assets/icons/bowman.svg"),
	"cultist_healer": preload("res://assets/icons/cowled.svg"),
	"stone_golem": preload("res://assets/icons/golem.svg"),
	"imp": preload("res://assets/icons/imp.svg"),
	"grave_warden": _GRAVEYARD,
	"heart_of_depths": preload("res://assets/icons/heart.svg"),
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
	"boss": preload("res://assets/icons/crowned_skull.svg"),
}

const CLASS_EMBLEM := {
	"fighter": _SWORD,
	"mage": _FIREBALL,
	"rogue": preload("res://assets/icons/ninja_mask.svg"),
}

const ESSENCE := preload("res://assets/icons/crystal.svg")
const CAMPFIRE := preload("res://assets/icons/campfire.svg")
const SKULL := preload("res://assets/icons/skull.svg")
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
