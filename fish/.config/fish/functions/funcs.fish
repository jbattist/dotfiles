# ~/.config/fish/functions/funcs.fish
# List all user-defined functions sourced from config.fish
function funcs --description "List my custom fish functions"
    for f in ~/.config/fish/functions/*.fish
        string replace -r '.*/(.+)\.fish$' '$1' -- $f
    end
end
