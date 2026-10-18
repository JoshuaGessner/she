"""Build Dvergar plate as it lies on a floor — one sculpted mesh (ADR-406).

Run with:
    Blender --background --factory-startup --python-exit-code 1 --python build_plate_item.py

**What it is.** The worn piece's cuirass (`build_worn.dvergar_plate`): a
lamellar of the Birka garrison's kind, courses of narrow iron lames laced from
the breast to the hips, with a spaulder at each shoulder and the belt still
through its loops. Put down, it does not slump as the byrnie does — lamellar
is laced rigid along each course — so it lies on its back as a shallow shell,
the spaulders fallen outward and the belt's tail loose. The lames are baked
into a normal map exactly as the worn piece draws them; one warm iron
material, as every prop has (`ART-006`).

Blender coordinates, Z up: the neck toward +Y, the hem toward −Y, lying on
z = 0. The exporter turns it Y-up for Godot.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import bpy
import numpy as np

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = Path(os.environ.get("PLATE_OUT", str(ROOT / "game/art/props")))
sys.path.insert(0, str(SRC.parent / "lib"))
import sdf_sculpt as S  # noqa: E402
import blender_bake as K  # noqa: E402

VOXEL = 0.007
TRIS = 2800
TEXTURE = 2048
BOUNDS = ((-0.50, -0.42, -0.02), (0.50, 0.42, 0.17))
## Ink metadata for metal (`ART-006` §2.3).
METAL = 0.4
V = lambda t: np.asarray(t, float)  # noqa: E731


def cuirass(p):
    """The cuirass on its back: a shallow rigid shell, open at the neck."""
    # Front and back pressed together: a shell rounded across the chest, as
    # the courses curve round a body, and flat beneath where it lies.
    body = S.round_box(p - V((0.0, -0.02, 0.045)), V((0.20, 0.25, 0.035)), 0.035)
    chest = S.ellipsoid(p - V((0.0, 0.07, 0.055)), V((0.21, 0.17, 0.065)))
    d = S.smin(body, chest, 0.04)
    # Each course stands a few millimetres proud at its foot (toward −Y), so
    # the courses are in the silhouette as well as the bake.
    k = np.floor((p[:, 1] + 0.30) / 0.056)
    d = d + 0.004 * ((p[:, 1] + 0.30) / 0.056 - k)
    # Spaulders, fallen outward from the shoulders, each a cap lying on its side.
    # Long and flat, as a laced spaulder lies: not a ball.
    for side in (-1.0, 1.0):
        c = V((side * 0.265, 0.12, 0.032))
        cap = S.ellipsoid(p - c, V((0.085, 0.14, 0.035)))
        d = S.smin(d, cap, 0.015)
    # The belt across the waist, its buckle up and its tail loose to one side.
    belt = S.round_box(p - V((0.0, -0.17, 0.085)), V((0.215, 0.022, 0.012)), 0.006)
    tail = S.round_cone(p, V((0.20, -0.17, 0.05)), V((0.33, -0.26, 0.012)), 0.014, 0.012)
    buckle = S.round_box(p - V((-0.04, -0.17, 0.10)), V((0.028, 0.026, 0.010)), 0.004)
    d = np.minimum(d, np.minimum(np.minimum(belt, tail), buckle))
    # The neck, a shallow opening at the head of the shell.
    neck = S.ellipsoid(p - V((0.0, 0.215, 0.07)), V((0.095, 0.065, 0.075)))
    d = S.smax(d, -neck, 0.01)
    return S.smax(d, -p[:, 2], 0.006)


def lame_height(p):
    """The worn piece's lames (`build_worn._lames`), its body axis along Y:
    courses across the shell, each lapping the one toward the hem, joints
    staggered and two lace holes at each lame's head."""
    course, lame = 0.056, 0.026
    along = p[:, 1] + 0.30
    k = np.floor(along / course)
    down = along / course - k
    around = p[:, 0] + (k % 2.0) * lame * 0.5
    across = around / lame - np.floor(around / lame)
    joint = np.clip(1.0 - np.minimum(across, 1.0 - across) / 0.08, 0.0, 1.0)
    lace = np.clip(1.0 - np.abs(down - 0.82) / 0.06, 0.0, 1.0) \
        * np.clip(1.0 - np.abs(across - 0.5) / 0.10, 0.0, 1.0)
    return 0.0012 * (1.0 - down) - 0.0010 * joint - 0.0006 * lace + 0.00012 * S.noise(p, 0.004)


def material():
    m = bpy.data.materials.new("plate_iron")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    # The worn piece's warm Dvergar iron, the Hall-Warden's (`humanoid_detail`'s
    # `plate`), so plate on the floor is the plate on a back.
    bsdf.inputs["Base Color"].default_value = (0.235, 0.225, 0.19, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.72
    bsdf.inputs["Roughness"].default_value = 0.70
    m.diffuse_color = (0.235, 0.225, 0.19, 1.0)
    return m


def collision():
    """A plain box: `ART-006` forbids render-mesh colliders."""
    bpy.ops.mesh.primitive_cube_add(location=(0.0, 0.0, 0.06))
    box = bpy.context.object
    box.dimensions = (0.84, 0.66, 0.12)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    box.name = "collision-colonly"
    box.data.materials.append(material())
    K.ink(box, {"plate_iron": METAL})
    return box


## **Worked iron is cut, not grown** (the Hall-Warden's rule): edges turning
## more than this are hard, so the belt, the buckle and each course's step
## carry the outline pass's interior lines (`art_probe`'s split normals). Mail
## folds and needs none; plate is edges.
HARD_EDGE_DEGREES = 35.0


def harden(obj):
    import bmesh
    import math
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for edge in bm.edges:
        if edge.is_manifold and edge.calc_face_angle(0.0) > math.radians(HARD_EDGE_DEGREES):
            edge.smooth = False
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    plate = K.mesh_field("dvergar_plate", cuirass, BOUNDS[0], BOUNDS[1], VOXEL, material())
    K.outward(plate)
    K.decimate(plate, TRIS)
    harden(plate)
    K.unwrap(plate, 0.003)
    normal = K.bake(plate, TEXTURE, lambda points, _n, _f: lame_height(points),
                    "dvergar_plate_n", None, cuirass)
    K.with_normal_map(plate.data.materials[0], normal)
    K.ink(plate, {"plate_iron": METAL})
    return plate


def review(plate):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.render.resolution_x, scene.render.resolution_y = 900, 700
    scene.world = bpy.data.worlds.new("hall")
    scene.world.color = (0.05, 0.05, 0.05)
    from mathutils import Vector
    for loc, energy in (((-1.0, -1.2, 1.6), 70), ((1.2, 0.6, 0.9), 22)):
        bpy.ops.object.light_add(type="AREA", location=loc)
        light = bpy.context.object
        light.data.energy, light.data.size = energy, 1.0
        light.rotation_euler = (Vector((0, 0, 0)) - light.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(0.30, -1.05, 0.90))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 45
    scene.camera = camera
    scene.render.filepath = str(SRC / "dvergar_plate_review.png")
    bpy.ops.render.render(write_still=True)


def main():
    plate = build()
    tris = K.triangles(plate)
    # `ART-006`: props, 3,000.
    assert tris <= 3000, tris
    box = collision()
    box.hide_render = True
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "dvergar_plate.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    plate.select_set(True)
    box.select_set(True)
    bpy.context.view_layer.objects.active = plate
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / "dvergar_plate.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True,
        export_tangents=True, export_image_format="AUTO")
    report = {"asset": "dvergar_plate", "triangles": tris, "textures": {"dvergar_plate_n": TEXTURE}}
    (SRC / "dvergar_plate_measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    review(plate)
    print(json.dumps(report))


if __name__ == "__main__":
    main()
