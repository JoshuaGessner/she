class_name WolfFury
extends Node

## **Wolf-Fury** (ADR-345, `DES-011`) — the Úlfheðinn's verb, and only theirs.
##
## > *"Odin's men went without their mail-coats, were mad as dogs or wolves,
## > bit their shields … and killed men at a blow, but neither fire nor iron
## > told upon them."* — Ynglinga saga, ch. 6
##
## Held for `fury_howl_seconds` — a howl, which is loud and is the Hunt's to
## hear — and then the host runs the fury's clock. Nothing on this body asks to
## end it: `DES-011`'s *"cannot voluntarily disengage"* is the price, so the key
## does nothing again until the fury and the weakness after it are both over.
##
## **A component of the body** (B52), as `Seidr`, `Haugbrot` and `Galdr` are:
## the howl, the host-checked rouse, the clock, the blood deferred and paid,
## Blood-Price and Rising Fury are this file's. `Player` keeps `fury`,
## `fury_spent` and `blood_owed`, which every peer and a dozen of the body's own
## rules read, and makes the noises (`howled`, `paid`).

## The fury began (host): the howl, which the floor and every peer hear.
signal howled
## The fury ended owing blood, and it was paid (host).
signal paid

var _body: Player = null
## How far through the howl that opens a fury the owner is, 0–1.
var _howling: float = 0.0
## Seconds Rising Fury has added to this fury, capped at its own length.
var _added: float = 0.0


## Called by the body that owns it, once, before anything asks.
func serve(body: Player) -> void:
	_body = body


## How far through the howl this body is, 0–1. Owner-side (ADR-372).
func howling() -> float:
	return _howling


## The owner's frame: the key held through the howl rouses the fury.
func ask(delta: float, tuning: TuningProfile, driving: bool, rummaging: bool) -> void:
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	var wants: bool = (body != null and body.verb == &"fury"
		and driving and Input.is_action_pressed("verb")
		and not _body.is_incapacitated()
		and not rummaging
		and _body.fury <= 0.0 and _body.fury_spent <= 0.0)
	if not wants:
		_howling = 0.0
		return
	_howling += delta / maxf(tuning.fury_howl_seconds, 0.001)
	if _howling >= 1.0:
		_howling = 0.0
		if multiplayer.is_server():
			rouse()
		else:
			rouse.rpc_id(Player.HOST_PEER)


## **The fury begins**, on the host: the clock, the howl's noise, and — with
## The Howl — every enemy in reach staggered back as by a blow.
@rpc("any_peer", "call_remote", "reliable")
func rouse() -> void:
	if not multiplayer.is_server():
		return
	var from: int = multiplayer.get_remote_sender_id()
	if from == 0:
		from = multiplayer.get_unique_id()
	if from != _body.get_multiplayer_authority():
		return
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	if body == null or body.verb != &"fury" or _body.fury > 0.0 or _body.fury_spent > 0.0 \
			or _body.is_incapacitated():
		return
	var tuning: TuningProfile = Config.tuning
	_body.fury = tuning.fury_seconds
	_added = 0.0
	# The howl (ADR-358), heard by every peer. `DES-018`'s twin of it is the
	# screen's ember edge, and the teammate's hunch.
	howled.emit()
	if _body.has_effect(&"fury_howl_breaks_nerve"):
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null:
				continue
			var off: Vector3 = enemy.global_position - _body.global_position
			off.y = 0.0
			if off.length() > tuning.rite_howl_reach:
				continue
			enemy.shove(off.normalized() if off.length() > 0.01 else Vector3.FORWARD,
				tuning.rite_howl_metres)


## The fury's clock and the weakness's, on the host. A body that goes down in
## the fury — by a fall, a hazard, the Last Door's blood — ends it and pays.
func tick(delta: float) -> void:
	if _body.fury_spent > 0.0:
		_body.fury_spent = maxf(0.0, _body.fury_spent - delta)
	if _body.fury <= 0.0:
		return
	_body.fury = maxf(0.0, _body.fury - delta)
	if _body.fury <= 0.0 or _body.is_incapacitated():
		_body.fury = 0.0
		_end()


## **The fury ends, and the blood is paid** — all of it, at once. The one
## sentence `PRO-005` asks a death to be explainable in: *I took more in the
## fury than I had.*
func _end() -> void:
	_body.fury_spent = Config.tuning.fury_spent_seconds
	var owed: float = _body.blood_owed
	_body.blood_owed = 0.0
	if owed > 0.0:
		_body.health.apply_damage(owed, null)
		paid.emit()


## A blow's damage: taken, or — in the fury — owed (ADR-345). WoW's Brewmaster
## *Stagger* is the shipped form: damage resistance as a **timing**, not a
## number, which is what `DES-022` permits and `×0.6 damage taken` is not.
func take_blood(amount: float, from: Node) -> void:
	if _body.fury > 0.0:
		_body.blood_owed += amount
		return
	_body.health.apply_damage(amount, from)


## A blow landed in the fury, on the host: **Blood-Price** pays down what is
## owed for a kill, and **Rising Fury** feeds the clock — up to its length again.
func landed(killed: bool) -> void:
	var tuning: TuningProfile = Config.tuning
	if killed and _body.has_effect(&"fury_blood_price"):
		_body.blood_owed = maxf(0.0, _body.blood_owed - tuning.rite_blood_price)
	if _body.has_effect(&"fury_rising") and _added < tuning.fury_seconds:
		var more: float = minf(tuning.rite_rising_seconds, tuning.fury_seconds - _added)
		_added += more
		_body.fury += more
