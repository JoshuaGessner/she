"""What is carved into her surface, as height (ADR-315).

Height is metres out along the surface's normal. `build_her` evaluates these at
every texel of the game mesh and bakes their slope into a tangent-space normal
map — the scales, the double contour, the scutes and the lip's scroll are drawn
by the light and the ink pass rather than modelled, which is the only way a
ten-metre creature carries fifteen-centimetre scales on forty thousand
triangles.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
import sdf_sculpt as S  # noqa: E402
import her_body as B  # noqa: E402
import her_body_sdf as BODY  # noqa: E402
import her_head_sdf as H  # noqa: E402

## Spacing of the band samples a texel is matched to.
SAMPLE = 0.03
## A texel further than this from a band's own surface is on a leg, a hand
## or a fillet, and is scaled without a band's direction.
OFF_BAND = 0.12


class Bands:
    """Every band's samples, and the nearest one to any point."""

    def __init__(self):
        from mathutils import kdtree, Vector
        centres, tangents, sides, ups, arcs, radii = [], [], [], [], [], []
        for _name, path, rad in BODY.bands():
            pts, s = B.resample(path, SAMPLE)
            r = np.interp(s, np.linspace(0.0, s[-1], len(rad)), rad)
            t, sd, up = B.frames(pts)
            centres.append(pts)
            tangents.append(t)
            sides.append(sd)
            ups.append(up)
            arcs.append(s)
            radii.append(r)
        self.c = np.concatenate(centres)
        self.t = np.concatenate(tangents)
        self.side = np.concatenate(sides)
        self.up = np.concatenate(ups)
        self.s = np.concatenate(arcs)
        self.r = np.concatenate(radii)
        self.tree = kdtree.KDTree(len(self.c))
        for i, q in enumerate(self.c):
            self.tree.insert(Vector(q), i)
        self.tree.balance()
        self._vector = Vector

    def nearest(self, points):
        """The sample each point belongs to: the one whose *surface* it is
        nearest, not merely the nearest centre, so a thin tail beside a thick
        chest is not claimed by the chest."""
        V = self._vector
        out = np.empty(len(points), dtype=np.int64)
        for k, q in enumerate(points):
            best, best_d = -1, 1e9
            for (_co, i, dist) in self.tree.find_n(V(q), 6):
                d = abs(dist - self.r[i])
                if d < best_d:
                    best, best_d = i, d
            out[k] = best
        return out

    def height(self, points, idx):
        """Band relief at `points`, each measured in the frame of its sample."""
        v = points - self.c[idx]
        along = np.einsum("ij,ij->i", v, self.t[idx])
        across = v - self.t[idx] * along[:, None]
        theta = np.arctan2(np.einsum("ij,ij->i", across, self.side[idx]),
                           np.einsum("ij,ij->i", across, self.up[idx]))
        return B.relief(theta, self.s[idx] + along, self.r[idx])

    def off_band(self, points, idx):
        v = points - self.c[idx]
        along = np.einsum("ij,ij->i", v, self.t[idx])
        radial = np.linalg.norm(v - self.t[idx] * along[:, None], axis=1)
        return np.abs(radial - self.r[idx]) > OFF_BAND


def limb_height(points):
    """Legs and hands: smaller scales, lying down the limb."""
    return S.scale_height(points, 0.06, 0.008, (0.0, 0.0, -1.0))


def blend_band(bands, points, idx):
    """Band relief where a texel is on a band, limb scales where it is not,
    crossfaded over the fillet so no seam is drawn."""
    v = points - bands.c[idx]
    along = np.einsum("ij,ij->i", v, bands.t[idx])
    radial = np.linalg.norm(v - bands.t[idx] * along[:, None], axis=1)
    off = np.abs(radial - bands.r[idx])
    w = np.clip((off - 0.06) / (OFF_BAND - 0.06), 0.0, 1.0)
    return bands.height(points, idx) * (1.0 - w) + limb_height(points) * w


def head_height(points, feature_mask):
    """The head, in its own frame: scales where it is skin, carved smooth where
    it is horn, plate or tooth, and the lip's scroll engraved."""
    top = points[:, 2] > 0.20
    back = (0.0, 1.0, 0.0)
    h = np.where(top, S.scale_height(points, 0.075, 0.010, back), S.scale_height(points, 0.05, 0.007, back))
    h = np.where(feature_mask, 0.0, h)
    return h + scroll(points)


def head_features(points):
    """Which head points are horn, plate or tooth rather than skin."""
    return H.features(points) < H.skin(points) + 0.004


## The lip's scroll, as a curve on each side of the snout's end.
def _scroll_curve():
    turns = np.linspace(0.0, 1.7, 60)
    tip = H.TIP
    return np.array([(0.0, tip + 0.32 + 0.17 * (1 - t / 2.0) * math.sin(t * math.tau),
                      0.05 + 0.13 * (1 - t / 2.0) * math.cos(t * math.tau)) for t in turns])


_SCROLL = _scroll_curve()


def scroll(points):
    """An engraved groove: distance in the side-on plane to the spiral, on the
    outer face of the snout only."""
    yz = points[:, 1:3]
    d = np.full(len(points), 9.0)
    for a, b in zip(_SCROLL[:-1, 1:3], _SCROLL[1:, 1:3]):
        ab = b - a
        t = np.clip(((yz - a) @ ab) / (ab @ ab), 0.0, 1.0)
        d = np.minimum(d, np.linalg.norm(yz - (a + np.outer(t, ab)), axis=1))
    side = np.abs(points[:, 0]) > 0.18
    return np.where(side, -0.018 * np.exp(-(d / 0.016) ** 2), 0.0)
