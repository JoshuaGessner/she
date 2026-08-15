---
id: DES-006
title: World & Setting
status: accepted
owner: design
tags: [world, setting, lore, tone, ip-safety, biomes]
updated: 2026-08-14
related: [DES-001, PRO-004, DES-007]
---

# World & Setting

## Constraint first

The brief asks for "loosely Tolkien-based fantasy, as much as possible without legal issues." The honest answer: **Tolkien's work is not public domain and won't be until ~2043**, and the rights holders are unusually litigious (see `PRO-004` for the full guardrails).

The good news is that **the things people actually mean by "Tolkien fantasy" mostly predate Tolkien.** He was a philologist adapting Norse, Anglo-Saxon, and Finnish material that is comprehensively public domain. Going *back to his sources* gets us the same texture, more originality, and zero legal exposure. That's the approach.

**Source palette (all public domain):**
- *Poetic Edda* & *Prose Edda* — dwarves (the actual names Tolkien lifted from Dvergatal), world-tree cosmology, the doomed-fate register
- *Völsunga saga* / *Nibelungenlied* — **Fáfnir**, the dwarf who became a dragon out of greed for a hoard, and whose gold is cursed. Our premise is *literally already public domain.*
- *Beowulf* — the barrow-wyrm, mead-hall culture, the thief who steals a cup from a sleeping dragon and dooms a kingdom
- *Kalevala* — Finnish material, strange magic, the Sampo as a "cursed artifact of prosperity"
- Anglo-Saxon elegiac poetry (*The Wanderer*, *The Ruin*) — the tone of a civilization walking through the ruins of a better one

## Tone

**Elegiac and grubby.** Not heroic-epic, not grimdark. The world had a golden age; it ended; you are looting its corpse for a monster. *The Ruin* — an Anglo-Saxon poem about a Roman city, where the narrator marvels at masonry his people can no longer make — is the exact register.

Barony's tonal contribution: **material, tactile, a little absurd.** Bread you can eat, barrels you can burn, a skeleton that trips a trap meant for you. Solemnity and slapstick coexist; we should not be precious.

## She

> **DECIDED (ADR-007):** She is an **original character, female**. Her *pattern* is Fáfnir's — greed, transformation, a cursed hoard. Her *identity* draws on **Gullveig**.

Fáfnir, the dragon whose story our premise follows, is male in the *Völsunga saga* — a dwarf-prince who murdered his father over a cursed hoard and became a wyrm coiled around it. We keep his pattern and change everything else, because a better figure exists.

**Gullveig** appears in *Völuspá*: a female being whose name means roughly *gold-power* or *gold-drunk*. The Æsir pierced her with spears and burned her three times in Óðinn's hall, and three times she was reborn. Public domain, female, explicitly gold-associated, and **canonically unable to die properly**. That is our wyrm exactly, sitting in the source material waiting for us.

### The character

She is vast, ancient, and **wounded in a way that will not close** — burned, speared, and reborn too many times, each rebirth leaving more of her fused into the mountain's stone. She has not moved in an age. She cannot hunt. She cannot leave. What she can still do is *give away pieces of herself* to those who bring her gold.

The gold is not wealth to her. It is the only thing that slows the dying, and she needs more of it every year — **which is why the Tithe escalates** (`DES-003`). Her hunger is not greed for its own sake. It's a body failing.

Every soul she binds carries a little of her fire, her greed, and her curse. None of them last. She has watched your whole bloodline descend into the dark for her, and she remembers all of them by name — the diegetic justification for the LINEAGE persistence tier, and a good one.

**Voice and register:** low, slow, enormous, and *close* — she speaks into the minds of the Bound rather than aloud. Never cruel, which is worse. She is fond of you, in the way a person is fond of a favourite tool. She grieves each death briefly and genuinely, and then asks what you brought.

**Her true name is late-game content.** Throughout, she is *She*, *the Wyrm*, *the Gold-Drowned*. Learning what to call her should be a real revelation, not an intro cutscene.

### Her arc, and the three endings

> **DECIDED (ADR-049):** the ending **mirrors the Gullsjúkr's two solutions** (`DES-017`), plus a third the Hunter never gets.

**1. Take everything.** The secret fight. Kill her, claim the hoard.

This is the **greed ending**, and it is thematically coherent rather than a violation — *taking everything it has* is already one of the two established answers to a Gullsjúkr. Killing her is the ultimate expression of the thing the whole game is about: consuming your own patron.

**She cannot be brute-forced.** The fight becomes available only once the player has assembled the **Calamity marks** (`DES-016`) — once they have worked out what the gold does. **Knowledge is the weapon.** This finally pays LINEAGE out in something beyond convenience without breaking ADR-006, because it grants *access to an ending*, never power. And it is exactly right: **you can only end the cycle once you have seen it.**

**The three burnings** (ADR-019) structure the fight. She has died three times and come back; there is a reason she cannot simply be killed.

**2. Give enough to rest.** Return the hoard until she can finally die properly. The mercy ending, and the direct mirror of *satisfying* a Gullsjúkr.

**3. Refuse.** There is a door. You walk out. A skippable cutscene resolves the story, **and the game quits itself.**

The last line is hers: *they'll be back, they always come back.*

**Nothing is deleted.** Her memory persists, your lineage persists, the camp persists. Open the game again and you are standing at the Threshold, and **she does not mention it.** The game was right, and you proved it — which is a far better ending than a deleted save, and it keeps stopping unpunished (`PRO-005 §11`).

The door must be unmistakably intentional and never readable as a crash: slow, deliberate, authored.

**Endings are small by design** — a room, her voice, a last screen. No cinematics. Cheap when authored as text and audio, which means the only large content cost is the optional, late, gated fight.

### She knew. She has forgotten. Many times.

> **DECIDED (ADR-019):** She understood, once, exactly what her hoard does. Each burning and rebirth took the knowledge with it. She has *almost* remembered before. She will almost remember again.

This is the decision that lets her be **genuinely fond of you and still kill you**, without either half being a lie. A wyrm who knows and asks anyway is a monster, which is flat. One who never knew is a tragedy, which is inert. One who keeps forgetting is both — and can be loved by her victims, which is the register the whole game needs.

**Her forgetting must be mechanical, not backstory.** If it only lives in a lore entry nobody experiences it. Concrete, cheap expressions — all of them dialogue variation keyed on lineage depth:

- **She repeats herself across a lineage.** The same greeting she gave your great-grandmother, word for word, delivered as though it were new.
- **She mistakes you for the dead.** Occasionally she greets you by the name of someone who died forty runs ago, and does not notice.
- **She speaks of the Dvergar in the present tense.** As though they still trade with her. As though the Delvings are not a grave you just walked out of.
- **She almost gets there.** Very rarely, and only deep in a lineage: she stops mid-sentence, and asks you what the barrow-kings were buried with. Then she loses it again, and asks what you brought.

That last one is the whole game in four seconds, and it costs a dialogue node.

**The three burnings** give the forgetting a structure to uncover: she has been reborn three times, each further from what she knew. What the player is assembling across a lineage is not just *what the gold does* — it's *how many times she has almost found out*.

**Writing rule (ADR-019/020): discoverable, never stated.** She never says she has forgotten. Nobody tells the player she has. It is visible only in the seams — repetition, misnaming, tense. The moment it is explained, it stops being true.

## The Deep

Below her mountain: a stratified ruin. A Dvergar mine-city that dug too far into something older, and stopped being a city.

> **DECIDED (ADR-018):** **The hoard is the disease.** Every Calamity down there traces back to her.

Gold that passes through her hoard is cursed, and every civilization in the Deep died of the same sickness in a different dialect. This is not an invention — Gullveig is *already* the figure who brought gold-lust into the world, burned three times for it and reborn each time. We are simply following the myth to its conclusion.

The consequence for the player is the thing the whole game is pointed at: **you are doing, right now, the exact thing that caused every disaster you walk through**, on behalf of the thing that caused it. Every run re-enacts the Calamity in miniature.

**Absolute rule: this is discoverable, never stated.** No NPC explains it. No codex spells it out. She never admits it. The evidence lives in architecture, grave-goods, inscriptions, and the shape of how people died — and the player gets to be the one who says it out loud, probably around their fifteenth run. The moment a character explains the curse, the effect dies permanently. See `DES-015` for how the generator carries it.

## Biomes (3 at 1.0)

| Biome | Sources | Fantasy | Distinct mechanic |
|---|---|---|---|
| **The Delvings** | Norse dwarf-halls, mines | Collapsed industrial dwarf city — cut stone, dead machinery, flooded shafts | Verticality, structural collapse, mine carts, darkness as a resource |
| **The Barrow-Fields** | *Beowulf*, Anglo-Saxon burial mounds | Grave-hills of a dead kingdom, the richest and worst-guarded loot | Undead that *keep what's theirs*; grave-goods carry curses (`DES-008`) |
| **The Sunken Wood** | *Kalevala*, Norse Járnviðr | A drowned petrified forest grown through the ruins, half-alive | Organic/hostile terrain, poor sightlines, things that watch |

> **DECIDED (ADR-005):** Three **separate expeditions**, chosen at the Lair, **3 floors each**. Modular to build and balance in parallel; preserves a descent arc within each expedition. Floor 3 of each must be genuinely punishing to recover the "went too deep" fantasy that a continuous descent would have given us for free.

Each expedition needs its own difficulty curve, its own Hunt escalation pacing, and extraction points on every floor (`DES-005`). Floors 1→3 should shift the *kind* of pressure, not just the numbers: floor 1 rewards exploration, floor 2 introduces the Hunt reliably, floor 3 is hostile from the moment you arrive.

## Peoples

Named to avoid Tolkien's specific vocabulary (`PRO-004`) while keeping the archetypes players want:

- **The Dvergar** — mountain-smiths, PD names straight from the Eddas. Their city is the dungeon. Some survive, degenerate and territorial.
- **The Álfar** — not Tolkien's elves; the Norse ones, which are stranger and better: capricious local spirits associated with the dead and with disease. Genuinely alien, no legal exposure, more interesting.
- **The Thursar** — giant-kin, from *þurs*. Big, slow, catastrophic.
- **Draugr** — Norse barrow-wights, hoard-guarding undead. Perfect fit for the Barrow-Fields and 100% PD.
- **The Bound** — humans like you, past and present, in various states of failure. Where the async player-echo content lives (`DES-002`).

**Explicitly avoided:** hobbits/halflings, orcs-as-Tolkien-wrote-them (we use *þurs*/troll-kin and Draugr instead), ents, balrogs, mithril, and every proper noun from his legendarium. See `PRO-004`.

> **DECIDED (ADR-050):** **A lineage of nobodies, with light customisation.** Nameless is thematically right, cheap, and it makes the Legacy screen about what you *did* rather than who you were.
