"""Her head, sculpted as a signed distance field (ADR-315).

Head-local frame, metres: the pivot at the top of the neck is the origin, the
snout runs out along -Y, up is +Z, her left is +X. `field()` is the skin of the
head; `eyes()` and `pupils()` are the separate gold eyes and their slits.

The references, and what each gives the head:
- **The crocodilian and monitor-lizard skull** — the real animal under every
  good dragon head: the eyes set high and back under a brow that overhangs
  them, a jugal bar swelling behind the eye into a heavy jaw muscle, so that
  from above the head is a broad wedge, not a stick.
- **The Oseberg ship's animal posts** (c. 820) — the heavy rounded snout, the
  large eye, the bared teeth.
- **The Borgund and Urnes gable heads** (11th–12th c.) — the snout ending in an
  upturned lip whose end is *carved* into a scroll, the almond eye.
- **Urnes beasts** — the "upwardly curled appendages" on the head: horns that
  sweep back from the skull and curl down at their ends, ridged.

Carved, not inflated: blends are kept tight so ridges keep an edge. The
scales and the lip's engraved scroll are not modelled here: they are
`her_detail`'s, baked into the normal map.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
import sdf_sculpt as S  # noqa: E402

## How far the jaw hangs open, degrees, and where it hinges (head-local).
JAW_OPEN = 18.0
HINGE = np.array([0.0, -0.02, -0.26])
## Where the snout ends, and the lip plate beyond it.
TIP = -1.95


def _mirror(p):
    q = p.copy()
    q[:, 0] = np.abs(q[:, 0])
    return q


def _scaled(fn, p, s):
    """Evaluate `fn` in space stretched by `s` per axis, keeping a lower bound."""
    s = np.asarray(s, float)
    return fn(p / s) * float(np.min(s))


def _half_width(y):
    """The upper jaw's half-width at `y` along the snout (for teeth, lips)."""
    t = np.clip((-y - 0.45) / (-TIP - 0.45), 0.0, 1.0)
    return 0.40 * (1.0 - t) + 0.21 * t


def _horn(m, root, sweep, base, length=1.0):
    """A ridged horn along a sweep: radius steps make the rings."""
    coarse = [np.asarray(root) + np.asarray(s) * length for s in sweep]
    pts = []
    for a, b in zip(coarse, coarse[1:]):
        for f in (0.0, 0.5):
            pts.append(a + (b - a) * f)
    pts.append(coarse[-1])
    n = len(pts)
    radii = [base * (1.0 - 0.86 * i / (n - 1)) * (1.0 + 0.13 * (i % 2)) for i in range(n)]
    return S.chain(m, pts, radii, 0.01)


def upper(p):
    """The skull and upper jaw's skin, which carries the scales."""
    m = _mirror(p)
    # **The main mass, carved from its profiles**: the skull and upper jaw as
    # one block — broad over the eyes, a wedge in plan, flat on its palate,
    # the snout deepening again at the nose under the rolled lip.
    ys = [0.50, 0.25, -0.05, -0.40, -0.72, -1.05, -1.38, -1.68, TIP]
    d = S.loft(p, ys,
               half_width=[0.34, 0.50, 0.56, 0.52, 0.44, 0.38, 0.33, 0.29, 0.25],
               top=[0.34, 0.52, 0.58, 0.52, 0.40, 0.33, 0.33, 0.36, 0.30],
               bottom=[-0.18, -0.22, -0.22, -0.21, -0.20, -0.20, -0.19, -0.18, -0.16],
               squareness=[2.2, 2.4, 2.6, 2.8, 3.0, 3.1, 3.2, 3.3, 3.2], cap=0.12)
    # Jaw muscle behind each eye.
    d = S.smin(d, S.ellipsoid(m - (0.44, -0.05, -0.06), (0.20, 0.34, 0.26)), 0.10)
    # Brow: a hard ridge along the skull's upper edge, over the eye and back.
    brow = S.ellipsoid(S.into(m, S.move((0.42, -0.58, 0.40)) @ S.rot((0, 0, 1), -12.0)
                              @ S.rot((0, 1, 0), 18.0)), (0.10, 0.46, 0.06))
    d = S.smin(d, brow, 0.06)
    # The eye socket, deep under the brow.
    d = S.carve(d, S.ellipsoid(m - (0.50, -0.66, 0.22), (0.16, 0.30, 0.15)), 0.035)
    # Lids: a heavy upper, a thinner lower, meeting at the corners.
    d = S.smin(d, S.chain(m, [(0.44, -0.38, 0.28), (0.54, -0.64, 0.34), (0.48, -0.94, 0.24)],
                          [0.03, 0.05, 0.03], 0.02), 0.04)
    d = S.smin(d, S.chain(m, [(0.45, -0.40, 0.14), (0.54, -0.66, 0.10), (0.48, -0.93, 0.20)],
                          [0.025, 0.035, 0.022], 0.02), 0.04)
    # The jugal bar, from under the eye back to the jaw muscle.
    d = S.smin(d, S.round_cone(m, (0.40, -1.00, -0.06), (0.50, -0.30, -0.08), 0.08, 0.13), 0.08)
    # The nose: a blunt rounded end, the nostril bosses on top of it.
    d = S.smin(d, S.ellipsoid(p - (0.0, TIP + 0.02, 0.10), (0.27, 0.16, 0.22)), 0.08)
    d = S.smin(d, S.ellipsoid(m - (0.12, TIP + 0.08, 0.30), (0.09, 0.13, 0.06)), 0.05)
    d = S.carve(d, S.ellipsoid(m - (0.13, TIP + 0.03, 0.34), (0.04, 0.06, 0.035)), 0.015)
    return d


def upper_features(p):
    """Horns, crest plates and teeth: carved smooth, never scaled."""
    return S.smin(horns(p), upper_teeth(p), 0.012)


def horns(p):
    """The horns and the plates down the back of the skull."""
    m = _mirror(p)
    # Horns: thick at the root, ridged, sweeping back and down, curling forward.
    horn = [(0.0, 0.0, 0.0), (0.10, 0.35, 0.16), (0.20, 0.72, 0.18), (0.26, 1.05, 0.05),
            (0.27, 1.25, -0.18), (0.24, 1.25, -0.40), (0.20, 1.10, -0.52), (0.17, 0.95, -0.52)]
    d = _horn(m, (0.32, -0.25, 0.46), horn, 0.17)
    small = [(0.0, 0.0, 0.0), (0.12, 0.30, -0.02), (0.20, 0.58, -0.08), (0.22, 0.78, -0.20)]
    d = S.smin(d, _horn(m, (0.46, 0.05, -0.06), small, 0.09), 0.06)
    # A row of carved plates down the back of the skull.
    for y, z, h in ((-0.40, 0.53, 0.10), (-0.10, 0.57, 0.15), (0.20, 0.52, 0.17), (0.48, 0.36, 0.15)):
        d = S.smin(d, _scaled(lambda q: S.round_cone(q, (0.0, y, z), (0.0, y + 0.12, z + h), 0.08, 0.02),
                              p, (0.40, 1.0, 1.0)), 0.04)
    return d


def upper_teeth(p):
    m = _mirror(p)
    d = np.full(len(p), 1e3)
    # Upper teeth: stout, curved back, a fang at each end of the row.
    for i, y in enumerate(np.linspace(-0.50, TIP + 0.10, 9)):
        fang = i in (1, 7)
        long = 0.21 if fang else 0.11 + 0.03 * ((i * 7) % 3) / 2.0
        r = 0.055 if fang else 0.042
        x = _half_width(y) * 0.86
        mid = (x * 0.98, y - 0.01, -0.20 - long * 0.55)
        tip = (x * 0.95, y + 0.05, -0.20 - long)
        d = S.smin(d, S.chain(m, [(x, y, -0.16), mid, tip], [r, r * 0.6, 0.006], 0.0), 0.012)
    return d


def _jaw_frame():
    return S.move(HINGE) @ S.rot((1, 0, 0), JAW_OPEN) @ S.move(-HINGE)


def lower(p):
    q = S.into(p, _jaw_frame())
    m = _mirror(q)
    # The mandible, carved from its profiles: deep at the hinge, a chin at
    # the front, its gum line flat; narrower than the upper jaw it closes under.
    ys = [0.18, -0.10, -0.50, -0.90, -1.30, -1.62, TIP + 0.22]
    d = S.loft(q, ys,
               half_width=[0.40, 0.45, 0.41, 0.35, 0.29, 0.25, 0.20],
               top=[-0.08, -0.18, -0.22, -0.22, -0.22, -0.21, -0.20],
               bottom=[-0.52, -0.62, -0.56, -0.50, -0.46, -0.45, -0.40],
               squareness=[2.4, 2.6, 2.8, 2.8, 2.8, 2.6, 2.4], cap=0.10)
    # The mouth's floor, sunk between the rami.
    d = S.carve(d, S.round_box(q - (0.0, -0.85, -0.22), (0.22, 0.85, 0.07), 0.05), 0.04)
    return d


def lower_features(p):
    """The lower teeth and the tongue."""
    return S.smin(lower_teeth(p), tongue(p), 0.02)


def lower_teeth(p):
    q = S.into(p, _jaw_frame())
    m = _mirror(q)
    d = None
    # Lower teeth, up out of the gum and curving back.
    for i, y in enumerate(np.linspace(-0.40, TIP + 0.32, 8)):
        fang = i in (1, 6)
        long = 0.18 if fang else 0.09 + 0.02 * ((i * 5) % 3) / 2.0
        r = 0.05 if fang else 0.037
        x = (0.37 - 0.17 * i / 7.0) * 0.86
        tooth = S.chain(m, [(x, y, -0.24), (x * 0.99, y + 0.005, -0.22 + long * 0.55),
                            (x * 0.97, y + 0.025, -0.22 + long)], [r, r * 0.6, 0.006], 0.0)
        d = tooth if d is None else S.smin(d, tooth, 0.005)
    return d


def tongue(p):
    q = S.into(p, _jaw_frame())
    # The tongue, lying in the floor and forked at its end.
    tongue = S.chain(q, [(0.0, -0.25, -0.27), (0.0, -0.85, -0.26), (0.0, -1.35, -0.22)],
                     [0.11, 0.09, 0.055], 0.05)
    for s in (-1, 1):
        tongue = S.smin(tongue, S.chain(q, [(0.0, -1.35, -0.22), (0.05 * s, -1.62, -0.19),
                                            (0.10 * s, -1.80, -0.11)], [0.05, 0.03, 0.01], 0.02), 0.02)
    return tongue


def skin(p):
    return S.smin(upper(p), lower(p), 0.015)


def features(p):
    return np.minimum(upper_features(p), lower_features(p))


def field(p, detail=True):
    s = skin(p)
    f = features(p)
    if detail:
        # Scales cut only into skin, and only where skin is the surface.
        near = (np.abs(s) < 0.03) & (s < f + 0.01)
        if near.any():
            pts = p[near]
            top = pts[:, 2] > 0.20
            out = np.zeros(len(pts))
            if top.any():
                out[top] = -S.scale_height(pts[top], 0.075, 0.010, (0.0, 1.0, 0.0))
            if (~top).any():
                out[~top] = -S.scale_height(pts[~top], 0.05, 0.007, (0.0, 1.0, 0.0))
            s = s.copy()
            s[near] += out
    return S.smin(s, f, 0.012)


def eyes(p):
    m = _mirror(p)
    return S.ellipsoid(S.into(m, S.move((0.47, -0.66, 0.21)) @ S.rot((0, 0, 1), -14.0)), (0.12, 0.25, 0.11))


def pupils(p):
    m = _mirror(p)
    return S.ellipsoid(S.into(m, S.move((0.575, -0.69, 0.21)) @ S.rot((0, 0, 1), -14.0)), (0.025, 0.045, 0.095))


BOUNDS = ((-0.85, -2.45, -1.30), (0.85, 1.55, 1.05))
