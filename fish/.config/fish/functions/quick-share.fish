function quick-share --description "Temporarily serve a directory over HTTP on the home LAN"
    set -l port 8000
    set -l directory $PWD
    set -l lan_cidr 192.168.1.0/24
    set -l opened_firewall 0

    if test (count $argv) -ge 1
        set port $argv[1]
    end

    if test (count $argv) -ge 2
        set directory $argv[2]
    end

    if test (count $argv) -gt 2
        echo "Usage: quick-share [port] [directory]" >&2
        return 2
    end

    if not string match -qr '^[0-9]+$' -- $port
        echo "quick-share: port must be numeric" >&2
        return 2
    end

    if test $port -lt 1; or test $port -gt 65535
        echo "quick-share: port must be between 1 and 65535" >&2
        return 2
    end

    if not test -d $directory
        echo "quick-share: directory does not exist: $directory" >&2
        return 2
    end

    if not command -q ufw
        echo "quick-share: ufw is required for temporary firewall access" >&2
        return 1
    end

    set directory (realpath $directory)
    set -l share_url "http://axis.home:$port/"

    echo "Authorizing temporary firewall access from $lan_cidr to TCP port $port..."
    if not sudo -v
        echo "quick-share: sudo authentication failed" >&2
        return 1
    end

    set -l ufw_status (sudo ufw status)
    if string match -rq "^$port/tcp[[:space:]]+ALLOW[[:space:]]+IN[[:space:]]+$lan_cidr" -- $ufw_status
        echo "An equivalent UFW rule already exists; it will be left unchanged."
    else
        if not sudo ufw allow from $lan_cidr to any port $port proto tcp comment quick-share-temporary
            echo "quick-share: failed to open TCP port $port" >&2
            return 1
        end
        set opened_firewall 1
    end

    echo
    echo "============================================================"
    echo " QUICK SHARE"
    echo "============================================================"
    echo " Directory: $directory"
    echo " URL:       $share_url"
    echo " Firewall:  TCP $port open temporarily to $lan_cidr"
    echo
    echo " Download/list with:"
    echo "   curl $share_url"
    echo
    echo " Download a file:"
    echo "   curl -O '$share_url<filename>'"
    echo
    echo " Directory contents:"
    command ls -lah -- $directory
    echo "============================================================"
    echo " Stop sharing with Ctrl+C"
    echo

    command python3 -m http.server $port --bind 0.0.0.0 --directory $directory
    set -l server_status $status

    if test $opened_firewall -eq 1
        echo
        echo "Removing temporary firewall rule for TCP port $port..."
        if not sudo ufw --force delete allow from $lan_cidr to any port $port proto tcp
            echo "WARNING: Failed to remove the temporary UFW rule." >&2
            echo "Remove it manually with:" >&2
            echo "  sudo ufw delete allow from $lan_cidr to any port $port proto tcp" >&2
            return 1
        end
    end

    return $server_status
end
