# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — KITTY THEME SWITCHER KITTEN                  ║
# ║           Programmatic theme application for Kitty terminal                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

"""
ASH Kitty Theme Kitten
Applies ASH theme colors to Kitty terminal programmatically.

Usage:
    kitty +kitten theme.py              # Apply current ASH theme
    kitty +kitten theme.py --list       # List available themes
    kitty +kitten theme.py --preview    # Preview theme
    kitty +kitten theme.py THEME_NAME   # Apply specific theme
"""

import os
import sys
import json
import argparse
from typing import Dict, Optional, Any

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 THEME DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

BUILTIN_THEMES = {
    "ash-mocha": {
        "name":        "ASH Catppuccin Mocha",
        "background":  "#1e1e2e",
        "foreground":  "#cdd6f4",
        "cursor":      "#cba6f7",
        "selection_background": "#313244",
        "selection_foreground": "#cdd6f4",
        "color0":  "#45475a",  # Black
        "color8":  "#585b70",  # Bright Black
        "color1":  "#f38ba8",  # Red
        "color9":  "#f38ba8",  # Bright Red
        "color2":  "#a6e3a1",  # Green
        "color10": "#a6e3a1",  # Bright Green
        "color3":  "#f9e2af",  # Yellow
        "color11": "#f9e2af",  # Bright Yellow
        "color4":  "#89b4fa",  # Blue
        "color12": "#89b4fa",  # Bright Blue
        "color5":  "#cba6f7",  # Magenta
        "color13": "#cba6f7",  # Bright Magenta
        "color6":  "#94e2d5",  # Cyan
        "color14": "#94e2d5",  # Bright Cyan
        "color7":  "#bac2de",  # White
        "color15": "#cdd6f4",  # Bright White
    },
    "ash-latte": {
        "name":        "ASH Catppuccin Latte (Light)",
        "background":  "#eff1f5",
        "foreground":  "#4c4f69",
        "cursor":      "#8839ef",
        "selection_background": "#ccd0da",
        "selection_foreground": "#4c4f69",
        "color0":  "#5c5f77",
        "color8":  "#6c6f85",
        "color1":  "#d20f39",
        "color9":  "#d20f39",
        "color2":  "#40a02b",
        "color10": "#40a02b",
        "color3":  "#df8e1d",
        "color11": "#df8e1d",
        "color4":  "#1e66f5",
        "color12": "#1e66f5",
        "color5":  "#8839ef",
        "color13": "#8839ef",
        "color6":  "#179299",
        "color14": "#179299",
        "color7":  "#acb0be",
        "color15": "#bcc0cc",
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

def load_ash_colors() -> Dict[str, str]:
    """Load current ASH color palette from cache."""
    cache_file = os.path.expanduser("~/.cache/ash-dots/colors/current.json")

    defaults = BUILTIN_THEMES["ash-mocha"].copy()

    if not os.path.exists(cache_file):
        return defaults

    try:
        with open(cache_file, "r") as f:
            data = json.load(f)

        # Flatten nested structure
        colors = {}
        for section, values in data.items():
            if isinstance(values, dict):
                for key, val in values.items():
                    if isinstance(val, str) and val.startswith("#"):
                        colors[key] = val

        # Map ASH semantic colors to Kitty color slots
        if colors:
            return {
                "name":        "ASH Dynamic Theme",
                "background":  colors.get("base",      defaults["background"]),
                "foreground":  colors.get("text",       defaults["foreground"]),
                "cursor":      colors.get("primary",    defaults["cursor"]),
                "selection_background": colors.get("surface1", defaults["selection_background"]),
                "selection_foreground": colors.get("text",     defaults["selection_foreground"]),
                "color0":  colors.get("crust",    defaults["color0"]),
                "color8":  colors.get("surface1", defaults["color8"]),
                "color1":  colors.get("error",    defaults["color1"]),
                "color9":  colors.get("error",    defaults["color9"]),
                "color2":  colors.get("success",  defaults["color2"]),
                "color10": colors.get("success",  defaults["color10"]),
                "color3":  colors.get("warning",  defaults["color3"]),
                "color11": colors.get("warning",  defaults["color11"]),
                "color4":  colors.get("info",     defaults["color4"]),
                "color12": colors.get("secondary",defaults["color12"]),
                "color5":  colors.get("primary",  defaults["color5"]),
                "color13": colors.get("tertiary", defaults["color13"]),
                "color6":  colors.get("tertiary", defaults["color6"]),
                "color14": colors.get("tertiary", defaults["color14"]),
                "color7":  colors.get("subtext0", defaults["color7"]),
                "color15": colors.get("text",     defaults["color15"]),
            }
    except Exception as e:
        print(f"Warning: Could not load ASH colors: {e}", file=sys.stderr)

    return defaults


def generate_kitty_theme(colors: Dict[str, str]) -> str:
    """Generate Kitty config snippet from color dict."""
    lines = [
        "# ASH Dynamic Theme — Auto-generated",
        f"# Theme: {colors.get('name', 'ASH')}",
        "",
    ]

    color_keys = [
        "background", "foreground", "cursor",
        "selection_background", "selection_foreground",
    ] + [f"color{i}" for i in range(16)]

    for key in color_keys:
        if key in colors and colors[key]:
            lines.append(f"{key} {colors[key]}")

    return "\n".join(lines)


def apply_theme(colors: Dict[str, str]) -> None:
    """Write theme to Kitty theme file."""
    theme_file = os.path.expanduser("~/.config/kitty/themes/current.conf")
    os.makedirs(os.path.dirname(theme_file), exist_ok=True)

    theme_content = generate_kitty_theme(colors)

    with open(theme_file, "w") as f:
        f.write(theme_content)

    print(f"✓ Theme applied: {colors.get('name', 'ASH')}")
    print(f"  File: {theme_file}")
    print(f"  Reload Kitty: Ctrl+Shift+F5")


def list_themes() -> None:
    """List available themes."""
    print("\n🎨 Available Themes:\n")
    for theme_id, theme in BUILTIN_THEMES.items():
        print(f"  {theme_id:<20} {theme['name']}")
    print(f"  {'ash-dynamic':<20} Current ASH wallpaper colors (default)")
    print()


def preview_theme(colors: Dict[str, str]) -> None:
    """Preview theme colors in terminal."""
    print(f"\n🎨 Preview: {colors.get('name', 'Theme')}\n")

    preview_colors = [
        ("Background", colors.get("background", "")),
        ("Foreground", colors.get("foreground", "")),
        ("Primary",    colors.get("cursor", "")),
        ("Success",    colors.get("color2", "")),
        ("Warning",    colors.get("color3", "")),
        ("Error",      colors.get("color1", "")),
        ("Info",       colors.get("color4", "")),
    ]

    for name, hex_color in preview_colors:
        if hex_color and hex_color.startswith("#"):
            r = int(hex_color[1:3], 16)
            g = int(hex_color[3:5], 16)
            b = int(hex_color[5:7], 16)
            print(f"  \033[38;2;{r};{g};{b}m██\033[0m  {name:<12} {hex_color}")
    print()


# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="ASH Kitty Theme Kitten — Apply ASH theme to Kitty",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("theme", nargs="?", default="ash-dynamic",
                        help="Theme name (default: ash-dynamic)")
    parser.add_argument("--list",    action="store_true", help="List themes")
    parser.add_argument("--preview", action="store_true", help="Preview theme")
    parser.add_argument("--output",  type=str, help="Output file path")

    args = parser.parse_args()

    if args.list:
        list_themes()
        return

    # Load colors
    if args.theme == "ash-dynamic" or args.theme == "current":
        colors = load_ash_colors()
    elif args.theme in BUILTIN_THEMES:
        colors = BUILTIN_THEMES[args.theme]
    else:
        print(f"Unknown theme: {args.theme}")
        list_themes()
        sys.exit(1)

    if args.preview:
        preview_theme(colors)
        return

    if args.output:
        content = generate_kitty_theme(colors)
        with open(args.output, "w") as f:
            f.write(content)
        print(f"✓ Theme written to: {args.output}")
    else:
        apply_theme(colors)


if __name__ == "__main__":
    main()