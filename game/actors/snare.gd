class_name Snare
extends Area3D

## The Veiðimaðr's verb (`M3-T11`, `DES-011`, ADR-123).
##
## > *"Place traps that hold, wound, or misdirect — **including against the
## > Hunter**, the only reliable way to buy time during the Sealing."*
##
## ## One trap, not three
##
## `DES-011` lists **trap variety** under the Veiðimaðr's *Rite themes*, which
## means the skill tree (`M3-T01`), not the base verb. So the verb ships as the
## one behaviour the sentence names as load-bearing: it **holds**. Wound is a
## bigger number and ADR-058 makes that the proposal needing a very good reason;
## misdirect already exists twice over — `DES-005`'s thrown loot, and this
## class's own bow landing its noise somewhere the archer is not.
##
## ## Its costs, which `DES-011` rule 3 requires of every unique verb
##
## - **Placing takes time and stamina.** Same commitment argument as the
##   Húskarl's plant: a verb you can flick out mid-fight is a reflex, and
##   principle 3 puts this game on the other side of that line.
## - **One live at a time.** Placing a second removes the first, so the Stalker
##   is never counting a resource — they are answering *"is this the doorway?"*
##   That is a decision rather than an inventory, which is also why it needs no
##   ammunition economy (`DES-008`) to exist. The Rite is the obvious place for
##   a second one, and that is a real upgrade rather than a bigger number.
## - **It is loud when it fires.** The Stalker's whole identity is being quiet,
##   and this is the one thing they do that makes noise — but the noise happens
##   **where the trap is**, which is where the thing they are running from
##   already is. A snare set in the doorway you are leaving through is a mistake
##   you can make, and it is legible the moment you make it.
##
## ## What it catches
##
## `ENEMY_BODY` only, so it never holds your own party. There is no "except
## teammates" rule to get wrong, for the same reason `BULWARK` needed none.

## Ring radius in metres ⟨tune⟩ — a doorway, roughly, matching ADR-054's 2 m
## module so a snare set in a door fills the door.
const RADIUS: float = 1.0

## Replicated so a client sees the trap snap shut on the thing it caught. The
## hold itself is host-side and needs no wire at all: a client's enemies are
## moved by the synchroniser, so a held one stops because the transform it is
## being sent stops changing. This is the **visual twin** (`DES-018`) — without
## it the enemy simply halts, and a thing that stops for no visible reason is
## indistinguishable from a thing that is stuck.
const REPLICATED_PROPERTIES: Dictionary = {
	".:sprung": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
}
const REPLICATION_HZ: float = 10.0

## Seconds the sprung trap stays visible before it clears. Long enough to read
## as *that is what stopped it*, short enough that the floor does not fill with
## spent rings.
const LINGER: float = 3.0

## The peer that set it, so a player can find and clear their own.
var placer: int = 0
var hold_seconds: float = 3.0
var clamor_trigger: float = 2.6

var sprung: bool = false:
	set(value):
		if sprung == value:
			return
		sprung = value
		_dress()
		# **On every peer**, because this is the setter a replicated value
		# arrives through. Putting the cue where it fires would have played it
		# on the host alone — the host being the only machine that decides a
		# snare has caught something, and the only one that would then have
		# heard it (`DES-018`: the visual twin above and this are one event).
		Foley.at(self, Foley.Sound.HIT, 0.62)

var _field: ClamorField = null
var _ring: MeshInstance3D = null


func configure_replication() -> void:
	var config := SceneReplicationConfig.new()
	for path: String in REPLICATED_PROPERTIES:
		var property := NodePath(path)
		config.add_property(property)
		config.property_set_spawn(property, true)
		config.property_set_replication_mode(property,
			int(REPLICATED_PROPERTIES[path]))
	var sync := MultiplayerSynchronizer.new()
	sync.name = "SnareSync"
	sync.replication_config = config
	sync.replication_interval = 1.0 / REPLICATION_HZ
	sync.delta_interval = 1.0 / REPLICATION_HZ
	add_child(sync)


func _ready() -> void:
	add_to_group(&"snares")
	collision_layer = 0
	# Hostile bodies only. A trap that caught the party would need an exception
	# rule, and `BULWARK` already established that the layer is the place to say
	# who something applies to.
	collision_mask = CollisionLayers.ENEMY_BODY
	monitoring = multiplayer.is_server()

	var shape := CollisionShape3D.new()
	var ball := CylinderShape3D.new()
	ball.radius = RADIUS
	ball.height = 1.2
	shape.shape = ball
	add_child(shape)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS * 0.78
	torus.outer_radius = RADIUS
	_ring.mesh = torus
	_ring.position.y = 0.03
	add_child(_ring)
	_dress()

	body_entered.connect(_on_stepped_in)


## Blockout, per ADR-046: an open ring on the floor and a tight bright one once
## it has fired. Two states, both readable from standing height, no animation.
func _dress() -> void:
	if _ring == null:
		return
	var torus := _ring.mesh as TorusMesh
	torus.inner_radius = (RADIUS * 0.30) if sprung else (RADIUS * 0.78)
	torus.outer_radius = (RADIUS * 0.42) if sprung else RADIUS
	var skin := StandardMaterial3D.new()
	skin.albedo_color = (Color(0.86, 0.74, 0.32) if sprung
		else Color(0.34, 0.30, 0.22))
	skin.emission_enabled = sprung
	skin.emission = Color(0.86, 0.74, 0.32)
	skin.emission_energy_multiplier = 0.6
	_ring.material_override = skin


func _on_stepped_in(body: Node3D) -> void:
	if sprung or not multiplayer.is_server():
		return
	# Whatever it is, it has to be holdable by the shared rule. Anything on
	# `ENEMY_BODY` without a `Rooted` is a body that grew a layer and not a
	# component, and it should walk through rather than crash.
	var caught: Rooted = body.get("rooted") as Rooted
	if caught == null:
		return
	sprung = true
	# Deferred: this runs inside `body_entered`, and Godot refuses a physics
	# state change from there — *"Function blocked during in/out signal"*. The
	# same rule that already defers a corpse dropping its collision layer.
	set_deferred("monitoring", false)
	caught.hold_for(hold_seconds)
	# **Noise where the trap is, not where the Stalker is.** Straight into the
	# field for the reason `Arrow._land` gives: a `ClamorSource` made and freed
	# inside one frame is never absorbed, and it would carry party scaling that
	# has already been paid.
	if _field != null:
		_field.deposit(global_position, clamor_trigger)
	var fade: SceneTreeTimer = get_tree().create_timer(LINGER)
	fade.timeout.connect(queue_free)


## Handed the floor's noise field, mirroring `Gullsjukr.hunt_with`.
func fly_with(field: ClamorField) -> void:
	_field = field
