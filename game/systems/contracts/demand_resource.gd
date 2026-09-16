class_name DemandResource
extends Resource

## **Her demand** (`M4-T04`, ADR-243) — `DES-007`'s tier 1, the pact's long arc.
##
## `DES-007`: *"the dragon's own agenda. Multi-run objectives that advance Pact
## Rank and unlock Aspect nodes."* Rank is what the tree cost you (ADR-125), so
## nothing may raise it from outside; what a demand can honestly do is **open**
## something. By the developer's call, once a life she names a count of one
## glitter, given at the hoard across as many runs as it takes, and meeting it
## opens her loudest nodes — the pact nodes a rank already gates (`DES-004`).
## They are still bought with Boon, so the Tithe still rises: an option opened,
## never a number raised (ADR-058), and power that still costs risk
## (principle 2).

const NUMBERS: Array[String] = ["no", "one", "two", "three", "four", "five", "six",
	"seven", "eight", "nine"]

@export var id: StringName = &""
## What is said when she names it, and when it is met. Narrated, as she always
## is, in the third person.
@export var named_key: StringName = &""
@export var met_key: StringName = &""
## The glitter she wants, and how many of it.
@export var item: StringName = &""
@export var count: int = 1


func wanted() -> ItemResource:
	return ItemCatalogue.by_id(item)


## *three Gilded Torcs* — the demand as a phrase a readout can hold.
func display() -> String:
	var thing: ItemResource = wanted()
	var called: String = thing.display() if thing != null else String(item)
	var many: String = NUMBERS[count] if count >= 0 and count < NUMBERS.size() \
		else str(count)
	return "%s %s%s" % [many, called, "s" if count != 1 else ""]


func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not String(id).begins_with("dmd_"):
		problems.append("demand id '%s' does not start with dmd_ (TEC-006)" % id)
	if named_key == &"" or met_key == &"":
		problems.append("%s says nothing when it is named or met" % id)
	if count < 1:
		problems.append("%s asks for %d — a demand for nothing is met before it is made"
			% [id, count])
	var thing: ItemResource = wanted()
	if thing == null:
		problems.append("%s wants '%s', which this build does not have" % [id, item])
	elif not thing.tags.has(&"glitter"):
		problems.append("%s wants '%s', which does not glitter — she wants what glitters"
			% [id, item])
	return problems
