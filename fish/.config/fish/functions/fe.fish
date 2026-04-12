# fe - Find & Edit
# Fuzzy file finder with bat preview, opens in micro
# Drop in ~/.config/fish/functions/fe.fish
 
function fe --description "Find and edit files with fzf + bat preview"
    # Usage: fe [search_path] [--type/-t ext] [--hidden/-H] [--depth/-d N]
    argparse 't/type=' 'H/hidden' 'd/depth=' -- $argv; or return 1
 
    set -l search_path (test (count $argv) -gt 0; and echo $argv[1]; or echo ".")
 
    # — Build find command —
    set -l fd_cmd find $search_path -type f

 
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
 
    # — Run fzf with bat preview —
    set -l selection (
        $fd_cmd 2>/dev/null | fzf \
            --ansi \
            --layout=reverse \
            --border=rounded \
            --margin=1,2 \
            --padding=1 \
            --prompt="  " \
            --pointer="▶" \
            --marker="✓" \
            --header="  fe · enter=edit · ctrl-y=copy path · ctrl-o=open dir" \
            --header-first \
            --preview='bat --color=always --style=numbers,changes,header --line-range=:300 --theme=Nord {}' \
            --preview-window='right:55%:border-left:wrap' \
            --color="$pointer,$hl,$fg,$bg,$info,$border,$header,$prompt,$marker,$spinner" \
            --bind='ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' \
            --bind='ctrl-y:execute-silent(echo -n {+} | xclip -selection clipboard)+abort' \
            --bind='ctrl-o:execute(xdg-open (dirname {}) &>/dev/null &)+abort' \
            --multi \
            --height=80% \
    )
 
    # — Open in micro if a file was selected —
    if test -n "$selection"
        # Split multi-select into separate args
        set -l files (string split \n -- $selection)
        micro $files
    end
end