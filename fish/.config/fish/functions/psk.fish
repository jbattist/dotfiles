# ~/.config/fish/functions/psk.fish
# Interactive process killer: type to fuzzy-search, TAB to select several,
# ENTER to pick, then confirm. Kills nothing without an explicit y.
#
#   psk              browse all processes (heaviest %cpu first)
#   psk chrome       start with only lines matching "chrome"
#   psk -9 chrome    send SIGKILL instead of SIGTERM
#
# The list is the same compact psaux layout, uncolored on purpose: fzf's
# own search highlighting applies, {1} in the preview stays a clean PID,
# and PID extraction for the kill is ANSI-free.

function psk --description "Interactive process killer (fzf); psk [pattern]"
    set -l sig TERM
    set -l pattern ""

    for arg in $argv
        switch $arg
            case -9
                set sig KILL
            case '*'
                set pattern "$pattern $arg"
        end
    end
    set pattern (string trim -- $pattern)

    set -l cols pid,user,%cpu,%mem,rss,stat,etime,args
    set -l ps_args -e -o $cols --sort=-%cpu

    # Feed: compact rows, header excluded so fzf's {1} is the PID
    set -l feed (command ps $ps_args | tail -n +2)
    if test -n "$pattern"
        set -l pat (string replace -r '^.' '[$0]' -- $pattern)
        set feed (printf '%s\n' $feed | rg -i -- "$pat")
    end
    if test -z "$feed"
        echo "No processes match: $pattern" >&2
        return 1
    end

    set -l picks (printf '%s\n' $feed | fzf --multi \
        --header 'TAB: select  ENTER: done  (kills only after confirm)' \
        --preview 'ps -ww -p {1} -o pid,user,%cpu,%mem,rss,stat,etime,args 2>/dev/null' \
        --preview-window=down:5)
    set -q picks[1]; or return 0

    echo
    printf '%s\n' $picks
    read -l -P "Are you sure (y/N) " ans
    if not string match -q -i 'y' -- "$ans"
        echo "Aborted - nothing was killed."
        return 1
    end

    set -l pids (printf '%s\n' $picks | awk '{print $1}')
    kill -s $sig $pids
    echo "Sent SIG$sig to: $pids"
end