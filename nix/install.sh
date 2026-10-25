set -euo pipefail

usage() {
  cat <<'EOF'
Install this NixOS configuration onto one whole disk.

Usage:
  install-nixos [--dry-run] DISK [PROFILE]

Arguments:
  DISK       Whole disk, for example /dev/sda or /dev/vda (not /dev/sda1)
  PROFILE    generic (default), generic-work, or generic-laptop

Examples:
  install-nixos --dry-run /dev/vda generic
  install-nixos /dev/vda generic

WARNING: without --dry-run, the entire selected disk is erased. Dual boot and
in-place conversion are not supported.
EOF
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

dry_run=false
if [[ ${1:-} == "--dry-run" ]]; then
  dry_run=true
  shift
fi

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

[[ $# -ge 1 && $# -le 2 ]] || {
  usage >&2
  exit 2
}

disk=$1
profile=${2:-generic}

case "$profile" in
  generic|generic-work|generic-laptop) ;;
  *) fail "unknown profile '$profile' (use generic, generic-work, or generic-laptop)" ;;
esac

# The flake app is first built as the live installer user. Re-executing the
# already-built store path with sudo avoids making root fetch/evaluate it again.
if [[ $(id -u) -ne 0 ]]; then
  # On NixOS, privilege-bearing programs live in /run/wrappers/bin. A plain
  # `pkgs.sudo` in /nix/store intentionally has no setuid bit and cannot elevate.
  # Use the system wrapper explicitly so package PATH ordering cannot shadow it.
  sudo_bin=/run/wrappers/bin/sudo
  if [[ ! -x $sudo_bin ]]; then
    sudo_bin=$(command -v sudo || true)
  fi
  [[ -n $sudo_bin && -x $sudo_bin ]] \
    || fail "no privilege-bearing sudo wrapper found; run this installer as root"

  if $dry_run; then
    exec "$sudo_bin" "$0" --dry-run "$disk" "$profile"
  else
    exec "$sudo_bin" "$0" "$disk" "$profile"
  fi
fi

[[ -d /sys/firmware/efi ]] || fail "this installer supports UEFI boot only; boot the ISO in UEFI mode"
[[ -b "$disk" ]] || fail "'$disk' is not a block device"

canonical_disk=$(readlink -f "$disk")
[[ -b "$canonical_disk" ]] || fail "cannot resolve '$disk' to a block device"

# Reject partitions. lsblk TYPE is stable for /dev/sdX, /dev/vdX, NVMe and
# /dev/disk/by-id symlinks.
[[ $(lsblk -dnro TYPE "$canonical_disk") == "disk" ]] \
  || fail "'$disk' is not a whole disk; select the parent disk, not a partition"

# Refuse to overwrite the live installer media or any disk with mounted content.
if lsblk -nrpo MOUNTPOINTS "$canonical_disk" | grep -q '[^[:space:]]'; then
  lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS "$canonical_disk" >&2
  fail "the selected disk or one of its partitions is mounted"
fi

printf '\nProfile: %s\nTarget:  %s -> %s\n\n' "$profile" "$disk" "$canonical_disk"
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS "$canonical_disk"

export NIXOS_INSTALL_DISK=$canonical_disk
export NIX_CONFIG=$'experimental-features = nix-command flakes\naccept-flake-config = true'
flake=${DOTFILES_FLAKE:?installer was not built with DOTFILES_FLAKE}
attribute="$flake#nixosConfigurations.$profile.config.system.build"

printf '\nEvaluating the pinned disk layout...\n'
disko_script=$(nix build --impure --no-link --print-out-paths "$attribute.diskoScript")

# Verify the impure disk override reached the generated script before offering
# to execute it. This protects against accidentally using the committed fallback.
grep -Fq "$canonical_disk" "$disko_script" \
  || fail "generated disk script does not reference $canonical_disk"

if $dry_run; then
  cat <<EOF

DRY RUN PASSED

The configuration evaluates, '$profile' is valid, and the generated disk script
references exactly:

  $canonical_disk

No disk changes were made. Run the same command without --dry-run to install.
EOF
  exit 0
fi

printf '\nTHIS ERASES THE ENTIRE DISK: %s\n' "$canonical_disk"
printf 'Type exactly: ERASE %s\n> ' "$canonical_disk"
IFS= read -r confirmation
[[ $confirmation == "ERASE $canonical_disk" ]] || fail "confirmation did not match; nothing changed"

printf '\nPartitioning, formatting, and mounting at /mnt...\n'
"$disko_script"

printf '\nBuilding the complete pinned NixOS system...\n'
system_path=$(nix build --impure --no-link --print-out-paths "$attribute.toplevel")

printf '\nInstalling NixOS and the boot loader...\n'
nixos-install \
  --no-channel-copy \
  --no-root-password \
  --system "$system_path" \
  --root /mnt

cat <<'EOF'

Set the initial password for user joe. You will be prompted twice.
EOF
nixos-enter --root /mnt -c 'passwd joe'

sync
cat <<'EOF'

INSTALLATION COMPLETE

You can now run:

  reboot

Remove the installer ISO when the VM or machine restarts.
EOF
