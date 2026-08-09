#!/usr/bin/env bash
# bootstrap-warm-daemon.sh — run once after install to make pre-warmed agent
# sessions work out of the box.
#
# 1. Seed `agentclitool` from the nvim config default (M.default_tool in
#    ai_tools_config.lua) when unset, so agent-warm.sh launches the right tool
#    immediately. Never overrides an existing :AiSelect choice.
# 2. (Re)start tmux-warm-daemon so it loads config.yaml and registers the
#    `agent` pool — without this, nvim's <leader><C-l> can never attach because
#    no agent@<hash> / agent-N session is ever created.
set -u

# Load kv-store (kv / kv-put). Source kv-store.sh directly — do NOT source
# ~/.aliases, since some alias modules reference unguarded vars ($ZSH_VERSION)
# that abort the script under `set -u` and leave `kv` undefined.
for f in "${HOME}/aliases/kv-store.sh" "${HOME}/.local/bin/kv-store.sh"; do
  [ -f "$f" ] && { source "$f" 2>/dev/null || true; }
done

if command -v kv >/dev/null 2>&1; then
  existing="$(kv agentclitool 2>/dev/null)"
  if [ -z "${existing:-}" ]; then
    default="$(grep -E '^M.default_tool' "${HOME}/.config/nvim/lua/ai_tools_config.lua" 2>/dev/null \
               | sed -E 's/.*"([^"]+)".*/\1/')"
    if [ -n "${default:-}" ]; then
      kv-put agentclitool "${default}" 2>/dev/null || true
    fi
  fi
fi

# (Re)start the daemon so it picks up the pool config.
restart="${HOME}/.local/bin/restart_daemon.sh"
[ -x "$restart" ] && nohup "$restart" >/tmp/tmux_warm_daemon.bootstrap.log 2>&1 &
true
