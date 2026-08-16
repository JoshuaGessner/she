class_name InkPass
extends MeshInstance3D

## The ink outline pass, as a component any camera can carry (ART-005 §1–2).
##
## Promoted out of the `M1-T09` spike after ADR-070 passed the gate at
## ≈0.4–0.6 ms per frame at 1080p. The spike measured it; this renders it in
## the actual game. There is exactly one copy of the shader and one copy of
## this setup — the spike scene uses this component too, because a spike-local
## duplicate would be the parallel path ADR-064 bans, and the two would drift
## apart the first time either was tuned.
##
## **What this is not.** Hatching, the paper/ink two-world inversion, and the
## vertex-colour ink-ID channel are all ART-005 material and all absent, not
## approximated — they are `M4-T08`. This is steps 1 and 2 only: screen-space
## edge detection over depth and normals, plus the hand-drawn treatment.
##
## Add it as a child of the camera. It draws a full-screen quad in clip space,
## so it needs no positioning and must never be frustum-culled.

const SHADER_PATH: String = "res://art/shaders/ink_outline.gdshader"

## ART-005: "Update that jitter at 8-12 fps, not 60. This is *the* trick."
const BOIL_FPS: float = 10.0
const WOBBLE_AMOUNT: float = 1.1
const WEIGHT_VARIATION: float = 0.55

var material: ShaderMaterial


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	mesh = quad
	# The quad lives in clip space, so its real-world AABB is meaningless and
	# the culler would otherwise throw it away the moment the camera turned.
	custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.03
	var noise_texture := NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.seamless = true
	noise_texture.width = 256
	noise_texture.height = 256

	material = ShaderMaterial.new()
	material.shader = load(SHADER_PATH) as Shader
	material.set_shader_parameter("noise_tex", noise_texture)
	# Drawn after everything else, since it reads the finished colour buffer.
	material.render_priority = 100
	material_override = material

	set_boil(true)


## Toggle the hand-drawn treatment without unloading the pass, so a clean Sobel
## can be compared against the boiled version in place. One implementation with
## its parameters zeroed — not a second code path.
func set_boil(on: bool) -> void:
	material.set_shader_parameter("wobble_amount", WOBBLE_AMOUNT if on else 0.0)
	material.set_shader_parameter("weight_variation", WEIGHT_VARIATION if on else 0.0)
	material.set_shader_parameter("boil_fps", BOIL_FPS if on else 0.0)
