#!/usr/bin/env python3
"""Assert the Godot project's locked decisions and coding conventions.

Usage:
    python3 tools/check_project.py            # report; exit 1 on any error
    python3 tools/check_project.py --strict   # warnings are errors too

Why this exists rather than a review checklist: three of the things it checks
are *locked decisions* that a stray editor session reverts silently and that
nobody notices for months — the Forward+ renderer (ADR-052), the autoload
budget (TEC-001), and typed GDScript (TEC-002). The rest are the conventions
in TEC-002 that are cheap to check and expensive to retrofit.

Deliberately dependency-free, matching tools/reindex.py and tools/status.py.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Iterator, NamedTuple

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
PROJECT = GAME / "project.godot"

# TEC-001: "Autoloads are a budget, not a habit."
AUTOLOAD_BUDGET = 6

# TEC-002 repository layout. Present so that a renamed or invented directory is
# caught at once rather than becoming a second convention nobody agreed to.
REQUIRED_DIRS = [
    "autoload", "components", "actors/player", "actors/enemies", "systems",
    "data/items", "data/enemies", "data/skills", "data/contracts",
    "data/biomes", "data/tuning", "levels/modules", "levels/lair",
    "ui", "art", "audio", "tests",
]

SNAKE_CASE = re.compile(r"^[a-z0-9_]+$")
PASCAL_CASE = re.compile(r"^[A-Z][A-Za-z0-9]*$")
SCREAMING_SNAKE = re.compile(r"^[A-Z][A-Z0-9_]*$")

CLASS_NAME = re.compile(r"^\s*class_name\s+([A-Za-z_]\w*)")
CONST_DECL = re.compile(r"^\s*const\s+([A-Za-z_]\w*)")
CALLS_UP = re.compile(r"\bget_parent\(\)\s*\.")

# ADR-064. A placeholder is permitted only with a named replacement task ID and
# a milestone by which it is gone. The task ID is the thing we can check for.
PLACEHOLDER_WORDS = re.compile(
    r"\b(TODO|FIXME|XXX|HACK|stub|stubbed|placeholder|for now)\b", re.IGNORECASE
)
# A task ID carries both halves of ADR-064's exception — the replacement and
# the milestone it lands in. An ADR reference marks prose that is *stating* the
# policy ("absent, not stubbed") rather than shipping a placeholder. Same
# exemption status.py applies to roadmap tasks; the two must agree or the same
# sentence passes one checker and fails the other.
PAIRED = re.compile(r"\b(M\d+-T\d+|ADR-\d+)\b")
COMMENT_LINE = re.compile(r"^\s*(#|//)")

TEXT_SUFFIXES = {".gd", ".gdshader", ".tscn", ".tres"}


class Issue(NamedTuple):
    level: str      # "error" | "warn"
    code: str
    where: str
    message: str
    fix: str


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def game_files() -> Iterator[Path]:
    """Every tracked source file under game/, skipping the engine's cache."""
    for path in sorted(GAME.rglob("*")):
        if not path.is_file() or ".godot" in path.parts:
            continue
        yield path


# ── project settings: the locked decisions ────────────────────────────────


def parse_project() -> dict[str, dict[str, str]]:
    """project.godot is INI-ish. Return {section: {key: raw_value}}."""
    sections: dict[str, dict[str, str]] = {"": {}}
    current = ""
    for line in PROJECT.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1]
            sections.setdefault(current, {})
            continue
        key, sep, value = line.partition("=")
        if sep:
            sections[current][key.strip()] = value.strip()
    return sections


def check_settings() -> list[Issue]:
    if not PROJECT.exists():
        return [Issue("error", "no-project", rel(PROJECT),
                      "the Godot project does not exist",
                      "M1-T08 creates game/project.godot")]

    issues: list[Issue] = []
    cfg = parse_project()
    where = rel(PROJECT)

    # Godot persists only settings that DIFFER from the engine default, so an
    # explicitly written `forward_plus` is deleted the next time anything calls
    # ProjectSettings.save(). Measured: it vanished on the first such save.
    # Absence therefore genuinely means forward_plus, the desktop default —
    # while any *other* renderer does differ from the default and so is always
    # written out. Checking for "absent or forward_plus" is not a weakening of
    # ADR-052: switching to Mobile still fails this, which is the only case
    # the lock was ever guarding against.
    method = cfg.get("rendering", {}).get("renderer/rendering_method", "").strip('"')
    if method and method != "forward_plus":
        issues.append(Issue(
            "error", "renderer", where,
            f"rendering_method is {method}, not forward_plus",
            "ADR-052 locks Forward+ — Mobile's 8-light cap breaks carried lanterns",
        ))

    features = cfg.get("application", {}).get("config/features", "")
    if "Forward Plus" not in features:
        issues.append(Issue(
            "warn", "renderer-feature", where,
            "config/features does not list \"Forward Plus\"",
            "add it so the editor does not offer to downgrade the renderer",
        ))

    typed = cfg.get("debug", {}).get("gdscript/warnings/untyped_declaration", "")
    if typed != "2":
        issues.append(Issue(
            "error", "untyped-allowed", where,
            f"untyped_declaration is {typed or 'unset'}, not 2 (Error)",
            "TEC-002 requires static typing everywhere; let the parser enforce it",
        ))

    autoloads = cfg.get("autoload", {})
    if len(autoloads) > AUTOLOAD_BUDGET:
        issues.append(Issue(
            "error", "autoload-budget", where,
            f"{len(autoloads)} autoloads registered, budget is {AUTOLOAD_BUDGET}: "
            + ", ".join(sorted(autoloads)),
            "TEC-001 names the six; a seventh needs an ADR, not a habit",
        ))

    main_scene = cfg.get("application", {}).get("run/main_scene", "").strip('"')
    if main_scene:
        target = GAME / main_scene.removeprefix("res://")
        if not target.exists():
            issues.append(Issue(
                "error", "main-scene-missing", where,
                f"run/main_scene points at {main_scene}, which does not exist",
                "point it at a real scene or remove the setting",
            ))
    return issues


def check_layout() -> list[Issue]:
    issues = []
    for name in REQUIRED_DIRS:
        if not (GAME / name).is_dir():
            issues.append(Issue(
                "error", "layout", f"game/{name}",
                "required directory is missing",
                "TEC-002 fixes the layout; recreate it rather than inventing one",
            ))
    for path in GAME.glob("*.gd"):
        issues.append(Issue(
            "warn", "layout-loose-script", rel(path),
            "script sits at the project root",
            "move it under autoload/, components/, actors/, systems/ or ui/",
        ))
    return issues


# ── naming and GDScript conventions (TEC-002) ─────────────────────────────


def check_naming(path: Path) -> list[Issue]:
    if path.suffix not in TEXT_SUFFIXES:
        return []
    if SNAKE_CASE.match(path.stem):
        return []
    return [Issue(
        "error", "filename", rel(path),
        f"'{path.name}' is not snake_case",
        "TEC-002: files and directories are snake_case, classes are PascalCase",
    )]


def check_script(path: Path) -> list[Issue]:
    # Static typing is *not* checked here. The GDScript parser enforces it
    # directly (untyped_declaration=2 covers untyped variables, parameters and
    # return types alike), and tools/check_scripts.sh runs that parser. Two
    # authorities for one rule is the parallel path ADR-064 bans; the engine
    # wins because it is the thing that actually compiles the code.
    issues: list[Issue] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    where = rel(path)

    for n, line in enumerate(lines, 1):
        match = CLASS_NAME.match(line)
        if match and not PASCAL_CASE.match(match.group(1)):
            issues.append(Issue(
                "error", "class-name", f"{where}:{n}",
                f"class_name '{match.group(1)}' is not PascalCase", "TEC-002 naming table",
            ))
        match = CONST_DECL.match(line)
        if match and not SCREAMING_SNAKE.match(match.group(1)):
            issues.append(Issue(
                "error", "const-name", f"{where}:{n}",
                f"const '{match.group(1)}' is not SCREAMING_SNAKE", "TEC-002 naming table",
            ))
        if CALLS_UP.search(line):
            issues.append(Issue(
                "error", "calls-up", f"{where}:{n}",
                "reaches into a parent via get_parent()",
                "TEC-001: signals up, calls down — emit a signal instead",
            ))
    return issues


def check_placeholders(path: Path) -> list[Issue]:
    """ADR-064: placeholder language needs a paired removal task ID.

    Scoped to the whole comment block, not the single line. A doc comment
    explaining *why* something is absent naturally wraps, so the sentence
    carrying the word and the sentence carrying the task ID are usually on
    different lines — and a checker that cannot read two lines together would
    force every such explanation to be deleted or contorted.
    """
    if path.suffix not in TEXT_SUFFIXES:
        return []

    lines = path.read_text(encoding="utf-8").splitlines()
    # Map each line to the text of its enclosing run of comment lines.
    context: list[str] = list(lines)
    start = 0
    while start < len(lines):
        if not COMMENT_LINE.match(lines[start]):
            start += 1
            continue
        end = start
        while end + 1 < len(lines) and COMMENT_LINE.match(lines[end + 1]):
            end += 1
        block = "\n".join(lines[start:end + 1])
        for i in range(start, end + 1):
            context[i] = block
        start = end + 1

    issues = []
    for n, line in enumerate(lines, 1):
        match = PLACEHOLDER_WORDS.search(line)
        if match and not PAIRED.search(context[n - 1]):
            issues.append(Issue(
                "error", "unpaired-placeholder", f"{rel(path)}:{n}",
                f"'{match.group(0)}' with nothing that removes it",
                "ADR-064: name the PRO-001 task that removes it, or remove it now",
            ))
    return issues


def main() -> int:
    strict = "--strict" in sys.argv[1:]

    issues = check_settings()
    if not any(i.code == "no-project" for i in issues):
        issues += check_layout()
        scripts = 0
        for path in game_files():
            issues += check_naming(path)
            issues += check_placeholders(path)
            if path.suffix == ".gd":
                scripts += 1
                issues += check_script(path)
    else:
        scripts = 0

    errors = [i for i in issues if i.level == "error"]
    warns = [i for i in issues if i.level == "warn"]
    for issue in errors + warns:
        print(f"{issue.level:<5} {issue.code:<22} {issue.where}: {issue.message}",
              file=sys.stderr)
        print(f"{'':<5} {'':<22} → {issue.fix}", file=sys.stderr)

    if errors or (strict and warns):
        print(f"\n{len(errors)} error(s), {len(warns)} warning(s)", file=sys.stderr)
        return 1
    print(f"project checks pass ({scripts} script(s), {len(warns)} warning(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
