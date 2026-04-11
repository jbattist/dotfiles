function fish_greeting
    if not status is-interactive
        return
    end

    if test "$TERM_PROGRAM" = "WezTerm"
        sleep 0.1
    end

    if command -q fastfetch
        fastfetch
    end
end