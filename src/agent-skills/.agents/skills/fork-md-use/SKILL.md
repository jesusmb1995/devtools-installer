---
name: fork-md-use
description: Load a previously forked conversation from /tmp/fork-<name>.md back into context. /fork-md-use <name>
---

# fork-md-use

Restore a convo saved with `/fork-md`.

## Trigger

`/fork-md-use <name>`

## Procedure

1. Resolve name: arg if given, else list `/tmp/fork-*.md` and ask which.
2. Read `/tmp/fork-<name>.md`.
3. Re-establish context: goal, decisions, files touched, pending state.
4. Confirm: `Loaded /tmp/fork-<name>.md (N lines) — <one-line goal>`.
5. Continue. Do not re-ask things already answered in the file.

## Rules

- Read-only. Do not modify the file.
- Missing? Say so, suggest `/fork-md`.