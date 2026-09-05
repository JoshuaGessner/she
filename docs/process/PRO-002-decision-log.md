---
id: PRO-002
title: Decision Log (ADRs)
status: accepted
owner: process
tags: [decisions, adr, process, history]
updated: 2026-09-04
related: [DES-001, DES-003, PRO-001]
---

# Decision Log

Every significant decision gets an entry. **Never delete an entry** — supersede it. The value of this file is that it records *why*, which is the thing that's always lost and always needed six months later.

Format:

```
## ADR-00N — Title
**Date:** YYYY-MM-DD · **Status:** accepted | superseded by ADR-00M
**Context:** what forced a decision
**Decision:** what we chose
**Rationale:** why, including what we're trading away
**Consequences:** what this now commits us to
```

---

## ADR-001 — Documentation lives in `docs/`, indexed by stable ID
**Date:** 2026-08-12 · **Status:** accepted
**Context:** Design is being developed conversationally; chat logs are not durable or searchable.
**Decision:** All project knowledge lives in `docs/` with YAML frontmatter and permanent IDs (`DES/TEC/PRO/ART-###`), indexed by `tools/reindex.py`.
**Rationale:** Stable IDs make conversational reference instant ("that's a DES-003 question") and prevent decisions from being silently re-litigated.
**Consequences:** Every decision requires a doc update. Index must be regenerated after edits.

---

## ADR-002 — Setting draws from Tolkien's public-domain sources, not Tolkien
**Date:** 2026-08-12 · **Status:** accepted
**Context:** Brief asked for "loosely Tolkien-based… without legal issues." Tolkien's work is under copyright until ~2044 (UK) / ~2050 (US) with actively enforced trademarks.
**Decision:** Build the setting from the Norse/Anglo-Saxon/Finnish public-domain material Tolkien himself adapted. Full guardrails in `PRO-004`.
**Rationale:** Delivers the requested texture with zero legal exposure and a more distinctive identity. The premise (a greed-cursed hoard-dragon) is *already* public domain via Fáfnir.
**Consequences:** No Tolkien proper nouns or coinages, in game or in marketing. Naming passes must check `PRO-004`.

---

## ADR-003 — Legacy slots cannot hold raw Boon
**Date:** 2026-08-12 · **Status:** accepted
**Context:** `DES-003` Legacy slots carry ≤3 things across death. Allowing raw Boon as a payload was under consideration.
**Decision:** 3 slots. Payload may be **one item** or **one skill node** only. **Raw Boon is disallowed.**
**Rationale:** Boon is fungible, so it would be the default optimal pick every time — collapsing the death screen into a percentage-retention system with extra UI. Forcing item-or-node keeps the choice specific, personal, and build-seeding.
**Consequences:** Death screen is harsher and more interesting. Legacy value is inherently capped by what a *single* item or node can be worth, which bounds power creep structurally. Watch for players feeling a death was "worthless" if they died with nothing good — mitigated by ADR-006.

---

## ADR-004 — The stash wipes on death
**Date:** 2026-08-12 · **Status:** accepted
**Context:** Whether banked gear should survive into a new life. The single harshest line in the design.
**Decision:** Stash is LIFE tier. It wipes. Only Legacy slots cross.
**Rationale:** Death is the economy's only large sink (`DES-008`). Without the wipe, value accumulates permanently and runs become risk-free by hour 20 — Failure Mode A in `DES-003`. With it, the economy self-corrects and we never need reactive nerfs.
**Consequences:** Death is severe, so **compensating retention design is mandatory** — see ADR-006 and `DES-010`. Stash cap can be relatively generous since it's periodically reset.

---

## ADR-005 — Biomes are separate expeditions of 3 floors each
**Date:** 2026-08-12 · **Status:** accepted
**Context:** Sequential floors of one continuous descent vs. discrete expeditions selected at the Lair.
**Decision:** Three expeditions (Delvings, Barrow-Fields, Sunken Wood), 3 floors each, chosen at the Lair.
**Rationale:** Modular to build, test, and balance in parallel — decisive at our team size. Preserves a descent arc within each expedition and gives better run-to-run variety. Costs some of the "went too deep" fantasy, recovered by making floor 3 of each expedition genuinely punishing.
**Consequences:** Hunt escalation resets per expedition, not per campaign. Each biome needs its own difficulty curve across its 3 floors. Extraction points must exist on every floor.

---

## ADR-006 — Every run pays something
**Date:** 2026-08-12 · **Status:** accepted
**Context:** ADR-004 makes death very costly. Retention is a stated priority. The first death is the single largest churn moment in games of this genre.
**Decision:** No run can ever return zero. Even a death advances LINEAGE — bestiary entries for what you fought, cartography for what you saw, lore for what you read, contacts for who you met. This accrues *during* the run, not on extraction.
**Rationale:** Hades' central retention insight: a failed run must still visibly move a bar. Lineage is power-free by construction (`DES-003`), so it can be paid out generously without touching balance.
**Consequences:** Lineage progression must be tracked live during a run and committed on death as well as extraction (`TEC-003`). The death screen must *show* what was gained, not only what was lost.

---

## ADR-007 — She is original, female, and drawn from Gullveig
**Date:** 2026-08-12 · **Status:** accepted
**Context:** Fáfnir — the greed-cursed hoard-dragon whose pattern the premise follows — is male in the *Völsunga saga*. The dragon is to be female, with original lore in a Norse-fantasy register.
**Decision:** The wyrm is an original character. Her *pattern* is Fáfnir's (greed-transformation, cursed hoard); her *identity* draws on **Gullveig** from *Völuspá* — thrice burned, thrice reborn, name meaning roughly "gold-power" / "gold-drunk."
**Rationale:** Gullveig is female, public domain, explicitly gold-associated, and canonically *cannot die properly* — which is exactly our wounded, immortal, mountain-fused wyrm. She is obscure enough to carry no Tolkien association. Original lore also removes the last of the IP exposure in `PRO-004`.
**Consequences:** Her true name is late-game revealed content; she is "She" / "the Wyrm" throughout. Lore may now be freely invented within the Norse-fantasy register.

---

## ADR-008 — Co-op is core, designed from the start
**Date:** 2026-08-12 · **Status:** accepted · **Supersedes** the "co-op later" lean in `DES-001`/`PRO-001`
**Context:** Co-op was previously deferred to M6 as conditional scope.
**Decision:** 1–4 players, with **2 and 4 as the primary experiences**. Solo fully supported and balanced as its own mode. Networking present from M1.
**Rationale:** Retrofitting multiplayer is a rewrite; the decision had to be made before M1 or not at all. Co-op is also the strongest available retention lever (Relatedness, `PRO-005 §4`), which matters given ADR-004's severity.
**Consequences:** Roughly **1.5–2× total project cost** — QA especially. `TEC-004` created. Milestones reordered (`PRO-001`). Host-authoritative P2P, no dedicated servers. Generation determinism becomes bit-exact-across-machines rather than merely reproducible. Design-side: pacts stay individual, which keeps progression off the network entirely (`DES-012`).

---

## ADR-009 — Six classes, gating Aspect access
**Date:** 2026-08-12 · **Status:** accepted
**Context:** Need for distinct Nordic-fantasy classes with their own skill tree variants, alongside the existing 5-Aspect shared tree.
**Decision:** Six classes (Húskarl, Völva, Skald, Úlfheðinn, Veiðimaðr, Haugbrjótr). Each has a starting kit, one unique verb, a class-only **Rite** branch (~7 nodes), and **access to 3 of the 5 Aspects**. Path of Exile Ascendancy model.
**Rationale:** Six full trees would be a content trap and unbalanceable. Shared-tree-plus-unique-branch yields 36 base identities from ~42 unique nodes. Class-gated Aspect access **resolves Q4** far better than an arbitrary lockout rule. And because class is chosen at the start of a life, **death becomes the door to a new class** — a large, free retention win against ADR-004.
**Consequences:** Class is locked for a life. Rite nodes may occupy a Legacy slot but only apply if the next life repeats that class. Every class must be solo-viable (Skald is the open problem). Q4 closed.

---

## ADR-010 — Floors scale to the highest Pact Rank in the party
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q33**
**Context:** A rank-9 player brings a rank-1 friend. Options were scale-to-highest, scale-to-average, or gate parties into rank bands.
**Decision:** **Scale to the highest rank present.** No rank gating — any two players may always play together.
**Rationale:** In co-op, **boredom is worse than danger.** Scaling down wastes the veteran's session *and* breaks their Tithe math (they can't service an escalated obligation on trivial floors). Scaling up terrifies the newcomer but gives them a protector, and the ember rescue (`DES-012`) already makes being outmatched survivable rather than punishing. Overwhelmed-alongside-a-friend is a better session than bored-alongside-a-friend. Rank-banding was rejected outright: preventing friends from playing together defeats the purpose of ADR-008.
**Consequences:** Requires ADR-011 to protect the Tithe coupling, or the design's central self-balancing property breaks. Low-rank players will be downed frequently — that is expected and acceptable, not a bug. Difficulty tuning must assume any floor can contain a wildly under-ranked player.

---

## ADR-011 — Boon is capped by your own Pact Rank
**Date:** 2026-08-13 · **Status:** accepted
**Context:** ADR-010 lets a rank-1 player extract from rank-9 floors carrying rank-9 value. Unmitigated, they would be power-levelled through the tree without ever earning it.
**Decision:** **Boon conversion is capped relative to your own Pact Rank, not the floor's.** Tribute value beyond that cap converts at a steeply decaying rate ⟨tune⟩, with the remainder paid out as LINEAGE progress instead.
**Rationale:** The Tithe only works as a self-operated flow-channel tracker (`PRO-005 §3`) if power and required depth stay coupled. A carried player gains depth without gaining skill; capping Boon means **you can be carried, but you cannot be carried past your own ability to use what you're given.** Overflow into Lineage means the run still pays generously (ADR-006) without breaking balance — Lineage is power-free by construction.
**Consequences:** Carrying a friend is socially rewarding and mechanically limited. The carried player advances fast in *knowledge* and slowly in *power*, which is the correct shape. Needs telemetry: if carried players still out-rank their competence, tighten the decay.

---

## ADR-012 — All six classes available from the start
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q31**
**Context:** Whether to gate 3 of the 6 classes behind Lineage milestones.
**Decision:** **All six available immediately.** Additional classes beyond the six become Lineage unlocks post-1.0.
**Rationale:** Variety at the point of first contact, and it preserves the death→new-class retention hook at full strength *at the first death* — precisely the moment it's most needed (`DES-010` C2). Gating would have weakened the mechanism exactly where it matters. Lineage still gets meaty class-shaped rewards; they're just *new* classes rather than withheld starting ones.
**Consequences:** All six must be playable and balanced by M4, not M5. `PRO-001` M4 updated. Post-1.0 class pipeline (starting with Smiðr) becomes the Lineage reward track.

---

## ADR-013 — Co-op cost is accepted without scope reduction
**Date:** 2026-08-13 · **Status:** accepted
**Context:** ADR-008 carries an estimated 1.5–2× total project cost. The alternative was cutting a biome or reducing the class count to pay for it.
**Decision:** **Absorb the cost. No compensating cuts.** Multiplayer is a requirement of the product, not a feature to be traded against content.
**Rationale:** Directed by the user, with the cost stated explicitly and understood.
**Consequences:** Timeline extends rather than scope shrinking. `PRO-001` milestone estimates stand as revised (M1–M4 ≈ 29–36 weeks). The M1 networking spike (`TEC-004`) becomes *more* critical, not less — with no scope buffer, discovering an architecture problem late has nowhere to absorb it.

---

## ADR-014 — 2D grid generation with in-room verticality
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q48**
**Context:** Whether the generator operates on 3D cells (true shafts and galleries between generated volumes) or a 2D cell grid with vertical detail authored inside rooms.
**Decision:** **2D grid of cells.** Verticality lives *inside* rooms — ledges, balconies, collapsed floors, chains, lifts — in the Dark and Darker manner. Cells connect on one plane.
**Rationale:** 3D cell adjacency is a permanent tax on navmesh, AI traversal, the Clamor field, and readability, for a benefit we can largely fake. In-room verticality delivers the *feel* at a fraction of the cost.
**Consequences:** Navmesh and AI stay tractable. Clamor stays a 2D grid with a cheap vertical term. **Explicit obligation:** the generator must work hard against boxiness — variable footprints, merged galleries, sightlines across cells, and visual-only vertical negative space (see `DES-015`). "2D grid" must never read as "flat corridors and boxes."

---

## ADR-015 — A run is three floors; early exfil is earned, not routed
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q49** · **Reworks `DES-005` Layer 3**
**Context:** Whether a run is one floor or the full expedition, and how extraction points work.
**Decision:** **A run is all three floors.** Extraction exists on every floor but must be *earned*: a rare found item (**Waystone**), or a fixed dangerous mechanism (**the Shaft**). Floor 3 holds the guaranteed **Deep Gate**.
**Rationale:** This converts extraction from a *routing* problem into a *resource* problem, which is strictly more interesting. The means of escape becomes lootable — and choosing to spend it is choosing to end the run early with what you have. That is one of the best decisions in the game and it was previously absent.
**Consequences:** `DES-005`'s Sealing is rewritten: Shafts seal floor by floor as the Hunt escalates, so staying makes your *cheap* exit vanish and pushes you toward the Deep Gate. Players must never be truly trapped — the Shaft is always reachable, just expensive. Waystone drop rates become a primary tuning lever ⟨tune⟩.

---

## ADR-016 — Join-in-progress through the Lair passage
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q37, reverses the `TEC-004` lean**
**Context:** Previously deferred past 1.0 as too costly.
**Decision:** **Players waiting in the Lair can join a run in progress**, arriving through a gate opened at the party's current position. Same mechanism as extraction, run backward.
**Rationale:** The exfil system (ADR-015) is *already* bidirectional — building arrival on top of it is far cheaper than a generic late-join, and it's fully diegetic: no menu, no teleport-in, they walk out of a gate next to you. Removes the worst friction in co-op sessions (a friend gets home late and can still play with you), which is a direct retention win.
**Consequences:** Requires a **world-delta sync** system — geometry comes free from the seed, but looted containers, dead enemies, opened doors, and alert states must be replicated to the joiner (`TEC-004`). **Anti-freeload rules:** the arriving player brings no accumulated loot, and **opening a gate is a loud Clamor event** — reinforcements announce themselves to the dungeon. ADR-011's Boon cap already blocks late-join Prize farming.

---

## ADR-017 — Lineage-improved map, drawn as you go
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q50**
**Decision:** The map draws itself as you explore. **Higher Lineage adds better annotation, not more coverage** — a veteran's map is *smarter*, not bigger.
**Rationale:** Preserves exploration as the thing that reveals space (so knowledge never removes the act of looking), while giving `DES-003`'s cartography tier something real to grant. Annotation is information, which is power-free by construction — exactly the category Lineage is allowed to be generous with.
**Consequences:** Annotations are the reward ladder: hazard marks, Shaft locations, likely vault positions, "a Bound died here." Needs a legibility pass — an over-annotated map becomes noise.

---

## ADR-018 — Every Calamity is her doing; the hoard is the disease
**Date:** 2026-08-13 · **Status:** accepted · **Shapes Q27**
**Context:** Whether the generated Calamities (`DES-015`) connect to the dragon, or are unrelated local disasters.
**Decision:** **All of them trace back to her.** Gold that passes through her hoard is cursed, and every civilization in the Deep died of the same disease in a different dialect.
**Rationale:** Gullveig is *already* the origin of gold-lust in the source material (ADR-007) — the myth hands us this for free. It makes environmental storytelling **accumulate across a lineage** into a pattern the player assembles themselves rather than is told. And it produces the reframe the whole game is pointed at: **you are doing, right now, the exact thing that caused every disaster you walk through.**
**Consequences:** Calamity templates are variations on one theme: *they came into her gold, and it unmade them.* Gives Q27 (her arc) its shape — the ending question becomes "do you keep feeding it?" Requires discipline: the pattern must be **discoverable, never stated**. If an NPC explains it, the whole effect dies.

---

## ADR-019 — She knew. She has forgotten. Many times.
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q55**
**Context:** Whether the wyrm understands what her hoard does to those who bring it (ADR-018).
**Decision:** **She knew once, and has burned the memory out of herself — repeatedly.** Gullveig was burned three times and reborn three times; each rebirth cost her the knowledge of what she is doing. She has *almost* remembered before. She will almost remember again.
**Rationale:** It is the only option that keeps her **genuine fondness for the player intact while she kills them.** A wyrm who knows and asks anyway is a monster (flat). One who never knew is a tragedy (inert). One who *keeps* forgetting is both, and is capable of being loved by the player and by her own victims at the same time.
**Consequences:** Her forgetting must be **mechanical, not just lore** — see `DES-006`. Requires strict writing discipline: the same rule as ADR-018, discoverable and never stated. Makes ADR-020's theme legible without a single line of exposition.

---

## ADR-020 — The theme: the thing you know is killing you
**Date:** 2026-08-13 · **Status:** accepted
**Context:** ADR-018 and ADR-019 together produce a coherent thematic spine. Naming it explicitly so it survives production.
**Decision:** The game is about **compulsion** — knowing exactly what a thing is doing to you and going back down anyway. She forgets and keeps feeding. Every dead civilization in the Deep did the same. **The player does it every run, and the systems already model it**: the Tithe escalates like a tolerance, the hoard grows and never resets, death takes everything and you descend again.
**Rationale:** Directed by the user. It unifies systems that were already designed for other reasons — that alignment is the sign it's the right theme rather than a coat of paint. It also gives `DES-007`'s Ashen Lodge real weight: they are the *light*, standing in the Lair offering a smaller, safer, worse life, and you walk past them every single run.
**Consequences — three hard rules:**
1. **Never stated.** No character names the theme. No codex explains it. Same discipline as ADR-018; violating it collapses both at once.
2. **Never accusatory.** The game does not judge the player for playing it. *Spec Ops: The Line* is the cautionary reference — it indicts the player for actions it forced on them. We show the shape and let the player draw the conclusion, or not.
3. **The character is trapped; the person is not.** A game about not being able to stop carries an obligation to make stopping easy and unpunished. This makes `PRO-005 §10`'s ethics **thematically load-bearing**: predatory retention mechanics would make us guilty of the exact thing the game is about. See `PRO-005 §11`.

---

## ADR-021 — The Lair splits: private Chamber, shared Threshold
**Date:** 2026-08-13 · **Status:** accepted
**Context:** With individual pacts (`DES-012`), a shared hub has no obvious owner. Options considered: everyone visits the host's Lair; a shared clan Lair; no hub at all, only a party menu.
**Decision:** **The Lair is two spaces.**
- **Your Chamber** — her, your hoard, the tree, your stash, the Legacy screen. **Always yours, always private, never networked, never entered by another player.**
- **The Threshold** — the mouth of the mountain outside her chamber. The Bound camp, the Ashen Lodge, the contract board, the Descent. **The only shared, networked hub space.**

**Rationale:** The Lair was doing two jobs with opposite multiplayer requirements. Tribute, her voice, and the Legacy choice are *solitary by design* — `DES-012` already established she speaks to each of the Bound separately, and four people watching you choose what she remembers is actively wrong. Assembly, contracts, and banter are *social by design*. Splitting them resolves the conflict instead of trading one loss for another.

It is also **diegetically enforced rather than technically excused**: she is fused into the mountain and cannot be approached in company. Each of the Bound goes in alone. That's a better fiction than the one we had.

**Consequences:**
- **Solo and co-op have identical flow** — Chamber → Threshold → Descent — the only difference being whether anyone else is standing in the Threshold. This is precisely the continuity a clan Lair would have destroyed.
- **The `TEC-004` architecture win is preserved.** Progression stays entirely off the network; the Chamber is a local scene. Only the Threshold replicates, and it has no simulation worth the name.
- **Rejected: the clan Lair.** It breaks solo/co-op continuity, breaks individual pacts (the property keeping progression off the network), and destroys the private hoard — `DES-014`'s strongest idea. The Threshold delivers most of the social value at a fraction of the cost.
- Threshold visual state follows **the host's lineage**, so joining a veteran shows you a fuller camp.

---

## ADR-022 — Hoard staves: an ambient, ambiguous leaderboard
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q57**
**Context:** Hoards are private (ADR-021), but a signifier of others' hoard size is wanted — a soft leaderboard reflecting time invested. `PRO-005 §11` flags this as precisely the shape a compulsion-driver takes.
**Decision:** Each of the Bound has a **rune-stave** planted at their camp spot in the Threshold, notched with what they have given her. Tall, worn staves belong to people who have fed her a long time. **No numbers, no sorting, no ranked list, no UI table.** It is read by looking.
**Rationale:** It delivers the social signal and the veteran-recognition the user wants, while the *framing* defuses the leaderboard problem: under ADR-020, a very tall stave is impressive **and** it is a gravestone. The game's own theme makes a big tally morally ambiguous rather than aspirational — which is exactly the mitigation §11 asks for, achieved through fiction rather than restriction.
**Consequences:** Signals **tenure, not skill** — it is a record of time and appetite, never a measure of competence. Must never become sortable or numeric; the moment it is a table, it's a leaderboard and the mitigation is gone. Deep Lineage may allow *reading* a stave in detail — a small, earned intimacy.

---

## ADR-023 — The Lair is thematically large, physically small
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q59**
**Context:** "The Lair should be a very big part of the game" was previously read as *physically* large, and `DES-014`'s scope note over-corrected toward sprawl.
**Decision:** The Lair is **compact and dense**. Big in narrative and mechanical weight, small in footprint. It contains only what is relevant to the individual player who lives there. The earlier "~2 minutes, few stations" constraint **stands**.
**Rationale:** Correction from the user. A large hub competes with the run (Principle 1) and dilutes exactly the intimacy ADR-021 was built to protect. Depth here comes from *what the space means*, not square metres.
**Consequences:** No hub sprawl, no fetch-walking, no filler stations. Design pressure moves to making each element carry more, rather than adding elements.

---

## ADR-024 — Vörðr: the dead choose between rescue and return
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q58**
**Context:** Barony keeps dead players in the level as useful ghosts. Proposal: additionally let a dead player **re-enter immediately with nothing**, as a redemption attempt — untried in extraction games.
**Decision:** On death you become a **Vörðr** (ward-spirit) — Barony-style: mobile, safe, minor utility (scouting, marking, slightly unnerving enemies ⟨tune⟩). From there, two exits, and **they are mutually exclusive**:
1. **Wait** — a teammate carries your ember out. **Your LIFE survives** (Scar, run loot lost).
2. **Return** — walk back in with nothing. **Your ember goes out; your LIFE is over.** Fresh life, rank 1, empty hands, still in this run.

**Rationale:** This does not weaken death — LIFE is still wiped either way you go, and ADR-004 is untouched. What it removes is *losing the rest of your evening*, which is a retention win with no balance cost. More importantly it creates a genuinely new decision: **give up on your friends saving you in exchange for playing right now.** That is a loss-aversion problem (`PRO-005 §1`) *and* a social one — returning can read as impatience or as mercy, since your ember is heavy and loud to carry.
**Consequences — two rules that keep it from breaking:**
- **Returning extinguishes your ember.** You cannot return *and* be rescued; choosing to come back is choosing that the death is final. Without this, ADR-004 collapses.
- **The returned arrive at the floor entrance, never at the party.** She spends full power opening a gate for a *new* soul (ADR-016), but a soul she just lost gets put back at the door. So return means a naked rank-1 crossing a scaled floor alone to rejoin — costly, tense, and the party must decide whether to come and get you.

Rescue remains strictly better when available (it saves the whole tree), so the two options coexist without either dominating.

---

## ADR-025 — The Threshold has two layers: camp momentum, and personal plots
**Date:** 2026-08-13 · **Status:** accepted · **Supersedes** the "Threshold state follows host lineage" note in ADR-021
**Context:** The Threshold needed both a shared stake and individual visible identity, without exposing private hoards.
**Decision:** Two independent layers.
- **Camp momentum (shared, volatile).** Population, vendor stock quality, available services, the size of the Lodge fire. Builds across successful runs. **A full-team wipe scatters it back to bare.**
- **Four campsites (personal, permanent).** One plot per party member. Grow and persist with LINEAGE. Customizable. Never lost — not to death, not to a wipe.

**Rationale:** Splitting volatile from permanent means the wipe stake is real without ever destroying investment: **you lose momentum, never property.** It also gives the design its first genuinely *shared* stake — everything else is individually pacted — which is a strong co-op bonding pressure ("don't wipe, we'll lose the camp"). And personal plots deliver visible identity in the shared space while hoards stay private (ADR-021), with the staves (ADR-022) living on them.
**Consequences:** Camp momentum must be **a bonus, never a baseline** — nothing required to play may live there, or a wipe becomes punitive and violates `PRO-005 §11`. Personal plots are LINEAGE tier, so they're power-free and can be generous. Replaces host-lineage-derived Threshold dressing.

---

## ADR-026 — Premium only. No microtransactions, including cosmetics.
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q63, Q64, Q65** · **Supersedes** the cosmetic-DLC plan in the first draft of `PRO-006`
**Context:** Paid campsite cosmetic themes were under consideration as a modest post-launch revenue stream.
**Decision:** **Premium purchase, nothing else.** No cosmetic DLC, no currency, no passes. Everything in the game is earned by playing it.
**Rationale:** Beyond the `PRO-005 §11` ethics argument, two design arguments make this an improvement rather than a sacrifice:
1. **Paid cosmetics would have broken the staves.** ADR-022 depends on the Threshold signalling *tenure*. Buyable camps make it signal *spending*, and the mitigation that made a public tally acceptable collapses.
2. **With nothing purchasable, every object in a camp is evidence.** A camp becomes an unforgeable record of what a player has done and chosen (`DES-016`) — worth more socially and thematically than a storefront.
**Consequences:** Post-launch revenue must come from **content** (new classes were already the planned Lineage track; biomes, expeditions), not cosmetics. The game must be worth its price on day one, with no back-loaded monetization. `PRO-006` rewritten. `DES-016` created to carry the earned-adornment system.

---

## ADR-027 — NPC Bound are simulated, and die of the same disease
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q68**
**Context:** NPC Bound at the Threshold persist and die permanently. Open: whether they are authored, procedural, and what triggers death.
**Decision:** **Authored person, procedural life.** ~8–10 hand-written personalities (voice, temperament, fears, dialogue with slots); generated name, class, origin, ambition, and run history. Each carries a **simulated Pact Rank and Tithe that escalate between your runs** — and dies when the math outruns them.
**Rationale:** Fully authored means everyone gets the same deaths and they stop landing on replay; fully procedural means template mush that nobody grieves. The split matches what we already do for contracts (`DES-007`) and Calamities (`DES-015`), so it's consistent rather than novel.

The simulation is the point: **they die because they got greedy, on the same curve the player is standing on.** ADR-020's theme becomes a system instead of a mood, for the price of a few numbers ticking offscreen. Foreshadowing emerges free — their stave grows faster, their talk gets confident, they ask which expedition was richest, and **if you tell them, that's where they go.** Watching someone else do it is how a player learns to see the pattern, from the outside, where it's actually visible.
**Consequences:** Requires per-NPC persistence, an offscreen tick between runs, and dialogue with procedural slots. Deaths are unannounced: stave stops, plot goes cold, gear appears in Lodge stock, a token becomes available for Memorial trophies (`DES-016`). New Bound arrive to fill empty plots. Q73 (can you save one?) left open and matters a great deal.

---

## ADR-028 — Saving a Bound: rare, costly, uncertain, and genuinely rewarded
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q73**
**Context:** Whether a doomed NPC Bound (ADR-027) can be saved, and whether saving pays anything beyond story.
**Decision:** **Rarely, at real cost, never certainly** — and it must pay mechanically, not only narratively.

**Costs:** your Waystone · tribute value to service their Tithe · a lie about where the gold was · or talking them down, which is gated on having actually known them.

**Rewards, none of them fungible with what you gave:**
1. **They keep running and keep reporting** — ongoing LINEAGE knowledge (cartography, bestiary, vault rumours), which is power-free by construction and unpurchasable at any price.
2. **They can appear in the Deep** as an unscheduled ally, reusing the existing Bound archetype (`DES-013`).
3. **They can carry your ember out** (`DES-012`) — the person you saved saves your entire LIFE.

**Rationale:** A pure-cost act of compassion, in a game already saturated with loss aversion and an escalating Tithe, would be learned as a trap and performed exactly once. That's the same failure named for the Ashen Lodge in `DES-007`: **if the kind path is strictly punished, the game is arguing that kindness is stupid.** Rewards must be non-fungible, though, or players compute the trade and a moral act becomes a shop transaction.

Reward 1 is also deliberately double-edged — **you saved them into continuing.** That keeps ADR-020 honest instead of letting compassion become a clean win.

**Consequences:** Anti-farming rules required — cannot save the same Bound twice, outcome hidden for several runs, no Boon/power/gear/Tithe relief ever. **The game never comments on it** (ADR-020 rule 2): no karma, no morality meter, no NPC praise. Simulation is cheap; **dialogue is a real ongoing writing cost**, so this is M5 work and must stay off the vertical-slice critical path.

---

## ADR-029 — Tithe comes due per 3-run cycle
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q2**
**Decision:** You owe your Tithe by the end of every **3 runs** ⟨tune⟩. Missing it is a soft fail (`DES-002`): standing lost, a debuff, possibly a skill node reclaimed.
**Rationale:** Absorbs one disaster run, so bad luck and experimentation don't default you. Matches the session shape already assumed in `DES-002` (a sitting is 3–6 runs). Gives a deadline the player can state out loud, which serves Principle 4. Two systems rather than three.
**Alternatives:** Per-run was rejected as hostile to experimentation and to short sessions. **Running-debt-with-interest** was seriously considered and is the more elegant, more thematic option — she is a creditor, and node reclamation would act as an automatic stabiliser (fall behind → she takes a node → your Tithe drops → you can pay again). Rejected for now on complexity and legibility, **not on merit.** If the 3-run boundary feels arbitrary in playtest, this is the first thing to try.
**Consequences:** Cycle length is a primary tuning lever. The cycle boundary must be unmissable in the Lair UI. Partial cycles at session end need handling so quitting mid-cycle is never punished (`PRO-005 §11`).

---

## ADR-030 — Boon is tribute-primary, with real contract income
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q5**
**Decision:** ~**70% of Boon from tribute** ⟨tune⟩, the remainder a meaningful secondary income from **contracts**. Exploration pays **Lineage only**, never Boon.
**Rationale:** The deciding argument is not class balance but **contract-system viability**: if contracts pay no progression, nobody runs them, and `DES-007`'s entire three-tier DMZ structure becomes decoration. Tribute must stay dominant so the keep-or-give decision remains the spine of progression (Pillar P1). Exploration is excluded because ADR-006 already pays it in Lineage — adding Boon would double-dip.
**Consequences:** Contract Boon rewards need tuning against tribute value so contracts are attractive but never the efficient path. Watch for a "contract-farming" degenerate strategy that skips looting entirely; if it appears, cut contract Boon before touching tribute.

---

## ADR-031 — The Skald acts on the dungeon, not just on allies
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q32**
**Context:** The Skald's Verse buffed allies, which does nothing solo — making it a trap pick for solo players and violating `DES-011` rule 1.
**Decision:** **Recast the class as a manipulator.** Songs act primarily on the dungeon and its inhabitants — maddening enemies into fighting each other, drawing the Hunt, unnerving Guardians, breaking morale. Ally buffs remain strong but **secondary**.
**Rationale:** Solo Skald becomes a *controller*, a genuinely different valid playstyle rather than a diminished co-op class. It's a reframe, not a redesign. And it's cheap: the enemy-faction hostility system in `DES-013` already simulates mutually hostile Dvergar/Draugr/Vættir, so a Skald turning one faction on another is **using AI we already have** — systems over content (Principle 5).
**Consequences:** `DES-011` Skald entry needs rewriting. The class stays the loud one — Clamor remains its defining cost — but now the noise *is* the weapon rather than a side effect. Ally-buff tuning must not make 4-player Skald mandatory.

---

## ADR-032 — Avoidability is guaranteed on the route to an exit only
**Date:** 2026-08-13 · **Status:** accepted · **Closes Q40**
**Decision:** The generator must guarantee that **at least one route from the entrance to a reachable exit bypasses every encounter on it**. Rooms the player *chooses* to enter carry no such guarantee and may well be committal.
**Rationale:** Preserves the Clamor thesis and the Veiðimaðr/Wing identities exactly where they matter — you can always, in principle, walk out without fighting. Exhaustive avoidability was rejected as expensive to validate and as making levels feel gamey (every threat visibly issued a designer's side door). No guarantee at all was rejected because two class identities and the whole noise economy rest on this, and unvalidated invariants erode silently as content is built.
**Consequences:** Becomes a hard check in **step 8 of the generation pipeline** (`DES-015`) — a validation failure re-rolls the offending sub-graph. Guardian rooms (`DES-013`) are now explicitly allowed to be committal, which sharpens them: entering one is a decision you may not be able to take back. Must be tested at M2.

---

## ADR-033 — The game is called SHE
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q13**
**Decision:** **SHE** is the title, not a placeholder. All "working title" and "TBD" language is removed from the docs.
**Rationale:** It is what the game is about — a creature the player never names, referred to only as *she*. The title withholds exactly what the game withholds (ADR-019/020), and the lowercase intimacy of it does more work than any compound fantasy name would.
**Consequences:** Trademark and handle searches should happen before any store presence. A one-word common-word title is hard to search for and hard to protect — accept that as a known cost. Her true name stays late-game content regardless.

---

## ADR-034 — Solo development, no fixed timeline
**Date:** 2026-08-14 · **Status:** accepted
**Context:** `PRO-001` carried week estimates that assumed unstated team capacity.
**Decision:** **Solo project, built as time allows.** Milestone *order* and *exit gates* stand; calendar estimates are removed and replaced with relative effort. Nothing ships to a date.
**Rationale:** Stated by the developer. Fake deadlines on a solo project produce guilt, not throughput, and the milestone gates were always the real mechanism — they're pass/fail on the game being good, not on elapsed time.

This is explicitly an **experiment in a crowded genre**: the goal is to find out what a systemically honest extraction roguelite feels like, not to hit a market window. That framing makes the M1 gate *more* important, not less — the only thing worth optimising for is whether the moment-to-moment is fun.
**Consequences:** `PRO-001` reworded. ADR-013's cost acceptance stands but is now expressed as scope-per-milestone rather than duration. Sequencing discipline matters more without a deadline forcing it: **finish a milestone gate before starting the next.**

---

## ADR-035 — Clamor is expressed through adaptive music, not alarms
**Date:** 2026-08-14 · **Status:** accepted
**Context:** The awareness ladder (`DES-013`) and Hunt state were specified as "distinct audio cues," which risked a stinger-and-alarm design.
**Decision:** **Clamor and Hunt state are carried by layered adaptive score and ambience** — instrument layers entering and leaving, drones tightening, rhythm arriving — never by alarm sounds or UI stingers.
**Rationale:** Directed by the developer, and it's the better design. Alarms are **threshold** signals; layered audio is **continuous**, so the player feels gradations rather than discrete state changes, which is what a system like Clamor actually is. It also fatigues far less over a 25-minute run, and it keeps the Deep feeling like a *place* rather than a UI.
**Consequences:** Requires a vertical-remix audio architecture from the start (`ART-001`) — layers authored together, mixed by a Clamor/Hunt driver, not one-shot cues bolted on. One instrument must be reserved to mean *the Hunter* and nothing else, ever. Raises `AudioDirector` from a budget line to a core system.

---

## ADR-036 — Every audio channel has a visual twin
**Date:** 2026-08-14 · **Status:** accepted
**Context:** The core mechanic is sound. "You should be able to close your eyes and know what state a room is in" is elegant and **excludes deaf and hard-of-hearing players from the game's central system.**
**Decision:** **A persistent on-screen cue reports room alert state and Clamor level.** More generally: every piece of information the audio carries has a visual equivalent, designed in parallel — not captioned afterward.
**Rationale:** Directed by the developer. This cannot be retrofitted: if Clamor is only ever legible through a mix, the visual language has no place to attach later. Designing both channels together also **improves the game for everyone** — a continuous visible Clamor readout serves the "explain your death in one sentence" principle directly, since you can see exactly how loud you were being.
**Consequences:** New doc `DES-018`. The cue must be readable without being noisy — it competes with weight, health, the map, and party state (`PRO-005 §8`). Must be validated at M2 by playing the prototype **with audio muted**, as a standing test.

---

## ADR-037 — The Hunter is one of the Bound who never left
**Date:** 2026-08-14 · **Status:** accepted
**Context:** The Hunter (`DES-005`) was "the dragon's rivals notice you" — vague, generic, and disconnected from the theme.
**Decision:** The Hunter is the **Gullsjúkr**, the Gold-Sick: a former Bound who stayed too long and never came out. Still carrying their hoard. Still trying to make a Tithe that can no longer be made. It **hunts carried wealth**, and it **stops to pick up gold you throw**.
**Rationale:** Ties the game's central pressure mechanism directly to ADR-018/020 instead of importing a generic antagonist. It hunts you because it is doing exactly what you are doing — **you are looking at your own future**, and the game never says so. It also connects to ADR-027: a Gullsjúkr can be an NPC Bound you knew, whose fire went out at camp last week.

Mechanically, **baiting with gold** is the counter-play that makes it specific rather than a reskinned Nemesis: throwing away treasure to survive is the game's core decision, embodied in an enemy that cannot refuse it.
**Consequences:** New doc `DES-017`. Requires carried-value tracking as a perception input alongside Clamor. Q9 (Hunt persistence across floors) resolved there. One archetype at 1.0 with biome dressing — not three Hunters.

---

## ADR-038 — Gullsjúkr identity reuses the death record that already exists
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q74**
**Context:** Whether a Hunter can be identified as a specific dead NPC Bound, and how much data that needs. Direction given: whatever is cheapest.
**Decision:** **Minimal identity, reusing existing data.** ADR-027's death record already stores what's needed for the cold plot and Memorial trophies — name, personality ID, class, lineage-run of death, final rank. Add **one boolean** (`became_gullsjukr`) and have the Hunter spawn dressed with that Bound's **class silhouette and one distinguishing token** (their coat, their helm).

**No gear reconstruction, no inventory replay, no bespoke record.** You recognise them by name and by one thing you remember about them.
**Rationale:** The expensive version — rebuilding their full loadout — buys almost nothing over the cheap one. Recognition is carried by *a name and a single detail*, which is how memory actually works. Cost is a flag and a spawn path reading fields that already exist.
**Consequences:** **Rare by design.** Most Gullsjúkr are strangers; only occasionally is one someone you knew ⟨tune⟩. If every Hunter is a dead friend it becomes cheap melodrama — the beat only lands because it's uncommon. Their stave at the Threshold stays cold either way; the game never connects the two out loud.

---

## ADR-039 — Hunter and Ear detail decisions
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q76, Q78, Q79**
Batch of recommendations accepted as specified:
- **Q76 — Gold-baiting cost is proportional to carried value**, not flat. The richer you are, the more it takes to make a thrown purse more interesting than you. Keeps baiting a real decision at every wealth level instead of a fixed toll that trivialises late runs.
- **Q78 — The Ear shows other players' Clamor in co-op**, rendered small on the **party frame** rather than on the Ear itself. Enables "you're the loud one" without cluttering the primary readout.
- **Q79 — Haptics are a third twin.** Controller rumble carries Clamor and Hunter proximity alongside audio and the Ear, for players comfortable with neither of the other channels. Cheap; must never be the *only* carrier of anything.

---

## ADR-040 — UI: Ear placement, inventory model, carried instruments
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q81, Q23, Q82**
- **Q81 — The Ear sits top right**, in the slot a minimap would conventionally occupy. Deliberate: it *is* our answer to a minimap, and putting it there says so. Keeps the centre clear (`DES-019` rule 1) and sits where players already look for spatial information.
- **Q23 — Inventory is grid-based, weighted, and real-time.** No longer a prototype fork. The grid makes hauling a spatial puzzle; weight drives movement and Clamor; the two constraints deliberately conflict. No pause — co-op forces that anyway, so **opening your bag is a vulnerable act** by design rather than by accident. Grid dimensions and cell sizes remain tuning work.
- **Q82 — The compass is an item**, alongside the map and the lantern. Three information tools that each cost a slot, weight, and often a hand. A player carrying all three is very well informed and very badly equipped for a fight — the intended trade, and good texture for Veiðimaðr and Völva builds.

**Consequence:** bearing is *equipment*, not a HUD guarantee. The Ear's coarse attention-sectors work without a compass; absolute orientation does not. Cartography annotations (ADR-017) become meaningfully more useful once a compass is carried, which is a nice reward for the loadout choice.

---

## ADR-041 — The Ear: core-and-ring, attention not positions
**Date:** 2026-08-14 · **Status:** accepted
**Context:** The Ear must carry four signals of two different natures — one continuous scalar about the player, three discrete/angular signals about the world.
**Decision:** **Inner core = you** (Clamor output: fills, brightens, quickens). **Outer ring = the world** (attention arcs light by bearing; ring character encodes the `DES-013` alert ladder; the Hunter takes a distinct heavy mark and the whole element gains weight).

**Hard guardrail: the Ear reports attention, never positions.** Coarse bearing only (8 sectors ⟨tune⟩). An unaware room produces a blank ring regardless of how many enemies stand in it. Never enemy count, health, or type.
**Rationale:** Cause on the inside, effect on the outside — the mental model the player actually needs, and it lets each half be read independently at a glance. The guardrail is what stops the Ear becoming a wallhack; without it players stare at the corner instead of the room and the entire "look at the world" premise behind the lighting and audio design collapses.
**Consequences:** Visual skin (Q85) still open — geometric ring, ember, or organic shell. The architecture holds under any of them.

---

## ADR-042 — The Ear renders as an ember
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q85**
**Decision:** The Ear's core is **a piece of her fire** — the same ember that drops when you die (`DES-012`). It flares and quickens as Clamor rises. Attention arrives on the outer ring as **drifting sparks from the direction that heard you**. The Gullsjúkr takes a heavy mark and the whole element grows.
**Rationale:** Ties the most-looked-at element in the game to what she put in you, and to the ember rescue system — the readout is literally the thing your friends carry out. Flame is naturally continuous, which suits Clamor, and it reads in monochrome through shape and motion rather than hue (`DES-018`).
**Consequences — the one real risk, and its fix:** a brighter flame reads as *good*. **High Clamor must look guttering and sick, not warm and bright** — the ember should feel like it's being blown about and giving you away, never like it's growing in power. If playtesters describe a loud state as "cool," the visual language has failed and needs desaturating, destabilising, and thinning.

---

## ADR-043 — Stepped audio states, not continuous gains
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q87**
**Decision:** The adaptive driver holds **discrete states** and crossfades between them ⟨~2–4s⟩. Not continuous layer gains following a Clamor float.
**Rationale:** Indistinguishable in play, dramatically cheaper to author, mix, and debug. Decisively, it gives the composer **something concrete to write to** — nine named states with a described mix — rather than an abstract parameter to imagine. That matters more now that a musician is delivering against a brief (`ART-003`).
**Consequences:** State table is canonical in `DES-018` and restated in `ART-003`. Crossfade length is a tuning lever; too short reads as a cut and reintroduces the stinger feel ADR-035 rejected.

---

## ADR-044 — Audio technology: stay in Godot, write occlusion, adopt FMOD later
**Date:** 2026-08-14 · **Status:** accepted
**Context:** Godot has no built-in audio occlusion. Raised as a possible reason to move the project to Unreal before development starts.
**Decision:** **Stay in Godot.** Write gradient occlusion ourselves (⟨~a week⟩). Adopt **FMOD** as middleware when the musician is onboarded and their workflow becomes the deciding factor.
**Rationale:** Verified against the Godot 4 class reference:
- `AudioStreamPlayer3D.attenuation_filter_cutoff_hz` / `attenuation_filter_db` are **per-source low-pass filters settable at runtime** — the occlusion primitive already exists. Occlusion is raycast → lerp cutoff.
- **Reverb zones are built in** (`Area3D.reverb_bus_*`), correcting an earlier overstatement in `ART-002`.
- Only genuine gap is occlusion, and **portal propagation is needed for exactly one source** (the Gullsjúkr), not as a general system.

**Switching engines to solve a week of raycasts would be a very large cost for a problem that is not real.**
**On Unreal specifically:** there *is* a legitimate argument, but it is **networking**, not audio — `TEC-004` names Godot's high-level multiplayer at 4 peers × 150 entities as the riskiest assumption in the project, and Unreal's replication is mature. Rejected for now because: Godot is the stated stronger skill and this is solo with no deadline (ADR-034); iteration speed dominates at M1; Unreal's strengths (Nanite, Lumen) are irrelevant to stylized low-poly; and `TEC-001`–`TEC-004` all assume Godot.
**Consequences:** **The M1 networking spike is the real engine decision point.** If Godot's multiplayer holds, the question is closed; if it fails, Unreal is the correct fallback — decided on measurement rather than a guess. `TEC-005` created.

---

## ADR-045 — Audio docs are a composer handoff
**Date:** 2026-08-14 · **Status:** accepted
**Context:** A musician is joining to produce all music and sound under our direction.
**Decision:** **`ART-003` is a standalone brief** — readable by someone who has never seen the rest of the corpus, containing everything needed to start work: premise, tone, the diegetic-versus-music rule, the nine Clamor states, the three sonic worlds, the Hunter, the reserved-instrument rule, instrumentation and anti-references, and full delivery specs (48 kHz/24-bit, loop discipline, dry SFX, LUFS targets, naming).
**Rationale:** A brief that requires reading thirty design documents is not a brief. Handing over a self-contained document is the difference between a collaborator who can start today and one who needs a week of meetings.
**Consequences:** `ART-003` must be **maintained as a handoff** — if a decision changes what the composer needs to know, it updates there too, not only in the design docs. Two composer-facing questions left deliberately open for their input.

---

## ADR-046 — Three-phase art pipeline: blockout, pass, final
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q30**
**Decision:** Art is produced in **three phases**: (1) **blockout** — grey/proxy geometry for design and feel, (2) **pass** — real-but-not-final models swapped in, (3) **final**. A **custom shader carries most of the art direction**, so models can be simple and consistency comes from lighting and material treatment rather than per-asset detail.

Environment volume comes from an existing owned library plus self-authored work (Blender, ShapeLab, Meshy). **Identity assets are always bespoke** and supplied on request.
**Rationale:** Decouples "does this play well" from "does this look right," which is exactly what the M1 feel gate needs — blockout is *sufficient* for M1 and M2. A shader-led direction is also the correct choice for a small team: one shader improves every asset at once, where per-asset polish scales linearly with content.
**Consequences:** **`ART-004` created** to specify what is needed, when, and in what format — the asset request schedule is now a first-class production document. Blockout must be honest about scale and silhouette or the feel test lies. The shader is a **critical-path asset**, not polish, and needs an early prototype.

---

## ADR-047 — First-person everywhere
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q26**
**Decision:** **First person, in runs and in the Lair.** No third-person camera anywhere. Players inspect their campsite, stave, and trophies by **walking around and looking at them** in first person.
**Rationale:** Consistency, and it removes the corner-peek exploit that a third-person option would have introduced into the awareness ladder (`DES-013`) and the Veiðimaðr's fantasy. `DES-016`'s "visible evidence" payoff still works — you can stand in front of your own trophies and look at them; you simply do it through your own eyes, which is arguably more intimate.
**Consequences:** Campsite and trophy assets must read well **up close and at eye level**, not as a diorama viewed from outside. Trophy placement must be reachable and readable from standing height. Third-person character models are still required for co-op (`DES-012`) — you see your *teammates*, never yourself.

---

## ADR-048 — Magic: consumable baseline, Ember for Cinder
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q25**
**Decision:** Magic is **found consumables** — runes and scrolls, scarce, spent and gone, no mana bar for anyone. The **Cinder Aspect** alone converts it into a system via **Ember**, per `DES-004`'s *Emberdebt* keystone: attacks cost Ember drawn from carried tribute. Burn your loot to burn your enemies.
**Rationale:** Keeps magic special and scarce for everyone, costs almost no UI, and avoids a regenerating resource becoming the reliable answer to every problem (which would flatten `DES-008`'s sidegrade philosophy). It also gives Cinder a genuine identity instead of being a damage-flavour path — the "stat stick with a portrait" failure `DES-004` explicitly warns against.
**Consequences:** Scroll and rune drop rates become a real tuning lever. Ember UI exists only for Cinder builds. Non-Cinder players should still find magic often enough that it feels present.

---

## ADR-049 — Three endings, and the door
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q56 and Q27**
**Context:** ADR-018 made the final question *"do you keep feeding it?"*, so an answer had to exist.
**Decision:** **The ending mirrors the Gullsjúkr's two solutions (`DES-017`), plus a third the Hunter never gets.**

1. **Take everything** — the secret fight. Kill her, claim the hoard.
2. **Give enough to rest** — return the hoard until she can finally die properly. The mercy ending.
3. **Refuse** — a door. Walk out. A skippable cutscene resolves the story, **and the game quits itself.**

**Rationale:** The player has been rehearsing this choice all game at Gullsjúkr scale without knowing it — take everything it has, or give it enough to rest. The ending is the same decision at the largest possible scale, which means the moral grammar was taught through play rather than exposition.

**On the fight not breaking continuity:** *taking everything* is **already** one of the two established answers. Killing her is the **greed ending** — the ultimate act of the thing the whole game is about, consuming your own patron. That is thematically coherent, not a violation.

**The gate is understanding, not gear.** She cannot be brute-forced. The fight becomes available only once the player has assembled the **Calamity marks** (`DES-016`) — that is, once they have worked out what the gold does. **Knowledge is the weapon.** This finally pays out the LINEAGE tier in something other than convenience, without breaking ADR-006 (it grants *access to an ending*, never power), and it is exactly right: you can only end the cycle once you have seen it.

**The three burnings** (ADR-019) give the fight its structure — she has died three times and returned. Phases, and a reason she cannot simply be killed.

**On the door:** quitting the game is the correct closing act for a refusal ending, and *"they'll be back, they always come back"* is the last line. **Critically, nothing is deleted.** Her memory persists, the lineage persists, the camp persists. Launch it again and you are at the Threshold, and she does not mention it. **The game is right, and you prove it.** Deleting the save would also violate `PRO-005 §11` — stopping must stay unpunished.
**Consequences:** The door must be unmistakably intentional, never readable as a crash — a deliberate, slow, authored sequence. Endings are **small by design**: a room, her voice, a last screen. No cinematics; cheap if authored as text and audio. The fight is the only large content cost and it is optional, late, and gated.

---

## ADR-050 — Bulk resolution pass
**Date:** 2026-08-14 · **Status:** accepted
Thirty-seven open questions resolved in one sweep, all taking the standing documented recommendation. Recorded together rather than as separate ADRs because each was already reasoned in its home document and none was contested.

**Loop & economy:** Q8 *(superseded by ADR-015 — Shaft known per floor, Waystones found)* · Q10 quit mid-run = suspend + forced resume, dropping in co-op leaves you a Vörðr · Q11 caches do **not** survive death · Q12 echoes drop local-only loot first · Q14 barter plus one soft currency for services · Q15 modest stash slot cap, Lineage expands · Q16 faction standing = threshold for access, spendable for favours · Q69 the Lodge sells Waystones rarely and expensively

**World & narrative:** Q17 lineage of nobodies with light customisation · Q18 authored faction voice per archetype + procedural specifics · Q45 she visibly changes across a lineage, further fused into stone each time · Q47 memorial wall at the Threshold · Q51 one authored set-piece floor per expedition, at floor 3 · Q52 **the level does not change mid-run at 1.0** — unbounded world-delta cost against ADR-016 late join

**Enemies & stealth:** Q41 enemies never pick up loot; only Gilded carry · Q42 stealth takedowns exist but are slow, positional, and impossible while heavily laden · Q43 no respawns, but the Hunt repopulates cleared space

**Co-op & the dead:** Q34 solo self-recovery once per run, costly, never better than a friend · Q35 one pact across solo and co-op · Q38 duplicate classes allowed in a party · Q39 all classes open to all gender presentations · Q46 players may trade gear, never tribute (would route around ADR-011) · Q61 the Vörðr window is visible and shortening · Q62 Vörðr utility is scout and mark only, no combat effect · Q86 as a Vörðr the Ear's core goes dark, the ring stays live · Q90 Vörðr audio = the world going quiet around you

**Lair & deeds:** Q44 the hoard is genuinely dynamic geometry, everything else prop-swapped · Q66 momentum loss removes services, but only pure-convenience ones · Q70 deeds are secret, discovered through Bound gossip · Q71 rescue deeds record who you carried out · Q72 plot space is finite, forcing curation of what you are known for

**UI & audio:** Q83 the Tithe is surfaced quietly on the Burden layer during runs · Q84 the ping wheel and the silent-gesture system are one system · Q88 the Threshold theme grows with camp momentum · Q91 raw Godot audio first, migrate to FMOD when the musician is onboarded

**Consequences:** `OPEN-QUESTIONS.md` rewritten. Stale rows removed (Q13, Q37, Q53, Q67, and duplicates of Q23/Q27). **Nothing now blocks M1 or M2.** What remains is deferrable, or answerable only by a build.

---

## ADR-051 — The ink shader: three layers, three different spaces
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q94, Q100**
**Context:** Where hatching lives — screen-space or object-space — is the most consequential technical decision in the visual direction. Researched rather than guessed.

**The literature:** Bénard, Bousseau & Thollot (2011) identify three goals of stylised animation — **flatness, motion coherence, temporal continuity** — and establish that they are **inherently contradictory**; every technique is a trade-off. Praun, Hoppe, Webb & Finkelstein's *Real-Time Hatching* (SIGGRAPH 2001) chose **object-space coherence** via Tonal Art Maps: mipmapped, *nested* hatch images per tone.

**Decision:** **Don't pick one space — split the layers, and let each sacrifice a different goal.**

| Layer | Space | Wins | Sacrifices |
|---|---|---|---|
| Paper & grain | Screen-space | Flatness — it *is* the page | Motion coherence, correctly |
| **Hatching** | **World-space triplanar** | Motion coherence + temporal continuity | Some flatness |
| Outlines | Screen-space + boil | Flatness + the hand-drawn read | Temporal continuity, **deliberately** |

**Rationale:** First-person with a constantly moving camera makes screen-space hatching shower-door badly, in the player's face, for the entire run — decisive. The fiction is that *the world is drawn*, not that you are looking at a drawing, so ink belongs to surfaces. And a real woodcut's lines describe form.

The outline row is the elegant part: **the boil is the artefact, embraced.** It also matches hand-drawn practice, where contours are redrawn every frame while fills are held or shot on twos.

**Implementation is triplanar, not lapped textures** — 4–6 **nested** hatch layers (the core TAM insight, and what prevents popping across tone changes), projected in world space at fixed density, blended by quantised lit tone, with mipmaps handling distance. Full TAM parametrisation over a curvature direction field is far beyond a solo project.

**Q94 answered:** vertex colours — **R** outline weight, **G** hatch density bias, **B** ink/material ID.
**Consequences (`ART-004` updated):**
- ✅ **Environment assets need no UVs.** Triplanar removes an entire authoring stage — a direct windfall for a pipeline built on purchased kits and Meshy output.
- ⚠️ **Hard edges become art-critical.** The outline pass reads the normal buffer; all-smooth models produce weak or missing interior lines. Author explicit split normals; check every model flat-shaded before export. **Silhouette and edge flow are the art now**, replacing texture detail.
- ⚠️ **Scale accuracy becomes art-critical.** World-space triplanar means a wrongly-scaled model gets wrong hatch density — a visual bug, not a tidiness issue.
- **Forward+ is locked** (`TEC-005`): `hint_normal_roughness_texture` is Forward+ only and per the Godot issue tracker is not expected to reach Mobile or Compatibility. No low-end fallback for the normal-buffer outline pass.
- Known gap: depth+normal edge detection misses coplanar same-orientation boundaries. Mitigate via the ink-ID channel; an object-ID buffer is the full fix if prototyping shows it is needed.

---

## ADR-052 — Forward+ renderer, chosen for lighting first
**Date:** 2026-08-14 · **Status:** accepted
**Context:** ADR-051 noted `hint_normal_roughness_texture` is "Forward+ only," which read as a platform limitation. It is not — **"Mobile" is the name of a Godot renderer, not a platform.** Targets are Windows, macOS and Linux on Steam, where Forward+ is the default.
**Decision:** **Forward+**, via Vulkan / Direct3D 12 / Metal.
**Rationale — the shader is the *secondary* reason.** Mobile and Compatibility cap omni/spot lights at **8 per mesh**; Forward+ uses a clustered light grid with **no per-object limit**. Our lighting design is built on darkness as a mechanic with up to four moving player lanterns, braziers, the Threshold fire, the ember, and dropped lights. A corridor with a 4-player party would exceed 8 lights routinely and start dropping them per-object — visibly, and worst exactly when a scene is most dramatic.

**We would pick Forward+ for the lighting alone. Normal-buffer access is a free consequence.**
**Consequences:** No web export (Compatibility only, and not a target). Hardware floor of roughly Vulkan 1.0 / D3D12 / Metal-capable GPUs — 2012-era and later, negligible for premium Steam. Forward+ has a higher base cost but lower scaling cost, which suits a dark scene full of small lights. Fallbacks documented in `TEC-001` (custom normal pass, or depth-derived normals) but not needed.

---

## ADR-053 — Combat is a temptation with a price
**Date:** 2026-08-14 · **Status:** accepted · **Revises the `DES-009` thesis**
**Context:** *"Combat should usually be a bad idea"* was strategically correct but, taken literally, would produce a large system nobody enjoys touching.
**Decision:** **Combat is a temptation with a price — exactly like loot.** All the cost, avoidance and Clamor design stands; what changes is that **feel is not optional polish, it is what makes the strategic layer function.**
**Rationale:** If fighting feels bad, players resent being pushed into it **and — worse — choosing not to fight stops costing anything.** A refusal is only meaningful if the thing refused was attractive. Greed works in this game because treasure is genuinely desirable *and* genuinely expensive; combat must be built the same way.

**Research grounding (`DES-009` expanded):**
- **Swink's ordering** — real-time control → predictable simulated space → polish that *amplifies what already works*. Becomes an M1 production rule: **the grey box must feel decent unjuiced.** Juice cannot rescue bad control, only mask it long enough to build a game on top of the problem.
- **The three features that empirically dominate impact feel** — *hitstop, sound coherence, camera control* (IEEE GEM 2022, NLP analysis of Steam reviews across best/worst-rated action games, 19 features tested). Neglecting any one significantly reduces satisfaction. Unusually actionable for a solo project: it says where to spend, and by omission where not to.
- **The 250 ms floor** — human visual reaction time. **No enemy attack telegraphs under 250 ms; standard attacks 400–600 ms** ⟨tune⟩. This is Principle 4 with a number attached: an attack faster than reaction time produces a death the player cannot explain, which `PRO-005 §5` identifies as the attribution failure that makes people quit rather than retry.
- **Depth comes from the situation, not the input.** Button count stays tiny; depth is terrain, hazards, mutually hostile enemy factions, throwables, weight, and Clamor — all already designed. References: *Dark Messiah* (environment is the depth), *Vermintide* (few inputs, enormous feel investment).

**Consequences:** Hitstop scales with weapon weight and is **client-side visual only** — never a simulation pause, or co-op desyncs. **First-person overrides the general camera advice: positional kick only, never rotational shake** (motion sickness), with hands and weapon carrying the impact. Combat audio does double duty as juice *and* Clamor signal. Input buffering during recovery is required or committal reads as unresponsive. New M1 test protocol, and its gate question is **"does a tester voluntarily swing at something they could have walked past?"**

---

## ADR-054 — 2m modular kit grid
**Date:** 2026-08-14 · **Status:** accepted · **Closes Q95**
**Decision:** Architecture is authored on a **2 metre grid**.
**Rationale:** Cell-based generation (ADR-014) wants a shared module size, and 2m divides cleanly into the corridor and room widths a first-person game needs while staying fine-grained enough for interesting silhouettes. A 4m grid would force coarser spaces and fewer, chunkier rooms. Makes environment modules interchangeable across biomes, which multiplies the value of every piece authored.
**Consequences:** All architecture snaps to 2m. Triplanar hatch density (ADR-051) is world-space, so grid discipline and scale accuracy reinforce each other. `ART-004` updated.

---

## ADR-055 — Data schemas: traits, not a class tree
**Date:** 2026-08-14 · **Status:** accepted · **Delegated decision**
**Context:** `.tres` shapes for items, enemies, skills, contracts, loot. Direction given: take the best recommendation.
**Decision:** **`ItemResource` = core physical facts + an array of trait resources**, not an inheritance tree. Full spec in **`TEC-006`**.
**Rationale:** `DES-008` deliberately makes items occupy several categories at once — a jewelled sword is gear *and* tribute; a grave-good is tribute *and* cursed *and* aggros a Draugr; a lantern is a light source in a weapon slot. An inheritance tree forces each into one bucket and then needs escape hatches everywhere. Composition handles it natively: a jewelled sword is `[Wieldable]` with a high `tribute_value`, and needs no new class.
**Consequences:** Stable string IDs, never resource paths, so moving a file cannot break a save (`TEC-003`). Data never contains behaviour — resources declare `effect_tags` and systems react, which keeps `DES-004`'s "no node is purely numeric" rule *enforceable* rather than aspirational.

**A CI validator is part of the decision, not an afterthought:** it fails the build on duplicate IDs, dangling references, keystones with no effect tags, free-money items — and on **any attack telegraphing under 250 ms** (ADR-053). A design rule that isn't checked is a design rule that erodes. Build it with the first ten resources, not the first thousand.

---

## ADR-056 — Equipment slots, and how gear renders
**Date:** 2026-08-15 · **Status:** accepted · **Closes Q96**
**Context:** Q96 asked whether first-person arms are universal or per-class. Answering it surfaced a real gap: **every document referenced "slots" and none defined them.** The two questions are the same decision.

**Decision — six slots:** Main hand · Off hand · Arms · Head · Body (torso *and* legs, one piece) · Pack. **No trinket slots** — `DES-009` already rejected a stat block as a third balance axis, and trinkets are that axis in a hat.

**Arms:** shared skeleton, **shared animation set**, **per-class bare arms** (six meshes), with the Arms slot rendering over them. All armour is visible.

**The cost-bounding rule: body armour stops at the elbow; the Arms slot owns everything below it.** Therefore **only the Arms slot ever needs a first-person mesh variant** — Head, Body and Pack are never in your own view. Without this rule every chest piece needs an FP sleeve variant and the armour budget roughly doubles.

**Rationale:** The expensive part of first-person arms is animation, not meshes, and the shared skeleton (`ART-004`) means it is authored once. Six bare-arm meshes buy most of the class identity for a fraction of bespoke cost. Body-as-one-piece halves the armour mesh count for a difference stylised low-poly barely registers.

**Reconciliation with `DES-008`:** "better gear" must mean **more appropriate, better preserved, better provenance — never bigger numbers.** A Dvergar king's mail looks extraordinary and is still a sidegrade. Visual progression tracks *where you have been*, not how strong you are — the same logic as `DES-016`'s trophies, and a better fantasy than a stat ladder.

**Consequences:** **Attachment sockets for all six slots must be defined on the rig before any character work** — adding one later means re-exporting every mesh. Per armour set: 4 meshes, not 5, and not doubled for first person. The **Pack slot sets inventory grid size**, making the upgrade that increases your capacity the same upgrade that makes you heavier and louder — Pillar P1 as a piece of gear, and visible on your back so teammates can see who is hauling. Condition renders as line roughness under the ink shader, so a glance at your own hands reports how the run is going. `DES-020` created; the onboarding doc is deferred and deliberately unwritten (ADR-065).

---

## ADR-057 — Equipment details and the rig attachment spec
**Date:** 2026-08-15 · **Status:** accepted · **Closes Q105, Q106, Q107**
- **Q105 — Off-hand swapping is mid-run, slow, and interruptible.** Same rule as opening the bag. Without a real time cost the lantern-versus-shield tension evaporates, because you would carry both and swap freely.
- **Q106 — A *no pack* option exists.** Tiny grid, minimal weight, near-silent. Free to build (it is the absence of a mesh), available to any class, and the purest expression of refusing the greed loop: *I came for one thing.*
- **Q107 — Rites visibly change your bare arms.** A mesh swap at two or three thresholds. **Non-numeric progression visible on your own body**, which `DES-022` names as the primary mitigation for horizontal progression feeling flat.

**Rig attachment spec — decided now because adding a socket later means re-exporting every mesh on the rig.** Skinned (deforms): **Body, Arms**. Socketed (rigid): `sock_head` · `sock_hand_r` · `sock_hand_l` · `sock_back` · `sock_hip_r` · `sock_hip_l` · `sock_shoulders` (reserved, unused).

**The two hip sockets are the cheap win:** a weapon you are *not* holding is visible stowed on your hip, so in co-op you can read someone's loadout at a glance. Party composition legibility for two bones and a transform.

---

## ADR-058 — The power model is capability, not numbers
**Date:** 2026-08-15 · **Status:** accepted · **`DES-022` created**
**Context:** *"If gear doesn't make you stronger, what lets you fight stronger things?"* The answer was implicit across `DES-003`, `DES-004`, `DES-008` and `DES-013` and stated in none of them — which is exactly how a design drifts back into a stat ladder.
**Decision:** Documented as a single page. **You do not get stronger; you get harder to kill, better prepared, and better informed.** Illustrative shares: player knowledge ~35% · Lineage knowledge ~15% · Aspects and Rites ~25% · loadout and preparation ~15% · consumables and condition ~10%. **Roughly half of effective power is knowledge.**

**The matching half — what "a rank-9 floor" means:** **enemy archetype stats are fixed. Difficulty scales by composition, density, modifiers, Hunt timing, time pressure and layout — never by giving the same enemy bigger numbers.** A Wretch is always a Wretch. An under-ranked player dies to *more things, worse things and less time*, which is also why a carried friend (ADR-010) survives at all: an unaware enemy is harmless whatever its stats.
**Rationale:** The Tithe coupling (`DES-003`) only functions if power is capability. If power were a stat ladder, players would out-scale the Tithe and the escalation would stop meaning anything — the exact trivialisation `DES-003` was built to prevent.
**Consequences:** **Archetype stats are set once and changed only by ADR** — the likeliest decay path is someone nudging Thursar damage each patch until archetypes *are* a ladder. The review test for any proposal: **"does this let the player do something new, or does it just make an existing number bigger?"** The second requires an ADR and a very good reason. Known risk accepted: some players will not *feel* progression — if playtest says "I don't feel stronger," the fix is louder keystones, not bigger numbers.

---

## ADR-059 — Voluntary descent above your rank
**Date:** 2026-08-15 · **Status:** accepted · **Closes Q108**
**Decision:** Players may **choose to descend above their Pact Rank.** Richer floors, worse composition, earlier Hunt. **The Tithe is still calculated at your own rank**, so it is a risk accepted rather than a shortcut taken, and `DES-003`'s power↔obligation coupling holds. Unlocks around Rank 4 ⟨tune⟩.
**Rationale:** Thematically it is greed again, at the level of the run itself. Mechanically it gives a skilled player a way to convert competence into reward without waiting for the tree — **and it lands as a pacing valve in the mid-life sag** (ADR-060), which is where the design most needs one.
**Consequences:** Watch that it does not become the *optimal* line; if over-ranked descent is strictly better EV, the rank system stops meaning anything. Boon remains capped by your own rank (ADR-011), which already blocks the worst version.

---

## ADR-060 — Progression pacing: the mid-life sag, and how growth is felt
**Date:** 2026-08-15 · **Status:** accepted · **`DES-022` expanded**
**Context:** Direction given: verify the systems are balanced and that the player genuinely feels growth across runs, before any further planning.
**Finding — the felt-growth curve sags in the middle.** Runs 1–3 (knowledge acquisition) and 4–10 (first keystone) feel excellent. Runs 26+ feel excellent. **Runs 11–25 are flat**: lesser nodes are small, the knowledge curve has flattened, and gear is sidegrades so there is no upgrade rush. `DES-010` independently names this exact window as churn point **C3** — two separate analyses landing on the same runs makes it real, and it is the single largest threat to *"stronger and stronger."*

**Decision — three levers aimed at the sag:**
1. **Cluster *greater* nodes at Ranks 4–6**; front-load lesser nodes at 1–3, where knowledge growth already carries the feeling. Free — it is only a question of where nodes sit on the tree.
2. **Rite branch unlocks at Rank 3** ⟨tune⟩, not Rank 1 — a second identity beat arriving as the first wears off. **Visible arm changes at Ranks 3, 5 and 7** (ADR-057), placed precisely where nothing else is changing.
3. **Over-rank descent unlocks around Rank 4** (ADR-059) — a growth outlet that costs no content.

**The rule:** growth is felt through **eight channels** — node acquired · gear visibly improved · Lineage knowledge · a deed · the hoard growing · Rite arm change · camp momentum · new access. **Every run must visibly tick at least two.** Stronger than ADR-006's "no run returns zero," and checkable in telemetry rather than a matter of opinion.

**The scaling model ⟨all tune⟩:** ~32 nodes accessible in a life, ~20 taken by Rank 9 (≈60%, so builds diverge and a second life with the same class still plays differently). **One node per ~2 runs, flat at every rank.** Costs: lesser 1 · greater 2 · keystone 5. **Boon income stays roughly flat across ranks** — tribute services the Tithe first, and the Tithe rises with every node, so a rank-7 player must extract far more to earn the same Boon. That is the intended treadmill: **the feeling of growth comes from nodes being loud, not from the rate accelerating.**
**Consequences:** M3 gets explicit balance tests (`DES-022`), with **self-reported growth across runs 11–25 as the headline metric.** If testers say they have stopped feeling growth there, no amount of late-game power recovers it — they will already have left.

---

## ADR-061 — M4 rescoped to an actual vertical slice
**Date:** 2026-08-15 · **Status:** accepted · **Revises `PRO-001` M4/M5**
**Context:** A pre-mortem pass (`PRO-007`) checked M4 against the standard definition of a vertical slice and found it mis-scoped.
**The definition:** a vertical slice is **a small, polished, fully playable cross-section showing all major systems working together** — typically 10–30 minutes. It is distinct from a prototype, which is rough and tests specific mechanics.
**The problem:** M4 specified *all six classes* and a *45-minute* target. Six classes is **breadth, not a cross-section** — it is the one axis of the game that adds no new *systems*, only more content. As written, M4 would have delayed the moment we learn whether the game is worth finishing by months of pure content work.
**Decision:** **M4 ships two classes (Húskarl and Veiðimaðr — opposite loop relationships) and targets 25 minutes** ⟨tune⟩. All six remain required *for launch* (ADR-012 — they are available from the start), but they move to **M5**.
**Rationale:** The slice's job is to prove the game is worth finishing. Class breadth is what you build **once you know that it is.** Two classes with opposite relationships to the loop demonstrate that the class system works, which is what a slice needs to show.
**Consequences:** M4 gets meaningfully smaller and arrives sooner. M5 absorbs the remaining four classes plus the onboarding design work. **ADR-012 is unchanged** — all six at launch, availability from the start; only the milestone placement moved.

---

## ADR-062 — Standing pre-mortem, and three actions from the first one
**Date:** 2026-08-15 · **Status:** accepted · **`PRO-007` created**
**Context:** Final cohesion pass before development. Rather than more design research, ran Klein's pre-mortem (HBR 2007) — assume the project already failed, then explain why. Prospective hindsight measurably improves risk identification.
**Findings, ranked by likelihood.** The top risk is **not** technical: **M1 never ends.** ADR-034 removed deadlines correctly, but deadlines were also what ended iteration, and nothing replaced them. Then: the ink shader consuming months as a novel four-part effect; scope (the authored floor is genuinely large for one person); *"it was elegant and it wasn't fun"*; co-op QA; **no marketing plan anywhere in 38 documents**; documentation becoming the project; burnout; the door reading as a crash.
**Three actions taken now:**
1. **ADR-061** — M4 rescoped to an actual slice.
2. **A weekend shader spike before M1 proper**, grey boxes, outlines and boil only — with an explicit fallback to flat quantised shading if it is not ~70% convincing. Hatching and the two-world inversion are separable later additions, not prerequisites.
3. **A devlog starts when the shader works.** The ink style is *screenshot-legible*, which is rare and valuable, and it is the only realistic distribution a solo premium title gets.

**One pre-authorised escape hatch, recorded because a pre-mortem is where unsayable things belong:** *if co-op is what stops this shipping, solo-first with co-op post-launch is available.* The architecture already supports it — pacts are individual and progression never touches the network. **This does not reverse ADR-008**; it makes the option exist later without feeling like defeat.
**Consequences:** **Re-run the pre-mortem at every milestone gate** — the failure modes that matter at M3 are not the ones on this page. "Decent unjuiced" is a *bar to clear and stop at*, not an aspiration to chase. Iterations are timeboxed at two weeks; combat feel is revisited **once**, at M4, with real assets.

---

## ADR-063 — Milestone progress is notation inside PRO-001, not a separate ledger
**Date:** 2026-08-15 · **Status:** accepted · **`tools/status.py` created**
**Context:** Progress across milestones was legible only by reading `PRO-001` prose and remembering what had actually been built. A tracking system needs machine-readable state, which normally means a `milestones.yaml` or an issue tracker. `PRO-007` names **"M1 never ends"** as the top project risk — a tracker that cannot show a gate standing open does nothing about it.
**Decision:** **Milestone state lives in `PRO-001` itself**, as checkbox tasks carrying permanent IDs (`M1-T01`), a `<!-- milestone id= depends= size= -->` comment per milestone, and `> **GATE Mx EXIT|COOP** \`state\`` lines. `tools/status.py` parses this file directly and renders it to a terminal view, `docs/STATUS.md` and `docs/status.html`. No parallel ledger file exists.
**Rationale:** A second file describing the same milestones drifts from the roadmap within weeks, and then neither is trustworthy. Keeping the state in the document already being read means updating progress and updating the roadmap are the same act. Cost: `PRO-001` is now load-bearing for a tool, so its formatting has rules. That is a fair trade for one source of truth — the same trade ADR-001 already made for the docs corpus.
**Consequences:** Task IDs are permanent and never renumbered; a cut task keeps its ID with a `[-]` state and a reason. `PRO-001` is `accepted`, so scope changes still require an ADR — this entry authorises the *notation* only, and the original conversion changed no scope item. Gate states are `pending | passed YYYY-MM-DD | failed YYYY-MM-DD — <reason>`; a failed gate is a normal working state, not an alarm, per ADR-034. Sizes are relative weights only and are `unknown` where `PRO-001` never stated one. **No part of this notation may be extended to express dates, durations, or velocity** (ADR-034) — the tool reports scope covered, never time remaining. `status.py --check` enforces sequencing: no task may leave `[ ]` while the milestone it depends on has an unpassed gate.

---

## ADR-064 — No stubs, no placeholders, no parallel fallbacks
**Date:** 2026-08-15 · **Status:** accepted
**Context:** Directed. Several existing decisions violated this and are corrected below.
**Decision:** **Build fewer things completely rather than many things partially.**

Three distinctions that make this workable rather than absolutist:

| | Verdict |
|---|---|
| **Absent** — not built yet, not present in the build, not in any menu | ✅ **Correct.** This is scoping. |
| **Stub** — present in the build but empty, fake, or non-functional | ❌ **Banned.** It lies to playtesters and rots silently. |
| **Parallel fallback** — a second, worse code path maintained alongside the real one | ❌ **Banned.** Doubles maintenance and hides failure. |
| **Gate decision** — one path chosen once at a decision point, the other never built | ✅ **Correct.** Not a fallback; a choice. |

**Rationale:** A stubbed class in a class-select screen is worse than no class — a playtester picks it, it does nothing, and the feedback is worthless. A maintained fallback path is worse than a decision, because it defers the decision forever while costing upkeep in both branches.

**The sanctioned-exception test.** A placeholder is permitted **only** if it has **both**:
1. a **named replacement task with a permanent ID** in `PRO-001`, and
2. a **milestone by which it is gone**.

Anything else requires an ADR naming the specific stub, why it is unavoidable, and when it dies.

**What this legitimately permits:**
- **Blockout art** (ADR-046) — a *named production phase* with a scheduled replacement, not a placeholder. Passes both tests.
- **`⟨tune⟩` numbers** — data, not systems, and already governed by `CLAUDE.md §1`.
- **Grey-box levels at M1** — same reasoning as blockout.

**Corrections made to existing decisions:**
- `PRO-001` M3-T01/T02 said *"three Aspects stubbed"* and *"four classes stubbed."* **Changed to absent.** Unbuilt classes do not appear in the class-select screen at all.
- ADR-062's shader fallback reworded: it is a **one-time gate decision at the spike**, not a second renderer maintained in parallel.
- `TEC-001`'s alternative normal-buffer approaches are marked **recorded, not built** — they exist to close a question, and no code will be written for them.

**Consequences:** A milestone ships fewer, complete features. `status.py --check` should flag any task whose description contains stub/placeholder language without a paired removal task. **The M4 slice is unaffected** — it was always "all systems present, less content," which is exactly this policy.

---

## ADR-065 — Every accepted doc has an implementing task; every milestone has a gate
**Date:** 2026-08-15 · **Status:** accepted
**Context:** A tracking pass found seven accepted documents with no task implementing them, one milestone with tasks but no exit gate, and one dangling reference to an unwritten doc.
**Decision:**
1. **Every accepted doc is either scheduled or explicitly parked.** Tasks added for `TEC-002`, `TEC-006`, `ART-003`, `ART-004`, `ART-005`, `DES-016`, `DES-020`.
2. **Every milestone has an exit gate.** `GATE M5 EXIT` added — without one a milestone can never be cleared, and nothing may depend on it.
3. **The dangling forward reference to an unwritten onboarding doc is removed.** Onboarding is real M5 work, but **a reference to a document that does not exist is itself a stub** (ADR-064). The M5 task now names the deliverable rather than citing a phantom ID. Writing it now would also violate the pre-mortem's *"documentation became the project"* warning — it is not needed to start development, and the doc will get the next free `DES-` number when it is actually written.

**Rationale:** An accepted document with no implementing task is indistinguishable from an abandoned one. The three states must be visible and distinct: **scheduled**, **deliberately parked**, or **not accepted yet.**
**Consequences:** `PRO-001` gains ten tasks and one gate. `status.py --check` should fail on any accepted doc with no implementing task and no explicit park marker, and on any milestone with tasks but no gate.

---

## ADR-066 — Autoloads are created when they have work, not registered in advance
**Date:** 2026-08-15 · **Status:** accepted
**Context:** `M1-T08` reads *"…**autoload stubs** against the ≤6 budget…"*. ADR-064 banned stubs and swept `PRO-001` for the word, correcting `M3-T01` and `M3-T02` — **it missed this line.** Building the skeleton forced the question, because six autoloads registered before anything uses them are six empty singletons: precisely the artefact ADR-064 describes as *"present in the build but empty."*

Every one of the six in `TEC-001` fails the completeness test today. `EventBus` with no signals is an empty file. `Config` with no `TuningProfile` to load returns nothing. `GameState`, `RunManager`, `SaveSystem` and `AudioDirector` each need a system that does not exist yet. None can be *complete* at `M1-T08`, because none has a caller.

**Decision:**
1. **`M1-T08` registers zero autoloads.** Each of the six named in `TEC-001` is created by the first task that gives it real work — `Config` at `M1-T01` (the controller's first tunable values), `EventBus` at `M1-T02` (the first real signal), and so on.
2. **The ≤6 budget is enforced by CI, not by pre-population.** `tools/check_project.py` fails the build if `project.godot` registers a seventh. The budget was always about refusing the seventh; it was never about reserving six.
3. **The wording of `M1-T08` is corrected** from *"autoload stubs against the ≤6 budget"* to *"the autoload budget enforced in CI"*, completing ADR-064's sweep.

**Rationale:** An empty autoload is worse than an absent one in exactly the way ADR-064 names — it is present, it is importable, and the next person needing a global reaches for the existing empty singleton instead of asking whether it should exist at all. A budget is a *refusal mechanism*; a machine check refuses reliably, a reserved slot does not refuse at all. This is "prefer subtraction" (`CLAUDE.md` §2) applied to architecture before there is any code to subtract.

**Consequences:** `game/autoload/` stays an empty directory until `M1-T01`. `project.godot` has no `[autoload]` section, and `check_project.py` reads a missing section as zero. The six names in `TEC-001` remain the sanctioned list — this changes *when* they appear, not *which* exist. With the wording fixed, the stub-language check that ADR-064 asked `status.py --check` to perform is implementable without failing on `PRO-001`'s own text, and is now built — a task description carrying stub language must cite either the ADR that governs it or the task ID that removes it.

**Rejected alternative:** register all six now and grant ADR-064 a sanctioned exception naming the milestone by which each stops being empty. Rejected because the exception would have to be renewed six times for six different reasons, which is how a policy becomes decorative.

---

## ADR-067 — The enforcement ADR-064 and ADR-065 specified is now built
**Date:** 2026-08-15 · **Status:** accepted
**Context:** ADR-064 and ADR-065 each closed with a sentence beginning *"`status.py --check` should…"*. Three checks were specified between them; **one was implemented.** Building `M1-T08` surfaced this, and it is the more serious half of the same failure ADR-066 records: a policy that is written but not enforced is indistinguishable from one that was never agreed, and it decays in exactly the direction the policy existed to prevent.

The unimplemented ones were the two that would have caught real drift — stub language in task descriptions (ADR-064), and an accepted document with nothing scheduling it (ADR-065). The third, milestones with tasks but no gate, existed only as a warning, which `--check` does not fail on.

**Decision:**
1. **Stub language in a task description is an error** unless the line names what removes it — a task ID (which carries both the replacement and its milestone, satisfying ADR-064's two-part test) or an ADR reference (which marks the line as stating policy, e.g. *"absent — not stubbed"*, rather than shipping a placeholder).
2. **An accepted doc with no implementing task is an error**, escalated from a warning. ADR-065's *"explicitly parked"* third state becomes real: `parked: <why>` in the frontmatter. A doc that is both parked and scheduled is also an error — the states are exclusive. The parked count appears on the dashboard only once something is parked.
3. **A milestone with tasks but no exit gate is an error**, escalated from a warning. `PRO-007` names *"M1 never ends"* as the top project risk; a milestone that cannot be cleared is that risk with a checkbox.
4. **`M1-T08`'s scope line no longer claims the determinism harness.** It read *"CI for index + determinism"*, but the harness is `M1-T07`'s deliverable. `M1-T08` built the CI it plugs into; claiming the harness itself would have marked as delivered a thing that does not exist.

**Rationale:** Every one of these was already decided — this ADR writes no new policy, it closes the gap between decisions and the tool that enforces them. Escalating warnings to errors is the substantive change, and it is the right one: `--check` passes on warnings, so a warning is a decision the project has agreed to ignore. Each check was verified by planting a violation, observing the failure, and reverting — a check that has never fired is not known to work.

That verification is permanent, not a one-off: **`tools/test_checks.py`** plants one violation per check and asserts the specific issue code appears, and CI runs it followed by `git diff --exit-code`. These checks guard *decisions* rather than code, so nothing else in the project would notice if one silently stopped matching — which is how ADR-064's check came to be unimplemented for two ADRs without anyone seeing it.

**Consequences:** `--check` is now strict about three things it previously tolerated. All 39 docs and every milestone pass today, so nothing is retroactively broken. The `parked:` key has no users yet; it exists so the escalated error has a legitimate escape that is *recorded* rather than silent. The remaining warnings are the `⟨tune⟩` counters on `TEC-001` and `TEC-002`, which are correct — those are performance budgets and export presets that cannot be tuned before there is a build to profile.

---

## ADR-068 — `M1-T06` networking spike: GO, and what it actually measured
**Date:** 2026-08-15 · **Status:** accepted · **Gate:** `M1-T06` go/no-go
**Context:** `TEC-004`'s risk register named `MultiplayerSynchronizer` performance at high object counts *"the assumption most likely to be wrong"*, and `PRO-001` made it a go/no-go before anything is built on top. Measured with `tools/run_net_spike.py`: one host plus three clients as separate processes on loopback, 150 spawned entities, position replicated at 20 Hz, 14–20 s windows with the first 3 s discarded. Godot 4.7-stable.

**The measurement:**

| Configuration | kbps/client | Verdict |
|---|---|---|
| 150 moving, `ALWAYS`, no compression | 528 | 8× over |
| 150 moving, `ON_CHANGE`, no compression | 711 | 11× over |
| 150 moving, `ON_CHANGE`, range coder | 321 | 5× over |
| 150 spawned / 20 moving, no compression | 94 | 1.5× over |
| **150 spawned / 20 moving, range coder** | **44** | **within budget** |

Delivery held at **18.1–18.2 Hz of the 20 Hz requested (91%)** in every configuration, including the ones 11× over budget. Host physics cost **0.2–0.9 ms** for 150 synchronised entities against a 16.6 ms frame. Spawning all 150 took **3–4 ms**.

**Decision: GO.** Godot's high-level multiplayer is validated for this project. The fallback — hand-rolled state replication over ENet — is not taken and no work proceeds on it (ADR-064: a gate decision, not a maintained alternative).

**Rationale, and the part that matters more than the verdict:** the risk as written was aimed at the wrong thing. **CPU was never close to a constraint** — 0.2 ms is a rounding error, and `MultiplayerSynchronizer` kept delivering at 91% of the requested rate even while consuming eleven times the bandwidth budget. The engine does not degrade gracefully into low update rates; it simply spends whatever bandwidth the design asks it to. **The binding constraint is bandwidth, and bandwidth is decided by the design, not the engine.** A spike that had measured only frame time would have returned a confident GO and taught us nothing.

**Consequences — three corrections to `TEC-004`:**
1. **`⟨tune⟩` 64 kbps and `TEC-001`'s 150 agents were never jointly satisfiable by naive replication** — that combination costs 528 kbps/client, 8× over. They are compatible only under the LOD split `TEC-001` already specifies (~20 of 150 fully simulated) *with* compression. **The measured ceiling is ~29 moving entities** at 20 Hz within 64 kbps; 20 moving leaves ~45% headroom. Relevance filtering is therefore **load-bearing, not an optimisation** — the wording in `TEC-004` implied the latter.
2. **ENet range coder compression is required.** It roughly halves cost (711→321, 94→44 kbps) for one line at transport setup. `TEC-004` did not mention compression at all.
3. **"≤64 kbps up per client" is clarified to mean host upstream divided by party size.** Clients send only input and are nowhere near any limit; the host's upstream is the constraint that decides whether four players work.

**Two engine behaviours worth recording, both of which cost real time here:**
- `ON_CHANGE` properties travel the **delta** channel, which has its own `delta_interval` defaulting to *every network frame*. Setting only `replication_interval` leaves deltas at the physics rate — a silent 4× bandwidth cost.
- For continuously-moving values, `ON_CHANGE` is **more** expensive than `ALWAYS` (711 vs 528), because delta encoding adds overhead and never elides anything. `ON_CHANGE` is correct for things that genuinely idle, and wrong for things that always move. Choose per property, not per project.

**Scope of this result.** Loopback, so no latency, jitter or packet loss; three clients; position only. It answers the object-count question `TEC-004` asked and nothing else. Real-network behaviour is `M4-T07` (Steam relay), and join-in-progress delta sync remains untested until M2.

**The NO-GO fallback, settled.** It was briefly unclear whether a failed spike meant *a different engine* or *hand-rolled replication*. **There is no engine-change fallback and there never was one** — it appears nowhere in 39 documents. The single documented fallback is `TEC-004`'s hand-rolled state replication over ENet, and it is **not taken and will not be built** (ADR-064: a gate decision, not a maintained alternative). Godot 4 is the engine. This is noted and closed; do not reopen it without an ADR arguing the engine itself is the problem.

---

## ADR-069 — Commit cadence: history tracks the roadmap, and agents do not ask
**Date:** 2026-08-15 · **Status:** accepted · **Amends `CLAUDE.md` §4**
**Context:** Directed. Two milestone tasks and four ADRs were completed before anything was committed, because the working agreement said what "done" means but never said *when work enters the repository*. Uncommitted work is invisible to CI, and CI is the only thing that runs the full check sweep on a clean checkout — so a green local tree proves less than it appears to.

**Decision:** **Agents commit and push without asking.** This is durable authorisation and is not re-requested per session.

**One commit per completed task or decision**, so `git log` and `PRO-001` tell the same story. A commit lands when a task changes state, when an ADR is written or its status changes, or when a measurement changes a decision — and it carries the work *and* the doc updates *and* both regenerated views together. Splitting a ticked checkbox from its regenerated dashboard is the stale-dashboard failure wearing a different hat.

**A failing check is a blocked commit, not a note in the commit message.**

**Rationale:** Batching a milestone into one commit destroys the thing that makes the roadmap notation worth having — the ability to see which change implemented which decision, and to revert one without the others. The standing authorisation exists because asking per commit converts a mechanical step into an interruption, and interruptions are what caused the batching in the first place.

**Consequences:** `main` receives work directly, which `TEC-002` already permits provided *main always launches* — the pre-commit sweep is what guarantees it, so the sweep is not optional. Commit subjects carry the task or ADR ID (`M1-T06: networking spike GO — bandwidth, not CPU`). **The first commit under this policy is necessarily an exception:** the `M1-T08` skeleton, the ADR-066/067 enforcement work and the `M1-T06` spike were done as one continuous session and are genuinely interdependent — the CI workflow references all of it and the dashboard regenerates once — so they land together rather than being retroactively split into commits that would not individually pass CI. The cadence applies from the next task onward.

---

## ADR-070 — `M1-T09` ink shader spike: GO
**Date:** 2026-08-15 · **Status:** accepted · **Gate:** `M1-T09` go/no-go
**Context:** ADR-062 required a weekend spike — grey boxes, **outlines and boil only**, no hatching and no two-world inversion — with a one-time gate at *"~70% convincing"*. `PRO-007` ranks the ink shader as the second most likely cause of this project failing, specifically by consuming months as a novel four-part effect. The narrow scope was the mitigation.

**Decision: GO.** The ink path is the visual direction. Flat quantised shading is **not built** — per ADR-064 this is a gate decision, not a maintained alternative, and no second renderer exists. Hatching and the Threshold/Deep inversion remain scheduled at `M4-T08` and are not brought forward.

**Measurements:**
- **Boil holds and jumps as specified.** Captured at 30 fps with boil at 10 Hz: frames inside a beat are pixel-identical (0 changed pixels), ~6,500 pixels change at each beat boundary. `ART-005` calls this "the cheapest, highest-impact line in this document"; it is now verified rather than asserted.
- **Pass cost ~0.15–0.23 ms** at 1152×648, ≈0.4–0.6 ms at 1080p — about 3% of a 60 fps frame. Bracketed, not exact: the baseline is vsync-clamped, so the true value sits inside that range.

**Two findings `ART-005` does not state, now folded into it:**
1. **The depth threshold must scale with N·V.** A fixed threshold renders every floor and ceiling as solid scribble, because depth changes enormously per pixel on any surface seen edge-on *even when it is perfectly flat*. This is not a tuning detail — without it the technique does not work at all.
2. **Wobble amplitude belongs near one pixel.** At 2.6 px a stroke wanders further than its own width and reads as a smudge rather than a drawn line.

**What this does not settle.** The spike used ordinary grey-box lighting. The grey-fill result is markedly weaker than the ink-on-paper result, because smooth gradient fills fight the printmaking read — which is what hatching exists to fix, and hatching was deliberately out of scope. **Q102 (coplanar edges) remains open:** the test geometry was staged but is not legible in the captures, so it needs a dedicated test rather than being inferred from these.

**Consequences:** `M1-T09` closes. The remaining M1 work is the game itself. **ADR-062's third action — *"a devlog starts when the shader works"* — has now been triggered and has no task anywhere in `PRO-001`.** `PRO-007` names the absence of any marketing plan as a real gap and made the devlog its mitigation; recorded here so the trigger is not lost, but **adding it to a milestone is a scope decision and is not taken by this ADR.**

---

## ADR-071 — The `untuned` check fires when a doc is *fully* built, not partly
**Date:** 2026-08-15 · **Status:** accepted
**Context:** After three M1 tasks closed, the dashboard carried four `untuned` warnings — `TEC-001`, `TEC-002`, `TEC-004`, `ART-005`. None was actionable, and that is the problem: a warning nobody can act on teaches the reader to skip the warnings block, which costs more than the check is worth. Investigating them found the check itself was wrong rather than the docs.

**The bug.** `check_quality` warned as soon as **any** implementing task finished. But docs are implemented by several tasks across several milestones:

| Doc | Implemented by | State |
|---|---|---|
| `ART-005` | `M1-T09` outlines and boil · `M4-T08` hatching, inversion | partly built |
| `TEC-004` | `M1-T05` · `M1-T06` · `M4-T07` Steam relay | partly built |
| `TEC-001` | `M1-T07` determinism · `M1-T08` | partly built |

`ART-005`'s numbers **cannot** be final after `M1-T09`, because `M1-T09` was explicitly scoped to outlines and boil (ADR-062). Asking for them was incoherent.

**Decision:**
1. **`untuned` fires only when every task implementing a doc is `[x]` or `[-]`**, and at least one is `[x]`. The message names the tasks that built it.
2. **`TEC-002`'s `⟨tune⟩` on "Build & release" is removed** — that section contains export targets and a build-stamping rule, and **not one number**. The marker was misapplied; accepting it as final is the correct half of the check's own advice.
3. **`TEC-001`'s autoload table no longer writes the literal `⟨tune⟩`** when describing the notation. Prose *about* the marker was being counted as an instance of it, inflating the corpus total by one.

**Rationale:** Three of the four warnings were the tool being wrong, and one was a doc being wrong. Neither was a number needing tuning — so suppressing the warnings would have hidden two real defects. The remaining five markers across `TEC-001`, `TEC-004` and `ART-005` are all genuine: performance targets needing a profiler, an RTT figure needing a real network, a join-in-progress sync window, wobble amplitude, and an outline distance. Every one is blocked on play, which is exactly what `⟨tune⟩` means.

**Consequences:** The dashboard reports zero warnings and therefore means something again. **One real gap surfaced and is deliberately not closed here:** nothing in `PRO-001` implements `TEC-002`'s build-and-release section — no task covers export presets or stamping the commit hash and save-format version into the main menu, even though "works in an exported build" sits in the Definition of Done. Scheduling that is a scope decision and is left to the owner.

---

## ADR-072 — `M1-T02` includes the awareness ladder, because the gate question needs it
**Date:** 2026-08-15 · **Status:** accepted
**Context:** `M1-T02` reads *"one weapon, one enemy, hit reactions, death"*. Built literally, that is an enemy which is always hostile. But DES-009's stated gate for this layer is **"does a tester voluntarily swing at something they could have walked past?"** — and an always-hostile enemy makes the answer unobtainable, because walking past is not an option. DES-013 opens on the same point from the other side: if encounters are unavoidable, Clamor stops being a decision and becomes a tax.

**Decision:** `M1-T02` builds **UNAWARE → SUSPICIOUS → ALERTED** as well. **SWARM is absent, not stubbed** (ADR-064): calling others is only meaningful once Clamor propagates between actors, and the Clamor field is M2. Senses are **sight only** for the same reason — DES-013 specifies hearing as O(1) Clamor-grid lookups, which needs that field.

SUSPICIOUS investigates the **last seen position, not the player's current one**, which `PRO-005` §5 makes a fairness requirement rather than a flourish.

**Also deliberately absent from this task**, each because one verb built completely beats four built partly: the heavy attack, block, shove and throw; weapon arcs colliding with world geometry; and every layer of DES-009's juice protocol — no hitstop, no impact audio, no camera kick, no particles. **Input buffering is present** and is not a violation: DES-009 §4 files it under Forgiveness, and is explicit that without it a committal system reads as unresponsive rather than weighty.

**Rationale:** the alternative was to build the literal task and discover at the gate that the gate could not be evaluated. Scope grew by one state machine; the thing it protects is the only question `M1` exists to answer.

**Consequences:** measured rather than asserted, via `--combat-probe`: swing wind-up 152 ms of an intended 160, active 111 of 100 (both quantised by the 60 Hz physics step), **enemy telegraph 518 ms against the 250 ms floor**, hits interrupt a wind-up, and an enemy starts UNAWARE and stays there until it sees you. Lethality currently sits at **3 swings to kill, 3 hits to die**, which matches DES-009's *"lean high lethality, telegraphed heavily"* — it does **not** close that open question, which only play can.

**The 250 ms telegraph floor is now enforced at load** by `TuningProfile.validate()`, not by convention. `CLAUDE.md` says CI enforces it and `TEC-006`'s full data validator is `M2-T08`; until that exists the rule would have been unenforced on the only telegraph value in the game. Verified by planting 0.12 s and observing the boot error.

---

## ADR-073 — `M1-T04` builds the Clamor *radius*, not the Clamor *field*
**Date:** 2026-08-16 · **Status:** accepted
**Context:** `M1-T04` is *"Weight & Clamor as visible debug numbers"*, but `M2-T02` is *"The Hunt: clamor field…"*. Both name Clamor, and building the wrong one here would either leave a number measuring nothing or do M2's work early.

**Decision:** `M1-T04` builds **DES-005 Layer 1** — clamor deposited by actions, decaying continuously, mapping to an **audible radius** that enemies hear. DES-005 Layer 1 names that mechanic directly: *"Clamor → wider aggro radius."* **TEC-001's decaying scalar grid is absent** (ADR-064), not approximated.

These are two consumers of one fiction and **both exist in the finished game**: the radius answers *"can that enemy hear me"*, the field answers *"where in the level was noise recently"*, and only the second needs a grid the Gullsjúkr can navigate by gradient. So this is not a cheaper stand-in that gets thrown away — `ClamorSensor`'s interface is unchanged when it becomes a grid lookup, which is also what DES-013's O(1)-per-agent requirement demands at 150 agents.

**Measured** (`--clamor-probe`), sustained level and the radius it buys:

| | peak | heard |
|---|---|---|
| crouch, empty | 0.34 | 0.5 m |
| crouch, full load | 0.87 | 1.4 m |
| walk, empty | 3.60 | 5.8 m |
| walk, full load | 4.71 | 7.5 m |
| sprint, empty | 13.21 | 21.1 m |
| swing, missed | 1.95 | 3.1 m |
| swing, connected | 6.50 | 10.4 m |

**A tuning finding that needs judgement, not a fix.** Weight multiplies each footfall by 2.4 at capacity, but sustained clamor rises only **31%** (3.60 → 4.71). Encumbrance also makes you *slower*, and because footfalls are emitted per metre walked rather than per second, a laden player takes the same number of steps over more time — giving decay longer to eat them. The two couplings partly cancel.

That may be correct: you are slower *and* louder, and the compounding shows up as time-in-the-open rather than as peak volume. But DES-005 calls Layer 1 *"the single most important feedback loop in the game"*, and a 31% change is close to imperceptible. **Flagged for play rather than silently retuned** — every number here is `⟨tune⟩`, and the choice between raising `clamor_footstep_at_capacity`, shortening `clamor_step_distance` under load, or accepting the damping is a feel call.

Crouch, by contrast, is unambiguous: **10.6× quieter than walking**, which makes it the real stealth verb DES-009 asks for rather than a speed penalty.

**Also in this task, and not a juice violation:** the weapon now has a blockout model that moves through wind-up, strike and recovery. Without it the phases are invisible and DES-009's attack anatomy cannot be judged at all — this is the *primary representation* of the mechanic, in the same way the enemy's telegraph tint is. Straight lerps, no easing and no anticipation overshoot, precisely so it does not flatter the timings being judged. The polish layer DES-009 defers — hitstop, impact audio, camera kick, the arm absorbing a blow — remains absent.

**Fixed here:** `Hitbox` toggled `monitoring` to open and close its damage window, which Godot forbids from inside an area signal (*"Function blocked during in/out signal"*) — and death is reached from exactly there. Monitoring now stays on for the node's life and `_armed` gates the window, which also fixes a second bug in the same code: an `Area3D` that has never monitored does not know what it overlaps, so the "already inside the arc" scan never worked. The corpse's physics changes are deferred. `--combat-probe` now kills an enemy as a regression test.

---

## ADR-074 — Sight and hearing are separate signals, and walls muffle
**Date:** 2026-08-16 · **Status:** accepted · **Extends ADR-073**
**Context:** Directed, after playing `M1-T04`. The awareness ladder reported a single state, so there was no way to tell a room that had *seen* you from one that had only *heard something* — and no way to test occlusion at all, because clamor ignored geometry.

**Decision:**
1. **The two senses are tracked and displayed separately.** DES-013's ladder is the *state*; sight and hearing are its two *inputs*. Collapsing them loses the distinction between "you are spotted" and "it is guessing at a position" — which is precisely the difference SUSPICIOUS exists to express, and the thing a player has to read in order to bluff. Both run every frame, including while attacking or staggered, so the readout always shows live contact; only the promotion to ALERTED is gated. Two lamps over each enemy carry it in-world: left sight, right hearing.
2. **Walls muffle rather than block.** Each occluder between source and listener adds a fixed amount of *equivalent distance* (`clamor_wall_penalty`, 7 m ⟨tune⟩), up to three. TEC-001's field gets this shape for free by diffusing through open space; this reproduces it — sound rounds a doorway cheaply and dies through a wall — and is replaced by the field at `M2-T02` rather than maintained beside it.
3. **The debug overlay is no longer a circle.** It is the audible *footprint*: a closed outline whose radius in each direction comes from `ClamorSource.reach()`, **the same function the enemy's ears call.** A circle would have been a lie the moment a wall existed, and an overlay that disagrees with its simulation is worse than none — the same failure as a stale dashboard, which the project already refuses.

**Measured**, two listeners past one wall, at a clamor level worth 9.9 m in open air:

| | distance | reach | heard |
|---|---|---|---|
| through the doorway | 7.0 m | 9.9 m | yes |
| through the wall | 9.9 m | 5.3 m | **no** |

**Consequences:** occlusion makes the aggro radius a *shape* rather than a number, which is what makes crouching past a doorway a real decision instead of an arithmetic one. It also means `M1-T03`'s room set is now the thing that gives this system something to say — an open gym cannot exercise it.

**Two bugs found while building it**, both worth recording because both were silent. `ClamorSource` became a `Node3D` so a listener need not reach into an emitter's parent, but the player scene still declared the node as `Node`, so the script did not attach and every clamor call hit a null — Godot reports that only at runtime. And the first occlusion measurement aimed its "clear line" straight through a 30° ramp, reading one wall of penalty as a broken doorway. **A measurement whose control case is not actually clear measures nothing.**

---

## ADR-075 — Full controller parity is a project rule, not a feature
**Date:** 2026-08-16 · **Status:** accepted · **Amends `DES-009`, `DES-018`, `DES-019`**
**Context:** Directed. `DES-018` already listed *"controller and keyboard parity"* and *"toggle-vs-hold for every hold action"* — but under **"Beyond the core loop"**, its own heading for things deferred past the vertical slice, and no `PRO-001` task implemented either. So the intent was recorded and nothing was going to build it, which is the precise failure ADR-065 exists to catch and did not, because that check works at document granularity and this was a line inside a scheduled doc.

Left to M4 it becomes a retrofit, because the cost is never the input map: it is that a HUD reading *"press E"* has to be rebuilt, and that any action which quietly assumed a pointer has to be redesigned.

**Decision: every action is reachable from a gamepad, and this is checkable.**
1. **Parity is enforced, not intended.** `tools/bind_gamepad.py --check` fails the build if any action lacks a gamepad binding. A generator rather than hand-editing because Godot writes keyboard-only actions as `Array[InputEventKey](…)` — a *typed* array that cannot hold a joypad event — so the wrapper has to be stripped every time the editor saves.
2. **Look is rate-based, not delta-based.** A mouse reports how far it moved; a stick reports how far it is *held*. Treating the second like the first is exactly what produces the floaty aim that gets controller support called "present but unusable". Full deflection turns at `stick_look_rate` rad/s, shaped by `stick_look_curve` so small deflections stay precise.
3. **Crouch has both a hold and a latch, on both devices** — `ctrl`/B to hold, `c`/R3 to toggle. Not a duplicate binding: they suit different hands, and holding a key through the long quiet approach `DES-005` Layer 1 rewards is a real accessibility cost (`DES-018`).
4. **Prompts must name both devices** from here on. The debug readout already does; `DES-019` now requires it, so no HUD element can be authored keyboard-only and need rebuilding later.

**Rationale:** The two tests in `CLAUDE.md` both pass — this lets a player do something *new* (play at all, with a controller or without fine pointer control) rather than making a number bigger. `PRO-005` treats accessibility as load-bearing rather than decorative, and arrow-key look, which falls out of the same action set, is the binding that makes looking around possible with no pointer at all.

**Consequences:** Seventeen actions bound. `stick_look_rate` and `stick_look_curve` join the `TuningProfile` as `⟨tune⟩` values — stick feel is a playtest question and these are first guesses. Rumble, glyph-swapping prompt icons and full rebinding UI are **absent, not stubbed**: rebinding is already scheduled as `M4-T06`, and prompt glyphs belong with the real HUD at `M4-T05`. **`M1-T05`'s two-player test should use one keyboard and one controller** — that is the cheapest possible parity check and it costs nothing extra.

---

## ADR-076 — The ink pass moves from the spike into the game
**Date:** 2026-08-16 · **Status:** accepted · **`M1-T09` follow-through**
**Context:** Reported from play: *"I'm not seeing our ink style shader working correctly in the game."* Correct — it was never in the game. ADR-070 passed the `M1-T09` gate, but the shader lived only inside `game/tests/ink_spike/`, and the movement gym carried a header comment saying it was unshaded on purpose. That was right at the time: `CLAUDE.md` requires blockout to feel good unjuiced, and `DES-009` puts control before polish in Swink's ordering.

**That bar has now been cleared** — encumbrance was signed off on 2026-08-15 and combat feel on 2026-08-16 — so the ordering permits the shader, and continuing to withhold it would be following the letter of a rule past its purpose.

**Decision:** the pass becomes `components/ink_pass.gd` with the shader at `art/shaders/ink_outline.gdshader`, carried by the player's camera. **Moved, not copied** — the spike scene now uses the same component, because a spike-local duplicate is the parallel path ADR-064 bans and the two would diverge the first time either was tuned, at which point the spike would stop measuring what ships.

**Consequences:** `i`/Y toggles the pass so the grey box can still be judged bare — one implementation switched off, not a second code path. Hatching, the Threshold/Deep inversion and the vertex-colour ink-ID channel remain **absent**; they are `M4-T08`. The gym's "unlit on purpose" comment is corrected rather than deleted, since the reasoning it records is still why the shader arrived after the controller and not before it.

---

## ADR-077 — A section that means "later" must say which later
**Date:** 2026-08-16 · **Status:** accepted · **Amends `PRO-001`, `DES-006`, `DES-013`, `DES-018`**
**Context:** Directed audit, following ADR-075. That ADR found controller parity listed in `DES-018` under **"Beyond the core loop"** with nothing scheduling it, and every existing check passed — ADR-065 works at *document* granularity, and `DES-018` is scheduled by two tasks. The question was whether the same blind spot hid other deferred intentions.

**The audit, and what it actually found.** Three passes over all 39 documents:

| Lens | Candidates | Verdict |
|---|---|---|
| Promise-verbs in prose ("we will", "eventually", "deferred") | 15 | Almost all prose or explicitly-reasoned deferrals |
| Bulleted sections naming no task or milestone | **72** | Unusable — most bulleted lists in a design doc *describe the design* |
| Section **headings** whose wording defers work | **3** | The real population |

The middle row is the important negative result. Section-body scanning cannot distinguish a backlog from a specification, because the bullets under both are bare noun phrases — *"UI scaling and font size"* has no verb to match on. **A check that flags 72 of anything is a check nobody reads**, and shipping it would have been worse than shipping nothing.

The heading lens found exactly three, and **two were already properly built**: `DES-006`'s *"Biomes (3 at 1.0)"* by `M4-T01`/`M5-T02`, and `DES-013`'s *"Roster sketch (~12 at 1.0)"* by `M4-T02`/`M5-T04`. Neither section said so, which is a readability defect rather than a scheduling one. **The blind spot is narrow, not systemic** — that is the headline finding.

**Decision:**
1. **An accepted doc's section whose heading defers work must name a milestone or task.** Enforced by `status.py --check`. Scoped to headings deliberately, per the table above.
2. **`M4-T11` — the accessibility suite — is split out of `M4-T06`.** `M4-T06` read *"full save/load, settings, controls rebinding"*, and **"settings" was carrying a dozen deliverables**: colour-blind support, UI scaling, a dyslexia-friendly font, high contrast, per-bus volume sliders, mono output, and independently adjustable shake / blur / head-bob / FOV. Several are **architectural constraints rather than options** — "no information in hue alone" is not a checkbox, it is a rule every HUD element obeys — and burying them inside one word is how they arrive as a retrofit.
3. **`DES-006` and `DES-013` now name their building tasks** inline.

**Rationale:** `PRO-005` treats accessibility as load-bearing rather than decorative, and the thing that makes that true in practice is a task with an ID. The general principle is the one ADR-064 already states about stubs, applied to documents: **listing is not planning.** A heading meaning "later" with no "later" attached is a backlog nobody owns, and it reads as commitment while functioning as none.

**Consequences:** Three sections edited, one task added. The check is verified by a trial in `tools/test_checks.py` that plants a deferring heading and asserts the failure. **It will fire on future docs written in the same shape, which is the point** — and when it does, the fix is usually one line naming the milestone, not new scope. Known limit, stated plainly: this catches deferral announced in a *heading*. Work deferred in a sentence in the middle of a paragraph is still invisible to it, and the 72-candidate result says no cheap check closes that gap.

---

## ADR-078 — The debug overlays are a component, not gym furniture
**Date:** 2026-08-16 · **Status:** accepted · **`M1-T04` follow-through**
**Context:** The clamor footprint and the vision cones were written inside `movement_gym.gd`, because the gym was the only level that existed. `M1-T03` then built a room set with corners, doorways and a room you cannot hear into — and it could not display either overlay. **The one space built to exercise walls was the one space unable to show what the walls were doing**, which is the opposite of the situation `TEC-001` demands when it says the Clamor system is *"untunable blind"*.

**Decision:** both move to `components/debug_overlays.gd`, added by any level in one line. It finds the player and the enemies by group, so it needs no wiring and puts no debug geometry inside either actor scene. **Moved, not copied** — a gym copy and a room-set copy would be the parallel path ADR-064 bans, and they would diverge the first time either was tuned.

**The visual language is recorded here because it is a rule, not a style:** *an **outline** is what you emit, a **fill** is what they perceive.* Your clamor footprint is a line on the floor; an enemy's cone is a filled wedge. Two overlapping fills read as two enemies looking at the same place; two overlapping outlines read as mush.

**Rationale:** This is also the groundwork for **Q105** — the proposal to promote the footprint into a real accessibility feature so deaf players can *see* where their sound went. That cannot be prototyped while the drawing code is welded to a dev level, and `DES-018`'s Ear reports loudness and bearing but never propagation.

**Consequences:** The gym keeps its probes and loses ~110 lines. The room set gains both overlays, and the footprint is visibly clipped by walls the moment the player stands in a room rather than a field. Still dev-only and still unstyled — Q105 is where it becomes something a player sees.

---

## ADR-079 — The avoidance test is premature at M1, and moves to M2
**Date:** 2026-08-16 · **Status:** accepted · **Amends `PRO-001` `M1-T02`**
**Context:** Playtest feedback: *"with combat so simple at this stage, and there being no real loot, it's hard to want to swing at something you can walk past — so that may be an irrelevant test parameter."* Correct, and **ADR-053 already said so**: combat is *"a temptation with a price,"* and *"a refusal is only meaningful if the thing refused was attractive."*

At M1 there is no Gilded enemy, no contract target, and nothing on the floor worth carrying. Walking past costs nothing, so declining a fight is not a decision and cannot be observed as one. `M1-T02`'s note asked *"does a tester swing at something they could have walked past?"* — **a question the milestone is constructed to make unanswerable.** That framing was added when the task was written up; it is not in the original task and not in `DES-009`.

**Decision:**
1. **`M1-T02`'s judgement is the one `DES-009` actually specifies for M1** — step 1 of its test protocol: *does swinging and connecting feel decent with zero feedback layers?* That is answerable today, and it is the question Swink's ordering says must be answered before anything is layered on top.
2. **The avoidance question moves to `M2-T02`**, where the Hunt, the Gullsjúkr and loot with weight and clamor all exist, and where declining a fight finally has something to decline.
3. **Clamor is signed off as functional and explicitly not as tuned.** Reported as *"neat and functional… may need tuning later once it's more filled out."* Its `⟨tune⟩` markers stand, and `M5-T06` balances against real telemetry.

**Rationale:** A gate that cannot discriminate is worse than no gate: it gets passed by default and the milestone claims evidence it never had — the failure `PRO-007` names as *"M1 never ends"* wearing the opposite mask. The general lesson is worth stating, since I generated the bad test myself while writing up a task: **a test invented at write-up time must be checked against the design docs, not just against intuition.** ADR-053 contained the answer and I did not consult it.

**Consequences:** `M1-T02` and `M1-T03` close on the criteria that are actually measurable now — attack anatomy and the awareness ladder measured, the loop and ADR-032's bypass asserted. Nothing about the avoidance design changes; only when it becomes testable.

---

## ADR-080 — The rig is built to the collider, and `M1-T10` understated its own spec
**Date:** 2026-08-16 · **Status:** accepted · **Amends `PRO-001` `M1-T10`, extends ADR-057**
**Context:** Opening `M1-T10` surfaced two problems, neither of them design questions — ADR-057 already locked the socket spec.

**First, the task line is wrong in the dangerous direction.** `M1-T10` reads *"all six attachment sockets."* ADR-057 specifies **seven sockets**, and only **four** of the six *slots* are socketed at all — Body and Arms are skinned. Someone building from the task line rather than from `DES-020` would author six, and the entire reason this task exists is that the seventh cannot be added afterwards without re-exporting every mesh on the rig. **The task line is what gets built from, so it has to be the accurate one.**

**Second, and not written down anywhere: the rig has to match dimensions that are already tuned.** `M1-T01` was signed off against a specific collider, and the encumbrance feel was approved against that. A rig authored at different proportions forces one of two bad outcomes — change the collider and invalidate a passed sign-off, or leave it and have the mesh float and clip. This constraint lived only in `player.tscn` and `default_tuning.tres`, where no one opening Blender would look.

**Decision:**
1. **`M1-T10`'s wording is corrected** to name the seven sockets and state that Body and Arms are skinned.
2. **The rig is authored to the collider, never the reverse.** Binding figures, from `default_tuning.tres` and `player.tscn`:

| | | Source |
|---|---|---|
| Standing height | **1.80 m** | `stand_height` |
| Crouched height | **1.15 m** | `crouch_height` |
| Body radius | **0.35 m** | `body_radius` |
| Eye / camera height | **1.62 m** | `Head` transform |

`sock_head` sits at the eye line, not the crown — a helm is placed relative to the face. Godot is Y-up, −Z forward, metres, and the rig is authored at **1.0 scale with no import-time rescale**, because a scaled rig makes every socket offset a lie.
3. **Hand-authored in Blender**, not a marketplace or Mixamo base. The sockets have to be exact and permanent, and an inherited rig means inheriting bone names, orientation and scale that we do not control — retargeting drift shows up months later as clipping, at which point the re-export this task exists to prevent is exactly what is required.

**Rationale:** Both halves are the same failure — a constraint that is real, load-bearing, and recorded somewhere nobody will read at the moment it matters. `ART-004` says adding a socket later means re-exporting every mesh; that warning is only useful if the socket list and the dimensions sit where the person building the rig is looking.

**Consequences:** The Blender authoring is hands-on work, not something the toolchain can produce. What the toolchain *can* do is refuse a rig that does not match this spec, and that check is worth building alongside the first imported rig rather than after — an unenforced dimension is the same class of thing ADR-067 was written about.

---

## ADR-081 — Four socket rules, and a justification that was wrong
**Date:** 2026-08-16 · **Status:** accepted · **Amends `DES-020`, corrects ADR-057's reasoning**
**Context:** Working through `M1-T10` before authoring anything. ADR-057 fixed *which* sockets exist; nothing had fixed how they behave.

**1. The stated reason for real bones is false, and the conclusion still holds.** ADR-057 and `ART-004` justify authoring sockets up front with *"adding one later means re-exporting every mesh."* **Godot's `BoneAttachment3D` tracks any named bone at an arbitrary offset, added engine-side, without touching a source file.** A socket genuinely can be added years later.

The real argument is that **armour is authored against the rig**: a modeller building a pack must see where `sock_back` lands while they work. As a bone they can; as an offset in a `.tscn` they are guessing, and every pack after the first inherits that guess. The failure is not a re-export, it is a gear library that sits subtly wrong with no traceable cause. **Recorded because a rule defended by a false reason gets discarded the first time somebody checks it** — and this one is load-bearing enough that losing it to a bad argument would be expensive.

**2. The camera is never parented to `sock_head`.** `DES-009` bans head bob at M1 and restricts shake to positional kick because rotational shake in first person causes motion sickness; `DES-018` requires shake, blur, head-bob and FOV to be independently adjustable. A camera on an animated head bone inherits **every rotation an animator authors, with no per-effect opt-out** — one parenting decision silently overriding an accessibility guarantee. `sock_head` is for helms.

**3. Socket orientation is one convention: −Z is the way the held object points, +Y is its up.** A weapon authored to +Y in a socket facing −Z is correct in Blender and ninety degrees wrong in game, and that is invisible until the whole weapon set exists.

**4. The off-hand grip offset is item data, not rig data.** `sock_hand_l` must carry a shield (forearm), a lantern (hanging grip), a map (open in the palm) and a compass. No single transform flatters all four, so the socket stays single and each item carries its offset in its `.tres` — a designer tunes grip per object without touching the skeleton every other slot depends on.

**Rationale:** All four are cheap now and a re-export later, which is exactly what `M1-T10` exists as a gate to prevent. Rule 2 is the one with real teeth: it is the natural thing to do, it looks correct, and it breaks a documented accessibility promise in a way nobody would trace back to the rig.

**Consequences:** `DES-020` gains the four rules. Nothing about the socket list changes. The rig is still unbuilt — this is the specification it has to satisfy, and writing it before the Blender work is the whole point of the ordering.

---

## ADR-082 — `M1-T05`: the peer owns its body, the host owns every consequence
**Date:** 2026-08-16 · **Status:** accepted · **Amends `TEC-004`** · **Task:** `M1-T05`
**Context:** `TEC-004` asks for two things that cannot both be true. It specifies *"client-side prediction for local movement only"* and, one line later, *"do **not** build rollback or lag compensation."* Prediction without reconciliation is not prediction — it is authority with a more reassuring name. Building `M1-T05` required picking one, and "host-authoritative" as a slogan reads as *the host simulates your body*, which needs exactly the machinery the document bans.

**Decision — the split is stated, not implied:**

> **The owning peer is authoritative over its own body's transform. The host is authoritative over every consequence.**

This is the reading `TEC-004`'s own exclusion list already implies: it names damage, loot acquisition, extraction and progression as host-owned, and conspicuously does not name movement. So a client simulates its own legs and nothing else, and no reconciliation path is needed because nothing corrects it.

**It is visible in the node tree rather than living in comments.** Each player carries two synchronisers with two different authorities — `MotionSync` (the peer: position, yaw, pitch, stance, grounded) and `StateSync` (the host: health, carried weight, clamor). A reader who wants to know who decides something looks at which one carries it.

**Damage has exactly one gate.** `Hitbox` refuses to resolve an overlap anywhere but the host. One line, in one place, rather than a guard at each call site — four guards are four chances to forget one.

### Three things measured on the way, all of which changed the work

**1. Solo is a host with zero peers, for free.** With no peer ever assigned, Godot 4.7 installs an `OfflineMultiplayerPeer`: `get_unique_id()` is 1, `is_server()` is true, and `MultiplayerSpawner.spawn()` works normally. So single-player runs the *same* path as a host with nobody connected and no offline branch exists to rot (ADR-064 satisfied structurally rather than by discipline). **The trap that comes with it:** `has_multiplayer_peer()` returns **true** with no peer at all, so it can never be used to ask "am I networked".

**2. `player.tscn` shared one `CapsuleShape3D` across every instance.** `_apply_height` mutates that shape every frame a player crouches, and a scene sub-resource is shared between instances by default — so **one player crouching resized the other player's collider and hurtbox**. Invisible for as long as there was only ever one body; arrived with the second. Fixed with `resource_local_to_scene`, and the co-op smoke now asserts two players in one process report different capsule heights.

**3. Every enemy perceived exactly one player.** `Enemy._look()` used `get_first_node_in_group("player")`, which with a party makes everyone else a ghost — invisible, unattackable, unable to fail a stealth approach. Now nearest-*visible*, so hiding still works when a teammate is standing in the open. `_on_hurt` had the same shape and sent a struck enemy after whoever was first in the group rather than after whoever hit it, which `PRO-005` §5 forbids: the player must be able to explain how they were found.

### Two checks that could not fail, and what they cost

The smoke test compares reports from **both** processes, because every claim in `TEC-004` is a claim that two peers agree and a probe that interrogates one of them passes with the cable pulled. Two of its assertions were written, passed, and were worthless until a planted violation proved they never fired:

- **"the enemy is host-simulated"** compared enemy positions. Deleting the host gate and letting the client simulate its own copies **still passed**, because the probe left the enemies standing still and a stationary enemy looks identical either way. Now the probe stages a chase and compares `velocity`, which is never replicated and never assigned on a client — an honest client reports exact zero.
- **"the host heard the client"** used the whole run's peak clamor. A *swing* makes noise on the host through a different path, so the check passed with the host deriving movement noise for its own body alone. Now sampled from the walk phase only.

**Recorded because this is the second time on this project that a green check turned out to be untestable** (ADR-067 was the first). The rule that caught both: plant the violation and watch it fail, or the check is decoration.

**Consequences:** `tools/run_coop.py --smoke` joins the pre-commit sweep via `tools/check_scripts.sh` — the only check that exercises a second process, which is the only way any of this can be checked at all. `TEC-004`'s risk register can close "co-op QA cost" as mitigated rather than intended. `CoopSession` is now the single place a peer is created or an actor is spawned, and levels ask it for actors rather than instantiating them; the network boundary `TEC-004` says every later system must be written against is therefore somewhere findable. **Latency, jitter and loss remain untested** — this is loopback, and `M4-T07` owns the real-network question.

`--input=keyboard|gamepad` strips the other device's bindings at launch, so ADR-075's parity check is enforceable rather than hopeful: two processes on one machine both enumerate the same pad, and "I checked the controller" with a hand resting on WASD checks nothing.

---

## ADR-083 — Q23 was closed, then quietly reopened by a stale line; and M2 starts with its schema
**Date:** 2026-08-16 · **Status:** accepted · **Amends `DES-019`, `PRO-001`** · **Reaffirms ADR-040**
**Context:** Orienting on M2 immediately after the M1 gate passed. `DES-019` says both of these, twelve lines apart, in one `accepted` document:

> line 140 — *"**DECIDED (ADR-040):** Grid-based, weighted, real-time. Closes Q23 — no longer a prototype fork."*
> line 152 — *"Q23 says prototype both models at M2 — that still stands, because this is a feel question and no document can settle it."*

`PRO-001` inherited the stale half: `M2-T01` read *"inventory (prototype both models, Q23)"*. So the roadmap instructed building **two** inventory models — the parallel path ADR-064 bans — applied to the thing `DES-019` itself prices at *"⟨a few weeks⟩ of UI work, the single largest UI item in the project."*

An audit of every `Q`-reference in `PRO-001` found this is the only one. The roadmap cites exactly one open question, and it has been closed since 2026-08-14.

**Decision 1: ADR-040 stands. One inventory — grid-based, weighted, real-time.** `DES-019` line 152 is corrected and `M2-T01`'s wording drops the fork.

**Rationale:** The ADR mechanism is the authority (`CLAUDE.md` §8), and ADR-040 is both later and explicit — line 152 predates it and was missed. Beyond precedence, the fork fails the standing test in `CLAUDE.md`: a second inventory model lets the player do nothing **new**. And it would spend most of M2 on inventory inside a milestone whose gate is *"a playtester voluntarily abandons loot to survive"* — a question one inventory answers perfectly well. **If the grid feels wrong, that is an M4 revision against playtest data, not a fork built at M2 on speculation.**

**Decision 2: `M2-T08` is built before `M2-T01`,** and moves to the head of the M2 list.

**Rationale:** `M2-T01` creates the first loot, and loot needs a resource shape. Building it first means inventing an ad-hoc shape and migrating it — the retrofit `TEC-003` and ADR-064 both exist to prevent. `M2-T08`'s own line already said *"built with the first ten resources, not the first thousand"*, which is an instruction about **ordering** that the list order silently contradicted. Task IDs are permanent; list order is presentation, and ADR-077 already reordered within a milestone.

**Consequences:** `DES-019` and `PRO-001` are corrected. Nothing about ADR-040's substance changes — this ADR exists because a decision that is recorded in two places and updated in one is worse than a decision recorded once.

**The generalisable failure, worth more than the fix.** ADR-065 checks that documents are *scheduled*; ADR-076's audit found intentions hiding inside scheduled documents. This is a third shape: **a closed question still cited as open, in a doc that also records it as closed.** The stale half was self-consistent enough to survive every existing check, and would have been read as an instruction by whoever started M2 — which was very nearly this session. Worth a check: no task line may cite a `Q` that `OPEN-QUESTIONS.md` no longer lists.

---

## ADR-084 — `M2-T08`: item text is keys, and the validator only checks what exists
**Date:** 2026-08-16 · **Status:** accepted · **Closes Q104** · **Amends `TEC-006`** · **Task:** `M2-T08`
**Context:** Building the item schema. Two things had to be settled before `ItemResource` could have fields.

**Decision 1 — Q104 closed: `display_name`/`description` become `name_key`/`description_key`.** `TEC-006` already leaned this way (*"Keys cost nothing now and are painful to retrofit"*) and was right. The English lives in `data/locale/en.csv`, loaded as a Godot translation, so `display()` returns *"Dvergar Hammer"* today — **the decision is implemented, not deferred.** Cost: one CSV and one project setting. It never gets cheaper than at ten items.

**Decision 2 — the validator implements the rules whose data exists, and no others.** `TEC-006` lists six. Three are built (ID uniqueness and format, required fields, the free-money rule, plus per-trait field rules). Three are **not**: `telegraph_ms >= 250`, dangling `requires` in skill nodes, and keystones with no `effect_tags`. Their resources do not exist — `EnemyResource` arrives at `M4-T02`, `SkillNodeResource` at `M3-T01` — and each rule arrives with its data.

**Rationale for 2, which is the part worth keeping.** `M1-T05` shipped two checks that passed with the code deliberately broken, because neither had data that could distinguish a pass from a failure. **A rule with nothing to check is not a safeguard, it is a green tick that means nothing** — and worse than an absent check, because it convinces the next person the ground is covered. The telegraph floor is meanwhile genuinely enforced where its data actually lives: `TuningProfile.validate()`, at boot, since `M1-T02`. Writing a second copy against an empty folder would be the duplicate ADR-064 bans *and* the untestable check ADR-083 was written about, in one line.

**Scope, stated plainly.** `M2-T08` delivers `ItemResource`, `ItemTrait`, `WieldableTrait`, ten authored items and `tests/data_probe.gd` in the pre-commit sweep. **Nothing reads an item yet** — wiring loot into the world is `M2-T01`, which is the next task and the reason this one went first.

**One trait, not seven.** `TEC-006` names seven; `WieldableTrait` is built because every field it holds is a number the melee system already runs on. The other six describe systems that do not exist (slots `M3-T07`, extraction `M2-T04`, curses `M5-T02`), and a trait whose fields nothing reads is a schema nobody can check. Absent, not stubbed.

**Decision 3 — Q103 closed: a carried item is an `ItemInstance`, not an `ItemResource`.** Godot shares one `Resource` between every holder of it, so two lanterns would share one fuel value and two blades one condition. So the definition and the carried thing are different objects:

| | |
|---|---|
| `ItemResource` | the shared, immutable definition — what a Hoard-Coin *is*. Never mutated at runtime |
| `ItemInstance` | one carried thing — a reference to its `ItemResource`, a per-instance id, its grid position, and any mutable state |

Inventories hold `ItemInstance`s. Saves store the instance id plus the item's **stable string id**, never a resource path (`TEC-003`).

**Built at `M2-T01`, decided here** — which is exactly what `TEC-006` asks: *"decide the runtime-instance model before the first stateful item."* Deciding is not building, and the first stateful item arrives with the inventory. Writing the class now, against ten deliberately stateless items and no inventory to hold them, would be the premature build Decision 2 spends its rationale rejecting.

*This was going to be left open. `status.py --check` refused the commit — M2 was underway with an M2 question unresolved — and it was right: the roadmap's own next task is the one that needs the answer.*

**Consequences:** `TEC-006`'s `ItemResource` sketch is corrected to keys. `OPEN-QUESTIONS.md` loses Q104. The data probe fails loudly if it finds **zero** items — without that line, a moved folder or a mistyped path produces a clean, meaningless pass, which is the exact failure this ADR spends its rationale on. Five planted violations were confirmed to fail it, two of which required fixing the *test* rather than the check.

---

## ADR-085 — Question numbers are permanent, and Q105 meant two things
**Date:** 2026-08-16 · **Status:** accepted · **Amends `OPEN-QUESTIONS.md`** · **Renumbers Q105 → Q109**
**Context:** ADR-083 added a check that a task may not cite a closed question. Tying up loose ends, its mirror was added too — *a question an ADR says it closed must not still be listed as open* — and it immediately reported two things, of which **one was a bug in the check and one was a bug in the docs.** Both are worth recording, because they are different failures that looked identical.

**The false positive.** `OPEN-QUESTIONS.md` contains the row *"First-person arms — universal or per-class? (Q96 answered; **proportions** are a feel question)"* — a **correct** citation of a closed question, flagged because the loader scraped every `Q\d+` in the file. Fixed by parsing **declarations** rather than mentions: a question is open if a table cell *begins* with its id, either owning the first cell (`| Q103 |`) or opening the question cell in bold (`| Accessibility | **Q109 — …`). Mentioning a closed question in prose is not reopening it.

**The real one: `Q105` identified two unrelated questions.** ADR-057 closed *"off-hand swapping is mid-run, slow and interruptible"* as Q105 on 2026-08-15. `OPEN-QUESTIONS.md` then filed the *"see your own sound"* deaf-accessibility question as Q105 as well. So *"is Q105 open?"* had two correct and opposite answers, which is the one thing an identifier may never do.

**Decision: question numbers are permanent identifiers and are never reused.** The accessibility question becomes **Q109** — the next free number above Q108, the highest any ADR has spent. The ADR keeps its number, because the decision log is history and history is not renumbered; the open list is the newer, colliding use and is the one that moves.

**Rationale:** This is the same rule `TEC-006` already applies to item IDs and `TEC-003` to save data — *stable string IDs, never reused* — and it had simply never been stated for questions. `PRO-001` and `PRO-002` both cite question numbers as though they were unique, and one of this session's ADRs was written referring to "Q105" meaning the accessibility one. That confusion is exactly the cost.

**Consequences:** `Q105` in this log continues to mean off-hand swapping. **The deaf-accessibility footprint question is `Q109` from here on** — the same question, parked, with `components/debug_overlays.gd` still its groundwork. `status.py --check` now cross-references the open list against every ADR's `Closes` line **in both directions**, and `test_checks.py` plants a violation for each. Two stale rows fell out of the same audit: Q36 (answered by ADR-068's spike) and Q104 (closed the same day by ADR-084).

**The pattern across ADR-083 and this one.** Three separate document-integrity failures in two days — a closed question cited as live, an answered question still listed, an id used twice — and **not one of them was caught by reading.** Each was caught by a check written immediately after the previous one, which is the argument for writing the check at the moment the failure is understood rather than filing it as a lesson.

---

## ADR-086 — Exported builds: standard Godot, tracked presets, and a check that opens the box
**Date:** 2026-08-16 · **Status:** accepted · **Amends `CLAUDE.md` §4, `.gitignore`, `project.godot`**
**Context:** Directed. Development is on a MacBook and the remote-multiplayer testers will be on Windows, so a Windows build has to be producible. Auditing that turned up something worse than the expected gap: **`CLAUDE.md`'s Definition of Done has always included "works in an exported build", and it had never once been checked — because it could not be.** The only engine on the machine was the .NET build, and its export template set contained a single file, `android_source.zip`. No desktop templates at all. Eleven completed tasks carried the claim.

**Decision 1 — exports use standard Godot 4.7, not the .NET build.** The project is GDScript-only by decision (`CLAUDE.md` §4: *"C# only if a profiler proves a hot path needs it. Do not mix languages speculatively"*), and **CI has been running standard Godot all along** while the development machine ran mono — a divergence nobody had noticed. Standard bundles no .NET runtime, produces smaller builds for testers, and removes a live hazard: the machine's `dotnet` is 10.0.400 while Godot 4.7 targets .NET 8. `tools/export_build.py` deliberately omits `Godot_mono.app` from its search path rather than falling back to it, because a silent fallback would produce a different artifact than CI does.

**Decision 2 — `game/export_presets.cfg` is tracked.** Ignoring it is the common default and was wrong here: it is the only place the export configuration lives, so ignoring it made a Definition-of-Done line unreproducible by anyone but the one machine that happened to hold the file. Nothing secret goes in it — signing identities and notarisation credentials arrive from the environment, and macOS export is unsigned on purpose because its job is to prove the pack runs, not to distribute.

**Decision 3 — exporting is not the check; opening the box is.** A build that boots proves the pack loads. It does not prove the pack contains the game, and **two things this project ships are generated rather than committed**: `en.en.translation` is gitignored and rebuilt by the importer, and every `.tres` is re-serialised on export. So `--export-probe` runs *inside* the exported binary and reports what it actually holds, which `tools/export_build.py` compares against the repo.

That distinction is not theoretical. Excluding `data/items/*` from the macOS pack was tried deliberately: the build **exported at full size, launched, and reported zero errors**, while shipping none of its ten items. Only the census caught it.

| Verified at `M2-T08` | |
|---|---|
| Windows export from macOS | 104 MB exe + pck, cross-exported without Wine |
| macOS export, arm64/universal | runs headless, reaches `CoopSession` |
| Ten items in the pack | `10 packed, 10 in repo` |
| Translation table | `item.wpn_seax.name` → `Seax` |

**Decision 4 — cadence: at every milestone gate, and on demand.** Not per commit — an export costs a 1.2 GB template download and catches nothing the pre-commit sweep does not, *except* packaging faults, which only change when packaging changes. `.github/workflows/build.yml` is `workflow_dispatch`, exports Windows on Linux, and then **runs it on a `windows-latest` runner** — the half `export_build.py` honestly cannot do from a Mac, and the half that matters most, since the Windows build is the one build nobody here can check by launching it.

**Consequences:** `project.godot` gains `textures/vram_compression/import_etc2_astc=true` — Godot refuses an arm64 or universal macOS export without it. It costs nothing (the project has no imported textures) and does **not** touch the renderer, so ADR-052's Forward+ lock is untouched. A second Godot now exists on the development machine; the tools' search order prefers `/Applications/Godot.app`, so the whole check sweep now runs on the same engine build as CI.

**The Windows CI job is unverified until its first dispatch**, and is stated as such rather than claimed to work: it cannot be run from here. Its YAML parses and its logic mirrors the local tool, but the first `workflow_dispatch` is its real test.

---

## ADR-087 — `M2-T01`: the bag is 6x5, the Prize is an item, and carried clamor is a floor
**Date:** 2026-08-16 · **Status:** accepted · **Amends `DES-005`, `DES-019`, `TEC-006`** · **Implements ADR-040, ADR-084**

**Context:** Building the inventory. ADR-040 settled the *model* — grid-based, weighted, real-time, one of them — and ADR-083 had to reaffirm it after a stale `PRO-001` line reopened it. Three things were still unsettled, and each of them changes weeks of work.

**Decision 1 — the grid is 6x5, and it lives in `TuningProfile` until the Pack slot exists.** `DES-020` gives inventory dimensions to the **Pack** — *"bigger pack, more grid, more weight, more Clamor"* — and slots arrive at `M3-T07`. So the number has one home now (`inventory_grid`) and one home later (the Pack's `WearableTrait`), never two at once. When `M3-T07` lands, the profile value becomes the Q106 *no pack* grid it already has to be. That is an ordering decision, not a fallback (ADR-064).

**Rationale for 6x5 specifically.** It is RE4's attaché case, which `DES-019` names as the gold standard, and — measured against the ten authored items rather than asserted — it is the size at which the two constraints genuinely disagree. A bag of gear fills 25 of 30 cells at 24.3 kg; a bag of glitter fills all 30 at 48.8 kg. Same squares, twice the price. At 4x5 both bags run out of space and the conflict collapses; at 8x6 neither does.

**Decision 2 — the room set's Prize becomes `glt_altar_plate`, and the level's loot code is deleted.** `M1-T03` built a gold block that added 16 kg of nothing; a playtester walked to it and asked what they were supposed to do, which is ADR-064's complaint about stubs arriving as feedback. It is now an item with a name, a footprint, a tribute value and a translation key — and the hand-rolled reach check, RPC pair and hardcoded weight **moved** to `Player` and `WorldItem` rather than being copied (the ADR-073 rule). There is one loot path in the project and `room_set.gd` has none of it. The floor gained seven more authored items, placed so that the safe west branch pays badly and the Guardian's room holds the three things worth the fight.

**Decision 3 — carried clamor is a floor `ClamorSource` decays *to*, not a constant it adds.** `DES-008` names clamor *"the audible cost of greed"* and `DES-005` makes dropping loot the primal counter-play, so what you carry has to be audible while you are standing still — otherwise "crouch in a corner and wait it out" costs a rich player nothing.

The constant-addition version was checked and **it deletes stealth**: a full glitter bag sums to 8.5, a permanent 13.6 m audible radius against a 16 m enemy vision range, which removes *"hide and let it pass"* from `DES-005`'s own list of things that must work. At `clamor_carried_fraction` ⟨tune⟩ 0.25 the same bag is heard from 3.4 m — sneakable, and never silent. **Dropping the loot drops the floor in the same frame**, which is what gives `DES-017`'s *"shedding carried value can shake it"* something to act on.

**Decision 4 — the debug weight keys are removed, not renamed.** `CarriedWeight`'s own note said its value was driven by hand *until `M2-T01`*. Loot is now the gameplay source, and a dev key writing the same number behind the inventory's back is the second weight path ADR-064 bans. `debug_weight_up`/`down` are gone from `project.godot`, `bind_gamepad.py` and the readout; their D-pad bindings went to `drop`.

**The correction this task produced, which is the part worth keeping.** `--bag-probe` first asserted that space *and* weight each refuse a pickup. It failed, and it was the **assertion** that was wrong: weight refuses nothing. ADR-050's cap is the *slot* cap, `DES-019` gives the grid the gating job, and `CarriedWeight` clamps its penalty at 1.0 precisely so a bad decision stays recoverable. So:

> **Space decides what you can carry. Weight decides what it costs you.**

That is a sharper reading of `DES-019`'s "two constraints that deliberately conflict" than *two gates*, and it sharpens the M2 gate question with it: you abandon loot not because nothing else fits, but because what you have is too expensive to walk home with. Recorded in `Inventory`'s header as well, because the next reader will otherwise notice the missing weight check and helpfully add it.

**Measured, at 6x5 and a 40 kg capacity:** the floor offers eight items; the bag takes seven and refuses the mail byrnie for space. 31.0 kg, 78% laden, 25/30 cells, walking 2.21 m/s against an unladen 3.40, audible 27.7 m moving and 4.3 m standing still. Dropping the altar-plate returns **+24% speed and 1.6 m of quiet**. Kilograms-per-cell spans 59x across the floor, from the gemstone to the hoard-coin.

**Consequences:** `ItemInstance` and `ItemCatalogue` are built, closing out ADR-084's Decision 3. Seven new checks, **each confirmed to fail by planting a violation**: four in `--bag-probe` (now in the pre-commit sweep), two in the data validator (item footprints against the grid; the catalogue's view of the corpus against the walk's), and two in the co-op smoke (the host granting a client's pickup, and the bag reaching the client that owns it). One of them was a green tick that could not fail — `--bag-probe` read the item count *after* the drop, so "the bag took everything" was unreachable; the oversized-grid plant is what exposed it.

**A dashboard correction fell out of ticking the task.** `M2-T01` was the only task citing `DES-008`, so ticking it made `status.py` report *"DES-008 is fully implemented"* — which is plainly false: its primary sink is tribute (`M3-T01`), and the stash (`M2-T06`) and the death wipe (`M2-T05`) are the other half of its economy. Those three tasks now cite `DES-008`, which is what they always implemented. The tool was not wrong; the roadmap was under-referenced, and it took a tick to make that visible.

`--bag-shot` renders the bag windowed and writes a PNG, because `--bag-probe` is headless and never executes a line of the drawing code. It found two defects on its first run that no headless check could: the footer prompt was silently clipped at the panel edge — losing the *drop* prompt, the verb this whole milestone is about — and the 0.04 kg gemstone rendered as `0.0 kg`, which reads as unset rather than as weightless.

---

## ADR-088 — The free-money rule could not fire, and "costs nothing" needs a capacity to mean anything
**Date:** 2026-08-16 · **Status:** accepted · **Amends `TEC-006`**

**Context:** `TEC-006` lists *"items with `tribute_value > 0` and zero `weight` and zero `clamor` — free money, always a bug"* as a built validator rule, implemented on `ItemResource.validate()` as:

```gdscript
if tribute_value > 0 and is_zero_approx(weight) and is_zero_approx(clamor):
```

`is_zero_approx` compares against `CMP_EPSILON`, which is **0.00001**. So any non-zero weight satisfies the first clause and the rule short-circuits before clamor is ever read. `glt_raw_gemstone` weighs 0.04 kg and is worth 55 — it escaped on that clause, and it is *the item the rule's own comment says it was written about.*

Setting the gem's clamor to `0.0` was tried directly: **55 tribute, 0.04 kg, silent, and the validator reported "every resource loads and validates".** Free money, passed by the rule that exists to forbid free money. Four checks in the previous two sessions were caught this way and this is the fifth — none of them by reading.

**Decision 1 — the rule moves to `tests/data_probe.gd`, and "no weight" is a fraction of `carry_capacity`** ⟨tune⟩ 0.005, which is 0.2 kg at the current 40 kg. Moved, not copied (ADR-073): a second copy would diverge the first time either was tuned.

**Rationale:** *"Costs nothing"* is not a property of an item. It is a relation between an item and how much a player can haul, and `carry_capacity` lives on `TuningProfile` where no `ItemResource` can see it. That is exactly the division `TEC-006` already draws — a resource answers for its own fields, and the probe owns the questions that need two resources to ask. The rule was on the wrong side of it, and `is_zero_approx` was the symptom of trying to ask a comparative question with no yardstick.

**Decision 2 — occupied cells do not count as a cost for this rule.** Space is a real constraint now (ADR-087), so counting it is tempting. But every item occupies at least one cell, so admitting cells would make the rule unfireable — the green tick that cannot fail, which is the failure this ADR is an instance of. Weight or clamor, or it is free money.

**Consequences:** `glt_raw_gemstone` keeps `clamor = 1.2` and the check is now what *enforces* that it cannot simply be removed. The gem's clamor currently encodes two unrelated things — noise, and the wealth `DES-017`'s Gullsjúkr senses — and `M2-T02` is where wealth gets its own sense. **When it does, this rule blocks the clamor coming off until the replacement cost exists**, which is the correct order and no longer depends on anyone remembering it.

---

## ADR-089 — `M2-T02`: the Hunt tracks noise, wants *disturbed* gold, and the Sealing moves to `M2-T04`
**Date:** 2026-08-16 · **Status:** accepted · **Amends `DES-017`, `DES-005`, `PRO-001`, `TEC-006`** · **Supersedes ADR-088's rule**

**Context:** `M2-T02` reads *"The Hunt: clamor field, the Gullsjúkr, escalation, the Sealing"*. Two of those four have dependencies that land later, and building them now would mean inventing the things they act on.

**Decision 1 — the Sealing moves to `M2-T04`.** `DES-005` Layer 3 seals **Shafts**, and Shafts are what `M2-T04` builds. There is nothing to seal, and a Sealing invented here would be an extraction system built inside a pressure task, ahead of the task that owns it. Cross-floor persistence (Q9) and *"a second one joins"* are likewise noted as `M4` work: there is one hand-built floor until `M4-T01`, so *"floor 1 absent, floor 2 arrives, floor 3 already there"* has nothing to vary across. The Gullsjúkr is on the one floor that exists — a scoping consequence, not a design change.

**Decision 2 — the throw is built.** `DES-009` listed it among the absent verbs, and `DES-017` calls baiting *"the best interaction in the design"*. Baiting by dropping at your feet does not draw the Hunter *away*, so it buys no time and the counter-play does not work; the doc says *down a side corridor* and means it. Cost was small because `WorldItem` and drop already existed — a throw is a drop with a launch velocity. The arc integrates identically on every peer from the spawn payload, so no position is replicated.

**Decision 3 — only *disturbed* gold baits it.** This is new, and it is the change the build forced.

`DES-017` describes baiting with thrown gold and says nothing about treasure already lying on the floor. Implemented literally, every authored item became an irresistible bait: **the Gullsjúkr spent the entire run walking between treasures and never hunted anybody.** `--hunt-probe` reported it as a wealth-sensing failure, which is what it looked like from outside — the Hunter never noticed a rich player because it was already stooped over a torc.

So a `WorldItem` is bait only if a player put it there. The fix is also the better fiction: it has been down there for years and never took the altar-plate off its plinth. What draws it is **someone handling wealth** — gold that is going somewhere, gold about to become a Tithe that is not its own. Baiting works because you *gave something up*, which is the sentence the whole game is written in.

The bait threshold also gained an absolute floor beside ADR-039's proportional one, because proportional to a player carrying nothing is zero. The floor is `hunter_wealth_floor` — the same number that decides whether *you* are worth crossing a room for. One threshold for "worth having", applied to a player and a purse alike: it does not want gold, it wants *enough* gold.

**Decision 4 — the free-money rule is deleted, and ADR-088's fix is superseded.** ADR-088 repaired a rule that could not fire and predicted this: *"when wealth-sensing lands, this rule blocks the clamor coming off until the replacement cost exists."* It did exactly that, and then the design closed the hole underneath it. The Gullsjúkr senses carried tribute through walls, so **every** item with `tribute_value > 0` now costs something by construction — it makes you legible to the thing hunting you, whatever it weighs. The rule can no longer fail, and a check whose premise the design has made unfalsifiable is the green tick ADR-084 spends its rationale on. Deleted rather than weakened into something that always passes.

`glt_raw_gemstone` lost its `clamor` in the same change. `DES-005` says *"gems are light and silent"*; it had only ever been loud to satisfy the rule that is now gone. Its cost is the one `DES-008` always described — it catches every light in the dark, including the ones looking for it.

**The bug the greed probe caught, which had nothing to do with greed.** Built in code rather than from a `.tscn`, the Gullsjúkr inherited `CharacterBody3D`'s default `collision_layer = 1` — which is **WORLD**. It was architecture: it blocked the player like a wall, it blocked `ClamorSource.reach()` so standing behind it muffled you, and it blocked `ClamorField._open_between`, making the Hunter a moving obstruction in the noise field it navigates by, able to wall off the trail it was following. `--bag-probe` found it by reporting that dropping 14 kg made the player *slower* — the Hunter had walked into them and was pushing. A check written for one thing failing on another is the argument for keeping it in the sweep.

**Measured:** a 21-by-25 field at 2 m per cell over the room set; a 20-unit deposit lands 21.5 in the cell it was made in. After making noise in the west corridor and moving silently to the east, the Hunter travels **+4.98 m toward the sound and +2.25 m toward the player** — it goes where the noise was. A silent player carrying 316 tribute is found; the same player carrying nothing is not. A thrown purse takes it from SIGHTED to COLLECTING.

**Consequences:** `--hunt-probe` joins the pre-commit sweep with four assertions, **each confirmed by planting a violation** — including handing the Hunter the player's transform, which is the shortcut anyone would reach for and which the probe exists to refuse. `TuningProfile` gains a Hunt group; `hunter_wealth_floor` is an `int` because `tribute_value` is one and the two are compared directly. The field's debug overlay is built per `TEC-001`'s *"build that overlay early; this system is untunable blind."*

**Absent, not stubbed:** killing it (`DES-017` makes that a high-Pact-Rank ability and Pact Rank is `M3-T04`), its audio (`M2-T03` owns the reserved instrument), and satisfying it outright.

---

## ADR-090 — `M2-T03`: one mix state, two renderers — and no middleware
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-018`, `DES-019`, `TEC-005`** · **Implements ADR-035, ADR-036** · **Registers `AudioDirector`**

**Context:** `DES-018` requires *every channel to have a twin* — everything the audio says, the screen says, and the reverse — and warns that it cannot be retrofitted, *"because by then every system will assume the mix is carrying the information and there will be nowhere for it to attach."* Two sessions of Hunt work had just produced exactly the state it warns about: clamor, the alert ladder, and a Gullsjúkr, all of them mute and invisible.

**Decision 1 — the twin is structural, not a discipline.** `AudioDirector` computes one `HuntMix` per frame; the score is driven from it and the **Ear** renders it. Not two readings of the world — **the same object**. Four channels: `clamor` (you), `alert` (the world), `hunter`, `bearing`.

**Rationale:** a convention that says "remember to add the visual" is a convention that lasts until the first hurried afternoon. With one source there is nothing to keep in step, and the only remaining failure — a channel nobody draws — is exactly what `--ear-probe` refuses, in both directions. Planting a fifth channel called `dread` fails the build.

That mechanism also settles Q80's shape without answering it: the Ear cannot reveal more than the mix does, because it has nothing else to read.

**Decision 2 — no middleware, and the reasoning is now stronger than ADR-050's.** ADR-050 said raw Godot first, FMOD when a musician is onboarded. Building it surfaced a better argument for the same conclusion: **`ART-002` chose vertical remixing**, which is layers playing in sync at independent volumes. That is the half Godot does natively. What middleware actually buys is *horizontal* re-sequencing — musically quantised jumps between sections — and `ART-002` explicitly rejects it (*"crossfades, not cuts"*, *"never stingers"*).

Two further points `TEC-005` undersells: **FMOD has no official Godot integration** (Wwise does), so adopting it means a community GDExtension with per-platform native binaries — landing directly on the export pipeline ADR-086 had just got working. And the composer-facing authoring workflow, which is FMOD's real value, benefits nobody until a composer exists; `ART-003` is still a brief.

> **If middleware is ever adopted, `TEC-005`'s own table points at Wwise for this project** — rooms-and-portals is native and matches the cell-based design (ADR-014), and it has official Godot support. Not decided here; noted so the next reader does not assume FMOD by default.

**Decision 3 — the layers are blockout (ADR-046).** Five synthesised loops: bed, drone, pulse, heartbeat, and the Hunter's reserved note. Obviously placeholder, and the point is that the **driver** is what ships — `M2-T09` authors the Threshold theme that replaces them. Grey-box audio for the same reason M1 had grey-box levels: the system has to be tunable before the content is worth making. **The reserved instrument is honoured even in blockout** — its tone is used for the Gullsjúkr and nothing else, because `DES-018` says it must never be a false alarm and a placeholder that broke that rule would teach the wrong reflex to anyone testing before `M2-T09`.

**On the standing test.** *"Playable to completion with audio muted"* is not automatable — nothing can play a run. What is automatable is the way it breaks, and that is what the probe asserts. Recorded plainly so nobody mistakes a green sweep for a played muted run; the muted playtest is still a human job.

**What the screenshots caught, and headless could not.** The Ear rendered off-screen entirely: a `Control` parented to a `CanvasLayer` gets no laid-out `size` from anchors, so `size.x` was 0 and top-right landed off the left edge. `--ear-probe` passed the whole time, because `_draw` never runs headless. `--ear-shot` now photographs the readout at three pressures, the same role `--bag-shot` plays for the inventory and the second time that pairing has earned itself.

**Measured:** clamor 0.07 → 0.95 moves the drone in at −20 dB and the pulse at −25; an alerted room brings the heartbeat to −17; the Gullsjúkr beside the player reports 0.22 presence at 90°. Quiet reads as a small warm dot, loud as a large pale desaturated disc — `DES-019`'s *"guttering and sick, never warm, never powerful"*, carried by size and fill so it survives monochrome.

**Consequences:** `AudioDirector` is registered, the second of `TEC-001`'s six autoloads, on ADR-066's terms — it now has work. Four buses (`score`/`ambience`/`diegetic`/`ui`) exist for `M4-T11`'s sliders; diegetic is never ducked (`ART-002`). Five probe assertions, **each confirmed by planting a violation**. Absent, not stubbed: rumble as a third twin (ADR-039, `M4-T11`), per-bus sliders, and the authored score.

---

## ADR-091 — `M2-T04`: the Shaft never locks, it gets worse
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-005` Layer 3, `TEC-006`** · **Implements ADR-015** · **Refines ADR-089**

**Context:** ADR-089 moved the Sealing from `M2-T02` to here, on the grounds that it seals the Shafts this task builds. That was right about *where* and incomplete about *whether one floor can express it*. Building it surfaced a contradiction inside `DES-005` itself:

> *"As the Hunt escalates, **the Shafts seal, floor by floor.**"*
> *"The player is never truly trapped — **the Shaft is always reachable**, just increasingly expensive."*

Both hold on a three-floor run: sealing floor 1 pushes you *down*, and down is still a way out. On the one hand-built floor that exists until `M4-T01`, a sealed Shaft is a locked door with nothing beneath it — the trapping ADR-015 forbids outright.

**Decision — the Sealing is built as the second sentence, not the first.**

> **The Shaft never locks. It gets worse.**

Escalation multiplies the channel time *and* the noise, so leaving late means standing exposed in a **known location**, for longer, screaming, with the thing that hunts wealth already coming. That is *"your cheap exit is gone"* delivered as a price rather than as a wall.

**Rationale:** it is what `DES-005`'s own guarantee describes, it needs no floor beneath it to be honest, and it keeps the felt content of the Sealing — staying costs you the cheap way out. **Floor-by-floor locking is not built and is not faked**; it needs floors and arrives with them at `M4-T01`, alongside the cross-floor Hunt (ADR-037). The two statements in `DES-005` are now consistent rather than in tension, which they quietly were.

**Measured:** 4.0 s and 5.0 clamor early; **12.8 s and 16.0 clamor** at full escalation. Still payable, three times worse.

**Decision 2 — `ExtractionTrait` is built**, the second of `TEC-006`'s seven traits, and for the same reason `WieldableTrait` was: its system now exists. It carries the **cap of one** (ADR-015, Q54), which `Inventory` enforces rather than trusting loot never to offer a second — `M4-T01`'s tables are generated, and generated things offer seconds. The cap is a UI decision as much as a balance one: `DES-019` requires the Waystone indicator to be *"binary and answerable in a glance"*, and a player holding two would make that mark a lie.

**Decision 3 — the Waystone is hand-placed, and its drop rate is explicitly not tuned here.** `DES-005` calls the rate *"the strongest single lever in the game"*, and a drop **rate** needs the loot tables `M4-T01` builds. One is placed in the guarded half, which lets this floor answer the question underneath the lever — *is a way out worth two squares and a walk past the Guardian?* — without pretending to answer the lever itself.

**On what extraction does today.** It reports what left with you and starts another descent. **The Settle beat is almost entirely absent** — `DES-019` wants punch, the hoard, the keep-or-give decision made physically, and deeds surfaced there and nowhere else; those need the Lair (`M2-T06`) and `DES-016`. Nothing fakes them: there is no hub, no stash screen, no summary panel. What you kept is printed and then gone, which is honest about there being nowhere yet to put it. What *is* built is the loop closing, and that is what makes `--bag-probe`'s agonising mean anything — you finally find out whether the loot you chose over the mail byrnie actually left with you.

**Consequences:** `--exit-probe` joins the sweep with five assertions, **each confirmed by planting a violation**. The one that earns its place is ADR-015's absolute: implementing the Sealing as a lock passes every reading of `DES-005`'s table and fails this check immediately, which is exactly what it is for. `use_waystone` is bound to the d-pad, deliberately away from the face buttons and triggers — the one input that ends a run should not sit under a thumb. The Waystone indicator lives on the debug readout until `M4-T05` builds the Burden layer.

---

## ADR-092 — `M2-T05`: the ember is an item, and that is what makes rescue cost something
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-012`, `TEC-006`** · **Implements ADR-024, ADR-050**

**Context:** ADR-004 wipes your LIFE on death, and in co-op you can die to a teammate's mistake. `DES-012` is blunt that unmitigated this is *"a friendship-ending mechanic"*, and answers it with three stages — downed, ember, carried out — whose whole point is that **the rescue has to be a genuine sacrifice**. A free revive is not a decision.

**Decision 1 — the ember is an `ItemResource`, carried in the bag.** `con_ember`: 12 kg, 5.5 clamor, 2×3 cells.

**Rationale:** `DES-012` asks for *"the ember's weight and noise mean rescue is a genuine sacrifice — the rescuer's own extraction gets materially worse."* Making it an item means that is not a special case to be tuned and maintained; it **falls out of systems already built**. It costs squares against `DES-019`'s grid, kilograms against `CarriedWeight`, and quiet against `ClamorSource`'s carried floor (ADR-087), all for the whole walk home. Measured: picking one up takes the carrier from 3.40 to 2.94 m/s and from silent to audible at 2.2 m standing still.

It also means the ember can be **put down**, which the design never forbids and which is the right kind of horrible: the sacrifice is real precisely because it can be abandoned partway home.

**Decision 2 — `ItemInstance` gains its first mutable field, `bound_to`.** ADR-084 built `ItemInstance` deliberately empty of state and said the fields would arrive with their systems. This is that: every ember loads from one `.tres`, so a shared `Resource` cannot possibly answer *whose* it is. Two embers on the floor are the same definition and two different people's lives. `condition`, `fuel` and `charges` remain absent on the same terms.

**Decision 3 — an ember is `disturbed`, so the Gullsjúkr will stop for it.** Not a special case: it is ADR-089's rule applied honestly, since a player put it there. The consequence is a genuinely nasty decision to be handed — **the thing that would buy you seconds is your friend.**

**On what is reported rather than enforced.** *"Your LIFE survives — tree, stash, rank intact"* names three things that do not exist until `M3`. Carrying an ember out therefore prints that the life was saved and emits `rescued`; `M3-T05`'s Legacy screen is what will read it. What is real today is that the ember drops, is carryable, costs its carrier, and reaches the exit — which is the whole mechanism under the M2 co-op gate.

**Absent, not stubbed:** the Vörðr's utility powers (scouting marks need the ping system, `M4-T05`), **Return** (walking back in with nothing needs a LIFE to end, `M3`), and Scars (`DES-003`, `M3`). A dead player's body stays where it fell rather than becoming a ghost with nothing to do.

**Two things planting violations found.** The first is ordinary and the second is not.

Adding a rescue phase to the co-op probe broke *"only the host simulates enemies"* — the new phase pushed the report six seconds past the chase, by which time the enemy had arrived and stopped, and a stopped enemy reads exactly like a client correctly refusing to simulate. Enemy speeds are now captured mid-phase, as the clamor peak already was for the same reason.

The second: freezing the bleed-out window made the probe **crash instead of failing**. With no ember, a later assertion dereferenced null, the function aborted, and it never reached its own reporting — printing nothing and hanging until `--quit-after` killed it. A check that cannot report is worse than one that cannot fail, because it looks like a timeout. The probe now bails out through the same reporting path an early return has to share.

**Consequences:** `--ember-probe` joins the sweep with six assertions and the co-op smoke gains three more — the client going down as seen by **both** peers, and a host's hand reaching across the wire to get them up. That last pair is the only claim in the design that genuinely cannot be tested in one process, because it is two people. `Health.revive()` is separate from `heal()`, which keeps refusing to work on the dead: `DES-009`'s non-regenerating health must not acquire a resurrection item by accident.

---

## ADR-093 — Party seats, so one ember is not another; and a check that cannot be unlucky
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-012`, `DES-018`** · **Follows ADR-092**

**Context:** Directed, and both halves were right. `M2-T05` shipped embers that were correct and **indistinguishable** — `DES-012` puts up to four on a floor and asks a player to answer *whose is that* while running — and the enemy-simulation check it disturbed had been repaired at the instant rather than at the cause.

**Decision 1 — `Player.party_slot`, assigned once by `CoopSession` and replicated in the spawn packet.**

Peer ids cannot serve as identity: Godot's are large arbitrary integers, they differ every session, and **the host's is always 1 regardless of who is hosting**. Nothing a human reads or that art varies on can be keyed to them. A seat is small, stable and countable — which is also what `DES-019`'s party frames need, so this is owed work brought forward rather than new scope.

**Decision 2 — embers differ in three channels at once: hue, value, and a countable number of motes.**

`DES-018` forbids hue as the only carrier (~8% of men), and four embers on a floor is precisely the case where that rule earns its keep. **All four stay in the fire family** — deep ember red, orange, amber, pale gold — because `DES-012` calls the ember *"a piece of her fire"* and `ART-005` reserves saturated colour for treasure; four arbitrary hues would break the fiction and the colour budget together. A value ramp through one fire separates *further* in greyscale than a rainbow does: 0.20 of luminance between neighbours.

**Decision 3 — the enemy-speed check measures a peak, not an instant.** Reading it at report time broke when `M2-T05` added a rescue phase six seconds later: the enemy had arrived and stopped, and a stopped enemy reads exactly like a client correctly refusing to simulate. Sampling mid-phase fixed that instant and left the fragility — any future phase, any slower enemy, any frame where it is turning rather than running. **A peak cannot be unlucky**, and it is the shape `_probe_clamor_peak` already used for the same reason.

**What the screenshot caught, and the numbers did not.** All four embers rendered identically, because `bind_to()` was called *after* `spawn()` — and an ember decides its colour and mote count in `_ready`. Every ember was seat 0. `--ember-probe` passed throughout, because it compares palette entries rather than pixels. The binding now rides the spawn payload, which is what `_build_world_item`'s own comment had said to do since `M2-T01`.

Two rendering faults came with it, and both were invisible headless. Emission at 1.4× clipped every seat to the same saturated orange and **destroyed the value ramp the palette is built on** — it is now scaled by the seat's own luminance, so the dim one glows dimly. And the motes shared the ember's emissive material and vanished into the bloom; they are dark, unlit beads riding above the core, because a *notch* counts and a spark does not.

**Consequences:** `--ember-shot` joins `--bag-shot` and `--ear-shot` — the third time a screenshot has caught what a headless check could not, and the pattern is now explicit: **anything whose correctness is a claim about seeing gets photographed.** `--ember-probe` gains a palette assertion across all four seats rather than the two a solo run can produce, with a 0.10 luminance floor rather than the 0.05 the first palette squeaked past at 0.07 — *a threshold set where a failure fits through is a threshold that has already failed.*

---

## ADR-094 — Every ember looks the same; the tag is the identity
**Date:** 2026-08-17 · **Status:** accepted · **Supersedes ADR-093 decision 2** · **Amends `DES-012`**

**Context:** Directed, reversing a decision made a few hours earlier. ADR-093 gave each party seat its own ember colour and a countable ring of motes, so a rescuer could answer *whose is that* across a room. It was legible, it satisfied `DES-018`, and it was the wrong answer.

**Decision — one ember appearance, for everyone. Whose it is lives in the tag.**

**Rationale, and it is a fiction argument that turns out to be a design argument.** `DES-012` calls the ember *"a piece of **her** fire, the piece she gave you"*. Four colours make four **team markers** — they read as player-identity UI wearing a diegetic costume, which is the thing `DES-019` rule 6 spends its whole existence avoiding. What is lying on the floor is not your friend's personal effect; it is the dragon's, briefly loose. All of them being the same fire *is the point*, and colouring them contradicted the sentence they were built from.

**Nothing legible is actually lost**, which is what makes the reversal cheap: **you know whose ember it is because you watched them fall there.** Position identifies it, diegetically, for free, with no UI and no draw on `ART-005`'s colour budget — the same reasoning that put the map in your hands rather than in a corner of the screen.

**What the tag does instead.** `bound_to` stops being a hint about appearance and becomes the only thing that decides anything: **an ember saves the person it names and nobody else.** Carrying someone else's is inert cargo — it will not save you, and it will not stand in for the ember you should have picked up. That is now asserted rather than assumed, and it is a far better check than the palette one it replaces, because it tests what the object *does* rather than how it looks. Planting an inventory that ignores the tag fails it.

**ADR-093's first decision stands.** `Player.party_slot` is still assigned and replicated — it names the bearer in the bag label, and `DES-019`'s party frames need it regardless. Only the colour ramp and the motes are gone.

**On the check that guarded the palette.** It was a good check for a thing that should not have existed, which is worth noticing on its own: a well-tested wrong answer is still a wrong answer, and a numeric assertion about a palette cannot tell you the palette should not be there. The screenshot could not either. **The direction had to come from a person**, and that is the honest limit of everything else in this project's tooling.

**Consequences:** `--ember-shot` keeps its place with a changed job — *"prove an ember reads as an ember"* rather than *"prove four are distinguishable"*. It had already earned itself twice on this object: it caught all four rendering as seat 0, and it caught emission flattening them into featureless discs.

---

## ADR-095 — `M2-T06`: the Lair is two places, and the Settle beat is a walk
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-014`, `PRO-001`, `project.godot`** · **Implements ADR-021**

**Context:** `M2-T04` closed the loop and deliberately left the Settle beat absent, because there was nowhere to put it. This builds the somewhere.

**Decision 1 — the split is enforced by absence, not by care.** ADR-021 makes the Chamber private and never networked. So `chamber.tscn` **contains no `CoopSession` at all** and instantiates a body directly. Nothing can replicate out of a scene with no session in it, however carelessly anyone wires it later — which is a stronger guarantee than a rule saying not to.

The reasoning runs fiction-first and that is worth preserving: tribute, her voice, and choosing what she keeps of you are *solitary by design*, and four people watching you decide is actively wrong. `TEC-004`'s property — progression never touches the wire — falls out of that rather than the fiction being bent to fit it.

**Decision 2 — the Settle beat is the drag-out-of-the-bag gesture you already have, and the *place* decides what it means.** At the hoard it is tribute; at the stash it is kept; anywhere else it lands on the floor, which is also an answer.

`DES-019` refuses a confirmation dialog for tribute and asks for the decision to be **physical**. This is what physical costs: a walk to one side of the room or the other, with the same verb that abandons loot on a dungeon floor. Nothing new had to be built for it, which is the tell that the verb was right.

**Decision 3 — `GameState` is registered**, the third of `TEC-001`'s six autoloads, on ADR-066's terms: it now has work. It holds `DES-003`'s three tiers and the difference between them is the whole emotional architecture — what you carried survives only if you extracted, **the stash dies with you** (`DES-008`'s great reset), and **the hoard never wipes**. `--lair-probe` asserts that pair in both directions, because it is one line away from being wrong either way and the economy's self-correction depends on it.

**Decision 4 — the main scene is the Threshold.** The game boots into its own loop rather than into a dev gym. `DES-014`'s first-sixty-seconds staging wants the first thing you see to be her and the Descent, and that is now literally what happens.

**The consequence that had to be caught by hand:** `check_scripts.sh` ran the lifecycle probe against *whatever `run/main_scene` happened to be*, so changing it would have silently stopped exercising the gym — a check that quietly stops running is the failure mode this project keeps writing ADRs about. It names the gym explicitly now.

**On the hoard, which is the cheapest good thing in the design.** `DES-014` prices it at *"a growing-pile-of-meshes system and nothing else"* and that is exactly what it cost: one mesh per ⟨tune⟩ 25 tribute, piled from a fixed seed so the mountain you walked past last run is the same mountain. It is visible progress with **zero balance impact** — the safest retention mechanism available — and it turns ADR-004's harshness into something you can walk on.

**Absent, not stubbed.** Boon (`M3-T01` builds the tree tribute buys), the Tithe and Pact Rank (`M3-T04`), the Legacy screen (`M3-T05`), and **saving any of it to disk** (`M3-T06`; `TEC-003` wants a versioned format with a migration path, not whatever is convenient today). In the Threshold: the contract board, the Forge, the Quartermaster, the staves, the campsites, camp momentum, and the NPC Bound. A fire and a doorway is not a placeholder for a bigger Threshold — `DES-010` wants the camp to *fill in* over the first hour, so it is the first hour.

---

## ADR-096 — `M2-T07`: two exponents, and the probe that had to stop inheriting a floor
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-012`, `PRO-001`, `TEC-004`**

**Context:** `DES-012` calls party scaling *"the most important balance relationship in co-op"* and asks for it to be instrumented **from the first playable build** — not balanced early, *measured* early, because the failure it prevents is silent: four-player quietly becomes the optimal way to farm and solo stops being played, and by the time anyone notices, the economy has been built on top of it.

**Decision 1 — the whole mechanism is two exponents, and the signs are the design.** Enemies scale near-linearly, loot **sub**-linearly, clamor **super**-linearly. What makes it work is that the interesting arithmetic is per-capita and nobody had to write it:

```
loot   per person = base · N^p / N = base · N^(p-1)   → falls, since p < 1
clamor per person =        N^q / N =        N^(q-1)   → rises, since q > 1
```

So a bigger party is **individually poorer and collectively louder** without a single rule saying "four players get less". Nobody is punished; the floor is being divided, and being divided by more people is worse for each of them. Measured at ⟨tune⟩ `0.6` / `1.35`:

| Party | Loot | Per head | Enemies | Clamor | Per head |
|---|---|---|---|---|---|
| 1 | 4 | 4.00 | 3 | ×1.00 | 1.00 |
| 2 | 6 | 3.00 | 6 | ×2.55 | 1.27 |
| 4 | 9 | 2.25 | 11 | ×6.50 | 1.62 |

Extraction points stay **flat**, deliberately: everyone converges on the same doors, which is where a scattered party becomes a crowd at the exit.

**Decision 2 — clamor scales at the one place noise enters the world.** `ClamorSource.add()` and nowhere else. Every consumer built since `M2-T02` — the field, the Gullsjúkr's three senses, the Ear, the mix — is downstream of that single multiply, so a four-stack meets the Hunt far sooner and not one line of the Hunt knows why. That is `TEC-001`'s "the Hunt tracks noise, never transforms" paying for itself a second time.

**Decision 3 — party size is counted from the group, not the peer list.** A body that has spawned is a body making noise and pulling loot, whether or not its owner's connection has finished settling.

**Decision 4 (the one that cost the time) — `--coop-probe` builds its own floor instead of inheriting one.** Party scaling broke the co-op smoke in five different places at once, and *none* of the failures were replication faults:

- extra enemies spawned into each other and shoved, so the two peers disagreed by 0.83 m;
- 2.55× clamor pulled every enemy off its post during the *walk* phase, so the strike phase swung at empty air — and the two checks that "passed" by hitting a different body than they meant to are the dangerous half of that;
- the floor got dangerous enough that the **host** was beaten down before the rescue phase, and a rescuer that is itself incapacitated cannot revive anybody. Three revive assertions failed for a reason with nothing to do with the wire.

The fix is not more tolerance. The probe now **empties the floor and spawns exactly the enemy each phase needs, immediately before it needs it** — a body half a second old cannot have wandered — and clears it again for the rescue. That holds at any party size and any clamor multiplier, which is the point: party scaling has `--scaling-probe` and does not need re-measuring through a probe about authority.

**The same bug, a third time.** `enemy_health`, `enemy_positions` and `enemies_seen` were read at *report* time rather than when the claim was made — the identical mistake ADR-093 fixed for enemy speeds, still sitting in three fields nobody had needed to move yet. It only surfaced because clearing the floor made "read it later" produce an empty dictionary instead of a plausible-looking one. **A measurement taken at a different moment than the claim is not a measurement of the claim**, and it fails silently until something makes the gap visible.

**Every number here is ⟨tune⟩ and the shape is what `M2-T07` owes.** `--scaling-probe` asserts the *signs*: per-capita loot must fall, per-capita clamor must rise, enemies must grow. Planting the linear values (`1.0`, `1.0`, `0.0`) makes each of the three fire. A future balance pass moves the exponents; it cannot flip them without CI saying so.

**Absent, not stubbed.** Elite frequency and contract objective count both scale in `DES-012`'s table and neither exists yet — `M3` builds ranks and `DES-007` builds contracts. Per-capita **extracted** value, as opposed to per-capita spawned value, needs the metrics sink `DES-010` describes and `M4` builds; what exists now is the generator, measured at the point it generates.

---

## ADR-097 — Party scaling, made to actually happen: every size, the behaviour/baggage line, and a floor that grows
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-012`, `TEC-004`, ADR-096**

**Context:** ADR-096 landed party scaling and `--scaling-probe` proved the arithmetic. A cohesion pass over the finished task found three things wrong with it, one of them severe. All three are the same species of fault: **a correct calculation that nothing made the game perform.**

### 1. The scaling was dead code in every real session

`CoopSession._start_host()` spawns the host's own body and nothing else — every other body arrives later, on `peer_connected`. But `_spawn_actors()` built the floor in the **same frame** it created the session. So `PartyScaling.size_of()` counted **one, always**, and enemy and loot scaling never fired outside the probe that measured them in isolation.

`--scaling-probe` could not have caught this. It measures a pure function and the pure function was right. What was missing was any check that the game **calls** it with a number above one, and that needs a second process.

**Decision — the floor is topped up as the party arrives, and never shrinks.** There is no "the party is complete" moment to wait for, and manufacturing one out of a timer is the fragile kind of fix this project keeps refusing. Instead each arrival brings enemy and loot counts up to what the current party warrants, adding only the difference. Both curves are monotonic, so a floor grown one player at a time is identical to one generated for the final party — which is why an incremental fix is a real fix here and not an approximation of one.

It **does not shrink** when somebody leaves. Despawning an enemy a player is fighting, or loot they were walking towards, is a bug they can *see*; a floor still populated for four after one quits is only a harder run. Between a visible wrong and an invisible imbalance, take the imbalance.

The ring placement had to change with it: the spread angle now depends on the body's index alone and never on the total, or every enemy already standing on the floor would shuffle each time somebody joined.

`run_coop.py` gained the row that catches this — the host's floor sampled while a second player is standing on it, compared against what a solo floor would hold. Commenting out one `connect` reproduces the original bug exactly and the row reads `2 players: 3 enemies (solo 3), 4 loot (solo 4)  FAIL`.

### 2. Three players were asserted by nothing

`DES-012` writes the relationship as 1/2/4 because those are the numbers people quote, and the probe sampled exactly those. The exponent form is continuous, so three was always correct — but nothing *checked* it, and "correct by construction" is the phrase that precedes most of this log's other entries.

**Decision — the probe walks every size from 1 to `Player.MAX_PARTY`**, derived from the constant rather than written out, so raising the cap extends the check instead of quietly leaving the new sizes untested. Three players lands where it should: 2.67 loot and 1.47 clamor per head, between two and four on all three curves.

### 3. The multiplier is on what people *do*, not on what they *hold*

`ClamorSource` has two ways to be loud and only one of them scaled. Transient deposits — footsteps, swings, rummaging, a Waystone channel — pass through `add()` and are multiplied. `carried_floor` is assigned straight from the bag and is not.

That was where the multiplication happened to land, not a decision. It is one now, and it is the right line:

* **What you do** gets sloppier with company. Four people cannot move through a room with the coordination of one, and that is what the super-linear exponent is charging for.
* **What you hold** does not. Ten kilos of coin clinks the same whoever you came with; nothing about the party changes the object in the bag.

The practical half is what settles it. `carried_floor` is a **floor** — a minimum audible radius that never decays away. Scaling it would put every party above the hearing threshold permanently and delete *"hide and let it pass"*, which `DES-005` lists among the things that must work. Per-capita clamor still rises, which is the property `DES-012` actually asks for. `--scaling-probe` now holds both halves: the same coin reads 0.75 at every party size while the same action rises 1.00 → 6.50, and planting either failure fires the matching row.

**The lesson, which is the third time this log has written a version of it.** ADR-093 moved a measurement to the moment its claim was made. ADR-096 found the same fault in three more fields. This one is its bigger sibling: **a probe that measures a function in isolation proves the function, and nothing else.** Somewhere there also has to be a check that the game reaches it — and for scaling, density, and anything else derived from how many people are playing, that check cannot live in a single process.

---

## ADR-098 — Nothing orphaned: 29 dead names, one write-only stash, and physics layers that could not be wrong
**Date:** 2026-08-17 · **Status:** accepted · **Amends `TEC-001`, `TEC-002`, `PRO-001`** · **Extends ADR-064**

**Context:** ADR-064 bans stubs because a thing that is present and does nothing lies to whoever finds it. ADR-097 found the harder version — code that is correct, tested, and never executed. This is the sweep for the rest of it, and the tool that keeps it swept.

**Decision — `tools/check_dead.py`, in the sweep and in CI.** Four kinds, in rough order of how quietly they fail: a function nothing calls, a signal nobody connects or nobody emits, a `TuningProfile` field nothing reads, a const nothing reads. It found **29** on its first run across 45 scripts.

It is a *name* checker and says so in its own output. It cannot tell that a function is called only from a branch that never runs — the exact shape of ADR-097 — and a tool that implied otherwise would be worse than no tool. Reachability stays the job of a probe run in the situation the code claims to work in. This proves only that nothing is orphaned, which is the half that can be proved cheaply and had never been proved at all.

### What it found

**Thirteen functions and ten signals, deleted.** Almost all were accessors written for a consumer that never arrived — `bag_openness()`, `spending_waystone()`, `shaft.progress()`, `hitbox.is_armed()`, `ear.rendered_channels()` (the probe reads the const directly), and so on. Two deserve naming:

* `Health.heal()`. `DES-009` bans regeneration within a run. A heal method sitting on the component is an invitation to break that quietly, and its absence is now the enforcement.
* `WorldItem.bind_to()`, orphaned by ADR-093 when ember binding moved into the spawn payload — the old path left standing beside the new one, which is the parallel fallback ADR-064 bans, arrived at by subtraction rather than by design.

`Stamina.emptied`/`replenished` took `_was_empty` and `_check_edges()` with them: the bookkeeping existed only to fire signals nobody heard. **"Signals up, calls down" is an architecture rule, not a licence to emit speculatively.**

**The stash was write-only, and this is the serious one.** `GameState.withdraw()` existed and nothing called it. `threshold.gd` has documented the Descent since `M2-T06` as *"whatever is in the stash is what you take, because `DES-014` puts loadout choices in the Chamber and this is the doorway rather than a menu"* — and nothing ever loaded it. You could keep things, watch them survive a run and die with you, and never once take one back down. `M2-T06` is called **"stash and re-descend"** and only the first half was built; I ticked it.

The floor now loads the local body's stash at generation. Local and host-side are the same thing here — `GameState` is never networked (`TEC-004`, ADR-021), so each process loads its own. **What does not fit stays in the stash**: `Inventory.add()` refuses when the grid is full, and the honest answer to a stash bigger than a bag is that you carry what fits and the rest waits — not that the bag silently grows, and not that the overflow is destroyed. `--exit-probe` asserts the hop, and asserts the item *moved* rather than being copied, because a stash that keeps its copy duplicates your loadout every descent.

**Three physics layers nothing read.** `CollisionLayers` opens by saying a mismatched mask is invisible — *"nothing errors, the swing simply passes through"* — and then the scenes set raw integers that nothing compared against it. `PLAYER_BODY`, `PLAYER_HURTBOX` and `ENEMY_HURTBOX` were read by no code at all, which left the file documenting the layout with no way to be wrong **and** no way to be right.

`check_project.py` now asserts every scene's layer and mask against the named constant. A deliberate duplicate, in the way a checksum is one: changing either side alone fires. Flipping the player's hitbox mask from `ENEMY_HURTBOX` to `PLAYER_HURTBOX` — a swing that hits your friends and not the enemies, and which nothing else in the sweep would notice — reports `layer-drift` and blocks the commit.

**The tooling counts as a reader.** A constant read only by the check that enforces it is doing its job, so `check_dead.py` scans `tools/*.py` alongside the game.

### The pattern worth keeping

Every one of these was invisible to a checker that only asks *"does this work?"* — because each of them worked. The question that found them is **"does anything use this?"**, and the two are not the same question. The stash proves it: `keep()` worked, `stash_changed` fired, the `--lair-probe` asserted the stash survives a run and dies with you, and all of it was true about a container with no way out.

## ADR-099 — `M2-T09`: three places, three pieces, and one note that is only ever hers
**Date:** 2026-08-17 · **Status:** accepted · **Amends `ART-002`, `TEC-005`, `PRO-001`** · **Implements ADR-050**

**Context:** `M2-T03` built the adaptive driver and ADR-090 settled that raw Godot is the right tool for it. What `M2-T09` owes is `ART-003`'s *"most important piece of music in the game"* — and, underneath it, the thing that was never actually true: that a **place** could have its own.

**Decision 1 — one flat layer table becomes three pieces, and a level says where it is.** Before this, `AudioDirector` had a single `LAYERS` dict driven by `HuntMix`. Every scene inherited it. So the Threshold and her Chamber — the safest and the strangest rooms in the game — were both scored by music written to say *how much trouble you are in*. Nobody had noticed, because a synthesised drone sounds plausible anywhere.

`AudioDirector.enter(place)`, called by the level in `_ready`, and the director starts with **no piece at all**. A director that guessed would guess the Deep, and the first thing a new player hears would be the Hunt playing over a campfire.

Her Chamber got its piece in the same change rather than later. Not scope creep — *adding* place-switching is what made "the Chamber plays the Deep's music" a decision rather than an oversight, and leaving it would have been choosing the wrong one.

**Decision 2 — the reserved instrument is structural, and CI holds it.** `ART-003` states it as an absolute: *"One instrument is reserved for the Hunter and appears nowhere else in the game. Ever. Not in the Threshold, not as texture, not 'just once' somewhere atmospheric… When the player hears it, it is always true."*

That rule is worth more than most systems in the design and it has no defence except memory. It will be broken by whoever needs a nice sound late one night, months after anyone last read `ART-003`, and the damage is not one bad cue — it is that **every previous time the player heard it retroactively becomes a coin-flip.** A warning that is sometimes false is worse than no warning, because players act on it.

So every layer declares a `voice`, and `--threshold-probe` fails if `bowed` appears anywhere but `deep/hunter`. Planting a second user fires it by name.

**Decision 3 — the Threshold is warm on arrival, and fills out as the camp does.** The hearth and the drone are unconditional: `ART-002` calls this *the only safe sound in the game*, and safety you have to wait two seconds for each time you walk through the door is a worse lie than silence. What grows is the **company** — a second instrument, arriving as the place becomes somewhere people live, which is ADR-050's *"a fuller camp gets a fuller arrangement"* and the entire reason this is a driver rather than a looping file.

Descents are the only camp state that exists yet — the contract board, the Forge and the Quartermaster are absent rather than stubbed — so descents are what it reads. Everything `M3` and `M4` add to the camp adds to the same number, and nothing here changes for it.

**Decision 4 — silence is asserted, not merely intended.** `ART-002` is emphatic that the most common mistake in the genre is scoring everything, and that Floor 1 at low clamor should be near-silent so the first drone is an *event*. That is exactly the kind of rule that decays without ever failing anything. `--ear-probe` now checks both directions: the score answers a loud player **and** says nothing to a quiet one.

**And the check corrected me on its first run.** The first draft asserted the whole score falls silent, and it failed immediately on the Hunter's note. It was right to. The heartbeat is the room having heard something; the Hunter's note is the Hunter being on this floor. Neither becomes untrue because you have since stopped moving, and a score that went quiet with a Gullsjúkr thirty metres away would be lying about the most important fact available. **The rule is that your silence gets quiet, not that the world does** — and only the layers reading your own clamor are held to it.

**And a third thing the tooling caught on the way out.** Ticking this task made `status.py` report `TEC-005` as *fully implemented* — because `M2-T03` and `M2-T09` were its only citers and both were now done. But `TEC-005`'s occlusion and reverb-zone sections are neither built nor planned, and its one remaining ⟨tune⟩ marker belongs to a filter cutoff no code sets. The same fault this project has now hit three times: **a document reads as finished when the tasks that happen to cite it are finished, whatever else it still says.** Split out as `M4-T12` rather than left for whoever eventually wonders why the Deep does not sound like stone.

**And the export gate caught the worst one.** `M2` is task-complete, so ADR-086's rule applies: export, and open the box. It failed — *"the build ran its probe: no probe output"*.

ADR-086 put the packed-content census in the movement gym because the gym was the main scene. Nine commits later ADR-095 made the Threshold the main scene, and the census became **unreachable**. Every export since has verified nothing.

The bitter part is that ADR-095's own text says: *"`check_scripts.sh` ran the lifecycle probe against whatever `run/main_scene` happened to be, so changing it would have silently stopped exercising the gym — a check that quietly stops running is the failure mode this project keeps writing ADRs about."* It fixed that instance and missed the identical one in `export_build.py`, in the same change that caused it.

**So the census moved into an autoload.** Naming the gym explicitly would have fixed this instance and left the shape intact; `Config` runs whatever boots, so there is no main scene anyone can choose that strands it again. It is not Config's job in any other sense — a census of the pack has no natural level, which is exactly why it kept ending up in one.

Then it was planted: restricting `ItemCatalogue` to `.tres` only — ADR-086's original bug — reports `0 packed, 12 in repo` on a **162.5 MB build that boots cleanly**. Which is the whole reason the rule reads *exporting is not the check*.

**On what is blockout and what is not.** Every note here is synthesised and `ART-002` says plainly to consider commissioning the score. What `M2-T09` owns is the **architecture**, and that is what a composer is handed: the stem layout, one key (D natural minor), one phrase length, every layer valid against every other, and the reserved voice already fenced off by a test. `ART-003` warns that a normally-composed soundtrack cannot be retrofitted into this system — the point of building it now, at `M2` rather than `M4`, is that nothing has to be.

## ADR-100 — A front door, a way out, and the two systems that were built but never shown
**Date:** 2026-08-17 · **Status:** accepted · **Amends `DES-018`, `TEC-004`, `PRO-001`** · **Precedes the `M2` gates**

**Context:** `M2` is task-complete and both its gates are playtest gates. Neither can be run: there was no main menu, no way to leave a level except killing the process, no way to change a volume except editing a file, no way for two people on different machines to meet, and no sound for anything the world does. This is the pass that makes the two gates *runnable*.

### The front door

`run/main_scene` is now `ui/main_menu.tscn`. **PLAY, HOST, JOIN, SETTINGS, QUIT**, and Escape opens a pause menu in every level with SETTINGS and a way home.

Solo is not a special case: PLAY sets `NetPlan.Role.SOLO` and loads the same scene the host does, because `TEC-004` measured that a host with no peers *is* single-player (ADR-064 — no second path to drift).

**The pause menu does not pause.** `DES-019` makes the bag real-time because rummaging is meant to be vulnerable, and a menu that froze the world would hand back exactly the safety the inventory exists to deny. It is also the only honest reading in co-op, where `get_tree().paused` on one peer pauses nothing for the other three. What it *does* do is stop the body taking orders — you stand still in the Deep while you read it.

**Leaving costs what leaving costs.** `ABANDON THE RUN` calls `GameState.die()`. A menu that let you bank a risky haul by quitting would make every extraction optional.

**Death now ends.** Bleeding out dropped an ember and left you lying on the floor indefinitely; it now runs the great reset and returns you to the Threshold. The Vörðr — `DES-012`'s spectating ghost — is `M3` and is absent rather than approximated.

### Joining, described honestly

`NetPlan` is a static class (no autoload — `TEC-001` budgets six and names them) holding one thing: how this process intends to connect. The command line writes into it *and so does the menu*, and `CoopSession` reads nothing else. A join code is ten Crockford base-32 characters — no I, L, O or U, so a code read aloud cannot become a different code.

**It is not matchmaking and it does not solve NAT**, and the host screen says so where a tester will actually read it. There is no relay and no hole-punching: a second machine reaches this one on the same LAN, through a forwarded port, or over Tailscale. Pretending otherwise would cost somebody an evening and read as a netcode bug.

The shape survives `M4-T07` because Steam changes **where an address comes from** and nothing about what the session does with it. Direct entry stops being the only way rather than becoming a fallback nobody maintains.

### The sound of the world

`Foley` — ten synthesised one-shots on the diegetic bus. `ART-002` is unambiguous that this layer matters more than the music, and the music got built first because it was the risky half.

The one that earns its place: **a footfall drops in pitch and rises in level with what you are carrying.** *"If a player can close their eyes and hear how rich they are, this system works"* — and it cost two lines, because `CarriedWeight` already knew the answer. Second is `NOTICED`, the cue when an enemy hears you, which is what makes `DES-005`'s *"explain your death in one sentence"* answerable at all.

### Two systems that were built, correct, and invisible

**The Ear was never instantiated.** It has existed since `M2-T03`; nothing anywhere created one. `--ear-probe` compares `HuntMix.CHANNELS` against `Ear.RENDERED` — both constants — so the parity check passed for two milestones while the visual channel was **never drawn**. `DES-018`'s standing rule is that from `M2` the build must be completable with sound muted. It was not, and every check said it was.

**`Player._reaching_for` was never shown.** The value has known what you would pick up since `M2-T01`. Without a reticle a tester walks a floor covered in loot pressing the key to find out what is reachable, and every "the pickup feels unreliable" report is really this.

Both are the ADR-097 fault a third and fourth time — *code that is correct, tested, and never reached* — and `check_dead.py` cannot see either, because in both cases the **class** is referenced by the probe that tests it. That limit is real and is written into the tool's own output; the lesson is that a name check and a reachability check are different things, and only playing the game or photographing it finds the second kind.

### The screenshots earned their place again

Headless probes passed while the settings panel rendered at x=0 with its title left of its own buttons, and while every checkbox indicator was clipped. `set_anchors_preset` does not move offsets; `set_anchors_and_offsets_preset` does. **Anything whose correctness is a claim about seeing gets photographed** — that is now four separate defects this rule has caught.

### Settings are preferences, not tuning

`Settings` writes `user://settings.cfg`. Deliberately **not** `TEC-003`'s save system: no run state, no progression, no migration path. Conflating them is how a save migration silently wipes somebody's audio. Per-bus volumes are `DES-018`'s ask; the full accessibility suite is `M4-T11` and is absent rather than half-present, because a greyed row promising high contrast is worse than no row.

Every control applies live. A slider you must close the panel to hear is one you cannot set by ear, which is the only way anybody sets a volume.

## ADR-101 — Direct connection, and the doorway that disconnected everybody
**Date:** 2026-08-17 · **Status:** accepted · **Amends `TEC-004`, `DES-012`, `PRO-001`** · **Follows ADR-100**

**Context:** ADR-100 built the shell that makes the `M2` gates runnable. This is the pass that makes them *survivable* — done at Josh's request before testing, and it found three faults, one of which broke co-op entirely.

**Decision 1 — a direct connection, described as one.** The overlay-network suggestion is gone; the host screen leads with `address : port` and offers the code as a shorthand. Port forwarding is the host's business. Nothing else changed, because nothing else needed to: `NetPlan` was always just a destination, and `M4-T07` still replaces only where that destination comes from.

Two ports were also found to be named `DEFAULT_PORT`, with different values — `CoopSession` had 47018 and the file introduced yesterday had 27015. The second was never reached, because `NetPlan` sets the port on every path, but two constants with one name and two values is precisely the drift this log keeps catching in other people's work. One number now, in `NetPlan`, and `CoopSession` reads it.

**Decision 2 — a failed join returns to the menu with a reason. It never quits.** `_on_connection_failed` closed the process and `_on_host_lost` closed the process. During a remote test the first of those is *the single most common event*: a mistyped address, a host not up yet, a port that is not open. Exiting in response teaches a tester nothing, costs a relaunch every time, and after the second one they stop trying. A client whose process vanishes mid-run reports *"it crashed"*, which is both wrong and the most expensive kind of report to chase.

**And the failure never arrived anyway.** Measured: joining a dead port emitted `connection_failed` **not once** in fifty seconds of frames. So the handler being fixed had never run, and the real behaviour was that a mistyped address left you standing in an empty Threshold forever with nothing to read — worse than quitting, because a quit is at least a signal. There is an 8-second ⟨tune⟩ deadline now, and a *"reaching for…"* line while it waits.

**Decision 3 (the serious one) — a connection outlives a scene change, so a session adopts one rather than building another.** The peer lives on the `SceneTree`, not on `CoopSession`. Walking from the Threshold into the Deep tore down one session and built another **on top of a live connection**, and the new one called `create_server` on a port it already held. It failed with `Couldn't create an ENet host`, and both players were left holding a connection nobody was serving.

**Every doorway in the game was a disconnect, and the entire sweep was green.** `run_coop.py` never changes scene; no single-process probe has a second peer to lose. It is the ADR-097 shape a fourth time — correct code the checks never make the game execute — and the only way to see it is to make two processes walk through a door. `tools/run_doorway.py` does exactly that and nothing more, and reverting the adoption reproduces the original error by name.

**Decision 4 — the party descends together.** Each peer changed scene the moment its own body reached the hole, so in company one player dropped into the Deep while everyone else stood at the fire looking at a world nobody was simulating for them. The hole is the host's decision now: anyone may walk into it, the host is told, and the host takes everybody. The Chamber stays per-player, because ADR-021 makes it a room no one else enters.

**Also, for the tester's sake.** The Threshold now shows **who is actually connected** — the host previously pressed OPEN THE THRESHOLD and had no way to tell whether anyone had arrived, and descending alone by accident is a wasted run and a confusing bug report — and lists the controls, which the Deep had and the camp did not, so the first time anybody needed them was the first time they were under pressure.

**What this run of the loop keeps proving.** Four separate faults now — party scaling, the stash, the Ear, and this — have been *code that works, that nothing ever made the game reach*. The checks that find them have nothing in common except that each one made the software do the thing a player would do: count a second body, take something back out, look at the screen, walk through a door.

## ADR-102 — The private door: your body leaves, and the room it goes to cannot reach the wire
**Date:** 2026-08-17 · **Status:** accepted · **Amends `TEC-004`, `PRO-001`** · **Reinforces ADR-021** · **Extends ADR-101**

**Context:** The first two-player remote test. It connected — ADR-101's work held — and then reported jittery remote movement, "quite a few issues" traversing menus from start to endgame and back, and crashes around the hoard room as the second player.

Five faults, and one shape: **every one of them was a per-player transition.** ADR-101 established that the party descends together and fixed the door everybody walks through. Nothing had looked at the door exactly one player walks through.

### What was actually wrong

**1. The client could not extract.** `_on_extracted` was guarded with `is_server()` and then acted on whichever body reached the Shaft. So a client extracting ran `GameState.bring_home()` **on the host's machine, with the client's loot**, and sent the *host* to the hoard room while the client stood in the Deep. That is the reported "jumping in and out of the hoard room as the second player", seen from the other side.

**2. A dying client was never told.** The mirror image: the run-end was gated on `player.is_multiplayer_authority()`, true on the host only for its own body. The client's ember dropped correctly and then they lay on the floor permanently.

**3. The Chamber was a black screen for anyone but the host.** It instantiated its body directly and never called `configure_replication`, so authority defaulted to peer 1 and `Player._ready` took the *remote* branch: no camera made current, no input, no bag. `chamber.tscn` contains no camera of its own. Deterministic, every time, for every client.

**4. Returning from the Chamber left a client with no body at all.** `MultiplayerSpawner` replicates spawns *as they happen* and never the existing world to an already-connected peer, so a client that changed scene and came back received nothing, forever.

**5. Remote movement was not interpolated at all.** Positions replicate at 20 Hz and were written straight onto the transform, so at 60 fps a teammate moved on one frame in three and was frozen on the other two. Measured: **still on 70% of frames.** `TEC-004` has described enemy transforms as *"synchronized, interpolated"* since it was written — a documented behaviour nothing ever implemented.

### The decision

**The door takes you out of the world.** Walking into your Chamber asks the host to **despawn your body**, and the room opens as an overlay above the camp rather than as a scene change.

Hiding the body was the obvious cheaper fix and it is a lie: an invisible body still collides, still holds a doorway, still makes noise, still occupies a seat. Other players now watch you walk to a door and go through it, which is what happened. **Reference:** Warframe's Orbiter/Relay split — a private ship, a squad that survives you entering it, and a door rather than a fade-out.

Not changing scene is what fixes fault 4 outright, and it does so by *removing* the problem: a returning player is a **re-spawn**, which replicates through the path that already works. The alternative was a world-resync protocol, which is real work that genuine late-join will still need one day and which a private room has no business requiring.

**The Chamber gets its own peerless `MultiplayerAPI`.** ADR-021 keeps a `CoopSession` out of that room to make privacy structural. That stopped being sufficient the moment the room floated above a live connection: the body in there is *local*, so it cheerfully fired an RPC at the host, which answered `Node not found: Chamber/chamber_body` — a private body reaching the wire, the exact thing ADR-021 exists to prevent. Guarding `Player`'s eleven outbound RPC sites one at a time would have worked until somebody added a twelfth. A subtree with its own multiplayer instance and no peer **cannot reach anybody by construction**, whatever gets written inside it later. ADR-021 is not amended; it is finally enforced.

**Seats are keyed to the peer, not to arrival order.** The seat came from the spawn counter, so a despawn/respawn brought you back wearing a different one — and since `party_slot` is what tells one ember from another (`M2-T05`), a player returning from their Chamber would have come home as somebody else, with their own ember on the floor naming a seat nobody held. Released on a real disconnect, so a door is not an identity change and a genuine newcomer still does not inherit a departed player's identity.

**The run ends for the party, and each player gets their own haul.** Peers cannot stand in different levels — the host owns the world, and a client in a scene the host is not in has nothing to receive. So extraction hands every peer its own bag over the wire and moves everybody at once, which is the Descent's rule (ADR-101) in reverse. **Dying no longer ends anybody's run**, including the dead player's: `DES-012` has your ember lying there for a teammate to carry out, and a run that stopped when you went out would delete the M2 co-op gate.

**Individual extract-and-wait is `M3-T09`** and is absent rather than approximated. It needs the Vörðr — somewhere to *be* while the others finish. A player parked in an empty room with no way to watch or help is worse than a short run that ends cleanly.

**Remote bodies are eased toward the wire.** Motion replicates into `net_position`/`net_yaw`/`net_pitch` and the body covers the gap in about one replication interval, so it is always roughly one packet behind and never waiting. **Still on 7% of frames, down from 70%.**

### The check that should have existed

`run_doorway.py` asked one narrow question about one door: does the connection survive? Every one of these five faults was downstream of a door and none of them touched the connection.

It walks a **client** through a **private** door now and asks the blunt questions instead — afterwards, does everyone still have a body, is it the same seat, and did either side send packets into freed nodes? All four rows fail on the previous commit by name. The jitter is a number in `run_coop.py`: how often a body that is definitely walking does not move at all, which is a thing a probe can see and a person can only feel.

**The recurring lesson, in a new place.** ADR-097: a probe that measures a function proves the function. ADR-099: a check that lives in the wrong scene stops running. This one is the same family — **a test that covers the transition everybody takes will not cover the transition one person takes**, and the difference is invisible until somebody plays it.

---

## ADR-103 — The published board says which commit it came from
**Date:** 2026-08-19 · **Status:** accepted · **Amends `CLAUDE.md`, `tools/status.py`, `tools/artifact_sync.sh`**

**Context:** Publishing the descent board after `M2-T12` came back as a conflict — *"another session published a newer version"*. Resolving it took a WebFetch, a task-count comparison against two commits, and a question to the user, for what turned out to be a mechanical fact: the live copy had been published from `22ac90c` and the local one was built from `c9bddd8`, a descendant. Nothing had diverged. Nobody else was involved.

**The actual failure is that a snapshot has no memory.** The board is a pure function of `PRO-001` at a commit — same commit in, same bytes out, no hand-written content, nothing unique that can be lost. But the published copy carried no record of *which* commit, so a session that had lost track of what it last published — across a compaction, or simply by being a different session — could not tell whether the live page was behind it, ahead of it, or identical. The publish tool can only report that someone got there first; it cannot know that "someone" was the same agent an hour earlier.

**Decision — the fragment stamps its own provenance.** `tools/status.py --fragment` embeds an HTML comment reading `descent-board commit <sha>`. On a conflict, read it off the live page and ask git one question:

```bash
git merge-base --is-ancestor <sha> HEAD
```

Exit 0 means the published copy is strictly older and republishing with `force: true` discards nothing. A non-zero exit means the two genuinely diverged, which is the only case that needs a person. The rule is in `CLAUDE.md` and the hook hands it to the agent verbatim, so the next session resolves this in one step instead of stopping to ask.

**Only the fragment carries it.** The committed views (`status.html`, `status-app.html`) must not: the SHA available while generating them is necessarily the commit *before* the one that contains them, so it would be wrong in the file it shipped in — and it would rewrite a generated view on every single commit, which is noise in exactly the artefacts this project insists must never disagree with their source.

**On forcing, and why it was safe here.** ADR-063 makes the board a generated view. That is what made the overwrite recoverable rather than destructive: the worst case is that another session republishes from an older commit and the two ping-pong until somebody runs the generator again. The ancestry test is not protecting data — it is telling a decision an agent can make from one a person has to.

**A quoting fault, caught by testing the hook rather than reading it.** The rule went into `artifact_sync.sh`, whose `jq` program is a single-quoted shell string; the word *"somebody's"* closed it early and broke the hook outright. `bash -n` caught the syntax error, and running the hook against a real payload confirmed it still emits valid JSON. A hook is a thing that only runs at push time — the moment it is least welcome to discover it is broken.

---

## ADR-104 — CI checked out a repository nobody has
**Date:** 2026-08-19 · **Status:** accepted · **Amends `.github/workflows/ci.yml`, `.github/workflows/build.yml`, `tools/check_project.py`, `tools/test_checks.py`**

**Context:** A position audit found the Godot job in CI failing, and then found it had been failing since `M1-T10` — **fourteen commits and three days**, every one of them pushed on a green local sweep. The error was `glTF: Error parsing .gltf JSON data: Expected 'true', 'false', or 'null', got 'version' at line: 0`.

That message is the whole story once read closely. `version` is the first word of a **Git LFS pointer file**. `.gitattributes` routes `*.glb` through LFS, `actions/checkout` leaves LFS files as ~130-byte text stubs unless told `lfs: true`, and no workflow said so. CI was parsing `version https://git-lfs.github.com/spec/v1` as glTF.

**Nothing local could have caught it.** Every developer clone has the LFS smudge filter installed, so `humanoid_rig.glb` is 295,704 real bytes here and 131 bytes of text there. The sweep is not weaker than CI — it was running against different content. This is the inverse of the usual complaint about local checks: not that they are laxer, but that they were never looking at the same repository.

**The damage is what the failure hid, not what it broke.** `check_scripts.sh` asserts the rig fourth of fourteen, and exits on failure — so **the ten assertions after it have not run on a clean checkout since 16 August**: boot, teardown, data, the way out, the fallen, the hoard, party scaling, the three places, the front door, both doorways, two-player co-op. `CLAUDE.md` justifies pushing on the grounds that *"CI is the only thing that runs the full sweep on a clean checkout."* For fourteen commits that sentence was false, and the argument it supports was resting on nothing.

**The export job is the more dangerous half, because it was green.** `build.yml` had the same omission, and an export from pointer files does not fail — it succeeds and ships a build with the art missing. Today nothing is lost: the rig is referenced by `tests/rig_probe.gd` and by no scene, the player is still ADR-046 blockout capsules, so **no build a playtester has received was wrong**. But `M3-T07` puts authored gear on screen, and at that point a green tick here would have meant the opposite of what it says. This is ADR-099's shape exactly — *a build that boots proves the pack loads, not that it contains the game* — arriving by a different road.

**Decision — two static checks, because the alternative is noticing.**

- `check_workflows()` fails any workflow job that runs Godot and checks out without `lfs: true`. Per job, not per file: a docs-only job has no business paying for LFS.
- `check_lfs_content()` fails any LFS-tracked file in the tree that is still a pointer. That one speaks to a person rather than to CI — a clone made without `git lfs install` currently gets told its art is corrupt, which sends you hunting a bad export instead of a missing fetch.

Both are exercised by `tools/test_checks.py`, which grew a `tool` field to do it: every trial before this one targeted `status.py`, and a trial pointed at the wrong checker passes by being silent — the precise failure that script exists to catch.

**What actually failed here is that a red CI run is invisible.** The pre-push sweep is thorough and the `PostToolUse` hook confirms a push landed, but nothing looks at the result, and CI finishes about fifty seconds after the agent has moved on. The checks above close this particular hole for good; they do not close the general one. **Read the CI conclusion at the start of a session** — it is one `gh run list` — because a check that has silently stopped running is worth less than no check at all, and this project has now proved that twice (ADR-099 was the first).

---

## ADR-105 — Lighting was handed off as polish, so nobody could find the way out
**Date:** 2026-08-20 · **Status:** accepted · **Adds `M2-T13`, `M4-T13`; rewrites both `M2` gates; amends `DES-019`'s HUD scope**

**Context:** After the first two-player remote test the objection was that the `M2` gates are *"arbitrary test cases that are more opinion than actual analysis"*, that the level offers no guidance on where to go, and that combat amounts to *"swing until you die."* Checking the build rather than the memory of it: the first two are correct, the third is correct **and on-plan**, and the reason for the first is a scheduling fault nobody had noticed.

**Thin combat is a deliberate deferral.** `DES-009`'s M1 protocol builds one attack completely — wind-up, active, recovery, input buffering — and withholds block, heavy and shove precisely so that four verbs are not built partly. *"Blockout must feel good unjuiced"* is a standing rule. Nothing to fix here, and adding a verb now would be the ADR-064 failure wearing a design hat.

**Wayfinding is not a deferral. It is a hole.** `ART-001` says, in as many words, that **"darkness is a mechanic, not an effect [...] lighting design is gameplay design here, so it can't be handed off as polish."** `PRO-001` then handed every part of it to `M4-T05` — *"real art pass, real audio, real UI"* — which is handing it off as polish. Searching every milestone for wayfinding, landmarks, signposting, orientation or navigation returns nothing. The floor therefore ran on **one directional light at -42° in an underground level, with flat 0.85 ambient**: six rooms lit identically, so no room looked like anywhere and nothing drew the eye toward anything. The Shaft — the way out — was a pale disc on the floor of one of them, with no light and no sound.

**And every check passed.** `--route-probe` asserts a clean route from entrance to exit exists and it has always been right. It cannot see that nobody could *find* the route. `DES-005`'s *"the Shaft's location is known"* was true of the layout and false of the experience, and no probe in this project was asking about the experience.

**Decision — one rule, and `ART-005` chooses the palette.**

> **Pale light is the way through. Gold light is what it will cost you.**

The first draft of this rule was *"the way out is warm"*, which is the natural instinct and is **forbidden**: gold is the only saturated hue in the game and it is spent on treasure, her fire and the ember, with the Threshold as the one warm place. A gold exit would say "safety" in the vocabulary this game reserves for "this will kill you." So the exit reads by **value** instead — a pale column, bright, never warm. Doorways carry pale light, which is the single largest win available: the rooms did not need to become distinct nearly as much as the *ways out of them* did. Glitter lights itself, because `ART-005`'s *"the player's eye is pulled to exactly the thing that will get them killed"* only holds if treasure is lit; in a flatly-lit level gold is a colour on a box.

**Wayfinding is level design, never UI.** `DES-019` makes orientation *"a thing you equipped rather than a thing the HUD gave you"*, so a marker or a minimap was never available and should not be.

**Two x-rays were corrupting the gate, and both were once justified.**

The debug readout listed **every enemy's state and hit points**. Its own comment explained why — *"the awareness ladder is unreadable without audio [...] the audio half is `M2-T03`; **until then** this is the only channel there is"* — and `M2-T03` is done. So it was a third channel, strictly more informative than either designed one, whose stated expiry condition had already passed. It also broke `DES-019` outright, which says of the Ear: **"never shows enemy count, health, or type."**

Worse, `DebugOverlays` drew every vision cone and the entire clamor field **in every session**, with no toggle. A tester reading that is not experiencing the awareness ladder, they are consulting it — and nothing they then say about how legible the pressure feels means anything. It stays, because `TEC-001` is right that the field is untunable blind; it is now off until `o` / d-pad-right. Removing the text list orphaned `Enemy.hears_player()`, which `check_dead.py` caught within the minute; it is now the overlay's third cone state, which is where ADR-074's *"sight and hearing are separate signals"* wanted it all along.

**`DES-019` asked for a wound vignette and nothing drew it** — *"wounds in gait, in a hand that won't come all the way up, in vignette."* Until now the only channel saying you were being hurt was a sample and a number in a debug label, which is the honest source of *"swing until you die"*: you could hear that something had happened and read afterwards that it had. The vignette carries damage **bearing**, and only for hits you could not see — a thing in front of you is already on screen, so flashing for it would spend the channel on information the player has. This is not the juice `DES-009` defers: the test is whether removing it costs a **fact** or only a feeling, and without it *"which side is hitting me"* is unanswerable.

**The gates are rewritten as experiments, not verdicts.** The sentences were right and unusable. *"Voluntarily abandons loot to survive"* assumes a choice between loot and escape; with no findable exit the run ends in wandering and the gate measures navigation while calling it greed. And a failure localised nothing — one bit of information against five candidate causes. Each gate now carries a protocol and a short list of preconditions, each of which names its own fix. **A failed precondition is the finding.** This project instruments everything else and the gates were the one place the standard dropped to *"we'll know it when we see it."*

**A probe that counts is not a probe that looks.** `--sight-probe` asserts the rule against the built scene tree — never against the constants it was built from, since a check reading `DOORS.size()` would pass with every light missing. All five claims were validated by planting their violations. It then passed twelve-of-twelve while the spawn view was **solid black**, because the first `--sight-shot` faced 180° into the wall behind the player. That is `--ear-shot`'s lesson arriving a second time, and the photograph earned its place immediately: it also caught the well rendering as an eight-spoked asterisk, because the segments were axis-aligned on a circle whose tangent they were meant to follow.

**The check that mattered most was the one asking the geometry.** Landmarks are solid, and the altar landed on top of the Waystone — which surfaced three probes away as *"dropping the heaviest item did not make the player faster."* True, and nothing to do with weight: the player was standing inside a block of stone at 0.00 m/s laden and unladen alike. The first fix declared a clearance radius per landmark, which is wrong twice over — it cannot describe a shape with a hole in it, and a number written beside a shape is one more thing that can disagree with the shape. Dropping a body-sized sphere at every authored position instead found **two more collisions immediately**: the exit stair clipped the Shaft, and the junction well clipped a piece of authored loot by 20 cm, which would have made it unpickupable and would have been invisible in every screenshot.

**The lantern is what finishes this, and it was never scheduled either** — filed as `M4-T13`. Until it exists the ambient floor stays navigable rather than truly dark, because a dark level with no light source is not a mechanic, it is a bug. That ⟨tune⟩ number is the one `M4-T13` exists to lower.

---

## ADR-106 — Every system had a probe; nothing proved a person could operate one
**Date:** 2026-08-22 · **Status:** accepted · **Adds `M2-T14`; reopens `M2-T13`; amends `DES-005`, `DES-009` scope**

**Context:** The `M2-T13` build was played and came back with four things: it still is not direct about what to do, **there was no way out of the level**, dead enemies do not read as dead, and the AI does not path. Plus the sentence that matters most — *"it's not super playable and demonstrates no real evidence of being viable."*

**All four were true, and the first two are `M2-T13`'s fault.** That task shipped a beacon, wrote a probe asserting the beacon was visible **from the junction**, watched it pass, and was ticked. Measured against every room afterwards: **two of six, and the room you spawn in was blind.** The check measured the thing that had been built rather than the thing a player needs, which is the same failure as ADR-097 (scaling that could not fire) and ADR-099 (a census in the wrong scene) wearing a third costume. `M2-T13` is un-ticked; this task is the rest of it.

**And finding the Shaft would not have helped.** It had **no prompt of any kind**. You had to stand on an unmarked pad, press a key nothing suggested, then hold position for four seconds with no progress shown anywhere — while the pad slowly changed colour beneath your feet, where you cannot see it. On the evidence available to the player there was no way out. The Waystone was identical: a timed channel, host-side, with nothing on screen, so pressing the key that ends your run appeared to do nothing. Both now draw the same ring at the crosshair, which is where the player is already looking and where every reference on hold-to-interact puts it — the hold is *chosen over a press* precisely so it can be seen happening and backed out of.

**Neither channel reached the other peers at all.** `Shaft._progress` and `Player._spending` are both host-side, and the comment beside the Shaft's brightening claimed *"every peer can see it, because a teammate standing in the Shaft is information the whole party needs."* True of the intent, false of the build: on a client the pad never brightened and a client spending a Waystone watched nothing happen for the whole channel. Both are replicated now.

**The level said nothing about itself.** No objective, anywhere, ever — `ArrivalBrief` is three lines on arrival and then gone. *"Climb out at the light"* is the load-bearing one: it names the beacon as the exit, so the pale column stops being scenery the first time it is seen. This is deliberately **not** onboarding, which is `M5-T05`'s job; it is the one-screen brief every mission-structured game opens with.

**Dead enemies stayed standing.** The comment was proud of it — *"No ragdoll, no death animation, no corpse fade — all polish, all absent."* Correct at `M1` and wrong at a playtest, for exactly the reason the wound vignette was: **"did I kill it?" is information, not polish**, and in a level that is now deliberately dark, 0.28 grey going to 0.12 grey is close to no signal. It topples, thumps, lies there and sinks. Still not a ragdoll — three unambiguous cues from primitives answers the question a player is actually asking. Only the host frees the body: it is spawner-managed, and a despawn has one owner exactly as a spawn does.

**There was no pathfinding in this project. At all.** `_steer_toward` pointed velocity at the target and walked — the correct technique for an open arena, and the wrong one for a floor whose own header boasts *"corners, doorways and a room you"* must commit to enter. Standard Godot practice is a baked `NavigationRegion3D` with a `NavigationAgent3D` per body, repathing a few times a second rather than every frame. The straight line survives as the deliberate fallback: the navigation map takes a frame to come up, and up close a path node is worse than walking at the thing.

**The bake then closed every doorway, and the number that did it was `cell_size`.** Recast erodes by `ceil(agent_radius / cell_size)` **cells**, not by the radius — so a 0.2 cell rounded a 0.45 m agent up to three cells, 0.6 m a side, 1.2 m off every opening. The doorways here have roughly 1.4 m of true clearance because each is flanked by both rooms' side walls, so the mesh baked with 130 vertices, every room had surface on it, and **not one doorway connected**: six navigable islands and no route between them. It looked exactly like an agent problem. Dropping the radius to 0.2 "fixed" it and would have shipped agents thinner than the bodies they steer; a 0.15 cell makes the erosion match the radius it is meant to represent and connects the floor at the full 0.45 m.

**Decision — the bar for `M2` is a stranger finishing a run, and checks must ask about the player.** `--sight-probe` now asserts the way out is visible from **every** room rather than from one. `--nav-probe` asserts a route across the floor that *bends*, because a straight line between those two points goes through three walls — traversal, not the existence of a mesh. Every assertion in both was validated by planting its violation, and `--nav-probe` found the Godot gotcha itself on its first run: the navigation map is not queryable in the frame it is baked in.

**A photograph remains the only thing that catches what a number cannot.** `--sight-shot` earned its place twice more here: the first run photographed a wall because it faced 180°, and the beacon at 16 m failed the entrance sightline **by one centimetre** — a pass that is really a coin toss. The binding constraint is the worst sightline in the level, not the best: from the middle of the entrance the room's own north wall is 6 m away, which forces the beam past 15 m before anything else is considered. At 24 m it clears every room, and that is the fiction catching up with the name — a **Shaft** is a hole to the surface, so light falls down it.

**On the wider question — *"what stage of playability do we need to be at?"*** `M2`'s gate requires a first-time player to complete a run unaided, and ADR-105 wrote that down as a precondition three days ago. The honest description of the build before this task is that **every system had a probe proving it worked and nothing proved a person could operate it** — which is the whole distance between a systems prototype, which this rigorously was, and a playable build. Nothing here adds a system. All of it is connective tissue that was never scheduled, because no task in any milestone owned it.

---

## ADR-107 — Abandoning a run left the process with no multiplayer peer at all
**Date:** 2026-08-22 · **Status:** accepted · **Adds `M2-T15`**

**Context:** A playtester walked off the edge of the camp, let the fall run for a while to see whether the game would stop them, abandoned the run, and descended again — to a **grey screen**. That is three separate faults in one sitting, and none of them had a check anywhere, because every probe in this project measures a system doing its job rather than a player leaving the rails.

**1. Abandoning set the peer to `null`, and nothing ever put one back.** Godot installs an `OfflineMultiplayerPeer` at startup, and *every* solo path here quietly depends on it: with it, `is_server()` is true and spawning works, which is exactly why there is no single-player branch to drift (ADR-064). `PauseMenu._leave()` closed the peer and assigned `null` — correct in intent, since a host walking out to the menu must stop hosting. From that moment on, **in that process**, `is_server()` answered false, `CoopSession.spawn_player()` returned `null` at its first line, no body was built, and the next level came up grey: the world was there and the camera belonged to a player who did not exist.

The dependency was invisible precisely because nothing had ever taken the offline peer away. It is repaired in `CoopSession`, not only in the menu: the session is the thing that *needs* a peer, so that is where the requirement belongs, and every other route back into a level is covered without anybody having to remember. The menu restores it too, because it should not sit in a state the next scene has to fix.

**2. There were no world bounds and no fall recovery anywhere.** Not in the camp, not in the Deep, not in the Chamber. The camp is a 34 m slab with walls on three sides, so its open side is simply where this is easiest to find. Bodies now remember the last ground they genuinely stood on and return to it — from the *body*, so it needs no per-level configuration and cannot be forgotten by the next level somebody builds.

**The threshold is relative, and that is not a detail.** An absolute floor is the obvious implementation and would have been catastrophic: the Chamber is an overlay parked **2000 m below the camp** (ADR-102), so any fixed depth generous enough to catch a fall would also decide that every player standing in their own hoard room had fallen out of the world and yank them back to the fire. Measuring from where you last stood works at any altitude and knows nothing about where levels put themselves.

Nothing is taken for falling. `DES-002`'s losses are meant to be ones the player can explain, and dropping through a hole in a blockout is not a decision anybody made. It prints, so a hole that keeps catching people appears in a log rather than only in a shrug.

**3. The Chamber outlived its level.** `_open_the_chamber` parents the room to `/root` rather than to the Threshold, so that hiding the camp does not hide the room floating above it — right, and it has a consequence nothing handled. `change_scene_to_file` frees the *current scene* and leaves every other child of the root alone, so abandoning from inside your own hoard room left the Chamber parented to the root, drawn over the main menu, with its private `MultiplayerAPI` still registered at `/root/Chamber`. The stale API is the worse half: the next Chamber would inherit somebody else's island, which is the exact fault ADR-102 built the island to make impossible. A level now cleans up what it created on the way out, whichever way out it was.

**Decision — `--edges-probe`, which asks what a player does rather than what a system does.** All three assertions were validated by planting their removal. It also caught two faults in its own first draft, both worth recording because both are the same mistake:

- It simulated the fall with `teleport()`, which is a *deliberate* relocation and therefore updates the ground of record — so the safety net moved down with the body, the recovery correctly declined to fire, and the probe reported a failure the game did not have. Setting `global_position` directly is the honest simulation of falling.
- It built the session with `CoopSession.new()`, which has no `Actors` or `Spawner` children and dies in `_ready` before reaching anything worth testing. The scene, not the class.

**The general lesson, and it is the third time this month.** ADR-097 shipped scaling that could not fire, ADR-105 shipped a beacon two rooms could see, and ADR-106 named the shape: *every system had a probe proving it worked and nothing proved a person could operate it.* This is the next layer down — **nothing proved a person could recover from doing something ordinary and slightly wrong.** A test suite built entirely from the happy path will keep finding the happy path intact.

---

## ADR-108 — Nobody had walked into the Chamber, and nobody had stayed dead
**Date:** 2026-08-24 · **Status:** accepted · **Adds `M2-T16`** · **Extends ADR-102, ADR-107**

**Context:** An audit run against `e80131f` with one instruction: find defects a green sweep cannot see, and prove each one in the engine. All sixteen probes, `check_project.py`, `check_dead.py`, `status.py --check` and CI were passing on that commit, and five defects were live in it. Four were reachable by a player and two of those in the first thirty seconds of a fresh install — from the single action the camp's own readout tells a new player to take.

Every one is the shape ADR-097 named and ADR-105, ADR-106 and ADR-107 each found again: **the state was proved reachable by a probe, using a route no player has.**

### 1. Walking into your own Chamber threw you 2000 m up into the camp you had just hidden

The room is an overlay parked at `CHAMBER_OFFSET`, and `Chamber._spawn_body` gives its body a `position` and adds it — it does not `teleport()` it in, because the room is built around its own origin and always has been. `_last_solid`, the ground of record ADR-107 introduced, was seeded **only** by `_apply_teleport`. So the one body in this game that spawns two kilometres down began life measuring itself against a memory of the camp, read `-2000 < 0 - 45` on its first physics frame, and was returned to the origin — which `_open_the_chamber` had set `visible = false` one line earlier.

What a player got was a black screen, the Chamber's music, and an invisible floor, with the door, the pile and the stash all 2000 m below. Holding forward closed none of that distance. **The Chamber has never been enterable in a real session** — solo or co-op, host or client — and the only way on was ABANDON THE RUN, which calls `GameState.die()`.

This is precisely the outcome ADR-107 rejected an absolute floor to avoid: *"any fixed depth generous enough to catch a fall would also decide that every player standing in their own hoard room had fallen out of the world and yank them back to the fire."* The threshold was relative and correct. The **seed** was absolute, and one code path skipped it.

**A body's starting position is ground it has stood on**, seeded in `Player._ready` beside `_last_position`, which was already seeded there. The two are the same kind of fact — where this body was a moment ago — and a body that seeds one and not the other is the asymmetry that caused this. It also fixes the class rather than the instance: it needs no per-level configuration and cannot be forgotten by the next level that instantiates a body directly, which is the same reasoning ADR-107 used to put fall recovery on the body.

### 2. Coming back out of the Chamber switched the camp off, permanently

`_open_the_chamber` calls `set_process(false)`. `_close_the_chamber` never turned it back on; the only `set_process(true)` in the file sat inside `_exit_tree`, where the node is already leaving and it does nothing.

The camp's `_process` **is** the camp: it notices you standing in the Descent, notices you standing on the Chamber slab, re-arms that slab, and writes the readout. After one visit all four are dead. You stand in the hole and nothing happens, and the readout is frozen on what it said before you went in — so the stash count you read after sorting your haul is the one from before you sorted it. The only way on was ABANDON, which deletes the stash the visit existed to build.

**One function owns the undo now**, and both exits call it. The failure was not that a line was forgotten; it was that there were two teardowns to keep in agreement, which is a thing that stays true and gets forgotten again.

### 3. Dying alone never ended the run

`_end_the_run` was reachable from `_on_extracted` and from nowhere else, so extraction was the only way a run could finish. A solo player who bled out went `spent`, had their bag emptied and their ember dropped, and then stayed there: `spent` clamps `_target_speed` to `0.0`, self-recovery refuses because it asks `is_downed()` and `spent` is not downed, and the floor kept running around a person who could not move. Nothing on screen said so except the developer readout — whose key list ends `r reset`, an action with exactly one consumer in the repository, in `movement_gym.gd`.

ADR-102 decided that dying must not end anybody's run, and that decision is right and is untouched: your ember lies there for a teammate to carry out, and a run that stopped when you went out would delete the M2 co-op gate. **It was simply the whole rule.** Nothing said what happens when there is no teammate — which solo is, always, and which is most runs.

**Nobody left standing ends the run.** Not "somebody died": the party being gone, which in a party is the wipe every extraction game ends on and in a solo run is the same event. `spent` rather than `is_incapacitated()`, because a **downed** player is bleeding and recoverable — they crawl, they have one self-recovery, a teammate can reach them — and only `spent` is final.

**A window, not an instant, and it is re-checked at the end of it** (`party_wipe_seconds`, 3.0 ⟨tune⟩). Two jobs, and the second is load-bearing: a cut to the camp on the frame you go out gives the player nothing to read, and the M2 exit gate asks a tester to explain their death in one sentence; and **a revive inside the window has to call it off**, because two players going down a second apart is an ordinary way for a fight to go and the second one getting up must not arrive after the run is already over. Re-checking is what makes the rule *nobody has been standing for a while* rather than *nobody was standing on one particular frame*.

### 4. A host whose port was taken built a level with nobody in it

`_start_host` checked `create_server`, called `push_error`, and returned — skipping the `spawn_player(HOST_PEER)` on its own last line. The `OfflineMultiplayerPeer` underneath went on answering `is_server()` true, so nothing downstream suspected anything: no body, no camera, an empty readout, and the only trace in a console the player is not reading. ADR-107's grey screen, arriving from a second direction. `_start_client` had always handled the identical failure correctly, on the very next function, by giving up with a sentence a person can act on.

Fixing it exposed two more things about `_give_up`, both now repaired:

- **It nulled the peer.** That is the exact ADR-107 shape, surviving here because `_ensure_a_peer()` repaired it in the *next* session before anything read it. Repair is not safety: `local_player()` asks `multiplayer.get_unique_id()` every frame the camp draws its readout, so with no peer at all that is an error per frame between giving up and the menu arriving. It restores the offline peer now, as `PauseMenu._leave` has since ADR-107. There is no reason for the session that *needs* a peer to be the last place still taking it away.
- **It navigated from inside `_ready`.** A host finds out its port is taken while the level it belongs to is still being built, and changing scene from there produces *"Parent node is busy adding/removing children"*. The navigation is deferred by a frame.

### 5. The Reticle kept reading a body that had left the tree

`is_instance_valid` keeps answering true for a node removed from the tree and not yet freed, which is the state a despawn passes through. A client walking into its Chamber has its camp body despawned, and for that frame the Reticle asked it for `global_position` and handed it to `Shaft.nearest`, which calls `get_tree()` on it. `is_inside_tree()` is the question that was meant; it implies validity, so it replaces the test rather than joining it.

### 6. A body outlives its peer by a frame, and two places addressed it anyway

Found by the check for fault 3 rather than by the audit: `--wipe-probe` needs a second body to tell a party apart from a wipe, and in one process with an offline peer the only way to get one is to spawn it for a peer id that is not a process. Both `_end_the_run` and `Player.teleport` then addressed it — *"Attempt to call RPC with unknown peer ID"*.

That is an artefact of the probe and it is also real, narrowly: `_on_peer_disconnected` frees a departed peer's body, but a run ending or a teleport issued inside that window addresses a peer the wire no longer has. Both sites now check `multiplayer.get_peers()` first and both **print** when they skip, because a teleport that quietly does nothing is otherwise indistinguishable from one that worked.

Worth recording for how it surfaced. The first run of `--wipe-probe` was filtered to `[wipe]` and `[death]` lines and looked perfect; the errors were three lines away the whole time and only the full sweep's `^ERROR:` grep found them. **A probe read through a filter is a probe you have not read** — which is the same fault as fault 5, where `run_doorway.py` was not grepping for `SCRIPT ERROR`, committed by the person auditing it.

### The checks that should have existed

**`--edges-probe` asks about the Chamber the way a player meets it.** It walks onto the pale slab rather than calling `_open_the_chamber()`, so the doorway is under test and not the function; it asserts the body is standing in the room it was sent to; it walks back out **through the Chamber's own door**; and it then asserts the camp is still a camp — processing, readout moving, and the door willing to open a second time. Going back in is the assertion because it is a thing a player does, and because every branch of `_process` is dead or alive together.

That last point is the whole reason `run_doorway.py` was green through all of this. Its private-door rows pass because `--chamber-probe` calls `Chamber._leave()` on a four-second timer **regardless of where the body is standing** — it manufactures an exit no player can perform, and so reported that a body two kilometres from a door had used it. The `[void] chamber_body fell out of the world` line was sitting in that check's own client log the whole time, unread.

**`--wipe-probe` asks what happens to the player the run is finished with**, in both directions: one down with a teammate standing does not end anything, nobody standing does and takes the stash with it, and getting up inside the window calls it off. It needs a second body to tell a party apart from a wipe, which is also what `--ember-probe` had been faking — that probe's own comment admits its solo rescue is *"not a thing that happens in a real run"*.

**A busy-port step in `check_scripts.sh`**, because every networked check in this project picks a free port on purpose so that two of them can run at once. Nothing anywhere had ever hosted twice on one port, which is the only way to see fault 4 at all.

**`run_doorway.py` now fails on `SCRIPT ERROR`.** It asked about packets into freed nodes and about the census and about nothing else, so fault 5 printed inside a run it reported as passing.

Every assertion above was validated by planting its violation, and one of the plants found a fault in the probe itself: two early exits reported a fresh list instead of the one they had been filling, so the first red run threw away the precise finding (*a body 2000 m from its own door*) and reported only the vaguer consequence that followed from it. A probe that discards what it has already found is the reporting equivalent of the bug it was written to catch.

**The lesson, for the sixth time, and it has a sharper edge now.** ADR-097 shipped scaling that could not fire; ADR-099 put a census in the wrong scene; ADR-105 shipped a beacon two rooms could see; ADR-106 named the shape; ADR-107 found that nothing proved a person could recover from an ordinary mistake. This one is the layer under that: **a check can reach a state by a route the game does not have, and then certify the state.** `_leave_soon`'s timer and `--ember-probe`'s `restore_for_descent()` are not sloppy — they are both reasonable ways to get a measurement started. Each is also the only way that state was ever reached, and so each proved nothing about the state a player arrives in. The question to ask of a probe is not *does it exercise this code* but **could a person get here the way you just did.**

---

## ADR-109 — The greed gate was asking a half-built system a question only the finished one can answer
**Date:** 2026-08-24 · **Status:** accepted · **Amends `PRO-001` (M2 exit gate, M4 exit gate, M3 ordering)** · **Extends ADR-105** · **Ticks `M2-T13`**

**Context:** *"The current blockout state of the game is no real judge of playability."* Raised after ADR-108, and it is half right in a way worth separating carefully, because the wrong half is the one that would quietly lower a bar.

**What a blockout cannot judge is appeal.** Whether this game is *good* — whether the Deep is oppressive, whether the hoard is a monument, whether anybody wants a second run — is unanswerable from grey boxes and always was. **What it judges better than anything downstream is feel and legibility**, which is Swink's ordering, which `DES-009` adopts, and which is the entire reason `M1` existed as a separate milestone. So "a blockout proves nothing" is false; "a blockout proves nothing *about pressure*" is the real claim, and it is correct.

### The gate was unanswerable, not merely hard

`GATE M2 EXIT` reads: *a playtester **voluntarily abandons loot to survive**, then talks about it afterwards.* That sentence assumes loot and survival are in tension. On the floor that exists, greed costs you one Gullsjúkr and a wider clamor radius — and that is all it costs, because the two systems that give greed teeth are both `M3`: the Tithe (`M3-T04`), which makes a hoard an obligation rather than a score, and classes (`M3-T02`), which make what you brought down a decision you can regret.

Running that gate now returns an answer about the blockout, exactly as claimed. Worse, it returns a *single bit* against a system that is deliberately unfinished — which is the failure ADR-105 already identified in the same sentence and tried to fix with preconditions. ADR-105 was right about the diagnosis and treated the symptom: it kept an unanswerable gate and wrapped it in four questions that *are* answerable.

**Reference.** Supergiant's Hades reached "the run feels good" long before "the meta-progression creates tension", because the second has nothing to grip until there is a Mirror to spend on. Tarkov and DMZ both hang extraction tension on gear *loss* — which here is `DES-003`'s Tithe, and is not built. A gate is a measurement, and a measurement taken before the instrument exists is not a strict bar. It is a coin toss with a strict reputation.

### The decision — the gate moves to where the thing it measures lives

**`GATE M2 EXIT` becomes ADR-105's preconditions, promoted.** They were already written, already the right questions, and already the things a blockout answers honestly: a first-time player finishes a run unaided, reads their own noise roughly right, explains their death in one sentence, and discovers they can drop loot without being told. That is `M2`'s actual claim — *the loop closes and a stranger can operate it* — and every one of those four failures localises to a named fix.

**The greed dilemma becomes `GATE M4 GREED`**, beside the slice gate, where the Tithe, two classes, equipment and a polished floor all exist. Unchanged in wording, because the sentence was never wrong — only early. `PRO-005`'s ethics and `DES-002`'s core loop both rest on it, so it stays a gate rather than becoming an aspiration.

**This is not a lowered bar.** `M2` still does not pass until somebody who has never seen the game finishes a run without help, and nothing in this project can assert that: the whole of ADR-106 is the distance between a probe and a person. What changes is that failing it will now mean something specific.

### Two corrections that fall out of the same reading

**`M2-T13` is ticked.** ADR-106 un-ticked it because its beacon was visible from two rooms of six and said in as many words that `M2-T14` was the rest of it. `M2-T14` is done and `--sight-probe` now asserts **6 of 6**, measured. Leaving the task open after the work landed is a stale dashboard of the kind `CLAUDE.md` says is worse than none, because it is believed.

**`M3` is reordered so the save system is first.** It sat sixth of nine — behind classes, Aspects, ranks, deeds and equipment slots, every one of which *is* save state. `TEC-003` and `CLAUDE.md` both say versioned from commit one *because retrofitting is agony*, and the written order guaranteed the retrofit. `M3-T04` also moves ahead of `M3-T03`, which cannot cap a Boon by a rank that does not exist yet. New order:

```
M3-T06  save, versioned      → the thing everything below writes into
M3-T04  Tithe and Pact Rank  → the pressure the M2 gate was missing
M3-T01  Tribute → Boon → Aspects
M3-T03  Boon cap by own rank → needs T04's rank
M3-T02  two classes
M3-T05  Legacy screen
M3-T08  deeds at the Settle beat
M3-T07  equipment slots and visible gear
M3-T09  extract and wait
```

**What this does not do is unblock `M3`.** An amended gate is an answerable gate, not a passed one, and `status.py`'s `gate-order` will keep refusing `M3` until a real person plays a real build. That is the correct outcome and the reason this ADR does not touch the tool: the point was never to get past the gate, it was to make failing it informative.

---

## ADR-110 — The floor's two decisions were being scaled away, and solo never saw either
**Date:** 2026-08-24 · **Status:** accepted · **Adds `M2-T17`** · **Amends `M2-T07` scaling** · **Extends ADR-032, ADR-098**

**Context:** The first play of the post-ADR-108 build. The report was a question — *"what does a current run include? I was able to pick up items and get to the shaft, but should there be more than one floor?"* — and the answer to the literal question is no, one floor is right until `M4-T01`. The useful part was the tone: a run read as pick some things up and walk to the light.

It did, and not because the floor is small.

### Solo could never reach either of the floor's decisions

`LOOT` held nine authored items and `_spawn_loot` scaled it to party size by taking a **prefix**. Both of the things worth deciding about sat near the end of that list, so at party size 1 — the only way anybody currently plays — neither had ever spawned. Measured:

```
[loot] solo floor holds 4 item(s), 98 tribute total
[loot]   mat_bog_iron     @ -9,-6   (3 tribute)
[loot]   wpn_seax         @ -10,-14 (0 tribute)
[loot]   glt_raw_gemstone @ -2,-22  (55 tribute)
[loot]   glt_hoard_coin   @ 9,-8    (40 tribute)
[loot] a way out other than the Shaft: NO
[loot] anything in the Guardian's room: NO
```

**The Prize was index 5.** ADR-032 built the Guardian's room as the floor's greed decision — one entrance, no way out but back past the thing in it. Without the Prize that room is a dead end containing a monster, there is no reason to enter it, and the Gullsjúkr starts every run guarding nothing. The whole east half of the floor was a detour with no argument for taking it.

**The Waystone was index 8, last.** `DES-005` calls its rarity *"the strongest single lever in the game"* and ADR-015 built extraction as a resource problem on there being two ways out. At party size 1 that lever was not rare, it was **off** — deterministically, every run. The HUD went on listing `v waystone` and printing `waystone none`, which is a verb offered and never grantable: the same fault as the `r reset` the dead-player readout advertises (ADR-108).

So the two questions this floor exists to ask — *is the Prize worth the walk past the Guardian*, and *is a second way out worth two squares* — were both unaskable, and the `GATE M2 EXIT` playtest was about to be run on a floor with neither of them present.

### The decision — fixtures are not quantity

`LOOT` splits into **`FIXTURES`** (the Prize, the Waystone) and **`FILLER`** (the other seven). Fixtures are laid once at every party size, like the Shaft; only the filler is divided.

This does not touch `DES-012`'s relationship, which is the thing `M2-T07` is about, because that relationship is about the **divided** yield and these two were never meant to be divided. Counting them in the denominator was in fact the error: it shrank every party's share to pay for two items everybody was supposed to get regardless. Per-capita filler still falls at every step —

```
1 player   3 loot (3.00 each)      3 enemies   clamor x1.00
2 players  5 loot (2.50 each)      6 enemies   clamor x2.55
3 players  6 loot (2.00 each)      8 enemies   clamor x4.41
4 players  7 loot (1.75 each)     11 enemies   clamor x6.50
```

— and a four-player floor still holds nine items, exactly as before. What changed is solo: **4 items and 98 tribute became 5 and 198**, which makes the lone run richer relative to a full party rather than poorer, and that is `DES-012`'s sentence read correctly: *a solo run is lethal, quiet, and lucrative.*

**The filler prefix is left biased on purpose.** Solo's three filler items are now all on the west and junction routes, so the east corridor holds nothing but the fixtures. That reads as a defect and is the design: ADR-032 makes west the cheap bypass and east the guarded half, so a solo floor that pays 3 tribute for the safe walk and 195 for the guarded one is the risk gradient stated as a fact about a floor. Revisit it when `M4-T01` replaces hand placement with tables.

### The check that should have existed, and the one that did

**`--scaling-probe` now reads the built world.** Every claim it made was already true — the arithmetic was right the entire time this was broken, because the fault was in *which list* the arithmetic was applied to. A probe that counted rows would have passed. It walks the spawner's own group now and asserts both fixtures are on the floor, and it fails by name when the fixture spawn is removed.

**`--prize-probe` was already red and nothing was running it.** It teleports to the Prize, picks it up, and asserts that carrying the heaviest thing on the floor costs walk speed. With no Prize to lift it was reporting `walk speed 3.40 → 3.40 m/s (+0%)`, `carrying 0.0 kg (nothing)`, and **exiting 1** — and it was the only probe in `room_set.gd` that `check_scripts.sh` had never been wired to run. It runs now, and reports the number it was written for: `3.40 → 2.86 m/s (-16%)`, heard from `3.8 → 10.3 m`, carrying `14.0 kg`.

The gym's `--clamor-probe` and `--combat-probe` were orphaned the same way. Both pass today and both are wired in, because *a check nobody runs is a check that is already failing* and the only reason to find out which is to run it. `check_dead.py` structurally cannot see this class — the probe functions are referenced by their own scene's argument dispatch, so every name is alive and only the running is absent, which is the caveat that tool prints about itself (ADR-098).

**The shape again, and the tell is getting easier to name.** ADR-097 through ADR-108 are all *correct code that nothing reaches*. This one adds a variant worth keeping separate: **correct code reached only at a parameter nobody uses.** The loot scaling worked, and worked at every party size the probe examined, and the party size every real session runs at was the one where it deleted the content. Whenever a check sweeps a range, ask which end of the range the game actually sits at.

---

## ADR-111 — The bag had no rect, so nothing in it could be touched
**Date:** 2026-08-24 · **Status:** accepted · **Adds `M2-T18`** · **Extends ADR-106**

**Context:** A second play of the build returned three things: *"some text runs out of the UI box"*, *"I was unable to click or drag any of the items out"*, and *"the hunter comes at the player but then disappears and it's not obvious what they're doing or supposed to do to the player on contact."* Plus, still, no way out of the level except the Shaft. This ADR is the first two; the others are recorded below it because they are decisions rather than defects.

### The screen was 0 x 0 and drawing a 315 x 362 panel

`BagScreen._ready` called `set_anchors_preset(PRESET_FULL_RECT)`. That sets the anchors and leaves the offsets, and **nothing lays out a `Control` parented to a `CanvasLayer`** — so the control's rect stayed at zero while `_draw` went on painting a panel in the middle of the screen from `get_viewport_rect()`, which asks the viewport and not the control.

Godot delivers a mouse event to a control only when the point falls inside its rect. At zero size that is never, so **`_gui_input` had never once fired**: no picking an item up, no moving it, no turning it, and no dragging it out of the bag. That last one is `DES-005`'s primal counter-play — *drop it and go quiet* — and one of the four preconditions `ADR-109` just made `GATE M2 EXIT` out of: *they discover they can drop loot without being told.* On a mouse, they could not do it having been told.

Measured, and the plant is the proof: with `set_anchors_preset` the control is `0 x 0`, `covers view false`, `click reached _gui_input: false`. With `set_anchors_and_offsets_preset` it is the viewport, and the click arrives.

`Reticle` carries a comment about this exact trap — *"a `Control` under a `CanvasLayer` gets no laid-out size from anchors… the exact bug `Ear` was shipped with and photographed to find"* — and uses the right call. So does `SettingsScreen`, and so does `PauseMenu`. The bag was the one screen that did not, and it is the one screen whose entire purpose is being clicked on.

**The gamepad path worked the whole time**, which is why this survived a build being played: `_unhandled_input` needs no rect, so `interact` and `rotate_item` reached the bag normally. A screen that works on one device and is inert on the other is worse than one that is broken on both, because it reads as *the player doing it wrong*.

### The header was drawn at "do not clip"

`draw_string` takes a width; `-1` means unbounded. The header line — kilograms, cells, and the noise radius, which `DES-019` names as the three numbers the bag exists to let you do arithmetic on — was drawn at `-1` into a panel sized to the item grid and nothing else. Measured: **334 px of text in 233 px of box**, spilling out past the panel and over the world.

**The panel grows now, and the grid centres in it.** Clipping was the smaller change and the wrong one: the footer two lines below carries a note about exactly that mistake — *"a prompt that names both devices and then gets cut off names neither"* — and it was written after the same fault was found there. Sized against the **widest** numbers the header can ever hold rather than the ones on screen, so the panel does not breathe by a few pixels every time a coin goes in.

One place builds the header string now, so the width it is measured at and the width it is drawn at cannot drift, and `FOOTER_LINES` does the same for the prompts. `BagScreen.overflowing()` returns every line that does not fit its box, which is the layout stated as a property the screen can be asked about rather than as a number in a draw call.

### The check that should have existed

`--bag-probe` is thorough and it asks entirely about the **inventory**: what fits, what refuses, what dropping something buys back in speed and quiet. Every assertion passed throughout, because every one of them calls `Inventory` and `Player` directly and none of them goes near the screen. **Rules and reach are different questions**, and only the first had a check — which is ADR-106's sentence again, one layer further out: *every system had a probe proving it worked and nothing proved a person could operate it.*

`--bagui-probe` asks the second question, and deliberately only in the form that survives a headless run: the control covers the viewport, and a click inside it arrives. Headless pins the viewport to 64 x 64 whatever `--resolution` says, so the panel centres off-screen and no click could land on a *specific item* wherever the code stood — asserting that would have been asserting the harness. Both assertions fail by name when the old call is planted back, and the overflow assertion fails when the panel is sized to the grid again.

**A UI fault is not a lesser fault.** Nine ADRs in this project are about correct code nothing reaches; this one is about correct code the player cannot touch, and it had the same cause — a check that measured the system rather than the person.

---

## ADR-112 — The Hunt had no consequence, and every item description was invisible
**Date:** 2026-08-24 · **Status:** accepted · **Adds `M2-T19`** · **Amends `DES-017`, `DES-019`** · **Extends ADR-053**

**Context:** Two of the three things a second play returned. *"The hunter comes at the player but then disappears and it's not obvious what they're doing or supposed to do to the player on contact"*, and *"I still could not find out how to extract from the level besides the shaft"* — the second raised **after** ADR-110 put a Waystone on every solo floor.

### It walked up, stopped at 24 cm, and did nothing

Measured, standing still, carrying 180 tribute:

```
[hunter] + 1.2s state SIGHTED  0.29 m   hp 100   bag 180 tribute
[hunter] + 6.0s state SIGHTED  0.24 m   hp 100   bag 180 tribute
[hunter] after 14 s   health 100 → 100, bag 180 tribute
```

Fourteen seconds inside the player, nothing taken, nothing lost. The report was exactly right, and the "disappears" half is the *designed* behaviour showing through: it courses by the **clamor gradient** rather than by a player transform, so it arrives where the noise was and then wanders off after the next loud thing. That is `DES-017` working. It only reads as aimless because arriving was worth nothing.

**And the design does not say what arriving should be worth.** `DES-017`'s verb list is five ways to *avoid* it — bait it, delay it, confuse it, satisfy it, eventually kill it — and its state table ends at *"Sighted: it has you. Full mix. It does not lose interest quickly."* Nothing anywhere says what "has you" costs. This is a hole in an accepted document rather than an unimplemented paragraph, which is why it is decided here rather than fixed quietly.

### The decision — it takes gold, never health

**Reaching you costs the single richest thing you are carrying.** Not hit points. It cannot be killed at this Pact Rank (`M3-T04`), so a Gullsjúkr that dealt damage would be an unwinnable fight you could only run from — the numbers-treadmill `CLAUDE.md` lists as an anti-goal — and it would say nothing about the subject. What it wants is the hoard. `DES-002`'s decision therefore arrives as a consequence instead of a prompt: **the run's value, not your life.**

**The stoop is a telegraph and it obeys ADR-053's floor.** `hunter_take_seconds` is 0.9 s ⟨tune⟩ against a 250 ms human-reaction minimum, deliberately long because principle 3 makes this a decision rather than a reflex. Backing out of reach resets it. So does throwing it something cheaper: `_bait_worth_taking` is evaluated before this every frame, so a purse on the floor still wins its attention, and the counter-play the design already had now has something to counter.

**What it takes lands at its feet.** An item deleted out of a bag is indistinguishable from a bug, and `DES-018` wants the loss legible. Dropped, it is *disturbed* gold — so the Hunter's own bait logic picks it straight back up and stoops over it for the window a thrown purse buys, and in those seconds you can run in and take it back. That is the bait beat turned around: it made the decision for you, and you can still contest it. It costs nothing to build because both halves already existed.

Wired as a **signal**, not a call: `Gullsjukr.took` is emitted and `CoopSession` — which owns every spawn there is — decides what a thing on the floor is. Same shape as `Player.dropped`, two functions above it in the same file.

### Every item description in the game was invisible

The Waystone's authored text reads: *"Grey, unremarkable, and the only thing down here that is worth more than what you came for. **Spending it ends the run with whatever is in your hands.**"* That sentence answers the exact question the playtest asked. It has been in `en.csv` since `M2-T08`, it is validated on every sweep by `data_probe`, and `description_key` had **two references in the entire codebase — both inside the validator.** Nothing ever drew one.

So: authored, checked, shipped, and never rendered. `check_dead.py` cannot see this class, because the name is referenced by the thing that validates it; it is ADR-110's variant one step further along — content that exists, is correct, and reaches nobody.

**The bag draws it now**, under the grid, for whatever the cursor is over. On the inventory screen rather than the reticle because `DES-019` rule 2 bans text in the middle of the screen during a run and names exactly one exception: *"the inventory screen, where you are deliberately doing arithmetic."* Wrapped rather than clipped, for the reason the footer has carried a note about since ADR-111.

### The checks

`--toll-probe` asserts the four things that make this a decision rather than a damage source: reaching you takes the richest item, health is untouched, out of reach takes nothing however long you wait, and what it takes is on the floor afterwards. All four fail by name when planted — never taking, taking from any distance, and deleting what it takes each produce their own message.

`--bagui-probe` already asserts that no line the bag draws falls outside its panel, so the new band is covered by the check ADR-111 added rather than needing one of its own.

**The pattern this makes explicit.** `--hunt-probe` asserts everything about how the Gullsjúkr *finds* you — wealth through walls, the clamor gradient, bait proportionality — and nothing about what happens next, because there was nothing. A check cannot notice a missing consequence; it can only fail an existing one. **The absent behaviour is invisible to every tool in this project and visible in ten seconds to a person holding the controller** — which is the argument for the `GATE M2 EXIT` playtest that ADR-109 made answerable, and the reason it is worth running before `M3` rather than after.

---

## ADR-113 — Extracting in company had never once worked
**Date:** 2026-08-24 · **Status:** accepted · **Adds `M2-T20`** · **Fixes a fault introduced in `M2-T12`, made loud by `M2-T16`**

**Context:** The first three-player session on the Windows build. *"We had a three man team and got the waystone but when I used it the game crashed and everyone else got kicked."*

Reproduced on the first attempt, and it is not three-player-specific — it reproduces at **two**:

```
[live] host spends the waystone with 2 bodies on the floor
[exit] descent 1 — player_1 left with 9.5 kg, 40 tribute: Hoard-Coin
SCRIPT ERROR: Cannot call method 'get_peers' on a null value.
   [0] _end_the_run   (res://levels/room_set/room_set.gd:2725)
   [1] _on_extracted  (res://levels/room_set/room_set.gd:2797)
   [2] _tick_waystone (res://actors/player/player.gd:1087)
```

### `change_scene_to_file` detaches the outgoing scene synchronously

`_end_the_run` walks `_session.players()` and hands each body its outcome — the host's directly, everybody else's by `rpc_id`. The host is index 0, so the host's own outcome was always taken **first**, and taking it runs `change_scene_to_file`. Only the *new* scene's instantiation is deferred; the old one leaves the tree immediately. Measured either side of the call:

```
[diag] before host outcome: in_tree=true
[diag] after  host outcome: in_tree=false
```

From that line on, every remaining iteration ran on a detached node. `Node.multiplayer` is `null` outside the tree, so the peer guard added in `M2-T16` threw, and the loop died before a single client had been told anything.

**The clients were never being told anyway.** Planting the pre-`M2-T16` form — a bare `rpc_id` with no guard — gives the same detachment with a quieter symptom:

```
host:   ERROR: Condition "!is_inside_tree()" is true. Returning: ERR_UNCONFIGURED
client: ERROR: Node not found: "Threshold/CoopSession/Spawner"   (never received an outcome)
```

So **co-op extraction has never worked**, since ADR-102 wrote `_end_the_run` in this shape at `M2-T12`. The client stayed in a Deep the host had walked out of, receiving spawn packets addressed to a scene it was not in, until the connection dropped and it gave up — *"everyone else got kicked"*. `M2-T16`'s guard did not cause this; it converted a silent `ERR_UNCONFIGURED` into a hard `SCRIPT ERROR` on the same line, which is the only reason it was ever reported. **Louder is better, and this is the argument for the guard rather than against it.**

**The decision:** everybody else first, the host last. One held haul and two extra locals, and the function no longer saws off the branch it is standing on.

### Why nothing caught it, and this one is the sharpest instance yet

Three checks cover co-op transitions and **none of them extracts**:

- `run_coop.py` never changes scene at all.
- `run_doorway.py` walks the Descent and a Chamber — the two doors going *in*.
- `--exit-probe` is the one check that spends a Waystone, and it is **solo** *and* it sets `_probing`, which swaps `change_scene_to_file` for `_reset_floor`. It deliberately skips the exact line that was broken, for the good reason that a probe measuring a floor must not be dropped out of it.

So the single most important transition in the game — the party leaving together, which `DES-002` calls the point of the loop — was the one transition nothing walked. Every ADR from ADR-097 onward is a variant of *correct code nothing reaches*; this is the variant where **the check that came closest had to disable the broken behaviour in order to run at all.**

### The check

`run_doorway.py` grows a third scenario: a host and **two** clients in the Deep, the host spends a Waystone, and every process is asserted to arrive at the Threshold with a body and without throwing. Three players because that is the size it was reported at, though it fails at two.

The arrival is reported from **`Threshold`**, not from the Deep, and that is the part worth remembering: a coroutine waiting in `room_set` when the run ends dies with the scene, so the process that most needs to say where it ended up is the least able to. The first draft reported from the Deep and printed nothing at all from any client — a check that looked like a total failure and was only a badly placed observer.

The flag is `--extraction`, deliberately without the word "probe" in it, because `_probing` is keyed on that substring and would have re-disabled the transition under test. **A check for a scene change has to be allowed to change scene.**

Planted, the check fails exactly as the playtest did: `host  SCRIPT ERROR`, `client0  STRANDED in the Deep`.

---

## ADR-114 — Nothing on the floor knew what a fallen player was
**Date:** 2026-08-25 · **Status:** accepted · **Adds `M2-T21`** · **Amends `DES-013`, `DES-017`** · **Completes a `DES-012` sentence**

**Context:** From play — *"when a player dies and goes to a ghost form, the enemies are still pathing and trying to attack them."*

There is no ghost form. The word is `DES-012`'s own, for the Vörðr state it deliberately has not built: *"a fallen player's body stays where it fell rather than becoming a ghost with nothing to do."* What was seen is `spent` — the body frozen at 0.00 m/s, camera still live, the world carrying on around it. From the seat that is exactly what being a ghost would feel like, which is worth noting: the description was accurate about the *experience* and the vocabulary arrived on its own.

### An enemy over a body is doing nothing, loudly

`Enemy._nearest_visible_player` walked the `"player"` group with no filter, and `_act`'s ALERTED branch attacked whatever `_target` held. A downed or spent body was a normal target — seen, chased and swung at indefinitely.

It achieved **nothing**. `Health.apply_damage` returns at its first line once `_dead`, so there was no damage, no `damaged` signal and not even a Foley cue. Animation with nothing behind it. And because acquisition is *nearest visible*, a body on the floor actively pulled enemies off a standing teammate to swing at the one thing in the room that could not be hurt.

**The fallen stop being targets, and the enemy searches the spot instead.** One predicate, `_worth_fighting`, used both where targets are acquired and where the ALERTED branch decides what to do — filtering acquisition alone is not enough, because `_target` keeps its reference and goes on swinging for the rest of `enemy_patience`.

It drops to `SUSPICIOUS`, which already steers to `_last_seen` — and `_last_seen` is where the body is lying. So the enemy loiters over the fallen without attacking, and **a rescuer walks into a live, alert enemy**, which is precisely the *"time, exposure, noise"* `DES-012` charges for a revive. Going down is not a free reset for a losing fight either: it is still standing over you. No new state, no new tuning value — `DES-013`'s ladder already had the right shape and nothing was consulting it.

### And the Gullsjúkr never stopped for an ember

Found while checking the above. `DES-012` says, in as many words:

> *"it is disturbed gold by ADR-089's rule, so **the Gullsjúkr will stop for it**: the thing that would buy you seconds is your friend."*

False in the build, and not marginally. `con_ember.tres` carries `tribute_value = 0`; `_bait_worth_taking` requires at least `hunter_wealth_floor`, which is 20. **The one object that sentence is about was the one object that could never qualify as bait.** The best moment the co-op design has was unreachable.

**An ember is exempted from the value test rather than given a value.** It is not tribute — she will not buy it back, and a number on that resource would make somebody's life bankable. It is what gold is *for*, which is the reason this thing wants it more than gold. It also has to *outrank* gold to be chosen at all: worth 0, it would have passed the exemption and then lost every comparison, including the zero the search starts at. `EMBER_WORTH` is a priority, and is documented as one.

**And it cannot destroy one.** Collecting ends in `queue_free`, so an ember treated like gold would be **deleted on a 4.5 s timer** — a teammate's LIFE gone to an AI clock, with no counter-play once it started, which is the unexplainable loss `PRO-005` forbids. `DES-012` says the Hunter *stops* for it; stopping is the whole of it. It stoops, gets nothing — her fire is not a payment and no Tithe was ever settled with one — and leaves.

Clearing `disturbed` is what keeps that from looping: the ember drops out of `_bait_worth_taking` by the rule that already exists, stays on the floor for whoever is coming, and the Hunter has had its look. **One stoop, one window** — which is exactly the seconds `DES-012` says an ember buys. A player who picks it up and sets it down re-disturbs it and pays the pickup for a second window.

### The check, and two things it taught before it worked

`--fallen-probe` asserts all four: the enemy notices a standing player, loses them when they go down, does **not** go home, and the Gullsjúkr stoops over an ember and leaves it intact. Each fails by name when planted.

**It lives in the Deep because the gym deletes the thing under test.** The first draft was in `--combat-probe`, which is where enemy behaviour belongs — and `movement_gym` calls `_reset()` from `health.died`, so downing a player there frees and respawns every enemy in the level. It died on `previously freed`, one line after the enemy it was asserting about had been recycled. A venue that reacts to the event under test is not a venue.

**And the first two runs reported `UNAWARE` at an enemy that genuinely could not see.** Placing the enemy relative to the player put it through a wall, and a yaw of `PI` turned the second attempt to face away — Godot's forward is -Z. It is placed by its own `facing()` now. Both were the probe being wrong in a way that looked exactly like the product being right, which is the failure mode `--edges-probe` was written about and it does not stop being easy.

One smaller thing, recorded because it nearly shipped: two of the failure messages were built as `"…" + "…%d…" + "…" % value`. `%` binds tighter than `+`, so the format applied to the last fragment only and the specifier printed literally. Caught by reading the planted output rather than by the plant passing or failing — **a check that fails for the right reason can still be unreadable**, and the message is the entire value of a failing check.

---

## ADR-115 — The M2 gates close on our own play, and the stranger session moves to M3
**Date:** 2026-08-25 · **Status:** accepted · **Passes `GATE M2 EXIT`, `GATE M2 COOP`** · **Amends `PRO-001` (M3 gate protocols)**

**Context:** M2 is 21/21. The last five tasks did not come from the sweep, from an audit, or from a probe. Every one of them came from one person playing the build and saying what happened.

`GATE M2 EXIT` as ADR-109 wrote it is three testers × three runs, no coaching, overlay off, four questions. **That protocol has not been run.** What has been run is a handful of solo runs and one three-player remote session, and it found more than the protocol was written to find:

| The four EXIT questions | What actually happened |
|---|---|
| reaches the Shaft having entered ≤4 of 6 rooms | reached it — and *"I still could not find out how to extract from the level besides the shaft"*, because **the Waystone had never spawned in a solo run** (ADR-110) |
| answers roughly right about their own noise | not asked |
| explains a death in one sentence | *"the hunter comes at the player but then disappears and it's not obvious what they're doing"* — **the Hunt had no consequence at all** (ADR-112) |
| discovers they can drop loot without being told | **could not touch the bag at all.** `_gui_input` had never once fired (ADR-111) |

Three of the four were failed by the person who designed the thing, which is the strongest possible form of that result: **if the author cannot operate his own inventory, no protocol is needed to establish that a stranger cannot.** The gate's stated job is to localise a failure, and it localised four — each now closed with a probe that fails by name.

### Why not simply run it

Because a first-time player is not a renewable resource. Each person is a first-time player exactly once, and asking *"how much noise are you making?"* on this build asks it of six grey rooms, one enemy archetype, no classes, no Tithe and no ranks. ADR-109 was right that the four questions are **answerable** at blockout — it is right still, and they were answered above. Answerable is not the same as worth spending three strangers on. Spending them here buys a second copy of a finding we already have and burns the measurement `GATE M4 GREED` needs most.

### `GATE M2 COOP` was not failed — it was unreachable

*"Someone carries a friend's ember out and it is the best moment of the session"* could not have happened in **any** session before today. Until ADR-114 the Gullsjúkr had never stopped for an ember, though `DES-012` says in as many words that it does, and enemies never let go of a downed body; until ADR-113 extracting in company **crashed the host and kicked everyone**. A gate cannot be failed by a session that was never able to reach it.

What the three-player session did establish is the layer underneath: three people on real connections, remote, found the Waystone and used it, and the run resolved for all of them. That is `M2-T12`'s five-fault list and `M2-T20`'s crash, both closed and both only findable that way.

### What carries forward — copied, not waived

- **The four EXIT questions are appended verbatim to `GATE M3 EXIT`'s protocol.** That session is already a playtest with people who are not us, and by then there are classes, a Tithe and ranks to be strange about.
- **The three COOP preconditions move to `GATE M3 COOP`** — the same mixed-rank session with a newcomer who is downed repeatedly. The third of them, *"the downed player can tell what is happening to them"*, is `M3-T09`'s Vörðr, which is where that readout gets built. Asking it before it exists was always going to return the same answer.

### The risk we are accepting, stated so it cannot arrive as a surprise

**M2 closes without a person who has never seen the game operating it.** If the M3 session then fails on wayfinding or on bag discoverability, that finding will be months old and buried under save migration, classes, ranks and equipment — and the fix will be harder for every system stacked on top of it in between. That is the price. It is the reason the four questions are copied forward rather than deleted, and the reason they are the *first* thing asked in that session rather than the last.

---

## ADR-116 — M3 made coherent: a tenth task, one swap, and a save that grows a version at a time
**Date:** 2026-08-25 · **Status:** accepted · **Adds `M3-T10`** · **Reorders `M3`** · **Amends `M3-T06`, `M3-T09`, `TEC-003` sequencing**

**Context:** M2 cleared, M3 is next, and the milestone had never been read end-to-end against the decisions it implements. Reading it that way found three things, one of which would have stopped a gate from being runnable at all.

### 1. `GATE M3 COOP` names a system nothing on the roadmap builds

The gate says, in its own sentence: *"a rank-8 player brings a rank-1 friend into a **rank-8 floor** (ADR-010)."*

ADR-010 is accepted — *"scale to the highest rank present"* — and ADR-011 (`M3-T03`) exists **only** to protect the coupling ADR-010 creates. But no task in `M3`, `M4` or `M5` builds rank-scaled floors. `M4-T01` scales by *depth*, `M2-T07` scales by *party size*, and `M5-T06` is a balance pass. **There is no rank-8 floor, at any milestone, and the gate that names one is two milestones away from noticing.**

This is the shape ADR-097, ADR-105 and ADR-110 all had, one level up: not correct code nothing reaches, but **an accepted decision with no task behind it, guarded by a second task written to protect it.** `M3-T03` reads *"must exist before mixed-rank parties are tested"* — and mixed-rank parties were not testable, because a floor had no rank.

Nothing in the tooling can see this. `status.py --check` reads sequencing and doc integrity; it does not ask whether every accepted ADR has an implementing task, and there is no obvious way to make it — an ADR is prose. **`M3-T10`** is the fix for this instance.

It is not scope creep. It was always in scope, named in a gate, and simply unwritten.

**`PartyScaling` is the seam and the shape.** Three static functions keyed on one axis; rank is a second axis on the same three quantities. At `M3` that honestly means *more of them, harder, and richer* — enemy **variety** by rank is `M4-T02` and `M5-T04`, and pretending a rank-8 floor has a rank-8 bestiary here would be the stub ADR-064 bans.

### 2. The Aspect tree was scheduled before the thing that gates it

ADR-009: **"access to 3 of the 5 Aspects"**, decided by your class. `M3-T01` built the tree third; `M3-T02` built the classes fifth. **A tree built before any class exists is a tree with its gating rule missing** — and the rule would then be retrofitted onto a shipped tree rather than built into it, which is the same mistake ADR-109 moved the save system to avoid.

`M3-T02` moves ahead of `M3-T01`. One swap, on a dependency that has been written down since 2026-08-12.

Two more things fall out of reading ADR-009 properly. *"Death becomes the door to a new class"* — so `M3-T02`'s class select and `M3-T05`'s Legacy screen are **one flow**, not two screens: death → what you learned → Legacy slots → the class of the next life. And *"Rite nodes may occupy a Legacy slot but only apply if the next life repeats that class"* couples them again, in the payload. They are written as one flow now.

**And there is no class-select screen.** `M3-T02`'s text said *"the other four are absent from the class-select screen entirely"*, which reads as though the screen exists and four entries are missing from it. `game/ui/` has eleven scripts and none of them is that screen. The task builds it.

### 3. The save grows one version per task

Approved as proposed. `TEC-003` draws a schema with `pact_rank`, `tithe_state`, `boon`, `skill_tree`, `scars`, `bestiary`, `cartography`, `legacy_slots_unlocked` — **none of which exist.** Writing them now as empty fields is exactly the stub ADR-064 bans: present, empty, and lying about what the game does.

**So `M3-T06` ships the machinery complete and the schema only as wide as the state that exists** — which is what `GameState` already holds: `hoard` and `hoard_value` (LINEAGE), `stash` (LIFE), `descents`, plus `meta`. The three sections are structure rather than stubs, because the tier split is *already* how `die()` works: clear LIFE, keep LINEAGE, one function. An empty `legacy.slots` is honest — there are zero Legacy slots. `pact_rank: 1` would not be.

**Every task after it that adds persistent state ships `SAVE_VERSION + 1`, its migration, and a fixture of the format it replaces.** By `GATE M3 EXIT` the migration path will have run for real seven times against saves that genuinely existed — which is a strictly stronger claim than one speculative v1 nobody ever migrates from, and it is the better argument for save-first than the one ADR-109 gave.

### 4. `user://run.active` moves to `M3-T09`

`TEC-003` specifies a separate mid-run file and ADR-050's suspend-with-forced-resume. Built at `M3-T06`, it would be built against a run structure `M3-T09` is about to change — and ADR-050's own sentence, *"dropping out of a co-op run leaves you a **Vörðr**"*, has no referent until the Vörðr exists. The file and the state it describes are one piece of work. `M3-T06` ships `profile.save` only.

### 5. And two tasks both said "save/load"

`M4-T06` read *"Full save/load, settings, controls rebinding"* — written before ADR-109 moved the save system out of `M4` and into `M3-T06`. Left as it stood, two tasks two milestones apart both claimed the same deliverable, which is how one of them gets built twice or neither gets built at all.

It is narrowed to **the part a player touches**: profile management, and what a build does with a save from a newer build than itself. Not the boot load — `M3-T06` reads the profile when a session starts, or the save it writes would be write-only, which is the ADR-098 failure this project has already had once. The format, the versioning, the migrations and the write policy are `M3-T06` and grow a version per task from there.

`game/systems/settings.gd` also still points at `M4-T06` for the versioned save; `M3-T06` corrects it. `Settings` itself stays exactly where it is — its header is right that preferences are a different file with different rules, *"and conflating them is how settings end up wiped by a save migration."*

### 6. Two things this pass itself got wrong, found by reading for `M3-T04`

**`M3-T10` cited the wrong doc.** It named `DES-003`, `DES-012` and `DES-015`; the specification is **`DES-022`**, which answers *"so what does a rank-9 floor mean?"* in a six-row table and sets the rule the whole thing turns on — *fixed stats per archetype, difficulty by composition and pressure, never bigger numbers.* Three of its six axes — **Density, the Hunt, Time** — are buildable at `M3`. The other three need archetypes, the modifier set and module generation that belong to `M4-T01`, `M4-T02` and `M5-T04`. Naming which three is the difference between a scoped task and one that either overreaches or quietly stubs half of itself.

**And `M3-T04` builds a rank that cannot rise.** `DES-022` raises Pact Rank by spending Boon on nodes — *"a player reaching Rank 9 takes roughly 20"* — and that is `M3-T01`, three tasks later. So a life sits at rank 1 until then, and both the Gullsjúkr's killable threshold and ADR-029's reclaimed-node soft-fail are numbers no build can reach yet.

That is the right way round and it is worth saying why, because it looks exactly like the ordering fault §2 just fixed and is its opposite. `DES-003`'s argument is that persistence *always* trivialises unless power is coupled to obligation. Building the obligation after the power ships Failure Mode A deliberately for three tasks. The rank is real, static, and honest — the same shape as the hoard, which has grown since `M2-T06` and buys nothing until `M3-T01`.

### The resulting order

`T06` → `T04` → **`T10`** → `T02` → `T01` → `T03` → `T05` → `T08` → `T07` → `T09`

`T10` sits directly after `T04` deliberately: rank raising your Tithe **and** raising the floor is one coupling, `DES-003`'s Pillar-P3 claim that *"power pulls you deeper"*, and splitting it across the milestone means neither half can be felt on its own.

---

## ADR-117 — The profile has a file, and the checks that proved it were wrong twice
**Date:** 2026-08-25 · **Status:** accepted · **Closes `M3-T06`** · **Implements `TEC-003`** · **Amends `M4-T06`**

**Context:** `GameState` held the hoard, the stash and the tribute total in memory and lost all of it on quit. Its own header said so, and said it would acquire a file *"when the file has a migration path."* This is that.

### v1 carries what exists, and nothing else (ADR-116)

```
user://profile.save
├── meta     { save_version, engine, created, updated }
├── lineage  { hoard, hoard_value }      ← survives death, always
└── life     { stash }                   ← wiped by death (DES-008)
```

`TEC-003` draws `pact_rank`, `tithe_state`, `boon`, `skill_tree`, `scars`, `bestiary`, `cartography` and `legacy_slots_unlocked` alongside those. **None exist**, and writing them as empty fields is the stub ADR-064 bans. `legacy` is **absent rather than empty** for the same reason — there are no Legacy slots until `M3-T05`, and a section for a system that does not exist is a stub wearing structure's clothes. `descents` is left out too: its own name is *"this session"*, and `TEC-003`'s LIFE-tier `run_count` is a different number that counts against a Tithe cycle, which is `M3-T04`.

The two sections that are here earn it: `die()` was **already** written as `TEC-003`'s one-function operation — clear LIFE, keep LINEAGE — so the split is the shape death already had, not a shape imposed on it.

**The stash saves ids only.** `_carry_the_stash_down()` re-mints a fresh `ItemInstance` from the definition and discards the stashed one, so a cell, a rotation and an instance id would all be written and thrown away on load. The moment anything persists a *placed* item — a bag across a suspend — those come with it, and that is `M3-T09`.

### Not an autoload, and nothing is written back to a file that was never read

`TEC-001` names `SaveSystem` in its budget of six. It is a `class_name` with static state instead, for the reason `Settings` gives three files over: an autoload is for something with a node's life, and this has none. `GameState` is the autoload, owns the state, and is the only caller. A second autoload whose whole body is *"hand this dict to a file"* is a habit rather than a budget (ADR-066).

`GameState._live` is false until `load_profile()` succeeds, and `MainMenu._enter()` is the only caller — the moment a session starts, which is the only path into the game. Everything follows from that one rule:

- A probe booting a level directly mutates state in memory and **cannot touch a player's profile.** No probe-awareness in production code, and no profile inherited from whatever the previous probe wrote.
- A build that **refused** a profile cannot overwrite it, because refusing leaves it not-live.
- Loading at boot would have done the opposite of both.

### The check was green and wrong, twice, and only planting showed it

**A corrupt profile was being destroyed.** `load_profile` asked `read_raw().is_empty()` whether a profile existed — and `read_raw` returns `{}` both for *no file* and for *a file that is not a save*. So an unreadable profile read as **no profile**, went live, and was overwritten by the next tribute. The protection built for a save from a newer build did not cover the case it was most needed in.

The probe was green throughout, because it asserted that garbage does not **load** — true — and never that garbage **survives**. ADR-113's shape exactly: an assertion that is correct and beside the point. *Is there a profile* is a filesystem question, and it asks the filesystem now.

**And the missing-migration guard was decorative.** Deleting it changed nothing observable: GDScript's own missing-key access aborts the function and hands back an empty dictionary anyway, so refusing and crashing were indistinguishable from outside and the check proved nothing about itself. It checks the **whole route before the first step** now — which is also better behaviour, because refusing part-way leaves the caller holding a profile half-way between two formats. A gap runs **zero** migrations instead of some, and *that* is observable: the probe asserts no step ran.

One smaller thing in the same family: the probe's synthetic migrations originally **mutated** the dictionary they were handed. A Dictionary is a reference in GDScript, so `walk()` throwing away its steps' return values still appeared to work. They build a new dictionary now, because a migration is a function from one shape to another and testing it as one is the only way the wiring is proved.

### `MIGRATIONS` is empty, and that is not the same as unbuilt

There is no format older than v1, so the table has nothing in it while `walk()` runs on every load. An algorithm proved only by the data it currently has is ADR-097 waiting to happen — so `walk()` takes its table as an argument, and `--save-probe` drives it with a synthetic two-step one. The algorithm is exercised; the table fills from `M3-T04` onward, one version per task.

`--save-probe` asserts nine things and **every one of them was planted and seen to fail by name**, which is how both faults above were found. It is the one probe in the sweep whose block does not treat `^ERROR:` as failure: driving the paths that push errors is its job.

### And one line that nothing reached

`MainMenu._enter()` is the only thing in the build that opens a profile, and `run_coop.py` boots the Deep directly — so every *piece* of this task had a check and the **composition** had none. That is the shape ADR-105, ADR-108 and ADR-110 all had, and it is the one this project keeps paying for. `--menu-probe` presses Descend now and asserts a profile opened; planted, it reports `saving=false` and fails by name.

Adding it broke the probe on the first attempt, in a way worth keeping: pressing Descend calls `change_scene_to_file`, which **detaches the outgoing scene synchronously** — so by the time the probe printed its report, `get_tree()` on the menu was null and the run died on `Cannot call method 'quit' on a null value`. The `SceneTree` outlives the node; the node's path to it does not. It is held in a local before the walk now. The same synchronous-detach behaviour was what ADR-113 turned on, three tasks ago, from the other direction.

### `M4-T06`, once more

ADR-116 narrowed it to *"the load path at boot, profile management, …"*. The boot load is here — a save nothing reads is the write-only stash ADR-098 already caught this project building once. `M4-T06` keeps profile management and what a build tells a player about a save it cannot read.

---

## ADR-118 — She is a creditor, and missing her costs a head start
**Date:** 2026-08-25 · **Status:** accepted · **Closes `M3-T04`** · **Amends ADR-029** · **Implements `DES-003`, `DES-017`**

**Context:** `DES-003`'s central claim is that *"persistence alone always trivializes, so power must be coupled to obligation."* The obligation had never been built. `M3-T04` builds it — and ADR-029, which decided the shape, names three consequences for missing a cycle that **all belong to systems that do not exist**: standing is `M4-T04`, node reclamation is `M3-T01`, and there is no status-effect system at all. The soft fail had to be decided, not looked up.

### Missing a cycle starts the Hunt early

**The next descent begins with the Gullsjúkr already `tithe_missed_head_start` seconds old** ⟨tune⟩, so `_wealth_range` opens wider from the first second.

It is the only one of ADR-029's consequences that could be built out of what exists, and it is better than the ones that could not:

- **Nothing new is added to the game.** It is the Hunter's own escalation, started partway along. A player who has met a Gullsjúkr already knows what it means, so there is no rule to learn and no icon to read.
- **`DES-022` already lists it as the rank axis** — *"the Hunt: arrives sooner, escalates faster"* — so a missed Tithe pushes the floor in the same direction rank does. The punishment and the progression speak one language.
- **She sends something rather than taking something.** The alternative considered was reclaiming tribute from the hoard, and it is wrong: `DES-014` makes the pile the one thing with zero balance impact, *"a permanent physical monument to every life you have lost."* Taking from it spends the monument to buy a penalty.
- **It is explicable in one sentence** (principle 4): *"I missed my Tithe, so it found me early."*

**And the slate clears.** Unpaid value does not carry. ADR-029's runner-up was running-debt-with-interest, which it called more elegant and rejected on complexity rather than merit — but that version self-stabilised through node reclamation (fall behind → she takes a node → your Tithe drops → you can pay again), and node reclamation is `M3-T01`. Carrying debt *here* would be the spiral with the floor taken out of it. Missing twice costs twice and never compounds, which is what makes ADR-029's *"absorbs one disaster run"* true rather than aspirational.

### What is real, and what cannot move yet

`pact_rank`, `tithe_paid`, `cycle_runs` and `hunt_head_start` are LIFE tier and `die()` puts every one of them back — including the head start, because **a debt outliving the debtor is the running-debt model arriving through the one door nobody was watching.**

Rank cannot rise: `DES-022` raises it by spending Boon on nodes, which is `M3-T01` (ADR-116 §6). So the Tithe is live at rank 1 and the curve above it is exercised only by the probe. That is the right order — building the obligation *after* the power ships `DES-003`'s Failure Mode A on purpose for three tasks — and it is the same shape as the hoard, which has grown since `M2-T06` and buys nothing yet.

**The curve is a table, not an equation.** `DES-003` gives three anchors — 40, 260, 900 — and everything between them is a designer's judgement. `validate()` refuses a table that ever falls, because a rank that is cheaper to hold than the one below it runs `DES-003`'s coupling backwards from there on, and that is a boot-time question rather than a balance-session one.

### The Gullsjúkr answers a swing now

`DES-017` says *"at high Pact Rank it becomes killable"*, and `M2-T02` left that absent because there was no rank to compare against. `killable()` compares now, on the real path, on every blow — and returns `false` in every build that exists, which is **not** the same as being unwritten.

Building it surfaced something worse. It had **no `Hurtbox` at all**, so a swing passed straight through and produced *nothing*: no contact, no cue, no refusal. A player will certainly try to fight it, and a game that answers by doing nothing reads as a broken hitbox rather than as a rule. It has one now, and a refused blow lands visibly — the tint jumps and settles. Visible rather than audible because its audio is `M2-T03`'s reserved instrument and absent by design.

What is still absent is the *fight*: health, the hoard it drops, the deed. Those arrive with `M3-T01`, when reaching the rank becomes possible and a playtester could be shown something other than a health bar that never empties.

### The check, and the case that could not fail

`--tithe-probe` asserts eight things, all planted. `--toll-probe` gained a ninth: the player's **real** `Hitbox`, at its real layers, has to find that new hurtbox — a handler proved by calling it directly proves only that it was called.

The first draft had a case that could not fail. `glt_hoard_coin` is worth 40 and the rank-1 Tithe is 40, so *"pay one coin, close the cycle, assert it came up short"* came up settled. The probe was wrong rather than the code, and it took the failure to see it: an assertion that cannot fail is one more that is true and beside the point, which is ADR-113 again. The short case runs at rank 5 now.

Worth recording on the way past: **one Hoard-Coin discharges an entire rank-1 cycle.** Both numbers are ⟨tune⟩ and the collision is coincidence, but a first cycle paid off by a single pickup is a real balance question — and it belongs to `M3-T10`, which is the first task with a floor rich enough to answer it.

---

## ADR-119 — A rank-8 floor exists, and two of its three axes are one lever
**Date:** 2026-08-25 · **Status:** accepted · **Closes `M3-T10`** · **Implements ADR-010, `DES-022`** · **Amends `TEC-004`**

**Context:** ADR-116 §1 found that `GATE M3 COOP` names *"a rank-8 floor (ADR-010)"* and nothing on the roadmap built one. `M3-T10` builds it. Two things came out of doing so that the task text had wrong.

### One integer crosses the wire, and only one

ADR-010 scales a floor to the **highest** Pact Rank present. `TEC-004`'s progression row says *"Progression (Boon, tree, Tithe) — **never networked**"*, and the line under it calls that *"the important one… a large, permanent reduction in complexity… **worth protecting if the design is revisited**."*

The host cannot know a client's rank. That is a genuine conflict between two accepted decisions, and `M3-T10` cannot be built without resolving it. **The cohesion pass missed it because it checked whether a task existed for ADR-010, not whether the task was possible.**

**Each peer declares one integer at descent; the host takes the max.** No tree, no Boon, no stash, no Tithe ledger. The host never stores it in a profile and never writes another player's anything — it builds a floor and is discarded with it, exactly like party size, which has always crossed. `TEC-004`'s row names the meta-layer *state*, and the state is what buys the complexity reduction; a floor-generation parameter is a different kind of value.

The alternatives were worse. **The host's own rank** needs no wire change and hands a rank-1 host with a rank-8 friend a rank-1 floor — wasting the veteran's session and breaking their Tithe math, which is precisely what ADR-010 refused when it chose highest over average. It also makes *who clicked host* a balance decision.

**And it has to be declared on every session, not on every connect.** `_ranks` lives on the `CoopSession`, and a session is per scene — so the Deep, built the instant the doorway resolves, starts with an empty table unless every peer declares again when it adopts the live connection. Walking through a doorway is the only way a real party ever reaches a floor, so a declaration made solely at connect is one the floor never sees.

### Density and the Hunt — and the Hunt is also Time

`DES-022` lists six axes. Three need content that does not exist (`M4-T01`, `M4-T02`, `M5-T04`) and ADR-116 §6 scoped them out. The task text then said the remaining three — **Density, the Hunt, Time** — were three things to build. They are **two**.

`Shaft._escalation` reads the Gullsjúkr's `age` rather than a clock of its own, and its comment says why: *"the pressure the player feels and the price of leaving have to come from the same source, or the Sealing is a timer wearing the Hunt's clothes."*

So a floor whose Hunt starts older **seals its Shafts sooner for free.** `rank_hunt_seconds` delivers *"the Hunt arrives sooner"* and *"cheap exits vanish sooner"* from one number, with no second system and nothing to drift out of step. That is not a coincidence — it is `M2-T04`'s architecture paying out — and it is the correct amount of work rather than a shortcut.

It also composes with `M3-T04`: a rank-8 floor you owe her on is both, and both are time.

### The tuning value the probe rejected on sight

The first `rank_hunt_seconds` was 45 s. At rank 8 that is 315 s against a 300 s seal, so **the floor opened with its Shafts already past maximum**.

Not locked — `_escalation` clamps at 1.0, and ADR-053's note that a locked Shaft is a trap still holds. **Flat**, which is worse in a quieter way: leaving early and leaving late cost the same, so `DES-005`'s leave-now-or-later decision stops existing *exactly where the game is supposed to be hardest*. Principle 1 says the run is the product, and a tuning value had deleted the run's central decision at the top of the tree.

20 s: rank 9 opens at 53 % sealed with 47 % of the climb left. **The invariant is an assertion now, not a note**, so it cannot drift back.

### The check

`--rank-probe` asserts six things, all planted: density rises with rank, rank and party still multiply, the Hunt starts older, the Shafts are correspondingly closer to sealed, the top of the tree still has a climb left, and **every enemy on the floor shares one stat line.**

The last is the one nothing else watches and the one this design would lose first. `DES-022`'s rule is *"more things, worse things, and less time — not because a skeleton hits for 40 instead of 12"*, and enemy health quietly acquiring a rank multiplier is the trivialisation treadmill `CLAUDE.md` names as an anti-goal. Planted by giving one enemy ten more hit points; it fails by name.

---

## ADR-120 — "Two classes complete" was three systems in one checkbox
**Date:** 2026-08-25 · **Status:** accepted · **Splits `M3-T02`, adds `M3-T11`** · **Scopes `DES-011`**

**Context:** `M3-T02` read *"Two classes complete — Húskarl and Veiðimaðr, opposite loop relationships."* One line, one checkbox. Read against what is actually built, it contains:

| | |
|---|---|
| **A class-select screen** | `game/ui/` has eleven scripts and none is it (ADR-116 §2 found this already) |
| **Blocking** | the Húskarl's *Hold* needs a shield. `WieldableTrait` carries windup, active, recovery, damage, reach — **no notion of stopping a blow** |
| **Ranged combat** | the Veiðimaðr's bow. Every weapon in the game is melee with a `reach` |
| **Placeable traps** | *Snare* — hold, wound, or misdirect, *"including against the Hunter"* — an entity with three behaviours and its own interaction with the Hunt |

That is three new systems and a screen. `PRO-007` §3 calls scope *"the most honest number in this document"*, and a task whose true size is invisible from its own text is how that number stops being honest.

**Split.** `M3-T02` takes the screen and the Húskarl; **`M3-T11`** takes the Veiðimaðr. Each is one class and one or two new systems, each ships playable on its own, and the second one's cost is now visible on the board rather than hidden behind a tick.

They stay **adjacent**, because `DES-011`'s claim is about the pair: *"classes must differ in their relationship to the loop, not just in their damage type"* — the Húskarl gets out by refusing to be stopped, the Stalker by never having been noticed. One class cannot test that rule. The split is about shipping order, not about whether both are needed.

And one class in the select screen is **correct**, not a stub: ADR-064's absent column, five entries that do not exist rather than five that do nothing.

### What "complete" means for a class

`DES-011` defines a class as four things: a starting kit, one unique verb, a class-only **Rite branch** (~7 nodes), and access to 3 of the 5 Aspects. **Two of those four are skill-tree work** — and the Rite unlocks at Pact Rank 3 (ADR-060), which nothing can reach until `M3-T01`.

**A class is complete at `M3-T02` as a body you play.** A Húskarl with Hold, a shield, heavy armour and a stat line is distinct, finished and playable; what it lacks is *progression*, and progression is absent for every player until the tree exists. That is the same shape as the hoard, which has grown since `M2-T06` and buys nothing yet — a real system whose consumer has not arrived, not a hollow one pretending to be real.

The alternative was moving `M3-T02` after `M3-T01` so a class arrives whole. Rejected: ADR-009 makes **your class decide which three Aspects you may enter**, so the tree would then be built with its gating rule missing and retrofitted afterwards — which is the exact ordering fault ADR-116 §2 swapped these two tasks to avoid. Trading it back to get a Rite branch three tasks sooner is a bad trade.

**The task text says all of this explicitly.** A class whose Rite branch is absent, with no note saying when it arrives, is indistinguishable from a class whose Rite branch was forgotten — and `CLAUDE.md`'s rule is that a placeholder needs a named replacement task and a milestone by which it is gone. Both are named: `M3-T01`, this milestone.

---

## ADR-121 — A guard, a doorway, and a life that can begin
**Date:** 2026-08-25 · **Status:** accepted · **Closes `M3-T02`** · **Implements `DES-011`, `DES-009`** · **Extends ADR-119** · **Amends ADR-075's check**

**Context:** `M3-T02` after ADR-120's split: the class-select screen and the Húskarl entire.

### Blocking, which the game did not have

`DES-009` names five combat verbs — attack, heavy, block, shove, throw — and had **two**. `WieldableTrait` carries windup, active, recovery, damage and reach, and no notion of stopping a blow.

*"Block with weapon or shield, costs stamina, reduces damage, doesn't negate it."* All three clauses are built, and `validate()` refuses a `block_damage_fraction` of 1.0 at boot — a guard that makes you invulnerable turns every fight into a holding contest and deletes the positional defence `DES-009` has *instead* of i-frames. The stamina is spent **per blow, not per second**, so a guard held down a quiet corridor costs nothing and a guard held into a fight empties you: blocking is a decision about *this swing*.

`blocking` replicates, and not for looks. The owning peer raises a guard; the **host** decides what a blow does (`TEC-004`). A block that never reached the host would stop a blow on one screen and nowhere else, which is `PRO-005` §5's unexplainable death arriving over the wire.

`check_dead.py` then found `blocked` emitted with nothing listening — a real gap, not a tidiness one, because **without feedback a block is indistinguishable from a miss.** The wound vignette draws it: pale, on every edge, deliberately unlike a wound's directional darkening. A wound asks *where is it?* and a block asks *did that work?*; `DES-018` wants a visual twin for every channel, and a twin that lies is worse than none.

### Hold is one collision layer

*"Plant and become an immovable object. Nothing pushes past you. **Allies can retreat through you.**"*

The obvious implementation puts a planted body on `WORLD`, and it **blocks the people it exists to protect.** `CollisionLayers.BULWARK` is a layer only a planted body ever carries: enemies mask it, players never do. So the same line that makes a Húskarl a wall makes them thin air to their own party — with no rule anywhere saying *"except teammates"*, and nothing to get wrong when a fourth player joins.

The other two thirds cost a line each, because the systems were already there: immovable is `_speed()` returning zero, and the cost is stamina per second — per *second*, unlike a block, because Hold's cost is that the clock runs while you are the only thing in the doorway whether or not anything comes. Planting takes `hold_plant_seconds` and unplanting is instant; that asymmetry is the commitment, and it gives an ally time to read that you have done it.

### The class is data, and complete as a body you play

`ClassResource` and `ClassCatalogue` mirror `ItemResource` and `ItemCatalogue` deliberately — including the three-extension scan, which is not defensive padding: a table that comes back empty in an export is a build in which **no life can begin**, and ADR-086 records that failure arriving silently at full size.

The kit lands **in the stash**, so `_carry_the_stash_down()` brings it on the first descent. A starting kit then behaves like anything else you kept — it fits or it waits, and you can leave it behind. Inventing a second route into the first descent would be a parallel path for something the Chamber already does.

`class_id` is LIFE tier and `die()` clears it, which is what makes ADR-009's *"death becomes the door to a new class"* true rather than a sentence. Save v3, with the second real migration; a v2 profile migrates to `class_id = ""`, because a build with no classes describes a life that has not chosen one, and naming a class there would lock somebody into a decision they never made.

### Three checks that were wrong, and one that was only half a check

**The class body is read from the spawn payload, never from `GameState`** — the host builds four bodies and three belong to somebody else. The probe asserts the difference (125 health against 100) comes from the payload, because reading local state would work perfectly in solo and build three of four bodies wrong in company.

Two probe assertions passed for the wrong reason and only planting showed it. The layout check's plant hit this file's own doc comment instead of the code; once it landed, the screen reported **0 x 0** — ADR-111 reproduced exactly, on a second screen. And the class-lock check tried to swear `veidimadr`, **which is not authored**, so the *catalogue* refused it and the lock was never consulted. It re-swears `huskarl` now. That is the second time in one milestone that a check has been true and beside the point (ADR-113's shape), and both times the plant is what said so.

**And `bind_gamepad.py` had been enforcing half of ADR-075.** It walks its own `BINDINGS` table and confirms each has an action; it never asked the reverse. So an action defined in `project.godot` with only a keyboard binding passed silently — it reported *"all 23 actions have a gamepad binding"* while `hold` sat there unbound, which is precisely *"an action reachable only from a keyboard"*, the bug the file's header says it exists to catch. It runs both directions now, and the first thing it did was fail on the action that had just slipped past it. **A check that enumerates its own expectations can only ever confirm them.**

### The pad is full, and three verbs are homeless

Adding `block` and `hold` found that **every face button, shoulder, trigger, stick-click and d-pad direction is already assigned** — while `heavy`, `block` and `shove` had no binding at all. Both new verbs *share*: `block` with `rotate_item` and `hold` with `sprint`, on the disjoint-context precedent `interact` already sets (you cannot raise a shield while rummaging, and no hand wants sprint and plant in the same instant).

That is a patch, and it is recorded as one. The layout pass belongs with rebinding at `M4-T06`, and it now has a written reason to happen.

---

## ADR-122 — `M3-T10` shipped doing the thing ADR-010 rejected
**Date:** 2026-08-25 · **Status:** accepted · **Corrects `M3-T10`** · **Extends ADR-119**

**Context:** An audit of `M3` after `M3-T02`. `M3-T10` was green, probed and committed, and in co-op it built **the floor to the host's rank alone** — which is the option ADR-010 considered and refused, failing in precisely the case ADR-010 exists for.

### One frame apart

`room_set._ready()` builds the floor: `_spawn_actors()`, then `_build_hunt()`, in one frame. A client's `declare_descent` is an **RPC**, sent from that peer's `_on_connected` and arriving on the host some milliseconds later.

So `_build_hunt()` — which reads `floor_rank()` exactly once — could only ever see the host's own declaration. A rank-8 friend joining a rank-1 host changed nothing about the Hunt, ever. Density recovered only by accident, because `_on_party_changed` re-spawns when a *body* appears, and a body appearing and a declaration arriving are independent events with no ordering between them.

*"Boredom is worse than danger"* is ADR-010's whole argument, and the build delivered boredom.

**`floor_rank_changed` is the fix.** The session raises it when a declaration moves the maximum; the level re-spawns and ages the Hunt by **the difference**, never the whole — `age` is a clock that has been running since the floor opened, and re-applying a rank in full would age it twice for the same rank.

### Why nothing caught it

`--rank-probe` is single-process. It set `_ranks` directly and asserted the arithmetic, the multiplication against party size, the fixed stat line and the maximum. **Every one of those was right.** What it could not ask is whether a *client's* declaration reaches a floor, because in one process there is no wire and no frame delay.

This is the shape ADR-097, ADR-105, ADR-108, ADR-110 and ADR-117 all had, and the fifth time this milestone: **the parts were correct and the join was not built.** It is also the second time a co-op-only fault has survived a green sweep (ADR-113 was the first), which is what the two-process smoke exists for.

### Three things the check taught while being written

**The first Hunt assertion was `> 0`, and it passed while the floor was demonstrably rank 1.** The Hunt's clock ticks on its own, so it read 2 s and called that a pass. Rank 8 is worth 140 s of head start and the probe runs for seconds, so the threshold is 100: three figures is the rank and nothing else could have put it there. Third *true-but-beside-the-point* assertion in one milestone (ADR-113's shape).

**The check was flaky, one run in two, and the flakiness was the bug's own shape.** `_await_party()` waits for bodies. A body and a declaration are independent, so the probe was sampling a floor that had not finished assembling. `CoopSession.everyone_declared()` settles the *measurement* — nothing in the game waits on it, because the floor now rescales whenever a declaration lands, however late. The `floor scaled to the party` row had been silently nondeterministic too, reporting 6 or 15 enemies depending on timing, and passing either way.

**And the two rows prove different things**, which only planting showed:

| Plant | `floor_rank` | `hunt_age` |
|---|---|---|
| the client never declares | **1 — fails** | **fails** |
| the floor ignores the declaration | 8 — passes | **fails** |

The first row proves the number crossed the wire; the second proves it was *used*. Keeping them apart is what makes a failure say which half broke, and collapsing them into one row would have hidden exactly the bug this ADR is about.

### `--as-rank=`

A mixed-rank party cannot otherwise be assembled: two processes on one machine share a `user://` and cannot hold two profiles, and nothing raises a rank until `M3-T01`. Without it the only co-op party the sweep can build is two rank-1 players — **the one composition that cannot tell a working ADR-010 from a broken one.** It overrides the profile for one process and every declaration site reads it through `_my_rank()`, because four copies of `GameState.pact_rank` is four places to forget a flag.

---

## ADR-123 — The quiet way out, and the first weapon that is not a swing

**Date:** 2026-08-25 · **Status:** accepted · **Implements `M3-T11`** · **Amends `DES-009`, `DES-011`** · **Completes ADR-120's split**

**Context:** `M3-T11`, the other half of the task ADR-120 broke in two. `DES-011` defines the Veiðimaðr by *"bow, traps, tracking, silence"* and by one unique verb — **Snare**, *"including against the Hunter, the only reliable way to buy time during the Sealing."* The build had neither half. `DES-009` names five verbs — attack, heavy, block, shove, throw — and **every one of them is melee or a physics launch**; `throw` exists and does no damage, because it is for baiting the Gullsjúkr.

So a class kit could not simply contain a bow. A bow is a whole damage-delivery system, and letting one arrive through a `.tres` would be the combat document being edited by something that is not allowed to edit it. **`DES-009` gains a *Shooting* section** — that is what this ADR buys, and the rest follows from it.

### The arrow is a body, and the noise is the weapon

Two decisions carry the design, and neither is about damage.

**It travels.** A raycast would make the bow a test of aim, which is the reflex-over-decision trade principle 3 rules out and which `DES-009` already refuses in as many words. An `Area3D` with a real radius can be **led**, and can be **walked out of** — so *"defense is positional"* stays true of a weapon fired across a room. Flat flight with a range cap, no arc: an arc is a precision mechanic wearing physics.

**It is quiet where you are and loud where it lands.** `clamor_loose` is 0.4 and `clamor_hit` is 3.2. That inversion, not the damage, is what the Stalker buys — the same misdirection `DES-005` already sells thrown loot on, and the mechanical form of *"gets out by never having been noticed."* A bow that were merely *quieter* would be a stealth stat; a bow that puts the noise **somewhere else** is a tool.

**The obvious way to make that noise does nothing at all.** A `ClamorSource` created at the impact, added, `add()`-ed and freed in one frame is **never heard**: `ClamorField` subscribes to sources on its *own* physics tick, so it absorbs a node that no longer exists and the signal reaches nobody. `deposit()` is the seam for exactly this — noise at a place, with nobody making it. There is a second reason that matters more once there are four players: `ClamorSource.add()` is where `M2-T07` put party scaling, so routing impact noise through one would charge a four-stack twice, and their arrows would land louder than their own footsteps.

### One weapon in the hands, and the kit is what puts it there

A body carrying a bow **does not also swing**, and the blade is not drawn. That is `DES-011`'s stated cost for this class — *"poor in a straight fight; a Stalker who is cornered is usually dead"* — written as a **missing verb rather than a penalty multiplier**, which is ADR-058's test passed rather than argued around. It is also why the bow needs no button of its own.

What arms the class is `ClassResource.kit`, which already named real catalogue ids and until now only stocked the stash. A kit entry carrying a `RangedTrait` is a bow in the hand, so a designer arms a class by editing a `.tres` and nothing in the player knows what a Veiðimaðr is. `M3-T07` re-points that at an equipment slot: it **moves the seam rather than growing a second one beside it**, which is the distinction ADR-064 draws between a gate decision and a parallel fallback.

`RangedWeapon` is built only when the class has one, rather than sitting hidden in `player.tscn` for the five classes that do not. A node present-but-inert in every body is ADR-066's argument one level down from autoloads.

### The Snare ships as *hold*, and that is the whole sentence

`DES-011` lists **trap variety** under this class's *Rite themes* — which means the tree (`M3-T01`), not the base verb. So one trap, doing the one thing the doc names as load-bearing. Wound is a bigger number and ADR-058 makes that the proposal needing a very good reason; misdirect already exists twice over, in thrown loot and now in this class's own arrows.

Its costs, per `DES-011` rule 3:

| | |
|---|---|
| Placing takes `snare_place_seconds` and stamina | the Húskarl's plant argument — a verb you can flick out mid-fight is a reflex |
| **One live at a time**, and a second removes the first | a decision about *where*, not a resource to count — which is also why it needs no ammunition economy to exist, and why the Rite has an obvious real upgrade to sell |
| Silent to set, **loud when it fires** | the Stalker's one loud act, and it makes a trap set in the doorway you are leaving through a mistake you can make |

It masks `ENEMY_BODY` and nothing else, so it never holds your own party — the same argument `BULWARK` settled at `M3-T02`: the layer is where you say who something applies to, and there is no *"except teammates"* rule to get wrong.

**`Rooted` is a component, not a flag.** `Enemy` and `Gullsjukr` share no ancestor and never should — one is a brain with a navigation agent, the other navigates a noise field. But *"can this thing move right now"* has to mean **exactly** the same thing for both, or the Snare works on the enemies it is a convenience against and fails on the Hunter it exists for. It roots movement and not action: a held enemy still turns to watch you and still swings at what is already in reach, so what the Stalker bought is that nothing **follows** — a trap that also disarmed would be a stun, and a one-placement stun is the no-counter-play answer `PRO-005` §5 rules out.

### One button for every class's verb

The input action `hold` is renamed **`verb`**. It was named after the Húskarl's verb because the Húskarl was the only class; with a second one arriving it would have become either a misnomer or the first of six buttons. `ClassResource.verb` still says *which* verb, so the class decides what the key does and `DES-009`'s button count does not grow with `DES-011`'s roster.

### One fault in the game. Six in the check.

The only production bug the probe found was Godot's *"Function blocked during in/out signal"* — a sprung trap dropping `monitoring` from inside `body_entered`, which is the same rule that already defers a corpse dropping its collision layer.

**Everything else that was wrong was wrong in the measurement**, and that is worth recording, because it is where the risk has moved:

- **Bodies spawned outside the room.** Every target went 8–14 m along +Z from a spawn point, and the entrance room ends at z = 10. Nothing errors when a body leaves the world — it falls, and the probe confidently reported an enemy "moving" 34 m in one second and an arrow that missed. Every distance is a named constant checked against `ROOMS.entrance` now.
- **A control that could not fail.** The first snare test spawned an enemy, waited, and measured a second of movement before snaring — by which time it had closed to 2.16 m and *stopped*, so "it did not move" was true of a body standing in attack range. The control is now the **same body moments later**, snared for a window and then released and measured over an identical one. **Fifth true-but-beside-the-point assertion this milestone** (ADR-113's shape, and ADR-117, ADR-119 and ADR-121 each found one).
- **An unbounded `while held()`.** A probe that hangs is strictly worse than one that answers wrongly: it ran the harness for ten minutes and reported nothing at all. Bounded, and the bound is now itself the assertion that a root ends.
- **A true reading of the wrong cell.** `ClamorField` is a 2 m grid, and an arrow stops at the *surface* of a hurtbox — here 0.17 m short, and one cell over. Asking a single coordinate returned 0.06 where 3.2 had just been deposited next door, and it survived three passes and two wrong diagnoses before the deposit was printed and found to have been correct all along. Both ends of every comparison go through one neighbourhood reader now, so the window can never favour one side.
- **Reading a node that had freed itself.** A sprung trap lingers three seconds so a player can see what stopped the thing; a wait longer than that outlived it, and the probe asked a freed object whether it had fired. The flag is read when it fires.
- **A trap sprung by somebody else.** The *"it never catches your own party"* row ran on a floor with a live enemy and a Hunter being deliberately called toward the same spot. It runs on an empty floor now, because the question is what the **player** does to a trap.
- **A row that had been deleted.** The *"your own arrow cannot kill you"* check was lost in a rewrite of the section around it and nothing noticed, because a probe reports what it runs and says nothing about what it no longer contains. The plant is what found it. It is back in a better form than it left: one arrow fired **at** the archer carrying their own peer id, and an identical one carrying a stranger's — because *"0 damage"* and *"it never arrived"* are the same reading, and the original had no control to tell them apart. Firing at your own feet, which was the obvious version, proves nothing either way: the muzzle sits half a metre ahead of the head and an arrow dropped from there is past the body in two physics frames.

### The exclusion was resting on its own fallback

The row saying a Snare never catches your own party **passed with `PLAYER_BODY` added to the mask.** The trap overlapped the player, was monitoring, and did not fire — because `_on_stepped_in` also bails on a body with no `Rooted`, and a player has none.

That fallback is correct and stays: a body that grew a layer and not a component should walk through rather than crash. But it is **not what this design leans on.** ADR-121 settled the argument at `BULWARK` — *the layer is where you say who something applies to* — and a claim resting on its second line of defence is one nobody is watching. The first body ever given a `Rooted` for another reason would have started catching the party, and the behavioural row could not have told anyone.

So the probe now asserts the **mask itself** beside the outcome. A structural assertion is unusual here and worth the exception: two independent guards produce one indistinguishable observation, and only naming the intended one keeps the other from silently becoming load-bearing.

Fourteen violations were planted and each named row was seen to fail.

### Removed rather than kept

`Rooted` shipped with `took_hold` and `let_go` signals for bodies to dress themselves with, and `remaining()` for a readout — **nothing connected or called any of them.** The visual twin `DES-018` asks for is the `Snare`'s own sprung ring, which is a spawned actor and therefore visible to everybody; the body does not need to change. `RangedWeapon.armed()` lost its caller when the player switched to a plain null check. All four are gone: names that work and that nothing reaches are what ADR-098 is about, and the sweep after this one is where they would have started reading as load-bearing.

---

## ADR-124 — The M3 cohesion pass, and a punishment that had never landed on the right run

**Date:** 2026-08-25 · **Status:** accepted · **Corrects `M3-T04`** · **Reorders `M3`** · **Amends `M3-T01`, `M3-T07`, `M3-T09` scope notes**

**Context:** A cohesion audit of `M3` with five of eleven tasks done, asked for before play testing resumes. ADR-116 was the same exercise at the start of the milestone and it asked *"does a task exist for this?"* Six findings here, and the two that matter most are the ones that question could not have caught: they are about things that **were** built.

### 1. The Tithe soft-fail had never once reached the floor it was for

`settle_cycle()` decides how much Hunt a missed cycle buys her. `_build_hunt()` is what makes a Gullsjúkr. In `room_set._ready()` the settle ran **seventeen lines after** the build.

So the head start a floor consumed was always the *previous* descent's, and the four minutes she had just sent for waited for the next floor — arriving on a cycle the player may well have paid. `tithe_missed_head_start` is 240 s: four minutes of Hunt, applied to the wrong run, every time since `M3-T04` shipped.

**Every piece had a check and passed it.** `--tithe-probe` drives `settle_cycle` and `take_hunt_head_start` in the Chamber and asserts both correctly. `--rank-probe` reads `hunt_age` off a built floor and asserts it correctly. What nothing asked is whether the **order** in `_ready` lets one reach the other. That is the sixth time this milestone that the parts were right and the join was not built — ADR-105, ADR-108, ADR-110, ADR-117, ADR-122, and now this.

The fix is also a subtraction. The Gullsjúkr no longer reaches into `GameState` at all: `_build_hunt` already applied the rank head start for the reason ADR-119 gives — *"the floor knows its rank and the Hunter should not be reaching for a session to ask"* — and a missed Tithe is the same kind of fact. Both live there now, so **one line in the project decides that a Hunt begins old**, and it runs after she has decided.

`settle_cycle()` is also **ungated from `_probing`**. It was gated alongside `_carry_the_stash_down()`, and only the second one needs it — a probe inheriting a loadout is measuring a bag it did not pack. Nothing in the settle can touch a player's file, because `GameState._live` is false until `load_profile()` succeeds and `MainMenu` is its only caller (ADR-117). Ungating is what lets `--creditor-probe` boot the level and read what the floor actually did, rather than reconstruct the order and assert against its own reconstruction.

Four violations planted, each caught — including the original ordering restored verbatim. **And one row that could not fail:** *"the slate cleared"* asserted `tithe_paid == 0` after the settle, having set it to 0 before it. It is part-paid now.

### 2. `WieldableTrait` has no reader anywhere in the game

Four weapons — `wpn_seax`, `wpn_ash_spear`, `wpn_dvergar_hammer`, `rlc_regin_blade` — carry full windup, active, recovery, damage, reach and block numbers that **nothing consumes.** Melee damage comes from `Config.tuning.swing_damage`.

`check_dead.py` cannot see this: the class name is referenced by `ItemResource.validate()`, so the name is alive and only the *data* is orphaned. It is ADR-098's own caveat — names, not reachability — arriving in a form probes cannot catch either, because no probe swings an item.

In play this is worse than inert. `wpn_seax` **spawns on the floor** as the payoff for the west bypass route ADR-032 designed, and is worth 0 tribute, 1.1 kg and two squares of bag for no function at all. `arm_mail_byrnie` is 11 kg for 8 tribute — the worst ratio in the table by four times — because its real value is armour and there is no armour. **Six of thirteen items are waiting on `M3-T07`.**

So `M3-T07` **moves from second-to-last to second.** It read as polish and it is not: it is what makes a third of the item table mean anything, and until it lands a tester who picks up a weapon has been handed a strictly negative object.

### 3. `M3-T01` is what makes Pact Rank move, and its task text never said so

Nothing writes `pact_rank` outside probes and `die()`. `DES-003` is explicit — *"every point of Boon spent raises your Tithe"* — so rank **is** Boon spent, and `M3-T01` is the only thing in the project that can raise it.

Three shipped systems are standing on that: the nine-row Tithe table only ever reads row 1, every axis of `RankScaling` is inert, and `Gullsjukr.killable()` needs rank 8 and can never be true. **Both `M3` gates are unreachable until it lands** — `GATE M3 EXIT` compares a rank-8 player against a rank-1 one, and `GATE M3 COOP` needs a rank-8 player to bring a rank-1 friend.

None of that was wrong, and none of it was written down. ADR-116 checked whether a task existed for each gate; this is the same blind spot from the other side — **what is standing on a task nobody has started.** The task text says it now.

### 4. A Veiðimaðr descended with two bows

`take_the_oath` stashes the kit and `Player._arm_from_kit` reads the same list to put a bow in the hand, so the bag held an inert duplicate: three squares, 1.4 kg, 0 tribute, no function. One object with two representations — ADR-064's banned category, arrived at by accident rather than by design.

A kit entry the body already *is* no longer goes to the stash. That guard is one line and `M3-T07` deletes it along with `_arm_from_kit`, when a slot decides what you hold and the bag copy becomes the real one.

### 5. A missed Tithe was legible only before you descended

The Chamber says how short you are. The floor said nothing, and the Hunt was simply four minutes further along than the player had any way to account for. Principle 4 asks that a death be explicable in one sentence, and *"I did not pay her"* is only available to somebody told it was still true down here. The arrival brief gains a fourth line, and only when she is owed.

### 6. The class-lock probe could finally be asked properly

It swore `huskarl` twice, because when it was written the only other name in `DES-011` was unauthored and the catalogue refused it — so the lock was never consulted and the row passed for the wrong reason. ADR-121 recorded that and left the comment as a marker. `M3-T11` authored the Veiðimaðr; the marker is redeemed, and the probe also asserts the kit no longer double-stocks.

### The reorder

`M3-T01` → `M3-T07` → `M3-T03` → `M3-T09` → `M3-T05` → `M3-T08`.

| | |
|---|---|
| `M3-T01` first | unchanged — it is the only thing that moves rank, and three built systems plus both gates wait on it |
| `M3-T07` second | six of thirteen items have no function until it lands, and it deletes finding 4's guard rather than patching around it |
| `M3-T03` third | the Boon cap needs a rank that can differ from a friend's, which is `M3-T01` |
| `M3-T09` fourth | the Vörðr readout is a **stated precondition** of `GATE M3 COOP`; `M3-T05` and `M3-T08` block no gate |

### What this pass did not find

No task in `M3` is missing, and no gate names something nothing builds — which is what ADR-116 was for, and it holds. The remaining six tasks do deliver both gates. Every fault here was in something already built and green, which is the same conclusion ADR-123 reached about its own probes one commit earlier: **the risk on this project has moved out of the code being written and into the joins between code that already works.**

---

## ADR-125 — "Tribute → Boon → Aspects" was four systems in one checkbox

**Date:** 2026-08-25 · **Status:** accepted · **Splits `M3-T01`** · **Adds `M3-T12`, `M3-T13`** · **Follows ADR-120**

**Context:** Starting `M3-T01`, the largest remaining task in the milestone. Reading `DES-004` and ADR-060 together makes the checkbox's real size visible.

### What the one line contains

| | |
|---|---|
| **Tribute → Boon** | the conversion, its rate, and the rule that tribute below the Tithe converts to nothing |
| **Boon → Pact Rank** | the number three shipped systems and both `M3` gates are standing on (ADR-124 §3) |
| **The tree itself** | node data, costs, prerequisites, class gating, the keystone lock, and a screen in the Chamber |
| **Two Aspects complete** | `DES-004` fixes an Aspect at ~13 nodes — 1 keystone, ~4 greater, ~8 lesser — and **rule 2 forbids any of them being numeric**, so all ~26 are bespoke mechanics |

That is the shape ADR-120 found in *"two classes complete"*, at roughly twice the size. The economy and the tree are machinery; an Aspect is content. Shipping them in one checkbox means nothing is playable until all of it is.

**`M3-T01` keeps the economy, the rank derivation, the tree and one Aspect. `M3-T12` is the second.**

### Hoard is the first Aspect, and the choice is forced

`DES-011` gives the Húskarl **Scale · Cinder · Hoard** and the Veiðimaðr **Wing · Hoard · Maw**. The two playable classes share exactly one Aspect, deliberately — they are designed as opposites.

So **Hoard is the only first Aspect that gives both classes progression at all.** Wing first would leave a Húskarl with a tree they cannot enter, which is worse than the tree not existing: a visible path with your class locked out of every node reads as a bug, not as a design.

It is also the one whose nodes are built from systems that already exist — inventory, carried weight, the Clamor field, the tribute ledger and the Gullsjúkr's own wealth check are all shipped and probed. Scale wants hazards (`M4-T02`), Maw wants consumables and Corruption, and Cinder wants area denial; each would have to invent its supporting system before its first node could do anything.

`M3-T12` is **Wing**, which completes the pair for the Veiðimaðr — primary and secondary, the full `DES-004` experience — and is pure content against machinery this task will have proven. The Húskarl's second Aspect is `M4`/`M5` work and is **absent, not stubbed**: three of five Aspects are not listed, not selectable, and not in any menu.

### The respec is absent, with a task and a milestone

`DES-004` gives a respec that costs real resources and cannot change your keystone mid-life. It is **`M3-T13`**, and it is deferred rather than stubbed on ADR-064's sanctioned-exception test — a named task with a permanent id, and a milestone it is gone by.

Nothing can respec into an Aspect that does not exist. The choice the respec exists to protect — *"locking the keystone is what makes the choice matter"* — has no teeth until there are two paths to choose between, which is `M3-T12`. Building it earlier would be tuning a resource cost against a decision nobody can yet make.

### Pact Rank is derived, not stored

ADR-124 §3 established that nothing raises rank and that `DES-003` makes it Boon spent. ADR-060 fixes the two numbers that turn that into an arithmetic: node costs of **lesser 1 · greater 2 · keystone 5**, and *"~20 taken by Rank 9"* — which is ~31 Boon on a representative spread.

So rank is a **function of the nodes taken**, not a counter that anything increments: one source of truth, and a rank that cannot drift from the tree that earned it. `pact_rank` stops being a stored field. The mapping itself is ⟨tune⟩ and lands in the `TuningProfile` like the Tithe table beside it.

---

## ADR-126 — The pact moves, and the tree is a set of names

**Date:** 2026-08-25 · **Status:** accepted · **Implements `M3-T01`** · **Follows ADR-125** · **Reads `TEC-006` §127**

**Context:** `M3-T01` as ADR-125 scoped it — Tribute → Boon → Pact Rank, the tree and its screen, and the Hoard. Pact Rank had sat at 1 since `M3-T04`, and ADR-124 §3 recorded three shipped systems and both `M3` gates standing on a number nothing in the project could change. This is the task that changes it.

### Rank is derived, and that removes a whole class of bug

`DES-003`: *"every point of Boon spent raises your Tithe."* So rank **is** what the tree cost you, and `pact_rank` is a computed property over `taken` rather than a stored field. Nothing can assign it; there is no second copy to drift.

That also makes `die()` simpler than it was. `DES-003`'s reset table gives the skill tree as *"all of it"*, and because rank reads off exactly that list, **clearing the list is what returns rank to 1.** There is no separate rank to remember to reset — which is the door ADR-118 worried a debt might survive through, closed by construction rather than by a line that has to be maintained.

Save **v4** drops `pact_rank`. Nothing is lost: it had exactly one possible value in every v3 save that ever existed, and an empty tree derives it.

### `TEC-006` was right and I was wrong

The first draft put node effects in code, with `AspectNode` holding only identity. `TEC-006` §127 is explicit:

> **`effect_tags` is where the discipline lives.** A node declares `"carry_no_limit"` and the inventory system reacts. The node never contains logic. This keeps `DES-004`'s "no node is purely numeric" rule enforceable — a node with only a numeric field and no tag is a stat stick, and reviewable as such.

Adopted, because it is better on both counts. `has_effect(tag)` is now the single seam every system reads the tree through — `Inventory` asks for `carry_no_limit` and never asks what nodes were taken; the tree never reaches into a bag. And `validate()` **refuses a node with no tags**, which turns `DES-004` rule 2 from an aspiration into something the build fails over.

Two of `TEC-006`'s sketched fields are deliberately absent, and both are superseded rather than skipped:

| | |
|---|---|
| `boon_cost` | ADR-060 fixes cost by **tier** — lesser 1 · greater 2 · keystone 5. A per-node price lets one lesser node quietly become worth three, which is rule 2's bigger-number pressure arriving through the price instead of through the effect. |
| `tithe_increase` | ADR-118 chose a **table** over a curve, because `DES-003` gives three anchors and everything between them is judgement. A per-node increment would be a second way to move one obligation. |

`AspectNode` also reaches for no autoload, and that is load-bearing: `data_probe.gd` runs as `--script` with none registered, so a single `Config` reference in a resource stops the **whole corpus** from validating. The first draft had one, in `cost()`.

### The tree comes with the body, not with the machine

`GameState` knows only this machine's nodes and the host builds four bodies, three of which belong to somebody else. A host reading its own `has_effect` would have applied its tree to the entire party.

That is exactly the fault ADR-121 avoided for the class, arriving one task later through a different door — so it takes the same route: the tags cross on `declare_descent` beside rank and class, and reach the body through the **spawn payload**. `Player.effects` is what every system reads, and `TEC-004`'s *"progression is never networked"* stays honest because what crosses is the set of rules that are on — no Boon, no spend, no tree, and the host stores none of it past the floor.

### The Hoard prises `DES-019`'s three costs apart

Space, weight and noise are one instrument today. Every Hoard node separates a strand of it, and the keystone removes the third at the price of doubling the other two:

| | |
|---|---|
| **Weight of Kings** *(keystone)* | `DES-004`'s own: no carry limit, and every kilogram is louder and slower than it would be for anyone else. The drawback rule holds — the whole floor hears the vault leaving. |
| **Ballast** | weight makes you slow; it no longer makes you loud |
| **Quiet Hands** · **Coin-Sense** · **Steady Step** | handling, gold and landings stop costing Clamor |
| **Her Reckoning** *(rank 4)* | `DES-017`'s wealth sense stops **singling you out**; it still hears you |
| **Tribute in Kind** | anything you set down is worth her stooping for — and she takes it |
| **Scavenger** · **Long Haul** · **Sure Grip** · **Ready Hand** · **Tally** · **Close the Lid** | materials weigh nothing, load stops costing height, and the bag stops costing seconds |

**Set Aside was designed and cut.** *"Promise her one carried item — weightless, silent, and hers when you climb out"* is a good node and needed a way to **pick** one; the bag's right-click rotates and its left-click drags, so it wanted a new input action. Adding a button for a single node in a single Aspect is the creep ADR-075's binding budget exists to resist, and shipping twelve-and-a-half nodes is what ADR-064 forbids. It is a natural `M3-T07` node instead, where equipment slots bring a UI that "promise this one" belongs in.

`Tribute in Kind` replaced it, built on the bait rule ADR-089 and ADR-114 already proved. It cuts both ways, which is what a greater node should do: you can buy seconds with a stone, and you have taught her to follow your discards.

### `data_probe.gd` kept a promise it made at `M2-T08`

Its own header said three `TEC-006` rules were absent *"because the resources they check do not exist"*, and that **each rule arrives with its data.** Two of the three arrived here: dangling `requires`, and tag-less nodes. Three more went in beside them that no single node can answer about itself — a prerequisite in **another Aspect** (a lockout gated on a path the class may not enter), a `requires` **cycle**, and an Aspect with **no keystone**. Plus the guard that matters most, in the shape the item one already had: *no nodes found* fails, because every rule below it is conditional on there being a tree.

### What made rank derived broke a probe's arrangement rather than its assertions

`--tithe-probe` assigned `GameState.pact_rank = 5` so that one coin would fall short of 260. With rank read-only the assignment did nothing, the case stopped being short, and four rows failed at once.

**The setup stopped working while every line still read as sensible** — quieter than a wrong assertion, and only the sweep caught it. It goes short by part-paying now, which asks the same question without borrowing a rank from another system.

It also produced a seam worth having. `tithe_for(rank)` splits the table from the rank, so `DES-003`'s three anchors can be asserted directly. The alternative was a probe stuffing `taken` with duplicate ids it could never own to manufacture rank 9 — the Hoard alone tops out near rank 6 — and a check that manufactures its own premise is testing its fiction, which is this milestone's most frequent failure wearing a new coat.

### What is not asserted, and is named rather than claimed

**One keystone at a time** cannot fail while one Aspect is authored: there is no second keystone to refuse. `M3-T12` is where that rule gets a real test. Saying so is cheaper than a green row that means nothing — this milestone has produced six true-but-beside-the-point assertions and every one of them read as coverage.

### A row that was true by construction

Ten violations were planted and each named row was seen to fail — but only after one of them did not. *"Taking nodes cost nothing"* asserted `boon_spent() > 0`, and `boon_spent()` is **summed from `taken`**: it reported the right number whether or not a single point had actually left the purse, so a plant making every node free walked straight through it.

Seventh true-but-beside-the-point assertion this milestone, and the first that was wrong *by construction* rather than by circumstance: **a derived value cannot witness the thing it is derived from failing to be paid for.** It asserts the balance now — what left the purse against what the tree cost.

That is worth stating as a rule, because deriving values is exactly what this task did to rank: every derived quantity in the project needs its check written against the *source* it is derived from, never against itself.

---

## ADR-127 — Six slots, and the client who had never had a class

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T07`** · **Corrects `M3-T02`** · **Extends ADR-122**

**Context:** `M3-T07`, moved second by ADR-125. `DES-020` specifies six equipment slots; the build had none, so `WieldableTrait` carried windup, active, recovery, damage and reach on four authored weapons and **nothing read any of it** — `MeleeWeapon` swung on `TuningProfile` numbers identical for every weapon in the game, and `wpn_seax` was the west bypass route's whole payoff at zero tribute and no function.

### The slot is the reader `WieldableTrait` never had

`Equipment` holds six slots and one rule: what is in `MAIN_HAND` is what `MeleeWeapon` swings. So a weapon's stat block finally reaches the thing that uses it, and four items stop being data nobody consumes. The Regin Blade is now genuinely better than the seax in the way its `.tres` always claimed.

`_arm_from_kit` is deleted. `M3-T11` built it as the seam that put a bow in a Stalker's hand and said in its own header that `M3-T07` would re-point it at a slot — which is what happened, one task later, exactly as written. `RangedWeapon` reads `OFF_HAND`-or-`MAIN_HAND` through the same accessor the melee weapon does, so *"one weapon in the hands"* is now a fact about the slot rather than a rule in the player.

### The kit is worn, not stashed

`M3-T02` put the class kit in the stash because there was nowhere to wear it. That was correct then and would be a duplicate now — a Húskarl would descend holding a seax **and** carrying one. Kit entries with a slot are equipped; entries without one still go to the stash, which is the honest split and needs no rule about duplicates.

`--class-probe` asserted `stash == kit.size()`. That assertion was right until slots existed and is wrong now, so it asks the surviving question instead: **every kit entry is either worn or stashed, never neither.** A vanished kit entry is what a first descent with empty hands would look like.

### The client had never had a class

The two-process smoke caught what no single-process probe could: with slots, a body's weapon comes from its class — and **every client's body had been built classless since `M3-T02`.**

`_on_peer_connected` spawns a joining peer's body immediately. That peer's `declare_descent` is an RPC it sends from its own `_on_connected`, and neither waits for the other, so the spawn payload was assembled before the host had been told anything. A client Húskarl had 100 health instead of 125, base speed, base carry, and no verb.

**Two tasks shipped over the top of it** and nothing noticed, because `sworn` only moved numbers — and a number being wrong on somebody else's screen is invisible without something to compare it against. Slots gave it a weapon to hold, and the smoke started swinging at air.

This is ADR-122's fault one door over: *a body arriving and a declaration arriving are independent events.* ADR-122 fixed the floor by reacting to the later of the two; the body takes the same answer from the other end. `sworn`, `effects` and `wearing` are **replicated host-authored state** rather than spawn payload, so a declaration is correct whenever it arrives instead of only if it arrives first. `_redress()` is idempotent and runs on every change.

One route, not two. A payload copy *and* a wire copy would be the parallel path ADR-064 bans, and the version of this bug that comes back.

### Two harness expectations that were describing nobody

Both failed the moment the class started reaching client bodies, which is the right way round — they had been quietly wrong for two tasks.

- **The revive row compared against `TuningProfile.player_health`.** A Húskarl is 1.25×, so a real revive returns 50 of 125 and the harness expected 40 of 100. It now reads that body's own maximum, which the report carries.
- **The smoke client was a Veiðimaðr** in the first draft of the `--as-class=` flag, because a mixed-class party is a better party. A Stalker carries a bow, and the row underneath is about *melee* damage being resolved once by the host — so it left the client with nothing to swing and the harness reported it as damage that failed to replicate. A true reading of an unarmed player and a wrong story about the wire. Mixed classes are `GATE M3 COOP`'s question, with real people.

`--as-class=` is a harness flag rather than a default in the level, for the reason `--as-rank=` is: `room_set` is only reachable in the real game through a menu that refuses to descend without a class, and a level quietly supplying one would hide the day that stops being true.

### Save v5

`worn` is LIFE tier — it dies with you, like the stash and the class it came from. What persists is the slot-to-item mapping, resolved against the catalogue on load, so an item removed from the game leaves an empty slot rather than a broken save.

### Three faults in the checking, one of them mine to the tree

**The probe was never wired into the sweep.** `--gear-probe` was written, run by hand, and left out of `check_scripts.sh` — ADR-110's failure exactly, and the second time on this project: *a probe nobody runs is a check that is already failing.* It runs now.

**Gear reached disk untested for the whole of its first task.** A plant that stopped writing `worn` to the wire went **uncaught**, because every row in `--save-probe` was about the hoard and the stash. Save v5 shipped a new LIFE-tier field with nothing behind it. The round trip covers it now, and it is the seventh time this milestone that a thing was built, believed, and not actually asked about.

**And I raced my own harness.** Running the sweep and the plant script concurrently against one working tree meant the sweep read `melee_weapon.gd` mid-plant and reported a `SCRIPT ERROR` that was tooling colliding with itself. Worse: two plant scripts overlapped, one restored an already-planted copy, and `held_unused` was left sitting in the tree. That would have been **committed** if the "restore" had been trusted instead of re-read. Plants mutate the working tree; they get to run alone.

### One assertion whose coverage is a different shape, and says so

The empty-hand guard **cannot be deleted without a null dereference** — removing it crashes rather than tripping the named row. So the row was verified from the other side, by planting its own claim and making `request_swing` wrongly report success.

That is real coverage, and it is not the same coverage. *"The guard is protected by a crash"* and *"the row catches the mistake"* are different guarantees, and a probe log that shows one while sounding like the other is how six true-but-beside-the-point assertions got written this milestone.

---

## ADR-128 — You may be carried, and not carried past yourself

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T03`** · **Settles ADR-011's ⟨tune⟩**

**Context:** `M3-T03`. ADR-011 decided in 2026-08 that Boon conversion is capped by your *own* Pact Rank, with overflow decaying and the remainder paid into LINEAGE — and left the rate ⟨tune⟩. It could not be built until two things existed: `M3-T10`, which made a floor above your own rank somewhere you can stand, and `M3-T01`, which made a rank that can differ from a friend's. Both now do.

### The cap is your own Tithe, not a second table

ADR-118 built a nine-row Tithe table from `DES-003`'s three anchors — 40 / 260 / 900. The conversion headroom is a fraction of **that**, so the number saying what she expects of you is the same number saying how much of a floor you can turn into power.

That is `DES-003`'s coupling stated once rather than twice. A second table would be a second set of anchors to argue about and a second thing to drift; `boon_cap_fraction` is one ⟨tune⟩ value with a `validate()` that refuses ≤ 0 (the tree becomes unreachable) and > 1.0 (a cycle earns back more than it owes, and the coupling runs backwards from there).

### Halving bands, because a flat second rate does not hold the line

ADR-011 asked for *"a steeply decaying rate"* rather than a wall. The obvious reading is a flat overflow rate, and it fails on the numbers: at 25%, a carried rank-1 player still converts **210** of a rank-9 floor's 900 — which is the power-levelling the ADR exists to prevent, arriving more slowly.

Each `cap`-sized band is worth half the last. The series sums to at most **twice the cap** however much is carried out, so the wall is soft to walk into and hard to pass. It is explicable in one sentence, which principle 6 asks of anything a player has to reason about.

Measured, at rank 1 with a cap of 30: a haul of 980 converts **60** and pays **920** into Lineage. That is ADR-011's *"fast in knowledge, slowly in power"* as an actual number rather than an intention.

### What the overflow becomes

`lineage_progress`, at LINEAGE tier — the one thing `die()` does not touch. `DES-003` is explicit that it must stay **power-free by construction**: a lineage-40 player and a lineage-1 player at the same Pact Rank have to die to the same floor at the same rate, so nothing may ever read this and hand out a number. `M3-T05` is what spends it, on Legacy slots, and it is in this milestone — which is what keeps a counter that currently buys nothing on the right side of ADR-064, the same way the hoard was between `M2-T06` and `M3-T01`.

`boon_converted` is LIFE tier and resets with the **cycle**, not the run. The Tithe is the accounting period the whole obligation is measured in, so the headroom is measured in it too.

Save **v6**. Both fields start at zero for the same reason: a profile written before the cap converted everything at full rate, so there is no overflow it failed to record. Backfilling would invent a history the save never had.

### The cap broke a probe's setup, one task after the last one did

`--pact-probe` piles forty plates into a single cycle to buy the nodes its later rows need. That is the *carried* case, and the cap now correctly refuses it — so the loop spun forever the moment this landed.

Same shape as ADR-126's finding in `--tithe-probe`, one task later: **a setup that manufactures its premise through another system's rules stops working when those rules arrive, and it does it silently.** The tree rows settle a cycle between tributes now, which is what real play does, and both loops carry a bound so a future rule change fails the probe instead of hanging it.

### A row that tested the calculator instead of the till

The headline row — *a rank-1 player cannot convert a rank-9 floor* — called `convert_with_decay` directly. It read beautifully and a plant that made `tribute()` **ignore the cap entirely** walked straight past it, because the row never touched `tribute()` at all.

It goes through `tribute()` now, one carried haul paid the way a run pays it. Eighth true-but-beside-the-point assertion this milestone, and the second whose lesson is about *which* seam a row exercises rather than what it claims: a pure function is the easiest thing to assert about and routinely the wrong one, because the bug lives in the caller.

---

## ADR-129 — "Extract and wait" was three systems and the wrong one first

**Date:** 2026-08-26 · **Status:** accepted · **Splits `M3-T09`** · **Adds `M3-T14`, `M3-T15`** · **Follows ADR-120, ADR-125**

**Context:** Picking up `M3-T09` and reading it against `DES-012`. The checkbox reads *"individual extraction, with somewhere to be while the rest of the party finishes"*, and carries two more systems in its note: the **Vörðr**, and **`user://run.active`**.

Third time this milestone. ADR-120 found *"two classes complete"* was three systems; ADR-125 found *"Tribute → Boon → Aspects"* was four. The tell is the same each time — a checkbox whose *note* introduces a noun the title does not contain.

### Three tasks

| | |
|---|---|
| **`M3-T14`** The Vörðr | Death → ward-spirit: mobile, safe, unable to fight or carry. And the **readout** — a downed player being able to tell what is happening to them. |
| **`M3-T09`** Extract and wait | Individual extraction, reusing the watching state `M3-T14` builds. |
| **`M3-T15`** `user://run.active` | ADR-050's suspend-with-forced-resume, and the file that describes it. |

### The gate precondition is not on the task that names it

`GATE M3 COOP` inherited three preconditions from `GATE M2 COOP` (ADR-115), and the third is *"the downed player can tell what is happening to them while down — fails ⇒ the Vörðr readout (`M3-T09`)."*

That is a claim about a **downed** player, not an extracted one. An extracted player is alive and out; a downed player is bleeding and deciding. They share a camera and nothing else. So the gate-blocking work is `M3-T14`, and `M3-T09` — the task the gate's own text points at — blocks nothing.

Worth stating plainly because ADR-124 §3 moved `M3-T09` ahead of `M3-T05` and `M3-T08` **on the strength of that precondition**, and the reasoning was right about the milestone and wrong about which half of the task carried it. The ordering survives the correction; the label on it does not.

### Return is not in the Vörðr task, and that is not a stub

`DES-012` gives the Vörðr two exits, and they are mutually exclusive: **Wait** (a teammate carries your ember out, your LIFE survives) and **Return** (you walk back in with nothing, your LIFE is over).

**Wait already works** — `M2-T05` built downed → ember → carried out, and ADR-114 made the Gullsjúkr stop for an ember. What is missing is the ghost between dying and being rescued.

**Return requires a LIFE to end**, and `DES-012` §32 says so in as many words: *"walking back in with nothing requires a LIFE to end, and that arrives with `M3`."* A LIFE ending is the Legacy screen — which is `M3-T05`. So Return ships **there**, with the flow that ends a life, rather than being approximated here.

That is a **gate decision**, not a stub (ADR-064): one path built completely, the other built where its dependency lives, and neither half-present. The sanctioned-exception test is met anyway — a named task with a permanent ID, and a milestone by which it exists.

### What this does not change

The milestone still ends where it ended. Nothing is added to `M3` that was not already inside `M3-T09`'s note, and nothing is deferred out of it. This is the same work with three checkboxes instead of one, which is the difference between a milestone that can report progress and one that reports a single unfinished item for three tasks' worth of building.

---

## ADR-130 — A dead player is still playing, and can finally see what is happening to them

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T14`** · **Unblocks `GATE M3 COOP`** · **Completes ADR-114**

**Context:** `M3-T14`, split out of `M3-T09` by ADR-129 as the half that blocks a gate. `DES-012`: *"On death you become a Vörðr — your ward-spirit, briefly loose. Mobile, safe, unable to fight or carry. The point is that a dead player is still playing."* None of it existed.

What existed instead was a body frozen at 0.00 m/s with a live camera. ADR-114 found enemies still attacking it and said the state *"reads exactly like being a ghost"* from the seat — which it did, minus every part of a ghost that is any fun.

### Two rules, and no third

`_target_speed` returned `0.0` when `spent`. It returns `vordr_speed` now, and the rest is what a body must stop being:

**Nothing collides with it.** The layer goes; the mask stays, so it still stands on floors and walks through doorways. A ghost the party has to walk *around* is the opposite of *"a dead player is still playing"*, and a corpse in a corridor would become a hazard to your own team — the same argument `BULWARK` settled at `M3-T02`, pointed the other way.

**And it cannot be hit.** ADR-114 made `Enemy._worth_fighting` refuse to acquire the incapacitated, and that is the right rule — but it is a rule about **attention**, and this one is about **geometry**. A swing already in flight, or any future hitbox that never thinks to ask, would otherwise still land on something `DES-012` calls safe. Safety has to be a property of the body, not of everything that might reach it.

Both are driven by the replicated `spent`, exactly as `_apply_bulwark` is driven by `planted`, and for the same reason: every peer's enemies collide against their own copy, and a body whose collider disagrees with its silhouette is `PRO-005` §5's unexplainable death.

**Deliberately absent.** No flight — `DES-012` says *mobile*, a ghost that walks is mobile, and flight is a movement system with its own tuning. No marking — it needs the ping system, which `DES-012` §32 already assigns to `M4-T05`. No unnerving enemies: it is ⟨tune⟩ flavour with no mechanism named, and inventing one to fill a bullet is how a class kit smuggles in a system.

### The readout is the gate

`GATE M3 COOP` has carried this precondition since ADR-115 — *"the downed player can tell what is happening to them while down"* — and **no build has ever had an answer.** A player taken to zero got a frozen camera, no number anywhere, and no way to know whether anyone was coming.

That is `PRO-005` §5's unexplainable event aimed at the worst moment in the game, and it is a **social** failure too: `DES-012`'s rescue design assumes the downed player is deciding whether to hold on, and nobody decides anything they cannot see.

Three states, three questions:

| | |
|---|---|
| **Down** | *How long have I got, and is anyone coming?* |
| **A hand on you** | *Is it working, and how far along?* |
| **Vörðr** | *What am I now?* |

It draws nothing that is not already replicated for this purpose — `bleeding` and `revival`, both of which `M2-T05` put on the wire precisely so the fallen player could be told. It is **not** a provisional Burden layer; `DES-019`'s is `M4-T05`, and building a second one here would be the parallel path ADR-064 bans. The test is `WoundVignette`'s: remove it and *"how long have I got"* becomes unanswerable, which is a fact rather than a feeling.

Monochrome-safe (`DES-018`): the bleed-out **shortens** and the revive **fills**, so direction carries the meaning and colour only agrees with it.

The Vörðr state deliberately draws **no bar**. There is no clock on it, and an empty bar would imply a deadline that does not exist — what that state has to say is *what you are*, because a translucent body walking through walls is otherwise a bug rather than a state.

### Return is not here, and `DES-012` says so

`DES-012`'s two exits are mutually exclusive. **Wait** already works — `M2-T05` built downed → ember → carried out, ADR-114 made the Gullsjúkr stop for an ember. **Return** requires a LIFE to end, and §32 states it: *"walking back in with nothing requires a LIFE to end, and that arrives with `M3`."* A LIFE ends at the Legacy screen, so Return ships with `M3-T05`. ADR-129 records that as a gate decision rather than a stub.

### An assertion that could not fail, and one that nearly hid behind a small screen

**The bag was already empty.** The row asserting a Vörðr carries nothing downed a player whose inventory was untouched, so it read `0 item(s)` whether or not `inventory.clear()` ran — and a plant deleting that call outright walked straight through it. A body that had nothing cannot demonstrate losing it. It goes down with a coin and a torc now, and the row reports both numbers.

Ninth true-but-beside-the-point assertion this milestone.

**And the layout row was measured against the wrong thing.** It asked whether the readout's rect was larger than 2 × 2 — which a `Control` stuck at Godot's 64 × 64 default passes while drawing a 360-wide bar off its own edge. It compares against the **viewport** now. Worth recording because the first reading of `64 x 64` looked exactly like ADR-111 happening again, and it was not: headless renders at 64 × 64, the readout was full-rect all along, and only printing the screen size beside it told the two apart.

---

## ADR-131 — Leaving is a state, not a scene change

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T09`** · **Extends ADR-102** · **Follows ADR-129, ADR-130**

**Context:** `M3-T09`, narrowed by ADR-129 to the one system its title names. `M2` ended the run for **everybody** at the first extraction, and `_on_extracted` said why in one line: it called `_end_the_run()`.

That was not an oversight. ADR-102 established that peers cannot stand in different levels, so the only way for one player to be *out* was for the floor to stop existing for all of them. The constraint is still true; what changes is the conclusion drawn from it.

### Out is a state on the body

`got_out` sits beside `spent` and replicates the same way, and `_apply_out` gives both the same treatment: off the body layer, hurtbox unmonitorable, moving at `vordr_speed`. `M3-T14` built that for the Vörðr a task ago and this reuses it rather than growing a second one — ADR-129 said it would, and the seam was already the right shape.

They are **not** collapsed into one state, and that matters. Both mean *the floor has nothing further to ask of you*; they differ in everything that happens next. One keeps their bag and is owed an outcome; the other lost theirs and is owed a Legacy screen. A single flag would have made those the same event, and `M3-T05` would have had to take it apart again.

Warm rather than cold, visually: a Vörðr is blue and a body that got out is lit like the surface. They are the only two translucent things on a floor, and a party has to be able to tell at a glance which of their friends is dead and which is safe.

### Down is not out

`_the_party_is_gone()` asked `spent` alone — the whole truth while extraction ended the run for everybody, and a hole the moment it did not. A party can now end with one body walked out and one lying spent, and a predicate counting only the dead would keep that floor open with nobody on it.

A **downed** player is emphatically still in the run. They are bleeding, an ember is coming, and their teammates are deciding — which is the entire mechanism `DES-012` builds the co-op gate on. Ending a run on a body that is still deciding would take the decision away from the people it was designed for.

And no settle window on the extraction path, unlike the wipe. The wipe waits because a revive inside the window has to cancel it; two players going down a second apart is an ordinary way for a fight to go. Nothing cancels an extraction — the last player walked out on purpose, and there is nobody left to change their mind.

### The harness was asserting the behaviour being removed

`run_doorway.py`'s extraction scenario spent **one** Waystone, on the host, and asserted the whole party reached the Threshold. Correct under `M2`'s rule, and the first thing to fail here — with all three peers *stranded in the Deep*, which is exactly right: a host that leaves no longer takes the floor with it, and nobody else had left.

Every peer extracts in turn now, host-side, because the bag is the host's to grant (`M2-T19`) and a client adding to its own would be writing a bag it does not own.

**And "everybody arrived" turned out to be the weaker half.** It is equally true of a build that sends the entire party home the instant the first stone is spent — which is the behaviour this task exists to end, so the row could not tell the old design from the new one. The harness asserts the thing only individual extraction can produce: after the first extraction resolves, **somebody is still down there**.

Not a weak assertion in the sense this milestone has produced nine of. This one was correct, and stopped being *sufficient* when the design underneath it moved. Worth naming as a separate failure mode: a check can rot without ever becoming wrong.

### The scenario outlived the scene it was measuring

`_extraction()` walks the party and spends a Waystone per body. The **last** of those calls `_end_the_run()`, which changes scene — and Godot detaches the outgoing scene **synchronously**, so the next `await get_tree().physics_frame` in the loop runs on a node whose tree is already gone: *"Cannot call method 'get_nodes_in_group' on a null value."*

Exactly ADR-117's trap, which killed `--menu-probe` on *"Cannot call method 'quit' on a null value"* and was fixed there by holding the tree before the walk. The lesson did not transfer, because this is a **new loop** rather than an edit to that one — worth recording, since "we already solved this" is only true of code that inherits the solution.

**Two green runs failed to exercise it**, and the reason is the ordering: when a client extracts last, the host's copy of the scenario has already returned and never touches a detached tree. It surfaced on the sweep, where the timing differed. Not a flaky check and not a check that rotted — a real race that two passes happened to miss, which is the case for running a harness more than once before believing it.

`is_inside_tree()` is the guard: the scenario notices it is no longer in the world it was measuring.

### One number that was written down twice

The scenario waited a literal for the Waystone's channel. It reads `ExtractionTrait.channel_seconds` off the item now — a harness carrying its own copy of a game value is a second source of truth, and this milestone has already produced two: the revive row measured against `TuningProfile.player_health` while a Húskarl revives against 125 (ADR-127), and `--tithe-probe` assigning a `pact_rank` that had become derived (ADR-126).

---

## ADR-132 — Quitting costs what staying would have

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T15`** · **Settles ADR-050 Q10** · **Completes ADR-129's split**

**Context:** `M3-T15`, the last of the three systems ADR-129 found inside `M3-T09`. `TEC-003` put mid-run state in `user://run.active` *"so a crash or quit mid-run can be resumed rather than silently converted into a death"*, and ADR-050 settled which way that cuts: **suspend with forced resume**, because *"disconnecting is never an escape from a bad run."*

That sentence is the whole feature, and it is what every decision here serves.

### A live run is the only run you may have

`MainMenu._enter()` checks the file before it checks anything else. A live run is not a prompt, it is the answer — there is no fresh descent on offer while one is open.

**Ahead of the class gate deliberately.** A suspended run already has a class, and asking again would open the one escape this exists to close: quit, come back as somebody else, keep the tree. The ordering is the rule.

`_end_the_run()` is the only thing that clears it, reached by extraction and by the wipe and by nothing else. There is no path from the pause menu to it, which is the property rather than an implementation detail.

### The generous resume was the real hazard

The obvious failure of a suspend feature is that it lets somebody escape a bad run. The obvious failure of *fixing* that is the opposite: a resume that hands back a full floor makes quit-and-relaunch the best way to **farm** one, which turns a feature about not escaping a run into a tool for extending it.

`stripped` is set the moment a floor lays its loot, and a resumed floor lays none. One flag rather than a ledger of what was taken, because the true sentence is about the floor — *you have already been through here* — and a ledger belongs to `M4-T01`, when a seed makes "this floor" mean something across processes.

What is **not** restored: which enemies are dead, which rooms are cleared. `Q43` already says the Hunt repopulates cleared space, so a resumed floor is a populated one.

### Opposite decision from `SaveFile`, on purpose

An unreadable **profile** is kept (`M3-T06`, ADR-117) — a lineage is not replaceable, and destroying one because a parser was unhappy is the fault that ADR found by planting. An unreadable **run file** is dropped, because keeping it would block every future descent forever and what it costs is one run.

Two files, two policies, and the asymmetry is the reasoning rather than an inconsistency.

### `as Dictionary` throws where null was expected

`read()` did `var run := parsed as Dictionary` on `JSON.parse_string`'s result. On a non-Dictionary Variant that **raises** — *"Invalid cast: could not convert value to 'Dictionary'"* — rather than yielding null, and the throw aborted the function **before** the branch that drops the bad file. So the exact case the branch existed for left the garbage on disk, which is the failure mode it was written to prevent, reached through the line meant to prevent it.

`typeof(parsed) != TYPE_DICTIONARY` now. Second time in two tasks a Godot API has differed from its obvious reading, after `material_override` versus `set_surface_override_material` in the headless renderer (ADR-130).

### An action the code under test swallowed

The row proving a resumed floor lays no loot called `_spawn_loot()` and compared counts. It read *5 before, 5 after* and passed with the `stripped` check **deleted** — because `_fixtures_placed` was already true from the level's own build, so the second call laid nothing whatever the run file said. It was proof that calling `_spawn_loot()` twice does nothing, which was never in question.

Tenth assertion this milestone that could not fail, and a **new variant**: the previous nine were setups that never established the precondition. This one established it correctly and then had its *action* silently swallowed by a guard inside the code under test. Clearing `_fixtures_placed` is what makes the call a resume rather than a repeat, and it is the only way one process can stand in for a relaunch.

---

## ADR-133 — She'll only remember three things

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T05`** · **Builds ADR-003, ADR-006** · **Save v7**

**Context:** `M3-T05`. `DES-003` calls the Legacy tier *"the anti-wipe-cliff mechanism, and the piece I feel strongest about"* — one screen doing enormous emotional work, on the oldest trick in roguelite design: **convert the wipe into a decision.** Players remember choices; they resent deletions. None of it existed. Death called `GameState.die()` and the player arrived at the fire with nothing to say about it.

### The life is over before the choice is made

`die()` snapshots the life into `last_life` and **then** wipes. The screen chooses from that record afterwards.

The obvious alternative — offer the choice, then wipe — is wrong in a way that matters: a wipe that waits on a decision is **a life you keep by not deciding**, and quitting at that moment would be exactly the escape `M3-T15` closed a task ago. `last_life` is LINEAGE tier, so coming back later and picking is allowed; coming back later and being alive is not.

It also keeps `TEC-003`'s death operation the one-function thing it is meant to be: delete LIFE, keep LINEAGE, move LEGACY across. The snapshot is one line at the top of it rather than a new flow wrapped around it.

### Three panels, and the order is the argument

| | |
|---|---|
| **What you learned** | ADR-006: *no run can ever return zero*, and the death screen must show what was **gained**. First, because it is the answer to the question a player is actually asking. |
| **What she keeps** | ADR-003: three slots, one item or one node each, **never raw Boon**. |
| **Who you are next** | ADR-009: death is the door to a new class. `M3-T02`'s screen, reused rather than rebuilt. |

`PRO-001` insisted these are **one flow, not two screens**, and the reason is mechanical: a Rite node in a slot only applies if the next life repeats that class, so the choice and its payload must be made in sight of each other. Panels on one object rather than a scene each is what makes that structural instead of a note.

**The refusal of Boon is on the *kind*, not on a list of ids.** ADR-003's argument is that a fungible payload is the optimal pick every time and collapses the screen into percentage retention with extra UI — so anything that is not an item or a node is refused, and a future currency cannot arrive through a gap in a denylist.

### Scarred is two halves, and shipping one is shipping none

`DES-003`: *"carried through death at reduced power and cannot be tributed. They're a head start, not a stockpile."*

`check_dead.py` caught the first draft with `scarred_power` **unread** — the tribute rule was built and the power rule was a number in a file. The scale lands on **damage alone**, deliberately: a Scarred blade that also swung slower would be two penalties for one sentence, and `DES-009`'s timings are what a player reads a fight by. It hits softer; it does not handle like a different weapon.

The tribute half bites where value is **counted** rather than where items are stored — `total_tribute`, `richest`, `GameState.tribute` and the Tithe all read `tribute_worth()`. Otherwise a Legacy slot launders a hoard through a life you were going to lose, which is raw Boon arriving through the door marked *item*.

A kept **node** is simply already bought. That raises the new life's rank and therefore its Tithe from the first cycle — measured: rank 2, owing 85. You begin stronger and owing more, which is `DES-003`'s coupling holding across death rather than being dodged.

### `check_dead.py` found the join, for the second time this milestone

`--legacy-probe` proves every rule inside the screen. **Nothing proved the Threshold ever opens one** — the composition, which is the shape ADR-105, ADR-108, ADR-110 and ADR-117 all had. It surfaced as an orphaned `legacy_screen()` accessor, exactly as `ask_to_unequip` surfaced a one-way equipment slot at `M3-T07` (ADR-127).

The tool only asks whether a name is referenced, and says so about itself. *"Nobody references this"* keeps turning out to be a reliable smell for *"nobody built the join."*

### Three uncaught plants, three different faults

- **The cap row could not fail.** It offered exactly three things against a cap of three, so deleting the cap changed nothing. Eleventh assertion this milestone that could not fail. There is a fourth thing now, and the probe **names** what it keeps rather than looping `offers()` — which had made both the cap row and the rank row hostage to an ordering neither is about.
- **A plant that was a no-op.** Reordering `carried.clear()` ahead of the snapshot proves nothing, because `_remember_the_life` never reads `carried`. The real violation is taking the record after `stash` and `taken` are gone.
- **A plant whose expectation could never match.** Built with a `.replace()` that left a double space, so it would have reported NOT CAUGHT against correct code forever. The mirror of the `label + FAIL on one line` fix from `M3-T09`: there, the matching was too loose; here, the expectation was simply wrong.

And one row was wrong rather than the code: it asserted a kept node raises rank, using a **lesser** node worth 1 Boon when rank 2 needs more. The claim was never true of that life.

---

## ADR-134 — A run ends on evidence, and never interrupts itself to say so

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T08`** · **Builds ADR-050's rescue clause**

**Context:** `M3-T08`. `DES-016` wants 40–60 deeds at 1.0, weighted toward rescue, refusal and memorial. None existed, and the profile had no record of anything a lineage had ever done.

### The doc supplies its own test for what may be a deed

> *"Deed conditions are evaluated by the run systems that already exist — extraction state, ember events, Clamor history, loot decisions. No bespoke tracking subsystems; **if a deed needs new instrumentation, it's probably the wrong deed.**"*

So the five that ship are exactly the five extraction state can already answer: you got out, you carried somebody's ember, your bag was empty, the Prize is still down there, you left on almost nothing. **Not one of them added a field.**

`DeedResource.CONDITIONS` is a **closed list**, and `validate()` refuses a deed waiting on anything outside it. That is the difference between honouring the rule and intending to: a deed that would need new tracking now fails the build rather than quietly arriving with a new subsystem behind it.

Memorial and Calamity are **absent rather than stubbed** (ADR-064). One needs NPCs who die while you know them (`DES-014`), the other expeditions with patterns (`DES-015`) — both `M4`.

### Two rules that a naive build breaks immediately

**No popups mid-run.** `DES-016` states this most firmly of anything in the document, and the obvious implementation — award on the event, show it there — breaks it on the first deed. A deed waits in `fresh_deeds` and surfaces at the Settle beat. The probe asserts the queue rather than the award, because the award is the easy half.

**No checklist.** *"A gallery of everything you haven't done converts the system from evidence into a chore"* (`PRO-005` §11). The banner shows what happened and has **no view of what did not** — there is no completion count anywhere, and no description says how a deed was earned, because ADR-050 makes them secret and found through Bound gossip.

### An empty bag is the done button

`DES-016` puts deeds *"after the tribute decision, so the run ends on evidence of what you did rather than on a balance sheet."* But the tribute decision here is **per item**, made by walking to one side of the room or the other — `DES-019` refuses a confirmation dialog and asks for the decision to be physical, so there is no "done" to hang this on.

An empty bag is that moment: everything you came back with has been given or kept. A run that came back with nothing settles on arrival, which is correct — there was no decision to be after.

### The first time this profile stores anyone but you

ADR-050: *"rescue deeds record who you carried out."* `deeds` is `{id: who}` rather than a list for that one clause. Every other deed stores `""`, and the banner leaves a description's `%s` unformatted when there is no name to fill, because a stray blank reads as a bug and a deed about nobody should not pretend otherwise.

### What the host decides and what crosses

Deeds are worked out **host-side** at the end of the run, because the host is the only peer that saw it. What crosses is a list of ids and a name — `GameState` is never networked (`TEC-004`), so each peer writes its own profile from what it is told, exactly as it does with its haul.

Awarded **before** `die()`, which is what makes LINEAGE tier true rather than merely intended.

Seven violations planted, all caught first time — the first task this milestone where that happened. Worth noting only because eleven assertions before it could not fail: the difference here is that every row asserts a *state change* (queued, recorded, spent, survived) rather than a value that might have been correct already.

---

## ADR-135 — Get in, get out, never fight

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T12`** · **Second Aspect (ADR-125)** · **Completes the Veiðimaðr's pair**

**Context:** `M3-T12`. `DES-004` gives five Aspects; `M3-T01` built the Hoard and the machinery under it. The Wing is the Veiðimaðr's primary and the second Aspect the design needs before *"one primary with its keystone, one secondary without"* means anything — until now there was nothing to be secondary.

Pure content against proved machinery, which makes the failure mode specific: not *does the tree work*, but **does each node do anything at all.**

### A node whose system has to be invented is a system arriving through a `.tres`

The first draft had three nodes with no reader: `no_fall_hurt` needs fall damage, which this game does not have, and `read_the_seal` / `remember_the_door` need a HUD element that does not exist. All three were **replaced**, not implemented — building a system to justify a node inverts which one is the requirement.

That is `DES-016`'s test for deeds — *if it needs new instrumentation, it's probably the wrong one* — applied one document over. The replacements gate numbers that were already there: extraction Clamor, `revive_clamor`, `shaft_channel_seconds`.

### The keystone's drawback is not in the document

`DES-004` sketches *Never Where She Struck* — return to where you stood three seconds ago, once per floor — and states the rule that governs every keystone: **each has a real drawback**, because *"a keystone without a cost is a stat stick with a portrait."* It does not say what this one's is.

**The ground you left roars.** You escape the blow and tell the whole floor which room the fight was in — `M3-T11`'s *loud somewhere you are not*, aimed at yourself. Escape as identity, paid for in attention rather than in a number.

Fired **after** the damage lands, deliberately. A keystone that cancelled the blow would be invulnerability once a floor, which is not what escape means.

### Changing a tree changed nothing

The block pushing effect tags into `Inventory` and `Stamina` lived in `_ready()` and ran once. Invisible in play, because effects arrive on the spawn payload before a bag holds anything — so nothing had ever changed a tree and looked.

`--wing-probe` sets `effects` directly and two nodes did nothing at all. It is `_push_effects_down()` now, called from `_redress()` as well.

**This would have taken `M3-T13` with it.** Respec is a tree that changes inside a life; that is the whole task, and this is the line that would have made it silently not work.

`check_dead.py` found a third: `refresh_recall` was unreachable, which made *once per floor* mean once per **life** — a different node, and a much worse one.

### One row, three ways of being green and wrong

The crouch row took three passes, and each fault alone produced a pass:

1. **It assigned `stance` directly.** `_update_stance` recomputes it from the crouch action every frame, so the assignment was gone before the next tick and **both walks measured a standing body**. The node under test never applied.
2. **It measured a delta from a reset `clamor.level`.** A `ClamorSource` decays toward its carried floor rather than to zero on demand, so the second reading was always ~0 — and with the reader deleted it still read *1.83 → 0.00*.
3. **It compared two nearly-equal noisy numbers.** Crouched footsteps are 0.33 and the planted value 0.34, so `quiet >= loud` passed **about half the time**. Two green plant runs are not evidence of determinism, and were reported as though they were.

It asserts against **zero** now, which is deterministic and is the actual claim: `DES-004` rule 2 says the multiplier goes to zero rather than lower, and zero is not a close call. Three consecutive clean probe runs.

Twelfth assertion this milestone that passed for the wrong reason, and the first where the fault was in the **measurement apparatus** rather than in the setup or the claim.

### What the probe checks that nothing else can

Every effect tag is looked up in the source of the systems that could read it. A tag nothing consults **passes every other check in the project** — it loads, it validates, the screen offers it, Boon buys it, and it does nothing. That row is the one this task exists to make possible.

---

## ADR-136 — A build can be reconsidered; a keystone cannot

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T13`** · **Closes `M3`** · **Settles `DES-004`'s respec ⟨tune⟩**

**Context:** `M3-T13`, deferred out of `M3-T01` by ADR-125 on ADR-064's sanctioned-exception test and placed after `M3-T12` deliberately — a respec into an Aspect that does not exist is a resource cost tuned against a decision nobody can make. With the Wing built there are two paths, and the choice is real.

`DES-004`: *"A respec exists but costs real resources and cannot change your keystone mid-life ⟨tune⟩. Locking the keystone is what makes the choice matter."*

### The resource is the Boon that does not come back

No new currency and no second economy. A reclaimed node refunds `respec_refund` of what it cost, and the shortfall is the price — which scales with how much of a build is being unmade, and that is the right shape: reconsidering one lesser node should not cost what abandoning a whole path does.

`validate()` refuses a fraction at or above 1.0 (a free respec is not a choice) and at or below zero (that is a delete, not a reconsideration).

### Two refusals, and only one is in the document

**The keystone does not come back.** `DES-004` verbatim, and it is what makes a build a commitment rather than a loadout. Death unmakes it; nothing else does.

**A node something else stands on does not come back either.** This one is not in the document and has to exist: `why_not` is asked when a node is *taken* and never again, so without it a tree can be left holding a node whose route was reclaimed underneath it, and nothing in the build would ever object. It also protects the keystone's chain for free, which is the same argument `BULWARK` made at `M3-T02` — one rule, stated where it belongs, and the special case falls out.

### Rank falls, and so does the Tithe

Rank is derived from `taken` (ADR-126), so giving nodes back lowers it — and `tithe_due()` follows. Measured: rank 4 owing 200 becomes rank 3 owing 140 for one lesser node.

That reads like a loophole — strip the tree before a settle and owe less. **Kept, deliberately.** A player who does it has paid twice, in the refund that does not come back and in the build they no longer have, and `DES-003`'s coupling is supposed to run in both directions: power went down, so the obligation went down. Closing it would need a rule the design does not ask for, and the round trip costs the shortfall twice.

### The row only this task can make

A respec is the **one thing in the game that changes a tree inside a life.** `M3-T12` found by accident that effect tags were pushed into `Inventory` and `Stamina` exactly once, in `_ready()` — invisible in play, because the spawn payload arrives before a bag holds anything. This is the only place that can be caught deliberately, and the probe asserts it: a tag reaches the bag, and stops reaching it when the tree loses the node.

### The probe failed on its own premise twice, and once on its own success

Twice before it ran: a route to the keystone that skipped two prerequisites, and a life with no class sworn — `take_node` refused correctly both times and the setup guard said so, which is the right way round.

Then a plant reported **NOT CAUGHT** against a probe that had detected the fault perfectly. The row has a **guard** ("the tag never reached the bag at all") and a **claim** ("the bag kept a rule the tree no longer has"), and the plant tripped the guard while the expectation named the claim. The guard exists because a row asserting the bag forgot something is meaningless if it never learned it — this milestone's most repeated lesson, built in on purpose, and then the harness tripped over it working.

**A plant can legitimately trip either half, and the expectation has to name the one it actually produces.**

### `M3` closes here

Fifteen tasks. The milestone's goal was *prove meta-progression makes runs more interesting, not easier* — and what is now true is that the pact moves, costs, is capped by your own rank, survives death in three named things, is spent on two Aspects with real drawbacks, and can be reconsidered at a price that never includes the one thing you committed to.

---

## ADR-137 — The gate needed a control list, and finding that found three more

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T16`** · **Amends `ART-004`** · **Borrows the display half of `M4-T06`**

**Context:** `M3` closed code-complete at ADR-136 with both gates `pending`, and both gates are human playtests. The pre-gate sweep asks one question — *what would make a tester fail a clause for a reason that is not the design?* — because a gate is only worth booking if a failure points where the clause says it points.

Four faults, none of which any probe could have been failing, because all four are about **what a player is told or shown** rather than what the code computes.

### 1. `GATE M3 EXIT` depends on a screen that did not exist

The protocol reads *"no coaching beyond the in-game control list."* There was no in-game control list. The main menu had five buttons, the pause menu four, `SETTINGS` had volumes and a sensitivity slider, and `ArrivalBrief` names the place, the job and the way home but **no verb**. `project.godot` defines twenty-four actions; contextual prompts existed on `WorldItem` and `Shaft` and nowhere else.

This does not merely fail the *"discovers they can drop loot without being told"* clause — **it contaminates the other three with it.** A tester who never found crouch cannot answer *"how much noise are you making"*, and the failure gets written down against the Ear. That is the expensive kind of wrong answer: it looks like a design finding, and it is a missing menu.

**`ControlsScreen` is generated from `InputMap`**, so the thing that drifts (keys) is derived and the thing that does not (the English name of a verb) is authored. `bind_gamepad.py` rewrites the pad half of `project.godot` on demand, so a hand-written list would have been stale the first time it ran.

**It is not rebinding.** `M4-T06` keeps that. Read-only is honest; a greyed row promising a rebind that does not exist is the stub ADR-064 bans. Reachable from the main menu **above** `SETTINGS` — a person looking for *how do I play* does not look under settings — and from the pause menu, because a player forgets which key drops loot while holding loot.

### 2. The diagnostic overlay could not be turned off

`DebugReadout` was mounted in `room_set.tscn` — the Deep, the level a tester plays — printing health, speed, stamina, cells and kilograms every frame with no visibility gate. The gate requires the overlay off.

It answers three of the four clauses before they are asked. A player reading a health number does not need damage feedback to be legible; a player reading a weight number does not need the bag to be. The session would have come back green on questions it never posed. It shares `debug_overlays` with `DebugOverlays` now and starts hidden, because *the x-ray* is one idea to whoever is tuning and two nodes only by accident of where they had to live.

### 3. On a pad, the Húskarl could not run

`sprint` and `verb` were both bound to `LEFT_STICK`. The comment said *sprinting and planting yourself in a doorway are opposites, so no hand ever wants both in the same instant* — **true about intent, false about code.** Nothing checked context. One click fired both actions, and `_target_speed` returns **zero** while `planted > 0`, so a Húskarl who pressed sprint stopped dead. The Veiðimaðr had the quieter half: sprinting set a snare at their feet and spent the stamina for it.

The claim that made the share necessary — *the pad has no free button* — was **also false**. `BACK` was empty, and `Y` was held by `debug_ink`. A debug toggle owned a face button while a combat verb was unreachable. `verb` takes `Y`; `debug_ink` takes `BACK`.

**The rule now runs rather than being commented.** `SHARED_OK` names the one pair allowed to share — `block` and `rotate_item`, disjoint by the bag, and both halves check it — and every other collision fails `check_project.py`. The test for entry is not *would a player want both at once*, which is an argument about intent, but **does code refuse one of them in the state the other is used in**, which a probe can ask.

Two smaller things fell out. `bind_gamepad.py` could only **add** bindings, so moving one would have left the old button bound and produced an action on two buttons rather than a moved one — a generator that cannot take a binding away is not one you can fix a layout with. And its `--check` ran in `ci.yml` **and nowhere else**, which by ADR-104's finding is the same as nowhere; it is in `check_project.py` now, in the sweep that runs before the commit rather than fifty seconds after it.

### 4. `ART-004` was lying in both directions about assets

`Q94` — *what does the shader read* — was marked **OPEN** with *"decide before Phase 2"*, and ADR-051 closed it on 2026-08-14 with the exact channel table printed three sections above it. The one sentence naming the decision that gates Phase 2 asset production went on saying it was unmade for twelve days. `status.py --check` compares `OPEN-QUESTIONS.md` against every ADR's `Closes:` line in both directions and neither it nor `reindex.py` reads prose inside an `ART-` document.

And **delivery pointed at `game/assets/<category>/`, which does not exist.** `TEC-002` fixes the layout as `game/art/`, `check_project.py` lists `art` in `REQUIRED_DIRS` and would not have created the other one. The first asset delivered by following that sentence lands outside the tree the project checks — on the one page a person reads *because* they do not yet know where things go.

### What this says about the gate, and about assets

`ART-004` schedules Phase 2 at M3: two class models with rigs, hoard geometry, skill-tree and Legacy UI art, the Ear final, a Delvings kit. **That list is written for the milestone and the gate is the last thing in it.** Every clause in both gates fails to a *system* — wayfinding, the Ear, combat readability, the bag, the ember's presentation. Not one fails to a model.

So the gate is run at Phase 1, deliberately, and the assets it needs are: this screen, a Windows build for testers, and confirmation that the ember and the three loot size classes still read at distance in blockout. **If the ember does not read, that is the gate's finding and not a reason to pre-empt it with art** — `DES-009`'s ordering says blockout must feel good unjuiced, and ADR-042 files the ember's read as a prototype question precisely because only a build answers it. Finalising the Ear before the clause that fails to *"the Ear, or clamor legibility"* has been run would be drawing the answer before hearing the question.

One sequencing problem is filed rather than fixed: `ART-004` wants the Delvings modular kit at M3, and `M4-T01` is the generator that consumes it. `game/levels/modules/` is empty and correctly so. The kit is specified a milestone ahead of the system it feeds.

### Verification

Eight plants against the control list, all caught — **after one was not.** The row *"CONTROLS opened and the menu behind it is hidden"* passed with the hide deleted, because the settings block earlier in the same probe leaves `_column` already invisible and never restores it. `_column.visible == false` was true before `_show_controls()` ran. It sets the precondition and asserts the **change** now. That is this milestone's rule arriving in the first check written after the milestone that taught it: *a row that could have passed before the code ran is not a check.*

### The probe proved every row existed, and the screen was cut in half

Every assertion above was green on a screen whose **BACK button was off the bottom of the window**. Stacked in one table the list ran past 648 lines, and nothing could see it: `--menu-probe` counts labels and asks `InputMap` questions, and *the rows exist* and *the rows are on screen* are different claims. Only the photograph showed it — which is what `--menu-shot` was built for at `M2`, and this screen was not in its list.

Two columns now, **split by row count rather than at a written-down halfway point**, because `M4-T06` adds rebinding rows and `DES-009` still owes three combat verbs. And `fits()` measures against `ProjectSettings`, not the live viewport: the headless dummy renderer reports 64×64, so a fit check asked against the running window fails in the sweep and passes nowhere — a check that cannot run. The configured window is the honest question anyway, since it is the one a player gets.

The plant that matters most here is *"one column again"*: reverting the layout to a single table now fails by name. The original bug is the plant.

Three plants against the pad-conflict rule, all caught first time: the old `sprint`/`verb` clash, a `SHARED_OK` entry that stops covering its pair, and a stray joypad event hand-added to `project.godot`.

---

## ADR-138 — A run belongs to a life, and a sweep does not get a run

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T17`** · **Reported from play**

**Context:** the first play of the `M3` build, on the exported macOS app. The report: *"I descended solo but there was no weapon or class selection of any kind."*

Nothing in that sentence is about weapons or class select. It is one fault with four steps, and **not one of the steps is wrong on its own.**

### What actually happened

`user://run.active` was on disk with **no `profile.save` beside it**. `MainMenu._enter()` checked `RunFile.exists()` before the class gate and returned early — correctly, by ADR-050: *there is no fresh descent while a run is open*, and a suspended run already has a class.

Except this one did not. The run file **stores** `class_id`, and **nothing read it**. `check_dead.py` cannot see that: `begin()` is called, so the name is alive. Dead *data*, not a dead name.

So: class select skipped → no class sworn → no kit → empty stash → empty bag → nothing in `MAIN_HAND` → and `MeleeWeapon.request_swing` returns `false` on an empty hand. **The attack button did nothing at all.** No swing, no sound, no refusal. The Threshold never mentions class either, so nothing between the menu and the floor could have said so.

### And the run file was ours

The run was left by a **probe**. Every probe boots a level directly and writes to the same `user://` the editor build plays from, and one that exits between `begin()` and `clear()` leaves a run open. The `M3-T13` session already hit a smaller version of this — a plant left garbage in `user://run.active` and contaminated an unrelated probe two steps later — and the fix then was local to the harness. It should have been this.

**`SaveFile` has had the rule since `M3-T06`: nothing is written back to a file that was never read.** `RunFile` did not, and the difference cost a play session.

### Two gates, and both are load-bearing

`RunFile` is armed by `MainMenu._enter()` — the one way into the game — and by `--run-probe`, whose subject it is. An unarmed process **cannot write** a run and **cannot see** one that is already there.

Both, not either. Planting the read gate's removal alone reported **NOT CAUGHT**: deleting the write gate changed nothing observable, because the read gate hid the file the write had just created. *A guard whose failure another guard conceals is not covered by a row about the other guard.*

Seeing nothing is stronger than refusing to write: an unarmed process cannot resume somebody else's run, cannot clear it, and cannot be confused by it.

### The run file must agree with the life

`resume_is_this_life()` reads `class_id` back and resumes only when it matches the sworn class. Anything else is an **orphan** — a record of where you were inside a life that no longer exists — and is dropped rather than entered. That costs one run, which is what a run file is worth. Entering it costs a descent that cannot be played.

This is also what makes the stored `class_id` load-bearing instead of decorative. The field was always right; nothing ever asked it.

### And the Threshold refuses too

Not a second copy of the rule. The menu decides whether a **run** may open; the Threshold decides whether a **body** may go down, and `M2-T15` proved a level can be reached without passing through the menu at all. Standing at the hole sworn to nothing now says so instead of silently working.

### The failure deleted its own witness

Both plants for *"a life sworn to nothing walked into the hole"* passed **silently**. `_descend` is `call_local` and ends in `change_scene_to_file`, so the body reaching the hole freed the node holding the assertion; the Deep came up with no probe flag and the process exited zero. A green row, for a fault that had just occurred.

`room_set` has had `_probing` swapping the scene change out since `M2` and says why in as many words. The same word now exists here — **with its exception named**: `--doorway-probe`'s whole subject is the transition, so holding the scene makes it fail by definition, and it did, immediately. `room_set` dodged the same collision by keeping "probe" out of `--extraction`'s name; naming the exception is the more durable half of that lesson, because the rule then survives somebody renaming a flag.

### Verification

Six plants on the resume guard and three on the descent guard, all caught — after three were not, each for a different reason worth keeping: one guard concealed by another, and a failure that destroyed the probe observing it.

The accepting half of the descent is asserted through the **predicate** rather than by walking into the hole, because walking into it is the thing that cannot be survived. That direction is already proved where it belongs — `--menu-probe`'s `_walk_the_loop` presses Descend and asserts it arrives in the Deep.

---

## ADR-139 — Four control lists, one of which I had just switched off

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T18`** · **Corrects ADR-137** · **Reported from play**

**Context:** the same play session as ADR-138. The second half of the report: *"there was no real guidance once in a level."*

### ADR-137's premise was wrong

It opens *"there was no in-game control list."* There were **four**:

| Where | Devices | State |
|---|---|---|
| `threshold.gd`, the fire's readout | keyboard only | omitted **block** and **the class verb** |
| `debug_readout.gd`, two lines at the bottom | both | said `i/Y ink` — stale the moment ADR-137 moved it to Back; never named the verb |
| `bag_screen.gd`, the footer | both | bag-only, and correct |
| `ControlsScreen` (ADR-137) | both | generated, complete |

Three hand-typed, two already stale, and **not one of them named the class verb**. `F` was a built verb — `M3-T02`'s Hold and `M3-T11`'s Snare, a whole milestone of work — that no player could discover.

That is worse than the thing ADR-137 said it was fixing, and its ADR said the opposite. **A stale ADR is believed**, which is the whole reason this project writes them.

### And ADR-137 made it worse before this fixed it

`DebugReadout` was two things fused into one node: the **diagnostics** — health, speed, stamina, carrying, clamor — and the **player's in-level control list**, two `lines.append` calls at the bottom.

`GATE M3 EXIT` requires the diagnostic overlay off. ADR-137 gated the node, correctly, and took the only in-level control reference in the game with it. The very next play reported no guidance in the Deep.

**One node doing two jobs with opposite audiences.** Hiding it for one broke the other, and nothing could have caught that: no probe reads a `Label` for guidance, and `check_dead.py` sees a node that is used.

### One table, three renderings

`ControlsScreen.GROUPS` is the source. Each row is `[full label, short label, actions]`, and two renderings hang off it:

- **`glyphs_for(action)`** — one binding as `"e/X"`, for a contextual prompt. The bag still says *take & place* where the screen says *pick up, and place in the bag*; that is a real difference of context, not drift. **Only the keys come from the table, because the keys are the half that moves.**
- **`compact_lines(per_line)`** — the whole list as running text, for a readout that is a `Label` rather than a screen. The Threshold uses it.

`DebugReadout` keeps only the diagnostics, which is what it always should have been.

### What the generated half structurally cannot say

**Mouse look is not an `InputMap` action.** It is raw motion, so no amount of reading the bindings will ever mention it — and the hand-written line it replaced did say *mouse look*. The row's authored label carries it: *"Look around — or just move the mouse"*.

This is the division the design already asks for. What drifts is generated; what does not is written down. A thing that can never be derived belongs on the authored side, and noticing which side it falls on is the whole job.

### Guidance in the Deep

`DES-019` is hostile to persistent UI and this does not add any. `ArrivalBrief` — which holds for 4.5 seconds and then frees itself — gains a fourth line naming the key that opens the menu, and the pause menu has carried CONTROLS since ADR-137. A player who forgets a key forgets it under pressure, and the answer is one press away instead of back at the fire.

### The check that makes it stay one list

`check_project.py` refuses any **string literal** outside `controls_screen.gd` that names a key: `wasd`, `lmb`, `dpad`, `/RB`, `shift/`, and the rest. Comments are exempt deliberately — the ADRs are written in the files they describe and quote the strings they replaced. What is banned is *shipping* a second list, not remembering one.

And a probe row the hand-written lists made impossible: the fire's readout must contain **every line the control screen teaches**, and must name the class verb. A hand-typed list is always internally consistent right up until it is wrong; the only way to ask whether it is *complete* is to compare it against the table.

### Verification

Five plants, none uncaught: the fire typing its own list, the bag typing its own keys, the fire teaching nothing, the verb falling off the table, and the table rendering nothing at all.

---

## ADR-140 — A dead button and text on top of text

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T19`** · **Reported from play**

**Context:** the last two items from the first play of the `M3` build. *"No weapon"* — after ADR-138 explained why there was none — and *"the UI is showing some text on top of others in the inventory."*

### An empty hand said nothing at all

`MeleeWeapon.request_swing` returns `false` when nothing is wielded, and did nothing else. No sound, no motion, no refusal. **Indistinguishable from a broken build**, and principle 4 has no one-sentence explanation for *the button does nothing*.

**Deliberately not an unarmed attack.** A punch is new combat content — reach, damage, timing, and a place among `DES-009`'s five verbs — and inventing one here would be answering a legibility question with a balance change. This is the refusal, said out loud.

**Two channels**, because `DES-018` requires the build to be completable muted: a dull `THUMP`, and the reticle flinching **inward** — the same four ticks it opens outward when a thing comes into reach, run backwards. Motion rather than a new symbol, on `Reticle`'s own standing rule, and the two never draw at once because nothing is in reach when this fires.

`empty_hand_gap` ⟨tune⟩ because attack is held down under pressure and a cue every frame is a rattle nobody reads as a refusal. Two rows, not one: **without the gap it rattles, without the tick it fires once per life and goes silent** — which is the silence it was built to replace. Each failure looks like the other's fix.

### The blurb drew through the prompts

Reproduced on the first attempt, and photographed: *"make one and regret continuously."* drawn straight through *"lmb/X take & place"*.

`BLURB` was **34 px** and holds a name line plus up to two wrapped description lines — **58 px** by the font's own metrics. The third line landed inside the footer.

Two reasons nothing saw it, and they are the same reason twice:

- **`overflowing()` measured widths.** Header width, footer width. It never asked whether a *block* fits its height, and the blurb is the only region here whose height is not fixed.
- **Every bag screenshot ever taken had nothing under the cursor.** `--bag-shot` opened the bag and photographed it, so the one region that draws variable-height text had never once appeared in a photograph. It hovers now, through a real motion event, on the same reasoning the shot already used for opening the bag: reaching in to set `_cursor` would photograph a state the mouse cannot produce.

The band is measured against the font now rather than against a remembered number, so raising `BLURB_TEXT` or allowing a third line fails in the sweep instead of on somebody's screen.

### And `0.04 kg` in a 36-pixel cell

Rendered as `0.04 k`, which reads as a broken renderer rather than as a weight. The unit is dropped in a one-cell footprint: every number in this panel is kilograms and the header says so two inches above, so the digits are the part worth keeping.

**The check for it is coarser than the screen it defends**, and that is worth writing down. Restoring the unit does *not* fail the new row — the headless dummy renderer's font metrics are a few pixels more generous than the real one, so a marginal overflow measures as a fit in the sweep and clips in the window. Planting a long string does fail it, so the row is live rather than decorative. But the four pixels that started this were caught by a **photograph**, and no headless check was ever going to.

### The counters were lying

The refusal rows first reported *zero cues* against a refusal that was firing perfectly. **A GDScript lambda captures a local by value**, so `func(): count += 1` increments a copy and the outer `int` stays zero. `--toll-probe`'s `shrugs` array has been working around this since `M2`; the array is the idiom, and an `int` is the trap.

Worth stating plainly because the symptom is a *green-looking failure*: the probe said the feature was missing, the feature was present, and the wrong one of those got believed for a minute.

### Verification

Five plants on the refusal, three on the bag. One reported NOT CAUGHT while failing correctly — the plant tripped the *cooldown* row and the expectation named the *silence* row, which is ADR-136's guard-versus-claim mistake arriving for the second time. **The plant has to name the row it actually produces.**

---

## ADR-141 — A death screen on a life that had just begun

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T20`** · **Reported from play**

**Context:** *"I exited the game and when I started it and descended again it had an overlay like I was dead right off the bat but I was still able to attack in the background just not walk or close the death screen."*

Four defects, and the player's own profile proved the first one:

```
legacy.last_life.class_id = "veidimadr"   ← a life that died, never answered
life.class_id             = "huskarl"     ← a new life, already sworn
```

### 1. The class question was asked twice, in two places

`die()` clears `class_id` **and** leaves `last_life` behind, so both questions look open. They are the same question. `DES-003` gives it to the fire as **one flow** — what you learned, what she keeps, who you are next — and `PRO-001` says *"one flow and not two screens"* for a mechanical reason: a Rite node in a Legacy slot only pays out if the next life repeats that class, so the class and the slots must be chosen in sight of each other.

`MainMenu._enter()` asked anyway, then changed scene. The Threshold, still holding an unanswered `last_life`, opened the Legacy screen **on a life that had just begun**. And the second answer was silently discarded: `take_the_oath` refuses to overwrite an existing oath, and `ClassScreen` emits `chosen` regardless of whether it succeeded.

The menu asks only when nobody is waiting to be buried.

### 2. A screen over a live body could not be used at all

`set_driving()` gated exactly one thing — `_wish_direction()`. So a screen opened over a body stopped the feet and nothing else. The body went on swinging, went on turning, and went on **recapturing the mouse every frame** in `_update_bag`. A second recapture sat in `_unhandled_input`, so the first click aimed at a button stole the pointer instead of pressing it.

All three halves of the report are that one fact: *attack in the background* (never gated), *not walk* (the only thing that was), *not close the death screen* (no cursor).

`PauseMenu` was the **only** caller of `set_driving` and the only screen that worked. It is the seam now: movement, the attack, the guard, the class verb, the bag, drop, throw, interact, the Waystone and the cursor all hang off it in one place.

### 3. Nothing in the game grabbed focus

`LegacyScreen`, `ClassScreen` and `PactScreen` contained **zero** `grab_focus()` calls between them. With the mouse captured and nothing focused there was no input path at all — not one device, not either. ADR-075 makes controller parity a project rule; a screen a pad cannot move around in is the same bug as an action with no pad binding, and it had gone unnoticed in all three.

The Chamber's Pact screen had the identical fault. It set `MOUSE_MODE_VISIBLE` directly and the body underneath set it straight back on the next frame.

### 4. Every probe pressed the buttons by calling them

`press()`, `press_give_back()`, `finished.emit()`. That is the right way to assert what a screen *decides*, and it is exactly why nothing caught any of the above: the screens were fully tested and completely unreachable.

So `--threshold-probe` now presses **`ui_accept` through `Input.parse_input_event`** and asserts the Legacy screen moves off panel 0. Three preconditions guard it — the body is not driving, something has focus, the body does not want the cursor — and then one claim that a press arrives.

### The row that could not fail, caught by planting it

The cursor check first read `Input.mouse_mode`, and deleting the `_driving` term from the capture rule changed **nothing the sweep could see**: Godot's headless dummy display ignores `mouse_mode` entirely, so the probe read `VISIBLE` whether the code was right or wrong. `pointer_captured()` exposes the **decision** instead, which is both testable and the part that was actually wrong.

Third time this milestone that a headless renderer has been more generous than the real one — after the bag's font metrics and the 64×64 viewport. **What the engine does in `--headless` is not evidence about what it does in a window.**

### Verification

Seven plants, none uncaught: the menu asking twice, the menu never asking, the body still driving under a screen, nothing grabbing focus, the cursor rule losing its `_driving` term, a press reaching nothing, and the controls never coming back.

---

## ADR-142 — The check about pursuit excluded the pursuer

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T21`** · **Reported from play**

**Context:** *"The hunter and enemies still path into walls and get stuck."*

### The Gullsjúkr had no navigation at all

Not intermittently — **at all**. `_walk` computed `to_goal.normalized() * speed` and `move_and_slide()` ground it along whatever stood between. `gullsjukr.gd` contained zero references to `NavigationAgent3D`. The one body that pursues you across the entire floor was the one body with no path.

`Enemy` has had an agent since `M2` and its steering is the shape to copy: path at range, walk directly when close or when the map has nothing to say. That is one idea about how a body crosses a floor, so the Hunter uses it rather than a second one.

### And the check that should have caught it asked the wrong group

`--nav-probe` asserts every body has an agent bound to a valid map, and walked `"enemies"`. The Gullsjúkr is in `"hunters"`.

It is fixed as a **list of groups**, not by adding one name, because that is the shape of the fault: the next thing that walks the floor arrives with a group of its own and a check naming one group exempts it silently. And a row now fails if no hunter is in the census at all — narrowing the list back would otherwise shrink the check in silence, which is exactly how this went uncovered.

### An agent nothing reads is the straight line with extra steps

Deleting the block in `_walk` that consults the agent passed **everything** — ADR-098's question arriving on the fix for ADR-098's question. `--hunt-probe` asserts the Hunter actually asked: `target_position` starts at the origin and is only ever written by that block, so a non-zero value is proof it ran.

### The probe that broke was measuring the route and calling it the goal

`--hunt-probe`'s oldest row parks the player in the west corridor, makes them loud, teleports them east and silences them, then asks whether the Hunter walked west. It compared displacement against two reference directions **56° apart** and read the winner as evidence about what the Hunter *wants*.

That inference held only while it walked in straight lines. The moment it had a path, a waypoint a metre off the direct line flipped the comparison — and the row failed on a change that never touched goal selection at all.

`TEC-001`'s claim is about the **goal**: it walks up the clamor gradient and never reads a player transform. Giving it an agent made that goal a *public fact* — `target_position` is where it is trying to get to — so it is asserted directly now: **1.0 m from the sound against 18.0 m from where the player hid**, where the old row was deciding on tenths of a metre of drift. Plus a separate row that it actually set off, because wanting the right place and never leaving is the same to a player as ignoring the noise.

A fix that makes an existing check *sharper* is worth more than the fix.

### What this does not solve

**The Hunter's collider is 0.75 and `room_set` bakes the mesh at 0.45.** The path is planned for a body narrower than this one, so corners will still catch it. That wants either a second bake at the Hunter's radius or path smoothing away from walls, and it belongs with `M4-T01` — the mesh is hand-authored until then. This stops it walking *into* walls; it does not yet stop it clipping their corners.

The ordinary enemies keep two rough edges, both deliberate for now and both measurable rather than guessable: `avoidance_enabled = false`, so bodies shove each other; and a 2.5 m direct-line fallback that is wrong when a wall separates two points 2 m apart. `M3-T22` measures wall contacts before tuning either.

### Verification

Four plants, none uncaught: the Hunter losing its agent, the census emptying, the Hunter leaving the `hunters` group, and the steering ignoring the agent it carries.

---

## ADR-143 — A run is a descent, and the haul is part of the life

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T23`** · **Save v8**

**Context:** two persistence gaps found while tracing ADR-141's menu flows. Neither was reported from play, and both cost a player something real and silent.

### The run began in one place and should have begun in three

`MainMenu._enter()` called `RunFile.begin()` on the route where a class was already sworn. The class screen changed scene **without it**. So a first life — and **every life after a death** — went down with no run file, and ADR-050's *quitting mid-run is never an escape* did not apply to the two cases a player meets first.

Nothing could have caught it. No probe walked the class-select route into a descent, and a missing run file is indistinguishable from a finished one.

It moves to **`Threshold._descend()`**, which is the honest moment: a run **is** a descent, and it is the one line every route into the Deep passes through. ADR-138's arming rule keeps it safe — a probe booting the Threshold directly is unarmed, so `begin()` is a no-op there.

### What you walked out with was never written down

`GameState`'s own header table has said since `M3-T06`:

> | **What you carried** | Survives a run: only if you extracted |

It did not survive a **quit**. `bring_home()` set `carried` and called `_persist()`, and `to_dict()` had no field for it — so extracting, landing at the fire, and closing the game lost the entire haul before the Chamber ever offered any of it. The Settle beat happens in the Chamber and the fire is where you land; the gap between them was a hole in the floor.

Save **v8** writes it, in the LIFE tier beside the stash, because that is what it is: `die()` clears it in the same breath, and `DES-012` is explicit that dying costs you the bag outright. Ids only, on the stash's own reasoning — the Chamber re-mints a fresh `ItemInstance` when it hands the haul back.

`_migrate_7_to_8` fills in `[]`, and empty is the **honest** value rather than a default: a v7 profile was written by a build with no field for this, and the only moment it could have held anything was a window that ended when the process did, because the value was never on disk.

### The read was right, the write was right, and the last line threw it away

The round-trip row failed, and the write was verified correct on the first look: `to_dict` put `["glt_altar_plate"]` on disk, and `from_dict` was seen receiving it. The restore ran. The size was still zero.

`from_dict` ended with **`carried.clear()`** — a line that had been correct for as long as nothing wrote the field. A loaded profile genuinely could not be carrying anything, so emptying it was the honest reading of the data. Once v8 wrote the field, that same line silently undid the restore twenty lines above it.

Worth recording as a habit, not a bug: **three wrong guesses went into the new code before the old line was read.** The instinct to distrust the thing you just changed is usually right and was exactly wrong here — the defect was a correct statement about a world that had stopped being true.

### Verification

Five plants, none uncaught: the haul unwritten, the haul unread, the old `carried.clear()` restored, the migration removed, and the descent opening no run.

---

## ADR-144 — Measuring how the floor is walked, and finding the probe stuck instead

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T22`** · **Completes ADR-142**

**Context:** ADR-142 gave the Gullsjúkr a path and deliberately left three tuning questions open, each argued from a reading of the code rather than from a number: its collider is **0.75** against a mesh baked at **0.45**, `Enemy.avoidance_enabled` is false, and steering drops to a straight line inside `DIRECT_RANGE`. None of those should be answered by opinion.

`--nav-probe` asks whether a path *exists*. It cannot ask whether a body actually gets anywhere, and that is the symptom that was reported.

### What it measures

One body starts in each room and walks to the exit **through its own real steering** — an `Enemy` returning `_home` is `_act`'s own unaware branch, not a route driven from outside — and every frame in contact with a wall is counted.

**Arrival is not the claim; movement is.** How far a body gets in a fixed time is a function of speed and distance and says nothing on its own. A body that moved **less than its own width in twenty seconds** is stuck, and that is true whatever the clock says. The scrape percentage is printed as a **number, not a threshold**: it exists so `M4-T01` can argue about the three questions above from a baseline instead of from a reading.

**Baseline, this floor:** every room reaches the exit within 0.4 m, scraping a wall between **0.0% and 2.8%** of the way.

### Three faults in the measurement, before it measured anything

The first run reported **every body rubbing a wall 100% of the way** and eight of nine stranded. All three were the probe's.

- **It counted the floor.** `get_slide_collision_count() > 0` is true every frame for anything standing on ground. A contact is a wall when its normal is roughly horizontal.
- **It measured the garrison too.** The floor already carries authored enemies, so nine rows appeared for five labels and the report was unreadable.
- **It ran for four seconds.** `enemy_walk_speed` is 2 m/s and the far corners are forty metres apart, so it measured nothing but how far a body gets in eight metres.

### And then it blamed the level for its own spawn point

With those fixed, one body still never moved: the west corridor, **0.82 m off the navmesh** against 0.15 m everywhere else, scraping 100%.

That reads exactly like the reported bug, and it was about to be written up as one. It is not. `LANDMARKS["west"]` is a **barricade at `(-9, -10)`** — which is precisely `_room_centre("west")`. The probe spawned a body inside the scenery and reported it as stuck on the floor's geometry. It was stuck on the probe's.

Spawns snap to the nearest navmesh point now, and the off-mesh distance is printed beside every row, because *"was it ever standing on the mesh"* is the first question to ask about a body that will not move and the last one anybody thinks of.

**Worth recording plainly: a measurement built to find a fault found itself three times before it found anything else.** Every number a new probe prints is a claim about the probe until something independent agrees with it.

### Verification

Three plants, none uncaught: nobody walked at all, the steering deleted, and spawns returned to the room centres — the last of which reproduces the false positive above, so the fix for it cannot silently come undone.

---

## ADR-145 — The sweep was deleting the player's save

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T24`** · **Extends ADR-138**

**Context:** found while rebuilding for a playtest. The reporter's profile — the one whose contents diagnosed ADR-141 an hour earlier — was **gone**, and it had not been touched by anything a player did.

`SaveFile.wipe()` deletes every file beginning `profile.save`. Three probes call it: `--save-probe`, `--class-probe`, and `--menu-probe` through `_walk_the_loop()`. Every one of them boots a level directly into the same `user://` the game plays from.

**So every full sweep destroyed a real lineage**, and did it in silence: nothing in the sweep's output says a save was deleted, and the game creates a fresh one on the next descent as though nothing had happened. `DES-014` calls the hoard *"a permanent physical monument to every life you have lost"*, and the check that guards it was removing it.

### Why ADR-138's answer is the wrong shape here

`RunFile` refuses to see or touch its file in an unarmed process. That works because no probe except `--run-probe` has any business with a run file.

The save probe's **whole subject** is writing, wiping and migrating. Refusing it the file would delete the check. So it gets a **different file** instead, which is what a test fixture has always been: `PATH` and `TMP` become `static var`s, and the probes redirect them to `user://profile.probe` for the life of the process.

`wipe()` keys off `PATH.get_file()` rather than a literal, or a scratch run would still match — and delete — the real profile by name.

### It took two passes, because two of the three were obvious

Redirecting the save and class probes was the fix that suggested itself. A full sweep still came back with the profile gone, and only then did `--menu-probe` turn up: `_walk_the_loop()` wipes between stops, and it is a check about *scene paths* that happens to clear state on its way through.

**The two that wiped in a function named for saving were found by reading. The third was found by planting a profile and running the whole sweep over it** — which is the only method that could have found it, and is now the check: a real profile with a hoard of 999, a full sweep, and the value still 999 afterwards. Verified across `check_scripts.sh`, `run_coop.py --smoke`, `check_determinism.py` and `export_build.py`.

Both probes also carry a guard that fails loudly if they are ever pointed back at `user://profile.save`, because the failure they prevent is invisible in the output and permanent on disk.

### The shape of the fault, for next time

Three sessions in a row have now found the same thing wearing different clothes: **a probe writing to the place the player keeps something.** ADR-138 was the run file. This is the profile. Both were found *after* they had cost something real, and neither was visible in a passing sweep.

The general rule that falls out: **a check that writes to `user://` must name the file it writes to, and it must not be the one the game uses.** Two down; anything added later that touches `user://` gets the same question asked of it before it lands.

### Verification

A profile planted with a distinctive hoard value, then run over by the complete tooling suite, and read back unchanged. Plus a guard row in each redirecting probe.

---

## ADR-146 — A boolean cannot hold two screens

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T25`** · **Extends ADR-141**

**Context:** reported from play — *"it still showed the death or tithe screen like I was supposed to offer something but had the new run already playing in the background."*

ADR-141 made `Player.set_driving` the seam that decides whether the body answers to input, and it was the right seam: movement, the attack, the guard, the class verb, the bag, drop, throw, interact, the Waystone and the cursor all hang off it in one place. It was left a **boolean**, and it acquired four independent writers — `PauseMenu` twice, `Threshold._hand_over`, and the Chamber's Pact tree twice.

**Screens stack.** `PauseMenu.close()` said `set_driving(true)`, which is a statement about the whole game rather than about the pause menu. So:

1. Die or abandon; arrive at the fire; the Legacy screen takes the body.
2. Press Escape. The pause menu opens on top of it and takes the body too.
3. Close it. The body is handed straight back and **recaptures the mouse**, while the Legacy screen is still up.

The result is the death screen with a live world behind it and no cursor to dismiss it — the same three symptoms ADR-141 fixed, reached through a different door. The Chamber had the identical fault with the Pact tree, and one boolean is why both were possible.

`Player._on_inventory_changed` already carries a comment naming this exact hazard — *"two writers to one number is the second weight path ADR-064 bans."* This was that hazard in the input path, and the comment was one file away from the code that had it.

### A claim is named and held

`_attention` is a list of claim names. The body drives when it is empty. `hold_attention(&"pause")` and `release_attention(&"pause")` replace `set_driving` outright rather than sitting beside it — a screen can only ever give back what it took, and the property is structural instead of a rule every future screen has to remember.

Releasing a claim nobody holds is deliberately **not** an error: a screen freed by its scene going away never gets to release, and a body parked forever is a worse failure than a no-op.

### Why nothing caught it

Every probe in this project drives a screen by calling its methods. ADR-141 added the one row that presses real input, and that row proves the Legacy screen takes the body **when it opens**. Nothing anywhere opened a *second* screen over a first — so the entire fault class was outside what the sweep could see, in both places it existed.

`--threshold-probe` now opens the pause menu over the Legacy screen and asserts three things about closing it: the body still does not drive, the Legacy claim survives, and the pause claim does not. Planted by restoring the old semantics — release every claim on close — which fails two of the three rows.

### Also, while here

`PauseMenu.close()` freed the settings panel and not the controls screen, so a controls screen opened from the pause menu was still standing behind it when the menu reopened, and `_show_controls` refused to build another for the rest of the level.

### Verification

`--threshold-probe`, with the violation planted and the named rows observed to fail.

---

## ADR-147 — A life ends once

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T26`**

**Context:** the other half of the report behind ADR-146 — *"it still showed the death or tithe screen like I was supposed to offer something."* Something to offer, and nothing offered.

`PauseMenu._leave()` calls `GameState.die()` on every ABANDON, with no idea whether anybody is alive to lose. That is the recorded decision and it is right: a menu that let you bank a risky haul by quitting would make every extraction optional.

What it did not account for is that **the pause menu is the only way out of the Legacy screen.** Its third panel is the class choice, which has no back button — by design, because `DES-003` makes this one flow. So a player who dies, arrives at the fire, and decides they would rather not choose a class right now has exactly one door, and it calls `die()` a second time.

The second call runs `_remember_the_life()` over state the first one already wiped:

```
{"class_id": "", "worn": [], "stash": [], "taken": [], "rank": 1}
```

**Non-empty, and recording nothing.** Every consequence follows from that one property:

- the fire goes on asking, because the record *is* the question (`_face_what_happened`);
- the menu goes on **not** asking about a class, because `menu_asks_the_class()` tests `last_life.is_empty()`;
- and the screen offers **zero things**, on a life that had gear, a stash and a bought tree.

So the player is returned, repeatedly, to a death screen about a life the game has forgotten, and the real record — the thing `DES-003` calls the anti-wipe-cliff mechanism — is gone.

### The refusal is in `die()`, not in the caller

`die()` is called from eight places. Guarding the pause menu would fix the one door that is known to reach it today and leave the property depending on nobody adding a ninth.

`life_already_ended()` asks both halves together — no class **and** an unanswered record — because a fresh profile has no class either, and it very much can die.

### Verification

`--legacy-probe` dies twice and asserts the second death changed nothing. Planted by disabling the guard, which fails four rows: the record is overwritten, nothing is offered, the slots pay out nothing, and no lesson comes back. The first of those is the check; the other three are the reported symptom stated three more ways.

---

## ADR-148 — After every death you stood at the fire as nobody

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T27`** · **Completes ADR-141**

**Context:** the reporter's own session log, one line:

```
[coop:solo] peer 1 descends at rank 1 as 'nobody' — the floor is rank 1
```

`CoopSession` declares what this peer is in its `_ready`, and `spawn_player` bakes the class into the spawn packet. Both happen when the level begins. The Legacy screen asks *who you are next* after that — ADR-141 moved it there deliberately, because `DES-003` makes it one flow with the slots and `PRO-001` is explicit that it is *"one flow and not two screens."*

Nothing joined the two up. So after **every** death — not an edge case, the normal path — the body at the camp had no class, no kit, nothing in its hand and plain health, and it came right only on the next scene change, because the Deep builds a fresh session that declares the class the life now has.

That is the fault ADR-141 was reported for, wearing different clothes: a body with no class has an empty hand, and ADR-140 made an empty hand refuse the swing.

### Rebuilt, not dressed

Becoming a class is `spawn_player`'s one job. A second route that dressed a standing body would be the parallel path ADR-064 bans, and it would drift from the spawn packet the first time the packet gained a field. So the body is taken away and the same person is put back, through `CoopSession`, at the same spot.

`redeclare()` is routed exactly like `_ready`'s declaration — locally on the host, by RPC from a client — because the host owns the table, and a client writing its own is the fault ADR-121 avoided for the class arriving through a second door.

**A frame between the despawn and the spawn, and it is load-bearing.** `player_for` finds a body by node name and `queue_free` does not release the name until the end of the frame, so doing both in one breath gives the new body a renamed node — `player_1@2` — that `player_for` can never find again. Planted: the camp came back with **no body at all**, which is ADR-107's grey screen by a new road. The screen is 94% opaque and is held up until after the swap, so the frame with no camera in it is a frame nobody sees.

### Two things that made it worse than it had to be

**`ClassScreen._commit` ignored what `take_the_oath` returned** and emitted `chosen` regardless. `DES-011` locks the class until death and `take_the_oath` is where that lock lives — so reporting past it made the lock true of the rules and false of the game. A screen opened on a life that already had a class told the Legacy flow a decision had been made, and the flow answered by paying out the Legacy slots and clearing the death record on a life that had never ended.

**And the flow asked a question with no answers.** If this life has a class, every button on the class panel would be refused, which is the stub ADR-064 bans. It is reachable: a profile that could not be written leaves `last_life` on disk, so the next launch opens the flow over a live life.

### Verification

`--threshold-probe` drives the whole flow through the class panel rather than emitting `finished`, because the fault was in the join — every rule inside the screen was right, `take_the_oath` was right, and the body three metres away was still `'nobody'`. Two plants: skipping the swear-in (the body stays classless) and removing the frame (the body vanishes).

---

## ADR-149 — She remembered three things forever, and the camp forgot every descent

**Date:** 2026-08-26 · **Status:** accepted · **Implements `M3-T28`** · **Save v9**

Two persistence faults, found while reading the reporter's profile for something else. Neither is a design change: both are the build failing to do what `DES-003` already says.

### 1. The Legacy slots were never spent

`draw_on_legacy()` read the list and left it there. Nothing else ever emptied it — `legacy.clear()` appears in `from_dict` (loading) and in two probes, and nowhere in play.

The reporter's own save is the evidence: `slots: [wpn_yew_bow]` still occupied, `last_life: {}` already answered, the Scarred bow already paid out into the stash.

Two consequences, and each of them is a sentence of `DES-003` being false:

| `DES-003` says | The build did |
|---|---|
| *"a head start, not a stockpile"* | granted a **fresh copy** of everything ever kept, to every subsequent life, forever |
| *"three slots is three slots. It cannot spiral no matter how many lifetimes accrue"* | it spiralled |
| *"slots are chosen at the moment of death"* | once the board filled, `why_not_keep` refused every future pick — the choice was made **once per lineage** |

The last one is the worst, because the screen `DES-003` calls *"a genuinely dramatic screen, and a real decision"* quietly stops being either. So `draw_on_legacy()` spends the board: the kept things become the new life's stash and tree, and the next death is a real choice again.

No ADR was needed to *permit* this — it is the accepted document being complied with. This one exists to record why nothing caught it.

**Why nothing caught it.** Every row of `--legacy-probe` is about **one** death. The fault only exists on the death *after* it, and no check had ever asked a second one. The new rows go last for exactly that reason, and dying twice inside the probe is what made ADR-147's guard show up as a real second death in `--pact-probe`.

### 2. `descents` was never written

It was absent from `to_dict` entirely. It counts how far down this lineage has been, `die()` does not touch it, and it drives two things: the camp readout, and `AudioDirector`'s company layer — the thing ADR-050 built so the Threshold *fills out as the camp does*.

So the camp went back to sounding empty on every relaunch, and the readout under-counted from the second session on. It is LINEAGE tier, beside the hoard, because that is what it is.

**Save v9.** `_migrate_8_to_9` writes `descents = 1`, because an old profile has no honest number to recover — a camp that sounds empty is the truthful reading of a count nobody kept. `from_dict` clamps to at least 1: `AudioDirector` divides by `descents - 1`, and a zero would make a fresh camp sound lived-in from below.

### Verification

`--legacy-probe` asserts the board is empty after a payout **and** that the next death can keep something again; planted by removing `legacy.clear()`, which fails both rows and prints the player-facing consequence verbatim — *"she will remember 3 things and no more"* on a fresh life's first death. `--save-probe` round-trips `descents`, planted by dropping the field. The v1 fixture still migrates the whole ladder to v9.

---

## ADR-150 — Forty-five seconds, and nothing said you could end them

**Date:** 2026-08-27 · **Status:** accepted · **Implements `M3-T29`** · **Option A of the reporter's three**

**Context:** reported from play — *"they bleed out but there is never anyone to save them on a solo run."*

There is someone. Yourself, once.

`Player.ask_to_self_recover()` has been bound to the Waystone key while down since ADR-050 — *"once per run, costly, and never better than having a friend"* — returning 22% health and gone for the rest of the run. `has_self_recovery()` reports whether it is still there.

**It was read by one probe and by nothing else.** ADR-098's question, exactly: it worked, and nothing used it. What a downed solo player saw was *"Bleeding out — 45 s. Your ember will drop where you fall."* — a clock, a shrinking bar, and no indication that the wait was theirs to end. Forty-five seconds, then three more, then a cut to the fire.

### And the Vörðr line was written for a party

*"Vörðr. You are loose, and nothing can touch you. **Scout for them.**"*

Solo there is no them, and the state lasts `party_wipe_seconds` — three seconds — before the run resolves. The reporter read it as written and concluded nobody was coming, which is the correct reading of that sentence and the wrong fact about the game.

The honest sentence is about who is actually left standing, which makes it right in a party wipe too: one player down among four still gets *scout for them*; a party with nobody up gets the truth.

### Wording is a decision, so it is asserted like one

`--vordr-probe` checked that the readout's rect was the screen, that all three states were reachable, and that the bleed clock ran. It never asked what any of them **said** — and what they said was the entire fault. `line()` and `hint()` are split out of `_draw` so the wording can be asserted rather than the pixels.

Three rows, three plants:

| Planted | Fails |
|---|---|
| no hint at all (the shipped build) | *"does not name the way up (v/D-pad Up)"* |
| a hint that never changes once spent | *"the same thing it said when there was a way up"* |
| the Vörðr always says *scout for them* | *"solo there is no them and three seconds left"* |

The middle one matters as much as the first: a hint still naming a key that has stopped working is worse than no hint, because it is a promise broken at the moment it is believed — `PRO-005` §5's unexplainable event with a keybinding attached.

Built from `ControlsScreen.glyphs_for` rather than typed, because ADR-139 made that file the only one in the project that names a key.

### What this does not do

It does not make dying alone easier. The self-recovery already existed, at the price `DES-012` set; this is the build finally saying so. `DES-012`'s *"a solo analogue so downing is not strictly worse alone"* was implemented and invisible, which is the same as absent to everyone except the person who wrote it.

---

## ADR-151 — The run ends on a press, not on a silent clock

**Date:** 2026-08-27 · **Status:** accepted · **Implements `M3-T30`** · **Extends ADR-108**

**Context:** the second half of the reporter's solo-death account. What a wipe was, from the seat: the bleed bar empties, the readout changes to a line about being a Vörðr, and three seconds later the scene changes. No acknowledgement of the death, no agency, and — solo — no way to tell an ending from a hang.

ADR-108 gave two reasons for `party_wipe_seconds`, and the first was *"a cut to the camp on the frame you go out gives the player nothing to read."* That was right about the problem and short of a solution: three seconds of the **same readout** is not something to read. Now there is a screen, and the wait is a **floor rather than a fixed price** — whoever is ready presses, and the clock is the backstop for whoever is not.

### It is not a death screen, and it must not become one

`DES-003` puts the Legacy choice at the fire; ADR-133 is explicit that it wants a scene rather than a modal over a corpse, and ADR-141 is the scar from splitting that flow in half. Nothing on this screen chooses anything. It names what happened, says what it cost, and takes you to the fire — where the screen that *is* a decision is waiting.

**One button, because the second one the reporter asked for cannot exist here.** *"Restart a fresh delve"* would have to jump the Legacy flow, and the Legacy flow is what starts the next life. A button that skipped it would delete the choice `DES-003` calls the piece it feels strongest about.

### The comment on the re-check was false

The old code said: *"`_stand_up` clears `spent` on a self-recovery and a teammate's hand does the same, so this is the ordinary way out of here."*

It does not. `_stand_up` sets `bleeding` to zero and never touches `spent`, and both `revive_by` and `_self_recover` refuse a body that is not `is_downed()`. **A spent body cannot be revived by anything in this build**, so once `_the_party_is_gone()` is true the only thing that can make it false is a peer connecting inside the window, whose body arrives standing.

`--wipe-probe` appeared to prove otherwise because it stands its bodies up with `restore_for_descent()` — a full reset, not a rescue. The row is honest about what it measures (the re-check works) and was being read as something stronger (a rescue cancels a wipe). The re-check stays: the peer-joining path is real, and *"nobody has been standing for a while"* is the right rule whether or not today's build can exercise every road into it. The comment is now what the code does.

That also settles whether the press is safe. The outcome is fixed by the time this screen exists — every body is out and nothing can revive a spent one — so a press from any peer costs nobody anything but the wait.

### The screen comes down the moment somebody is standing

Not at the end of the wait. `--ember-probe` found this within minutes of the screen existing: it downs its only body, stands it back up **inside** the window, and then measures what carrying an ember costs a rescuer. With the screen holding the body for the rest of the three seconds, it measured a rescuer who could not move and reported the cost as nothing.

The re-check that decides the run is unchanged. Breaking the wait early only takes the screen down, which is the safe direction — ADR-108's rule guards against ending a run too eagerly, never against calling one off too eagerly.

Worth naming because the cause and the symptom had nothing to do with each other: a new screen in the death path broke a check about the **weight of a rescue**, and the failure it printed was a true sentence about a false cause.

### Verification

Four rows, four plants: no screen at all (the shipped build), a screen that does not take the body, a press the window ignores, and a screen never put away. Each fails by name. The last matters because in a real session the scene change disposes of the screen, so nothing would ever notice it being left behind — it is the probe path, which resets the floor instead, that can see it.

---

## ADR-152 — Abandoning a run you were not on

**Date:** 2026-08-27 · **Status:** accepted · **Implements `M3-T31`** · **Extends ADR-145**

**Context:** reported as *"starting a new run showed the tithe menu."* The reporter's own log has the moment:

```
[lair] kept Raw Gemstone — the stash holds 1
[lair] kept Bog Iron — the stash holds 2
[coop:solo] peer 1 descends at rank 1 as 'nobody'
```

Stashing loot in the Chamber, and the next thing is a new Threshold with a classless body. The life ended in between, and there was no run in progress to end it.

`PauseMenu` is the same object in all three levels, and `_leave()` called `GameState.die()` in all three. **In two of them there is no run**: `RunFile` opens at the descent and closes when the run resolves. So a player standing at the fire between descents — with a class, a tree, a stash and gear — ended their life on one click of a button that promised to abandon a run, with no confirmation, and with nothing else on the menu that goes back to the main menu at all.

The Legacy screen then appeared on the next descent. That was correct behaviour about a death the player never recognised as one.

### Three changes, one rule

`RunFile.exists()` decides what leaving costs — the game's own definition of being inside a run, in the file that owns it (ADR-050), rather than a level asking what kind of level it is. With a run: `ABANDON THE RUN`, and it **asks first**, because everything else on that menu is reversible and this one is `DES-008`'s great reset arriving through a button rather than through a fight. Without one: `TO THE MENU`, costing nothing.

`take_what_leaving_costs()` is separate from the departure, because `change_scene_to_file` detaches the menu synchronously (ADR-117) and takes any check with it — so the cost can be asserted and the going cannot.

### The pause menu had never been checked

Before ADR-146 the only line about it outside its own file was `add_child(PauseMenu.new())`. `--menu-probe` carefully asserts that every button on the **main** menu is wired and that none is the stub ADR-064 bans; the menu that can end a lineage had nothing at all. It has six rows now, three of them planted.

**And the first draft of those rows could not fail.** Run after the Legacy section, every one read a life that had already ended — the plant leaves `class_id` empty with nothing left to lose, and ADR-147's guard then refuses the second `die()` — so all six passed green against code that could not fail them. They run first now, on a life that has something to lose.

**The third plant printed nothing at all.** With the price wrong the button is wired straight to `_leave`, so pressing it changed scene and detached the probe mid-row: the failure deleted its own witness, and the run exited zero. The rows now stop before the press when the price is already wrong. Same lesson as ADR-138's `_descend`, arrived at from the other end.

### Four probes were writing the player's run file

Fixing the abandon branch needed a probe with a run open, which meant asking where probes get run files. The answer was: the player's.

| | How |
|---|---|
| `--run-probe` | armed and cleared it; ADR-138 sanctioned the arming and nobody asked about the path |
| `--edges-probe` | reasoned correctly that it *had* to arm, and read that as having to use the real file |
| `--class-probe` | reached past `RunFile` entirely — `DirAccess.remove_absolute` and a raw `FileAccess` write on `PATH` |
| `--menu-probe` | presses DESCEND, which runs the real `_enter()` and arms through the game's own front door |

Every one destroyed a suspended run on every sweep, and **none of it appeared in any output.** ADR-138 was written about precisely this file and fixed the probes that touched it by accident; the ones that touched it on purpose were left, because *"its subject is the run file"* reads like a licence and is not one. ADR-145 had already written the general rule after the same shape cost a profile: **a check that writes to `user://` must name the file it writes to, and it must not be the one the game uses.**

`PATH` and `TMP` become `static var`s with `use_a_scratch_run()`, on `SaveFile`'s pattern.

### The rule stops depending on being remembered

Three sessions have now found this, in five places, and each fix was "remember to call the redirect." So `arm()` **refuses** when the path is the real one and the process was launched with a probe argument.

Loud rather than lint: a refusal leaves `exists()` false, so the probe that did it fails its own assertions by name. That is what found `--menu-probe`, which no reading of the code would have turned up — it does not look like it touches a run file, because it does not: it presses a button, and the button does.

### Verification

A real run file planted in `user://`, a full sweep run over it, and the file read back byte-identical afterwards — alongside the profile, on ADR-145's check. Before the fix it was gone, three times running, each time for a different reason.

---

## ADR-153 — She took the bow and gave nothing, and the floor ate the Seax

**Date:** 2026-08-27 · **Status:** accepted · **Implements `M3-T32`**

**Context:** reported from play as *"the hoard went to 999 after I tributed my bow."* The 999 was a test fixture left in the reporter's `user://` by ADR-145's own verification — one `glt_hoard_coin` sitting under a value of 999, which is not a reachable state: `tribute()` appends to `hoard` and adds to `hoard_value` in consecutive lines and they can never disagree.

The bow was real, and it was worse than the number.

### She takes whatever lands near her, and gives nothing back

`Chamber._on_put_down` handed the pile anything dropped within `PLACE_REACH` with no question asked. `DES-014` makes the hoard **one-way by construction** — *"there is no method that takes anything off a hoard"* — so anything given for nothing is destroyed for nothing.

Two ways a thing can be worth nothing, and both were reachable:

**Scarred.** `DES-003` says Legacy items *"cannot be tributed"*. The build implemented that as *can be tributed, for zero* — the refusal existed in `tribute_worth()` and stopped at the arithmetic. The reporter's bow was Scarred; it had come back through a Legacy slot.

**Worth nothing to begin with.** Every weapon in this build is `tribute_value` 0 — the Seax you start with, the bow a Veiðimaðr *is*, the spear, the hammer — as are the Waystone and an ember. So the pile silently ate any weapon in the game, and a Veiðimaðr could disarm themselves permanently by walking too close to it.

`why_not_tribute()` is the fourth `why_not_*` and refuses both. Value is the judgment rather than the category: `rlc_regin_blade` is a weapon worth 120 and she wants it very much. A refusal is **not** the confirmation dialog `DES-019` bans — it is her declining, which is flavour and a guard in the same gesture.

### The Chamber floor was a deletion with a cheerful line about it

The third branch printed *"put X down on the floor"* and did nothing, under a comment saying the floor was *"a perfectly good place for a thing to be and needs no handling at all."*

Nothing spawns a `WorldItem` in that room. The Chamber builds its own body and `CoopSession` — which owns the spawner — never sees it, so a dropped item left the bag and existed **nowhere**. Then `_leave()` rebuilds `carried` from the bag alone. The reporter's log has `put Seax down on the floor`; their profile has no Seax anywhere.

There is no third gesture here. `DES-019` makes the decision physical and binary — give, or keep — so anything else is a mis-drop, and the answer to a mis-drop is to hand it back rather than to invent a third state for it. The readout said `anywhere else → it is on the floor`; it now says what actually happens.

### `put_back`, because `add` mints

`add()` builds a new instance from a definition, which is right for a pickup and wrong for a return: `scarred` and `bound_to` live on the **instance**. Handing a Scarred bow back through `add()` would quietly un-Scar it into full power, and a teammate's ember would come back bound to nobody.

### Why nothing caught it

`--lair-probe` has asserted since `M2` that giving works — and it gives her `inventory.richest()`, which is always the most valuable thing in the bag. A check written around the best case cannot see a rule about the worthless one.

Four rows now, three planted: the shipped no-gate build (the weapon and the Scarred coin both reach the pile and vanish), a return through `add()` (the item comes back as a different instance, so it is gone), and the old floor branch (the mis-drop leaves the bag and goes nowhere).

---

## ADR-154 — Bearing an ember out was a print

**Date:** 2026-08-27 · **Status:** accepted · **Implements `M3-T33`** · **Completes `M2-T05`**

**Context:** found while scoping the tribute fix. `DES-012` §3:

> **Carried out.** If your ember reaches an extraction point, **your LIFE survives.** You lose the run, your carried loot, and take a Scar — but your skill tree, stash, and Pact Rank are intact.

`_on_extracted` emitted `rescued(peer, player)` and printed *"their LIFE survives."* **`rescued` was connected by one probe and by nothing in the game.** ADR-098's question exactly: it fired, and the only thing listening was the check that it fired.

`_end_the_run` read `body.spent` and wiped the rescued player anyway. So a rescuer paid `DES-012`'s whole price — an ember is 12 kg and 5.5 clamor, it makes the Gullsjúkr stop for you (ADR-114), and it makes the walk home materially worse — and the person they saved lost their tree, their stash and their rank regardless.

The comment above it was honest about this and is the reason it survived: *"There is no tree, stash or rank until `M3`, so this is reported rather than enforced."* True when it was written. `M3` built all three, across `M3-T01`, `M3-T03` and `M3-T05`, and nobody came back to the sentence that was waiting on them.

### Out is not the same as lost

`_borne_out` records the peers whose ember reached an exit, and `_end_the_run` computes `gone = body.spent and not _borne_out.has(peer)`. That is the whole change: a rescued body still returns an empty haul, because `packed` is already `[]` for a spent body and `DES-012` is explicit that the bag stays with the body — so *"you lose the run and your carried loot"* falls out of code that already existed, and only *"the LIFE survives"* had to be added.

Per floor, and cleared with it. A rescue carried past a floor reset would forgive a death on the next one, for free.

### The token is spent at the exit

The ember is removed from the rescuer's bag when it is delivered. Left in, it rides home in `carried`, arrives in the Chamber as an ordinary item, and the pile takes anything it is given (ADR-153 is the same day's other half) — so the token for a life somebody has already saved becomes a thing you can throw away by accident.

### The Scar is absent, not stubbed

`DES-012` asks for a Scar and there is no Scar system in this build. Inventing one to satisfy the sentence would be the stub ADR-064 bans — a state with no rules, no display and no consequence, present only so a doc reads as done. It is scoped as `M4-T14` instead. Two thirds of the sentence are now true and the third is honestly missing, which is better than three thirds of it being a lie.

### Verification

`--vordr-probe` and `--ember-probe` between them had asserted that the ember drops, that it costs the carrier speed and quiet, that carrying it to the exit **reports** a rescue, and that an ember bound to somebody else does not stand in for yours. Every one of those passed against a build where the rescue did nothing.

The new row spawns a second body, has the host go out, puts its ember in the helper's bag and sends the helper up the Shaft — then asserts the host's class, tree, stash and rank all survive and that no death record was left for the fire to find. Planted by deleting the one line that records the rescue: two rows fail, the second being *"a rescued life left a death record"*, which is the Legacy screen opening over somebody who was carried home.

**Two of its own rows could not fail before they were planted.** The helper started 29 m from the exit, because a body nobody drives is eased toward `net_position` every frame and that starts at the origin — `teleport` declines for a peer that is not a process, and setting `global_position` does not stick. And the token check looked at the bag *after* the run resolved, which is after `_reset_floor` has emptied every bag; it samples at the instant the rescue is announced now, which is the only moment it can.

---

## ADR-155 — The run resolved for the host and stayed open for everybody else

**Date:** 2026-08-28 · **Status:** accepted · **Implements `M3-T34`** · **Completes `M3-T15`** · **Extends ADR-152**

**Context:** a playtester reported *"there is still an issue with joining and leaving games in progress."* That is all there was, so the whole menu / session / save-state flow was audited against the six pieces of state that can disagree. This is the first and worst of what it found, and it is the one that most plausibly *is* the report.

`Threshold._descend()` is `@rpc("authority", "call_local", "reliable")`, so `RunFile.begin()` runs on **every** peer — each machine opens its own run file, which is correct and is what makes ADR-050's *quitting is never an escape* true for a client at all.

`RunFile.clear()` was inside `_end_the_run()`, which returns on its first line for anything that is not the server. So a run opened on four machines closed on one.

### What that costs, on the path out of camp

`PauseMenu.leaving_ends_the_life()` is `RunFile.exists()` — ADR-152 chose that deliberately, as *"the game's own definition of being inside a run, in the file that owns it."* The definition is right and it was being read off a file that had stopped telling the truth.

So a client who extracted successfully, walked back to the fire and pressed Escape was offered `ABANDON THE RUN`. Pressing it calls `GameState.die()`: the tree, the stash, the Pact Rank, the worn gear and the class, for walking out of camp after a run they won. **And there is no other way back to the main menu** — the menu offers `BACK TO IT`, `CONTROLS`, `SETTINGS`, the abandon, and `QUIT TO DESKTOP`. The trap was on the exit.

### It bites only on runs you survive

This is why it lasted through three sessions of work in exactly this area. A wipe sends the client `lost = true`, `die()` clears `class_id`, and the stale run file is then an orphan that `resume_is_this_life()` drops on the next launch (ADR-138). Every **failed** run cleaned up after itself. Only the good ones left the trap armed, which is also the cruellest possible distribution.

### The clear belongs to the peer whose run resolved

`_take_the_outcome` already *is* the per-peer sentence — *your run is over, and here is what it came to* — and `_end_the_run` already delivers it to every peer including itself. `TEC-004` says the host reports and each peer writes its own profile; the run file is the same kind of state and now follows the same rule. One writer, one event, on each machine, and `_end_the_run` loses a line rather than gaining a guard.

### Nothing caught it because the row that should have could not fail

`--threshold-probe` has asserted since ADR-152 that *"at the fire there is no run, so leaving costs nothing."* It is a single-process check, and **solo is the host** — the one peer whose file was always cleared. The row's premise held for exactly the case that was not broken.

### A two-process check needed a `user://` per process first

`user://` is derived from the **project name**, not the process, so both peers of every harness scenario resolve `user://run.active` to the same bytes. Godot 4.7 has no `--user-data-dir`, so `tools/own_user_dir.py` gives each launched process its own `HOME` and XDG roots; `run_coop.py` and `run_doorway.py` route every launch through it.

**This was planted, and it is the finding underneath the finding.** With the fault still in place and every slot sharing one directory, all six new rows go **green** — the host's clear answers for the client, and the check asserts nothing. That is the fifth time this project has written a row that could not fail, and the first time one was caught before it shipped rather than after.

### `--extraction` was the hole in ADR-152's refusal

ADR-152 made `arm()` refuse the real run file in a process launched with a probe argument, matching on `probe` or `shot` in the name. `room_set` had deliberately kept those words **out** of `--extraction` so that `_probing` would stay false and the scene change would be real — `threshold.gd` says so in as many words. So the one harness flag that most needs a run file was the one flag allowed to open the player's.

Nothing had exercised it, because the extraction scenario had no run file until this task gave it one. `_a_check_is_running()` names `--extraction` now, and the scenario redirects and asserts on top of that. A guard whose coverage depends on a naming convention expires the first time somebody names a flag well.

### Verification

Six new rows in `run_doorway.py`'s extraction scenario, two per peer, read from the fire rather than from the Deep — `_take_the_outcome` ends in `change_scene_to_file`, which detaches the floor synchronously (ADR-113), so the process best placed to report is the one least able to. One row asks whether the run file closed; the other asks what the **pause menu** prices leaving at, kept separate so a build that fixes the file without the menu fails the half that is wrong.

Planted by restoring the host-only clear: the host's two rows pass, all four client rows fail, and the second of each names the symptom as reported — `ABANDON THE RUN`. Then planted a second time, on the harness, as described above.

---

## ADR-156 — A run ended on a death or an extraction, and never on somebody leaving

**Date:** 2026-08-28 · **Status:** accepted · **Implements `M3-T35`** · **Extends ADR-108**

**Context:** the second finding of the session-flow sweep that produced ADR-155, and the one that most directly answers *"leaving games in progress."*

Run resolution is reachable from exactly two places, and that was the whole of it:

| | |
|---|---|
| `_on_died_here` | → `_watch_for_a_wipe()` |
| `_on_extracted` | → `_settle_if_nobody_is_left()` |

**A peer disconnecting is neither.** `CoopSession._on_peer_disconnected` freed the body, released the seat, and told the level nothing at all — no signal, no call. `_watch_for_a_wipe` returns immediately when somebody is still standing and leaves `_ending` false, so nothing re-armed it, and `_the_party_is_gone()` would have answered correctly if anything had thought to ask it again.

### What that was, from the seat

Your last teammate closes their laptop while you are lying there spent. A `spent` body cannot move, and **cannot be revived by anything in this build** — ADR-151 established that `_stand_up` never clears `spent` and both revive paths refuse a body that is not `is_downed()`. So the floor goes on running around somebody who can do nothing, until they close the process.

The only way out is the pause menu, and with a run open that button is `ABANDON THE RUN` (ADR-152). So a friend's alt-F4 cost you the tree, the stash and the rank. The same shape reaches you from the other direction: you have already extracted and are waiting under `M3-T09`'s out-but-present rule, and the last person still down there disconnects.

This is ADR-108's own finding — *"a player with no teammates simply never ended"* — arriving through the door ADR-108 did not cover: the teammate **leaving** rather than dying.

### The level is told, and it chooses between the endings it already has

`CoopSession` gains `player_left`, and `room_set` connects it. Deliberately **not** to `_on_party_changed`: that one grows the floor, and ADR-110's rule is that it never shrinks, because despawning an enemy somebody is fighting is a bug they can see. What a departure changes is not the size of the floor, it is whether anybody is still in the run.

The two endings are not interchangeable and the handler picks between them. `RunOverScreen` says **"YOU WENT OUT"** — true for somebody lying spent, and a lie told to somebody who walked out on their own feet and was waiting for a friend who never came back. So: any remaining body `spent` → the wipe path, with its window and its screen; otherwise → settle, silently, as an extraction does.

### The fix's first draft failed its own new row, and that is the useful half

`queue_free` does not leave the tree until the deletion queue is flushed, which is after the frame the signal fires in. So the first version asked `_the_party_is_gone()` about a party that **still contained the person who had just left** — not `is_out()`, therefore reading as *somebody is standing* — and did nothing whatsoever. The check caught it immediately, which is the entire argument for writing the check first.

Awaiting a frame appeared to be the fix. It is a guess about when Godot flushes a queue, and it would have been a guess sitting underneath a rule about whether a run is over. `players()` skips a body that is being freed instead — which is a statement about the party rather than about the frame, is true at all twenty of its call sites, and makes `_the_party_is_gone()`, `_end_the_run`'s per-peer loop and party scaling agree with each other for free.

### Verification

A new two-process scenario, `--abandoned`, in `run_doorway.py` — the first one that **kills a process on purpose**. The host spends its own body while a client is still standing, holds long enough to prove the run has *not* ended (ADR-102: a party with somebody standing is not a party that is gone), and then the harness kills the client.

Five rows. The precondition — *one out, one standing, and the floor stayed* — is half the assertion: without it a build that ended the run at the first death would satisfy the rest for entirely the wrong reason.

**Both halves of the fix were planted separately**, and each fails *and ended once the last of them left*, *the one left behind got home* and *with its run closed behind it* by name, while the precondition row passes throughout. No single-process probe could have caught any of this — `--wipe-probe` walks a two-body party all the way to a wipe and has always passed, because its second body is a peer id rather than a process, and a peer id cannot leave.

`--abandoned` is named without the word `probe` for `--extraction`'s reason: `_probing` swaps the scene change for `_reset_floor`, and *arriving at the Threshold* is the whole assertion. `RunFile.HARNESS_FLAGS` names both, so neither can arm the player's run file — and the list carries a note that a third entry means it should become one `--scenario=NAME` argument instead of a longer list.

---

## ADR-157 — Nobody joins a descent that has already begun

**Date:** 2026-08-28 · **Status:** accepted · **Implements `M3-T36`** · **Extends ADR-101, ADR-107**

**Context:** the third finding of the session-flow sweep, and the only one of the four that was reproduced across two processes *before* being fixed rather than after.

Nothing gated a late join. The peer lives on the `SceneTree` and outlives a scene change (ADR-101), and `CoopSession` is built per level — so a peer that connected while the host was in the Deep ended up with **two processes in two different scenes on one connection.** Godot addresses every RPC and every spawn by node path, so both directions break at once:

```
host      ERROR: Failed to get path from RPC: Threshold/CoopSession
joiner    ERROR: Node not found: "RoomSet/CoopSession/Spawner"     … every packet
```

The joiner receives no body, no camera and nothing else. That is ADR-107's grey screen, arriving through the one door ADR-107 did not close.

### It cost the host as much as the joiner

`_on_peer_connected` spawned a body for them regardless. That body is **un-driven**, because its owner's process cannot see it; it counts in `players()`, so `_the_party_is_gone()` waits on it; and `_on_party_changed` re-runs `_spawn_enemies()` for a party that just grew, hardening the floor for a player who is not there.

In the reproduction, the host's run ended in a wipe within seconds of the join — `nobody is left standing`, `the great reset — carried and stash gone`. **The control run, identical but with nobody joining, had no deaths at all in forty seconds.** A friend arriving a minute late could cost you the run.

### This does not reverse ADR-016, and the difference matters

**Added after the fact, because the first version of this ADR did not name ADR-016 at all.** `TEC-004` has a full *Join-in-progress* section and ADR-016 makes late join **core, not post-launch** — so an ADR that refuses joining mid-run and says nothing about either one reads, to anybody arriving later, as a silent reversal of an accepted decision. `CLAUDE.md` §8 exists for exactly that failure, and this ADR walked into it.

The two are compatible, and the distinction is the whole point: **what was refused here is not join-in-progress.** ADR-016's feature is a player opening a gate at the party's position and stepping through, with the world delta — looted containers, dead enemies, opened doors, Hunt state — synchronised behind the animation. None of that exists. What existed was an *ungated connection* that broke both processes and could cost the host the run.

So this is `ADR-064`'s **absence with a named replacement**: the specification in `TEC-004` stands unchanged, and it is now `M4-T15` with a milestone attached. There was no task for it anywhere in `PRO-001` — `TEC-004` said *"build this test at M2, not M4"* and nothing on the roadmap ever picked it up, which is the same shape ADR-116 §1 found when `GATE M3 COOP` named a rank-8 floor nothing built. A refusal without that task would have been a stub in the other direction: a permanent-looking answer to a question the design had already answered differently.

### The first shape of the fix was wrong, and the harnesses said so

*"Only the Threshold accepts arrivals"* is a rule about **scenes**, and it broke three harness scenarios that assemble a party directly in the Deep — `run_doorway.py`'s extraction and left-behind, and `run_coop.py --smoke`. Those are not cheating: every peer boots the same scene, so their node paths agree and a join between them is sound.

What is unsound is joining a party that has **already gone down**, which is a fact about the run rather than about which file is loaded. So the door is open while the party is assembling, `Threshold._descend()` shuts it, and `Threshold._spawn_actors()` opens it again — which also covers the way home, because arriving at the camp is the one thing every route back has in common.

Static on `CoopSession`, for `NetPlan`'s reason: what it describes is the **connection**, and the connection outlives every level. A per-node flag would be reset by each doorway, which is precisely the moment it must be carried across.

### Connecting is not arriving

`refuse_new_connections` shuts the transport, and the joiner *still* fires `connected_to_server` — measured: the client logs `connected as peer N` and the host never fires `peer_connected` at all. `_on_connected` cleared the client's own deadline, so a refused client stood in an empty camp forever with nothing to read. That is the state ADR-108 called *"worse than the process quitting, because at least a quit is a signal"* — the fix had replaced one silent failure with another.

The deadline is **extended** rather than cleared, so a slow link is not mistaken for a refusal, and what ends it is the thing you came for: your body, which only the host can send. No handshake was added — the arrival of the thing you were waiting for is the signal that you have arrived.

### The fourth player gets an honest sentence out of it

The same wait now ends the same way for the party-full case, which ADR-155's sweep had filed as not worth fixing on its own. There are three real causes and a client can distinguish none of them, because ENet raises nothing for two of them. The message named one and asserted it — *"Check the address, and that the host has opened the Threshold"* — which is **wrong two times in three** and sends somebody to re-check an address that was right. It names all three now. Telling them apart needs the host to answer before the transport refuses, which is a handshake this build does not have and which `M4-T07` brings for free.

### Verification, including the plant that did not fail

A fourth two-process scenario in `run_doorway.py`. The host **descends** rather than being launched into the Deep, which is the difference between asserting the rule and asserting a scene; `--doorway-probe` is the flag that walks a host into the hole. Five rows: the door shut, no packets addressed into a scene either peer is not in (both directions), no body built, and the one knocking is told why. The first is a precondition — without it the rest pass against a host that never got as far as descending.

| plant | caught |
|---|---|
| the door never shuts | **yes** — all four rows, and it reproduces the original fault exactly: both node-path errors and the phantom body |
| connecting counts as arriving | **yes** — *the one knocking is told why* |
| the fire never reopens the door | **yes**, after two false starts of its own — see below |
| the body guard inside `_on_peer_connected` | **no** |

### The reopen row took three attempts to become a row at all

The door shuts at the descent, so something has to open it again; a build that never did would finish one run and be **unjoinable for the rest of the session** — co-op quietly becoming single-player, with nothing about it that looks like an error.

Asserting that turned out to be harder than fixing it, and both failures were the same failure:

1. The row was first written in `--edges-probe` as *the camp takes arrivals*, sampled before `_descend`. It **passed with the camp's own call deleted**, because `_party_is_assembling` starts open — a row reading an initial value rather than a decision. That half is now gone from the probe entirely, with the reason written where it was.
2. Moved to `run_doorway.py`'s extraction scenario, where peers really do come home, it **still** passed with the call deleted: those peers boot straight into the Deep, so nothing had ever shut the door and *reopened* meant nothing.

The scenario now shuts it, which is not a concession — `--extraction` already stands in for the descent by opening a run file, and saying so about one half and not the other is what left the row reading a default. **And that had to happen after the party assembles, not in `_ready`:** the first attempt shut the door before the scenario's own clients had joined, and the host refused them. The same mistake as writing the rule about scenes instead of about the descent, one layer in.

### One plant is not caught, and that is recorded rather than hidden

With the door working, `_on_peer_connected` never fires for a refused peer at all, so deleting the guard inside it changes nothing the harness can see. It is not dead code and it is not a stub: it defends a genuine race — the door shuts as the descent begins, and a connection already in flight can land inside that window — and what it prevents is the phantom body that costs the host its run. But it is **unasserted**, it cannot be counted as a row, and a future change could break it silently. Constructing the race deliberately would need frame-accurate timing across two processes, which is a flakier check than no check. ADR-098's distinction applies exactly: `check_dead.py` proves nothing is orphaned, and only a probe proves the game reaches its own code.

`check_dead.py` did earn its keep here, though: `taking_arrivals()` was added *"for `--threshold-probe`"* and then not called by it, and the sweep said so immediately.

---

## ADR-158 — The hole asked the host and nobody else

**Date:** 2026-08-28 · **Status:** accepted · **Implements `M3-T37`** · **Completes the `M3-T34`–`M3-T37` sweep** · **Extends ADR-101, ADR-138, ADR-148**

**Context:** the fourth and last finding of the session-flow sweep.

ADR-101 made the hole the host's decision, so that a party arrives together rather than one player dropping into the Deep while everybody else stands at the fire. That is right, and it asked **nobody whether they were ready.**

`_descend` is `@rpc("authority", "call_local", "reliable")`, so it runs on every peer — including a client with the **Legacy screen open**. What that peer does, in order: `RunFile.begin()` with an empty `class_id`, a scene change out from under a question it has not answered, and then `declare_descent` sending `""` to a host that builds it a body with no class. No class is no kit, no kit is an empty hand, and `MeleeWeapon.request_swing` refuses on an empty hand.

An attack button that does nothing, for a whole run. Principle 4 has no sentence for that.

### The same fault, through a third door

ADR-138 put a guard at the menu — *nobody descends as nobody*. ADR-148 fixed the body at the fire — *after every death you stood at the fire as nobody*. Both were right, and neither could see a client's class question being **answered for it by somebody else's footsteps**.

And it is not an edge case. `DES-003` deliberately lets a player come back to the fire and take as long as they like over what she keeps, so a client sitting on the Legacy screen is the ordinary state of anybody whose life ended last run — which is the second co-op run in every session.

### The host already knew

No new message and no readiness protocol. `declare_descent` has carried the class since `M3-T02`, because the host builds every body and a Húskarl who is only a Húskarl on their own screen is not one. A peer that has not chosen declares `""`.

So `still_choosing()` counts the peers whose class is empty, and the descent waits on it. It counts the **host** too, so a classless host cannot take a sworn party down either. `Threshold.may_descend()` is not a duplicate of this: that one decides whether the body you are driving may walk into the hole, this decides whether the party may go, and `M2-T15`'s lesson — a level can be reached without passing through the menu — is why both exist.

A peer that has connected but not yet declared counts as still choosing. That is correct rather than merely convenient: they are not ready, they are about to be, and the answer changes on its own a frame later. ADR-122 is the same observation about ranks.

### And the hole says why

A trigger that silently does nothing is indistinguishable from a broken one, and it generates the wrong bug report — *"the descent doesn't work"* rather than *"we were waiting for someone."* Whoever walked in is told, on their own readout: **N of the party are still at the fire — the Deep takes you together, or not at all.** Both peers are in the Threshold, so the node paths agree and the reply routes; ADR-157 is the case where they do not.

### Verification

A fifth two-process scenario. The client is launched **without** `--as-class`, which is exactly the state of a real client whose life ended last run, and the sworn host walks into the hole at six seconds. Three rows: the hole waited, and neither peer reached the Deep.

`--as-class` is how the harness says a party has chosen — the same lever `--as-rank` has been for ADR-010 since `M3-T10` — and the party-door scenario now passes it, because a party at the fire has chosen who they are. A scenario that leaves it off is saying something, and this one says it on purpose.

Three plants, all failing by name:

| plant | the row that caught it |
|---|---|
| the gate is never asked | *the hole waits for somebody still choosing* → **TOOK THEM DOWN unchosen**, and both peers *went down anyway* |
| the host does not count itself | *a life sworn to nothing is not counted as still choosing* |
| the hole refuses and says nothing | *the hole refused and said nothing* |

The first is the one worth reading twice: with the gate deleted, the classless client **went down anyway**, while the party-door row saying a sworn client follows the host down still passed. The plant is the fault and nothing else, which is what tells a check apart from a smoke alarm.

The single-process half lives in `--edges-probe`, and only the host's own share of it is reachable there — `still_choosing()` reads `multiplayer.get_peers()` and there are none. That half is the one solo depends on; `run_doorway.py` walks the other with a real second peer.

---

## ADR-159 — One machine, one running copy

**Date:** 2026-08-28 · **Status:** accepted · **Amends `TEC-003`, `TEC-004`** · **Closes the last question from the `M3-T34`–`M3-T37` sweep**

**Context:** the session-flow sweep found that `user://` is derived from the **project name**, not from the process, so two copies of SHE on one machine resolve `profile.save` and `run.active` to the same bytes. Writes are atomic (`SaveFile` renames a complete file over the old one), so there is no torn file — but two different lives writing one profile is last-writer-wins, and **nothing anywhere would say so.**

The sweep deliberately did not decide this, because the severity depends entirely on a fact only the person playing knows: *does anybody actually run two copies at once?*

**Answered: no.** Testing happens on one machine with one client at a time; co-op is between machines.

### So nothing is built

This is `ADR-064`'s **gate decision** rather than a fallback — one path chosen once, the other never built. A lock file, or a second instance refusing to start, would be a system built for a configuration nobody uses, and the honest cost of *not* building it is a documented assumption rather than a hidden one.

The design already leaned this way without saying so. `NetPlan.local_address()` filters loopback out of the address the host screen reads aloud, on the grounds that *"handing somebody `127.0.0.1` is handing them their own machine"* — which is this decision, expressed in one line, three tasks before anybody wrote it down. Loopback stays reachable by typing it, because every two-process check in the project connects that way.

### What it looks like if the assumption breaks

A profile that quietly loses a tithe, a rank, or a stash entry, with **no crash and no error**, because the other copy wrote last. Written down so a future session recognises the signature instead of chasing it as save corruption — the failure mode is the whole cost of the decision, and a cost nobody has written down is one somebody pays twice.

### The one exception is named and already separated

`tools/run_coop.py`'s windowed mode launches a host and a client side by side, which *is* two copies on one machine. It is a harness rather than the game, and since ADR-155 every process it launches gets its own `HOME` and therefore its own `user://`. So the exception exists, is named, and cannot corrupt anything — the sweep's harness split turns out to have closed the only live instance of the hazard as a side effect of making a check able to fail.

---

## ADR-160 — The second descent of a session was walked by nothing

**Date:** 2026-08-28 · **Status:** accepted · **Implements `M3-T38`** · **Extends ADR-050, ADR-152**

**Context:** reported from play, on the build cut at `d9f3da3`:

> I entered a solo run. I immediately abandoned it and was taken back to the menu. When I started another run it showed a screen to select loot to give up and I was allowed to offer my weapon and then when I got into the new run around the fire room I couldn't enter the dungeon again.

The reporter's own logs have it twice, in two separate sessions, identically:

```
[coop:solo] peer 1 descends at rank 1 as 'veidimadr'    ← the camp
[coop:solo] peer 1 descends at rank 1 as 'veidimadr'    ← the Deep
[descent] carried 1 of 1 stashed item(s) down, 11.0 kg
WARNING: the open run belongs to 'veidimadr' and this life is ''; dropping it
[coop:solo] peer 1 descends at rank 1 as 'nobody'       ← the camp again
[coop:solo] peer 1 descends at rank 1 as 'veidimadr'    ← sworn at the fire
                                                        ← and the log ends
```

One descent per launch, and then nothing: **no error, no refusal, no scene change.** The fix for that silence is `M3-T39`. This ADR is the instrument that makes it visible, and the one defect the instrument proved on its own.

### Nothing had ever walked a second descent

Every probe in this project boots **one level directly**. `--menu-probe`'s loop instantiates each level side by side and frees it without ever entering one. `run_doorway.py` is about two processes walking through a single door. Not one check had ever crossed a scene boundary in a single process.

A player's second descent of a session crosses four scenes — menu, camp, floor, menu — and rewrites half the state table `M3-T34` wrote down. It was covered by nothing whatsoever, which is why a fault this reachable survived a green sweep and four ADRs written about exactly this area on the same day.

`--again` walks it the way a player does: through the front door, the camp, the floor, the pause menu, back to the front door and down again. Its assertion is blunt, because the failure is silent — **the second run begins**, and a body that stands in the hole for three seconds without a run starting is a failure with a name.

Booted with no scene argument, through `run/main_scene`, because the front door is the only thing in the build that opens a profile (`M3-T06`) and half of what this walks is what the menu decides.

### Abandoning never closed the run it abandoned

`take_what_leaving_costs()` called `GameState.die()` and left `user://run.active` on disk. ADR-050 permits exactly one open run per life, so what that leaves is **a run file describing a life that has just ended** — precisely the state `M3-T34` was written to eliminate, manufactured deliberately on every abandon.

It looked harmless because `resume_is_this_life()` drops it as an orphan on the next entry: `die()` clears `class_id`, so the run and the life no longer agree and ADR-138 throws it away. That is the `WARNING` line in the reporter's log above — **on a path that is not an error**, appearing every single time they abandoned.

A repair standing in for a fix. It depends on the next thing the player does being the menu; it leaves an open run on disk for as long as the game is closed, which the next launch will find and reason about; and it spends ADR-138's orphan-drop — a guard written for probe litter — on ordinary play. `M3-T34` settled the rule for the other two ways a run ends: *the run resolved for this peer, so this peer's run file closes.* Abandoning **is** the run resolving, and it is the only one you pay for on purpose.

### Where the assertion had to go

At the front door, before `_enter()` runs, and nowhere else — because `_enter()`'s own orphan drop is a few lines further on and **tidies the evidence away**. By the time the camp could ask, the file is gone and the build looks correct. A check placed one scene later would have passed against the broken build.

The condition is `GameState.life_already_ended()` — ADR-147's own predicate, a cleared class with a record still waiting — so the scenario names the state using the game's vocabulary rather than counting steps of its own.

### The walk needed its own memory, and the first draft did not have one

Telling the two arrivals in the Deep apart by `last_life` read well — `die()` leaves the record, the Legacy screen clears it — and walked the loop **forever**: answering the screen empties the record, so the second arrival looked exactly like the first and abandoned again. The record is a question the *game* asks and answers; how far along a scenario is, is the scenario's own business. A static on the level, because a level is rebuilt on every descent and this outlives them.

### Verification

Two plants, each failing by name:

| plant | the row that caught it |
|---|---|
| the abandon leaves its run open | *abandoning ended the life and left its run open* |
| the camp cannot find its body | *the camp cannot find the body it is standing next to* |

The second is the reported symptom made assertable: with no body, `Threshold._process` returns at its first line, so the Descent, the Chamber and the readout are all dead while the player walks around a fire that answers nothing.

And because this session has spent four tasks inside the save and run-file paths, the full sweep was run with the developer's real `profile.save` checksummed either side: **byte-identical**, and no run file left behind.

---

## ADR-161 — A fire that answers nothing, and a save that stops saving

**Date:** 2026-08-28 · **Status:** accepted · **Implements `M3-T39`** · **Completes `M3-T38`**

**Context:** `M3-T38` built the walk that covers a second descent. This is the fix for the thing it was built to find, and the finding is not a single bug — it is that **three separate failures in this build produce no line anywhere.**

### The camp goes blind and says nothing

Every trigger at the fire hangs off `_session.local_player()` finding `player_1`. When that lookup fails, `Threshold._process` returns at its **first line**: no Descent, no Chamber, no readout. The body is still there, still drawn, still drivable — so the player walks around a camp that answers nothing, and the log looks exactly like somebody who never found the hole.

That is the reported symptom, word for word:

> when I got into the new run around the fire room I couldn't enter the dungeon again

It cost two play sessions and eight headless reproductions to place, and the reason is entirely that **nothing said anything.** The reporter's log ends mid-session with no error, no warning and no scene change — which is the least useful artefact a fault can leave, because it is consistent with a dozen explanations including the player simply stopping.

### The hole refuses onto a wall nobody keeps

`may_descend()` failing wrote *"you have sworn to nothing"* to the readout and nowhere else. The readout is the right place for the player and the wrong place for a report: it is gone the moment the scene changes, and no bug report has ever carried one. Both now, and the log line is the half that survives.

### And the save had stopped saving

`_persist()` returns early when `_live` is false. That is correct — a process that never opened a profile must not write one, and a profile that was found and refused must not be overwritten (ADR-117) — and it was **completely silent.** A session in which every write is discarded looks identical to one in which they all landed.

Found chasing a reported profile whose `updated` stamp was **minutes older than a session that contained both a death and a class oath**, each of which calls `_persist()`. Whether that session was writing at all should have been answerable from its log in one line. It was not, and the question is still open — but it is answerable now, which is the difference that matters.

`push_error` rather than a print, because this is data loss in progress. And `load_profile()` names which of its three branches it took: a profile read, a profile refused, and no profile at all lead to three different games and produced one silence between them.

### Never opened is not the same as opened and refused

**The first draft of the save half said both, and the sweep failed it.** Every probe in this project boots a level directly and never sees the front door, so `_live` is false for all of them **by design** — erroring there broke six checks at once and would have buried the one occurrence that matters under a hundred that do not.

ADR-138 had already written this rule down, for `RunFile._write`, in as many words:

> Not an error. A probe booting a level directly has no business opening a run, and saying so on every one of them would bury the output that matters in noise.

Same rule, a second file, and it was found by the sweep rather than by remembering — which is the argument for running the sweep before the commit rather than after.

So the error is now for the case with a player behind it: a profile that **is on disk**, was read, and was refused (ADR-117) — a lineage that exists while this session quietly discards everything that happens to it. `_refused_a_profile` is that state, and it is the one the row plants.

### Once, not per frame

Each of these latches. Sixty lines a second is not a diagnosis — it is the reason nobody reads the log, and it would bury the line that matters under the one that is merely repeating. The camp's latch clears when it finds its body again, so a recovery is visible too.

### What this does not do

It does not fix the reported fault. **It makes the reported fault legible**, which is the honest position: I could not reproduce it headlessly across eight attempts, including against a copy of the reporter's own save, and shipping a speculative fix for a mechanism I have not observed would be worse than shipping the instrument that names it. The next occurrence writes down which of the three branches it took, and the fix follows from that rather than from a guess.

Two of the three suspects were ruled out by measurement on the way here, and both are recorded so nobody re-walks them: the `_rebuild` node-rename theory (one frame **is** enough, even driven from `_process`, where a real button press lands) and the rebuilt body being undrivable (`driving=true`, walks 12 m). ADR-158's party gate was also cleared — `still_choosing()` is 0 throughout and prints nothing in the reporter's logs.

### Verification

Three plants, each failing by name:

| plant | the row that caught it |
|---|---|
| the camp is blind in silence | *the camp lost the body it is standing next to and said nothing* |
| the hole refuses in silence | *the hole refused a life sworn to nothing and only the readout said so* |
| the save discards in silence | *the profile refused to go live and then discarded every write in silence* |

The first row takes the body away and gives it back, because every row after it needs one — and it asserts the return, so a plant cannot pass by leaving the camp empty.

The full sweep was run with the developer's real `profile.save` checksummed either side: **byte-identical**, no run file left behind.

---

## ADR-162 — The camp that would not take you back, and the instrument that could not see it

**Date:** 2026-08-29 · **Status:** accepted · **Implements `M3-T40`** · **Completes `M3-T39`**

**Context:** `M3-T39` shipped the instrument and said in as many words that it did not fix the fault: *"I could not reproduce it headlessly across eight attempts, and shipping a speculative fix for a mechanism I have not observed would be worse."* The next play session reproduced it again. This is the mechanism, measured, and the fix.

### What actually happens

Swearing a class at the fire rebuilds the body — `LegacyScreen.finished` → `_swear_in_the_body` → `_rebuild` — which despawns it and spawns a new one. `_rebuild` waited exactly one frame between the two halves, and `player_for` found a body by **node name**:

```gdscript
return _actors.get_node_or_null("player_%d" % peer) as Player
```

`add_child` renames on collision. So a body spawned while its predecessor is still in the deletion queue arrives as something other than `player_1`, and from that moment `player_for(1)` answers `null` for the rest of the level. `Threshold._process` returns at its first line, and the Descent, the Chamber and the readout are all dead while the body is still drawn and still walkable. That is the report, word for word:

> around the fire room I couldn't enter the dungeon again

### Why one frame was enough eight times and never once in play

The deletion queue is flushed **early in the frame**, before idle processing. Measured directly — free a node, add a same-named one with a single `process_frame` between them:

| the swap is started from | old node after 1 frame | the new node | `get_node_or_null` returns |
|---|---|---|---|
| `_process` | **still valid** | renamed | the **dying** node |
| a coroutine already resumed at `process_frame` | gone | `player_1` | the new one |

Input is dispatched before idle processing, so a real button press is on the first row. **Every probe in this project was on the second.** `LegacyScreen.finished` fires from a click for a player and from `emit_signal` in a coroutine for every check — the same line, one frame apart, and only one of them worked.

The previous note on `_rebuild` had the mechanism exactly right and drew the wrong conclusion from it — *"a frame between the two halves, and it is load-bearing"* — because it was verified from the side of the frame where it is true.

### Fixed at both ends, and neither alone is the fix

**The rebuild stops counting frames.** It waits until the old body is actually gone, bounded, and says so if it never leaves. Bounded rather than a bare loop: a body that never goes would hang the coroutine holding the player's input, which is worse than the fault being fixed.

**The lookup stops depending on the name.** `player_for` keys on **multiplayer authority**, which is what the body actually is: `configure_replication` sets it before `add_child`, it rides the spawn packet to every peer, and nothing renames it. Scoped to `_actors` and skipping the deletion queue, so it can return neither a corpse nor somebody else's session's body — `players()` learned that second half in ADR-156 and this is the same sentence about one peer.

Both, deliberately. They are independent failures — planted separately, each one alone still passes, because either fix rescues the other's absence. The pair is what the reported bug is.

**And the camp recovers rather than only complaining.** `M3-T39` made blindness loud, which was necessary and is not sufficient: a player standing in a dead camp cannot read a log. The camp now puts a body back. It also names what `Actors` held, because a rename, an empty `Actors` and a body belonging to the wrong peer are three different bugs that produced one sentence between them.

**A gap the code made itself is not a fault.** `M3-T39`'s error fired the moment the lookup failed, which is one frame too eager — `_rebuild` takes the body away on purpose, so an ordinary class oath logged an error every time. Blindness has to persist before it is news, or the log stops being read, which is the failure `M3-T39` existed to end rather than to reproduce.

### The part that makes this definitive

The other three parts fix this bug. This one is why it took three rounds.

`ClassScreen.press` now fires from `_process`, where a real click lands, instead of `emit_signal` in the caller's frame. Three attempts, each of which measured the last one wrong:

1. `emit_signal("pressed")` — runs the handler inline in the caller's frame, on the safe side of the flush.
2. `Input.parse_input_event` from the same coroutine — no better. `parse_input_event` dispatches **synchronously**, so the event went through the button, through focus, through `BaseButton`'s action handling, and arrived at the same place in the frame.
3. Awaiting the press through to the oath — hangs, every time. `_commit` frees the screen, and **a coroutine whose `self` has been freed never resumes.** A function cannot watch its own destruction.

A `SceneTreeTimer` was tried too, and is also on the safe side.

### Verification

The A/B is the finding:

| | the press is driven from | `--threshold-probe` |
|---|---|---|
| **A** the bug planted | `_process` (a real click) | **exit 1** — *"swearing a class at the fire left no body at all"* |
| **B** the bug planted | `emit_signal` (how every probe pressed) | **exit 0, green** |
| **C** fixed | `_process` | exit 0, green |

The same broken code, two instruments, opposite verdicts. A and B are one line apart.

Three further plants, each failing by name: the rebuild counting frames again, the lookup keyed on the name again, and the camp complaining without recovering. The first two pass alone and fail together, which is the point above.

`--edges-probe`'s blind-camp row was rewritten to stop handing the body back itself — it could only ever assert that the camp *complained*, and a player standing in that camp does not care. It waits out the grace and asserts the camp recovered on its own. Its latch also had to become a **count**: `_said_it_lost_the_body` clears when a body is found, so the row was reading it after the recovery had already reset it — a check quietly measuring nothing.

### What this does not cover

~~`run_doorway.py`'s *left behind* scenario fails on macOS — three rows, reproducibly, **on this commit and on its parent alike**, and green on CI's Linux. It is a co-op disconnect-detection difference, it predates this work, and it is not touched by it. Recorded rather than absorbed: `M3-T41`.~~

**Retracted — this was wrong** (ADR-163). There is no platform difference and there was no pre-existing co-op bug. The scenario passes 3/3 alone at the same budget; the harness passes entire on a quiet machine. Its 18 s sleep had 1.8x headroom over ENet's peer timeout, and the machine was loaded with processes a mistake of mine had left running. The explanation above was inferred from three identical failures and never tested, which is the same error this ADR spent a page warning about one section earlier. `M3-T41` fixes the harness.

---

## ADR-163 — A check that fails when the machine is busy is a check that lies

**Date:** 2026-08-30 · **Status:** accepted · **Implements `M3-T41`** · **Corrects ADR-162**

**Context:** `M3-T40` shipped with the sweep red. The three failing rows were `run_doorway.py`'s *left behind* scenario, and ADR-162 recorded them as a pre-existing macOS platform difference in how a hard-killed peer's disconnect is detected.

**That explanation was wrong, and nothing had tested it.** It was inferred from a failure that reproduced three times, and "reproducible" was taken to mean "real" when it only meant the cause was still present.

### What the measurements say

| test | result |
|---|---|
| `run_left_behind` alone, at its real 18 s budget | **3/3 pass** |
| after `run_extraction`, the sweep's own order | pass |
| the full harness, quiet machine | **exit 0** |
| the full harness, earlier the same day | 3 failures, three times |

Timestamped against the kill, the chain is:

```
+5.4s   [coop:host] peer 461268956 left        ← ENet's peer timeout
+5.4s   [left] nobody is left in the run
+5.4s   [death] nobody is left standing — 3.0 s and the run is over
+10.0s  [extract] host arrived at the Threshold
```

Ten seconds of an eighteen-second budget. **1.8x headroom over an event that is a timeout rather than a packet** — so it stretches under load, and a `sleep` does not stretch with it. The machine was loaded because a hung process of mine and its children were still running; killing them was not enough, because by then the measurement had already been taken and believed.

### The fix is in the harness, and the product is untouched

The scenario knows what it is waiting for, so it waits for **that** — `wait_for(host, HOME_AGAIN, LEFT_BEHIND_CEILING)` — and carries on the moment the line appears. The 45 s ceiling is a backstop that only a real failure reaches, not a budget every run pays. Faster when it works, and on a slow machine it simply takes longer instead of lying.

This needs the output readable *while the process runs*, so `launch()` returns a `Launched` that drains stdout on a thread. That removes a second latent fault nobody had hit yet: `subprocess.PIPE` read only at the end means a chatty process fills the OS pipe buffer — 8 KB on macOS — and blocks on write until somebody reads it. Every scenario went through the wrapper rather than only this one, because two ways to read a process is the parallel path ADR-064 bans, in a file where the second one would rot unnoticed.

### Verification

`_on_peer_left` was planted to return at its first line. The scenario reaches its ceiling, prints *"gave up after 45s"*, and all three rows miss — so waiting for a marker did not make the check unfalsifiable, which is the obvious way this change could have gone wrong.

The full sweep is green, and so is CI.

### The lesson worth keeping

A check whose budget is a fixed sleep encodes an assumption about the machine it runs on, and it fails in the least useful direction: **it blames the product.** That cost an ADR paragraph, a filed task, and a wrong answer given with confidence. Where a check waits for something the process will say, it should wait for the thing it will say.

The `M3-T40` fix and its A/B are unaffected; only ADR-162's closing section is retracted.

---

## ADR-164 — The pile that asked for nothing

**Date:** 2026-08-30 · **Status:** accepted · **Implements `M3-T42`**

**Context:** Reported from play, at the end of the first session on a build containing the whole `M3` loop:

> There was no UI pop up or cue for talking with the dragon in the treasure room and its not very apparent what it is in the blockout.

Both halves are true and they are different problems. This ADR is the first one.

### The Pact tree was behind an unannounced interaction

Standing within `PLACE_REACH` of the pile and pressing `interact` opens `PactScreen` — her aspects, the whole tree, `DES-003`'s coupling of *what you hand over* to *what you may become*. Nothing told the player that. There was no prompt at the pile, no highlight on it, and the only sentence naming the verb lived in the corner readout **behind a condition**:

```
her aspects   2 boon unspent — hold e/X at the pile      ← only when boon > 0
her aspects   nothing yet — 40 more tribute buys the first   ← what a first life sees
```

A first life has no boon. So the player who has never seen the tree gets the line that does not mention the pile, and the player who already knows what the pile is gets the instructions.

### No check could have found it

Every row in `--lair-probe` reaches the tree by **calling** `_open_the_pact()`, or by dropping tribute through `ask_to_drop_instance`. All of them passed, correctly, in a room that announced nothing to anybody standing in it.

That is `M2-T18` again — *"the bag's rules were all correct and no click had ever reached them"* — in a second room, and it is the third time this shape has appeared this milestone. A rule can be right, replicated, saved, and unreachable.

### Through the reticle, not beside it

`Reticle` is already built by `room_set`, `threshold` **and** `chamber`; `DES-019` Layer 5 is *"interaction prompts — appears, then leaves"*; and the widget already names two things off the body — an item you could take, and the Shaft you are standing in. What it had no way to hear was a **room** saying *this is reachable, and here is the verb*.

So a level sets a standing offer and the reticle draws it. Precedence is the design's own: the Shaft speaks first (`DES-005` makes leaving the decision the floor is about), then the room's offer, then a loose item — a fixture that is asking you something outranks a coin on the floor. Nothing new arrives in the centre of the screen that was not there before, so rule 1 holds.

**It says something with nothing to spend, and that is the fix rather than a detail.** The version of this that prompted only when there was something to buy would have been invisible to exactly the player the report is about. With no boon it names her and the gesture — *"hold e/X — the hoard, and what she is owed"* — which is the thing worth saying to somebody who does not yet know what the room is.

Both glyphs, from `ControlsScreen`, per ADR-075 and ADR-139.

### Verification

Three plants, each failing by name:

| plant | the row that caught it |
|---|---|
| the room never speaks | *standing at the pile with nothing to spend, the room said nothing at all* |
| the offer is never withdrawn | *the prompt survived walking away from the pile* |
| the prompt does not name the verb | *the pile prompt does not name the verb — ADR-075 requires both devices* |

The row walks to the pile and away again, with `boon` forced to 0, because the clearing half is the half that goes wrong: a standing offer nothing withdraws points at something you have left behind, which is worse than silence because it is wrong rather than absent.

### What this does not fix

**She is still three grey boxes.** `_build_her` is an 11 m slab and two lumps, and *"not very apparent what it is"* is a fair description of that. This is blockout, which ADR-046 permits as a named production phase, and her real model is scheduled at `M4-T10`. The cue is what could not wait — a player who cannot tell the pile is interactive never reaches the tree, whereas a player who knows what to do at a grey shape has only been shown a grey shape.

---

## ADR-165 — Depth before polish, and gates asked where they can be answered

**Date:** 2026-09-01 · **Status:** accepted · **Resequences `M4`** · **Restates `GATE M3 EXIT`** · **Moves `GATE M3 COOP` to `M4`**

**Context:** the first play session on a build containing the whole `M3` loop, reported as:

> There is still not enough gameplay mechanic or level depth to test any of our gates or real flow. We need to change plan accordingly and move forward with more system design cohesively.

That is a correct reading of a real problem, and it is a **sequencing** problem rather than a scope one. Nothing below is added or cut.

### The gates asked questions this milestone cannot answer

`GATE M3 EXIT` asked whether *"a rank-8 player and a rank-1 player both die at similar rates for different reasons."* That needs two different reasons to exist. Every enemy in the build shares one stat line — `M3-T10` asserts it deliberately, because *"worse things, not bigger numbers"* is what this design would lose first — so the comparison has nothing to compare. It could not have failed and it could not have passed.

`GATE M3 COOP` asked for a newcomer downed repeatedly on a rank-8 floor. The floor can be built; the **experience** it names cannot, for the same reason.

So both move to `M4`, where `M4-T16` and `M4-T02` build the difference they are about.

### And the stranger session moves for the second time, on its own precedent

ADR-115 moved it out of `M2` because *"a first-time player is not a renewable resource, and spending one here spends them on six grey rooms with no classes, no Tithe and no ranks."*

**It is still those six grey rooms.** `M4-T01` replaces the Deep entirely with the Delvings, so wayfinding tested now is wayfinding against a level that is about to be deleted. Same sentence, same reason, one milestone later — and the fact that the argument recurs unchanged is the evidence that it is right rather than convenient.

### What `GATE M3 EXIT` becomes

The milestone is called The Pact. Its subject is `DES-003`'s coupling of what you hand over to what you may become, and whether that coupling is legible to the person doing it. That is answerable on the current build, solo, in one sitting — so the gate now asks it: **one life ends and the next is visibly a consequence of it.**

Four preconditions, and the third is there because ADR-164 found it failing three days ago: a first life has to reach the Pact tree without coaching. Until the pile had a cue, it could not.

### `M4·A` and `M4·B`

`M4` interleaved the systems that make a run worth playing with the presentation that makes it worth looking at. Ordered as written, the art pass, the shader, the composer and the accessibility suite would have been applied to a game with one enemy behaviour and six grey rooms.

This **serves ADR-061 rather than contradicting it.** That ADR cut `M4` from six classes to two so we would learn whether the game is good *sooner*; depth-first is how that is learned, because polishing a shallow slice tells you how a shallow slice looks.

`M4-T16` is filed ahead of `M4-T02` for the same reason: six archetypes on one behaviour is six ways to meet the same fight, which is content rather than systems (principle 5) and fails ADR-058's test — a new silhouette on the same behaviour is a bigger number wearing a face.

### Two things found in the check while doing this, and not fixed here

**`GATE M4 GREED` is invisible to `status.py`.** `GATE_RE` matches `(EXIT|COOP)` and nothing else, so the gate that ADR-109 called *"the whole game in one moment"* has never been parsed, never been counted, and could never have blocked `M5`. It is a gate in prose only. Same shape as ADR-098: it reads as alive and nothing calls it.

**The `question-open` check over-counts `M4`.** `OPEN-QUESTIONS.md` heads its section *"Needed at M4 / M5"* and every row in it is attributed to `M4` — including one that says in its own text *"scheduled as `M5-T05`"*, and two with no milestone at all. Nine of the twelve are art and audio questions that belong to `M4·B`; two of those can only be answered by a composer who has not been hired and at an FMOD licensing decision that has not arrived.

**Both are left alone deliberately.** Either one could be adjusted to make `M4` unblock sooner, and adjusting a check because it is inconvenient — while actively trying to get past it — is how a check stops meaning anything. They are recorded so the decision to change them is taken on its own merits, by a person, on a day when nothing depends on the answer.

---

## ADR-166 — What the Hunt is, and what it tells you

**Date:** 2026-09-01 · **Status:** accepted · **Closes Q75, Q77, Q80** · **Feeds `M4-T16`**

**Context:** `M4-T16` is enemy behaviour, and three questions about the Gullsjúkr and the Ear had been open since `DES-017` and `DES-018` were written. All three are load-bearing for it, and none of them could be answered by building — they are what the building is supposed to express.

### Q75 — a stave only when it was somebody

ADR-038 already makes the Hunter *rarely* a dead Bound, wearing that person's class silhouette and one distinguishing token, and it made it rare deliberately: *"if every Hunter is a dead friend it becomes cheap melodrama."*

A stave per kill would undo that from the other end. It would be a **kill counter wearing a memorial's clothes** — staves for strangers, planted beside staves for people, and a wall that no longer distinguishes them. So the stave is only for ADR-038's case, which costs nothing to implement because the death record and the boolean already exist.

What it buys is the document's own thesis standing in the camp as an object: the wall reads *people I knew, and people I put down*, and those are the same wall.

### Q77 — human sounds, never words

Confirming the lean `DES-017` already carried. It was a person; wordless human sound is how that is **shown**, and the moment it speaks the player is *told* instead — which is the thing this document spends its length avoiding.

Counting earns its place twice: it is dread, and it is information — the sound of something working through a room methodically rather than passing through it.

**With a cost that is not free.** `DES-018` requires every audio channel to have a visual twin, and from `M2` the build must be completable muted. So the vocalisations need one, or a muted player loses the cue that distinguishes a search from a transit. `M4-T16` carries that, not a later audio task, because the twin is a *behaviour* readout and not a decoration.

### Q80 — coursing versus sighted, coarse bearing, never position

The question reads as being about the Ear and is really about the **mix**: parity forces the Ear to show whatever the audio reveals, so deciding the Ear alone would have let the two drift apart, which is precisely the failure `DES-018` exists to prevent.

Principle 4 discriminates. *"It had sighted me and I kept looting"* is a death explainable in one sentence. *"It was somewhere"* is not — and that sentence is what `GATE M4 EXIT` asks a stranger for.

So the **state change** is revealed, because it is what makes `DES-005`'s stay-or-leave a decision. **Precise position is withheld**, because a position readout is a radar, and a radar converts the Hunt from a judgement into a reflex optimisation — which principle 3 puts second.

The question's final clause is a task rather than a flourish: *confirm the mix isn't accidentally revealing more than intended*. `HuntMix` is computed once per frame and feeds both channels (ADR-090), so there is exactly one place to audit and one place to assert it. `M4-T16` carries that too.

### What none of this decides

Whether the Gullsjúkr is *killable* at all at a given rank is `DES-017`'s existing ⟨tune⟩ — *"not at low Pact Rank, and possibly never by force alone"*. Q75 answers what happens **if** you kill one, and deliberately does not reopen whether you can.

---

## ADR-167 — The six art questions, and three rows that were never questions

**Date:** 2026-09-01 · **Status:** accepted · **Closes Q89, Q90, Q92, Q93, Q97, Q98** · **Schedules `M4-T17`, `M4-T18`**

**Context:** `M4` could not start with twelve questions filed against it. ADR-166 answered the three the Hunt needed; these are the rest. Answering them all now was chosen deliberately over reclassifying them, and it turned out to be the better call — four of the six were decidable on principles already written down, and two of them were not questions at all.

### Q89 — gear weight only, and that is the Clamor read

The question's own instinct was right and undersold itself as *"probably footsteps and gear weight only"*. A class does not get a voice, because the mix has one job during a run: telling you how loud **you** are. A Húskarl in mail and a Veiðimaðr in leather already differ in Clamor — so making them differ in sound is not decoration competing with the read, it *is* the read arriving through the channel that carries it. Learning the sound is learning the mechanic.

### Q90 — you keep the world and lose yourself

The Vörðr makes no sound at all. But the world does **not** go quiet, and the question's lovely instinct is the wrong one: muffling the room makes death *restful*, and `DES-012` wants a dead player still playing, still tense, still useful. Going quiet is how a game says *you may put the controller down*. The horror of the state is hearing the fight perfectly and contributing nothing to it.

Your own channel drops out and nothing else changes. No visual twin needed under `DES-018` — what is removed is the sound of a body the player can see is gone.

### Q93 — one shared interval, no shared instrument

Filed as *the composer's call*, and it is not: it asks whether the Deep is **one place**, which is a design answer the brief should carry rather than a preference to be discovered by whoever is hired.

Separate instrumentation for all three environments, and one interval in common — present in all three, nowhere else in the game, never stated plainly. `DES-022` makes the Deep one antagonist with three faces; total separation would make three antagonists. An *instrument* in common would be recognisable, and recognisable is the opposite of what the Deep is for.

### Q97 — constant ink

The ink is the game's handwriting, and handwriting that changes per room is three styles. The argument that settles it is not taste: `ART-005` reserves saturated colour for treasure, and an ink that is ochre in the Barrows has nothing left to say *this is worth picking up* in the one biome where ochre is also the ink. Atmosphere comes from the accent, the light and the material response, all already per-biome.

### Q98 — hard cut

Confirming the lean, on a systems argument stronger than the aesthetic one. `DES-014` builds the Threshold around a single irreversible gesture and `DES-005` makes leaving the decision the floor is about. A gradient makes the moment of commitment **unlocatable** — no frame at which the player crossed, so no frame they can regret. The hard cut gives the decision a timestamp. It is also cheaper and survives a loading transition.

### Q92 — never a design question

It asks a third party for commercial terms *at a future date*. The honest answer is not a licence tier: it is that nobody should write one down here, because a term recorded now expires silently and is then believed. ADR-050 already decided the thing that mattered — raw Godot first, FMOD only when the musician's workflow becomes the deciding factor — so no adoption is pending and nothing is blocked. The verification moves to `M4-T09`, where the adoption happens.

### And three rows that were never questions

`OPEN-QUESTIONS.md` carried three unnumbered rows that blocked `M4` while being unanswerable **by shape**: none of them has an answer that fits in a sentence, because each is a piece of work.

- **Onboarding / the first hour** already said in its own text *"scheduled as `M5-T05`"*. A scheduled task filed as an open question blocks a milestone twice and is addressable in neither place.
- **Item & weapon taxonomy** is a document somebody writes — now `M4-T17`, in `M4·A`, because `M4-T02` and `M4-T03` both want a table of what exists to swing, wear and carry.
- **A marketing plan** is `PRO-007`'s named failure mode — now `M4-T18`, in `M4·B`, tied to `M4-T08` by its own note that the devlog starts when the shader works.

**The lesson is about the table, not the rows.** A question with no answer-shape is a task wearing a question's clothes, and it blocks work while being impossible to resolve — which is how all three sat untouched from the design lock to here.

---

## ADR-168 — What the Ear reveals, decided against the literature

**Date:** 2026-09-01 · **Status:** accepted · **Sharpens ADR-166 (Q80)** · **Clarifies ADR-167 (Q90)**

**Context:** ADR-166 answered Q80 from this project's own principles — reveal the state change, withhold the position. That reasoning stands, and it was asked to be checked against design practice, player psychology and the genre's track record before `M4-T16` is built on it. It was. **The conclusion did not move; its precision did**, and three specifics came back that the principles alone did not produce.

### The evidence points both ways, and that is the useful part

**Stealth practice says reveal more.** The design literature is consistent that enemies should traverse *named, discrete* awareness states — at ease, curious, searching, alerted — and that the player must be told which one is current, because it is what "keeps the player in control" and gives them the chance to disengage. Detection meters and visibility gems exist for this reason.

**Horror psychology says reveal less.** Work on ambiguous threat finds that *spatial* and *temporal* uncertainty produce a distinctly anxious response, and that people faced with uncertain cues overestimate the probability of bad outcomes. The dread we want is manufactured by not knowing exactly where it is.

**Alien: Isolation is the case study that reconciles them.** Its motion tracker is deliberately imprecise — it reports movement and rough direction, not identity, distance or intent — and the imprecision is the design rather than a limitation. It also *costs* something: the alien learns to listen for the tracker's beeps, so the instrument that keeps you safe is the one that gives you away.

**And the genre supplies the failure mode.** Extraction shooters accumulate players posting variants of *"died out of nowhere, with no reason of death"* — Tarkov's forums carry them by the hundred — and the genre is widely described as one full of dead games. Principle 4 is not a stylistic preference in this genre; it is the churn mechanism.

The synthesis: **reveal the state, withhold the position.** Which is where ADR-166 already was. What the literature adds is *how*.

### The three sharpenings

**1. Two discrete states, never a continuous meter.** Coursing and sighted, plus the absence of both. Discrete states are learnable and attributable; a continuous bar invites optimisation by nudging — creeping forward to watch a number tick — which is principle 3's failure mode wearing a progress bar. This is the specific thing the stealth literature is right about and it costs us nothing.

**2. The transition is the event.** A readout you have to consult is a radar. A change that announces itself is a cue. The Ear marks the *moment* coursing becomes sighted, and that moment is the one a player remembers and can recount — which is exactly the sentence `GATE M4 EXIT` asks a stranger to produce.

**3. Coarse bearing is quantised, not attenuated.** Eight wedges of 45° ⟨tune⟩. A smoothly-varying needle is a position readout with extra steps: given two seconds of watching it, a player can triangulate. Quantisation is what makes the imprecision *structural* rather than a matter of how carefully you stare.

### The accessibility argument arrives at the same place

Deaf-accessibility practice names awareness indicators — *warn the player when an enemy is about to spot them, and from which direction* — as a baseline expectation, alongside directional indicators for sound. `DES-018`'s parity rule and the genre's accessibility standard therefore converge: state plus coarse direction is simultaneously the tension-optimal read and the accessible one. It is worth recording that they agreed, because the cases where they disagree are the expensive ones.

### Noted, not decided

Alien: Isolation's tracker **costs** the player something, and this project already has the economy for that: ADR-040 makes the compass an item, and `DES-019` describes the map, lantern and compass as *"three tools that give you information, each of which costs you something to carry."*

A carried instrument that sharpens the Hunter read — finer bearing, or range — would sit naturally in that economy and make information a thing you *equipped* rather than a thing the HUD gave you. **Not opened as a question and not scheduled**, because the free readout above has to be right on its own first, and because an instrument that improves it is only meaningful once there is something to improve. Recorded here so the idea is not re-derived from scratch at `M4-T13`, which is the task that already owns the instrument economy.

### What `M4-T16` inherits

- `HuntMix` computes both channels once per frame (ADR-090), so there is one place to assert what is revealed and one place for it to drift.
- The assertion is a **negative** as much as a positive: the mix must reveal state and coarse bearing, **and not distance, and not a continuous value**. A probe that only checks the state is present would pass a build that shipped a radar.

**Sources.** [Stealth game design principles](https://gamedesignskills.com/game-design/stealth/) · [Stealth AI states](https://www.gamedesigndiary.co.uk/post/design-stealth-part-2-ai-behaviours) · [Visibility Meter](https://tvtropes.org/pmwiki/pmwiki.php/Main/VisibilityMeter) · [The Underwood Project: eliciting ambiguous threat](https://pmc.ncbi.nlm.nih.gov/articles/PMC10700233/) · [Anticipation of uncertain threat](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6297831/) · [Alien: Isolation motion tracker](https://alienisolation.fandom.com/wiki/Motion_Tracker) · [Deaf accessibility in video games](https://www.gamedeveloper.com/audio/deaf-accessibility-in-video-games) · [Fortnite's sound visualiser](https://accessibility-labs.com/feature-highlight-fortnites-sound-visualizer/) · [Tarkov: "died out of nowhere"](https://forum.escapefromtarkov.com/topic/134336-was-running-to-an-extract-and-i-died-out-of-nowhere-with-no-reason-of-death/) · [Extraction shooters: a niche full of dead games](https://gaming.news/codex/extraction-shooters-explained-niche-genre-full-of-dead-games/)

---

## ADR-169 — Topology before geometry, and the seed nothing was reading

**Date:** 2026-09-01 · **Status:** accepted · **`M4-T01` in progress**

**Context:** `M4-T01` is the Delvings — `DES-015`'s eight-step pipeline, costed in that document at ⟨1–2 months⟩ and called *"the single highest-leverage technical investment in the project."* This records the two decisions taken before any of it was written, and the fault found while taking them.

### What was actually there

Nothing. `room_set.gd`'s "generation" is six literal `AABB`s in a `const ROOMS`, six literal doorways, and three literal enemy posts. `M4-T01` is not improving a generator; it is writing the first one.

### Decision 1 — the graph, before any geometry

Step 3 of the pipeline is built and steps 4–7 are not. `MissionGraph` produces nodes, edges and roles: no rooms, no metres, no meshes.

Three reasons, in order of weight:

1. **The design risk is topological.** Whether a floor poses a decision is a property of its shape — a cycle means the way back is not the way in, which is the whole of `DES-015` Layer 1. That can be asserted with no art, no navmesh and no scene, and 1200 floors validate in under a second.
2. **It defers the room-module contract until the graph can state its requirements.** `M4-T01` says *"generation from room modules"*, and a `RoomModule` resource designed before anything consumes it would be a guess. The graph will say what a module needs to expose — sockets, footprint, which roles it can host — and then it gets written.
3. **`DES-015` step 8 is mostly a graph question.** Exits reachable, Prize reachable, the ADR-032 bypass, no soft-lock. Catching those here costs nothing; catching them after placement costs a re-roll of work already done.

The structure is a spine with one or two alternate arms rejoining it. The Prize sits inside the first arm's span and the Shaft beyond its rejoin, so both routes reach the way out and only one is held. **That is not a new idea** — it is the hand-authored room set's own recorded finding, that confining danger to one branch makes *"west long and safe, east short and held"*. The generator's job is to keep producing that property rather than rediscover it by luck, which is what `problems()` is for.

### Decision 2 — determinism is asserted in both directions

`check_determinism.py` has passed `--seed=` on every run since `M1-T07`, and **nothing in this project has ever read it.** `room_set.gd` does not contain the word. The layout is constant, so every seed yields an identical hash and the harness has been asserting that a constant is constant.

That is not a criticism of the harness. `WorldHash`'s own header says so plainly — *"what it currently proves is real but modest… coverage grows the day `M4-T01` lands"* — and being written before the generator is what makes it a **specification** rather than a description of whatever the generator happens to do. ADR-098's distinction applies exactly: it works, and until today nothing used the part of it that mattered.

But it means the harness catches *"the engine introduced variance"* and cannot catch the failure a generator actually has: **ignoring its seed.** A generator returning one floor forever is perfectly deterministic and passes `check_determinism.py` at every seed.

So `--graph-probe` asserts both directions — *same seed, same graph* **and** *different seed, different graph*. The plant is the proof:

```
plant: the generator ignores its seed
  [graph] same seed    identical          ← passes
  [graph] seed matters 1 distinct from 400 ← FAILS
```

### The check found a real weakness immediately

The first generator emitted **82 distinct topologies from 400 seeds** — a floor space a player would start recognising inside an evening, which is the flatness `DES-015` opens by diagnosing. The assertion was kept and the generator widened rather than the reverse: the spine now grows with depth (`DES-015` Layer 4 wants depth to be visible, and a longer floor is the structural half of that), and a floor may carry a second arm. 308 distinct from 400, and the three floors of one expedition can no longer be the same size, so they can no longer be the same floor.

### Verification

Four plants, each caught:

| plant | caught by |
|---|---|
| the generator ignores its seed | *400 seeds produced only 1 distinct floor* |
| no alternate arm | *1026 of 1200 floors failed step 8* · *the bypass does not reach the Shaft* |
| the Shaft inside the held span | *1200 of 1200 failed step 8* · *ADR-032's way round does not exist* |
| the Prize outside the held arm | *the greedy line is also the safe one and the cycle costs nothing* |

Validation runs over 1200 generated floors rather than one, because `problems()` is a claim about every floor the generator can emit and a single sample proves nothing about a random process.

### What is not done

Steps 4–7 — space, history bias, machines, population — and the `RoomModule` resource. `WorldHash` does not yet consume the graph, so `check_determinism.py` still measures the hand-authored rooms; wiring it is what makes that harness mean across processes what `--graph-probe` means within one.

---

## ADR-170 — The generator, chosen from the field rather than from the one paper we had

**Date:** 2026-09-01 · **Status:** accepted · **Adopts `TEC-007`** · **Narrows `DES-015` step 8** · **`M4-T01` in progress**

**Context:** `DES-015` Layer 1 adopts cyclic dungeon generation, cites Dormans & Bakkes (2011), and stops — the right amount of detail for a design document and not enough to build a month of work from. It never says how a graph becomes a space, which techniques were considered, or which of them our own constraints forbid. ADR-169 built step 3 and deliberately deferred everything after it. This ADR adopts `TEC-007`, the review that was supposed to happen before steps 4–7 exist.

### The review's job was to be able to say no

It can. Two techniques that a reasonable person would reach for are ruled out by constraints we already hold, and saying so here is cheaper than discovering it in a desync:

- **Answer Set Programming** is the strongest rejected alternative and deserves the record. It is the only surveyed technique that would make `DES-015` step 8 unnecessary, because the validity conditions become the generator and a soft-lock is then unrepresentable. It dies on two independent grounds: solver tie-breaking is not a stability contract, and `TEC-004` needs a promise rather than a reproducibility that holds until a version bump; and there is no GDScript-native solver, so adopting it means a native dependency on four platforms, on a solo project, for a subsystem that has a working alternative.
- **Wave Function Collapse** cannot express a global reachability constraint — it is a local propagator and "the Prize is reachable without passing the held arm" is not local. The standard workaround is generate-and-test, which is unbounded search against `TEC-001`'s 2 s budget.

Neither is a close call, and neither was obvious before the constraints were written down together.

### The finding that made the review worth doing first

The graph stage is healthy: 1200 floors built with 0 invalid, same seed identical, 308 distinct graphs from 400 seeds. **That number measures the wrong thing.**

`build()` is a fixed construction — a spine, one arm from `leave` to `rejoin`, the Prize on the spine inside that span, the Shaft past the rejoin, plus zero or one further arms. There is no branch that can produce a second topology class. All 308 graphs are the same *kind* of floor with different numbers in it. The digests differ; the shape does not.

That is `DES-015`'s own diagnosis of Dark and Darker, one level up the stack: *the randomness is in the stuff, not the space.* We moved it into the space and stopped one step short. A player who learns "the Prize is on the loop, the Shaft is past where the loop closes" has learned every floor this generator can produce.

Dormans' actual contribution is not "put a loop in it" — it is that **the type of cycle is the design content.** So step 3 gains a **cycle-type catalogue** applied by seeded rewriting: danger-and-detour (the current shape), lock-and-key, foldback, two-fronted, shortcut, nested. Each names a question the floor asks, which is `DES-015` Layer 3's test for machines applied one level up.

Had steps 4–7 been built first, all of that work would have had its variety ceiling fixed before any of it started. This is the concrete answer to "why not just keep building."

### Decision 1 — the technique, and the pipeline it implies

Cyclic graph rewriting over a named cycle catalogue for topology; integer-grid module placement with bounded, seeded backtracking for space; Brogue machines stamped into sockets. WFC and constraint solving rejected for topology. `TEC-001`'s existing choice of authored modules over generated geometry is not reopened.

The Spelunky lesson is adopted as a general pattern rather than as an algorithm: **guarantee by construction, then assert anyway.** The graph already does this — `build()` places the Shaft and Prize so that reachability and the ADR-032 bypass cannot fail, and `problems()` checks them regardless. Every later stage inherits that shape.

### Decision 2 — the determinism rule was protecting against the wrong thing

`mission_graph.gd`'s header says nothing iterates a `Dictionary` because traversal order is not a promised invariant. The conservatism is right; the reason is wrong, and a wrong reason defends the wrong border.

Measured on Godot 4.7: `Dictionary` iterates in **insertion order**, forward and reverse, and two dictionaries holding the same keys inserted in different orders iterate differently. `RandomNumberGenerator` gives identical sequences for identical seeds over 10 000 draws.

So a `Dictionary` is not a nondeterminism source. The hazard is one step back — **iteration faithfully reproduces insertion order, and insertion order is a function of call order.** Two machines building the same collection by different code paths diverge with no hash table involved. The rule that actually holds is *never let a decision depend on the order a collection was built in; sort by an explicit total order first* — which also covers rewrite-rule candidate matching, where enumeration must be sorted by node id.

Also decided: **own the seed mix.** `hash("%d:%d:%d")` is safe against desync, since every player in a session runs the same binary, but it is not a contract across engine versions — and `TEC-001` calls the run seed's shareability non-negotiable, which means a seed in a bug report should survive a Godot upgrade. A SplitMix64-style integer mix we own costs about an hour.

### Decision 3 — `DES-015` step 8 says two things that cannot both hold

Step 8 requires *"navmesh sane"* and requires that validation be deterministic because *"a re-roll that happens on one machine and not another is a desync."* Runtime navmesh baking is Recast, voxel-based, and threaded per platform. It is not a bit-exactness substrate, so a bake-triggered re-roll is exactly the desync the second clause forbids.

Resolved by splitting the two jobs the word "validate" was doing:

- **Traversability is decided on the integer generation grid, before any bake.** Deterministic, and the only thing that may trigger a bounded re-roll.
- **Navmesh sanity is a build-time assertion** over a seed corpus, in the sweep and in CI, failing the build. It never runs as a gameplay decision, so it cannot desync anything.

Step 8 keeps its teeth. This narrows an accepted document, which is why it is here and not a silent implementation choice.

Re-roll itself is bounded and seeded — sub-seed from `mix(stage_seed, attempt)`, a hard cap, and loud failure on exhaustion. **No fallback generator**, which ADR-064 forbids and which would otherwise be the obvious thing to reach for: two generators, one never tested, both needing determinism.

### What the review found in the tree, which is not a design decision

`--graph-probe` **is not run by anything.** It exists in `room_set.gd`; ADR-169 describes it as the check asserting determinism in both directions; `check_scripts.sh` does not invoke it and neither does CI. Across the whole repository the string appears only in `room_set.gd`, a comment in `mission_graph.gd`, the M4 brief, and ADR-169. It reads as alive to `check_dead.py` because `room_set.gd` calls its own handler — the "does anything use it?" gap ADR-098 exists for.

**ADR-169's central claim is therefore currently true only when somebody runs the probe by hand.** Wiring it in is `M4-T19` and comes before further generator work.

Related: the variety row counts distinct digests, which cannot tell 308 different floors from 308 numberings of one floor. When the catalogue lands it needs a companion assertion counting distinct *cycle types*, or it will keep passing while the catalogue is ignored.

### Cost

⟨5–6 weeks⟩ across catalogue, `RoomModule` and placement, steps 5–7, and extended validation — inside `DES-015`'s own ⟨1–2 months⟩ costing. Measured aside: the whole graph probe, 1200 floors plus a 400-seed census, runs in about a second including engine boot. Step 3 is free at floor scale; the 2 s budget belongs to steps 4–7 and the navmesh bake, and the bake is the thing to measure first.

### Rejected

- **Building steps 4–7 on the existing single-topology generator.** Cheapest today, and it fixes the variety ceiling before the expensive work starts.
- **Adjusting the variety threshold rather than widening the generator.** The same choice ADR-169 already faced at 82 topologies and answered the same way.
- **Treating the `--graph-probe` gap as a fix to fold into this change.** It is a task with an ID, not a quiet repair inside an ADR about something else.

### What `M4-T01` inherits

In order: wire the probe (`M4-T19`); own the seed mix; the cycle catalogue with a type-counting assertion; `RoomModule` and step 4; `WorldHash` on the generated floor; steps 5–7 and extended step 8.

Signed off 2026-09-01. `TEC-007` is `accepted` and `DES-015` step 8 is edited to carry Decision 3, which is the only accepted document this ADR changes.

---

## ADR-171 — The catalogue is five types, and a seal has two ends

**Date:** 2026-09-01 · **Status:** accepted · **Amends `TEC-007` §5.1 (ADR-170)** · **`M4-T01` in progress**

**Context:** ADR-170 adopted `TEC-007`, whose §5.1 proposed six named cycle types for `DES-015` step 3. Building them found one that cannot exist at this layer and one that did not work as specified. Both were found by checks rather than by reading, which is the argument for having written the checks first.

### Decision 1 — `two-fronted` is not a topology, and is dropped

`TEC-007` §5.1 proposed **two-fronted**: both arms held differently, so there is no safe route, only a choice of danger. It is cut, and the catalogue ships as five.

It is a category error. At the graph layer "held" means exactly one thing — the nodes a route may not use if it is to count as an ADR-032 bypass. So marking both arms held has only two possible readings, and both are wrong:

- If `_held` really covers both arms, **there is no bypass**, and ADR-032 wants a way out that does not cross the danger. The floor fails `problems()` by construction, and rightly: the Prize stops being a choice and becomes a toll.
- If `_held` covers only the Prize's arm and the other arm is merely *dangerous*, then the graph is identical to `danger-detour`. The difference lives entirely in what gets placed on the second arm, which is `DES-015` step 7 — population, not topology.

So the interesting version of "both ways are bad" is real, and it is a **population** decision belonging to step 7. Recorded here so it is not re-derived as a topology later. Shipping it as a sixth type would have been variety on the digest and nothing on the floor — the exact failure ADR-170 exists to prevent, wearing a catalogue.

### Decision 2 — a key-gated span is sealed at both ends

`lock-and-key` shuts the short way and puts the opener down the long one. As specified it gated one edge, the near end of the held span. **275 of 1200 floors failed step 8**, all with the same fault: *the Prize can be reached without opening the locked span, so the lock decides nothing.*

The held span has two ends. Gating only the near one left it reachable backwards from the rejoin, by walking the quiet arm and turning round — so the key opened a door with a hole beside it. Both ends are gated now, and extra arms on a `lock-and-key` floor are drawn wholly beyond the rejoin so none can span the seal.

This is the case ADR-169's *"widen the generator, not the tolerance"* was about, arriving in the other direction: the check was right, the generator was wrong, and the fix was structural rather than a threshold.

### Decision 3 — the validity row reports every fault on a floor, not the first

`--graph-probe` printed `faults[0]` for the first invalid floor. A floor is usually wrong in more than one way, and reporting one fault means the fix for the loudest ships beside the quiet one it was masking.

Found by planting. Writing `KEY` over a spine index inside the seal to plant *the key is behind the door it opens* also deleted the Prize that had been placed on that node, so the floor was wrong twice and the probe named the other one. The row had fired correctly and was invisible. The plant was then narrowed to one meaning, and the reporting widened to all faults — **the reporting change makes the check more legible, never weaker**, which is the only kind of check adjustment permitted while trying to get past one.

### What the catalogue is worth, measured

| | before ADR-170 | now |
|---|---|---|
| distinct digests / 400 seeds | 308 | 372 |
| distinct topology *classes* | 1 | 5 |
| invalid floors / 1200 | 0 | 0 |

Across 1200 floors: `danger-detour` 273, `foldback` 229, `lock-and-key` 276, `shortcut` 250, `nested` 172. `nested` is lower because it is legal only from floor 1 (⟨tune⟩), which is deliberate — `DES-015`'s three floors escalate.

Six assertions were planted before being believed: the seed-mix known answer, a cycle type nothing emits, one shape past half the floor space, the key behind its own door, the Shaft beside the entrance, and a cost gate as the only cycle.

### Rejected

- **Keeping `two-fronted` as a sixth type by relaxing ADR-032 on floors that use it.** A bypass rule with an exception is not a rule, and the exception would be invisible to `problems()` — which is where every soft-lock in this project is going to be caught.
- **Gating the whole held span as one object rather than two edges.** An edge is what a gate physically is once step 4 turns it into geometry; a "span gate" would need translating into edges anyway, later, with less information.
- **Reporting all faults for every invalid floor rather than the first.** 275 invalid floors × several faults is a wall of text nobody reads. One floor, fully described, is the useful unit.

---

## ADR-172 — The floor is the mission, and a search budget fails like a constraint

**Date:** 2026-09-01 · **Status:** accepted · **Implements `TEC-007` §5.2 (ADR-170)** · **`M4-T01` in progress**

**Context:** ADR-169 deferred the `RoomModule` contract so the graph could state what it needed rather than have somebody guess. `DES-015` step 4 turns that graph into a space. The whole risk of the step is that the space stops being the graph — every guarantee the topology passed is about routes, and routes become geometry the moment geometry exists.

### Decision 1 — rooms never touch, and connectivity is read back off the grid

Rooms are seated one per cell of a coarse **lattice**, each rectangle inset inside its own cell, so two rooms **cannot** overlap or touch. Every graph edge is then routed as a corridor through the margins, and a corridor joins rooms **only at its two doors**.

The alternative — let rooms share a wall and call the shared edge a link — cannot be made safe. Two rooms that are not graph-neighbours will end up flush during packing, and then either they are joined, which is a route ADR-032 never authorised, or they are not, and the level contains a wall indistinguishable from every other wall that happens to be the one the player cannot open. A mandatory gap makes accidental adjacency impossible instead of detectable.

`problems()` then asserts it anyway, and asserts it **independently**: `realised_links()` reads which rooms each corridor joins off the grid, not from the graph that asked for it. That independence is the entire value. A corridor that clipped a third room shows up there and nowhere else.

Adjacency turned out not to be connection, which cost a debugging pass: a corridor threading a gutter runs *past* three or four rooms and opens into exactly two. Links come from doors.

### Decision 2 — corridors may cross, and may not merge

A shared corridor cell would join four rooms where the graph joined two. Crossing at different heights does not: a **bridge** cell carries two routes and no doors, so the floor's shape changes and its meaning does not. Only a single, straight-running corridor may be bridged, square-on — there is nothing to be perpendicular to at a corner, and a cell carrying three routes is a junction nobody can build. Both are asserted.

`DES-015` asks for this independently: *"shafts and chasms you can look down into and see the next floor, while traversal still happens via stairs."*

**Measured, because "it helped once" is not a reason to keep a mechanism.** With crossings forbidden, 360 floors cost 458 re-rolls and one floor could not be laid out at all. With them, 4 re-rolls and none. Kept on that number.

### Decision 3 — the search budget was the bug, and it did not look like one

Placement failed on 82 of 360 floors. The message was *"no corridor could reach 5 from 4"*, which reads as a geometry failure, and it was diagnosed as one **twice**: first the lattice was too tight, then the graph was non-planar and needed a crossing mechanism. Widening the lattice from 12 to 15 made it **worse** — 6 invalid floors became 17 — and that was the tell, because a bigger grid costs more cells to search.

The router's cell budget was 4000. It was giving up mid-search on the larger floors. At 24000 the same corpus and the same generator plan 360 floors with **zero failures and four re-rolls between them**, in 11 seconds rather than 77.

Recorded as a decision because the lesson generalises past this constant: **a search budget that is too small fails like a constraint violation.** Nothing in the failure said "I ran out of room to look", and two plausible structural explanations fitted the evidence first. Bounded search wants a distinguishable exhaustion signal, and the next bounded search in this project should have one.

Two of the three fixes were kept regardless — the crossing mechanism pays for itself on its own numbers, and the lattice went back to 12.

### Decision 4 — the corpus is asserted to cover what the generator can ask for

A node's role and link count are properties of the topology: several arms can rejoin the spine at one node, so a Shaft can be a five-way junction. Each time the vocabulary fell short the symptom was one unplaceable floor in a hundred and the diagnosis cost a probe run — twice.

So `--plan-probe` asserts **coverage**: every `(role, links, held, depth)` the generator emits over 360 floors has a module that could serve it. 54 demands, 0 unserved. A corpus falling behind the generator now says so in one line instead of presenting as a rare placement failure.

### Decision 5 — `RoomModule` carries only what step 4 consumes

Volume profile, vista affordance and prop weighting are all named in `TEC-007` §5.2 and all **absent**. Steps 5–7 read them and steps 5–7 are not built. A field nothing reads is a dead name that `check_dead.py` cannot see, because a `.tres` mentions it — the ADR-098 gap with a data file standing in for a call site.

Empty `roles` means **connective tissue only**, not "anything". A corridor must never stand in for the Guardian's chamber because nobody wrote down that it could not.

### What the check caught that reading would not have

The `seed matters` row — 120 distinct spaces from 120 seeds — **cannot detect a placer that ignores its own seed**, and looked like it could. The graph varies with the seed too, so a frozen placer stream still yields 115 distinct spaces from 120 and sails through. Found by planting it.

That is ADR-169's finding one layer down, and it now has the assertion that bites: **one graph, sixty seeds, and the layouts must differ.** Every stage added after this one needs its own version of that row, because the whole-pipeline variety row will keep passing without it.

### Rejected

- **Sharing walls instead of a gap.** Decision 1.
- **Forbidding crossings.** 458 re-rolls per 360 floors against 4, and a floor that could not be laid out.
- **A wider lattice.** Tried, measured, worse.
- **Deriving `realised_links()` from the routing record rather than the grid.** It would agree with the graph by construction and assert nothing.
- **A simpler placer to fall back on when routing fails.** ADR-064. The floor is not offered rather than quietly made worse.

---

## ADR-173 — The determinism harness finally measures the generator

**Date:** 2026-09-01 · **Status:** accepted · **Completes ADR-169's second half** · **`TEC-007` §11 item 5** · **`M4-T01` in progress**

**Context:** `check_determinism.py` has run in CI since `M1-T07`. It generated the same seed in two processes, hashed the resulting world, and asserted the hashes matched. It passed every time, and until this change it could not have failed for any reason connected to the generator: `room_set.gd` never parsed `--seed=`, and the world it hashed was six literal `AABB`s in a `const`. The harness was asserting that a constant is constant.

ADR-169 named this and fixed half of it, in `--graph-probe`, **inside one process**. The half that was still missing is the one `TEC-004` actually needs: the host sends a seed, every client builds the floor from it, geometry is never replicated, and a divergence is two players disagreeing about where a wall is. That is a claim about *separate processes*, and nothing was making it.

### Decision 1 — the hash covers the floor that was decided, not only the one that was built

`WorldHash.digest()` takes an `extra` array of rows alongside the scene tree, and `--hash` fills it with the graph and plan digests for all three floors of the given seed.

`M4-T01` generates a floor as data before it generates it as geometry, and that data is exactly what two machines must agree about. Hashing only the scene tree would have kept measuring the hand-authored rooms and calling it a determinism guarantee until blockout geometry existed — which is months of the guarantee not existing while a green check says it does.

### Decision 2 — the seed is read before any switch is dispatched

`check_determinism.py` passes `--hash --seed=N` **in that order**. Parsing the seed in the same pass that dispatches switches would have hashed seed 0 every time, and the harness would have gone green while proving nothing — the identical shape to the bug ADR-169 found, in the code written to fix it. The seed now gets its own pass first.

### Decision 3 — the harness asserts both directions, like the probe does

Same seed → same world was the whole check. It is the half a generator that ignores its seed passes perfectly. `check_determinism.py` now also builds a second, unrelated seed and requires a **different** hash.

Verified in both directions rather than assumed: seeds 111 and 222 produce different digests, two processes on one seed produce identical ones, and forcing `_run_seed = 0` makes the run fail with `SEED IGNORED` rather than pass.

**Every stage added after this needs its own version of this row.** `--plan-probe` already found the same trap one layer down — its whole-pipeline variety row could not see a placer with a frozen stream, because the graph varied underneath it — and the pattern will keep recurring, because a stage that ignores its input is always perfectly deterministic.

### What this costs

Two extra process launches per CI run and one more seed's worth of generation. The harness went from proving the engine introduced no variance to proving the generator is bit-identical across processes, which is the guarantee `DES-015` and `TEC-004` both depend on and the one `TEC-007` §11 put fifth precisely so it would land before steps 5–7 were built on top of it.

### Rejected

- **Waiting for blockout geometry so `WorldHash` could see the floor in the scene tree.** The guarantee would not exist until then, and the check would stay green throughout — the worst combination available.
- **A separate cross-process generator harness beside this one.** Two harnesses making overlapping claims, one of which would rot. This one already ran in CI and already had the process-launching machinery.
- **Hashing the plan only, not the graph.** The graph is what the Hunt, the contracts and the Sealing will read. A desync in it would not show up in a plan digest that happened to match.

---

## ADR-174 — The history reaches the architecture, and two rows that could not fail

**Date:** 2026-09-01 · **Status:** accepted · **`DES-015` steps 2 and 5** · **`TEC-007` §11 item 6, in part** · **`M4-T01` in progress**

**Context:** `DES-015` Layer 2 is the cheapest thing in the whole design — *"generate the history first, then generate the space to express it"*, costed at *"a weighted prop/room table keyed on depth"* and called an absurd return on investment. It is also the layer that decides whether a floor is a place where something happened or a set of rooms. This builds it: the roll (step 2) and the bias it puts on what gets built (step 5).

### Decision 1 — the Calamity expresses itself as tags a room can carry

A `CalamityResource` names room *flavours* rather than text. Five are authored for the Delvings — the deepening, the drowning, the sealing, the turning, the waking — and per ADR-018 they are variations on one story rather than unrelated disasters: the Dvergar mined the seam her hoard grew from and then they kept mining, and what differs is how that ended.

Room modules carry matching tags, and a module sharing a tag with the rolled Calamity is **weighted up** rather than exclusively selected. Filtering would make every room of an expedition say the same thing; `DES-015`'s payoff is a floor you can read, not one that shouts. Neutral rooms — the majority, and not a gap — are the quiet between the evidence.

The Prize is a harder constraint: the history promises a vault or a barrow, and the room the player finally walks into has to be the one promised, so the Prize node's module must declare the rolled kind.

**What is not built:** the legibility rule — *the Calamity readable within 30 seconds of arriving* — is a claim about what a room looks like, and there is no art. It is an obligation on the `M4·B` art pass, not something this layer can assert.

### Decision 2 — the Claimant is rolled before anything reads it, and has no accessor

The Calamity and the Prize both have readers. The Claimant does not: who holds the Prize becomes visible through enemies, and enemies are `M4-T02`.

It is rolled anyway, for **seed stability**. `TEC-001` calls the run seed's shareability non-negotiable, and adding a third draw to this stream later would shift every subsequent value and silently repurpose every seed anybody had written down. One value now fixes the stream's shape.

`check_dead.py` then refused a `claimant()` accessor, and was right to — a getter nothing calls is a name that reads as alive and answers no question. The value is rolled, hashed and agreed across processes; the getter arrives with the enemies that read it. That is the distinction ADR-064 draws between *absent* and *stubbed*, holding at the level of a single function.

### The two rows that could not fail, both found by planting

**The bias row was comparing labels, not floors.** It builds one graph and lays it out under every Calamity in turn, requiring the results to differ. It used `FloorPlan.digest()` — which folds in the history, because two machines must agree about what happened here before they build a room from it. So five Calamities differed by their own names and the row passed with `favours()` hard-wired to `false`. It now uses a `module_digest()` that carries the architecture and no history, and fails correctly.

**The coverage row was missing a dimension.** ADR-172 added it precisely so a corpus falling behind the generator would say so in one line instead of presenting as a rare unplaceable floor. It keyed on `(role, links, held, depth)` and not the Prize kind — so a `vault` node with three corridors passed coverage and then failed placement, 22 floors in 360. **The class of failure that row exists to make loud was hiding inside that row.** Coverage now includes the kind: 72 demands, 0 unserved.

Both are the same mistake in different clothes: an assertion whose subject is not quite the thing it claims to be about. This is now the third instance in `M4-T01` — after the graph variety row counting digests rather than shapes (ADR-170) and the plan variety row that could not see a frozen placer stream (ADR-172) — and the pattern is worth stating plainly:

> **An assertion built from a convenient existing value tends to measure that value, not the property.** Ask what the row would say if the feature were deleted, then delete it and check.

### Measured

```
[plan] calamities  5 authored, 4 prize kind(s)
[plan] history     61 distinct history/histories from 120 seeds
[plan] bias        5 distinct floor(s) from 5 Calamities on one graph
[plan] coverage    72 demand(s), 0 unserved
[plan] validity    360 floor(s) planned, 0 invalid, 2 re-roll(s)
[plan] the floor   foldback under cal_the_drowning/seam/dvergar_remnant:
                   12 room(s), 182 corridor cell(s), 13 link(s)
```

Four assertions planted: a roll that ignores its seed, a Calamity that never reaches the rooms, no authored Calamities at all, and a Calamity with no rooms that answer to it. The history is folded into `WorldHash`, so two machines must agree on it before they build.

### Rejected

- **Filtering to on-theme modules instead of weighting them.** Every room saying the same thing is the flatness `DES-015` opens by diagnosing.
- **Rolling the Claimant later, when enemies exist.** Every logged seed would change meaning.
- **Keeping a `claimant()` accessor "for when it is needed".** That is the shape of every dead name ADR-098 was written about.
- **Asserting the 30-second legibility rule now.** It is about what a room looks like, and there is no art. Naming it as an `M4·B` obligation is honest; asserting it against blockout would be a check that means nothing.

---

## ADR-175 — Worked stone to raw cave, and the three elements the floors were missing

**Date:** 2026-09-01 · **Status:** accepted · **Adopts `TEC-008`** · **Implements `DES-015` step 4's geometry half** · **`M4-T01` in progress**

**Context:** `M4-T01` generates a floor as data and nothing builds it. Before writing a `FloorBuilder`, ten generated floors were drawn as plans and looked at. They are legible as diagrams and **indistinguishable as places** — ten scatters of rectangles joined by identical one-cell corridors. The cycle type differs, the modules differ, the Calamity weighting differs, and none of that is visible from inside.

That is not a generator fault. Topology cannot produce spatial character, and `DES-015` already warns that *"2D grid" must never read as "boxes and corridors."* Geometry is where the promise is kept, so it was worth researching before building rather than after.

### The finding, from Lynch

Kevin Lynch's *The Image of the City* (1960) names the five things people build mental maps from: paths, edges, districts, nodes, landmarks. Held against the floor sheet, the diagnosis is exact.

**Our floors have paths and nodes. They have no edges, no districts and no landmarks.** The generator's weakness was never variety — 372 distinct digests and five topology classes is plenty. It is that a player standing in one has nothing to build a mental map *out of*. Every decision below adds one of the missing three, cheaply and generatively.

### Decision 1 — the cell is 2.0 metres, derived rather than picked

`FloorPlan` was unitless. One cell is 2.0 m because it is the only value that reconciles three independent constraints: a one-cell corridor becomes 2.9 body-widths, so two players pass and a player plus a Draugr is a squeeze; the authored corpus lands on the hand-built scale (`prz_sealed_vault` at 8×8 m against the built guardian room's 10×10 m); and the largest module is a 10×10 m great hall rather than a plaza. Halving it makes corridors impassable, doubling it makes the smallest module a 20 m square.

Generated space also inherits the shipped conventions — 4.0 m walls, 0.6 m thickness, 2.4 m doors — because generated and hand-built rooms sharing a level and not sharing a scale is the fastest way to make both look wrong.

### Decision 2 — depth is a gradient from worked stone to raw cave

`DES-015` reads the disaster backward as you descend, and ADR-018 says the Delvings' Calamity is *"the Dvergar mined the seam her hoard grew from. Then they kept mining."* That is a geometry instruction and it was free to take.

One parameter — *roughness*, 0 on floor 1 and 1 on floor 3 — drives corner chamfer, ceiling variance and floor stepping. Floor 1 is orthogonal Dvergar working; floor 3 is the thing they dug into. The player descends and the architecture stops being architecture.

This is Lynch's **districts**, and it is the direct fix for what the sheet exposed: three floors of an expedition become three *places* rather than three sizes, from one number.

### Decision 3 — three cross-sections, and `RoomModule.volume` finally has a reader

Real cave passages come in recognisable morphologies — phreatic (rounded, water-cut), vadose (tall, narrow, directional), breakdown (angular, collapsed, wide). Three shapes. A cave using all three reads as a cave; one using a single shape reads as a tunnel with the width randomised, which is what "make it irregular" produces if taken literally.

`RoomModule` gains `volume` — `CRAWL` 1.4 m, `LOW` 2.4 m, `HALL` 4.0 m, `GREAT` 7.0 m. It was deliberately withheld from ADR-172 because nothing read it and a `.tres` mentioning a field is a dead name `check_dead.py` cannot see. Geometry is its reader, so it arrives now.

`CRAWL` at 1.4 m is set against the body, not chosen for looks: it clears the 1.15 m crouch and refuses the 1.80 m stand. It is a mechanical space — you crouch, you slow to 1.6 m s⁻¹, your Clamor drops and you cannot swing. `DES-009`'s crouch verb gets a room that demands it.

### Decision 4 — four generated devices for prospect, refuge and mystery

Appleton's prospect–refuge (1975) explains why ledges over halls and alcoves read as good places; the Kaplans' **mystery** (1989) — the promise of more if you move deeper — is the one a straight corridor between two rectangles has *none* of. You can see the whole proposition from the doorway.

1. **Ledges over `GREAT` rooms** at ~2.5 m: prospect, and Lynch's landmarks. This is the vista rule's delivery mechanism and ADR-014's *"verticality lives inside rooms"* made concrete.
2. **Corridor dog-legs** — a corridor of three cells or more bends at least once. One cell of routing slack buys mystery outright.
3. **Alcoves** in rooms 3×3 and larger: refuge, cover, and an irregular wall line so the room stops being a rectangle. Lynch's edges.
4. **Depth as district** — Decision 2, doing double duty.

### Decision 5 — blockout builds structure, not surface

`DES-009` adopts Swink's ordering: blockout must feel good unjuiced. In scope now are volumes, ceilings, floors, walls, doorways, ledges, alcoves, chamfers, the gradient and collision — all structural, all generated. Out of scope are textures, props, decals and decorative meshes.

The asymmetry is the reason: a floor that reads as a cave in grey boxes will read as one when textured, and the reverse is not true. Detailing a floor that does not read is the expensive mistake, and it is expensive exactly once the art exists.

### Rejected

- **Marching-cubes / SDF cave meshing.** Genuinely cave-shaped, and it discards the authored-module decision `TEC-001` made on readability and art-cost grounds, makes collision and navmesh far dearer, and has to come out bit-exact for `TEC-004`.
- **Cellular-automata cave carving instead of rooms and corridors.** Produces caves and destroys the mission graph — the held arm, the bypass and the Prize's position all stop being controllable, which is every guarantee `MissionGraph` exists to make.
- **Hand-authored 3D prefabs per module.** The right answer later, and it costs 24 modules × 3 depth phases of modelling before one floor can be walked. The gradient gets most of it from one parameter.
- **Randomised wall jitter as "irregularity".** Noise, not morphology — the argument for three named sections is that random offsets read as a bug.
- **Full vertical topology.** ADR-014 settled it; reopening changes navmesh, AI traversal and the Clamor field at once.

### What this obliges

`FloorBuilder` implements `TEC-008`. Step 8's navmesh half follows and is a **build-time assertion**, never a runtime re-roll (ADR-172 Decision 3). Three things are ⟨tune⟩ and cannot be settled until a floor is walked: whether 2.0 m reads as tight or generous, whether floor 3 reads as natural or broken, and whether ledges break the Clamor field — the last belonging to `M4-T16`, checked there rather than assumed here.

---

## ADR-176 — A seam you cannot see, and a check that was reading one slab

**Date:** 2026-09-01 · **Status:** accepted · **Fixes ADR-175's builder** · **Sharpens `TEC-007` §1** · **`M4-T01` in progress**

**Context:** ADR-175 landed `FloorBuilder` and the geometry it raises. Wiring `DES-015` step 8's navmesh half then found a room the AI could not reach, and chasing it turned up two defects in the geometry and — worse — a defect in how every geometry check had been measuring.

### Decision 1 — floors overlap; they do not butt

A room's floor slab ended exactly where a corridor's began. Recast voxelizes at 0.15 m, and those shared edges do not land on voxel boundaries, so a butt joint between two coplanar slabs can rasterise into a hairline gap. The room's mesh is then cut off from the corridor serving it, and a route *enters the room and stops inside it* — 2.63 m short of the centre, against 0.30 m for every healthy room.

**It is intermittent by construction**, because whether it bites depends on where a particular room's edge falls against the voxel grid. One room on one floor was affected and eight others were not.

Floors now grow `FLOOR_LAP` past their own footprint and overlap their neighbours. The joint is removed rather than hoped about.

### Decision 2 — the corridor cell keeps its full width

Room walls were built *outside* the room's rect, which put them inside the corridor cell next door and took 0.6 m off its 2.0 m. Walls now stand inside the rect, at 0.3 m rather than 0.6 m — the rect becomes the room's outer bound, so every wall costs interior, and at 0.6 m the narrowest module (1 cell, 2.0 m) would be left 0.8 m across: narrower than the 0.9 m navmesh agent, so a room nothing could enter.

Routing also refuses to run a corridor flush along a room it does not open into.

**Neither of these was the bug**, and the code says so. Both were tried as fixes, measured, and kept because they are right on their own merits: a corridor should not be pinched by its neighbour's masonry, and one running the length of a room's wall is poor level design whatever the navmesh makes of it. Recording that they were not the cause matters more than recording that they were kept.

### Decision 3 — a crossing is a property of the path, and it needs a ramp

ADR-175 shipped bridge cells that lifted the corridor floor 2.6 m with no ramp: a 58° step, past the 45° the navmesh bakes and far past the 0.49 m the player can jump. Two rooms unreachable, on a commit whose sweep was green — because the row that would have caught it was asking the wrong question (Decision 4).

`FloorPlan` already computed each corridor's ordered path and which cells crossed over another, and discarded both; it keeps them now, and `FloorBuilder` cuts corridors **per route rather than per cell**. Routing refuses a crossing within `BRIDGE_CLEARANCE` of a doorway so thresholds stay flat.

The first ramp was still a staircase with 1.07 m risers, because each cell was laid as a flat box at its own height — the same defect one iteration smaller. A cell whose entry and exit heights differ is now a tilted slab, lengthened by 1/cos so it still covers its cell.

### Decision 4 — the rule `TEC-007` §1 was missing

Every one of these was found by planting, and each plant failed against a check that looked healthy:

- `map_get_closest_point` was asked "does this room have navmesh". It finds the nearest mesh **anywhere**, so a corridor a metre outside a sealed room answered for the room, and dropping every ceiling below agent height still reported full coverage. It asks for a *route* now.
- The doorway row counted `doors_of()` and compared it to the edge list — the plan against itself. Building every wall solid left it passing. It measures **through the wall** now.
- The headroom row called any thin slab above half a metre a ceiling. True until corridors ramped, at which point a raised floor answered as a 0.6 m ceiling.

And the one that generalises furthest. Slabs were named by role so probes could tell a ceiling from a floor. **Godot does not rename a colliding child to `floor2`; it discards the requested name and calls it `@MeshInstance3D@37`.** So every probe filtering by role was reading exactly *one slab per floor* and reporting it as the whole population. The join check announced "8 floor slabs across 8 floors" — for floors carrying about 1500 — and was green.

Once slabs carried unique names, that same check immediately found **54 genuinely isolated slabs** the miscount had hidden: ramps were not lapping their neighbours, and the probe was computing tilted slabs' bounds without their rotation.

So `TEC-007` §1 gains a second rule beside "never let a decision depend on the order a collection was built in":

> **Assert the size of the population you are measuring, not only the property.** A check that reports a count nobody compares against an expected magnitude is not a check. "8 slabs across 8 floors" was absurd on its face and shipped green.

### Decision 5 — the cheap check over a corpus beats the expensive one over a sample

Baking a navmesh per floor across a corpus was attempted three ways — freeing regions between iterations, a private navigation map per floor, floors baked side by side at world offsets — and each fought Godot's navigation lifecycle differently. It was abandoned.

The **joint** is what breaks, and it is checkable without baking anything: every floor slab must overlap another. That runs over eight floors in milliseconds, where one bake takes seconds and was the sample that nearly missed the bug. One floor still bakes as the integration check.

The general shape: when an expensive check can only afford a small sample, look for the *cause* it is a proxy for and assert that cheaply over a large one.

### Rejected

- **Shrinking the navmesh agent or the voxel to make the room reachable.** Both "fixed" it and neither addressed a seam; the geometry would still have been wrong for anything else that read it.
- **Keeping the multi-floor bake by working around the navigation lifecycle.** Three attempts, none clean, and the cheap check covers more floors.
- **Leaving `corridor_at()` and `is_bridge()` behind for a later caller.** ADR-098: delete it or call it.

---

## ADR-177 — The map is not the region, and the probe's own litter failed the row

**Date:** 2026-09-01 · **Status:** accepted · **Fixes ADR-176's navmesh row** · **Sharpens `TEC-007` §1** · **`M4-T01` in progress**

**Context:** ADR-176 landed the navmesh half of `DES-015` step 8 and the local sweep was read as green. CI went **red on the merge commit** — the first time that row had ever run on Linux — reporting all eight standing rooms off the mesh and no route from the entrance to the Shaft, on a floor that baked *the same 260 vertices* it bakes here. Two independent faults, both introduced by ADR-176, and the local sweep was hiding the second one.

### Decision 1 — wait for the map, not for the region

Godot 4.4 made navigation map synchronisation asynchronous by default (`navigation/world/map_use_async_iterations`, confirmed `true` on 4.7). The rebuild lands on a worker thread some frames after `bake_navigation_mesh()` returns, and **`map_force_update()` does not wait for it**. ADR-176 waited a fixed six physics frames, which is not a synchronisation primitive — it is a measurement of this desk. A two-core runner needs more, gets asked anyway, and `map_get_closest_point` answers honestly about a map that is not there yet.

The row now polls until every room that ought to be walkable can find the mesh, with a budget (`NAV_SYNC_FRAMES`) rather than a delay. It costs nothing in the normal case — two frames — and a genuinely stranded room spends the budget and is then reported by the rows below, which is the right trade on a floor that is already failing.

**`region_get_bounds()` is not the sentinel, and finding that out is what reproduced CI here.** The first attempt polled the region's own extent, on the reasoning that it is what the *server* holds rather than what the resource was baked with. It reports the full 77 × 81 m one frame after the bake — while the map it belongs to still answers nothing, for several frames more. That version turned this desk red in exactly CI's words, which is how the mechanism was confirmed rather than assumed. The region receiving its data and the map merging it are two events, and only the second one can be asked a question.

So `TEC-007` §1 gains a third rule:

> **Wait for the thing you are about to measure, not for something that arrives near it.** A sentinel one step upstream of the measurement is a race with better manners.

### Decision 2 — the two failures must not share a message

`on_mesh == 0` is reachable from a map that never rebuilt *and* from geometry the rooms are nowhere near, and blaming synchronisation for the second sends the next reader somewhere useless. The region bounds tell them apart — held mesh means the rooms are not on it — and the row says which. Both branches were planted by starving the budget to 1 and 2 frames, and produce distinct, correct sentences.

A third plant — the floor built 500 m from where the plan says it is — confirms the poll cannot *hide* a coverage failure: 1/9 rooms, budget spent, and the stranded row reports it. An earlier attempt at that plant displaced the region *before* baking and was a no-op, because the bake converts world geometry into region-local space and the transform cancels; recorded because a plant that quietly tests nothing is the failure mode this whole file exists to catch.

### Decision 3 — the probe must exit clean, because its litter is read as a failure

`check_scripts.sh` greps `^ERROR:`, so **anything the engine prints at exit fails the row regardless of what the row measured.** Two sources:

- Querying before the server's first synchronization is an *engine error*, not an empty answer: Godot prints "navigation map query failed because it was made before first map synchronization". The poll now checks `map_get_iteration_id(map) > 0` before asking.
- Section 5 built a floor into a bare `Node3D.new()` written inline as an argument. Never parented, so nothing ever freed it, and its 472 static bodies were still allocated at exit — seven `ERROR: ... leaked at exit` lines. **Nodes in the tree are released by teardown; an orphan is the one thing that has to free itself.**

**The local sweep was already failing on `main` before any of this session's work**, for the second reason, and had been reported as green. Verified by stashing and re-running. That is the ADR-104 lesson arriving a second time from the other direction: it is not enough to run the sweep, the result has to be *read*.

Two frees added here were removed again. They released the navmesh probe's floor at the end of the row, on the theory that it was the leak; it was not — everything parented is freed at teardown — and keeping code whose comment states a false cause is worse than the code being merely unnecessary.

### Rejected

- **A larger fixed frame wait.** The same bug with a bigger constant, and it would have gone red again on a slower runner without saying why.
- **Turning async iterations off for the probe's map.** Would likely work and hides the mechanism: the game runs with them on, so the probe should ask the same server the game asks.
- **Suppressing the leak lines in the grep.** The grep is right. A probe that cannot exit cleanly reports a failure it does not have, and the fix is to stop littering.

---

## ADR-178 — Ledges and alcoves, and the ramp that had never been walked on

**Date:** 2026-09-02 · **Status:** accepted · **Implements `TEC-008` §3.3** · **Corrects ADR-176's ramps** · **`M4-T01` in progress**

**Context:** `TEC-008` §2.2 diagnosed the generated floors against Lynch's five elements: they had **paths** and **nodes**, and no **edges**, **districts** or **landmarks** — which is the list of things a player builds a mental map out of. ADR-175 bought the districts with the roughness gradient. This buys the other two, and in doing so found that the ramp ADR-176 added had never been walked on by anything.

### Decision 1 — alcoves, and the test that keeps them from being doors

Rooms of three cells or more take one or two one-cell recesses cut into a wall (Alexander's *Alcoves*): cover that breaks a sightline, somewhere to let a patrol pass, and a wall line that stops a large room reading as a box. 54 across three floors.

The candidate test is doing more work than it looks like: **a cell may only become an alcove if every side of it but this room's is rock.** A recess touching a corridor or a second room would be a hole joining two spaces the graph never linked — ADR-172's hazard arriving dressed as decoration, and invisible to every topology check, because the plan does not know the recess exists.

### Decision 2 — ledges, and the metre that makes them reachable

A great room takes a walkable deck at 2.5 m along one door-free wall, reached by a ramp. It is the delivery mechanism for `DES-015`'s vista rule — *you see the Prize before you can reach it* — and Appleton's prospect and refuge in one piece of geometry: the deck is the view out, the wall behind it the cover. 20 across three floors.

**The ramp's foot touches down a clear metre from the wall at the end of the strip, and that number is the whole device.** Recast erodes the walkable surface by the agent radius, 0.45 m, back from every wall. A ramp whose foot meets the floor *at* the wall has its entire touch-down inside that band, so deck and ramp bake as an island with no way onto them. Measured, by sampling the ramp's own surface: mesh from 2.5 m down to 0.7 m and **none at all below it**, on three of four ledges.

Two earlier explanations were wrong and were measured wrong rather than argued away. The ramp's uphill lap putting a 0.48 m lip over the deck was real, fixed, and changed nothing. Recast eroding the deck's leading edge — which is real, and is why the deck must not overhang the ramp by any amount — also changed nothing on its own. Raising `agent_max_climb` to 0.9 m recovered one ledge of four, which said the junction was *a* cause and not *the* cause. Only sampling along the ramp found the foot.

A ledge must stay reachable: `DES-013`'s Hunt has to be able to follow you up, or a vantage is a safe room, and `DES-005`'s pressure is the product. That is asserted, and it is the opposite of the crawl rule — a crawl with no navmesh is correct.

### Decision 3 — the check was baking the one floor with no ramps on it

`--build-probe` baked floor 0 of seed 31337 for four commits. **That floor has no crossing on it.** Neither does floor 1. So the ramped bridge ADR-176 exists to build — the fix for a 2.6 m unramped cliff — had never once been asked whether anything could walk up it.

It could not. `Vector3.UP.cross(along)` is what reads naturally for the tilt axis and it slopes the plate the *other way*: measured, a 4.0 m run raised 2.5 m put the far end 1.06 m **below** the near one. Every ramp in `FloorBuilder` sloped downhill. The ledge was simply the first tilted slab the navmesh row ever saw.

So the sign lives in one named function, `rise_toward`, and the probe now bakes a floor **chosen for having crossings** — seed 31342 at depth 0, four crossings and two great rooms for the price of the same nine rooms — and asserts that it has them, because a corpus change could quietly take them away again. Planted by restoring the inverted axis: six of nine rooms become islands and there is no route to the Shaft, where the same defect on the old floor ran green.

### Decision 4 — the doorway row asks the collider

It built an axis-aligned box per slab from its position and skipped anything yawed. A ledge ramp is *pitched*, its yaw is zero, and the box of a tilted plate is not its shape — so it reported a doorway walled shut by a ramp that is at floor level where the doorway is. ADR-176 fixed exactly this in the join check and left it here.

It asks `intersect_point` of the physics space now, which is both exact under rotation and *the thing the player will walk into*. The floor it builds stands 5 km clear of everything else, because a point query cannot say which of four overlapping floors answered it.

### Rejected

- **Corridor dog-legs**, the fourth device (Kaplan & Kaplan's mystery). A routing decision rather than a geometric one; it belongs to `FloorPlan` and to its own change, next.
- **A ramp per crossing corridor into the ledge**, as `TEC-008` §3.3.1 describes it. It makes a ledge conditional on a bridge happening to arrive at deck height beside a great room, which is rare; an in-room ramp is unconditional. `TEC-008` §3.3.1 is amended to say so.
- **Shrinking the agent or the voxel** to make the foot fit against the wall. The third time this has been the wrong answer in `M4-T01` (ADR-176): it moves a threshold rather than fixing geometry, and the geometry would still have been wrong for everything else that reads it.

---

## ADR-179 — Corridors that bend, and the sightline nobody had measured

**Date:** 2026-09-02 · **Status:** accepted · **Completes `TEC-008` §3.3** · **`M4-T01` in progress**

**Context:** the fourth and last of `TEC-008` §3.3's devices, for Kaplan & Kaplan's **mystery** — a passage bending out of sight promises more if you move deeper. `TEC-008` asked for it in one sentence and assumed a modest problem: *"a corridor of three cells or more bends at least once rather than running straight."*

### Decision 1 — measure the sightline before building anything for it

The problem is much worse than the document assumed, and worth stating as numbers because everything else follows from them. Across **4780 routes** on 360 floors:

| | Before |
|---|---|
| Routes running **dead straight end to end** | **65%** |
| Bends per route | 0.71 |
| Median longest straight run | **9 cells — 18 m** |
| Routes with a straight run of 8 m or more | 96% |
| Longest run in the corpus | 75 cells — **150 m** |

An 18 m straight tunnel 2 m wide, between two rectangles, is the entire proposition visible from the doorway — and it was the *median*. This was measured first precisely because the alternative was building a device for a problem the floors might not have had; `CLAUDE.md` prefers subtraction, and the way to find out is to look.

### Decision 2 — a jog, not a re-route

The router is a breadth-first search, so it finds shortest paths — and **between two rooms whose doors line up, the straight line is the only shortest path.** No amount of tie-breaking inside the search can bend it: preferring perpendicular expansion changes which of several equal-length paths wins, and here there is only one. Bending has to be paid for.

Two ways to pay, and the choice matters:

- **Constrain the search** to refuse straight runs past a limit. Cheapest in cells, and it can fail to route at all — which is exactly how `MAX_ROUTE` failed in ADR-172, where a search budget too small failed like a constraint violation and was misdiagnosed twice as geometry.
- **Jog the found path.** The corridor steps aside one cell, runs parallel, and steps back, keeping both doorways exactly where the search put them. Costs two cells per bend. **When there is no room to step aside it does nothing**, so it cannot turn a routable floor into an unroutable one.

The second. A device that can strand a floor is not worth a sightline, and the corpus confirms it: 4780 routes before, 4780 after, 0 invalid floors of 360.

| | Before | After |
|---|---|---|
| Dead straight end to end | 65% | **13%** |
| Bends per route | 0.71 | **5.72** |
| Median longest straight run | 9 cells (18 m) | **5 cells (10 m)** |

It costs **+19% to +28% corridor cells** on the three probed floors. That is a real cost and it lands on a floor that is already corridor-heavy — see the open question below.

Routes that cross another corridor are left alone: a chicane shifts every later cell's index, and `_climbable` measured the crossing's ramp clearance against the old ones.

### Decision 3 — the row measures the distribution, not the mechanism

`--plan-probe` reports the share of dead-straight routes, bends per route, and the median longest run, and fails on the first two exceeding bounds. Planted by disabling the jog: it reproduces 65%, 0.7 bends and 9 cells exactly, and both assertions fire.

Asserting *"`_dogleg` was called"* would have been the cheaper row and the wrong one — it is a claim about the code rather than about the floor, and `TEC-007` §1 is a list of what that costs.

### Open question — the floors are corridor-heavy, and this made it worse

The route-length histogram has a median around 9–10 cells (18–20 m) **before** the jog, with a tail past 100 cells. Adding ~24% corridor is defensible for the sightline, but the underlying density is a separate question with its own lever — `LATTICE`, currently 12 — and it is a design decision about how much of a floor should be connective tissue rather than room. Not reopened here. Filed to `OPEN-QUESTIONS.md`.

### Rejected

- **Constraining the search** (Decision 2), on the ADR-172 precedent.
- **A single bend per corridor**, as `TEC-008` §3.3.2 literally says. One bend in a 20-cell corridor still leaves two 10-cell sightlines; the limit has to be on the *run*, not on the count. `TEC-008` is amended to say so.
- **Reducing `LATTICE` instead**, to shorten corridors rather than bend them. It would help, and it changes room density, adjacency and the bypass distances all at once — a floor-composition decision, not a sightline fix.

---

## ADR-180 — Half the floor was corridor, and three things were hiding behind that

**Date:** 2026-09-02 · **Status:** accepted · **Retunes `TEC-008`, corrects ADR-176 and ADR-178** · **`M4-T01` in progress**

**Context:** ADR-179 left an open question — *how much of a floor should be corridor?* — because adding the dog-leg made an already corridor-heavy floor about a quarter heavier. Answering it meant sweeping `LATTICE`, and tightening it exposed three separate faults that had been invisible while corridors were long. **Every one of them was a safe room or an impassable step that no check could see.**

### Decision 1 — `LATTICE` is 8

Swept over 180 floors per value, with the dog-leg live:

| `LATTICE` | valid | corridor share of walkable floor | median corridor | re-rolls |
|---|---|---|---|---|
| 6 | **7/180** | 33% | 4 m | 78 |
| 7 | 180/180 | 35% | 8 m | 104 |
| **8** | 180/180 | **41%** | **10 m** | **57** |
| 9 | 180/180 | 46% | 16 m | 57 |
| 10 | 180/180 | 50% | 18 m | 80 |
| 11 | 180/180 | 54% | 20 m | 83 |
| 12 (was) | 180/180 | **56%** | 24 m | 87 |

At 12, **more than half of every walkable floor was connective tissue**. Eight is chosen over seven for margin rather than for its numbers: seven plans every floor too, and its re-roll count nearly doubles, which is a placer straining next to a cliff — six collapses to 7 valid floors in 180. Eight has the lowest re-roll count of any value swept and generates twice as fast as twelve.

### Decision 2 — the sightline row is bounded on the tail

Both obvious statistics are useless, and that is worth recording because both look right:

- *"runs dead straight end to end"*, the bound ADR-179 shipped, is a function of corridor **length**. Corridors got shorter, the share went 13% → 61%, and **a 4-cell dead-straight corridor is 8 m and entirely fine**. The row would have failed a floor that had just improved.
- the **median** longest run has no power at this lattice at all: 5 cells with the dog-leg and 5 without.

The tail separates them. The device permits `DOGLEG_RUN + 1` cells, and past that is a corridor the chicane had no room to bend: **8% over the limit with the dog-leg, 34% without**, p95 of 9 cells against 16. Bounded on those two, planted, both fire.

### Decision 3 — a corridor with no bridge was lifting its own doorways

`FloorBuilder` seeds "how far is the nearest crossing" with `path.size()`, meaning *far enough not to matter*. That is true only while every corridor is longer than a ramp. **A two-cell corridor with no bridge anywhere measured its nearest crossing as 2** and lifted both its doorways a third of the way to bridge height: a 1.10 m step against a 0.49 m jump, at the threshold.

It was not new. The corpus held **61 two-cell routes at the old lattice** and every one of them was like this. It survived because the doorway row bakes one floor, and that floor happened to have no two-cell corridor on it. Seeded with the ramp's own reach now.

### Decision 4 — a crawl may never be the only way in

A crawl is 1.4 m and the agent stands 1.8 m, so the Hunt cannot follow you through one — `DES-009`'s crouch verb given teeth, and the navmesh row asserts the *absence* of mesh there. But a standing room whose every approach is a crawl is a room nothing can ever reach: a safe room built out of topology, with no geometry wrong anywhere. **482 of them across 360 floors.**

Two weaker rules were tried and measured, and both are the kind that would have shipped:

- *"is this node a cut vertex?"* left **6** of the 482. Two crawls on two different approaches strand a room between them while neither is a cut vertex alone.
- *"admit a maximal set up front, then let the seater pick any subset"* left **1**. It assumes removing fewer nodes cannot strand more, which is false: in `entrance—A—B`, removing both strands nothing and removing only A strands B.

Testing each crawl against the crawls already placed gives the invariant directly. **0 across 360 floors**, with 171 crawls still placed — and the rule leaves the crawl meaning what `DES-009` wants, because a node on a cycle always passes, so crawls seat themselves on the ways *round*: a shortcut you can take and the Hunt cannot, rather than a door it cannot open.

### Decision 5 — 40° does not bake, whatever the setting says

`agent_max_slope` is 45°. Two ramps at ~39.5° do not produce walkable navmesh:

- **The ledge ramp**, when `LEDGE_RAMP_CELLS` was cut to 2 to buy back a cell of deck. Five of seven ledges went unreachable and five rooms with them — a ramp Recast rejects is not a ramp, it is a slab across a third of the room.
- **Every corridor bridge, since ADR-176.** `BRIDGE_LIFT` of 3.3 m over `RAMP_CELLS` of 2 is 4.0 m of run: 39.5°. Sampling routability cell by cell showed the mesh breaking and resuming at each of a route's four crossings. It was invisible for the same reason the sign error in ADR-178 was — **a crossing sits on a cycle by construction, so the route simply goes the other way round**, and no room is stranded until the lattice tightens and the alternatives get shorter.

`BRIDGE_CLEARANCE` is 4, giving 6.0 m of run and 28.8°, and ledges keep their 3-cell ramp at 26.6°. The two working ramps in this generator are both under 30°; the two broken ones were both near 40°. **The limit that matters is the one measured, not the one documented.**

### Cost, and what it bought

Ledges fall from about 20 per three floors to 7, because a ledge now needs a five-cell wall to leave two cells of deck. Crossings are rarer, and re-rolls rise from 127 to 234 across 360 floors — still no invalid floor. Against that: corridor share 56% → 41%, median corridor 24 m → 10 m, generation twice as fast, and **every bridge, every ledge and every doorway on a generated floor is now walkable**, which none of them reliably were.

### Rejected

- **`LATTICE` 7**, for margin (Decision 1).
- **Keeping the 2-cell ledge ramp and accepting one-cell decks.** A 2.0 × 2.0 m deck erodes to about 1.1 × 0.8 m of walkable surface; Recast keeps it and nothing can reach it.
- **Widening `agent_max_slope` past 45°** so the 39.5° ramps bake. It is not the slope setting that is wrong, it is the ramp; and a steeper limit would have hidden Decision 5 rather than fixed it.

---

## ADR-181 — `FloorAnchors`: the mission decides where things stand

**Date:** 2026-09-02 · **Status:** accepted · **`M4-T01` in progress** · **First half of making a generated floor playable**

**Context:** the generator produces a floor you could walk if anything put you on it. Nothing does. `room_set.gd` knows where the party arrives, where the Shaft is, where the Gullsjúkr posts, and which corner the coin is in — as **twelve hand-placed constants**, checked by hand against one authored level. A generated floor has as many such positions as it has rooms, and a different set every seed.

### Decision 1 — positions are derived from the mission, and contents are not

`FloorAnchors` answers *where*, from the graph's roles and the plan's rectangles: arrival points, the Shaft, the Prize, where the Hunt begins, standing posts, door lights, landmarks, the Clamor field's bounds, and one loot spot per room tagged `prize` / `held` / `bypass`.

**It never answers *what*.** Which Prize, which enemy archetype, which item — those are `DES-008`, `DES-013` and `M4-T17`, and none of them exists yet. Splitting on that line is what lets the item taxonomy arrive later without touching this file, and it is why the loot spots carry a tag naming what the room is *for* rather than an item id.

### Decision 2 — loot placement is ADR-032 generalised

ADR-032's finding on the authored floor was that a cycle only means something if its two arms pay differently: the long safe branch carries bog iron and a working knife, the short held branch carries coin and gold, and the guarded room carries the three things worth the fight. **Held-versus-unheld is a property of the graph**, so that rule generalises to any floor with no hand-placed coordinate at all. Measured across 360 floors: every floor has a bypass payoff.

### Decision 3 — the Hunt starts far in hops, not in metres, and never in a crawl

`DES-017` wants the first meeting on the walk *out* with a full bag, so the Hunter begins as deep as the floor allows. On a graph that means **hops**: a room two corridors away across a cycle is nearer than its distance suggests. And never in a crawl — a crawl carries no navmesh by design, so a Hunter posted in one cannot move, and the deepest room on a floor is exactly where a crawl gets seated.

### Decision 4 — the party arrives in a grid, and the line that preceded it would have failed 103 floors

Four players spread along one axis need 4.8 m of clear interior. The smallest entrance module is three cells: 6.0 m of room, **4.2 m once the walls and a body's radius come off**. Of 360 floors, **103 could not have seated a four-stack**, and the failure mode is bodies spawned inside each other, shoved apart host-side, which reads on a client as two peers disagreeing about where somebody is. A 2×2 needs 1.6 m on each axis and every entrance has it.

**The row that found it was itself wrong first.** It asked whether the *room* was big enough — a proxy, and one that encodes the layout it is meant to be checking. It measures the points that come out instead: no two of a four-stack closer than a body's width. 103 → 0.

### Decision 5 — one row was removed because the design never promised it

The first draft asserted that every floor has a held room. **145 of 360 do not**, and they are not faults: only two of the five cycle types hold a span at all (`DANGER_DETOUR` and `LOCK_AND_KEY`, ADR-171), so a foldback or shortcut floor having nothing held is the catalogue working. The assertion was inventing a promise and would have failed 40% of a healthy corpus.

It is **printed rather than asserted**, because it is the number that decides a real question: whether standing posts can be derived from held rooms alone, or whether 40% of floors would have no standing danger on them at all. That belongs to `M4-T02` and `DES-013`, not here.

### What is asserted

- **Every placement stands on the navmesh** — asked of the mesh, not of the geometry, because "inside a room" is not the claim and "somewhere a body can stand and walk away from" is. 18 placements on the baked floor, worst 0.24 m off. Planted by pushing the inset negative: 5 adrift.
- **A light per doorway, a landmark per great room, every room inside the Clamor field** — each checked against the thing it is derived from, not against itself. Planted separately; both fire.
- **No two of a four-stack spawn inside each other**, over 360 floors.
- **Every floor has a bypass payoff** (ADR-032).

### Rejected

- **Asserting that posts land only in held rooms.** True by construction — the function skips everything else — so it is a claim about the code, and `TEC-007` §1 is a list of what those cost.
- **Deriving posts from something richer than held-ness** to cover the 145 floors. That is enemy placement design; inventing it here would put a rule with no document behind it into the generator.

---

## ADR-182 — A seam, not an extraction: `FloorSource`

**Date:** 2026-09-02 · **Status:** accepted · **Changes the route approved for `M4-T01` phase 2b** · **`M4-T01` in progress**

**Context:** the approved plan for making a generated floor playable was: *extract the floor-agnostic machinery out of `room_set.gd` into a `RunFloor` component both levels compose, then build the Delvings on it.* Reading the machinery closely before moving it says the extraction is unnecessary, and this ADR records the change of route rather than making it quietly.

### Decision — parameterise the reads instead of moving the functions

`room_set.gd` is 7436 lines and is two things: **the machinery a run needs** — a session, a party, a Hunt, an extraction, a wipe, thirty probes — and **one hand-authored floor**, as a dozen constants that machinery reads inline.

The run lifecycle was to be the extraction's subject. It does not mention the floor. `_end_the_run`, `_take_the_outcome`, `_watch_for_a_wipe`, `_the_party_is_gone`, `_on_peer_left`, `_settle_if_nobody_is_left` and `_deeds_for` talk to `_session`, `GameState` and `RunFile` and nothing else — **they are already floor-agnostic.** Moving them would relocate code that is not coupled to the thing it would be decoupled from, and it would cost:

- an `@rpc` whose **node path is part of its contract** (`_take_the_outcome` is addressed by `rpc_id`), moved to a different node,
- ~30 probes that call into the cluster, re-pointed,
- a week, against a plan estimate that already flagged this phase as the one likely to overrun.

What *is* floor-specific is **six functions reading a dozen constants**: `_spawn_actors` (spawns), `_spawn_enemies` (posts, guardian), `_spawn_loot` (fixtures, filler), `_build_hunt` (field bounds, hunter post), `_build_shaft` (shaft), `_build_lighting` (door lights). `FloorSource` is the one object those six read instead, with `AuthoredFloor` returning the Deep's constants unchanged.

**The same result by arithmetic rather than by surgery**, and the reason it works is that the extraction's premise was wrong: the machinery did not need separating, it needed *asking somewhere else*.

### Why this is not a stub or a parallel path (ADR-064)

`AuthoredFloor` is not a second, worse implementation kept beside a real one. It is the Deep — the floor thirty probes exist to measure, and which stays exactly as it was. `DelvingsFloor` will be the other implementation of one contract, chosen once at the descent. That is ADR-064's **gate decision**, not its banned fallback.

The base is `@abstract` (Godot 4.5+, confirmed on 4.7), so a source that forgets a method fails at parse time rather than returning a plausible empty list — which is exactly the shape of stub this project keeps finding.

### What it does not cover yet

**Geometry.** `AuthoredFloor` answers *where things stand*; the Deep's walls are still built by `_build_room` and its landmarks by `_build_landmark`, from `ROOMS` and `DOORS` directly. Raising the geometry is the other half of the seam and the next commit, because it is the half that needs `FloorBuilder` wired in and a scene to put it in.

Naming this rather than half-doing it: a `build()` on the contract that only one implementation honoured would be the stub the paragraph above rejects.

### Evidence

The sweep is the assertion. Every probe passes unchanged, including `--sight-probe`, which reports the lighting the seam now routes: **12 of 12 doorway lights, 6 of 6 rooms seeing the way out** — identical to before, and computed through `FloorSource.door_lights()` rather than from `ROOMS` and `DOORS` inline.

### Rejected

- **The `RunFloor` extraction**, as above — and it is worth being precise that it was rejected on evidence rather than on cost. Had the run lifecycle actually read the floor, the cost would have been worth paying.
- **`Delvings extends RoomSet`.** Cheaper still, and it makes a 7400-line class a base class, which is the shape `CLAUDE.md` names in as many words when it asks for composition over a 900-line `Actor`.

---

## ADR-183 — The Delvings is a level

**Date:** 2026-09-02 · **Status:** accepted · **Completes ADR-182's seam** · **`M4-T01`: a generated floor can be descended into**

**Context:** ADR-182 put a `FloorSource` between `RoomSet` and the dozen constants it read, with `AuthoredFloor` answering for the Deep. This adds the other half — the geometry, the generated implementation, and the flag that descends into it — so a generated floor is something a player stands in rather than something a probe measures.

### Decision 1 — geometry moves, because a floor has to be able to raise itself

`_slab`, `_wall`, `_gaps`, `_build_room`, `_build_landmark`, `_pillar`, `_beam` and `_ring` are now `AuthoredFloor`'s. They were called from `_ready` and from each other and **from no probe at all**, so the move is a cut, a paste and two call sites. `FloorSource.build(into)` is the contract; `_ready` calls it and lights whatever comes back.

`--sight-probe` is the evidence: **12 of 12 doorway lights, 6 of 6 rooms with a landmark, 6 of 6 rooms seeing the way out** — the same numbers as before the move, now produced by a class that does not know it is a level.

### Decision 2 — loot is placed by rule and named by value

The approved decision was *derive placement rules from the plan*. `FloorAnchors` tags every spot `prize`, `held` or `bypass` from the graph (ADR-181); `DelvingsFloor` fills them by sorting the item corpus on **`tribute_value`, which every item already carries**. The dearest thing goes on the Prize, the dearer half is dealt into held rooms, the cheaper half into the bypass.

So ADR-032's finding — *the long safe branch pays badly, the short guarded one pays well* — holds on any floor, with no hand-placed coordinate and **no invented taxonomy**. `M4-T17` will give the items a real one and `DES-008` its loot tables; this is the one function that changes when they arrive.

### Decision 3 — depth comes from a flag, and that is scoping rather than a shortcut

The obvious source for the floor index is `GameState.descents`. It is wrong: `descents` counts every descent a lineage has ever made, and the index this wants is *how deep into this expedition* you are, 0 to 2. **A run that goes down three floors does not exist** — nothing carries a party from one to the next, and `RunFile` deliberately holds no floor.

Reading `descents` would have looked right and quietly rolled floor 47 on somebody's forty-eighth run. `--floor=N` is honest about being for walking the three depths until the run that owns the number is built.

### Decision 4 — the navigation map was rasterising at a size nothing baked

Found by booting a generated floor and reading what scrolled past. Every navigation mesh in the project bakes at **0.15** — the level's and the one `--build-probe` measures ramps and ledges with — and Godot's default navigation map is **0.25**. The engine says so in as many words: *"this mismatch in cell size can cause rasterization errors with navigation mesh edges"*.

It survived because it is a `WARNING` and the sweep greps for `^ERROR:`. Every navmesh number in ADR-178 through ADR-181 was measured against a map that disagreed with its own mesh. The findings stand — the mesh is what Recast bakes — but the game and its probes were not asking the same server the same question. `navigation/3d/default_cell_size` and `default_cell_height` are 0.15 now.

### Decision 5 — the row that makes "playable" an assertion

`--build-probe` proves the floor is right and the navmesh covers it. `--delvings-probe` proves the **level arrives**: the same `_ready` that raises the Deep, handed a `DelvingsFloor`, produces a way out, a Hunt, something to pick up, a light in every doorway, and a body standing on the floor rather than inside it.

None of that is visible to a check that reads the plan — a floor can be perfectly generated, perfectly walkable, and arrive with no exit and nothing on it. Run at two depths, because the roughness gradient makes floor 0 and floor 2 different geometry.

Measured on floor 1 of seed 31346: **764 nodes of geometry, 30 door lights, a Shaft, a Hunter, 5 items, 5 enemies, one body, none off the floor.** Planted twice — no door lights, and an empty item pool — and both rows fire.

### What is still absent

- **The descent still goes to the Deep.** `Threshold._descend` loads `room_set.tscn` without `--delvings`, so the Delvings is reachable by flag and not yet by playing. Switching it is one line and belongs with the multi-floor run that gives the floor index meaning, not before it.
- **Enemies are one archetype and items are fourteen.** `M4-T02`, `M4-T16` and `M4-T17` own that, and nothing here pretends otherwise.

### Rejected

- **Reading the floor index from `GameState.descents`** (Decision 3).
- **Setting the meshes to 0.25 rather than the map to 0.15.** The finer grid is what the ledge and bridge work was measured on; coarsening it would invalidate those findings to silence a warning.

---

## ADR-184 — A run knows which floor it is on, and which expedition it is

**Date:** 2026-09-02 · **Status:** accepted · **Supersedes ADR-183 Decision 3** · **`M4-T01`: the first half of the multi-floor run**

**Context:** ADR-183 left the floor index coming from `--floor=N` and said why: `GameState.descents` counts a *lineage's* descents, `RunFile` held no floor, and a run that goes down three floors did not exist. This builds the thing that was missing. It does **not** yet carry a party down — that is the next decision, and the one-line switch that points the Threshold at the Delvings must land after both.

### Decision 1 — the floor index lives in the run file, because that is what a run file is

`RunFile` is *"where you are inside one run"*, kept separate from the profile so `TEC-003`'s death operation stays a one-liner. Depth into an expedition is exactly that kind of state, and `TEC-003` has listed **floor transition** as an autosave point since before there were floors to transition between. `RunFile`'s own note named this task as the owner: *"a ledger is `M4-T01`'s to keep, when a seed makes 'this floor' mean something across processes."*

So `floor` (0…`LAST_FLOOR`) and `seed` join the run file, `VERSION` goes to 2, and `descend()` is the one place the index moves.

The alternatives were worse in specific ways rather than merely less tidy. `GameState` is profile-tier — LIFE and LINEAGE — and putting run position there is the coupling the two-file split exists to prevent. A new autoload spends from a budget of six (`CLAUDE.md` §4) on a single integer that already has a home.

### Decision 2 — the seed goes with it, and that is the half that is easy to miss

An index alone resumes you onto *a* floor 2, not *the* floor 2. `stripped` — the flag that says **you have already been through here** — would then be asserted about a floor nobody had ever walked, and a resumed run would arrive on unfamiliar ground stripped bare. That is the same farming exploit ADR-132 closed, wearing the opposite face: the fix eating the feature instead of the feature eating the fix.

`descend()` therefore carries the seed forward untouched and clears `stripped`, because a new floor has not been looted. Both are asserted, and the `stripped` row is the one that would otherwise have made every floor after the first lay no loot at all.

### Decision 3 — the host rolls the seed, and the descent RPC already crosses the wire

**Every peer builds its own floor geometry.** `room_set._ready` calls `_floor.build()` with no `is_server` gate, on the same reasoning as `_build_shaft`: a floor both sides can derive is not worth a spawn packet. That makes the *number they derive it from* a value the party must agree on — and a seed rolled per process would put four players in four different Delvings, each solid on one machine and thin air on the other three.

It would also have looked perfect solo, and the co-op smoke has never launched with `--delvings`, so nothing in the sweep would have said a word.

No new wire was needed. `Threshold._descend` is already `@rpc("authority", "call_local", "reliable")`: the host is its only caller, so it rolls `randi()` once and every peer runs the same call with the same integer. The seed is printed at the descent, which `TEC-001` requires — a run seed has to be readable off a bug report.

### Decision 4 — the flags stay, as the unarmed process's door

`--floor=N` and `--seed=N` still work, and this is **not** the parallel fallback ADR-064 bans. A probe booting a level directly is not on an expedition; `RunFile` shows an unarmed process no run at all, deliberately (ADR-138). So there is no second *game* path to drift out of step — the open run is the only source when there is one, and the flags are how a measurement asks for a floor to look at. Same shape as `--as-rank=N` against `_declared_rank` (ADR-119), and documented at the read site as such.

`LAST_FLOOR` is a constant on `RunFile` because `room_set` had the same `0, 2` written inline: two places saying how long an expedition is, one of which would eventually have been found by a player rather than by a check.

### The rows, and what they caught

Five new assertions on `--run-probe`, **every one planted and every one caught**:

| Planted | Fires |
|---|---|
| a run opens at floor 1 | *"an expedition starts at the top"* |
| the seed is not recorded | *"a resume would rebuild a different floor under the same index"* |
| `descend()` does not increment | *"depth would be a lie"* |
| `descend()` keeps `stripped` | *"every floor after the first would lay no loot"* |
| the index is not clamped | *"the Deep Gate is the way out of the third, not a fourth"* |

### What is still absent (ADR-064, deliberately)

- **Nothing carries a party down yet.** The bag, the Hunt's age and the bodies do not cross a floor. `descend()` exists and the game does not call it.
- **The Threshold still opens onto the Deep.** One line, and it stays uncut until the party can actually survive the trip.

### Found on the way, and not fixed here

`RunFile`'s `carried` and `hunt_age` are **written once at `begin()` and never read or updated by anything**. They are dead fields inside a live file — ADR-098's question at field granularity, which `check_dead.py` cannot see because it checks names. The visible consequence today is that a resumed run gives you back your class and your rank but an **empty bag**. They are what the next decision uses to carry a party between floors; noted here so the fix is not mistaken for new construction.

### Rejected

- **A floor index on `GameState`** — profile-tier state, and the coupling `TEC-003`'s two-file split exists to prevent.
- **A new `Expedition` autoload** — one integer, against a budget of six.
- **Each process rolling its own seed** (Decision 3), which is correct solo and silently catastrophic in co-op.
- **Migrating v1 run files.** `read()` drops what it cannot read, by standing policy: keeping a bad run file blocks every future descent and dropping one costs a single run. `SaveFile` takes the opposite decision because a lineage is not replaceable.

---

## ADR-185 — A party crosses a floor, carrying what it earned and what it cost

**Date:** 2026-09-02 · **Status:** accepted · **Builds on ADR-184** · **`M4-T01`: the run that goes down three floors**

**Context:** ADR-184 gave a run a floor index and a seed. Nothing moved it. This is what a party takes with it when it does — and the answer had to be *everything*, because each thing left behind is a way the descent stops being a commitment.

### Decision 1 — the bag, the wound and the Hunt all cross, and the wound is the one with a doc behind it

| Crosses | Why it must |
|---|---|
| **The bag** | Obvious, and it was the easy one to get wrong: repacking by id would drop whatever no longer fits |
| **The wound** | `DES-009` bans regeneration **within** a run; ADR-015 makes a run three floors |
| **The Hunt's age** | ADR-037 closed Q9 with *"descending grants nothing — a staircase cannot shake it"* |

The health row is not a nicety. `Health`'s own header calls non-regenerating hit points *"the most important single decision in this document after the thesis"* and says adding regeneration needs an ADR. A floor transition that handed back a full pool **is** regeneration, with a staircase standing in front of it — and it would have made quitting to the menu a bandage, which is the ADR-050 escape wearing its third face.

### Decision 2 — the host is told, because the host owns the body

The obvious build is for each peer to restore its own bag on arrival. It is wrong, and quietly: **the host owns every body's inventory** and pushes it to the owning client (`Player._push_bag`), so a client filling its own bag would be overwritten a frame later. Health is the same — `Health:current` replicates host→peers.

So a peer writes its own run file on the way down and **declares** what it is carrying on the way in. `CoopSession.declare_descent` is already that channel: it has carried rank since ADR-119, class since ADR-121, and worn slots since `M3-T07`, on the standing argument that these are run state rather than progression — discarded with the floor, never written to anybody's profile. A bag is the same kind of value.

It is **not** on the spawn packet, unlike the class and the slots. A spawn packet reaches every peer, and putting bags on it would broadcast four inventories to four players to save a dictionary.

### Decision 3 — the wire form was never a save form, and nothing had found out

`ItemInstance.to_wire()` has been documented as *"the wire **and save** form"* since `M3-T07`. Only the first half was true.

Measured rather than assumed: `JSON.stringify` turns `Vector2i(3, 2)` into the **string** `"(3, 2)"`, and `from_wire`'s `row["cell"] as Vector2i` on a string is an invalid cast — which **throws** rather than yielding null. Exactly the Godot behaviour that cost ADR-132 a run file, in a second place, found before it cost anything. JSON also returns every number as a float, so `instance` and the cell pair need `int()`.

Nothing had ever written an item to disk — `GameState` deliberately stores ids only, with a note saying a placed item's cell and rotation *"come with it, and that is `M3-T09`"* — so the fault was unreachable until a bag crossed a floor. `cell` is a two-element array now, which survives JSON and RPC alike, so there is still **one** form rather than a save form beside a wire form (ADR-064).

### Decision 4 — the probe drives both sides of a transition it cannot survive

A floor change is a scene change, and a probe cannot outlive its own. `--descent-probe` asserts the **record** directly (`_take_the_party_down` returns before the change under `_probing`, as ADR-138 requires) and drives the **restore** by calling `declare_descent` with what was recorded — which is the call `CoopSession._ready` makes on arrival. Both sides run the real functions; only the scene change is stood in for.

**Seven plants, all caught**: the Shaft not descending, the bag not packed, the wound not recorded, the Hunt not carried, `_hand_down` not unpacking, `_hand_down` not applying health, and the bottom floor never extracting.

**And one row was wrong before it was right.** It asserted the floor index was still 1 after the bottom-floor extraction, and failed a healthy build: extraction is an outcome, an outcome calls `RunFile.clear()`, and a cleared run reads back as floor 0 — so the row was measuring the *absence of a file* and calling it a descent. It asks whether the run **resolved** now, which is both correct and the better claim: it is what ADR-186 most plausibly breaks.

### Found and fixed on the way

`RunFile`'s `carried` and `hunt_age` were written once at `begin()` and **never read or updated** — dead fields inside a live file, invisible to `check_dead.py` because it checks names. The visible consequence: a resumed run gave back your class and rank but an **empty bag**, and a full health pool. Both are now live.

### Rejected

- **Each peer restoring its own body** (Decision 2) — correct-looking, overwritten a frame later.
- **Bags on the spawn packet** — broadcasts every inventory to every player.
- **Ids-only serialisation, repacked with `add()`** — packing order is not stable, so a full bag can fail to fit itself and silently drop items on descent.
- **A separate `to_save()` beside `to_wire()`** — two serialisers for one object, which is the parallel path ADR-064 bans. One JSON-safe form serves both.

---

## ADR-186 — The Shaft is the way down; the Waystone is the way out

**Date:** 2026-09-02 · **Status:** accepted · **Revises `DES-005`, `DES-015`, `DES-014`, `DES-019`; resolves ADR-091's contradiction** · **`M4-T01`**

**Context:** `DES-005` gave a run **three** ways out and two of them did the same job. Raised as *"the Waystone looks redundant"*, and it was — but the redundancy resolves the opposite way from the obvious one.

### Decision 1 — the Shaft descends, and only the bottom floor lets you leave

`MissionGraph.Role.SHAFT` has read *"The way down, **and out**"* since the graph was written, and only the second half was ever built. Now the first half is: claiming a Shaft on floor 1 or 2 takes the party **deeper**. On floor 3 it is the Deep Gate's mechanism, which is `DES-005`'s guaranteed exit and the only one that is always there.

**The party goes together**, on `Threshold._take_the_party_down`'s precedent and for a harder reason than symmetry: peers cannot stand in different levels (ADR-102). Extraction is a *state* precisely because of that; a floor change cannot be one.

### Decision 2 — the Waystone stays, and that is the whole argument

The cheap subtraction is to cut the Waystone: it is a rare found item with a ⟨tune⟩ drop rate that `DES-005` itself calls *"the strongest single lever in the game"*, and deleting it deletes the project's scariest untuned number.

It is the wrong half to cut. The Waystone's real job is not *an exit* — it is **an exit you can give away.** `DES-014` calls that *"the single best payoff available in this design"*: the person you saved saves you, because you gave away your own way out six hours ago. `DES-016` already has a deed for a Waystone you never spent. You cannot hand a teammate a Shaft.

So the Shaft gives up the exit role, and the Waystone stops being redundant by becoming **the only early exit**. `DES-019`'s binary readout — *do I still have my way out?* — stops meaning *my cheap way out* and starts meaning *a way out at all*.

### Decision 3 — what was considered and refused: no early exit at all

The proposal on the table was stronger: cut the Waystone, make the Shaft a late-join entrance only, and let the bottom floor be the sole exit. It is a coherent game and it is **a different genre**. The research says so plainly:

- The genre is defined by loot runs with *mandatory exfiltration*; the retention decision **is** the product.
- **Dwarf Delve** (2026), the nearest shipped competitor, is built entirely on the beat this deletes — *"a little voice whispering 'one more chest, one more room'; that voice is what kills you."*
- **Dark and Darker** ships the two-verb idea as red portals (deeper) and blue portals (out), deliberately spawning close together. It kept both verbs.
- **Tarkov's Scav runs** are the late-entry precedent, and a Scav still has to extract: the late arrival gets a cheaper way *in*, never a removed way *out*.

Against our own documents it costs more than it looks: Principle 3's *"do I open this, take this, fight this, **leave now**?"*, `DES-008`'s greed gradient, `DES-022`'s *"growth pulls you toward danger"*, and Principle 4's one-sentence death all depend on depth being **chosen**. Carried loot stops being a decision and becomes an inventory state.

**The late-join entrance is a good idea and is kept** — and it already has a task. `M4-T15` is join-in-progress as `TEC-004` specifies it, sequenced *after* `M4-T01` for reasons that now read as an argument for the Shaft: the world delta is bounded per floor, and a joiner arriving on floor 3 does not need floor 1's state. **The Shaft is the diegetic answer to where that joiner appears** — `DES-005` Layer 3b already says *"the same mechanism that takes you out lets someone in"*, and Tarkov's Scav runs are the shipped precedent for a late arrival dropping into a raid already in progress. Recorded there rather than built here, because it reopens ADR-157's deliberately shut door.

### Decision 4 — ADR-091's guarantee survives, and gains a second reason

`DES-005`'s table said *the Shafts seal, floor by floor*; its guarantee said *the Shaft is always reachable*. ADR-091 resolved that for a one-floor world by building the guarantee — **the Shaft never locks, it gets worse** — and parked floor-by-floor locking at `M4-T01`.

The floors arrived and the contradiction resolves the other way. The Shaft is the way **down** now, so a lock-shaped Sealing would seal the route to the Deep Gate and strand a party with no Waystone — the trapping ADR-015 forbids, reached by the opposite road. Sealing stays entirely a cost curve, `--exit-probe` still refuses to let the Shaft become unusable, and that check is now load-bearing for descent rather than for exit.

### The risk, named

**Waystone drop rate is now the only dial** controlling how often a run ends before the bottom. `DES-005` already warns that too rare means players are *"shoved to floor 3 every run whether they wanted it or not"* — and that warning is sharper now, not softer. It is the single biggest thing this change can get wrong, it is a ⟨tune⟩ number, and only play answers it.

### Rejected

- **Cutting the Waystone** (Decision 2).
- **No early exit at all** (Decision 3) — coherent, well-precedented as a *descent* game, and not the game in the pitch line.
- **A separate Descent object beside the Shaft** — two placed mechanisms per floor, a new graph role, and generator validation that they are never the same node; ~a week against a generator that has only just stabilised. Worth revisiting once somebody has walked three floors and can say whether one object with two meanings reads.
- **Floor-by-floor Shaft locking** (Decision 4).

---

## ADR-187 — Walking into the hole opens onto the Delvings

**Date:** 2026-09-02 · **Status:** accepted · **Completes the descent chain begun in ADR-184** · **`M4-T01`**

**Context:** ADR-183 left the Delvings *"reachable by flag and not by playing"*, and called switching it **one line**. It is not one line, and the reason matters: `room_set` chose its floor by reading `--delvings` out of `OS.get_cmdline_user_args()`, and **a played game has no command line.** The flag was unreachable by playing, so every descent opened onto the Deep regardless of what the run file said.

### Decision 1 — an open run is what says a person is playing

The floor source now comes from `RunFile.exists()`. A run is open exactly when somebody walked in through the front door (ADR-143 put `begin()` on the descent, which every route into the Deep passes through), so it is the honest signal. The flags still work and are still how a measurement asks for a particular floor.

**The Deep survives as the test stage, and that is not the fallback ADR-064 bans.** An unarmed process is a probe (ADR-138); `AuthoredFloor` is the fixed, deterministic floor thirty of them measure, and four — `--sight-probe`, `--route-probe`, `--nav-probe`, `--walk-probe` — are *written around* six rooms and twelve doors. The generated floor has its own checks in `--build-probe`, `--plan-probe` and `--delvings-probe`. Two floors, one played and one measured against, rather than two paths a player could be on.

### Decision 2 — `--seed=` still wins, because otherwise the printed seed is a lie

`TEC-001` requires a run seed to be loggable and replayable off a bug report, and `Threshold._descend` prints one at every descent. A real run always has a run file, so without an explicit override the file's seed would always win and *"launch with the seed from the report"* would silently build a different floor. The named flag beats the file.

### Decision 3 — three things were reading the Deep's coordinates from the game path

Not probes. Game code, which would have been wrong on every generated floor and silent about it:

- **`_the_prize_is_still_here`** — a `DES-016` deed measuring 3 m from `PRIZE_AT`, a constant in the authored level. On a generated floor it would have answered *no* forever, and **a deed that never fires is indistinguishable from a deed nobody earned.** `FloorSource` gained `prize()`.
- **`_reset_floor`** — placed bodies at `SPAWNS` and the Hunter at `HUNTER_POST`, which on a generated floor is a body standing inside whatever the generator built there. `M3-T22` spent a whole probe learning to recognise that symptom.
- **`ArrivalBrief`** — said **"THE DEEP"**.

### Decision 4 — the screenshots found what the probes could not

The first look at a generated floor was taken with a new `--delvings-shot`, and it found two things no check in this project can see.

**The Shaft's prompt said *"hold e/X — climb out"* on floor 0**, where ADR-186 takes you down. The player reads one verb and the game does another, which is the legibility failure `DES-018` is written against — and nothing asserts prompt text against behaviour. Fixed by giving `Shaft` a `leads_out` flag that **both** the prompt and `_on_shaft_claimed` read, because two derivations of one fact is how words and behaviour drift apart in the first place.

**The arrival brief named the wrong place**, and now names the right one out of `DES-015` Layer 2's own structure: *"THE DELVINGS · THE AFTERMATH / THE RETREAT / THE CAUSE."* Naming the depth is the cheapest half of the rule that the Calamity be readable within thirty seconds.

**And the shot tool's own first finding was about the shot tool.** It stood at straight-line midpoints between anchors and photographed solid rock three times out of four, because a cyclic layout with dog-legs has no straight line between any two of its anchors. It looked exactly like a broken floor. Every view now stands on an anchor the generator chose and aims at a door light — `M3-T22`'s lesson arriving for the fourth time in this milestone.

### The row that keeps it from reverting

`--again` is the only check that walks the real route — front door, class, camp, hole — so it is the only one that can say what a **player** lands on. It now fails unless the descent logs `[delvings]`. Without it the switch would revert in silence: every probe in the sweep runs unarmed and therefore gets the Deep, so nothing else would notice the game going back to six grey rooms.

Measured on two consecutive real descents, seeds 2661306861 and 2130218600, both built and both walked into.

### Rejected

- **Moving every probe to the Delvings** — the honest option, and a couple of days: four probes are about six rooms and twelve doors and would need rethinking rather than editing. Revisit when the Deep's checks start disagreeing with the game.
- **Keeping `--delvings` as the switch** — unreachable by playing, which is the whole defect.

---

## ADR-188 — The lantern, and darkness as something you spend

**Date:** 2026-09-03 · **Status:** accepted · **`M4-T13`** · **Amends `DES-009`, `DES-008`, `DES-018`, `DES-020`, `ART-001`, `TEC-006`**

**Context:** `ART-001` has said since the design lock that **darkness is a mechanic, not an effect**, `DES-008` spends a weapon slot on a lantern, and `ART-005` builds an entire visual direction on the sentence *"your lantern does not illuminate, it draws."* **No task built one, in any milestone.** `M2-T13` lit the floor as far as it can be lit without a light source, and the ambient energy stood at 0.34 under a comment promising it would drop *"when the lantern lands."* Meanwhile `Enemy._can_see` was range, cone and line of sight — **no light term anywhere** — so *"carrying a lantern makes you visible"* was a design document describing a build that did not do it.

### Decision 1 — light is `ClamorSource`'s twin, not `ClamorField`'s

`DES-009` says light should be *"built on the same Clamor field the Hunt uses — one system, two consumers, which is the right kind of economy."* **The economy is right and the layer is wrong**, and the codebase already draws the distinction that settles it (ADR-073):

| | Answers |
|---|---|
| `ClamorSource.audible_at()` | *can that enemy hear me **right now*** |
| `ClamorField` | *where in the level was noise, and **how long ago*** |

**The field is a memory of events.** Its entire justification is that the Hunter does not know where you are — it knows where noise *was*, which is what makes shaking it real rather than performative. **Light has no past tense.** A lantern is a state attached to a moving body: it either reaches you from where it is now, or it does not.

Put light in the field and you get a luminous trail the player left five seconds ago that enemies still walk toward. Decay it fast enough to fix that, and you have built a diffusing grid whose values only ever describe the current frame — a per-body query wearing a field's costume, paying a blur over the whole floor for the privilege.

So light enters at `ClamorSource`'s layer instead, as a new **`Exposure`** component. Both are per-body, instantaneous, occlusion-tested, host-authored and replicated `ON_CHANGE`; one is read by ears and one by eyes. `DES-018`'s rule that *every audio channel has a visual twin* turns out to be true of the **systems** and not only of the feedback.

**Where they genuinely differ is the one line that had to be written twice.** `ClamorSource.reach()` spends an occluder budget so sound rounds a corner and dies through a wall; `Exposure._reaches()` is a single ray, because a lamp behind a wall contributes exactly nothing. That is the physics that made one structure for both dishonest, stated as two functions of four lines each.

`DES-009` §Stealth is amended accordingly.

### Decision 2 — no fuel

Nothing in any document says the lantern burns down, and it stays that way.

- `DES-022` requires power to cost **risk, not time**, and a burn-down clock is time.
- `DES-005` deliberately refuses a hard timer; the Hunt is the pressure, and `DES-019` reserves exactly one HUD element for urgency. A second clock competes with the first for the channel that carries it.
- Principle 4 — *"I ran out of oil"* is a worse sentence than *"I was lit up and it found me."*

**Reference:** Darkest Dungeon's torch is the canonical case *for* fuel and it works because that game **is** its light meter — an explicit gauge driving encounter tables, in a party-management resource game. Amnesia's tinderbox works because darkness costs sanity, a second resource. We have the Hunt doing that job and no second resource. What stops *"lantern always on"* is Decision 3, not an oil economy.

### Decision 3 — the verb is turning it **off**, and the cooldown is what makes it honest

A shutter is a decision every few seconds — *see, or be unseen* — in one input, with no economy behind it. Principle 3 in a keypress.

**It is not a free swap by another name.** ADR-057 made off-hand swapping slow and interruptible precisely so a shield and a light cannot both be carried and flicked between. The shutter does not change **which** thing is in your hand; it changes what that thing is **doing**, and it buys darkness rather than a shield. The off hand stays spent either way.

**What the off hand is contested by today is a two-hander, not a shield.** There is no shield item in the corpus, so `DES-020`'s *"a player with a shield is blind in the dark"* still describes a trade nothing can make; the real contest is the Veiðimaðr's yew bow against a lamp. `DES-020` is amended to say so rather than to claim a measurement it did not get, and the shield arrives with `M4-T17`'s taxonomy.

**The cooldown is load-bearing and was not in the first draft.** Without it the optimal play is to strobe the lamp — a frame of light to read the room, dark again before anything resolves sight — which buys vision at no exposure and deletes the trade the whole item is. `shutter_seconds` ⟨tune⟩ is therefore how long before you can work it *again*, not an animation length.

### Decision 4 — what light buys you, measured

| | Seen from | You see |
|---|---|---|
| **Shutter open** | **16.0 m** — the full `enemy_vision_range` | ~11 m of drawn room |
| **Shutter shut, away from every lamp** | **6.7 m** | almost nothing |

**A lit player is seen five metres before they can see.** That asymmetry is the cost, and it is deliberate: the lantern advertises you further than it lets you look.

`ART-001` asks for enemy silhouettes at 20 m, and **the lantern does not deliver that, correctly.** `ART-005` already owns the answer — *"enemies and loot always outline, at full weight, regardless of distance ⟨tune⟩; if the shader ever makes a threat harder to see, the shader is wrong."* Threat legibility belongs to the ink pass at `M4-T08`, not to the reach of a lamp. Making the lantern reach 20 m would light you up further than the thing hunting you can see, which is the opposite of the mechanic.

### Decision 5 — how dark is dark: **0.12**, and the number was never doing the job it was blamed for

`PRO-001` names lowering the ambient as the point of this task. `--light-shot` was built to answer it — the same view, four ambient values, shutter open and shut, eight images of a real generated floor — and the finding corrects the brief:

**The ambient energy was never what made the floor navigable. The doorway lamps were.** At the darkest standable point on seed 31346 floor 1 — 20.3 m from the nearest of thirty lamps — the floor is near-black at **0.34** and at **0.06** alike; the ambient term barely registers on dark stone at that distance. Near a doorway lamp, geometry stays fully readable at 0.12.

So the drop from 0.34 to 0.12 changes what a player can *see* very little, and changes what an enemy can see a great deal — the exposure floor falls from 9.7 m to 6.7 m. That is the correct trade and it is the opposite of what the task expected to find.

`DES-018` keeps its veto and keeps it satisfied: **you can cross a floor with the shutter shut by moving between the lamps**, which makes `M2-T13`'s doorway lights terrain rather than decoration, and gives an unlit crossing a real shape — slower, blinder, and much harder to see.

### Decision 6 — the two halves of one fact now live in one place

The ambient energy moved from `RoomSet.AMBIENT_ENERGY` into `TuningProfile.floor_ambient_energy`, **directly beside `exposure_ambient`**. They are one fact seen two ways — what your eye gets, and what an enemy gets — and they were in different files with nothing tying them together. A floor darkened without its partner would look black and still get you spotted at the same distance: the worst possible outcome, and one that would have read as the lantern not working. They cannot be derived from one another, so what `validate()` enforces is that they were not tuned in opposite directions.

The first `--light-shot` demonstrated the hazard immediately, by sweeping one and holding the other still.

### Decision 7 — co-op is free, because a teammate's lamp and a doorway lamp are the same thing

`Exposure` takes the **maximum** over every light that can reach you, and door lights join the same group a carried lantern does. So four players with four open shutters are a floodlight, one player carrying the light for the party is a formation, and a lit doorway is somewhere you are visible standing — all with **no co-op branch anywhere**. `DES-012` gets its answer out of the data structure rather than out of a rule.

A maximum, not a sum: two lamps do not make you twice as visible, and summing would let a corridor of dim lamps quietly exceed a lantern held to your face.

### Rejected

- **Light in the Clamor field**, as `DES-009` specified — Decision 1. One structure serving two different physics, for tidiness.
- **Fuel** — Decision 2. A second clock beside the Hunt.
- **Putting exposure on the Ear** — the Ear's contract is that it renders *the same `HuntMix` object* the score is driven by, and `--ear-probe` fails if a mix channel exists that nothing draws. Light is not in the audio mix, so this would mean inventing a mix channel to justify a HUD element, and it would break the Ear's *cause inside / effect outside* split. **The lamp is its own readout** — `DES-019` rule 6, diegetic where free — and the verb is taught in `ControlsScreen` like every other binding.
- **A `LightTrait.fuel` and `drop_lit` field, per `TEC-006`'s row** — absent rather than stubbed (ADR-064). A lantern left burning in a doorway is a decoy, and a decoy is only interesting once something navigates light. Nothing does; the Gullsjúkr reads clamor. It becomes buildable when it becomes a decision.
- **Giving the Veiðimaðr a lantern** — the yew bow is two-handed, so `DES-020`'s own rule (*"no lantern, no shield, no map without stowing"*) makes the kit impossible. Left as it is, and it is the better design: the Húskarl walks lit and loud, the archer descends dark and chooses bow **or** lamp. Two classes, opposite relationships to light, out of a rule already accepted.

### What this found on the way

**`ClassResource.kit` had no validator, and its own comment said it did** — *"an id nothing knows fails `validate()` rather than silently arming somebody with nothing."* Nothing checked it. `_dress_the_body` equips a kit in array order and `Equipment.equip` **discards** what conflicts, so a lantern added to the Veiðimaðr would have spawned a bow-less archer holding a lamp, with no error. Four rules now live in `data_probe.gd`, all four planted: the id resolves, it occupies a slot, one item per slot, and no two-hander beside an off-hand item. ADR-098's question asked of a promise instead of a function.

**The controls-coverage probe caught the new binding before a person did.** `shutter` was in the input map and taught nowhere, and `_controls_probe` failed on it unprompted — the check working exactly as ADR-139 intended.

**The pad had no free button**, so `shutter` took `DPAD_LEFT` and `debug_reset` moved to `START`. That is ADR-137's argument applied a second time rather than a new one: *a debug toggle does not get to hold prime real estate while a gameplay verb goes unbound.* The full layout pass is still `M4-T06`.

**And `--light-shot`'s first two findings were about `--light-shot`** — the fourth and fifth time this milestone. It let the body drift toward a lamp between exposures, so the 0.12 image came out *brighter* than the 0.34 one; and it derived each step's exposure from the previous step's mutated value rather than the baseline, so the sweep compounded 0.15 → 0.43 → 0.71 while reporting a floor going dark. Both produced plausible numbers. `TEC-007` §1's rule about assertions built from convenient existing values, arriving in a measurement instead of an assertion.

**`glare` was almost a field that could not be turned down.** The bearer's lamp has to sit in the shared light group so *teammates* are lit by it — and that meant it was counted twice for its own carrier, once at `glare` and once at a 0.35 m falloff worth ~0.97. At `glare = 1.0` the two agree and nothing shows. A designer authoring a dim candle at 0.3 would have got 0.97 anyway, with no way to find out why. `Lantern.owns()` excludes it from the walk, and the row that catches it turns the dial down mid-probe rather than trusting the shipped value — because a row written against `glare = 1.0` would have passed against the broken build.

**And the sight row failed on a healthy build before it worked.** It placed the enemy once and read it twice with 0.4 s between; an enemy that has seen you is ALERTED and *walks*, so by the second read it had left its mark and the row blamed the lantern for the pathfinding. It now settles the exposure first and places the enemy second. Wait for the thing you are about to measure, not something that arrives near it.

**The lantern was gold, and `--sight-probe` refused it.** `ART-005` spends the game's only saturated hue on *"treasure, your ember, her fire"*, and a lantern filed itself under **fire** — warm amber, `Color(1.0, 0.78, 0.42)`. The check caught it on the first full sweep, and it is right for a reason larger than the letter of the rule: **a lantern lights the whole room.** A warm sconce tints one corner; a warm lantern tints everything you can see, everywhere you go, for the entire run. Gold means *this will get you killed*, and a gold lamp says it about every wall in the Delvings.

`ART-005` had already answered it, in the sentence the whole item exists to serve: the Deep is *"pale bone-white ink, appearing only in lantern reach."* **The lamp is the thing doing the drawing, so it is the colour of the ink** — `Color(0.91, 0.90, 0.89)`, kept clear of `GOLD_MARGIN` rather than tuned up against it, and still warmer than the cold `PALE` of a doorway lamp so a carried light reads as a different kind of thing.

Worth recording because it is the one time today the check was right and the code was wrong, against a day of the reverse — and because the failure mode it prevented is invisible: nothing about a nice-looking amber light announces that it has spent the palette's entire budget.

**And changing how far a body is seen from broke a co-op check that had nothing to do with light.**

`run_doorway.py`'s extraction scenario stands three bodies still for a 1.1 s Waystone channel each. `DES-005` makes that channel *"a moment you can be interrupted in"*, and being downed silently zeroes it (`_go_down` cancels whatever you were doing, correctly). So the check has always asserted **three consecutive uninterrupted channels on a floor with live enemies on it** — something the design explicitly refuses to guarantee. It passed on luck.

`M4-T13` changed enemy sight and the luck ran out: four runs in a row, an enemy reached the first client mid-channel and the scenario stranded the party. It cost most of a day, and almost all of that was spent looking for a networking fault, because the symptom — `ERR_UNAUTHORIZED`, *"the camp cannot find the body"*, a haul arriving as zero — reads exactly like broken replication. **The lantern did not break extraction.** It perturbed a check whose subject is a scene change across three peers and whose outcome depended on enemy pathing.

`_clear_the_floor()` takes the threats off before the measurement, and says why in its header. A check that can go red for a reason unrelated to its own claim is worse than no check, because the next person to see it red spends the day I spent.

Two lessons worth keeping, both already in `TEC-007` §1 and both re-learned at full price: **the check can be wrong instead of the code, and it usually looks right when it is** — and a green suite is only evidence about the thing each check actually controls for.

Seven probe rows in `--lantern-probe`, each planted against a deliberately broken build and each caught; four more in `data_probe.gd`, likewise.

---

## ADR-189 — The interface has no regions, and three `DES-019` layers do not exist

**Date:** 2026-09-04 · **Status:** accepted · **Adopts `TEC-009`** · **Puts a `M4-T05` split to a person** · **Reported from play**

**Context:** four sentences from play — *"everything but the Ear is just plain text"*, *"overlapping text in the threshold/hoard areas"*, *"more apparent how users get into skill and character menus"*, *"the inventory/character menu is basic."* `DES-019` is `accepted` and has been since the design lock. `TEC-009` is the review of what was actually built against it, in the same relationship `TEC-007` has to `DES-015`: a design document that decided the thing and stopped short of how it is built or checked.

The review's job was to find out whether this is a styling problem. **It is not**, and the four findings below stand whatever is decided about sequencing.

### Finding 1 — three of the six layers were never built

`room_set.gd:3693` builds the entire in-run HUD and it is five children. **Layer 2 (Body), Layer 3 (Burden) and Layer 4 (Party) do not exist.** That is scheduled rather than forgotten — `wound_vignette.gd:26` says so in as many words, and refusing to build a provisional Burden layer was the right ADR-064 call at the time. Two consequences were not visible when it was made:

- **The Waystone.** `DES-019` calls the indicator binary and *"answerable in a glance"*; ADR-186 raised it to the sharpest mark on the HUD, because the Shaft leads *down* now and a Waystone is the only extraction above the bottom floor. The only way to answer *do I have a way out* today is to open the bag — and `DES-019` designs the bag so that opening it is a vulnerable act. **The game charges the player safety to answer a question the design says is free.** One `DES-019` rule failing against another, and the fix is one mark on screen.
- **The party.** `FallenReadout` binds to `local_player` (`fallen_readout.gd:66`), so in company you cannot see whether a teammate is up, down or a Vörðr unless you can see their body.

### Finding 2 — nothing owns a region, so "overlapping text" is not an ordering bug

Measured, windowed, at 1152×648: the Chamber's readout is one `Label` at `(18, 18)` occupying **50% of the screen's width and 71% of its height**, and the Threshold's is 57% × 62%. Two of the Threshold's lines are `+=` appended (`:955`, `:1048`), so the block's height is a function of game state and nothing bounds it.

Underneath that, every screen sets its own inset as a literal at its own call site — **18, 22, 40, 48, 64, and centred** — and `CanvasLayer.layer` likewise: **0, 5, 6, 7, 8, 30**, six literals at six sites with no register. The two hub readouts are on layer 0, beneath everything.

So the reported collision is not a z-order to nudge. **Nothing owns a region of the screen**, and the only thing standing between a player and a collision is that nobody has yet written a string long enough. `TEC-009` §5.1's answer is to make `DES-019`'s own regions code — `Ear` is already the working prototype of it, and generalising its three habits is the whole proposal.

### Finding 3 — the check does not exist, and this is the second report

ADR-140, three days into `M3`: *"the UI is showing some text on top of others in the inventory."* The blurb's third wrapped line drew through the footer prompt. Every existing row was green, because `overflowing()` measured **widths** and *"never asked whether a block fits its height."*

That was fixed inside one screen, band by band, after the report. `BagScreen.overflowing()` is called by `--bagui-probe`, is correct, and is **the only place in the project that asks a layout question at all** — so the fault is not a dead name (ADR-098) but a live check with a scope of one screen. **The general question was never asked**, and nothing in the ten UI probes asserts that two pieces of interface do not land on the same pixels. `TEC-009` §5.6 is `overflowing()` given a home, which is what the region grammar buys.

**And the screenshot harness does not run headless**, which is not written down anywhere and cost this session ten minutes: `_draw` never executes in a headless process — the whole reason `--ear-shot` exists (ADR-090) — so `--headless --chamber-shot` hangs on `RenderingServer.frame_post_draw` rather than failing. `TEC-009` §5.6 records the windowed form.

### Finding 4 — the vocabulary's colours are absolute, and `ART-005` inverts the ground

`MenuStyle.INK` is `Color(0.07, 0.065, 0.06)` — near black — with bone text. `ART-005` specifies the Threshold and Chamber as **white ground, hard black ink, fully drawn**, against the Deep's inverse. When `M4-T08` lands, **every Lair screen becomes a black panel on a white world**: the hub wearing the Deep's interface, at maximum contrast in the wrong direction.

The rule that fixes it is one line — *ink is the opposite of the ground, and the ground flips at the Descent* — and it is nearly free now and a seventeen-screen migration later. The same is true of `M4-T11`: colour-blind support, UI scaling, a dyslexia font and high contrast are each a global swap of a font, a size or a palette, and font sizes are currently `add_theme_font_size_override` calls scattered across seventeen files. **The constraint that says do not build something that makes `M4-T11` impossible is currently being built.**

### What is adopted here, and what is not

**Adopted:** `TEC-009` as the review, the four findings above, and its framing — the four reported sentences are two structure faults, one missing door, and one correctly-scheduled art gap. It stays `status: proposed` until a task implements it, exactly as `TEC-007` did between this ADR's equivalent and `M4-T01`.

**Not adopted, and deliberately left to a person:** `TEC-009` §8 proposes splitting `M4-T05` — *"Real art pass, real audio, real UI, ping system"* — into an asset half that stays in `M4·B` and a structure half (`M4-T20`, ≈2–3 weeks) that moves to `M4·A`. The argument for it is ADR-165's own test applied again — **a gate that cannot be asked on the build it gates belongs somewhere else** — and it indicts the current order twice: `GATE M4 COOP` is an `M4·A` gate that depends on Layer 4, and `GATE M4 GREED` is a decision made against weight and the Waystone, none of which are on screen.

That argument may well be right. **It is still a change to a sequencing a person decided, made by the party that benefits from the change**, which is ADR-165's own reason for leaving two convenient check adjustments alone: *adjusting a check because it is inconvenient — while actively trying to get past it — is how a check stops meaning anything.* The same suspicion applies to a roadmap. It is recorded so the decision is taken on its own merits, and **no interface code is written until it is.**

If the answer is no, the work waits — and `GATE M4 COOP` should then be annotated with what it cannot currently ask, so nobody runs it and writes the result down against the ember rescue.

### Verification

No game code changed, so there is nothing to plant. The measurements are reproducible: `TEC-009` §0 carries the two windowed screenshot commands and the luminance threshold the bounding boxes were taken at. The sweep, `check_project.py`, `check_dead.py` and `status.py --check` all pass on this commit.

---

## ADR-190 — `M4-T05` splits, and the split is a third of what was asked for

**Date:** 2026-09-04 · **Status:** accepted · **Answers `TEC-009` §8** · **Splits `M4-T05`** · **Orders `M4·A`** · **Accepts `TEC-009`**

**Context:** ADR-189 put a sequencing question to a person and it has been answered: split `M4-T05`, but not the way `TEC-009` §8 asked for. **The proposal was ≈2–3 weeks of interface structure into `M4·A`. This takes about a week of it and leaves the rest where ADR-165 put it.**

### The argument that shrank it is the stranger session

`TEC-009` §8 justified the move on two gates: `GATE M4 COOP` needs Layer 4, `GATE M4 GREED` needs weight and the Waystone. Both true, and both are `M4·B`-adjacent gates that arrive late.

**The gate that arrives first needs none of it.** The stranger session — three testers, three runs, moved to `M4` by ADR-165 — has four clauses, and every one of them is answerable on interface that already exists:

| Clause | What answers it | State |
|---|---|---|
| reaches an exit having entered ≤4 rooms | wayfinding | needs `M4-T01` |
| answers *"how much noise are you making?"* roughly right | the Ear | **built** (`M2-T03`) |
| explains a death in one sentence | combat readability | needs `M4-T16` |
| discovers they can drop loot untold | `ControlsScreen`, the bag | **built** (`M3-T16`, `M2-T01`) |

So the cheapest, earliest and most informative gate on the board is blocked by **two depth tasks and zero interface work**. Front-loading three weeks of layout ahead of it is `PRO-007` §1's mechanism exactly — iterating on the legible thing while the core question stays unasked — and `PRO-007` §1 is the risk this project was told is its most likely.

**`TEC-009` §8 was written by the party that benefits from the change, and it over-claimed.** Recording that plainly is the point of ADR-189 having left it to a person.

### What moves, and why each row cannot wait

`M4-T20` takes the gate-blocking quarter of `TEC-009` §5 and nothing else:

- **`HudFrame`, the region grammar** (§5.1). Not for tidiness. The two readouts below are two more corner literals without it — the fault `TEC-009` §1.3 measured — and it is what makes the overlap check writable at all.
- **Layer 3's Waystone mark** (§5.4). ADR-186 made it the only extraction above the bottom floor; today the answer costs a rummage, and `GATE M4 GREED` is a decision about exactly this.
- **Layer 4's party frames** (§5.4). `GATE M4 COOP` asks a repeatedly-downed newcomer whether they still want to go again, and `FallenReadout` binds to `local_player`.
- **The overlap check** (§5.6). Second report of the same bug (ADR-140).

### What stays in `M4-T05`, deliberately

The Lair layout, the `MenuStyle` vocabulary, Layer 2, and the doors. All four are right; none is gate-blocking; all four are better done beside the art they are sockets for. **This is not a deferral dressed as a decision** — they have a task ID and a milestone, which is ADR-064's test.

**Two exceptions pulled forward into `M4-T20` on cost asymmetry alone**, not on scope:

- **The two-ground palette rule** — *ink is the opposite of the ground, and the ground flips at the Descent.* `MenuStyle`'s colours are absolute and `ART-005` makes the Lair white-ground, so `M4-T08` turns every hub screen into the Deep's interface worn in the hub. One constant today; seventeen screens after.
- **`MenuStyle` as a Godot `Theme`.** `M4-T11` is a global swap of a font, a size and a palette, against seventeen files of `add_theme_font_size_override`. Also what `CLAUDE.md` §4's *data over code* asks for.

Both are ⟨a weekend⟩ now and ⟨a month⟩ later. Neither is art.

### And the order inside `M4·A` is now written down

`M4·A` listed nine tasks and no sequence. It has one:

> **`M4-T01` → `M4-T16` → the stranger session → `M4-T20` → the rest.**

`M4-T01` first because it is `[~]` and owes exactly two things — `TEC-007` §11 steps 6 and 7, **machines stamped into sockets** and **population against the greed gradient**. Those are not housekeeping: a machine is what makes a floor ask a question rather than be rooms, and greed-gradient population is what makes the loot decision spatial. **They are the literal content of the complaint that produced ADR-165**, and half of the task is already built. A half-finished task held open while new ones start is the most expensive object on a roadmap.

`M4-T16` before `M4-T02` for the reason `M4-T16` already gives, and before the stranger session because *explains a death in one sentence* is a question about behaviour.

**Nothing new until the stranger session runs.** `M4-T02`, `M4-T03` and `M4-T04` are each defensible alone and together they are `PRO-007` §3.

### `TEC-009` goes `accepted`

`M4-T20` implements it, which is the condition ADR-189 set and the same one `TEC-007` cleared at ADR-172. Its §8 is now historical: the recommendation stands, the sequencing claim in it was too broad, and this ADR is the correction rather than a second opinion.

---

## ADR-191 — The pre-mortem re-run at the `M3` gate, three weeks late

**Date:** 2026-09-04 · **Status:** accepted · **Updates `PRO-007`** · **Adds `M4-T21`**

**Context:** `PRO-007`'s last section instructs, in its own words: *"A pre-mortem is not a one-time ritual. **Re-run it at each milestone gate** — the failure modes change as the project does, and the ones that matter at M3 are not the ones on this page."*

`M3` cleared. It was not re-run. `PRO-007` is `updated: 2026-08-15` and has not been touched through the whole of `M3` or the start of `M4` — **a mitigation the project wrote for itself and then did not take**, which is the same shape as every ADR-098 finding: it reads as alive and nothing calls it.

Re-running it found that two of the nine risks have changed materially, one is being actively realised, and one mitigation has had its precondition met for weeks with nothing done.

### §1 has mutated: *"M1 never ended"* is now *"M4 never ends"*

The mechanism is unchanged and the milestone is not. `M4` holds **seventeen open tasks**, and `PRO-007`'s own mitigation — *"timebox iterations, not the milestone. Two weeks per pass; at the end, ship it forward or cut the feature"* — is applied nowhere. ADR-034 removed deadlines correctly; nothing replaced what deadlines were doing, and `M4` is where that bill arrives because it is the first milestone big enough to hide in.

ADR-190's ordering is half the answer. The other half is that the two-week rule needs somewhere to live, and it now does: `PRO-007` §1 names `M4` explicitly.

### §4 is being realised, and it has been answered with documents twice

*"It was elegant and it wasn't fun."* Two independent play sessions have now reported a version of it — ADR-165's *"not enough gameplay mechanic or level depth to test any of our gates"* and `M4-T16`'s *"the gameplay feels a little stale still"* — and **both were answered with a resequencing and a decision record.** ADR-165 reordered `M4`; ADR-189 reordered an argument about the interface.

Neither answer was more game, and `PRO-007` §4's mitigation is one sentence: *"take a failure seriously rather than explaining it away."* A resequence is not an explaining-away, but two of them in a row, with no playtest between, is the same thing arriving by instalments. **Recorded here rather than softened**, because the document exists to hold exactly this.

### §6's precondition has been met since `M1` and nothing has been posted

*"The ink shader is the marketing asset… start posting development shots the moment it works."* `M1-T09` passed its go/no-go at ADR-070 — outlines and boil, measured, GO. That was the condition. `M4-T18` exists and is untouched.

**Not escalated to urgent, and not left implicit either.** `M4-T18` gains the trigger it never had: the devlog starts when the Delvings are photogenic — realistically the `M4-T01` ⟨tune⟩ pass — rather than at an unnamed later point.

### §7, and this session's own contribution to it

*"Documentation became the project."* The corpus is 42 documents and 191 ADRs against roughly two play sessions on a build. This session added a document and three ADRs to that ledger.

The corpus is genuinely load-bearing — it has stopped this design drifting back into a stat ladder three times, and `TEC-007` and `TEC-009` each found a real fault before a month was spent on it. **But the marginal ADR is now worth less than the marginal playtest, and that was not true six weeks ago.** `PRO-007` §7's mitigation is already the standing rule; what changes is the bar, and `M4-T21` carries it: re-running the pre-mortem is itself a gate ritual, not a document that gets improved.

### What this changes

- `PRO-007` §1, §4, §6 and §7 rewritten against the `M3`-cleared state; the re-run instruction gains a task so it cannot be skipped again.
- **`M4-T21`** — re-run the pre-mortem at `GATE M4 EXIT`, and at every gate after.
- The two-week timebox is now written where `M4` can be measured against it.

**No risk was removed and none was added.** A pre-mortem that comes back with a shorter list every time is a pre-mortem nobody is running honestly.

---

## ADR-192 — The rooms ask something now, and a Calamity nobody could read

**Date:** 2026-09-04 · **Status:** accepted · **Implements `M4-T01` step 6** · **Adds `--machine-probe`, `--machine-shot`** · **Fixes `CalamityResource`**

**Context:** ADR-190 put `M4-T01` first in `M4·A` and named what it owes: `TEC-007` §11 steps 6 and 7. This is step 6. `DES-015` Layer 3 adopts Brogue's machines — *"pre-authored situations, not geometry, stamped procedurally into generated space"* — under one rule: **every machine poses a question the player answers with an action.** *"A room with loot in it"* is not a machine.

Before this, every room on a generated floor was space with loot dealt into it by `tribute_value`. Correct, deterministic, reproducible, and **asking nothing** — which is the state the play report behind ADR-165 was describing when it said there was not enough depth to test a gate.

### The rule is the schema, because otherwise this is a second loot table

`MachineResource.question` is **required** and `validate()` refuses a machine without one. That is the only mechanical difference between this system and another way to place items, and it is stated in the resource a designer edits rather than in a document they might not read.

`--machine-probe` **prints** every question. A field only a validator reads is exactly the trap the rest of this ADR is about.

### What was built, and what it deliberately does not know

`MachineResource` (`.tres` under `data/machines/`, `CLAUDE.md` §4's data-over-code), `MachineCatalogue` on `RoomCatalogue`'s idiom including its `.remap` extension list, and `FloorMachines` as pipeline **stage 6** with its own seeded stream.

It keeps the split every stage before it keeps: **which room, never what is in it.** No file in this system names an item. `gear` is a *count* drawn from the same worth-sorted pool everything else is dealt from, because a machine naming `wep_seax` would be the invented taxonomy `delvings_floor.gd` refuses in as many words, and `M4-T17` is what earns the right to name one.

**Two machines, complete, rather than six partial** (ADR-064):

| | The question it asks | Where it goes |
|---|---|---|
| **The Witness** | You have found out what happened here, and there is nothing in this room worth anything. Do you keep going down? | **Unheld only** — it gives ADR-032's safe branch something to be about, since by design it pays badly |
| **The Bad Room** | A crew died here, their gear is on the floor, and the thing that killed them has not moved. Do you go in? | **Held only** — threat belongs where danger already is |

The two constraints were chosen independently and fall out well: a floor carrying both tells you what happened on the safe branch and shows you what it costs on the guarded one.

### Three rooms the mission owns

The entrance, the Prize and the Shaft. A situation on the entrance is one the player walks into before the floor has begun; the Prize already carries the Guardian, which `FloorSource` calls a machine in as many words; the Shaft is the moment `DES-005` has already spent.

**Enforced at the point of use, not trusted to the corpus** — and the plant proved that necessary in a way the first attempt did not. Removing the guard changed nothing, because `fits()` already refuses a machine with empty `roles` for any non-connective role. The plant that reaches the guard is a machine authored `roles = [SHAFT]`: with the guard removed it lands on the Shaft on every floor, with it restored it is never placed. **A guard is only proven by a plant that can reach it.**

### The arrangement, and why nothing in it collides

A machine's `fallen` are laid as marks — long, low, bone, and pointed. `facing` is the verb: *toward the door* is a crew that was trying to leave, *away* is one that was facing something already in the room with them.

**They have no collision, and that is the design rather than an economy.** A 0.24 m box on `CollisionLayers.WORLD` is an obstacle Recast bakes around, and seven in one room is a room full of unwalkable islands. ADR-144 spent a day on a body a probe had dropped inside a barricade; `_mark()` is a separate function from `_slab()` rather than a flag on it, because *architecture the navmesh must see* and *evidence it must not* are different claims and a boolean lets the wrong one be passed by accident.

### The finding: a Calamity that was never told to anybody

`CalamityResource.name_key` had a validator **requiring** it, five `.tres` files supplying one, and **no reader anywhere in the project.** Every other resource carrying that field has a `display()` beside it — `ItemResource`, `DeedResource`, `AspectNode`, `ClassResource`. This one did not.

So a Calamity was rolled per expedition, weighted every room the floor seated through `ExpeditionHistory.favours`, and was **named to the player in no channel at all**, while `DES-015`'s thesis is a place *"where something specific happened, that you can read as you move through it."* The reading had no text and no object.

**And it was worse underneath.** None of the five keys existed in `en.csv`. `tr()` returns its argument when a key is missing, so the failure mode is not a crash or a blank — it is the literal locale key rendered on screen as though it were English. An unread field and an unauthored string hid each other perfectly, and **nothing in the project checks that a `name_key` points at a string.**

`check_dead.py` could not see either half: the field is mentioned by a `.tres`, which is the trap `room_module.gd` writes down and then avoids by refusing to declare a field before something consumes it. `calamity_resource.gd` did not.

Fixed as narrowly as the design allows. `display()` exists, the arrival brief carries it, the five names are authored, and `--machine-probe` fails on any Calamity that renders as its own id or as its own key. **The name only** — `DES-015` Layer 2's discipline is that the pattern is discoverable and never stated, so this says what the disaster was called and never what it was. What happened is read off the architecture and off `mac_witness`.

**One name is not the id's.** `cal_the_sealing` displays as **The Walling**, because `PRO-003` already defines *the Sealing* as the player-facing extraction-pressure mechanic, and *"THE DELVINGS · WORKED SEAM · THE SEALING"* on arrival would read as that mechanic having fired. The id is stable and unchanged (`TEC-006` principle 3); only the display avoids the collision.

### Verification, and three checks that were wrong before the code was

Eight rows planted. Five caught their plant immediately. **Three did not, and each was a fault in the check:**

- **The density row could not fail.** Written as `share > FloorMachines.SHARE`, it compares the measurement against the constant that produced it — so raising `SHARE`, the one edit the row exists to catch, raises the threshold with it. Planting `SHARE = 0.95` passed. It now asserts the *claim* against a fixed half: **most of a floor is quiet, or a situation is not one.**
- **The seed-sensitivity row asserted the wrong thing.** Rolling eighty whole floors and counting distinct stampings returns fifty-plus even with this stage's RNG pinned to a constant, because the *plan* varies by seed. It measured "the floor varies", which `--plan-probe` already covers, and passed against a stamper that ignored its seed entirely. It now stamps **one pinned plan** with eighty seeds, so the only thing that can vary is this stage's stream.
- **The mission-rooms guard was unreachable by its first plant**, as above.

Three true-but-beside-the-point assertions in one probe, all found by planting rather than by reading. `TEC-007` §1's rule earning itself again: **the check can be wrong instead of the code, and it usually looks right when it is.**

**And the screenshot found what no probe could.** `--machine-shot` stands where a player walks in and photographs each stamped room. At the first colour — `0.19`, darker than the stone — the arrangement read as bodies in a lit room and as **nothing at all** in an unlit one. `ART-005` answers which way to move it: the Deep is *pale ink on black*, so a body is something the light draws rather than a hole in the floor. Bone at `0.62`, above `STONE`'s `0.46` so it reads against any wall and below the pale `M2-T13` spends on doorways, because a room full of exit-coloured objects lies about where the exit is. **Fourth time a screenshot has caught what a headless check could not** (ADR-093's rule).

**Wired into the sweep in the same commit as the probe.** `M4-T19` exists because `--graph-probe` was written, correct, and run by nothing for weeks; shipping a second stage the same way would be the same ADR-098 finding with the lesson already written down.

### And `check_dead.py` has a hole, found by falling into it

`FloorMachines` shipped a `questions()` that **nothing called** — written for a run log, never wired — and `check_dead.py` passed. In the same session as an ADR about dead names.

The tool is not broken: a canary named `zzz_canary_for_check_dead` is caught immediately. The hole is in what counts as the corpus. `scenes_and_data()` deliberately includes `tools/*.py`, on the good reasoning that *"the build tooling counts as a reader"* — `CollisionLayers` is read only by `check_project.py` and is doing its job. But `body_text()` strips only `#` comments, and **Python docstrings are not `#` comments.** So `status.py`'s *"Open questions grouped by the milestone their section names"* counted as a use of a GDScript function called `questions`.

**Any GDScript name that is also an ordinary English word appearing in a tool's docstring is invisible to this checker.** That is a wide hole and it has been open since the tool was written; how many names are currently hiding in it is unknown, which is exactly why it gets a task (`M4-T22`) rather than a fix squeezed into this commit — the fix will surface findings that each need judging on their own.

The dead function is deleted rather than kept and called, on ADR-064: absent beats present-and-unused.

### What step 7 still owes

**The greed gradient does not climb with depth.** `DelvingsFloor._by_worth()` ignores `_depth` entirely, so floor 0 and floor 2 draw from an identical pool — and `DES-015` Layer 4 calls the depth curve the load-bearing part: *"value must climb steeply with depth, and the player must be able to see that from floor 1."* The within-floor half is built and has been since ADR-032's rule generalised; the across-floor half is not. Named here rather than left for a later reader, and it is the rest of `M4-T01`.

---

## ADR-193 — The Prize on floor 0 was the Prize on floor 2

**Date:** 2026-09-04 · **Status:** accepted · **Completes `M4-T01`** · **Implements `DES-015` step 7**

**Context:** the last thing `M4-T01` owed. `TEC-007` §11 step 7 is *"population against the greed gradient"*, and ADR-192 measured what was actually missing: the *within-floor* half has worked since ADR-032's held-versus-bypass rule generalised, and the **across-floor** half did not exist at all.

`DelvingsFloor._by_worth()` ignored `_depth`. Every floor of an expedition drew one identical pool, so **the Prize on floor 0 was the same object as the Prize on floor 2** and the only thing that got worse as you descended was the Hunt.

### Why that is worse than a flat number

`DES-015` Layer 4 does not treat the depth curve as tuning. It calls it the load-bearing part: *"value must climb steeply with depth, and the player must be able to see that from floor 1. The Prize being visible-but-distant from early in the expedition is what pulls people down."*

And it reaches further than loot. `DES-003` couples the Tithe to what you carry home, so **a Tithe payable out of the shallowest floor is a Tithe nobody has to descend for** — the pull the whole persistence design hangs off, quietly disconnected. It is also, precisely, the flat middle `DES-015` opens by diagnosing in other games, sitting inside our own generator: *the randomness is in the stuff, not the space*, one level further down again.

### The fix is one function, because everything already reads it

`_by_worth()` returns the pool cut by depth. The Prize, the machine gear and the filler all read that one list, so cutting the list cuts all three and **nothing above the line changes** — which is the promise `delvings_floor.gd` already made about `M4-T17` and is now the second time it has paid.

**One cut, not three tiers.** Floor `d` withholds the dearest `WITHHELD` share, closing linearly to nothing at `RunFile.LAST_FLOOR`, so the floors overlap. Three separate loot tables would make a floor identifiable by its drops, which is the sameness `DES-015` was written against.

Measured across 40 seeds per depth, against the fifteen authored items:

| | Best single item | Total laid, 40 floors |
|---|---|---|
| **Floor 0 — the Aftermath** | 6 | 480 |
| **Floor 1 — the Retreat** | 55 | 5 039 |
| **Floor 2 — the Cause** | 140 | 20 923 |

Twenty-three-fold on the best item, forty-four-fold on what a floor holds.

### The numbers are `⟨tune⟩` and one of them is deliberately uncomfortable

`WITHHELD = 0.45` puts the Aftermath's best find at 6 tribute against a 40-tribute Tithe cycle (ADR-029). **A floor-0 run cannot pay a cycle**, and that is the intended reading of *"power must cost risk"* — but it is a balance claim made against no playtest and it is marked as one.

`GATE M4 GREED` — *a playtester voluntarily abandons loot to survive* — is the measurement that settles it, and it is worth noting that **that gate could not have been run against a flat curve at all**: abandoning loot is only a decision when some of it is worth more than the rest, and until now every floor's best item was the same object. `LEAVE_AT_LEAST = 6` is the floor under the floor: a first act with nothing in it is one `DES-002`'s loop cannot survive.

`M4-T17`'s loot tables replace the slice with authored depth bands, and nothing above `_by_worth()` changes then either.

### The half that is not built, stated plainly

`DES-015` Layer 4 is two clauses and this implements one. **"The player must be able to see that from floor 1"** is not done: nothing on floor 0 tells you the Cause is richer. That is the *visible-but-distant Prize* — sightlines, lighting and the Shaft's framing — which is `TEC-008` and `M2-T13`'s language rather than the generator's, and it is named here rather than left to read as finished.

### Verification

One plant, and it is the bug itself: `WITHHELD = 0.0` restores the flat pool, and all three floors report a best item of 140. Three rows fire — the two strict-climb comparisons and the steepness ratio — so the check fails against exactly the state the code was in this morning.

The row is deliberately measured on **what the floor lays**, not on what the pool contains. A pool cut by depth that nothing read would satisfy a pool-shaped assertion and change no run, which is ADR-098's shape and the reason `--machine-probe` row 7 exists.

**`M4-T01` is done.** `TEC-007` §11's list is complete through step 7; extended step 8 with §6's split remains as `TEC-007`'s own open item, not as this task's.

---

## ADR-194 — A hit staggers when it is heavy, or when it is earned

**Date:** 2026-09-04 · **Status:** accepted · **Implements the first quarter of `M4-T16`** · **Adds `--fight-probe`** · **Builds `DES-009` line 47**

**Context:** `M4-T16` was raised from play — *"the gameplay feels a little stale still and AI will have to be greatly worked on"* — and the roadmap's diagnosis was that a fight *"is a swing timed against a telegraph."* Measured, it was not that. It was not timed at all.

### The fight, in numbers

`Enemy._on_hurt` staggered on **every** hit, for a flat `enemy_stagger`, with a comment explaining that this was *"the whole reward for reading a telegraph correctly."* A stagger costs the enemy `enemy_stagger` (350 ms) + `enemy_telegraph` (500 ms) before its hitbox can arm again — **850 ms**. Against the roster:

| Weapon | Swing cycle | Locked out by |
|---|---|---|
| Seax | 390 ms | **460 ms** |
| Regin blade | 520 ms | **330 ms** |
| Ash spear | 630 ms | **220 ms** |
| Dvergar hammer | 900 ms | — (it is 50 ms too slow) |

Four of five weapons re-stagger the enemy before it can finish standing up. **The lightest weapon in the game was the one that locked an enemy out permanently, and the heavy one — the weapon `DES-009` line 47 says is the one that staggers — was the only weapon that could be hit back.** The rule was not merely unbuilt; it ran backwards.

`--fight-probe` measured it against the pre-poise build: a player holding attack with a seax took **24 swings and zero hits in ten seconds**, and the enemy never started a swing. At the real stamina rate the enemy recovered enough to swing four times in ten seconds — but the fight it is in lasts **1.6 seconds**, because four seax hits kill it. So the honest statement is not *"combat is free"* but *"combat is free for as long as it takes to win it,"* which is the same thing from inside the fight.

**Reading the telegraph was strictly dominated by ignoring it.** Interrupting a windup cancels the attack outright; waiting to dodge only avoids it. Principle 3 says a fight has to be a decision, and there is no decision when one option is never worse.

### Poise, and the two ways through it

`enemy_poise` is a pool a hit spends; a stagger happens when it breaks. `WieldableTrait.stagger` is what each weapon spends — **the field `DES-009` line 47 has implied since the design lock and nothing carried**, because `TuningProfile.enemy_stagger` was one number for a knife and a war hammer.

Two ways to stagger, and a light weapon only has the second:

1. **Break its poise.** The hammer's 100 breaks a full pool in one hit. `DES-009`'s *"heavy staggers"*, now literally that. The seax's 22 cannot: four hits kill this enemy and four hits are 88.
2. **Punish the recovery.** A swing already thrown cannot be taken back, so hitting into `Attack.RECOVERY` always staggers, whatever the pool holds.

Rule 2 is what makes an attack a *commitment* rather than a timer, and it is what `DES-002` needs for *"do I take this fight"* to have an answer other than yes. It is also why this is not simply *"knives no longer stagger"* — that would be a subtraction, not a design.

**Reference: Dark Souls' poise, and it is not a straight copy.** Poise there exists to stop light-weapon spam from trivialising a duel, which is our problem exactly. What differs is the context: `DES-013`'s thesis is that enemies are a *noise system*, not a challenge system, and fights are meant to be **avoidable and expensive**. So our poise is tuned to a stronger requirement than From's — *no melee weapon may solo-lock an enemy* — rather than to a duel's balance.

### What was not done, and why

- **No poise on the player.** `DES-009` gives the player stamina and positional defence, and ADR-114's argument against invulnerability applies unchanged. `Hitbox.stagger` defaults to `0.0`, so the enemy's own hitbox cannot stagger anybody.
- **Poise is not replicated.** Its only output is `_state`, which already is (`TEC-004` costs relevance per enemy per tick).
- **`scarred_power` does not scale stagger.** A Scar is `DES-003`'s tax on damage; letting it erode stagger would mean a scarred hammer stops being a hammer, which is a change to `DES-009`'s light/heavy rule rather than to a number — ADR-058 puts that behind an ADR.

### Two faults found in the checks rather than the code

**`_combat_probe` places the player facing away from the enemy.** It teleports to `-Z` — correctly, so the player is inside the vision cone — and passes yaw `0.0`, which is Godot's forward. The player therefore stands in front of the enemy looking away from it. That probe only ever asks whether the enemy *telegraphs*, which it does regardless, so the error was invisible there and fatal to any probe that asks whether a blow lands.

**GDScript lambdas capture by value.** `--fight-probe`'s first version counted hits into a captured `int`, which increments a copy and reads back zero forever — so it reported that the *fixed* build landed no hits either, and the first reading of this whole investigation was wrong in the player's favour. The counters are a `Dictionary` now. Recorded because it is the third *"true but beside the point"* measurement class this project has hit, and the first where the probe was wrong rather than merely narrow.

### `--fight-probe`, five rows, every one planted

Both passes must see the enemy land a blow; the recovery punish must stagger a **full-poise** enemy (so it is proven to stand on its own rather than on an empty pool); the hammer must break poise in one hit; the seax must not break it inside the four swings that kill. Planted by restoring the old unconditional stagger, by neutering the punish, by lowering the hammer to 40, and by raising the seax to 26. All caught.

### This is a quarter of `M4-T16`

The task names four absent things. This is the first: *enemies that commit to an attack and can be punished for it.* **`M4-T16` stays open.** Still absent: enemies that use the floor's geometry, that react to clamor as a group — `SWARM` is still unbuilt, and `DES-013`'s ladder has had four states since the design lock — and that give a player a reason to disengage. Named here so the tick, when it comes, is about the whole task.

---

## ADR-195 — The slice audit: three decisions the dashboard could not see

**Date:** 2026-09-04 · **Status:** accepted · **Amends `status.py`** · **Restores `GATE M4 STRANGER`** · **Corrects `DES-015`, `TEC-007`, `CLAUDE.md`, `PRO-001`**

**Context:** `M4·A` has landed three tasks in three days — `M4-T13` (ADR-188), `M4-T01` (ADR-192, ADR-193) and the first quarter of `M4-T16` (ADR-194) — by two sessions working in parallel. This is the sweep across all of it, asking the only question that matters about documentation: **where has a document stopped agreeing with the build?**

Six drifts. Three are ordinary staleness. Three are the same failure this project keeps rediscovering — **a decision that reads as alive with nothing calling it** (ADR-098) — and this time the thing not calling them was the dashboard.

### `GATE M4 GREED` has never once been counted

`GATE_RE` matched `(EXIT|COOP)`. ADR-109 moved `GATE M4 GREED` here from `M2` and nobody widened the pattern, so for the whole of `M3` and `M4` the line sat in the roadmap being read by people and by nothing else.

That is not cosmetic. `Milestone.cleared` requires **every declared gate** to have passed, so an unparsed gate is a gate that *cannot block*: `M4` could have been declared cleared with *"a playtester voluntarily abandons loot to survive"* — the sentence `PRO-001` calls **the whole game in one moment** — never asked. Now `([A-Z]+)`, and `M4` went from two tracked gates to four.

### The stranger session stopped being a gate when it moved

ADR-165 moved it out of `GATE M3 EXIT`. The move kept the four clauses and dropped the `> **GATE …**` header, and since that header is the only thing `status.py` matches, the **cheapest and earliest evidence this project has about whether the loop is fun** became invisible to the tool that sequences the work. ADR-190 then made it step three of four in `M4·A`'s order, still as prose.

It is `GATE M4 STRANGER` again. Restored, not invented — it was a gate, and the move lost the header rather than the intent.

### The dashboard recommended exactly what ADR-190 forbade

ADR-190 wrote the order down — **`M4-T01` → `M4-T16` → the stranger session → `M4-T20` → the rest** — and ended *"Nothing new until it runs. `M4-T02`, `M4-T03` and `M4-T04` are each defensible alone and together they are `PRO-007` §3."*

`NEXT UP` was `nxt = [t for t in cur.tasks if t.state == TODO][:3]` — document order, `[ ]` only. On the next run after that ADR it offered **`M4-T02` and `M4-T04`**, two of the three named tasks, and omitted `M4-T16` entirely because a task in progress is not `TODO`. **The one task actually underway was the one thing the dashboard never named**, which is precisely ADR-190's *"a half-finished task held open while new ones start is the most expensive object on a roadmap."*

Three changes, and the first is the one that matters:

- **A `<!-- hold … until=GATE by=ADR -->` line**, read by `status.py`. Held tasks are withheld from `NEXT UP` and listed under `HELD`, and **starting one is a blocking error**. ADR-063 gave this tool the job of refusing work that skips a step; it could only ever see steps *between* milestones, and `M4` is the first milestone big enough for the order *inside* one to matter.
- **`NEXT UP` shows `[~]` first**, marked.
- **A hold naming an unknown task or an unknown gate is an error**, because a hold with a typo in it holds nothing and would fail silently — the exact class of bug this ADR is about.

Four plants, all caught: starting a held task, a hold on `M4-T99`, a hold on a gate that does not exist, and a gate passing while tasks remain.

### And three ordinary drifts

- **`TEC-007` was edited in both ADR-192 and ADR-193 and its `updated:` was never bumped**, so the doc index dated it three days early. `CLAUDE.md` §3 names bumping as step two of four and nothing enforces it — **no check is proposed here**, because "was this file edited without its date changing" is a question about a diff, and the sweep runs on clean checkouts where that has no meaning. It is caught by review or not at all, and saying so is better than inventing a check that would pass.
- **`DES-015` Layers 3 and 4 were implemented and never annotated.** Layer 3 has two of its six machines (ADR-192); Layer 4 has one of its two clauses — value climbs with depth, and the player still cannot *see* it from floor 1, which is `M4-T23`. A design doc that describes built systems as though they were still proposals is how `DES-009` line 47 stayed backwards for three milestones (ADR-194).
- **`CLAUDE.md` said "all 38 documents … and 60 ADRs"** while the build had 42 and 195 — a hand-maintained count in the file every session reads first, wrong by a third. Both counts are now deleted rather than corrected: `status.py` prints them, generated, and a number maintained by hand in a file about not trusting stale views was the wrong shape to begin with. `OPEN-QUESTIONS.md` carried the same rot and got the same treatment.

### What this does not claim

`M4-T16` is still `[~]` and three of its four parts are unbuilt. `GATE M4 STRANGER` is now visible and still `pending`, which is the honest state: **the sequencing is fixed, the evidence is not gathered.** The point of making it a gate is that it can no longer be quietly skipped, not that anything has been learned.

---

## ADR-196 — The floor can be called, and the call can be stopped

**Date:** 2026-09-04 · **Status:** accepted · **Implements `M4-T16` parts 2 and 3** · **Adds `--swarm-probe`** · **Builds `DES-013`'s fourth rung**

**Context:** `DES-013`'s awareness ladder has read **UNAWARE → SUSPICIOUS → ALERTED → SWARM** since the design lock, and the document calls the ladder *"the single most important system in this document."* Three rungs were built. The fourth was deferred at ADR-064 on the grounds that calling others needs clamor to propagate between actors, and the Clamor field was `M2`.

`M2` shipped. The deferral was never revisited, and the reason it stayed unbuilt turns out to be one missing node.

### The propagation arrow had nothing behind it

`DES-013`'s diagram carries an arrow labelled *"(Clamor spike propagates to nearby actors)"*. Every enemy has carried a `ClamorSensor` since `M1-T04`. **None has ever carried a `ClamorSource`** — so enemies could hear the player and were **silent to each other**, and the arrow described a mechanism that had no emitter at either end of it.

That is the whole of the missing system. `M2-T02` already paid for hearing: `ClamorSensor` scans the `clamor_sources` group, skips anything at zero level, and muffles through occluders. An `ALERTED` enemy that makes a noise gets propagation for free, with no new sense, no new grid, and no new per-agent cost — the sensor's loop already early-outs on a silent source, so an enemy that is not shouting costs one null check.

### `CALLING` is the beat, not a fifth rung

`DES-013` is specific: the failure state *"must be loudly telegraphed a beat before it happens so the player gets one chance to prevent it."*

That beat is a **state** rather than a timer, and deliberately: `_state` is already replicated and already drives `_apply_state`'s tint, so a client sees the wind-up for free. A host-only float would have made *"one chance to prevent it"* a chance only the host gets, which fails `DES-018`'s parity guarantee on a co-op mechanic.

The ladder still has four rungs. `CALLING` is the telegraph of the transition into the fourth.

### Three counters, and one of them had to be added

A call is prevented by **staggering it**, by **breaking line of sight**, or by having **finished the fight inside five seconds**.

The first falls out of ADR-194 a week early: `_break_poise` throws a call away, so the hammer that breaks poise in one hit and the recovery-punish a knife earns are both answers here. **The two halves of `M4-T16` turn out to be the same decision seen twice.**

The second was added after checking the first was enough, and it was not. The beat is 0.9 s; a seax swings in 0.39 s and deals 15, so a light build inside the telegraph can land two hits for 30 against 60 hit points — **it could neither stop the call nor kill through it.** A counter only the heavy weapon owns is not a counter, it is a weapon tax, and `PRO-005` §5 wants counters a player can name. Losing sight cancels the call; `_alerted_for` keeps running, so ducking behind a pillar re-calls the moment you lean out, and only genuinely losing the body clears the clock. **That is what makes disengaging the answer rather than a delay**, which is `M4-T16`'s fourth item and why this ADR closes two of them.

### The Ear needed no new channel, and that was already designed

`DES-019` Layer 1 lists room state as *unaware / suspicious / alerted / swarm*, `DES-018` requires a visual twin for every audio channel, and `--ear-probe` fails any mix channel nothing draws. A fourth state looked like it needed a fourth readout — and it does not, because `HuntMix.alert` is documented in its own comment as *"`DES-013`'s ladder, flattened to a scalar so it can be shown continuously."*

What was wrong is that **`ALERTED` returned 1.0**, so the ladder's top rung had nowhere above it to go. Rescaled to four levels — SUSPICIOUS 0.35, ALERTED 0.70, CALLING 0.85, SWARM 1.0 — which also means **the Ear grows during the beat**, making `DES-013`'s *"loudly telegraphed"* true in the visual channel without a single new element. `DES-019` rule 5 permits exactly one element to carry urgency; adding a `swarm` channel would have broken that rule to say something the existing one already says.

### Two faults this found

- **The clock did not run during the fight it is about.** `_alerted_for` was incremented inside `_act`, which `_physics_process` skips entirely while `_attack != NONE` — and a body inside its attack range is in an attack cycle roughly nine tenths of the time. It advanced about one frame per second, so the call arrived minutes late. Moved beside poise regeneration, which is already where *"things true of this body regardless of what it is doing this frame"* live. `--swarm-probe` bounds the timing now rather than only asking whether it escalated at all, because *"it escalated eventually"* passes that build.
- **Two probes compared `state() == ALERTED` and would have broken in opposite directions.** `--fallen-probe` asserts an enemy *did* notice and would have started failing a healthy build; the Vörðr row asserts one did *not* and would have **passed a broken one**, which is worse. Both meant *"has it got you"*, so `Enemy.is_hunting()` says that once.

### A third fault, found by a probe about snares

`--stalker-probe` went red on the first full sweep, and it was right to. It
measures a snared body's movement over a window, then measures the **same
window with nothing holding it** — a control it added after an earlier draft
compared against a body that had already arrived and stopped, so *"it did not
move"* was true for the wrong reason. That control has a vacuity guard: if the
released body also covers nothing, the row says so and fails.

It fired. By that point in the probe the body has held the player for far
longer than `enemy_swarm_after`, so the first thing it does on being released
is **stand still and shout** for most of the window.

The first fix — wait out the call, then measure — traded this confound for the
one the probe already knew about: the extra second let the body close the last
of the distance and start swinging, and the control read 0.10 m instead of
0.00. It now resets the clock (`Enemy.reset_alert_clock()`), which leaves the
measurement at the instant of release and removes only the variable this probe
is not about.

**The behaviour itself is not a bug and was not changed.** A snared enemy
calling for help is the system working; `PRO-005` §5 would be poorer without
it. What was wrong was a probe measuring one thing and reading another.

### What `M4-T16` still owes

**One of four**: enemies that use the floor's geometry rather than walking through it. Pathing exists (`M2-T14`); what is absent is tactical use of it — flanking, holding a doorway, breaking line of sight of their own accord. It is the vaguest of the four and the only one with no measurement behind it yet, which is why it is named here rather than guessed at.

### Three of the five rows proved nothing, and one of them found dead code

The first plant pass caught **two of five**. The three that walked through are worth recording, because all three were rows that *looked* like assertions:

- **The beat row polled for `CALLING` once per frame.** A beat of zero seconds is still `CALLING` for one frame, so a build that shouted with no warning at all passed. It measures the **duration** now and holds it to `TELEGRAPH_FLOOR` — a frame is not a chance.
- **The self-skip row checked the caller straight after its own call**, where `_listen` returns early on ALERTED, CALLING, SWARM and STAGGERED. The state machine protects the caller there whether or not the sensor skips itself, so the guard was never reached. The case that actually bites is a *quiet* body whose own clamor is still decaying, and the row tests that now: spike an UNAWARE body's own source and it must stay UNAWARE.
- **The stagger row could not fail, because the line it was testing does nothing.** `_break_poise` sets `_state = STAGGERED`, and `_tick_call` runs on no other state — so leaving CALLING is what cancels the call, and the `_call_timer = 0.0` sitting beside it was unobservable from any state that line can be reached from. **Deleted rather than kept**: it read as the mechanism and was not, which is ADR-098's question asked of code written an hour earlier. The row now plants a regression that could really happen — `_on_hurt` skipping poise while a body is *"busy shouting"* — and catches it.

Five rows, all five planted and caught after that.

---

*Entries below to be added as design decisions are signed off.*

