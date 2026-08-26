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
import subprocess
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
    # `(?![\w])` alone is not enough: `placeholder_text` is a Godot property
    # and `stub` appears inside plenty of ordinary words. The trailing guard
    # rejects a following underscore too, so an engine identifier that happens
    # to contain the word is not read as a promise nobody kept.
    r"(?<![\w])(TODO|FIXME|XXX|HACK|stub|stubbed|placeholder|for now)(?![\w_])",
    re.IGNORECASE
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


# What each physics body is, by name rather than by integer. Compared against
# `CollisionLayers` and against the scenes themselves by `check_collision_layers`.
LAYER_CONTRACT: dict[tuple[str, str], tuple[str | None, str | None]] = {
    # (scene, node)                     (layer constant, mask constant)
    ("actors/player/player.tscn", "Player"): ("PLAYER_BODY", "WORLD"),
    ("actors/player/player.tscn", "Hurtbox"): ("PLAYER_HURTBOX", None),
    ("actors/player/player.tscn", "Hitbox"): (None, "ENEMY_HURTBOX"),
    # `WORLD|BULWARK`: an enemy is stopped by geometry and by a planted
    # Húskarl, and by nothing else (`M3-T02`, `DES-011`). Adding `PLAYER_BODY`
    # here would make every teammate a wall; `BULWARK` is a layer only a body
    # holding a doorway ever carries, which is what lets allies retreat
    # *through* that body with no rule saying "except teammates".
    ("actors/enemies/enemy.tscn", "Enemy"): ("ENEMY_BODY", "WORLD|BULWARK"),
    ("actors/enemies/enemy.tscn", "Hurtbox"): ("ENEMY_HURTBOX", None),
    ("actors/enemies/enemy.tscn", "Hitbox"): (None, "PLAYER_HURTBOX"),
}


def check_collision_layers() -> list[Issue]:
    """Assert every scene's physics layers match the names in the one file.

    `CollisionLayers` says of itself that a mismatched mask is invisible —
    "nothing errors, the swing simply passes through" — and then the scenes
    set raw integers that nothing compared against it. Three of its five
    constants were read by no code at all (ADR-098), which meant the file
    documenting the layout had no way to be wrong *and* no way to be right.

    This is a deliberate duplicate, in the way a checksum is one: the table
    below and the scenes have to agree, so changing either alone fires. It is
    also what makes the constants load-bearing rather than decorative.
    """
    issues: list[Issue] = []
    source = GAME / "systems/collision_layers.gd"
    if not source.exists():
        return [Issue("error", "no-layers", rel(source),
                      "CollisionLayers is missing",
                      "physics layers must be named in one place")]

    named: dict[str, int] = {}
    for line in source.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\s*const\s+([A-Z_]+):\s*int\s*=\s*1\s*<<\s*(\d+)", line)
        if match:
            named[match.group(1)] = 1 << int(match.group(2))

    for (scene, node), (layer, mask) in LAYER_CONTRACT.items():
        path = GAME / scene
        if not path.exists():
            issues.append(Issue("error", "layer-scene", scene,
                                f"{scene} is missing but the layer contract names it",
                                "update LAYER_CONTRACT or restore the scene"))
            continue
        found = _scene_layers(path, node)
        if found is None:
            issues.append(Issue("error", "layer-node", scene,
                                f"no node named {node}",
                                "update LAYER_CONTRACT or restore the node"))
            continue
        for kind, want in (("collision_layer", layer), ("collision_mask", mask)):
            # A `|`-joined name is a combination — a mask may name more than
            # one layer, and spelling it out is what keeps the contract
            # readable as a sentence about what collides with what.
            expected = 0
            for part in (want.split("|") if want else []):
                expected |= named.get(part.strip(), 0)
            actual = found[kind]
            if actual != expected:
                issues.append(Issue(
                    "error", "layer-drift", f"{scene}:{node}",
                    f"{kind} is {actual}, but CollisionLayers says "
                    f"{want or 'nothing'} = {expected}",
                    "a mismatched mask fails silently — the swing simply "
                    "passes through. Fix the scene or the constant."))
    return issues


def _scene_layers(path: Path, node: str) -> dict[str, int] | None:
    """The collision layer and mask a .tscn sets on one named node."""
    wanted = re.compile(rf'^\[node name="{re.escape(node)}"')
    found: dict[str, int] | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("[node "):
            if found is not None:
                return found
            found = {"collision_layer": 0, "collision_mask": 0} \
                if wanted.match(line) else None
            continue
        if found is None:
            continue
        match = re.match(r"(collision_layer|collision_mask)\s*=\s*(\d+)", line)
        if match:
            found[match.group(1)] = int(match.group(2))
    return found


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


# ── CI must check out the same repository a developer has (ADR-104) ───────


def _lfs_patterns() -> list[str]:
    """Extensions `.gitattributes` routes through LFS, if any."""
    attrs = ROOT / ".gitattributes"
    if not attrs.is_file():
        return []
    found = []
    for line in attrs.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "filter=lfs" not in line:
            continue
        found.append(line.split()[0])
    return found


def check_lfs_content() -> list[Issue]:
    """Every LFS-tracked file in the tree is real content, not a pointer.

    The other half of ADR-104, and the half that speaks to a person rather
    than to CI. A clone made without `git lfs install` leaves ~130 bytes of
    text where the art should be; the first thing to complain is Godot, and
    what it says is that the glTF is malformed. That sends you looking for a
    corrupt export instead of a missing fetch.
    """
    issues: list[Issue] = []
    for pattern in _lfs_patterns():
        for path in ROOT.rglob(pattern):
            if ".git" in path.parts or not path.is_file():
                continue
            with path.open("rb") as handle:
                if handle.read(43) != b"version https://git-lfs.github.com/spec/v1\n":
                    continue
            issues.append(Issue(
                "error", "lfs-pointer", rel(path),
                "is an LFS pointer, not the file itself",
                "run `git lfs install --local && git lfs pull` — the engine "
                "will otherwise report this as corrupt art",
            ))
    return issues


def check_workflows() -> list[Issue]:
    """A CI job that runs Godot must fetch LFS content, not pointer files.

    ADR-104. `actions/checkout` leaves LFS files as ~130-byte text pointers
    unless told otherwise, and nothing downstream announces that: Godot reports
    a glTF *parse* error, which reads like corrupt art rather than art that was
    never fetched. The Godot job stayed red for fourteen commits on exactly
    this, and the export job is worse — it goes *green* while shipping a build
    with the art missing.

    Checked statically because the alternative is noticing. Nothing in the
    pre-commit sweep can see it: every developer clone has LFS smudged, so the
    files are real locally and only ever pointers on a fresh CI checkout.
    """
    workflows = ROOT / ".github" / "workflows"
    if not _lfs_patterns() or not workflows.is_dir():
        return []

    issues: list[Issue] = []
    for path in sorted(workflows.glob("*.yml")):
        text = path.read_text(encoding="utf-8")
        # Split on job headers — two-space keys under `jobs:` — so the rule
        # applies per job. A docs-only job has no business paying for LFS.
        blocks = re.split(r"^  (?=[A-Za-z0-9_-]+:\s*$)", text, flags=re.M)
        for block in blocks:
            if not re.search(r"\bgodot\b", block, re.I):
                continue
            job = block.split(":", 1)[0].strip() or path.stem
            for match in re.finditer(r"^(\s*)- uses:\s*actions/checkout",
                                     block, re.M):
                # The step runs to the next list item at the same indent.
                rest = block[match.end():]
                end = re.search(r"^%s- " % match.group(1), rest, re.M)
                step = rest[:end.start()] if end else rest
                if re.search(r"^\s*lfs:\s*true\s*$", step, re.M):
                    continue
                issues.append(Issue(
                    "error", "ci-lfs-pointer", f"{rel(path)}:{job}",
                    "runs Godot but checks out without `lfs: true`",
                    "add `with: {lfs: true}` — otherwise LFS art arrives as "
                    "text pointers and the job tests a repository nobody has",
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


def check_gamepad() -> list[Issue]:
    """Controller parity, run locally instead of only in CI (ADR-137).

    `bind_gamepad.py --check` existed and was wired into `ci.yml` and nowhere
    else, so a binding fault was invisible until roughly fifty seconds after a
    push — which ADR-104 already established is the same as invisible. It found
    `sprint` and `verb` sharing the left-stick click only because somebody read
    the table by hand, and by then the Húskarl had been unable to run on a pad
    for eleven tasks.

    `project.godot` is this file's subject, so the check belongs here, in the
    sweep that runs before the commit rather than after it.
    """
    result = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "bind_gamepad.py"), "--check"],
        capture_output=True, text=True)
    if result.returncode == 0:
        return []
    detail = (result.stderr or result.stdout).strip().splitlines()
    return [Issue(
        "error", "gamepad-bindings", "game/project.godot",
        "; ".join(line.strip() for line in detail if line.strip()),
        "run: python3 tools/bind_gamepad.py")]


def main() -> int:
    strict = "--strict" in sys.argv[1:]

    issues = check_settings()
    if not any(i.code == "no-project" for i in issues):
        issues += check_layout()
        issues += check_collision_layers()
        issues += check_workflows()
        issues += check_lfs_content()
        issues += check_gamepad()
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
