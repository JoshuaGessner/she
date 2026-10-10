class_name Engagement
extends RefCounted
## **How a group fights one body** (ADR-391, `M4-T38`, `DES-013`).
##
## Every enemy used to decide alone: path to you, swing when in reach. So three
## Wretches arrived in a line and wound up together, and whichever stood behind
## you landed the blow you never saw. Two pieces, both on the host, both
## invisible as mechanisms and visible only as a fight that can be read:
##
## - **Tokens, per target** (DOOM 2016, *Embracing Push Forward Combat*, GDC
##   2018). A melee body must hold one of `engage_tokens` to wind up on a player,
##   and gives it back when its blow is over. A body in the player's view is
##   offered one before a body behind, so a blow from behind is never the first.
## - **The ring** (Arkham's freeflow, the Souls games). A body that wants a token
##   and has none holds just outside its reach on its own bearing round the
##   player, spread from the others, facing in. That is what a crowd looks like
##   when it is dangerous and not unfair.
##
## Static and keyed by the target's instance, because the pool belongs to the
## body being fought and nothing about it needs a node: no replication (a client
## sees bodies move and wind up, which it already receives), no scene, nothing
## to free. Every read purges what has died or gone, so a stale entry costs a
## frame of bookkeeping, never a token held by a corpse.

## Holders per pool: `_key(target, missile)` → Array of `Enemy`.
static var _holders: Dictionary = {}
## Each waiting body's claimed bearing: Enemy → [target id, radians].
static var _bearing: Dictionary = {}

## Bearings tried each side of a body's own, in steps of this many degrees.
const BEARING_STEP: float = 10.0


## May `body` begin a blow on `target` now? True if it already holds a token or
## is given one. `near` is how close a rival must be to count as closing on the
## same body. Host only.
static func take(body: Enemy, target: Node3D, missile: bool, tuning: TuningProfile,
		near: float) -> bool:
	var key: int = _key(target, missile)
	var holders: Array = _live_holders(key, target)
	if holders.has(body):
		return true
	var cap: int = tuning.engage_missile_tokens if missile else tuning.engage_tokens
	if holders.size() >= cap:
		return false
	# **In view first.** Refused while a body the player *can* see is closing
	# on them without a turn of its own — so the first blow of a fight comes
	# from in front, and a body behind still fights a player who turns their
	# back on an otherwise empty room.
	if not in_view(target, body.global_position, tuning):
		for node: Node in body.get_tree().get_nodes_in_group(&"enemies"):
			var other := node as Enemy
			if other == null or other == body or holders.has(other) \
					or other.target() != target or not other.is_hunting() \
					or other.turned.mood != Turned.Mood.NONE:
				continue
			if other.global_position.distance_to(target.global_position) <= near \
					and in_view(target, other.global_position, tuning):
				return false
	holders.append(body)
	_holders[key] = holders
	_bearing.erase(body)
	return true


## Give back whatever `body` holds or claims, everywhere. Host only.
static func release(body: Enemy) -> void:
	for key: int in _holders.keys():
		(_holders[key] as Array).erase(body)
	_bearing.erase(body)


## Does `body` hold a token on anyone?
static func holds(body: Enemy) -> bool:
	for key: int in _holders.keys():
		if (_holders[key] as Array).has(body):
			return true
	return false


## Is `point` inside the cone `target` is looking down?
static func in_view(target: Node3D, point: Vector3, tuning: TuningProfile) -> bool:
	var look: Vector3 = -target.global_transform.basis.z
	look.y = 0.0
	var to: Vector3 = point - target.global_position
	to.y = 0.0
	if to.length() < 0.01 or look.length() < 0.01:
		return true
	return look.normalized().dot(to.normalized()) >= cos(deg_to_rad(tuning.engage_view_half_angle))


## **Where `body` waits** round `target`: `radius` out, on the free bearing
## nearest its own, at least `engage_ring_spacing` from every other body waiting
## on or striking that target. Pulled in short of a wall between the two, so a
## ring point is never somewhere the body cannot stand and see.
static func ring_point(body: Enemy, target: Node3D, radius: float, tuning: TuningProfile) -> Vector3:
	var key: int = target.get_instance_id()
	var centre: Vector3 = target.global_position
	var mine: float = _bearing_of(body.global_position, centre)
	var taken: Array[float] = []
	for other: Variant in _bearing.keys():
		if other == body:
			continue
		if not is_instance_valid(other) or (other as Enemy).target() != target \
				or (other as Enemy).state() == Enemy.State.DEAD:
			_bearing.erase(other)
			continue
		var entry: Array = _bearing[other]
		if int(entry[0]) == key:
			taken.append(float(entry[1]))
	for holder: Enemy in _live_holders(_key(target, false), target):
		if holder != body:
			taken.append(_bearing_of(holder.global_position, centre))
	var spacing: float = deg_to_rad(tuning.engage_ring_spacing)
	var chosen: float = mine
	var found: bool = false
	for step: int in range(0, int(180.0 / BEARING_STEP) + 1):
		for side: float in [1.0, -1.0]:
			var bearing: float = mine + side * deg_to_rad(BEARING_STEP * step)
			if _clear_of(bearing, taken, spacing):
				chosen = bearing
				found = true
				break
			if step == 0:
				break
		if found:
			break
	_bearing[body] = [key, chosen]
	var out := Vector3(cos(chosen), 0.0, sin(chosen))
	var point: Vector3 = centre + out * radius
	var from: Vector3 = centre + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, point + Vector3.UP)
	query.collision_mask = CollisionLayers.WORLD
	var hit: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var short: float = maxf(0.0, from.distance_to(hit["position"]) - NAV_CLEARANCE)
		point = centre + out * short
	point.y = body.global_position.y
	return point


## How far short of a wall a ring point stands: a body's half-width and a margin.
const NAV_CLEARANCE: float = 0.6


static func _key(target: Node3D, missile: bool) -> int:
	return target.get_instance_id() * 2 + (1 if missile else 0)


static func _bearing_of(point: Vector3, centre: Vector3) -> float:
	var flat: Vector3 = point - centre
	return atan2(flat.z, flat.x) if Vector2(flat.x, flat.z).length() > 0.01 else 0.0


static func _clear_of(bearing: float, taken: Array[float], spacing: float) -> bool:
	for other: float in taken:
		if absf(angle_difference(bearing, other)) < spacing:
			return false
	return true


## The holders still worth counting: alive, still after this target.
static func _live_holders(key: int, target: Node3D) -> Array:
	var kept: Array = []
	for holder: Variant in _holders.get(key, []):
		if is_instance_valid(holder) and (holder as Enemy).state() != Enemy.State.DEAD \
				and (holder as Enemy).target() == target:
			kept.append(holder)
	_holders[key] = kept
	return kept
