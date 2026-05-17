-- Noctalia colors for Hyprland 0.55+ Lua config.
-- Converted from noctalia-colors.conf.

local primary     = "rgb(bac3ff)"
local surface     = "rgb(131318)"
local secondary   = "rgb(c1c4e6)"
local error_color = "rgb(ffb4ab)"

hl.config({
    general = {
        col = {
            active_border   = primary,
            inactive_border = surface,
        },
    },

    group = {
        col = {
            border_active          = secondary,
            border_inactive        = surface,
            border_locked_active   = error_color,
            border_locked_inactive = surface,
        },

        groupbar = {
            col = {
                active          = secondary,
                inactive        = surface,
                locked_active   = error_color,
                locked_inactive = surface,
            },
        },
    },
})
