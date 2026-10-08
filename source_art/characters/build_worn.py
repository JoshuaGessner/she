"""The worn pieces of `DES-020`: mail, bracers and Ótr's pelt, sculpted (ADR-318).

Run with Blender, after `build_player_body.py`:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \\
      --python source_art/characters/build_worn.py

Each is sculpted over the delvers' body (`build_player_body.BUILD`) as the
enemies are, through `build_enemies.sculpt`, and skinned to the shared rig.
The loose pickup models stay separate: their base-centred pivots cannot also
be the bind-space origin of a garment.

**A body piece dresses the legs too.** `BodyRig` hides the base body under
body armour by dominant bone — pelvis, spine, chest, legs, feet and upper arms
— so the mail and the pelt each carry the trousers, wraps and shoes the body
had there. Only the bracers go over it.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
import numpy as np

SRC = Path(__file__).resolve().parent
OUT = SRC.parents[1] / "game" / "art" / "characters"
sys.path.insert(0, str(SRC.parent / "enemies"))
sys.path.insert(0, str(SRC.parent / "lib"))
sys.path.insert(0, str(SRC))
import build_enemies as E  # noqa: E402
import build_enemy_models as em  # noqa: E402
import build_player_body as P  # noqa: E402
import humanoid_detail as Dt  # noqa: E402
import sculpt_humanoid as Hm  # noqa: E402
import sdf_sculpt as S  # noqa: E402

B = P.BUILD
V = Hm.V


def _fur(p):
    # Fur lies down the pelt: soft streaks running with it, and clumps.
    return 0.0014 * S.fbm(p * np.array([1.0, 1.0, 0.3]), 0.02, 2) + 0.0008 * S.noise(p, 0.012)


## Ótr's colours (ADR-318): an otter's dark brown over a paler throat.
Dt.MATERIALS.update({
    "fur": ((0.15, 0.105, 0.062), 0.80, _fur),
    "fur_light": ((0.30, 0.225, 0.13), 0.80, _fur),
    # The wolf's (ADR-354): a grey back over a pale muzzle and throat.
    "fur_grey": ((0.21, 0.20, 0.185), 0.82, _fur),
    "fur_pale": ((0.42, 0.40, 0.355), 0.82, _fur),
    # The hunter's (ADR-364): undyed wool gone green-brown with the weather.
    "wool": ((0.17, 0.165, 0.115), 0.92, lambda p: 0.0007 * S.noise(p, 0.006)),
    # The seeress's (ADR-379): Þorbjörg's blue mantle and black lambskin hood.
    "wool_blue": ((0.105, 0.125, 0.185), 0.92, lambda p: 0.0007 * S.noise(p, 0.006)),
    "fur_dark": ((0.055, 0.050, 0.048), 0.85, _fur),
    # The skald's (ADR-387): a madder-dyed cloak, the dye gone dark as wool's
    # does — muted, because `ART-005` spends saturation on gold alone.
    "wool_red": ((0.185, 0.095, 0.075), 0.92, lambda p: 0.0007 * S.noise(p, 0.006)),
})


def underlayer(p):
    """What the body wore where a body piece hides it."""
    return {
        "cloth": Hm.trousers(p, B, bottom=0.28),
        "rag": Hm.wraps(p, B, legs=True, arms=False),
        "leather": np.minimum(Hm.boots(p, B, top=0.27), Hm.belt(p, B, grow=0.040)),
    }


def byrnie(p):
    """**A byrnie** (`DES-020`): mail to mid-thigh, split front and back for the
    stride, sleeves past the elbow; the Gjermundbu mail's cut."""
    r = underlayer(p)
    r["mail"] = Hm.mail_coat(p, B, hem=0.60, sleeves=0.56)
    return r


def bracers(p):
    """**Iron bracers** (`DES-020`), each strapped over the sleeve."""
    return {"iron": np.minimum(Hm.bracer(p, "l", B), Hm.bracer(p, "r", B))}


def pelt(p):
    """**Ótr's pelt** (`DES-020`, *Völsunga saga* and *Reginsmál*): the
    otter-skin the gods filled and covered with gold, worn as a mantle. The
    hide lies over the shoulders and down the back; the head rests on the
    right shoulder looking forward, the forepaws hang on the chest, and the
    tail runs down the back to the knees. Over the tunic the body had."""
    r = underlayer(p)
    r["linen"] = np.minimum(Hm.tunic(p, B, hem=0.62, flare=0.06, slit=True, grow=0.020),
                            np.minimum(Hm.sleeve(p, "l", B, to=0.40, grow=0.010),
                                       Hm.sleeve(p, "r", B, to=0.40, grow=0.010)))
    # The hide: thick, as a fur is, deep down the back and short in front. A
    # solid rather than a shell — a 2 cm shell at this voxel shattered.
    hide = Hm.trunk(p, B, 0.045)
    front = 1.30 - 0.36 * np.clip((p[:, 1] + 0.02) / 0.16, 0.0, 1.0)
    hide = S.smax(hide, front - p[:, 2], 0.02)
    m = Hm.mirror(p)
    hide = S.smax(hide, m[:, 0] - 0.27 * B.broad, 0.03)
    # The head, raised clear on the right shoulder (the rig's right is −X) and
    # looking forward past the face: a flat broad skull, small round ears, a
    # blunt muzzle — the otter's, read at a glance from across a room.
    c = V((-0.20, -0.05, 1.615))
    head = S.ellipsoid(p - c, V((0.066, 0.095, 0.052)))
    muzzle = c + V((0.0, -0.095, -0.012))
    head = S.smin(head, S.ellipsoid(p - muzzle, V((0.040, 0.050, 0.034))), 0.025)
    for sx in (-1.0, 1.0):
        head = S.smin(head, S.sphere(p - (c + V((0.050 * sx, 0.040, 0.040))), 0.016), 0.008)
        head = S.carve(head, S.sphere(p - (c + V((0.045 * sx, -0.045, 0.030))), 0.010), 0.004)
    nose_at = muzzle + V((0.0, -0.048, 0.010))
    nose = S.ellipsoid(p - nose_at, V((0.020, 0.014, 0.013)))
    neck = S.round_cone(p, c + V((0.0, 0.07, -0.02)), V((-0.13, 0.08, 1.50)), 0.050, 0.060)
    # Forepaws over the chest, hind legs at the back, the tail to the knees.
    limbs = np.full(len(p), 1e3)
    for sx in (-1.0, 1.0):
        top, low = V((0.09 * sx, -0.140, 1.32)), V((0.085 * sx, -0.150, 1.16))
        limbs = np.minimum(limbs, S.round_cone(p, top, low, 0.026, 0.020))
        limbs = S.smin(limbs, S.ellipsoid(p - (low + V((0.0, -0.008, -0.025))), V((0.028, 0.018, 0.032))), 0.01)
        hip, foot = V((0.12 * sx, 0.165, 1.00)), V((0.12 * sx, 0.170, 0.86))
        limbs = np.minimum(limbs, S.round_cone(p, hip, foot, 0.030, 0.020))
    tail = S.chain(p, [V((0.0, 0.170, 0.98)), V((0.0, 0.185, 0.80)), V((0.01, 0.180, 0.62)),
                       V((0.02, 0.165, 0.50))], [0.050, 0.038, 0.024, 0.010], 0.01)
    r["fur"] = S.smin(S.smin(hide, np.minimum(head, neck), 0.03), np.minimum(limbs, tail), 0.02)
    # A pale throat and chin, as an otter has: the head's underside.
    r["fur_light"] = S.ellipsoid(p - (c + V((0.0, -0.06, -0.045))), V((0.045, 0.075, 0.022)))
    r["dark"] = nose
    return r


def wolf_coat(p):
    """**The wolf-coat** (ADR-354): what the úlfheðnar are named for —
    *Haraldskvæði*'s *wolf-skins*, and the wolf-headed warrior of the Torslunda
    helmet plates. The skin is worn as a hood: the wolf's skull rides the
    crown with its muzzle out over the brow and its ears up, so the head reads
    as a wolf's from across a room; the hide falls over the shoulders and down
    the back to the calves, the forelegs are knotted across the chest, and the
    tail hangs behind. The face is open. Over the tunic the body had."""
    r = underlayer(p)
    r["linen"] = np.minimum(Hm.tunic(p, B, hem=0.62, flare=0.06, slit=True, grow=0.020),
                            np.minimum(Hm.sleeve(p, "l", B, to=0.40, grow=0.010),
                                       Hm.sleeve(p, "r", B, to=0.40, grow=0.010)))
    # The hood with the face open, and its cape the hide's top.
    hood = Hm.hood(p, B, grow=0.024, cape=0.10)
    # The hide down the back: thick as a fur is, deep behind and short in front.
    hide = Hm.trunk(p, B, 0.040)
    front = 1.32 - 0.40 * np.clip((p[:, 1] + 0.02) / 0.16, 0.0, 1.0)
    hide = S.smax(hide, front - p[:, 2], 0.02)
    # Down the back to the calves, a flap narrowing as it falls.
    flap = S.round_cone(p, V((0.0, 0.16, 1.30)), V((0.0, 0.19, 0.55)), 0.17, 0.09)
    flap = S.smax(flap, 0.10 - p[:, 1], 0.02)
    hide = S.smin(hide, flap, 0.04)
    # The wolf's head on the crown, looking where the wearer looks.
    c = V((0.0, -0.005, 1.835))
    skull = S.ellipsoid(p - c, V((0.088, 0.112, 0.058)))
    muzzle = S.round_cone(p, c + V((0.0, -0.085, -0.005)), c + V((0.0, -0.215, -0.035)), 0.050, 0.030)
    head = S.smin(skull, muzzle, 0.03)
    for sx in (-1.0, 1.0):
        ear = S.round_cone(p, c + V((0.055 * sx, 0.030, 0.035)), c + V((0.068 * sx, 0.045, 0.110)), 0.026, 0.006)
        head = S.smin(head, ear, 0.012)
        head = S.carve(head, S.sphere(p - (c + V((0.040 * sx, -0.080, 0.022))), 0.013), 0.005)
    # Hollow under the skull, so the wearer's head is inside it.
    head = S.carve(head, S.ellipsoid(p - V((0.0, 0.012, 1.71)), V((0.11, 0.125, 0.13))), 0.008)
    nose_at = c + V((0.0, -0.232, -0.030))
    nose = S.ellipsoid(p - nose_at, V((0.022, 0.016, 0.014)))
    # Forelegs over the shoulders, knotted on the chest.
    legs = np.full(len(p), 1e3)
    for sx in (-1.0, 1.0):
        legs = np.minimum(legs, S.round_cone(p, V((0.14 * sx, -0.10, 1.44)), V((0.03 * sx, -0.155, 1.26)),
                                             0.030, 0.022))
    legs = S.smin(legs, S.ellipsoid(p - V((0.0, -0.162, 1.25)), V((0.045, 0.026, 0.030))), 0.012)
    tail = S.chain(p, [V((0.0, 0.18, 0.62)), V((0.01, 0.195, 0.48)), V((0.02, 0.19, 0.36))],
                   [0.045, 0.035, 0.012], 0.01)
    # Over the delver's braid, which pushed through the hood's back in the
    # first review: the hide thickens down the nape.
    hide = S.smin(hide, S.chain(p, [V((0.0, 0.13, 1.74)), V((0.0, 0.18, 1.62)), V((0.0, 0.20, 1.46))],
                                [0.060, 0.055, 0.050], 0.02), 0.03)
    r["fur_grey"] = S.smin(S.smin(S.smin(hood, hide, 0.03), head, 0.03),
                           np.minimum(legs, tail), 0.02)
    # The pale underside of the muzzle and the throat.
    r["fur_pale"] = S.round_cone(p, c + V((0.0, -0.10, -0.040)), c + V((0.0, -0.20, -0.055)), 0.034, 0.020)
    r["dark"] = nose
    return r


def hunter_hood(p):
    """**The Veiðimaðr's hood** (ADR-364): a hood and a short shoulder-cape,
    the Skjoldehamn find's cut — the one thing the Norse wore that is a
    silhouette from across a room by itself — over a tunic and wraps. A hood
    up is a stalker; a cape to the shoulder blades keeps the bow arm free."""
    r = underlayer(p)
    r["linen"] = np.minimum(Hm.tunic(p, B, hem=0.62, flare=0.06, slit=True, grow=0.020),
                            np.minimum(Hm.sleeve(p, "l", B, to=0.40, grow=0.010),
                                       Hm.sleeve(p, "r", B, to=0.40, grow=0.010)))
    r["wool"] = Hm.hood(p, B, grow=0.022, cape=0.20, tail=0.18)
    return r


def volva_mantle(p):
    """**The Völva's mantle** (ADR-379), as Eiríks saga ch. 4 dresses
    Þorbjörg: *a blue mantle with straps … a string of glass beads about her
    neck, and on her head a hood of black lambskin lined with white catskin.*
    A gown to the ankle under it, because a seeress does not stride, and the
    mantle open down the front, falling to the calf behind. Over the wraps
    the body had."""
    r = underlayer(p)
    r["linen"] = np.minimum(Hm.tunic(p, B, hem=0.16, flare=0.12, slit=False, grow=0.018),
                            np.minimum(Hm.sleeve(p, "l", B, to=0.42, grow=0.010),
                                       Hm.sleeve(p, "r", B, to=0.42, grow=0.010)))
    # A shell around the gown, from the shoulders to the calf, hanging wide of
    # it — and open down the front below the breast, where it is pinned.
    mantle = Hm.tunic(p, B, hem=0.36, flare=0.18, slit=False, grow=0.050)
    opening = np.maximum(p[:, 1] + 0.04 - 0.10 * np.clip(1.30 - p[:, 2], 0.0, 1.0),
                         p[:, 2] - 1.30)
    r["wool_blue"] = S.carve(mantle, opening, 0.02)
    hood = Hm.hood(p, B, grow=0.026, cape=0.06)
    # Over the delver's braid, which pushes through any hood's back.
    hood = S.smin(hood, S.chain(p, [V((0.0, 0.13, 1.74)), V((0.0, 0.18, 1.62)), V((0.0, 0.20, 1.48))],
                                [0.060, 0.055, 0.050], 0.02), 0.03)
    r["fur_dark"] = hood
    # The beads, hung across the breast below the hood's cape.
    beads = np.full(len(p), 1e3)
    for k in range(9):
        s = k / 8.0
        x = -0.085 + 0.17 * s
        z = 1.33 - 0.06 * np.sin(np.pi * s)
        beads = np.minimum(beads, S.sphere(p - V((x, -0.160 + 0.03 * abs(s - 0.5), z)), 0.012))
    r["gold"] = beads
    return r


def mound_jerkin(p):
    """**The Haugbrjótr's working leathers** (ADR-382): what a mound-breaker
    goes down in. A jerkin of thick leather to mid-thigh over the tunic,
    against stone edges and a barrow's damp; a hood of the same with a short
    cape to keep the earth off the neck; and a strap slung across the chest
    for the haul. A worker's outline, stocky and square, where the others are
    a wolf's head, a mantle and a hunter's hood."""
    r = underlayer(p)
    r["linen"] = np.minimum(Hm.tunic(p, B, hem=0.62, flare=0.06, slit=True, grow=0.020),
                            np.minimum(Hm.sleeve(p, "l", B, to=0.40, grow=0.010),
                                       Hm.sleeve(p, "r", B, to=0.40, grow=0.010)))
    jerkin = Hm.tunic(p, B, hem=0.70, flare=0.07, slit=True, grow=0.034)
    hood = Hm.hood(p, B, grow=0.026, cape=0.14)
    # Over the braid, as every hood here must be.
    hood = S.smin(hood, S.chain(p, [V((0.0, 0.13, 1.74)), V((0.0, 0.18, 1.62)), V((0.0, 0.20, 1.48))],
                                [0.060, 0.055, 0.050], 0.02), 0.03)
    r["leather"] = S.smin(jerkin, hood, 0.03)
    # The haul strap, from the left shoulder across to the right hip: a band
    # **lying on** the leather, not a cord through it. A tube the jerkin's
    # thickness buried everywhere but mid-chest, where it read in the portrait
    # as a rod stuck in her. So: a 1.2 cm skin over the jerkin, cut to a 6 cm
    # band on the plane through that diagonal and the body's depth.
    run = np.array([-0.29, -0.49])
    across = np.array([run[1], -run[0]]) / np.linalg.norm(run)
    on_line = (p[:, 0] - 0.0) * across[0] + (p[:, 2] - 1.22) * across[1]
    skin = np.maximum(jerkin - 0.012, -jerkin)
    band = np.abs(on_line) - 0.03
    r["dark"] = np.maximum(np.maximum(skin, band),
                           np.maximum(0.92 - p[:, 2], p[:, 2] - 1.52))
    return r


def skald_cloak(p):
    """**The Skald's cloak** (ADR-387): what a poet wore to a king's hall. A
    *feldr* of madder-red wool to the knee, hung from the right shoulder and
    pinned there with a gilt ring-headed pin, so the sword arm stays free and
    the cloak falls open down that side — as the sagas pin every cloak, and as
    the Birka graves lay the pin. A tablet-woven border runs along the
    opening and round the hem, in pale linen. Over a linen tunic, and no
    hood: a skald is heard, and wants his face seen. Bare-headed, he is the one
    delver whose outline is not a hood, and that is the point."""
    r = underlayer(p)
    r["linen"] = np.minimum(Hm.tunic(p, B, hem=0.58, flare=0.07, slit=True, grow=0.020),
                            np.minimum(Hm.sleeve(p, "l", B, to=0.40, grow=0.010),
                                       Hm.sleeve(p, "r", B, to=0.40, grow=0.010)))
    cloak = Hm.tunic(p, B, hem=0.42, flare=0.22, slit=False, grow=0.050)
    # Hung from the shoulders, a cloak falls lower behind than before: the hem
    # rises from the back of the knee to mid-thigh at the front.
    front = np.clip(-p[:, 1] / 0.16, 0.0, 1.0)
    hemline = 0.46 + 0.18 * front
    cloak = S.carve(cloak, p[:, 2] - hemline, 0.02)
    # Open down the right front, below the pin: +x is his left, -y his front.
    opening = np.maximum(np.maximum(p[:, 0] - 0.02, p[:, 1] + 0.03), p[:, 2] - 1.40)
    cloak = S.carve(cloak, opening, 0.02)
    # The tablet-woven border: a band along the opening's edge and the hem.
    edge = np.maximum(np.abs(opening) - 0.016, cloak - 0.004)
    hem = np.maximum(np.abs(p[:, 2] - hemline - 0.016) - 0.016, cloak - 0.004)
    border = np.minimum(edge, hem)
    r["wool_red"] = np.maximum(cloak, -border)
    r["linen"] = np.minimum(r["linen"], np.maximum(border, cloak - 0.006))
    # The pin at the right shoulder's front, standing off the wool: a ring on
    # a shaft, in gilt — the one bright thing on him, as a ring-giver's gift.
    ring_at = V((-0.115, -0.175, 1.39))
    ring = np.maximum(np.abs(S.sphere(p - ring_at, 0.030)) - 0.0065, np.abs(p[:, 1] - ring_at[1]) - 0.008)
    shaft = S.round_cone(p, ring_at + V((0.0, 0.0, -0.028)), ring_at + V((0.035, 0.005, -0.13)), 0.0055, 0.003)
    r["gold"] = np.minimum(ring, shaft)
    return r


ITEMS = {
    "mail_byrnie_worn": (byrnie, dict(voxel=0.010, body_tris=7500, texture=1024, ceiling=10000)),
    # Seen from the eye in first person, not only across a room: dense enough
    # that no facet shows at arm's length (ADR-319).
    "iron_bracers_worn": (bracers, dict(voxel=0.005, body_tris=5000, texture=1024, ceiling=10000, sparse=True)),
    "otr_pelt_worn": (pelt, dict(voxel=0.008, body_tris=9000, texture=1024, ceiling=10000)),
    "wolf_coat_worn": (wolf_coat, dict(voxel=0.008, body_tris=9000, texture=1024, ceiling=10000)),
    "hunter_hood_worn": (hunter_hood, dict(voxel=0.008, body_tris=9000, texture=1024, ceiling=10000)),
    "volva_mantle_worn": (volva_mantle, dict(voxel=0.008, body_tris=9000, texture=1024, ceiling=10000)),
    "mound_jerkin_worn": (mound_jerkin, dict(voxel=0.008, body_tris=9000, texture=1024, ceiling=10000)),
    "skald_cloak_worn": (skald_cloak, dict(voxel=0.008, body_tris=9000, texture=1024, ceiling=10000)),
}


def build(name):
    rig = em.begin()
    regions, plan = ITEMS[name]
    piece = E.sculpt(name, regions, plan, rig)
    piece.name = name
    em.PARTS.append(piece)
    return rig, plan


def export(name, rig, plan):
    em.validate(plan["ceiling"])
    bpy.ops.object.select_all(action="DESELECT")
    for obj in em.PARTS:
        obj.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC / f"{name}.blend"))
    bpy.ops.export_scene.gltf(filepath=str(OUT / f"{name}.glb"), export_format="GLB", use_selection=True,
        export_yup=True, export_apply=False, export_skins=True, export_def_bones=False,
        export_leaf_bone=False, export_animations=False, export_morph=False, export_cameras=False,
        export_lights=False, export_vertex_color="ACTIVE", export_attributes=True, export_extras=True)
    return {"triangles": em.triangle_count(), "mesh_parts": len(em.PARTS), "bones": len(rig.data.bones),
            "source_rig": "humanoid_rig.blend", "sculpted": True,
            "weighted_bones": sorted({g.name for o in em.PARTS for g in o.vertex_groups})}


def review(name):
    """The piece on the delver, front and back: the body is brought in from
    its own source so the fit is what is judged."""
    with bpy.data.libraries.load(str(SRC / "player_body.blend")) as (src, dst):
        dst.objects = ["player_body"]
    body = dst.objects[0]
    bpy.context.scene.collection.objects.link(body)
    for mod in body.modifiers:
        if mod.type == "ARMATURE":
            mod.object = em.RIG
    if name in BODY_PIECES:
        _mask(body)
    em.review(name, SRC)


## Pieces in the body slot, which hide the body under them, and the bones
## whose vertices they hide (`BodyRig.BODY_COVERED_BONES`).
BODY_PIECES = ("mail_byrnie_worn", "otr_pelt_worn", "wolf_coat_worn", "hunter_hood_worn",
               "volva_mantle_worn", "mound_jerkin_worn", "skald_cloak_worn")
COVERED = {"pelvis", "spine_01", "spine_02", "chest", "thigh_l", "calf_l", "foot_l",
           "thigh_r", "calf_r", "foot_r", "upper_arm_l", "upper_arm_r"}


def _mask(body):
    """What `BodyRig` does in the game: drop every face with a corner whose
    strongest bone a body piece covers."""
    import bmesh
    names = {g.index: g.name for g in body.vertex_groups}
    hidden = set()
    for v in body.data.vertices:
        if v.groups and names[max(v.groups, key=lambda g: g.weight).group] in COVERED:
            hidden.add(v.index)
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if any(v.index in hidden for v in f.verts)], context="FACES")
    bm.to_mesh(body.data)
    bm.free()


def main():
    chosen = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(ITEMS)
    path = SRC / "worn_armour_measurements.json"
    report = json.loads(path.read_text()) if path.exists() else {}
    for name in chosen:
        rig, plan = build(name)
        report[name] = export(name, rig, plan)
        review(name)
        print(name, json.dumps({k: report[name][k] for k in ("triangles", "mesh_parts")}))
    path.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
