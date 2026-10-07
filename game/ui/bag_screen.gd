class_name BagScreen
extends Control

## The bag, drawn (`M2-T01`, `DES-019`).
##
## **Grid-based, weighted, real-time, and there is no pause** (ADR-040,
## reaffirmed ADR-083). Co-op makes pausing impossible anyway, so `DES-019`
## designs for it deliberately rather than inheriting it: *opening your bag is
## a vulnerable act.* You kneel, you rummage, and the floor keeps happening.
##
## The cost is charged by `Player`, not here — movement drops to
## `bag_speed_multiplier`, sprint and the weapon refuse, and looking is
## suspended because you are looking at your bag. This file is the readout and
## the hands.
##
## ## The item is a silhouette (ADR-248)
##
## Each item Resource owns an authored ink icon. Compact cells keep the icon
## and weight; taller items also show their name, and the hover readout always
## gives the complete name and description. Packing and rotation still use the
## item's real footprint, independently of the art fitted inside it.
##
## ## Numbers are allowed here, and only here
##
## `DES-019` rule 2 bans numbers during a run — health is not `73/100` — with
## one stated exception: *"the inventory screen, where you are deliberately
## doing arithmetic."* That is exactly what this is for. Kilograms against
## capacity, cells against grid, and how far you can be heard from standing
## still, because those three numbers **are** the decision the M2 gate is
## asking about.
##
## ## Both devices reach everything (ADR-075)
##
## Mouse drags. The right stick moves a cell cursor, because `Player` suspends
## look while the bag is open and hands the stick over — which is why bag
## control needs no bindings of its own beyond `rotate_item`. Prompts name both
## devices, per `DES-019` rule 7.

## **The six slots** (`M3-T07`, `DES-020`), worn on a body beside the grid
## (ADR-342).
##
## In the bag rather than on a screen of its own, because `DES-019` is hostile
## to persistent UI and the decision *"is this worth carrying or worth
## wearing"* is one question — putting it in two places would make it two.
## The order here is the order a pad's cursor would meet them in.
const SLOT_ROW: Array[Enums.Slot] = [
	Enums.Slot.MAIN_HAND, Enums.Slot.OFF_HAND, Enums.Slot.ARMS,
	Enums.Slot.HEAD, Enums.Slot.BODY, Enums.Slot.PACK,
]

## **Only the slots something can go in** (ADR-218).
##
## The row drew all six, and nothing in the item folder has ever been worn on
## the head or the arms — so a tester saw two places gear goes that no gear
## goes, which is ADR-064's stub in a row of outlines. `DES-023` fills them
## with a helm and bracers when wounds exist (`M4-T14`). This reads the folder,
## so those slots appear the day the items do and nothing here changes.
static func slots_for(corpus: Array[ItemResource]) -> Array[Enums.Slot]:
	var named: Dictionary = {}
	for item: ItemResource in corpus:
		named[item.slot] = true
	var out: Array[Enums.Slot] = []
	for slot: Enums.Slot in SLOT_ROW:
		if named.has(slot):
			out.append(slot)
	return out


const SLOT_LABEL: Dictionary = {
	Enums.Slot.MAIN_HAND: "hand", Enums.Slot.OFF_HAND: "off",
	Enums.Slot.ARMS: "arms", Enums.Slot.HEAD: "head",
	Enums.Slot.BODY: "body", Enums.Slot.PACK: "pack",
}
const SLOT_SIZE: float = 52.0

## ## The body beside the bag (ADR-342)
##
## Reported from play: the interface wanted to be *"more Diablo-esque — the
## character screen and equipment"*. Every action RPG since Diablo puts worn
## gear **on a figure**: the helm where a head is, the weapon in the hand it is
## held in, the pack on the back. A row of six squares under a grid asks the
## player to map *hand, off, arms* onto a body in their head; a figure answers
## it before anything is read. Grim Dawn, Path of Exile and Last Epoch keep the
## figure and the bag side by side for the same reason this does: *"is this
## worth carrying or worth wearing"* is one question, asked across one panel.
##
## The figure is the class's own portrait, cropped to the body and drawn dark
## — it is the life you are equipping, not a mannequin.
const DOLL_WIDTH: float = 236.0
## The figure's own height: the six slots are placed against it.
const DOLL_HEIGHT: float = 300.0
## The class's name and rank above the figure.
const DOLL_TITLE: float = 34.0
## Health, breath, wounds and the verb, under it.
const DOLL_STATS: float = 96.0
const DOLL_STAT_LEAD: float = 19.0
## Between the body and the bag.
const COLUMN_GAP: float = 26.0
## Where each worn slot sits on the figure, as fractions of the doll's box —
## its top-left corner. Head over the head, body on the chest, the hands at the
## hands, arms below the hand that guards, the pack on the far side.
const SLOT_ON_BODY: Dictionary = {
	Enums.Slot.HEAD: Vector2(0.5, 0.02),
	Enums.Slot.BODY: Vector2(0.5, 0.34),
	Enums.Slot.MAIN_HAND: Vector2(0.0, 0.44),
	Enums.Slot.OFF_HAND: Vector2(1.0, 0.44),
	Enums.Slot.ARMS: Vector2(0.0, 0.74),
	Enums.Slot.PACK: Vector2(1.0, 0.74),
}

## ## The item card (ADR-342)
##
## What the thing under your hands is, in a card beside them rather than a band
## at the foot of the panel — Diablo's tooltip, which every successor kept
## because the eye is already at the cursor. The band it replaces held a name
## and two wrapped lines; the card has room to say what the thing **is to you**:
## where it is worn, what it weighs, how far it is heard, and what she would
## give for it.
const CARD_WIDTH: float = 272.0
const CARD_PAD: float = 14.0
const CARD_NAME_TEXT: int = 17
const CARD_TEXT: int = 13
const CARD_LEAD: float = 18.0
## How many wrapped lines of description a card will draw. Every authored
## description fits in four at this width; `overflowing()` checks that.
const CARD_LINES: int = 5
## How far from the hands the card sits.
const CARD_OFFSET: Vector2 = Vector2(22.0, 10.0)

const CELL: float = 44.0
const GAP: float = 3.0
const PADDING: float = 18.0
const HEADER: float = 64.0
## **Deep enough that the frame does not eat the last prompt** (`M4-T05`).
##
## It was 30, which put the second prompt's descender 5 px above the panel
## edge — clear of the 1 px border it was measured against, and *inside* the
## carved band that replaced it. The same fault as ADR-140 with a different
## thing doing the overdrawing, so `overflowing()` now asks the stylebox how
## thick it is rather than trusting a number written here.
const FOOTER: float = 52.0
## Where the first prompt's baseline sits above the panel's bottom edge, and
## how far the second follows it. Named because the layout check and the
## drawing both need them, and a remembered number is what ADR-140 was about.
const FOOTER_BASE: float = 12.0
const FOOTER_LEAD: float = 14.0
## ## The sizes here are the theme's scale, in a control that paints (`M4-T05`)
##
## `draw_string` takes a number, not a role, so this screen names its steps as
## constants — but they are **the nine steps `MenuStyle` defines**, not a
## private set. They were 16, 13, 12 and 12: two of those are not on the scale
## at all, which is the same drift as the nine hard-coded colours above and
## found the same way.
##
## They stay constants rather than theme lookups because this panel's whole
## geometry is measured against them — `FOOTER` and the card are sized to fit
## these lines, and `overflowing()` checks that fit every run. A size that
## moved without its band moving is the ADR-140 fault again.
## The header line sits to the right of the word BAG; this is that gap.
const HEADER_INSET: float = 46.0
const HEADER_TEXT: int = 15
const FOOTER_TEXT: int = 13
## An item's own name and weight, inside its cell.
const CELL_TEXT: int = 13
## The word under a slot, and the smallest thing this screen draws.
const SLOT_TEXT: int = 11
## A radius wide enough that no real bag exceeds it, used to size the panel to
## its worst case rather than to whatever it holds right now.
const WIDEST_RADIUS: float = 99.9
## Both prompt lines, in one place so the layout check and the drawing agree.
##
## **The wording is authored here and the keys come from `ControlsScreen`**
## (ADR-139). The bag says *take & place* where the control list says *pick up,
## and place in the bag* — that is a real difference of context, not drift. The
## keys are the half that moves, and this line said `rmb/RB turn` while the
## screen said `R`, because two hand-typed lists is one too many. A function
## rather than a `const`, since `InputMap` is not loaded when constants are.
static func footer_lines() -> Array[String]:
	return [
		"%s take & place    %s turn" % [
			ControlsScreen.glyphs_for("interact"),
			ControlsScreen.glyphs_for("rotate_item")],
		"drag out or %s drop    %s use    %s close" % [
			ControlsScreen.glyphs_for("drop"),
			ControlsScreen.glyphs_for("use_item"),
			ControlsScreen.glyphs_for("bag")],
	]

## Screen pixels per second the gamepad cursor travels at full deflection.
const CURSOR_RATE: float = 620.0

## **How dense the hatch over an overloaded bar is.** Tighter than a panel's
## grain, because a 8 px bar with the panel's 7 px pitch would show two strokes
## and read as a rendering artefact rather than as a mark.
const OVER_PITCH: float = 4.0

## ## Every colour on this screen comes from the theme (`M4-T05`, ADR-216)
##
## Nine of them were `const Color` in this file, and five were *within 0.03* of
## a theme tone without being equal to one — `TEXT_COLOUR` was `0.86, 0.84,
## 0.80` where the `Text` tone is `0.87, 0.85, 0.81`. So ADR-216's promise that
## a palette swap is **"five tones, not twenty-two roles"** held for every
## screen except the one a player spends the most time inside.
##
## Nothing was broken by it, which is exactly why it survived: the near-misses
## are invisible side by side, and the only symptom is that the bag does not
## move when the register does. `M4-T11`'s high-contrast palette would have
## reached every screen in the game and stopped at this one.
##
## The four that are genuinely not tones — *this fits*, *this does not*, *full*
## and *over* — are colours on a `Bag` theme type rather than constants, so a
## palette reaches them too.
##
## Cached and dropped on `NOTIFICATION_THEME_CHANGED`: `_draw` runs every frame
## the bag is open, and a theme lookup is a walk up the tree.
var _palette: Dictionary = {}

var _player: Player = null
var _inventory: Inventory = null
## `slots_for` the folder, asked once: the folder does not change mid-run.
var _slots: Array[Enums.Slot] = []

## Where the hands are, in screen pixels. Mouse motion assigns it; the right
## stick integrates into it. Whichever moved last wins, which is the whole
## device-switching rule and needs no mode flag to track.
var _cursor: Vector2 = Vector2.ZERO
var _held: ItemInstance = null
var _held_rotated: bool = false
## Cursor cell minus the held item's origin cell, so a dragged item does not
## snap its corner to the pointer the instant you grab it.
var _grab: Vector2i = Vector2i.ZERO
## Whether `rotate_item` is still held from the pull that last turned the item.
var _turn_pulled: bool = false


## Build a bag for one player and hang it off them. A `CanvasLayer` in between
## because a `Control` parented straight to a `Node3D` never renders — and
## parenting it to the player rather than the level means it dies with the body
## it belongs to, which is the lifecycle the churn probe walks over.
static func attach(to: Player) -> BagScreen:
	var layer := CanvasLayer.new()
	layer.name = "BagLayer"
	var screen := BagScreen.new()
	screen.name = "BagScreen"
	screen._player = to
	screen._inventory = to.inventory
	layer.add_child(screen)
	to.add_child(layer)
	return screen


func _ready() -> void:
	# **`_and_offsets_`, or this control has no rect and takes no clicks**
	# (`M2-T18`, ADR-111). `set_anchors_preset` sets the anchors and leaves the
	# offsets, and a `Control` parented to a `CanvasLayer` is not laid out by
	# anything — so this sat at **0 x 0** while drawing a 315 x 362 panel in the
	# middle of the screen. Godot routes a mouse event to a control only if the
	# point is inside its rect, so `_gui_input` never fired once: no clicking an
	# item, no dragging one out, and therefore no way to abandon loot with the
	# mouse at all. `Reticle` carries a note about this exact trap and uses the
	# right call; this was the one screen that did not.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# STOP so a click meant for an item never also swings the weapon. Invisible
	# controls receive nothing, so a shut bag costs no input at all.
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_cursor = get_viewport_rect().size * 0.5
	_inventory.changed.connect(queue_redraw)


## Driven by `Player`, which owns the open/shut transition because the movement
## penalty and the fade have to be the same number (`DES-019` charges time).
func set_openness(openness: float) -> void:
	var open: bool = openness > 0.0
	if open and not visible:
		# Start the cursor in the middle of the grid rather than wherever the
		# pointer happened to be left, so a controller player is never hunting
		# for a cursor parked off-screen.
		_cursor = _grid_origin() + Vector2(_inventory.grid()) * (CELL + GAP) * 0.5
	visible = open
	modulate.a = openness
	if not open:
		# Whatever was in hand goes back where it was. Nothing was mutated —
		# the host owns the bag and was never told — so this is genuinely just
		# letting go.
		_held = null
	queue_redraw()


## Where the hands are, in screen pixels. Public because the layout check needs
## to know whether a click reached `_gui_input` at all.
func cursor() -> Vector2:
	return _cursor


## What `drop` should act on: the item in hand, or the one under the cursor.
## Screen point at the middle of the first item in the bag, so `--bag-shot` can
## put the pointer on something without knowing this file's geometry.
func first_item_middle() -> Vector2:
	for item: ItemInstance in _inventory.items():
		return _cell_rect(item.cell, item.footprint()).get_center()
	return _grid_origin()


## Screen point at the middle of the grid's far corner cell, so `--bag-shot`
## can put the pointer somewhere nothing larger than one cell can fit without
## knowing this file's geometry.
func last_cell_middle() -> Vector2:
	return _cell_rect(_inventory.grid() - Vector2i.ONE, Vector2i.ONE).get_center()


## **Whether what is in hand would be refused where the cursor is** — the
## question the ghost answers, in code, so a shot can assert it is
## photographing a refusal rather than assume it staged one. ADR-198's rule:
## a readout drawing the right shape while saying the wrong thing is the fault
## a photograph is least able to catch.
func refusing() -> bool:
	if _held == null or not _within_grid(_cursor):
		return false
	return not _inventory.fits(_held_footprint(), _cursor_cell() - _grab, _held)


func hovered() -> ItemInstance:
	if _held != null:
		return _held
	var worn: Enums.Slot = _slot_at(_cursor)
	if worn != Enums.Slot.NONE and _player.equipment != null:
		return _player.equipment.in_slot(worn)
	return _item_at(_cursor_cell())


func _process(delta: float) -> void:
	if not visible:
		return
	# The stick the player is not looking with. `Player._apply_stick_look`
	# returns early while the bag is open, so this cannot fight it.
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick.length_squared() > 0.0:
		_cursor += stick * CURSOR_RATE * delta
		_cursor = _cursor.clamp(Vector2.ZERO, get_viewport_rect().size)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_cursor = (event as InputEventMouseMotion).position
		return
	var button := event as InputEventMouseButton
	if button == null:
		return
	_cursor = button.position
	if button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
		_turn()
	elif button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_grab_at_cursor()
		else:
			_release()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Gamepad and keyboard: `interact` toggles hold-and-place rather than
	# requiring a button to be held down across a stick movement, which is the
	# convention every console inventory has settled on.
	if event.is_action_pressed("interact"):
		if _held == null:
			_grab_at_cursor()
		else:
			_release()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rotate_item"):
		# One pull is one turn. On the pad this is the left trigger (ADR-292),
		# and an axis reports *pressed* on every motion event past the dead zone
		# — so held, it would spin the item every frame the trigger moved.
		if not _turn_pulled:
			_turn()
		_turn_pulled = true
		get_viewport().set_input_as_handled()
	elif event.is_action_released("rotate_item"):
		_turn_pulled = false
	elif event.is_action_pressed("use_item"):
		_use_at_cursor()
		get_viewport().set_input_as_handled()


# ── the hands ─────────────────────────────────────────────────────────────


func _grab_at_cursor() -> void:
	# **On a filled slot, taking it off** (`M3-T07`, `DES-020`). Slots have to
	# be reversible — a player who can put a byrnie on and not take it off has
	# been given a one-way door, and `DES-019` sells the bag as the place you
	# reorganise under pressure.
	#
	# A press rather than a drag out, deliberately: the item lands in the bag
	# and can then be dragged like anything else, so there is no second kind of
	# held item with its own rules about where it may be dropped. The refusal
	# when the bag is full is the host's (`Player._unequip_to_bag`) — you asked
	# to stow it, not to abandon it.
	var from_slot: Enums.Slot = _slot_at(_cursor)
	if from_slot != Enums.Slot.NONE:
		if _player.equipment.in_slot(from_slot) != null:
			_player.ask_to_unequip(from_slot)
		return
	var item: ItemInstance = _item_at(_cursor_cell())
	if item == null:
		return
	_held = item
	_held_rotated = item.rotated
	_grab = _cursor_cell() - item.cell


## **Use what the hands are on** (`M4-T32`, ADR-221): a binding or a rune.
##
## The bag shuts as you do it. Tying linen and breaking a stave are done looking
## at the room, not into a satchel — and the binding's ring is at the crosshair,
## which the open bag hides. A press that would do nothing — a coin, or a binding
## on a body with no wound — sends nothing and leaves the bag open, because
## nothing happened (`Player.can_use`, the rule the host asks too).
func _use_at_cursor() -> void:
	var item: ItemInstance = hovered()
	if not _player.can_use(item):
		return
	# A held item is the host's still, in the cell it came from, so letting go
	# of it here is just letting go (see `set_openness`).
	_held = null
	_player.ask_to_use(item.instance_id)
	_player.close_bag()


func _turn() -> void:
	if _held == null:
		return
	# A square item has nothing to turn, and letting it "rotate" would send a
	# request the host correctly ignores while the screen showed it moving.
	var size: Vector2i = _held.definition.grid_size
	if size.x == size.y:
		return
	_held_rotated = not _held_rotated
	# The grab offset was measured against the old orientation; keeping it
	# would make a turned item lurch away from the cursor.
	_grab = Vector2i.ZERO


func _release() -> void:
	if _held == null:
		return
	var item: ItemInstance = _held
	_held = null
	# **Onto a slot is putting it on** (`M3-T07`). Checked before the
	# out-of-bag test, because the slot row sits outside the grid and dropping
	# a helm on it would otherwise read as abandoning it on the floor.
	var onto: Enums.Slot = _slot_at(_cursor)
	if onto != Enums.Slot.NONE:
		if item.definition.slot == onto:
			_player.ask_to_equip(item.instance_id)
		return
	var target: Vector2i = _cursor_cell() - _grab
	if not _within_grid(_cursor):
		# Dragged out of the bag entirely. `DES-005`'s primal counter-play,
		# and it is deliberately the same gesture as putting something down on
		# a table — the abandonment should feel like a physical act, not a menu
		# confirmation.
		_player.ask_to_drop_instance(item.instance_id)
		return
	if target == item.cell and _held_rotated == item.rotated:
		return
	_player.ask_to_move(item.instance_id, target, _held_rotated)


# ── geometry ──────────────────────────────────────────────────────────────


func _grid_pixels() -> Vector2:
	var grid: Vector2i = _inventory.grid()
	return Vector2(grid.x * CELL + (grid.x - 1) * GAP,
		grid.y * CELL + (grid.y - 1) * GAP)


## **The box is as wide as the widest thing in it** (`M2-T18`, ADR-111).
##
## It used to be exactly the grid, and the header line — weight, cells and the
## noise radius, which are `DES-019`'s three decision numbers — was drawn at
## `-1` width, meaning *do not clip*. Measured: **334 px of text in 233 px of
## box**, running out past the panel edge and over the world behind it.
##
## Clipping it would have been the smaller change and the wrong one: the footer
## two lines below carries a note about exactly that mistake — *"a prompt that
## names both devices and then gets cut off names neither"*. So the panel grows
## instead, and the grid centres inside it.
func _panel_rect() -> Rect2:
	var inner: Vector2 = _grid_pixels()
	var body: float = maxf(DOLL_TITLE + DOLL_HEIGHT + DOLL_STATS, HEADER + inner.y)
	var size := Vector2(PADDING * 2.0 + DOLL_WIDTH + COLUMN_GAP + _bag_width(),
		PADDING * 2.0 + body + FOOTER)
	var screen: Vector2 = get_viewport_rect().size
	return Rect2(((screen - size) * 0.5).round(), size)


## The bag's column: as wide as the grid or the header line, whichever is wider.
func _bag_width() -> float:
	return maxf(_grid_pixels().x, _header_width())


## The right-hand column, where the header, the grid and their numbers are.
func _bag_column() -> Rect2:
	var panel: Rect2 = _panel_rect()
	var left: float = panel.position.x + PADDING + DOLL_WIDTH + COLUMN_GAP
	return Rect2(Vector2(left, panel.position.y + PADDING),
		Vector2(_bag_width(), panel.size.y - PADDING * 2.0 - FOOTER))


## The figure the slots are worn on, under the class's name.
func _doll_rect() -> Rect2:
	var panel: Rect2 = _panel_rect()
	return Rect2(panel.position + Vector2(PADDING, PADDING + DOLL_TITLE),
		Vector2(DOLL_WIDTH, DOLL_HEIGHT))


## How wide the header needs, measured against the **widest** numbers it can
## ever hold rather than the ones on screen now. Sizing to the live string would
## make the whole panel breathe by a few pixels every time a coin went in.
func _header_width() -> float:
	var grid: Vector2i = _inventory.grid()
	var cells: int = grid.x * grid.y
	var widest: String = _header_summary(
		_player.carried.capacity(), cells, WIDEST_RADIUS)
	return HEADER_INSET + get_theme_default_font().get_string_size(
		widest, HORIZONTAL_ALIGNMENT_LEFT, -1, HEADER_TEXT).x


## One place the header line is built, so the width it is measured at and the
## width it is drawn at cannot drift apart.
func _header_summary(kilograms: float, used: int, radius: float) -> String:
	var grid: Vector2i = _inventory.grid()
	return "%.1f / %.0f kg     %d / %d cells     heard from %.1f m" % [
		kilograms, _player.carried.capacity(), used, grid.x * grid.y, radius]


## Every line this screen draws that does not fit the box it is drawn in.
## Empty when the layout is honest; read by `--bagui-probe`.
func overflowing() -> PackedStringArray:
	var font: Font = get_theme_default_font()
	var panel: Rect2 = _panel_rect()
	var spilled := PackedStringArray()
	var header: String = _header_summary(_player.carried.kilograms,
		_inventory.cells_used(), _carried_radius())
	var room: float = _bag_column().size.x - HEADER_INSET
	var drawn: float = font.get_string_size(header,
		HORIZONTAL_ALIGNMENT_LEFT, -1, HEADER_TEXT).x
	if drawn > room:
		spilled.append("header is %.0f px in %.0f px: %s" % [drawn, room, header])
	for line: String in footer_lines():
		var wide: float = font.get_string_size(line,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FOOTER_TEXT).x
		if wide > panel.size.x - PADDING * 2.0:
			spilled.append("footer is %.0f px in %.0f px: %s" % [
				wide, panel.size.x - PADDING * 2.0, line])

	# **And whether every item's card fits on the screen** (ADR-140, ADR-342).
	#
	# The band this replaced was the one region whose height was not fixed, and
	# the card inherits that: a name, a kind, up to `CARD_LINES` of description
	# and the numbers. Measured per item against the font rather than against a
	# remembered height, so a longer description or a larger type fails here
	# rather than running off the bottom of somebody's screen.
	# Against the smallest window the game is laid out for, not the live
	# viewport — headless, that is 64 px and every card would fail.
	var screen := Vector2(1152.0, 648.0)
	if panel.size.y > screen.y or panel.size.x > screen.x:
		spilled.append("the panel is %.0f × %.0f on a %.0f × %.0f screen" % [
			panel.size.x, panel.size.y, screen.x, screen.y])
	for definition: ItemResource in ItemCatalogue.all():
		var wrapped: int = _wrapped_lines(definition.describe(), font)
		if wrapped > CARD_LINES:
			spilled.append("%s's description wraps to %d lines and the card draws %d"
				% [definition.id, wrapped, CARD_LINES])
		var tall: float = _card_height(ItemInstance.of(definition, 0))
		if tall > screen.y - PADDING * 2.0:
			spilled.append("%s's card is %.0f px on a %.0f px screen" % [
				definition.id, tall, screen.y])

	# **And the weight inside each cell** (ADR-140). `0.04 kg` overflowed a 36 px
	# cell and rendered as `0.04 k`, which a player reads as a broken renderer
	# rather than as a weight. Checked per item rather than against a worst
	# case, because footprint width is what decides it and the narrowest things
	# in this game are the lightest.
	#
	# **It is coarser than the screen it defends.** Restoring the unit does not
	# fail this row: the headless dummy renderer's font metrics are a few pixels
	# more generous than the real one, so a marginal overflow measures as a fit
	# here and clips in the window. Planting a long string does fail it, so the
	# row is live rather than decorative — but the four pixels that started this
	# were caught by a **photograph**, which is why `--bag-shot` now hovers.
	for item: ItemInstance in _inventory.items():
		var cell_room: float = item.footprint().x * (CELL + GAP) - GAP - 8.0
		var weight: String = _kilograms(item.weight())
		if item.footprint().x <= 1:
			weight = weight.replace(" kg", "")
		var drawn_at: float = font.get_string_size(
			weight, HORIZONTAL_ALIGNMENT_LEFT, -1, CELL_TEXT).x
		if drawn_at > cell_room:
			spilled.append("%s's weight is %.0f px in %.0f px: %s" % [
				item.definition.id, drawn_at, cell_room, weight])

	# **And whether the panel's own frame is drawn over the last line**
	# (`M4-T05`). Same shape of fault as the blurb above, with the overdrawing
	# done by the border rather than by other text: the second prompt's
	# descender sat 5 px above the panel edge, which was clear of a 1 px border
	# and inside the carved band that replaced it. A screenshot is the only
	# thing that ever sees this, and only if somebody looks at the corner.
	#
	# Asked of the **stylebox**, not of a number copied out of it, so a heavier
	# frame is a failing row here rather than a clipped prompt on somebody's
	# screen — which is the whole argument ADR-140 makes about remembered
	# numbers, applied to the thing that just changed underneath them.
	var carved := get_theme_stylebox(&"panel", MenuStyle.SLATE) as CarvedFrame
	if carved != null:
		var thick: float = carved.bevel + carved.band + carved.inset + carved.hairline
		var clear: float = (FOOTER - FOOTER_BASE - FOOTER_LEAD
			- font.get_descent(FOOTER_TEXT))
		if clear < thick:
			spilled.append(("the last prompt clears the panel edge by %.0f px "
				+ "and the frame is %.0f px thick, so the band is drawn through "
				+ "it") % [clear, thick])
	return spilled


## Where a slot sits: **on the body** (ADR-342), at its place on the figure.
func _slot_rect(slot: Enums.Slot) -> Rect2:
	var doll: Rect2 = _doll_rect().grow(-8.0)
	var at: Vector2 = SLOT_ON_BODY.get(slot, Vector2(0.5, 0.5))
	var room: Vector2 = doll.size - Vector2(SLOT_SIZE, SLOT_SIZE)
	return Rect2((doll.position + room * at).round(), Vector2(SLOT_SIZE, SLOT_SIZE))


## The slot under a point, or `NONE`.
func _slot_at(point: Vector2) -> Enums.Slot:
	for slot: Enums.Slot in slots():
		if _slot_rect(slot).has_point(point):
			return slot
	return Enums.Slot.NONE


## **An empty slot says what goes in it** (`M4-T20`, TEC-009 §5.5).
##
## The six slots were empty outlines with a word underneath, which reads as six
## disabled buttons rather than as six places gear goes — and the word is only
## legible if you are already looking at it, which is the wrong way round for a
## screen you open under time pressure.
##
## Nielsen #6, **recognition over recall**: a ghosted mark of the kind of thing
## that belongs there answers *where does this go* before you have read
## anything. `DES-018` requires it be carried by **shape**, not hue, so these
## are primitives — a haft, a round shield, a dome — and they survive both
## monochrome and a glance.
##
## Drawn, not authored. `M4-T05` replaces these with real icons; that is an
## asset swap behind one function, which is the point of putting them here.
func _slot_mark(box: Rect2, slot: Enums.Slot, tint: Color) -> void:
	var middle: Vector2 = box.position + box.size * 0.5
	var reach: float = minf(box.size.x, box.size.y) * 0.30
	var weight: float = 2.0
	match slot:
		Enums.Slot.MAIN_HAND:
			# A haft, on the diagonal a swing follows.
			draw_line(middle + Vector2(-reach, reach),
				middle + Vector2(reach, -reach), tint, weight)
			draw_line(middle + Vector2(reach * 0.2, -reach),
				middle + Vector2(reach, -reach * 0.2), tint, weight)
		Enums.Slot.OFF_HAND:
			# A round shield: the one mark that is a closed curve.
			draw_arc(middle, reach, 0.0, TAU, 20, tint, weight)
		Enums.Slot.ARMS:
			draw_line(middle + Vector2(-reach, -reach * 0.5),
				middle + Vector2(-reach * 0.2, reach), tint, weight)
			draw_line(middle + Vector2(reach, -reach * 0.5),
				middle + Vector2(reach * 0.2, reach), tint, weight)
		Enums.Slot.HEAD:
			# A dome with a brow line under it.
			draw_arc(middle + Vector2(0.0, reach * 0.3), reach, PI, TAU,
				16, tint, weight)
			draw_line(middle + Vector2(-reach, reach * 0.4),
				middle + Vector2(reach, reach * 0.4), tint, weight)
		Enums.Slot.BODY:
			draw_rect(Rect2(middle - Vector2(reach * 0.7, reach),
				Vector2(reach * 1.4, reach * 2.0)), tint, false, weight)
		Enums.Slot.PACK:
			draw_rect(Rect2(middle - Vector2(reach * 0.8, reach * 0.6),
				Vector2(reach * 1.6, reach * 1.6)), tint, false, weight)
			draw_arc(middle + Vector2(0.0, -reach * 0.6), reach * 0.5,
				PI, TAU, 12, tint, weight)
		_:
			pass


## The slots this bag draws — `slots_for` the item folder. Read by
## `--bagui-probe`.
func slots() -> Array[Enums.Slot]:
	if _slots.is_empty():
		_slots = slots_for(ItemCatalogue.all())
	return _slots


func _draw_slots() -> void:
	var worn: Equipment = _player.equipment
	for slot: Enums.Slot in slots():
		var box: Rect2 = _slot_rect(slot)
		var item: ItemInstance = worn.in_slot(slot) if worn != null else null
		# A slot the held item could go into lights up while you are dragging,
		# so the answer to "where does this go" is visible before you let go
		# rather than discovered by trying.
		var wanted: bool = (_held != null
			and _held.definition.slot == slot)
		get_theme_stylebox(&"panel", MenuStyle.SOCKET).draw(get_canvas_item(), box)
		var warm: Color = palette()[&"warm"] as Color
		var faint: Color = palette()[&"dim"] as Color
		# Over the socket's own band rather than instead of it, so a lit slot is
		# the same shape carried heavier — the row never changes its geometry
		# while you are dragging across it.
		if wanted:
			draw_rect(box, warm, false, 2.0)
		if item != null:
			draw_rect(box.grow(-6.0), palette()[&"cell"] as Color)
			_draw_icon(item.definition.icon, box.grow(-7.0), 1.0)
			# The mark stays over a worn item, dark against it. The slot keeps
			# saying what it is even when it is full, so the row still scans as
			# a body rather than as six coloured squares.
			_slot_mark(box, slot, Color(palette()[&"mark"] as Color, 0.75))
		else:
			# Brighter while it is the slot you are dragging toward — the same
			# signal the border gives, said twice, because `DES-018` will not
			# let the border's colour carry it alone.
			_slot_mark(box, slot,
				warm if wanted else Color(faint, 0.55))
		var font: Font = get_theme_default_font()
		draw_string(font, box.position + Vector2(4.0, box.size.y + 12.0),
			String(SLOT_LABEL[slot]), HORIZONTAL_ALIGNMENT_LEFT, -1, SLOT_TEXT, faint)


func _grid_origin() -> Vector2:
	var column: Rect2 = _bag_column()
	var inner: Vector2 = _grid_pixels()
	# Centred, because the column is allowed to be wider than the grid.
	return column.position + Vector2(((column.size.x - inner.x) * 0.5), HEADER).round()


func _cell_rect(at: Vector2i, size: Vector2i) -> Rect2:
	var origin: Vector2 = _grid_origin()
	return Rect2(
		origin + Vector2(at) * (CELL + GAP),
		Vector2(size) * (CELL + GAP) - Vector2(GAP, GAP))


func _cursor_cell() -> Vector2i:
	var local: Vector2 = _cursor - _grid_origin()
	return Vector2i(floori(local.x / (CELL + GAP)), floori(local.y / (CELL + GAP)))


func _within_grid(point: Vector2) -> bool:
	return Rect2(_grid_origin(), _grid_pixels()).has_point(point)


func _item_at(cell: Vector2i) -> ItemInstance:
	for item: ItemInstance in _inventory.items():
		var size: Vector2i = item.footprint()
		if (cell.x >= item.cell.x and cell.x < item.cell.x + size.x
				and cell.y >= item.cell.y and cell.y < item.cell.y + size.y):
			return item
	return null


func _held_footprint() -> Vector2i:
	var size: Vector2i = _held.definition.grid_size
	return Vector2i(size.y, size.x) if _held_rotated else size


# ── drawing ───────────────────────────────────────────────────────────────


## Every colour this screen paints with, resolved from the theme it is under.
## Public because that is the claim `--bagui-probe` checks: it paints the theme
## a small number of flat colours and asks whether anything in here is another
## one, which no amount of reading the file can establish.
func palette() -> Dictionary:
	if _palette.is_empty():
		_palette = {
			&"text": MenuStyle.tone(self, MenuStyle.TEXT),
			&"dim": MenuStyle.tone(self, MenuStyle.DIM),
			&"warm": MenuStyle.tone(self, MenuStyle.WARM),
			&"line": get_theme_color(&"line", MenuStyle.BAG),
			&"legal": get_theme_color(&"legal", MenuStyle.BAG),
			&"illegal": get_theme_color(&"illegal", MenuStyle.BAG),
			&"load": get_theme_color(&"load", MenuStyle.BAG),
			&"overload": get_theme_color(&"overload", MenuStyle.BAG),
			&"scrim": get_theme_color(&"scrim", MenuStyle.BAG),
			&"mark": get_theme_color(&"mark", MenuStyle.BAG),
			&"worth_none": MenuStyle.tone(self, MenuStyle.DIM),
			&"worth_trifle": MenuStyle.tone(self, MenuStyle.TEXT),
			&"worth_fair": get_theme_color(&"worth_fair", MenuStyle.BAG),
			&"worth_rich": get_theme_color(&"worth_rich", MenuStyle.BAG),
			&"worth_kingly": get_theme_color(&"worth_kingly", MenuStyle.BAG),
			&"panel": MenuStyle.ground(self, MenuStyle.SLATE),
			&"cell": MenuStyle.ground(self, MenuStyle.SOCKET),
		}
	return _palette


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_palette = {}
		queue_redraw()


func _draw() -> void:
	var panel: Rect2 = _panel_rect()
	# **The world goes quiet behind it** (`M4-T20`).
	#
	# The panel floated over a lit room at full contrast, so the first thing the
	# eye found on opening the bag was whatever happened to be behind it. A wash
	# rather than a blackout — `DES-019` makes the bag **real-time** *"because
	# rummaging is a vulnerable act"*, and a screen that hid the room would hand
	# back exactly the safety the inventory is designed to deny. You can still
	# see something coming.
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size),
		palette()[&"scrim"] as Color)
	# **The panel is the theme's, not a rectangle that resembles it** (`M4-T05`).
	# Drawn by the same `CarvedFrame` object the Chamber's readout is laid out
	# in, so the one screen that paints itself by hand cannot drift from the ones
	# that do not — which is precisely how it came to be three near-misses away.
	get_theme_stylebox(&"panel", MenuStyle.SLATE).draw(get_canvas_item(), panel)
	_draw_doll(panel)
	_draw_header(_bag_column())
	_draw_slots()
	_draw_cells()
	for item: ItemInstance in _inventory.items():
		if item != _held:
			_draw_item(item, _cell_rect(item.cell, item.footprint()), 1.0)
	# A hairline between the body and the bag, and one above the prompts.
	# Gestalt common region, the argument `MenuStyle.rule()` already makes.
	var line := Color(palette()[&"line"] as Color, 0.55)
	draw_rect(Rect2(panel.position.x + PADDING + DOLL_WIDTH + COLUMN_GAP * 0.5,
		panel.position.y + PADDING, 1.0, panel.size.y - PADDING * 2.0 - FOOTER), line)
	draw_rect(Rect2(panel.position.x + PADDING,
		panel.end.y - PADDING - FOOTER + 4.0, panel.size.x - PADDING * 2.0, 1.0), line)
	_draw_footer(panel)
	if _held != null:
		_draw_held()
	else:
		var item: ItemInstance = hovered()
		if item != null and item.definition != null:
			_draw_card(item, _cursor)


## **The body** (ADR-342): who this is, the figure the slots are worn on, and
## what the body itself is carrying — health and breath as bars, the wounds by
## name, and the verb only this class has.
##
## Health is a bar and not a number on purpose: `DES-019` rule 2 bans numbers
## for the body, and its one exception — *"the inventory screen, where you are
## deliberately doing arithmetic"* — is about what you carry, which the bag's
## own header already counts.
func _draw_doll(panel: Rect2) -> void:
	var font: Font = get_theme_default_font()
	var at: Vector2 = panel.position + Vector2(PADDING, PADDING + 18.0)
	var body: ClassResource = ClassCatalogue.by_id(_player.sworn)
	var who: String = body.display() if body != null else "Unsworn"
	draw_string(get_theme_font(&"font", MenuStyle.DISPLAY_WARM), at, who,
		HORIZONTAL_ALIGNMENT_LEFT, DOLL_WIDTH * 0.7, HEADER_TEXT + 4,
		palette()[&"warm"] as Color)
	draw_string(font, at + Vector2(DOLL_WIDTH * 0.7, 0.0), "rank %d" % GameState.pact_rank,
		HORIZONTAL_ALIGNMENT_RIGHT, DOLL_WIDTH * 0.3, CARD_TEXT, palette()[&"dim"] as Color)

	var doll: Rect2 = _doll_rect()
	get_theme_stylebox(&"panel", MenuStyle.SOCKET).draw(get_canvas_item(), doll)
	# The class's portrait, cropped to the doll's own proportions around the
	# body and darkened, so the slots read on it rather than fight it.
	if body != null and body.portrait != null:
		var source: Vector2 = body.portrait.get_size()
		var drawn: Rect2 = doll.grow(-6.0)
		var wide: float = minf(source.x, source.y * drawn.size.x / drawn.size.y)
		var region := Rect2(Vector2((source.x - wide) * 0.5, 0.0), Vector2(wide, source.y))
		draw_texture_rect_region(body.portrait, drawn, region, Color(1.0, 1.0, 1.0, 0.42))

	var stats: Rect2 = Rect2(Vector2(doll.position.x, doll.end.y + 8.0),
		Vector2(DOLL_WIDTH, DOLL_STATS - 8.0))
	var y: float = stats.position.y + 13.0
	_draw_bar_row("health", _player.health.fraction(), stats.position.x, y)
	y += DOLL_STAT_LEAD
	_draw_bar_row("breath", _player.stamina.fraction(), stats.position.x, y)
	y += DOLL_STAT_LEAD
	_draw_stat_row("wounds", WoundMarks.named(_player.wounds), stats.position.x, y)
	y += DOLL_STAT_LEAD
	if body != null and body.verb != &"":
		_draw_stat_row("verb", "%s  (%s)" % [String(body.verb).capitalize(),
			ControlsScreen.glyphs_for("verb")], stats.position.x, y)


const STAT_KEY: float = 62.0


func _draw_stat_row(key: String, value: String, x: float, y: float) -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(x, y), key, HORIZONTAL_ALIGNMENT_LEFT, STAT_KEY,
		CARD_TEXT, palette()[&"dim"] as Color)
	draw_string(font, Vector2(x + STAT_KEY, y), value, HORIZONTAL_ALIGNMENT_LEFT,
		DOLL_WIDTH - STAT_KEY, CARD_TEXT, palette()[&"text"] as Color)


## A fraction as a bar in a sunken track, and as the word *low* under a third —
## `DES-018`: the bar's length is the signal, never its colour.
func _draw_bar_row(key: String, fraction: float, x: float, y: float) -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(x, y), key, HORIZONTAL_ALIGNMENT_LEFT, STAT_KEY,
		CARD_TEXT, palette()[&"dim"] as Color)
	var track := Rect2(Vector2(x + STAT_KEY, y - 9.0), Vector2(DOLL_WIDTH - STAT_KEY, 9.0))
	draw_rect(track, palette()[&"cell"] as Color)
	var low: bool = fraction < 0.34
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(fraction, 0.0, 1.0),
		track.size.y)), palette()[&"overload" if low else &"load"] as Color)
	draw_rect(track, palette()[&"line"] as Color, false, 1.0)
	if low:
		CarvedFrame.hatch_into(get_canvas_item(), track,
			palette()[&"cell"] as Color, OVER_PITCH, 1.0)


## **What a thing is worth to her**, as a word and a colour — the only ladder an
## item in this game is on (ADR-342). `DES-008` refuses a rarity ladder: gear is
## sidegrades, and a blue axe that is better than a white one is the treadmill
## `DES-022` exists to prevent. But every item *does* stand somewhere on one
## scale, the one the whole loop turns on — what she would give for it — and
## Diablo's coloured name is the fastest read in the genre. So the name is
## coloured by **tribute**, and the band is written under it as well, because
## `DES-018` will not let a colour carry anything alone.
const WORTH_BANDS: Array[int] = [1, 20, 60, 150]
const WORTH_WORDS: Array[String] = ["nothing to her", "a trifle to her",
	"worth her while", "rich, to her", "a king's gift"]
const WORTH_TONES: Array[StringName] = [&"worth_none", &"worth_trifle",
	&"worth_fair", &"worth_rich", &"worth_kingly"]


static func worth_band(tribute: int) -> int:
	var band: int = 0
	for floor_of: int in WORTH_BANDS:
		if tribute >= floor_of:
			band += 1
	return band


## The line under the name: where it goes or what it is for.
static func kind_of(definition: ItemResource) -> String:
	if definition.slot != Enums.Slot.NONE:
		return "worn · %s%s" % [SLOT_LABEL.get(definition.slot, ""),
			", both hands" if definition.two_handed else ""]
	if definition.tags.has(&"ember"):
		return "an ember — carry it out"
	if definition.tags.has(&"consumable"):
		return "used from the bag"
	if definition.tags.has(&"glitter"):
		return "glitter — hers, if you give it"
	if definition.tags.has(&"relic"):
		return "a relic"
	if definition.tags.has(&"material"):
		return "material"
	return "carried"


func _wrapped_lines(text: String, font: Font) -> int:
	var width: float = CARD_WIDTH - CARD_PAD * 2.0
	var tall: float = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
		width, CARD_TEXT).y
	return int(ceilf(tall / maxf(font.get_height(CARD_TEXT), 1.0) - 0.01))


## The rows of numbers a card ends with.
func _card_rows(item: ItemInstance) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	rows.append(PackedStringArray(["weight", _kilograms(item.weight())]))
	if item.clamor() > 0.0:
		rows.append(PackedStringArray(["heard", "%.1f m further" % (
			item.clamor() * Config.tuning.clamor_metres_per_unit)]))
	var size: Vector2i = item.definition.grid_size
	rows.append(PackedStringArray(["takes", "%d × %d cells" % [size.x, size.y]]))
	if item.tribute_worth() > 0:
		rows.append(PackedStringArray(["tribute", str(item.tribute_worth())]))
	return rows


func _card_height(item: ItemInstance) -> float:
	var font: Font = get_theme_default_font()
	var lines: int = mini(_wrapped_lines(item.definition.describe(), font), CARD_LINES)
	return (CARD_PAD * 2.0 + 24.0 + CARD_LEAD + 10.0
		+ lines * font.get_height(CARD_TEXT) + 10.0
		+ _card_rows(item).size() * CARD_LEAD)


## **The card**, beside the hands and kept on the screen: to the right of the
## cursor, or to the left where the right would run off it.
func _draw_card(item: ItemInstance, at: Vector2) -> void:
	var font: Font = get_theme_default_font()
	var screen: Vector2 = get_viewport_rect().size
	var size := Vector2(CARD_WIDTH, _card_height(item))
	var origin: Vector2 = at + CARD_OFFSET
	if origin.x + size.x > screen.x - 8.0:
		origin.x = at.x - CARD_OFFSET.x - size.x
	origin.y = clampf(origin.y, 8.0, maxf(8.0, screen.y - size.y - 8.0))
	var card := Rect2(origin.round(), size)
	get_theme_stylebox(&"panel", MenuStyle.FRAME).draw(get_canvas_item(), card)
	var left: float = card.position.x + CARD_PAD
	var width: float = card.size.x - CARD_PAD * 2.0
	var y: float = card.position.y + CARD_PAD + 16.0
	var band: int = worth_band(item.tribute_worth())
	draw_string(get_theme_font(&"font", MenuStyle.DISPLAY_WARM), Vector2(left, y),
		item.definition.display(), HORIZONTAL_ALIGNMENT_LEFT, width, CARD_NAME_TEXT,
		palette()[WORTH_TONES[band]] as Color)
	y += CARD_LEAD
	draw_string(font, Vector2(left, y), "%s · %s" % [WORTH_WORDS[band],
		kind_of(item.definition)], HORIZONTAL_ALIGNMENT_LEFT, width, CARD_TEXT,
		palette()[&"dim"] as Color)
	y += 10.0
	draw_rect(Rect2(left, y - 4.0, width, 1.0), Color(palette()[&"line"] as Color, 0.8))
	y += font.get_ascent(CARD_TEXT)
	draw_multiline_string(font, Vector2(left, y), item.definition.describe(),
		HORIZONTAL_ALIGNMENT_LEFT, width, CARD_TEXT, CARD_LINES, palette()[&"text"] as Color)
	y += mini(_wrapped_lines(item.definition.describe(), font), CARD_LINES) \
		* font.get_height(CARD_TEXT) - font.get_ascent(CARD_TEXT) + 10.0
	draw_rect(Rect2(left, y - 4.0, width, 1.0), Color(palette()[&"line"] as Color, 0.8))
	y += 12.0
	for row: PackedStringArray in _card_rows(item):
		draw_string(font, Vector2(left, y), row[0], HORIZONTAL_ALIGNMENT_LEFT,
			STAT_KEY, CARD_TEXT, palette()[&"dim"] as Color)
		draw_string(font, Vector2(left + STAT_KEY, y), row[1], HORIZONTAL_ALIGNMENT_LEFT,
			width - STAT_KEY, CARD_TEXT, palette()[&"text"] as Color)
		y += CARD_LEAD


## The three numbers the decision is actually made on.
func _draw_header(column: Rect2) -> void:
	var font: Font = get_theme_default_font()
	# **The body's load, not the bag's** (ADR-224): what is worn weighs, and the
	# class sets the capacity. The bag's own sum showed a Húskarl in a byrnie
	# 0.2 kg against 40 while their legs carried 13.5 against 52.
	var kilograms: float = _player.carried.kilograms
	var capacity: float = _player.carried.capacity()
	var at: Vector2 = column.position + Vector2(0.0, 14.0)

	# The bag's name in the display type (ADR-289), as every screen's title is.
	draw_string(get_theme_font(&"font", MenuStyle.DISPLAY_WARM), at + Vector2(0.0, 2.0),
		"Bag", HORIZONTAL_ALIGNMENT_LEFT, -1, HEADER_TEXT + 4,
		palette()[&"dim"] as Color)
	# Through `_header_summary` so the string the panel was *sized* against and
	# the string actually drawn cannot drift apart, and clipped to the room it
	# was sized for — belt and braces, because the panel now guarantees the fit
	# and a silent clip would hide it if that ever stopped being true.
	var summary: String = _header_summary(kilograms, _inventory.cells_used(),
		_carried_radius())
	draw_string(font, at + Vector2(HEADER_INSET, 0.0), summary,
		HORIZONTAL_ALIGNMENT_LEFT, column.size.x - HEADER_INSET,
		HEADER_TEXT, palette()[&"text"] as Color)

	# The load bar. Encumbrance is what the legs feel, so it is drawn as a
	# proportion rather than left as a figure to be read — `DES-019` wants
	# shapes for feel and digits only for arithmetic, and both are here doing
	# their own job.
	var track := Rect2(at + Vector2(0.0, 12.0), Vector2(column.size.x, 8.0))
	draw_rect(track, palette()[&"cell"] as Color)
	draw_rect(track, palette()[&"line"] as Color, false, 1.0)
	var fraction: float = clampf(kilograms / maxf(capacity, 0.001), 0.0, 1.0)
	var filled := Rect2(track.position, Vector2(track.size.x * fraction, track.size.y))
	var over: bool = kilograms >= capacity
	draw_rect(filled, palette()[&"overload" if over else &"load"] as Color)
	# **Over capacity is hatched, because the bar has nowhere left to go**
	# (`DES-018`, `M4-T05`). The fill is clamped at 1.0, so at 39.9 kg and at
	# 60 kg against a 40 kg capacity the shape is identical and *only the hue*
	# differed — which is the one thing `DES-018` will not let a signal rest on.
	# Strokes over the whole trough say *past full* in a mark rather than in a
	# colour, and they say it at any colour vision and in a photograph.
	if over:
		CarvedFrame.hatch_into(get_canvas_item(), track,
			palette()[&"cell"] as Color, OVER_PITCH, 1.0)


func _draw_cells() -> void:
	var grid: Vector2i = _inventory.grid()
	# An empty cell is a socket cut into the slate, tick-marked at the corners —
	# a grid of them reads as a thing built to hold things, where a grid of
	# outlined rectangles reads as a spreadsheet.
	var socket: StyleBox = get_theme_stylebox(&"panel", MenuStyle.SOCKET)
	var into: RID = get_canvas_item()
	for y: int in range(grid.y):
		for x: int in range(grid.x):
			socket.draw(into, _cell_rect(Vector2i(x, y), Vector2i.ONE))


func _draw_item(item: ItemInstance, rect: Rect2, alpha: float) -> void:
	var font: Font = get_theme_default_font()
	var seat: int = -1
	if item.is_ember():
		seat = Player.slot_for_peer(self, item.bound_to)
	# The bag used coloured rectangles as an M2 blockout.  The art pass replaces
	# those category colours with authored silhouettes: bone and black ink for
	# equipment and supplies, gold only for glitter and the ember.  The border
	# stays quiet so the icon, not a colour patch, is what a hand recognises.
	var cell: Color = palette()[&"cell"] as Color
	var line: Color = palette()[&"line"] as Color
	if alpha >= 1.0:
		# **A thing in the bag is a plate on the slate** (ADR-343): raised
		# iron in a sunken socket, the aspect chip's forged plate, so what you
		# carry stands off the holes it sits in rather than being one more
		# outlined rectangle among thirty.
		get_theme_stylebox(&"normal", MenuStyle.ASPECT_CHIP).draw(get_canvas_item(), rect)
	else:
		draw_rect(rect, Color(cell, cell.a * alpha))
		draw_rect(rect, Color(line, line.a * alpha), false, 2.0)
	var one_row: bool = item.footprint().y == 1
	var icon_top: float = 5.0 if one_row else 20.0
	var icon_bottom: float = 16.0
	_draw_icon(item.definition.icon,
		Rect2(rect.position + Vector2(5.0, icon_top),
			rect.size - Vector2(10.0, icon_top + icon_bottom)), alpha)
	# **Wearable things carry their slot's mark** (`M4-T20`). Which of these is
	# gear and which is loot was carried by nothing but the name, and the name
	# truncates in a one-cell footprint — so *"can I wear this"* was a question
	# you answered by dragging it at the slots and seeing which lit up.
	#
	# Bottom-right, small, and only where there is room for it: a 1×1 cell is
	# already carrying a clipped name and a weight, and a third thing in it
	# would be the ADR-140 fault committed on purpose.
	if item.definition.slot != Enums.Slot.NONE \
			and item.footprint().x >= 2 and item.footprint().y >= 2:
		var badge := Rect2(rect.end - Vector2(26.0, 26.0), Vector2(20.0, 20.0))
		_slot_mark(badge, item.definition.slot,
			Color(palette()[&"mark"] as Color, 0.7 * alpha))
	# A one-row footprint spends its scarce height on a recognisable silhouette
	# and its weight.  Hover still gives its complete name and description below;
	# taller things keep their label above the icon.
	var text_colour := Color(palette()[&"text"] as Color, alpha)
	if not one_row:
		draw_string(font, rect.position + Vector2(5.0, 16.0), item.label(seat),
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, CELL_TEXT, text_colour)
	# **The unit is dropped in a one-cell footprint** (ADR-140). `0.04 kg` is
	# 40 px of text in 36 px of cell and rendered as `0.04 k`, which reads as a
	# rendering bug rather than as a weight. Every number in this panel is
	# kilograms and the header says so two inches above, so the digits are the
	# part worth keeping — clip-free beats a unit nobody was in doubt about.
	var weight: String = _kilograms(item.weight())
	if item.footprint().x <= 1:
		weight = weight.replace(" kg", "")
	draw_string(font, rect.position + Vector2(5.0, rect.size.y - 6.0),
		weight, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0,
		CELL_TEXT, Color(palette()[&"dim"] as Color, alpha))


## Fit the SVG's own proportions inside the space left by the item's text and
## weight.  The resource validator makes a missing icon a content error, so a
## generic rectangle here would be a deceptive fallback rather than resilience.
func _draw_icon(icon: Texture2D, available: Rect2, alpha: float) -> void:
	var source: Vector2 = icon.get_size()
	var scale: float = minf(available.size.x / source.x, available.size.y / source.y)
	var drawn: Vector2 = source * scale
	var destination := Rect2(available.get_center() - drawn * 0.5, drawn)
	draw_texture_rect(icon, destination, false, Color(1.0, 1.0, 1.0, alpha))


## The item in hand, plus a ghost of where it would land and whether it can.
## Answering "does this fit" *before* the release is what makes packing a
## puzzle rather than a guess.
func _draw_held() -> void:
	var footprint: Vector2i = _held_footprint()
	var target: Vector2i = _cursor_cell() - _grab
	if _within_grid(_cursor):
		var legal: bool = _inventory.fits(footprint, target, _held)
		var ghost: Color = palette()[&"legal" if legal else &"illegal"] as Color
		draw_rect(_cell_rect(target, footprint), ghost)
		# **And a refusal is hatched, not merely red** (`DES-018`). A ghost that
		# says *this does not fit* in hue alone says nothing to a third of a
		# colour-blind audience, and this is the one readout in the bag a player
		# acts on within the same second they read it.
		if not legal:
			CarvedFrame.hatch_into(get_canvas_item(),
				_cell_rect(target, footprint), Color(ghost, 0.9),
				OVER_PITCH * 2.0, 1.0)
	var floating := Rect2(_cursor - Vector2(footprint) * (CELL + GAP) * 0.5,
		Vector2(footprint) * (CELL + GAP) - Vector2(GAP, GAP))
	_draw_item(_held, floating, 0.85)


## Every prompt names both devices (`DES-019` rule 7, ADR-075). This is a rule
## about authoring, not about the final look — `M4-T05` swaps in the active
## device's glyph, and writing both now is what makes that a rendering change
## rather than a redesign.
##
## Two lines, not one. The first version was a single row that `draw_string`
## silently clipped at the panel edge, so the last two prompts — including how
## to drop something, which is the verb the whole milestone is about — were
## invisible. A prompt that names both devices and then gets cut off names
## neither.
func _draw_footer(panel: Rect2) -> void:
	var font: Font = get_theme_default_font()
	var width: float = panel.size.x - PADDING * 2.0
	var left: float = panel.position.x + PADDING
	var base: float = panel.position.y + panel.size.y - PADDING - FOOTER + FOOTER_BASE + 12.0
	var prompts: Array[String] = footer_lines()
	var faint: Color = palette()[&"dim"] as Color
	draw_string(font, Vector2(left, base), prompts[0],
		HORIZONTAL_ALIGNMENT_LEFT, width, FOOTER_TEXT, faint)
	draw_string(font, Vector2(left, base + FOOTER_LEAD), prompts[1],
		HORIZONTAL_ALIGNMENT_LEFT, width, FOOTER_TEXT, faint)


## An item light enough to read as *free* has to say so without looking like a
## bug. `DES-008`'s raw gemstone is "high tribute, no weight" and weighs 0.04 kg
## — at one decimal that renders as `0.0 kg`, which reads as unset rather than
## as weightless.
static func _kilograms(value: float) -> String:
	return "%.2f kg" % value if value < 0.1 else "%.1f kg" % value


## Metres you can be heard from standing perfectly still, carrying this.
## `ClamorSource` decays to this rather than to zero, so it is the number that
## answers *"can I hide with all this on me?"* — which is the question
## `DES-005`'s counter-play list is built around.
##
## The body's standing floor rather than the bag's sum (ADR-224): it counts what
## is worn, and it is the number `ClamorSource` actually decays to, so Ballast
## and Faint Trace are in it as well — the bag's sum ignored both.
func _carried_radius() -> float:
	return _player.clamor.carried_floor * Config.tuning.clamor_metres_per_unit
