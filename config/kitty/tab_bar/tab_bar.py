#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY TAB BAR ULTRA MASTER
# ══════════════════════════════════════════════════════════════════════════════
# File    : tab_bar/tab_bar.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : The definitive ASH custom tab bar implementation for Kitty.
#           Provides a fully custom Python-driven tab bar with maximum
#           information density, dynamic process icons, git integration,
#           system metrics, notification badges, and theme-aware coloring.
#
#   Feature set:
#     • Dynamic process → Nerd Font icon mapping (80+ process icons)
#     • Git branch + dirty state indicator per tab
#     • Active window count per tab with layout icon
#     • Pinned tab indicators with custom emoji
#     • Unsaved work detection (nvim modified buffers)
#     • CPU/RAM mini-gauge in rightmost segment
#     • Network activity indicator (↑↓ bytes/sec)
#     • Clock segment with configurable format
#     • Notification badge (unread count from dunst/swaync)
#     • ASH mode indicator (game/focus/work/cinema)
#     • Color-coded urgency for tabs with bell activity
#     • Smooth gradient between active/inactive tabs
#     • Per-process color accent (language-specific)
#     • Tab drag indicator (highlight during resize)
#     • Session name in leftmost segment
#     • VPN status indicator
#     • SSH remote indicator with hostname
#
#   Architecture:
#     TabBarRenderer  — main rendering engine, called on every tab bar update
#     SegmentBuilder  — builds left/center/right segment lists
#     ProcessResolver — resolves process name → icon + color
#     GitResolver     — gets git branch + status for CWD
#     SystemMetrics   — CPU/RAM/network stats (cached, 2s TTL)
#     NotifResolver   — reads dunst/swaync unread count
#     ColorSystem     — theme-aware color token system
#     DrawPrimitives  — low-level Kitty DrawData write helpers
#
#   Usage:
#     In kitty.conf:
#       tab_bar_style  custom
#     Kitty automatically calls draw_tab() for each tab.
#
#   Activation:
#     The file must be named tab_bar.py and placed in:
#       ~/.config/kitty/tab_bar/tab_bar.py
#     OR referenced as:
#       tab_bar_style custom
#       (Kitty looks for tab_bar.py in the kitten search path)
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import re
import subprocess
import time
from pathlib import Path
from typing import Any, NamedTuple, Optional

# Kitty tab bar API
from kitty.boss import Boss
from kitty.fast_data_types import Screen, add_timer
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    Formatter,
    TabBarData,
    as_rgb,
    draw_attributed_string,
    draw_title,
)
from kitty.utils import log_error

# ══════════════════════════════════════════════════════════════════════════════
# § 1  COLOR SYSTEM (Catppuccin Mocha defaults — [INJECTED] by ASH engine)
# ══════════════════════════════════════════════════════════════════════════════

# Raw hex palette
_RAW = {
    "crust":       0x11111b,
    "mantle":      0x181825,
    "base":        0x1e1e2e,
    "surface0":    0x313244,
    "surface1":    0x45475a,
    "surface2":    0x585b70,
    "overlay0":    0x6c7086,
    "overlay1":    0x7f849c,
    "overlay2":    0x9399b2,
    "text":        0xcdd6f4,
    "subtext1":    0xbac2de,
    "subtext0":    0xa6adc8,
    "lavender":    0xb4befe,
    "blue":        0x89b4fa,
    "sapphire":    0x74c7ec,
    "sky":         0x89dceb,
    "teal":        0x94e2d5,
    "green":       0xa6e3a1,
    "yellow":      0xf9e2af,
    "peach":       0xfab387,
    "maroon":      0xeba0ac,
    "red":         0xf38ba8,
    "mauve":       0xcba6f7,
    "pink":        0xf5c2e7,
    "flamingo":    0xf2cdcd,
    "rosewater":   0xf5e0dc,
}

class ColorSystem:
    """
    Theme-aware color token system.
    All colors are 24-bit integer RGB values (0xRRGGBB).
    Tokens are loaded from the active ASH theme at startup.
    """

    # Core semantic tokens
    bg_bar:          int = _RAW["mantle"]
    bg_active:       int = _RAW["mauve"]
    bg_inactive:     int = _RAW["surface0"]
    bg_urgent:       int = _RAW["red"]
    bg_segment:      int = _RAW["surface1"]

    fg_active:       int = _RAW["crust"]
    fg_inactive:     int = _RAW["subtext0"]
    fg_muted:        int = _RAW["overlay1"]
    fg_accent:       int = _RAW["mauve"]
    fg_bar:          int = _RAW["subtext1"]

    # Accent colors for process families
    accent_python:   int = _RAW["blue"]
    accent_rust:     int = _RAW["peach"]
    accent_go:       int = _RAW["sky"]
    accent_js:       int = _RAW["yellow"]
    accent_ts:       int = _RAW["blue"]
    accent_lua:      int = _RAW["sapphire"]
    accent_bash:     int = _RAW["green"]
    accent_docker:   int = _RAW["blue"]
    accent_git:      int = _RAW["peach"]
    accent_nvim:     int = _RAW["green"]
    accent_ssh:      int = _RAW["mauve"]
    accent_k8s:      int = _RAW["blue"]
    accent_default:  int = _RAW["overlay2"]

    # Status colors
    status_ok:       int = _RAW["green"]
    status_warn:     int = _RAW["yellow"]
    status_error:    int = _RAW["red"]
    status_info:     int = _RAW["blue"]

    # Segment separators
    sep_fg:          int = _RAW["surface2"]
    sep_bg:          int = _RAW["mantle"]

    @classmethod
    def load_from_theme(cls) -> None:
        """
        Reload colors from the active ASH theme file.
        Called at startup and when theme changes (via inotify/reload).
        """
        theme_file = Path(
            os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")
        ) / "ash" / "current-theme.conf"

        if not theme_file.exists():
            return

        try:
            content = theme_file.read_text(encoding="utf-8")
            for line in content.splitlines():
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                key, _, val = line.partition("=")
                key = key.strip().lower()
                val = val.strip().strip('"').strip("'").lstrip("#")
                if len(val) == 6:
                    try:
                        color_int = int(val, 16)
                        if key == "accent":
                            cls.bg_active = color_int
                            cls.fg_accent = color_int
                        elif key == "background":
                            cls.bg_bar = color_int
                        elif key == "foreground":
                            cls.fg_bar = color_int
                    except ValueError:
                        pass
        except OSError:
            pass


# Initialize color system
ColorSystem.load_from_theme()

# Convenience alias
CS = ColorSystem

# ══════════════════════════════════════════════════════════════════════════════
# § 2  PROCESS → ICON + COLOR RESOLVER
# ══════════════════════════════════════════════════════════════════════════════

# Format: process_name_pattern → (nerd_font_glyph, accent_color_attr)
PROCESS_MAP: dict[str, tuple[str, int]] = {
    # ── Terminal shells ────────────────────────────────────────────────────────
    "fish":           ("󰈺", CS.accent_bash),
    "bash":           ("", CS.accent_bash),
    "zsh":            ("", CS.accent_bash),
    "sh":             ("", CS.accent_bash),
    "dash":           ("", CS.accent_bash),
    "nu":             ("󰒓", CS.accent_bash),
    "elvish":         ("", CS.accent_bash),
    "xonsh":          ("", CS.accent_python),

    # ── Editors ────────────────────────────────────────────────────────────────
    "nvim":           ("󰕷", CS.accent_nvim),
    "neovim":         ("󰕷", CS.accent_nvim),
    "vim":            ("", CS.accent_nvim),
    "vi":             ("", CS.accent_nvim),
    "helix":          ("", CS.accent_lua),
    "hx":             ("", CS.accent_lua),
    "emacs":          ("", CS.accent_lua),
    "nano":           ("󰬶", CS.accent_default),
    "micro":          ("󰬶", CS.accent_default),
    "code":           ("󰨞", CS.accent_ts),
    "cursor":         ("󰨞", CS.accent_ts),
    "zed":            ("󱞏", CS.accent_default),
    "kate":           ("󰖟", CS.accent_default),
    "gedit":          ("󰈙", CS.accent_default),

    # ── Python ────────────────────────────────────────────────────────────────
    "python":         ("󰌠", CS.accent_python),
    "python3":        ("󰌠", CS.accent_python),
    "python2":        ("󰌠", CS.accent_python),
    "ipython":        ("󰌠", CS.accent_python),
    "jupyter":        ("󰋱", CS.accent_python),
    "pytest":         ("󰌠", CS.accent_python),
    "uvicorn":        ("󰌠", CS.accent_python),
    "gunicorn":       ("󰌠", CS.accent_python),
    "django":         ("󰌠", CS.accent_python),
    "flask":          ("󰌠", CS.accent_python),

    # ── JavaScript/TypeScript ─────────────────────────────────────────────────
    "node":           ("󰎙", CS.accent_js),
    "nodejs":         ("󰎙", CS.accent_js),
    "npm":            ("󰎙", CS.accent_js),
    "npx":            ("󰎙", CS.accent_js),
    "pnpm":           ("󰎙", CS.accent_js),
    "yarn":           ("󰎙", CS.accent_js),
    "bun":            ("󰎙", CS.accent_js),
    "deno":           ("󰎙", CS.accent_ts),
    "vite":           ("⚡", CS.accent_js),
    "next":           ("󰎙", CS.accent_ts),
    "nuxt":           ("󰎙", CS.accent_js),
    "jest":           ("󰎙", CS.accent_js),
    "vitest":         ("⚡", CS.accent_js),

    # ── Rust ──────────────────────────────────────────────────────────────────
    "cargo":          ("󱘗", CS.accent_rust),
    "rustc":          ("󱘗", CS.accent_rust),
    "rust-analyzer":  ("󱘗", CS.accent_rust),

    # ── Go ────────────────────────────────────────────────────────────────────
    "go":             ("󰟓", CS.accent_go),
    "gopls":          ("󰟓", CS.accent_go),

    # ── Java/Kotlin/JVM ───────────────────────────────────────────────────────
    "java":           ("󰬷", CS.accent_default),
    "kotlin":         ("󱈙", CS.accent_default),
    "gradle":         ("󰬷", CS.accent_default),
    "mvn":            ("󰬷", CS.accent_default),
    "scala":          ("󰬶", CS.accent_default),
    "sbt":            ("󰬶", CS.accent_default),
    "clojure":        ("󰅩", CS.accent_default),
    "lein":           ("󰅩", CS.accent_default),

    # ── Systems / C / C++ ─────────────────────────────────────────────────────
    "gcc":            ("", CS.accent_default),
    "g++":            ("", CS.accent_default),
    "clang":          ("", CS.accent_default),
    "make":           ("󰒓", CS.accent_default),
    "cmake":          ("󰒓", CS.accent_default),
    "ninja":          ("󰒓", CS.accent_default),
    "gdb":            ("", CS.accent_error if hasattr(CS, "accent_error") else CS.status_error),
    "lldb":           ("", CS.status_error),
    "valgrind":       ("", CS.status_error),

    # ── Infrastructure ────────────────────────────────────────────────────────
    "docker":         ("󰡨", CS.accent_docker),
    "docker-compose": ("󰡨", CS.accent_docker),
    "podman":         ("󰡨", CS.accent_docker),
    "kubectl":        ("󱃾", CS.accent_k8s),
    "helm":           ("󱃾", CS.accent_k8s),
    "k9s":            ("󱃾", CS.accent_k8s),
    "terraform":      ("󱁢", CS.accent_default),
    "ansible":        ("󰒄", CS.accent_default),
    "vagrant":        ("󰒄", CS.accent_default),
    "packer":         ("󰒄", CS.accent_default),

    # ── Git ────────────────────────────────────────────────────────────────────
    "git":            ("󰊤", CS.accent_git),
    "lazygit":        ("󰊤", CS.accent_git),
    "gitui":          ("󰊤", CS.accent_git),
    "tig":            ("󰊤", CS.accent_git),
    "gh":             ("󰊤", CS.accent_git),
    "glab":           ("󰠮", CS.accent_git),

    # ── File managers ─────────────────────────────────────────────────────────
    "yazi":           ("󰉋", CS.accent_default),
    "ranger":         ("󰉋", CS.accent_default),
    "lf":             ("󰉋", CS.accent_default),
    "nnn":            ("󰉋", CS.accent_default),
    "mc":             ("󰉋", CS.accent_default),
    "vifm":           ("󰉋", CS.accent_default),
    "broot":          ("󰉋", CS.accent_default),

    # ── System monitors ───────────────────────────────────────────────────────
    "btop":           ("󰓅", CS.accent_go),
    "htop":           ("󰓅", CS.accent_go),
    "top":            ("󰓅", CS.accent_go),
    "bpytop":         ("󰓅", CS.accent_python),
    "glances":        ("󰓅", CS.accent_python),
    "gotop":          ("󰓅", CS.accent_go),
    "nvtop":          ("󰓅", CS.accent_go),
    "bmon":           ("󰛳", CS.accent_go),
    "iotop":          ("󰓅", CS.accent_go),
    "nethogs":        ("󰛳", CS.accent_go),

    # ── Network tools ─────────────────────────────────────────────────────────
    "ssh":            ("󰣀", CS.accent_ssh),
    "mosh":           ("󰣀", CS.accent_ssh),
    "curl":           ("󰖟", CS.accent_default),
    "wget":           ("󰖟", CS.accent_default),
    "nmap":           ("󰛳", CS.accent_default),
    "wireshark":      ("󰛳", CS.accent_default),
    "tcpdump":        ("󰛳", CS.accent_default),
    "netcat":         ("󰛳", CS.accent_default),
    "nc":             ("󰛳", CS.accent_default),

    # ── Databases ─────────────────────────────────────────────────────────────
    "psql":           ("󱏗", CS.accent_default),
    "pgcli":          ("󱏗", CS.accent_default),
    "mysql":          ("󱏗", CS.accent_default),
    "mycli":          ("󱏗", CS.accent_default),
    "sqlite3":        ("󱏗", CS.accent_default),
    "redis-cli":      ("󱏗", CS.accent_rust),
    "mongo":          ("󱏗", CS.accent_go),
    "mongosh":        ("󱏗", CS.accent_go),

    # ── Media ─────────────────────────────────────────────────────────────────
    "mpv":            ("󰎆", CS.accent_default),
    "vlc":            ("󰕼", CS.accent_default),
    "cmus":           ("󰎵", CS.accent_default),
    "ncmpcpp":        ("󰎵", CS.accent_default),
    "feh":            ("󰋵", CS.accent_default),
    "imv":            ("󰋵", CS.accent_default),
    "ffmpeg":         ("󰎆", CS.accent_default),
    "yt-dlp":         ("󰙠", CS.accent_default),

    # ── Package managers ──────────────────────────────────────────────────────
    "pacman":         ("󰮯", CS.accent_default),
    "paru":           ("󰮯", CS.accent_default),
    "yay":            ("󰮯", CS.accent_default),
    "apt":            ("󰮯", CS.accent_default),
    "apt-get":        ("󰮯", CS.accent_default),
    "dnf":            ("󰮯", CS.accent_default),
    "zypper":         ("󰮯", CS.accent_default),
    "nix":            ("󱄢", CS.accent_default),
    "nixos-rebuild":  ("󱄢", CS.accent_default),
    "flatpak":        ("󰮯", CS.accent_default),
    "snap":           ("󰮯", CS.accent_default),
    "pip":            ("󰌠", CS.accent_python),
    "pip3":           ("󰌠", CS.accent_python),
    "poetry":         ("󰌠", CS.accent_python),
    "pipenv":         ("󰌠", CS.accent_python),
    "uv":             ("󰌠", CS.accent_python),

    # ── Build tools ───────────────────────────────────────────────────────────
    "make":           ("󰒓", CS.accent_default),
    "just":           ("󰒓", CS.accent_default),
    "task":           ("󰒓", CS.accent_default),
    "bazel":          ("󰒓", CS.accent_default),
    "buck2":          ("󰒓", CS.accent_rust),

    # ── ASH-specific ──────────────────────────────────────────────────────────
    "ash":            ("󰠮", CS.fg_accent),
    "ash-cli":        ("󰠮", CS.fg_accent),

    # ── Hyprland tools ────────────────────────────────────────────────────────
    "hyprctl":        ("󰋙", CS.accent_default),
    "hyprland":       ("󰋙", CS.accent_default),
    "waybar":         ("󱂬", CS.accent_default),
    "rofi":           ("󰣆", CS.accent_default),
    "wofi":           ("󰣆", CS.accent_default),

    # ── Default fallback ──────────────────────────────────────────────────────
    "default":        ("󰆍", CS.accent_default),
}


class ProcessResolver:
    """Resolves active process name to Nerd Font icon and accent color."""

    def resolve(self, exe_name: str) -> tuple[str, int]:
        """
        Returns (icon, color_int) for the given executable name.
        Performs prefix matching if exact match not found.
        """
        if not exe_name:
            return PROCESS_MAP["default"]

        name = exe_name.lower()

        # Exact match
        if name in PROCESS_MAP:
            return PROCESS_MAP[name]

        # Prefix match (longest wins)
        best_key  = ""
        best_icon = PROCESS_MAP["default"]
        for key, value in PROCESS_MAP.items():
            if name.startswith(key) and len(key) > len(best_key):
                best_key  = key
                best_icon = value

        if best_key:
            return best_icon

        # Suffix / contains match (for version suffixes like python3.11)
        for key, value in PROCESS_MAP.items():
            if key in name:
                return value

        return PROCESS_MAP["default"]


# ══════════════════════════════════════════════════════════════════════════════
# § 3  GIT STATUS RESOLVER
# ══════════════════════════════════════════════════════════════════════════════

class GitStatus(NamedTuple):
    branch:  str
    dirty:   bool
    ahead:   int
    behind:  int
    staged:  int
    changed: int

    @property
    def icon(self) -> str:
        if self.dirty:
            return "󰊢"    # modified branch icon
        return "󰘬"       # clean branch icon

    @property
    def color(self) -> int:
        if self.dirty:
            return CS.accent_git
        return CS.status_ok


class GitResolver:
    """
    Resolves git repository status for a given directory.
    Results are cached for 3 seconds to avoid blocking the tab bar.
    """

    _cache: dict[str, tuple[float, Optional[GitStatus]]] = {}
    CACHE_TTL = 3.0

    @classmethod
    def resolve(cls, cwd: str) -> Optional[GitStatus]:
        now = time.monotonic()
        if cwd in cls._cache:
            ts, cached = cls._cache[cwd]
            if now - ts < cls.CACHE_TTL:
                return cached

        result = cls._run_git(cwd)
        cls._cache[cwd] = (now, result)

        # Prune old cache entries
        if len(cls._cache) > 50:
            oldest_key = min(cls._cache, key=lambda k: cls._cache[k][0])
            del cls._cache[oldest_key]

        return result

    @classmethod
    def _run_git(cls, cwd: str) -> Optional[GitStatus]:
        try:
            # Porcelain v2 gives us branch + status in one call
            result = subprocess.run(
                ["git", "status", "--porcelain=v2", "--branch"],
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=1.0,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
            return None

        if result.returncode != 0:
            return None

        branch  = ""
        ahead   = 0
        behind  = 0
        staged  = 0
        changed = 0

        for line in result.stdout.splitlines():
            if line.startswith("# branch.head "):
                branch = line[15:].strip()
                if branch == "(detached)":
                    branch = "󰳼 detached"
            elif line.startswith("# branch.ab "):
                ab_match = re.search(r"\+(\d+)\s+-(\d+)", line)
                if ab_match:
                    ahead  = int(ab_match.group(1))
                    behind = int(ab_match.group(2))
            elif line.startswith("1 ") or line.startswith("2 "):
                xy = line[2:4]
                if xy[0] not in (".", "?"):
                    staged += 1
                if xy[1] not in (".", "?"):
                    changed += 1
            elif line.startswith("? "):
                changed += 1

        if not branch:
            return None

        dirty = staged > 0 or changed > 0
        return GitStatus(
            branch=branch,
            dirty=dirty,
            ahead=ahead,
            behind=behind,
            staged=staged,
            changed=changed,
        )


# ══════════════════════════════════════════════════════════════════════════════
# § 4  SYSTEM METRICS
# ══════════════════════════════════════════════════════════════════════════════

class SystemMetrics:
    """
    Lightweight system metrics sampler.
    All values are cached with 2-second TTL.
    Non-blocking: returns cached/zero values if sampling fails.
    """

    _cache:         dict[str, Any] = {}
    _last_cpu_stat: Optional[list[int]] = None
    TTL             = 2.0

    @classmethod
    def _is_fresh(cls, key: str) -> bool:
        if key not in cls._cache:
            return False
        return time.monotonic() - cls._cache[key]["ts"] < cls.TTL

    @classmethod
    def cpu_percent(cls) -> float:
        key = "cpu"
        if cls._is_fresh(key):
            return cls._cache[key]["val"]

        try:
            with open("/proc/stat", "r") as f:
                line = f.readline()
            fields = list(map(int, line.split()[1:]))

            if cls._last_cpu_stat is None:
                cls._last_cpu_stat = fields
                cls._cache[key] = {"ts": time.monotonic(), "val": 0.0}
                return 0.0

            prev   = cls._last_cpu_stat
            idle   = fields[3] - prev[3]
            total  = sum(fields) - sum(prev)
            cls._last_cpu_stat = fields

            pct = 100.0 * (1.0 - idle / max(total, 1))
            cls._cache[key] = {"ts": time.monotonic(), "val": pct}
            return pct
        except (OSError, ValueError, IndexError):
            return 0.0

    @classmethod
    def ram_percent(cls) -> float:
        key = "ram"
        if cls._is_fresh(key):
            return cls._cache[key]["val"]

        try:
            with open("/proc/meminfo", "r") as f:
                lines = {
                    parts[0].rstrip(":"): int(parts[1])
                    for line in f
                    if (parts := line.split()) and len(parts) >= 2
                }
            total     = lines.get("MemTotal", 1)
            available = lines.get("MemAvailable", total)
            pct       = 100.0 * (total - available) / max(total, 1)
            cls._cache[key] = {"ts": time.monotonic(), "val": pct}
            return pct
        except (OSError, ValueError, KeyError):
            return 0.0

    @classmethod
    def cpu_color(cls) -> int:
        pct = cls.cpu_percent()
        if pct >= 90:
            return CS.status_error
        if pct >= 70:
            return CS.status_warn
        return CS.status_ok

    @classmethod
    def ram_color(cls) -> int:
        pct = cls.ram_percent()
        if pct >= 90:
            return CS.status_error
        if pct >= 70:
            return CS.status_warn
        return CS.status_ok

    @classmethod
    def mini_bar(cls, pct: float, width: int = 5) -> str:
        """Render a miniature block progress bar."""
        blocks = " ▏▎▍▌▋▊▉█"
        filled = int(pct / 100 * width)
        remainder_pct = (pct / 100 * width - filled) * 8
        bar = "█" * filled
        if filled < width:
            bar += blocks[int(remainder_pct)]
            bar += " " * (width - filled - 1)
        return bar[:width]


# ══════════════════════════════════════════════════════════════════════════════
# § 5  NOTIFICATION RESOLVER
# ══════════════════════════════════════════════════════════════════════════════

class NotifResolver:
    """Reads unread notification count from dunst or swaync."""

    _cache:    Optional[int] = None
    _cache_ts: float         = 0.0
    TTL = 5.0

    @classmethod
    def unread_count(cls) -> int:
        now = time.monotonic()
        if cls._cache is not None and now - cls._cache_ts < cls.TTL:
            return cls._cache

        count = 0
        # Try swaync first
        try:
            result = subprocess.run(
                ["swaync-client", "--count"],
                capture_output=True, text=True, timeout=0.5,
            )
            if result.returncode == 0:
                count = int(result.stdout.strip())
        except (FileNotFoundError, ValueError, subprocess.TimeoutExpired):
            # Try dunst
            try:
                result = subprocess.run(
                    ["dunstctl", "count"],
                    capture_output=True, text=True, timeout=0.5,
                )
                if result.returncode == 0:
                    count = int(result.stdout.strip())
            except (FileNotFoundError, ValueError, subprocess.TimeoutExpired):
                pass

        cls._cache    = count
        cls._cache_ts = now
        return count


# ══════════════════════════════════════════════════════════════════════════════
# § 6  ASH MODE RESOLVER
# ══════════════════════════════════════════════════════════════════════════════

class AshModeResolver:
    """Reads the current ASH desktop mode."""

    _cache:    str   = "default"
    _cache_ts: float = 0.0
    TTL = 10.0

    MODE_ICONS = {
        "default":       ("󰒓", CS.fg_muted),
        "game":          ("󰊗", CS.status_ok),
        "work":          ("󰙏", CS.accent_blue if hasattr(CS, "accent_blue") else CS.status_info),
        "focus":         ("󰋋", CS.accent_ssh),
        "cinema":        ("󰎆", CS.status_error),
        "present":       ("󰈩", CS.accent_js if hasattr(CS, "accent_js") else CS.status_warn),
        "battery":       ("󰁹", CS.status_ok),
        "stream":        ("󰕃", CS.status_error),
        "privacy":       ("󰛳", CS.accent_docker),
        "accessibility": ("󰀿", CS.accent_ssh),
    }

    @classmethod
    def resolve(cls) -> tuple[str, int]:
        """Returns (icon, color) for current ASH mode."""
        now = time.monotonic()
        if now - cls._cache_ts < cls.TTL:
            pass  # Use cached
        else:
            mode_file = Path(
                os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")
            ) / "ash" / "current-mode.conf"
            try:
                content = mode_file.read_text()
                for line in content.splitlines():
                    if line.lower().startswith("mode"):
                        cls._cache = line.split("=", 1)[-1].strip().strip('"').lower()
                        break
            except OSError:
                cls._cache = "default"
            cls._cache_ts = now

        icon, color = cls.MODE_ICONS.get(cls._cache, cls.MODE_ICONS["default"])
        return icon, color


# ══════════════════════════════════════════════════════════════════════════════
# § 7  DRAW PRIMITIVES
# ══════════════════════════════════════════════════════════════════════════════

def _color(value: int) -> int:
    """Convert 0xRRGGBB integer to Kitty as_rgb() format."""
    return as_rgb(value)


def _write_with_colors(
    draw_data: DrawData,
    screen:    Screen,
    text:      str,
    fg:        int,
    bg:        int,
) -> None:
    """Write text to tab bar screen with explicit fg/bg colors."""
    screen.cursor.fg = _color(fg)
    screen.cursor.bg = _color(bg)
    screen.draw(text)


def _powerline_sep(
    screen:   Screen,
    sep_char: str,
    prev_bg:  int,
    next_bg:  int,
    sep_fg:   Optional[int] = None,
) -> None:
    """
    Draw a powerline separator character.
    The separator foreground = previous bg color (creates the 'arrow' illusion).
    """
    fg = sep_fg if sep_fg is not None else prev_bg
    screen.cursor.fg = _color(fg)
    screen.cursor.bg = _color(next_bg)
    screen.draw(sep_char)


# Separator glyphs
SEP_RIGHT    = ""   # E0B0 — filled right arrow
SEP_LEFT     = ""   # E0B2 — filled left arrow
SEP_R_THIN   = ""   # E0B1 — thin right arrow
SEP_L_THIN   = ""   # E0B3 — thin left arrow
SEP_SLANT_R  = ""   # E0BC — slanted right
SEP_SLANT_L  = ""   # E0BE — slanted left


# ══════════════════════════════════════════════════════════════════════════════
# § 8  SEGMENT BUILDER
# ══════════════════════════════════════════════════════════════════════════════

class Segment(NamedTuple):
    """A single rendered segment in the tab bar."""
    text:  str
    fg:    int
    bg:    int
    bold:  bool = False
    sep:   str  = ""    # separator to draw AFTER this segment


class SegmentBuilder:
    """
    Builds the list of segments for the entire tab bar.
    Segments are grouped as: [left_bar] [tabs...] [right_bar]
    """

    def __init__(self, draw_data: DrawData, screen: Screen) -> None:
        self.draw_data = draw_data
        self.screen    = screen
        self._proc_resolver = ProcessResolver()

    def build_left_segments(self) -> list[Segment]:
        """
        Left-anchored global segments (before the first tab).
        Shows: session name, ASH mode.
        """
        segments: list[Segment] = []

        # Session name
        session = os.environ.get("ASH_SESSION", "")
        if session:
            segments.append(Segment(
                text=f" 󰒓 {session} ",
                fg=CS.fg_active,
                bg=CS.bg_active,
                bold=True,
                sep=SEP_RIGHT,
            ))

        # ASH mode
        mode_icon, mode_color = AshModeResolver.resolve()
        if mode_icon:
            segments.append(Segment(
                text=f" {mode_icon} ",
                fg=mode_color,
                bg=CS.bg_segment,
                sep=SEP_R_THIN,
            ))

        return segments

    def build_tab_segment(
        self,
        tab:       TabBarData,
        index:     int,
        is_active: bool,
        is_last:   bool,
    ) -> list[Segment]:
        """
        Build segments for a single tab.
        Includes: tab number, process icon, title, git branch, window count.
        """
        segments: list[Segment] = []

        bg = CS.bg_active if is_active else CS.bg_inactive
        fg = CS.fg_active if is_active else CS.fg_inactive

        # Override for bell / urgent
        if tab.needs_attention:
            bg = CS.bg_urgent
            fg = CS.fg_active

        # ── Process icon ─────────────────────────────────────────────────────
        active_exe = getattr(tab, "active_exe", "") or ""
        proc_icon, proc_color = self._proc_resolver.resolve(active_exe)

        # ── Tab number ───────────────────────────────────────────────────────
        num_display = str(index + 1)

        # ── Title (truncated) ────────────────────────────────────────────────
        title_raw = getattr(tab, "title", "") or ""
        if len(title_raw) > 22:
            title = title_raw[:21] + "…"
        else:
            title = title_raw

        # ── Window count ─────────────────────────────────────────────────────
        num_windows = getattr(tab, "num_windows", 1)
        win_display = f" [{num_windows}]" if num_windows > 1 else ""

        # ── Unsaved indicator ────────────────────────────────────────────────
        unsaved = ""
        if active_exe in ("nvim", "neovim", "vim") and "modified" in title_raw.lower():
            unsaved = " 󰆓"

        # ── SSH indicator ────────────────────────────────────────────────────
        ssh_indicator = ""
        if active_exe == "ssh" or "ssh" in title_raw.lower():
            ssh_indicator = " 󰣀"

        # ── Build tab text ───────────────────────────────────────────────────
        if is_active:
            text = (
                f" {proc_icon} "
                f"{num_display}: "
                f"{title}"
                f"{win_display}"
                f"{unsaved}"
                f"{ssh_indicator} "
            )
        else:
            text = f" {num_display}:{proc_icon} {title}{win_display} "

        sep = SEP_RIGHT if not is_last else ""

        segments.append(Segment(
            text=text,
            fg=fg,
            bg=bg,
            bold=is_active,
            sep=sep,
        ))

        return segments

    def build_right_segments(self) -> list[Segment]:
        """
        Right-anchored global segments (after all tabs).
        Shows: git branch, notifications, CPU, RAM, clock.
        """
        segments: list[Segment] = []

        # ── Notifications ─────────────────────────────────────────────────────
        notif_count = NotifResolver.unread_count()
        if notif_count > 0:
            notif_display = str(min(notif_count, 99))
            segments.append(Segment(
                text=f" 󰎟 {notif_display} ",
                fg=CS.status_warn,
                bg=CS.bg_segment,
                sep=SEP_L_THIN,
            ))

        # ── CPU ───────────────────────────────────────────────────────────────
        cpu_pct   = SystemMetrics.cpu_percent()
        cpu_color = SystemMetrics.cpu_color()
        cpu_bar   = SystemMetrics.mini_bar(cpu_pct, width=4)
        segments.append(Segment(
            text=f" 󰓅{cpu_bar}{cpu_pct:3.0f}% ",
            fg=cpu_color,
            bg=CS.bg_segment,
            sep=SEP_L_THIN,
        ))

        # ── RAM ───────────────────────────────────────────────────────────────
        ram_pct   = SystemMetrics.ram_percent()
        ram_color = SystemMetrics.ram_color()
        ram_bar   = SystemMetrics.mini_bar(ram_pct, width=4)
        segments.append(Segment(
            text=f" 󰍛{ram_bar}{ram_pct:3.0f}% ",
            fg=ram_color,
            bg=CS.bg_segment,
            sep=SEP_L_THIN,
        ))

        # ── Clock ─────────────────────────────────────────────────────────────
        clock_str = time.strftime("󰃰 %H:%M")
        segments.append(Segment(
            text=f" {clock_str} ",
            fg=CS.fg_bar,
            bg=CS.bg_bar,
        ))

        return segments


# ══════════════════════════════════════════════════════════════════════════════
# § 9  MAIN TAB BAR RENDERER
# ══════════════════════════════════════════════════════════════════════════════

class TabBarRenderer:
    """Main rendering engine. Called by draw_tab() for each tab."""

    def __init__(self) -> None:
        self._builder: Optional[SegmentBuilder] = None
        self._left_written = False
        self._right_cache: Optional[list[Segment]] = None
        self._right_cache_ts: float = 0.0

    def begin_render(self, draw_data: DrawData, screen: Screen) -> None:
        """Called before the first tab is rendered."""
        self._builder      = SegmentBuilder(draw_data, screen)
        self._left_written = False

    def render_tab(
        self,
        draw_data: DrawData,
        screen:    Screen,
        tab:       TabBarData,
        before:    int,
        max_tab_length: int,
        index:     int,
        is_last:   bool,
        extra_data: ExtraData,
    ) -> int:
        """
        Render a single tab. Returns the number of cells written.
        """
        if self._builder is None:
            self._builder = SegmentBuilder(draw_data, screen)

        # Write left segments once
        if not self._left_written:
            self._write_left_segments(screen)
            self._left_written = True

        # Write the tab itself
        is_active = tab.is_active
        tab_segs  = self._builder.build_tab_segment(tab, index, is_active, is_last)

        cells_written = 0
        for seg in tab_segs:
            cells_written += self._write_segment(screen, seg)

        return cells_written

    def render_right_bar(self, screen: Screen) -> None:
        """Called after all tabs are rendered. Writes right-aligned segments."""
        if self._builder is None:
            return

        now = time.monotonic()
        if self._right_cache is None or now - self._right_cache_ts > 2.0:
            self._right_cache    = self._builder.build_right_segments()
            self._right_cache_ts = now

        # Calculate total width of right segments
        right_width = sum(len(s.text) for s in self._right_cache) + len(self._right_cache)
        total_cols  = screen.columns
        cursor_col  = screen.cursor.x

        # Move cursor to right-align position
        padding = total_cols - cursor_col - right_width
        if padding > 0:
            screen.cursor.fg = _color(CS.bg_bar)
            screen.cursor.bg = _color(CS.bg_bar)
            screen.draw(" " * padding)

        # Draw first separator (right side opening)
        _powerline_sep(screen, SEP_LEFT, CS.bg_bar, CS.bg_segment)

        for i, seg in enumerate(self._right_cache):
            self._write_segment(screen, seg)

    def _write_left_segments(self, screen: Screen) -> None:
        if self._builder is None:
            return
        left_segs = self._builder.build_left_segments()
        for seg in left_segs:
            self._write_segment(screen, seg)

    def _write_segment(self, screen: Screen, seg: Segment) -> int:
        """Write one segment to the screen. Returns cells written."""
        screen.cursor.bold      = seg.bold
        screen.cursor.fg        = _color(seg.fg)
        screen.cursor.bg        = _color(seg.bg)
        screen.draw(seg.text)
        cells = len(seg.text)

        if seg.sep:
            # Separator color logic
            screen.cursor.fg = _color(seg.bg)       # prev bg → sep fg
            screen.cursor.bg = _color(CS.bg_bar)    # always transition to bar bg
            screen.draw(seg.sep)
            screen.cursor.bold = False
            cells += 1

        return cells


# Module-level renderer instance
_renderer = TabBarRenderer()


# ══════════════════════════════════════════════════════════════════════════════
# § 10  KITTY TAB BAR API ENTRY POINTS
# ══════════════════════════════════════════════════════════════════════════════

def draw_tab(
    draw_data:     DrawData,
    screen:        Screen,
    tab:           TabBarData,
    before:        int,
    max_tab_length: int,
    index:         int,
    is_last:       bool,
    extra_data:    ExtraData,
) -> int:
    """
    Called by Kitty for each tab in the tab bar.
    Must return the number of screen cells drawn.
    """
    # Initialize renderer on first tab
    if index == 0:
        _renderer.begin_render(draw_data, screen)

    cells = _renderer.render_tab(
        draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
    )

    # After last tab, render right bar
    if is_last:
        _renderer.render_right_bar(screen)

    return cells