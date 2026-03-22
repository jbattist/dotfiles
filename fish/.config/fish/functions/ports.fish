# ~/.config/fish/functions/ports.fish
# List open TCP listening ports.

function ports --description "List open TCP listening ports"
    sudo lsof -iTCP -sTCP:LISTEN -P -n
end
