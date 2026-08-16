# Open Questions

Live queue of unresolved decisions. Resolved items move to `process/PRO-002-decision-log.md` as ADRs and are deleted from here.

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

| # | Question | Doc | Lean |
|---|---|---|---|
| Q36 | Godot high-level multiplayer at 4 peers × ~150 entities | `TEC-004` | **A measurement, not a decision.** The M1 spike is go/no-go on the whole approach |
| Q103 | Runtime instance state — a lantern's fuel, a weapon's condition | `TEC-006` | Resources are shared in Godot; instance state needs a separate runtime object keyed by item instance ID. **Decide before the first stateful item** |
| Q104 | Localisation — raw strings or translation keys? | `TEC-006` | **Keys from the start.** Costs nothing now, painful to retrofit |

## Needed at M4 / M5

| # | Question | Doc |
|---|---|---|
| Q89 | Do the six classes have any audio identity beyond footsteps? | `ART-002` |
| Q90 | How does audio handle the Vörðr state? | `ART-002` |
| Q92 | Confirm FMOD indie licensing terms at adoption | `TEC-005` |
| Q93 | Do the three biomes share musical DNA, or separate voices? | `ART-003` — composer's call |
| Q97 | Does ink colour shift per biome, or only the accent? | `ART-005` |
| Q98 | Threshold-white → Deep-black: hard cut or gradient? | `ART-005` — leaning hard cut |
| Q75 | Does killing a Gullsjúkr leave a stave for your camp? | `DES-017` |
| Q77 | Does the Gullsjúkr ever vocalise? | `DES-017` — no words, human sounds |
| Q80 | How much Hunter state does the Ear reveal? | `DES-018` |
| — | **Onboarding / the first hour** — design work, produces a doc | `DES-010` C1 — scheduled as `M5-T05` |
| — | Item & weapon taxonomy | `DES-008` has philosophy, `DES-009` feel, nothing has the list |
| — | **A marketing plan** | Flagged by `PRO-007` as a genuine gap. Devlog starts when the shader works |

## Prototype questions — only a build answers these

Recorded so they are not mistaken for undesigned areas.

| Area | Question | Doc |
|---|---|---|
| Combat | Weight, commitment, swing timing; how lethal | `DES-009` |
| Shader | Does the ember read as *sick* when loud? | `DES-019`, ADR-042 |
| Shader | Hatch layer count (Q101); object-ID buffer needed? (Q102) | `ART-005` |
| Shader | Do player characters get heavier outlines? (Q99) | `ART-005` |
| Inventory | Grid dimensions, cell sizes, rummage speed | `DES-019` |
| Pressure | **Waystone drop rate** — the strongest single lever in the game | `DES-005` |
| Audio | Crossfade length between states | `ART-002`, ADR-043 |
| Co-op | Per-capita extracted value at 1 / 2 / 4 players | `DES-012` |
| Hunter | Gold-bait cost curve; how long a bait buys | `DES-017` |
| Art | First-person arms — universal or per-class? (Q96 answered; **proportions** are a feel question) | `ART-004` |
| Progression | **Self-reported growth across runs 11–25** | `DES-022` — the headline metric |
| Accessibility | **Q105 — "see your own sound": a polished, in-game version of the M1 debug clamor footprint.** The dev overlay draws the *shape* your noise actually makes, notched where walls muffle it (`M1-T04`). `DES-018`'s Ear reports **how loud** you are and **which bearing** heard you; it does not show **where your sound went**, which is the thing a hearing player gets for free and a deaf player currently cannot get at all. Worth prototyping as a toggle: does the footprint read as information or as visual noise in a real room? **If it works it is a strong candidate for the audio twin ADR-036 demands**, and it is largely already built. Cost: the shape exists; the work is art direction and the readability test | `DES-018`, `DES-019`, ADR-036, ADR-073 |

---

## The first three things to build

Not questions. The answer to *"what now."*

1. ~~**Godot project skeleton**~~ — done (`M1-T08`). `TEC-002` layout, Forward+, typed GDScript enforced by the parser, the ≤6 autoload budget enforced in CI (ADR-066), doc-index and dashboard checks in CI.
2. **The shader weekend spike** — grey boxes, outlines and boil only. Explicit fallback to flat quantised shading if it is not ~70% convincing (ADR-062).
3. **The M1 networking spike** — 4 peers, ~150 synchronised entities. Go/no-go on the engine (`TEC-004`).

Then M1 proper, whose only job is: **two people who aren't you play for ten minutes and ask to keep playing.**
