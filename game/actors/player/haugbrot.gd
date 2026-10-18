class_name Haugbrot
extends Verb

## **Haugbrot** (ADR-382, `DES-011` §6) — the Haugbrjótr's verb, and only hers.
##
## > *"Grettir broke open the mound and went in, and it was dark and the smell
## > was not pleasant."* — Grettis saga, ch. 18
##
## Held at what is shut — a door locked against her, or barred from the wrong
## side — she breaks it in. The owner only asks; the host runs the clock, ends
## it on a step or a blow, and on the last second opens the door with a noise
## the whole floor hears. Greed is her strength, and the Hunt comes for it.
##
## **A component of the body** (B52), as `Seidr` is: the ask, the host-checked
## request, the clock and the rule for what may be broken are this file's.
## `Player` keeps `breaking`, which every peer draws, and the noise a broken
## thing makes, which is the body's to make (`broke`).

## Something gave under her hands (host): the body makes the noise of it.
signal broke

## Host-side: seconds left, the length, what is being broken, and the measure
## of movement a step breaks it off by.
var _left: float = 0.0
var _total: float = 0.0
var _what: NodePath = NodePath()
var _at: Vector3 = Vector3.ZERO
var _speed: float = 0.0
## Owner-side: the thing this body last asked to break, or empty.
var _asked: NodePath = NodePath()


## Whether a break is under way, on the host.
func working() -> bool:
	return _left > 0.0


## The owner's frame: the craft key held at what is shut is a request to break
## it — a door shut against her first, then a barrow, then the Hunter's hoard.
func ask(driving: bool, rummaging: bool) -> void:
	var target: NodePath = NodePath()
	if _owns(&"haugbrot") and driving \
			and Input.is_action_pressed("verb") and not _body.is_incapacitated() and not rummaging:
		var door: LockedDoor = _body.door_at_hand()
		var barrow: Barrow = barrow_at_hand()
		var hunter: Gullsjukr = hunter_at_hand()
		if door != null and door.refusal(_body) != &"":
			target = door.get_path()
		elif barrow != null:
			target = barrow.get_path()
		elif hunter != null:
			target = hunter.get_path()
	if target == _asked:
		return
	_asked = target
	if multiplayer.is_server():
		start(target)
	else:
		_request.rpc_id(Player.HOST_PEER, target)


@rpc("any_peer", "call_remote", "reliable")
func _request(target: NodePath) -> void:
	if _from_owner():
		start(target)


## Host-side. Only a Haugbrjótr, only at a door that is shut against her (a
## door her key or her side would open is opened the ordinary way), and only
## within reach of it. An empty path stops her.
func start(target: NodePath) -> void:
	if target.is_empty():
		stop()
		return
	if not _owns(&"haugbrot") or not breakable(target) \
			or _body.is_incapacitated() or _left > 0.0:
		return
	# The Hunter's hoard comes loose faster than a door gives (ADR-403): it
	# is standing over her, and she has to beat its stoop.
	_total = maxf(Config.tuning.haugbrot_hunter_seconds
		if get_node_or_null(target) is Gullsjukr else Config.tuning.haugbrot_seconds, 0.01)
	_left = _total
	_what = target
	_at = _body.global_position
	_speed = 0.0
	_body.breaking = 0.0


func stop() -> void:
	_left = 0.0
	_what = NodePath()
	_body.breaking = 0.0


## A blow landed (host): it knocks the bar from her hands — unless she has
## learned the Long Pry. The blow still lands.
func struck() -> void:
	if _left > 0.0 and not _body.has_effect(&"haugbrot_holds"):
		stop()


## The clock, on the host: the trance's rule for a step (`Seidr.tick`), and
## on the last second the door opens, loud as a spent Waystone.
func tick(delta: float, tuning: TuningProfile) -> void:
	if _left <= 0.0:
		return
	var moved: Vector3 = _body.global_position - _at
	moved.y = 0.0
	_at = _body.global_position
	_speed = lerpf(_speed, moved.length() / maxf(delta, 0.0001),
		clampf(delta * 8.0, 0.0, 1.0))
	if not breakable(_what) or _body.is_incapacitated() \
			or _speed > tuning.seidr_break_speed:
		stop()
		return
	_left -= delta
	_body.breaking = clampf(1.0 - _left / _total, 0.0, 1.0)
	if _left > 0.0:
		return
	var broken: Node = get_node_or_null(_what)
	stop()
	if broken is LockedDoor:
		(broken as LockedDoor).broken_by = _body.get_multiplayer_authority()
		(broken as LockedDoor).host_open()
	elif broken is Barrow:
		(broken as Barrow).break_in()
	elif broken is Gullsjukr:
		(broken as Gullsjukr).knock_loose(_body)
	broke.emit()


## **Whether what `path` names is hers to break, from where she stands**: a door
## shut against her, or a barrow shut on its find, within reach. One rule for
## the start and for every tick of the clock, on the host.
func breakable(path: NodePath) -> bool:
	var thing: Node = get_node_or_null(path)
	var door := thing as LockedDoor
	if door != null:
		var off: Vector3 = door.global_position - _body.global_position
		off.y = 0.0
		return not door.open and door.refusal(_body) != &"" \
			and off.length() <= _body.hand_reach() + door.leaf_size().x * 0.5 + 0.5
	var barrow := thing as Barrow
	if barrow != null:
		return barrow.state == Barrow.State.SHUT \
			and barrow.global_position.distance_to(_body.global_position) <= _body.hand_reach() + 1.0
	var hunter := thing as Gullsjukr
	if hunter != null:
		return hunter.knockable() and _hunter_in_reach(hunter)
	return false


## **The Hunter within a mound-breaker's reach**, or null (ADR-403): her
## hammer knocks its hoard loose (`Gullsjukr.knock_loose`).
func hunter_at_hand() -> Gullsjukr:
	for node: Node in get_tree().get_nodes_in_group(&"hunters"):
		var hunter := node as Gullsjukr
		if hunter != null and hunter.knockable() and _hunter_in_reach(hunter):
			return hunter
	return null


func _hunter_in_reach(hunter: Gullsjukr) -> bool:
	var off: Vector3 = hunter.global_position - _body.global_position
	off.y = 0.0
	return off.length() <= _body.hand_reach() + Gullsjukr.NAV_RADIUS + 0.3


## A barrow shut on its find within reach, or null (ADR-382).
func barrow_at_hand() -> Barrow:
	for node: Node in get_tree().get_nodes_in_group(Barrow.GROUP):
		var barrow := node as Barrow
		if barrow != null and barrow.state == Barrow.State.SHUT \
				and barrow.global_position.distance_to(_body.global_position) <= _body.hand_reach() + 1.0:
			return barrow
	return null
