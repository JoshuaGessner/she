shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;
// Ink class 1 (ADR-269): an enemy or a thing worth taking — full weight, any distance, lit or not.
// The stencil value is the only thing this file says; InkPass.CLASSES owns
// what the class draws and ink.gdshaderinc owns how.
stencil_mode read, compare_equal, 1;

#include "res://art/shaders/ink.gdshaderinc"
