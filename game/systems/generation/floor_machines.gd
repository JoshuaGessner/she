class_name FloorMachines
extends RefCounted
## `M4-T01` step 6 — situations stamped into rooms (`DES-015` Layer 3, ADR-192).
##
## `FloorPlan` decides the shape of a floor and `FloorAnchors` decides where
## things stand in it. Neither decides whether a room **means** anything. Before
## this, every room on a generated floor was space with loot dealt into it by
## worth — correct, deterministic, and asking nothing.
##
## `DES-015` Layer 3 is Brogue's answer: *"pre-authored situations, not
## geometry, stamped procedurally into generated space,"* under one rule —
## **every machine poses a question the player answers with an action.**
##
## ## It decides which room, never what the room contains
##
## The same split every stage before it keeps. This picks nodes and machines;
## `MachineResource` says how many fallen, bodies and items; `DelvingsFloor`
## draws the items from the worth-sorted pool; `FloorBuilder` raises the marks.
## No file here names an item, and `M4-T17` is the task that earns the right to.
##
## ## Three rooms the mission owns, and a machine may never take them
##
## - **The entrance** — a run starts by standing in it. A situation there is one
##   the player walks into before the floor has begun, and `DES-015` step 5's
##   whole read-it-as-you-descend argument needs somewhere to descend *from*.
## - **The Prize** — it already carries the Guardian, which `FloorSource` calls
##   a machine in as many words. Two situations in one room is neither.
## - **The Shaft** — the way down. A situation on the exit is one the player
##   meets while leaving, which is the moment `DES-005` has already spent.
##
## Enforced here rather than trusted to the corpus, because a `.tres` claiming
## `Role.SHAFT` is a data error a designer can make at four in the afternoon and
## a floor that stamps one is a floor that reads wrong for a reason nobody can
## see. `MachineResource.validate()` refuses the two it can catch statically;
## this refuses all three at the point of use.
##
## ## Determinism
##
## Its own stream, seeded from the run seed, floor index and stage number, so it
## cannot consume another stage's numbers or be shifted by a change to how many
## values one of them drew (`DES-015`, `TEC-004`).
##
## Every candidate list is built in a fixed order and drawn from by index —
## `TEC-007` §1: never let a decision depend on the order a collection happened
## to be built in. Nodes walk the graph in index order and machines walk
## `MachineCatalogue.all()`, which sorts by id.


## `DES-015` pipeline step 6. One stream per stage, never shared.
const STAGE: int = 6

## The largest share of a floor's eligible rooms that may carry a situation
## ⟨tune⟩.
##
## **A floor where every room is a machine has no machines.** The reading only
## works against quiet: `FloorPlan.THEME_WEIGHT`'s comment makes the same
## argument one layer down — *"neutral rooms are the quiet between the
## evidence."* A situation is evidence, and it needs more quiet than the theme
## weighting does.
##
## At a third, a six-room floor carries one or two. That is a guess against
## nothing and it is marked as one; the playtest that answers it is the stranger
## session, whose *"reaches an exit having entered ≤4 rooms"* clause is a
## measurement of exactly how much of a floor a person walks into.
const SHARE: float = 0.34

## Floors with fewer eligible rooms than this carry no machine at all.
##
## Below it, `SHARE` rounds to one and that one is a large fraction of what the
## player sees — so the smallest floors would be the most machine-dense, which
## is backwards.
const MIN_ROOMS: int = 3

var _graph: MissionGraph = null
var _plan: FloorPlan = null
## node index → `MachineResource`. Sparse: most rooms carry nothing.
var _stamped: Dictionary = {}


## Stamp `plan`. `machines` is normally `MachineCatalogue.all()`; it is a
## parameter so a probe can pin a corpus rather than depend on what is on disk —
## the same reason `FloorPlan.build` takes its modules.
static func of(plan: FloorPlan, graph: MissionGraph, run_seed: int,
		floor_index: int,
		machines: Array[MachineResource] = []) -> FloorMachines:
	var stamped := FloorMachines.new()
	stamped._graph = graph
	stamped._plan = plan
	var corpus: Array[MachineResource] = machines
	if corpus.is_empty():
		corpus = MachineCatalogue.all()
	var rng := RandomNumberGenerator.new()
	rng.seed = MissionGraph._mix(
		MissionGraph.stage_seed(run_seed, floor_index) + STAGE)
	stamped._stamp(rng, corpus, floor_index)
	return stamped


func _stamp(rng: RandomNumberGenerator, corpus: Array[MachineResource],
		floor_index: int) -> void:
	var eligible: PackedInt32Array = _eligible()
	if eligible.size() < MIN_ROOMS:
		return
	var wanted: int = int(floor(float(eligible.size()) * SHARE))
	if wanted <= 0:
		return
	# **Rooms are drawn, not walked.** Taking the first `wanted` eligible nodes
	# would put every situation nearest the entrance, because `_eligible` walks
	# the graph in index order and `MissionGraph.build` numbers outward from it.
	# The shuffle is over a list built in a fixed order, so it is a choice
	# rather than an accident (`TEC-007` §1).
	var order: Array[int] = []
	for node: int in eligible:
		order.append(node)
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = order[i]
		order[i] = order[j]
		order[j] = swap
	for node: int in order:
		if _stamped.size() >= wanted:
			return
		var options: Array[MachineResource] = _options(corpus, node, floor_index)
		if options.is_empty():
			continue
		_stamped[node] = options[rng.randi_range(0, options.size() - 1)]


## Rooms a situation may be stamped into: everything the mission does not own,
## and nothing you have to crouch through.
func _eligible() -> PackedInt32Array:
	var out := PackedInt32Array()
	var spoken_for: Array[int] = [
		_graph.node_with(MissionGraph.Role.ENTRANCE),
		_graph.node_with(MissionGraph.Role.PRIZE),
		_graph.node_with(MissionGraph.Role.SHAFT),
	]
	for node: int in _graph.size():
		if spoken_for.has(node):
			continue
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		if module == null or module.volume == RoomModule.Volume.CRAWL:
			continue
		out.append(node)
	return out


## Which machines could stand in `node`'s room, in catalogue order.
func _options(corpus: Array[MachineResource], node: int,
		floor_index: int) -> Array[MachineResource]:
	var out: Array[MachineResource] = []
	var role: int = _graph._role[node]
	var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
	var held: bool = _graph.is_held(node)
	for machine: MachineResource in corpus:
		if machine.fits(role, module, held, floor_index):
			out.append(machine)
	return out


## The nodes carrying a situation, **in ascending order** so any two callers
## enumerate them identically.
func nodes() -> PackedInt32Array:
	var out := PackedInt32Array()
	for node: int in _stamped.keys():
		out.append(node)
	out.sort()
	return out


## What stands in `node`, or `null` if the room is quiet.
func at(node: int) -> MachineResource:
	return _stamped.get(node, null)


func count() -> int:
	return _stamped.size()


## Whatever makes this stamping wrong, or an empty list. The Spelunky pattern
## `TEC-007` §2.5 takes and every stage here follows: **guarantee by
## construction, then assert anyway.**
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	var entrance: int = _graph.node_with(MissionGraph.Role.ENTRANCE)
	var prize: int = _graph.node_with(MissionGraph.Role.PRIZE)
	var shaft: int = _graph.node_with(MissionGraph.Role.SHAFT)
	for node: int in nodes():
		var machine: MachineResource = _stamped[node]
		if node == entrance:
			out.append(("`%s` was stamped on the entrance — a run starts by "
				+ "standing in it") % machine.id)
		if node == prize:
			out.append(("`%s` was stamped on the Prize, which already carries "
				+ "the Guardian") % machine.id)
		if node == shaft:
			out.append("`%s` was stamped on the Shaft, which is the way out"
				% machine.id)
		var module: RoomModule = RoomCatalogue.by_id(_plan.module_of(node))
		if module == null:
			out.append("`%s` stands in room %d, which seated no module"
				% [machine.id, node])
			continue
		if module.volume < machine.min_volume:
			out.append(("`%s` needs a %s and room %d is a %s")
				% [machine.id, machine.min_volume, node, module.volume])
	return out


## A short, stable fingerprint of what was stamped where, for the determinism
## harness. Two peers handed the same seed must agree about this as exactly as
## they agree about geometry (`TEC-004`) — a floor whose *rooms* match and whose
## *situations* do not is two different floors wearing one layout.
func digest() -> String:
	var parts := PackedStringArray()
	for node: int in nodes():
		parts.append("%d:%s" % [node, _stamped[node].id])
	return ",".join(parts)
