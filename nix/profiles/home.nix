# Default desktop profile, migrated from:
#   niri/.config/niri/machine.kdl.home
#   umbriel/.config/umbriel/machine.home
#
# Outputs are intentionally empty. That is what makes this profile portable:
# niri and Umbriel autodetect connectors and modes. After installation, add an
# output block in a small host override only if scale/position must be pinned.
{
  jb.desktop = {
    niri = {
      outputs = { };
      terminalColumnWidth = 0.3333;
      layout = {
        presetColumnWidths = [
          0.3333
          0.5
          0.6
        ];
        defaultColumnWidth = 0.5;
      };
    };

    umbriel = {
      outputs = { };
      layout = {
        extentPresets = [
          0.3333
          0.5
          0.6
        ];
        defaultExtentFraction = 0.5;
        defaultMasterWidthFraction = 0.55;
      };
      windowRules = [
        {
          match.app_id = ''^(com\.mitchellh\.ghostty|org\.wezfurlong\.wezterm|wezterm|kitty)$'';
          default_scrolling_extent = 0.3333;
        }
      ];
      autostart = [ "vicinae server" ];
    };
  };
}
