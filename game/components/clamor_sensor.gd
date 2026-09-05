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
	# Hearing is a host-side sense, because the brain it feeds is (`TEC-004`:
	# enemies are host-authoritative). Running it on a client would scan every
	# clamor source in the level to emit into a state machine that is not
	# listening — O(n) per agent per frame, bought for nothing.
	if not multiplayer.is_server():
		return
	var loudest: float = 0.0
	var where: Vector3 = Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group("clamor_sources"):
		var source := node as ClamorSource
		if source == null or source.level <= 0.0:
			continue
		# **Not your own shout** (`M4-T16`). Enemies became clamor sources so
		# they could call each other, and a body whose own call is the loudest
		# thing it can hear investigates itself forever — it would stand in the
		# spot it is already standing in, permanently SUSPICIOUS of itself.
		# `owner` is the actor for both nodes, since both are children of the
		# same scene.
		if owner != null and source.owner == owner:
			continue
		# Occlusion lives in ClamorSource so that this test and the gym's debug
		# ring cannot disagree about what is audible.
		if not source.audible_at(global_position):
			continue
		# Nearest-loudest wins. With one player this is trivial; it matters
		# once thrown objects are also sources (DES-005 counter-play).
		var distance: float = global_position.distance_to(source.global_position)
		var loudness: float = source.level - distance / maxf(
			Config.tuning.clamor_metres_per_unit, 0.001
		)
		if loudness > loudest:
			loudest = loudness
			where = source.global_position
	if loudest > 0.0:
		heard.emit(where, loudest)
