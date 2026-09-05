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
	# The player's volumes, now that there are buses to set them on. `Config`
	# loads the preferences a frame earlier and cannot apply the audio half,
	# because these buses did not exist yet.
	Settings.apply()
	# No piece until a level says where it is. A director that guessed would
	# guess the Deep, and the first thing a new player hears would be the Hunt
	# playing over a campfire.
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
	# **Four rungs, four levels** (`M4-T16`, ADR-196). ALERTED used to return
	# 1.0 and so sat at the top of a scale `DES-013` says has a rung above it —
	# which meant the failure state had nowhere to show. Rescaling here rather
	# than adding a channel is deliberate: `HuntMix.alert` is documented as the
	# ladder *flattened to a scalar*, `DES-019` rule 5 allows exactly one
	# element to carry urgency, and `--ear-probe` fails any channel without a
	# visual twin. The Ear was already built for this.
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
		Enemy.State.SWARM:
			return 1.0
		Enemy.State.CALLING:
			return 0.85
		Enemy.State.ALERTED:
			return 0.70
		Enemy.State.SUSPICIOUS:
			return 0.35
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


## **The reserved instrument** (`ART-002`, `ART-003`).
##
## > *"One instrument is reserved for the Hunter and appears nowhere else in
## > the game. Ever. Not in the Threshold, not as texture, not 'just once'
## > somewhere atmospheric. When the player hears it, it is always true."*
##
## A rule that strong is worth making structural rather than remembering. Every
## layer below declares a `voice`, exactly one layer in the whole game may use
## this one, and `--threshold-probe` fails if a second ever appears. It is the
## kind of rule that gets broken by someone reaching for a nice sound at 2am,
## and by then the false alarm has already cost a player their run.
const RESERVED_VOICE: String = "bowed"

## Where the player is standing, and therefore what is playing.
##
## `ART-002`'s **three sonic worlds** — the Deep, the Threshold, her Chamber —
## are three different pieces, not one piece with the lights dimmed. Before
## `M2-T09` there was one flat layer table, which meant the camp and her
## Chamber were both scored by the Hunt: the safest and the strangest places in
## the game playing music written to say *how much trouble you are in*.
##
## Each layer: `voice` (how it is made), `hz` (its pitch, 0 for air), `db` (the
## level it sits at when fully in), `bus`.
##
## Everything is blockout (ADR-046) and `M2-T09` owns the *architecture* rather
## than the notes — `ART-002` says outright to consider commissioning the score,
## and this is what a composer is handed: the stem layout, one key, one tempo,
## every layer valid against every other.
const PIECES: Dictionary = {
	# ── The Deep ──────────────────────────────────────────────────────────
	# Sparse, cold, mostly diegetic. Music arrives as pressure. Read as a
	# sentence: the bed is always there; the drone rides your own clamor; the
	# pulse enters once you are properly loud; the heartbeat is the room
	# listening; the Hunter's note is the Hunter and nothing else.
	"deep": {
		"bed": {"voice": "air", "hz": 0.0, "db": -26.0, "bus": "ambience"},
		"drone": {"voice": "held", "hz": 55.0, "db": -20.0, "bus": "score"},
		"pulse": {"voice": "throb", "hz": 82.5, "db": -18.0, "bus": "score"},
		"heartbeat": {"voice": "throb", "hz": 110.0, "db": -17.0, "bus": "score"},
		"hunter": {"voice": "bowed", "hz": 146.8, "db": -14.0, "bus": "score"},
	},
	# ── The Threshold ─────────────────────────────────────────────────────
	# **The only safe sound in the game**, and `ART-003` calls it the most
	# important piece of music in it: *"warm, acoustic, sad, and small… if a
	# player hums anything from this game a year later, it should be this."*
	#
	# So it is the one piece with an actual tune rather than a texture. The
	# hearth and the drone are always in — safety is not something you have to
	# earn back each time you arrive — and the arrangement *fills out* as the
	# camp does (ADR-050), which is the whole reason this needed a driver and
	# not a looping file.
	"threshold": {
		"hearth": {"voice": "air", "hz": 0.0, "db": -22.0, "bus": "ambience"},
		"warmth": {"voice": "held", "hz": 73.4, "db": -19.0, "bus": "score"},
		"theme": {"voice": "plucked", "hz": 293.66, "db": -13.0, "bus": "score"},
		"company": {"voice": "plucked", "hz": 146.83, "db": -17.0, "bus": "score"},
	},
	# ── Her Chamber ───────────────────────────────────────────────────────
	# *"Enormous and close. Deep room tone, a sense of vast air, and beneath it
	# something slow and breathing."* Not a threat and not a comfort.
	#
	# Built here rather than deferred because `M2-T09` is what made a place
	# able to have its own sound — and leaving the Chamber on the Deep's piece
	# would have scored the quietest room in the game with the Hunt.
	"chamber": {
		"air": {"voice": "air", "hz": 0.0, "db": -20.0, "bus": "ambience"},
		"vast": {"voice": "held", "hz": 36.7, "db": -16.0, "bus": "score"},
		"breathing": {"voice": "throb", "hz": 49.0, "db": -21.0, "bus": "score"},
	},
}

## D natural minor, which is what the pitches above are drawn from. `ART-003`:
## *"all layers of a piece share one tempo and one key, so any combination is
## musically valid."* A constraint on the composer, so it is a constraint here.
const ROOT_HZ: float = 146.83
const PHRASE_SECONDS: float = 8.0

## The Threshold's tune, as a descending figure that resolves and then asks
## again — small, and sad without being funereal. Scale degrees in D Aeolian,
## as multiples of the root; `-1.0` is a rest, which a tune needs more than it
## needs another note.
const THEME_PHRASE: Array[float] = [
	3.0, 2.5, 2.0, 1.5, -1.0, 2.0, 1.5, 1.0,
]
## The second voice, underneath and slower. This is the layer that arrives as
## the camp fills: somebody else is playing along.
const COMPANY_PHRASE: Array[float] = [
	1.0, -1.0, 0.75, -1.0, 1.0, -1.0, 1.5, -1.0,
]

var _place: String = ""


## Move to a place, and with it a piece. Called by the level in `_ready`.
##
## Idempotent, so a level re-entering the same place does not restart its own
## music underneath the player.
func enter(named: String) -> void:
	if named == _place:
		return
	if not PIECES.has(named):
		push_error("AudioDirector: no piece for place '%s'" % named)
		return
	_place = named
	_build_layers()


func place() -> String:
	return _place


## Tear down the old piece and stand up the new one.
func _build_layers() -> void:
	for name: String in _players:
		(_players[name] as AudioStreamPlayer).queue_free()
	_players = {}
	_targets = {}
	_levels = {}
	for name: String in layers():
		var spec: Dictionary = layers()[name]
		var player := AudioStreamPlayer.new()
		player.name = "layer_%s" % name
		player.stream = _voice_stream(spec)
		player.bus = String(spec["bus"])
		player.volume_db = SILENCE_DB
		add_child(player)
		_players[name] = player
		_targets[name] = SILENCE_DB
		_levels[name] = SILENCE_DB


## The layer table for whatever is playing.
func layers() -> Dictionary:
	return PIECES.get(_place, {}) as Dictionary


## Blockout audio for one layer (ADR-046).
##
## Four voices, each recognisably different by ear — which is the whole job of
## a blockout layer, and also what lets `--threshold-probe` assert that the
## reserved one is used once.
func _voice_stream(spec: Dictionary) -> AudioStreamWAV:
	var voice: String = String(spec["voice"])
	var hz: float = float(spec["hz"])
	match voice:
		"air":
			return _render(PHRASE_SECONDS, _air_at, hz)
		"held":
			return _render(PHRASE_SECONDS, _held_at, hz)
		"throb":
			return _render(PHRASE_SECONDS, _throb_at, hz)
		"bowed":
			return _render(PHRASE_SECONDS, _bowed_at, hz)
		"plucked":
			return _render(PHRASE_SECONDS, _plucked_at, hz)
	push_error("AudioDirector: unknown voice '%s'" % voice)
	return _render(PHRASE_SECONDS, _held_at, hz)


const MIX_RATE: int = 22050

## Sample a voice function across a whole phrase and pack it as a looping WAV.
##
## Seeded and deterministic, so two runs sound identical and a probe comparing
## them is not comparing noise (`TEC-001`).
func _render(seconds: float, voice: Callable, hz: float) -> AudioStreamWAV:
	var frames: int = int(float(MIX_RATE) * seconds)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for frame: int in range(frames):
		var at: float = float(frame) / float(MIX_RATE)
		var value: float = voice.call(at, hz, seconds) as float
		data.encode_s16(frame * 2, clampi(int(value * 32767.0), -32768, 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	# Looped, because these are beds and layers rather than cues. A layer that
	# stopped would be a stinger, which ADR-035 bans outright.
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


## Air and stone settling. Noise rather than a pitch, because a pitched bed is
## music pretending to be a room.
func _air_at(at: float, _hz: float, seconds: float) -> float:
	var wobble: float = 0.75 + 0.25 * sin(TAU * at / seconds)
	return _noise_at(at) * 0.3 * wobble


## A held note with a little odd harmonic. The Deep's cold drone and the
## Threshold's warm one are the same voice at different pitches, which is
## `ART-003`'s point about one key: warmth is register, not a different scale.
func _held_at(at: float, hz: float, _seconds: float) -> float:
	var phase: float = TAU * hz * at
	return sin(phase) * 0.7 + sin(phase * 3.0) * 0.12


## A slow swell rather than a beat — `ART-002` bans stingers, so the pulse
## breathes instead of hitting.
func _throb_at(at: float, hz: float, _seconds: float) -> float:
	var swell: float = 0.35 + 0.65 * pow(0.5 + 0.5 * sin(TAU * at * 0.5), 2.0)
	return (sin(TAU * hz * at) * 0.6 + sin(TAU * hz * 2.0 * at) * 0.15) * swell


## **The reserved voice.** Bowed: slow attack, rich in odd harmonics, and a
## vibrato that makes it unmistakably an instrument somebody is playing rather
## than a tone the game is emitting. `ART-003` proposes tagelharpa or jouhikko
## and leaves the choice open; what it does not leave open is using it twice.
func _bowed_at(at: float, hz: float, seconds: float) -> float:
	var bow: float = smoothstep(0.0, seconds * 0.35, at)
	var vibrato: float = 1.0 + 0.004 * sin(TAU * 5.5 * at)
	var phase: float = TAU * hz * vibrato * at
	var body: float = (sin(phase) * 0.5 + sin(phase * 2.0) * 0.22
		+ sin(phase * 3.0) * 0.16 + sin(phase * 5.0) * 0.08)
	return body * bow


## Plucked and decaying — a kantele, and the only voice in the game that plays
## a *tune*. Each note is struck and left to ring, so the phrase loops without
## a seam: the last note has decayed to nothing before the first returns.
func _plucked_at(at: float, hz: float, seconds: float) -> float:
	var phrase: Array[float] = (THEME_PHRASE if hz >= ROOT_HZ * 1.5
		else COMPANY_PHRASE)
	var beat: float = seconds / float(phrase.size())
	var index: int = clampi(int(at / beat), 0, phrase.size() - 1)
	var degree: float = phrase[index]
	if degree < 0.0:
		return 0.0
	var since: float = at - float(index) * beat
	var decay: float = exp(-since * 3.2)
	var note: float = hz * degree
	var phase: float = TAU * note * since
	return (sin(phase) * 0.6 + sin(phase * 2.0) * 0.2
		+ sin(phase * 3.0) * 0.08) * decay


## Deterministic value noise, so the ambient bed is identical run to run.
func _noise_at(at: float) -> float:
	var seeded: float = sin(at * 12543.7 + 17.0) * 43758.5453
	return (seeded - floor(seeded)) * 2.0 - 1.0


## Move every layer toward the level the mix asks for.
##
## Crossfades throughout, and the only fast one is the duck: `DES-018` makes
## the drop when the Hunter is baited a *designed beat*, and a beat that eased
## in over 1.6 s would read as the music losing its place rather than as relief.
func _drive_layers(delta: float) -> void:
	var duck: float = 1.0
	match _place:
		"deep":
			duck = 0.12 if mix.collecting else 1.0
			_targets["bed"] = _db_for(1.0, "bed")
			_targets["drone"] = _db_for(
				smoothstep(0.02, 0.55, mix.clamor) * duck, "drone")
			_targets["pulse"] = _db_for(
				smoothstep(0.35, 0.9, mix.clamor) * duck, "pulse")
			_targets["heartbeat"] = _db_for(mix.alert * duck, "heartbeat")
			_targets["hunter"] = _db_for(mix.hunter * duck, "hunter")
		"threshold":
			_drive_threshold()
		"chamber":
			_drive_chamber()

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


## **A fuller camp gets a fuller arrangement** (ADR-050).
##
## The hearth and the warmth are unconditional. `ART-002` calls the Threshold
## *the only safe sound in the game*, and safety that faded in over two seconds
## every time you walked through the door would be a worse lie than no music.
##
## What grows is the *company*. `DES-010` wants the camp to fill in over the
## first hour rather than arrive complete, and ADR-050 made that audible as
## well as visible: the second instrument comes in as the place becomes
## somewhere people live. Descents are the only camp state that exists yet —
## the contract board, the Forge and the Quartermaster are all absent rather
## than stubbed — so descents are what it reads. Everything `M3` and `M4` add
## to the camp adds to this same number; nothing here needs to change for it.
const CAMP_FULL_AT: float = 6.0

func _drive_threshold() -> void:
	_targets["hearth"] = _db_for(1.0, "hearth")
	_targets["warmth"] = _db_for(1.0, "warmth")
	_targets["theme"] = _db_for(1.0, "theme")
	var settled: float = clampf(
		float(GameState.descents - 1) / CAMP_FULL_AT, 0.0, 1.0)
	_targets["company"] = _db_for(settled, "company")


## Her Chamber: always on, and it does not react. Nothing that happens in here
## is a threat or a reward — you are standing in a room with her, and the room
## sounds the same whether you brought a fortune or nothing at all. The hoard
## is the visible readout (`DES-014`); making the *sound* congratulate you as
## well would turn a felt presence into a scoreboard.
func _drive_chamber() -> void:
	for name: String in _players:
		_targets[name] = _db_for(1.0, name)


func _db_for(weight: float, layer: String) -> float:
	if weight <= 0.001:
		return SILENCE_DB
	var full: float = float((layers()[layer] as Dictionary)["db"])
	return lerpf(SILENCE_DB, full, clampf(weight, 0.0, 1.0))


## What the score is currently saying, for the parity probe and the readout.
func layer_levels() -> Dictionary:
	var out: Dictionary = {}
	for name: String in _levels:
		out[name] = float(_levels[name])
	return out
