---
id: PRO-005
title: Design Psychology & Research Basis
status: proposed
owner: process
tags: [psychology, research, theory, balance, retention, ethics]
updated: 2026-08-12
related: [DES-003, DES-005, DES-009, DES-010]
---

# Design Psychology & Research Basis

The grounding for tuning decisions across the project. **These are frameworks, not laws.** Every one of them is a hypothesis generator — they tell us *what to try* and *what to measure*, never what is true of our game. Playtest data overrides any claim in this document.

A second caution, taken seriously: several of these findings describe how to make an experience *compelling*, which is a hair's breadth from how to make it *compulsive*. `DES-010`'s "what we will not do" list is the ethical line, and it's non-negotiable.

---

## 1. Loss aversion is the engine of this entire genre

**Prospect theory** (Kahneman & Tversky, 1979; refined 1992): losses register roughly **twice as strongly** as equivalent gains. The **endowment effect** (Thaler, 1980) extends this — once you possess something, you value it more than you did a moment before acquiring it.

This is *the* psychological mechanism extraction games run on, and naming it precisely tells us what to tune:

- The moment loot enters your bag, it becomes **yours**, and its potential loss is felt about twice as hard as the gain of more loot.
- That asymmetry *is* the sentence "I have enough, I should leave." **We don't have to manufacture the tension. We have to avoid destroying it.**

**Design consequences:**
- Loot must be **visibly possessed** — in a bag you can see, with weight you can feel (`DES-009`). Abstract score accrues no endowment effect.
- The bag should be **full-ish early**. Endowment can't operate on an empty inventory. Early-run loot density matters more than late-run density.
- **Corollary risk:** loss aversion also produces *risk aversion*. Too much fear and players stop descending — the observed failure mode in punishing extraction games. Counterweight: guaranteed Lineage payout (ADR-006) means descending is never strictly-negative EV.

## 2. Peak-end rule: runs are remembered by two moments

Kahneman and colleagues: retrospective judgment of an experience is dominated by its **most intense moment** and its **ending**, not its average or duration.

For us, that's decisive. **Every run ends in either extraction or death** — so those two screens carry disproportionate weight in whether a player starts another run.

- **Extraction must be a peak**, not a fade-out. The walk to the exit under pressure is the designed climax (`DES-005`), and the moment of getting out needs real punch — audio, light, her voice.
- **Death must be authored** (`DES-010` C2). A death screen that reads "you lost everything" makes the *ending* the worst moment. Leading with what was gained, then her grief, then the Legacy choice, deliberately restructures the ending into something bearable and interesting.
- **Practical rule: never end a run on a flat screen.** Not once.

## 3. Flow: challenge must track skill

Csikszentmihalyi (1990): engagement lives in a narrow channel between anxiety (challenge > skill) and boredom (skill > challenge). The channel *moves* as the player improves.

**Our version of this is unusually elegant:** the Tithe (`DES-003`) is a flow-channel tracker the player operates themselves. Take more power → owe more → must go deeper. A player who stops taking Boon stays at their current challenge level, which is a legitimate way to play. **The player self-selects difficulty by choosing how much power to accept.**

Worth stating plainly: this is the strongest structural argument for the Tithe, above and beyond its balance function.

## 4. Self-Determination Theory: what makes play intrinsically motivating

Deci & Ryan; applied to games by Ryan, Rigby & Przybylski (2006) and *Glued to Games* (2011). Three needs predict enjoyment and sustained play better than reward schedules do:

| Need | Our provision | Failure mode to watch |
|---|---|---|
| **Autonomy** | Aspect/class builds, route choice, when to leave, what to tribute | Contracts that feel mandatory; one optimal build |
| **Competence** | Legible telegraphs, learnable enemies, deaths you can explain | Unfair deaths, invisible systems, RNG-dominant outcomes |
| **Relatedness** | Co-op (`DES-012`), She as a persistent relationship, factions | Co-op that's mechanically solo; a patron who is a vending machine |

This is the strongest available argument for **co-op as core rather than optional** (ADR-008). Relatedness is the need most under-served by a solo extraction game, and it's the one most strongly associated with *long-term* rather than short-term engagement.

## 5. Fair failure motivates retry; unfair failure motivates quitting

Jesper Juul, *The Art of Failure* (2013): players tolerate — even seek — failure when they attribute it to **their own correctable choices**. Attribution to unfairness or randomness produces frustration and churn instead.

This is Principle 4 in `CLAUDE.md` ("explain your death in one sentence") with a citation behind it, and it's why `DES-009` commits to **high lethality with heavy telegraphing**. Lethality is fine. *Illegibility* is not.

**Measurable proxy:** post-death survey or telemetry on whether the player re-descends immediately. Instant re-descent = fair failure. Quit-after-death = attribution failure (`DES-010` metrics).

## 6. Fun is pattern-learning, and mastery ends it

Koster, *A Theory of Fun* (2004): fun is the feedback from successfully learning a pattern. When the pattern is fully learned, the fun stops.

**Consequences for content strategy:**
- Systemic depth outlasts authored content because the pattern space is combinatorial (Principle 5 — this is its theoretical basis).
- Our churn point C5 (`DES-010`, post-mastery plateau) is *predicted* by this, not a surprise to be handled later.
- **Complications** (`DES-007`) are pattern-disruptors and are therefore worth more authoring effort per unit than new quest instances.

## 7. Zeigarnik effect: unfinished business is remembered

Zeigarnik (1927): interrupted or incomplete tasks are recalled more readily than completed ones, and generate residual tension.

This is the theoretical basis for `DES-010`'s session hooks, and it means the design should **deliberately leave threads dangling**:
- A cache still down there (the strongest one we have)
- A contract expiring in 2 runs
- A vault you now have the key for
- A Whisper you had to abandon

**Never let a session end on a resolved state.**

## 8. Cognitive load: teach one system per run

Sweller (1988): working memory saturates fast, and novel interacting elements are the most expensive thing to learn.

`DES-010` C1 already stages the tutorial one system per run. The theory adds a specific warning: **Clamor + weight + the Hunt + tribute + contracts are heavily *interacting* elements**, which is the most expensive category to learn simultaneously. Staging isn't a nicety, it's required.

## 9. Arousal and performance

Yerkes-Dodson (1908) proposes an inverted-U between arousal and performance. *Caveat: the finding is oversimplified in popular use and its generality is contested.* Treat it as a design metaphor, not evidence.

The usable idea: **sustained maximum pressure degrades performance and enjoyment.** `DES-002`'s run shape (low → building → break point → escape) is a deliberate arousal curve with troughs. **Protect the troughs** — the quiet first five minutes are load-bearing, not filler.

## 10. Variable reward — used carefully, and only where it belongs

Variable-ratio reinforcement is the most powerful known schedule for sustaining behaviour, and it is also the mechanism underlying most predatory game monetization.

**Our position:** variance belongs in **loot placement and dungeon composition** — this is legitimate procedural design, and it's where surprise and story come from. It does **not** belong in progression gates, monetization, or anything that gates a player's ability to pursue a goal. Boon from tribute is *deterministic* by design (`DES-004`): you know what you'll get for what you give. Chase the excitement of discovery; never the itch of a slot machine.

### What this does and does not forbid

Worth stating exactly, because "variable reward is bad" is too blunt to design with and gets misapplied.

**The rule restricts variance in three places only:** progression gates, monetization, and anything that stands between a player and a goal they're pursuing. Everything else is fair game — a dungeon that surprises you is the entire point of the genre.

**Applied to a gambling vendor** (`DES-014` Q67): it is not monetized, it gates nothing, it spends resources you already earned, and you can ignore it forever. **So §10 does not forbid it — it flags it**, and names the specific line it must not cross:

> The moment gambling becomes the *best* way to obtain something that matters, it has become a progression gate with variance attached. That is the failure.

**Guardrails that keep it on the right side:**
- **Never the best source of anything.** Dungeon loot must beat it in expectation for everything that matters.
- **No near-miss theatre.** Do not animate a wheel that almost lands on the good thing. The near-miss effect is the actively manipulative part of slot design — show the result plainly.
- **Bounded, known pool.** The player can see what's possible. Mystery jackpots are the problem; a known set of grave-goods is not.
- **No pity timers or streak mechanics.** Those are engagement engineering, not generosity.
- **Hard stock cap per cycle** ⟨tune⟩ — a small decision, never an activity you can sit and grind.
- **Costs a resource with better uses**, so it's a genuine trade-off rather than a dump for surplus.

And the tone does real work, the same trick as the staves (ADR-022): it should feel **seedy and a little sad**, not exciting. It is a Choir scavenger selling dead people's belongings. Framed that way, the mechanic is characterizing rather than seductive.

## 11. The theme makes the ethics load-bearing

ADR-020 made the game explicitly **about compulsion** — knowing what a thing costs you and going back anyway. That sits directly on top of §10's caution, and the relationship between them needs stating precisely, because this is exactly the kind of distinction that erodes quietly under production pressure.

**A game about addiction that is itself addictive by predatory design is not a game about addiction. It's an instance of one.**

The distinction isn't squeamishness, it's craft. If we reach for dark patterns, the work becomes the thing it's depicting and loses any standing to depict it. So the ethical rules stop being hygiene and become **artistic requirements**:

| Forbidden | Why it's now a theme violation, not just a policy one |
|---|---|
| Daily login rewards, streaks, FOMO timers | Manufactures the compulsion instead of portraying it |
| Monetized progression or loot boxes | Makes us the dragon, unironically |
| Punishing absence (decay, expiring stashes) | The character is trapped; the player must not be |
| Obscured playtime | A game about not noticing what you're doing owes the player the ability to notice |

And the positive obligations:

- **Stopping is easy and unpunished.** Quit for six months, come back, nothing is gone. `DES-003`'s LIFE/LINEAGE split already delivers this — your lineage is exactly where you left it.
- **Sessions have natural ends.** `DES-002`'s Tithe cycle gives a clean stopping point every ~3 runs. Protect it; do not add a mechanic that makes leaving mid-cycle costly.
- **Honest playtime visibility**, in-game, unhidden.
- **The theme is shown, never argued.** Rule 2 of ADR-020: no judgment, no lecture. *Spec Ops: The Line* is the failure mode — it accuses the player of things it required them to do, which is both dishonest and cheap. We build the shape and let people see it or not.

**Where the real care is owed:** some players will not experience this theme as an abstraction. That's not an argument against making it — the best work about compulsion comes from people who recognize it — but it does argue for the rules above being non-negotiable rather than aspirational, and for the tone being *compassionate* rather than clever. She is not a joke about addiction. She is a creature who loves you and is killing you and cannot remember why.

> **OPEN (Q56):** Should refusal be a mechanically supported ending? ADR-018 makes the final question *"do you keep feeding it?"* — which implies **no** must be answerable. An ending you reach by *stopping* is thematically exact and structurally strange in a roguelite. Worth designing properly rather than bolting on.

---

## How to use this document

1. When proposing a tuning change, name the mechanism you think you're affecting.
2. Name the **metric** that would show it working (`DES-010`).
3. Playtest. **If the data disagrees with the theory, the theory is wrong for our game.** Every item above is a prior, not a conclusion.

> **OPEN:** Worth a literature pass on extraction-shooter-specific player research (Tarkov/DMZ/Hunt retention studies, GDC talks) once the vertical slice exists and we know which questions matter. Premature now — we'd be reading answers to questions we haven't asked yet.
