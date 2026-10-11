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


kit.PALETTE["canvas"] = ((0.60, 0.56, 0.48, 1.0), kit.PALETTE["rope"][1])
kit.PALETTE["hide"] = ((0.27, 0.20, 0.14, 1.0), kit.PALETTE["timber"][1])

# The tent's measure (ADR-402): door toward -Y, which glTF's Y-up turns into
# the scene's +Z, the way `CampDressing.campsite` faces a plot at the fire.
TENT_LONG = 3.0
TENT_HALF = 1.3
TENT_HIGH = 2.0


def _canvas_point(flank, u, v):
    """A point on one flank of the canvas: `u` along the tent (0 at the door),
    `v` from the hem (0) to the ridge (1). Wool over a ridge pole sags between
    the gables and bellies inward down the slope; the hem flares where it is
    pegged out, and lifts a little between the pegs."""
    sag = 0.12 * math.sin(math.pi * v) * (0.5 + 0.5 * math.sin(math.pi * u))
    # Woven strips sewn edge to edge: every seam stands a little proud, which
    # is also what gives the ink pass an edge to draw down the slope.
    seam = 0.022 * math.sin(math.pi * v) if 0.0 < u < 1.0 and round(u * 8) % 2 == 0 else 0.0
    flare = 0.07 * max(0.0, 1.0 - v / 0.16) ** 2
    lift = 0.045 * (1.0 - math.cos(math.tau * u * 4.0)) * 0.5 * max(0.0, 1.0 - v / 0.05)
    x = flank * (TENT_HALF * (1.0 - v) - sag + flare + seam)
    y = -TENT_LONG * 0.5 + TENT_LONG * u
    return (x, y, TENT_HIGH * v + lift)


def _solidify(obj, thickness):
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new("cloth_weight", "SOLIDIFY")
    mod.thickness = thickness
    mod.offset = -1.0
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return kit.finish(obj, obj.name, obj.data.materials[0].name.removeprefix("flat_"))


def _carved_head(name, tip, rise, out):
    """A beast's head on a gable board's tip, as on the Gokstad tent boards: a
    neck turning out over the gable, a snout, an open jaw and a swept-back ear.
    Read at camp distance as a silhouette against the sky, which is all it is
    asked to do."""
    tip, rise, out = Vector(tip), Vector(rise), Vector(out)
    neck = [tip - rise * 0.06, tip + rise * 0.10, tip + rise * 0.17 + out * 0.07,
            tip + rise * 0.19 + out * 0.17]
    kit.tube(f"{name}_neck", [tuple(p) for p in neck], 0.045, "bark", sides=6)
    head = neck[-1] + out * 0.08
    snout = kit.cube(f"{name}_snout", tuple(head), (0.17, 0.06, 0.08), "bark", 0.008)
    snout.rotation_euler = (0.0, -math.atan2(out.z, out.x) + 0.12 * (1 if out.x > 0 else -1), 0.0)
    kit.apply_mesh_transform(snout)
    jaw = kit.cube(f"{name}_jaw", tuple(head + out * 0.02 - Vector((0, 0, 0.065))),
                   (0.13, 0.05, 0.035), "bark", 0.006)
    jaw.rotation_euler = (0.0, 0.32 if out.x > 0 else -0.32, 0.0)
    kit.apply_mesh_transform(jaw)
    ear = kit.cube(f"{name}_ear", tuple(head - out * 0.07 + Vector((0, 0, 0.06))),
                   (0.03, 0.04, 0.09), "bark", 0.0)
    ear.rotation_euler = (0.0, -0.6 if out.x > 0 else 0.6, 0.0)
    kit.apply_mesh_transform(ear)


def _join_by_family():
    """One mesh per material family: built as fifty-odd pieces, the tent
    arrived as fifty-four surfaces, and the camp lays four of them. The canvas
    joins under the name `canvas`, which is how the camp finds it to dye."""
    families = {}
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and not obj.hide_render:
            families.setdefault(obj.data.materials[0].name.removeprefix("flat_"), []).append(obj)
    for kind, parts in families.items():
        bpy.ops.object.select_all(action="DESELECT")
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        if len(parts) > 1:
            bpy.ops.object.join()
        bpy.context.object.name = kind
        bpy.context.object.data.name = kind
        # A torus keeps its rotation un-applied; joined under it, the whole
        # family would carry it, and its bounds would be measured rotated.
        kit.apply_mesh_transform(bpy.context.object)
    bpy.context.view_layer.update()


def camp_tent():
    """A plot's tent (ADR-402), after the tent found with the Gokstad ship: two
    pairs of boards crossed at each gable with carved heads on their tips, a
    ridge pole laid in the crossings, and wool canvas pegged out at the hem.

    The first tent was two quads that a rotation stood on edge — the camp's
    four plots read as blades. This one is built so its silhouette says *tent*
    from the fire: the crossed boards and the heads against the sky, the door
    flaps tied back toward the fire, a bedroll and a hide inside.

    The canvas is its own material family so the camp can dye each plot."""
    rows, cols = 6, 8
    for flank in (-1, 1):
        verts, faces = [], []
        for j in range(rows + 1):
            for i in range(cols + 1):
                verts.append(_canvas_point(flank, i / cols, j / rows))
        for j in range(rows):
            for i in range(cols):
                a = j * (cols + 1) + i
                quad = (a, a + 1, a + cols + 2, a + cols + 1)
                faces.append(quad if flank > 0 else tuple(reversed(quad)))
        _solidify(kit.mesh_object(f"canvas_flank_{flank}", verts, faces, "canvas"), 0.025)
    # The back gable, closed: the two flanks' last columns and the ridge.
    edge = [_canvas_point(-1, 1.0, j / rows) for j in range(rows + 1)]
    edge += [_canvas_point(1, 1.0, j / rows) for j in reversed(range(rows))]
    back = [(x, y - 0.01, z) for x, y, z in edge]
    _solidify(kit.mesh_object("canvas_back", back, [tuple(range(len(back)))], "canvas"), 0.025)
    # The door, open: the front gable is split down the middle and each half
    # is gathered back against its board and tied, so the doorway is a dark
    # triangle framed in bunched cloth, facing the fire.
    apex = Vector((0.0, -TENT_LONG * 0.5, TENT_HIGH))
    for flank in (-1, 1):
        corner = Vector(_canvas_point(flank, 0.0, 0.0))
        gathered = corner.lerp(Vector((0.0, corner.y, 0.0)), 0.22) + Vector((0.0, -0.05, 0.12))
        belly = apex.lerp(corner, 0.55).lerp(gathered, 0.5) + Vector((0.0, -0.09, 0.0))
        pts = [apex + Vector((0.0, -0.02, -0.06)), corner + Vector((0.0, -0.03, 0.0)), gathered, belly]
        faces = [(0, 3, 2, 1)] if flank > 0 else [(0, 1, 2, 3)]
        _solidify(kit.mesh_object(f"canvas_door_{flank}", [tuple(p) for p in pts], faces, "canvas"), 0.07)
        # The tie round the gathered cloth, halfway down.
        tie = apex.lerp(corner, 0.5)
        kit.torus(f"door_tie_{flank}", tuple(tie + Vector((0.0, -0.06, 0.0))), 0.1, 0.014, "rope", 10, 4,
                  rotation=(0.0, math.atan2(corner.z - apex.z, corner.x - apex.x) + math.pi * 0.5, 0.0))
    # The frame: at each gable two boards cross over the ridge.
    for end, y in (("door", -TENT_LONG * 0.5 - 0.05), ("back", TENT_LONG * 0.5 + 0.05)):
        crossing = Vector((0.0, y, TENT_HIGH + 0.03))
        for flank in (-1, 1):
            foot = Vector((flank * (TENT_HALF + 0.08), y + 0.03 * flank, -0.04))
            rise = (crossing - foot).normalized()
            tip = crossing + rise * 0.34 + Vector((0, 0.03 * flank, 0))
            kit.beam_between(f"board_{end}_{flank}", tuple(foot), tuple(tip), 0.15, 0.045, "bark")
            out = Vector((-flank, 0.0, 0.0))
            _carved_head(f"head_{end}_{flank}", tuple(tip), tuple(rise), tuple(out))
    kit.cylinder("ridge_pole", (0.0, 0.0, TENT_HIGH + 0.07), 0.05, TENT_LONG + 0.5, "bark",
                 vertices=8, rotation=(math.pi * 0.5, 0.0, 0.0))
    # Pegs down each hem, at the low points between the scallops, with a loop
    # of rope from the hem to each.
    for flank in (-1, 1):
        for k in range(5):
            u = k / 4.0
            hem = Vector(_canvas_point(flank, u, 0.0))
            peg_at = hem + Vector((flank * 0.2, 0.0, 0.0))
            peg = kit.cube(f"peg_{flank}_{k}", tuple(peg_at + Vector((0, 0, 0.07))),
                           (0.04, 0.04, 0.22), "bark", 0.0)
            peg.rotation_euler = (0.0, -0.35 * flank, 0.0)
            kit.apply_mesh_transform(peg)
            kit.tube(f"peg_loop_{flank}_{k}", [tuple(hem + Vector((0, 0, 0.03))),
                                               tuple(peg_at + Vector((0, 0, 0.13)))], 0.01, "rope", sides=4)
    # Inside: a hide on the ground and a rolled bedroll at the back.
    hide = [(math.cos(a) * (0.78 + 0.08 * math.sin(a * 3)), math.sin(a) * (0.55 + 0.06 * math.cos(a * 2)) + 0.25, 0.015)
            for a in (math.tau * i / 9 for i in range(9))]
    kit.mesh_object("floor_hide", hide, [tuple(range(9))], "hide")
    kit.cylinder("bedroll", (0.0, 0.85, 0.15), 0.15, 1.0, "hide", vertices=10,
                 rotation=(0.0, math.pi * 0.5, 0.0))
    for x in (-0.3, 0.3):
        kit.torus(f"bedroll_strap_{x}", (x, 0.85, 0.15), 0.158, 0.012, "rope", 12, 4,
                  rotation=(0.0, math.pi * 0.5, 0.0))
    # By the door: a leather pack and an iron pot.
    kit.lathe("pack", [(0.0, 0.0), (0.2, 0.02), (0.23, 0.22), (0.18, 0.46), (0.07, 0.52), (0.0, 0.53)],
              "hide", loc=(1.0, -TENT_LONG * 0.5 - 0.45, 0.0), segments=9)
    kit.lathe("pot", [(0.0, 0.0), (0.13, 0.01), (0.19, 0.12), (0.17, 0.24), (0.19, 0.26), (0.16, 0.26), (0.0, 0.03)],
              "metal", loc=(0.42, -TENT_LONG * 0.5 - 0.62, 0.0), segments=12)
    _join_by_family()
    # Its solid: a low box the width of the hem and a narrow one up to the
    # ridge, so a body is turned by the canvas, not by air beside it.
    for name, half, high in (("tent_low-colonly", TENT_HALF, 0.9), ("tent_high-colonly", TENT_HALF * 0.5, TENT_HIGH)):
        solid = kit.cube(name, (0.0, 0.0, high * 0.5), (half * 2.0, TENT_LONG, high), "canvas", 0.0, 0.0)
        solid.hide_render = True
        solid.display_type = "WIRE"


# (name, builder, centred): a tent's origin is its own middle, not the middle
# of whatever stands by its door.
ASSETS = [("camp_hearth", hearth, True), ("camp_log", seat_log, True), ("mine_set", mine_set, True),
          ("camp_tent", camp_tent, False)]


def main():
    bpy.context.preferences.filepaths.save_version = 0
    # `-- camp_tent` builds only what is named; the measurements keep the rest.
    wanted = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    record = SRC / "camp_measurements.json"
    delivered = [row for row in json.loads(record.read_text())
                 if wanted and row["name"] not in wanted] if record.exists() else []
    for name, builder, centred in ASSETS:
        if wanted and name not in wanted:
            continue
        kit.clear_scene()
        builder()
        # Base-centre from the finished visible form, as `build_dressing.py`
        # does — bark facets put the lowest point a little under the round.
        bpy.context.view_layer.update()
        visible = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
        pts = [o.matrix_world @ v.co for o in visible for v in o.data.vertices]
        shift = Vector(((min(p.x for p in pts) + max(p.x for p in pts)) / 2 if centred else 0.0,
                        (min(p.y for p in pts) + max(p.y for p in pts)) / 2 if centred else 0.0,
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
