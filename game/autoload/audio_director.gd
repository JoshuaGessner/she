extends Node

## The adaptive score, and the single source both channels read (`M2-T03`).
##
## `DES-018`: *"**`AudioDirector` is a core system, not a budget line.**"* It is
## one of `TEC-001`'s six sanctioned autoloads and it is registered now rather
## than earlier because ADR-066 requires an autoload to have work before it
## exists — and until `M2-T02` produced a Hunt to score, it had none.
##
## ## Vertical remixing, not cues (ADR-035)
##
## **No alarms, no stingers.** Clamor is continuous, so it is carried by layers
## that enter and leave rather than by events that fire. One piece per biome,
## stems written to one tempo and key so any combination is musically valid
## (`ART-002`). A threshold signal would also fatigue badly across a 25-minute
## run and would make the Deep feel like a UI rather than a place.
##
## That choice is why this needs no middleware. Vertical remixing is layers
## playing in sync with independent volumes, which Godot does natively; the
## expensive thing middleware buys is *horizontal* re-sequencing — musically
## quantised jumps between sections — and `ART-002` explicitly does not want
## that (ADR-050: raw Godot first, FMOD when a musician is onboarded).
##
## ## The layers are blockout (ADR-046)
##
## Synthesised at boot: a bed, a drone, a pulse, a heartbeat, and the Hunter's
## reserved note. They are obviously placeholder and they are meant to be —
## what ships here is the **driver**, and `M2-T09` authors the Threshold theme
## that replaces them. Grey-box audio for the same reason `M1` had grey-box
## levels: the system has to be tunable before the content is worth making.
##
## **The reserved instrument is honoured even in blockout.** Its tone is used
## for the Gullsjúkr and nothing else, because `DES-018` says it must never be
## a false alarm, and a placeholder that broke that rule would teach the wrong
## reflex to anyone testing before `M2-T09`.

## Buses, in the order `DES-018` names them for the per-bus sliders `M4-T11`
## builds. Diegetic is separate and **never ducked** — `ART-002`: if score and
## a threat sound collide, the score loses, because a player must never miss a
## footstep because the music was swelling.
const BUSES: Array[String] = ["score", "ambience", "diegetic", "ui"]

## Seconds a layer takes to reach a new target volume ⟨tune⟩. `DES-018`:
## *"transitions are crossfades, not cuts — the player should feel the room
## getting worse, not be told."*
const CROSSFADE: float = 1.6
## The drop when the Hunter takes a bait is the one transition allowed to be
## fast. It is a designed beat and it has to read as *relief*, which a 1.6 s
## fade would blur into an accident.
const DUCK_CROSSFADE: float = 0.35

## Below this a layer is switched off rather than left inaudible, so a silent
## run costs no mixing at all.
const SILENCE_DB: float = -60.0

signal mixed(mix: HuntMix)

var mix: HuntMix = HuntMix.new()

var _players: Dictionary = {}
var _targets: Dictionary = {}
var _levels: Dictionary = {}
var _ready_to_mix: bool = false


func _ready() -> void:
	_build_buses()
	_build_layers()
	_ready_to_mix = true


## `AudioServer` buses, made in code rather than as a `default_bus_layout.tres`.
##
## Deliberate: the layout is *structural* rather than tunable — `ART-002`'s
## diegetic/score split settles every mix argument in advance, and a designer
## is never meant to reorganise it. `TEC-002`'s "data over code" rule is about
## things a designer would tune; the per-bus **volumes** are that, and they are
## `M4-T11`'s sliders.
func _build_buses() -> void:
	for name: String in BUSES:
		if AudioServer.get_bus_index(name) != -1:
			continue
		var index: int = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, name)
		AudioServer.set_bus_send(index, "Master")


func _process(delta: float) -> void:
	if not _ready_to_mix:
		return
	_read_world()
	_drive_layers(delta)
	mixed.emit(mix)


## Everything the mix knows, gathered from the world once per frame.
##
## By group, like every other cross-cutting system in the project, so no level
## has to wire audio up and nothing here reaches into an actor's internals.
##
## **Host and client both run this.** It is a readout, not a consequence — a
## client scoring its own screen from the replicated state it already has is
## correct, and routing the mix through the host would put a network hop
## between a footstep and the music noticing it.
func _read_world() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var tuning: TuningProfile = Config.tuning

	var player := tree.get_first_node_in_group("local_player") as Player
	if player == null:
		mix.clamor = 0.0
	else:
		mix.clamor = clampf(player.clamor.level / maxf(tuning.clamor_maximum, 0.001),
			0.0, 1.0)

	# The world's attention, and where from. `DES-019`'s guardrail is that the
	# Ear reports *attention*, never positions — so what is gathered here is
	# how alert the loudest-alerted actor is and the coarse direction it is in,
	# never how many there are or what they are.
	mix.alert = 0.0
	mix.bearing = NAN
	if player != null:
		for node: Node in tree.get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null:
				continue
			var weight: float = _alert_weight(enemy)
			if weight <= mix.alert:
				continue
			mix.alert = weight
			var offset: Vector3 = enemy.global_position - player.global_position
			mix.bearing = atan2(offset.x, offset.z)

	mix.hunter = 0.0
	mix.collecting = false
	for node: Node in tree.get_nodes_in_group(&"hunters"):
		var hunter := node as Gullsjukr
		if hunter == null:
			continue
		mix.hunter = maxf(mix.hunter, _hunter_weight(hunter))
		if hunter.state() == Gullsjukr.State.COLLECTING:
			mix.collecting = true
		# The Hunter outranks a merely alerted room for bearing: it is the one
		# thing on the floor whose direction the player must always be able to
		# answer (`DES-017`).
		if player != null and mix.hunter > 0.0:
			var toward: Vector3 = hunter.global_position - player.global_position
			mix.bearing = atan2(toward.x, toward.z)


## `DES-013`'s ladder as a scalar. Discrete underneath — the enemy really is in
## one of three states — but reported continuously, because ADR-035 rejects
## threshold signals and a readout that stepped in thirds would be one.
func _alert_weight(enemy: Enemy) -> float:
	match enemy.state():
		Enemy.State.ALERTED:
			return 1.0
		Enemy.State.SUSPICIOUS:
			return 0.45
		_:
			return 0.0


## `DES-017`'s ladder as a scalar, and **Collecting reads low on purpose**:
## that is the beat where everything drops away, so the number the score and
## the Ear both read has to fall with it.
func _hunter_weight(hunter: Gullsjukr) -> float:
	match hunter.state():
		Gullsjukr.State.SIGHTED:
			return 1.0
		Gullsjukr.State.COURSING:
			return 0.62
		Gullsjukr.State.COLLECTING:
			return 0.15
		Gullsjukr.State.LOST:
			return 0.4
		_:
			return 0.22


# ── the layers ────────────────────────────────────────────────────────────


## What each layer answers to, and at what level it sits when fully in.
##
## Read as a sentence: the bed is always there; the drone rides your own
## clamor; the pulse only enters once you are properly loud; the heartbeat is
## the room listening; the Hunter's note is the Hunter and nothing else.
const LAYERS: Dictionary = {
	"bed": {"hz": 0.0, "db": -26.0, "bus": "ambience"},
	"drone": {"hz": 55.0, "db": -20.0, "bus": "score"},
	"pulse": {"hz": 82.5, "db": -18.0, "bus": "score"},
	"heartbeat": {"hz": 110.0, "db": -17.0, "bus": "score"},
	"hunter": {"hz": 146.8, "db": -14.0, "bus": "score"},
}


func _build_layers() -> void:
	for name: String in LAYERS:
		var spec: Dictionary = LAYERS[name]
		var player := AudioStreamPlayer.new()
		player.name = "layer_%s" % name
		player.stream = _blockout_stream(float(spec["hz"]))
		player.bus = String(spec["bus"])
		player.volume_db = SILENCE_DB
		add_child(player)
		player.play()
		_players[name] = player
		_targets[name] = SILENCE_DB
		_levels[name] = SILENCE_DB


## One second of looping blockout tone (ADR-046).
##
## `hz` of zero makes the ambient bed: filtered noise rather than a pitch,
## because `ART-002` wants air and stone settling, and a pitched bed would be
## music pretending to be a room.
##
## Everything else is a sine with a little odd harmonic — enough that the
## layers are distinguishable from each other by ear, which is the only thing
## a blockout layer has to achieve. `M2-T09` replaces all of it.
func _blockout_stream(hz: float) -> AudioStreamWAV:
	var rate: int = 22050
	var frames: int = rate
	var data := PackedByteArray()
	data.resize(frames * 2)
	var noise := RandomNumberGenerator.new()
	# Seeded, so two runs sound identical and a probe comparing them is not
	# comparing noise (`TEC-001`: determinism where it matters).
	noise.seed = int(hz * 1000.0) + 17
	for frame: int in range(frames):
		var value: float = 0.0
		if hz <= 0.0:
			value = noise.randf_range(-0.35, 0.35)
		else:
			var phase: float = TAU * hz * (float(frame) / float(rate))
			value = sin(phase) * 0.7 + sin(phase * 3.0) * 0.12
		var sample: int = clampi(int(value * 32767.0), -32768, 32767)
		data.encode_s16(frame * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	# Looped, because these are beds and layers rather than cues. A layer that
	# stopped would be a stinger, which ADR-035 bans outright.
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


## Move every layer toward the level the mix asks for.
##
## Crossfades throughout, and the only fast one is the duck: `DES-018` makes
## the drop when the Hunter is baited a *designed beat*, and a beat that eased
## in over 1.6 s would read as the music losing its place rather than as relief.
func _drive_layers(delta: float) -> void:
	var duck: float = 0.12 if mix.collecting else 1.0
	_targets["bed"] = _db_for(1.0, "bed")
	_targets["drone"] = _db_for(smoothstep(0.02, 0.55, mix.clamor) * duck, "drone")
	_targets["pulse"] = _db_for(smoothstep(0.35, 0.9, mix.clamor) * duck, "pulse")
	_targets["heartbeat"] = _db_for(mix.alert * duck, "heartbeat")
	_targets["hunter"] = _db_for(mix.hunter * duck, "hunter")

	var rate: float = delta / (DUCK_CROSSFADE if mix.collecting else CROSSFADE)
	for name: String in _players:
		var current: float = float(_levels[name])
		var goal: float = float(_targets[name])
		# In decibels, so the fade is perceptually even rather than rushing the
		# quiet end the way a linear amplitude ramp does.
		var moved: float = move_toward(current, goal, absf(goal - current) * rate
			+ 60.0 * rate)
		_levels[name] = moved
		var player: AudioStreamPlayer = _players[name]
		player.volume_db = moved
		# Below the floor it is switched off rather than left running silently,
		# so a quiet run costs nothing to mix.
		var audible: bool = moved > SILENCE_DB + 0.5
		if audible and not player.playing:
			player.play()
		elif not audible and player.playing:
			player.stop()


func _db_for(weight: float, layer: String) -> float:
	if weight <= 0.001:
		return SILENCE_DB
	var full: float = float((LAYERS[layer] as Dictionary)["db"])
	return lerpf(SILENCE_DB, full, clampf(weight, 0.0, 1.0))


## What the score is currently saying, for the parity probe and the readout.
func layer_levels() -> Dictionary:
	var out: Dictionary = {}
	for name: String in _levels:
		out[name] = float(_levels[name])
	return out
