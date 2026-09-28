class_name Hands
extends Node3D
## **What your left hand is holding, and what you are doing with your hands**
## (`M4-T10`, ADR-267) — first person only.
##
## The weapon in the right hand has always been drawn: `MeleeWeapon` and
## `RangedWeapon` pose it, because its wind-up is a telegraph. Everything else a
## player holds was invisible to the one holding it. `DES-020` says of the off
## hand *"seen by you: constantly"*, and a lantern you cannot see is a light
## source you have to remember you are carrying — in a game where
## `DES-012` makes that light the thing that gives you away.
##
## So this draws, in front of the camera:
##
## - **the off hand** — a lantern hanging from the fist with its shutter open
##   or shut as `Player.lit` says, or a shield that comes up across the view
##   while the guard is raised (`Player.blocking`);
## - **a binding being tied** (`Player.mending`) — the roll turning as the linen
##   comes off it, the off hand lowered out of the way to tie it;
## - **a Waystone being spent** (`Player.leaving`) — the stone raised and
##   taking the doorway's pale as the way out opens.
##
## ## It reads state and writes none
##
## Every input is a number the body already has, and `step()` is called down by
## `Player` each frame. Nothing here is replicated, nothing here is read back,
## and a teammate sees the same states on their body through `BodyRig` —
## `HeldLook` is the one place either of them turns a number into a pose.
##
## ## Where things are held
##
## In the head's frame, like the weapon, so a lantern stays where a hand holds
## it when you look down at your feet. Poses are ⟨tune⟩ and were set against
## `--hands-shot`; the lantern's is chosen so its flame sits close to where
## `Lantern.GRIP` puts the actual light, so what you see lit is lit from there.

## Where the off-hand item rests — (position, rotation in degrees), head frame.
const OFF_REST: Array = [Vector3(-0.42, 0.12, -0.74), Vector3(0, 158, 4)]
## Where a shield comes to while the guard is up: across the body, face out.
const OFF_GUARD: Array = [Vector3(-0.12, -0.20, -0.42), Vector3(6, 4, -8)]
## Where the off hand goes while both hands are busy with something else.
const OFF_AWAY: Array = [Vector3(-0.46, -0.72, -0.50), Vector3(-30, 158, 4)]
## Where a thing being used is held: low and central, in both hands.
const USE_HELD: Array = [Vector3(0.0, -0.30, -0.46), Vector3(8, 0, 0)]
## Where it starts from as it is brought up.
const USE_BELOW: Array = [Vector3(0.0, -0.78, -0.40), Vector3(-40, 0, 0)]
## How fast poses chase what they want, per second ⟨tune⟩.
const EASE: float = 9.0

var _off_item: ItemResource = null
var _off_look: Node3D = null
var _off: Node3D = null
var _guard: float = 0.0
var _open: float = 0.0
var _busy: float = 0.0

var _use: Node3D = null
var _use_item: ItemResource = null
var _use_look: Node3D = null
var _raised: float = 0.0


func _ready() -> void:
	_off = Node3D.new()
	_off.name = "OffHand"
	add_child(_off)
	_use = Node3D.new()
	_use.name = "InUse"
	add_child(_use)
	_place(_off, OFF_AWAY, OFF_AWAY, 0.0)
	_place(_use, USE_BELOW, USE_BELOW, 0.0)


## What the off hand holds, or null. Rebuilt only when it changes.
func hold(item: ItemResource) -> void:
	if item == _off_item:
		return
	_off_item = item
	if _off_look != null:
		_off_look.free()
		_off_look = null
	if item == null:
		return
	_off_look = item.look()
	if _off_look == null:
		return
	# A thing that gives light hangs from the fist by its bail; anything else
	# is held by its middle.
	var box: AABB = _bounds(_off_look)
	if item.has_trait(LightTrait):
		_off_look.position = Vector3(0.0, -box.end.y, 0.0)
	else:
		_off_look.position = -box.get_center()
	_off.add_child(_off_look)
	# In from below, like a weapon: a thing put in the hand arrives.
	_busy = 1.0


## Pose everything for this frame from what the body is doing.
##
## `lit` is whether the lamp is open, `guarding` whether the guard is up,
## `mending` and `leaving` the fractions of a binding and a Waystone done, each
## 0 when nothing is under way.
func step(delta: float, lit: bool, guarding: bool, mending: float,
		leaving: float) -> void:
	var rate: float = clampf(delta * EASE, 0.0, 1.0)
	_open = lerpf(_open, 1.0 if lit else 0.0, rate)
	var shield: bool = _off_item != null and _off_item.has_trait(ShieldTrait)
	_guard = lerpf(_guard, 1.0 if guarding and shield else 0.0, rate)

	# What the hands are busy with, if anything.
	var using: ItemResource = null
	var done: float = 0.0
	if leaving > 0.0:
		using = HeldLook.first_with(ExtractionTrait)
		done = leaving
	elif mending > 0.0:
		using = HeldLook.first_with(MendingTrait)
		done = mending
	_bring(using)
	_raised = lerpf(_raised, 1.0 if using != null else 0.0, rate)
	_busy = lerpf(_busy, 1.0 if using != null else 0.0, rate)

	# The off hand: at rest, up across the body on guard, or out of the way.
	var off_at: Array = _blend(OFF_REST, OFF_GUARD, _guard)
	_place(_off, off_at, OFF_AWAY, _busy)
	if _off_look != null and _off_item.has_trait(LightTrait):
		HeldLook.lantern(_off_look, _open)

	# The thing in use, and what doing it looks like.
	_place(_use, USE_BELOW, USE_HELD, _raised)
	_use.visible = _raised > 0.02
	if _use_look != null and _use_item != null:
		if _use_item.has_trait(ExtractionTrait):
			HeldLook.waystone(_use_look, done)
		elif _use_item.has_trait(MendingTrait):
			HeldLook.binding(_use_look, done)


## The model in the off hand, for `--hands-probe`.
func off_look() -> Node3D:
	return _off_look


## The model being used, or null, for `--hands-probe`.
func use_look() -> Node3D:
	return _use_look if _use.visible else null


func _bring(item: ItemResource) -> void:
	if item == _use_item or item == null:
		return
	_use_item = item
	if _use_look != null:
		_use_look.free()
	_use_look = item.look()
	if _use_look != null:
		_use_look.position = -_bounds(_use_look).get_center()
		# Held in a pivot of its own, so turning it (a binding unwinding)
		# turns it about its middle rather than about where it was lying.
		var pivot := Node3D.new()
		pivot.name = "pivot"
		pivot.add_child(_use_look)
		for child: Node in _use.get_children():
			child.free()
		_use.add_child(pivot)
		_use_look = pivot


static func _bounds(look: Node3D) -> AABB:
	var out := AABB()
	var first: bool = true
	for node: Node in look.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box: AABB = mesh.transform * mesh.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


static func _blend(from: Array, to: Array, t: float) -> Array:
	return [(from[0] as Vector3).lerp(to[0] as Vector3, t),
		(from[1] as Vector3).lerp(to[1] as Vector3, t)]


static func _place(node: Node3D, from: Array, to: Array, t: float) -> void:
	var at: Array = _blend(from, to, t)
	node.position = at[0] as Vector3
	var turn: Vector3 = at[1] as Vector3
	node.rotation = Vector3(deg_to_rad(turn.x), deg_to_rad(turn.y),
		deg_to_rad(turn.z))
