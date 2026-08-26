class_name ControlsScreen
extends Control

## What the buttons do, said once, where a first-time player can find it.
##
## **This exists because a gate depends on it.** `GATE M3 EXIT`'s protocol is
## *"no coaching beyond the in-game control list"* — and there was no in-game
## control list. The main menu had five buttons, the pause menu four, `SETTINGS`
## had volumes and a sensitivity slider, and `ArrivalBrief` named no verb at
## all. `project.godot` defines twenty-three actions and a tester was told about
## none of them, which does not merely fail the *"discovers they can drop loot"*
## clause — it contaminates every other clause with it, because a tester who
## never found crouch cannot answer a question about noise.
##
## ## Generated from `InputMap`, never typed twice
##
## The bindings are read out of `InputMap` at build time, so this screen cannot
## disagree with `project.godot`. That is the whole design: what drifts (keys)
## is generated, and what does not (the English name of a verb) is authored.
## `tools/bind_gamepad.py` rewrites the pad half of `project.godot` on demand
## and a hand-written list would be stale the first time it ran.
##
## `--controls-probe` closes the loop in **both directions**: every action that
## is neither `ui_*` nor deliberately hidden must appear in a row, and every
## action a row names must exist in `InputMap`. Adding an action without
## teaching it is then a failed build rather than a thing a playtester finds.
##
## ## Not rebinding
##
## `M4-T06` owns rebinding. This is the display half, pulled forward under
## ADR-137 because a gate needs it and rebinding does not. It is deliberately
## read-only: a row you cannot click is honest, and a greyed row promising a
## rebind you have not built is the stub `ADR-064` bans.
##
## Both devices on every row, per `DES-019` rule 7.

signal closed()

## Actions kept off this screen, and why. A tester is not told about the debug
## keys because they are not part of the game — and `GATE M3 EXIT` requires the
## diagnostic overlay off, so advertising its toggle would be working against
## the session. Named rather than pattern-matched, so that adding a fourth debug
## action is a decision somebody makes rather than one a prefix makes for them.
const HIDDEN: Array[String] = ["debug_reset", "debug_overlays", "debug_ink"]

## The rows, in the order a person needs them: how to move, how to fight, how
## to carry, how to leave. One row may cover several actions — `move_forward`
## and its three siblings are one idea to a player and four to `InputMap` — and
## the glyphs of everything it covers are joined and de-duplicated, so "Move"
## reads `W A S D` on a keyboard and `Left Stick` on a pad without either being
## written down anywhere.
const GROUPS: Array = [
	["MOVING", [
		["Move", ["move_forward", "move_left", "move_back", "move_right"]],
		["Look around", ["look_up", "look_left", "look_down", "look_right"]],
		["Run", ["sprint"]],
		["Crouch — hold", ["crouch"]],
		["Crouch — stay down", ["crouch_toggle"]],
		["Jump", ["jump"]],
	]],
	["FIGHTING", [
		["Swing", ["attack"]],
		["Guard", ["block"]],
		["Your class verb", ["verb"]],
	]],
	["CARRYING", [
		["Open the bag", ["bag"]],
		["Pick up, and place in the bag", ["interact"]],
		["Drop what is in your hand", ["drop"]],
		["Turn an item in the bag", ["rotate_item"]],
		["Throw — bait the Hunter", ["throw"]],
	]],
	["LEAVING", [
		["Spend a Waystone", ["use_waystone"]],
	]],
]

## Xbox names, because they are the ones printed on the majority of pads sold
## and a player on a different pad reads position rather than letter. Godot's
## `JoyButton` has no string form of its own.
const PAD_BUTTON: Dictionary = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left", JOY_BUTTON_DPAD_RIGHT: "D-pad Right",
}

const PAD_AXIS: Dictionary = {
	JOY_AXIS_LEFT_X: "Left Stick", JOY_AXIS_LEFT_Y: "Left Stick",
	JOY_AXIS_RIGHT_X: "Right Stick", JOY_AXIS_RIGHT_Y: "Right Stick",
	JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuStyle.backdrop())

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var column: VBoxContainer = MenuStyle.column(8)
	centre.add_child(column)
	column.add_child(MenuStyle.title("CONTROLS", 34))

	var table := GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 26)
	table.add_theme_constant_override("v_separation", 4)
	column.add_child(table)

	for group: Array in GROUPS:
		_heading(table, String(group[0]))
		for row: Array in (group[1] as Array):
			_row(table, String(row[0]), PackedStringArray(row[1] as Array))

	column.add_child(_gap(14))
	var back: Button = MenuStyle.button("BACK")
	back.pressed.connect(func() -> void: closed.emit())
	column.add_child(back)
	back.grab_focus()


func _heading(table: GridContainer, text: String) -> void:
	# A heading spans the table by being a row of its own with two blanks after
	# it. `GridContainer` has no column span, and three cells is cheaper than
	# the nested containers the alternative needs.
	table.add_child(_gap(8))
	table.add_child(_gap(8))
	table.add_child(_gap(8))
	var label: Label = MenuStyle.line(text, 13, MenuStyle.WARM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size = Vector2(240.0, 0.0)
	table.add_child(label)
	table.add_child(_blank())
	table.add_child(_blank())


func _row(table: GridContainer, text: String, actions: PackedStringArray) -> void:
	var name_cell: Label = MenuStyle.line(text, 15, MenuStyle.TEXT)
	name_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_cell.custom_minimum_size = Vector2(240.0, 0.0)
	table.add_child(name_cell)
	table.add_child(_glyph_cell(keyboard_glyphs(actions)))
	table.add_child(_glyph_cell(pad_glyphs(actions)))


func _glyph_cell(glyphs: PackedStringArray) -> Label:
	# An empty cell would be a lie of omission — it reads as "this verb has no
	# binding on this device", which is a different and much worse statement
	# than "nothing is bound here yet". ADR-075 makes both devices reach
	# everything, so if this ever renders the dash, that is the bug.
	var text: String = "  ".join(glyphs) if not glyphs.is_empty() else "—"
	var cell: Label = MenuStyle.line(text, 15,
		MenuStyle.TEXT if not glyphs.is_empty() else MenuStyle.DIM)
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cell.custom_minimum_size = Vector2(160.0, 0.0)
	return cell


## Keyboard and mouse glyphs for everything these actions are bound to, in
## `InputMap` order, each appearing once. Static so `--controls-probe` can ask
## the same question without building a screen.
static func keyboard_glyphs(actions: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for action: String in actions:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			var text: String = _keyboard_text(event)
			if not text.is_empty() and not out.has(text):
				out.append(text)
	return out


static func pad_glyphs(actions: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for action: String in actions:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			var text: String = _pad_text(event)
			if not text.is_empty() and not out.has(text):
				out.append(text)
	return out


static func _keyboard_text(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		# **Physical, not logical** (`TEC-002`, and `project.godot` binds the
		# physical half). `W` is the key above `S` on every layout; the letter
		# printed on it is not, and a player on AZERTY reads position.
		return key.as_text_physical_keycode() if key.physical_keycode != 0 \
			else key.as_text_keycode()
	var mouse := event as InputEventMouseButton
	if mouse == null:
		return ""
	match mouse.button_index:
		MOUSE_BUTTON_LEFT: return "Left Mouse"
		MOUSE_BUTTON_RIGHT: return "Right Mouse"
		MOUSE_BUTTON_MIDDLE: return "Middle Mouse"
	return "Mouse %d" % mouse.button_index


static func _pad_text(event: InputEvent) -> String:
	var pressed := event as InputEventJoypadButton
	if pressed != null:
		return String(PAD_BUTTON.get(pressed.button_index, "Pad %d"
			% pressed.button_index))
	var moved := event as InputEventJoypadMotion
	if moved == null:
		return ""
	return String(PAD_AXIS.get(moved.axis, "Axis %d" % moved.axis))


## Every action this screen teaches. The probe compares it against `InputMap`
## in both directions, which is what stops the screen and the bindings drifting
## apart — the failure `M3-T06` and ADR-098 both landed on, in a place a
## playtester rather than a probe would have paid for it.
static func covered() -> PackedStringArray:
	var out := PackedStringArray()
	for group: Array in GROUPS:
		for row: Array in (group[1] as Array):
			for action: String in PackedStringArray(row[1] as Array):
				if not out.has(action):
					out.append(action)
	return out


func _gap(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, float(height))
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _blank() -> Control:
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer
