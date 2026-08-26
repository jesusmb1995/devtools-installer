Pre-allocated sessions of TMUX for ultra-fast zsh terminal start-up.

Sessions of tmux not explicitely closed with `exit` will be available for later use. When starting a re-used terminal `cd` is automatically applied into the curret pwd.

## Configuration

The daemon reads a YAML config from `~/.config/tmux_warm_daemon/config.yaml`:

```yaml
pid_file: /tmp/tmux_warm_daemon.pid
log_file: /tmp/tmux_warm_daemon.log

pools:
  warm:
    max_detached: 2
  agent:
    max_detached: 1
    command: agent
```

Each pool maintains its own set of pre-warmed tmux sessions:

- **`warm`** — default pool for regular shell sessions (no command, just zsh).
  Sessions are named `warm-0`, `warm-1`, etc.
- **`agent`** — pool with `agent` already started and waiting for input.
  Generic sessions are named `agent-0`, `agent-1`, etc.
  Workspace sessions are named `agent@<hash>` (see below).

Pool options:
- `max_detached` — how many generic detached sessions to keep warm (default: 2, set to 0 to disable)
- `command` — optional command to run in the session (omit for a regular shell)

If no config file exists, the daemon falls back to a single `warm` pool with `max_detached: 2`.

A custom config path can be passed as a CLI argument:
```
tmux_warm_daemon /path/to/config.yaml
```

## Idle-session reaper

`tmux_session_reaper.sh` is a separate, non-blocking bash service that reclaims
forgotten tmux sessions. Every `idle_reaper_interval` seconds it scans the tmux
server and kills any detached session with no activity for longer than
`idle_reaper_hours` (default 26h). It never holds tmux locks between passes and
never interferes with pre-warming.

The reaper is started (and stopped) alongside the warm daemon by
`restart_daemon.sh`, so it runs out of the box after install. It can also be
invoked directly:

```bash
# single pass, then exit (handy from cron or for a manual cleanup)
tmux_session_reaper.sh --once

# run as the background service
tmux_session_reaper.sh
```

A session is always **spared** if it is currently attached, if it is managed by
a pool (`warm-N`, `agent-N`, `<pool>@<hash>` — read from `pools:` in this same
config), or if its age cannot be determined. "No activity / did not change" is
the time since the most recent of: the session's last change (the **max of
`#{window_activity}` across its windows** — this advances on real output with
the default `monitor-activity=off`, unlike `#{session_activity}` which stays
frozen at creation), the last attach (`#{session_last_attached}`) and creation
(`#{session_created}`, fallback). So a session started days ago that still
produces output is measured by that recent change and spared; only one with no
change or attach for longer than the threshold is reaped.

Both knobs live in the same config as the daemon and are ignored by it, so the
file configures both processes:

```yaml
idle_reaper_hours: 26      # 0 disables the reaper
idle_reaper_interval: 3600 # seconds between scans
```

The reaper is started (and stopped) alongside the warm daemon by
`restart_daemon.sh`, so it runs out of the box after install. It can also be
invoked directly:

```bash
# single pass, then exit (handy from cron or for a manual cleanup)
tmux_session_reaper.sh --once

# run as the background service
tmux_session_reaper.sh
```

Kills are logged (tagged `[reaper]`) to the daemon's `log_file`
(`/tmp/tmux_warm_daemon.log` by default).

## Backends

Two interchangeable implementations live side by side:

- **`rust/`** — the gold reference (`rust/mod.rs`). Fast, compiled, used by default.
- **`bash/`** — a pure-bash port (`bash/tmux_warm_daemon`) that mirrors the Rust
  behaviour with no compile step and only tmux/md5sum/coreutils as dependencies.

The backend-agnostic launcher `./tmux_warm_daemon` runs whichever backend is
present (preferring the Rust binary when built). When deployed through the
[generator](../../repos/generate.sh), the `tmux-warm-daemon` repo entry selects
the backend via its `impl` field (`"rust"` or `"bash"`) and only the chosen
backend folder is emitted into `src`:

```json
{ "id": "tmux-warm-daemon", "impl": "bash", "impl_variants": ["rust", "bash", "python"] }
```

## Installation

For the bash backend, no build is needed — just use `./tmux_warm_daemon`.

For the Rust backend, build it first:
```
cd rust && cargo build --release
```

Install (pick one):
```bash
# System-wide
sudo cp rust/target/release/tmux_warm_daemon /usr/bin/tmux_warm_daemon

# Or reference the backend-agnostic launcher directly from .zshrc (no install):
#   $HOME/.tmux_warm_daemon/tmux_warm_daemon
```

Apply mod to tmux plugin:
```
tmux_warm_daemon_dir="$(pwd)"
(cd "${HOME}/.oh-my-zsh/plugins/tmux" && git apply "${tmux_warm_daemon_dir}/tmux.plugin.zsh.diff")
```

The plugin patch adds two config variables:
- `ZSH_TMUX_CD` — send `cd` to the attached session to match the launching terminal's pwd
  (only when the target pane is a plain shell prompt; it is never typed into a
  pane running another tool, and the fresh-session fallback needs no `cd` at
  all — tmux starts it in the client's pwd)
- `ZSH_TMUX_WARM_SESSION_PREFIX` — when set, auto-attach targets a detached session
  whose name starts with this prefix (e.g. `"warm"` matches `warm-0`, `warm-1`),
  preventing accidental attachment to sessions from other pools like `agent-*`.
  The pick is CLEAN-AWARE: it skips warm sessions whose pane is currently
  running another cli-tool (btop, an editor, an agent CLI, ...) and takes the
  first one sitting at a plain shell prompt (one `list-panes` roundtrip, no
  added latency). The forked omz-config plugin ships the same gate
  (`_zsh_tmux_warm_pick` / `_zsh_tmux_pane_is_shell`); this diff mirrors it
  for stock oh-my-zsh installs.

Set up tmux plugin in `.zshrc`:

```zsh
plugins=(git tmux zshmarks)

if [ -z "$ZSH_TMUX_AUTOSTART" ]; then
	export ZSH_TMUX_AUTOSTART=true
fi

export ZSH_TMUX_AUTOCONNECT=true
export ZSH_TMUX_CD=true
export ZSH_TMUX_WARM_SESSION_PREFIX="warm"

if [ -z "$TMUX" ]; then
  export TMUX_WARM_DAEMON=$(cat /tmp/tmux_warm_daemon.pid 2>/dev/null)
  ps -p ${TMUX_WARM_DAEMON:-0} > /dev/null 2>&1
  if [ $? -ne 0  ]; then
    $HOME/.tmux_warm_daemon/tmux_warm_daemon
    export TMUX_WARM_DAEMON=$(cat /tmp/tmux_warm_daemon.pid 2>/dev/null)
  fi

  export TMUX_PREATTACH_PATH="$(pwd)"
  kill -USR1 ${TMUX_WARM_DAEMON}
fi

source $ZSH/oh-my-zsh.sh
```

## Workspace-specific sessions

For any pool named `<pool>`, the daemon automatically checks
`/tmp/tmux_warm_<pool>_workspaces.json` on every SIGUSR1. If the file exists,
it creates a session per workspace path. The JSON file is a plain array of
absolute paths:

```json
["/home/user/project-alpha", "/home/user/project-beta"]
```

For example, writing the above to `/tmp/tmux_warm_agent_workspaces.json` creates:
- `agent@<8-char md5 hash>` running `agent --workspace /home/user/project-alpha`
- `agent@<8-char md5 hash>` running `agent --workspace /home/user/project-beta`

These coexist with generic `agent-0` sessions (controlled by `max_detached`).
Set `max_detached: 0` to only use workspace-specific sessions.

The JSON file can be managed by external tooling (IDE hooks, scripts, cron).

## Agent-workspace registry (`was-agent`)

`was-agent.sh` (deployed as `~/.local/bin/was-agent`) is the registry of
"agent workspaces": `attach_warm.sh` and nvim's `<leader><C-l>` call
`was-agent mark <path>`, and the bash daemon reads `was-agent json` (preferred
over the legacy `/tmp` json) to decide which `agent@<hash>` sessions to
pre-warm.

- **Storage**: sqlite db at `~/.cache/tmux_warm_daemon/was_agent.db`
  (table `workspaces(path, h8, marked_at)`; `path` is the primary key so
  re-marking upserts).
- **Subcommands**:
  - `mark <path>` — register a workspace (sqlite upsert, plus a dual-write to
    the legacy json so the Rust daemon keeps working)
  - `is-marked <path>` — exit 0 when the path is in the db, has a legacy
    `$path/.was_agent` file, or appears in the legacy json
  - `list` / `json` — registered paths, one per line / as a JSON array
  - `hash <path>` — the 8-char md5 prefix used in `agent@<hash>` names
- **Fallback**: `sqlite3` is resolved from `PATH`, then
  `/home/linuxbrew/.linuxbrew/bin/sqlite3`, then `/opt/homebrew/bin/sqlite3`
  (an explicit `$WAS_AGENT_SQLITE3` overrides). Without any sqlite3, `mark`
  degrades to the legacy scheme (touch `$path/.was_agent` + append to the
  legacy json — note that in sqlite mode no per-directory file is created at
  all), and `list`/`json` read the legacy json via `python3`.
- **TMPDIR note**: the legacy json path is `${TMPDIR:-/tmp}/tmux_warm_agent_workspaces.json`,
  so tests/sandboxes can redirect it by setting `TMPDIR`.

## Attaching to non-default pools

Use `attach_warm.sh` to attach to a pre-warmed session from any pool:

```bash
# Usage: attach_warm.sh [pool_name] [init_cmd] [workspace_path]

# Attach to a generic agent session
bash attach_warm.sh agent

# Attach with workspace — tries agent@<hash> first, falls back to generic
bash attach_warm.sh agent "agent --workspace /my/project" /my/project

# Shell pool — cd into current directory
bash attach_warm.sh warm "cd $PWD"

# Works from inside tmux too (uses switch-client)
```

Or add shell aliases:

```bash
# Agent pool — prefer workspace session, fall back to generic
alias wa='bash $HOME/.tmux_warm_daemon/attach_warm.sh agent "" "$PWD"'
# Shell pool — cd into current directory
alias ww='bash $HOME/.tmux_warm_daemon/attach_warm.sh warm "cd $PWD"'
```
