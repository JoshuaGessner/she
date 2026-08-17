---
id: PRO-001
title: Roadmap & Milestones
status: accepted
owner: process
tags: [roadmap, milestones, scope, planning, production]
updated: 2026-08-15
related: [DES-001, TEC-001, TEC-003]
---

# Roadmap & Milestones

**Philosophy:** prove the *feel* before building the *systems*. This game lives or dies on one sentence — *"I have enough. I should leave. One more room."* Everything before that sentence is provably fun is speculative work.

The most common way a project like this dies is building the meta-progression first, because it's the most fun part to design. **Do not.** The meta-layer is worthless if the run isn't good.

> **Notation (ADR-063).** Milestone scope is written as checkbox tasks with permanent IDs so `tools/status.py` can read progress straight out of this file. States: `[ ]` not started · `[~]` in progress · `[x]` done · `[-]` cut. The `→ DOC-ID` suffix at the end of a task line names the docs that task implements. Task IDs are never reused or renumbered. **This notation carries no schedule** — see *Estimates are lies* below.

---

## M0 — Design Lock
<!-- milestone id=M0 size=0 -->
**Goal:** a signed-off design document set.
**Deliverable:** these docs.

> **GATE M0 EXIT** `passed 2026-08-14` — `DES-001` through `DES-008` at status `accepted`; `OPEN-QUESTIONS.md` empty of blocking items.

> **Reordered by ADR-008.** Co-op is no longer a late milestone — it is a constraint on every milestone. Networking exists from M1.

> **DECIDED (ADR-034): solo project, no fixed timeline.** Calendar estimates are removed — on a solo project they produce guilt rather than throughput, and the **exit gates were always the real mechanism.** They are pass/fail on the game being good, never on elapsed time.
>
> Sizes below are *relative effort only*. The one piece of discipline that still matters without a deadline forcing it: **clear a milestone's exit gate before starting the next one.**

## M1 — The Feel Prototype  ·  *smallest milestone*
<!-- milestone id=M1 depends=M0 size=1.0 -->
**Goal:** answer "is moving and fighting in this space enjoyable?" — with grey boxes and zero content.
- [x] `M1-T01` First-person controller: walk, sprint, crouch, stamina, weight affecting movement. *Unjuiced per Swink; couplings measured, encumbrance signed off 2026-08-15* → DES-009, DES-005
- [x] `M1-T02` One weapon, one enemy, hit reactions, death. *Built with the awareness ladder (ADR-072); anatomy and telegraph measured. Signed off 2026-08-16 on DES-009's actual M1 criterion — swinging and connecting feel decent unjuiced. The avoidance question moves to `M2-T02`, where there is finally something worth declining (ADR-079)* → DES-009, DES-013
- [x] `M1-T03` One hand-built room set, no generation. *A cycle, not a corridor: two routes to the exit, one enemy-free, both asserted by `--route-probe`. The Prize costs -18% walk speed and triples your audible radius, so the Guardian room poses a real question. Signed off 2026-08-16* → DES-015
- [x] `M1-T04` Weight & Clamor as visible debug numbers. *Layer 1 radius, not the M2 field (ADR-073); readout plus an audible-radius ring, since TEC-001 calls this untunable blind* → DES-005
- [x] `M1-T05` **Two players over localhost**, host-authoritative (`TEC-004`). *The peer owns its body, the host owns every consequence (ADR-082) — `TEC-004` asked for prediction and banned reconciliation, which cannot both hold. A two-process smoke test runs in the pre-commit sweep* → TEC-004
- [x] `M1-T06` **Networking spike test — go/no-go:** 4 peers, ~150 synchronized entities. This validates or kills the whole Godot high-level-multiplayer approach, and it must happen now rather than at M4. **GO (ADR-068)** — CPU never the constraint; bandwidth is, and relevance filtering is load-bearing → TEC-004
- [x] `M1-T07` **Determinism harness in CI**: same seed on two processes → identical layout hash. *Built before the generator on purpose — written first it is a specification `M4-T01` must satisfy, written after it only ratifies whatever the generator already does* → TEC-001, DES-015
- [x] `M1-T08` **Godot project skeleton** — folder layout, the ≤6 autoload budget enforced in CI (ADR-066), Forward+, naming and GDScript conventions, CI for the doc index and the dashboard. *The determinism harness is `M1-T07`'s deliverable, not this one (ADR-067)* → TEC-002, TEC-001
- [x] `M1-T09` **Ink shader spike** — grey boxes, outlines and boil only. **Go/no-go**: if it is not ~70% convincing, commit to flat quantised shading and never build the other path (ADR-062, ADR-064). **GO (ADR-070)** — pass costs ≈0.4–0.6 ms at 1080p; flat quantised shading is not built → ART-005
- [x] `M1-T10` **Shared humanoid rig — seven sockets, authored to the collider** (ADR-080). `sock_head` `sock_hand_r` `sock_hand_l` `sock_back` `sock_hip_r` `sock_hip_l` `sock_shoulders`; Body and Arms are *skinned*, not socketed (ADR-057). Built to 1.80 m standing, 0.35 m radius, 1.62 m eye — the dimensions `M1-T01` was signed off against. Must exist before *any* character work; adding a socket later means re-exporting every mesh → ART-004, DES-020

> **GATE M1 EXIT** `passed 2026-08-16` — *two people who aren't you play for 10 minutes and ask to keep playing.*

**If this fails, nothing else matters.** Iterate here as long as needed. Do not proceed on hope.

## M2 — The Loop Prototype  ·  *~1.5× M1*
<!-- milestone id=M2 depends=M1 size=1.5 -->
**Goal:** prove the target sentence.
- [x] `M2-T08` **Data schema base resources** — `ItemResource` + trait resources, stable string IDs, **plus the CI validator**. Built with the first ten resources, not the first thousand. *Moved ahead of `M2-T01` by ADR-083. `WieldableTrait` only — the other six traits describe systems that do not exist yet. Validator implements the rules whose data exists and no others (ADR-084): a rule against an empty folder is a green tick that cannot fail. Item text is translation keys (ADR-084)* → TEC-006
- [x] `M2-T01` Loot with weight and clamor; **one inventory: grid-based, weighted, real-time** (ADR-040, reaffirmed by ADR-083 — decided, not a prototype fork). *6×5 grid ⟨tune⟩, `ItemInstance` + `ItemCatalogue`, host-validated pickup and drop, blockout bag screen. The room set's Prize is `glt_altar_plate` and its hand-rolled loot path is deleted. Carried clamor is a decay floor, so dropping loot buys silence back (ADR-087)* → DES-008, DES-005, DES-019
- [x] `M2-T02` The Hunt: clamor field, **the Gullsjúkr** (`DES-017` — wealth-sensing, gold-baiting, the whole point), escalation. *It navigates the clamor gradient and never a player transform (`TEC-001`), feels carried tribute through walls, and stops for gold a player disturbed — authored floor treasure is scenery to it (ADR-089). The throw verb is built. **The Sealing moved to `M2-T04`**, where the Shafts it seals exist* → DES-017, DES-005
- [ ] `M2-T03` **The Ear + adaptive audio driver** (`DES-018`, ADR-035/036) — both channels together, from the first build. *Carries the Gullsjúkr's reserved instrument: `DES-017` says you hear it before you see it, always, and `M2-T02` shipped it with only the visual half* → DES-017, DES-018, DES-019, TEC-005
- **Standing test from here on: every milestone must be playable to completion with audio muted**
- [ ] `M2-T04` Extraction: reach an exit, keep what you carried — **plus the Sealing** (`DES-005` Layer 3), moved here from `M2-T02` by ADR-089 because it seals the Shafts this task builds → DES-005, DES-002
- [ ] `M2-T05` Death: lose it all — plus **downed state and ember rescue** (`DES-012`) → DES-003, DES-008, DES-012
- [ ] `M2-T06` Minimal Lair: stash and re-descend → DES-008, DES-014
- [ ] `M2-T07` **Party scaling instrumented from the first build**: per-capita extracted value at 1/2/4 players → DES-012
- [ ] `M2-T09` **Threshold theme + adaptive driver prototype** — the emotional anchor and the highest-risk audio tech, both cheap to test early → ART-002, ART-003, TEC-005

> **GATE M2 EXIT** `pending` — a playtester **voluntarily abandons loot to survive**, then talks about it afterwards. That's the whole game in one moment. If it doesn't happen, the pressure system is wrong, not the content.

> **GATE M2 COOP** `pending` — someone carries a friend's ember out and it is the best moment of the session.

## M3 — The Pact  ·  *~2× M1*
<!-- milestone id=M3 depends=M2 size=2.0 -->
**Goal:** prove meta-progression makes runs *more* interesting, not easier.
- [ ] `M3-T01` Tribute → Boon → Aspects; **two Aspects complete. The other three are absent — not stubbed, not listed, not selectable** (ADR-064) → DES-003, DES-004, DES-008
- [ ] `M3-T02` **Two classes complete** — Húskarl and Veiðimaðr, opposite loop relationships. **The other four are absent from the class-select screen entirely.** A stubbed class a playtester can pick and that does nothing produces worthless feedback (ADR-064) → DES-011
- [ ] `M3-T03` **Boon cap by own rank** (ADR-011) — must exist before mixed-rank parties are tested → DES-003, DES-012
- [ ] `M3-T04` Tithe and Pact Rank escalation (`DES-003`) — *and with it the rank at which a Gullsjúkr becomes killable, which `M2-T02` left absent rather than stubbed* → DES-003, DES-017
- [ ] `M3-T05` Death → Legacy selection screen, with the "what you learned" panel first (ADR-006) → DES-003, DES-019
- [ ] `M3-T06` Save system with versioning and migration from day one (`TEC-003`) → TEC-003
- [ ] `M3-T07` **Equipment slots and visible gear** — six slots, per-class bare arms, armour rendering over them, Pack driving grid size → DES-020
- [ ] `M3-T08` **Deeds awarded at the Settle beat** — never mid-run; the run must end on evidence of what you did → DES-016

> **GATE M3 EXIT** `pending` — a rank-8 player and a rank-1 player both die at similar rates for different reasons. Verify against the `DES-003` balance guardrails.

> **GATE M3 COOP** `pending` — a rank-8 player brings a rank-1 friend into a rank-8 floor (ADR-010). The newcomer is downed repeatedly and *still wants to go again*. If they don't, the ember rescue isn't doing enough work.

## M4 — Vertical Slice  ·  *largest; art and audio dominate*

> **RESCOPED (ADR-061).** A vertical slice is **a small, polished, fully playable cross-section showing all major systems working together** — typically 10–30 minutes. The previous M4 listed *all six classes* and a 45-minute target, which is **breadth, not a cross-section**, and would have delayed the moment we learn whether the game is good by months of content work.
>
> **M4 ships two classes, not six.** All six remain required *for launch* (ADR-012 — they are available from the start), but they move to **M5**. The slice's job is to prove the game is worth finishing; class breadth is what you build once you know it is.
<!-- milestone id=M4 depends=M3 size=unknown -->
**Goal:** one biome, complete and polished, representative of the final game.
- [ ] `M4-T01` The Delvings: full generation from room modules, 3 floors — *first point at which the Hunt can vary by floor and persist across one (`DES-017`, ADR-037); `M2-T02` has one floor to hunt on* → DES-015, DES-006, DES-017
- [ ] `M4-T02` ~6 enemy archetypes, 2 hazard types → DES-013
- [ ] `M4-T03` **Two classes**, fully polished — Húskarl and Veiðimaðr, opposite loop relationships. *The other four move to M5 (ADR-061).* → DES-011
- [ ] `M4-T04` Contracts tier 1–3, one faction (`DES-007`) → DES-007
- [ ] `M4-T05` Real art pass, real audio, real UI, ping system → ART-001, ART-002, DES-019, DES-012
- [ ] `M4-T06` Full save/load, settings, controls rebinding → TEC-003, DES-018
- [ ] `M4-T11` **The accessibility suite** — colour-blind support with no information in hue alone, UI scaling, dyslexia-friendly font, high contrast, per-bus volume sliders, mono output, and independently adjustable shake / blur / head-bob / FOV. *Split out of `M4-T06` by ADR-077: "settings" was standing in for a dozen deliverables, several of which are architectural constraints rather than options* → DES-018
- [ ] `M4-T07` **Steam networking integration** (lobbies, invites, relay) — before any external playtest → TEC-004
- [ ] `M4-T08` **Ink shader, complete** — hatching (nested triplanar layers), the Threshold/Deep inversion, vertex-colour authoring across the asset library → ART-005
- [ ] `M4-T09` **Composer onboarded; first full stem set** — brief handed over as-is, stems authored to one tempo and key → ART-003
- [ ] `M4-T10` **Phase 2→3 asset production** — real models replacing blockout, per the schedule and specs → ART-004

> **GATE M4 EXIT** `pending` — shippable-quality **25 minutes** ⟨tune⟩, played solo *and* as a 4-stack, with every major system present and polished. This is what a publisher, a Steam page, or a Kickstarter would see.

## M5 — Content & Breadth
<!-- milestone id=M5 depends=M4 size=unknown -->
- [ ] `M5-T01` **The remaining four classes** — moved here by ADR-061; all six are required for launch (ADR-012) → DES-011
- [ ] `M5-T02` Remaining biomes — Barrow-Fields, Sunken Wood → DES-006, DES-015
- [ ] `M5-T03` Remaining factions and Aspects → DES-007, DES-004
- [ ] `M5-T04` Full enemy roster and modifier set → DES-013
- [ ] `M5-T05` **Design and build onboarding / the first hour** — `DES-010` C1 is the largest absolute churn point. *Produces a new design doc; deliberately not written yet (ADR-065) — it is not needed to start development, and a reference to a document that does not exist is itself a stub.* → DES-010, PRO-005
- [ ] `M5-T06` Balance passes against real telemetry, at every party size → DES-022

> **GATE M5 EXIT** `pending` — all six classes, three biomes and the full enemy roster complete and balanced; `DES-022`'s balance checks pass at every party size; **self-reported growth across runs 11–25 shows no dip** (the headline metric). Feature-complete: from here, only bugs and polish.

## M6 — Ship
<!-- milestone id=M6 depends=M5 size=unknown -->
Store page, IP attorney review (`PRO-004`), demo, playtesting at scale, launch.

---

## Standing risks

| Risk | Severity | Mitigation |
|---|---|---|
| Meta-progression trivializes runs | **High** | Tithe counter-pressure (`DES-003`); guardrail tests at M3 |
| Scope creep via biomes/enemies | **High** | Hard caps in `DES-001`; systems over content |
| Procedural levels feel samey | Medium | Hand-authored modules, not generated geometry (`TEC-001`) |
| Save migration retrofit | Medium | Versioning from commit one (`TEC-003`) |
| Hunt is annoying rather than tense | Medium | Counter-play tools first, not last; heavy M2 playtesting |
| Solo-dev burnout | **High** | Milestone gates with real exit criteria; ship the slice before breadth |
| IP exposure | Low (if `PRO-004` followed) | Guardrails + pre-launch legal review |
| **Godot high-level multiplayer doesn't scale to our object counts** | **High** | M1 spike test is an explicit go/no-go (`TEC-004`) |
| **Co-op roughly doubles QA surface** | **High** | Automated 2-client smoke tests in CI from M1; accept slower milestones rather than skipping the tests |
| Class balance across 6 classes × 5 Aspects | Medium | Shared tree + small Rite branches (ADR-009) keeps the surface small; every class solo-viable is a hard rule |

## Estimates are lies

The ⟨week⟩ figures assume roughly one focused full-time developer and are **optimistic by the usual factor**. Treat ordering as the real content of this document; treat durations as relative weights, not commitments.
