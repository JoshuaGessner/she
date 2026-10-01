class_name FlickerLight
extends OmniLight3D

## **A light that is a fire** (ADR-283). A steady omni light reads as an electric
## bulb, and a bulb is what the camp's fire and the dungeon's torches looked
## like. This breathes: two slow, unrelated waves and a small fast one, so the
## light never repeats in a way an eye catches, and never strobes — the swing is
## a fraction of the energy, because `ART-001` makes light a mechanic and a
## light that flashes is a light that lies about what is lit.
##
## Seeded by its position, so two torches side by side do not pulse together,
## and every peer's copy of the same torch agrees.

## How far the energy swings either side of `light_energy`, as a fraction ⟨tune⟩.
@export var swing: float = 0.14
@export var rate: float = 1.0

var _base: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_base = light_energy
	_phase = fposmod(global_position.x * 1.73 + global_position.z * 2.91, TAU)


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001 * rate + _phase
	var breath: float = sin(t * 1.9) * 0.5 + sin(t * 3.1 + 1.7) * 0.35 \
		+ sin(t * 11.0 + _phase) * 0.15
	light_energy = _base * (1.0 + breath * swing)
