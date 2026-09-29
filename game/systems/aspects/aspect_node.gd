class_name AspectNode
extends Resource

## One node of the dragon's tree (`M3-T01`, `DES-004`), as data rather than as
## code.
##
## `ItemResource` and `ClassResource` are the shape this follows — the id
## prefix, the locale keys, the `validate()` that runs at boot — because it
## answers the same question: a profile holds `"hrd_ballast"` and something has
## to turn that back into a node without the save knowing where the file lived.
##
## ## The rule that shapes every one of these
##
## `DES-004` anti-bloat rule 2: **no node is purely numeric. Ever.** It is the
## rule the whole tree rests on, because a tree of percentages is precisely the
## trivialisation curve `DES-003` §A is written to prevent — by rank 8 you walk
## through what killed you at rank 1, and the run stops being a decision.
##
## There is no `power` or `magnitude` field here, and that absence is the
## design. ADR-058's test — *does this let the player do something new, or does
## it just make an existing number bigger* — is enforced by the schema having
## nowhere to put a bigger number.
##
## ## `effect_tags` is where the discipline lives (`TEC-006`)
##
## > *"A node declares `carry_no_limit` and the inventory system reacts. The
## > node never contains logic."*
##
## So a node is a **name and a set of tags**, and the system that owns a rule is
## the only thing that knows what changing it means. `Inventory` asks whether
## this life has `carry_no_limit`; the tree never reaches into a bag. That is
## also what makes `DES-004` rule 2 reviewable rather than aspirational — a node
## with no tag does nothing, `validate()` refuses it, and a stat stick has
## nowhere to hide because there is no number to be the stick.
##
## ## What is derived rather than stored
##
## `TEC-006` sketches `boon_cost` and `tithe_increase` as fields. Both are
## superseded by more specific decisions taken since:
##
## - **Cost** is fixed by tier — ADR-060 gives lesser 1 · greater 2 · keystone
##   5 — and a per-node price would let one lesser node quietly become worth
##   three, which is rule 2's bigger-number pressure arriving through the price
##   instead of through the effect. It is read through
##   `TuningProfile.node_cost()` rather than answered here, because a resource
##   that reaches for an autoload cannot be validated by `data_probe.gd` — that
##   runs as `--script` with none registered, and one `Config` reference in a
##   resource stops the **whole corpus** from checking.
## - **The Tithe increase** is the rank table in `TuningProfile` (ADR-118 chose
##   a table over a curve, because `DES-003` gives three anchors and everything
##   between them is judgement). A per-node increment would be a second way to
##   move the same obligation.

## `DES-004`'s three, and the cost of each is `TuningProfile.node_cost`.
enum Tier { LESSER, GREATER, KEYSTONE }

## **The Pact Rank a Rite opens at** (ADR-060) ⟨tune⟩ — the whole branch, not
## node by node. Not `rank_required`, deliberately: that field marks *her*
## loudest gifts, which also wait on her demand (ADR-243), and a Rite is the
## class's own path rather than something she hands down. A Rite has no
## keystone either — `DES-004`'s one-keystone rule belongs to the Aspects.
const RITE_RANK: int = 3

@export var id: StringName = &""
## Which of `DES-004`'s five this belongs to. Validated against
## `ClassResource.ASPECTS` so there is one list of Aspect names in the project.
## Empty for a Rite node, which belongs to a class instead.
@export var aspect: StringName = &""
## **The class whose Rite this is** (`DES-011`, `M4-T03`, ADR-273), or empty for
## an Aspect node. A Rite is the class-only branch — *"nobody else can take
## these"* — so the one field that says whose it is is also the gate, and a
## node cannot be in an Aspect and a Rite at once.
@export var sworn: StringName = &""
@export var tier: Tier = Tier.LESSER

@export_group("Text")
@export var name_key: StringName = &""
## One sentence a player would repeat aloud — `DES-004` anti-bloat rule 1 makes
## that the test for whether a node should exist at all.
@export var description_key: StringName = &""

@export_group("Shape")
## Nodes that must already be taken. A path down the tree rather than a menu:
## `DES-004`'s model is *"take its keystone, take minor nodes down it"*, and
## prerequisites are what make a build a route instead of a shopping list.
@export var requires: Array[StringName] = []
## What systems react to (`TEC-006`). The node never contains logic; it names a
## rule, and whichever system owns that rule reads it through
## `GameState.has_effect`.
@export var effect_tags: Array[StringName] = []
## Pact Rank required, or 0. `DES-004`'s **pact nodes** — *"gate the loudest
## effects behind Tithe obligation, so top-end power always costs risk"*
## (`DES-003`). The gate is real precisely because rank raises the Tithe.
@export var rank_required: int = 0


## Three letters per Aspect, so ids sort into their paths.
static func _prefix(path: StringName) -> String:
	match path:
		&"hoard": return "hrd_"
		&"cinder": return "cnd_"
		&"scale": return "scl_"
		&"wing": return "wng_"
		&"maw": return "maw_"
		_: return ""


func display() -> String:
	return tr(String(name_key)) if name_key != &"" else String(id)


## **Whether this node does anything for a body sworn to `class_id`.** An Aspect
## node always does. A Rite node only for its own class — `DES-011`'s Legacy
## rule: *"class Rite nodes can occupy a Legacy slot, but only apply if the next
## life is the same class"*. Asked wherever a tree becomes effects, so there is
## one answer.
func applies_to(class_id: StringName) -> bool:
	return sworn == &"" or sworn == class_id


## Checked at boot by `AspectCatalogue`, in the shape the item and class
## resources established: a malformed node should stop the build rather than
## reach a player as a purchase that does nothing.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	if id == &"":
		problems.append("a node with no id cannot be taken or saved")
	if sworn != &"":
		# **A Rite node** (ADR-273). Its class is checked against the catalogue
		# by `data_probe`, which can see it; here, only its own shape.
		if aspect != &"":
			problems.append("%s is in the %s Aspect and %s's Rite at once"
				% [id, aspect, sworn])
		if not String(id).begins_with("rit_"):
			problems.append("%s is a Rite node and should be named 'rit_…'" % id)
		if tier == Tier.KEYSTONE:
			problems.append("%s is a Rite keystone — a Rite has none" % id)
		if rank_required > 0:
			problems.append(("%s gates on rank %d — a Rite opens as a whole at "
				+ "RITE_RANK and waits on no demand") % [id, rank_required])
	elif not ClassResource.ASPECTS.has(aspect):
		problems.append(("%s belongs to '%s', which is not one of DES-004's "
			+ "five — a sixth Aspect is a design change needing an ADR")
			% [id, aspect])
	if name_key == &"" or description_key == &"":
		problems.append(("%s has no name or description — `DES-004` rule 1 is "
			+ "that a node you cannot say in one sentence should be cut, and a "
			+ "node with no sentence at all cannot be read by anybody") % id)
	if rank_required < 0:
		problems.append("%s requires a negative Pact Rank" % id)
	# **The stat-stick check, made mechanical** (`TEC-006`). A node with no tag
	# reacts nowhere, so it is either a number in disguise or a purchase that
	# does nothing — and `DES-004` rule 2 exists to keep both out of the tree.
	if effect_tags.is_empty():
		problems.append(("%s declares no effect_tags, so nothing anywhere reacts "
			+ "to owning it — `TEC-006` puts the discipline in the tags "
			+ "precisely so a node with only a number is reviewable as the stat "
			+ "stick `DES-004` rule 2 forbids") % id)
	# The id says which Aspect it is in, so a node can be placed by eye in a
	# folder of a hundred and a save file naming one is legible in a bug report.
	if id != &"" and sworn == &"" and aspect != &"" \
			and not String(id).begins_with(_prefix(aspect)):
		problems.append("%s is a %s node and should be named '%s…'"
			% [id, aspect, _prefix(aspect)])
	for other: StringName in requires:
		if other == id:
			problems.append("%s requires itself, which can never be satisfied" % id)
	return problems
