# ~/.config/fish/functions/psaux.fish
# Compact, greppable, color-coded process list — built for finding a PID to kill.
#
#   psaux               all processes, heaviest %cpu on top, no wrap
#   psaux chrome        only lines matching "chrome" (case-insensitive, highlighted)
#   psaux -t chrome     forest view: children indented under parents
#   psaux -w chrome     wide: full command lines (may wrap)
#
# Colors: header cyan, PID bold yellow, root red, %cpu/%mem heat-graded
# (>=50% bright red, >=10% yellow), RSS magenta, STAT cyan (zombies bold
# red), elapsed dim. Width handling: procps truncates the args column to
# the terminal width itself (via COLUMNS when piped); -w maps to ps -ww.

function psaux --description "Compact process list; psaux [pattern]"
    set -l cols pid,user,%cpu,%mem,rss,stat,etime,args
    set -l ps_args -e -o $cols --sort=-%cpu
    set -l pattern ""

    for arg in $argv
        switch $arg
            case -t --tree
                set ps_args $ps_args --forest
            case -w --wide
                set ps_args $ps_args -ww
            case '*'
                set pattern "$pattern $arg"
        end
    end
    set pattern (string trim -- $pattern)

    if test -z "$pattern"
        command ps $ps_args | _psaux_colorize
        return 0
    end

    # []-trick: keep the filter command itself out of the listing
    set -l pat (string replace -r '^.' '[$0]' -- $pattern)

    if not command ps $ps_args | rg -q -i -- "$pat"
        echo "No processes match: $pattern" >&2
        return 1
    end
    # Colorize after ps truncates, so escapes are never cut mid-stream;
    # rg's match highlight (applied last) wins over the column color.
    command ps $ps_args | _psaux_colorize | rg -i --color=auto -- "$pat"
    return 0
end
# _psaux_colorize lives in its own file (shared with psk).