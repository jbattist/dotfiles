# dotfiles

Personal Linux dotfiles for Arch-family desktops, centered on niri and Noctalia. The shell bootstrap also has an Ubuntu path; the interactive desktop package installer is Arch-only. Configs are grouped as GNU Stow packages, while package and system-service manifests are separate from dotfile installation.

## v3 at a glance

- Package groups live in `manifests/packages/`; systemd service policy lives in `manifests/services/`. Selecting groups installs packages and reconciles their services.
- `1-install-shell.sh` bootstraps shell tools and stows terminal/application configs. `3-install-dots.sh` stows desktop configs and selects a machine profile.
- Desktop choices include niri, Hyprland, Mango, and Umbriel; Noctalia uses `config.toml` (v5), not the old `settings.json`.
- Yazi config and plugin declarations, Paneru, Vicinae, and per-machine Niri/Umbriel files are tracked. Tracked `noctalia-v4-backup/` is historical, not the installed Noctalia config.

## Layout

| Path | Purpose |
|------|---------|
| `1-install-shell.sh` | Shell package bootstrap, terminal/editor/Yazi Stow packages, optional default shell |
| `2-install-pkgs.sh` | Interactive Arch package selection and service reconciliation |
| `3-install-dots.sh` | Desktop Stow packages and Niri machine config |
| `4-git-config.sh` | Optional personal global Git defaults and identity; inspect before running |
| `manifests/packages/` | One package name per line; `shell` is used by step 1 and excluded from the step 2 picker |
| `manifests/services/` | `common` and selected-group `.enable` / `.disable` systemd unit lists |
| `tests/` | Mocked package and service installer tests |

Stow packages installed by step 1: `zshrc`, `fish`, `starship`, `fastfetch`, `ghostty`, `nvim`, `wezterm`, `micro`, `yazi`, `thefuck`. Step 1 also runs `ya pkg install` if `ya` is available. Step 3 installs `wallpapers`, `niri`, `noctalia`, `umbriel`, `fuzzel`, `hyprland`, `systemd` (user portal override), `gtk`, and `plasma`. Other tracked configs, such as `mango`, `paneru`, `swayidle`, and `vicinae`, are **not** installed by these scripts; stow them deliberately if wanted (for example `stow -d ~/dotfiles -t ~ paneru`). Review conflicts before doing so.

## Install

These scripts change packages, services, DNS/shell settings, and existing config paths. Read them first and take a backup of important local config. Stow installers move conflicting paths to timestamped `.backup.*` names; do not assume a no-op on every rerun. Do not run the whole sequence merely to pick up a single changed config.

```bash
git clone https://github.com/jbattist/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash 1-install-shell.sh
```

Step 1 reads `manifests/packages/shell`, installs via `yay` on supported Arch-family systems (bootstrapping `yay` if necessary), or uses APT for available packages on Ubuntu and reports unsupported ones. On Arch it also configures `systemd-resolved`, NetworkManager/system DNS, and pacman colors; it can change the login shell and offers a reboot. On Ubuntu it does not apply the Arch DNS/pacman changes. `DEFAULT_SHELL=skip bash 1-install-shell.sh` leaves the default shell unchanged, but does not skip other effects.

On an Arch-family machine, optionally install desktop packages:

```bash
bash 2-install-pkgs.sh
```

Use Tab to select manifests in `fzf`, Enter to install, or Escape to cancel. The script requires `yay`, updates the system with `pacman -Syu`, installs missing selected packages, and applies the selected groups' service manifests plus `common` service policy. Selecting `gaming` also enables the pacman `multilib` stanza. **Do not use this step on Ubuntu**; it invokes pacman and systemd. See `manifests/packages/README.md` and `manifests/services/README.md` before editing manifests.

Install desktop config separately:

```bash
bash 3-install-dots.sh
```

This requires `stow` and `jq`, creates `~/Pictures/Screenshots`, restows the desktop packages listed above, and installs a user portal override with `systemctl --user`. It asks for `home`, `work`, or `laptop`, saves the choice to `~/.config/dotfiles/machine.env`, and generates `~/.config/niri/machine.kdl` from the matching template. Set `MACHINE=home` (or `work` / `laptop`) to skip the prompt. A subsequent interactive run asks whether to retain the saved profile. If Niri is running, the installer uses `niri msg --json outputs` to substitute the first connector; otherwise it comments out the template output block. Re-run inside Niri or update the live file with the connector reported by `niri msg outputs`.

Step 3 does **not** install GUI packages or apply system-level service manifests. The user portal override is separate from the system-service policy in step 2. On machines without a running user systemd manager, inspect the script before running it.

## Updating and machine-local state

Pull or reconcile your branch before re-stowing. If other machines have committed changes, avoid a blind `git pull` over local edits; inspect `git status` and `git fetch` first. Run only the relevant installer for the configs you changed, and review any backups it makes.

- `~/.config/dotfiles/machine.env` is the local machine selection. The generated `~/.config/niri/machine.kdl` is also local; edit its `machine.kdl.<profile>` template for changes you want in Git. `niri/.config/niri/output.kdl` is ignored for local output settings.
- The active Noctalia v5 config is `noctalia/.config/noctalia/config.toml`. Runtime colors and plugins are ignored under the active directory; the tracked `noctalia-v4-backup/` is an archival copy. Do not edit its `settings.json` expecting it to change v5.
- `nvim/.config/nvim/lazy-lock.json` and `fish/.config/fish/fish_variables` are ignored; keep secrets and machine-specific tokens out of tracked config. `.gitignore` is not a substitute for checking already-tracked files.
- To add a Niri profile, copy `niri/.config/niri/machine.kdl.home` to `machine.kdl.<new-name>`, edit it, then add the new choice to `3-install-dots.sh`. Package selection remains independent of the profile.

## Checks

Run the mocked package and service tests without installing anything:

```bash
bash tests/run.sh
bash tests/service-run.sh
```

The tests cover manifest selection and service actions, not an end-to-end desktop install. Shell syntax can be checked with `bash -n` on the shell scripts. Historical `.bak`, `.bad`, and `noctalia-v4-backup/` files are tracked in parts of the repo; review before using or pruning them.
