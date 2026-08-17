class_name Settings
extends Object

## What the player has chosen, as opposed to what the designer has tuned.
##
## `TuningProfile` holds design values — how fast you walk, what a swing costs.
## These are the other kind: preferences that belong to whoever is sitting at
## the machine and must survive quitting. Keeping them apart matters, because a
## player raising their mouse sensitivity must not be editing game balance, and
## a balance pass must not silently reset somebody's audio.
##
## Written to `user://settings.cfg` with `ConfigFile`. **This is not `TEC-003`'s
## save system** and does not pretend to be: no run state, no progression, no
## migration path, nothing that death or a schema change touches. `M4-T06`
## builds the versioned save; preferences are a different file with different
## rules, and conflating them is how settings end up wiped by a save migration.
##
## Not an autoload — `TEC-001` budgets six and names them. Static state on a
## `class_name`, loaded once at boot by `Config`, costs no budget.
##
## Every value here is **applied**, not merely stored. `DES-018` asks for
## independent per-bus volumes; the full accessibility suite is `M4-T11` and is
## absent rather than half-present.

const PATH: String = "user://settings.cfg"

## The buses `AudioDirector` builds, plus Master. Sliders are per-bus because
## `DES-018` wants a player who cannot hear the score to still hear footsteps.
const VOLUME_BUSES: Array[String] = [
	"Master", "score", "ambience", "diegetic", "ui",
]

static var volumes: Dictionary = {}
static var mouse_sensitivity: float = 1.0
static var invert_look: bool = false
static var fullscreen: bool = false

static var _loaded: bool = false


static func load_once() -> void:
	if _loaded:
		return
	_loaded = true
	for bus: String in VOLUME_BUSES:
		volumes[bus] = 1.0

	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for bus: String in VOLUME_BUSES:
			volumes[bus] = clampf(
				float(file.get_value("audio", bus, 1.0)), 0.0, 1.0)
		mouse_sensitivity = clampf(
			float(file.get_value("input", "mouse_sensitivity", 1.0)), 0.1, 4.0)
		invert_look = bool(file.get_value("input", "invert_look", false))
		fullscreen = bool(file.get_value("video", "fullscreen", false))
	apply()


static func save() -> void:
	var file := ConfigFile.new()
	for bus: String in VOLUME_BUSES:
		file.set_value("audio", bus, float(volumes[bus]))
	file.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("input", "invert_look", invert_look)
	file.set_value("video", "fullscreen", fullscreen)
	file.save(PATH)


## Push every value at the thing that honours it. Called on load and on every
## change, so a slider is audible while you are still dragging it — a settings
## screen you have to close to hear is one you cannot actually set by ear.
static func apply() -> void:
	for bus: String in VOLUME_BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		var level: float = float(volumes[bus])
		# Silence is a real choice and `linear_to_db(0)` is negative infinity,
		# which some drivers dislike more than a large finite number.
		AudioServer.set_bus_volume_db(index, -80.0 if level <= 0.001
			else linear_to_db(level))
		AudioServer.set_bus_mute(index, level <= 0.001)

	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN \
		if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## The multiplier the player's look applies on top of `TuningProfile`. A
## multiplier rather than a replacement, so the tuned value stays the baseline
## and "default" always means what the designer chose.
static func look_scale() -> float:
	return mouse_sensitivity


static func pitch_sign() -> float:
	return -1.0 if invert_look else 1.0
