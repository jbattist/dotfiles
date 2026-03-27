# Color palette definitions
# Define ANSI color names with hex values per host

# Default palette (local machine)
function palette_default
    set -gx PALETTE_GREEN "green"
    set -gx PALETTE_YELLOW "yellow"
    set -gx PALETTE_BLUE "blue"
    set -gx PALETTE_MAGENTA "magenta"
end

# Production servers (red theme)
function palette_red
    set -gx PALETTE_GREEN "#f7768e"
    set -gx PALETTE_YELLOW "#ffb4ab"
    set -gx PALETTE_BLUE "#ffb4ab"
    set -gx PALETTE_MAGENTA "#ff6666"
end

# Development servers (cyan theme)
function palette_cyan
    set -gx PALETTE_GREEN "#7dcfff"
    set -gx PALETTE_YELLOW "#a9e5ff"
    set -gx PALETTE_BLUE "#a9e5ff"
    set -gx PALETTE_MAGENTA "#bb9af7"
end

# Detect environment and load palette
function load_palette
    # Check if we're in an SSH session
    if set -q SSH_CLIENT
        # SSH session: use host-specific palette
        switch (hostname)
            case "*prod*" "*production*"
                palette_red
            case "*dev*" "*development*"
                palette_cyan
            case "*"
                palette_default
        end
    else
        # Local machine: use default palette
        palette_default
    end
end

# Load palette on shell init
load_palette
