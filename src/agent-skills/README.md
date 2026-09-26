# Cursor Skills

Agent skills for workflows I want to reuse across repositories.

## Install

Install from GitHub with the open skills CLI:

```bash
npx skills add <owner>/<repo>
```

For a local checkout while developing:

```bash
./install.sh
```

This installs all skills globally without prompting.

## Skills

- `gh-comment-reply`: drafts concise responses to GitHub comment URLs with reviewer-comment assessment and fix commit links.
- `gh-pr-comments-investigate`: investigates all open/unresolved review comments on a PR URL, spawning one reviewer agent per comment; writes a report per comment under `/tmp/<pr-title>/`. No code changes — analysis only.
- `gh-pr-comments-tdd-fix`: reads the reports from `gh-pr-comments-investigate`, spawns one named TDD agent per comment in an isolated git worktree (red repro patch + green fix patch each), exports `.patch` files, imports all successful patches into the real working tree via `stg`, then — after user confirmation — resumes the same agents (no new spawns) to `/gh-comment-reply` each original reviewer comment.
- `progress-report`: summarizes recent developer activity into a confirmed compact HTML progress report with per-task comments.
- `stg-last-patch-description`: reviews the top StGit patch and rewrites its message with concise short and long descriptions.
- `stg-series-descriptions`: reviews up to five StGit patches and rewrites patch messages with concise short and long descriptions.

## General-purpose

- `wrap-up`: summarize changed files, caveats, stop. No open questions.
- `per_patch`: group changes, commit per patch.
- `per_patch_fixups`: fix as a child patch on top, leave parent untouched, user squashes later.
- `fork-md [name]`: dump convo to `/tmp/fork-<name>.md`, uncompressed.
- `fork-md-use <name>`: restore a `/fork-md` snapshot into context.
- `plan-points`: turn the plan into short bullets.
- `explain-short-simple`: plain short explanation, no jargon.
- `commit`: stage + commit with a proper message. No push.
- `commit-push`: `commit` then push.
- `cmdsave [name]`: save last command as a project bookmark (cmd_bookmarks).
- `cmdrun [name] [-d]`: run a saved bookmark, deps first with `-d`.
- `do-task-from-md <path>`: run a task from a .md, log progress in a separate section of that file.
- `recommend-skills-plan <task>`: ordered plan of which skills to use first/second for the task.
- `gon`: continue the previous task; interruption was a mistake.
- `y`: answer yes to the pending question and go on.
- `review-stack-up`: check if current patch review comments apply thematically to sibling patches.
- `pr-comments-tdd-fix-direct <URL>`: TDD-fix open review comments here, no sub-agents.
- `pr-comments-fix-direct <URL>`: fix open review comments here directly, no TDD.
- `per_patch_fix_comments`: combo of `per_patch_fixups` + `pr-comments-fix-direct`.
- `add_ai_permissions <command>`: allow a command in the current agent's permissions config.
- `harden_ai_permissions_review`: read-only audit of the agent permissions config.
- `sub <what>`: run a task in a sub-agent, use its result.
- `side <what>`: side-task in a sub-agent while you keep focus; no deviation.
- `describe-conflicts`: compact conflict summary + full report in a tmp .md.
- `explain-min-example`: explain through a minimal example with concrete values.
- `clean-proposal <issue>`: short fix in chat + straight-to-point detail file.
- `dsum`: compact summary of recent changes with small snippets.
- `newtask <what>`: park current work in context, switch full focus to the new task.
- `readability_review_patch` / `readability_review_stack`: readability review of patch or stack; simpler, clearer, aux-lib suggestions.
- `split_with_diffeq <how>`: split a patch per instructions, verify splits sum to the original diff.
- `md-block`: re-emit markdown wrapped in a codeblock for clean copypaste.
- `pr-checkok <URL>`: full PR readiness — format, lint, tests, no open comments.
- `pr-ok <URL>`: PR readiness lite — open comments only, skips CI.
- `just-dpatch`: justify why the current patch is needed, summarized.
- `just-dstack`: justify why the whole stack is needed, per patch + through-line.