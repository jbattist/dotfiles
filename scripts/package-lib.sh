#!/usr/bin/env bash
# Shared package-manifest parsing and resolution. Source this file; it does not run commands.
set -euo pipefail

PACKAGE_ROOT="${PACKAGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST_ROOT="$PACKAGE_ROOT/manifests/packages"

pkg_err() { printf '[!] %s\n' "$*" >&2; }
pkg_log() { printf '[*] %s\n' "$*"; }
contains() { local x=$1; shift; local y; for y in "$@"; do [[ "$x" == "$y" ]] && return 0; done; return 1; }
valid_token() { [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9+_.@:-]*$ ]]; }

parse_manifest() {
  local file=$1 line n=0
  [[ -f "$file" ]] || { pkg_err "Missing manifest: $file"; return 1; }
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1)); line="${line%$'\r'}"
    [[ -z "${line//[[:space:]]/}" || "$line" == \#* ]] && continue
    [[ "$line" != *[[:space:]]* ]] || { pkg_err "Malformed token at $file:$n"; return 1; }
    valid_token "$line" || { pkg_err "Unsafe package token '$line' at $file:$n"; return 1; }
    printf '%s\n' "$line"
  done < "$file"
}

dedupe_lines() { awk 'NF && !seen[$0]++'; }

list_package_manifests() {
  local file name
  for file in "$MANIFEST_ROOT"/*; do
    [[ -f "$file" ]] || continue
    name=${file##*/}
    [[ "$name" == README.md || "$name" == shell ]] && continue
    valid_token "$name" || { pkg_err "Unsafe package manifest name: $name"; return 1; }
    printf '%s\n' "$name"
  done | sort
}

resolve_manifests() {
  (($# > 0)) || { pkg_err 'No package manifests selected'; return 1; }
  local manifest pkg
  for manifest in "$@"; do
    valid_token "$manifest" || { pkg_err "Unsafe package manifest: $manifest"; return 1; }
    [[ -f "$MANIFEST_ROOT/$manifest" && "$manifest" != README.md ]] || {
      pkg_err "Unknown package manifest: $manifest"
      return 1
    }
    while IFS= read -r pkg; do printf '%s\n' "$pkg"; done < <(parse_manifest "$MANIFEST_ROOT/$manifest")
  done | dedupe_lines
}
