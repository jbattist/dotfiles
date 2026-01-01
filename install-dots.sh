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

install_with_yay() {
    for pkg in niri noctalia-shell fuzzel ttf-jetbrains-mono ttf-inter ttf-jetbrains-mono-nerd; do
        if yay -Qi "$pkg" >/dev/null 2>&1; then
            log "$pkg already installed"
        else
            log "Installing $pkg via yay"
            yay -S --needed "$pkg"
        fi
    done
}

backup_and_stow() {
    local repo_root="$1" dir="$2" target="$3"
    local target_path="$HOME/$target"
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        backup_name="$target_path.backup.$(date +%Y%m%d%H%M%S)"
        log "Backing up existing $target_path to $backup_name"
        mv "$target_path" "$backup_name"
    fi
    stow -d "$repo_root" -R -t "$HOME" "$dir"
}

main() {
    require_cmd yay
    require_cmd stow
    install_with_yay

    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    repo_root="$script_dir"

    backup_and_stow "$repo_root" wallpapers "wallpapers"
    backup_and_stow "$repo_root" niri ".config/niri"
    backup_and_stow "$repo_root" noctalia ".config/noctalia"
    backup_and_stow "$repo_root" fuzzel ".config/fuzzel"

    log "Dotfiles and configs installed."
}

main "$@"
