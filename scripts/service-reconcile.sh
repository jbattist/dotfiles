#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=package-lib.sh
. "$SCRIPT_DIR/package-lib.sh"
# shellcheck source=service-lib.sh
. "$SCRIPT_DIR/service-lib.sh"

(($# > 0)) || { service_err 'No package manifests selected'; exit 2; }
SELECTED_MANIFESTS=("$@")
mapfile -t ENABLE_UNITS < <(resolve_service_action enable "${SELECTED_MANIFESTS[@]}" | dedupe_lines)
mapfile -t DISABLE_UNITS < <(resolve_service_action disable "${SELECTED_MANIFESTS[@]}" | dedupe_lines)

failed=()
missing_units=()
for unit in "${ENABLE_UNITS[@]}"; do
  if ! service_unit_exists "$unit"; then
    missing_units+=("$unit")
  elif ! systemctl is-enabled --quiet "$unit" || ! systemctl is-active --quiet "$unit"; then
    printf '[*] Enabling and starting %s\n' "$unit"
    sudo systemctl enable --now "$unit" || failed+=("$unit")
  fi
done
for unit in "${DISABLE_UNITS[@]}"; do
  if service_unit_exists "$unit" && { systemctl is-enabled --quiet "$unit" || systemctl is-active --quiet "$unit"; }; then
    printf '[*] Stopping and disabling %s\n' "$unit"
    sudo systemctl disable --now "$unit" || failed+=("$unit")
  fi
done

if ((${#missing_units[@]})); then
  service_err "Declared units are unavailable: ${missing_units[*]}"
  failed+=("${missing_units[@]}")
fi
if ((${#failed[@]})); then
  service_err "Failed service operations: ${failed[*]}"
  exit 1
fi
printf '[*] Service standards applied.\n'
