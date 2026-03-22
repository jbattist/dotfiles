# ~/.config/fish/functions/ff.fish
# Find files matching a pattern and print a compact, readable list.

function ff --description "Find files matching pattern (e.g. ff .pdf)"
    if test -z "$argv[1]"
        echo "Usage: ff <pattern>"
        return 1
    end

    set -l found 0

    while read -l file
        set found 1
        set -l dir (path dirname -- $file)
        set dir (string replace -r '^\.' '' $dir)
        test -z "$dir" && set dir "."

        set -l icon (eza --icons=always --no-filesize --no-permissions --no-time --no-user $file 2>/dev/null | sed 's/[[:space:]].*$//')
        set -l name (path basename -- $file)
        set_color cyan;  echo -n "$icon $name"
        set_color normal; echo -n "  "
        set_color brblack; echo $dir
        set_color normal
    end < (find . -type f -iname "*$argv[1]*" 2>/dev/null | psub)

    if test $found -eq 0
        echo "No files found for: $argv[1]"
        return 1
    end
end
