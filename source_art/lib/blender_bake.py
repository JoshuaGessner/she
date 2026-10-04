"""Blender side of the sculpt pipeline (ADR-315): field to game mesh, and the
carving baked onto it.

Shared by every sculpted asset — her, and the bodies on the shared rig — so
there is one mesher, one decimator, one unwrapper and one baker, and a fix to
any of them reaches all of them. `sdf_sculpt` is the pure-numpy half.

The bake is a **height-slope bake**: a height function (metres, out along the
surface normal) is evaluated at every texel either side of it along the
texel's tangent and bitangent, and the slope is written as a tangent-space
normal. The frame is **MikkTSpace**, interpolated per corner exactly as the
glTF carries it and Godot decodes it; a per-triangle frame disagreed with that
at every triangle edge and shattered the carving into facets.
"""
from __future__ import annotations

import math
import tempfile
import time
from pathlib import Path

import bpy
import numpy as np

import sdf_sculpt as S

## Gutter each island's colour is grown into, in texels.
DILATE = 6
## The step the slope is read with, metres.
SLOPE_STEP = 0.004


def log(*parts):
    print("[sculpt]", *parts, flush=True)


def to_object(name, verts, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(np.asarray(verts).tolist(), [], [list(f) for f in faces])
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(mat)
    for poly in data.polygons:
        poly.use_smooth = True
    return obj


def mesh_field(name, field, lo, hi, voxel, mat, sparse=False):
    t = time.time()
    if sparse:
        vals, lo3, h, _busy, _total = S.sample_sparse(field, lo, hi, voxel)
    else:
        vals, lo3, h = S.sample(field, lo, hi, voxel)
    v, q = S.surface_nets(vals, lo3, h)
    v = S.relax(v, q, 1, 0.3)
    log(f"meshed {name}: {len(q)} quads in {time.time() - t:.1f} s")
    return to_object(name, v, q, mat)


def select_only(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def outward(obj):
    """Every normal pointing out."""
    select_only(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")


def triangles(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def decimate(obj, target):
    have = triangles(obj)
    if have <= target:
        return
    select_only(obj)
    mod = obj.modifiers.new("budget", "DECIMATE")
    mod.ratio = target / have
    mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Decimation can fold a triangle over.
    outward(obj)
    log(f"decimated {obj.name}: {have} → {triangles(obj)} triangles")


def unwrap(obj, margin):
    select_only(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60.0), island_margin=margin,
                             area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    # Packed tight and turned to fit: smart projection alone left more than
    # half of a map empty.
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, margin=margin, shape_method="CONCAVE")
    bpy.ops.object.mode_set(mode="OBJECT")


def ink(obj, family=None):
    """`ART-006`'s ink metadata on every corner: R 1, G 0.5, and B the
    material family — per face, from `family[material name]` (default 0)."""
    data = obj.data
    layer = data.color_attributes.get("ink") or data.color_attributes.new(
        name="ink", type="FLOAT_COLOR", domain="CORNER")
    data.color_attributes.active_color = layer
    names = [m.name if m else "" for m in data.materials]
    family = family or {}
    for poly in data.polygons:
        b = family.get(names[poly.material_index] if poly.material_index < len(names) else "", 0.0)
        for li in poly.loop_indices:
            layer.data[li].color = (1.0, 0.5, b, 1.0)


def raster(obj, size):
    """Every covered texel of `obj`'s UV layout: position, the MikkTSpace
    frame, the face it lies on, and the corner it is nearest."""
    me = obj.data
    me.calc_loop_triangles()
    me.calc_tangents()
    uv_layer = me.uv_layers.active.data
    co = np.array([v.co for v in me.vertices])
    n_loops = len(me.loops)
    lt = np.empty(n_loops * 3)
    ln = np.empty(n_loops * 3)
    ls = np.empty(n_loops)
    me.loops.foreach_get("tangent", lt)
    me.loops.foreach_get("normal", ln)
    me.loops.foreach_get("bitangent_sign", ls)
    lt, ln = lt.reshape(-1, 3), ln.reshape(-1, 3)
    pos, nrm, tan, sgn, px, nearest, face = [], [], [], [], [], [], []
    for tri in me.loop_triangles:
        vi = np.array(tri.vertices)
        li = np.array(tri.loops)
        uv = np.array([uv_layer[k].uv for k in li]) * size - 0.5
        lo = np.clip(np.floor(uv.min(axis=0)).astype(int), 0, size - 1)
        hi = np.clip(np.ceil(uv.max(axis=0)).astype(int), 0, size - 1)
        if hi[0] < lo[0] or hi[1] < lo[1]:
            continue
        xs, ys = np.meshgrid(np.arange(lo[0], hi[0] + 1), np.arange(lo[1], hi[1] + 1))
        xs, ys = xs.ravel(), ys.ravel()
        a, b, c = uv
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-12:
            continue
        w0 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
        w1 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -1e-4) & (w1 >= -1e-4) & (w2 >= -1e-4)
        if not inside.any():
            continue
        w = np.stack([w0[inside], w1[inside], w2[inside]], axis=1)
        pos.append(w @ co[vi])
        nrm.append(w @ ln[li])
        tan.append(w @ lt[li])
        sgn.append(np.full(len(w), ls[li[0]]))
        px.append(np.stack([xs[inside], ys[inside]], axis=1))
        nearest.append(vi[np.argmax(w, axis=1)])
        face.append(np.full(len(w), tri.polygon_index))
    me.free_tangents()
    return (np.concatenate(pos), np.concatenate(nrm), np.concatenate(tan), np.concatenate(sgn),
            np.concatenate(px), np.concatenate(nearest), np.concatenate(face))


def tangent_frame(n, t, sign):
    """The frame a shader builds from interpolated corner data."""
    n = n / np.maximum(np.linalg.norm(n, axis=1), 1e-9)[:, None]
    t = t - n * np.einsum("ij,ij->i", t, n)[:, None]
    t /= np.maximum(np.linalg.norm(t, axis=1), 1e-9)[:, None]
    return n, t, np.cross(n, t) * sign[:, None]


def _dilated(img, filled, size):
    """Grow each island's colour into its gutter, so a mip or a filter never
    reads the empty colour across a seam."""
    for _ in range(DILATE):
        grow = np.zeros_like(img[:, :, :3])
        cnt = np.zeros((size, size))
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            grow += np.roll(np.roll(img[:, :, :3] * filled[:, :, None], dy, 0), dx, 1)
            cnt += np.roll(np.roll(filled, dy, 0), dx, 1)
        new = (~filled) & (cnt > 0)
        img[new, :3] = grow[new] / cnt[new][:, None]
        filled |= new
    return img


def _image(name, img, size, colour):
    image = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
    image.colorspace_settings.name = "sRGB" if colour else "Non-Color"
    image.pixels.foreach_set(img.ravel())
    # Saved beside the build, not in the tree: the glb carries the map.
    image.filepath_raw = str(Path(tempfile.gettempdir()) / f"{name}.png")
    image.file_format = "PNG"
    image.save()
    return image


## The step the sculpted surface's gradient is read with, metres.
FIELD_STEP = 0.0015
_TETRA = np.array([(1, -1, -1), (-1, -1, 1), (-1, 1, -1), (1, 1, 1)], float)


def field_normals(field, points, chunk=400000):
    """The sculpted surface's normal near each point: the field's gradient,
    from four evaluations on a tetrahedron (Quilez)."""
    out = np.empty_like(points)
    for s in range(0, len(points), chunk):
        p = points[s:s + chunk]
        g = np.zeros_like(p)
        for k in _TETRA:
            g += k * field(p + k * FIELD_STEP)[:, None]
        out[s:s + chunk] = g / np.maximum(np.linalg.norm(g, axis=1), 1e-12)[:, None]
    return out


def bake(obj, size, height_at, name, colour_at=None, field=None):
    """Bake `obj`'s normal map and return the image.

    Two things are baked into it. Given the `field` the mesh was meshed from,
    **the sculpt itself**: decimation keeps the silhouette and throws away the
    nostril, the lid and the fillet, and the field still has them, so the
    field's own normal is written in the low mesh's frame and the decimated
    mesh is lit as the sculpt. And over that, `height_at(points,
    nearest_vertex, face)`'s slope — the carving too fine for any mesh.

    Given `colour_at(points, nearest_vertex, face)` (linear RGB), a base colour
    map beside it, so a boundary between two materials follows the texels
    rather than the decimated mesh's edges; then a (normal, colour) pair."""
    t0 = time.time()
    pos, nrm, tan, sign, px, nearest, face = raster(obj, size)
    nrm, tan, bit = tangent_frame(nrm, tan, sign)
    e = SLOPE_STEP
    h_t = (height_at(pos + tan * e, nearest, face) - height_at(pos - tan * e, nearest, face)) / (2 * e)
    h_b = (height_at(pos + bit * e, nearest, face) - height_at(pos - bit * e, nearest, face)) / (2 * e)
    if field is not None:
        sculpt = field_normals(field, pos)
        base = np.stack([np.einsum("ij,ij->i", sculpt, tan), np.einsum("ij,ij->i", sculpt, bit),
                         np.einsum("ij,ij->i", sculpt, nrm)], axis=1)
        # A normal pointing into the low surface means the sculpt is folded
        # away from it there (a deep cut the decimation bridged): keep the
        # low surface's own rather than write one that lights from inside.
        base[base[:, 2] < 0.05] = (0.0, 0.0, 1.0)
        base /= np.linalg.norm(base, axis=1)[:, None]
    else:
        base = np.tile((0.0, 0.0, 1.0), (len(pos), 1))
    ts = base + np.stack([-h_t, -h_b, np.zeros_like(h_t)], axis=1)
    ts /= np.linalg.norm(ts, axis=1)[:, None]
    img = np.zeros((size, size, 4), np.float32)
    filled = np.zeros((size, size), bool)
    img[:, :, :3] = (0.5, 0.5, 1.0)
    img[:, :, 3] = 1.0
    img[px[:, 1], px[:, 0], :3] = ts * 0.5 + 0.5
    filled[px[:, 1], px[:, 0]] = True
    normal = _image(name, _dilated(img, filled.copy(), size), size, False)
    log(f"baked {name}: {len(px)} texels in {time.time() - t0:.1f} s")
    if colour_at is None:
        return normal
    col = np.zeros((size, size, 4), np.float32)
    col[:, :, 3] = 1.0
    linear = np.clip(colour_at(pos, nearest, face), 0.0, 1.0)
    # Stored as sRGB, as a base colour texture is read.
    srgb = np.where(linear <= 0.0031308, linear * 12.92, 1.055 * np.power(linear, 1 / 2.4) - 0.055)
    col[px[:, 1], px[:, 0], :3] = srgb
    colour = _image(name.replace("_n", "_c") if name.endswith("_n") else name + "_c",
                    _dilated(col, filled.copy(), size), size, True)
    return normal, colour


def with_colour_map(mat, image):
    """`mat` taking its base colour from `image`."""
    nodes = mat.node_tree.nodes
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs["Color"], nodes.get("Principled BSDF").inputs["Base Color"])
    return mat


def with_normal_map(mat, image):
    """`mat` reading `image` as its tangent-space normal map."""
    nodes = mat.node_tree.nodes
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    nm = nodes.new("ShaderNodeNormalMap")
    mat.node_tree.links.new(tex.outputs["Color"], nm.inputs["Color"])
    mat.node_tree.links.new(nm.outputs["Normal"], nodes.get("Principled BSDF").inputs["Normal"])
    return mat
