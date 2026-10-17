#!/usr/bin/env python3
"""Build the Shaft's head (B132): the timber over the way out.

The Shaft — the floor's way out, where a body stands and is drawn up — was a
pale disc under a column of light: it said *here*, never *what*. A mine's way
up is a windlass over a hole, and Agricola's woodcuts in *De Re Metallica*
(1556, book VI) draw exactly that: two A-frames standing either side of the
mouth, a drum across them turned by cranks, a rope and a kibble hanging into
the dark. The woodcut is this game's own register, so it is drawn from them.

Everything stands outside the disc (radius 1.6 m) or above head height, so the
place a body stands to be drawn up is unchanged. Its solids are the four legs,
authored for `ART-004`; the level places it look-only, as it does the mine
set, so it can never close a route on a floor the generator laid.
  /Applications/Blender.app/Contents/MacOS/Blender --background --python \
    source_art/dressing/build_shaft_head.py
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_dressing as kit  # noqa: E402

SRC = Path(__file__).resolve().parent
kit.PALETTE["bark"] = ((0.11, 0.075, 0.05, 1.0), kit.PALETTE["timber"][1])

LEG_X = 1.95      # the A-frames, outside the disc
SPLAY = 0.95      # how far each leg's foot stands from the frame's middle
APEX = 3.55       # where the legs meet
DRUM_Z = 3.25     # the drum's axis
DRUM_R = 0.17


def headframe():
    for side in (-1, 1):
        x = side * LEG_X
        apex = Vector((x, 0.0, APEX))
        for foot_y in (-SPLAY, SPLAY):
            kit.beam_between(f"leg_{side}_{foot_y:+.0f}", (x, foot_y, 0.0), tuple(apex), 0.17, 0.17, "bark")
        # A tie across each frame, and a short cap over the apex.
        tie = 1.3
        half = SPLAY * (1.0 - tie / APEX)
        kit.beam_between(f"tie_{side}", (x, -half - 0.08, tie), (x, half + 0.08, tie), 0.12, 0.12, "bark")
        kit.cube(f"cap_{side}", (x, 0.0, APEX + 0.06), (0.26, 0.34, 0.12), "bark", 0.01)
        # A footing stone under each leg.
        for foot_y in (-SPLAY, SPLAY):
            kit.irregular_rock(f"footing_{side}_{foot_y:+.0f}", (x, foot_y, 0.0), (0.42, 0.38, 0.14))
    # The drum across the frames, with the rope wound on it.
    kit.cylinder("drum", (0.0, 0.0, DRUM_Z), DRUM_R, LEG_X * 2.0 - 0.1, "timber", vertices=12,
                 rotation=(0.0, math.pi * 0.5, 0.0))
    for i in range(7):
        kit.torus(f"wound_{i}", (0.18 + 0.07 * i, 0.0, DRUM_Z), DRUM_R + 0.012, 0.016, "rope", 12, 4,
                  rotation=(0.0, math.pi * 0.5, 0.0))
    # The cranks: an arm and a handle beyond each frame.
    for side in (-1, 1):
        x = side * (LEG_X + 0.16)
        kit.beam_between(f"crank_arm_{side}", (x, 0.0, DRUM_Z), (x, 0.0, DRUM_Z - 0.48), 0.07, 0.07, "metal")
        kit.beam_between(f"crank_grip_{side}", (x, 0.0, DRUM_Z - 0.48), (x + side * 0.32, 0.0, DRUM_Z - 0.48),
                         0.06, 0.06, "timber")
    # The rope down from the drum to a kibble above head height.
    rope_x = 0.42
    top = Vector((rope_x, -DRUM_R * 0.9, DRUM_Z - 0.05))
    bottom = Vector((rope_x, -0.05, 2.45))
    kit.tube("rope", [tuple(top), tuple(top.lerp(bottom, 0.5) + Vector((0.0, 0.02, 0.0))), tuple(bottom)],
             0.022, "rope", sides=6)
    kit.lathe("kibble", [(0.0, 0.0), (0.2, 0.0), (0.24, 0.32), (0.26, 0.36), (0.0, 0.36)],
              "timber", loc=(rope_x, -0.05, 2.06), segments=10)
    for z in (2.12, 2.36):
        kit.torus(f"kibble_band_{z}", (rope_x, -0.05, z), 0.23 + (z - 2.06) * 0.08, 0.014, "metal", 12, 4)
    kit.torus("kibble_bail", (rope_x, -0.05, 2.45), 0.2, 0.012, "metal", 12, 4,
              rotation=(math.pi * 0.5, 0.0, 0.0))
    # The collar: flat stones set flush round the mouth, outside the disc.
    for i in range(14):
        a = math.tau * i / 14 + 0.1
        r = 1.82 + 0.05 * math.sin(i * 2.3)
        slab = kit.cube(f"collar_{i}", (math.cos(a) * r, math.sin(a) * r, 0.03),
                        (0.42, 0.62 + 0.08 * math.cos(i * 1.7), 0.06), "stone", 0.012)
        slab.rotation_euler = (0.0, 0.0, a)
        kit.apply_mesh_transform(slab)
    # One mesh per family, so it costs a handful of draws.
    families = {}
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH":
            families.setdefault(obj.data.materials[0].name.removeprefix("flat_"), []).append(obj)
    for kind, parts in families.items():
        bpy.ops.object.select_all(action="DESELECT")
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        if len(parts) > 1:
            bpy.ops.object.join()
        bpy.context.object.name = kind
        kit.apply_mesh_transform(bpy.context.object)
    # Its solids: the four legs' feet (ART-004). Placed look-only.
    for side in (-1, 1):
        for foot_y in (-SPLAY, SPLAY):
            solid = kit.cube(f"leg_{side}_{foot_y:+.0f}-colonly", (side * LEG_X, foot_y * 0.8, 0.9),
                             (0.2, 0.2, 1.8), "bark", 0.0, 0.0)
            solid.hide_render = True
            solid.display_type = "WIRE"


def main():
    bpy.context.preferences.filepaths.save_version = 0
    kit.clear_scene()
    headframe()
    bpy.context.view_layer.update()
    stats = kit.mesh_stats()
    assert stats["triangles"] <= 3000, stats
    kit.export_asset("shaft_head")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "shaft_head.blend"))
    kit.render_asset_review("shaft_head", stats)
    (SRC / "shaft_head_measurements.json").write_text(
        json.dumps([{"name": "shaft_head", **stats}], indent=2) + "\n")
    print("SHAFT_DELIVERED", json.dumps(stats))


if __name__ == "__main__":
    main()
