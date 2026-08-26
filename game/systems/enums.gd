class_name Enums
extends Object

## Shared enum definitions, in one place (`TEC-006`).
##
## Never instantiated and never an autoload. It exists so that a resource and
## the system that reads it can share one definition without either depending
## on the other — the alternative is an enum declared on whichever class
## happened to need it first, which makes every later consumer depend on that
## class for a constant.
##
## Deliberately thin. Enums arrive here when a resource needs to name one, not
## in advance of that.

## DES-009's cut/pierce/blunt triangle.
##
## One type resolves today: `Hurtbox.damage_scale` is at 1.0 everywhere while
## there is a single damage type, and the triangle is `M4-T02`'s work. The
## three names exist because a weapon that cannot say what kind of damage it
## deals is not describable, which is the same argument `Hurtbox` already
## makes for its multiplier — a real value at its only current setting, not a
## reserved slot.
enum DamageType { CUT, PIERCE, BLUNT }

## `DES-020`'s six, and `NONE` for everything that is only ever cargo.
##
## Six deliberately: *"every slot multiplies against every armour set in art
## cost."* There are no trinket or charm slots and there will not be — `DES-009`
## refused a stat block because Aspects plus gear already carry build identity,
## and a third axis is that refusal undone wearing a different hat.
##
## `BODY` is torso **and** legs in one piece, which `DES-020` calls the single
## largest art saving in the system for a difference stylised low-poly barely
## registers.
enum Slot { NONE, MAIN_HAND, OFF_HAND, ARMS, HEAD, BODY, PACK }
