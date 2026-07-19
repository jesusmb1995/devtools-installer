#!/usr/bin/env sh
# Seed Antigravity CLI (agy) permissions from the shared permissions.json.
# agy reads ~/.gemini/antigravity-cli/settings.json using command(...) syntax
# (cursor/claude use Shell(...)); convert and merge idempotently.
set -e
perms="$HOME/.agent/permissions.json"
agy_cfg="$HOME/.gemini/antigravity-cli/settings.json"
[ -f "$perms" ] || exit 0
mkdir -p "$(dirname "$agy_cfg")"
[ -f "$agy_cfg" ] || echo '{}' > "$agy_cfg"
jq -n --slurpfile base "$agy_cfg" --slurpfile p "$perms" '
  ($base[0] // {}) as $b |
  ($p[0] // {}) as $perm |
  ($perm | {
     allow: ((.allow // []) | map(gsub("^Shell\\("; "command("))),
     deny:  ((.deny  // []) | map(gsub("^Shell\\("; "command(")))
  }) as $agy |
  $b | .permissions = {
    allow: (((($b.permissions // {}).allow) // []) + $agy.allow) | unique,
    deny:  (((($b.permissions // {}).deny)  // []) + $agy.deny)  | unique
  }
' > "$agy_cfg.new" && mv "$agy_cfg.new" "$agy_cfg"
