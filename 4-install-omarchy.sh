#!/usr/bin/env bash
set -euo pipefail

log() {
    printf '[*] %s\n' "$1"
}

warn() {
    printf '[!] %s\n' "$1" >&2
}

err() {
    printf '[x] %s\n' "$1" >&2
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
        log "Backing up $target_path -> $backup_name"
        mv "$target_path" "$backup_name"
    fi
}

ensure_line() {
    local file="$1"
    local line="$2"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if grep -Fqx "$line" "$file"; then
        return
    fi

    printf '\n%s\n' "$line" >> "$file"
}

append_zsh_block_if_missing() {
    local zshrc_file="$1"
    local block_start="# >>> dotfiles-omarchy >>>"

    mkdir -p "$(dirname "$zshrc_file")"
    touch "$zshrc_file"

    if grep -Fq "$block_start" "$zshrc_file"; then
        log "zsh loader block already present in $zshrc_file"
        return
    fi

    cat >> "$zshrc_file" <<'EOF'

# >>> dotfiles-omarchy >>>
# Added by 4-install-omarchy.sh
if [ -f "$HOME/.config/dotfiles/omarchy/zshrc/.zshrc" ]; then
    export STARSHIP_CONFIG="$HOME/.config/dotfiles/omarchy/starship/.config/starship.toml"
    source "$HOME/.config/dotfiles/omarchy/zshrc/.zshrc"
fi
# <<< dotfiles-omarchy <<<
EOF

    log "Added zsh loader block to $zshrc_file"
}

stage_layer_with_stow() {
    local repo_root="$1"
    local layer_root="$2"

    local stage_packages=(
        fish
        zshrc
        starship
        hyprland
        ghostty
        fuzzel
        noctalia
        fastfetch
        nvim
        mango
        vicinae
        filen
    )

    mkdir -p "$layer_root"
    stow -d "$repo_root" -R -t "$layer_root" "${stage_packages[@]}"
    log "Staged configs via stow into $layer_root"
}

setup_shell_hooks() {
    local layer_root="$1"

    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/99-dotfiles-omarchy.fish" <<EOF
# Managed by 4-install-omarchy.sh
set -l omarchy_root "$layer_root"

if test -f "$omarchy_root/starship/.config/starship.toml"
    set -gx STARSHIP_CONFIG "$omarchy_root/starship/.config/starship.toml"
end

if test -f "$omarchy_root/fish/.config/fish/config.fish"
    source "$omarchy_root/fish/.config/fish/config.fish"
end
EOF

    append_zsh_block_if_missing "$HOME/.zshrc"
    log "Installed shell hooks (fish + zsh)"
}

setup_hyprland_hook() {
    local layer_root="$1"

    mkdir -p "$HOME/.config/hypr"

    cat > "$HOME/.config/hypr/omarchy-user.conf" <<'EOF'
# Managed by 4-install-omarchy.sh
# This file is sourced by ~/.config/hypr/hyprland.conf so Omarchy defaults stay intact.
source = ~/.config/dotfiles/omarchy/hyprland/.config/hypr/hyprland.conf
EOF

    ensure_line "$HOME/.config/hypr/hyprland.conf" "source = ~/.config/hypr/omarchy-user.conf"

    if [ -f "$layer_root/hyprland/.config/hypr/hyprland.conf" ]; then
        log "Installed Hyprland include hook"
    else
        warn "Staged Hyprland config not found under $layer_root/hyprland"
    fi
}

apply_app_symlinks() {
    local layer_root="$1"

    local app_packages=(
        ghostty
        fuzzel
        noctalia
        fastfetch
        nvim
        mango
        vicinae
        filen
    )

    local backup_targets=(
        "$HOME/.config/ghostty"
        "$HOME/.config/fuzzel"
        "$HOME/.config/noctalia"
        "$HOME/.config/fastfetch"
        "$HOME/.config/nvim"
        "$HOME/.config/mango"
        "$HOME/.config/vicinae"
        "$HOME/.filen-cli"
    )

    local target
    for target in "${backup_targets[@]}"; do
        backup_path "$target"
    done

    stow -d "$layer_root" -R -t "$HOME" "${app_packages[@]}"
    log "Applied app configs with stow"
}

print_usage() {
    cat <<'EOF'
Usage: bash 4-install-omarchy.sh [--apply-apps]

Safe default behavior:
- Stages shell, Hyprland, and app configs into ~/.config/dotfiles/omarchy using stow
- Adds source/include hooks for shell + Hyprland
- Does NOT overwrite app config directories

Options:
  --apply-apps   Backup and symlink app config directories from staged layer
  -h, --help     Show this help
EOF
}

main() {
    require_cmd stow
    require_cmd grep

    local script_dir repo_root
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    repo_root="$script_dir"

    local config_home layer_root
    config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    layer_root="$config_home/dotfiles/omarchy"

    local apply_apps=0

    while (($#)); do
        case "$1" in
            --apply-apps)
                apply_apps=1
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                err "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
        shift
    done

    log "Staging Omarchy-safe config layer at $layer_root"

    stage_layer_with_stow "$repo_root" "$layer_root"
    setup_shell_hooks "$layer_root"
    setup_hyprland_hook "$layer_root"

    if [ "$apply_apps" -eq 1 ]; then
        warn "Applying app symlinks with stow (existing targets will be backed up first)."
        apply_app_symlinks "$layer_root"
    else
        log "App configs were staged only. Re-run with --apply-apps to symlink them."
    fi

    log "Done. Omarchy base files were preserved; your overrides live in $layer_root"
}

main "$@"
