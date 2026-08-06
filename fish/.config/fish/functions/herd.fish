function herd --description "Attach to the persistent Herdr command center on heimdallama"
    set -l target (set -q HERDR_HOST; and echo $HERDR_HOST; or echo heimdallama.home)
    set -l session (set -q HERDR_SESSION; and echo $HERDR_SESSION; or echo command-center)

    # On the host itself, attach directly to the named local session.
    if test (string split -m1 . (uname -n 2>/dev/null))[1] = heimdallama
        command herdr session attach $session
        return $status
    end

    # Native remote attach preserves local keybindings and clipboard bridging.
    if command -q herdr
        command herdr --remote $target --session $session
        return $status
    end

    # Thin clients only need SSH; Herdr runs entirely on heimdallama.
    command ssh -t $target "\$HOME/.local/bin/herdr session attach $session"
end
