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

## Multiplies incoming damage, before armour. Every hurtbox sets 1.0 — a real
## value at its only current setting, and where a head taking more than a body
## would live if the game ever had one.
@export var damage_scale: float = 1.0

## **What this body turns a blow with** (ADR-219, `DES-009`'s triangle).
##
## Set by the actor, which is the only thing that knows what it wears: a player
## from the torso slot, an archetype from its own data. The triangle resolves
## here, at the one place every blow arrives, so a sword, an enemy's claw and an
## arrow all meet the same table and none of them can forget to ask.
var armour: Enums.ArmourClass = Enums.ArmourClass.UNARMOURED


## A blow of `amount` and `type` arrived. The type is required rather than
## defaulted: a caller that forgot it would silently strike as a cut, and a
## missing argument is a parse error where a wrong default is a balance bug.
func receive(amount: float, type: Enums.DamageType, from: Node) -> void:
	hit.emit(amount * damage_scale * Config.tuning.armour_through(armour, type),
		from)
