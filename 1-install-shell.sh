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

install_release_ubuntu() {
	# Install tools that have no Ubuntu APT package from their upstream
	# release assets into ~/.local/bin (deb via apt for fastfetch).
	local pkg m arch_rust arch_deb tmp folder asset
	pkg="$1"
	m=$(uname -m)
	case "$m" in
		x86_64) arch_rust=x86_64; arch_deb=amd64 ;;
		aarch64|arm64) arch_rust=aarch64; arch_deb=arm64 ;;
		*) err "Unsupported architecture $m for $pkg"; return 1 ;;
	esac
	mkdir -p "$HOME/.local/bin"
	tmp=$(mktemp -d)
	case "$pkg" in
		starship)
			log "Installing starship from starship.rs into ~/.local/bin"
			curl -fsSL https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" -y \
				|| { err "starship install failed"; rm -rf "$tmp"; return 1; }
			;;
		yazi)
			if ! command -v unzip >/dev/null 2>&1; then
				sudo apt-get install -y unzip
			fi
			folder="yazi-${arch_rust}-unknown-linux-gnu"
			asset="${folder}.zip"
			log "Installing yazi from GitHub releases (${asset})"
			curl -fsSL -o "$tmp/$asset" \
				"https://github.com/sxyazi/yazi/releases/latest/download/$asset" \
				|| { err "yazi download failed"; rm -rf "$tmp"; return 1; }
			unzip -o -q "$tmp/$asset" -d "$tmp" \
				|| { err "yazi unzip failed"; rm -rf "$tmp"; return 1; }
			install -m755 "$tmp/$folder/yazi" "$HOME/.local/bin/"
			install -m755 "$tmp/$folder/ya" "$HOME/.local/bin/"
			;;
		fastfetch)
			asset="fastfetch-linux-${arch_deb}.deb"
			log "Installing fastfetch from GitHub releases (${asset})"
			curl -fsSL -o "$tmp/$asset" \
				"https://github.com/fastfetch-cli/fastfetch/releases/latest/download/$asset" \
				|| { err "fastfetch download failed"; rm -rf "$tmp"; return 1; }
			sudo apt-get install -y "$tmp/$asset" \
				|| { err "fastfetch deb install failed"; rm -rf "$tmp"; return 1; }
			;;
		*)
			err "install_release_ubuntu: unknown package $pkg"
			rm -rf "$tmp"
			return 1
			;;
	esac
	rm -rf "$tmp"
	if command -v "$pkg" >/dev/null 2>&1; then
		log "$pkg installed ($(command -v "$pkg"))"
	else
		err "$pkg installed but not on PATH; ensure ~/.local/bin is in your PATH"
	fi
}

install_thefuck_ubuntu() {
	# apt's thefuck (3.29) and PyPI's 3.32 both die on Python 3.12+:
	# removed 'distutils' and 'imp' stdlib modules. Install via pipx, then
	# patch the venv: setuptools restores distutils, a shim restores imp.
	local venv sp
	log "Installing thefuck via pipx (apt build is broken on Python 3.12+)"
	command -v pipx >/dev/null 2>&1 || sudo apt-get install -y pipx
	if dpkg-query -W -f='${Status}' thefuck 2>/dev/null | grep -qx 'install ok installed'; then
		log "Removing broken apt thefuck before pipx install"
		sudo apt-get remove -y thefuck
	fi
	if command -v fuck >/dev/null 2>&1 && fuck --version >/dev/null 2>&1; then
		log "thefuck already installed and working"
		return 0
	fi
	pipx install thefuck || { err "pipx install thefuck failed"; return 1; }
	venv="$HOME/.local/share/pipx/venvs/thefuck"
	sp="$venv/lib/python3.*/site-packages"
	log "Patching thefuck venv for Python 3.12 (setuptools + imp shim)"
	pipx inject thefuck setuptools >/dev/null 2>&1
	# shellcheck disable=SC2086
	cat > ${sp}/imp.py <<'EOF'
"""Compatibility shim: imp was removed in Python 3.12; thefuck still uses it."""
from importlib.machinery import SourceFileLoader

def load_source(name, path):
    loader = SourceFileLoader(name, path)
    return loader.load_module()
EOF
	if command -v fuck >/dev/null 2>&1 && fuck --version >/dev/null 2>&1; then
		log "thefuck installed via pipx and working"
	else
		err "thefuck still not working after patch; leaving install as-is"
		return 1
	fi
}

install_on_ubuntu() {
	local script_dir repo_root pkg apt_pkg
	local -a missing=()
	export PATH="$HOME/.local/bin:$PATH"
	mkdir -p "$HOME/.local/bin"
	script_dir=$(cd "$(dirname "$(resolve_script_dir)")" && pwd)
	repo_root=$(cd "$script_dir" && pwd)
	# shellcheck source=/dev/null
	. "$repo_root/scripts/package-lib.sh"
	require_cmd apt-get
	require_cmd apt-cache
	sudo apt-get update
	while IFS= read -r pkg; do
		case "$pkg" in
			starship|yazi|fastfetch)
				if command -v "$pkg" >/dev/null 2>&1; then
					log "$pkg already installed ($pkg)"
				else
					install_release_ubuntu "$pkg" \
						|| missing+=("$pkg (release install failed)")
				fi
				continue ;;
			thefuck)
				# Probe with --version: apt's 3.29 crashes on Python 3.12+
				# before the dpkg check can pass it as healthy.
				if command -v fuck >/dev/null 2>&1 && fuck --version >/dev/null 2>&1; then
					log "thefuck already installed"
				else
					install_thefuck_ubuntu \
						|| missing+=("thefuck (pipx install failed)")
				fi
				continue ;;
			fd) apt_pkg=fd-find ;;
			bind-tools) apt_pkg=dnsutils ;;
			nfs-utils) apt_pkg=nfs-common ;;
			herdr-bin|sysz|isd|ghostty|wezterm)
				case "$pkg" in herdr-bin) apt_pkg=herdr ;; *) apt_pkg=$pkg ;; esac
				if command -v "$apt_pkg" >/dev/null 2>&1; then
					log "$pkg already installed ($apt_pkg)"
				else
					missing+=("$pkg (no Ubuntu APT package in this installer)")
				fi
				continue ;;
			*) apt_pkg=$pkg ;;
		esac
		if dpkg-query -W -f='${Status}' "$apt_pkg" 2>/dev/null | grep -qx 'install ok installed'; then
			log "$apt_pkg already installed"
			# Ubuntu ships renamed binaries for conflicting package names.
			case "$apt_pkg" in
				bat) [ -e "$HOME/.local/bin/bat" ] || ln -s /usr/bin/batcat "$HOME/.local/bin/bat" ;;
				fd-find) [ -e "$HOME/.local/bin/fd" ] || ln -s /usr/bin/fdfind "$HOME/.local/bin/fd" ;;
			esac
		elif apt-cache show "$apt_pkg" >/dev/null 2>&1; then
			log "Installing $apt_pkg via APT"
			sudo apt-get install -y "$apt_pkg"
			case "$apt_pkg" in
				bat) ln -s /usr/bin/batcat "$HOME/.local/bin/bat" ;;
				fd-find) ln -s /usr/bin/fdfind "$HOME/.local/bin/fd" ;;
			esac
		else
			missing+=("$pkg (APT package $apt_pkg unavailable)")
		fi
	done < <(parse_manifest "$repo_root/manifests/packages/shell" | dedupe_lines)
	if ((${#missing[@]})); then
		err "Ubuntu packages requiring separate installation:"
		printf '[!]   %s\n' "${missing[@]}" >&2
	fi
}

install_with_yay() {
	local script_dir repo_root
	script_dir=$(cd "$(dirname "$(resolve_script_dir)")" && pwd)
	repo_root=$(cd "$script_dir" && pwd)
	# Package ownership lives in the shell manifest; this script retains yay bootstrap.
	# shellcheck source=/dev/null
	. "$repo_root/scripts/package-lib.sh"
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

	mapfile -t packages < <(parse_manifest "$repo_root/manifests/packages/shell" | dedupe_lines)
	for pkg in "${packages[@]}"; do
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

	backup_and_stow "$repo_root" zshrc ".zshrc"
	backup_and_stow "$repo_root" fish ".config/fish"
	# Stow the whole starship package: installs starship.toml and
	# update-noctalia-starship.py together into ~/.config/
	backup_path "$HOME/.config/starship.toml"
	backup_path "$HOME/.config/update-noctalia-starship.py"
	stow_pkg "$repo_root" "starship"
	backup_and_stow "$repo_root" fastfetch ".config/fastfetch"
	backup_and_stow "$repo_root" ghostty ".config/ghostty"
	backup_and_stow "$repo_root" nvim ".config/nvim"
    backup_and_stow "$repo_root" wezterm ".wezterm.lua"
    backup_and_stow "$repo_root" micro ".config/micro"
	# Stow tracked Yazi config files without absorbing generated plugins/flavors.
	# Pick up newly added top-level configs (e.g. yazi.toml) automatically.
	mkdir -p "$HOME/.config/yazi"
	local yazi_source yazi_target
	for yazi_source in "$repo_root/yazi/.config/yazi/"*.lua "$repo_root/yazi/.config/yazi/"*.toml; do
		[ -f "$yazi_source" ] || continue
		yazi_target="$HOME/.config/yazi/$(basename "$yazi_source")"
		if [ "$yazi_target" -ef "$yazi_source" ]; then
			continue
		fi
		backup_path "$yazi_target"
	done
	stow_pkg "$repo_root" yazi
	if command -v ya >/dev/null 2>&1; then
		log "Installing Yazi plugins from package.toml"
		ya pkg install
	fi
	backup_and_stow "$repo_root" thefuck ".config/thefuck"
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
	printf '  1) fish\n' >&2
	printf '  2) zsh\n' >&2
	printf '  3) keep current shell (default)\n' >&2
	read -rp "Selection [1/2/3]: " shell_choice

	case "$shell_choice" in
		1)
			printf '%s' "fish"
			;;
		2)
			printf '%s' "zsh"
			;;
		""|3)
			printf '%s' "skip"
			;;
		*)
			err "Invalid shell selection: $shell_choice"
			exit 1
			;;
	esac
}

configure_npm_user_prefix() {
	# Keep npm global packages user-local so tools such as Log4brains do not
	# write into /usr/lib/node_modules and leave root-owned build artifacts.
	if ! command -v npm >/dev/null 2>&1; then
		log "npm not installed; skipping user-local npm configuration"
		return
	fi

	local npm_prefix="$HOME/.local"
	log "Configuring npm global packages under $npm_prefix"
	npm config set prefix "$npm_prefix"
	export PATH="$npm_prefix/bin:$PATH"
}

install_gaze() {
	# gaze: personal Rust TUI hosted on the homelab Forgejo. Prefer the checksummed
	# release asset; fall back to building the pinned tag from source.
	local base="${FORGEJO_URL:-http://forgejo.home}"
	local repo="joe/gaze"
	local fallback_version="v0.2.1"
	# GAZE_VERSION=vX.Y.Z pins a version; otherwise use the newest published release.
	local version="${GAZE_VERSION:-}"
	if [[ -z "$version" ]]; then
		version="$(curl -fsSL --connect-timeout 5 "$base/api/v1/repos/$repo/releases/latest" 2>/dev/null \
			| grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')" || true
		if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			err "Could not resolve latest gaze release; using $fallback_version"
			version="$fallback_version"
		fi
	fi
	local bin_dir="$HOME/.local/bin"
	local arch asset tmp

	if command -v gaze >/dev/null 2>&1 && [[ "$(gaze --version 2>/dev/null)" == "gaze ${version#v}" ]]; then
		log "gaze ${version} already installed"
		return 0
	fi

	arch="$(uname -m)"
	asset="gaze-${arch}-linux"
	tmp="$(mktemp -d)"
	mkdir -p "$bin_dir"

	log "Installing gaze ${version}"
	if curl -fsSL --connect-timeout 5 -o "$tmp/$asset" "$base/$repo/releases/download/$version/$asset" \
		&& curl -fsSL --connect-timeout 5 -o "$tmp/SHA256SUMS" "$base/$repo/releases/download/$version/SHA256SUMS-${arch}" \
		&& (cd "$tmp" && sha256sum -c SHA256SUMS >/dev/null); then
		install -m755 "$tmp/$asset" "$bin_dir/gaze"
	elif command -v cargo >/dev/null 2>&1; then
		err "gaze release asset unavailable or failed checksum; building $version from source"
		cargo install --locked --root "$HOME/.local" --git "$base/$repo.git" --tag "$version" gaze \
			|| { err "gaze install failed; skipping"; rm -rf "$tmp"; return 0; }
	else
		err "gaze release unavailable and cargo not installed; skipping"
	fi
	rm -rf "$tmp"
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

configure_systemd_resolved() {
    log "Configuring systemd-resolved to use DHCP-provided DNS"
    # The service must be running for the stub at /run/systemd/resolve/stub-resolv.conf
    # to exist; otherwise /etc/resolv.conf points at a dead socket and ALL lookups
    # fail (NXDOMAIN/unknown unit). Enable+start here so script 1 is self-sufficient;
    # manifests/services/common.enable keeps this enforced for step-2 hosts too.
    if ! systemctl is-enabled --quiet systemd-resolved; then
        log "Enabling systemd-resolved.service"
        sudo systemctl enable systemd-resolved
    fi
    if ! systemctl is-active --quiet systemd-resolved; then
        log "Starting systemd-resolved.service"
        sudo systemctl start systemd-resolved
    fi

    sudo mkdir -p /etc/systemd/resolved.conf.d
    sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null << 'EOF'
[Resolve]
Domains=home
DNSStubListener=yes
FallbackDNS=
EOF

    if systemctl is-active --quiet NetworkManager; then
        log "NetworkManager detected, configuring dns=systemd-resolved"
        sudo mkdir -p /etc/NetworkManager/conf.d
        sudo tee /etc/NetworkManager/conf.d/dns.conf > /dev/null << 'EOF'
[main]
dns=systemd-resolved
EOF

        # Only configure host uplinks, not Docker bridges or loopback profiles.
        # Those may use ipv6.method=link-local, which rejects ipv6.dns-search.
        while IFS=: read -r uuid type device; do
            case "$type" in
                802-3-ethernet|802-11-wireless) ;;
                *) continue ;;
            esac
            [[ -n "$device" ]] || continue

            log "Setting dns-search on connection: $uuid ($device)"
            sudo nmcli con modify "$uuid" ipv4.dns-search "home"
            if [[ "$(nmcli -g ipv6.method con show "$uuid")" != link-local ]]; then
                sudo nmcli con modify "$uuid" ipv6.dns-search "home"
            fi

            # Remove manual DNS overrides and allow DHCP to provide DNS
            sudo nmcli con modify "$uuid" ipv4.dns ""
            sudo nmcli con modify "$uuid" ipv6.dns ""
            sudo nmcli con modify "$uuid" ipv4.ignore-auto-dns no
            sudo nmcli con modify "$uuid" ipv6.ignore-auto-dns no
        done < <(nmcli -t -f UUID,TYPE,DEVICE con show --active)
    else
        log "No NetworkManager, using systemd-networkd with resolved"
    fi

    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    log "systemd-resolved is enabled, active, and configured for DHCP-provided DNS"
}

configure_pacman_colors() {
	log "Enabling Color and ILoveCandy in /etc/pacman.conf"
	sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
	if ! grep -q '^ILoveCandy' /etc/pacman.conf; then
		sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
	fi
}

main() {
	# Arch-specific DNS and pacman changes must never be applied on Ubuntu.
	# Check the OS before package bootstrap or any system configuration.
	# shellcheck source=/dev/null
	. /etc/os-release
	case "$ID" in
		arch|cachyos|endeavouros|manjaro)
			install_with_yay
			configure_pacman_colors
			configure_systemd_resolved
			;;
		ubuntu)
			install_on_ubuntu
			;;
		*)
			err "Unsupported distribution: $ID. No changes made."
			return 1
			;;
	esac
	link_dotfiles
	configure_npm_user_prefix
	install_gaze
	ensure_sudo_access
	ensure_default_shell

	if [[ "$ID" != ubuntu ]]; then
		# Arch's nsswitch policy; Ubuntu retains its distribution defaults.
		sudo sed -i 's/^hosts:.*/hosts: files dns resolve myhostname mymachines/' /etc/nsswitch.conf
	fi
	
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
