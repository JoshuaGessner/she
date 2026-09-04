class_name MachineResource
extends Resource
## One authored **situation**, as data (`DES-015` Layer 3, step 6, `TEC-006`).
##
## Brogue's machines, which `DES-015` adopts by name: *"pre-authored situations
## — not geometry — stamped procedurally into generated space."* A module says
## what a room **is**; a machine says what **happened** in it and what the
## player has to decide about that.
##
## ## The rule that makes one, and the check that enforces it
##
## > **Every machine poses a question the player answers with an action.**
## > *"A room with loot in it" is not a machine.*
##
## That is `DES-015`'s sentence and it is the only thing separating this system
## from a second loot table. So `question` is a **required** field — a machine
## that cannot state what it asks fails `validate()` and never reaches a floor
## — and `--machine-probe` prints it, because a field only a validator reads is
## the `name_key` trap this system was built after finding (ADR-192).
##
## ## What a machine is allowed to name, and what it is not
##
## The same split `FloorAnchors` and `DelvingsFloor` already keep: **this says
## how much and what shape, never which.** A machine that named `wep_seax`
## would be the invented taxonomy `delvings_floor.gd` refuses in as many words,
## and `M4-T17` is the task that earns the right to name one. `gear` is a
## count drawn from the worth-sorted pool for exactly that reason.
##
## ## Fields are added when something consumes them
##
## `room_module.gd`'s rule, and it is here because that file's own warning is
## what caught `CalamityResource.name_key`: a `.tres` mentioning a field makes
## it invisible to `check_dead.py`, so an unread export can sit in the corpus
## looking alive for as long as nobody reads the resource by hand.


## Stable string id, the `ItemResource` idiom (`TEC-006` principle 3). A plan
## records `"mac_witness"`, never a resource path.
@export var id: StringName = &""

## **What this room asks the player.** Required, in the author's own words, and
## the difference between a machine and a room with loot in it.
##
## Never shown to a player — `DES-015` Layer 2's discipline is that the pattern
## is discoverable and never stated. This is for whoever authors the next one
## and for the probe that prints what a floor asked.
@export_multiline var question: String = ""

@export_group("Fit")
## Which `MissionGraph.Role` values this machine may stamp onto. **Empty means
## connective rooms only**, the same safe default `RoomModule.roles` takes.
##
## The entrance, the Prize and the Shaft are refused whatever this says — see
## `FloorMachines`. They are spoken for by the mission itself.
@export var roles: PackedInt32Array = PackedInt32Array()
## The smallest room this situation reads in. A crawl is 1.15 m of crouch with
## no swing (`TEC-008`), so an arrangement laid in one is an arrangement nobody
## can stand up and look at.
@export var min_volume: RoomModule.Volume = RoomModule.Volume.LOW

## Whether the situation belongs on the held arm, off it, or either.
##
## `DES-015`'s *"west long and safe, east short and held"* is a placement
## constraint (`RoomModule.held_capable` carries the module half of it). A
## machine that posts bodies belongs where danger already is; one that posts
## none can sit on the safe branch and give it something to be about.
enum Held {
	EITHER,       ## Anywhere the roles allow.
	HELD_ONLY,    ## Only on the guarded span.
	UNHELD_ONLY,  ## Only off it — the bypass, which otherwise pays badly and says nothing.
}
@export var held: Held = Held.EITHER

@export_group("Depth")
## Floors this machine is legal on, inclusive. `DES-015` Layer 2 reads the
## disaster backward as you descend, so a situation can belong to the Aftermath
## and not to the Cause.
@export var min_floor: int = 0
@export var max_floor: int = 2

@export_group("Arrangement")
## How many **fallen** the situation lays — the dead, as blockout marks
## (ADR-046). This is the readable half: where people were when it reached them.
@export var fallen: int = 0
## Which way the fallen point. The arrangement *is* the sentence, so this is
## the verb in it, and each value says something different.
enum Facing {
	TOWARD_DOOR,     ## Pointing at the way out. They were trying to leave, and did not.
	AWAY_FROM_DOOR,  ## Pointing into the room. It was already in here with them.
	SCATTERED,       ## No order at all — whatever happened gave nobody time to face anything.
}
@export var facing: Facing = Facing.SCATTERED

@export_group("Contents")
## Live threat, posted **once** whatever the party size.
##
## Not `enemy_posts()`, deliberately: those are the floor's danger *shape* and
## party scaling stacks bodies around them. A machine's threat is a fixed part
## of the situation, like the Guardian — *"four of it in one room would be a
## different encounter rather than a scaled one"* (`FloorSource.guardian`).
@export var bodies: int = 0
## How many items lie in the room, drawn from the same worth-sorted pool
## everything else on the floor is dealt from.
##
## A **count, never an id.** Which items exist and what they are for belong to
## `M4-T17` and `DES-008`; when they arrive, this is the field that reads a
## loot table instead, and nothing above it changes.
@export var gear: int = 0


## Checked at boot, in the shape `ItemResource.validate()` established
## (`TEC-006` principle 4).
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id == &"":
		problems.append("a machine with no id cannot be stamped or logged")
	# **The rule, made mechanical.** `DES-015`: *"every authored room type poses
	# a question the player answers with an action. 'A room with loot in it' is
	# not a machine."* Without this the system is a second loot table with
	# better documentation.
	if question.strip_edges() == "":
		problems.append(("`%s` states no question — `DES-015` Layer 3 is that "
			+ "a machine poses one the player answers with an action, and a "
			+ "room with loot in it is not a machine") % id)
	if fallen <= 0 and bodies <= 0 and gear <= 0:
		problems.append(("`%s` puts nothing in the room at all, so stamping it "
			+ "would change a floor's log and not its contents") % id)
	if fallen < 0 or bodies < 0 or gear < 0:
		problems.append("`%s` asks for a negative quantity" % id)
	if min_floor > max_floor:
		problems.append("`%s` is legal from floor %d to floor %d, which is no "
			% [id, min_floor, max_floor] + "floors at all")
	for role: int in roles:
		if role < 0 or role >= MissionGraph.Role.size():
			problems.append("`%s` claims role %d, which does not exist"
				% [id, role])
	# The mission owns these three and a machine may not take them. Stated here
	# as well as enforced in `FloorMachines`, because a `.tres` author reads
	# this file and not that one.
	for role: int in roles:
		if role == MissionGraph.Role.ENTRANCE or role == MissionGraph.Role.PRIZE:
			problems.append(("`%s` claims role %d, which the mission owns — the "
				+ "entrance is where a run starts and the Prize already carries "
				+ "the Guardian") % [id, role])
	if min_volume == RoomModule.Volume.CRAWL:
		problems.append(("`%s` would stamp into a crawl — 1.15 m of crouch with "
			+ "no swing is not somewhere a situation can be read or fought")
			% id)
	return problems


## Can this machine stand in `node`'s room? Everything the stamper needs before
## it commits, so a candidate that cannot fit is never chosen.
##
## Deliberately the same shape as `RoomModule.fits()` — one predicate, all the
## constraints, no partial matching anywhere else.
func fits(role: int, module: RoomModule, held_arm: bool, floor_index: int) -> bool:
	if module == null:
		return false
	if floor_index < min_floor or floor_index > max_floor:
		return false
	if module.volume < min_volume:
		return false
	if held == Held.HELD_ONLY and not held_arm:
		return false
	if held == Held.UNHELD_ONLY and held_arm:
		return false
	if roles.is_empty():
		return role == MissionGraph.Role.CONNECTIVE
	return roles.has(role)
