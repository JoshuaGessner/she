"""Build Her — the hoard-wyrm in her Chamber (ADR-298, ADR-284, `DES-006`, ADR-050).

Run with:
    Blender --background --factory-startup --python build_her.py

## What she is

An **ormr**: the serpent-dragon of the Norse sources, wingless, long and coiled
round her gold. Her *pattern* is Fáfnir's (`DES-006`), and Fáfnir is drawn as a
serpent on the Ramsund carving, his body the band the runes run along. The
shapes here are taken from that tradition rather than from the winged
European dragon, because she **cannot leave her mountain** (`DES-001`) — a pair
of wings says the opposite:

- **She is fused into the mountain.** Her body comes *out of the back wall* on
  both sides of the hoard and an arch of it rises out of the floor between, as
  if the rest of her is stone. ADR-050 fuses her further into the rock with each
  lineage; the colour does that over time, and the shape says it from the first
  visit. It is also the only way a 16 m hall holds her: behind the pile there is
  2.7 m to the wall.
- **Her head is a stave-church dragon's** (the Borgund and Urnes gable heads,
  the Oseberg ship's posts): a long carved snout whose upper lip curls up into a
  spiral, an almond eye under a heavy brow, a lappet streaming back from the
  skull, and a crest of blades down the neck.
- **Her body carries the Urnes double contour** — two raised rims along her
  flanks, the line every Urnes-style beast is drawn with, which the ink pass
  draws as a pair of lines.
- **Two heavy forelegs** at her chest, at the right, with their claws spread on
  the floor in front of the pile.
- **Her eyes are gold**, the one saturated colour on her (ART-005 spends
  saturated colour on treasure): she wants what glitters.

## Where she lies

Authored with her forward along Blender -Y (glTF exports that as Godot +Z), so
in the Chamber she faces the door you come in by, and her origin is the centre
of the hoard. Measured against the hall it stands in (Blender frame, metres):
the back wall's face at y = 2.7, the piers at x = ±7.25, the braziers at
(±5.6, -1.4). The way from the door to the pile, |x| < 1.4 in front of it, is
kept clear below 2.6 m so a body can walk in and kneel.

One material, `her`, whose colour the Chamber overrides every visit — ADR-050's
slow fusing into the stone — and a second, `eye`, which it leaves alone.
"""
import json
import math
import os
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = Path(os.environ.get("HER_OUT", str(ROOT / "game/art/heroes")))
REVIEW = Path(os.environ.get("HER_REVIEW", str(SRC)))
NAME = "her"
PARTS = []
## The head's parts, exported as a node of their own pivoted where the neck
## meets the skull, so the Chamber can turn it toward you (ADR-298).
HEAD = []
NECK_END = []
MATERIALS = {}


def material(kind):
    if kind in MATERIALS:
        return MATERIALS[kind]
    colour = {"her": (0.32, 0.26, 0.22, 1.0), "eye": (0.95, 0.62, 0.12, 1.0)}[kind]
    m = bpy.data.materials.new(kind)
    m.diffuse_color = colour
    m.use_nodes = True
    node = m.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = colour
    node.inputs["Roughness"].default_value = 0.85 if kind == "her" else 0.25
    if kind == "eye":
        node.inputs["Emission Color"].default_value = colour
        node.inputs["Emission Strength"].default_value = 1.5
    m.use_backface_culling = True
    MATERIALS[kind] = m
    return m


def mesh(name, verts, faces, kind="her", smooth=True):
    data = bpy.data.meshes.new(name)
    data.from_pydata([tuple(v) for v in verts], [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(material(kind))
    ink = data.color_attributes.new(name="ink", type="FLOAT_COLOR", domain="CORNER")
    data.color_attributes.active_color = ink
    for c in ink.data:
        c.color = (1.0, 0.5, 0.0, 1.0)
    for poly in data.polygons:
        poly.use_smooth = smooth
    PARTS.append(obj)
    return obj


def frames(points):
    """A rotation-minimising frame along a polyline: (tangent, side, up)."""
    out = []
    t0 = (points[1] - points[0]).normalized()
    up = Vector((0, 0, 1))
    if abs(t0.dot(up)) > 0.9:
        up = Vector((0, 1, 0))
    u = t0.cross(up).normalized()
    for j, p in enumerate(points):
        a = points[max(j - 1, 0)]
        b = points[min(j + 1, len(points) - 1)]
        t = (b - a).normalized()
        # Carry the side vector along rather than re-deriving it, so a sweep
        # that climbs or turns over does not twist its seams round.
        u = (u - t * u.dot(t)).normalized()
        out.append((t, u, u.cross(t).normalized()))
    return out


def tube(name, points, radii, flat=1.0, sides=18, kind="her", ripple=0.0, smooth=True):
    """A swept tube with closed ends. `flat` squashes it vertically and
    `ripple` bands it, so a long body reads as segmented rather than as hose."""
    points = [Vector(p) for p in points]
    along = [0.0]
    for j in range(1, len(points)):
        along.append(along[-1] + (points[j] - points[j - 1]).length)
    rows = []
    for (p, r, s, (t, u, v)) in zip(points, radii, along, frames(points)):
        r *= 1.0 + ripple * math.cos(s * math.tau / 0.42)
        rows.append([p + u * (r * math.cos(k * math.tau / sides))
                     + v * (r * flat * math.sin(k * math.tau / sides)) for k in range(sides)])
    verts = [q for row in rows for q in row]
    faces = []
    for j in range(len(rows) - 1):
        for i in range(sides):
            k = (i + 1) % sides
            faces.append((j * sides + i, j * sides + k, (j + 1) * sides + k, (j + 1) * sides + i))
    verts.append(points[0])
    verts.append(points[-1])
    first, last = len(verts) - 2, len(verts) - 1
    end = (len(rows) - 1) * sides
    for i in range(sides):
        k = (i + 1) % sides
        faces.append((first, k, i))
        faces.append((last, end + i, end + k))
    return mesh(name, verts, faces, kind, smooth)


def rims(name, points, radii, flat=1.0, at=1.05, size=0.055):
    """**The Urnes double contour**: a raised rim along each flank of a sweep."""
    points = [Vector(p) for p in points]
    for side in (-1, 1):
        rim = []
        for p, r, (t, u, v) in zip(points, radii, frames(points)):
            angle = side * at
            rim.append(p + u * (r * math.cos(angle)) + v * (r * flat * math.sin(angle)))
        tube(f"{name}_rim_{side}", rim, [max(0.012, size * r) for r in radii], sides=6)


def blob(name, centre, radii, kind="her", around=20, rows=12, turn=None):
    c = Vector(centre)
    verts, faces = [], []
    for j in range(rows + 1):
        lat = math.pi * j / rows - math.pi / 2
        for i in range(around):
            lon = math.tau * i / around
            q = Vector((radii[0] * math.cos(lat) * math.cos(lon),
                        radii[1] * math.cos(lat) * math.sin(lon),
                        radii[2] * math.sin(lat)))
            verts.append(c + (turn @ q if turn is not None else q))
    for j in range(rows):
        for i in range(around):
            k = (i + 1) % around
            faces.append((j * around + i, j * around + k, (j + 1) * around + k, (j + 1) * around + i))
    return mesh(name, verts, faces, kind)


def loft(name, sections, frame, kind="her", around=20, power=2.6):
    """A carved form lofted through superellipse sections.

    Each section is (forward, half-width, half-height, lift) in `frame`'s own
    space — forward along its -Y — so a head is drawn the way a carver works a
    block: by its profile at each cut. `power` above 2 squares the corners off,
    which is what reads as *carved* rather than as *inflated*."""
    verts, faces = [], []
    for (d, w, h, lift) in sections:
        for i in range(around):
            a = math.tau * i / around
            c, s = math.cos(a), math.sin(a)
            x = w * math.copysign(abs(c) ** (2.0 / power), c)
            z = h * math.copysign(abs(s) ** (2.0 / power), s) + lift
            verts.append(frame @ Vector((x, -d, z)))
    for j in range(len(sections) - 1):
        for i in range(around):
            k = (i + 1) % around
            faces.append((j * around + i, j * around + k, (j + 1) * around + k, (j + 1) * around + i))
    first = frame @ Vector((0, -sections[0][0], sections[0][3]))
    last = frame @ Vector((0, -sections[-1][0], sections[-1][3]))
    verts += [first, last]
    a, b = len(verts) - 2, len(verts) - 1
    end = (len(sections) - 1) * around
    for i in range(around):
        k = (i + 1) % around
        faces.append((a, k, i))
        faces.append((b, end + i, end + k))
    return mesh(name, verts, faces, kind)


def fin(name, base, tangent, up, length, height, thick=0.05, rake=0.35):
    """A blade of crest standing on a spine, raked back along it."""
    t, u = Vector(tangent).normalized(), Vector(up).normalized()
    side = t.cross(u).normalized() * thick
    b = Vector(base)
    front, back = b - t * (length * 0.5), b + t * (length * 0.5)
    top = b + u * height + t * (length * rake)
    verts = [front - side, back - side, top - side, front + side, back + side, top + side]
    faces = [(0, 1, 2), (3, 5, 4), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)]
    return mesh(name, verts, faces, smooth=False)


def spline(points, steps=6):
    """Catmull-Rom through `points`, so every sweep is a curve."""
    points = [Vector(p) for p in points]
    out = []
    for i in range(len(points) - 1):
        p0 = points[max(i - 1, 0)]
        p1, p2 = points[i], points[i + 1]
        p3 = points[min(i + 2, len(points) - 1)]
        for s in range(steps):
            t = s / steps
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t))
    out.append(points[-1])
    return out


def curl(start, centre, turns, shrink, z0, z1, steps=28, clockwise=True):
    """An Urnes spiral: from `start`, winding in round `centre`."""
    s, c = Vector(start), Vector(centre)
    r0 = (s.xy - c.xy).length
    a0 = math.atan2(s.y - c.y, s.x - c.x)
    sign = -1.0 if clockwise else 1.0
    out = []
    for i in range(steps + 1):
        f = i / steps
        a = a0 + sign * f * turns * math.tau
        r = r0 * (1.0 - shrink * f)
        out.append(Vector((c.x + r * math.cos(a), c.y + r * math.sin(a), z0 + (z1 - z0) * f)))
    return out


def taper(count, start, end, bulge=0.0):
    return [start + (end - start) * (i / (count - 1)) + bulge * math.sin(math.pi * i / (count - 1))
            for i in range(count)]


def spines(name, points, radii, every, height, start=0, stop=None, flat=1.0):
    """A crest of blades down the top of a sweep."""
    marks = frames(points)
    stop = len(points) if stop is None else stop
    for n, j in enumerate(range(start, stop, every)):
        t, u, v = marks[j]
        top = points[j] + v * (radii[j] * flat * 0.92)
        size = height * (0.55 + 0.45 * radii[j] / max(radii))
        fin(f"{name}_{n}", top, t, v, size * 0.9, size)


def head(base, aim, pitch):
    """The stave-church head: skull, snout and lip-curl, a hanging jaw, almond
    eyes under the brow, teeth, and a lappet streaming back."""
    frame = (Matrix.Translation(Vector(base))
             @ Matrix.Rotation(math.radians(aim), 4, "Z")
             @ Matrix.Rotation(math.radians(pitch), 4, "X")
             @ Matrix.Scale(1.35, 4))
    # (forward, half-width, half-height, lift) — the carver's cuts, back to tip.
    skull = [(-0.10, 0.36, 0.38, 0.02), (0.08, 0.52, 0.48, 0.04), (0.35, 0.56, 0.46, 0.04),
             (0.62, 0.48, 0.36, 0.00), (0.95, 0.37, 0.28, -0.04), (1.30, 0.31, 0.23, -0.05),
             (1.62, 0.27, 0.21, -0.03), (1.84, 0.22, 0.18, 0.00), (1.96, 0.12, 0.10, 0.02)]
    loft("skull", skull, frame)
    # A carved ridge down the snout's crown, as the gable heads have.
    ridge = [frame @ Vector((0.0, -d, h + lift - 0.02)) for (d, w, h, lift) in skull[2:-1]]
    tube("snout_ridge", spline(ridge, 4), taper(len(spline(ridge, 4)), 0.07, 0.035), sides=8)
    # The jaws stand open, hinged under the back of the skull — a gable head
    # is never shown with its mouth shut — and a tongue curls out between them.
    hinge = frame @ Matrix.Translation(Vector((0, -0.12, -0.30))) @ Matrix.Rotation(math.radians(24), 4, "X")
    jaw = [(0.00, 0.34, 0.14, 0.00), (0.30, 0.38, 0.15, -0.02), (0.70, 0.30, 0.12, -0.03),
           (1.10, 0.25, 0.10, -0.03), (1.45, 0.21, 0.09, -0.02), (1.66, 0.13, 0.06, 0.00)]
    loft("jaw", jaw, hinge, around=16)
    tongue = spline([hinge @ Vector(p) for p in ((0, -0.30, 0.10), (0, -0.95, 0.14), (0, -1.55, 0.20),
                                                 (0, -1.95, 0.42), (0, -1.85, 0.66), (0, -1.68, 0.60))], 5)
    tube("tongue", tongue, taper(len(tongue), 0.08, 0.02), flat=0.5, sides=10)
    for side in (-1, 1):
        x = 0.30 * side
        for n, d in enumerate((0.75, 1.05, 1.35)):
            root = hinge @ Vector((0.22 * side * (1.0 - 0.15 * n), -d, 0.12))
            tube(f"lower_tooth_{side}_{n}", [root, root + hinge.to_3x3() @ Vector((0, -0.02, 0.12 + 0.03 * n))],
                 [0.03, 0.004], sides=6)
        # A heavy brow, low and long, and an almond eye set under it — gold.
        blob(f"brow_{side}", frame @ Vector((0.40 * side, -0.56, 0.27)), (0.15, 0.48, 0.08),
             turn=frame.to_3x3() @ Matrix.Rotation(math.radians(-14 * side), 3, "Z"))
        blob(f"eye_{side}", frame @ Vector((0.47 * side, -0.55, 0.16)), (0.065, 0.21, 0.085),
             kind="eye", around=12, rows=6,
             turn=frame.to_3x3() @ Matrix.Rotation(math.radians(-14 * side), 3, "Z"))
        blob(f"nostril_{side}", frame @ Vector((0.13 * side, -1.86, 0.15)), (0.06, 0.07, 0.05),
             around=8, rows=5)
        # Teeth down the upper rim, longest at the front.
        for n, d in enumerate((0.95, 1.15, 1.35, 1.55, 1.75)):
            length = 0.10 + 0.05 * n
            top = frame @ Vector((x * (1.0 - 0.18 * n), -d, -0.20))
            tube(f"tooth_{side}_{n}", [top, top + frame.to_3x3() @ Vector((0, -0.02, -length))],
                 [0.035, 0.004], sides=6)
        # A cheek blade swept back below the eye.
        fin(f"cheek_{side}", frame @ Vector((0.44 * side, -0.25, -0.12)),
            frame.to_3x3() @ Vector((0, 1, 0.2)), frame.to_3x3() @ Vector((side, 0, -0.2)), 0.7, 0.45)
    # **The lip-curl**: the upper lip rises off the snout's tip and rolls back
    # on itself — the gable heads' signature, and her silhouette's.
    lip = [frame @ Vector((0.0, -1.90 + 0.42 * math.sin(f * 1.15 * math.tau) * (1 - 0.6 * f),
                          0.45 - 0.25 * math.cos(f * 1.15 * math.tau) * (1 - 0.6 * f)))
           for f in (i / 22 for i in range(23))]
    tube("lip_curl", lip, taper(len(lip), 0.16, 0.03), sides=12)
    # **The lappet**: a tendril off the back of the skull, streaming back down
    # the neck and curling at its end.
    lappet = [frame @ Vector(p) for p in ((0, 0.05, 0.38), (0, 0.55, 0.45), (0, 1.05, 0.25),
                                         (0, 1.45, -0.15), (0, 1.55, -0.50))]
    lappet = spline(lappet, 6)
    end = lappet[-1]
    tail_curl = [end + frame.to_3x3() @ Vector((0, 0.22 * math.sin(f * 4.2), -0.22 * (1 - math.cos(f * 4.2))))
                 * (1 - 0.5 * f) for f in (i / 12 for i in range(1, 13))]
    path = lappet + tail_curl
    tube("lappet", path, taper(len(path), 0.13, 0.025), flat=0.55, sides=10)
    return frame


def leg(side_name, shoulder, elbow, wrist, paw, size):
    """A foreleg on the floor, claws spread forward over the stone."""
    path = spline([shoulder, elbow, wrist], 6)
    tube(f"foreleg_{side_name}", path, taper(len(path), 0.55 * size, 0.30 * size, 0.08), sides=16)
    p = Vector(paw)
    blob(f"paw_{side_name}", p, (0.42 * size, 0.50 * size, 0.18 * size))
    for k, spread in enumerate((-0.55, -0.18, 0.18, 0.55)):
        root = p + Vector((0.34 * size * spread, -0.40 * size, 0.0))
        claw = [root, root + Vector((0.10 * spread, -0.22, -0.02)) * size,
                root + Vector((0.14 * spread, -0.38, -0.14)) * size]
        tube(f"claw_{side_name}_{k}", claw, [0.075 * size, 0.045 * size, 0.004], sides=8)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0

    # ── the right: her chest and forequarters, out of the wall ────────────
    chest = spline([(3.0, 3.6, 0.65), (3.9, 2.1, 0.85), (4.3, 0.5, 0.95), (4.0, -0.9, 1.05),
                    (3.0, -1.8, 1.25)], 8)
    chest_r = taper(len(chest), 0.78, 0.95, 0.06)
    tube("chest", chest, chest_r, flat=0.86, sides=24, ripple=0.035)
    rims("chest", chest, chest_r, flat=0.86)
    spines("chest_crest", chest, chest_r, 4, 0.34, start=6, flat=0.86)

    # ── the neck rises off the chest and arches in over the hoard ─────────
    neck = spline([(3.0, -1.8, 1.25), (2.45, -2.05, 2.15), (1.75, -1.65, 3.05), (1.05, -1.05, 3.55),
                   (0.62, -0.72, 3.70)], 7)
    neck_r = taper(len(neck), 0.92, 0.40)
    tube("neck", neck, neck_r, flat=0.92, sides=22, ripple=0.03)
    rims("neck", neck, neck_r, flat=0.92)
    spines("neck_crest", neck, neck_r, 3, 0.48, start=2, flat=0.92)
    first = len(PARTS)
    head(neck[-1], aim=-38.0, pitch=24.0)
    HEAD[:] = PARTS[first:]
    NECK_END[:] = list(neck[-1])

    # ── the forelegs, at her chest, claws on the floor before the pile ────
    leg("outer", (3.55, -1.35, 1.10), (4.35, -2.15, 0.75), (3.95, -3.00, 0.28), (3.85, -3.30, 0.16), 1.0)
    leg("inner", (2.45, -2.10, 1.05), (2.45, -2.95, 0.78), (1.95, -3.30, 0.28), (1.85, -3.58, 0.15), 0.9)

    # ── the left: her tail, out of the wall, round the pile, curling ──────
    sweep = spline([(-2.6, 3.6, 0.55), (-3.8, 2.1, 0.68), (-4.3, 0.3, 0.62), (-3.85, -1.5, 0.48),
                    (-2.85, -2.55, 0.36), (-1.95, -2.95, 0.28)], 8)
    spiral = curl(sweep[-1], (-1.95, -2.30, 0.0), 1.15, 0.72, 0.28, 0.20, 26, clockwise=False)
    tail = sweep + spiral[1:]
    tail_r = taper(len(tail), 0.78, 0.07)
    tube("tail", tail, tail_r, flat=0.82, sides=20, ripple=0.04)
    rims("tail", tail, tail_r, flat=0.82)
    spines("tail_crest", tail, tail_r, 4, 0.26, start=2, stop=len(sweep), flat=0.82)

    # ── an arch of her rising out of the floor behind the pile ───────────
    arch = spline([(1.9, 2.9, -0.45), (1.0, 2.25, 0.85), (-0.2, 2.15, 1.25), (-1.3, 2.4, 0.75),
                   (-2.0, 2.95, -0.45)], 8)
    arch_r = taper(len(arch), 0.72, 0.66, 0.06)
    tube("arch", arch, arch_r, flat=0.9, sides=22, ripple=0.035)
    rims("arch", arch, arch_r, flat=0.9)
    spines("arch_crest", arch, arch_r, 4, 0.32, start=3, stop=len(arch) - 3, flat=0.9)


def joined(parts, name):
    """Join `parts` into one object, every normal pointing out."""
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    # Every sweep is wound by hand, and a hand gets half of them inside out:
    # Cycles draws both sides and hid it, the game culls back faces and showed
    # a body with no skin. One pass makes every normal point out.
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def export():
    build()
    triangles = sum(len(poly.vertices) - 2 for obj in PARTS for poly in obj.data.polygons)
    assert triangles <= 40000, triangles
    for obj in PARTS:
        assert obj.matrix_basis.is_identity
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / (NAME + ".blend")))
    body = joined([obj for obj in PARTS if obj not in HEAD], "her_body")
    skull = joined(HEAD, "her_head")
    # The head turns about the top of the neck, so its origin is put there.
    bpy.context.scene.cursor.location = Vector(NECK_END)
    bpy.ops.object.select_all(action="DESELECT")
    skull.select_set(True)
    bpy.context.view_layer.objects.active = skull
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    skull.select_set(True)
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / (NAME + ".glb")), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True)
    report = {"asset": NAME, "triangles": triangles, "parts": len(PARTS), "units": "metres",
              "forward": "Blender -Y / Godot +Z", "origin": "centre of the hoard pile",
              "form": "ormr — wingless, fused into the back wall (ADR-298)",
              "nodes": {"her_body": "everything but the head",
                        "her_head": "pivoted at the top of the neck, %s" % [round(c, 3) for c in NECK_END]}}
    (SRC / (NAME + "_measurements.json")).write_text(json.dumps(report, indent=2) + "\n")
    review()
    return report


def review():
    """Her from the door, both quarters and above, against her hall's walls.

    The walls are stood in so the review answers the question the game asks:
    does she fit the room and leave the way to the pile open."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_cavity = True
    scene.display.shading.show_object_outline = True
    scene.render.resolution_x = 960
    scene.render.resolution_y = 600
    for name, size, at in (("back_wall", (16, 0.6, 6), (0, 3.0, 3)), ("floor", (16, 14, 0.2), (0, -3.0, -0.1))):
        bpy.ops.mesh.primitive_cube_add(location=at)
        wall = bpy.context.object
        wall.name = name
        wall.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=2.4, location=(0, 0, 0))
    hoard = bpy.context.object
    hoard.scale = (1, 1, 0.3)
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    scene.camera = camera
    camera.data.lens = 24
    for view, at, look in (("door", (0.0, -8.0, 1.6), (0, 0, 2.0)),
                           ("quarter_left", (-5.5, -6.5, 2.2), (0, 0, 1.8)),
                           ("quarter_right", (5.5, -6.5, 2.2), (0, 0, 1.8)),
                           ("above", (0.0, -7.0, 9.0), (0, 0, 0.5)),
                           ("head", (2.2, -4.6, 3.2), (0.4, -1.4, 3.5))):
        camera.location = at
        camera.rotation_euler = (Vector(look) - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(REVIEW / f"{NAME}_review_{view}.png")
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    print(json.dumps(export(), indent=2))
