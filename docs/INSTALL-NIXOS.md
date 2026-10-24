# Test and install the generic NixOS configuration

The commands below assume this repository is checked out as `~/dotfiles`.

## Available builds

| Flake target | Use |
|---|---|
| `generic` | Default/home desktop profile |
| `generic-work` | Work layout and app rules |
| `generic-laptop` | Wider laptop columns and touchpad policy |
| `installer` | Graphical NixOS installer ISO |

The three installed targets share the same package and service selection. Their
only intentional differences are the niri/Umbriel layouts migrated from the old
`home`, `work`, and `laptop` templates. Outputs are autodetected; no connector
name, hostname, or existing machine is baked into the build.

## 1. Evaluate it without installing NixOS

On any Linux machine with flakes enabled:

```bash
cd ~/dotfiles
nix flake check
nix eval .#nixosConfigurations.generic.config.system.build.toplevel.drvPath
```

`nix flake check` evaluates all profiles and builds the generated niri and
Umbriel files. It does not build the entire graphical application closure.

To build the full system without changing the current OS:

```bash
nix build .#nixosConfigurations.generic.config.system.build.toplevel
```

This can download/build several gigabytes (Chrome, Obsidian, IDEs, etc.).

## 2. Boot it safely in a VM

Requirements: Linux, KVM (`/dev/kvm`), and a graphical session.

```bash
cd ~/dotfiles
nix run .#generic-vm
```

For another profile:

```bash
nix run .#generic-work-vm
nix run .#generic-laptop-vm
```

The VM-specific login is:

```text
user: joe
password: test
```

That password is defined only in `virtualisation.vmVariant`; it is not present
in the real installation configuration. VM disk state is disposable.

## 3. Optionally build the installer ISO

```bash
cd ~/dotfiles
nix build .#installer-iso
ls -lh result/iso/
```

Write the ISO to a USB drive using your preferred tool. Double-check the target:

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS
sudo dd if=result/iso/*.iso of=/dev/disk/by-id/usb-YOUR_USB_DEVICE \
  bs=4M status=progress oflag=sync
```

The `dd` destination is destroyed.

You can also use the official graphical NixOS ISO; `disko-install` only requires
a Linux environment with Nix and internet access.

## 4. Install to a machine

> **Destructive operation:** the command below replaces the entire selected disk
> with GPT, a 1 GiB EFI system partition, and Btrfs subvolumes for `/`, `/home`,
> `/nix`, `/var/log`, and `/.snapshots`. It does not support dual boot.

Boot a NixOS installer, connect to the network, then:

```bash
git clone https://github.com/jbattist/dotfiles.git ~/dotfiles
cd ~/dotfiles
git pull --ff-only

lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/
```

Choose a stable **whole-disk** path such as
`/dev/disk/by-id/nvme-Samsung_SSD_...`, not a partition ending in `-part1`.
Store it in a shell variable and verify it twice:

```bash
DISK=/dev/disk/by-id/nvme-YOUR_DISK
readlink -f "$DISK"
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS "$DISK"
```

Choose a profile:

```bash
PROFILE=generic             # or generic-work / generic-laptop
```

### Dry run

This asks disko-install to print what it would do:

```bash
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --dry-run \
  --flake ".#$PROFILE" \
  --disk system "$DISK"
```

Read the output and ensure `system` maps to the intended disk.

### Set the real user's initial password

No credentials are committed. Generate a SHA-512 password hash in the installer
shell; input is hidden and the hash remains only in the shell variable:

```bash
read -rsp 'Initial password for joe: ' PASSWORD; echo
HASH="$(printf '%s' "$PASSWORD" | nix run nixpkgs#mkpasswd -- -m sha-512 -s)"
unset PASSWORD
SYSTEM_CONFIG="$(jq -nc --arg hash "$HASH" \
  '{users:{users:{joe:{hashedPassword:$hash}}}}')"
unset HASH
```

### Install

```bash
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --write-efi-boot-entries \
  --flake ".#$PROFILE" \
  --disk system "$DISK" \
  --system-config "$SYSTEM_CONFIG"
unset SYSTEM_CONFIG
```

This is the upstream `disko-install` interface. `--disk system ...` overrides
the fallback disk in `nix/hardware/generic.nix`; `--system-config` adds only the
password hash to this evaluation. The installer invokes `nixos-install` with no
root password; log in as `joe` after reboot and use `sudo`.

Reboot only after `disko-install succeeded`:

```bash
sudo reboot
```

## 5. After the first boot

Clone this repository to the location expected for future rebuilds:

```bash
git clone https://github.com/jbattist/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo nixos-rebuild switch --flake .#generic   # use the profile installed above
```

Then check:

```bash
systemctl --failed
systemctl --user --failed
resolvectl status
niri validate 2>/dev/null || true
```

The wallpaper directory is intentionally not populated by Nix. Copy or sync the
collection into:

```text
~/.local/share/wallpapers
```

If the display needs fixed scaling or placement, add an output entry to the
selected profile or create a small host override. Keeping outputs empty is the
portable default.

## Known limitations before relying on this as your only system

- The generic initrd covers common NVMe/SATA/USB hardware, not every storage
  controller. Test the VM and installer first; unusual machines need a hardware
  override.
- No disk encryption is configured yet.
- The full desktop closure has not been boot-tested on physical hardware.
- Noctalia/Vicinae/Plasma files managed by home-manager are read-only; use the
  `jb.opts.desktop.manage*` toggles if their GUIs need to own those files.
- The homelab role is off in generic profiles; this avoids requiring Forgejo and
  CIFS credentials on an arbitrary machine.
