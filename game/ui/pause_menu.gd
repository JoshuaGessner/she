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
## `LEAVE` is not a safe exit. Whatever you were carrying is gone, the same as
## dying with it — `DES-008`'s great reset — because a menu that let you bank a
## risky haul by quitting would make every extraction optional.

const MENU: String = "res://ui/main_menu.tscn"

var _root: Control
var _column: VBoxContainer
var _settings: SettingsScreen
var _open: bool = false


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
	_build()


func _build() -> void:
	_column.add_child(MenuStyle.title("PAUSED", 34))
	_column.add_child(MenuStyle.line(
		"The Deep does not stop while this is open.", 14))
	_column.add_child(_gap(14))

	var resume: Button = MenuStyle.button("BACK TO IT")
	resume.pressed.connect(close)
	_column.add_child(resume)

	var settings: Button = MenuStyle.button("SETTINGS")
	settings.pressed.connect(_show_settings)
	_column.add_child(settings)

	var leave: Button = MenuStyle.button("ABANDON THE RUN")
	leave.pressed.connect(_leave)
	_column.add_child(leave)

	var quit: Button = MenuStyle.button("QUIT TO DESKTOP")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_column.add_child(quit)


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
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var body: Player = _local_body()
	if body != null:
		body.set_driving(false)


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	if _settings != null:
		_settings.queue_free()
		_settings = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var body: Player = _local_body()
	if body != null:
		body.set_driving(true)


func _show_settings() -> void:
	if _settings != null:
		return
	_settings = SettingsScreen.new()
	_settings.closed.connect(func() -> void:
		_settings.queue_free()
		_settings = null)
	_root.add_child(_settings)


## Out, and it costs what leaving always costs.
func _leave() -> void:
	GameState.die()
	# The peer goes with us. A process that changed scene while still hosting
	# would leave the other players connected to a lobby nobody is in.
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
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
