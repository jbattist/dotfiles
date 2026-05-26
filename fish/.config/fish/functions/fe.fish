# fe - Find & Edit
# Fuzzy file/content finder with fzf + ripgrep + bat preview, opens in micro
# Drop in ~/.config/fish/functions/fe.fish

function fe --description "Find and edit files or content with fzf + rg + bat preview"
    # Usage:
    #   fe                         # fuzzy-open files under .
    #   fe ~/.config               # fuzzy-open files under ~/.config
    #   fe kanagawa                # live ripgrep content search for "kanagawa" under .
    #   fe ~/.config kanagawa      # live ripgrep content search under ~/.config
    #   fe -c                      # start blank live content search
    #   fe -f kanagawa             # force filename search with initial query
    #   fe -t toml ~/.config       # limit to extension
    argparse 'c/content' 'f/files' 't/type=' 'H/hidden' 'd/depth=' 'h/help' -- $argv; or return 1

    if set -q _flag_help
        echo "Usage: fe [path] [query]"
        echo "  fe                         fuzzy-open files under ."
        echo "  fe ~/.config               fuzzy-open files under ~/.config"
        echo "  fe kanagawa                search file contents for 'kanagawa' under ."
        echo "  fe ~/.config kanagawa      search file contents for 'kanagawa' under ~/.config"
        echo "  fe -c                      blank live content search"
        echo "  fe -f kanagawa             force filename fuzzy search"
        echo "Options: -c/--content, -f/--files, -t/--type EXT, -H/--hidden, -d/--depth N"
        return 0
    end

    set -l search_path "."
    set -l query_parts

    if test (count $argv) -gt 0
        if test -e $argv[1]
            set search_path $argv[1]
            if test (count $argv) -gt 1
                set query_parts $argv[2..-1]
            end
        else
            set query_parts $argv
        end
    end

    set -l initial_query (string join " " -- $query_parts)

    # Default heuristic: if you pass a non-path argument, you probably want content search.
    set -l mode files
    if set -q _flag_content
        set mode content
    else if test -n "$initial_query"; and not set -q _flag_files
        set mode content
    end

    # Include hidden files by default because dotfiles are usually what Joe is hunting.
    # Keep noisy/generated directories out of both file and content search.
    set -l common_args --hidden --glob '!.git/**' --glob '!node_modules/**' --glob '!target/**' --glob '!dist/**' --glob '!build/**' --glob '!__pycache__/**' --glob '!.venv/**' --glob '!venv/**'

    if set -q _flag_type
        set common_args $common_args --glob "*.$_flag_type"
    end

    if set -q _flag_depth
        set common_args $common_args --max-depth $_flag_depth
    end

    # — Theme: Nord-inspired colors —
    set -l pointer "pointer:#81a1c1"
    set -l hl "hl:#ebcb8b,hl+:#ebcb8b:bold"
    set -l fg "fg:#d8dee9,fg+:#eceff4:bold"
    set -l bg "bg+:#3b4252"
    set -l info "info:#8fbcbb"
    set -l border "border:#4c566a"
    set -l header "header:#616e88"
    set -l prompt "prompt:#88c0d0:bold"
    set -l marker "marker:#a3be8c"
    set -l spinner "spinner:#b48ead"

    set -l escaped_path (string escape -- $search_path)

    if test "$mode" = files
        set -l selection (
            rg --files $common_args -- $search_path 2>/dev/null | fzf \
                --ansi \
                --exact \
                --layout=reverse \
                --border=rounded \
                --margin=1,2 \
                --padding=1 \
                --query="$initial_query" \
                --prompt="files > " \
                --pointer="▶" \
                --marker="✓" \
                --header="  fe files · enter=edit · ctrl-r=content mode · ctrl-y=copy path · ctrl-o=open dir" \
                --header-first \
                --preview='bat --color=always --style=numbers,changes,header --line-range=:300 {}' \
                --preview-window='right:55%:border-left:wrap' \
                --color="$pointer,$hl,$fg,$bg,$info,$border,$header,$prompt,$marker,$spinner" \
                --bind='ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' \
                --bind='ctrl-y:execute-silent(command -q wl-copy; and echo -n {+} | wl-copy; or echo -n {+} | xclip -selection clipboard)+abort' \
                --bind='ctrl-o:execute(xdg-open (dirname {}) &>/dev/null &)+abort' \
                --bind="ctrl-r:become(fe --content $escaped_path {q})" \
                --multi \
                --height=80%
        )

        if test -n "$selection"
            set -l files (string split \n -- $selection)
            micro $files
        end

        return
    end

    set -l rg_args (string escape -- $common_args)
    set -l reload_cmd "test -n {q}; and rg --line-number --column --smart-case --color=always $rg_args -- {q} $escaped_path 2>/dev/null; or true"

    set -l selection (
        fzf \
            --ansi \
            --disabled \
            --layout=reverse \
            --border=rounded \
            --margin=1,2 \
            --padding=1 \
            --query="$initial_query" \
            --prompt="rg > " \
            --pointer="▶" \
            --marker="✓" \
            --header="  fe content · type to ripgrep · enter=edit at line · ctrl-f=file mode · ctrl-y=copy line" \
            --header-first \
            --delimiter=':' \
            --preview='bat --color=always --style=numbers,changes,header --highlight-line {2} {1}' \
            --preview-window='right:55%:border-left:wrap,+{2}/2' \
            --color="$pointer,$hl,$fg,$bg,$info,$border,$header,$prompt,$marker,$spinner" \
            --bind="start:reload:$reload_cmd" \
            --bind="change:reload:$reload_cmd" \
            --bind='ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' \
            --bind='ctrl-y:execute-silent(command -q wl-copy; and echo -n {} | wl-copy; or echo -n {} | xclip -selection clipboard)+abort' \
            --bind="ctrl-f:become(fe --files $escaped_path {q})" \
            --height=80%
    )

    if test -n "$selection"
        # Strip ANSI, then parse rg's file:line:column:match format.
        set -l clean (string replace -ra '\e\[[0-9;]*m' '' -- $selection)
        set -l file (string split -m1 ':' -- $clean)[1]
        set -l rest (string split -m1 ':' -- $clean)[2]
        set -l line (string split -m1 ':' -- $rest)[1]

        if test -n "$file"; and test -n "$line"
            micro +$line $file
        end
    end
end
