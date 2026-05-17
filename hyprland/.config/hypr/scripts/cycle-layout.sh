#!/usr/bin/env bash
set -euo pipefail

layouts=(scrolling dwindle master monocle)
current="$(hyprctl getoption general:layout -j 2>/dev/null \
    | sed -n 's/.*"str"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1)"

if [[ -z "${current}" ]]; then
    current="$(hyprctl getoption general:layout 2>/dev/null \
        | sed -n 's/^[[:space:]]*\(str\|set\):[[:space:]]*//p' \
        | head -n 1)"
fi

next="${layouts[0]}"
for i in "${!layouts[@]}"; do
    if [[ "${layouts[$i]}" == "${current}" ]]; then
        next="${layouts[$(((i + 1) % ${#layouts[@]}))]}"
        break
    fi
done

hyprctl eval "hl.config({ general = { layout = \"${next}\" } })"
notify-send 'Hyprland layout' "Switched to ${next}" 2>/dev/null || true
