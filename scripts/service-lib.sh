#!/usr/bin/env bash
# Shared systemd service-manifest parsing and resolution.
set -euo pipefail

SERVICE_ROOT="${SERVICE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/manifests/services}"

service_err() { printf '[!] %s\n' "$*" >&2; }
valid_unit() { [[ "$1" =~ ^[a-zA-Z0-9@_.:-]+\.(service|socket|timer|path|target|mount|automount)$ ]]; }

parse_service_manifest() {
  local file=$1 line n=0
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    line="${line%$'\r'}"
    [[ -z "${line//[[:space:]]/}" || "$line" == \#* ]] && continue
    [[ "$line" != *[[:space:]]* ]] || { service_err "Malformed unit at $file:$n"; return 1; }
    valid_unit "$line" || { service_err "Unsafe systemd unit '$line' at $file:$n"; return 1; }
    printf '%s\n' "$line"
  done < "$file"
}

resolve_service_action() {
  local action=$1
  shift
  local group file unit
  [[ "$action" == enable || "$action" == disable ]] || { service_err "Unknown service action: $action"; return 1; }
  parse_service_manifest "$SERVICE_ROOT/common.$action"
  for group in "$@"; do
    file="$SERVICE_ROOT/$group.$action"
    while IFS= read -r unit; do printf '%s\n' "$unit"; done < <(parse_service_manifest "$file")
  done
}

service_unit_exists() {
  systemctl show "$1" -p LoadState --value 2>/dev/null | grep -qv '^not-found$'
}
