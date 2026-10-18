class_name SnareVerb
extends Node

## **Snare** (`M3-T11`, `DES-011`) — the Veiðimaðr's verb, and only theirs.
##
## > *"Place traps that hold, wound, or misdirect — including against the
## > Hunter, the only reliable way to buy time during the Sealing."*
##
## Held rather than tapped, and it takes `snare_place_seconds`, for the reason
## the Húskarl's plant takes time: `DES-009` refuses reflex-timed play, so this
## is a thing you decide to do a beat before you need it. Releasing early
## abandons it and costs nothing — the stamina is spent when the trap exists,
## not when you start thinking about it.
##
## It goes at your feet. Not ahead of you, which would need an aim and a preview
## and a rule about walls; at your feet is somewhere you have just proved you
## can stand, and *"set it and back away through it"* is a legible gesture with
## nothing to learn.
##
## **A component of the body** (B52), as the other verbs are. Named for the
## verb, because `Snare` is the trap: this is the setting of one. The trap is
## spawned by `CoopSession` on the body's `set_snare`, which this feeds.

## The host was told a trap was set here, by this peer (`Player.set_snare`).
signal placed(at: Vector3, placer: int)

var _body: Player = null
## How far through setting a Snare, 0 to 1. **Not replicated**, unlike the
## Húskarl's `planted`: that one crosses the wire because it changes a collision
## layer and the host's enemies have to collide with it. This changes nothing
## anyone else's machine has to agree about — the legible event is the trap
## appearing, and the trap is a spawned actor that appears for everybody.
var _setting: float = 0.0
## The ring a snare being set will be, growing at your feet as you set it —
## the progress of a verb you cannot otherwise see, since `_setting` never
## leaves this machine. Made the first time it is needed.
var _ghost: MeshInstance3D = null


## Called by the body that owns it, once, before anything asks.
func serve(body: Player) -> void:
	_body = body


## How far through setting a snare this body is (the kneel, `--verbs-probe`).
func setting() -> float:
	return _setting


## The ring growing at your feet, or null before one was ever set.
func ghost() -> MeshInstance3D:
	return _ghost


## The owner's frame: held for `snare_place_seconds`, the trap is asked for.
func ask(delta: float, tuning: TuningProfile, driving: bool, rummaging: bool) -> void:
	var body: ClassResource = ClassCatalogue.by_id(_body.sworn)
	var wants: bool = (body != null and body.verb == &"snare"
		and driving and Input.is_action_pressed("verb")
		and not _body.is_incapacitated()
		and not rummaging
		and _body.stamina.current >= tuning.snare_stamina_cost)
	if not wants:
		_setting = 0.0
		return
	_setting += delta / maxf(tuning.snare_place_seconds, 0.001)
	if _setting < 1.0:
		return
	_setting = 0.0
	if not _body.stamina.spend(tuning.snare_stamina_cost):
		return
	# The jaws set: a small click for your own ears (ADR-272). Not a noise the
	# floor hears — setting is silent (ADR-123), and `Foley` is sound, never
	# Clamor.
	Foley.at(_body, Foley.Sound.CLINK, 0.55, -8.0)
	if multiplayer.is_server():
		place(_body.global_position)
	else:
		place.rpc_id(Player.HOST_PEER, _body.global_position)


## The host is told a trap was set. It does not set it — `CoopSession` does,
## including clearing the one this peer already had, because the session owns
## every spawned actor and *one live at a time* is a fact about the world rather
## than about this body.
@rpc("any_peer", "call_local", "reliable")
func place(at: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var from: int = multiplayer.get_remote_sender_id()
	if from == 0:
		from = multiplayer.get_unique_id()
	if from != _body.get_multiplayer_authority():
		return
	placed.emit(at, from)


## **Setting a snare, seen** (ADR-272): the ring it will be, growing at your
## feet. Returns whether the body's stance wants applying again — the eye drops
## as you kneel to it, and rises the frame you stop.
func draw() -> bool:
	var showing: bool = _ghost != null and _ghost.visible
	var restance: bool = _setting > 0.0 or showing
	if _setting <= 0.0:
		if _ghost != null:
			_ghost.visible = false
		return restance
	if _ghost == null:
		var torus := TorusMesh.new()
		torus.inner_radius = Snare.RADIUS * 0.78
		torus.outer_radius = Snare.RADIUS
		# Opaque and dim rather than see-through: the ink pass composites over
		# the finished frame, and a transparent ring would be drawn and then
		# painted over (`ART-005`) — measured, it vanished.
		var faint := StandardMaterial3D.new()
		faint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		faint.albedo_color = Color(0.46, 0.42, 0.34)
		_ghost = MeshInstance3D.new()
		_ghost.name = "SnareGhost"
		_ghost.mesh = torus
		_ghost.material_override = faint
		_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost.top_level = true
		add_child(_ghost)
	_ghost.visible = true
	_ghost.global_position = _body.global_position + Vector3(0.0, 0.03, 0.0)
	var grown: float = lerpf(0.3, 1.0, _setting)
	_ghost.scale = Vector3(grown, 1.0, grown)
	return restance
