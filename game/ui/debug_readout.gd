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
	var health: Health = _player.health
	var clamor: ClamorSource = _player.clamor
	var lines: PackedStringArray = PackedStringArray([
		"health    %5.1f / %.0f%s" % [
			health.current, health.maximum, "   DEAD" if health.is_dead() else "",
		],
		"speed     %5.2f m/s" % _player.planar_speed(),
		"stamina   %5.1f / %.0f" % [stamina.current, stamina.maximum()],
		"carrying  %5.1f kg  (%.0f%% laden)" % [
			carried.kilograms, carried.encumbrance() * 100.0,
		],
		# The radius is the number that means something: DES-005 requires the
		# player to always know how much pressure they have made. "4.8 clamor"
		# is not actionable; "heard 7.7 m away" is.
		"clamor    %5.1f      heard %.1f m away" % [
			clamor.level, clamor.audible_radius(),
		],
	])
	# Enemy state is on screen because the awareness ladder is unreadable
	# without audio, and DES-013 requires every transition to be legible in
	# both channels. The audio half is `M2-T03`; until then this is the only
	# channel there is, and judging the ladder blind is not possible.
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		# Sight and hearing shown apart from the ladder state. The state says
		# what the enemy is doing; these say which sense is feeding it, which
		# is the difference between "spotted" and "it heard something".
		lines.append("enemy     %-10s %5.1f hp   %s %s" % [
			Enemy.State.keys()[enemy.state()].to_lower(), enemy.health.current,
			"SEES" if enemy.sees_player() else "····",
			"HEARS" if enemy.hears_player() else "·····",
		])
	lines.append("lmb attack   [ ] weight   shift sprint   ctrl crouch   r reset")
	text = "\n".join(lines)
