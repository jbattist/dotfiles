# System-level packages: fonts, filesystem helpers, containers.
#
# User-facing CLI/GUI applications live in the home-manager modules instead, so
# that they land in the user profile rather than the system closure. What is
# here needs privileges, kernel support, or is consumed by every user.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.jb.roles;
in
{
  # ---------------------------------------------------------------------------
  # Fonts — was manifests/packages/fonts
  # ---------------------------------------------------------------------------
  #   ttf-jetbrains-mono       -> jetbrains-mono
  #   ttf-jetbrains-mono-nerd  -> nerd-fonts.jetbrains-mono
  #   noto-fonts-emoji         -> noto-fonts-color-emoji   (renamed upstream)
  #   inter-font               -> inter
  #
  # Arch splits "font package installed" from "fontconfig knows about it"; on
  # NixOS `fonts.fontconfig.enable` regenerates the cache at build time, so the
  # `fc-cache` step the old setup relied on happening implicitly is explicit.
  fonts = {
    fontconfig.enable = true;
    packages =
      with pkgs;
      lib.optionals cfg.fonts [
        jetbrains-mono
        nerd-fonts.jetbrains-mono
        noto-fonts-color-emoji
        inter

        # Themes referenced by gtk/.config/gtk-3.0/settings.ini. On Arch these
        # arrived as dependencies of the Noctalia/AUR stack; here they are named
        # explicitly because Nix has no implicit dependency resolution into
        # $XDG_DATA_DIRS.
        adw-gtk3 # gtk-theme-name=adw-gtk3-dark
        tela-icon-theme # gtk-icon-theme-name=Tela-dracula-dark
        gnome-themes-extra # Adwaita engine, needed by adw-gtk3
        kdePackages.breeze # gtk-cursor-theme-name=breeze_cursors
        sound-theme-freedesktop # gtk-sound-theme-name (see docs: "ocean" is Plasma-only)
      ];
  };

  # ---------------------------------------------------------------------------
  # Filesystem tooling — was in manifests/packages/shell
  # ---------------------------------------------------------------------------
  # sshfs, nfs-utils and cifs-utils are not just binaries on NixOS: FUSE needs a
  # setuid helper and the kernel modules must be present. Installing the packages
  # alone (what the Arch manifest did) would leave `sshfs` failing with
  # "fusermount: not found" or "transport endpoint is not connected".
  boot.supportedFilesystems =
    lib.optionals cfg.shell [ "fuse" ]
    ++ lib.optionals (cfg.shell && config.jb.homelab.enable) [
      "cifs"
      "nfs"
    ];

  environment.systemPackages =
    with pkgs;
    lib.optionals cfg.shell [
      sshfs
      nfs-utils
      cifs-utils
      # `bind-tools` in the Arch manifest; split into dnsutils on nixpkgs.
      dnsutils
      btrfs-progs
    ];

  # The yazi sshfs plugin (yazi/.config/yazi/package.toml pins uhs-robert/sshfs)
  # shells out to sshfs, so the two must be enabled together. That coupling was
  # implicit before: the plugin was installed by `ya pkg install` and sshfs came
  # from the shell manifest, with nothing checking that both happened.
  assertions = lib.optional (cfg.shell) {
    assertion = pkgs.stdenv.hostPlatform.isLinux;
    message = "jb.roles.shell expects a Linux host.";
  };

  # ---------------------------------------------------------------------------
  # Containers — no manifest existed for this
  # ---------------------------------------------------------------------------
  # hermes runs docker today (open-webui, arcane-agent, hindsight). The old
  # setup had it installed out of band, which is exactly the kind of undeclared
  # host state the manifests were supposed to prevent.
  virtualisation.docker = {
    enable = cfg.container;
    # Rootless is not used: the existing containers bind host paths and the
    # compose files assume the docker group.
    autoPrune = {
      enable = cfg.container;
      dates = "weekly";
    };
  };

  users.users.joe.extraGroups = lib.optionals cfg.container [ "docker" ];

  # ---------------------------------------------------------------------------
  # Unfree
  # ---------------------------------------------------------------------------
  # google-chrome, vscode, cursor and slack are all unfree. Declaring the
  # predicate here keeps `nix build` from failing with EULA errors on hosts that
  # enable the interactive role.
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "vscode"
      "cursor"
      "slack"
      "obsidian"
      "claude-code"
      "kiro"
      "wordcraft"
      "gridcraft"
      "deckcraft"
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
      "gaze"
    ];
}
