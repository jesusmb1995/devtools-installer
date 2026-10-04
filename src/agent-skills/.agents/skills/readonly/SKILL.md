---
name: readonly
description: Read-only mode — do not edit files nor perform any mutable operation. Reads and read-only inspection commands only. Use when the user writes /readonly.
---

# Readonly

Do not edit anything and do not run anything that changes state. Inspect and answer only.

## Trigger

User writes `/readonly`.

## Procedure

1. Read files, grep, and run read-only inspection commands only (`ls`, `cat`, `git status/log/diff`, `jj st/log`, `rg`).
2. Answer from what you found.

## Rules

- No file writes, no edits, no installs, no builds that write artifacts, no pushes, no network mutations.
- Stricter than `/ask` (which runs no commands at all): here shell is allowed, but only commands with zero side effects.
- If the task cannot be done read-only, say which step needs mutation and stop.
