#!/bin/bash

# remote-nvim: connect to a remote host's Neovim over an SSH tunnel.
#
# Usage:
#   remote-nvim <user@host>[:<port>]
#   remote-nvim <user@host>            # port defaults to $REMOTE_NVIM_PORT (45678)
#
# Flow:
#   1. Open (or reuse) an SSH local forward  <port>:localhost:<port>.
#   2. On the remote, kill any leaked server on <port> then start
#      nvim --headless --listen 127.0.0.1:<port>.
#   3. Poll until the remote server answers, then attach a local
#      nvim --clean --server localhost:<port> --remote-ui.
#   4. On exit (normal or interrupted), tear down the remote server and tunnel.
#
# Robustness: a per-port ControlPath makes the forward idempotent; the launch
# step clears stale/leaked servers on that port before binding; cleanup is
# explicit + signal-trapped so crashed trials don't leak.

REMOTE_NVIM_PORT="${REMOTE_NVIM_PORT:-45678}"

remote-nvim() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: remote-nvim <user@host>[:<port>]  (default ${REMOTE_NVIM_PORT})" >&2
    return 1
  fi

  local target="$1"
  local host="${target%%:*}"
  local port="${target#*:}"
  if [[ "$port" == "$target" || -z "$port" ]]; then
    port="${REMOTE_NVIM_PORT}"
  fi
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "remote-nvim: invalid port '${port}'" >&2
    return 1
  fi

  local ctrl_path="${HOME}/.ssh/remote-nvim-${port}.sock"
  local _rn_cleaned=0

  _remote_nvim_cleanup() {
    (( _rn_cleaned )) && return 0
    _rn_cleaned=1
    ssh -o ControlPath="${ctrl_path}" "${host}" \
      "pkill -f 'nvim --headless --listen 127.0.0.1:${port}' 2>/dev/null" 2>/dev/null
    ssh -o ControlPath="${ctrl_path}" -O exit "${host}" 2>/dev/null
    rm -f "${ctrl_path}"
  }
  trap '_remote_nvim_cleanup' INT TERM

  # --- 1. idempotent forward (reuse if alive, else establish fresh) ----------
  if ssh -o ControlPath="${ctrl_path}" -O check "${host}" 2>/dev/null; then
    echo "remote-nvim: reusing forward on port ${port}." >&2
  else
    rm -f "${ctrl_path}"
    ssh -f -N \
      -o ControlMaster=auto \
      -o ControlPath="${ctrl_path}" \
      -o ControlPersist=yes \
      -o ExitOnForwardFailure=yes \
      -L "${port}:localhost:${port}" \
      "${host}" || {
        echo "remote-nvim: failed to open SSH forward to ${host}:${port}" >&2
        trap - INT TERM
        return 1
      }
  fi

  # --- 2. remote headless server (port-scoped pkill clears leaks, then start) -
  ssh -o ControlPath="${ctrl_path}" -f "${host}" \
    "pkill -f 'nvim --headless --listen 127.0.0.1:${port}' 2>/dev/null; nvim --headless --listen 127.0.0.1:${port}" || {
      echo "remote-nvim: failed to launch remote Neovim on ${host}" >&2
      _remote_nvim_cleanup
      trap - INT TERM
      return 1
    }

  # --- 3. wait for the remote server to answer, then attach the local UI -----
  local i ready=0
  for i in {1..30}; do
    if nvim --clean --server "localhost:${port}" --remote-expr '1' >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 1
  done
  if (( ! ready )); then
    echo "remote-nvim: remote Neovim did not become ready on localhost:${port}" >&2
    _remote_nvim_cleanup
    trap - INT TERM
    return 1
  fi

  nvim --clean --server "localhost:${port}" --remote-ui
  local rc=$?

  trap - INT TERM
  _remote_nvim_cleanup
  return $rc
}

alias rnv='remote-nvim'
