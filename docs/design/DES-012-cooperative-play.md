---
id: DES-012
title: Cooperative Play
status: accepted
owner: design
tags: [co-op, multiplayer, scaling, social, networking, retention]
updated: 2026-08-17
related: [DES-002, DES-003, DES-011, TEC-001, TEC-004]
---

# Cooperative Play

> **DECIDED (ADR-008):** Co-op is **core, designed from the start**. Target 1–4 players, with **2 and 4 as the primary experiences**. Solo is fully supported, never an afterthought, and never balanced as "4-player content with fewer people."

This is a structural decision, not a feature. It changes the architecture (`TEC-001`, `TEC-004`), the milestones (`PRO-001`), and the balance of nearly every system. It's also the single strongest retention lever available (Relatedness, `PRO-005 §4`) — co-op games retain dramatically better than solo ones because the commitment is social as well as personal.

## The core question: whose pact is this?

**Every player has their own pact with her.** Parties are temporary; the relationship is personal.

- **Loot is individual.** You pick it up, it's in your bag, it's your weight and your risk. No shared party inventory.
- **Tribute and Boon are individual.** Your Tithe is yours. Your skill tree is yours. Your Legacy is yours.
- **The dragon speaks to each of you separately** — and under ADR-021 this is literal: **each player has their own private Chamber**, never entered by anyone else. The shared hub is the **Threshold** outside it. Solo and co-op have identical flow; the only difference is whether anyone is standing in the Threshold. See `DES-014`.
- **Contracts can be shared or personal** — see below.

This keeps `DES-003` intact without modification, avoids loot-drama entirely, and is thematically exact: she binds *souls*, not parties. It also means a veteran and a newcomer can play together without either one's progression being distorted.

## Vörðr — the dead keep playing (ADR-024)

Barony's best social idea is that dead players stay in the level as ghosts with small useful powers, instead of watching a spectator camera. We take it, and add a decision to it that no extraction game has tried.

> **Partly built at `M2-T05` (ADR-092).** *Wait* is real — you go down, you bleed out, your ember drops and a friend can carry it. **Return is absent, not approximated**: walking back in with nothing requires a LIFE to end, and that arrives with `M3`. So does the Vörðr's utility (scout marks need the ping system, `M4-T05`). Until then a fallen player's body stays where it fell rather than becoming a ghost with nothing to do.

**On death you become a Vörðr** — your ward-spirit, briefly loose. Mobile, safe, unable to fight or carry. Minor utility ⟨tune⟩: scout ahead without risk, mark what you find for the living, unnerve enemies slightly. **The point is that a dead player is still playing**, still talking, still contributing — which is the whole reason Barony's ghosts work.

From there, **two exits, and they are mutually exclusive:**

| | **Wait** | **Return** |
|---|---|---|
| What happens | A teammate carries your ember out | You walk back in with nothing |
| Your LIFE | **Survives** — tree, stash, rank intact | **Over.** Fresh life, rank 1, empty hands |
| Your run | Ends | Continues |
| Your ember | Carried | **Extinguished** |

**This is the decision, and it's a good one:** give up on your friends saving you, in exchange for playing *right now*. It's a loss-aversion problem (`PRO-005 §1`) with a social face — returning can read as impatience, or as mercy, since your ember is heavy and loud and carrying it makes their extraction materially worse.

### The two rules that keep it from breaking

**1. Returning extinguishes your ember.** You cannot return *and* be rescued. Choosing to come back is choosing that the death is final. Without this rule, ADR-004 collapses and death costs nothing.

**2. The returned arrive at the floor entrance, never at the party.** She spends full power opening a gate for a *new* soul (ADR-016) — but a soul she just lost gets put back at the door. So returning means **a naked rank-1 crossing a scaled floor alone** to rejoin. Costly, tense, and it forces the party to decide whether to come and get you.

**Why this doesn't weaken death:** your LIFE is wiped either way. ADR-004 is untouched. What you no longer lose is *the rest of your evening* — a retention win at zero balance cost. And rescue stays strictly better when it's available, since it saves the entire tree, so neither option dominates.

**Solo:** the same, minus the wait. With nobody to carry your ember, it's return or end the run — which makes solo death heavier than co-op death, correctly.

> **DECIDED (ADR-050):** **A visible, shortening window** ⟨tune⟩. Your ember is going out whether you choose or not, so the decision is forced by the fiction rather than by a UI timer.

## Bear My Ember Out — death and rescue

The hardest problem co-op creates: ADR-004 wipes your LIFE on death, and in co-op you can die to a teammate's mistake. Unmitigated, that's a friendship-ending mechanic.

**The three-stage answer:**

1. **Downed.** Taken to zero health, you go down — crawling, bleeding, unable to fight. A teammate can revive you in the field at a real cost (time, exposure, noise).
2. **Ember.** Bleed out and you die *for the run* — but your **ember**, the piece of her fire she gave you, drops where you fell. A teammate can carry it. **It is heavy and it is loud.**
3. **Carried out.** If your ember reaches an extraction point, **your LIFE survives.** You lose the run, your carried loot, and take a Scar — but your skill tree, stash, and Pact Rank are intact. If nobody carries it out, you die properly and the Legacy screen follows.

> **BUILT AT `M2-T05` (ADR-092), and the ember is an `ItemResource`.** Not a special-cased object with hand-tuned penalties — `con_ember` goes in the bag, so the sacrifice **falls out of systems already built**: it costs 2×3 squares against the grid, 12 kg against `CarriedWeight`, and 5.5 clamor against the carried floor. Measured on a rescuer: **3.40 → 2.94 m/s, and silent → audible from 2.2 m standing still.**
>
> Two consequences worth stating. The ember can be **put down** — the design never forbids it, and the sacrifice is real precisely because it can be abandoned partway home. And it is *disturbed* gold by ADR-089's rule, so **the Gullsjúkr will stop for it**: the thing that would buy you seconds is your friend.
>
> **Whose is that? (ADR-094.)** **Every ember looks the same**, deliberately. It is *her* fire, not yours — four colours would make four team markers, which is player-identity UI wearing a diegetic costume, and it would contradict the sentence the object is built from. ADR-093 tried the coloured version and it was reversed.
>
> Nothing is lost, because the question is already answered without UI: **you know whose it is because you watched them fall there.** What the ember carries is a **tag** (`bound_to`), and the tag is mechanical rather than decorative — *an ember saves the person it names and nobody else*. Carrying someone else's is inert cargo; it will not save you and it will not stand in for the one you should have picked up. The bag names the bearer in text for a rescuer holding two.
>
> *"Your LIFE survives"* names a tree, a stash and a rank that arrive at `M3`. Carrying an ember out therefore **reports** the life saved today; `M3-T05`'s Legacy screen reads it. What is real is the mechanism, which is what the co-op gate is about.

Why this is good:
- It converts the harshest mechanic in the game into **the most heroic thing a friend can do for you.**
- The ember's weight and noise mean rescue is a genuine sacrifice — the rescuer's own extraction gets materially worse. That's a real decision, not a free revive.
- It gives co-op an emotional peak that solo cannot have (peak-end rule, `PRO-005 §2`).
- **Solo equivalent needed** — see OPEN below.

## Scaling: co-op is safer per person, and worse per person

The classic co-op failure is that 4-player becomes the optimal farm and everyone abandons solo. The fix is that **party size trades safety for yield and pressure**, deliberately:

| Scales with party size | Direction | Rationale |
|---|---|---|
| Enemy density & elite frequency | ↑ near-linear | Keeps combat meaningful |
| **Loot quantity** | **↑ sub-linear** ⟨tune⟩ | Per-capita yield *drops* with party size — you're splitting a floor |
| **Clamor generation** | **↑ super-linear** ⟨tune⟩ | Four bodies are far more than twice as loud as two |
| Hunt escalation rate | ↑ with Clamor | Follows naturally from the above |
| Extraction point count | flat | Everyone converges on the same doors |
| Contract objective count | ↑ modest | More hands, more threads (`DES-007`) |

**The resulting shape:** a 4-player run is *safer moment to moment* and *far more hunted*, with *less loot each*. A solo run is lethal, quiet, and lucrative. **Neither dominates** — they're different games, and a player should choose based on mood and on who's online, not on efficiency.

This is the most important balance relationship in co-op and it needs early instrumentation (`DES-010` metrics): per-capita extracted value by party size, tracked from the first playable build.

## Mixed-rank parties

> **DECIDED (ADR-010/011).**

**The floor scales to the highest Pact Rank present.** A rank-9 player brings a rank-1 friend into a rank-9 floor.

The reasoning is that **in co-op, boredom is worse than danger.** Scaling to the average or the lowest wastes the veteran's session *and* breaks their Tithe math — they cannot service an escalated obligation on trivial floors, so playing with a new friend would actively cost them. Scaling up terrifies the newcomer, but they have a protector, and the ember rescue already makes being outmatched survivable rather than terminal. Overwhelmed-alongside-a-friend beats bored-alongside-a-friend.

Rank-banding was rejected outright: a system that prevents friends from playing together defeats the point of ADR-008.

**The real danger is not lethality — it's the Tithe coupling.** A carried player extracts rank-9 value at rank 1. Unmitigated, they'd be power-levelled through the tree without earning it, and the design's central self-balancing property (`PRO-005 §3`) would break. So:

- **Boon conversion is capped by your own Pact Rank.** Value beyond that converts at a steeply decaying rate ⟨tune⟩.
- **The overflow becomes LINEAGE**, which is power-free and can be paid out lavishly (ADR-006).
- Net effect: **you can be carried, but not past your own ability to use what you're given.** A carried player advances quickly in *knowledge* and slowly in *power* — the correct shape, and it means veterans helping newcomers is socially rewarded without being an exploit.
- The carried player's **Tithe does not inflate** from playing above their rank, so they're never left with an obligation they can't service alone.

**Consequences to accept:** low-rank players will be downed constantly. That is expected, not a bug — and it self-limits the "carry meta," because high floors demand mechanical knowledge (Hunt behaviour, hazard reading) that no amount of borrowed gear substitutes for. All difficulty tuning must assume any floor may contain a wildly under-ranked player.

**Telemetry to watch:** if carried players consistently out-rank their demonstrated competence, tighten the Boon decay before touching anything else.

## Friendly fire

**Direct damage: off.** Griefing and accidental swings in a melee game with four people in a corridor is misery.

**Environmental: on.** You absolutely can drop a chandelier on your friend, collapse a floor under them, or shove them into a pit. This preserves the slapstick physicality that makes Barony memorable (`DES-009`) while removing the frustrating case. Environmental deaths are *funny* and *attributable*; a stray sword swing is neither.

**Shove works on allies** — and is essential to `Húskarl` play (pushing an ally out of a trap) as well as to comedy.

## Contracts in co-op

- **Party contracts** — accepted together, completed together, everyone rewarded. The default.
- **Personal contracts** — your own Pact objectives, which nobody else shares. Creates the good kind of social friction: *"I need one more thing before we go."*
- **Rival objectives** — occasionally two players' contracts genuinely conflict. Rare and opt-in; when it fires it should be a story, never a betrayal system.

The DMZ lesson holds: **being overcommitted together** is the fun. Four players with nine objectives between them and one closing exit is the game at its best.

## Communication as a mechanic

Because Clamor is the central system, **voice comms are diegetically interesting** — talking is how you coordinate, and the game is about being quiet. We won't punish real voice chat (that's hostile), but in-game signalling should be built for it:

- **Ping system** — mark loot, enemies, routes, extraction. Essential; build early.
- **Silent gestures** for stop / go / danger / regroup.
- **Shared map marks** feeding the Lineage cartography.

## Session model

- **Private lobbies and friend invites first.** Drop-in matchmaking is a much larger problem (`TEC-004`) and can follow.
- **Host-authoritative peer-to-peer.** No dedicated servers — the cost is not defensible for a premium PvE game.
- **Host disconnect = forced extraction, not a wipe.** Everyone keeps what they were carrying. Punishing players for someone else's router is the fastest way to lose a community.

## Solo parity

Solo must be a first-class way to play, not a handicap:

- Enemy density, loot, and Clamor all scale down properly (above).
- Every class is solo-viable (`DES-011` rule 1) — the Skald is the open problem.
- The ember rescue needs a solo analogue so downing isn't strictly worse alone. **Proposal:** solo players get a single self-recovery per run ⟨tune⟩ — you crawl to a shrine or burn a consumable. Rarer and more desperate than a friend's hand, which is correct.

## Open questions

> **DECIDED (ADR-016):** **Yes.** A player waiting in the Threshold opens a gate at the party's current position and walks out of the dark next to them — no menu, no teleport-in. Built on the extraction mechanism run backward (`DES-005` Layer 3b, `TEC-004`).
>
> Removes the worst friction in co-op sessions: a friend who gets home late can still play with you tonight. **Costs:** the arriving player brings no accumulated loot, and **opening a gate is a loud Clamor event** — so "call them in here, or push somewhere quieter first?" is a real tactical question.

> **DECIDED (ADR-050):** **One pact, regardless of who you play with.** Splitting solo and co-op progression would double the surface for no benefit.

> **DECIDED (ADR-010/011):** Floors scale to the **highest** Pact Rank in the party. No rank gating — any two players may always play together. Boon is capped by *your own* rank, with overflow paid as Lineage.

> **DECIDED (ADR-050):** **Once per run, costly, and never better than having a friend.** Rarer and more desperate than a hand up, which is the correct relationship.
>
> **Built at `M2-T05`.** Self-recovery returns ⟨tune⟩ 22% health against a friend's 40%, and it is gone for the rest of the run. `--ember-probe` asserts all three: that it works, that it returns less than full, and that a second attempt is refused.
