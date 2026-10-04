# AGENTS.md (global)

Terminal dev box (gerpsonal): tmux-as-WM, jj (no git), nvim. Keep answers short. Check skills before acting — `ls ~/.agents/skills`, or `/recommend-skill`.

## Workspace peculiarities

One-liners; in depth: `/workspace-setup-peculiarities`.
- `cmdsave`/`cmdrun` for shell cmds; tmux default socket (WM is `-L wm`); jj `-agent`/`-secondary` siblings; notes in `~/projtmp`, `<leader>q*`, `/journal-dir-update`; drive nvim via `/nvim-control`, approvals via noice (`rules/nvim.md`).

## Responsiveness

- Task will take long: say so in one line, then keep working. Report state as it lands (done X, now doing Y), not only at the end.
- Anything answerable now gets answered now, even mid-task.
- Blocked: report the blocker + what unblocks it, then stop. Do not poll or busy-wait.
