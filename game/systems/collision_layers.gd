class_name CollisionLayers
extends Object

## Physics layer assignments, named once.
##
## Not a tuning value, so it does not live in `TuningProfile`: these are
## structural, and changing one is a code change with consequences, not a
## balance pass. The reason they are here rather than as bare numbers at each
## call site is that hitbox/hurtbox bugs caused by a mismatched mask are
## invisible — nothing errors, the swing simply passes through — and that is
## the worst class of bug to debug by eye.
##
## Bodies and hitboxes are deliberately separate layers. A hitbox that also
## collided with world geometry would be stopped by it; DES-009 wants weapon
## arcs to *hit* the world eventually, but as a query, not as a collision.

const WORLD: int = 1 << 0
const PLAYER_BODY: int = 1 << 1
const ENEMY_BODY: int = 1 << 2
const PLAYER_HURTBOX: int = 1 << 3
const ENEMY_HURTBOX: int = 1 << 4
