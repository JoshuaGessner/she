# `M4-T13` — the lantern, and darkness as a mechanic

You are picking up **Project SHE**. Read `CLAUDE.md` first; it is the working
agreement and this brief does not repeat it. Then read this, then start.

**Do not re-derive the state of the world from the code.** Everything below was
measured, and the file references are current as of ADR-187.

---

## Read before you propose anything

| | |
|---|---|
| `ART-001` §"Darkness is a mechanic" | the rule this task exists to make true |
| `ART-005` | the ink shader — *"your lantern does not illuminate, **it draws**"* |
| `DES-020` | the off hand, and why one hand is the contested space |
| `DES-009` §"Light and dark" | light rides the **Clamor field**, not a second system |
| `DES-008`, `DES-019`, `DES-022` | the slot cost, the carried instruments, the growth channel |
| `DES-018` | a dark game still has to be playable by people who cannot see well |

`PRO-001`'s line for this task is the specification in one sentence:

> `ART-001` is explicit that light is a resource the player manages and that
> lighting design is gameplay design, and `DES-008` spends a weapon slot on it.
> **No task built it, in any milestone.** `M2-T13` lit the floor as far as it
> can be lit without one: the ambient floor stays navigable rather than truly
> dark, because a dark level with no light source is not a mechanic, it is a
> bug. **That ⟨tune⟩ number is the one this task exists to lower.**

---

## What already exists, measured

| | |
|---|---|
| `AMBIENT_ENERGY = 0.34` ⟨tune⟩ | [`room_set.gd:81`](../../game/levels/room_set/room_set.gd#L81) — its own comment says *"drops when the lantern lands"* |
| `_build_lighting()` | environment + a pale light in every doorway (`M2-T13`, ADR-105) |
| `Enums.Slot` | `NONE, MAIN_HAND, OFF_HAND, ARMS, HEAD, BODY, PACK` |
| `Equipment` | `equip` / `unequip` / `why_not` / `trait_in`; the off-hand contest is already documented in its header |
| `ClamorField` | host-only, per floor; `ClamorSource` per body. Two consumers already: enemies and the Gullsjúkr |
| `ItemTrait` | the composition seam — traits are how an item gains behaviour |
| 14 items | `wpn_ · arm_ · con_ · glt_ · mat_ · rlc_` prefixes. **There is no lantern** |

### The two facts that decide the shape of this task

**1. Enemy detection has no light term.** `Enemy._can_see()` is range, cone and
line-of-sight against world geometry — nothing else.
[`enemy.gd:403`](../../game/actors/enemies/enemy.gd#L403). So `DES-009`'s
*"carrying a lantern makes you visible"* is **not implemented anywhere**, and it
is the systemic half of this task. A lantern that only brightens pixels is a
graphics setting, not a mechanic.

**2. The ink shader is not built.** `M4-T08` is open, so `ART-005`'s *lantern
draws the world* look does not exist yet and you must not wait for it.
`CLAUDE.md`'s standing rule applies: **blockout must feel good unjuiced.** Build
the lantern so it is a good decision in flat grey light; the shader will later
make it beautiful, and if it is only good once the shader lands, it is not good.

---

## The decisions this task has to make

Bring an opinion on each, cost it, name the shipped game you are borrowing from,
and **write an ADR** — these change accepted documents.

### 1. Where light lives — and `DES-009` has already answered, so argue *against* it before you accept it

> *"Built on the same Clamor field the Hunt uses — one system, two consumers,
> which is the right kind of economy. Light matters as much as sound: carrying a
> lantern makes you visible, and darkness is a resource you spend by lighting
> it."*

That is a strong steer and it may still be wrong in the code: noise **decays and
propagates around corners**, light **travels in straight lines and is blocked by
them**. If you put both in one field you must say how one structure serves two
different physics, or you have conflated them for tidiness. The alternative — a
separate glow term read by the same `_can_see` — is more honest and costs a
second thing to keep in step. **Decide deliberately and record the rejected
option.**

### 2. Fuel, or no fuel

Nothing in any document says the lantern burns down. Adding fuel is the obvious
move (Darkest Dungeon's torch, Amnesia's tinderbox) and it is **a second clock
running beside the Hunt** — `DES-022` says power must cost *risk*, not time, and
`DES-005` deliberately has no hard timer. If you add fuel, justify it against
those two. If you do not, say what stops "lantern always on" from being the only
correct play — because that is the failure mode, and the answer is probably
Decision 3.

### 3. The verb that makes it interesting is turning it **off**

A lantern you can shutter is a decision every few seconds: *see, or be unseen.*
That is Principle 3 in one input, it needs no fuel economy, and it makes darkness
something you **use** rather than something you suffer. Weigh it against the
swap: ADR-057 already made off-hand swapping slow and interruptible precisely so
you cannot carry both a shield and a light and switch freely — a shutter must not
become a free swap by another name.

### 4. What light does *for* you, not just *to* you

If a lantern only raises your visibility it is a pure cost and nobody carries it.
It has to buy something legible: seeing an enemy's silhouette before it sees you,
reading a room, finding what is on the floor. `ART-001` wants enemies to read as
silhouettes at 20 m — say what that distance is with a lantern and without.

### 5. How dark is dark

`AMBIENT_ENERGY` drops, and there is a floor under it that is not zero. `M2-T13`
learned this the expensive way: a dark level with no light source is a bug, not a
mechanic. `DES-018` also gets a vote — a high-contrast mode and "no information
in hue alone" are accepted requirements, and "the player cannot see" is the one
accessibility failure a lighting task can ship. **Measure this with screenshots,
not with a number you like.**

### 6. Co-op, in one line

Four players and one lantern is a formation; four players and four lanterns is a
floodlight. `DES-012` cares. Decide whether light is shared, and whether the
party's brightest member is the one the floor reacts to.

---

## How this codebase expects you to work

These are the lessons `M4` keeps re-teaching, at cost. `TEC-007` §1 carries the
first three as rules.

**Measure before you build, and measure before you believe.** The dog-leg was
built because 65% of corridors ran dead straight — measured first. `LATTICE` sat
at 12 for weeks because nobody asked what fraction of a floor was corridor. It
was 56%.

**An assertion built from a convenient existing value measures that value, not
the property.** Never let a decision depend on the order a collection was built
in; assert the *size* of the population you are measuring, not only the property;
wait for the thing you are about to measure, not something that arrives near it.

**Plant every row before you trust it.** A check that has never failed has never
been tested. Rows in this milestone passed green against deliberately broken
builds until they were planted.

**The check can be wrong instead of the code, and usually looks right when it
is.** Three from `M4-T01`: *"% of corridors that run dead straight"* is a
function of corridor length; *"is the entrance room big enough for four"* encodes
the layout it is checking; *"every floor has a held room"* was a promise the
design never made.

**"Does it work?" and "does anything use it?" are different questions**
(ADR-098). A lantern that emits light nothing reads is the exact shape of that
bug — `keep()` filed to the stash for a whole milestone and nothing ever called
`withdraw()`. `tools/check_dead.py` checks *names*, not reachability. Probes are
what prove the game reaches its own code.

**Screenshots find what probes cannot, and this task is the one that proves it.**
Yesterday every probe was green while the Shaft's prompt read *"climb out"* on a
floor where it takes you **down** — caught in an image, not by a check (ADR-187).
This is a *lighting* task: a number can be right and the room still unreadable.
`--delvings-shot=PATH` already stands the body at real anchors and photographs
them; extend it rather than eyeballing the editor.

**A green local sweep and a green CI are different claims.** Read CI at the start
of the session (`gh run list --workflow=CI --limit 5`) and after every push. A
`WARNING` is not an `ERROR`, and the sweep greps for `^ERROR:` — that is how a
navigation map rasterising at the wrong cell size survived for months.

**Absent beats stubbed** (ADR-064). If part of this cannot be finished properly,
name it in the ADR and leave it out, with a task ID and a milestone.

---

## Definition of done

- The lantern is an **item** (`.tres`, data not code) with an `ItemTrait`, in the
  off hand, competing with the shield — and **`PRO-004` governs its name**. If
  you learned the word from Tolkien, do not use it.
- Something **reads** the light: enemy detection, the Hunt, or both. Prove the
  game reaches it with a probe, not with the existence of the code.
- `AMBIENT_ENERGY` is lower than 0.34 and the floor is still playable, with
  **screenshots at each candidate value** rather than an argued number.
- New probe rows in `tools/check_scripts.sh`, **every one planted and caught**.
- An ADR per decision above, `DES-008` / `DES-009` / `DES-020` / `ART-001`
  updated where they now say something new, `PRO-001` ticked.
- `python3 tools/reindex.py` and `python3 tools/status.py --write`, then the full
  sweep in `CLAUDE.md` §4, then push, then **read CI**, then republish the board.

## Practical

- The sweep takes **~45 minutes**. Start it early; poll a log file rather than
  blocking, and do not batch a milestone into one commit.
- One commit per completed task or decision, subject carrying the ID and saying
  *why*.
- `--delvings-shot=/tmp/x.png --delvings --seed=31346 --floor=N` for a first-person
  look. Seed 31346 builds cleanly at all three depths.
- Ask before reopening an accepted decision. The design is locked; changing it
  requires an ADR, and that is the mechanism that stopped this design drifting
  back into a stat ladder three separate times.
