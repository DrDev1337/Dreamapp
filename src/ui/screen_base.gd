class_name ScreenBase
extends Control
## Bas för alla skärmar. main sätts av routern innan skärmen läggs till
## i trädet; data bär skärmspecifik kontext (t.ex. rewards).

var main: Control = null
var data := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()


## Överskuggas av varje skärm.
func build() -> void:
	pass


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	build.call_deferred()
