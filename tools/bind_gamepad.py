#!/usr/bin/env python3
"""Give every input action a gamepad binding alongside its keyboard one.

Usage:
    python3 tools/bind_gamepad.py            # write bindings into project.godot
    python3 tools/bind_gamepad.py --check    # CI: fail if any action lacks one

Why a generator rather than hand-editing: Godot rewrites `project.godot`
whenever the editor saves, and a keyboard-only action array is written as
`Array[InputEventKey]([...])` — a *typed* array that cannot hold a joypad
event. Adding controller support by hand therefore means retyping every array
and re-doing it after the next editor save. This is idempotent, so it can be
re-run at any time, and `--check` makes a missing binding a build failure
rather than something a player discovers.

ADR-075 makes full controller parity a project rule, so "every action" is the
requirement — an action reachable only from a keyboard is the bug this catches.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "game" / "project.godot"

# Godot 4 JoyButton / JoyAxis indices.
A, B, X, Y = 0, 1, 2, 3
LEFT_STICK, RIGHT_STICK = 7, 8
LEFT_SHOULDER, RIGHT_SHOULDER = 9, 10
DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT = 11, 12, 13, 14
AXIS_LX, AXIS_LY, AXIS_RX, AXIS_RY = 0, 1, 2, 3
AXIS_TRIGGER_RIGHT = 5

# One binding per action. Sticks are analogue on purpose: movement and look are
# the two places a controller is *better* than a keyboard, and quantising them
# to digital would throw that away.
BUTTON = "button"
AXIS = "axis"

BINDINGS: dict[str, list[tuple[str, int, float]]] = {
    "move_forward": [(AXIS, AXIS_LY, -1.0)],
    "move_back": [(AXIS, AXIS_LY, 1.0)],
    "move_left": [(AXIS, AXIS_LX, -1.0)],
    "move_right": [(AXIS, AXIS_LX, 1.0)],
    "look_left": [(AXIS, AXIS_RX, -1.0)],
    "look_right": [(AXIS, AXIS_RX, 1.0)],
    "look_up": [(AXIS, AXIS_RY, -1.0)],
    "look_down": [(AXIS, AXIS_RY, 1.0)],
    "jump": [(BUTTON, A, 0.0)],
    "sprint": [(BUTTON, LEFT_STICK, 0.0)],
    # Hold on B, latch on right-stick click — the two conventions shooters have
    # settled on, and ADR-075 keeps both live for the same reason the keyboard
    # does: neither suits every hand.
    "crouch": [(BUTTON, B, 0.0)],
    "crouch_toggle": [(BUTTON, RIGHT_STICK, 0.0)],
    "attack": [(AXIS, AXIS_TRIGGER_RIGHT, 1.0)],
    "debug_weight_up": [(BUTTON, DPAD_UP, 0.0)],
    "debug_weight_down": [(BUTTON, DPAD_DOWN, 0.0)],
    "debug_reset": [(BUTTON, DPAD_LEFT, 0.0)],
    "debug_ink": [(BUTTON, Y, 0.0)],
    "interact": [(BUTTON, X, 0.0)],
}

JOY_BUTTON = ('Object(InputEventJoypadButton,"resource_local_to_scene":false,'
              '"resource_name":"","device":-1,"button_index":{index},'
              '"pressure":0.0,"pressed":false,"script":null)')
JOY_AXIS = ('Object(InputEventJoypadMotion,"resource_local_to_scene":false,'
            '"resource_name":"","device":-1,"axis":{index},'
            '"axis_value":{value},"script":null)')

ACTION_RE = re.compile(
    r'^(?P<name>[a-z_0-9]+)=\{\n'
    r'(?P<head>.*?)"events": (?P<events>.*?)\n\}$',
    re.MULTILINE | re.DOTALL,
)


def event_text(kind: str, index: int, value: float) -> str:
    if kind == BUTTON:
        return JOY_BUTTON.format(index=index)
    return JOY_AXIS.format(index=index, value=value)


def rewrite(text: str) -> tuple[str, list[str]]:
    """Return the updated file and the actions that gained a binding."""
    changed: list[str] = []

    def replace(match: re.Match) -> str:
        name = match.group("name")
        if name not in BINDINGS:
            return match.group(0)
        events = match.group("events")
        wanted = [event_text(*b) for b in BINDINGS[name]]
        missing = [e for e in wanted if e not in events]
        if not missing:
            return match.group(0)
        changed.append(name)

        # Strip the Array[T](...) wrapper: a typed array cannot hold a mix of
        # key and joypad events, which is the whole reason this tool exists.
        body = events.strip()
        inner = re.sub(r'^Array\[\w+\]\(\[', '[', body)
        inner = re.sub(r'\]\)$', ']', inner)
        inner = inner.rstrip()
        assert inner.endswith("]"), f"unexpected events block for {name}"
        joined = inner[:-1].rstrip()
        if not joined.endswith("["):
            joined += ", "
        joined += ", ".join(missing) + "\n]"
        return f'{name}={{\n{match.group("head")}"events": {joined}\n}}'

    return ACTION_RE.sub(replace, text), changed


def main() -> int:
    check = "--check" in sys.argv[1:]
    text = PROJECT.read_text(encoding="utf-8")

    missing_actions = [a for a in BINDINGS if f"\n{a}={{" not in text]
    if missing_actions:
        print("actions absent from project.godot: " + ", ".join(sorted(missing_actions)),
              file=sys.stderr)
        print("→ define them in the input map first", file=sys.stderr)
        return 1

    updated, changed = rewrite(text)

    if check:
        if changed:
            print("gamepad bindings missing for: " + ", ".join(sorted(changed)),
                  file=sys.stderr)
            print("→ run: python3 tools/bind_gamepad.py", file=sys.stderr)
            return 1
        print(f"all {len(BINDINGS)} actions have a gamepad binding")
        return 0

    if changed:
        PROJECT.write_text(updated, encoding="utf-8")
        print(f"bound {len(changed)} action(s): {', '.join(sorted(changed))}")
    else:
        print(f"all {len(BINDINGS)} actions already bound")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
