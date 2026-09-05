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
## ## Blockout, and honestly so
##
## Coloured rectangles with names on them (ADR-046 — a named production phase
## with scheduled replacement, not a stub). Every function is complete: you can
## see everything you carry, move it, turn it, and put it down. What is absent
## is art, and `M4-T05` is where it arrives with the rest of the HUD. The
## colours come from `WorldItem.colour_for` rather than a second palette, so a
## thing is the same colour in your bag as it was on the floor.
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

## **The six slots** (`M3-T07`, `DES-020`), drawn as a row beneath the grid.
##
## In the bag rather than on a screen of its own, because `DES-019` is hostile
## to persistent UI and the decision *"is this worth carrying or worth
## wearing"* is one question — putting it in two places would make it two.
const SLOT_ROW: Array[Enums.Slot] = [
	Enums.Slot.MAIN_HAND, Enums.Slot.OFF_HAND, Enums.Slot.ARMS,
	Enums.Slot.HEAD, Enums.Slot.BODY, Enums.Slot.PACK,
]
const SLOT_LABEL: Dictionary = {
	Enums.Slot.MAIN_HAND: "hand", Enums.Slot.OFF_HAND: "off",
	Enums.Slot.ARMS: "arms", Enums.Slot.HEAD: "head",
	Enums.Slot.BODY: "body", Enums.Slot.PACK: "pack",
}
const SLOT_SIZE: float = 52.0
const SLOT_BAND: float = 78.0

const CELL: float = 44.0
const GAP: float = 3.0
const PADDING: float = 18.0
const HEADER: float = 64.0
const FOOTER: float = 30.0
## The band between the grid and the prompts, holding whatever the cursor is
## over (`M2-T19`, ADR-112). A **name** line and up to **two** wrapped lines of
## description, which is three, not two.
##
## It was 34 px and needs 58 by the font's own metrics (ADR-140). The third line landed inside
## the footer and drew *"make one and regret continuously."* straight through
## *"lmb/X take & place"* — reported from play as text on top of other text.
##
## Nothing could have seen it. `overflowing()` measured the width of the header
## and the footer and never looked at this band at all, and every bag
## screenshot ever taken had **nothing under the cursor**, so the one region
## that draws variable-height text had never appeared in a photograph.
const BLURB: float = 60.0
const BLURB_TEXT: int = 12
## The header line sits to the right of the word BAG; this is that gap.
const HEADER_INSET: float = 46.0
const HEADER_TEXT: int = 16
const FOOTER_TEXT: int = 12
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
		"drag out or %s drop    %s close" % [
			ControlsScreen.glyphs_for("drop"),
			ControlsScreen.glyphs_for("bag")],
	]

## Screen pixels per second the gamepad cursor travels at full deflection.
const CURSOR_RATE: float = 620.0

const PANEL_COLOUR: Color = Color(0.09, 0.085, 0.08, 0.93)
const CELL_COLOUR: Color = Color(0.20, 0.19, 0.18, 1.0)
const GRID_LINE: Color = Color(0.31, 0.30, 0.28, 1.0)
const TEXT_COLOUR: Color = Color(0.86, 0.84, 0.80, 1.0)
const DIM_TEXT: Color = Color(0.56, 0.54, 0.51, 1.0)
const LEGAL_GHOST: Color = Color(0.55, 0.78, 0.52, 0.45)
const ILLEGAL_GHOST: Color = Color(0.82, 0.35, 0.30, 0.45)
## `DES-019` rule 2 again: over capacity is a *shape and colour* change, not a
## red number. The bar is the readout; the digits beside it are the arithmetic.
const LOAD_COLOUR: Color = Color(0.72, 0.68, 0.44, 1.0)
const OVERLOAD_COLOUR: Color = Color(0.82, 0.35, 0.30, 1.0)

var _player: Player = null
var _inventory: Inventory = null

## Where the hands are, in screen pixels. Mouse motion assigns it; the right
## stick integrates into it. Whichever moved last wins, which is the whole
## device-switching rule and needs no mode flag to track.
var _cursor: Vector2 = Vector2.ZERO
var _held: ItemInstance = null
var _held_rotated: bool = false
## Cursor cell minus the held item's origin cell, so a dragged item does not
## snap its corner to the pointer the instant you grab it.
var _grab: Vector2i = Vector2i.ZERO


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


func hovered() -> ItemInstance:
	if _held != null:
		return _held
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
		_turn()
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
	var size := Vector2(maxf(inner.x, _header_width()) + PADDING * 2.0,
		inner.y + PADDING * 2.0 + HEADER + BLURB + FOOTER + SLOT_BAND)
	var screen: Vector2 = get_viewport_rect().size
	return Rect2(((screen - size) * 0.5).round(), size)


## How wide the header needs, measured against the **widest** numbers it can
## ever hold rather than the ones on screen now. Sizing to the live string would
## make the whole panel breathe by a few pixels every time a coin went in.
func _header_width() -> float:
	var grid: Vector2i = _inventory.grid()
	var cells: int = grid.x * grid.y
	var widest: String = _header_summary(
		Config.tuning.carry_capacity, cells, WIDEST_RADIUS)
	return HEADER_INSET + ThemeDB.fallback_font.get_string_size(
		widest, HORIZONTAL_ALIGNMENT_LEFT, -1, HEADER_TEXT).x


## One place the header line is built, so the width it is measured at and the
## width it is drawn at cannot drift apart.
func _header_summary(kilograms: float, used: int, radius: float) -> String:
	var grid: Vector2i = _inventory.grid()
	return "%.1f / %.0f kg     %d / %d cells     heard from %.1f m" % [
		kilograms, Config.tuning.carry_capacity, used, grid.x * grid.y, radius]


## Every line this screen draws that does not fit the box it is drawn in.
## Empty when the layout is honest; read by `--bagui-probe`.
func overflowing() -> PackedStringArray:
	var font: Font = ThemeDB.fallback_font
	var panel: Rect2 = _panel_rect()
	var spilled := PackedStringArray()
	var header: String = _header_summary(_inventory.total_weight(),
		_inventory.cells_used(), _carried_radius())
	var room: float = panel.size.x - PADDING * 2.0 - HEADER_INSET
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

	# **And whether the bands collide, which is a different question** (ADR-140).
	#
	# Everything above asks *does this line fit its width*. Nothing asked *does
	# this block fit its height*, and the blurb is the one region whose height
	# is not fixed: a name line plus up to two wrapped description lines. At
	# `BLURB = 34` the third landed inside the footer and drew text through
	# text, with every width row green.
	#
	# Measured against the font rather than against a remembered number, so
	# raising `BLURB_TEXT` or allowing a third description line fails here
	# instead of on somebody's screen.
	var line_height: float = font.get_height(BLURB_TEXT)
	var needed: float = 11.0 + 13.0 + line_height * 2.0
	if needed > BLURB:
		spilled.append(("the blurb needs %.0f px and has %.0f — a name line and "
			+ "two wrapped lines, and the overflow lands in the prompts")
			% [needed, BLURB])

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
			weight, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		if drawn_at > cell_room:
			spilled.append("%s's weight is %.0f px in %.0f px: %s" % [
				item.definition.id, drawn_at, cell_room, weight])
	return spilled


## Where a slot sits. Below the grid, spread across the panel, so the row reads
## as *what is on you* under *what you are carrying* — which is the order the
## question is asked in.
func _slot_rect(slot: Enums.Slot) -> Rect2:
	var panel: Rect2 = _panel_rect()
	var index: int = SLOT_ROW.find(slot)
	var span: float = SLOT_SIZE * SLOT_ROW.size() + GAP * (SLOT_ROW.size() - 1)
	var left: float = panel.position.x + (panel.size.x - span) * 0.5
	var top: float = _grid_origin().y + _grid_pixels().y + PADDING
	return Rect2(Vector2(left + index * (SLOT_SIZE + GAP), top),
		Vector2(SLOT_SIZE, SLOT_SIZE))


## The slot under a point, or `NONE`.
func _slot_at(point: Vector2) -> Enums.Slot:
	for slot: Enums.Slot in SLOT_ROW:
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


func _draw_slots() -> void:
	var worn: Equipment = _player.equipment
	for slot: Enums.Slot in SLOT_ROW:
		var box: Rect2 = _slot_rect(slot)
		var item: ItemInstance = worn.in_slot(slot) if worn != null else null
		# A slot the held item could go into lights up while you are dragging,
		# so the answer to "where does this go" is visible before you let go
		# rather than discovered by trying.
		var wanted: bool = (_held != null
			and _held.definition.slot == slot)
		draw_rect(box, PANEL_COLOUR)
		draw_rect(box, MenuStyle.WARM if wanted else GRID_LINE, false, 2.0)
		if item != null:
			draw_rect(box.grow(-6.0), WorldItem.colour_for(item.definition))
			# The mark stays over a worn item, dark against it. The slot keeps
			# saying what it is even when it is full, so the row still scans as
			# a body rather than as six coloured squares.
			_slot_mark(box, slot, Color(0.10, 0.09, 0.08, 0.75))
		else:
			# Brighter while it is the slot you are dragging toward — the same
			# signal the border gives, said twice, because `DES-018` will not
			# let the border's colour carry it alone.
			_slot_mark(box, slot,
				MenuStyle.WARM if wanted else Color(MenuStyle.DIM, 0.55))
		var font: Font = ThemeDB.fallback_font
		draw_string(font, box.position + Vector2(4.0, box.size.y + 12.0),
			String(SLOT_LABEL[slot]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			MenuStyle.DIM)


func _grid_origin() -> Vector2:
	var panel: Rect2 = _panel_rect()
	var inner: Vector2 = _grid_pixels()
	# Centred, because the panel is now allowed to be wider than the grid.
	return panel.position + Vector2((panel.size.x - inner.x) * 0.5,
		PADDING + HEADER)


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
		Color(0.04, 0.04, 0.05, 0.45))
	draw_rect(panel, PANEL_COLOUR)
	draw_rect(panel, GRID_LINE, false, 2.0)
	_draw_header(panel)
	_draw_slots()
	_draw_cells()
	for item: ItemInstance in _inventory.items():
		if item != _held:
			_draw_item(item, _cell_rect(item.cell, item.footprint()), 1.0)
	if _held != null:
		_draw_held()
	_draw_blurb(panel)
	_draw_footer(panel)


## **What the thing under your cursor actually is** (`M2-T19`, ADR-112).
##
## Every item in the game carries a `description_key`, every one of them is
## authored, and `data_probe` has validated all of them since `M2-T08` — and
## nothing had ever *drawn* one. So the Waystone said `Grey, unremarkable, and
## the only thing down here that is worth more than what you came for. Spending
## it ends the run with whatever is in your hands.` to nobody, and a playtester
## carrying one reported there was no way out of the level except the Shaft.
##
## Here rather than on the reticle, because `DES-019` bans text in the middle of
## the screen and names this one exception: *"the inventory screen, where you
## are deliberately doing arithmetic."* Wrapped rather than clipped, for the
## reason the footer already gives about being cut off.
func _draw_blurb(panel: Rect2) -> void:
	var item: ItemInstance = hovered()
	if item == null or item.definition == null:
		return
	var font: Font = ThemeDB.fallback_font
	var width: float = panel.size.x - PADDING * 2.0
	var top: float = panel.position.y + panel.size.y - FOOTER - BLURB + 11.0
	draw_string(font, Vector2(panel.position.x + PADDING, top),
		item.definition.display(), HORIZONTAL_ALIGNMENT_LEFT, width,
		BLURB_TEXT, TEXT_COLOUR)
	draw_multiline_string(font,
		Vector2(panel.position.x + PADDING, top + 13.0),
		item.definition.describe(), HORIZONTAL_ALIGNMENT_LEFT, width,
		BLURB_TEXT, 2, DIM_TEXT)


## The three numbers the decision is actually made on.
func _draw_header(panel: Rect2) -> void:
	var font: Font = ThemeDB.fallback_font
	var tuning: TuningProfile = Config.tuning
	var kilograms: float = _inventory.total_weight()
	var capacity: float = tuning.carry_capacity
	var grid: Vector2i = _inventory.grid()
	var at: Vector2 = panel.position + Vector2(PADDING, PADDING + 14.0)

	draw_string(font, at, "BAG", HORIZONTAL_ALIGNMENT_LEFT, -1, HEADER_TEXT,
		DIM_TEXT)
	# Through `_header_summary` so the string the panel was *sized* against and
	# the string actually drawn cannot drift apart, and clipped to the room it
	# was sized for — belt and braces, because the panel now guarantees the fit
	# and a silent clip would hide it if that ever stopped being true.
	var summary: String = _header_summary(kilograms, _inventory.cells_used(),
		_carried_radius())
	draw_string(font, at + Vector2(HEADER_INSET, 0.0), summary,
		HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - PADDING * 2.0 - HEADER_INSET,
		HEADER_TEXT, TEXT_COLOUR)

	# The load bar. Encumbrance is what the legs feel, so it is drawn as a
	# proportion rather than left as a figure to be read — `DES-019` wants
	# shapes for feel and digits only for arithmetic, and both are here doing
	# their own job.
	var track := Rect2(at + Vector2(0.0, 12.0), Vector2(panel.size.x - PADDING * 2.0, 8.0))
	draw_rect(track, CELL_COLOUR)
	var fraction: float = clampf(kilograms / maxf(capacity, 0.001), 0.0, 1.0)
	var filled := Rect2(track.position, Vector2(track.size.x * fraction, track.size.y))
	var over: bool = kilograms >= capacity
	draw_rect(filled, OVERLOAD_COLOUR if over else LOAD_COLOUR)


func _draw_cells() -> void:
	var grid: Vector2i = _inventory.grid()
	for y: int in range(grid.y):
		for x: int in range(grid.x):
			var rect: Rect2 = _cell_rect(Vector2i(x, y), Vector2i.ONE)
			draw_rect(rect, CELL_COLOUR)
			draw_rect(rect, GRID_LINE, false, 1.0)


func _draw_item(item: ItemInstance, rect: Rect2, alpha: float) -> void:
	var font: Font = ThemeDB.fallback_font
	var colour: Color = WorldItem.colour_for(item.definition)
	# Every ember is the same colour on the floor and the same colour here
	# (ADR-094) — it is a piece of *her* fire, not a team marker. Whose it is
	# lives in the **label**, which is where a rescuer with two of them can
	# read it without anything having to be encoded in hue.
	var seat: int = -1
	if item.is_ember():
		seat = Player.slot_for_peer(self, item.bound_to)
	colour.a = alpha
	draw_rect(rect, colour * Color(0.55, 0.55, 0.55, 1.0))
	draw_rect(rect, colour, false, 2.0)
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
			Color(0.10, 0.09, 0.08, 0.7 * alpha))
	# Name and weight, clipped to the footprint. A one-cell gemstone gets a
	# truncated name and its weight; a three-by-three plate gets both in full.
	var text_colour := Color(TEXT_COLOUR, alpha)
	draw_string(font, rect.position + Vector2(5.0, 16.0), item.label(seat),
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, 13, text_colour)
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
		12, Color(DIM_TEXT, alpha))


## The item in hand, plus a ghost of where it would land and whether it can.
## Answering "does this fit" *before* the release is what makes packing a
## puzzle rather than a guess.
func _draw_held() -> void:
	var footprint: Vector2i = _held_footprint()
	var target: Vector2i = _cursor_cell() - _grab
	if _within_grid(_cursor):
		var legal: bool = _inventory.fits(footprint, target, _held)
		draw_rect(_cell_rect(target, footprint),
			LEGAL_GHOST if legal else ILLEGAL_GHOST)
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
	var font: Font = ThemeDB.fallback_font
	var width: float = panel.size.x - PADDING * 2.0
	var left: float = panel.position.x + PADDING
	var base: float = panel.position.y + panel.size.y - FOOTER + 12.0
	var prompts: Array[String] = footer_lines()
	draw_string(font, Vector2(left, base), prompts[0],
		HORIZONTAL_ALIGNMENT_LEFT, width, FOOTER_TEXT, DIM_TEXT)
	draw_string(font, Vector2(left, base + 13.0), prompts[1],
		HORIZONTAL_ALIGNMENT_LEFT, width, FOOTER_TEXT, DIM_TEXT)


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
func _carried_radius() -> float:
	var tuning: TuningProfile = Config.tuning
	return (_inventory.total_clamor() * tuning.clamor_carried_fraction
		* tuning.clamor_metres_per_unit)
