extends Node

## What outlives a run (`M2-T06`, `DES-014`, `DES-003`).
##
## The third of `TEC-001`'s six autoloads, registered now because it finally
## has work (ADR-066): until `M2-T04` closed the loop there was nothing that
## survived leaving the floor, and until `M2-T06` there was nowhere to put it.
##
## ## Three tiers, and they are not the same thing
##
## `DES-003` and `DES-014` are precise about what survives what, and the whole
## emotional architecture rests on the difference:
##
## | | Survives a run | Survives death |
## |---|---|---|
## | **What you carried** | only if you extracted | no |
## | **The stash** | yes | **no** — the great reset (`DES-008`) |
## | **The hoard** | yes | **yes, always** (LINEAGE tier) |
##
## The hoard is the one that matters most and costs least. `DES-014`: *"a
## permanent physical monument to every life you have lost, which turns
## ADR-004's harshness into something you can walk on"* — visible progress with
## **zero balance impact**, which makes it the safest retention mechanism in
## the design.
##
## ## Saved to disk since `M3-T06`
##
## `SaveFile` owns the format, the versioning and the migrations; this owns what
## goes in it. The split is `TEC-003`'s: *what* persists is a design question
## and *how* is not, and the one-function death operation — clear LIFE, keep
## LINEAGE — is already how `die()` below is written.
##
## **Writing only happens once a profile has been opened.** `_live` is false
## until `load_profile()` succeeds, which means a process that never opened one
## never writes one: a probe booting a level directly mutates this in memory and
## leaves the player's profile alone, and a build that *refused* a profile it
## could not read cannot then overwrite it. That is not a probe accommodation —
## a save is a thing you write *back*, and there is nothing to write back to
## until something was read.
##
## ## Never networked
##
## `DES-012` makes every pact individual and `TEC-004` keeps progression off
## the wire entirely. This is local state on every peer, describing only the
## person sitting at that machine. ADR-021 makes that structural rather than
## careful: the Chamber where it all lives is a scene no other player enters.

## What you walked out of the Deep with, waiting to be sorted. Emptied by the
## Chamber once you have decided what she keeps.
var carried: Array[ItemInstance] = []

## Kept for next time. **Wiped by death** (`DES-008`'s great reset) — which is
## what stops an economy inflating across a lineage and is why this design
## needs no late-game nerfs.
var stash: Array[ItemInstance] = []

## Given to her. **Never wiped, ever.** Stored as ids and values rather than
## instances because nothing ever comes back off the pile — she is lying on it.
var hoard: Array[StringName] = []
var hoard_value: int = 0
## **What this lineage has learned** (`M3-T03`, ADR-011, `DES-003`).
##
## LINEAGE tier, so it is the one thing here that death does not touch. It is
## **power-free by construction** — `DES-003` is explicit that a lineage-40
## player and a lineage-1 player at the same Pact Rank must die to the same
## floor at the same rate, so nothing may ever read this and hand out a number.
## `M3-T05` is what spends it, on Legacy slots.
var lineage_progress: int = 0
## **What she agreed to remember** (`M3-T05`, ADR-003, `DES-003`).
##
## LINEAGE tier: these are the bridge across death and the only thing that
## crosses it besides knowledge. At most `legacy_slot_count` of them, each one
## `{"kind": "item"|"node", "id": ...}` — **never raw Boon**, which ADR-003
## disallows because a fungible payload is the optimal pick every time and
## collapses the death screen into percentage retention with extra UI.
## **What this lineage is known for** (`M3-T08`, `DES-016`).
##
## LINEAGE tier, always, and `DES-003` explains why that is safe to be generous
## with: it is power-free by construction. A camp full of marks says something
## about a player and gives them nothing.
##
## `{id: who}` rather than a list, because ADR-050 puts **another player's name**
## in your save for a rescue — *"rescue deeds record who you carried out"* — and
## that is the first time this profile stores anyone but you. `""` for the deeds
## that are about nobody.
var deeds: Dictionary = {}
## Earned this run and not yet shown. `DES-016`: **no popups mid-run**, they
## break the pressure the whole game is built on — so a deed waits here and
## surfaces at the Settle beat, after the tribute decision.
var fresh_deeds: Array[String] = []
var legacy: Array[Dictionary] = []
## **What the last life had to offer**, snapshotted the instant before the wipe.
##
## LINEAGE tier so that quitting between the death and the choice cannot dodge
## either: the life is already over — `die()` is still the one-function
## operation `TEC-003` describes — and this is the record the Legacy screen
## chooses *from*. Coming back later and picking is allowed; coming back later
## and being alive is not.
var last_life: Dictionary = {}

## Runs completed this session, for the readouts. Not progression; `DES-003`'s
## Pact Rank is `M3-T04` and is a different number with different rules.
##
## **Deliberately not saved.** Its own name is "this session", and `TEC-003`'s
## LIFE-tier `run_count` is a different number that counts against a Tithe
## cycle. It arrives with `M3-T04`, which is the first build in which there is
## a cycle to count against.
## How many times this lineage has gone down. Drives the camp readout and
## `AudioDirector`'s company layer, which is the thing that makes the Threshold
## fill out as you keep coming back (ADR-050).
##
## **LINEAGE tier** (save v9, ADR-149): it counts descents rather than a life's
## descents, `die()` does not touch it, and it was absent from `to_dict`
## entirely — so the camp went back to sounding empty every time the game was
## relaunched, and the readout under-counted from the second session on.
var descents: int = 1

## **The pact** (`M3-T04`, `DES-003`). LIFE tier, all of it: `die()` puts every
## one of these back where a new life starts.
##
## **Rank is derived, not stored** (`M3-T01`, ADR-125). `DES-003` says *"every
## point of Boon spent raises your Tithe"*, so rank **is** what the tree cost
## you — and a stored copy is a second source of truth that can disagree with
## the nodes that earned it. It reads as a field because every call site already
## did; nothing can assign it, and that is the point.
##
## It sat at 1 for the whole of `M3-T04` and `M3-T10`, which built a nine-row
## Tithe table and three axes of floor scaling against a number nothing could
## move (ADR-124 §3). This is the task that moves it.
var pact_rank: int:
	get:
		var per: int = maxi(1, Config.tuning.boon_per_rank)
		var top: int = maxi(1, Config.tuning.tithe_by_rank.size())
		return clampi(1 + boon_spent() / per, 1, top)

## **Boon** (`DES-004`). Unspent points, and the surplus tribute working toward
## the next one. Both LIFE tier — `DES-003`'s reset table gives the skill tree
## as *"all of it"*.
var boon: int = 0
var boon_progress: int = 0
## Tribute value already converted this cycle (`M3-T03`). LIFE tier, and reset
## by the cycle rather than by the run: the Tithe is the accounting period the
## whole obligation is measured in, so the cap is measured in it too.
var boon_converted: int = 0

## Node ids taken this life, in the order they were taken. The **only** record
## of the tree: rank, spend and what you can reach next are all read off this,
## so there is nothing to keep in step with it.
var taken: Array[StringName] = []

## Tribute value handed to her since the cycle last closed.
var tithe_paid: int = 0

## Runs finished in this cycle. **Only a finished run moves it**, which is what
## makes `PRO-005 §11` hold for free: quitting mid-cycle leaves the count
## exactly where it was, however long you stay away.
var cycle_runs: int = 0

## Seconds of Hunt already elapsed when the next descent begins — what missing
## a cycle costs (ADR-118). Consumed by the descent that pays it.
var hunt_head_start: float = 0.0

## Who you are this life (`M3-T02`, `DES-011`). **Chosen at the start of a life
## and locked until death** — so it is LIFE tier, and `die()` clears it, which
## is what makes ADR-009's *"death becomes the door to a new class"* true rather
## than a sentence in a doc.
##
## Empty means no class has been chosen, which is exactly the state a fresh
## profile is in and the condition the select screen opens on.
var class_id: StringName = &""

## **What this life is wearing** (`M3-T07`, `DES-020`). Slot name → item id.
##
## LIFE tier, beside the stash: gear is `DES-008`'s *record of where you have
## been*, and a record that outlived its owner would make death cost less than
## `DES-002` says it does. Kept as **slot names** rather than enum indices, so
## reordering `Enums.Slot` later cannot silently move a helm onto a hand.
##
## Written by the local body whenever its slots change, and read at descent to
## dress it again. The **host reads each peer's own copy off the descent
## declaration**, never this one — three of the four bodies it builds belong to
## somebody else, which is the trap ADR-121 and ADR-126 both had to avoid.
var worn: Dictionary = {}

## Whether a profile has been opened. See the header: nothing is written back
## to a file that was never read.
var _live: bool = false
## **A profile exists and this build would not open it** (`M3-T39`, ADR-161).
##
## Distinct from `_live` being false, which is also the ordinary state of every
## probe: this is the one where a lineage is on disk and every write is being
## discarded. See `_persist`.
var _refused_a_profile: bool = false


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--save-probe"):
		_save_probe()


## Carried out alive. The Chamber sorts it from here, and the cycle moves on:
## **getting out is what finishes a run.** A death does not count, because a
## death ends the life and takes the cycle with it (`DES-003`).
func bring_home(items: Array[ItemInstance]) -> void:
	carried = items.duplicate()
	cycle_runs += 1
	_persist()


## Put on the pile. One-way, by construction: there is no method that takes
## anything off a hoard, because `DES-014` gives her everything you ever gave
## her and never gives any of it back.
func tribute(item: ItemInstance) -> void:
	hoard.append(item.definition.id)
	# **Scarred is worth nothing** (`M3-T05`, ADR-003). A Legacy slot carries a
	# head start across death and never value — otherwise it launders a hoard
	# through a life you were going to lose, which is raw Boon arriving through
	# the door marked *item*.
	var value: int = item.tribute_worth()
	hoard_value += value
	# **Only the surplus becomes Boon** (`DES-004`): *"surplus tribute beyond
	# your Tithe converts to Boon at full rate; tribute below the Tithe converts
	# at nothing and counts against your obligation."*
	#
	# This is the whole coupling in four lines. Servicing the debt buys you
	# nothing but the absence of a punishment, and the debt rises with every
	# node — so a rank-7 player extracts far more for the same point of Boon,
	# which is ADR-060's intended flat income and the reason growth has to be
	# *felt through loud nodes* rather than through a rate that accelerates.
	var still_owed: int = maxi(0, tithe_due() - tithe_paid)
	var surplus: int = maxi(0, value - still_owed)
	# **Capped by your own rank** (`M3-T03`, ADR-011). ADR-010 lets a rank-1
	# player stand on a rank-9 floor and carry rank-9 value home; this is the
	# line that stops that being a rank-9 tree. What the cap turns away is not
	# lost — it becomes what this lineage *learned*, which `DES-003` makes
	# power-free by construction, so the run still pays generously (ADR-006)
	# without paying in power.
	var cap: int = boon_cap()
	var earned: int = convert_with_decay(surplus, cap, boon_converted)
	boon_converted += surplus
	lineage_progress += surplus - earned
	boon_progress += earned
	var per: int = maxi(1, Config.tuning.boon_per_tribute)
	while boon_progress >= per:
		boon_progress -= per
		boon += 1
	# The same gesture pays two things at once, which is the point: there is no
	# separate "pay the Tithe" button anywhere, because `DES-014` puts the
	# keep-or-give decision at the hoard and giving *is* paying.
	tithe_paid += item.tribute_worth()
	carried.erase(item)
	stash.erase(item)
	_persist()


## Kept for next time.
func keep(item: ItemInstance) -> void:
	if not stash.has(item):
		stash.append(item)
	carried.erase(item)
	_persist()


## Take something back out of the stash for a descent.
func withdraw(item: ItemInstance) -> void:
	stash.erase(item)
	_persist()


## **The great reset** (`DES-008`, ADR-004). Everything you were carrying and
## everything you had put aside, gone. The hoard is untouched and that is the
## entire point: the pile is what you have to show for the lives it cost.
## **The instant before the wipe** (`M3-T05`). What this life could still be
## remembered for: what it was wearing, what waited in the stash, and what it
## bought in the tree. Not the carried bag — `DES-012` is explicit that dying
## costs you what you were carrying, and rescue is the only thing that saves it.
## **Ask her to remember one thing** (`M3-T05`, ADR-003).
##
## An item id or a node id, and never Boon. Returns why not, or `""`.
func why_not_keep(kind: String, id: StringName) -> String:
	if legacy.size() >= Config.tuning.legacy_slot_count:
		return "she will remember %d things and no more" \
			% Config.tuning.legacy_slot_count
	for slot: Dictionary in legacy:
		if String(slot.get("id", "")) == String(id):
			return "she is already keeping that"
	if kind == "item":
		if ItemCatalogue.by_id(id) == null:
			return "this build does not have that item"
		if not (last_life.get("worn", []) as Array).has(String(id)) \
				and not (last_life.get("stash", []) as Array).has(String(id)):
			return "that was not yours to lose"
	elif kind == "node":
		if AspectCatalogue.by_id(id) == null:
			return "this build does not have that node"
		if not (last_life.get("taken", []) as Array).has(String(id)):
			return "that life never bought it"
	else:
		# **Not Boon, and not anything else either** (ADR-003). A fungible
		# payload would be the optimal pick every time and turn this screen into
		# percentage retention with extra UI, so the refusal is on the *kind*
		# rather than on a list of banned ids.
		return "she keeps a thing or a lesson, never a measure of Boon"
	return ""


## **Will she take this?** (`M3-T32`, ADR-153)
##
## The fourth `why_not_*`, and the one that was missing. `_on_put_down` handed
## the pile whatever landed near it with no question asked, and `DES-014` makes
## the hoard **one-way by construction** — *"there is no method that takes
## anything off a hoard"* — so anything she was given for nothing was destroyed
## for nothing.
##
## Two ways a thing can be worth nothing, and both were reachable:
##
## **Scarred.** `DES-003` says Legacy items *"cannot be tributed"*, and the
## build implemented that as *can be tributed, for zero*, which is a different
## and much worse sentence: the refusal existed in `tribute_worth()` and stopped
## at the arithmetic.
##
## **Worth nothing to begin with.** Every weapon in the game is `tribute_value`
## 0 — the Seax you start with, the bow a Veiðimaðr *is* — as are the Waystone
## and an ember. Reported from play: a bow given to the pile, gone forever, and
## the hoard did not move. Value is the judgment rather than the category;
## `rlc_regin_blade` is a weapon and she wants it very much.
func why_not_tribute(item: ItemInstance) -> String:
	if item == null:
		return "there is nothing there"
	if item.scarred:
		return "she will not take back what she has already given you"
	if item.definition.tribute_value <= 0:
		return "she has no use for that"
	return ""


func keep_in_legacy(kind: String, id: StringName) -> bool:
	if why_not_keep(kind, id) != "":
		return false
	legacy.append({"kind": kind, "id": String(id)})
	_persist()
	return true


## **What the new life starts with.** Called once, when a life begins.
##
## `DES-003`: *"Legacy items are Scarred — carried through death at reduced
## power and cannot be tributed. They're a head start, not a stockpile."* A kept
## **node** is simply already bought, which raises the new life's rank and
## therefore its Tithe from the first cycle: you begin stronger and owing more,
## which is `DES-003`'s coupling working rather than being circumvented.
func draw_on_legacy() -> void:
	for slot: Dictionary in legacy:
		var id := StringName(slot.get("id", ""))
		match String(slot.get("kind", "")):
			"item":
				var definition: ItemResource = ItemCatalogue.by_id(id)
				if definition == null:
					continue
				var made: ItemInstance = ItemInstance.of(definition, _next_stash_id())
				made.scarred = true
				stash.append(made)
			"node":
				if AspectCatalogue.by_id(id) != null and not taken.has(id):
					taken.append(id)
	# **And the slots are spent** (ADR-149). This read the list and left it
	# there, and nothing else ever emptied it — so the three things she
	# remembers were re-granted to **every** subsequent life, forever, while
	# `why_not_keep` refused every future pick because the slots were full.
	# `DES-003` calls this *"a head start, not a stockpile"* and *"three slots
	# is three slots; it cannot spiral no matter how many lifetimes accrue"*,
	# and both were false: it was a stockpile, it spiralled, and the choice the
	# whole screen exists for was one a lineage made once.
	legacy.clear()
	_persist()


## The Legacy question has been answered. Clears the record `die()` left, so
## the Threshold stops asking — and so a second death has a clean one to write.
## **Mark it, once** (`M3-T08`). Returns whether it was new.
##
## Deeds never un-earn and never re-earn: the first time is the whole record,
## which is what makes a camp readable as a history rather than a tally.
func award(id: StringName, who: String = "") -> bool:
	if deeds.has(String(id)):
		return false
	if DeedCatalogue.by_id(id) == null:
		push_warning("GameState: no deed '%s' in this build" % id)
		return false
	deeds[String(id)] = who
	fresh_deeds.append(String(id))
	_persist()
	return true


## Taken by the Settle beat when it has shown them. Emptying it here rather than
## at the next descent is deliberate: a deed shown is a deed spent, and one that
## surfaced twice would read as having been earned twice.
func take_fresh_deeds() -> Array[String]:
	var shown: Array[String] = fresh_deeds.duplicate()
	fresh_deeds.clear()
	_persist()
	return shown


func forget_the_last_life() -> void:
	last_life = {}
	_persist()


func _next_stash_id() -> int:
	var highest: int = 0
	for item: ItemInstance in stash:
		highest = maxi(highest, item.instance_id)
	return highest + 1


func _remember_the_life() -> Dictionary:
	var wearing: Array[String] = []
	for slot: String in worn:
		wearing.append(String(worn[slot]))
	var stashed: Array[String] = []
	for item: ItemInstance in stash:
		stashed.append(String(item.definition.id))
	var nodes: Array[String] = []
	for node: StringName in taken:
		nodes.append(String(node))
	return {
		"class_id": String(class_id),
		"worn": wearing,
		"stash": stashed,
		"taken": nodes,
		"rank": pact_rank,
	}


## **Is there a life here to end?** (ADR-147)
##
## A life that has already ended is one with nobody living it and a record still
## waiting to be answered. `die()` clears `class_id` and leaves `last_life`
## behind, so that pair is exactly the state between a death and the Legacy
## screen — and it is a state a player can sit in for as long as they like,
## because `DES-003` lets them come back to the fire later and choose.
##
## The two halves are asked together on purpose. A fresh profile has no class
## either, and it very much can die.
func life_already_ended() -> bool:
	return class_id == &"" and not last_life.is_empty()


func die() -> void:
	# **A life ends once** (ADR-147). `PauseMenu._leave` calls this on every
	# ABANDON with no idea whether anybody is alive to lose, and the way out of
	# the Legacy screen — which has no back button on its class panel — is the
	# pause menu. So: die in the Deep, arrive at the fire, decide you would
	# rather not choose right now, abandon.
	#
	# The second call ran `_remember_the_life()` over state the first had
	# already wiped and wrote `{"class_id": "", "worn": [], "stash": [],
	# "taken": [], "rank": 1}` — **non-empty, and recording nothing**. So the
	# fire went on asking (the record is the question), the menu went on not
	# asking about a class (`last_life` is not empty), and the screen offered
	# **nothing**, on a life that had really had gear, a stash and a tree.
	#
	# Reported as *"like I was supposed to offer something."* The real record is
	# the thing worth protecting here, so this refuses rather than overwrites.
	if life_already_ended():
		return
	# **Before anything is cleared.** The Legacy screen chooses from this, and
	# it has to exist for a life that has already ended — a choice offered
	# *instead* of the wipe would be a life you could keep by not choosing.
	last_life = _remember_the_life()
	carried.clear()
	stash.clear()
	# **Death is the door to a new class** (ADR-009), and that is a retention
	# argument rather than a tidiness one: `DES-011` locks class for a life, so
	# clearing it here is what turns ADR-004's harshness into an invitation to
	# try being someone else. It is also what makes the next life's Legacy
	# choice a real bet — a Rite node only applies if you pick that class again.
	class_id = &""
	# The pact dies with you (`DES-003`): *"Pact Rank & Tithe obligation — resets
	# to 1."* Including what you owed and what she was going to send for it — a
	# debt surviving the debtor would be the running-debt model ADR-029 rejected,
	# arriving by accident through the one door nobody was watching.
	# The tree goes with it. `DES-003`'s reset table is unambiguous — *"skill
	# tree (Boon spent into Aspects): all of it"* — and because rank is derived
	# from exactly this list, clearing it is what puts rank back to 1. There is
	# no separate rank to forget.
	taken.clear()
	boon = 0
	boon_progress = 0
	# Gear goes with the life. `DES-008` makes it a record of where you have
	# been, and `DES-002` is what makes that record worth anything.
	worn.clear()
	tithe_paid = 0
	cycle_runs = 0
	boon_converted = 0
	hunt_head_start = 0.0
	# `TEC-003` calls this the critical path: a hard kill during the death
	# sequence must never produce a half-wiped profile. It cannot, because
	# `SaveFile.write` renames a complete file over the old one — either the
	# life ended or it did not, and there is no third state on disk.
	_persist()


func stash_value() -> int:
	var sum: int = 0
	for item: ItemInstance in stash:
		sum += item.definition.tribute_value
	return sum


# ── the pact ──────────────────────────────────────────────────────────────


# ── the tree ──────────────────────────────────────────────────────────────


## What the tree has cost you. `DES-003` makes this the same number as rank,
## which is why rank is read off it rather than stored beside it.
func boon_spent() -> int:
	var sum: int = 0
	for id: StringName in taken:
		var node: AspectNode = AspectCatalogue.by_id(id)
		# **A node this build does not have contributes nothing, and is kept
		# anyway.** Keeping it means a profile opened in an older build and
		# returned to a newer one still has its tree; contributing nothing is
		# simply the truth, because a cost is read off a tier and an unknown
		# node has no tier to read. The consequence — that such a life reads a
		# rank lower than it earned, and so a cheaper Tithe — is `M4-T06`'s
		# question about what a build does with a save from a newer one, and it
		# is written down here rather than papered over with a stored cost that
		# could disagree with the node it belongs to.
		sum += Config.tuning.node_cost(node.tier) if node != null else 0
	return sum


func has_taken(id: StringName) -> bool:
	return taken.has(id)


## **Does this life have that rule?** (`TEC-006`.)
##
## The one seam every system reads the tree through. `Inventory` asks for
## `carry_no_limit`; it never asks what nodes were taken, and the tree never
## reaches into a bag. A node is a name and a set of tags, and the system that
## owns a rule is the only thing that knows what changing it means.
##
## Rebuilt from `taken` rather than cached, because a cache is a second copy of
## the tree that can disagree with it — which is the argument that made rank
## derived (ADR-125), applied to the same list one function down.
func has_effect(tag: StringName) -> bool:
	for id: StringName in taken:
		var node: AspectNode = AspectCatalogue.by_id(id)
		if node != null and node.effect_tags.has(tag):
			return true
	return false


## Which Aspect your keystone is in, or empty. `DES-004`: **one keystone active
## at a time** — *"this is the primary anti-bloat rule"* — and the Aspect it
## sits in is your primary by definition, so there is nothing else to store.
func primary_aspect() -> StringName:
	for id: StringName in taken:
		var node: AspectNode = AspectCatalogue.by_id(id)
		if node != null and node.tier == AspectNode.Tier.KEYSTONE:
			return node.aspect
	return &""


## Why you cannot take this node, or empty if you can.
##
## **A sentence rather than a bool**, because every one of these is something a
## player is entitled to see on the node they just clicked. A tree that greys
## something out and will not say why is the unexplainable-loss shape
## `PRO-005` §5 rules out, moved from the floor into a menu.
func why_not(id: StringName) -> String:
	var node: AspectNode = AspectCatalogue.by_id(id)
	if node == null:
		return "this build does not have that node"
	if has_taken(id):
		return "already taken"
	# **Your class decides which three Aspects you may enter** (ADR-009,
	# `DES-011`). The gate that makes 6 classes into 36 identities, and the
	# reason `M3-T02` had to precede this task rather than follow it.
	var body: ClassResource = ClassCatalogue.by_id(class_id)
	if body == null:
		return "no life has been sworn yet"
	if not body.aspects.has(node.aspect):
		return "%s may not enter the %s" % [body.display(), node.aspect]
	# One keystone, ever, and it names the build. `DES-004` allows a secondary
	# Aspect's greater and lesser nodes but never its keystone.
	if node.tier == AspectNode.Tier.KEYSTONE:
		var already: StringName = primary_aspect()
		if already != &"":
			return "your keystone is already in the %s" % already
	if node.rank_required > pact_rank:
		return "pact rank %d" % node.rank_required
	for needed: StringName in node.requires:
		if not has_taken(needed):
			var before: AspectNode = AspectCatalogue.by_id(needed)
			return "needs %s first" % (before.display() if before != null else needed)
	var price: int = Config.tuning.node_cost(node.tier)
	if boon < price:
		return "%d boon" % price
	return ""


## Spend on a node. Returns whether it was taken.
##
## **The only writer of `taken`.** Rank, the Tithe it raises and everything the
## floor scales by all fall out of this one list, so a second path into it would
## be a second way to change the difficulty of the game.
## **Why you cannot give this one back**, or empty if you can (`M3-T13`).
##
## A sentence rather than a bool, on `why_not`'s rule: a tree that greys
## something out and will not say why is `PRO-005` §5's unexplainable loss moved
## from the floor into a menu.
##
## Two refusals, and the first is `DES-004` verbatim.
func why_not_reclaim(id: StringName) -> String:
	if not taken.has(id):
		return "that is not yours to give back"
	var node: AspectNode = AspectCatalogue.by_id(id)
	if node == null:
		# A node this build does not have. `boon_spent` keeps it for the reason
		# given there; reclaiming it would refund a cost nothing can price.
		return "this build does not have that node"
	if node.tier == AspectNode.Tier.KEYSTONE:
		# **`DES-004`, in as many words**: a respec *"cannot change your
		# keystone mid-life. Locking the keystone is what makes the choice
		# matter."* Everything else about a build is a reconsideration; this is
		# the one thing you committed to, and death is what unmakes it.
		return "she does not forget a keystone while you live"
	for other: StringName in taken:
		var dependent: AspectNode = AspectCatalogue.by_id(other)
		if dependent != null and dependent.requires.has(id):
			# Prerequisite integrity. Without this a tree can be left with a
			# node whose route was reclaimed underneath it — which nothing in
			# the build would refuse afterwards, because `why_not` is asked when
			# a node is *taken* and never again.
			return "%s stands on it" % dependent.display()
	return ""


## **Give a node back** (`M3-T13`, `DES-004`). Returns whether it happened.
##
## The refund is deliberately partial: `DES-004` says a respec *"costs real
## resources"*, and the resource is the Boon that does not come back. No new
## currency and no second economy — the cost scales with how much of a build is
## being unmade, which is the right shape.
##
## **Rank falls with it**, because rank is derived from `taken` (ADR-126) — and
## so does the Tithe. That is `DES-003`'s coupling running in the direction it
## is usually read backwards: power went down, so the obligation went down.
## Considered and kept: a player who strips a tree to owe her less has paid for
## it twice over, in the refund and in the build, which is exactly the trade the
## design wants to be available rather than a loophole to close.
func reclaim(id: StringName) -> bool:
	if why_not_reclaim(id) != "":
		return false
	var node: AspectNode = AspectCatalogue.by_id(id)
	var paid: int = Config.tuning.node_cost(node.tier)
	taken.erase(id)
	boon += int(floor(paid * Config.tuning.respec_refund))
	_persist()
	return true


func take_node(id: StringName) -> bool:
	var refused: String = why_not(id)
	if refused != "":
		return false
	var node: AspectNode = AspectCatalogue.by_id(id)
	var was: int = pact_rank
	boon -= Config.tuning.node_cost(node.tier)
	taken.append(id)
	# Said out loud because it is the moment `DES-003` is about: the power
	# arrived and the obligation moved with it, in the same breath.
	if pact_rank != was:
		print("[pact] %s taken — rank %d, and she now expects %d a cycle" % [
			node.display(), pact_rank, tithe_due()])
	_persist()
	return true


## What she expects of you this cycle (`DES-003`, ADR-029).
func tithe_due() -> int:
	return tithe_for(pact_rank)


## What she would expect at a given rank. Split out from `tithe_due()` so the
## **table** can be asserted at `DES-003`'s three anchors without a probe having
## to manufacture a tree that reaches rank 9 (`M3-T01`).
##
## That is not a convenience. Rank is derived from the nodes taken now, and the
## Hoard alone tops out around rank 6 — so a probe that drove `pact_rank` to
## test the table would have to fill `taken` with duplicates it could never
## own, and would then be testing its own fiction. This asks the table the
## question the table can answer, and `--pact-probe` separately proves that
## `tithe_due()` tracks a rank a player actually earned.
## **How much tribute converts at full rate this cycle** (`M3-T03`, ADR-011).
##
## Deliberately **your own Tithe**, not a second table. ADR-010 lets a rank-1
## player extract rank-9 value, and ADR-011's whole point is that they may be
## carried but *"not carried past your own ability to use what you're given."*
## Tying the headroom to the obligation is `DES-003`'s coupling stated once:
## the number that says what she expects of you is the number that says how
## much of a floor you can turn into power.
##
## A fraction of it rather than the whole, because the Tithe is what a cycle
## must *return*; converting a cycle's entire obligation into Boon every cycle
## would make the debt self-financing.
func boon_cap() -> int:
	return int(round(tithe_for(pact_rank) * Config.tuning.boon_cap_fraction))


## Tribute value → Boon-earning value, with everything past the cap decaying.
##
## **Halving bands.** The first `cap` of surplus converts whole, the next `cap`
## at half, the next at a quarter, and so on — so no cycle can ever convert
## much more than **twice** the cap however much is carried out of a floor.
## ADR-011 asked for *"a steeply decaying rate"* rather than a wall, and this is
## the version that is explicable in one sentence: *each band is worth half the
## last.* A flat second rate was tried on paper first and does not hold the
## line — at 25%%, a carried rank-1 player still converts 210 of a rank-9
## floor's 900, which is the power-levelling ADR-011 exists to prevent.
##
## `already` is what this cycle has spent, so the bands are a property of the
## cycle rather than of a single item — otherwise four coins would each get
## their own full-rate band and the cap would mean nothing.
func convert_with_decay(value: int, cap: int, already: int) -> int:
	if value <= 0:
		return 0
	if cap <= 0:
		return value
	var earned: float = 0.0
	var left: int = value
	var at: int = already
	while left > 0:
		var band: int = at / cap
		var rate: float = pow(0.5, float(band))
		if rate < 0.001:
			break
		var room: int = cap - (at % cap)
		var take: int = mini(left, room)
		earned += float(take) * rate
		left -= take
		at += take
	return int(round(earned))


func tithe_for(rank: int) -> int:
	var table: PackedInt32Array = Config.tuning.tithe_by_rank
	if table.is_empty():
		return 0
	return table[clampi(rank - 1, 0, table.size() - 1)]


## Runs before she settles up.
func runs_left() -> int:
	return maxi(0, Config.tuning.tithe_cycle_runs - cycle_runs)


## She settles up at the door, before you go down again.
##
## **At the descent rather than at the end of a run**, because the Chamber is
## where you pay: a cycle that closed the moment you extracted would demand the
## Tithe before you had the chance to hand anything over.
##
## Returns whether she was satisfied, so the descent can say so out loud.
func settle_cycle() -> bool:
	if runs_left() > 0:
		return true
	var owed: int = tithe_due()
	var met: bool = tithe_paid >= owed
	# **Soft fail** (ADR-029, ADR-118). She sends something rather than taking
	# something: the next descent begins with the Hunt already this old, so its
	# reach opens wider from the first second. No new rule, no new system — the
	# Gullsjúkr's own escalation, started early. `DES-022` calls this the rank
	# axis anyway: *the Hunt arrives sooner.*
	hunt_head_start = 0.0 if met else Config.tuning.tithe_missed_head_start
	print("[tithe] rank %d owed %d, paid %d — %s" % [
		pact_rank, owed, tithe_paid,
		"settled" if met else "short, and she has sent for it"])
	# **The slate clears.** Unpaid value does not carry (ADR-118): ADR-029's
	# running-debt alternative self-stabilised through node reclamation, and
	# node reclamation is `M3-T01`, so carrying a debt here could only spiral
	# with nothing at the bottom of it.
	tithe_paid = 0
	cycle_runs = 0
	# The conversion headroom is the cycle's, so it refills with the cycle.
	boon_converted = 0
	_persist()
	return met


## The head start she is owed, taken once. Consumed rather than read, so a
## missed cycle costs the next descent and not every descent after it.
func take_hunt_head_start() -> float:
	var owed: float = hunt_head_start
	hunt_head_start = 0.0
	if owed > 0.0:
		_persist()
	return owed


# ── the file ──────────────────────────────────────────────────────────────


## Open the profile. Called when a session starts — `MainMenu` on the way to the
## Threshold — because that is when a player has one, and it is the only path
## into the game.
##
## Returns whether this process may now write. **A profile that exists and could
## not be read leaves us not-live**, which is the whole of the protection: a
## build that refuses a save from a newer version must not then overwrite it
## with what it managed to understand.
func load_profile() -> bool:
	# **Which of the three ways this went** (`M3-T39`, ADR-161). The branches
	# differ in what the player keeps and none of them was distinguishable
	# afterwards: a profile read, a profile refused, and no profile at all lead
	# to three different games and produced one silence. A reported save that
	# stopped being written could not be diagnosed from the log because the log
	# did not say which of these happened.
	if SaveFile.exists():
		var data: Dictionary = SaveFile.read()
		if data.is_empty():
			# `SaveFile.read` has already said what was wrong with it.
			print("[save] a profile is there and could not be read — playing "
				+ "on, and writing nothing")
			_live = false
			_refused_a_profile = true
			return false
		from_dict(data)
		print("[save] opened a profile — life '%s', descent %d, %d in the hoard"
			% [class_id, descents, hoard_value])
	else:
		print("[save] no profile yet — this is a first descent")
	_refused_a_profile = false
	_live = true
	return true


## Whether this process will write what it is told. False before a profile has
## been opened, and false again if one was found and refused.
func saving() -> bool:
	return _live


## Swear to a class for this life (`M3-T02`, `DES-011`).
##
## **Refuses to overwrite an existing oath.** `DES-011` locks class until death
## and `die()` is the only thing that clears it, so a second call is either a
## bug or a screen that was opened when it should not have been — and silently
## honouring it would let a player swap class mid-life, which is the one thing
## the lock exists to prevent.
func take_the_oath(id: StringName) -> bool:
	if class_id != &"":
		push_warning("GameState: already sworn as '%s'; ignoring '%s'"
			% [class_id, id])
		return false
	if ClassCatalogue.by_id(id) == null:
		push_error("GameState: '%s' is not a class in this build" % id)
		return false
	class_id = id
	# **The kit arrives in the stash**, not in a bag and not through a new path.
	# `_carry_the_stash_down()` already takes what you kept down with you, so a
	# starting kit behaves exactly like anything else you put aside — it fits or
	# it waits, and you can leave it behind. Inventing a second route into the
	# first descent would be a parallel path (ADR-064) for something the Chamber
	# already does.
	for item: StringName in ClassCatalogue.by_id(id).kit:
		var definition: ItemResource = ItemCatalogue.by_id(item)
		if definition == null:
			push_error("GameState: %s's kit names '%s', which is not an item"
				% [id, item])
			continue
		# **What has a slot is worn, not stashed** (`M3-T07`, `DES-020`).
	#
		#
		# ADR-124 patched this with a guard against ranged weapons specifically,
		# because a bow was reaching the hand *and* the bag. Slots make the rule
		# general and the guard unnecessary: `Player._dress_from_kit` equips
		# everything in the kit that has somewhere to go, so anything that does
		# is already accounted for and only cargo waits in the stash.
		if definition.slot != Enums.Slot.NONE:
			worn[Enums.Slot.keys()[definition.slot]] = String(item)
			continue
		stash.append(ItemInstance.of(definition, 0))
	_persist()
	return true


## The class this life is, or `null` before one is chosen and after a death.
func sworn() -> ClassResource:
	return ClassCatalogue.by_id(class_id)


## The two tiers that exist, in `TEC-003`'s sections. `carried` is absent on
## purpose: it is what you are holding *during* a run, and `M3-T09` is where a
## suspended run gets a file of its own (ADR-116).
func to_dict() -> Dictionary:
	var pile: Array[String] = []
	for id: StringName in hoard:
		pile.append(String(id))
	# **Ids only.** `_carry_the_stash_down()` re-mints a fresh `ItemInstance`
	# from the definition and discards the stashed one, so a cell, a rotation
	# and an instance id would all be written and then thrown away on load. The
	# moment anything persists a *placed* item — a bag across a suspend — those
	# come with it, and that is `M3-T09`.
	var kept: Array[String] = []
	for item: ItemInstance in stash:
		kept.append(String(item.definition.id))
	# Ids only, on the stash's own reasoning above: `Chamber` re-mints a fresh
	# `ItemInstance` from the definition when it hands the haul back, so a cell
	# and a rotation would be written and thrown away.
	var held: Array[String] = []
	for item: ItemInstance in carried:
		held.append(String(item.definition.id))
	var spent: Array[String] = []
	for id: StringName in taken:
		spent.append(String(id))
	return {
		"lineage": {"hoard": pile, "hoard_value": hoard_value,
			"descents": descents,
			"progress": lineage_progress, "deeds": deeds,
			# Carried across a quit, because a deed earned on the last run and
			# not yet seen is still owed to the player — `DES-016` puts it at
			# the Settle beat, and quitting before the fire is not a forfeit.
			"fresh_deeds": fresh_deeds},
		# **Its own section** (`TEC-003`), not a corner of `lineage`. The three
		# tiers are the design's own (`DES-003`) and the save mirrors them
		# deliberately, because that alignment is what keeps death a one-function
		# operation: delete LIFE, keep LINEAGE, move LEGACY across.
		"legacy": {"slots": legacy, "last_life": last_life},
		"life": {
			"stash": kept,
			# **What you walked out with, before you decided about it** (save
			# v8, ADR-143). This file's own header table has always said
			# *"what you carried — survives a run: only if you extracted"*, and
			# it did not survive a **quit**: `bring_home()` wrote a profile that
			# had no field for it, so extracting and closing the game at the
			# fire lost the whole haul.
			#
			# LIFE tier, beside the stash, because that is what it is — `die()`
			# clears it in the same breath, and `DES-012` is explicit that dying
			# costs you the bag outright.
			"carried": held,
			"class_id": String(class_id),
			# **No `pact_rank`.** It is derived from `taken` (ADR-125), and a
			# stored copy is a second source of truth that a hand-edited or
			# half-migrated file could set out of step with the tree.
			"worn": worn,
			"boon": boon,
			"boon_progress": boon_progress,
			"boon_converted": boon_converted,
			"taken": spent,
			"tithe_paid": tithe_paid,
			"cycle_runs": cycle_runs,
			"hunt_head_start": hunt_head_start,
		},
	}


## Rebuild from a profile already migrated to the current version.
##
## An id the catalogue does not know is **skipped with a warning, not fatal**:
## that is what a save from a build with an item this one lacks looks like, and
## `ItemInstance.from_wire` documents the same rule for the same reason.
func from_dict(data: Dictionary) -> void:
	var lineage: Dictionary = _section(data, "lineage")
	hoard.clear()
	for raw: Variant in lineage.get("hoard", []) as Array:
		hoard.append(StringName(raw))
	hoard_value = int(lineage.get("hoard_value", 0))
	lineage_progress = int(lineage.get("progress", 0))
	# At least 1: `AudioDirector` divides by `descents - 1` against a full-camp
	# constant, and a zero here would make a fresh camp sound like a lived-in
	# one from below.
	descents = maxi(1, int(lineage.get("descents", 1)))
	deeds = (lineage.get("deeds", {}) as Dictionary).duplicate()
	fresh_deeds.clear()
	for row: Variant in lineage.get("fresh_deeds", []) as Array:
		fresh_deeds.append(String(row))
	var kept: Dictionary = _section(data, "legacy")
	legacy.clear()
	for row: Variant in kept.get("slots", []) as Array:
		var slot := row as Dictionary
		if slot != null:
			legacy.append(slot)
	last_life = (kept.get("last_life", {}) as Dictionary).duplicate(true)

	var life: Dictionary = _section(data, "life")
	stash.clear()
	for raw: Variant in life.get("stash", []) as Array:
		var known: ItemResource = ItemCatalogue.by_id(StringName(raw))
		if known == null:
			push_warning("GameState: stashed '%s' is not in this build" % raw)
			continue
		# Instance id `0`: an `Inventory` mints from 1, so nothing in a bag can
		# collide with something merely sitting in the stash.
		stash.append(ItemInstance.of(known, 0))
	# **And the haul that has not been decided about yet** (save v8, ADR-143).
	carried.clear()
	for raw: Variant in life.get("carried", []) as Array:
		var brought: ItemResource = ItemCatalogue.by_id(StringName(raw))
		if brought == null:
			push_warning("GameState: carried '%s' is not in this build" % raw)
			continue
		carried.append(ItemInstance.of(brought, 0))
	# Defaults matching a new life, so a `life` block from before `M3-T04`
	# reads as what it was — rank 1, owing nothing. `SaveFile._migrate_1_to_2`
	# writes them explicitly; these are what happens if a field is missing for
	# any other reason, and a rank of 0 would index the Tithe table below zero.
	class_id = StringName(life.get("class_id", ""))
	worn = (life.get("worn", {}) as Dictionary).duplicate()
	boon = maxi(0, int(life.get("boon", 0)))
	boon_progress = maxi(0, int(life.get("boon_progress", 0)))
	boon_converted = maxi(0, int(life.get("boon_converted", 0)))
	taken.clear()
	for raw: Variant in life.get("taken", []) as Array:
		var node: AspectNode = AspectCatalogue.by_id(StringName(raw))
		if node == null:
			# **Kept, not dropped**, so a profile opened in a build that lacks a
			# node still has it when it goes home. See `boon_spent()` for what
			# it is worth while it is unknown, which is nothing, and why.
			push_warning("GameState: node '%s' is not in this build" % raw)
		taken.append(StringName(raw))
	tithe_paid = int(life.get("tithe_paid", 0))
	cycle_runs = int(life.get("cycle_runs", 0))
	hunt_head_start = float(life.get("hunt_head_start", 0.0))
	# **The line that used to end this function was `carried.clear()`**, and it
	# was correct while nothing wrote the field: a loaded profile could not be
	# carrying anything, so emptying it was the honest reading. Save v8 writes
	# it (ADR-143), and the same line then quietly undid the restore two dozen
	# lines above — the read was right, the write was right, and the last
	# statement threw the answer away.
	#
	# Found by planting nothing: the round-trip row simply failed, and the
	# instinct to distrust the *new* code cost three wrong guesses before the
	# old line was even read.


## **A profile that is not being written says so, once** (`M3-T39`, ADR-161).
##
## `_live` is false before a profile is opened and false again if one was found
## and refused — both correct, and both silent. `TEC-003` calls the death write
## *the critical path*, and the state this guards is one where **every** write
## is discarded: a life ends, a class is sworn, a tithe is paid, and none of it
## reaches disk. There is nothing on screen to notice and nothing in the log to
## find afterwards.
##
## Found chasing a reported profile whose `updated` stamp was minutes older
## than a session containing two writes that cannot be skipped. That question
## should have been answerable from the log and was not.
##
## **Never opened is not the same as opened and refused**, and the first draft
## of this said both. Every probe in the sweep boots a level directly and never
## sees the front door, so `_live` is false for all of them by design — and
## erroring there broke six checks at once and would have buried the one
## occurrence that matters under a hundred that do not. ADR-138 wrote this rule
## down for `RunFile._write` in as many words: *"Not an error. A probe booting a
## level directly has no business opening a run, and saying so on every one of
## them would bury the output that matters in noise."* Same rule, a second file,
## found by the sweep rather than by remembering.
##
## So the error is for the case with a player behind it: a profile that **is on
## disk**, was read, and was refused (ADR-117) — where a lineage exists and this
## session is quietly discarding everything that happens to it.
##
## `push_error`, not a warning: that is data loss in progress.
var _said_it_is_not_saving: bool = false


func _persist() -> void:
	if not _live:
		if _refused_a_profile and not _said_it_is_not_saving:
			_said_it_is_not_saving = true
			push_error("GameState: there is a profile on disk that this build "
				+ "would not open, so nothing in this session — a death, an "
				+ "oath, a tithe — is being written to it.")
		return
	_said_it_is_not_saving = false
	if not SaveFile.write(to_dict()):
		# `SaveFile.write` already says which half failed and why. This says
		# what it *costs*, which is the part a reader of the log needs.
		push_error("GameState: the profile was not written — this life's "
			+ "progress is only in memory.")


func _section(data: Dictionary, name: String) -> Dictionary:
	var part: Variant = data.get(name, {})
	return part as Dictionary if typeof(part) == TYPE_DICTIONARY else {}


# ── the check ─────────────────────────────────────────────────────────────


## `--save-probe`: does a profile survive a round trip, refuse what it must,
## and do migrations run in order?
##
## It lives in this autoload rather than in a level because its subject is this
## autoload and `SaveFile`, and neither has a room. `Config` hosts
## `--export-probe` on the same reasoning (ADR-099): a check with no natural
## level belongs with the thing that always boots, not with whichever scene
## happens to be main this month.
func _save_probe() -> void:
	var problems: PackedStringArray = PackedStringArray()
	# **Its own profile, never the players** (ADR-145). Writing, wiping and
	# migrating are this probes whole subject, so it cannot be refused the file —
	# it gets a different one.
	SaveFile.use_a_scratch_profile()
	if SaveFile.PATH == "user://profile.save":
		printerr("[save] FAIL this probe is pointed at the real profile and "
			+ "wipes below — every sweep would delete a player's lineage")
		get_tree().quit(1)
		return
	SaveFile.wipe()

	# ── a profile that is not there ──────────────────────────────────────
	if not load_profile():
		problems.append(("opening a profile that does not exist failed — first "
			+ "launch is the most common load there is, and a build that "
			+ "cannot do it cannot be played at all"))
	if FileAccess.file_exists(SaveFile.PATH):
		problems.append(("opening a missing profile created one — a file must "
			+ "appear because something was saved, not because something looked"))
	print("[save] no profile     opened, live=%s, nothing written" % _live)

	# ── a round trip ─────────────────────────────────────────────────────
	tribute(ItemInstance.of(ItemCatalogue.by_id(&"glt_hoard_coin"), 1))
	keep(ItemInstance.of(ItemCatalogue.by_id(&"wpn_seax"), 2))
	var gave: int = hoard_value
	var pile: int = hoard.size()
	# **What you are wearing is part of the life** (`M3-T07`, save v5). Recorded
	# before the round trip below, because a plant that stopped writing `worn`
	# to the wire went **uncaught**: every row here was about the hoard and the
	# stash, and gear reached disk untested for the whole of its first task.
	worn["MAIN_HAND"] = "wpn_seax"
	# **And what was walked out with** (save v8, ADR-143), recorded here for the
	# reason `worn` is: a haul that never reaches disk is invisible to every row
	# that asks about the hoard or the stash. Extracting and quitting at the
	# fire lost the whole bag, and this file's own header table said it should
	# not have.
	carried.append(ItemInstance.of(ItemCatalogue.by_id(&"glt_altar_plate"), 7))
	# **And how far down this lineage has been** (save v9, ADR-149). Recorded
	# here for the reason `worn` and `carried` are: a field nothing asserts is a
	# field that can silently stop reaching disk, and this one never reached it
	# at all — the camp went back to sounding empty on every relaunch and
	# nothing in the sweep could see it.
	descents = 5
	_persist()

	if FileAccess.file_exists(SaveFile.TMP):
		problems.append(("a scratch file survived the write — `%s` is renamed "
			+ "over the profile, and one left behind means the rename did not "
			+ "happen and the profile on disk is the previous one")
			% SaveFile.TMP)

	hoard.clear()
	hoard_value = 0
	stash.clear()
	worn.clear()
	carried.clear()
	descents = 1
	from_dict(SaveFile.read())
	print("[save] round trip     hoard %d/%d, value %d/%d, stash %d" % [
		hoard.size(), pile, hoard_value, gave, stash.size()])
	if hoard.size() != pile or hoard_value != gave:
		problems.append(("the hoard did not survive a round trip — it is the "
			+ "one tier `DES-014` says is never wiped, ever, and a lineage that "
			+ "does not reach disk is the whole of what this file is for"))
	if stash.size() != 1 or stash[0].definition.id != &"wpn_seax":
		problems.append(("the stash did not survive a round trip — `DES-008`'s "
			+ "great reset is supposed to be what empties it, not quitting"))
	print("[save] the haul       %d item(s) still to decide about" % carried.size())
	if carried.size() != 1 or carried[0].definition.id != &"glt_altar_plate":
		problems.append(("what was carried out did not survive a round trip — "
			+ "the Settle beat happens at the Chamber and the fire is where you "
			+ "land, so quitting in between used to cost the whole haul before "
			+ "she was ever offered any of it"))
	print("[save] the descent    %d down (want 5)" % descents)
	if descents != 5:
		problems.append(("how far down this lineage has been did not survive a "
			+ "round trip — `AudioDirector` fills the camp out from this count "
			+ "and the readout names it, so a lineage that forgets it is a camp "
			+ "that sounds empty however long you have been coming back"))
	print("[save] gear           main hand '%s'" % worn.get("MAIN_HAND", ""))
	if String(worn.get("MAIN_HAND", "")) != "wpn_seax":
		problems.append(("what was worn did not survive a round trip — "
			+ "`DES-020` puts the class kit in slots, so a life that reloads "
			+ "unarmed has lost the thing `M3-T02` swore it to"))

	# ── a scratch file left by an earlier crash ──────────────────────────
	var litter := FileAccess.open(SaveFile.TMP, FileAccess.WRITE)
	litter.store_string("half a save, from a process that died")
	litter.close()
	keep(ItemInstance.of(ItemCatalogue.by_id(&"glt_hoard_coin"), 3))
	var after_litter: Dictionary = SaveFile.read()
	print("[save] stale scratch  ignored, profile still v%d" % int(
		(after_litter.get("meta", {}) as Dictionary).get("save_version", 0)))
	if after_litter.is_empty():
		problems.append(("a leftover scratch file broke the next load — a crash "
			+ "mid-write is exactly the case the rename exists to survive, so "
			+ "its debris must cost nothing"))

	# ── a profile this build cannot read ─────────────────────────────────
	_write_raw('{"meta": {"save_version": %d}, "lineage": {"hoard_value": 999}}'
		% (SaveFile.SAVE_VERSION + 1))
	if not SaveFile.read().is_empty():
		problems.append(("a save from a newer build was loaded — its migrations "
			+ "have not been written, so what came back is a guess"))
	if load_profile():
		problems.append(("a profile this build refused still went live — the "
			+ "next tribute would write over a newer save with whatever this "
			+ "build managed to understand of it"))
	hoard_value = 1
	_persist()
	var untouched: Dictionary = SaveFile.read_raw()
	var kept_value: int = int((untouched.get("lineage", {}) as Dictionary).get(
		"hoard_value", 0))
	print("[save] newer profile  refused, left on disk at %d" % kept_value)
	if kept_value != 999:
		problems.append(("a refused profile was overwritten anyway — refusing to "
			+ "read it is worth nothing if we then destroy it"))

	# ── a profile that is not a profile ──────────────────────────────────
	#
	# The second half of this is the one that matters, and asserting only the
	# first is how the bug in `SaveFile.exists()`'s note shipped past a green
	# probe: garbage not loading was true while garbage was being destroyed.
	_write_raw("this is not JSON and never was")
	if not SaveFile.read().is_empty():
		problems.append(("garbage loaded as a profile — `TEC-003` asks for a "
			+ "clean failure rather than half-loading into a corrupt state"))
	if load_profile():
		problems.append(("an unreadable profile still went live — a file that "
			+ "cannot be parsed is the case a player most needs protected, not "
			+ "the one where it parses and is merely too new"))
	hoard_value = 7
	_said_it_is_not_saving = false
	_persist()
	# **And it said so** (`M3-T39`, ADR-161). Refusing to write is correct and
	# was silent, so a session in which every write is discarded looks exactly
	# like one in which they all landed. `TEC-003` calls the death write the
	# critical path; this is the state where the critical path is a no-op.
	print("[save] not saving     said so=%s" % _said_it_is_not_saving)
	if not _said_it_is_not_saving:
		problems.append(("the profile refused to go live and then discarded "
			+ "every write in silence — a life ends, a class is sworn, a tithe "
			+ "is paid, and none of it reaches disk with nothing on screen or "
			+ "in the log to say so"))
	var still_garbage: bool = FileAccess.open(
		SaveFile.PATH, FileAccess.READ).get_as_text().begins_with("this is not")
	print("[save] corrupt        refused, left on disk=%s" % still_garbage)
	if not still_garbage:
		problems.append(("an unreadable profile was overwritten — whatever is "
			+ "in that file is the only copy of somebody's lineage, and a build "
			+ "that cannot read it has no business replacing it"))

	# ── migrations, driven with a table the real one cannot supply yet ───
	# These build a **new** dictionary rather than mutating the one they are
	# given, and that is load-bearing rather than tidy. A Dictionary is a
	# reference in GDScript, so in-place migrations make `walk()` appear to work
	# even when it throws its steps' return values away — planted exactly that
	# and the probe stayed green. A migration is a function from one shape to
	# another, and testing it as one is the only way the wiring is proved.
	var order: Array[int] = []
	var first: Callable = func(step: Dictionary) -> Dictionary:
		order.append(1)
		var out: Dictionary = step.duplicate(true)
		out["stepped_one"] = true
		return out
	var second: Callable = func(step: Dictionary) -> Dictionary:
		order.append(2)
		var out: Dictionary = step.duplicate(true)
		out["stepped_two"] = true
		return out
	var walked: Dictionary = SaveFile.walk(
		{"meta": {"save_version": 1}}, {1: first, 2: second}, 1, 3)
	var landed: int = int((walked.get("meta", {}) as Dictionary).get(
		"save_version", 0))
	print("[save] migrations     ran %s, landed at v%d" % [order, landed])
	if order != [1, 2]:
		problems.append(("migrations did not run once each in order, they ran "
			+ "%s — `TEC-003` loads from arbitrary old versions and a step "
			+ "skipped or repeated corrupts a profile silently") % [order])
	if not walked.has("stepped_one") or not walked.has("stepped_two"):
		problems.append("a migration's result was discarded rather than carried forward")
	if landed != 3:
		problems.append(("a migrated profile was stamped v%d rather than the "
			+ "version it was actually migrated to, so the next load would run "
			+ "the same steps again") % landed)

	# A gap in the **middle** of the table, not an empty one. An empty table
	# fails on its first step, so anything at all that returns nothing looks
	# right; a gap after a step that succeeded is the case where skipping it
	# hands back a half-migrated profile, which is the actual danger.
	var ran_before: int = order.size()
	var gapped: Dictionary = SaveFile.walk(
		{"meta": {"save_version": 1}}, {1: first}, 1, 3)
	var ran_anyway: int = order.size() - ran_before
	print("[save] missing step   refused, %d step(s) ran, carried forward=%s"
		% [ran_anyway, not gapped.is_empty()])
	if not gapped.is_empty():
		problems.append(("a gap in the migration table was skipped rather than "
			+ "refused, and a profile half-way between two shapes came back — "
			+ "a shape no build ever wrote, saved back over the one that was"))
	if ran_anyway != 0:
		problems.append(("%d migration(s) ran before the gap was noticed — the "
			+ "route has to be checked before the first step, or a refusal "
			+ "still leaves a profile part-way between two formats")
			% ran_anyway)

	# ── a real v1 profile, through the real table ────────────────────────
	#
	# **A fixture of the format being replaced**, which `TEC-003` calls the most
	# valuable test in the project — and which the synthetic walk above cannot
	# be. That one proves the *algorithm*: ordering, refusal, re-stamping. This
	# proves the **migrations themselves**, which are a permanent public
	# contract with files already sitting on people's disks. Nothing else in the
	# sweep ever runs `_migrate_1_to_2`.
	#
	# Written as literal v1 text rather than built from today's `to_dict()`,
	# because a fixture generated by the current build is a fixture that changes
	# shape every time the schema does — and then it stops being a record of
	# what v1 was.
	_write_raw('{"meta": {"save_version": 1}, "lineage": {"hoard": '
		+ '["glt_hoard_coin"], "hoard_value": 40}, "life": {"stash": ["wpn_seax"]}}')
	hoard.clear()
	hoard_value = 0
	stash.clear()
	# **Dirtied before the load, so the load has something to overwrite.** Rank
	# is derived now (ADR-125), so the way to make it wrong is to give this life
	# a tree — a v1 profile has none, and reading one must clear it.
	taken.append(&"hrd_sure_grip")
	boon = 3
	class_id = &"someone_else"
	var lifted: Dictionary = SaveFile.read()
	from_dict(lifted)
	var lifted_life: Dictionary = _section(lifted, "life")
	print("[save] v1 fixture    → v%d, hoard %d, stash %d, rank %d, class '%s'" % [
		int(_section(lifted, "meta").get("save_version", 0)), hoard_value,
		stash.size(), pact_rank, class_id])
	if int(_section(lifted, "meta").get("save_version", 0)) != SaveFile.SAVE_VERSION:
		problems.append(("a v1 profile did not come back at v%d — a player "
			+ "loading from an old build is the case migrations exist for, and "
			+ "the synthetic walk above cannot prove this one")
			% SaveFile.SAVE_VERSION)
	if hoard_value != 40 or stash.size() != 1:
		problems.append(("a v1 profile lost its hoard or its stash on the way "
			+ "forward (%d value, %d stashed) — a migration that drops the "
			+ "lineage is worse than one that refuses") % [hoard_value, stash.size()])
	if pact_rank != 1 or class_id != &"":
		problems.append(("a migrated v1 profile came back at rank %d as '%s' — "
			+ "a save written before either existed describes a life that has "
			+ "neither, and inventing one locks somebody into a class they "
			+ "never picked") % [pact_rank, class_id])
	if not lifted_life.has("class_id"):
		problems.append("the v2→v3 migration did not run; `class_id` is absent")

	SaveFile.wipe()
	for problem: String in problems:
		print("[save] PROBLEM: %s" % problem)
	print("[save] probe complete")
	get_tree().quit(1 if problems.size() > 0 else 0)


func _write_raw(text: String) -> void:
	var file := FileAccess.open(SaveFile.PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()
