shader_type spatial;
// **A flame, cut out rather than blended** (ADR-283). The ink pass reads the
// opaque frame and paints over anything transparent, so a fire drawn additively
// vanished under it; an alpha-scissored tongue is opaque, and stencil class 4
// (gold, ADR-269) keeps its colour through the page.
render_mode unshaded, cull_disabled, shadows_disabled;
stencil_mode write, compare_always, 4;

uniform vec3 core : source_color = vec3(1.0, 0.86, 0.46);
uniform vec3 rim : source_color = vec3(0.94, 0.42, 0.12);
uniform float speed = 1.6;
uniform float seed = 0.0;

float wave(float x) {
	return sin(x) * 0.5 + 0.5;
}

void vertex() {
	// Turned to face the camera about the vertical only, so it stands up out
	// of the fire from every side without tipping when you look down at it.
	vec3 toward = normalize(vec3(INV_VIEW_MATRIX[3].x - MODEL_MATRIX[3].x, 0.0,
		INV_VIEW_MATRIX[3].z - MODEL_MATRIX[3].z));
	vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), toward));
	vec3 up = vec3(0.0, 1.0, 0.0);
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	vec3 world = MODEL_MATRIX[3].xyz + side * VERTEX.x * scale_x + up * VERTEX.y * scale_y;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

void fragment() {
	vec2 uv = UV;
	float h = 1.0 - uv.y;
	float t = TIME * speed + seed * 13.0;
	// A tongue that narrows as it rises and sways more at the tip.
	float sway = (wave(t * 2.3 + h * 5.0) - 0.5) * 0.22 * h
		+ (wave(t * 3.7 + h * 9.0 + 1.3) - 0.5) * 0.08 * h;
	float x = abs(uv.x - 0.5 - sway) * 2.0;
	float width = (1.0 - pow(h, 1.4)) * (0.82 + 0.18 * wave(t * 5.1 + h * 3.0));
	float body = width - x;
	// Licks: the top breaks into flickering fingers.
	float lick = wave(uv.x * 17.0 + t * 4.0) * wave(uv.x * 9.0 - t * 2.6);
	body -= smoothstep(0.55, 1.0, h) * lick * 0.35;
	if (body < 0.02) {
		discard;
	}
	float heat = clamp(body * 2.2 + (1.0 - h) * 0.4, 0.0, 1.0);
	ALBEDO = mix(rim, core, heat);
}
