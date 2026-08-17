class_name WorldItem
extends Node3D

## One item lying in the world, waiting to be picked up (`M2-T01`, `DES-008`).
##
## This is the room set's Prize, generalised. `M1-T03` built a gold box that
## added 16 kg of nothing and a playtester asked what they were supposed to do
## with it — ADR-064's complaint about stubs, arriving as feedback. It is now
## an `ItemResource` with a name, a weight, a footprint and a tribute value,
## and the hand-rolled pickup path it used to carry **moved here rather than
## being copied** (the ADR-073 rule): there is one loot path and the room set
## has no loot code left in it at all.
##
## ## Host-authoritative, and pickup is a host-validated request
##
## `TEC-004` and ADR-082. The logic lives on `Player`, because reach and the
## bag are both the player's — what lives here is the thing being reached for,
## its identity, and how to find the nearest one.
##
## Spawned through `CoopSession` like every other actor, so a client builds its
## copy from the same payload and derives the same node name. Names have to
## match across peers or the pickup RPC addresses a different object on each.
##
## **No `MultiplayerSynchronizer`.** A dropped item does not move, so its
## position rides the spawn packet and costs nothing thereafter. Despawn
## replicates from `queue_free()` on the host, which is what makes two players
## lunging for the same thing resolve correctly: the second request arrives to
## find the node already gone.
##
## A **thrown** item does move, and still has no synchroniser: its whole flight
## is a parabola determined by the launch velocity in the spawn payload, so
## every peer integrates the same arc from the same numbers and nobody sends a
## position. Peers can drift by centimetres where a wall stops it, and that is
## harmless — the host's copy is the one that decides pickups and the one the
## Gullsjúkr reads. Replicating the flight would spend bandwidth per frame on
## an object whose resting place is the only thing anyone acts on.

const GROUP: StringName = &"world_items"

## Metres per grid cell when blocking out the mesh. An item's `grid_size` is
## its bulk (`DES-019`), so reading bulk off the floor before you pick it up is
## free and it is the information the decision actually needs.
const METRES_PER_CELL: float = 0.28
const MINIMUM_EXTENT: float = 0.18

## Blockout colours by tag (ADR-046 — a named production phase, not a stub).
## Data names a tag and code reacts, which is `TEC-006` principle 1: the
## palette is not in the `.tres` and the item does not know it is being drawn.
## `ART-005` spends saturated colour on treasure, so glitter is the warm one.
const TAG_COLOURS: Dictionary = {
	&"glitter": Color(0.85, 0.66, 0.22),
	&"relic": Color(0.72, 0.44, 0.78),
	&"gear": Color(0.62, 0.63, 0.66),
	&"material": Color(0.45, 0.40, 0.34),
}
const DEFAULT_COLOUR: Color = Color(0.55, 0.54, 0.52)

## Metres per second lost to the floor on landing, and the height below which
## it is simply at rest. A thrown purse should stop where it lands rather than
## skitter — `DES-017` has the Hunter stooping to *pick it up*, which needs it
## to be somewhere specific.
const REST_HEIGHT: float = 0.0

## Set before the node enters the tree, by `CoopSession`, on every peer.
var item_id: StringName = &""
## Launch velocity, also from the spawn payload. Zero for a dropped item, which
## is why drop and throw are one code path with one difference.
var launch: Vector3 = Vector3.ZERO

## **Did a player just put this here?** Only disturbed gold baits the Gullsjúkr
## (`DES-017`), and the distinction turned out to be load-bearing.
##
## Without it, every piece of authored floor loot is an irresistible bait, and
## `--hunt-probe` caught the consequence immediately: the Hunter spent the
## entire run walking between treasures and never hunted anybody. A pursuer
## doing a shopping round is not a pursuer.
##
## The fix is also the better fiction. It has been down there for years and the
## altar-plate has been sitting on its plinth the whole time — it never took
## that. What draws it is *someone handling wealth*: gold that has been picked
## up, gold that is going somewhere, gold that is about to become a Tithe that
## is not its own. That is its entire psychology, and it means baiting works
## because you **gave something up**, not because gold was nearby.
var disturbed: bool = false

var _definition: ItemResource = null
var _mesh: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _velocity: Vector3 = Vector3.ZERO
var _flying: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	_velocity = launch
	_flying = not launch.is_zero_approx()
	set_physics_process(_flying)
	_definition = ItemCatalogue.by_id(item_id)
	if _definition == null:
		# A spawn naming an item this build does not have. Loud, because it
		# means the two peers disagree about what exists, and silent divergence
		# between peers is the expensive kind of bug.
		push_error("world item spawned with unknown id '%s'" % item_id)
		return
	_build_mesh()


func definition() -> ItemResource:
	return _definition


## True while it is still in the air. The Gullsjúkr ignores a bait it cannot
## pick up yet, so a purse thrown *over* it does not stop it mid-stride.
func in_flight() -> bool:
	return _flying


## Integrate the arc. Runs on every peer from the same launch velocity, so no
## position is ever sent — see the note at the top of this file.
##
## `move_and_collide` needs a body; this is a `Node3D`, so the sweep is a
## shapecast-free raycast along the step. That is enough for a thrown purse: it
## stops at the first wall or floor it meets, which is all `DES-017`'s bait
## needs it to do. A bouncing, rolling item would be a physics toy, and
## `CLAUDE.md`'s anti-goals rule that out explicitly.
func _physics_process(delta: float) -> void:
	_velocity.y -= Config.tuning.gravity * delta
	var step: Vector3 = _velocity * delta
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position, global_position + step)
	query.collision_mask = CollisionLayers.WORLD
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		global_position += step
		return
	# Land just clear of the surface, so the next frame's ray does not start
	# inside it and report an immediate second hit.
	global_position = (hit["position"] as Vector3) + (hit["normal"] as Vector3) * 0.02
	global_position.y = maxf(global_position.y, REST_HEIGHT)
	_velocity = Vector3.ZERO
	_flying = false
	set_physics_process(false)


## Bulk, as a box. A 3x3 altar-plate is visibly a shield-sized slab and a 1x1
## gemstone is visibly nothing, so the weight-versus-space trade is legible
## from across the room rather than only once it is in the bag.
func _build_mesh() -> void:
	var footprint: Vector2i = _definition.grid_size
	var mesh := BoxMesh.new()
	mesh.size = Vector3(
		maxf(footprint.x * METRES_PER_CELL, MINIMUM_EXTENT),
		maxf(minf(footprint.x, footprint.y) * METRES_PER_CELL, MINIMUM_EXTENT),
		maxf(footprint.y * METRES_PER_CELL, MINIMUM_EXTENT))
	_material = StandardMaterial3D.new()
	_material.albedo_color = _colour()
	_material.roughness = 0.4
	_mesh = MeshInstance3D.new()
	_mesh.mesh = mesh
	_mesh.material_override = _material
	_mesh.position.y = mesh.size.y * 0.5
	add_child(_mesh)


## The blockout colour for an item, wherever it is being drawn. `BagScreen`
## calls this too, so **the colour a thing is on the floor is the colour it is
## in your bag** — one palette, one authority, and no chance of the two
## drifting the first time either is tuned (the ADR-073 rule).
static func colour_for(item: ItemResource) -> Color:
	for tag: StringName in item.tags:
		if TAG_COLOURS.has(tag):
			return TAG_COLOURS[tag] as Color
	return DEFAULT_COLOUR


func _colour() -> Color:
	return colour_for(_definition)


## Pulse while a player is close enough to take it. A prompt needs the HUD that
## `M4-T05` builds; the object drawing attention to itself is free, needs no
## text, and therefore needs no per-device glyph (`DES-019` rule 7).
func highlight(on: bool) -> void:
	if _material == null:
		return
	var pulse: float = 1.0
	if on:
		pulse = 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.25
	_material.albedo_color = _colour() * pulse


## The nearest takeable item within `radius`, or `null`.
##
## A static group query rather than an `Area3D` per item: at M2 there are a
## handful of items in a level, and this keeps the reach test in one place —
## the same place the host re-runs it when it decides whether the request was
## honest.
static func nearest(from: Node, at: Vector3, radius: float) -> WorldItem:
	var best: WorldItem = null
	var best_distance: float = radius
	for node: Node in from.get_tree().get_nodes_in_group(GROUP):
		var item := node as WorldItem
		if item == null or not item.is_inside_tree():
			continue
		var distance: float = item.global_position.distance_to(at)
		if distance <= best_distance:
			best = item
			best_distance = distance
	return best
