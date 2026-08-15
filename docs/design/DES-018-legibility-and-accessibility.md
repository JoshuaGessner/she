---
id: DES-018
title: Legibility & Accessibility
status: accepted
owner: design
tags: [accessibility, ui, hud, audio, legibility, clamor]
updated: 2026-08-14
related: [DES-005, DES-013, DES-017, ART-001, PRO-005]
---

# Legibility & Accessibility

## The problem this document exists to fix

The game's central system is **sound**. `DES-013` states that a player "should be able to close their eyes and know what state a room is in." That is elegant, and it **locks deaf and hard-of-hearing players out of the core mechanic entirely.**

This is not a polish task. A visual language for Clamor cannot be bolted on at the end, because by then every system will assume the mix is carrying the information and there will be nowhere for it to attach.

> **DECIDED (ADR-036): every channel has a twin.** Everything the audio tells you, the screen also tells you. Everything the screen tells you, the audio also tells you. Designed together, from the start.

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

Its mirror is worth stating too: a run played with the HUD hidden should still be *survivable* on audio alone. Neither channel may become vestigial.

---

## Beyond the core loop

The rest, listed so it is planned rather than discovered late:

**Visual**
- Full colour-blind support; no information in hue alone, anywhere
- UI scaling and font size; a dyslexia-friendly font option
- High contrast mode; adjustable HUD opacity
- Camera shake, motion blur, head-bob, and FOV all independently adjustable — **first-person + motion sickness is a real exclusion**, and cheap to prevent

**Audio**
- Independent volume sliders per bus (score / ambience / diegetic / UI / voice)
- Mono output option (single-sided hearing loss)
- **Visual sound indicators** as above — the same system, not a separate mode

**Input**
- Full rebinding, including modifiers
- Toggle-vs-hold for every hold action (crouch, sprint, block, aim)
- No required rapid repeated inputs; **no quick-time events anywhere**
- Controller and keyboard parity

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

> **OPEN (Q80):** How much of the Hunter's *state* does the Ear reveal — bearing only, or coursing-versus-sighted too? Full parity with audio says everything the mix reveals. Confirm the mix isn't accidentally revealing more than intended.
