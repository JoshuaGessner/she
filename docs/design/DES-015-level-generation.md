---
id: DES-015
title: Level Generation
status: accepted
owner: design
tags: [procgen, levels, narrative, generation, pacing, technical]
updated: 2026-08-14
related: [DES-005, DES-006, DES-013, DES-008, TEC-001, TEC-004]
---

# Level Generation

## Diagnosis first: why Dark and Darker's dungeons feel flat

Worth being precise, because the diagnosis dictates the fix.

1. **The topology never changes.** D&D uses *hand-authored fixed maps* with randomized contents. Twenty hours in, you know every room and every corner. The randomness is in the *stuff*, not the *space* — so exploration dies early and never comes back. This is the big one.
2. **Rooms have no reason to exist.** Most are "a room, with pots, and a skeleton." Nothing about a room poses a question. You can't remember a single one afterward.
3. **No narrative frame.** You enter, you take, you leave. There is no answer to "what is this place, and what happened here." The map is set dressing.
4. **The level is a container, not an antagonist.** Its pressure comes from other players and the timer — the architecture itself never threatens or helps you.

**Barony inverts 1 and 2** (genuinely procedural topology, and rooms that are *situations* because traps/items/monsters interact systemically) but is weak on 3 and 4, and its spaces are boxy and same-ish.

**Our target is all four.** Procedural topology + rooms as situations + a per-run narrative frame + architecture that participates in the Hunt.

---

## The thesis

> **The generator's job is not to produce a space. It is to produce a place where something specific happened, that you can read as you move through it.**

Every run should be answerable in one sentence — *"this is where the Dvergar sealed the lower halls and starved rather than open them"* — and the player should arrive at that sentence by **looking at the level**, not by reading a quest log.

This is what gives the player a reason to be here beyond loot, and it's the thing Dark and Darker never attempts.

---

## Layer 1 — Cyclic generation (the structural spine)

**Adopt cyclic dungeon generation** (Dormans & Bakkes, *Generating Missions and Spaces for Adaptable Play Experiences*, 2011; shipped in **Unexplored**, 2017).

Most procedural dungeons are **trees**: a branching structure with dead ends. Cyclic generation instead builds the level from **loops** — go out one way, come back another, with lock-and-key relationships along the ring.

**Why this is not optional for an extraction game:**

- **The walk out must not be a retrace.** In a tree, extraction means backtracking the corridor you came down — boring, and it means the Hunter just follows you along a line. In a cyclic layout the exit route can be *new ground*, which is where `DES-005`'s climax actually lives.
- **You can be cut off.** Loops give the Hunter somewhere to come *from*. On a tree it can only ever be behind you.
- **Loops give counter-play.** Go around. That's the whole Wing Aspect and the Veiðimaðr's fantasy made structural.
- **It reads as designed.** Cyclic layouts feel hand-made in a way tree layouts never do — that's the documented result from Unexplored, and it's the cheapest available fix for "procedural sludge."

**Cost:** this is a whole system. ⟨~1–2 months to get genuinely good⟩. It is also the single highest-leverage technical investment in the project after networking.

## Layer 2 — History bias (the narrative spine, and it's nearly free)

**Generate the history first, then generate the space to express it.**

Each expedition rolls three things before a single room is placed:

| Rolled | Examples |
|---|---|
| **The Calamity** — what happened here | The flood · the siege · the sickness · the betrayal · *the thing they dug up* — **and all of them trace back to her** (ADR-018) |
| **The Prize** — what's at the bottom worth having | A sealed vault · a king's barrow · a Bound crew's whole haul · the Calamity itself |
| **The Claimant** — who holds it now | Draugr · Dvergar remnant · Vættir · another Bound crew, six days ahead of you |

Then the payoff mechanism:

> **Moving inward is reading the disaster backward.**

- **Floor 1 — The Aftermath.** What was left. Failed barricades, the evacuation that didn't make it, scavengers picking over it now.
- **Floor 2 — The Retreat.** Where they fought and lost. Barricades facing the wrong way. The line breaking, room by room.
- **Floor 3 — The Cause.** The thing itself. Still here. Still doing whatever it did.

This maps exactly onto ADR-005's three floors, and mechanically it's **a weighted prop/room table keyed on depth** — ⟨a weekend⟩ once the room system exists. That's an absurd return on investment: systemic environmental storytelling for the price of a lookup table.

**Legibility rule:** the Calamity must be readable within **30 seconds of arriving**. You should be able to look at the entrance and know what killed this place.

### Every Calamity is hers (ADR-018)

> **The hoard is the disease.** Gold that passes through her becomes cursed, and every civilization in the Deep died of the same sickness in a different dialect.

The myth hands us this for free: Gullveig is *already* the figure who brought gold-lust into the world (ADR-007), burned three times for it and reborn every time. So the Calamity templates are not a grab-bag of unrelated disasters — they are **variations on one story**: *they came into her gold, and it unmade them.*

| Expedition | Their version of it |
|---|---|
| **The Delvings** | The Dvergar mined the seam her hoard grew from. Then they kept mining. |
| **The Barrow-Fields** | Kings buried with her gold. They will not stay dead, because the gold will not let them. |
| **The Sunken Wood** | The wood grew over a spill of it. It is alive now, and alive *wrong*. |

**Why this is worth the constraint:**

- Environmental storytelling **accumulates across a lineage** into a pattern the player assembles themselves. Individually each ruin is a tragedy; forty runs in, it's a *diagnosis*. That's the LINEAGE tier (`DES-003`) finally paying out something other than convenience.
- It produces the reframe the whole game is pointed at: **you are doing, right now, the exact thing that caused every disaster you are walking through.** The player is re-enacting the Calamity in miniature, every single run, on behalf of the thing that caused it.
- It gives Q27 (her arc) its shape. The ending question stops being "can she be saved" and becomes **"do you keep feeding it?"**

**The discipline this demands — and it is the whole thing:** the pattern must be **discoverable, never stated.** No NPC explains it. No codex entry spells it out. She certainly never admits it. If a character says "the gold is cursed, you know," the effect dies instantly and permanently. The evidence goes in the architecture, the grave-goods, the inscriptions, and the shape of how people died — and the player gets to be the one who says it out loud.

> **DECIDED (ADR-019):** **She knew, and has burned the memory out of herself — repeatedly.** The only version where her fondness and her lethality are both sincere, and it makes her forgetting mechanical rather than backstory (`DES-006`). *Original framing kept below for the reasoning.*
>
> ~~Does *she* know?~~ A wyrm who knows exactly what her gold does and asks for it anyway is a monster. One who doesn't is a tragedy. One who knew once and has burned the memory out of herself is both, and is the most interesting — but it's the hardest to write without stating it. Affects every line she has.

## Layer 3 — Machines (rooms that pose questions)

Borrowed from **Brogue**, whose "machines" are pre-authored *situations* — not geometry — stamped procedurally into generated space.

**Rule: every authored room type poses a question the player answers with an action.** "A room with loot in it" is not a machine.

| Machine | The question |
|---|---|
| **Guardian & Prize** | A Draugr on a hoard that will never come to you. *Do you want it?* |
| **The Choice** | Two prizes, one exit, taking either seals the other |
| **The Bad Room** | A previous crew died here. Their gear is still on the floor. So is what killed them |
| **The Witness** | No combat. Something that tells you what happened here — the Calamity, made explicit |
| **The Shortcut** | Costs something to open now; saves the entire walk out later |
| **The Wrong Barricade** | Built to keep something *in*. It failed. |

Machines are the authored content budget — ⟨~a day each⟩ — and unlike hand-built maps they compose with the generator instead of replacing it.

## Layer 4 — Population

Loot and enemies placed against the rules already established: greed gradient (`DES-008`), avoidable encounters (`DES-013`, Q40), Clamor topology, and extraction-point placement (`DES-005`).

**The greed gradient is the load-bearing part:** value must climb steeply with depth, and the player must be able to *see* that from floor 1. The Prize being visible-but-distant from early in the expedition is what pulls people down (`PRO-005 §1`).

---

## Generation pipeline

```
1. seed + expedition + party rank (ADR-010)
2. roll history       → Calamity, Prize, Claimant
3. mission graph      → cyclic lock/key structure, entrance, Prize node, exits
4. space              → rooms + corridors embodying the graph
5. history bias       → props/room types weighted by floor depth
6. machines           → stamp authored situations into valid sockets
7. population         → loot, enemies, hazards, Clamor topology
8. VALIDATE           → exits reachable · Prize reachable · no soft-lock
                      · a bypass route to an exit exists (ADR-032) · navmesh sane
```

**Step 8 is not optional.** A generator without a validation pass ships soft-locks. Failing validation should re-roll the offending sub-graph, not the whole level.

## Technical constraints (`TEC-004`)

- **Bit-exact determinism across machines.** Host sends the seed; clients build the identical floor. Geometry is never replicated. This is already a hard requirement and level gen is where it will actually break.
- One RNG stream per pipeline stage, never shared with anything render-side.
- Generation budget: **under 2 seconds** (`TEC-001`).
- Validation runs on the host and must be deterministic too — a re-roll that happens on one machine and not another is a desync.

## Open questions

> **DECIDED (ADR-050):** **Yes, sparingly — one per expedition, at floor 3**, where the Deep Gate and the Cause already sit.

> **DECIDED (ADR-050):** **No at 1.0.** Mid-run geometry mutation makes the late-join world delta unbounded (`TEC-004`, ADR-016). The Sealing already supplies escalation. Revisit post-launch.

> **DECIDED — Waystone economy.** **No stacking, not tributable, hard cap of one**, so *"do I still have my out?"* stays a binary question answerable at a glance. Drop rate remains the primary tuning number ⟨tune⟩ and the strongest single lever on the whole pressure system.
>
> ~~Original:~~ Drop rate is the primary tuning lever on the entire pressure system ⟨tune⟩. Too common and pressure evaporates; too rare and every run is forced to floor 3. Do Waystones stack? Can they be tributed? Can you carry two? Leaning **no stacking, not tributable, hard cap of one** — so it is always a binary "do I still have my out?"

---

## Resolved

### Verticality — 2D grid, vertical rooms (ADR-014, closes Q48)

Cells are laid out on **one plane**. Verticality lives **inside** rooms.

That keeps navmesh, AI traversal, and the Clamor field tractable — but it creates an explicit obligation: **"2D grid" must never read as "boxes and corridors."** The generator earns openness through:

- **Variable footprints.** Rooms span 2×3 or 4×4 cells, not one. Merged cells become galleries.
- **Height variation as a first-class axis.** A cell's *volume* is generated even though its *position* is planar — crushed crawlspaces, three-story halls, mezzanines.
- **Sightlines across cell boundaries.** The single highest-value technique: standing on a balcony and *seeing* the great hall four cells away. Openness is perceived through the eye, not the navmesh.
- **Visual-only vertical negative space.** Shafts and chasms you can look down into and *see the next floor*, while traversal still happens via stairs. This is how Dark and Darker gets its vertical feel cheaply, and it is the correct trick to steal.
- **Non-orthogonal interiors.** Diagonal walls, collapsed masonry, curved Dvergar architecture. The grid is a generation substrate, never a visible constraint.
- **In-room traversal:** ledges, chains, mine lifts, collapsing floors that drop you a level *within* a room.

**The vista rule:** each floor should contain at least one moment where the player can see something valuable and distant that they must route toward. That's the greed gradient (`DES-008`) delivered through architecture — you *see* the Prize before you can reach it.

### Run structure — three floors, earned exits (ADR-015, closes Q49)

A run is the full expedition. Extraction on floors 1–2 requires a **Waystone** (rare, found, consumed) or **the Shaft** (fixed, known, dangerous, seals as the Hunt escalates). Floor 3 holds the **Deep Gate**. Full treatment in `DES-005`.

**Generation consequence:** every floor needs exactly one Shaft placed at a *deliberately inconvenient* node in the cyclic graph — reachable, never near the entrance. Floor 3 must place the Deep Gate and the Cause in tension with each other: the way out and the reason you came should not be the same room, but they should be able to see each other.

### Map — drawn as you go, Lineage annotates (ADR-017, closes Q50)

Coverage comes from exploring. **Lineage adds annotation, not area.** A veteran's map is smarter, not bigger: hazard marks, Shaft locations, likely vault positions, *a Bound died here*. Needs a legibility pass — an over-annotated map is noise.
