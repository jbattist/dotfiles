# ~/.config/fish/config.fish

~/.config/update-noctalia-starship.py >/dev/null 2>&1; or true

# History #####################################################################
# Fish handles history deduplication and sharing natively.
# These are the closest equivalents to your zsh history options:
set -g fish_history_max_commands 1000   # analogous to SAVEHIST
set -g fish_greeting

# Environment Variables #######################################################
set -gx FZF_DEFAULT_OPTS '--height 60% --layout reverse --border top'
set -gx EDITOR micro
set -gx VISUAL micro
set -gx PAGER 'bat --style=header,grid'
set -gx MANPAGER 'bat --language=man --style=header,grid'
set -gx BAT_STYLE header,grid

if test "$TERM" = xterm-ghostty
	if not infocmp xterm-ghostty >/dev/null 2>&1
		set -gx TERM xterm-256color
	end
end


# Key Bindings ################################################################
# Fish uses `bind` instead of zsh's `bindkey`.
# Syntax/autosuggestions are built into fish — no plugins needed.
bind \e\[F end-of-line           # End key
bind \e\[H beginning-of-line     # Home key
bind \e\[3~ delete-char          # Delete key
bind \t  complete               # Tab → complete
bind \e\[Z accept-autosuggestion # Shift+Tab → accept autosuggestion


# Paths #######################################################################
fish_add_path ~/.local/bin
fish_add_path ~/.filen-cli/bin
fish_add_path ~/.npm-global/bin


# Aliases #####################################################################
alias ls  "eza --icons=always"
alias ssh-pi "env TERM=xterm-256color ssh"


# Sources / Inits #############################################################

# fzf key bindings + completions
fzf --fish | source

# Starship prompt
starship init fish | source

# zoxide (replaces cd — uses builtin cd internally, no alias loop)
zoxide init fish --cmd cd | source

# NVM
# fish-nvm (https://github.com/jorgebucaran/nvm.fish) is the native alternative.
# If you still want the bash nvm, install `bass` (https://github.com/edc/bass) and uncomment:
# bass source ~/.nvm/nvm.sh

