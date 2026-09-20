---
name: pr-comments-fix-direct
description: Fix all open PR/MR review comments right here in this terminal, no TDD, no sub-agents. Use when user writes /pr-comments-fix-direct <PR/MR URL>.
---

# pr-comments-fix-direct

Like `/pr-comments-tdd-fix-direct` but no TDD: straight to the fix.

**Forge commands:** `system_assets` skill (`forge.md`). Reply skill: `/comment-reply`.

## Trigger

`/pr-comments-fix-direct <PR/MR URL>`

## Procedure

1. Fetch open/unresolved root comments (forge recipes). Zero survivors → stop.
2. Per comment, in id order: minimal fix, run the relevant test once.
3. Ask before replying upstream; then `/comment-reply` per fixed comment.

## Rules

- Trivial/mechanical comments only. Logic bugs → use `/pr-comments-tdd-fix-direct`.
- Small queue only (1-3 comments). Bigger → use the `team-` variant.
