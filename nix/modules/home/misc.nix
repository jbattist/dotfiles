# Tracked-but-uninstalled configurations.
#
# The old README was explicit that some stow packages were never installed by any
# script:
#
#   Other tracked configs, such as `mango`, `paneru`, `swayidle`, and `vicinae`,
#   are **not** installed by these scripts; stow them deliberately if wanted
#   (for example `stow -d ~/dotfiles -t ~ paneru`). Review conflicts before
#   doing so.
#
# Each of those four is handled differently here, and the reasoning matters
# because "stow it manually and review conflicts" is exactly the kind of
# undocumented host state a declarative config is supposed to eliminate:
#
#   vicinae   — actually *was* in manifests/packages/desktop-niri, so it is
#               installed. Deployed in nix/modules/home/desktop-ui.nix.
#   swayidle  — ported behind jb.opts.desktop.swayidle (default off), see
#               nix/modules/home/services.nix.
#   mango     — ported behind jb.roles.mango (default off), below.
#   paneru    — NOT ported. paneru/.config/paneru/paneru.toml opens with
#               "Paneru is a macOS tiling WM", and the file is a translation of
#               the niri keybinds for the macOS machine. It belongs with
#               `brewfile`, not with a NixOS flake, and there is no Nix package
#               for it on Linux.
#
# The five mango/.config/mango/*.bak files and theme.conf.bak are not deployed.
# Like the gtk settings.ini.bak-* files, they are residue of stow's
# backup-on-conflict behaviour and have no meaning once Nix owns the paths.

{
  config,
  lib,
  pkgs,
  jbRoles,
  ...
}:

let
  root = ../../..;
in
{
  config = lib.mkIf jbRoles.mango {
    home.packages = with pkgs; [ mango ];

    xdg.configFile = {
      "mango/config.conf".source = root + "/mango/.config/mango/config.conf";
      "mango/noctalia.conf".source = root + "/mango/.config/mango/noctalia.conf";
    };
  };
}
