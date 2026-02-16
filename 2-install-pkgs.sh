#!/usr/bin/env bash
set -euo pipefail

# =========================
# Arch bootstrap via yay
# =========================

# --- Your package list (edit this) ---
# Use package names as they appear in pacman/yay.
PACKAGES=(
    btop
    #cups
    #ferdium-bin
    #filen-desktop-bin
    firefox
    #fuzzel
    nemo
    #noctalia-shell
    #niri
    obsidian
    #protonplus
    #steam
    #visual-studio-code-bin
    antigravity
    #resources
    #tela-icon-theme
    ttf-jetbrains-mono
    ttf-jetbrains-mono-nerd
    # in Extra repo - inter-font
    #lazyjournal-bin
    nfs-utils
    #pavucontrol
    #openssh
    #swayidle
    gnome-calculator
    
)

# --- Helpers ---
log()  { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m==>\033[0m %s\n" "$*"; }
err()  { printf "\n\033[1;31m==>\033[0m %s\n" "$*"; }

require_arch() {
  if [[ ! -f /etc/arch-release ]]; then
    err "This script is intended for Arch Linux (or Arch-based) systems."
    exit 1
  fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

pkg_installed() {
  # Returns 0 if installed, 1 if not
  pacman -Qi "$1" >/dev/null 2>&1
}

install_yay() {
  warn "yay is not installed."
  read -r -p "Install yay now? [y/N] " ans
  case "${ans,,}" in
    y|yes)
      log "Installing prerequisites (git, base-devel)..."
      sudo pacman -S --needed --noconfirm git base-devel

      tmpdir="$(mktemp -d)"
      trap 'rm -rf "$tmpdir"' EXIT

      log "Cloning yay..."
      git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"

      log "Building & installing yay..."
      (cd "$tmpdir/yay" && makepkg -si --noconfirm)
      ;;
    *)
      err "Cannot continue without yay."
      exit 1
      ;;
  esac
}

update_all() {
  log "Updating system packages and AUR packages..."
  # -Syu updates everything; --needed prevents reinstalls where possible
  yay -Syu --noconfirm
}

install_packages() {
  log "Installing packages (skipping anything already installed)..."

  local to_install=()
  for pkg in "${PACKAGES[@]}"; do
    if pkg_installed "$pkg"; then
      log "Already installed: $pkg"
    else
      to_install+=("$pkg")
    fi
  done

  if (( ${#to_install[@]} == 0 )); then
    log "All packages already installed."
    return 0
  fi

  log "Installing: ${to_install[*]}"
  yay -S --needed --noconfirm "${to_install[@]}"
}

main() {
  require_arch

  if ! has_cmd yay; then
    install_yay
  fi

  # Ensure package DB is available (and keys initialized as needed)
  log "Ensuring pacman keyring is ready..."
  sudo pacman -Sy --noconfirm archlinux-keyring || true

  update_all
  install_packages

  log "Done."
}

main "$@"
