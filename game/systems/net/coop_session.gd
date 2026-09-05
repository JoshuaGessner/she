class_name CoopSession
extends Node

## `M1-T05` — the network boundary, in one node (`TEC-004`).
##
## `TEC-004`'s first claim is that networking is *not a milestone, it is a
## constraint on every milestone*: every system written after this point gets
## written against a boundary that already exists. That is only true if the
## boundary is somewhere findable. This is it — transport, peer lifecycle, and
## the creation of every replicated actor. Nothing else in the project calls
## `ENetMultiplayerPeer`, and nothing else instantiates a player or an enemy.
##
## ## Solo is a host with zero peers, and that is free
##
## Measured on 4.7: with no peer ever assigned, Godot installs an
## `OfflineMultiplayerPeer` — `get_unique_id()` is 1, `is_server()` is true,
## and `MultiplayerSpawner.spawn()` works normally. So a single-player launch
## runs the *same* code as a host with nobody connected, and no second,
## offline path exists to drift out of sync with the real one (ADR-064).
##
## The trap that comes with it: `has_multiplayer_peer()` returns **true** with
## no peer at all, so it can never be used to ask "am I in a session". Ask
## `multiplayer.get_peers()` whether anyone is there, and `is_server()` who
## decides.
##
## ## Authority (ADR-082)
##
## The owning peer is authoritative over its own body's transform; the host is
## authoritative over every consequence. `TEC-004` bans rollback and lag
## compensation, and prediction without reconciliation is not prediction — it
## is authority. So the player's transform is genuinely owned by whoever is
## playing it, and damage, loot, clamor and enemy behaviour are genuinely owned
## by the host. Each player therefore carries two synchronisers with two
## different authorities; see `Player.configure_replication`.
##
## Levels hand this node their spawn points and ask it for actors. They never
## instantiate one themselves — that is what keeps "the network boundary
## already exists" true rather than aspirational.

## The host is always peer 1 in Godot's high-level multiplayer, including the
## offline peer, which is why solo needs no special case anywhere.
const HOST_PEER: int = 1

## `DES-012` / `TEC-004`: 1–4 players, so the host accepts three others.
const MAX_CLIENTS: int = 3

## The deepest rank `DES-022` describes. A declaration is a client's own
## number and the host builds a floor out of it, so it is clamped where it
## arrives rather than trusted and clamped later by whatever reads it.
const MAX_RANK: int = 9
## From `NetPlan`, which owns the number. Two copies is how they diverge.
const DEFAULT_PORT: int = NetPlan.DEFAULT_PORT
## Where a failed or lost connection lands. Never a quit — see `_give_up`.
const MENU_SCENE: String = "res://ui/main_menu.tscn"
## How long a client waits before deciding nobody is there ⟨tune⟩. Long enough
## for a slow link, short enough that a mistyped address is a small mistake.
const CONNECT_TIMEOUT_MSEC: int = 8000
const LOOPBACK: String = "127.0.0.1"
## **Why a connection did not happen, when nobody can say which** (`M3-T36`,
## ADR-157).
##
## There are three real causes and a client can tell them apart from none of
## them: nothing is hosting, the party is full, or the host has already gone
## down. ENet refuses the last two at the transport and never raises
## `connection_failed` for either — measured, and the reason `_start_client`
## carries its own deadline — so all three arrive here as silence.
##
## It used to say *"Check the address, and that the host has opened the
## Threshold"*, which names one cause and asserts it. Two of the three times
## that sentence appears it is **wrong**, and it sends somebody to re-check an
## address that was right all along: a fourth player is told to check their
## typing, and so is somebody whose friend simply started without them.
##
## Naming all three is honest about what this process knows, and each one is
## something the reader can act on. Telling them apart needs the host to answer
## before the transport refuses, which is a handshake this build does not have
## and which `M4-T07` brings for free with lobbies — so this is the whole of
## what is worth building today.
const NO_ANSWER: String = ("No answer from %s:%d after %d seconds.\n\n"
	+ "Either nothing is hosting there, the party is already full, or they "
	+ "have gone down without you — a descent only takes arrivals while "
	+ "everyone is at the fire.")
## Sentinel for "wherever the next spawn mark is". A real position, never used
## as one, because `Vector3` has no null.
const NO_PLACE: Vector3 = Vector3(-99999.0, -99999.0, -99999.0)

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://actors/enemies/enemy.tscn")

signal player_spawned(player: Player)
## Somebody's connection went away, and their body with it (`M3-T35`,
## ADR-156). The level listens because **a party can shrink without anybody
## dying**, and every question about whether a run is over is a question about
## who is left in it.
##
## Emitted after the body is freed and the seat released, so a handler asking
## `players()` is asking about the party that remains — with the caveat the
## handler carries: `queue_free` lands at the end of the frame, so the body is
## still in the group when this fires.
signal player_left(peer: int)
## The party's highest Pact Rank changed, because somebody declared (ADR-122).
## Levels listen: a floor is built in one frame and a client's declaration
## arrives in a later one, so "scale to the highest rank present" (ADR-010) is
## only true if the floor can be told about a rank that turns up late.
signal floor_rank_changed(was: int, now: int)
## Where each successive player starts. Cycled, so a fourth player in a
## three-point level stands on the first point rather than at the origin.
## Levels set this before adding the session to the tree.
var spawn_points: Array[Vector3] = [Vector3.ZERO]

var _role: String = "solo"
var _address: String = LOOPBACK
var _port: int = DEFAULT_PORT
var _device: String = InputDevices.ALL
## Peer to seat, for as long as the peer is connected. See `seat_for`.
var _seats: Dictionary = {}
var _next_enemy: int = 0
var _next_spawn: int = 0
## Counts every item ever spawned, and never counts back down. Node names have
## to agree across peers, and reusing an index after something was picked up
## would give a new item the name of one a client is still despawning.
var _next_item: int = 0
var _next_hunter: int = 0
## Counts every arrow ever loosed and never counts back down, for the reason
## `_next_item` gives: node names have to agree across peers, and reusing an
## index would give a new arrow the name of one a client is still despawning.
var _next_arrow: int = 0
var _next_snare: int = 0
## The floor's noise field, handed over by the level that built it — the same
## handoff `Gullsjukr.hunt_with` gets, and for the same reason: an arrow or a
## snare has no business searching the tree for a system, and the field is
## host-only (`TEC-001`) so there is nothing here for a client to hold.
##
## Levels come and go and this autoload does not, so every read goes through
## `floor_field()` rather than touching it directly.
var _floor_field: ClamorField = null
## When a client stops waiting, or 0 when it is not waiting. See `_start_client`.
var _waiting_until: int = 0
var _waiting_layer: CanvasLayer = null

## **Is the party still assembling?** (`M3-T36`, ADR-157)
##
## Static, because the thing it describes is the **connection**, and the
## connection outlives every level (ADR-101). A per-node flag would be reset by
## each doorway, which is precisely the moment it must not be — walking into the
## Deep is what shuts this, and the session that finds out is the next one.
## `NetPlan` is static for the same reason and gets the same benefit: no
## autoload budget spent on a fact with no behaviour (`TEC-001`).
##
## Open until the party descends. **Not "open only at the Threshold"** — that
## was the first shape of this fix and it is subtly the wrong rule, because it
## is about scenes and the truth is about the descent. It also broke every
## harness that assembles a party directly in the Deep, and those are not
## cheating: their peers all boot the same scene, so their node paths agree and
## a join between them is sound. What is unsound is joining a party that has
## **already gone down**, which is a fact about the run rather than about which
## file is loaded.
static var _party_is_assembling: bool = true

@onready var _actors: Node3D = $Actors
@onready var _spawner: MultiplayerSpawner = $Spawner


func _ready() -> void:
	_device = InputDevices.restrict_from_cmdline()
	_parse_args()
	# Set on every peer before any spawn packet can arrive: a client that has
	# not been told how to build an actor drops the spawn silently, and the
	# symptom is an empty world rather than an error.
	_spawner.spawn_function = _spawn_actor
	_ensure_a_peer()

	# **A connection outlives a scene change.** The peer lives on the
	# `SceneTree`, not on this node, so walking from the Threshold into the
	# Deep tears down one session and builds another *on top of a live
	# connection* — and the new one used to call `create_server` again, which
	# fails with "Couldn't create an ENet host" because the port is already
	# ours. In co-op that made every doorway in the game a disconnect.
	#
	# So a session that finds a working peer adopts it. Host stays host, client
	# stays client, and the level it happens to be in is not the network's
	# business.
	if _already_connected():
		_log("adopted the existing connection as peer %d"
			% multiplayer.get_unique_id())
		# **Declared again, on every session** (`M3-T10`). `_ranks` lives on the
		# session and a session is per scene, so the one that matters — the Deep,
		# built the instant this returns — starts with an empty table unless
		# every peer says its rank again here. Walking through a doorway is the
		# only way a real party ever reaches a floor, so a declaration made
		# solely at connect would be a declaration the floor never sees.
		declare_descent.rpc_id(HOST_PEER, _my_rank(),
			String(GameState.class_id), _my_effects(), _my_worn(),
			_my_bag(), _my_wound())
		if multiplayer.is_server():
			# **Re-applied on every session, because the peer outlives them and
			# the flag does too.** A doorway is exactly where this has to be
			# carried across rather than reset.
			_hold_the_door()
			multiplayer.peer_connected.connect(_on_peer_connected)
			multiplayer.peer_disconnected.connect(_on_peer_disconnected)
			# Every body has to exist again in the new scene, including the
			# ones belonging to peers that joined before this level did.
			spawn_player(HOST_PEER)
			for peer: int in multiplayer.get_peers():
				spawn_player(peer)
		else:
			multiplayer.server_disconnected.connect(_on_host_lost)
		return

	match _role:
		"host":
			_start_host()
		"client":
			_start_client()
		_:
			# No peer assigned at all. The offline peer is already in place and
			# already reports us as server 1, so the host path below is simply
			# skipped rather than replaced.
			_log("solo — offline peer, id %d" % multiplayer.get_unique_id())
			declare_descent(_my_rank(), String(GameState.class_id),
				_my_effects(), _my_worn(), _my_bag(), _my_wound())
			spawn_player(HOST_PEER)


## **There must be a peer, even when nobody is connected** (`M2-T15`, ADR-107).
##
## Godot installs an `OfflineMultiplayerPeer` at startup, and every solo path in
## this project quietly depends on it: with it, `is_server()` is true and
## spawning works, which is why there is no single-player branch anywhere.
##
## The dependency was invisible until something took it away. **Abandoning a run
## sets `multiplayer.multiplayer_peer = null`** — correctly, so a host that
## walks out to the menu stops hosting — and nothing ever put one back. From
## that moment on, in that process, `is_server()` answered **false**,
## `spawn_player()` returned `null` at its first line, no body was ever built,
## and the next level came up as a **grey screen**: the world was there and the
## camera belonged to a player who did not exist.
##
## A playtester found it by walking off the edge of the camp, abandoning, and
## descending again. Only the abandon mattered; the fall was a separate bug.
##
## Restoring it here rather than only at the menu is deliberate. This is the
## thing that *needs* a peer, so this is where the requirement belongs — any
## other route back into a level is covered for free, and nothing else has to
## remember.
func _ensure_a_peer() -> void:
	if multiplayer.multiplayer_peer != null:
		return
	_log("no peer at all — installing the offline one Godot starts with")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


## **Nobody joins a descent that has already begun** (`M3-T36`, ADR-157).
##
## Nothing gated a late join. The peer outlives a scene change and
## `CoopSession` is built per level, so a peer connecting after the party went
## down put **two processes in two different scenes on one connection** — and
## Godot addresses every RPC and every spawn by node path. Reproduced across two
## processes: the host logs *"Failed to get path from RPC:
## Threshold/CoopSession"*, the joiner logs *"Node not found:
## RoomSet/CoopSession/Spawner"* on every packet, and so the joiner receives no
## body, no camera and nothing else — ADR-107's grey screen through the one door
## ADR-107 did not close.
##
## **And it was not only the joiner's problem.** The host spawned a body for
## them anyway; that body is un-driven, because its owner's process cannot see
## it; `_on_party_changed` then hardens the floor for a player who is not there,
## and `_the_party_is_gone()` waits on a body nobody can move. In the
## reproduction the host's run ended in a wipe seconds after the join, where the
## identical run with nobody joining had no deaths at all.
##
## **Refused rather than supported**, deliberately. Telling a joiner which scene
## to load and reconciling a floor that is already half-cleared is a system, it
## overlaps `M4-T07`, and `DES-012` has the party descend together — so *"wait
## for them at the fire"* is the design's own answer rather than a limitation
## wearing its clothes.
##
## `refuse_new_connections` rather than a test inside `_on_peer_connected`: a
## peer that is never accepted cannot send a packet addressed to a scene nobody
## is in, which is the failure itself rather than its consequences.
static func the_party_has_gone_down() -> void:
	_party_is_assembling = false


## Home again, and the fire takes arrivals. Called by the Threshold, which is
## the only place a joining process can land (`DES-014`, `MainMenu._enter`).
static func the_party_is_at_the_fire() -> void:
	_party_is_assembling = true


## Whether somebody knocking right now would be let in. Public for
## `--threshold-probe`, which asserts both halves.
static func taking_arrivals() -> bool:
	return _party_is_assembling


## Apply the door to the transport. Called wherever this process becomes, or
## discovers it already is, a host.
func _hold_the_door() -> void:
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	multiplayer.multiplayer_peer.refuse_new_connections = not _party_is_assembling
	_log("the door is %s" % ("open — the party is still at the fire"
		if _party_is_assembling else "shut — the descent has begun"))


## Is there already a live connection this session should adopt?
##
## Deliberately not `has_multiplayer_peer()`, which `TEC-004` records as
## returning **true with no peer at all** — Godot installs an
## `OfflineMultiplayerPeer` and it answers yes. The question here is whether
## real packets are moving, which is `CONNECTION_CONNECTED` on something that
## is not the offline stand-in.
func _already_connected() -> bool:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Where this process is connecting, from `NetPlan` and nowhere else.
##
## The command line writes into the plan first, so probes and CI are unchanged
## and the main menu writes into the same place. Two callers, one answer — the
## alternative was a session that read `--host` itself and a menu with nowhere
## to put what the player chose.
func _parse_args() -> void:
	NetPlan.adopt_cmdline(OS.get_cmdline_user_args())
	match NetPlan.role:
		NetPlan.Role.HOST:
			_role = "host"
		NetPlan.Role.CLIENT:
			_role = "client"
		_:
			_role = "solo"
	_address = NetPlan.address
	_port = NetPlan.port
	# **What rank this process descends at**, overriding the profile.
	#
	# It exists because ADR-010 is a claim about a *mixed-rank party* and there
	# is no other way to build one: two processes on one machine share a `user://`,
	# so they cannot hold two different profiles, and nothing can raise a rank
	# until `M3-T01`. Without this, the only co-op party the sweep can assemble
	# is two rank-1 players — which is the one composition that cannot tell a
	# working ADR-010 from a broken one.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--as-rank="):
			_declared_rank = maxi(1, int(arg.split("=", true, 1)[1]))
		# **A body with no class holds nothing** (`M3-T07`, `DES-020`). Slots
		# make the class kit what arms you, and a headless process has never
		# been to the class select — so the two-process smoke was swinging with
		# empty hands and reading it as damage that failed to replicate.
		#
		# A harness flag rather than a default in the level: in the real game
		# `room_set` is only reachable through a menu that refuses to descend
		# without a class, and quietly supplying one here would hide the day
		# that stops being true.
		elif arg.begins_with("--as-class="):
			GameState.class_id = StringName(arg.split("=", true, 1)[1])


# ── transport ─────────────────────────────────────────────────────────────


## ENet's range coder, applied identically at both ends because a mismatch
## makes every packet unreadable rather than merely expensive.
##
## Not an optimisation. ADR-068 measured it roughly halving cost — 94 → 44
## kbps/client at `TEC-001`'s LOD split — which is the difference between
## inside and outside `TEC-004`'s budget. One line, and the budget depends on
## it, so it lives at the single place a peer is created.
func _configure(peer: ENetMultiplayerPeer) -> void:
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)


func _start_host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(_port, MAX_CLIENTS)
	if err != OK:
		# **Back to the menu with a reason, exactly as a failed join does**
		# (`M2-T16`, ADR-108). This used to `push_error` and return — which
		# skipped the `spawn_player` on the last line of this function and left
		# the level standing with no body and no camera, while the
		# `OfflineMultiplayerPeer` underneath went on answering `is_server()`
		# true so nothing downstream suspected anything. That is ADR-107's grey
		# screen arriving from a second direction, and the only trace of it was
		# a line in a console the player is not reading.
		#
		# The failure is ordinary: something is already on the port. A second
		# instance, a build left running, anything else on the machine.
		# `_start_client` has always handled the identical case correctly, on
		# the very next function.
		_give_up(("Could not open the Threshold on port %d — something else "
			+ "is already using it. Try another port, or close whatever has "
			+ "it.") % _port)
		return
	_configure(peer)
	multiplayer.multiplayer_peer = peer
	_hold_the_door()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_log("hosting on %d, up to %d client(s), input=%s" % [_port, MAX_CLIENTS, _device])
	declare_descent(_my_rank(), String(GameState.class_id),
		_my_effects(), _my_worn(), _my_bag(), _my_wound())
	spawn_player(HOST_PEER)


func _start_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(_address, _port)
	if err != OK:
		_give_up("Could not open a connection to %s:%d." % [_address, _port])
		return
	_configure(peer)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_host_lost)
	_log("joining %s:%d, input=%s" % [_address, _port, _device])
	# **Our own deadline**, because ENet's is not one worth waiting for.
	#
	# Measured: joining a dead port never emitted `connection_failed` at all
	# within fifty seconds of frames. So the failure this was supposed to
	# handle simply never arrived, and a tester who mistyped an address would
	# stand in an empty Threshold indefinitely with nothing to read — which is
	# worse than the process quitting, because at least a quit is a signal.
	_waiting_until = Time.get_ticks_msec() + CONNECT_TIMEOUT_MSEC
	_show_waiting()


func _process(_delta: float) -> void:
	if _waiting_until == 0 or Time.get_ticks_msec() < _waiting_until:
		return
	_waiting_until = 0
	_give_up(NO_ANSWER % [_address, _port, CONNECT_TIMEOUT_MSEC / 1000])


func _on_connected() -> void:
	# The client spawns nothing. Its own body arrives from the host like every
	# other actor, which is what makes "the host owns the world" true from the
	# first frame instead of true after a handshake.
	_log("connected as peer %d" % multiplayer.get_unique_id())
	# Before anything else asks (`M3-T10`). A floor built while a rank-8 player
	# was still announcing themselves is a rank-1 floor with a rank-8 player on
	# it, which is the opposite of what ADR-010 is for.
	declare_descent.rpc_id(HOST_PEER, _my_rank(),
			String(GameState.class_id), _my_effects(), _my_worn(),
			_my_bag(), _my_wound())
	# **Connecting is not arriving** (`M3-T36`, ADR-157).
	#
	# This cleared the deadline, and that is a claim the client is in no
	# position to make: a host that is refusing new connections still lets ENet
	# complete the handshake, so `connected_to_server` fires on a client the
	# host has already dropped. Measured — the joiner logs *"connected as peer
	# N"* and the host never fires `peer_connected` at all — and with the
	# deadline gone that client stands in an empty camp forever with nothing to
	# read, which is the state ADR-108 called *"worse than the process
	# quitting, because at least a quit is a signal."*
	#
	# **Extended rather than cleared**, because the two failures are different
	# lengths of the same wait and a slow link must not be mistaken for a
	# refusal. What ends the wait is the thing you came for: your body, which
	# only the host can send. See `_build_player`.
	_waiting_until = Time.get_ticks_msec() + CONNECT_TIMEOUT_MSEC


## Something to read while the wire is quiet. A client changes scene the moment
## it presses JOIN, so without this the whole connection is an empty room.
func _show_waiting() -> void:
	if _waiting_layer != null:
		return
	_waiting_layer = CanvasLayer.new()
	_waiting_layer.layer = 30
	add_child(_waiting_layer)
	var label: Label = MenuStyle.line("reaching for %s…" % _address, 18,
		MenuStyle.WARM)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.position = Vector2(label.position.x, 40.0)
	_waiting_layer.add_child(label)


func _hide_waiting() -> void:
	if _waiting_layer == null:
		return
	_waiting_layer.queue_free()
	_waiting_layer = null


## Could not reach the host. **Back to the menu, with a reason** — never a
## quit.
##
## It used to close the process. During a remote playtest this is the single
## most common thing that happens: a mistyped address, a host not up yet, a
## port that is not open. Exiting the game in response teaches a tester nothing
## and costs them a relaunch every time, and the second time it happens they
## stop trying.
func _on_connection_failed() -> void:
	_log("could not reach a host at %s:%d" % [_address, _port])
	_give_up(NO_ANSWER % [_address, _port, CONNECT_TIMEOUT_MSEC / 1000])


## The host went away. Same treatment, and for the same reason: a client whose
## process vanishes mid-run reports "it crashed", which is both wrong and the
## most expensive kind of bug report to chase.
##
## `DES-012`'s forced extraction — the run ending *in fiction* when the party
## collapses — is `M3`, and is absent rather than approximated here.
func _on_host_lost() -> void:
	_log("host disconnected")
	_give_up("The host closed the session.")


func _give_up(because: String) -> void:
	_log("gave up — %s" % because)
	NetPlan.last_error = because
	NetPlan.role = NetPlan.Role.SOLO
	# **Back to the offline peer, never to null** (`M2-T16`, ADR-108).
	#
	# This used to assign `null`, which is the shape ADR-107 was written about,
	# surviving here because `_ensure_a_peer()` repaired it in the next session
	# before anything read it. That is repair, not safety: `local_player()` asks
	# `multiplayer.get_unique_id()` every frame the camp draws its readout, and
	# with no peer at all that is an error per frame between giving up and the
	# menu actually arriving. `PauseMenu._leave` has done it this way since
	# ADR-107; there is no reason for the session that *needs* a peer to be the
	# one place still taking it away.
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	# **Never navigate during a probe.** A measuring process has no menu to
	# return to, and one that quietly changed scene would report on a level it
	# was not asked about — or, as happened here, sit in the menu forever while
	# the harness waited for a report that was never coming.
	#
	# Matched loosely on purpose. The first version compared against
	# `--coop-probe` exactly, and the real argument is `--coop-probe=PATH`, so
	# the guard never once fired and the co-op smoke hung for half an hour. Same
	# test `room_set` already uses to decide it is measuring rather than playing.
	for arg: String in OS.get_cmdline_user_args():
		if arg.contains("probe") or arg.contains("shot"):
			return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# **Deferred, because one caller is `_ready`** (`M2-T16`, ADR-108). A host
	# whose port is taken finds out while the level it belongs to is still being
	# built, and changing scene from inside that produces *"Parent node is busy
	# adding/removing children"* — the navigation lands a frame later instead.
	get_tree().change_scene_to_file.call_deferred(MENU_SCENE)



## **What rank of floor each peer needs** (`M3-T10`, ADR-119).
##
## The single exception to `TEC-004`'s progression row, and it is deliberately
## one integer. ADR-010 scales a floor to the **highest** Pact Rank present, so
## the host has to know what the party's ranks are; `TEC-004` says progression
## is never networked and calls that *"the important one… worth protecting"*.
##
## Both hold, because what crosses is not progression. No tree, no Boon, no
## stash, no Tithe ledger — one number, sent once, used to build a floor and
## then discarded with it. The host never stores it in a profile and never
## writes another player's anything. It is the same kind of value as party
## size, which has always crossed.
var _ranks: Dictionary = {}
## And who they are (`M3-T02`). Same argument, same one-way trip: the **host**
## builds every body and simulates its health, so a class that never reached it
## would be a Húskarl who is only a Húskarl on their own screen.
var _sworn: Dictionary = {}
## Peer id → the effect tags that peer's tree has switched on (`M3-T01`).
## Per scene like `_ranks`, and it dies with the floor.
var _effects: Dictionary = {}
## Peer id → slot name → item id (`M3-T07`). Per scene, and it dies with the
## floor like everything else here.
var _worn: Dictionary = {}
## Peer id → the bag that peer brought down, in `Inventory.pack()` rows
## (`M4-T01`, ADR-185). Per scene like everything above it.
##
## **Not on the spawn packet, unlike the class and the worn slots.** A spawn
## packet reaches every peer, and a bag is not everybody's business — the host
## sends each body's contents to its owner alone (`Player._push_bag`). Putting
## bags on the packet would broadcast all four inventories to all four players
## and change what the game shares, to save a dictionary.
var _bags: Dictionary = {}
## Peer id → the health that peer arrived carrying, or `RunFile.UNHURT`. Same
## trip and the same reason as the bag: `DES-009` bans regeneration *within* a
## run, ADR-015 makes a run three floors, and the host is the copy that decides
## what a blow did.
var _wounds: Dictionary = {}
## What this process says its own rank is. `0` means "ask the profile", which
## is every real launch; `--as-rank=N` is the sweep building a mixed party.
var _declared_rank: int = 0


## The rank this floor is built for: the highest anyone brought (ADR-010).
##
## *"Boredom is worse than danger."* Scaling down wastes the veteran's session
## and breaks their Tithe math, which is why ADR-010 chose highest over average
## and refused rank-banding outright.
func floor_rank() -> int:
	var highest: int = 1
	for rank: Variant in _ranks.values():
		highest = maxi(highest, int(rank))
	return highest


## What class this peer is playing, for the host that builds their body.
## The effect tags a peer descended with, or empty. Read by the spawn payload
## and by nothing else — a system asks the **body**, never the session.
func effects_of(peer: int) -> PackedStringArray:
	return _effects.get(peer, PackedStringArray()) as PackedStringArray


func sworn_of(peer: int) -> StringName:
	return StringName(_sworn.get(peer, ""))


## **How many of us have not said who they are** (`M3-T37`, ADR-158).
##
## No new wire and no new bit: `declare_descent` has carried the class since
## `M3-T02` because the host builds every body, and a peer whose class question
## is still open declares `""`. The host already knew; nothing asked it.
##
## Counts a peer that has connected and not yet declared, which is correct
## rather than merely convenient — they are not ready, they are about to be,
## and the answer changes on its own a frame later (ADR-122 is the same
## observation about ranks).
##
## The host counts itself, so a classless host cannot take a sworn party down
## either. `Threshold.may_descend()` is **not** a duplicate of this: that one
## decides whether the body you are driving may walk into the hole, and this
## decides whether the party may go. `M2-T15`'s lesson — a level can be reached
## without passing through the menu — is why both exist.
func still_choosing() -> int:
	if not multiplayer.is_server():
		return 0
	var waiting: int = 0
	for peer: int in multiplayer.get_peers():
		if sworn_of(peer) == &"":
			waiting += 1
	if sworn_of(multiplayer.get_unique_id()) == &"":
		waiting += 1
	return waiting


## **Has everyone here said who they are** (ADR-122)?
##
## A body arriving and a declaration arriving are two independent events: the
## host spawns a joining peer's body from `peer_connected`, while that peer's
## declaration is an RPC it sends from its own `_on_connected`. Neither waits
## for the other, so "two players are on the floor" does **not** mean "the floor
## knows what rank to be" — and a check that samples on the first is reading a
## floor that is still assembling. It failed one run in two before this existed.
##
## Nothing in the game waits on this: the floor rescales when a declaration
## lands, whenever that is. It is the *measurement* that needs a settled floor.
func everyone_declared() -> bool:
	if not multiplayer.is_server():
		return true
	for peer: int in multiplayer.get_peers():
		if not _ranks.has(peer):
			return false
	return _ranks.has(multiplayer.get_unique_id())


## Tell the host what floor you need and what body to build. Host-local too, so
## solo takes the same path as a four-stack and there is no second branch to
## keep in step.
##
## **Two values, and still not progression** (ADR-119, extended by ADR-121). A
## rank builds a floor; a class id builds a body. Neither is tree state, Boon,
## stash or Tithe ledger — the host stores neither in a profile and writes
## nobody's but its own. They are the same kind of value as party size, which
## has always crossed, and they are discarded with the scene.
## **And what it is carrying** (`M4-T01`, ADR-185). `bag` is `Inventory.pack()`
## rows and `hurt` is `RunFile.UNHURT` or a health figure — both read off that
## peer's own run file, both discarded with the floor like everything else here.
##
## Still not progression (`TEC-004`, ADR-119). A bag is run state: it does not
## outlive the expedition, the host writes nobody's profile with it, and the
## host already holds every body's inventory anyway — this is how it *gets* it
## when the body is rebuilt one floor down.
@rpc("any_peer", "call_local", "reliable")
func declare_descent(rank: int, sworn: String, effects: PackedStringArray,
		worn: Dictionary, bag: Array, hurt: float) -> void:
	if not multiplayer.is_server():
		return
	var who: int = multiplayer.get_remote_sender_id()
	# `0` is what a local call reports rather than a peer id.
	var id: int = who if who != 0 else multiplayer.get_unique_id()
	var was: int = floor_rank()
	# **Both ends, not just the floor** (ADR-199). This clamped upward from 1
	# and let anything through above — so one client sending a wrong number,
	# from a version skew or a bug, built a floor `DES-022` has no rank for.
	# `GameState`'s own tables clamp to their length; this is the same ceiling
	# stated where the value enters the host.
	_ranks[id] = clampi(rank, 1, MAX_RANK)
	# **A class the game has.** `sworn` reaches `spawn_player` as the body to
	# build and `ClassCatalogue.by_id` returns null for anything else — which
	# is a body with no kit, and `--stalker-probe` has already recorded what an
	# unarmed class looks like from the inside. An unknown name is dropped to
	# nobody, which is the state a body that has not chosen is already in.
	if sworn != "" and ClassCatalogue.by_id(StringName(sworn)) == null:
		_log("peer %d declared class '%s', which does not exist — treated as "
			% [id, sworn] + "unsworn rather than built")
		sworn = ""
	_sworn[id] = sworn
	# **The tree comes with the body** (`M3-T01`). `GameState` knows only this
	# machine's nodes, and the host builds four bodies of which three belong to
	# somebody else — so a host reading its own `has_effect` would apply its
	# tree to the whole party. Exactly the fault ADR-121 avoided for the class,
	# arriving one task later through a different door.
	#
	# Tags rather than node ids: what crosses is the set of rules that are on,
	# which is what a body needs, and it keeps `TEC-004`'s *"progression is
	# never networked"* honest — no Boon, no spend, no tree, and the host stores
	# none of it past the floor.
	_effects[id] = effects
	# **What that peer is wearing** (`M3-T07`). Same reason as the two above:
	# the host dresses four bodies and only one of the wardrobes is its own.
	_worn[id] = worn
	_bags[id] = bag
	_wounds[id] = hurt
	# **Tell the body, if it is already here.** A declaration and a spawn packet
	# are independent events and neither waits for the other (ADR-122), so both
	# orders have to end in the same place: the payload covers *declared first*,
	# and this covers *spawned first* — which is the ordinary case, because the
	# host spawns from `peer_connected` and the declaration is an RPC behind it.
	var body: Player = player_for(id)
	if body != null:
		body.sworn = StringName(sworn)
		body.effects = effects
		body.wearing = worn
		_hand_down(body, id)
	_log("peer %d descends at rank %d as '%s' — the floor is rank %d" % [
		id, rank, sworn if sworn != "" else "nobody", floor_rank()])
	# **The floor has to hear this** (ADR-122). A client's declaration is an
	# RPC and arrives *after* the host has already built the level in its own
	# `_ready` — so a floor that read `floor_rank()` once was a floor built to
	# the host's rank alone, which is the option ADR-010 rejected outright.
	if floor_rank() != was:
		floor_rank_changed.emit(was, floor_rank())


## **A body is built when the host knows what body to build** (`M3-T07`).
##
## This used to call `spawn_player` here, and that is one frame too early:
## a joining peer's `declare_descent` is an RPC it sends from its own
## `_on_connected`, so the payload was assembled before the host had been told
## the class — and **every client's body has been built classless since
## `M3-T02`**, quietly losing its health, speed and carry scales. Nothing
## noticed, because `sworn` only changed numbers until `M3-T07` gave it a
## weapon to hold and the two-process smoke started swinging at air.
##
## Exactly the shape ADR-122 found in `_build_hunt` — a body arriving and a
## declaration arriving are independent events — so it takes the same answer
## from the other end: the declaration is what spawns the body.
func _on_peer_connected(peer: int) -> void:
	# **Belt as well as braces** (`M3-T36`, ADR-157). `refuse_new_connections`
	# is the fix; this is what makes a failure of it visible instead of
	# expensive. There is a real window — the door is shut as the descent
	# begins, and a connection already in flight can land inside it — and a body
	# built for somebody who cannot see it is what hardens the floor and holds
	# the run open.
	if not _party_is_assembling:
		_log("peer %d knocked after the descent began — no body, and the "
			% peer + "connection is closed")
		multiplayer.multiplayer_peer.disconnect_peer(peer)
		return
	_log("peer %d joined" % peer)
	spawn_player(peer)


func _on_peer_disconnected(peer: int) -> void:
	_log("peer %d left" % peer)
	var player: Player = player_for(peer)
	if player != null:
		player.queue_free()
	# The seat is theirs until they are actually gone. A door does not free it;
	# leaving does, so the next arrival is a new person rather than an heir.
	_seats.erase(peer)
	_forget(peer)
	# **And the level has to be told** (`M3-T35`, ADR-156). This freed a body
	# and said nothing, so a run whose last standing member *left* was never
	# re-examined: run resolution is reachable from a death and from an
	# extraction and from nowhere else, and a disconnect is neither.
	player_left.emit(peer)


# ── spawning ──────────────────────────────────────────────────────────────


## The one place an actor is created, on every peer.
##
## Runs on the host when it calls `spawn()`, and on each client when the spawn
## packet arrives — with the *same* payload, so both sides derive the same node
## name and the same authority without either being told. Names have to match
## across peers or every RPC and every synchroniser addresses a different node.
## **Everything that peer was, dropped when the peer is** (`M4-T24`, ADR-199).
##
## `_seats` was erased here and the other six were not, so a departed player
## went on being part of the party in every way that mattered to the floor.
## `floor_rank()` reads `_ranks.values()` — the dictionary, not the live peer
## list — and it is consulted at **every floor build** for enemy density
## (`RankScaling.denser`) and for how old the Hunt starts (`RankScaling
## .hunt_age`). So a rank-8 player who joined, descended and left on floor 0
## kept floors 1 and 2 built at rank 8 for a party of rank-1s, which is
## ADR-010's *"the highest rank **present**"* being wrong about present.
##
## `_bags` was the other half: a full inventory per departed peer, held for the
## life of the level.
##
## **Only on a real disconnect.** `despawn_player` is a different event —
## ADR-102 makes peers unable to stand in different levels, so leaving the
## world is a *state* and a body can come back through `_rejoin_the_world`.
## That peer must keep its bag, so nothing here runs on that path.
##
## **And `floor_rank_changed` is deliberately not emitted.** Its handler
## respawns the floor's enemies, so firing it mid-run would resurrect
## everything the party had already killed and reset the rest — a worse bug
## than the one being fixed. The floor you are standing on was built for the
## party that entered it; only the *next* one reads the corrected rank. Losing
## a teammate makes the rest of this floor harder, and that is the run being
## the product rather than a fault.
func _forget(peer: int) -> void:
	var was: int = floor_rank()
	_ranks.erase(peer)
	_sworn.erase(peer)
	_effects.erase(peer)
	_worn.erase(peer)
	_bags.erase(peer)
	_wounds.erase(peer)
	var now: int = floor_rank()
	if now != was:
		_log("peer %d took rank %d with them — the next floor is rank %d, and "
			% [peer, was, now] + "this one stays as it was built")


func _spawn_actor(data: Variant) -> Node:
	var payload: Dictionary = data as Dictionary
	match String(payload["kind"]):
		"player":
			return _build_player(payload)
		"world_item":
			return _build_world_item(payload)
		"hunter":
			return _build_hunter(payload)
		"arrow":
			return _build_arrow(payload)
		"snare":
			return _build_snare(payload)
		_:
			return _build_enemy(payload)


func _build_player(payload: Dictionary) -> Node:
	var peer: int = int(payload["peer"])
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.name = "player_%d" % peer
	player.position = payload["at"] as Vector3
	player.rotation.y = float(payload["yaw"])
	# Before `add_child`, like the authority, so the seat rides the spawn packet
	# and every peer derives the same one from the same payload. A slot decided
	# after the fact would differ per process, and it is what tells one player's
	# **ember** from another's (`M2-T05`).
	player.party_slot = int(payload["slot"])
	# Before `add_child` for the same reason the seat is: the body's own
	# `_ready` sizes its health and stamina pools, and a class applied after
	# that would leave a Húskarl standing there with a Veiðimaðr's numbers for
	# a frame — on the host, which is the copy that decides what a blow does.
	player.sworn = StringName(payload.get("class", ""))
	player.effects = payload.get("effects", PackedStringArray()) as PackedStringArray
	player.wearing = (payload.get("worn", {}) as Dictionary).duplicate()
	# Before `add_child`, so `_ready` already knows whether it is looking at
	# its own body. Deciding afterwards means one frame of a remote player
	# holding the camera and capturing the mouse.
	player.configure_replication(peer)
	# **This is what arriving looks like** (`M3-T36`, ADR-157). A client is in
	# when the host has built it a body, and not when ENet says the socket is
	# up — the host is the only peer that can decide, and this packet is the
	# decision. No handshake was added for this: the thing you were waiting for
	# turning up is the signal that you are no longer waiting.
	if peer == multiplayer.get_unique_id() and not multiplayer.is_server():
		_waiting_until = 0
		_hide_waiting()
	# Signals up, calls down (`TEC-002`): a player putting something down says
	# so, and the session — which owns the spawner — is what makes it exist.
	# `spawn_world_item` is host-only, so a client's copy of this connection is
	# inert rather than wrong.
	# Bound, so the handler knows **whose** drop it is. A Hoard build's discards
	# are bait whatever they are worth (`hrd_tribute_in_kind`), and the signal
	# carries the item rather than the body that let go of it.
	player.dropped.connect(_on_player_dropped.bind(player))
	# An arrow leaving a bow and a trap being set are both *"the actor decides,
	# the session spawns"* (`M3-T11`, ADR-112) — the same wiring one line up.
	player.loosed_arrow.connect(_on_player_loosed)
	player.set_snare.connect(_on_player_set_snare)
	player.roared.connect(_on_player_roared)
	return player


func _build_enemy(payload: Dictionary) -> Node:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.name = "enemy_%d" % int(payload["index"])
	enemy.position = payload["at"] as Vector3
	enemy.rotation.y = float(payload["yaw"])
	# Authority stays with the host: every enemy is host-simulated (`TEC-004`),
	# and the default authority of a spawned node is already peer 1.
	enemy.configure_replication()
	return enemy


## Loot, built in code rather than from a scene: a `WorldItem` is a blockout
## box sized from its own `grid_size`, so a `.tscn` would hold nothing the
## resource does not already say (ADR-046).
func _build_world_item(payload: Dictionary) -> Node:
	var item := WorldItem.new()
	item.name = "item_%d" % int(payload["index"])
	# Before `add_child`: `_ready` resolves the id against the catalogue, and a
	# node that entered the tree not knowing what it is would have to be told
	# afterwards, which is one frame of an item with no mesh on every peer.
	item.item_id = payload["item"] as StringName
	item.launch = payload["launch"] as Vector3
	item.disturbed = bool(payload["disturbed"])
	item.bound_to = int(payload["bound"])
	item.worth_stopping_for = bool(payload.get("bait", false))
	item.position = payload["at"] as Vector3
	item.rotation.y = float(payload["yaw"])
	return item


## The Gullsjúkr (`M2-T02`). One per floor for now — `DES-017`'s second Hunter
## needs floors to escalate across, and there is one until `M4-T01`.
func _build_hunter(payload: Dictionary) -> Node:
	var hunter := Gullsjukr.new()
	hunter.name = "gullsjukr_%d" % int(payload["index"])
	hunter.position = payload["at"] as Vector3
	# Authority stays with the host: every decision it makes is a consequence,
	# and the default authority of a spawned node is already peer 1.
	hunter.configure_replication()
	# What it tears out of a bag becomes a thing on the floor, and spawning is
	# this node's job alone (`M2-T19`, ADR-112). Same wiring as `Player.dropped`
	# two functions up — the actor decides, the session spawns.
	hunter.took.connect(_on_hunter_took)
	return hunter


## Give this peer a body.
##
## `at` overrides the spawn mark for somebody coming back through a door rather
## than arriving for the first time — you step out of the door you went in by,
## not onto the next free mark across the camp.
func spawn_player(peer: int, at: Vector3 = NO_PLACE) -> Player:
	if not is_host():
		return null
	if at.is_equal_approx(NO_PLACE):
		# A counter rather than the current peer count: after someone
		# disconnects and someone else joins, a count would put the new arrival
		# on an occupied point, and two players standing inside each other on
		# spawn reads as a replication bug rather than as arithmetic.
		at = spawn_points[_next_spawn % spawn_points.size()]
		_next_spawn += 1
	var player: Player = _spawner.spawn({
		"kind": "player", "peer": peer, "at": at, "yaw": 0.0,
		"slot": seat_for(peer),
		# What body to build (`M3-T02`). On the spawn packet like the seat, so
		# every peer derives the same Húskarl from the same payload rather than
		# each deciding for itself and disagreeing about how much health it has.
		"class": String(sworn_of(peer)),
		# The rules this life has bought (`M3-T01`, `TEC-006`). On the packet
		# beside the class and for the same reason: every peer derives the same
		# body from the same payload.
		"effects": effects_of(peer),
		"worn": _worn.get(peer, {}),
	}) as Player
	if player != null:
		# **Before anyone hears about the body** (`M4-T01`, ADR-185). Levels
		# listen to `player_spawned` to rescale a floor, and one of the things
		# they scale on is what the party is carrying — a body that announced
		# itself empty and filled a frame later would be measured empty.
		_hand_down(player, peer)
		player_spawned.emit(player)
	return player


## Take this peer's body out of the world (ADR-102).
##
## Used by a private door: a player who steps into their own Chamber is not in
## the camp any more, and hiding the body instead would leave an invisible
## person still colliding, still holding a doorway, still making noise. The
## despawn replicates like any other, so everyone else watches them leave.
func despawn_player(peer: int) -> void:
	if not is_host():
		return
	var body: Player = player_for(peer)
	if body != null:
		body.queue_free()


## Which seat this peer holds, assigned once and **remembered**.
##
## It used to be the spawn counter, so a body that was despawned and spawned
## again came back wearing a different seat — and since `party_slot` is what
## tells one ember from another (`M2-T05`), a player returning from their
## Chamber would come home as somebody else, with their own ember on the floor
## naming a seat nobody held. Keyed to the peer, released only when the peer
## actually leaves, so a door is not an identity change.
func seat_for(peer: int) -> int:
	if _seats.has(peer):
		return int(_seats[peer])
	var taken: Array = _seats.values()
	for seat: int in range(Player.MAX_PARTY):
		if not taken.has(seat):
			_seats[peer] = seat
			return seat
	# More bodies than seats is a bug elsewhere, but wrapping is better than
	# refusing to spawn somebody who is already connected.
	_seats[peer] = _seats.size() % Player.MAX_PARTY
	return int(_seats[peer])


## Levels ask for enemies; they never instantiate one. Silently does nothing on
## a client, because a client asking for an enemy is asking the wrong process —
## the host's spawn will arrive on its own.
func spawn_enemy(at: Vector3, yaw: float = 0.0) -> void:
	if not is_host():
		return
	_spawner.spawn({
		"kind": "enemy", "index": _next_enemy, "at": at, "yaw": yaw,
	})
	_next_enemy += 1


## Levels and players ask for loot; neither instantiates one. Host-only for the
## same reason enemies are: what exists in the world is a consequence, and
## consequences have one owner (`TEC-004`, ADR-082).
##
## Returns the host's copy so a drop can be measured immediately; clients get
## theirs when the spawn packet lands.
## `disturbed` defaults false, so **authored floor loot is not bait** — levels
## place treasure without it becoming something the Gullsjúkr walks off to
## collect. Only a player putting something down sets it (`DES-017`).
## `bound_to` rides the **payload**, not a call afterwards. An ember decides
## how it looks in `_ready` — whose seat, which colour, how many motes — so a
## binding applied after `spawn()` arrives too late and every ember renders as
## seat 0. That is not hypothetical: it shipped for an hour and only a
## screenshot of four side by side caught it, because the numbers all passed.
func spawn_world_item(item: StringName, at: Vector3, yaw: float = 0.0,
		launch: Vector3 = Vector3.ZERO, disturbed: bool = false,
		bound_to: int = 0, worth_stopping_for: bool = false) -> WorldItem:
	if not is_host():
		return null
	var made: WorldItem = _spawner.spawn({
		"kind": "world_item", "index": _next_item, "item": item,
		"at": at, "yaw": yaw, "launch": launch, "disturbed": disturbed,
		"bound": bound_to, "bait": worth_stopping_for,
	}) as WorldItem
	_next_item += 1
	return made


func _on_player_dropped(item: ItemInstance, at: Vector3, yaw: float,
		launch: Vector3, from: Player) -> void:
	# Anything a player set down counts as disturbed, thrown or not: a panic
	# dump is as much an offering as a bait, and the Hunter stopping for the
	# pile you abandoned is `DES-005`'s counter-play paying out.
	#
	# A put-down ember is still somebody's. Losing the binding here would turn
	# a friend into scenery the moment their rescuer set them down for a fight.
	var bait: bool = from != null and from.has_effect(&"tribute_in_kind")
	spawn_world_item(item.definition.id, at, yaw, launch, true, item.bound_to, bait)


## The Gullsjúkr took something (`M2-T19`, ADR-112). It lands at its feet as
## **disturbed** gold, which is what makes the next few seconds work: the
## Hunter's own bait logic finds it and stoops, and that stoop is the window in
## which you can take it back. Deleting it into the creature's hoard instead
## would be a loss with no evidence, and a loss with no evidence reads as a bug.
##
## The binding travels, for the same reason a put-down ember keeps it: if this
## was somebody's ember, it is still somebody's.
func _on_hunter_took(item: ItemInstance, at: Vector3) -> void:
	spawn_world_item(item.definition.id, at, 0.0, Vector3.ZERO, true,
		item.bound_to)


## Levels ask for the Hunter. Returns the host's copy so a level can hand it
## the clamor field it hunts by; clients get theirs from the spawn packet and
## never need one, because the field is host-only (`TEC-001`).
func spawn_hunter(at: Vector3) -> Gullsjukr:
	if not is_host():
		return null
	var made: Gullsjukr = _spawner.spawn({
		"kind": "hunter", "index": _next_hunter, "at": at,
	}) as Gullsjukr
	_next_hunter += 1
	return made


## Free every enemy. Host-only: the despawn replicates, so a client doing this
## itself would delete an actor the host still believes in.
func clear_enemies() -> void:
	if not is_host():
		return
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()


# ── who is who ────────────────────────────────────────────────────────────


func is_host() -> bool:
	return multiplayer.is_server()


## **Whose body is this?** — asked of the body, not of its name (`M3-T40`,
## ADR-162).
##
## This used to be `_actors.get_node_or_null("player_%d" % peer)`, and a node
## name is the one property of a body Godot will silently change out from under
## you. `add_child` renames on collision, so a body spawned while its
## predecessor is still in the deletion queue arrives as `player_1@2` — and
## this lookup then answers `null` for that peer **for the rest of the level**,
## with no error and a body still standing there.
##
## Measured, because the previous note here asserted the opposite. Freeing a
## node and adding a same-named one with a single `process_frame` between them:
##
## | started from | old body after 1 frame | new name | lookup finds |
## |---|---|---|---|
## | `_process` | **still valid** | renamed | the **dying** node |
## | a coroutine already resumed at `process_frame` | gone | `player_1` | the new one |
##
## Input is dispatched before idle processing, so a real button press is on the
## first row and every probe in this project is on the second. That is the whole
## reason this survived two play sessions and eight headless reproductions: the
## instrument shared the blind spot with the code (`M3-T40` builds the row that
## does not).
##
## Authority is the right key because it is what the body actually *is*:
## `configure_replication` sets it before `add_child`, it rides the spawn packet
## to every peer, and nothing renames it. Scoped to `_actors` and skipping the
## deletion queue, so this can return neither a corpse nor somebody else's
## session's body — `players()` learned the second half in ADR-156 and this is
## the same sentence about one peer.
func player_for(peer: int) -> Player:
	if _actors == null:
		return null
	for node: Node in _actors.get_children():
		var body: Player = node as Player
		if body == null or body.is_queued_for_deletion():
			continue
		if body.get_multiplayer_authority() == peer:
			return body
	return null


## Every actor this session is holding, named, with the dying ones marked.
##
## For a report that has to say what it **did** find. `M3-T39` made the camp
## say it had lost its body; that line named the peer and nothing else, which
## narrows the cause to "the lookup failed" and stops. A rename, an empty
## `Actors`, and a body that belongs to the wrong peer are three different bugs
## and produced one sentence between them.
func actor_names() -> PackedStringArray:
	var names: PackedStringArray = []
	if _actors == null:
		return names
	for node: Node in _actors.get_children():
		names.append("%s%s" % [node.name,
			" (being freed)" if node.is_queued_for_deletion() else ""])
	return names


## The body this process is playing. Every peer has exactly one; on the host
## that is peer 1's, on a client its own.
func local_player() -> Player:
	return player_for(multiplayer.get_unique_id())


## Everybody who is actually in the party.
##
## **A body being freed is not one of them** (`M3-T35`, ADR-156). `queue_free`
## does not leave the tree until the deletion queue is flushed, which is after
## the frame the caller is in — so a body whose peer has just disconnected was
## still answering this, still counted by `_the_party_is_gone()`, and still
## reading as *standing*, which is the shape that kept a run open with nobody
## in it.
##
## Stated here rather than worked around at each of the twenty call sites, and
## rather than by awaiting a frame and hoping: *is this body still in the run*
## is one question, and the honest answer to it is the same everywhere.
func players() -> Array[Player]:
	var found: Array[Player] = []
	for node: Node in get_tree().get_nodes_in_group("player"):
		if node.is_queued_for_deletion():
			continue
		found.append(node as Player)
	return found


func _log(message: String) -> void:
	print("[coop:%s] %s" % [_role, message])


## The rank this process descends at: the profile's, unless `--as-rank=` said
## otherwise. One function so every declaration site answers the same way —
## there are four of them, and four copies of `GameState.pact_rank` is four
## places for a flag to be forgotten.
## Every rule this machine's tree has switched on (`M3-T01`).
##
## Gathered here rather than at each of the four declaration sites, for the
## reason `_my_rank` gives one function down: four copies of a lookup is four
## places to forget it.
## **Say again what this peer is** (ADR-148).
##
## The declaration is made once, in `_ready`, because a level beginning is when
## a peer arrives and nothing about it changes inside one. Swearing a class at
## the fire is the exception `M3-T02` created and nobody joined up: the Legacy
## screen chooses who you are **next** after the camp has already built a body,
## so from that moment the session's table is a life out of date.
##
## Routed exactly like `_ready`'s call — locally on the host, by RPC from a
## client — because the host owns the table and a client writing its own would
## be the fault ADR-121 avoided for the class arriving through a second door.
func redeclare() -> void:
	if multiplayer.is_server():
		declare_descent(_my_rank(), String(GameState.class_id),
			_my_effects(), _my_worn(), _my_bag(), _my_wound())
	else:
		declare_descent.rpc_id(HOST_PEER, _my_rank(),
			String(GameState.class_id), _my_effects(), _my_worn(),
			_my_bag(), _my_wound())


## **Put back what this peer carried down** (`M4-T01`, ADR-185).
##
## Host-only, because the host owns every body's inventory and health — a peer
## restoring its own would be overwritten by the next `_push_bag` anyway, which
## is the quiet kind of wrong.
##
## Called from **both** the declaration and the spawn, because either can arrive
## first (ADR-122) and both orders have to end in the same place. Safe twice:
## `unpack` replaces the bag rather than adding to it, so the second call is the
## same bag, not a doubled one.
func _hand_down(body: Player, peer: int) -> void:
	if not multiplayer.is_server() or body == null:
		return
	var rows: Array = _bags.get(peer, []) as Array
	if not rows.is_empty():
		body.inventory.unpack(rows)
	# **`DES-009` is why this is not optional.** `Health`'s own header calls
	# non-regenerating health *"the most important single decision in this
	# document after the thesis"* and says adding regeneration needs an ADR —
	# and a floor transition that handed back a full pool is regeneration with a
	# staircase in front of it. `UNHURT` is the fresh-run case, where the body's
	# own maximum is right.
	var hurt: float = float(_wounds.get(peer, RunFile.UNHURT))
	if hurt > 0.0:
		body.health.current = minf(hurt, body.health.maximum)


func _my_worn() -> Dictionary:
	return GameState.worn.duplicate()


## What this process is bringing onto the floor it is arriving at, straight off
## its own run file. Empty and `UNHURT` on floor 0, and in any process with no
## run open at all — which is every probe.
func _my_bag() -> Array:
	return RunFile.bag()


func _my_wound() -> float:
	return RunFile.wound()


func _my_effects() -> PackedStringArray:
	var tags := PackedStringArray()
	for id: StringName in GameState.taken:
		var node: AspectNode = AspectCatalogue.by_id(id)
		if node == null:
			continue
		for tag: StringName in node.effect_tags:
			if not tags.has(String(tag)):
				tags.append(String(tag))
	return tags


func _my_rank() -> int:
	return _declared_rank if _declared_rank > 0 else GameState.pact_rank


## Something in the air (`M3-T11`, ADR-123).
##
## Through the spawner like every other actor, so a client sees the arrow that
## wounds it rather than a body losing health for no visible reason — which is
## `PRO-005` §5's unexplainable death in its most literal form.
##
## The whole flight is in the payload because an arrow's entire life is decided
## the instant it is loosed: nothing steers it, so every peer can build the same
## one and only the host needs to resolve what it meets.
func spawn_arrow(at: Vector3, travel: Vector3, trait_of: RangedTrait,
		shooter: int) -> Arrow:
	if not is_host():
		return null
	var made: Arrow = _spawner.spawn({
		"kind": "arrow", "index": _next_arrow, "at": at,
		"travel": travel, "speed": trait_of.arrow_speed,
		"damage": trait_of.damage, "clamor": trait_of.clamor_hit,
		"range": trait_of.arrow_range, "shooter": shooter,
	}) as Arrow
	_next_arrow += 1
	if made != null:
		made.fly_with(floor_field())
	return made


## The level hands over the field it built. Called beside `hunt_with`, because
## the two are the same sentence: this is the floor, and this is what noise on
## it goes into.
func hunt_in(field: ClamorField) -> void:
	_floor_field = field


## Null once the level that owned it is gone, which is the only reason this is a
## function. An autoload outlives every level it ever sees, so a bare reference
## here is a dangling pointer waiting for the first descent after the second.
func floor_field() -> ClamorField:
	return _floor_field if is_instance_valid(_floor_field) else null


## A trap on the floor (`M3-T11`, ADR-123).
##
## Through the spawner like every other actor, so a client watching a teammate
## set one can see where it is — a trap only the host can see is a thing that
## stops enemies for no reason on every other screen.
func _on_player_loosed(at: Vector3, travel: Vector3, kit: RangedTrait,
		shooter: int) -> void:
	spawn_arrow(at, travel, kit, shooter)


## **One live at a time.** Read off the host's own scene tree rather than from a
## count, so there is no tally that can disagree with the world — and freeing
## the old one here despawns it on every peer, because that is what the spawner
## does with a node it made.
## A Wing keystone escaped, and left the noise where the blow landed.
func _on_player_roared(at: Vector3, amount: float) -> void:
	var field: ClamorField = floor_field()
	if field != null:
		field.deposit(at, amount)


func _on_player_set_snare(at: Vector3, placer: int) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"snares"):
		var old := node as Snare
		if old != null and old.placer == placer:
			old.queue_free()
	spawn_snare(at, placer)


func spawn_snare(at: Vector3, placer: int) -> Snare:
	if not is_host():
		return null
	var tuning: TuningProfile = Config.tuning
	var made: Snare = _spawner.spawn({
		"kind": "snare", "index": _next_snare, "at": at, "placer": placer,
		"hold": tuning.snare_hold_seconds, "clamor": tuning.snare_clamor_trigger,
	}) as Snare
	_next_snare += 1
	if made != null:
		made.fly_with(floor_field())
	return made


func _build_snare(payload: Dictionary) -> Node:
	var made := Snare.new()
	made.name = "snare_%d" % int(payload["index"])
	made.position = payload["at"] as Vector3
	made.placer = int(payload["placer"])
	made.hold_seconds = float(payload["hold"])
	made.clamor_trigger = float(payload["clamor"])
	made.configure_replication()
	return made


func _build_arrow(payload: Dictionary) -> Node:
	var made := Arrow.new()
	made.name = "arrow_%d" % int(payload["index"])
	made.position = payload["at"] as Vector3
	# Every field before `add_child`, so `_ready` sees a fully-formed arrow and
	# every peer derives the same one from the same packet.
	made.travel = (payload["travel"] as Vector3).normalized()
	made.speed = float(payload["speed"])
	made.damage = float(payload["damage"])
	made.clamor_hit = float(payload["clamor"])
	made.left = float(payload["range"])
	made.shooter = int(payload["shooter"])
	return made
