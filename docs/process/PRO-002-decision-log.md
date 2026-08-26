---
id: PRO-002
title: Decision Log (ADRs)
status: accepted
owner: process
tags: [decisions, adr, process, history]
updated: 2026-08-25
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

### One number that was written down twice

The scenario waited a literal for the Waystone's channel. It reads `ExtractionTrait.channel_seconds` off the item now — a harness carrying its own copy of a game value is a second source of truth, and this milestone has already produced two: the revive row measured against `TuningProfile.player_health` while a Húskarl revives against 125 (ADR-127), and `--tithe-probe` assigning a `pact_rank` that had become derived (ADR-126).

---

*Entries below to be added as design decisions are signed off.*

