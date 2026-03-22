# ~/.config/fish/config.fish

# Keep Starship palette in sync with Noctalia active colors
~/.config/update-noctalia-starship.py >/dev/null 2>&1; or true


# History #####################################################################
# Fish handles history deduplication and sharing natively.
# These are the closest equivalents to your zsh history options:
set -g fish_history_max_commands 1000   # analogous to SAVEHIST


# Environment Variables #######################################################
set -gx FZF_DEFAULT_OPTS '--height 60% --tmux center,80% --layout reverse --border top'


# Key Bindings ################################################################
# Fish uses `bind` instead of zsh's `bindkey`.
# Syntax/autosuggestions are built into fish — no plugins needed.
bind \e\[F end-of-line           # End key
bind \e\[H beginning-of-line     # Home key
bind \e\[3~ delete-char          # Delete key
bind \t  complete               # Tab → complete
bind \e\[Z accept-autosuggestion # Shift+Tab → accept autosuggestion


# Paths #######################################################################
fish_add_path ~/.filen-cli/bin
fish_add_path ~/.npm-global/bin


# Aliases #####################################################################
alias ls  "eza --icons=always"
alias cd  "z"
alias ssh-pi "env TERM=xterm-256color ssh"


# Sources / Inits #############################################################

# fzf key bindings + completions
fzf --fish | source

# Starship prompt
starship init fish | source

# zoxide (replaces cd)
zoxide init fish | source

# NVM
# fish-nvm (https://github.com/jorgebucaran/nvm.fish) is the native alternative.
# If you still want the bash nvm, install `bass` (https://github.com/edc/bass) and uncomment:
# bass source ~/.nvm/nvm.sh

# Fastfetch on new shell
fastfetch
