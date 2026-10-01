"""Build Her — the hoard-dragon in her Chamber (ADR-284, `DES-014`, ADR-050).

Run with:
    Blender --background --factory-startup --python build_her.py

Static, not skinned: she lies behind the hoard and does not move in the slice.
Authored with her forward along Blender -Y (glTF exports that as Godot +Z), so
in the Chamber she faces the door you come in by, and her origin is the centre
of the hoard pile she lies around. One material, `her`, whose colour the
Chamber overrides every visit — ADR-050's slow fusing into the stone — and a
second, `eye`, which it leaves alone.

The shapes are swept tubes and ellipsoids, because a silhouette is what carries
her across a dark hall (`DES-014`: *"a neck, a head that looms over the hoard
and a tail"*), and every one of them is a curve rather than a box.
"""
import json
import math
import os
from pathlib import Path

import bpy
from mathutils import Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = Path(os.environ.get("HER_OUT", str(ROOT / "game/art/heroes")))
NAME = "her"
PARTS = []
MATERIALS = {}


def material(kind):
    if kind in MATERIALS:
        return MATERIALS[kind]
    colour = {"her": (0.32, 0.26, 0.22, 1.0), "eye": (0.03, 0.025, 0.02, 1.0)}[kind]
    m = bpy.data.materials.new(kind)
    m.diffuse_color = colour
    m.use_nodes = True
    node = m.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = colour
    node.inputs["Roughness"].default_value = 0.85
    m.use_backface_culling = False
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


def tube(name, points, radii, flat=1.0, sides=18, kind="her"):
    """A swept tube with closed ends. `flat` squashes it vertically."""
    points = [Vector(p) for p in points]
    rows = []
    for j, (p, r) in enumerate(zip(points, radii)):
        a = points[max(j - 1, 0)]
        b = points[min(j + 1, len(points) - 1)]
        t = (b - a).normalized()
        up = Vector((0, 0, 1))
        if abs(t.dot(up)) > 0.95:
            up = Vector((0, 1, 0))
        u = t.cross(up).normalized()
        v = u.cross(t).normalized()
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
    return mesh(name, verts, faces, kind)


def blob(name, centre, radii, kind="her", around=20, rows=12):
    c = Vector(centre)
    verts, faces = [], []
    for j in range(rows + 1):
        lat = math.pi * j / rows - math.pi / 2
        for i in range(around):
            lon = math.tau * i / around
            verts.append(c + Vector((radii[0] * math.cos(lat) * math.cos(lon),
                                     radii[1] * math.cos(lat) * math.sin(lon),
                                     radii[2] * math.sin(lat))))
    for j in range(rows):
        for i in range(around):
            k = (i + 1) % around
            faces.append((j * around + i, j * around + k, (j + 1) * around + k, (j + 1) * around + i))
    return mesh(name, verts, faces, kind)


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


def taper(count, start, end, bulge=0.0):
    return [start + (end - start) * (i / (count - 1)) + bulge * math.sin(math.pi * i / (count - 1))
            for i in range(count)]


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0

    # ── the body: a long mound coiled behind the pile ──────────────────────
    body = spline([(-5.6, 2.9, 1.0), (-3.4, 3.1, 1.45), (-0.6, 2.8, 1.7), (2.4, 2.9, 1.55), (4.4, 3.3, 1.05), (5.4, 4.3, 0.6)], 8)
    tube("body", body, taper(len(body), 1.0, 0.25, 0.75), flat=0.74, sides=24)

    # ── the neck rises from the shoulders and arches over the hoard ──────
    neck = spline([(0.9, 2.3, 2.2), (0.6, 1.6, 3.3), (0.25, 0.6, 4.0), (0.05, -0.3, 3.95)], 7)
    tube("neck", neck, taper(len(neck), 0.95, 0.5), flat=0.9, sides=20)
    for i, p in enumerate(neck[2:-1:2]):
        tube(f"neck_spine_{i}", [p + Vector((0, 0.15, 0.42)), p + Vector((0, 0.42, 0.85))], [0.13, 0.01], sides=8)

    # ── the head, looking down at what you bring ────────────────────────
    blob("skull", (0.0, -0.5, 3.95), (0.52, 0.78, 0.42))
    snout = spline([(0.0, -0.8, 3.88), (0.0, -1.6, 3.62), (0.0, -2.35, 3.36)], 5)
    tube("snout", snout, taper(len(snout), 0.38, 0.16), flat=0.62, sides=18)
    jaw = spline([(0.0, -0.55, 3.58), (0.0, -1.35, 3.36), (0.0, -2.15, 3.22)], 5)
    tube("jaw", jaw, taper(len(jaw), 0.36, 0.15), flat=0.55, sides=16)
    for side in (-1, 1):
        blob(f"brow_{side}", (0.33 * side, -0.92, 4.1), (0.2, 0.42, 0.1))
        tube(f"fang_{side}", [(0.14 * side, -2.05, 3.3), (0.15 * side, -2.1, 3.08)], [0.045, 0.004], sides=8)
        blob(f"eye_{side}", (0.38 * side, -1.0, 4.0), (0.05, 0.09, 0.035), kind="eye", around=10, rows=6)
        blob(f"nostril_{side}", (0.13 * side, -2.4, 3.45), (0.07, 0.06, 0.05), kind="eye", around=8, rows=5)
        horn = spline([(0.32 * side, -0.25, 4.25), (0.58 * side, 0.45, 4.62), (0.8 * side, 1.3, 4.5), (0.85 * side, 1.8, 4.1)], 6)
        tube(f"horn_{side}", horn, taper(len(horn), 0.15, 0.015), sides=10)
        tube(f"cheek_{side}", [(0.48 * side, -0.35, 3.75), (0.85 * side, 0.15, 3.65)], [0.09, 0.01], sides=8)

        # ── forelegs, resting forward either side of the pile ──────────
        leg = spline([(2.4 * side, 2.4, 1.6), (3.1 * side, 1.5, 1.0), (3.35 * side, 0.4, 0.45), (3.4 * side, -0.25, 0.22)], 6)
        tube(f"foreleg_{side}", leg, taper(len(leg), 0.62, 0.3), sides=16)
        blob(f"forepaw_{side}", (3.4 * side, -0.5, 0.2), (0.5, 0.62, 0.22))
        for k in (-1, 0, 1):
            root = Vector((3.4 * side + 0.26 * k, -0.95, 0.18))
            tube(f"claw_{side}_{k}", [root, root + Vector((0.02 * k, -0.28, -0.06)), root + Vector((0.03 * k, -0.42, -0.17))],
                 [0.08, 0.05, 0.005], sides=8)

        # ── wings, folded along the back ───────────────────────────────
        spar = spline([(1.0 * side, 2.4, 2.6), (2.0 * side, 3.4, 4.3), (3.6 * side, 3.9, 3.9), (5.0 * side, 3.7, 2.4)], 6)
        tube(f"wing_arm_{side}", spar, taper(len(spar), 0.22, 0.05), sides=10)
        lower = [Vector((p.x * 0.92, p.y - 0.15, 2.35 - 0.12 * abs(p.x))) for p in spar]
        verts = list(spar) + lower
        n = len(spar)
        faces = [(i, i + 1, n + i + 1, n + i) for i in range(n - 1)]
        mesh(f"wing_{side}", verts, faces, smooth=False)
        for f, finger in enumerate((0.4, 0.7)):
            p = spar[int(finger * (n - 1))]
            tube(f"wing_finger_{side}_{f}", [p, Vector((p.x * 0.95, p.y - 0.1, 2.45))], [0.06, 0.03], sides=8)

    # ── a hind leg on the near side of the coil ─────────────────────────
    for name, hind in (("hindleg_l", spline([(-3.6, 2.6, 1.3), (-4.1, 1.9, 0.75), (-3.9, 1.35, 0.25)], 6)),
                       ("hindleg_r", spline([(4.0, 3.1, 1.2), (4.6, 2.3, 0.7), (4.5, 1.7, 0.25)], 6))):
        tube(name, hind, taper(len(hind), 0.7, 0.32), sides=16)
        blob(name + "_paw", hind[-1] + Vector((0, -0.3, -0.07)), (0.42, 0.55, 0.18))

    # ── the tail, curling round the pile's left side ────────────────────
    tail = spline([(-5.4, 3.0, 1.0), (-6.5, 1.6, 0.7), (-6.2, -0.5, 0.5), (-5.0, -2.2, 0.38), (-3.4, -2.9, 0.3)], 8)
    tube("tail", tail, taper(len(tail), 0.95, 0.05), flat=0.8, sides=16)

    # ── the ridge down her back ─────────────────────────────────────────
    for i, p in enumerate(body[2:-14:3]):
        tube(f"back_spine_{i}", [p + Vector((0, 0.1, 0.8)), p + Vector((0, 0.35, 1.35))], [0.16, 0.01], sides=8)
    for i, p in enumerate(tail[1:-4:3]):
        tube(f"tail_spine_{i}", [p + Vector((0, 0, 0.45)), p + Vector((0, 0.1, 0.75))], [0.1, 0.01], sides=8)


def export():
    build()
    triangles = sum(len(poly.vertices) - 2 for obj in PARTS for poly in obj.data.polygons)
    assert triangles <= 40000, triangles
    for obj in PARTS:
        assert obj.matrix_basis.is_identity
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / (NAME + ".blend")))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    # Every sweep is wound by hand, and a hand gets half of them inside out:
    # Cycles draws both sides and hid it, the game culls back faces and showed
    # a body with no skin. One pass makes every normal point out.
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / (NAME + ".glb")), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True)
    report = {"asset": NAME, "triangles": triangles, "parts": len(PARTS), "units": "metres",
              "forward": "Blender -Y / Godot +Z", "origin": "centre of the hoard pile"}
    (SRC / (NAME + "_measurements.json")).write_text(json.dumps(report, indent=2) + "\n")
    review()
    return report


def review():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 760
    world = bpy.data.worlds.new("review")
    world.color = (0.3, 0.3, 0.32)
    scene.world = world
    for loc, power in (((-6, -9, 9), 3000), ((7, -4, 6), 1800)):
        bpy.ops.object.light_add(type="AREA", location=loc)
        light = bpy.context.object
        light.data.energy = power
        light.data.size = 6
        light.rotation_euler = (Vector((0, 1, 2)) - light.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(4.5, -11.0, 4.2))
    camera = bpy.context.object
    scene.camera = camera
    camera.rotation_euler = (Vector((0, 1.2, 2.2)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 32
    scene.render.filepath = str(SRC / (NAME + "_review.png"))
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    print(json.dumps(export(), indent=2))
