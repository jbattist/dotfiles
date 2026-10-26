# NixOS configuration

A NixOS + home-manager flake that reproduces this repo's Arch dotfiles
declaratively. It lives alongside the original Arch scripts; both read the same
config files (fish functions, Umbriel TOML, GTK css, etc.).

- Current release: **`nix-v0.1.0`**
- Desktop: **Umbriel** compositor + **Noctalia v5** shell, Noctalia greeter
- Target: UEFI x86_64, single disk, verified on a Proxmox VM
- Kernel: `linuxPackages_latest` (mainline, like Arch); installer ISO stays on LTS

Related docs: [`docs/INSTALL-NIXOS.md`](docs/INSTALL-NIXOS.md) (install detail),
[`docs/MIGRATION.md`](docs/MIGRATION.md) (old-to-new mapping and decisions).

---

## 1. How it was derived

The Arch setup had four imperative scripts plus data files. Each piece was
translated to a declarative Nix equivalent:

| Arch (before) | NixOS (now) |
|---|---|
| `manifests/packages/<group>` + `2-install-pkgs.sh` fzf picker | `jb.roles.<group> = true;` in a profile |
| `manifests/services/*.enable/.disable` + reconciler script | Native `services.*.enable` options |
| `1-install-shell.sh` (yay, resolved, nsswitch, chsh, npm prefix) | `nix/modules/system/base.nix`, `packages.nix` |
| GNU Stow packages (`fish/`, `ghostty/`, `umbriel/`, ...) | home-manager `xdg.configFile` / `programs.*` in `nix/modules/home/` |
| `3-install-dots.sh` machine prompt, `machine.env`, `sed __NIRI_OUTPUT__` | Profiles in `nix/profiles/` generate `umbriel/machine.toml` and `output.toml` |
| `4-git-config.sh` | `programs.git.settings` in `nix/modules/home/git.nix` |
| `ya pkg install` (unpinned yazi plugins) | `fetchFromGitHub` with pinned hashes |
| `install_gaze` (curl latest release) | Pinned derivation in `nix/overlay.nix` |
| Manual partitioning | `nix/hardware/generic.nix` (disko layout) + the install app |

Design rules followed throughout:

- **Prefer native options.** Use a home-manager `programs.<x>` module or NixOS
  `services.<x>` option when one exists; otherwise deploy the existing tracked
  file verbatim with `xdg.configFile."<path>".source = root + "/<pkg>/.config/...";`.
- **One source of truth.** Config files stay in their original stow-shaped
  directories (`fish/.config/fish/...`) so Arch and NixOS share them.
- **Nothing machine-specific is committed.** No hostname, disk UUID or output
  connector is baked in; displays autodetect and the disk is chosen at install.
- **No secrets in git.** The user password is set interactively at install.

Notable deviations from the Arch setup:

- `thefuck` was removed from nixpkgs, replaced by `pay-respects`.
- Snapper is not ported; NixOS generations provide system rollback.
- Noctalia is **v5** (`pkgs.noctalia`, native C++). The old v4
  `noctalia-shell` (Quickshell/Qt) does not build against the pinned Qt 6.12.
- Niri and Hyprland are not installed; their modules exist but are inactive.
- `paneru` is macOS-only and stays in `brewfile`.

---

## 2. Layout

```
flake.nix                    Inputs (pinned), the profiles, install app, checks
flake.lock                   Exact versions of every input
install-nixos                Curl-able bootstrap (gets a current Nix, runs #install)
nix/
  install.sh                 The installer app: validate disk, partition, install
  overlay.nix                Packages not in nixpkgs (gaze, cursor stub)
  hardware/generic.nix       Portable hardware + disko disk layout (GPT/EFI/Btrfs)
  profiles/
    default.nix              Base role selection shared by every profile
    home.nix work.nix laptop.nix   Umbriel layout per machine type
    full.nix                 Adds the large app suite (layered on home.nix)
  modules/
    roles.nix                All jb.* options (roles, opts, desktop, disk)
    system/                  NixOS modules (base, packages, desktop, services)
    home/                    home-manager modules (shell, editors, terminals,
                             desktop-ui, apps, git, services, misc, niri)
```

### Profiles (flake outputs)

| Output | Contents |
|---|---|
| `generic` | Core desktop, default/home layout (~8 GiB closure) |
| `generic-work` | Core desktop, work layout and Chrome app rules |
| `generic-laptop` | Core desktop, laptop widths and touchpad policy |
| `generic-full` | `generic` + Chrome, Obsidian, VS Code, Zed, Kiro, Claude Code, OpenCode, Slack, Craft apps |

### How options flow

1. `nix/modules/roles.nix` declares every `jb.*` option.
2. `nix/profiles/default.nix` sets the shared `jb.roles`; a layout profile adds
   `jb.desktop.*` (Umbriel extents, window rules, autostart).
3. NixOS modules read `config.jb.*` directly.
4. home-manager modules can't see NixOS `config`, so
   `nix/modules/system/home-bridge.nix` passes `jbRoles`, `jbOpts`, `jbDesktop`
   and `jbHomelab` in as module arguments.

---

## 3. Installing

### Fresh install (destroys the target disk)

1. Boot the **minimal** NixOS ISO in **UEFI** mode. On Proxmox: BIOS = OVMF,
   Display = VirtIO-GPU, 64 GB+ disk.
2. Run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/jbattist/dotfiles/main/install-nixos | sh
   ```
3. Choose the whole disk (e.g. `/dev/sda`), press Enter for `generic`, enter a
   hostname (e.g. `nix-test`), type the exact `ERASE /dev/...` confirmation,
   then set the `joe` password.
4. On `INSTALLATION COMPLETE`, remove the ISO and `reboot`.

Dry run (no disk changes): append `-s -- --dry-run` style arguments, i.e.
`curl ... | sh -s -- --dry-run /dev/sda generic`.

Pin to a release instead of `main`:
```bash
nix --extra-experimental-features 'nix-command flakes' \
  run github:jbattist/dotfiles/nix-v0.1.0#install
```

The installer logs to `/tmp/dotfiles-nixos-install.log` and prints the last 100
lines on failure.

### Updating an installed system

```bash
sudo nixos-rebuild switch --refresh --flake github:jbattist/dotfiles#generic
```

Use the profile you installed. From a local checkout: `--flake .#generic`.
Roll back with `sudo nixos-rebuild switch --rollback`, or pick an older
generation from the boot menu.

### Hostname

The config does **not** set a hostname (`networking.hostName = ""` in
`flake.nix`), so `/etc/hostname` is a normal file. The installer writes it; to
change it later:

```bash
sudo hostnamectl set-hostname nix-test
sudo nmcli con up "Wired connection 1"   # re-announce via DHCP so DNS updates
```

NetworkManager sends the hostname in DHCP option 12; home DNS (Technitium)
registers `<hostname>.home` from it. Never derive the hostname from the profile
name: every install of a profile would announce the same name and collide.

### Remote access

SSH is on with password login for `joe` (root is denied). `ssh joe@<ip>`.

---

## 4. Making changes (maintainer guide)

### Workflow

1. Edit files in this repo.
2. Validate (all must pass, see "Verification" below).
3. Commit and push to `main`.
4. On the machine: `sudo nixos-rebuild switch --refresh --flake github:jbattist/dotfiles#<profile>`.

Flakes only see **git-tracked** files. New files must be `git add`ed before
`nix` commands will find them.

### Add a package

Find the attribute name first:
```bash
nix search nixpkgs <name>
# or confirm an exact attribute:
nix eval --raw .#nixosConfigurations.generic.pkgs.<name>.version
```

Then add it in the module matching its purpose:

| Kind of package | File | Where |
|---|---|---|
| CLI tool for the user | `nix/modules/home/shell.nix` | `home.packages` |
| GUI app (optional suite) | `nix/modules/home/apps.nix` | `interactive` / `work-apps` lists |
| Desktop component | `nix/modules/system/desktop.nix` | `desktopPackages` |
| Needs root/kernel/system service | `nix/modules/system/packages.nix` | `environment.systemPackages` |
| Font | `nix/modules/system/packages.nix` | `fonts.packages` |

Unfree packages (Chrome, VS Code, Slack, ...) must also be added to
`nixpkgs.config.allowUnfreePredicate` in `nix/modules/system/packages.nix`, or
the build fails with an EULA error.

If a package is **not in nixpkgs**, add a derivation to `nix/overlay.nix` and
reference it as `pkgs.jbattist.<name>`. Pin with a hash: set
`hash = lib.fakeHash;`, build, and copy the real hash from the error.

### Change a dotfile

Edit the tracked file in its original location (e.g.
`fish/.config/fish/functions/foo.fish`, `umbriel/.config/umbriel/keybinds.toml`).
It is deployed as-is. New files in already-enumerated directories (fish
functions/completions, micro colorschemes, fuzzel themes) are picked up
automatically; others need an `xdg.configFile` entry.

Read-only caveat: deployed files are symlinks into the read-only Nix store.
Apps whose GUIs write their own config (Noctalia, Vicinae, Plasma, GTK css) are
gated by `jb.opts.desktop.manage*` in `roles.nix`; set one to `false` to let the
app own that file.

### Change a service

Use the native NixOS option in `nix/modules/system/services.nix` (system) or
`nix/modules/home/services.nix` (user `systemd.user.services`). Do not write
imperative `systemctl enable` steps; there is no reconciler anymore.

### Toggle a whole feature group

Edit `jb.roles` in `nix/profiles/default.nix` (all profiles) or in one profile.
Available roles: `shell fonts audio bluetooth printing desktop-niri
noctalia-greeter interactive work-apps gaming snapshots container mango`.
(`desktop-niri` is a historical name; it now means the Umbriel + Noctalia stack.)

### Add a new role

1. Declare it in `nix/modules/roles.nix` under `options.jb.roles`.
2. Implement it with `lib.mkIf config.jb.roles.<name>` (NixOS) or
   `lib.mkIf jbRoles.<name>` (home-manager).
3. Enable it in a profile.

### Change per-machine desktop layout

Edit `nix/profiles/{home,work,laptop}.nix` (`jb.desktop.umbriel.*`): extent
presets, default widths, window rules, autostart, touchpad. These generate
`~/.config/umbriel/machine.toml` and `output.toml`.

### Add a profile

Add an entry to `profiles` in `flake.nix`, a layout file in `nix/profiles/`,
and the profile name to the validation lists in `nix/install.sh` and
`install-nixos`.

### Update package versions

```bash
nix flake update nixpkgs        # or home-manager / disko
```

This moves every package. **Always do a full system build afterwards** (see
below); version bumps have broken builds before (the Noctalia v4/Qt 6.12
failure). Commit `flake.lock` with the change.

### Kernel

`boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;` in
`nix/modules/system/base.nix`. If a new kernel regresses, pin LTS for a host or
profile with `boot.kernelPackages = pkgs.linuxPackages;`. Out-of-tree modules
(ZFS, NVIDIA) often lag `_latest`; the installer ISO forces LTS for exactly that
reason (it bundles ZFS). Adding ZFS/NVIDIA to installed systems means revisiting
this.

### Verification (required before pushing)

```bash
nix flake check                 # evaluates all profiles, builds generated configs,
                                # shellchecks the installer
nix build .#nixosConfigurations.generic.config.system.build.toplevel   # full build
```

`nix flake check` only evaluates; it does **not** compile packages. A change
that evaluates can still fail to build. Run the full `nix build` for any
package, input or desktop change. Check closure size for small disks:
```bash
nix path-info -Sh ./result
```

If the build machine is not NixOS, run these inside the `nixos/nix` Docker
image with the repo mounted, or `nix develop` for the tooling.

---

## 5. Pitfalls already hit (read before debugging)

| Symptom | Cause | Fix in tree |
|---|---|---|
| Boot stops at `initrd.target`, emergency mode | initrd lacked the disk driver (virtio on Proxmox) | `boot.initrd.availableKernelModules` in `hardware/generic.nix` |
| Login screen bounces back as if bad password | `start-umbriel` runs `umbriel.service`, which wasn't registered | `systemd.packages = [ pkgs.umbriel ]` in `desktop.nix` |
| Greeter shows no session | Session file not in system profile | `environment.pathsToLink = [ "/share/wayland-sessions" ]` |
| Black screen, no bar | Shell not running / wrong Noctalia version | Use `pkgs.noctalia` (v5), autostarted by Umbriel |
| Every install named `generic`, DNS collisions | Hostname was derived from the profile name | `networking.hostName = ""`; installer prompts for it |
| Installer out of disk space | Built closure in live ISO store | `nixos-install --flake` builds straight into `/mnt` |
| `sudo must be owned by uid 0` | Store copy of sudo shadowed the setuid wrapper | Installer uses `/run/wrappers/bin/sudo` |
| `unknown setting no-write-lock-file` | ISO's old Nix vs `disko-install` | Bootstrap fetches `nixVersions.latest`; `disko-install` not used |

Debugging after login:
```bash
journalctl --user -b --no-pager | tail -50     # Umbriel, Noctalia, user apps
journalctl -b -p err --no-pager | tail -50     # system services
systemctl --failed; systemctl --user --failed
```

---

## 6. Known gaps (as of nix-v0.1.0)

- Umbriel only; Niri and Hyprland modules exist but are disabled.
- No disk encryption, no dual boot, UEFI x86_64 only.
- Noctalia plugins (wallhaven, arch-updater) not installed.
- `generic-full` needs ~100 GB+.
- Neovim still uses lazy.nvim at runtime (plugins not pinned in Nix).
- `wallpapers/` (455 MB) is not managed; populate `~/.local/share/wallpapers` manually.
