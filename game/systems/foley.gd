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
## ## Recorded where the world makes the sound (ADR-326)
##
## The things a body and a blow do — footfalls, coin, a thing set down, a knock
## on stone, a blow on mail or into flesh, a blow on you — and the interface's
## click and the party's ping are **recorded**: CC0 field recordings cut by
## `source_art/audio/build_foley.py` into several takes each, played in turn so
## the same action twice is never the same sound twice. Each take is set to the
## loudness of the cue it replaced, so every `volume_db` tuned against those
## cues still holds.
##
## A swing through air is recorded too (ADR-327); the camp's fire is a recorded
## loop, and the Hunter's tread a loop composed from recorded coin and weight.
## a barrow's slab grinding open is recorded stone. The rest — being noticed, a
## Waystone working, an ember going out — are **synthesised at boot**, as
## everything was at blockout: designed cues and loops with no recording that
## says them better. One source for each sound, never both. Callers ask for
## `Foley.CLINK`, not for a file, so either can change without them.
##
## Never networked. `TEC-004`: audio is client-side, driven by replicated
## state. **Never replicate sounds** — each peer plays its own from what it can
## already see.

const RATE: int = 22050

## Sound -> how many recorded takes `build_foley.py` made of it, at
## `res://audio/foley/<sound>_<nn>.ogg`. A sound not here is synthesised.
const RECORDED: Dictionary = {
	Sound.STEP: 5, Sound.CLINK: 2, Sound.THUMP: 5, Sound.HIT: 5, Sound.HURT: 5,
	Sound.CLICK: 5, Sound.PING: 2, Sound.CLANG: 5, Sound.CRUNCH: 5, Sound.COIN: 4,
	Sound.SWING: 5, Sound.GRIND: 3,
}
const TAKES: String = "res://audio/foley/%s_%02d.ogg"
## Presences rather than events, recorded as one seamless loop each at
## `res://audio/foley/<sound>_loop.ogg`.
const LOOPED: Array = [Sound.CRACKLE, Sound.STALK]
const LOOP: String = "res://audio/foley/%s_loop.ogg"

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
	GRIND,      # stone dragged over stone: a barrow opening (ADR-242)
	PING,       # a mark placed for the party (ADR-244) — interface, never world
	STALK,      # the Hunter's own weight, moving (ADR-249) — never the score's note
	CLANG,      # a blow on mail or plate (ADR-279) — the metal half of an impact
	CRUNCH,     # a blow into flesh (ADR-279) — the body half of an impact
	CRACKLE,    # the camp's fire (ADR-287), looped — a world sound, never the score
	COIN,       # coin shifting in the bag at a step (ADR-326) — how rich you sound
}

## How far a one-shot carries by default: roughly the Deep's scale, audible
## across a room and gone across the floor.
const REACH: float = 28.0

static var _cache: Dictionary = {}
## Sound -> its takes, loaded once; and which take each plays next. In turn
## rather than at random, so a run is the same sequence every time — `TEC-004`
## keeps sound off the wire, so no two peers need agree on it.
static var _takes: Dictionary = {}
static var _turn: Dictionary = {}
## How many of each sound this peer has played in the world, by `Sound` —
## counted so `--coop-probe` can ask what a client *heard*, which is the
## question ADR-311 was about and the one no number on the wire answers.
static var played: Dictionary = {}


## A one-shot at a place in the world. 3D so it carries direction and distance,
## which is most of what makes a diegetic cue *information*.
## `reach` is how far it carries; only a sound meant to be heard across the
## floor passes more than `REACH`.
static func at(where: Node3D, sound: Sound, pitch: float = 1.0,
		volume_db: float = 0.0, reach: float = REACH) -> void:
	if where == null or not where.is_inside_tree():
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream_for(sound)
	player.bus = "diegetic"
	player.pitch_scale = clampf(pitch, 0.4, 2.4)
	player.volume_db = volume_db
	player.unit_size = 6.0 * reach / REACH
	player.max_distance = reach
	where.add_child(player)
	played[sound] = int(played.get(sound, 0)) + 1
	# Measured before it is heard, not on the next tick (`M4-T12`).
	Acoustics.heard(player)
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


static func stream_for(sound: Sound) -> AudioStream:
	# A presence played once — the Hunter's heave is one tread of its loop —
	# is the loop's recording, not looped.
	if LOOPED.has(sound):
		return _looped(sound, false)
	if RECORDED.has(sound):
		var all: Array = _recorded(sound)
		if all.is_empty():
			return null
		var next: int = int(_turn.get(sound, 0))
		_turn[sound] = next + 1
		return all[next % all.size()] as AudioStream
	return _synthesised(sound)


## Is `stream` one of `sound`'s — any take, loop or render of it. For a probe
## that counts a sound by what was played, now that one sound is several
## streams and a loop is a fresh copy each time: every stream this file hands
## out carries the sound it is.
static func is_sound(stream: AudioStream, sound: Sound) -> bool:
	return stream != null and int(stream.get_meta(&"foley", -1)) == int(sound)


## A recorded loop, as its own copy: looping, or played once through.
##
## A deep copy: its packets become this player's own rather than the cached
## file's, so a player outliving the tree at quit holds nothing with a path —
## which the engine reports as a resource still in use.
static func _looped(sound: Sound, looping: bool) -> AudioStreamOggVorbis:
	var path: String = LOOP % (Sound.keys()[sound] as String).to_lower()
	var loaded := load(path) as AudioStreamOggVorbis
	if loaded == null:
		push_error("Foley: no loop at %s" % path)
		return null
	var recorded := loaded.duplicate(true) as AudioStreamOggVorbis
	recorded.loop = looping
	recorded.set_meta(&"foley", sound)
	return recorded


## Drop every loaded take and synthesised cue. Called as the game closes.
static func forget() -> void:
	_takes.clear()
	_cache.clear()
	_turn.clear()


static func _recorded(sound: Sound) -> Array:
	if not _takes.has(sound):
		var name: String = (Sound.keys()[sound] as String).to_lower()
		var all: Array = []
		for take: int in int(RECORDED[sound]):
			# A deep copy, kept: a voice holds this, and any voice still alive
			# when the game closes would otherwise hold the file's own packets,
			# which the engine reports as a resource still in use — an exit
			# error, where an unpathed copy is at most a leak warning.
			# A take missing from the pack is a fault to report, not a crash
			# on the first footstep: the sound goes quiet and the log says why.
			var loaded := load(TAKES % [name, take]) as AudioStream
			if loaded == null:
				push_error("Foley: no take at %s" % (TAKES % [name, take]))
				continue
			var copy := loaded.duplicate(true) as AudioStream
			copy.set_meta(&"foley", sound)
			all.append(copy)
		_takes[sound] = all
	return _takes[sound] as Array


static func _synthesised(sound: Sound) -> AudioStreamWAV:
	# Only the designed cues have a render; anything recorded asked here would
	# come back as silence, which nobody would hear go missing.
	assert(not RECORDED.has(sound) and not LOOPED.has(sound),
		"Foley: %s is recorded" % Sound.keys()[sound])
	if not _cache.has(sound):
		var rendered: AudioStreamWAV = _render(sound)
		rendered.set_meta(&"foley", sound)
		_cache[sound] = rendered
	return _cache[sound] as AudioStreamWAV


## The same sample, as a **loop**, for a sound that is a continuous presence
## rather than an event — the Shaft's idle hum is the only one today.
##
## Returns a duplicate, always. `stream_for` hands back the cached instance
## every caller shares, so setting `loop_mode` on it would turn every one-shot
## of that sound into a drone — the exact bug the comment below warns about,
## reached from the other direction. The frame arithmetic lives here because
## this is where the format is decided: 16-bit mono, so two bytes a frame.
static func looping_stream_for(sound: Sound) -> AudioStream:
	# A recorded one-shot looped would be the footstep this file's header
	# warns of; only a sound recorded *as* a loop loops.
	assert(not RECORDED.has(sound), "Foley: %s is a recorded one-shot" % Sound.keys()[sound])
	if LOOPED.has(sound):
		return _looped(sound, true)
	var stream: AudioStreamWAV = (_synthesised(sound).duplicate()) as AudioStreamWAV
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
	# Only the designed cues are rendered here (ADR-326, ADR-327); everything
	# the world does is recorded, and `build_foley.py` keeps the formulas
	# those recordings were levelled against.
	var progress: float = at_second / seconds
	match sound:
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
	return 0.0

