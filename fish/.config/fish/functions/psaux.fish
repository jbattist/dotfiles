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

function _psaux_colorize
    # Fields: pid user %cpu %mem rss stat etime args (args = rest of line).
    # Field offsets are located in the original line, so every inter-column
    # gap (and ps's truncation) is preserved byte-for-byte; only color codes
    # are inserted. Zero width drift at any terminal size.
    awk '
        BEGIN {
            rst="\033[0m"; dim="\033[2m"
            hdr="\033[1;36m"; pidc="\033[1;33m"
            usrc="\033[32m"; root="\033[1;31m"
            heat="\033[91m"; warn="\033[33m"
            rssc="\033[95m"; statc="\033[36m"; zomb="\033[1;31m"
        }
        NR==1 { printf "%s%s%s\n", hdr, $0, rst; next }
        {
            line=$0; cur=1
            for (i=1; i<=7; i++) {
                while (substr(line,cur,1)==" ") cur++
                s[i]=cur
                while (substr(line,cur,1)!=" " && cur<=length(line)) cur++
                e[i]=cur-1
            }
            pid =substr(line,s[1],e[1]-s[1]+1)
            g0  =substr(line,1,s[1]-1)
            user=substr(line,s[2],e[2]-s[2]+1)
            cpu =substr(line,s[3],e[3]-s[3]+1)
            mem =substr(line,s[4],e[4]-s[4]+1)
            rss =substr(line,s[5],e[5]-s[5]+1)
            st  =substr(line,s[6],e[6]-s[6]+1)
            et  =substr(line,s[7],e[7]-s[7]+1)
            args=substr(line,e[7]+1)
            g1=substr(line,e[1]+1,s[2]-e[1]-1); g2=substr(line,e[2]+1,s[3]-e[2]-1)
            g3=substr(line,e[3]+1,s[4]-e[3]-1); g4=substr(line,e[4]+1,s[5]-e[4]-1)
            g5=substr(line,e[5]+1,s[6]-e[5]-1); g6=substr(line,e[6]+1,s[7]-e[6]-1)
            uc = (user=="root") ? root : usrc
            cc = (cpu+0>=50) ? heat : (cpu+0>=10 ? warn : "")
            mc = (mem+0>=30) ? heat : (mem+0>=10 ? warn : "")
            sc = (st ~ /Z/) ? zomb : statc
            printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n", \
                   g0, pidc, pid, rst, g1, uc, user, rst, g2, cc, cpu, rst, g3, \
                   mc, mem, rst, g4, rssc, rss, rst, g5, sc, st, rst, g6, \
                   dim, et, rst, args
        }
    '
end