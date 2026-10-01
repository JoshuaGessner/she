shader_type spatial;
// **Stone that has been somewhere** (ADR-285). Every kit surface was one flat
// albedo, so a wall of two hundred blocks read as one grey sheet and the eye had
// nothing to hold. This keeps the authored colour and varies it in world space,
// where nothing swims as the view moves (ADR-281's lesson):
//
// - a fine mottle, so no face is one flat value (smooth, never cells: a hard
//   cell on the world grid cut across the kit's bricks and read as a fault);
// - a slow stain wanders across a wall, warmer in one place, cooler in another;
// - the foot of every wall is darker and damper, where water stands and boots
//   have been — the grime line that tells a floor from a wall at a glance;
// - and in the dampest low places, a trace of green.
//
// All of it multiplies the authored albedo, so a band's colour (ADR-246) is
// still the band's colour, and the ink pass reads the tone it always read.
render_mode diffuse_lambert, specular_disabled;

uniform vec3 albedo : source_color = vec3(0.5);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
uniform float mottle : hint_range(0.0, 0.5) = 0.12;
uniform float stain : hint_range(0.0, 0.5) = 0.2;
uniform float grime : hint_range(0.0, 0.8) = 0.32;
uniform float grime_high : hint_range(0.1, 3.0) = 0.9;
uniform float moss : hint_range(0.0, 0.6) = 0.18;

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
	float fine = (noise3(world_pos * 2.4) - 0.5) * 2.0 * mottle;
	float wander = noise3(world_pos * 0.35);
	float second = noise3(world_pos * 0.9 + vec3(13.0));
	vec3 tint = mix(vec3(1.04, 0.99, 0.93), vec3(0.94, 0.98, 1.04), wander);
	vec3 colour = albedo * (1.0 + fine) * mix(vec3(1.0), tint, 0.6)
		* (1.0 - stain * (second - 0.5));
	// The grime line, measured from the ground the kit lays rooms on (y = 0).

	// A raised deck keeps its walls clean: a repeating band would put a dark
	// stripe four metres up every tall wall, which read as a fault.
	float above = max(world_pos.y, 0.0);
	float upright = 1.0 - abs(world_normal.y);
	float foot = (1.0 - smoothstep(0.0, grime_high, above)) * upright;
	colour *= 1.0 - grime * foot * (0.7 + 0.6 * second);
	float damp = foot * smoothstep(0.55, 0.8, noise3(world_pos * 0.6 + vec3(7.0)));
	colour = mix(colour, colour * vec3(0.78, 0.92, 0.7), moss * damp * 2.0);
	ALBEDO = colour;
	ROUGHNESS = roughness;
}
