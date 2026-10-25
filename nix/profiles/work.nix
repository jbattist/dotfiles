# Work desktop profile, migrated from machine.kdl.work / umbriel/machine.work.
# No connector is pinned; outputs are autodetected on first boot.
{
  jb.desktop = {
    niri = {
      outputs = { };
      terminalColumnWidth = 0.2;
      layout = {
        presetColumnWidths = [
          0.2
          0.25
          0.3333
          0.5
        ];
        defaultColumnWidth = 0.25;
      };
      windowRules = [
        ''
          window-rule {
              match app-id=r#"chrome-faolnafnngnfdaknnbpnkhgohbobgegn-Default"#
              open-floating true
          }
        ''
        ''
          window-rule {
              match app-id=r#"chrome-cifhbcnohmdccbgoicgdjpfamggdegmo-Default"#
              default-column-width { proportion 0.25; }
          }
        ''
      ];
    };

    umbriel = {
      outputs = { };
      layout = {
        extentPresets = [
          0.2
          0.25
          0.3333
          0.5
        ];
        defaultExtentFraction = 0.25;
        defaultMasterWidthFraction = 0.55;
      };
      windowRules = [
        {
          match.app_id = "^chrome-faolnafnngnfdaknnbpnkhgohbobgegn-Default$";
          default_floating = true;
        }
        {
          match.app_id = "^chrome-cifhbcnohmdccbgoicgdjpfamggdegmo-Default$";
          default_scrolling_extent = 0.25;
        }
        {
          match.app_id = ''^(com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|wezterm|kitty)$'';
          default_scrolling_extent = 0.2;
        }
      ];
      autostart = [
        "noctalia"
        "vicinae server"
        "gtk-launch chrome-fmgjjmmmlfnkbppncabfkddbjimcfncm-Profile_1"
        "gtk-launch chrome-kjbdgfilnfhdoflbpgamdcdgpehopbep-Profile_1"
        "slack"
      ];
    };
  };
}
