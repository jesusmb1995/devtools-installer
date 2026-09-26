---
name: pr-ok
description: Check if a PR/CL is ready — any open review comments? Skips format/lint/test (see /pr-checkok for the full check). Use when user writes /pr-ok <URL or id>.
---

# pr-ok

Readiness lite: comments only, no CI.

## Trigger

`/pr-ok <PR/CL URL or id>`

## Procedure

1. Any review comment still open/unresolved? (Read-only commands per `system_assets` `forge.md` — never paste tokens.)
2. Verdict: `OK — ready` or `NOT OK:` + the open threads.
3. Need format/lint/test too? That's `/pr-checkok`.
