class_name HudFrame
extends RefCounted
## Where interface is allowed to be (`DES-019`, `M4-T20`, TEC-009 §5.1).
##
## `DES-019` names five layers and gives each one a corner — *"the Ear (top
## right)"*, *"Body (bottom left)"*, *"Burden (bottom right)"*, *"Party (left
## edge)"* — and forbids the middle: **"nothing lives in the centre. The centre
## of the screen is the game."**
##
## That is a layout specification, and until this file it existed only as prose.
## Every element positioned itself with a literal: the Ear at `MARGIN` from the
## top-right, the Chamber's readout at `(18, 18)`, the Threshold's at `(18, 18)`
## as well, in a different `CanvasLayer`. Four independent things drawing into
## one corner with nothing owning the corner.
##
## ## Why a grammar rather than tidier literals
##
## The reported bug is *"overlapping text in the threshold/hoard areas"* and it
## has been reported **twice** — ADR-140 was the same fault inside the bag,
## where a blurb's third wrapped line drew through the footer. It was fixed
## there by `BagScreen.overflowing()`, band by band, hardcoded to that one
## screen, and written *after* the collision rather than before it.
##
## Every UI probe was green both times, because a probe reads a label's `text`
## and proves the string exists — never that a human can see it.
##
## So the fix is not a tidier set of literals. It is that **an element declares
## which region it lives in and never where it is**, which makes
## `collisions()` writable *once* instead of re-derived per screen after each
## report. That check is the deliverable; the regions are what make it possible.
##
## ## Not an autoload
##
## Autoloads are a budget of six and all six are spoken for (`CLAUDE.md` §4).
## This is a plain `RefCounted` of pure functions over a viewport size — it owns
## no state, so there is nothing for a singleton to hold. `Ear` and `Reticle`
## are `Control`s a level builds; this is the ruler they measure against.
##
## ## Sized from the viewport, never from `size`
##
## `ear.gd:129`'s lesson, generalised: a `Control` whose parent is a
## `CanvasLayer` gets no laid-out size from anchors alone, so `size` is `(0, 0)`
## and top-right lands off the left edge of the screen. Every rect here is
## computed from a viewport size the caller passes in.
##
## ## Fractions, not pixels (`M4-T11`)
##
## Every region is a fraction of the viewport. The brief's accessibility
## constraint is *"no fixed-pixel layouts"*, because UI scaling is a global
## resource swap at `M4-T11` and a layout in pixels is one that has to be
## redesigned rather than rescaled. The margin is the single exception and it
## is a minimum, not a size.


## The regions `DES-019` names, plus the two the Lair needs.
##
## `PLACE` and `SPEECH` are not in `DES-019`'s five layers because `DES-019`'s
## layers describe **the Deep**. Its Lair section is explicit that *"different
## rules apply"* — numbers are welcome, cycle position must be unmissable — and
## the Chamber is where the overlap was reported. They are regions of the same
## frame so that one check covers both places rather than two.
enum Region {
	PLACE,      ## Top left. Where you are and the state that persists. Lair.
	EAR,        ## Top right. `DES-019` Layer 1 — the instrument.
	PARTY,      ## Left edge. Layer 4, co-op only. Deep.
	BODY,       ## Bottom left. Layer 2 — health, stamina, wounds. Deep.
	BURDEN,     ## Bottom right. Layer 3 — weight, and the Waystone mark.
	SPEECH,     ## Lower band. Her voice, and nothing else. Transient. Lair.
	PROMPT,     ## Below the reticle. Layer 5 — appears, then leaves.
	REFERENCE,  ## Left column. The camp's control card. Lair.
}

## **The regions are not all on screen at once, and pretending they are makes
## the check wrong in both directions.**
##
## The Deep has a body, a party and a burden. The camp has none of those and has
## a control card two hundred pixels tall, which does not fit `BODY` and should
## not have to — `BODY` is where health goes, and the camp has no health bar.
##
## Squeezing the card into a Deep region would have been the fault this file
## exists to prevent, dressed as tidiness. Instead the two worlds declare what
## they use, and the grammar is checked **per world**: a pair that can never be
## on screen together is not a collision, and a pair that can is checked whether
## or not anything happens to be drawn there today.
enum World {
	DEEP,  ## A floor. `DES-019`'s five layers.
	LAIR,  ## The Threshold and the Chamber. Different rules (`DES-019` §Lair).
}


## Which regions can be on screen together in `world`.
static func regions_of(world: World) -> Array:
	if world == World.LAIR:
		return [Region.PLACE, Region.EAR, Region.BURDEN, Region.SPEECH,
			Region.PROMPT, Region.REFERENCE]
	return [Region.EAR, Region.PARTY, Region.BODY, Region.BURDEN,
		Region.PROMPT]

## The smallest gap between anything and a screen edge, in pixels.
##
## A minimum rather than a layout unit: it stops a region touching the bezel on
## a small window, and every actual dimension below is a fraction. ⟨tune⟩
const MARGIN: float = 22.0

## **The centre is the game** (`DES-019` rule 1).
##
## Held as an explicit rect so the rule can be *checked* rather than respected.
## A region that grows into this fails `collisions()`, which is the difference
## between a rule in a document and a rule in the build. ⟨tune⟩
const KEEPOUT: Rect2 = Rect2(0.32, 0.30, 0.36, 0.28)

## **The size a layout check measures against** (`M4-T20`, ADR-198).
##
## A probe cannot ask the live viewport how big it is, because the sweep runs
## **headless** and a headless viewport is about 73 px wide — every region
## rounds to nothing, every panel "escapes", and the check fails for a reason
## that has nothing to do with the layout. ADR-093's rule is that anything whose
## correctness is a claim about seeing gets photographed; this is the other half
## of it, and the reason `--hud-probe` takes its sizes as arguments.
##
## So a screen is **declared** rather than read. The content is real — real
## strings, real fonts, real wrapping — laid out at the resolution the game is
## shot at, which makes the measurement deterministic *and* meaningful. The
## alternative was a row that only runs when somebody remembers to open a
## window, which is a row that has never failed.
const REFERENCE: Vector2 = Vector2(1152.0, 648.0)


## Where `region` lives, in pixels, for a viewport of `screen`.
##
## The one function every element calls instead of holding a position. Laid out
## so that **no two regions intersect and none of them enters `KEEPOUT`** — a
## guarantee by construction, asserted anyway by `collisions()`, which is the
## Spelunky pattern `TEC-007` §2.5 takes and every generator stage follows.
static func rect_of(region: Region, screen: Vector2) -> Rect2:
	# **Never a negative size.** A window smaller than twice the margin makes
	# `w * 0.30 - MARGIN` negative, and `Rect2.intersects` errors rather than
	# returning false — so the check would crash on exactly the degenerate case
	# it exists to survive. Clamped, so a tiny viewport yields an empty region
	# and `collisions()` skips it.
	var w: float = maxf(screen.x, MARGIN * 4.0)
	var h: float = maxf(screen.y, MARGIN * 4.0)
	match region:
		Region.PLACE:
			# Narrow on purpose. It is 0.30 wide rather than the 0.40 the
			# fifteen-line readout needed, because after TEC-009 §5.2 the
			# Chamber carries two regions and a prompt — and a region sized to
			# hold what it used to hold is a region that lets it grow back.
			return Rect2(MARGIN, MARGIN, w * 0.30 - MARGIN, h * 0.40)
		Region.EAR:
			# Square, and sized to the Ear's own `SIZE + MARGIN` growth budget
			# rather than to a fraction, because it is the one element
			# `DES-019` rule 5 permits to grow.
			var side: float = 144.0
			return Rect2(w - MARGIN - side, MARGIN, side, side)
		Region.PARTY:
			return Rect2(MARGIN, h * 0.44, w * 0.20, h * 0.28)
		Region.BODY:
			return Rect2(MARGIN, h * 0.78, w * 0.30, h * 0.22 - MARGIN)
		Region.BURDEN:
			# Deep and Lair both. It was 0.15 tall and the Chamber's Tithe panel
			# — a heading and three rows — did not fit, so it grew off the
			# bottom of the window on the first screenshot. A region sized to
			# what it holds, rather than to what looked right empty.
			return Rect2(w * 0.72, h * 0.78, w * 0.28 - MARGIN, h * 0.22 - MARGIN)
		Region.REFERENCE:
			# The left column, below `PLACE` and down to the floor. Lair only:
			# the camp's control card is ten lines and the camp has no body or
			# party frames to compete with it.
			return Rect2(MARGIN, h * 0.44, w * 0.30 - MARGIN, h * 0.56 - MARGIN)
		Region.SPEECH:
			# Horizontally centred but **below** the keepout, not in it. She is
			# the only thing in the game with a voice and it still does not get
			# to stand in the middle of the screen.
			#
			# Tall enough for **three** wrapped lines, not one. It was 0.11 and
			# a two-line refusal already stood 4 px proud of it — and because
			# speech is bottom-anchored, an overflow here climbs toward the
			# centre rather than off the bottom of the screen.
			return Rect2(w * 0.32, h * 0.72, w * 0.38, h * 0.16)
		Region.PROMPT:
			return Rect2(w * 0.32, h * 0.61, w * 0.36, h * 0.08)
	return Rect2()


## The forbidden middle, in pixels.
static func keepout(screen: Vector2) -> Rect2:
	return Rect2(KEEPOUT.position * screen, KEEPOUT.size * screen)


## Anchor a `Control` into `region` — the call that replaces a literal position.
##
## Sets both position and size, because a `Label` left to its own width is a
## `Label` that grows out of its region the moment its text lengthens, which is
## precisely how the Chamber's readout and the bag's blurb each escaped.
## **Width is fixed; height is not** — and that asymmetry is the whole lesson of
## ADR-140. `BagScreen.overflowing()` measured widths and *"never asked whether a
## block fits its height"*, so the blurb's third wrapped line drew through the
## footer with every row green. A region is a promise about width, which
## wrapping can keep. Height is then a **measured consequence**, and the thing
## `collisions()` has to be handed rather than told.
static func place(control: Control, region: Region, screen: Vector2) -> void:
	var box: Rect2 = rect_of(region, screen)
	control.position = box.position
	control.custom_minimum_size = Vector2(box.size.x, 0.0)
	control.size = Vector2(box.size.x, 0.0)
	if control is Label:
		# Wrapping is what keeps a long line inside its region instead of
		# running under whatever is beside it. `DES-019`'s regions are a
		# promise about width; this is what makes the promise true.
		var label := control as Label
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = false


## **Put a laid-out control back in its corner** (`M4-T20`).
##
## `place()` runs before a container knows how tall it is, so it can only
## promise width. A bottom-anchored region then has its content grow *downward*
## off the screen — which is what the Tithe panel did on the first screenshot:
## three rows and a heading in a region 75 px tall, clipped by the window.
##
## So the corner a region is named for is the corner it **grows from**. Bottom
## regions grow up, right-hand regions grow left, and the top-left one is the
## only place where "position" and "corner" already mean the same thing.
##
## Called after layout and cheap enough to call every frame, which is the point:
## the Chamber's aspects line wraps to two lines when the number reaches three
## digits, and a one-shot placement would be correct until it wasn't.
static func settle(control: Control, region: Region, screen: Vector2) -> void:
	var box: Rect2 = rect_of(region, screen)
	# **Snap the height to what the content needs.**
	#
	# A `Control` that is not inside a container is never grown to its minimum
	# size by anybody — Godot only does that for container children. So the
	# zero height `place()` sets stays zero, and a free `Label` measures as
	# drawing nothing at all. The Chamber's speech region did exactly that: no
	# overlap, no escape, and no height, which is a check passing because there
	# was nothing there to fail it.
	control.size = Vector2(box.size.x,
		maxf(control.size.y, control.get_minimum_size().y))
	var actual: Vector2 = control.size
	var at: Vector2 = box.position
	match region:
		Region.BODY, Region.BURDEN, Region.SPEECH, Region.REFERENCE:
			at.y = box.end.y - actual.y
		_:
			pass
	if region == Region.BURDEN:
		at.x = box.end.x - actual.x
	control.position = at


## What a control is **actually** occupying, for `collisions()`.
##
## Measured rather than assumed, and that distinction is the whole check. A
## region says where an element may be; this says where it is. ADR-140 was
## exactly the gap between those two sentences — every row green, because every
## row asked the first question.
static func occupied_by(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control) or not control.visible:
		# Absent, not zero-sized-and-present. `collisions()` skips empty rects,
		# so a hidden element cannot fail a screen for a layer it is not drawing.
		return Rect2()
	return Rect2(control.position, control.size)


## **The check that did not exist** (TEC-009 §5.6).
##
## Ten UI probes run in the sweep and not one of them asks whether two pieces of
## interface are drawn on top of each other — the reported bug, twice, invisible
## to every green row.
##
## `occupied` maps a region to the rect an element is *actually* drawing in,
## which is normally `rect_of()` but is measured from the element where it can
## be, so that a `Label` which outgrew its region is caught rather than assumed
## innocent. Regions nothing is drawing in are not passed, and are not checked:
## the question is about what a person can see, so an empty corner cannot
## collide with anything.
##
## Returns every fault, not the first, because a layout with two collisions
## fixed one at a time is two more screenshots than it needs to be.
static func collisions(occupied: Dictionary, screen: Vector2) -> PackedStringArray:
	var out := PackedStringArray()
	var middle: Rect2 = keepout(screen)
	# Sorted, so two callers enumerate faults in the same order and a probe's
	# output is diffable between runs (`TEC-007` §1 — never let a result depend
	# on the order a collection happened to be built in).
	var names: Array = occupied.keys()
	names.sort()
	for i: int in range(names.size()):
		var a_name: String = names[i]
		var a: Rect2 = occupied[a_name]
		if a.size.x <= 0.0 or a.size.y <= 0.0:
			continue
		# **Rule 1, made mechanical.** `DES-019` forbids the centre in prose and
		# nothing has ever refused a build for entering it.
		if a.intersects(middle):
			out.append(("`%s` reaches into the centre of the screen, which "
				+ "`DES-019` rule 1 keeps for the game") % a_name)
		for j: int in range(i + 1, names.size()):
			var b_name: String = names[j]
			var b: Rect2 = occupied[b_name]
			if b.size.x <= 0.0 or b.size.y <= 0.0:
				continue
			if not a.intersects(b):
				continue
			var over: Rect2 = a.intersection(b)
			out.append("`%s` and `%s` overlap by %d×%d px"
				% [a_name, b_name, int(over.size.x), int(over.size.y)])
	return out


## **Does each element stay inside the region it claimed?** (TEC-009 §5.6)
##
## The other half of the check, and the half that catches a fault *before* it
## becomes visible. `collisions()` asks whether two things are on top of each
## other, which is only true once something else has been placed nearby; this
## asks whether an element has grown out of its own box, which is true the
## moment the text gets longer.
##
## The camp's control panel was ten pixels wider than `BODY` on its first
## render. Nothing overlapped it, so `collisions()` was right to pass — and it
## is precisely the state ADR-140 was in for two milestones before a blurb grew
## one line and landed in the footer.
##
## `claims` maps a name to `[region, measured rect]`. A tolerance of one pixel,
## because a `PanelContainer`'s border rounds.
static func escapes(claims: Dictionary, screen: Vector2) -> PackedStringArray:
	var out := PackedStringArray()
	var names: Array = claims.keys()
	names.sort()
	for element: String in names:
		var claim: Array = claims[element]
		var region: Region = claim[0] as Region
		var box: Rect2 = claim[1] as Rect2
		if box.size.x <= 0.0 or box.size.y <= 0.0:
			continue
		var allowed: Rect2 = rect_of(region, screen).grow(1.0)
		if allowed.encloses(box):
			continue
		out.append(("`%s` is drawing %d×%d at (%d, %d), which is outside the "
			+ "%d×%d its region allows — nothing overlaps it yet, and that is "
			+ "the state ADR-140 sat in for two milestones") % [
				element, int(box.size.x), int(box.size.y),
				int(box.position.x), int(box.position.y),
				int(allowed.size.x), int(allowed.size.y)])
	return out


## Every region's rect, for the probe that asserts the grammar itself is sound.
##
## Distinct from `collisions()` on purpose: that one asks what is on screen
## *now*, this one asks whether the grid could ever be laid out cleanly. A
## regression in `rect_of()` is caught even on a screen where nothing happens to
## be drawn.
static func all_rects(screen: Vector2, world: World) -> Dictionary:
	var out: Dictionary = {}
	for region: int in regions_of(world):
		out[Region.keys()[region]] = rect_of(region as Region, screen)
	return out
