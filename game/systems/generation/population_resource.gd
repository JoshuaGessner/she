class_name PopulationResource
extends Resource
## **Who stands where on a floor** (`M4-T02` step 7, ADR-237, `DES-015` step 7).
##
## ADR-230 fielded five archetypes and ordered this step last: which of them a
## floor's posts carry, and how that changes with depth. The developer's two
## calls (ADR-237) are why this file has the shape it has:
##
## - **By the room a post is in.** Each archetype stands where its role reads —
##   a Blocker at the door into the guarded arm, a slinger in a room big enough
##   to throw across, the Guardian on the Prize — rather than wherever a
##   weighted roll put it.
## - **Ramped in.** The first floor is Wretches and Bellringers, so the base
##   fight is learned before plate and stones arrive.
##
## One per biome, as `LootTable` is. It names archetypes and the depths they
## arrive at; `FloorPopulation` reads a floor's rooms against it.

## Stable, prefixed `pop_`.
@export var id: StringName = &""

@export_group("Who")
## Every body no other rule claims.
@export var rank_and_file: StringName = &"enm_wretch"
## On the Prize, on every floor.
@export var guardian: StringName = &"enm_hoard_keeper"
## At the door into the guarded arm.
@export var warden: StringName = &"enm_hall_warden"
## In a room big enough to throw across.
@export var slinger: StringName = &"enm_sling_wretch"
## One ordinary body in `ringer_every`.
@export var ringer: StringName = &"enm_bellringer"

@export_group("Where and when")
## The first floor, counted from 0, whose guarded arm has a Hall-Warden at its
## door ⟨tune⟩.
@export var warden_from_floor: int = 1
## Per floor, counted from 0: the smallest room a Sling-Wretch's post may stand
## in, as a `RoomModule.Volume`, or -1 for none on that floor. A floor past the
## end of the list reads the last entry ⟨tune⟩.
@export var slinger_rooms: PackedInt32Array = PackedInt32Array([-1, 3, 2])
## **Per floor, how many Sling-Wretches at most** (ADR-237, the developer's call
## after the census): the largest rooms that qualify get one each, great rooms
## before halls. Without it a slinger stood in 41 of 55 guarded rooms on floor
## two and the Wretch all but vanished below floor one ⟨tune⟩.
@export var slinger_caps: PackedInt32Array = PackedInt32Array([0, 1, 2])
## **One ordinary body in this many rings the floor**, counted from the first
## ordinary one, so every floor with an ordinary body has a Bellringer (ADR-234,
## which kept this on `TuningProfile` until this step) ⟨tune⟩.
@export var ringer_every: int = 4


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("pop_"):
		problems.append("population id '%s' does not start with pop_" % id)
	for archetype: StringName in [rank_and_file, guardian, warden, slinger, ringer]:
		if not String(archetype).begins_with("enm_"):
			problems.append("%s names '%s', which is not an enemy id" % [id, archetype])
	if ringer_every < 1:
		problems.append("%s rings one body in %d, which is fewer than one" % [id, ringer_every])
	if warden_from_floor < 0:
		problems.append("%s starts its Warden on floor %d" % [id, warden_from_floor])
	if slinger_rooms.is_empty() or slinger_caps.is_empty():
		problems.append("%s says nothing about where a slinger stands, or how many" % id)
	for cap: int in slinger_caps:
		if cap < 0:
			problems.append("%s allows %d slingers on a floor" % [id, cap])
	for volume: int in slinger_rooms:
		if volume < -1 or volume > RoomModule.Volume.GREAT:
			problems.append("%s puts a slinger in room volume %d, which does not exist"
				% [id, volume])
	return problems


## The smallest room a slinger stands in on `floor_index`, or -1 for none.
func slinger_room(floor_index: int) -> int:
	if slinger_rooms.is_empty():
		return -1
	return slinger_rooms[clampi(floor_index, 0, slinger_rooms.size() - 1)]


## How many slingers `floor_index` carries at most.
func slinger_cap(floor_index: int) -> int:
	if slinger_caps.is_empty():
		return 0
	return slinger_caps[clampi(floor_index, 0, slinger_caps.size() - 1)]
