---
id: DES-014
title: The Lair
status: accepted
owner: design
tags: [hub, lair, retention, social, co-op, ui, progression, networking]
updated: 2026-08-17
related: [DES-002, DES-003, DES-010, DES-012, DES-006, TEC-004]
---

# The Lair

Her mountain, and the camp of desperate people who live at its mouth.

> **Scope (ADR-023):** the Lair is **thematically large and physically small.** Big in narrative and mechanical weight; compact in footprint. It contains only what is relevant to the individual player who lives there — no sprawl, no fetch-walking, no filler stations. **The ~2-minute target stands.** Depth comes from what the space *means*, not from square metres.

---

## The multiplayer problem, and the fix

Pacts are individual (`DES-012`). So a shared hub has no obvious owner: whose Lair are four players standing in? Every naive answer is bad.

| Option | Why it fails |
|---|---|
| **Everyone visits the host's Lair** | Your progress is invisible while you play with friends. A rank-1 player wandering a rank-9 Lair spoils their own arc. The hoard — the emotional payload — belongs to someone else. |
| **Shared clan Lair** | Breaks solo/co-op continuity outright. Breaks individual pacts, which is the property keeping progression off the network (`TEC-004`). Destroys the private hoard. Adds a whole shared-save sync problem. |
| **No hub, just a party menu** | Loses the four-people-standing-around value entirely. A menu is not a place. |

**The actual problem is that the Lair was doing two jobs with opposite requirements.**

> **DECIDED (ADR-021): split it in two.**
>
> **BUILT AT `M2-T06` (ADR-095), and the split is enforced by absence.** `chamber.tscn` contains **no `CoopSession` at all** — a body is instantiated directly. Nothing can replicate out of a scene with no session in it, however carelessly anyone wires it later, which is a stronger guarantee than a rule saying not to. `TEC-004`'s "progression never touches the wire" therefore falls out of the fiction rather than the fiction being bent to fit it.
>
> The **Settle beat** landed with it: tribute is the same drag-out-of-the-bag gesture that abandons loot on a dungeon floor, and **the place you are standing decides what it means** — at the hoard she keeps it, at the stash you do, anywhere else it is on the floor. `DES-019` refuses a confirmation dialog and asks for the decision to be physical; this is what physical costs, and nothing new had to be built for it. The game now boots into the Threshold.

### Your Chamber — private, local, always yours

Her. Your hoard. The skill tree. Your stash. The Legacy screen.

**You are always in your own Chamber, even in co-op, even at the moment your friends are in theirs.** No other player ever enters it. It is never networked.

This is right for design reasons before technical ones: tribute, her voice, and choosing what she remembers of you are **solitary by design**. `DES-012` already established she speaks to each of the Bound separately. Four people watching you decide what she keeps of your life is actively wrong — it's the most intimate moment in the game.

And it is **diegetically enforced, not technically excused**: she is fused into the mountain and cannot be approached in company. Each of the Bound goes in alone.

### The Threshold — shared, networked, the only hub

The mouth of the mountain. Where the Bound camp, where the Ashen Lodge keeps its fire, where the contract board hangs, where the Descent begins.

**This is the only space that replicates**, and it has essentially no simulation — avatars, NPCs, UI. Cheap.

### Why this solves the continuity problem

```
SOLO:    Chamber ──► Threshold ──► Descent
CO-OP:   Chamber ──► Threshold ──► Descent
                     └─ friends are standing here
```

**Identical flow.** No mode switch, no different UI, no "clan Lair" versus "my Lair." The only difference between solo and co-op is whether anyone else is in the Threshold when you walk out. That is exactly the continuity a shared Lair would have destroyed, and we get it by *removing* a system rather than adding one.

It also preserves the `TEC-004` architecture win intact: **progression never touches the network.**

### The thematic bonus

Putting the Ashen Lodge in the *shared* space means **your friends are standing around the people telling you to quit** (`DES-007`, ADR-020). The light you don't walk toward is where you socialize. That wasn't planned; it's what happens when the structure is right.

---

## Networking specifics (`TEC-004`)

| Element | Handling |
|---|---|
| Chamber | **Local scene. Never replicated.** Zero sync cost. |
| Threshold | Networked; player avatars, presence, ready-state, chat/ping |
| Threshold visual state | **Follows the host's lineage** — joining a veteran shows a fuller, older camp. One rule, legible, aspirational. |
| Contract board | Shows *your* contracts. Party contracts are proposed and accepted by the party (`DES-007`). |
| Expedition select | Party vote; host breaks ties |
| Host disconnect | Party dissolves back to solo Thresholds. No run state at risk — nothing is simulated here. |
| Late join (ADR-016) | The waiting player is **in the Threshold**, and opens the gate from there |

**A player can drop back to their Chamber mid-lobby without disrupting anyone** — respec, re-stash, talk to her — and walk back out. Because the Chamber is local, this costs the party nothing.

---

## The hoard grows, and it never resets

Unchanged, and now unambiguously **in your Chamber where it belongs**.

She sits on everything you have ever given her, and it is physically there. Tribute a crown, and that crown is in the pile. Come back at rank 8 and walk through gold up to your chest.

**The hoard is LINEAGE tier. It never wipes.** Your stash is gone, your tree is gone, your rank is gone — but the mountain of gold your last eleven lives paid for is still there, and she is still lying on it.

- A **permanent physical monument to every life you have lost**, which turns ADR-004's harshness into something you can walk on.
- **Visible progress with zero balance impact** — the safest possible retention mechanism (`DES-003`).
- Under ADR-020 it is also the clearest statement of the theme in the game, and it never says a word.
- Costs a growing-pile-of-meshes system and nothing else. **Cheap. Build it early.**

---

## The staves — an ambient, ambiguous leaderboard

> **DECIDED (ADR-022):** hoards stay private. What's public is a **rune-stave** at each of the Bound's camp spot in the Threshold, notched with what they have given her.

Tall, worn, deeply-notched staves belong to people who have been feeding her a long time. **No numbers, no sorting, no ranked table, no UI list.** You read it by looking at it.

**Why the fiction does the work here.** A public tally of what people have given a dragon is, structurally, a leaderboard for who has fed their compulsion hardest — exactly what `PRO-005 §11` exists to catch. But under ADR-020, **a very tall stave is impressive and it is a gravestone.** The game's own framing makes a big tally ambiguous instead of aspirational, which defuses the problem through story rather than restriction. That's the better fix, and it only works if we never undercut it.

- Signals **tenure, not skill** — a record of time and appetite, never competence.
- **It must never become sortable or numeric.** The moment it's a table, it's a leaderboard again and the mitigation is gone.
- Deep Lineage may allow *reading* a stave closely — a small earned intimacy, and a way to learn who someone was.

---

## The Threshold in detail

**Target vibe:** Barony's tactile grubbiness, Dark and Darker's huddled-at-the-mouth-of-hell staging, and **Diablo's Rogue Encampment** — which is the key reference, because it is *tiny*, dense, warm, and unforgettable. Tristram's power was never square metres; it was a handful of characters, a fire, and a guitar.

### Two layers (ADR-025)

**Camp momentum — shared, volatile.** Builds across successful runs; **a full-team wipe scatters it.** The Bound camp here because you are succeeding; when a party dies whole, they drift off.

What momentum affects — **all bonuses, never baselines:**

| Momentum grows | Effect |
|---|---|
| Population | More Bound camped, more chatter, more ambient life |
| Vendor stock | Better and deeper inventory at the Forge and the Lodge |
| Services | A healer arrives at ⟨tune⟩ 3 clean runs. A rune-carver at 5. They leave on a wipe. |
| The fire | Bigger, warmer, brighter |

> **Hard rule:** nothing *required* to play may live in momentum. Losing it must feel like the camp got colder, never like the game got harder — otherwise a wipe becomes punitive and breaks `PRO-005 §11`.

**The four campsites — personal, permanent.** One plot per party member, ringed around the fire. They grow with LINEAGE, they are customizable, and **they are never lost** — not to death, not to a wipe. Your stave (ADR-022) stands on your plot. In solo or a short party, empty plots are held by NPC Bound.

Customization axes, all earned through Lineage: shelter style and material · brazier and firelight · banners and marks · stave carving style · trophies from expeditions you've survived · ground dressing. Paid themes layer on top of this later (`PRO-006`) — but **the coolest thing in a camp should always be something you did, not something you bought.**

### The fire

A communal fire at the centre. The party gathers here; the ready-check happens here. A diegetic lobby rather than a menu.

**It is the Ashen Lodge's fire.** So walking from the fire to the Descent is, literally, walking away from the light (ADR-020, `DES-007`). Never stated, never pointed at. It's just where the door is.

### The Bound — simulated, authored, and doomed

> **DECIDED (ADR-027):** NPC Bound persist, remember you, and **die permanently.**

NPC Bound camp at the Threshold between your runs. They greet you by name, ask about the expedition you just came back from, complain about their Tithe. Over a lineage they become characters — Diablo's Cain and Charsi, but grubbier and on borrowed time.

#### Authored person, procedural life

Fully authored means everyone experiences the same deaths, and once you know Ingrith dies at lineage 12 it stops meaning anything. Fully procedural means template mush — **nobody grieves a generated backstory.**

So the same split we already use for contracts (`DES-007`) and Calamities (`DES-015`):

| Authored | Procedural |
|---|---|
| **Personality** — voice, temperament, opinions, speech rhythm, what they're afraid of | Name, class, where they came from |
| Dialogue lines with slots | What they're chasing, and why |
| Reactions to your deeds | Their run history — **which actually happened in your world** |
| Their manner of unravelling | Their Pact Rank, their Tithe, and **when they die** |

~8–10 authored personalities is enough to feel written, and the generated life around each one makes every player's camp different.

#### They are playing the same game you are

**This is the mechanism, and it's the whole idea.** Each NPC Bound has a Pact Rank that grows, a Tithe that escalates with it, and a simulated run record ticking over between your sessions. They take power. Their obligation rises. They go deeper to service it.

**Eventually the math catches them — exactly as it will catch you.**

So death isn't a timer or an authored beat. **They die because they got greedy**, on the same curve the player is standing on. The ones who climb fastest die soonest. It costs a few numbers ticking offscreen, and it makes ADR-020 a *system* rather than a mood.

#### You will see it coming, and you cannot stop it

The foreshadowing falls out of the simulation for free:
- Their stave grows faster (ADR-022).
- Their talk gets more confident. They mention a bigger tithe like it's good news.
- They ask to borrow something.
- They ask which expedition was richest — **and if you tell them, that's where they go.**
- Then their fire is out.

**Watching someone else do it is how a player learns to recognize the pattern**, and it puts them on the *outside* of the compulsion for once, which is the only vantage point from which it's visible. That's worth more than any amount of exposition.

Nothing announces the death. Their stave stops. Their plot goes cold. Their gear turns up in the Lodge's stock, which is grim and correct — and **a token from them can be taken for your camp** (`DES-016`, Memorial deeds), so your plot slowly fills with the belongings of dead friends.

After a while, a new Bound arrives and takes the empty plot. The camp cycles. It always has.

#### Saving one (ADR-028)

> **DECIDED:** **Rarely, at real cost, and never certainly.** You will not know whether it worked for some time.

**What it costs you** — all real, all things you wanted:

| Give | Cost |
|---|---|
| **Your Waystone** | You give away your own way out. The purest form of the thing (`DES-005`). |
| **Tribute value** to service their Tithe | Directly delays your own rank |
| **A lie** — tell them the rich expedition was somewhere else | Costs nothing material; costs their trust, and the information they'd have brought you |
| **Talking them down** | Requires actually knowing them — gated on having engaged over many runs, not on a resource |

**What you get.** The design rule here is that **the reward must not be fungible with what you gave up.** Trade tribute for tribute and players will compute it, and a moral act becomes a shop transaction. So every payoff is something you cannot buy:

**1. They keep running, and they keep telling you what they saw.**
A living Bound continues their simulated runs and feeds you **LINEAGE knowledge** over time — cartography, bestiary entries, rumours of where the vaults are. Lineage is power-free by construction (`DES-003`), so it can be generous without touching balance, and it is not purchasable at any price.

It is also quietly horrifying, which is why it's the right reward: **you saved them into continuing.** They go back down because you helped them. The theme bites the hand that fed it.

**2. They can appear in the Deep.**
The Bound already exist as an in-run archetype (`DES-013`). Someone you saved may turn up mid-expedition — unscheduled, unfarmable, and exactly when you're in trouble.

**3. They can carry your ember out.**
The single best payoff available in this design, and it costs almost nothing because the system already exists (`DES-012`). **The person you saved saves you** — your whole LIFE preserved by someone who is only alive because you gave away your Waystone six hours ago.

**Anti-farming guardrails:**
- **You cannot save the same Bound twice.** Not a renewable resource.
- **You don't learn whether it worked for several runs**, so the timing can't be optimized.
- Saving is rare and uncertain by design, and few Bound exist at once — the ceiling is low.
- **No Boon, no power, no gear, no Tithe relief.** All fungible, all would turn this into a strategy.

**And the game never comments on it.** No karma, no morality meter, no NPC telling you that you did a good thing (ADR-020, rule 2). It happens, and later something happens because of it, and the connection is the player's to make.

> **Cost note:** the simulation is cheap (numbers ticking offscreen), the in-Deep appearance reuses existing systems, but **the dialogue is a genuine ongoing writing cost.** This is M5 work, not M3 — keep it off the vertical-slice critical path (`PRO-001`).

### Vendors, and the Diablo shop loop

Rotating stock is one of the cheapest and most reliable "check in every run" hooks ever built, and Diablo proved it. Both vendors refresh per run cycle ⟨tune⟩:

- **The Deep-Kin Forge** — repairs, crafting, rune-work. Staffed by someone who resents what you do for a living.
- **The Lodge Quartermaster** — consumables, Waystones ⟨tune⟩, tools, extraction gear. Warm, competent, quietly sad about you.

Waystone availability here is a **major balance lever** (Q54) — if the Lodge reliably sells your escape, the pressure system softens considerably. Handle deliberately.

### Sound

Underweighted in most design docs and half of why Diablo's town is remembered. The Threshold theme should be the emotional anchor of the game: warm, sad, acoustic, and **the only safe sound in it**. Nordic instrumentation — tagelharpa, kantele, low humming, a lyre. The contrast between this and the Deep does more work than any mechanic.

Cheap. High impact. Prototype it early.

## Stations

**In your Chamber:** Her (tribute, the tree, the Tithe, the Legacy screen) · the Stash.

**In the Threshold:** the Contract Board · the Deep-Kin Forge · the Ashen Lodge fire · the Descent.

## The first sixty seconds

`DES-010` C1 stages onboarding one system per run. First visit shows **her and the Descent only** — the Threshold is nearly empty, the board bare, the forge cold. Systems light up as they become relevant, so the Lair *fills in* over the first hour. That doubles as progress the player can see.

## Open questions

> **DECIDED (ADR-050):** **Services** — but **only pure-convenience ones.** Never Waystones, never repairs. Losing momentum must feel like the camp got colder, never like the game got harder (`PRO-005 §11`).

> **DECIDED:** **Yes**, with the guardrails in `PRO-005 §10` — never the best source of anything, no near-miss theatre, bounded known pool, no pity timers, hard stock cap. Tone does the work: seedy and a little sad, not exciting.

> **DECIDED (ADR-027):** **Yes, permanently.** Authored personality, procedural life, and a simulated Pact Rank that eventually outruns them — they die of the same disease you have.

> **DECIDED (ADR-050):** **Yes — rarely and expensively.** Enough that a well-prepared player can buy an out; never enough to make the pressure system optional.

> **DECIDED (ADR-050):** **Yes** — further fused into the stone with each lineage, a long-horizon signal of what the pact is doing to her as well as to you.

> **OPEN (Q56):** If refusal is a real ending, it lives here. Where, and does the Threshold show it?
