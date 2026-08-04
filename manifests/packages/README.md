# Package manifests v2

Every file in this directory is a newline-delimited package manifest. Blank lines and full-line comments are ignored; each other line must contain exactly one package token. `scripts/package-lib.sh` validates tokens and deduplicates packages deterministically.

Package selection is interactive and local. There are no package profiles or host mappings. Dotfile profiles remain available only for machine-specific configuration such as Niri KDL files.

`1-install-shell.sh` installs the `shell` manifest, bootstraps yay, and stows shell configuration. The `shell` manifest is intentionally hidden from step 2 to avoid duplicate ownership.

## Install

Run step 2 without arguments:

```bash
bash 2-install-pkgs.sh
```

The script displays all package manifests in an `fzf` multi-select list. Use Tab to toggle manifests and Enter to install them. Escape cancels without changing anything.

After selection, the script:

1. Shows the selected manifests and package list.
2. Runs a full `pacman -Syu` update.
3. Installs missing packages independently with yay.
4. Applies service manifests matching the selected package manifests.

It never removes packages. Selecting `gaming` enables multilib. Selecting `bluetooth`, `printing`, or `snapshots` also applies their service standards. Fleet-wide service standards in `common.enable` and `common.disable` are always applied.

`work-apps` currently contains `slack-desktop`. Notes applications are included in `interactive`; there is no separate notes manifest.

## Promotion workflow

Add a package to the broadest manifest that accurately represents it. Create a narrowly named capability manifest only when users may reasonably select it independently. Run `bash -n`, `tests/run.sh`, and `tests/service-run.sh`, then review the manifest diff.
