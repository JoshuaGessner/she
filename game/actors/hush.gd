class_name Hush
extends Node3D

## A broken hush rune: a circle on the floor where nothing sounds, until the
## stave cracks (`M4-T32`, `DES-023`, ADR-221).
##
## `HushTrait` has the numbers and this is the thing they describe. It **does
## not silence anything itself**. Sound enters the world in exactly two places —
## `ClamorSource.add`, which every step, swing, pickup and enemy call passes
## through, and `ClamorField.deposit`, where an arrow or a sprung snare lands its
## noise straight into the field — and both ask `Hush.silences` before they
## accept a sound. So there is one rule, read where it applies, and no second
## noise path that a new sound could forget to check.
##
## A source standing inside also **carries no radius** while it is inside
## (`ClamorSource.audible_radius`): a bag of coin rings whether or not you move,
## and a circle that let the ringing through would not be *nothing makes a
## sound*.
##
## ## The crack
##
## When the time runs out the circle is gone and a `ClamorSource` at its centre
## makes one loud pulse. A source rather than a field deposit — the snare's
## choice — because the pulse is meant to be **heard**: an enemy's ears are
## `ClamorSensor`, which reads sources, while the field is the Gullsjúkr's alone.
## A crack only the Hunter noticed would be a price half the floor never charged.
## The source is made when the circle is, so the field has long since subscribed
## to it by the time it speaks.
##
## ## Seen, not only heard (`DES-018`)
##
## A thin ring at the edge, which is the circle, and an inner ring closing on the
## centre as the time runs out, which is *when it cracks*. The crack flares the
## ring before it fades, so muted play reads the same event.

## Who is standing in one. A static list rather than a group, because it is
## asked for every sound and by every enemy's ears every frame — a group lookup
## allocates an array each time, and on a floor with no circle this must cost
## nothing at all.
static var _live: Array[Hush] = []

## The height a circle reaches above and below its floor ⟨tune⟩ — one storey of
## ADR-054's kit, so a hush on a gallery does not silence the hall beneath it.
const REACH_HEIGHT: float = 3.0

## Seconds the spent ring stays after the crack. Long enough to see what just
## made that noise, and to find the place again.
const LINGER: float = 2.0

const REPLICATED_PROPERTIES: Dictionary = {
	".:cracked": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
}
const REPLICATION_HZ: float = 10.0

const EDGE_COLOUR: Color = Color(0.55, 0.62, 0.66)

var radius: float = 6.0
var seconds: float = 10.0
var crack: float = 10.0

## Seconds of silence left. Counted on every peer from the spawn packet, for the
## closing ring only; **the host alone decides the crack**, and `cracked` is how
## every other peer learns it happened.
var left: float = 10.0

var cracked: bool = false:
	set(value):
		if cracked == value:
			return
		cracked = value
		_dress()
		# In the setter, so every peer plays it from the replicated value —
		# the snare's reasoning, and `DES-018`'s twin of the flare above.
		Foley.at(self, Foley.Sound.HIT, 0.45, 6.0)

var _source: ClamorSource = null
var _edge: MeshInstance3D = null
var _closing: MeshInstance3D = null


## Whether a sound made at `at` is swallowed by a circle.
static func silences(at: Vector3) -> bool:
	for hush: Hush in _live:
		if hush.covers(at):
			return true
	return false


func covers(at: Vector3) -> bool:
	if cracked or not is_inside_tree():
		return false
	var offset: Vector3 = at - global_position
	if absf(offset.y) > REACH_HEIGHT:
		return false
	offset.y = 0.0
	return offset.length() <= radius


func configure_replication() -> void:
	var config := SceneReplicationConfig.new()
	for path: String in REPLICATED_PROPERTIES:
		var property := NodePath(path)
		config.add_property(property)
		config.property_set_spawn(property, true)
		config.property_set_replication_mode(property,
			int(REPLICATED_PROPERTIES[path]))
	var sync := MultiplayerSynchronizer.new()
	sync.name = "HushSync"
	sync.replication_config = config
	sync.replication_interval = 1.0 / REPLICATION_HZ
	sync.delta_interval = 1.0 / REPLICATION_HZ
	add_child(sync)


func _enter_tree() -> void:
	if not _live.has(self):
		_live.append(self)


func _exit_tree() -> void:
	_live.erase(self)


func _ready() -> void:
	left = seconds
	_source = ClamorSource.new()
	_source.name = "Crack"
	_source.add_to_group("clamor_sources")
	add_child(_source)

	_edge = MeshInstance3D.new()
	_edge.mesh = TorusMesh.new()
	_edge.position.y = 0.03
	add_child(_edge)
	_closing = MeshInstance3D.new()
	_closing.mesh = TorusMesh.new()
	_closing.position.y = 0.03
	add_child(_closing)
	_dress()


func _process(delta: float) -> void:
	if cracked:
		return
	left = maxf(0.0, left - delta)
	_close_ring()
	if not multiplayer.is_server() or left > 0.0:
		return
	# Out of the list's reach before the pulse, so the crack is not swallowed
	# by the circle it is the end of.
	cracked = true
	_source.add(crack)
	var fade: SceneTreeTimer = get_tree().create_timer(maxf(LINGER,
		crack / maxf(Config.tuning.clamor_decay, 0.001)))
	fade.timeout.connect(queue_free)


## Blockout, per ADR-046. A cold colour on purpose: `ART-005` spends the warm
## saturated one on treasure, and a circle the eye mistook for gold would be a
## lie told to the greed the whole floor runs on.
func _dress() -> void:
	if _edge == null:
		return
	var edge := _edge.mesh as TorusMesh
	edge.inner_radius = maxf(0.01, radius - 0.12)
	edge.outer_radius = radius
	var skin := StandardMaterial3D.new()
	skin.albedo_color = EDGE_COLOUR
	skin.emission_enabled = true
	skin.emission = EDGE_COLOUR
	skin.emission_energy_multiplier = 2.4 if cracked else 0.35
	_edge.material_override = skin
	_closing.material_override = skin
	_closing.visible = not cracked
	_close_ring()


func _close_ring() -> void:
	if _closing == null:
		return
	var inner := _closing.mesh as TorusMesh
	var reach: float = radius * clampf(left / maxf(seconds, 0.001), 0.0, 1.0)
	inner.outer_radius = maxf(0.08, reach)
	inner.inner_radius = maxf(0.02, reach - 0.06)
