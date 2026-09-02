class_name RoomModule
extends Resource
## One authored room, as data (`DES-015` step 4, `TEC-006`, ADR-170).
##
## `TEC-001` chose **hand-authored modules, procedurally assembled** over
## generated geometry — better readability, better art, far less generator
## tuning agony — and `CLAUDE.md` §4 requires a designer be able to add a room
## without touching a script. So a module is a `.tres` under `game/data/rooms/`
## and this is its schema.
##
## ## Why this file did not exist until now
##
## ADR-169 deferred it deliberately. The graph had to be built first so it could
## *state* what it needed from a module rather than have someone guess: a node
## with three neighbours needs a module that can carry three doors, a node on
## the held arm needs one that can carry danger, and neither fact was knowable
## before `MissionGraph` existed. Every field here is one the graph asks for.
##
## **Fields are added when something consumes them, not when they sound useful.**
## Volume profile, vista affordance and prop weighting are all named in
## `TEC-007` §5.2 and all absent, because steps 5–7 are what read them and steps
## 5–7 are not built. A field nothing reads is a dead name (ADR-098) that
## `check_dead.py` cannot see, because a `.tres` mentions it.


## Stable string id, the `ItemResource` idiom (`TEC-006` principle 3). A plan
## records `"hall_pillared"`, never a resource path.
@export var id: StringName = &""

## How tall a room stands, which is the only axis ADR-014 lets vary: cells are
## planar and **verticality lives inside rooms**. Ceiling heights per value are
## `FloorBuilder`'s to set — this says which kind of space the module is.
##
## The order is the wire order, and it is in every `.tres`. Append, never insert.
enum Volume {
	CRAWL,  ## Crouch-only. Refuses the standing body on purpose (`TEC-008`).
	LOW,    ## Standing, oppressive. A worked passage.
	HALL,   ## The shipped default, matching the hand-authored rooms.
	GREAT,  ## Seen from elsewhere. Vista target and fight space.
}

@export_group("Shape")
## Footprint in grid cells. `DES-015`'s anti-boxiness list wants 2×3 and 4×4
## galleries as well as single cells — *"the grid is a generation substrate,
## never a visible constraint."*
@export var footprint: Vector2i = Vector2i.ONE
## Which cross-section this room is cut as (`TEC-008` §3.2, ADR-175).
##
## Withheld from ADR-172 deliberately: nothing read it then, and a `.tres`
## mentioning a field is a dead name `check_dead.py` cannot see. `FloorBuilder`
## is its reader, so it arrives now.
@export var volume: Volume = Volume.HALL

@export_group("Fit")
## Which `MissionGraph.Role` values this module may serve. **Empty means
## connective tissue only**, which is the common case and the safe default: a
## corridor must never stand in for the Guardian's chamber merely because
## nobody wrote down that it could not.
@export var roles: PackedInt32Array = PackedInt32Array()
## May this module sit on the held arm? *"West long and safe, east short and
## held"* is a placement constraint, not a decoration — a corridor cannot be
## the room a Guardian holds.
@export var held_capable: bool = false
## How many corridors it can carry. The graph decides how many a node needs;
## this says whether the module can take them.
@export var max_links: int = 4

@export_group("History")
## Room flavours this module carries, matched against the Calamity's own tags
## (`DES-015` Layer 2). A module sharing a tag with what happened here is
## weighted up when the floor is built.
##
## **Empty is the common case and is not a gap.** A neutral module can appear
## under any Calamity, and it is what stops a floor reading as a single note
## repeated fourteen times.
@export var tags: Array[StringName] = []
## Which kind of Prize this module can hold — `DES-015` Layer 2 rolls one per
## expedition, and the room the player finally walks into has to be the one the
## history promised. Empty on everything that is not a Prize room.
@export var prize_kind: StringName = &""

@export_group("Depth")
## Floors this module is legal on, inclusive. `DES-015` Layer 2 reads the
## disaster backward as you descend, so a module can belong to the Aftermath
## and not to the Cause.
@export var min_floor: int = 0
@export var max_floor: int = 2


## Checked at boot, in the shape `ItemResource.validate()` established
## (`TEC-006` principle 4): a malformed module should stop the build rather than
## reach a player as a floor the generator could not lay out.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id == &"":
		problems.append("a room module with no id cannot be placed or logged")
	if footprint.x < 1 or footprint.y < 1:
		problems.append("`%s` has a %d×%d footprint — a room occupies cells"
			% [id, footprint.x, footprint.y])
	if footprint.x > FloorPlan.MAX_FOOTPRINT \
			or footprint.y > FloorPlan.MAX_FOOTPRINT:
		problems.append(("`%s` is %d×%d, past the %d-cell limit — a room "
			+ "larger than its lattice cell reaches into its neighbour's")
			% [id, footprint.x, footprint.y, FloorPlan.MAX_FOOTPRINT])
	if max_links < 1:
		problems.append("`%s` accepts no corridors, so nothing could reach it"
			% id)
	if min_floor > max_floor:
		problems.append("`%s` is legal from floor %d to floor %d, which is no "
			% [id, min_floor, max_floor] + "floors at all")
	for role: int in roles:
		if role < 0 or role >= MissionGraph.Role.size():
			problems.append("`%s` claims role %d, which does not exist"
				% [id, role])
	# A module that can serve the held arm but only takes one corridor is a
	# dead end, and the held span is a *span* — it has two ends by definition.
	if held_capable and max_links < 2:
		problems.append(("`%s` can hold danger but takes one corridor — the "
			+ "held arm is a span and a dead end cannot be one") % id)
	var serves_prize: bool = roles.has(MissionGraph.Role.PRIZE)
	if serves_prize and prize_kind == &"":
		problems.append(("`%s` can be the Prize but names no kind, so the "
			+ "history could promise a barrow and the player walk into a "
			+ "vault") % id)
	if prize_kind != &"" and not serves_prize:
		problems.append("`%s` names a Prize kind but cannot serve the Prize"
			% id)
	return problems


## Can this module stand in for `node`? Everything the placer needs to know
## before it tries a position, so a candidate that cannot fit is never tried.
func fits(role: int, links: int, held: bool, floor_index: int) -> bool:
	if links > max_links:
		return false
	if held and not held_capable:
		return false
	if floor_index < min_floor or floor_index > max_floor:
		return false
	if roles.is_empty():
		return role == MissionGraph.Role.CONNECTIVE
	return roles.has(role)
