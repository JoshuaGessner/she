# Project SHE

> A first-person 3D fantasy **extraction roguelite** built in **Godot 4**, for 1–4 players.
>
> *Barony's grubby, systemic dungeon-crawling meets DMZ's layered mission structure, in service of a hoard-dragon who buys your soul one run at a time.*

**Status: design locked, implementation starting.** No engine code yet. This repository holds the design corpus — **39 documents and 64 architecture decision records** covering the full game design, technical architecture, art and audio direction, and production plan. Every design document is `accepted`; changing one now requires an ADR.

Implementation begins at **M1**, whose only job is to answer whether moving and fighting is fun in a grey box (see [roadmap](docs/process/PRO-001-roadmap-and-milestones.md)).

Built solo, as time allows. It is deliberately an experiment: a crowded genre, approached from an angle nobody has tried, to find out what happens.

---

## The pitch

You are one of many desperate souls who have made a pact with a dying, ancient wyrm. She cannot leave her mountain, so she sends you into the buried places of a broken world to bring back what glitters. In return she burns a piece of her power into you.

The more she gives, the more she demands. And she is always hungry.

**The feeling the whole design chases, in one sentence:**
> *"I have enough. I should leave. One more room."*

## What makes it different

- **Greed is the core mechanic.** Loot isn't a reward, it's a liability you chose to carry. Every valuable thing makes the walk to the exit measurably worse — heavier, louder, more hunted.
- **Extraction is a resource problem, not a routing problem.** Your way out is *itself* loot. Spending a Waystone means choosing to end the run right now with what you have.
- **Meta-progression that raises stakes instead of lowering them.** Every point of power you take raises your Tithe — the tribute you owe. Growth pulls you toward danger by design, so the game never goes soft.
- **Death is a decision, not a wipe.** She remembers three things about you. You choose which, at the moment you die.
- **Co-op where a friend can carry your soul out.** Fall, and your ember drops. It's heavy and it's loud. If someone hauls it to an exit, everything you built survives.
- **A dungeon that tells you what happened to it.** Generation rolls a history first, then builds space to express it — so descending is reading a disaster backwards.

## Design corpus

Everything lives in [`docs/`](docs/). Start with the **[INDEX](docs/INDEX.md)**.

| | |
|---|---|
| **[DES-001 Vision & Pillars](docs/design/DES-001-vision-and-pillars.md)** | What the game is and what it refuses to be |
| **[DES-002 Core Loop](docs/design/DES-002-core-loop.md)** | Run / Life / Lineage — the three nested loops |
| **[DES-003 Persistence](docs/design/DES-003-persistence.md)** | What survives death, and why that's the hardest problem here |
| **[DES-005 Extraction Pressure](docs/design/DES-005-extraction-pressure.md)** | Weight, Clamor, the Hunt, the Sealing |
| **[DES-011 Classes](docs/design/DES-011-classes.md)** | Six of the Sworn, each defined by *how they get out* |
| **[DES-015 Level Generation](docs/design/DES-015-level-generation.md)** | Cyclic generation and history-driven space |
| **[DES-017 The Gold-Sick](docs/design/DES-017-the-gold-sick.md)** | The Hunter — a Bound who never left, still trying to pay a debt |
| **[ART-005 The Ink Shader](docs/art/ART-005-the-ink-shader.md)** | A woodcut you can walk through, drawn by your lantern |
| **[PRO-002 Decision Log](docs/process/PRO-002-decision-log.md)** | Every decision, with the reasoning and the rejected alternatives |
| **[OPEN-QUESTIONS](docs/OPEN-QUESTIONS.md)** | The live queue of what's unresolved |

Docs carry YAML frontmatter (`id`, `status`, `tags`, `updated`, `related`) and stable permanent IDs. The index is generated:

```bash
python3 tools/reindex.py           # regenerate docs/INDEX.md
python3 tools/reindex.py --check   # CI-safe staleness check
```

## Design principles

These exist to settle arguments. Lower number wins.

1. **The run is the product.** Meta-progression makes runs more interesting, never easier by default.
2. **Power must cost risk, not just time.**
3. **Decisions over reflexes.**
4. **The player should be able to explain their death in one sentence.**
5. **Systems over content.** Hand-authored content is the scarcest resource on a small team.
6. **Legibility beats realism.**
7. **Ship the vertical slice.** One biome, one full loop, polished, before any breadth.

Full working agreement in [CLAUDE.md](CLAUDE.md).

## On the setting

The world is **Norse-adjacent, drawn from public-domain sources** — the Poetic and Prose Eddas, *Völsunga saga*, *Beowulf*, the *Kalevala*, Anglo-Saxon elegiac poetry.

It is deliberately **not** Tolkien-derived. Tolkien's legendarium remains under copyright until at least 2043 and its rights holders litigate actively. The good news is that most of what people mean by "Tolkien fantasy" predates him — he was a philologist adapting material that is comprehensively public domain, so going back to his sources gets the same texture with more originality and no exposure. Guardrails are in [PRO-004](docs/process/PRO-004-ip-and-legal-guardrails.md).

## Technical shape

- **Godot 4.x**, GDScript first. C# only where a profiler proves a hot path needs it.
- **Data over code** — enemies, items, skills, quests, and loot tables are `.tres` resources, not scripts.
- **Composition over inheritance** — scenes as components; signals up, calls down.
- **Seeded, bit-exact-deterministic generation** — the host sends a seed and every client builds the identical floor, so geometry is never replicated.
- **Host-authoritative peer-to-peer**, 1–4 players, no dedicated servers.
- **Versioned save data from commit one**, with a migration path.

See [TEC-001](docs/tech/TEC-001-godot-architecture.md) and [TEC-004](docs/tech/TEC-004-networking.md).

## Monetization

**Premium purchase. Nothing else.** No microtransactions, cosmetic or otherwise; no loot boxes, no premium currency, no battle pass, no purchasable power. Everything in the game is earned by playing it.

That's partly ethics and partly craft: the game is *about* compulsion, and monetizing with the mechanisms it critiques would make it an instance of the thing rather than a work about it. Reasoning in [PRO-006](docs/process/PRO-006-monetization.md), standing rules in [PRO-005 §11](docs/process/PRO-005-design-psychology.md).

## License

**[PolyForm Noncommercial 1.0.0](LICENSE)** — source-available, not open source.

You may **read, run, modify, and share** this work freely for any **noncommercial** purpose: personal study, hobby projects, research, education, and use by nonprofit or public institutions. **Commercial use is reserved.**

For commercial licensing, open an issue.

> Not legal advice. Anyone relying on these terms should consult their own counsel, and this project will have an IP attorney review before any commercial release (see PRO-004).

## Contributing

**The design is locked and not open to contributions.** Issues and discussion are welcome — particularly if you have shipped an extraction game, a roguelite meta-progression system, or Godot co-op netcode at this scale, in which case the remaining [open questions](docs/OPEN-QUESTIONS.md) are genuinely open.

If you want the honest version of where this could go wrong, read the [pre-mortem](docs/process/PRO-007-premortem.md).
