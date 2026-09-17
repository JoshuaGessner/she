class_name Acoustics
extends Object

## **What the stone does to a sound** (`M4-T12`, `TEC-005`).
##
## `ART-002` costed occlusion and reverb as a week and named them the half of
## the audio work that makes the Deep sound like a place. `TEC-005` corrected
## the reverb half — Godot does it natively — and settled the occlusion half:
## there is no built-in feature, but `AudioStreamPlayer3D` carries a per-source
## low-pass that is settable at runtime, so occlusion is **a raycast and a
## lerp**. This is that, and the room's own sound is `AudioDirector`'s, because
## `DES-018` gives it the buses.
##
## ## Five rays, not one
##
## Binary occlusion is the thing that makes a doorway sound like a switch: a
## footstep is either in the room with you or gone, and a player sidestepping a
## doorframe hears the world flick. `TEC-005` asks for **gradient** occlusion
## instead — the emitter's own point and four around it, so a sound half behind
## a corner is half muffled — and calls it cheap and a large perceptual win.
##
## ## A readout, never a consequence
##
## Occlusion changes what a **player** hears and nothing else. What an *enemy*
## hears is `ClamorField`, which is host-authoritative and knows nothing about
## this file; a sound muffled here is still a sound the dungeon heard at full
## strength. Keeping those apart is what stops a client's audio settings from
## being a stealth advantage — and it is why this runs on every peer for its
## own screen (`TEC-004`: audio is client-side, driven by replicated state).

## Every 3D sound that the world should be allowed to muffle. A group rather
## than a list the director keeps, because sources are made in a dozen places
## and die on their own — `Foley` frees a one-shot when it ends.
const GROUP: StringName = &"heard"

## Where the four extra rays land, in metres, around the emitter's own point:
## far enough apart to straddle a doorframe, close enough to still be that
## sound rather than a guess about the room.
##
## Lifted, because a world sound is played at the emitter's own origin, which
## is something's feet: a ray that ends on the floor slab hits the floor, and
## a sound sitting exactly on it measures as fully behind a wall.
const SPREAD: float = 0.6
## How far a sample point is lifted off the ground, in metres — below knee
## height, so it is still that sound rather than a guess about the room.
const LIFT: float = 0.4

## What a source sounded like before anything was done to it, kept on the node
## so the muffle is always applied to the caller's own volume rather than
## compounding on the last frame's.
const DRY: StringName = &"acoustics_dry_db"
## Where this source is headed: recomputed on its turn, approached every frame.
const AIM: StringName = &"acoustics_aim"

## How many sources recompute their rays per frame. `TEC-005` budgets
## *"~20–30 audible sources, staggered across frames at ~10 Hz"*, which at 60 fps
## is four a frame: twenty-four sources all refreshed ten times a second, and a
## noisier moment degrading into a slower refresh rather than a frame spike.
const PER_FRAME: int = 4

static var _turn: int = 0
## Rays cast since boot, so a check can hold the refresh to its budget.
static var _rays: int = 0


## How many rays this system has cast. `TEC-005` budgets the refresh rather
## than the ray, and a budget nothing counts is a hope.
static func rays() -> int:
	return _rays


## **This sound can be muffled.** Called where a 3D source is made, with its
## volume already set: the first measurement is taken now rather than on the
## next tick, because a footstep three rooms away that arrives clear and
## muffles a tenth of a second later has already told the lie.
static func heard(player: AudioStreamPlayer3D) -> void:
	if player == null:
		return
	player.add_to_group(GROUP)
	player.set_meta(DRY, player.volume_db)
	var aim: float = blocked(player)
	player.set_meta(AIM, aim)
	_apply(player, aim)


## Every source's turn, in order, a few each frame; and every source moves
## toward what it was last told, whether or not this was its turn.
static func tick(tree: SceneTree, delta: float) -> void:
	if tree == null:
		return
	var heard_now: Array[Node] = tree.get_nodes_in_group(GROUP)
	if heard_now.is_empty():
		_turn = 0
		return
	_turn = _turn % heard_now.size()
	for i: int in mini(PER_FRAME, heard_now.size()):
		var source := heard_now[(_turn + i) % heard_now.size()] as AudioStreamPlayer3D
		if source != null:
			source.set_meta(AIM, blocked(source))
	_turn = (_turn + PER_FRAME) % heard_now.size()

	# A tenth of a second of travel ⟨tune⟩, so stepping through a doorway is a
	# sound opening rather than a cut.
	var step: float = clampf(delta / maxf(Config.tuning.muffle_travel_seconds, 0.001), 0.0, 1.0)
	for node: Node in heard_now:
		var source := node as AudioStreamPlayer3D
		if source == null or not source.has_meta(AIM):
			continue
		var was: float = _now(source)
		_apply(source, lerpf(was, float(source.get_meta(AIM)), step))


## How much stone stands between the ear and a sound, from 0 (nothing) to 1.
static func blocked(player: AudioStreamPlayer3D) -> float:
	if player == null or not player.is_inside_tree():
		return 0.0
	var ear: Camera3D = player.get_viewport().get_camera_3d()
	var world: World3D = player.get_world_3d()
	if ear == null or world == null:
		return 0.0
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	if space == null:
		return 0.0
	var from: Vector3 = ear.global_position
	var at: Vector3 = player.global_position + Vector3(0.0, LIFT, 0.0)
	var hits: int = 0
	var points: Array[Vector3] = [at,
		at + Vector3(SPREAD, 0.0, 0.0), at + Vector3(-SPREAD, 0.0, 0.0),
		at + Vector3(0.0, 0.0, SPREAD), at + Vector3(0.0, 0.0, -SPREAD)]
	for point: Vector3 in points:
		var query := PhysicsRayQueryParameters3D.create(from, point,
			CollisionLayers.WORLD)
		# Bodies are not walls to sound. A teammate standing between you and a
		# footstep does not mute it, and `WORLD` is the only layer the level's
		# own geometry carries.
		query.collide_with_areas = false
		_rays += 1
		if not space.intersect_ray(query).is_empty():
			hits += 1
	return float(hits) / float(points.size())


## What a source is muffled by right now, read back off the filter — so the
## lerp has something to start from without a second copy of the state.
static func _now(player: AudioStreamPlayer3D) -> float:
	var tuning: TuningProfile = Config.tuning
	var span: float = tuning.muffle_clear_hz - tuning.muffle_blocked_hz
	if absf(span) < 0.001:
		return 0.0
	return clampf((tuning.muffle_clear_hz - player.attenuation_filter_cutoff_hz)
		/ span, 0.0, 1.0)


static func _apply(player: AudioStreamPlayer3D, aim: float) -> void:
	var tuning: TuningProfile = Config.tuning
	var shut: float = clampf(aim, 0.0, 1.0)
	player.attenuation_filter_cutoff_hz = lerpf(tuning.muffle_clear_hz,
		tuning.muffle_blocked_hz, shut)
	# The filter alone reads as *further away* rather than *behind something*;
	# the few dB are what make it a wall. The source's own volume is the
	# baseline, so a quiet sound stays quiet and this never compounds.
	var dry: float = float(player.get_meta(DRY, player.volume_db))
	player.volume_db = dry + tuning.muffle_blocked_db * shut
