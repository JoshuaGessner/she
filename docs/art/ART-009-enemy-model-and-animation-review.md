---
id: ART-009
title: Enemy Model and Animation Review
status: draft
owner: art
tags: [art, enemies, animation, review, blender]
updated: 2026-10-02
related: [ART-004, ART-005, ART-006, DES-013, DES-017, PRO-001, PRO-002]
---

# Enemy model and animation review

The developer authorised the enemy production pass on 2026-09-29. This covers
the current Delvings roster: Wretch, Sling-Wretch, Bellringer, Hall-Warden,
Hoard-Keeper and the Gold-Sick. Future-biome enemies are outside this pass.

## Source and delivery

`source_art/enemies/build_enemy_models.py` builds the five standard enemies;
`source_art/heroes/build_gullsjukr.py` builds the Gold-Sick.
`source_art/enemies/animate_enemies.py` bakes the shared-rig performances into
their `.blend` sources and exports the engine GLBs. Run both model builders
before the animation builder. All use the installed Blender in background mode.

The models retain the permanent 28-bone rest hierarchy. Export merges authored
parts into one skinned mesh per enemy, preserving its material surfaces; the
Sling-Wretch keeps a separate skinned stone for release/reload visibility. Mesh
names cannot collide with bone names: Godot otherwise renames those bones on
import. Every surface carries UVs and FLOAT_COLOR ink metadata. The import
script disables vertex-colour albedo because these colours encode ink data.

## Animation contract

Standard enemies carry idle, search, walk, run, telegraph, attack, recovery,
stagger and death. Bellringer also carries call. The Gold-Sick carries idle,
search, walk, run, collect, take and shrug. It has no killable combat/death state
in the current game; no unused combat library is presented as shipped behaviour.

Combat clips use normalized phase time. Gameplay retains the existing wind-up,
active and recovery durations, hitboxes and damage. Animation does not emit a
second hit. Locomotion advances by distance travelled; planted feet are authored
with two-bone inverse kinematics. Death animation replaces the old proxy's root
topple, retaining the corpse lifetime and later sink/despawn.

The Gold-Sick walks toward bait before collecting. The host replicates its
presentation phase and progress so collecting, taking and shrugging reach other
players. Ordinary enemies also replicate normalized event progress so a late
arrival samples the current performance instead of restarting a wind-up.

The skeleton has hand bones, not finger chains. Grips are modeled poses carried
by the animated wrists. This pass does not add facial, finger or cloth rigs.

## Verification and remaining review

- `rig_probe.gd` checks all six rest hierarchies, skins, required clips, actual
  skeletal motion, finite poses, loop seams and locomotion foot planting.
- `enemy_animation_probe.tscn` exercises the production actor/visual path:
  wind-up, follow-through, stagger, death interruption, unchanged actor transform
  and the Hunter's presentation phases.
- `art_probe.gd` checks the GLBs against the category budgets and material rules.
- `enemy_review.gd` captures lineup poses under the production ink shader and
  close-up material views in `/private/tmp/she_enemy_*.png`.

The captured lineup poses are also retained as
`source_art/enemies/runtime_*_review.png`. The printed-page lineup is a shape
review under the production shader, not a replacement for the Deep's lighting.

The controlled Deep darkness capture (`--threat-dark-shot`, seed 5, floor 2)
measured a body eight metres away against zero ambient/direct illumination:
81% of its silhouette was drawn when marked, versus 0% in the unmarked control.
The paired images are retained as `dark_marked_review.png` and
`dark_control_review.png` beside the lineup captures. Natural-post captures
were inconclusive because the sampled posts were lit; the controlled capture
proves darkness visibility, not the lighting balance of every generated room.

Final standard-enemy exports contain 4,462 / 4,734 / 4,554 / 4,852 / 5,818
triangles respectively, below the 6,000-triangle category budget. Across all
six enemies the library contains 53 clips.

The final close-up pass removed separate rounded cheek pieces from the
Gold-Sick, narrowed the nose profile and replaced spherical gold sack bulges
with struck coins emerging from tied leather openings. The resulting export
was rechecked against the rig, art and live-animation probes; its material
review is retained as `source_art/heroes/gullsjukr_runtime_review.png`.

The final focused checks and full local regression sweep passed on 2026-09-29,
including 151-script parsing, boot/teardown, co-op and late joins. Foot-plant
drift measured below 0.025 m. The status check retains nine existing untuned
documentation warnings. Final visual sign-off remains pending. Faces, equipment grips,
silhouette character and motion readability must be reviewed in actual combat;
passing a mesh or animation census is not art approval. `M4-T10` remains open.

**ADR-275:** a state with no clip of its own played `idle` while the body moved,
so an UNAWARE enemy walking back to its post glided with its feet still. Those
states walk while moving now, at the walk's stride, and the animation probe
asserts moving and still clips for every travelling state, and half a cycle for
half a stride.

**ADR-280:** the first-person hands are closed fists built round each hand's
grip socket, not an open carrying curl. The seax is held up and in, so its
edge is in view. The shield rests on its rim at the left edge and on guard
covers only the left half of the view.

## Silhouettes (ADR-305)

Five kinds were one body in five outfits, and two of them were one hooded
figure. Each limb now has its own anatomical profile (`LIMB_PROFILES`), and
each kind has a silhouette taken from Norse finds, recognisable before its
weapon is:

| Kind | Reads as | Built from |
|---|---|---|
| Wretch | small, ragged, many | hood with a tail and torn cape, tongued hem, bound forearms and calves |
| Sling-Wretch | lopsided, the one that stays back | bare bound head and braid, hide on the left shoulder only, a sling hanging to the knee |
| Bellringer | long and narrow | hood, robe to the shins, chain across the body, bells at the belt |
| Hall-Warden | square and heavy | conical spangenhelm, mail curtain, lamellar shoulders, hauberk |
| Hoard-Keeper | tall and closed | crested round helm, byrnie, cloak to the calf, arm rings, spear |
| Gullsjúkr | lopsided under a hoard | unchanged above the waist; the shared legs, bound |

Nothing worn may cover the eyes, where the senses are drawn (ADR-295).
Cloth follows the bones it is weighted to; nothing simulates.

`--roster-shot=DIR` stands every kind at one post on a generated floor, lit by
the player's lantern at 2.6 m under the production ink, facing the camera and
turned away. It is the review this section's claims were checked against.
Windowed, because a headless render has no pixels.

Standard-enemy exports now contain 5,668 / 5,308 / 5,930 / 5,080 / 5,174
triangles (Wretch, Sling-Wretch, Bellringer, Hall-Warden, Hoard-Keeper) and
the Gold-Sick 31,998. Visual sign-off remains the developer's.
