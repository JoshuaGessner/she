"""Build Her — the hoard-wyrm in her Chamber (ADR-315, ADR-298, `DES-006`, ADR-050).

Run with:
    Blender --background --factory-startup --python-exit-code 1 --python build_her.py

## What she is

An **ormr**: the serpent-dragon of the Norse sources, wingless, long, coiled
round her gold, and fused into the mountain she cannot leave (`DES-001`). The
references and what each gives her are in the modules this builds from:
`her_head_sdf` (the head), `her_body_sdf` (the pose and the body), `her_body`
(the bands' carving) and `her_detail` (what is baked into her surface).

## How she is made — sculpted, not swept (ADR-315)

ADR-298 swept tubes along curves and stuck them together, and from every angle
she read as hose: no join between two parts was ever a join, only an overlap.
She is now **sculpted as signed distance fields** (`source_art/lib/sdf_sculpt`):
every part is blended into the next like clay, so a foreleg grows out of the
chest and a neck out of the shoulders, and where she goes into the wall or the
floor she is cut by it, flush.

The game mesh is that field meshed and decimated to her budget; everything too
fine for the budget — scales, the Urnes double contour, belly scutes, the lip's
engraved scroll — is **baked into a tangent-space normal map** from height
functions evaluated at every texel. ADR-259 established that the ink pass draws
what a normal map says, so the carving is drawn as line, not lost.

## Where she lies

Authored with her forward along Blender -Y (glTF exports that as Godot +Z), so
in the Chamber she faces the door you come in by, and her origin is the centre
of the hoard. The back wall's face is at y = 2.7, the piers at x = ±7.25, the
braziers at (±5.6, -1.4).

Materials: `her` (the hide, recoloured by the Chamber every visit — ADR-050's
slow fusing into the stone — with its normal map kept), `her_plate` (the
crest, plain), `eye` (gold, emissive) and `eye_slit` (the pupil). The Chamber
leaves any material named `eye…` alone.
"""
import json
import math
import os
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
sys.path.insert(0, str(SRC.parent / "lib"))
sys.path.insert(0, str(SRC))
import sdf_sculpt as S  # noqa: E402
import blender_bake as K  # noqa: E402
import her_body as B  # noqa: E402
import her_body_sdf as BODY  # noqa: E402
import her_detail as D  # noqa: E402
import her_head_sdf as H  # noqa: E402

OUT = Path(os.environ.get("HER_OUT", str(ROOT / "game/art/heroes")))
REVIEW = Path(os.environ.get("HER_REVIEW", str(SRC)))
NAME = "her"

## Mesh density before decimation, and the budget after (ART-004's hero
## ceiling is 40,000 triangles; these leave room for the crest and eyes).
BODY_VOXEL = 0.03
HEAD_VOXEL = 0.011
BODY_TRIS = 22000
HEAD_TRIS = 12000
EYE_TRIS = 700
## Normal and region map sizes.
BODY_TEXTURE = 4096
HEAD_TEXTURE = 2048

COLOURS = {"her": (0.32, 0.26, 0.22, 1.0), "her_plate": (0.30, 0.25, 0.21, 1.0),
           "eye": (0.95, 0.62, 0.12, 1.0), "eye_slit": (0.02, 0.015, 0.01, 1.0)}


log = K.log


# ── Materials ────────────────────────────────────────────────────────────

def material(kind):
    m = bpy.data.materials.get(kind) or bpy.data.materials.new(kind)
    colour = COLOURS[kind]
    m.diffuse_color = colour
    m.use_nodes = True
    nodes = m.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Roughness"].default_value = 0.25 if kind.startswith("eye") else 0.85
    if kind == "eye":
        bsdf.inputs["Emission Color"].default_value = colour
        bsdf.inputs["Emission Strength"].default_value = 1.5
    m.use_backface_culling = True
    return m


# ── The crest ────────────────────────────────────────────────────────────

def crest():
    """Carved plates down her spine, larger over the shoulders, none where
    she goes into the wall or the floor."""
    verts, faces = [], []
    for name, path, radii in BODY.bands():
        pts, s = B.resample(path, 0.36 if name != "tail" else 0.30)
        t, side, up = B.frames(pts)
        r = np.interp(s, np.linspace(0.0, s[-1], len(radii)), radii)
        for i in range(1, len(pts) - 1):
            top = pts[i] + up[i] * r[i] * 0.97
            if top[1] > BODY.WALL_Y - 0.15 or top[2] < 0.25 or r[i] < 0.12:
                continue
            # None where the spine turns under, round her tail's curl: a
            # plate there would stand into the coil inside it.
            if up[i][2] < 0.5:
                continue
            # A slow swell and fall down the row, so it is a row of carved
            # blades rather than one blade stamped.
            swell = 1.0 + 0.16 * math.sin(i * 1.9) + 0.08 * math.sin(i * 0.7)
            if name == "body" and s[i] > s[-1] - 0.6:
                continue
            pv, pf = B.plate(top, t[i], up[i], 0.30 * r[i] + 0.10, (0.36 * r[i] + 0.06) * swell,
                             0.035 * r[i] + 0.012)
            faces += [tuple(k + len(verts) for k in f) for f in pf]
            verts += list(pv)
    plates = K.to_object("crest", np.array(verts), faces, material("her_plate"))
    # In triangles: a blade's face is concave, and a baked map's tangents
    # (and the glTF's) are only defined on triangles and quads.
    bm = bmesh.new()
    bm.from_mesh(plates.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method="BEAUTY", ngon_method="EAR_CLIP")
    bm.to_mesh(plates.data)
    bm.free()
    return plates


# ── Build ────────────────────────────────────────────────────────────────

def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    out = bpy.context.view_layer.objects.active
    out.name = name
    return out


def transform(obj, matrix):
    m = np.asarray(matrix)
    co = np.array([v.co for v in obj.data.vertices])
    co = co @ m[:3, :3].T + m[:3, 3]
    obj.data.vertices.foreach_set("co", co.ravel())
    obj.data.update()


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    bands = D.Bands()

    # The head, in its own frame first: it is baked there.
    head = K.mesh_field("head", lambda p: H.field(p, False), H.BOUNDS[0], H.BOUNDS[1], HEAD_VOXEL, material("her"))
    K.outward(head)
    K.decimate(head, HEAD_TRIS)
    K.unwrap(head, 0.004)

    def head_at(points, _nearest, _face):
        mask = H.features(points) < H.skin(points) + 0.004
        return D.head_height(points, mask)

    head_nz = np.array([v.normal.z for v in head.data.vertices])

    def head_colour(points, nearest, _face):
        return D.head_value(points, head_nz[nearest])

    head_map, head_value = K.bake(head, HEAD_TEXTURE, head_at, "her_head_n", head_colour,
                                  lambda p: H.field(p, False))
    head.data.materials.clear()
    head.data.materials.append(material_with_map("her", head_map, "her_head_skin", head_value))
    eyes = K.mesh_field("eyes", H.eyes, H.BOUNDS[0], H.BOUNDS[1], 0.008, material("eye"))
    pupils = K.mesh_field("pupils", H.pupils, H.BOUNDS[0], H.BOUNDS[1], 0.006, material("eye_slit"))
    for o in (eyes, pupils):
        K.outward(o)
        K.decimate(o, EYE_TRIS if o is eyes else EYE_TRIS // 3)
        K.unwrap(o, 0.01)
    for o in (head, eyes, pupils):
        transform(o, BODY.head_frame())
        K.ink(o)
    skull = join([head, eyes, pupils], "her_head")

    # The body, in the world's frame.
    body = K.mesh_field("body", BODY.skin, BODY.BOUNDS[0], BODY.BOUNDS[1], BODY_VOXEL, material("her"), sparse=True)
    K.outward(body)
    K.decimate(body, BODY_TRIS)
    K.unwrap(body, 0.002)
    vert_co = np.array([v.co for v in body.data.vertices])
    vert_band = bands.nearest(vert_co)

    def body_at(points, nearest, _face):
        return D.blend_band(bands, points, vert_band[nearest])

    body_map = K.bake(body, BODY_TEXTURE, body_at, "her_body_n", None, BODY.skin)
    body.data.materials.clear()
    body.data.materials.append(material_with_map("her", body_map, "her_body_skin"))
    plates = crest()
    K.outward(plates)
    K.unwrap(plates, 0.01)
    for o in (body, plates):
        K.ink(o)
    hide = join([body, plates], "her_body")
    return hide, skull


def material_with_map(kind, image, name, regions=None):
    """`her` with its baked normal map — and, for the head, its region map —
    under its own name so the head's and the body's maps stay apart; the
    Chamber recolours both."""
    m = K.with_normal_map(material(kind).copy(), image)
    m.name = name
    return with_value(m, regions) if regions is not None else m


def with_value(m, image):
    """A region map multiplied into the material's own colour (ADR-317,
    ADR-321): the glTF carries the colour as its factor and the map as its
    texture, and the Chamber swaps the factor for her lineage's colour."""
    nodes = m.node_tree.nodes
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    bsdf = nodes.get("Principled BSDF")
    factor, a, b = [s for s in mix.inputs if s.enabled]
    factor.default_value = 1.0
    a.default_value = tuple(bsdf.inputs["Base Color"].default_value)
    m.node_tree.links.new(tex.outputs["Color"], b)
    m.node_tree.links.new([o for o in mix.outputs if o.enabled][0], bsdf.inputs["Base Color"])
    return m


def clearance(skull):
    """How low her head comes over the way to the pile: the lowest point of it
    with |x| < 1.4, in front of the pile."""
    co = np.array([v.co for v in skull.data.vertices])
    way = (np.abs(co[:, 0]) < 1.4) & (co[:, 1] < -1.0)
    return float(co[way, 2].min()) if way.any() else 99.0


def solids():
    """**Her collision ships with her** (ART-004's `-convcolonly` suffix): a
    box round each stretch of band and one round each foreleg, which Godot's
    importer turns into solids. They were a hand-kept list in the Chamber
    (`HER_SHAPE`) that had to be redrawn every time she was. None of them is
    over the way to the pile, and none is up where only her neck and head are
    — a body walks under those."""
    boxes = []
    for name, path, radii in BODY.bands():
        pts, s = B.resample(path, 0.05)
        r = np.interp(s, np.linspace(0.0, s[-1], len(radii)), radii)
        n = 4 if name != "arch" else 2
        for k in range(n):
            pick = slice(k * len(pts) // n, (k + 1) * len(pts) // n + 1)
            lo = (pts[pick] - r[pick, None] * 0.85).min(axis=0)
            hi = (pts[pick] + r[pick, None] * 0.85).max(axis=0)
            lo[2] = max(lo[2], 0.0)
            hi[1] = min(hi[1], BODY.WALL_Y)
            if hi[2] - lo[2] < 0.3 or hi[1] - lo[1] < 0.3 or lo[2] > 2.2:
                continue
            boxes.append((lo, hi))
    for leg in BODY.LEGS.values():
        pts = np.array([leg["shoulder"], leg["elbow"], leg["wrist"], leg["hand"]])
        lo = pts.min(axis=0) - 0.30 * leg["size"]
        hi = pts.max(axis=0) + 0.30 * leg["size"]
        lo[2] = 0.0
        boxes.append((lo, hi))
    made = []
    for i, (lo, hi) in enumerate(boxes):
        assert not (lo[0] < 1.4 and hi[0] > -1.4 and lo[1] < -1.0 and lo[2] < 1.8), (lo, hi)
        bpy.ops.mesh.primitive_cube_add(location=tuple((lo + hi) * 0.5))
        box = bpy.context.object
        box.name = f"her_solid_{i}-convcolonly"
        box.scale = tuple((hi - lo) * 0.5)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        made.append(box)
    return made


def export():
    hide, skull = build()
    tris = K.triangles(hide) + K.triangles(skull)
    assert tris <= 40000, tris
    low = clearance(skull)
    top = float(np.array([v.co for v in skull.data.vertices])[:, 2].max())
    log(f"{tris} triangles; her head comes down to {low:.2f} m over the way in, up to {top:.2f} m")
    # Clear of a standing body under her, and of the 6 m ceiling over her.
    assert low >= 2.3, low
    assert top <= 5.85, top
    # The head turns about the top of the neck, so its origin is put there.
    bpy.context.scene.cursor.location = Vector(BODY.NECK_END)
    K.select_only(skull)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / (NAME + ".blend")))
    blocks = solids()
    bpy.ops.object.select_all(action="DESELECT")
    hide.select_set(True)
    skull.select_set(True)
    for box in blocks:
        box.select_set(True)
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT / (NAME + ".glb")), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=True, export_animations=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True,
        export_tangents=True, export_image_format="AUTO")
    report = {"asset": NAME, "triangles": tris, "units": "metres",
              "forward": "Blender -Y / Godot +Z", "origin": "centre of the hoard pile",
              "form": "ormr — sculpted as signed distance fields, carving baked to normal maps (ADR-315)",
              "textures": {"her_body_n": BODY_TEXTURE, "her_head_n": HEAD_TEXTURE,
                           "her_head_c": HEAD_TEXTURE},
              "head_clearance_m": round(low, 2),
              "nodes": {"her_body": "everything but the head",
                        "her_head": "pivoted at the top of the neck, %s" % [round(float(c), 3) for c in BODY.NECK_END],
                        "her_solid_N-convcolonly": "%d collision boxes" % len(blocks)}}
    (SRC / (NAME + "_measurements.json")).write_text(json.dumps(report, indent=2) + "\n")
    for box in blocks:
        bpy.data.objects.remove(box, do_unlink=True)
    review()
    return report


def review():
    """Her from the door, both quarters, above and kneeling at the pile,
    against her hall's walls, lit and with her carving shown."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.render.resolution_x = 960
    scene.render.resolution_y = 600
    scene.world = bpy.data.worlds.new("hall") if scene.world is None else scene.world
    scene.world.color = (0.05, 0.05, 0.05)
    stone = bpy.data.materials.new("stone")
    stone.diffuse_color = (0.42, 0.40, 0.37, 1)
    for name, size, at in (("back_wall", (16, 0.6, 7), (0, 3.0, 3.5)), ("floor", (16, 14, 0.2), (0, -3.0, -0.1))):
        bpy.ops.mesh.primitive_cube_add(location=at)
        wall = bpy.context.object
        wall.name = name
        wall.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
        wall.data.materials.append(stone)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=2.4, location=(0, 0, 0))
    hoard = bpy.context.object
    hoard.scale = (1, 1, 0.3)
    gold = bpy.data.materials.new("gold")
    gold.use_nodes = True
    gold.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (0.9, 0.6, 0.15, 1)
    gold.node_tree.nodes.get("Principled BSDF").inputs["Metallic"].default_value = 1.0
    hoard.data.materials.append(gold)
    for loc, energy in (((-4.0, -6.0, 6.0), 2500), ((5.6, -1.4, 1.6), 600), ((-5.6, -1.4, 1.6), 600),
                        ((0.0, -2.0, 1.0), 300)):
        bpy.ops.object.light_add(type="POINT", location=loc)
        bpy.context.object.data.energy = energy
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    scene.camera = camera
    camera.data.lens = 24
    for view, at, look in (("door", (0.0, -8.0, 1.6), (0, 0, 2.0)),
                           ("quarter_left", (-5.5, -6.5, 2.2), (0, 0, 1.8)),
                           ("quarter_right", (5.5, -6.5, 2.2), (0, 0, 1.8)),
                           ("above", (0.0, -7.0, 9.0), (0, 0, 0.5)),
                           ("head", (-0.6, -4.6, 2.4), (0.2, -1.6, 3.4))):
        camera.location = at
        camera.rotation_euler = (Vector(look) - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(REVIEW / f"{NAME}_review_{view}.png")
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    print(json.dumps(export(), indent=2))
