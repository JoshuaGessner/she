"""Her body, everything but the head, as one signed distance field (ADR-315).

One field, so every join is a true fillet: the forelegs grow out of the chest,
the neck out of the shoulders, and where she goes into the wall or the floor
she is *cut* by it, flush, as if the stone carries on being her.

World frame (Blender), metres, matching `build_her.py`: origin at the centre
of the hoard, the door along -Y, the back wall's face at y = 2.7, the floor at
z = 0. The way in, |x| < 1.4 in front of the pile, is left clear below 2.6 m.

**The pose** — couchant, a guardian at rest who is not asleep:
- Her body comes **out of the back wall high on the right**, descends to the
  floor and lies along the right of the hoard; her two forelegs lie forward on
  the stone, forearms flat, as a lion couchant's or a resting monitor
  lizard's do.
- Her **neck rises up and back** over the pile and her head arches forward and
  down over its front — the swan-necked S every looming serpent in the
  carvings makes, and the only way a head can come at you from *above*.
- Her **tail comes out of the wall low on the left**, lies round the left of the
  hoard, tapering all the way, and lifts at its end into an upright Urnes curl
  in front of it.
- An **arch of her rises out of the floor** behind the pile and dives back in:
  the Midgard serpent of the Altuna stone and Thor's fishing, a body swimming
  through rock as through water.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
import sdf_sculpt as S  # noqa: E402
import her_body as B  # noqa: E402

WALL_Y = 2.78
FLOOR_Z = -0.06
## Where the neck ends: inside the back of her skull. The head is its own node,
## pivoted here, aimed `HEAD_AIM` degrees about Z and `HEAD_PITCH` down.
NECK_END = np.array([0.62, -0.72, 4.35])
HEAD_AIM = -38.0
HEAD_PITCH = 24.0
## The head is authored at 1:1 and worn larger: a head in proportion to a body
## this heavy (ADR-284's model wore its head at the same 1.35).
HEAD_SCALE = 1.35


def head_frame():
    """World-from-head: the frame `her_head_sdf` is authored in."""
    return (S.move(NECK_END) @ S.rot((0, 0, 1), HEAD_AIM) @ S.rot((1, 0, 0), HEAD_PITCH)
            @ np.diag([HEAD_SCALE, HEAD_SCALE, HEAD_SCALE, 1.0]))


def _neck_entry():
    """The neck comes into the back of the skull from behind and below, so it
    reads as carrying the head rather than meeting it from the side."""
    f = head_frame()
    back = f[:3, :3] @ np.array([0.0, 1.0, -0.55])
    back /= np.linalg.norm(back)
    return [NECK_END + back * 1.4, NECK_END + back * 0.65, NECK_END + f[:3, :3] @ np.array([0.0, -0.05, 0.0])]


## Band paths are resampled evenly, so a radius is the same whether it is read
## per point (`S.band`) or by arc length (the crest, the carving).
BAND_STEP = 0.08


def _even(path, at, radii):
    """`path` resampled every `BAND_STEP`, and its radius interpolated at each
    fraction of its length from (`at`, `radii`)."""
    pts, s = B.resample(path, BAND_STEP)
    return pts, np.interp(s / s[-1], at, radii)


def _tail_curl(end, heading, rise, turns, shrink, steps=48):
    """The end of her tail lifting off the floor into a spiral that stands
    upright, facing the door: the spirals the Urnes portal's ribbon-beasts
    and tendrils turn into, and the fiddlehead they echo. Upright so it
    reads from the door as a tail's end, and a spiral so it tapers to a point
    that can be seen rather than hiding in its own coil."""
    d = np.array([heading[0], heading[1], 0.0])
    d /= np.linalg.norm(d)
    z = np.array([0.0, 0.0, 1.0])
    centre = np.asarray(end, float) + z * rise
    out = []
    for i in range(1, steps + 1):
        f = i / steps
        a = -0.5 * np.pi + f * turns * 2.0 * np.pi
        r = rise * (1.0 - shrink * f)
        out.append(centre + r * (np.cos(a) * d + np.sin(a) * z))
    return np.array(out)


def bands():
    """The swept parts of her: (name, path points, radii along it)."""
    entry = _neck_entry()
    body = B.spline([(3.2, 3.4, 2.6), (3.95, 2.2, 1.85), (4.25, 0.9, 1.15), (4.15, -0.35, 1.0),
                     (3.75, -1.25, 1.40), (3.05, -1.55, 2.35), (2.25, -1.05, 3.25),
                     tuple(entry[0]), tuple(entry[1]), tuple(entry[2])], 10)
    body, body_r = _even(body, [0.0, 0.18, 0.36, 0.48, 0.60, 0.72, 0.84, 0.93, 1.0],
                         [0.90, 1.0, 1.10, 1.02, 0.80, 0.60, 0.50, 0.44, 0.40])
    lying = B.spline([(-3.0, 3.5, 0.70), (-4.15, 2.0, 0.78), (-4.55, 0.2, 0.70), (-4.05, -1.55, 0.55),
                      (-3.25, -2.70, 0.40), (-2.55, -2.95, 0.34)], 10)
    # Wide and slender, as a chameleon's coiled tail is: a coil about six
    # times its own thickness reads as a tail's end from any side, a fatter
    # one as a shell.
    curl = _tail_curl(lying[-1], lying[-1] - lying[-4], rise=0.95, turns=1.30, shrink=0.85)
    # Tapering the whole way, wall to tip, and already slender where it lifts:
    # a tail that keeps its girth into its curl reads as a coil of hose, and
    # one that is still thick where it starts to turn reads as a snail's shell.
    tail, tail_r = _even(np.concatenate([lying, curl]), [0.0, 0.25, 0.50, 0.65, 0.80, 1.0],
                         [0.80, 0.68, 0.44, 0.20, 0.10, 0.02])
    arch = B.spline([(2.0, 2.65, -0.55), (1.15, 2.05, 0.95), (-0.15, 1.95, 1.35), (-1.35, 2.15, 0.95),
                     (-2.15, 2.70, -0.55)], 10)
    arch, arch_r = _even(arch, [0.0, 0.5, 1.0], [0.70, 0.66, 0.68])
    return [("body", body, body_r), ("tail", tail, tail_r), ("arch", arch, arch_r)]


## The forelegs, couchant: shoulder, elbow on the floor, forearm lying forward
## along the stone, and a hand of four clawed digits with a dewclaw. Kept clear
## of the brazier at (5.6, -1.4).
LEGS = {
    "outer": dict(shoulder=(4.40, -0.95, 1.10), elbow=(4.55, -0.55, 0.42), wrist=(4.42, -2.60, 0.30),
                  hand=(4.40, -3.10, 0.17), spread=1.0, size=1.45),
    "inner": dict(shoulder=(3.30, -1.40, 1.00), elbow=(3.05, -0.95, 0.42), wrist=(2.92, -2.75, 0.28),
                  hand=(2.88, -3.22, 0.16), spread=-1.0, size=1.38),
}


def _leg(p, shoulder, elbow, wrist, hand, spread, size):
    s, e, w, h = (np.asarray(x, float) for x in (shoulder, elbow, wrist, hand))
    d = S.ellipsoid(p - s, np.array([0.44, 0.50, 0.46]) * size)
    # Upper arm, with the swell of its muscle.
    d = S.smin(d, S.round_cone(p, s, e, 0.36 * size, 0.24 * size), 0.18)
    d = S.smin(d, S.ellipsoid(p - (s * 0.55 + e * 0.45 + np.array([0.0, -0.12, 0.0])),
                              np.array([0.30, 0.30, 0.34]) * size), 0.12)
    d = S.smin(d, S.sphere(p - e, 0.24 * size), 0.08)
    # Forearm, thick at the elbow, lying along the floor.
    fore_mid = e * 0.62 + w * 0.38 + np.array([0.0, 0.0, 0.10 * size])
    d = S.smin(d, S.round_cone(p, e, w, 0.25 * size, 0.16 * size), 0.10)
    d = S.smin(d, S.ellipsoid(p - fore_mid, np.array([0.22, 0.42, 0.18]) * size), 0.10)
    # The hand: a broad flat palm, four digits fanned forward, claws down.
    d = S.smin(d, S.ellipsoid(p - h, np.array([0.30, 0.30, 0.13]) * size), 0.10)
    d = S.smin(d, S.round_cone(p, w, h, 0.17 * size, 0.15 * size), 0.06)
    for k, fan in enumerate((-0.55, -0.18, 0.18, 0.55)):
        long = (0.95 if abs(fan) < 0.3 else 0.80) * size
        base = h + np.array([0.20 * fan * size * 1.4, -0.12 * size, 0.0])
        knuckle = base + np.array([0.20 * fan * size, -0.26 * long, 0.04 * size])
        tipj = knuckle + np.array([0.10 * fan * size, -0.20 * long, -0.03 * size])
        d = S.smin(d, S.chain(p, [base, knuckle, tipj], [0.085 * size, 0.07 * size, 0.06 * size], 0.03), 0.05)
        # The claw: curved, sharp, hooked down into the stone.
        c0 = tipj + np.array([0.0, -0.04 * size, 0.0])
        c1 = c0 + np.array([0.04 * fan * size, -0.16 * size, -0.01 * size])
        c2 = c1 + np.array([0.02 * fan * size, -0.10 * size, -0.10 * size])
        d = S.smin(d, S.chain(p, [c0, c1, c2], [0.055 * size, 0.035 * size, 0.004], 0.0), 0.02)
    # Dewclaw on the inside of the wrist.
    dw = w + np.array([-0.18 * spread * size, -0.05 * size, 0.06 * size])
    d = S.smin(d, S.chain(p, [dw, dw + np.array([-0.08 * spread * size, -0.10 * size, -0.06 * size])],
                          [0.05 * size, 0.004], 0.0), 0.03)
    return d


def skin(p):
    """The body's surface without the crest: bands and forelegs."""
    d = np.full(len(p), 1e3)
    for name, path, radii in bands():
        d = np.minimum(d, S.band(p, path, radii, k=0.0))
    for leg in LEGS.values():
        d = S.smin(d, _leg(p, **leg), 0.24)
    # Cut by the wall and the floor, flush, as if the stone carries on.
    d = S.smax(d, p[:, 1] - WALL_Y, 0.04)
    d = S.smax(d, FLOOR_Z - p[:, 2], 0.04)
    return d


BOUNDS = ((-5.6, -4.5, -0.15), (6.1, 2.9, 4.95))
