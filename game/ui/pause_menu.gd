class_name PauseMenu
extends CanvasLayer

## The way back out, from anywhere in the game.
##
## Before this there was no way to leave a level except closing the process,
## which makes a playtest session an exercise in alt-tabbing and makes "quit
## and try that again" cost thirty seconds of relaunch.
##
## ## It does not pause anything
##
## `DES-019` makes the bag real-time *"because rummaging is a vulnerable act"*,
## and a pause menu that froze the world would hand back exactly the safety the
## inventory is designed to deny. So the tree keeps running: this is a menu you
## open while the Deep carries on around you, and stepping away from the
## keyboard is not a tactic.
##
## That is a deliberate reading rather than an oversight, and it is also the
## honest one for a **co-op** game — `get_tree().paused` on one peer pauses
## nothing for the other three, so a pause that worked solo and did nothing in
## company would be the worst of both.
##
## ## Leaving is a real thing that happens to the run
##
## `ABANDON THE RUN` is not a safe exit. Whatever you were carrying is gone, the
## same as dying with it — `DES-008`'s great reset — because a menu that let you
## bank a risky haul by quitting would make every extraction optional.
##
## **But only when there is a run** (ADR-152). This menu is the same object in
## the Deep, at the fire and in the Chamber, and in two of those three there is
## no run to abandon: `RunFile` is opened at the descent and closed when the run
## resolves. It called `die()` in all three anyway, so a player standing at the
## fire between descents — with a class, a tree, a stash and gear — could end
## their life with one click on a button that promised to abandon a run, with no
## confirmation and nothing else on the menu that goes back to the main menu.
##
## Reported as *"starting a new run showed the tithe menu"*: the life ended at
## the fire, so the Legacy screen was waiting on the next descent, which is
## correct behaviour and an unrecognisable cause.

const MENU: String = "res://ui/main_menu.tscn"
## This menu's claim on the body (ADR-146). Named, so closing this screen
## cannot hand the player back to a world that another screen is still standing
## in front of.
const CLAIM: StringName = &"pause"

var _root: Control
var _column: VBoxContainer
var _settings: SettingsScreen
var _controls: ControlsScreen
var _open: bool = false
## True while the second press is being asked for. Cleared on close, so a menu
## reopened later never comes back mid-question.
var _confirming: bool = false
## The button that leaves, held so a probe can press the one that is there
## rather than guessing which of the two it is.
var _way_out: Button = null


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_root.add_child(MenuStyle.backdrop())

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(centre)
	_column = MenuStyle.column(12)
	centre.add_child(_column)
	_rebuild()


## Rebuilt rather than built once: what the way out costs depends on whether a
## run is open, and a run resolving inside a level is exactly the moment that
## changes.
func _rebuild() -> void:
	for child: Node in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	if _confirming:
		_build_confirmation()
		MenuStyle.focus_first.call_deferred(_root)
		return
	_column.add_child(MenuStyle.title("PAUSED", 34))
	_column.add_child(MenuStyle.line(
		"The Deep does not stop while this is open.", 14))
	_column.add_child(_gap(14))

	var resume: Button = MenuStyle.button("BACK TO IT")
	resume.pressed.connect(close)
	_column.add_child(resume)

	# Reachable mid-run as well as from the menu (ADR-137). A player who forgets
	# which key drops loot forgets it while holding loot, and the Deep does not
	# stop while this is open — so the answer has to be one screen away from
	# where the question is actually asked.
	var controls: Button = MenuStyle.button("CONTROLS")
	controls.pressed.connect(_show_controls)
	_column.add_child(controls)

	var settings: Button = MenuStyle.button("SETTINGS")
	settings.pressed.connect(_show_settings)
	_column.add_child(settings)

	# **What this costs depends on where you are standing** (ADR-152), and it is
	# rebuilt on every open because a run resolving is what changes the answer.
	if leaving_ends_the_life():
		_way_out = MenuStyle.button("ABANDON THE RUN")
		_way_out.pressed.connect(_ask_first)
	else:
		_way_out = MenuStyle.button("TO THE MENU")
		_way_out.pressed.connect(_leave)
	_column.add_child(_way_out)

	var quit: Button = MenuStyle.button("QUIT TO DESKTOP")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_column.add_child(quit)


## **Ending a life takes two presses** (ADR-152). Everything else on this menu
## is reversible; this one is the great reset, arriving through a button rather
## than through a fight, and `PRO-005` is explicit that the harshness has to be
## legible *in advance*.
func _ask_first() -> void:
	_confirming = true
	_rebuild()


func _build_confirmation() -> void:
	_column.add_child(MenuStyle.title("ABANDON THE RUN", 30))
	_column.add_child(MenuStyle.line(
		"This ends the life. The tree, the stash, what you are wearing and "
		+ "everything you are carrying go with it.", 15))
	_column.add_child(MenuStyle.line(
		"The hoard is untouched. It always is.", 14, MenuStyle.WARM))
	_column.add_child(_gap(14))

	_way_out = MenuStyle.button("END IT")
	_way_out.pressed.connect(_leave)
	_column.add_child(_way_out)

	var back: Button = MenuStyle.button("NOT YET")
	back.pressed.connect(func() -> void:
		_confirming = false
		_rebuild())
	_column.add_child(back)


## **Does leaving cost the life?** (ADR-152)
##
## `RunFile.exists()` rather than a level asking what kind of level it is: a run
## is opened at the descent and closed when it resolves, so this is the game's
## own definition of being inside one, in the one file that owns it (ADR-050).
##
## An unarmed process — a probe booting a level directly — sees no run at all
## (ADR-138), so the default is the answer that costs nothing.
func leaving_ends_the_life() -> bool:
	return RunFile.exists()


## What leaving costs, taken. **Separate from the departure**, because
## `change_scene_to_file` detaches this node synchronously (ADR-117) and takes
## any check with it — so the cost can be asserted and the going cannot.
func take_what_leaving_costs() -> void:
	if leaving_ends_the_life():
		GameState.die()


## The button that leaves, whichever of the two it currently is. For
## `--threshold-probe`, which presses it rather than calling past it.
func way_out() -> Button:
	return _way_out


## True while the confirmation is up and nothing has been taken yet.
func confirming() -> bool:
	return _confirming


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# The bag owns Escape while it is open (`DES-019`), so a player closing
	# their inventory does not find themselves staring at a menu instead.
	get_viewport().set_input_as_handled()
	var body: Player = _local_body()
	if body != null and body.wants_bag():
		body.close_bag()
		return
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open:
		return
	_open = true
	_confirming = false
	_rebuild()
	_root.visible = true
	MenuStyle.focus_first.call_deferred(_root)
	var body: Player = _local_body()
	if body != null:
		# The body owns the cursor, because it is the thing that would take it
		# back (ADR-141). Setting `mouse_mode` here as well was the second
		# writer, and it is gone rather than left beside the first.
		body.hold_attention(CLAIM)
	else:
		# No body to drive — between a despawn and a spawn, or on a floor that
		# never built one. Nothing else is competing for the cursor, so this
		# menu takes it directly.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not _open:
		return
	_open = false
	_confirming = false
	_root.visible = false
	if _settings != null:
		_settings.queue_free()
		_settings = null
	# Freed for the same reason the settings panel is, and it was not: a
	# controls screen left standing behind a hidden pause menu is still there
	# when the menu reopens, and `_show_controls` refuses to build a second one
	# for the rest of the level.
	if _controls != null:
		_controls.queue_free()
		_controls = null
	var body: Player = _local_body()
	if body != null:
		# **Only our own claim** (ADR-146). This said `set_driving(true)`, which
		# is a statement about the whole game rather than about this menu, and
		# it handed the body back from underneath the Legacy screen.
		body.release_attention(CLAIM)


func _show_settings() -> void:
	if _settings != null:
		return
	_settings = SettingsScreen.new()
	_settings.closed.connect(func() -> void:
		_settings.queue_free()
		_settings = null)
	_root.add_child(_settings)


func _show_controls() -> void:
	if _controls != null:
		return
	_controls = ControlsScreen.new()
	_controls.closed.connect(func() -> void:
		_controls.queue_free()
		_controls = null)
	_root.add_child(_controls)


## Out, and it costs what leaving costs **here**.
func _leave() -> void:
	take_what_leaving_costs()
	# The peer goes with us. A process that changed scene while still hosting
	# would leave the other players connected to a lobby nobody is in.
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	# **Back to the offline peer, never to null** (`M2-T15`, ADR-107). This line
	# used to assign `null`, which stopped the hosting correctly and left the
	# process with no peer at all — and every solo path here depends on the
	# offline one Godot installs at startup. `CoopSession` repairs it too, but
	# the menu should not be sitting in a state the next scene has to fix.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	NetPlan.role = NetPlan.Role.SOLO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU)


func _local_body() -> Player:
	for node: Node in get_tree().get_nodes_in_group("player"):
		var body := node as Player
		if body != null and body.is_multiplayer_authority():
			return body
	return null


func _gap(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, float(height))
	return spacer
