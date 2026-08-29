class_name Threshold
extends Node3D

## The mouth of the mountain (`M2-T06`, `DES-014`, ADR-021).
##
## **The only space that replicates.** Where the Bound camp, where the Lodge
## keeps its fire, and where the Descent begins. Your Chamber is behind you and
## nobody else has ever been in it.
##
## The split earns its keep by *removing* a system rather than adding one:
##
## ```
## SOLO:    Chamber ──► Threshold ──► Descent
## CO-OP:   Chamber ──► Threshold ──► Descent
##                      └─ friends are standing here
## ```
##
## Identical flow. No mode switch, no different UI, no "clan Lair" versus "my
## Lair" — the only difference is whether anyone else is out here when you walk
## out. And because nothing is simulated in this space, it is nearly free to
## replicate: avatars, and that is all.
##
## ## The one thing it already says without saying anything
##
## The fire is the **Ashen Lodge's** fire (`DES-007`, ADR-020) — the people
## telling you to stop. So walking from the fire to the Descent is literally
## walking away from the light, and your friends are standing around the ones
## who want you to quit. Never stated, never pointed at. It is just where the
## door is.
##
## ## Deliberately almost empty (ADR-023)
##
## *"Thematically large and physically small."* What is absent is absent, not
## sketched: the contract board (`M4-T04`), the Forge and the Quartermaster
## (`M4`/`M5`), the staves (ADR-022), the four campsites, camp momentum
## (ADR-025), and the NPC Bound who remember you and die of the same disease
## you have (ADR-027, `M5`). `DES-010`'s onboarding wants the first visit to
## show **her and the Descent only** and the camp to fill in over the first
## hour — so a Threshold that is a fire and a doorway is not a placeholder for
## a bigger one. It is the first hour.

const GROUND: float = 34.0
const FIRE_AT: Vector3 = Vector3(0.0, 0.0, 0.0)
const DESCENT_AT: Vector3 = Vector3(0.0, 0.0, -9.0)
const CHAMBER_AT: Vector3 = Vector3(0.0, 0.0, 7.5)

const NIGHT: Color = Color(0.055, 0.06, 0.075)
const ROCK: Color = Color(0.19, 0.185, 0.19)
const FIRE_COLOUR: Color = Color(1.0, 0.62, 0.24)
## The Descent is a hole. It is the only thing here that is not lit.
const DESCENT_COLOUR: Color = Color(0.04, 0.04, 0.05)
const CHAMBER_DOOR: Color = Color(0.42, 0.40, 0.36)

const SESSION_SCENE: PackedScene = preload("res://systems/net/coop_session.tscn")
## The Legacy screen's claim on the body (ADR-146). Named, so the pause
## menu opening and closing over the top of it cannot give the player back
## to a world this screen is still standing in front of.
const LEGACY_CLAIM: StringName = &"legacy"
const SPAWNS: Array[Vector3] = [
	Vector3(-1.6, 0.1, 3.2), Vector3(1.6, 0.1, 3.2),
	Vector3(-3.4, 0.1, 4.0), Vector3(3.4, 0.1, 4.0),
]

var _session: CoopSession = null
var _readout: Label = null
## Set by any `--…probe` or `--…shot` argument. Its one job is to stop
## `_descend` changing scene, so a check about the descent can survive it.
var _probing: bool = false


## True once the descent is under way, so a body standing in the hole does not
## ask again every frame while the scene is still changing.
var _descending: bool = false


func _ready() -> void:
	# The only safe sound in the game (`M2-T09`, `ART-002`). Declared before
	# anything is built, so the first frame here already sounds like here.
	AudioDirector.enter("threshold")
	_build_ground()
	_build_fire()
	_build_doors()
	_spawn_actors()
	_build_readout()
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	hud.add_child(Reticle.new())
	add_child(PauseMenu.new())
	_face_what_happened()
	# **A probe must be able to watch the descent without taking it** (ADR-138).
	# `_descend` is `call_local` and ends in `change_scene_to_file`, so a body
	# that reaches the hole destroys whatever was watching it — and the two
	# plants for *"a life sworn to nothing walked into the hole"* both passed
	# **silently** for that reason: the failure deleted its own witness, the
	# Deep came up with no probe flag, and the run exited zero.
	#
	# `room_set` has had this exact swap since `M2` and says why in as many
	# words. Same rule, same word, stated where the second scene needs it.
	#
	# **`--doorway-probe` is the exception, and it has to be.** Its whole
	# subject is the transition — it asserts the host keeps its connection
	# through the door and the client follows it down — so holding the scene
	# makes it fail by definition. It did, immediately: *"built a new session"*
	# and *"did not follow"*. `room_set` learned the same thing about
	# `--extraction` and dodged it by keeping "probe" out of the name; naming
	# the exception is the clearer half of that lesson, because the rule then
	# survives somebody renaming a flag.
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--doorway-probe":
			continue
		if arg.contains("probe") or arg.contains("shot"):
			_probing = true
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--threshold-shot="):
			_threshold_shot(arg.split("=", true, 1)[1])
		elif arg == "--threshold-probe":
			_threshold_probe()
		elif arg == "--doorway-probe":
			_doorway_probe()
		elif arg == "--chamber-probe":
			_chamber_probe()
		elif arg == "--extraction" or arg == "--abandoned":
			# One arrival reporter, two scenarios (`M3-T35`). Both are asking
			# the same question — did this peer's run resolve, and did its run
			# file close with it — and they differ only in what ended the run.
			_arrived_from_the_deep()
		elif arg == "--edges-probe":
			_edges_probe()
		elif arg == "--again":
			_again()


## **The three ways a run can end up somewhere it cannot come back from**
## (`M2-T15`, ADR-107).
##
## All three were found by one playtester doing one ordinary thing: walking off
## the edge of the camp, letting the fall run, abandoning, and descending again
## to a grey screen. Nothing in this project asked any of these questions,
## because every existing probe measures a system doing its job rather than a
## player leaving the rails.
func _edges_probe() -> void:
	var problems := PackedStringArray()
	await get_tree().create_timer(1.0).timeout
	var body: Player = _session.local_player()
	if body == null:
		_report_edges(PackedStringArray(["no body at all on arrival — the "
			+ "session built nothing to play"]))
		return

	# ─ 1. falling out of the world puts you back ─
	#
	# `global_position` directly, **not `teleport`**: teleporting is a
	# deliberate relocation and it updates the ground of record, so using it to
	# simulate a fall moves the safety net down with the body and the recovery
	# correctly declines to fire. The first draft of this probe did exactly
	# that and reported a failure the game did not have.
	var began: Vector3 = body.global_position
	body.global_position = began + Vector3(0.0, -400.0, 0.0)
	await get_tree().create_timer(1.2).timeout
	var height: float = body.global_position.y
	print("[edges] after a 400 m drop      y %.1f" % height)
	if height < began.y - Player.VOID_DROP:
		problems.append(("a body 400 m below the floor was still down there "
			+ "at y %.1f — there is no way back into the level") % height)

	# ─ 2. the offline peer survives abandoning a run ─
	#
	# The abandon path itself is not run here: it changes scene, which would
	# end the probe. What is asserted is the property that path depends on —
	# that a session with no peer at all builds one — because that is the
	# thing whose absence produced the grey screen.
	# The scene, not `CoopSession.new()` — the class alone has no `Actors` or
	# `Spawner` children and falls over in `_ready` before reaching anything
	# worth testing.
	multiplayer.multiplayer_peer = null
	var rebuilt := SESSION_SCENE.instantiate() as CoopSession
	rebuilt.name = "RebuiltSession"
	add_child(rebuilt)
	await get_tree().process_frame
	var peered: bool = multiplayer.multiplayer_peer != null
	var hosting: bool = peered and multiplayer.is_server()
	print("[edges] session with no peer    %s" % [
		"installed one, is_server=%s" % hosting if peered else "LEFT IT NULL"])
	if not hosting:
		problems.append("a session starting with no peer did not install the "
			+ "offline one — `spawn_player` refuses at its first line when "
			+ "`is_server()` is false, so no body is ever built and the level "
			+ "comes up as a grey screen")
	rebuilt.queue_free()
	await get_tree().process_frame

	# ─ 3. your own Chamber is somewhere you can stand ─
	#
	# The room is an overlay 2000 m below the camp, and the body it builds is
	# assigned a `position` rather than teleported — so it began life measuring
	# itself against a `_last_solid` of `Vector3.ZERO`, read a 2000 m fall on
	# its first physics frame, and was returned to the camp that had just been
	# hidden. Standing at the origin with the door, the pile and the whole room
	# two kilometres below: nothing to see, nothing to walk to, no way out but
	# ABANDON.
	#
	# **Walked onto rather than opened by hand.** `_process` owns the trigger,
	# and a probe that called `_open_the_chamber()` itself would be testing the
	# function instead of the doorway.
	body.teleport(CHAMBER_AT, 0.0)
	await get_tree().create_timer(0.6).timeout
	var room := get_tree().root.get_node_or_null(CHAMBER_NODE) as Chamber
	if room == null:
		# Appended rather than reported on its own: an early exit that replaces
		# the list throws away everything found above it, and the finding it
		# discards is usually the more precise one.
		problems.append("walking onto the pale slab did not open the Chamber "
			+ "— nothing below this could be checked")
		_report_edges(problems)
		return
	var inside: Player = room.get_node_or_null("chamber_body") as Player
	if inside == null:
		# **Report and stop.** A GDScript runtime error aborts the function it
		# happens in, so a null dereference below would never reach the report
		# at the bottom and the run would hang until `--quit-after` killed it,
		# printing nothing — which is the one thing a check must never do.
		problems.append("the Chamber opened with no body in it — there is "
			+ "nobody to be in your own hoard room")
		_report_edges(problems)
		return
	var to_door: float = inside.global_position.distance_to(
		room.global_position + Chamber.DOOR_AT)
	print("[edges] in the chamber body %.0f m from the door, %.0f m from the pile" % [
		to_door, inside.global_position.distance_to(
			room.global_position + Chamber.HOARD_AT)])
	if to_door > CHAMBER_REACH:
		problems.append(("the body in the Chamber is %.0f m from its own door "
			+ "— it was put in the room and then thrown out of it, so the "
			+ "hoard, the stash and the way back are all unreachable and the "
			+ "screen is empty") % to_door)

	# ─ 4. and the camp is still a camp when you come back ─
	#
	# Leaving used to free the room and clear the island and leave
	# `set_process(false)` exactly where `_open_the_chamber` put it, so the
	# camp came back switched off: no Descent trigger, no Chamber trigger, no
	# re-arm, and a readout frozen on what it said before you went in. Going
	# back in is the assertion because it is a thing a player does, and because
	# every branch of `_process` — the Descent first among them — is dead or
	# alive together.
	await _walk_out_of_the_chamber(room, inside)
	var out: Player = _session.local_player()
	print("[edges] back outside  camp processing=%s, body=%s, readout %s" % [
		is_processing(), "yes" if out != null else "NO",
		"live" if _readout.text != "" else "EMPTY"])
	if out == null:
		problems.append("nobody came back out of the Chamber — the door "
			+ "despawns you and the way back never ran")
		_report_edges(problems)
		return
	if not is_processing():
		problems.append("the camp is not processing after a Chamber visit — "
			+ "the Descent trigger, the Chamber trigger and the readout all "
			+ "live in `_process`, so the only way on is ABANDON, which wipes "
			+ "the stash the visit existed to build")
	# The readout is written from `_process` too, and it froze on whatever it
	# said before the visit — so the stash count a player read after sorting
	# their haul was the one from before they sorted it. Moved by hand rather
	# than compared to itself: two identical camps produce identical text, and
	# an assertion that passes when nothing has happened is not an assertion.
	var before: String = _readout.text
	GameState.descents += 1
	await get_tree().create_timer(0.3).timeout
	if _readout.text == before:
		problems.append("the camp readout is frozen after a Chamber visit — it "
			+ "is written from `_process`, so it reports the stash you had "
			+ "before you sorted it")

	# Far enough away to re-arm, then back on, exactly as walking does it.
	out.teleport(FIRE_AT, 0.0)
	await get_tree().create_timer(0.4).timeout
	out.teleport(CHAMBER_AT, 0.0)
	await get_tree().create_timer(0.6).timeout
	var again := get_tree().root.get_node_or_null(CHAMBER_NODE) as Chamber
	print("[edges] second visit  door opened again=%s, readout live=%s" % [
		"yes" if again != null else "NO", _readout.text != before])
	if again == null:
		problems.append("the Chamber door opens once per level — a player who "
			+ "walks out of their own room can never walk back into it")
	else:
		await _walk_out_of_the_chamber(again,
			again.get_node_or_null("chamber_body") as Player)

	# ─ 4b. **a camp that has lost its body says so** (`M3-T39`, ADR-161) ─
	#
	# Every trigger here hangs off finding `player_1`; when that lookup fails,
	# `_process` returns at its first line and the fire is dead while still
	# drawn. The reported symptom — *"I couldn't enter the dungeon again"* —
	# had no line anywhere in the log, which is what made it cost two sessions
	# to place. Taken away and given back, because the rows after this need one.
	_said_it_lost_the_body = false
	_session.despawn_player(multiplayer.get_unique_id())
	await get_tree().process_frame
	await get_tree().process_frame
	var complained: bool = _said_it_lost_the_body
	_session.spawn_player(multiplayer.get_unique_id(), FIRE_AT)
	await get_tree().process_frame
	print("[edges] blind camp   said so=%s, body back=%s" % [
		complained, _session.local_player() != null])
	if not complained:
		problems.append(("the camp lost the body it is standing next to and "
			+ "said nothing — the Descent, the Chamber and the readout are all "
			+ "dead, the player can still walk around, and there is nothing in "
			+ "the log to tell that apart from somebody who never found the "
			+ "hole"))
	if _session.local_player() == null:
		problems.append("the body did not come back, so every row below this "
			+ "is about a camp with nobody in it")

	# ─ 5. nobody descends as nobody ─
	#
	# **Before the teardown below, not after.** Row 6 calls `_exit_tree()` and
	# frees the body, so anything asking a question about that body has to have
	# asked it already — placed last, this failed with *"the Object-derived
	# class of argument 1 (previously freed)"*, which is the probe holding a
	# corpse rather than a finding.
	problems.append_array(await _sworn_to_nothing())
	problems.append_array(_the_descent_opens_a_run())

	# ─ 6. the Chamber does not outlive the level that made it ─
	_open_the_chamber()
	await get_tree().process_frame
	var opened: bool = get_tree().root.get_node_or_null(CHAMBER_NODE) != null
	_exit_tree()
	await get_tree().process_frame
	var lingering: Node = get_tree().root.get_node_or_null(CHAMBER_NODE)
	print("[edges] chamber opened=%s, left behind=%s" % [
		"yes" if opened else "NO", "YES" if lingering != null else "no"])
	if not opened:
		problems.append("the Chamber never opened, so this proves nothing "
			+ "about whether it is cleaned up")
	elif lingering != null:
		problems.append("the Chamber is still parented to the root after its "
			+ "level left — it is a sibling, so a scene change does not take "
			+ "it, and its private MultiplayerAPI stays registered too")

	_report_edges(problems)


## **Nobody descends as nobody** (ADR-138), asked in the room where it matters.
##
## `MainMenu` refuses to *open* a run for a classless life; this refuses to send
## a classless *body* down. Not a second copy of one rule — `M2-T15` proved a
## level can be reached without passing through the menu, and the two are asked
## at different moments about different things.
##
## Asserted as a **change**: the same body, at the same spot, refused and then
## accepted with nothing between the two but an oath. A row that only ever
## watched the refusal would be satisfied by a Threshold nobody can leave.
func _sworn_to_nothing() -> PackedStringArray:
	var problems := PackedStringArray()
	# **Asked for fresh, not handed down.** The Chamber rows above walk a body
	# in and out of a room that frees and respawns it, so the reference this
	# function was originally given had been dead for two rows — Godot said so:
	# *"the Object-derived class of argument 1 (previously freed)"*, which is a
	# probe holding a corpse rather than a finding.
	var body: Player = _session.local_player()
	if body == null:
		return PackedStringArray(["no body to walk into the hole"])
	var was: StringName = GameState.class_id

	# **Only the refusal is walked.** The accepting half cannot be: `_descend`
	# is `call_local`, so a sworn body at the hole runs `change_scene_to_file`
	# and takes this probe with it (ADR-117 again). That direction is already
	# proved where it belongs — `--menu-probe`'s `_walk_the_loop` presses
	# Descend and asserts it arrives in the Deep. Here the predicate carries it,
	# which is enough to stop the refusal being a Threshold nobody can leave.
	GameState.class_id = &""
	_descending = false
	_said_it_cannot_go = false
	body.teleport(DESCENT_AT, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var walked_in: bool = _descending
	var closed: bool = not may_descend()
	# **And it said so where a bug report can carry it** (`M3-T39`, ADR-161).
	# The readout is what the player reads and it goes nowhere afterwards; the
	# log is the half that survives into a report.
	print("[edges] the refusal  in the log=%s" % _said_it_cannot_go)
	if not _said_it_cannot_go:
		problems.append(("the hole refused a life sworn to nothing and only "
			+ "the readout said so — a refusal that leaves no trace is what "
			+ "made the reported fault take two sessions to place"))

	GameState.class_id = &"huskarl"
	var opens: bool = may_descend()

	# **And the party gate, which is a different question** (`M3-T37`,
	# ADR-158). The rows above are about the body walking in; these are about
	# whether the party may go, which is what a client with the Legacy screen
	# open used to have decided for it by somebody else's footsteps.
	#
	# Only the host's own half is reachable in one process — `still_choosing()`
	# reads `multiplayer.get_peers()`, and there are none — but that half is
	# the one solo depends on, and `run_doorway.py` walks the other with a real
	# second peer.
	_session.redeclare()
	var ready_when_sworn: int = _session.still_choosing()
	GameState.class_id = &""
	_session.redeclare()
	var waiting_when_not: int = _session.still_choosing()
	print("[edges] the party    still choosing: sworn=%d, unsworn=%d (want 0, 1)"
		% [ready_when_sworn, waiting_when_not])
	if ready_when_sworn != 0:
		problems.append(("a sworn party is counted as still choosing, so the "
			+ "hole would never open for anybody — a gate that never lets "
			+ "the party through is worse than the one it replaced"))
	if waiting_when_not != 1:
		problems.append(("a life sworn to nothing is not counted as still "
			+ "choosing, so the descent would take it down with no class, no "
			+ "kit and an empty hand — which is the fault this exists for"))

	# **And the person standing in the hole is told why nothing happened.**
	# The wording is the deliverable here: a hole that silently does nothing
	# reads as a broken trigger, which is the bug report this would otherwise
	# generate instead of the one it is preventing.
	var before_line: String = _readout.text if _readout != null else ""
	_still_at_the_fire(1)
	var said: bool = _readout != null and _readout.text != before_line \
		and _readout.text.contains("still at the fire")
	print("[edges] and it says  the hole explains itself=%s" % said)
	if not said:
		problems.append(("the hole refused and said nothing — a trigger that "
			+ "does nothing with no explanation is indistinguishable from a "
			+ "broken one, and principle 4 has no sentence for it"))

	GameState.class_id = was
	_session.redeclare()
	_descending = false
	print("[edges] the descent  classless walked in=%s, shut=%s, opens once sworn=%s"
		% [walked_in, closed, opens])
	if walked_in:
		problems.append(("a life sworn to nothing walked into the hole — it "
			+ "arrives with no kit, so an empty hand, and `request_swing` "
			+ "refuses on an empty hand: an attack button that does nothing, "
			+ "which principle 4 has no sentence for"))
	if not closed:
		problems.append("the descent is open to a life sworn to nothing")
	if not opens:
		problems.append(("the descent is shut to a sworn Húskarl as well, so "
			+ "the refusal above is a Threshold nobody can leave rather than "
			+ "a guard"))
	return problems


## **Going down opens a run** (ADR-143).
##
## `MainMenu` used to do this, and only on the route where a class was already
## sworn — the class screen changed scene without it. So a first life, and
## **every life after a death**, descended with no run file, and ADR-050's
## *quitting is never an escape* did not apply to the two cases a player meets
## first. Nothing could have caught it: no probe walked the class-select route,
## and a missing run file is indistinguishable from a finished run.
##
## **Armed here, on `--run-probe`'s precedent** (ADR-138), and pointed at a
## file that is nobody's (ADR-152). This one has to arm, because a run file that
## nothing writes is the fault being asserted — but *"it has to arm"* was read
## as *"it has to use the player's file"*, and it does not. It cleared a real
## suspended run on every sweep, silently, which is ADR-145's finding arriving
## for a third time in a third file. `arm()` now refuses this outright.
func _the_descent_opens_a_run() -> PackedStringArray:
	var problems := PackedStringArray()
	var was: StringName = GameState.class_id
	RunFile.use_a_scratch_run()
	RunFile.arm()
	RunFile.clear()

	GameState.class_id = &"huskarl"
	_descending = false
	# **The descent stops taking arrivals** (`M3-T36`, ADR-157), sampled either
	# side of the one call that moves it.
	#
	# **Only this half is here**, and the missing half is the point. A row
	# reading *the camp takes arrivals* was written first and **could not
	# fail**: the flag starts open, so deleting the camp's own call to
	# `the_party_is_at_the_fire()` changed nothing at boot and the row passed
	# green against it. What that call is actually load-bearing for is the way
	# **home** — a party that has descended has a shut door, and arriving at
	# the fire must open it again — which is a claim about a second visit and
	# belongs where a second visit happens. `run_doorway.py` asserts it on the
	# peers that walk back out of the Deep.
	_descend()
	var shut_below: bool = not CoopSession.taking_arrivals()
	print("[edges] the door      shut once down=%s (want yes)" % shut_below)
	if not shut_below:
		problems.append(("the descent did not shut the door — a peer that "
			+ "connects after it is a second process in a scene the host is "
			+ "not in, and Godot addresses every spawn by node path"))
	# Put it back, because the rows after this one are about a camp.
	CoopSession.the_party_is_at_the_fire()
	var opened: bool = RunFile.exists()
	var whose: String = String(RunFile.read().get("class_id", ""))
	print("[edges] the run      opened=%s, for '%s'" % [opened, whose])
	if not opened:
		problems.append(("walking into the hole opened no run — quitting from "
			+ "the floor would then cost nothing, which is the one escape "
			+ "ADR-050 exists to close"))
	elif whose != "huskarl":
		problems.append(("the run was opened for '%s' rather than for the life "
			+ "descending — ADR-138 reads that back to decide whether a run is "
			+ "resumable, and a mismatch drops it on the next launch") % whose)

	RunFile.clear()
	GameState.class_id = was
	set_process(true)
	return problems


## **May this life go down?** (ADR-138)
##
## A classless life has no kit, so it arrives with an empty bag and an empty
## hand, and `MeleeWeapon.request_swing` refuses on an empty hand — an attack
## button that does nothing at all, which principle 4 has no sentence for.
##
## `MainMenu` already refuses to *open* a run for one, and this is not a second
## copy of that rule: the menu decides whether a **run** may begin, this decides
## whether a **body** may go down, and `M2-T15` proved a level can be reached
## without passing through the menu at all.
func may_descend() -> bool:
	return GameState.class_id != &""


## Walk the body in the Chamber onto its own door, which is the only way out of
## that room a player has. Deliberately **not** `Chamber._leave()`: that is what
## `--chamber-probe` does on a four-second timer regardless of where the body is
## standing, and it is why every private-door row passed while the body it was
## asserting about was two kilometres from the door it was said to have used.
func _walk_out_of_the_chamber(room: Chamber, inside: Player) -> void:
	if room == null or inside == null:
		return
	inside.global_position = (room.global_position + Chamber.DOOR_AT
		+ Vector3(0.0, 0.1, 0.0))
	await get_tree().create_timer(0.6).timeout


func _report_edges(problems: PackedStringArray) -> void:
	for problem: String in problems:
		print("[edges] FAIL %s" % problem)
	if problems.size() == 0:
		print("[edges] the rails hold")
	get_tree().quit(1 if problems.size() > 0 else 0)


## Walk the party through the Descent on a timer (`run_doorway.py`).
##
## The host waits for company, then descends — which is the whole test, because
## the transition is what used to drop the connection. Nothing is asserted
## here; the harness reads both processes' logs, since the question is about
## what happened to *two* of them.
func _doorway_probe() -> void:
	await get_tree().create_timer(6.0).timeout
	if multiplayer.is_server():
		_ask_to_descend()


## The camp's own music, and the rules that hold across all three (`M2-T09`).
##
## `ART-002` and `ART-003` both single this piece out — *"the most important
## piece of music in the game"*, *"the only safe sound"* — and `TEC-005` names
## the adaptive driver the highest-risk audio tech in the project. `M2-T03`
## built the driver for the Deep. What was still unproven is that a *place* can
## have its own, which is what makes three sonic worlds three pieces rather
## than one piece with the lights dimmed.
##
## Five assertions, and two of them are rules rather than behaviours:
##
## 1. **The reserved instrument is used once.** `ART-003` states it as an
##    absolute — the Hunter's voice appears nowhere else, ever, *"not in the
##    Threshold, not as texture, not 'just once' somewhere atmospheric"* —
##    because the moment it is a false alarm it is worthless for the rest of
##    the game. A rule that depends on remembering it is a rule that will be
##    broken by whoever needs a nice sound late one night.
## 2. **Every place has its own piece**, and no two are the same table.
## 3. **Every piece has air.** Somewhere with no room tone is not a place.
## 4. **The Threshold is warm on arrival.** Safety that fades in over two
##    seconds each time you walk through the door is a worse lie than silence.
## 5. **The arrangement fills out as the camp does** (ADR-050) — the thing that
##    makes this a driver rather than a looping file.
func _threshold_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()

	# ─ **the way out of here** (`M3-T31`, ADR-152) ─
	#
	# First, and that ordering is the check rather than tidiness. Run after the
	# section below, every row read a life that had **already ended** — the
	# plant leaves `class_id` empty with nothing left to lose, and ADR-147's
	# guard then refuses the second `die()` — so all six rows passed without the
	# code being able to fail them. A row that could have passed before the code
	# ran is not a check.
	problems.append_array(_the_way_out())

	# ─ 0. **the fire asks about the death** (`M3-T05`, ADR-133) ─
	#
	# The composition row. `--legacy-probe` builds a `LegacyScreen` itself and
	# proves every rule inside it; **nothing proved the Threshold ever shows
	# one**, which is the shape ADR-105, ADR-108, ADR-110 and ADR-117 all had —
	# every piece checked and the join built by nobody. `check_dead.py` found it
	# as an orphaned accessor, which is the second time it has been the thing
	# that noticed (`ask_to_unequip`, ADR-127).
	print("[camp] no death yet  screen=%s (want none)" % (legacy_screen() != null))
	if legacy_screen() != null:
		problems.append("the Legacy screen is up with no life behind it — it "
			+ "would greet every arrival at the fire with a death that did not "
			+ "happen")
	GameState.last_life = {"class_id": "huskarl", "worn": [], "stash": [],
		"taken": [], "rank": 1}
	_face_what_happened()
	await get_tree().process_frame
	var shown: LegacyScreen = legacy_screen()
	print("[camp] a life ended  screen=%s" % (shown != null))
	if shown == null:
		problems.append("a life ended down there and the fire said nothing — "
			+ "`DES-003` puts the choice at the moment of death, and a screen "
			+ "nothing opens is a screen that does not exist")
	else:
		problems.append_array(await _screen_has_the_player(shown))
		problems.append_array(_screens_stack())

		# ─ **and the answer reaches the body** (ADR-148) ─
		#
		# Driven all the way through the class panel rather than by emitting
		# `finished`, because the fault is in the join: every rule inside the
		# screen was right, `take_the_oath` was right, and the body standing
		# three metres away was still `'nobody'`. The reporter's log named it —
		# `peer 1 descends at rank 1 as 'nobody'` — after **every** death.
		var before_body: Player = _session.local_player()
		var was: StringName = before_body.sworn if before_body != null else &"?"
		shown.advance()
		await get_tree().process_frame
		var picking: ClassScreen = null
		for node: Node in shown.find_children("*", "ClassScreen", true, false):
			picking = node as ClassScreen
		if picking == null or not picking.press(&"huskarl"):
			problems.append("the Legacy flow never reached a class to swear, so "
				+ "the rows below are about nothing")
		for _frame: int in 4:
			await get_tree().process_frame
		var now: Player = _session.local_player()
		print("[camp] sworn in      body '%s' -> '%s', life '%s'" % [
			was, now.sworn if now != null else &"none", GameState.class_id])
		if now == null:
			problems.append(("swearing a class at the fire left no body at all "
				+ "— `player_for` finds a body by node name and `queue_free` "
				+ "holds the name to the end of the frame, so a despawn and a "
				+ "spawn in one breath renames the new one out of reach"))
		elif now.sworn != GameState.class_id:
			problems.append(("the class was sworn and the body at the fire is "
				+ "still '%s' — no kit, nothing in its hand, plain health, "
				+ "until the next scene change builds a session that declares "
				+ "it. An empty hand refuses the swing, which is what ADR-141 "
				+ "was reported for") % now.sworn)

		await get_tree().process_frame
		print("[camp] and then asks   record=%s (want empty)"
			% (not GameState.last_life.is_empty()))
		if not GameState.last_life.is_empty():
			problems.append("the record outlived the choice, so the fire would "
				+ "ask about the same death every time you came back to it")
		var after: Player = _session.local_player() if _session != null else null
		if after != null and not after.driving():
			problems.append("the body never got the controls back after the "
				+ "screen closed, so answering the question costs you the run")

	# ─ 1. the reserved instrument ─
	var reserved: Array[String] = []
	for piece: String in AudioDirector.PIECES:
		var table: Dictionary = AudioDirector.PIECES[piece]
		for layer: String in table:
			var spec: Dictionary = table[layer]
			if String(spec["voice"]) == AudioDirector.RESERVED_VOICE:
				reserved.append("%s/%s" % [piece, layer])
	print("[camp] reserved     %s plays %s" % [
		AudioDirector.RESERVED_VOICE, ", ".join(reserved)])
	# Spelt out rather than compared against a literal array: `x != [y] as
	# Array[T]` binds the cast to the comparison, not the literal, and is a
	# parse error rather than the check you meant to write.
	if reserved.size() != 1 or reserved[0] != "deep/hunter":
		problems.append(("the %s voice is used by %s — ART-003 reserves it for "
			+ "the Hunter and nothing else, ever, so that hearing it is always "
			+ "true. A second user makes every first one a coin-flip")
			% [AudioDirector.RESERVED_VOICE, ", ".join(reserved)])

	# ─ 2 and 3. three places, three pieces, all of them rooms ─
	var seen: Array[String] = []
	for piece: String in AudioDirector.PIECES:
		var table: Dictionary = AudioDirector.PIECES[piece]
		var signature: String = ",".join(table.keys())
		var air: bool = false
		for layer: String in table:
			if String((table[layer] as Dictionary)["bus"]) == "ambience":
				air = true
		print("[camp] %-11s %d layer(s), %s" % [
			piece, table.size(), "has air" if air else "NO AIR"])
		if not air:
			problems.append(("%s has no ambience layer — ART-002 wants air and "
				+ "stone settling under everything, and a place with no room "
				+ "tone stops being a place the moment the score rests")
				% piece)
		if seen.has(signature):
			problems.append(("%s is scored by the same layers as another place "
				+ "— the three sonic worlds are three pieces, not one piece "
				+ "with the lights dimmed") % piece)
		seen.append(signature)

	# ─ 4. warm on arrival ─
	await _hold(AudioDirector.CROSSFADE + 0.6)
	var here: Dictionary = AudioDirector.layer_levels()
	print("[camp] on arrival  %s" % [_levels_line(here)])
	if AudioDirector.place() != "threshold":
		problems.append("standing in the Threshold and the director is playing "
			+ "'%s'" % AudioDirector.place())
	for named: String in ["hearth", "warmth", "theme"]:
		if float(here.get(named, AudioDirector.SILENCE_DB)) \
				<= AudioDirector.SILENCE_DB + 0.5:
			problems.append(("the Threshold's %s is silent on arrival — this is "
				+ "the only safe sound in the game and it is not something the "
				+ "player should have to wait out") % named)

	# ─ 5. a fuller camp, a fuller arrangement ─
	var lonely: float = float(here.get("company", AudioDirector.SILENCE_DB))
	GameState.descents += int(AudioDirector.CAMP_FULL_AT) + 1
	await _hold(AudioDirector.CROSSFADE + 0.6)
	var settled: float = float(AudioDirector.layer_levels().get(
		"company", AudioDirector.SILENCE_DB))
	print("[camp] company     %.1f dB at one descent → %.1f dB at %d" % [
		lonely, settled, GameState.descents])
	if settled <= lonely + 0.5:
		problems.append(("the arrangement did not fill out as the camp did — "
			+ "ADR-050 makes momentum audible as well as visible, and a camp "
			+ "that sounds the same on descent 1 and descent 8 is a looping "
			+ "file rather than a driver"))

	# ─ the fire teaches every verb, and teaches the same ones the screen does ─
	#
	# **The row that catches a second list going stale** (ADR-139). These three
	# lines were hand-typed, keyboard-only, and omitted `block` and `verb` —
	# two combat verbs a player at this fire could not learn existed. Nothing
	# could have failed over that: a hand-written list is always internally
	# consistent, and the only way to ask whether it is *complete* is to compare
	# it against the table the screen renders.
	await get_tree().process_frame
	var taught: PackedStringArray = ControlsScreen.compact_lines(4)
	var missing := PackedStringArray()
	for line: String in taught:
		if not _readout.text.contains(line):
			missing.append(line)
	var names_the_verb: bool = _readout.text.contains(
		ControlsScreen.glyphs_for("verb"))
	print("[camp] the controls %d line(s), %d missing, names the verb=%s" % [
		taught.size(), missing.size(), names_the_verb])
	if taught.is_empty():
		problems.append("the control table renders nothing, so the two rows "
			+ "below are about an empty string")
	if missing.size() > 0:
		problems.append(("the fire's readout is missing %d line(s) the control "
			+ "screen teaches (%s) — two lists again, and the hand-written one "
			+ "is always internally consistent right up until it is wrong")
			% [missing.size(), ", ".join(missing)])
	if not names_the_verb:
		problems.append(("the readout never names the class verb — it did not "
			+ "for the whole of `M3`, so `F` was a built verb with no way of "
			+ "being discovered, which is maintenance paid for nothing"))

	for problem: String in problems:
		printerr("[camp] FAIL %s" % problem)
	get_tree().quit(1 if problems.size() > 0 else 0)


func _levels_line(levels: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for name: String in levels:
		parts.append("%s %.0f" % [name, float(levels[name])])
	return "  ".join(parts)


func _hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _spawn_actors() -> void:
	_session = SESSION_SCENE.instantiate() as CoopSession
	_session.spawn_points = SPAWNS
	# **The fire takes arrivals** (`M3-T36`, ADR-157). Said before the session
	# enters the tree, because its `_ready` is what applies it to the transport.
	#
	# This is also the way *back* open: a party that comes home from a run that
	# resolved is assembling again, and the next person to knock should be let
	# in. Stated here rather than in `_take_the_outcome` because arriving at the
	# camp is the one thing every route home has in common.
	CoopSession.the_party_is_at_the_fire()
	add_child(_session)


## **A camp that has lost its body says so, once** (`M3-T39`, ADR-161).
##
## Every trigger at the fire — the Descent, the Chamber, the readout — hangs off
## finding `player_1` under the session. When that lookup fails this function
## returns at its first line and the camp is **dead while still drawn**: the
## body is there, the player can walk and look, and nothing they walk into
## does anything. Reported as *"I couldn't enter the dungeon again"*, with a
## log that simply stopped — which is the worst shape a fault can have, because
## it is indistinguishable from a player who did not find the hole.
##
## Once, not per frame: sixty lines a second is not a diagnosis, it is a reason
## nobody reads the log.
var _said_it_lost_the_body: bool = false
## The same, for a life with no class standing in the hole.
var _said_it_cannot_go: bool = false


func _process(_delta: float) -> void:
	var player: Player = _session.local_player() if _session != null else null
	if player == null:
		if not _said_it_lost_the_body:
			_said_it_lost_the_body = true
			push_error(("Threshold: the camp cannot find the body it is "
				+ "standing next to (peer %d). The Descent, the Chamber and "
				+ "the readout are all dead until it can.")
				% multiplayer.get_unique_id())
		return
	_said_it_lost_the_body = false
	if _readout != null:
		_readout.text = "\n".join([
			"THE THRESHOLD    descent %d" % GameState.descents,
			"",
			"stash      %d item(s), %d tribute" % [
				GameState.stash.size(), GameState.stash_value()],
			"the hoard  %d" % GameState.hoard_value,
			"",
			# Who is actually here. The host presses OPEN THE THRESHOLD and then
			# has no way to tell whether anybody arrived — and descending alone
			# by accident is a wasted run and a confusing bug report.
			"party      %d of %d%s" % [
				_session.players().size(), Player.MAX_PARTY,
				"" if multiplayer.get_peers().size() > 0 or not _session.is_host()
					else "   (nobody has joined yet)"],
			"",
			"the fire behind you is the Lodge's",
			"walk into the dark ahead to descend",
			"walk back onto the pale slab for your Chamber",
			"",
			# The Deep lists these and the camp did not, so the first time a
			# tester needed them was the first time they were under pressure.
			# `M2-T13`: attack, throw and the waystone were on no list anywhere
			# in the game. A verb a tester cannot discover is worse than one
			# that does not exist — it is maintenance paid for nothing, and it
			# makes every report about the run describe a smaller game than the
			# one that was built. The throw is the Hunt's counter-play and the
			# waystone is half of `DES-005`'s way out.
			#
			# **Generated now, not typed** (ADR-139). These three lines were
			# hand-written, keyboard-only, and omitted **block** and **the class
			# verb** — two combat verbs a player at this fire could not learn
			# existed. `ControlsScreen` is the one table; this is one rendering
			# of it, and a verb added there appears here without anybody
			# remembering to come back.
		] + Array(ControlsScreen.compact_lines(4)) + [
			"esc menu, and the full list of controls with it",
		])
	# **Nobody descends as nobody** (ADR-138). The last gate before the floor,
	# and the only one standing in the room where the mistake becomes visible:
	# a classless life has no kit, so it arrives with an empty bag and an empty
	# hand, and `MeleeWeapon.request_swing` refuses on an empty hand — an attack
	# button that does nothing, which principle 4 has no sentence for.
	#
	# `MainMenu` already refuses to start one and this is not a second copy of
	# that rule: the menu decides whether a *run* may open, and this decides
	# whether a *body* may go down. `M2-T15` proved a level can be reached
	# without passing through the menu at all.
	if player.global_position.distance_to(DESCENT_AT) <= 2.0:
		if may_descend():
			_ask_to_descend()
		else:
			# **Said on the screen and in the log** (`M3-T39`, ADR-161). The
			# readout is what the player reads; the log is what a bug report
			# carries, and the reported fault was a refusal that appeared in
			# neither. Once, like the blindness above.
			if not _said_it_cannot_go:
				_said_it_cannot_go = true
				print("[camp] the hole refuses — this life has sworn to nothing")
			if _readout != null:
				_readout.text += ("\n\nyou have sworn to nothing — there is "
					+ "no one here to go down")
	elif (_chamber_armed
			and player.global_position.distance_to(CHAMBER_AT) <= 1.8):
		_open_the_chamber()
	elif player.global_position.distance_to(CHAMBER_AT) > 3.0:
		# Stepped clear of the slab, so the door will take you again. Without
		# this a player who came back out would be standing close enough to
		# re-enter on the very next frame, forever.
		_chamber_armed = true


## **The party descends together, or the party is not a party.**
##
## Each peer used to change scene the moment its own body reached the hole, so
## in company one player would drop into the Deep while everybody else stood at
## the fire looking at a world nobody was simulating for them. `DES-012` has
## you go down *together* — that is the whole shape of a run.
##
## So the hole is the host's decision. Anyone can walk into it; the host is
## told, and the host takes everyone.
func _ask_to_descend() -> void:
	if _descending:
		return
	_descending = true
	if multiplayer.is_server():
		_take_the_party_down(CoopSession.HOST_PEER)
	else:
		_ask_host_to_descend.rpc_id(CoopSession.HOST_PEER)


@rpc("any_peer", "reliable")
func _ask_host_to_descend() -> void:
	if not multiplayer.is_server():
		return
	_take_the_party_down(multiplayer.get_remote_sender_id())


## **Nobody is taken down in the middle of answering a question** (`M3-T37`,
## ADR-158).
##
## ADR-101 made the hole the host's decision, so that the party arrives
## together — right, and it asked nobody whether they were ready. `_descend` is
## `call_local` on an authority RPC, so a client with the **Legacy screen open**
## ran it too: `RunFile.begin()` with an empty `class_id`, a scene change out
## from under a screen it had not answered, and `declare_descent` sending `""`
## — so the host built it a body with no class, therefore no kit, therefore an
## empty hand, and `MeleeWeapon.request_swing` refuses on an empty hand.
##
## That is exactly the fault ADR-138 and ADR-148 were written about, reached
## through a door neither closed: both fixed the *menu* and the *fire*, and
## neither could see a client's class question being answered for it by
## somebody else's footsteps. It is the ordinary state of any client at the
## fire after any death (`DES-003` lets them take as long as they like), so it
## is not an edge case — it is the second co-op run in every session.
##
## **The host already knew.** `declare_descent` has carried the class since
## `M3-T02`, and a peer that has not chosen declares `""`. No new message, no
## readiness protocol: the gate is a question asked of data that was already
## crossing.
func _take_the_party_down(asked_by: int) -> void:
	var waiting: int = _session.still_choosing()
	if waiting == 0:
		_descend.rpc()
		return
	# **Let them try again.** `_descending` latches so a body standing in the
	# hole does not ask every frame while the scene changes; a refusal is not a
	# descent, so it has to come back off or the hole is dead for the rest of
	# the visit.
	_descending = false
	print("[camp] the descent waits — %d of the party still at the fire"
		% waiting)
	if asked_by == CoopSession.HOST_PEER:
		_still_at_the_fire(waiting)
	else:
		_still_at_the_fire.rpc_id(asked_by, waiting)


## Told to whoever walked in, because they are the one standing in a hole that
## did nothing. Both peers are in the Threshold — the paths agree — which is
## the whole reason this can be said at all (ADR-157 is the case where they do
## not).
@rpc("authority", "reliable")
func _still_at_the_fire(waiting: int) -> void:
	_descending = false
	if _readout == null:
		return
	_readout.text += ("\n\n%d of the party %s still at the fire — the Deep "
		+ "takes you together, or not at all") % [
			waiting, "is" if waiting == 1 else "are"]


## Down. Whatever is in the stash is what you take, because `DES-014` puts
## loadout choices in the Chamber and this is the doorway rather than a menu.
@rpc("authority", "call_local", "reliable")
func _descend() -> void:
	set_process(false)
	GameState.descents += 1
	# **A run is a descent, so this is where one opens** (ADR-143). `MainMenu`
	# used to do it, and only on the route where a class was already sworn — the
	# class screen changed scene without it, so a first life and every life
	# after a death went down with no run file, and quitting mid-run cost them
	# nothing. One line, on the path every route into the Deep passes through.
	#
	# A no-op in an unarmed process (ADR-138), so a probe booting this level
	# directly still cannot open a run in the player's `user://`.
	RunFile.begin(GameState.class_id, GameState.pact_rank)
	# **And the door shuts behind the party** (`M3-T36`, ADR-157). Here rather
	# than in `room_set`, because *the descent* is the event — a level cannot
	# know whether the process that built it walked in or was launched into it,
	# and a rule about scenes would refuse the harnesses that assemble a party
	# in the Deep, whose peers do all agree about where they are.
	#
	# `call_local`, so the host runs this on the frame it commits, before the
	# scene change and therefore before there is any window at all on the
	# common path.
	CoopSession.the_party_has_gone_down()
	if _probing:
		# The descent *happened* — `_descending` is already true and that is
		# what a probe reads. Going through with it would free the node holding
		# the assertion (ADR-138).
		print("[edges] descended (held, probing)")
		return
	get_tree().change_scene_to_file("res://levels/room_set/room_set.tscn")


## **The camp's half of the second descent** (`M3-T38`, ADR-160).
##
## Answers the Legacy screen if one is up — which it is on the way back, because
## abandoning ends the life — and then walks into the hole. The whole scenario
## is the walk; the assertion is that the second one arrives.
##
## **The failure this exists for is silence.** Reported from play as *"I
## couldn't enter the dungeon again"*, with a log that simply stops: no error,
## no refusal, no scene change. So the deadline below is the check — a descent
## that does not happen has to say so, because the fault does not announce
## itself and every other check in this project would sit through it green.
func _again() -> void:
	await get_tree().create_timer(1.5).timeout
	var shown: LegacyScreen = legacy_screen()
	print("[again] the camp, life '%s', a death to answer=%s" % [
		GameState.class_id, shown != null])
	if shown != null:
		# Driven through the panels rather than by emitting `finished`, because
		# the join is what breaks: `M3-T05`'s rules were all correct while the
		# body three metres away stayed `'nobody'` (ADR-148).
		shown.advance()
		await get_tree().process_frame
		shown.advance()
		await get_tree().process_frame
		var picking: ClassScreen = null
		for node: Node in shown.find_children("*", "ClassScreen", true, false):
			picking = node as ClassScreen
		if picking == null or not picking.press(&"huskarl"):
			printerr("[again] FAIL the Legacy flow never reached a class to "
				+ "swear, so there is nobody to go back down")
			get_tree().quit(1)
			return
		for _frame: int in 8:
			await get_tree().process_frame

	var body: Player = _session.local_player() if _session != null else null
	print("[again] ready to go down: life '%s', body=%s, camp awake=%s, "
		% [GameState.class_id, body != null, is_processing()]
		+ "party still choosing=%d" % _session.still_choosing())
	if body == null:
		printerr("[again] FAIL the camp cannot find the body it is standing "
			+ "next to — `_process` returns at its first line, so the Descent, "
			+ "the Chamber and the readout are all dead while the player walks "
			+ "around a fire that answers nothing")
		get_tree().quit(1)
		return

	body.teleport(DESCENT_AT, 0.0)
	# Long enough for the trigger, the party gate and the scene change. If this
	# node is still here afterwards, the descent did not happen — and *that* is
	# the reported bug, which nothing else in the sweep can see.
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	printerr("[again] FAIL stood in the hole for 3 s and the run did not "
		+ "begin — life '%s', may_descend=%s, still choosing=%d, asking=%s"
		% [GameState.class_id, may_descend(), _session.still_choosing(),
			_descending])
	get_tree().quit(1)


func _build_ground() -> void:
	_slab(Vector3(GROUND, 0.4, GROUND), Vector3(0.0, -0.2, 0.0), ROCK)
	# The mountain, closing in behind the Descent.
	_slab(Vector3(GROUND, 9.0, 0.8), Vector3(0.0, 4.5, -13.0), ROCK)
	_slab(Vector3(0.8, 9.0, 12.0), Vector3(-8.0, 4.5, -7.0), ROCK)
	_slab(Vector3(0.8, 9.0, 12.0), Vector3(8.0, 4.5, -7.0), ROCK)

	var environment := WorldEnvironment.new()
	var world := Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.background_color = NIGHT
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.ambient_light_color = Color(0.16, 0.17, 0.22)
	world.ambient_light_energy = 0.5
	environment.environment = world
	add_child(environment)


## The fire, and it is the only warm thing here. `DES-014`: *"the only safe
## sound in the game"* is this camp, and the light is the visual half of that
## — `M2-T09` writes the other half.
func _build_fire() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.8
	mesh.height = 0.7
	var glow := StandardMaterial3D.new()
	glow.albedo_color = FIRE_COLOUR
	glow.emission_enabled = true
	glow.emission = FIRE_COLOUR
	glow.emission_energy_multiplier = 1.2
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = glow
	node.position = FIRE_AT + Vector3(0.0, 0.35, 0.0)
	add_child(node)

	var light := OmniLight3D.new()
	light.position = FIRE_AT + Vector3(0.0, 1.4, 0.0)
	light.omni_range = 16.0
	light.light_color = FIRE_COLOUR
	light.light_energy = 2.4
	add_child(light)


func _build_doors() -> void:
	# The Descent: unlit, and deliberately the darkest thing on screen.
	_slab(Vector3(3.6, 0.1, 3.6), DESCENT_AT + Vector3(0.0, 0.02, 0.0),
		DESCENT_COLOUR)
	_slab(Vector3(2.6, 0.1, 2.6), CHAMBER_AT + Vector3(0.0, 0.02, 0.0),
		CHAMBER_DOOR)


func _build_readout() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_readout = Label.new()
	_readout.position = Vector2(18.0, 18.0)
	_readout.add_theme_color_override("font_color", Color(0.88, 0.86, 0.80))
	layer.add_child(_readout)


func _slab(size: Vector3, centre: Vector3, colour: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = centre
	node.material_override = material
	var body := StaticBody3D.new()
	body.collision_layer = CollisionLayers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	node.add_child(body)
	add_child(node)


func _threshold_shot(path: String) -> void:
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[lair] threshold — %s" % path.get_file())
	get_tree().quit()


## Send the **client** into its own Chamber and back (`run_doorway.py`).
##
## The doorway probe walks the *host* through the Descent, which is the
## transition the party takes together. This is the other kind: a doorway only
## one player goes through, while everybody else stays where they are. Nothing
## covered it, and ADR-102 found four faults living in it at once.
##
## Drives the real slab rather than a test-only entry point — the client
## teleports onto the Chamber door and whatever the game does next is what is
## being measured.
##
func _chamber_probe() -> void:
	await get_tree().create_timer(5.0).timeout
	_census("before")
	if not multiplayer.is_server():
		var mine: Player = _session.local_player()
		if mine != null:
			mine.teleport(CHAMBER_AT, 0.0)
	# Long enough to walk in, look around, and come back out.
	await get_tree().create_timer(13.0).timeout
	_census("settled")


## What this peer can see, in one line. The whole assertion surface: how many
## bodies exist, whether one of them is mine, and which seat it holds — a seat
## that changes across a Chamber visit means I came back as somebody else.
func _census(tag: String) -> void:
	var bodies: int = get_tree().get_nodes_in_group("player").size()
	var mine: Player = _session.local_player() if _session != null else null
	print("[chamber] %s %s bodies=%d mine=%s slot=%d" % [
		"host" if multiplayer.is_server() else "client", tag, bodies,
		"yes" if mine != null else "NO",
		mine.party_slot if mine != null else -1])


## **The door takes you out of the world** (ADR-102).
##
## The Chamber is yours alone (ADR-021), so this is the one doorway exactly one
## player walks through while everybody else stays at the fire. It used to be a
## `change_scene_to_file`, and that was the wrong shape three times over: the
## client lost its camera, lost its body on the way back, and left the host
## sending packets into a scene that no longer existed.
##
## So the room opens *above* the camp instead, and your body is **despawned**
## rather than hidden. Hiding was the tempting fix and it is a lie: an
## invisible body still collides, still holds a doorway, still makes noise, and
## still occupies a seat. Other players see you walk to the door and go through
## it, which is what happened.
##
## The offset is what keeps two rooms built around the origin from standing
## inside each other. Both are lit by omni lights only, so at this distance
## neither one reaches the other.
const CHAMBER_SCENE: PackedScene = preload("res://levels/lair/chamber.tscn")
const CHAMBER_OFFSET: Vector3 = Vector3(0.0, -2000.0, 0.0)
## Where you are standing when you come back out — off the slab, facing the
## camp. On it, and the door would swallow you again immediately.
const CHAMBER_STEP: Vector3 = Vector3(0.0, 0.1, 4.6)
## The room's node name, which is also the path its private multiplayer is
## keyed to. One constant, because the two must agree.
const CHAMBER_NODE: String = "Chamber"
## How far from its own door a body in the Chamber is allowed to be for the room
## to count as somewhere a person is standing (`M2-T16`). The room is 16 x 14 m,
## so anything inside it is well under this; the failure it exists to catch put
## the body 2000 m away.
const CHAMBER_REACH: float = 40.0

var _chamber: Chamber = null
## False from the moment you step onto the slab until you step off it again.
var _chamber_armed: bool = true


func _open_the_chamber() -> void:
	if _chamber != null:
		return
	_chamber_armed = false
	set_process(false)
	# Out of the world first, so nobody watches a statue of you standing at the
	# door while you are inside.
	_ask_to_leave_the_world()

	_chamber = CHAMBER_SCENE.instantiate() as Chamber
	_chamber.name = CHAMBER_NODE
	_chamber.position = CHAMBER_OFFSET
	_chamber.left.connect(_close_the_chamber)
	# **The room gets its own multiplayer, with nobody on the other end.**
	#
	# ADR-021 says the Chamber is never networked and makes that structural by
	# keeping a `CoopSession` out of it. That was not enough once the room
	# started floating above a live connection: the body in here is *local*, so
	# it happily fired `_ask_for_my_bag` at the host, which answered "Node not
	# found: Chamber/chamber_body" — a private body reaching the wire, which is
	# the exact thing the ADR exists to prevent.
	#
	# Guarding the eleven RPC sites on `Player` one at a time would have worked
	# until somebody added a twelfth. A subtree with its own peerless
	# `MultiplayerAPI` cannot reach anybody by construction, whatever is written
	# inside it later. Set **before** it enters the tree, because `_ready` is
	# where the body decides whose it is.
	var island := MultiplayerAPI.create_default_interface()
	island.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().set_multiplayer(island, NodePath("/root/%s" % CHAMBER_NODE))
	# A sibling of this level rather than a child, so hiding the camp does not
	# hide the room floating above it.
	get_tree().root.add_child(_chamber)
	visible = false
	AudioDirector.enter("chamber")


func _close_the_chamber() -> void:
	if _chamber == null:
		return
	_take_down_the_chamber()
	visible = true
	AudioDirector.enter("threshold")
	_ask_to_rejoin_the_world()


## **Everything `_open_the_chamber` did, undone in one place** (`M2-T16`,
## ADR-108).
##
## There are two ways out of that room — through its door, and by the level
## going away underneath it — and they used to undo different amounts. Walking
## out freed the room and cleared the island and **left `set_process(false)`
## where it was**, so the camp came back with its own `_process` switched off:
## no descent trigger, no Chamber trigger, no re-arm, and a readout frozen on
## whatever it said before you went in. The only way on from there was ABANDON
## THE RUN, which calls `GameState.die()` — so the recovery deleted the stash
## the visit existed to build.
##
## One function owns the undo now, and both exits call it. The failure was not
## that somebody forgot a line; it was that there were two teardowns to keep in
## agreement, which is a thing that stays true and gets forgotten again.
func _take_down_the_chamber() -> void:
	_chamber.queue_free()
	_chamber = null
	get_tree().set_multiplayer(null, NodePath("/root/%s" % CHAMBER_NODE))
	set_process(true)


## **The Chamber is a sibling, so a scene change does not take it with us**
## (`M2-T15`, ADR-107).
##
## `_open_the_chamber` parents the room to `/root` rather than to this level, so
## that hiding the camp does not hide the room floating above it. That is right,
## and it has a consequence nothing was handling: `change_scene_to_file` frees
## the *current scene* and leaves every other child of the root alone. Abandon
## the run — or quit to the menu — from inside your own hoard room, and the
## Chamber survives, parented to the root, drawn over the main menu, with its
## private `MultiplayerAPI` still registered at `/root/Chamber`.
##
## The stale API is the worse half. `set_multiplayer` on a path that no longer
## holds what it did leaves the next Chamber to inherit somebody else's island,
## which is precisely the kind of fault ADR-102 built the island to make
## impossible.
##
## A level cleans up what a level created, on the way out, whichever way out it
## was.
func _exit_tree() -> void:
	if _chamber == null:
		return
	_take_down_the_chamber()


## Ask the host to take my body out. The host owns every spawn and despawn
## (`TEC-004`), so a client cannot simply free its own copy — it would come
## straight back on the next synchroniser packet.
func _ask_to_leave_the_world() -> void:
	if multiplayer.is_server():
		_session.despawn_player(CoopSession.HOST_PEER)
	else:
		_leave_the_world.rpc_id(CoopSession.HOST_PEER)


func _ask_to_rejoin_the_world() -> void:
	if multiplayer.is_server():
		_session.spawn_player(CoopSession.HOST_PEER, CHAMBER_STEP)
	else:
		_rejoin_the_world.rpc_id(CoopSession.HOST_PEER)


@rpc("any_peer", "reliable")
func _leave_the_world() -> void:
	if not multiplayer.is_server():
		return
	_session.despawn_player(multiplayer.get_remote_sender_id())


## Back through the door you went in by, rather than onto the next free spawn
## mark across the camp. **Beside** the slab rather than on it: landing on the
## trigger you just used sends you straight back in.
@rpc("any_peer", "reliable")
func _rejoin_the_world() -> void:
	if not multiplayer.is_server():
		return
	_session.spawn_player(multiplayer.get_remote_sender_id(), CHAMBER_STEP)


## The arrival half of `--extraction` (`M2-T20`, ADR-113).
##
## Reported from here rather than from the Deep because the Deep is the scene
## that goes away: a coroutine waiting in `room_set` when the run ends dies with
## it, so the process that most needs to say where it ended up is the one least
## able to. Whoever reaches the camp says so, and `run_doorway.py` checks that
## everybody did.
func _arrived_from_the_deep() -> void:
	await get_tree().create_timer(1.5).timeout
	var body: Player = _session.local_player() if _session != null else null
	var role: String = "host" if multiplayer.is_server() else "client"
	print("[extract] %s arrived at the Threshold, body=%s, carried=%d" % [
		role, "yes" if body != null else "NO", GameState.carried.size()])

	# **The run resolved for everybody, so it is closed for everybody**
	# (`M3-T34`, ADR-155).
	#
	# Asked here rather than in the Deep for the reason the line above is here:
	# `_take_the_outcome` ends in `change_scene_to_file`, which detaches the
	# floor synchronously (ADR-113, ADR-117), so the process best placed to say
	# what its run file did is the one least able to. Whoever reaches the camp
	# says so, and `run_doorway.py` reads both peers.
	#
	# **And the price of the way out, because that is the part a player meets.**
	# `RunFile.exists()` is what `PauseMenu` reads to decide between `ABANDON
	# THE RUN` and `TO THE MENU` (ADR-152) — so a stale run file is not a stale
	# file, it is a fire where the only door out costs the life. Asserting the
	# menu's own answer rather than the file keeps the row about the thing that
	# was reported.
	var pause: PauseMenu = null
	for child: Node in get_children():
		var found := child as PauseMenu
		if found != null:
			pause = found
	print("[extract] %s at the fire, run still open=%s, leaving ends the life=%s"
		% [role, RunFile.exists(),
			pause.leaving_ends_the_life() if pause != null else "no menu"])
	# **And the door is open again** (`M3-T36`, ADR-157). The descent shuts it,
	# and a party that never reopened it would finish one run and be
	# unjoinable for the rest of the session — a co-op game that quietly
	# becomes single-player after the first descent, which is worse than the
	# fault this replaced because nothing about it looks like an error.
	#
	# Reported from here because arriving at the camp is the one thing every
	# route home has in common, and because it is a claim about a **second**
	# visit: the flag starts open, so nothing asserted at boot can fail.
	print("[extract] %s at the fire, taking arrivals again=%s"
		% [role, CoopSession.taking_arrivals()])


## **A life ended down there, and she is waiting to be told what to keep**
## (`M3-T05`, ADR-133).
##
## `last_life` is written by `die()` and cleared when the choice is made, so its
## presence *is* the question. Checked here rather than at the moment of death
## because `DES-003` wants a scene rather than a modal over a corpse — and
## because the fire is where the rest of the loop's decisions already happen
## (`M2-T06`).
##
## Not gated on a probe flag: the screen draws nothing unless a life actually
## ended, so it cannot fade over a screenshot, and a probe that kills a player
## deliberately should be meeting it rather than skipping past it.
func _face_what_happened() -> void:
	if GameState.last_life.is_empty():
		return
	var screen := LegacyScreen.new()
	# Its own layer, above whatever the Threshold built. Same reason
	# `MainMenu._choose_a_class` does it: this can be the last thing between a
	# player and their next run, and a failure to build it must not leave them
	# looking at nothing (ADR-107's grey screen).
	var layer := CanvasLayer.new()
	layer.layer = 7
	layer.add_child(screen)
	add_child(layer)
	# **The screen has the player** (ADR-141). Without this the body underneath
	# keeps driving — and keeps recapturing the mouse every frame — so there is
	# no cursor to press any of these buttons with, and this screen is the one
	# you cannot skip. `PauseMenu` has always done it; it is a rule now rather
	# than one screen's good manners.
	_hand_over(true)
	screen.finished.connect(func() -> void:
		# **The question is answered, so it stops being asked.** Clearing this
		# is what ends the flow; leaving it would greet the player with their
		# own death every time they came back to the fire.
		GameState.forget_the_last_life()
		# **And the answer reaches the body** (ADR-148). Held until after the
		# swap, deliberately: the screen is 94% opaque and the body is rebuilt
		# underneath it, so the frame with no camera in it is a frame nobody
		# sees.
		await _swear_in_the_body()
		_hand_over(false)
		layer.queue_free())


## **Can a person actually use the screen that is up?** (ADR-141)
##
## Every probe in this project drives a screen by calling its methods —
## `press()`, `press_give_back()`, `finished.emit()`. That is the right way to
## assert what a screen *decides*, and it is why nothing ever noticed that the
## Legacy screen could not be **reached**: the body underneath kept driving,
## kept recapturing the mouse every frame, and no screen in the game grabbed
## focus, so there was neither a cursor nor a focused control. Reported from
## play as a death screen that could not be closed.
##
## So this row does the one thing the others do not: it presses `ui_accept` and
## checks the screen moved. Four claims, and the first three are the conditions
## that make the fourth possible at all.
func _screen_has_the_player(shown: LegacyScreen) -> PackedStringArray:
	var problems := PackedStringArray()
	var body: Player = _session.local_player() if _session != null else null
	if body == null:
		return PackedStringArray(["no body at the fire to take the controls from"])

	var driving: bool = body.driving()
	var focused: Control = get_viewport().gui_get_focus_owner()
	var captured: bool = body.pointer_captured()
	print("[camp] the screen    body driving=%s, focus=%s, wants cursor=%s" % [
		driving, focused != null, captured])
	if driving:
		problems.append(("the body is still being driven under an open screen "
			+ "— it goes on swinging and goes on recapturing the mouse, which "
			+ "is what left the death screen with no cursor to close it"))
	if focused == null:
		problems.append(("nothing on the screen has focus, so a controller has "
			+ "nowhere to start — ADR-075 makes both devices reach everything, "
			+ "and a screen a pad cannot move around in is the same bug as an "
			+ "action with no pad binding"))
	if captured:
		problems.append("the body still wants the cursor under an open screen, "
			+ "so there is nothing to press a button with. Asserted against the "
			+ "decision, not `Input.mouse_mode`: the headless display ignores "
			+ "that, so a row reading the engine passes either way")

	# **The composition row.** Everything above is a preconditionCheck; this is
	# the claim: a press reaches the screen and it moves.
	var before: int = shown.panel()
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	var lift := InputEventAction.new()
	lift.action = &"ui_accept"
	lift.pressed = false
	Input.parse_input_event(lift)
	await get_tree().process_frame
	await get_tree().process_frame
	print("[camp] a press       panel %d -> %d" % [before, shown.panel()])
	if shown.panel() == before:
		problems.append(("pressing accept did not move the Legacy screen off "
			+ "panel %d — every other check here calls its methods directly, "
			+ "so the input path is the one thing they cannot see, and it is "
			+ "the one that was broken") % before)
	return problems


## **The pause menu, which nothing had ever checked** (ADR-152).
##
## It is the screen implicated in all three of the reports this session
## answered, and before ADR-146 the only mention of it outside its own file was
## `add_child(PauseMenu.new())`. `--menu-probe` carefully asserts that every
## button on the **main** menu is wired and that none of them is the stub
## ADR-064 bans; the menu that can end a lineage had nothing.
##
## Run here rather than in the Deep because the fault was about *where you are
## standing*: this menu is the same object in all three levels, and at the fire
## there is no run to abandon.
func _the_way_out() -> PackedStringArray:
	var problems := PackedStringArray()
	var pause: PauseMenu = null
	for child: Node in get_children():
		var found := child as PauseMenu
		if found != null:
			pause = found
	if pause == null:
		return PackedStringArray(["no pause menu at the fire, so there is no "
			+ "way back to the main menu from here at all"])
	# **A life worth losing**, or the rows below are about an empty profile and
	# cannot tell a menu that ends a life from one that does not.
	GameState.forget_the_last_life()
	GameState.class_id = &"huskarl"
	GameState.taken.clear()
	GameState.taken.append(&"hrd_ballast")
	pause.open()

	# ─ every button does something (the rule `--menu-probe` applies to the
	#   other menu, on the screen that actually needed it) ─
	var buttons: int = 0
	var wired: int = 0
	for node: Node in pause.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null:
			continue
		buttons += 1
		if button.pressed.get_connections().size() > 0:
			wired += 1
	print("[camp] the pause menu %d button(s), %d wired" % [buttons, wired])
	if buttons == 0 or wired != buttons:
		problems.append(("the pause menu has %d button(s) and %d of them do "
			+ "anything — this is the screen a player reaches when something "
			+ "has gone wrong, and a dead button here is worse than a dead "
			+ "button anywhere else") % [buttons, wired])

	# ─ **at the fire there is no run, so leaving costs nothing** ─
	#
	# This is the reported bug. `_leave` called `die()` in all three levels, and
	# in two of them there is no run: a player standing at the fire between
	# descents, with a class and a tree and a stash, ended their life on one
	# click of a button that promised to abandon a run.
	var sworn_before: StringName = GameState.class_id
	print("[camp] no run here    leaving ends the life=%s (want no), sworn '%s'"
		% [pause.leaving_ends_the_life(), sworn_before])
	if pause.leaving_ends_the_life():
		problems.append(("leaving the fire is priced as abandoning a run, and "
			+ "there is no run at the fire — `RunFile` opens at the descent "
			+ "and closes when the run resolves"))
	pause.take_what_leaving_costs()
	print("[camp] and it cost    class '%s' -> '%s', a death waiting=%s (want no)"
		% [sworn_before, GameState.class_id,
			not GameState.last_life.is_empty()])
	if GameState.class_id != sworn_before or not GameState.last_life.is_empty():
		problems.append(("walking back to the main menu from the fire ended "
			+ "the life — reported as *starting a new run showed the tithe "
			+ "menu*, which is the Legacy screen doing its job about a death "
			+ "the player never recognised as one"))

	# ─ **and inside a run it costs the life, and it asks first** ─
	#
	# Its own run file, never the player's (ADR-152/ADR-145): this opens one.
	RunFile.use_a_scratch_run()
	RunFile.arm()
	RunFile.begin(GameState.class_id, GameState.pact_rank)
	pause.close()
	pause.open()
	print("[camp] in a run       leaving ends the life=%s (want yes)"
		% pause.leaving_ends_the_life())
	if not pause.leaving_ends_the_life():
		problems.append(("with a run open, leaving is priced at nothing — a "
			+ "menu that let you bank a risky haul by quitting would make "
			+ "every extraction optional (`DES-008`)"))
		# **And nothing below is pressed**, because with the price wrong this
		# button is wired straight to `_leave` — and `change_scene_to_file`
		# detaches this node synchronously (ADR-117), so the press would take
		# every assertion after it with it. Planted exactly that: the row above
		# printed **nothing at all** and the probe exited zero, because the
		# failure deleted its own witness. Same lesson as ADR-138's `_descend`,
		# reached from the other end.
		_put_the_fire_back(sworn_before)
		return problems
	var asked: Button = pause.way_out()
	if asked != null:
		asked.emit_signal("pressed")
	print("[camp] it asks first  confirming=%s, class still '%s'" % [
		pause.confirming(), GameState.class_id])
	if not pause.confirming():
		problems.append(("abandoning a run took one press — everything else on "
			+ "this menu is reversible and this one is `DES-008`'s great reset "
			+ "arriving through a button rather than through a fight"))
	if GameState.class_id != sworn_before:
		problems.append("the life ended while the menu was still asking, so "
			+ "the question is a caption rather than a question")
	pause.take_what_leaving_costs()
	print("[camp] and then       class '%s', a death waiting=%s (want empty/yes)"
		% [GameState.class_id, not GameState.last_life.is_empty()])
	if GameState.class_id != &"" or GameState.last_life.is_empty():
		problems.append(("abandoning an open run did not end the life — "
			+ "ADR-050 makes quitting cost exactly what staying would have "
			+ "cost, and this is the whole of that"))
	_put_the_fire_back(sworn_before)
	return problems


## Put back what `_the_way_out` spent, so everything after it is about the
## Legacy screen rather than about a life this check ended.
func _put_the_fire_back(_was: StringName) -> void:
	RunFile.clear()
	GameState.forget_the_last_life()
	GameState.class_id = &""
	GameState.taken.clear()


## **A screen closing gives back only what it took** (ADR-146).
##
## The rows above prove the Legacy screen takes the body when it opens. Nothing
## proved what happens when a **second** screen opens over the top of one, and
## that is exactly where the fault was: `PauseMenu.close()` said
## `set_driving(true)` — a statement about the whole game rather than about
## itself — so opening and closing the pause menu under the death screen handed
## the body back and recaptured the mouse while the screen was still up.
##
## Reported as *"it still showed the death or tithe screen ... but had the new
## run already playing in the background."* The Chamber had the same fault with
## the Pact tree, and one boolean was the reason both were possible.
func _screens_stack() -> PackedStringArray:
	var problems := PackedStringArray()
	var body: Player = _session.local_player() if _session != null else null
	var pause: PauseMenu = null
	for child: Node in get_children():
		var found := child as PauseMenu
		if found != null:
			pause = found
	if body == null or pause == null:
		return PackedStringArray(["no body or no pause menu at the fire to "
			+ "stack a second screen over"])

	pause.open()
	var both: PackedStringArray = body.attention_claims()
	pause.close()
	var left: PackedStringArray = body.attention_claims()
	print("[camp] two screens   held %s -> %s, driving=%s (want legacy, no)" % [
		both, left, body.driving()])
	if both.size() != 2:
		problems.append(("two screens are open and the body records %d claim(s) "
			+ "— a count that cannot reach two is the boolean this replaced")
			% both.size())
	if body.driving():
		problems.append(("closing the pause menu gave the body back while the "
			+ "Legacy screen was still up — it drives, and it recaptures the "
			+ "mouse, so the screen you cannot skip is the screen you cannot "
			+ "click. This is the reported bug"))
	if not left.has(String(LEGACY_CLAIM)):
		problems.append(("the pause menu released the Legacy screen's claim as "
			+ "well as its own. A screen may only give back what it took, or "
			+ "the seam is a boolean again wearing a list's clothes"))
	if left.has(String(PauseMenu.CLAIM)):
		problems.append("the pause menu closed and kept its claim, which parks "
			+ "the body for the rest of the level")
	return problems


## **The class reaches the body standing at the fire** (ADR-148).
##
## `CoopSession` declares what this peer is in its `_ready`, and `spawn_player`
## bakes the class into the spawn packet — both of which happen before the
## Legacy screen has asked who you are next. So after **every** death the body
## at the camp was `'nobody'`: no class, no kit, nothing in its hand, plain
## health. The reporter's own log says so in as many words —
## `peer 1 descends at rank 1 as 'nobody'` — and it came right only on the next
## scene change, because the Deep builds a fresh session that declares the class
## the life now has.
##
## That is the same fault ADR-141 was reported for, wearing different clothes:
## a body with no class has an empty hand, and an empty hand refuses the swing.
##
## Rebuilt through `CoopSession` rather than dressed in place, because becoming
## a class is `spawn_player`'s one job and a second route into it is the
## parallel path ADR-064 bans.
func _swear_in_the_body() -> void:
	if _session == null or GameState.class_id == &"":
		return
	var peer: int = multiplayer.get_unique_id()
	if _session.sworn_of(peer) == GameState.class_id:
		return
	_session.redeclare()
	if not multiplayer.is_server():
		# The host owns every body (`TEC-004`), so a client can only ask. The
		# declaration above is a reliable RPC to the same peer and therefore
		# arrives first, which is the whole reason the respawn can be a bare
		# request with nothing in it.
		_sworn_at_the_fire.rpc_id(CoopSession.HOST_PEER)
		return
	await _rebuild(peer)


## Take the body away and put the same person back, as the class they have just
## sworn.
##
## **A frame between the two halves, and it is load-bearing.** `player_for`
## finds a body by node name and `queue_free` does not release the name until
## the end of the frame, so despawning and spawning in one breath gives the new
## body a renamed node — `player_1@2` — that `player_for` can never find again.
## The camp would then have a body nobody could look up: no camera, no readout,
## no descent.
func _rebuild(peer: int) -> void:
	var body: Player = _session.player_for(peer)
	if body == null:
		return
	var where: Vector3 = body.global_position
	_session.despawn_player(peer)
	await get_tree().process_frame
	_session.spawn_player(peer, where)


## The client half. A client chooses its own class on its own machine — nothing
## about `GameState` is networked (`TEC-004`) — so the only thing that crosses
## is the request to be built again.
@rpc("any_peer", "reliable")
func _sworn_at_the_fire() -> void:
	if not multiplayer.is_server():
		return
	await _rebuild(multiplayer.get_remote_sender_id())


## Give the player's attention to a screen, or give it back.
##
## Looked up rather than held, because bodies are spawned and despawned by
## `CoopSession` at runtime and a reference caught when the screen opened can be
## freed before it closes — the lifetime fault `--edges-probe` already found
## twice in this file.
func _hand_over(to_a_screen: bool) -> void:
	var body: Player = _session.local_player() if _session != null else null
	if body == null:
		return
	if to_a_screen:
		body.hold_attention(LEGACY_CLAIM)
	else:
		body.release_attention(LEGACY_CLAIM)


## Reachable without a mouse, for `--legacy-probe`.
func legacy_screen() -> LegacyScreen:
	for child: Node in get_children():
		var layer := child as CanvasLayer
		if layer == null:
			continue
		for grandchild: Node in layer.get_children():
			var found := grandchild as LegacyScreen
			if found != null:
				return found
	return null
