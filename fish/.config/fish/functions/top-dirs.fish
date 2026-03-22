# ~/.config/fish/functions/top-dirs.fish
# Show the 10 largest directories anywhere under the current directory.

function top-dirs --description "Show the 10 largest directories under cwd"
    find . -type d -exec du -sh {} + 2>/dev/null | sort -rh | head -10
end
