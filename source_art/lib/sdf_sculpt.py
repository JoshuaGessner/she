"""Procedural sculpting: signed distance fields, meshed by surface nets.

Lofting tubes along curves cannot make an organic form: it has no way to let a
brow overhang a socket, a cheek swell into a jaw, or a groove be cut into a
surface. A signed distance field can. Every form here is a function from a
point to its distance from the surface; forms are combined with smooth unions
(`smin`), which blend them like clay, and smooth cuts, which carve them. That
is how the hero assets are sculpted from a script (ADR-315).

The field is meshed by **surface nets**: one vertex per grid cell the surface
crosses, at the average of the edge crossings, and one quad per grid edge the
surface crosses. It needs no case table and gives clean, even quads, which is
what a decimate-and-bake pipeline wants to start from.

Pure numpy, so it runs inside Blender's Python; Blender is used only to hold
the result.
"""
from __future__ import annotations

import math

import numpy as np


# ── Points and frames ────────────────────────────────────────────────────

def frame(origin, x=(1, 0, 0), y=(0, 1, 0), z=(0, 0, 1)):
    """A 4x4 world-from-local matrix, as numpy."""
    m = np.eye(4)
    m[:3, 0], m[:3, 1], m[:3, 2], m[:3, 3] = x, y, z, origin
    return m


def rot(axis, degrees):
    a = math.radians(degrees)
    c, s = math.cos(a), math.sin(a)
    x, y, z = np.asarray(axis, float) / np.linalg.norm(axis)
    r = np.array([[c + x * x * (1 - c), x * y * (1 - c) - z * s, x * z * (1 - c) + y * s],
                  [y * x * (1 - c) + z * s, c + y * y * (1 - c), y * z * (1 - c) - x * s],
                  [z * x * (1 - c) - y * s, z * y * (1 - c) + x * s, c + z * z * (1 - c)]])
    m = np.eye(4)
    m[:3, :3] = r
    return m


def move(offset):
    m = np.eye(4)
    m[:3, 3] = offset
    return m


def into(points, world_from_local):
    """Points (N,3) expressed in a local frame."""
    inv = np.linalg.inv(world_from_local)
    return points @ inv[:3, :3].T + inv[:3, 3]


# ── Combining ────────────────────────────────────────────────────────────

def smin(a, b, k):
    """Smooth union: `k` is the blend radius in metres."""
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def carve(a, b, k):
    """Smooth subtraction of `b` from `a`."""
    return smax(a, -b, k)


# ── Primitives (each takes points already in its own frame) ─────────────

def sphere(p, r):
    return np.linalg.norm(p, axis=1) - r


def ellipsoid(p, radii):
    """A good approximation (Quilez): exact on the axes, smooth everywhere."""
    r = np.asarray(radii, float)
    k0 = np.linalg.norm(p / r, axis=1)
    k1 = np.linalg.norm(p / (r * r), axis=1)
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def round_cone(p, a, b, ra, rb):
    """A capsule whose radius runs from `ra` at `a` to `rb` at `b`."""
    a, b = np.asarray(a, float), np.asarray(b, float)
    ba = b - a
    l2 = ba @ ba
    rr = ra - rb
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = p - a
    y = pa @ ba
    z = y - l2
    x2v = pa * l2 - np.outer(y, ba)
    x2 = np.einsum("ij,ij->i", x2v, x2v)
    y2 = y * y * l2
    z2 = z * z * l2
    k = np.sign(rr) * rr * rr * x2
    out = (np.sqrt(x2 * a2 * il2) + y * rr) * il2 - ra
    m1 = np.sign(z) * a2 * z2 > k
    out = np.where(m1, np.sqrt(x2 + z2) * il2 - rb, out)
    m2 = np.sign(y) * a2 * y2 < k
    out = np.where(m2, np.sqrt(x2 + y2) * il2 - ra, out)
    return out


def chain(p, points, radii, k=0.0):
    """Round cones through a polyline, smoothly joined: a limb, a horn, a tail."""
    d = None
    for i in range(len(points) - 1):
        seg = round_cone(p, points[i], points[i + 1], radii[i], radii[i + 1])
        d = seg if d is None else smin(d, seg, k)
    return d


def band(p, points, radii, k=0.0, reach=0.5):
    """`chain` for long paths: each segment is evaluated exactly only for the
    points near enough to matter, and bounded by its enclosing sphere for the
    rest, so a hundred-segment body costs little more than a few segments."""
    points = [np.asarray(q, float) for q in points]
    d = np.full(len(p), 1e3)
    for i in range(len(points) - 1):
        a, b = points[i], points[i + 1]
        mid = (a + b) * 0.5
        rad = np.linalg.norm(b - a) * 0.5 + max(radii[i], radii[i + 1])
        bound = np.linalg.norm(p - mid, axis=1) - rad
        near = bound < np.minimum(d, 0.0) + k + reach
        if near.any():
            seg = round_cone(p[near], a, b, radii[i], radii[i + 1])
            d[near] = smin(d[near], seg, k) if k > 0 else np.minimum(d[near], seg)
        far = ~near
        d[far] = np.minimum(d[far], bound[far])
    return d


def round_box(p, half, r):
    q = np.abs(p) - (np.asarray(half, float) - r)
    return (np.linalg.norm(np.maximum(q, 0.0), axis=1)
            + np.minimum(np.max(q, axis=1), 0.0) - r)


def plane(p, normal, offset):
    n = np.asarray(normal, float)
    n = n / np.linalg.norm(n)
    return p @ n - offset


def torus(p, major, minor):
    q = np.stack([np.linalg.norm(p[:, [0, 1]], axis=1) - major, p[:, 2]], axis=1)
    return np.linalg.norm(q, axis=1) - minor


def loft(p, ys, half_width, top, bottom, squareness, cap=0.05):
    """**A form carved from profiles**, the way a carver works a block: its
    plan (half-width), its side (top and bottom) and how square each section
    is, given at stations along -Y. Between stations everything is
    interpolated, so the planes run continuously — which a pile of blended
    blobs cannot do. Approximate distance, good for meshing and blending."""
    ys = np.asarray(ys, float)
    order = np.argsort(ys)
    ys = ys[order]
    w = np.interp(p[:, 1], ys, np.asarray(half_width, float)[order])
    zt = np.interp(p[:, 1], ys, np.asarray(top, float)[order])
    zb = np.interp(p[:, 1], ys, np.asarray(bottom, float)[order])
    n = np.interp(p[:, 1], ys, np.asarray(squareness, float)[order])
    h = np.maximum((zt - zb) * 0.5, 1e-4)
    z0 = (zt + zb) * 0.5
    ax = np.abs(p[:, 0]) / np.maximum(w, 1e-4)
    az = np.abs(p[:, 2] - z0) / h
    r = (ax ** n + az ** n) ** (1.0 / n)
    d = (r - 1.0) * np.minimum(w, h) * 0.9
    ends = np.maximum(p[:, 1] - ys[-1], ys[0] - p[:, 1])
    return smax(d, ends, cap)


# ── Surface detail ───────────────────────────────────────────────────────

def _hash3(c):
    """A stable pseudo-random point in each integer cell."""
    c = c.astype(np.int64)
    h = (c[..., 0] * 73856093) ^ (c[..., 1] * 19349663) ^ (c[..., 2] * 83492791)
    h = (h ^ (h >> 13)) * 1274126177
    out = np.stack([((h >> s) & 1023) / 1023.0 for s in (0, 10, 20)], axis=-1)
    return out


def cells(p, size, jitter=0.7):
    """Worley noise: distance to the nearest and second-nearest scattered
    point, in units of `size`, and the offset from the nearest. `f2 - f1` is
    zero on the borders between cells — the grooves between scales."""
    q = p / size
    base = np.floor(q)
    f1 = np.full(len(p), 9.0)
    f2 = np.full(len(p), 9.0)
    off = np.zeros_like(q)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                c = base + np.array([dx, dy, dz])
                site = c + 0.5 + (_hash3(c) - 0.5) * jitter
                v = q - site
                d = np.linalg.norm(v, axis=1)
                closer = d < f1
                f2 = np.where(closer, f1, np.minimum(f2, d))
                off = np.where(closer[:, None], v, off)
                f1 = np.where(closer, d, f1)
    return f1, f2, off


def scale_height(p, size, depth, along=None):
    """**Scales, as height**: each cell domed, the border between cells a
    soft valley, and — given the direction `along` a body runs — each scale
    tipped up toward its trailing edge, so they lie over one another like a
    serpent's rather than sitting side by side like cobbles."""
    f1, f2, off = cells(p, size)
    edge = np.clip((f2 - f1) / 0.16, 0.0, 1.0)
    edge = edge * edge * (3.0 - 2.0 * edge)
    dome = 1.0 - np.clip(f1 / 0.8, 0.0, 1.0) ** 2
    if along is None:
        lift = dome
    else:
        a = np.asarray(along, float)
        tilt = np.clip(0.5 + (off @ a) / 0.9, 0.0, 1.0)
        lift = 0.6 * dome + 0.4 * tilt
    return depth * lift * edge


# ── Meshing ──────────────────────────────────────────────────────────────

def grid(lo, hi, voxel):
    lo, hi = np.asarray(lo, float), np.asarray(hi, float)
    n = np.ceil((hi - lo) / voxel).astype(int) + 1
    axes = [lo[i] + voxel * np.arange(n[i]) for i in range(3)]
    return axes, n


def sample(field, lo, hi, voxel, chunk=400000):
    """The field on a grid over the box, in chunks so memory stays flat."""
    axes, n = grid(lo, hi, voxel)
    X, Y, Z = np.meshgrid(*axes, indexing="ij")
    pts = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    out = np.empty(len(pts))
    for s in range(0, len(pts), chunk):
        out[s:s + chunk] = field(pts[s:s + chunk])
    return out.reshape(n), np.asarray(lo, float), voxel


def sample_sparse(field, lo, hi, voxel, block=16, slack=1.6):
    """The field on a grid over the box, skipping blocks the surface cannot
    reach: each block's centre is evaluated first, and a block whose centre is
    further from the surface than its own half-diagonal (times `slack`, since
    blended fields only roughly keep distance) is filled with that value
    rather than evaluated point by point. A body ten metres long at three
    centimetres is otherwise thirteen million evaluations, almost all of them
    in empty air."""
    axes, n = grid(lo, hi, voxel)
    out = np.empty(n)
    half = block * voxel * math.sqrt(3) * 0.5
    starts = [range(0, n[i], block) for i in range(3)]
    centres = []
    keys = []
    for i in starts[0]:
        for j in starts[1]:
            for k in starts[2]:
                ie, je, ke = min(i + block, n[0]), min(j + block, n[1]), min(k + block, n[2])
                centres.append([(axes[0][i] + axes[0][ie - 1]) * 0.5, (axes[1][j] + axes[1][je - 1]) * 0.5,
                                (axes[2][k] + axes[2][ke - 1]) * 0.5])
                keys.append((i, ie, j, je, k, ke))
    centre_d = field(np.array(centres))
    busy = []
    for (i, ie, j, je, k, ke), d in zip(keys, centre_d):
        if abs(d) > half * slack:
            out[i:ie, j:je, k:ke] = d
        else:
            busy.append((i, ie, j, je, k, ke))
    # Evaluate the busy blocks in batches.
    batch, sizes = [], []
    def flush():
        if not batch:
            return
        vals = field(np.concatenate(batch))
        at = 0
        for (i, ie, j, je, k, ke), size in zip(sizes, [len(b) for b in batch]):
            out[i:ie, j:je, k:ke] = vals[at:at + size].reshape(ie - i, je - j, ke - k)
            at += size
        batch.clear()
        sizes.clear()
    for key in busy:
        i, ie, j, je, k, ke = key
        X, Y, Z = np.meshgrid(axes[0][i:ie], axes[1][j:je], axes[2][k:ke], indexing="ij")
        batch.append(np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1))
        sizes.append(key)
        if sum(len(b) for b in batch) > 300000:
            flush()
    flush()
    return out, np.asarray(lo, float), voxel, len(busy), len(keys)


def surface_nets(values, lo, voxel):
    """Quads over the zero set of a sampled field. Returns (verts, quads),
    quads wound so their normals point out of the solid (negative inside)."""
    v = values
    inside = v < 0.0
    nx, ny, nz = v.shape
    # Corners of every cell, and which cells the surface crosses.
    corners = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0),
               (0, 0, 1), (1, 0, 1), (0, 1, 1), (1, 1, 1)]
    cell_in = [inside[i:nx - 1 + i, j:ny - 1 + j, k:nz - 1 + k] for i, j, k in corners]
    count = sum(c.astype(np.int8) for c in cell_in)
    active = (count > 0) & (count < 8)
    idx = np.full(active.shape, -1, dtype=np.int64)
    ai = np.argwhere(active)
    idx[active] = np.arange(len(ai))
    # Vertex = mean of the edge crossings in its cell.
    edges = [(0, 1), (2, 3), (4, 5), (6, 7), (0, 2), (1, 3), (4, 6), (5, 7),
             (0, 4), (1, 5), (2, 6), (3, 7)]
    acc = np.zeros((len(ai), 3))
    num = np.zeros(len(ai))
    for a, b in edges:
        ca, cb = np.array(corners[a]), np.array(corners[b])
        va = v[ai[:, 0] + ca[0], ai[:, 1] + ca[1], ai[:, 2] + ca[2]]
        vb = v[ai[:, 0] + cb[0], ai[:, 1] + cb[1], ai[:, 2] + cb[2]]
        cross = (va < 0) != (vb < 0)
        t = np.where(cross, va / np.where(cross, va - vb, 1.0), 0.0)
        pos = ca + (cb - ca) * t[:, None]
        acc[cross] += pos[cross]
        num[cross] += 1
    verts = lo + (ai + acc / np.maximum(num, 1)[:, None]) * voxel
    quads = []
    # A quad for every grid edge the surface crosses, from the four cells round it.
    for axis in range(3):
        a1, a2 = [x for x in range(3) if x != axis]
        sl = [slice(None)] * 3
        lo_s = [slice(0, n - 1) if d == axis else slice(1, (nx, ny, nz)[d] - 1) for d, n in
                enumerate((nx, ny, nz))]
        hi_s = [slice(1, n) if d == axis else slice(1, (nx, ny, nz)[d] - 1) for d, n in
                enumerate((nx, ny, nz))]
        va = v[tuple(lo_s)]
        vb = v[tuple(hi_s)]
        cross = (va < 0) != (vb < 0)
        where = np.argwhere(cross)
        if len(where) == 0:
            continue
        base = where.copy()
        base[:, a1] += 1
        base[:, a2] += 1
        def cell(d1, d2):
            c = base.copy()
            c[:, a1] -= d1
            c[:, a2] -= d2
            return idx[c[:, 0], c[:, 1], c[:, 2]]
        q = np.stack([cell(1, 1), cell(0, 1), cell(0, 0), cell(1, 0)], axis=1)
        flip = va[tuple(where.T)] < 0
        if axis == 1:
            flip = ~flip
        q = np.where(flip[:, None], q[:, ::-1], q)
        ok = np.all(q >= 0, axis=1)
        quads.append(q[ok])
    out = np.concatenate(quads) if quads else np.zeros((0, 4), int)
    # Wound by the rule above, every quad faced into the solid; turned over
    # once here rather than at each axis.
    return verts, out[:, ::-1].copy()


def relax(verts, quads, rounds=2, amount=0.5):
    """Laplacian smoothing over the quad mesh's edges."""
    n = len(verts)
    e = np.concatenate([quads[:, [0, 1]], quads[:, [1, 2]], quads[:, [2, 3]], quads[:, [3, 0]]])
    for _ in range(rounds):
        acc = np.zeros_like(verts)
        cnt = np.zeros(n)
        np.add.at(acc, e[:, 0], verts[e[:, 1]])
        np.add.at(acc, e[:, 1], verts[e[:, 0]])
        np.add.at(cnt, e[:, 0], 1)
        np.add.at(cnt, e[:, 1], 1)
        mean = acc / np.maximum(cnt, 1)[:, None]
        verts = verts + amount * (mean - verts) * (cnt > 0)[:, None]
    return verts


def project(verts, field, rounds=3, step=0.002):
    """Pull vertices back onto the zero set along the field's gradient."""
    for _ in range(rounds):
        d = field(verts)
        g = np.stack([(field(verts + np.eye(3)[i] * step) - d) / step for i in range(3)], axis=1)
        g /= np.maximum(np.linalg.norm(g, axis=1), 1e-9)[:, None]
        verts = verts - g * d[:, None]
    return verts
