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
## DES-009 attack anatomy: Anticipation → Active → Recovery. Attacks commit;
## there is no cancelling out of one. Recovery is not dead time — it is the
## window an enemy gets to punish a badly chosen swing.
@export var swing_windup: float = 0.16
@export var swing_active: float = 0.10
@export var swing_recovery: float = 0.30
@export var swing_damage: float = 25.0
@export var swing_stamina_cost: float = 12.0
## A press this long before recovery ends still fires (DES-009 §4). Without
## buffering, a committal system reads as unresponsive rather than weighty.
@export var swing_buffer_window: float = 0.25
## Generous on the player's swing, tight on incoming (DES-009 §4). Invisible,
## standard practice, and it is most of why a game feels fair.
@export var swing_reach: float = 2.2
@export var swing_arc_radius: float = 1.1

@export_group("Enemy")
@export var enemy_health: float = 60.0
@export var enemy_attack_damage: float = 34.0
@export var enemy_walk_speed: float = 2.0
@export var enemy_run_speed: float = 3.6
@export var enemy_turn_rate: float = 0.12
@export var enemy_vision_range: float = 16.0
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
## DES-009: "Every swing has a Clamor value." Missing is quieter than hitting;
## hitting something is the loud part, which is what makes a whiff cheap and a
## fight expensive.
@export var clamor_swing: float = 2.0
@export var clamor_hit: float = 4.5
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


func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if enemy_telegraph < TELEGRAPH_FLOOR:
		problems.append("enemy_telegraph is %.3f s, below the %.2f s floor (DES-009 §3)"
			% [enemy_telegraph, TELEGRAPH_FLOOR])
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
	return problems
