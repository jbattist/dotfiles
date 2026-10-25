# Migrating these dotfiles to NixOS

Status: the flake evaluates `generic`, `generic-work`, `generic-laptop`, and the
installer ISO configuration. `nix flake check` passes and builds the generated
niri/Umbriel files for all three profiles. A full physical installation and
full GUI closure have not yet been boot-tested. See [INSTALL-NIXOS.md](INSTALL-NIXOS.md).

## Repo strategy: in this repo

The config files (fish functions, nvim Lua, niri KDL, GTK css) are consumed by
Nix at their existing paths, so Arch/stow and NixOS can share one copy during a
gradual migration. Extracting later with `git filter-repo` preserves history.

The cost is flake source size: all tracked files are copied into the Nix store.
The 455 MB `wallpapers/` directory should move to its own repository or storage
location. The configuration creates `~/.local/share/wallpapers` but deliberately
does not manage the collection.

## Layout

    flake.nix, flake.lock    pinned nixpkgs + home-manager + disko
    nix/overlay.nix          gaze (Forgejo release, pinned hash), Cursor stub
    nix/profiles/            generic package roles + home/work/laptop layouts
    nix/hardware/generic.nix portable UEFI + GPT/Btrfs disko layout
    nix/modules/roles.nix    jb.roles.*, jb.opts.*, jb.desktop.*
    nix/modules/system/      NixOS modules
    nix/modules/home/        home-manager modules
    docs/INSTALL-NIXOS.md    evaluation, VM, ISO and install procedure

## Generic builds

- `generic`: old `home` niri/Umbriel layout.
- `generic-work`: old `work` layout and Chrome app rules.
- `generic-laptop`: old `laptop` layout and touchpad policy.

None pins a connector, hostname belonging to an existing machine, disk UUID,
GPU, or machine-specific hardware scan. Displays are autodetected. The
repository's `#install` app supplies the selected disk through one scoped,
impure evaluation; normal flake evaluation remains pure.

## Mapping

| Before | Now |
|---|---|
| `2-install-pkgs.sh` fzf picker | `jb.roles.<manifest> = true` in a profile |
| service manifests + reconciler | Native `services.*.enable` options |
| machine prompt, `machine.env`, template copy, `sed __NIRI_OUTPUT__`, gitignored `output.kdl` | Profile data -> generated niri and Umbriel files |
| `ya pkg install` | Pinned, hash-verified yazi plugin sources |
| latest-release `install_gaze` | Pinned derivation in `nix/overlay.nix` |
| `4-git-config.sh` | `programs.git.settings` |
| resolved/NM/nsswitch/chsh/npm scripting | NixOS options and session variables |
| mocked shell tests | Real flake evaluation and generated-file builds |
| manual partitioning/hardware config | Generic disko GPT/Btrfs layout selected at install time |

## Findings

- The old generated `machine.kdl` can have its output block commented out when
  installation runs outside niri. `config.kdl` also includes a gitignored
  `output.kdl`, so a fresh clone is incomplete. Empty generated output files now
  intentionally mean compositor autodetection.
- `package.toml` names `uhs-robert/sshfs`; Nix must fetch the actual repository,
  `uhs-robert/sshfs.yazi`.
- Almost all former AUR packages now exist in nixpkgs. Cursor remains an off-by-
  default packaging stub; Paneru is macOS-only; removed `thefuck` becomes
  `pay-respects`.
- Snapper system snapshots are not ported: NixOS generations provide system
  rollback. The optional snapshots role uses btrbk for user data.
- Stow backup residue and `update-noctalia-starship.py` are not deployed.

## Decisions and limitations

1. Generic roles are intentionally conservative: desktop/shell/fonts/audio,
   bluetooth, printing, interactive apps and Noctalia greetd are enabled;
   gaming, work apps, containers, snapshots and Mango are off.
2. Mutable Noctalia, GTK, Vicinae and Plasma configs are read-only when managed.
   `jb.opts.desktop.manage*` can hand ownership back to their GUIs.
3. Neovim remains lazy.nvim-based; its read-only config means lazy-lock.json
   cannot persist. Native `pkgs.vimPlugins` is a follow-up.
4. The old hardcoded niri `/dev/dri/card1` renderer was removed; a future host
   can set the typed `jb.desktop.niri.renderDrmDevice` option if needed.
5. The generic initrd targets normal UEFI NVMe/SATA/USB x86_64 hardware. Unusual
   storage, ARM, encryption, dual boot and proprietary GPU setup need modules.
6. No secrets are committed. The installer guide injects the initial password
   hash at install time. Homelab and CIFS support are disabled generically.
7. The timezone default remains `America/New_York`; change it in the profile if
   needed.

## Validation

```bash
nix flake check
nix build .#nixosConfigurations.generic.config.system.build.toplevel
nix run .#generic-vm     # login: joe / test; VM only
```

For installation, follow the four-step process in
[INSTALL-NIXOS.md](INSTALL-NIXOS.md). It uses the repository's installer app,
not the upstream `disko-install` wrapper, so old installer-ISO Nix versions do
not leak into partitioning or system evaluation.
