---
id: PRO-002
title: Decision Log (ADRs)
status: accepted
owner: process
tags: [decisions, adr, process, history]
updated: 2026-08-12
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

*Entries below to be added as design decisions are signed off.*
