# ~/.config/fish/functions/ports.fish
# List open TCP listening ports.
# Colorized via grc/grcat when grc is installed and the conf exists.

set -g __ports_grc_conf "$HOME/.config/grc/conf.lsof"

function ports --description "List open TCP listening ports"
    sudo lsof -iTCP -sTCP:LISTEN -P -n | _ports_maybe_colorize
end

function _ports_maybe_colorize
    if command -q grcat; and test -f $__ports_grc_conf
        grcat $__ports_grc_conf
    else
        cat
    end
end
