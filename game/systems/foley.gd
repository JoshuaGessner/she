class_name Foley
extends Object

## Blockout diegetic sound: the things the world does (ADR-046).
##
## `ART-002` is unambiguous about the priority — *"this is the most important
## sound work in the game, more important than the music"* — because the
## diegetic layer is **information the player dies without**, and the score is
## only a readout of how much trouble they are in. The score got built first
## anyway (`M2-T03`) because it was the risky half. This is the half that
## matters.
##
## ## The sound of your own greed
##
## The one thing `ART-002` asks for above everything: *"if a player can close
## their eyes and hear how rich they are, this system works."* So a pickup is
## not one sound — it is pitched and weighted by what you picked up, and the
## footstep under a full bag is a different sound from the footstep under an
## empty one. That relationship is the whole point and it is cheap to build,
## which is why it is here at blockout rather than waiting for a sound designer.
##
## ## Synthesised, seeded, and replaceable
##
## Everything is generated at boot: no files, no licensing, and identical every
## run so a probe comparing two of them is not comparing noise. `M4-T05` swaps
## these for recorded material, and nothing else changes — callers ask for
## `Foley.CLINK`, not for a file.
##
## Never networked. `TEC-004`: audio is client-side, driven by replicated
## state. **Never replicate sounds** — each peer plays its own from what it can
## already see.

const RATE: int = 22050

## Every sound the game can make, and what it means. Kept as one table so the
## question "what does this game sound like" has one answer, and so a sound
## added without a reason to exist is visible.
enum Sound {
	STEP,       # a footfall, pitched down by what you are carrying
	CLINK,      # something went into the bag
	THUMP,      # something came out of it
	SWING,      # a weapon through air
	HIT,        # a weapon into something
	HURT,       # that something was you
	NOTICED,    # an enemy just heard you — the most important cue here
	CHANNEL,    # a Waystone or a Shaft, working
	EMBER,      # a life on the floor
	CLICK,      # interface
}

static var _cache: Dictionary = {}


## A one-shot at a place in the world. 3D so it carries direction and distance,
## which is most of what makes a diegetic cue *information*.
static func at(where: Node3D, sound: Sound, pitch: float = 1.0,
		volume_db: float = 0.0) -> void:
	if where == null or not where.is_inside_tree():
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream_for(sound)
	player.bus = "diegetic"
	player.pitch_scale = clampf(pitch, 0.4, 2.4)
	player.volume_db = volume_db
	# Roughly the Deep's scale: audible across a room, gone across the floor.
	player.unit_size = 6.0
	player.max_distance = 28.0
	where.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


## A one-shot with no position — interface only. Anything the *world* does has
## a place it happened, and playing it flat throws that information away.
static func flat(host: Node, sound: Sound, pitch: float = 1.0) -> void:
	if host == null or not host.is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream_for(sound)
	player.bus = "ui"
	player.pitch_scale = clampf(pitch, 0.4, 2.4)
	host.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


static func stream_for(sound: Sound) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = _render(sound)
	return _cache[sound] as AudioStreamWAV


## The same sample, as a **loop**, for a sound that is a continuous presence
## rather than an event — the Shaft's idle hum is the only one today.
##
## Returns a duplicate, always. `stream_for` hands back the cached instance
## every caller shares, so setting `loop_mode` on it would turn every one-shot
## of that sound into a drone — the exact bug the comment below warns about,
## reached from the other direction. The frame arithmetic lives here because
## this is where the format is decided: 16-bit mono, so two bytes a frame.
static func looping_stream_for(sound: Sound) -> AudioStreamWAV:
	var stream: AudioStreamWAV = (stream_for(sound).duplicate()) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	return stream


static func _render(sound: Sound) -> AudioStreamWAV:
	var seconds: float = 0.32
	match sound:
		Sound.NOTICED: seconds = 0.55
		Sound.CHANNEL: seconds = 0.5
		Sound.EMBER: seconds = 0.9
		Sound.CLICK: seconds = 0.08
	var frames: int = int(float(RATE) * seconds)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for frame: int in range(frames):
		var at_second: float = float(frame) / float(RATE)
		var value: float = _sample(sound, at_second, seconds)
		data.encode_s16(frame * 2, clampi(int(value * 32767.0), -32768, 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	# One-shots, never looped. A looping footstep is a bug you hear once and
	# then cannot stop hearing.
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream


static func _sample(sound: Sound, at_second: float, seconds: float) -> float:
	var progress: float = at_second / seconds
	match sound:
		Sound.STEP:
			# Body weight into stone: a short noisy thud with no pitch to it.
			return _noise(at_second) * exp(-at_second * 34.0) * 0.6 \
				+ sin(TAU * 78.0 * at_second) * exp(-at_second * 26.0) * 0.35
		Sound.CLINK:
			# Metal on metal. Two inharmonic partials, because a single sine
			# reads as a beep and a beep is a menu, not a coin.
			return (sin(TAU * 2100.0 * at_second) * 0.5
				+ sin(TAU * 3170.0 * at_second) * 0.3) \
				* exp(-at_second * 19.0)
		Sound.THUMP:
			return (sin(TAU * 140.0 * at_second) * 0.6
				+ _noise(at_second) * 0.25) * exp(-at_second * 15.0)
		Sound.SWING:
			# Air: filtered noise that rises and falls across the arc, so the
			# sound has a *direction in time* the way a swing does.
			var arc: float = sin(PI * clampf(progress, 0.0, 1.0))
			return _noise(at_second * 3.0) * arc * 0.45
		Sound.HIT:
			return (_noise(at_second) * 0.5
				+ sin(TAU * 190.0 * at_second) * 0.45) * exp(-at_second * 22.0)
		Sound.HURT:
			# Lower and longer than a hit, and it lands on *you*.
			return (sin(TAU * 96.0 * at_second) * 0.55
				+ _noise(at_second) * 0.3) * exp(-at_second * 9.0)
		Sound.NOTICED:
			# **The most important cue in this file.** `DES-005` requires the
			# player to be able to explain their death in one sentence, and
			# "something heard me and I kept going" is only available if being
			# heard is audible. A rising two-note figure — unmistakably a
			# reaction, not ambience.
			var step: float = 1.0 if progress > 0.45 else 0.0
			var note: float = 330.0 + 110.0 * step
			return sin(TAU * note * at_second) * 0.4 \
				* exp(-fmod(at_second, 0.25) * 8.0)
		Sound.CHANNEL:
			# Something working: a held tone that climbs, so holding it feels
			# like progress rather than a stuck key.
			return sin(TAU * (220.0 + 160.0 * progress) * at_second) * 0.3 \
				* sin(PI * progress)
		Sound.EMBER:
			# A life, going out. Falling, and slower than anything else here.
			return sin(TAU * (300.0 - 170.0 * progress) * at_second) * 0.42 \
				* exp(-at_second * 2.2)
		Sound.CLICK:
			return _noise(at_second) * exp(-at_second * 90.0) * 0.3
	return 0.0


## Deterministic value noise. Seeded by position rather than by a generator, so
## the same sound is byte-identical every run and across peers.
static func _noise(at_second: float) -> float:
	var seeded: float = sin(at_second * 15731.0 + 7.0) * 43758.5453
	return (seeded - floor(seeded)) * 2.0 - 1.0
