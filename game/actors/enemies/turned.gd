class_name Turned
extends Node3D
## **What a Skald's verse has done to a denizen** (ADR-387, `M4-T37`).
##
## The Skald's Galdr turns the dungeon on itself: an enemy in earshot when the
## verse ends is **maddened** and hunts the nearest other enemy, and whoever it
## strikes is **provoked** and fights back — Brogue's discord and Egill's
## níðstöng in one rule. An enemy with nobody to fight, a Guardian, or a
## thrower that cannot brawl is instead **unnerved**: it gives ground from the
## singer for a few seconds, which is `DES-011`'s *"breaking morale"* and the
## song's solo answer.
##
## A component rather than more of `Enemy` (`CLAUDE.md`: scenes are
## components). It holds the mood, the host's clock, the foe and where the
## song came from; `Enemy` asks it what to do. The mood replicates, and every
## peer draws its mark and plays its sound from the same setter, so *"the song
## turned them"* is something a client can see as well as the host
## (`DES-018`, PRO-005 §5).

enum Mood { NONE, MADDENED, PROVOKED, UNNERVED }

## Raised on every peer when the mood changes, after the mark has followed it.
signal changed(mood: Mood)

## Replicated (`Enemy.REPLICATED_PROPERTIES`). Set on the host only.
var mood: Mood = Mood.NONE:
	set(next):
		if next == mood:
			return
		var was: Mood = mood
		mood = next
		if is_node_ready():
			_show()
			# The ear's twin of the mark (`DES-018`): low and rough as it turns
			# on its own kind, high and thin as it gives way.
			if next == Mood.MADDENED or (next == Mood.PROVOKED and was == Mood.NONE):
				Foley.at(self, Foley.Sound.NOTICED, 0.62, 2.0)
			elif next == Mood.UNNERVED:
				Foley.at(self, Foley.Sound.NOTICED, 1.45, -3.0)
		changed.emit(next)

## Host-side: seconds left, the enemy it fights, and where the song was sung.
var left: float = 0.0
var foe: Node3D = null
var song_at: Vector3 = Vector3.ZERO

## Over the head, readable in the dark on every peer: the ring is unshaded.
const MARK_HEIGHT: float = 2.15
const MADDENED_TINT: Color = Color(0.86, 0.6, 0.26)
const UNNERVED_TINT: Color = Color(0.82, 0.8, 0.72)

var _ring: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _clock: float = 0.0


func _ready() -> void:
	_ring = MeshInstance3D.new()
	_ring.name = "Mark"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.13
	torus.outer_radius = 0.19
	torus.rings = 24
	torus.ring_segments = 8
	_ring.mesh = torus
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = _material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = Vector3(0.0, MARK_HEIGHT, 0.0)
	add_child(_ring)
	_show()


func _process(delta: float) -> void:
	if not _ring.visible:
		return
	_clock += delta
	if mood == Mood.UNNERVED:
		# Tipped and bobbing: something that has lost its footing.
		_ring.rotation = Vector3(0.6, _clock * 1.5, 0.0)
		_ring.position.y = MARK_HEIGHT + sin(_clock * 5.0) * 0.06
	else:
		_ring.rotation = Vector3(0.0, _clock * 4.0, 0.0)
		_ring.position.y = MARK_HEIGHT


## Is it fighting its own kind — maddened, or provoked by one that is?
func fighting() -> bool:
	return mood == Mood.MADDENED or mood == Mood.PROVOKED


## Host-side: take on `next` for `seconds`. A longer madness is never cut short
## by a shorter one, so a second verse cannot calm what the first turned.
func take(next: Mood, seconds: float, with_foe: Node3D = null,
		from: Vector3 = Vector3.ZERO) -> void:
	if not multiplayer.is_server():
		return
	if mood == next and seconds <= left:
		return
	left = maxf(seconds, 0.0)
	foe = with_foe
	song_at = from
	mood = next


## Host-side: run the clock. True on the tick the mood ends.
func tick(delta: float) -> bool:
	if mood == Mood.NONE or not multiplayer.is_server():
		return false
	left -= delta
	if left > 0.0:
		return false
	clear()
	return true


## Host-side: back to itself.
func clear() -> void:
	left = 0.0
	foe = null
	mood = Mood.NONE


func _show() -> void:
	if _ring == null:
		return
	_ring.visible = mood != Mood.NONE
	_material.albedo_color = UNNERVED_TINT if mood == Mood.UNNERVED else MADDENED_TINT
