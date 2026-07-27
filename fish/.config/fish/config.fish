# ~/.config/fish/config.fish

#~/.config/update-noctalia-starship.py >/dev/null 2>&1; or true

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
alias ssh-pi "env TERM=xterm-256color ssh"
alias serve "python -m http.server"
alias psaux "ps auxw -e -H"
alias hermes-tui "ssh -t hermes.home 'hermes --tui'"

# Sources / Inits #############################################################

#eval "$(/opt/homebrew/bin/brew shellenv)"

# fzf key bindings + completions
fzf --fish | source

# Starship prompt
starship init fish | source

# zoxide (replaces cd — uses builtin cd internally, no alias loop)
zoxide init fish --cmd cd | source

thefuck --alias | source

# Colorify everything with grc when installed
# Arch's grc package provides /etc/grc.fish; machines without grc should not error.
if test -f /etc/grc.fish
    source /etc/grc.fish
end
# Overrides — must come AFTER source /etc/grc.fish so these functions win
function ping --wraps=ping --description "ping with -c 5 + optional grc colors"
    if isatty 1; and command -q grc
        grc ping -c 5 $argv
    else
        command ping -c 5 $argv
    end
end

function ls --wraps=ls --description "eza with icons instead of grc ls"
    eza --icons=always $argv
end

