---
id: TEC-002
title: Project Structure & Conventions
status: accepted
owner: tech
tags: [structure, conventions, godot, tooling]
updated: 2026-08-14
related: [TEC-001, PRO-001]
---

# Project Structure & Conventions

## Repository layout

```
she/
├── CLAUDE.md
├── docs/                       # all project knowledge (see docs/README.md)
├── tools/                      # reindex.py, build scripts, data validators
└── game/                       # the Godot project root (project.godot)
    ├── autoload/               # GameState, RunManager, EventBus, SaveSystem, ...
    ├── components/             # reusable node components (health, hitbox, clamor, ...)
    ├── actors/
    │   ├── player/
    │   └── enemies/
    ├── systems/                # generation, hunt, contracts, economy, skills
    ├── data/                   # .tres content — the designer-facing surface
    │   ├── items/  enemies/  skills/  contracts/  biomes/  tuning/
    ├── levels/
    │   ├── modules/            # hand-authored room modules for the generator
    │   └── lair/               # the hub
    ├── ui/
    ├── art/                    # models, materials, vfx
    ├── audio/
    └── tests/                  # GUT test suites
```

Rationale: `data/` is deliberately isolated so content authoring never requires navigating code, and so a future modding surface is a directory rather than a refactor.

## Naming

| Thing | Convention | Example |
|---|---|---|
| Files & directories | `snake_case` | `hunt_director.gd` |
| Classes & nodes | `PascalCase` | `class_name HuntDirector` |
| Functions & vars | `snake_case` | `func begin_pursuit()` |
| Private members | `_leading_underscore` | `var _clamor_grid` |
| Constants | `SCREAMING_SNAKE` | `const MAX_CLAMOR` |
| Signals | past-tense phrases | `signal hunt_escalated(level)` |
| Resource files | `type_name.tres` | `item_dvergar_crown.tres` |

## GDScript standards

- **Static typing everywhere.** `var hp: int = 100`, typed params, typed returns. Godot 4's typed GDScript is meaningfully faster and catches real bugs.
- `class_name` on anything referenced from elsewhere.
- `@export` for anything a designer tunes; `@export_group` to keep inspectors legible.
- **Signals up, calls down.** A child never calls `get_parent().something`.
- Header comment on every non-obvious system explaining **why**, not what.
- No magic numbers in logic — they belong in `Config` / a `TuningProfile` resource.

## Testing

**GUT** (Godot Unit Test) for logic that is expensive to verify by hand:
- Save migration across versions (`TEC-003`) — the highest-value tests in the project
- Loot table distributions and tribute-value math
- Skill tree legality (path rules, keystone exclusivity, respec)
- Generator validation (traversability, objective reachability) over hundreds of seeds
- Tithe / Boon economy math

Feel — combat, movement, pressure pacing — is **not** unit tested. It's playtested. Don't confuse the two.

## Version control

- `git init` + Godot `.gitignore` (written, at repo root).
- `.tscn`/`.tres` are text and diff acceptably. **Never** hand-edit `.uid` files.
- **Git LFS** for `.blend`, `.png` over ~1MB, `.wav`, `.ogg` — set this up *before* art lands, not after.
- Branches: `main` always launches. `feat/*` for work. Commit messages describe *why*.

## Build & release ⟨tune⟩

Export presets for Windows (primary), Linux, macOS. Every build stamps commit hash + save-format version into the main menu — indispensable when triaging player bug reports against save data.
