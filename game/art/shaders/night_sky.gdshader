shader_type sky;
// **The camp is under a sky** (ADR-286). It is the one place in the game that is
// outdoors (`M4-T12` gives it no reverb tail for that reason), and above its
// walls was a flat grey colour. A night: deep blue going black overhead, a
// field of small fixed stars, and a pale glow low on one side where the moon
// is behind the rock. Fixed in direction, so nothing in it moves.

uniform vec3 zenith : source_color = vec3(0.012, 0.016, 0.03);
uniform vec3 horizon : source_color = vec3(0.06, 0.07, 0.11);
uniform vec3 moon_glow : source_color = vec3(0.2, 0.22, 0.28);
uniform vec3 moon_toward = vec3(-0.5, 0.35, -0.8);
uniform float star_density : hint_range(0.0, 1.0) = 0.012;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = clamp(dir.y, 0.0, 1.0);
	vec3 colour = mix(horizon, zenith, pow(up, 0.6));
	float moon = max(dot(dir, normalize(moon_toward)), 0.0);
	colour += moon_glow * pow(moon, 8.0) * 0.8;
	vec3 cell = floor(dir * 520.0);
	float star = step(1.0 - star_density, hash(cell));
	float twinkle = 0.55 + 0.45 * hash(cell + vec3(3.0));
	colour += vec3(0.75, 0.78, 0.86) * star * twinkle * smoothstep(0.08, 0.35, up);
	COLOR = colour;
}
