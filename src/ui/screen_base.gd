class_name ScreenBase
extends Control
## Bas för alla skärmar. main sätts av routern innan skärmen läggs till
## i trädet; data bär skärmspecifik kontext (t.ex. rewards).

var main: Control = null
var data := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()
	# Mjuk intoning vid skärmbyte.
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)


## Överskuggas av varje skärm.
func build() -> void:
	pass


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	build.call_deferred()
