class_name WoundVignette
extends Control

## What is happening to you, drawn instead of counted (`M2-T13`, ADR-105).
##
## `DES-019` already asked for this — *"wounds in gait, in a hand that won't
## come all the way up, **in vignette**"* — and nothing drew it. Until now the
## only channel telling a player they were being hurt was a `HURT` sample and a
## number changing in a debug label, so the honest description of a fight was
## "swing until you die": you could hear that something had happened and read
## afterwards that it had, but not feel it happening or tell where it came from.
##
## ## Two things, one drawing
##
## - **A hit flashes, and it flashes on the side it came from.** Principle 4 of
##   the working agreement is that a player must be able to explain their death
##   in one sentence, and *"something killed me from behind"* is not a sentence
##   this game can currently let anyone say truthfully — there was no channel
##   carrying direction at all. The Ear carries *attention* bearing (`DES-019`
##   Layer 2); this carries *damage* bearing, which is a different question and
##   arrives after the decision rather than before it.
##
## - **A standing darkness that deepens as you do.** This is the wound half:
##   below `WOUNDED` the edges of the screen close in, continuously, with no
##   number and no bar. It is deliberately *not* a health bar — `DES-019`'s real
##   Burden layer is `M4-T05` and building a provisional one here would be the
##   parallel path ADR-064 bans. A vignette cannot be read precisely, which is
##   correct: it tells you *how bad*, never *how many*.
##
## ## Not juice
##
## `DES-009`'s M1 protocol withholds hitstop, camera kick and particles until
## the blockout feels good unjuiced, and that rule stands. This is not on that
## list: it carries **information the player has no other way to get**, which is
## the same argument that put the Reticle and the Ear on screen. The test is
## whether removing it would cost the player a fact or only a feeling — remove
## this and "which side is hitting me" becomes unanswerable.
##
## Monochrome-safe (`DES-018`): the flash is a value change at the screen edge,
## not a colour, so a player with colour vision differences and a player with
## the sound muted both still get it.

## Seconds a hit stays legible. Long enough to notice while being hit again,
## short enough that two hits read as two.
const FLASH_SECONDS: float = 0.55  # ⟨tune⟩
const FLASH_STRENGTH: float = 0.62  # ⟨tune⟩

## Health fraction below which the standing vignette begins. Above this you are
## fine and the screen says nothing at all — a permanent effect would stop
## meaning anything within a minute.
const WOUNDED: float = 0.7  # ⟨tune⟩
const WOUND_STRENGTH: float = 0.55  # ⟨tune⟩

## How far across the screen a flash reaches from its edge.
const ARC: float = 0.34

## How far off centre a hit must be before it counts as coming from one side
## rather than from in front of you.
const SIDEWAYS: float = 0.25

## Bands per edge. Eight is enough that the gradient does not band visibly at
## 1080p and few enough that the whole vignette is a couple of dozen quads.
const STEPS: int = 8

## Ink, never red. `ART-005` gives the Deep pale ink on black and spends every
## saturated hue on treasure; a red damage flash would put the game's loudest
## colour on the one event that happens most often, and blood in this world is
## *"desaturated almost to black"* anyway.
const SHADOW: Color = Color(0.02, 0.02, 0.03)
## A blow the guard took (`M3-T02`). Pale rather than dark, and briefer than a
## wound: `DES-018` wants every audio channel to have a visual twin, and
## without one a block is indistinguishable from a miss — the player learns
## nothing about whether the thing they are holding down is working.
const GUARD: Color = Color(0.62, 0.60, 0.54)
const GUARD_SECONDS: float = 0.22  # ⟨tune⟩

var _body: Player = null
var _health: Health = null
var _flash: float = 0.0
## Where the last hit came from, in screen terms: -1 is hard left, +1 hard
## right, and the sign of `_from_behind` says whether it was in front.
var _from_x: float = 0.0
var _from_behind: bool = false
## Seconds of guard-flare left, drawn over the same edges a wound uses.
var _guard: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _health == null or not is_instance_valid(_body):
		_bind()
		if _health == null:
			return
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta / FLASH_SECONDS)
	if _guard > 0.0:
		_guard = maxf(0.0, _guard - delta / GUARD_SECONDS)
	queue_redraw()


## Bodies are spawned at runtime, so bind on the first frame one exists rather
## than assuming scene order — and bind to `local_player`, because this is the
## screen of the person sitting at this machine and nobody else's.
func _bind() -> void:
	_body = get_tree().get_first_node_in_group("local_player") as Player
	if _body == null:
		return
	_health = _body.health
	_health.damaged.connect(_on_damaged)
	_body.blocked.connect(_on_blocked)


## Direction is computed **here, from the camera**, rather than being handed
## down from the hit. The same blow is on your left or your right depending on
## which way you are facing when it lands, so a bearing baked in at damage time
## would be wrong by the time it was drawn.
func _on_damaged(_amount: float, _remaining: float, from: Node) -> void:
	_flash = 1.0
	_from_x = 0.0
	_from_behind = false
	var source := from as Node3D
	if source == null or not is_instance_valid(source):
		# Damage with no source in the world — a fall, or a thing that has
		# already been freed. Flash without a direction rather than inventing
		# one: a lie about where you were hit from is worse than silence.
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var to_source: Vector3 = source.global_position - camera.global_position
	to_source.y = 0.0
	if to_source.length_squared() < 0.0001:
		return
	to_source = to_source.normalized()
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = camera.global_transform.basis.x
	right.y = 0.0
	_from_x = clampf(right.normalized().dot(to_source), -1.0, 1.0)
	_from_behind = forward.dot(to_source) < 0.0


func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	var wound: float = 0.0
	if _health != null and _health.maximum > 0.0:
		var fraction: float = _health.fraction()
		if fraction < WOUNDED:
			wound = (1.0 - fraction / WOUNDED) * WOUND_STRENGTH
	if wound > 0.0:
		# The standing wound closes in from every side, so it reads as the
		# frame tightening rather than as a direction.
		_draw_sides(screen, true, true, 1.0, wound)
		_draw_caps(screen, wound)
	_draw_guard(screen)
	if _flash <= 0.0:
		return

	# **A hit you could see does not get an edge flash.** If the thing that hit
	# you is in front of you, the screen already shows it and a marker would be
	# telling you something you know. The flash exists for the case the camera
	# cannot cover, which makes its presence meaningful rather than constant:
	# when the edges go dark, something is on you that you are not looking at.
	#
	# Behind reads as *both* edges rather than as a bearing you could aim at —
	# `DES-019`'s guardrail for the Ear, report attention and never positions,
	# applies just as well here. It says "turn round", not "it is exactly there".
	var strength: float = _flash * FLASH_STRENGTH
	if _from_behind:
		_draw_sides(screen, true, true, ARC, strength)
	elif _from_x < -SIDEWAYS:
		_draw_sides(screen, true, false, ARC, strength)
	elif _from_x > SIDEWAYS:
		_draw_sides(screen, false, true, ARC, strength)


## Darkening bands down the left and/or right edges. `spread` is how far across
## the screen they reach, `strength` how dark they get at the very edge.
##
## Stacked translucent rectangles rather than a shader: a handful of quads once
## a frame, and `ART-005`'s ink pass is the only shader this project has agreed
## to pay for.
func _draw_sides(screen: Vector2, left: bool, right: bool, spread: float,
		strength: float) -> void:
	var band: float = screen.x * spread * 0.5
	var thickness: float = band / float(STEPS)
	for step: int in range(STEPS):
		var through: float = float(step) / float(STEPS)
		# Squared, so the darkness gathers at the very edge instead of washing
		# evenly across the screen — which would read as fog rather than as a
		# frame closing in.
		var alpha: float = strength * (1.0 - through) * (1.0 - through)
		var colour := Color(SHADOW.r, SHADOW.g, SHADOW.b, alpha)
		if left:
			draw_rect(Rect2(Vector2(through * band, 0.0),
				Vector2(thickness, screen.y)), colour)
		if right:
			draw_rect(Rect2(Vector2(screen.x - through * band - thickness, 0.0),
				Vector2(thickness, screen.y)), colour)


## Top and bottom, for the standing wound only. A hit never draws these: a
## flash on all four edges is indistinguishable from the wound itself.
func _draw_caps(screen: Vector2, strength: float) -> void:
	var band: float = screen.y * 0.5
	var thickness: float = band / float(STEPS)
	for step: int in range(STEPS):
		var through: float = float(step) / float(STEPS)
		var alpha: float = strength * (1.0 - through) * (1.0 - through)
		var colour := Color(SHADOW.r, SHADOW.g, SHADOW.b, alpha)
		draw_rect(Rect2(Vector2(0.0, through * band),
			Vector2(screen.x, thickness)), colour)
		draw_rect(Rect2(Vector2(0.0, screen.y - through * band - thickness),
			Vector2(screen.x, thickness)), colour)


## A blow the guard took the weight of (`M3-T02`, `DES-009`).
##
## **Pale, and on every edge.** A wound darkens the side it came from, because
## that is the question a wound raises — *where is it?* A block raises a
## different one, *did that work?*, and the answer is not directional. Drawn
## unlike a wound on purpose: `DES-018` asks every audio channel for a visual
## twin, and a block that looked like a hit would be a twin that lies.
func _on_blocked(_stopped: float, _from: Node) -> void:
	_guard = 1.0


## The pale flare, over the same edges. Called from `_draw` after the wound so a
## block landing on a hurt player reads as both, in the order they happened.
func _draw_guard(screen: Vector2) -> void:
	if _guard <= 0.0:
		return
	var band: float = screen.x * ARC * 0.5
	var thickness: float = band / float(STEPS)
	for step: int in range(STEPS):
		var alpha: float = _guard * (1.0 - float(step) / float(STEPS)) * 0.22
		var colour := Color(GUARD.r, GUARD.g, GUARD.b, alpha)
		draw_rect(Rect2(Vector2(float(step) * thickness, 0.0),
			Vector2(thickness, screen.y)), colour)
		draw_rect(Rect2(Vector2(screen.x - float(step + 1) * thickness, 0.0),
			Vector2(thickness, screen.y)), colour)
