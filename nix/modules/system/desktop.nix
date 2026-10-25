# The desktop stack: compositor, shell, audio, portals, gaming.
#
# Replaces the `desktop-niri`, `audio` and `gaming` entries of
# manifests/packages/, plus the service expectations that
# scripts/service-reconcile.sh used to enforce by hand.
#
# Package renames versus the Arch manifests:
#   umbriel-git          -> umbriel
#   noctalia             -> noctalia (v5, native C++; not v4 noctalia-shell)
#   vicinae-bin          -> vicinae
#   xorg-xwayland        -> xwayland
#   gst-plugin-pipewire  -> built by the pipewire derivation itself
#   libpulse             -> libpulseaudio

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.jb.roles;
  desktop = cfg.desktop-niri;

  audioPackages =
    with pkgs;
    lib.optionals cfg.audio [
      libpulseaudio
      gst_all_1.gst-plugins-base
      # `wpctl` is what niri/.config/niri/keybinds.kdl invokes for the XF86Audio*
      # bindings; named here so the dependency is visible.
      wireplumber
    ];

  gamingPackages = lib.optionals cfg.gaming [ pkgs.protonplus ];

  desktopPackages =
    with pkgs;
    lib.optionals desktop [
      umbriel
      noctalia
      vicinae
      flameshot
      cliphist
      wl-clipboard # cliphist and the fish `quick-share` function both need it
      gnome-network-displays
      # Noctalia's polkit_agent = true expects an agent on the bus.
      kdePackages.polkit-kde-agent-1
    ];
in
{
  # ---------------------------------------------------------------------------
  # Audio — was the pipewire block of manifests/packages/desktop-niri
  # ---------------------------------------------------------------------------
  # `services.pipewire.enable` pulls in pipewire, pipewire-alsa, pipewire-pulse
  # and wireplumber, and wires the systemd user units. The Arch manifest listed
  # six separate packages and left the unit wiring to the desktop environment.
  services.pipewire = {
    enable = lib.mkDefault cfg.audio;
    alsa.enable = lib.mkDefault cfg.audio;
    alsa.support32Bit = lib.mkDefault (cfg.audio && cfg.gaming);
    pulse.enable = lib.mkDefault cfg.audio;
    # PipeWire JACK shim.
    # avoids a separate jackd install if anything ever asks for JACK.
    jack.enable = lib.mkDefault cfg.audio;
  };

  # Apps that dlopen libpulse at runtime (Steam, some Electron builds) need it in
  # the system profile — a per-user home.packages entry is not visible to
  # setuid/system services.
  environment.systemPackages = audioPackages ++ desktopPackages ++ gamingPackages;

  # (audio package list lives in the `let` block above)

  # WirePlumber runs as a *user* service; it needs a session bus and the right
  # environment. Enabling it here is what makes the XF86 volume binds work.
  security.rtkit.enable = lib.mkDefault cfg.audio;

  # ---------------------------------------------------------------------------
  # Compositor + shell — Umbriel only in the core profile
  # ---------------------------------------------------------------------------
  # Umbriel ships start-umbriel and share/wayland-sessions/umbriel.desktop. The
  # package wraps its compositor with xwayland-satellite, so neither the Niri
  # session nor the Hyprland package is installed.
  programs.niri.enable = false;
  programs.xwayland.enable = lib.mkDefault desktop;

  # start-umbriel does not exec the compositor itself: under systemd it runs
  # `systemctl --user --wait start umbriel.service`. Listing the package only in
  # systemPackages does NOT register its units, so that start failed instantly
  # and greetd returned to the login prompt (indistinguishable from a bad
  # password). systemd.packages links share/systemd/user/{umbriel.service,
  # umbriel-session.target,umbriel-shutdown.target} into /etc/systemd/user.
  systemd.packages = lib.optionals desktop [ pkgs.umbriel ];

  # Register share/wayland-sessions/umbriel.desktop for session pickers.
  services.displayManager.sessionPackages = lib.optionals desktop [ pkgs.umbriel ];

  # noctalia-greeter discovers sessions in /run/current-system/sw/share/
  # wayland-sessions. sessionPackages alone only feeds the display-manager's
  # private desktops path, so also link Umbriel's session file into the system
  # profile or the greeter shows no session to start.
  environment.pathsToLink = lib.optionals desktop [ "/share/wayland-sessions" ];

  xdg.portal = lib.mkIf desktop {
    enable = true;
    # The old manifest installed xdg-desktop-portal-gnome and
    # 3-install-dots.sh added a user-unit drop-in to restart it after a
    # compositor restart (so Flameshot would not hang). Both are handled:
    # the portal package here, the drop-in in nix/modules/home/services.nix.
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    # Umbriel is wlroots-based and supports the wlr portal protocols.
    wlr.enable = true;
    config.common.default = lib.mkDefault "gnome";
  };

  # ---------------------------------------------------------------------------
  # Display manager — greetd/tuigreet launches Umbriel directly
  # ---------------------------------------------------------------------------
  services.greetd = lib.mkIf desktop {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command =
        if cfg.noctalia-greeter then
          "${pkgs.noctalia-greeter}/bin/noctalia-greeter-session"
        else
          "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --cmd /run/current-system/sw/bin/start-umbriel";
    };
  };

  # noctalia-greeter ships tmpfiles rules for its state directory and lists
  # sessions from share/wayland-sessions (registered via sessionPackages above).
  systemd.tmpfiles.packages = lib.optionals (desktop && cfg.noctalia-greeter) [ pkgs.noctalia-greeter ];

  # ---------------------------------------------------------------------------
  # Gaming — was manifests/packages/gaming
  # ---------------------------------------------------------------------------
  # `programs.steam.enable` builds the FHS environment Steam needs. This is what
  # the old `sed` over /etc/pacman.conf to uncomment `[multilib]` was working
  # around: Steam requires 32-bit libraries, which on Arch means enabling a
  # repository. Nix builds both ABIs from source, so there is no multilib stanza
  # to toggle and no reason for a script to edit a package manager's config.
  programs.steam = lib.mkIf cfg.gaming {
    enable = true;
    # Lets Steam launch games from niri/Noctalia without the extra-args dialog.
    gamescopeSession.enable = false;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  hardware.graphics = {
    enable = lib.mkDefault (desktop || cfg.gaming);
    # 32-bit Vulkan/OpenGL loaders, required by Steam and Proton. This is the
    # direct replacement for the multilib stanza.
    enable32Bit = lib.mkDefault (desktop || cfg.gaming);
  };

  # ---------------------------------------------------------------------------
  # Input / power
  # ---------------------------------------------------------------------------
  # umbriel/.config/umbriel/machine.laptop and the niri touchpad block assume
  # libinput. Enabling it system-wide is what makes `input { touchpad { tap } }`
  # apply consistently across compositors.
  services.libinput.enable = lib.mkDefault desktop;

  # Battery/brightness reporting for Noctalia's bar widgets. Harmless on a
  # desktop (upower just finds no battery).
  services.upower.enable = lib.mkDefault desktop;

  # `udiskie` was in manifests/packages/interactive and needs udisks2 running to
  # do anything; the Arch manifest installed the tray applet without the daemon
  # dependency being declared anywhere.
  services.udisks2.enable = lib.mkDefault desktop;

  # GTK/Qt apps read their settings through dconf. Without this, the
  # gtk-3.0/settings.ini values deployed by home-manager are ignored by GNOME
  # toolkits.
  programs.dconf.enable = lib.mkDefault desktop;
}
