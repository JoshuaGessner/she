---
description: Milestone dashboard — where the project stands and what is blocked
allowed-tools: Bash(python3 tools/status.py:*), Bash(python3 tools/reindex.py:*)
---

Run `python3 tools/status.py` and show the output verbatim in a code block.

Then, in no more than four lines:

- Name the current milestone and its gate, and whether anything is blocked.
- If there are blockers, say which one to deal with first and why.
- If `$ARGUMENTS` is non-empty, treat it as the question to answer against the
  dashboard rather than giving the general summary.

Do not restate the whole dashboard in prose — it is already on screen. Do not
estimate dates or durations for anything: ADR-034 removed schedules from this
project deliberately, and progress here is scope covered, never time remaining.
