extends Label

## Speed, stamina and weight on screen. You cannot tune a controller blind —
## "it feels heavy" is not a number, and DES-009's whole M1 protocol depends on
## being able to tell whether a change moved what you thought it moved.
##
## Scope note: `M1-T04` owns the real debug overlay, **Weight *and* Clamor**.
## Clamor does not exist yet and is not faked here — a zero next to a label
## would read as "silent" rather than "unbuilt" (ADR-064).

@export var player_path: NodePath

var _player: Player


func _ready() -> void:
	_player = get_node_or_null(player_path) as Player


func _process(_delta: float) -> void:
	if _player == null:
		# The gym spawns the player at runtime, so bind on the first frame it
		# is actually there rather than assuming scene order.
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
	var carried: CarriedWeight = _player.carried
	var stamina: Stamina = _player.stamina
	text = "\n".join([
		"speed     %5.2f m/s" % _player.planar_speed(),
		"stamina   %5.1f / %.0f" % [stamina.current, stamina.maximum()],
		"carrying  %5.1f kg  (%.0f%% laden)" % [
			carried.kilograms, carried.encumbrance() * 100.0,
		],
		"[ ] adjust weight   shift sprint   ctrl crouch",
	])
