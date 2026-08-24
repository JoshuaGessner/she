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
## From `NetPlan`, which owns the number. Two copies is how they diverge.
const DEFAULT_PORT: int = NetPlan.DEFAULT_PORT
## Where a failed or lost connection lands. Never a quit — see `_give_up`.
const MENU_SCENE: String = "res://ui/main_menu.tscn"
## How long a client waits before deciding nobody is there ⟨tune⟩. Long enough
## for a slow link, short enough that a mistyped address is a small mistake.
const CONNECT_TIMEOUT_MSEC: int = 8000
const LOOPBACK: String = "127.0.0.1"
## Sentinel for "wherever the next spawn mark is". A real position, never used
## as one, because `Vector3` has no null.
const NO_PLACE: Vector3 = Vector3(-99999.0, -99999.0, -99999.0)

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://actors/enemies/enemy.tscn")

signal player_spawned(player: Player)
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
## When a client stops waiting, or 0 when it is not waiting. See `_start_client`.
var _waiting_until: int = 0
var _waiting_layer: CanvasLayer = null

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
		if multiplayer.is_server():
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
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_log("hosting on %d, up to %d client(s), input=%s" % [_port, MAX_CLIENTS, _device])
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
	_give_up("No answer from %s:%d after %d seconds. Check the address and "
		% [_address, _port, CONNECT_TIMEOUT_MSEC / 1000]
		+ "that the host has opened the Threshold.")


func _on_connected() -> void:
	# The client spawns nothing. Its own body arrives from the host like every
	# other actor, which is what makes "the host owns the world" true from the
	# first frame instead of true after a handshake.
	_log("connected as peer %d" % multiplayer.get_unique_id())
	_waiting_until = 0
	_hide_waiting()


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
	_give_up("No answer from %s:%d. Check the address, and that the host has "
		% [_address, _port] + "opened the Threshold.")


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



func _on_peer_connected(peer: int) -> void:
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


# ── spawning ──────────────────────────────────────────────────────────────


## The one place an actor is created, on every peer.
##
## Runs on the host when it calls `spawn()`, and on each client when the spawn
## packet arrives — with the *same* payload, so both sides derive the same node
## name and the same authority without either being told. Names have to match
## across peers or every RPC and every synchroniser addresses a different node.
func _spawn_actor(data: Variant) -> Node:
	var payload: Dictionary = data as Dictionary
	match String(payload["kind"]):
		"player":
			return _build_player(payload)
		"world_item":
			return _build_world_item(payload)
		"hunter":
			return _build_hunter(payload)
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
	# Before `add_child`, so `_ready` already knows whether it is looking at
	# its own body. Deciding afterwards means one frame of a remote player
	# holding the camera and capturing the mouse.
	player.configure_replication(peer)
	# Signals up, calls down (`TEC-002`): a player putting something down says
	# so, and the session — which owns the spawner — is what makes it exist.
	# `spawn_world_item` is host-only, so a client's copy of this connection is
	# inert rather than wrong.
	player.dropped.connect(_on_player_dropped)
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
	}) as Player
	if player != null:
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
		bound_to: int = 0) -> WorldItem:
	if not is_host():
		return null
	var made: WorldItem = _spawner.spawn({
		"kind": "world_item", "index": _next_item, "item": item,
		"at": at, "yaw": yaw, "launch": launch, "disturbed": disturbed,
		"bound": bound_to,
	}) as WorldItem
	_next_item += 1
	return made


func _on_player_dropped(item: ItemInstance, at: Vector3, yaw: float,
		launch: Vector3) -> void:
	# Anything a player set down counts as disturbed, thrown or not: a panic
	# dump is as much an offering as a bait, and the Hunter stopping for the
	# pile you abandoned is `DES-005`'s counter-play paying out.
	#
	# A put-down ember is still somebody's. Losing the binding here would turn
	# a friend into scenery the moment their rescuer set them down for a fight.
	spawn_world_item(item.definition.id, at, yaw, launch, true, item.bound_to)


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


func player_for(peer: int) -> Player:
	return _actors.get_node_or_null("player_%d" % peer) as Player


## The body this process is playing. Every peer has exactly one; on the host
## that is peer 1's, on a client its own.
func local_player() -> Player:
	return player_for(multiplayer.get_unique_id())


func players() -> Array[Player]:
	var found: Array[Player] = []
	for node: Node in get_tree().get_nodes_in_group("player"):
		found.append(node as Player)
	return found


func _log(message: String) -> void:
	print("[coop:%s] %s" % [_role, message])
