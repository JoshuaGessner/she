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
## ## Not saved to disk yet, and that is a different system
##
## The stash and the hoard are real and they persist across runs. They do
## **not** survive quitting, because writing them down is `TEC-003`'s versioned
## save format and `M3-T06`'s task. Nothing here is faked to look persistent —
## a session's hoard is genuinely the sum of that session's tributes, and it
## acquires a file when the file has a migration path.
##
## ## Never networked
##
## `DES-012` makes every pact individual and `TEC-004` keeps progression off
## the wire entirely. This is local state on every peer, describing only the
## person sitting at that machine. ADR-021 makes that structural rather than
## careful: the Chamber where it all lives is a scene no other player enters.

signal stash_changed()
signal hoard_changed(total: int)

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

## Runs completed this session, for the readouts. Not progression; `DES-003`'s
## Pact Rank is `M3-T04` and is a different number with different rules.
var descents: int = 1


## Carried out alive. The Chamber sorts it from here.
func bring_home(items: Array[ItemInstance]) -> void:
	carried = items.duplicate()


## Put on the pile. One-way, by construction: there is no method that takes
## anything off a hoard, because `DES-014` gives her everything you ever gave
## her and never gives any of it back.
func tribute(item: ItemInstance) -> void:
	hoard.append(item.definition.id)
	hoard_value += item.definition.tribute_value
	carried.erase(item)
	stash.erase(item)
	hoard_changed.emit(hoard_value)
	stash_changed.emit()


## Kept for next time.
func keep(item: ItemInstance) -> void:
	if not stash.has(item):
		stash.append(item)
	carried.erase(item)
	stash_changed.emit()


## Take something back out of the stash for a descent.
func withdraw(item: ItemInstance) -> void:
	stash.erase(item)
	stash_changed.emit()


## **The great reset** (`DES-008`, ADR-004). Everything you were carrying and
## everything you had put aside, gone. The hoard is untouched and that is the
## entire point: the pile is what you have to show for the lives it cost.
func die() -> void:
	carried.clear()
	stash.clear()
	stash_changed.emit()


func stash_value() -> int:
	var sum: int = 0
	for item: ItemInstance in stash:
		sum += item.definition.tribute_value
	return sum


func carried_value() -> int:
	var sum: int = 0
	for item: ItemInstance in carried:
		sum += item.definition.tribute_value
	return sum
