# Service standards

Service manifests define desired systemd state separately from package installation.

- `common.enable`: enable and start whenever step 2 installs selected manifests.
- `common.disable`: stop and disable whenever step 2 installs selected manifests.
- `<package-manifest>.enable`: enable and start when that package manifest is selected.
- `<package-manifest>.disable`: stop and disable when that package manifest is selected.

Each non-comment line is one validated systemd unit. Blank lines and full-line comments are ignored.

Current standard:

- `sshd.service`: enabled and active.
- `systemd-resolved.service`: enabled and active.
- `NetworkManager-wait-online.service`: disabled.
- `bluetooth.service`: enabled when `bluetooth` is selected.
- `cups.service`: enabled when `printing` is selected.
- `snapper-timeline.timer` and `snapper-cleanup.timer`: enabled when `snapshots` is selected.
- `greetd.service`: enabled when `desktop-umbriel` is selected.
- `gdm.service`: disabled when `desktop-umbriel` is selected.

`2-install-pkgs.sh` invokes `scripts/service-reconcile.sh` automatically with the selected package manifests. The reconciler applies only declared units and never touches unlisted services.
