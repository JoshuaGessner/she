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

## A panel that sits over the world rather than over a backdrop.
##
## Lighter and more transparent than `PANEL`, because a readout in the Chamber
## is competing with a lit room behind it and an opaque slab there would read as
## a menu that failed to close.
const OVERLAY: Color = Color(0.09, 0.085, 0.08, 0.72)

## **The one number in the game that is allowed to be alarming.**
##
## `ART-005` spends saturated gold on treasure and nothing else, so this is not
## gold — it is the desaturated red the wound vignette already uses, reserved
## here for a debt that is about to come due. Anything using it must also say so
## in shape or word, never in hue alone (`DES-018`).
const DEBT: Color = Color(0.72, 0.36, 0.30, 1.0)


## ## The two grounds, and the flip at the Descent (TEC-009 §5.5)
##
## `ART-005` §"Two worlds, two treatments" specifies that the Threshold and the
## Chamber are **white ground, hard black ink, fully drawn**, and the Deep is the
## inverse — pale ink on black.
##
## Every colour above is absolute and assumes the Deep. So when `M4-T08` lands,
## **every Lair screen becomes a black panel on a white world** — the hub wearing
## the Deep's interface, at maximum contrast in the wrong direction, across
## seventeen files.
##
## The rule that prevents it is one line:
##
## > **Ink is the opposite of the ground, and the ground flips at the Descent.**
##
## Defined here once, now, while it is nearly free.
##
## **What is expensive is the indirection, not the palette.** Seventeen screens
## reference `TEXT` and `DIM` as constants; routing them through `ink()` and
## `dim()` is the part that has to happen before `M4-T08`, and it is what makes
## the eventual flip **four constants instead of seventeen files.**
##
## ## The values below are correct for the world as it is drawn *today*
##
## The Lair is not white yet — `ART-005`'s two treatments arrive with the ink
## shader at `M4-T08`, and the Chamber is currently a dark, warm room. So `LAIR`
## is a *warmer, higher-contrast* version of the same pale-on-dark reading,
## rather than the inverted one it will become.
##
## Writing the inverted palette now would put a black panel on a black wall and
## call it forward-looking. **`M4-T08` changes these four constants**; nothing
## above them and no screen below them moves. That is the whole return on the
## indirection, and it is claimed here rather than promised.
enum Ground {
	DEEP,  ## Pale ink on black. Every level, and the default.
	LAIR,  ## The hub. Warmer and brighter now; inverted at `M4-T08`.
}

## Which world the interface is currently being drawn in.
##
## **Set by the scene, and set on the way out as well.** A `static var` outlives
## the scene that wrote it — `M2-T15` is a whole task about state that survived
## a level change — so the Lair scenes restore `DEEP` when they leave, or the
## first floor after a visit to the Chamber draws in the hub's palette.
static var ground: Ground = Ground.DEEP

const LAIR_INK: Color = Color(0.94, 0.91, 0.85, 1.0)
const LAIR_DIM: Color = Color(0.66, 0.62, 0.57, 1.0)
const LAIR_PANEL: Color = Color(0.13, 0.11, 0.09, 0.78)
const LAIR_EDGE: Color = Color(0.44, 0.38, 0.30, 1.0)


## Body text, in whichever world we are drawing in.
static func ink() -> Color:
	return LAIR_INK if ground == Ground.LAIR else TEXT


## Secondary text — labels, units, the things you read second.
static func dim() -> Color:
	return LAIR_DIM if ground == Ground.LAIR else DIM


## The fill behind a readout that floats over the world.
static func overlay() -> Color:
	return LAIR_PANEL if ground == Ground.LAIR else OVERLAY


static func edge() -> Color:
	return LAIR_EDGE if ground == Ground.LAIR else EDGE


## A framed region that floats over the world (TEC-009 §5.5).
##
## The difference between "a readout" and "text lying on the screen", and the
## cheapest single thing that makes a blockout interface read as built. Gestalt
## common region: a border around a group says *these four lines are one thing*
## far more cheaply than spacing does, which is what fifteen unframed lines in
## one corner could never say.
static func frame() -> PanelContainer:
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = overlay()
	style.border_color = edge()
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	# Square. `ART-005` is a woodcut — a carved line has no radius, and a
	# rounded panel would be the one element on screen made by a different tool.
	style.corner_radius_top_left = 0
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


## The name of a region, above its contents. Small, spaced, and quiet — it is
## the thing you read *once* to learn where to look, and never again.
static func heading(text: String) -> Label:
	var label := Label.new()
	# Letter-spacing is not a `Label` property in Godot 4, so the spacing is in
	# the string. It is a heading, never a sentence, so this cannot reach
	# anything a translator has to reflow (`ADR-084` — text is keys).
	label.text = " ".join(text.to_upper().split())
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", dim())
	return label


## One fact: what it is, and what it currently reads.
##
## Fitts is not the argument here — nothing is clicked. **Gestalt proximity and
## a shared left edge** are: a column of these scans as a table, where the same
## content as sentences scans as a paragraph nobody reads. That is the whole
## difference between the Chamber's fifteen lines and four rows.
static func row(key: String, value: String, tone: Color = Color(0, 0, 0, 0)) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	var key_label := Label.new()
	key_label.text = key
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", dim())
	# A fixed key column so the values line up, as a fraction of nothing — this
	# is the one place a pixel width is right, because it is a text measure and
	# it scales with the font when `M4-T11` swaps it.
	key_label.custom_minimum_size = Vector2(74.0, 0.0)
	bar.add_child(key_label)
	var read := Label.new()
	read.text = value
	read.add_theme_font_size_override("font_size", 13)
	read.add_theme_color_override("font_color",
		tone if tone.a > 0.0 else ink())
	read.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bar.add_child(read)
	return bar


## A hairline between groups. Cheaper than a gap and says more: a gap is
## ambiguous about whether the next line belongs to the last group.
static func rule() -> Control:
	var bar := ColorRect.new()
	bar.color = edge()
	bar.custom_minimum_size = Vector2(0.0, 1.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


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
