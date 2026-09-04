@abstract
class_name FloorSource
extends RefCounted
## What a level needs to know about the floor underneath it (`M4-T01`).
##
## `room_set.gd` is 7400 lines and is two things at once: **the machinery a run
## needs** — a session, a party, a Hunt, an extraction, a wipe, thirty probes —
## and **one hand-authored floor**, as a dozen constants the machinery reads
## inline. Only the second half is about the Deep. Everything else would serve a
## generated floor unchanged if it had somewhere else to read those dozen
## answers from.
##
## This is that somewhere. Two implementations: `AuthoredFloor` returns the
## Deep's constants, `DelvingsFloor` derives the same answers from a
## `MissionGraph` and a `FloorPlan` through `FloorAnchors`.
##
## ## Why a seam rather than an extraction
##
## The plan this came from proposed moving the run lifecycle out of `RoomSet`
## into a component both levels could compose. Reading it closely says
## otherwise: `_end_the_run`, `_take_the_outcome`, `_watch_for_a_wipe` and the
## rest **do not mention the floor at all** — they talk to the session, the
## party, `GameState` and `RunFile`. What is floor-specific is the handful of
## constants six functions read. Moving forty functions and an `@rpc` (whose
## node path is part of its contract) to separate code that is already separate
## would be a week of risk for no change in structure; parameterising the six
## reads is the same result by arithmetic.
##
## ## It answers where, never what
##
## Like `FloorAnchors`, which it wraps on the generated side. Which enemy, which
## item, which Prize are `DES-013`, `M4-T17` and `DES-008`, and none of them is
## settled — so nothing here names one.


## Raise the floor's geometry under `into`.
##
## Walls, floors, ceilings and whatever else a body collides with. The level
## supplies the node and lights it; what stands in it is the floor's business.
@abstract func build(into: Node3D) -> void


## Where the party arrives. One point per player, far enough apart that two
## bodies are never spawned inside each other.
@abstract func spawns() -> Array[Vector3]


## Where standing danger posts (`DES-013`). Party and rank scaling stack extra
## bodies *around* these rather than inventing new ones, so the list is the
## shape of the floor's danger and not its quantity — ADR-032's clean bypass is
## a claim about which rooms are on this list.
@abstract func enemy_posts() -> Array[Vector3]


## Where the Machine on the Prize stands (`DES-015` Layer 3). Spawned once
## whatever the party size: four of it would be a different encounter rather
## than a scaled one.
@abstract func guardian() -> Vector3


## Where the threat belonging to a **machine** stands (`DES-015` Layer 3,
## ADR-192).
##
## The Guardian's rule, generalised: spawned once, whatever the party size.
## Deliberately not `enemy_posts()` — those are the floor's danger *shape* and
## scaling stacks bodies around them, which is right for standing danger and
## wrong for a situation. *"A crew died in here and the thing that killed them
## has not moved"* is one encounter; four of it because four people came down
## is a different room.
##
## Empty on the authored Deep, which places its own situations by hand.
@abstract func machine_posts() -> Array[Vector3]


## The way down (`DES-005`, ADR-186) — and, on the bottom floor, the Deep Gate's
## mechanism, which is where an expedition ends.
@abstract func shaft() -> Vector3


## Where the best thing on this floor is (`DES-015` Layer 3, ADR-187).
##
## Added because a **game-path** deed was reading `RoomSet.PRIZE_AT` directly:
## `_the_prize_is_still_here` asks whether the best thing down here is still
## down here, by measuring 3 m from a hand-authored coordinate. On a generated
## floor the Prize is wherever the mission graph put it, so the check would have
## answered *no* on every run — silently, with no error, because a deed that
## never fires looks exactly like a deed nobody earned.
##
## `DES-016`'s instrumentation rule is *ask the world, it already knows*. This
## is what the world is asked through.
@abstract func prize() -> Vector3


## Where the Hunt begins (`DES-017`) — deep, so the first meeting happens on the
## walk out with a full bag.
@abstract func hunter() -> Vector3


## The things that are on the floor whatever the party size (`M2-T17`,
## ADR-110): the Prize and the way out that is not the Shaft. Rows of
## `[StringName, Vector3]`.
@abstract func fixtures() -> Array


## The loot that is quantity rather than a decision, divided among the party.
## Rows of `[StringName, Vector3]`.
@abstract func filler() -> Array


## The bounds the Clamor field covers. Noise made outside it lands nowhere.
@abstract func field() -> AABB


## A pale light in every doorway — `ART-005`'s rule that a room shows its own
## exits, which `M2-T13` found is the difference between a floor you can read
## and six identically lit boxes.
@abstract func door_lights() -> Array[Vector3]
