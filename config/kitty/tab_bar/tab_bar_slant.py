#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY TAB BAR SLANT ULTRA
# ══════════════════════════════════════════════════════════════════════════════
# File    : tab_bar/tab_bar_slant.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Slant-style tab bar — diagonal parallelogram-shaped tabs using
#           Nerd Font slant separator glyphs. Each tab appears to lean forward
#           giving a dynamic, modern editorial look.
#
#   Visual output:
#    ╱▓████ CODE ████▓╲ ╱░░ GIT ░░╲ ╱░ DOCS ░╲   [clock] [cpu] [ram]
#
#   Glyph set used:
#     U+E0BC  — left slant open  (╱  shape)
#     U+E0BE  — right slant open (╲  shape)
#     U+E0BD  — left slant solid (▓╱ shape)
#     U+E0BF  — right slant solid(╲▓ shape)
#
#   Active tab:   ╱████ TITLE ████╲
#   Inactive tab: ╱░░ TITLE ░░╲
#   Bell tab:     ╱!!!! TITLE !!!!╲  (red highlight)
#
#   Features:
#     • Parallelogram shape via slant glyphs
#     • Active tab: filled, bold, accent color
#     • Inactive tab: ghosted, thin text
#     • Bell tab: red fill, attention-grabbing
#     • Gap between tabs: small space (floating effect)
#     • Right bar: git branch of focused window's CWD
#     • Process icon at tab prefix
#     • Layout icon in active tab
#     • Pinned tab indicator
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import time
from typing import Optional

from kitty.fast_data_types import Screen, as_rgb
from kitty.tab_bar import DrawData, ExtraData, TabBarData

from .tab_bar import (
    CS, ProcessResolver, GitResolver, SystemMetrics,
    NotifResolver, _color,
)

# ══════════════════════════════════════════════════════════════════════════════
# SLANT GLYPHS
# ══════════════════════════════════════════════════════════════════════════════

# Powerline Extra glyphs for slant separators
SLANT_LEFT_OPEN   = "\uE0BC"   # ╱  left-side opening slant
SLANT_RIGHT_OPEN  = "\uE0BE"   # ╲  right-side closing slant
SLANT_LEFT_FILL   = "\uE0BD"   # solid left slant (filled)
SLANT_RIGHT_FILL  = "\uE0BF"   # solid right slant (filled)

# Layout icons
LAYOUT_ICONS = {
    "splits":     "󰕘",
    "tall":       "󰙀",
    "fat":        "󰑲",
    "grid":       "󱇘",
    "horizontal": "󰤻",
    "vertical":   "󰤼",
    "stack":      "󰊓",
    "default":    "󰕘",
}

_proc_resolver = ProcessResolver()


# ══════════════════════════════════════════════════════════════════════════════
# COLOR HELPERS
# ══════════════════════════════════════════════════════════════════════════════

def _tab_colors(is_active: bool, is_urgent: bool) -> tuple[int, int]:
    """Return (fg, bg) for a tab based on state."""
    if is_urgent:
        return CS.fg_active, CS.bg_urgent
    if is_active:
        return CS.fg_active, CS.bg_active
    return CS.fg_inactive, CS.bg_inactive


# ══════════════════════════════════════════════════════════════════════════════
# SLANT DRAWING
# ══════════════════════════════════════════════════════════════════════════════

def _draw_slant_left(screen: Screen, tab_bg: int, bar_bg: int) -> None:
    """
    Draw the left opening slant of a tab.
    Visually: bar_bg | slant_glyph(fg=tab_bg,bg=bar_bg) | tab content
    """
    screen.cursor.fg = _color(tab_bg)
    screen.cursor.bg = _color(bar_bg)
    screen.draw(SLANT_LEFT_OPEN)


def _draw_slant_right(screen: Screen, tab_bg: int, bar_bg: int) -> None:
    """
    Draw the right closing slant of a tab.
    Visually: tab content | slant_glyph(fg=tab_bg,bg=bar_bg)
    """
    screen.cursor.fg = _color(tab_bg)
    screen.cursor.bg = _color(bar_bg)
    screen.draw(SLANT_RIGHT_OPEN)


def _draw_tab_content(
    screen:       Screen,
    tab:          TabBarData,
    index:        int,
    is_active:    bool,
    is_urgent:    bool,
    fg:           int,
    bg:           int,
) -> int:
    """Draw the inner content of a tab. Returns cells drawn."""
    screen.cursor.fg   = _color(fg)
    screen.cursor.bg   = _color(bg)
    screen.cursor.bold = is_active

    active_exe = getattr(tab, "active_exe", "") or ""
    proc_icon, proc_color = _proc_resolver.resolve(active_exe)

    # Icon color: use process color if active, else muted
    icon_fg = proc_color if is_active else CS.fg_muted
    screen.cursor.fg = _color(icon_fg)
    screen.draw(f"{proc_icon}")

    # Tab number
    screen.cursor.fg = _color(fg)
    screen.draw(f" {index + 1}")

    # Title
    title = getattr(tab, "title", "") or ""
    if len(title) > 16:
        title = title[:15] + "…"

    if title:
        screen.draw(f" {title}")

    # Num windows
    num_windows = getattr(tab, "num_windows", 1)
    if num_windows > 1 and is_active:
        screen.cursor.fg = _color(CS.fg_muted)
        layout_name = getattr(tab, "layout_name", "default") or "default"
        layout_icon = LAYOUT_ICONS.get(layout_name, LAYOUT_ICONS["default"])
        screen.cursor.fg = _color(fg)
        screen.draw(f" {layout_icon}{num_windows}")

    screen.cursor.bold = False
    content = f"{proc_icon} {index + 1} {title}"
    return len(content) + (4 if num_windows > 1 and is_active else 0)


# ══════════════════════════════════════════════════════════════════════════════
# RIGHT BAR
# ══════════════════════════════════════════════════════════════════════════════

def _draw_slant_right_bar(screen: Screen, cwd: str) -> None:
    """Draw the right-aligned status bar with git + metrics."""
    parts = []

    # Git branch
    git = GitResolver.resolve(cwd)
    if git:
        branch_short = git.branch[:12] if len(git.branch) > 12 else git.branch
        dirty_mark   = "+" if git.dirty else ""
        git_color    = git.color
        parts.append((f"󰘬 {branch_short}{dirty_mark}", git_color))

    # Notifications
    notif = NotifResolver.unread_count()
    if notif > 0:
        parts.append((f"󰎟 {min(notif, 99)}", CS.status_warn))

    # Metrics
    cpu_pct = SystemMetrics.cpu_percent()
    ram_pct = SystemMetrics.ram_percent()
    parts.append((f"󰓅{cpu_pct:2.0f}%", SystemMetrics.cpu_color()))
    parts.append((f"󰍛{ram_pct:2.0f}%", SystemMetrics.ram_color()))

    # Clock
    parts.append((time.strftime("󰃰 %H:%M"), CS.fg_bar))

    # Calculate total width
    total_w = sum(len(p[0]) + 3 for p in parts)
    remaining = screen.columns - screen.cursor.x - total_w
    if remaining > 0:
        screen.cursor.fg = _color(CS.bg_bar)
        screen.cursor.bg = _color(CS.bg_bar)
        screen.draw(" " * remaining)

    # Draw slant opening for right bar
    _draw_slant_left(screen, CS.bg_segment, CS.bg_bar)

    for text, color in parts:
        screen.cursor.fg = _color(color)
        screen.cursor.bg = _color(CS.bg_segment)
        screen.draw(f" {text} ")


# ══════════════════════════════════════════════════════════════════════════════
# KITTY API ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

# Track active window CWD for git display
_active_cwd: str = ""


def draw_tab(
    draw_data:      DrawData,
    screen:         Screen,
    tab:            TabBarData,
    before:         int,
    max_tab_length: int,
    index:          int,
    is_last:        bool,
    extra_data:     ExtraData,
) -> int:
    """Main entry point — draws one slant-style tab."""

    global _active_cwd

    is_active = tab.is_active
    is_urgent = tab.needs_attention

    if is_active:
        _active_cwd = getattr(extra_data, "active_fg_colors", {}).get("cwd", "")

    fg, bg = _tab_colors(is_active, is_urgent)

    cells = 0

    # Gap before tab (floating effect between tabs)
    if index > 0:
        screen.cursor.fg = _color(CS.bg_bar)
        screen.cursor.bg = _color(CS.bg_bar)
        screen.draw(" ")
        cells += 1

    # Left slant
    _draw_slant_left(screen, bg, CS.bg_bar)
    cells += 1

    # Tab content (padding inside)
    screen.cursor.fg = _color(fg)
    screen.cursor.bg = _color(bg)
    screen.draw(" ")
    content_cells = _draw_tab_content(screen, tab, index, is_active, is_urgent, fg, bg)
    screen.draw(" ")
    cells += content_cells + 2

    # Right slant
    _draw_slant_right(screen, bg, CS.bg_bar)
    cells += 1

    # Right bar after last tab
    if is_last:
        _draw_slant_right_bar(screen, _active_cwd)

    return cells