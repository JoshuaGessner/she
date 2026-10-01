shader_type spatial;
// **Cloth in the wind** (ADR-287): a banner or a tent's flap, held along its
// top edge and moving more the further it hangs. Opaque, because the ink pass
// paints over anything transparent (ADR-283), and two-sided, because cloth has
// no inside.
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform vec3 dye : source_color = vec3(0.45, 0.30, 0.18);
uniform float wind = 1.0;
uniform float seed = 0.0;

void vertex() {
	float hang = 1.0 - UV.y;
	float t = TIME * 1.6 + seed * 7.0;
	float ripple = sin(t + VERTEX.x * 3.0 + VERTEX.y * 2.0) * 0.6
		+ sin(t * 2.3 + VERTEX.x * 5.0) * 0.4;
	VERTEX.z += ripple * 0.06 * wind * (1.0 - hang);
}

void fragment() {
	// A darker hem and a little weave, so it reads as cloth up close.
	float hem = smoothstep(0.92, 1.0, UV.y) + smoothstep(0.08, 0.0, UV.y);
	float weave = 0.94 + 0.06 * sin(UV.x * 180.0) * sin(UV.y * 180.0);
	ALBEDO = dye * weave * (1.0 - 0.3 * hem);
	ROUGHNESS = 1.0;
}
