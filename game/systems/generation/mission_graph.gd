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
## ## The catalogue, and why one cycle was not enough (`TEC-007`, ADR-170)
##
## The first version of this file built exactly one shape: a spine, one arm
## rejoining it, the Prize inside the arm's span and the Shaft beyond the
## rejoin. It emitted 308 distinct graphs from 400 seeds and the check was
## satisfied — but 308 *digests* is not 308 *floors*. There was no branch in
## `build()` that could produce a second kind of topology, so every one of them
## was the same floor with different numbers in it. That is `DES-015`'s own
## diagnosis of Dark and Darker, one level up the stack: the randomness was in
## the stuff, not the space.
##
## Dormans' actual contribution is not "put a loop in it" — it is that **the
## type of cycle is the design content.** So a floor now picks a *named* cycle,
## and each one names a question the floor asks:
##
## ```
##   danger-detour   push through the held span, or spend the time going round?
##   foldback        the way out is on the far side — the walk out is new ground
##   lock-and-key    the short way is shut; the opener is down the long way
##   shortcut        a closed span that only ever pays back on the way out
##   nested          the quiet route has a fork of its own (floor 2+)
## ```
##
## `TWO_FRONTED` — both arms held, no safe route — was in `TEC-007` §5.1 and is
## **deliberately absent.** At the graph layer it is either indistinguishable
## from `danger-detour` or it violates ADR-032, which wants a way out that does
## not cross the danger. "The other arm is also dangerous" is a *population*
## property (`DES-015` step 7), not a topology, and putting it here would have
## been a category error dressed as variety.
##
## ## Gates
##
## A **gate** is an edge that exists but cannot be crossed yet. `lock-and-key`
## gates need a `KEY` node; `shortcut` gates open by paying something, and what
## that costs is `DES-015` step 6's business, not this file's. Both are the same
## topological object and are kept apart only where the distinction changes an
## assertion — which it does exactly once, in `problems()`.
##
## ## What a floor is, structurally
##
## A spine from the entrance, and one **alternate arm** rejoining it — the
## minimum that makes a cycle. The Prize sits on the held span and the Shaft
## where the chosen cycle puts it, so both arms reach the way out and only one
## of them is held.
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
## ## Determinism (`TEC-004`, `TEC-007` §5.3)
##
## The host sends a seed and every client builds the identical floor; geometry
## is never replicated, so a divergence here is two players disagreeing about
## where a wall is. `DES-015` requires **one RNG stream per pipeline stage,
## never shared** — so this takes a stream of its own, derived from the run
## seed and the floor index, and touches no global RNG.
##
## Node ids are integers assigned in creation order and edges are stored with
## the lower id first, then sorted. Nothing here iterates a `Dictionary` where
## the order could change an outcome — **and the reason is not the one this
## file used to give.** Measured on Godot 4.7, `Dictionary` iterates in
## *insertion* order, not hash order, so it is not itself a nondeterminism
## source. The hazard is one step back: insertion order is a function of call
## order, so two machines that build the same collection by different paths
## diverge with no hash table involved. Sort by an explicit total order before
## any loop whose order can change a decision (`TEC-007` §1).
##
## The seed mix is **ours** rather than `hash()`. `hash()` is stable within one
## engine build, which is all a desync needs, but it is not a contract across
## versions — and `TEC-001` calls the run seed's shareability non-negotiable, so
## a seed pasted into a bug report has to survive a Godot upgrade. SplitMix64 is
## sixty-four bits of integer arithmetic we control, and `--graph-probe` pins it
## with a known answer.


## What a node is for. The graph carries roles, not contents — *which* machine
## is stamped into the Prize node is `DES-015` step 6 and none of this file's
## business.
enum Role {
	CONNECTIVE,  ## Ordinary space. Most of a floor.
	ENTRANCE,    ## Where the party arrives.
	PRIZE,       ## The Guardian & Prize machine (`DES-015` Layer 3).
	SHAFT,       ## The way down, and out (`DES-005`).
	KEY,         ## Opens a gated span. Never behind its own door.
}

## The named cycle types (`TEC-007` §5.1). The order is the wire order — it is
## in `digest()`, so inserting a value in the middle changes every fingerprint.
## Append, never insert.
enum Cycle {
	DANGER_DETOUR,
	FOLDBACK,
	LOCK_AND_KEY,
	SHORTCUT,
	NESTED,
}

## Indexed by `Cycle`. Only for messages and `--graph-probe` output; nothing
## reads these to make a decision.
const CYCLE_NAMES: Array[String] = [
	"danger-detour", "foldback", "lock-and-key", "shortcut", "nested",
]

## Which pipeline stage this is, mixed into the seed so stage 3 and stage 5
## cannot accidentally draw the same numbers from the same run seed.
const STAGE: int = 3

## SplitMix64. `GOLDEN` is 2^64/φ; the other two are Steele et al.'s avalanche
## constants. Written signed because GDScript's `int` is `int64` and the
## unsigned spellings do not fit: 0x9E3779B97F4A7C15, 0xBF58476D1CE4E5B9,
## 0x94D049BB133111EB.
const GOLDEN: int = -7046029254386353131
const MIX_1: int = -4658895280553007687
const MIX_2: int = -7723592293110705685

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
## `nested` needs a floor with room to fold twice, and `DES-015`'s three floors
## are meant to escalate. Floor 0 never gets it ⟨tune⟩.
const NESTED_FROM_FLOOR: int = 1
## `DES-015`: the Shaft is *"reachable, never near the entrance."* Measured in
## edges, on the graph the player can actually walk before opening anything —
## a shortcut that lands beside the entrance must not count ⟨tune⟩.
const SHAFT_MIN_DISTANCE: int = 2

var _role: PackedInt32Array = PackedInt32Array()
## Edges as `Vector2i(low, high)`, canonical and sorted. See the class note.
var _edges: Array[Vector2i] = []
## The nodes a route may not use if it is to count as a bypass (ADR-032).
var _held: PackedInt32Array = PackedInt32Array()
## Which named cycle this floor is. See `Cycle`.
var _cycle: int = Cycle.DANGER_DETOUR
## Gated spans needing a `KEY` node. Canonical and sorted, like `_edges`.
var _key_gates: Array[Vector2i] = []
## Gated spans that open by paying something (`DES-015` step 6 decides what).
var _cost_gates: Array[Vector2i] = []


## One round of SplitMix64. Pure integer arithmetic, so it is the same number on
## every machine and in every engine version — which `hash()` is not.
static func _mix(value: int) -> int:
	var z: int = value + GOLDEN
	z = (z ^ _ushr(z, 30)) * MIX_1
	z = (z ^ _ushr(z, 27)) * MIX_2
	return z ^ _ushr(z, 31)


## Logical (zero-filling) right shift. GDScript's `>>` propagates the sign, and
## SplitMix64's avalanche is wrong without the zero fill — the top bits would
## never mix down. Never called with `bits` of 0.
static func _ushr(value: int, bits: int) -> int:
	return (value >> bits) & ((1 << (64 - bits)) - 1)


## The RNG stream for this stage of this floor of this run.
##
## Mixed rather than added: `run_seed + floor` and `run_seed' + floor'` collide
## constantly for adjacent runs, which would make floor 2 of one expedition
## identical to floor 1 of the next. Chained rather than summed for the same
## reason one level up — `mix(a) + b` and `mix(a') + b'` still collide, so each
## input goes through its own avalanche.
static func stage_seed(run_seed: int, floor_index: int) -> int:
	return _mix(_mix(_mix(run_seed) + floor_index) + STAGE)


static func cycle_name(cycle_type: int) -> String:
	return CYCLE_NAMES[cycle_type]


## Which cycle this floor is, drawn from the types legal at this depth.
static func _choose_cycle(rng: RandomNumberGenerator, floor_index: int) -> int:
	var legal := PackedInt32Array([
		Cycle.DANGER_DETOUR, Cycle.FOLDBACK, Cycle.LOCK_AND_KEY, Cycle.SHORTCUT,
	])
	if floor_index >= NESTED_FROM_FLOOR:
		legal.append(Cycle.NESTED)
	return legal[rng.randi_range(0, legal.size() - 1)]


## Build the graph for one floor of one run.
##
## `run_seed` is the number the host sends; `floor_index` is 0-based depth, so
## the three floors of an expedition are three different graphs from one seed
## rather than the same floor three times.
static func build(run_seed: int, floor_index: int) -> MissionGraph:
	var graph := MissionGraph.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = stage_seed(run_seed, floor_index)

	var spine: int = rng.randi_range(SPINE_MIN, SPINE_MAX) \
		+ floor_index * SPINE_PER_FLOOR
	for i: int in spine:
		graph._role.append(Role.CONNECTIVE)
		if i > 0:
			graph._link(i - 1, i)
	graph._role[0] = Role.ENTRANCE

	graph._cycle = _choose_cycle(rng, floor_index)

	# **The first arm is the one the design depends on**, so it is drawn first
	# and separately: the Prize goes inside its span and the ADR-032 bypass is
	# the arm itself. Any further arm is variety, and must not be able to
	# change either of those facts.
	var leave: int = rng.randi_range(0, spine - 3)
	var rejoin: int = rng.randi_range(leave + 2, spine - 1)
	var arm: PackedInt32Array = graph._grow_arm(rng, leave, rejoin)

	# The held span is the spine between the arm's two ends, in every cycle
	# type. What changes between types is where the way *out* sits relative to
	# it, which is what makes the walk out a different journey each time.
	for node: int in range(leave + 1, rejoin):
		graph._held.append(node)
	graph._role[rng.randi_range(leave + 1, rejoin - 1)] = Role.PRIZE

	match graph._cycle:
		Cycle.FOLDBACK:
			# The way out is on the far side of the loop, so the walk out is
			# new ground rather than a retrace — `DES-005`'s climax, made
			# structural. Drawn from the arm's back half so the Shaft cannot
			# land beside the entrance when the arm leaves from node 0.
			graph._role[arm[rng.randi_range(arm.size() / 2, arm.size() - 1)]] = Role.SHAFT
		Cycle.LOCK_AND_KEY:
			graph._role[rng.randi_range(rejoin, spine - 1)] = Role.SHAFT
			# Shut the short way in and put its opener down the long one. The
			# player must walk the quiet arm *first*, which inverts the usual
			# order of the decision: the detour stops being optional.
			#
			# **Both ends, not one.** Gating only the near end left the held
			# span reachable backwards from the rejoin, so the lock decided
			# nothing — 275 floors in 1200 said so before this line existed.
			# A span has two ends and a seal has to mean both of them.
			graph._gate_with_key(leave, leave + 1)
			graph._gate_with_key(rejoin - 1, rejoin)
			graph._role[arm[rng.randi_range(0, arm.size() - 1)]] = Role.KEY
		Cycle.SHORTCUT:
			var shaft: int = rng.randi_range(rejoin, spine - 1)
			graph._role[shaft] = Role.SHAFT
			# A closed span from the deep end back toward the entrance. It
			# costs something now and saves the entire walk out later, which
			# is the one loop shape that is worth *nothing* on the way in.
			# `near + 2 <= far` always, so it never duplicates a spine edge.
			graph._gate_by_cost(rng.randi_range(0, leave), rng.randi_range(rejoin, spine - 1))
		Cycle.NESTED:
			graph._role[rng.randi_range(rejoin, spine - 1)] = Role.SHAFT
			# A fork inside the quiet route, so the safe way stops being one
			# known corridor. Deep floors only.
			graph._grow_arm(rng, arm[0], arm[arm.size() - 1])
		_:
			graph._role[rng.randi_range(rejoin, spine - 1)] = Role.SHAFT

	# Further arms are variety on top of the chosen type. On a `lock-and-key`
	# floor they must not span *either* gate — an arm around the seal would
	# make the key decorative — so they are drawn wholly beyond the rejoin, or
	# not at all. A range that admits nothing is a constraint doing its job,
	# not a failure, and `problems()` asserts the seal held either way.
	var low: int = rejoin if graph._cycle == Cycle.LOCK_AND_KEY else 0
	for extra: int in rng.randi_range(ARMS_MIN, ARMS_MAX) - 1:
		if low > spine - 3:
			continue
		var from: int = rng.randi_range(low, spine - 3)
		graph._grow_arm(rng, from, rng.randi_range(from + 2, spine - 1))

	graph._edges.sort()
	graph._key_gates.sort()
	graph._cost_gates.sort()
	return graph


func _link(a: int, b: int) -> void:
	_edges.append(Vector2i(mini(a, b), maxi(a, b)))


func _gate_with_key(a: int, b: int) -> void:
	_key_gates.append(Vector2i(mini(a, b), maxi(a, b)))


func _gate_by_cost(a: int, b: int) -> void:
	var edge := Vector2i(mini(a, b), maxi(a, b))
	_cost_gates.append(edge)
	_edges.append(edge)


## A chain of new nodes joining two existing ones, which is what makes a cycle.
## Returns the ids it created, so a caller can hang a nested cycle off them.
##
## Takes the `rng` rather than reaching for one: `DES-015` requires a single
## stream per pipeline stage, and a helper that seeded its own would be a second
## stream whose draws changed whenever the caller drew a different number of
## values first.
func _grow_arm(rng: RandomNumberGenerator, from: int, to: int) -> PackedInt32Array:
	var made := PackedInt32Array()
	var previous: int = from
	for i: int in rng.randi_range(ARM_MIN, ARM_MAX):
		var id: int = _role.size()
		_role.append(Role.CONNECTIVE)
		_link(previous, id)
		made.append(id)
		previous = id
	_link(previous, to)
	return made


func size() -> int:
	return _role.size()


func cycle() -> int:
	return _cycle


## Every span that cannot be crossed until something opens it.
func gates() -> Array[Vector2i]:
	var all: Array[Vector2i] = _key_gates.duplicate()
	all.append_array(_cost_gates)
	all.sort()
	return all


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
	return _neighbours(node, [])


func _neighbours(node: int, blocked: Array[Vector2i]) -> PackedInt32Array:
	var found := PackedInt32Array()
	for edge: Vector2i in _edges:
		if blocked.has(edge):
			continue
		if edge.x == node:
			found.append(edge.y)
		elif edge.y == node:
			found.append(edge.x)
	return found


func _flood(from: int, avoiding: PackedInt32Array,
		blocked: Array[Vector2i]) -> PackedInt32Array:
	var seen := PackedInt32Array([from])
	var queue := PackedInt32Array([from])
	while not queue.is_empty():
		var at: int = queue[0]
		queue.remove_at(0)
		for next: int in _neighbours(at, blocked):
			if seen.has(next) or avoiding.has(next):
				continue
			seen.append(next)
			queue.append(next)
	return seen


## Everything reachable from `from`, optionally refusing to pass through
## `avoiding`. Gates are ignored — this is the floor once it is fully open.
func reachable(from: int, avoiding: PackedInt32Array = PackedInt32Array()) -> PackedInt32Array:
	return _flood(from, avoiding, [])


## Everything reachable before anything is opened. This is the question a gate
## actually poses, and the one `DES-015` step 8 has to ask: no key may sit
## behind its own door, and no Shaft behind any door at all.
func reachable_initially(from: int) -> PackedInt32Array:
	return _flood(from, PackedInt32Array(), gates())


## Edges from the entrance to `node` on the unopened floor, or -1 if it cannot
## be walked to yet.
func distance_from_entrance(node: int) -> int:
	var entrance: int = node_with(Role.ENTRANCE)
	if entrance < 0:
		return -1
	var blocked: Array[Vector2i] = gates()
	var seen := PackedInt32Array([entrance])
	var frontier := PackedInt32Array([entrance])
	var steps: int = 0
	while not frontier.is_empty():
		if frontier.has(node):
			return steps
		var next := PackedInt32Array()
		for at: int in frontier:
			for other: int in _neighbours(at, blocked):
				if seen.has(other):
					continue
				seen.append(other)
				next.append(other)
		frontier = next
		steps += 1
	return -1


## Is there a way round the held arm to the Shaft? (ADR-032)
func has_bypass() -> bool:
	var shaft: int = node_with(Role.SHAFT)
	var entrance: int = node_with(Role.ENTRANCE)
	if shaft < 0 or entrance < 0:
		return false
	return reachable(entrance, _held).has(shaft)


## Is this a cycle at all, or did the generator emit a tree?
##
## Counted rather than searched: a connected graph is a tree exactly when it
## has `n - 1` edges, so anything more is a cycle. Cheaper than a traversal and
## it cannot be fooled by the order the edges happen to be in.
func has_cycle() -> bool:
	return _edges.size() >= _role.size()


## Is there a loop that does not depend on paying for one?
##
## A `shortcut` floor whose only cycle *is* the shortcut would be a tree to any
## player who declines to pay, and `DES-015` Layer 1 is not optional for them.
## Key gates are exempt: their opener is asserted reachable, so that loop is
## deferred rather than conditional.
func has_cycle_without_cost_gates() -> bool:
	return _edges.size() - _cost_gates.size() >= _role.size()


## `DES-015` step 8, the graph half. Everything here is a soft-lock, a broken
## promise to ADR-032, or a floor that poses no question at all.
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
	if not has_cycle_without_cost_gates():
		found.append("the only cycle on this floor is one the player has to "
			+ "pay to open, so anybody who declines gets a tree")
	if not has_bypass():
		found.append("no route to the Shaft avoids the held arm — ADR-032 "
			+ "wants a way out that does not go through the danger, and "
			+ "without one the Prize is a toll rather than a choice")
	if _held.is_empty():
		found.append("nothing on this floor is held, so there is no route "
			+ "worth avoiding and the cycle costs the player nothing")

	# Gates, and the two ways they go wrong: a way out nobody can reach, and a
	# key behind the door it opens.
	var open_now: PackedInt32Array = reachable_initially(entrance)
	if shaft >= 0 and not open_now.has(shaft):
		found.append("the Shaft is only reachable through a gated span, so a "
			+ "party that cannot open it is sealed in")
	if not _key_gates.is_empty():
		var key: int = node_with(Role.KEY)
		if key < 0:
			found.append("a span is locked and no node opens it")
		elif not open_now.has(key):
			found.append("the key is behind the door it opens")
		elif prize >= 0 and open_now.has(prize):
			found.append("the Prize can be reached without opening the "
				+ "locked span, so the lock decides nothing")

	if shaft >= 0:
		var walk: int = distance_from_entrance(shaft)
		if walk >= 0 and walk < SHAFT_MIN_DISTANCE:
			found.append(("the Shaft is %d edge(s) from the entrance — "
				+ "`DES-015` wants it reachable and never near the way in")
				% walk)
	return found


## A stable one-line fingerprint, for `--graph-probe` and for the day this
## feeds `WorldHash`. Roles, edges, gates and the cycle type: two graphs that
## differ in none of them are the same floor regardless of how they were built.
func digest() -> String:
	var parts := PackedStringArray(["c%d" % _cycle])
	for id: int in _role.size():
		parts.append("%d:%d" % [id, _role[id]])
	for edge: Vector2i in _edges:
		parts.append("%d-%d" % [edge.x, edge.y])
	for edge: Vector2i in gates():
		parts.append("g%d-%d" % [edge.x, edge.y])
	return "%d|%s" % [parts.size(), "|".join(parts)]
