class_name FloorPopulation
extends RefCounted
## `M4-T02` step 7 — which archetype each of a floor's bodies is (ADR-237).
##
## Reads a floor's posts against its biome's `PopulationResource`. Posts are one
## per held room, in graph order (`FloorAnchors.posts`); each is the **door** into
## the guarded arm, a **wide** room a slinger can throw across, or **ordinary**.
##
## ## Every answer is a function of the body's index
##
## `RoomSet._spawn_enemies` grows a floor by index as a party arrives, and body
## *n* has to be the same body however many people the floor grew for — the
## reason the ring is by index. So the bodies past the last post, the ones a
## party or a rank stacks around the posts, are all ordinary, and which ordinary
## body rings is counted over the indices before it. Four of a Hall-Warden at one
## door would be a different encounter rather than a scaled one, which is
## `FloorSource.guardian`'s argument one room over.

enum Post {
	ORDINARY,  ## Rank and file, one in `ringer_every` a Bellringer.
	DOOR,      ## The door into the guarded arm: the Hall-Warden's.
	WIDE,      ## A room big enough to throw across: a Sling-Wretch's.
}

var _rules: PopulationResource = null
## A `Post` per post, in post order.
var _posts: Array[int] = []
## The held room whose door the Warden holds, or -1.
var _door_node: int = -1
var _door_index: int = -1


## A generated floor: its held rooms read against `rules` at `floor_index`.
static func of(plan: FloorPlan, graph: MissionGraph, floor_index: int,
		rules: PopulationResource) -> FloorPopulation:
	var made := FloorPopulation.new()
	made._rules = rules
	var held: Array[int] = []
	for node: int in graph.size():
		if graph.is_held(node):
			held.append(node)
	# **The Bellringer keeps a post** (ADR-237, the developer's call after the
	# census). Every floor with a post keeps one ordinary, so ADR-234's promise
	# holds — a floor with nothing that can call it has no fourth rung. So the
	# Warden needs a second guarded room to stand in, and slingers never take
	# the last ordinary post. Before this, solo, 22 second floors in 40 and 26
	# third floors in 40 had no Bellringer at all.
	if floor_index >= rules.warden_from_floor and held.size() >= 2:
		made._door_node = _nearest_to_entrance(graph, held)
	var spare: int = held.size() - (1 if made._door_node >= 0 else 0) - 1
	var slung: Array[int] = _widest(plan, held, made._door_node,
		rules.slinger_room(floor_index), mini(rules.slinger_cap(floor_index), spare))
	for node: int in held:
		if node == made._door_node:
			made._door_index = made._posts.size()
			made._posts.append(Post.DOOR)
		elif slung.has(node):
			made._posts.append(Post.WIDE)
		else:
			made._posts.append(Post.ORDINARY)
	return made


## **The largest rooms that qualify, `cap` of them** (ADR-237): great rooms
## before halls, and a lower room index first between two of a size, so one seed
## always chooses the same rooms. Never the Warden's.
static func _widest(plan: FloorPlan, held: Array[int], door: int, smallest: int,
		cap: int) -> Array[int]:
	var chosen: Array[int] = []
	if smallest < 0 or cap <= 0:
		return chosen
	var candidates: Array = []
	for node: int in held:
		if node == door:
			continue
		var module: RoomModule = RoomCatalogue.by_id(plan.module_of(node))
		if module != null and module.volume >= smallest:
			candidates.append([module.volume, node])
	candidates.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	for row: Array in candidates.slice(0, cap):
		chosen.append(int(row[1]))
	return chosen


## A floor with posts and no rooms to read — the Deep, which is floor one's
## population and nothing else: every post ordinary.
static func plain(post_count: int, rules: PopulationResource) -> FloorPopulation:
	var made := FloorPopulation.new()
	made._rules = rules
	for index: int in post_count:
		made._posts.append(Post.ORDINARY)
	return made


## The archetype of body `index`, posts first and then the bodies stacked
## around them.
func kind_at(index: int) -> StringName:
	if index < _posts.size():
		if _posts[index] == Post.DOOR:
			return _rules.warden
		if _posts[index] == Post.WIDE:
			return _rules.slinger
	var ordinary_before: int = 0
	for earlier: int in index:
		if earlier >= _posts.size() or _posts[earlier] == Post.ORDINARY:
			ordinary_before += 1
	return _rules.ringer if ordinary_before % _rules.ringer_every == 0 \
		else _rules.rank_and_file


func guardian() -> StringName:
	return _rules.guardian


## What post `index` is, or `ORDINARY` past the last post.
func post(index: int) -> Post:
	return _posts[index] as Post if index < _posts.size() else Post.ORDINARY


## Which post is the door, and which room's door it holds; -1 for none.
func door_index() -> int:
	return _door_index


func door_node() -> int:
	return _door_node


## The held room fewest rooms from the entrance, lowest index on a tie.
static func _nearest_to_entrance(graph: MissionGraph, held: Array[int]) -> int:
	if held.is_empty():
		return -1
	var entrance: int = graph.node_with(MissionGraph.Role.ENTRANCE)
	var hops: Dictionary = {entrance: 0}
	var queue: Array[int] = [entrance]
	while not queue.is_empty():
		var at: int = queue.pop_front()
		for next: int in graph.neighbours(at):
			if not hops.has(next):
				hops[next] = int(hops[at]) + 1
				queue.append(next)
	var best: int = -1
	for node: int in held:
		if not hops.has(node):
			continue
		if best < 0 or int(hops[node]) < int(hops[best]):
			best = node
	return best
