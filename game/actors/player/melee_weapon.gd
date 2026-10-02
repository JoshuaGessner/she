class_name MeleeWeapon
extends Node3D

## The one weapon (`M1-T02`). Wind-up → swing → recovery, and it commits.
##
## **Unjuiced until ADR-279, per DES-009's M1 protocol step 1.** The protocol
## built the control first and said to add hitstop, impact sound and camera
## kick *afterwards*; M1 cleared and nothing came after, which is most of why a
## fight felt stale. Now: the blade **holds at impact** (hitstop, owner-side),
## poses are **eased** with an anticipation beat, and keeping the attack held
## through the wind-up draws a **heavy** blow. Particles remain absent.
##
## What is here that might look like polish but is not: **input buffering**.
## DES-009 §4 lists it under Forgiveness, and is blunt about why — without it a
## committal system reads as *unresponsive* rather than *weighty*. It is part
## of the control layer, not the polish layer.
##
## Block, shove and throw live on the body; the heavy blow lives here, as a
## longer wind-up of the same swing rather than a second weapon state.

signal swing_started
signal connected(hurtbox: Hurtbox)
## An attack was asked for with nothing in hand. Local: `Reticle` draws it, and
## nothing crosses the wire, because a refusal is feedback rather than an event
## the world needs to agree on (`TEC-004`).
signal swing_refused
## A swing met stone before it met anything it could hurt (ADR-222). Every peer
## raises it from its own copy of the swing, like `swing_started`; the host's is
## the one whose hitbox was therefore never armed.
signal glanced
## This swing became heavy (ADR-279): its owner kept attack held through the
## wind-up and paid for it. Raised on the owner, so the body can tell the
## other peers — the host's copy is the one whose blow counts.
signal went_heavy
enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

## Lines cast across a swing's path to find a wall in it. Five across 24° leave
## gaps of about 40 cm at a spear's length — narrower than any pillar the kit has.
const ARC_RAYS: int = 5

## Blockout poses, as (position, rotation-in-degrees). Not juice: without a
## visible weapon the player cannot see wind-up, strike or recovery at all, and
## the whole point of DES-009's attack anatomy is that those phases are
## *readable*. This is the primary representation of the mechanic — the polish
## layer is the arm absorbing impact and the camera kick, both still absent.
##
## **A cut, not a jab** (ADR-303). The strike ran from a raised pose to a
## struck one that pointed the blade along nearly the same line, so the blade
## slid along its own length from right to left — a thrust drawn sideways. A
## swing reads by its **arc**: the blade is raised over the right shoulder
## pointing up, and the strike pitches it down and across to the lower left,
## so the edge sweeps the view diagonally the way a forehand cut does. The
## hitbox is its own sphere (ADR-222), so what a swing can reach is unchanged.
## Eased since ADR-279; all four poses ⟨tune⟩.
const POSE_REST: Array = [Vector3(0.33, -0.28, -0.50), Vector3(32, 7, -16)]
const POSE_RAISED: Array = [Vector3(0.36, 0.06, -0.40), Vector3(75, 20, -10)]
const POSE_STRUCK: Array = [Vector3(-0.28, -0.32, -0.52), Vector3(-20, 58, -25)]
## Drawn right back for a heavy blow (ADR-279): higher, further back, and
## turned past the shoulder — the wind-up a teammate reads as *heavy*.
const POSE_HEAVY: Array = [Vector3(0.46, 0.18, -0.26), Vector3(100, 32, -15)]

## **Held by the owner, each frame** (ADR-279): whether attack is still down.
## Read once, as the wind-up ends. Probes that call `request_swing` never set
## it, so every existing swing measurement stays a light one.
var holding: bool = false
var _heavy: bool = false
## Seconds left on the blade holding at impact. Owner-side and visual: the host
## decides every hit, and its copy of someone else's swing never stops.
var _stop_left: float = 0.0

var _phase: Phase = Phase.IDLE
var _remaining: float = 0.0
var _duration: float = 0.0
var _buffered_until: float = -1.0
## Seconds until an empty hand is allowed to complain again.
var _refusal_gap: float = 0.0
## **What is in the main hand** (`M3-T07`, `DES-020`), or null for empty hands.
##
## Until now every swing in the game came from `TuningProfile.swing_*`, and the
## four weapons in the item table carried a full windup/active/recovery/damage/
## reach block that **nothing anywhere read** (ADR-124 §2). This is the reader.
## `wpn_seax` is the one those tuning numbers described, so they moved onto it
## rather than being duplicated — one home, not two (ADR-064).
##
## Null is empty hands and empty hands do not swing. `DES-009` names five combat
## verbs and none of them is a punch, so there is nothing to fall back to and
## nothing is invented to fill the gap.
var _held: WieldableTrait = null
## Whether what is held came back through a Legacy slot (`M3-T05`).
var _scarred: bool = false
## Whether the swing now recovering glanced off the world, so it recoils from
## where it was raised rather than from a strike that never happened.
var _glancing: bool = false
## Whose model is in the hand — see `_show`.
var _shown: ItemResource = null
## How far the blade has come up into view since it was put in the hand, 0 to 1.
var _drawn: float = 1.0

## The arc behind the blade while it strikes (ADR-303).
var _smear: SwingSmear = null
## How far the held model runs out from the grip, metres — see `_show`.
var _blade: float = 0.0

@onready var _hitbox: Hitbox = $Hitbox
@onready var _model: Node3D = $Model


func _ready() -> void:
	_hitbox.struck.connect(_on_struck)
	_smear = SwingSmear.new()
	_smear.name = "Smear"
	add_child(_smear)
	_pose(POSE_REST, POSE_REST, 0.0)
	_dress()


## Give it what the main hand holds, or null. Called down by the body, which is
## the only thing that knows whose slots these are — `Equipment` never reaches
## up and this never reaches sideways.
## **Scarred, or whole** (`M3-T05`, `DES-003`). *"Legacy items are Scarred:
## carried through death at reduced power."*
##
## Passed in rather than looked up, on this node's own rule — it is told what it
## holds and never asks. The scale lands on **damage alone**, deliberately: a
## Scarred blade that also swung slower would be two penalties for one sentence,
## and `DES-009`'s timings are what a player reads a fight by. It hits softer;
## it does not handle like a different weapon.
##
## `item` is what the blade **looks** like, and it is separate from `blade`
## because the two answer different questions: the trait is the numbers a swing
## is made of, the item is the thing a teammate reads the wind-up from.
func wield(blade: WieldableTrait, scarred: bool = false,
		item: ItemResource = null) -> void:
	if _held == blade and _scarred == scarred and _shown == item:
		return
	_scarred = scarred
	_held = blade
	_show(item)
	# A weapon that leaves your hand mid-swing takes the swing with it. The
	# alternative is a hitbox armed by a blade nobody is holding.
	if _phase != Phase.IDLE:
		_enter(Phase.IDLE, 0.0)
	_dress()


func held() -> WieldableTrait:
	return _held


## **The weapon in the hand is the weapon's own model** (`M4-T10`, ADR-265).
##
## Until the art arrived every blade in the game was one 0.85 m box, so a hammer
## wound up looking exactly like a seax — and `DES-009`'s whole attack anatomy
## is that the wind-up is *read*. A hammer is 0.85 m of haft with a head on it
## and a spear is two metres of ash; a teammate across a room can now tell
## which is about to land from the silhouette alone, which is `DES-018`'s
## visual twin for a swing that makes no sound until it hits.
##
## Hung at the pose node's origin with no offset: `ART-006` pivots every weapon
## at its grip pointing −Z, and the poses above were always of a hand, never of
## a box — the box was the thing standing 0.35 m ahead of it.
##
## **No box when there is no model.** `--data-probe` fails any item without
## one, so a missing model is a build that does not ship rather than a weapon
## that quietly turns back into blockout (ADR-262).
func shown() -> ItemResource:
	return _shown


func _show(item: ItemResource) -> void:
	if item == _shown:
		return
	_shown = item
	# **Brought up into view** (ADR-267). A weapon changing in the hand was a
	# cut from one model to the next; it now rises from below the frame, which
	# is where a hand brings a thing from. Idle only — see `_enter`.
	_drawn = 0.0 if item != null else 1.0
	set_process(_drawn < 1.0)
	for child: Node in _model.get_children():
		child.free()
	if item == null:
		return
	var look: Node3D = item.look()
	if look != null:
		_model.add_child(look)
		# How far the model runs out from the grip along −Z, for the smear.
		_blade = 0.0
		for node: Node in look.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			var box: AABB = look.transform * mesh.transform * mesh.get_aabb()
			_blade = maxf(_blade, -box.position.z)


## Reach is a weapon stat (`DES-009`: *"space is a weapon stat"*), so the hitbox
## is resized by what you are holding rather than being one size for everything.
func _dress() -> void:
	visible = _held != null
	if _held == null:
		_hitbox.disarm()
		return
	_hitbox.damage = _held.damage * (Config.tuning.scarred_power if _scarred else 1.0)
	_hitbox.heavy = false
	# Unscaled by `scarred_power` on purpose: a Scar is `DES-003`'s tax on
	# damage, and letting it also erode stagger would quietly change which
	# weapons can interrupt a telegraph — a scarred hammer would stop being a
	# hammer, which is a change to `DES-009`'s light/heavy rule rather than to
	# a number, and ADR-058 puts that behind an ADR.
	_hitbox.stagger = _held.stagger
	if _heavy:
		# **The heavy blow is the blow** (ADR-279). Set here, on every copy
		# that knows the swing went heavy, so the host's hitbox — the only one
		# that decides — carries it. `heavy` is what a guard reads (ADR-238).
		var tuning: TuningProfile = Config.tuning
		_hitbox.damage *= tuning.heavy_damage_scale
		_hitbox.stagger *= tuning.heavy_stagger_scale
		_hitbox.heavy = true
	# A seax cuts and a hammer crushes (ADR-219). Recorded on every weapon since
	# weapons became data, and this is the line that finally carries it to the
	# thing it strikes.
	_hitbox.damage_type = _held.damage_type
	# **The arc is a sphere from the eye to the reach** (ADR-222) — the shape
	# `M1` signed the seax off with, 1.1 m around a point 1.1 m ahead, now drawn
	# from what is held. This resized a `BoxShape3D` and the arc has always
	# been a sphere, so the cast failed silently and every weapon in the game
	# reached exactly as far as the seax.
	var shape := _hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape != null:
		var arc := shape.shape as SphereShape3D
		if arc != null:
			arc.radius = _held.reach * 0.5
			shape.position.z = -_held.reach * 0.5


func _pose(from: Array, to: Array, t: float) -> void:
	_model.position = (from[0] as Vector3).lerp(to[0] as Vector3, t)
	_model.rotation = Vector3(
		deg_to_rad(lerpf((from[1] as Vector3).x, (to[1] as Vector3).x, t)),
		deg_to_rad(lerpf((from[1] as Vector3).y, (to[1] as Vector3).y, t)),
		deg_to_rad(lerpf((from[1] as Vector3).z, (to[1] as Vector3).z, t))
	)


func _update_pose() -> void:
	# How far through the current phase we are, 0 at its start and 1 at its end.
	var t: float = 1.0 - clampf(_remaining / maxf(_duration, 0.0001), 0.0, 1.0)
	# **Eased since ADR-279.** M1 kept these straight so an easing curve could
	# not flatter the timings being judged; they are judged. The wind-up rises
	# fast and settles, so the top of it is a held beat (anticipation); the
	# strike starts at full speed and brakes into the target; the recovery
	# eases both ends.
	match _phase:
		Phase.WINDUP:
			if _heavy:
				_pose(POSE_RAISED, POSE_HEAVY, smoothstep(0.0, 1.0, t))
			else:
				_pose(POSE_REST, POSE_RAISED, 1.0 - pow(1.0 - t, 2.0))
		Phase.ACTIVE:
			_pose(POSE_HEAVY if _heavy else POSE_RAISED, POSE_STRUCK,
				1.0 - pow(1.0 - t, 3.0))
			# The arc behind it, from the blade's middle to its tip (ADR-303):
			# the model points along −Z from its grip (ART-006).
			if _smear != null and _blade > 0.0:
				_smear.sample(_model.global_transform * Vector3(0.0, 0.0, -_blade * 0.62),
					_model.global_transform * Vector3(0.0, 0.0, -_blade))
		Phase.RECOVERY:
			# A glance rebounds from the raised pose: the blade stopped where
			# it met the wall, and the strike was never made (`DES-018`'s twin
			# of the clang).
			_pose(POSE_RAISED if _glancing else POSE_STRUCK, POSE_REST,
				smoothstep(0.0, 1.0, t))
		Phase.IDLE:
			_pose(POSE_REST, POSE_REST, 0.0)
			lower_by_draw(_model, 1.0 - _drawn)


## How long a weapon takes to come up into view, seconds ⟨tune⟩ — shorter than
## the fastest wind-up, so a draw is never what a player is waiting on.
const DRAW_SECONDS: float = 0.28
## How far below and tipped away from its rest pose a weapon starts its draw.
const LOWERED_BY: Vector3 = Vector3(0.05, -0.42, 0.10)
const LOWERED_PITCH: float = -55.0


func _process(delta: float) -> void:
	_drawn = minf(1.0, _drawn + delta / DRAW_SECONDS)
	if _phase == Phase.IDLE:
		_update_pose()
	if _drawn >= 1.0:
		set_process(false)


## How far it has been drawn, for `--hands-probe`.
func drawn() -> float:
	return _drawn


## Push a pose node down and away by `amount` of the lowered offset — shared
## with `RangedWeapon`, which draws the same way. Eased, so the weapon arrives
## rather than slides: most of the travel is at the start.
static func lower_by_draw(node: Node3D, amount: float) -> void:
	if amount <= 0.0:
		return
	var t: float = 1.0 - pow(1.0 - clampf(amount, 0.0, 1.0), 3.0)
	node.position += LOWERED_BY * t
	node.rotation.x += deg_to_rad(LOWERED_PITCH) * t


func phase() -> Phase:
	return _phase


## The arc drawn behind the blade, for `--feel-probe`.
func smear() -> SwingSmear:
	return _smear


func is_busy() -> bool:
	return _phase != Phase.IDLE


## Whether the swing under way is a heavy one (ADR-279).
func is_heavy() -> bool:
	return _heavy


## Seconds the blade is still holding at impact, for `--feel-probe`.
func stopped_for() -> float:
	return _stop_left


## **The blade holds where it met something** (ADR-279, `DES-009`'s hitstop:
## *"the pause sells the collision as something that cost energy"*). Called on
## the owner's machine when the host says the blow landed. The whole phase
## machine holds, which is what makes it felt rather than only seen — and it
## is the owner's copy, so the host's timing and every other peer's are
## untouched (`DES-009`: hitstop must never pause simulation).
func hitstop(seconds: float) -> void:
	_stop_left = maxf(_stop_left, seconds)


## The swing another peer's owner drew back into a heavy blow (ADR-279).
func become_heavy() -> void:
	if _phase != Phase.WINDUP or _heavy:
		return
	_draw_back()


func _draw_back() -> void:
	_heavy = true
	_dress()
	_enter(Phase.WINDUP, Config.tuning.heavy_extra_windup)


## Called by the owner on input. Returns false if the swing was refused, which
## is not the same as being buffered — see `_buffered_until`.
func request_swing(stamina: Stamina) -> bool:
	var tuning: TuningProfile = Config.tuning
	if _held == null:
		refuse()
		return false
	if _phase == Phase.IDLE:
		return _begin(stamina, tuning)
	# A press during recovery is remembered and fires on the first legal frame.
	# Buffering during wind-up or the active frames would queue a second swing
	# before the first has resolved, which reads as the input being swallowed.
	if _phase == Phase.RECOVERY:
		_buffered_until = _remaining + tuning.swing_buffer_window
	return false


## **An empty hand says so** (ADR-140).
##
## This returned `false` and did nothing else, which is how the first play of
## the build found a body with no kit and reported *"no weapon"*: the attack
## button was not weak or slow, it was **silent**. Nothing on screen, nothing in
## the ears, no refusal — indistinguishable from a broken build, and principle 4
## has no one-sentence explanation for it.
##
## **Deliberately not an unarmed attack.** A punch is new combat content with
## reach, damage, timing and a place in `DES-009`'s five verbs, and inventing
## one here to plug a feedback hole would be answering a legibility question
## with a balance change. This is the refusal, said out loud.
##
## Two channels, because `DES-018` requires the build to be completable muted:
## a dull `THUMP` — the sound of something heavy moving with nothing behind it —
## and the reticle flinching inward, which is the opposite gesture to the ticks
## it opens outward when a thing comes into reach.
##
## Public since ADR-239: a broken arm holding a two-hander refuses the same way,
## because from the seat it is the same fact — the hands cannot do this.
func refuse() -> void:
	if _refusal_gap > 0.0:
		return
	_refusal_gap = Config.tuning.empty_hand_gap
	swing_refused.emit()
	Foley.at(self, Foley.Sound.THUMP, 0.55, -7.0)


func _begin(stamina: Stamina, tuning: TuningProfile) -> bool:
	if _held == null or not stamina.spend(_held.stamina_cost):
		return false
	begin_owned_swing()
	return true


## Start a swing whose cost has already been paid, on another peer's machine
## (`M1-T05`, ADR-082).
##
## Every peer runs this phase machine: the owner because they asked for the
## swing, the host because its copy's hitbox is the only one allowed to decide
## that something was hurt, and everyone else so a teammate visibly swings
## rather than gliding with a still weapon.
##
## It does not consult stamina, and that is the point rather than an oversight.
## Stamina was spent on the owner's machine; a remote copy has been drained by
## nothing, so charging it again would sometimes *refuse* — on the host — a
## swing that legitimately happened, and the symptom would be hits that
## occasionally do not land for no visible reason.
func begin_owned_swing() -> void:
	if _phase != Phase.IDLE or _held == null:
		return
	_enter(Phase.WINDUP, _held.windup)
	swing_started.emit()
	Foley.at(self, Foley.Sound.SWING, randf_range(0.94, 1.08))


func _enter(next: Phase, duration: float) -> void:
	# A swing takes the blade from wherever the draw had got to: the timing of
	# a swing is `DES-009`'s and a draw may never delay or soften one.
	if next != Phase.IDLE:
		_drawn = 1.0
	if next != Phase.RECOVERY:
		_glancing = false
	if next == Phase.IDLE and _heavy:
		_heavy = false
		_dress()
	_phase = next
	_remaining = duration
	_duration = duration
	if next == Phase.ACTIVE:
		_hitbox.arm()
	else:
		_hitbox.disarm()
	_update_pose()


func advance(delta: float, stamina: Stamina) -> void:
	# **Before the idle return, not after it.** An empty hand is only ever idle,
	# so a cooldown ticked below this line would never tick at all — the refusal
	# would fire once per life and then go quiet, which is the silence it exists
	# to replace (ADR-140).
	_refusal_gap = maxf(0.0, _refusal_gap - delta)
	if _phase == Phase.IDLE:
		return
	if _stop_left > 0.0:
		_stop_left -= delta
		return
	var tuning: TuningProfile = Config.tuning
	_remaining -= delta
	_update_pose()
	if _remaining > 0.0:
		return

	match _phase:
		Phase.WINDUP:
			# **Still held, it draws back instead** (ADR-279) — once, and only
			# if the breath is there for it. Let go before the wind-up ends and
			# it is the light swing it always was.
			if holding and not _heavy \
					and stamina.spend(_held.stamina_cost * tuning.heavy_stamina_scale):
				_draw_back()
				went_heavy.emit()
			elif _meets_the_world():
				_glance(tuning)
			else:
				_enter(Phase.ACTIVE, _held.active)
		Phase.ACTIVE:
			_enter(Phase.RECOVERY, _held.recovery)
		Phase.RECOVERY:
			_enter(Phase.IDLE, 0.0)
			# Spend the buffered press, if one is still live. `_remaining` is
			# now zero or negative, so the window is measured against how far
			# past the end of recovery we are.
			if _buffered_until > 0.0 and _buffered_until + _remaining > 0.0:
				_buffered_until = -1.0
				_begin(stamina, tuning)
			else:
				_buffered_until = -1.0
		Phase.IDLE:
			pass


## **Would this swing meet a wall before it met a body?** (ADR-222, `DES-009`).
##
## Asked at the instant the strike would begin, along `ARC_RAYS` lines fanned
## `swing_arc_degrees` either side of where the body faces, each as long as the
## reach. A line that reaches something it could hurt **first** is clear — the
## blade found flesh before stone — and any line that reaches the world first
## means the swing glances.
##
## **Level, not pitched.** The lines run at eye height along the body's facing,
## so looking down at a crouched thing never glances off the floor and a low
## ceiling never stops a sweep. Walls, pillars and door jambs are what it asks
## about, because they are what `DES-009`'s corridor sentence is about.
##
## Every peer asks its own copy, since the level is the same on each; the host's
## answer decides whether anything was hurt. A client standing a few centimetres
## from where the host has it could hear a clang the host did not — at the very
## edge of a wall's reach, and only in its own sound and pose.
func _meets_the_world() -> bool:
	if _held == null or not is_inside_tree():
		return false
	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.000001:
		return false
	forward = forward.normalized()
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var half: float = deg_to_rad(Config.tuning.swing_arc_degrees)
	for step: int in range(ARC_RAYS):
		var angle: float = lerpf(-half, half, float(step) / float(ARC_RAYS - 1))
		var along: Vector3 = forward.rotated(Vector3.UP, angle)
		var line := PhysicsRayQueryParameters3D.create(global_position,
			global_position + along * _held.reach)
		line.collision_mask = CollisionLayers.WORLD | _hitbox.collision_mask
		line.collide_with_areas = true
		var hit: Dictionary = space.intersect_ray(line)
		if not hit.is_empty() and not (hit["collider"] is Hurtbox):
			return true
	return false


## **Glances off**: no strike, a clang, a recoil, and a longer recovery. The
## hitbox is never armed, so nothing in the arc is hurt — the choice ADR-222
## records over cutting the swing short, because a spear that still hit
## everything between you and the wall would barely pay for its length.
func _glance(tuning: TuningProfile) -> void:
	_enter(Phase.RECOVERY, _held.active + _held.recovery * tuning.glance_recovery_scale)
	_glancing = true
	_update_pose()
	glanced.emit()
	Foley.at(self, Foley.Sound.HIT, 1.45, 3.0)


func _on_struck(hurtbox: Hurtbox) -> void:
	connected.emit(hurtbox)


## Presented grip, passed down to the first-person arms by Player.
func grip() -> Node3D:
	return _model if _shown != null else null
