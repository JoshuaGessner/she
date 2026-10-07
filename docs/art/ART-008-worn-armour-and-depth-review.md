---
id: ART-008
title: Worn Armour, Class Arms and Depth Variants — Review
status: proposed
owner: art
tags: [art, assets, modelling, review]
updated: 2026-10-07
related: [ART-004, ART-006, ART-007, DES-020, TEC-008]
---

# Worn armour, class arms and depth variants

The developer asked to continue the remaining modelling plan after the first
46-asset quality pass. This review covers the next deliverables. It does not
accept the entire `M4-T10` milestone or claim that full character and enemy
models are complete.

## Shared-rig equipment

`mail_byrnie_worn.glb` is a fitted, split-skirt mail shirt with half sleeves,
trousers and boots. Body remains one slot, including the legs, and its sleeves
stop above the elbow. `iron_bracers_worn.glb` supplies two open forged cuffs,
leather bindings and a raised central ridge. Both use the exact 28-bone rest
pose from `humanoid_rig.blend`; neither adds sockets or changes the player
collider. The loose pickup props retain their base-centred pivots.

- [Mail fit](../../source_art/characters/mail_byrnie_worn_review.png)
- [Bracer fit](../../source_art/characters/iron_bracers_worn_review.png)

Covered body geometry is hidden when wearing the mail and restored when it is
removed, so a rigid base leg cannot poke through a deforming trouser knee. The
reviews hide it the same way.

`otr_pelt_worn.glb` supplies the other Body-slot item: Ótr’s Pelt. Its fur
mantle sits over a complete tunic, trousers and boots so replacing mail does
not leave holes in the covered body. The equipment regression swaps mail for
the pelt, checks that the old garment is removed, then checks the original body
is restored on unequip. Every Body/Arms item now requires a worn-model reference
in its data validation.

- [Pelt fit](../../source_art/characters/otr_pelt_worn_review.png)
- [Pelt from behind](../../source_art/characters/otr_pelt_worn_rear_review.png)

## Class dress (ADR-354, ADR-364)

Two pieces are not items. They are a class's own look, `ClassResource.dress`,
worn when nothing is in the body slot and replaced by any body piece put on.
They weigh nothing and ward nothing, and no catalogue or bag ever holds them:
`ClassResource.dress_item()` wraps the model in an `ItemResource` at run time
so `BodyRig.wear` can dress it as gear.

- **`wolf_coat_worn`, the Úlfheðinn.** A wolf's skin worn as a hood, the
  skull on the crown with the muzzle over the brow (the Torslunda plates'
  wolf-warrior), the hide to the calves, the forelegs knotted on the chest,
  grey with a pale muzzle. The first review had the delver's braid through
  the hood's back; the hide is thickened down the nape.
- **`hunter_hood_worn`, the Veiðimaðr.** A hood and shoulder-cape with a
  liripipe tail, cut after the Skjoldehamn find, in weathered wool.
- **`volva_mantle_worn`, the Völva** (ADR-379). Þorbjörg's dress in Eiríks
  saga ch. 4: a blue mantle hung wide of an ankle-length gown, open down the
  front and falling to the calf behind; a hood of black lambskin; glass beads
  across the breast, which the gilt pass picks out. The first review hung the
  mantle as a narrow slab down the back, which read as a pack. It is now a
  shell around the gown, open in front. The hood is thickened over the braid
  as the wolf-coat's is.

The Húskarl has none: a byrnie and round shield already make its outline.
`--fury-probe` row 8 asks every class with a dress to wear it, and the
Úlfheðinn's to give way to a byrnie.

- [Wolf-coat fit](../../source_art/characters/wolf_coat_worn_review.png)
- [Wolf-coat from behind](../../source_art/characters/wolf_coat_worn_rear_review.png)
- [Hunter's hood fit](../../source_art/characters/hunter_hood_worn_review.png)
- [Völva's mantle fit](../../source_art/characters/volva_mantle_worn_review.png)
- [Völva's mantle from behind](../../source_art/characters/volva_mantle_worn_rear_review.png)

## The body under the gear (ADR-308)

A teammate is `player_body.glb`, built by
`source_art/characters/build_player_body.py` on the shared rig from the
enemies' anatomy, not the rig's proxy. It wears a linen tunic, wrapped calves,
boots and bound hair. The proxy stays in `humanoid_rig.glb` for `rig_probe`.
Armour hides the body by each vertex's dominant bone, so the neck is weighted
to `neck` and survives a byrnie. The byrnie's sleeves and trousers follow the
same limb profiles; its review renders over the delvers' body, not the proxy.

## Sculpted, as the enemies are (ADR-318)

When the enemies were sculpted (ADR-316), the delver was left the one boxy
human in the game. The body and all three worn pieces are now sculpted through
`build_enemies.sculpt`, from `sculpt_humanoid`'s anatomy and garments:

| Piece | Triangles | Built by |
|---|---|---|
| `player_body` | 7,000 | `build_player_body.py` |
| `mail_byrnie_worn` | 7,500 | `build_worn.py` |
| `iron_bracers_worn` | 5,000 | `build_worn.py` |
| `otr_pelt_worn` | 9,000 | `build_worn.py` |
| `wolf_coat_worn` | 9,000 | `build_worn.py` |
| `hunter_hood_worn` | 9,000 | `build_worn.py` |
| `volva_mantle_worn` | 8,989 | `build_worn.py` |

- **The body** is a tunic to mid-thigh with fitted sleeves to the wrist,
  trousers, leg wraps, turnshoes, a belt, and hair bound back with a braid.
  It stands 1.835 m tall, and its upper arm reaches 0.348 m, inside the rig's
  0.35 m capsule.
- **Its colour is the teammate's.** It bakes a value map — each material's
  lightness against linen, held to ADR-308's range of 0.75–1.0 — and
  `BodyRig._dress_in` keeps that map and the normal map, taking only the
  teammate's colour.
- **The byrnie** is mail to mid-thigh, split for the stride, with sleeves past
  the elbow.
- **The bracers** are hammered forearm shells with rolled rims.
- **Ótr's pelt** is a thick otter-hide mantle down the back. The head lies on
  the right shoulder looking forward, with its pale throat; the forepaws hang
  on the chest, and the tail runs to the knees.

## First-person arm library

Six arm pairs use that same skeleton and bind pose. Each contains tapered
forearms, shaped palms and individually modelled fingers closed round the grip
(ADR-280). The rig has hand bones rather than finger bones; the fingers do not
articulate individually. This is a modelling limitation, not a claim of
authored finger animation.

**Sculpted (ADR-319).** These are on screen for every second of a run, so they
are now the most carefully made models in the game:
- **Built like the bodies.** Each pair is sculpted through `build_enemies.sculpt`
  at a 2.8 mm voxel, in bounds round the forearms only, and decimated to 9,000
  triangles with 1024² maps.
- **ADR-280's construction is kept.** The fist is still built round
  `sock_hand_*`, read from the rig, with the same palm, finger and thumb paths.
  It now has knuckles standing proud and a forearm that swells below the elbow.
- **Class marks are part of the skin.** The Völva's interlace is painted into
  the skin's colour map, and the Húskarl's scars are raised.
- **Iron is planished:** small, shallow hammer marks. Dents 3.5 cm across read
  as low-poly facets from the eye, on the worn bracers most of all.

| Class | Authored distinction | Review |
|---|---|---|
| Húskarl | Healed forearm cuts | [Arms](../../source_art/characters/huskarl_arms_review.png) |
| Veiðimaðr | Draw-finger tabs and wrist tape | [Arms](../../source_art/characters/veidimadr_arms_review.png) |
| Völva | Ink marks and bone charms | [Arms](../../source_art/characters/volva_arms_review.png) |
| Skald | Stained fingers and a wrist tie | [Arms](../../source_art/characters/skald_arms_review.png) |
| Úlfheðinn | Fur wrist wraps | [Arms](../../source_art/characters/ulfhedinn_arms_review.png) |
| Haugbrjótr | Leather cuff and small wrist tools | [Arms](../../source_art/characters/haugbrjotr_arms_review.png) |

Only Húskarl and Veiðimaðr currently have class resources in the game. The other
four arm assets do not create classes or expose unfinished class choices.
Full class bodies, enemy models and authored locomotion remain separate work.

## The deeper Delvings

The Retreat and Cause each add three wall heights and one floor variant. They
keep the kit's footprints and use the generator's existing band geometry;
the visual variants do not replace its collision or navigation surfaces.

[Depth comparison](../../source_art/environment/delvings_depth_review.png)

## Reproduction

Run these with Blender in background mode and `--python-exit-code 1`:

- `source_art/characters/build_player_body.py`
- `source_art/characters/build_worn.py`
- `source_art/characters/build_class_arms.py`
- `source_art/environment/build_delvings_depth.py`

The measurement JSON files next to the scripts record triangle counts and
bone usage. Review both the source renders and the actual in-game views:
passing a dimension or skin-binding check does not establish visual quality.

An independent GLB inspection checks all nine character-related exports
against the original rig: identical bone names, parent hierarchy and rest
transforms; normalized skin weights; UVs; normals; and the required ink colour
attribute on every primitive. Godot's `art_probe.gd` also passes the complete
library with these exports present.

Runtime checks cover the equipment lifecycle: the byrnie masks the shared body
from 2,224 to 816 triangles, and removing it restores all 2,224. Both worn
slots resolve to the existing skeleton without a duplicate armature. Rig tests
check rest-pose drift and deformation at the chest, shoulder, thigh and both
forearms. First-person hands follow the presented weapon and off-hand grips
independently; the camera remains independent of the skeleton. The moving-grip
probe measures draw-in and swing poses after frame processing: 0.0000 m and
0.04° maximum error. Disabling the frame refresh deliberately produces a
0.0457 m / 5.78° miss and fails that check. Returning to an unsworn body also
removes the class arms cleanly.

The depth probe confirms all eight variants are used, repeatable generation at
depths one and two, unchanged collision slabs, and floor relief above the
existing floor render surface. The relief is deliberately shallow: actual
steps and slopes remain the generator's responsibility.
