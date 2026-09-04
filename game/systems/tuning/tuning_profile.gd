class_name TuningProfile
extends Resource

## Every tunable number in the project, in one designer-facing Resource.
##
## TEC-001: "every tunable number lives in a resource file, not in code.
## Balance iteration on a game like this happens hundreds of times, and
## recompiling logic to change a timer is how projects stall."
##
## One profile with @export_group sections rather than a profile per system:
## the doc names a single `TuningProfile`, and splitting it before there is any
## pain from its size would be inventing structure ahead of need. Groups keep
## the inspector legible (TEC-002).
##
## Every value here is ⟨tune⟩ by definition. None is settled, and none should
## be treated as settled because it appears in a committed file.

@export_group("Movement")
## Metres per second on flat ground, unencumbered.
@export var walk_speed: float = 3.4
@export var sprint_speed: float = 6.2
@export var crouch_speed: float = 1.6
## How hard the controller pulls toward its target velocity. High values feel
## snappy and arcade; low values feel like mass. DES-009 wants "grounded and
## physical", which lives in this number more than in any other.
@export var ground_acceleration: float = 11.0
@export var ground_friction: float = 14.0
## Air control is deliberately poor: no parkour, no wall-running (DES-009).
@export var air_acceleration: float = 1.8
@export var jump_velocity: float = 4.2
@export var gravity: float = 18.0

@export_group("Body")
@export var stand_height: float = 1.8
@export var crouch_height: float = 1.15
@export var body_radius: float = 0.35
## Eye sits below the top of the capsule, not at it.
@export var eye_drop: float = 0.18
## Seconds to move between standing and crouched. Instant reads as a teleport.
@export var crouch_time: float = 0.14

@export_group("Look")
@export var mouse_sensitivity: float = 0.0022
@export var pitch_limit_degrees: float = 88.0
## Radians per second at full stick deflection. A stick reports *displacement*,
## not motion, so look is rate-based rather than scaled per-event like a mouse
## (ADR-075).
@export var stick_look_rate: float = 3.0
## Response exponent. 1.0 is linear and precise nowhere; above 1 compresses
## small deflections for fine aim while leaving full deflection at full rate.
@export var stick_look_curve: float = 2.0
@export var field_of_view: float = 75.0

@export_group("Stamina")
@export var stamina_max: float = 100.0
@export var sprint_drain: float = 17.0
@export var stamina_regen: float = 14.0
## Seconds after spending before regeneration begins. Without a delay, sprint
## becomes free in short bursts and stops being a resource at all.
@export var stamina_regen_delay: float = 0.9
## You cannot start a sprint below this, which stops one-step sprint stutter.
@export var sprint_minimum: float = 12.0

@export_group("Weight")
## Kilograms at which encumbrance reaches 1.0. DES-005: weight is the player's
## own greed made physical, so this is the ceiling on how rich you can get
## before the game starts taking it out of your legs.
@export var carry_capacity: float = 40.0
## Multipliers applied at full encumbrance; interpolated from 1.0 at empty.
## DES-009: "Weight is felt everywhere: acceleration, top speed, jump height,
## mantle ability, stamina, footstep volume. One number the player can feel."
@export var speed_at_capacity: float = 0.55
@export var acceleration_at_capacity: float = 0.5
@export var jump_at_capacity: float = 0.6
@export var stamina_drain_at_capacity: float = 2.2

@export_group("Vitals")
@export var player_health: float = 100.0

@export_group("Blocking")
## Fraction of a blow a raised guard stops ⟨tune⟩ (`M3-T02`, `DES-009`).
##
## **Never 1.0, and `validate()` refuses it.** `DES-009` is explicit: block
## *"costs stamina, reduces damage, doesn't negate it"* — and the reason is the
## same one that rules out i-frames and dodge-rolls. A guard that makes you
## invulnerable turns every fight into a holding contest and deletes the
## positional defence the whole combat model is built on.
@export var block_damage_fraction: float = 0.6
## Stamina a blocked blow costs ⟨tune⟩. Blocking is a *resource*, not a stance:
## `DES-009` puts swinging, blocking, sprinting and climbing on one pool, so a
## Húskarl who blocks everything cannot also run.
@export var block_stamina_cost: float = 22.0
## Below this you cannot raise a guard at all ⟨tune⟩ — the same rule
## `sprint_minimum` applies to sprinting, and for the same reason: a guard that
## flickers on and off at zero stamina is unreadable to the person relying on it.
@export var block_stamina_minimum: float = 10.0
## Top speed multiplier with a guard up ⟨tune⟩. Slow, not rooted — `DES-009`
## makes movement the primary defence, and a block that stopped you moving
## would be asking you to give up the better one.
@export var block_speed_multiplier: float = 0.55

@export_group("Hold")
## Stamina per second while planted ⟨tune⟩ (`M3-T02`, `DES-011`). Per *second*
## rather than per blow, unlike a block: `DES-011` gives every unique verb a
## real cost, and Hold's is that it is a decision to stop — a clock running
## while you are the only thing in a doorway, whether or not anything comes.
@export var hold_stamina_drain: float = 16.0
## Seconds from pressing to being planted ⟨tune⟩. Long enough to be a
## commitment rather than a reflex (principle 3), and it obeys ADR-053's 250 ms
## floor for the same reason an attack does — an ally has to be able to read it.
@export var hold_plant_seconds: float = 0.3

## Seconds to set a Snare ⟨tune⟩ — the Veiðimaðr's verb (`M3-T11`, `DES-011`).
## Longer than a plant on purpose: the Húskarl decides to stop *here, now*, and
## the Stalker decides where the fight will be a while before it happens.
@export var snare_place_seconds: float = 0.9
## Stamina to set one ⟨tune⟩. `DES-011` rule 3: every unique verb has a real
## cost. Flat rather than drained per second, because the cost is the placing
## and the trap then costs nothing to leave lying there.
@export var snare_stamina_cost: float = 25.0
## Seconds whatever steps in it is held ⟨tune⟩. The number `DES-011` is really
## about — *"the only reliable way to buy time during the Sealing"* — so it is
## measured against a Shaft's closing rather than against a fight.
@export var snare_hold_seconds: float = 3.5
## Clamor deposited **at the trap** when it fires ⟨tune⟩. Above a footstep and
## below a weapon hit: the Stalker's one loud act, and it is loud somewhere they
## are not.
@export var snare_clamor_trigger: float = 2.6

@export_group("Inventory")
## Cells wide and tall (`DES-019`). **`DES-020` gives this to the Pack slot** —
## bigger pack, more grid, more weight, more Clamor — and slots arrive at
## `M3-T07`, at which point the Pack supplies it and this becomes the *no pack*
## grid Q106 already requires. One home now, one home later, never two.
##
## 6x5 is RE4's attaché case, which `DES-019` names as the gold standard, and
## it is the size at which the two constraints actually disagree across the
## authored corpus: a bag of gear runs out of squares at 25/30 cells and 24 kg,
## a bag of glitter runs out of kilograms at 40 kg well short of 30 cells.
## Tighter (4x5) and both bind on space; looser (8x6) and both bind on weight.
## `--bag-probe` measures this rather than trusting it.
@export var inventory_grid: Vector2i = Vector2i(6, 5)
## Seconds to get the bag open or shut. `DES-019`: *"you kneel, you rummage,
## and the floor keeps happening"* — the cost has to be time you can be caught
## in, not a keystroke.
@export var bag_open_time: float = 0.35
## Top speed multiplier while the bag is open. Opening your bag is a vulnerable
## act by design, not by accident (`DES-019`).
@export var bag_speed_multiplier: float = 0.45

@export_group("The Hunt")
## `TEC-001`'s decaying scalar field (`M2-T02`). Ceiling per cell, so one very
## loud event cannot flatten the whole gradient into a plateau the Hunter
## cannot climb.
@export var clamor_field_maximum: float = 24.0
## Fraction of a cell's level handed to its open neighbours each tick. Higher
## spreads noise further and faster and blurs the direction it came from —
## which is the trade: a field that spreads too eagerly tells the Hunter a
## room was loud, not which corner of it.
@export var clamor_field_spread: float = 0.22
## Units lost per second. Sets how long the Hunter can follow a cold trail, and
## with it how much a moment of quiet actually buys you.
@export var clamor_field_decay: float = 0.9
## Below this a cell is silence, not a whisper. Without a floor the Hunter
## chases rounding error forever and never returns to wandering.
@export var clamor_field_floor: float = 0.35

## Metres the Gullsjúkr feels carried wealth **through walls** (`DES-017`).
## *"A silent Veiðimaðr with a bag full of Dvergar regalia is a lantern to this
## thing."* Going quiet is not enough; you have to give something up.
@export var hunter_wealth_range: float = 26.0
## Tribute value that registers at all. Below it you are not worth crossing a
## room for, which is what makes a stripped-down run genuinely uninteresting to
## it rather than merely quieter.
## An `int` because `tribute_value` is one, and the two are compared directly.
## As a float it silently narrowed at every call site, including inside `maxi`.
@export var hunter_wealth_floor: int = 20
@export var hunter_walk_speed: float = 1.9
@export var hunter_pursue_speed: float = 3.1
## What escalation buys it, per minute on the floor ⟨tune⟩ — `DES-017`: *"it
## gets faster and reads you more accurately the longer you stay."*
@export var hunter_speed_per_minute: float = 0.28
@export var hunter_range_per_minute: float = 3.0
## Seconds it keeps coming after losing you. Long, on purpose: `DES-017` says
## it does not lose interest quickly, and a pursuer you can shake in two
## seconds is a patrol.
@export var hunter_patience: float = 9.0
## Seconds it spends stooped over thrown gold. **The player's window** — the
## whole value of a bait is measured in this number.
@export var hunter_collect_seconds: float = 4.5
## ADR-039: a bait must be worth this fraction of what you carry before it is
## more interesting than you are. **Proportional, not fixed** — a flat toll
## would be ruinous on floor one and pocket change by the time it matters.
@export var hunter_bait_fraction: float = 0.34
@export var hunter_reach: float = 2.0
## Seconds it stands over you, stooping, before it takes something ⟨tune⟩
## (`M2-T19`, ADR-112). **This is a telegraph and it obeys the 250 ms floor**
## ADR-053 puts under every attack: it is the window in which backing away, or
## throwing it something cheaper, still works. Long, because the answer to a
## Gullsjúkr is a decision rather than a reflex (principle 3).
@export var hunter_take_seconds: float = 0.9

@export_group("The Tithe")
## What she expects of you per cycle, indexed by Pact Rank (`DES-003`) ⟨tune⟩.
##
## **A table rather than a curve.** `DES-003` gives three anchors — rank 1 at
## 40, rank 5 at 260, rank 9 at 900 — and every value between them is a
## designer's judgement, not an equation's output. ADR-029 calls cycle length
## the primary tuning lever in the game, and `TEC-002`'s data-over-code rule
## bites hardest on the numbers that get changed most.
##
## It must never fall as rank rises: `validate()` refuses that, because a Tithe
## that got cheaper with power inverts the entire coupling `DES-003` is built
## on — the one that makes growth pull you toward danger instead of away.
@export var tithe_by_rank: PackedInt32Array = PackedInt32Array(
	[40, 85, 140, 200, 260, 380, 520, 700, 900])
## Runs you get to pay it in (ADR-029) ⟨tune⟩. Three absorbs one disaster run,
## so bad luck and experimentation do not default you.
@export var tithe_cycle_runs: int = 3

## **What a node costs, by tier** (`M3-T01`, ADR-060) ⟨tune⟩ — lesser 1,
## greater 2, keystone 5. Here rather than on `AspectNode` on purpose: a
## per-node price would let one lesser node quietly become worth three, which is
## `DES-004` rule 2's bigger-number pressure arriving through the cost instead
## of through the effect.
@export var node_cost_lesser: int = 1
@export var node_cost_greater: int = 2
@export var node_cost_keystone: int = 5

## **Boon spent per point of Pact Rank** ⟨tune⟩.
##
## `DES-003` makes rank Boon spent — *"every point of Boon spent raises your
## Tithe"* — and ADR-060 fixes the scale: *"~20 taken by Rank 9"*, which on a
## representative spread of tiers is about 31 Boon. Four per rank puts rank 9 at
## 32, so the whole table above is reachable by the life ADR-060 describes and
## no further.
@export var boon_per_rank: int = 4

## **Surplus tribute value per point of Boon** ⟨tune⟩.
##
## `DES-004`: tribute *below* your Tithe converts at nothing and counts against
## the obligation; only the surplus becomes Boon. ADR-060 wants roughly one node
## per two runs at a flat rate across ranks — the Tithe rising with every node
## is what does the throttling, so this number does not need to.
## **How much of your own Tithe converts at full rate each cycle** ⟨tune⟩
## (`M3-T03`, ADR-011). A fraction of the obligation rather than a second
## table: the number that says what she expects of you is the number that says
## how much of a floor you can turn into power, which is `DES-003`'s coupling
## stated once. Below 1.0 because a cycle that converts its whole obligation
## into Boon every cycle makes the debt self-financing.
## **How many things she remembers** ⟨tune⟩ (`M3-T05`, ADR-003, `DES-003`).
##
## Three, *"expanding very slowly — one at lineage milestones, capped at 5
## lifetime."* The expansion is `M4`'s; what matters here is that the number is
## small and fixed, because `DES-003`'s claim is that **power creep is bounded
## by design rather than by tuning**: three slots is three slots, and it cannot
## spiral however many lifetimes accrue.
## What a Wing channel costs against everyone else's ⟨tune⟩ (`M3-T12`).
## One number for both the Waystone and the Shaft, because *Windward* and
## *Swift Seal* are the same sentence pointed at the two ways off a floor, and
## two numbers would be two things to drift.
## **What a respec gives back** ⟨tune⟩ (`M3-T13`, `DES-004`).
##
## `DES-004`: *"a respec exists but costs real resources."* The resource is the
## Boon that does not come back — no new currency, no second economy, and the
## cost scales with how much of a build you are unmaking, which is the right
## shape: reconsidering one lesser node should not cost what abandoning a whole
## path does.
##
## Below 1.0 or a respec is free and the choice stops being one; above 0 or it
## is a delete rather than a reconsideration, and `validate()` refuses both.
@export var respec_refund: float = 0.6

@export var wing_channel_fraction: float = 0.55
## **Never Where She Struck** ⟨tune⟩ (`M3-T12`, `DES-004`): *"return to where
## you stood 3 seconds ago, once per floor."*
@export var recall_seconds: float = 3.0
## How often the trail is sampled. Coarse on purpose — the keystone returns you
## to *roughly* three seconds ago, and a per-frame history would be precision
## nobody can perceive.
@export var recall_step: float = 0.25
## What the ground you left costs you ⟨tune⟩. `DES-004`'s rule is that every
## keystone has a real drawback and the document names none for this one: it is
## the noise. You escaped the blow and told the floor which room the fight was
## in — the bow's *loud somewhere you are not* (`M3-T11`), aimed at yourself.
@export var recall_clamor: float = 9.0

@export var legacy_slot_count: int = 3
## What a Scarred item is worth against a fresh one ⟨tune⟩. `DES-003` says
## *"carried through death at reduced power"* — a head start, not a stockpile.
@export var scarred_power: float = 0.7

@export var boon_cap_fraction: float = 0.75

@export var boon_per_tribute: int = 60
## What missing a cycle costs: seconds of Hunt **already elapsed** when your
## next descent begins (ADR-118) ⟨tune⟩.
##
## ADR-029 named three consequences and every one of them belongs to a system
## that does not exist yet. This is the one that could be built out of what
## does — the Gullsjúkr's reach opens with `hunter_range_per_minute`, so a run
## that starts old starts hunted, with no new rule to learn and nothing added
## to the game. It is also `DES-022`'s own rank axis: *the Hunt arrives sooner.*
@export var tithe_missed_head_start: float = 240.0
## The rank at which a Gullsjúkr can be killed at all (`DES-017`) ⟨tune⟩ —
## *"at high Pact Rank it becomes killable. You get its entire hoard, which is
## enormous, and a deed."* Unreachable until `M3-T01` lets a rank rise, and the
## check runs on every hit regardless, so it answers rather than waits.
@export var gullsjukr_killable_rank: int = 8

@export_group("The floor's rank")
## Extra enemies per rank above 1, as a fraction of the base count ⟨tune⟩
## (`M3-T10`, ADR-010, `DES-022`). Density is the axis that needs no new
## content: the ring `ENEMY_POSTS` already grows for a party grows for a rank.
@export var rank_density_slope: float = 0.22
## Seconds of Hunt a floor has already had, per rank above 1 ⟨tune⟩.
##
## **One number, two of `DES-022`'s axes.** `Shaft._escalation` reads the
## Gullsjúkr's age rather than a clock of its own, so a floor whose Hunt starts
## older also seals its Shafts sooner — *arrives sooner* and *cheap exits vanish
## sooner*, from the same lever, with nothing to keep in step.
@export var rank_hunt_seconds: float = 20.0

@export_group("The party")
## Extra enemies per additional player, as a fraction of the base count ⟨tune⟩.
## Near-linear (`DES-012`) so combat stays meaningful with four swords in the
## room rather than becoming a formality.
@export var party_enemy_slope: float = 0.85
## Loot present scales as `party ^ this` ⟨tune⟩. **Below 1 on purpose**, which
## is what makes per-capita yield *fall* with party size — you are splitting a
## floor, and four people splitting it get less each without any rule saying
## four people get less.
@export var party_loot_exponent: float = 0.6
## Every clamor deposit is multiplied by `party ^ this` ⟨tune⟩. **Above 1 on
## purpose**: `DES-012` says four bodies are far more than twice as loud as
## two, and since `M2-T02` the Gullsjúkr navigates that noise, so a four-stack
## meets it sooner as a consequence rather than as a rule.
@export var party_clamor_exponent: float = 1.35

@export_group("Down and out")
## Seconds on the floor before the ember goes out ⟨tune⟩ (`DES-012`, ADR-050).
## **The window is the decision** — it shortens whatever anyone does about it,
## so choosing to wait for a rescue is forced by the fiction rather than by a
## UI prompt. Long enough to cross a room for someone, short enough that
## crossing two is a gamble.
@export var bleed_out_seconds: float = 45.0
## Seconds of a teammate's hands to get you up. A real cost in time and
## exposure, because a free revive is not a decision (`DES-012`).
@export var revive_seconds: float = 3.5
## Clamor per second made by whoever is kneeling over you. It is the *rescuer*
## who makes it — being loud on someone else's behalf is the sacrifice.
@export var revive_clamor: float = 3.2
## Fraction of maximum health you stand up with. Not full: going down has to
## cost something even when it works out.
@export var revive_health_fraction: float = 0.4
## Solo's single self-recovery (ADR-050) — deliberately below the value a
## friend's hand returns, because it *"must never be better than having a
## friend."*
@export var self_recovery_health_fraction: float = 0.22
## Crawl speed as a fraction of walking. You are on the floor and bleeding;
## you can move, and you cannot get anywhere.
@export var downed_speed_fraction: float = 0.28
## **The Vörðr** (`M3-T14`, `DES-012`) — your ward-spirit, briefly loose ⟨tune⟩.
##
## Faster than walking, because the one utility it has that does not need the
## ping system is *"scout ahead without risk"*, and a scout slower than the
## party scouts nothing. It carries nothing and fears nothing, so there is
## no load term and no sprint: one speed, always.
@export var vordr_speed: float = 4.6
## Seconds between the last body going out and the run ending ⟨tune⟩
## (`M2-T16`, ADR-108). Two jobs: it gives the moment somewhere to land instead
## of cutting to the camp on the frame you die, and it is the window in which a
## revive still counts — the party going down a second apart is an ordinary way
## for a fight to end, and the second one getting up must not arrive after the
## run is already over.
@export var party_wipe_seconds: float = 3.0

@export_group("Extraction")
## Seconds standing in the Shaft to leave, before escalation ⟨tune⟩. Long
## enough that a known, fixed location is a real exposure and short enough that
## an early exit is genuinely the cheap one (`DES-005`).
@export var shaft_channel_seconds: float = 4.0
## Clamor per second while using it. The Shaft is *"reliable but dangerous and
## loud"* — this is the loud.
@export var shaft_clamor: float = 5.0
## **The Sealing** (ADR-091). At full escalation the channel and the noise are
## both multiplied by `1 + this`, so leaving late is longer *and* louder. The
## Shaft never locks — `DES-005` guarantees it stays reachable, and on one
## floor a locked Shaft is a trap with nothing beneath it.
@export var shaft_seal_factor: float = 2.2
## Seconds of Hunt on the floor for escalation to reach full ⟨tune⟩. Read off
## the Gullsjúkr's age, so the price of leaving and the pressure you feel come
## from the same clock.
@export var shaft_seal_seconds: float = 300.0

@export_group("Interaction")
## Metres you can reach a thing from. Latency slack is added on top **on the
## host**: a client presses interact from where it believes it stands, and the
## host tests against a transform up to a replication interval old, which is
## about 0.2 m at walking pace.
@export var interact_reach: float = 2.2
@export var interact_reach_slack: float = 0.5

@export_group("Weapon")
## **The attack anatomy lives on the weapon now** (`M3-T07`, `DES-020`).
##
## `DES-009`'s Anticipation → Active → Recovery used to be seven numbers here,
## and every weapon in the item table carried its own copy that **nothing read**
## (ADR-124 §2). Slots gave `WieldableTrait` a reader, so the numbers moved to
## where the design always described them — *"space is a weapon stat"* is not a
## sentence about a profile — and they are gone from here rather than left as a
## second source of truth (ADR-064).
##
## What stays is the one value that is **not** a property of a weapon:
## buffering is a property of the *input*, and it is the same for a knife and a
## hammer because it is about how a press feels, not about what is being swung.
## `DES-009` §4 lists it under Forgiveness for exactly that reason.
##
## A press this long before recovery ends still fires. Without buffering, a
## committal system reads as unresponsive rather than weighty.
@export var swing_buffer_window: float = 0.25

## **How often an empty hand is allowed to say so** ⟨tune⟩ (ADR-140).
##
## Swinging with nothing in your hand used to do **nothing at all** — no sound,
## no motion, no refusal — because `request_swing` returns false when nothing is
## wielded. A dead button is not an absent feature, it is a broken one, and
## principle 4 has no sentence for it.
##
## A gap rather than a cue per press: attack is held down under pressure, and a
## refusal that fires every frame is a rattle nobody can read as a refusal.
@export var empty_hand_gap: float = 0.4

@export_group("Light")
## How much light the floor gives you for free ⟨tune⟩ (`M4-T13`, `ART-001`).
##
## **Moved here from `RoomSet.AMBIENT_ENERGY`**, where it sat since `M2-T13`
## under a comment promising it would *"drop when the lantern lands."* It is a
## ⟨tune⟩ number, and ⟨tune⟩ numbers live in the profile — but the sharper
## reason is the field directly below it: the two are one fact seen two ways,
## and they were in different files with nothing tying them together. A floor
## made darker while `exposure_ambient` stood still would look black and still
## get you spotted at the same distance, which is the *worst* possible outcome
## and would have read as the lantern not working.
@export var floor_ambient_energy: float = 0.12
## The exposure a body has with no lamp anywhere near it ⟨tune⟩ (`M4-T13`).
##
## **Not zero, and the reason is `DES-018` rather than taste.** The floor keeps
## a little ambient light so an unlit player is navigable-but-furtive rather
## than blind, and this is that light expressed as visibility: at 0.15 you are
## seen from about a third of the lit distance. Zero would mean a body that
## nothing can ever see, which is not stealth, it is invisibility — and
## `DES-005` requires *hide and let it pass* to be a risk, not a switch.
@export var exposure_ambient: float = 0.15

@export_group("Enemy")
@export var enemy_health: float = 60.0
@export var enemy_attack_damage: float = 34.0
@export var enemy_walk_speed: float = 2.0
@export var enemy_run_speed: float = 3.6
@export var enemy_turn_rate: float = 0.12
## How far a **fully lit** body is seen from. Unchanged since `M1`: this is the
## number every existing measurement was taken against, and `M4-T13` made it
## the top of a range rather than the whole story.
@export var enemy_vision_range: float = 16.0
## And how far a body in the dark is seen from ⟨tune⟩ (`M4-T13`, `ART-001`).
##
## `Exposure.seen_from()` interpolates between the two. **The gap is the whole
## mechanic** — set these equal and the lantern becomes a graphics setting, and
## `ART-001`'s *"darkness is a mechanic, not an effect"* becomes a sentence the
## build contradicts.
##
## Below `enemy_attack_range` would mean a thing could hit you without ever
## having seen you, so `_validate()` refuses it.
@export var enemy_vision_dark: float = 5.0
@export var enemy_vision_half_angle: float = 60.0
## Seconds of pursuit after losing sight, before dropping to SUSPICIOUS and
## then back to UNAWARE. Short enough that breaking line of sight is a real
## counter-play, long enough that it is not trivial.
@export var enemy_patience: float = 4.0
@export var enemy_attack_range: float = 2.2
## **Hard floor 0.25 s** — enforced in `_validate()`, not by convention.
@export var enemy_telegraph: float = 0.50
@export var enemy_attack_active: float = 0.12
@export var enemy_attack_recovery: float = 0.45
## How long a hit interrupts an attack. The reward for reading a telegraph.
@export var enemy_stagger: float = 0.35

## Poise an enemy absorbs before it staggers (`M4-T16`, ADR-194).
##
## Sized against the roster rather than picked: the hammer's 100 breaks it in
## one hit, so `DES-009`'s *"heavy staggers"* is literally true, and the seax's
## 22 cannot break it inside the four swings that kill this enemy — so a light
## weapon has to earn its stagger in the recovery window. Regeneration is what
## stops poise carrying between fights, and it is deliberately slower than the
## fastest weapon's damage rate so sustained pressure still wins eventually.
@export var enemy_poise: float = 100.0  # ⟨tune⟩
@export var enemy_poise_regen: float = 18.0  # ⟨tune⟩
## Seconds of hearing something before UNAWARE becomes SUSPICIOUS. A short
## delay stops a single footstep at the edge of earshot from flipping a whole
## room, which would make crouching pointless.
@export var enemy_hearing_patience: float = 0.35

@export_group("Clamor")
## DES-005 Layer 1: noise is continuous, player-caused pressure. Units are
## arbitrary; what matters is the ratios between the emitters below and the
## radius they buy.
@export var clamor_decay: float = 2.4
@export var clamor_maximum: float = 20.0
## Metres of audible radius per unit of clamor.
@export var clamor_metres_per_unit: float = 1.6
## Metres walked between footfalls. Distance rather than time, so sprinting is
## louder because you cover ground faster *and* because of the multiplier.
@export var clamor_step_distance: float = 1.9
@export var clamor_footstep: float = 1.5
@export var clamor_crouch_multiplier: float = 0.25
@export var clamor_sprint_multiplier: float = 1.7
## Weight makes you louder as well as slower — the same greed, same number.
@export var clamor_footstep_at_capacity: float = 2.4
@export var clamor_landing: float = 3.5
## `DES-009`: *"Every swing has a Clamor value. Blunt weapons are loudest."*
## Both halves of that are claims about **weapons**, so both live on
## `WieldableTrait` since `M3-T07` — a hammer is louder than a knife, and one
## number here could never say so.
## Noise made handling one item — rummaging in an open bag, and lifting or
## setting down anything. Scaled by the item's own clamor.
@export var clamor_rummage: float = 0.6
## What fraction of the bag's total clamor you give off **standing perfectly
## still**. `ClamorSource` decays toward this rather than to zero, so a rich
## player is never truly silent and dropping the loot is what buys silence
## back — `DES-005`'s primal counter-play, made mechanical.
##
## Deliberately a fraction and not the whole sum. At 1.0 a full glitter bag is
## a permanent 13.6 m audible radius against a 16 m enemy vision range, which
## deletes *"hide and let it pass"* from `DES-005`'s own counter-play list. At
## 0.25 the same bag is heard from 3.4 m — close enough to sneak past, far
## enough that you can feel it.
@export var clamor_carried_fraction: float = 0.25
## Metres of *equivalent distance* added by each wall between you and a
## listener. Walls muffle rather than block: TEC-001's field gets that shape
## for free by diffusing through open space, and this reproduces it — sound
## rounds a corner cheaply and dies through a wall.
@export var clamor_wall_penalty: float = 7.0


## Human visual reaction time is ~250 ms before any decision-making or input
## actuation (DES-009 §3), so an attack faster than that produces a death the
## player cannot explain — Principle 4 with a number attached.
##
## CLAUDE.md says CI enforces this. The full data validator is `M2-T08`, which
## will check every `EnemyDef` rather than this one profile; until it exists
## the constraint would otherwise be unenforced on the only telegraph value
## that actually exists, so the resource checks itself at load.
const TELEGRAPH_FLOOR: float = 0.25


## What one node of a tier costs. Read through here rather than off the three
## fields, so nothing has to remember which is which.
func node_cost(tier: AspectNode.Tier) -> int:
	match tier:
		AspectNode.Tier.KEYSTONE:
			return node_cost_keystone
		AspectNode.Tier.GREATER:
			return node_cost_greater
		_:
			return node_cost_lesser


func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if enemy_telegraph < TELEGRAPH_FLOOR:
		problems.append("enemy_telegraph is %.3f s, below the %.2f s floor (DES-009 §3)"
			% [enemy_telegraph, TELEGRAPH_FLOOR])
	# **The gap between lit and dark is the lantern** (`M4-T13`, ADR-188). Both
	# rows below describe a build in which darkness has stopped being a
	# mechanic, and neither would raise an error anywhere else: the game would
	# run, and the lamp would just be a light.
	if enemy_vision_dark >= enemy_vision_range:
		problems.append(("a body in the dark is seen from %.1f m and a lit one "
			+ "from %.1f m — with no gap the lantern costs nothing and "
			+ "`ART-001`'s darkness is an effect again")
			% [enemy_vision_dark, enemy_vision_range])
	if enemy_vision_dark <= enemy_attack_range:
		problems.append(("enemy_vision_dark %.1f m is inside enemy_attack_range "
			+ "%.1f m — something could hit you having never seen you, which is "
			+ "the death principle 4 forbids") % [enemy_vision_dark, enemy_attack_range])
	if exposure_ambient < 0.0 or exposure_ambient > 1.0:
		problems.append("exposure_ambient %.2f is outside 0–1" % exposure_ambient)
	if floor_ambient_energy <= 0.0:
		problems.append(("floor_ambient_energy %.2f leaves a floor with no "
			+ "light at all — `DES-018` rules out a build the player cannot "
			+ "see, and `M2-T13` already learned that a dark level with no "
			+ "light source is a bug rather than a mechanic")
			% floor_ambient_energy)
	# **The two halves of one fact, checked against each other.** They live in
	# different units and cannot be derived from one another, so what is
	# enforceable is that they were not tuned in opposite directions: a floor
	# lit brightly enough to walk without a lamp, whose bodies are as invisible
	# as if it were pitch dark, is a build where the lantern is decoration.
	if floor_ambient_energy >= 0.30 and exposure_ambient <= 0.20:
		problems.append(("a floor at %.2f ambient is bright enough to cross "
			+ "unlit, and %.2f exposure says a body standing in it is nearly "
			+ "invisible — `M4-T13` moved these into one place precisely so "
			+ "they could not drift apart like this")
			% [floor_ambient_energy, exposure_ambient])
	if carry_capacity <= 0.0:
		problems.append("carry_capacity must be positive or encumbrance is undefined")
	if stamina_max <= 0.0:
		problems.append("stamina_max must be positive")
	if inventory_grid.x < 1 or inventory_grid.y < 1:
		problems.append("inventory_grid %s has no cells to put anything in"
			% inventory_grid)
	# A negative fraction would make carrying loot quieter than carrying
	# nothing, which inverts the coupling DES-005 Layer 1 is built on.
	if clamor_carried_fraction < 0.0:
		problems.append("clamor_carried_fraction cannot be negative — greed does"
			+ " not make you quieter")
	if bag_speed_multiplier <= 0.0:
		problems.append("bag_speed_multiplier must be positive; opening the bag"
			+ " is meant to slow you, not root you")
	if interact_reach <= 0.0:
		problems.append("interact_reach must be positive or nothing can be picked up")
	# The Tithe's whole job is that growth costs more, not less. A table that
	# dips anywhere hands the player a rank that is strictly cheaper to hold
	# than the one below it, and `DES-003`'s coupling — power pulls you deeper —
	# runs backwards from that rank on. Caught at boot rather than in balance.
	if tithe_by_rank.is_empty():
		problems.append("tithe_by_rank is empty; she would expect nothing at any rank")
	for rank: int in range(1, tithe_by_rank.size()):
		if tithe_by_rank[rank] < tithe_by_rank[rank - 1]:
			problems.append(("tithe_by_rank falls at rank %d (%d after %d) — a "
				+ "Tithe that gets cheaper with power inverts DES-003's coupling")
				% [rank + 1, tithe_by_rank[rank], tithe_by_rank[rank - 1]])
	if tithe_cycle_runs < 1:
		problems.append("tithe_cycle_runs must be at least 1 or the cycle never closes")
	# The ordering is the design, not tidiness: `DES-004` gives a keystone the
	# weight of five lesser nodes because it is the thing a build is named
	# after, and a keystone that cost the same as a trinket would be taken by
	# everybody on the first run and stop meaning anything.
	if node_cost_lesser < 1 or node_cost_greater < 1 or node_cost_keystone < 1:
		problems.append("a node that costs nothing is not a decision")
	if not (node_cost_lesser <= node_cost_greater and node_cost_greater <= node_cost_keystone):
		problems.append(("node costs run %d / %d / %d — ADR-060 orders them "
			+ "lesser ≤ greater ≤ keystone, and a keystone priced like a "
			+ "trinket is taken on the first run by everybody")
			% [node_cost_lesser, node_cost_greater, node_cost_keystone])
	if boon_per_rank < 1:
		problems.append("boon_per_rank below 1 makes every node a rank, and the "
			+ "Tithe table would be exhausted before a build existed")
	if boon_per_tribute < 1:
		problems.append("boon_per_tribute below 1 makes Boon free, which is "
			+ "`DES-004`'s *tribute is a real cost* deleted")
	if tithe_missed_head_start < 0.0:
		problems.append("tithe_missed_head_start cannot be negative — missing a "
			+ "Tithe does not buy you a calmer floor")
	if gullsjukr_killable_rank < 1:
		problems.append("gullsjukr_killable_rank below 1 makes it killable from "
			+ "the first descent, which DES-017 spends a page refusing")
	# Both negatives would make a high-rank floor *easier* than a low-rank one,
	# which is ADR-010 inverted: the veteran's session gets safer as they grow,
	# and the Tithe they cannot service on it is the one that rose.
	if rank_density_slope < 0.0:
		problems.append("rank_density_slope cannot be negative — a rank-8 floor "
			+ "with fewer things on it than a rank-1 floor inverts ADR-010")
	if rank_hunt_seconds < 0.0:
		problems.append("rank_hunt_seconds cannot be negative — it would hand a "
			+ "high-rank floor a younger Hunt and slower-sealing Shafts")
	# `DES-009` in as many words: block *"reduces damage, doesn't negate it"*.
	# At 1.0 a raised guard is invulnerability, every fight becomes a holding
	# contest, and the positional defence the combat model is built on stops
	# being the answer to anything. Refused at boot rather than discovered in a
	# playtest where the Húskarl simply never dies.
	if block_damage_fraction < 0.0 or block_damage_fraction >= 1.0:
		problems.append(("block_damage_fraction is %.2f — it must sit in [0, 1), "
			+ "because DES-009 says a block reduces damage and never negates it")
			% block_damage_fraction)
	if respec_refund <= 0.0 or respec_refund >= 1.0:
		problems.append(("respec_refund is %.2f — at or above 1.0 a respec is "
			+ "free and `DES-004`'s *costs real resources* stops being true; at "
			+ "or below zero it deletes a node rather than reconsidering it")
			% respec_refund)
	if boon_cap_fraction <= 0.0 or boon_cap_fraction > 1.0:
		problems.append(("boon_cap_fraction is %.2f — at or below zero nothing "
			+ "converts and the tree is unreachable; above 1.0 a cycle earns "
			+ "back more than it owes and `DES-003`'s coupling runs backwards")
			% boon_cap_fraction)
	if block_stamina_cost <= 0.0:
		problems.append("block_stamina_cost must be positive or blocking is free, "
			+ "and a free block is a stance rather than a resource")
	# ADR-053's 250 ms floor is about telegraphs an ally or an enemy can read,
	# and setting a trap is as much of one as raising an axe.
	if snare_place_seconds < 0.25:
		problems.append(("snare_place_seconds is %.2f s, below ADR-053's 250 ms "
			+ "floor — a verb that costs no visible time is a reflex, which is "
			+ "the side of principle 3 this game is not on") % snare_place_seconds)
	if snare_stamina_cost <= 0.0:
		problems.append("snare_stamina_cost must be positive; DES-011 rule 3 "
			+ "requires every unique verb to have a real cost")
	if snare_hold_seconds <= 0.0:
		problems.append("snare_hold_seconds must be positive or a Snare holds "
			+ "nothing and the Veidimadr's verb does nothing")
	if snare_clamor_trigger < 0.0:
		problems.append("snare_clamor_trigger cannot be negative — a silent "
			+ "trap is 0.0, not less")
	return problems
