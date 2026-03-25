#!/usr/bin/env bash

# Ensures the script behaves consistently when run via zsh
if [ -n "${ZSH_VERSION:-}" ]; then
	emulate -L sh 2>/dev/null || true
fi

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
		return 1
	fi
}

ensure_sudo_access() {
	if [ "$(id -u)" -eq 0 ]; then
		return
	fi

	log "Requesting sudo access for system updates"
	sudo -v
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
	local repo_root="$1"
	local pkg="$2"
	log "Stowing package: $pkg"
	stow -d "$repo_root" -R -t "$HOME" "$pkg"
}

backup_and_stow() {
	local repo_root="$1"
	local pkg="$2"
	local target_rel="$3"
	local target_path="$HOME/$target_rel"

	# Ensure parent directory exists so stow does not link parent paths unexpectedly.
	mkdir -p "$(dirname "$target_path")"

	backup_path "$target_path"
	stow_pkg "$repo_root" "$pkg"
}

resolve_script_dir() {
	if [ -n "${BASH_SOURCE:-}" ]; then
		printf '%s' "${BASH_SOURCE[0]}"
	elif [ -n "${ZSH_VERSION:-}" ]; then
		printf '%s' "${(%):-%x}"
	else
		printf '%s' "$0"
	fi
}

install_eza() {
	if command -v eza >/dev/null 2>&1; then
		log "eza already installed"
		return
	fi
	log "Installing eza via official deb repo"
	sudo mkdir -p /etc/apt/keyrings
	wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
		| sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
	echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
		| sudo tee /etc/apt/sources.list.d/gierens.list
	sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
	sudo apt-get update -y
	sudo apt-get install -y eza
}

install_starship() {
	if command -v starship >/dev/null 2>&1; then
		log "starship already installed"
		return
	fi
	log "Installing starship via official installer"
	require_cmd curl
	curl -sS https://starship.rs/install.sh | sh -s -- --yes
}

install_fastfetch() {
	if command -v fastfetch >/dev/null 2>&1; then
		log "fastfetch already installed"
		return
	fi
	log "Installing fastfetch from GitHub releases"
	require_cmd curl
	local ver
	ver=$(curl -sSf https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
		| grep '"tag_name"' | cut -d'"' -f4)
	local deb="/tmp/fastfetch.deb"
	curl -sLo "$deb" \
		"https://github.com/fastfetch-cli/fastfetch/releases/download/${ver}/fastfetch-linux-amd64.deb"
	sudo dpkg -i "$deb"
	rm -f "$deb"
}

install_zoxide() {
	if command -v zoxide >/dev/null 2>&1; then
		log "zoxide already installed"
		return
	fi
	log "Installing zoxide via official installer"
	require_cmd curl
	curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_ghostty() {
	if command -v ghostty >/dev/null 2>&1; then
		log "ghostty already installed"
		return
	fi
	log "Installing ghostty from GitHub releases"
	require_cmd curl
	local ver
	ver=$(curl -sSf https://api.github.com/repos/ghostty-org/ghostty/releases/latest \
		| grep '"tag_name"' | cut -d'"' -f4)
	local deb="/tmp/ghostty.deb"
	local url="https://github.com/ghostty-org/ghostty/releases/download/${ver}/ghostty_${ver#v}_amd64.deb"
	if curl -sLfo "$deb" "$url" && [ -s "$deb" ]; then
		sudo dpkg -i "$deb"
		rm -f "$deb"
	else
		rm -f "$deb"
		err "ghostty .deb not found for $ver — install manually from https://ghostty.org"
	fi
}

install_with_apt() {
	log "Updating apt package list"
	sudo apt-get update -y

	local apt_packages=(
		# Shells
		fish
		zsh
		zsh-autosuggestions
		zsh-syntax-highlighting

		# Prompt & utilities
		fzf
		fd-find
		bat

		# Dotfile management & tools
		stow

		# Editors
		micro
		neovim

		# Build / fetch deps
		git
		curl
		wget
		gpg
	)

	for pkg in "${apt_packages[@]}"; do
		if dpkg -s "$pkg" >/dev/null 2>&1; then
			log "$pkg already installed"
		else
			log "Installing $pkg via apt"
			sudo apt-get install -y "$pkg"
		fi
	done

	# Packages not in standard Debian repos
	install_eza
	install_starship
	install_fastfetch
	install_zoxide
	# install_ghostty
}

link_dotfiles() {
	local script_path script_dir repo_root
	script_path=$(resolve_script_dir)
	script_dir=$(cd "$(dirname "$script_path")" && pwd)
	repo_root=$(cd "$script_dir" && pwd)

	require_cmd stow

	backup_and_stow "$repo_root" zshrc ".zshrc"
	backup_and_stow "$repo_root" fish ".config/fish"
	# Stow the whole starship package: installs starship.toml and
	# update-noctalia-starship.py together into ~/.config/
	backup_path "$HOME/.config/starship.toml"
	backup_path "$HOME/.config/update-noctalia-starship.py"
	stow_pkg "$repo_root" "starship"
	backup_and_stow "$repo_root" fastfetch ".config/fastfetch"
	# backup_and_stow "$repo_root" ghostty ".config/ghostty"
	backup_and_stow "$repo_root" nvim ".config/nvim"
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
		""|1)
			printf '%s' "fish"
			;;
		2)
			printf '%s' "zsh"
			;;
		3)
			printf '%s' "skip"
			;;
		*)
			err "Invalid shell selection: $shell_choice"
			exit 1
			;;
	esac
}

ensure_default_shell() {
	local target_shell shell_path selected_shell
	selected_shell=$(choose_default_shell)

	if [ "$selected_shell" = "skip" ]; then
		log "Keeping current default shell unchanged"
		return
	fi

	target_shell="$selected_shell"
	if ! shell_path=$(command -v "$target_shell"); then
		err "$target_shell is not installed or not in PATH"
		exit 1
	fi

	if [ "${SHELL:-}" = "$shell_path" ]; then
		log "$target_shell is already the default shell"
		return
	fi

	log "Setting default shell to $target_shell (you may be prompted for your password)"
	if [ "$(id -u)" -eq 0 ]; then
		chsh -s "$shell_path" "${SUDO_USER:-$USER}"
	else
		sudo chsh -s "$shell_path" "$USER"
	fi
}

main() {
	ensure_sudo_access
	install_with_apt
	link_dotfiles
	ensure_default_shell

	# Fix nsswitch.conf to prioritize DNS over LLMNR for name resolution
	sudo sed -i 's/^hosts:.*/hosts: files dns resolve myhostname/' /etc/nsswitch.conf

	log "Setup complete. Open a new terminal session to use your selected shell."
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
