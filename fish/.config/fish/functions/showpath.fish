# ~/.config/fish/functions/path.fish
# Pretty print PATH with one entry per line.
# Note: `path` is also a fish built-in subcommand (fish 3.5+).
# Rename to `showpath` if you hit conflicts.

function showpath --description "Pretty print PATH, one entry per line"
    echo $PATH | tr " " "\n"
    # Fish stores PATH as a list (space-separated internally),
    # so the above works. Alternatively: printf '%s\n' $PATH
end
