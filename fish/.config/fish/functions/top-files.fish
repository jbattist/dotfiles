# ~/.config/fish/functions/top-files.fish
# Show the 10 largest files anywhere under the current directory.

function top-files --description "Show the 10 largest files under cwd"
    find . -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10
end
