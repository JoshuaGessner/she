class_name ExpeditionHistory
extends RefCounted
## `M4-T01` step 2 — the history, rolled before a single room is placed.
##
## `DES-015` Layer 2: *"Generate the history first, then generate the space to
## express it."* Each expedition rolls three things — the **Calamity** (what
## happened here), the **Prize** (what is at the bottom worth having) and the
## **Claimant** (who holds it now) — and the floors are then built to express
## them. Rolled per *expedition*, not per floor: all three floors are the same
## disaster, read backward as you descend.
##
## ## Why the Claimant is rolled before anything reads it
##
## The Calamity and the Prize both have readers today: they weight which room
## modules a floor is built from (`DES-015` step 5). The Claimant does not —
## who holds the Prize becomes visible through enemies, and enemies are
## `M4-T02`.
##
## It is rolled anyway, and the reason is **seed stability**. `TEC-001` calls
## the run seed's shareability non-negotiable; a seed on a death screen or in a
## bug report has to name the same expedition later. Adding a third draw to this
## stream after the fact would shift every subsequent value and silently
## repurpose every seed anybody had written down. Drawing it now costs one value
## and fixes the stream's shape.
##
## That is a real cost and worth naming: until `M4-T02`, the Claimant is decided
## and only *observed* — it is in `digest()`, so two machines must agree about it
## and a probe asserts the history varies with the seed. It is not absent and it
## is not a stub; it is a fact about the expedition that nothing dramatises yet.
##
## **There is deliberately no `claimant()` accessor.** `check_dead.py` refused
## one, and it was right to: an accessor nothing calls is a name that reads as
## alive and answers no question. The value is rolled, hashed and agreed upon;
## the getter arrives with the enemies that read it.


## Which pipeline stage this is (`DES-015`), mixed into the seed so no two
## stages can draw the same numbers from the same run seed.
const STAGE: int = 2

## Who holds the Prize now (`DES-015` Layer 2). Read by `M4-T02`; see the class
## note for why it is rolled before it has a reader. The order is the wire
## order — it is in `digest()`. Append, never insert.
const CLAIMANTS: Array[StringName] = [
	&"draugr", &"dvergar_remnant", &"vaettir", &"a_bound_crew_six_days_ahead",
]

var _calamity: CalamityResource = null
var _prize: StringName = &""
var _claimant: StringName = &""


## Roll the history for one expedition.
##
## `prizes` is normally every prize kind the room corpus can build, so the roll
## cannot name a Prize no floor could hold. It is a parameter so a probe can pin
## a corpus rather than depend on what happens to be on disk.
static func roll(run_seed: int, calamities: Array[CalamityResource],
		prizes: Array[StringName]) -> ExpeditionHistory:
	var history := ExpeditionHistory.new()
	if calamities.is_empty() or prizes.is_empty():
		return history
	var rng := RandomNumberGenerator.new()
	rng.seed = MissionGraph._mix(MissionGraph._mix(run_seed) + STAGE)
	# Fixed draw order. Moving it, or inserting a draw before an existing one,
	# changes what every already-logged seed means.
	history._calamity = calamities[rng.randi_range(0, calamities.size() - 1)]
	history._prize = prizes[rng.randi_range(0, prizes.size() - 1)]
	history._claimant = CLAIMANTS[rng.randi_range(0, CLAIMANTS.size() - 1)]
	return history


func calamity() -> CalamityResource:
	return _calamity


## Which kind of Prize sits at the bottom. A `RoomModule` serving the Prize node
## must declare this kind, so the room the player walks into is the one the
## history promised.
func prize_kind() -> StringName:
	return _prize


## Does this module lean toward what happened here? On-theme modules are
## weighted up when a floor is built; neutral ones can appear under any
## Calamity, which is what keeps a floor from reading as a single note.
func favours(module: RoomModule) -> bool:
	if _calamity == null:
		return false
	for tag: StringName in module.tags:
		if _calamity.tags.has(tag):
			return true
	return false


## A stable one-line fingerprint, folded into `WorldHash` so two machines must
## agree about the history before they build a room from it.
func digest() -> String:
	var named: StringName = _calamity.id if _calamity != null else &"none"
	return "%s/%s/%s" % [named, _prize, _claimant]
