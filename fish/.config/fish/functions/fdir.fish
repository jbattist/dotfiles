# ~/.config/fish/functions/fdir.fish
# Find folders matching a pattern and print a compact, readable list.

function fdir --description "Find folders matching pattern (e.g. fdir config)"
    if test -z "$argv[1]"
        echo "Usage: fdir <pattern>"
        return 1
    end

    set -l found 0

    while read -l dir
        set found 1
        set -l parent (path dirname -- $dir)
        set parent (string replace -r '^\.' '' $parent)
        test -z "$parent" && set parent "."

        set -l icon (eza --icons=always --only-dirs --no-filesize --no-permissions --no-time --no-user $dir 2>/dev/null | sed 's/[[:space:]].*$//')
        set -l name (path basename -- $dir)
        set_color yellow;   echo -n "$icon $name"
        set_color normal;   echo -n "  "
        set_color brblack;  echo $parent
        set_color normal
    end < (find . -type d -iname "*$argv[1]*" 2>/dev/null | psub)

    if test $found -eq 0
        echo "No folders found for: $argv[1]"
        return 1
    end
end
