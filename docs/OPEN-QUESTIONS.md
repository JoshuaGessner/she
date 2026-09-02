# Open Questions

Live queue of unresolved decisions. Resolved items move to `process/PRO-002-decision-log.md` as ADRs and are deleted from here.

> **Question numbers are permanent identifiers and are never reused.** The
> "see your own sound" accessibility question was filed as **Q105** and is now
> **Q109** (ADR-085): ADR-057 had already spent Q105 on off-hand swapping, so
> the id meant two unrelated things and *"is Q105 open?"* had two correct
> answers. Take the next free number, always — `status.py --check` compares
> this file against every ADR's `Closes` line in both directions.

---

## ✅ Development is unblocked

**Nothing on this page blocks M1 or M2.** Design is locked — all 39 documents are `status: accepted`, and changing one now requires an ADR.

Every question below is one of three kinds:

- **A prototype question** — only a build can answer it. Each has a documented lean.
- **A measurement** — not a decision at all.
- **Genuinely deferred** — needed at M4/M5, and answering it now would be guessing.

> **The design is finished. Further planning requires an ADR justifying why it could not wait until after M1** (ADR-062).

---

## Needed at M2

*Nothing outstanding. Q36 was answered by ADR-068 (the `M1-T06` spike returned GO) and Q103 by ADR-084; both sat here after the ADRs that closed them, which is the failure ADR-083 added a check for.*

## Needed at M4 / M5

| # | Question | Doc |
|---|---|---|

## Prototype questions — only a build answers these

Recorded so they are not mistaken for undesigned areas.

| Area | Question | Doc |
|---|---|---|
| Combat | Weight, commitment, swing timing; how lethal | `DES-009` |
| Shader | Does the ember read as *sick* when loud? | `DES-019`, ADR-042 |
| Shader | Hatch layer count (Q101); object-ID buffer needed? (Q102) | `ART-005` |
| Shader | Do player characters get heavier outlines? (Q99) | `ART-005` |
| Inventory | **Cell sizes and rummage speed.** Grid dimensions are settled at 6×5 by ADR-087 — measured, not guessed: it is where a bag of gear runs out of squares and a bag of glitter runs out of legs. Whether 44 px cells read at a glance, and whether `bag_open_time` ⟨tune⟩ 0.35 s feels vulnerable or merely slow, are questions only a playtest answers | `DES-019` |
| Pressure | **Waystone drop rate** — the strongest single lever in the game | `DES-005` |
| Pressure | **Is one early exit enough?** ADR-186 made the Shaft the way *down*, so a Waystone is the only extraction above the bottom floor — which puts the entire "can I leave?" question on a single ⟨tune⟩ drop rate. `DES-005` already warns that too rare means players are *"shoved to floor 3 every run whether they wanted it or not"*, and that warning is sharper now. Only play answers it, and it is the biggest thing ADR-186 can have got wrong | `DES-005`, `DES-019`, ADR-186 |
| Enemies | **Where does standing danger go on a floor with no held arm?** `FloorAnchors` posts enemies in held rooms, which is ADR-032 generalised — but only two of the five cycle types hold a span, so **145 floors of 360 have nothing held** and would carry no standing danger at all beyond the Hunt. Either posts derive from something richer than held-ness, or the catalogue guarantees a held arm per floor. Measured, not guessed; it is `M4-T02`'s to answer | `DES-013`, `DES-015`, ADR-171, ADR-181 |
| Audio | Crossfade length between states | `ART-002`, ADR-043 |
| Co-op | Per-capita extracted value at 1 / 2 / 4 players | `DES-012` |
| Hunter | **Gold-bait cost curve; how long a bait buys.** Built at `M2-T02`: proportional to carried value (ADR-039) with an absolute floor (ADR-089), buying ⟨tune⟩ 4.5 s of Collecting. Whether that is a window worth spending a torc on is the playtest question | `DES-017` |
| Art | First-person arms — universal or per-class? (Q96 answered; **proportions** are a feel question) | `ART-004` |
| Progression | **Self-reported growth across runs 11–25** | `DES-022` — the headline metric |
| Accessibility | **Q109 — "see your own sound": a polished, in-game version of the M1 debug clamor footprint.** The dev overlay draws the *shape* your noise actually makes, notched where walls muffle it (`M1-T04`). `DES-018`'s Ear reports **how loud** you are and **which bearing** heard you; it does not show **where your sound went**, which is the thing a hearing player gets for free and a deaf player currently cannot get at all. Worth prototyping as a toggle: does the footprint read as information or as visual noise in a real room? **If it works it is a strong candidate for the audio twin ADR-036 demands**, and it is largely already built. Cost: the shape exists; the work is art direction and the readability test | `DES-018`, `DES-019`, ADR-036, ADR-073 |

---

## The first three things to build

Not questions. The answer to *"what now."*

1. ~~**Godot project skeleton**~~ — done (`M1-T08`). `TEC-002` layout, Forward+, typed GDScript enforced by the parser, the ≤6 autoload budget enforced in CI (ADR-066), doc-index and dashboard checks in CI.
2. **The shader weekend spike** — grey boxes, outlines and boil only. Explicit fallback to flat quantised shading if it is not ~70% convincing (ADR-062).
3. **The M1 networking spike** — 4 peers, ~150 synchronised entities. Go/no-go on the engine (`TEC-004`).

Then M1 proper, whose only job is: **two people who aren't you play for ten minutes and ask to keep playing.**
