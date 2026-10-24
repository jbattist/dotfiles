# User systemd units and idle/lock handling.
#
# Replaces install_user_systemd_config() from 3-install-dots.sh and the tracked
# swayidle/.config/systemd/user/swayidle.service unit.
#
# install_user_systemd_config() did five imperative things after copying one
# drop-in file:
#
#   1. compared the existing file with cmp -s and deleted it if identical
#   2. otherwise ran backup_path() to move it aside with a timestamp
#   3. stowed the `systemd` package
#   4. ran `systemctl --user daemon-reload`
#   5. looked up LoadState and ran `systemctl --user stop
#      xdg-desktop-portal-gnome.service` so the drop-in would take effect without
#      a GUI restart
#
# All five collapse into a declarative `Service` attribute set below.
# home-manager's activation handles the daemon-reload, and the unit is restarted
# by the generation switch rather than by a hand-written stop.

{
  config,
  lib,
  pkgs,
  jbRoles,
  jbOpts,
  ...
}:

{
  config = lib.mkIf jbRoles.desktop-niri {
    # -------------------------------------------------------------------------
    # xdg-desktop-portal-gnome restart policy
    # -------------------------------------------------------------------------
    # Byte-for-byte the same policy as
    # systemd/.config/systemd/user/xdg-desktop-portal-gnome.service.d/restart.conf:
    #
    #   [Unit]
    #   # Recover when the backend loses its Wayland compositor connection.
    #   [Service]
    #   Restart=on-failure
    #   RestartSec=5
    #
    # The reason it exists is unchanged: portal backends are demand-activated
    # D-Bus services, and when niri restarts the GNOME portal loses its
    # compositor connection and exits. Without a restart policy Flameshot then
    # hangs waiting for a screenshot that will never come.
    systemd.user.services.xdg-desktop-portal-gnome = {
      Service = {
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # -------------------------------------------------------------------------
    # swayidle
    # -------------------------------------------------------------------------
    # The tracked unit was NOT installed by any of the four scripts — the README
    # lists swayidle alongside mango and paneru as tracked-but-not-installed. It
    # is ported here behind an option that defaults to off, so the capability
    # survives the migration without silently changing behaviour on a host that
    # never ran it.
    #
    # Two reasons it stayed off:
    #
    #   * Its ExecStart calls `qs -c noctalia-shell ipc call lockScreen lock`,
    #     an older Noctalia IPC path. niri's own keybinds.kdl uses the current
    #     one (`noctalia msg session lock`, bound to Super+L).
    #   * Noctalia ships its own idle/lock handling, so running swayidle
    #     alongside it can produce two lock attempts on one timeout.
    #
    # The raw unit also hardcoded `ExecStart=/usr/bin/swayidle`, a path that does
    # not exist on NixOS. The home-manager module resolves the binary through the
    # store, which is the actual fix for that.
    services.swayidle = lib.mkIf jbOpts.desktop.swayidle {
      enable = true;
      # `-w` waits for the Wayland compositor before registering; the tracked
      # unit passed it explicitly.
      extraArgs = [ "-w" ];
      timeouts = [
        {
          timeout = 3600;
          command = "noctalia msg session lock";
        }
        # The tracked unit had a second, commented-out entry:
        #   timeout 14400 'qs -c noctalia-shell ipc call sessionMenu lockAndSuspend'
        # Left out for the same reason it was commented out upstream.
      ];
    };
  };
}
