---
name: run-upstream-ci
description: Manually trigger CI jobs on an already-pushed upstream branch. Use when the user asks to run, rerun, start, open, or watch CI for a branch, workflow, PR/MR, or pushed upstream branch.
compatibility: Read `system_assets` skill (`forge.md`) for CI recipes. Needs pushed branch + forge CI access.
---

# Run Upstream CI

**Forge commands:** `system_assets` skill (`forge.md`) (CI — list / trigger / watch).

## Goal

Manually start a CI workflow for an already-pushed upstream branch, then help the user open or watch the resulting run.

Never push commits, force-push, create branches, change upstream tracking, or overwrite remote state. If the branch is not already pushed, stop and ask the user to push it themselves.

## Workflow

1. Inspect branch + upstream (`git status`, `git rev-parse`, `@{u}`).
2. Confirm local is not ahead of upstream (`git rev-list --left-right --count @{u}...HEAD` → second number must be `0`).
3. Branch name for CI = upstream branch with remote prefix stripped.
4. List workflows when user did not name one (forge asset).
5. Trigger requested workflow on that branch (forge asset). Inspect inputs first if required.
6. Find the new run; open or watch (forge asset; optional local aliases `ciopen` / `ciwatch` if present).

## Safety Rules

- Do not mutate remote branch state.
- Ask before triggering if multiple workflows are plausible.
- Report run URL or watch command after trigger.
