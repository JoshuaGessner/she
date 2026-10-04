"""A body on the shared rig, sculpted (ADR-316).

The shared rig's rest pose, in Blender's frame (metres, facing -Y, her left +X):
pelvis at 0.90–1.04, spine to the chest at 1.48, neck to 1.56, head to 1.78;
the arms hang in an A at 45° from shoulders at (±0.18, 0, 1.48) to elbows at
(±0.31, 0, 1.35) and wrists at (±0.42, 0, 1.10), the fists closed round the
grip at (±0.46, -0.035, 1.065); the legs run straight from (±0.09, 0, 0.94) to
the ankles at 0.12.

ADR-305 built five kinds of body from lofted tubes and ellipsoids stuck
together — a face was an egg with a wedge for a nose — and they read, close
up, as mannequins in costume. Here the body is **one signed distance field**,
anatomy first and clothes over it, so a shoulder is a shoulder all the way
round and a hood is a hood with a face in it:

- **The head of a Dvergar**, not an egg: a brow ridge over sunken sockets, a
  broad nose with a bridge and alae, cheekbones, a set mouth, a heavy jaw, ears,
  and a beard that falls in locks. *References: the Sigurd portal carvings at
  Hylestad, and the Oseberg cart's faces* — broad, staring, bearded.
- **Muscle on the bone**: deltoid, biceps and forearm swell; thigh, knee and
  calf; hands closed round their grip.
- **Garments as shells** over the body: tunic and skirt, sleeves, trousers,
  wraps, boots, belt, hood and cape, mail. Each garment is its own region, so
  the build knows what every face is made of — for the ink pass's material
  family and for what is carved into it (`humanoid_detail`).

`regions()` returns {material: field}; the build unions them into one mesh and
gives each face the material whose field is nearest it.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
import sdf_sculpt as S  # noqa: E402

V = np.array


# ── Anatomy ──────────────────────────────────────────────────────────────

class Build:
    """Proportions: `broad` widens the trunk and head, `limb` thickens or thins
    the limbs, `belly` swells the waist, `stature` scales the head."""

    def __init__(self, broad=1.0, limb=1.0, belly=0.0, stature=1.0, beard=1.0):
        self.broad, self.limb, self.belly, self.stature, self.beard = broad, limb, belly, stature, beard


def loft_z(p, zs, half_x, half_y, y0, power=2.4):
    """A trunk-like form from its sections up Z: half-width, half-depth and
    centre-depth at each station, superelliptic in section."""
    zs = np.asarray(zs, float)
    hx = np.interp(p[:, 2], zs, half_x)
    hy = np.interp(p[:, 2], zs, half_y)
    yc = np.interp(p[:, 2], zs, y0)
    ax = np.abs(p[:, 0]) / hx
    ay = np.abs(p[:, 1] - yc) / hy
    r = (ax ** power + ay ** power) ** (1.0 / power)
    d = (r - 1.0) * np.minimum(hx, hy) * 0.9
    ends = np.maximum(p[:, 2] - zs[-1], zs[0] - p[:, 2])
    return S.smax(d, ends, 0.04)


def tatters(p, count, depth):
    """How far a torn hem hangs at each point round the body: V-shaped tongues,
    `count` of them, each its own length, so a hem reads as torn cloth rather
    than as a battlement."""
    a = (np.arctan2(p[:, 1], p[:, 0]) / (2 * np.pi) + 0.5) * count
    i = np.floor(a)
    f = a - i
    length = 0.45 + 0.55 * ((np.sin(i * 12.9898) * 43758.5453) % 1.0)
    return depth * length * (1.0 - np.abs(2.0 * f - 1.0)) ** 1.5


def mirror(p):
    q = p.copy()
    q[:, 0] = np.abs(q[:, 0])
    return q


def trunk(p, b: Build, grow=0.0):
    """Pelvis to shoulders. `grow` swells it outward for a garment over it."""
    w = b.broad
    zs = [0.86, 0.95, 1.04, 1.12, 1.22, 1.32, 1.40, 1.46, 1.52]
    hx = np.array([0.165, 0.180, 0.158 + 0.03 * b.belly, 0.162 + 0.04 * b.belly, 0.182, 0.200, 0.205,
                   0.190, 0.110]) * w + grow
    hy = np.array([0.115, 0.120, 0.110 + 0.04 * b.belly, 0.118 + 0.05 * b.belly, 0.128, 0.132, 0.126,
                   0.110, 0.070]) + grow
    y0 = [0.005, 0.0, -0.005 - 0.02 * b.belly, -0.01 - 0.03 * b.belly, -0.012, -0.010, -0.005, 0.0, 0.0]
    d = loft_z(p, zs, hx, hy, y0)
    m = mirror(p)
    # Trapezius from neck to shoulder, and the shoulder's cap.
    d = S.smin(d, S.round_cone(m, V((0.0, 0.01, 1.50)), V((0.17 * w, 0.0, 1.455)), 0.055 + grow, 0.062 + grow), 0.05)
    d = S.smin(d, S.ellipsoid(m - V((0.185 * w, 0.0, 1.435)), V((0.072, 0.078, 0.072)) * b.limb + grow), 0.04)
    # Chest and shoulder blades, for the shape under a tunic.
    d = S.smin(d, S.ellipsoid(m - V((0.085 * w, -0.085, 1.33)), V((0.095, 0.05, 0.075)) + grow), 0.05)
    d = S.smin(d, S.ellipsoid(m - V((0.09 * w, 0.085, 1.36)), V((0.085, 0.045, 0.09)) + grow), 0.05)
    return d


def neck(p, b: Build, grow=0.0):
    return S.round_cone(p, V((0.0, 0.0, 1.47)), V((0.0, -0.01, 1.62)), 0.066 + grow, 0.058 + grow)


def head(p, b: Build):
    """The face and skull, without hair."""
    w, s = b.broad, b.stature
    m = mirror(p)
    c = V((0.0, 0.012, 1.70))
    d = S.ellipsoid(p - c, V((0.106 * w, 0.118, 0.125 * s)))
    # Face mass, brought forward.
    d = S.smin(d, S.ellipsoid(p - V((0.0, -0.045, 1.675)), V((0.085 * w, 0.075, 0.095 * s))), 0.04)
    # The jaw, heavy, and the chin.
    d = S.smin(d, S.ellipsoid(p - V((0.0, -0.045, 1.615)), V((0.085 * w, 0.072, 0.055))), 0.035)
    d = S.smin(d, S.ellipsoid(p - V((0.0, -0.097, 1.595)), V((0.036, 0.03, 0.028))), 0.02)
    # Cheekbones.
    d = S.smin(d, S.ellipsoid(m - V((0.058 * w, -0.088, 1.688)), V((0.032, 0.026, 0.022))), 0.02)
    # Brow ridge, heavy, the Dvergar's mark.
    d = S.smin(d, S.round_cone(m, V((0.012, -0.108, 1.742)), V((0.07 * w, -0.094, 1.746)), 0.022, 0.018), 0.018)
    # Sockets, sunk under it; the eyes (`EYE_AT`) sit in them.
    d = S.carve(d, S.ellipsoid(m - V((0.043, -0.112, 1.716)), V((0.026, 0.022, 0.017))), 0.010)
    # Lids.
    d = S.smin(d, S.round_cone(m, V((0.022, -0.106, 1.727)), V((0.064, -0.098, 1.724)), 0.007, 0.006), 0.006)
    # The nose: a bridge, a broad bulb, its wings and nostrils.
    d = S.smin(d, S.round_cone(p, V((0.0, -0.112, 1.735)), V((0.0, -0.148, 1.665)), 0.014, 0.019), 0.012)
    d = S.smin(d, S.sphere(p - V((0.0, -0.150, 1.662)), 0.024), 0.012)
    d = S.smin(d, S.ellipsoid(m - V((0.022, -0.136, 1.656)), V((0.016, 0.016, 0.013))), 0.008)
    d = S.carve(d, S.ellipsoid(m - V((0.013, -0.150, 1.648)), V((0.007, 0.008, 0.005))), 0.004)
    # The mouth: lips and the line between them.
    d = S.smin(d, S.round_cone(m, V((0.0, -0.118, 1.630)), V((0.028, -0.110, 1.628)), 0.009, 0.007), 0.008)
    d = S.smin(d, S.round_cone(m, V((0.0, -0.112, 1.614)), V((0.026, -0.106, 1.616)), 0.009, 0.007), 0.008)
    d = S.carve(d, S.round_cone(m, V((0.0, -0.124, 1.622)), V((0.032, -0.112, 1.622)), 0.0025, 0.0025), 0.003)
    # Ears.
    ear = S.ellipsoid(m - V((0.106 * w, 0.004, 1.700)), V((0.013, 0.028, 0.040)))
    ear = S.carve(ear, S.ellipsoid(m - V((0.114 * w, 0.002, 1.702)), V((0.006, 0.018, 0.028))), 0.004)
    return S.smin(d, ear, 0.01)


def beard(p, b: Build, length=1.0, split=False):
    """Hair: a beard falling in locks from the jaw, a moustache, brows."""
    m = mirror(p)
    L = 0.09 * length * b.beard
    w = b.broad
    # The mass on the jaw, and three locks falling from it, the middle longest.
    d = S.ellipsoid(p - V((0.0, -0.075, 1.605)), V((0.082 * w, 0.06, 0.05)))
    for x, drop, r in ((0.0, 1.0, 0.040), (0.045 * w, 0.78, 0.032)):
        for sx in ((1.0,) if x == 0.0 else (1.0, -1.0)):
            top = V((x * sx, -0.105, 1.60))
            tip = V((x * sx * 0.8, -0.128, 1.585 - L * drop))
            d = S.smin(d, S.round_cone(p, top, tip, r, 0.010), 0.025)
    if split:
        d = S.carve(d, S.round_cone(p, V((0.0, -0.15, 1.575)), V((0.0, -0.16, 1.56 - L)), 0.010, 0.020), 0.008)
    # Moustache, over the lip and down at its ends.
    d = S.smin(d, S.chain(m, [V((0.0, -0.133, 1.640)), V((0.03, -0.125, 1.633)), V((0.048, -0.112, 1.612))],
                          [0.011, 0.012, 0.008], 0.008), 0.01)
    # Brows.
    d = S.smin(d, S.round_cone(m, V((0.016, -0.118, 1.752)), V((0.068, -0.103, 1.754)), 0.010, 0.008), 0.004)
    # Keep the mouth open to the eye: cut the hair back from the lips.
    d = S.carve(d, S.ellipsoid(p - V((0.0, -0.125, 1.622)), V((0.030, 0.02, 0.012))), 0.006)
    return d


def arm(p, side, b: Build, grow=0.0):
    """Shoulder to wrist, muscle on it."""
    sx = 1.0 if side == "l" else -1.0
    sh, el, wr = V((0.18 * sx, 0.0, 1.475)), V((0.31 * sx, 0.0, 1.35)), V((0.42 * sx, 0.0, 1.10))
    k = b.limb
    d = S.round_cone(p, sh, el, 0.056 * k + grow, 0.044 * k + grow)
    mid = sh * 0.45 + el * 0.55
    d = S.smin(d, S.ellipsoid(p - (mid + V((0.0, -0.02, 0.0))), V((0.045, 0.045, 0.06)) * k + grow), 0.03)
    d = S.smin(d, S.ellipsoid(p - (mid + V((0.0, 0.025, 0.01))), V((0.042, 0.04, 0.06)) * k + grow), 0.03)
    d = S.smin(d, S.sphere(p - el, 0.045 * k + grow), 0.02)
    d = S.smin(d, S.round_cone(p, el, wr, 0.047 * k + grow, 0.031 * k + grow), 0.02)
    d = S.smin(d, S.ellipsoid(p - (el * 0.7 + wr * 0.3 + V((0.0, -0.01, 0.0))), V((0.04, 0.042, 0.065)) * k + grow), 0.03)
    return d


def hand(p, side, b: Build):
    """A fist closed round the grip, which runs along -Y through `GRIP`."""
    sx = 1.0 if side == "l" else -1.0
    grip = V((0.45 * sx, -0.028, 1.09))
    wr = V((0.42 * sx, 0.0, 1.10))
    d = S.round_cone(p, wr, grip + V((0.02 * sx, 0.008, 0.0)), 0.032, 0.036)
    d = S.smin(d, S.ellipsoid(p - (grip + V((0.026 * sx, 0.008, 0.002))), V((0.026, 0.045, 0.040))), 0.015)
    for f in range(4):
        y = -0.056 + f * 0.017
        pts = [grip + V((sx * x, y - grip[1], z)) for x, z in
               ((0.023, 0.018), (0.032, -0.005), (0.021, -0.027), (-0.006, -0.032), (-0.020, -0.018))]
        d = S.smin(d, S.chain(p, pts, [0.0095, 0.0092, 0.0088, 0.0082, 0.0075], 0.004), 0.006)
    d = S.smin(d, S.chain(p, [grip + V((-0.012 * sx, 0.02, 0.018)), grip + V((-0.024 * sx, -0.005, 0.028)),
                              grip + V((-0.022 * sx, -0.03, 0.022))], [0.012, 0.011, 0.009], 0.004), 0.008)
    return d


def leg(p, side, b: Build, grow=0.0):
    sx = 1.0 if side == "l" else -1.0
    hip, knee, ankle = V((0.09 * sx, 0.0, 0.94)), V((0.09 * sx, -0.005, 0.55)), V((0.09 * sx, 0.0, 0.12))
    k = b.limb
    d = S.round_cone(p, hip, knee, 0.088 * k + grow, 0.055 * k + grow)
    d = S.smin(d, S.ellipsoid(p - (hip * 0.5 + knee * 0.5 + V((0.0, -0.03, 0.04))), V((0.07, 0.06, 0.15)) * k + grow), 0.04)
    d = S.smin(d, S.sphere(p - knee, 0.054 * k + grow), 0.02)
    d = S.smin(d, S.round_cone(p, knee, ankle, 0.054 * k + grow, 0.034 * k + grow), 0.02)
    d = S.smin(d, S.ellipsoid(p - (knee * 0.7 + ankle * 0.3 + V((0.0, 0.025, 0.0))), V((0.048, 0.045, 0.10)) * k + grow), 0.03)
    return d


def foot(p, side, grow=0.0, toe=0.0):
    """A boot's foot: heel, sole, and a toe pointed along -Y."""
    sx = 1.0 if side == "l" else -1.0
    d = S.round_cone(p, V((0.09 * sx, 0.015, 0.06)), V((0.09 * sx, -0.17 - toe, 0.045)), 0.058 + grow, 0.042 + grow)
    d = S.smin(d, S.round_cone(p, V((0.09 * sx, 0.0, 0.14)), V((0.09 * sx, 0.01, 0.06)), 0.05 + grow, 0.056 + grow), 0.03)
    return S.smax(d, -p[:, 2], 0.01)


# ── Garments ─────────────────────────────────────────────────────────────

def tunic(p, b: Build, hem=0.62, flare=0.10, torn=0.0, slit=True, grow=0.016):
    """Body to hem: the trunk grown, then a skirt flaring to `hem`. `torn`
    cuts the hem into tongues; `slit` opens it front and back for the stride."""
    d = trunk(p, b, grow)
    zs = [hem - 0.02, hem + 0.15, 0.86, 0.96]
    hx = np.array([0.20 + flare, 0.19 + flare * 0.7, 0.18, 0.18]) * b.broad + grow
    hy = np.array([0.15 + flare * 0.6, 0.14 + flare * 0.4, 0.13, 0.125]) + grow
    skirt = loft_z(p, zs, hx, hy, [0.0, 0.0, 0.0, 0.0], 2.2)
    if torn > 0:
        skirt = S.smax(skirt, (hem + torn - tatters(p, 14, torn)) - p[:, 2], 0.006)
    d = S.smin(d, skirt, 0.04)
    if slit:
        cut = S.round_box(p - V((0.0, 0.0, hem + 0.06)), V((0.025, 0.4, 0.09)), 0.02)
        d = S.carve(d, cut, 0.015)
    # A skirt is a shell: hollow it so the legs are under it, not inside a block.
    inner = loft_z(p, [hem - 0.05, 0.84], np.array([0.18 + flare, 0.15]) * b.broad,
                   np.array([0.13 + flare * 0.6, 0.10]), [0.0, 0.0], 2.2)
    return S.carve(d, S.smax(inner, p[:, 2] - 0.84, 0.01), 0.008)


def sleeve(p, side, b: Build, to=0.5, grow=0.014):
    """A sleeve from the shoulder `to` a fraction down the arm (0.5 the
    elbow, 1.0 the wrist), with a turned cuff."""
    sx = 1.0 if side == "l" else -1.0
    sh, el, wr = V((0.18 * sx, 0.0, 1.475)), V((0.31 * sx, 0.0, 1.35)), V((0.42 * sx, 0.0, 1.10))
    end = sh + (el - sh) * min(to * 2.0, 1.0) if to <= 0.5 else el + (wr - el) * (to - 0.5) * 2.0
    d = arm(p, side, b, grow)
    axis = (wr - sh) / np.linalg.norm(wr - sh)
    beyond = (p - end) @ axis
    d = S.smax(d, beyond, 0.008)
    cuff = S.round_cone(p, end - axis * 0.03, end, 0.06 * b.limb + grow * 1.6, 0.06 * b.limb + grow * 1.6)
    return S.smin(d, cuff, 0.01)


def trousers(p, b: Build, top=0.98, bottom=0.30, grow=0.012):
    d = np.minimum(leg(p, "l", b, grow), leg(p, "r", b, grow))
    d = S.smin(d, S.ellipsoid(p - V((0.0, 0.0, 0.92)), V((0.19 * b.broad, 0.13, 0.10)) + grow), 0.05)
    return S.smax(S.smax(d, p[:, 2] - top, 0.02), bottom - p[:, 2], 0.02)


def boots(p, b: Build, top=0.30, grow=0.022):
    d = np.minimum(foot(p, "l", grow * 0.6), foot(p, "r", grow * 0.6))
    shaft = np.minimum(leg(p, "l", b, grow), leg(p, "r", b, grow))
    d = S.smin(d, S.smax(shaft, p[:, 2] - top, 0.015), 0.03)
    # The cuff at the top.
    for sx in (-1.0, 1.0):
        d = S.smin(d, S.round_cone(p, V((0.09 * sx, 0.0, top - 0.025)), V((0.09 * sx, 0.0, top)),
                                   0.052 * b.limb + grow * 1.5, 0.052 * b.limb + grow * 1.5), 0.01)
    return d


def wraps(p, b: Build, legs=True, arms=False, grow=0.008):
    """Rag wound round calves and forearms, in tilted turns."""
    d = np.full(len(p), 1e3)
    if legs:
        for sx in (-1.0, 1.0):
            for i, z in enumerate(np.linspace(0.30, 0.48, 5)):
                tilt = 0.012 * (1 if i % 2 else -1)
                q = p - V((0.09 * sx, 0.0, z))
                q[:, 2] -= tilt * q[:, 0] / 0.05
                r = 0.05 * b.limb + grow
                d = np.minimum(d, S.torus(q, r, 0.013))
    if arms:
        for sx in (-1.0, 1.0):
            el, wr = V((0.31 * sx, 0.0, 1.35)), V((0.42 * sx, 0.0, 1.10))
            axis = (wr - el) / np.linalg.norm(wr - el)
            for i, f in enumerate(np.linspace(0.30, 0.82, 4)):
                c = el + (wr - el) * f
                q = p - c
                # Into the forearm's frame: z along it.
                zt = q @ axis
                rad = np.linalg.norm(q - np.outer(zt, axis), axis=1)
                r = (0.047 + (0.031 - 0.047) * f) * b.limb + grow
                d = np.minimum(d, np.hypot(rad - r, zt) - 0.012)
    return d


def belt(p, b: Build, z=1.04, grow=0.034):
    q = p - V((0.0, -0.01, z))
    hx, hy = 0.17 * b.broad + grow, 0.12 + grow + 0.03 * b.belly
    ring = loft_z(p, [z - 0.022, z + 0.022], [hx, hx], [hy, hy], [-0.012, -0.012], 2.6)
    buckle = S.round_box(q - V((0.0, -hy - 0.004, 0.0)), V((0.032, 0.012, 0.026)), 0.004)
    return S.smin(ring, buckle, 0.004)


def hood(p, b: Build, grow=0.026, cape=0.12, tail=0.0, torn=0.0):
    """A hood over the skull with the face open, a cape on the shoulders, and
    optionally a tail (the gugel's liripipe). Skjoldehamn and Bocksten."""
    w = b.broad
    shell = S.ellipsoid(p - V((0.0, 0.025, 1.705)), V((0.112 * w + grow, 0.13 + grow, 0.135 * b.stature + grow)))
    shell = S.smin(shell, S.round_cone(p, V((0.0, 0.03, 1.58)), V((0.0, 0.01, 1.68)), 0.09 + grow, 0.10 + grow), 0.04)
    # The cape: a cone from the throat out over the shoulders.
    zs = [1.42 - cape, 1.44, 1.52, 1.58]
    hx = np.array([0.30, 0.27, 0.17, 0.10]) * w + grow
    hy = np.array([0.20, 0.18, 0.13, 0.09]) + grow
    capelet = loft_z(p, zs, hx, hy, [0.01, 0.01, 0.01, 0.01], 2.0)
    if torn > 0:
        capelet = S.smax(capelet, (1.42 - cape + torn - tatters(p, 16, torn)) - p[:, 2], 0.006)
    d = S.smin(shell, capelet, 0.05)
    if tail > 0:
        pts = [V((0.0, 0.10, 1.80)), V((0.0, 0.17, 1.76)), V((0.0, 0.22, 1.66)),
               V((0.0, 0.24, 1.66 - tail * 0.5)), V((0.0, 0.235, 1.66 - tail))]
        d = S.smin(d, S.chain(p, pts, [0.06, 0.045, 0.034, 0.024, 0.01], 0.02), 0.03)
    # The face opening, and a rolled rim round it.
    opening = S.ellipsoid(p - V((0.0, -0.14, 1.68)), V((0.085 * w, 0.12, 0.112)))
    d = S.carve(d, opening, 0.012)
    rim = S.torus(S.into(p, S.move((0.0, -0.095, 1.69)) @ S.rot((1, 0, 0), 90.0) @ S.rot((1, 0, 0), -8.0)),
                  0.092 * w, 0.014)
    d = S.smin(d, rim, 0.01)
    # Hollow, so the head is in it.
    return S.carve(d, S.ellipsoid(p - V((0.0, 0.02, 1.70)), V((0.10 * w, 0.115, 0.122))), 0.005)


def mail_coat(p, b: Build, hem=0.56, sleeves=0.42):
    d = tunic(p, b, hem=hem, flare=0.08, slit=True, grow=0.022)
    for side in ("l", "r"):
        d = S.smin(d, sleeve(p, side, b, to=sleeves, grow=0.020), 0.02)
    return d


def bound_hair(p, b: Build, braid=0.30):
    """Hair bound back under a band, a braid down the spine: the Sling-Wretch's."""
    w = b.broad
    cap = S.ellipsoid(p - V((0.0, 0.025, 1.715)), V((0.110 * w, 0.125, 0.128 * b.stature)) + 0.008)
    # Off the face: the hairline runs back from the brow and down behind the ears.
    face = S.ellipsoid(p - V((0.0, -0.12, 1.66)), V((0.095 * w, 0.10, 0.10)))
    cap = S.carve(cap, face, 0.015)
    cap = S.carve(cap, S.ellipsoid(mirror(p) - V((0.11 * w, -0.01, 1.68)), V((0.03, 0.05, 0.06))), 0.01)
    pts = [V((0.0, 0.13, 1.70)), V((0.0, 0.16, 1.62)), V((0.0, 0.175, 1.52)), V((0.0, 0.18, 1.70 - braid))]
    d = S.smin(cap, S.chain(p, pts, [0.032, 0.028, 0.024, 0.010], 0.01), 0.02)
    # The braid's plaits.
    q = p - V((0.0, 0.17, 0.0))
    plait = 0.006 * np.sin(p[:, 2] * 2 * np.pi / 0.03)
    return d + np.where(np.abs(q[:, 1]) < 0.04, plait * (p[:, 2] < 1.66), 0.0)


def headband(p, b: Build):
    q = S.into(p, S.move((0.0, 0.015, 1.752)))
    hx, hy = 0.112 * b.broad + 0.010, 0.128 + 0.010
    return loft_z(q + V((0.0, 0.0, 0.0)), [-0.013, 0.013], [hx, hx], [hy, hy], [0.0, 0.0], 2.0)


def mantle(p, b: Build, side="l", drop=0.16, torn=0.05):
    """A hide over one shoulder only, front to back, its hem torn."""
    sx = 1.0 if side == "l" else -1.0
    zs = [1.42 - drop, 1.44, 1.52, 1.57]
    hx = np.array([0.33, 0.30, 0.19, 0.11]) * b.broad + 0.03
    hy = np.array([0.22, 0.20, 0.145, 0.10]) + 0.03
    d = loft_z(p, zs, hx, hy, [0.01] * 4, 2.0)
    d = S.smax(d, -sx * p[:, 0] - 0.02, 0.03)
    if torn > 0:
        d = S.smax(d, (1.42 - drop + torn - tatters(p, 12, torn)) - p[:, 2], 0.006)
    return S.carve(d, loft_z(p, [1.30, 1.56], np.array([0.30, 0.10]) * b.broad, [0.18, 0.08], [0.01, 0.01], 2.0), 0.01)


def strap(p, points, radius=0.012):
    return S.chain(p, [V(q) for q in points], [radius] * len(points), 0.0)


def collar(p, z=1.565, rx=0.13, ry=0.118, thick=0.018):
    q = p - V((0.0, 0.01, z))
    ring = np.hypot(np.hypot(q[:, 0] / rx, q[:, 1] / ry) * min(rx, ry) - min(rx, ry), q[:, 2] * 1.5)
    return ring - thick


def spangenhelm(p, b: Build):
    """A cone in ribbed plates on a brow band, a nasal, and the Gjermundbu
    helm's spectacle guard — clear of the eyes, where the senses are drawn."""
    w = b.broad
    cone = S.round_cone(p, V((0.0, 0.01, 1.70)), V((0.0, 0.01, 1.95)), 0.148 * w, 0.02)
    cone = S.smax(cone, 1.695 - p[:, 2], 0.01)
    band = loft_z(p, [1.69, 1.735], [0.158 * w, 0.158 * w], [0.156, 0.156], [0.008, 0.008], 2.0)
    d = S.smin(cone, band, 0.006)
    for k in range(4):
        a = k * np.pi / 2 + np.pi / 4
        base = V((0.148 * w * np.cos(a), 0.01 + 0.146 * np.sin(a), 1.725))
        d = S.smin(d, S.round_cone(p, base, V((0.0, 0.01, 1.94)), 0.012, 0.006), 0.004)
    d = S.smin(d, S.round_box(p - V((0.0, -0.158, 1.665)), V((0.017, 0.008, 0.062)), 0.006), 0.006)
    m = mirror(p)
    ring = S.torus(S.into(m, S.move((0.048, -0.152, 1.708)) @ S.rot((1, 0, 0), 90.0)), 0.034, 0.007)
    return S.smin(d, ring, 0.004)


def aventail(p, b: Build, front_open=True):
    """Mail from the helm's rim to the shoulders, open over the face."""
    w = b.broad
    zs = [1.47, 1.54, 1.62, 1.70]
    hx = np.array([0.24, 0.19, 0.16, 0.155]) * w + 0.01
    hy = np.array([0.18, 0.16, 0.155, 0.153]) + 0.01
    d = loft_z(p, zs, hx, hy, [0.015] * 4, 2.2)
    # A shell thick enough to mesh: mail hangs heavy, and a centimetre of it
    # breaks into shards at the voxel the body is meshed at.
    d = S.carve(d, loft_z(p, [1.46, 1.71], np.array([0.205, 0.128]) * w, [0.15, 0.13], [0.015, 0.015], 2.2), 0.006)
    if front_open:
        d = S.carve(d, S.ellipsoid(p - V((0.0, -0.17, 1.655)), V((0.092 * w, 0.14, 0.105))), 0.012)
    return d


def lamellar(p, b: Build, rows=3):
    """Overlapping plates stepping down over each shoulder."""
    m = mirror(p)
    d = np.full(len(p), 1e3)
    for k in range(rows):
        c = V((0.24 * b.broad + k * 0.045, 0.0, 1.50 - k * 0.065))
        q = S.into(m, S.move(c) @ S.rot((0, 1, 0), -38.0 - k * 6.0))
        plate = S.round_box(q, V((0.075, 0.15, 0.010)), 0.006)
        plate = S.smax(plate, -S.ellipsoid(q - V((0.0, 0.0, -0.10)), V((0.30, 0.30, 0.11))), 0.004)
        d = np.minimum(d, plate)
    return d


def cloak(p, b: Build, hem=0.48):
    """A cloak from both shoulders to `hem`, open at the front and swept
    behind the arms."""
    w = b.broad
    zs = [hem, 0.90, 1.25, 1.40, 1.48, 1.54, 1.575]
    hx = np.array([0.36, 0.33, 0.31, 0.29, 0.25, 0.19, 0.12]) * w + 0.02
    hy = np.array([0.27, 0.25, 0.22, 0.20, 0.17, 0.14, 0.10]) + 0.02
    d = loft_z(p, zs, hx, hy, [0.04, 0.035, 0.03, 0.025, 0.02, 0.015, 0.01], 2.3)
    inner = loft_z(p, [hem - 0.05, 0.90, 1.25, 1.40], np.array([0.33, 0.30, 0.28, 0.26]) * w,
                   np.array([0.24, 0.22, 0.19, 0.17]), [0.04, 0.035, 0.03, 0.025], 2.3)
    d = S.carve(d, S.smax(inner, p[:, 2] - 1.40, 0.02), 0.005)
    # Open at the front below the clasp, and behind the arms at the sides.
    d = S.carve(d, S.round_box(p - V((0.0, -0.30, hem + 0.45)), V((0.22 * w, 0.20, 0.50)), 0.05), 0.02)
    clasp = S.sphere(mirror(p) - V((0.10 * w, -0.125, 1.50)), 0.022)
    return S.smin(d, clasp, 0.005)


def arm_rings(p, side, b: Build, at=(0.50, 0.62, 0.74)):
    sx = 1.0 if side == "l" else -1.0
    el, wr = V((0.31 * sx, 0.0, 1.35)), V((0.42 * sx, 0.0, 1.10))
    axis = (wr - el) / np.linalg.norm(wr - el)
    d = np.full(len(p), 1e3)
    for f in at:
        c = el + (wr - el) * f
        q = p - c
        zt = q @ axis
        rad = np.linalg.norm(q - np.outer(zt, axis), axis=1)
        r = (0.047 + (0.031 - 0.047) * f) * b.limb + 0.010
        d = np.minimum(d, np.hypot(rad - r, zt) - 0.009)
    return d


def crested_helm(p, b: Build):
    """A rounded helm with a crest from brow to nape, brow arches and a nasal
    (the Vendel and Valsgärde helms) — the eyes left clear."""
    w = b.broad
    dome = S.ellipsoid(p - V((0.0, 0.01, 1.72)), V((0.150 * w, 0.148, 0.19)))
    dome = S.smax(dome, 1.695 - p[:, 2], 0.01)
    rim = loft_z(p, [1.69, 1.725], [0.155 * w, 0.155 * w], [0.152, 0.152], [0.01, 0.01], 2.0)
    d = S.smin(dome, rim, 0.006)
    crest = S.chain(p, [V((0.0, -0.15, 1.75)), V((0.0, -0.12, 1.86)), V((0.0, -0.04, 1.925)),
                        V((0.0, 0.06, 1.925)), V((0.0, 0.14, 1.85)), V((0.0, 0.165, 1.75))],
                    [0.016, 0.019, 0.019, 0.019, 0.019, 0.016], 0.0)
    d = S.smin(d, crest, 0.008)
    m = mirror(p)
    arch = S.chain(m, [V((0.008, -0.162, 1.73)), V((0.045, -0.157, 1.745)), V((0.095 * w, -0.138, 1.73))],
                   [0.010, 0.010, 0.009], 0.0)
    d = S.smin(d, arch, 0.006)
    return S.smin(d, S.round_box(p - V((0.0, -0.165, 1.67)), V((0.015, 0.007, 0.055)), 0.005), 0.006)


def coin(p, centre, radius, thick, tilt):
    """A struck coin: a disc with a raised rim, at any angle."""
    q = S.into(p, S.move(centre) @ S.rot((1, 0, 0), tilt[0]) @ S.rot((0, 1, 0), tilt[1]) @ S.rot((0, 0, 1), tilt[2]))
    radial = np.hypot(q[:, 0], q[:, 1]) - radius
    flat = np.abs(q[:, 2]) - thick
    d = np.minimum(np.maximum(radial, flat), 0.0) + np.hypot(np.maximum(radial, 0.0), np.maximum(flat, 0.0)) - 0.002
    rim = np.hypot(np.hypot(q[:, 0], q[:, 1]) - radius * 0.86, np.abs(q[:, 2]) - thick) - 0.004
    return np.minimum(d, rim)


def coin_mass(p, coins, blend=0.012):
    """Many coins fused into one mass, as the Gold-Sick's are: each still
    reads as a coin at its edge, and they have run together where they touch."""
    d = np.full(len(p), 1e3)
    for c in coins:
        near = np.linalg.norm(p - c[0], axis=1) < c[1] * 2.5 + blend
        if near.any():
            d[near] = S.smin(d[near], coin(p[near], *c), blend)
    return d


def sack(p, centre, radii, tie=0.95):
    c = V(centre)
    d = S.ellipsoid(p - c, V(radii))
    neck = S.round_cone(p, c + V((0.0, 0.0, radii[2] * 0.7)), c + V((0.0, -0.01, radii[2] * 1.05)),
                        radii[0] * 0.45, radii[0] * 0.55)
    d = S.smin(d, neck, 0.03)
    tie_ring = S.torus(p - (c + V((0.0, 0.0, radii[2] * 0.82))), radii[0] * 0.48, 0.010)
    return S.smin(d, tie_ring, 0.006)


def breastplate(p, b: Build):
    """A split Dvergar breastplate on the chest, broken on its right."""
    plate = trunk(p, b, 0.04)
    plate = S.smax(plate, -(-0.10 - p[:, 1]), 0.02)
    plate = S.smax(plate, p[:, 2] - 1.46, 0.02)
    plate = S.smax(plate, 1.05 - p[:, 2], 0.02)
    # Broken away below the right shoulder.
    plate = S.carve(plate, S.ellipsoid(p - V((-0.20, -0.16, 1.18)), V((0.14, 0.12, 0.16))), 0.02)
    inner = trunk(p, b, 0.018)
    return S.carve(plate, inner, 0.005)


# ── Eyes ─────────────────────────────────────────────────────────────────
## Where `EnemyVisual` puts the sense eyes (EYE_AT in the head bone's frame):
## the sockets above are cut round these.
EYE = V((0.042, -0.112, 1.715))
