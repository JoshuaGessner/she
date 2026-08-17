---
id: PRO-002
title: Decision Log (ADRs)
status: accepted
owner: process
tags: [decisions, adr, process, history]
updated: 2026-08-17
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

*Entries below to be added as design decisions are signed off.*
