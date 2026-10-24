# Service policy and host services.
#
# Replaces manifests/services/*.enable / *.disable and the reconciler that
# applied them (scripts/service-reconcile.sh, invoked by 2-install-pkgs.sh).
#
# The reconciler existed because pacman and systemd are separate systems: you
# install a package, then you must remember to enable its unit, and the
# `.enable`/`.disable` lists were the memory. On NixOS a service and its package
# are one option, so there is nothing to reconcile and no way to get out of sync.
# Every unit named in the old manifests appears below exactly once.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.jb.roles;
in
{
  # ---------------------------------------------------------------------------
  # manifests/services/bluetooth.enable  ->  bluetooth.service
  # ---------------------------------------------------------------------------
  hardware.bluetooth = {
    enable = cfg.bluetooth;
    powerOnBoot = cfg.bluetooth;
  };
  services.blueman.enable = cfg.bluetooth;

  # ---------------------------------------------------------------------------
  # manifests/services/printing.enable  ->  cups.service
  # ---------------------------------------------------------------------------
  # The Arch manifest needed three packages (cups, cups-pk-helper,
  # system-config-printer) and then a separate service standard to enable
  # cups.service. `services.printing.enable` does all of it.
  services.printing = {
    enable = cfg.printing;
    # drivers were previously pulled in implicitly by whatever the printer's
    # package happened to depend on.
    drivers = lib.optionals cfg.printing (
      with pkgs;
      [
        cups-pk-helper
        gutenprint
        splix
      ]
    );
  };

  # ---------------------------------------------------------------------------
  # manifests/services/snapshots.enable  ->  snapper-timeline.timer,
  #                                          snapper-cleanup.timer
  #
  # DELIBERATELY NOT PORTED AS SNAPPER.
  # ---------------------------------------------------------------------------
  # Snapper's job on Arch was to snapshot `/` so a bad `pacman -Syu` could be
  # rolled back. NixOS solves that problem structurally:
  #
  #   * every `nixos-rebuild switch` creates a new *generation* in /nix/var/nix
  #   * systemd-boot gets a boot entry per generation
  #   * `nixos-rebuild switch --rollback` or picking an entry at boot reverts
  #     the entire system atomically, including kernel and config
  #
  # A btrfs snapshot of a NixOS root adds nothing on top of that, and snapshotting
  # /nix/store actively hurts (the store is already immutable and shared).
  #
  # What snapper *was* usefully doing here is snapshotting **user data** on the
  # `@home` subvolume — that has no Nix equivalent, so it is kept, using btrbk
  # (which has a first-class NixOS module) instead of snapper.
  #
  # hermes's disk layout (verified): single btrfs filesystem on nvme0n1p2 with
  # subvolumes @, @home, @pkg, @log; compress=zstd:3, ssd, discard=async.
  services.btrbk.instances.home = lib.mkIf cfg.snapshots {
    # snapper-timeline.timer defaulted to hourly; retention is stated explicitly
    # here instead of being inherited from /etc/snapper/configs.
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "24h 7d 4w 6m";
      volume."/" = {
        snapshot_dir = "/.snapshots";
        subvolume."home" = { };
      };
    };
  };

  # btrfs-progs was in manifests/packages/snapshots; it is also needed by
  # `nixos-rebuild` for subvolume-aware operations and by the fstab entries.
  environment.systemPackages = with pkgs; lib.optionals cfg.snapshots [ btrfs-progs ];

  # ---------------------------------------------------------------------------
  # Network mounts — from /etc/fstab, previously unmanaged
  # ---------------------------------------------------------------------------
  # The existing fstab carries a CIFS mount to the NAS with credentials in
  # /etc/samba/credentials-joe. That file is a secret and is NOT committed. It is
  # created out of band (or by sops-nix, see docs/MIGRATION.md §Secrets).
  #
  # Gated on jb.homelab.enable so that building this flake off the homelab
  # network does not produce a host that hangs at boot on an unreachable share.
  fileSystems."/mnt/joe" = lib.mkIf config.jb.homelab.enable {
    device = "//truenas.home/joe";
    fsType = "cifs";
    options = [
      "credentials=/etc/samba/credentials-joe"
      "uid=1000"
      "gid=1000"
      "file_mode=0775"
      "dir_mode=0775"
      "vers=3.1.1"
      "noperm"
      "_netdev"
      "x-systemd.automount"
      "nofail"
    ];
  };

  # `nofail` + `x-systemd.automount` mean a missing share (or a missing
  # credentials file) cannot block boot. The credentials file is deliberately not
  # checked at evaluation time: a flake must build on machines that do not have
  # this host's secrets.

  # ---------------------------------------------------------------------------
  # mDNS
  # ---------------------------------------------------------------------------
  # `*.home` names (forgejo.home, truenas.home, heimdallama.home, hermes.home)
  # resolve via the DHCP-provided resolver with `Domains=home` from base.nix.
  # avahi is enabled so that this host is also *discoverable* by name, which the
  # fish `herd`/`hermes-tui` helpers assume.
  services.avahi = lib.mkIf cfg.shell {
    enable = lib.mkDefault true;
    nssmdns4 = true;
    # Discoverable by name, which the fish `herd`/`hermes-tui` helpers assume.
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
    };
  };
}
