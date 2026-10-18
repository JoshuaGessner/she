class_name Seidr
extends Node

## **Seiðr** (ADR-379, `DES-011` §2) — the Völva's verb, and only hers.
##
## > *"She was to sit on a high seat … and the women made a ring around it,
## > and Guðríðr sang the ward-songs so well that the seeress said many
## > spirits had come."* — Eiríks saga rauða, ch. 4
##
## **A component of the body** (B52), not a part of it: the ask, the host's
## clock, the blow that breaks it and the reading are this file's, and
## `Player` keeps only what every peer must see — `trance` and `sight_spent`,
## replicated with the rest of its state — and calls down. Made on every peer
## at one path, as `Pinger` is, so its request reaches the host's copy.
##
## The owner's half is only the asking: held, she asks the host to let her sit;
## let go, to stand. The host runs the trance's clock and breaks it on a step
## or a blow, because what it pays for is the floor's secrets, and those are
## never the client's to award itself (`TEC-004`).

## The key was pressed while the sight is still spent (B55): the body says so.
signal resting
## Vé: the seat stays warded a while, laid where she sat.
signal warded(at: Vector3, ward: HushTrait)

var _body: Player = null
## Host-side: seconds left on the trance, its length, and whether Varðlokkur's
## ward still stands between it and the next blow.
var _left: float = 0.0
var _total: float = 0.0
var _warded: bool = false
## Host-side, the binding's measure of movement (`_tick_binding`): a step
## breaks a trance, judged as the host sees the body go.
var _at: Vector3 = Vector3.ZERO
var _speed: float = 0.0
## Owner-side: whether this body has asked the host to sit, so the key is a
## request when it changes and not twenty a second.
var _asked: bool = false


## Called by the body that owns it, once, before anything asks.
func serve(body: Player) -> void:
	_body = body


## Whether a trance is running, on the host.
func sitting() -> bool:
	return _left > 0.0


## The owner's frame: the craft key held is a request to sit, let go to stand.
func ask(driving: bool, rummaging: bool) -> void:
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	var hers: bool = body != null and body.verb == &"seidr"
	if hers and driving and _body.sight_spent > 0.0 \
			and Input.is_action_just_pressed("verb"):
		resting.emit()
	var wants: bool = (hers and driving and Input.is_action_pressed("verb")
		and not _body.is_incapacitated()
		and not rummaging
		and _body.sight_spent <= 0.0)
	if wants == _asked:
		return
	_asked = wants
	if multiplayer.is_server():
		sit(wants)
	else:
		_request.rpc_id(Player.HOST_PEER, wants)


@rpc("any_peer", "call_remote", "reliable")
func _request(sitting_down: bool) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != _body.get_multiplayer_authority():
		return
	sit(sitting_down)


## Host-side. Sitting is refused to any but a Völva, while the sight is
## spent, while down, or while one trance already runs.
func sit(sitting_down: bool) -> void:
	if not sitting_down:
		stop()
		return
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	if body == null or body.verb != &"seidr" or _body.sight_spent > 0.0 \
			or _body.is_incapacitated() or _left > 0.0:
		return
	_total = maxf(Config.tuning.seidr_seconds, 0.01)
	_left = _total
	_warded = _body.has_effect(&"seidr_warded")
	_at = _body.global_position
	_speed = 0.0
	_body.trance = 0.0


func stop() -> void:
	_left = 0.0
	_body.trance = 0.0


## A blow landed (host): it breaks the trance, unless the ward-songs hold
## for one blow.
func struck() -> void:
	if _left <= 0.0:
		return
	if _warded:
		_warded = false
	else:
		stop()


## The trance's clock and the sight's, on the host. A step breaks it — judged
## by the binding's averaged speed against `seidr_break_speed`, so a client's
## eased packets do not read as a stride — and so does going down.
func tick(delta: float, tuning: TuningProfile) -> void:
	if _body.sight_spent > 0.0:
		_body.sight_spent = maxf(0.0, _body.sight_spent - delta)
	if _left <= 0.0:
		return
	var moved: Vector3 = _body.global_position - _at
	moved.y = 0.0
	_at = _body.global_position
	_speed = lerpf(_speed, moved.length() / maxf(delta, 0.0001),
		clampf(delta * 8.0, 0.0, 1.0))
	if _body.is_incapacitated() or _speed > tuning.seidr_break_speed:
		stop()
		return
	_left -= delta
	_body.trance = clampf(1.0 - _left / _total, 0.0, 1.0)
	if _left > 0.0:
		return
	stop()
	_body.sight_spent = tuning.seidr_spent_seconds
	read(tuning)


## **The reading**, decided on the host: where the Gold-Sick was, the best
## thing still on the floor, and the way out — and, with the Rite, the awake,
## where the Gold-Sick is going, and a hush where she sat. Every mark is where
## the thing *was*; none of them follows.
func read(tuning: TuningProfile) -> void:
	var found: Array = []
	for node: Node in get_tree().get_nodes_in_group(&"hunters"):
		var hunter := node as Gullsjukr
		if hunter == null or not hunter.is_inside_tree():
			continue
		found.append([Pinger.Kind.ENEMY, hunter.global_position])
		# **Sjónhverfing** (ADR-403): sight-turning, the seiðr the sagas give
		# Útgarða-Loki and Katla of Eyrbyggja — she reads it, and reads the
		# party's gold out of what it can feel.
		hunter.veil(tuning.hunter_veil_seconds, _body)
		# **Spá** — and where it is going, one more snapshot.
		if _body.has_effect(&"seidr_foresees") and hunter.has_goal():
			found.append([Pinger.Kind.GO, hunter.goal()])
		break
	var best: WorldItem = null
	var worth: int = 0
	for node: Node in get_tree().get_nodes_in_group(WorldItem.GROUP):
		var lying := node as WorldItem
		if lying == null or lying.definition() == null:
			continue
		var value: int = lying.definition().tribute_value
		if value > worth:
			best = lying
			worth = value
	if best != null:
		found.append([Pinger.Kind.LOOT, best.global_position])
	for node: Node in get_tree().get_nodes_in_group(Shaft.GROUP):
		var way := node as Shaft
		if way != null:
			found.append([Pinger.Kind.WAY, way.global_position])
			break
	# **Marking Prey** — every awake enemy near, where it stood.
	if _body.has_effect(&"seidr_marks_prey"):
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			var awake := node as Enemy
			if awake == null or found.size() >= Sight.MOST:
				continue
			var state: Enemy.State = awake.state()
			if state == Enemy.State.UNAWARE or state == Enemy.State.DEAD:
				continue
			if awake.global_position.distance_to(_body.global_position) > tuning.rite_prey_metres:
				continue
			found.append([Pinger.Kind.ENEMY, awake.global_position])
	_body.sight.show_reading(found)
	# **Vé** — the seat stays warded a while, and cracks as a rune does.
	if _body.has_effect(&"seidr_wards_ground"):
		var ward := HushTrait.new()
		ward.radius = tuning.rite_ve_radius
		ward.seconds = tuning.rite_ve_seconds
		ward.crack = tuning.rite_ve_crack
		warded.emit(_body.global_position, ward)
