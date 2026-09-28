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


## Blockout colours by tag (ADR-046 — a named production phase, not a stub).
## Data names a tag and code reacts, which is `TEC-006` principle 1: the
## palette is not in the `.tres` and the item does not know it is being drawn.
## `ART-005` spends saturated colour on treasure, so glitter is the warm one.
const TAG_COLOURS: Dictionary = {
	# An ember first, whatever else it is. `DES-012` makes it *"a piece of her
	# fire"* and `DES-019` builds the whole Ear out of the same image, so it
	# reads as the one thing on the floor that used to be a person.
	&"ember": EMBER_COLOUR,
	&"glitter": Color(0.85, 0.66, 0.22),
	&"relic": Color(0.72, 0.44, 0.78),
	&"gear": Color(0.62, 0.63, 0.66),
	&"material": Color(0.45, 0.40, 0.34),
}
const DEFAULT_COLOUR: Color = Color(0.55, 0.54, 0.52)

## **Every ember looks the same, and that is the decision** (ADR-094).
##
## An earlier version gave each party seat its own colour and a countable ring
## of motes, so a rescuer could answer *whose is that* across a room. It was
## legible and it was wrong: `DES-012` calls the ember *"a piece of **her**
## fire"*, and four differently-coloured ones read as **team markers** rather
## than as four pieces of the same fire. The person is gone; what is lying on
## the floor is the dragon's.
##
## Nothing legible is actually lost, because the question is already answered
## diegetically — **you know whose it is because you watched them fall there.**
## Position identifies it, for free, with no UI and no colour budget. What the
## ember *carries* is a tag (`bound_to`), and the tag is mechanical rather than
## decorative: it decides whose life the thing saves, and an ember in anyone
## else's hands saves that same person and nobody else.
## Every light that is allowed to be warm (`M2-T13`, ADR-105). `ART-005` gives
## the game one saturated hue and spends it on treasure, her fire and the ember;
## `--sight-probe` fails if anything outside this group is gold, because a warm
## wall sconce would say "valuable" in the only vocabulary the Deep has for it.
const TREASURE_LIGHT_GROUP: StringName = &"treasure_light"

## **What a glitter pool is worth, in light** ⟨tune⟩ (`M4-T23`, ADR-204).
##
## The first value is what the cheapest glitter in the corpus pours; the second
## is what the richest does. Everything between is linear in `tribute_value`,
## because that is the number `M4-T01` step 7 made climb with depth (ADR-193) —
## 8 → 70 → 140 across three floors on ADR-220's table — and `DES-015` Layer 4's second clause is
## that a player must be able to *see* that climb. A constant glow says every
## floor is worth the same, which is the state the gradient was built out of.
##
## The low end is unchanged from `M2-T13`, deliberately: a coin still marks a
## place rather than lighting a room, so *"a treasure that lit its surroundings
## would make the greedy route the easiest one to walk"* still holds of cheap
## loot. What changed is that the sentence stops being true of the Prize, which
## is the one object the design wants you to cross a floor for.
const GLIMMER_ENERGY: Vector2 = Vector2(0.9, 2.6)
const GLIMMER_RANGE: Vector2 = Vector2(4.2, 9.0)

const EMBER_COLOUR: Color = Color(0.95, 0.45, 0.14)
const EMBER_RADIUS: float = 0.30

## Metres per second lost to the floor on landing, and the height below which
## it is simply at rest. A thrown purse should stop where it lands rather than
## skitter — `DES-017` has the Hunter stooping to *pick it up*, which needs it
## to be somewhere specific.
const REST_HEIGHT: float = 0.0

## The inked star on treasure (ADR-267) — see the shader for why it is a star
## and not a flicker of the glimmer light.
const GLINT: Shader = preload("res://art/shaders/glint.gdshader")
## How big the star is, metres across ⟨tune⟩.
const GLINT_SIZE: float = 0.34

## How far a thing in reach floats off the floor, metres ⟨tune⟩. A few
## centimetres: enough that the eye catches it moving, not so much that it
## reads as magic in a game whose floors are honest about weight.
const HOVER: float = 0.05
## How fast it floats up and settles back, per second ⟨tune⟩.
const HOVER_EASE: float = 10.0
## How far a dropped thing falls to the floor, and for how long ⟨tune⟩ — the
## height a hand lets go from, compressed so a panic dump is not a slow drop.
const DROP_HEIGHT: float = 0.45
const DROP_SECONDS: float = 0.32
## How fast a thrown thing turns end over end, radians a second ⟨tune⟩.
const TUMBLE: float = 13.0

## How wide a thrown weapon is in the air, for what it can meet (ADR-227) — an
## arrow's forgiving radius and a little more, because an axe is not a point.
const STRIKE_RADIUS: float = 0.2

## Emitted on the host when a thrown weapon strikes a body, with where it comes
## to rest below the blow (ADR-227). **Signals up**: `CoopSession` owns every
## spawn, so it lays the axe down there and frees this one in flight.
signal struck(rest: Vector3)

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
## **A Scar lies on the floor with the thing it is on** (ADR-225). Off the spawn
## packet with `bound_to` and for the same reason — a shared `ItemResource`
## cannot say *this one* — and read back into the bag by whoever lifts it.
## Without it, setting a Legacy relic down and picking it up made it whole.
var scarred: bool = false
## **Whose throw this is, if it can wound** (ADR-227). The thrower's peer, or `0`
## for everything that is only bait. Set from the spawn packet when a thing with
## a `ThrownTrait` leaves a hand at speed; the host then resolves what it meets
## in the air, and never on the body that threw it.
var thrower: int = 0
## The field a thrown weapon rings into. Handed down by `CoopSession`, as an
## arrow's is, because a level that forgot to pass it should give a silent axe
## rather than a crash.
var _field: ClamorField = null
## **Tribute in Kind** (`hrd_tribute_in_kind`). Set when a Hoard build put this
## down: the Gullsjúkr treats it as worth stopping for whatever it is actually
## worth. A property of the *thing on the floor* rather than of the player,
## because by the time she stoops the player may be a room away — and it
## replicates with the spawn packet for the same reason `disturbed` does.
var worth_stopping_for: bool = false

var _definition: ItemResource = null
var _mesh: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _velocity: Vector3 = Vector3.ZERO
var _flying: bool = false

# ── how it moves when handled (ADR-267) ──────────────────────────────────────
# Everything below is **look, never state**: no position, collider or clock the
# host resolves anything against is touched. Each peer animates its own copy.

## The authored model, and what is drawn under it when it is the one in reach.
var _look: Node3D = null
var _halo: MeshInstance3D = null
## How far the look floats while it is in reach, eased toward its target.
var _lift: float = 0.0
var _highlit: bool = false
## When this process's own player reached for it, for the ghost that follows it
## into the bag — see `_exit_tree`.
var _claimed_msec: int = -1


func _ready() -> void:
	add_to_group(GROUP)
	_velocity = launch
	_flying = not launch.is_zero_approx()
	set_physics_process(_flying)
	# Idle until something is in reach — see `_process`. A floor lays hundreds
	# of these and almost all of them are never looked at.
	set_process(false)
	_definition = ItemCatalogue.by_id(item_id)
	if is_ember():
		_build_ember()
		return
	if _definition == null:
		# A spawn naming an item this build does not have. Loud, because it
		# means the two peers disagree about what exists, and silent divergence
		# between peers is the expensive kind of bug.
		push_error("world item spawned with unknown id '%s'" % item_id)
		return
	_build_mesh()
	_build_halo()
	_build_glint()
	# **A thing set down falls the last half-metre** (ADR-267). `disturbed`
	# is exactly *somebody put this here*, which is the only time it arrived
	# from a hand rather than having lain here since the floor was built. A
	# thrown thing lands from its own flight and needs no drop.
	if disturbed and not _flying:
		_fall_into_place(DROP_HEIGHT)


func definition() -> ItemResource:
	return _definition


func bound() -> int:
	return bound_to


## What she would pay for this one: nothing if Scarred (`DES-003`), which is
## `ItemInstance.tribute_worth` asked of the thing on the floor. What the
## Gullsjúkr weighs a bait by and what a pool of glitter pours light by, so a
## Scarred relic set down is neither worth stopping for nor lit like treasure.
func worth() -> int:
	if _definition == null or scarred:
		return 0
	return _definition.tribute_value


## **Is this somebody's fire rather than an object?** (`M2-T21`, ADR-114)
##
## The tag, not `bound_to`, and the difference matters: `ItemInstance.is_ember`
## asks *whose this is* and answers with the binding, while the question here is
## *what kind of thing this is* — which the Gullsjúkr needs before it knows
## whether it may take it. One copy of the test, used by `_ready` to decide how
## to draw it and by the Hunter to decide what it is allowed to do with it.
func is_ember() -> bool:
	return _definition != null and _definition.tags.has(&"ember")


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
	# **A thrown weapon meets a body before the stone behind it** (ADR-227).
	# Host-only, like an arrow: a client's copy is a thing flying, and the blow
	# is the host's decision arriving.
	if thrower != 0 and multiplayer.is_server() and _strike(space, step):
		return
	var query := PhysicsRayQueryParameters3D.create(
		global_position, global_position + step)
	query.collision_mask = CollisionLayers.WORLD
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		global_position += step
		_tumble(delta)
		return
	# Land just clear of the surface, so the next frame's ray does not start
	# inside it and report an immediate second hit.
	global_position = (hit["position"] as Vector3) + (hit["normal"] as Vector3) * 0.02
	global_position.y = maxf(global_position.y, REST_HEIGHT)
	_velocity = Vector3.ZERO
	_flying = false
	set_physics_process(false)
	_land()
	# A thrown axe rings on stone as well as on flesh: a miss still tells the
	# floor where it went.
	if thrower != 0:
		_ring()


## Handed the floor's noise field (ADR-227). Mirrors `Arrow.fly_with`.
func fly_with(field: ClamorField) -> void:
	_field = field


## The first hurtbox inside this step that is not the thrower's, struck once.
## True when it struck, so the flight stops here.
func _strike(space: PhysicsDirectSpaceState3D, step: Vector3) -> bool:
	var hurl: ThrownTrait = _thrown()
	if hurl == null:
		return false
	var ball := SphereShape3D.new()
	ball.radius = STRIKE_RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
	query.transform = Transform3D(Basis.IDENTITY, global_position + step)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = CollisionLayers.ENEMY_HURTBOX | CollisionLayers.PLAYER_HURTBOX
	for found: Dictionary in space.intersect_shape(query, 8):
		var hurtbox := found.get("collider") as Hurtbox
		if hurtbox == null:
			continue
		# Never the hand that threw it — `Arrow._on_hit`'s rule, for the same
		# unexplainable death.
		var body := hurtbox.get_parent() as Player
		if body != null and body.get_multiplayer_authority() == thrower:
			continue
		global_position += step
		hurtbox.receive(hurl.damage, hurl.damage_type, self)
		_ring()
		_velocity = Vector3.ZERO
		_flying = false
		set_physics_process(false)
		struck.emit(_rest_below(space))
		return true
	return false


## The ring (ADR-227): straight into the field at the axe, as an arrow's impact
## is, and not through a `ClamorSource` — the thrower paid their own handling
## noise when it left the hand, and the rest happens over there.
func _ring() -> void:
	var hurl: ThrownTrait = _thrown()
	if hurl == null:
		return
	Foley.at(self, Foley.Sound.HIT, 0.9)
	if multiplayer.is_server() and _field != null:
		_field.deposit(global_position, hurl.clamor_hit)


func _thrown() -> ThrownTrait:
	if _definition == null:
		return null
	return _definition.first_trait(ThrownTrait) as ThrownTrait


## The floor under a blow, where an axe that struck a body falls.
func _rest_below(space: PhysicsDirectSpaceState3D) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(global_position,
		global_position + Vector3.DOWN * 6.0)
	query.collision_mask = CollisionLayers.WORLD
	var ground: Dictionary = space.intersect_ray(query)
	if ground.is_empty():
		return global_position
	return (ground["position"] as Vector3) + Vector3.UP * 0.02


## **The authored model, and nothing else** (`M4-T10`, ADR-262).
##
## This drew a coloured box sized from `grid_size`, so that *"a 3x3
## altar-plate is visibly a shield-sized slab and a 1x1 gemstone is visibly
## nothing"* — bulk read honestly and that was the whole of it. The models now
## carry that reading themselves: `ART-006` gives the modeller each item's bag
## footprint and weight precisely so proportion survives the swap, and
## `art_probe` asserts every one of them is honest about metres.
##
## **No fallback.** An item without a model fails `--data-probe` rather than
## quietly getting a box, because a box that stands in for missing art is the
## parallel path ADR-064 bans — and the failure mode is that nobody ever
## notices the art is missing.
func _build_mesh() -> void:
	# **The collision the model carries is not this item's collision.** A
	# `WorldItem` is an `Area3D` with its own shape for the pick-up test, and a
	# second body from the `-col` suffix would put a solid object in the room
	# that a player can walk into and shove around. `look()` throws it away,
	# and says why it has to happen before the tree sees the model.
	_look = _definition.look()
	add_child(_look)
	_build_glimmer()


## **Gold light is what it will cost you** (`M2-T13`, ADR-105).
##
## The other half of the Deep's lighting rule, and the half that does the design
## work. `ART-005`: *"in a game about greed, the only thing in colour is
## treasure — the player's eye is pulled to exactly the thing that will get them
## killed, and that is not a metaphor we have to explain, it is just how the
## screen looks."* That only holds if treasure is **lit**. In a flatly-lit
## level, gold is a colour on a box; in a dark one it is the thing you can see
## from the doorway, and walking toward it is a decision you made.
##
## **Glitter only.** Gear, materials and relics are coloured but do not glow —
## if everything glowed, nothing would be worth crossing a room for, and the
## pull would go back to being decoration. `DES-017` also has the Gullsjúkr
## *baited* by disturbed gold, so the thing drawing your eye is the same thing
## drawing its attention, which is the joke the whole level is built on.
func _build_glimmer() -> void:
	if not _definition.tags.has(&"glitter"):
		return
	# **The light, not the surface** (ADR-262). The box glowed because it had
	# one material this file owned; an authored model has its own, and reaching
	# into a delivered asset to overwrite them would make the art depend on
	# what this function happens to do to it. ADR-204 put the magnitude on the
	# light in the first place — *how much it pours is what it is worth* — and
	# a gold model standing in its own pool of gold light reads as treasure
	# without the mesh being asked to emit anything.
	var glow := OmniLight3D.new()
	# Declares itself as treasure rather than being recognised by what it hangs
	# off. `--sight-probe` asserts that gold is spent only here, and its first
	# version identified a light's owner with `get_parent()` — which `TEC-001`
	# forbids outright ("signals up, calls down") and `check_project.py` caught
	# on the first run.
	glow.add_to_group(TREASURE_LIGHT_GROUP)
	glow.light_color = _colour()
	# **How much it pours is what it is worth** (`M4-T23`, ADR-204). A coin is
	# still the small mark `M2-T13` made it; the richest thing on the floor is a
	# pool you can see from another room, which is `ART-005`'s *"treasure should
	# be visually magnetic — greed should be a visual pull before it is a
	# mechanical one"* given the one number that varies.
	var t: float = _share_of_the_richest()
	glow.light_energy = lerpf(GLIMMER_ENERGY.x, GLIMMER_ENERGY.y, t)
	glow.omni_range = lerpf(GLIMMER_RANGE.x, GLIMMER_RANGE.y, t)
	glow.position.y = 0.45
	add_child(glow)


## Where this item sits between the cheapest and the dearest glitter the
## corpus holds, 0 to 1.
##
## **Measured against the catalogue rather than a constant.** A hardcoded 140
## would be a second copy of `glt_altar_plate.tres`, and the first designer to
## author something richer would get a Prize that pours less light than the
## thing it outranks — with nothing anywhere saying so.
func _share_of_the_richest() -> float:
	var low: int = -1
	var high: int = 0
	for item: ItemResource in ItemCatalogue.all():
		if not item.tags.has(&"glitter"):
			continue
		high = maxi(high, item.tribute_value)
		low = item.tribute_value if low < 0 else mini(low, item.tribute_value)
	if low < 0 or high <= low:
		return 0.0
	return clampf(float(worth() - low) / float(high - low), 0.0, 1.0)


## An ember on the floor (`M2-T05`). A glowing sphere rather than a box, so it
## never reads as loot at a glance — and the same glowing sphere whoever it
## belongs to (ADR-094).
func _build_ember() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = EMBER_RADIUS
	mesh.height = EMBER_RADIUS * 2.0
	_material = StandardMaterial3D.new()
	_material.albedo_color = EMBER_COLOUR
	# It is a light, and it is going out — which is the whole of `DES-012`'s
	# window, said without a word of UI. Modest energy: at 1.4x it clipped to a
	# flat saturated disc and stopped reading as fire at all.
	_material.emission_enabled = true
	_material.emission = EMBER_COLOUR
	_material.emission_energy_multiplier = 0.7
	_mesh = MeshInstance3D.new()
	_mesh.mesh = mesh
	_mesh.material_override = _material
	_mesh.position.y = EMBER_RADIUS + 0.1
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
	# **The model floats and is ringed** (ADR-267). This pulsed a material's
	# albedo, which was the whole of the highlight while every item was a box
	# this file owned. ADR-262 swapped the boxes for authored models and left
	# the pulse reaching only the ember, so for every other item in the game
	# the only sign it was the one in reach was the prompt — a sentence, where
	# `DES-019` wants the thing itself to answer the eye.
	if _look != null:
		_highlit = on
		if _halo != null:
			_halo.visible = on
		set_process(true)
	if _material == null:
		return
	var pulse: float = 1.0
	if on:
		pulse = 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.25
	_material.albedo_color = _colour() * pulse


## How far the model is off its floor right now, metres — for the probe that
## asks whether a highlight, a drop or a landing ever leaves it hanging.
func look_lift() -> float:
	return _look.position.y if _look != null else 0.0


## The model, turned however its flight turned it — for the probe that asks
## whether it comes to rest the right way up.
func look_basis() -> Basis:
	return _look.basis if _look != null else Basis()


## This process's own player reached for it (ADR-267). Only a mark for the
## ghost that follows a taken thing into the bag; nothing is decided by it.
func claim_locally() -> void:
	_claimed_msec = Time.get_ticks_msec()


func _process(delta: float) -> void:
	if _look == null:
		set_process(false)
		return
	var want: float = HOVER if _highlit else 0.0
	_lift = lerpf(_lift, want, clampf(delta * HOVER_EASE, 0.0, 1.0))
	if absf(_lift - want) < 0.001:
		_lift = want
		# Settled and not in reach: nothing left to animate.
		if not _highlit:
			set_process(false)
	# Only while nothing else is moving it: a fall or a landing owns the
	# height until it has finished.
	if not _falling:
		_look.position.y = _lift


var _falling: bool = false


## Drop the model the last `height` metres onto its spot, with one small
## bounce, so a thing let go of reads as let go of rather than as appearing.
func _fall_into_place(height: float) -> void:
	if _look == null:
		return
	_falling = true
	_look.position.y = height
	var fall := create_tween()
	fall.tween_property(_look, "position:y", 0.0, DROP_SECONDS * 0.7) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(_look, "position:y", height * 0.08, DROP_SECONDS * 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(_look, "position:y", 0.0, DROP_SECONDS * 0.15) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.finished.connect(func() -> void: _falling = false)


## End over end while it flies, about the axis across its flight. Only the
## model turns; the node keeps flying straight, so nothing the host measures
## about a throw moves by a millimetre.
func _tumble(delta: float) -> void:
	if _look == null:
		return
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	if flat.length() < 0.01:
		return
	var across: Vector3 = global_basis.inverse() * flat.cross(Vector3.UP).normalized()
	_look.rotate(across.normalized(), -TUMBLE * delta)


## Come to rest the right way up. A model pivots at its base, so one that
## stopped mid-turn would lie half inside the floor or stand on its point.
func _land() -> void:
	if _look == null:
		return
	var settle := create_tween()
	settle.tween_property(_look, "basis", Basis(), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_fall_into_place(0.12)


## The ring drawn under the model while it is in reach (ADR-267).
##
## A ring on the floor rather than a glow on the model: `ART-005` inks a
## surface's edges and hatches its value, and a model tinted brighter reads as
## a lighting fault in a woodcut. An inked circle around a thing is how a
## printmaker points at it. Sized to the model's own footprint, so a gemstone
## gets a small one and an altar-plate a wide one.
func _build_halo() -> void:
	if _look == null:
		return
	var span: float = 0.0
	for node: Node in _look.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box: AABB = mesh.transform * mesh.get_aabb()
		span = maxf(span, maxf(box.size.x, box.size.z))
	var ring := TorusMesh.new()
	ring.inner_radius = span * 0.5 + 0.10
	ring.outer_radius = span * 0.5 + 0.13
	ring.rings = 32
	ring.ring_segments = 4
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = _colour().lerp(Color(0.92, 0.9, 0.85), 0.55)
	_halo = MeshInstance3D.new()
	_halo.name = "halo"
	_halo.mesh = ring
	_halo.material_override = ink
	_halo.scale = Vector3(1.0, 0.05, 1.0)
	_halo.position.y = 0.012
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.visible = false
	add_child(_halo)


## The glint on treasure — glitter only, for `_build_glimmer`'s reason: if
## everything caught the eye, nothing would be worth crossing a room for.
func _build_glint() -> void:
	if _look == null or not _definition.tags.has(&"glitter"):
		return
	var top: float = 0.0
	for node: Node in _look.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		top = maxf(top, (mesh.transform * mesh.get_aabb()).end.y)
	var star := ShaderMaterial.new()
	star.shader = GLINT
	# Per item, from where it lies, so a hoard does not twinkle in step and a
	# given coin catches at the same moment on every peer.
	star.set_shader_parameter("phase",
		fposmod(global_position.x * 0.37 + global_position.z * 0.61, 1.0))
	var quad := QuadMesh.new()
	quad.size = Vector2(GLINT_SIZE, GLINT_SIZE)
	var star_quad := MeshInstance3D.new()
	star_quad.name = "glint"
	star_quad.mesh = quad
	star_quad.material_override = star
	star_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	star_quad.position = Vector3(0.0, top * 0.8, 0.0)
	_look.add_child(star_quad)


## The glint, if this thing has one — for the probe.
func glint() -> MeshInstance3D:
	return _look.get_node_or_null(^"glint") as MeshInstance3D if _look != null else null


## **Taken, and seen going into the bag** (ADR-267).
##
## The host frees a taken item and every peer's copy goes with it, so until
## now a pick-up was a thing on the floor, then no thing. For the player who
## took it, a copy of the model is sent up into the lower edge of their view
## and gone — the hand going down for it and coming back, without a hand.
## Only for this process's own reach (`claim_locally`), because a teammate's
## pick-up is theirs to see; and only when this node is being **freed**, so a
## floor being torn down by a descent does not fire a flight of ghosts.
func _exit_tree() -> void:
	if _claimed_msec < 0 or not is_queued_for_deletion() or _definition == null:
		return
	if Time.get_ticks_msec() - _claimed_msec > 1500:
		return
	var eye: Camera3D = get_viewport().get_camera_3d() if get_viewport() != null else null
	var root: Node = get_tree().root if get_tree() != null else null
	if eye == null or root == null:
		return
	var ghost := ItemGhost.made(_definition, global_transform, eye)
	if ghost != null:
		root.add_child.call_deferred(ghost)


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
