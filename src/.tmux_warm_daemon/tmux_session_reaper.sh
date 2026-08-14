#!/usr/bin/env bash
# tmux_session_reaper.sh — lightweight idle-tmux-session reaper service.
#
# Periodically scans the tmux server for detached sessions that have had no
# activity for longer than the configured threshold (default 26h) and kills
# them, reclaiming forgotten/leaked sessions without touching anything in use.
#
# It is a separate process from tmux-warm-daemon on purpose: it never blocks or
# interferes with pre-warming. Each pass is one `tmux list-sessions` call plus a
# handful of `tmux kill-session` calls, then it sleeps idle_reaper_interval
# (default 1h) before the next pass. It never busy-loops and holds no tmux lock
# between passes.
#
# Conservative by design — a session is spared if ANY of these hold:
#   - it is currently attached (someone is looking at it);
#   - it is managed by a tmux-warm-daemon pool (name matches `<pool>-*` or
#     `<pool>@*` for any pool in config.yaml, e.g. warm-0, agent-3, agent@1a2b3c4d);
#   - its age cannot be determined (no activity/creation timestamp).
#
# "No activity / did not change" is measured as time since the most recent of:
#   - the session's last change = the MAX of #{window_activity} across its
#     windows (this advances on real output/keystrokes, even with the default
#     monitor-activity=off — verified). #{session_activity} is NOT used: it only
#     records activity bells an attached client observes and is otherwise frozen
#     at creation time, so it cannot tell a busy session from a dead one.
#   - last attach (#{session_last_attached});
#   - creation (#{session_created}), used only as a fallback.
# So a session started 30h ago that produced output 1h ago is measured by the
# 1h-ago change and spared; only one with no change/attach for > threshold is
# reaped.
#
# Settings are read from the same config.yaml as tmux-warm-daemon
# (~/.config/tmux_warm_daemon/config.yaml, or the path passed as $1) so a single
# file configures both. Unknown keys are ignored by the warm daemon, so adding
# the two reaper keys below is safe for the Rust and bash backends alike:
#   idle_reaper_hours:     26      # 0 disables the reaper
#   idle_reaper_interval:  3600    # seconds between passes
#
# Usage:
#   tmux_session_reaper.sh [config.yaml]   # run as a background service
#   tmux_session_reaper.sh --once [config.yaml]   # single pass, then exit
#
# Started (and stopped) alongside the warm daemon by restart_daemon.sh.
set -uo pipefail

DEFAULT_IDLE_HOURS=26
DEFAULT_INTERVAL=3600
DEFAULT_PID_FILE="/tmp/tmux_session_reaper.pid"
DEFAULT_LOG_FILE="/tmp/tmux_warm_daemon.log"
DEFAULT_CONFIG="${HOME:-/tmp}/.config/tmux_warm_daemon/config.yaml"

IDLE_HOURS="$DEFAULT_IDLE_HOURS"
INTERVAL="$DEFAULT_INTERVAL"
PID_FILE="$DEFAULT_PID_FILE"
LOG_FILE="$DEFAULT_LOG_FILE"
CONFIG_PATH="$DEFAULT_CONFIG"
POOL_NAMES=()
ONCE=0

# Re-exec flag set when daemonising so we don't loop.
DAEMONIZED="${REAPER_DAEMONIZED:-0}"

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------

print_usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--once] [config.yaml]
  --once   run a single reaper pass and exit (no daemonising)
Run with no flag to start the background reaper service.
EOF
}

for a in "$@"; do
  case "$a" in
    --once|-1) ONCE=1 ;;
    --daemonized) DAEMONIZED=1 ;;
    --help|-h) print_usage; exit 0 ;;
    -*) echo "unknown option: $a" >&2; print_usage; exit 2 ;;
    *) CONFIG_PATH="$a" ;;
  esac
done

# ---------------------------------------------------------------------------
# Helpers (mirror tmux-warm-daemon's conventions)
# ---------------------------------------------------------------------------

log() { printf '%s %s\n' "$(date '+%F %T')" "[reaper] $1" >>"$LOG_FILE"; }

strip_quotes() {
  local v="$1"
  case "$v" in
    \"*\") v="${v#\"}"; v="${v%\"}" ;;
    \'*\') v="${v#\'}"; v="${v%\'}" ;;
  esac
  printf '%s' "$v"
}

# Read only what the reaper needs from the warm-daemon config: the top-level
# idle_reaper_hours / idle_reaper_interval / pid_file / log_file scalars and the
# pool names under `pools:` (used only to spare managed sessions).
load_config() {
  local file="$1" in_pools=0 line trimmed nows indent key val
  if [ -f "$file" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    nows="${line%%[![:space:]]*}"
    trimmed="${line#"$nows"}"
    [ -z "$trimmed" ] && continue
    case "$trimmed" in '#'*) continue ;; esac
    indent=${#nows}

    if [ "$indent" -eq 0 ]; then
      in_pools=0
      key="${trimmed%%:*}"
      val="${trimmed#*:}"
      val="${val#"${val%%[![:space:]]*}"}"
      val="$(strip_quotes "$val")"
      case "$key" in
        idle_reaper_hours)    case "$val" in ''|*[!0-9]*) : ;; *) IDLE_HOURS="$val" ;; esac ;;
        idle_reaper_interval) case "$val" in ''|*[!0-9]*) : ;; *) INTERVAL="$val" ;; esac ;;
        pid_file) [ -n "$val" ] && PID_FILE="$val" ;;
        log_file) [ -n "$val" ] && LOG_FILE="$val" ;;
        pools) in_pools=1 ;;
      esac
      continue
    fi

    [ "$in_pools" -eq 1 ] || continue
    key="${trimmed%%:*}"
    val="${trimmed#*:}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="$(strip_quotes "$val")"
    # A bare `name:` (empty value) at the first indent level under `pools:`
    # starts a pool; its sessions are managed by the warm daemon and spared.
    if [ -z "$val" ]; then
      POOL_NAMES+=("$key")
    fi
  done <"$file"
  fi

  # Match the warm daemon's default-pool fallback so default `warm-N` sessions
  # are always spared even when the config file is absent/has no pools.
  if [ "${#POOL_NAMES[@]}" -eq 0 ]; then
    POOL_NAMES=("warm")
  fi
}

is_pool_session() {
  local name="$1" pool
  for pool in "${POOL_NAMES[@]+"${POOL_NAMES[@]}"}"; do
    case "$name" in
      "${pool}-"*) return 0 ;;
      "${pool}@"*) return 0 ;;
    esac
  done
  return 1
}

# Largest of the given epoch values, ignoring non-positive ones. Falls back to 0.
max_epoch() {
  local m=0 v
  for v in "$@"; do
    case "$v" in ''|*[!0-9]*) continue ;; esac
    [ "$v" -gt "$m" ] && m="$v"
  done
  printf '%s' "$m"
}

# Session's true "last changed" time = the MAX of #{window_activity} across its
# windows. Unlike #{session_activity} (frozen at creation unless an attached
# client sees an activity bell), per-window activity advances on real
# output/keystrokes with the default monitor-activity=off, so this is the
# reliable "did it change?" signal. Returns 0 if no windows / undeterminable.
session_last_change() {
  local s="$1" wa max=0
  while IFS= read -r wa; do
    case "$wa" in ''|*[!0-9]*) continue ;; esac
    [ "$wa" -gt "$max" ] && max="$wa"
  done < <(tmux list-windows -t "$s" -F '#{window_activity}' 2>/dev/null)
  printf '%s' "$max"
}

# ---------------------------------------------------------------------------
# The reaper pass — cheap, idempotent, non-blocking.
# ---------------------------------------------------------------------------

reap_pass() {
  command -v tmux >/dev/null 2>&1 || return 0
  local idle_threshold now killed=0
  case "$IDLE_HOURS" in ''|*[!0-9]*) IDLE_HOURS="$DEFAULT_IDLE_HOURS" ;; esac
  [ "$IDLE_HOURS" -gt 0 ] || return 0          # 0 => disabled
  case "$INTERVAL" in ''|*[!0-9]*) INTERVAL="$DEFAULT_INTERVAL" ;; esac
  idle_threshold=$(( IDLE_HOURS * 3600 ))
  now=$(date +%s)

  local name attached last_attached created last idle wa
  while IFS=$'\t' read -r name attached last_attached created; do
    [ -n "$name" ] || continue
    [ "$attached" = "0" ] || continue           # in use — never reap
    is_pool_session "$name" && continue         # warm-daemon managed — spared

    wa="$(session_last_change "$name")"          # last real output/change
    last="$(max_epoch "${wa:-0}" "${last_attached:-0}" "${created:-0}")"
    [ "$last" -gt 0 ] || continue               # indeterminate age — skip
    idle=$(( now - last ))
    if [ "$idle" -gt "$idle_threshold" ]; then
      if tmux kill-session -t "$name" 2>/dev/null; then
        killed=$(( killed + 1 ))
        log "killed idle session '$name' (idle $(( idle / 3600 ))h > ${IDLE_HOURS}h)"
      fi
    fi
  done < <(tmux list-sessions -F $'#{session_name}\t#{session_attached}\t#{session_last_attached}\t#{session_created}' 2>/dev/null)

  # Stay quiet when nothing happened so the shared log isn't spammed hourly.
  [ "$killed" -gt 0 ] && log "pass complete: reaped $killed session(s)"
}

# ---------------------------------------------------------------------------
# Daemonising + main loop
# ---------------------------------------------------------------------------

daemonize() {
  if [ "$DAEMONIZED" -ne 1 ]; then
    # Don't start a second instance if one is already alive.
    local old
    old="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then
      echo "reaper already running (PID $old)" >&2
      exit 0
    fi
    umask 0002
    REAPER_DAEMONIZED=1 setsid "$0" --daemonized "$CONFIG_PATH" \
      </dev/null >>"$LOG_FILE" 2>&1 &
    exit 0
  fi
}

if [ "$ONCE" -eq 1 ]; then
  load_config "$CONFIG_PATH"
  reap_pass
  exit 0
fi

daemonize
# Only the daemonised process reaches here.
umask 0002
cd /tmp || true
echo "$$" >"$PID_FILE"

load_config "$CONFIG_PATH"
log "started (reap detached idle > ${IDLE_HOURS}h every ${INTERVAL}s; sparing attached + pool sessions)"
reap_pass
while :; do
  sleep "$INTERVAL" &
  sp=$!
  wait "$sp" 2>/dev/null
  kill "$sp" 2>/dev/null
  reap_pass
done
