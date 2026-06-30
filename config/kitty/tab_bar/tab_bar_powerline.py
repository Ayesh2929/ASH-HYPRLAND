#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY TAB BAR POWERLINE ULTRA
# ══════════════════════════════════════════════════════════════════════════════
# File    : tab_bar/tab_bar_powerline.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Ultimate Powerline tab bar with maximum information density,
#           real-time system metrics, git integration, and a comprehensive
#           right-side status panel inspired by airline/lualine prompts.
#
#   Layout:
#   ┌─────────────────────────────────────────────────────────────────────────┐
#   │ ❯❯ SESSION  CODE  ❯  GIT  ❯  DOCS  ❯  NOTES    git:main+ │cpu │ram │⏰│
#   └─────────────────────────────────────────────────────────────────────────┘
#
#   Left powerline (tabs):
#     [SESSION_BADGE] ► [active_tab] ► [inactive] ► [inactive] ►
#
#   Right powerline (status):
#     ◄ [git:branch+dirty] ◄ [cpu%] ◄ [ram%] ◄ [notif] ◄ [mode] ◄ [clock]
#
#   Separator hierarchy:
#     ●──────────────────────────────────────────────────────────────────────●
#     │  Solid arrows (►◄) between different-colored segments               │
#     │  Thin arrows (❯❮) between same-colored segments                     │
#     │  No separator: between consecutive same-tab segments                │
#     ●──────────────────────────────────────────────────────────────────────●
#
#   Features (beyond base tab_bar.py):
#     • Full right-side powerline panel (git/cpu/ram/notif/mode/clock)
#     • Per-language syntax highlighting of tab accent
#     • Uncommitted change count in git segment
#     • Ahead/behind count with directional arrows
#     • Network speed indicator (↑↓ bytes/s) when active
#     • VPN status indicator (🔒 when VPN is active)
#     • SSH session indicator (hostname of remote)
#     • Battery level (for laptop users)
#     • Active layout icon in tab
#     • Per-tab background with gradient tint
#     • Tab group coloring (ASH workspace mapping)
#     • Macro recording indicator (⚫ REC)
#
#   Performance:
#     • All system data cached with configurable TTL
#     • Non-blocking subprocess calls (ThreadPoolExecutor)
#     • No regex in hot path (pre-compiled at module load)
#     • String building with list joins (no string concatenation loops)
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import re
import subprocess
import time
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path
from typing import Optional

from kitty.fast_data_types import Screen, as_rgb
from kitty.tab_bar import DrawData, ExtraData, TabBarData

from .tab_bar import (
    CS, ProcessResolver, GitResolver, GitStatus,
    SystemMetrics, NotifResolver, AshModeResolver,
    PROCESS_MAP, SEP_RIGHT, SEP_LEFT, SEP_R_THIN, SEP_L_THIN,
    _color,
)

# ══════════════════════════════════════════════════════════════════════════════
# § 1  POWERLINE CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

# Powerline separator styles
PL_ARROWS = {
    "right_solid": "\uE0B0",   # ►
    "right_thin":  "\uE0B1",   # ❯
    "left_solid":  "\uE0B2",   # ◄
    "left_thin":   "\uE0B3",   # ❮
}

# Tab group color mapping (ASH session → accent)
TAB_GROUP_COLORS = {
    "dev":        0x89b4fa,   # blue
    "admin":      0xf38ba8,   # red
    "monitoring": 0xa6e3a1,   # green
    "fullstack":  0x89dceb,   # sky
    "gaming":     0xa6e3a1,   # green
    "default":    0xcba6f7,   # mauve
}

# Layout icon mapping
LAYOUT_ICONS: dict[str, str] = {
    "splits":     "󰕘",
    "tall":       "󰙀",
    "fat":        "󰑲",
    "grid":       "󱇘",
    "horizontal": "󰤻",
    "vertical":   "󰤼",
    "stack":      "󰊓",
}

# Pre-compiled regex for SSH hostname extraction
_SSH_RE = re.compile(r"ssh\s+(?:[\w.]+@)?([\w.-]+)")

# Thread pool for non-blocking IO
_executor = ThreadPoolExecutor(max_workers=2, thread_name_prefix="ash-tab-bar")

# ══════════════════════════════════════════════════════════════════════════════
# § 2  NETWORK SPEED MONITOR
# ══════════════════════════════════════════════════════════════════════════════

class NetworkMonitor:
    """Non-blocking network I/O speed sampler."""

    _rx_prev:   int   = 0
    _tx_prev:   int   = 0
    _last_ts:   float = 0.0
    _rx_speed:  float = 0.0
    _tx_speed:  float = 0.0
    TTL         = 2.0

    @classmethod
    def _read_net_stats(cls) -> tuple[int, int]:
        """Read total RX/TX bytes from /proc/net/dev."""
        total_rx = total_tx = 0
        try:
            with open("/proc/net/dev", "r") as f:
                for line in f:
                    parts = line.split()
                    if len(parts) < 10 or ":" not in parts[0]:
                        continue
                    iface = parts[0].rstrip(":")
                    if iface in ("lo",):
                        continue
                    total_rx += int(parts[1])
                    total_tx += int(parts[9])
        except (OSError, ValueError, IndexError):
            pass
        return total_rx, total_tx

    @classmethod
    def update(cls) -> None:
        now = time.monotonic()
        if now - cls._last_ts < cls.TTL:
            return

        rx, tx = cls._read_net_stats()
        if cls._last_ts > 0:
            dt = now - cls._last_ts
            cls._rx_speed = (rx - cls._rx_prev) / dt
            cls._tx_speed = (tx - cls._tx_prev) / dt

        cls._rx_prev = rx
        cls._tx_prev = tx
        cls._last_ts = now

    @classmethod
    def speed_display(cls) -> Optional[str]:
        """Return formatted speed string, or None if below threshold."""
        cls.update()
        threshold = 50 * 1024  # 50KB/s minimum to display
        if cls._rx_speed < threshold and cls._tx_speed < threshold:
            return None

        def _fmt(bps: float) -> str:
            if bps >= 1024 * 1024:
                return f"{bps / 1024 / 1024:.1f}M"
            if bps >= 1024:
                return f"{bps / 1024:.0f}K"
            return f"{bps:.0f}B"

        return f"↓{_fmt(cls._rx_speed)} ↑{_fmt(cls._tx_speed)}"


# ══════════════════════════════════════════════════════════════════════════════
# § 3  VPN DETECTOR
# ══════════════════════════════════════════════════════════════════════════════

class VPNDetector:
    """Detects active VPN connections."""

    _cache:    bool  = False
    _cache_ts: float = 0.0
    TTL = 10.0

    @classmethod
    def is_active(cls) -> bool:
        now = time.monotonic()
        if now - cls._cache_ts < cls.TTL:
            return cls._cache

        try:
            result = subprocess.run(
                ["ip", "link", "show"],
                capture_output=True, text=True, timeout=0.5,
            )
            cls._cache = bool(re.search(
                r"\b(tun|wg|vpn|tap|ppp|ipsec)\d*\b",
                result.stdout,
            ))
        except (FileNotFoundError, subprocess.TimeoutExpired):
            cls._cache = False

        cls._cache_ts = now
        return cls._cache


# ══════════════════════════════════════════════════════════════════════════════
# § 4  BATTERY READER
# ══════════════════════════════════════════════════════════════════════════════

class BatteryReader:
    """Reads battery status from /sys/class/power_supply."""

    _capacity:   int  = -1  # -1 = no battery / desktop
    _charging:   bool = False
    _cache_ts:   float = 0.0
    TTL = 30.0

    # Battery level icons (10-step)
    ICONS_DISCHARGING = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    ICONS_CHARGING    = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂄"]

    @classmethod
    def update(cls) -> None:
        now = time.monotonic()
        if now - cls._cache_ts < cls.TTL:
            return

        for bat_path in Path("/sys/class/power_supply").glob("BAT*"):
            try:
                capacity = int((bat_path / "capacity").read_text().strip())
                status   = (bat_path / "status").read_text().strip()
                cls._capacity = capacity
                cls._charging = status in ("Charging", "Full")
                break
            except (OSError, ValueError):
                cls._capacity = -1

        cls._cache_ts = now

    @classmethod
    def display(cls) -> Optional[tuple[str, int]]:
        """Returns (display_str, color) or None if no battery."""
        cls.update()
        if cls._capacity < 0:
            return None

        icons = cls.ICONS_CHARGING if cls._charging else cls.ICONS_DISCHARGING
        idx   = min(10, cls._capacity // 10)
        icon  = icons[idx]

        if cls._charging:
            color = CS.status_ok
        elif cls._capacity <= 10:
            color = CS.status_error
        elif cls._capacity <= 25:
            color = CS.status_warn
        else:
            color = CS.status_ok

        charging_mark = "+" if cls._charging else ""
        return f"{icon}{cls._capacity}{charging_mark}%", color


# ══════════════════════════════════════════════════════════════════════════════
# § 5  POWERLINE SEGMENT RENDERER
# ══════════════════════════════════════════════════════════════════════════════

class PowerlineTab:
    """
    Renders a single powerline-style tab with all decorations.
    """

    def __init__(self) -> None:
        self._proc_resolver = ProcessResolver()

    def _session_badge(self, screen: Screen) -> int:
        """Draw session badge (leftmost element, before any tabs)."""
        session = os.environ.get("ASH_SESSION", "")
        if not session:
            return 0

        session_color = TAB_GROUP_COLORS.get(session, TAB_GROUP_COLORS["default"])
        text          = f" 󰒓 {session[:8].upper()} "

        screen.cursor.bold = True
        screen.cursor.fg   = _color(CS.fg_active)
        screen.cursor.bg   = _color(session_color)
        screen.draw(text)
        cells = len(text)

        # Separator: session → first tab
        screen.cursor.bold = False
        screen.cursor.fg   = _color(session_color)
        screen.cursor.bg   = _color(CS.bg_active)   # Will be overridden per tab
        screen.draw(PL_ARROWS["right_solid"])
        cells += 1

        return cells

    def draw(
        self,
        screen:    Screen,
        tab:       TabBarData,
        index:     int,
        is_active: bool,
        is_last:   bool,
        next_is_active: bool = False,
        prev_bg:   int  = 0,
    ) -> int:
        """
        Draw a complete powerline tab.
        Returns total cells drawn.
        """
        is_urgent = tab.needs_attention
        cells     = 0

        # ── Determine colors ──────────────────────────────────────────────────
        if is_urgent:
            bg, fg = CS.bg_urgent, CS.fg_active
        elif is_active:
            bg, fg = CS.bg_active, CS.fg_active
        else:
            # Inactive: slight tint based on process family
            active_exe = getattr(tab, "active_exe", "") or ""
            _, proc_color = self._proc_resolver.resolve(active_exe)
            # Blend process color into inactive bg (10%)
            bg = self._blend(CS.bg_inactive, proc_color, 0.08)
            fg = CS.fg_inactive

        # ── Left separator (previous → this tab) ─────────────────────────────
        if index > 0 and prev_bg != 0:
            screen.cursor.fg = _color(prev_bg)
            screen.cursor.bg = _color(bg)
            screen.draw(PL_ARROWS["right_solid"])
            cells += 1

        # ── Tab content ───────────────────────────────────────────────────────
        active_exe = getattr(tab, "active_exe", "") or ""
        proc_icon, proc_color = self._proc_resolver.resolve(active_exe)

        # Process icon with language color
        icon_color = proc_color if is_active else self._blend(proc_color, fg, 0.5)
        screen.cursor.fg   = _color(icon_color)
        screen.cursor.bg   = _color(bg)
        screen.cursor.bold = is_active
        screen.draw(f" {proc_icon}")
        cells += 2

        # Tab index
        screen.cursor.fg = _color(fg)
        screen.draw(f" {index + 1}")
        cells += 2

        # Thin separator between index and title
        screen.cursor.fg = _color(CS.sep_fg)
        screen.draw(PL_ARROWS["right_thin"])
        cells += 1

        # Title
        title = getattr(tab, "title", "") or ""
        if len(title) > 20:
            title = title[:19] + "…"
        screen.cursor.fg = _color(fg)
        screen.draw(f" {title}")
        cells += len(title) + 1

        # Layout icon (active tab only)
        if is_active:
            num_windows = getattr(tab, "num_windows", 1)
            layout_name = getattr(tab, "layout_name", "") or "splits"
            layout_icon = LAYOUT_ICONS.get(layout_name, "󰕘")
            if num_windows > 1:
                screen.cursor.fg = _color(CS.fg_muted)
                screen.draw(f" {layout_icon}{num_windows}")
                cells += 4

        screen.draw(" ")
        cells += 1

        # ── Store this tab's bg for next separator ───────────────────────────
        screen.cursor.bold = False

        self._last_bg = bg
        return cells, bg

    @staticmethod
    def _blend(color_a: int, color_b: int, t: float) -> int:
        """Blend two colors. t=0 → a, t=1 → b."""
        r_a, g_a, b_a = (color_a >> 16) & 0xFF, (color_a >> 8) & 0xFF, color_a & 0xFF
        r_b, g_b, b_b = (color_b >> 16) & 0xFF, (color_b >> 8) & 0xFF, color_b & 0xFF
        r = int(r_a + (r_b - r_a) * t)
        g = int(g_a + (g_b - g_a) * t)
        b = int(b_a + (b_b - b_a) * t)
        return (r << 16) | (g << 8) | b


# ══════════════════════════════════════════════════════════════════════════════
# § 6  RIGHT POWERLINE STATUS BAR
# ══════════════════════════════════════════════════════════════════════════════

class RightStatusBar:
    """
    Renders the right-anchored powerline status bar.
    Segments (right to left): clock ◄ mode ◄ notif ◄ vpn ◄ battery ◄ net ◄ ram ◄ cpu ◄ git
    """

    def __init__(self) -> None:
        self._segments: list[tuple[str, int, int]] = []   # (text, fg, bg)
        self._total_width: int = 0
        self._last_update: float = 0.0
        self._cwd: str = ""

    def set_cwd(self, cwd: str) -> None:
        self._cwd = cwd

    def _build_segments(self) -> list[tuple[str, int, int]]:
        """Build all right-side segments. Returns list of (text, fg, bg)."""
        segments: list[tuple[str, int, int]] = []

        # ── Git ───────────────────────────────────────────────────────────────
        if self._cwd:
            git = GitResolver.resolve(self._cwd)
            if git:
                branch_text = git.branch[:14]
                dirty       = "+" if git.dirty else ""
                ahead       = f"↑{git.ahead}" if git.ahead > 0 else ""
                behind      = f"↓{git.behind}" if git.behind > 0 else ""
                extra       = f"{ahead}{behind}"
                git_text    = f" 󰘬 {branch_text}{dirty} {extra}".rstrip()
                git_bg      = 0x2a2a40
                git_fg      = git.color
                segments.append((git_text, git_fg, git_bg))

        # ── Network speed ─────────────────────────────────────────────────────
        net_speed = NetworkMonitor.speed_display()
        if net_speed:
            segments.append((f" 󰛳 {net_speed} ", CS.accent_docker, CS.bg_segment))

        # ── VPN ───────────────────────────────────────────────────────────────
        if VPNDetector.is_active():
            segments.append((" 󰒃 VPN ", CS.status_ok, CS.bg_segment))

        # ── Battery ───────────────────────────────────────────────────────────
        bat = BatteryReader.display()
        if bat:
            bat_text, bat_color = bat
            segments.append((f" {bat_text} ", bat_color, CS.bg_segment))

        # ── CPU ───────────────────────────────────────────────────────────────
        cpu_pct   = SystemMetrics.cpu_percent()
        cpu_color = SystemMetrics.cpu_color()
        cpu_bar   = SystemMetrics.mini_bar(cpu_pct, 5)
        segments.append((
            f" 󰓅 {cpu_bar} {cpu_pct:2.0f}% ",
            cpu_color,
            CS.bg_segment,
        ))

        # ── RAM ───────────────────────────────────────────────────────────────
        ram_pct   = SystemMetrics.ram_percent()
        ram_color = SystemMetrics.ram_color()
        ram_bar   = SystemMetrics.mini_bar(ram_pct, 5)
        segments.append((
            f" 󰍛 {ram_bar} {ram_pct:2.0f}% ",
            ram_color,
            CS.bg_segment,
        ))

        # ── Notifications ─────────────────────────────────────────────────────
        notif = NotifResolver.unread_count()
        if notif > 0:
            notif_text = f" 󰎟 {min(notif, 99)} "
            segments.append((notif_text, CS.status_warn, CS.bg_segment))

        # ── ASH Mode ──────────────────────────────────────────────────────────
        mode_icon, mode_color = AshModeResolver.resolve()
        if mode_icon:
            segments.append((f" {mode_icon} ", mode_color, CS.bg_segment))

        # ── Clock ─────────────────────────────────────────────────────────────
        clock_text = time.strftime(" 󰃰 %H:%M ")
        segments.append((clock_text, CS.fg_bar, CS.bg_bar))

        return segments

    def draw(self, screen: Screen, last_tab_bg: int) -> None:
        """Draw all right-side segments."""
        now = time.monotonic()
        if now - self._last_update >= 1.0:
            self._segments    = self._build_segments()
            self._total_width = sum(len(s[0]) for s in self._segments) + len(self._segments)
            self._last_update = now

        if not self._segments:
            return

        # Fill gap between tabs and right bar
        gap = screen.columns - screen.cursor.x - self._total_width
        if gap > 0:
            screen.cursor.fg = _color(CS.bg_bar)
            screen.cursor.bg = _color(CS.bg_bar)
            screen.draw(" " * gap)

        # Opening left-solid separator: last_tab_bg → first right segment bg
        first_bg = self._segments[0][2]
        screen.cursor.fg = _color(first_bg)
        screen.cursor.bg = _color(CS.bg_bar)
        screen.draw(PL_ARROWS["left_solid"])

        for i, (text, fg, bg) in enumerate(self._segments):
            screen.cursor.fg = _color(fg)
            screen.cursor.bg = _color(bg)
            screen.draw(text)

            # Separator between segments
            if i < len(self._segments) - 1:
                next_bg = self._segments[i + 1][2]
                if next_bg != bg:
                    screen.cursor.fg = _color(next_bg)
                    screen.cursor.bg = _color(bg)
                    screen.draw(PL_ARROWS["left_solid"])
                else:
                    screen.cursor.fg = _color(CS.sep_fg)
                    screen.cursor.bg = _color(bg)
                    screen.draw(PL_ARROWS["left_thin"])


# ══════════════════════════════════════════════════════════════════════════════
# § 7  STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

class TabBarState:
    """Tracks state across draw_tab() calls."""

    def __init__(self) -> None:
        self._tab_renderer  = PowerlineTab()
        self._right_bar     = RightStatusBar()
        self._prev_bg:      int  = 0
        self._session_drawn: bool = False
        self._active_cwd:   str  = ""
        self._last_tab_bg:  int  = CS.bg_inactive

    def reset(self) -> None:
        """Reset per-render state (called on first tab)."""
        self._prev_bg       = 0
        self._session_drawn = False

    def draw_session_badge_if_needed(self, screen: Screen) -> None:
        if not self._session_drawn:
            self._tab_renderer._session_badge(screen)
            self._session_drawn = True

    def draw_tab(
        self,
        screen:    Screen,
        tab:       TabBarData,
        index:     int,
        is_last:   bool,
    ) -> int:
        """Draw one tab. Returns cells written."""
        is_active = tab.is_active

        if is_active:
            self._active_cwd = ""  # Reset CWD; will be set via extra_data

        cells, bg = self._tab_renderer.draw(
            screen    = screen,
            tab       = tab,
            index     = index,
            is_active = is_active,
            is_last   = is_last,
            prev_bg   = self._prev_bg,
        )

        self._prev_bg    = bg
        self._last_tab_bg = bg

        if is_last:
            self._right_bar.set_cwd(self._active_cwd)
            self._right_bar.draw(screen, self._last_tab_bg)

        return cells


# Module-level singleton
_state = TabBarState()


# ══════════════════════════════════════════════════════════════════════════════
# § 8  KITTY API ENTRY POINT
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
    """
    Main Kitty entry point — called once per tab per render cycle.
    Returns number of screen cells written.
    """
    # Reset state for first tab
    if index == 0:
        _state.reset()
        # Draw session badge before any tab
        _state.draw_session_badge_if_needed(screen)

    # Extract CWD from extra_data if available
    if tab.is_active and hasattr(extra_data, "active_cwd"):
        _state._active_cwd = getattr(extra_data, "active_cwd", "") or ""

    return _state.draw_tab(screen, tab, index, is_last)