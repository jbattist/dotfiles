# Umbriel theme packs

A **pack** is a directory here containing a full look: `theme.toml`
(chrome/animation/fonts + which effect presets to load) plus `effects/<name>/`
(self-contained GLSL presets: `effect.toml` declares the preset, `shader.glsl`
implements it; shader paths resolve relative to the declaring TOML).

This is the closest thing Umbriel has to a plugin system: presets are pure
data + GLSL, loaded through normal includes, defined once, selected per slot
(`border`/`window`/`screen`/`cursor` + animation `effect` keys). Upstream ships
its own presets exactly this way under `/usr/share/umbriel/effects/` — we
include or imitate them.

## Using a pack

```fish
cp themes/pixel/theme.toml theme.toml      # enable (hot-reloads; theme.toml is gitignored)
rm theme.toml                               # back to themes/base.toml values
umbriel config validate                     # must stay clean
umbriel effects                             # per-preset COMPILED/ACTIVE/INERT state
```

`theme.toml` overrides `base.toml` (both live in `[include.optional]`, later
list entry wins) but does NOT redefine values it omits — base carries through.
So a pack can ship only the deltas it wants.

## Live toggling (the part that beats "copy a file")

Presets that are *included* but unselected cost nothing. `umbriel msg` flips
them at runtime — instant, no reload, great for evaluating a look:

```fish
umbriel msg effect-window-set downres        # pixelate focused content everywhere
umbriel msg effect-border-set neon
umbriel msg effect-screen-set vignette
umbriel msg effect-cursor-set trail
umbriel msg effect-window-toggle             # suppress current window's slot
umbriel msg effect-window-reset              # back to config values
```

Runtime selections persist until reset/reload. Example keybinds (uncomment in
keybinds.toml — Mod+P/O/N/M are unused as of 2026-11-04):

```toml
[[keybind]]
bind = "Mod+P"
action = "effect-window-set downres"

[[keybind]]
bind = "Mod+Shift+P"
action = "effect-window-reset"
```

## Perf note before enabling broadly

- **Window effects**: one shader pass per window per frame — fine on modern GPUs,
  scales with visible windows.
- **Screen & cursor effects**: full-output passes that **disable direct scanout**
  on that output. Bad idea while watching Jellyfin/video on that monitor; a
  video-only `border_effect = "off"` / `window_effect` rule is not enough — the
  screen slot is per-output (`[output."NAME"] screen_effect = "off"`).
- Border `light` adds a second pass + blur pyramid on top of the ring.

## Fonts

Only the title/tab-bar fonts live in Umbriel (`[appearance.title_bar].font`,
`[appearance.tab_bar].font`, Pango descriptions). Bar/OSD fonts come from
Noctalia (`font_family` in noctalia's own config), and everything inside
windows from each app/GTK. So a pack covers chrome fonts; the desktop-wide
font swap is a second, per-component step (GTK + ghostty/kitty/starship each
have their own config).

## Packs here

- `pixel/` — square chrome, stepped entrance (`stepin`), blocky content
  (`downres`, fixed 3-logical-pixel blocks; tune the `block` constant in the
  shader), bundled scanlines/reveal available.
- `cyberpunk/` — 3px hot ring via `neon` (palette-cycling + glow light),
  bundled pulse/audio/scanlines/vignette/trail included, JetBrains Mono chrome.
- `../omarchy.toml` — single-file theme (no effects), kept as the flat example.

## Authoring a new pack

1. `mkdir themes/mything && cd themes/mything`
2. Copy an existing `theme.toml`, keep the `[include]` lines for the presets
   you want (absolute `/usr/share/...` for bundled, `themes/<pack>/...` for
   custom; the custom one must point at a directory you create).
3. For a custom effect: `effects/<name>/effect.toml` with
   `[effects.preset.<name>] kind=... shader="shader.glsl"`, then GLSL ES 1.00
   fragment code — no `#version`, no `main`, no precision qualifiers. Entry
   point per kind: `vec4 animation|border|window|screen|cursor(vec2 uv)`;
   uniforms (`umbriel_sample`, `umbriel_time`, `umbriel_size`,
   `umbriel_border_distance`, `umbriel_palette_at`, `umbriel_progress` ...)
   are in docs/user/effects.md — fetch at YOUR built sha, upstream churns.
4. Validate with `umbriel config validate`, check compile state with
   `umbriel effects`, then evaluate live via msg toggles before selecting
   statically.
