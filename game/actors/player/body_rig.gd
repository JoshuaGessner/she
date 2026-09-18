class_name BodyRig
extends Node3D
## The body a teammate sees, posed in code (`M4-T05`, ADR-046 blockout).
##
## Until now every other player was a **capsule**. The shared humanoid rig has
## existed since `M1-T10` — 28 joints and seven gear sockets, placed to the
## millimetre and asserted by `rig_probe.gd` — and nothing in the game had ever
## instanced it. This is the file that uses it.
##
## ## Why the motion is procedural
##
## The rig carries **no animation clips at all**; the developer's call was to
## drive it from code until authored clips exist. That is a gate decision rather
## than a fallback (`ADR-064`): when clips arrive they replace this, and nothing
## in gameplay code changes, because nothing in gameplay code knows this file
## exists beyond `step()`.
##
## ## The gait is driven by distance, not by time
##
## A cycle advances with **metres travelled**, so the feet keep pace with the
## ground at any speed and a body that is walking slowly takes slow steps rather
## than the same steps more faintly. Driving the phase off a clock is what
## produces skating, and it is the single most visible tell of a cheap
## procedural walk.
##
## ## Nothing here is replicated, and that is the point
##
## Every input to `step()` is something the watching peer already knows:
## position deltas it is interpolating anyway (`Player._ease_toward_the_wire`),
## the replicated stance, and the replicated pitch. **A remote body animates
## from what the wire already carries**, so a party of four costs exactly as
## much bandwidth as it did when everyone was a capsule — which is the budget
## `TEC-004` actually defends.
##
## ## Bone axes are read from the rig, never assumed
##
## A bone swings about whichever of *its own* axes happens to line up with the
## body's left-right axis, and on this rig that is not the same axis for every
## bone: the legs and spine are axis-aligned, and the arms rest in a twisted
## A-pose where `upper_arm_l`'s local X points (0.50, 0.50, 0.71). Hard-coding
## per-bone axes would be a table that silently rots the first time the rig is
## re-exported. Each axis is derived from the bone's own rest basis instead, so
## a re-export moves the axes with it.

## The rig itself. Preloaded rather than looked up: the dependency is then a
## parse error if the art moves, instead of a body that silently fails to exist.
const RIG: PackedScene = preload("res://art/characters/humanoid_rig.glb")

## Metres of travel per complete two-step cycle ⟨tune⟩. Measured against the
## rig's 1.80 m and `walk_speed`; shorter reads as a scurry, longer as a stride
## the legs cannot reach.
const STRIDE_METRES: float = 1.75
## How far the thigh swings at full walking speed, radians ⟨tune⟩.
const THIGH_SWING: float = 0.55
## How far the knee folds behind, radians ⟨tune⟩. Knees bend one way only, so
## this is applied to the back half of the cycle and never the front.
const KNEE_BEND: float = 0.95
## Arm counter-swing, radians ⟨tune⟩. Deliberately smaller than the legs: equal
## amplitude reads as marching.
const ARM_SWING: float = 0.38
## How far the hips rise and fall across a stride, metres ⟨tune⟩.
const BOB_METRES: float = 0.045
## Breath, for a body that is standing still ⟨tune⟩ — radians of chest pitch and
## cycles per second.
const BREATH_RADIANS: float = 0.022
const BREATH_HZ: float = 0.22
## Above this fraction of walking speed the gait is at full amplitude ⟨tune⟩.
## Below it the swing fades out rather than snapping off, so the last step
## before a stop is a step rather than a twitch.
const FULL_GAIT_AT: float = 0.55
## How fast the amplitude chases the speed it wants ⟨tune⟩. This is the only
## smoothing in the file: everything else is a function of where the body is.
const GAIT_EASE: float = 7.0
## Crouch, radians and metres ⟨tune⟩ — thigh forward, knee folded, hips dropped.
const CROUCH_THIGH: float = 0.95
const CROUCH_KNEE: float = 1.45
const CROUCH_DROP: float = 0.30
## How far a downed body folds, radians ⟨tune⟩.
const DOWNED_PITCH: float = 1.25
## How much of the camera's pitch the neck and head carry ⟨tune⟩. Not all of it:
## a head that tracks a look exactly reads as a turret, and `DES-018` only needs
## a teammate's attention to be legible, never precise.
const HEAD_PITCH_SHARE: float = 0.55
const NECK_PITCH_SHARE: float = 0.25

## The bones this file poses. Anything not named here keeps its rest pose, which
## is what makes the rig's own author the authority on everything else.
const POSED: Array[String] = [
	"pelvis", "spine_01", "chest", "neck", "head",
	"thigh_l", "calf_l", "thigh_r", "calf_r",
	"upper_arm_l", "upper_arm_r", "forearm_l", "forearm_r",
]

## What a living teammate is made of. Kept in the scene rather than here
## because it is the one value on this body a designer would argue about:
## lighter than every enemy state (0.20–0.52) and darker than the telegraph
## flash (0.95), so a teammate is never mistaken for a threat at a glance, and
## the distinction is **value** because `ART-005` spends saturated colour on
## treasure. It replaces the rig's own `proxy_grey`.
@export var teammate_skin: StandardMaterial3D = null

var _skeleton: Skeleton3D = null
var _mesh: MeshInstance3D = null
## Bone name -> index, and bone name -> the local axis that swings it forward.
var _bone: Dictionary = {}
var _swing: Dictionary = {}
var _rest_y: float = 0.0

var _phase: float = 0.0
var _gait: float = 0.0
var _breath: float = 0.0


func _ready() -> void:
	var body: Node = RIG.instantiate()
	add_child(body)
	_skeleton = _find_skeleton(body)
	if _skeleton == null:
		push_error("BodyRig: the rig has no Skeleton3D — gear and pose have "
			+ "nothing to hang on")
		return
	_mesh = _find_mesh(body)
	if _mesh != null and teammate_skin != null:
		_mesh.set_surface_override_material(0, teammate_skin)
	for name: String in POSED:
		var index: int = _skeleton.find_bone(name)
		if index < 0:
			push_warning("BodyRig: the rig has no bone '%s'" % name)
			continue
		_bone[name] = index
		# The axis that swings this bone forward and back, expressed in the
		# bone's own space. `get_bone_global_rest().basis` maps bone-local to
		# skeleton space, so its inverse carries the body's left-right axis the
		# other way — which is the axis a hip or a shoulder actually turns on,
		# whatever pose the rig was exported in.
		var rest: Basis = _skeleton.get_bone_global_rest(index).basis
		_swing[name] = (rest.inverse() * Vector3.RIGHT).normalized()
	if _bone.has("pelvis"):
		_rest_y = _skeleton.get_bone_global_rest(_bone["pelvis"]).origin.y


## How far the furthest foot reaches in front of or behind the hips, in metres.
##
## **Fore-and-aft, not the gap between the feet.** The gap was the first
## observable and it was the wrong one: with the hip swing zeroed to prove the
## check could fail, the knees still folded, the feet still parted by a quarter
## of a metre, and the row passed on a body whose legs were not striding at all.
## A stride is displacement *along the direction of travel*, so that is what
## this measures — and a body that has stopped striding now reads as one.
##
## It is also the one thing a check on the far side of a network can ask without
## a second copy of the gait to compare against.
func stride_reach() -> float:
	if _skeleton == null or not _bone.has("pelvis"):
		return 0.0
	var hips: float = _skeleton.get_bone_global_pose(_bone["pelvis"]).origin.z
	var reach: float = 0.0
	for name: String in ["foot_l", "foot_r"]:
		var index: int = _skeleton.find_bone(name)
		if index < 0:
			continue
		reach = maxf(reach,
			absf(_skeleton.get_bone_global_pose(index).origin.z - hips))
	return reach


## Bone names this rig actually has, for the check that the art still carries
## what the pose expects.
func posed_bones() -> Array[String]:
	var out: Array[String] = []
	for name: String in POSED:
		if _bone.has(name):
			out.append(name)
	return out


## Where the hips sit, for the check that a crouch bends the body rather than
## resizing it.
func pelvis_height() -> float:
	if _skeleton == null or not _bone.has("pelvis"):
		return 0.0
	return _skeleton.get_bone_global_pose(_bone["pelvis"]).origin.y


## The surface a skin override is applied to — the faint teammate, the Vörðr and
## the body that got out all dress this (`Player._dress_as_out`).
func mesh() -> MeshInstance3D:
	return _mesh


## Pose the body for this frame.
##
## `speed` is metres per second along the ground, `of_walking` is what this body
## calls a walk, `stance` is 0 standing to 1 crouched, and `pitch` is where the
## head is looking. None of it is replicated; all of it is already known.
func step(delta: float, speed: float, of_walking: float, stance: float,
		pitch: float, downed: bool) -> void:
	if _skeleton == null:
		return
	# Distance, not time: the feet then keep pace with the ground instead of
	# running their own clock while the body slides along under them.
	_phase = fposmod(_phase + (speed * delta / STRIDE_METRES) * TAU, TAU)
	_breath = fposmod(_breath + delta * BREATH_HZ * TAU, TAU)
	var wants: float = clampf(
		speed / maxf(of_walking * FULL_GAIT_AT, 0.001), 0.0, 1.0)
	_gait = lerpf(_gait, wants, clampf(delta * GAIT_EASE, 0.0, 1.0))

	var swing: float = sin(_phase) * THIGH_SWING * _gait
	var fold: float = maxf(0.0, -sin(_phase)) * KNEE_BEND * _gait
	var fold_other: float = maxf(0.0, sin(_phase)) * KNEE_BEND * _gait

	_turn("thigh_l", swing + stance * CROUCH_THIGH)
	_turn("thigh_r", -swing + stance * CROUCH_THIGH)
	# Knees fold **backwards**, which is the opposite sign to the hip, and the
	# reason a knee cannot simply mirror its thigh.
	_turn("calf_l", -fold - stance * CROUCH_KNEE)
	_turn("calf_r", -fold_other - stance * CROUCH_KNEE)
	# Arms oppose the legs. A body carrying nothing still swings them, because
	# the alternative — arms that hang dead while the legs work — is the tell
	# that reads as a puppet rather than as a person.
	_turn("upper_arm_l", -swing * (ARM_SWING / THIGH_SWING))
	_turn("upper_arm_r", swing * (ARM_SWING / THIGH_SWING))
	_turn("forearm_l", -absf(swing) * 0.35)
	_turn("forearm_r", -absf(swing) * 0.35)

	var lean: float = stance * 0.28 + (DOWNED_PITCH if downed else 0.0)
	_turn("spine_01", lean * 0.45)
	_turn("chest", lean * 0.35 + sin(_breath) * BREATH_RADIANS * (1.0 - _gait))
	# The head keeps looking where the eyes are while the spine folds under it,
	# so the two have to cancel rather than compound.
	_turn("neck", pitch * NECK_PITCH_SHARE - lean * 0.4)
	_turn("head", pitch * HEAD_PITCH_SHARE - lean * 0.4)

	if _bone.has("pelvis"):
		var index: int = _bone["pelvis"]
		# Two steps per cycle, so the hips rise twice — hence the doubled phase.
		var bob: float = -absf(sin(_phase)) * BOB_METRES * _gait
		var rest: Vector3 = _skeleton.get_bone_rest(index).origin
		_skeleton.set_bone_pose_position(index,
			rest + Vector3(0.0, bob - stance * CROUCH_DROP, 0.0))


## Rotate one bone about its own swing axis. A bone this rig does not have is
## skipped rather than crashing: a re-export that drops a bone should lose that
## bone's motion, not the body.
func _turn(name: String, radians: float) -> void:
	if not _bone.has(name):
		return
	_skeleton.set_bone_pose_rotation(_bone[name],
		Quaternion(_swing[name], radians))


func _find_skeleton(node: Node) -> Skeleton3D:
	var found := node as Skeleton3D
	if found != null:
		return found
	for child: Node in node.get_children():
		var deeper: Skeleton3D = _find_skeleton(child)
		if deeper != null:
			return deeper
	return null


func _find_mesh(node: Node) -> MeshInstance3D:
	var found := node as MeshInstance3D
	if found != null:
		return found
	for child: Node in node.get_children():
		var deeper: MeshInstance3D = _find_mesh(child)
		if deeper != null:
			return deeper
	return null
