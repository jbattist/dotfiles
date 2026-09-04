#!/usr/bin/env bash
set -euo pipefail
layouts=(dwindle master scrolling)
current=$(hyprctl activeworkspace -j | jq -r '.tiledLayout // .tiled_layout')
next=${layouts[0]}
for i in "${!layouts[@]}"; do
    if [[ "${layouts[$i]}" == "$current" ]]; then
        next=${layouts[$(((i + 1) % ${#layouts[@]}))]}
        break
    fi
done
hyprctl eval "hl.config({ general = { layout = \"${next}\" } })"
