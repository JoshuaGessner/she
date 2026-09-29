class_name EnemyVisual
extends Node3D

## Presentation stays below the actor because gameplay owns the body transform,
## hitboxes and replicated decisions. This consumes those decisions locally: a
## remote peer can animate from the transform and state it already receives.

const HUNTER_MODEL: String = "res://art/heroes/gullsjukr.glb"

enum HunterPresentation { NONE, COLLECT, TAKE, SHRUG }

const ENEMY_SUSPICIOUS: int = 1
const ENEMY_ALERTED: int = 2
const ENEMY_CALLING: int = 3
const ENEMY_SWARM: int = 4
const ENEMY_STAGGERED: int = 5
const ENEMY_DEAD: int = 6

const ATTACK_TELEGRAPH: int = 1
const ATTACK_ACTIVE: int = 2
const ATTACK_RECOVERY: int = 3

const HUNTER_COURSING: int = 1
const HUNTER_SIGHTED: int = 2
const HUNTER_COLLECTING: int = 3
const HUNTER_LOST: int = 4

## Measured from the authored foot plants. A cycle advances from metres moved,
## rather than a clock, so host and client copies do not skate at different
## speeds between their replicated transform samples.
const ENEMY_WALK_STRIDE: float = 1.05
const ENEMY_RUN_STRIDE: float = 1.65
const HUNTER_WALK_STRIDE: float = 0.693
const HUNTER_RUN_STRIDE: float = 1.089

var _model: Node3D = null
var _player: AnimationPlayer = null
var _clip: StringName = &""
var _last_at: Vector3 = Vector3.ZERO
var _has_last_at: bool = false
var _walk_metres: float = 0.0
var _run_metres: float = 0.0
var _loop_time: float = 0.0
var _moved: float = 0.0
var _materials: Array[Dictionary] = []
var _rig: Skeleton3D = null
var _blend_from: Array[Transform3D] = []
var _blend_elapsed: float = 1.0
var _delta: float = 0.0
var _sling_stone: MeshInstance3D = null


func configure_enemy(kind: EnemyResource) -> void:
	_configure(kind.visual_path)


func configure_hunter() -> void:
	_configure(HUNTER_MODEL)


func _configure(path: String) -> void:
	if _model != null:
		_model.queue_free()
		_model = null
		_player = null
		_materials.clear()
	if path.is_empty():
		push_error("enemy visual has no model path")
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("could not load enemy visual '%s'" % path)
		return
	_model = packed.instantiate() as Node3D
	if _model == null:
		push_error("enemy visual '%s' is not a Node3D" % path)
		return
	# The shared rig's authored forward is +Z; Godot actors face -Z.
	_model.rotation.y = PI
	add_child(_model)
	InkPass.classify(_model)
	var players: Array[Node] = _model.find_children("*", "AnimationPlayer", true, false)
	_player = players[0] as AnimationPlayer if not players.is_empty() else null
	var rigs: Array[Node] = _model.find_children("*", "Skeleton3D", true, false)
	_rig = rigs[0] as Skeleton3D if not rigs.is_empty() else null
	_sling_stone = _model.find_child("sling_stone", true, false) as MeshInstance3D
	if _player == null:
		push_error("enemy visual '%s' has no AnimationPlayer" % path)
	else:
		_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_snapshot_materials()


func _snapshot_materials() -> void:
	if _model == null:
		return
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface: int in range(mesh.mesh.get_surface_count()):
			var source := mesh.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as BaseMaterial3D
			mesh.set_surface_override_material(surface, material)
			_materials.append({"material": material, "base": material.albedo_color})


## State brightness must reach the authored material families without turning
## the Gold-Sick's gold into a flat proxy colour.
func set_tint(tint: Color) -> void:
	for entry: Dictionary in _materials:
		var material := entry["material"] as BaseMaterial3D
		var base: Color = entry["base"]
		if material != null:
			material.albedo_color = base * (0.6 + tint.r * 0.8)


func present_enemy(state: int, attack: int, state_progress: float,
		attack_progress: float, at: Vector3, delta: float) -> void:
	_delta = delta
	if _sling_stone != null:
		_sling_stone.visible = attack != ATTACK_ACTIVE and not (
			attack == ATTACK_RECOVERY and attack_progress < 0.75)
	_track_distance(at)
	_loop_time += delta
	if state == ENEMY_DEAD:
		_play_event(&"death", state_progress)
		return
	if state == ENEMY_STAGGERED:
		_play_event(&"stagger", state_progress)
		return
	if attack == ATTACK_TELEGRAPH:
		_play_event(&"telegraph", attack_progress)
		return
	if attack == ATTACK_ACTIVE:
		_play_event(&"attack", attack_progress)
		return
	if attack == ATTACK_RECOVERY:
		_play_event(&"recovery", attack_progress)
		return
	match state:
		ENEMY_SUSPICIOUS:
			if _moved > 0.0001:
				_play_locomotion(&"walk", ENEMY_WALK_STRIDE, _walk_metres)
			else:
				_play_loop(&"search")
		ENEMY_ALERTED, ENEMY_SWARM:
			if _moved > 0.0001:
				_play_locomotion(&"run", ENEMY_RUN_STRIDE, _run_metres)
			else:
				_play_loop(&"idle")
		ENEMY_CALLING:
			_play_event(&"call", state_progress)
		_:
			# **An unaware body walking home walks** (ADR-275). `_settle` steers
			# an UNAWARE enemy back to its post, and this played `idle` all the
			# way there: a body gliding across the floor with its feet still.
			_idle_or_walk(ENEMY_WALK_STRIDE)


func present_hunter(state: int, presentation: int, presentation_progress: float,
		at: Vector3, delta: float) -> void:
	_delta = delta
	_track_distance(at)
	_loop_time += delta
	match presentation:
		HunterPresentation.COLLECT:
			_play_event(&"collect", presentation_progress)
			return
		HunterPresentation.TAKE:
			_play_event(&"take", presentation_progress)
			return
		HunterPresentation.SHRUG:
			_play_event(&"shrug", presentation_progress)
			return
	match state:
		HUNTER_COURSING:
			_play_locomotion(&"walk", HUNTER_WALK_STRIDE, _walk_metres)
		HUNTER_SIGHTED:
			if _moved > 0.0001:
				_play_locomotion(&"run", HUNTER_RUN_STRIDE, _run_metres)
			else:
				_play_loop(&"idle")
		HUNTER_COLLECTING:
			# It enters COLLECTING while still crossing the room. The stoop begins
			# only when the host publishes HunterPresentation.COLLECT at the bait.
			_play_locomotion(&"walk", HUNTER_WALK_STRIDE, _walk_metres)
		HUNTER_LOST:
			if _moved > 0.0001:
				_play_locomotion(&"walk", HUNTER_WALK_STRIDE, _walk_metres)
			else:
				_play_loop(&"search")
		_:
			# Distant, or anything added after it: still unless it is going
			# somewhere, and walking if it is (ADR-275).
			_idle_or_walk(HUNTER_WALK_STRIDE)


## Idle while standing, walking while not — for the states that have no clip of
## their own, so nothing a body does while moving can play with its feet still.
func _idle_or_walk(stride: float) -> void:
	if _moved > 0.0001:
		_play_locomotion(&"walk", stride, _walk_metres)
	else:
		_play_loop(&"idle")


func _track_distance(at: Vector3) -> void:
	if not _has_last_at:
		_last_at = at
		_has_last_at = true
		return
	var moved: Vector3 = at - _last_at
	moved.y = 0.0
	var metres: float = moved.length()
	_moved = metres
	_walk_metres += metres
	_run_metres += metres
	_last_at = at


func _play_locomotion(clip: StringName, stride: float, metres: float) -> void:
	if _player == null or not _player.has_animation(clip):
		return
	var length: float = _player.get_animation(clip).length
	if length > 0.0:
		_sample(clip, fposmod(metres / stride, 1.0) * length)


func _play_loop(clip: StringName) -> void:
	if _player == null or not _player.has_animation(clip):
		return
	var length: float = _player.get_animation(clip).length
	if length > 0.0:
		_sample(clip, fposmod(_loop_time, length))


func _play_event(clip: StringName, progress: float) -> void:
	if _player == null or not _player.has_animation(clip):
		return
	var length: float = _player.get_animation(clip).length
	if length > 0.0:
		_sample(clip, clampf(progress, 0.0, 1.0) * length)


## Seeking a paused AnimationPlayer does not advance its crossfade clock.
## Blend the sampled skeleton explicitly so locomotion and interrupts soften,
## while the three combat phases meet at their authored boundary poses.
func _sample(clip: StringName, time: float) -> void:
	if _rig == null:
		return
	if _clip != clip:
		_blend_from.clear()
		for bone: int in range(_rig.get_bone_count()):
			_blend_from.append(_rig.get_bone_pose(bone))
		_blend_elapsed = 1.0 if clip in [&"attack", &"recovery"] else 0.0
		_clip = clip
		_player.play(clip, 0.0)
	_player.seek(time, true)
	_blend_elapsed += _delta
	var amount: float = clampf(_blend_elapsed / 0.10, 0.0, 1.0)
	if amount < 1.0:
		for bone: int in range(_rig.get_bone_count()):
			var target: Transform3D = _rig.get_bone_pose(bone)
			_rig.set_bone_pose(bone, _blend_from[bone].interpolate_with(target, amount))
