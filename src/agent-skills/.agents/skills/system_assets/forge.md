# Forge recipes (code host)

Path after install: `~/.agents/skills/system_assets/forge.md` (catalog skill: `system_assets`).
Skills under `~/.agents/skills/*/SKILL.md` point here for host-specific commands.


## Host: adaptive (discover)

No forge feature pinned at generate time. Discover what this machine and repo can do — do not assume any specific vendor tool.

### Discover
- Inspect the repo itself for remotes and branches:
  ```bash
  git remote -v
  git rev-parse --abbrev-ref HEAD
  git rev-parse --abbrev-ref --symbolic-full-name @{u}
  ```
- Look for a forge / source-control tool available in the environment: a CLI on
  PATH, an MCP server, or a service the host exposes. An *appropriate* tool is
  anything that can read PRs/MRs, their review comments, and CI runs for this repo,
  and (when the user confirms) post comments or trigger CI.

### Operate without assuming a tool
- Prefer read-only local inspection (`git log`, `git diff`, `stg show`) when no
  forge tool is available.
- Name the action you need (fetch PR context, post a comment, trigger CI) and let
  the environment supply the matching tool. Do not invent host-specific commands
  that are not present on PATH or reachable from here.
- If an action needs write access you cannot perform, state what is missing and ask
  the user for the URL, credentials, or the tool to use.

### Rules
- Never hard-require a specific vendor tool.
- Never post or mutate remote state without explicit user confirmation.
- Fall back to read-only git + local files when nothing else is available.


