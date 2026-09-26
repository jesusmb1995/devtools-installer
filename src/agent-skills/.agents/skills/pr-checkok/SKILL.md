---
name: pr-checkok
description: Double-check a PR/CL is green and clean — formatting, lint, tests passed, no open comments. Use when user writes /pr-checkok <URL or id>.
---

# pr-checkok

Full readiness check. Nothing skipped.

## Trigger

`/pr-checkok <PR/CL URL or id>`

## Procedure

1. Formatting clean? Lint clean? Tests passed? Check CI status (see `system_assets` `forge.md` for the read-only commands — never paste tokens).
2. Any review comment still open/unresolved? List them.
3. Verdict: `OK — ready` or `NOT OK:` + the exact blockers. No guessing — every claim backed by command output.
