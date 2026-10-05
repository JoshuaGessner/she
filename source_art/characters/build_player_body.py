"""Build the delvers' body: what a teammate is seen as, on the shared rig.

Run with Blender, after `build_humanoid_rig.py`:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \\
      --python source_art/characters/build_player_body.py

**Why this is not the rig's proxy** (ADR-308). `build_humanoid_rig.py` makes a
proxy of spheres, boxes and cylinders and says what it is for: *"rig placement
and measurement only; not character art"*. It stays the rig's measuring stick;
this is the character.

**Sculpted, as the enemies are** (ADR-318). ADR-308 built the delver from the
enemies' lofted anatomy, and when the enemies were sculpted (ADR-316) the
delver was left the one boxy human in the game. It is now the same sculpt —
`sculpt_humanoid`'s anatomy and garments, through `build_enemies.sculpt` — so
a delver and a Wretch are still one people: the Viking-age working dress the
Wretches are a ruin of. A tunic to mid-thigh with a plain hem and sleeves to
the wrist, trousers, leg wraps, turnshoes, a belt, and hair bound back under
a band, with a braid.

**Its colour is the teammate's.** `BodyRig` gives each teammate their colour at
runtime, so what is baked is a **value map** it multiplies (ADR-318): each
material's lightness against linen, held to ADR-308's range — never below
`SKIN_FLOOR` of the teammate's colour, so hair and a belt read as hair and a
belt without a teammate reading as a threat (every enemy state is darker).

**What gear hides.** `BodyRig` hides the base body under armour by each vertex's
dominant bone — pelvis, spine, chest, legs, feet and upper arms. So what always
shows is weighted to what armour never covers: the head, the neck, the
forearms and the hands.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
import numpy as np

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[1]
OUT = ROOT / "game" / "art" / "characters" / "player_body.glb"
sys.path.insert(0, str(SRC.parent / "enemies"))
sys.path.insert(0, str(SRC.parent / "lib"))
sys.path.insert(0, str(SRC))
import build_enemies as E  # noqa: E402
import build_enemy_models as em  # noqa: E402
import humanoid_detail as Dt  # noqa: E402
import sculpt_humanoid as Hm  # noqa: E402

## The rig's collider (`build_humanoid_rig.CAPSULE_RADIUS_M`): nothing the upper
## arm owns may stand outside it.
CAPSULE = 0.35
BUILD = Hm.Build(broad=0.92, limb=0.90, stature=1.0, beard=0.0)
## A character's budget is `ART-004`'s 10,000; the worn pieces go over it.
PLAN = dict(voxel=0.010, body_tris=7000, texture=1024, ceiling=10000)
## ADR-308's range, moved here from `BodyRig` (ADR-318): a material's value is
## its lightness against linen's, never darker than `SKIN_FLOOR` of the
## teammate's colour and never lighter than it.
SKIN_FLOOR = 0.75
LUMINANCE = np.array([0.2126, 0.7152, 0.0722])


def regions(p):
    b = BUILD
    flesh = np.minimum(Hm.head(p, b), Hm.neck(p, b))
    linen = Hm.tunic(p, b, hem=0.62, flare=0.06, torn=0.0, slit=True)
    for side in ("l", "r"):
        flesh = np.minimum(flesh, Hm.hand(p, side, b))
        # Fitted: a loose sleeve puts the elbow outside the rig's capsule.
        linen = np.minimum(linen, Hm.sleeve(p, side, b, to=0.94, grow=0.004))
    return {
        "flesh": flesh,
        "dark": Hm.bound_hair(p, b, braid=0.30, crown=-0.016),
        "linen": linen,
        "cloth": Hm.trousers(p, b, bottom=0.28),
        "rag": Hm.wraps(p, b, legs=True, arms=False),
        "leather": np.minimum(np.minimum(Hm.boots(p, b, top=0.27), Hm.belt(p, b)),
                              np.minimum(Hm.headband(p, b), Hm.collar(p, z=1.545, rx=0.125, ry=0.112))),
    }


def value(points, which, names):
    """Each material's lightness against linen, in the teammate's range, with
    the material's own variation through it."""
    linen = float(np.asarray(Dt.MATERIALS["linen"][0]) @ LUMINANCE)
    shade = np.clip((Dt.colour(points, which, names) @ LUMINANCE) / linen, SKIN_FLOOR, 1.0)
    return np.repeat(shade[:, None], 3, axis=1)


def build():
    rig = em.begin()
    body = E.sculpt("player", regions, PLAN, rig, colour=value)
    body.name = "player_body"
    em.PARTS.append(body)
    return rig


def validate(rig):
    em.validate(PLAN["ceiling"])
    co = np.array([v.co for obj in em.PARTS for v in obj.data.vertices])
    assert abs(co[:, 2].min()) < 0.02, co[:, 2].min()
    assert 1.76 <= co[:, 2].max() <= 1.84, co[:, 2].max()
    reach, far = 0.0, None
    for obj in em.PARTS:
        names = {group.index: group.name for group in obj.vertex_groups}
        for vertex in obj.data.vertices:
            if not vertex.groups:
                continue
            strongest = max(vertex.groups, key=lambda link: link.weight)
            if names[strongest.group].startswith("upper_arm"):
                if abs(vertex.co.x) > reach:
                    reach, far = abs(vertex.co.x), tuple(round(c, 3) for c in vertex.co)
    assert reach <= CAPSULE + 1e-6, (reach, far)
    return {"triangles": em.triangle_count(), "height_m": round(float(co[:, 2].max()), 3),
            "upper_arm_reach_m": round(reach, 3), "bones": len(rig.data.bones), "sculpted": True}


def export(rig):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in em.PARTS:
        obj.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / "player_body.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_skins=True, export_def_bones=False,
        export_leaf_bone=False, export_animations=False, export_morph=False,
        export_cameras=False, export_lights=False, export_vertex_color="ACTIVE",
        export_attributes=True, export_extras=True)


def main():
    rig = build()
    report = validate(rig)
    export(rig)
    em.review("player_body", SRC)
    (SRC / "player_body_measurements.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
