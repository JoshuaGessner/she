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
	# An ember first, whatever else it is. `DES-012` makes it *"a piece of her
	# fire"* and `DES-019` builds the whole Ear out of the same image, so it
	# reads as the one thing on the floor that used to be a person.
	&"ember": Color(0.95, 0.42, 0.16),
	&"glitter": Color(0.85, 0.66, 0.22),
	&"relic": Color(0.72, 0.44, 0.78),
	&"gear": Color(0.62, 0.63, 0.66),
	&"material": Color(0.45, 0.40, 0.34),
}
const DEFAULT_COLOUR: Color = Color(0.55, 0.54, 0.52)

## One per party seat (`DES-012` targets four). **Never hue alone** — `DES-018`
## bans that outright, ~8% of men cannot use it, and four embers on a floor is
## exactly the case where a player has to answer *whose is that* at a glance.
##
## So each seat differs in **three** ways at once: hue, **value**, and a
## **countable** number of motes ringing it. Any one of the three answers the
## question on its own; in monochrome the count still does.
##
## **All four stay in the fire family, and that is deliberate.** `DES-012` calls
## the ember *"a piece of her fire"*, and `ART-005` spends saturated colour on
## treasure — four arbitrary hues would break the fiction *and* the colour
## budget in one go. So the seats are a **value ramp** through the same fire:
## deep ember red, orange, amber, pale gold. That reads as four embers rather
## than four team colours, and it separates further in greyscale than a rainbow
## does — 0.20 of luminance between neighbours, against 0.07 for the first
## palette this had, which passed its own check and was wrong anyway.
##
## These become the class silhouette at `M3-T02` (`DES-020` — teammates read
## your loadout across a room). Until there are classes to look at, the seat is
## what there is.
const EMBER_SEATS: Array[Color] = [
	Color(0.62, 0.16, 0.05),
	Color(0.88, 0.36, 0.08),
	Color(0.96, 0.62, 0.18),
	Color(1.00, 0.86, 0.52),
]
const EMBER_RADIUS: float = 0.30
const MOTE_RADIUS: float = 0.075
const MOTE_ORBIT: float = 0.46

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

## The peer whose ember this is, or `0`. Carried through to `ItemInstance` on
## pickup, because a shared `ItemResource` cannot possibly answer *whose*.
var bound_to: int = 0

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
	if _definition != null and _definition.tags.has(&"ember"):
		_build_ember()
		return
	if _definition == null:
		# A spawn naming an item this build does not have. Loud, because it
		# means the two peers disagree about what exists, and silent divergence
		# between peers is the expensive kind of bug.
		push_error("world item spawned with unknown id '%s'" % item_id)
		return
	_build_mesh()


func definition() -> ItemResource:
	return _definition


## Whose life this carries, or `0`. Only the ember uses it (`DES-012`), and it
## rides through `ItemInstance.bound_to` into the bag of whoever picks it up —
## which is how a rescue knows *who* was rescued.
func bind_to(peer: int) -> void:
	bound_to = peer


func bound() -> int:
	return bound_to


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


## Whose ember this is, drawn so it can be answered from across a room and
## with the colour taken out (`M2-T05`, `DES-018`).
##
## A sphere rather than a box, so an ember never reads as loot at a glance, and
## `seat + 1` motes ringing it, so the answer survives monochrome. `DES-018`'s
## rule is *shape and motion first, colour second* and this is what that costs:
## three cheap primitives instead of one.
func _build_ember() -> void:
	var seat: int = ember_seat()
	var tint: Color = ember_colour(seat)

	var mesh := SphereMesh.new()
	mesh.radius = EMBER_RADIUS
	mesh.height = EMBER_RADIUS * 2.0
	_material = StandardMaterial3D.new()
	_material.albedo_color = tint
	# It is a light, and it is going out — which is the whole of `DES-012`'s
	# window, said without a word of UI.
	#
	# **Weak emission, and that is the fix rather than the flourish.** At 1.4x
	# every seat clipped to the same saturated orange and the value ramp this
	# palette is built on vanished; four embers side by side were
	# indistinguishable. Emission scaled *by* the seat's own brightness keeps
	# the ramp instead of flattening it, so the dim one glows dimly.
	_material.emission_enabled = true
	_material.emission = tint
	_material.emission_energy_multiplier = 0.30 + tint.get_luminance() * 0.55
	_mesh = MeshInstance3D.new()
	_mesh.mesh = mesh
	_mesh.material_override = _material
	_mesh.position.y = EMBER_RADIUS + 0.1
	add_child(_mesh)

	# Countable, and the count *is* the identity. Seat 0 gets one mote, seat 3
	# gets four — legible in a grey screenshot, legible to a colour-blind
	# player, and legible at the distance you first see a body on the floor.
	#
	# **Dark and unlit**, against a glowing core. The first version made them
	# the same emissive material as the ember and they disappeared into it;
	# beads that read as *notches* count far better than sparks that read as
	# bloom. They also ride above the ember rather than around its equator, so
	# the count survives being seen from any angle.
	var beads := StandardMaterial3D.new()
	beads.albedo_color = Color(0.09, 0.07, 0.06)
	beads.roughness = 0.9
	var motes: int = seat + 1
	for index: int in range(motes):
		var mote := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = MOTE_RADIUS
		ball.height = MOTE_RADIUS * 2.0
		mote.mesh = ball
		mote.material_override = beads
		var angle: float = TAU * float(index) / float(motes)
		mote.position = Vector3(cos(angle) * MOTE_ORBIT,
			EMBER_RADIUS * 2.0 + 0.16, sin(angle) * MOTE_ORBIT)
		add_child(mote)


## The party seat this ember belongs to, or `0` when nothing bound it.
func ember_seat() -> int:
	return maxi(0, Player.slot_for_peer(self, bound_to))


static func ember_colour(seat: int) -> Color:
	return EMBER_SEATS[posmod(seat, EMBER_SEATS.size())]


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
