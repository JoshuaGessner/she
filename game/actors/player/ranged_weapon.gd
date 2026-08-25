class_name RangedWeapon
extends Node3D

## A bow (`M3-T11`, ADR-123). Draw → loose → recovery, and it commits.
##
## `MeleeWeapon` is the shape this follows deliberately, down to the phase
## machine, the pose lerps and the *"stamina was spent on the owner's machine"*
## rule — the two are the same mechanism with a different verb at the end of the
## wind-up, and making them look alike is what stops them drifting into two
## different ideas of what an attack is.
##
## ## Built in code, and only when the body has one
##
## Unlike `MeleeWeapon`, this is not in `player.tscn`. Five of `DES-011`'s six
## classes carry no bow, and a node sitting hidden in every body for the one
## that does is a stub wearing a scene's clothes (ADR-064). It is created when
## it has work, which is ADR-066's rule for autoloads applied one level down.
##
## ## Where it comes from
##
## The class kit. `ClassResource.kit` already names real catalogue ids, and a
## kit entry carrying a `RangedTrait` is what puts a bow in the hand — so a
## designer arms a class by editing a `.tres`, per `CLAUDE.md`'s data-over-code
## rule, and nothing here knows what a Veiðimaðr is. `M3-T07` re-points this at
## an equipment slot; it moves the seam rather than adding a second one.
##
## ## One weapon at a time
##
## A body with a bow does not also swing. That is `DES-011`'s stated cost for
## this class — *"poor in a straight fight; a Stalker who is cornered is usually
## dead"* — expressed as the absence of a verb rather than as a penalty
## multiplier, and it means the bow needs no button of its own.

signal draw_started
## The owner's aim at the instant of release. Only the owner's copy is worth
## listening to: every peer runs this machine so the bow visibly bends, but the
## direction an arrow actually flies is the shooter's, not a replicated
## approximation of it arriving a frame late.
signal loosed

enum Phase { IDLE, DRAWING, RECOVERY }

## Blockout poses, as (position, rotation-in-degrees), on `MeleeWeapon`'s
## convention. The draw is the whole telegraph — ADR-053's 250 ms floor exists
## so an enemy can read one — so it has to be visible as travel, not as a state.
const POSE_REST: Array = [Vector3(0.34, -0.30, -0.66), Vector3(4, -8, -6)]
const POSE_DRAWN: Array = [Vector3(0.16, -0.16, -0.48), Vector3(-2, -26, -2)]

var _phase: Phase = Phase.IDLE
var _remaining: float = 0.0
var _duration: float = 0.0
var _model: Node3D = null
var _nock: MeshInstance3D = null
var _kit: RangedTrait = null


func _ready() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)

	# The stave, bent the wrong way round on purpose: a straight box reads as a
	# stick, and the point of a blockout mesh is that it is unmistakable at a
	# glance (`DES-009` legibility, ADR-046).
	var stave := MeshInstance3D.new()
	var arc := TorusMesh.new()
	arc.inner_radius = 0.30
	arc.outer_radius = 0.33
	stave.mesh = arc
	stave.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	_model.add_child(stave)

	# The nocked arrow, present only while drawn. Without it, a drawn bow and a
	# spent one are the same silhouette and the recovery is invisible.
	_nock = MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.012
	shaft.bottom_radius = 0.012
	shaft.height = 0.62
	_nock.mesh = shaft
	_nock.rotation_degrees.x = 90.0
	_model.add_child(_nock)

	_pose(POSE_REST, POSE_REST, 0.0)
	_update_nock()


## Give it a bow. A body that cannot shoot has no `RangedWeapon` at all rather
## than an unarmed one — see the header — so this is called exactly once, by
## `Player._arm_from_kit`, with something real.
func equip(bow: RangedTrait) -> void:
	_kit = bow


func kit() -> RangedTrait:
	return _kit


func phase() -> Phase:
	return _phase


func is_busy() -> bool:
	return _phase != Phase.IDLE


func _pose(from: Array, to: Array, t: float) -> void:
	_model.position = (from[0] as Vector3).lerp(to[0] as Vector3, t)
	_model.rotation = Vector3(
		deg_to_rad(lerpf((from[1] as Vector3).x, (to[1] as Vector3).x, t)),
		deg_to_rad(lerpf((from[1] as Vector3).y, (to[1] as Vector3).y, t)),
		deg_to_rad(lerpf((from[1] as Vector3).z, (to[1] as Vector3).z, t))
	)


func _update_pose() -> void:
	var t: float = 1.0 - clampf(_remaining / maxf(_duration, 0.0001), 0.0, 1.0)
	match _phase:
		Phase.DRAWING:
			_pose(POSE_REST, POSE_DRAWN, t)
		Phase.RECOVERY:
			_pose(POSE_DRAWN, POSE_REST, t)
		Phase.IDLE:
			_pose(POSE_REST, POSE_REST, 0.0)
	_update_nock()


func _update_nock() -> void:
	if _nock == null:
		return
	# An arrow is on the string while drawing and gone the instant it is
	# loosed, which is what makes the recovery legible as *reloading* rather
	# than as input being eaten.
	_nock.visible = _phase == Phase.DRAWING


## Called by the owner on input. Deliberately **not** buffered, unlike
## `MeleeWeapon.request_swing`: `DES-009` §4 wants buffering so a committal
## melee system reads as weighty rather than unresponsive, and that argument is
## about a rhythm of repeated swings. A bow is one considered shot at a time,
## and a queued second arrow would fire itself at whatever you happened to be
## looking at when the recovery ended.
func request_draw(stamina: Stamina) -> bool:
	if _kit == null or _phase != Phase.IDLE:
		return false
	if not stamina.spend(_kit.stamina_cost):
		return false
	begin_owned_draw()
	return true


## Start a draw whose cost has already been paid, on another peer's machine —
## `MeleeWeapon.begin_owned_swing`'s argument, unchanged. It does not consult
## stamina: a remote copy has been drained by nothing, and charging it again
## would make the host occasionally refuse a shot that legitimately happened.
func begin_owned_draw() -> void:
	if _kit == null or _phase != Phase.IDLE:
		return
	_enter(Phase.DRAWING, _kit.draw_seconds)
	draw_started.emit()
	Foley.at(self, Foley.Sound.SWING, 1.34)


func _enter(next: Phase, duration: float) -> void:
	_phase = next
	_remaining = duration
	_duration = duration
	_update_pose()


func advance(delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	_remaining -= delta
	_update_pose()
	if _remaining > 0.0:
		return
	match _phase:
		Phase.DRAWING:
			_enter(Phase.RECOVERY, _kit.recovery)
			loosed.emit()
		Phase.RECOVERY:
			_enter(Phase.IDLE, 0.0)
		Phase.IDLE:
			pass


## Interrupted — going down, opening the bag, or losing the bow. The draw is
## abandoned rather than fired: an arrow that leaves the string because you were
## knocked over is `PRO-005` §5's unexplainable event pointed at a teammate.
## The stamina is **not** refunded, for the same reason a whiffed swing is not.
func cancel() -> void:
	if _phase == Phase.IDLE:
		return
	_enter(Phase.IDLE, 0.0)
