class_name Arrow
extends Area3D

## Something in the air (`M3-T11`, ADR-123). The first thing in this game that
## does damage without touching the person who caused it.
##
## ## A body, not a ray
##
## `DES-009` refuses hit-scan precision requirements and keeps melee volumes
## forgiving. An arrow is a travelling `Area3D` with a real radius for the same
## reason: it can be **led**, and it can be **walked out of**, which keeps
## *"defense is positional"* true of a weapon fired across a room. A raycast
## would make the bow a test of aim, which is the reflex-over-decision trade
## principle 3 rules out.
##
## No gravity and no arc. An arc is a precision mechanic; a flat flight with a
## range cap is the same weapon without the skill-ceiling arms race `DES-009`
## names *Mordhau* to exclude.
##
## ## Host-only, like every other consequence
##
## `TEC-004` gives consequences one owner. The arrow is spawned through
## `CoopSession` so every peer has one to look at, and **only the host moves it
## or resolves what it hits** — a client's copy is a thing flying, and the
## damage it appears to do is the host's decision arriving.
##
## ## What lands where
##
## Its noise is deposited **at the impact, not at the shooter** — which is the
## whole tactic and the same misdirection `DES-005` already sells thrown loot
## on. `clamor_loose` is what the archer pays; `clamor_hit` happens somewhere
## else, and somewhere else is where the Hunt goes.

const RADIUS: float = 0.14

## Set from the payload before it enters the tree, so every peer builds the
## same arrow from the same packet.
var travel: Vector3 = Vector3.FORWARD
var speed: float = 34.0
var damage: float = 32.0
var clamor_hit: float = 3.2
## Metres left before it gives up. Counted down rather than timed, so a slow
## arrow and a fast one reach equally far.
var left: float = 26.0
## The peer that loosed it, so its own body cannot be hit by it.
var shooter: int = 0

## The field this arrow deposits into. Handed down by whatever spawned it,
## because an arrow has no business finding one for itself and a level that
## forgot to pass it should be a silent arrow rather than a crash.
var _field: ClamorField = null

var _spent: bool = false


func _ready() -> void:
	collision_layer = 0
	# Hurtboxes only. **Not `WORLD`** — an arrow that collided with geometry as
	# a body would be stopped by the floor it is flying over. Walls are handled
	# by the range cap and by a separate query, not by making this a wall.
	collision_mask = CollisionLayers.ENEMY_HURTBOX | CollisionLayers.PLAYER_HURTBOX
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = RADIUS
	shape.shape = ball
	add_child(shape)

	var mesh := MeshInstance3D.new()
	var body := CylinderMesh.new()
	body.top_radius = 0.02
	body.bottom_radius = 0.02
	body.height = 0.7
	mesh.mesh = body
	mesh.rotation_degrees.x = 90.0
	add_child(mesh)

	area_entered.connect(_on_hit)
	# Only the host flies it. A client's copy is moved by the synchroniser, so
	# leaving physics on here would give it two authorities disagreeing about
	# where it is.
	set_physics_process(multiplayer.is_server())


func _physics_process(delta: float) -> void:
	if _spent:
		return
	var step: float = speed * delta
	global_position += travel * step
	left -= step
	if left <= 0.0:
		# Out of range and nothing hit. It stops existing quietly — a spent
		# arrow lying on the floor is `DES-008` economy work (ammunition), and
		# there is no economy for it to belong to yet.
		_finish()


## First thing it touches wins. Deliberately not a sphere query for *all*
## overlaps: an arrow passing through a crowd and wounding every one of them is
## a different weapon, and `DES-008` makes gear a sidegrade rather than a way to
## make a number bigger.
func _on_hit(area: Area3D) -> void:
	if _spent or not multiplayer.is_server():
		return
	var hurtbox := area as Hurtbox
	if hurtbox == null:
		return
	# Never your own loosing. A body walking into the arrow it just fired is an
	# unexplainable death (`PRO-005` §5) with a very silly cause.
	var struck: Node = hurtbox.get_parent()
	var body := struck as Player
	if body != null and body.get_multiplayer_authority() == shooter:
		return
	hurtbox.receive(damage, self)
	_land(_field)


## **Straight into the field**, not through a `ClamorSource`.
##
## The obvious version makes a source at the impact, calls `add()` and frees
## it — and the noise goes **nowhere**. `ClamorField` subscribes to sources in
## its own `_physics_process`, so one created and freed inside a single frame is
## never absorbed and its signal is heard by nothing. `deposit()` is the seam
## for exactly this: noise at a place, with nobody making it.
##
## The other half of the reason is that a `ClamorSource` would carry party
## scaling (`M2-T07` puts it in `add()`), and this noise has already been paid
## for — the archer's shot was scaled when they loosed it. Charging it twice
## would make a four-stack's arrows land louder than their own footsteps.
func _land(field: ClamorField) -> void:
	if field != null:
		field.deposit(global_position, clamor_hit)
	_finish()


func _finish() -> void:
	_spent = true
	set_physics_process(false)
	queue_free()


## Handed the floor's noise field. Mirrors `Gullsjukr.hunt_with` — the level
## owns the field and the actors are given it, so nothing goes looking through
## the tree for a singleton that may not be there yet.
func fly_with(field: ClamorField) -> void:
	_field = field
