class_name Bindings
extends Object

## **Rebinding** (`M4-T06`, ADR-245) — every action, on both devices, by the
## developer's call.
##
## `ControlsScreen` has always been generated from `InputMap`, so a binding
## changed here is a binding every prompt in the game already says: the rules
## live in this file and the display needed nothing new. What a player changes
## is kept in `Settings` as an **override** per action and device — never a copy
## of the whole map — so a build that moves a default still moves it for anyone
## who never touched that verb.
##
## ## A clash swaps
##
## Taking an input another action holds hands that action the one you gave up,
## which is the rule most rebinding screens settle on because it never leaves a
## verb unbound — ADR-075 requires both devices to reach everything, and a pad
## with no free button has nowhere else to put it. **An input two actions share
## by design moves as a pair** (`SHARED`): their contexts never meet, so they
## may share whatever they are given. Anything else that would end up sharing
## is refused, with the reason.

enum Device { KEYS, PAD }

## Inputs two actions may share because their contexts never meet — the game's
## copy of `tools/bind_gamepad.py`'s `SHARED_OK`, which `check_project.py`
## holds it to.
const SHARED: Array = [
	["block", "rotate_item"],
	["verb", "use_item"],
	["debug_ink", "debug_overlays"],
	["jump", "ui_accept"],
	["debug_reset", "ui_cancel"],
]
## Never a player's to move: the debug keys are not the game (the controls
## screen hides them for the same reason).
const FIXED: Array[String] = ["debug_reset", "debug_overlays", "debug_ink"]
## The way to the menu on each device, which no verb may take: a verb on it
## would open the menu every time it was used.
const RESERVED_KEYS: Array[Key] = [KEY_ESCAPE]
const RESERVED_BUTTONS: Array[JoyButton] = [JOY_BUTTON_START]
const DEVICE_NAMES: Array[String] = ["keys", "pad"]

## What the last rebind did to anything else, for the screen to say.
static var last_note: String = ""


## Every action a player may rebind, in `InputMap` order.
static func rebindable() -> PackedStringArray:
	var out := PackedStringArray()
	for action: StringName in InputMap.get_actions():
		var name: String = String(action)
		if name.begins_with("ui_") or FIXED.has(name):
			continue
		out.append(name)
	return out


## Every action in the map, the fixed ones included.
static func _mapped() -> PackedStringArray:
	var out := PackedStringArray()
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			out.append(String(action))
	return out


## Which device an event belongs to, or -1 for anything a binding cannot be.
static func device_of(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return Device.KEYS
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Device.PAD
	return -1


## An event as something `ConfigFile` can keep and compare.
static func describe(event: InputEvent) -> Dictionary:
	var key := event as InputEventKey
	if key != null:
		var code: int = key.physical_keycode if key.physical_keycode != KEY_NONE \
			else key.keycode
		return {"kind": "key", "code": int(code)}
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return {"kind": "mouse", "button": int(mouse.button_index)}
	var button := event as InputEventJoypadButton
	if button != null:
		return {"kind": "button", "button": int(button.button_index)}
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return {"kind": "axis", "axis": int(motion.axis),
			"sign": 1 if motion.axis_value >= 0.0 else -1}
	return {}


## The event a description stands for, on every device of its kind.
static func build(row: Dictionary) -> InputEvent:
	match String(row.get("kind", "")):
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(row.get("code", 0)) as Key
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(row.get("button", 0)) as MouseButton
			return mouse
		"button":
			var button := InputEventJoypadButton.new()
			button.device = -1
			button.button_index = int(row.get("button", 0)) as JoyButton
			return button
		"axis":
			var motion := InputEventJoypadMotion.new()
			motion.device = -1
			motion.axis = int(row.get("axis", 0)) as JoyAxis
			motion.axis_value = 1.0 if int(row.get("sign", 1)) >= 0 else -1.0
			return motion
	return null


## What an action is bound to on a device, as descriptions.
static func bound(action: String, device: int) -> Array:
	var out: Array = []
	if not InputMap.has_action(action):
		return out
	for event: InputEvent in InputMap.action_get_events(action):
		if device_of(event) == device:
			out.append(describe(event))
	return out


static func may_share(a: String, b: String) -> bool:
	for pair: Array in SHARED:
		if pair.has(a) and pair.has(b):
			return true
	return false


## **Take an input** for an action. Returns the reason it was refused, or empty
## when it was done — and `last_note` says what else moved.
static func rebind(action: String, event: InputEvent) -> String:
	last_note = ""
	if not rebindable().has(action):
		return "%s cannot be rebound" % action
	var device: int = device_of(event)
	if device < 0:
		return "that is not a key or a button"
	var key := event as InputEventKey
	if key != null and RESERVED_KEYS.has(key.physical_keycode if key.physical_keycode != KEY_NONE
			else key.keycode):
		return "Escape is the way out of every menu"
	var button := event as InputEventJoypadButton
	if button != null and RESERVED_BUTTONS.has(button.button_index):
		return "Start is the way to the menu"
	var wanted: Dictionary = describe(event)
	var before: Array = bound(action, device)
	if before.has(wanted) and before.size() == 1:
		return ""
	# The whole map for this device — the debug keys too, which never move but
	# still answer in a shipped build — then the change, then the check.
	var plan: Dictionary = {}
	for other: String in _mapped():
		plan[other] = bound(other, device)
	var moved := PackedStringArray()
	for other: String in plan:
		if other == action or not (plan[other] as Array).has(wanted):
			continue
		if FIXED.has(other):
			return "that is kept for %s" % other
		var theirs: Array = (plan[other] as Array).filter(
			func(row: Dictionary) -> bool: return row != wanted)
		for row: Dictionary in before:
			if not theirs.has(row):
				theirs.append(row)
		plan[other] = theirs
		moved.append(other)
	plan[action] = [wanted]
	var clash: String = _clash(plan)
	if clash != "":
		return clash
	for changed: String in moved + PackedStringArray([action]):
		_keep(changed, device, plan[changed])
	apply_overrides()
	Settings.save()
	if not moved.is_empty():
		last_note = "%s took %s's old %s" % [", ".join(moved), action,
			"key" if device == Device.KEYS else "button"]
	return ""


## Every default back, and nothing kept.
static func reset() -> void:
	Settings.bindings.clear()
	apply_overrides()
	Settings.save()
	last_note = ""


## **The map a player has**: the project's, with every kept override laid over
## it, and a dev launch's device restriction put back on top.
static func apply_overrides() -> void:
	InputMap.load_from_project_settings()
	for action: String in Settings.bindings:
		if not InputMap.has_action(action) or FIXED.has(action):
			continue
		var kept: Dictionary = Settings.bindings[action]
		for device: int in [Device.KEYS, Device.PAD]:
			var rows: Variant = kept.get(DEVICE_NAMES[device])
			if typeof(rows) != TYPE_ARRAY:
				continue
			var events: Array[InputEvent] = []
			for row: Variant in rows as Array:
				if typeof(row) != TYPE_DICTIONARY:
					continue
				var made: InputEvent = build(row)
				if made != null and device_of(made) == device:
					events.append(made)
			if events.is_empty():
				# A kept list that builds nothing would unbind the verb.
				continue
			for event: InputEvent in InputMap.action_get_events(action):
				if device_of(event) == device:
					InputMap.action_erase_event(action, event)
			for made: InputEvent in events:
				InputMap.action_add_event(action, made)
	InputDevices.reapply()


## Where two actions would share an input they may not, as a sentence.
static func _clash(plan: Dictionary) -> String:
	# Plain arrays: a packed one read out of a dictionary is a copy, and
	# appending to it would add to nothing.
	var holders: Dictionary = {}
	for action: String in plan:
		for row: Dictionary in plan[action]:
			var key: String = JSON.stringify(row)
			if not holders.has(key):
				holders[key] = []
			(holders[key] as Array).append(action)
	for key: String in holders:
		var sharing: Array = holders[key]
		for i: int in sharing.size():
			for j: int in range(i + 1, sharing.size()):
				if not may_share(sharing[i], sharing[j]):
					return "that would leave %s and %s on one input" % [sharing[i], sharing[j]]
	return ""


static func _keep(action: String, device: int, rows: Array) -> void:
	var kept: Dictionary = Settings.bindings.get(action, {})
	kept[DEVICE_NAMES[device]] = rows.duplicate(true)
	Settings.bindings[action] = kept
