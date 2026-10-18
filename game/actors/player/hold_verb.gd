class_name HoldVerb
extends Node

## **Hold** (`M3-T02`, `DES-011`) — the Húskarl's verb, and only theirs.
##
## *"Plant and become an immovable object. Nothing pushes past you. Allies can
## retreat through you."*
##
## Three things, and each is one line because the systems were already there:
##
## - **Immovable** is `_speed()` returning nothing while planted. Not a physics
##   change, not a new movement state — you simply cannot walk, which is what
##   makes it a *decision to stop* rather than a stance you drift into.
## - **Nothing pushes past you** is `CollisionLayers.BULWARK`. Enemies mask it,
##   players do not, so the same layer that makes you a wall makes you thin air
##   to your own party. There is no "except teammates" rule to get wrong.
## - **A real cost** (`DES-011`'s rule for every unique verb) is stamina per
##   second. Not per blow: the clock runs while you are the only thing in the
##   doorway, whether or not anything comes.
##
## Planting **takes `hold_plant_seconds`** and unplanting is immediate. That
## asymmetry is the commitment: `DES-009` refuses reflex-timed defence, so this
## is a thing you decide to do a beat before you need it, and an ally has time
## to read that you have done it.
##
## **A component of the body** (B52), as the other five verbs are: the owner's
## plant, its breath, the Last Door's blood and the Shove are this file's.
## `Player` keeps `planted`, which crosses the wire, and everything every peer
## does with it — the layer, the stance, the brace, the sound of the plant.

var _body: Player = null
## Health a Last Door has cost and the host has not yet taken (ADR-273).
var _owed_blood: float = 0.0


## Called by the body that owns it, once, before anything asks.
func serve(body: Player) -> void:
	_body = body


## The owner's frame: the plant, what it costs, and what letting go of it does.
func ask(delta: float, tuning: TuningProfile, driving: bool, rummaging: bool) -> void:
	# Only a class with the verb has the verb. `DES-011`: identity comes from
	# the verb, not the stat line — so this is the line that makes a Húskarl
	# recognisable from ten seconds of watching, and it is gated on nothing but
	# whether you are one.
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	var wants: bool = (body != null and body.verb == &"hold"
		and driving and Input.is_action_pressed("verb")
		and not _body.is_incapacitated()
		and not rummaging
		and (_body.stamina.current > 0.0 or _body.has_effect(&"hold_past_breath")))
	var step: float = delta / maxf(tuning.hold_plant_seconds, 0.001)
	var was: float = _body.planted
	_body.planted = minf(_body.planted + step, 1.0) if wants else 0.0
	# **Drained, not spent** (ADR-273). `spend` refuses an amount larger than
	# what is left and then does not restart the regeneration delay — so once
	# the bar was below one frame's cost it stopped falling, refilled while you
	# held, and **a Hold never ran out**. `drain` takes the last of it; at empty
	# the delay is held open, so a Last Door's chest does not refill mid-hold.
	if _body.planted > 0.0 and not _body.stamina.drain(tuning.hold_stamina_drain, delta):
		_body.stamina.spend(0.0)
	# **Last Door** (ADR-273): held past empty, the breath you do not have is
	# paid in blood. Owed here, where the empty bar is known, and settled on
	# the host a point at a time — health is the host's, stamina is not.
	if _body.planted >= 1.0 and _body.stamina.current <= 0.0 \
			and _body.has_effect(&"hold_past_breath"):
		_owed_blood += tuning.rite_last_door_bleed * delta
	if _owed_blood >= 1.0 or (_body.planted <= 0.0 and _owed_blood > 0.0):
		var paid: float = _owed_blood
		_owed_blood = 0.0
		if multiplayer.is_server():
			bleed_for_the_door(paid)
		else:
			bleed_for_the_door.rpc_id(Player.HOST_PEER, paid)
	# **Shove** (ADR-273): letting go of a full Hold throws what is in front of
	# you back. Only a full one — a plant you abandoned half-set has nothing
	# braced to push with — and only if there is breath to push with.
	if was >= 1.0 and _body.planted <= 0.0 and _body.has_effect(&"hold_shove") \
			and _body.stamina.spend(tuning.rite_shove_stamina):
		if multiplayer.is_server():
			shove()
		else:
			shove.rpc_id(Player.HOST_PEER)


## Whether an RPC came from the peer that owns this body, on the host. A local
## call reports sender 0, which is this peer.
func _from_owner() -> bool:
	if not multiplayer.is_server():
		return false
	var from: int = multiplayer.get_remote_sender_id()
	if from == 0:
		from = multiplayer.get_unique_id()
	return from == _body.get_multiplayer_authority()


## **Last Door's price, taken where health lives** (ADR-273). The owner knows
## the bar is empty; the host owns the blood. Checked against what the host can
## see — a full Hold and the node — which is `TEC-004`'s trust model: a client
## that lies about this hurts nobody but itself.
@rpc("any_peer", "call_local", "reliable")
func bleed_for_the_door(amount: float) -> void:
	if not _from_owner() or not _body.has_effect(&"hold_past_breath"):
		return
	_body.health.apply_damage(clampf(amount, 0.0, 10.0), null)


## **Shove, on the host** (ADR-273): everything in front, inside the guard's arc
## and the reach, is staggered and thrown back a step. Loud — the Húskarl's
## Rite is a doorway, not a hiding place.
@rpc("any_peer", "call_local", "reliable")
func shove() -> void:
	if not _from_owner() or not _body.has_effect(&"hold_shove"):
		return
	var tuning: TuningProfile = Config.tuning
	var ahead: Vector3 = -_body.global_transform.basis.z
	ahead.y = 0.0
	ahead = ahead.normalized()
	var cone: float = cos(deg_to_rad(tuning.guard_arc_degrees))
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		var off: Vector3 = enemy.global_position - _body.global_position
		off.y = 0.0
		if off.length() < 0.01 or off.length() > tuning.rite_shove_reach:
			continue
		if ahead.dot(off.normalized()) < cone:
			continue
		enemy.shove(off.normalized(), tuning.rite_shove_metres)
	_body.clamor.add(tuning.rite_shove_clamor)
