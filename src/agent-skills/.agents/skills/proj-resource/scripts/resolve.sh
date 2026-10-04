#!/usr/bin/env bash
set -eu
# proj-resource resolver: identify current workspace/project the same way nvim does.
# Usage: eval "$(sh resolve.sh [path])"
# Output: ROOT= ORIG= SECONDARY= RES= JOURNAL_HASH= NOTES_STORE=

start="${1:-$(pwd)}"
if [ -e "$start" ] && [ ! -d "$start" ]; then
  start="$(dirname -- "$start")"
fi

canon() {
  local p="$1" out=""
  if command -v realpath >/dev/null 2>&1; then
    out="$(realpath -m -- "$p" 2>/dev/null || true)"
  fi
  if [ -z "$out" ]; then
    if [ -d "$p" ]; then
      out="$(cd -- "$p" && pwd -P)"
    else
      out="$p"
    fi
  fi
  if [ "$out" != "/" ]; then
    out="${out%/}"
  fi
  printf "%s" "$out"
}

root="$(canon "$start")"
probe="$root"
while :; do
  if [ -d "$probe/.jj" ]; then
    root="$probe"
    break
  fi
  parent="$(dirname -- "$probe")"
  if [ "$parent" = "$probe" ]; then
    break
  fi
  probe="$parent"
done

if [ ! -d "$root/.jj" ]; then
  git_root="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$git_root" ]; then
    root="$(canon "$git_root")"
  else
    root="$(canon "$start")"
  fi
fi

base="$(basename -- "$root")"
orig="$base"
secondary=0
case "$base" in
  *-secondary|*-secondary[0-9]*)
    orig="$(printf "%s" "$base" | sed -E 's/-secondary[0-9]*$//')"
    if [ -z "$orig" ]; then
      orig="$base"
    else
      secondary=1
    fi
    ;;
esac

canon_root="$(canon "$root")"
hash=""
if command -v sha256sum >/dev/null 2>&1; then
  hash="$(printf "%s" "$canon_root" | sha256sum | cut -c1-8)"
elif command -v shasum >/dev/null 2>&1; then
  hash="$(printf "%s" "$canon_root" | shasum -a 256 | cut -c1-8)"
elif command -v openssl >/dev/null 2>&1; then
  hash="$(printf "%s" "$canon_root" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-8)"
fi
hash="$(printf "%s" "$hash" | tr '[:upper:]' '[:lower:]')"
store_hash="$hash"
if command -v sha256sum >/dev/null 2>&1; then
  store_hash="$(printf "%s" "$root" | sha256sum | cut -c1-16)"
elif command -v shasum >/dev/null 2>&1; then
  store_hash="$(printf "%s" "$root" | shasum -a 256 | cut -c1-16)"
elif command -v openssl >/dev/null 2>&1; then
  store_hash="$(printf "%s" "$root" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-16)"
fi
store_hash="$(printf "%s" "$store_hash" | tr '[:upper:]' '[:lower:]')"

printf "ROOT=%s\n" "$root"
printf "ORIG=%s\n" "$orig"
printf "SECONDARY=%s\n" "$secondary"
printf "RES=%s/projtmp/%s\n" "$HOME" "$orig"
printf "JOURNAL_HASH=%s\n" "$hash"
printf "NOTES_STORE=%s/.local/share/quicknote/%s\n" "$HOME" "$store_hash"
