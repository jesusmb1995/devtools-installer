#!/usr/bin/env bash
# Attach to a pre-warmed tmux session from a named pool.
# Usage: attach_warm.sh [pool_name] [init_cmd] [workspace_path]
#   pool_name      defaults to "agent"
#   init_cmd       sent to the session before attaching (skipped if empty)
#                  defaults to "cd <current working directory>"
#   workspace_path if provided, try workspace-specific session (pool@hash) first
#
# CLEANLINESS GATE: a generic pool session is only picked when its pane looks
# idle/clean, so we never attach into something the user left running (btop,
# vim, ...). The check costs ONE extra `tmux list-panes -a -F` roundtrip
# replacing the old `list-sessions` one, and the attach path gains ZERO new
# sleeps — pick latency stays in the low-ms tmux-call range.
#   - pool "agent": expected content is an AI-agent session (agent CLI, its
#     node/python host, or the shell fallback), so we use a DENYLIST of other
#     interactive cli-tools (btop htop vim ...) — a whitelist would wrongly
#     reject the many agent-CLI process names we cannot enumerate.
#   - other pools (e.g. "warm"): expected content is JUST a shell prompt —
#     "terminals, not other cli-tools" — so anything outside the shell
#     whitelist (zsh bash sh dash fish) is dirty and skipped.
# The workspace-specific pool@<hash> session is exempt from the gate: if it
# exists detached it IS this workspace's session and is used regardless of
# pane content. init_cmd (typically `cd <dir>`) is only ever typed into a
# SHELL pane (same whitelist), so a running agent CLI / tool is never fed
# keystrokes; on other panes it is skipped with a stderr note.

set -euo pipefail

pool="${1:-agent}"
init_cmd="${2-cd $(printf '%q' "$PWD")}"
workspace="${3:-}"

session=""
was_agent=""
pane_cmd=""

pid=$(cat /tmp/tmux_warm_daemon.pid 2>/dev/null || true)

signal_daemon() {
  [ -n "$pid" ] && (sleep 1 && kill -USR1 "$pid" 2>/dev/null) &
}

if [ -n "$workspace" ]; then
  # Try workspace-specific session. NOTE: the was-agent mark is deliberately
  # DEFERRED until a session has been secured below — the failure paths here
  # (no warm session for this workspace / no pool session at all) must not
  # register the workspace.
  hash=$(printf '%s' "$workspace" | md5sum | cut -c1-8)
  ws_session="${pool}@${hash}"
  if tmux has-session -t "$ws_session" 2>/dev/null; then
    echo "Found session for ${hash}" >&2
    # Session exists — use it if detached
    session=$(tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null \
      | awk -v name="${ws_session}" '$1 == name && $2 == 0 { print $1; exit }')
  else
    echo "No warm session for workspace '${workspace}' (${hash}), signalling daemon" >&2
    [ -n "$pid" ] && kill -USR1 "$pid" 2>/dev/null || true
    exit 1
  fi
  # NOTE: no init_cmd clearing here anymore — the send-keys block below now
  # only types into SHELL panes, so a shell-fallback pool@<hash> session can
  # still receive its `cd`, while an agent-CLI pane is protected by the gate.
fi

# Fall back to any detached generic pool session (no workspace requested, or
# the workspace session is attached). CLEAN-AWARE pick instead of a blind
# first match: one list-panes roundtrip gives us both the candidate order and
# each pane's current command; dirty candidates are skipped in favor of the
# first clean one (see header for the pool-specific dirty rules).
if [ -z "$session" ]; then
  denylist="btop htop top gtop glances k9s lazygit lazydocker git vim nvim vi nano less more man fzf ssh"
  busy=""
  while IFS='|' read -r cand attached cmd _rest; do
    [ "$attached" = "0" ] || continue
    case "$cand" in
      "$pool"-*) ;;
      *) continue ;;
    esac
    if [ "$pool" = "agent" ]; then
      # Agent panes legitimately run the agent CLI or its node/python host,
      # so only OTHER interactive cli-tools make them dirty.
      case " $denylist " in
        *" $cmd "*) busy="$busy $cand:$cmd"; continue ;;
      esac
    else
      # Every other pool must look like a plain shell prompt.
      case "$cmd" in
        zsh|bash|sh|dash|fish) ;;
        *) busy="$busy $cand:$cmd"; continue ;;
      esac
    fi
    session="$cand"
    pane_cmd="$cmd"
    break
  done < <(tmux list-panes -a -F '#{session_name}|#{session_attached}|#{pane_current_command}|#{pane_current_path}' 2>/dev/null || true)

  if [ -z "$session" ] && [ -n "$busy" ]; then
    echo "No clean detached session in pool '${pool}' (busy:${busy}), signalling daemon" >&2
    signal_daemon
    exit 1
  fi
fi

if [ -z "$session" ]; then
  echo "No warm session available for pool '${pool}'" >&2
  exit 1
fi

# A session is secured for this workspace — NOW register it via was-agent
# (sqlite registry at ~/.cache/tmux_warm_daemon/was_agent.db + legacy json
# dual-write). Runs once for both the ws-session path and the generic-pool
# fallback path above.
if [ -n "$workspace" ]; then
  if [ -x "$HOME/.local/bin/was-agent" ]; then
    was_agent="$HOME/.local/bin/was-agent"
  elif [ -x "$HOME/.tmux_warm_daemon/was-agent.sh" ]; then
    was_agent="$HOME/.tmux_warm_daemon/was-agent.sh"
  fi

  if [ -n "$was_agent" ]; then
    "$was_agent" mark "$workspace" 2>/dev/null || true
  else
    # Legacy fallback (was-agent not deployed): inline marker + json append.
    if [ ! -f "$workspace/.was_agent" ]; then
      touch "$workspace/.was_agent"
    fi

    ws_file="/tmp/tmux_warm_${pool}_workspaces.json"
    if [ -f "$ws_file" ]; then
      if ! grep -qF "\"$workspace\"" "$ws_file" 2>/dev/null; then
        tmp=$(mktemp)
        python3 -c "
import json,sys
ws=json.load(open('$ws_file'))
ws.append('$workspace')
json.dump(ws,open('$tmp','w'))
" 2>/dev/null && mv "$tmp" "$ws_file" || rm -f "$tmp"
      fi
    else
      printf '["%s"]\n' "$workspace" > "$ws_file"
    fi
  fi
fi

# Type init_cmd ONLY into a shell pane: an agent CLI or any other running
# tool would misinterpret raw keystrokes (e.g. a `cd` line typed into an
# agent prompt). For the generic-pool pick the command is already known from
# the list-panes pass; for the pool@<hash> branch it takes ONE extra
# display-message lookup — only when there is actually something to type.
if [ -n "$init_cmd" ]; then
  if [ -z "$pane_cmd" ]; then
    pane_cmd=$(tmux display-message -p -t "$session" '#{pane_current_command}' 2>/dev/null || true)
  fi
  case "$pane_cmd" in
    zsh|bash|sh|dash|fish)
      tmux send-keys -t "$session" C-c
      sleep 0.1
      tmux send-keys -t "$session" "$init_cmd" Enter
      ;;
    *)
      echo "init_cmd skipped: pane running ${pane_cmd:-unknown}" >&2
      ;;
  esac
fi

if [ -t 1 ]; then
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
    signal_daemon
  else
    signal_daemon
    tmux attach -t "$session"
  fi
else
  # Non-interactive (e.g. vim.fn.system): print session name
  echo "$session"
  signal_daemon
fi
