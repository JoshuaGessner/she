#!/usr/bin/env python3
"""Build a barrow's capstone (B129): the stone a barrow's find lies under.

The capstone was a box with a box laid on it for a cut line — a paving slab
over a hole. Grave covers in the Norse world were dressed and carved: the
Gotland picture stones and the Danish hogback-like covers carry a border band
and a beast running down their length. This is one in the kit's grammar
(`build_dressing.py`): hand-dressed outline (no two edges straight), a
chamfered rim, a sunken panel, and a serpent raised along the panel, its head
at one end — low enough to step over, as the old slab was.

Base-centre origin, X across (0.9 m), Y along (1.6 m), Z up (0.14 m), flat
`stone` family with the `ink` attribute, one mesh, so `Barrow` can tint the
one surface for sealed and spent. Run with:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python \
    source_art/dressing/build_barrow.py
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
WIDE, LONG, HIGH = 0.9, 1.6, 0.14


def _outline(scale, wobble, seed):
    """A hand-dressed rectangle: rounded corners, every edge a little off true."""
    pts = []
    corners = 4
    per = 6
    for c in range(corners):
        cx = (1 if c in (0, 3) else -1) * WIDE * 0.5 * scale
        cy = (1 if c in (0, 1) else -1) * LONG * 0.5 * scale
        start = math.pi * 0.5 * c
        for k in range(per):
            a = start + math.pi * 0.5 * k / (per - 1)
            r = 0.09 * scale
            x = cx - math.copysign(r, cx) + r * math.cos(a)
            y = cy - math.copysign(r, cy) + r * math.sin(a)
            n = 1.0 + wobble * math.sin(seed + 3.1 * c + 1.7 * k)
            pts.append((x * n, y * n))
    return pts


def capstone():
    # Three rings: the foot (full outline at the ground), the shoulder (where
    # the chamfer starts), the top (inset), then the panel's lip and floor.
    foot = _outline(1.0, 0.012, 0.3)
    shoulder = _outline(0.985, 0.012, 0.3)
    top = _outline(0.94, 0.010, 0.9)
    lip = _outline(0.78, 0.006, 1.4)
    floor = _outline(0.77, 0.006, 1.4)
    rings = [(foot, 0.0), (shoulder, HIGH * 0.72), (top, HIGH), (lip, HIGH), (floor, HIGH - 0.018)]
    n = len(foot)
    verts = [(x, y, z) for ring, z in rings for x, y in ring]
    faces = []
    for j in range(len(rings) - 1):
        for i in range(n):
            k = (i + 1) % n
            faces.append((j * n + i, j * n + k, (j + 1) * n + k, (j + 1) * n + i))
    faces.append(tuple(range((len(rings) - 1) * n, len(rings) * n)))
    faces.append(tuple(reversed(range(n))))
    kit.mesh_object("capstone_body", verts, faces, "stone")
    # The serpent, raised down the panel: a body in S-curves, thinning to the
    # tail, and a head at the far end with a jaw.
    panel = HIGH - 0.018
    body = []
    for s in range(22):
        t = s / 21.0
        y = -LONG * 0.30 + LONG * 0.56 * t
        x = 0.19 * math.sin(t * math.tau * 1.25) * (0.35 + 0.65 * t)
        body.append((x, y, panel + 0.008))
    kit.tube("serpent", body, 0.052, "stone", sides=7, taper=True)
    tail = Vector(body[0])
    kit.tube("serpent_tail", [tuple(tail), tuple(tail + Vector((0.04, -0.07, -0.002))),
                              tuple(tail + Vector((0.10, -0.09, -0.004)))], 0.026, "stone", sides=5)
    head = Vector(body[-1]) + Vector((0.0, 0.07, 0.0))
    kit.cube("serpent_head", tuple(head + Vector((0.0, 0.0, 0.004))), (0.17, 0.15, 0.06), "stone", 0.015)
    kit.cube("serpent_jaw", tuple(head + Vector((0.0, 0.08, -0.004))), (0.11, 0.08, 0.04), "stone", 0.01)
    for side in (-1, 1):
        kit.cube(f"serpent_eye_{side}", tuple(head + Vector((side * 0.055, 0.02, 0.036))),
                 (0.022, 0.03, 0.012), "stone", 0.0)
    # One mesh, so the barrow tints one surface.
    bpy.ops.object.select_all(action="DESELECT")
    parts = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    bpy.context.object.name = "capstone"
    bpy.context.object.data.name = "capstone"
    kit.apply_mesh_transform(bpy.context.object)
    # Its true solid (`ART-004`): the stone below step height. Low enough to
    # step over is the capstone's whole brief, and a body climbs 0.10 m, so
    # the solid stands 0.08 and the carving above it is look only.
    kit.collision_box((-WIDE * 0.48, WIDE * 0.48, -LONG * 0.48, LONG * 0.48, 0.0, 0.08))


def main():
    bpy.context.preferences.filepaths.save_version = 0
    kit.clear_scene()
    capstone()
    bpy.context.view_layer.update()
    stats = kit.mesh_stats()
    assert stats["triangles"] <= 3000, stats
    kit.export_asset("barrow_capstone")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "barrow_capstone.blend"))
    kit.render_asset_review("barrow_capstone", stats)
    (SRC / "barrow_measurements.json").write_text(
        json.dumps([{"name": "barrow_capstone", **stats}], indent=2) + "\n")
    print("BARROW_DELIVERED", json.dumps(stats))


if __name__ == "__main__":
    main()
