class_name AuthoredFloor
extends FloorSource
## The Deep, as a `FloorSource` (`M4-T01`).
##
## Every answer here is one of `RoomSet`'s hand-placed constants, unchanged and
## still documented where it is declared — the reasoning for *why the west
## branch is empty* or *why the Waystone is a fixture* belongs beside the data,
## not beside the accessor that hands it over.
##
## This exists so the generated floor has something to be the other half of.
## `RoomSet` reads the floor under it through a `FloorSource` now, and this is
## what it reads when nobody has given it anything else — so the Deep, and the
## thirty probes that measure it, behave exactly as they did.


func spawns() -> Array[Vector3]:
	return RoomSet.SPAWNS


func enemy_posts() -> Array[Vector3]:
	return RoomSet.ENEMY_POSTS


func guardian() -> Vector3:
	return RoomSet.GUARDIAN_POST


func shaft() -> Vector3:
	return RoomSet.SHAFT_AT


func hunter() -> Vector3:
	return RoomSet.HUNTER_POST


func fixtures() -> Array:
	return RoomSet.FIXTURES


func filler() -> Array:
	return RoomSet.FILLER


func field() -> AABB:
	return AABB(RoomSet.FIELD_FROM, RoomSet.FIELD_TO - RoomSet.FIELD_FROM)


## Every doorway is listed twice in `DOORS` — once per room it joins — so this
## lights both approaches without knowing which side you are on. That
## duplication was already there to cut the hole from both rooms; it turns out
## to be exactly what "visible from either side" needs.
func door_lights() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for door: Array in RoomSet.DOORS:
		var rect: Array = RoomSet.ROOMS[door[0] as String]
		var offset: float = float(door[2])
		# Inside the room by a little more than the wall is thick, so the lamp
		# is in the room it belongs to rather than buried in the masonry.
		var inset: float = RoomSet.WALL_THICK * 1.5
		var high: float = RoomSet.DOOR_LIGHT_HEIGHT
		match door[1] as String:
			"n": out.append(Vector3(offset, high, float(rect[2]) + inset))
			"s": out.append(Vector3(offset, high, float(rect[3]) - inset))
			"w": out.append(Vector3(float(rect[0]) + inset, high, offset))
			"e": out.append(Vector3(float(rect[1]) - inset, high, offset))
	return out
