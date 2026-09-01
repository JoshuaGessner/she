class_name MissionGraph
extends RefCounted

## `M4-T01` step 3 — the mission graph, before any geometry exists (`DES-015`).
##
## `DES-015` Layer 1 adopts **cyclic** dungeon generation (Dormans & Bakkes,
## 2011) and calls it *"the single highest-leverage technical investment in the
## project"*. The reason it is not optional for an extraction game is the shape
## of the decision it creates: a cycle means the way back is not the way in, so
## *"do I push on or turn around"* has two different answers with two different
## costs. A tree gives you one, and Dark and Darker's flatness is the diagnosis
## this document opens with.
##
## ## Topology first, and nothing else
##
## This builds a **graph**, not a floor. No rooms, no metres, no meshes. That
## ordering is deliberate rather than tidy:
##
## - The graph is where the design risk lives. Whether a floor poses a decision
##   is a property of its topology, and it can be asserted with no art, no
##   navmesh and no scene.
## - It **defers the room-module contract** until the graph can say what it
##   needs from a module. Designing the `Resource` first would mean guessing.
## - `DES-015` step 8 validates reachability and the ADR-032 bypass, and both
##   are graph questions. A soft-lock is detectable here, cheaply, before it
##   costs two seconds of generation to find.
##
## ## What a floor is, structurally
##
## A spine from the entrance, and one **alternate arm** rejoining it — the
## minimum that makes a cycle. The Prize sits on one arm and the Shaft beyond
## the rejoin, so both arms reach the way out and only one of them is held.
##
## ```
##            ┌── b1 ── b2 ──┐          the quiet arm
## entrance ──┤              ├── join ── … ── shaft
##            └── s2 ── s3 ──┘          the held arm (Prize)
## ```
##
## That is not a new idea — it is the hand-authored room set's own finding,
## which `room_set.gd` records: *"with the danger confined to one branch, the
## two halves of the loop mean different things — west is long and safe, east
## is short and held."* The generator has to keep producing that property
## rather than rediscover it by luck, which is what `problems()` is for.
##
## ## Determinism (`TEC-004`)
##
## The host sends a seed and every client builds the identical floor; geometry
## is never replicated, so a divergence here is two players disagreeing about
## where a wall is. `DES-015` requires **one RNG stream per pipeline stage,
## never shared** — so this takes a stream of its own, derived from the run
## seed and the floor index, and touches no global RNG.
##
## Node ids are integers assigned in creation order and edges are stored with
## the lower id first, then sorted. Nothing here iterates a `Dictionary`:
## `WorldHash` warns that traversal order is not a promised invariant, and a
## generator that is deterministic only because a hash table happened to
## enumerate the same way is not deterministic.

## What a node is for. The graph carries roles, not contents — *which* machine
## is stamped into the Prize node is `DES-015` step 6 and none of this file's
## business.
enum Role {
	CONNECTIVE,  ## Ordinary space. Most of a floor.
	ENTRANCE,    ## Where the party arrives.
	PRIZE,       ## The Guardian & Prize machine (`DES-015` Layer 3).
	SHAFT,       ## The way down, and out (`DES-005`).
}

## Which pipeline stage this is, mixed into the seed so stage 3 and stage 5
## cannot accidentally draw the same numbers from the same run seed.
const STAGE: int = 3

## Spine length at floor 0 ⟨tune⟩. Short enough that a floor is walkable in
## `DES-005`'s pressure window, long enough that the cycle is a detour rather
## than a fork.
const SPINE_MIN: int = 5
const SPINE_MAX: int = 7
## **And it grows with depth.** `DES-015` Layer 4 wants value to climb steeply
## with depth and the player to be able to see that; a floor that also gets
## *longer* is the structural half of the same statement. It has a second
## effect worth having: the three floors of one expedition can no longer be the
## same size, so they can no longer be the same floor.
const SPINE_PER_FLOOR: int = 2
## Nodes on an alternate arm ⟨tune⟩. At least two, so the quiet route is
## genuinely longer than the held one — that length difference *is* the trade
## `DES-015` Layer 1 is buying.
const ARM_MIN: int = 2
const ARM_MAX: int = 4
## How many alternate arms a floor may have ⟨tune⟩.
##
## **One was not enough, and the check is what said so.** With a single arm the
## generator emitted 82 distinct topologies from 400 seeds — a floor space a
## player would start recognising inside an evening, which is precisely the
## flatness `DES-015` opens by diagnosing. A second arm is not decoration: it
## turns *"the loop or the shortcut"* into a floor with more than one way to be
## read, and it multiplies the space rather than adding to it.
const ARMS_MIN: int = 1
const ARMS_MAX: int = 2

var _role: PackedInt32Array = PackedInt32Array()
## Edges as `Vector2i(low, high)`, canonical and sorted. See the class note.
var _edges: Array[Vector2i] = []
## The nodes a route may not use if it is to count as a bypass (ADR-032).
var _held: PackedInt32Array = PackedInt32Array()


## Build the graph for one floor of one run.
##
## `run_seed` is the number the host sends; `floor_index` is 0-based depth, so
## the three floors of an expedition are three different graphs from one seed
## rather than the same floor three times.
static func build(run_seed: int, floor_index: int) -> MissionGraph:
	var graph := MissionGraph.new()
	var rng := RandomNumberGenerator.new()
	# Mixed rather than added: `run_seed + floor` and `run_seed' + floor'`
	# collide constantly for adjacent runs, which would make floor 2 of one
	# expedition identical to floor 1 of the next.
	rng.seed = hash("%d:%d:%d" % [run_seed, floor_index, STAGE])

	var spine: int = rng.randi_range(SPINE_MIN, SPINE_MAX) \
		+ SPINE_PER_FLOOR * floor_index
	for i: int in spine:
		graph._role.append(Role.CONNECTIVE)
		if i > 0:
			graph._link(i - 1, i)
	graph._role[0] = Role.ENTRANCE

	# **The first arm is the one the design depends on**, so it is drawn first
	# and separately: the Prize goes inside its span and the ADR-032 bypass is
	# the arm itself. Any further arm is variety, and must not be able to
	# change either of those facts.
	var leave: int = rng.randi_range(0, spine - 3)
	var rejoin: int = rng.randi_range(leave + 2, spine - 1)
	graph._grow_arm(rng, leave, rejoin)

	for extra: int in rng.randi_range(ARMS_MIN, ARMS_MAX) - 1:
		var from: int = rng.randi_range(0, spine - 3)
		var to: int = rng.randi_range(from + 2, spine - 1)
		graph._grow_arm(rng, from, to)

	# **The Prize goes on the spine arm, and the arm becomes the held one.**
	# Not on the new arm: the spine is the route a player takes if they do
	# nothing clever, and `DES-015` wants the greedy line to be the dangerous
	# one so that the quiet route is a decision rather than a default.
	var prize: int = rng.randi_range(leave + 1, rejoin - 1)
	graph._role[prize] = Role.PRIZE
	for node: int in range(leave + 1, rejoin):
		graph._held.append(node)

	# **The Shaft is beyond the rejoin, or at it.** ADR-015 wants it at a
	# deliberately inconvenient node; past the join means both arms reach it,
	# which is what keeps the ADR-032 bypass true by construction rather than
	# by luck — and `problems()` still checks, because "by construction" is a
	# claim about code that changes.
	# On the **spine** at or past the rejoin. The first draft indexed the whole
	# node list and picked `size() - 1`, which is the last node of the *arm* —
	# inside the cycle rather than beyond it, so the bypass it was supposed to
	# guarantee ran through the arm it was supposed to avoid.
	graph._role[rng.randi_range(rejoin, spine - 1)] = Role.SHAFT
	graph._edges.sort()
	return graph


func _link(a: int, b: int) -> void:
	_edges.append(Vector2i(mini(a, b), maxi(a, b)))


## A chain of new nodes joining two existing ones, which is what makes a cycle.
##
## Takes the `rng` rather than reaching for one: `DES-015` requires a single
## stream per pipeline stage, and a helper that seeded its own would be a second
## stream in the same stage — reproducible in isolation and desynced the moment
## the caller drew a different number of values first.
func _grow_arm(rng: RandomNumberGenerator, from: int, to: int) -> void:
	var previous: int = from
	for i: int in rng.randi_range(ARM_MIN, ARM_MAX):
		var id: int = _role.size()
		_role.append(Role.CONNECTIVE)
		_link(previous, id)
		previous = id
	_link(previous, to)


func size() -> int:
	return _role.size()


## The single node holding a role, or -1. Roles that appear once are the ones
## worth asking for by name.
func node_with(role: Role) -> int:
	for id: int in _role.size():
		if _role[id] == role:
			return id
	return -1


func is_held(node: int) -> bool:
	return _held.has(node)


func neighbours(node: int) -> PackedInt32Array:
	var found := PackedInt32Array()
	for edge: Vector2i in _edges:
		if edge.x == node:
			found.append(edge.y)
		elif edge.y == node:
			found.append(edge.x)
	return found


## Everything reachable from `from`, optionally refusing to pass through
## `avoiding`. The second argument is what makes the ADR-032 bypass a question
## this class can answer rather than an aspiration in a document.
func reachable(from: int, avoiding: PackedInt32Array = PackedInt32Array()) -> PackedInt32Array:
	var seen := PackedInt32Array([from])
	var queue := PackedInt32Array([from])
	while not queue.is_empty():
		var at: int = queue[0]
		queue.remove_at(0)
		for next: int in neighbours(at):
			if seen.has(next) or avoiding.has(next):
				continue
			seen.append(next)
			queue.append(next)
	return seen


## Is there a way round the held arm to the Shaft? (ADR-032)
func has_bypass() -> bool:
	var shaft: int = node_with(Role.SHAFT)
	var entrance: int = node_with(Role.ENTRANCE)
	if shaft < 0 or entrance < 0:
		return false
	return reachable(entrance, _held).has(shaft)


## Does the floor actually loop? `DES-015` Layer 1 is the whole reason this
## file exists, and a graph with no cycle is a tree wearing its name.
##
## Counted rather than searched: a connected graph is a tree exactly when it
## has `n - 1` edges, so anything more is a cycle. Cheaper than a traversal and
## it cannot be fooled by the order the edges happen to be in.
func has_cycle() -> bool:
	return _edges.size() >= _role.size()


## `DES-015` step 8, the half that is a graph question.
##
## **Not optional**, in the document's own words: *"a generator without a
## validation pass ships soft-locks."* Every entry here is a floor a player
## could be given that could not be finished, or could be finished without a
## decision — and the second failure is the quieter one, because it produces a
## floor that works and is boring.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	var entrance: int = node_with(Role.ENTRANCE)
	var prize: int = node_with(Role.PRIZE)
	var shaft: int = node_with(Role.SHAFT)

	if entrance < 0:
		found.append("no entrance — nobody can arrive")
		return found
	if prize < 0:
		found.append("no Prize node — the floor poses no question")
	if shaft < 0:
		found.append("no Shaft — the floor has no way out, which is a "
			+ "soft-lock and the failure `DES-015` step 8 exists for")

	var from_entrance: PackedInt32Array = reachable(entrance)
	if shaft >= 0 and not from_entrance.has(shaft):
		found.append("the Shaft is not reachable from the entrance")
	if prize >= 0 and not from_entrance.has(prize):
		found.append("the Prize is not reachable from the entrance")
	if from_entrance.size() != _role.size():
		found.append("%d node(s) are cut off from the entrance"
			% (_role.size() - from_entrance.size()))

	if not has_cycle():
		found.append("the floor is a tree, not a cycle — the way back is the "
			+ "way in, and `DES-015` Layer 1 is the reason this generator "
			+ "exists at all")
	if not has_bypass():
		found.append("no route to the Shaft avoids the held arm — ADR-032 "
			+ "wants a way out that does not go through the danger, and "
			+ "without one the Prize is a toll rather than a choice")
	if _held.is_empty():
		found.append("nothing on this floor is held, so there is no route "
			+ "worth avoiding and the cycle costs the player nothing")
	return found


## A stable one-line fingerprint, for `--graph-probe` and for the day this
## feeds `WorldHash`. Roles and edges only: two graphs that differ in neither
## are the same floor regardless of how they were built.
func digest() -> String:
	var parts := PackedStringArray()
	for id: int in _role.size():
		parts.append("%d:%d" % [id, _role[id]])
	for edge: Vector2i in _edges:
		parts.append("%d-%d" % [edge.x, edge.y])
	return "%d|%s" % [parts.size(), "|".join(parts)]
