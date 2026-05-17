#!/usr/bin/env bash
set -euo pipefail

# Preserve niri-like Mod+F behavior in scrolling (maximize the column), while
# making the same key useful in dwindle where colresize is not implemented.
layout=$(hyprctl getoption general:layout -j | jq -r '.str // empty')

if [[ "$layout" == "scrolling" ]]; then
    exec hyprctl eval 'hl.dispatch(hl.dsp.layout("colresize 1"))'
fi

exec hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen" }))'
