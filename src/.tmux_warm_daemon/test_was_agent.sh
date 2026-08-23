#!/usr/bin/env bash
# Integration test for was-agent (sqlite registry + legacy fallback).
# Sandboxes HOME and TMPDIR; never touches the real ~/.cache or /tmp json.
# Run: bash user/repos/tmux_warm_daemon/test_was_agent.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAS_AGENT_SRC="$HERE/was-agent.sh"

FAILURES=0
PASS() { printf 'PASS: %s\n' "$1"; }
FAIL() { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
EXPECT_OK() { if [ "$1" -eq 0 ]; then PASS "$2"; else FAIL "$2 (rc=$1)"; fi; }
EXPECT_FAIL() { if [ "$1" -ne 0 ]; then PASS "$2"; else FAIL "$2 (expected non-zero rc)"; fi; }

# ---------------------------------------------------------------------------
# Sqlite mode (forced via WAS_AGENT_SQLITE3 override)
# ---------------------------------------------------------------------------
SB="$(mktemp -d)"
export HOME="$SB/home"
mkdir -p "$HOME/.cache" "$HOME/.local/bin" "$SB/tmp"
export TMPDIR="$SB/tmp"
cp "$WAS_AGENT_SRC" "$HOME/.local/bin/was-agent"
chmod +x "$HOME/.local/bin/was-agent"
WAS_AGENT="$HOME/.local/bin/was-agent"

export WAS_AGENT_SQLITE3
WAS_AGENT_SQLITE3="$(command -v sqlite3 || echo /home/linuxbrew/.linuxbrew/bin/sqlite3)"

PROJ="$SB/proj a" # path with a space on purpose

# Empty registry must print exactly "[]" (the bash daemon treats that as
# empty and falls back to the legacy json file).
EMPTY_JSON="$("$WAS_AGENT" json 2>/dev/null)"
[ "$EMPTY_JSON" = "[]" ]
EXPECT_OK $? "sqlite mode: json prints [] for empty registry (daemon fallback sentinel)"

"$WAS_AGENT" mark "$PROJ" 2>/dev/null
EXPECT_OK $? "sqlite mode: mark exits 0"

"$WAS_AGENT" is-marked "$PROJ" 2>/dev/null
EXPECT_OK $? "sqlite mode: is-marked exits 0 for marked path"

"$WAS_AGENT" list 2>/dev/null | grep -qF "$PROJ"
EXPECT_OK $? "sqlite mode: list contains path"

JSON_OUT="$("$WAS_AGENT" json 2>/dev/null)"
if command -v python3 >/dev/null 2>&1; then
  python3 -c '
import json, sys
arr = json.loads(sys.argv[1])
assert sys.argv[2] in arr, "path not in json array"
' "$JSON_OUT" "$PROJ" 2>/dev/null
  EXPECT_OK $? "sqlite mode: json is a valid array containing the path"
else
  [ "$JSON_OUT" = "[\"$PROJ\"]" ]
  EXPECT_OK $? "sqlite mode: json literal array contains the path"
fi

HASH_GOT="$("$WAS_AGENT" hash "$PROJ")"
HASH_WANT="$(printf '%s' "$PROJ" | md5sum | cut -c1-8)"
[ "$HASH_GOT" = "$HASH_WANT" ]
EXPECT_OK $? "hash matches daemon formula (${HASH_GOT} vs ${HASH_WANT})"

[ -f "$HOME/.cache/tmux_warm_daemon/was_agent.db" ]
EXPECT_OK $? "sqlite mode: db file exists at \$HOME/.cache/tmux_warm_daemon/was_agent.db"

[ ! -f "$PROJ/.was_agent" ]
EXPECT_OK $? "sqlite mode: NO .was_agent file created in proj dir"

"$WAS_AGENT" mark "$PROJ" 2>/dev/null
EXPECT_OK $? "sqlite mode: second mark exits 0"
ROWS="$("$WAS_AGENT" list 2>/dev/null | wc -l)"
[ "$ROWS" -eq 1 ]
EXPECT_OK $? "sqlite mode: upsert keeps a single row (list | wc -l == ${ROWS})"

"$WAS_AGENT" is-marked "$SB/unmarked" 2>/dev/null
EXPECT_FAIL $? "sqlite mode: is-marked exits 1 for unmarked dir"

"$WAS_AGENT" json 2>/dev/null | grep -qF "$PROJ"
EXPECT_OK $? "sqlite mode: json (daemon feed) still contains path after upsert"

"$WAS_AGENT" 2>/dev/null
[ $? -eq 2 ]
PASS "no args exits 2 (usage error)"
"$WAS_AGENT" bogus-subcommand 2>/dev/null
[ $? -eq 2 ]
PASS "unknown subcommand exits 2 (usage error)"

# ---------------------------------------------------------------------------
# UNION: sqlite rows + legacy-only json entries merged in list/json
# (fresh sandbox so sqlite starts empty; the legacy json is pre-seeded with a
#  pre-was-agent registration that must keep feeding the daemon)
# ---------------------------------------------------------------------------
SB3="$(mktemp -d)"
UHOME="$SB3/home"
UTMP="$SB3/tmp"
mkdir -p "$UHOME/.local/bin" "$UTMP"
cp "$WAS_AGENT_SRC" "$UHOME/.local/bin/was-agent"
chmod +x "$UHOME/.local/bin/was-agent"
UWA="$UHOME/.local/bin/was-agent"
UENV=(HOME="$UHOME" TMPDIR="$UTMP" WAS_AGENT_SQLITE3="$WAS_AGENT_SQLITE3")

printf '["/old/ws"]\n' > "$UTMP/tmux_warm_agent_workspaces.json"

env "${UENV[@]}" "$UWA" mark /new/ws 2>/dev/null
EXPECT_OK $? "union: mark /new/ws exits 0 (first sqlite row lands)"

ULIST="$(env "${UENV[@]}" "$UWA" list 2>/dev/null)"
printf '%s\n' "$ULIST" | grep -qxF /old/ws
EXPECT_OK $? "union: list includes legacy-only /old/ws"
printf '%s\n' "$ULIST" | grep -qxF /new/ws
EXPECT_OK $? "union: list includes sqlite /new/ws"

UJSON="$(env "${UENV[@]}" "$UWA" json 2>/dev/null)"
python3 -c '
import json, sys
arr = json.loads(sys.argv[1])
assert "/old/ws" in arr, "legacy /old/ws missing from json array"
assert "/new/ws" in arr, "sqlite /new/ws missing from json array"
' "$UJSON" 2>/dev/null
EXPECT_OK $? "union: json (python3-validated) contains both entries"

env "${UENV[@]}" "$UWA" mark /old/ws 2>/dev/null
EXPECT_OK $? "union: mark /old/ws exits 0 (now in sqlite too)"
ULINES="$(env "${UENV[@]}" "$UWA" list 2>/dev/null | wc -l)"
[ "$ULINES" -eq 2 ]
EXPECT_OK $? "union: dedup keeps list at 2 lines (got ${ULINES})"

# ---------------------------------------------------------------------------
# Legacy mode (no sqlite3 reachable: bogus override + PATH stripped of brew)
# ---------------------------------------------------------------------------
SB2="$(mktemp -d)"
HOME2="$SB2/home2"
mkdir -p "$HOME2/.cache" "$HOME2/.local/bin" "$SB2/tmp" "$SB2/legacy proj"
cp "$WAS_AGENT_SRC" "$HOME2/.local/bin/was-agent"
chmod +x "$HOME2/.local/bin/was-agent"

REAL_JSON="/tmp/tmux_warm_agent_workspaces.json"
real_json_mtime_before=""
[ -f "$REAL_JSON" ] && real_json_mtime_before="$(stat -c %Y "$REAL_JSON" 2>/dev/null || printf 'x')"

(
  export HOME="$HOME2" TMPDIR="$SB2/tmp" WAS_AGENT_SQLITE3="/nonexistent"
  export PATH="/usr/bin:/bin"
  WA="$HOME2/.local/bin/was-agent"
  LP="$SB2/legacy proj"
  rc=0
  "$WA" mark "$LP" 2>/dev/null; [ $? -eq 0 ] && PASS "legacy mode: mark exits 0" || { FAIL "legacy mode: mark exits 0"; rc=1; }
  [ -f "$LP/.was_agent" ] && PASS "legacy mode: .was_agent file created in proj dir" || { FAIL "legacy mode: .was_agent file created in proj dir"; rc=1; }
  "$WA" is-marked "$LP" 2>/dev/null; [ $? -eq 0 ] && PASS "legacy mode: is-marked exits 0" || { FAIL "legacy mode: is-marked exits 0"; rc=1; }
  "$WA" json 2>/dev/null | grep -qF "$LP" && PASS "legacy mode: json contains path (read from legacy json)" || { FAIL "legacy mode: json contains path (read from legacy json)"; rc=1; }
  [ -f "$SB2/tmp/tmux_warm_agent_workspaces.json" ] && PASS "legacy mode: json lands under \$TMPDIR" || { FAIL "legacy mode: json lands under \$TMPDIR"; rc=1; }
  [ ! -f "$HOME2/.cache/tmux_warm_daemon/was_agent.db" ] && PASS "legacy mode: no db file created" || { FAIL "legacy mode: no db file created"; rc=1; }
  exit "$rc"
)
LEGACY_RC=$?

# Authoritative parent-side re-verification of the legacy-mode filesystem:
LEGACY_OK=1
[ -f "$SB2/legacy proj/.was_agent" ] || LEGACY_OK=0
[ -f "$SB2/tmp/tmux_warm_agent_workspaces.json" ] || LEGACY_OK=0
grep -qF "$SB2/legacy proj" "$SB2/tmp/tmux_warm_agent_workspaces.json" 2>/dev/null || LEGACY_OK=0
[ ! -f "$HOME2/.cache/tmux_warm_daemon/was_agent.db" ] || LEGACY_OK=0
[ "$LEGACY_OK" -eq 1 ] && [ "$LEGACY_RC" -eq 0 ]
EXPECT_OK $? "legacy mode: marker file + TMPDIR json + no db (parent-verified)"

# The real /tmp json (if it existed) must be untouched by the sandboxed run.
if [ -n "$real_json_mtime_before" ] && [ "$real_json_mtime_before" != "x" ]; then
  real_json_mtime_after="$(stat -c %Y "$REAL_JSON" 2>/dev/null || printf 'y')"
  [ "$real_json_mtime_before" = "$real_json_mtime_after" ]
  EXPECT_OK $? "legacy mode: real /tmp json untouched"
fi

# ---------------------------------------------------------------------------
# Daemon consumption (static): bash daemon references was-agent
# ---------------------------------------------------------------------------
grep -q "was-agent" "$HERE/bash/tmux_warm_daemon"
EXPECT_OK $? "bash daemon (bash/tmux_warm_daemon) references was-agent"

grep -q "was-agent" "$HERE/attach_warm.sh"
EXPECT_OK $? "attach_warm.sh references was-agent"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAILURES" -ne 0 ]; then
  printf 'FAILED: %d assertion(s)\n' "$FAILURES"
  printf 'Sandbox kept for inspection: %s / %s / %s\n' "$SB" "$SB2" "$SB3"
  exit 1
fi
printf 'ALL TESTS PASSED\n'
rm -rf "$SB" "$SB2" "$SB3"
exit 0
