class_name Exposure
extends Node3D

## How brightly lit this body is, and therefore how far away it can be seen
## (`M4-T13`, `DES-009`, `ART-001`).
##
## ## This is the visual twin of `ClamorSource`, and deliberately *not* of
## ## `ClamorField`
##
## `DES-009` says light should be *"built on the same Clamor field the Hunt uses
## — one system, two consumers."* The economy is right and the layer is wrong,
## and the codebase already draws the distinction that settles it (ADR-073):
##
## | | Answers |
## |---|---|
## | `ClamorSource.audible_at()` | *can that enemy hear me **right now*** |
## | `ClamorField` | *where in the level was noise, and **how long ago*** |
##
## **The field is a memory of events.** Its entire justification is that the
## Hunter does not know where you are — it knows where noise *was*, which is
## what makes shaking it real rather than performative. Light has no past
## tense. A lantern is a *state attached to a moving body*: it is either
## reaching you from where it is now, or it is not.
##
## Put light in the field and you get a luminous trail the player left five
## seconds ago that enemies still walk toward — which is not what light does.
## Decay it fast enough to fix that and you have built a grid whose values only
## ever describe the current frame: a per-body query, wearing a field's costume.
##
## So light enters the world at `ClamorSource`'s layer instead. Both are
## per-body, instantaneous, occlusion-tested, host-authored and replicated
## `ON_CHANGE`; one is read by ears and one by eyes. `DES-018`'s rule that
## *every audio channel has a visual twin* turns out to be true of the systems
## and not only of the feedback (ADR-188).
##
## ## What it costs
##
## One pass per body per tick over the floor's lights, at 10 Hz, for at most
## four bodies. The distance test runs first and the ray only runs for a lamp
## that could actually beat the brightest one found so far, so a floor full of
## doorway lamps costs a handful of rays rather than one per lamp.

## Sampled at the chest rather than the feet: a lamp on the far side of a low
## wall lights your head and shoulders, and that is the half an enemy sees.
const CHEST: float = 1.1

## Recomputed at `ClamorField`'s rate and for its reason — nobody can react
## faster than this changes, and a per-frame pass would spend the budget on
## resolution no player can perceive.
const TICK_HZ: float = 10.0

## 0 is as dark as the floor gets, 1 is standing in open flame. **Host-authored
## and replicated**, like `ClamorSource.level` and for the same reason
## (`TEC-004`): the host owns consequences, and a client that computed its own
## would be arguing with the value arriving over the wire.
var level: float = 0.0

var _lantern: Lantern = null
var _accumulated: float = 0.0


## The body's own light, if it has one. Told rather than found: `Player` owns
## the tree and this node must not go looking through it (`TEC-001`, calls down).
func watch(lamp: Lantern) -> void:
	_lantern = lamp


## Metres at which an enemy can see this body right now.
##
## **The single owner of the derivation.** `Enemy._can_see` and the debug
## overlay both call it, so the ring drawn on screen cannot disagree with the
## sight that killed you — ADR-187's lesson from the Shaft, where two owners of
## one derivation immediately produced a prompt that lied about its own verb.
func seen_from() -> float:
	var tuning: TuningProfile = Config.tuning
	return lerpf(tuning.enemy_vision_dark, tuning.enemy_vision_range,
		clampf(level, 0.0, 1.0))


func _ready() -> void:
	set_physics_process(multiplayer.is_server())


func _physics_process(delta: float) -> void:
	_accumulated += delta
	var step: float = 1.0 / TICK_HZ
	if _accumulated < step:
		return
	_accumulated = 0.0
	level = _measure()


## The brightest thing that can reach this body, floored at the ambient light
## the level never turns off.
##
## **A maximum, not a sum.** Two lamps do not make you twice as visible; the
## nearer one already gave you away, and summing would mean a corridor of dim
## lamps quietly exceeding a lantern held to your face.
func _measure() -> float:
	var tuning: TuningProfile = Config.tuning
	var brightest: float = tuning.exposure_ambient
	# **Your own lantern exposes you by its `glare`, not by its falloff.** The
	# lamp hangs 0.35 m away, so the distance curve below would return ~0.97
	# for it and `LightTrait.glare` would be a field nothing reads — the exact
	# shape ADR-098 keeps finding. Carrying a light is its own fact.
	if _lantern != null and _lantern.burning():
		brightest = maxf(brightest, _lantern.glare())

	var at: Vector3 = global_position + Vector3.UP * CHEST
	for node: Node in get_tree().get_nodes_in_group(Lantern.LIGHT_GROUP):
		var light := node as OmniLight3D
		if light == null or not light.is_visible_in_tree():
			continue
		# Our own lamp is in this group for everybody else's benefit. It has
		# already been counted above, at its `glare` rather than at its
		# falloff — see `Lantern.owns`.
		if _lantern != null and _lantern.owns(light):
			continue
		var distance: float = at.distance_to(light.global_position)
		if distance >= light.omni_range:
			continue
		var here: float = 1.0 - distance / light.omni_range
		# Cheapest test first, and it is not only an optimisation: a lamp that
		# cannot beat what we already have needs no ray, so a floor of dim
		# doorway lights costs almost nothing next to one lantern.
		if here <= brightest:
			continue
		if not _reaches(light.global_position, at):
			continue
		brightest = here
	return minf(1.0, brightest)


## Light travels in straight lines and stops at walls. **This is the one place
## light and noise genuinely differ in physics**, and it is why they are two
## functions rather than one: `ClamorSource.reach` spends an occluder budget so
## sound rounds a corner and dies through a wall, and a lamp behind a wall
## contributes exactly nothing.
func _reaches(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = CollisionLayers.WORLD
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
