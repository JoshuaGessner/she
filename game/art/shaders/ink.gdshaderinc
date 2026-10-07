// ART-005: contours sit on the page; nested hatching belongs to the world.
// Reconstruct the visible surface from depth, so generated geometry and
// authored opaque assets receive the same printmaking treatment.
//
// Included by one shader per ink class (M4-T08, ADR-269). A full-screen pass
// cannot see which object drew a pixel, so each class is the same treatment
// run again behind a stencil test, and the only thing its own file says is
// which stencil value it answers to. Everything else is here, once.
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
// **Creases are not contours** (ADR-281). A normal break inside a surface — a
// brick seam, a flagstone joint, a bevel — is drawn this much as strongly as a
// silhouette, and only this near: every seam in a wall at full weight made the
// room a white grid, and at range the grid broke into dashes that flickered as
// the view moved. Silhouettes (depth breaks) keep the full line at any range
// the falloff below allows.
uniform float crease_weight : hint_range(0.0, 1.0) = 0.4;
uniform float crease_near : hint_range(0.5, 30.0) = 3.0;
uniform float crease_far : hint_range(1.0, 60.0) = 9.0;

// Legibility controls ART-005 makes mandatory: distant geometry must lose its
// lines rather than degenerate into scribble.
uniform float falloff_start : hint_range(1.0, 60.0) = 14.0;
uniform float falloff_end : hint_range(2.0, 120.0) = 34.0;

// What this class's contour is (ADR-269). A world surface draws at full
// weight, dissolves with distance and — in the Deep — only where there is
// light to draw it. A threat ignores all three: ART-005's "if the shader ever
// makes a threat harder to see, the shader is wrong". Set dressing is drawn
// faintly or not at all, from the R channel its modeller authored.
uniform float edge_weight : hint_range(0.0, 2.0) = 1.0;
uniform float edge_width : hint_range(0.5, 3.0) = 1.0;
uniform float edge_needs_light : hint_range(0.0, 1.0) = 1.0;
uniform float edge_fades : hint_range(0.0, 1.0) = 1.0;

// **The page** (ART-005 "Two worlds, two treatments"). 0 is the Deep — pale
// ink on black, drawn by your light; 1 is the Threshold and the Chamber — hard
// black ink on white, everywhere, a finished print. A hard cut, never a blend
// in play (ADR-167): the value is set once, by the level the camera is in.
uniform float page : hint_range(0.0, 1.0) = 0.0;

uniform vec3 ink_color : source_color = vec3(0.05, 0.045, 0.055);
uniform vec3 bone_color : source_color = vec3(0.86, 0.83, 0.76);
uniform vec3 paper_color : source_color = vec3(0.93, 0.915, 0.87);
uniform float grain : hint_range(0.0, 0.4) = 0.05;
// **Engraved, not screened** (ADR-339). Cuts per metre; how black a cut
// prints; and the hairline a cut starts from where the tone first asks for one.
uniform float hatch_scale : hint_range(1.0, 40.0) = 14.0;
uniform float hatch_strength : hint_range(0.0, 1.0) = 0.24;
uniform float hatch_width : hint_range(0.02, 0.45) = 0.16;
// A hand's cut: how far a line wanders off straight, as a fraction of the
// spacing, and how much it swells and thins along its length.
uniform float hatch_wave : hint_range(0.0, 1.0) = 0.09;
uniform float hatch_pressure : hint_range(0.0, 1.0) = 0.3;

// The Deep's fill. The stone keeps this much of its own value and the rest of
// what it reads as is pale strokes, laid densest where the light is strongest:
// a white-line engraving, where light is the thing that is cut.
uniform float deep_keep : hint_range(0.0, 1.0) = 0.55;
uniform float deep_stroke : hint_range(0.0, 1.0) = 0.28;

// The print's fill: tone mapped onto the page between solid ink and bare
// paper, in display space so the two ends mean what they look like.
uniform float print_black : hint_range(0.0, 1.0) = 0.04;
uniform float print_white : hint_range(0.0, 1.0) = 0.3;
// How much of the light's own hue the paper takes. The Threshold is warm
// because the Lodge's fire is; paper that ignored it would be a colder room.
uniform float print_warmth : hint_range(0.0, 1.0) = 0.45;

// **Gold is the only colour** (ART-005). A pixel this saturated is treasure,
// an ember or her fire, and the page is never laid over it — on either page
// it stays exactly the colour it was lit. Chroma rather than saturation,
// because firelit stone is as saturated as gold and far less bright.
uniform float gold_chroma : hint_range(0.0, 1.0) = 0.4;
// A class that *is* gold keeps its colour outright: the hoard and her fire are
// declared rather than recognised, because in linear light the Chamber's
// hoard and the Threshold's firelit stone have the same chroma, and a guess
// that cannot tell them apart papers over one or leaves the other orange.
uniform float keep_colour : hint_range(0.0, 1.0) = 0.0;
// **Gilt, not plastic** (ADR-347). Gold kept its rendered colour outright, so
// the one colour in the picture was the one thing in it not drawn: a lit PBR
// surface in a woodcut, which read as yellow plastic on her pile. A
// chiaroscuro woodcut (Ugo da Carpi, Hans Burgkmair) prints colour as **flat
// tone blocks** under a key block of line — so gold here is two flat inks of
// its own hue, split where the light turns, with the engraver's cuts across
// the shade side and the paper left bare where the light peaks.
uniform float gilt_split : hint_range(0.0, 1.0) = 0.5;
uniform float gilt_leaf : hint_range(0.0, 1.5) = 1.0;
uniform float gilt_shade : hint_range(0.0, 1.0) = 0.62;
uniform float gilt_glint : hint_range(0.0, 1.0) = 0.86;

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


float luminance_of(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}


// **One engraved family** (ADR-339): parallel cuts whose *width* is the tone.
//
// The hatch this replaced was two families of fixed-width lines at ±45° on
// every surface, switched on by tone — so shadow read as a mechanical screen
// laid over the picture, the same on a dragon as on a floor. An engraver
// carries tone the other way: one family of lines that **swell** as the
// surface turns from the light and run together into solid black, cut along
// the form rather than across the page. Doré's wood engravings for the
// *Inferno*, Dürer's woodcuts, and the halftoning primitive of Freudenberg et
// al. (*Real-Time Halftoning*, 2002) all draw tone as line width; Praun et
// al.'s tonal art maps (*Real-Time Hatching*, 2001) give the rule that a darker
// tone must keep every stroke a lighter one had, which a widening line does by
// construction.
//
// `across` is the direction the cuts are stacked in. Each line wanders a
// little and its pressure changes along it — world-space noise, so a line
// stays the same line as you move.
float engrave(vec2 point, vec2 across, float tone) {
	vec2 along_dir = vec2(-across.y, across.x);
	float coordinate = dot(point, across) * hatch_scale;
	float along = dot(point, along_dir);
	coordinate += (texture(noise_tex, point * 0.23).r - 0.5) * 2.0 * hatch_wave;
	float pressure = mix(1.0,
		0.55 + 0.9 * texture(noise_tex, vec2(along * 0.12, coordinate * 0.011)).g,
		hatch_pressure);
	// From nothing: a cut tapers out into the light rather than starting at a
	// fixed hairline, which laid a faint mesh over every lit wall. Below
	// `hatch_width` it is not drawn at all — a burin lifts before it scratches.
	float half_width = clamp(tone * 0.55 * pressure, 0.0, 0.55);
	float footprint = max(fwidth(coordinate), 0.0001);
	float distance_to_line = abs(fract(coordinate) - 0.5);
	float cut = 1.0 - smoothstep(half_width - footprint, half_width + footprint, distance_to_line);
	cut *= smoothstep(hatch_width * 0.25, hatch_width * 0.5, half_width);
	// Past what the screen can resolve, a cut becomes the tone it was drawing,
	// not a shimmer (ADR-281) and not a sudden lightening.
	float resolve = smoothstep(0.16, 0.42, footprint);
	return mix(cut, clamp(half_width * 2.0, 0.0, 1.0), resolve);
}


// A surface's cuts: one family from the first tone, a second at sixty
// degrees only in the deepest part of it — the cross an engraver saves for
// night, never laid over the half-tones.
float engrave_plane(vec2 point, vec2 across, float amount) {
	float tone = smoothstep(0.1, 1.0, amount);
	float first = engrave(point, across, tone);
	vec2 crossed = vec2(across.x * 0.5 - across.y * 0.866, across.x * 0.866 + across.y * 0.5);
	float second = engrave(point + vec2(3.7, 1.3), crossed, smoothstep(0.8, 1.0, amount) * 0.6);
	return max(first, second);
}


// Walls are cut along their courses, floors and ceilings on one diagonal, as
// a hand would follow the form; blended by how much each plane faces you.
float engrave_world(vec3 world_pos, vec3 weights, float amount) {
	return dot(weights, vec3(
		engrave_plane(world_pos.yz, vec2(1.0, 0.12), amount),
		engrave_plane(world_pos.xz, vec2(0.7071, 0.7071), amount),
		engrave_plane(world_pos.xy, vec2(0.12, 1.0), amount)));
}


// The gilt print of a gold pixel: leaf or shade by where the light turns,
// cut toward ink on the shade side, and the paper's own white at the peak.
vec3 gilt(vec3 base, float luminance, vec3 world_pos, vec3 weights, float nearby) {
	float peak = max(base.r, max(base.g, max(base.b, 0.0001)));
	vec3 hue = base / peak;
	float v = sqrt(clamp(luminance, 0.0, 1.0));
	float lit_side = smoothstep(gilt_split - 0.04, gilt_split + 0.04, v);
	vec3 col = mix(hue * gilt_shade, hue * gilt_leaf, lit_side);
	float cuts = engrave_world(world_pos, weights, smoothstep(gilt_split, gilt_split * 0.2, v));
	col = mix(col, ink_color, cuts * nearby * 0.7);
	// A glint only lifts the leaf a little, never to white: her eyes are this
	// class too, and a pale eye is a different creature — the first draft
	// glinted them to cream.
	float glint = smoothstep(gilt_glint, gilt_glint + 0.05, v);
	return mix(col, mix(hue, vec3(1.0), 0.45), glint * 0.25);
}


void fragment() {
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	float t = manual_time >= 0.0 ? manual_time : TIME;

	// Boil: hold the jitter for a whole 1/boil_fps beat, then jump. Setting
	// boil_fps to 0 disables the hold and gives the sterile 60 fps shimmer,
	// which is exactly the comparison the gate needs to be able to see.
	// **Zero is still, not 60 fps** since ADR-281: the boil re-jittered every
	// line on screen ten times a second, and over a wall of seams that read as
	// the surface flashing. The wobble stays — it is a hand's line — but held.
	vec2 boil = boil_fps > 0.0
		? vec2(hash11(floor(t * boil_fps)), hash11(floor(t * boil_fps) + 37.0)) * 32.0
		: vec2(0.0);

	vec2 wob = texture(noise_tex, SCREEN_UV * wobble_scale + boil).rg * 2.0 - 1.0;
	vec2 uv = SCREEN_UV + wob * wobble_amount * texel;

	// Variable weight — strokes thicken and thin like a nib, driven off a
	// different noise channel so weight and wobble are not visibly correlated.
	float nib = texture(noise_tex, SCREEN_UV * wobble_scale * 0.45 + boil * 0.7).b;
	float width = line_width * edge_width * mix(1.0, nib * 1.7 + 0.35, weight_variation);
	vec2 o = texel * width;

	// Roberts cross: two diagonal differences. Cheaper than Sobel (4 taps per
	// buffer instead of 8) and the diagonal bias reads closer to a drawn stroke.
	vec2 ua = uv + vec2(-o.x, -o.y);
	vec2 ub = uv + vec2(o.x, o.y);
	vec2 uc = uv + vec2(-o.x, o.y);
	vec2 ud = uv + vec2(o.x, -o.y);
	float da = view_depth(ua, INV_PROJECTION_MATRIX);
	float db = view_depth(ub, INV_PROJECTION_MATRIX);
	float dc = view_depth(uc, INV_PROJECTION_MATRIX);
	float dd = view_depth(ud, INV_PROJECTION_MATRIX);

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
	// Scaled by the class's width as well: taps set further apart see more
	// of a curved or slanted surface's own change, and a class drawn wider
	// must get a thicker line, not a more nervous one — a threat's capsule
	// otherwise fills with its own curvature.
	float tolerance = depth_threshold * centre / facing * edge_width;

	float depth_edge = smoothstep(
		tolerance * 0.35, tolerance, length(vec2(da - db, dc - dd))
	);

	vec3 na = view_normal(ua);
	vec3 nb = view_normal(ub);
	vec3 nc = view_normal(uc);
	vec3 nd = view_normal(ud);
	float normal_delta = (length(na - nb) + length(nc - nd)) / edge_width;
	float normal_edge = smoothstep(normal_threshold * 0.4, normal_threshold, normal_delta);

	float crease = crease_weight * (1.0 - smoothstep(crease_near, crease_far, centre));
	float edge = max(depth_edge, normal_edge * crease) * edge_weight;

	// ART-005: "distant geometry loses its outlines rather than becoming a
	// scribble." Non-negotiable — Principle 6, legibility beats realism.
	float nearby = 1.0 - smoothstep(falloff_start, falloff_end, centre);
	edge *= mix(1.0, nearby, edge_fades);

	vec3 base = texture(screen_tex, SCREEN_UV).rgb;
	float luminance = luminance_of(base);
	// The drawing never creates light. It follows the existing illumination,
	// and retreats in the deepest dark and the fog.
	float lit = smoothstep(0.015, 0.08, luminance);
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(centre_pos, 1.0)).xyz;
	vec3 world_normal = normalize(mat3(INV_VIEW_MATRIX) * centre_normal);
	vec3 weights = pow(abs(world_normal), vec3(4.0));
	weights /= max(dot(weights, vec3(1.0)), 0.0001);

	float chroma = max(base.r, max(base.g, base.b)) - min(base.r, min(base.g, base.b));
	float gold = max(keep_colour, smoothstep(gold_chroma * 0.75, gold_chroma, chroma));

	vec3 col;
	if (page < 0.5) {
		// **The Deep: your lantern draws.** Darkness is the paper, so a line
		// is only put down where there is light to put it down with — the
		// brightest of the five samples, because a contour sits on the edge
		// of a lit thing and half of its taps are the dark beside it.
		float seen = max(luminance, max(
			max(luminance_of(texture(screen_tex, ua).rgb), luminance_of(texture(screen_tex, ub).rgb)),
			max(luminance_of(texture(screen_tex, uc).rgb), luminance_of(texture(screen_tex, ud).rgb))));
		edge *= mix(1.0, smoothstep(0.012, 0.06, seen), edge_needs_light);
		float drawn = sqrt(clamp(luminance, 0.0, 1.0));
		// A white-line engraving: the cut is the light, so it widens where
		// the light is strongest.
		// Fine in the dark: a lit floor at full light cut to half-width read as
		// broad pale bars, not lines. The light is drawn by more of them
		// thickening a little, never by any one becoming a stripe.
		float strokes = engrave_world(world_pos, weights, drawn * 0.5);
		// Only lit stone gives up value to the strokes. The unlit page is
		// left exactly as rendered, because ADR-203's fog is authored at
		// the ground colour and a pass that darkened it would put the
		// boundary back.
		vec3 ground = mix(base, base * deep_keep, lit);
		ground = mix(ground, bone_color * max(drawn, 0.35), strokes * deep_stroke * lit * nearby);
		ground = mix(ground, gilt(base, luminance, world_pos, weights, nearby), gold);
		col = mix(ground, bone_color, clamp(edge, 0.0, 1.0));
	} else {
		// **The print: a finished page.** Tone becomes paper and ink — bare
		// paper in the light, hatch through the middle, solid ink in the
		// deepest shadow, which is how a woodcut draws night.
		float tone = smoothstep(print_black, print_white, sqrt(clamp(luminance, 0.0, 1.0)));
		float peak = max(base.r, max(base.g, max(base.b, 0.0001)));
		vec3 hue = mix(vec3(1.0), base / peak, print_warmth);
		// Paper, washed by tone, and ink cut into the shadow side only. The
		// first pass cut every half-tone and striped lit walls and her whole
		// body alike — the form drowned in its own texture. An engraver leaves
		// the light bare: cuts begin past the middle of the shadow and widen
		// toward black, so the line says *this side is turned away* and the
		// wash under it still carries her carving.
		float shadow = 1.0 - tone;
		vec3 paper = paper_color * hue;
		vec3 ground = mix(paper, mix(ink_color, paper, tone), 0.75);
		float turned = smoothstep(0.38, 0.98, shadow);
		float cuts = engrave_world(world_pos, weights, turned);
		// At range the cuts give way to the flat tone they average to.
		float coverage = mix(turned * 0.4, cuts, nearby);
		ground = mix(ground, ink_color, clamp(coverage * hatch_strength, 0.0, 1.0));
		ground = mix(ground, gilt(base, luminance, world_pos, weights, nearby), gold);
		col = mix(ground, ink_color, clamp(edge, 0.0, 1.0));
	}

	// Paper grain. Screen-space on purpose (ART-005's layer table): the page
	// genuinely is fixed in front of you, so it is the one layer that should
	// sacrifice motion coherence.
	col *= 1.0 - grain * (texture(noise_tex, SCREEN_UV * 7.0).r - 0.5);

	ALBEDO = col;
}
