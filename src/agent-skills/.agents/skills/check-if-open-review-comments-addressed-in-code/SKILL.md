---
name: check-if-open-review-comments-addressed-in-code
description: Checks whether open/unresolved review comments on a PR/MR are already addressed in the current code. Verdict per comment: addressed / partially addressed / not addressed. No code changes.
compatibility: Read `system_assets` skill (`forge.md`). Needs forge access for the target repo.
---

# Check If Open Review Comments Are Addressed In Code

**Forge commands:** `system_assets` skill (`forge.md`) (fetch comments, unresolved threads, resolve, approve).

Given a PR/MR URL, fetch open/unresolved review comments and check whether each concern is already fixed in the working tree.

**No code changes. Read-only analysis.**

## Steps

### 1. Parse PR/MR URL

Extract host, owner/repo (or project path), PR/MR number.

### 2. Fetch review comments + title

Forge asset recipes.

### 3. Filter to open/unresolved (main agent only — before spawning)

Forge asset unresolved-threads recipe. Keep only: root comments whose thread is not resolved and not outdated, with a valid line.

Log total fetched vs. survived. If zero survive, stop.

### 4. For each open comment — check if addressed in code

Read the full file at `path`. Check:
- Is the concern raised in the comment still present in current code?
- Does git log/blame show a recent fix commit?

Verdict:
- **addressed** — concern is gone from current code, evidence present
- **partially addressed** — concern reduced but not fully resolved
- **not addressed** — concern still present as-is

### 5. Output summary table

```
PR/MR: {title} — {url}

| # | File | Line | Reviewer | Verdict |
|---|------|------|----------|---------|
| {id} | {path} | {line} | {user} | {verdict} |
```

For each non-addressed comment, print one line of evidence (file:line or commit).

### 6. Post-check actions (ask user)

After presenting the table, ask:

1. **Resolve threads** — for every `addressed` comment, offer resolve via forge asset.
2. **Approve PR/MR** — if all surviving comments addressed (or user resolved them), offer approve via forge asset.

Ask once, act only on user confirmation.
