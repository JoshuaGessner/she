class_name ControlsScreen
extends Control

## What the buttons do, said once, where a first-time player can find it.
##
## **This exists because a gate depends on it.** `GATE M3 EXIT`'s protocol is
## *"no coaching beyond the in-game control list"* — and there was no in-game
## control list. The main menu had five buttons, the pause menu four, `SETTINGS`
## had volumes and a sensitivity slider, and `ArrivalBrief` named no verb at
## all. `project.godot` defines twenty-four actions and a tester was told about
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
## `--menu-probe` closes the loop in **both directions**: every action that
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

## The laid-out column, kept so `--menu-probe` can ask whether it fits. The
## screen's row count comes from `InputMap`, so it is the one menu in the game
## that can outgrow the viewport without anybody editing it.
var _body: VBoxContainer

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
## Each row is `[full label, short label, [actions]]`. The short label exists
## because the same rows are rendered as **running text** in the Threshold's
## readout, where "Pick up, and place in the bag" is a paragraph and "take" is
## a prompt. One table, two renderings — rather than the four separate lists
## this replaced (ADR-139), of which two were already stale and none named the
## class verb.
const GROUPS: Array = [
	["MOVING", [
		["Move", "move", ["move_forward", "move_left", "move_back", "move_right"]],
		# **The mouse cannot be generated.** Looking around with it is raw motion,
		# not an `InputMap` action, so no amount of reading the bindings will
		# ever mention it — and the hand-written list this replaced did say
		# *mouse look*. The authored half of the row carries what the generated
		# half structurally cannot (ADR-139).
		["Look around — or just move the mouse", "look",
			["look_up", "look_left", "look_down", "look_right"]],
		["Run", "run", ["sprint"]],
		["Crouch — hold", "crouch", ["crouch"]],
		["Crouch — stay down", "stay down", ["crouch_toggle"]],
		["Jump", "jump", ["jump"]],
	]],
	["FIGHTING", [
		["Swing", "attack", ["attack"]],
		["Guard", "guard", ["block"]],
		["Your class verb", "your verb", ["verb"]],
	]],
	["CARRYING", [
		["Open the bag", "bag", ["bag"]],
		["Pick up, and place in the bag", "take", ["interact"]],
		["Drop what is in your hand", "drop", ["drop"]],
		["Turn an item in the bag", "turn", ["rotate_item"]],
		["Throw — bait the Hunter", "throw", ["throw"]],
	]],
	# **A group of its own, and that is the point** (`M4-T13`, `ART-001`).
	#
	# The shutter could have been filed under CARRYING — a lantern is a thing
	# you carry — and it would have read as bag management. Darkness is a
	# mechanic here, and a player scanning this list for what the game is about
	# should find *seeing* named as one of its verbs rather than buried among
	# the ways to move an item between squares.
	["SEEING", [
		["Open or shutter the lantern", "shutter", ["shutter"]],
	]],
	["LEAVING", [
		["Spend a Waystone", "waystone", ["use_waystone"]],
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
	_body = column
	centre.add_child(column)
	column.add_child(MenuStyle.title("CONTROLS", 34))

	# **Two columns, because one did not fit** (ADR-137). Stacked in a single
	# table this ran past the bottom of a 648-line viewport and cut the BACK
	# button in half — invisible to `--menu-probe`, which can prove every row
	# exists and cannot see where any of them landed. `--menu-shot` photographs
	# it now, and the probe asserts the built column fits.
	#
	# The split is **computed, not written down**: `M4-T06` adds rebinding rows
	# and `DES-009` still owes three combat verbs, so a hardcoded halfway point
	# would be wrong by the next task that touches the input map.
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 40)
	column.add_child(spread)

	var total: int = 0
	for group: Array in GROUPS:
		total += (group[1] as Array).size()

	var left: GridContainer = _table()
	var right: GridContainer = _table()
	spread.add_child(left)
	spread.add_child(right)

	var placed: int = 0
	for group: Array in GROUPS:
		var rows: Array = group[1] as Array
		var table: GridContainer = left if placed * 2 < total else right
		_heading(table, String(group[0]))
		for row: Array in rows:
			_row(table, String(row[0]), PackedStringArray(row[2] as Array))
		placed += rows.size()

	column.add_child(_gap(14))
	var back: Button = MenuStyle.button("BACK")
	# Every other menu's column is one button wide, so a stretched button looks
	# right there and looks like a banner here. Shrink to its own width instead.
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	column.add_child(back)
	back.grab_focus()


## One action's binding as running text — `"e/X"`, `"tab/LB"`, `"lmb/RT"`.
##
## **The seam that makes one control list possible** (ADR-139). Before it, four
## lists existed: this screen, the Threshold's readout, the bag's footer, and
## two lines buried at the bottom of `DebugReadout`. Three were hand-typed, two
## were already stale — `DebugReadout` still said `i/Y ink` after ADR-137 moved
## it to Back — and **not one of them named the class verb**, so `F` was a built
## verb no player could discover.
##
## Contextual wording stays with the caller: the bag says *take & place* where
## this screen says *pick up, and place in the bag*, and that is a real
## difference rather than drift. Only the **keys** come from here, because the
## keys are the half that moves.
static func glyphs_for(action: String) -> String:
	return glyphs_for_all(PackedStringArray([action]))


## The same, for a row that covers several actions. `W A S D` becomes `wasd`
## rather than `w`, which is what the hand-written lists said and what a player
## reads as one thing.
static func glyphs_for_all(actions: PackedStringArray) -> String:
	var keys: PackedStringArray = keyboard_glyphs(actions)
	var pad: PackedStringArray = pad_glyphs(actions)
	var short := PackedStringArray()
	var every_one_a_letter: bool = true
	for key: String in keys:
		var text: String = String(COMPACT_KEY.get(key, key.to_lower()))
		if text.length() > 1:
			every_one_a_letter = false
		short.append(text)
	var left: String = "—"
	if not short.is_empty():
		left = "".join(short) if every_one_a_letter else "/".join(short)
	var right: String = pad[0] if not pad.is_empty() else "—"
	return "%s/%s" % [left, right]


## Short forms for running text only. The screen has room to say *Left Mouse*
## and a one-line prompt does not, and `lmb` is what every list in this game
## said before there was one list.
const COMPACT_KEY: Dictionary = {
	"Left Mouse": "lmb", "Right Mouse": "rmb", "Middle Mouse": "mmb",
}


## The whole list as running text, `per_line` prompts to a line, for readouts
## that are a `Label` rather than a screen. The Threshold uses this.
static func compact_lines(per_line: int = 4) -> PackedStringArray:
	var prompts := PackedStringArray()
	for group: Array in GROUPS:
		for row: Array in (group[1] as Array):
			var actions: PackedStringArray = PackedStringArray(row[2] as Array)
			if actions.is_empty():
				continue
			prompts.append("%s %s" % [glyphs_for_all(actions), String(row[1])])
	var out := PackedStringArray()
	var line := PackedStringArray()
	for prompt: String in prompts:
		line.append(prompt)
		if line.size() >= maxi(1, per_line):
			out.append("   ".join(line))
			line = PackedStringArray()
	if not line.is_empty():
		out.append("   ".join(line))
	return out


## The window the game is configured to open at, which is **not** the viewport
## the probe measures. Godot's headless dummy renderer reports 64×64, so a fit
## check asked against the live viewport fails in the sweep and passes nowhere —
## the shape of a check that cannot run. `ProjectSettings` answers the question
## that actually matters anyway: does this fit the window a player gets?
static func configured_window() -> Vector2:
	return Vector2(
		float(ProjectSettings.get_setting_with_override(
			&"display/window/size/viewport_width")),
		float(ProjectSettings.get_setting_with_override(
			&"display/window/size/viewport_height")))


## Does the whole list, BACK included, land inside that window?
##
## Asked because it did not. Stacked in one table the column ran past 648 lines
## and cut the button in half, and every row-level assertion was green while it
## did — *the rows all exist* and *the rows are all on screen* turn out to be
## different claims, and only the second one is what a tester needs.
func fits() -> bool:
	if _body == null:
		return false
	var window: Vector2 = configured_window()
	return _body.size.y <= window.y and _body.size.x <= window.x


func _table() -> GridContainer:
	var table := GridContainer.new()
	table.columns = 3
	table.add_theme_constant_override("h_separation", 22)
	table.add_theme_constant_override("v_separation", 4)
	return table


func _heading(table: GridContainer, text: String) -> void:
	# A heading spans the table by being a row of its own with two blanks after
	# it. `GridContainer` has no column span, and three cells is cheaper than
	# the nested containers the alternative needs.
	table.add_child(_gap(8))
	table.add_child(_gap(8))
	table.add_child(_gap(8))
	var label: Label = MenuStyle.line(text, 13, MenuStyle.WARM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size = Vector2(215.0, 0.0)
	table.add_child(label)
	table.add_child(_blank())
	table.add_child(_blank())


func _row(table: GridContainer, text: String, actions: PackedStringArray) -> void:
	var name_cell: Label = MenuStyle.line(text, 15, MenuStyle.TEXT)
	name_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_cell.custom_minimum_size = Vector2(215.0, 0.0)
	table.add_child(name_cell)
	# Wider on the left. Four arrow keys read as `Up  Left  Down  Right` and wrap
	# at the pad column's width, which costs the row a second line — and the pad
	# side never needs it, because every pad glyph here is two words at most.
	table.add_child(_glyph_cell(keyboard_glyphs(actions), 152))
	table.add_child(_glyph_cell(pad_glyphs(actions), 112))


func _glyph_cell(glyphs: PackedStringArray, width: int) -> Label:
	# An empty cell would be a lie of omission — it reads as "this verb has no
	# binding on this device", which is a different and much worse statement
	# than "nothing is bound here yet". ADR-075 makes both devices reach
	# everything, so if this ever renders the dash, that is the bug.
	var text: String = "  ".join(glyphs) if not glyphs.is_empty() else "—"
	var cell: Label = MenuStyle.line(text, 15,
		MenuStyle.TEXT if not glyphs.is_empty() else MenuStyle.DIM)
	cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cell.custom_minimum_size = Vector2(float(width), 0.0)
	return cell


## Keyboard and mouse glyphs for everything these actions are bound to, in
## `InputMap` order, each appearing once. Static so `--menu-probe` can ask
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
			for action: String in PackedStringArray(row[2] as Array):
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
