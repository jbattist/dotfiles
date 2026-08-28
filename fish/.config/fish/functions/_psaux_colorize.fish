# ~/.config/fish/functions/_psaux_colorize.fish
# Shared by psaux and psk. Fields: pid user %cpu %mem rss stat etime args
# (args = rest of line). Field offsets are located in the original line,
# so every inter-column gap (and ps's truncation) is preserved
# byte-for-byte; only color codes are inserted. Zero width drift.

function _psaux_colorize
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