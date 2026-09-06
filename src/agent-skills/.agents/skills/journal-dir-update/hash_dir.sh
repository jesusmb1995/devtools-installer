#!/usr/bin/env bash
set -eu
# pipefail where supported (bash/ksh/zsh)
if set -o | grep -q pipefail 2>/dev/null; then set -o pipefail; fi
# hash_dir.sh — stable 8-char hash of a directory's canonical absolute path
# Usage: hash_dir.sh [dir_path]
#   dir_path defaults to pwd
# Output: 8-char lowercase hex (first 8 of sha256 of canonical path) on stdout
# Companion skill: journal-dir-update / journal-dir-read

dir="${1:-$(pwd)}"

# canonicalize
canon=""
if command -v realpath >/dev/null 2>&1; then
    canon="$(realpath -m -- "$dir" 2>/dev/null || realpath -m "$dir")"
else
    if [ -d "$dir" ]; then
        canon="$(cd -- "$dir" && pwd -P)"
    else
        # for non-existing paths, resolve parent
        parent="$(dirname -- "$dir")"
        base="$(basename -- "$dir")"
        if [ -d "$parent" ]; then
            canon="$(cd -- "$parent" && pwd -P)/$base"
        else
            canon="$dir"
        fi
    fi
fi

# remove trailing slash except root
if [ "$canon" != "/" ]; then
    canon="${canon%/}"
fi

# hash: sha256 -> first 8 chars
hash=""
if command -v sha256sum >/dev/null 2>&1; then
    hash="$(printf "%s" "$canon" | sha256sum | cut -c1-8)"
elif command -v shasum >/dev/null 2>&1; then
    hash="$(printf "%s" "$canon" | shasum -a 256 | cut -c1-8)"
elif command -v openssl >/dev/null 2>&1; then
    hash="$(printf "%s" "$canon" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-8)"
else
    echo "hash_dir.sh: no sha256 tool found (need sha256sum, shasum, or openssl)" >&2
    exit 1
fi

# normalize lowercase
hash="$(printf "%s" "$hash" | tr '[:upper:]' '[:lower:]')"

if ! printf "%s" "$hash" | grep -Eq '^[0-9a-f]{8}$'; then
    echo "hash_dir.sh: unexpected hash output: $hash (canon=$canon)" >&2
    exit 1
fi

printf "%s\n" "$hash"
