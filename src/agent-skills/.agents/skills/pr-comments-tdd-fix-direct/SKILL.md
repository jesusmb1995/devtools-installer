---
name: pr-comments-tdd-fix-direct
description: Fix all open PR/MR review comments right here in this terminal via TDD, no sub-agents. Use when user writes /pr-comments-tdd-fix-direct <PR/MR URL>.
---

# pr-comments-tdd-fix-direct

Same goal as `team-pr-comments-tdd-fix-direct`, but no team: fix directly in this terminal, fast.

**Forge commands:** `system_assets` skill (`forge.md`). Reply skill: `/comment-reply`.

## Trigger

`/pr-comments-tdd-fix-direct <PR/MR URL>`

## Procedure

1. Fetch open/unresolved root comments (forge recipes). Zero survivors → stop.
2. Per comment, in id order:
   - `/tdd`: failing test first (red), confirm fail, minimal fix (green), confirm pass.
   - Keep red + green as separate commits/patches — never squash.
3. Run the broader relevant suite once at the end.
4. Ask before replying upstream; then `/comment-reply` per fixed comment.

## Rules

- Small queue only (1-3 comments). Bigger → use the `team-` variant.
- Skip verdict-`incorrect` / `already fixed` comments — say why, one line each.
