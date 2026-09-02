---
id: TEC-008
title: Level Geometry & Spatial Legibility
status: accepted
owner: tech
tags: [levels, geometry, blockout, metrics, legibility, procgen, research]
updated: 2026-09-02
related: [DES-015, DES-009, DES-018, DES-006, TEC-001, TEC-007, ART-001]
---

# Level Geometry & Spatial Legibility

> **Accepted 2026-09-01 by ADR-175.** `TEC-007` covers *what the generator
> decides*; this covers *what that decision is built as*, and it is the document
> `FloorBuilder` implements. Changing it needs a further ADR.

## 0. Why this document exists

`M4-T01` can now generate a floor as data: a mission graph with a named cycle
type, rooms placed on a lattice, corridors routed between them, all
deterministic and asserted. Nothing builds it. `FloorPlan` produces integers.

Drawing ten of those floors as plans exposed the problem that geometry either
fixes or bakes in permanently: **they are legible as diagrams and
indistinguishable as places.** Every one is a scatter of rectangles joined by
one-cell corridors. The cycle type differs, the room modules differ, the
Calamity weights differ — and at the level of *what you would see standing in
it*, all ten are the same corridor.

That is not a generator failure. Topology cannot produce spatial character;
`DES-015` says as much when it insists *"2D grid" must never read as "boxes and
corridors."* Geometry is where that promise is kept or broken, so it is worth
being deliberate about before a `FloorBuilder` exists rather than after.

---

## 1. The metrics, derived from the player

Everything below is a multiple of the body. These are not chosen numbers; they
are what `game/data/tuning/default_tuning.tres` already says the player is.

| Quantity | Value | Source |
|---|---|---|
| Body radius | 0.35 m (0.7 m across) | `body_radius` |
| Standing height | 1.80 m | `stand_height` |
| Crouched height | 1.15 m | `crouch_height` |
| Eye height | 1.62 m | `stand_height − eye_drop` |
| Walk / sprint / crouch | 3.4 / 6.2 / 1.6 m s⁻¹ | tuning |
| Jump apex | **0.49 m** | `jump_velocity² ÷ 2·gravity` = 4.2² ÷ 36 |
| Sprint jump gap | **≈2.9 m** air distance | `2·v_jump ÷ gravity × sprint` |
| Field of view | 75° | `field_of_view` |

And the shipped conventions the hand-authored rooms already use, which
generated space must match or the two read as different games:

| Quantity | Value |
|---|---|
| Wall height | 4.0 m |
| Wall thickness | 0.6 m |
| Door width | 2.4 m |
| Authored room sizes | 6×6 m to 24×8 m |

### 1.1 The cell is 2.0 metres, and that is a derivation

`FloorPlan` works in unitless cells. One cell = **2.0 m** because it is the only
value that makes three independent things line up:

- A one-cell corridor is 2.0 m wide — **2.9 body-widths.** Two players pass
  without touching; one player plus a Draugr is a squeeze, which is the correct
  feeling in a corridor.
- The authored corpus lands on the authored scale: `prz_sealed_vault` (4×4
  cells) becomes 8×8 m against the hand-built guardian room's 10×10 m;
  `ent_stair_head` (3×3) becomes 6×6 m, exactly the built exit room.
- The largest module, 5×5 cells, is 10×10 m — a great hall, not a stadium.

Halving it makes corridors impassable; doubling it makes the smallest module a
20 m plaza. It is 2.0 m.

---

## 2. What the research actually gives us

### 2.1 Metrics-first construction — Valve, Source

Valve's level design practice derives every architectural dimension from the
player hull (32×32×72 units, 72 units being six feet), and sets door, corridor
and ceiling minimums as multiples of it. The transferable rule is not the
numbers — ours differ — but the discipline: **pick one base module from the body
and build everything as multiples of it**, so scale never drifts between
authors, or in our case between the generator and the hand-built rooms. §1.1 is
that module.

### 2.2 The five elements — Kevin Lynch, *The Image of the City* (1960)

Lynch's study of how people build mental maps of cities names five elements:
**paths** (routes travelled), **edges** (boundaries), **districts** (regions with
a shared character), **nodes** (junctions and destinations), and **landmarks**
(distant reference points). It is the standard framework for wayfinding in level
design, and it explains the floor sheet precisely.

**Our floors have paths and nodes. They have no edges, no districts, and no
landmarks** — which is exactly the list of things that would make one floor
memorable as a place rather than legible as a diagram. Everything in §3 is an
attempt to add the missing three cheaply.

This is the review's central finding, and it is worth stating plainly: the
generator's weakness is not variety. It is that a player has nothing to build a
mental map *out of*.

### 2.3 Prospect and refuge — Jay Appleton, *The Experience of Landscape* (1975)

Appleton's thesis is that people prefer places offering both **prospect** (a
view out) and **refuge** (cover to occupy). It is why balconies over halls,
alcoves off corridors, and elevated ledges read as good places to be, and it is
the mechanism underneath `DES-015`'s vista rule — *"you see the Prize before you
can reach it."* A vista is a prospect; the ledge you view it from is a refuge.

For an extraction game it is also tactical: prospect is where you decide, refuge
is where you wait for the Hunt to pass.

### 2.4 Mystery — Kaplan & Kaplan, *The Experience of Nature* (1989)

The Kaplans' preference matrix rates environments on coherence, complexity,
legibility and **mystery** — mystery being the promise of more information if
you move deeper: a passage bending out of sight, a partially occluded opening, a
light source with no visible origin.

This is the single most actionable idea in the whole review for a dungeon,
because it is *the opposite of a corridor with a room at each end.* A straight
2 m corridor between two rectangles has zero mystery: you can see the entire
proposition from the doorway. Every device in §3.3 is a way of buying mystery
with geometry rather than content.

### 2.5 Architectural patterns — Christopher Alexander et al., *A Pattern Language* (1977)

Four of Alexander's patterns transfer directly: **Alcoves** (small recesses off
a larger room give it usable edge), **Hierarchy of Open Space** (spaces should
grade from enclosed to open, not alternate randomly), **Zen View** (a
significant view is stronger when framed and glimpsed than when panoramic), and
**Light on Two Sides**. Zen View is `DES-015`'s vista rule arrived at from
architecture rather than from games.

### 2.6 Shipped level design worth stealing from

| Game | What it does | What we take |
|---|---|---|
| **Dark Souls** (FromSoftware, 2011) | Levels fold back on themselves; shortcuts unlock into already-known space; heavy vertical layering | Our `shortcut` and `foldback` cycle types *are* this. Geometry has to make the fold **visible** — you should see the place you'll come back to |
| **Thief: The Dark Project** (Looking Glass, 1998) | Light and shadow are the readable gameplay surface; darkness is legible, not just dark | The Delvings are lantern-lit (`M4-T13`). Geometry must give light something to fall on and something to hide — flat walls do neither |
| **Deep Rock Galactic** (Ghost Ship, 2020) | Procedural caves that read as caves: chambers and connective tunnels are *different shapes*, not the same tube at different widths | §3.2's three cross-sections |
| **Spelunky** (Mossmouth, 2008) | A guaranteed path carved first, rooms filled after | Already adopted structurally (`TEC-007` §2.5) |

### 2.7 What a cave actually looks like

Worth knowing, because "irregular" is not a design and produces noise. Real
cave passages come in recognisably different morphologies:

- **Phreatic** — formed underwater, under pressure. Rounded, tubular,
  roughly circular in section. Reads as *smooth, ancient, water-cut*.
- **Vadose** — cut by a stream under gravity. Tall and narrow, a canyon in
  section, often with a notch at the bottom. Reads as *deep, cramped, directional*.
- **Breakdown chamber** — where a ceiling has collapsed. Wide, angular, floored
  with fallen blocks, irregular polygonal plan. Reads as *unstable, open, recent*.

Three shapes, not one. A cave that uses all three reads as a cave; a cave that
uses one reads as a tunnel with the width randomised.

---

## 3. Recommendation

**Build the floor as a gradient from worked stone to raw cave, with three
distinct cross-sections and four devices that supply Lynch's missing elements.**

### 3.1 The gradient is the setting, not a style choice

`DES-015` Layer 2 reads the disaster backward as you descend — Aftermath,
Retreat, Cause — and ADR-018 says the Delvings' Calamity is *"the Dvergar mined
the seam her hoard grew from. Then they kept mining."*

That is a geometry instruction, and it costs nothing to honour:

| Floor | Reads as | Geometry |
|---|---|---|
| **1 — Aftermath** | Dvergar workings. Built. | Orthogonal, square corners, even 4.0 m ceilings, flat floors |
| **2 — Retreat** | Workings failing into the seam | Corners chamfered, ceilings varying ±1 m, floors stepping ⟨tune⟩ |
| **3 — Cause** | What they dug into | Heavy chamfer, ceiling range 2.4–7 m, floors stepping and sloping |

One parameter — call it *roughness*, 0 at floor 1 and 1 at floor 3 — drives
chamfer depth, ceiling variance and floor variance. The player descends and the
architecture stops being architecture. **The three floors of an expedition
become three places rather than three sizes**, which is the failure the floor
sheet exposed, fixed at its cause.

### 3.2 Three cross-sections, driven by the module's volume

`RoomModule` gains a `volume` field — deliberately withheld until now because
nothing read it (`TEC-007` §5.2, ADR-172 Decision 5). Geometry is its reader.

| Volume | Ceiling | Section | Feels like |
|---|---|---|---|
| `CRAWL` | 1.4 m | rounded, phreatic | crouch-only, water-cut, cannot fight here |
| `LOW` | 2.4 m | rectangular | worked passage, oppressive but standing |
| `HALL` | 4.0 m | rectangular, chamfered with depth | the shipped default |
| `GREAT` | 7.0 m | breakdown, angular | vista target, fight space, seen from elsewhere |

`CRAWL` at 1.4 m is chosen against the body: it clears the 1.15 m crouch with
headroom and refuses the 1.80 m stand. It is a **mechanical** space, not a
decorative one — you crouch, you slow to 1.6 m s⁻¹, your Clamor drops, and you
cannot swing. That is `DES-009`'s crouch verb given a room that demands it.

### 3.3 Four devices for the missing three elements

Each is generated, none needs art, and each buys one thing the floor sheet says
is missing. **Three of the four are built** (ADR-178): ledges, alcoves and the
depth gradient. Corridor dog-legs are a routing decision rather than a geometric
one and belong to `FloorPlan`.

1. **Ledges over halls — prospect/refuge, and Lynch's landmarks.** A `GREAT`
   room gets a walkable ledge at 2.5 m along one door-free wall, reached by **a
   ramp inside the room**. You see the hall floor before you are in it. This is
   the vista rule's delivery mechanism and ADR-014's *"verticality lives inside
   rooms"* made concrete.

   > **Amended by ADR-178.** This originally said *"reachable from an adjoining
   > corridor at that height"*, which makes a ledge conditional on a bridge
   > happening to arrive at deck height beside a great room — rare enough that
   > most great rooms would get none. An in-room ramp is unconditional.
   >
   > The ramp's foot must touch down a clear metre from the wall at the end of
   > the strip. Recast erodes the walkable surface by the agent radius from
   > every wall, so a foot that meets the floor *at* the wall leaves the deck an
   > island: measured, mesh from 2.5 m down to 0.7 m and none below it, on three
   > ledges of four.
2. **Corridor dog-legs — mystery.** A corridor of three cells or more bends at
   least once rather than running straight. Costs one cell of routing slack and
   removes the see-the-whole-proposition-from-the-doorway problem entirely.
3. **Alcoves — refuge, and edges.** Rooms of 3×3 cells or larger get one or two
   1-cell recesses in the wall. Cover to break line of sight, somewhere to wait
   out a patrol, and an irregular wall line so the room stops being a rectangle.
4. **Depth as district — Lynch's districts.** The gradient of §3.1 *is* the
   district system: the player can tell which floor they are on by looking at a
   wall. No signage, no map colour, no UI.

### 3.4 What blockout may and may not do

`DES-009` adopts Swink's ordering — **blockout must feel good unjuiced** — and
ADR-046 makes blockout a named production phase with scheduled replacement. So:

**In scope now:** volumes, ceilings, floors, walls, doorways, ledges, alcoves,
chamfers, the roughness gradient, collision. All structural, all generated.

**Not now:** textures, props, decals, light placement beyond what `M4-T13`
needs, any mesh that is decoration rather than collision. A cave that *reads* as
a cave in grey boxes will read as one when textured; the reverse is not true,
and the reverse is the expensive mistake.

---

## 4. Cost

| Work | Estimate |
|---|---|
| `RoomModule.volume`, the metrics, room and corridor shells with doorways | ⟨3–4 days⟩ |
| The roughness gradient and three cross-sections | ⟨2–3 days⟩ |
| Ledges, alcoves, dog-legs | ⟨3–4 days⟩ |
| Navmesh bake and `DES-015` step 8's navmesh half as a CI assertion (ADR-172) | ⟨2 days⟩ |
| **Total** | **⟨2 weeks⟩** |

---

## 5. Rejected alternatives

| Rejected | Why |
|---|---|
| **Marching cubes / SDF cave meshing** | Genuinely cave-shaped, and it throws away the authored-module decision `TEC-001` made on readability and art-cost grounds. It also makes collision and navmesh generation far more expensive, and `TEC-004` needs the result bit-exact |
| **Cellular-automata cave carving instead of rooms and corridors** | Produces caves that read as caves and destroys the mission graph — the held arm, the bypass and the Prize's position all stop being controllable, which is every guarantee `MissionGraph` exists to make |
| **Hand-authored 3D room prefabs per module** | Best-looking option and the correct one *later*. It costs a modelled scene per module per depth phase — 24 modules × 3 phases — before a single floor can be walked. The gradient in §3.1 gets 80% of it from one parameter |
| **Randomised wall jitter for "irregularity"** | Noise, not morphology. §2.7 is the argument: three named sections read as a cave, random offsets read as a bug |
| **Full vertical topology (multi-storey graphs)** | ADR-014 settled this: cells are planar, verticality lives inside rooms. Reopening it changes navmesh, AI traversal and the Clamor field at once |

---

## Open questions

> **Q — Is 2.0 m per cell right once a floor is walked?** Derived in §1.1 and
> not yet felt. The first thing to check when `FloorBuilder` lands: a 2 m
> corridor may read as generous rather than tight, and tightness is what makes
> the Hunt work (`DES-005`). ⟨tune⟩

> **Q — Does the roughness gradient survive three floors, or does floor 3 read
> as broken rather than natural?** Chamfer and variance are ⟨tune⟩ and the
> failure mode is a floor that looks like a bug rather than a cave.

> **Q — Do ledges break the Clamor field or enemy pathing?** `DES-013`'s AI is
> planar. A ledge is a navmesh island reachable only from a corridor; whether
> enemies use it correctly is `M4-T16`'s problem and should be checked there,
> not assumed here.
