class_name Pinger
extends Node

## **The ping** (`M4-T05`, ADR-244, `DES-012`) — the party's silent channel.
##
## `DES-012` calls it essential: *mark loot, enemies, routes, extraction*. And
## ADR-050 made the ping wheel and the silent gestures one system. So one key,
## by the developer's calls: **a tap marks what you are looking at**, and **a
## hold opens four gestures** — go, stop, danger, regroup — chosen by where the
## look is pushed and sent on release. Apex Legends is the reference: one
## context-sensitive press covers almost everything a squad needs to say.
##
## ## Silent to the dungeon
##
## A ping is party talk, and `DES-012` will not punish voice chat — so a player
## with no microphone must not be the one who pays for talking. Nothing here
## touches a `ClamorSource` or the field, and the sound it makes is on the
## interface bus.
##
## ## One mark a body, held by the body
##
## Every player's copy has one of these at the same path, and it holds that
## player's **one** current mark, which is what makes *one mark per player*
## true by construction. The owner decides what was marked and says so to every
## peer; a mark changes nothing in the world, so there is nothing for the host
## to adjudicate — only that the sender is the body's own peer (`TEC-004`'s
## guard on every `@rpc`). Every peer ages its copies itself, and
## `PingLayer` draws them.

enum Kind { SPOT, LOOT, ENEMY, WAY, GO, STOP, DANGER, REGROUP }

const GROUP: StringName = &"pingers"
## The gestures, in wheel order: up, right, down, left.
const WHEEL: Array[Kind] = [Kind.GO, Kind.DANGER, Kind.STOP, Kind.REGROUP]
## How far the look has to be pushed before the wheel names a gesture, in the
## wheel's own units: mouse pixels, or a stick's full throw at 1.
const WHEEL_DEADZONE: float = 24.0
const WHEEL_REACH: float = 80.0
const STICK_DEADZONE: float = 0.5
## Where a mark stands above what it marks, by kind — over a head, over a thing
## on the floor, up the Shaft's column.
const LIFT: Dictionary = {
	Kind.SPOT: 0.3, Kind.LOOT: 0.6, Kind.ENEMY: 2.3, Kind.WAY: 2.6,
	Kind.GO: 2.3, Kind.STOP: 2.3, Kind.DANGER: 2.3, Kind.REGROUP: 2.3,
}
const NAMES: Array[String] = ["spot", "loot", "enemy", "way", "go", "stop",
	"danger", "regroup"]

## True while the key is held past a tap: the look is steering the wheel.
var wheel_open: bool = false
## The current mark on this peer, or empty: `kind`, `at`, `target` (a path, or
## empty) and `left` seconds.
var mark: Dictionary = {}

var _eye: Camera3D = null
var _body: Node3D = null
var _held: float = -1.0
var _aim := Vector2.ZERO


func _ready() -> void:
	add_to_group(GROUP)


## Handed down by the body: whose pinger this is, and the camera it looks
## through (only the owner's copy uses the camera).
func serve(body: Node3D, camera: Camera3D) -> void:
	_body = body
	_eye = camera


## The body this pinger speaks for.
func owner_body() -> Node3D:
	return _body


## Owner-side, every physics frame: read the key, time the hold, and send what
## a release means. `allowed` is false while the body cannot act on the world —
## a bag open, a menu over it — and cancels a hold in progress.
func tick(delta: float, allowed: bool) -> void:
	if not allowed:
		_cancel()
		return
	if Input.is_action_just_pressed("ping"):
		_held = 0.0
		_aim = Vector2.ZERO
	if _held < 0.0:
		return
	_held += delta
	if Input.is_action_pressed("ping"):
		wheel_open = _held >= Config.tuning.ping_hold_seconds
		return
	if wheel_open:
		var chosen: int = gesture_for(_aim)
		if chosen >= 0:
			gesture(chosen)
	else:
		mark_what_is_seen()
	_cancel()


## The look, pushed while the wheel is open (mouse motion). Clamped, so the
## wheel answers direction rather than distance.
func steer(relative: Vector2) -> void:
	_aim = (_aim + relative).limit_length(WHEEL_REACH)


## The right stick while the wheel is open: its direction, when pushed.
func point(stick: Vector2) -> void:
	if stick.length() >= STICK_DEADZONE:
		_aim = stick.normalized() * WHEEL_REACH


## Which gesture a push names, or -1 inside the deadzone.
static func gesture_for(push: Vector2) -> int:
	if push.length() < WHEEL_DEADZONE:
		return -1
	# Up is negative y on a screen; the wheel's first slot is up.
	var turn: float = atan2(push.x, -push.y)
	var slot: int = posmod(int(round(turn / (TAU / 4.0))), 4)
	return WHEEL[slot]


## The gesture under the aim right now, or -1 — for the wheel to highlight.
func aimed() -> int:
	return gesture_for(_aim)


## **What is being looked at**, marked. The nearest thing to the aim inside the
## cone — an enemy, then loot, then the way on — that nothing solid hides;
## otherwise the point the look lands on; otherwise nothing.
func mark_what_is_seen() -> bool:
	if _eye == null or not _eye.is_inside_tree():
		return false
	var tuning: TuningProfile = Config.tuning
	var from: Vector3 = _eye.global_position
	var ahead: Vector3 = -_eye.global_transform.basis.z
	var cone: float = deg_to_rad(tuning.ping_cone_degrees)
	var best: Node3D = null
	var best_kind: int = Kind.SPOT
	var best_turn: float = cone
	for candidate: Array in _candidates():
		var thing := candidate[0] as Node3D
		var toward: Vector3 = thing.global_position + Vector3.UP * 0.5 - from
		var far: float = toward.length()
		if far > tuning.ping_range or far < 0.05:
			continue
		var turn: float = ahead.angle_to(toward)
		if turn > best_turn or not _clear(from, thing.global_position + Vector3.UP * 0.5):
			continue
		best = thing
		best_kind = int(candidate[1])
		best_turn = turn
	if best != null:
		send(best_kind, best.global_position, best.get_path())
		return true
	var ray := PhysicsRayQueryParameters3D.create(from, from + ahead * tuning.ping_range)
	ray.collision_mask = CollisionLayers.WORLD
	var hit: Dictionary = _eye.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return false
	send(Kind.SPOT, hit["position"] as Vector3, NodePath())
	return true


## A gesture, stood over the body that made it.
func gesture(kind: int) -> void:
	if _body == null:
		return
	send(kind, _body.global_position, _body.get_path())


## Say it to every peer, this one included.
func send(kind: int, at: Vector3, target: NodePath) -> void:
	_show.rpc(kind, at, target)


@rpc("any_peer", "call_local", "reliable")
func _show(kind: int, at: Vector3, target: NodePath) -> void:
	# Only the body's own peer speaks for it (`TEC-004`). A local call reports
	# sender 0 on some paths and the authority on others; both are this peer.
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	if kind < 0 or kind >= Kind.size() or not at.is_finite():
		return
	mark = {"kind": kind, "at": at, "target": target, "left": Config.tuning.ping_seconds}
	Foley.flat(self, Foley.Sound.PING, 1.0 if kind < Kind.GO else 0.85)
	print("[ping] %s marked %s at %.1f, %.1f" % [
		_body.name if _body != null else "?", NAMES[kind], at.x, at.z])


## Where the mark stands now, following what it marks while that exists.
func mark_position() -> Vector3:
	return (mark["at"] as Vector3) + Vector3.UP * float(LIFT[int(mark["kind"])])


func _process(delta: float) -> void:
	if mark.is_empty():
		return
	mark["left"] = float(mark["left"]) - delta
	if float(mark["left"]) <= 0.0:
		mark = {}
		return
	var path: NodePath = mark["target"]
	if path.is_empty():
		return
	var followed := get_node_or_null(path) as Node3D
	if followed != null and not followed.is_queued_for_deletion():
		mark["at"] = followed.global_position
	elif int(mark["kind"]) == Kind.LOOT:
		# Taken: the thing the mark was about is in somebody's bag now.
		mark = {}


## Everything a tap can be about, with what it would be called.
func _candidates() -> Array:
	var out: Array = []
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		# A corpse is not a threat to point at.
		var body := node as Enemy
		if body != null and body.state() == Enemy.State.DEAD:
			continue
		out.append([node, Kind.ENEMY])
	for node: Node in get_tree().get_nodes_in_group(&"hunters"):
		out.append([node, Kind.ENEMY])
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		out.append([node, Kind.LOOT])
	for node: Node in get_tree().get_nodes_in_group(Shaft.GROUP):
		out.append([node, Kind.WAY])
	return out.filter(func(row: Array) -> bool:
		return row[0] is Node3D and not (row[0] as Node).is_queued_for_deletion())


## Nothing solid between the eye and a point.
func _clear(from: Vector3, to: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(from, to)
	ray.collision_mask = CollisionLayers.WORLD
	return _eye.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _cancel() -> void:
	_held = -1.0
	wheel_open = false
	_aim = Vector2.ZERO
