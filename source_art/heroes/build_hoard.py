"""Build the hoard's mound — the heap of coin under everything in her Chamber (ADR-320).

Run with:
    Blender --background --factory-startup --python-exit-code 1 --python build_hoard.py

**What it replaces.** ADR-284 put loose coin under the hoard's pieces as a
`SphereMesh` hemisphere: a smooth gold dome, the one shape in the game a
treasure-heap never is. Fáfnir lies on his gold (`DES-006`), and the pile is
the reason for every descent; it has to read as *coin* from the door.

**What it is.** A heap as coin settles: a low cone of slumped sub-heaps, its
rim slipping out into drifts across the floor, with a few things the gold has
swallowed breaking its line — a goblet on its side, a crown, a sword driven in
to the hilt, a shield on its rim, a helm, two ingots — the inventory of every
hoard in the sagas and of the Hoxne and Cuerdale hoards in the ground. The
coin itself is too fine for any mesh: struck faces, packed and overlapping,
are baked into a normal map. The gold is one flat material (`ART-006`):
the hollows between coins are the ink's to darken, by the light.

The Chamber scales it with the hoard's value (`chamber._rebuild_hoard`) and
gives it the hoard's gold; this is the shape and the surface. Authored one
unit across and `RISE` tall.
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
OUT = Path(os.environ.get("HOARD_OUT", str(ROOT / "game/art/heroes")))
sys.path.insert(0, str(SRC.parent / "lib"))
import sdf_sculpt as S  # noqa: E402
import blender_bake as K  # noqa: E402

## The mound's height at one unit across; the Chamber scales from it.
RISE = 0.40
VOXEL = 0.010
TRIS = 14000
TEXTURE = 2048
BOUNDS = ((-1.35, -1.35, -0.02), (1.35, 1.35, 0.85))
V = lambda t: np.asarray(t, float)  # noqa: E731


def heap(p):
    """The coin: a slumped cone, drifts at its rim, lumpy."""
    # Coin settles at its angle of repose, about 30°: a cone with its top
    # rounded, not a dome — a dome's sides stand up like a cake's. Poured in
    # many loads, its height undulates; loads modelled as lumps of their own
    # overhung its slope as ledges.
    r = np.hypot(p[:, 0], p[:, 1])
    flat = p * np.array([1.0, 1.0, 0.0])
    swell = 1.0 + 0.16 * S.fbm(flat, 0.55, 2)
    d = (p[:, 2] - RISE * (1.0 - np.minimum(r, 1.6) ** 1.4) * swell) * 0.8
    # Drifts: coin that slid off the rim, short and low, as coin lies.
    for k in range(11):
        a = k * math.tau / 11 + 0.37 * math.sin(k * 2.3)
        reach = 0.95 + 0.08 * math.sin(k * 1.7)
        c = V((math.cos(a) * reach, math.sin(a) * reach, 0.0))
        q = S.into(p, S.move(c) @ S.rot((0, 0, 1), math.degrees(a)))
        d = S.smin(d, S.ellipsoid(q, V((0.16, 0.11, 0.05))), 0.08)
    d = d + 0.018 * S.fbm(p, 0.16, 2)
    return S.smax(d, -p[:, 2], 0.01)


## The swallowed pieces' size against the heap ⟨tune⟩: large enough to read from
## the door as a cup, a crown, a sword, not as bumps.
PIECE = 1.6


def _framed(p, frame):
    """Points in a piece's frame, at `PIECE` scale."""
    return S.into(p, frame) / PIECE


def treasures(p):
    """What the gold has swallowed, each half under it."""
    d = np.full(len(p), 1e3)
    # A goblet on its side, its mouth toward the door.
    q = _framed(p, S.move((0.30, -0.44, 0.27)) @ S.rot((1, 0, 0), 80.0) @ S.rot((0, 1, 0), 25.0))
    cup = S.carve(S.round_cone(q, V((0, 0, 0.0)), V((0, 0, 0.13)), 0.035, 0.065),
                  S.round_cone(q, V((0, 0, 0.03)), V((0, 0, 0.15)), 0.025, 0.055), 0.004)
    stem = S.round_cone(q, V((0, 0, -0.10)), V((0, 0, 0.0)), 0.012, 0.016)
    foot = S.round_box(q - V((0, 0, -0.105)), V((0.045, 0.045, 0.006)), 0.005)
    d = np.minimum(d, S.smin(S.smin(cup, stem, 0.01), foot, 0.008) * PIECE)
    # A crown, tipped, its points up.
    q = _framed(p, S.move((-0.34, 0.04, 0.31)) @ S.rot((1, 0, 0), 22.0) @ S.rot((0, 1, 0), -14.0))
    crown = S.torus(q, 0.11, 0.016)
    for k in range(7):
        a = k * math.tau / 7
        base = V((math.cos(a) * 0.11, math.sin(a) * 0.11, 0.0))
        crown = S.smin(crown, S.round_cone(q, base, base + V((0, 0, 0.07)), 0.016, 0.004), 0.006)
    d = np.minimum(d, crown * PIECE)
    # A sword driven in to its hilt.
    q = _framed(p, S.move((0.06, 0.34, 0.46)) @ S.rot((1, 0, 0), -14.0) @ S.rot((0, 1, 0), 9.0))
    sword = S.round_box(q - V((0, 0, -0.20)), V((0.022, 0.006, 0.22)), 0.004)
    sword = np.minimum(sword, S.round_box(q - V((0, 0, 0.03)), V((0.10, 0.016, 0.012)), 0.006))
    sword = np.minimum(sword, S.round_cone(q, V((0, 0, 0.04)), V((0, 0, 0.15)), 0.014, 0.012))
    sword = np.minimum(sword, S.sphere(q - V((0, 0, 0.17)), 0.026))
    d = np.minimum(d, sword * PIECE)
    # A round shield on its rim, leaning into the heap.
    q = _framed(p, S.move((0.70, 0.34, 0.28)) @ S.rot((0, 0, 1), -35.0) @ S.rot((1, 0, 0), 62.0))
    shield = np.maximum(np.hypot(q[:, 0], q[:, 1]) - 0.30, np.abs(q[:, 2]) - 0.010) - 0.004
    shield = S.smin(shield, S.ellipsoid(q - V((0, 0, 0.02)), V((0.07, 0.07, 0.04))), 0.01)
    shield = S.smin(shield, S.torus(q - V((0, 0, 0.004)), 0.29, 0.012), 0.004)
    d = np.minimum(d, shield * PIECE)
    # A helm, crown-down in the coin.
    q = _framed(p, S.move((-0.60, -0.30, 0.24)) @ S.rot((1, 0, 0), 150.0))
    helm = S.carve(S.ellipsoid(q, V((0.10, 0.12, 0.11))), S.ellipsoid(q, V((0.088, 0.108, 0.098))), 0.003)
    helm = S.smax(helm, -q[:, 2] - 0.0, 0.005)
    d = np.minimum(d, helm * PIECE)
    # Two ingots on the slope.
    for c, a in (((-0.12, -0.64, 0.16), 20.0), ((0.50, 0.02, 0.30), -40.0)):
        q = S.into(p, S.move(c) @ S.rot((0, 0, 1), a) @ S.rot((1, 0, 0), 12.0))
        d = np.minimum(d, S.round_box(q, V((0.09, 0.04, 0.025)), 0.010))
    return d


def field(p):
    return np.minimum(heap(p), treasures(p))


## A coin's size at one unit across ⟨tune⟩; the Chamber scales it with the heap.
COIN = 0.030


def _coins(p, size, depth):
    """One layer of round coins: a disc at each scattered point, its face a
    plateau with a raised rim, and a gap between it and the next."""
    f1, _f2, _off = S.cells(p, size, 0.85)
    disc = np.clip((0.46 - f1) / 0.05, 0.0, 1.0)
    rim = np.exp(-((f1 - 0.39) / 0.035) ** 2)
    face = 0.10 * S.noise(p, size * 0.3)
    return depth * disc * (0.72 + 0.28 * rim + face)


def coin_height(p, on_coin):
    """Struck coins in three overlapping layers, each sitting on the last, so
    the surface is coin lying on coin rather than a pavement of cells."""
    h = _coins(p, COIN, 0.0045)
    h = np.maximum(h, _coins(p + 0.37 * COIN, COIN * 1.12, 0.0045) - 0.0012)
    h = np.maximum(h, _coins(p - 0.61 * COIN, COIN * 0.92, 0.0045) - 0.0024)
    return np.where(on_coin, h, 0.0)


def material():
    m = bpy.data.materials.new("hoard_coin")
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (0.86, 0.67, 0.22, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.85
    bsdf.inputs["Roughness"].default_value = 0.3
    return m


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # No `.blend1` beside the source: the build is the history.
    bpy.context.preferences.filepaths.save_version = 0
    mound = K.mesh_field("hoard_mound", field, BOUNDS[0], BOUNDS[1], VOXEL, material())
    K.outward(mound)
    K.decimate(mound, TRIS)
    K.unwrap(mound, 0.003)

    def is_coin(points):
        return heap(points) < treasures(points)

    def height_at(points, _nearest, _face):
        return coin_height(points, is_coin(points))

    normal = K.bake(mound, TEXTURE, height_at, "hoard_mound_n", None, field)
    K.with_normal_map(mound.data.materials[0], normal)
    # Gold is the ink's own class (`ART-005`, ADR-269).
    K.ink(mound, {"hoard_coin": 1.0})
    return mound


def review():
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.render.resolution_x, scene.render.resolution_y = 1100, 700
    scene.world = bpy.data.worlds.new("hall")
    scene.world.color = (0.03, 0.03, 0.03)
    from mathutils import Vector
    for loc, energy in (((-1.5, -2.5, 2.0), 900), ((2.0, -0.5, 1.2), 300)):
        bpy.ops.object.light_add(type="AREA", location=loc)
        light = bpy.context.object
        light.data.energy, light.data.size = energy, 2.0
        light.rotation_euler = (Vector((0, 0, 0.1)) - light.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(0.0, -2.6, 1.0))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, 0.12)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 40
    scene.camera = camera
    scene.render.filepath = str(SRC / "hoard_mound_review.png")
    bpy.ops.render.render(write_still=True)


def main():
    mound = build()
    tris = K.triangles(mound)
    assert tris <= 40000, tris
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "hoard_mound.blend"))
    K.select_only(mound)
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / "hoard_mound.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True,
        export_tangents=True, export_image_format="AUTO")
    report = {"asset": "hoard_mound", "triangles": tris, "units": "one unit across",
              "rise": RISE, "textures": {"hoard_mound_n": TEXTURE}}
    (SRC / "hoard_mound_measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    review()
    print(json.dumps(report))


if __name__ == "__main__":
    main()
