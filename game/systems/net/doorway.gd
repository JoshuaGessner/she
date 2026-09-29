class_name Doorway
extends Node

## Scene admission before any gameplay packet (ADR-271).
## A per-scene RPC cannot redirect a peer in another scene. SceneMultiplayer's
## authentication stage holds replication, RPCs and relay announcements until
## both ends confirm the scene and expedition. This is readiness, not identity
## authentication. The existing connection is still replaced when changing scene.

const NAME: StringName = &"Doorway"
const FLOOR_SCENE: String = "res://levels/room_set/room_set.tscn"
signal called_down(run_seed: int, floor_index: int)

static var _here: Doorway = null
var _api: SceneMultiplayer = null
var _scene: String = ""


static func of(tree: SceneTree) -> Doorway:
	if _here != null and is_instance_valid(_here):
		return _here
	if tree == null or tree.root == null:
		return null
	var made := Doorway.new()
	made.name = NAME
	_here = made
	tree.root.add_child.call_deferred(made)
	return made


## Install before a transport is assigned. This node outlives each session,
## so the API never retains a callback to a freed level between doorways.
func configure(api: SceneMultiplayer, scene: String, timeout: float) -> void:
	_api = api
	_scene = scene
	_api.auth_callback = _receive_admission
	_api.auth_timeout = timeout
	if not _api.peer_authenticating.is_connected(_send_admission):
		_api.peer_authenticating.connect(_send_admission)


func _place() -> Dictionary:
	return {"scene": _scene,
		"seed": RunFile.seed_of() if _scene == FLOOR_SCENE else 0,
		"floor": RunFile.floor_index() if _scene == FLOOR_SCENE else 0}


func _send_admission(peer: int) -> void:
	_api.send_auth(peer, var_to_bytes(_place()))


func _receive_admission(peer: int, packet: PackedByteArray) -> void:
	var decoded: Variant = bytes_to_var(packet)
	if not decoded is Dictionary:
		return
	var place: Dictionary = decoded as Dictionary
	if place == _place():
		_api.complete_auth(peer)
	elif not _api.is_server() and peer == 1 \
			and place.get("scene", "") == FLOOR_SCENE \
			and place.get("seed") is int and place.get("floor") is int \
			and int(place["floor"]) >= 0 and int(place["floor"]) <= RunFile.LAST_FLOOR:
		# The session receives this deferred, outside the engine's packet loop.
		called_down.emit(int(place["seed"]), int(place["floor"]))
