#!/usr/bin/env python3
"""Build the camp's own pieces (ADR-299): the hearth and the logs drawn up to it.

The camp's fire was nine boxes, four plain cylinders and two cards of flame —
the last of the camp built in code, in the one room every life walks through.
These are authored the way the Delvings dressing is (`build_dressing.py`, whose
helpers this reuses): base-centre origin, flat material families, hard edges,
and the `ink` vertex attribute, so `art_probe.gd` holds them to `ART-004` with
everything else. Run with:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python \
    source_art/dressing/build_camp.py
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_dressing as kit  # noqa: E402

# The camp burns live wood, not the Delvings' weathered grey: dark bark on the
# timber family's material identifier, so it is still timber to the ink pass.
kit.PALETTE["bark"] = ((0.11, 0.075, 0.05, 1.0), kit.PALETTE["timber"][1])

SRC = Path(__file__).resolve().parent


def fieldstone(name, at, size, turn, seed):
    """A rounded fieldstone with a flat underside — river stone, not quarry
    block — faceted enough for the ink pass to find edges on."""
    # Full shoulders and a broad, slightly tilted top rather than a peak.
    lats = (0.0, 0.35, 0.75, 1.1, 1.32)
    around = 9
    verts, faces = [], []
    for lat in lats:
        for i in range(around):
            lon = math.tau * i / around
            # A fixed lumpiness per stone: the seed varies it, nothing random.
            bump = 1.0 + 0.08 * math.sin(lon * 3 + seed)
            r = math.cos(lat) ** 0.45 * bump
            tilt = 0.12 * math.cos(lon - seed) * math.sin(lat)
            verts.append((size[0] * 0.5 * r * math.cos(lon),
                          size[1] * 0.5 * r * math.sin(lon),
                          size[2] * (math.sin(lat) / math.sin(lats[-1]) + tilt)))
    rows = len(lats) - 1
    for j in range(rows):
        for i in range(around):
            k = (i + 1) % around
            faces.append((j * around + i, j * around + k, (j + 1) * around + k, (j + 1) * around + i))
    faces.append(tuple(reversed(range(around))))
    faces.append(tuple(rows * around + i for i in range(around)))
    obj = kit.mesh_object(name, verts, faces, "stone", at)
    obj.rotation_euler = (0.0, 0.0, turn)
    kit.apply_mesh_transform(obj)
    return obj


def split_log(name, a, b, radius, sides=7, charred=0.0):
    """A split length of firewood: a faceted round with one flat split face,
    its far end burned down to a point by `charred` of its radius."""
    a, b = Vector(a), Vector(b)
    axis = (b - a).normalized()
    up = Vector((0, 0, 1)) if abs(axis.z) < 0.95 else Vector((1, 0, 0))
    side = axis.cross(up).normalized()
    over = side.cross(axis).normalized()
    rings = []
    for t, scale in ((0.0, 1.0), (0.55, 0.96), (1.0, 1.0 - charred)):
        centre = a.lerp(b, t)
        ring = []
        for k in range(sides):
            angle = math.tau * k / sides
            # The split: a flat chord across one side of the round.
            r = radius * scale * (0.78 if k in (0, 1) else 1.0)
            ring.append(centre + side * (r * math.cos(angle)) + over * (r * math.sin(angle)))
        rings.append(ring)
    verts = [v for ring in rings for v in ring]
    faces = []
    for j in range(len(rings) - 1):
        for k in range(sides):
            n = (k + 1) % sides
            faces.append((j * sides + k, j * sides + n, (j + 1) * sides + n, (j + 1) * sides + k))
    faces.append(tuple(reversed(range(sides))))
    faces.append(tuple((len(rings) - 1) * sides + k for k in range(sides)))
    return kit.mesh_object(name, verts, faces, "bark")


def kerb_slab(name, at, wide, thick, tall, turn, lean, seed):
    """A flat stone set on edge in the ground: a slab, not a boulder, its top
    as it split rather than squared."""
    s = seed
    outline = [(-wide/2, 0.0), (wide/2, 0.0),
               (wide/2, tall*(.72+.12*math.sin(s))), (wide*.18, tall*(.95+.05*math.cos(s*1.3))),
               (-wide*.22, tall), (-wide/2, tall*(.66+.14*math.cos(s*.7)))]
    n = len(outline)
    verts = [(u, side*thick/2, v) for side in (-1, 1) for u, v in outline]
    faces = [tuple(range(n)), tuple(reversed(range(n, 2*n)))]
    faces += [(i, i+n, (i+1) % n+n, (i+1) % n) for i in range(n)]
    obj = kit.mesh_object(name, verts, faces, "stone", at, bevel=0.012)
    obj.rotation_euler = (lean, 0.0, turn)
    kit.apply_mesh_transform(obj)
    return obj


def hearth():
    # A hearth as the Norse built one (the long-hearths of Hofstaðir and
    # L'Anse aux Meadows): flat slabs set on edge round an ash bed, and a fire
    # laid as a star — logs pushed in from their ends as they burn, which is
    # how a fire is kept all night. The first version was a ring of round
    # boulders and a teepee of sticks, which is a campsite's.
    for i in range(10):
        angle = math.tau * i / 10 + 0.15
        wide = 0.40 + 0.06 * math.sin(i * 1.7)
        tall = 0.20 + 0.07 * abs(math.sin(i * 0.9 + 0.4))
        # Set tangent to the ring, each leaning out a little as the fire's
        # heat and years of feet have pushed it.
        kerb_slab(f"kerb_slab_{i}", (math.cos(angle) * 0.74, math.sin(angle) * 0.74, 0.0),
                  wide, 0.085 + 0.015 * math.cos(i), tall, angle + math.pi * 0.5,
                  -(0.08 + 0.06 * math.sin(i * 2.1)), float(i))
    # The ash bed, dished, with charcoal in it.
    kit.lathe("ash_bed", [(0.0, 0.035), (0.30, 0.03), (0.52, 0.045), (0.62, 0.0)], "stone", segments=18)
    for i in range(6):
        angle = math.tau * i / 6 + 0.5
        reach = 0.22 + 0.12 * (i % 2)
        kit.cube(f"charcoal_{i}", (math.cos(angle) * reach, math.sin(angle) * reach, 0.05),
                 (0.10, 0.06, 0.05), "timber", 0.01)
    # Five split logs laid as a star, their inner ends burned down where they
    # meet; every other one rides over its neighbours.
    for i in range(5):
        angle = math.tau * i / 5 + 0.3
        foot = Vector((math.cos(angle) * 0.60, math.sin(angle) * 0.60, 0.07))
        inner = Vector((math.cos(angle) * 0.09, math.sin(angle) * 0.09, 0.12 + 0.06 * (i % 2)))
        split_log(f"firewood_{i}", foot, inner, 0.065 + 0.008 * (i % 3), charred=0.6)
    kit.collision_box((-0.95, 0.95, -0.95, 0.95, 0.0, 0.32))


def seat_log():
    """A felled log drawn up to a fire: bark facets, a sawn end and a broken
    one, and two branch stubs — something people have sat on for years."""
    length, radius, sides = 1.7, 0.21, 12
    rings = []
    for t in (0.0, 0.08, 0.5, 0.92, 1.0):
        x = -length * 0.5 + length * t
        swell = 1.0 + 0.06 * math.sin(t * math.pi) - (0.08 if t in (0.0, 1.0) else 0.0)
        ring = []
        for k in range(sides):
            angle = math.tau * k / sides
            bark = 1.0 + 0.05 * ((k * 7 + int(t * 10)) % 3 - 1)
            ring.append((x, radius * swell * bark * math.cos(angle), radius + radius * swell * bark * math.sin(angle)))
        rings.append(ring)
    verts = [v for ring in rings for v in ring]
    faces = []
    for j in range(len(rings) - 1):
        for k in range(sides):
            n = (k + 1) % sides
            faces.append((j * sides + k, j * sides + n, (j + 1) * sides + n, (j + 1) * sides + k))
    faces.append(tuple(reversed(range(sides))))
    faces.append(tuple((len(rings) - 1) * sides + k for k in range(sides)))
    kit.mesh_object("seat_log", verts, faces, "bark")
    for i, (x, angle) in enumerate(((-0.35, 1.1), (0.42, 2.4))):
        root = Vector((x, radius * 0.7 * math.cos(angle), radius + radius * 0.7 * math.sin(angle)))
        tip = root + Vector((0.08, 0.18 * math.cos(angle), 0.18 * math.sin(angle)))
        split_log(f"branch_stub_{i}", root, tip, 0.045, sides=6, charred=0.3)
    kit.collision_box((-0.85, 0.85, -0.22, 0.22, 0.0, 0.42))


def mine_set():
    """A timber set — two posts, a cap, knee braces — the shoring of a mine
    adit. The camp's ways out are the mouth of the Delvings cut into a
    hillside, and its doors were the Delvings' dressed-stone surround standing
    in the cliff like a box set against it. Sized to `LairPassage`'s opening
    (2.4 m wide, 3.4 m to its ceiling): the posts stand 4 cm proud of the
    passage's side walls and the cap 4 cm under its ceiling, so no face of it
    shares a plane with the rock (ADR-297). Symmetric front to back, so it
    needs no facing."""
    post, cap_low, cap_high = 0.28, 3.02, 3.36
    for side in (-1, 1):
        x = side * 1.30
        kit.beam_between(f"post_{side}", (x, 0, 0.0), (x, 0, cap_low), post, post, "bark")
        # A knee brace from the post up under the cap.
        kit.beam_between(f"knee_{side}", (side * 1.16, 0, 2.45), (side * 0.78, 0, cap_low - 0.02),
                         0.14, 0.16, "bark")
        # A stone footing each post stands on.
        fieldstone(f"footing_{side}", (x, 0.0, 0.0), (0.42, 0.40, 0.10), 0.4 * side, 3.0 + side)
    kit.beam_between("cap", (-1.52, 0, (cap_low + cap_high) * 0.5), (1.52, 0, (cap_low + cap_high) * 0.5),
                     cap_high - cap_low, 0.34, "bark")
    # Its true solid, the two posts, as `ART-004` asks of every placed piece.
    # The Lair's doors and the Delvings' corridors place it look-only, as the
    # kit's own modules are (`DelvingsKit.look_of`): their rock is the solid.
    for side in (-1, 1):
        post_solid = kit.cube(f"post_{side}-colonly", (side * 1.30, 0, cap_low * 0.5),
                              (post, post, cap_low), "bark", 0.0, 0.0)
        post_solid.hide_render = True
        post_solid.display_type = "WIRE"


ASSETS = [("camp_hearth", hearth), ("camp_log", seat_log), ("mine_set", mine_set)]


def main():
    bpy.context.preferences.filepaths.save_version = 0
    delivered = []
    for name, builder in ASSETS:
        kit.clear_scene()
        builder()
        # Base-centre from the finished visible form, as `build_dressing.py`
        # does — bark facets put the lowest point a little under the round.
        bpy.context.view_layer.update()
        visible = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
        pts = [o.matrix_world @ v.co for o in visible for v in o.data.vertices]
        shift = Vector(((min(p.x for p in pts) + max(p.x for p in pts)) / 2,
                        (min(p.y for p in pts) + max(p.y for p in pts)) / 2,
                        min(p.z for p in pts)))
        for obj in bpy.context.scene.objects:
            obj.location -= shift
        bpy.context.view_layer.update()
        stats = kit.mesh_stats()
        assert stats["triangles"] <= 3000, (name, stats["triangles"])
        kit.export_asset(name)
        bpy.ops.wm.save_as_mainfile(filepath=str(SRC / (name + ".blend")))
        delivered.append({"name": name, **stats})
        kit.render_asset_review(name, stats)
    (SRC / "camp_measurements.json").write_text(json.dumps(delivered, indent=2) + "\n")
    print("CAMP_DELIVERED", json.dumps(delivered))


if __name__ == "__main__":
    main()
