shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;
// Ink class 4 (ADR-269): gold that is not loot — the hoard, her fire — kept its own colour.
// The stencil value is the only thing this file says; InkPass.CLASSES owns
// what the class draws and ink.gdshaderinc owns how.
stencil_mode read, compare_equal, 4;

#include "res://art/shaders/ink.gdshaderinc"
