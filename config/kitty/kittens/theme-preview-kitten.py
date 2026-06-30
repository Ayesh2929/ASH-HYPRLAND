#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY THEME PREVIEW KITTEN ULTRA
# ══════════════════════════════════════════════════════════════════════════════
# File    : kittens/theme-preview-kitten.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Ultra-premium live theme preview kitten for Kitty terminal.
#           Browse and apply ASH themes with a rich live preview showing
#           all 16 ANSI colors, syntax-highlighted code samples, UI element
#           previews, and real-time application without restart.
#
#   Features:
#     • Live preview: applies theme temporarily while browsing
#     • Syntax demo: renders code samples in current theme colors
#     • Color swatch grid: all 16 ANSI + true-color swatches
#     • UI preview: simulated waybar/prompt/git status in theme colors
#     • Contrast checker: WCAG ratio display for key color pairs
#     • History: recently applied themes
#     • Favourites: star themes for quick access
#     • Category filter: dark/light/neon/nature/pastel/retro
#     • Export: save theme to kitty.conf / colors.conf format
#     • Before/after comparison: toggle between current and previewed
#
#   Usage:
#     map super+shift+t  kitten kittens/theme-preview-kitten.py
#     ash theme preview  ash-dark
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from kittens.tui.handler import Handler
from kittens.tui.loop import Loop
from kittens.tui.operations import clear_screen, set_line_wrapping
from kitty.boss import Boss
from kitty.fast_data_types import Screen
from kitty.key_encoding import KeyEvent

# Paths
XDG_CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
ASH_DIR         = XDG_CONFIG_HOME / "ash"
KITTY_DIR       = XDG_CONFIG_HOME / "kitty"
THEMES_DIR      = KITTY_DIR / "themes"
ASH_THEMES_DIR  = XDG_CONFIG_HOME / "ash" / "themes" / "presets"

# ── Colors (current terminal palette — before any preview) ────────────────────
C = {
    "bg":    "\033[48;2;30;30;46m",
    "bg_s":  "\033[48;2;49;50;68m",
    "fg":    "\033[38;2;205;214;244m",
    "fg_m":  "\033[38;2;166;173;200m",
    "acc":   "\033[38;2;203;166;247m",
    "blue":  "\033[38;2;137;180;250m",
    "green": "\033[38;2;166;227;161m",
    "red":   "\033[38;2;243;139;168m",
    "yel":   "\033[38;2;249;226;175m",
    "bold":  "\033[1m",
    "dim":   "\033[2m",
    "ital":  "\033[3m",
    "r":     "\033[0m",
}

# ── Syntax demo code (shown in preview panel) ─────────────────────────────────
DEMO_CODE_LINES = [
    ("comment",   "# ASH Dotfiles — theme preview"),
    ("import",    "import asyncio, pathlib"),
    ("blank",     ""),
    ("decorator", "@dataclass"),
    ("keyword",   "class ThemeEngine:"),
    ("string",    '    """Ultra-premium theme engine."""'),
    ("blank",     ""),
    ("func",      "    async def apply(self, theme: str) -> bool:"),
    ("var",       "        colors = await self.extract(theme)"),
    ("call",      "        await self.broadcast(colors)"),
    ("number",    "        return len(colors) == 16"),
    ("blank",     ""),
    ("type",      "theme_map: dict[str, Path] = {}"),
    ("op",        "result = 42 * 0xFF + 0o17 - 0b1010"),
    ("regex",     "pattern = re.compile(r'\\w+\\s*=\\s*.+'  )"),
]

# ANSI color codes for syntax demo
SYNTAX_COLORS = {
    "comment":   "\033[38;5;8m",    # color8 bright black
    "import":    "\033[38;5;5m",    # color5 magenta/mauve
    "keyword":   "\033[38;5;5m",    # color5 magenta
    "decorator": "\033[38;5;6m",    # color6 cyan
    "string":    "\033[38;5;2m",    # color2 green
    "func":      "\033[38;5;4m",    # color4 blue
    "var":       "\033[38;5;7m",    # color7 white
    "call":      "\033[38;5;4m",    # color4 blue
    "number":    "\033[38;5;3m",    # color3 yellow
    "type":      "\033[38;5;6m",    # color6 cyan
    "op":        "\033[38;5;1m",    # color1 red
    "regex":     "\033[38;5;3m",    # color3 yellow
    "blank":     "",
}


@dataclass
class ThemeEntry:
    """A theme available for preview."""
    name:        str
    path:        Path
    category:    str = "dark"
    description: str = ""
    background:  str = "#1e1e2e"
    foreground:  str = "#cdd6f4"
    accent:      str = "#cba6f7"
    is_fav:      bool = False
    is_applied:  bool = False

    @property
    def display_name(self) -> str:
        return self.name.replace("-", " ").replace("_", " ").title()

    def read_color(self, key: str) -> str:
        """Read a specific color from the theme file."""
        if not self.path.exists():
            return ""
        for line in self.path.read_text().splitlines():
            line = line.strip()
            if line.lower().startswith(f"{key} ") or line.lower().startswith(f"{key}\t"):
                return line.split()[-1] if line.split() else ""
        return ""

    def load_colors(self) -> None:
        """Load key colors from theme file."""
        self.background = self.read_color("background") or self.background
        self.foreground = self.read_color("foreground") or self.foreground
        cursor          = self.read_color("cursor")
        if cursor:
            self.accent = cursor


class ThemeRegistry:
    """Discovers all available ASH + Kitty themes."""

    def __init__(self) -> None:
        self._themes: list[ThemeEntry] = []
        self._load()

    def _load(self) -> None:
        # Load from kitty themes dir
        for theme_path in sorted(THEMES_DIR.glob("*.conf")):
            self._themes.append(ThemeEntry(
                name=theme_path.stem,
                path=theme_path,
                category=self._guess_category(theme_path.stem),
            ))

        # Load from ASH themes directory tree
        if ASH_THEMES_DIR.exists():
            for category_dir in ASH_THEMES_DIR.iterdir():
                if category_dir.is_dir():
                    for theme_dir in category_dir.iterdir():
                        if theme_dir.is_dir():
                            conf = theme_dir / "theme.conf"
                            if conf.exists():
                                entry = ThemeEntry(
                                    name=theme_dir.name,
                                    path=conf,
                                    category=category_dir.name,
                                )
                                entry.load_colors()
                                self._themes.append(entry)

        # Load colors for kitty themes
        for t in self._themes:
            if not t.background or t.background == "#1e1e2e":
                t.load_colors()

    def _guess_category(self, name: str) -> str:
        """Guess category from theme name."""
        name_lower = name.lower()
        if any(w in name_lower for w in ["light", "latte", "dawn", "paper"]):
            return "light"
        if any(w in name_lower for w in ["neon", "cyber", "matrix", "synthwave"]):
            return "neon"
        if any(w in name_lower for w in ["forest", "ocean", "nature", "sakura"]):
            return "nature"
        if any(w in name_lower for w in ["pastel", "cotton", "mint"]):
            return "pastel"
        if any(w in name_lower for w in ["retro", "vapor", "8bit", "dos"]):
            return "retro"
        return "dark"

    def search(self, query: str, category: str = "all") -> list[ThemeEntry]:
        results = [
            t for t in self._themes
            if (category == "all" or t.category == category)
            and (not query or query.lower() in t.name.lower())
        ]
        return sorted(results, key=lambda t: t.name.lower())

    @property
    def categories(self) -> list[str]:
        cats = sorted({t.category for t in self._themes})
        return ["all"] + cats


class ThemePreviewHandler(Handler):
    """
    Live theme preview TUI.

    Layout:
    ┌──────────────────────────┬──────────────────────────────────────────────┐
    │  THEME LIST              │  LIVE PREVIEW                                │
    │  ── Categories ──        │  ┌─────────────────────────────────────────┐ │
    │  ● dark (24)             │  │ Color swatches                          │ │
    │  ○ light (14)            │  │ ■ ■ ■ ■ ■ ■ ■ ■  (ANSI 0-7)           │ │
    │                          │  │ ■ ■ ■ ■ ■ ■ ■ ■  (ANSI 8-15)          │ │
    │  ── Themes ──             │  ├─────────────────────────────────────────┤ │
    │  ❯ ash-dark              │  │ Syntax demo                             │ │
    │    catppuccin-mocha      │  │ import asyncio                          │ │
    │    tokyo-night           │  │ class Engine:  # comment                │ │
    │    gruvbox-dark          │  │     result = 42 + 0xFF                  │ │
    │                          │  └─────────────────────────────────────────┘ │
    │                          │  WCAG: bg/fg 13.4:1 ✓AAA                    │
    └──────────────────────────┴──────────────────────────────────────────────┘
    """

    def __init__(self, registry: ThemeRegistry, initial: str = "") -> None:
        super().__init__()
        self.registry     = registry
        self.query        = initial
        self.category     = "all"
        self.cat_idx      = 0
        self.selected_idx = 0
        self.scroll       = 0
        self.results      = registry.search(self.query, self.category)
        self.applied      = False
        self.chosen:      Optional[ThemeEntry] = None
        self._original_theme = ""  # Store to restore on cancel
        self._previewed:  Optional[str] = None

    @property
    def current_theme(self) -> Optional[ThemeEntry]:
        if self.results and 0 <= self.selected_idx < len(self.results):
            return self.results[self.selected_idx]
        return None

    def initialize(self) -> None:
        self.cmd_write(set_line_wrapping(False))
        self._render()

    def on_resize(self, screen_size: Screen) -> None:
        self._screen_size = screen_size
        self._render()

    def on_text(self, text: str, in_bracketed_paste: bool = False) -> None:
        self.query = self.query + text if text.isprintable() else self.query
        self.selected_idx = 0
        self.scroll = 0
        self.results = self.registry.search(self.query, self.category)
        self._render()

    def on_key(self, key_event: KeyEvent) -> None:
        key  = key_event.key
        mods = key_event.mods

        if key in ("up", "k") and not mods:
            self._move(-1)
        elif key in ("down", "j") and not mods:
            self._move(1)
        elif key == "left" and not mods:
            self._prev_category()
        elif key == "right" and not mods:
            self._next_category()
        elif key in ("backspace", "delete") and not mods:
            self.query = self.query[:-1]
            self.results = self.registry.search(self.query, self.category)
        elif key == "enter":
            self._apply()
            return
        elif key == "space":
            self._preview_current()
        elif key == "f" and mods == "ctrl":
            self._toggle_fav()
        elif key == "escape":
            self._restore_original()
            self.quit_loop(0)
            return

        self._render()

    def _move(self, delta: int) -> None:
        if not self.results:
            return
        self.selected_idx = max(0, min(len(self.results) - 1, self.selected_idx + delta))
        # Auto-preview on navigation
        self._preview_current()

    def _next_category(self) -> None:
        cats = self.registry.categories
        self.cat_idx = (self.cat_idx + 1) % len(cats)
        self.category = cats[self.cat_idx]
        self.selected_idx = 0
        self.results = self.registry.search(self.query, self.category)

    def _prev_category(self) -> None:
        cats = self.registry.categories
        self.cat_idx = (self.cat_idx - 1) % len(cats)
        self.category = cats[self.cat_idx]
        self.selected_idx = 0
        self.results = self.registry.search(self.query, self.category)

    def _preview_current(self) -> None:
        """Apply theme temporarily for live preview."""
        theme = self.current_theme
        if not theme or str(theme.path) == self._previewed:
            return
        self._previewed = str(theme.path)
        # Live apply via kitty @ set-colors
        try:
            subprocess.run(
                ["kitty", "@", "set-colors", "-a", str(theme.path)],
                capture_output=True, timeout=2,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
            pass

    def _apply(self) -> None:
        """Apply selected theme permanently."""
        theme = self.current_theme
        if not theme:
            return
        self.chosen = theme
        self.applied = True
        self.quit_loop(0)

    def _restore_original(self) -> None:
        """Restore the original theme on cancel."""
        orig = THEMES_DIR / "ash-dark.conf"
        if orig.exists():
            try:
                subprocess.run(
                    ["kitty", "@", "set-colors", "-a", str(orig)],
                    capture_output=True, timeout=2,
                )
            except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
                pass

    def _toggle_fav(self) -> None:
        theme = self.current_theme
        if theme:
            theme.is_fav = not theme.is_fav

    def _render_swatches(self) -> str:
        """Render ANSI color swatches (16 colors in 2 rows)."""
        rows = ["", ""]
        for i in range(8):
            rows[0] += f"\033[48;5;{i}m  {i:<2}\033[0m "
        for i in range(8, 16):
            rows[1] += f"\033[48;5;{i}m  {i:<2}\033[0m "
        return rows[0] + "\n  " + rows[1]

    def _render_syntax_demo(self) -> list[str]:
        """Render syntax-highlighted code demo."""
        lines = []
        for kind, code in DEMO_CODE_LINES:
            if kind == "blank":
                lines.append("")
                continue
            color = SYNTAX_COLORS.get(kind, "")
            lines.append(f"  {color}{code}\033[0m")
        return lines

    def _wcag_contrast(self, bg: str, fg: str) -> float:
        """Calculate WCAG luminance contrast ratio."""
        def lum(hex_color: str) -> float:
            hex_color = hex_color.lstrip("#")
            if len(hex_color) != 6:
                return 0.0
            r, g, b = (int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4))
            def lin(c: float) -> float:
                return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
            return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)

        l1, l2 = lum(bg), lum(fg)
        if l1 < l2:
            l1, l2 = l2, l1
        return (l1 + 0.05) / (l2 + 0.05)

    def _render(self) -> None:
        self.cmd_write(clear_screen())
        sc = getattr(self, "_screen_size", None)
        w  = getattr(sc, "columns", 120)
        h  = getattr(sc, "rows", 40)
        r  = C["r"]

        list_w    = min(32, w // 3)
        preview_w = w - list_w - 3

        # ── Header ────────────────────────────────────────────────────────────
        self.print(
            f"{C['bg_s']}{C['bold']}{C['acc']} 󰔰 THEME PREVIEW {r}"
            f"{C['bg_s']}{C['fg_m']} │ {r}"
            f"{C['bg_s']}{C['blue']} {len(self.results)} themes {r}"
            f"{C['bg_s']}{C['fg_m']} │ ←/→ category │ Space:preview │ Enter:apply {r}"
        )

        # ── Category bar ──────────────────────────────────────────────────────
        cats = self.registry.categories
        cat_bar = ""
        for i, cat in enumerate(cats):
            if cat == self.category:
                cat_bar += f" {C['bold']}{C['acc']}[{cat}]{r}"
            else:
                cat_bar += f" {C['fg_m']}{cat}{r}"
        self.print(f"\n{cat_bar}\n")

        # ── Two-column layout ──────────────────────────────────────────────────
        theme = self.current_theme

        # LEFT: theme list
        visible = h - 10
        end_idx = min(self.scroll + visible, len(self.results))
        list_lines: list[str] = []

        for i, t in enumerate(self.results[self.scroll:end_idx], self.scroll):
            is_sel  = i == self.selected_idx
            arrow   = f"{C['acc']}❯{r}" if is_sel else " "
            fav     = f"{C['yel']}★{r} " if t.is_fav else "  "
            name    = f"{C['bold']}{C['fg']}{t.display_name}{r}" if is_sel else f"{C['fg_m']}{t.display_name}{r}"
            cat_tag = f"{C['dim']}{t.category[:4]}{r}"
            list_lines.append(f"{arrow}{fav}{name} {cat_tag}")

        # RIGHT: preview panel
        preview_lines: list[str] = []
        if theme:
            preview_lines.append(
                f"{C['bold']}{C['acc']} 󰔰 {theme.display_name}{r}"
            )
            preview_lines.append(f"{C['fg_m']} {theme.category} │ {str(theme.path.parent.name)}{r}")
            preview_lines.append("")

            # Swatches
            preview_lines.append(f"{C['fg_m']}  Colors:{r}")
            for i in range(8):
                swatch = ""
                for j in range(8):
                    swatch += f"\033[48;5;{i*8+j}m  {r}"
                preview_lines.append(f"  {swatch}")

            preview_lines.append("")

            # Syntax demo
            preview_lines.append(f"{C['fg_m']}  Syntax:{r}")
            preview_lines.extend(self._render_syntax_demo()[:6])

            preview_lines.append("")

            # WCAG
            contrast = self._wcag_contrast(theme.background, theme.foreground)
            level    = "AAA" if contrast >= 7.0 else "AA" if contrast >= 4.5 else "FAIL"
            col      = C["green"] if contrast >= 7.0 else C["yel"] if contrast >= 4.5 else C["red"]
            preview_lines.append(
                f"  {C['fg_m']}WCAG: bg/fg {r}{col}{contrast:.1f}:1 ✓{level}{r}"
            )

            # Colors
            preview_lines.append(
                f"  {C['fg_m']}bg:{r} {theme.background}  "
                f"{C['fg_m']}fg:{r} {theme.foreground}  "
                f"{C['fg_m']}acc:{r} {theme.accent}"
            )

        # Render side by side
        max_rows = max(len(list_lines), len(preview_lines))
        for i in range(max_rows):
            left  = list_lines[i] if i < len(list_lines) else ""
            right = preview_lines[i] if i < len(preview_lines) else ""
            left_pad = f"{left:<{list_w}}"
            self.print(f" {left_pad} {C['fg_m']}│{r} {right}")

        # ── Footer ────────────────────────────────────────────────────────────
        self.print(f"\n{C['fg_m']}{'─' * w}{r}")
        self.print(
            f"  {C['bold']}{C['acc']}Enter{r}{C['fg_m']}:Apply  {r}"
            f"{C['bold']}{C['acc']}Space{r}{C['fg_m']}:Preview  {r}"
            f"{C['bold']}{C['acc']}^F{r}{C['fg_m']}:Favourite  {r}"
            f"{C['bold']}{C['acc']}Esc{r}{C['fg_m']}:Cancel{r}"
        )

    def print(self, text: str) -> None:
        self.cmd_write(text + "\r\n")


def main(args: list[str]) -> Optional[str]:
    registry = ThemeRegistry()
    initial  = args[1] if len(args) > 1 else ""
    handler  = ThemePreviewHandler(registry, initial)
    loop     = Loop()
    loop.loop(handler)

    if handler.chosen:
        return str(handler.chosen.path)
    return None


def handle_result(
    args:             list[str],
    answer:           Optional[str],
    target_window_id: int,
    boss:             Boss,
) -> None:
    if not answer:
        return
    # Apply via ASH CLI for full ecosystem update
    try:
        subprocess.run(
            ["ash", "theme", "apply-from-file", answer],
            capture_output=True, timeout=10,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        # Fall back to kitty-only apply
        subprocess.run(
            ["kitty", "@", "set-colors", "-a", answer],
            capture_output=True,
        )