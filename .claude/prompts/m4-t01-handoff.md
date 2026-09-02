# `M4-T01` handoff — the Delvings, from here

You are picking up **Project SHE** mid-task. Read `CLAUDE.md` first; it is the
working agreement and this brief does not repeat it. Then read this, then start.

**Do not re-derive the state of the world from the code.** Everything below is
measured, and the numbers are in the ADRs with the commands that produced them.

---

## Where you are

`M4-T01` — *the Delvings: full generation from room modules, 3 floors* — is
in progress and roughly two thirds done. `DES-015`'s pipeline runs end to end
and **a generated floor is now a level you can stand in**.

Prove it to yourself before you touch anything:

```bash
gh run list --workflow=CI --limit 3          # ADR-104: read CI first, every session
godot --path game levels/room_set/room_set.tscn -- --delvings --seed=31346 --floor=2
```

The last eight commits are ADR-176 through ADR-183. Read
`docs/process/PRO-002-decision-log.md` from ADR-176 down — that is the session
you are continuing, and about half of it is *"the check was wrong, not the
code"*, which is the part worth internalising.

### What exists and is asserted

| | |
|---|---|
| `MissionGraph` | five cycle types, seeded, determinism asserted both ways |
| `FloorPlan` | rooms on a lattice, corridors routed, dog-legs, crawl placement rule |
| `FloorBuilder` | geometry: rooms, corridors, ramped crossings, ledges, alcoves, the worked-stone-to-cave gradient |
| `FloorAnchors` | where the party, Shaft, Prize, Hunt, posts, lights and loot go |
| `FloorSource` | the seam: `AuthoredFloor` (the Deep) and `DelvingsFloor` (generated) |

Verified by `--graph-probe`, `--plan-probe`, `--build-probe` and
`--delvings-probe`, all in `tools/check_scripts.sh`. Current numbers on the
probed floors: 360 planned floors 0 invalid · 0 rooms off the navmesh · 0 slabs
isolated · every ledge reachable · 0 rooms behind a crawl · 764 nodes, 30 door
lights, a Shaft, a Hunter, 5 items, 5 enemies on a booted generated floor.

---

## What to do next

**The multi-floor run.** It is the top row of `docs/OPEN-QUESTIONS.md` and it is
what everything else is now waiting on.

`DES-015` is a **three-floor expedition** and nothing descends between the
floors. Concretely:

- `Threshold._descend()` loads `room_set.tscn` **without** `--delvings`, so the
  generated floor is reachable by flag and not by playing.
- The floor index comes from `--floor=N`. The obvious source, `GameState.descents`,
  counts a *lineage's* descents rather than depth into this expedition — reading
  it would roll floor 47 on somebody's forty-eighth run (ADR-183 Decision 3).
- `RunFile` deliberately holds no floor (`TEC-003`, and its own note says why).

So the work is: **decide where a run's floor index lives, carry a party from one
floor to the next, and point the descent at the Delvings.** That last part is one
line and must not land before the other two, or depth becomes a lie.

Design reading before you propose anything: `DES-015` (the expedition),
`DES-005` (the Shaft and the Sealing — *"the Sealing can lock a Shaft"* needs a
floor beneath the one you are on, which is why it was parked here),
`DES-017` (the Hunt persisting across a floor), `TEC-003` (save/run state).

### After that, in rough order

- `M4-T16` **enemy behaviour** — and note the open question filed against it:
  posts derive from held rooms, but only two of the five cycle types hold a span,
  so **145 floors of 360 carry no standing danger** beyond the Hunt. Either posts
  derive from something richer, or the catalogue guarantees a held arm. Measured,
  not guessed (ADR-181).
- `M4-T17` **item taxonomy** — `DelvingsFloor.filler()` currently deals the
  14-item corpus by `tribute_value`. That is one function to replace when real
  loot tables exist; nothing above it changes.
- **A ⟨tune⟩ pass, but only after somebody walks a floor.** `LEDGE_HEIGHT`,
  `LEDGE_FOOT`, `DOGLEG_RUN`, `LATTICE`, `CHAMFER`, `CELL` — every one is
  unfelt. `TEC-008`'s own open questions say the first thing to check is whether
  a 2 m corridor reads as tight, and tightness is what makes the Hunt work.

---

## How this codebase expects you to work

`CLAUDE.md` has the rules. These are the ones this task keeps teaching, at cost:

**Measure before you build, and measure before you believe.** The dog-leg was
built because 65% of corridors ran dead straight with an 18 m median sightline —
measured first, because the alternative was building a device for a problem the
floors might not have had. Conversely: `LATTICE` was 12 for weeks because nobody
had asked what fraction of a floor was corridor. It was 56%.

**An assertion built from a convenient existing value measures that value, not
the property.** This has now happened eleven times in `M4-T01`. `TEC-007` §1
carries the three rules it cost:

1. Never let a decision depend on the order a collection was built in.
2. Assert the *size* of the population you are measuring, not only the property.
3. Wait for the thing you are about to measure, not for something that arrives
   near it.

**Plant every row before you trust it.** A check that has never failed has never
been tested. Several rows in this task passed green against deliberately broken
builds until they were planted — including one that reported *"8 floor slabs
across 8 floors"* for floors carrying 1500.

**The check can be wrong instead of the code, and usually looks right when it
is.** Three examples from this session, all of which read as sensible:
- *"% of corridors that run dead straight"* is a function of corridor **length**;
  when corridors got shorter it went 13% → 61% and would have failed a floor that
  had just improved.
- *"is the entrance room big enough for four players"* is a proxy that encodes the
  layout it is checking. Measuring the spawn points that come **out** found 103
  bad floors of 360.
- *"every floor has a held room"* was a promise the design never made — only two
  of five cycle types hold a span. It would have failed 40% of a healthy corpus.

**The engine's documented limit is not the measured one.** `agent_max_slope` is
45°; ramps at ~39.5° do not bake. Both working ramps here are under 30°. Two
separate systems shipped broken on that assumption (ADR-180 Decision 5).

**A green local sweep and a green CI are different claims.** Run the full sweep
before every commit, push, and then *read* the CI result — ADR-104 exists because
the Godot job was red for fourteen commits and nobody looked. A `WARNING` is not
an `ERROR`, and the sweep greps for `^ERROR:`: that is how a navigation map
rasterising at the wrong cell size survived every check for months (ADR-183
Decision 4).

**Absent beats stubbed** (ADR-064). When something cannot be finished properly,
name it in the ADR and leave it out. The Threshold still opening onto the Deep is
that decision, made deliberately.

---

## Practical

- Full sweep before every commit — the exact sequence is in `CLAUDE.md` §4.
- `python3 tools/reindex.py` and `python3 tools/status.py --write` on any change
  touching `docs/` or task state. A stale dashboard is worse than none.
- After a push lands, republish the descent board (`CLAUDE.md` §4 has the two
  steps; the `PostToolUse` hook does the first half and prompts for the second).
- One commit per completed task or decision, subject carrying the task or ADR id
  and saying *why*.
- The probe corpus is 38 flags on `room_set.gd`. `--build-probe` and
  `--plan-probe` take a few minutes each; `--delvings-probe` is seconds.

Ask before reopening an accepted decision. Bring an opinion, cost it, and name
the shipped game you are borrowing from.
