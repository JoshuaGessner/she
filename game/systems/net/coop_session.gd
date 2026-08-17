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
const DEFAULT_PORT: int = 47018
const LOOPBACK: String = "127.0.0.1"

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://actors/enemies/enemy.tscn")

signal player_spawned(player: Player)
signal player_left(peer: int)

## Where each successive player starts. Cycled, so a fourth player in a
## three-point level stands on the first point rather than at the origin.
## Levels set this before adding the session to the tree.
var spawn_points: Array[Vector3] = [Vector3.ZERO]

var _role: String = "solo"
var _address: String = LOOPBACK
var _port: int = DEFAULT_PORT
var _device: String = InputDevices.ALL
var _next_enemy: int = 0
var _next_spawn: int = 0
## Counts every item ever spawned, and never counts back down. Node names have
## to agree across peers, and reusing an index after something was picked up
## would give a new item the name of one a client is still despawning.
var _next_item: int = 0

@onready var _actors: Node3D = $Actors
@onready var _spawner: MultiplayerSpawner = $Spawner


func _ready() -> void:
	_device = InputDevices.restrict_from_cmdline()
	_parse_args()
	# Set on every peer before any spawn packet can arrive: a client that has
	# not been told how to build an actor drops the spawn silently, and the
	# symptom is an empty world rather than an error.
	_spawner.spawn_function = _spawn_actor

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
			_spawn_player(HOST_PEER)


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--host":
			_role = "host"
		elif arg.begins_with("--join"):
			_role = "client"
			if arg.contains("="):
				_address = arg.split("=", true, 1)[1]
		elif arg.begins_with("--port="):
			_port = int(arg.split("=", true, 1)[1])


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
		push_error("CoopSession: create_server(%d) failed: %d" % [_port, err])
		return
	_configure(peer)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_log("hosting on %d, up to %d client(s), input=%s" % [_port, MAX_CLIENTS, _device])
	_spawn_player(HOST_PEER)


func _start_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(_address, _port)
	if err != OK:
		push_error("CoopSession: create_client(%s:%d) failed: %d" % [_address, _port, err])
		return
	_configure(peer)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_host_lost)
	_log("joining %s:%d, input=%s" % [_address, _port, _device])


func _on_connected() -> void:
	# The client spawns nothing. Its own body arrives from the host like every
	# other actor, which is what makes "the host owns the world" true from the
	# first frame instead of true after a handshake.
	_log("connected as peer %d" % multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	push_error("CoopSession: could not reach a host at %s:%d" % [_address, _port])
	get_tree().quit(1)


## The host going away is `DES-012`'s forced extraction, and forced extraction
## is `M2-T04`/`M2-T05`. There is no run state to rescue at M1, so the honest
## behaviour is to say so and stop — not to leave a client walking around a
## world that nobody is simulating any more.
func _on_host_lost() -> void:
	_log("host disconnected — forced extraction is M2-T05; ending the session")
	get_tree().quit()


func _on_peer_connected(peer: int) -> void:
	_log("peer %d joined" % peer)
	_spawn_player(peer)


func _on_peer_disconnected(peer: int) -> void:
	_log("peer %d left" % peer)
	var player: Player = player_for(peer)
	if player != null:
		player.queue_free()
	player_left.emit(peer)


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
		_:
			return _build_enemy(payload)


func _build_player(payload: Dictionary) -> Node:
	var peer: int = int(payload["peer"])
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.name = "player_%d" % peer
	player.position = payload["at"] as Vector3
	player.rotation.y = float(payload["yaw"])
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
	item.position = payload["at"] as Vector3
	item.rotation.y = float(payload["yaw"])
	return item


func _spawn_player(peer: int) -> void:
	if not is_host():
		return
	# A counter rather than the current peer count: after someone disconnects
	# and someone else joins, a count would put the new arrival on an occupied
	# point, and two players standing inside each other on spawn reads as a
	# replication bug rather than as arithmetic.
	var at: Vector3 = spawn_points[_next_spawn % spawn_points.size()]
	_next_spawn += 1
	var player: Player = _spawner.spawn({
		"kind": "player", "peer": peer, "at": at, "yaw": 0.0,
	}) as Player
	if player != null:
		player_spawned.emit(player)


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
func spawn_world_item(item: StringName, at: Vector3, yaw: float = 0.0) -> WorldItem:
	if not is_host():
		return null
	var made: WorldItem = _spawner.spawn({
		"kind": "world_item", "index": _next_item, "item": item,
		"at": at, "yaw": yaw,
	}) as WorldItem
	_next_item += 1
	return made


func _on_player_dropped(item: StringName, at: Vector3, yaw: float) -> void:
	spawn_world_item(item, at, yaw)


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
