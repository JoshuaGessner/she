"""Build Ótr's Pelt as it lies on a floor — one sculpted mesh (ADR-327).

Run with:
    Blender --background --factory-startup --python-exit-code 1 --python build_otr_pelt_item.py

**What it replaces.** `build_items.pelt` lofted a scalloped star of hide with
four flat discs for paws and an icosphere for a head: from across a room it
read as a starfish, and this is *the* relic — the otter-skin the gods filled
and covered with gold to pay for Ótr (*Reginsmál*, *Völsunga saga*), the first
treasure in the story every other treasure in this game descends from.

**What it is.** An otter's skin laid out flat, fur up, as a skin is when it
has been taken whole: the long body, the broad flat head with its small round
ears and blunt muzzle, four short legs splayed with their webbed feet, and the
thick tail that tapers to a point — an otter's, the one part no other skin
has. Slumped a little where it was dropped. The fur is baked into a normal
map, lying down the body as fur lies; colour is flat per region (ADR-321):
the otter's dark brown, darker feet, and a black nose. The worn pelt's
colours (ADR-318), so the relic in the hand and on the floor is one skin.

Blender coordinates, Z up: the head toward +Y, lying on z = 0.
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
OUT = Path(os.environ.get("PELT_OUT", str(ROOT / "game/art/props")))
sys.path.insert(0, str(SRC.parent / "lib"))
import sdf_sculpt as S  # noqa: E402
import blender_bake as K  # noqa: E402

VOXEL = 0.006
TRIS = 2800
TEXTURE = 2048
BOUNDS = ((-0.50, -0.80, -0.02), (0.50, 0.66, 0.12))
## Ink metadata for organic matter (`ART-006` §2.3).
ORGANIC = 0.8
FUR = (0.15, 0.105, 0.062)
FEET = (0.085, 0.060, 0.038)
NOSE = (0.035, 0.030, 0.027)
V = lambda t: np.asarray(t, float)  # noqa: E731


def _flat(d_of, p, squash):
    """A shape in a space squashed by `squash` in z: a body lying flat."""
    q = p * np.array([1.0, 1.0, squash])
    return d_of(q) / squash


def parts(p):
    """Each region's field: the skin and the parts coloured apart from it."""
    z = V((1.0, 1.0, 2.5))
    # The body: long and a little waisted, narrowing to a neck behind the
    # head and widest across the haunches, lying a few fingers high.
    body = _flat(lambda q: S.chain(q, [V((0.0, 0.36, 0.03)) * z, V((0.0, 0.26, 0.035)) * z,
                                       V((0.0, 0.06, 0.04)) * z, V((0.0, -0.14, 0.04)) * z,
                                       V((0.0, -0.30, 0.035)) * z],
                                   [0.085, 0.14, 0.16, 0.165, 0.13], 0.06), p, 2.5)
    # The head: a whole skin keeps its skull — broad and flat-topped, standing
    # clear of the hide, with a blunt muzzle and small round ears.
    head = S.ellipsoid(p - V((0.0, 0.46, 0.050)), V((0.088, 0.092, 0.052)))
    head = S.smin(head, S.ellipsoid(p - V((0.0, 0.555, 0.042)), V((0.052, 0.058, 0.036))), 0.03)
    for sx in (-1.0, 1.0):
        head = S.smin(head, S.sphere(p - V((0.072 * sx, 0.43, 0.085)), 0.017), 0.008)
        # An eye's hollow, so the face reads.
        head = S.carve(head, S.sphere(p - V((0.045 * sx, 0.515, 0.080)), 0.011), 0.004)
    body = S.smin(body, head, 0.035)
    # Legs short and thick, splayed out flat, as an otter's are; the feet
    # webbed and toed.
    feet = np.full(len(p), 1e3)
    for sx in (-1.0, 1.0):
        for root, tip, size in (((0.10, 0.24), (0.25, 0.31), 0.044),
                                ((0.11, -0.20), (0.27, -0.30), 0.052)):
            a = V((root[0] * sx, root[1], 0.03))
            b = V((tip[0] * sx, tip[1], 0.022))
            leg = _flat(lambda q: S.round_cone(q, a * z, b * z, 0.060, 0.045), p, 2.5)
            body = S.smin(body, leg, 0.04)
            out = (b - a) * V((1.0, 1.0, 0.0))
            out = out / np.linalg.norm(out)
            side = V((-out[1], out[0], 0.0))
            c = b + out * 0.035 + V((0.0, 0.0, -0.006))
            foot = S.ellipsoid(p - c, V((size, size, 0.016)))
            for k in (-1.5, -0.5, 0.5, 1.5):
                toe = c + out * size * 0.85 + side * k * size * 0.42
                foot = S.smin(foot, S.sphere(p - toe, size * 0.26), 0.01)
            feet = np.minimum(feet, foot)
    # The tail: thick at the root, tapering to a point, laid in a slight curve.
    tail = _flat(lambda q: S.chain(q, [V((0.0, -0.36, 0.035)) * z, V((0.03, -0.50, 0.030)) * z,
                                       V((0.07, -0.63, 0.024)) * z, V((0.08, -0.74, 0.016)) * z],
                                   [0.080, 0.058, 0.034, 0.010], 0.03), p, 2.5)
    body = S.smin(body, tail, 0.04)
    # Slumped where it was dropped: a fold or two across the back.
    body = body - 0.008 * np.sin(p[:, 1] * 17.0 + 4.0 * S.fbm(p, 0.20, 2)) * np.clip(p[:, 2] / 0.03, 0, 1)
    body = body - 0.004 * S.fbm(p, 0.08, 2)
    nose = S.ellipsoid(p - V((0.0, 0.612, 0.050)), V((0.024, 0.015, 0.016)))
    floor = -p[:, 2]
    return {"fur": S.smax(body, floor, 0.006), "feet": S.smax(feet, floor, 0.004),
            "nose": nose}


def field(p):
    r = parts(p)
    return np.minimum(np.minimum(r["fur"], r["feet"]), r["nose"])


def fur_height(p):
    # Fur lies down the body, toward the tail: soft streaks running with it,
    # and clumps — the worn pelt's (`build_worn._fur`), turned to lie along Y.
    return 0.0016 * S.fbm(p * np.array([1.0, 0.3, 1.0]), 0.02, 2) + 0.0008 * S.noise(p, 0.012)


def colour_at(points, _nearest, _face):
    r = parts(points)
    which = np.argmin(np.stack([r["fur"], r["feet"], r["nose"]], axis=1), axis=1)
    out = np.empty((len(points), 3))
    out[which == 0] = FUR
    out[which == 1] = FEET
    out[which == 2] = NOSE
    return out


def material():
    m = bpy.data.materials.new("otr_fur")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*FUR, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    m.diffuse_color = (*FUR, 1.0)
    return m


def collision():
    """A plain box: `ART-006` forbids render-mesh colliders."""
    bpy.ops.mesh.primitive_cube_add(location=(0.0, -0.07, 0.04))
    box = bpy.context.object
    box.dimensions = (0.84, 1.40, 0.08)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    box.name = "collision-colonly"
    box.data.materials.append(material())
    K.ink(box, {"otr_fur": ORGANIC})
    return box


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    pelt = K.mesh_field("otr_pelt", field, BOUNDS[0], BOUNDS[1], VOXEL, material())
    K.outward(pelt)
    K.decimate(pelt, TRIS)
    K.unwrap(pelt, 0.003)
    normal, colour = K.bake(pelt, TEXTURE, lambda points, _n, _f: fur_height(points),
                            "otr_pelt_n", colour_at, field)
    K.with_colour_map(pelt.data.materials[0], colour)
    K.with_normal_map(pelt.data.materials[0], normal)
    K.ink(pelt, {"otr_fur": ORGANIC})
    return pelt


def review():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.render.resolution_x, scene.render.resolution_y = 900, 700
    scene.world = bpy.data.worlds.new("hall")
    scene.world.color = (0.05, 0.05, 0.05)
    from mathutils import Vector
    for loc, energy in (((-1.0, -1.2, 1.6), 120), ((1.2, 0.6, 0.9), 40)):
        bpy.ops.object.light_add(type="AREA", location=loc)
        light = bpy.context.object
        light.data.energy, light.data.size = energy, 1.0
        light.rotation_euler = (Vector((0, 0, 0)) - light.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(0.55, -1.35, 1.15))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, -0.05, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 40
    scene.camera = camera
    scene.render.filepath = str(SRC / "otr_pelt_review.png")
    bpy.ops.render.render(write_still=True)


def main():
    pelt = build()
    tris = K.triangles(pelt)
    # `ART-006`: props, 3,000.
    assert tris <= 3000, tris
    box = collision()
    box.hide_render = True
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "otr_pelt.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    pelt.select_set(True)
    box.select_set(True)
    bpy.context.view_layer.objects.active = pelt
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / "otr_pelt.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True,
        export_tangents=True, export_image_format="AUTO")
    report = {"asset": "otr_pelt", "triangles": tris,
              "textures": {"otr_pelt_n": TEXTURE, "otr_pelt_c": TEXTURE}}
    (SRC / "otr_pelt_measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    review()
    print(json.dumps(report))


if __name__ == "__main__":
    main()
