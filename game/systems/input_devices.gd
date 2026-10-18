class_name InputDevices
extends Object

## Restrict the whole game to one input device, at launch (`M1-T05`, ADR-075).
##
## ADR-075 asks `M1-T05`'s two-player test to be run as **one keyboard and one
## controller**, on the grounds that it is the cheapest possible parity check
## and costs nothing extra. It costs nothing extra only if the two instances
## can actually be told apart: two processes on one machine both enumerate the
## same joypad, and a tester who "checked the controller" while their other
## hand rested on WASD has checked nothing.
##
## So the restriction is enforced rather than trusted. `--input=gamepad` erases
## every key and mouse event from every action; `--input=keyboard` erases every
## joypad event. What is left is a game that is *unplayable* by the wrong
## device, which is the only way a parity claim can be believed.
##
## This is not a fallback path (ADR-064): it removes bindings from the one
## input map the game already has. With no flag, nothing is erased and both
## devices work, which is the shipping behaviour.

## Devices a launch may restrict to. `all` is the default and erases nothing.
const KEYBOARD: String = "keyboard"
const GAMEPAD: String = "gamepad"
const ALL: String = "all"

## Mouse *motion* is not an action, so the input map cannot express it. Look is
## read straight from `InputEventMouseMotion` in the player, which asks here.
static var _pointer_allowed: bool = true
## The device a launch was restricted to, so a rebuilt map can be restricted
## again.
static var _restricted: String = ALL
## **The device in hand** (`M4-T05`, `DES-019` rule 7): the last one a person
## touched, or `ALL` before anything was. Prompts name it alone once it is
## known — *"e"* or *"A"*, not *"e/A"* — and both until then.
static var _in_hand: String = ALL
## How far a stick must lean to count as picking the pad up. A resting stick
## drifts, and a prompt that flickered between devices on drift would be worse
## than one that named both.
const STICK_WAKES: float = 0.5
## How far the mouse must move in one event to count as taking it in hand: a
## desk knocked is not a choice of device.
const MOUSE_WAKES: float = 4.0
## How far each axis leaned at its last event, by device and axis (B167): a
## stick counts when it *crosses* `STICK_WAKES`, not while it rests past it, so
## a pad with a stuck axis cannot take the prompts back after every key.
static var _leaned: Dictionary = {}
## The pad a person last picked up, or -1 (B164): whose family names the buttons.
static var _pad: int = -1
## Pad families whose faces are labelled differently (B164).
const XBOX: StringName = &"xbox"
const PLAYSTATION: StringName = &"playstation"
const NINTENDO: StringName = &"nintendo"


## The device a person is using, or `ALL` while nothing says.
static func in_hand() -> String:
	return _in_hand if _restricted == ALL else _restricted


## Hear one input event (`Config` passes every one).
static func note(event: InputEvent) -> void:
	var device: String = ALL
	if event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			device = GAMEPAD
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var axis: int = motion.device * 64 + int(motion.axis)
		var was: float = float(_leaned.get(axis, 0.0))
		var now: float = absf(motion.axis_value)
		_leaned[axis] = now
		if now >= STICK_WAKES and was < STICK_WAKES:
			device = GAMEPAD
	elif event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			device = KEYBOARD
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() >= MOUSE_WAKES:
			device = KEYBOARD
	if device != ALL:
		_in_hand = device
		if device == GAMEPAD:
			_pad = event.device


## **Whose buttons the prompts name** (B164): the family of the pad last picked
## up — or of the first one connected, before any was — read off its name.
## SDL's names, which Godot reports: *"PS5 Controller"*, *"DualSense Wireless
## Controller"*, *"Nintendo Switch Pro Controller"*, *"Xbox Series X
## Controller"*. Anything unrecognised reads as the Xbox layout Godot's own
## button names follow.
static func pad_family() -> StringName:
	var pad: int = _pad
	if pad < 0 or not Input.get_connected_joypads().has(pad):
		var connected: Array[int] = Input.get_connected_joypads()
		pad = connected[0] if not connected.is_empty() else -1
	return family_of(Input.get_joy_name(pad)) if pad >= 0 else XBOX


static func family_of(pad_name: String) -> StringName:
	var named: String = pad_name.to_lower()
	for word: String in ["playstation", "dualsense", "dualshock", "ps3", "ps4", "ps5", "sony"]:
		if named.contains(word):
			return PLAYSTATION
	for word: String in ["nintendo", "switch", "joy-con", "joycon"]:
		if named.contains(word):
			return NINTENDO
	return XBOX


## Back to knowing nothing, for a probe that has fed events of its own.
static func forget() -> void:
	_in_hand = ALL
	_leaned.clear()
	_pad = -1


## True unless this instance was launched gamepad-only. The player consults it
## before reading mouse look or capturing the cursor — a captured cursor on the
## controller instance would steal the pointer from the keyboard instance's
## window, on the same desktop, which is its own kind of unplayable.
static func pointer_allowed() -> bool:
	return _pointer_allowed


## Apply `--input=` from the command line. Returns the device that is now in
## force, so the caller can report it — a restriction nobody can see is one
## nobody trusts.
static func restrict_from_cmdline() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--input="):
			return restrict(arg.split("=", true, 1)[1])
	return ALL


static func restrict(device: String) -> String:
	if device != KEYBOARD and device != GAMEPAD:
		return ALL
	_pointer_allowed = device == KEYBOARD
	_restricted = device
	var erased: int = 0
	var touched: int = 0
	for action: StringName in InputMap.get_actions():
		# The project's actions only. Godot's built-in `ui_*` set is the engine's
		# UI navigation, and stripping half of it at launch would break menus
		# later for a reason nobody would connect to a dev flag.
		if String(action).begins_with("ui_"):
			continue
		touched += 1
		for event: InputEvent in InputMap.action_get_events(action):
			if _belongs_to(event, device):
				continue
			InputMap.action_erase_event(action, event)
			erased += 1
	# Printed, because a restriction nobody can see is one nobody trusts — and
	# the entire value of this flag is being able to believe the parity check
	# afterwards.
	print("[input] %s only — erased %d binding(s) across %d action(s)" % [
		device, erased, touched])
	return device


## **Put a restriction back** after the input map was rebuilt (`M4-T06`,
## ADR-245) — a rebind reloads the project's map, which would otherwise hand a
## gamepad-only launch its keyboard back mid-session.
static func reapply() -> void:
	if _restricted != ALL:
		restrict(_restricted)


static func _belongs_to(event: InputEvent, device: String) -> bool:
	var is_pad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	return is_pad if device == GAMEPAD else not is_pad
