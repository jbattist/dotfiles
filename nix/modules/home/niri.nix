# niri configuration.
#
# This module is the clearest example of what the migration buys. The old setup
# assembled a working niri config from four separate mechanisms:
#
#   1. `3-install-dots.sh` asked which machine you were on and wrote the answer
#      to ~/.config/dotfiles/machine.env
#   2. it copied niri/.config/niri/machine.kdl.<profile> to machine.kdl
#   3. it ran `niri msg --json outputs` and substituted the first connector for
#      `__NIRI_OUTPUT__` with sed — and if niri was not running (which is the
#      normal case during install) it commented out the whole output block with a
#      second sed and told you to re-run later
#   4. config.kdl then did `include "./output.kdl"`, but output.kdl is in
#      .gitignore, so a fresh clone produced a config that included a file which
#      did not exist
#
# All four are replaced by two generated files whose contents come from
# jb.desktop.niri.*, set by a profile (nix/profiles/*.nix) and optionally
# overridden per host (hosts/<name>/). There is no
# prompt, no runtime probe, no placeholder substitution, and nothing missing
# after a clone.
#
# The hand-written KDL that is *not* machine-specific — config.kdl, keybinds.kdl,
# windowrules.kdl, noctalia.kdl, ~700 lines total — is deployed verbatim as store
# paths. Rewriting working KDL into Nix attrsets would risk the raw-string regex
# literals (r#"^(com\.mitchellh\.ghostty|…)$"#) and buy nothing.

{
  config,
  lib,
  pkgs,
  jbRoles,
  jbDesktop,
  ...
}:

let
  root = ../../..;
  niriCfg = jbDesktop.niri;

  # toJSON prints 0.3333 as `0.3333`; toString would print `0.333300`.
  num = n: builtins.toJSON n;

  # One `output "<connector>" { … }` block. Every field is optional and omitted
  # when null, so a host can declare just a scale and inherit niri's defaults for
  # the rest.
  renderOutput =
    name: o:
    lib.optionalString o.enable (
      "output \"${name}\" {\n"
      + lib.concatMapStrings (l: "    ${l}\n") (
        lib.optional (o.mode != null) ''mode "${o.mode}"''
        ++ lib.optional (o.scale != null) "scale ${num o.scale}"
        ++ lib.optional (o.transform != null) ''transform "${o.transform}"''
        ++ lib.optional (
          o.position != null
        ) "position x=${toString o.position.x} y=${toString o.position.y}"
      )
      + "}\n"
    );

  outputKdl =
    if niriCfg.outputs == { } then
      # A host with no declared outputs still needs the file to exist, because
      # config.kdl includes it unconditionally. An empty include is valid KDL and
      # makes niri fall back to its own autodetected defaults.
      ''
        // No outputs declared for this host in jb.desktop.niri.outputs.
        // niri will use its autodetected defaults.
        // Run `niri msg outputs` and copy the connector names into
        // hosts/<name>/ to pin scale, mode and position.
      ''
    else
      ''
        // Generated from jb.desktop.niri.outputs — do not edit.
        // Source: nix/modules/home/niri.nix
      ''
      + lib.concatStrings (lib.mapAttrsToList renderOutput niriCfg.outputs);

  machineKdl =
    let
      presets = lib.concatMapStrings (
        p: "        proportion ${num p}\n"
      ) niriCfg.layout.presetColumnWidths;
      layout =
        lib.optionalString
          (niriCfg.layout.presetColumnWidths != [ ] || niriCfg.layout.defaultColumnWidth != null)
          (
            "layout {\n"
            + lib.optionalString (
              niriCfg.layout.presetColumnWidths != [ ]
            ) "    preset-column-widths {\n${presets}    }\n"
            + lib.optionalString (
              niriCfg.layout.defaultColumnWidth != null
            ) "    default-column-width { proportion ${num niriCfg.layout.defaultColumnWidth}; }\n"
            + "}\n\n"
          );
      # The old machine.kdl.<profile> templates each carried a terminal
      # window-rule with a per-profile width (home 0.3333, work 0.2, laptop
      # 0.5). windowrules.kdl keeps the fleet default; a host states only its
      # own width.
      terminalRule = lib.optional (niriCfg.terminalColumnWidth != null) ''
        window-rule {
            match app-id=r#"^(com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|wezterm|kitty)$"#
            default-column-width { proportion ${num niriCfg.terminalColumnWidth}; }
        }
      '';
      rules = lib.concatMapStrings (r: r + "\n") (niriCfg.windowRules ++ terminalRule);
      debug = lib.optionalString (niriCfg.renderDrmDevice != null) ''
        debug {
            render-drm-device "${toString niriCfg.renderDrmDevice}"
        }
      '';
    in
    ''
      // Generated from jb.desktop.niri.* — do not edit.
      // Source: nix/modules/home/niri.nix
      //
      // Replaces machine.kdl.<profile>, which 3-install-dots.sh copied into place
      // after substituting __NIRI_OUTPUT__ with sed.

    ''
    + layout
    + rules
    + debug;
in
{
  config = lib.mkIf (jbRoles.desktop-niri || jbRoles.shell) {
    xdg.configFile = {
      # Hand-written, machine-independent. Deployed verbatim.
      "niri/config.kdl".source = root + "/niri/.config/niri/config.kdl";
      "niri/keybinds.kdl".source = root + "/niri/.config/niri/keybinds.kdl";
      "niri/windowrules.kdl".source = root + "/niri/.config/niri/windowrules.kdl";
      "niri/noctalia.kdl".source = root + "/niri/.config/niri/noctalia.kdl";

      # Generated. These two paths were the ones the installer had to synthesise
      # at run time; both are now plain functions of the host declaration.
      "niri/output.kdl".text = outputKdl;
      "niri/machine.kdl".text = machineKdl;
    };

    home.packages = with pkgs; [
      # `niri msg` is used by the fish helper functions and by anything that
      # wants to script the compositor.
      niri
    ];
  };
}
