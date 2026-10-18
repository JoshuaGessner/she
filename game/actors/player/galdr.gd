class_name Galdr
extends Node

## **Galdr** (ADR-387, `DES-011` §3) — the Skald's verb, and only his.
##
## > *"That I know, the eleventh: if I lead old friends to battle, I chant
## > under their shields, and they go out whole."* — Hávamál st. 156
##
## Held, he asks the host to sing; let go, to stop. The host runs the verse's
## clock, lays its noise every second, breaks it on a blow or a fall, and at
## its end tells every enemy in earshot it has been sung to — what that does
## is each enemy's to decide (`Enemy.hear_the_song`).
##
## **A component of the body** (B52), as `Seidr` and `Haugbrot` are: the ask,
## the host-checked requests, the clock, where the verse lands and what it does
## are this file's. `Player` keeps what every peer reads — `singing`,
## `song_at`, `under_shields` — the verse's voice, and the telling (`sung`).

## The verse was sung through (host): how many it turned. The body tells the
## singer's own screen.
signal sung(turned: int)

var _body: Player = null
var _camera: Camera3D = null
## Host-side: seconds left on the verse and its length. Owner-side: whether
## this body has asked to sing, so the key is a request when it changes.
var _left: float = 0.0
var _total: float = 0.0
var _asked: bool = false
## Owner-side: the bag has already ended this verse.
var _hushed: bool = false
## Host-side: this verse is a Lausavísa's single stanza, not the whole verse.
var _stanza: bool = false
## Owner-side: when the key went down, to tell a Lausavísa's tap from a hold.
var _pressed_at: int = 0
## Host-side: the noise of a placed verse, standing where it lands.
var _stave: ClamorSource = null


## Called by the body that owns it, once, before anything asks: the body, and
## the eye Níðstöng aims by.
func serve(body: Player, camera: Camera3D) -> void:
	_body = body
	_camera = camera


## The owner's frame. Held asks to sing; a Lausavísa's tap shortens the verse
## to a stanza; the bag ends any verse.
func ask(driving: bool, rummaging: bool) -> void:
	# **The bag ends any verse** (B78), a Lausavísa's stanza included: the
	# stanza sings on after the key is up, so letting go cannot stop it, and
	# rummaging takes the breath a verse is made of. Said once, by the owner,
	# who is the only one that knows the bag is open.
	if _body.singing > 0.0 and rummaging and not _hushed:
		_hushed = true
		if multiplayer.is_server():
			stop()
		else:
			_request_hush.rpc_id(Player.HOST_PEER)
	elif _body.singing <= 0.0:
		_hushed = false
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	var wants: bool = (body != null and body.verb == &"galdr"
		and driving and Input.is_action_pressed("verb")
		and not _body.is_incapacitated()
		and not rummaging)
	if wants == _asked:
		return
	_asked = wants
	if wants:
		_pressed_at = Time.get_ticks_msec()
	# **Lausavísa** (ADR-387): let go almost at once, and the verse becomes a
	# single stanza — sung through on its own, quieter, at the nearest only.
	# Not gated on `singing`: on a client that is the host's progress, still
	# zero on the wire a tenth of a second in, and the tap would cancel the
	# verse it meant to shorten. The host refuses a stanza with no verse begun.
	elif _body.has_effect(&"galdr_stanza") \
			and float(Time.get_ticks_msec() - _pressed_at) / 1000.0 <= Config.tuning.galdr_tap_seconds:
		if multiplayer.is_server():
			stanza()
		else:
			_request_stanza.rpc_id(Player.HOST_PEER)
		return
	if multiplayer.is_server():
		sing(wants)
	else:
		_request_song.rpc_id(Player.HOST_PEER, wants)


## Whether an RPC came from the peer that owns this body, on the host.
func _from_owner() -> bool:
	return multiplayer.is_server() \
		and multiplayer.get_remote_sender_id() == _body.get_multiplayer_authority()


@rpc("any_peer", "call_remote", "reliable")
func _request_song(sing_on: bool) -> void:
	if _from_owner():
		sing(sing_on)


@rpc("any_peer", "call_remote", "reliable")
func _request_hush() -> void:
	if _from_owner():
		stop()


@rpc("any_peer", "call_remote", "reliable")
func _request_stanza() -> void:
	if _from_owner():
		stanza()


## Host-side. Refused to any but a Skald, while down, or mid-verse.
func sing(sing_on: bool) -> void:
	if not sing_on:
		# A stanza, once begun, is sung through on its own: the key is already up.
		if not _stanza:
			stop()
		return
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	if body == null or body.verb != &"galdr" or _body.is_incapacitated() or _left > 0.0:
		return
	_stanza = false
	_total = maxf(Config.tuning.galdr_seconds, 0.01)
	_left = _total
	_body.singing = 0.0
	_body.song_at = _lands(Config.tuning)


## Host-side: the verse under way becomes a Lausavísa's stanza — only for one
## who knows it, and only a verse that has just begun.
func stanza() -> void:
	if not _body.has_effect(&"galdr_stanza") or _left <= 0.0 or _stanza:
		return
	_stanza = true
	_total = maxf(Config.tuning.galdr_stanza_seconds, 0.01)
	_left = _total
	_body.singing = 0.0


## **Where the verse lands** (ADR-387): where he stands, or with Níðstöng the
## first stone his gaze meets within `galdr_aim` — Egill's pole, planted.
func _lands(tuning: TuningProfile) -> Vector3:
	if not _body.has_effect(&"galdr_placed"):
		return Vector3.INF
	var eye: Vector3 = _camera.global_position
	var look: Vector3 = -_camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(eye, eye + look * tuning.galdr_aim)
	query.collision_mask = CollisionLayers.WORLD | CollisionLayers.GATE
	var hit: Dictionary = _body.get_world_3d().direct_space_state.intersect_ray(query)
	var landed: Vector3 = (hit["position"] as Vector3) - look * 0.4 if not hit.is_empty() \
		else eye + look * tuning.galdr_aim
	landed.y = _body.global_position.y
	return landed


func stop() -> void:
	_left = 0.0
	_body.singing = 0.0
	_stanza = false


## A blow landed (host): it takes the breath from the verse (ADR-387).
func struck() -> void:
	if _left > 0.0:
		stop()


## The verse's clock, on the host: loud every second it is sung, and sung
## through, it lands on everything in earshot.
func tick(delta: float, tuning: TuningProfile) -> void:
	if _body.under_shields > 0.0:
		_body.under_shields = maxf(0.0, _body.under_shields - delta)
	if _left <= 0.0:
		return
	if _body.is_incapacitated():
		stop()
		return
	_sound_the_verse(tuning.galdr_clamor * delta * (0.5 if _stanza else 1.0))
	_left -= delta
	_body.singing = clampf(1.0 - _left / _total, 0.0, 1.0)
	if _left > 0.0:
		return
	var was_stanza: bool = _stanza
	stop()
	sing_out(tuning, was_stanza)


## The verse's noise, laid where it is sung: on the singer, or with Níðstöng at
## a stave of its own where it lands, which the floor and the Hunt hear there.
func _sound_the_verse(amount: float) -> void:
	if not _body.song_at.is_finite():
		_body.clamor.add(amount)
		return
	if _stave == null or not is_instance_valid(_stave):
		_stave = ClamorSource.new()
		_stave.name = "Stave"
		_stave.top_level = true
		_stave.add_to_group("clamor_sources")
		add_child(_stave)
	_stave.global_position = _body.song_at + Vector3.UP * 1.0
	_stave.add(amount)


## **The verse lands** (ADR-387): every living enemy within `galdr_reach` of
## where it is sung hears it — or, for a Lausavísa's stanza, only the nearest.
## With the Rite it also rallies a fallen friend (Bjarkamál) and sets friends
## under shields.
func sing_out(tuning: TuningProfile, was_stanza: bool) -> void:
	var turned_count: int = 0
	var landed: Vector3 = _body.song_at if _body.song_at.is_finite() else _body.global_position
	var hearing: Array[Enemy] = []
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var heard := node as Enemy
		if heard == null or heard.state() == Enemy.State.DEAD \
				or heard.global_position.distance_to(landed) > tuning.galdr_reach:
			continue
		hearing.append(heard)
	if was_stanza and hearing.size() > 1:
		hearing.sort_custom(func(a: Enemy, b: Enemy) -> bool:
			return a.global_position.distance_to(landed) < b.global_position.distance_to(landed))
		hearing = [hearing[0]]
	for heard: Enemy in hearing:
		if heard.hear_the_song(landed, tuning) != Turned.Mood.NONE:
			turned_count += 1
	if not was_stanza:
		_rally_and_shield(tuning)
	sung.emit(turned_count)
	# **And the Hunt hears it** (ADR-403, reopening ADR-387's "not the Hunt"):
	# `DES-017` lists Skald songs among the ways to confuse it — *"it is a
	# person, badly, and can still be lied to."* A whole verse sung within
	# reach of it sends it away. A stanza is too short to. Told after the
	# count, so the singer reads what mattered more.
	if not was_stanza:
		for node: Node in get_tree().get_nodes_in_group(&"hunters"):
			var hunter := node as Gullsjukr
			if hunter != null and hunter.global_position.distance_to(landed) <= tuning.galdr_reach:
				hunter.turn_away(&"galdr", tuning.hunter_turn_galdr_seconds, landed, _body)


## **Bjarkamál and Under Shields** (ADR-387), host-side at a whole verse's end.
## Þormóðr woke the army with the poem; the nearest fallen friend who hears it
## stands. And Hávamál st. 156: friends who hear it, the singer too, take the
## next heavy blow on the guard and the guard holds.
func _rally_and_shield(tuning: TuningProfile) -> void:
	var rally: bool = _body.has_effect(&"galdr_rallies")
	var shields: bool = _body.has_effect(&"galdr_shields")
	if not rally and not shields:
		return
	var fallen: Player = null
	var at: Vector3 = _body.global_position
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		var friend := node as Player
		if friend == null or friend.global_position.distance_to(at) > tuning.galdr_reach:
			continue
		if shields and not friend.is_incapacitated():
			friend.under_shields = tuning.galdr_shields_seconds
		if rally and friend != _body and friend.is_downed() and (fallen == null
				or friend.global_position.distance_to(at) < fallen.global_position.distance_to(at)):
			fallen = friend
	if fallen != null:
		fallen.roused_by_song()
