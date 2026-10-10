shader_type spatial;
// **The camp's ground** (ADR-393): packed earth (ADR-287) — the mottle and stain
// `weathered.gdshader` gives any flat floor — and the ring round the fire that
// the party's feet have worn to dust and ash.
//
// **Quieter than what stands on it.** On the Deep page lit stone gives up its
// value to pale strokes, and the earth was light enough that every brazier's
// pool on it became the busiest pattern in the camp. The earth is darker, so a
// brazier lights its plot and not a patch of floor, and the one light place on
// the ground is the hearth, where the party gathers.
//
// A worn way down the axis was tried and cut: nothing lights the ground between
// the fire and the hole, so it never showed, and lamps along it would break the
// rule that light on safe ground means a station.
//
// In the ground's own material, because the ink pass composites the screen as
// the opaque pass left it: a transparent layer over the earth was never drawn.
render_mode diffuse_lambert, specular_disabled;

uniform vec3 albedo : source_color = vec3(0.21, 0.175, 0.135);
uniform float mottle : hint_range(0.0, 0.5) = 0.22;
uniform float stain : hint_range(0.0, 0.5) = 0.3;
// The hearth's worn ring: dust at its rim, ash toward the fire.
uniform vec3 worn : source_color = vec3(0.42, 0.36, 0.28);
uniform vec3 ash : source_color = vec3(0.38, 0.355, 0.33);
// The fire, world xz, and the ring's radius in metres.
uniform vec2 fire = vec2(0.0);
uniform float ring = 4.2;
// How soft the ring's edge is and how far it wanders, metres, and how worn.
uniform float soft = 0.7;
uniform float wander = 0.6;
uniform float strength : hint_range(0.0, 1.0) = 0.85;

varying vec3 world_pos;

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
}

void fragment() {
	// The earth, as `weathered.gdshader` draws a floor.
	float fine = (noise3(world_pos * 2.4) - 0.5) * 2.0 * mottle;
	float drift = noise3(world_pos * 0.35);
	float second = noise3(world_pos * 0.9 + vec3(13.0));
	vec3 tint = mix(vec3(1.04, 0.99, 0.93), vec3(0.94, 0.98, 1.04), drift);
	vec3 earth = albedo * (1.0 + fine) * mix(vec3(1.0), tint, 0.6)
		* (1.0 - stain * (second - 0.5));
	// The ring, its edge wandering at two scales so it reads as feet, not paint.
	vec2 at = world_pos.xz;
	float from_fire = length(at - fire);
	float outside = from_fire - ring
		+ (noise3(vec3(at * 0.45, 3.0)) - 0.5) * 2.0 * wander
		+ (noise3(vec3(at * 1.9, 5.0)) - 0.5) * 0.5 * wander;
	float cover = (1.0 - smoothstep(-soft, soft, outside)) * strength;
	// Packed smoother than the earth round it: half its mottle, and grit.
	vec3 packed = mix(worn, ash, smoothstep(ring + 0.5, ring - 1.5, from_fire))
		* (1.0 + fine * 0.5) * (0.94 + 0.12 * noise3(world_pos * 3.1));
	ALBEDO = mix(earth, packed, cover);
	ROUGHNESS = 1.0;
}
