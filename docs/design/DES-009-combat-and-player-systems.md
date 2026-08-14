---
id: DES-009
title: Combat, Movement & Player Systems
status: proposed
owner: design
tags: [combat, movement, feel, vitals, inventory, gameplay]
updated: 2026-08-12
related: [DES-005, DES-007, DES-008, PRO-001]
---

# Combat, Movement & Player Systems

This is the M1 gate (`PRO-001`). If this layer isn't enjoyable in a grey box with one enemy, nothing above it matters.

## Thesis correction (ADR-053)

> The original framing — *"combat should usually be a bad idea"* — was **strategically right and tactilely wrong**, and taken literally it would produce a large system nobody enjoys touching.
>
> **The correction: combat is a temptation with a price. Exactly like loot.**

If fighting feels bad, two things break at once. Players **resent** being pushed into it, and — worse — **choosing not to fight stops costing anything.** A refusal is only meaningful if the thing refused was attractive.

Greed works in this game because treasure is genuinely desirable *and* genuinely expensive. **Combat must be built the same way:** satisfying enough that walking past a fight is a real sacrifice, costly enough that walking past is often correct.

So everything below about cost, avoidance, and Clamor stands. What changes is that **feel is not optional polish here — it is what makes the strategic layer function.**

## The thesis: combat should usually be a bad idea

Most action games make fighting the reward. **We can't**, and shouldn't try.

Fighting is loud (`DES-005` Clamor), costs durability, costs health that does not come back, costs consumables that are scarce, and costs *time* against the Hunt. In a game where the core sentence is *"I have enough, I should leave,"* every fight is greed of a different flavour.

So the design goal is **not** "make combat awesome." It is:

> **Make combat a costly option the player sometimes chooses, and make choosing it feel deliberate rather than forced.**

That single position resolves a dozen downstream questions. It's why avoidance must be viable, why the Wing Aspect is a real build and not a gimmick, why enemies don't drop meaningful loot (`DES-008` — Glitter is in the world, not in corpses), and why we don't need Mordhau-grade melee mechanics.

**It also has to be true in the numbers, not just the fiction.** If killing a room is the fastest path to a full bag, players will kill the room and the whole design collapses. Testable rule: *clearing a floor of enemies must be worth less than looting it quietly.*

## Combat feel: weighty, committal, physical

**Reference:** *Dark Messiah of Might & Magic* for physicality, *Hunt: Showdown* for lethality and deliberation, *Barony* for systemic mess. **Not** *Mordhau* (skill-ceiling arms race we can't support or balance against AI) and **not** Souls-style i-frame rolling (rewards reflex over decision — violates Principle 3).

**Attacking**
- Wind-up → swing → recovery. Attacks **commit**; you cannot cancel out of a heavy.
- Light (fast, low stagger, quiet-ish) vs. heavy (slow, staggers, loud).
- Weapon arcs are real and hit the world — swing a poleaxe in a corridor and you hit the wall. Space is a weapon stat.
- **Every swing has a Clamor value.** Blunt weapons are loudest. This is the main combat↔pressure coupling.

**Defending**
- **Block** with weapon or shield, costs stamina, reduces damage, doesn't negate it.
- **No dodge-roll, no i-frames.** Defense is *positional*: spacing, cover, terrain, doorways, retreat. Movement is defense.
- A short directional **step/lunge** exists for spacing, not for invulnerability.

**Physicality — the Barony inheritance, and our cheapest source of delight**
- **Kick/shove** is a core verb bound to its own key. Creates space, staggers, and puts things into pits, spikes, and water.
- **Throw anything.** A pot, a torch, a coin purse, your weapon. Throwing loot is also the primary Hunt-misdirection tool (`DES-005`).
- **Hazards are universal.** Traps, fire, water, and falls apply identically to enemies. Enemies of hostile factions fight each other.
- **The environment is destructible where it matters** — braced beams, rotten floors, oil, dammed water, chandeliers.

This cluster is where the game gets its personality, and it's disproportionately cheap: physics and shared hazard rules generate emergent stories at near-zero content cost (Principle 5).

**Damage triangle** — cut / pierce / blunt against unarmoured / mailed / plated. Legible RPG texture without a stat ladder (`DES-008`). Learning it is Lineage-tier knowledge: your bestiary records what worked.

---

## How to make simple combat feel good

Researched rather than asserted. Three findings drive everything here.

### 1. Swink's ordering — and it is a production rule, not a theory

Steve Swink's *Game Feel* frames it as three layers, **in strict order**: **real-time control** → **a simulated space that behaves predictably** → **polish that amplifies what is already working.**

The operative word is *amplifies*. **Juice cannot rescue bad control — it can only mask it, briefly.**

> **M1 discipline: the grey box must feel decent with no juice at all.**
> Get the controller, the hit detection, and the weight right *before* adding a single particle or shake. If it feels bad unjuiced, adding feedback hides the problem long enough for us to build a whole game on top of it.

### 2. The three feedback features that actually matter (empirical)

*"What Features Influence Impact Feel?"* (IEEE GEM 2022) analysed Steam player reviews across the best- and worst-rated action games using an NLP model, testing a framework of **19 impact-feedback features**. Three came out as dominant:

> **Hitstop · sound coherence · camera control.** Neglecting *any one* of the three significantly diminishes player satisfaction with combat feedback.

That is an unusually actionable result for a solo project — it says where to spend, and by omission, where not to.

**Hitstop** — freeze both attacker and target for a few dozen milliseconds at the frame of impact. The pause sells the collision as something that *cost energy*.
- Scale with weapon weight: dagger ~40 ms, hammer ~120 ms ⟨tune⟩.
- **Cheapest impact win available.** Near-zero implementation cost, enormous perceived difference.
- **Co-op rule: hitstop is a client-side visual effect only.** It must never pause simulation, or hosts and clients desync (`TEC-004`).

**Sound coherence** — the hit must *sound like what it looked like*: the material struck, the weapon's weight, whether it met flesh, mail, plate, or stone. Layered, not a single sample.
- **This does double duty here.** Combat sound is also **Clamor** (`ART-002` — diegetic sound is gameplay). Our impact audio is simultaneously juice *and* a gameplay signal, which is a rare efficiency.

**Camera control** — with a **first-person caveat that overrides the general advice.**
- **Rotational screen shake in first person causes motion sickness.** Use **positional kick** — a small translation — never rotation.
- **In first person the hands and weapon carry the impact, not the camera.** The arm animation absorbing a blow does more than any shake, and costs no comfort.
- Must remain **independently adjustable** for accessibility (`DES-018`).

### 3. Attack anatomy, and the 250 ms floor

Every attack has three phases: **Anticipation (windup) → Active (the strike) → Recovery.**

- **Anticipation** must be unique in shape and pose, and hint at *which* attack is coming. This is the telegraph.
- **Active** should read as instant, unambiguous, exaggerated for clarity over realism.
- **Recovery** exists to give the player a window — to counter, reposition, or disengage. It is not dead time; it is the reward for reading correctly.

**The hard number:** human visual reaction time is roughly **250 ms**, before any decision-making or input actuation. The minimum readable telegraph is therefore *reaction time + input time + a difficulty buffer*.

> **Rule: no enemy attack has a telegraph under 250 ms. Standard attacks sit at 400–600 ms** ⟨tune⟩; heavy, deadly attacks longer still.

This is not generosity — it is **Principle 4** with a number attached. An attack faster than human reaction time produces a death the player cannot explain, which `PRO-005 §5` identifies as the attribution failure that makes people quit rather than retry.

### 4. Forgiveness — invisible, and it decides whether the game feels responsive

Identical mechanics feel wildly different depending on systems the player never sees:

- **Input buffering.** Attacks queued during recovery frames fire on the first legal frame. Without this, a committal system reads as *unresponsive* rather than *weighty*.
- **Coyote time** on ledges and mantles.
- **Generous hit volumes on the player's swing, tight ones on incoming attacks.** Standard practice, invisible, and it makes the game feel fair.
- **Latency budget:** input-to-visual response above ~100 ms is perceptible. Committal animation is fine; a delayed *start* is not.

### 5. Where the depth comes from

The brief was *fun and engaging, even if simple.* Simple is achievable and correct — but only if depth lives somewhere.

> **Depth comes from the situation, not from the input.**

Our button count stays tiny: attack, heavy, block, shove/kick, throw. The depth is **already designed elsewhere**:

- Terrain, doorways, ledges, and drops (positional defense — no dodge-roll)
- Hazards that apply to everyone
- **Enemy factions that fight each other** (`DES-013`)
- Throwables, including your loot
- Weight and stamina changing how you move as you get rich
- Clamor making every swing a strategic cost

**Reference: *Dark Messiah*.** Its attacks are simple; the *environment* is the depth. **Vermintide/Darktide** is the other model — a handful of inputs, enormous feel investment, and it plays beautifully. Neither needed a move list.

### What we are explicitly not building

- **No combo strings or move lists.** Depth is situational.
- **No parry requiring reaction-speed timing.** That rewards reflex over reading, violating Principle 3.
  - *Proposal ⟨tune⟩:* a **generous block window (~300 ms)** that opens on a correctly-read telegraph — testing **attention, not hand speed**. Learnable, satisfying, and it does not become a skill-ceiling arms race.
- **No damage numbers.** (`DES-019` — no numbers during a run.)
- **No hit-scan precision requirements.** Melee volumes are forgiving.

### M1 test protocol

In order, per Swink:

1. **Unjuiced grey box.** One weapon, one enemy. Does swinging and connecting feel decent with zero feedback layers? **If no, fix control before proceeding.**
2. Add **hitstop** alone. Measure the difference — it should be large.
3. Add **layered impact sound**.
4. Add **positional camera kick** and weapon/arm reaction.
5. Add everything else — particles, decals — last, and sparingly.

**The gate question is not "is this deep?" It is: does a tester voluntarily swing at something they could have walked past?** If yes, combat is tempting, and the strategic layer above it will work.

## Vitals

**Health does not regenerate.** This is the most important single decision in this document after the thesis.

- Healing is a **scarce, slow-to-apply consumable**. You cannot safely heal mid-fight.
- Therefore every point of damage is a permanent resource loss for the run, and **damage taken becomes extraction pressure on its own** — "I'm at 40% and out of bandages" is a reason to leave that has nothing to do with a timer. Free pressure, deeply thematic, no systems required.

**Stamina** governs swinging, blocking, sprinting, and climbing. Reduced by carried weight (`DES-005`). The moment a player notices their stamina bar shrinking as their bag fills, the core loop has taught itself.

**Wounds** — a small set of legible, specific injuries from heavy hits, falls, and traps. Not a limb-health simulation.

| Wound | Effect | Treatment |
|---|---|---|
| Gashed leg | Slower, louder, stamina drain | Bind (field, slow) |
| Broken arm | No two-handing, no blocking | Splint (field) or Lair |
| Concussed | No map, muffled audio, blurred edges | Time or Lair |
| Bleeding | HP drain until treated | Bind immediately |

Wounds are **run-scoped**; extracting while wounded converts one into a **Scar** (life-scoped, `DES-003`) ⟨tune⟩. That gives the "extract wounded" outcome in `DES-002` real teeth.

**No hunger clock.** Barony has one; for a 20-minute run it would be friction that generates no decisions. Cut.

## Inventory & the greed puzzle

The inventory screen is where the game's central question gets asked, so it must be **tactile and spatial**, not a list.

**Proposal: a modest grid (Resident Evil 4 attaché case), plus weight.** Two constraints that conflict — bulky-but-light bedrolls versus small-but-crushing coin — so "what do I leave behind" becomes a physical puzzle you can *see*, and dropping something is a visible, satisfying act.

- **Quick-drop** must be one key, usable while running, no menu. Panic-dumping loot to outrun the Hunt is a headline moment (`DES-005`) and cannot be buried in UI.
- Equipped weapons/tools occupy real slots. The lantern competes with a weapon.
- Looting a container is **not instant** — a short, interruptible, *audible* action. Looting under pressure is a decision.

> **DECIDED (ADR-040):** **Grid + weight, real-time, no pause.** Both constraints kept — they conflict deliberately. Co-op makes pausing impossible anyway, so opening your bag is a vulnerable act *by design*. Grid dimensions and cell sizes remain tuning work (`DES-019`).

## Magic

Small at 1.0, and deliberately not a parallel combat system.

**Runes** — inscribed, single-use or charge-limited, found not built. Loud, dramatic, situational: shatter a wall, freeze water, call light, silence an area. They read as *tools* rather than as a spellbar, which keeps them from competing with melee for design attention.

The Cinder and Maw Aspects (`DES-004`) are where sustained magical identity lives, so baseline magic can stay light.

> **DECIDED (ADR-048):** **Consumable-only at baseline** — no mana bar for anyone. **Cinder alone** converts magic into a system via **Ember**, drawn from carried tribute (`DES-004`'s *Emberdebt*): burn your loot to burn your enemies. Keeps magic scarce and special for everyone, and gives Cinder a real identity rather than a damage-flavour path.

## Movement

Grounded and physical. Walk / sprint / crouch, mantling, ledge-hanging, real fall damage. Vertical traversal matters in the Delvings (`DES-006`).

- **Weight is felt everywhere:** acceleration, top speed, jump height, mantle ability, stamina, footstep volume. One number the player can *feel* in their hands.
- **Crouch is a real stealth verb** — significant Clamor reduction, meaningful speed cost.
- **No parkour, no wall-running, no dodge-roll.** Mobility is earned through the Wing Aspect, not given as a baseline.

## Stealth

Not a stealth game, but avoidance must be genuinely viable or the thesis is a lie.

Built on **the same Clamor field the Hunt uses** (`TEC-001`) — one system, two consumers, which is the right kind of economy. Light matters as much as sound: carrying a lantern makes you visible, and darkness is a resource you spend by lighting it.

**No stealth meter, no cones on a minimap.** Diegetic feedback only: enemies visibly pause, turn, investigate, call out. The player learns the system by watching it behave.

## Resolved since writing

> **DECIDED (ADR-047):** **First-person everywhere**, including the Lair. No third-person camera at all — it would let players peek around corners without exposing themselves, which quietly breaks the awareness ladder, stealth, and the Veiðimaðr. Character models are still needed for co-op: you see your *teammates*, never yourself.

> **DECIDED (Q22):** **No stat block.** Aspects plus gear cover build identity; a third axis would make balance materially harder.

## Open feel questions for M1

> **OPEN:** How lethal? Can 2–3 hits from a common enemy kill a fresh player? Lethality sells the thesis, but pairs badly with a stash wipe on death (ADR-004). Lean **high lethality, telegraphed heavily** — deaths must be legible (Principle 4).

*(Both remaining items are M1 prototype questions — the build answers them, not the document.)*
