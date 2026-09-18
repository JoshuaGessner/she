class_name MenuStyle
extends Object

## One look, shared by every screen outside the world.
##
## Three screens needed the same buttons — the main menu, the settings panel
## and the pause menu — and three copies of the same styling is three places to
## fix a colour and two of them get missed. `ART-001`'s palette is grubby and
## warm and the UI should not fight it; `ART-005` reserves saturated gold for
## treasure, so nothing here is allowed to be gold.
##
## ## The look is a `Theme`, and this file only names it (ADR-216)
##
## Every size and colour lives in `res://ui/interface_theme.tres`, the project
## theme. What this file holds is the **vocabulary**: constructors that build a
## control and say which role it plays, and the role names as constants so a
## typo is a parse error rather than a label that silently falls back to the
## engine's white.
##
## It used to set every size and colour by hand, on every control, at the
## moment it was built — forty hand-set styles across six scripts. That
## made `M4-T11`'s dyslexia font, high-contrast palette and type scale each an
## edit to every screen, and none of them could reach a screen that was already
## open. A theme is resolved when the control draws, so changing it changes
## what is on screen now.
##
## **The price: a control resolves its role only once it is in the tree.**
## Measured, a `Label` given `CaptionDebt` and asked before `add_child` reports
## the engine's 16 px and white — the project theme included. An override
## answered immediately, so code that sizes a control before parenting it was
## correct before this and is not now. A census of every screen's resolved
## sizes and rects came back identical, so nothing did; add it, then measure.
##
## **A role is a size on a tone.** A Godot theme variation has one base, so
## `BodyWarm` is a variation of `Warm`, which is a variation of `Label`: the
## colour is written once per tone and the size once per role. A palette swap
## is five tones, not twenty-two roles — plus the button, field and toggle, whose
## colours are their own because a `Button` cannot inherit a `Label` tone.
##
## **The roles are what the screens drew before, not a type scale.** Twelve
## sizes on five tones, some of them one pixel apart doing the same job. That is
## an inventory for `M4-T05`'s typography, which is where collapsing it belongs;
## collapsing it here would have been a restyle hiding inside a refactor.
##
## **Layout stays in the screens.** Separations, minimum widths and alignment
## are decisions about one screen's shape, not about how text reads, and
## `M4-T11`'s UI scaling moves them all at once through the window's scale.

## ## Tones — read by drawn controls through `tone()`
const TEXT: StringName = &"Text"
const DIM: StringName = &"Dim"
const WARM: StringName = &"Warm"

## ## Roles — a size on a tone
##
## Named by size step and tone rather than by what they are for, because the
## same pair is used for different jobs and the same job at different sizes.
## Pretending otherwise would name a distinction the screens do not make.
##
## ## The scale, and why there are nine steps rather than fourteen (`M4-T05`)
##
## This block read *"Twelve sizes on five tones, some of them one pixel apart
## doing the same job... an inventory for `M4-T05`'s typography"*, and it was
## an honest inventory: **11, 12, 13, 14, 15, 16** — six steps inside five
## pixels, on screens where three of them appear in the same readout. A
## hierarchy nobody can see is not a hierarchy; it is a list of numbers that
## happened.
##
## | px | roles |
## |---|---|
## | **11** | `Heading`, `FineDim` |
## | **13** | `Caption*` |
## | **15** | `Body*` |
## | **18** | `Sub*` |
## | **21** | `DisplayWarm`, `DeedName` |
## | **26** | `BannerWarm`, `DeedsTitle`, `LegacyTitle` |
## | **30** | `DialogTitle` |
## | **34** | `ScreenTitle` |
## | **44** | `Title` |
##
## **No two steps are closer than 13%**, and the only pair under 15% —
## `DialogTitle` and `ScreenTitle` — never appear together, because one is a
## question asked *over* the other.
##
## **`Small*` and `Large*` are gone rather than merged.** Collapsing 14 into 13
## and 16 into 15 would have left `SmallDim` and `CaptionDim` byte-identical,
## which turns twenty-two call sites into a coin flip between two names for one
## thing — worse than the sizes were. `Small` and `Large` are also relative
## words with no referent; they came from *whatever this screen happened to
## draw*. `Caption` and `Body` say what the text is.
##
## **`Heading` and `FineDim` share 11 on purpose.** A heading is uppercase and
## letter-spaced and a fine line is a sentence, so they are never mistaken for
## each other — and a footnote that sits *under* a column of `Caption` rows has
## to be quieter than them, which 13 would not be.
const TITLE: StringName = &"Title"  ## 44, the first screen of a flow.
const SCREEN_TITLE: StringName = &"ScreenTitle"  ## 34.
const DIALOG_TITLE: StringName = &"DialogTitle"  ## 30, a question asked over a screen.
const HEADING: StringName = &"Heading"  ## 11, the name of a region.
const FINE_DIM: StringName = &"FineDim"  ## 11, a footnote under a column of rows.
const CAPTION_DIM: StringName = &"CaptionDim"  ## 13.
const CAPTION_TEXT: StringName = &"CaptionText"
const CAPTION_WARM: StringName = &"CaptionWarm"
## **The one number in the game that is allowed to be alarming.**
##
## `ART-005` spends saturated gold on treasure and nothing else, so this is not
## gold — it is the desaturated red the wound vignette already uses, reserved
## for a debt that is about to come due. Anything using it must also say so in
## shape or word, never in hue alone (`DES-018`).
const CAPTION_DEBT: StringName = &"CaptionDebt"
## Something went wrong and you can act on it. Was `SmallFault` at 14.
const CAPTION_FAULT: StringName = &"CaptionFault"
const BODY_DIM: StringName = &"BodyDim"  ## 15, and what `line()` draws unless told.
const BODY_TEXT: StringName = &"BodyText"
const BODY_WARM: StringName = &"BodyWarm"
const SUB_DIM: StringName = &"SubDim"  ## 18.
const SUB_WARM: StringName = &"SubWarm"
const DISPLAY_WARM: StringName = &"DisplayWarm"  ## 21.
const BANNER_WARM: StringName = &"BannerWarm"  ## 26.

## **Never given the house style.** The Legacy screen and the deeds banner draw
## in the engine's own white on its own grey buttons, and always have: they were
## built beside `MenuStyle` rather than with it. These roles carry only the
## sizes they already set, so the theme draws them exactly as before, and
## bringing them into the register is `M4-T05`'s — it is a visible change a
## person should look at, not a side effect of moving numbers into a file.
const LEGACY_TITLE: StringName = &"LegacyTitle"  ## 26.
const DEEDS_TITLE: StringName = &"DeedsTitle"  ## 26.
const DEED_NAME: StringName = &"DeedName"  ## 21.

## ## Controls
##
## Not `MenuButton`: that is a Godot class, and the theme refuses a variation
## named after one.
const ACTION: StringName = &"MenuAction"
const FIELD: StringName = &"MenuField"
const TOGGLE: StringName = &"MenuToggle"
const BINDING: StringName = &"BindingCell"
## A readout that floats over a live room. See-through ground, thin band.
const FRAME: StringName = &"Frame"
## **A surface you are working on**, rather than one you are reading past
## (`M4-T05`). Opaque, heavier at the corners, and the only ground in the game
## that carries grain — a stroke drawn over a moving world reads as a scratch
## on the screen, so `CarvedFrame.hatch` belongs on a panel you cannot see
## through and nowhere else.
const SLATE: StringName = &"Slate"
## A hole in a slate: an inventory cell, an equipment slot. One band and a tick
## at each corner, because 44 px has no room for furniture.
const SOCKET: StringName = &"Socket"
## **The bag's own colours, which are not tones** (`M4-T05`). *Does this fit*
## has a yes and a no, and the load bar has a full and an over — four answers
## that are not text and therefore have no `font_color` to live on. They were
## `const Color` inside `bag_screen.gd`, which put them outside every palette
## this file exists to make reachable.
const BAG: StringName = &"Bag"
const RULE: StringName = &"Rule"
const BACKDROP: StringName = &"Backdrop"
## A backdrop you can still half see through, for a banner laid over a room.
const SCRIM: StringName = &"Scrim"


## ## The two grounds, and the flip at the Descent (TEC-009 §5.5)
##
## `ART-005` §"Two worlds, two treatments" specifies that the Threshold and the
## Chamber are **white ground, hard black ink, fully drawn**, and the Deep is the
## inverse — pale ink on black. The rule that keeps the interface honest about
## it is one line:
##
## > **Ink is the opposite of the ground, and the ground flips at the Descent.**
##
## **The ground is where a panel lives, not a switch somebody sets.** This
## theme overrides only the `Text` and `Dim` tones, the frame and the rule, and a
## Lair scene assigns it to the panels it builds; everything inside them — every
## role on those tones — resolves against it, and nothing outside does. It
## replaced a `static var` the Lair scenes set on the way in and had to restore
## on the way out, because a static outlives the scene that wrote it (`M2-T15`):
## a way out that forgot would have drawn the next floor in the hub's colours.
## A theme on a node is freed with the node.
##
## ## The values in it are correct for the world as it is drawn *today*
##
## The Lair is not white yet — `ART-005`'s two treatments arrive with the ink
## shader at `M4-T08`, and the Chamber is currently a dark, warm room. So the
## hub's ground is a *warmer, higher-contrast* version of the same pale-on-dark
## reading, rather than the inverted one it will become. Writing the inverted
## palette now would put a black panel on a black wall and call it
## forward-looking. **`M4-T08` changes the four entries in that file**; no
## screen moves.
const LAIR: Theme = preload("res://ui/lair_theme.tres")


## A tone, as the ground under `of` draws it — for controls that paint rather
## than lay out a `Label`, which is the reticle, the marks and the bag.
static func tone(of: Control, name: StringName) -> Color:
	return of.get_theme_color(&"font_color", name)


## **The ground a carved role paints**, for the same controls — the party
## frames' empty track, the bag's cells and its panel.
##
## It replaced `(get_theme_stylebox(...) as StyleBoxFlat).bg_color`, which was
## correct for as long as every panel was flat and returned **null** the moment
## one stopped being, taking the party frames down with it. Asking the role for
## its ground is the same question without the assumption about how the ground
## is drawn, and there is one of these rather than one per caller because the
## cast is exactly the part that was wrong.
##
## A role that is not a `CarvedFrame` is a fault in the theme rather than a
## state to draw around, so it says so and returns a colour nobody would
## author, instead of quietly painting the wrong thing.
static func ground(of: Control, role: StringName) -> Color:
	var carved := of.get_theme_stylebox(&"panel", role) as CarvedFrame
	if carved == null:
		push_error("the `%s` role is not a `CarvedFrame`, so it has no " % role
			+ "ground to read")
		return Color(1.0, 0.0, 1.0, 1.0)
	return carved.ground


## Every panel named here that is not drawn on the hub's ground. For
## `--lair-probe` and `--threshold-probe`.
##
## A panel built without `LAIR` is the one way the flip goes wrong now, and
## nothing else notices: it draws the Deep's palette, which is a readable
## palette, in a room that is merely the wrong colour.
static func off_the_lair_ground(tag: String, panels: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var wanted: Color = LAIR.get_color(&"font_color", DIM)
	for name: String in panels:
		var drawn: Color = tone(panels[name] as Control, DIM)
		print("[%s] ground     %-9s reads Dim as %s" % [tag, name, drawn])
		if drawn != wanted:
			out.append(("`%s` reads Dim as %s, not the hub's %s — it was built "
				+ "without `MenuStyle.LAIR`, so it draws the Deep's palette in "
				+ "the hub") % [name, drawn, wanted])
	return out


## A framed region that floats over the world (TEC-009 §5.5).
##
## The difference between "a readout" and "text lying on the screen", and the
## cheapest single thing that makes a blockout interface read as built. Gestalt
## common region: a border around a group says *these four lines are one thing*
## far more cheaply than spacing does, which is what fifteen unframed lines in
## one corner could never say.
##
## Square in the theme. `ART-005` is a woodcut — a carved line has no radius,
## and a rounded panel would be the one element on screen made by a different
## tool.
static func frame() -> PanelContainer:
	var box := PanelContainer.new()
	box.theme_type_variation = FRAME
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
	label.theme_type_variation = HEADING
	return label


## One fact: what it is, and what it currently reads.
##
## Fitts is not the argument here — nothing is clicked. **Gestalt proximity and
## a shared left edge** are: a column of these scans as a table, where the same
## content as sentences scans as a paragraph nobody reads. That is the whole
## difference between the Chamber's fifteen lines and four rows.
static func row(key: String, value: String) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	var key_label := Label.new()
	key_label.text = key
	key_label.theme_type_variation = CAPTION_DIM
	# A fixed key column so the values line up, as a fraction of nothing — this
	# is the one place a pixel width is right, because it is a text measure and
	# it scales with the font when `M4-T11` swaps it.
	key_label.custom_minimum_size = Vector2(74.0, 0.0)
	bar.add_child(key_label)
	var read := Label.new()
	read.text = value
	read.theme_type_variation = CAPTION_TEXT
	read.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bar.add_child(read)
	return bar


## A hairline between groups. Cheaper than a gap and says more: a gap is
## ambiguous about whether the next line belongs to the last group.
##
## A `Panel` rather than a `ColorRect`, because a `ColorRect`'s colour is a
## property and a property cannot follow the ground it is drawn on.
static func rule() -> Control:
	var bar := Panel.new()
	bar.theme_type_variation = RULE
	bar.custom_minimum_size = Vector2(0.0, 1.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


## Everything in a menu column is centred on the column, because the buttons
## are and a title that sits left of its own buttons reads as a layout bug even
## when it is deliberate. Caught by `--menu-shot`, which is the only thing that
## can see it.
static func title(text: String, role: StringName = TITLE) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = role
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func line(text: String, role: StringName = BODY_DIM) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = role
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
	control.theme_type_variation = ACTION
	return control


## **A binding you can press** (ADR-245): the controls screen's cells, a line
## tall so twenty verbs still fit two columns, and clicking like every button.
static func binding(text: String, width: float) -> Button:
	var control := Button.new()
	control.text = text
	control.pressed.connect(func() -> void:
		Foley.flat(control, Foley.Sound.CLICK))
	control.custom_minimum_size = Vector2(width, 0.0)
	control.alignment = HORIZONTAL_ALIGNMENT_LEFT
	control.theme_type_variation = BINDING
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
	edit.theme_type_variation = FIELD
	return edit


static func backdrop(role: StringName = BACKDROP) -> Control:
	var rect := Panel.new()
	rect.theme_type_variation = role
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
