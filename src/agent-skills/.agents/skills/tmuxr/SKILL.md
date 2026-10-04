---
name: tmuxr
description: Minimal tmux runner for agent shells — run a command in a detached session and read its output back. Use when user writes /tmuxr, asks to run something in tmux, or needs output from a background shell.
---

# tmuxr

Three commands cover nearly everything. Bare `tmux` hits the default socket (warm daemon) — correct from agent shells; the outer WM lives on `-L wm`, never touch it from here.

```bash
tmuxr <session> <cmd...>   # run detached, print captured output when done
```

Recipe (this is all `tmuxr` does):

```bash
tmux new-session -d -s <session> "<cmd...>"   # detached run
sleep <n>                                      # let it finish (short cmds: 2-5s)
tmux capture-pane -t <session> -p              # read output back
tmux kill-session -t <session>                 # cleanup, always
```

Long tasks: poll with `capture-pane -p | tail` + sleeps, never block forever. Name sessions `<what>-<id>` so reruns do not collide. Kill the session when done — detached leftovers pile up.
