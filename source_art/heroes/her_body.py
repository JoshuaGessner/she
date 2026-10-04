"""Her body's bands: their paths, frames, crest plates and carved relief (ADR-315).

The body's *form* is a signed distance field (`her_body_sdf`); this module
knows the bands it is built round, so the surface can be carved in each band's
own coordinates — `theta` round it (0 on the spine, pi on the belly) and `s`
metres along it — rather than in the world's:

- **A keel down the spine**, and a crest of carved plates standing on it.
- **The Urnes double contour** (ADR-298's reference): a raised band down each
  flank with a groove along its middle — the outline every Urnes beast is
  drawn with, so the ink pass draws it as a pair of lines.
- **Belly scutes**, broad plates across the belly, as a serpent's are.
- **Scales that flow**: cells laid out in the band's unrolled surface, so they
  run along her length, larger on the back than on the flanks.

The relief is never geometry: it is baked into the normal map (`build_her`).
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
import sdf_sculpt as S  # noqa: E402


def spline(points, steps=8):
    """Catmull-Rom through `points`."""
    pts = [np.asarray(p, float) for p in points]
    out = []
    for i in range(len(pts) - 1):
        p0, p1, p2 = pts[max(i - 1, 0)], pts[i], pts[i + 1]
        p3 = pts[min(i + 2, len(pts) - 1)]
        for s in range(steps):
            t = s / steps
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                              + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    out.append(pts[-1])
    return np.array(out)


def resample(path, spacing):
    """Points along `path` every `spacing` metres, and their arc length."""
    seg = np.linalg.norm(np.diff(path, axis=0), axis=1)
    s = np.concatenate([[0.0], np.cumsum(seg)])
    n = max(2, int(math.ceil(s[-1] / spacing)) + 1)
    at = np.linspace(0.0, s[-1], n)
    out = np.stack([np.interp(at, s, path[:, i]) for i in range(3)], axis=1)
    return out, at


def frames(points):
    """Rotation-minimising frames (tangent, side, up), the up kept toward the
    sky where it can be so the keel stays on top."""
    t = np.gradient(points, axis=0)
    t /= np.linalg.norm(t, axis=1)[:, None]
    up0 = np.array([0.0, 0.0, 1.0])
    side = np.cross(t[0], up0)
    if np.linalg.norm(side) < 1e-3:
        side = np.array([1.0, 0.0, 0.0])
    side /= np.linalg.norm(side)
    sides, ups = [], []
    for i in range(len(points)):
        side = side - t[i] * (side @ t[i])
        side /= np.linalg.norm(side)
        up = np.cross(side, t[i])
        # Lean back toward the sky a little each step, so a long sweep does
        # not end up with its spine on its flank.
        want = np.cross(t[i], np.cross(up0, t[i]))
        if np.linalg.norm(want) > 1e-3:
            want /= np.linalg.norm(want)
            up = up * 0.9 + want * 0.1
            up /= np.linalg.norm(up)
            side = np.cross(t[i], up)
            side /= np.linalg.norm(side)
        sides.append(side)
        ups.append(up)
    return t, np.array(sides), np.array(ups)


def relief(theta, s, r):
    """Height (metres, out along the normal) of the carving at angle `theta`,
    `s` metres along a band whose radius there is `r`."""
    a = np.abs(np.angle(np.exp(1j * theta)))      # 0 on the spine, pi on the belly
    keel = 0.05 * r * np.exp(-(a / 0.16) ** 2)
    # The double contour: a raised band on each flank, grooved down its middle.
    band = np.minimum(np.clip(1.0 - np.abs(a - 1.80) / 0.13, 0.0, 1.0) * 3.0, 1.0)
    groove = np.exp(-((a - 1.80) / 0.022) ** 2)
    contour = 0.030 * r * band - 0.022 * r * groove
    # Belly scutes: broad plates across the belly, a cut between each.
    belly = np.clip((a - 2.15) / 0.20, 0.0, 1.0)
    pitch = 0.20 + 0.06 * r
    phase = (s / pitch) % 1.0
    scute = -0.016 * r * np.exp(-((phase - 0.5) / 0.06) ** 2) + 0.006 * r * np.sin(phase * math.pi)
    # Scales on the back and flanks, laid out in the unrolled band so they
    # run along her; larger on the back.
    u = theta * r
    pts = np.stack([u, s, np.zeros_like(u)], axis=1)
    size = np.where(a < 1.2, 0.13, 0.095) * np.clip(r / 0.8, 0.5, 1.15)
    sc = np.zeros_like(u)
    for unit in np.unique(np.round(size, 2)):
        pick = np.abs(size - unit) < 0.006
        if pick.any():
            sc[pick] = S.scale_height(pts[pick], unit, 0.012 * min(unit / 0.10, 1.3), (0.0, 1.0, 0.0))
    return keel + contour + belly * scute + sc * (1.0 - belly) * (1.0 - band)


def plate(base, tangent, up, length, height, thick):
    """A carved crest plate: a blade with a curved back edge, thick at its
    root and thin at its edge, standing on the spine and raked back."""
    t = tangent / np.linalg.norm(tangent)
    u = up / np.linalg.norm(up)
    sd = np.cross(t, u)
    outline = []
    for f in np.linspace(0.0, 1.0, 9):
        along = -0.5 + f
        rise = math.sin(math.pi * f) ** 0.8 * (1.0 - 0.35 * f)
        outline.append((along * length + 0.35 * length * rise, rise * height))
    verts = []
    for side_k in (-1, 1):
        for a, z in outline:
            th = thick * (1.0 - 0.85 * z / max(height, 1e-6))
            verts.append(base + t * a + u * z + sd * side_k * th)
    n = len(outline)
    quads = [(i, i + 1, n + i + 1, n + i) for i in range(n - 1)]
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))] + quads
    return np.array(verts), faces
