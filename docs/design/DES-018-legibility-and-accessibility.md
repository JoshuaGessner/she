---
id: DES-018
title: Legibility & Accessibility
status: accepted
owner: design
tags: [accessibility, ui, hud, audio, legibility, clamor]
updated: 2026-09-01
related: [DES-005, DES-013, DES-017, ART-001, PRO-005]
---

# Legibility & Accessibility

## The problem this document exists to fix

The game's central system is **sound**. `DES-013` states that a player "should be able to close their eyes and know what state a room is in." That is elegant, and it **locks deaf and hard-of-hearing players out of the core mechanic entirely.**

This is not a polish task. A visual language for Clamor cannot be bolted on at the end, because by then every system will assume the mix is carrying the information and there will be nowhere for it to attach.

> **DECIDED (ADR-036): every channel has a twin.** Everything the audio tells you, the screen also tells you. Everything the screen tells you, the audio also tells you. Designed together, from the start.

> **BUILT AT `M2-T03`, and made structural (ADR-090).** The twin is not a convention anyone has to remember. `AudioDirector` computes **one `HuntMix`** per frame; the score is driven from it and the Ear renders **the same object**. There are not two readings of the world to keep in step, so the only way the guarantee can break is a channel nobody draws — and `--ear-probe` refuses exactly that, in both directions, in the pre-commit sweep. Planting a fifth channel fails the build.

**This makes the game better for everyone.** A continuous visible Clamor readout serves Principle 4 directly — you can *see* how loud you were being, so you can explain your death in one sentence instead of guessing.

---

## Channel A — Audio: Clamor as adaptive score

> **DECIDED (ADR-035):** no alarms, no stingers. Clamor and Hunt state are carried by **layered adaptive music and ambience**.

Alarms are *threshold* signals — they fire or they don't. Clamor is *continuous*, and layered audio expresses continuity natively. It also fatigues far less across a 25-minute run and keeps the Deep feeling like a place rather than a UI.

**Vertical remixing.** One piece of music per biome, authored as stems that enter and leave under a Clamor/Hunt driver:

| Clamor / state | The mix |
|---|---|
| **Silent** | Air, distant water, stone settling. Almost no score. |
| **Low** | A single held drone, barely there |
| **Rising** | The drone tightens and narrows. A low pulse enters. |
| **Room alerted** | Pulse gains a heartbeat. Ambience pulls back — the room is listening. |
| **Swarm** | Layers stack, tempo lifts |
| **Hunter distant** | **The reserved instrument** enters — one bowed tagelharpa note that means this and *nothing else, ever* |
| **Hunter coursing** | Rhythm arrives under it |
| **Hunter sighted** | Full |
| **Collecting** *(baited)* | Everything drops away for a few seconds. **Silence as relief** — and as your window. |

**Rules:**
- **One instrument is reserved for the Hunter** and is never used decoratively anywhere in the game. It must never be a false alarm.
- **Transitions are crossfades, not cuts** ⟨tune⟩ — the player should feel the room getting worse, not be told.
- **Silence is a tool.** The drop when the Hunter is distracted is a designed beat, not an absence.
- Diegetic sound (footsteps, coin, doors) stays fully separate and unducked — it is gameplay information.

**Architecture:** vertical-remix from day one (`ART-001`), driven by `AudioDirector`. Stems authored together; one-shot cues cannot be retrofitted into this. **`AudioDirector` is a core system, not a budget line.**

## Channel B — Visual: the Ear

A persistent, quiet on-screen cue reporting exactly what the mix reports.

**What it shows:**

1. **Your Clamor output** — how loud *you* currently are. A filling ring or bar. Rises with weight, sprinting, combat, songs, opening a gate. **This is the single most important readout in the game** and the one that makes greed legible.
2. **Room state** — the `DES-013` awareness ladder as four unmistakable states: *unaware / suspicious / alerted / swarm*. Distinct by **shape and motion**, not colour alone.
3. **Bearing** — directional pips when something is investigating, so "where is it" is answerable without stereo hearing.
4. **The Hunter** — a distinct persistent marker whenever it is on the floor, showing state and rough bearing. Never a health bar, never a distance number. It appears when the reserved instrument does.

**Rules:**
- **Shape and motion first, colour second.** Colour-blind players must lose nothing (~8% of men). Never encode state in hue alone.
- **Quiet by default.** It competes with weight, health, map, and party state — cognitive load is our most expensive category (`PRO-005 §8`).
- **Continuous, not thresholded.** It should show gradations, matching the mix.
- **Scalable and repositionable**, including a high-contrast mode.

## The standing test

> **From M2 onward, the prototype must be played to completion with audio muted, as a regular part of testing.**

If a muted run is unplayable, the visual channel is incomplete. This is the only way to keep the twin honest as systems get added — everything else will drift.

> **This test is not automatable, and the sweep does not claim it is (ADR-090).** Nothing in CI can play a run. What CI *can* do is refuse the way the guarantee actually breaks — an audio channel with no visual twin — and that is what `--ear-probe` asserts. **A green sweep is not a muted playthrough.** The muted run remains a human job, and this line exists so nobody mistakes one for the other.

Its mirror is worth stating too: a run played with the HUD hidden should still be *survivable* on audio alone. Neither channel may become vestigial.

---

## Beyond the core loop

The rest. **Built by `M4-T11`, the accessibility suite** — which exists because this list said "planned rather than discovered late" for six months while no task implemented any of it (ADR-077). Listing is not planning; a milestone is.

**Visual**
- Full colour-blind support; no information in hue alone, anywhere
- UI scaling and font size; a dyslexia-friendly font option
- High contrast mode; adjustable HUD opacity
- Camera shake, motion blur, head-bob, and FOV all independently adjustable — **first-person + motion sickness is a real exclusion**, and cheap to prevent

**Audio**
- Independent volume sliders per bus (score / ambience / diegetic / UI / voice)
- Mono output option (single-sided hearing loss)
- **Visual sound indicators** as above — the same system, not a separate mode

**Input** — *the first two moved out of this list by ADR-075; see below*
- Full rebinding, including modifiers — `M4-T06`
- No required rapid repeated inputs; **no quick-time events anywhere**

## Input parity is a standing rule, from M1 (ADR-075)

> Controller parity and toggle-vs-hold were listed above as post-slice work. They were **promoted to standing rules in M1** because both are cheap now and are retrofits later — a HUD authored as *"press E"* has to be rebuilt, not adjusted.

- **Every action is reachable from a gamepad**, and `tools/bind_gamepad.py --check` fails the build if one is not. Parity that is merely intended is parity that regresses the next time an action is added.
- **Every hold action also has a latch.** Crouch ships with both (`ctrl`/B to hold, `c`/R3 to toggle); sprint, block and aim inherit the rule as they are built. Holding an input through the long quiet approach `DES-005` Layer 1 rewards is a real physical cost, not a preference.
- **Look is available without fine pointer control** — stick or arrow keys, rate-based, with an adjustable response curve.
- **Prompts name both devices** (`DES-019`).

Still absent, deliberately: rumble, glyph-swapping prompt icons, and rebinding UI. Those are `M4-T05`/`M4-T06` and are not approximated in the meantime.

**Cognitive**
- Contract and objective text re-readable at any time, never timed
- A run summary that explains what killed you (Principle 4, and it's an accessibility feature)
- Adjustable or disableable HUD elements individually

**What we will not do**
- No difficulty setting that removes the Hunter or Clamor — those are the game. Accessibility is about **access to the systems**, never about removing them.
- No accessibility feature gated behind progression.

## Open questions

> **DECIDED (ADR-039):** **Yes** — rendered small on the **party frame**, not on the Ear itself. Enables *"you're the loud one"* without cluttering the primary readout.

> **DECIDED (ADR-039):** **Yes** — controller rumble as a third twin for Clamor and Hunter proximity. Cheap, and it helps players comfortable with neither of the other channels. It must never be the *only* carrier of anything.

> **DECIDED (ADR-166):** **Coursing versus sighted, and coarse bearing — never precise position.** The question is really *what should the mix reveal*, because parity then forces the Ear to match it; answering the Ear alone would have let the two drift.

> Principle 4 is the discriminator. *"It had sighted me and I kept looting"* is a death a player can explain in one sentence; *"it was somewhere"* is not, and that is the failure `GATE M4 EXIT` asks about. So the **state change** is revealed, because it is what makes the stay-or-leave decision (`DES-005`) a decision at all — and precise position is withheld, because a position readout is a radar, and a radar turns the Hunt into a stealth minigame optimised by reflex rather than judgement (principle 3).

> Bearing stays **coarse** for the same reason: enough to run the right way, never enough to strafe around it. **Eight wedges of 45°** ⟨tune⟩, quantised — a needle is a position readout with extra steps.

> **Sharpened by ADR-168 against the literature.** Three specifics that the principles alone did not give:
>
> 1. **Two discrete states, never a continuous meter.** Stealth design practice moves enemies through *named* awareness states — at ease, curious, searching, alerted — precisely because discrete states are learnable and attributable. A continuous 0–1 bar invites optimisation by nudging, which is principle 3's failure mode wearing a progress bar. Ours are **coursing** and **sighted**, plus the absence of both.
> 2. **The transition is the event, not the steady state.** A readout you consult is a radar; a change that announces itself is a cue. The Ear marks the *moment* coursing becomes sighted, and that moment is what the player remembers and can recount afterwards.
> 3. **This is the accessibility floor, not a design luxury.** Deaf-accessibility practice names awareness indicators — *warn the player when an enemy is about to spot them, and from which direction* — as a baseline expectation. `DES-018`'s parity rule and the genre's accessibility standard arrive at the same readout from opposite directions.

> This question's own last clause is a task, not a rhetorical flourish — *confirm the mix isn't accidentally revealing more than intended*. `HuntMix` is computed once per frame and feeds both channels, so it is a single place to audit and a single place to assert. `M4-T16` carries it. **Closes Q80.**
