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
## migration path, nothing that death or a schema change touches. `M3-T06`
## builds the versioned save; preferences are a different file with different
## rules, and conflating them is how settings end up wiped by a save migration.
##
## Not an autoload — `TEC-001` budgets six and names them. Static state on a
## `class_name`, loaded once at boot by `Config`, costs no budget.
##
## Every value here is **applied**, not merely stored. `DES-018` asks for
## independent per-bus volumes; the full accessibility suite is `M4-T11` and is
## absent rather than half-present.

## A variable only so the probes can point it elsewhere (ADR-245), on
## `SaveFile`'s pattern: a check that rebinds keys must never rebind a player's.
static var PATH: String = "user://settings.cfg"
## Where the probes write, named rather than read back from `PATH`: a probe
## that wrote to `PATH` once wrote to a player's file (see `read_again`).
const PROBE_PATH: String = "user://settings.probe.cfg"

## The buses `AudioDirector` builds, plus Master. Sliders are per-bus because
## `DES-018` wants a player who cannot hear the score to still hear footsteps.
const VOLUME_BUSES: Array[String] = [
	"Master", "score", "ambience", "diegetic", "ui",
]

static var volumes: Dictionary = {}
static var mouse_sensitivity: float = 1.0
static var invert_look: bool = false
static var fullscreen: bool = false
## **What the player rebound** (`M4-T06`, ADR-245): action → `{keys, pad}`,
## each a list of `Bindings.describe` rows. Only what was changed, so a default
## moved by a later build still moves for every verb nobody touched.
static var bindings: Dictionary = {}

static var _loaded: bool = false


## Send every read and write to a scratch file for the rest of this process
## (ADR-245). The probes that rebind call it; the game never does.
static func use_a_scratch_file() -> void:
	PATH = PROBE_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


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
		# A file from before rebinding has no section, which is true of it.
		if file.has_section("bindings"):
			for action: String in file.get_section_keys("bindings"):
				var kept: Variant = file.get_value("bindings", action, {})
				if typeof(kept) == TYPE_DICTIONARY:
					bindings[action] = kept
	apply()
	Bindings.apply_overrides()


## Read the file again as a fresh boot would (ADR-245) — for the probe that asks
## whether a rebind survives quitting. **Not `reload`**: that name is already
## `Script.reload()`, which `Settings.reload()` reaches first — it re-ran every
## static initialiser, `PATH` included, and the probe's next write landed on
## the player's own settings.
static func read_again() -> void:
	_loaded = false
	bindings.clear()
	load_once()


static func save() -> void:
	var file := ConfigFile.new()
	for bus: String in VOLUME_BUSES:
		file.set_value("audio", bus, float(volumes[bus]))
	file.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	file.set_value("input", "invert_look", invert_look)
	file.set_value("video", "fullscreen", fullscreen)
	for action: String in bindings:
		file.set_value("bindings", action, bindings[action])
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
