#!/usr/bin/env sh
# Seed Kilo Code permissions from the shared permissions.json.
# kilocode reads ~/.config/kilo/kilo.jsonc with permission.bash as a
# { "<cmd> *": "allow"|"deny" } map; convert Shell(...) entries accordingly.
set -e
perms="$HOME/.agent/permissions.json"
kilo_cfg="$HOME/.config/kilo/kilo.jsonc"
[ -f "$perms" ] || exit 0
mkdir -p "$(dirname "$kilo_cfg")"
[ -f "$kilo_cfg" ] || echo '{}' > "$kilo_cfg"
jq -n --slurpfile base "$kilo_cfg" --slurpfile p "$perms" '
  ($base[0] // {}) as $b |
  ($p[0] // {}) as $perm |
  ($perm.allow // [] | map(select(startswith("Shell(")))
                      | map(gsub("^Shell\\("; "") | sub("\\)$"; ""))
                      | map(if test("\\*") then . else . + " *" end)
                      | map({(.):"allow"}) | add // {}) as $allow |
  ($perm.deny  // [] | map(select(startswith("Shell(")))
                      | map(gsub("^Shell\\("; "") | sub("\\)$"; ""))
                      | map(if test("\\*") then . else . + " *" end)
                      | map({(.):"deny"})  | add // {}) as $deny |
  $b | .permission.bash = (((.permission // {}).bash // {}) * $allow * $deny)
' > "$kilo_cfg.new" && mv "$kilo_cfg.new" "$kilo_cfg"
