#!/usr/bin/env bash
set -euo pipefail

# =========================
# Arch bootstrap via yay
# =========================

# --- Base packages installed on every machine (edit this) ---
PACKAGES_BASE=(
  # System + terminal tools
  btop
  nfs-utils

  # Desktop + shell utilities
  firefox
  nemo
  gnome-calculator
  udiskie
  cliphist
  ferdium-bin
    
  # Development tooling
  visual-studio-code-bin
  opencode
  claude-code
  codex-cli

  # Window manager + theming
  niri
  noctalia-shell

  # Fonts
  ttf-jetbrains-mono
  ttf-jetbrains-mono-nerd

  # Notes
  obsidian
)

# --- Home desktop packages ---
PACKAGES_home=(
  # Gaming
    steam
    protonplus
)

# --- Work machine packages ---
PACKAGES_work=(
  # Browser
  chromium
)

# --- Laptop packages ---
PACKAGES_laptop=(
  # Browser
  chromium
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

# ---------------------------------------------------------------------------
# Machine profile resolution — reads the same machine.env written by
# 3-install-dots.sh, or falls back to an interactive prompt.
# ---------------------------------------------------------------------------

MACHINE_ENV_FILE="$HOME/.config/dotfiles/machine.env"

resolve_machine_profile() {
    # 1. Honour env var if already set
    if [ -n "${MACHINE:-}" ]; then
        case "$MACHINE" in
            home|work|laptop) return ;;
            *)
                err "Invalid MACHINE='$MACHINE'. Valid values: home, work, laptop"
                exit 1
                ;;
        esac
    fi

    # 2. Read saved profile
    if [ -f "$MACHINE_ENV_FILE" ]; then
        # shellcheck source=/dev/null
        . "$MACHINE_ENV_FILE"
        if [ -n "${MACHINE:-}" ]; then
            log "Using saved machine profile: $MACHINE"
            return
        fi
    fi

    # 3. Interactive fallback
    warn "No machine profile found at $MACHINE_ENV_FILE"
    printf 'Select machine profile:\n' >&2
    printf '  1) home    (default)\n' >&2
    printf '  2) work\n' >&2
    printf '  3) laptop\n' >&2
    read -rp "Selection [1/2/3]: " profile_choice

    case "${profile_choice:-1}" in
        ""|1) MACHINE="home"   ;;
        2)    MACHINE="work"   ;;
        3)    MACHINE="laptop" ;;
        *)
            err "Invalid selection: $profile_choice"
            exit 1
            ;;
    esac
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
  local machine="$1"
  log "Installing packages for profile '$machine' (skipping anything already installed)..."

  # Merge base + machine-specific arrays
  local extra_var="PACKAGES_${machine}[@]"
  local all_packages=("${PACKAGES_BASE[@]}" "${!extra_var}")

  local to_install=()
  for pkg in "${all_packages[@]}"; do
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

  resolve_machine_profile
  log "Machine profile: $MACHINE"

  if ! has_cmd yay; then
    install_yay
  fi

  # Ensure package DB is available (and keys initialized as needed)
  log "Ensuring pacman keyring is ready..."
  sudo pacman -Sy --noconfirm archlinux-keyring || true

  update_all
  install_packages "$MACHINE"

  log "Done."
}

main "$@"
