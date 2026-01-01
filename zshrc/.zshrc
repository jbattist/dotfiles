eval "$(starship init zsh)"

HISTFILE=~/.history
HISTSIZE=999
SAVEHIST=1000
setopt share_history
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_verify


export FZF_DEFAULT_OPTS='--height 60% --tmux center,80% --layout reverse --border top'

bindkey "^[[F" end-of-line
bindkey "^[[H" beginning-of-line
bindkey "^[[3~" delete-char

# Binds to use for zsh-autosuggestions
bindkey '\t'   complete-word       # tab          | complete
bindkey '^[[Z' autosuggest-accept  # shift + tab  | autosuggest

fastfetch

source ~/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source ~/.config/zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh

source <(fzf --zsh)

# Use eza instead of ls and get icons
alias ls="eza --icons=always"

# Partial directory name cd with zoxide
eval "$(zoxide init zsh)"
alias cd="z"