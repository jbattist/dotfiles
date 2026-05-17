#!/usr/bin/env bash
set -euo pipefail

# Cycle niri-like preset widths. The scrolling layout has native colresize
# presets; dwindle needs a relative resize toward the next preset width.
layout=$(hyprctl getoption general:layout -j | jq -r '.str // empty')

if [[ "$layout" == "scrolling" ]]; then
    exec hyprctl eval 'hl.dispatch(hl.dsp.layout("colresize +conf"))'
fi

if [[ "$layout" == "dwindle" ]]; then
    active_json=$(hyprctl activewindow -j)
    monitor_id=$(jq -r '.monitor' <<<"$active_json")
    current_w=$(jq -r '.size[0]' <<<"$active_json")
    monitor_json=$(hyprctl monitors -j | jq --argjson id "$monitor_id" '.[] | select(.id == $id)')
    monitor_w=$(jq -r '(.width / .scale) | floor' <<<"$monitor_json")

    # Match niri preset-column-widths: 1/3, 1/2, 0.6.
    # Use hysteresis so small rounding/gap differences do not get stuck.
    ratio=$(awk -v w="$current_w" -v m="$monitor_w" 'BEGIN { if (m <= 0) print 0; else print w / m }')
    target_ratio=$(awk -v r="$ratio" 'BEGIN { if (r < 0.42) print 0.5; else if (r < 0.55) print 0.6; else print 0.3333 }')
    target_w=$(awk -v m="$monitor_w" -v r="$target_ratio" 'BEGIN { printf "%d", m * r }')
    delta=$(( target_w - current_w ))

    exec hyprctl eval "hl.dispatch(hl.dsp.window.resize({ x = ${delta}, y = 0, relative = true }))"
fi

# Other layouts do not have niri-style columns; keep the key harmless.
exec hyprctl eval 'hl.dispatch(hl.dsp.no_op())'
