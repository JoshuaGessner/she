---
id: TEC-009
title: Interface Architecture
status: accepted
owner: tech
tags: [ui, hud, layout, legibility, accessibility, godot, research]
updated: 2026-09-04
related: [DES-019, DES-018, DES-014, DES-008, DES-020, ART-005, ART-001, PRO-005, TEC-001]
---

# Interface Architecture

> **Accepted 2026-09-04 by ADR-190.** Changing anything here now requires a
> further ADR. The rejected alternatives in §7 are rejected *with reasons*; if
> one is reopened, the reason is what has to be argued with.
>
> **§8 was answered, and answered smaller than it asked.** ADR-190 splits
> `M4-T05` and moves **about a week** of §5 into `M4·A` as `M4-T20` — the region
> grammar, the Waystone mark, the party frames, the overlap check, plus the
> two-ground palette and the `Theme` on cost asymmetry. The Lair layout, the
> rest of the vocabulary, Layer 2 and the doors stay in `M4-T05`.
>
> **The correction is worth reading before §8 is:** §8 argued from two late
> gates and missed that the *earliest* gate — the stranger session — needs two
> depth tasks and **zero interface work**. It was written by the party that
> benefits from the change, and it over-claimed by roughly three to one. §8 is
> kept unedited as the argument that was made; ADR-190 is what was decided.

## 0. Why this document exists

`DES-019` is `accepted` and specifies six layers of interface. **Three of them
have never been built**, two of the built ones are a single `Label` each, and
nothing anywhere in the project asserts that two pieces of interface do not
land on the same pixels.

That asymmetry is the task. `DES-019` says *what* the interface tells the
player and *where* each thing lives; it does not say how an element claims a
region, how a vocabulary is shared, or how any of it is checked. `TEC-007`
stands in exactly this relationship to `DES-015` — a design document that
adopted a technique and stopped — and this follows its shape.

**Everything in §1 is measured on `fd54dd1`, not remembered.** The pixel
extents below are read off screenshots rather than estimated, because *the
readout is too big* and *the readout looks fine to me* are different claims and
only one of them survives being written down. To reproduce them:

```bash
# Windowed, NOT headless — see the note at the end of §5.6
/Applications/Godot.app/Contents/MacOS/Godot --path game \
    levels/lair/chamber.tscn -- --chamber-shot=/tmp/chamber.png
/Applications/Godot.app/Contents/MacOS/Godot --path game \
    levels/lair/threshold.tscn -- --threshold-shot=/tmp/threshold.png
```

The bounding boxes are of pixels above `(170, 168, 160)` — the bone-white the
readouts are drawn in (`chamber.gd:586`), and nothing else in either scene is
that bright.

---

## 1. What is actually on screen

### 1.1 The two hub screens are one `Label` each

`chamber.gd:581` builds a `Label` at `(18, 18)`. `chamber.gd:455` fills it
every frame with a fifteen-line joined string carrying the descent number, what
you carry, the stash, the hoard, the Tithe, three lines of drag-and-drop
instruction, her refusal, the offer, and how to leave. `threshold.gd:1223` does
the same at the same coordinates with fourteen lines.

Measured on a 1152×648 viewport, bone-white text pixels only:

| | Bounding box | Share of screen |
|---|---|---|
| **Chamber readout** | x 19–596, y 24–481 | **50% of width, 71% of height** |
| **Threshold readout** | x 19–676, y 24–427 | **57% of width, 62% of height** |

Half the screen, unframed, left-aligned, drawn over the room. In the Chamber it
crosses the hoard — the one object in the room you can interact with, and the
one `DES-014` calls a *"permanent physical monument."*

Two of the Threshold's lines are not composed but **appended**:
`threshold.gd:955` adds *"you have sworn to nothing"* and `threshold.gd:1048`
adds *"still at the fire"* with `+=`. The block's height is therefore a
function of game state and nothing bounds it.

### 1.2 Three of `DES-019`'s six layers do not exist

`room_set.gd:3693` builds the whole in-run HUD. It is five children:
`WoundVignette`, `Ear`, `Reticle`, `FallenReadout`, and — outside a probe —
`ArrivalBrief`.

| `DES-019` layer | State |
|---|---|
| **0 — the world tells you** | Partial. Vignette, gait, breathing. |
| **1 — the Ear** (top right) | **Built to the design** (`M2-T03`, ADR-090). |
| **2 — Body** (bottom left) | **Absent.** No health, no stamina, no wound readout. |
| **3 — Burden** (bottom right) | **Absent.** No weight, **no Waystone indicator.** |
| **4 — Party** (left edge) | **Absent.** `FallenReadout` binds to `local_player` only (`fallen_readout.gd:66`). |
| **5 — Contextual** | Built. `Reticle`, `ArrivalBrief`. |

This is not an oversight; it is scheduled. `wound_vignette.gd:26` says so in as
many words — *"`DES-019`'s real Burden layer is `M4-T05` and building a
provisional one here would be the parallel path ADR-064 bans."* That was the
right call at the time. §8 argues the schedule is now wrong, and these two
rows are why:

**Layer 3's Waystone mark.** `DES-019` calls it binary and *"answerable in a
glance"*, and ADR-186 raised it to **the sharpest mark on the HUD**, because
the Shaft now leads *down* and a Waystone is the only extraction above the
bottom floor. Today the only way to answer *do I have a way out* is to open the
bag — and `DES-019` designs the bag so that opening it is a vulnerable act.
**The game currently charges the player safety to answer a binary question the
design says must be free.** That is a `DES-019` rule failing against a
`DES-019` rule, and it is one mark on screen.

**Layer 4's party frames.** `GATE M4 COOP` sits in **`M4·A`** and asks whether
a repeatedly-downed newcomer still wants to go again. In a party today you
cannot see whether a teammate is up, down, or a Vörðr unless you can see their
body. The readout that answers it is `DES-019` Layer 4, scheduled in
**`M4·B`**. *An `M4·A` gate depends on a layer sequenced after it.* This is
ADR-165's own argument — a gate that cannot be asked on the build it gates —
arriving one milestone later.

### 1.3 Six margins, six z-layers, no register

Every screen sets its own inset, as a literal, at its own call site:

| Value | Where |
|---|---|
| `18` | `chamber.gd:585`, `threshold.gd:1224` |
| `40` | `pact_screen.gd:31` |
| `48` | `class_screen.gd:39`, `legacy_screen.gd:34`, `run_over_screen.gd:31` |
| `64` | `deeds_banner.gd:27` |
| `22` | `ear.gd:71` |
| centred | `bag_screen.gd` |

`CanvasLayer.layer` is the same story — `0` (implicit, `chamber.gd:582` and
`threshold.gd:1221`), `5`, `6`, `7`, `8`, `30`, each assigned as a literal at a
different site. **There is no register.** The two hub readouts sit on layer 0,
*beneath* everything, which is why the fix for a collision has repeatedly
looked like nudging a number.

It is not a z-order bug. **Nothing owns a region of the screen**, so any two
elements that happen to want the same corner get it, and the only thing
standing between the player and a collision is that nobody has yet written a
string long enough.

### 1.4 The vocabulary is four widgets deep

`menu_style.gd` gives six colours (`INK PANEL EDGE TEXT DIM WARM`) and six
constructors (`title / line / button / field / backdrop / column`). Forty-eight
call sites use it. It is a good foundation and it is a very small one: there is
no panel, no rule, no region header, no key-value row, no state mark. That is
why every screen is a centred column of sentences — **the vocabulary can only
say "list."**

Five elements bypass it entirely and draw themselves (`bag_screen`, `ear`,
`fallen_readout`, `reticle`, `wound_vignette`), and seven `Label`s are built
raw (`deeds_banner` ×3, `legacy_screen` ×2, the two hub readouts).

### 1.5 Found while measuring

Small, real, and none of them visible to any existing check:

- **`chamber.gd:537` renders literal asterisks.** The offer line reads *"%d
  more tribute \*above\* the tithe buys the first"* — Markdown emphasis in a
  `Label`, which draws it as punctuation. Visible in `chamber.png`.
- **The Chamber's readout layer has no `layer` value**, so it is 0 and sits
  under the reticle, the deeds banner and the Aspects tree.
- **`deeds_banner.gd` dims rather than covers.** Its backdrop is `INK` at 0.86
  over a colour already 0.94 opaque, so the fifteen-line readout beneath it
  stays legible through the banner that is supposed to be the whole screen.
- **A one-cell item is four characters and a colour.** `bag_screen` clips
  names to the footprint by design (ADR-140), so the Waystone — the most
  consequential object in the game — renders as `Ways`. The full name is drawn
  in the blurb on hover, which means identification already lives there and the
  cell text is doing almost nothing. `DES-018` forbids information in hue
  alone, and colour is currently carrying more of this than the text is.
- **The bag panel is centred**, which reads against `DES-019` rule 1 and is
  *correct anyway*: rule 1 governs the always-on HUD, and Fitts's law wants the
  grid under the cursor that starts at its centre (`bag_screen.gd:174`). Noted
  so nobody later "fixes" it.

---

## 2. The four complaints, restated as faults

The report was four sentences. Measured, they are four different faults with
four different fixes, and conflating them is how this becomes a restyling pass.

| Reported | Actual fault | Kind |
|---|---|---|
| *"Everything but the Ear is plain text"* | The vocabulary can only express a list (§1.4) | Missing structure |
| *"Overlapping text in the threshold/hoard"* | Nothing owns a region; five z-literals, six margins (§1.3) | Missing structure |
| *"Not apparent how to get into skill and character menus"* | The Aspects have no presence at range; **there is no character sheet at all** | Missing door |
| *"The inventory/character menu is basic"* | Blockout art, as scheduled — and three layers that do not exist (§1.2) | Partly scheduled, partly missing |

**Only the third and fourth rows contain anything the player would call
missing content.** The first two are one fault wearing two hats.

---

## 3. The survey

Per `CLAUDE.md`: a shipped game, why it worked there, and whether our context
differs.

### 3.1 The door to a progression tree

**Hades — the Mirror of Night.** The best-solved version of our exact problem.
It works for three reasons, and only one of them is about UI: it is *in the
critical path* (the bedroom is the first room of every run), it is *the only
lit interactive object in that room*, and *the character comments on it*. No
menu, no button, no tutorial.

**Our context is already right structurally and wrong optically.** `DES-003`
couples the Aspects to the Tithe, so buying them at the pile is correct and a
menu button would convert a pact into a shop. The pile is also unavoidably in
the path — you go to the Chamber to tribute. What is missing is Hades' second
reason: **the pile does not read as interactive from across the room.** ADR-164
added a reticle prompt inside `PLACE_REACH`, which helps the player who is
already standing there and not the player who never walks over.

**Dark Souls / Elden Ring — the bonfire.** The same answer from a game where
you cannot see your own character's face: a unique light, a unique sound, a
unique idle animation. First-person-compatible, and it confirms the fix is
*presence*, not *prompt*.

**Path of Exile / Last Epoch / Diablo — a tab, one key away.** Recognition over
recall in its purest form. **Rejected for buying**, for the coupling reason
above. **Not rejected for reading**: there is no design argument anywhere that
a player may not *look at* the tree they already own, and today they cannot.

### 3.2 Inventory as weight

**RE4 — the attaché case.** Already `DES-019`'s and ADR-087's reference, and
already built at 6×5. The thing RE4 does that we do not is that its cells hold
**pictures of objects**, so the grid reads as a bag rather than as a table.
That is an asset problem, not a layout one — it belongs to the art pass, and
saying so here keeps us from trying to solve it with layout.

**Hunt: Showdown.** The better reference for the *slot* row: a small silhouette
with worn equipment, not a spreadsheet. Our slot row is six labelled empty
squares 100 px below the grid — the most-travelled drag in the screen, and by
Fitts's law the most expensive.

**Tarkov.** Spatial anxiety, which we want. `DES-002` rejects its
*player-driven loot anxiety*, which is a different thing and not at stake in
the layout.

**Diablo II.** Where the "inventory Tetris" reading comes from, and its failure
mode is inventory-management-as-chore. `DES-019` already avoids it structurally
by making space the **gate** and weight the **price** (ADR-087) — worth naming
so no layout decision quietly reintroduces optimisation as a pastime.

### 3.3 A committed visual language on no budget

**Return of the Obra Dinn.** 1-bit dither, and — the part usually missed — its
interface is **typographic**: a book, chapter rules, a crew list, one typeface,
absolute commitment. It works because the UI is a diegetic printed object and
because it never breaks its own rule.

That is directly transferable. **A woodcut's native interface vocabulary is the
printed page**: rules, plates, marginalia, a heavy border, generous gutters.
Every one of those is one or two draw calls. `ART-005` has already chosen this
register for the world; the interface is not currently speaking it.

**Darkest Dungeon.** The frame *is* the art, and it stays legible with dozens
of simultaneous states because a heavy border says *this is interface, the rest
is world*. The cost is 9-slice ornament assets — a real art budget. We can take
about 70% of the benefit with a hairline rule and one border weight, which is
`MenuStyle` work rather than asset work.

**Inscryption.** Diegetic-adjacent, everything is objects on a table.
**Rejected**: we are first-person with a lantern and there is no table.

### 3.4 Diegetic UI, and when it stops paying

This is the family most often reached for when a stylised game wants a
distinctive interface, and it is the one to read most skeptically.

**Dead Space.** The spine bar and the holographic inventory. It works because
the camera is over the shoulder and the character *wears* the readout — and it
costs an animation rig per readout. Two specifics matter to us:

- **We are first-person.** Nothing worn on the body is visible. The single best
  trick in this family is unavailable to us.
- **Dead Space's inventory does not pause, and it is the game's weakest UI
  moment** — widely reported as the place where immersion and legibility
  collide. `DES-019` gives our bag the same rule deliberately. That is a direct
  warning: **the no-pause bag is the screen most in need of legibility, not
  least.**

**Death Stranding.** The cargo stack on your back *is* the weight readout —
`DES-019` Layer 0, executed perfectly. Third-person only. Same conclusion.

**The honest reading: `DES-019` rule 6 already says "diegetic where free."** In
first person, very little is free. The pile's light in §3.1 is one of the few
places it genuinely is.

### 3.5 Many simultaneous states, staying legible

**Caves of Qud.** A fixed status row of short mark-and-word pairs, each of
which is simply **absent when it does not apply**. Cheap, monochrome-safe, and
it scales to many states without growing — which is exactly the shape Layers 2
and 3 need, and exactly the opposite of a fifteen-line block that is always the
same size.

**Dwarf Fortress Adventure mode.** The counter-example, and the useful one:
everything is text, everything is one column, and the reader parses a wall.
**That is precisely the state the Chamber readout is in today.**

**Barony.** Already rejected by `DES-019` as the minimap counter-example. It
stays rejected.

---

## 4. The heuristics, named, and what each indicts

Saying which principle is being applied to what, per the brief.

| Principle | Indicts |
|---|---|
| **Nielsen #1 — visibility of system status** | The missing Waystone mark. The most consequential state in a run is answerable only by becoming vulnerable (§1.2). |
| **Nielsen #4 — consistency and standards** | Six margins, six z-literals, five self-drawing elements, seven raw `Label`s (§1.3, §1.4). |
| **Nielsen #6 — recognition over recall** | The Aspects' door, and the absent character sheet. Mid-run a player cannot see their class, their Aspects, their rank or their deeds. |
| **Nielsen #8 — aesthetic and minimalist design** | Fifteen lines where `DES-019`'s thesis is *show the fewest things*. Every extra line dilutes the ones that matter. |
| **Fitts's law** (t ∝ log₂(2D/W)) | The bag's grid → slot drag: 44 px source, 52 px target, ~120 px apart, and it is the most frequent movement in the screen. Also the one thing already right — *drop* is "anywhere outside the panel", an effectively infinite target. |
| **Gestalt — proximity vs. common region** | The Chamber's four content groups (state, obligation, instruction, speech) are separated by blank lines alone. Proximity is the weakest grouping cue available; common region is the strongest and costs one `draw_rect`. |
| **Hick's law** | Not an objection to a sixth pause-menu entry. Five → six is negligible, and it buys the missing door. |
| **Sweller (1988), via `PRO-005` §8** | The argument for §5.2's deletions: interacting elements are the most expensive thing to learn, and three lines of permanent drag-and-drop instruction are a tutorial that never turns off. |

---

## 5. Recommendation

Five parts, ordered so each one makes the next cheaper. **The first is the
whole argument**; without it the rest is restyling.

### 5.1 A region grammar — `HudFrame`

`DES-019` already names the regions: top-right, bottom-left, bottom-right, left
edge, contextual, **and the centre is forbidden**. That is a layout
specification and it currently exists only as prose.

Make it code. A `HudFrame` `Control` owns the viewport and hands out region
rects; every HUD element declares **which region it lives in** instead of a
position and a magic number. Z-order becomes a named constant per region rather
than a literal per call site.

**Not an autoload.** Autoloads are a budget of six and all six are spoken for
(`CLAUDE.md` §4). `HudFrame` is a `Control` the level builds, exactly as
`Reticle` and `Ear` already are.

`Ear` is the working prototype of this and should be read as the pattern: it
declares a corner and a margin, sizes itself from `get_viewport_rect()` rather
than from `size` (`ear.gd:129` — and the comment explains why), and publishes
a `RENDERED` list that a probe checks **in both directions**. Generalise all
three habits.

The payoff is not tidiness. It is that **§5.6's check becomes writable**, and
today it is not.

### 5.2 The Lair stops being a `Label`

The Chamber's fifteen lines are doing four unrelated jobs. Most of them should
not be text at all — and the first move is subtraction, not framing.

| Line | Verdict |
|---|---|
| `the hoard 2400 (never wiped)` | **Delete.** `DES-014` makes the pile a physical monument and it is rendered as one — 96 lumps at the shot's seeded 2400, three metres in front of you. A number for a thing you can see is a number that teaches the player not to look. |
| `carrying 0 item(s), 0 tribute` | **Delete.** It duplicates the bag, which is one key away and is where the arithmetic belongs (`DES-019` rule 2's exception). |
| Three drag-and-drop instruction lines | **Move to Layer 5.** These are contextual prompts that belong at the pile and at the chest, on the `Reticle` that already exists, already names both devices (ADR-075), and already appears-then-leaves. A permanent tutorial is the `PRO-005` §8 cost paid every run forever. |
| **The Tithe** | **Keep, and give it a region.** ADR-029 requires cycle position be *unmissable*; today it is line seven of fifteen. |
| **Her refusal, and the offer** | **Keep as speech.** Transient, its own region, and the only thing in the room with a voice. It is currently held as a blank line so nothing below it moves (`chamber.gd:471`) — which is a layout workaround for having no layout. |
| `descent %d`, `stash` | **Keep, small.** Genuine persistent state with nowhere else to live. |

Fifteen lines become two regions and a prompt. **That is a `DES-019`-shaped
answer and it is cheaper than restyling fifteen lines.** The Threshold gets the
same treatment; its control list is already generated from `InputMap`
(ADR-139) and belongs behind the same door as the character sheet, not printed
on the wall of the camp.

### 5.3 The doors

Two different problems, two different fixes.

**In the Lair — the pile needs presence, not a prompt.** Hades' second reason
(§3.1). The pile should read as interactive from the doorway: a light and a
silhouette. `ART-005` already rules that *gold light is what it will cost you*
and *pale light is the way through* — the pile is the gold, so it needs the
mark that reads at range rather than more warmth. This is a lighting change as
much as a UI one, and it is small.

**Mid-run — there is no character sheet, and `DES-019` does not want one on
screen.** The resolution is that the pause menu already exists, already has
five entries, and is where a player looks. A sixth entry — *who you are* —
composing screens that already exist (`ClassScreen`, `PactScreen` read-only,
deeds) puts nothing on screen during play and costs one button.

**This is a door, not a system.** No new screen is invented; three existing
ones get a second way in. Which matters for ADR-064: nothing here is a stub,
because nothing here is new.

### 5.4 The missing layers, at blockout fidelity

Layers 2, 3 and 4, built the way Caves of Qud builds a status row: **marks that
are absent when they have nothing to say**, carried by shape and fill so they
survive monochrome (`DES-018`), no numbers (`DES-019` rule 2), nothing that
grows (rule 5 — only the Ear may).

Priority order, by what is blocked:

1. **Layer 3's Waystone mark** — §1.2, and one mark on screen.
2. **Layer 4's party frames** — `GATE M4 COOP` depends on it (§8).
3. **Layer 3's weight** — `GATE M4 GREED` is a decision made against weight.
4. **Layer 2's body** — the vignette carries wound direction and severity today
   and would keep doing so; this adds stamina, which nothing carries.

### 5.5 The vocabulary, and the `ART-005` trap

`MenuStyle` needs five more constructors — `panel`, `rule`, `region header`,
`key-value row`, `state mark` — which is the printed-page register from §3.3
and is roughly a hundred lines.

**But there is a trap in it, and it is worth more than the vocabulary.**

`MenuStyle`'s colours are absolute: `INK` is `Color(0.07, 0.065, 0.06)`, near
black, and `TEXT` is bone. `ART-005` §"Two worlds, two treatments" specifies
that the Threshold and Chamber are **white ground, hard black ink, fully
drawn**, and the Deep is the inverse. When `M4-T08` lands, **every Lair screen
becomes a black panel on a white world** — the hub wearing the Deep's
interface, at maximum contrast in the wrong direction.

The fix is one rule and it is nearly free *now* and a seventeen-screen
migration *later*:

> **Ink is the opposite of the ground, and the ground flips at the Descent.**

Two palettes and one switch, defined once. This is the single most expensive
thing in this document to retrofit and the cheapest to build in.

**Related, and the reason to do the vocabulary as a Godot `Theme` rather than
as more static functions:** `M4-T11` is colour-blind support, **UI scaling**, a
dyslexia-friendly font and high contrast. Every one of those is a global swap
of a font, a size or a palette. Today font sizes are `add_theme_font_size_
override` calls scattered across seventeen files, which makes `M4-T11` a
seventeen-file edit instead of a resource swap. A `Theme` is also what
`CLAUDE.md` §4's *data over code* asks for. **This is the constraint the brief
names — do not build something that makes `M4-T11` impossible — and it is
currently being built.**

### 5.6 The check that does not exist — and the one that already half-exists

Ten UI probes run in the sweep. **Not one of them asserts that two pieces of
interface do not overlap**, which is the reported bug, and it is invisible to
every existing check because probes read a label's `text` — proving the string
exists, never that a human can see it.

**This has already been reported from play once.** ADR-140: *"the UI is showing
some text on top of others in the inventory."* The blurb's third wrapped line
landed inside the footer and drew *"make one and regret continuously."* straight
through *"lmb/X take & place"*. Every existing row was green, because
`overflowing()` measured **widths** and *"never asked whether a block fits its
height."*

`BagScreen.overflowing()` is the right idea, and it is the only layout question
anything in this project asks. It is also hardcoded to one screen, band by
band, and it was written after the collision rather than before it. **§5.6 is
that function given a home**, which is what §5.1 buys: with regions declared
rather than positioned, the same question can be asked of every element at once
instead of re-derived per screen after each report.

With §5.1 in place the check is small and it is a real one:

- Every registered element's rect lies **inside its declared region**.
- **No two regions intersect**, and none of them touches the centre (rule 1).
- The Chamber and Threshold readouts fit their regions **at their longest
  state** — including the appended lines at `threshold.gd:955` and `:1048`,
  which is the growth nothing currently bounds.
- Photograph it. `--bag-shot` (ADR-087), `--ear-shot` (ADR-090) and
  `--ember-shot` (ADR-093) have each caught what a headless check could not,
  and ADR-093 made the pattern explicit: *anything whose correctness is a claim
  about seeing gets photographed.* Two overlaps are a claim about seeing.

**A note for whoever writes it:** the existing probes were written against the
current structure, and a probe rewritten to match new code asserts nothing.
Each one that changes gets a plant.

**And a note about the harness itself, because it is not written down
anywhere:** these shots do **not** run headless. `_draw` never executes in a
headless process — which is the whole reason `--ear-shot` exists (ADR-090) — so
`--headless` hangs forever waiting on `RenderingServer.frame_post_draw` rather
than failing. The correct form is windowed:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path game \
    levels/lair/chamber.tscn -- --chamber-shot=/tmp/chamber.png
```

---

## 6. Cost

Per `CLAUDE.md`: *trivial / a weekend / a month / this is a whole system.*

| | Cost |
|---|---|
| §5.1 `HudFrame` region grammar | **a weekend** |
| §5.2 The Lair layout (mostly deletion) | **a weekend** |
| §5.3 The doors (pile light + pause entry) | **a weekend** |
| §5.4 Layers 2/3/4 at blockout fidelity | **a weekend each for 3 and 4; a few days for 2** |
| §5.5 `Theme` + the two-ground palette | **a weekend**, and it is what makes `M4-T11` a resource swap |
| §5.6 The overlap check and its plants | **a few days** |
| — | |
| **The structure half, total** | **≈2–3 weeks** |
| **The art pass** (icons, ornaments, typography, RE4-style item art) | **a month or more — this stays `M4-T05` and is not in scope** |

---

## 7. Rejected alternatives

**Restyle in place.** Give `MenuStyle` nicer boxes and wrap the existing labels
in them. **Rejected**: it produces a *framed* fifteen-line block. The argument
for doing layout before art applies with more force to frames than to art —
real assets dropped onto a bad layout make the layout permanent, and a nice
border makes it permanent sooner and for less.

**One unified character screen** replacing `class` / `pact` / `legacy` / `bag`.
**Rejected**: `DES-020` puts the slots inside the bag deliberately, because
*"is this worth carrying or worth wearing"* is one question and splitting it
would make it two; `DES-003` couples the tree to the hoard. Merging breaks both
couplings to fix a problem that is actually about doors. **We need one way in,
not one screen.**

**Fully diegetic Lair interface** — the Tithe carved on the wall, the hoard's
value as pile size alone, no readout at all. Tempting, very `ART-005`, and
**rejected as a whole**: ADR-029 requires cycle position to be *unmissable*,
and a diegetic-only cycle counter is a legibility gamble taken at precisely the
moment the design forbids gambling. **Partially adopted** in §5.2 — the hoard's
number goes, because the pile genuinely is the readout.

**A `Hud` autoload.** **Rejected**: the budget is six and six are named
(`CLAUDE.md` §4). Nothing here needs process-wide lifetime.

**Nudging the `CanvasLayer` numbers.** **Rejected on the measurement**: five
literals at five sites with no register is not an ordering problem, and
renumbering them leaves the next collision exactly as likely.

**Keeping `MenuStyle` as static constructors and adding to it.** **Rejected
narrowly** — it is the cheaper move today and it makes `M4-T11` a
seventeen-file edit (§5.5). The `Theme` is the same work aimed somewhere
useful.

---

## 8. What this obliges the roadmap to do

`M4-T05` is *"Real art pass, real audio, real UI, ping system"* and sits in
**`M4·B`** — the half ADR-165 sequenced *after* depth so that presentation is
not polished onto systems that might still change.

**Proposal: split `M4-T05`, and move the structure half to `M4·A`.**

- `M4-T05` **Real art pass, real audio, ping system** — stays in `M4·B`.
- `M4-T20` **The interface has a structure** — §5.1–5.6, into `M4·A`.

### Why this serves ADR-165 rather than undermining it

ADR-165's argument is precise, and it is worth quoting against itself: *"the
art pass, the shader, the composer and the accessibility suite would have been
applied to a game with one enemy behaviour and six grey rooms."* **Every noun
in that sentence is an asset.** What §5 proposes is not presentation; it is the
sockets presentation plugs into. `DES-009`'s blockout ordering — *it has to be
good before it is pretty* — is the same argument, and ADR-046 already names
blockout as a production phase rather than a stub.

The stronger argument is ADR-165's own test, applied again:

> **A gate that cannot be asked on the build it gates belongs somewhere else.**

That is how the `M3` gates moved. It now indicts the current sequencing twice:

- **`GATE M4 COOP` is in `M4·A`** and asks whether a repeatedly-downed newcomer
  still wants to go again. They cannot currently see whether *anyone* is coming
  for them, because Layer 4 does not exist and `FallenReadout` binds to
  `local_player` (§1.2). The gate would return an answer about a missing
  readout.
- **`GATE M4 GREED`** — *"a playtester voluntarily abandons loot to survive"* —
  is a decision made against **weight** and **whether you still have a way
  out**, and neither is on screen. ADR-186 made the second one sharper, not
  softer.

**This is not a request to start `M4·B` early.** It is the observation that
three `DES-019` layers are load-bearing for `M4·A` gates and are filed behind
them. `M4-T20` contains no art, no icons, no typography and no audio; those
stay in `M4-T05` where ADR-165 put them.

**If the answer is no, the work waits** — but then `GATE M4 COOP` should be
annotated with what it cannot currently ask, so nobody runs it and writes the
result down against the ember rescue.

---

## 9. Open questions

> **OPEN (§5.2):** Does the Chamber keep a persistent Tithe readout, or does
> the Tithe become part of the hoard itself — a line on the pile that rises?
> Leaning **persistent**, because ADR-029 says *unmissable* and a diegetic
> gauge is exactly the gamble §7 rejects. A prototype question, not a debate.

> **OPEN (§5.4):** Does Layer 2 carry stamina at all, or is stamina wholly
> Layer 0 (breathing, camera settle)? `DES-019` lists it explicitly, but it is
> the one body state the world already narrates well. Leaning **a mark that
> appears only when you are near empty** — Qud's rule, and it keeps the resting
> HUD smaller.

> **OPEN (§5.5):** Does the two-ground palette flip at the Descent only, or
> does any lit space in the Deep flip locally? Leaning **Descent only** —
> ADR-167 chose a hard cut for the world on the argument that a gradient makes
> the moment of commitment unlocatable, and an interface that flips per room is
> three interfaces.

> **DEFERRED to `M4-T11`:** everything about scaling, dyslexia font and high
> contrast. §5.5 exists so that task is a resource swap; it does not do that
> task.
