class_name AspectCatalogue
extends RefCounted

## Every authored node of the tree, addressable by its stable id (`M3-T01`,
## `DES-004`).
##
## The same shape as `ItemCatalogue` and `ClassCatalogue`, **including the
## three-extension scan** — and for the reason ADR-086 reproduced deliberately:
## the repo holds `.tres` and an exported build does not, so a scan matching
## only `.tres` finds nothing in a shipped build while `load()` on the original
## path keeps working. A tree that comes back empty in an export is a build
## where no run can spend anything it earns.
##
## ## One Aspect exists
##
## `DES-004` lists five. **Hoard** is authored; `M3-T12` authors Wing and the
## remaining three are `M4`/`M5`. They are **absent, not stubbed** (ADR-064) —
## the tree screen draws what the catalogue holds, so an Aspect nobody has
## written is not a locked path with a padlock on it. It is not there.

const ASPECTS_ROOT: String = "res://data/aspects"
const PACKED_EXTENSIONS: Array[String] = ["tres", "res", "remap"]

## Keyed by `String`, never `StringName` — Godot treats the two as different
## dictionary keys, which produces a lookup that fails for a value that is
## demonstrably present.
static var _by_id: Dictionary = {}
static var _ids: Array[String] = []
static var _scanned: bool = false


## Every node, ordered by id so any two runs draw the tree identically.
static func all() -> Array[AspectNode]:
	_scan()
	var found: Array[AspectNode] = []
	for id: String in _ids:
		found.append(_by_id[id] as AspectNode)
	return found


## Every node of one Aspect, in tier order and then by id — which is the order
## the screen draws them in, so the keystone is never buried in the middle.
static func of_aspect(aspect: StringName) -> Array[AspectNode]:
	var found: Array[AspectNode] = []
	for node: AspectNode in all():
		if node.aspect == aspect:
			found.append(node)
	found.sort_custom(func(a: AspectNode, b: AspectNode) -> bool:
		if a.tier != b.tier:
			return a.tier > b.tier
		return String(a.id) < String(b.id))
	return found


## Which Aspects have any node authored at all. The screen asks this rather
## than `ClassResource.ASPECTS`, because a class may enter three and only one
## of them has been built — and a path with nothing in it is not a path.
static func authored() -> Array[StringName]:
	var seen: Array[StringName] = []
	for node: AspectNode in all():
		if not seen.has(node.aspect):
			seen.append(node.aspect)
	return seen


static func ids() -> Array[String]:
	_scan()
	return _ids.duplicate()


## The node behind a stable id, or `null` if nothing owns it — which is what a
## profile naming a node this build no longer has looks like. A migration
## question (`TEC-003`), never a crash.
static func by_id(id: StringName) -> AspectNode:
	_scan()
	return _by_id.get(String(id)) as AspectNode


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	var dir: DirAccess = DirAccess.open(ASPECTS_ROOT)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension() in PACKED_EXTENSIONS:
			_absorb("%s/%s" % [ASPECTS_ROOT, entry.trim_suffix(".remap")])
		entry = dir.get_next()
	dir.list_dir_end()
	_ids.sort()


static func _absorb(path: String) -> void:
	var node := load(path) as AspectNode
	if node == null:
		return
	var key: String = String(node.id)
	# First loaded wins. A duplicate is a corpus error and the data probe fails
	# the build over one; raising here would take down a running game for a
	# problem that cannot reach a commit.
	if _by_id.has(key):
		return
	_by_id[key] = node
	_ids.append(key)
