---
id: PRO-004
title: IP & Legal Guardrails
status: proposed
owner: process
tags: [legal, ip, risk, naming, public-domain]
updated: 2026-08-12
related: [DES-006, PRO-003]
---

# IP & Legal Guardrails

> **Not legal advice.** This is practical risk-reduction written by a design lead, not a lawyer. Before any commercial release, an IP attorney should review names, marketing copy, and store assets. The purpose of this document is to keep us from building anything we'd later have to tear out.

## The situation, accurately

**Tolkien's work is not public domain and will not be for a long time.**

- Tolkien died 2 September 1973. UK/EU copyright runs life + 70 → **~2044**.
- US terms for *The Lord of the Rings* (published 1954–55, renewed) run 95 years from publication → **~2050**. *The Hobbit* (1937) is somewhat earlier but still decades out.
- Separately from copyright, **trademarks** on names like *The Hobbit*, *Gandalf*, *Shire*, *Mithril*, and *Middle-earth* are held by **Middle-earth Enterprises** (acquired by Embracer Group in 2022) and are actively enforced. Trademarks do not expire while they're maintained.

The rights holders have a long, well-documented history of enforcement, including against small developers. This is not a theoretical risk.

**The best-known precedent:** early D&D used *hobbit*, *ent*, and *balrog*; after contact from the rights holders, TSR renamed them to *halfling*, *treant*, and *balor*. That rename is why the fantasy genre's vocabulary looks the way it does today — and it's a good model for us. **The archetypes are free. The names are not.**

## The strategy: go upstream

Tolkien was a philologist adapting older material. Nearly everything people mean by "Tolkien fantasy" comes from sources that are **comprehensively public domain**:

| Source | Gives us |
|---|---|
| *Poetic Edda*, *Prose Edda* | Dwarves (incl. the actual name-list Tolkien mined), cosmology, doom-laden register |
| *Völsunga saga*, *Nibelungenlied* | **Fáfnir** — the greed-cursed hoard-dragon. Our entire premise, already free. |
| *Beowulf* | Barrow-wyrm, hoard theft, mead-hall culture, monster-kin |
| *Kalevala* | Strange magic, cursed prosperity-artifacts |
| Anglo-Saxon elegies (*The Ruin*, *The Wanderer*) | The exact tone of `DES-006` |

Going upstream is not a compromise. It produces a **more distinctive** game than a Tolkien pastiche would, at zero legal exposure.

## The fast rule

> **If you learned the word from Tolkien, don't use it.**

## Do not use

**Proper nouns (all of them):** Middle-earth, Mordor, Gondor, Rohan, Rivendell, Lothlórien, the Shire, Númenor, Valinor, Moria, Isengard, Erebor, Bree, Gandalf, Frodo, Aragorn, Sauron, Saruman, Galadriel, Legolas, Gimli, Thorin, Smaug, Bilbo, Nazgûl, Uruk-hai, Palantír, Anduril, Sting, the One Ring.

**Tolkien-coined common nouns:** hobbit *(trademarked)*, mithril *(trademarked)*, ent (as tree-people), balrog, orc *as specifically depicted by Tolkien*, warg (as he used it), *eleventy-first*, "precious" as a ring-obsessed catchphrase.

**Invented languages:** Quenya, Sindarin, Khuzdul, Black Speech, Tengwar and Cirth scripts. Do not generate "elvish-looking" text from his grammars.

**Plot structure as pastiche:** a fellowship of mixed races escorting a corrupting ring to a volcano. Individual beats are unprotectable; the *combination* is what creates risk.

**Marketing language:** never describe the game as "Tolkien-inspired," "Middle-earth-like," or "Lord of the Rings-style" in any store page, trailer, or press release. **This is where most small studios actually get into trouble** — the game itself is often fine, and the marketing copy is what draws the letter. Say "Norse-inspired dark fantasy."

## Safe to use

**Generic fantasy vocabulary:** elves, dwarves, giants, trolls, goblins, wizards, rangers, barrows, wights, wyrms, runes, halls, hoards. Long predates Tolkien or is now genre-generic.

**Norse/Germanic material outright:** Fáfnir, Draugr, Dvergar, Álfar, Þursar (Thursar), Jötnar, Níðhöggr, Ratatoskr, Yggdrasil, Sampo, Andvaranaut, Ginnungagap. All public domain, all richer than the Tolkien equivalents.

**Anglo-Saxon vocabulary:** barrow, wyrd, mearc, burg, wíc, scop, heorot-as-common-noun, folc.

**"Orc"** is generally treated as safe — it predates Tolkien (Old English *orcnēas* in *Beowulf*) and is used industry-wide by D&D, Warcraft, and countless others. `DES-006` avoids it anyway, for originality rather than legal reasons.

## The subtle trap: PD names with strong association

Some names are genuinely public domain but so strongly associated with Tolkien that using them invites confusion and unwanted attention.

**Gandalf, Thorin, Durin, Fili, Kili, Óin, Glóin, Dvalin** all appear in the *Dvergatal* (the dwarf-list in *Völuspá*) — Tolkien took them from there. **The source being public domain does not fully protect you**, because trademark and passing-off claims turn on *consumer confusion*, not on origin. A dwarf named Thorin in a fantasy game reads as a Tolkien reference to every player and every lawyer, regardless of the Eddas.

**Rule:** use the *obscure* Eddic names (Nár, Náin, Bífurr, Alvíss, Regin, Ótr, Hreiðmarr) and avoid the famous ones. Same well, different bucket.

## Other IP hygiene

- **Barony and DMZ** are mechanical references only. Mechanics aren't copyrightable; **never** copy their assets, names, UI layouts, or specific text.
- **Asset licensing:** log the license for every third-party asset, font, and sound in a `CREDITS.md` from the first import. Retroactive license archaeology is miserable and has killed releases.
- **Fonts** are the most commonly-missed licensing trap in games — desktop licenses frequently don't cover game embedding. Verify each one.
- **AI-generated assets:** if any are used, log it. Steam requires disclosure of AI-generated content.
- **Title clearance:** the eventual real title needs a trademark search before any store page exists. Renaming after launch is expensive and hurts discoverability.

## Open items

> **OPEN:** Working title "SHE" needs replacing. Requires trademark search and Steam/social handle availability check.

> **OPEN:** Budget a real IP attorney review before store page publication ⟨tune: ~$500–2000 for a focused review⟩.
