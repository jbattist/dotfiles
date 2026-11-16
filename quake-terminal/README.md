# quake-terminal

A drop-down Ghostty terminal for Umbriel. Press `Mod+Grave` (Super + the backtick key) and it slides down from the top of the screen. Press it again and it slides back up.

It uses Umbriel's own features and runs no extra process:

| Piece | Umbriel feature |
|---|---|
| Hotkey toggle | `scratchpad-toggle quake` (named scratchpad) |
| Launch on first use | `[[scratchpad]] spawn_when_empty` |
| Relaunch after `exit` | `hide_when_empty = true` |
| Full-width top placement | `[[window_rule]]` with `default_floating_size` and `default_position` anchored `top` |
| Slide animation | Custom GLSL `kind = "animation"` preset on `[animation.scratchpad]` |

The drawer opens on the monitor under the pointer. If it's open on another monitor, the hotkey moves it to the current one.

## Install

Add `quake.toml` to the optional includes in `~/.config/umbriel/config.toml`. Put it last so its settings override the theme:

```toml
[include.optional]
files = ["noctalia.toml", "themes/base.toml", "theme.toml",
         "~/projects/quake-terminal/quake.toml"]
```

Umbriel hot-reloads the config. Then check it:

```sh
umbriel config validate
journalctl --user -u umbriel -n 50 | grep -iE 'ignoring keybind|quake|effect'
```

## Notes and side effects

- **Default scratchpad renamed.** Once you define a named scratchpad, Umbriel removes the implicit `default` one. This file adds a `main` scratchpad and points your `Mod+Space`, `Mod+Shift+Space` and `Mod+Ctrl+Space` bindings at it.
- **Scratchpad animation applies to every scratchpad.** Your `themes/base.toml` turns it off. This file turns it on and sets the slide effect, so the `main` scratchpad slides from the top too.
- **Hotkey:** edit the `"Mod+Grave"` line. `F12` and `Ctrl+Grave` are common choices.
- **Size:** `default_floating_size.height` (0.45 = 45% of the usable area). It only applies when the window is created, so run `exit` in the drawer to resize it.
- **Grammar:** the keybinds use the newer word grammar (`scratchpad-toggle quake`). A machine running a build older than that refactor needs `scratchpad-toggle:quake`.
