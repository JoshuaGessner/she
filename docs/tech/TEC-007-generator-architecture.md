---
id: TEC-007
title: Generator Architecture
status: accepted
owner: tech
tags: [procgen, generation, determinism, godot, research, levels, cyclic]
updated: 2026-09-01
related: [DES-015, DES-005, DES-008, TEC-001, TEC-004, TEC-006, PRO-001]
---

# Generator Architecture

> **Accepted 2026-09-01 by ADR-170.** Changing anything here now requires a
> further ADR. The rejected alternatives in §9 are rejected *with reasons*; if
> one is reopened, the reason is what has to be argued with.

## 0. Why this document exists

`DES-015` adopts cyclic dungeon generation, cites Dormans & Bakkes (2011), and
stops. That was the right amount of detail for a design document and it is not
enough to build from. It names *what* to do and never says how the graph becomes
a space, which techniques were considered and discarded, or which of them our own
constraints quietly forbid.

`DES-015` also costs this work at ⟨1–2 months⟩ and calls it *"the single
highest-leverage technical investment in the project."* A month of work chosen in
a chat window is a month nobody can audit. So: the field, surveyed; the
constraints, applied; a recommendation; and the alternatives that were rejected
and why.

**One thing this review is not allowed to do:** re-open `DES-015` Layer 1. Cyclic
generation is accepted. What is open is *how* cycles are produced, and everything
downstream of the graph.

---

## 1. The constraints rule out more than the survey does

Working these first saves surveying things we cannot use.

| Constraint | Source | What it forbids |
|---|---|---|
| Bit-exact generation across machines from a seed | `TEC-004` §Determinism | Any technique whose reference implementation depends on float accumulation order, unstable sort, or solver tie-breaking |
| One RNG stream per pipeline stage, never shared render-side | `DES-015`, `TEC-004` | A single global RNG threaded through everything |
| Floor generation under 2 s | `TEC-001` §Budgets | Search that is unbounded, or that backtracks without a cap |
| Hand-authored room modules, procedurally assembled — *not* fully generated geometry | `TEC-001` §Procedural generation | Marching-cubes / fully synthesised geometry, and anything that makes authored modules impossible |
| Cells on one plane; verticality lives inside rooms | ADR-014 | 3D volumetric graph layout |
| Validation must be deterministic — a re-roll on one machine and not another is a desync | `DES-015` step 8 | Validation that consults anything non-deterministic |
| Data over code: a designer adds a room without touching a script | `CLAUDE.md` §4, `TEC-006` | A generator whose room vocabulary lives in GDScript constants |
| No stubs, no parallel fallbacks | ADR-064 | "If generation fails, fall back to the simple generator" |

The last row deserves emphasis because it is the most tempting mistake in this
whole task. A generator that falls back to a simpler algorithm when it fails is
two generators, one of which is never tested and both of which must stay
deterministic. **Bounded re-roll, then loud failure** is the only shape ADR-064
permits.

### The determinism constraint, stated precisely, from measurement

The current code's header comment says *"Nothing here iterates a `Dictionary`:
traversal order is not a promised invariant."* The conservatism is right and the
reason is wrong, which matters because the wrong reason protects against the
wrong thing.

Measured on Godot 4.7 (scratchpad probe, 64 keys, forward and reverse insertion):

```
[dict] forward-insert iterates in insertion order: true
[dict] reverse-insert iterates in insertion order: true
[dict] two dicts with same keys, different insert order, iterate alike: false
[rng]  same seed, 10000 draws identical: true
```

Godot's `Dictionary` is **insertion-ordered**, not hash-ordered. So a `Dictionary`
is not itself a source of nondeterminism. The real hazard is one step back:
**iteration order faithfully reproduces insertion order, and insertion order is a
function of call order.** Two machines that build the same dictionary by different
code paths get different iteration orders and neither hash tables nor sorting had
anything to do with it.

The rule that actually holds:

> **Never let a decision depend on the order a collection was built in.** Sort by
> an explicit total order — node id, grid coordinate, module id — immediately
> before any loop whose iteration order can change an outcome.

`RandomNumberGenerator` is PCG32 and integer-based; identical seeds give identical
integer sequences, which the same probe confirms over 10 000 draws. The danger is
never the RNG. It is what you do with the numbers afterwards.

---

## 2. The techniques, surveyed

### 2.1 Cyclic graph rewriting — Dormans & Bakkes

**What it is.** Joris Dormans, *Adventures in Level Design: Generating Missions
and Spaces for Action Adventure Games* (PCGames, 2010), and Dormans & Bakkes,
*Generating Missions and Spaces for Adaptable Play Experiences* (IEEE TCIAIG 3(3),
2011). The contribution is a **separation**: generate the *mission* — the graph of
tasks, locks, keys and goals, i.e. what the player does — with a graph grammar,
then generate the *space* with a second grammar constrained by the first. Shipped
in **Unexplored** (Ludomotion, 2017); Dormans has written and talked publicly
about the cyclic variant since.

The cyclic part is the later refinement and it is a claim about *how* the mission
graph is built. Rather than growing a tree and hoping loops appear, the generator
starts from a trivial graph and repeatedly applies **rewrite rules that insert a
named cycle**, then subdivides. The catalogue of cycle types is the actual design
content: a lock-and-key cycle, a foldback, a danger-and-detour cycle, a two-way
lock, a shortcut cycle.

**Determinism:** good, with one obligation. Graph rewriting is integer work on
node ids. The one place it can go wrong is **rule matching** — finding where a
rule applies enumerates candidate subgraphs, and if that enumeration follows
construction order rather than a sorted order, §1's hazard applies exactly.
Enumerate candidates sorted by node id and the whole technique is bit-exact.

**Cost:** the machinery is a week. The catalogue is the real cost and it is
ongoing design work, not engineering.

### 2.2 Trees, BSP, and room-and-corridor

**What it is.** Recursive subdivision (Diablo, most classic roguelikes) or random
room placement with corridor carving. Cheap, robust, thoroughly understood.

**Determinism:** excellent if implemented on integers. **With one specific trap:**
the widely-copied "TinyKeep" method separates overlapping rooms with physics-style
separation steering — iterative float displacement whose result depends on
accumulation order. That exact algorithm is a desync waiting to happen. The idea
survives; that implementation does not.

**Why it is not the topology answer:** it produces trees. `DES-015`'s entire
diagnosis of why Dark and Darker's dungeons feel flat is that the topology never
poses a question, and a tree cannot pose the one this game is built on. Rejected
for topology; **retained inside rooms**, where subdividing a 4×4-cell gallery into
readable sub-spaces is exactly what BSP is good at.

### 2.3 Wave Function Collapse

**What it is.** Maxim Gumin's WFC (2016), descended from Paul Merrell's model
synthesis (2007). Propagates local adjacency constraints across a grid, collapsing
the lowest-entropy cell and re-propagating. Shipped in Bad North, Caves of Qud,
Townscaper.

**What it is good at:** local coherence and texture. It makes a space look like it
was built by someone who had a consistent vocabulary.

**What it is bad at:** global constraints. WFC has no way to express *"the Prize
must be reachable without passing the held arm."* It is a local propagator;
reachability is a global property. The standard workaround is generate-and-test,
which multiplies cost by the retry count and puts you back in unbounded search
against a 2 s budget.

**Determinism:** achievable, not free. Reference implementations pick the
lowest-entropy cell with random tie-breaking over a float entropy value, and
frequently iterate an unordered container to find it. Made deterministic by
comparing integer entropy, imposing a total order on cells, and seeding the
selection — all doable, all easy to get subtly wrong.

**Verdict: not for topology.** Possibly interesting later for room *interior*
dressing, and per ADR-064 it should not be built until it has a job.

### 2.4 Constraint solving / Answer Set Programming

**What it is.** State the level's requirements as logical constraints and let a
solver produce a level satisfying them. Smith & Mateas, *Answer Set Programming
for Procedural Content Generation: A Design Space Approach* (IEEE TCIAIG, 2011),
is the canonical treatment.

**Why it is genuinely attractive:** it is the only technique here that makes
`DES-015` step 8 unnecessary, because the validity conditions *are* the generator.
No soft-lock is possible if "no soft-lock" is an axiom.

**Why it is rejected anyway, on two independent grounds:**

1. **Determinism.** ASP and SAT solvers tie-break by internal heuristics that are
   not part of any stability contract, and enumeration order can shift with
   solver version, options, or threading. This is precisely the trap the M4 brief
   named. Pinning a solver build makes it *reproducible* on identical binaries;
   it does not make it a promise, and `TEC-004` needs a promise.
2. **Cost and dependency.** There is no GDScript-native ASP solver. Adopting one
   means shipping a native dependency to four platforms, on a solo project, for a
   subsystem that has a working alternative.

**Rejected. Recorded because it is the strongest rejected alternative**, and if
determinism were ever relaxed it is the one to revisit first.

### 2.5 Handmade-module stitching, as actually shipped

Four shipped implementations, and they disagree in instructive ways.

| Game | Shape | What to take | What not to |
|---|---|---|---|
| **Spelunky** | 4×4 grid of authored templates; a guaranteed path carved top-to-bottom first, then rooms chosen per cell | **Path first, rooms second.** Guaranteeing solvability by construction rather than by validation is cheaper and never fails | The grid becomes visible after ~20 hours — the exact failure `DES-015` diagnoses in Dark and Darker |
| **Enter the Gungeon** | Authored rooms placed against a semantic flow graph specifying types and connections | Closest shipped analogue to what we want: a graph that says what a room is *for*, and modules that satisfy it | Its floors are trees with occasional loops; navigation is not the point of that game |
| **Hades** | Room-by-room selection from a weighted pool, with pacing rules over encounters and rewards | The pacing selector — value and threat as a *curve* over the run, not a per-room roll | **Hades is deliberately not cyclic.** Its run is a sequence with a door choice. That works because Hades has no navigation and no extraction; our context differs on both |
| **Brogue** | "Machines" — pre-authored *situations*, not geometry, stamped into generated space with their required components | Already adopted as `DES-015` Layer 3. The discipline that makes it work is that a machine poses a question | — |

The Spelunky lesson is the one with teeth here. **Guaranteeing a property by
construction beats validating for it**, and our graph already does this: `build()`
places the Shaft beyond the rejoin and the Prize inside the arm span, so
reachability and the ADR-032 bypass are true by construction. `problems()` then
checks them anyway. That belt-and-braces is correct and should be the pattern for
every later stage: construct so it cannot fail, assert that it did not.

---

## 3. What a cycle actually buys, precisely

The brief asks for precision here, because "cycles feel better" is not an argument
anyone can build against.

A cycle buys exactly one primitive: **two distinct routes between two nodes.**
Everything else is a consequence.

1. **Route choice can exist at all.** On a tree there is one path between any two
   rooms, so "which way" is never a question. This is the whole of `DES-005`'s
   stay-or-leave decision having a spatial half.
2. **The two routes can differ in kind.** Long-and-safe versus short-and-held is a
   *decision*; two routes of different length are a *calculation*. This is the
   hand-authored room set's own finding and it is what ADR-032's bypass rule
   protects.
3. **The walk out is not a retrace.** In a tree, extraction means re-walking the
   corridor you came down. A cycle lets the exit route be new ground, which is
   where `DES-005`'s climax lives — and it halves the "seen this already" cost of
   every authored module.
4. **A threat can come from in front.** On a tree a pursuer is always behind you.
   Cycles give the Hunt somewhere to come *from*, and give the player somewhere to
   go *around*.
5. **Optionality becomes real.** A key reachable without passing its lock is only
   possible with a second route. Without it, "optional" content is content you are
   funnelled through.
6. **It reads as authored.** Human designers reliably build loops; Dormans'
   argument, supported by analysis of Zelda dungeons, is that loop structure is a
   large part of what "hand-made" means to a player.

Point 2 is the one that generalises into an assertion, and it is the one the
current generator does not yet earn — see next.

---

## 4. The finding that matters: our cycle catalogue has one entry

The graph stage is live and healthy. Measured, this working tree, `--graph-probe`:

```
[graph] validity     1200 floor(s) built, 0 invalid
[graph] same seed    identical
[graph] seed matters 308 distinct graph(s) from 400 seeds
[graph] three floors 3 distinct
[graph] the loop     14 node(s), cycle=true, bypass=true, held=3
[graph] the prize    node 4, held=true
```

308 distinct graphs from 400 seeds is good *numeric* variety, and it is the number
the earlier widening was aimed at. **It is also measuring the wrong thing.**

`build()` is a fixed construction: a spine of 5–7 nodes growing 2 per floor, one
arm from `leave` to `rejoin`, the Prize on the spine inside that span, the Shaft
beyond the rejoin, plus zero or one further arms. Every one of those 308 graphs is
the same *kind* of floor with different numbers in it. The digest differs; the
shape does not. This is a property of the code, not a sampling artefact — there is
no branch in `build()` that can produce a second topology class.

That is precisely the failure `DES-015` diagnoses in Dark and Darker one level up
the stack: *the randomness is in the stuff, not the space.* We have moved it into
the space and stopped one step short. Twenty hours in, a player who has learned
"the Prize is on the loop, the Shaft is past where the loop closes" has learned
every floor this game will ever produce.

Dormans' actual contribution is not "put a loop in it." It is that **the type of
cycle is the design content**, and a catalogue of cycle types is what makes floors
differ in kind rather than in measurement.

**This is the review's central recommendation and the reason it was worth doing
before steps 4–7.** Building space, props, machines and population on top of a
single topology class would have produced a great deal of work whose variety
ceiling was fixed before any of it started.

---

## 5. Recommendation

**Adopt cyclic graph rewriting over a named cycle catalogue for topology; then
deterministic grid-based module placement with bounded backtracking for space;
then Brogue machines. Reject WFC and constraint solving for topology.**

Mapped onto `DES-015`'s eight steps:

| Step | Technique | Status |
|---|---|---|
| 1–2 | seed, expedition, rank; roll history | — |
| **3** | **Cycle-type catalogue applied by seeded graph rewriting** | Exists as a single hardcoded cycle; needs the catalogue (§4) |
| **4** | **Integer-grid module placement, seeded backtracking over a sorted candidate list, socket-compatibility driven** | To build. Needs `RoomModule` |
| 5 | History bias — depth-weighted prop/room tables | To build. Data, not code |
| 6 | Machines stamped into sockets (Brogue) | To build |
| 7 | Population against the greed gradient | To build |
| **8** | Construct-so-it-cannot-fail, then assert. **Bounded sub-graph re-roll, then loud failure** | Graph half exists; needs placement and navmesh halves |

### 5.1 The cycle catalogue — the first coding job in step 3

Five cycle types (six were proposed; ADR-171 cut one) is enough to change the
character of a floor, and each is a rewrite rule, not a special case in
`build()`:

- **Danger-and-detour** — the current shape. One arm held, one long and safe.
- **Lock-and-key** — the loop opens from the far side; you must go around before
  the short way exists.
- **Foldback** — the loop returns you to a node you have already been through, so
  the second traversal is of known ground under new pressure.
- ~~**Two-fronted**~~ — *cut by ADR-171.* Both arms held is either no bypass at
  all, which ADR-032 forbids, or it is `danger-detour` with something nastier on
  the quiet arm — which is `DES-015` step 7, population, not topology. The
  interesting version of "both ways are bad" is real and belongs there.
- **Shortcut** — the loop is closed by something you open at cost, which pays back
  only on the way out. The Dark Souls shortcut, made structural.
- **Nested** — a cycle inside an arm of a cycle. Rare, deep floors only.

Each names a question the floor asks. That is the same test `DES-015` Layer 3
applies to machines, applied one level up, and it keeps the catalogue from
becoming six ways to draw a loop.

### 5.2 `RoomModule`, and what the graph tells us it must carry

ADR-169 deferred this contract deliberately so it would not be a guess. The graph
is now in a position to state its requirements, and they are:

- **`id`** — `StringName`, the `ItemResource` idiom (`TEC-006`).
- **Footprint** — `Vector2i` in cells, so 2×3 and 4×4 galleries are expressible
  (`DES-015`'s anti-boxiness list).
- **Sockets** — edge positions where a connection can attach, per cell edge. This
  is what placement matches against, and it is why the graph had to come first: a
  node with three neighbours needs a module with three sockets.
- **Role compatibility** — which `MissionGraph.Role` values this module can serve.
- **Held-capable** — whether the module can carry the danger of a held arm.
  `DES-015`'s "west long and safe, east short and held" is a placement constraint,
  not a decoration.
- **Vista affordance** — whether this module can be a vista source or target.
  The vista rule is `DES-015`'s, it is a per-floor obligation, and a generator
  that cannot ask a module "can you see out of yourself" cannot honour it.
- **Volume profile** — crawlspace / hall / three-storey. ADR-014 puts verticality
  inside rooms, so it belongs on the module.
- **Depth weighting** — which floors this module is legal on, feeding step 5.

`.tres` under `game/data/rooms/`, following `ItemResource`. `game/data/biomes/`
exists and is empty; biome definitions go there and name their module sets.

### 5.3 The determinism rules, as enforceable statements

Each is written so a check could be built against it.

1. **Every decision affecting layout is integer or grid math.** Floats appear only
   in final transforms that nothing reads back.
2. **One `RandomNumberGenerator` per stage**, seeded from an explicit mix of run
   seed, floor index and stage id. No stage draws from another's stream.
3. **Sort before you iterate**, whenever iteration order can change an outcome.
   Per §1 the hazard is inherited insertion order, not hashing.
4. **Rewrite-rule candidate matching enumerates in sorted node-id order.**
5. **Navmesh baking never influences a generation decision, and never triggers a
   re-roll.** See §6 — this resolves a live contradiction in `DES-015`.
6. **Re-roll is bounded and seeded**: sub-seed derived as `mix(stage_seed,
   attempt)`, a hard attempt cap, and on exhaustion a loud failure. No fallback
   generator (ADR-064).
7. **Own the seed mix.** `MissionGraph` currently derives its stream with
   `hash("%d:%d:%d" % [...])`. Within one engine build this is stable and safe
   against desync, because every player in a session runs the same binary. It is
   not a contract *across* engine versions, which makes a logged seed from a bug
   report potentially unreproducible after a Godot upgrade — and `TEC-001` calls
   the run seed's shareability non-negotiable. Replacing `hash()` with a
   SplitMix64-style integer mix we own costs about an hour and removes the
   question permanently.

---

## 6. `DES-015` step 8 contains a contradiction, and this is the resolution

`DES-015` requires both of these:

- *"VALIDATE → … navmesh sane"*
- *"Validation runs on the host and must be deterministic too — a re-roll that
  happens on one machine and not another is a desync."*

Runtime navmesh baking is Recast, it is voxel-based, and Godot bakes it with
platform-dependent threading. It is not something to build a bit-exactness promise
on, and a re-roll triggered by a bake result on one machine and not another is the
exact desync the second bullet forbids.

**Resolution, and it costs nothing:** separate the two jobs the word "validate"
is doing.

- **Traversability is decided on the integer generation grid**, before any bake.
  This is deterministic, it is what may trigger a bounded re-roll, and it is what
  the host and every client agree on.
- **Navmesh sanity is a build-time assertion**, checked in the sweep and in CI
  over a seed corpus, failing the build. It never runs as a gameplay decision, so
  it cannot desync anything.

This keeps step 8's teeth and removes the contradiction. It is recorded here
rather than as a silent implementation choice because it narrows an accepted
document, which ADR-170 covers.

---

## 7. Godot 4.7: what the engine gives, and what it charges

| Facility | Use | Charge |
|---|---|---|
| `RandomNumberGenerator` | PCG32, integer, identical across platforms for a seed — measured | None. Use it everywhere; never `randf_range` for a layout decision |
| `AStar3D` / `AStarGrid2D` | Reachability and route-cost queries during validation | Deterministic on integer weights. `AStarGrid2D` fits ADR-014's planar grid better than `AStar3D` |
| `NavigationServer3D` runtime baking | Agent navigation after layout is final | Not a determinism substrate — see §6. Bake cost is the largest single item in the 2 s budget and needs measuring before step 4 lands |
| `SurfaceTool` / `ArrayMesh` | Assembling module geometry | Fine, but `TEC-001` already chose authored modules over generated geometry; this is for joins and caps, not rooms |
| `MultiMeshInstance3D` | Repeated props at population time | Large win for prop density; a floor's worth of rubble should be one draw call, not four hundred nodes |
| `GridMap` | Tempting for a cell grid | **Avoid as the source of truth.** It couples layout data to a scene node and makes the generator hard to test headlessly. Generate to plain data, instantiate scenes from it |

**Budget, measured.** The whole `--graph-probe` — 1200 floor graphs plus a
400-seed census — runs in about one second of wall clock *including engine boot*.
Step 3 is effectively free at floor scale. The entire 2 s budget is available to
steps 4–7 and the navmesh bake, and the bake is the item to measure first.

---

## 8. Cost

Against `DES-015`'s ⟨1–2 months⟩ for `M4-T01`:

| Work | Estimate |
|---|---|
| Cycle catalogue: rewrite machinery + six cycle types + variety assertions | ⟨1 week⟩ |
| `RoomModule` resource, a starter module set, the placement pass with bounded backtracking | ⟨2 weeks⟩ |
| History bias, machines, population (steps 5–7) | ⟨1–2 weeks⟩ |
| Extended validation, navmesh sanity in CI, `WorldHash` wiring | ⟨1 week⟩ |
| **Total** | **⟨5–6 weeks⟩**, inside the design document's own costing |

---

## 9. Rejected alternatives

| Rejected | Why |
|---|---|
| **Wave Function Collapse for topology** | Cannot express global reachability constraints; generate-and-test against a 2 s budget; determinism achievable but fiddly. Revisit only for room-interior dressing, and only when it has a job |
| **Answer Set Programming / constraint solving** | The strongest alternative. Solver tie-breaking is not a stability contract (`TEC-004`), and there is no GDScript-native solver — a native dependency on four platforms for a subsystem with a working alternative. First thing to revisit if determinism is ever relaxed |
| **BSP / tree generation for topology** | Produces trees. `DES-015`'s whole diagnosis is that a tree cannot pose the decision this game runs on. Retained *inside* rooms for sub-space division |
| **Physics-style room separation (TinyKeep method)** | Iterative float displacement, accumulation-order dependent. A desync waiting to happen |
| **Hades-style linear room sequence** | Works because Hades has no navigation and no extraction. Ours has both. Its *pacing selector* is worth stealing; its topology is not |
| **Fully generated geometry (marching cubes, etc.)** | `TEC-001` already chose authored modules: better readability, better art, far less tuning agony. Not reopened |
| **`GridMap` as the generator's data model** | Couples layout to a scene node; blocks headless testing, which is how every check in this project works |
| **A simpler fallback generator when generation fails** | ADR-064. Two generators, one untested, both needing determinism |

---

## 10. Findings recorded while doing this review

Two things surfaced that are not recommendations but are facts about the tree as
it stands.

1. **`--graph-probe` is not run by anything.** It exists in `room_set.gd`, ADR-169
   describes it as the check that asserts determinism in both directions, and
   `tools/check_scripts.sh` does not invoke it — nor does CI. Searched the whole
   repository: the string appears only in `room_set.gd`, a comment in
   `mission_graph.gd`, the M4 brief, and ADR-169 itself. It reads as alive to
   `check_dead.py` because `room_set.gd` calls its own handler, which is exactly
   the "does anything use it?" gap ADR-098 was written about. **ADR-169's central
   claim is currently true only when somebody runs the probe by hand.** Wiring it
   into the sweep is a small task and it belongs before any further generator work.
2. **The variety assertion measures digests, not shapes.** `[graph] seed matters`
   counts distinct fingerprints, which cannot distinguish 308 different floors from
   308 numberings of one floor (§4). When the cycle catalogue lands, the assertion
   needs a companion that counts distinct *cycle types* observed across the seed
   corpus, or it will keep passing while the catalogue is ignored.

The first is `M4-T19` in `PRO-001` — a task with an ID, not a quiet repair folded
into a change about something else. The second belongs to the catalogue work
inside `M4-T01`, because the assertion cannot be written before the thing it
counts exists.

---

## 11. What this obliges `M4-T01` to do next

In order, and each is a commit. **1–3 are done** (ADR-171):

1. ~~`M4-T19` — wire `--graph-probe` into `check_scripts.sh` and CI (§10.1).~~
   Done, every row planted.
2. ~~Own the seed mix (§5.3 rule 7).~~ Done — SplitMix64, pinned by a known answer.
3. ~~The cycle catalogue, with a variety assertion that counts cycle
   *types*.~~ Done — five types, 372 digests and 5 classes from 400 seeds.
4. ~~`RoomModule` as `.tres` (§5.2), then `DES-015` step 4.~~ Done (ADR-172) — 24 modules, 360 floors planned with 0 invalid, corpus coverage asserted.
5. `WorldHash` wired to the generated floor, so `check_determinism.py` becomes a
   cross-process guarantee rather than a check on six literal `AABB`s.
6. Steps 5–7, then extended step 8 with §6's split.

---

## Open questions

> **Q — How many cycle types before the catalogue is "enough"?** Five shipped
> (ADR-171), from the shape of the design, not from measurement. The honest answer arrives
> when a tester describes two floors as different kinds of place rather than as
> two floors. ⟨tune⟩

> **Q — What is the navmesh bake actually costing?** Named as the largest item in
> the 2 s budget on reasoning, not measurement. Must be measured before step 4
> lands, because if it is dominant the module set has a size constraint nobody has
> written down yet.
