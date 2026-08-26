#!/usr/bin/env bash
# Host test for the clean-aware warm-session pick in the forked oh-my-zsh
# tmux plugin (plugins/tmux/tmux.plugin.zsh):
#   * _zsh_tmux_warm_pick   — first DETACHED warm-* session whose pane sits
#     at a plain shell prompt; sessions running another cli-tool (btop, ...)
#     are skipped; attached/other-pool sessions never match.
#   * _zsh_tmux_pane_is_shell — shell-pane detection gating the `cd`
#     send-keys correction.
#
# Sandboxes the tmux server via TMUX_TMPDIR (pattern: tmux_warm_daemon's
# test_attach_warm_mark.sh); the real server is never touched.
# Run: bash user/repos/omz_config/plugins/tmux/test_warm_pick.sh

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$HERE/tmux.plugin.zsh"

FAILURES=0
PASS() { printf 'PASS: %s\n' "$1"; }
FAIL() { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
EXPECT_OK() { if [ "$1" -eq 0 ]; then PASS "$2"; else FAIL "$2 (rc=$1)"; fi; }
EXPECT_FAIL() { if [ "$1" -ne 0 ]; then PASS "$2"; else FAIL "$2 (expected non-zero rc)"; fi; }

command -v tmux >/dev/null 2>&1 || { printf 'FAIL: tmux not found on PATH\n'; exit 1; }
command -v zsh >/dev/null 2>&1 || { printf 'FAIL: zsh not found on PATH\n'; exit 1; }
[ -f "$PLUGIN" ] || { printf 'FAIL: plugin not found: %s\n' "$PLUGIN"; exit 1; }

SB="$(mktemp -d)"
export TMUX_TMPDIR="$SB/tmux"
mkdir -p "$TMUX_TMPDIR" "$SB/bin"

# Fake cli-tool: pane_current_command reads argv[0], so `exec -a` makes the
# pane report the tool's name while the process is really just sleep (same
# trick as tmux_warm_daemon/test_attach_warm_clean.sh).
cat >"$SB/bin/btop" <<'EOF'
#!/usr/bin/env bash
exec -a btop sleep 600
EOF
chmod +x "$SB/bin/btop"

cleanup() {
  env -u TMUX TMUX_TMPDIR="$SB/tmux" tmux kill-server 2>/dev/null || true
  [ -n "${SB:-}" ] && rm -rf "$SB"
}
trap cleanup EXIT

# attach/pick helpers run plain `command tmux`, which honors TMUX_TMPDIR.
T() { env -u TMUX TMUX_TMPDIR="$SB/tmux" PATH="$SB/bin:$PATH" tmux "$@"; }
Z() { env -u TMUX TMUX_TMPDIR="$SB/tmux" PATH="$SB/bin:$PATH" zsh -f -c "$1"; }

# Load the plugin (autostart off: we drive the helpers directly) and make
# sure the two helper functions actually exist.
Z "ZSH_TMUX_AUTOSTART=false; source '$PLUGIN' >/dev/null 2>&1; (( \$+functions[_zsh_tmux_warm_pick] )) && (( \$+functions[_zsh_tmux_pane_is_shell] ))"
EXPECT_OK $? "plugin sources cleanly and defines the warm-pick helpers"

# ---------------------------------------------------------------------------
# 1. warm-0 dirty (btop) + warm-1 clean (bash): pick skips the tool session.
# ---------------------------------------------------------------------------
T new-session -d -s warm-0 "$SB/bin/btop" >/dev/null 2>&1
EXPECT_OK $? "setup: warm-0 running fake btop"
T new-session -d -s warm-1 /bin/bash >/dev/null 2>&1
EXPECT_OK $? "setup: warm-1 running bash"
sleep 0.3 # let panes settle so pane_current_command reports the real process

GOT="$(Z "ZSH_TMUX_AUTOSTART=false; ZSH_TMUX_WARM_SESSION_PREFIX=warm; source '$PLUGIN' >/dev/null 2>&1; _zsh_tmux_warm_pick")"
[ "$GOT" = "warm-1" ]
EXPECT_OK $? "dirty warm-0 skipped, clean warm-1 picked (got: ${GOT})"

# ---------------------------------------------------------------------------
# 2. All warm sessions dirty -> empty pick (caller falls back to plain attach).
# ---------------------------------------------------------------------------
T new-session -d -s warm-2 "$SB/bin/btop" >/dev/null 2>&1
T kill-session -t warm-1 >/dev/null 2>&1
sleep 0.3

GOT="$(Z "ZSH_TMUX_AUTOSTART=false; ZSH_TMUX_WARM_SESSION_PREFIX=warm; source '$PLUGIN' >/dev/null 2>&1; _zsh_tmux_warm_pick")"
[ -z "$GOT" ]
EXPECT_OK $? "all-dirty pool yields empty pick (got: '${GOT}')"

# ---------------------------------------------------------------------------
# 3. Other pools never match the warm pick: a CLEAN detached agent-0 (bash)
#    exists while every warm-* session is dirty -> pick stays empty, proving
#    the prefix filter. (Attached-session skipping is enforced by the same
#    `$2 == 0` term as the daemon-side pick, exercised in
#    tmux_warm_daemon/test_attach_warm_clean.sh.)
# ---------------------------------------------------------------------------
T new-session -d -s agent-0 /bin/bash >/dev/null 2>&1
sleep 0.3

GOT="$(Z "ZSH_TMUX_AUTOSTART=false; ZSH_TMUX_WARM_SESSION_PREFIX=warm; source '$PLUGIN' >/dev/null 2>&1; _zsh_tmux_warm_pick")"
[ -z "$GOT" ]
EXPECT_OK $? "clean agent-0 ignored by the warm pick (got: '${GOT}')"

# A clean detached warm session IS picked again once one exists.
T new-session -d -s warm-3 /bin/bash >/dev/null 2>&1
sleep 0.3

GOT="$(Z "ZSH_TMUX_AUTOSTART=false; ZSH_TMUX_WARM_SESSION_PREFIX=warm; source '$PLUGIN' >/dev/null 2>&1; _zsh_tmux_warm_pick")"
[ "$GOT" = "warm-3" ]
EXPECT_OK $? "clean detached warm-3 picked once it exists (got: ${GOT})"

# ---------------------------------------------------------------------------
# 4. _zsh_tmux_pane_is_shell: bash -> true, btop -> false, missing -> false.
# ---------------------------------------------------------------------------
Z "ZSH_TMUX_AUTOSTART=false; source '$PLUGIN' >/dev/null 2>&1; _zsh_tmux_pane_is_shell warm-3"
EXPECT_OK $? "pane_is_shell: bash session is a shell"

Z "ZSH_TMUX_AUTOSTART=false; source '$PLUGIN' >/dev/null 2>&1; _zsh_tmux_pane_is_shell warm-0"
EXPECT_FAIL $? "pane_is_shell: btop session is NOT a shell"

Z "ZSH_TMUX_AUTOSTART=false; source '$PLUGIN' >/dev/null 2>&1; _zsh_tmux_pane_is_shell no-such-session"
EXPECT_FAIL $? "pane_is_shell: missing session is NOT a shell"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$FAILURES" -ne 0 ]; then
  printf 'FAILED: %d assertion(s)\n' "$FAILURES"
  exit 1
fi
printf 'ALL TESTS PASSED\n'
exit 0
