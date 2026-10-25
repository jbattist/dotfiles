# Laptop profile, migrated from machine.kdl.laptop / umbriel/machine.laptop.
# Output autodetection keeps it usable across panels with eDP-1/eDP-2 names.
{
  jb.desktop = {
    niri = {
      outputs = { };
      terminalColumnWidth = 0.5;
      layout = {
        presetColumnWidths = [
          0.3333
          0.5
          0.6666
          0.8
        ];
        defaultColumnWidth = 0.6666;
      };
    };

    umbriel = {
      outputs = { };
      layout = {
        extentPresets = [
          0.3333
          0.5
          0.6666
          0.8
        ];
        defaultExtentFraction = 0.6666;
        defaultMasterWidthFraction = 0.55;
      };
      windowRules = [
        {
          match.app_id = ''^(com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|wezterm|kitty)$'';
          default_scrolling_extent = 0.5;
        }
      ];
      autostart = [
        "vicinae server"
      ];
      touchpad = {
        disableWhileTyping = true;
        disableOnExternalMouse = true;
      };
    };
  };
}
