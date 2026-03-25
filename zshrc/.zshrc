# Keep Starship palette in sync with Noctalia active colors
# (fast + idempotent; updates dotfiles starship.toml when Noctalia colors change)

HISTFILE=~/.history
HISTSIZE=999
SAVEHIST=1000
setopt share_history
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_verify

# Environment Variables #######################################################
export FZF_DEFAULT_OPTS='--height 60% --layout reverse --border top'
export EDITOR='micro'
export VISUAL='micro'
export PAGER='bat --style=header,grid'
export MANPAGER='bat --language=man --style=header,grid'
export BAT_STYLE='header,grid'

if [[ "$TERM" == 'xterm-ghostty' ]] && ! infocmp xterm-ghostty >/dev/null 2>&1; then
    export TERM='xterm-256color'
fi

# Keybinds ####################################################################
bindkey "^[[F" end-of-line
bindkey "^[[H" beginning-of-line
bindkey "^[[3~" delete-char

# Binds to use for zsh-autosuggestions
bindkey '\t'   complete-word       # tab          | complete
bindkey '^[[Z' autosuggest-accept  # shift + tab  | autosuggest

# Functions ###################################################################

# List all functions defined in this .zshrc
funcs() {
  awk 'match($0,/^[[:space:]]*([[:alnum:]_-]+)[[:space:]]*\(\)/,m){print m[1]}' ~/.zshrc
}

# ff .pdf    → finds all PDFs anywhere below current dir
ff() {
    # Find files matching the search term and print a compact, readable list.
    [[ -z "$1" ]] && {
        echo "Usage: ff <pattern>"
        return 1
    }

    local file dir icon found=0
    while IFS= read -r file; do
        found=1
        dir=${file:h}
        dir=${dir#./}
        [[ -z "$dir" || "$dir" == "$file" ]] && dir="."

        icon=$(eza --icons=always --no-filesize --no-permissions --no-time --no-user "$file" 2>/dev/null | sed 's/[[:space:]].*$//')
        print -P "${icon} %F{6}${file:t}%f  %F{8}${dir}%f"
    done < <(find . -type f -iname "*$1*" 2>/dev/null)

    (( found )) || {
        echo "No files found for: $1"
        return 1
    }
}


# Pretty print PATH with one entry per line
path() {
    echo "$PATH" | tr ":" "\n"
}

# List open ports
ports() {
    sudo lsof -iTCP -sTCP:LISTEN -P -n
}

# Show the 10 largest files anywhere under the current directory.
top-files() {
    find . -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10
}

# Show the 10 largest directories anywhere under the current directory.
top-dirs() {
    find . -type d -exec du -sh {} + 2>/dev/null | sort -rh | head -10
}

# Kill all suspended jobs in the current shell.
kill-jobs() {
    local job
    for job in ${(k)jobstates}; do
        [[ ${jobstates[$job]} == suspended* ]] && kill -9 %$job
    done
}

# Pick a command from fzf and run it.
cmds() {
    # Pick a command from fzf and run it.
    local cmd
    cmd=$(
        (
            print -l ${(ok)aliases}
            print -l ${(ok)functions}
            print -l ${(ok)builtins}
            print -l ${(ok)commands}
        ) | sort -u | fzf
    ) || return
    print -z "$cmd"
}


# Sources #####################################################################

if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

source <(fzf --zsh)

# Aliases #####################################################################
# Use eza instead of ls and get icons
alias ls="eza --icons=always"

# Partial directory name cd with zoxide
alias cd="z"

#fix SSH bullshit
alias ssh-pi='TERM=xterm-256color ssh'

# Paths #######################################################################
# filen-cli
PATH=$PATH:~/.filen-cli/bin
export PATH="$HOME/.npm-global/bin:$PATH"

# Inits #######################################################################
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
fastfetch