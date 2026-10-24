# The desktop stack: compositor, shell, audio, portals, gaming.
#
# Replaces the `desktop-niri`, `audio` and `gaming` entries of
# manifests/packages/, plus the service expectations that
# scripts/service-reconcile.sh used to enforce by hand.
#
# Package renames versus the Arch manifests:
#   umbriel-git          -> umbriel
#   noctalia             -> noctalia-shell
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
      niri
      umbriel
      noctalia-shell
      vicinae
      xwayland-satellite
      flameshot
      cliphist
      wl-clipboard # cliphist and the fish `quick-share` function both need it
      jq # used by 3-install-dots.sh's output probe; kept because niri scripts use it
      gnome-network-displays
      # Noctalia's polkit_agent = true expects an agent on the bus.
      kdePackages.polkit-kde-agent-1
      # swaylock is bound to Super+Alt+L in keybinds.kdl.
      swaylock
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
  # Compositor + shell — was manifests/packages/desktop-niri
  # ---------------------------------------------------------------------------
  programs.niri.enable = lib.mkDefault desktop;

  # niri >= 25.08 spawns xwayland-satellite itself and sets DISPLAY for
  # children. config.kdl documents this explicitly and warns against hardcoding
  # DISPLAY; the package just has to be present.
  programs.xwayland.enable = lib.mkDefault desktop;

  xdg.portal = lib.mkIf desktop {
    enable = true;
    # The old manifest installed xdg-desktop-portal-gnome and
    # 3-install-dots.sh added a user-unit drop-in to restart it after a
    # compositor restart (so Flameshot would not hang). Both are handled:
    # the portal package here, the drop-in in nix/modules/home/services.nix.
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    # niri implements the wlr screencopy/layer-shell protocols; without these
    # settings screen sharing silently fails.
    wlr.enable = true;
    config.common.default = lib.mkDefault "gnome";
  };

  # ---------------------------------------------------------------------------
  # Display manager — was manifests/packages/noctalia-greeter
  # ---------------------------------------------------------------------------
  # The old service standard enabled greetd.service and disabled gdm.service.
  # On NixOS you do not "disable GDM" as a separate step: GDM is only present if
  # `services.xserver.displayManager.gdm.enable` is set, and it is not set
  # anywhere in this configuration. The `.disable` manifest disappears.
  services.greetd = lib.mkIf cfg.noctalia-greeter {
    enable = true;
    # The NixOS greetd module creates the `greeter` user, so nothing here has to
    # (the old package printed manual "create the greeter user" steps).
    settings.default_session.command = "${pkgs.noctalia-greeter}/bin/noctalia-greeter-session";
  };

  # The greeter package ships tmpfiles.d rules for its state directory.
  systemd.tmpfiles.packages = lib.optionals cfg.noctalia-greeter [ pkgs.noctalia-greeter ];

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
