# ~/.config/fish/functions/cmds.fish
# Pick a command from fzf and drop it on the command line.

function cmds --description "Pick a command via fzf and put it on the prompt"
    set -l cmd (
        begin
            functions --names
            builtin --names
            string split ' ' -- (string join ' ' $PATH) | while read -l p
                test -d $p && ls $p 2>/dev/null
            end
        end | sort -u | fzf
    )
    test -n "$cmd" && commandline -- $cmd
end
