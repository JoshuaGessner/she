class_name Hurtbox
extends Area3D

## What can be hit. A pure detector: it holds no hit points and applies no
## damage, it only reports that something struck it.
##
## Keeping this separate from `Health` is what lets an actor have several
## hurtboxes later (a head, a body) feeding one pool, without `Health` knowing
## anything about geometry. The actor wires `hit` to `Health.apply_damage`;
## the two components never reference each other.

signal hit(amount: float, from: Node)

## Multiplies incoming damage. Every hurtbox sets 1.0 while there is exactly
## one damage type in the game. DES-009's cut/pierce/blunt triangle resolves
## per-hurtbox rather than per-actor, so the multiplier belongs here — it is a
## real value being used at its only current setting, not a reserved slot.
@export var damage_scale: float = 1.0


func receive(amount: float, from: Node) -> void:
	hit.emit(amount * damage_scale, from)
