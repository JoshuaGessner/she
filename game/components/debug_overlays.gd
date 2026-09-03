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
##
## `M2-T02` adds the third thing: **the clamor field the Gullsjúkr navigates**,
## drawn as a fill because it is emphatically not what you emit — it is the
## level's memory of noise, which is a different object from your current
## radius and behaves differently. Seeing both at once is the whole reason this
## overlay exists: `TEC-001` says the field is untunable blind, and the two
## things it is easiest to confuse are *how far I carry right now* and *where
## the noise I made is still lying around.*

## Enough to show a doorway notch without the outline looking polygonal.
const RING_SEGMENTS: int = 96
const VISION_SEGMENTS: int = 32

## Dark on a pale floor. ART-005 spends saturated colour on treasure, so
## contrast here has to come from value instead.
const RING_COLOUR: Color = Color(0.08, 0.08, 0.09, 0.9)
## Low enough that three overlapping cones stay readable.
const VISION_IDLE: Color = Color(0.10, 0.10, 0.12, 0.16)
const VISION_SEEING: Color = Color(0.02, 0.02, 0.03, 0.42)
## Between the two, because hearing you is between not knowing and knowing.
## Value rather than hue, like everything else here: `ART-005` spends colour on
## treasure, and a diagnostic overlay is the last thing that should borrow it.
const VISION_HEARING: Color = Color(0.05, 0.05, 0.07, 0.28)

## 127 is Godot's `MATERIAL_RENDER_PRIORITY_MAX`; anything higher is rejected at
## runtime rather than clamped. Diagnostics sit above the ink pass, which is a
## transparent full-screen quad at priority 100 — below it they are composited
## over and vanish, which reads as "the overlay is broken" when it is not.
const OVERLAY_PRIORITY: int = 127

## Sound leaves the head, not the feet. Casting along the floor makes every
## ramp read as a wall.
const EAR_HEIGHT: float = 1.2

## The field, as heat. Warm where noise is, and it has to stay well under the
## vision fills in value or a loud room drowns out every other diagnostic.
const FIELD_COLOUR: Color = Color(0.72, 0.30, 0.12, 0.30)
## Cells quieter than this are not drawn at all. Drawing every cell at low alpha
## turns the floor into a uniform wash that reads as nothing.
const FIELD_FLOOR: float = 0.35
## Just off the floor, under the emission outline. The field is background
## information; your own footprint is the thing you are reading.
const FIELD_HEIGHT: float = 0.03

var _ring: MeshInstance3D = null
var _field_mesh: MeshInstance3D = null
var _field: ClamorField = null
var _player: Player = null


## **Off until asked for** (`M2-T13`, ADR-105).
##
## This used to draw in every session, which made it an x-ray rather than a
## diagnostic: a playtester could see every enemy's vision cone and the whole
## clamor field painted on the floor. `DES-019` forbids the Ear from showing
## enemy count, health or type precisely so that noticing is a skill — and this
## handed all three to anyone standing still, then invited them to report on how
## legible the pressure felt.
##
## It stays because `TEC-001` is right that the field is untunable blind. It is
## simply not a thing to hand a tester by default. `o` / d-pad-right, next to
## the other two debug keys.
var _shown: bool = false


func _ready() -> void:
	visible = false
	_ring = MeshInstance3D.new()
	_ring.mesh = ImmediateMesh.new()
	_ring.material_override = _material(RING_COLOUR)
	add_child(_ring)

	_field_mesh = MeshInstance3D.new()
	_field_mesh.mesh = ImmediateMesh.new()
	var field_material: StandardMaterial3D = _material(Color.WHITE)
	# Loudness is per cell, so it arrives as a vertex colour rather than as a
	# material property. Without this flag `surface_set_color` is silently
	# ignored and every cell draws at the same alpha — a field that looks
	# uniform, which is exactly the reading it must never give.
	field_material.vertex_color_use_as_albedo = true
	_field_mesh.material_override = field_material
	add_child(_field_mesh)


## Levels hand over the field they built. Not discovered by group: the field is
## host-only (`TEC-001`), so on a client there is genuinely nothing to draw and
## the overlay should show nothing rather than an empty grid that reads as
## "silent everywhere".
func show_field(field: ClamorField) -> void:
	_field = field


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_overlays"):
		return
	_shown = not _shown
	visible = _shown
	# The vision cones live on the enemies (`top_level`, so they draw on the
	# floor rather than inside a body), which puts them outside this node's
	# visibility. Hiding only the ring and the field would leave the loudest
	# part of the x-ray on screen — and it is the part a tester would most
	# obviously read.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var cone: Node = node.get_node_or_null("VisionOverlay")
		if cone != null:
			(cone as MeshInstance3D).visible = _shown


func _process(_delta: float) -> void:
	if not _shown:
		return
	if _player == null or not is_instance_valid(_player):
		# `local_player`, not `player`: the ring is *what you are emitting*, so
		# with a party it has to follow the body this process is playing rather
		# than whichever teammate happens to be first in the group.
		_player = get_tree().get_first_node_in_group("local_player") as Player
		if _player == null:
			return
	_redraw_ring()
	_redraw_field()
	_sync_vision()


## The clamor field, one quad per audible cell, brighter where it is louder.
##
## Redrawn every frame from the host's live grid rather than cached on the
## field's `ticked` signal — the overlay must never be able to show a field the
## Hunter is not reading, and the cheapest way to guarantee that is to have no
## second copy to fall out of date (the ADR-073 rule).
func _redraw_field() -> void:
	var mesh: ImmediateMesh = _field_mesh.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if _field == null or _field.width() == 0:
		return
	var ceiling: float = maxf(Config.tuning.clamor_field_maximum, 0.001)
	# Gathered before the surface is opened, because `surface_end` on an empty
	# surface is an engine error rather than a no-op — and a silent field is
	# the *normal* state at the start of a run, so the naive version errors
	# every frame until somebody makes a noise.
	var audible: Array[Vector2i] = []
	for y: int in range(_field.height()):
		for x: int in range(_field.width()):
			if _field.level_in(Vector2i(x, y)) >= FIELD_FLOOR:
				audible.append(Vector2i(x, y))
	if audible.is_empty():
		return

	var half: float = ClamorField.CELL_METRES * 0.5
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for cell: Vector2i in audible:
		var centre: Vector3 = _field.cell_centre(cell.x, cell.y)
		centre.y = FIELD_HEIGHT
		# Alpha carries loudness. Value rather than hue, so the overlay is
		# still readable in monochrome (`DES-018`) and does not compete with
		# the one saturated colour the game reserves for treasure.
		var shade: Color = FIELD_COLOUR
		shade.a *= clampf(_field.level_in(cell) / ceiling, 0.0, 1.0) * 3.0
		mesh.surface_set_color(shade)
		var a := centre + Vector3(-half, 0.0, -half)
		var b := centre + Vector3(half, 0.0, -half)
		var c := centre + Vector3(half, 0.0, half)
		var d := centre + Vector3(-half, 0.0, half)
		for corner: Vector3 in [a, b, c, a, c, d]:
			mesh.surface_add_vertex(corner)
	mesh.surface_end()


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
		# Seeing you is the one state that must be unmissable at a glance, and
		# **hearing you is a different state** (ADR-074: sight and hearing are
		# separate signals). The overlay drew only sight, so the one question it
		# could not answer was the one the Clamor system exists to raise —
		# *has this thing noticed the noise I am making?* — and the answer lived
		# in a text readout instead, where a playtester could read it.
		var material := cone.material_override as StandardMaterial3D
		if enemy.sees_player():
			material.albedo_color = VISION_SEEING
		elif enemy.hears_player():
			material.albedo_color = VISION_HEARING
		else:
			material.albedo_color = VISION_IDLE
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

	# **The cone is as long as *you* are visible** (`M4-T13`). Drawn from the
	# same `Exposure.seen_from()` the enemy resolves sight with, so shuttering
	# the lantern visibly pulls every cone in the room back — which is the one
	# picture that teaches the mechanic. A cone frozen at `enemy_vision_range`
	# would be a debug view contradicting the sight that killed you, and this
	# file's own ring already refuses to do that.
	var seen_at: float = (_player.exposure.seen_from() if _player != null
		else tuning.enemy_vision_range)

	var points: Array[Vector3] = []
	for i: int in range(VISION_SEGMENTS + 1):
		var angle: float = -half + 2.0 * half * float(i) / float(VISION_SEGMENTS)
		var direction: Vector3 = forward.rotated(Vector3.UP, angle)
		var reach: float = seen_at
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
