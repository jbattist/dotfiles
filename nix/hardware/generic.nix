# Portable UEFI x86_64 hardware and disk layout.
#
# disko-install overrides disko.devices.disk.system.device with:
#   --disk system /dev/disk/by-id/...
# so the committed default is only a fallback for local evaluation.
#
# WARNING: applying this layout destroys the entire selected disk.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Broad enough for common NVMe/SATA/USB installer targets. The installed
  # initrd includes only these drivers; add a host override for unusual storage.
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "uas"
    "usb_storage"
    "usbhid"
    "xhci_pci"
  ];
  # Do not force vendor-specific GPU/CPU/KVM modules in the generic build.
  # Kernel modaliases load the right drivers; a future host module may opt into
  # vendor-specific tuning and microcode policy.
  hardware.enableRedistributableFirmware = true;

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # `nix run .#generic-vm` boots the same configuration without touching a
  # physical disk. This password exists only in system.build.vm, never in the
  # real installation closure. Change it freely if the VM is exposed to a
  # network you do not trust.
  virtualisation.vmVariant = {
    users.users.joe.initialPassword = "test";
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = true;
      diskSize = 32768;
    };
  };

  disko.devices.disk.system = {
    type = "disk";
    # The install app exports this only for its two `nix build --impure`
    # evaluations. Normal evaluation remains pure and uses jb.disk.device.
    device =
      let
        installDisk = builtins.getEnv "NIXOS_INSTALL_DISK";
      in
      if installDisk != "" then installDisk else config.jb.disk.device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@snapshots" = {
                mountpoint = "/.snapshots";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
