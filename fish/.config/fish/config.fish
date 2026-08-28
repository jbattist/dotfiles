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
alias serve "python -m http.server"
# psaux is now a function: fish/.config/fish/functions/psaux.fish
alias hermes-tui "ssh -t hermes.home 'hermes --tui'"
alias tree "eza --tree --icons"

# Sources / Inits #############################################################

#eval "$(/opt/homebrew/bin/brew shellenv)"

# fzf key bindings + completions. Newer fzf provides `--fish`; Ubuntu's
# older package ships a Fish key-bindings file instead.
if command -q fzf
    if fzf --fish >/dev/null 2>&1
        fzf --fish | source
    else if test -r /usr/share/doc/fzf/examples/key-bindings.fish
        source /usr/share/doc/fzf/examples/key-bindings.fish
    end
end

# Starship prompt
if command -q starship
    starship init fish | source
end

# zoxide (replaces cd — uses builtin cd internally, no alias loop)
if command -q zoxide
    zoxide init fish --cmd cd | source
end

if command -q thefuck
    thefuck --alias | source
end

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
    eza --icons=always --group-directories-first --mounts $argv
end


fish_add_path -gm /home/joe/go/bin
