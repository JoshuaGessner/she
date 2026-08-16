class_name ClamorSensor
extends Node3D

## Hearing. Reports the position of any `ClamorSource` currently loud enough to
## reach this node (`M1-T04`, DES-005 Layer 1).
##
## A group scan rather than physics areas, because DES-013 requires hearing to
## be **O(1) per agent** at 150 agents — an Area3D per enemy resized every frame
## as the player's clamor changes would be the opposite of that. With the
## Clamor field at `M2-T02` this becomes a single grid lookup, which is cheaper
## still; the interface here does not change when it does.
##
## Signals up, calls down: this reports, it never reaches into a brain.

signal heard(position: Vector3, loudness: float)


func _physics_process(_delta: float) -> void:
	var loudest: float = 0.0
	var where: Vector3 = Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group("clamor_sources"):
		var source := node as ClamorSource
		if source == null or source.level <= 0.0:
			continue
		var origin: Node3D = source.get_parent() as Node3D
		if origin == null:
			continue
		var distance: float = global_position.distance_to(origin.global_position)
		if distance > source.audible_radius():
			continue
		# Nearest-loudest wins. With one player this is trivial; it matters
		# once thrown objects are also sources (DES-005 counter-play).
		var loudness: float = source.level - distance / maxf(
			Config.tuning.clamor_metres_per_unit, 0.001
		)
		if loudness > loudest:
			loudest = loudness
			where = origin.global_position
	if loudest > 0.0:
		heard.emit(where, loudest)
