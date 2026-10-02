shader_type spatial;
// **The camp is dug into a hillside** (ADR-287). Its walls were the Delvings'
// dressed brick — the inside of a mine, nine metres high, under an open sky. A
// camp outdoors is held by rock: bedding planes running across, cracks down
// them, a darker foot where the ground meets it, and lichen where it is damp.
// World-space and smooth, like `weathered.gdshader`, so nothing swims.
render_mode diffuse_lambert, specular_disabled;

uniform vec3 rock : source_color = vec3(0.30, 0.28, 0.26);
uniform vec3 bed : source_color = vec3(0.24, 0.22, 0.21);
uniform vec3 lichen : source_color = vec3(0.32, 0.34, 0.24);

varying vec3 world_pos;
varying vec3 world_normal;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x),
			mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x),
			mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	// Gently bent rather than wound: strongly warped bands read as wood grain
	// under the ink pass, and strata are nearly level (ADR-300).
	float warp = noise3(world_pos * 0.25) * 0.55 + noise3(world_pos * 1.3) * 0.12;
	// Bedding planes: bands across the face, bent by the warp so they are
	// strata rather than shelves.
	float layer = fract((world_pos.y + warp) * 0.42);
	float plane = smoothstep(0.0, 0.08, layer) * (1.0 - smoothstep(0.86, 1.0, layer));
	vec3 colour = mix(bed, rock, plane);
	colour *= 0.85 + 0.3 * noise3(world_pos * 2.2);
	// Cracks: thin dark seams where a ridge of noise crosses zero, running
	// mostly downward the way rock splits.
	float split = abs(noise3(world_pos * vec3(2.4, 0.18, 2.4)) - 0.5);
	colour *= mix(0.6, 1.0, smoothstep(0.0, 0.018, split));
	float foot = 1.0 - smoothstep(0.0, 1.4, world_pos.y);
	colour *= 1.0 - 0.3 * foot;
	float damp = smoothstep(0.6, 0.78, noise3(world_pos * 0.7 + vec3(5.0)))
		* (1.0 - smoothstep(2.0, 6.0, world_pos.y));
	colour = mix(colour, lichen, damp * 0.55);
	ALBEDO = colour;
	ROUGHNESS = 1.0;
}
