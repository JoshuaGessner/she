---
id: ART-002
title: Audio Design
status: proposed
owner: art
tags: [audio, music, sound-design, clamor, godot, budget]
updated: 2026-08-14
related: [ART-001, DES-018, DES-005, DES-013, DES-017, DES-014, TEC-001]
---

# Audio Design

Audio is not decoration in SHE. **It is the primary carrier of the game's core system**, and it deserves more design attention than it usually gets.

---

## The organizing principle

> **Diegetic sound is gameplay. Score is state. They never compete.**

| | Tells you | Bus | Ducked? |
|---|---|---|---|
| **Diegetic** — footsteps, coin, doors, breathing, the Gullsjúkr dragging | **Facts about the world.** Where something is, what it is, how close. | Diegetic | **Never** |
| **Score** — layered stems under the Clamor/Hunt driver | **How much trouble you are in.** A continuous emotional readout. | Music | Yes, to diegetic |

This split follows directly from `DES-018`'s dual-channel rule and it settles every mix argument in advance: **if score and a threat sound collide, the score loses.** A player must never miss a footstep because the music was swelling.

## Silence is the default

The single most common mistake in atmospheric game audio is scoring everything. If the music always plays, the layers have nowhere to go.

**The Deep is mostly quiet.** Air, distant water, stone settling, your own body. Floor 1 at low Clamor should be **near-silent** — which protects the arousal trough `PRO-005 §9` says the run needs, and makes the first drone entering an *event* rather than a texture change.

**Silence is also a designed beat.** When the Gullsjúkr stops to collect thrown gold (`DES-017`), the mix drops away. Relief, and your window.

---

## The sound of your own greed

**This is the most important sound work in the game — more important than the music.**

The player must *hear* what they are carrying:

- **Coin** shifting with every step. More coin, more sound, and it is the sound that gets you killed.
- **Plate and metal** knocking as you move; catastrophic when you run.
- **Breath** shortening under weight.
- **Footfalls** getting heavier, landing harder, on surfaces that answer differently — stone, water, bone, wood.
- **The bag** itself: leather, strain, the noise of rummaging while you crouch (`DES-019` — inventory is real-time and vulnerable).

If a player can close their eyes and *hear how rich they are*, this system works. That feedback loop is what makes Pillar P1 felt rather than understood.

## Adaptive score — vertical remixing (ADR-035)

One piece per biome, authored as **stems that enter and leave under a Clamor/Hunt driver.** Never alarms, never stingers.

Full state table in `DES-018`. The rules that matter for authoring:

- **Stems are written together**, to one tempo and key, so any combination is musically valid. This cannot be retrofitted from separately-composed cues.
- **Transitions are crossfades, not cuts** ⟨tune⟩. The player feels the room getting worse; they are never told.
- **The Hunter owns one reserved instrument** — a bowed tagelharpa note that means the Gullsjúkr and *nothing else, anywhere, ever*. It must never be a false alarm. When the player hears it, it is true.
- **Layers must sound complete at every level.** A single drone alone has to be satisfying, or quiet play is punished aesthetically.

## The three sonic worlds

**The Deep** — sparse, cold, reverberant, mostly diegetic. Score arrives as pressure. Each biome sounds materially different: the Delvings ring with stone and dead machinery; the Barrow-Fields are dry, close, and muffled by earth; the Sunken Wood is wet, organic, and full of things that stop when you look.

**The Threshold** — **the only safe sound in the game.** Warm, acoustic, sad. A fire, low voices, someone tuning something. This is the emotional anchor and the contrast that makes the Deep work (`DES-014`). Diablo's Tristram theme is the benchmark, and its power was never complexity.

**Her Chamber** — enormous and *close*. Deep room tone, a sense of vast air, and beneath it something slow and breathing. She speaks into the mind of the Bound: **no words, no voice acting** (`DES-001` anti-goal). Her presence is a felt sonic pressure paired with text — low, slow, immense, intimate.

## The Gullsjúkr sounds like money

Its movement is **a great deal of loose coin being dragged.** That single sound is its footstep, its tell, and its entire characterisation — you learn what it is before anyone explains it.

Plus: laboured breathing under enormous weight, the creak of overloaded straps, and **counting** — the recognisable human sounds of a person still doing the thing (`DES-017` Q77 — no words).

## Instrumentation

Nordic and archaic, matching `DES-006`'s sources: **tagelharpa / jouhikko** (bowed lyre — and the Hunter's reserved voice), **kantele**, **frame drum**, **birch-bark lur**, **bone flute**, low overtone singing, and a great deal of prepared and bowed metal for the Deep.

> **Avoid Wardruna pastiche.** The Nordic-folk-revival sound is well-trodden and instantly recognisable as a reference rather than a voice. Use the instruments; do not use the arrangements.

## Mix priority

When everything happens at once, this is the order things survive in:

1. **The Hunter's reserved instrument** — always audible, no exceptions
2. **Diegetic threat** — nearby footsteps, doors, enemy tells
3. **Your own noise** — you must always be able to hear your Clamor
4. **Score layers**
5. **Ambience**
6. **UI** — minimal by design, since we have no stingers

## Implementation (`TEC-001`)

**`AudioDirector` is a core system, not a budget line.** It owns the Clamor/Hunt driver, bus state, and reverb zones.

- **Buses:** Master → Music (stems) · Ambience · Diegetic · UI. Independent player-facing sliders for each (`DES-018`).
- **Adaptive music:** Godot 4.3+ `AudioStreamInteractive` where it fits; otherwise synchronised `AudioStreamPlayer`s crossfaded by bus volume. Prototype both early — this is the highest-risk audio tech in the project.
- **Reverb zones.** Dungeon spaces vary enormously — a great hall and a crawlspace must not share a reverb. Area-driven reverb parameters, switched by the player's current cell (`DES-015`).
- **Occlusion.** Godot has no built-in audio occlusion, and **this game needs it** — hearing something through a wall versus around a corner is gameplay information. Implement raycast-driven low-pass filtering on 3D sources ⟨a known real cost; budget for it⟩.
- **Networking:** audio is entirely client-side, driven by replicated *state* (`TEC-004`). **Never replicate sounds.** Each client resolves its own mix from Hunt state, alert states, and positions.

## Scope, honestly (solo project — ADR-034)

Adaptive audio is a genuine specialism and this is a solo build, so priorities matter more than usual:

**Spend effort here first:** the **diegetic layer** — your own greed, enemy tells, the Gullsjúkr. It is gameplay-critical, it is what `DES-018` parity depends on, and it is craft rather than composition.

**Consider licensing or commissioning the score.** Stems authored for vertical remixing are a well-understood commission, and a composer will do it better and faster than learning to. If commissioning: **specify the stem architecture up front** — one tempo, one key, layers valid in any combination — because a normally-composed soundtrack cannot be retrofitted into this system.

**Prototype at M1, not M4.** The Threshold theme and a two-layer Clamor test are both cheap and both de-risk the largest unknown. `DES-014` already flags the Threshold theme as an early prototype item.

## Open questions

> **OPEN (Q87):** Is the adaptive driver **continuous** (layer gains follow Clamor smoothly) or **stepped** (discrete states with crossfades)? Continuous is truer to the system; stepped is far easier to author and mix. Leaning **stepped states with long crossfades** — indistinguishable in play, dramatically cheaper.

> **OPEN (Q88):** Does the Threshold theme change as camp momentum builds (`DES-014`, ADR-025)? A fuller camp with a fuller arrangement is lovely and nearly free if the stems already exist.

> **OPEN (Q89):** Do the six classes have any audio identity — the Skald's Verse obviously, but do the others sound different to play? Probably footsteps and gear weight only; anything more competes with the Clamor read.

> **OPEN (Q90):** How does audio handle the **Vörðr** state (`DES-012`)? A ghost that hears everything and makes nothing is a real mix problem, and possibly a lovely one — the world going quiet around you.
