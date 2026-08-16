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


static func _belongs_to(event: InputEvent, device: String) -> bool:
	var is_pad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	return is_pad if device == GAMEPAD else not is_pad
