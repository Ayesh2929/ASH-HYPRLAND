#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY TAB BAR FADE ULTRA
# ══════════════════════════════════════════════════════════════════════════════
# File    : tab_bar/tab_bar_fade.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Fade-effect tab bar — inactive tabs smoothly fade to transparent.
#           Creates a depth effect: active tab is full-bright, inactive tabs
#           progressively dim based on distance from active tab.
#
#   Visual effect:
#     Active:       [██ CODE ██]
#     1 away:       [▓▓ GIT  ▓▓]
#     2 away:       [░░ DOCS ░░]
#     3+ away:      [── NOTE ──]
#
#   Algorithm:
#     For each tab at distance D from active:
#       opacity = max(MIN_OPACITY, ACTIVE_OPACITY - D * FADE_STEP)
#       bg = lerp(bg_active, bg_bar, 1 - opacity)
#       fg = lerp(fg_active, fg_muted, 1 - opacity)
#
#   Features:
#     • Distance-based opacity falloff (configurable step)
#     • Separate fade curves for fg and bg
#     • Minimum opacity floor (never fully transparent)
#     • Process icon always at full brightness
#     • Bell/urgent tabs always at full brightness
#     • Smooth separator: fade from tab bg → bar bg
#     • Configurable via ASH config: ash config set kitty.tab_fade_step 0.15
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import time
from pathlib import Path
from typing import Optional

from kitty.fast_data_types import Screen, as_rgb
from kitty.tab_bar import DrawData, ExtraData, TabBarData

# Import shared utilities from tab_bar.py
from .tab_bar import (
    CS, ProcessResolver, SystemMetrics, AshModeResolver,
    NotifResolver, SEP_RIGHT, SEP_R_THIN, _color,
)

# ══════════════════════════════════════════════════════════════════════════════
# FADE CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

FADE_STEP      = 0.18   # Opacity reduction per tab distance
MIN_OPACITY    = 0.15   # Minimum opacity (fully transparent = 0.0)
ACTIVE_OPACITY = 1.0    # Active tab opacity
BG_FADE_WEIGHT = 0.85   # How much bg fades vs fg
FG_FADE_WEIGHT = 0.70   # How much fg fades

# Load fade config from ASH settings
def _load_fade_config() -> None:
    global FADE_STEP, MIN_OPACITY
    cfg_path = Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")
    ) / "ash" / "kitty" / "tab-fade.conf"
    if not cfg_path.exists():
        return
    try:
        for line in cfg_path.read_text().splitlines():
            k, _, v = line.partition("=")
            k, v = k.strip(), v.strip()
            if k == "fade_step":
                FADE_STEP = float(v)
            elif k == "min_opacity":
                MIN_OPACITY = float(v)
    except (OSError, ValueError):
        pass


_load_fade_config()


# ══════════════════════════════════════════════════════════════════════════════
# COLOR INTERPOLATION
# ══════════════════════════════════════════════════════════════════════════════

def _lerp_channel(a: int, b: int, t: float) -> int:
    """Linear interpolation between two color channel values."""
    return int(a + (b - a) * t)


def _lerp_color(color_a: int, color_b: int, t: float) -> int:
    """
    Interpolate between two 0xRRGGBB colors.
    t=0.0 → color_a, t=1.0 → color_b
    """
    r_a, g_a, b_a = (color_a >> 16) & 0xFF, (color_a >> 8) & 0xFF, color_a & 0xFF
    r_b, g_b, b_b = (color_b >> 16) & 0xFF, (color_b >> 8) & 0xFF, color_b & 0xFF

    r = _lerp_channel(r_a, r_b, t)
    g = _lerp_channel(g_a, g_b, t)
    b = _lerp_channel(b_a, b_b, t)

    return (r << 16) | (g << 8) | b


def _fade_tab_colors(
    distance:  int,
    is_urgent: bool,
) -> tuple[int, int]:
    """
    Calculate fg/bg colors for a tab at `distance` from the active tab.
    Returns (fg_color, bg_color).
    """
    if is_urgent:
        return CS.fg_active, CS.bg_urgent

    if distance == 0:
        return CS.fg_active, CS.bg_active

    # Calculate fade amount (0.0 = no fade, 1.0 = fully faded)
    fade_amount = min(1.0, distance * FADE_STEP)
    opacity     = max(MIN_OPACITY, ACTIVE_OPACITY - fade_amount)
    fade_t      = 1.0 - opacity

    # Fade bg toward bar background
    bg = _lerp_color(CS.bg_active, CS.bg_bar, fade_t * BG_FADE_WEIGHT)

    # Fade fg toward muted text
    fg = _lerp_color(CS.fg_active, CS.fg_muted, fade_t * FG_FADE_WEIGHT)

    return fg, bg


# ══════════════════════════════════════════════════════════════════════════════
# TAB DISTANCE TRACKER
# ══════════════════════════════════════════════════════════════════════════════

class TabDistanceTracker:
    """
    Tracks the active tab index so we can calculate distance for each tab.
    Since Kitty calls draw_tab() left-to-right, we need a two-pass approach
    or to track state across calls.
    """

    def __init__(self) -> None:
        self._active_idx:  int = 0
        self._total_tabs:  int = 0
        self._tab_indices: list[tuple[int, bool]] = []  # (index, is_active)

    def record_tab(self, index: int, is_active: bool) -> None:
        if is_active:
            self._active_idx = index
        if index == 0:
            self._tab_indices = []
        self._tab_indices.append((index, is_active))

    def distance(self, index: int) -> int:
        return abs(index - self._active_idx)


_distance_tracker = TabDistanceTracker()
_proc_resolver    = ProcessResolver()


# ══════════════════════════════════════════════════════════════════════════════
# DRAW FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

def _draw_fade_separator(
    screen:    Screen,
    from_bg:   int,
    to_bg:     int,
    distance:  int,
) -> None:
    """
    Draw a fade-aware separator between tabs.
    Uses thin separator (no arrow) for a softer look.
    """
    if distance == 0:
        # Active → next: use full separator
        screen.cursor.fg = _color(from_bg)
        screen.cursor.bg = _color(to_bg)
        screen.draw(SEP_RIGHT)
    else:
        # Between faded tabs: thin separator
        sep_fg = _lerp_color(from_bg, CS.bg_bar, 0.5)
        screen.cursor.fg = _color(sep_fg)
        screen.cursor.bg = _color(to_bg)
        screen.draw(SEP_R_THIN)


def _draw_right_bar(screen: Screen) -> None:
    """Draw the right-aligned status bar."""
    # System metrics
    cpu_pct   = SystemMetrics.cpu_percent()
    ram_pct   = SystemMetrics.ram_percent()
    cpu_color = SystemMetrics.cpu_color()
    ram_color = SystemMetrics.ram_color()
    notif     = NotifResolver.unread_count()
    clock     = time.strftime("%H:%M")

    # Build right text
    parts = []
    if notif > 0:
        parts.append(f"󰎟 {min(notif, 99)}")
    parts.append(f"󰓅 {cpu_pct:2.0f}%")
    parts.append(f"󰍛 {ram_pct:2.0f}%")
    parts.append(f"󰃰 {clock}")

    right_text = "  ".join(parts)
    total_width = len(right_text) + 4

    # Right-align
    remaining = screen.columns - screen.cursor.x - total_width
    if remaining > 0:
        screen.cursor.fg = _color(CS.bg_bar)
        screen.cursor.bg = _color(CS.bg_bar)
        screen.draw(" " * remaining)

    # Draw segments
    screen.cursor.fg = _color(CS.fg_muted)
    screen.cursor.bg = _color(CS.bg_segment)
    screen.draw(f"  {right_text}  ")


# ══════════════════════════════════════════════════════════════════════════════
# KITTY API ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

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
    """Main entry point called by Kitty for each tab."""

    # Track this tab
    _distance_tracker.record_tab(index, tab.is_active)
    distance  = _distance_tracker.distance(index)
    is_urgent = tab.needs_attention

    # Calculate colors for this tab
    fg, bg = _fade_tab_colors(distance, is_urgent)

    # Opacity-based alpha for the text opacity feel
    opacity   = max(MIN_OPACITY, ACTIVE_OPACITY - distance * FADE_STEP)

    # Process icon
    active_exe = getattr(tab, "active_exe", "") or ""
    proc_icon, proc_color = _proc_resolver.resolve(active_exe)

    # At high fade levels, use the process icon color at reduced brightness
    if distance >= 2:
        icon_fg = _lerp_color(proc_color, CS.fg_muted, distance * 0.3)
    else:
        icon_fg = proc_color if tab.is_active else fg

    # Tab title
    title = getattr(tab, "title", "") or ""
    if len(title) > 18:
        title = title[:17] + "…"

    num_windows = getattr(tab, "num_windows", 1)
    win_suffix  = f" [{num_windows}]" if num_windows > 1 else ""

    # Draw tab background
    screen.cursor.bold = tab.is_active and distance == 0
    screen.cursor.fg   = _color(icon_fg)
    screen.cursor.bg   = _color(bg)

    cells = 0

    # Icon
    screen.draw(f" {proc_icon}")
    cells += 2

    # Number + title
    screen.cursor.fg = _color(fg)
    num_display = f" {index + 1}:" if tab.is_active else f" {index + 1}:"
    text        = f"{num_display}{title}{win_suffix} "
    screen.draw(text)
    cells += len(text)

    # Separator (if not last tab)
    if not is_last:
        next_distance = distance + (1 if not tab.is_active else -1)
        _, next_bg = _fade_tab_colors(abs(next_distance), False)
        _draw_fade_separator(screen, bg, next_bg, distance)
        cells += 1

    # After last tab: right bar
    if is_last:
        _draw_right_bar(screen)

    screen.cursor.bold = False
    return cells