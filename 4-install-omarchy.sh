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
if [ -f "$HOME/.config/dotfiles/omarchy/.zshrc" ]; then
    export STARSHIP_CONFIG="$HOME/.config/dotfiles/omarchy/.config/starship.toml"
    source "$HOME/.config/dotfiles/omarchy/.zshrc"
fi
# <<< dotfiles-omarchy <<<
EOF

    log "Added zsh loader block to $zshrc_file"
}

ensure_sudo_access() {
    if [ "$(id -u)" -eq 0 ]; then
        return
    fi
    log "Requesting sudo access for system updates"
    sudo -v
}

install_with_yay() {
    if ! command -v yay >/dev/null 2>&1; then
        log "'yay' not found. Installing yay..."
        require_cmd git
        require_cmd make
        require_cmd gcc
        local tmpdir
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
    fi

    local packages=(
        # Shells
        fish
        zsh
        zsh-autosuggestions
        zsh-syntax-highlighting

        # Terminal
        ghostty

        # Prompt & utilities
        starship
        fastfetch
        fzf
        fzf-zsh
        eza
        zoxide
        fd
        bat

        # Dotfile management & tools
        stow

        # Editors
        micro
        neovim
    )

    for pkg in "${packages[@]}"; do
        if yay -Qi "$pkg" >/dev/null 2>&1; then
            log "$pkg already installed"
        else
            log "Installing $pkg via yay"
            yay -S --needed --noconfirm "$pkg"
        fi
    done
}

choose_default_shell() {
    if [ -n "${DEFAULT_SHELL:-}" ]; then
        case "$DEFAULT_SHELL" in
            fish|zsh|skip)
                printf '%s' "$DEFAULT_SHELL"
                return
                ;;
            *)
                err "Invalid DEFAULT_SHELL='$DEFAULT_SHELL'. Use: fish, zsh, or skip."
                exit 1
                ;;
        esac
    fi

    if [ ! -t 0 ]; then
        printf '%s' "fish"
        return
    fi

    printf '\n' >&2
    printf 'Choose your default shell:\n' >&2
    printf '  1) fish (recommended, default)\n' >&2
    printf '  2) zsh\n' >&2
    printf '  3) keep current shell\n' >&2
    read -rp "Selection [1/2/3]: " shell_choice

    case "$shell_choice" in
        ""|1) printf '%s' "fish" ;;
        2)    printf '%s' "zsh" ;;
        3)    printf '%s' "skip" ;;
        *)
            err "Invalid shell selection: $shell_choice"
            exit 1
            ;;
    esac
}

ensure_default_shell() {
    local selected_shell shell_path
    selected_shell=$(choose_default_shell)

    if [ "$selected_shell" = "skip" ]; then
        log "Keeping current default shell unchanged"
        return
    fi

    if ! shell_path=$(command -v "$selected_shell"); then
        err "$selected_shell is not installed or not in PATH"
        exit 1
    fi

    if [ "${SHELL:-}" = "$shell_path" ]; then
        log "$selected_shell is already the default shell"
        return
    fi

    log "Setting default shell to $selected_shell (you may be prompted for your password)"
    if [ "$(id -u)" -eq 0 ]; then
        chsh -s "$shell_path" "${SUDO_USER:-$USER}"
    else
        sudo chsh -s "$shell_path" "$USER"
    fi
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
        fastfetch
        nvim
        mango
        vicinae
        filen
    )

    mkdir -p "$layer_root"
    stow --ignore='update-noctalia-starship\.py' -d "$repo_root" -R -t "$layer_root" "${stage_packages[@]}"
    log "Staged configs via stow into $layer_root"
}

setup_shell_hooks() {
    local layer_root="$1"

    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/99-dotfiles-omarchy.fish" <<EOF
# Managed by 4-install-omarchy.sh
set -l omarchy_root "$layer_root"

if test -f "\$omarchy_root/.config/starship.toml"
    set -gx STARSHIP_CONFIG "\$omarchy_root/.config/starship.toml"
end

if test -f "\$omarchy_root/.config/fish/config.fish"
    source "\$omarchy_root/.config/fish/config.fish"
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
source = ~/.config/dotfiles/omarchy/.config/hypr/hyprland.conf
EOF

    ensure_line "$HOME/.config/hypr/hyprland.conf" "source = ~/.config/hypr/omarchy-user.conf"

    if [ -f "$layer_root/.config/hypr/hyprland.conf" ]; then
        log "Installed Hyprland include hook"
    else
        warn "Staged Hyprland config not found under $layer_root/.config/hypr"
    fi
}

apply_app_symlinks() {
    local layer_root="$1"

    local app_packages=(
        ghostty
        fuzzel
        fastfetch
        nvim
        mango
        vicinae
        filen
    )

    local backup_targets=(
        "$HOME/.config/ghostty"
        "$HOME/.config/fuzzel"
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

What this script does:
- Installs packages via yay (fish, zsh, ghostty, starship, fastfetch, fzf, neovim, etc.)
- Stages shell, Hyprland, and app configs into ~/.config/dotfiles/omarchy using stow
- Adds source/include hooks for shell + Hyprland
- Sets your default shell (fish or zsh)
- Fixes /etc/nsswitch.conf for DNS resolution
- Does NOT overwrite app config directories (unless --apply-apps is passed)

Options:
  --apply-apps   Backup and symlink app config directories from staged layer
  -h, --help     Show this help
EOF
}

main() {
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

    ensure_sudo_access
    install_with_yay

    require_cmd stow
    require_cmd grep

    local script_dir repo_root
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    repo_root="$script_dir"

    local config_home layer_root
    config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    layer_root="$config_home/dotfiles/omarchy"

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

    ensure_default_shell

    # Fix nsswitch.conf to prioritize DNS over LLMNR for name resolution
    sudo sed -i 's/^hosts:.*/hosts: files dns resolve myhostname mymachines/' /etc/nsswitch.conf

    log "Done. Omarchy base files were preserved; your overrides live in $layer_root"
    echo
    read -rp "Would you like to reboot now? [y/N]: " answer
    case "$answer" in
        [Yy]*)
            log "Rebooting..."
            sudo reboot
            ;;
        *)
            log "Reboot skipped. Please reboot manually if needed."
            ;;
    esac
}

main "$@"
