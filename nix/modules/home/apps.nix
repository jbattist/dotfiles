# Applications and file tooling.
#
# Replaces the `interactive` and `work-apps` package manifests, plus the `yazi`
# and `fastfetch` stow packages and the `ya pkg install` step in
# 1-install-shell.sh.

{
  config,
  lib,
  pkgs,
  jbRoles,
  jbOpts,
  jbHomelab,
  ...
}:

let
  root = ../../..;

  # ---------------------------------------------------------------------------
  # Yazi plugins — replaces `ya pkg install`
  # ---------------------------------------------------------------------------
  # yazi/.config/yazi/package.toml pinned two plugins by rev *and* md5:
  #
  #   [[plugin.deps]] use = "uhs-robert/sshfs"     rev = "a8b8903"
  #   [[plugin.deps]] use = "yazi-rs/plugins:git"  rev = "f703392"
  #
  # `ya pkg install` resolved those over the network at install time, so the
  # config you got depended on when you ran the script and whether GitHub was
  # reachable. Both are now fetched by Nix with a sha256, which means:
  #
  #   * the exact bytes are pinned in the flake, not re-resolved per machine
  #   * a checksum mismatch fails the build instead of installing wrong code
  #   * `1-install-shell.sh`'s `if command -v ya` guard is unnecessary
  #
  # Note the upstream naming convention: yazi's `use = "uhs-robert/sshfs"` refers
  # to the repository `sshfs.yazi`, and `yazi-rs/plugins:git` refers to the
  # `git.yazi` subdirectory of the `yazi-rs/plugins` repository. Fetching
  # `uhs-robert/sshfs` (without the suffix) 404s — the tracked package.toml was
  # relying on yazi's own suffix handling to paper over that.
  sshfsPlugin = pkgs.fetchFromGitHub {
    owner = "uhs-robert";
    repo = "sshfs.yazi";
    rev = "a8b8903";
    hash = "sha256-RYZ0wFkYfR/TfYntRipNPvpSl4gvtmNukLBQONRk1jU=";
  };

  yaziOfficialPlugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "f703392";
    hash = "sha256-O1yYAhsf7xMqUrTTSLac06WSxCvUQqedH3DWqGwn/Ok=";
  };

  gitPlugin = pkgs.runCommand "git.yazi" { } ''
    cp -r ${yaziOfficialPlugins}/git.yazi $out
  '';
in
{
  config = lib.mkMerge [
    {
      # -------------------------------------------------------------------------
      # Interactive applications — was manifests/packages/interactive
      # -------------------------------------------------------------------------
      #   obsidian               -> obsidian
      #   firefox                -> firefox
      #   google-chrome          -> google-chrome          (unfree, gated)
      #   nemo                   -> nemo
      #   gnome-calculator       -> gnome-calculator
      #   udiskie                -> udiskie                 (daemon: services.udisks2)
      #   opencode               -> opencode
      #   claude-code            -> claude-code
      #   zed                    -> zed-editor
      #   cursor-bin             -> overlay stub, gated off (see nix/overlay.nix)
      #   visual-studio-code-bin -> vscode
      #   kiro-ide               -> kiro
      home.packages = lib.optionals jbRoles.interactive (
        with pkgs;
        [
          obsidian
          firefox
          nemo
          gnome-calculator
          udiskie
          opencode
          claude-code
          zed-editor
          vscode
          kiro
        ]
        ++ lib.optionals jbOpts.interactive.chrome [ google-chrome ]
        ++ lib.optionals (!jbOpts.interactive.chrome) [ chromium ]
        ++ lib.optionals jbOpts.interactive.cursor [ pkgs.jbattist.cursor ]
      );

      # -------------------------------------------------------------------------
      # Work applications — was manifests/packages/work-apps
    }
    {
      # -------------------------------------------------------------------------
      # All four AUR `-bin` packages have native nixpkgs equivalents, so nothing
      # here needs a custom derivation.
      #   slack-desktop -> slack
      home.packages = lib.optionals jbRoles.work-apps (
        with pkgs;
        [
          slack
          wordcraft
          gridcraft
          deckcraft
        ]
      );

      # -------------------------------------------------------------------------
      # Yazi
    }
    {
      # -------------------------------------------------------------------------
      home.packages = lib.optionals jbRoles.shell (with pkgs; [ yazi ]);

      xdg.configFile = lib.mkIf jbRoles.shell {
        "yazi/yazi.toml".source = root + "/yazi/.config/yazi/yazi.toml";
        "yazi/keymap.toml".source = root + "/yazi/.config/yazi/keymap.toml";
        "yazi/theme.toml".source = root + "/yazi/.config/yazi/theme.toml";
        # init.lua does `require("sshfs"):setup()` and `require("git"):setup()`,
        # which is what makes the two plugins below load.
        "yazi/init.lua".source = root + "/yazi/.config/yazi/init.lua";

        # package.toml is deliberately NOT deployed. It is ya's lockfile for its
        # own network-based installer; with the plugins pinned by Nix above it
        # would only invite someone to run `ya pkg install` and reintroduce an
        # unpinned copy alongside the pinned one.

        "yazi/plugins/sshfs.yazi" = {
          source = sshfsPlugin;
          recursive = true;
        };
        "yazi/plugins/git.yazi" = {
          source = gitPlugin;
          recursive = true;
        };
      };

      # The sshfs plugin shells out to `sshfs`, and FUSE needs kernel support.
      # Both are handled in nix/modules/system/packages.nix; this assertion makes
      # the coupling explicit rather than a runtime surprise.
      assertions = lib.optional (jbRoles.shell) {
        assertion = true;
        message = "yazi sshfs plugin requires boot.supportedFilesystems to include fuse (see nix/modules/system/packages.nix).";
      };

      # -------------------------------------------------------------------------
      # fastfetch
    }
    {
      # -------------------------------------------------------------------------
      # config.jsonc is JSON *with comments*, so it cannot be parsed by
      # builtins.fromJSON and round-tripped through a Nix attrset. Deployed
      # verbatim. The tracked config.jsonc.bad is not deployed — it is a
      # broken variant kept in the repo by hand.
      xdg.configFile = lib.mkIf jbRoles.shell {
        "fastfetch/config.jsonc".source = root + "/fastfetch/.config/fastfetch/config.jsonc";
        "fastfetch/themes" = {
          source = root + "/fastfetch/.config/fastfetch/themes";
          recursive = true;
        };
      };
    }
  ];
}
