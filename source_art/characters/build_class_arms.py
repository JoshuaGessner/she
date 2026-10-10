"""Six DES-020 class arm pairs, sculpted (ADR-319), on the permanent humanoid bind pose.

Run with Blender:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \\
      --python source_art/characters/build_class_arms.py

**The most-seen model in the game.** These are the forearms and hands in front
of the camera for every second of every run. ADR-280 got their *pose* right
and built them from lofted tubes; they are now sculpted as the bodies are
(ADR-316, ADR-318), so a knuckle, a tendon and the heel of a hand are shapes,
and what each class carries on its skin — the Völva's ink, the Húskarl's healed
cuts — is baked into the surface rather than stuck to it.

**Closed fists around the grip** (ADR-280). The shared rig has hand bones and
no finger bones, so the fingers are posed once, in the mesh, and the pose that
matters in first person is the one holding something: every item the hands
carry is hung from `sock_hand_*`, so the fist is built around that socket's
axis, read from the rig at build time. The forearm and wrist deform with the
shared skeleton; never add a competing armature hierarchy.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

SRC = Path(__file__).resolve().parent
OUT = SRC.parents[1] / "game" / "art" / "characters"
sys.path.insert(0, str(SRC.parent / "enemies"))
sys.path.insert(0, str(SRC.parent / "lib"))
sys.path.insert(0, str(SRC))
import build_enemies as E  # noqa: E402
import build_enemy_models as em  # noqa: E402
import humanoid_detail as Dt  # noqa: E402
import sdf_sculpt as S  # noqa: E402


def _skin(p):
    # Pores, and the faint lines over the back of a hand and a wrist.
    return 0.00025 * S.fbm(p, 0.004, 2) + 0.0004 * S.noise(p, 0.012)


def _scar(p):
    return 0.0006 * S.noise(p, 0.003)


## A hand's colours (ADR-319): the class arms' palette, which ADR-280's review
## was lit against, now with a little variation through it.
Dt.MATERIALS.update({
    "skin": ((0.57, 0.49, 0.40), 0.80, _skin),
    "scar": ((0.66, 0.53, 0.45), 0.80, _scar),
    "ink": ((0.11, 0.105, 0.10), 0.80, _skin),
    "bone": ((0.66, 0.63, 0.53), 0.80, Dt.MATERIALS["wood"][2]),
    "nail": ((0.62, 0.52, 0.44), 0.80, _scar),
    "fur": ((0.24, 0.22, 0.19), 0.80, lambda p: 0.0014 * S.fbm(p * np.array([1.0, 1.0, 0.3]), 0.008, 2)),
    # Barrow-earth worked into the skin (ADR-057): a mound-breaker's hands.
    "grave": ((0.27, 0.21, 0.16), 0.85, _skin),
})

## A first-person budget: most of a character's, because these are seen from
## centimetres away; a voxel a finger can be sculpted in, and a dense map.
PLAN = dict(voxel=0.0028, body_tris=9000, texture=1024, ceiling=10000, sparse=True)
CLASSES = ("huskarl", "veidimadr", "volva", "skald", "ulfhedinn", "haugbrjotr")
## **The Rites change the arms** (ADR-057, `M4-T46`): the Pact Ranks at which a
## class's forearms carry more of their own marks — stage 1, 2 and 3. Stage 0
## is the arms a life begins with, exported as `{kind}_arms`; stage n as
## `{kind}_arms_r{rank}`. Each stage is the stage before it and more: the marks
## a class already has, spread, never a new costume.
RITE_RANKS = (3, 5, 7)


class Side:
    """One arm's frame, read from the rig: the forearm from `start` to `end`,
    `front` and `across` round it, and the fist's frame — `u` down the hand
    bone, `w` the grip axis, `n` the back of the hand — about `grip`."""

    def __init__(self, rig, side):
        fore = rig.data.bones[f"forearm_{side}"]
        self.start, self.end = np.array(fore.head_local), np.array(fore.tail_local)
        self.axis = (self.end - self.start) / np.linalg.norm(self.end - self.start)
        self.front = np.array((0.0, -1.0, 0.0))
        self.across = np.cross(self.axis, self.front)
        self.across /= np.linalg.norm(self.across)
        self.front = np.cross(self.across, self.axis)
        hand = rig.data.bones[f"hand_{side}"]
        self.origin = np.array(hand.head_local)
        self.u = np.array(hand.tail_local) - self.origin
        self.u /= np.linalg.norm(self.u)
        self.w = np.array((0.0, 1.0, 0.0))
        self.n = np.cross(self.w, self.u)
        self.n *= (1.0 if side == "r" else -1.0) / np.linalg.norm(self.n)
        sock = np.array(rig.data.bones[f"sock_hand_{side}"].head_local)
        self.grip = self.origin + self.u * float((sock - self.origin) @ self.u)
        self.wrap = 0.016 + 0.0105
        self.side = side

    def at(self, t):
        return self.start + (self.end - self.start) * t

    def around(self, theta, along):
        return self.grip + self.w * along + self.wrap * (math.cos(theta) * self.u + math.sin(theta) * self.n)

    def local(self, p):
        """Points in the forearm's frame: across, front, along (metres)."""
        q = p - self.start
        return np.stack([q @ self.across, q @ self.front, q @ self.axis], axis=1)


STATIONS = [-0.07, 0.05, 0.23, 0.46, 0.70, 0.88, 1.01]
ACROSS = [0.046, 0.046, 0.046, 0.042, 0.035, 0.029, 0.029]
FRONT = [0.040, 0.042, 0.040, 0.036, 0.031, 0.025, 0.024]


def girth(t):
    """The forearm's section at `t`: half its width across, and its depth to
    the front — where a mark at that station sits on the skin."""
    return float(np.interp(t, STATIONS, ACROSS)), float(np.interp(t, STATIONS, FRONT))


def forearm(p, s: Side):
    """The forearm narrowing through the wrist: an elliptical section at each
    station, flattening toward the wrist as the radius and ulna do, with the
    swell of the muscles below the elbow on the thumb side."""
    q = s.local(p)
    length = float(np.linalg.norm(s.end - s.start))
    t = q[:, 2] / length
    rx = np.interp(t, STATIONS, ACROSS)
    ry = np.interp(t, STATIONS, FRONT)
    k = np.sqrt((q[:, 0] / rx) ** 2 + (q[:, 1] / ry) ** 2)
    d = (k - 1.0) * np.minimum(rx, ry)
    d = S.smax(d, np.maximum(-0.07 * length - q[:, 2], q[:, 2] - 1.01 * length), 0.01)
    swell = s.at(0.22) + s.front * 0.010 + s.across * 0.012 * (1 if s.side == "l" else -1)
    d = S.smin(d, S.ellipsoid(p - swell, np.array((0.036, 0.034, 0.036))), 0.02)
    return d


def fist(p, s: Side, finger_material=None):
    """The palm, four fingers closed round the handle, and the thumb locked
    over the first two (ADR-280's construction, sculpted). Returns the palm
    and thumb, and the four fingers apart, so a class can colour them."""
    knuckle = s.around(math.radians(96), 0.0) + s.n * 0.004
    wrist = s.origin - s.u * 0.03
    palm = np.full(len(p), 1e3)
    for t, hw, ht in ((0.0, 0.030, 0.023), (0.22, 0.038, 0.022), (0.5, 0.043, 0.020),
                      (0.8, 0.045, 0.019), (1.0, 0.044, 0.017)):
        c = wrist + (knuckle - wrist) * t
        frame = np.stack([knuckle - wrist, s.w, s.n])
        frame[0] /= np.linalg.norm(frame[0])
        q = (p - c) @ frame.T
        palm = S.smin(palm, S.ellipsoid(q, np.array((0.026, hw, ht))), 0.012)
    fingers = np.full(len(p), 1e3)
    ends = (-122, -116, -110, -100)
    for j, along in enumerate((-0.031, -0.0105, 0.0105, 0.030)):
        pts = [s.around(math.radians(96 + (ends[j] - 96) * k / 6), along) for k in range(7)]
        radii = [0.0115, 0.0112, 0.0108, 0.0104, 0.0098, 0.009, 0.0078]
        if j == 3:
            radii = [r * 0.9 for r in radii]
        finger = S.chain(p, pts, radii, 0.003)
        # Knuckles: the joint stands proud of the finger as it bends.
        for k in (1, 4):
            finger = S.smin(finger, S.sphere(p - pts[k], radii[k] * 1.12), 0.004)
        fingers = np.minimum(fingers, finger)
    g = s.grip
    thumb = S.chain(p, [s.origin + s.u * 0.004 - s.w * 0.030 - s.n * 0.010,
                        g - s.u * 0.020 - s.w * 0.040 - s.n * 0.022,
                        g - s.u * 0.004 - s.w * 0.036 - s.n * (s.wrap + 0.006),
                        g + s.u * 0.010 - s.w * 0.022 - s.n * (s.wrap + 0.008),
                        g + s.u * 0.016 - s.w * 0.006 - s.n * (s.wrap + 0.004)],
                    [0.0145, 0.0135, 0.012, 0.0105, 0.008], 0.004)
    hand = S.smin(S.smin(palm, thumb, 0.008), fingers, 0.004)
    return hand, fingers


def band(p, s: Side, t0, t1, r, rough=0.0):
    """A band round the wrist from `t0` to `t1` along the forearm."""
    q = s.local(p)
    length = float(np.linalg.norm(s.end - s.start))
    radial = np.hypot(q[:, 0], q[:, 1])
    rr = r + rough * np.sin(np.arctan2(q[:, 1], q[:, 0]) * 9.0)
    mid, half = (t0 + t1) * 0.5 * length, (t1 - t0) * 0.5 * length
    return S.smax(radial - rr, np.abs(q[:, 2] - mid) - half, 0.003)


def sleeve(p, s: Side, t0, t1, pad, rough=0.0):
    """A sleeve from `t0` to `t1` that follows the forearm's own section, `pad`
    proud of it all the way — a pelt worn on the arm, not rings round it."""
    q = s.local(p)
    length = float(np.linalg.norm(s.end - s.start))
    t = q[:, 2] / length
    across = np.interp(t, STATIONS, ACROSS) + pad
    front = np.interp(t, STATIONS, FRONT) + pad
    k = np.sqrt((q[:, 0] / across) ** 2 + (q[:, 1] / front) ** 2)
    d = (k - 1.0) * np.minimum(across, front)
    d = d + rough * np.sin(np.arctan2(q[:, 1], q[:, 0]) * 9.0 + t * 23.0)
    mid, half = (t0 + t1) * 0.5 * length, (t1 - t0) * 0.5 * length
    return S.smax(d, np.abs(q[:, 2] - mid) - half, 0.004)


def regions_for(kind, sides, stage=0):
    def regions(p):
        out = {"skin": np.full(len(p), 1e3)}
        extra = {}

        def add(name, d):
            extra[name] = np.minimum(extra.get(name, np.full(len(p), 1e3)), d)

        for s in sides:
            hand, fingers = fist(p, s)
            out["skin"] = np.minimum(out["skin"], S.smin(forearm(p, s), hand, 0.012))
            if kind == "huskarl":
                # Two healed cuts raised across the back of the forearm, and a
                # cut more for each stage of the Rite: a shield-wall's record.
                for t in (0.35, 0.46, 0.58, 0.68, 0.77)[:2 + stage]:
                    # The first two keep the place ADR-319 sculpted them at.
                    c = s.at(t) + s.front * (0.039 if t in (0.35, 0.46) else girth(t)[1] + 0.001)
                    add("scar", S.round_cone(p, c - s.across * 0.021 - s.axis * 0.006,
                                             c + s.across * 0.020 + s.axis * 0.006, 0.0032, 0.0028))
            elif kind == "veidimadr":
                # Tabs over the first joint of the three draw fingers, and a
                # taped wrist: a bowman's.
                for along in (-0.031, -0.0105, 0.0105):
                    add("linen", S.chain(p, [s.around(math.radians(92), along), s.around(math.radians(40), along)],
                                         [0.0128, 0.0124], 0.0))
                add("linen", band(p, s, 0.90, 0.99, 0.0325))
                # The stalker's bindings climb the forearm, stage by stage.
                for t0, t1 in ((0.78, 0.84), (0.62, 0.68), (0.46, 0.52))[:stage]:
                    add("linen", band(p, s, t0, t1, girth(t0)[0] + 0.0025))
            elif kind == "volva":
                add("ink", band(p, s, 0.905, 0.94, 0.0322))
                for j in range(3):
                    c = s.end + s.front * 0.028 + s.across * ((j - 1) * 0.020)
                    add("bone", S.round_cone(p, c, c + s.axis * 0.03, 0.006, 0.003))
            elif kind == "ulfhedinn":
                # The wolf-skin climbs from the wrist toward the elbow as the
                # Rite grows: "more wolf" (ADR-057).
                start = (0.89, 0.72, 0.52, 0.30)[stage]
                add("fur", band(p, s, 0.89, 1.09, 0.036, rough=0.003))
                if stage > 0:
                    # One sleeve of pelt up the arm, following its taper.
                    add("fur", sleeve(p, s, start, 0.92, 0.005, rough=0.0016))
            elif kind == "haugbrjotr":
                add("leather", band(p, s, 0.89, 1.02, 0.0345))
                # **Grave-stained** (ADR-057): barrow-earth worked into the skin
                # from the fingertips up — the fingers, then the hand, then half
                # the forearm. A region a hair outside the skin, as the Skald's
                # inked fingers are, so it wins the surface it recolours.
                if stage >= 1:
                    add("grave", fingers - 0.0004)
                if stage >= 2:
                    add("grave", hand - 0.0004)
                if stage >= 3:
                    q = s.local(p)
                    length = float(np.linalg.norm(s.end - s.start))
                    # A ragged edge: earth worked into the skin, not a sleeve.
                    edge = 0.6 * length - q[:, 2] + 0.012 * S.noise(p, 0.02)
                    add("grave", S.smax(forearm(p, s) - 0.0004, edge, 0.006))
                for j in (-1, 1):
                    c = s.end + s.across * (j * 0.021) + s.front * 0.027
                    add("iron", S.round_cone(p, c - s.axis * 0.03, c + s.axis * 0.035, 0.004, 0.0015))
            elif kind == "skald":
                add("linen", band(p, s, 0.905, 0.945, 0.0322))
                # **Rings given for verse** (Egils saga ch. 55: Æthelstan gives
                # Egill a gold ring off his own arm for his drápa). One more
                # arm-ring for each stage, worn up the forearm.
                for t in (0.78, 0.66, 0.54)[:stage]:
                    add("gold", band(p, s, t, t + 0.035, girth(t)[0] + 0.0028))
                # Ink-stained fingers: a skald writes. A hair *outside* the
                # skin, so the stain wins the surface it lies on (inside, as
                # first built, it never showed).
                add("ink", fingers - 0.0004)
        out.update(extra)
        return out
    return regions


def tattoo(sides, stage=0):
    """The Völva's ink (ADR-319), painted into the skin's colour: two bands of
    interlace round the forearm, the pattern of the Mammen and Jelling
    ribbons drawn as a tattooist's line — and a band more for each stage of
    her Rite, the ink spreading toward the elbow (ADR-057)."""
    def colour(points, which, names):
        out = Dt.colour(points, which, names)
        skin = which == names.index("skin")
        for s in sides:
            q = s.local(points)
            length = float(np.linalg.norm(s.end - s.start))
            t = q[:, 2] / length
            a = np.arctan2(q[:, 1], q[:, 0])
            line = np.zeros(len(points), bool)
            for t0 in (0.36, 0.62, 0.16, 0.80, 0.49)[:2 + stage]:
                wave = t0 + 0.035 * np.sin(a * 4.0)
                line |= (np.abs(t - wave) < 0.006) | (np.abs(t - (t0 + 0.035 * np.sin(a * 4.0 + math.pi))) < 0.006)
                line |= (np.abs(t - t0 + 0.05) < 0.003) | (np.abs(t - t0 - 0.05) < 0.003)
            near = np.hypot(q[:, 0], q[:, 1]) < 0.06
            out[skin & line & near] = Dt.MATERIALS["ink"][0]
        return out
    return colour


def weigh(obj, sides):
    """ADR-280's weights: the forearm to its bone, the hand to its own, mixed
    over the wrist; each point to the side it is on."""
    obj.vertex_groups.clear()
    groups = {}
    for v in obj.data.vertices:
        p = np.array(v.co)
        s = min(sides, key=lambda s: np.linalg.norm(p - (s.start + s.end) * 0.5))
        t = max(0.0, min(1.0, (float((p - s.end) @ s.axis) + 0.035) / 0.065))
        for bone, value in ((f"forearm_{s.side}", 1.0 - t), (f"hand_{s.side}", t)):
            if value <= 0.0:
                continue
            group = groups.get(bone) or obj.vertex_groups.new(name=bone)
            groups[bone] = group
            group.add([v.index], value, "REPLACE")


def stem(kind, stage):
    """The exported name: the arms a life begins with, or a Rite stage's."""
    return f"{kind}_arms" if stage == 0 else f"{kind}_arms_r{RITE_RANKS[stage - 1]}"


def build(kind, stage=0):
    rig = em.begin()
    sides = [Side(rig, "l"), Side(rig, "r")]
    lo = np.min([np.minimum(s.start, s.grip) for s in sides], axis=0) - 0.09
    hi = np.max([np.maximum(s.start, s.grip) for s in sides], axis=0) + 0.09
    plan = dict(PLAN, bounds=(lo, hi))
    paint = None
    if kind == "volva":
        paint = tattoo(sides, stage)
    arms = E.sculpt(stem(kind, stage), regions_for(kind, sides, stage), plan, rig, colour=paint)
    weigh(arms, sides)
    arms.name = f"{kind}_arms"
    em.PARTS.append(arms)
    return rig


def export(kind, rig, stage=0):
    em.validate(PLAN["ceiling"])
    bpy.ops.object.select_all(action="DESELECT")
    for obj in em.PARTS:
        obj.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / f"{stem(kind, stage)}.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUT / f"{stem(kind, stage)}.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_skins=True, export_def_bones=False,
        export_leaf_bone=False, export_animations=False, export_morph=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True, export_extras=True)
    return {"triangles": em.triangle_count(), "mesh_parts": len(em.PARTS), "bones": len(rig.data.bones),
            "source_rig": "humanoid_rig.blend", "sculpted": True,
            "weighted_bones": sorted({g.name for o in em.PARTS for g in o.vertex_groups})}


def review(kind, stage=0):
    """Close enough to read the fingers and the class work."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.render.resolution_x, scene.render.resolution_y = 1100, 700
    scene.render.resolution_percentage = 100
    scene.world.color = (0.30, 0.30, 0.30)
    scene.view_settings.look = "AgX - Medium High Contrast"
    for loc, power in (((-2, -3, 4), 420), ((3, 1, 3), 300)):
        bpy.ops.object.light_add(type="AREA", location=loc)
        o = bpy.context.object
        o.data.energy, o.data.size = power, 3
        o.rotation_euler = (Vector((0, 0, 1.2)) - o.location).to_track_quat("-Z", "Y").to_euler()
    bpy.ops.object.camera_add(location=(0.9, -3, 2))
    camera = bpy.context.object
    scene.camera = camera
    camera.rotation_euler = (Vector((0, 0, 1.17)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type, camera.data.ortho_scale = "ORTHO", 1.30
    scene.render.filepath = str(SRC / f"{stem(kind, stage)}_review.png")
    bpy.ops.render.render(write_still=True)


def main():
    """`-- [kind ...] [--stages 1,2,3]`: the classes (all by default) and the
    stages to build (0 alone by default, the arms a life begins with)."""
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    stages = [0]
    if "--stages" in args:
        at = args.index("--stages")
        stages = [int(v) for v in args[at + 1].split(",")]
        args = args[:at] + args[at + 2:]
    chosen = args or list(CLASSES)
    path = SRC / "class_arms_measurements.json"
    report = json.loads(path.read_text()) if path.exists() else {}
    for kind in chosen:
        for stage in stages:
            rig = build(kind, stage)
            name = kind if stage == 0 else stem(kind, stage)
            report[name] = export(kind, rig, stage)
            review(kind, stage)
            print(name, report[name]["triangles"])
    path.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
