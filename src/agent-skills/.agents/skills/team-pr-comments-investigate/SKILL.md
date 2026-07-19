---
name: team-pr-comments-investigate
description: Investigates all open/unresolved review comments on a PR/MR URL. Spawns one reviewer agent per comment, writes a .md report for each under $AGENT_TMP/<pr-title>/ (see /tmp-agent-skill). No code changes — analysis only.
compatibility: Read `system_assets` skill (`forge.md`). Needs forge access for the target repo.
---

# PR/MR Comments Investigator

Load `/tmp-agent-skill` for the canonical per-agent temp root (`$AGENT_TMP = /tmp/agent-<id>/`). All scratch files go there — never the `/tmp` root.

**Forge commands:** `system_assets` skill (`forge.md`) (fetch comments, unresolved threads).

Given a PR/MR URL, fetch all review comments, **filter down to only open and unresolved ones in the main agent**, then spawn a team of reviewers — one per surviving comment — to investigate each independently.

**No code changes. Investigation and reporting only.**

Each reviewer agent must load `/coding-preferences` at startup when present and apply it as the reference style when evaluating whether the reviewer's concern is valid.

## Steps

### 1. Parse the PR/MR URL

Extract host, owner/repo (or project path), and PR/MR number.

### 2. Fetch all review comments + title

Use forge asset recipes for list-comments and PR/MR title.

### 3. Filter to open/unresolved (main agent — before spawning)

Use forge asset unresolved-threads recipe. Keep only:
1. Root comments (not replies).
2. Thread not resolved and not outdated.
3. Associated file position (line present).

Log total vs survived. Zero survivors → stop, no agents.

### 4. Prepare output directory

Slug from title. Output: `$AGENT_TMP/{slug}/`.

### 5. Spawn a reviewer team

One agent per filtered comment in parallel. Each agent:
- Gets comment body, path, line, diff hunk.
- Follows `/review-comment-investigate` logic (read file, git history, verdict).
- Writes `$AGENT_TMP/{slug}/comment-{id}.md` with the template below.
- **Must not edit, stage, or commit any file.**

### 6. Report template

```markdown
# Comment #{id} — {file_path}:{line}

**Author:** {user}
**Posted:** {created_at}

## Original Comment

> {body}

## Diff Hunk

```diff
{diff_hunk}
```

## Investigation

{detailed analysis}

## Verdict

**{correct | partially correct | incorrect | already fixed}**

{one-paragraph explanation with file:line evidence and commit SHA}
```

### 7. Final summary

Print summary table: id / file / line / verdict. State count and output path.
