class_name DebugOverlays
extends Node3D

## The spatial half of `M1-T04`: what you are emitting, and what they perceive.
##
## Extracted from the movement gym so the room set gets it too. `TEC-001` on the
## Clamor field: *"Build that overlay early; this system is untunable blind."*
## That is truer in a level with corners than in an open gym — occlusion only
## has anything to show once there is something to hide behind — and leaving
## the overlay behind in the gym meant the one space built to exercise walls
## was the one space that could not display them.
##
## Add one to any level. It finds the player and the enemies by group, so it
## needs no wiring and no debug geometry inside either actor scene.
##
## **The visual language is one rule:** an *outline* is what you emit, a *fill*
## is what they perceive. Your clamor footprint is a line on the floor; an
## enemy's vision cone is a filled wedge. Two overlapping fills read as two
## enemies looking at the same place; two overlapping outlines read as mush.

## Enough to show a doorway notch without the outline looking polygonal.
const RING_SEGMENTS: int = 96
const VISION_SEGMENTS: int = 32

## Dark on a pale floor. ART-005 spends saturated colour on treasure, so
## contrast here has to come from value instead.
const RING_COLOUR: Color = Color(0.08, 0.08, 0.09, 0.9)
## Low enough that three overlapping cones stay readable.
const VISION_IDLE: Color = Color(0.10, 0.10, 0.12, 0.16)
const VISION_SEEING: Color = Color(0.02, 0.02, 0.03, 0.42)

## 127 is Godot's `MATERIAL_RENDER_PRIORITY_MAX`; anything higher is rejected at
## runtime rather than clamped. Diagnostics sit above the ink pass, which is a
## transparent full-screen quad at priority 100 — below it they are composited
## over and vanish, which reads as "the overlay is broken" when it is not.
const OVERLAY_PRIORITY: int = 127

## Sound leaves the head, not the feet. Casting along the floor makes every
## ramp read as a wall.
const EAR_HEIGHT: float = 1.2

var _ring: MeshInstance3D = null
var _player: Player = null


func _ready() -> void:
	_ring = MeshInstance3D.new()
	_ring.mesh = ImmediateMesh.new()
	_ring.material_override = _material(RING_COLOUR)
	add_child(_ring)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
	_redraw_ring()
	_sync_vision()


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	material.render_priority = OVERLAY_PRIORITY
	return material


## The audible footprint: a closed outline whose radius in each direction is
## however far sound actually carries that way.
##
## Not a circle, because a circle becomes a lie the moment there is a wall, and
## showing occlusion is the entire reason this exists. Every vertex comes from
## `ClamorSource.reach()` — the same function the enemies' ears use — so the
## shape on the ground is exactly the shape being simulated.
func _redraw_ring() -> void:
	var mesh := _ring.mesh as ImmediateMesh
	mesh.clear_surfaces()
	var radius: float = _player.clamor.audible_radius()
	if radius <= 0.1:
		return
	var origin: Vector3 = _player.global_position + Vector3.UP * EAR_HEIGHT
	var world: World3D = _player.get_world_3d()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i: int in range(RING_SEGMENTS + 1):
		var angle: float = TAU * float(i) / float(RING_SEGMENTS)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var carried: float = ClamorSource.reach(world, origin, direction, radius)
		var point: Vector3 = origin + direction * carried
		point.y = _player.global_position.y + 0.05
		mesh.surface_add_vertex(point)
	mesh.surface_end()


## Each enemy owns its cone, so the engine disposes of it with the enemy.
##
## A `{enemy: overlay}` dictionary cannot work here: iterating its keys assigns
## a freed instance to a typed loop variable, which throws *before* any
## `is_instance_valid()` guard can run. `top_level` keeps the cone's transform
## in world space — which is what its vertices are built in — while its
## lifetime follows its parent.
func _sync_vision() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		var cone := enemy.get_node_or_null("VisionOverlay") as MeshInstance3D
		if cone == null:
			cone = MeshInstance3D.new()
			cone.name = "VisionOverlay"
			cone.top_level = true
			cone.mesh = ImmediateMesh.new()
			cone.material_override = _material(VISION_IDLE)
			(cone.material_override as StandardMaterial3D).cull_mode = \
				BaseMaterial3D.CULL_DISABLED
			enemy.add_child(cone)
		# Seeing you is the one state that must be unmissable at a glance.
		var material := cone.material_override as StandardMaterial3D
		material.albedo_color = VISION_SEEING if enemy.sees_player() else VISION_IDLE
		_redraw_cone(enemy, cone.mesh as ImmediateMesh)


## One filled wedge per enemy: `DES-013`'s vision half-angle, every ray cut at
## the first wall.
##
## Filled rather than outlined because a hairline cannot carry a shape across a
## room and Godot 4 will not widen one. The first version drew a dashed arc and
## vanished at any distance.
func _redraw_cone(enemy: Enemy, mesh: ImmediateMesh) -> void:
	mesh.clear_surfaces()
	if enemy.state() == Enemy.State.DEAD:
		return
	var tuning: TuningProfile = Config.tuning
	var origin: Vector3 = enemy.eye_position()
	var forward: Vector3 = enemy.facing()
	var half: float = deg_to_rad(tuning.enemy_vision_half_angle)
	var floor_y: float = enemy.global_position.y + 0.04
	var space: PhysicsDirectSpaceState3D = enemy.get_world_3d().direct_space_state

	var points: Array[Vector3] = []
	for i: int in range(VISION_SEGMENTS + 1):
		var angle: float = -half + 2.0 * half * float(i) / float(VISION_SEGMENTS)
		var direction: Vector3 = forward.rotated(Vector3.UP, angle)
		var reach: float = tuning.enemy_vision_range
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * reach)
		query.collision_mask = CollisionLayers.WORLD
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			reach = origin.distance_to(hit["position"] as Vector3)
		var point: Vector3 = origin + direction * reach
		point.y = floor_y
		points.append(point)

	var apex: Vector3 = Vector3(origin.x, floor_y, origin.z)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(points.size() - 1):
		mesh.surface_add_vertex(apex)
		mesh.surface_add_vertex(points[i])
		mesh.surface_add_vertex(points[i + 1])
	mesh.surface_end()
