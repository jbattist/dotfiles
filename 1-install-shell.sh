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

resolve_script_dir() {
	if [ -n "${BASH_SOURCE:-}" ]; then
		printf '%s' "${BASH_SOURCE[0]}"
	elif [ -n "${ZSH_VERSION:-}" ]; then
		printf '%s' "${(%):-%x}"
	else
		printf '%s' "$0"
	fi
}

install_with_yay() {
	if ! command -v yay >/dev/null 2>&1; then
		log "'yay' not found. Installing yay..."
		require_cmd git || { err "git is required to install yay."; exit 1; }
		require_cmd make || { err "make is required to install yay."; exit 1; }
		require_cmd gcc || { err "gcc is required to install yay."; exit 1; }
		tmpdir=$(mktemp -d)
		git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
		(cd "$tmpdir/yay" && makepkg -si --noconfirm)
		rm -rf "$tmpdir"
	fi

	packages="fish zsh starship fzf zsh-autosuggestions zsh-syntax-highlighting eza zoxide stow fastfetch ghostty micro bat fd"

	for pkg in $packages; do
		if yay -Qi "$pkg" >/dev/null 2>&1; then
			log "$pkg already installed"
		else
			log "Installing $pkg via yay"
			yay -S --needed --noconfirm "$pkg"
		fi
	done
}

link_dotfiles() {
	local script_path script_dir repo_root
	script_path=$(resolve_script_dir)
	script_dir=$(cd "$(dirname "$script_path")" && pwd)
	repo_root=$(cd "$script_dir" && pwd)

	require_cmd stow

	log "Linking .zshrc via stow"
	stow -d "$repo_root" -R -t "$HOME" zshrc

	log "Linking fish config via stow"
	stow -d "$repo_root" -R -t "$HOME" fish

	log "Linking starship config via stow"
	stow -d "$repo_root" -R -t "$HOME" starship

	log "Linking fastfetch config via stow"
	stow -d "$repo_root" -R -t "$HOME" fastfetch

	log "Linking ghostty config via stow"
	# Backup existing ghostty config if it exists
	ghostty_target="$HOME/.config/ghostty"
	if [ -e "$ghostty_target" ] || [ -L "$ghostty_target" ]; then
		backup_name="$ghostty_target.backup.$(date +%Y%m%d%H%M%S)"
		log "Backing up existing ghostty config to $backup_name"
		mv "$ghostty_target" "$backup_name"
	fi
	stow -d "$repo_root" -R -t "$HOME" ghostty
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

	echo
	echo "Choose your default shell:"
	echo "  1) fish (recommended, default)"
	echo "  2) zsh"
	echo "  3) keep current shell"
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
	chsh -s "$shell_path"
}

main() {
	install_with_yay
	link_dotfiles
	ensure_default_shell

	# Fix nsswitch.conf to prioritize DNS over LLMNR for name resolution
	sudo sed -i 's/^hosts:.*/hosts: files dns resolve myhostname mymachines/' /etc/nsswitch.conf
	
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
