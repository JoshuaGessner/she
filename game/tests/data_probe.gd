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
## `TEC-006` lists six validator rules. Three of them — `telegraph_ms >= 250`,
## dangling `requires` in skill nodes, keystones with no `effect_tags` — are
## **not implemented, because the resources they check do not exist.**
## `EnemyResource` arrives with `M4-T02`, `SkillNodeResource` with `M3-T01`,
## and each rule arrives with its data.
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

	# A validator that validated nothing must never report success. This is
	# the single most important line in the file: every other check here is
	# conditional on there being data, and without this one a mistyped path,
	# a moved folder or an empty tree would produce a clean, meaningless pass.
	if _items.is_empty():
		_fail("no items found under %s — the validator checked nothing" % DATA_ROOT)

	print("[data] %d resource(s), %d item(s)" % [_loaded, _items.size()])
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


func _fail(message: String) -> void:
	printerr("[data] FAIL %s" % message)
	_failures += 1
