class_name Ear
extends Control

## The visual twin (`M2-T03`, `DES-018` Channel B, `DES-019` Layer 1).
##
## **Everything the mix tells you, this tells you.** It renders the same
## `HuntMix` the score is driven by — not a parallel reading of the world, the
## *same object* — so the two channels cannot drift apart. `--ear-probe` fails
## if a mix channel exists that nothing here draws.
##
## `DES-019` gives it the top-right corner, where a minimap would conventionally
## live, deliberately: it is this game's answer to a minimap and putting it
## there says so.
##
## ## A core and a ring, and which half is which
##
## > **Cause on the inside, effect on the outside.**
##
## - **Inner core = you.** It fills and quickens with your own Clamor. This is
##   the readout that makes greed legible.
## - **Outer ring = the world.** Arcs light where attention is coming from; the
##   ring's *character* carries the alert ladder; the Gullsjúkr takes a heavy
##   mark of its own.
##
## Each half can then be read independently at a glance, which is the whole
## reason `DES-019` splits them — the four things this carries are of two
## fundamentally different kinds, and cramming them into one undifferentiated
## widget is what makes HUD elements unreadable.
##
## ## The risk `DES-019` names, and the rule that fixes it
##
## > *"A brighter flame reads as good. **High Clamor must look guttering and
## > sick — never warm, never powerful.**"*
##
## So loud does not mean bigger and brighter here. It means **desaturated,
## thinner, and unstable**: the core loses colour as it fills, its edge breaks
## up, and it jitters. If a playtester ever calls the loud state "cool", this
## has failed and the fix is more sickness, not less glow.
##
## ## The guardrail that keeps it from becoming a radar
##
## > **It reports attention, not positions.**
##
## - **Coarse bearing only** — `SECTORS` of them ⟨tune⟩, never a precise angle.
## - **Only attention that exists.** An unaware room produces a blank ring
##   however many enemies are standing in it, which is why `HuntMix.bearing`
##   is `NAN` rather than zero when nothing is attending.
## - **Never count, health, or type.**
##
## Without this the Ear becomes a wallhack, players stare at the corner instead
## of the room, and the entire look-at-the-world premise of the lighting and
## audio design collapses.
##
## ## Readable with the colour taken out
##
## `DES-018`: shape and motion first, colour second, never hue alone (~8% of
## men). Every state here is carried by **fill, thickness, break-up and
## motion**; colour only ever agrees with something already said by shape.

## Every mix channel this draws. Compared against `HuntMix.CHANNELS` in both
## directions by `--ear-probe`, so a channel added to the score without a
## visual fails the build — which is ADR-036 made mechanical rather than
## promised. Adding a name here without drawing it would defeat that, and is
## the one thing the probe cannot catch on its own.
const RENDERED: Array[String] = ["clamor", "alert", "hunter", "bearing"]

## `DES-019` ⟨tune⟩: eight sectors, never a precise angle.
const SECTORS: int = 8

const SIZE: float = 96.0
const MARGIN: float = 22.0
## How much the whole element is allowed to grow under pressure. `DES-019`
## rule 5: **the only element permitted to grow**, and everything else on
## screen stays exactly as it was.
const GROWTH: float = 0.28

const RING_RADIUS: float = 40.0
const RING_WIDTH: float = 5.0
const CORE_RADIUS: float = 26.0

## Warm and whole when quiet; pale, thin and sick when loud. Never the other
## way round — see the class note.
const CORE_QUIET: Color = Color(0.92, 0.64, 0.26, 0.95)
const CORE_LOUD: Color = Color(0.78, 0.80, 0.72, 0.72)
const CORE_EMPTY: Color = Color(0.16, 0.15, 0.14, 0.55)
const RING_IDLE: Color = Color(0.34, 0.33, 0.31, 0.55)
const RING_ATTENDING: Color = Color(0.86, 0.84, 0.78, 0.92)
const HUNTER_MARK: Color = Color(0.93, 0.75, 0.28, 1.0)

var _mix: HuntMix = HuntMix.new()
## Drives the guttering. Advanced by clamor rather than by wall-clock, so a
## quiet ember is steady and a loud one is visibly agitated.
var _flicker: float = 0.0


## Hang an Ear off the local player, the way the bag is. Only the body this
## process is playing gets one.
static func attach(to: Player) -> Ear:
	var layer := CanvasLayer.new()
	layer.name = "EarLayer"
	var ear := Ear.new()
	ear.name = "Ear"
	layer.add_child(ear)
	to.add_child(layer)
	return ear


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# It reports; it never accepts. A HUD element that ate a click would be a
	# reticle-adjacent surprise in a game with no cursor during play.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioDirector.mixed.connect(_on_mixed)


func _on_mixed(mix: HuntMix) -> void:
	_mix = mix
	queue_redraw()


func _process(delta: float) -> void:
	# Guttering runs on its own clock so the ember is alive even when the mix
	# is steady, and quickens with your own noise.
	_flicker += delta * (1.0 + _mix.clamor * 7.0)


func _draw() -> void:
	var grown: float = 1.0 + GROWTH * _mix.pressure()
	# `get_viewport_rect()`, **not** `size`. A `Control` whose parent is a
	# `CanvasLayer` does not get a laid-out size from anchors alone, so `size`
	# is (0, 0) and top-right lands off the left edge of the screen. The first
	# screenshot was of an empty corner; nothing headless could have caught it,
	# because `_draw` never runs there.
	var screen: Vector2 = get_viewport_rect().size
	var centre := Vector2(
		screen.x - MARGIN - SIZE * 0.5,
		MARGIN + SIZE * 0.5)
	_draw_ring(centre, grown)
	_draw_core(centre, grown)
	_draw_hunter(centre, grown)


## The world half: how alert it is, and roughly where from.
##
## Character carries the ladder rather than colour — an idle ring is a thin
## unbroken circle, an attending one thickens and breaks into sectors. That is
## legible with the hue removed, which is the point.
func _draw_ring(centre: Vector2, grown: float) -> void:
	var radius: float = RING_RADIUS * grown
	var width: float = RING_WIDTH * (1.0 + _mix.alert * 0.8)
	draw_arc(centre, radius, 0.0, TAU, 64, RING_IDLE, width * 0.6, true)
	if not _mix.has_bearing() or _mix.alert <= 0.0:
		# Nothing is attending. A blank ring, however many enemies are in the
		# room — `DES-019`'s guardrail, and the reason `bearing` is NAN rather
		# than a direction nobody is looking from.
		return

	# Quantised to sectors so it can never be read as a precise angle. The
	# bearing is a world angle and the Ear is screen-fixed, which is correct:
	# it answers "something over there heard me", not "look here".
	var span: float = TAU / float(SECTORS)
	var sector: int = int(round(_mix.bearing / span)) % SECTORS
	var middle: float = float(sector) * span
	# A pulsing sector reads as *listening*; a solid one as *found*. Motion is
	# doing the work that colour is not allowed to do alone.
	var beat: float = 1.0
	if _mix.alert < 0.9:
		beat = 0.55 + 0.45 * sin(_flicker * 5.0)
	var lit: Color = RING_ATTENDING
	lit.a *= beat
	draw_arc(centre, radius, middle - span * 0.42, middle + span * 0.42,
		12, lit, width, true)


## The you half: your own Clamor, and it must read as *sick* when it is high.
func _draw_core(centre: Vector2, grown: float) -> void:
	var radius: float = CORE_RADIUS * grown
	draw_circle(centre, radius, CORE_EMPTY)
	if _mix.clamor <= 0.001:
		return
	# Area-proportional, not radius-proportional: a ring filling by radius
	# reads as far fuller than it is, and this is the number the player is
	# meant to be able to trust at a glance.
	var filled: float = radius * sqrt(clampf(_mix.clamor, 0.0, 1.0))
	# Unstable at the top end. The wobble is the *whole* legibility argument
	# for loud not reading as powerful.
	var gutter: float = 1.0 + sin(_flicker * 9.0) * 0.06 * _mix.clamor
	var colour: Color = CORE_QUIET.lerp(CORE_LOUD, _mix.clamor)
	draw_circle(centre, filled * gutter, colour)
	# Thin, broken edge as it gets loud — the ember blown about rather than
	# burning brighter.
	if _mix.clamor > 0.45:
		var flecks: int = 10
		for i: int in range(flecks):
			var angle: float = TAU * float(i) / float(flecks) + _flicker * 0.8
			var jitter: float = 1.0 + sin(_flicker * 6.0 + float(i)) * 0.12
			var at: Vector2 = centre + Vector2(cos(angle), sin(angle)) \
				* filled * gutter * jitter
			draw_circle(at, 1.6 * _mix.clamor, Color(colour, 0.5 * _mix.clamor))


## The Hunter's mark. Distinct, heavy, and present whenever it is on the floor —
## `DES-018`: *"it appears when the reserved instrument does."*
func _draw_hunter(centre: Vector2, grown: float) -> void:
	if _mix.hunter <= 0.0:
		return
	var radius: float = (RING_RADIUS + 8.0) * grown
	var angle: float = 0.0
	if _mix.has_bearing():
		var span: float = TAU / float(SECTORS)
		angle = round(_mix.bearing / span) * span
	var at: Vector2 = centre + Vector2(sin(angle), -cos(angle)) * radius
	# A wedge rather than a dot, and it grows with the Hunter's state. Shape
	# distinguishes it from anything else on the ring, so it survives both
	# monochrome and a glance.
	var heavy: float = 4.0 + 5.0 * _mix.hunter
	draw_circle(at, heavy, HUNTER_MARK)
	# While it is stooped over a bait the mark hollows out. That is the visual
	# twin of the mix dropping away — the beat has to exist in both channels or
	# a muted player never gets their window (`DES-018`).
	if _mix.collecting:
		draw_circle(at, heavy * 0.55, Color(0.10, 0.10, 0.10, 0.9))
