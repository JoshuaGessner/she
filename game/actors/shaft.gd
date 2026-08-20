class_name Shaft
extends Node3D

## The way out you did not have to find (`M2-T04`, `DES-005` Layer 3, ADR-015).
##
## One fixed mechanism per floor, **location known**. Reliable, dangerous and
## loud — a real place you have to reach and survive rather than a door you
## walk through. ADR-015 made extraction a *resource* problem, and the Shaft is
## the half of that resource you never have to loot: it is always there, and it
## always costs.
##
## ## The Sealing, and the contradiction it had to resolve
##
## `DES-005` says two things that do not sit together on one floor:
##
## > *"As the Hunt escalates, **the Shafts seal, floor by floor.**"*
## > *"The player is never truly trapped — **the Shaft is always reachable**,
## > just increasingly expensive."*
##
## Both are true of a three-floor run: sealing floor 1 pushes you *down*, and
## down is still a way out. On the one hand-built floor that exists until
## `M4-T01`, a sealed Shaft is a locked door with nothing below it — which is
## the trapping ADR-015 forbids outright.
##
## So the Sealing is built as the **second** sentence, not the first (ADR-091):
##
## > **The Shaft never locks. It gets worse.**
##
## Escalation lengthens the channel and raises the noise, so leaving late means
## standing exposed in a known location, for longer, screaming — with the thing
## that hunts wealth already coming. That is *"your cheap exit is gone"*
## delivered as a price rather than as a wall, it is what `DES-005`'s own
## guarantee describes, and it needs no floor beneath it to be honest.
##
## **Floor-by-floor locking is not built and is not faked.** It needs floors,
## and it arrives with them at `M4-T01`, alongside the cross-floor Hunt.
##
## ## Host-validated, like every consequence
##
## Authored geometry on every peer, so there is nothing to spawn; the *use* is
## a request the host decides, exactly as pickup is (`TEC-004`, ADR-082).

signal claimed(player: Player)

const GROUP: StringName = &"shafts"

const RADIUS: float = 1.6
const HEIGHT: float = 0.35
## Cold, pale, and the only thing down here that is not warm. `ART-005` spends
## saturated colour on treasure, so the way out reads by *value* instead —
## which also keeps it distinguishable from gold at a glance and in monochrome.
const IDLE: Color = Color(0.62, 0.68, 0.74)
const WORKING: Color = Color(0.88, 0.93, 0.97)

## The beacon (`M2-T13`, ADR-105). **`DES-005` says the Shaft's location is
## *known*, and until now nothing made it so** — it was a pale disc on the floor
## of one room among six, invisible from anywhere else, in a level lit flatly
## enough that no room looked like a destination. "Known" was true of the
## layout and false of the experience, which is the gap `--route-probe` could
## not see: it asserts a clean *path* exists, never that a player could find it.
##
## A column of pale light, tall enough to clear the walls in sightline terms and
## bright enough to read through a doorway from the junction — the room every
## route crosses. It does not tell you where you are; it tells you which way
## out is, which is the one piece of orientation `DES-005` actually promises.
##
## Pale, never gold. `ART-005` spends saturated colour on treasure and her fire,
## so a warm exit would say "safety" using the vocabulary this game reserves for
## "this will kill you."
const BEACON_HEIGHT: float = 5.2
const BEACON_RADIUS: float = 0.18
const BEACON_ENERGY: float = 2.4   # ⟨tune⟩
const BEACON_RANGE: float = 26.0   # ⟨tune⟩

## The audible half. `DES-018` requires every channel to have a twin, and this
## is the twin of the column above rather than a separate cue: a player with the
## sound muted has the light, and a player who cannot see the light from where
## they are standing has the hum. Quiet, and it does not carry as far as the
## light does — it is a confirmation once you are close, not a second beacon.
const HUM_DECIBELS: float = -22.0  # ⟨tune⟩
const HUM_RANGE: float = 14.0      # ⟨tune⟩

var _mesh: MeshInstance3D = null
var _beacon: MeshInstance3D = null
var _light: OmniLight3D = null
var _material: StandardMaterial3D = null
## Who is currently standing in it, and how far through. Host-side only: the
## channel is a consequence and consequences have one owner.
var _claimant: Player = null
var _progress: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	_build_body()


## Seconds this takes to use, right now. **This is the Sealing.**
##
## Grows with how long the Hunt has been escalating, so an early exit is cheap
## and a late one is a long exposed moment in a place the Gullsjúkr already
## knows about. `DES-005`: *"increasingly expensive."*
func channel_seconds() -> float:
	var tuning: TuningProfile = Config.tuning
	return tuning.shaft_channel_seconds * (1.0 + _escalation()
		* tuning.shaft_seal_factor)


## Noise made while using it, per second. Escalates alongside the time, so a
## late exit is both longer *and* louder — the two costs compound, which is
## what makes staying feel like a decision rather than a delay.
func channel_clamor() -> float:
	var tuning: TuningProfile = Config.tuning
	return tuning.shaft_clamor * (1.0 + _escalation() * tuning.shaft_seal_factor)


## 0 at the start of a floor, rising with the Hunt's age ⟨tune⟩. Read off the
## Gullsjúkr rather than a clock of its own: the pressure the player feels and
## the price of leaving have to come from the same source, or the Sealing is a
## timer wearing the Hunt's clothes.
func _escalation() -> float:
	var oldest: float = 0.0
	for node: Node in get_tree().get_nodes_in_group(&"hunters"):
		var hunter := node as Gullsjukr
		if hunter != null:
			oldest = maxf(oldest, hunter.age)
	return clampf(oldest / maxf(Config.tuning.shaft_seal_seconds, 0.001), 0.0, 1.0)


## True if this player is close enough to use it. The host re-runs this with
## its own copy of where they are, which is what makes the client's request a
## request rather than an instruction.
func in_reach(player: Player) -> bool:
	var span: float = RADIUS + Config.tuning.interact_reach_slack
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	return offset.length() <= span


## Host-side. Advance whoever is standing in it, and give up on anyone who
## walked away — the channel is not a commitment, because a player who has to
## abandon their exit to fight for it should be able to.
func advance(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if _claimant == null or not is_instance_valid(_claimant):
		_reset()
		return
	if not in_reach(_claimant):
		# Stepped out. `DES-005` wants the Shaft dangerous, not sticky.
		_reset()
		return
	var before: float = _progress
	_progress += delta / maxf(channel_seconds(), 0.001)
	# A tick every quarter of the climb, so holding it *sounds* like progress.
	# `DES-018` wants every audio channel to have a visual twin and vice versa;
	# a channel with a bar and no sound is the same failure from the other side.
	if int(before * 4.0) != int(_progress * 4.0):
		Foley.at(self, Foley.Sound.CHANNEL, 0.9 + _progress * 0.5)
	# Loud the whole time, not once at the end. The noise is what makes using a
	# known location dangerous, and a single deposit at the finish would be a
	# cost you only pay after you have already got away with it.
	_claimant.clamor.add(channel_clamor() * delta)
	if _progress < 1.0:
		return
	var leaving: Player = _claimant
	_reset()
	claimed.emit(leaving)


func begin(player: Player) -> void:
	if not multiplayer.is_server():
		return
	if not in_reach(player):
		return
	if _claimant == player:
		return
	_claimant = player
	_progress = 0.0


func _reset() -> void:
	_claimant = null
	_progress = 0.0


func _process(_delta: float) -> void:
	if _material == null:
		return
	# Brightens as it works. Every peer can see it, because a teammate standing
	# in the Shaft is information the whole party needs — and it is the visual
	# half of a sound `M2-T09` will give it.
	_material.albedo_color = IDLE.lerp(WORKING, _progress)


func _build_body() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS
	mesh.height = HEIGHT
	_material = StandardMaterial3D.new()
	_material.albedo_color = IDLE
	_material.roughness = 0.6
	_mesh = MeshInstance3D.new()
	_mesh.mesh = mesh
	_mesh.material_override = _material
	_mesh.position.y = HEIGHT * 0.5
	add_child(_mesh)
	_build_beacon()


## The column, the light and the hum — the three halves of "you can find this".
func _build_beacon() -> void:
	var column := CylinderMesh.new()
	column.top_radius = BEACON_RADIUS
	column.bottom_radius = BEACON_RADIUS
	column.height = BEACON_HEIGHT
	var glow := StandardMaterial3D.new()
	glow.albedo_color = WORKING
	glow.emission_enabled = true
	glow.emission = WORKING
	glow.emission_energy_multiplier = 1.6
	# Unshaded, so the column reads at the same value from every angle. A
	# beacon that dims as you walk round it is not a beacon.
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beacon = MeshInstance3D.new()
	_beacon.mesh = column
	_beacon.material_override = glow
	_beacon.position.y = BEACON_HEIGHT * 0.5
	add_child(_beacon)

	_light = OmniLight3D.new()
	_light.light_color = IDLE
	_light.light_energy = BEACON_ENERGY
	_light.omni_range = BEACON_RANGE
	_light.position.y = BEACON_HEIGHT * 0.6
	add_child(_light)

	var hum := AudioStreamPlayer3D.new()
	# The same sample the Shaft plays when it is working, looped — so the idle
	# hum and the channelling sound are recognisably one object rather than two
	# unrelated noises that happen to share a location.
	hum.stream = Foley.looping_stream_for(Foley.Sound.CHANNEL)
	hum.volume_db = HUM_DECIBELS
	hum.max_distance = HUM_RANGE
	hum.pitch_scale = 0.55
	hum.autoplay = true
	add_child(hum)


## The nearest Shaft within reach of a point, or `null`.
static func nearest(from: Node, at: Vector3) -> Shaft:
	for node: Node in from.get_tree().get_nodes_in_group(GROUP):
		var shaft := node as Shaft
		if shaft == null or not shaft.is_inside_tree():
			continue
		var offset: Vector3 = at - shaft.global_position
		offset.y = 0.0
		if offset.length() <= Shaft.RADIUS:
			return shaft
	return null
