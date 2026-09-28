shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, fog_disabled;
// A threat's ink class (ADR-269). Worn as an overlay by an enemy or a thing
// worth taking, it redraws the surface adding black — no colour at all — so
// the only thing it leaves behind is a 1 in the stencil buffer, which is how
// the full-screen ink pass learns what it is looking at. Depth-tested as any
// overlay is, so the part of a body behind a wall is not marked.
stencil_mode write, compare_always, 1;

void fragment() {
	ALBEDO = vec3(0.0);
}
