shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;

// M1-T09 — the ink shader spike. ART-005 §"Technical approach", steps 1 and 2
// ONLY: screen-space outlines, and the hand-drawn treatment. No hatching, no
// two-world inversion — those are separable later additions (ADR-062), and
// building them now would prejudge a gate that has not been passed.
//
// Screen-space edge detection over depth + normals, not inverted hull, because
// inverted hull cannot produce *interior* creases — and interior creases are
// what make a drawing read as drawn rather than as an object with a border.
//
// The boil is the point. A clean Sobel looks like a technical drawing; hand
// drawing shimmers because every frame was redrawn by a hand that could not
// repeat itself. Quantising the wobble clock to 8-12 fps reproduces that, and
// it is the cheapest, highest-impact line in ART-005.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
// Forward+ only, deliberately (ADR-052). Not expected to land for Mobile.
uniform sampler2D normal_tex : hint_normal_roughness_texture, repeat_disable, filter_nearest;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

uniform float line_width : hint_range(0.5, 6.0) = 1.15;
uniform float depth_threshold : hint_range(0.005, 0.5) = 0.06;
uniform float normal_threshold : hint_range(0.05, 2.0) = 0.7;

// The hand-drawn treatment (ART-005 step 2). Wobble is in pixels and wants to
// stay near 1: a stroke that wanders further than its own width stops reading
// as a drawn line and starts reading as a smudge.
uniform float wobble_amount : hint_range(0.0, 12.0) = 1.1;
uniform float wobble_scale : hint_range(0.5, 20.0) = 4.0;
uniform float boil_fps : hint_range(0.0, 60.0) = 10.0;
uniform float weight_variation : hint_range(0.0, 1.0) = 0.55;

// Legibility controls ART-005 makes mandatory: distant geometry must lose its
// lines rather than degenerate into scribble.
uniform float falloff_start : hint_range(1.0, 60.0) = 14.0;
uniform float falloff_end : hint_range(2.0, 120.0) = 34.0;

uniform vec3 ink_color : source_color = vec3(0.05, 0.045, 0.055);
uniform vec3 paper_color : source_color = vec3(0.93, 0.915, 0.87);
uniform float paper_mix : hint_range(0.0, 1.0) = 0.0;
uniform float grain : hint_range(0.0, 0.4) = 0.05;

// Set by the capture harness so boil is paced by frame index rather than by
// wall clock — otherwise a slow render makes the boil look wrong in a recording
// while looking correct live, which would corrupt the very thing being judged.
uniform float manual_time = -1.0;


void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


float hash11(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}


vec3 view_position(vec2 uv, mat4 inv_proj) {
	float raw = texture(depth_tex, uv).x;
	vec4 view = inv_proj * vec4(vec3(uv * 2.0 - 1.0, raw), 1.0);
	return view.xyz / view.w;
}


float view_depth(vec2 uv, mat4 inv_proj) {
	return -view_position(uv, inv_proj).z;
}


vec3 view_normal(vec2 uv) {
	return normalize(texture(normal_tex, uv).xyz * 2.0 - 1.0);
}


void fragment() {
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	float t = manual_time >= 0.0 ? manual_time : TIME;

	// Boil: hold the jitter for a whole 1/boil_fps beat, then jump. Setting
	// boil_fps to 0 disables the hold and gives the sterile 60 fps shimmer,
	// which is exactly the comparison the gate needs to be able to see.
	float beat = boil_fps > 0.0 ? floor(t * boil_fps) : t * 60.0;
	vec2 boil = vec2(hash11(beat), hash11(beat + 37.0)) * 32.0;

	vec2 wob = texture(noise_tex, SCREEN_UV * wobble_scale + boil).rg * 2.0 - 1.0;
	vec2 uv = SCREEN_UV + wob * wobble_amount * texel;

	// Variable weight — strokes thicken and thin like a nib, driven off a
	// different noise channel so weight and wobble are not visibly correlated.
	float nib = texture(noise_tex, SCREEN_UV * wobble_scale * 0.45 + boil * 0.7).b;
	float width = line_width * mix(1.0, nib * 1.7 + 0.35, weight_variation);
	vec2 o = texel * width;

	// Roberts cross: two diagonal differences. Cheaper than Sobel (4 taps per
	// buffer instead of 8) and the diagonal bias reads closer to a drawn stroke.
	float da = view_depth(uv + vec2(-o.x, -o.y), INV_PROJECTION_MATRIX);
	float db = view_depth(uv + vec2(o.x, o.y), INV_PROJECTION_MATRIX);
	float dc = view_depth(uv + vec2(-o.x, o.y), INV_PROJECTION_MATRIX);
	float dd = view_depth(uv + vec2(o.x, -o.y), INV_PROJECTION_MATRIX);

	vec3 centre_pos = view_position(SCREEN_UV, INV_PROJECTION_MATRIX);
	float centre = -centre_pos.z;
	vec3 centre_normal = view_normal(SCREEN_UV);

	// The tolerance has to follow the *surface*, not just the distance. On a
	// floor seen at a grazing angle, depth changes enormously from pixel to
	// pixel while the surface is perfectly flat — a fixed threshold paints the
	// entire floor as edge. Widening the tolerance as the surface turns away
	// (small N·V) is what separates a real discontinuity from foreshortening.
	vec3 to_eye = normalize(-centre_pos);
	float facing = max(abs(dot(centre_normal, to_eye)), 0.06);
	float tolerance = depth_threshold * centre / facing;

	float depth_edge = smoothstep(
		tolerance * 0.35, tolerance, length(vec2(da - db, dc - dd))
	);

	vec3 na = view_normal(uv + vec2(-o.x, -o.y));
	vec3 nb = view_normal(uv + vec2(o.x, o.y));
	vec3 nc = view_normal(uv + vec2(-o.x, o.y));
	vec3 nd = view_normal(uv + vec2(o.x, -o.y));
	float normal_delta = length(na - nb) + length(nc - nd);
	float normal_edge = smoothstep(normal_threshold * 0.4, normal_threshold, normal_delta);

	float edge = max(depth_edge, normal_edge);

	// ART-005: "distant geometry loses its outlines rather than becoming a
	// scribble." Non-negotiable — Principle 6, legibility beats realism.
	edge *= 1.0 - smoothstep(falloff_start, falloff_end, centre);

	vec3 base = texture(screen_tex, SCREEN_UV).rgb;
	vec3 ground = mix(base, paper_color, paper_mix);
	vec3 col = mix(ground, ink_color, clamp(edge, 0.0, 1.0));

	// Paper grain. Screen-space on purpose (ART-005's layer table): the page
	// genuinely is fixed in front of you, so it is the one layer that should
	// sacrifice motion coherence.
	col *= 1.0 - grain * (texture(noise_tex, SCREEN_UV * 7.0).r - 0.5);

	ALBEDO = col;
}
