# Open Questions

Live queue of unresolved decisions. Resolved items move to `process/PRO-002-decision-log.md` as ADRs and are deleted from here.

**Priority:** 🔴 blocking · 🟡 needed soon · 🟢 can wait

**Recently resolved:** ADR-038 (Gullsjúkr identity reuses the existing death record — **closes Q74**) · ADR-039 (**closes Q76/Q78/Q79**) · ADR-033 (title is SHE — **closes Q13**) · ADR-034 (solo, no timeline) · ADR-035 (Clamor via adaptive score, not alarms) · ADR-036 (every audio channel has a visual twin) · ADR-037 (the Hunter is the Gullsjúkr — **resolves Q9**) · ADR-029 (Tithe per 3-run cycle — **closes Q2**) · ADR-030 (Boon ~70% tribute + contracts — **closes Q5**) · ADR-031 (Skald acts on the dungeon — **closes Q32**) · ADR-032 (bypass route guaranteed to an exit — **closes Q40**) · Q54 (Waystone: no stacking, not tributable, cap of one) · ADR-028 (saving a Bound: rare, costly, non-fungible rewards — **closes Q73**) · ADR-026 (premium only, no MTX — **closes Q63/Q64/Q65**) · ADR-027 (Bound: authored person, simulated life — **closes Q68**) · Q67 (gambling vendor: yes, with guardrails in `PRO-005 §10`) · ADR-021–025 · ADR-014 (2D grid, in-room verticality — **closes Q48**) · ADR-015 (3 floors, earned exfil — **closes Q49, Q8**) · ADR-016 (join-in-progress via Lair passage — **closes Q37**) · ADR-017 (Lineage-annotated drawn map — **closes Q50**) · ADR-018 (every Calamity is hers) · ADR-003 (Legacy: no raw Boon) · ADR-004 (stash wipes) · ADR-005 (3 expeditions × 3 floors) · ADR-006 (every run pays) · ADR-007 (She is original, female, Gullveig-derived) · ADR-008 (co-op core, 1–4p, from M1) · ADR-009 (six classes gating Aspect access — **closes Q4**) · ADR-010 (floors scale to highest rank — **closes Q33**) · ADR-011 (Boon capped by own rank) · ADR-012 (all six classes at start — **closes Q31**) · ADR-013 (co-op cost accepted, no scope cuts) · Q20 combat thesis · Q21 no health regen · Q22 no stat block · Q24 high lethality

---

## 🔴 Blocking design lock (M0)

| # | Question | Doc | Recommendation |
|---|---|---|---|
| Q56 | **Is refusal a mechanically supported ending?** ADR-018 makes the final question "do you keep feeding it?" — which implies *no* must be answerable | `PRO-005` | Deferred to its own conversation. Shapes her writing; gates no code |
| Q27 | **Her arc** — healed, freed, killed, or refused? Shaped but not settled by ADR-018 | `DES-006` | Answer alongside Q56 |

**Blocking design lock is otherwise clear.** M1–M3 can be built against the current docs.

## 🟡 Needed before M2

| # | Question | Doc | Recommendation |
|---|---|---|---|
| Q8 | Extraction points known at run start or discovered? | `DES-005` | One known, others discovered |
| Q23 | **Inventory model** — grid+weight vs weight-only. Doc leans grid+weight+real-time | `DES-019` | Prototype both at M2. Feel question; largest single UI item in the project |
| Q81 | Ear placement — reticle-adjacent or bottom-centre? | `DES-019` | Prototype question, not a document question |
| Q82 | Is there a compass / bearing reference? | `DES-019` | A diegetic compass item that occupies a slot |
| Q83 | Is the Tithe surfaced during a run, or Lair-only? | `DES-019` | Quietly, on the Burden layer — it's a greed readout |
| Q84 | Does the ping wheel double as the silent-gesture system? | `DES-019` | One system is cheaper and less to learn |
| Q10 | Quit mid-run — death, suspend, or forfeit? | `TEC-003` | Suspend with forced resume (B); co-op complicates this |
| Q11 | Do player caches survive death? | `TEC-003` | No (LIFE tier); a Legacy slot may hold cache locations |
| Q12 | Do other players' echoes drop their real lost loot? | `DES-002` | Start local-only (your own corpses) |
| Q23 | Inventory model — grid + weight, or weight only? | `DES-009` | Prototype both at M2; feel question, not a paper question |
| Q25 | Magic — consumable runes only, or a baseline resource? | `DES-009` | Consumable-only baseline; Cinder adds Ember |
| Q26 | First-person only, or third-person option? | `DES-009` | First-person only — but co-op means character models are seen from outside |
| Q27 | Does She have an arc — healed, freed, killed, refused? | `DES-006` | Needs a *shape* now; it colours every line she speaks |
| Q34 | Solo self-recovery analogue to ember rescue | `DES-012` | Once per run, costly. Must not beat having friends |
| Q35 | Cross-progression solo ↔ co-op — one pact? | `DES-012` | Yes, one pact regardless of party |
| Q36 | Godot high-level multiplayer at 4 peers × 150 entities | `TEC-004` | **M1 spike is go/no-go on the whole approach** |

## 🟢 Later

| # | Question | Doc |
|---|---|---|
| Q13 | Real title (needs trademark + handle search) | `PRO-004` |
| Q14 | Currency, or barter-and-tribute only? | `DES-008` |
| Q15 | Stash cap model — slots, weight, or per-category? | `DES-008` |
| Q16 | Faction standing — spendable or threshold? | `DES-007` |
| Q17 | Player character identity — nobody, lineage, or customizable? | `DES-006` |
| Q18 | How much hand-written text per contract? | `DES-007` |
| Q41 | Do enemies pick up dropped loot? | `DES-013` |
| Q42 | Stealth takedowns — reward or ladder-trivializer? | `DES-013` |
| Q43 | Respawns — none, or Hunt-only repopulation? | `DES-013` |
| Q44 | Is the Lair dynamic geometry or prop-swapped? | `DES-014` |
| Q66 | Does camp momentum loss remove **services** or only **warmth**? | `DES-014` |
| Q67 | **A gambling vendor?** On-theme, good sink, but a variable-ratio mechanic (`PRO-005 §10`) | `DES-014` |
| Q69 | Does the Lodge sell Waystones? Softens the pressure system | `DES-014` |
| Q70 | Are undiscovered deeds hinted at, or entirely secret? | `DES-016` |
| Q71 | Do rescue deeds record *who* you carried out? | `DES-016` |
| Q72 | Is camp plot space finite, forcing curation of trophies? | `DES-016` |
| Q61 | How long may a Vörðr linger before the wait/return choice is forced? | `DES-012` |
| Q62 | Vörðr utility budget — scouting range, marking, enemy unnerve ⟨tune⟩ | `DES-012` |
| Q45 | Does She visibly change across a lineage? (ties to Q27) | `DES-014` |
| Q46 | Player-to-player trading — gear yes, tribute no? | `DES-014` |
| Q47 | Memorial wall of the Bound who died today? | `DES-014` |
| Q51 | Authored set-piece floors punctuating generated ones? | `DES-015` |
| Q52 | Does the level itself change mid-run (flood, collapse)? | `DES-015` |
| Q53 | **The Lair deep-dive** — flagged for major expansion before coding | `DES-014` |
| Q30 | Bought asset kit vs. bespoke art | `ART-001` |
| Q37 | Join-in-progress | `DES-012` |
| Q38 | Two players of the same class in one party? | `DES-011` |
| Q39 | Class gender presentation — confirm all classes open to all | `DES-011` |
