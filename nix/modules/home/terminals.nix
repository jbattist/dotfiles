# Terminals: ghostty, wezterm, kitty.
#
# Replaces the `ghostty`, `wezterm` and `kitty` stow packages. Step 1 stowed
# ghostty/wezterm and step 3 stowed them again (3-install-dots.sh re-runs
# `backup_and_stow ghostty` and `wezterm`), which is why those two had two
# backup opportunities and could accumulate `.backup.<ts>` siblings. Here each
# path is owned once.
#
# All three terminals were deliberately kept in sync by hand — the commit
# "feat(terminals): port Ghostty profile to WezTerm and Kitty" exists precisely
# because the same profile is expressed three times. The shared values are
# collected in `profile` below so that drift is at least visible in one place.

{
  config,
  lib,
  pkgs,
  jbRoles,
  ...
}:

let
  root = ../../..;

  # The common terminal profile, extracted from the three configs:
  #   ghostty/.config/ghostty/config   font-family / font-size 11 / opacity 0.9
  #   wezterm/.wezterm.lua             font / font_size 11 / opacity 0.90
  #   kitty/.config/kitty/kitty.conf   font_family / font_size 11.0 / opacity 0.90
  profile = {
    font = "JetBrainsMono Nerd Font Mono";
    fontSize = 11;
    opacity = 0.9;
    theme = "noctalia";
  };
in
{
  config = lib.mkIf jbRoles.shell {
    # -------------------------------------------------------------------------
    # ghostty
    # -------------------------------------------------------------------------
    programs.ghostty = {
      enable = true;

      # The tracked ghostty config is ~120 lines, but all but six of them are the
      # auto-generated template comments that ship with a fresh
      # `ghostty +show-config`. The real settings are small enough to express
      # natively, which gets type checking on the values.
      settings = {
        font-family = profile.font;
        font-size = profile.fontSize;
        background-opacity = profile.opacity;
        clipboard-read = "allow";
        clipboard-write = "allow";
        theme = profile.theme;
      };
    };

    # The noctalia theme is Ghostty's own `key = value` palette format, not
    # something Nix can round-trip through an attrset without inventing a
    # convention for repeated `palette` keys. Deployed verbatim; Ghostty resolves
    # `theme = noctalia` from ~/.config/ghostty/themes/.
    xdg.configFile."ghostty/themes/noctalia".source = root + "/ghostty/.config/ghostty/themes/noctalia";

    # -------------------------------------------------------------------------
    # kitty
    # -------------------------------------------------------------------------
    programs.kitty = {
      enable = true;

      settings = {
        font_family = profile.font;
        font_size = "${toString profile.fontSize}.0";
        background_opacity = profile.opacity;
        # kitty's clipboard_control is a space-separated list in the config file.
        clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
        tab_bar_min_tabs = 2;
        tab_bar_edge = "top";
      };

      # kitty.conf's last line is `include themes/noctalia.conf`. home-manager
      # appends extraConfig after the generated settings, which reproduces the
      # original ordering (include wins over the settings above, exactly as in
      # the tracked file).
      extraConfig = ''
        include themes/noctalia.conf
      '';
    };

    xdg.configFile."kitty/themes/noctalia.conf".source =
      root + "/kitty/.config/kitty/themes/noctalia.conf";

    # -------------------------------------------------------------------------
    # wezterm
    # -------------------------------------------------------------------------
    # wezterm/.wezterm.lua is a full Lua configuration using
    # `wezterm.config_builder()`, a key table with LEADER mods, and a
    # `return config` at the end. There is no Nix representation of that; it is
    # deployed as-is. Note it is a dotfile in $HOME, not under ~/.config.
    home.file.".wezterm.lua".source = root + "/wezterm/.wezterm.lua";

    # .wezterm.lua resolves its colour scheme with
    #   config.color_scheme_dirs = { wezterm.home_dir .. '/.config/wezterm/colors' }
    # so the theme must be present at that exact path.
    xdg.configFile."wezterm/colors/noctalia.toml".source =
      root + "/wezterm/.config/wezterm/colors/noctalia.toml";

    home.packages = with pkgs; [
      wezterm
    ];
  };
}
