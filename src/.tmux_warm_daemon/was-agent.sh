#!/usr/bin/env bash
# was-agent — registry of "agent workspaces" for the tmux warm daemon.
#
# Replaces the old marker+json scheme (touch $ws/.was_agent +
# /tmp/tmux_warm_agent_workspaces.json) with a sqlite db at
# ~/.cache/tmux_warm_daemon/was_agent.db, while still dual-writing the legacy
# json so the Rust daemon (and anything else reading it) keeps working.
#
# Subcommands:
#   mark <path>       register a workspace (sqlite upsert + legacy json append)
#   is-marked <path>  exit 0 if registered (sqlite, .was_agent file, or json)
#   list              registered paths, one per line (sqlite rows first, then
#                     legacy-json-only entries; deduplicated)
#   json              registered paths as a JSON array (feeds the bash daemon;
#                     same union as list)
#   hash <path>       8-char md5 prefix used for agent@<hash> session names
#
# Graceful degradation: without sqlite3, mark falls back to the legacy
# .was_agent marker file + json; list/json read the legacy json (python3).
# No `set -e` on purpose — a failing helper must degrade, not abort.

set -uo pipefail

DB_DIR="${HOME:-/tmp}/.cache/tmux_warm_daemon"
DB_FILE="$DB_DIR/was_agent.db"
# Legacy registry the Rust daemon still reads; TMPDIR-aware for sandboxing.
LEGACY_JSON="${TMPDIR:-/tmp}/tmux_warm_agent_workspaces.json"

# SQL string literal quoting (mirrors kv-store's _kv_sql_quote).
_wa_sql_quote() {
  printf "'%s'" "${1//\'/\'\'}"
}

# Resolve a usable sqlite3 binary. An explicitly-set WAS_AGENT_SQLITE3 wins
# (and if it is not executable, sqlite mode is off — test override semantics);
# otherwise PATH, then the brew locations (kv-store.sh-style fallback).
_wa_sqlite3() {
  if [ -n "${WAS_AGENT_SQLITE3:-}" ]; then
    [ -x "$WAS_AGENT_SQLITE3" ] || return 1
    printf '%s\n' "$WAS_AGENT_SQLITE3"
  elif command -v sqlite3 >/dev/null 2>&1; then
    command -v sqlite3
  elif [ -x /home/linuxbrew/.linuxbrew/bin/sqlite3 ]; then
    printf '%s\n' /home/linuxbrew/.linuxbrew/bin/sqlite3
  elif [ -x /opt/homebrew/bin/sqlite3 ]; then
    printf '%s\n' /opt/homebrew/bin/sqlite3
  else
    return 1
  fi
}

_wa_hash() {
  printf '%s' "$1" | md5sum | cut -c1-8
}

_wa_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# Append $1 to the legacy json (create if missing). Best-effort only: the
# sqlite write in cmd_mark must succeed even when this degrades.
_wa_legacy_json_append() {
  local path="$1"
  if [ -f "$LEGACY_JSON" ]; then
    grep -qF "\"$path\"" "$LEGACY_JSON" 2>/dev/null && return 0
    if command -v python3 >/dev/null 2>&1; then
      local tmp
      tmp="$(mktemp)" || return 0
      python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    ws = json.load(f)
ws.append(sys.argv[3])
with open(sys.argv[2], 'w') as f:
    json.dump(ws, f)
" "$LEGACY_JSON" "$tmp" "$path" 2>/dev/null && mv "$tmp" "$LEGACY_JSON" || rm -f "$tmp"
    fi
    # python3 missing: skip silently (creating is handled below; appending
    # a raw JSON array in pure bash is not worth the fragility).
  else
    printf '["%s"]\n' "$path" > "$LEGACY_JSON" 2>/dev/null || true
  fi
}

# Print legacy-json paths one per line (python3 only; silently empty without).
_wa_legacy_list() {
  [ -f "$LEGACY_JSON" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  python3 -c '
import json, sys
try:
    ws = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
for p in ws:
    print(p)
' "$LEGACY_JSON" 2>/dev/null
}

_wa_db_init() {
  local sqlite3="$1"
  mkdir -p "$DB_DIR" 2>/dev/null || true
  "$sqlite3" "$DB_FILE" 'CREATE TABLE IF NOT EXISTS workspaces (path TEXT PRIMARY KEY, h8 TEXT NOT NULL, marked_at INTEGER NOT NULL);' 2>/dev/null
}

_wa_db_list() {
  local sqlite3="$1"
  [ -f "$DB_FILE" ] || return 0
  "$sqlite3" -noheader "$DB_FILE" 'SELECT path FROM workspaces ORDER BY marked_at, path;' 2>/dev/null
}

_wa_print_json_array() {
  # Reads paths from stdin, prints a compact JSON array of strings.
  local out="[" p first=1
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ "$first" -eq 1 ]; then first=0; else out+=","; fi
    out+="\"$(_wa_json_escape "$p")\""
  done
  printf '%s]\n' "$out"
}

cmd_mark() {
  local path="$1" sqlite3 rc=0
  if sqlite3="$(_wa_sqlite3)"; then
    _wa_db_init "$sqlite3" || rc=1
    local q h now
    q="$(_wa_sql_quote "$path")"
    h="$(_wa_hash "$path")"
    now="$(date '+%s')"
    "$sqlite3" "$DB_FILE" "INSERT INTO workspaces(path, h8, marked_at) VALUES ($q, '$h', $now) ON CONFLICT(path) DO UPDATE SET h8 = excluded.h8, marked_at = excluded.marked_at;" 2>/dev/null || rc=1
  else
    # Legacy mode: per-dir marker file (in sqlite mode none is created).
    touch "$path/.was_agent" 2>/dev/null || true
  fi
  # Dual-write for the Rust daemon / old readers; degrades silently.
  _wa_legacy_json_append "$path"
  return "$rc"
}

cmd_is_marked() {
  local path="$1" sqlite3
  if sqlite3="$(_wa_sqlite3)" && [ -f "$DB_FILE" ]; then
    local q="$(_wa_sql_quote "$path")"
    if [ -n "$("$sqlite3" -noheader "$DB_FILE" "SELECT 1 FROM workspaces WHERE path = $q LIMIT 1;" 2>/dev/null)" ]; then
      return 0
    fi
  fi
  [ -f "$path/.was_agent" ] && return 0
  [ -f "$LEGACY_JSON" ] && grep -qF "\"$path\"" "$LEGACY_JSON" 2>/dev/null && return 0
  return 1
}

cmd_list() {
  local sqlite3 db_rows p
  if sqlite3="$(_wa_sqlite3)"; then
    # UNION output: sqlite rows first (preserving their ORDER BY), then
    # legacy-json entries not already present. Pre-was-agent registrations
    # live only in the legacy json and must keep feeding the daemon after
    # the first sqlite row lands. Legacy mode (no sqlite) is unchanged.
    db_rows="$(_wa_db_list "$sqlite3")"
    [ -n "$db_rows" ] && printf '%s\n' "$db_rows"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if [ -n "$db_rows" ] && printf '%s\n' "$db_rows" | grep -qxF -- "$p"; then
        continue
      fi
      printf '%s\n' "$p"
    done < <(_wa_legacy_list)
  else
    _wa_legacy_list
  fi
}

cmd_json() {
  cmd_list | _wa_print_json_array
}

usage() {
  cat >&2 <<'EOF'
Usage: was-agent <command> [args]
  mark <path>       register a workspace (sqlite + legacy json dual-write)
  is-marked <path>  exit 0 if the path is registered
  list              print registered paths, one per line (sqlite + legacy union)
  json              print registered paths as a JSON array
  hash <path>       print the 8-char md5 hash used for agent@<hash> names
EOF
}

[ $# -ge 1 ] || { usage; exit 2; }
cmd="$1"
shift

case "$cmd" in
  mark)      [ $# -eq 1 ] || { usage; exit 2; }; cmd_mark "$1" ;;
  is-marked) [ $# -eq 1 ] || { usage; exit 2; }; cmd_is_marked "$1" ;;
  list)      [ $# -eq 0 ] || { usage; exit 2; }; cmd_list ;;
  json)      [ $# -eq 0 ] || { usage; exit 2; }; cmd_json ;;
  hash)      [ $# -eq 1 ] || { usage; exit 2; }; _wa_hash "$1" ;;
  help|-h|--help) usage ;;
  *) usage; exit 2 ;;
esac
