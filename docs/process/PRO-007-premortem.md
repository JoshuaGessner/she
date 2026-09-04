---
id: PRO-007
title: Pre-Mortem — How This Fails
status: accepted
owner: process
tags: [risk, premortem, scope, production, honesty]
updated: 2026-09-04
related: [PRO-001, DES-009, ART-005, TEC-004, DES-001]
---

# Pre-Mortem — How This Fails

Gary Klein's technique (*Performing a Project Premortem*, HBR 2007): **assume the project has already failed, then explain why.** It works because of **prospective hindsight** — imagining an event has already happened rather than might happen measurably improves risk identification, on the order of 30%.

The premise below is not *"could this fail."* It is: **it is two years from now and SHE was abandoned. What happened?**

Ordered by how likely each is to be the actual cause.

---

## 1. M1 never ended ⚠ most likely

> **RE-RUN AT THE `M3` GATE (ADR-191): the milestone changed, the mechanism did not.** `M1` ended. **`M4` is where this risk now lives**, and it is a better host for it: `M1` had five tasks, `M4` has seventeen open rows across two halves and every one of them is defensible. A milestone large enough to always contain something worth doing is a milestone you never have to leave.

Solo, no deadline, and combat feel is a bottomless pit. The controller got tuned, then re-tuned. The swing arc was never quite right. Eighteen months in there was an excellent first-person controller and no game.

**Why it's the top risk:** ADR-034 removed deadlines deliberately and correctly — but deadlines were also the thing that ended iteration. Nothing replaced them.

**Mitigation:**
- **"Decent unjuiced" is a *bar*, not an aspiration.** Two people who aren't you, ten minutes, want to keep playing. When that passes, **stop**, even if it could be better.
- **Timebox iterations, not the milestone.** Two weeks per pass; at the end, ship it forward or cut the feature.
- Return to combat feel **once**, at M4, with real assets. Not continuously.

> **The timebox has never been applied, and that is the finding.** It is written above and nothing measures against it. `M4·A` now carries an explicit order (ADR-190) precisely so the two-week rule has something to be late against: **`M4-T01` → `M4-T16` → the stranger session → `M4-T20` → the rest.** A pass that overruns two weeks ships forward or gets cut; that is the sentence, and it applies to `M4-T01`'s remaining two steps first.

## 2. The ink shader ate four months

It is critical path, it is novel, and novel shaders are notorious sinks. Boil, hatching, outlines, and the two-world inversion are **four hard things stacked**, and it was the thing most likely to be visually disappointing after enormous effort.

**Mitigation:**
- **Spike it in a weekend, on grey boxes, before M1 proper** (`M1-T09`). Outlines and boil only.
- **If it isn't ~70% convincing in that weekend, it is a research project, not a feature.** Commit to flat quantised shading with simple outlines — still deliberate-looking, a fraction of the cost — and **do not keep the ink path alive alongside it.** One choice, made once at the gate (ADR-064).
- Hatching and the two-world inversion are **separable later additions** (`M4-T08`), not prerequisites.

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

> **RE-RUN AT THE `M3` GATE (ADR-191): this is now the risk being actively realised, not the one being guarded against.**
>
> Two independent play sessions have reported a version of it — *"there is still not enough gameplay mechanic or level depth to test any of our gates or real flow"* (ADR-165) and *"the gameplay feels a little stale still"* (`M4-T16`). **Both were answered with a resequencing and a decision record.** ADR-165 reordered `M4`; ADR-189 reordered an argument about the interface. Neither answer was more game, and there was no playtest between them.
>
> A resequence is not an explaining-away. **Two in a row with nothing played in between is the same thing arriving by instalments**, and the mitigation above is one sentence long for a reason.
>
> **What changes:** the stranger session is run as soon as `M4-T16` lands rather than at the end of `M4` (ADR-190). Its four clauses need two depth tasks and zero interface work, which makes it the cheapest evidence available about whether any of this is fun — and the count that matters is that **every gate testing fun is still `pending` while the corpus is 42 documents and 191 ADRs.**

## 5. Co-op solo-developed was 2× and it was the 2× that killed it

ADR-013 accepted the cost with eyes open. But QA on four-player emergent systems, alone, is genuinely brutal — the Gullsjúkr targeting the richest player, ember rescue, late-join world deltas, host migration, four lanterns of Clamor.

**The unsayable version, stated because a pre-mortem is where unsayable things belong:** *if co-op is what stops this shipping, solo-first with co-op post-launch is a real option.* The architecture supports it — pacts are individual and progression never touches the network.

That is **not** a recommendation to reverse ADR-008. It is a pre-authorised escape hatch, so the choice is available later without feeling like defeat.

## 6. There was no audience

Premium price, crowded genre (Dark and Darker, Tarkov, DMZ, Hunt), solo developer, **and no marketing plan anywhere in 38 documents.**

**This is a genuine gap, not a hypothetical.** Differentiation is strong — PvE-only, the ink shader, the theme, no microtransactions — but differentiation nobody sees is not differentiation.

**Mitigation:** the ink shader is the marketing asset. It is *screenshot-legible*, which is rare and valuable. **Start posting development shots the moment it works.** A devlog costs an hour a week and is the only distribution a solo premium title realistically gets.

> **RE-RUN AT THE `M3` GATE (ADR-191): the precondition was met at `M1` and nothing has been posted.** *"The moment it works"* had an answer — `M1-T09`'s go/no-go, measured GO at ADR-070 with outlines and boil at ~0.15–0.23 ms. That was weeks ago. `M4-T18` exists and is untouched, and *"the moment it works"* turns out to be a trigger nobody can be late for because it names no observable.
>
> **It has one now:** the devlog starts when the Delvings are photogenic — realistically the `M4-T01` ⟨tune⟩ pass, which is the first floor worth a screenshot. Not urgent, and no longer implicit.

## 7. Documentation became the project

38 documents, 60 ADRs, zero lines of engine code. The corpus kept improving and the game never started.

**Mitigation:** already flagged repeatedly. **The design is locked. Further planning now requires an ADR justifying why it could not wait until after M1.**

> **RE-RUN AT THE `M3` GATE (ADR-191): the count is now 42 documents and 191 ADRs against roughly two play sessions on a build.** The session that wrote this re-run added one document and three ADRs to that ledger, which is worth stating rather than leaving for a later reader to notice.
>
> **The corpus is load-bearing and the rule stands** — it has stopped this design drifting back into a stat ladder three separate times, and `TEC-007` and `TEC-009` each found a real fault before a month was spent on it. What has changed is the exchange rate: **the marginal ADR is now worth less than the marginal playtest, and six weeks ago it was not.** The corrective is not to write fewer records, it is to have something played between them (§4).

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
2. **The shader weekend spike** happens before M1 proper (`M1-T09`), with an explicit **go/no-go**: if it is not ~70% convincing, we commit to flat quantised shading and **never build the other path.** That is a gate decision, not a maintained fallback (ADR-064).
3. **A devlog** starts when the shader works.

## Re-run this

A pre-mortem is not a one-time ritual. **Re-run it at each milestone gate** — the failure modes change as the project does, and the ones that matter at M3 are not the ones on this page.

> **This instruction was skipped once already, and now has a task** (`M4-T21`, ADR-191). `M3` cleared and this document sat untouched for three weeks; the re-run above is late, and it found `§1` living in a different milestone, `§4` being actively realised, and `§6`'s trigger met since `M1`. **A sentence at the bottom of a document is not a process** — that is ADR-098's finding applied to ourselves, and the fix is the same one: give it a name something calls.
>
> **The `M3` re-run confirms the page's own prediction.** *"The ones that matter at M3 are not the ones on this page"* — the top risk is no longer combat feel iterating forever, it is a seventeen-row milestone with no timebox and no playtest in it.

**Sources:** [Klein, *Performing a Project Premortem* (HBR 2007)](https://nesslabs.com/pre-mortem-anticipate-failure-with-prospective-hindsight) · [Vertical slice definitions and solo-dev scope](https://ltpf.ramiismail.com/prototypes-and-vertical-slice/)
