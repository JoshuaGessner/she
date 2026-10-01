class_name Hearth
extends RefCounted

## **Fire, wherever fire is** (ADR-283, ADR-286). The camp's pit and her hall's
## braziers burn the same way: an ember bed, tongues of flame that stand up from
## any side, sparks going up, and a light that breathes. One builder, so a
## brazier and a camp fire cannot drift into two ideas of what a flame is.

const FLAME: Shader = preload("res://art/shaders/flame.gdshader")


## Flames, embers and sparks at `at`, scaled by `size` (1 is the camp's pit).
static func flames(into: Node3D, at: Vector3, size: float) -> void:
	var bed := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5 * size
	disc.bottom_radius = 0.56 * size
	disc.height = 0.06 * size
	bed.mesh = disc
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.9, 0.36, 0.1)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.42, 0.12)
	glow.emission_energy_multiplier = 1.4
	InkPass.stamp(glow, InkPass.Class.GOLD)
	bed.material_override = glow
	bed.position = at + Vector3(0.0, 0.03 * size, 0.0)
	into.add_child(bed)
	for i: int in 2:
		var tongue := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.62 - 0.18 * float(i), 1.5 - 0.4 * float(i)) * size
		quad.center_offset = Vector3(0.0, quad.size.y * 0.5, 0.0)
		tongue.mesh = quad
		var burn := ShaderMaterial.new()
		burn.shader = FLAME
		burn.set_shader_parameter("seed", float(i) * 0.37 + at.x * 0.11)
		burn.set_shader_parameter("speed", 1.5 + 0.4 * float(i))
		tongue.material_override = burn
		tongue.position = at + Vector3(0.06 * float(i), 0.12, -0.04 * float(i)) * size
		tongue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		into.add_child(tongue)
	var sparks := GPUParticles3D.new()
	sparks.amount = int(26.0 * size)
	sparks.lifetime = 1.8
	sparks.position = at + Vector3(0.0, 0.5 * size, 0.0)
	var rise := ParticleProcessMaterial.new()
	rise.direction = Vector3(0.0, 1.0, 0.0)
	rise.spread = 18.0
	rise.initial_velocity_min = 0.6 * size
	rise.initial_velocity_max = 1.4 * size
	rise.gravity = Vector3(0.0, 0.25, 0.0)
	rise.turbulence_enabled = true
	rise.turbulence_noise_strength = 0.6
	rise.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	rise.emission_sphere_radius = 0.3 * size
	rise.scale_min = 0.6
	rise.scale_max = 1.0
	sparks.process_material = rise
	var mote := BoxMesh.new()
	mote.size = Vector3(0.025, 0.025, 0.025)
	var spark_glow := StandardMaterial3D.new()
	spark_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_glow.albedo_color = Color(1.0, 0.62, 0.22)
	InkPass.stamp(spark_glow, InkPass.Class.GOLD)
	mote.material = spark_glow
	sparks.draw_pass_1 = mote
	into.add_child(sparks)


## The light a fire gives, breathing (`FlickerLight`).
static func light(into: Node3D, at: Vector3, colour: Color, energy: float,
		reach: float, shadows: bool) -> FlickerLight:
	var lamp := FlickerLight.new()
	lamp.position = at
	lamp.light_color = colour
	lamp.light_energy = energy
	lamp.omni_range = reach
	lamp.shadow_enabled = shadows
	into.add_child(lamp)
	return lamp


## **A brazier** (ADR-286): an iron bowl on three legs with a fire in it, solid
## to walk into. For her hall, where light is ceremony rather than mechanic.
static func brazier(into: Node3D, at: Vector3) -> void:
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.13, 0.12, 0.12)
	iron.metallic = 0.6
	iron.roughness = 0.6
	var bowl := MeshInstance3D.new()
	var cup := CylinderMesh.new()
	cup.top_radius = 0.48
	cup.bottom_radius = 0.24
	cup.height = 0.32
	bowl.mesh = cup
	bowl.material_override = iron
	bowl.position = at + Vector3(0.0, 1.0, 0.0)
	into.add_child(bowl)
	for i: int in 3:
		var angle: float = TAU * float(i) / 3.0
		var leg := MeshInstance3D.new()
		var rod := CylinderMesh.new()
		rod.top_radius = 0.035
		rod.bottom_radius = 0.045
		rod.height = 1.0
		leg.mesh = rod
		leg.material_override = iron
		leg.position = at + Vector3(cos(angle) * 0.24, 0.5, sin(angle) * 0.24)
		leg.rotation = Vector3(sin(angle) * 0.22, 0.0, -cos(angle) * 0.22)
		into.add_child(leg)
	var solid := StaticBody3D.new()
	solid.collision_layer = CollisionLayers.WORLD
	solid.collision_mask = 0
	var shape := CollisionShape3D.new()
	var column := CylinderShape3D.new()
	column.radius = 0.45
	column.height = 1.2
	shape.shape = column
	solid.add_child(shape)
	solid.position = at + Vector3(0.0, 0.6, 0.0)
	into.add_child(solid)
	flames(into, at + Vector3(0.0, 1.12, 0.0), 0.55)
	light(into, at + Vector3(0.0, 1.9, 0.0), Color(1.0, 0.66, 0.32), 1.6, 9.0, false)


## **A lamp hung in a doorway** (ADR-291): an iron cage on a short chain with a
## cold pale flame in it. The Delvings' door lights were lights with nothing
## giving them — a glow from nowhere over every doorway. This is what gives
## them, in their own pale colour, so the light a player steers by has a
## source a player can see.
static func door_lamp(into: Node3D, at: Vector3, colour: Color) -> void:
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.1, 0.095, 0.09)
	iron.metallic = 0.5
	iron.roughness = 0.6
	var chain := MeshInstance3D.new()
	var link := BoxMesh.new()
	link.size = Vector3(0.03, 0.5, 0.03)
	chain.mesh = link
	chain.material_override = iron
	chain.position = at + Vector3(0.0, 0.48, 0.0)
	into.add_child(chain)
	for corner: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var bar := MeshInstance3D.new()
		var rod := BoxMesh.new()
		rod.size = Vector3(0.03, 0.46, 0.03)
		bar.mesh = rod
		bar.material_override = iron
		bar.position = at + Vector3(corner.x * 0.14, 0.0, corner.y * 0.14)
		into.add_child(bar)
	for y: float in [-0.23, 0.23]:
		var plate := MeshInstance3D.new()
		var cap := BoxMesh.new()
		cap.size = Vector3(0.34, 0.035, 0.34)
		plate.mesh = cap
		plate.material_override = iron
		plate.position = at + Vector3(0.0, y, 0.0)
		into.add_child(plate)
	var tongue := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.17, 0.32)
	quad.center_offset = Vector3(0.0, 0.16, 0.0)
	tongue.mesh = quad
	var burn := ShaderMaterial.new()
	burn.shader = FLAME
	burn.set_shader_parameter("core", colour.lightened(0.3))
	burn.set_shader_parameter("rim", colour.darkened(0.25))
	burn.set_shader_parameter("seed", at.x * 0.31 + at.z * 0.17)
	tongue.material_override = burn
	tongue.position = at + Vector3(0.0, -0.2, 0.0)
	tongue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	into.add_child(tongue)
