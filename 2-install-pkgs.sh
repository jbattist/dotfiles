#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/package-lib.sh
. "$SCRIPT_DIR/scripts/package-lib.sh"

command -v fzf >/dev/null 2>&1 || {
  pkg_err 'fzf is required. Run 1-install-shell.sh first.'
  exit 1
}
command -v yay >/dev/null 2>&1 || {
  pkg_err 'yay is required. Run 1-install-shell.sh first.'
  exit 1
}

mapfile -t AVAILABLE_MANIFESTS < <(list_package_manifests)
((${#AVAILABLE_MANIFESTS[@]})) || { pkg_err 'No package manifests found'; exit 1; }

printf 'Select package manifests with TAB, then press ENTER. ESC installs nothing.\n' >&2
selection=$(printf '%s\n' "${AVAILABLE_MANIFESTS[@]}" | fzf --multi --prompt='Package manifests> ' --header='TAB: toggle  ENTER: install  ESC: cancel') || {
  printf '[*] No manifests selected; nothing changed.\n'
  exit 0
}
[[ -n "$selection" ]] || { printf '[*] No manifests selected; nothing changed.\n'; exit 0; }
mapfile -t SELECTED_MANIFESTS <<<"$selection"
mapfile -t PACKAGES < <(resolve_manifests "${SELECTED_MANIFESTS[@]}")

printf 'Selected manifests: %s\n' "${SELECTED_MANIFESTS[*]}"
installed=()
missing=()
for pkg in "${PACKAGES[@]}"; do
  if pacman -Qi "$pkg" >/dev/null 2>&1; then installed+=("$pkg"); else missing+=("$pkg"); fi
done
printf 'Already installed (%d): %s\n' "${#installed[@]}" "${installed[*]:-none}"
printf 'Installing (%d): %s\n' "${#missing[@]}" "${missing[*]:-none}"

if contains gaming "${SELECTED_MANIFESTS[@]}"; then
  sudo sed -i '/^#\s*\[multilib\]/,/Include/s/^#\s*//' /etc/pacman.conf
fi
sudo pacman -Syu --noconfirm || { pkg_err 'System update failed'; exit 1; }

failed=()
for pkg in "${missing[@]}"; do
  printf '[*] Installing %s\n' "$pkg"
  yay -S --needed --noconfirm "$pkg" || failed+=("$pkg")
done
if ((${#failed[@]})); then
  printf '[!] Failed: %s\n' "${failed[*]}" >&2
  exit 1
fi

printf '[*] Reconciling services for selected manifests.\n'
"$SCRIPT_DIR/scripts/service-reconcile.sh" "${SELECTED_MANIFESTS[@]}"
printf '[*] Package installation complete.\n'
