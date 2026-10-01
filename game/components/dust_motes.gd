class_name DustMotes
extends GPUParticles3D

## **The air has something in it** (ADR-285). A few dozen motes drift in a box
## around the local player's head, in world space, so walking moves you through
## them rather than carrying them along. They are lit, never glowing, so they
## show only where there is light to show them — in your lantern's throw and a
## torch's — and the dark stays dark (`ART-001`). Opaque specks, because the
## ink pass paints over anything transparent (ADR-283).
##
## Local and decorative: nothing reads it and nothing crosses the wire.


func _ready() -> void:
	# **The Deep's air only** (ADR-286). On the Lair's paper page a speck's
	# shaded side prints as ink, and a floor of dark dots reads as dirt on the
	# lens rather than as dust in the light.
	if not (get_tree().current_scene is RoomSet):
		queue_free()
		return
	amount = 70
	lifetime = 7.0
	preprocess = 7.0
	local_coords = false
	randomness = 1.0
	visibility_aabb = AABB(Vector3(-4.0, -3.0, -4.0), Vector3(8.0, 6.0, 8.0))
	var drift := ParticleProcessMaterial.new()
	drift.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	drift.emission_box_extents = Vector3(3.0, 1.6, 3.0)
	drift.gravity = Vector3(0.0, -0.01, 0.0)
	drift.initial_velocity_min = 0.0
	drift.initial_velocity_max = 0.05
	drift.direction = Vector3(0.0, 1.0, 0.0)
	drift.spread = 180.0
	drift.turbulence_enabled = true
	drift.turbulence_noise_strength = 0.15
	drift.turbulence_noise_speed_random = 0.4
	drift.scale_min = 0.5
	drift.scale_max = 1.0
	process_material = drift
	var speck := BoxMesh.new()
	speck.size = Vector3(0.006, 0.006, 0.006)
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.86, 0.82, 0.72)
	lit.roughness = 1.0
	# No outline (class 3, bare): a speck drawn round in ink is a black dot,
	# and on the Lair's paper page a floor of black dots is dirt on the lens.
	InkPass.stamp(lit, InkPass.Class.BARE)
	speck.material = lit
	draw_pass_1 = speck
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
