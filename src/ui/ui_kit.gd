class_name UIKit
## Små hjälpare för programmatiskt UI. Portrait, enhandsvänligt:
## stora tryckytor (US-3.2) och tydlig hierarki. Ingen grafik i MVP –
## färgpaneler och text tills art-passet görs.

const COLOR_BG := Color("1a1621")
const COLOR_PANEL := Color("262033")
const COLOR_BUTTON := Color("332b47")
const COLOR_BUTTON_HOVER := Color("3e3456")
const COLOR_BUTTON_PRESSED := Color("241e33")
const COLOR_ACCENT := Color("8c6ff0")
const COLOR_ACCENT_DARK := Color("6b4fd0")
const COLOR_ESSENCE := Color("5fd4c4")
const COLOR_HP := Color("e05555")
const COLOR_MANA := Color("5580e0")
const COLOR_WARN := Color("e0a437")
const RARITY_COLORS := {"common": Color("b8b8b8"), "rare": Color("5fa8e0"), "epic": Color("b45fe0")}

# Bundlade typsnitt (OFL, se assets/fonts/): Cinzel för rubriker,
# Alegreya Sans för brödtext och knappar.
const FONT_TITLE := preload("res://assets/fonts/cinzel-700.woff2")
const FONT_BODY := preload("res://assets/fonts/alegreya-sans-400.woff2")
const FONT_BOLD := preload("res://assets/fonts/alegreya-sans-700.woff2")


## Globalt tema: rundade knappar med tydliga tryck-tillstånd, luftiga
## paneler och konsekventa typsnittsstorlekar. Sätts på rot-noden i
## main.gd så att allt UI (även dialoger) ärver det.
static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT_BODY
	theme.default_font_size = 19

	theme.set_font_size("font_size", "Label", 19)
	theme.set_font("font", "Button", FONT_BOLD)
	theme.set_font_size("font_size", "Button", 22)
	theme.set_color("font_color", "Label", Color("e8e4f0"))

	theme.set_stylebox("normal", "Button", _button_box(COLOR_BUTTON))
	theme.set_stylebox("hover", "Button", _button_box(COLOR_BUTTON_HOVER))
	theme.set_stylebox("pressed", "Button", _button_box(COLOR_BUTTON_PRESSED, COLOR_ACCENT, true))
	theme.set_stylebox("focus", "Button", _button_box(COLOR_BUTTON_HOVER, COLOR_ACCENT))
	var disabled_box := _button_box(
		Color(COLOR_BUTTON.r, COLOR_BUTTON.g, COLOR_BUTTON.b, 0.4), Color(1, 1, 1, 0.06), true
	)
	theme.set_stylebox("disabled", "Button", disabled_box)
	theme.set_color("font_color", "Button", Color("f0edf7"))
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))

	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = COLOR_PANEL
	panel_box.set_corner_radius_all(14)
	panel_box.border_width_top = 1
	panel_box.border_color = Color(1, 1, 1, 0.05)
	panel_box.shadow_color = Color(0, 0, 0, 0.35)
	panel_box.shadow_size = 10
	panel_box.shadow_offset = Vector2(0, 5)
	panel_box.content_margin_left = 16
	panel_box.content_margin_right = 16
	panel_box.content_margin_top = 12
	panel_box.content_margin_bottom = 12
	theme.set_stylebox("panel", "PanelContainer", panel_box)

	return theme


## pressed=true tar bort skuggan så att knappen känns nedtryckt.
static func _button_box(
	bg: Color, border := Color(1, 1, 1, 0.10), pressed := false
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(16)
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.border_width_bottom = 1
	box.border_color = border
	if not pressed:
		box.shadow_color = Color(0, 0, 0, 0.30)
		box.shadow_size = 4
		box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


static func title(text: String, size := 34) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT_TITLE)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## Tunn accentlinje som avdelare under rubriker.
static func divider(color := COLOR_ACCENT, height := 2) -> Control:
	var line := ColorRect.new()
	line.color = Color(color.r, color.g, color.b, 0.55)
	line.custom_minimum_size = Vector2(0, height)
	return line


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
	# autowrap_mode på Button finns från Godot 4.3; set() är no-op annars.
	button.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	return button


## Primär handling (run-start, checkpoint-valen): accentfärgad knapp.
static func primary_button(text: String, min_height := 96) -> Button:
	var button := big_button(text, min_height)
	button.add_theme_stylebox_override("normal", _button_box(COLOR_ACCENT_DARK, COLOR_ACCENT))
	button.add_theme_stylebox_override("hover", _button_box(COLOR_ACCENT, COLOR_ACCENT))
	button.add_theme_stylebox_override("pressed", _button_box(COLOR_BUTTON_PRESSED, COLOR_ACCENT))
	return button


static func bar(value: int, max_value: int, color: Color, height := 26) -> ProgressBar:
	var bar_node := ProgressBar.new()
	bar_node.max_value = max_value
	bar_node.value = value
	bar_node.show_percentage = false
	# Bars är ren visning – utan IGNORE äter de tryck på knappen bakom
	# (ProgressBar har mouse_filter STOP som default).
	bar_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(child)
	return container


## Popup för onboarding (US-9.1) och bekräftelser.
static func popup(parent: Node, popup_title: String, text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = popup_title
	dialog.dialog_text = text
	dialog.ok_button_text = "Got it"
	parent.add_child(dialog)
	dialog.popup_centered(Vector2i(560, 0))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
