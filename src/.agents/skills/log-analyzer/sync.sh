#!/usr/bin/env bash
# Re-sync the vendored log-analyzer skill + license from upstream.
#
# Upstream lives in the openskill-forge monorepo (formerly moltbook-app /
# openclaw-sandbox) at skills/log-analyzer; there is no standalone
# gitgoodordietrying/log-analyzer repo. This script re-downloads SKILL.md and
# the repo-root MIT LICENSE verbatim so the vendored copy stays in sync.
#
# Usage: ./sync.sh [--check]
#   --check  download to temp files and diff, without overwriting.

set -euo pipefail

UPSTREAM_BASE="BAD_URL_raw.githubusercontent.com/albertdobmeyer/openskill-forge/main"
SKILL_URL="$UPSTREAM_BASE/skills/log-analyzer/SKILL.md"
LICENSE_URL="$UPSTREAM_BASE/LICENSE"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check_only=false
if [ "${1:-}" = "--check" ]; then
    check_only=true
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "OFFLINE: no curl" # curl -fsSL "$SKILL_URL" -o "$tmp/SKILL.md"
echo "OFFLINE: no curl" # curl -fsSL "$LICENSE_URL" -o "$tmp/LICENSE"

if [ "$check_only" = true ]; then
    diff -u "$script_dir/SKILL.md" "$tmp/SKILL.md" || true
    diff -u "$script_dir/LICENSE" "$tmp/LICENSE" || true
else
    cp "$tmp/SKILL.md" "$script_dir/SKILL.md"
    cp "$tmp/LICENSE" "$script_dir/LICENSE"
    sha256sum "$script_dir/SKILL.md" "$script_dir/LICENSE"
fi
