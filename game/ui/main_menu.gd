extends Control

## Where the game starts.
##
## Until now `run/main_scene` was a level, so the only way to play in company
## was a command-line flag and the only way to change a volume was to edit a
## file. This is the front door: play alone, host, join, set things, leave.
##
## ## Solo is host, and that is not a special case
##
## `TEC-004` measured it: with no peer assigned Godot installs an
## `OfflineMultiplayerPeer`, `is_server()` is true, and spawning works. So PLAY
## sets `NetPlan.Role.SOLO` and the identical scene loads. There is no
## single-player branch to drift out of sync with the real one (ADR-064).
##
## ## What HOST and JOIN honestly are
##
## A join code is **a shorter way to write an address**, not matchmaking. This
## is a direct connection: no relay, no hole-punching, so a second machine
## reaches this one only if the port is actually reachable — the same network,
## or a forwarded port. The host panel says so, because a tester who cannot
## connect will otherwise spend the evening assuming the netcode is broken.
##
## `M4-T07` brings Steam lobbies and relay. It replaces *where the address
## comes from* and nothing else — `NetPlan` is the seam, and direct entry stops
## being the only way rather than becoming a fallback nobody maintains.

const THRESHOLD: String = "res://levels/lair/threshold.tscn"

var _column: VBoxContainer
var _panel: VBoxContainer
var _settings: SettingsScreen


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(MenuStyle.backdrop())

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	_column = MenuStyle.column(12)
	centre.add_child(_column)
	_show_root()

	for arg: String in OS.get_cmdline_user_args():
		if arg == "--menu-probe":
			_menu_probe()
		elif arg.begins_with("--menu-shot="):
			_menu_shot(arg.split("=", true, 1)[1])


## Photograph every screen (`--menu-shot=DIR`).
##
## A menu's correctness is mostly a claim about *seeing* — text that clips, a
## column that runs off the bottom, a contrast nobody can read — and this
## project has been caught by that twice already on the bag screen. Headless
## probes cannot see any of it.
func _menu_shot(directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	for screen: String in ["root", "host", "join", "settings"]:
		match screen:
			"root": _show_root()
			"host": _show_host()
			"join": _show_join()
			"settings": _show_settings()
		for frame: int in range(4):
			await RenderingServer.frame_post_draw
		var shot: Image = get_viewport().get_texture().get_image()
		var path: String = "%s/menu_%s.png" % [directory, screen]
		shot.save_png(path)
		print("[menu] shot %s" % path)
		if _settings != null:
			_settings.queue_free()
			_settings = null
	get_tree().quit()


## Removed *and* freed. `queue_free` alone lands at the end of the frame, so
## for one frame both screens are children of the same column — which stacks
## the old buttons under the new ones and, less visibly, made `--menu-probe`
## count 10, 13 and 15 buttons across three screens that have five each.
func _clear() -> void:
	for child: Node in _column.get_children():
		_column.remove_child(child)
		child.queue_free()


func _show_root() -> void:
	_clear()
	_column.add_child(MenuStyle.title("SHE"))
	_column.add_child(MenuStyle.line(
		"a hoard-dragon buys your soul one run at a time", 15))
	_column.add_child(_gap(18))

	var play: Button = MenuStyle.button("DESCEND ALONE")
	play.pressed.connect(_play_solo)
	_column.add_child(play)

	var host: Button = MenuStyle.button("HOST A DESCENT")
	host.pressed.connect(_show_host)
	_column.add_child(host)

	var join: Button = MenuStyle.button("JOIN A DESCENT")
	join.pressed.connect(_show_join)
	_column.add_child(join)

	var settings: Button = MenuStyle.button("SETTINGS")
	settings.pressed.connect(_show_settings)
	_column.add_child(settings)

	var quit: Button = MenuStyle.button("QUIT")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_column.add_child(quit)
	play.grab_focus()

	# Why the last attempt ended, if it ended badly. `CoopSession` sends people
	# back here instead of closing the process, and a bounce with no
	# explanation is barely better than the quit it replaced.
	if not NetPlan.last_error.is_empty():
		_column.add_child(_gap(14))
		_column.add_child(MenuStyle.line(NetPlan.last_error, 14,
			Color(0.82, 0.42, 0.36)))
		NetPlan.last_error = ""


func _play_solo() -> void:
	NetPlan.role = NetPlan.Role.SOLO
	_enter()


func _show_host() -> void:
	_clear()
	NetPlan.role = NetPlan.Role.HOST
	var address: String = NetPlan.local_address()
	var code: String = NetPlan.code_for(address, NetPlan.DEFAULT_PORT)

	_column.add_child(MenuStyle.title("HOST", 34))
	_column.add_child(MenuStyle.line("On this network, join at", 14))
	var shown: Label = MenuStyle.line("%s : %d" % [address, NetPlan.DEFAULT_PORT],
		26, MenuStyle.WARM)
	_column.add_child(shown)
	_column.add_child(MenuStyle.line("or with the code  %s" % code, 15))

	_column.add_child(_gap(10))
	# The honest part, where somebody will actually read it.
	# Parenthesised: `%` binds to the last literal, not to a concatenation, so
	# the obvious spelling formats only the final fragment and is a parse error.
	var warning: Label = MenuStyle.line((
		"Direct connection — no relay. Someone on another network joins at "
		+ "your public IP on port %d, which has to reach this machine. Steam "
		+ "lobbies and relay arrive at M4-T07."
		) % NetPlan.DEFAULT_PORT, 13)
	warning.custom_minimum_size = Vector2(380.0, 0.0)
	_column.add_child(warning)

	_column.add_child(_gap(10))
	var copy: Button = MenuStyle.button("COPY ADDRESS")
	copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set("%s:%d" % [address, NetPlan.DEFAULT_PORT])
		copy.text = "COPIED")
	_column.add_child(copy)

	var start: Button = MenuStyle.button("OPEN THE THRESHOLD")
	start.pressed.connect(_enter)
	_column.add_child(start)

	var back: Button = MenuStyle.button("BACK")
	back.pressed.connect(_show_root)
	_column.add_child(back)
	start.grab_focus()


func _show_join() -> void:
	_clear()
	_column.add_child(MenuStyle.title("JOIN", 34))
	_column.add_child(MenuStyle.line(
		"The host's address. Port %d is assumed if you leave it off."
			% NetPlan.DEFAULT_PORT, 14))

	var field: LineEdit = MenuStyle.field("192.168.1.20  or  1.2.3.4:47018")
	_column.add_child(field)

	var problem: Label = MenuStyle.line("", 14, Color(0.82, 0.42, 0.36))
	_column.add_child(problem)

	var go: Button = MenuStyle.button("JOIN")
	go.pressed.connect(func() -> void:
		if not NetPlan.adopt_code(field.text):
			problem.text = NetPlan.last_error
			return
		NetPlan.role = NetPlan.Role.CLIENT
		_enter())
	_column.add_child(go)
	field.text_submitted.connect(func(_text: String) -> void: go.pressed.emit())

	var back: Button = MenuStyle.button("BACK")
	back.pressed.connect(_show_root)
	_column.add_child(back)
	field.grab_focus()


func _show_settings() -> void:
	if _settings != null:
		return
	_settings = SettingsScreen.new()
	# The menu underneath is hidden rather than merely covered. The backdrop is
	# 94% opaque, which over a 3D world is fine and over another menu leaves a
	# ghost of the screen behind — legible enough to read and wrong enough to
	# look broken.
	_column.visible = false
	_settings.closed.connect(func() -> void:
		_settings.queue_free()
		_settings = null
		_column.visible = true
		_show_root())
	add_child(_settings)


func _enter() -> void:
	get_tree().change_scene_to_file(THRESHOLD)


func _gap(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, float(height))
	return spacer


## Walk every screen and prove each one builds and wires up (`--menu-probe`).
##
## A menu is the one part of a build that is *guaranteed* to be exercised by a
## player and easy to leave broken, because nothing else in the sweep loads it.
## This does not test that it looks right — `--menu-shot` is for that — only
## that every branch constructs, every button has something connected, and the
## join parser accepts what the host panel prints.
func _menu_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	var round_trip: String = NetPlan.code_for("192.168.1.20", NetPlan.DEFAULT_PORT)
	var parsed: bool = NetPlan.adopt_code(round_trip)
	print("[menu] join code    192.168.1.20:%d -> %s -> %s:%d" % [
		NetPlan.DEFAULT_PORT, round_trip, NetPlan.address, NetPlan.port])
	if not parsed or NetPlan.address != "192.168.1.20" or NetPlan.port != NetPlan.DEFAULT_PORT:
		problems.append(("a join code did not survive the round trip — the host "
			+ "reads this number out loud and the client types it in, so a code "
			+ "that decodes to a different address is worse than no code"))
	if not NetPlan.adopt_code("10.0.0.4:9999") or NetPlan.port != 9999:
		problems.append("a plain host:port was rejected — a tester on a known "
			+ "address must not be forced through the code")
	if NetPlan.adopt_code("not a code at all!"):
		problems.append("nonsense was accepted as an address — a join that "
			+ "silently goes nowhere reads as a netcode bug")

	for screen: String in ["root", "host", "join"]:
		match screen:
			"root": _show_root()
			"host": _show_host()
			"join": _show_join()
		var buttons: int = 0
		var wired: int = 0
		for child: Node in _column.get_children():
			var button := child as Button
			if button == null:
				continue
			buttons += 1
			if button.pressed.get_connections().size() > 0:
				wired += 1
		print("[menu] %-11s %d button(s), %d wired" % [screen, buttons, wired])
		if buttons == 0 or wired != buttons:
			problems.append(("the %s screen has %d button(s) and %d of them do "
				+ "anything — a button that does nothing is the stub ADR-064 "
				+ "bans, and on a menu it is the first thing a player finds")
				% [screen, buttons, wired])

	_show_settings()
	await get_tree().process_frame
	var sliders: int = 0
	for node: Node in _settings.find_children("*", "Range", true, false):
		sliders += 1
	print("[menu] settings    %d slider(s)" % sliders)
	if sliders < Settings.VOLUME_BUSES.size():
		problems.append(("settings shows %d slider(s) for %d bus(es) plus look "
			+ "— DES-018 asks for independent per-bus volumes and a missing one "
			+ "is a channel somebody cannot turn down")
			% [sliders, Settings.VOLUME_BUSES.size()])

	problems.append_array(await _walk_the_loop())

	for problem: String in problems:
		printerr("[menu] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


## **Menu → Threshold → Deep → Chamber → Threshold**, actually walked.
##
## Every scene in the loop has its own probe already, and all of them pass while
## the loop between them is broken — a scene path with a typo in it fails only
## when a player presses the button, which in a playtest means it fails in front
## of somebody. This loads each scene in turn and asserts it came up with the
## thing that makes it that scene.
func _walk_the_loop() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	# Solo, because the screens above left the plan on HOST and a port set by
	# the parser test — so the walk tried to open a server twice on someone
	# else's port. The probe controls its own variables, including the ones it
	# set itself two functions ago.
	NetPlan.role = NetPlan.Role.SOLO
	NetPlan.port = NetPlan.DEFAULT_PORT
	var stops: Array[Array] = [
		["res://levels/lair/threshold.tscn", "threshold"],
		["res://levels/room_set/room_set.tscn", "deep"],
		["res://levels/lair/chamber.tscn", "chamber"],
		["res://levels/lair/threshold.tscn", "threshold"],
	]
	for stop: Array in stops:
		var path: String = stop[0] as String
		var expected: String = stop[1] as String
		if not ResourceLoader.exists(path):
			problems.append("%s is not in the build — every door in the menu "
				% path + "leads somewhere and this one leads nowhere")
			continue
		var scene := load(path) as PackedScene
		var instance: Node = scene.instantiate()
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		var place: String = AudioDirector.place()
		var paused: int = instance.find_children("*", "PauseMenu", true, false).size()
		print("[menu] %-11s loaded, sounds like '%s', %d way(s) out" % [
			expected, place, paused])
		if place != expected:
			problems.append(("%s came up playing '%s' — a level that does not "
				+ "declare where it is inherits the last piece, and the Deep's "
				+ "score over a campfire is the failure ADR-099 exists for")
				% [path, place])
		if paused != 1:
			problems.append(("%s has %d pause menu(s) — with none there is no "
				+ "way out but killing the process, and a playtester who cannot "
				+ "leave stops reporting anything useful") % [path, paused])
		instance.queue_free()
		await get_tree().process_frame
	return problems
