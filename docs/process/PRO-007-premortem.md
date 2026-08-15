---
id: PRO-007
title: Pre-Mortem — How This Fails
status: accepted
owner: process
tags: [risk, premortem, scope, production, honesty]
updated: 2026-08-15
related: [PRO-001, DES-009, ART-005, TEC-004, DES-001]
---

# Pre-Mortem — How This Fails

Gary Klein's technique (*Performing a Project Premortem*, HBR 2007): **assume the project has already failed, then explain why.** It works because of **prospective hindsight** — imagining an event has already happened rather than might happen measurably improves risk identification, on the order of 30%.

The premise below is not *"could this fail."* It is: **it is two years from now and SHE was abandoned. What happened?**

Ordered by how likely each is to be the actual cause.

---

## 1. M1 never ended ⚠ most likely

Solo, no deadline, and combat feel is a bottomless pit. The controller got tuned, then re-tuned. The swing arc was never quite right. Eighteen months in there was an excellent first-person controller and no game.

**Why it's the top risk:** ADR-034 removed deadlines deliberately and correctly — but deadlines were also the thing that ended iteration. Nothing replaced them.

**Mitigation:**
- **"Decent unjuiced" is a *bar*, not an aspiration.** Two people who aren't you, ten minutes, want to keep playing. When that passes, **stop**, even if it could be better.
- **Timebox iterations, not the milestone.** Two weeks per pass; at the end, ship it forward or cut the feature.
- Return to combat feel **once**, at M4, with real assets. Not continuously.

## 2. The ink shader ate four months

It is critical path, it is novel, and novel shaders are notorious sinks. Boil, hatching, outlines, and the two-world inversion are **four hard things stacked**, and it was the thing most likely to be visually disappointing after enormous effort.

**Mitigation:**
- **Spike it in a weekend, on grey boxes, before M1 proper.** Outlines and boil only.
- **If it isn't ~70% convincing in that weekend, it is a research project, not a feature.** Fall back to flat quantised shading with simple outlines — which still looks deliberate and costs a fraction.
- Hatching and the two-world inversion are **separable later additions**, not prerequisites.

## 3. Scope. Six classes, five Aspects, three biomes, twelve enemies, one person

Systems-over-content helps, and modifiers multiply properly. But the *authored floor* is still enormous: 6 unique verbs, 6 Rite branches, ~107 skill nodes, 3 full environment kits, the Gullsjúkr, her, a full adaptive score.

**This is the most honest number in the document, and it is big.**

**Mitigation:**
- **The vertical slice must be a slice** (ADR-061 — see below). Two classes, one biome, all systems.
- **Nothing new until M4 clears its gate.** No new class, no new biome, no new mechanic, however good.
- Post-1.0 content was already designed as the class pipeline — **use it.** Ship four classes if six is what stands between the game and existing.

## 4. It was elegant and it wasn't fun

Every system reads beautifully on paper. Clamor, the Tithe, the ember, the Gullsjúkr, the staves, the three endings. But the entire edifice rests on one unproven sentence — *"I have enough, I should leave. One more room."* — actually feeling good moment to moment.

**Elegance is not fun, and this design has a lot of elegance.**

**Mitigation:** the M1 and M2 gates test exactly this and nothing else. **Take a failure seriously rather than explaining it away.** If a playtester never voluntarily abandons loot, the pressure system is wrong — and no amount of the rest of this corpus compensates.

## 5. Co-op solo-developed was 2× and it was the 2× that killed it

ADR-013 accepted the cost with eyes open. But QA on four-player emergent systems, alone, is genuinely brutal — the Gullsjúkr targeting the richest player, ember rescue, late-join world deltas, host migration, four lanterns of Clamor.

**The unsayable version, stated because a pre-mortem is where unsayable things belong:** *if co-op is what stops this shipping, solo-first with co-op post-launch is a real option.* The architecture supports it — pacts are individual and progression never touches the network.

That is **not** a recommendation to reverse ADR-008. It is a pre-authorised escape hatch, so the choice is available later without feeling like defeat.

## 6. There was no audience

Premium price, crowded genre (Dark and Darker, Tarkov, DMZ, Hunt), solo developer, **and no marketing plan anywhere in 38 documents.**

**This is a genuine gap, not a hypothetical.** Differentiation is strong — PvE-only, the ink shader, the theme, no microtransactions — but differentiation nobody sees is not differentiation.

**Mitigation:** the ink shader is the marketing asset. It is *screenshot-legible*, which is rare and valuable. **Start posting development shots the moment it works.** A devlog costs an hour a week and is the only distribution a solo premium title realistically gets.

## 7. Documentation became the project

38 documents, 60 ADRs, zero lines of engine code. The corpus kept improving and the game never started.

**Mitigation:** already flagged repeatedly. **The design is locked. Further planning now requires an ADR justifying why it could not wait until after M1.**

## 8. Burnout

Solo, no deadline, multi-year horizon, and a theme about compulsion that demands sustained emotional engagement.

**Mitigation:** the milestone gates are also *rest points*. Clearing one is permission to stop for a while. And the LIFE/LINEAGE structure that makes it safe for players to walk away applies to the developer too — nothing here decays if left alone.

## 9. The theme got preachy, or the door read as a bug

`ADR-020` rule 2 already forbids the first. The second is a real production risk: **a game that quits itself is indistinguishable from a crash unless the sequence is unmistakably authored.**

**Mitigation:** the door gets deliberate, slow, unambiguous staging — and it ships late, when there is time to make it right.

---

## What this changes

Three concrete actions, taken now:

1. **ADR-061** — M4 rescoped to an actual vertical slice.
2. **The shader weekend spike** happens before M1 proper, with an explicit fallback.
3. **A devlog** starts when the shader works.

## Re-run this

A pre-mortem is not a one-time ritual. **Re-run it at each milestone gate** — the failure modes change as the project does, and the ones that matter at M3 are not the ones on this page.

**Sources:** [Klein, *Performing a Project Premortem* (HBR 2007)](https://nesslabs.com/pre-mortem-anticipate-failure-with-prospective-hindsight) · [Vertical slice definitions and solo-dev scope](https://ltpf.ramiismail.com/prototypes-and-vertical-slice/)
