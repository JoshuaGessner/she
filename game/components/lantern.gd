class_name Lantern
extends Node3D

## The light you are carrying, if you are carrying one (`M4-T13`, `ART-001`).
##
## One job: turn *"there is a `LightTrait` in the off hand"* into an actual lamp
## in the world, and take it away again. Everything the light **costs** is
## `Exposure`'s; everything it **draws** is `ART-005`'s. This node is the seam
## between an item and a photon and holds no rules of its own.
##
## ## Why the lamp joins a group instead of being found by walking the tree
##
## `Exposure` has to answer *"how lit is this body"* for up to four bodies
## against every light on the floor, and the floor's own doorway lamps are
## already in a group for exactly that kind of question (`RoomSet`'s
## `--sight-probe` reads its lights the same way). One group means a teammate's
## lantern and a doorway light are the same kind of thing to the system that
## cares, which is what makes *"four players and four lanterns is a floodlight"*
## fall out of `DES-012` with no co-op branch anywhere (ADR-188).
##
## ## Where it hangs
##
## Chest height and a little to the left, on the body rather than the head —
## **not** `sock_hand_l`. `DES-020` reserves that socket and gives each off-hand
## item its own grip offset in its `.tres`, and neither the rig socket nor the
## held mesh exists yet at blockout (ADR-046). A light parented to the head
## would also swing with pitch, so looking at your feet would darken the room.

## Every light a body can be seen by. Door lamps join it too — see the header.
const LIGHT_GROUP: StringName = &"lights_the_dark"

## Where the lamp rides on the body ⟨tune⟩. Left of centre, at the height a
## hand carries a lantern, so a teammate's light reads as *held* rather than as
## a glow emitted by a person.
const GRIP: Vector3 = Vector3(-0.35, 1.05, 0.0)

var _lamp: OmniLight3D = null
var _carried: LightTrait = null


## What is in the off hand, or null. Called from `Player._on_equipment_changed`,
## so the lamp exists exactly when a light-bearing item is held — calls down,
## and this node never reaches up to ask what is equipped.
func carry(light: LightTrait) -> void:
	_carried = light
	if light == null:
		_put_out()
		return
	if _lamp == null:
		_lamp = OmniLight3D.new()
		_lamp.name = "Flame"
		_lamp.position = GRIP
		_lamp.add_to_group(LIGHT_GROUP)
		add_child(_lamp)
	_lamp.light_color = light.colour
	_lamp.light_energy = light.energy
	_lamp.omni_range = light.radius


## Open or close the shutter. Driven from `Player.lit`, which is replicated —
## so a teammate's lantern goes dark on every screen, and on the host, whose
## enemies are the ones reading `Exposure`.
func show_flame(alight: bool) -> void:
	if _lamp != null:
		_lamp.visible = alight


## Is there anything to shutter? `Player.try_shutter` asks, so the verb refuses
## rather than toggling a flag against an empty hand.
func held() -> bool:
	return _carried != null


## Is the flame actually reaching the world right now?
##
## Asked rather than inferred: `Exposure` needs this, and the alternative was
## `get_node_or_null("Flame").is_visible_in_tree()` — a sibling reaching through
## this node into its children by name, which `TEC-001`'s *calls down, never
## sideways* rules out and which a rename would break silently.
func burning() -> bool:
	return _lamp != null and _lamp.is_visible_in_tree()


## Is that light this body's own lamp?
##
## `Exposure` walks `LIGHT_GROUP` for everything that can give a body away, and
## this lamp is in that group because **teammates** have to be lit by it. Its
## bearer must not be, twice: `glare` is what carrying a light costs you, and
## the falloff curve would otherwise quietly overrule it — a lamp hangs 0.35 m
## from the chest, so a designer authoring a dim candle at `glare = 0.3` would
## get 0.97 anyway and have no way to find out why. A field that cannot be
## turned down is a field that lies.
func owns(light: OmniLight3D) -> bool:
	return _lamp != null and light == _lamp


## How much this exposes its bearer while open, on `Exposure`'s 0–1 scale.
func glare() -> float:
	return _carried.glare if _carried != null else 0.0


## Seconds before the shutter can be worked again — what stops a player
## strobing the lamp to get sight without exposure. See `LightTrait`.
func shutter_seconds() -> float:
	return _carried.shutter_seconds if _carried != null else 0.0


func _put_out() -> void:
	if _lamp == null:
		return
	# Freed rather than hidden. A hidden lamp still sits in `LIGHT_GROUP` and
	# `Exposure` would keep stepping over it once per body per tick for the
	# rest of the run, and a dropped lantern that still lights you is exactly
	# the kind of bug that reads as the game cheating.
	_lamp.queue_free()
	_lamp = null
