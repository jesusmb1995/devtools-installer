# Task tracker recipes

Path after install: `~/.agents/skills/system_assets/tasks.md` (catalog skill: `system_assets`).
Used by `/progress-report` and any skill that links work to tracked tasks.


## Tracker: adaptive (discover)

No task MCP pinned at generate time.

### 1. Discover what exists
```bash
# MCP / agent tools for task trackers present in this session
# Project files: AGENTS.md, CONTRIBUTING, issue tracker URLs in README
git log --oneline -20
git branch --show-current
```

### 2. Prefer order
1. MCP/task tools actually available in this session
2. Issue IDs found in branch names / commit messages / PR titles
3. User-supplied task list or paste
4. Local notes only (say so)

### 3. Rules
- Never hard-require a specific vendor tracker if tools absent.
- Match activity → tasks by ID token, URL, or clear semantic match.
- Uncertain match → label uncertain in draft.
- Post/update comments only after user confirms exact write actions.
- Identifier format is whatever the project uses (not a fixed vendor prefix).


