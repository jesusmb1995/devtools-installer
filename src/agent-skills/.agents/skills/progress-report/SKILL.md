---
name: progress-report
description: Summarize developer activity into a concise daily progress report with task links and comments. Use when the user asks for a progress report, daily status, developer activity summary, or the "uncompact -> confirm -> compact + comments" workflow.
compatibility: Read `system_assets` skill (`forge.md`) and `system_assets` skill (`tasks.md`).
---

# Progress Report

**Assets:**
- Forge activity: `system_assets` skill (`forge.md`)
- Task tracker: `system_assets` skill (`tasks.md`)

## Goal

Create a daily developer activity report by reviewing recent forge activity first, then checking recent task-tracker comments, and matching activity to assigned tasks.

Follow this flow exactly: **uncompact -> confirm -> compact + comments**.

Never publish, post, or modify anything until the user confirms the uncompact draft and the exact write actions.

## Inputs

- Activity window: default last 18 hours unless user specifies.
- Tomorrow plan: user-provided, else infer from active tasks (explain inference).
- Upcoming time off: only if user provides.
- Blockers / risks: default `None` only when none found.
- Natural-language context from the skill invocation.

## Gather Activity

1. Inspect recent developer activity via forge asset (commits, PRs/MRs, reviews, comments).
2. Include relevant commits, PRs/MRs, reviews, and merged work.
3. Forge activity is primary; then task tracker for recent comments (tasks asset).
4. Use user natural language to guide matching and wording.
5. Find assigned/active tasks via tasks asset. Prefer subtask matches; keep parent attached; load custom fields/IDs when present.
6. Match forge + task activity by IDs in branches/PR titles/commits, direct links, or clear semantic match.
7. Reviewed PRs/MRs: extract task IDs from titles when present; resolve to tracker. Uncertain → label uncertain.
8. Uncertain task match → label in uncompact draft, never silent guess.

## Uncompact Draft

Before confirmation, show:

- Completed-today parents with task links, subtask links, matched forge links, exact comments to post
- Reviewed PRs/MRs with links, extracted IDs, match certainty
- Planned-tomorrow parents/subtasks + comments to post
- Unmatched forge activity, uncertain matches
- Compact HTML preview + temp file path + open command
- Exact write actions after confirmation

Structure:

```markdown
What I completed today:
- [TASK-ID](task-url) - [parent short outcome]
  Subtasks:
  - [Subtask](task-url) - [granular outcome]
  Forge: [PR/commit/comment links]
  Parent task comment to post: [...]
  Subtask comment(s) to post:
  - [Subtask]: [...]
- [Reviewed PR/MR](url) [TASK-ID](task-url) - [title]

What I plan to complete tomorrow:
- [TASK-ID](task-url) - [plan]
  ...

Blockers / risks: None
Upcoming time off: [only if provided]

Compact HTML preview:
[rich text HTML]

Temp preview (under the per-agent temp root — see `/tmp-agent-skill`):
- File: $AGENT_TMP/progress-report-YYYY-MM-DD.html
- Open with: xdg-open $AGENT_TMP/progress-report-YYYY-MM-DD.html

Write actions after confirmation:
- Post/update the compact progress report in [destination].
- Add the listed comments to each linked task.
```

## Compact HTML Report

After confirmation, concise HTML. Compact items: linked parent ID + linked child IDs only (project ID scheme from tasks asset). Reviewed items: link "Reviewed PR/MR" to forge URL + linked task ID. Write temp preview before asking confirm.

## Task Comments

Every report task gets a matching comment (parent summary + forge links; subtask granular). Combine completed+planned when clearer. Confirm each write action.

## Confirmation And Publishing

List exact posts. Only after confirm: publish compact report, create task comments, report back with links. If user changes draft, regenerate uncompact and re-confirm.
