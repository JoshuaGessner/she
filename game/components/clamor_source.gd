class_name ClamorSource
extends Node3D

## How much noise this actor is making, right now (`M1-T04`, DES-005 Layer 1).
##
## Clamor is deposited by actions and decays continuously. The level maps to an
## **audible radius**, which DES-005 Layer 1 names directly: *"Clamor → wider
## aggro radius"*. That is the mechanic here.
##
## **Not the Clamor field.** TEC-001's decaying scalar grid — the one the
## Gullsjúkr navigates by gradient — is `M2-T02`, and is absent rather than
## approximated. These are two different consumers of the same fiction and both
## exist in the finished game: this one answers "can that enemy over there hear
## me", the field answers "where in the level was noise recently".
##
## Weight feeds straight into this. DES-005 Layer 1 again: *"You feel your greed
## in your legs"* — and in how far the sound of you carries.
##
## A Node3D rather than a Node so it carries its own position: a listener asking
## where a sound came from should not have to reach into the emitter's parent.

signal made_noise(amount: float, level: float)

## Walls muffle rather than block. TEC-001's field gets this for free by
## diffusing through open space; until it exists, each occluder between source
## and listener costs a fixed amount of *equivalent distance*, which produces
## the same shape — sound rounds a corner and dies through a wall.
const MAX_OCCLUDERS: int = 3

var level: float = 0.0

## The level this decays **to** rather than through — what you give away just
## by having it on you (`M2-T01`). Set by the actor from its inventory:
## `Inventory.total_clamor()` scaled by `clamor_carried_fraction`.
##
## `DES-005` Layer 1 makes greed continuous, player-caused pressure, and
## `DES-008` names clamor *the audible cost of greed*. A floor is what makes
## that true when you stop moving: coin rings in the bag, a gem catches every
## light in the dark, and neither cares that you are standing still. It is also
## what gives `DES-005`'s primal counter-play something to act on — **drop the
## loot and the floor drops with it, in the same frame** — and what `DES-017`
## means by *"shedding carried value can shake it"*.
##
## A floor rather than a constant addition, because the addition version was
## checked and it deletes stealth: a full glitter bag sums to 8.5, which is a
## permanent 13.6 m audible radius against a 16 m enemy vision range, and
## *"hide and let it pass"* is on `DES-005`'s own list of things that must work.
var carried_floor: float = 0.0


func _process(delta: float) -> void:
	# Noise is host-authoritative (`TEC-004`, ADR-082) and `level` is
	# replicated host→peer. A client that also decayed it locally would be
	# fighting the value arriving from the host twenty times a second, and the
	# two would settle somewhere neither of them meant — which would make the
	# debug ring disagree with the ears that actually heard you.
	if not multiplayer.is_server():
		return
	if is_equal_approx(level, carried_floor):
		return
	# Linear decay, not exponential: a decay curve with a long tail leaves a
	# faint level hanging around forever, and "am I quiet yet?" has to have a
	# definite answer the player can act on (DES-005 requirement 1).
	#
	# `max` against the floor rather than against zero, so a bag that just got
	# heavier raises the level on its own — and a bag that just got lighter
	# lets it fall further than it could a moment ago.
	level = maxf(carried_floor, level - Config.tuning.clamor_decay * delta)


func add(amount: float) -> void:
	if amount <= 0.0:
		return
	# **Party scaling lives here, at the one place noise enters the world**
	# (`M2-T07`, `DES-012`). Every footstep, swing, pickup and rummage from
	# every source passes through this function, so one multiplication makes a
	# four-stack super-linearly loud without a single system having to know how
	# many people are playing.
	#
	# Putting it on each emitter instead would have meant remembering it at a
	# dozen call sites, and the one forgotten site would be the one that made
	# the metric lie.
	amount *= PartyScaling.clamor(PartyScaling.size_of(self))
	level = minf(Config.tuning.clamor_maximum, level + amount)
	made_noise.emit(amount, level)


## Metres this actor carries in open air, before any wall is in the way.
func audible_radius() -> float:
	return level * Config.tuning.clamor_metres_per_unit


## As quiet as this actor can currently get — which is not zero once it is
## carrying anything. Used by the gym's measurement probes to start each sample
## from a known level; making it lie about a loaded bag would let a probe
## measure a silence the game never actually offers.
func silence() -> void:
	level = carried_floor


## How far sound travels from `origin` along `direction` before it runs out.
##
## **The single authority on occlusion.** Both the listener test below and the
## gym's debug ring call this, so the overlay cannot draw a shape the
## simulation disagrees with — a debug view that lies is worse than none,
## for the same reason a stale dashboard is.
static func reach(world: World3D, origin: Vector3, direction: Vector3,
		budget: float) -> float:
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	var penalty: float = Config.tuning.clamor_wall_penalty
	var travelled: float = 0.0
	var remaining: float = budget
	for i: int in range(MAX_OCCLUDERS):
		if remaining <= 0.0:
			return travelled
		var from: Vector3 = origin + direction * travelled
		var to: Vector3 = from + direction * remaining
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = CollisionLayers.WORLD
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			return travelled + remaining
		var step: float = from.distance_to(hit["position"] as Vector3)
		# Nudge past the surface so the next cast does not re-hit it.
		travelled += step + 0.02
		remaining -= step + penalty
	return travelled + maxf(0.0, remaining)


## True if a listener at `to` can currently hear this source.
func audible_at(to: Vector3) -> bool:
	var radius: float = audible_radius()
	if radius <= 0.0:
		return false
	var offset: Vector3 = to - global_position
	var distance: float = offset.length()
	if distance > radius:
		return false
	return reach(get_world_3d(), global_position, offset / distance, radius) >= distance
