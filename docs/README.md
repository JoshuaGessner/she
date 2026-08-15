# Documentation System

Everything the project knows lives here. If a decision only exists in a chat log, it does not exist.

## Layout

```
docs/
├── INDEX.md              # auto-generated master index — start here
├── OPEN-QUESTIONS.md     # live queue of unresolved decisions
├── design/    DES-###    # what the game is
├── tech/      TEC-###    # how it's built
├── process/   PRO-###    # how we work, decisions, legal, glossary
└── art/       ART-###    # visual/audio direction (stubs until art starts)
```

## Frontmatter contract

Every doc starts with:

```yaml
---
id: DES-003
title: Persistence & Meta-Progression
status: draft
owner: design
tags: [persistence, meta, balance]
updated: 2026-08-12
related: [DES-002, DES-004, TEC-003]
---
```

| Field | Meaning |
|---|---|
| `id` | Permanent. Never reused, never renumbered. |
| `status` | `draft` → `proposed` → `accepted` → `superseded` |
| `owner` | `design`, `tech`, `art`, `process` |
| `tags` | Lowercase, kebab-case. Drives index grouping. |
| `updated` | ISO date. Bump on every edit. |
| `related` | Other doc IDs. Makes the graph navigable. |

## Conventions inside docs

- `⟨tune⟩` marks any number that is a placeholder awaiting playtesting.
- `> **OPEN:**` marks an unresolved question — these get mirrored into `OPEN-QUESTIONS.md`.
- `> **DECIDED (ADR-00X):**` marks a locked decision, cross-referenced to the decision log.
- Options under consideration are named (Option A / B / C) so they can be referenced in conversation without re-explaining.

## Workflow after any decision

1. Edit the design doc; bump `updated`; change `status` if warranted.
2. Add an ADR entry to `process/PRO-002-decision-log.md`.
3. Remove the resolved item from `OPEN-QUESTIONS.md`.
4. Run `python3 tools/reindex.py`.
5. Run `python3 tools/status.py --write`, then `--check` before committing.

## Tracking progress

Milestone state lives in `process/PRO-001-roadmap-and-milestones.md` as checkbox
tasks with permanent IDs (ADR-063) — there is no separate ledger. Edit the task
line, regenerate, and both [STATUS.md](STATUS.md) and `status.html` follow.

| State | Meaning |
|---|---|
| `- [ ]` | not started |
| `- [~]` | in progress |
| `- [x]` | done — see the definition of done in `CLAUDE.md §4` |
| `- [-]` | cut; must be followed by ` — cut: <reason>` |

Gates are the mechanism that stops one milestone bleeding into the next
(ADR-034). Mark one `passed YYYY-MM-DD` only when it genuinely is; `failed
YYYY-MM-DD — <reason>` is a normal working state, not an alarm.

## Finding things fast

- **By ID:** `rg "DES-003" docs/` — finds the doc and everything referencing it.
- **By tag:** `rg "tags:.*persistence" docs/`
- **By status:** `rg "^status: proposed" docs/` — what needs sign-off.
- **Unresolved:** `rg "OPEN:" docs/`
- **Untuned numbers:** `rg "⟨tune⟩" docs/`
