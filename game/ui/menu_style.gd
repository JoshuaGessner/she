class_name MenuStyle
extends Object

## One look, shared by every screen outside the world.
##
## Three screens needed the same buttons — the main menu, the settings panel
## and the pause menu — and three copies of the same styling is three places to
## fix a colour and two of them get missed. `ART-001`'s palette is grubby and
## warm and the UI should not fight it; `ART-005` reserves saturated gold for
## treasure, so nothing here is allowed to be gold.

const INK: Color = Color(0.07, 0.065, 0.06, 0.94)
const PANEL: Color = Color(0.11, 0.105, 0.10, 0.96)
const EDGE: Color = Color(0.28, 0.26, 0.24, 1.0)
const TEXT: Color = Color(0.87, 0.85, 0.81, 1.0)
const DIM: Color = Color(0.55, 0.53, 0.50, 1.0)
const WARM: Color = Color(0.78, 0.55, 0.30, 1.0)


## Everything in a menu column is centred on the column, because the buttons
## are and a title that sits left of its own buttons reads as a layout bug even
## when it is deliberate. Caught by `--menu-shot`, which is the only thing that
## can see it.
static func title(text: String, size: int = 44) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func line(text: String, size: int = 15, colour: Color = DIM) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Wide enough that a short sentence does not wrap into two ragged lines,
	# and matching the button width so a column reads as one shape.
	label.custom_minimum_size = Vector2(340.0, 0.0)
	return label


static func button(text: String) -> Button:
	var control := Button.new()
	control.text = text
	# Every button in the game clicks, because it is defined here once. A menu
	# with no sound reads as a menu that did not register the press.
	control.pressed.connect(func() -> void:
		Foley.flat(control, Foley.Sound.CLICK))
	control.custom_minimum_size = Vector2(280.0, 40.0)
	control.add_theme_font_size_override("font_size", 18)
	control.add_theme_color_override("font_color", TEXT)
	control.add_theme_color_override("font_hover_color", WARM)
	control.add_theme_color_override("font_focus_color", WARM)
	control.add_theme_stylebox_override("normal", _box(PANEL))
	control.add_theme_stylebox_override("hover", _box(PANEL, WARM))
	control.add_theme_stylebox_override("focus", _box(PANEL, WARM))
	control.add_theme_stylebox_override("pressed", _box(INK, WARM))
	return control


## **Put the focus somewhere** (ADR-141).
##
## `LegacyScreen`, `ClassScreen` and `PactScreen` between them contained **zero**
## `grab_focus()` calls, so all three were mouse-only — and every one of them
## opens over a live body that was recapturing the mouse every frame. With no
## cursor and no focus there was no input path to them at all. ADR-075 makes
## controller parity a project rule; a screen a pad cannot move around in is the
## same bug as an action with no pad binding.
##
## Deferred by the caller, because a `Control` takes focus only once it is in
## the tree. Returns whether anything took it, so a probe can ask.
static func focus_first(root: Node) -> bool:
	for node: Node in root.find_children("*", "Button", true, false):
		var pressable := node as Button
		if pressable != null and not pressable.disabled:
			pressable.grab_focus()
			return true
	return false


static func field(hint: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = hint
	edit.custom_minimum_size = Vector2(280.0, 36.0)
	edit.add_theme_font_size_override("font_size", 17)
	edit.add_theme_color_override("font_color", TEXT)
	edit.add_theme_stylebox_override("normal", _box(INK))
	edit.add_theme_stylebox_override("focus", _box(INK, WARM))
	return edit


static func backdrop() -> ColorRect:
	var rect := ColorRect.new()
	rect.color = INK
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Menus sit over a live world, so the backdrop has to swallow the clicks
	# that would otherwise reach it.
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	return rect


## A vertical stack, centred, with room to breathe.
static func column(gap: int = 10) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	return box


static func _box(fill: Color, border: Color = EDGE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	return style
