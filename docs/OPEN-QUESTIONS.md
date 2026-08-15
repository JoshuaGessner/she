# Open Questions

Live queue of unresolved decisions. Resolved items move to `process/PRO-002-decision-log.md` as ADRs and are deleted from here.

**Priority:** 🔴 blocking · 🟡 needed soon · 🟢 can wait

> **2026-08-14 — bulk resolution pass.** Thirty-seven questions closed in one sweep (ADR-046 through ADR-050). Stale entries removed: Q13 (closed by ADR-033), Q37 (ADR-016), Q53 (DES-014 rewritten), Q67 (`PRO-005 §10`), and duplicate rows for Q23 and Q27.
>
> **Nothing blocks M1 or M2.** What remains is either genuinely deferrable, or a question only a build can answer.

---

## 🔴 Blocking

*None.* The design lock is clear.

## 🟡 Needed before M2

| # | Question | Doc | Recommendation |
|---|---|---|---|
| Q101 | How many nested hatch layers — 4, 5, or 6? | `ART-005` | Start at 4; add only if banding is visible |
| Q102 | Build an object-ID buffer, or live with missing coplanar edges? | `ART-005` | Try the ink-ID mitigation first |
| Q95 | Shared **modular kit grid** for architecture (2m? 4m?) | `ART-004` | Cell-based generation (ADR-014) strongly favours one |
| Q96 | First-person arms — universal, or per-class? | `ART-004` | Per-class is far better for identity and multiplies the most-viewed asset by six |
| Q36 | Godot high-level multiplayer at 4 peers × 150 entities | `TEC-004` | **M1 spike — go/no-go on the whole approach.** Not a design decision; a measurement |
| — | **TEC-006 data schemas** | *(unwritten)* | The `.tres` shapes for items, enemies, skills, contracts. Needed the moment M2 introduces loot |

## 🟢 Later

| # | Question | Doc |
|---|---|---|
| Q92 | Confirm FMOD indie licensing terms at adoption | `TEC-005` |
| Q93 | Do the three biomes share musical DNA? | `ART-003` — composer's call |
| Q18 | How much hand-written text per contract? | `DES-007` — settled in principle, needs a volume target |
| — | **DES-021 onboarding / the first hour** | `DES-010` names C1 as the largest churn point but does not design the answer. M4 work. *(DES-020 became Equipment & Slots.)* |
| Q105 | Off-hand swapping mid-run, or Lair-only? | `DES-020` — mid-run, slow, interruptible |
| Q106 | Is there a *no pack* option — tiny grid, near-silent? | `DES-020` — almost free, great for a stealth run |
| Q107 | Do class Rites change your bare arms over time? | `DES-020` — cheap mesh swap, non-numeric progression |
| — | **Localization plan** | Cheap now, painful later; procedural contract text complicates string handling |
| — | **Item & weapon taxonomy** | `DES-008` has philosophy, `DES-009` has feel, nothing has the list |

---

## Prototype questions — answerable only by playing

Recorded so they aren't mistaken for undesigned areas. Each has a documented lean; the build decides.

| Area | Question | Doc |
|---|---|---|
| Combat | Weight, commitment, and swing timing | `DES-009` |
| The Ear | Readability at a glance; does the ember read as *sick* when loud? (ADR-042) | `DES-019` |
| Inventory | Grid dimensions, cell sizes, rummage speed | `DES-019` |
| Pressure | Waystone drop rate — the primary lever on the whole system | `DES-005` |
| Audio | Crossfade length between states (ADR-043) | `ART-002` |
| Co-op | Per-capita extracted value at 1 / 2 / 4 players | `DES-012` |
| Hunter | Gold-bait cost curve; how long a bait buys | `DES-017` |
