extends SceneTree

## **Which floors the generator makes, held still** (B183).
##
## A fixed panel of seeds and depths is planned, and each plan's digest is
## compared against `plan_digests.txt`. Two things are true of the generator
## and both need this: it is deterministic (`TEC-001`: a run seed must be
## replayable), and its floors are *tuned* — the vista panel, the reach panel
## and the glint guarantee were all measured on floors that only exist while
## every plan stays the plan it was. A refactor meant to change nothing
## (B159 read the corridor search's queue by index) had to prove itself with a
## one-off script; this makes that proof the standing rule.
##
## A change that *should* make different floors is made by regenerating the
## file on purpose and saying why in the commit:
##   Godot --headless --path game --script tests/plan_digest_probe.gd -- --write

const PANEL_SEEDS: Array[int] = [7919, 15838, 23757, 31346, 39595, 47514, 55433,
	63352, 71271, 79190, 87109, 95028]
const DIGESTS: String = "res://tests/plan_digests.txt"


func _initialize() -> void:
	var modules: Array[RoomModule] = RoomCatalogue.all()
	var calamities: Array[CalamityResource] = CalamityCatalogue.all()
	var kinds := PackedStringArray()
	for module: RoomModule in modules:
		if not module.prize_kind.is_empty() and not kinds.has(module.prize_kind):
			kinds.append(module.prize_kind)
	kinds.sort()
	var made: PackedStringArray = PackedStringArray()
	for run_seed: int in PANEL_SEEDS:
		for depth: int in 3:
			var graph: MissionGraph = MissionGraph.build(run_seed, depth)
			var lore: ExpeditionHistory = ExpeditionHistory.roll(run_seed, calamities, kinds)
			var plan: FloorPlan = FloorPlan.build(graph, run_seed, depth, modules, lore)
			# The digest is the seating and the routes; the carved corners (which
			# rooms stand as an L, a T or a cross) are not in it, so they are added.
			var carved: PackedStringArray = PackedStringArray()
			for node: int in graph.size():
				carved.append(str(plan.notches_of(node)))
			made.append("%d %d %s|%s" % [run_seed, depth, plan.digest(), ";".join(carved)])
	if OS.get_cmdline_user_args().has("--write"):
		var out := FileAccess.open(DIGESTS, FileAccess.WRITE)
		out.store_string("\n".join(made) + "\n")
		print("[digest] wrote %d plan digest(s) to %s" % [made.size(), DIGESTS])
		quit(0)
		return
	var kept: PackedStringArray = FileAccess.get_file_as_string(DIGESTS).strip_edges().split("\n")
	var differ: PackedStringArray = PackedStringArray()
	for i: int in made.size():
		if i >= kept.size() or kept[i] != made[i]:
			differ.append(made[i].get_slice(" ", 0) + "/" + made[i].get_slice(" ", 1))
	print("[digest] %d of %d floor(s) planned as kept (want all)" % [made.size() - differ.size(), made.size()])
	if kept.size() != made.size() or not differ.is_empty():
		printerr(("[digest] FAIL these floors are no longer the floors they were: %s — "
			+ "if that is meant, regenerate tests/plan_digests.txt with --write and say why")
			% ", ".join(differ.slice(0, 6)))
		quit(1)
		return
	quit(0)
