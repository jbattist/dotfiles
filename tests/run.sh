#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$ROOT/scripts/package-lib.sh"

mapfile -t manifests < <(list_package_manifests)
contains interactive "${manifests[@]}"
contains work-apps "${manifests[@]}"
contains gaming "${manifests[@]}"
contains desktop-niri "${manifests[@]}"
if contains shell "${manifests[@]}"; then exit 1; fi
if contains README.md "${manifests[@]}"; then exit 1; fi
packages=$(resolve_manifests interactive work-apps)
grep -qx obsidian <<<"$packages"
grep -qx slack-desktop <<<"$packages"
desktop_pkgs=$(resolve_manifests desktop-niri)
grep -qx umbriel-git <<<"$desktop_pkgs"
grep -qx noctalia-greeter <<<"$desktop_pkgs"
grep -qx greetd <<<"$desktop_pkgs"
if resolve_manifests notes >/dev/null 2>&1; then exit 1; fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cat >"$TMP/fzf" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' interactive work-apps
MOCK
cat >"$TMP/pacman" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == -Qi ]]; then exit 1; fi
printf 'pacman %s\n' "$*" >>"$MOCK_LOG"
MOCK
cat >"$TMP/yay" <<'MOCK'
#!/usr/bin/env bash
printf 'yay %s\n' "$*" >>"$MOCK_LOG"
MOCK
cat >"$TMP/sudo" <<'MOCK'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >>"$MOCK_LOG"
if [[ "$1" == pacman ]]; then exit 0; fi
exec "$@"
MOCK
cat >"$TMP/systemctl" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
  show) printf 'loaded\n';;
  is-enabled|is-active) exit 0;;
esac
MOCK
chmod +x "$TMP/fzf" "$TMP/pacman" "$TMP/yay" "$TMP/sudo" "$TMP/systemctl"
export MOCK_LOG="$TMP/log"
: >"$MOCK_LOG"
PATH="$TMP:$PATH" bash "$ROOT/2-install-pkgs.sh" >"$TMP/out"
grep -q 'Selected manifests: interactive work-apps' "$TMP/out"
grep -q '^sudo pacman -Syu --noconfirm$' "$MOCK_LOG"
grep -q '^yay -S --needed --noconfirm obsidian$' "$MOCK_LOG"
grep -q '^yay -S --needed --noconfirm slack-desktop$' "$MOCK_LOG"
if grep -q '^sudo sed ' "$MOCK_LOG"; then exit 1; fi

cat >"$TMP/fzf" <<'MOCK'
#!/usr/bin/env bash
exit 130
MOCK
chmod +x "$TMP/fzf"
: >"$MOCK_LOG"
PATH="$TMP:$PATH" bash "$ROOT/2-install-pkgs.sh" >"$TMP/cancel"
grep -q 'nothing changed' "$TMP/cancel"
[[ ! -s "$MOCK_LOG" ]]
printf 'ok\n'
