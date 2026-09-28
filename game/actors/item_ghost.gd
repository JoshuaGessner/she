class_name ItemGhost
extends Node3D
## **A taken thing, seen going into the bag** (ADR-267).
##
## The host frees an item the moment it is taken — that is what makes two
## players lunging for one coin resolve (`WorldItem`'s header) — so the thing
## on the floor cannot itself be what flies. This is a copy of its model, made
## by the taker's own process as its `WorldItem` leaves, sent from where it lay
## down past the lower edge of the view in a fifth of a second and gone.
##
## Nothing reads it and nothing is decided by it: it is not in a group, carries
## no collision (`ItemResource.look` strips it) and frees itself.

## How long the flight takes ⟨tune⟩. Under a quarter-second, so it reads as a
## hand going down for something and not as the item being admired.
const SECONDS: float = 0.22
## Where it goes, in the camera's frame: below and a little right of the
## crosshair, where a bag would be if you could see yourself carrying one.
const INTO: Vector3 = Vector3(0.18, -0.55, -0.45)
## How small it is when it gets there, as a fraction of its size.
const SHRINK: float = 0.15

var _to: Node3D = null


## A ghost of `item` lying at `from`, bound for `eye`. Null if it has no model.
static func made(item: ItemResource, from: Transform3D, eye: Node3D) -> ItemGhost:
	var look: Node3D = item.look()
	if look == null:
		return null
	var ghost := ItemGhost.new()
	ghost.name = "ghost_%s" % item.id
	ghost.transform = from
	ghost._to = eye
	ghost.add_child(look)
	return ghost


func _ready() -> void:
	if _to == null or not is_instance_valid(_to):
		queue_free()
		return
	var goal: Vector3 = _to.global_transform * INTO
	var flight := create_tween().set_parallel(true)
	flight.tween_property(self, "global_position", goal, SECONDS) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	flight.tween_property(self, "scale", Vector3.ONE * SHRINK, SECONDS) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	flight.chain().tween_callback(queue_free)
