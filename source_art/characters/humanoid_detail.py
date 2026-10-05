"""What each material looks like close to, as height and colour (ADR-316).

`build_enemies` bakes these into each body's normal and base colour maps: a
fold in cloth, the grain of leather, the rings of mail, the strands of a beard,
the pores of skin. The base colours are `build_enemy_models.PALETTE`'s, which
the ink pass was tuned against, with a little variation through them so a
surface reads as a material rather than as a fill.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
import sdf_sculpt as S  # noqa: E402


def _flesh(p):
    return 0.0005 * S.fbm(p, 0.012, 2) + 0.0012 * S.noise(p, 0.04)


def _hair(p):
    # Lumps, never grooves (ADR-317): any row of vertical grooves in a dark
    # band under a nose draws under the ink as bared teeth — at 7 mm and at
    # 18 mm alike. The beard's locks are sculpted; its surface only roughens.
    return 0.0016 * S.fbm(p * np.array([1.0, 1.0, 0.5]), 0.03, 2)


def _cloth(p):
    folds = 0.0045 * S.fbm(p * np.array([1.0, 1.0, 0.35]), 0.06, 3)
    weave = 0.00035 * np.sin(p[:, 0] * 2 * math.pi / 0.004) * np.sin(p[:, 2] * 2 * math.pi / 0.004)
    return folds + weave


def _rag(p):
    return _cloth(p) * 1.5 + 0.0015 * S.noise(p, 0.012)


def _leather(p):
    return 0.0018 * S.fbm(p, 0.035, 2) + S.scale_height(p, 0.008, 0.0005)


def _mail(p):
    # Mail as it is drawn rather than as it is made (ADR-317): rows of arcs
    # hanging down, the illuminator's shorthand for rings. Rings at their real
    # 8 mm are a fraction of a texel, and drew nothing; a course of arcs every
    # 16 mm draws the lines that say mail.
    return S.scale_height(p, 0.016, 0.0016, (0.0, 0.0, -1.0))


def _iron(p):
    return -S.scale_height(p, 0.035, 0.0012)


def _gold(p):
    # Struck faces: a raised boss in each, worn by handling.
    return S.scale_height(p, 0.022, 0.0014) - 0.0006 * S.noise(p, 0.01)


def _wood(p):
    return 0.0012 * np.sin((p[:, 2] + 0.01 * S.noise(p, 0.05)) * 2 * math.pi / 0.006)


## Material → (linear base colour, ink family B, height function).
MATERIALS = {
    "flesh": ((0.40, 0.36, 0.31), 0.80, _flesh),
    "dark": ((0.050, 0.046, 0.042), 0.80, _hair),
    "cloth": ((0.105, 0.105, 0.11), 0.60, _cloth),
    "rag": ((0.15, 0.142, 0.125), 0.60, _rag),
    # The delvers' tunic (ADR-318): undyed linen, the lightest cloth in the game.
    "linen": ((0.36, 0.33, 0.27), 0.60, _cloth),
    "leather": ((0.16, 0.115, 0.075), 0.60, _leather),
    "iron": ((0.16, 0.175, 0.185), 0.40, _iron),
    "mail": ((0.22, 0.235, 0.245), 0.40, _mail),
    "wood": ((0.19, 0.13, 0.08), 0.20, _wood),
    # The Gold-Sick's (ADR-316): gold is the one saturated colour on it, as
    # `ART-005` spends saturation on treasure; the body under it is ashen.
    "ashen": ((0.36, 0.33, 0.28), 0.80, _flesh),
    "gold": ((0.92, 0.47, 0.055), 1.00, _gold),
    "plate": ((0.235, 0.225, 0.19), 0.40, _iron),
}


def height(points, which, names):
    """Height at each point, by the material index `which` into `names`."""
    out = np.zeros(len(points))
    for i, name in enumerate(names):
        pick = which == i
        if pick.any():
            out[pick] = MATERIALS[name][2](points[pick])
    return out


def colour(points, which, names):
    out = np.zeros((len(points), 3))
    vary = 1.0 + 0.10 * S.fbm(points, 0.05, 2)
    for i, name in enumerate(names):
        pick = which == i
        if pick.any():
            out[pick] = np.asarray(MATERIALS[name][0]) * vary[pick, None]
    return out
