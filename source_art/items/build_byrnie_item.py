"""Build the Mail Byrnie as it lies on a floor — one sculpted mesh (ADR-323).

Run with:
    Blender --background --factory-startup --python-exit-code 1 --python build_byrnie_item.py

**What it replaces.** `build_items.byrnie` stood the shirt up as a rigid shell
with barrel sleeves, as if on a mannequin nobody else could see, and drew its
mail as a few dozen hexagonal studs. Mail is the softest metal there is: a
shirt of it put down slumps flat, the sleeves fall where they lie, and the
rings bunch into folds. Without the rings it is plastic; with them as geometry
it is ten thousand tori.

**What it is.** The byrnie of the Gjermundbu find — hip-length, elbow-length
sleeves, a slit at the front of the skirt for the saddle — lying on its back,
sculpted as one mesh, with the rings baked into a normal map as the worn
byrnie draws them (`humanoid_detail._mail`, ADR-317): courses of arcs hanging
toward the hem. One flat iron material, as every prop has (`ART-006`); the
normal map is ADR-321's per-asset map, which ADR-323 allows a prop too soft
to model as parts.

Blender coordinates, Z up: the neck toward +Y, the hem toward −Y, lying on
z = 0. The exporter turns it Y-up for Godot.
"""
from __future__ import annotations

import json
import math
import os
import sys
from pathlib import Path

import bpy
import numpy as np

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = Path(os.environ.get("BYRNIE_OUT", str(ROOT / "game/art/props")))
sys.path.insert(0, str(SRC.parent / "lib"))
import sdf_sculpt as S  # noqa: E402
import blender_bake as K  # noqa: E402

VOXEL = 0.007
TRIS = 2800
TEXTURE = 2048
BOUNDS = ((-0.62, -0.50, -0.02), (0.62, 0.50, 0.16))
## Ink metadata for metal (`ART-006` §2.3).
METAL = 0.4
V = lambda t: np.asarray(t, float)  # noqa: E731


def _flat(d_of, p, squash):
    """A shape in a space squashed by `squash` in z, so a round limb lies flat
    the way a sleeve of mail does under its own weight."""
    q = p * np.array([1.0, 1.0, squash])
    return d_of(q) / squash


def shirt(p):
    """The byrnie lying on its back: body, sleeves, slumped into folds."""
    # The body: front and back lying together, a little fuller at the chest
    # where the two layers do not quite meet.
    body = _flat(lambda q: S.round_box(q - V((0, -0.02, 0.02 * 2.4)),
                                       V((0.24, 0.36, 0.012 * 2.4)), 0.03), p, 2.4)
    chest = _flat(lambda q: S.ellipsoid(q - V((0, 0.12, 0.022 * 3.0)),
                                        V((0.22, 0.16, 0.03 * 3.0))), p, 3.0)
    d = S.smin(body, chest, 0.03)
    # The hem spreads a little where the skirt lies open.
    skirt = _flat(lambda q: S.round_box(q - V((0, -0.30, 0.012 * 2.4)),
                                        V((0.27, 0.08, 0.010 * 2.4)), 0.03), p, 2.4)
    d = S.smin(d, skirt, 0.05)
    # Sleeves: elbow length, falling outward and a little down from the
    # shoulders, flattened.
    for side in (-1.0, 1.0):
        a = V((side * 0.20, 0.25, 0.022))
        b = V((side * 0.43, 0.10, 0.018))
        sleeve = _flat(lambda q: S.round_cone(q, a * V((1, 1, 2.6)), b * V((1, 1, 2.6)),
                                              0.088, 0.080), p, 2.6)
        d = S.smin(d, sleeve, 0.04)
    # Slumped into folds: mail drapes in long soft ridges and bunches.
    ridges = 0.011 * np.sin(p[:, 0] * 22.0 + p[:, 1] * 6.0 + 9.0 * S.fbm(p, 0.25, 2)) * np.clip(p[:, 2] / 0.03, 0, 1)
    d = d - ridges - 0.010 * S.fbm(p, 0.09, 2)
    # Where it was dropped, the mail heaped on itself.
    for c, r in (((0.10, -0.10, 0.03), (0.13, 0.09, 0.035)), ((-0.14, 0.04, 0.028), (0.09, 0.12, 0.03))):
        d = S.smin(d, S.ellipsoid(p - V(c), V(r)), 0.05)
    # Cut after the folds, so no fold stands up as a sliver at an edge.
    # The neck: a round opening with a slit down the front.
    neck = S.ellipsoid(p - V((0, 0.34, 0.03)), V((0.085, 0.085, 0.06)))
    slit = S.round_box(p - V((0, 0.21, 0.03)), V((0.010, 0.07, 0.06)), 0.004)
    d = S.smax(d, -np.minimum(neck, slit) + 0.0, 0.008)
    # The skirt's slit at the front of the hem.
    split = S.round_box(p - V((0, -0.37, 0.02)), V((0.010, 0.10, 0.06)), 0.006)
    d = S.smax(d, -split, 0.01)
    return S.smax(d, -p[:, 2], 0.006)


def ring_height(p):
    """Courses of arcs hanging toward the hem, as the worn byrnie draws mail."""
    return S.scale_height(p, 0.016, 0.0016, (0.0, -1.0, 0.0))


def material():
    m = bpy.data.materials.new("byrnie_mail")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    # `build_items`' metal, so a byrnie on the floor is the iron beside it.
    bsdf.inputs["Base Color"].default_value = (0.23, 0.23, 0.23, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.72
    bsdf.inputs["Roughness"].default_value = 0.82
    m.diffuse_color = (0.23, 0.23, 0.23, 1.0)
    return m


def collision():
    """A plain box: `ART-006` forbids render-mesh colliders."""
    bpy.ops.mesh.primitive_cube_add(location=(0.0, 0.0, 0.05))
    box = bpy.context.object
    box.dimensions = (1.10, 0.84, 0.10)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    box.name = "collision-colonly"
    box.data.materials.append(material())
    K.ink(box, {"byrnie_mail": METAL})
    return box


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    mail = K.mesh_field("mail_byrnie", shirt, BOUNDS[0], BOUNDS[1], VOXEL, material())
    K.outward(mail)
    K.decimate(mail, TRIS)
    K.unwrap(mail, 0.003)
    normal = K.bake(mail, TEXTURE, lambda points, _n, _f: ring_height(points),
                    "mail_byrnie_n", None, shirt)
    K.with_normal_map(mail.data.materials[0], normal)
    K.ink(mail, {"byrnie_mail": METAL})
    return mail


def review(mail):
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
    bpy.ops.object.camera_add(location=(0.35, -1.25, 1.05))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 45
    scene.camera = camera
    scene.render.filepath = str(SRC / "mail_byrnie_review.png")
    bpy.ops.render.render(write_still=True)


def main():
    mail = build()
    tris = K.triangles(mail)
    # `ART-006`: props, 3,000.
    assert tris <= 3000, tris
    box = collision()
    box.hide_render = True
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "mail_byrnie.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    mail.select_set(True)
    box.select_set(True)
    bpy.context.view_layer.objects.active = mail
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / "mail_byrnie.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True,
        export_tangents=True, export_image_format="AUTO")
    report = {"asset": "mail_byrnie", "triangles": tris, "textures": {"mail_byrnie_n": TEXTURE}}
    (SRC / "mail_byrnie_measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    review(mail)
    print(json.dumps(report))


if __name__ == "__main__":
    main()
