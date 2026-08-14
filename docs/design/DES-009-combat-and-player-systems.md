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

> **OPEN:** Grid + weight may be one constraint too many. Fallback is weight-only with a silhouette showing what's on your back. Prototype both at M2; this is a feel question, not an argument to settle on paper.

## Magic

Small at 1.0, and deliberately not a parallel combat system.

**Runes** — inscribed, single-use or charge-limited, found not built. Loud, dramatic, situational: shatter a wall, freeze water, call light, silence an area. They read as *tools* rather than as a spellbar, which keeps them from competing with melee for design attention.

The Cinder and Maw Aspects (`DES-004`) are where sustained magical identity lives, so baseline magic can stay light.

> **OPEN:** Is there a mana/ember resource at baseline, or are runes purely consumable? Consumable-only is cheaper, keeps magic special, and avoids a second combat economy. **Leaning consumable-only at baseline**, with Cinder introducing Ember as a build-specific resource.

## Movement

Grounded and physical. Walk / sprint / crouch, mantling, ledge-hanging, real fall damage. Vertical traversal matters in the Delvings (`DES-006`).

- **Weight is felt everywhere:** acceleration, top speed, jump height, mantle ability, stamina, footstep volume. One number the player can *feel* in their hands.
- **Crouch is a real stealth verb** — significant Clamor reduction, meaningful speed cost.
- **No parkour, no wall-running, no dodge-roll.** Mobility is earned through the Wing Aspect, not given as a baseline.

## Stealth

Not a stealth game, but avoidance must be genuinely viable or the thesis is a lie.

Built on **the same Clamor field the Hunt uses** (`TEC-001`) — one system, two consumers, which is the right kind of economy. Light matters as much as sound: carrying a lantern makes you visible, and darkness is a resource you spend by lighting it.

**No stealth meter, no cones on a minimap.** Diegetic feedback only: enemies visibly pause, turn, investigate, call out. The player learns the system by watching it behave.

## Open feel questions for M1

> **OPEN:** First-person only, or does third-person exist? First-person is better for tension and cheaper (no full-body animation set). Strongly lean **first-person only** — but co-op players like seeing each other, so character models still need to look right from outside.

> **OPEN:** How lethal? Can 2–3 hits from a common enemy kill a fresh player? Lethality sells the thesis, but pairs badly with a stash wipe on death (ADR-004). Lean **high lethality, telegraphed heavily** — deaths must be legible (Principle 4).

> **OPEN:** Does the player have a persistent character stat block (STR/DEX-style, Barony), or is all differentiation from gear and Aspects? Lean **no stat block** — Aspects plus gear already cover build identity, and a third axis makes balance much harder.
