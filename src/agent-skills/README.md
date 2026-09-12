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