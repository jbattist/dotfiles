# Central option namespace for this configuration.
#
# Two things live here, and both exist to replace imperative machinery from the
# old dotfiles repo:
#
#   jb.roles.*   — one boolean per file that used to be in manifests/packages/.
#                  The old `2-install-pkgs.sh` presented those files in an fzf
#                  multi-select and installed whatever was ticked. NixOS has no
#                  install-time selection: a host *declares* what it is. The
#                  group names are kept identical so the manifests map 1:1.
#
#   jb.desktop   — the machine-specific values that used to be produced at
#                  install time by `3-install-dots.sh`: the `machine.env`
#                  profile choice, the `machine.kdl.<profile>` template, the
#                  `sed __NIRI_OUTPUT__` substitution, the live
#                  `niri msg --json outputs` probe, and the gitignored
#                  `output.kdl`. Profiles (nix/profiles/) set these as data, so a
#                  fresh clone is complete and nothing needs re-running in a
#                  session. Outputs left empty mean "let niri autodetect", which
#                  is what makes a profile usable on any machine.

{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;

  role = description: mkEnableOption description;
in
{
  options.jb = {
    # -------------------------------------------------------------------------
    # Disk (used by nix/hardware/generic.nix)
    # -------------------------------------------------------------------------
    disk.device = mkOption {
      type = types.str;
      default = "/dev/nvme0n1";
      example = "/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T123456";
      description = "Whole disk the generic layout partitions and formats. DESTROYED by disko.";
    };

    # -------------------------------------------------------------------------
    # Homelab access
    # -------------------------------------------------------------------------
    homelab.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this host can reach `*.home` (Forgejo, TrueNAS). Gates the
        `gaze` release binary and the TrueNAS CIFS mount so that builds on
        untrusted networks do not stall on unreachable hosts.
      '';
    };

    # -------------------------------------------------------------------------
    # Roles — 1:1 with the old manifests/packages/* files
    # -------------------------------------------------------------------------
    roles = {
      # manifests/packages/bootstrap — baseline for every managed host.
      # Not a toggle: always on, because "a host without sshd" is not a
      # configuration anyone wants to select by accident.
      bootstrap = mkOption {
        type = types.bool;
        default = true;
        readOnly = true;
        description = "Baseline packages and services for every managed host (was manifests/packages/bootstrap).";
      };

      shell = role "Shell, terminal, editor and CLI tooling (was manifests/packages/shell).";
      fonts = role "Fonts (was manifests/packages/fonts).";
      audio = role "PipeWire audio stack (was the pipewire entries in desktop-niri).";
      bluetooth = role "BlueZ and bluetooth.service (was manifests/packages/bluetooth).";
      printing = role "CUPS and cups.service (was manifests/packages/printing).";
      desktop-niri = role "niri + Noctalia + Umbriel + Vicinae desktop stack (was manifests/packages/desktop-niri).";
      noctalia-greeter = role "greetd display manager (was manifests/packages/noctalia-greeter).";
      interactive = role "GUI applications (was manifests/packages/interactive).";
      work-apps = role "Work applications (was manifests/packages/work-apps).";
      gaming = role "Steam and Proton (was manifests/packages/gaming).";

      # manifests/packages/snapshots installed snapper + its two timers.
      # On NixOS the *system* half of that job is done by the Nix store and
      # boot entries, so this role covers only user-data snapshots. See the
      # long comment in nix/modules/system/services.nix.
      snapshots = role "btrfs snapshots of user data (was manifests/packages/snapshots).";

      container = role "Docker daemon (hermes runs containers; there was no manifest for this).";

      # mango was tracked (mango/.config/mango/) but installed by none of the
      # four scripts. Kept as an opt-in role so the config is not orphaned by the
      # migration. The tracked .bak variants (five of them) are not deployed.
      mango = role "Mango compositor (tracked but never installed by the old scripts).";
    };

    # -------------------------------------------------------------------------
    # Package-level opt-outs
    # -------------------------------------------------------------------------
    # Kept out of `roles.*` so that every role stays a plain bool and the group
    # names continue to map 1:1 onto the old manifests/packages/ files.
    opts = {
      interactive = {
        cursor = mkOption {
          type = types.bool;
          default = false;
          description = "Install Cursor. Off by default: proprietary, not in nixpkgs, and unpackageable without a hand-maintained URL+hash per release. See nix/overlay.nix.";
        };
        chrome = mkOption {
          type = types.bool;
          default = true;
          description = "Install google-chrome (unfree). Set false to fall back to chromium.";
        };
      };

      # Ownership toggles for configs that an application also writes to.
      #
      # A home-managed file is a symlink into the read-only Nix store. For pure
      # config that is the point. But Noctalia, Vicinae and Plasma all have GUIs
      # that persist settings back into their own config files, and a read-only
      # symlink makes that write fail.
      #
      # The repo already draws this line for Noctalia: colors.json and plugins/
      # are gitignored runtime state while config.toml is tracked. These options
      # make the line explicit and per-host instead of implicit. Leave them true
      # and edit config in Nix; set one false on a host where you drive the app's
      # GUI and want it to own that file.
      desktop = {
        manageNoctaliaConfig = mkOption {
          type = types.bool;
          default = true;
          description = "Deploy noctalia/config.toml read-only. Set false to let the Noctalia settings GUI own it.";
        };
        manageGtkCss = mkOption {
          type = types.bool;
          default = true;
          description = "Deploy the Noctalia-generated GTK css overlays read-only. Set false to let Noctalia rewrite them on theme changes.";
        };
        manageVicinaeConfig = mkOption {
          type = types.bool;
          default = true;
          description = "Deploy vicinae/settings.json read-only.";
        };
        managePlasmaConfig = mkOption {
          type = types.bool;
          default = true;
          description = "Deploy kdeglobals/powerdevilrc read-only. Set false to let Plasma's System Settings own them.";
        };
        swayidle = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the ported swayidle idle/lock service. Off by default because the old repo tracked it without installing it; see nix/modules/home/services.nix.";
        };
      };
    };

    # -------------------------------------------------------------------------
    # Desktop
    # -------------------------------------------------------------------------
    desktop = {
      wallpaperDir = mkOption {
        type = types.str;
        default = "/home/joe/.local/share/wallpapers";
        description = ''
          Directory Noctalia's wallpaper picker browses. The 455 MB collection
          that used to be committed under `wallpapers/` is deliberately *not*
          part of this flake: Noctalia only needs a readable path, not a store
          path, and pulling 455 MB into the flake source would copy it into the
          Nix store on every rebuild. Populate it out of band (see
          docs/MIGRATION.md §Wallpapers).
        '';
      };

      niri = {
        # Replaces the gitignored niri/.config/niri/output.kdl. Being in git is
        # the point: `include "./output.kdl"` in a fresh clone used to reference
        # a file that did not exist.
        outputs = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                };
                mode = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  example = "3840x1080@60.00";
                };
                scale = mkOption {
                  type = types.nullOr types.number;
                  default = null;
                };
                transform = mkOption {
                  type = types.nullOr (
                    types.enum [
                      "normal"
                      "90"
                      "180"
                      "270"
                      "flipped"
                      "flipped-90"
                      "flipped-180"
                      "flipped-270"
                    ]
                  );
                  default = null;
                };
                position = mkOption {
                  type = types.nullOr (
                    types.submodule {
                      options = {
                        x = mkOption {
                          type = types.int;
                          default = 0;
                        };
                        y = mkOption {
                          type = types.int;
                          default = 0;
                        };
                      };
                    }
                  );
                  default = null;
                };
              };
            }
          );
          default = { };
          description = "niri `output` blocks, keyed by connector name (DP-1, HDMI-A-1, eDP-1, …).";
        };

        terminalColumnWidth = mkOption {
          type = types.nullOr types.number;
          default = null;
          description = "Default column width for terminals (ghostty/wezterm/kitty). Was the per-profile terminal window-rule in machine.kdl.<profile>.";
        };

        layout = {
          presetColumnWidths = mkOption {
            type = types.listOf types.number;
            default = [ ];
            description = "Proportions cycled by `switch-preset-column-width`. Was `layout.preset-column-widths` in machine.kdl.<profile>.";
          };
          defaultColumnWidth = mkOption {
            type = types.nullOr types.number;
            default = null;
            description = "Was `layout.default-column-width` in machine.kdl.<profile>.";
          };
        };

        # Extra per-host window rules. The old machine.kdl.work carried two
        # Chrome app-id rules inline; those become data here.
        windowRules = mkOption {
          type = types.listOf types.lines;
          default = [ ];
          description = "Raw KDL `window-rule { … }` blocks appended to the generated machine.kdl.";
        };

        # Was hardcoded as `debug { render-drm-device "/dev/dri/card1" }` in the
        # tracked config.kdl — machine-specific state living in a fleet file.
        renderDrmDevice = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "niri `debug.render-drm-device`. Null omits the block entirely.";
        };
      };

      # -------------------------------------------------------------------------
      # Umbriel
      # -------------------------------------------------------------------------
      # umbriel/.config/umbriel/config.toml does `[include] files = […,
      # "output.toml", "machine.toml"]`. Both included files were machine-
      # specific and were activated by hand — machine.work opens with the comment
      # "Work profile: copy to machine.toml to activate", and output.toml is not
      # in the profile scheme at all, so it just had to be edited per box.
      #
      # Both are generated from the declarations below. The `machine.home` /
      # `machine.work` / `machine.laptop` variants become host configs.
      umbriel = {
        outputs = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                };
                mode = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  example = "2560x1440@144";
                };
                scale = mkOption {
                  type = types.nullOr types.number;
                  default = null;
                };
                position = mkOption {
                  type = types.nullOr (types.listOf types.int);
                  default = null;
                  example = [
                    0
                    0
                  ];
                };
                hdr = mkOption {
                  type = types.nullOr (
                    types.enum [
                      "off"
                      "on"
                      "auto"
                      "fullscreen"
                    ]
                  );
                  default = null;
                };
                vrr = mkOption {
                  type = types.nullOr (
                    types.enum [
                      "disabled"
                      "always"
                      "fullscreen"
                    ]
                  );
                  default = null;
                };
                tearing = mkOption {
                  type = types.nullOr types.bool;
                  default = null;
                };
                workspaces = mkOption {
                  type = types.nullOr (types.either types.int (types.listOf types.str));
                  default = null;
                  description = "Null keeps umbriel's dynamic workspaces.";
                };
              };
            }
          );
          default = { };
          description = "umbriel `[output.<connector>]` tables.";
        };

        layout = {
          extentPresets = mkOption {
            type = types.listOf types.number;
            default = [ ];
            description = "Was `[layout].extent_presets` in machine.<profile>.";
          };
          defaultExtentFraction = mkOption {
            type = types.nullOr types.number;
            default = null;
            description = "Was `[layout.scrolling].default_extent_fraction`.";
          };
          defaultMasterWidthFraction = mkOption {
            type = types.nullOr types.number;
            default = null;
            description = "Was `[layout.master].default_width_fraction`.";
          };
        };

        # Typed as free-form attrs and rendered with pkgs.formats.toml, so the
        # generated file is real TOML rather than interpolated text. Each entry is
        # one `[[window_rule]]` table, e.g.
        #   { match = { app_id = "^slack$"; }; default_floating = true; }
        windowRules = mkOption {
          type = types.listOf types.attrs;
          default = [ ];
        };

        autostart = mkOption {
          type = types.listOf types.str;
          default = [
            "vicinae server"
          ];
          description = "Was `[general].autostart`. The per-profile Chrome app-window and Slack entries move to the host that actually has them.";
        };

        touchpad = {
          disableWhileTyping = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };
          disableOnExternalMouse = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };
        };
      };
    };
  };
}
