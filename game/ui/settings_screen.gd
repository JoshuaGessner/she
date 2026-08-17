class_name SettingsScreen
extends Control

## Preferences, reachable from the main menu and from the pause menu.
##
## The same node in both places rather than two screens that drift: what you
## can change in the middle of a run and what you can change before one are the
## same list, and a settings panel that differs by where you opened it is a
## small betrayal a player notices immediately.
##
## Every control here **does something**, applied live (ADR-064). A slider you
## have to close the panel to hear is one you cannot set by ear, which is the
## only way anybody actually sets a volume. The full accessibility suite —
## colour-blind support, UI scaling, dyslexia-friendly font, shake and blur
## sliders — is `M4-T11` and is **absent rather than half-present**: a greyed
## row promising high contrast is worse than no row.

signal closed()

const BUS_LABELS: Dictionary = {
	"Master": "everything",
	"score": "score",
	"ambience": "ambience",
	"diegetic": "the world",
	"ui": "interface",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuStyle.backdrop())

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var column: VBoxContainer = MenuStyle.column(14)
	centre.add_child(column)
	column.add_child(MenuStyle.title("SETTINGS", 34))
	column.add_child(MenuStyle.line(
		"Changes apply as you make them and are kept when you quit.", 14))

	column.add_child(_gap(8))
	column.add_child(MenuStyle.line("SOUND", 13, MenuStyle.WARM))
	for bus: String in Settings.VOLUME_BUSES:
		column.add_child(_volume_row(bus))

	column.add_child(_gap(10))
	column.add_child(MenuStyle.line("LOOK", 13, MenuStyle.WARM))
	column.add_child(_sensitivity_row())
	column.add_child(_toggle_row("Invert vertical look", Settings.invert_look,
		func(on: bool) -> void:
			Settings.invert_look = on
			Settings.save()))
	column.add_child(_toggle_row("Fullscreen", Settings.fullscreen,
		func(on: bool) -> void:
			Settings.fullscreen = on
			Settings.apply()
			Settings.save()))

	column.add_child(_gap(14))
	var back: Button = MenuStyle.button("BACK")
	back.pressed.connect(func() -> void: closed.emit())
	column.add_child(back)
	back.grab_focus()


func _volume_row(bus: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var name_label: Label = MenuStyle.line(String(BUS_LABELS[bus]), 16,
		MenuStyle.TEXT)
	name_label.custom_minimum_size = Vector2(110.0, 0.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(Settings.volumes[bus])
	slider.custom_minimum_size = Vector2(200.0, 20.0)
	row.add_child(slider)

	var readout: Label = MenuStyle.line(_percent(slider.value), 15)
	readout.custom_minimum_size = Vector2(48.0, 0.0)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(readout)

	slider.value_changed.connect(func(value: float) -> void:
		Settings.volumes[bus] = value
		Settings.apply()
		Settings.save()
		readout.text = _percent(value))
	return row


func _sensitivity_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var name_label: Label = MenuStyle.line("sensitivity", 16, MenuStyle.TEXT)
	name_label.custom_minimum_size = Vector2(110.0, 0.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.min_value = 0.1
	slider.max_value = 3.0
	slider.step = 0.05
	slider.value = Settings.mouse_sensitivity
	slider.custom_minimum_size = Vector2(200.0, 20.0)
	row.add_child(slider)

	var readout: Label = MenuStyle.line("%.2fx" % slider.value, 15)
	readout.custom_minimum_size = Vector2(48.0, 0.0)
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(readout)

	slider.value_changed.connect(func(value: float) -> void:
		Settings.mouse_sensitivity = value
		Settings.save()
		readout.text = "%.2fx" % value)
	return row


func _toggle_row(text: String, on: bool, apply: Callable) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = on
	box.add_theme_font_size_override("font_size", 16)
	box.add_theme_color_override("font_color", MenuStyle.TEXT)
	box.add_theme_color_override("font_hover_color", MenuStyle.WARM)
	# Wide enough that the check indicator is not clipped against the edge of a
	# centred column — it sits to the *left* of the text, outside the width the
	# label alone asks for. Only a screenshot shows this.
	box.custom_minimum_size = Vector2(340.0, 0.0)
	box.toggled.connect(func(pressed: bool) -> void: apply.call(pressed))
	return box


func _gap(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, float(height))
	return spacer


func _percent(value: float) -> String:
	return "off" if value <= 0.001 else "%d%%" % int(round(value * 100.0))
