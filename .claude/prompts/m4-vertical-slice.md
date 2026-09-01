# Agent brief — M4, the Vertical Slice: the Delvings, and everything that makes them a game

## 0. The job

**M4 is the most consequential milestone in this project so far**, and the reason
is not that it is the largest. It is the first milestone whose output is a thing
you can put in front of a person and learn whether the game is good. M0–M3 built
systems that are correct; M4 decides whether they are *worth playing*. Everything
before it can be justified as scaffolding. This cannot.

You are finishing M4 in Project SHE (`/Users/josh/dev/she`, Godot 4.7, GDScript).
Design is locked and 40 documents are `status: accepted`; you are implementing a
design, not inventing one. The bar is **beautiful and functional** — a floor that
is correct and dull has failed, and so has one that is lovely and soft-locks.

**Start with `M4-T01`, the Delvings generator.** It is the spine of the milestone:
`M4-T02` (enemies), `M4-T04` (contracts), `M4-T13` (the lantern) and both M4 gates
are all questions asked *about a floor*, and none of them can be answered honestly
against six grey rooms. It is also, in `DES-015`'s own costing, ⟨1–2 months to get
genuinely good⟩ and *"the single highest-leverage technical investment in the
project."* Treat that sentence as a scope warning and a mandate at once.

### The research mandate — this is not optional and it comes first

`DES-015` names its source (Dormans & Bakkes, *Generating Missions and Spaces for
Adaptable Play Experiences*, 2011) and stops there. **Before you write generator
code beyond what already exists, do a genuine literature and practice review** and
write it up. Specifically:

- **Cyclic dungeon generation** as actually shipped — Unexplored is the canonical
  case; read what its developers have published about cyclic rewrite rules, and be
  precise about what a "cycle" buys that a tree does not.
- **Modern procedural level generation practice** — graph rewriting, wave function
  collapse, constraint solving / answer set programming, handmade-module stitching
  (Spelunky's room templates, Enter the Gungeon, Hades' room graph). For each: what
  it is good at, what it costs, and **whether our constraints admit it**.
- **The determinism constraint rules some of these out.** `TEC-004` requires
  bit-exact generation across machines from a seed. Any technique whose reference
  implementation depends on hash-map iteration order, floating-point accumulation
  order, or a solver with nondeterministic tie-breaking is a trap. Say so
  explicitly in the review rather than discovering it in a desync.
- **Godot 4.7 specifics** — what the engine gives you (`AStar3D`, `NavigationMesh`
  baking at runtime, `SurfaceTool`, multimesh) and what it charges for it. The
  generation budget is **under 2 seconds** (`TEC-001`).

Deliver that review as a new `TEC-###` document (frontmatter, ID, the usual), with
a **recommendation and a rejected-alternatives section**. Then an ADR adopting it.
This project's whole method is that the reasoning survives in the repo; a
generator whose approach was chosen in a chat window is a generator nobody can
argue with later.

**Do not skip this because a generator already partly exists.** What exists is one
deliberately minimal stage (§3). If the review concludes the current approach is
wrong, saying so is a good outcome and cheap right now — it will not be cheap
after steps 4–7 are built on top of it.

---

## 1. Read first

- `CLAUDE.md` — all of it. Especially §2 (the tie-breaker principles, in order),
  §3 (documentation discipline), §4 (technical standards and *when to commit*),
  and §8 (the two tests that settle most arguments).
- `docs/design/DES-015-level-generation.md` — **the specification for this task.**
  The eight-step pipeline, the four layers, the vista rule, verticality (ADR-014),
  three floors and earned exits (ADR-015).
- `docs/design/DES-005-extraction-pressure.md` — what a floor is *for*. The Shaft,
  the stay-or-leave decision, the Sealing.
- `docs/design/DES-017-the-gold-sick.md` — the Hunt. `M4-T01` is the first point
  it can vary by floor and persist across one (ADR-037).
- `docs/design/DES-022-the-power-model.md` — the most misunderstood document here.
  Read it before you tune anything.
- `docs/process/PRO-002-decision-log.md`, ADR-165 through ADR-169 — the M4
  resequence, the three Hunt answers, the six art answers, and the generator
  decisions already taken.
- `docs/process/PRO-007` — the pre-mortem. The ways this project most plausibly
  fails. Re-read it at the *end* of M4 as well; several of its failure modes are
  M4-shaped.
- `game/systems/generation/mission_graph.gd` — what exists. Read the class header
  in full; it states the reasoning the next stage inherits.

---

## 2. Working rules (non-negotiable)

These are carried forward from `session-flow-sweep.md` because every one of them
was learned the expensive way.

- **`python3 -c` and python3 heredoc-on-stdin are blocked** by policy. Write the
  script to a file in the scratchpad, then run the file. Same for any multi-step
  edit: script it with an exact-match assertion (`text.count(old) == 1`), run it,
  delete it.
- **Read with `sed -n 'A,Bp'` / `cat`**, not the native `Read` tool, which
  misreports file lengths in this repo.
- `untyped_declaration=2`: an untyped declaration is a **hard parse error**. Every
  `var` and every parameter gets a type.
- **No stubs, no placeholders, no parallel fallbacks** (ADR-064). A half-built
  generation stage that returns plausible-looking output is the worst possible
  thing to put in this system, because everything downstream will look like it
  works. Absent, with a named `PRO-001` task, is the correct shape.
- **A check must never touch the player's `user://`** (ADR-145, ADR-152).
- **Every new assertion must be planted before it is believed.** Break the code
  the row is about, confirm *that row by name* fails, restore. A row that could
  have passed before your change is not a check. This has bitten the project five
  times now; the most recent is in §3.
- **New `class_name` scripts need `--headless --path game --import` once** before
  anything can reference them, or you get *"Could not find type X"*.
- Run the full sweep before every commit (`CLAUDE.md` §4). A failing check is a
  blocked commit. **On a machine under load, prefer waiting to re-running** —
  ADR-163 is the story of a load-sensitive check being misread as a product bug,
  and it cost a wrong ADR and a bogus task.

---

## 3. Where M4-T01 actually is — settled ground, do not re-derive

`M4-T01` is `[~]`. **Step 3 of the eight-step pipeline is built and nothing else.**

`game/systems/generation/mission_graph.gd` — `MissionGraph.build(run_seed,
floor_index)` produces nodes, edges and roles. No rooms, no metres, no meshes.
A spine of 5–7 nodes (growing 2 per floor of depth) with one or two alternate arms
rejoining it; the Prize inside the first arm's span, the Shaft beyond its rejoin.
`problems()` is `DES-015` step 8's graph half: reachability, the ADR-032 bypass,
cycle-or-tree, and whether anything is actually held.

**Three decisions are already taken (ADR-169) — inherit them, do not relitigate
without an ADR:**

1. **Topology before geometry.** The design risk is topological, it is assertable
   with no art, and it defers the `RoomModule` contract until the graph can state
   what it needs. That deferral is deliberate: **designing the resource first
   would have been a guess.** Defining it is your first coding job, and the graph
   is now in a position to tell you what it must carry.
2. **Determinism is asserted in both directions.** `check_determinism.py` has
   passed `--seed=` since `M1-T07` and *nothing read it* — the layout was six
   literal `AABB`s, so the harness was asserting that a constant is constant. It
   catches "the engine introduced variance"; it cannot catch a generator that
   **ignores its seed**, which is perfectly deterministic and useless. So
   `--graph-probe` asserts *same seed → same graph* **and** *different seed →
   different graph*. Keep both properties in every stage you add.
3. **The held-arm shape is load-bearing.** Danger confined to one branch is what
   makes "west long and safe, east short and held" — the hand-authored room set's
   own finding, and what ADR-032's bypass rule protects. Preserve it through
   placement; do not let step 4 quietly produce two equivalent routes.

**And the lesson from building it:** the first generator emitted **82 distinct
topologies from 400 seeds**. The check caught it, and the correct response was to
widen the generator, not the tolerance. Expect that pattern to recur at every
stage — variety is a property you assert, not one you assume.

---

## 4. What remains in M4-T01

Steps 4–7 of `DES-015`'s pipeline, plus the harness wiring:

| step | what it is | notes |
|---|---|---|
| 4 | **space** — rooms and corridors embodying the graph | ADR-014: 2D grid, vertical rooms. Needs the `RoomModule` resource. |
| 2 | **history bias** — Calamity, Prize, Claimant | `DES-015` Layer 2, *"nearly free"*, and it is what makes rooms mean something. Legibility rule: the Calamity is readable within **30 seconds of arriving**. |
| 5 | history-weighted props / room types by depth | |
| 6 | **machines** — authored situations stamped into valid sockets | Layer 3's rule: *every authored room type poses a question the player answers with an action.* "A room with loot in it" is not a machine. |
| 7 | **population** — loot, enemies, hazards, Clamor topology | The greed gradient is load-bearing: value must climb steeply with depth and the player must be able to **see** that. |
| 8 | validation, extended | Currently graph-only. Needs navmesh sanity and placement validation. **Re-roll the offending sub-graph, not the whole level.** |

**Wire `WorldHash` to consume the generated floor.** Until that happens
`check_determinism.py` still measures the hand-authored rooms, and the
cross-process guarantee `TEC-004` actually needs does not exist. This is the
single highest-value non-feature task in `M4-T01` and it should land early, not
last — it is what makes every later stage's determinism checkable for free.

**Data over code** (`CLAUDE.md` §4): room modules are `.tres` resources under
`game/data/`, following the `ItemResource` / `ClassResource` idiom. A designer
must be able to add a room without touching a script. `game/data/biomes/` exists
and is empty; that is where biome definitions belong.

---

## 5. The rest of M4, in the order ADR-165 set

**`M4·A` — Depth, at blockout fidelity. No art pass.**

`M4-T01` Delvings → `M4-T16` enemy behaviour → `M4-T02` ~6 archetypes + 2 hazards
→ `M4-T04` contracts tier 1–3 → `M4-T13` lantern and darkness → `M4-T14` the Scar
→ `M4-T03` two classes polished. `M4-T17` (item & weapon taxonomy) feeds T02/T03
and should land before them.

**`M4-T16` is the one the developer cares most about.** Reported from play: *"the
gameplay feels a little stale still and AI will have to be greatly worked on."*
Read ADR-166 before starting it — Q75, Q77 and Q80 were answered specifically to
feed it, and Q80 carries a **negative assertion** that is easy to miss: the mix
must reveal coursing-vs-sighted and coarse bearing, **and not distance, and not a
continuous value.** A probe that only checks the state is present would pass a
build that shipped a radar.

`M4-T16` also inherits a `DES-018` obligation from Q77: the Gullsjúkr's human
vocalisations need a **visual twin**, and it belongs in the behaviour task rather
than a later audio one, because the twin is a behaviour readout and not a
decoration.

**The gates that moved here (ADR-165)**, asked between `M4·A` and `M4·B`:

- **`GATE M4 COOP`** — a rank-8 player brings a rank-1 friend into a rank-8 floor;
  the newcomer is downed repeatedly and *still wants to go again*. Two machines,
  remote. This is the one gate ADR-159's *one machine, one running copy* cannot
  cover.
- **The rank comparison** — a rank-8 and a rank-1 player die at similar rates *for
  different reasons*. Solo-runnable. **Run it the day `M4-T02` lands**, not at
  `GATE M4 EXIT`: it is the check that says whether `DES-022`'s power model
  survives contact, and all of `M4·B` is painted on top of that answer.
- **The stranger session** — three testers × three runs, no coaching beyond the
  in-game control list, diagnostic overlay off. It has now moved twice, both times
  on the same argument: a first-time player is not a renewable resource. `M4-T01`
  is the first level worth spending one on. **Do not spend them earlier.**

**`M4·B` — Polish.** `M4-T05` art/audio/UI/ping → `M4-T06` settings and rebinding
→ `M4-T11` accessibility → `M4-T07` Steam → `M4-T08` ink shader → `M4-T09`
composer (**carries a precondition: confirm current FMOD indie terms before a
single bank enters the repo**) → `M4-T12` audio occlusion → `M4-T10` asset
production → `M4-T18` marketing plan and devlog → `M4-T15` join-in-progress.

Then `GATE M4 EXIT` (shippable-quality 25 minutes ⟨tune⟩, solo *and* 4-stack) and
`GATE M4 GREED` (a playtester voluntarily abandons loot to survive, then talks
about it unprompted).

---

## 6. Two known faults in the checks, deliberately left alone

Recorded in ADR-165 and **not fixed**, because adjusting a check while trying to
get past it is how a check stops meaning anything. Decide them on their own
merits, with the developer, on a day nothing depends on the answer:

- **`GATE M4 GREED` is invisible to `status.py`.** `GATE_RE` matches
  `(EXIT|COOP)` and nothing else, so the gate ADR-109 calls *"the whole game in
  one moment"* has never been parsed and could never block `M5`.
- **`question-open` over-counts.** Every row under `OPEN-QUESTIONS.md`'s *"Needed
  at M4 / M5"* heading is charged to M4 regardless of which milestone needs it.

---

## 7. What "beautiful and functional" has to mean here

Concretely, so it can be argued about:

- **Functional** is `DES-015` step 8 with teeth: no soft-lock, every exit
  reachable, the ADR-032 bypass real, the navmesh sane, generation under 2 s, and
  bit-exact across machines. All asserted, all planted.
- **Beautiful** is not the art pass — that is `M4·B`. At blockout fidelity it
  means: a floor **reads**. You can tell where you are, the Calamity is legible
  within 30 seconds, the vista rule is honoured (each floor contains a moment
  where you see something valuable and distant that you must work out how to
  reach), and the two arms of the cycle feel *different* rather than merely being
  different lengths.
- The test that settles arguments (`CLAUDE.md` §8): does this let the player do
  something **new**, or does it make an existing number **bigger**? A generator
  that produces larger floors with more enemies as depth increases has failed it.

---

## 8. Deliverables, in order

1. The **generator research review** as a `TEC-###` doc, with a recommendation and
   rejected alternatives, plus an ADR adopting it. Stop for sign-off before
   building on it.
2. `RoomModule` as a `.tres`-backed resource, and `DES-015` step 4.
3. `WorldHash` wired to the generated floor; `check_determinism.py` made
   meaningful across processes.
4. Steps 2, 5, 6, 7 and the extended step 8.
5. The rest of `M4·A` in the ADR-165 order.
6. Both mid-milestone gates run, with results recorded in `PRO-001`.
7. `M4·B`.

Per `CLAUDE.md` §4: **one commit per completed task or decision**, the full sweep
before each, the dashboard regenerated in the same commit as the checkbox, and the
descent board republished after every push that lands
(`tools/artifact.json` holds the URL; pass it, or you orphan the link).

---

## 9. Out of scope

- Re-opening design decisions in accepted documents without an ADR that says which
  one and why. Forty documents are accepted and 169 ADRs record the reasoning,
  including the alternatives already rejected. Read before you re-derive.
- Anything in `M5` or `M6`. The four remaining classes, the remaining biomes, and
  onboarding (`M5-T05`) are all deliberately not here.
- Switching engines, languages, or the networking model. `TEC-005` §"switching
  engines" and `TEC-004` are both explicit, and both were decided with measurement.
- Weakening a check to make a milestone move. §6 exists precisely so that
  temptation is a decision somebody takes on purpose, in daylight.
