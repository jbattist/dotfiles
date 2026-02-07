#!/usr/bin/env bash

set -euo pipefail

log() {
    printf '[*] %s\n' "$1"
}

err() {
    printf '[!] %s\n' "$1" >&2
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "Missing required command: $1"
        exit 1
    fi
}


backup_path() {
    local target_path="$1"
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        local backup_name="$target_path.backup.$(date +%Y%m%d%H%M%S)"
        log "Backing up existing $target_path to $backup_name"
        mv "$target_path" "$backup_name"
    fi
}

stow_pkg() {
    local pkg="$1"
    log "Stowing package: $pkg"
    stow -d "$repo_root" -R -t "$HOME" "$pkg"
}

backup_and_stow() {
    local pkg="$1" target_rel="$2"
    local target_path="$HOME/$target_rel"
    
    # Ensure parent directory exists so stow doesn't link the parent incorrectly
    mkdir -p "$(dirname "$target_path")"
    
    backup_path "$target_path"
    stow_pkg "$pkg"
}

install_plasma() {
    # Plasma installs into .config directly. We CANNOT backup .config.
    # We backup specific conflicting files if they exist as real files.
    log "Installing Plasma configs (merging into .config)..."
    
    local config_files=("kdeglobals" "powerdevilrc")
    for f in "${config_files[@]}"; do
        [ -f "$HOME/.config/$f" ] && [ ! -L "$HOME/.config/$f" ] && backup_path "$HOME/.config/$f"
    done
    
    stow_pkg "plasma"
}

main() {
    require_cmd stow

    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    repo_root="$script_dir"

    # Wallpapers: Target is inside .local/share, NOT ~/wallpapers
    backup_and_stow wallpapers ".local/share/wallpapers"

    # Applications: These are self-contained in their own folders inside .config,
    # so it is safe to backup/replace the folder.
    backup_and_stow niri ".config/niri"
    backup_and_stow noctalia ".config/noctalia"
    backup_and_stow fuzzel ".config/fuzzel"

    # GTK theming (Noctalia overlays + settings)
    # We must backup both gtk-3.0 and gtk-4.0 before stowing the gtk package.
    log "Installing GTK configs (gtk-3.0 + gtk-4.0)..."
    backup_path "$HOME/.config/gtk-3.0"
    backup_path "$HOME/.config/gtk-4.0"
    stow_pkg "gtk"

    # WezTerm (single file in $HOME)
    backup_and_stow wezterm ".wezterm.lua"
    
    # Plasma: Special handling to avoid wiping .config
    install_plasma

    log "Dotfiles and configs installed."
}

main "$@"
