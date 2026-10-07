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

## The body on the shared rig. Preloaded rather than looked up: the dependency
## is then a parse error if the art moves, instead of a body that silently
## fails to exist.
##
## **The delvers' body, not the rig's proxy** (ADR-308). The proxy is spheres
## and cylinders and says it is *"rig placement and measurement only; not
## character art"*; it stays `humanoid_rig.glb`'s, for `rig_probe`. This is the
## same skeleton under a body built from the enemies' anatomy.
const RIG: PackedScene = preload("res://art/characters/player_body.glb")

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
## **A Húskarl holding** (`M4-T03`, ADR-272): a lunge, the lead foot forward and
## the back foot braced, the shield arm up across the chest, the body leaning
## into what is coming. Radians ⟨tune⟩, except the drop, which is metres and
## deliberately small — the collider does not move, and a silhouette that sank
## below its own collider would be `PRO-005` §5's unexplainable hit.
const BRACE_LEAD_THIGH: float = 0.45
const BRACE_BACK_THIGH: float = -0.30
const BRACE_LEAD_KNEE: float = 0.55
const BRACE_BACK_KNEE: float = 0.15
const BRACE_SHIELD_ARM: float = 1.15
const BRACE_SHIELD_ELBOW: float = 0.95
const BRACE_LEAN: float = 0.35
const BRACE_DROP: float = 0.06
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

## **Which socket each worn slot rides** (`DES-020`'s attachment table,
## ADR-265).
##
## Three of the table's rows ride sockets. The remaining rows use their
## prescribed attachment method: **the main hand** is held in the right fist
## (`wield`, ADR-330, closing Q114) and the arm is posed by the swing — the
## weapon's own phase, read every frame, so the wind-up a teammate reads is the
## one its hitbox runs. Until ADR-330 it floated in front of the head, where
## the first-person copy draws it. **Body and arms** are *skinned*
## in `DES-020`, deforming with the torso and forearm. Their source scenes only
## carry a skeleton so Blender can author the weights; `ItemResource.wear_on`
## remaps those skins by bone name and attaches the meshes to this skeleton.
## There is never a second armature moving beside the teammate's body.
## The hand a thing being used is held in (ADR-267) — the right, which carries
## nothing else on the rig (see above).
const USE_SOCKET: StringName = &"sock_hand_r"
const SOCKETS: Dictionary = {
	Enums.Slot.HEAD: &"sock_head",
	Enums.Slot.OFF_HAND: &"sock_hand_l",
	Enums.Slot.PACK: &"sock_back",
}
## The two slots that deform with this skeleton rather than ride a socket.
const SKINNED_SLOTS: Array[Enums.Slot] = [Enums.Slot.ARMS, Enums.Slot.BODY]

## **The weapon in the hand** (ADR-330). A weapon's own frame is `ART-006`'s:
## the grip at the origin, the blade along −Z, its up along +Y. These place
## that frame in a closed fist on the rig's hand sockets ⟨tune⟩, set against
## `--teammate-shot`.
const WIELD_HAND: StringName = &"sock_hand_r"
const BOW_HAND: StringName = &"sock_hand_l"
const WIELD_TURN: Vector3 = Vector3(-1.45, 0.0, 0.0)
## A bow hangs along the arm at rest and stands across it at the draw.
const BOW_TURN: Vector3 = Vector3(0.0, 0.0, 0.0)
const BOW_DRAWN_TURN: Vector3 = Vector3(-1.5708, 0.0, 0.0)
## How the arm carries a swing, radians ⟨tune⟩: the wind-up lifts the upper arm
## forward and over and folds the elbow, so the blade stands behind the head;
## the cut brings the arm down through the front and opens the elbow.
const ARM_RAISE: float = 2.5
const ELBOW_RAISE: float = 1.6
const ARM_CUT: float = 1.05
const ELBOW_CUT: float = 0.10
## A bow is held up before it is drawn, the draw hand brought back to the jaw.
const BOW_ARM: float = 1.45
const DRAW_ARM: float = 1.35
const DRAW_ELBOW: float = 2.0
## The base rig is a blockout person, not a layer of clothing. A body garment
## therefore replaces its torso, legs and upper arms while preserving the head,
## neck, forearms and hands that the garment is designed to leave exposed.
const BODY_COVERED_BONES: Array[StringName] = [
	&"pelvis", &"spine_01", &"spine_02", &"chest",
	&"thigh_l", &"calf_l", &"foot_l", &"thigh_r", &"calf_r", &"foot_r",
	&"upper_arm_l", &"upper_arm_r",
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
var _base_body_mesh: Mesh = null
var _masked_body_mesh: Mesh = null
## Bone name -> index, and bone name -> the local axis that swings it forward.
var _bone: Dictionary = {}
var _swing: Dictionary = {}
var _rest_y: float = 0.0

var _phase: float = 0.0
## Strides taken since the rig was made, for `strides_taken`.
var _strides_taken: float = 0.0
var _gait: float = 0.0
## How far into a Hold this body is, 0 to 1. Set by `brace()` before `step()`.
var _brace: float = 0.0
## The off-hand item's orientation relative to the body, as it hangs when not
## braced — face out, square to the front. Held while braced so the shield
## rides the raised arm *as a shield* rather than tipping with the forearm
## into a tray (measured: a 2.1 rad arm-and-elbow lift laid it flat).
var _held_square: Basis = Basis()
## And where it hung from the hand, in the body's frame — the item's own offset
## from its socket swings with the arm too, and left alone it carried the shield
## a metre over the head.
var _held_offset: Vector3 = Vector3.ZERO
var _held_known: bool = false
var _breath: float = 0.0
## Slot -> the `BoneAttachment3D` carrying it, and slot -> whose model it is.
var _sockets: Dictionary = {}
var _worn: Dictionary = {}
## Slot -> one carrier directly under `_skeleton`, containing meshes whose
## `skeleton` NodePath resolves to the shared skeleton.
var _skinned: Dictionary = {}
var _gear_shown: bool = true
## The weapon held (ADR-330): its holder node on the hand socket, what it is,
## and whether it is a bow — which the left hand holds and the right draws.
var _wielded: Node3D = null
var _wielded_item: ItemResource = null
var _bow: bool = false
var _raise: float = 0.0
var _cut: float = 0.0
var _pull: float = 0.0
var _pull_shown: float = 0.0
## How fast a bow arm settles after a loose, per second ⟨tune⟩ — the string
## goes home at once, the arms come down.
const BOW_SETTLE: float = 6.0
## The thing in the right hand being *used* (a binding, a Waystone), which
## takes the hand from the weapon while it lasts.
var _use_look: Node3D = null
## The lantern's shutter, eased, and what the right hand is using (ADR-267).
var _open: float = 0.0
var _using: ItemResource = null


func _ready() -> void:
	var body := RIG.instantiate() as Node3D
	# **Turned round to face the way the body faces** (ADR-265). glTF assets
	# face +Z and every gameplay node faces −Z (`humanoid_rig_measurements.md`
	# says so in as many words), so an unturned rig walks backwards: a
	# teammate's face on the side away from where they look, their blade
	# hanging behind them and their pack on their chest. Nothing measured it —
	# the stride is fore-and-aft either way — until gear went on the sockets
	# and a picture showed a pack on the wrong side of a body.
	body.rotation.y = PI
	add_child(body)
	_skeleton = _find_skeleton(body)
	if _skeleton == null:
		push_error("BodyRig: the rig has no Skeleton3D — gear and pose have "
			+ "nothing to hang on")
		return
	_mesh = _find_mesh(body)
	if _mesh != null and teammate_skin != null:
		_dress_in(teammate_skin)
	if _mesh != null:
		_base_body_mesh = _mesh.mesh
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
		#
		# **The rig's own right, which is skeleton −X.** The rig faces +Z, so
		# its right hand is at −X (`sock_hand_r` is at x −0.46); taking +X
		# called its left hand its right and turned every sign in `step()`
		# over. About the right-hand side, a positive turn swings a hanging
		# limb *forward* and tips an upright one *back* — which is the one
		# convention every sign below is written in.
		var rest: Basis = _skeleton.get_bone_global_rest(index).basis
		_swing[name] = (rest.inverse() * Vector3.LEFT).normalized()
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


## **How many strides the gait has taken**, ever — for the co-op smoke's
## *walking, not sliding* row (ADR-351). Distance-driven like the phase it
## advances, so it says whether this body is being handed to the gait at all,
## and says it the same on an idle machine and a loaded one.
func strides_taken() -> float:
	return _strides_taken


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


## **Put on what the slots hold** (`DES-020`): slot -> `ItemResource` or null.
##
## Called down by the body on every change to its equipment, on every peer, so
## a remote teammate's helm arrives with the slot that says they wear one and
## goes with it. Only a slot whose item *changed* is rebuilt — equipment changes
## for reasons that have nothing to do with the head, and instancing the helm
## again every time the bag reshuffles would be a model built per pick-up.
##
## Each model rides its socket at the item's own `grip`. A socket the rig does
## not have is skipped with a warning rather than a crash, for `_turn`'s reason:
## a re-export that drops a bone should lose that gear, not the body.
func wear(items: Dictionary) -> void:
	if _skeleton == null:
		return
	for slot: Enums.Slot in SKINNED_SLOTS:
		var skinned_item: ItemResource = items.get(slot, null) as ItemResource
		if _worn.get(slot, null) == skinned_item:
			continue
		_worn[slot] = skinned_item
		var old: Node3D = _skinned.get(slot, null) as Node3D
		if old != null:
			old.free()
		_skinned.erase(slot)
		if skinned_item == null:
			continue
		var carrier: Node3D = skinned_item.wear_on(_skeleton)
		if carrier == null:
			push_error("BodyRig: %s has no skinned worn model for %s"
				% [skinned_item.id, Enums.Slot.keys()[slot]])
			continue
		carrier.visible = _gear_shown
		_skinned[slot] = carrier
	for slot: Enums.Slot in SOCKETS:
		var item: ItemResource = items.get(slot, null) as ItemResource
		if _worn.get(slot, null) == item:
			continue
		_worn[slot] = item
		var socket: BoneAttachment3D = _socket(slot)
		if socket == null:
			continue
		for child: Node in socket.get_children():
			child.free()
		if item == null:
			continue
		var look: Node3D = item.look()
		if look == null:
			continue
		look.transform = item.grip
		socket.add_child(look)
	_mask_base_body(_skinned.has(Enums.Slot.BODY))


## Draw the gear or not. Off for the body you are inside, for the reason its
## skin is: your own helm stands where your camera is.
func show_gear(on: bool) -> void:
	_gear_shown = on
	# Keyed by slot or, for the hand a thing is used in, by bone — so untyped.
	for key: Variant in _sockets:
		(_sockets[key] as Node3D).visible = on
	for slot: Enums.Slot in _skinned:
		(_skinned[slot] as Node3D).visible = on


## Where a bone's head is now, in world space — for the checks that ask which
## way a knee went, which `stride_reach` cannot, since it measures a distance.
func bone_at(name: String) -> Vector3:
	if _skeleton == null:
		return global_position
	var index: int = _skeleton.find_bone(name)
	if index < 0:
		return global_position
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(index).origin


func gear_shown() -> bool:
	return _gear_shown


## Where the socket for `slot` is now, in world space — posed, not at rest, so
## a check against it measures the body a teammate is actually looking at.
func socket_at(slot: Enums.Slot) -> Vector3:
	if _skeleton == null or not SOCKETS.has(slot):
		return global_position
	var index: int = _skeleton.find_bone(SOCKETS[slot])
	if index < 0:
		return global_position
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(index).origin


## **What a teammate's hands are doing** (ADR-267), from numbers the wire
## already carries: `lit` opens the shutter of a lantern in the off hand, and
## while `mending` or `leaving` runs the binding or the Waystone is in the right
## hand — which is otherwise empty (Q114), and is the hand a person ties a knot
## or holds up a stone with. `HeldLook` poses both, so a teammate's lantern and
## your own shut the same way.
func show_use(delta: float, lit: bool, mending: float, leaving: float) -> void:
	if _skeleton == null:
		return
	_open = lerpf(_open, 1.0 if lit else 0.0, clampf(delta * 9.0, 0.0, 1.0))
	var carried: ItemResource = _worn.get(Enums.Slot.OFF_HAND, null) as ItemResource
	if carried != null and carried.has_trait(LightTrait):
		HeldLook.lantern(worn_on(Enums.Slot.OFF_HAND), _open)
	var using: ItemResource = null
	var done: float = 0.0
	if leaving > 0.0:
		using = HeldLook.first_with(ExtractionTrait)
		done = leaving
	elif mending > 0.0:
		using = HeldLook.first_with(MendingTrait)
		done = mending
	var hand: BoneAttachment3D = _attach(USE_SOCKET)
	if hand == null:
		return
	if using != _using:
		_using = using
		if _use_look != null and is_instance_valid(_use_look):
			_use_look.free()
		_use_look = null
		if using != null:
			var look: Node3D = using.look()
			if look != null:
				# Held by its middle, hanging below the fist.
				look.position = Vector3(0.0, -0.12, 0.0)
				hand.add_child(look)
				_use_look = look
		# A thing in use takes the right hand from the weapon while it lasts.
		if _wielded != null and is_instance_valid(_wielded) and not _bow:
			_wielded.visible = _use_look == null
	if _use_look == null:
		return
	var held := _use_look
	if using != null and using.has_trait(ExtractionTrait):
		HeldLook.waystone(held, done)
	elif using != null and using.has_trait(MendingTrait):
		HeldLook.binding(held, done)


## What the right hand is holding while it is used, for `--hands-probe`.
func in_use() -> Node3D:
	return _use_look if _use_look != null and is_instance_valid(_use_look) else null


## **Hold the main-hand weapon** (ADR-330): a blade in the right fist, or a bow
## in the left. Called on every equipment change after `wear`, which may have
## rebuilt the off-hand socket a bow rides.
func wield(item: ItemResource, bow: bool) -> void:
	if _skeleton == null:
		return
	if item == _wielded_item and bow == _bow and _wielded != null and is_instance_valid(_wielded):
		return
	_wielded_item = item
	_bow = bow
	if _wielded != null and is_instance_valid(_wielded):
		_wielded.free()
	_wielded = null
	if item == null:
		return
	var hand: BoneAttachment3D = _attach(BOW_HAND if bow else WIELD_HAND)
	var look: Node3D = item.look()
	if hand == null or look == null:
		return
	var holder := Node3D.new()
	holder.name = "Wielded"
	holder.rotation = BOW_TURN if bow else WIELD_TURN
	holder.add_child(look)
	holder.visible = _gear_shown and (bow or _use_look == null)
	hand.add_child(holder)
	_wielded = holder


## Which hand socket the weapon is held in, or empty — for `--body-probe`.
func wielded_in() -> StringName:
	if wielded() == null:
		return &""
	return BOW_HAND if _bow else WIELD_HAND


## The weapon held, for `--body-probe` and for the swing's trail.
func wielded() -> Node3D:
	return _wielded if _wielded != null and is_instance_valid(_wielded) else null


## The swing this frame: raised 0 to 1 (past 1 for a heavy blow), cut 0 to 1
## — `MeleeWeapon.arm_pose`, read by the body on every peer.
func swing_arm(pose: Vector2) -> void:
	_raise = pose.x
	_cut = pose.y


## The string this frame, 0 to 1 — `RangedWeapon.pull`.
func draw(pull: float) -> void:
	_pull = pull


## The model riding `slot`, or null — for `--body-probe`, which asks where it
## actually landed rather than what was asked for.
func worn_on(slot: Enums.Slot) -> Node3D:
	if SKINNED_SLOTS.has(slot):
		return _skinned.get(slot, null) as Node3D
	var socket: BoneAttachment3D = _sockets.get(slot, null) as BoneAttachment3D
	if socket == null or socket.get_child_count() == 0:
		return null
	return socket.get_child(0) as Node3D


## Whether a body garment has replaced the covered part of the proxy rig. The
## equipment probe asks this after equipping and again after unequipping, so a
## garment cannot leave a second torso inside it or permanently erase the base
## body on its way back to the bag.
func body_is_masked() -> bool:
	return _mesh != null and _mesh.mesh == _masked_body_mesh


## Triangle count of the body currently drawn, for the same focused probe.
func body_triangles() -> int:
	return _triangles(_mesh.mesh) if _mesh != null else 0


func base_body_triangles() -> int:
	return _triangles(_base_body_mesh)


## Confirm that an equipped skinned slot uses this body's one Skeleton3D. The
## body probe asks this at runtime: an asset may carry the right Skin yet still
## point at the discarded source armature after it is reparented.
func skinned_slot_uses_shared_skeleton(slot: Enums.Slot) -> bool:
	var carrier: Node3D = _skinned.get(slot, null) as Node3D
	if carrier == null or _skeleton == null \
			or not carrier.find_children("*", "Skeleton3D", true, false).is_empty():
		return false
	var meshes: Array[Node] = carrier.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		return false
	for node: Node in meshes:
		var skinned := node as MeshInstance3D
		if skinned == null or skinned.skin == null \
				or skinned.get_node_or_null(skinned.skeleton) != _skeleton:
			return false
	return true


## Make one mesh from the original rig with only its exposed parts. This is a
## presentation swap, so it keeps the original skeleton, Skin and materials;
## re-authoring a second base body beside the rig would drift the next time the
## rig changes. The mesh is restored by identity on unequip.
func _mask_base_body(on: bool) -> void:
	if _mesh == null or _base_body_mesh == null:
		return
	if not on:
		_mesh.mesh = _base_body_mesh
		return
	if _masked_body_mesh == null:
		_masked_body_mesh = _without_covered_body(_base_body_mesh, _mesh.skin)
	if _masked_body_mesh != null:
		_mesh.mesh = _masked_body_mesh


func _without_covered_body(source: Mesh, skin: Skin) -> Mesh:
	if skin == null:
		push_error("BodyRig: the base body has no Skin to mask under armour")
		return null
	var covered: Dictionary = {}
	for name: StringName in BODY_COVERED_BONES:
		var index: int = _skeleton.find_bone(name)
		if index >= 0:
			covered[index] = true
	var filtered := ArrayMesh.new()
	for surface: int in range(source.get_surface_count()):
		var arrays: Array = source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES] as PackedInt32Array
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array
		if vertices.is_empty() or bones.is_empty() or weights.is_empty():
			push_error("BodyRig: base body surface %d has no skin weights" % surface)
			return null
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		if indices.is_empty():
			for vertex: int in range(vertices.size()):
				indices.append(vertex)
		var kept := PackedInt32Array()
		for first: int in range(0, indices.size() - 2, 3):
			var hidden: bool = false
			for corner: int in 3:
				if _covered_vertex(indices[first + corner], vertices.size(), bones,
						weights, skin, covered):
					hidden = true
					break
			if not hidden:
				kept.append_array(PackedInt32Array([
					indices[first], indices[first + 1], indices[first + 2],
				]))
		# A surface armour hides entirely keeps one degenerate triangle, so the
		# body's surfaces keep their indices and their materials (ADR-308).
		if kept.is_empty():
			kept = PackedInt32Array([0, 0, 0])
		arrays[Mesh.ARRAY_INDEX] = kept
		filtered.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		filtered.surface_set_material(filtered.get_surface_count() - 1,
			source.surface_get_material(surface))
	return filtered


## A vertex belongs to the one bone contributing most of its weight. The edge
## between an upper arm and a forearm stays with the forearm where that is what
## visibly owns it; filtering every *partial* upper-arm influence would eat the
## elbow and leave a gap beneath a bracer.
func _covered_vertex(vertex: int, vertex_count: int,
		bones: PackedInt32Array, weights: PackedFloat32Array, skin: Skin,
		covered: Dictionary) -> bool:
	var influences: int = bones.size() / vertex_count
	if influences <= 0 or weights.size() < bones.size():
		return false
	var strongest_weight: float = -1.0
	var strongest_bone: int = -1
	for influence: int in range(influences):
		var at: int = vertex * influences + influence
		if weights[at] > strongest_weight:
			strongest_weight = weights[at]
			strongest_bone = _bind_bone(skin, bones[at])
	return covered.has(strongest_bone)


## A glTF import may preserve a Skin bind's name but omit its old skeleton
## index. The base body is posed by `_skeleton`, so resolve names against that
## skeleton before falling back to a valid numeric bind.
func _bind_bone(skin: Skin, bind: int) -> int:
	if bind < 0 or bind >= skin.get_bind_count():
		return -1
	var named: StringName = skin.get_bind_name(bind)
	if named != &"" and _skeleton != null:
		return _skeleton.find_bone(named)
	return skin.get_bind_bone(bind)


static func _triangles(source_mesh: Mesh) -> int:
	if source_mesh == null:
		return 0
	var total: int = 0
	for surface: int in range(source_mesh.get_surface_count()):
		var arrays: Array = source_mesh.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		total += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
	return total


## The attachment for one slot, made the first time it is asked for.
func _socket(slot: Enums.Slot) -> BoneAttachment3D:
	if _sockets.has(slot):
		return _sockets[slot]
	var socket: BoneAttachment3D = _attach(SOCKETS[slot])
	if socket != null:
		_sockets.erase(SOCKETS[slot])
		_sockets[slot] = socket
	return socket


## An attachment on one bone, made the first time it is asked for, keyed by the
## bone's name until a slot claims it.
func _attach(bone: StringName) -> BoneAttachment3D:
	if _sockets.has(bone):
		return _sockets[bone]
	if _skeleton.find_bone(bone) < 0:
		push_warning("BodyRig: the rig has no socket '%s'" % bone)
		return null
	var socket := BoneAttachment3D.new()
	socket.name = String(bone)
	socket.bone_name = bone
	socket.visible = _gear_shown
	_skeleton.add_child(socket)
	_sockets[bone] = socket
	return socket


## The surface a skin override is applied to — the faint teammate, the Vörðr and
## the body that got out all dress this (`Player._dress_as_out`).
func mesh() -> MeshInstance3D:
	return _mesh


## **How planted this body is**, 0 to 1 — the Húskarl's Hold, from the
## replicated `Player.planted`, so it costs nothing on the wire. Read by the
## next `step()`, which is the one place a pose is made.
func brace(amount: float) -> void:
	_brace = clampf(amount, 0.0, 1.0)


## How far into a Hold the last `brace()` put this body, for `--verbs-probe`.
func braced() -> float:
	return _brace


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
	_strides_taken += speed * delta / STRIDE_METRES
	_breath = fposmod(_breath + delta * BREATH_HZ * TAU, TAU)
	var wants: float = clampf(
		speed / maxf(of_walking * FULL_GAIT_AT, 0.001), 0.0, 1.0)
	_gait = lerpf(_gait, wants, clampf(delta * GAIT_EASE, 0.0, 1.0))

	var swing: float = sin(_phase) * THIGH_SWING * _gait
	var fold: float = maxf(0.0, -sin(_phase)) * KNEE_BEND * _gait
	var fold_other: float = maxf(0.0, sin(_phase)) * KNEE_BEND * _gait

	# A planted body is not walking — Hold makes you immovable — so the lunge
	# replaces the stride rather than adding to it.
	swing *= 1.0 - _brace
	_turn("thigh_l", swing + stance * CROUCH_THIGH + _brace * BRACE_LEAD_THIGH)
	_turn("thigh_r", -swing + stance * CROUCH_THIGH + _brace * BRACE_BACK_THIGH)
	# Knees fold **backwards**, which is the opposite sign to the hip, and the
	# reason a knee cannot simply mirror its thigh.
	_turn("calf_l", -fold - stance * CROUCH_KNEE - _brace * BRACE_LEAD_KNEE)
	_turn("calf_r", -fold_other - stance * CROUCH_KNEE - _brace * BRACE_BACK_KNEE)
	# Arms oppose the legs. A body carrying nothing still swings them, because
	# the alternative — arms that hang dead while the legs work — is the tell
	# that reads as a puppet rather than as a person.
	#
	# The left arm is the shield's (`sock_hand_l`), and a Hold brings it up
	# across the chest: the one part of the pose a teammate across a room reads
	# as *they are holding this door*.
	# **A swing takes the arm from the walk** (ADR-330): the wind-up lifts it
	# up and over, the cut brings it down through the front. A bow is held up
	# in the left hand while the right draws back to the jaw.
	# Up with the draw at once; down after the loose in its own time.
	_pull_shown = _pull if _pull >= _pull_shown \
		else move_toward(_pull_shown, _pull, delta * BOW_SETTLE)
	var pull: float = _pull_shown
	var busy: float = clampf(maxf(maxf(_raise, _cut), pull * 1.5), 0.0, 1.0)
	var arm_r: float = swing * (ARM_SWING / THIGH_SWING) * (1.0 - busy)
	var elbow_r: float = absf(swing) * 0.35 * (1.0 - busy)
	var arm_l: float = -swing * (ARM_SWING / THIGH_SWING)
	var elbow_l: float = absf(swing) * 0.35
	if _bow:
		var up: float = clampf(pull * 2.0, 0.0, 1.0)
		if _wielded != null and is_instance_valid(_wielded):
			_wielded.rotation = BOW_TURN.lerp(BOW_DRAWN_TURN, up)
		arm_l = lerpf(arm_l, BOW_ARM, up)
		elbow_l *= 1.0 - up
		arm_r += pull * DRAW_ARM
		elbow_r += pull * DRAW_ELBOW
	else:
		arm_r += _raise * ARM_RAISE + _cut * ARM_CUT
		elbow_r += _raise * ELBOW_RAISE + _cut * ELBOW_CUT
	_turn("upper_arm_l", arm_l + _brace * BRACE_SHIELD_ARM)
	_turn("upper_arm_r", arm_r)
	# Elbows bend forward, which for a hanging forearm is the positive sense.
	_turn("forearm_l", elbow_l + _brace * BRACE_SHIELD_ELBOW)
	_turn("forearm_r", elbow_r)

	# An upright segment tips *back* on a positive turn, so a body folding
	# forward over its knees is a negative one.
	var lean: float = stance * 0.28 + _brace * BRACE_LEAN \
		+ (DOWNED_PITCH if downed else 0.0)
	_turn("spine_01", -lean * 0.45)
	_turn("chest", -lean * 0.35 + sin(_breath) * BREATH_RADIANS * (1.0 - _gait))
	# The head keeps looking where the eyes are while the spine folds under it,
	# so the two have to cancel rather than compound. Tipping back is looking
	# up, which is the sense `pitch` already has.
	_turn("neck", pitch * NECK_PITCH_SHARE + lean * 0.4)
	_turn("head", pitch * HEAD_PITCH_SHARE + lean * 0.4)

	if _bone.has("pelvis"):
		var index: int = _bone["pelvis"]
		# Two steps per cycle, so the hips rise twice — hence the doubled phase.
		var bob: float = -absf(sin(_phase)) * BOB_METRES * _gait
		var rest: Vector3 = _skeleton.get_bone_rest(index).origin
		_skeleton.set_bone_pose_position(index,
			rest + Vector3(0.0, bob - stance * CROUCH_DROP - _brace * BRACE_DROP, 0.0))
	_square_the_shield()


## Keep what the braced arm holds facing the way it faced at rest (ADR-272).
## Recorded while not braced, applied while braced, in the body's frame — so it
## needs no knowledge of the hand bone's axes, only of where the item hung.
func _square_the_shield() -> void:
	var held: Node3D = worn_on(Enums.Slot.OFF_HAND)
	if held == null:
		_held_known = false
		return
	if not held.has_meta(&"hung"):
		held.set_meta(&"hung", held.transform)
	var hung: Transform3D = held.get_meta(&"hung") as Transform3D
	var parent := held.get_parent() as Node3D
	if _brace <= 0.0:
		held.transform = hung
		_held_square = global_basis.inverse() * held.global_basis
		_held_offset = global_basis.inverse() * (held.global_position - parent.global_position)
		_held_known = true
		return
	if not _held_known:
		return
	var square := Transform3D(global_basis * _held_square,
		parent.global_position + global_basis * _held_offset)
	var local: Transform3D = parent.global_transform.affine_inverse() * square
	held.transform = Transform3D(
		hung.basis.orthonormalized().slerp(local.basis.orthonormalized(), _brace)
			.scaled(hung.basis.get_scale()),
		hung.origin.lerp(local.origin, _brace))


## Rotate one bone about its own swing axis. A bone this rig does not have is
## skipped rather than crashing: a re-export that drops a bone should lose that
## bone's motion, not the body.
##
## **About the rest pose, not in place of it** (ADR-265). This set the pose to
## the swing alone, which is the rest pose only for a bone whose rest rotation is
## identity — true of the legs and spine, and false of the arms, which rest in a
## twisted A-pose. So every teammate's arms were thrown up and out towards a T,
## the fist at 1.54 m instead of 1.07 m, and nothing saw it until something was
## hung in the hand and `--body-probe` asked where it was.
func _turn(name: String, radians: float) -> void:
	if not _bone.has(name):
		return
	var index: int = _bone[name]
	_skeleton.set_bone_pose_rotation(index,
		_skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			* Quaternion(_swing[name], radians))


## The body in the teammate's colour, its own value and carving kept (ADR-318).
## The body is sculpted and baked: its value map already holds ADR-308's range
## — each material's lightness against linen, never darker than 0.75 of the
## teammate's colour, so hair and a belt read as hair and a belt without a
## teammate reading as a threat — and its normal map holds the folds and the
## face. So the teammate's colour multiplies the one, and the other is kept.
func _dress_in(skin: StandardMaterial3D) -> void:
	for surface: int in _mesh.mesh.get_surface_count():
		var authored := _mesh.mesh.surface_get_material(surface) as BaseMaterial3D
		var made := skin.duplicate() as StandardMaterial3D
		if authored != null:
			made.albedo_texture = authored.albedo_texture
			made.normal_enabled = authored.normal_enabled
			made.normal_texture = authored.normal_texture
			made.normal_scale = authored.normal_scale
		_mesh.set_surface_override_material(surface, made)


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
