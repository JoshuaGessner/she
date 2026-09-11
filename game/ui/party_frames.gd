class_name PartyFrames
extends Control

## **Is my teammate up, down, or a Vörðr?** (`M4-T20`, `DES-019` Layer 4,
## ADR-212)
##
## `GATE M4 COOP` asks a repeatedly-downed newcomer whether they still want to
## go again, and until now nobody could see the thing that question is about.
## `FallenReadout` answers *what is happening to me* — it binds to
## `local_player` deliberately, because being down is the worst moment in the
## game and the person in it needs the whole screen. It says nothing about
## anybody else.
##
## So a party of four had no way to know that somebody was bleeding out two
## rooms away, and `DES-012`'s rescue is a **social** act: the whole design
## assumes a teammate is deciding whether to come for you. A decision nobody can
## see is not a decision.
##
## ## Everyone but you
##
## The local player is the `BODY` layer's, and drawing yourself twice would
## spend the left edge on something already on screen. `DES-019` says *three
## compact frames*, which is a four-stack minus you.
##
## ## All five values were already on the wire, and one was not
##
## `Health:current`, `ClamorSource:level` and `sworn` have been in
## `Player.STATE_PROPERTIES` since `M3-T07` — configured by node path, which is
## why they are easy to miss when looking for them on `Health` itself. Health
## even rides the spawn packet, and `maximum` is derived locally from the class
## every peer already has, so `fraction()` is correct on every machine without
## sending it.
##
## **Rank was not.** It lived in `CoopSession._ranks`, host-side and keyed by
## peer, so a client could see who its teammates were and not what they were.
## `M4-T20` put `rank` on the body beside `sworn`, replicated the same way and
## for the same reason — the host builds a joining peer's body before that
## peer's declaration arrives.
##
## ## The vocabulary is `FallenReadout`'s, on purpose
##
## A **shortening** bar is bleeding out and a **filling** bar is a hand on you —
## the same two directions, so a player who has learned them from the inside
## reads them on somebody else without being taught twice. `DES-018`: direction
## carries the meaning and hue only agrees with it, so this survives the sound
## being off and the colour being gone.

## One row's height in pixels ⟨tune⟩.
const ROW: float = 40.0
## Gap between rows ⟨tune⟩.
const GUTTER: float = 6.0
## How wide a bar runs, as a share of the frame ⟨tune⟩.
const BAR_SHARE: float = 0.70
const BAR_HEIGHT: float = 4.0
## The Clamor pip's radius at its loudest ⟨tune⟩.
##
## ADR-039's *"you're the loud one"* made visible without cluttering the Ear,
## which `DES-019` rule 5 reserves as the only element allowed to carry urgency.
## A pip that grows is a pip you notice without reading.
const PIP_RADIUS: float = 4.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## **The height three frames need, declared rather than assigned.**
##
## `HudFrame.place` overwrites `custom_minimum_size` with the region's width and
## a height of **zero**, which is right for the labels it was written for and
## leaves a drawn `Control` with nothing to paint into. `settle` reads
## `get_minimum_size()`, and this is the answer `place` cannot overwrite.
##
## Sized for **three** rather than for however many are here: `DES-019` says
## three compact frames, a four-stack minus you is three, and a region that
## resized itself as teammates died would move the surviving rows at the exact
## moment somebody is trying to read them.
func _get_minimum_size() -> Vector2:
	return Vector2(0.0, (ROW + GUTTER) * 3.0)


func _process(_delta: float) -> void:
	queue_redraw()


## The party, minus you, in seat order.
##
## Seat order rather than discovery order: `party_slot` rides the spawn packet
## and never changes, so a frame stays in the same place for the whole run. A
## list that reorders itself when somebody goes down is a list you have to
## re-read at the moment you can least afford to.
func others() -> Array[Player]:
	var found: Array[Player] = []
	for node: Node in get_tree().get_nodes_in_group("player"):
		var body := node as Player
		if body == null or body.is_queued_for_deletion():
			continue
		if body.is_in_group("local_player"):
			continue
		found.append(body)
	found.sort_custom(func(a: Player, b: Player) -> bool:
		return a.party_slot < b.party_slot)
	return found


## What one body is doing, as a word the frame draws and a shot can assert.
##
## Public and string-valued because the windowed measurement compares what is
## drawn against what is true, and deriving the expectation from the expression
## that drew it is ADR-192's fault — a row that cannot fail.
static func state_of(body: Player) -> StringName:
	if body.got_out:
		return &"out"
	if body.spent:
		return &"vordr"
	if body.revival > 0.0:
		return &"held"
	if body.bleeding > 0.0:
		return &"down"
	return &"up"


## The loudest anyone in the party is right now, including you.
##
## **The pip is comparative, and that is the point.** `DES-019` asks for it so
## that *"you're the loud one"* is visible, which is a statement about the party
## and not about a number — and scaling against the loudest present needs no
## ⟨tune⟩ ceiling to be invented for it. A party creeping together shows three
## small pips; the one who just sprinted in mail shows one big one.
func _loudest() -> float:
	var most: float = 0.0
	for node: Node in get_tree().get_nodes_in_group("player"):
		var body := node as Player
		if body == null or body.is_queued_for_deletion():
			continue
		most = maxf(most, body.clamor.level)
	return most


func _draw() -> void:
	var top: float = 0.0
	var most: float = _loudest()
	for body: Player in others():
		_draw_frame(body, top, most)
		top += ROW + GUTTER


func _draw_frame(body: Player, top: float, loudest: float) -> void:
	var state: StringName = state_of(body)
	var quiet: bool = state == &"up" or state == &"out"
	var ink: Color = MenuStyle.dim() if quiet else MenuStyle.ink()
	var font: Font = get_theme_default_font()

	# The seat, as a standing tick. It is the only part of a frame that never
	# moves, so it is what the eye finds the row by.
	draw_rect(Rect2(0.0, top + 5.0, 2.0, ROW - 10.0), ink)

	# **Who, what and how far down** — `DES-019` Layer 4's name and class, plus
	# the rank, because ADR-010 builds the floor for the deepest rank *present*
	# and that number is the reason the room is what it is.
	var who: String = "%s  %s" % [
		body.name, String(body.sworn).to_upper() if body.sworn != &"" else "—"]
	draw_string(font, Vector2(10.0, top + 13.0), who,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, ink)
	draw_string(font, Vector2(10.0, top + 27.0), "rank %d" % body.rank,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MenuStyle.dim())

	var run: float = size.x * BAR_SHARE
	var left: float = 10.0

	# **Health, and it is not the bleed-out bar.** Two bars would be two things
	# to read at the worst moment, so health sits on its own line above and the
	# state bar replaces it only when there is a window running.
	if state != &"down" and state != &"held":
		var whole := Rect2(left, top + ROW - 10.0, run, BAR_HEIGHT)
		draw_rect(whole, MenuStyle.overlay())
		var share: float = clampf(body.health.fraction(), 0.0, 1.0)
		draw_rect(Rect2(whole.position, Vector2(run * share, BAR_HEIGHT)), ink)
	else:
		var base := Rect2(left, top + ROW - 10.0, run, BAR_HEIGHT)
		draw_rect(base, MenuStyle.overlay())
		# Shortening for a bleed-out, filling for a hand on you. **The two are
		# not in the same units** — `revival` is already 0..1 and `bleeding` is
		# *seconds remaining* — so the bleed is divided by the window it counts
		# down, exactly as `FallenReadout` does it. Read as a share it would
		# draw a full bar for the first second and nothing after.
		var share: float = clampf(body.revival, 0.0, 1.0)
		if state == &"down":
			var whole_window: float = maxf(
				Config.tuning.bleed_out_seconds, 0.001)
			share = clampf(body.bleeding / whole_window, 0.0, 1.0)
		draw_rect(Rect2(base.position, Vector2(run * share, BAR_HEIGHT)), ink)

	# The Clamor pip, at the right edge of the row. Radius rather than hue, so
	# it reads with the colour gone (`DES-018`).
	var loud: float = clampf(
		body.clamor.level / maxf(loudest, 0.001), 0.0, 1.0)
	if loudest > 0.0 and loud > 0.0:
		draw_circle(Vector2(size.x - PIP_RADIUS - 2.0, top + ROW * 0.5),
			PIP_RADIUS * loud, ink)
