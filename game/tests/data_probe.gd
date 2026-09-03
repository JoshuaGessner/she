extends SceneTree

## `M2-T08` — load every authored resource and check it (`TEC-006`).
##
## `TEC-006` principle 4: *every resource is validatable*, and a CI pass loads
## every `.tres` and checks required fields, ID uniqueness and reference
## integrity. This is that pass. It runs in `tools/check_scripts.sh` beside the
## rig probe, because a data corpus rots exactly the way a rig does — silently,
## three tools away from the symptom.
##
## **Rules live with the resources, not here.** Each resource answers
## `validate()` about its own fields, the same shape `TuningProfile` already
## uses, because only the resource knows what its fields mean. What lives here
## is the two things no single resource can know: that its `id` is unique
## across the corpus, and that the corpus is not empty.
##
## ## What it deliberately does not check yet
##
## `TEC-006` lists six validator rules. **Two of the three that were absent
## arrived with `M3-T01`**, exactly as this note said they would: `AspectNode`
## exists, so dangling `requires` and tag-less nodes are both checked below and
## the promise *"each rule arrives with its data"* is kept rather than quoted.
## `telegraph_ms >= 250` is still **not implemented** because `AttackResource`
## arrives at `M4-T02`; the floor is meanwhile enforced where its data does live,
## in `TuningProfile.validate()`.
##
## That is not laziness, it is the lesson from `M1-T05`: two checks written
## there passed with the code deliberately broken, because neither had data
## that could distinguish a pass from a failure. **A rule with nothing to check
## is not a safeguard, it is a green tick that means nothing** — and a green
## tick that means nothing is worse than an absent check, because it stops
## anyone writing the real one. The telegraph floor is meanwhile genuinely
## enforced where its data actually lives today, in `TuningProfile.validate()`.

const DATA_ROOT: String = "res://data"

var _failures: int = 0
var _frame: int = 0
var _loaded: int = 0
var _items: Array[ItemResource] = []
var _nodes: Array[AspectNode] = []
var _classes: Array[ClassResource] = []
## Taken from the walk rather than from `Config`. This runs as `--script`,
## which builds a bare `SceneTree` with **no autoloads registered** — so
## `Config.tuning` is not merely empty here, it does not compile. The profile
## is a `.tres` under `data/` like everything else, so the corpus already has
## it and the rule that needs it can read it from there.
var _tuning: TuningProfile = null


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_run()
	return _frame >= 2


func _run() -> void:
	var paths: PackedStringArray = _resource_paths(DATA_ROOT)
	paths.sort()
	for path: String in paths:
		_check(path)

	_check_unique_ids()
	_check_catalogue_agrees()
	_check_items_fit_the_grid()
	_check_kits_can_be_worn()
	_check_the_tree_hangs_together()

	# A validator that validated nothing must never report success. This is
	# the single most important line in the file: every other check here is
	# conditional on there being data, and without this one a mistyped path,
	# a moved folder or an empty tree would produce a clean, meaningless pass.
	if _items.is_empty():
		_fail("no items found under %s — the validator checked nothing" % DATA_ROOT)
	# The same argument, for the tree. Every rule below it is conditional on
	# there being nodes, and a build that can earn Boon and spend it on nothing
	# is a build where `M3`'s whole goal is unreachable.
	if _nodes.is_empty():
		_fail("no aspect nodes found — nothing a run earns can be spent")
	# And for the classes, whose rule below is conditional on there being any.
	if _classes.is_empty():
		_fail("no classes found — every kit rule checked nothing")

	print("[data] %d resource(s), %d item(s), %d node(s)" % [
		_loaded, _items.size(), _nodes.size()])
	if _failures > 0:
		printerr("[data] FAIL — %d problem(s)" % _failures)
		quit(1)
		return
	print("[data] every resource loads and validates")
	quit()


## Every `.tres` under `root`, recursively. `DirAccess` rather than a hardcoded
## list, so a designer adding a folder gets it checked without editing this.
func _resource_paths(root: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		_fail("cannot open %s" % root)
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var path: String = "%s/%s" % [root, entry]
		if dir.current_is_dir():
			found.append_array(_resource_paths(path))
		elif entry.ends_with(".tres"):
			found.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


func _check(path: String) -> void:
	var resource: Resource = load(path)
	if resource == null:
		_fail("%s did not load" % path)
		return
	_loaded += 1

	var tuning := resource as TuningProfile
	if tuning != null:
		_tuning = tuning

	var sworn := resource as ClassResource
	if sworn != null:
		_classes.append(sworn)

	var node := resource as AspectNode
	if node != null:
		_nodes.append(node)
		var named: String = "%s.tres" % node.id
		if path.get_file() != named:
			_fail("%s holds node id '%s' — the file should be named %s"
				% [path, node.id, named])

	var item := resource as ItemResource
	if item != null:
		_items.append(item)
		# The file is named after its id, so a data tree can be searched by the
		# string a save file holds. Cheap to keep true, miserable to restore
		# once a hundred items disagree.
		var expected: String = "%s.tres" % item.id
		if path.get_file() != expected:
			_fail("%s holds id '%s' — the file should be named %s"
				% [path, item.id, expected])

	if not resource.has_method("validate"):
		_fail("%s has no validate() — TEC-006 principle 4" % path)
		return
	for problem: String in resource.call("validate"):
		_fail("%s: %s" % [path.get_file(), problem])


## `id` is what a save file stores (`TEC-003`), so two resources sharing one is
## a save that silently loads the wrong thing. No single resource can see this.
func _check_unique_ids() -> void:
	var seen: Dictionary = {}
	for item: ItemResource in _items:
		var key: String = String(item.id)
		if seen.has(key):
			_fail("id '%s' is used by both %s and %s"
				% [key, seen[key], item.resource_path.get_file()])
			continue
		seen[key] = item.resource_path.get_file()
	# Nodes get their own namespace: a save holds them in a different list, and
	# a node sharing an id with an item is confusing rather than broken.
	var node_ids: Dictionary = {}
	for node: AspectNode in _nodes:
		var key: String = String(node.id)
		if node_ids.has(key):
			_fail("node id '%s' is used by both %s and %s"
				% [key, node_ids[key], node.resource_path.get_file()])
			continue
		node_ids[key] = node.resource_path.get_file()


## The corpus on disk and the corpus the *game* can see must be the same set.
##
## This walk uses `DirAccess` over `.tres`; `ItemCatalogue` is what every
## running system actually asks, and it matches `.tres`, `.res` **and**
## `.remap` because Godot re-serialises text resources when it packs them. Two
## scans of the same folder is exactly the arrangement that rots silently, so
## they are compared rather than trusted — and this is the check that fails if
## the catalogue's idea of the item table ever drifts from the files, which
## ADR-086 records shipping once as an empty item table in a build that
## launched perfectly.
func _check_catalogue_agrees() -> void:
	var known: Array[String] = ItemCatalogue.ids()
	if known.size() != _items.size():
		_fail("the catalogue sees %d item(s), this walk found %d — they are "
			% [known.size(), _items.size()]
			+ "reading the same folder and must not disagree")
		return
	for item: ItemResource in _items:
		if ItemCatalogue.by_id(item.id) == null:
			_fail("'%s' is on disk but the catalogue cannot resolve it" % item.id)


## An item bigger than the bag can never be picked up (`M2-T01`, `DES-019`).
##
## Cross-resource, so it cannot live on `ItemResource`: the item knows its
## footprint and `TuningProfile` knows the grid, and neither can see the other.
## That is the division `TEC-006` draws, and this is the second question this
## file owns after ID uniqueness.
##
## Rotation counts. A 1x4 spear fits a 6-wide, 5-tall grid upright, and would
## also fit turned; a 7x1 pole fits neither way and is unpickupable content —
## authored, validating, and dead.
func _check_items_fit_the_grid() -> void:
	# No profile means the rule cannot run, and a rule that cannot run must say
	# so rather than pass (ADR-084). The corpus is required to contain one.
	if _tuning == null:
		_fail("no TuningProfile in the corpus — item footprints cannot be "
			+ "checked against the bag they have to fit in")
		return
	var grid: Vector2i = _tuning.inventory_grid
	for item: ItemResource in _items:
		var size: Vector2i = item.grid_size
		var upright: bool = size.x <= grid.x and size.y <= grid.y
		var turned: bool = size.y <= grid.x and size.x <= grid.y
		if not upright and not turned:
			_fail("'%s' is %s and the bag is %s — it can never be picked up, "
				% [item.id, size, grid] + "in either orientation")


## **A class has to be able to hold its own kit** (`M4-T13`, `DES-020`).
##
## `ClassResource.kit` has always been documented as *"real definitions from the
## catalogue — an id nothing knows fails `validate()` rather than silently
## arming somebody with nothing."* **Nothing checked it.** The comment described
## a guard that was never built, which is ADR-098's question asked of a promise
## instead of a function, and it went unnoticed because the two authored kits
## happened to be correct.
##
## `M4-T13` walked straight into the gap. `_dress_the_body` equips a kit in
## array order and `Equipment.equip` *displaces* whatever conflicts, discarding
## it — so adding a lantern to the Veiðimaðr, whose bow is two-handed, would
## have spawned a bow-less archer holding a lamp. No error, no warning, and a
## class that reads as broken rather than as misconfigured.
##
## Here rather than in `ClassResource.validate()` because every rule needs the
## *item* corpus, and a resource may only answer for its own fields.
func _check_kits_can_be_worn() -> void:
	var by_id: Dictionary = {}
	for item: ItemResource in _items:
		by_id[String(item.id)] = item

	for sworn: ClassResource in _classes:
		var filled: Dictionary = {}
		var two_handed: String = ""
		var off_hand: String = ""
		for id: StringName in sworn.kit:
			# 1. **The id resolves.** The rule the header promised.
			var item := by_id.get(String(id)) as ItemResource
			if item == null:
				_fail(("%s descends with '%s', which no item in the corpus "
					+ "owns — that is a class armed with nothing, silently")
					% [sworn.id, id])
				continue
			if item.slot == Enums.Slot.NONE:
				_fail("%s descends with '%s', which occupies no slot and so is "
					% [sworn.id, id] + "dropped on the floor of `_dress_the_body`")
				continue
			# 2. **One item per slot.** Two body pieces in a kit means the
			# second silently replaces the first, and which one survives is
			# array order — the ordering dependency `TEC-007` §1 rules out.
			var slot: String = Enums.Slot.keys()[item.slot]
			if filled.has(slot):
				_fail(("%s descends with both '%s' and '%s' in %s — one of them "
					+ "is discarded, and which depends on kit order")
					% [sworn.id, filled[slot], id, slot])
			filled[slot] = String(id)
			if item.slot == Enums.Slot.MAIN_HAND and item.two_handed:
				two_handed = String(id)
			elif item.slot == Enums.Slot.OFF_HAND:
				off_hand = String(id)
		# 3. **A two-hander leaves no off hand** (`DES-020`: *"no lantern, no
		# shield, no map without stowing"*). The rule is already enforced at
		# runtime by `Equipment.equip`; what is missing is anyone noticing that
		# a *kit* asking for both means one of them never arrives.
		if two_handed != "" and off_hand != "":
			_fail(("%s descends with two-handed '%s' and off-hand '%s' — "
				+ "`Equipment` gives the off hand to the two-hander, so "
				+ "whichever is equipped second disarms the first")
				% [sworn.id, two_handed, off_hand])


## **The tree has to be walkable** (`M3-T01`, `TEC-006`).
##
## Three questions no single node can answer about itself, and each is a way a
## tree can be authored into something a player can see and never reach.
func _check_the_tree_hangs_together() -> void:
	var by_id: Dictionary = {}
	for node: AspectNode in _nodes:
		by_id[String(node.id)] = node

	for node: AspectNode in _nodes:
		# 1. **Dangling `requires`** — `TEC-006`'s named rule, and the reason a
		#    node becomes permanently unreachable rather than merely expensive.
		for needed: StringName in node.requires:
			if not by_id.has(String(needed)):
				_fail("'%s' requires '%s', which nothing authors — that node can "
					% [node.id, needed] + "never be taken by anybody")
				continue
			# 2. **Across Aspects.** A prerequisite in another path means the
			#    node is gated on an Aspect a class may not even be allowed to
			#    enter, which is a lockout nothing in the UI could explain.
			var before := by_id[String(needed)] as AspectNode
			if before.aspect != node.aspect:
				_fail("'%s' is a %s node requiring '%s' from the %s — a path "
					% [node.id, node.aspect, needed, before.aspect]
					+ "cannot depend on one a class may not enter (ADR-009)")

		# 3. **Cycles.** Two nodes each waiting on the other are both authored,
		#    both valid on their own, and both unreachable forever.
		if _requires_itself(node, by_id, {}):
			_fail("'%s' is in a `requires` cycle — every node in it is "
				% node.id + "permanently unreachable")

	# The keystone is what a build is named after (`DES-004`), so an Aspect
	# without one is a path with no destination.
	var keystones: Dictionary = {}
	for node: AspectNode in _nodes:
		if node.tier == AspectNode.Tier.KEYSTONE:
			keystones[String(node.aspect)] = true
	for node: AspectNode in _nodes:
		if not keystones.has(String(node.aspect)):
			_fail("the %s has nodes but no keystone — `DES-004` makes the "
				% node.aspect + "keystone the thing a build is named after")
			break


## Depth-first, carrying the path so a cycle is found rather than recursed into
## forever. `seen` is by value at each level on purpose: this asks whether a
## node reaches *itself*, not whether the graph has any cycle anywhere.
func _requires_itself(node: AspectNode, by_id: Dictionary, seen: Dictionary) -> bool:
	if seen.has(String(node.id)):
		return true
	seen[String(node.id)] = true
	for needed: StringName in node.requires:
		var before := by_id.get(String(needed)) as AspectNode
		if before == null:
			continue
		if _requires_itself(before, by_id, seen.duplicate()):
			return true
	return false


## **The free-money rule is gone, and its absence is the decision** (ADR-089).
##
## It asked whether a tributable item cost either weight or clamor, because
## without one of those a valuable item was free to carry. `M2-T02` closed that
## hole in the design rather than in the validator: the Gullsjúkr senses
## **carried tribute value through walls** (`DES-017`), so *every* item with
## `tribute_value > 0` now costs something by construction — it makes you
## legible to the thing hunting you, whatever it weighs and however quiet it is.
##
## Which means the rule could no longer fail. A check whose premise the design
## has made unfalsifiable is exactly the green tick ADR-084 and ADR-088 both
## spend their rationale on: it reads as coverage and provides none, and the
## next person to look sees a guarded corpus that is not guarded. Deleted
## rather than weakened into something that always passes.
##
## `glt_raw_gemstone` lost its `clamor` in the same change — `DES-005` says
## *"gems are light and silent"*, and it had only been loud to satisfy this
## rule. Its cost is now the one `DES-008` always described: it catches every
## light in the dark, including the ones looking for it.


func _fail(message: String) -> void:
	printerr("[data] FAIL %s" % message)
	_failures += 1
