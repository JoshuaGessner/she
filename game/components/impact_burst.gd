class_name ImpactBurst
extends RefCounted

## **Where a blow lands, seen** (ADR-303). ADR-279 gave a landed blow its
## hitstop, its kick, its sound and the body's flinch, and named what it left
## out: particles. So a hit read in the hands and the ears and nowhere on the
## thing that was hit — you could feel that steel met something, and not see
## where.
##
## - **On mail or plate, sparks**: a spray of short bright slivers that fly
##   off the struck side and fall, self-lit so the dark does not hide them.
## - **On hide and cloth, chips**: dark flecks knocked off the body, fewer and
##   slower, falling hard.
##
## A heavy blow throws twice as many, further. Both are opaque — the ink pass
## paints over anything blended (`flame.gdshader`'s finding) — so the sparks
## stand on the fire's stencil class, which keeps its colour through the page,
## and the chips on `BARE`, with no line round a fleck.
##
## Look only: no collision, no light, nothing replicated. Every peer raises its
## own burst from the replicated health it already reads, and sprays it toward
## its own camera, which is the side of the body that peer is looking at.

const SPARK_COLOUR: Color = Color(1.0, 0.78, 0.42)
const CHIP_COLOUR: Color = Color(0.13, 0.11, 0.10)
## How long a burst lives, seconds ⟨tune⟩.
const LIFETIME: float = 0.55


## A burst at `at`, sprayed toward `toward`. Freed when it has fallen.
static func at(into: Node, point: Vector3, toward: Vector3, metal: bool,
		heavy: bool) -> GPUParticles3D:
	if DisplayServer.get_name() == "headless" or into == null:
		return null
	var burst := GPUParticles3D.new()
	burst.one_shot = true
	burst.explosiveness = 0.92
	burst.lifetime = LIFETIME
	burst.amount = (18 if metal else 14) * (2 if heavy else 1)
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fly := ParticleProcessMaterial.new()
	var out: Vector3 = toward - point
	out.y = 0.0
	fly.direction = (out.normalized() + Vector3(0.0, 0.45, 0.0)).normalized() \
		if out.length() > 0.01 else Vector3.UP
	fly.spread = 55.0 if metal else 40.0
	# From a patch of the body, not a point, so the first frames are a spray
	# rather than every fleck stacked into one block.
	fly.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fly.emission_sphere_radius = 0.09
	var speed: float = (4.2 if metal else 3.2) * (1.4 if heavy else 1.0)
	fly.initial_velocity_min = speed * 0.5
	fly.initial_velocity_max = speed
	fly.gravity = Vector3(0.0, -9.8 if metal else -14.0, 0.0)
	fly.damping_min = 1.0
	fly.damping_max = 3.0
	# Shrinks as it falls rather than fading, so it stays opaque to the end.
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	var shrinking := CurveTexture.new()
	shrinking.curve = shrink
	fly.scale_curve = shrinking
	fly.scale_min = 0.6
	fly.scale_max = 1.2
	if metal:
		# Slivers: drawn along the way they fly.
		fly.particle_flag_align_y = true
	burst.process_material = fly
	var fleck := BoxMesh.new()
	fleck.size = Vector3(0.012, 0.07, 0.012) if metal else Vector3(0.022, 0.018, 0.02)
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = SPARK_COLOUR if metal else CHIP_COLOUR
	InkPass.stamp(paint, InkPass.Class.GOLD if metal else InkPass.Class.BARE)
	fleck.material = paint
	burst.draw_pass_1 = fleck
	burst.position = point
	into.add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
	return burst
