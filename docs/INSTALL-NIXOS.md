# Install and test the generic NixOS configuration

## The four-step install process

Boot the official NixOS installer and connect it to the network:

```bash
# 1. Identify the disposable whole target disk.
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS

# 2. Start the installer. It asks for the disk and profile.
curl -fsSL https://raw.githubusercontent.com/jbattist/dotfiles/main/install-nixos | sh

# 3. Answer its prompts, then wait for "INSTALLATION COMPLETE".

# 4. Reboot and remove the installer ISO.
reboot
```

That is the supported installation interface. You do **not** clone the repo,
install Git or jq, set `NIX_CONFIG`, invoke disko, edit a Nix file, or generate a
password hash. The bootstrap supplies a current Nix even when the ISO's Nix is
old; the real installer app then uses this repo's pinned inputs.

The app validates the disk, refuses partitions/mounted disks, prints the exact
target, requires an exact destructive confirmation, partitions/formats/mounts,
builds and installs NixOS, and prompts for the initial `joe` password.

> **Destructive operation:** installation erases the entire selected disk. The
> generic layout uses UEFI/GPT and Btrfs. It does not support dual boot, BIOS
> boot, encryption, or in-place conversion.

Profiles:

- `generic`: core Umbriel desktop, ~8 GiB closure (recommended)
- `generic-work`: core desktop with work layout
- `generic-laptop`: core desktop with laptop layout
- `generic-full`: default layout plus the large interactive/work application set

Press Enter at the profile prompt to select `generic`. `generic-full` includes
Chrome, Obsidian, VS Code, Zed, Kiro, Claude Code, OpenCode, Slack and the three
Craft applications; use a substantially larger virtual disk for it.

## Non-destructive installer test

Use the same command with `--dry-run` after the app separator:

```bash
curl -fsSL https://raw.githubusercontent.com/jbattist/dotfiles/main/install-nixos \
  | sh -s -- --dry-run /dev/vda generic
```

The app validates the disk and builds the pinned disk-layout script, but does
not execute it. A successful result ends with `DRY RUN PASSED`.

## Test the configuration in a VM instead

On an existing Linux system with Nix and KVM:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  run github:jbattist/dotfiles#generic-vm
```

Login:

```text
user: joe
password: test
```

The password exists only in the disposable VM variant; it is not part of a real
installation.

Other VM profiles:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  run github:jbattist/dotfiles#generic-work-vm

nix --extra-experimental-features 'nix-command flakes' \
  run github:jbattist/dotfiles#generic-laptop-vm
```

## Custom installer ISO

The custom ISO contains the installer as a normal `install-nixos` command, so
its console flow is even shorter:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
sudo install-nixos /dev/vda generic
reboot
```

Build it from another Nix machine with:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  build github:jbattist/dotfiles#installer-iso
```

## After first boot

The system is already installed from the pinned flake. Clone the repository only
when you want to edit and rebuild it locally:

```bash
nix-shell -p git
git clone https://github.com/jbattist/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo nixos-rebuild switch --flake .#generic
```

Use the profile selected during installation. Then inspect failures:

```bash
systemctl --failed
systemctl --user --failed
resolvectl status
```

The wallpaper directory is created but deliberately empty. Populate:

```text
~/.local/share/wallpapers
```

## Current limitations

- Desktop is **Umbriel + Noctalia v5**, logged in through the Noctalia greeter.
  Niri and Hyprland are not installed. (Noctalia v5 is native C++; the old v4
  `noctalia-shell` Quickshell build does not compile against Qt 6.12.)
- UEFI x86_64 only.
- Common NVMe/SATA/USB storage drivers are included; unusual controllers need a
  hardware override.
- No disk encryption or dual boot yet.
- Outputs are autodetected. Fixed scale/position needs a profile override later.
- The core desktop has not yet been boot-tested on physical hardware.
- A 32 GiB disk is for the core test profile. Use at least 64 GiB (preferably
  100+ GiB) for `generic-full` and long-lived Nix generations.
- Noctalia/Vicinae/Plasma files managed by home-manager are read-only; use the
  `jb.opts.desktop.manage*` switches if their GUIs need ownership.
- Homelab packages and CIFS mounts are disabled in generic profiles.
