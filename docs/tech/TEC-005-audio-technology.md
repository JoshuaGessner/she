---
id: TEC-005
title: Audio Technology
status: accepted
owner: tech
tags: [audio, occlusion, middleware, godot, engine, risk]
updated: 2026-09-01
related: [ART-002, ART-003, TEC-001, TEC-004, DES-018]
---

# Audio Technology

## Summary

**Audio occlusion is not an engine-change problem.** It is roughly a week of work in Godot, or free with middleware. Reverb zones are already built into Godot and `ART-002` overstated their cost.

There *is* a legitimate argument for Unreal on this project — but it is about **networking**, not audio, and the right moment to make it is the M1 spike.

---

## What Godot 4 actually gives us

Verified against the Godot 4 class reference:

| Feature | Status |
|---|---|
| **Per-source low-pass** | ✅ `AudioStreamPlayer3D.attenuation_filter_cutoff_hz` (float, default 5000) and `attenuation_filter_db` (float, default −24). **Settable at runtime, per source.** This is the occlusion primitive, and it is already there. |
| **Reverb zones** | ✅ **Built in.** `Area3D.reverb_bus_enabled`, `reverb_bus_name`, `reverb_bus_amount`, `reverb_bus_uniformity`, plus `audio_bus_override` / `audio_bus_name`. |
| **Directional emission** | ✅ `emission_angle_enabled`, `emission_angle_degrees`, `emission_angle_filter_attenuation_db` |
| **Occlusion / obstruction** | ❌ **No built-in feature.** This is the only real gap. |

> **Correction to `ART-002`:** reverb zones were listed as a cost. They are not — `Area3D` does this natively, driven by the player's current cell.

## Writing occlusion ourselves — the approach

Straightforward, and cheaper than it sounds because the primitive already exists.

**Per audible 3D source:**
1. Raycast from listener to emitter.
2. If blocked, lerp `attenuation_filter_cutoff_hz` down (5000 → ~400 ⟨tune⟩) and drop `volume_db` a few dB.
3. If clear, lerp back up.

**Cost:** one raycast per audible source per update tick. With ~20–30 audible sources, **staggered across frames at ~10 Hz**, that is a few hundred raycasts per second. Negligible against a 150-agent AI budget (`TEC-001`).

**Refinements, in order of value:**
- **3–5 sample points** rather than one ray (emitter centre plus offsets) → *gradient* occlusion instead of binary. Cheap, and a large perceptual win.
- **Material-aware transmission** — a wooden door passes more than a metre of Dvergar stone. One float per material, near-free.
- **Portal propagation** — sound arriving *around* a corner rather than *through* the wall. This is the genuinely hard part.

> **The scoping insight: full propagation for every source is unnecessary.**
> Gradient occlusion for everything; **portal-based propagation only for the Gullsjúkr** (`DES-017`). It is the one source where "coming around the corner" versus "through the wall" is information the player must act on. One special case, not a general system.

Cell-based generation (`DES-015`, ADR-014) helps here — doorways between cells are known, so portals are already in the level graph rather than needing to be authored.

## Middleware — the better answer

**Recommendation: FMOD Studio.**

Given a dedicated musician, middleware stops being a convenience and becomes the correct architecture:

- **The composer authors the adaptive system themselves.** States, transitions, layer logic, and mixing live in FMOD Studio. They deliver a **bank**, not forty loose stems that we then have to wire up and guess at. This is a dramatically better handoff (`ART-003`).
- **Occlusion and reverb come with it**, including geometry-based occlusion.
- **Iteration without programmer involvement** — they can retune the whole Clamor ramp without touching the project.
- **Licensing:** FMOD's indie tier is free below revenue and budget thresholds. **Verify current terms before committing** — they change.

| Option | Verdict |
|---|---|
| **FMOD** | **Recommended.** Best composer-facing tooling, community Godot 4 integration, standard for adaptive music. |
| **Wwise** | More powerful spatial audio (rooms and portals are native, exactly our model), official Godot support, steeper learning curve. Strong second choice. |
| **Steam Audio** | Free, excellent occlusion/propagation, Godot 4 plugin exists but is community-maintained — maturity risk. Solves occlusion but *not* the adaptive-music handoff. |
| **Raw Godot** | Entirely viable. ~a week for gradient occlusion, plus wiring the stepped state machine ourselves. |

**Suggested path:** build the raw-Godot version first — it is a week, it removes the dependency risk, and it proves the design. Adopt FMOD when the musician is actually onboarded and their workflow is the deciding factor.

---

## Should this be an Unreal game?

Asked directly, so answered directly.

### Not for audio

Occlusion is ~a week in Godot or free with middleware, and reverb zones already exist. **Switching engines to solve this would be a large cost for a problem that is not real.**

### The honest argument for Unreal is networking

`TEC-004` names Godot's high-level multiplayer at 4 peers × ~150 synchronized entities as **the single riskiest assumption in the project**, with an explicit go/no-go spike. Unreal's replication, relevancy, and net culling are mature and battle-tested; that risk largely evaporates. For a co-op-core game (ADR-008), that is a real argument and a better one than audio.

### Why I still recommend staying in Godot

- **Use the tool you are fastest in.** Solo project, no deadline (ADR-034), and Godot is the stated stronger skill. Moving to a second-best tool trades certain velocity for uncertain benefit.
- **Iteration speed matters more than raw capability here.** M1 is a grey-box feel test. Godot's edit-run loop is materially faster, and the M1 gate is the only thing that matters right now.
- **Unreal's strengths do not apply.** Nanite, Lumen, and film-grade rendering are irrelevant to stylized low-poly (`ART-001`). We would carry the weight and none of the benefit.
- **Every technical doc assumes Godot** — `.tres` resources, scenes-as-components, autoloads, GDScript, `MultiplayerSynchronizer`. `TEC-001` through `TEC-004` would need rewriting.
- 5% royalty above $1M gross. Not decisive, but real.

### The actual decision point

> **The M1 networking spike is the engine decision, and it is cheap.**
>
> 4 peers, ~150 synchronized entities, measured. If Godot holds, the question is closed. **If it fails, Unreal is the correct fallback** — and that is a far better-informed decision than making it now on a problem that turned out to be a week of raycasts.

Deciding now means guessing. Deciding at M1 means knowing.

## Open questions

> **DECIDED (ADR-050):** **Raw Godot first**, migrating to FMOD when the musician is onboarded and their workflow becomes the deciding factor. A week of work, no dependency risk, and it proves the state machine before anyone is handed a pipeline.

> **BUILT AT `M2-T03` (ADR-090), and the reasoning got stronger.** `ART-002` chose **vertical remixing** — layers playing in sync at independent volumes — which is the half Godot does natively. What middleware actually buys is *horizontal* re-sequencing, musically quantised jumps between sections, and `ART-002` rejects it outright (*"crossfades, not cuts"*, *"never stingers"*). So the recommendation above is not a compromise for this design; it is the right tool.
>
> Two things this document undersells, worth correcting here:
>
> - **FMOD has no official Godot integration** — the table above says "community Godot 4 integration" and that is the decisive fact, not a footnote. It means a GDExtension with per-platform native binaries, tracking Godot releases, landing on the export pipeline ADR-086 established.
> - **The composer-facing workflow is FMOD's real value, and it benefits nobody until a composer exists.** `ART-003` is a brief, not a hire.
>
> **If middleware is ever adopted, this document's own table points at Wwise for this project** — rooms-and-portals is native and matches the cell-based design (ADR-014), and it has official Godot support. Not decided; recorded so the next reader does not inherit "FMOD" as a default.

> **DECIDED (ADR-167): this was never a design question, and it is now a precondition of `M4-T09`.** It asks for a third party's commercial terms *at a future date*, and the honest answer today is not a licence tier — it is that nobody should write one down here, because a term recorded now expires silently and is then believed.

> ADR-050 already decided the thing that matters: **raw Godot first**, migrating to FMOD only when the musician is onboarded and their workflow becomes the deciding factor. So there is no adoption pending, no dependency taken, and nothing blocked on the answer.

> The verification moves to where the adoption happens. `M4-T09` carries it as a precondition: **confirm current FMOD indie terms before a single bank enters the repo**, and if they have moved, `TEC-005`'s own table already names Wwise as the strong second choice. **Closes Q92.**
