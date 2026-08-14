#!/usr/bin/env bash
set -euo pipefail

PIDFILE="/tmp/tmux_warm_daemon.pid"
# Backend-agnostic entrypoint: picks the Rust binary or the bash daemon,
# whichever the chosen config deployed.
BINARY="$HOME/.tmux_warm_daemon/tmux_warm_daemon"

pid=$(cat "$PIDFILE" 2>/dev/null || true)
if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
  kill "$pid"
  echo "Killed old daemon (PID $pid)"
else
  echo "No running daemon found"
fi

"$BINARY"
sleep 0.2
new_pid=$(cat "$PIDFILE" 2>/dev/null || true)
echo "Started new daemon (PID $new_pid)"

# Also (re)start the idle-session reaper alongside the warm daemon. It is a
# separate, non-blocking process that only wakes every idle_reaper_interval to
# scan; killing it here ensures we never accumulate duplicate reapers. Best
# effort: a missing binary or no tmux must never fail the restart above.
REAPER_PIDFILE="/tmp/tmux_session_reaper.pid"
REAPER_BIN=""
for c in "$HOME/.local/bin/tmux_session_reaper.sh" "$HOME/.tmux_warm_daemon/tmux_session_reaper.sh"; do
  [ -x "$c" ] && { REAPER_BIN="$c"; break; }
done
if [ -n "$REAPER_BIN" ]; then
  rpid="$(cat "$REAPER_PIDFILE" 2>/dev/null || true)"
  if [ -n "$rpid" ] && kill -0 "$rpid" 2>/dev/null; then
    kill "$rpid" 2>/dev/null || true
    # Wait for the old reaper to actually exit so the new one's "already
    # running" guard doesn't refuse to start (guards against a not-yet-reaped
    # PID). Bounded so this never blocks the restart.
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      kill -0 "$rpid" 2>/dev/null || break
      sleep 0.1
    done
    echo "Killed old reaper (PID $rpid)"
  fi
  nohup "$REAPER_BIN" >/tmp/tmux_session_reaper.bootstrap.log 2>&1 &
  echo "Started session reaper"
else
  echo "Session reaper binary not found; skipping"
fi
