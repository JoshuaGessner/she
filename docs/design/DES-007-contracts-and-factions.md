---
id: DES-007
title: Contracts & Factions
status: accepted
owner: design
tags: [quests, contracts, factions, dmz, structure, replayability]
updated: 2026-08-14
related: [DES-002, DES-006, DES-008]
---

# Contracts & Factions

## What we're actually taking from DMZ

DMZ's mission system worked for reasons worth naming precisely, because most people copy the wrong part:

1. **Concurrency.** You hold multiple active objectives from different sources simultaneously. You are always overcommitted, so every route is a compromise. *This is the essential part.*
2. **Three tiers of commitment.** Long-arc faction missions (tier progression), mid-arc contracts (this run), and opportunistic in-world contracts (picked up off a board mid-run).
3. **Objectives that reshape routing.** Good ones send you somewhere you wouldn't go, at a time you'd rather not go there.
4. **Fail-forward.** Failing a mission costs progress, not the run.

What we're *not* taking: DMZ's opaque unlock chains, its dependence on other players existing, and its habit of gating essential items behind grindy prerequisites.

## Three tiers

### Tier 1 — Pacts (long arc, spans a life)
The dragon's own agenda. Multi-run objectives that advance Pact Rank and unlock Aspect nodes (`DES-004`).
*"Bring me nine crowns of the Dvergar kings."* — spans many runs, tracks in the Lair, gives a life its through-line.

### Tier 2 — Contracts (accepted in the Lair, resolve this run)
Chosen before descent, 2–4 active ⟨tune⟩. From factions (below). This is where concurrency bites: three contracts pointing at three different parts of the floor, and you cannot do all of them and leave on time.

Contract archetypes (keep the list short and recombine heavily — Principle 5):
- **Retrieve** — a specific item from a specific danger
- **Cull** — kill a named/elite target
- **Escort/Deliver** — move a fragile thing to a place (the best routing-pressure contracts)
- **Survey** — reach a location and record it (rewards Lineage cartography)
- **Denial** — destroy or seal something; often makes the *world* worse permanently (`DES-006` world scars)
- **Rival** — a competing Bound is after the same prize; get there first

### Tier 3 — Whispers (found in-run, opportunistic)
Discovered mid-descent. Short, sharp, expiring: a sealed door needing a key you just found, a Bound's corpse with a half-finished contract, a Draugr barrow that opens only while the Hunt is active.

**Whispers are the "one more room" engine.** They should fire *precisely* when the player has decided to leave. That's not accidental — it's the design job of this tier.

## Factions

Three, each wanting a different behaviour from the player, so faction choice implies playstyle:

| Faction | Want | Reward | Tension with the dragon |
|---|---|---|---|
| **The Ashen Lodge** (mortal salvagers, your peers) | Survival, information, mutual aid | Gear, extraction tools, safehouses, map intel | They think your pact will kill you. They're right. |
| **The Deep-Kin** (surviving Dvergar) | Their heritage returned, their halls respected | Crafting, repairs, unique smithing, deep access | Everything you tribute to her is *their* property |
| **The Silent Choir** (Álfar-touched cultists of what's below) | Things left undisturbed — or disturbed *deliberately* | Corruption powers, forbidden routes, Maw Aspect nodes | They want her dead. Or awake. It's unclear. |

### The Ashen Lodge carries the theme

> Under ADR-020 the Lodge is **the light you don't walk toward.**

They are the only people in the game telling the truth: the pact will kill you, it has killed everyone who took it, and there is a smaller life available where you salvage what you can and die old. They offer real, useful, *unglamorous* things — safehouses, map intel, extraction tools. Never power.

They must be **written with dignity, not as a nagging voice.** If they scold, the player tunes them out and the theme dies with them. They should be warm, competent, and quietly sad about you. A good Lodge NPC greets you by name, gives you something useful, and doesn't mention the dragon at all — and *that's* what lands.

**They also must never be mechanically correct-but-punished.** Taking Lodge work over a Pact objective should be a legitimate, viable run. If the Lodge path is a trap, we've argued the opposite of what we meant.

- **Standing is zero-sum ⟨tune⟩** between Deep-Kin and Silent Choir — you cannot max both in one life. Forces identity per life; supports the LIFE persistence tier (`DES-003`) by making each life *feel* different.
- **Contacts persist to Lineage; standing does not.** A new life can talk to everyone but has to re-earn trust — which is exactly the right split (options persist, power doesn't).

> **DECIDED (ADR-050):** **Both, in separate lanes** — a *threshold* rank gates access to contract tiers, and standing is *spendable* on individual favours. Keeps access legible while leaving an ongoing decision.

## Generation

Contracts are **templates + parameters**, assembled at run generation, not hand-authored instances:

```
Contract := archetype × target × location × complication × faction × reward-tier
```

A complication is what makes a template feel authored: *the target is already dead and something is wearing it*, *the item is cursed and cannot be dropped once taken*, *a Rival is 90 seconds ahead of you*, *it can only be done during the Hunt*.

**~20 well-written complications generate more perceived variety than 100 hand-written quests, at a fraction of the cost.** Invest authoring effort in complications and in the *text*, not in instances.

> **DECIDED (ADR-050):** **Hand-written faction voice per archetype, procedural specifics.** A small authored corpus with slots — the same split used for Calamities (`DES-015`) and the Bound (ADR-027). Volume target still to set.
