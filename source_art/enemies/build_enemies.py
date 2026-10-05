"""Build the Delvings enemies, sculpted, on the shared rig (ADR-316).

Run with Blender:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \\
      --python source_art/enemies/build_enemies.py -- [kind ...]
then `animate_enemies.py` with the same kinds.

Each body is **one signed distance field** (`sculpt_humanoid`): anatomy, and
garments as shells over it, each garment a material region. The field is
meshed, decimated to the enemy budget, weighted to the shared rig by bone heat
and unwrapped; then the sculpt's own normals, every material's carving
(`humanoid_detail`) and the base colour of each region are baked into a normal
map and a colour map. What stays hard-surface — weapons, a bell, a helm's
nasal — is `build_enemy_models`' pieces, weighted rigidly to their bone.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
import numpy as np

SRC = Path(__file__).resolve().parent
sys.path.insert(0, str(SRC.parent / "lib"))
sys.path.insert(0, str(SRC.parent / "characters"))
sys.path.insert(0, str(SRC))
import sdf_sculpt as S  # noqa: E402
import blender_bake as K  # noqa: E402
import sculpt_humanoid as Hm  # noqa: E402
import humanoid_detail as Dt  # noqa: E402
import build_enemy_models as em  # noqa: E402

## The body's box in the rig's frame, and the voxel it is meshed at.
BOUNDS = ((-0.62, -0.34, -0.02), (0.62, 0.46, 2.10))
VOXEL = 0.012
## What the body may spend of the 6,000-triangle enemy ceiling; the hard
## pieces have the rest.
BODY_TRIS = 4300
TEXTURE = 1024


# ── The kinds ────────────────────────────────────────────────────────────

def wretch():
    """**Pitiable before it is dangerous** (ADR-305). A Dvergar survivor gone
    to rags: a hood whose tail hangs to the shoulder blades and whose cape is
    torn at the hem, a tunic that ends in tongues, bare gaunt arms with the
    forearms bound in rag, and wrapped calves. The seax is the one whole
    thing it owns. Thin, so a crowd of them reads as many small threats."""
    b = Hm.Build(broad=0.86, limb=0.86, stature=0.98)

    def regions(p):
        flesh = np.minimum(Hm.head(p, b), Hm.neck(p, b))
        for side in ("l", "r"):
            flesh = np.minimum(flesh, np.minimum(Hm.arm(p, side, b), Hm.hand(p, side, b)))
        return {
            "flesh": flesh,
            "dark": Hm.beard(p, b, 0.9, split=True),
            "rag": np.minimum(np.minimum(Hm.tunic(p, b, hem=0.66, flare=0.07, torn=0.08),
                                         Hm.hood(p, b, cape=0.11, tail=0.40, torn=0.06)),
                              Hm.wraps(p, b, legs=True, arms=True)),
            "cloth": Hm.trousers(p, b, bottom=0.26),
            "leather": np.minimum(Hm.boots(p, b, top=0.27), Hm.belt(p, b)),
        }

    def hard():
        em.weapon_seax()

    return regions, hard


def sling_wretch():
    """**The one that keeps its distance** (ADR-305). Bareheaded where the
    Wretch is hooded: hair bound back under a band and a braid down the
    spine, a hide over the left shoulder only, a strap across the chest to a
    stone bag, and the sling hanging long from the right hand. Lopsided on
    purpose — a thrower's body."""
    b = Hm.Build(broad=0.82, limb=0.84, stature=0.96)

    def regions(p):
        flesh = np.minimum(Hm.head(p, b), Hm.neck(p, b))
        for side in ("l", "r"):
            flesh = np.minimum(flesh, np.minimum(Hm.arm(p, side, b), Hm.hand(p, side, b)))
        hide = np.minimum(Hm.mantle(p, b, "l", drop=0.18, torn=0.05),
                          Hm.strap(p, [(0.13, -0.145, 1.47), (0.03, -0.162, 1.33), (-0.08, -0.163, 1.18),
                                       (-0.17, -0.14, 1.05)]))
        return {
            "flesh": flesh,
            "dark": np.minimum(Hm.beard(p, b, 0.6), Hm.bound_hair(p, b)),
            "leather": np.minimum(np.minimum(hide, Hm.boots(p, b, top=0.26)),
                                  np.minimum(Hm.belt(p, b), Hm.headband(p, b))),
            "rag": np.minimum(Hm.tunic(p, b, hem=0.74, flare=0.05, torn=0.06),
                              Hm.wraps(p, b, legs=True, arms=False)),
            "cloth": Hm.trousers(p, b, bottom=0.25),
        }

    def hard():
        em.sling_and_pouch()

    return regions, hard


def bellringer():
    """**The one that has learned what the chains are for** (ADR-305). A Wretch
    that stood up: hooded like its kin, but in a robe to the shins, an iron
    collar and a chain across the body, and two small bells at the belt
    besides the one in its hand. The robe is the silhouette: long and narrow
    among short ragged ones."""
    b = Hm.Build(broad=0.90, limb=0.9, stature=1.0)

    def regions(p):
        flesh = np.minimum(Hm.head(p, b), Hm.neck(p, b))
        for side in ("l", "r"):
            flesh = np.minimum(flesh, np.minimum(Hm.arm(p, side, b), Hm.hand(p, side, b)))
        robe = np.minimum(Hm.tunic(p, b, hem=0.30, flare=0.12, torn=0.05, slit=False),
                          Hm.hood(p, b, cape=0.06, tail=0.18, torn=0.03))
        for side in ("l", "r"):
            robe = np.minimum(robe, Hm.sleeve(p, side, b, to=0.92))
        return {
            "flesh": flesh,
            "dark": Hm.beard(p, b, 1.1),
            "rag": robe,
            "iron": Hm.collar(p),
            "leather": np.minimum(Hm.belt(p, b), Hm.boots(p, b, top=0.22)),
        }

    def hard():
        em.bell_and_striker()
        em.alarm_chain()
        em.belt_bells()

    return regions, hard


def hall_warden():
    """**The door that does not open** (ADR-305). A Dvergar housecarl kept at
    his post: a conical spangenhelm with a nasal and the Gjermundbu helm's
    guard, a mail curtain open at the face, lamellar shoulders, a hauberk to
    the knee, and the hammer. *The Gjermundbu helm and the Birka mail.* Broad
    and heavy — the blocker it plays."""
    b = Hm.Build(broad=1.22, limb=1.12, stature=1.03, belly=0.4)

    def regions(p):
        flesh = np.minimum(Hm.head(p, b), Hm.neck(p, b))
        for side in ("l", "r"):
            flesh = np.minimum(flesh, np.minimum(Hm.arm(p, side, b), Hm.hand(p, side, b)))
        mail = np.minimum(Hm.mail_coat(p, b, hem=0.56, sleeves=0.62), Hm.aventail(p, b))
        return {
            "flesh": flesh,
            "dark": Hm.beard(p, b, 1.0, split=True),
            "mail": mail,
            "cloth": Hm.trousers(p, b, bottom=0.28),
            "leather": np.minimum(Hm.belt(p, b, grow=0.05), Hm.boots(p, b, top=0.30)),
        }

    def hard():
        # Worked iron is cut, not grown: the helm's plates, ribs, nasal and
        # spectacle guard and the lamellar shoulders keep their hard edges.
        em.spangenhelm()
        em.lamellar_shoulders()
        em.war_hammer()

    return regions, hard


def hoard_keeper():
    """**It does not leave the gold** (ADR-305). The last of the hoard's guard:
    a rounded helm with a crest from brow to nape and brow arches (the Vendel
    and Valsgärde helms), a byrnie to the knee, a cloak to the calf swept
    behind the arms, arm rings taken from the hoard, and the spear. Tall and
    closed, where the Warden is square."""
    b = Hm.Build(broad=0.98, limb=1.0, stature=1.04)

    def regions(p):
        flesh = np.minimum(Hm.head(p, b), Hm.neck(p, b))
        for side in ("l", "r"):
            flesh = np.minimum(flesh, np.minimum(Hm.arm(p, side, b), Hm.hand(p, side, b)))
        return {
            "flesh": flesh,
            "dark": Hm.beard(p, b, 1.4),
            "mail": np.minimum(Hm.mail_coat(p, b, hem=0.54, sleeves=0.85), Hm.aventail(p, b)),
            "iron": np.minimum(Hm.crested_helm(p, b),
                               np.minimum(Hm.arm_rings(p, "l", b), Hm.arm_rings(p, "r", b))),
            "cloth": np.minimum(Hm.cloak(p, b, hem=0.46), Hm.trousers(p, b, bottom=0.30)),
            "leather": np.minimum(Hm.belt(p, b, grow=0.05), Hm.boots(p, b, top=0.32)),
        }

    def hard():
        em.spear()

    return regions, hard


def gullsjukr():
    """**The Gold-Sick** (`DES-017`): a Bound gone hollow under what it carries.
    A gaunt ashen body bound in cloth, an old Dvergar breastplate split on its
    chest, coin sacks at both hips — and the hoard *fused to it*: a mass of
    struck coins run together over its right shoulder and down its back,
    rising past its head, three medallions in it. One-sided on purpose, so it
    moves as something carried rather than worn."""
    import random
    b = Hm.Build(broad=0.95, limb=0.80, stature=1.0, beard=0.0)
    rng = random.Random(1717)
    coins = []
    for z, count, spread in ((1.38, 30, 0.30), (1.46, 36, 0.34), (1.54, 40, 0.36), (1.62, 40, 0.35),
                             (1.70, 36, 0.33), (1.78, 30, 0.28), (1.86, 22, 0.22), (1.94, 12, 0.15)):
        for i in range(count):
            arc = i / max(1, count - 1) - 0.5
            x = -0.27 + arc * spread * 0.8 + rng.uniform(-0.025, 0.025)
            y = 0.04 + rng.uniform(-0.12, 0.13)
            # Coins at a size a hand could close on: the hoard reads as a
            # hoard because there are many of them, not because each is big.
            r = 0.030 + rng.random() * 0.016
            coins.append((np.array([x, y, z + rng.uniform(-0.03, 0.03)]), r, 0.006 + r * 0.10,
                          (rng.uniform(-40, 40), 20 + (i % 5) * 16, rng.uniform(-50, 50))))
    for x, y, z, r in ((-0.41, -0.09, 1.66, 0.10), (-0.24, -0.17, 1.47, 0.098), (-0.39, 0.11, 1.84, 0.085)):
        coins.append((np.array([x, y, z]), r, 0.026, (55.0, 0.0, 10.0)))

    def regions(p):
        flesh = np.minimum(Hm.head(p, b), Hm.neck(p, b))
        for side in ("l", "r"):
            flesh = np.minimum(flesh, np.minimum(Hm.arm(p, side, b), Hm.hand(p, side, b)))
        bound = np.minimum(Hm.tunic(p, b, hem=0.84, flare=0.03, torn=0.04),
                           np.minimum(Hm.trousers(p, b, bottom=0.24), Hm.wraps(p, b, legs=True, arms=True)))
        return {
            "ashen": flesh,
            "cloth": bound,
            "plate": Hm.breastplate(p, b),
            "gold": Hm.coin_mass(p, coins),
            "leather": np.minimum(np.minimum(Hm.sack(p, (-0.21, 0.08, 0.80), (0.13, 0.11, 0.17)),
                                             Hm.sack(p, (0.21, 0.08, 0.80), (0.13, 0.11, 0.17))),
                                  np.minimum(Hm.boots(p, b, top=0.24), Hm.belt(p, b))),
        }

    def hard():
        em.drag_chain()

    return regions, hard


KINDS = {"wretch": wretch, "sling_wretch": sling_wretch, "bellringer": bellringer,
         "hall_warden": hall_warden, "hoard_keeper": hoard_keeper, "gullsjukr": gullsjukr}
## The Gold-Sick is a hero asset (`ART-004`'s 40,000-triangle row) and lives
## with the heroes: a finer mesh, a denser map, its own folder.
HERO = {"gullsjukr": dict(voxel=0.009, body_tris=16000, texture=2048, ceiling=40000)}
## Materials carried rigidly, by kind: material → {bone: weight}.
RIGID = {"gullsjukr": {"gold": {"chest": 0.78, "clavicle_r": 0.22}, "plate": {"chest": 1.0}}}


# ── Pipeline ─────────────────────────────────────────────────────────────

def material(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.85
    m.use_backface_culling = True
    return m


def weigh(obj, rig):
    """Bone heat, as a rigger's first pass would be: Blender diffuses each
    deform bone's influence through the closed mesh. Then normalised and held
    to four influences, as the engine skins."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    K.select_only(obj)
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
    # Bone heat leaves a vertex it could not reach with no weight at all;
    # give it its nearest bone's.
    names = {g.index: g.name for g in obj.vertex_groups}
    bones = [b for b in rig.data.bones if b.use_deform]
    for v in obj.data.vertices:
        if sum(g.weight for g in v.groups) > 0.999:
            continue
        best = min(bones, key=lambda bn: _segment_distance(np.array(v.co), np.array(bn.head_local),
                                                           np.array(bn.tail_local)))
        group = obj.vertex_groups.get(best.name) or obj.vertex_groups.new(name=best.name)
        for gi in [g.group for g in v.groups]:
            obj.vertex_groups[names[gi]].remove([v.index])
        group.add([v.index], 1.0, "REPLACE")
    # The engine wants the modifier named as the other parts' are.
    for mod in obj.modifiers:
        if mod.type == "ARMATURE":
            mod.name = "shared_skeleton"


def _segment_distance(p, a, b):
    ab = b - a
    t = np.clip((p - a) @ ab / max(ab @ ab, 1e-12), 0.0, 1.0)
    return float(np.linalg.norm(p - (a + ab * t)))


def spec(kind):
    """Voxel, body budget, map size, and triangle ceiling for a kind."""
    return HERO.get(kind, dict(voxel=VOXEL, body_tris=BODY_TRIS, texture=TEXTURE, ceiling=6000))


def sculpt(name, regions, plan, rig, rigid=None, colour=None):
    """One sculpted body on the shared rig: `regions(points)` names each
    material's field, the body is their union, and each point is the material
    whose field is nearest. Meshed at `plan`'s voxel, decimated to its budget,
    baked to a normal map and a colour map — `colour(points, which, names)`,
    or each material's own — inked by family and weighted by bone heat.
    Shared with the delvers' body (ADR-318)."""
    colour = colour or Dt.colour

    def field(p):
        return np.min(np.stack(list(regions(p).values())), axis=0)

    def which(points):
        r = regions(points)
        names = list(r.keys())
        return np.argmin(np.stack([r[n] for n in names]), axis=0), names

    body = K.mesh_field(f"{name}_body", field, BOUNDS[0], BOUNDS[1], plan["voxel"], material(f"{name}_skin"))
    K.outward(body)
    K.decimate(body, plan["body_tris"])
    K.unwrap(body, 0.006)

    def height_at(points, _nearest, _face):
        w, names = which(points)
        return Dt.height(points, w, names)

    def colour_at(points, _nearest, _face):
        w, names = which(points)
        return colour(points, w, names)

    normal, colour_map = K.bake(body, plan["texture"], height_at, f"{name}_n", colour_at, field)
    mat = body.data.materials[0]
    K.with_colour_map(mat, colour_map)
    K.with_normal_map(mat, normal)
    # Ink family per corner, from the material nearest each vertex.
    co = np.array([v.co for v in body.data.vertices])
    w, names = which(co)
    family = np.array([Dt.MATERIALS[n][1] for n in names])[w]
    layer = body.data.color_attributes.new(name="ink", type="FLOAT_COLOR", domain="CORNER")
    body.data.color_attributes.active_color = layer
    for loop in body.data.loops:
        layer.data[loop.index].color = (1.0, 0.5, float(family[loop.vertex_index]), 1.0)
    weigh(body, rig)
    # A material that is carried rather than worn rides its bones rigidly:
    # bone heat would let a swinging arm drag a share of the hoard with it.
    if rigid:
        for v in body.data.vertices:
            weights = rigid.get(names[w[v.index]])
            if weights is None:
                continue
            for gi in [g.group for g in v.groups]:
                body.vertex_groups[gi].remove([v.index])
            for bone, value in weights.items():
                group = body.vertex_groups.get(bone) or body.vertex_groups.new(name=bone)
                group.add([v.index], value, "REPLACE")
    return body


def build(kind):
    rig = em.begin()
    regions, hard = KINDS[kind]()
    em.PARTS.append(sculpt(kind, regions, spec(kind), rig, RIGID.get(kind)))
    hard()
    return rig


def export(kind):
    """Save the source and export the bind-pose model: the enemies with the
    enemies, the Gold-Sick with the heroes."""
    hero = kind in HERO
    source = SRC.parent / "heroes" if hero else SRC
    out = em.ROOT / "game" / "art" / ("heroes" if hero else "enemies")
    em.validate(spec(kind)["ceiling"])
    bpy.ops.object.select_all(action="DESELECT")
    em.RIG.select_set(True)
    for obj in em.PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = em.RIG
    bpy.ops.wm.save_as_mainfile(filepath=str(source / f"{kind}.blend"))
    bpy.ops.export_scene.gltf(filepath=str(out / f"{kind}.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_skins=True, export_def_bones=False,
        export_leaf_bone=False, export_animations=False, export_morph=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True, export_extras=True)
    em.review(kind, source)
    return source, {"triangles": em.triangle_count(), "mesh_parts": len(em.PARTS),
                    "bones": len(em.RIG.data.bones), "source_rig": "humanoid_rig.blend", "sculpted": True}


def main():
    chosen = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(KINDS)
    for kind in chosen:
        build(kind)
        source, row = export(kind)
        path = source / ("gullsjukr_measurements.json" if kind in HERO else "enemy_model_measurements.json")
        report = json.loads(path.read_text()) if path.exists() else {}
        if kind in HERO:
            report.update(row)
        else:
            report[kind] = row
        path.write_text(json.dumps(report, indent=2) + "\n")
        print(kind, json.dumps(row))


if __name__ == "__main__":
    main()
