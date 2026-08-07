#!/usr/bin/env bash

set -euo pipefail

log() {
    printf '[*] %s\n' "$1"
}

warn() {
    printf '[!] %s\n' "$1" >&2
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

install_user_systemd_config() {
    local source_file="$repo_root/systemd/.config/systemd/user/xdg-desktop-portal-gnome.service.d/restart.conf"
    local target_file="$HOME/.config/systemd/user/xdg-desktop-portal-gnome.service.d/restart.conf"

    log "Installing user systemd overrides..."
    mkdir -p "$(dirname "$target_file")"

    # Adopt an identical locally installed override without creating a backup.
    # Preserve any differing local override before stow takes ownership.
    if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
        if cmp -s "$source_file" "$target_file"; then
            rm "$target_file"
        else
            backup_path "$target_file"
        fi
    fi

    stow_pkg "systemd"
    systemctl --user daemon-reload
    if systemctl --user show xdg-desktop-portal-gnome.service -p LoadState --value 2>/dev/null | grep -qv '^not-found$'; then
        systemctl --user try-restart xdg-desktop-portal-gnome.service
    fi
}

# ---------------------------------------------------------------------------
# Machine profile selection
# ---------------------------------------------------------------------------

MACHINE_ENV_DIR="$HOME/.config/dotfiles"
MACHINE_ENV_FILE="$MACHINE_ENV_DIR/machine.env"

choose_machine_profile() {
    # If already set in environment, use it (allows non-interactive runs)
    if [ -n "${MACHINE:-}" ]; then
        case "$MACHINE" in
            home|work|laptop) printf '%s' "$MACHINE"; return ;;
            *)
                err "Invalid MACHINE='$MACHINE'. Valid values: home, work, laptop"
                exit 1
                ;;
        esac
    fi

    # If a saved profile exists, offer to reuse it
    if [ -f "$MACHINE_ENV_FILE" ]; then
        # shellcheck source=/dev/null
        . "$MACHINE_ENV_FILE"
        if [ -n "${MACHINE:-}" ]; then
            printf '\nCurrent machine profile: %s\n' "$MACHINE" >&2
            printf 'Keep this profile? [Y/n]: ' >&2
            read -r keep_ans
            case "${keep_ans:-Y}" in
                [Yy]*|"") printf '%s' "$MACHINE"; return ;;
            esac
        fi
    fi

    # Interactive selection
    printf '\n' >&2
    printf 'Select machine profile:\n' >&2
    printf '  1) home    (default)\n' >&2
    printf '  2) work\n' >&2
    printf '  3) laptop\n' >&2
    read -rp "Selection [1/2/3]: " profile_choice

    case "${profile_choice:-1}" in
        ""|1) printf '%s' "home"   ;;
        2)    printf '%s' "work"   ;;
        3)    printf '%s' "laptop" ;;
        *)
            err "Invalid selection: $profile_choice"
            exit 1
            ;;
    esac
}

save_machine_profile() {
    local machine="$1"
    mkdir -p "$MACHINE_ENV_DIR"
    printf 'MACHINE=%s\n' "$machine" > "$MACHINE_ENV_FILE"
    log "Machine profile '$machine' saved to $MACHINE_ENV_FILE"
}

install_machine_niri_config() {
    local machine="$1"
    local template="$repo_root/niri/.config/niri/machine.kdl.$machine"
    local dest="$HOME/.config/niri/machine.kdl"

    if [ ! -f "$template" ]; then
        err "No niri machine template found at $template — skipping"
        return
    fi

    mkdir -p "$HOME/.config/niri"

    # Detect the first connected output name from the running niri instance.
    # On a fresh install before first login niri may not be running; in that
    # case the __NIRI_OUTPUT__ placeholder is left in the written file for the
    # user to fill in after logging in and running `niri msg outputs`.
    local detected=""
    if command -v niri >/dev/null 2>&1; then
        detected="$(niri msg outputs 2>/dev/null | awk '/^Output /{sub(/:$/,"",$2); print $2; exit}')"
    fi

    if [ -n "$detected" ]; then
        sed "s/__NIRI_OUTPUT__/$detected/g" "$template" > "$dest"
        log "Installed niri machine config for '$machine' (output: $detected)"
    else
        cp "$template" "$dest"
        warn "Could not auto-detect display output (niri not running)."
        warn "Edit $dest and replace __NIRI_OUTPUT__ with your output name."
        warn "Run 'niri msg outputs' after logging in to list outputs."
    fi
}

# ---------------------------------------------------------------------------

main() {
    require_cmd stow

    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    repo_root="$script_dir"

    # Resolve machine profile
    MACHINE=$(choose_machine_profile)
    save_machine_profile "$MACHINE"
    log "Using machine profile: $MACHINE"

    # Wallpapers: Target is inside .local/share, NOT ~/wallpapers
    # No backup — wallpapers are large (~400MB) and nothing there needs preserving.
    mkdir -p "$HOME/.local/share/wallpapers"
    stow_pkg "wallpapers"

    # Applications: These are self-contained in their own folders inside .config,
    # so it is safe to backup/replace the folder.
    backup_and_stow niri ".config/niri"
    backup_and_stow noctalia ".config/noctalia"
    backup_and_stow fuzzel ".config/fuzzel"
    backup_and_stow hyprland ".config/hypr"

    # User service policy: keep the GNOME portal backend alive after a
    # compositor restart so Flameshot does not hang waiting for screenshots.
    install_user_systemd_config

    # Install machine-specific niri config (layout widths, output, window rules)
    install_machine_niri_config "$MACHINE"

    # GTK theming (Noctalia overlays + settings)
    # We must backup both gtk-3.0 and gtk-4.0 before stowing the gtk package.
    log "Installing GTK configs (gtk-3.0 + gtk-4.0)..."
    backup_path "$HOME/.config/gtk-3.0"
    backup_path "$HOME/.config/gtk-4.0"
    stow_pkg "gtk"
    
    # Plasma: Special handling to avoid wiping .config
    install_plasma

    # System service state is managed by manifests/services and applied from
    # 2-install-pkgs.sh. User-unit overrides are stowed above with dotfiles.

    log "Dotfiles and configs installed."
}

main "$@"
