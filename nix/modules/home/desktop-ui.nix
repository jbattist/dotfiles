# Desktop UI: Noctalia, Umbriel, Vicinae, fuzzel, GTK, Hyprland, Plasma.
#
# Replaces the `noctalia`, `umbriel`, `vicinae`, `fuzzel`, `gtk`, `hyprland` and
# `plasma` stow packages — most of which were installed by 3-install-dots.sh, and
# one of which (`plasma`) needed its own bespoke function because stowing into
# ~/.config directly would have wiped the directory:
#
#   install_plasma() {
#     # Plasma installs into .config directly. We CANNOT backup .config.
#
# That hazard does not exist here. home-manager addresses individual paths, so
# `kdeglobals` and `powerdevilrc` are deployed without anything else in ~/.config
# being at risk, and no special-casing is required.

{
  config,
  lib,
  pkgs,
  jbRoles,
  jbOpts,
  jbDesktop,
  ...
}:

let
  root = ../../..;
  toml = pkgs.formats.toml { };

  u = jbDesktop.umbriel;

  # -------------------------------------------------------------------------
  # umbriel/output.toml — generated, was hand-edited per machine
  # -------------------------------------------------------------------------
  outputToml = toml.generate "umbriel-output.toml" {
    output = lib.mapAttrs (
      _: o:
      lib.filterAttrs (_: v: v != null) {
        enabled = if o.enable then null else false;
        inherit (o) mode scale;
        position = o.position;
        inherit (o)
          hdr
          vrr
          tearing
          workspaces
          ;
      }
    ) u.outputs;
  };

  # -------------------------------------------------------------------------
  # umbriel/machine.toml — generated, was `cp machine.<profile> machine.toml`
  # -------------------------------------------------------------------------
  machineToml = toml.generate "umbriel-machine.toml" (
    {
      layout = lib.filterAttrs (_: v: v != null && v != [ ]) {
        extent_presets = u.layout.extentPresets;
        scrolling = lib.optionalAttrs (u.layout.defaultExtentFraction != null) {
          default_extent_fraction = u.layout.defaultExtentFraction;
        };
        master = lib.optionalAttrs (u.layout.defaultMasterWidthFraction != null) {
          default_width_fraction = u.layout.defaultMasterWidthFraction;
        };
      };
      general.autostart = u.autostart;
    }
    // lib.optionalAttrs (u.windowRules != [ ]) { window_rule = u.windowRules; }
    //
      lib.optionalAttrs
        (u.touchpad.disableWhileTyping != null || u.touchpad.disableOnExternalMouse != null)
        {
          input.touchpad = lib.filterAttrs (_: v: v != null) {
            disable_while_typing = u.touchpad.disableWhileTyping;
            disable_on_external_mouse = u.touchpad.disableOnExternalMouse;
          };
        }
  );
in
{
  config = lib.mkIf jbRoles.desktop-niri (
    lib.mkMerge [
      {
        # -------------------------------------------------------------------------
        # Noctalia
        # -------------------------------------------------------------------------
        # config.toml is tracked; colors.json and plugins/ are gitignored runtime
        # state that Noctalia regenerates on every theme change. Only the tracked
        # file is deployed, which is exactly the split the .gitignore already encoded.
        #
        # config_version = 8 and `[shell.greeter_sync] auto_sync = true` mean the
        # settings GUI writes back to this file. See jb.opts.desktop.manageNoctaliaConfig.
        xdg.configFile = lib.mkIf jbOpts.desktop.manageNoctaliaConfig {
          "noctalia/config.toml".source = root + "/noctalia/.config/noctalia/config.toml";
        };

        # config.toml sets `[wallpaper] directory = "/home/joe/.local/share/wallpapers"`.
        # The 455 MB collection that used to be committed under wallpapers/ is not
        # part of this flake — Noctalia only needs a readable directory, not an
        # immutable store path, and adding it to the flake source would copy it into
        # the store on every rebuild. The directory is created here and populated out
        # of band; see docs/MIGRATION.md §Wallpapers.
        systemd.user.tmpfiles.rules = [ "d ${jbDesktop.wallpaperDir} 0755 - - -" ];

        # -------------------------------------------------------------------------
        # Umbriel
        # -------------------------------------------------------------------------
      }
      {
        xdg.configFile = {
          # Machine-independent, deployed verbatim. config.toml's `[include] files`
          # list is what pulls in the two generated files below.
          "umbriel/config.toml".source = root + "/umbriel/.config/umbriel/config.toml";
          "umbriel/keybinds.toml".source = root + "/umbriel/.config/umbriel/keybinds.toml";
          "umbriel/window_rules.toml".source = root + "/umbriel/.config/umbriel/window_rules.toml";
          "umbriel/input.toml".source = root + "/umbriel/.config/umbriel/input.toml";

          # Generated per host.
          "umbriel/output.toml".source = outputToml;
          "umbriel/machine.toml".source = machineToml;
        };

        # The machine.home / machine.work / machine.laptop variants are no longer
        # deployed. They were never read by umbriel — they were inert files waiting to
        # be copied over machine.toml by hand. Their contents now live in
        # hosts/<name>/machine.nix, and leaving them in ~/.config/umbriel would only
        # invite someone to edit a file that does nothing.

        # -------------------------------------------------------------------------
        # Vicinae
        # -------------------------------------------------------------------------
      }
      {
        xdg.configFile = lib.mkIf jbOpts.desktop.manageVicinaeConfig {
          "vicinae/settings.json".source = root + "/vicinae/.config/vicinae/settings.json";
        };

        # -------------------------------------------------------------------------
        # fuzzel
        # -------------------------------------------------------------------------
        # The tracked fuzzel.ini had no section header at all, relying on fuzzel
        # tolerating top-level keys. fuzzel.ini(5) documents these under [main], so
        # the native settings attrset is both more correct and type-checked.
      }
      {
        programs.fuzzel = {
          enable = true;
          settings = {
            main = {
              dpi-aware = "no";
              font = "JetBrainsMono:size=14";
              include = "~/.config/fuzzel/themes/noctalia";
            };
          };
        };

        # 56 theme files (fourteen catppuccin variants x four flavours, plus the
        # noctalia theme that fuzzel.ini actually includes). Verbatim: they are
        # generated colour data, not hand-maintained config.
        xdg.configFile."fuzzel/themes" = {
          source = root + "/fuzzel/.config/fuzzel/themes";
          recursive = true;
        };

        # -------------------------------------------------------------------------
        # GTK
        # -------------------------------------------------------------------------
        # settings.ini was previously backed up and replaced wholesale by
        # 3-install-dots.sh (which had to `backup_path` both gtk-3.0 and gtk-4.0
        # before stowing, because the two directories differ only in which keys GTK
        # accepts). The values are now typed options, and the gtk-3-only keys
        # (gtk-button-images, gtk-menu-images, gtk-modules, gtk-theme-name,
        # gtk-toolbar-style) are placed only where GTK3 reads them.
      }
      {
        gtk = {
          enable = true;
          theme = {
            name = "adw-gtk3-dark";
            package = pkgs.adw-gtk3;
          };
          iconTheme = {
            name = "Tela-dracula-dark";
            package = pkgs.tela-icon-theme;
          };
          cursorTheme = {
            name = "breeze_cursors";
            size = 24;
            package = pkgs.kdePackages.breeze;
          };
          font = {
            name = "Inter";
            size = 10;
            package = pkgs.inter;
          };

          # Keys shared by both settings.ini files.
          gtk4.theme = config.gtk.theme;

          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = true;
            gtk-cursor-blink = true;
            gtk-cursor-blink-time = 1000;
            gtk-decoration-layout = "icon:minimize,maximize,close";
            gtk-enable-animations = true;
            gtk-primary-button-warps-slider = true;
            gtk-sound-theme-name = "ocean";
            gtk-xft-dpi = 147456;
            # GTK3-only keys from gtk-3.0/settings.ini.
            gtk-button-images = true;
            gtk-menu-images = true;
            gtk-toolbar-style = 3;
            # Provided by kdePackages.kde-cli-tools (window-decorations) and Plasma
            # (colorreload). Absent on a pure-niri host these are silently ignored by
            # GTK, which is the same behaviour as before.
            gtk-modules = "colorreload-gtk-module:window-decorations-gtk-module";
          };

          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = true;
            gtk-cursor-blink = true;
            gtk-cursor-blink-time = 1000;
            gtk-decoration-layout = "icon:minimize,maximize,close";
            gtk-enable-animations = true;
            gtk-primary-button-warps-slider = true;
            gtk-sound-theme-name = "ocean";
            gtk-xft-dpi = 147456;
          };

          # gtk-3.0/bookmarks. home-manager has a typed option for this, which is
          # why it is not in the verbatim css block below.
          gtk3.bookmarks = [
            "file:///home/joe/Documents"
            "file:///home/joe/Music"
            "file:///home/joe/Pictures"
            "file:///home/joe/Videos"
            "file:///home/joe/Downloads"
          ];
        };

        # Noctalia's dynamic GTK theming: gtk.css is a two-line @import of radii.css
        # and noctalia.css, and Noctalia rewrites those on every colour change. That
        # is the clearest case in this file of an application owning files that are
        # also tracked in git, hence the toggle.
        #
        # The tracked settings.ini.bak-20260607-112713 files are NOT deployed. They
        # are residue from stow's `mv $target $target.backup.<timestamp>` conflict
        # handling — the exact mechanism Nix replaces — and deploying a `.bak` into
        # ~/.config would be actively wrong.
      }
      {
        xdg.configFile = lib.mkIf jbOpts.desktop.manageGtkCss (
          let
            overlay = ver: file: {
              name = "gtk-${ver}/${file}";
              value.source = root + "/gtk/.config/gtk-${ver}/${file}";
            };
            files = [
              "gtk.css"
              "radii.css"
              "noctalia.css"
              "colors.css"
              "dank-colors.css"
              "window_decorations.css"
            ];
          in
          builtins.listToAttrs (
            lib.concatLists (
              map (ver: map (overlay ver) files) [
                "3.0"
                "4.0"
              ]
            )
            # gtk-3.0 also ships the window-button SVG assets that
            # window_decorations.css references.
            ++ [
              {
                name = "gtk-3.0/assets";
                value = {
                  source = root + "/gtk/.config/gtk-3.0/assets";
                  recursive = true;
                };
              }
            ]
          )
        );

        # -------------------------------------------------------------------------
        # Hyprland
        # -------------------------------------------------------------------------
        # Secondary compositor. hyprland.conf's first live line is
        #   source = /home/joe/.config/hypr/noctalia/noctalia-colors.conf
        # a path that does not exist in the repository: Noctalia generates it at
        # runtime. So the hyprland tree is deployed verbatim and that file is left
        # for Noctalia to own. The tracked
        # hyprland.conf.pre-lua-20260517-093505.bak is not deployed, for the same
        # reason as the settings.ini.bak files above.
      }
      {
        xdg.configFile."hypr" = {
          source = root + "/hyprland/.config/hypr";
          recursive = true;
        };

        # -------------------------------------------------------------------------
        # Plasma
        # -------------------------------------------------------------------------
      }
      {
        xdg.configFile = lib.mkIf jbOpts.desktop.managePlasmaConfig {
          "kdeglobals".source = root + "/plasma/.config/kdeglobals";
          "powerdevilrc".source = root + "/plasma/.config/powerdevilrc";
        };
      }
    ]
  );
}
