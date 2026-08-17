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
	if _player == null or not is_instance_valid(_player):
		# The session spawns bodies at runtime, so bind on the first frame one
		# is actually there rather than assuming scene order — and bind to
		# `local_player`, since these are the numbers for the body this process
		# is playing, not for whoever is first in the party.
		_player = get_tree().get_first_node_in_group("local_player") as Player
		if _player == null:
			return
	var carried: CarriedWeight = _player.carried
	var stamina: Stamina = _player.stamina
	var health: Health = _player.health
	var clamor: ClamorSource = _player.clamor
	var bag: Inventory = _player.inventory
	var lines: PackedStringArray = PackedStringArray([
		"health    %5.1f / %.0f%s" % [
			health.current, health.maximum, "   DEAD" if health.is_dead() else "",
		],
		"speed     %5.2f m/s" % _player.planar_speed(),
		"stamina   %5.1f / %.0f" % [stamina.current, stamina.maximum()],
		# Cells beside kilograms, because `M2-T01` made them two different
		# constraints and a readout showing only one cannot tell you which of
		# them is the reason you had to leave something behind.
		"carrying  %5.1f kg  (%.0f%% laden)   %d/%d cells" % [
			carried.kilograms, carried.encumbrance() * 100.0,
			bag.cells_used(), bag.grid().x * bag.grid().y,
		],
		# The radius is the number that means something: DES-005 requires the
		# player to always know how much pressure they have made. "4.8 clamor"
		# is not actionable; "heard 7.7 m away" is.
		# Two radii, because they answer different questions. The first is how
		# far you carry *right now*; the second is the floor your bag imposes —
		# how far you carry standing perfectly still, which is the number
		# `DES-005`'s "drop it and go quiet" counter-play acts on.
		"clamor    %5.1f      heard %.1f m away   (%.1f m carrying this)" % [
			clamor.level, clamor.audible_radius(),
			clamor.carried_floor * Config.tuning.clamor_metres_per_unit,
		],
	])
	# `DES-019` Layer 3 puts the Waystone on the Burden layer and requires one
	# question to be answerable in a glance: **do I still have my way out?**
	# Binary, which only holds because ADR-015 caps it at one. The real Burden
	# layer is `M4-T05`; this is where it lives until then.
	lines.append("waystone  %s" % [
		"CARRIED" if bag.waystone() != null else "none",
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
	# Every prompt names both devices (`DES-019` rule 7, ADR-075). The weight
	# keys are gone rather than renamed: loot is the gameplay source of carried
	# weight from `M2-T01`, and a debug key that sets it behind the inventory's
	# back would be the second writer ADR-064 bans.
	lines.append("lmb/RT attack   e/X take   tab/LB bag   g/dpad-down drop   "
		+ "shift/L3 sprint   ctrl/B crouch   c/R3 toggle   i/Y ink   r reset")
	text = "\n".join(lines)
