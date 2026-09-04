-- Hyprland 0.55+ Lua config.
-- Migrated from hyprland.conf on 2026-05-17 and aligned with the tracked niri config where Hyprland has equivalent behavior.
-- Reference: https://wiki.hypr.land/Configuring/Start/

-- niri home profile uses a single ultrawide on DP-1 at scale 1.
hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = 1 })

local terminal    = "ghostty"
local fileManager = "nemo"
local browser     = "firefox"
local launcher    = "vicinae toggle"
local mainMod     = "SUPER"

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("vicinae server")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QPA_PLATFORMTHEME_QT6", "kde")
hl.env("TERMINAL", terminal)

hl.config({
    general = {
        gaps_in = 10,
        gaps_out = 10,
        border_size = 3,
        col = { active_border = "rgb(7fc8ff)", inactive_border = "rgb(505050)" },
        resize_on_border = false,
        allow_tearing = false,
        layout = "master",
    },
    decoration = {
        rounding = 12,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = false, range = 30, render_power = 3, color = 0x77000000 },
        blur = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },
    animations = { enabled = true },
    misc = { force_default_wallpaper = -1, disable_hyprland_logo = true },
    dwindle = { preserve_split = true },
    master = {
        orientation = "center",
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = false,
        column_width = 0.5,
        direction = "right",
        follow_focus = true,
        explicit_column_widths = "0.3333, 0.5, 0.6",
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })
hl.curve("niriSpring",     { type = "spring", mass = 1, stiffness = 80, dampening = 17 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "niriSpring" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "niriSpring", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",     style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, spring = "niriSpring", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, spring = "niriSpring", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, spring = "niriSpring", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0.2,
        touchpad = { tap_to_click = true, natural_scroll = true },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

local function sh(cmd) return hl.dsp.exec_cmd(cmd) end
local function hypr_dispatch(cmd)
    return function() hl.exec_cmd("hyprctl dispatch " .. cmd) end
end

local columnSizeScript  = "/home/joe/.config/hypr/scripts/cycle-column-size.sh"
local fullscreenScript  = "/home/joe/.config/hypr/scripts/maximize-or-fullscreen.sh"

-- Launchers and session controls, mirrored from niri where practical.
hl.bind(mainMod .. " + T", sh(terminal), { description = "Open a Terminal: ghostty" })
hl.bind(mainMod .. " + SHIFT + T", sh(terminal .. " --title=floating-terminal --window-height=100 --window-width=100"), { description = "Open a Floating Terminal: ghostty" })
hl.bind(mainMod .. " + R", sh(launcher), { repeating = false, description = "Run an Application: vicinae" })
hl.bind(mainMod .. " + D", sh(fileManager), { description = "Run an Application: nemo" })
hl.bind(mainMod .. " + B", sh(browser), { description = "Run an Application: firefox" })
hl.bind("SUPER + ALT + L", sh("swaylock"), { description = "Lock the Screen: swaylock" })
hl.bind("SUPER + ALT + S", sh("pkill orca || exec orca"), { locked = true, description = "Toggle screen reader" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { repeating = false })
hl.bind(mainMod .. " + SHIFT + E", sh("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind("CTRL + ALT + Delete", sh("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.dpms("off"))

for _, item in ipairs({
    {"Left", "left"}, {"Right", "right"}, {"Up", "up"}, {"Down", "down"},
    {"H", "left"}, {"L", "right"}, {"K", "up"}, {"J", "down"},
}) do
    hl.bind(mainMod .. " + " .. item[1], hl.dsp.focus({ direction = item[2] }))
end

-- Scrolling-layout column/window movement approximating niri's column workflow.
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + apostrophe", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + CTRL + Right", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + CTRL + Left", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + CTRL + Up", hypr_dispatch("movewindow u"))
hl.bind(mainMod .. " + CTRL + Down", hypr_dispatch("movewindow d"))
hl.bind(mainMod .. " + CTRL + K", hypr_dispatch("movewindow u"))
hl.bind(mainMod .. " + CTRL + J", hypr_dispatch("movewindow d"))

for _, item in ipairs({
    {"Left", "l"}, {"Right", "r"}, {"Up", "u"}, {"Down", "d"},
    {"H", "l"}, {"L", "r"}, {"K", "u"}, {"J", "d"},
}) do
    hl.bind(mainMod .. " + SHIFT + " .. item[1], hypr_dispatch("focusmonitor " .. item[2]))
    hl.bind(mainMod .. " + SHIFT + CTRL + " .. item[1], hypr_dispatch("movewindow mon:" .. item[2]))
end

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + CTRL + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(mainMod .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + Page_Up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + U", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + Page_Down", hypr_dispatch("movetoworkspace e+1"))
hl.bind(mainMod .. " + CTRL + Page_Up", hypr_dispatch("movetoworkspace e-1"))
hl.bind(mainMod .. " + CTRL + U", hypr_dispatch("movetoworkspace e+1"))
hl.bind(mainMod .. " + CTRL + I", hypr_dispatch("movetoworkspace e-1"))

hl.bind(mainMod .. " + G", sh(columnSizeScript), { repeating = false, description = "Cycle niri preset column/window width" })
hl.bind(mainMod .. " + F", sh(fullscreenScript), { repeating = false, description = "Maximize scrolling column or fullscreen active window" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + CTRL + F", hl.dsp.layout("colresize 1"))
hl.bind(mainMod .. " + C", hypr_dispatch("centerwindow"))
hl.bind(mainMod .. " + Minus", hl.dsp.layout("colresize -0.1"))
hl.bind(mainMod .. " + Equal", hl.dsp.layout("colresize +0.1"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", hypr_dispatch("cyclenext floating"))
hl.bind(mainMod .. " + W", sh("current=$(hyprctl activeworkspace -j | jq -r .tiled_layout); case $current in dwindle) next=master;; master) next=scrolling;; *) next=dwindle;; esac; hyprctl eval \"hl.config({ general = { layout = \\\"$next\\\" } })\""), { repeating = false, description = "Cycle layout: dwindle/master/scrolling" })
hl.bind(mainMod .. " + comma", hl.dsp.layout("cyclenext"), { description = "Focus next master window" })
hl.bind(mainMod .. " + semicolon", hl.dsp.layout("cycleprev"), { description = "Focus previous master window" })
hl.bind(mainMod .. " + Return", hl.dsp.layout("swapwithmaster master"), { description = "Swap active window with master" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.group.toggle())
hl.bind(mainMod .. " + BracketLeft", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + BracketRight", hl.dsp.layout("colresize +conf"))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + mouse_down", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + mouse_up", hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + mouse_right", hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + mouse_left", hl.dsp.layout("move +col"))

hl.bind("Print", sh("flameshot gui --clipboard"))
hl.bind("CTRL + Print", sh("flameshot screen --path ~/Pictures/Screenshots"))
hl.bind("SHIFT + Print", sh("flameshot gui --clipboard"))

hl.bind("XF86AudioRaiseVolume", sh("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", sh("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", sh("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", sh("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", sh("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioStop", sh("playerctl stop"), { locked = true })
hl.bind("XF86AudioPrev", sh("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", sh("playerctl next"), { locked = true })
hl.bind("XF86MonBrightnessUp", sh("brightnessctl --class=backlight set +10%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", sh("brightnessctl --class=backlight set 10%-"), { locked = true, repeating = true })
hl.bind("XF86Tools", sh("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), { locked = true, repeating = true })
hl.bind("XF86Launch5", sh("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86Calculator", sh("gnome-calculator"))
hl.bind(mainMod .. " + S", sh("$TERMINAL -e fish -c fe"))

-- Noctalia colors override base borders/groups.
require("noctalia.noctalia-colors")

hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({ name = "move-hyprland-run", match = { class = "hyprland-run" }, move = "20 monitor_h-120", float = true })
hl.window_rule({ name = "wezterm-third-width", match = { class = "wezterm" }, scrolling_width = 0.333 })
hl.window_rule({ name = "firefox-pip-floating", match = { class = "firefox$", title = "^Picture-in-Picture$" }, float = true })
hl.window_rule({
    name = "floating-terminal",
    match = { class = "com.mitchellh.ghostty", title = "floating-terminal" },
    float = true,
    size = "840 800",
    center = true,
    scrolling_width = 0.3333,
})
hl.window_rule({ name = "pavucontrol-floating", match = { class = "pavucontrol$" }, float = true })
hl.window_rule({ name = "calculator-floating", match = { class = "org.gnome.Calculator$" }, float = true })
hl.window_rule({ name = "ghostty-home-width", match = { class = "com.mitchellh.ghostty" }, scrolling_width = 0.3333 })


