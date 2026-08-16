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
