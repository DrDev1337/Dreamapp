class_name UIKit
## Små hjälpare för programmatiskt UI. Portrait, enhandsvänligt:
## stora tryckytor (US-3.2) och tydlig hierarki. Ingen grafik i MVP –
## färgpaneler och text tills art-passet görs.

const COLOR_BG := Color("1a1621")
const COLOR_PANEL := Color("262033")
const COLOR_ACCENT := Color("8c6ff0")
const COLOR_ESSENCE := Color("5fd4c4")
const COLOR_HP := Color("e05555")
const COLOR_MANA := Color("5580e0")
const COLOR_WARN := Color("e0a437")
const RARITY_COLORS := {"common": Color("b8b8b8"), "rare": Color("5fa8e0"), "epic": Color("b45fe0")}


static func title(text: String, size := 34) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func body(text: String, size := 20) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func big_button(text: String, min_height := 88) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, min_height)
	button.add_theme_font_size_override("font_size", 24)
	return button


static func bar(value: int, max_value: int, color: Color, height := 26) -> ProgressBar:
	var bar_node := ProgressBar.new()
	bar_node.max_value = max_value
	bar_node.value = value
	bar_node.show_percentage = false
	bar_node.custom_minimum_size = Vector2(0, height)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar_node.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.4)
	bar_node.add_theme_stylebox_override("background", background)
	return bar_node


static func panel(color := COLOR_PANEL) -> PanelContainer:
	var container := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	container.add_theme_stylebox_override("panel", style)
	return container


static func spacer(height := 12) -> Control:
	var control := Control.new()
	control.custom_minimum_size = Vector2(0, height)
	return control


static func vmargin(child: Control, margin := 24) -> MarginContainer:
	var container := MarginContainer.new()
	container.add_theme_constant_override("margin_left", margin)
	container.add_theme_constant_override("margin_right", margin)
	container.add_theme_constant_override("margin_top", margin)
	container.add_theme_constant_override("margin_bottom", margin)
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(child)
	return container


## Popup för onboarding (US-9.1) och bekräftelser.
static func popup(parent: Node, popup_title: String, text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = popup_title
	dialog.dialog_text = text
	dialog.ok_button_text = "Uppfattat"
	parent.add_child(dialog)
	dialog.popup_centered(Vector2i(560, 0))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
