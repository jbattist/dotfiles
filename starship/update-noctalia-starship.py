#!/usr/bin/env python3
"""Generate a Starship palette named 'noctalia' from Noctalia's active colors.

- Reads:   ~/.config/noctalia/colors.json
- Writes:  ~/dotfiles/starship/.config/starship.toml

Idempotent: updates/creates [palettes.noctalia] block and sets palette='noctalia'.

This intentionally maps the Material-ish palette into the prompt's section roles.
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

NOCTALIA_COLORS = Path(os.path.expanduser("~/.config/noctalia/colors.json"))
STARSHIP_TOML = Path(os.path.expanduser("~/dotfiles/starship/.config/starship.toml"))

PALETTE_NAME = "noctalia"


def load_noctalia_colors() -> dict:
    data = json.loads(NOCTALIA_COLORS.read_text())
    required = [
        "mPrimary",
        "mOnPrimary",
        "mSecondary",
        "mTertiary",
        "mError",
        "mSurface",
        "mOnSurface",
        "mSurfaceVariant",
        "mOnSurfaceVariant",
        "mOutline",
    ]
    missing = [k for k in required if k not in data]
    if missing:
        raise SystemExit(f"Noctalia colors missing keys: {missing}")
    return data


def build_starship_palette(c: dict) -> dict:
    # Section backgrounds: keep it dark and tasteful.
    # Use primary/tertiary for accent sections; use surface variants for calmer blocks.
    return {
        "os_section_bg": c["mOutline"],
        "dir_section_bg": c["mPrimary"],
        "git_section_bg": c["mTertiary"],
        "lang_section_bg": c["mSecondary"],
        "docker_section_bg": c["mOutline"],
        "time_section_bg": c["mOnSurfaceVariant"],
        "text_light": c["mOnSurface"],
        "text_dark": c["mOnPrimary"],
        "success_fg": c["mPrimary"],
        "error_fg": c["mError"],
    }


def upsert_palette_block(toml: str, palette: dict) -> str:
    # Remove any existing Noctalia auto-generated section(s) if present.
    # We remove both the header comment + the [palettes.noctalia] table, so reruns
    # don't accumulate headers.
    auto_section_re = re.compile(
        rf"\n# =+\n# NOCTALIA \(AUTO-GENERATED\)\n# =+\n\[palettes\.{re.escape(PALETTE_NAME)}\]\n(?:[^\n]*\n)*?(?=\n\[|\Z)",
        re.MULTILINE,
    )
    toml, _ = auto_section_re.subn("\n", toml)

    # Also remove a bare [palettes.noctalia] block (in case the file predates the header).
    block_re = re.compile(
        rf"\n\[palettes\.{re.escape(PALETTE_NAME)}\]\n(?:[^\n]*\n)*?(?=\n\[|\Z)",
        re.MULTILINE,
    )
    toml, _ = block_re.subn("\n", toml)

    # Ensure palette selection is set
    toml = re.sub(
        r"^palette\s*=\s*(['\"]).*?\1\s*$",
        f"palette = '{PALETTE_NAME}'",
        toml,
        flags=re.MULTILINE,
    )

    # Append palette block at end (keeps it simple and avoids breaking other palettes)
    lines = ["", f"# ============================================================================", f"# NOCTALIA (AUTO-GENERATED)", f"# ============================================================================", f"[palettes.{PALETTE_NAME}]"]
    for k, v in palette.items():
        lines.append(f"{k} = \"{v}\"")
    lines.append("")

    return toml.rstrip() + "\n" + "\n".join(lines)


def main() -> int:
    if not NOCTALIA_COLORS.exists():
        raise SystemExit(f"Missing {NOCTALIA_COLORS}")
    if not STARSHIP_TOML.exists():
        raise SystemExit(f"Missing {STARSHIP_TOML}")

    colors = load_noctalia_colors()
    palette = build_starship_palette(colors)

    original = STARSHIP_TOML.read_text()
    updated = upsert_palette_block(original, palette)

    if updated != original:
        STARSHIP_TOML.write_text(updated)
        print("Updated starship.toml with Noctalia palette")
    else:
        print("No changes needed")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
