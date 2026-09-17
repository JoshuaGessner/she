---
id: PRO-008
title: Vertical Slice Polish Sweep
status: accepted
owner: tech
tags: [polish, ui, art, generation, verification]
updated: 2026-09-17
related: [PRO-001, TEC-008, ART-004, ART-005, DES-019]
---

# Vertical Slice Polish Sweep

The developer requested a polish sweep with particular attention to flashing
at room/hallway intersections. ADR-248 records the implementation boundary:
improve the existing playable build while preserving the generated plan,
collision, navigation, loot, combat and lighting rules.

## Implementation plan

| Work | Implementation | Verification |
|---|---|---|
| Room/hallway seams | Render flat floors at their exact footprint; retain collider laps; render a shared alcove floor only once | Count actual coplanar visible overlaps on 24 layouts; compare collision fingerprint before/after; existing build and reach probes |
| Shared asset treatment | World-space triplanar hatch strokes in the existing ink pass, nested by tone and filtered with pixel derivatives; art settings in `data/tuning/ink_style.tres` | Forward+ rendered captures; shader compilation; inspect lit stone, gold, dark corridors and distance |
| Contextual UI | Compact ink-backed interaction and arrival text; hide empty cards; themed deeds dismissal with initial gamepad focus | In-game renders with and without an interaction; existing HUD, menu and bag probes |
| Inventory asset pass | Distinct authored ink SVG icons for every current item, referenced by its Resource; preserve packing, weights, equipment cues and hover descriptions | Item corpus completeness; real bag screenshot and existing inventory probes |
| Integration | Preserve the pre-existing UI/settings/co-op work in the shared working tree | Project, dead-code, gamepad, documentation, determinism and full script/runtime sweep |

## Completion boundary

This is a presentation pass over the existing assets and interfaces. It does
not certify M4's complete final asset production: bespoke character models,
rigged animation, She, the Gullsjúkr, the full environment kit, the remaining
ink vertex channels and Threshold inversion retain their existing M4-T08 and
M4-T10 ownership. M4-T05 remains in progress while its wider art/audio work is
unfinished. Playtest and exported-build gates remain explicit gates.

## Measured seam regression

`floor_surface_probe.gd` builds eight seeds at all three depths and compares
actual rendered flat-floor rectangles at equal height. Before the change:
3,288 floors and **4,480 coplanar overlaps**. After: 3,285 visible floors and
**zero overlaps**. Three duplicate floors belonged to shared alcove cells.

The SHA-256 fingerprint of the complete collision/occluder corpus is identical
before and after:
`5c14b519b73ca389987a665ad8ff79cd28e0a15d0e7a575079a26fbab75980f9`.
This protects the specific regression from a cosmetic fix that changes the
simulation. It does not substitute for the existing walking/navmesh probes.

## Integration evidence — 2026-09-17

The complete script/runtime sweep passed on a fixed snapshot containing this
pass and ADR-247. It covered parsing, boot/teardown, resources, UI, gameplay,
generated-floor traversal and two-player co-op. Independent processes agreed
on all 120 deterministic entries; a different seed produced a different world.
The same determinism check passed after integration with ADR-249's Hunter
sound routing. The combined tree also passed every required check: its first
runtime sweep stopped on the doorway group's 45-second disconnect/rank timeout.
That scenario passed alone, then the complete doorway group passed on separate
ports; the remaining unchanged sweep passed, including navigation reachability,
geometry/plan agreement, walking (zero stuck routes) and two-player co-op.
Runtime/tool file fingerprints stayed unchanged throughout these checks. No
gameplay workaround or relaxed assertion was introduced for the timeout.

Forward+ captures cover the inventory, contextual prompts and ink treatment.
The amplified 1,920 × 1,080 ink benchmark measured **0.437 ms per pass** across
401 passes (8.337 ms raw versus 183.526 ms amplified). This is a local
measurement, not a claim about every target GPU. All 25 current items have
authored icons and the complete 110-resource data census passes.
