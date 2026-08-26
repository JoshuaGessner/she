class_name Inventory
extends Node

## One bag: a grid of cells holding `ItemInstance`s (`M2-T01`, `DES-019`).
##
## **One inventory, grid-based, weighted, real-time** (ADR-040, reaffirmed by
## ADR-083). Not a prototype fork — the second model was a stale line in
## `PRO-001` that survived two days past the ADR closing it, and building both
## would be the parallel path ADR-064 bans applied to what `DES-019` itself
## calls the single largest UI item in the project.
##
## ## The two constraints exist to disagree
##
## `DES-019`: *"a bulky-but-light bolt of cloth and a tiny-but-ruinous bag of
## coin pose different problems."* Space is this grid; weight is `CarriedWeight`
## and through it movement, stamina, jump and footstep noise. Measured against
## the authored corpus at a 6x5 grid and a 40 kg capacity, they genuinely
## disagree today and in the direction `DES-008` wants:
##
## | A full bag of | Cells | Weight | Laden |
## |---|---|---|---|
## | gear — spear, hammer, byrnie, seax, blade | 25/30 | 24.3 kg | 61% |
## | glitter — two plates, two coin, a torc | 30/30 | 48.8 kg | 100% |
##
## Same grid, same thirty squares, and twice the price. *She wants what
## glitters, not what works* (`DES-008`) is a spatial fact rather than a
## flavour line: glitter is dense in kilograms, gear is dense in squares.
## `--bag-probe` measures the spread rather than trusting this table, and fails
## if it ever collapses.
##
## ## Weight does not refuse a pickup, and must not start
##
## > **Space decides what you can carry. Weight decides what it costs you.**
##
## `add()` checks the grid and nothing else. That is deliberate and it is the
## design rather than an omission: ADR-050's *"modest slot cap"* is this grid,
## `carry_capacity` is the denominator `CarriedWeight` measures encumbrance
## against, and that penalty is itself clamped at 1.0 so an overloaded player
## is slow and loud rather than stuck. A hard weight refusal would make the two
## constraints the same kind of thing — two walls — when what `DES-019` wants
## is one wall and one price.
##
## `--bag-probe` asserted the opposite first, failed, and was wrong. Recorded
## here because the next reader will otherwise notice the missing check and
## helpfully add it.
##
## ## Who owns a bag
##
## **The host owns all of it, arrangement included.** `TEC-004` gives the
## owning peer its body's transform and the host every consequence, and what is
## in your bag is as consequential as your health. Rearranging within the grid
## could defensibly have been owner-authoritative — it changes no outcome — but
## a second authority over the same array buys about 60 ms of drag latency at
## the price of two writers and a reconciliation rule, and `player.gd` already
## records why half-prediction is the wrong trade. One authority. If dragging
## feels laggy on a real link, that is an M4 revision with playtest data behind
## it.
##
## The owning client is *sent* the whole bag on every change. Whole, not a
## delta: a bag is at most a few dozen rows and changes on pickup rather than
## per frame, so the cheap version is also the one that cannot drift.

signal changed()

var _items: Array[ItemInstance] = []
## Monotonic per bag. Never reused within a run, so an in-flight RPC naming a
## dropped item can never be applied to whatever took its square.
var _next_instance_id: int = 1


## Cells wide and tall. `DES-020` gives this to the **Pack slot** — bigger pack,
## more grid, more weight, more Clamor, *"the upgrade that makes you more
## powerful is the upgrade that makes you louder"*. Slots are `M3-T07`, so
## until then every player carries the profile's grid and the Pack overrides it
## when it exists. That is an ordering decision, not a fallback: the number has
## one home now and one home later, never two at once, and the profile value
## becomes the Q106 *no pack* grid it already has to be.
func grid() -> Vector2i:
	return Config.tuning.inventory_grid


func items() -> Array[ItemInstance]:
	return _items


func count() -> int:
	return _items.size()


func find(instance_id: int) -> ItemInstance:
	for item: ItemInstance in _items:
		if item.instance_id == instance_id:
			return item
	return null


## Kilograms carried. Drives `CarriedWeight`, which is the **only** weight path
## in the project — movement, stamina, jump and footstep volume all already
## read it, so loot arrives in the player's legs without a second mechanism.
## **Scavenger** (`hrd_scavenger`) and **Weight of Kings** both land here.
##
## Set by the body from its own `effects` — a component never reaches up to ask
## (`CLAUDE.md`: signals up, calls down), and the body is the only thing that
## knows whose tree it is carrying.
var weightless_materials: bool = false
var unlimited: bool = false
var weight_costs_double: bool = false


func total_weight() -> float:
	var sum: float = 0.0
	for item: ItemInstance in _items:
		# Raw stock is ballast you can sell rather than treasure, and a Hoard
		# build stops paying to carry it. Tag rather than id prefix, so a
		# material authored tomorrow is covered without editing this.
		if weightless_materials and item.definition.tags.has(&"material"):
			continue
		sum += item.weight()
	return sum * (2.0 if weight_costs_double else 1.0)


## What the bag gives away, on `TuningProfile`'s clamor scale. `DES-008` names
## clamor *the audible cost of greed*, and `DES-005` makes dropping loot the
## primal counter-play — so this number has to fall the instant something
## leaves the bag, and it does.
func total_clamor() -> float:
	var sum: float = 0.0
	for item: ItemInstance in _items:
		sum += item.clamor()
	return sum


func cells_used() -> int:
	var sum: int = 0
	for item: ItemInstance in _items:
		var size: Vector2i = item.footprint()
		sum += size.x * size.y
	return sum


## The single item costing you the most to carry. This is what a panic-drop
## reaches for (`Player`), and weight rather than clamor because `DES-005`
## Layer 1 is explicit that the thing you feel is in your legs.
func heaviest() -> ItemInstance:
	var worst: ItemInstance = null
	for item: ItemInstance in _items:
		if worst == null or item.weight() > worst.weight():
			worst = item
	return worst


## The single most valuable thing you carry. What a **bait** reaches for
## (`DES-017`): the Gullsjúkr is drawn by tribute, so the purse worth throwing
## is the one she would pay most for — deliberately a different item from
## `heaviest()`, which is what a panic dump reaches for. The two answers
## disagreeing is the point.
func richest() -> ItemInstance:
	var best: ItemInstance = null
	for item: ItemInstance in _items:
		if best == null or item.definition.tribute_value > best.definition.tribute_value:
			best = item
	return best


## The embers in your bag — the peers whose lives you are carrying (`DES-012`).
## Their weight and noise are already counted by `total_weight` and
## `total_clamor` like anything else, which is exactly what makes a rescue a
## sacrifice rather than a formality.
func embers() -> Array[int]:
	var borne: Array[int] = []
	for item: ItemInstance in _items:
		if item.bound_to != 0:
			borne.append(item.bound_to)
	return borne


## Everything you are carrying, as she would price it. **This is what the
## Gullsjúkr senses through walls** — going quiet is not enough, because it is
## not listening for this (`DES-017`).
func total_tribute() -> int:
	var sum: int = 0
	for item: ItemInstance in _items:
		sum += item.definition.tribute_value
	return sum


# ── space ─────────────────────────────────────────────────────────────────


## Would `footprint` sit legally at `at`? `ignore` exempts one item, which is
## what makes moving an item onto squares it already covers work.
func fits(footprint: Vector2i, at: Vector2i, ignore: ItemInstance = null) -> bool:
	var size: Vector2i = grid()
	if at.x < 0 or at.y < 0:
		return false
	if at.x + footprint.x > size.x or at.y + footprint.y > size.y:
		return false
	for other: ItemInstance in _items:
		if other == ignore:
			continue
		if _overlaps(at, footprint, other.cell, other.footprint()):
			return false
	return true


## First legal square for `footprint`, scanning row-major, or `(-1, -1)`.
func find_space(footprint: Vector2i, ignore: ItemInstance = null) -> Vector2i:
	var size: Vector2i = grid()
	for y: int in range(size.y):
		for x: int in range(size.x):
			var at := Vector2i(x, y)
			if fits(footprint, at, ignore):
				return at
	return Vector2i(-1, -1)


## Where a new item would land, and whether it has to be turned to land at all.
## Upright first so a bag packs predictably; rotation is the fallback that lets
## a 1x4 spear into a grid only 4 tall in one direction.
func placement_for(definition: ItemResource) -> Dictionary:
	var upright: Vector2i = definition.grid_size
	var at: Vector2i = find_space(upright)
	if at.x >= 0:
		return {"cell": at, "rotated": false}
	if upright.x == upright.y:
		return {"cell": Vector2i(-1, -1), "rotated": false}
	at = find_space(Vector2i(upright.y, upright.x))
	return {"cell": at, "rotated": true}


## How many of this definition the bag already holds.
func count_of(definition: ItemResource) -> int:
	var found: int = 0
	for item: ItemInstance in _items:
		if item.definition.id == definition.id:
			found += 1
	return found


## Some items cap below what the grid would allow — today only the Waystone,
## at one (ADR-015, Q54). **That cap is a UI decision as much as a balance
## one:** `DES-019` requires the Waystone indicator to be binary and
## answerable in a glance, one lit or unlit mark, and a player holding two
## would make that mark a lie.
##
## Enforced here rather than by trusting loot never to offer a second, because
## `M4-T01`'s tables will be generated and generated things offer seconds.
func within_cap(definition: ItemResource) -> bool:
	for item_trait: ItemTrait in definition.traits:
		var extraction := item_trait as ExtractionTrait
		if extraction == null:
			continue
		if count_of(definition) >= extraction.carry_cap:
			return false
	return true


## The way out you are carrying, or `null`. `DES-019`'s Burden layer asks one
## question of this — *do I still have my way out?* — and the cap above is what
## keeps the answer to it a single bit.
func waystone() -> ItemInstance:
	for item: ItemInstance in _items:
		if item.definition.has_trait(ExtractionTrait):
			return item
	return null


static func _overlaps(a_at: Vector2i, a_size: Vector2i,
		b_at: Vector2i, b_size: Vector2i) -> bool:
	return (a_at.x < b_at.x + b_size.x and b_at.x < a_at.x + a_size.x
		and a_at.y < b_at.y + b_size.y and b_at.y < a_at.y + a_size.y)


# ── mutation (host only; `Player` is what enforces that) ──────────────────


## Put a new item in the first square it fits. `null` when the bag is full,
## which is the answer a pickup request needs — a bag that silently swallowed
## an item it had no room for would break the spatial half of the design.
func add(definition: ItemResource) -> ItemInstance:
	if not within_cap(definition):
		return null
	var placement: Dictionary = placement_for(definition)
	var at: Vector2i = placement["cell"] as Vector2i
	# **Weight of Kings** (`hrd_weight_of_kings`). `DES-004`'s own keystone:
	# *"no carry limit; instead every item you carry adds noise and slows you.
	# You can haul the whole vault. The dungeon will hear you do it."*
	#
	# The grid stops refusing and stops being the constraint; weight and noise
	# become the whole of it, at double rate. `within_cap` still holds, because
	# that one is not a capacity rule — it is `DES-019`'s single bit about
	# whether you still have your way out, and two Waystones would make that
	# mark a lie whatever your tree says.
	if at.x < 0 and unlimited:
		at = Vector2i.ZERO
	elif at.x < 0:
		return null
	var made := ItemInstance.of(definition, _next_instance_id)
	_next_instance_id += 1
	made.cell = at
	made.rotated = bool(placement["rotated"])
	_items.append(made)
	changed.emit()
	return made


func remove(instance_id: int) -> ItemInstance:
	var item: ItemInstance = find(instance_id)
	if item == null:
		return null
	_items.erase(item)
	changed.emit()
	return item


## Move an item within the grid. Refuses illegal packings rather than clamping
## them: the request came over the wire, and a bag that quietly accepted an
## overlap would corrupt every space search after it.
func move(instance_id: int, to: Vector2i, rotated: bool) -> bool:
	var item: ItemInstance = find(instance_id)
	if item == null:
		return false
	var size: Vector2i = item.definition.grid_size
	var footprint: Vector2i = Vector2i(size.y, size.x) if rotated else size
	if not fits(footprint, to, item):
		return false
	item.cell = to
	item.rotated = rotated
	changed.emit()
	return true


func clear() -> void:
	if _items.is_empty():
		return
	_items.clear()
	changed.emit()


# ── the wire form ─────────────────────────────────────────────────────────


func pack() -> Array:
	var rows: Array = []
	for item: ItemInstance in _items:
		rows.append(item.to_wire())
	return rows


## Replace everything with what the host says is there. The whole bag, so a
## dropped packet costs one stale frame rather than a permanent disagreement.
func unpack(rows: Array) -> void:
	_items.clear()
	for row: Variant in rows:
		var item: ItemInstance = ItemInstance.from_wire(row as Dictionary)
		if item != null:
			_items.append(item)
	changed.emit()
