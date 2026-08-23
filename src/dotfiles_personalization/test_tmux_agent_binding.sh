#!/usr/bin/env bash
# Integration test for the C-b c agent-window binding in .tmux.conf.
#
# Runs an ISOLATED tmux server (-L socket) with the repo's .tmux.conf:
#   1. static check: `list-keys -T prefix c` must mention agent-warm.sh;
#   2. behavioral check: on a fake HOME with an executable
#      ~/.local/bin/agent-warm.sh stub, the binding is driven for REAL by
#      attaching a tmux client inside the session's own pane and injecting
#      `C-b c` with send-keys (plain send-keys to a shell pane would not hit
#      the binding; the in-pane client makes tmux interpret the prefix).
#      The stub writes a marker file -> proves the if-shell took the
#      agent-warm.sh branch and the new window is named "agent".
# If the in-pane client cannot attach (unreliable in this env), the test
# falls back to inspecting the bound command reported by list-keys.
# Run: bash user/repos/dotfiles_personalization/test_tmux_agent_binding.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$HERE/.tmux.conf"

FAILURES=0
PASS() { printf 'PASS: %s\n' "$1"; }
FAIL() { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

command -v tmux >/dev/null 2>&1 || { printf 'FAIL: tmux not found on PATH\n'; exit 1; }
[ -f "$CONF" ] || { printf 'FAIL: conf not found: %s\n' "$CONF"; exit 1; }

S="agentbind$$"
FAKE_HOME=""
cleanup() {
  tmux -L "$S" kill-server 2>/dev/null || true
  [ -n "$FAKE_HOME" ] && rm -rf "$FAKE_HOME"
}
trap cleanup EXIT

# --- 1. Static: the binding must reference agent-warm.sh ----------------------
env -u TMUX tmux -L "$S" -f "$CONF" new-session -d -s t >/dev/null 2>&1
if [ $? -ne 0 ]; then
  FAIL "isolated server starts with $CONF"
  printf 'FAILED: %d assertion(s)\n' "$FAILURES"
  exit 1
fi
PASS "isolated server starts with $CONF"

BIND_OUT="$(env -u TMUX tmux -L "$S" list-keys -T prefix c 2>/dev/null)"
case "$BIND_OUT" in
  *agent-warm.sh*) PASS "list-keys -T prefix c contains agent-warm.sh" ;;
  *) FAIL "list-keys -T prefix c contains agent-warm.sh (got: $BIND_OUT)" ;;
esac

BIND_OUT_BRANCHES="$(env -u TMUX tmux -L "$S" list-keys -T prefix c 2>/dev/null | grep -o 'new-window' | wc -l)"
[ "$BIND_OUT_BRANCHES" -eq 2 ]
if [ $? -eq 0 ]; then PASS "binding has both branches (agent + plain new-window)"; else FAIL "binding has both branches (agent + plain new-window); got $BIND_OUT_BRANCHES"; fi

env -u TMUX tmux -L "$S" kill-server 2>/dev/null || true

# --- 2. Behavioral: drive the real binding on a fake HOME ---------------------
FAKE_HOME="$(mktemp -d)"
mkdir -p "$FAKE_HOME/.local/bin"
cat > "$FAKE_HOME/.local/bin/agent-warm.sh" <<STUB
#!/bin/sh
echo ran > "$FAKE_HOME/stub-ran"
exec sleep 60
STUB
chmod +x "$FAKE_HOME/.local/bin/agent-warm.sh"

# Session t's pane runs a client of its own server; keys sent to the pane are
# interpreted by that client, so send-keys C-b c exercises the real binding.
env -u TMUX HOME="$FAKE_HOME" tmux -L "$S" -f "$CONF" \
  new-session -d -s t "env -u TMUX tmux -L $S attach" >/dev/null 2>&1
sleep 1
env -u TMUX tmux -L "$S" send-keys -t t C-b c 2>/dev/null
sleep 1

MARKER="$FAKE_HOME/stub-ran"
if [ -f "$MARKER" ]; then
  PASS "C-b c ran agent-warm.sh stub (marker file written)"
else
  FAIL "C-b c ran agent-warm.sh stub (marker file missing)"
fi

WINDOWS="$(env -u TMUX tmux -L "$S" list-windows -t t -F '#W' 2>/dev/null)"
case "$WINDOWS" in
  *agent*) PASS "new window is named 'agent' (windows: $(echo $WINDOWS | tr '\n' ' '))" ;;
  *) FAIL "new window is named 'agent' (windows: $(echo $WINDOWS | tr '\n' ' '))" ;;
esac

if [ ! -f "$MARKER" ]; then
  printf 'NOTE: behavioral send-keys path failed; falling back to command inspection only\n'
fi

if [ "$FAILURES" -ne 0 ]; then
  printf 'FAILED: %d assertion(s)\n' "$FAILURES"
  exit 1
fi
printf 'ALL TESTS PASSED\n'
exit 0
