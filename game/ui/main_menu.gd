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
var _controls: ControlsScreen


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
		if arg == "--again":
			_again()
		if arg == "--class-probe":
			_class_probe()
		if arg == "--menu-probe":
			_menu_probe()
		if arg == "--rebind-probe":
			_rebind_probe()
		if arg == "--lineage-probe":
			_lineage_probe()
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
	# **`controls` is in this list because it is the one screen a first-time
	# tester is asked to read** (ADR-137). It is also the only generated one —
	# a table whose row count comes from `InputMap` — so it is the screen most
	# able to grow past the bottom of the viewport without any code changing.
	# `--menu-probe` can prove every row exists; only a photograph can show
	# whether the last one is on screen.
	for screen: String in ["root", "host", "join", "settings", "controls", "abandon"]:
		match screen:
			"root": _show_root()
			"abandon": _show_abandon()
			"host": _show_host()
			"join": _show_join()
			"settings": _show_settings()
			"controls": _show_controls()
		for frame: int in range(4):
			await RenderingServer.frame_post_draw
		var shot: Image = get_viewport().get_texture().get_image()
		var path: String = "%s/menu_%s.png" % [directory, screen]
		shot.save_png(path)
		print("[menu] shot %s" % path)
		if _settings != null:
			_settings.queue_free()
			_settings = null
		if _controls != null:
			_controls.queue_free()
			_controls = null
			_column.visible = true
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
		"a hoard-dragon buys your soul one run at a time"))
	var said: Array = lineage_line(SaveFile.standing())
	if not said.is_empty():
		_column.add_child(_gap(6))
		var told: Label = MenuStyle.line(String(said[0]), said[1] as StringName)
		told.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_column.add_child(told)
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

	# **Above SETTINGS, not below it** (ADR-137). `GATE M3 EXIT` allows a tester
	# no coaching beyond this list, so it is the one menu entry a first-time
	# player is expected to open before their first descent — and a person
	# looking for *how do I play* does not look under a heading called settings.
	var controls: Button = MenuStyle.button("CONTROLS")
	controls.pressed.connect(_show_controls)
	_column.add_child(controls)

	var settings: Button = MenuStyle.button("SETTINGS")
	settings.pressed.connect(_show_settings)
	_column.add_child(settings)

	# **The lineage, and the way to set it aside** (`M4-T06`, ADR-246). Only a
	# profile this build can read may be abandoned: one from a newer build is
	# not this build's to touch, which is the whole of what it is told.
	var standing: Dictionary = SaveFile.standing()
	if String(standing["state"]) == "readable":
		var abandon: Button = MenuStyle.button("ABANDON THIS LINEAGE")
		abandon.pressed.connect(_show_abandon)
		_column.add_child(abandon)

	var quit: Button = MenuStyle.button("QUIT")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_column.add_child(quit)
	play.grab_focus()

	# Why the last attempt ended, if it ended badly. `CoopSession` sends people
	# back here instead of closing the process, and a bounce with no
	# explanation is barely better than the quit it replaced.
	if not NetPlan.last_error.is_empty():
		_column.add_child(_gap(14))
		_column.add_child(MenuStyle.line(NetPlan.last_error,
			MenuStyle.CAPTION_FAULT))
		NetPlan.last_error = ""


## **Down, out, and down again** (`M3-T38`, ADR-160).
##
## Reported from play: descend, abandon immediately, start another run, answer
## the Legacy screen at the fire — and the hole does nothing. **Nothing in the
## sweep had ever walked that**, and the reason is structural rather than an
## oversight: every probe boots one level directly, `--menu-probe`'s loop
## instantiates levels side by side without entering them, and `run_doorway.py`
## is about two processes. A player's second descent of a session crosses four
## scenes and two of the six pieces of state in `M3-T34`'s table, and no check
## in this project had ever crossed even one scene boundary in a single
## process.
##
## So this walks the loop the way a player does — through the front door, the
## camp, the floor, the pause menu, back to the front door, and down again —
## and the assertion is the blunt one: **you can descend a second time.**
##
## Its own profile and its own run file (ADR-145, ADR-152). This one genuinely
## needs both: it opens a run, ends a life, and reads the profile back through
## the menu's own `load_profile()`.
func _again() -> void:
	SaveFile.use_a_scratch_profile()
	RunFile.use_a_scratch_run()
	if SaveFile.PATH == "user://profile.save" or RunFile.PATH == "user://run.active":
		printerr("[again] FAIL pointed at the player's own files, and this "
			+ "scenario ends a life and opens a run")
		get_tree().quit(1)
		return
	SaveFile.wipe()
	await get_tree().create_timer(0.4).timeout
	print("[again] the front door, life '%s', a life waiting to be buried=%s, "
		% [GameState.class_id, GameState.life_already_ended()]
		+ "a run still open=%s" % RunFile.exists())

	# **A life that has ended has no run in progress** (`M3-T38`, ADR-160).
	#
	# `life_already_ended()` is ADR-147's own predicate — a cleared class with a
	# record still waiting — so this is the state immediately after abandoning,
	# named by the game rather than counted by the scenario.
	#
	# **Asserted here and nowhere else, because here is the only place it is
	# still visible.** `_enter()` runs `resume_is_this_life()` a few lines
	# further on, which drops the stale file as an orphan — so by the time the
	# camp could ask, the evidence has been tidied away by the repair that was
	# standing in for the fix.
	if GameState.life_already_ended() and RunFile.exists():
		printerr("[again] FAIL abandoning ended the life and left its run open "
			+ "— ADR-050 allows one run per life and that life is over, so the "
			+ "next entry has to drop it as an orphan instead of never having "
			+ "been handed it")
		get_tree().quit(1)
		return
	_enter()
	# `_enter()` may change scene, which detaches this node (ADR-117) — so
	# anything after it has to check it is still in the tree before awaiting.
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	for node: Node in find_children("*", "ClassScreen", true, false):
		var picking := node as ClassScreen
		if picking != null:
			print("[again] swearing at the front door")
			picking.press(&"huskarl")
			# The press lands a frame later, from `_process`, because that is
			# where a real click lands (`M3-T40`). Nothing below reads the
			# oath, but the scenario continues into a descent and a body with
			# no class arrives with empty hands (`M3-T07`).
			#
			# **Guarded every time round**, not once before the loop: swearing
			# here changes scene, which detaches this node — so `get_tree()`
			# goes null *between* iterations and the await on the next one is
			# a null dereference. Same rule as the two guards above (ADR-117),
			# and the loop is a third place it has to be asked.
			for _frame: int in 4:
				if not is_inside_tree():
					return
				await get_tree().process_frame


func _play_solo() -> void:
	NetPlan.role = NetPlan.Role.SOLO
	_enter()


func _show_host() -> void:
	_clear()
	NetPlan.role = NetPlan.Role.HOST
	var address: String = NetPlan.local_address()
	var code: String = NetPlan.code_for(address, NetPlan.DEFAULT_PORT)

	_column.add_child(MenuStyle.title("HOST", MenuStyle.SCREEN_TITLE))
	_column.add_child(MenuStyle.line("On this network, join at",
		MenuStyle.CAPTION_DIM))
	var shown: Label = MenuStyle.line("%s : %d" % [address, NetPlan.DEFAULT_PORT],
		MenuStyle.BANNER_WARM)
	_column.add_child(shown)
	_column.add_child(MenuStyle.line("or with the code  %s" % code))

	_column.add_child(_gap(10))
	# The honest part, where somebody will actually read it.
	# Parenthesised: `%` binds to the last literal, not to a concatenation, so
	# the obvious spelling formats only the final fragment and is a parse error.
	var warning: Label = MenuStyle.line((
		"Direct connection — no relay. Someone on another network joins at "
		+ "your public IP on port %d, which has to reach this machine. Steam "
		+ "lobbies and relay arrive at M4-T07."
		) % NetPlan.DEFAULT_PORT, MenuStyle.CAPTION_DIM)
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
	_column.add_child(MenuStyle.title("JOIN", MenuStyle.SCREEN_TITLE))
	_column.add_child(MenuStyle.line(
		"The host's address. Port %d is assumed if you leave it off."
			% NetPlan.DEFAULT_PORT, MenuStyle.CAPTION_DIM))

	var field: LineEdit = MenuStyle.field("192.168.1.20  or  1.2.3.4:47018")
	_column.add_child(field)

	var problem: Label = MenuStyle.line("", MenuStyle.CAPTION_FAULT)
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


## **What the menu says about the lineage on disk** (ADR-246): `[text, role]`,
## or empty when there is none yet. A refused one is said plainly, in the one
## tone the game keeps for something wrong you can act on, because every
## descent it covers is being thrown away.
static func lineage_line(standing: Dictionary) -> Array:
	match String(standing.get("state", "none")):
		"readable":
			return ["your lineage: %d descent%s · a hoard worth %d" % [
				int(standing["descents"]), "" if int(standing["descents"]) == 1 else "s",
				int(standing["hoard_value"])], MenuStyle.CAPTION_DIM]
		"newer":
			return [("your lineage was saved by a newer version of SHE — this one "
				+ "will not open it, and nothing you do here will be saved"),
				MenuStyle.CAPTION_FAULT]
		"unreadable":
			return [("your lineage could not be read — this build will not write "
				+ "over it, and nothing you do here will be saved"),
				MenuStyle.CAPTION_FAULT]
	return []


## **Setting a lineage aside, asked properly** (`M4-T06`, ADR-246): **held**,
## not pressed, because this is the one choice in the game that is not a run's.
## Held rather than typed because a word is a keyboard's, and ADR-075 gives a
## pad everything — Destiny 2 deletes a character the same way, on a hold long
## enough that nobody does it by passing through. The file is kept under
## another name.
const ABANDON_LABEL: String = "HOLD TO ABANDON"

## The hold button while it is on screen, and how long it has been held; below
## zero when nobody is holding it.
var _abandon: Button = null
var _abandon_held: float = -1.0


func _show_abandon() -> void:
	_clear()
	_column.add_child(MenuStyle.title("ABANDON", MenuStyle.SCREEN_TITLE))
	var told: Label = MenuStyle.line(("Everything she has kept of you — the hoard, "
		+ "the deeds, the lives — is set aside, and your next descent begins a new "
		+ "lineage. The old one is kept on disk under another name. Hold the "
		+ "button for %d seconds to confirm.")
		% roundi(Config.tuning.abandon_hold_seconds), MenuStyle.CAPTION_DIM)
	told.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(told)
	_abandon = MenuStyle.button(ABANDON_LABEL)
	_abandon_held = -1.0
	# `button_down` and `button_up` come from a mouse, a key and a pad's accept
	# alike, so one pair of signals is the whole of the parity.
	_abandon.button_down.connect(func() -> void: _abandon_held = 0.0)
	_abandon.button_up.connect(_let_go_of_abandon)
	_abandon.tree_exited.connect(func() -> void:
		_abandon = null
		_abandon_held = -1.0)
	_column.add_child(_abandon)
	var back: Button = MenuStyle.button("BACK")
	back.pressed.connect(_show_root)
	_column.add_child(back)
	# BACK first: the safe choice is where a pad lands.
	back.grab_focus()


func _process(delta: float) -> void:
	hold_abandon(delta)


## **Time on the hold** — `_process`'s, and the probe's, so a hold is measured
## the same way whoever is counting. Says the seconds left on the button in
## words (`DES-018`: not a fill colour alone), and sets the lineage aside when
## they run out.
func hold_abandon(delta: float) -> void:
	if _abandon == null or _abandon_held < 0.0:
		return
	_abandon_held += delta
	var hold: float = Config.tuning.abandon_hold_seconds
	if _abandon_held < hold:
		_abandon.text = "KEEP HOLDING — %d" % ceili(hold - _abandon_held)
		return
	_abandon_held = -1.0
	GameState.forget_the_lineage()
	_show_root()


func _let_go_of_abandon() -> void:
	_abandon_held = -1.0
	if _abandon != null:
		_abandon.text = ABANDON_LABEL


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


func _show_controls() -> void:
	if _controls != null:
		return
	_controls = ControlsScreen.new()
	# Same hide-rather-than-cover rule as the settings panel above, and for the
	# same reason: 94% opacity over another menu leaves a ghost of it behind.
	_column.visible = false
	_controls.closed.connect(func() -> void:
		_controls.queue_free()
		_controls = null
		_column.visible = true
		_show_root())
	add_child(_controls)


## Into the Lair, and the one place a profile is opened (`M3-T06`).
##
## Here rather than in `GameState._ready()` because this is where a *session*
## starts: a player pressing this is the moment they have a profile, and it is
## the only path into the game. An autoload that loaded at boot would also load
## in every probe that boots a level directly, so each one would inherit
## whatever the last one wrote — and `GameState` writing back only once it has
## read makes that impossible in the other direction too.
func _enter() -> void:
	if not GameState.load_profile():
		# `SaveFile` has already said what was wrong with it. The run is allowed
		# to start — refusing to play at all because of an unreadable file is a
		# worse answer than playing without saving — and nothing will be written
		# over it. Telling a player any of this is `M4-T06`.
		push_warning("MainMenu: descending without a profile; nothing will be saved")
	# **A life needs somebody to live it** (`M3-T02`). A profile with no class
	# is a fresh one or one whose last life ended, and `DES-011` puts the choice
	# at exactly those two moments. It sits between the profile and the
	# Threshold rather than earlier, because the answer is *per life* and the
	# profile is what knows whether this life has one.
	# **A run already open is the only run you may have** (`M3-T15`, ADR-050).
	#
	# *"Quitting mid-run suspends; you resume into the same run"* — so a live
	# `user://run.active` is not a prompt, it is the answer. There is no fresh
	# descent on offer while one is open, which is what makes quitting cost
	# exactly what staying would have cost.
	#
	# Ahead of the class gate below, deliberately: a suspended run already has
	# a class, and asking again would be offering the one escape this exists to
	# close — quit, come back somebody else, keep the tree.
	RunFile.arm()
	if resume_is_this_life():
		get_tree().change_scene_to_file(THRESHOLD)
		return
	# **A life that just ended is asked about at the fire, not here** (ADR-141).
	#
	# `die()` leaves `last_life` behind and clears `class_id`, so both of the
	# questions below look unanswered. They are the *same* question: `DES-003`
	# makes the Legacy screen one flow — what you learned, what she keeps, who
	# you are next — and `PRO-001` is explicit that it is *"one flow and not two
	# screens"*, because a Rite node in a slot only pays out if the next life
	# repeats its class.
	#
	# Asking here as well split that flow in half across a scene change. The
	# profile that reported this had `last_life.class_id = "veidimadr"` sitting
	# under `life.class_id = "huskarl"`: a class sworn at the menu, and the dead
	# life still waiting to be answered. The Threshold then opened the Legacy
	# screen on a **brand-new life**, which reads exactly like what it was
	# reported as — *"an overlay like I was dead right off the bat"*.
	#
	# So the menu asks only when nobody has died: a first life ever, or one
	# whose Legacy question has already been answered.
	if menu_asks_the_class():
		_choose_a_class()
		return
	# **The run begins at the hole, not here** (ADR-143). This opened one for a
	# life that had a class and nothing opened one for a life that gained its
	# class later — the class screen changed scene without it, so a first life,
	# and every life after a death, descended with no run file at all and
	# ADR-050's *quitting is never an escape* simply did not apply to them.
	#
	# `Threshold._descend()` is the honest moment: a run **is** a descent, and
	# it is the one line every route into the Deep passes through.
	get_tree().change_scene_to_file(THRESHOLD)


## **Is the open run this life's run?** (ADR-138)
##
## The descent used to resume on the run file's mere *existence*, and `class_id`
## was written into that file by `begin()` and read by **nothing** — dead data
## `check_dead.py` cannot see, because `begin()` is called.
##
## What that cost, exactly once and in front of the person it was built for: a
## run file left behind by a probe, a profile that had never been written, and
## the existence check skipping class select. The result was a body on the floor
## with no class, therefore no kit, therefore nothing in its hand — and
## `MeleeWeapon.request_swing` returns false on an empty hand, so the attack
## button did nothing at all. Not one of those steps was wrong on its own.
##
## A run file says **where you are inside a life**. Without that life there is
## nothing to resume *into*, so an orphaned run is dropped rather than entered.
## It costs one run, which is exactly what a run file is worth; entering it
## costs a descent that cannot be played.
##
## Public because `--class-probe` asks it directly. The alternative is asserting
## against `change_scene_to_file`, which detaches this node synchronously and
## takes the probe with it (ADR-117).
func resume_is_this_life() -> bool:
	if not RunFile.exists():
		return false
	var run: Dictionary = RunFile.read()
	var sworn: StringName = StringName(run.get("class_id", ""))
	if sworn != &"" and sworn == GameState.class_id:
		print("[run] a run is still open — resuming it as '%s'" % sworn)
		return true
	push_warning(("MainMenu: the open run belongs to '%s' and this life is "
		+ "'%s'; dropping it") % [sworn, GameState.class_id])
	RunFile.clear()
	return false


## **Is the class question this screen's to ask?** (ADR-141)
##
## Only when nobody is waiting to be buried. `die()` clears `class_id` *and*
## leaves `last_life` behind, so both questions look open — but they are the
## same question, and `DES-003` gives it to the fire as one flow: what you
## learned, what she keeps, who you are next. `PRO-001` calls that *"one flow
## and not two screens"* because a Rite node in a slot only pays out if the next
## life repeats its class, so the class and the slots have to be chosen in sight
## of each other.
##
## Asking here as well split that flow across a scene change, and the profile
## that reported it proved the split: `last_life.class_id = "veidimadr"` sitting
## under `life.class_id = "huskarl"`. The fire then opened a death screen on a
## life that had just begun.
func menu_asks_the_class() -> bool:
	return GameState.class_id == &"" and GameState.last_life.is_empty()


func _choose_a_class() -> void:
	var screen := ClassScreen.new()
	# Onto a layer of its own, above whatever the menu had built. The menu is
	# left standing rather than torn down: this screen can be the last thing
	# between a player and a run, and a failure to build it must not leave them
	# looking at nothing (ADR-107's grey screen).
	var layer := CanvasLayer.new()
	layer.layer = 6
	layer.add_child(screen)
	add_child(layer)
	screen.chosen.connect(func(id: StringName) -> void:
		print("[menu] sworn as %s" % id)
		get_tree().change_scene_to_file(THRESHOLD))


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
	# **This one too** (ADR-145). `_walk_the_loop()` wipes the profile between
	# stops, and it was the last thing still deleting a real lineage after the
	# save and class probes had been sent to a scratch file — a full sweep still
	# came back with the profile gone, which is how it was found. Three probes
	# touched that file and two of them were obvious.
	SaveFile.use_a_scratch_profile()
	# **And the run file** (ADR-152). This probe's last stop presses DESCEND,
	# which runs the real `_enter()` — so it arms and can clear a run through
	# the game's own front door rather than through anything probe-shaped.
	# Found by `RunFile.arm()` refusing, which is the whole argument for that
	# refusal being loud: four probes have reached this file and not one of
	# them said so in any output.
	RunFile.use_a_scratch_run()

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

	problems.append_array(await _controls_probe())

	# Held before the walk, because its last stop presses Descend and
	# `change_scene_to_file` detaches this menu **synchronously** — so by the
	# time the report is printed, `get_tree()` on this node is null. The
	# `SceneTree` itself outlives the node; the node's path to it does not.
	var tree: SceneTree = get_tree()
	problems.append_array(await _walk_the_loop())

	for problem: String in problems:
		printerr("[menu] FAIL %s" % problem)
	tree.quit(1 if problems.size() > 0 else 0)


## **The control list agrees with the input map, in both directions** (ADR-137).
##
## `GATE M3 EXIT` allows a tester no coaching beyond this screen, so an action
## the screen does not name is an action that does not exist as far as the
## session is concerned — and the failure it produces is attributed to whatever
## system the tester could not reach, not to the list. That is the expensive
## kind of wrong answer: it looks like a design finding.
##
## Asked both ways on purpose. A screen checked only against its own table can
## only ever confirm itself, which is the fault `bind_gamepad.py` shipped with
## and `M3-T06` found again in `load_profile` — a check that enumerates its own
## expectations is not a check.
## The root's buttons by label, for the lineage probe.
func _root_labels() -> PackedStringArray:
	var out := PackedStringArray()
	for node: Node in _column.find_children("*", "Button", true, false):
		out.append((node as Button).text)
	return out


## Every label the root is showing, joined, for the lineage probe.
func _root_text() -> String:
	var out := PackedStringArray()
	for node: Node in _column.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return " | ".join(out)


func _write_profile_text(text: String) -> void:
	var file := FileAccess.open(SaveFile.PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## **`--lineage-probe`** (`M4-T06`, ADR-246). No profile: nothing said and
## nothing to abandon. A readable one: named, and abandoned only by the word
## typed, which moves it aside intact, closes its run and leaves this process a
## lineage nobody has lived. A newer one and an unreadable one: said plainly in
## the fault tone, never offered for abandoning, opened by nothing, and every
## place a player stands says nothing is being saved.
func _lineage_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	SaveFile.use_a_scratch_profile()
	RunFile.use_a_scratch_run()
	RunFile.arm()
	if SaveFile.PATH == "user://profile.save" or RunFile.PATH == "user://run.active":
		printerr("[lineage] FAIL this probe is pointed at the player's files")
		get_tree().quit(1)
		return
	SaveFile.wipe()
	RunFile.clear()

	# ─ 1. no profile ─
	_show_root()
	var bare: PackedStringArray = _root_labels()
	print("[lineage] no profile      %s; abandon offered %s (want none, no)"
		% [SaveFile.standing()["state"], bare.has("ABANDON THIS LINEAGE")])
	if String(SaveFile.standing()["state"]) != "none" or bare.has("ABANDON THIS LINEAGE"):
		problems.append("with no profile the menu offered to abandon one")

	# ─ 2. a readable lineage, named ─
	GameState.descents = 4
	GameState.hoard_value = 300
	SaveFile.write(GameState.to_dict())
	var original: String = FileAccess.get_file_as_string(SaveFile.PATH)
	RunFile.begin(&"huskarl", 1, 5)
	_show_root()
	var named: String = _root_text()
	var offered: bool = _root_labels().has("ABANDON THIS LINEAGE")
	print("[lineage] readable        '%s'; abandon offered %s (want 4 descents and 300, yes)"
		% [named, offered])
	if not named.contains("4 descents") or not named.contains("300") or not offered:
		problems.append("a readable lineage was not named, or could not be abandoned")

	# ─ 3. abandoned only by a hold, and a pad can hold it ─
	_show_abandon()
	await get_tree().process_frame
	var go: Button = _abandon
	var hold: float = Config.tuning.abandon_hold_seconds
	var focus: Control = get_viewport().gui_get_focus_owner()
	var safe_first: bool = focus is Button and (focus as Button).text == "BACK"
	if go != null:
		go.pressed.emit()
	var survived_a_press: bool = SaveFile.exists()
	if go != null:
		go.button_down.emit()
	hold_abandon(hold * 0.6)
	var counting: String = go.text if go != null else ""
	if go != null:
		go.button_up.emit()
	hold_abandon(hold)
	var survived_letting_go: bool = SaveFile.exists() and go != null \
		and go.text == ABANDON_LABEL
	# The pad's own accept, through the viewport, onto the focused button.
	var pad_holds: bool = false
	if go != null:
		go.grab_focus()
		var down := InputEventJoypadButton.new()
		down.button_index = JOY_BUTTON_A
		down.pressed = true
		get_viewport().push_input(down)
		pad_holds = _abandon_held >= 0.0
		var up := InputEventJoypadButton.new()
		up.button_index = JOY_BUTTON_A
		up.pressed = false
		get_viewport().push_input(up)
		pad_holds = pad_holds and _abandon_held < 0.0 and SaveFile.exists()
	if go != null:
		go.button_down.emit()
	hold_abandon(hold * 0.5)
	hold_abandon(hold * 0.5 + 0.01)
	await get_tree().process_frame
	var set_aside: PackedStringArray = PackedStringArray()
	for name: String in DirAccess.get_files_at("user://"):
		if name.begins_with(SaveFile.PATH.get_file() + ".abandoned."):
			set_aside.append(name)
	var kept_whole: bool = set_aside.size() == 1 and FileAccess.get_file_as_string(
		"user://" + set_aside[0]) == original
	print("[lineage] abandoning      BACK first %s, a press did nothing %s, counting '%s', letting go did nothing %s, a pad's accept holds it %s; set aside %d, whole %s; profile %s, run %s; descents %d, hoard %d, saving %s (want yes, yes, KEEP HOLDING, yes, yes, 1, yes, gone, gone, 1, 0, no)"
		% [safe_first, survived_a_press, counting, survived_letting_go, pad_holds,
			set_aside.size(), kept_whole, "there" if SaveFile.exists() else "gone",
			"open" if RunFile.exists() else "gone", GameState.descents,
			GameState.hoard_value, GameState.saving()])
	if not (safe_first and survived_a_press and counting.begins_with("KEEP HOLDING")
			and survived_letting_go):
		problems.append("the abandon could be done without holding it through")
	if not pad_holds:
		problems.append("a pad's accept could not hold the abandon, or letting go of it did not stop it")
	if SaveFile.exists() or not kept_whole:
		problems.append("an abandoned lineage was not moved aside whole")
	if RunFile.exists():
		problems.append("an abandoned lineage's run was left open")
	if GameState.descents != 1 or GameState.hoard_value != 0 or GameState.saving():
		problems.append("this process kept the abandoned lineage in memory")
	var after_root: bool = _root_labels().has("ABANDON THIS LINEAGE")
	if after_root:
		problems.append("the menu still offered to abandon a lineage that is gone")

	# ─ 4. a newer profile, and an unreadable one ─
	for kind: String in ["newer", "unreadable"]:
		SaveFile.wipe()
		_write_profile_text('{"meta": {"save_version": %d}, "lineage": {}}'
			% (SaveFile.SAVE_VERSION + 5) if kind == "newer" else "this is not a save")
		_show_root()
		var said: Array = lineage_line(SaveFile.standing())
		var abandon_offered: bool = _root_labels().has("ABANDON THIS LINEAGE")
		var opened: bool = GameState.load_profile()
		var camp: PackedStringArray = Threshold.saving_lines()
		var before: String = FileAccess.get_file_as_string(SaveFile.PATH)
		GameState.descents = 9
		GameState._persist()
		var untouched: bool = FileAccess.get_file_as_string(SaveFile.PATH) == before
		print("[lineage] %-15s %s; said in %s: '%s'; abandon offered %s; opened %s; the camp says %s; the file untouched %s (want %s, the fault tone, no, no, NOT BEING SAVED, yes)"
			% [kind, SaveFile.standing()["state"],
				said[1] if not said.is_empty() else "nothing",
				said[0] if not said.is_empty() else "", abandon_offered, opened,
				camp[0] if not camp.is_empty() else "nothing", untouched, kind])
		if String(SaveFile.standing()["state"]) != kind or said.is_empty() \
				or said[1] != MenuStyle.CAPTION_FAULT or abandon_offered:
			problems.append("a %s profile was not said plainly, or was offered for abandoning" % kind)
		if opened or not GameState.refused_a_profile() or camp.is_empty() \
				or not camp[0].begins_with("NOT BEING SAVED"):
			problems.append("a %s profile was opened, or the camp did not say nothing is being saved" % kind)
		if not untouched:
			problems.append("a %s profile was written over" % kind)

	SaveFile.wipe()
	RunFile.clear()
	for problem: String in problems:
		printerr("[lineage] FAIL %s" % problem)
	print("[lineage] one lineage, named, set aside only on purpose, and a refused one said everywhere")
	get_tree().quit(1 if problems.size() > 0 else 0)


## A key going down, for the rebind probe.
static func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.keycode = code
	key.pressed = true
	return key


static func _pad(button: JoyButton) -> InputEventJoypadButton:
	var press := InputEventJoypadButton.new()
	press.button_index = button
	press.pressed = true
	return press


## **`--rebind-probe`** (`M4-T06`, ADR-245). A key taken is kept, survives a
## fresh read and is what every prompt says; a clash swaps; Escape and the
## debug keys are refused; a designed pair moves together and any other share
## is refused with nothing changed; a trigger is a pad input; through the
## screen, a row of four asks for each and swaps mid-row, Escape lets go, and a
## pad capture ignores the keyboard; the defaults come back and the file
## forgets; and a file from before rebinding reads as defaults.
func _rebind_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	Settings.use_a_scratch_file()
	Settings.bindings.clear()
	Bindings.apply_overrides()
	var one := func(action: String) -> String:
		return " ".join(ControlsScreen.keyboard_glyphs(PackedStringArray([action])))
	var pad_one := func(action: String) -> String:
		return " ".join(ControlsScreen.pad_glyphs(PackedStringArray([action])))

	# ─ 1. a key taken, kept, and said everywhere ─
	var was: String = one.call("interact")
	var refused: String = Bindings.rebind("interact", _key(KEY_K))
	var prompt: String = ControlsScreen.glyphs_for("interact")
	Settings.read_again()
	var after_reload: String = one.call("interact")
	print("[rebind] a key            interact %s -> %s, refused '%s', the prompt '%s', after a fresh read %s (want E, K, nothing, k/X, K)"
		% [was, one.call("interact"), refused, prompt, after_reload])
	if refused != "" or after_reload != "K" or not prompt.begins_with("k"):
		problems.append("a rebound key was not taken, kept, or said by the prompts")
	if Settings.PATH != Settings.PROBE_PATH:
		problems.append("a fresh read put the settings path back on the player's file")

	# ─ 2. a clash swaps ─
	refused = Bindings.rebind("jump", _key(KEY_G))
	print("[rebind] a clash          jump %s, drop %s, said '%s' (want G, Space, drop took jump's)"
		% [one.call("jump"), one.call("drop"), Bindings.last_note])
	if refused != "" or one.call("jump") != "G" or one.call("drop") != "Space" \
			or not Bindings.last_note.contains("drop"):
		problems.append("taking another verb's key did not hand it the one given up")

	# ─ 3. refused: Escape, and the debug keys ─
	var escape: String = Bindings.rebind("jump", _key(KEY_ESCAPE))
	var debug: String = Bindings.rebind("debug_ink", _key(KEY_J))
	var ink_key: InputEvent = Bindings.build(
		Bindings.bound("debug_ink", Bindings.Device.KEYS)[0])
	var taken: String = Bindings.rebind("jump", ink_key)
	var start: String = Bindings.rebind("jump", _pad(JOY_BUTTON_START))
	print("[rebind] refused          Escape '%s'; Start '%s'; a debug key '%s'; the ink view's key '%s'; jump still %s and %s (want four reasons, G, A)"
		% [escape, start, debug, taken, one.call("jump"), pad_one.call("jump")])
	if escape == "" or not start.begins_with("Start") or debug == "" or taken == "" \
			or one.call("jump") != "G" or pad_one.call("jump") != "A":
		problems.append("Escape, Start, a debug key, or what a debug key holds could be taken")

	# ─ 4. a designed pair moves together; any other share is refused whole ─
	var ping_was: String = pad_one.call("ping")
	refused = Bindings.rebind("ping", _pad(JOY_BUTTON_Y))
	var pair_ok: bool = refused == "" and pad_one.call("ping") == "Y" \
		and pad_one.call("verb") == ping_was and pad_one.call("use_item") == ping_was
	var bad: String = Bindings.rebind("block", _pad(JOY_BUTTON_LEFT_SHOULDER))
	var untouched: bool = pad_one.call("block") == "RB" and pad_one.call("bag") == "LB"
	print("[rebind] shared inputs    ping on %s, verb and use on %s and %s; block to LB refused '%s', block %s, bag %s (want Y, ping's old button twice, a reason, RB, LB)"
		% [pad_one.call("ping"), pad_one.call("verb"), pad_one.call("use_item"), bad,
			pad_one.call("block"), pad_one.call("bag")])
	if not pair_ok:
		problems.append("a designed pair did not move together to the input given up")
	if bad == "" or not untouched:
		problems.append("a rebind that left two unrelated verbs on one button was allowed, or half-made")

	# ─ 5. a trigger is a pad input ─
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_LEFT
	trigger.axis_value = 1.0
	refused = Bindings.rebind("attack", trigger)
	print("[rebind] a trigger        attack %s, throw %s (want LT, RT)"
		% [pad_one.call("attack"), pad_one.call("throw")])
	if refused != "" or pad_one.call("attack") != "LT" or pad_one.call("throw") != "RT":
		problems.append("a trigger could not be taken, or its swap went wrong")

	# ─ 6. through the screen ─
	var screen := ControlsScreen.new()
	add_child(screen)
	await get_tree().process_frame
	var pressed: bool = screen.press_cell("Move", Bindings.Device.KEYS)
	for code: Key in [KEY_U, KEY_H, KEY_K, KEY_L]:
		screen.capture(_key(code))
	await get_tree().process_frame
	var moves: String = " ".join(PackedStringArray([one.call("move_forward"),
		one.call("move_left"), one.call("move_back"), one.call("move_right")]))
	print("[rebind] the screen       pressed %s; move is %s; interact moved to %s (want yes, U H K L, S)"
		% [pressed, moves, one.call("interact")])
	if not pressed or moves != "U H K L" or one.call("interact") != "S":
		problems.append("the screen did not ask for each of a row's four verbs, or lost the swap mid-row")
	screen.press_cell("Jump", Bindings.Device.KEYS)
	var let_go: bool = screen.capture(_key(KEY_ESCAPE))
	var let_go_said: String = screen.said()
	screen.capture(_key(KEY_U))
	var pad_side: bool = screen.press_cell("Jump", Bindings.Device.PAD)
	var ignored: bool = not screen.capture(_key(KEY_U))
	screen.capture(_key(KEY_ESCAPE))
	print("[rebind] letting go       Escape taken %s, said '%s', jump still %s; a pad capture ignored a key %s (want yes, left as it was, G, yes)"
		% [let_go, let_go_said, one.call("jump"), pad_side and ignored])
	if not let_go or let_go_said != "left as it was" or one.call("jump") != "G" \
			or not (pad_side and ignored):
		problems.append("Escape did not let a capture go, or a pad capture took a key")

	# ─ 7. the defaults come back, and the file forgets ─
	screen.restore_defaults()
	await get_tree().process_frame
	var file := ConfigFile.new()
	file.load(Settings.PROBE_PATH)
	print("[rebind] defaults         interact %s, jump %s, attack %s, kept %d, the file's bindings %s (want E, Space, RT, 0, none)"
		% [one.call("interact"), one.call("jump"), pad_one.call("attack"),
			Settings.bindings.size(), file.has_section("bindings")])
	if one.call("interact") != "E" or one.call("jump") != "Space" \
			or pad_one.call("attack") != "RT" or not Settings.bindings.is_empty() \
			or file.has_section("bindings"):
		problems.append("the defaults did not all come back, or the file kept a binding")
	screen.queue_free()

	# ─ 8. a file from before rebinding reads as defaults, over what memory held ─
	Bindings.rebind("interact", _key(KEY_K))
	var old := ConfigFile.new()
	old.set_value("input", "mouse_sensitivity", 1.5)
	old.save(Settings.PROBE_PATH)
	Settings.read_again()
	print("[rebind] an older file    kept %d, interact %s, sensitivity %.1f (want 0, E, 1.5)"
		% [Settings.bindings.size(), one.call("interact"), Settings.mouse_sensitivity])
	if not Settings.bindings.is_empty() or one.call("interact") != "E" \
			or absf(Settings.mouse_sensitivity - 1.5) > 0.01:
		problems.append("a settings file from before rebinding did not read as the defaults")

	Settings.use_a_scratch_file()
	Settings.read_again()
	for problem: String in problems:
		printerr("[rebind] FAIL %s" % problem)
	print("[rebind] every verb can be moved on both devices, and moving one never strands another")
	get_tree().quit(1 if problems.size() > 0 else 0)


func _controls_probe() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var covered: PackedStringArray = ControlsScreen.covered()

	# The guard. Everything below compares two sets, and two empty sets agree
	# perfectly — so the row that says they match has to know they are not both
	# empty first.
	if covered.is_empty():
		problems.append("the control list teaches nothing at all")
		return problems

	var playable: PackedStringArray = PackedStringArray()
	for action: StringName in InputMap.get_actions():
		var name: String = String(action)
		if name.begins_with("ui_") or ControlsScreen.HIDDEN.has(name):
			continue
		playable.append(name)

	var untaught: PackedStringArray = PackedStringArray()
	for action: String in playable:
		if not covered.has(action):
			untaught.append(action)
	var invented: PackedStringArray = PackedStringArray()
	for action: String in covered:
		if not InputMap.has_action(action):
			invented.append(action)

	print("[controls] %d playable action(s), %d taught, %d hidden" % [
		playable.size(), covered.size(), ControlsScreen.HIDDEN.size()])
	if untaught.size() > 0:
		problems.append(("the input map has %d action(s) the control list never "
			+ "mentions (%s) — a tester cannot be expected to find a verb "
			+ "nothing told them about, and GATE M3 EXIT forbids telling them")
			% [untaught.size(), ", ".join(untaught)])
	if invented.size() > 0:
		problems.append(("the control list teaches %s, which is not in the input "
			+ "map — it names a key that does nothing") % ", ".join(invented))

	# Every taught action reaches both devices, asked through the screen rather
	# than through `BINDINGS`. ADR-075 is a rule about what a player can reach,
	# and the list is where the player finds out.
	var dashes: PackedStringArray = PackedStringArray()
	for action: String in covered:
		var one: PackedStringArray = PackedStringArray([action])
		if ControlsScreen.keyboard_glyphs(one).is_empty():
			dashes.append(action + " (keyboard)")
		if ControlsScreen.pad_glyphs(one).is_empty():
			dashes.append(action + " (pad)")
	if dashes.size() > 0:
		problems.append(("the control list would draw a dash for %s — an empty "
			+ "cell reads as *this verb has no binding on this device*, which "
			+ "ADR-075 says can never be true") % ", ".join(dashes))

	# **Reached from the menu, not merely constructible.** The composition
	# question, which every piece having its own check does not answer.
	#
	# The precondition is **set rather than assumed**, and the row asserts the
	# *change*. It did not, at first: the settings block above leaves its panel
	# mounted and `_column` already hidden, so `_column.visible == false` was
	# true before `_show_controls()` ran, and the plant that deletes the hide
	# passed. Caught by planting it — which is the whole argument for planting,
	# since the probe was reporting a green row about a screen it never opened
	# correctly.
	if _settings != null:
		_settings.closed.emit()
		await get_tree().process_frame
	_show_root()
	_column.visible = true
	_show_controls()
	await get_tree().process_frame
	var opened: bool = _controls != null and not _column.visible
	var glyphs: int = 0
	var fits: bool = true
	var measured := Vector2.ZERO
	if _controls != null:
		for node: Node in _controls.find_children("*", "Label", true, false):
			if not (node as Label).text.is_empty():
				glyphs += 1
		measured = ControlsScreen.configured_window()
		fits = _controls.fits()
		_controls.closed.emit()
		await get_tree().process_frame
	var shut: bool = _controls == null and _column.visible
	print("[controls] opened %s, %d label(s), closed %s" % [opened, glyphs, shut])
	if not opened:
		problems.append("CONTROLS did not open, or left the menu behind it "
			+ "visible through a 94%-opaque backdrop")
	if not shut:
		problems.append("BACK did not return to the menu — the list is a "
			+ "one-way door, which on the root screen means a relaunch")
	if glyphs < covered.size():
		problems.append(("the control list drew %d label(s) for %d taught "
			+ "action(s) — rows are being lost between the table and the screen")
			% [glyphs, covered.size()])
	if not fits:
		problems.append(("the control list is taller or wider than the %dx%d "
			+ "window it is drawn in, so the last thing on it — which is BACK — "
			+ "is off screen. Every row-level check above passes while this is "
			+ "true: *the rows exist* and *the rows are visible* are different "
			+ "claims") % [int(measured.x), int(measured.y)])

	return problems


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

	# **And the door itself**, last because it detaches this menu.
	#
	# `_enter()` is the only thing in the build that opens a profile (`M3-T06`),
	# and `run_coop.py` boots the Deep directly — so without this, the one line
	# joining the menu to the save is reached by nothing in the sweep. Every
	# piece of `M3-T06` has its own check and none of them is the composition,
	# which is the shape ADR-105, ADR-108 and ADR-110 all had.
	SaveFile.wipe()
	_enter()
	print("[menu] descend     profile opened, saving=%s" % GameState.saving())
	if not GameState.saving():
		problems.append(("pressing Descend did not open a profile — every part "
			+ "of the save works and nothing joins them, so a run would end and "
			+ "the hoard `DES-014` says is never wiped would go nowhere"))
	return problems


## **Can a life actually begin** (`M3-T02`, `DES-011`, ADR-120)?
##
## The screen, the oath and the body, asserted through the path a player takes
## rather than past it. `M2-T18` is why: the bag's rules were all correct and no
## click had ever reached them, so a check that calls `_commit` directly proves
## the same nothing.
func _class_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	# **Its own profile, never the players** (ADR-145). This wipes below, and it
	# was wiping a real lineage on every sweep.
	SaveFile.use_a_scratch_profile()
	if SaveFile.PATH == "user://profile.save":
		printerr("[class] FAIL this probe is pointed at the real profile and "
			+ "wipes below — every sweep would delete a player's lineage")
		get_tree().quit(1)
		return
	SaveFile.wipe()
	# **And its own run file** (ADR-152). This one is worse than ADR-145's two:
	# it does not merely call `RunFile`, it reaches past it — `DirAccess.remove`
	# on `RunFile.PATH` and a raw `FileAccess` write to the same path — so
	# ADR-138's arming discipline, which exists precisely to stop a probe
	# touching a player's run, could not see it. A suspended run was deleted on
	# every sweep, silently, and the file it deleted is the one ADR-138 was
	# written about.
	RunFile.use_a_scratch_run()
	if RunFile.PATH == "user://run.active":
		printerr("[class] FAIL this probe is pointed at the player's run file "
			+ "and deletes it below — a suspended run would be gone and "
			+ "nothing in the output would say so")
		get_tree().quit(1)
		return
	GameState.class_id = &""
	GameState.stash.clear()

	# ── the catalogue holds what is authored, and nothing else ───────────
	var sworn: Array[ClassResource] = ClassCatalogue.all()
	var names: Array[String] = []
	for entry: ClassResource in sworn:
		names.append(String(entry.id))
	print("[class] catalogue    %d authored: %s" % [sworn.size(), str(names)])
	if sworn.is_empty():
		problems.append(("no classes are in this build — an export whose class "
			+ "table comes back empty is a build in which no life can begin, "
			+ "which is ADR-086's silent packaging fault wearing a new hat"))
	for entry: ClassResource in sworn:
		for problem: String in entry.validate():
			problems.append("%s is malformed: %s" % [entry.id, problem])

	# ── the screen builds, has a rect, and its buttons reach the oath ────
	var screen := ClassScreen.new()
	var layer := CanvasLayer.new()
	layer.add_child(screen)
	add_child(layer)
	await get_tree().process_frame
	await get_tree().process_frame
	var rect: Vector2 = screen.size
	var buttons: int = screen.find_children("*", "Button", true, false).size()
	print("[class] the screen   %.0f x %.0f, %d button(s)" % [
		rect.x, rect.y, buttons])
	if rect.x <= 0.0 or rect.y <= 0.0:
		problems.append(("the class screen laid out at %.0f x %.0f — a `Control` "
			+ "under a `CanvasLayer` gets no layout unless it sets its own "
			+ "offsets, and at zero size Godot delivers it no mouse events at "
			+ "all (ADR-111). Nobody could pick a class with a mouse")
			% [rect.x, rect.y])
	if buttons != sworn.size():
		problems.append(("%d button(s) for %d authored class(es) — a class in "
			+ "the catalogue with no way to choose it is unreachable, and a "
			+ "button with no class behind it is the stub ADR-064 bans")
			% [buttons, sworn.size()])

	# ── pressing one swears the oath and stocks the kit ──────────────────
	var reached: bool = screen.press(&"huskarl")
	# **A frame, because the press is real** (`M3-T40`). `press` queues input
	# rather than emitting a signal inline, so `GameState` on the next line is
	# a frame behind the button and this row read the oath before it was sworn.
	for _frame: int in 4:
		await get_tree().process_frame
	print("[class] the oath     pressed=%s, sworn as '%s', stash %d" % [
		reached, GameState.class_id, GameState.stash.size()])
	if not reached:
		problems.append("the Húskarl's own button could not be found or pressed")
	if GameState.class_id != &"huskarl":
		problems.append(("pressing a class did not swear it — every part of this "
			+ "can work and leave the button joined to nothing, which is the "
			+ "shape ADR-105, ADR-108 and ADR-110 all had"))
	# **Only what has nowhere to be worn waits in the stash** (`M3-T07`).
	# This asserted `stash == kit.size()`, which was right until slots existed:
	# the kit is equipped now, so a Húskarl's seax and byrnie go to hands and
	# body and the stash is correctly empty. The claim that survives is that
	# nothing is *lost* — every kit entry is either worn or stashed, never
	# neither, which is the failure a first descent with empty hands would be.
	# And what the class carries rather than wears goes there too (ADR-238).
	var cargo: int = ClassCatalogue.by_id(&"huskarl").carried.size()
	for id: StringName in ClassCatalogue.by_id(&"huskarl").kit:
		var definition: ItemResource = ItemCatalogue.by_id(id)
		if definition != null and definition.slot == Enums.Slot.NONE:
			cargo += 1
	if GameState.stash.size() != cargo:
		problems.append(("swearing put %d item(s) in the stash and %d of the kit "
			+ "has no slot — a kit entry that is neither worn nor stashed has "
			+ "vanished between the oath and the descent")
			% [GameState.stash.size(), cargo])

	# ── and it cannot be taken back until you die (`DES-011`) ────────────
	# **A genuinely different class, now that one exists** (ADR-124).
	#
	# This swore `huskarl` twice, because when it was written the only other
	# name in `DES-011` was unauthored and the catalogue refused it — so the
	# lock was never consulted and the row passed for the wrong reason. The
	# comment saying so was left in place as a marker; `M3-T11` authored the
	# Veiðimaðr, and this is the test that comment was waiting for. Swearing
	# the same class twice is a weaker question: it cannot tell a lock from a
	# no-op.
	var swapped: bool = GameState.take_the_oath(&"veidimadr")
	print("[class] the lock     second oath accepted=%s, still '%s'" % [
		swapped, GameState.class_id])
	if swapped or GameState.class_id != &"huskarl":
		problems.append(("a class could be swapped mid-life — `DES-011` locks it "
			+ "until death, and that lock is what makes ADR-009's 'death is the "
			+ "door to a new class' a decision rather than a menu"))
	GameState.die()
	print("[class] after death  class '%s' (want empty)" % GameState.class_id)
	if GameState.class_id != &"":
		problems.append(("the class survived a death — `DES-003` puts it in the "
			+ "LIFE tier and ADR-009 makes death the door to a new one, which "
			+ "is a retention argument and not a tidiness one"))

	# ── the kit stocks the stash, but never twice (ADR-124) ──────────────
	#
	# A kit entry the body already *is* must not also be an object in the bag.
	# `Player._arm_from_kit` reads this same list and puts a bow in the hand,
	# so a stashed copy was three squares and 1.4 kg of inert duplicate — the
	# banned category of ADR-064 reached by accident. `M3-T07` collapses the
	# two representations into one when a slot decides what you hold; until
	# then, the hand wins and the bag does not get a second.
	GameState.take_the_oath(&"veidimadr")
	var stalker: ClassResource = ClassCatalogue.by_id(&"veidimadr")
	var stashed_bow: bool = false
	for held: ItemInstance in GameState.stash:
		if held.definition.has_trait(RangedTrait):
			stashed_bow = true
	var kit_bow: bool = false
	for id: StringName in stalker.kit:
		var definition: ItemResource = ItemCatalogue.by_id(id)
		if definition != null and definition.has_trait(RangedTrait):
			kit_bow = true
	print("[class] the kit      Veiðimaðr kit has a bow=%s, stash has one=%s (want yes/no)"
		% [kit_bow, stashed_bow])
	if not kit_bow:
		problems.append("the Veiðimaðr's kit names no ranged weapon, so the "
			+ "check below is about nothing — ADR-123 makes the kit what arms "
			+ "a class")
	if stashed_bow:
		problems.append(("swearing the Veiðimaðr put a bow in the stash as well "
			+ "as in their hands — one object with two representations, and the "
			+ "bag copy is inert, heavy and three squares wide"))

	# ── the body is shaped by the class, on the host's copy ──────────────
	# The **scene**, not `Player.new()`: the body is a tree of components and a
	# bare script instance has no `Health` to size. Instantiated the way
	# `CoopSession` does it, so what is measured is the body a session builds.
	var scene: PackedScene = preload("res://actors/player/player.tscn")
	var plain: Player = scene.instantiate() as Player
	var stout: Player = scene.instantiate() as Player
	stout.sworn = &"huskarl"
	add_child(plain)
	add_child(stout)
	await get_tree().process_frame
	print("[class] the body     health %.0f plain vs %.0f Húskarl" % [
		plain.health.maximum, stout.health.maximum])
	# **And the kit is on it** (`M3-T07`, `DES-020`). The oath stocks nothing a
	# body can hold; the body does that from the same list when it is built, so
	# this is the half of the claim the menu cannot see.
	var fist: ItemInstance = stout.equipment.in_slot(Enums.Slot.MAIN_HAND)
	var coat: ItemInstance = stout.equipment.in_slot(Enums.Slot.BODY)
	print("[class] the kit worn main hand '%s', body '%s'" % [
		fist.definition.id if fist != null else "",
		coat.definition.id if coat != null else ""])
	if fist == null or coat == null:
		problems.append(("a Húskarl was built holding '%s' and wearing '%s' — "
			+ "`DES-020` puts the kit in slots, and a body that arrives with "
			+ "empty hands cannot fight whatever the class resource says")
			% [fist.definition.id if fist != null else "nothing",
			coat.definition.id if coat != null else "nothing"])
	if stout.weapon.held() == null:
		problems.append("the main hand holds a weapon and `MeleeWeapon` was not "
			+ "told — the slot is set and the thing that swings does not know")
	if stout.health.maximum <= plain.health.maximum:
		problems.append(("a Húskarl's body is no sturdier than a classless one "
			+ "(%.0f vs %.0f) — the class is being read from `GameState` rather "
			+ "than from the spawn payload, so in co-op the host would build "
			+ "three of four bodies wrong")
			% [stout.health.maximum, plain.health.maximum])

	# ── an empty hand says so, and a full one does not ──────────────────
	#
	# **The row that would have caught the report** (ADR-140). Swinging with
	# nothing wielded returned `false` and did nothing else — no sound, no
	# motion, no refusal — so the first play of the build described a working
	# game as *"no weapon"*, and it was right to. A dead button is not an absent
	# feature; it is one that lies.
	#
	# Both directions, because a refusal that fires for everybody is a weapon
	# nobody can swing. The two bodies here are exactly the pair: `plain` has
	# never sworn and holds nothing, `stout` is a Húskarl with the seax its kit
	# put in its hand.
	# **Arrays, not ints.** A GDScript lambda captures a local by *value*, so
	# `func(): count += 1` increments a copy and the outer variable stays zero —
	# which reported the refusal as never firing when it was firing correctly.
	# `--toll-probe`'s `shrugs` array is here for the same reason.
	var empty_cries: Array[int] = []
	var armed_cries: Array[int] = []
	plain.weapon.swing_refused.connect(func() -> void: empty_cries.append(1))
	stout.weapon.swing_refused.connect(func() -> void: armed_cries.append(1))
	var empty_swung: bool = plain.weapon.request_swing(plain.stamina)
	var armed_swung: bool = stout.weapon.request_swing(stout.stamina)
	print("[class] empty hand   swung=%s refused=%d | armed swung=%s refused=%d"
		% [empty_swung, empty_cries.size(), armed_swung, armed_cries.size()])
	if empty_swung:
		problems.append("a body with nothing in its hand swung anyway")
	if empty_cries.size() != 1:
		problems.append(("an empty-handed attack said nothing (%d cue(s)) — it "
			+ "returns false and stops, which reads as a broken build rather "
			+ "than as empty hands, and principle 4 has no sentence for it")
			% empty_cries.size())
	if not armed_swung:
		problems.append("a Húskarl holding a seax could not swing it")
	if armed_cries.size() != 0:
		problems.append(("a weapon in hand refused as well (%d cue(s)), so the "
			+ "refusal is not about empty hands and fires on every attack")
			% armed_cries.size())

	# **It says so again later, and not every frame.**
	#
	# Both halves, because they fail in opposite directions and each looks like
	# the other's fix. Without the gap, attack held down under pressure is a
	# rattle nobody reads as a refusal; without the tick, the cue fires once per
	# life and then goes silent — which is the silence it was built to replace.
	# Planting a cooldown that never ticks went **uncaught** against a probe
	# that pressed the button once, and one press cannot tell a debounce from a
	# dead one.
	var gap: float = Config.tuning.empty_hand_gap
	plain.weapon.request_swing(plain.stamina)
	var during: int = empty_cries.size()
	plain.weapon.advance(gap * 0.5, plain.stamina)
	plain.weapon.request_swing(plain.stamina)
	var half_way: int = empty_cries.size()
	plain.weapon.advance(gap, plain.stamina)
	plain.weapon.request_swing(plain.stamina)
	var after: int = empty_cries.size()
	print("[class] the gap      %d cue(s) → %d at half a gap → %d after one"
		% [during, half_way, after])
	if half_way != during:
		problems.append(("an empty hand complained twice inside one gap — "
			+ "attack is held down under pressure, and a cue on every frame is "
			+ "a rattle rather than a refusal"))
	if after <= half_way:
		problems.append(("the refusal never came back (%d cue(s) after a full "
			+ "gap) — it fires once per life and then goes quiet, which is the "
			+ "silence it exists to replace") % after)

	# ── what the body wears weighs, and the class sizes what it can bear ──
	#
	# **ADR-224.** Only the bag was weighed, so the Húskarl's 11 kg byrnie cost
	# nothing on their back and jingled for nobody; and `carry_scale` and
	# `stamina_scale` were validated at boot and read by nothing. The expected
	# numbers come from the **class resources and the kit's definitions**, not
	# from `Equipment`, so a sum that forgot a slot cannot agree with itself.
	var fleet: Player = scene.instantiate() as Player
	fleet.sworn = &"veidimadr"
	add_child(fleet)
	await get_tree().process_frame
	var tuning: TuningProfile = Config.tuning
	var husk_class: ClassResource = ClassCatalogue.by_id(&"huskarl")
	var kit_kilograms: float = 0.0
	var kit_noise: float = 0.0
	for id: StringName in husk_class.kit:
		var kit_item: ItemResource = ItemCatalogue.by_id(id)
		if kit_item != null and kit_item.slot != Enums.Slot.NONE:
			kit_kilograms += kit_item.weight
			kit_noise += kit_item.clamor
	print("[class] the load     Húskarl kit worn %.1f kg, body carries %.1f kg; "
		% [kit_kilograms, stout.carried.kilograms]
		+ "classless body %.1f kg" % plain.carried.kilograms)
	if kit_kilograms <= 0.0 or absf(stout.carried.kilograms - kit_kilograms) > 0.01:
		problems.append(("a Húskarl wearing %.1f kg of kit carries %.1f kg — what "
			+ "is worn and held is not being weighed, so the byrnie `DES-023` "
			+ "calls heavy costs nothing on the body") % [kit_kilograms,
			stout.carried.kilograms])
	var want_floor: float = kit_noise * tuning.clamor_carried_fraction
	print("[class] the jingle   standing floor %.2f, the kit's clamor wants %.2f"
		% [stout.clamor.carried_floor, want_floor])
	if kit_noise <= 0.0 or absf(stout.clamor.carried_floor - want_floor) > 0.001:
		problems.append(("a Húskarl in a byrnie stands at a clamor floor of %.2f, "
			+ "not %.2f — worn gear is silent, and a jingling coat is a word")
			% [stout.clamor.carried_floor, want_floor])
	var stalker_class: ClassResource = ClassCatalogue.by_id(&"veidimadr")
	print("[class] the bearing  capacity %.0f classless · %.0f Húskarl · %.0f Veiðimaðr"
		% [plain.carried.capacity(), stout.carried.capacity(), fleet.carried.capacity()])
	for pair: Array in [[stout, husk_class], [fleet, stalker_class]]:
		var bearer: Player = pair[0] as Player
		var sworn_as: ClassResource = pair[1] as ClassResource
		var want_capacity: float = tuning.carry_capacity * sworn_as.carry_scale
		if is_equal_approx(sworn_as.carry_scale, 1.0) \
				or absf(bearer.carried.capacity() - want_capacity) > 0.01:
			problems.append(("a %s bears %.0f kg, not %.0f — `carry_scale` %.2f "
				+ "is authored and not read (or is 1.0, and this row proves nothing)")
				% [sworn_as.id, bearer.carried.capacity(), want_capacity,
				sworn_as.carry_scale])
		var want_stamina: float = tuning.stamina_max * sworn_as.stamina_scale
		if is_equal_approx(sworn_as.stamina_scale, 1.0) \
				or absf(bearer.stamina.maximum() - want_stamina) > 0.01:
			problems.append(("a %s has a %.0f stamina bar, not %.0f — "
				+ "`stamina_scale` %.2f is authored and not read")
				% [sworn_as.id, bearer.stamina.maximum(), want_stamina,
				sworn_as.stamina_scale])
	# Full, on the body that has done nothing yet. The Húskarl swung above and
	# is short by a swing, which is right; the Veiðimaðr has not moved, and a
	# bar grown after `Stamina._ready` filled it would start a tenth empty.
	print("[class] the wind     stamina %.0f classless · %.0f Húskarl · %.0f Veiðimaðr, "
		% [plain.stamina.maximum(), stout.stamina.maximum(), fleet.stamina.maximum()]
		+ "a fresh Veiðimaðr at %.0f" % fleet.stamina.current)
	if absf(fleet.stamina.current - fleet.stamina.maximum()) > 0.01:
		problems.append(("a Veiðimaðr who has done nothing starts at %.0f of %.0f "
			+ "stamina — the bar grew after it was filled")
			% [fleet.stamina.current, fleet.stamina.maximum()])
	# **Taking it off moves the weight; putting it down removes it.** Into the
	# bag it still weighs the same, and out of the bag it is gone — both, since
	# a load that ignored the swap and a load that double-counted it each pass
	# one half.
	var coat_kilograms: float = coat.definition.weight if coat != null else 0.0
	var dressed: float = stout.carried.kilograms
	stout.ask_to_unequip(Enums.Slot.BODY)
	var stowed: float = stout.carried.kilograms
	var in_bag: ItemInstance = null
	for held: ItemInstance in stout.inventory.items():
		if coat != null and held.definition == coat.definition:
			in_bag = held
	if in_bag != null:
		stout.inventory.remove(in_bag.instance_id)
	var shed: float = stout.carried.kilograms
	print("[class] taking off   %.1f kg worn → %.1f kg in the bag → %.1f kg set down"
		% [dressed, stowed, shed])
	if in_bag == null or absf(stowed - dressed) > 0.01 \
			or absf(dressed - shed - coat_kilograms) > 0.01:
		problems.append(("the byrnie's %.1f kg did not follow it: %.1f worn, %.1f "
			+ "stowed, %.1f set down") % [coat_kilograms, dressed, stowed, shed])

	# ── a body that put everything away is not handed the kit again ─────
	#
	# **ADR-228.** What is worn was written slot by slot for the slots in use,
	# so a Veiðimaðr who stowed the bow wrote an empty dictionary, and an empty
	# dictionary is what dresses the class kit — a second bow on the next floor,
	# with the first still in the bag. Stowed, then dressed again from what the
	# body reports wearing, which is what the next floor builds from.
	fleet.ask_to_unequip(Enums.Slot.MAIN_HAND)
	var reported: Dictionary = fleet.wearing.duplicate(true)
	fleet.wearing = reported
	var bows_held: int = 1 if fleet.equipment.in_slot(Enums.Slot.MAIN_HAND) != null else 0
	var bows_bagged: int = 0
	for carried_item: ItemInstance in fleet.inventory.items():
		if carried_item.definition.has_trait(RangedTrait):
			bows_bagged += 1
	print("[class] stowed bow   after a re-dress: %d in the hand, %d in the bag (want 0, 1); reports %d slot(s)"
		% [bows_held, bows_bagged, reported.size()])
	if bows_held != 0 or bows_bagged != 1:
		problems.append(("a Veiðimaðr who stowed the bow was dressed again with %d "
			+ "in the hand and %d in the bag — putting everything away read as "
			+ "never having dressed, and the kit is handed out again")
			% [bows_held, bows_bagged])

	plain.queue_free()
	stout.queue_free()
	fleet.queue_free()

	# ── and the Húskarl's verb (`M3-T02`, `DES-011`) ─────────────────────
	#
	# *"Plant and become an immovable object. Nothing pushes past you. Allies
	# can retreat through you."* The last sentence is a collision layer, and it
	# is the half that would break silently: a planted body on `WORLD` would
	# block the people it exists to protect and nothing would say so.
	var husk: Player = scene.instantiate() as Player
	husk.sworn = &"huskarl"
	add_child(husk)
	await get_tree().process_frame
	husk.planted = 1.0
	husk._apply_bulwark()
	var wall: int = husk.collision_layer
	print("[class] planted      layer %d, bulwark=%s, enemies mask it=%s" % [
		wall, (wall & CollisionLayers.BULWARK) != 0,
		(_enemy_mask() & CollisionLayers.BULWARK) != 0])
	if (wall & CollisionLayers.BULWARK) == 0:
		problems.append(("a planted Húskarl carries no bulwark layer, so nothing "
			+ "collides with them — *Hold* is the class's whole verb and this is "
			+ "the line that makes it exist"))
	if (_enemy_mask() & CollisionLayers.BULWARK) == 0:
		problems.append(("enemies do not mask the bulwark layer, so a planted "
			+ "Húskarl is a wall nothing walks into — the layer and the mask are "
			+ "two halves of one claim and either alone is silent"))
	if (_player_mask() & CollisionLayers.BULWARK) != 0:
		problems.append(("players mask the bulwark layer, so a planted Húskarl "
			+ "blocks their own party — `DES-011` says allies retreat *through* "
			+ "you, and this is the doorway becoming a trap for the people it "
			+ "was held for"))
	husk.planted = 0.0
	husk._apply_bulwark()
	if (husk.collision_layer & CollisionLayers.BULWARK) != 0:
		problems.append(("the bulwark layer outlived the plant — a Húskarl who "
			+ "walks away still blocking is a wall wandering the floor"))
	husk.queue_free()

	problems.append_array(_resume_rows())

	SaveFile.wipe()
	for problem: String in problems:
		printerr("[class] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


## **You cannot descend as nobody, and a sweep cannot open your run** (ADR-138).
##
## Here rather than in `--run-probe` because the subject is not the run file, it
## is the **decision the menu makes about one** — and that decision is what put
## a classless body on the floor.
func _resume_rows() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()

	# ── an unarmed process cannot *write* a run ──────────────────────────
	#
	# Two gates, and both are load-bearing. This one is why a sweep can no
	# longer leave a file in the player's `user://` at all; the next one is why
	# a sweep cannot read or delete one that is already there. Planting the
	# second without the first reported **NOT CAUGHT** — deleting the write gate
	# changed nothing visible, because the read gate was hiding the file the
	# write had just created. A guard whose failure another guard conceals is
	# not covered by a row about the other guard.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RunFile.PATH))
	RunFile.begin(&"huskarl", 1, 31346)
	var wrote_unarmed: bool = FileAccess.file_exists(RunFile.PATH)
	print("[class] unarmed write left a file=%s (want no)" % wrote_unarmed)
	if wrote_unarmed:
		problems.append(("an unarmed process opened a run — every probe in the "
			+ "sweep boots a level directly, and one that exits between "
			+ "`begin()` and `clear()` leaves a run open in the player's own "
			+ "`user://`. That is exactly what happened"))

	# ── and cannot see one that is already there ─────────────────────────
	#
	# Written with `FileAccess` rather than `RunFile.begin()`, because `begin()`
	# is exactly what the row above prevents — setting this up with it would be
	# asserting one guard by getting past the other.
	var planted := FileAccess.open(RunFile.PATH, FileAccess.WRITE)
	planted.store_string(JSON.stringify(
		{"version": RunFile.VERSION, "class_id": "huskarl", "rank": 1,
		"floor": 0, "seed": 31346,
		"carried": [], "hunt_age": 0.0, "stripped": false}))
	planted.close()
	var on_disk: bool = FileAccess.file_exists(RunFile.PATH)
	var seen_unarmed: bool = RunFile.exists()
	RunFile.arm()
	var seen_armed: bool = RunFile.exists()
	print("[class] the arming   on disk=%s, unarmed sees=%s, armed sees=%s" % [
		on_disk, seen_unarmed, seen_armed])
	if not on_disk:
		problems.append("the planted run file is not on disk, so the two rows "
			+ "below are about nothing")
	if seen_unarmed:
		problems.append(("an unarmed process can see a run file — every probe "
			+ "in the sweep boots a level directly, and one that exits between "
			+ "`begin()` and `clear()` then leaves a run open in the player's "
			+ "`user://`. That is what happened, and the next launch resumed it"))
	if not seen_armed:
		problems.append("arming did not make the run visible, so the guard "
			+ "refuses the player as well as the sweep")

	# ── a run that belongs to nobody is dropped, not entered ─────────────
	GameState.class_id = &""
	var orphan_resumed: bool = resume_is_this_life()
	var orphan_kept: bool = RunFile.exists()
	print("[class] the orphan   resumed=%s, still open=%s (want no/no)" % [
		orphan_resumed, orphan_kept])
	if orphan_resumed:
		problems.append(("a run opened by nobody was resumed — the life it "
			+ "describes does not exist, so the descent arrives with no class, "
			+ "no kit and an empty hand, and the attack button does nothing"))
	if orphan_kept:
		problems.append(("an unresumable run was left on disk, so it blocks "
			+ "every future descent — ADR-050 says there is no fresh run while "
			+ "one is open, and this one can never be finished"))

	# ── a run belonging to another life is dropped too ───────────────────
	RunFile.begin(&"veidimadr", 1, 31346)
	GameState.class_id = &"huskarl"
	var stranger_resumed: bool = resume_is_this_life()
	print("[class] another life resumed=%s (want no)" % stranger_resumed)
	if stranger_resumed:
		problems.append(("a Húskarl resumed a Veiðimaðr's run — the body is "
			+ "built from the profile and the floor from the run file, so this "
			+ "is a life playing somebody else's descent"))

	# ── and this life's own run is kept and entered ──────────────────────
	#
	# The row that stops all of the above being satisfied by *never* resuming,
	# which would close the escape ADR-050 exists to close by deleting the
	# feature.
	RunFile.begin(&"huskarl", 1, 31346)
	var mine_resumed: bool = resume_is_this_life()
	var mine_kept: bool = RunFile.exists()
	print("[class] my own run   resumed=%s, still open=%s (want yes/yes)" % [
		mine_resumed, mine_kept])
	if not mine_resumed:
		problems.append(("this life's own run was refused — quitting mid-run "
			+ "would then be a free escape from a bad one, which is the whole "
			+ "of ADR-050"))
	if not mine_kept:
		problems.append("resuming cleared the run file, so the next quit would "
			+ "find nothing to resume")

	RunFile.clear()
	GameState.class_id = &""

	# ── one question, asked in one place ────────────────────────────────
	#
	# Asserted as a **change** across the one fact that decides it, on the same
	# body of state. A row that only ever watched the refusal would be satisfied
	# by a menu that never asks anybody's class.
	GameState.last_life = {}
	var fresh_life: bool = menu_asks_the_class()
	GameState.last_life = {"class_id": "veidimadr", "worn": [], "stash": [],
		"taken": [], "rank": 1}
	var after_a_death: bool = menu_asks_the_class()
	GameState.last_life = {}
	print("[class] who asks     first life=%s, after a death=%s (want yes/no)"
		% [fresh_life, after_a_death])
	if not fresh_life:
		problems.append(("the menu never asks for a class, so a first life "
			+ "reaches the fire sworn to nothing and ADR-138's guard refuses "
			+ "the descent — a game that cannot be started"))
	if after_a_death:
		problems.append(("the menu asks for a class while a death is still "
			+ "unanswered — the Legacy screen asks the same question at the "
			+ "fire, so the player is asked twice for one life and the second "
			+ "answer is silently discarded by `take_the_oath`. The fire then "
			+ "opens a death screen on a life that has just begun"))

	return problems


## The masks the shipped scenes actually carry, read from the scenes rather
## than restated here. `check_project.py` asserts they match `CollisionLayers`;
## this asserts what they *mean* — that a planted body stops an enemy and not a
## friend. Two different questions, and the second one is the design's.
func _enemy_mask() -> int:
	var scene: PackedScene = preload("res://actors/enemies/enemy.tscn")
	var body: CharacterBody3D = scene.instantiate() as CharacterBody3D
	var mask: int = body.collision_mask
	body.free()
	return mask


func _player_mask() -> int:
	var scene: PackedScene = preload("res://actors/player/player.tscn")
	var body: CharacterBody3D = scene.instantiate() as CharacterBody3D
	var mask: int = body.collision_mask
	body.free()
	return mask
