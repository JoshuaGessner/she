class_name LockedDoor
extends Node3D

## **A gate, built** (ADR-381, `TEC-007`, `DES-015` step 3).
##
## `MissionGraph` has drawn `lock-and-key` and `shortcut` cycles since ADR-171
## and validated them as locks, and nothing stood where a gate was: half the
## floors played as plain detours. This is the thing that stands there.
##
## - **Locked** — a key gate. It opens for a body carrying the floor's key
##   (`KEY_ITEM`, lying in the `KEY` node's room), and stays open. Zelda's
##   small key: the key and the door are both things you can see.
## - **Barred** — a cost gate, a shortcut. Barred on its deep side, so the party
##   that came the long way lifts the bar and takes the short way out, and from
##   the near side it is shut and says so. Dark Souls' shortcut, made
##   structural.
##
## The host decides and replicates `open`; every peer swings its own leaf. It
## opens loudly — a hinge nobody has oiled — and once only.

enum Kind { LOCKED, BARRED }

const GROUP: StringName = &"locked_doors"
## The floor's key, which opens every locked door on it.
const KEY_ITEM: StringName = &"tol_floor_key"
## The leaf: the corridor's own width and height, and a plank's depth.
const SIZE := Vector3(2.0, 2.6, 0.2)
## How far the leaf swings when it opens, and how fast.
const SWING: float = 1.75
const SWING_SECONDS: float = 0.7
const REPLICATION_HZ: float = 10.0
const REPLICATED_PROPERTIES: Dictionary = {
	".:open": SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE,
}

signal opened(door: LockedDoor)

var kind: Kind = Kind.LOCKED
## Toward the side a bar is lifted from, in the world's plane. Barred only.
var bar_side: Vector3 = Vector3.ZERO
## Whether it stands open. The host's, replicated.
var open: bool = false:
	set(value):
		var was: bool = open
		open = value
		if open and not was and _solid != null:
			_solid.set_deferred("disabled", true)

var _solid: CollisionShape3D = null
var _leaf: Node3D = null
var _swung: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	var body := StaticBody3D.new()
	body.name = "Body"
	# On `GATE` alone (ADR-384): solid to every body, transparent to sight.
	body.collision_layer = CollisionLayers.GATE
	body.collision_mask = 0
	add_child(body)
	_solid = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE
	_solid.shape = box
	_solid.position = Vector3(0.0, SIZE.y * 0.5, 0.0)
	_solid.disabled = open
	body.add_child(_solid)
	_leaf = _build_leaf()
	add_child(_leaf)
	_swung = 1.0 if open else 0.0
	_pose()


## The leaf, hinged at its left edge: an **iron grille** (ADR-384) — rails top
## and bottom, a band across, upright bars between, a ring where a hand would
## be — so what is kept behind it can be seen. For a barred door, a timber
## beam across the bar side.
func _build_leaf() -> Node3D:
	var hinge := Node3D.new()
	hinge.name = "Leaf"
	hinge.position = Vector3(-SIZE.x * 0.5, 0.0, 0.0)
	# In the world's own range of values, not the colour of old oak: the ink
	# pass prints anything this dark as solid ink, and the first photograph of
	# a door was a black slab with no planks — a hole, not a door.
	var timber := _material(Color(0.46, 0.37, 0.27), 0.9)
	var iron := _material(Color(0.30, 0.30, 0.32), 0.5)
	var bars: int = 9
	for i: int in bars:
		var x: float = SIZE.x * (float(i) + 0.5) / float(bars)
		_box(hinge, Vector3(0.05, SIZE.y - 0.1, 0.05), Vector3(x, SIZE.y * 0.5, 0.0), iron)
	for y: float in [0.06, 1.1, SIZE.y - 0.06]:
		_box(hinge, Vector3(SIZE.x - 0.02, 0.11, 0.09), Vector3(SIZE.x * 0.5, y, 0.0), iron)
	for x: float in [0.04, SIZE.x - 0.04]:
		_box(hinge, Vector3(0.08, SIZE.y, 0.09), Vector3(x, SIZE.y * 0.5, 0.0), iron)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.06
	torus.outer_radius = 0.085
	ring.mesh = torus
	ring.material_override = iron
	ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	ring.position = Vector3(SIZE.x * 0.82, 1.1, -(SIZE.z * 0.5 + 0.03))
	hinge.add_child(ring)
	if kind == Kind.BARRED:
		var facing: float = -1.0 if bar_side.dot(global_basis.z) < 0.0 else 1.0
		_box(hinge, Vector3(SIZE.x + 0.2, 0.16, 0.16),
			Vector3(SIZE.x * 0.5, 1.2, facing * (SIZE.z * 0.5 + 0.1)), timber)
	return hinge


func _box(into: Node3D, size: Vector3, at: Vector3, look: Material) -> void:
	var piece := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	piece.mesh = box
	piece.material_override = look
	piece.position = at
	into.add_child(piece)


## The kit's own weathering (ADR-285), so a door is lit and inked as the walls
## around it are, not as a plain material in a world of worn stone.
static func _material(colour: Color, rough: float) -> ShaderMaterial:
	var look := ShaderMaterial.new()
	look.shader = DelvingsKit.WEATHERED
	look.set_shader_parameter("albedo", Vector3(colour.r, colour.g, colour.b))
	look.set_shader_parameter("roughness", rough)
	return look


func configure_replication() -> void:
	var config := SceneReplicationConfig.new()
	for path: String in REPLICATED_PROPERTIES:
		var property := NodePath(path)
		config.add_property(property)
		config.property_set_spawn(property, true)
		config.property_set_replication_mode(property, int(REPLICATED_PROPERTIES[path]))
	var sync := MultiplayerSynchronizer.new()
	sync.name = "DoorSync"
	sync.replication_config = config
	sync.replication_interval = 1.0 / REPLICATION_HZ
	sync.delta_interval = 1.0 / REPLICATION_HZ
	add_child(sync)


## **Why it would not open for `body`**, or `""` when it would: one rule, asked
## by the reticle before the key is pressed and by the host before it is
## honoured — the bag's `can_use` shape.
func refusal(body: Player) -> StringName:
	if open:
		return &"open"
	if kind == Kind.BARRED:
		return &"" if on_bar_side(body.global_position) else &"barred"
	return &"" if carries_key(body) else &"locked"


## Whether `at` is on the side the bar is lifted from.
func on_bar_side(at: Vector3) -> bool:
	var off: Vector3 = at - global_position
	off.y = 0.0
	return off.dot(bar_side) > 0.0


## A haul without the floor's key, for `GameState.bring_home`: it opens its
## floor's doors and no other, so it does not come home.
static func coming_home(items: Array[ItemInstance]) -> Array[ItemInstance]:
	return items.filter(func(item: ItemInstance) -> bool:
		return item.definition.id != KEY_ITEM)


## A packed bag without the floor's key (ADR-381, B49): the rows that go down
## the stairs. The key opens this floor's doors and no other.
static func leaving_floor(rows: Array) -> Array:
	return rows.filter(func(row: Variant) -> bool:
		return StringName((row as Dictionary).get("item", "")) != KEY_ITEM)


static func carries_key(body: Player) -> bool:
	for held: ItemInstance in body.inventory.items():
		if held.definition.id == KEY_ITEM:
			return true
	return false


## The host's half: open it, once.
func host_open() -> void:
	if open or not multiplayer.is_server():
		return
	open = true
	opened.emit(self)


func _process(delta: float) -> void:
	var want: float = 1.0 if open else 0.0
	if is_equal_approx(_swung, want):
		return
	_swung = move_toward(_swung, want, delta / SWING_SECONDS)
	_pose()


func _pose() -> void:
	if _leaf != null:
		# Eased, so it starts stiff and swings free — the grind is at the start.
		_leaf.rotation.y = -SWING * _swung * _swung
