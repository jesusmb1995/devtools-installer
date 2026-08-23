#!/usr/bin/env bash
# Integration test for attach_warm.sh's DEFERRED was-agent marking: the
# workspace is registered only AFTER a session has been secured, so the
# no-warm-session failure path must NOT mark.
#
# Sandboxes HOME and TMPDIR (was-agent deployed to $HOME/.local/bin, db +
# legacy json land inside the sandbox) and runs its own tmux server via
# TMUX_TMPDIR (attach_warm calls plain `tmux`, which honors it for the socket
# dir) — the real daemon, db and /tmp json are never touched.
# Run: bash user/repos/tmux_warm_daemon/test_attach_warm_mark.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATTACH="$HERE/attach_warm.sh"
WAS_AGENT_SRC="$HERE/was-agent.sh"

FAILURES=0
PASS() { printf 'PASS: %s\n' "$1"; }
FAIL() { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
EXPECT_OK() { if [ "$1" -eq 0 ]; then PASS "$2"; else FAIL "$2 (rc=$1)"; fi; }
EXPECT_FAIL() { if [ "$1" -ne 0 ]; then PASS "$2"; else FAIL "$2 (expected non-zero rc)"; fi; }

command -v tmux >/dev/null 2>&1 || { printf 'FAIL: tmux not found on PATH\n'; exit 1; }
command -v md5sum >/dev/null 2>&1 || { printf 'FAIL: md5sum not found on PATH\n'; exit 1; }
[ -f "$ATTACH" ] || { printf 'FAIL: attach_warm.sh not found: %s\n' "$ATTACH"; exit 1; }

SB="$(mktemp -d)"
export HOME="$SB/home"
export TMPDIR="$SB/tmp"
export TMUX_TMPDIR="$SB/tmux"
export WAS_AGENT_SQLITE3
WAS_AGENT_SQLITE3="$(command -v sqlite3 || echo /home/linuxbrew/.linuxbrew/bin/sqlite3)"
mkdir -p "$HOME/.local/bin" "$TMPDIR" "$TMUX_TMPDIR" "$SB/ws1" "$SB/ws2"
cp "$WAS_AGENT_SRC" "$HOME/.local/bin/was-agent"
chmod +x "$HOME/.local/bin/was-agent"
WAS_AGENT="$HOME/.local/bin/was-agent"

# attach_warm calls plain `tmux`; TMUX_TMPDIR points it at the sandbox socket.
T() { env -u TMUX TMUX_TMPDIR="$SB/tmux" tmux "$@"; }

cleanup() {
  T kill-server 2>/dev/null || true
  [ -n "${SB:-}" ] && rm -rf "$SB"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# 1. Failure path: no tmux server at all -> no agent@<hash> session ->
#    attach_warm exits 1 AND the workspace is NOT registered.
# ---------------------------------------------------------------------------
env -u TMUX bash "$ATTACH" agent '' "$SB/ws1" >/dev/null 2>&1
EXPECT_FAIL $? "failure path: attach_warm exits non-zero with no server"

env -u TMUX "$WAS_AGENT" is-marked "$SB/ws1" 2>/dev/null
EXPECT_FAIL $? "failure path: ws1 NOT marked (was-agent)"

[ ! -f "$SB/ws1/.was_agent" ]
EXPECT_OK $? "failure path: no .was_agent marker in ws1 (legacy fallback)"

# ---------------------------------------------------------------------------
# 2. Success path: detached agent@<hash> session for ws2 -> session secured
#    via the workspace branch -> ws2 IS registered. stdout is not a tty, so
#    attach_warm prints the session name and exits 0.
# ---------------------------------------------------------------------------
hash2="$(printf '%s' "$SB/ws2" | md5sum | cut -c1-8)"
T new-session -d -s "agent@${hash2}" >/dev/null 2>&1
EXPECT_OK $? "success path: sandbox server up with detached agent@${hash2}"

OUT="$(env -u TMUX bash "$ATTACH" agent '' "$SB/ws2" 2>/dev/null)"
EXPECT_OK $? "success path: attach_warm exits 0"

[ "$OUT" = "agent@${hash2}" ]
EXPECT_OK $? "success path: prints secured session name (got: ${OUT})"

env -u TMUX "$WAS_AGENT" is-marked "$SB/ws2" 2>/dev/null
EXPECT_OK $? "success path: ws2 IS marked (mark after session secured)"

[ ! -f "$SB/ws2/.was_agent" ]
EXPECT_OK $? "success path: sqlite mode (no .was_agent marker in ws2)"

# ---------------------------------------------------------------------------
# 3. No-workspace run on the generic pool succeeds but must not register
#    anything (mark block is guarded on $workspace).
# ---------------------------------------------------------------------------
T new-session -d -s agent-0 >/dev/null 2>&1
EXPECT_OK $? "guard: sandbox server has detached generic agent-0"

OUT2="$(env -u TMUX bash "$ATTACH" agent '' 2>/dev/null)"
EXPECT_OK $? "guard: no-workspace attach_warm exits 0 on generic pool"

[ "$OUT2" = "agent-0" ]
EXPECT_OK $? "guard: prints generic pool session (got: ${OUT2})"

MARKED_COUNT="$(env -u TMUX "$WAS_AGENT" list 2>/dev/null | wc -l)"
[ "$MARKED_COUNT" -eq 1 ]
EXPECT_OK $? "guard: registry still holds exactly the 1 marked ws (got ${MARKED_COUNT})"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAILURES" -ne 0 ]; then
  printf 'FAILED: %d assertion(s)\n' "$FAILURES"
  printf 'Sandbox kept for inspection: %s\n' "$SB"
  exit 1
fi
printf 'ALL TESTS PASSED\n'
exit 0
