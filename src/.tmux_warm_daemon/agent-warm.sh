#!/usr/bin/env bash
# Pre-warmed agent-session launcher, run by tmux-warm-daemon inside every
# `agent-N` / `agent@<hash>` session.
#
# It execs whichever agent CLI is currently selected via `kv agentclitool`
# (written by nvim's :AiSelect), so changing the default agent in nvim
# immediately affects the next pre-warmed session — nothing is hardcoded.
#
# tmux already starts each workspace session in the workspace dir (`-c "$ws"`),
# so this script ignores the daemon's trailing `--workspace <path>` argument;
# only the cursor `agent` CLI understands that flag, and it's redundant for
# cwd-aware tools.

set -u

# Load the kv-store functions (kv / kv-put) directly. Do NOT source
# ~/.aliases here: some alias modules (e.g. ci.sh/git.sh) reference vars like
# $ZSH_VERSION unguarded, which aborts the whole script under `set -u` and
# leaves `kv` undefined. Sourcing kv-store.sh alone is enough.
for f in "${HOME}/aliases/kv-store.sh" "${HOME}/.local/bin/kv-store.sh"; do
  [ -f "$f" ] && { source "$f" 2>/dev/null || true; }
done

# Resolve a usable sqlite3 binary for kv (mirrors kv-store.sh's fallback, since
# this runs in a non-interactive tmux session where brew's bin may be absent).
_kv_sqlite3() {
  if command -v sqlite3 >/dev/null 2>&1; then echo sqlite3
  elif [ -x /home/linuxbrew/.linuxbrew/bin/sqlite3 ]; then echo /home/linuxbrew/.linuxbrew/bin/sqlite3
  else return 1; fi
}

tool=""
if command -v kv >/dev/null 2>&1; then
  tool="$(kv agentclitool 2>/dev/null)"
fi

# Drop the daemon's trailing --workspace <path> (and any args); the cwd is
# already correct via tmux -c. Only exec the tool if it's actually installed.
if [ -n "$tool" ] && command -v "$tool" >/dev/null 2>&1; then
  exec "$tool"
fi

# Nothing selected (or not installed): fall back to a plain shell so the
# session stays usable; :AiSelect + a daemon USR1 will pre-warm a real tool.
exec "${SHELL:-/bin/bash}"
