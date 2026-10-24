{ lib, ... }:

{
  imports = [
    ./git.nix
    ./shell.nix
    ./editors.nix
    ./terminals.nix
    ./niri.nix
    ./desktop-ui.nix
    ./apps.nix
    ./services.nix
    ./misc.nix
  ];

  # home.username and home.homeDirectory are supplied by the NixOS module system
  # (from `home-manager.users.joe` and `users.users.joe.home`), so they are not
  # repeated here.
  home.stateVersion = lib.mkDefault "25.05";

  programs.home-manager.enable = true;
}
