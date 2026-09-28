shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// The glint on treasure (ADR-267, ART-005): an inked four-point star that
// catches now and then, the way a woodcut draws a thing that shines.
//
// Why a star and not a flicker of the glimmer light: the light's energy *is*
// what the find is worth (ADR-204) and `--prize-probe` holds it to that number
// exactly, so a light that pulsed would lie about the price between samples.
// The star says "gold" and nothing about how much.
//
// Stepped at the ink pass's boil rate rather than smooth, so it catches on the
// same clock the lines redraw on and reads as drawn rather than as a sprite.

uniform vec4 colour : source_color = vec4(0.95, 0.78, 0.36, 1.0);
// Seconds between catches, and how much of that the star is showing ⟨tune⟩.
uniform float period = 2.6;
uniform float showing : hint_range(0.02, 1.0) = 0.22;
// Per-item offset so a floor of coin does not twinkle in unison.
uniform float phase = 0.0;
uniform float boil_fps = 10.0;

varying float catch;

void vertex() {
	// Face the camera, keep the quad's own scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	float t = floor(TIME * boil_fps) / boil_fps;
	float cycle = fract(t / period + phase);
	// A catch is a swell and a fall inside `showing` of the cycle, else dark.
	catch = cycle < showing ? sin(cycle / showing * PI) : 0.0;
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	// Four thin rays: the star narrows sharply away from each axis.
	float ray_x = max(0.0, 1.0 - abs(p.x)) * max(0.0, 1.0 - abs(p.y) * 14.0);
	float ray_y = max(0.0, 1.0 - abs(p.y)) * max(0.0, 1.0 - abs(p.x) * 14.0);
	float core = max(0.0, 1.0 - length(p) * 4.0);
	float star = clamp(max(max(ray_x, ray_y) * catch, core * catch), 0.0, 1.0);
	// Longer rays at the height of the catch, so it opens rather than fades.
	star *= step(length(p), 0.35 + 0.65 * catch);
	ALBEDO = colour.rgb;
	ALPHA = star * colour.a;
}
