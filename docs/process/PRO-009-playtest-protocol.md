---
id: PRO-009
title: Playtest Protocol — The Questions Only A Session Answers
status: proposed
owner: design
tags: [playtest, process, verification, open-questions]
updated: 2026-09-17
related: [PRO-001, DES-005, DES-009, DES-019, DES-022, ART-001]
---

# Playtest Protocol — The Questions Only A Session Answers

Twelve of the questions in `OPEN-QUESTIONS.md` cannot be closed by anyone
sitting at this desk. They are not undecided — each has a documented lean and a
costed alternative. They are **unobserved**. This is the script that observes
them.

> **Why a script rather than "play it and see."** A session with no script
> produces impressions, and an impression cannot close a question that a doc
> will later be changed on the strength of. Each block below names the thing to
> do, the thing to write down, and **what answer changes what**. A question
> whose answer would change nothing is not on this list.

---

## 1. What the session needs

| | |
|---|---|
| **People** | You, plus **2–3 others**. At least one who has not played before. |
| **Time** | One evening, ~2½ hours including setup and the talking afterwards. |
| **Build** | `python3 tools/export_build.py`, or run from the editor. Use the same build all night. |
| **Recording** | One notebook, or the table in §7. **Written during, not after.** |
| **Overlays** | `debug_overlays` **off** by default. Named blocks below turn it on. |

**The two rules that make the data worth having:**

1. **Do not coach.** Not "you can shutter the lantern", not "there's a Waystone
   in the guarded room". `GATE M4 STRANGER` passed on exactly this rule and it
   is the reason its result is trusted. The moment you explain a mechanic, every
   later observation about that mechanic is about *your explanation*.
2. **Write the sentence they said, not what you think they meant.** *"I didn't
   know I could leave"* and *"I didn't want to leave yet"* are opposite answers
   to `ADR-186`, and by the next morning they are the same memory.

---

## 2. Block 0 — Ten minutes, you alone, before anyone arrives

Two shader questions may already be answered by **ADR-248**, which built nested
world-space analytic hatching using pixel derivatives. They need your eye, not a
session.

| Q | What to do | What decides it |
|---|---|---|
| **Q101** — hatch layer count | Stand in a lit room, then a dark one, then a corridor at 20 m. Screenshot each. | Do the layers read as one material at all three distances? If yes, the count is settled and `ART-005`'s proposed texture implementation is superseded in fact as well as on paper. |
| **Q102** — object-ID buffer | Look at two overlapping hatched objects at a silhouette edge. | If the hatching does not swim or bleed across the seam, no ID buffer is needed and the question closes. |
| **Q99** — heavier player outlines | Stand a teammate at 15 m among two enemies. Screenshot. | Can you tell the player from the enemies by silhouette weight alone? **Untouched by ADR-248** — this one may still need work. |

---

## 3. Block A — Solo, 25 minutes each, no overlay

Everyone plays **one full solo run** — the `GATE M4 EXIT` shape. You are
watching four things at once; the questions are ordered by how early in a run
they show up.

### A1 · Inventory — cells and rummage speed
> `DES-019`, ADR-087. Grid is settled at 6×5. Open: whether **44 px cells** read
> at a glance, and whether **`bag_open_time` 0.35 s** feels vulnerable or merely slow.

- **Do:** nothing special. Watch when they open the bag and what they do next.
- **Write down:** the first time they open the bag **in a corridor with something
  audible nearby** — do they close it fast, or do they not register the risk?
- **Decides it:** *merely slow* → raise it and make the vulnerability real.
  *Vulnerable* → leave it. If they never open it under pressure at all, the
  number is not the problem and the question is really about the bag's prompt.

### A2 · Combat — weight, commitment, lethality
> `DES-009`. The oldest open question in the project.

- **Do:** ask afterwards, not during: *"describe the last thing that killed you."*
- **Write down:** whether the sentence is about **a decision** or **a reaction**.
  Principle 4 wants *"I took a fight I shouldn't have"*, not *"it hit me from
  behind"*.
- **Decides it:** three reaction-sentences out of four means swing timing is
  reading as twitch, and `DES-009`'s commitment window is wrong.

### A3 · Poise — the six numbers, and whether it is visible
> `DES-009`, ADR-194. Values live in `game/systems/enemies/enemy_resource.gd`
> (`poise` 100, `poise_regen` 18/s) and the weapons' `stagger`
> (seax 22, blade 40, spear 34, hammer 100).

- **Do:** make sure at least one person fights mostly with the **seax**. That is
  the thin one: 4 hits kill, 4 × 22 = 88 against a pool of 100, so a single miss
  turns a knife into a stagger-lock. The 12-point margin is the whole question.
- **Write down:** does anyone say anything resembling *"keep hitting"* or *"back
  off"*? Do they ever **stop attacking on purpose** to let poise regenerate?
- **Decides it:** if nobody ever makes a poise decision, poise is not felt, and
  the answer to *"should a player see poise"* is not a bar — it is that the
  **recovery punish** must be made more legible. `DES-019` rule 2 forbids numbers
  during a run and ADR-105 already tore out one readout for showing enemy
  internals; a bar is very likely the wrong answer even if the need is real.

### A4 · The lantern — six numbers and a noise
> `ART-001`, ADR-188. `shutter_seconds` 0.25 lives in
> `game/systems/items/light_trait.gd`; `enemy_vision_dark` 5.0,
> `exposure_ambient` 0.15 and `floor_ambient_energy` 0.12 in the tuning profile.

- **Do:** nothing. The shutter is either reached for or it is not.
- **Write down:** **count the shutter presses per run.** Then ask: *"what was
  the shutter for?"*
- **Decides it:** zero presses means going dark is not a live verb and the
  cooldown is the least of it. Many presses with no memory of why means it is
  being flickered — **0.25 s is too short**. This is also where *"does the
  shutter make a noise?"* gets decided: if going dark is already free and
  frequent, it needs a cost you can hear; if it is rare and deliberate, adding
  clamor would make a reflex into a flinch and Principle 3 says leave it silent.
  **`LightTrait` has no clamor field on purpose** — do not add one before this
  block runs.

---

## 4. Block B — Pressure and greed, solo, 25 minutes each

This is the block that feeds `GATE M4 GREED`, and it contains the single most
consequential open question in the project.

### B1 · Waystone drop rate, and whether one early exit is enough
> `DES-005`, ADR-186. *"The strongest single lever in the game."* The Shaft is
> the way **down**, so a Waystone is the **only** extraction above the bottom
> floor. The entire "can I leave?" question rests on one drop rate.
>
> **This block could not have been run before 2026-09-17.** ADR-251 found that
> the generator laid **no Waystone at all on 145 floors of 360** — on two floors
> in five there was no early exit of any kind, so any earlier session would have
> been measuring *that* rather than the drop rate. Fixed and asserted. It is now
> a fair question, and it is the first one worth asking.

- **Do:** play three runs each if there is time. Change nothing between them.
- **Write down, per run:** the floor they left on, **and whether leaving was
  chosen or forced**. Then the sentence: *"when did you first want to leave?"*
- **Decides it:** if people repeatedly reach floor 3 without ever having had the
  option, that is `DES-005`'s own warning — *"shoved to floor 3 every run whether
  they wanted it or not"* — landing, and ADR-186 is wrong in the way it is most
  likely to be wrong. The costed fixes are a higher drop rate (trivial) or a
  second exit kind (a week or more).

### B2 · Q112 — does a far glint that is usually a bead still pull?
> `DES-015`, `DES-002`, ADR-215. Every generated floor is guaranteed a glitter
> in view down a hall. On **23 floors of 24** that glitter is the gilt bead,
> worth 5.

- **Do:** watch for the walk. It happens in the first 60 seconds of a floor.
- **Write down:** on floor 1 they will walk to it. **Do they still walk to it on
  floor 3?** That is the entire question.
- **Decides it:** if the third-floor walk stops happening, the vista rule has
  taught the opposite lesson — *distant gold is junk* — and it is quietly
  deleting itself while every probe stays green. The fix is choosing the Prize
  room for its sightline in `FloorPlan` (a week or more) or dealing a dearer
  glitter at depth (a `GATE M4 GREED` economy question, cheap).

### B3 · The gold-bait cost curve
> `DES-017`, ADR-039/089. Proportional to carried value
> (`hunter_bait_fraction` 0.34) with an absolute floor, buying ⟨tune⟩ 4.5 s of
> Collecting.

- **Do:** this only comes up if someone is being hunted while carrying. If it
  does not happen naturally, do not force it.
- **Write down:** did anyone throw a bait? If so — *"was it worth it?"* If not,
  *"did you know you could?"*
- **Decides it:** 4.5 s is a window; the question is whether it is a window worth
  spending a torc on. A bait nobody throws is either priced wrong or not legible.

---

## 5. Block C — Co-op, the rest of the evening

### C1 · `GATE M4 COOP` — the rank-8 and the rank-1
> ADR-010. This is a **gate**, not an open question, and it is the reason to get
> people in a room.

- **Do:** you at high rank, a newcomer at rank 1, in your floor.
- **Write down:** how many times the newcomer goes down, and whether they **ask
  to go again**.
- **Decides it:** if they don't ask, the ember rescue is not doing enough work.

### C2 · Per-capita extracted value at 1 / 2 / 4
> `DES-012`. **This one I cannot close for you and neither can this session yet
> — see §6.** What you *can* do is bank the raw material: play the same seed at
> 2 and at 4 and write down what each person carried out. It is not the metric,
> but it is the only data that exists until the sink is built.

### C3 · Q110 — should a director reposition the Hunter?
> `DES-013`, `DES-005`, ADR-211. The want is stated plainly: *the Hunter should
> sometimes feel like it comes from all directions.* The reference is Alien:
> Isolation's director, which moves its alien only while the player cannot
> observe it.

- **Do:** play co-op with the Hunter active. **No build has ever posed this
  question** — the body only began fitting the floors on 2026-09-11.
- **Write down:** **how often does it lose you?** That is the number this whole
  question rests on. And: when it re-appears, does anyone say *"where did that
  come from"* in a good way or a cheated way?
- **Decides it:** if it loses you often and the re-approach is always from the
  same direction, relocation has a case. **What must survive is `DES-005`'s
  counter-play** — going quiet, breaking line of sight, putting a door between
  you — all of which assume a pursuer bound by the floor you are on. Any
  relocation must be unobservable and must never undo what the player just
  earned.

### C4 · Audio crossfade length
> `ART-002`, ADR-043.

- **Do:** turn `debug_overlays` **on** for one co-op run so state changes are
  visible, and listen at the transitions.
- **Write down:** does any transition read as a **cut**? Does any read as a
  **smear** — the calm music still going while something is clearly wrong?
- **Decides it:** a smear is worse than a cut and is the more likely fault.

---

## 6. What this session cannot close, and why

Three items on the page stay open after a perfect evening. They are listed here
so nobody expects them back.

| Item | Why the session does not close it |
|---|---|
| **Per-capita *extracted* value at 1/2/4** | `DES-012` already measures per-capita *spawned* value (4.00 / 3.00 / 2.67 / 2.25) and `--scaling-probe` asserts its sign. **Extracted** value waits on `DES-010`'s metrics sink — and **there is no task on the roadmap that builds it.** The question cannot close until something records the number. |
| **Self-reported growth across runs 11–25** | `DES-022`'s headline metric. Not an evening — a dozen-plus runs by somebody who is not you, over weeks. Needs a decision about whether it gates launch or moves to M5. |
| **First-person arm proportions** | `ART-004`. A feel question that needs arms to look at; Q96 is answered and the proportions are an art pass, not an observation. |

---

## 7. The sheet to fill in

One row per person per run. Everything above collapses to this.

| Run | Who | Party | Floor left on | Left by choice? | Shutter presses | Walked to the far glint? | Last death, in their words |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

And three sentences per person at the end of the night:

1. *"When did you first want to leave?"*
2. *"Describe the last thing that killed you."*
3. *"What was the shutter for?"*

---

## 8. What comes back

Hand me the sheet and the three sentences. Each question above names what its
answer changes; I write the ADRs, update the docs, and delete the rows from
`OPEN-QUESTIONS.md`. **Questions that the evening did not actually pose stay
open** — a question closed on a session that never reached it is worse than one
still on the page, because the page is what stops things getting lost.
