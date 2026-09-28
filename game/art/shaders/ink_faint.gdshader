shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;
// Ink class 2 (ADR-269): set dressing its modeller gave a light line (0 < R < 0.5).
// The stencil value is the only thing this file says; InkPass.CLASSES owns
// what the class draws and ink.gdshaderinc owns how.
stencil_mode read, compare_equal, 2;

#include "res://art/shaders/ink.gdshaderinc"
