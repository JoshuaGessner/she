---
id: ART-003
title: Composer & Sound Design Brief
status: proposed
owner: art
tags: [audio, handoff, brief, music, sound-design, specs]
updated: 2026-08-14
related: [ART-001, ART-002, TEC-005, DES-018, DES-017, DES-014]
---

# Composer & Sound Design Brief

**This document is a standalone handoff.** It should be readable by someone who has never seen the rest of the project, and contain everything needed to start making sound. Nothing here assumes familiarity with the other docs.

---

## 1. What the game is

**SHE** is a first-person fantasy dungeon-crawler for 1–4 players. You descend into a buried, ruined world to steal gold for an ancient dragon who cannot leave her mountain. She gives you a piece of her power in exchange. The more she gives, the more she demands.

You go down, you take as much as you can carry, and you try to get out. Dying loses almost everything.

The world is **Norse and Anglo-Saxon**, drawn from the Eddas, *Beowulf*, and *Völsunga saga* — *not* high fantasy. Think grave-mounds, collapsed dwarf mines, drowned forests. A civilization died here and you are looting the body.

**Tone: elegiac and grubby.** Not heroic. Not grimdark. Sad, physical, slightly absurd. The Anglo-Saxon poem *The Ruin* — a man walking through a dead city marvelling at masonry his people can no longer make — is the exact register.

**The feeling the whole game chases, in one sentence:**
> *"I have enough. I should leave. One more room."*

---

## 2. The one rule that governs everything

> **Diegetic sound is gameplay. Music is state. They never compete.**

- **Diegetic sound** — footsteps, coins, doors, breathing, enemies — tells the player **facts**: where something is, what it is, how close. **This is information they will die without.** It is never ducked, never buried.
- **Music** tells them **how much trouble they are in.** It is a continuous emotional readout of a system called Clamor (below).

**If music and a threat sound ever collide, the music loses.** No player should miss a footstep because a cue was swelling.

### Silence is the default

The most common mistake in this genre is scoring everything. **Please score less than feels natural.** If music always plays, there is nowhere to escalate to.

At the start of a descent, when the player is being quiet, there should be **almost nothing** — air, distant water, stone settling. The first drone entering must feel like an *event*.

---

## 3. Clamor — the system you are scoring

**Clamor is noise.** Everything the player does makes it: walking, running, fighting, opening doors, and above all **carrying treasure**. Coins are heavy and loud. The richer you get, the louder you are, the more the dungeon notices.

**The music is a live readout of that number.** Not a series of cues — a mix that continuously reflects how much danger the player has brought on themselves.

### Structure: layered stems (vertical remixing)

One piece of music per environment, written as **separate layers that fade in and out** as Clamor rises and falls. Not linear tracks. Not cues that trigger and finish.

Everything is **stepped** — the game holds a discrete state and crossfades between them (⟨~2–4s⟩), so please compose to states rather than to a continuous parameter.

### The states

| State | What is happening | The mix |
|---|---|---|
| **Silent** | Player is being careful, carrying little | Ambience only. Almost no music. |
| **Low** | Moving normally | One held drone, barely present |
| **Rising** | Getting loud — running, weighed down | Drone tightens and narrows. A low pulse enters. |
| **Room alerted** | Something has heard them | Pulse gains a heartbeat. Ambience pulls back — *the room is listening.* |
| **Swarm** | Multiple enemies converging | Layers stack, tempo lifts |
| **Hunter distant** | **The Hunter is on this floor** | **The reserved instrument enters** (see §5) |
| **Hunter coursing** | It is following them | Rhythm arrives underneath |
| **Hunter sighted** | It has them | Full |
| **Hunter distracted** | They threw gold and it stopped to collect | **Everything drops away.** Near silence. |

**That last state matters enormously.** The drop is relief and it is the player's window to escape. It should feel like surfacing.

### Composition constraints

- **All layers of a piece share one tempo and one key**, so any combination is musically valid.
- **Every layer must be complete on its own.** A player who plays quietly will hear the drone alone for twenty minutes — it has to be worth hearing.
- **Layers are all the same length** and loop seamlessly against each other.

---

## 4. The three sonic worlds

### The Deep — where the game happens

Sparse, cold, reverberant, **mostly diegetic**. Music arrives as pressure rather than accompaniment.

Three environments, each materially distinct:

- **The Delvings** — a collapsed dwarf mine-city. Cut stone, dead machinery, flooded shafts. **Rings.** Metal, depth, industrial ghosts.
- **The Barrow-Fields** — grave-mounds of a dead kingdom. **Dry, close, muffled by earth.** Almost no reverb. Claustrophobic. The dead here keep what is theirs.
- **The Sunken Wood** — a drowned petrified forest grown through ruins. **Wet, organic, alive-wrong.** Things that stop when you look at them.

### The Threshold — the camp, between runs

> **This is the most important piece of music in the game.**

It is **the only safe sound**, and the contrast is what makes the Deep work. A fire, a few desperate people who live at the mouth of the mountain, someone quietly tuning an instrument.

**Warm, acoustic, sad, and small.** People come back here having lost friends. Some of them will not come back at all.

The benchmark is **Diablo's Tristram theme** — its power was never complexity, it was that it sounded like the last warm place in the world. If a player hums anything from this game a year later, it should be this.

### Her Chamber — the dragon

Enormous and **close**. Deep room tone, a sense of vast air, and beneath it something slow and breathing.

**She has no voice acting and no words.** She speaks directly into the mind, delivered as text. What you are creating is her *presence* — low, slow, immense, intimate. Not a monster. Something old and wounded and fond of you.

---

## 5. The Hunter — and the one reserved instrument

The Hunter is a **former treasure-hunter who stayed too long and never came out.** They are still down there, still carrying their hoard, still trying to pay a debt that can no longer be paid. Enormous with gold fused into what used to be armour.

It hunts the player because they have gold and it needs gold.

**It sounds like money.** Its movement is a great deal of **loose coin being dragged**. That single sound is its footstep, its warning, and its entire characterization — the player should understand what it is before anyone explains it. Plus: laboured breathing under weight, overloaded straps, and **counting**. Recognisably a person, still doing the thing. **No words, ever.**

### The reserved instrument — a hard rule

**One instrument is reserved for the Hunter and appears nowhere else in the game. Ever.** Not in the Threshold, not as texture, not "just once" somewhere atmospheric.

When the player hears it, **it is always true.** It must never be a false alarm. Proposed: a single bowed note — **tagelharpa or jouhikko** — but the choice is yours as long as it is unmistakable and never reused.

---

## 6. The sound of your own greed

> **This is the most important sound design in the game — more than the music.**

The player must be able to **hear how rich they are**:

- **Coin** shifting with every step. More coin, more noise. This is the sound that gets them killed.
- **Plate and metal** knocking as they move. Catastrophic at a run.
- **Breath** shortening under weight.
- **Footfalls** getting heavier and landing harder, differentiated by surface — stone, water, bone, wood.
- **The bag** — leather, strain, and the sound of rummaging while crouched in the dark.

If a player can close their eyes and hear how much they are carrying, this system works. That is the whole game in one feedback loop.

---

## 7. Instrumentation

**Nordic and archaic**, matching the setting:

**tagelharpa / jouhikko** (bowed lyre) · **kantele** · **frame drum** · **birch-bark lur** · **bone flute** · low overtone and throat singing · a great deal of **prepared and bowed metal** for the Deep.

**Please avoid Wardruna pastiche.** The Nordic-folk-revival sound is extremely well-trodden and reads instantly as a reference rather than a voice. **Use the instruments; do not use the arrangements.** We would rather sound strange than sound familiar.

**Reference points:** *Alien: Isolation* for restraint and dread · *Diablo II*'s Rogue Encampment for the safe place · *Hunt: Showdown* for grubby weight · Anglo-Saxon and Norse source material over any modern fantasy score.

---

## 8. Deliverable specs

**Format:** 48 kHz, 24-bit WAV. Keep your masters; we handle conversion.

**Music stems:**
- All layers of one piece: **same tempo, same key, same length**, aligned to sample zero
- **Seamless loops** — no fades at loop boundaries, sample-accurate
- Deliver **wet** — musical space and reverb baked in is fine and welcome
- Target roughly **−18 LUFS integrated** so there is headroom for stacking

**Sound effects:**
- Deliver **completely dry — no reverb.** The engine applies reverb per space, and a great hall and a crawlspace must not share one. Baked reverb will fight it.
- Peaks no higher than **−6 dBFS**
- Variations for anything repetitive: **4–6 alternates** minimum for footsteps, coin, impacts

**Naming:** `mus_<place>_<state>_<layer>.wav` and `sfx_<category>_<thing>_<var>.wav`
e.g. `mus_delvings_rising_pulse.wav`, `sfx_foot_stone_run_03.wav`

**Delivery:** whatever is comfortable — a shared drive is fine. Stems in folders per piece.

---

## 9. Accessibility — please read this one

**Every piece of information the audio carries must also exist visually.** The game has an on-screen readout mirroring Clamor and threat state, because a player who cannot hear must still be able to play.

This does **not** constrain what you make. It does mean: **if you invent a new audio-only signal for something important, tell us**, so we can build its visual twin. The parallel is designed, not captioned afterward.

---

## 10. What we would love, and what we would not

**Love:**
- Restraint. Long stretches of near-nothing.
- Real instruments, real rooms, real noise. Imperfection is welcome.
- Strangeness over familiarity.
- Music that sounds like the place, not like a score laid over it.

**Not:**
- Alarms, stingers, or "danger!" hits. The system is continuous. **No jump-scare cues.**
- Orchestral epic fantasy. This is a small sad story about greed.
- Anything that competes with footsteps.
- A theme that plays constantly.

## Open questions for the composer

> Whether the Threshold theme should grow as the camp fills with survivors (`ART-002` Q88) — lovely, and nearly free if the stems exist.

> Whether the three environments share any musical DNA, or are entirely separate voices. A shared interval or instrument across all three would tie the world together; total separation makes each descent feel like a different place.
