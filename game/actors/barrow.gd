class_name Barrow
extends Node3D

## **A barrow that opens behind you** (`M4-T04`, ADR-242) — `DES-007`'s tier 3.
##
## `DES-007` calls whispers *the "one more room" engine* and gives them one
## design job: fire **precisely when the player has decided to leave**. So a
## floor keeps a grave sealed in a room already walked through, and the first
## time anybody reaches the way on it grinds open, gold light inside and one
## find on its floor, and then shuts again with the find still in it. Dead
## Cells' timed doors are the reference — a real prize, a real clock, and the
## only way to it is back.
##
## ## Loud, and it shuts, by the developer's call
##
## The grind is laid in the Clamor field where the barrow is, so the Gold-Sick
## walk towards what you would walk back for; the clock stops a party waiting
## the Hunt out. Either alone is a walk the answer to which is nearly always
## *yes*. Both together are `GATE M4 GREED`'s question asked on purpose.
##
## ## A capstone flush with the floor, never a room
##
## The find lies in a shallow pit under a low slab that slides aside, so
## nobody ever stands *inside* the barrow when it shuts — ADR-015 forbids
## trapping, and a door that closes on a body is a trap. Like the Shaft and
## the cairn it has no collision: it is a mark on the floor you step over.
##
## ## The host decides, every peer sees
##
## Built on every peer at the same path, like the Shaft, and its one replicated
## value is `state`. Waking it, spawning its find, counting it down and freeing
## the find are the host's (`TEC-004`); every peer draws the slab, the light and
## the sound from `state`, and says what happened in its own words.

signal changed(state: int)

## `SPENT` is `SHUT` found rather than watched: a resumed floor's barrow, drawn
## dark and said nothing about.
enum State { SEALED, OPEN, CLOSING, SHUT, SPENT }

const GROUP: StringName = &"barrows"
## The capstone: long, narrow and low enough to step over.
const SLAB := Vector3(0.9, 0.14, 1.6)
## How far it slides aside, along its narrow axis — enough to bare the pit.
const SLIDE: float = 1.05
## Seconds the slab takes to move, which is how long it grinds.
const GRIND_SECONDS: float = 2.5
## How far the grind carries ⟨tune⟩: past a room, because the person it is for
## is standing at the Shaft two rooms away.
const GRIND_REACH: float = 70.0
const STONE := Color(0.46, 0.45, 0.43)
## A shut barrow is darker than a sealed one, so a floor never looks as if it
## still has a whisper to give when it does not.
const SPENT := Color(0.27, 0.26, 0.25)
## Gold light is what it will cost you (`M2-T13`, `ART-005`).
const GOLD := Color(1.0, 0.74, 0.34)
const GLOW_ENERGY: float = 2.2   # ⟨tune⟩
const GLOW_RANGE: float = 7.0    # ⟨tune⟩
## A floor point stands this far above the floor (`FloorAnchors.CLEARANCE`).
const FLOOR_Y: float = -0.1

## **The only replicated value.** An `int` of `State`.
var state: int = State.SEALED

## What this peer last drew, so a change is noticed once.
var _shown: int = State.SEALED
## Host-side: seconds before it shuts, seconds of grind still to lay, the find
## it opened on, and the field the grind is laid in.
var _left: float = 0.0
var _grinding: float = 0.0
var _find: WorldItem = null
var _field: ClamorField = null
var _slab: MeshInstance3D = null
var _slab_material: StandardMaterial3D = null
var _glow: OmniLight3D = null
var _flicker: float = 0.0


## Before it enters the tree, on every peer, so the synchronizer has the same
## path everywhere (the Shaft's reason). Spawn state as well as change, so a
## peer arriving after it opened sees it open.
func configure_replication() -> void:
	var config := SceneReplicationConfig.new()
	var property := NodePath(".:state")
	config.add_property(property)
	config.property_set_spawn(property, true)
	config.property_set_replication_mode(property,
		SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "StateSync"
	sync.replication_config = config
	add_child(sync)


func _ready() -> void:
	add_to_group(GROUP)
	var pit := MeshInstance3D.new()
	var hole := BoxMesh.new()
	hole.size = Vector3(SLAB.x * 0.8, 0.01, SLAB.z * 0.85)
	pit.mesh = hole
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.04, 0.035, 0.03)
	pit.material_override = dark
	pit.position = Vector3(0.0, FLOOR_Y + 0.006, 0.0)
	add_child(pit)
	_slab = MeshInstance3D.new()
	var stone := BoxMesh.new()
	stone.size = SLAB
	_slab.mesh = stone
	_slab_material = StandardMaterial3D.new()
	_slab_material.albedo_color = STONE
	_slab_material.roughness = 1.0
	_slab.material_override = _slab_material
	_slab.position = Vector3(0.0, FLOOR_Y + SLAB.y * 0.5, 0.0)
	add_child(_slab)
	# A cut line down the capstone, so it reads as worked stone laid over
	# something rather than a paving slab.
	var rune := MeshInstance3D.new()
	var groove := BoxMesh.new()
	groove.size = Vector3(0.07, 0.012, SLAB.z * 0.7)
	rune.mesh = groove
	var cut := StandardMaterial3D.new()
	cut.albedo_color = Color(0.2, 0.19, 0.18)
	rune.material_override = cut
	rune.position = Vector3(0.0, SLAB.y * 0.5 + 0.004, 0.0)
	_slab.add_child(rune)


## Host-side: the field the grind is laid in.
func hear_with(field: ClamorField) -> void:
	_field = field


func is_sealed() -> bool:
	return state == State.SEALED


func is_open() -> bool:
	return state == State.OPEN or state == State.CLOSING


func is_shut() -> bool:
	return state == State.SHUT or state == State.SPENT


## Host-side: the find it opened on, while it is still lying in it.
func find() -> WorldItem:
	if _find != null and is_instance_valid(_find) and not _find.is_queued_for_deletion():
		return _find
	return null


## Host-side: seconds before it shuts, or 0.
func seconds_left() -> float:
	return _left if is_open() else 0.0


## **Wake it** (host). Once: a barrow that has opened never seals again on this
## floor, whatever happens to its find.
func open(laid: WorldItem) -> void:
	if not multiplayer.is_server() or state != State.SEALED:
		return
	_find = laid
	_left = Config.tuning.barrow_open_seconds
	_grinding = GRIND_SECONDS
	state = State.OPEN


## **Already woken** (host): a floor resumed after its barrow opened finds it
## shut and empty, as `RunFile.stripped` finds its loot gone.
func spend() -> void:
	if not multiplayer.is_server():
		return
	_left = 0.0
	_grinding = 0.0
	_find = null
	state = State.SPENT


## **A fresh descent on the same level** (host) — the probes' reset, which
## frees the floor's loot and lays it again.
func reseal() -> void:
	if not multiplayer.is_server():
		return
	_left = 0.0
	_grinding = 0.0
	_find = null
	state = State.SEALED


## Host-side, from the level's physics tick: lay the grind, count down, warn,
## and shut on whatever is still inside.
func advance(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var tuning: TuningProfile = Config.tuning
	if _grinding > 0.0:
		_grinding -= delta
		if _field != null:
			_field.deposit(global_position, tuning.barrow_grind_clamor * delta)
	if not is_open():
		return
	_left -= delta
	if state == State.OPEN and _left <= tuning.barrow_warning_seconds:
		state = State.CLOSING
	if _left > 0.0:
		return
	_left = 0.0
	var left_behind: WorldItem = find()
	if left_behind != null:
		# Freed by the host, so the spawner frees it everywhere.
		left_behind.queue_free()
	_find = null
	state = State.SHUT


func _process(delta: float) -> void:
	if state != _shown:
		_show(state)
	if _slab == null:
		return
	var aside: float = -SLIDE if is_open() else 0.0
	_slab.position.x = move_toward(_slab.position.x, aside,
		SLIDE / GRIND_SECONDS * delta)
	if _glow == null:
		return
	if state == State.CLOSING:
		# Guttering: the one light on the floor that is visibly running out.
		_flicker += delta
		_glow.light_energy = GLOW_ENERGY * (0.55 + 0.45 * absf(sin(_flicker * 9.0)))
	else:
		_glow.light_energy = GLOW_ENERGY


## Draw a change once, on every peer: the light, the stone, the sound.
func _show(now: int) -> void:
	_shown = now
	match now:
		State.OPEN:
			if _glow == null:
				# Made on waking rather than hidden until then, so a sealed
				# barrow adds no light to a floor that counts its lights.
				_glow = OmniLight3D.new()
				_glow.name = "Glow"
				_glow.light_color = GOLD
				_glow.light_energy = GLOW_ENERGY
				_glow.omni_range = GLOW_RANGE
				_glow.position = Vector3(0.0, 0.5, 0.0)
				add_child(_glow)
			_glow.visible = true
			_slab_material.albedo_color = STONE
			Foley.at(self, Foley.Sound.GRIND, 0.6, 4.0, GRIND_REACH)
		State.CLOSING:
			# Quieter, and laid in no field: a warning to the party, not a
			# second call to the Hunt.
			Foley.at(self, Foley.Sound.GRIND, 0.8, -4.0)
		State.SHUT, State.SPENT:
			if _glow != null:
				_glow.visible = false
			_slab_material.albedo_color = SPENT
			if now == State.SHUT:
				Foley.at(self, Foley.Sound.THUMP, 0.5, 2.0)
		State.SEALED:
			if _glow != null:
				_glow.visible = false
			_slab_material.albedo_color = STONE
	changed.emit(now)


## **What a peer is told** (ADR-242), from where it stands and which way it
## faces — the sound's twin (`DES-018`), said once in the brief's fading form.
static func said(now: int, from: Vector3, facing: float, at: Vector3) -> String:
	match now:
		State.OPEN:
			return "stone grinds open %s — a barrow, and it will not stay open" \
				% ArrivalBrief.bearing(from, at, facing)
		State.CLOSING:
			return "the barrow is closing"
		State.SHUT:
			return "the barrow has shut"
	return ""
