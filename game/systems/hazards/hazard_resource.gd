class_name HazardResource
extends Resource
## Ground that changes what a body can do while it stands on it (`M4-T02` step 6,
## ADR-236, `DES-009`'s *hazards are universal*).
##
## ADR-230 chose two, one for each sense the game is built on: **scree** is noise
## and **choke-damp** is light and breath. A hazard is a handful of rules, and
## every rule is asked of an enemy exactly as of a player — `DES-009`: *"traps,
## fire, water, and falls apply identically to enemies."*
##
## Laid only by a machine (ADR-236, the developer's call). A room a hazard covers
## is a situation, and `DES-015`'s rule is that a situation asks the player
## something; a hazard stamped into a room on its own would be a colour with a
## rule under it and no question.

## Stable, prefixed `haz_`, the `EnemyResource` idiom.
@export var id: StringName = &""

@export_group("Rules")
## **Every step on it is at least this loud**, for any body and whatever its
## stance or its Wing (ADR-236, the developer's call). Crouching does not quiet
## scree, and neither does the silent crouch node: a louder step — a sprint —
## is still louder ⟨tune⟩.
@export var step_clamor: float = 0.0
## A lantern goes out in it and will not open while you stand in it.
@export var snuffs_light: bool = false
## Breath does not come back in it: a player's stamina and an enemy's poise hold
## where they are for as long as the body stays.
@export var stops_recovery: bool = false
## No body calls the floor from inside it (ADR-230). A Bellringer that has you
## in the damp has you, and cannot tell anyone.
@export var stops_calls: bool = false

@export_group("Look")
## What it is drawn in. **Its visual twin** (`DES-018`): scree is a sound, and a
## hazard only heard is one a player with the sound off walks into unwarned.
## Desaturated, because `ART-005` keeps saturated colour for treasure.
@export var colour: Color = Color(0.5, 0.5, 0.5, 1.0)
## Drawn as air filling the room rather than as a layer lying on its floor.
@export var fills_air: bool = false


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("haz_"):
		problems.append("hazard id '%s' does not start with haz_" % id)
	if step_clamor < 0.0:
		problems.append("%s makes a step %.1f loud, which is quieter than silence"
			% [id, step_clamor])
	if step_clamor <= 0.0 and not snuffs_light and not stops_recovery and not stops_calls:
		problems.append("%s changes nothing about a body standing in it, so it is a colour"
			% id)
	if colour.a <= 0.0:
		problems.append("%s is drawn fully transparent — a hazard nobody can see" % id)
	return problems
