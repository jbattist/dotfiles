# ~/.config/fish/functions/kill-jobs.fish
# Kill all suspended (stopped) jobs in the current shell.

function kill-jobs --description "Kill all suspended background jobs"
    for job in (jobs | grep -oP '^\[\K[0-9]+')
        kill -9 %$job
    end
end
