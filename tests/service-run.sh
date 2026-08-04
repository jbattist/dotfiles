#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$ROOT/scripts/package-lib.sh"
. "$ROOT/scripts/service-lib.sh"

selected_enabled=$(resolve_service_action enable bluetooth printing snapshots)
selected_disabled=$(resolve_service_action disable bluetooth printing snapshots)
grep -qx sshd.service <<<"$selected_enabled"
grep -qx systemd-resolved.service <<<"$selected_enabled"
grep -qx bluetooth.service <<<"$selected_enabled"
grep -qx cups.service <<<"$selected_enabled"
grep -qx snapper-timeline.timer <<<"$selected_enabled"
grep -qx snapper-cleanup.timer <<<"$selected_enabled"
grep -qx NetworkManager-wait-online.service <<<"$selected_disabled"
if grep -qx snapper-timeline.service <<<"$selected_enabled"; then exit 1; fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cat >"$TMP/systemctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MOCK_LOG"
case "$1" in
  show) printf 'loaded\n'; exit 0 ;;
  is-enabled|is-active) exit 1 ;;
  *) exit 0 ;;
esac
MOCK
cat >"$TMP/sudo" <<'MOCK'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >>"$MOCK_LOG"
MOCK
chmod +x "$TMP/systemctl" "$TMP/sudo"
export MOCK_LOG="$TMP/log"
: >"$MOCK_LOG"
PATH="$TMP:$PATH" bash "$ROOT/scripts/service-reconcile.sh" bluetooth printing >"$TMP/out"
grep -q 'Service standards applied' "$TMP/out"
grep -q '^sudo systemctl enable --now sshd.service$' "$MOCK_LOG"
grep -q '^sudo systemctl enable --now bluetooth.service$' "$MOCK_LOG"
grep -q '^sudo systemctl enable --now cups.service$' "$MOCK_LOG"
if PATH="$TMP:$PATH" bash "$ROOT/scripts/service-reconcile.sh" >/dev/null 2>&1; then exit 1; fi
printf 'service tests ok\n'
