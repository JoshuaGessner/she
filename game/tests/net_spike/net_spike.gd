class_name NetSpike
extends Node

## `M1-T06` — go/no-go on Godot's high-level multiplayer (`TEC-004`).
##
## TEC-004's risk register names `MultiplayerSynchronizer` performance at high
## object counts as "the assumption most likely to be wrong", and PRO-001 makes
## answering it a gate before anything is built on top. This harness answers it
## with a measurement rather than an impression.
##
## Why the headline metric is per-entity update rate, not bandwidth: a host that
## quietly degrades to 4 Hz per entity looks *cheap* on bandwidth and is unusable
## in a game whose core tension is hearing something move toward you through a
## wall (`DES-005`). Bytes are the budget; update rate is the experience. We
## measure both, and neither alone decides the gate.
##
## Roles are separate OS processes, driven by tools/run_net_spike.sh:
##   host   — simulates every agent and replicates to clients
##   client — connects and counts what actually arrives
##
## Agents are deliberately dumb Node3Ds moved by the host. This isolates the
## replication path: any cost measured here is the network layer, not AI.

const PORT: int = 47017
const LOOPBACK: String = "127.0.0.1"

## Seconds discarded at the start of the measurement window. The spawn burst and
## ENet's initial window growth are real costs, but they are not the steady state
## the gate is about, so they are reported separately rather than averaged in.
const WARMUP_SECONDS: float = 3.0

## How far apart agents sit, and how fast they orbit. Continuous motion is the
## worst case for replication: nothing is ever unchanged, so no update can be
## skipped. A real floor would be kinder than this.
const AGENT_SPACING: float = 4.0
const ORBIT_RADIUS: float = 3.0
const ORBIT_SPEED: float = 1.5

const DEFAULTS: Dictionary = {
	"role": "host",
	"entities": 150,   # TEC-001's per-floor AI budget
	"peers": 3,        # 4 players = host + 3 clients
	"seconds": 25.0,
	"rate": 20.0,      # synchroniser Hz
	"active": -1,      # moving agents; -1 = all. Models TEC-001's LOD split.
	"compress": 0,     # ENet range coder on the whole host
	"out": "",
}

var _role: String = "host"
var _entities: int = 150
var _peers: int = 3
var _seconds: float = 25.0
var _rate: float = 20.0
var _active: int = -1
var _compress: bool = false
var _out: String = ""

var _agents: Array[Node3D] = []
var _elapsed: float = 0.0
var _running: bool = false
var _finished: bool = false

# Sampled once per second; the summary is computed over post-warmup samples.
var _samples: Array[Dictionary] = []
var _sample_clock: float = 0.0
var _sync_events: int = 0
var _sync_events_at_sample: int = 0
var _spawn_msec: int = 0
var _connect_msec: int = 0

@onready var _world: Node = $World
@onready var _spawner: MultiplayerSpawner = $AgentSpawner


func _ready() -> void:
	_parse_args()
	_spawner.spawn_function = _spawn_agent

	if _role == "host":
		_start_host()
	else:
		_start_client()


func _parse_args() -> void:
	var parsed: Dictionary = DEFAULTS.duplicate()
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var pair: PackedStringArray = arg.substr(2).split("=", true, 1)
		if parsed.has(pair[0]):
			parsed[pair[0]] = pair[1]
	_role = str(parsed["role"])
	_entities = int(parsed["entities"])
	_peers = int(parsed["peers"])
	_seconds = float(parsed["seconds"])
	_rate = float(parsed["rate"])
	_active = int(parsed["active"])
	if _active < 0:
		_active = _entities
	_compress = int(parsed["compress"]) != 0
	_out = str(parsed["out"])
	Engine.physics_ticks_per_second = 60


func _configure_transport(peer: ENetMultiplayerPeer) -> void:
	# Must match on both ends or packets are unreadable, so it is applied in one
	# place for both roles.
	if _compress:
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)


# ── roles ─────────────────────────────────────────────────────────────────


func _start_host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(PORT, _peers)
	if err != OK:
		_abort("create_server failed: %d" % err)
		return
	_configure_transport(peer)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	_log("host listening on %d, waiting for %d peer(s)" % [PORT, _peers])


func _start_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(LOOPBACK, PORT)
	if err != OK:
		_abort("create_client failed: %d" % err)
		return
	_configure_transport(peer)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.server_disconnected.connect(_finish)
	_spawner.spawned.connect(_on_agent_spawned)


func _on_peer_connected(_id: int) -> void:
	if multiplayer.get_peers().size() < _peers or _running:
		return
	# Every client is in. Spawn the world and start the clock together.
	var began: int = Time.get_ticks_msec()
	for i: int in range(_entities):
		_agents.append(_spawner.spawn(i) as Node3D)
	_spawn_msec = Time.get_ticks_msec() - began
	_log("spawned %d agents in %d ms" % [_entities, _spawn_msec])
	_begin_measuring()


func _on_connected() -> void:
	_connect_msec = Time.get_ticks_msec()
	_begin_measuring()


func _on_agent_spawned(node: Node) -> void:
	# Count deliveries, not bytes: this is what "the world is still moving"
	# actually means on a client.
	var sync := node.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
	# ALWAYS properties arrive on `synchronized`, ON_CHANGE ones on
	# `delta_synchronized`. Listening to only the first reads as a total
	# replication failure when the transport is in fact working perfectly.
	sync.synchronized.connect(_on_agent_synchronized)
	sync.delta_synchronized.connect(_on_agent_synchronized)


func _on_agent_synchronized() -> void:
	_sync_events += 1


# ── the agents ────────────────────────────────────────────────────────────


func _spawn_agent(data: Variant) -> Node:
	var index: int = int(data)
	var agent := Node3D.new()
	agent.name = "agent_%03d" % index
	agent.position = _agent_origin(index)

	var config := SceneReplicationConfig.new()
	config.add_property(^".:position")
	config.property_set_spawn(^".:position", true)
	# ON_CHANGE, not ALWAYS: an idle enemy should cost nothing. With every agent
	# moving the two are identical, which is why `--active` exists — it is the
	# only way to measure the LOD split TEC-001 actually specifies.
	config.property_set_replication_mode(
		^".:position", SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE
	)

	var sync := MultiplayerSynchronizer.new()
	sync.name = "MultiplayerSynchronizer"
	sync.replication_config = config
	# Two intervals, not one. ON_CHANGE properties travel the *delta* channel,
	# which has its own `delta_interval` defaulting to 0.0 — every network
	# frame. Setting only `replication_interval` leaves deltas running at the
	# physics rate and silently costs ~4x the bandwidth (measured: 528 -> 2358
	# kbps/client at 150 entities). Set both.
	sync.replication_interval = 1.0 / _rate
	sync.delta_interval = 1.0 / _rate
	agent.add_child(sync)
	return agent


func _agent_origin(index: int) -> Vector3:
	# A 13-wide grid: no significance beyond keeping 150 agents in a squarish
	# block so relevance filtering has nothing accidental to exploit.
	@warning_ignore("integer_division")
	var row: int = index / 13
	var col: int = index % 13
	return Vector3(col * AGENT_SPACING, 0.0, row * AGENT_SPACING)


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta
	_sample_clock += delta

	# Host-authoritative motion. Clients never move an agent themselves.
	if _role == "host":
		for i: int in range(mini(_active, _agents.size())):
			var phase: float = _elapsed * ORBIT_SPEED + float(i)
			var origin: Vector3 = _agent_origin(i)
			_agents[i].position = origin + Vector3(
				cos(phase) * ORBIT_RADIUS, 0.0, sin(phase) * ORBIT_RADIUS
			)

	if _sample_clock >= 1.0:
		_take_sample(_sample_clock)
		_sample_clock = 0.0

	if _elapsed >= _seconds:
		_finish()


# ── measurement ───────────────────────────────────────────────────────────


func _begin_measuring() -> void:
	_running = true
	_elapsed = 0.0
	_sample_clock = 0.0
	# `pop_statistic` reads *and clears*, so every later read is already the
	# traffic since the previous sample. This first pair discards the handshake.
	_pop_traffic()


func _pop_traffic() -> Vector2:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	var enet_host: ENetConnection = enet.get_host()
	return Vector2(
		enet_host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA),
		enet_host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
	)


func _take_sample(window: float) -> void:
	var traffic: Vector2 = _pop_traffic()
	var syncs: int = _sync_events - _sync_events_at_sample

	_samples.append({
		"at": _elapsed,
		"kbps_up": traffic.x * 8.0 / 1000.0 / window,
		"kbps_down": traffic.y * 8.0 / 1000.0 / window,
		# Delivery rate per *moving* entity — the number the gate turns on.
		# Idle agents are divided out, or LOD runs would flatter themselves.
		"updates_hz": (float(syncs) / float(_active) / window) if _active > 0 else 0.0,
		"frame_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
	})
	_sync_events_at_sample = _sync_events


func _summarise() -> Dictionary:
	var steady: Array[Dictionary] = _samples.filter(
		func(s: Dictionary) -> bool: return float(s["at"]) >= WARMUP_SECONDS
	)
	if steady.is_empty():
		steady = _samples

	var summary: Dictionary = {
		"role": _role,
		"entities": _entities,
		"active": _active,
		"compress": _compress,
		"peers": _peers,
		"sync_rate_hz": _rate,
		"seconds": _elapsed,
		"steady_samples": steady.size(),
		"spawn_msec": _spawn_msec,
		"godot": Engine.get_version_info()["string"],
	}
	for key: String in ["kbps_up", "kbps_down", "updates_hz", "frame_ms", "physics_ms"]:
		var values: Array = steady.map(func(s: Dictionary) -> float: return float(s[key]))
		values.sort()
		summary[key + "_mean"] = _mean(values)
		# "Worst" is the high end for costs and the low end for delivery rate.
		# Never null: a run that sampled nothing must read as a failure, not as
		# a missing field the reader can mistake for "fine".
		if values.is_empty():
			summary[key + "_worst"] = 0.0
		elif key == "updates_hz":
			summary[key + "_worst"] = values.front()
		else:
			summary[key + "_worst"] = values.back()
	summary["samples"] = _samples
	return summary


func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for v: float in values:
		total += v
	return total / float(values.size())


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_running = false
	var summary: Dictionary = _summarise()
	if _out.is_empty():
		print(JSON.stringify(summary, "\t"))
	else:
		var file: FileAccess = FileAccess.open(_out, FileAccess.WRITE)
		if file == null:
			_log("could not write %s (%d)" % [_out, FileAccess.get_open_error()])
		else:
			file.store_string(JSON.stringify(summary, "\t"))
			file.close()
	_log("%s done: %.1f kbps up, %.1f Hz/entity" % [
		_role, float(summary.get("kbps_up_mean", 0.0)), float(summary.get("updates_hz_mean", 0.0)),
	])
	get_tree().quit()


func _log(message: String) -> void:
	print("[net_spike:%s] %s" % [_role, message])


func _abort(message: String) -> void:
	printerr("[net_spike:%s] %s" % [_role, message])
	get_tree().quit(1)
