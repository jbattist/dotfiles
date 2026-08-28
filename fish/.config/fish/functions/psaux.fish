# ~/.config/fish/functions/psaux.fish
# Compact, greppable process list — built for finding a PID to kill.
#
#   psaux               all processes, heaviest %cpu on top, no wrap
#   psaux chrome        only lines matching "chrome" (case-insensitive)
#   psaux -t chrome     forest view: children indented under parents
#   psaux -w chrome     wide: full command lines (may wrap)
#
# Width handling: procps truncates the args column to the terminal width
# itself (via COLUMNS when piped); -w maps to ps -ww for unlimited width.

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
        command ps $ps_args
        return 0
    end

    # []-trick: keep the filter command itself out of the listing
    set -l pat (string replace -r '^.' '[$0]' -- $pattern)

    if not command ps $ps_args | rg -q -i -- "$pat"
        echo "No processes match: $pattern" >&2
        return 1
    end
    # Colorize after ps has truncated, so escapes are never cut mid-stream
    command ps $ps_args | rg -i --color=auto -- "$pat"
    return 0
end