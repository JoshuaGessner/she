---
id: DES-013
title: Enemies & AI
status: draft
owner: design
tags: [enemies, ai, combat, clamor, systems, co-op]
updated: 2026-08-13
related: [DES-005, DES-007, DES-009, TEC-001, TEC-004]
---

# Enemies & AI

## The thesis: enemies are a noise system, not a challenge system

In most action games the enemy roster exists to test your combat skill. **Here it exists to make combat expensive.** Fighting is loud, and loud feeds the Hunt (`DES-005`). So the roster's job is to make you constantly answer *"is this fight worth the noise?"* — which is Principle 3 applied to every room.

**Design consequence:** encounters must be **avoidable**. If the level design forces combat, Clamor stops being a decision and becomes a tax, and both the Veiðimaðr and the Wing Aspect lose their reason to exist.

> **DECIDED (ADR-032), closing Q40:** the generator guarantees **at least one route from entrance to a reachable exit that bypasses every encounter on it.** Rooms you *choose* to enter carry no such guarantee.
>
> So you can always, in principle, walk out without fighting — but **Guardian rooms are explicitly allowed to be committal**, which sharpens them considerably: entering one is a decision you may not be able to take back. Enforced as a hard check in step 8 of the generation pipeline (`DES-015`); a failure re-rolls the offending sub-graph. Test at M2.

**Reference:** Thief's guards (avoidable, alert-laddered, more dangerous as a group than as a challenge), *Alien: Isolation*'s working joes, and Barony's mutually hostile dungeon factions.

## The awareness ladder — the spine of all AI

Every enemy runs the same four-state ladder. This is the single most important system in the document because **it's what consumes the Clamor field** and turns an abstract number into felt pressure.

```
UNAWARE ──heard something──► SUSPICIOUS ──confirmed──► ALERTED ──calls out──► SWARM
   ▲                              │                        │                    │
   └──────timeout, quiet──────────┴────lost you────────────┘                    │
                                                                                 │
                              (Clamor spike propagates to nearby actors) ◄───────┘
```

- **Unaware** — patrol, idle, work. Full loot opportunity, full stealth options.
- **Suspicious** — investigates the *last heard position*, not your actual position. Critical for fairness (`PRO-005 §5`): the player can always understand why they were found, and can bait it.
- **Alerted** — actively hunting you. Generates Clamor itself.
- **Swarm** — calls others. **This is the failure state**, and it must be loudly telegraphed a beat before it happens so the player gets one chance to prevent it.

**Rule:** every transition has a distinct, unmissable audio cue. A player must be able to close their eyes and know what state the room is in.

## Roles, not damage types

Roster is defined by *what problem it poses*, never by "fire guy / ice guy":

| Role | Poses | Counter-play |
|---|---|---|
| **Alarm** | Weak, but escalates the whole floor if it survives 3 seconds ⟨tune⟩ | Kill it fast and quietly, or avoid its sightline entirely |
| **Attrition** | Numerous, cheap, chips health and durability | Not worth fighting; worth outrunning |
| **Blocker** | Owns a corridor or door; makes a route expensive | Go around, shove past, or pay for it |
| **Tracker** | Follows Clamor trails across rooms | Go quiet, break the trail, bait it |
| **Guardian** | Stationary, immobile, sits on high-value loot | **Purely optional.** The clean greed check — it will never come to you |
| **Fauna** | Neutral until disturbed; hazardous to everyone | Weaponize it against other factions |
| **Elite / Named** | Contract targets (`DES-007`) | The fights you actually choose |

**The Guardian role is the most important one.** An enemy that *never* threatens you unless you approach it is the purest possible expression of Pillar P1 — the danger is entirely self-selected.

## Roster sketch (~12 at 1.0)

**The Delvings** — Dvergar ruin
- **Wretch** *(attrition)* — degenerate Dvergar survivors, numerous, pitiable
- **Hall-Warden** *(blocker)* — dead Dvergar armour still doing its job. Slow, immovable, deafeningly loud when struck
- **Sump-Swarm** *(fauna)* — things in the flooded shafts; harmless unless you enter the water
- **Bellringer** *(alarm)* — a Wretch that has learned what the old alarm-chains are for

**The Barrow-Fields**
- **Draugr** *(guardian)* — **aggros on theft, not proximity.** Take the grave-goods, take the consequence. Perfect thematic fusion of enemy and loot (`DES-008`)
- **Haugbúi** *(elite)* — the mound-lord. A named fight, always optional, always worth it
- **Grave-Hound** *(tracker)* — hunts by scent *and* Clamor
- **Barrow-Wisp** *(alarm)* — lures toward drowning, calls the rest

**The Sunken Wood**
- **Vættir** *(fauna/neutral)* — land-spirits. Hostile only if you take from the wood
- **Root-Bound** *(blocker)* — grown through the corpses of people who tried this before
- **The Watcher** *(tracker)* — never attacks. Follows. Escalates the Hunt while it has line of sight

**Cross-biome**
- **The Bound** *(elite)* — other pact-holders, past and present. Where async player echoes live (`DES-002`)
- **Thursar** *(rare, catastrophic)* — giant-kin. Not a fight. A weather event.

## Modifiers: the content multiplier

Roster variety comes from **~8 modifiers × 12 archetypes**, not from authoring 40 enemies (Principle 5, and Koster's pattern-disruption in `PRO-005 §6`).

| Modifier | Effect |
|---|---|
| **Gilded** | Carries real tribute value. **An optional fight that is worth money** — greed made into an encounter |
| **Silent** | No audio tells. Terrifying, and rare by necessity |
| **Roused** | Starts Alerted. The room already knows |
| **Starved** | Faster, weaker, attacks other factions on sight |
| **Warded** | Immune to one damage type; forces a weapon swap |
| **Grave-Cursed** | Killing it inflicts a Scar-lite debuff until extraction |
| **Yoked** | Linked to another enemy; damage is shared |
| **Watched** | Its death alerts the floor |

**Gilded is the standout.** An enemy that is *loot* inverts the entire avoid-combat calculus for one encounter at a time, and it's the cheapest possible way to make the player argue with themselves.

## Enemy factions fight each other

Three mutually hostile groups — **Dvergar remnant · Draugr · Vættir** — plus the Bound, who hate everyone.

This is a Barony inheritance and it earns its cost several times over: it produces emergent stories, gives the player a tool (bait one into another), makes the dungeon feel like a place rather than a shooting gallery, and it means a room's contents are a *situation* rather than a wave.

**Rule:** faction hostility is real, not scripted. If a Draugr and a Wretch are in a room, they fight, whether or not the player is watching.

## Co-op considerations (ADR-008/010)

- **Aggro must be legible with four players.** Every enemy shows who it is targeting. Non-negotiable for readability.
- **Enemies target by Clamor, not by proximity** — so the loud Skald pulls aggro off the sneaking Veiðimaðr *by design*. This makes the class roster mechanically coherent in a party.
- **Floors scale to the highest rank present** (ADR-010) — so under-ranked players will meet enemies that two-shot them. The awareness ladder is what makes that survivable: an unaware enemy is harmless regardless of its stats.
- **Density scales near-linearly with party size**, Clamor super-linearly (`DES-012`).

## AI budget (`TEC-001`)

- ≤150 agents per floor; **~20 fully simulated** (behaviour tree, navmesh, senses), the rest on a cheap LOD brain (state + position only), frozen entirely outside a radius.
- **Host-authoritative**, with relevance filtering so clients don't sync AI they can't perceive (`TEC-004`).
- Senses are **Clamor-grid lookups**, not per-agent raycasts. Hearing must be O(1) per agent or the budget dies.

> **OPEN:** Do enemies loot? A Wretch picking up gold you dropped, and having to kill it to get it back, is extremely on-theme — and a nightmare for the host-authoritative loot model. Cheap version: only **Gilded** enemies carry, and they never pick up.

> **OPEN:** Is there a stealth-kill? A silent takedown on an Unaware enemy is the obvious reward for the Veiðimaðr, but it risks trivializing the awareness ladder if it's reliable. Leaning **yes, but slow, positional, and impossible while carrying heavy loot** — greed should close the option.

> **OPEN:** Respawns. None is cleanest and rewards clearing. But it makes a cleared floor a safe corridor, which undercuts the extraction walk. Leaning **no respawns, but the Hunt reintroduces pressure into cleared space** — the room is empty, and something is still coming.
