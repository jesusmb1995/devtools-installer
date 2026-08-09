---
name: team-stg-last-patch-nonverbosecomments
description: Spawns parallel reviewer subagents to check the top StGit patch's description (using stg-last-patch-description) and code comments (using stg-last-patch-nonverbosecomments), and aggregates a patch of suggested changes. Use when asked to review or clean up the last StGit patch or its comments using a team of agents.
compatibility: Requires StGit with the `stg` command available.
---

# Team StGit Last Patch Comment & Description Reviewer

This skill orchestrates a parallel team of subagents to review both the description/commit message and the code comments of the whole stack of applied StGit patch. It generates proposed changes without modifying the working tree directly, presenting them to the user for approval.

## Workflow

### 1. Verification & Patch Discovery
- Confirm StGit is used by running:
  ```bash
  stg series
  ```
- Identify the target patches (all that appear on series). If not specified by the user, default to the top applied patch:
  ```bash
  stg top
  ```
- Retrieve the files modified by the patch:
  ```bash
  stg show --files
  ```
- Inspect the current patch description and complete diff:
  ```bash
  stg show
  ```

### 2. Spawn Subagents in Parallel
Use the `Task` tool with `run_in_background: true` to spawn:
1. **Description Reviewer Subagent**:
   - **Task**: Load the `/stg-last-patch-description` skill. Review the target patch's commit message/description. Propose a refined, concise commit message following the "Short imperative subject" and "Concise body explaining intent" format.
2. **File Comment Reviewer Subagents** (One per modified source file):
   - **Task**: Load the `/stg-last-patch-nonverbosecomments` skill. Inspect the specific file's changes inside the patch. Propose code comment removals or compressions to eliminate redundant or obvious comments while keeping high-value "Why" or API documentation.
   - **Output**: Each subagent must return a suggested diff (patch) or concrete list of comment edits for their assigned file.

### 3. Aggregate Suggestions & Present to User
Once all parallel subagents complete:
- Collect the proposed commit message improvements.
- Collect all suggested comment changes/diffs from the file subagents.
- Consolidate all the suggestions into a unified summary or patch.
- Present the choices to the user. Do not apply the changes automatically.
- Let the user decide which changes to accept. Apply only the approved changes (e.g. updating the patch description via `stg edit` or modifying the files and refreshing the patch with `stg refresh`).

## Rules for Subagents

### Description Subagent Rules
- Keep the subject short (<= 50 chars) and imperative.
- Explanatory body should be 1-3 short paragraphs or bullets.
- No verbose summaries or file lists.
- When invoked it rarely should end in no modifications at all. AI editing leaves many thins to be improved.

### File Comment Subagent Rules
- **Kill redundant comments**: Remove comments that repeat the code (e.g., `i++; // increment i`).
- **Kill obvious intent**: Drop comments where the code's purpose is already clear.
- **Keep API docs**: Retain public API documentation.
- **Keep "Why"**: Retain explanations of business logic, trade-offs, or weird hacks.
- **Keep warnings**: Retain warnings about side-effects.
