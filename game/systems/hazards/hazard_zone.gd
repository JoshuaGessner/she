class_name HazardZone
extends Node3D
## A hazard's room on a built floor (ADR-236).
##
## **A box a body is asked about, not a physics area.** An `Area3D` would report
## entering and leaving through signals, host and client each keeping their own
## tally of who is inside; a body asking *"what am I standing in"* of its own
## position every tick has nothing to fall out of step. Rooms never overlap
## (`FloorPlan`), so a point is in one zone or none, and a floor lays a handful.
##
## Laid by `FloorBuilder` on every peer from the same seed, like the walls, so
## every peer has the same zones without a byte on the wire.

const GROUP: StringName = &"hazard_zones"
## How high a zone reaches above its floor. A body is asked about at its feet, so
## this only has to hold a standing one; a ledge above it is somewhere to stand
## out of the damp.
const REACH: float = 2.6

var hazard: HazardResource = null
## In this node's own space, centred on it.
var box: AABB = AABB()


func _ready() -> void:
	add_to_group(GROUP)


## A zone over a `span` of floor centred on `centre`: what `FloorBuilder` lays
## for a machine's room and what `--hazard-probe` lays where it wants one, so the
## two cannot disagree about what a zone covers. From half a metre under the
## floor, so a body's feet are in it.
static func made(of: HazardResource, centre: Vector3, span: Vector2) -> HazardZone:
	var zone := HazardZone.new()
	zone.hazard = of
	zone.position = centre
	zone.box = AABB(Vector3(-span.x * 0.5, -0.5, -span.y * 0.5),
		Vector3(span.x, REACH + 0.5, span.y))
	return zone


## The hazard `point` stands in, or null. Asked through `from` because a scene
## tree is needed to find the zones and a static function has none.
static func at(from: Node, point: Vector3) -> HazardResource:
	if from == null or not from.is_inside_tree():
		return null
	for node: Node in from.get_tree().get_nodes_in_group(GROUP):
		var zone := node as HazardZone
		if zone != null and zone.hazard != null and zone.box.has_point(zone.to_local(point)):
			return zone.hazard
	return null
