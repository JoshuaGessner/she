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
BACK, GUIDE, START = 4, 5, 6
LEFT_STICK, RIGHT_STICK = 7, 8
LEFT_SHOULDER, RIGHT_SHOULDER = 9, 10
DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT = 11, 12, 13, 14
AXIS_LX, AXIS_LY, AXIS_RX, AXIS_RY = 0, 1, 2, 3
AXIS_TRIGGER_LEFT, AXIS_TRIGGER_RIGHT = 4, 5

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
    # The bag (`M2-T01`, DES-019). Opening it is a vulnerable act, so it sits on
    # a shoulder rather than a face button — nothing you press by accident while
    # fighting. Moving items needs no bindings of its own: `Player` suspends
    # look while the bag is open and hands the right stick to the cell cursor,
    # and `interact` is take-and-place there exactly as it is reach-for-it in
    # the world. One verb, one button, two contexts.
    "bag": [(BUTTON, LEFT_SHOULDER, 0.0)],
    "drop": [(BUTTON, DPAD_DOWN, 0.0)],
    "rotate_item": [(BUTTON, RIGHT_SHOULDER, 0.0)],
    # Baiting the Gullsjúkr (`M2-T02`, DES-017). On the trigger opposite attack,
    # because it is the other thing you do with a full hand under pressure and
    # the two must never be confused at the moment it matters.
    "throw": [(AXIS, AXIS_TRIGGER_LEFT, 1.0)],
    # Spending the way home (`M2-T04`, ADR-015). Deliberately off on the d-pad,
    # away from the face buttons and the triggers: it ends the run, and the one
    # input you must never press by accident should not sit under your thumb.
    "use_waystone": [(BUTTON, DPAD_UP, 0.0)],
    "debug_reset": [(BUTTON, DPAD_LEFT, 0.0)],
    # Off the face buttons and onto `BACK` (ADR-137), which nothing was using.
    # A debug toggle does not get to hold prime real estate while a class verb
    # goes unbound — and `GUIDE` stays empty deliberately, because it is the
    # system button and the OS eats it.
    "debug_ink": [(BUTTON, BACK, 0.0)],
    # The diagnostic overlay (`M2-T13`, ADR-105). Beside the other two debug
    # keys, because it is one: vision cones and the clamor field are for tuning,
    # and they were drawn in every session including a playtester's.
    "debug_overlays": [(BUTTON, DPAD_RIGHT, 0.0)],
    "interact": [(BUTTON, X, 0.0)],
    # **Hold and Snare** (`M3-T02`, `M3-T11`, `DES-011`) — the class verb, on
    # the face button every shooter puts a class ability on.
    #
    # **It used to share `LEFT_STICK` with `sprint`, and that was a bug, not a
    # trade** (ADR-137). The argument was *sprinting and planting yourself in a
    # doorway are opposites, so no hand ever wants both in the same instant* —
    # true about intent, false about code. Nothing checked context: one click
    # fired both actions, and since `_target_speed` returns **zero** while
    # `planted > 0`, a Húskarl on a pad who pressed sprint stopped dead. On a
    # pad that class could not run at all. The Veiðimaðr had the quieter half of
    # it — sprinting set a snare at their feet and spent the stamina for it.
    #
    # The claim that made sharing necessary — *the pad has no free button* —
    # was also false: `BACK` was empty the whole time, and `Y` was spent on
    # `debug_ink`. A debug toggle was holding a face button while a combat verb
    # was not reachable. That is the trade that actually existed.
    "verb": [(BUTTON, Y, 0.0)],
    # **Blocking** (`M3-T02`, `DES-009`). Right mouse, and on the pad it shares
    # RIGHT_SHOULDER with `rotate_item` — the two contexts are disjoint, since
    # you cannot raise a shield while rummaging and cannot turn an item while
    # fighting. Precedent is `interact`, which is already take-and-place in the
    # bag and reach-for-it in the world.
    #
    # It shares rather than takes a free button because **there is no free
    # button**: every face, shoulder, trigger, stick and d-pad direction is
    # spoken for, while `DES-009`'s five combat verbs are attack, heavy,
    # block, shove and throw — of which three are still unbound. The layout
    # pass that fixes that properly belongs with rebinding at `M4-T06`.
    "block": [(BUTTON, RIGHT_SHOULDER, 0.0)],
}

# Pairs allowed to sit on one physical input, and the context that keeps them
# apart. **Everything not named here is a conflict and fails the check**
# (ADR-137), because `sprint` and `verb` shared `LEFT_STICK` for eleven tasks
# with a comment explaining why it was fine, and it was not fine: the comment
# was the only thing separating them, and a comment does not run.
#
# The test for entry is not "would a player want both at once" — that is an
# argument about intent. It is **"does code refuse one of them in the state the
# other is used in"**, which is a thing a probe can ask.
SHARED_OK: dict[frozenset[str], str] = {
    frozenset({"block", "rotate_item"}):
        "disjoint by the bag: `blocking` requires `_bag <= 0.0`, and "
        "`rotate_item` is only read by BagScreen while it is open",
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


ELEMENT_SPLIT = re.compile(r",\s*(?=Object\()")


def rewrite(text: str) -> tuple[str, list[str]]:
    """Return the updated file and the actions whose bindings moved."""
    changed: list[str] = []

    def replace(match: re.Match) -> str:
        name = match.group("name")
        if name not in BINDINGS:
            return match.group(0)
        events = match.group("events")
        wanted = [event_text(*b) for b in BINDINGS[name]]

        # Strip the Array[T](...) wrapper: a typed array cannot hold a mix of
        # key and joypad events, which is the whole reason this tool exists.
        body = events.strip()
        inner = re.sub(r'^Array\[\w+\]\(\[', '[', body)
        inner = re.sub(r'\]\)$', ']', inner)
        inner = inner.rstrip()
        assert inner.endswith("]"), f"unexpected events block for {name}"
        listed = inner[1:-1].strip()
        elements = ELEMENT_SPLIT.split(listed) if listed else []

        # **Keep every keyboard and mouse event, replace every joypad one.**
        # This used to only append what was missing, which made the tool
        # idempotent for additions and silently wrong for moves: sending `verb`
        # from LEFT_STICK to Y (ADR-137) would have left LEFT_STICK bound and
        # produced an action on two buttons rather than a moved one. A generator
        # that cannot take a binding away is a generator you cannot use to fix a
        # layout, which is exactly what ADR-137 needed it for.
        kept = [e.strip() for e in elements
                if not e.strip().startswith("Object(InputEventJoypad")]
        rebuilt = kept + wanted
        if [e.strip() for e in elements] == rebuilt:
            return match.group(0)
        changed.append(name)
        joined = "[" + ", ".join(rebuilt) + "\n]"
        return f'{name}={{\n{match.group("head")}"events": {joined}\n}}'

    return ACTION_RE.sub(replace, text), changed


def conflicts() -> list[str]:
    """Actions sharing one physical input without a documented context split.

    Axis *direction* is part of the identity — `move_forward` and `move_back`
    are the same stick and opposite signs, which is one input used two ways and
    not two actions fighting over one.
    """
    seen: dict[tuple, list[str]] = {}
    for action, binds in BINDINGS.items():
        for kind, index, value in binds:
            key = (kind, index) if kind == BUTTON else (kind, index, value)
            seen.setdefault(key, []).append(action)
    out: list[str] = []
    for key, actions in sorted(seen.items(), key=lambda kv: str(kv[0])):
        if len(actions) < 2:
            continue
        if SHARED_OK.get(frozenset(actions)) is not None:
            continue
        out.append("%s: %s" % (key[1], ", ".join(sorted(actions))))
    return out


def main() -> int:
    check = "--check" in sys.argv[1:]
    text = PROJECT.read_text(encoding="utf-8")

    missing_actions = [a for a in BINDINGS if f"\n{a}={{" not in text]
    if missing_actions:
        print("actions absent from project.godot: " + ", ".join(sorted(missing_actions)),
              file=sys.stderr)
        print("→ define them in the input map first", file=sys.stderr)
        return 1

    # And the other direction, which this tool did not ask for two years of
    # actions and then missed one on the first try (`M3-T02`).
    #
    # The check above walks BINDINGS and confirms each has an action. That is
    # only half of ADR-075's rule: an action defined in project.godot with no
    # entry here is **keyboard-only**, which is precisely "an action reachable
    # only from a keyboard" — the bug this file exists to catch — and it passed
    # silently, reporting that all 23 actions were bound while a 24th was not.
    # A check that enumerates its own expectations can only ever confirm them.
    declared = set(re.findall(r"^([a-z_0-9]+)=\{", text, re.MULTILINE))
    unbound = sorted(declared - set(BINDINGS))
    if unbound:
        print("actions with no gamepad binding: " + ", ".join(unbound),
              file=sys.stderr)
        print("→ add them to BINDINGS; ADR-075 makes controller parity a rule",
              file=sys.stderr)
        return 1

    clashes = conflicts()
    if clashes:
        print("two actions on one pad input, with nothing separating them:",
              file=sys.stderr)
        for line in clashes:
            print("  button %s" % line, file=sys.stderr)
        print("→ move one, or add the pair to SHARED_OK with the context that "
              "keeps them apart (ADR-137)", file=sys.stderr)
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
