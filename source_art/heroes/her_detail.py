"""What is carved into her surface, as height (ADR-315), and how light or dark
each part of her is (ADR-317).

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

    def dorsal(self, points, idx):
        """How far round her band each point is: 0 on the spine, pi on the
        belly."""
        v = points - self.c[idx]
        along = np.einsum("ij,ij->i", v, self.t[idx])
        across = v - self.t[idx] * along[:, None]
        theta = np.arctan2(np.einsum("ij,ij->i", across, self.side[idx]),
                           np.einsum("ij,ij->i", across, self.up[idx]))
        return np.abs(theta)

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


# ── Value (ADR-317) ──────────────────────────────────────────────────────
#
# The Chamber colours her by lineage (ADR-050), so what is baked here is not a
# colour but a **value map** her lineage colour is multiplied by: 1.0 where she
# is her lineage's colour, darker where she is darker. Without it she is one
# value from crest to belly, and a body of one value reads as a model, not an
# animal. What it carries is what every reptile carries:
# - **Countershading:** a dark back and a pale belly — the crocodile's and the
#   monitor's — with the line between them on the Urnes double contour, so
#   the carving and the colour agree on where her flank turns under.
# - **Cavity:** dark in the cuts between scales and plates, so the carving
#   reads under flat light, where a normal map alone says nothing.
# - **Mottle:** a slow, faint variation, so a long band is not a gradient.
# - On her head: ivory teeth, a dark mouth, and horn darker than the bone.

def _smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


BACK = 0.50
## Linear tints at the dark and the light end, multiplied into the value: a
## cool back and a warm belly, faint, so the lineage colour still decides.
COOL = np.array([0.93, 0.96, 1.0])
WARM = np.array([1.0, 0.95, 0.85])


def _tinted(value):
    light = np.clip((value - BACK) / (1.0 - BACK), 0.0, 1.0)[:, None]
    return value[:, None] * (COOL * (1.0 - light) + WARM * light)


def _cavity(h):
    return 0.70 + 0.30 * np.clip(0.5 + h / 0.02, 0.0, 1.0)


def body_value(bands, points, idx, normal_z, height):
    """Her body's value map, in linear RGB."""
    a = bands.dorsal(points, idx)
    v = points - bands.c[idx]
    along = np.einsum("ij,ij->i", v, bands.t[idx])
    radial = np.linalg.norm(v - bands.t[idx] * along[:, None], axis=1)
    w = np.clip((np.abs(radial - bands.r[idx]) - 0.06) / (OFF_BAND - 0.06), 0.0, 1.0)
    on_band = BACK + (1.0 - BACK) * _smooth(1.55, 2.25, a)
    on_limb = BACK + (1.0 - BACK) * _smooth(0.25, -0.55, normal_z)
    value = (on_band * (1.0 - w) + on_limb * w) * _cavity(height)
    value *= 1.0 + 0.07 * S.fbm(points, 0.7, 2)
    return _tinted(np.clip(value, 0.0, 1.0))


def head_value(points, normal_z, height):
    """Her head's value map, in its own frame, in linear RGB."""
    value = (BACK + (1.0 - BACK) * _smooth(0.25, -0.45, normal_z)) * _cavity(height)
    value *= 1.0 + 0.06 * S.fbm(points, 0.35, 2)
    out = _tinted(np.clip(value, 0.0, 1.0))
    skin = H.skin(points)
    near = 0.006
    teeth = np.minimum(H.upper_teeth(points), H.lower_teeth(points))
    horns = H.horns(points)
    tongue = H.tongue(points)
    # The mouth: inside the line of the jaws, between the palate and the
    # floor, and not a tooth. Dark, and red as a mouth is.
    m = np.abs(points[:, 0])
    half = H._half_width(points[:, 1])
    q = S.into(points, H._jaw_frame())
    # Inside the rows of teeth and behind the front ones: the lip and the gum
    # outside them stay skin, or the snout wears a band of red like paint.
    inside = (m < 0.70 * half) & (points[:, 1] < 0.20) & (points[:, 1] > H.TIP + 0.30)
    # By facing as well as by place: the palate looks down and the floor up,
    # so the outside of a lip at the same height stays skin.
    palate = (points[:, 2] < -0.10) & (points[:, 2] > -0.27) & (normal_z < -0.35)
    floor = (q[:, 2] > -0.33) & (q[:, 2] < -0.14) & (normal_z > 0.25)
    mouth = inside & (palate | floor)
    out[mouth] = (0.34, 0.13, 0.12)
    out[tongue < np.minimum(skin, teeth) + near] = (0.52, 0.20, 0.19)
    horn = horns < skin + near
    out[horn] = _tinted(np.full(int(horn.sum()), 0.55) * _cavity(height[horn]))
    tooth = teeth < np.minimum(skin, tongue) + near
    out[tooth] = (0.95, 0.90, 0.76)
    return out


def crest_value(points):
    """The crest plates: dark at the root, paling toward the edge, as horn
    does."""
    out = BODY.skin(points)
    value = 0.30 + 0.26 * np.clip(out / 0.45, 0.0, 1.0)
    return _tinted(value)
