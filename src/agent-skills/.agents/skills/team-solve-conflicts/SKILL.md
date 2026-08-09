---
name: team-solve-conflicts
description: Resolve merge/rebase conflicts with a team of subagents. Reuses team-basic to fan out one subagent per conflicted file (or hunk), each summarizing why the conflict happened and how to resolve it. Master aggregates into a single table — per conflict the why, what current side has, what patch side introduces, the how-to-resolve, and whether it is straightforward or carries major risk. Use when a merge/rebase/cherry-pick hits conflicts and you want a structured resolution plan before editing.
---

# Team Solve Conflicts

Plan conflict fixes in parallel. Built on `team-basic` — reuse that harness for fan-out. This skill only define pieces + output table.

## Step 1: Find conflicts

```bash
git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'
git diff --name-only --diff-filter=U
```

Per conflicted file: grab markers (`<<<<<<<`, `=======`, `>>>>>>>`), both sides, base. Know operation (merge / rebase / cherry-pick) + which branches collide.

Pick slug (branch being merged). One piece = one file. File huge → split per-hunk.

## Step 2: Fan out via team-basic

Reuse `team-basic`: one subagent per file. Give each its file + both sides + what each branch try to do.

Each subagent summary `.md` (under `$AGENT_TMP/team-basic-<slug>/`, see `/tmp-agent-skill`) must answer:

```
# <file path>

## Why
Why conflict happen — what each side change, why they collide.

## Current side
What CURRENT/ours side hold here (the code, the intent).

## Patch side
What PATCH/theirs side introduce here (the code, the intent).

## How to resolve
Take ours / take theirs / merge both / rewrite. Show final code.

## Risk
straightforward  OR  major risk — with reason (semantic, lost logic, API change, data loss).

## Confidence
high / med / low.
```

Subagents analyze only — NO edit files unless user approve later.

## Step 3: Master evaluate

Per `team-basic` Step 4: read each summary, check against real markers + code, drop guesses, re-spawn weak pieces. Master must confirm resolution match both sides intent — semantic conflict hide behind clean merge.

## Step 4: Aggregate into resolution table

Master merge verified summaries into ONE table. "Current" + "Patch" columns let user spot the diff fast:

```markdown
| File | Why conflict | Current (ours) | Patch (theirs) | How to resolve | Risk | Confidence |
|---|---|---|---|---|---|---|
| src/auth.ts | both renamed login fn | `signIn()` + retry loop | `login()`, no retry | merge: keep theirs name + our retry | straightforward | high |
| db/schema.sql | both added migration | add `users.role` col | add `users.tier` col | rewrite: sequence both migrations | ⚠ major risk — order matters | med |
```

Keep Current/Patch cells short — just the diffing bit, not whole file. After table, call out each ⚠ major-risk row in 1-2 sentences (what break, what to verify), and list straightforward ones that apply mechanically.

## Step 5: Continue

Ask user: apply straightforward fixes now, and how handle each major-risk one. Edit files / `git add` / continue merge only after user confirm. Analysis read-only until then.

## What NOT do

- NO auto-resolve major-risk without user sign-off.
- NO edit conflicted files during analysis — plan first, table first.
- NO skip team-basic — reuse for fan-out, don't re-implement.
- NO present resolution master did not verify against real markers.
