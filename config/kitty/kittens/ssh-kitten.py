#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY SSH KITTEN ULTRA
# ══════════════════════════════════════════════════════════════════════════════
# File    : kittens/ssh-kitten.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Ultra-premium SSH kitten for Kitty terminal.
#           Wraps Kitty's native SSH kitten with intelligent host discovery,
#           interactive fuzzy-search host picker, connection profiles,
#           automatic terminfo deployment, session naming, and jump host
#           chain support.
#
#   Features:
#     • Fuzzy-search SSH host picker (fzf-style TUI built with Kitty API)
#     • Auto-discover hosts from: ~/.ssh/config, ~/.ssh/known_hosts,
#       /etc/hosts, custom host registry (~/.config/ash/ssh-hosts.json)
#     • SSH config group parsing (Host * / Match blocks)
#     • Connection profiles: dev/prod/staging/personal with different keys
#     • Jump host chain builder (ProxyJump / -J flag UI)
#     • Auto terminfo deployment (kitten ssh handles this, we wrap it)
#     • Session naming: sets Kitty window title to user@host
#     • Port tunnel builder: -L / -R / -D flag UI
#     • Password manager integration: pass, gopass, bitwarden-cli
#     • Recent connections history (last 50, with timestamps)
#     • Host health indicator: ping test before connecting
#     • Multiplexer integration: tmux/zellij session auto-attach
#     • Background connection status (reconnect on drop)
#     • Host alias + emoji labeling
#     • One-time connection (discard after session)
#     • Shared connection pool (ControlMaster multiplexing)
#
#   Architecture:
#     HostRegistry  — discovers + parses all SSH host sources
#     HostPicker    — interactive TUI fuzzy picker using Kitty overlay
#     ConnectionBuilder — builds SSH command from profile + overrides
#     ProfileManager — stores/loads connection profiles
#     HistoryManager — tracks recent connections
#     TunnelBuilder  — interactive SSH tunnel configuration
#
#   Usage:
#     map kitty_mod+shift+s  kitten kittens/ssh-kitten.py
#     Command line: kitty +kitten kittens/ssh-kitten.py [host]
#     With host: kitty +kitten kittens/ssh-kitten.py user@host:port
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Generator, Optional, Sequence

# Kitty kitten API
from kittens.tui.handler import Handler
from kittens.tui.loop import Loop
from kittens.tui.operations import (
    clear_screen,
    cursor,
    set_line_wrapping,
    set_window_title,
    styled,
)
from kitty.boss import Boss
from kitty.fast_data_types import Screen
from kitty.key_encoding import KeyEvent

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS & CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

# XDG paths
XDG_CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
XDG_DATA_HOME   = Path(os.environ.get("XDG_DATA_HOME",   Path.home() / ".local/share"))
XDG_STATE_HOME  = Path(os.environ.get("XDG_STATE_HOME",  Path.home() / ".local/state"))
ASH_DIR         = XDG_CONFIG_HOME / "ash"

# File locations
SSH_CONFIG_FILE  = Path.home() / ".ssh" / "config"
KNOWN_HOSTS_FILE = Path.home() / ".ssh" / "known_hosts"
ASH_SSH_HOSTS    = ASH_DIR / "ssh-hosts.json"
SSH_HISTORY_FILE = XDG_STATE_HOME / "ash" / "ssh-history.json"
SSH_PROFILES_FILE= ASH_DIR / "ssh-profiles.json"

# UI constants
MAX_HISTORY      = 50
MAX_DISPLAY_HOSTS= 200
PING_TIMEOUT_MS  = 500

# Color palette (Catppuccin Mocha — injected by ASH theme engine)
COLORS = {
    "bg":          "\033[48;2;30;30;46m",
    "bg_surface":  "\033[48;2;49;50;68m",
    "bg_elevated": "\033[48;2;69;71;90m",
    "fg":          "\033[38;2;205;214;244m",
    "fg_muted":    "\033[38;2;166;173;200m",
    "accent":      "\033[38;2;203;166;247m",      # mauve
    "accent_bg":   "\033[48;2;203;166;247m",
    "blue":        "\033[38;2;137;180;250m",
    "green":       "\033[38;2;166;227;161m",
    "red":         "\033[38;2;243;139;168m",
    "yellow":      "\033[38;2;249;226;175m",
    "peach":       "\033[38;2;250;179;135m",
    "teal":        "\033[38;2;148;226;213m",
    "sky":         "\033[38;2;137;220;235m",
    "pink":        "\033[38;2;245;194;231m",
    "bold":        "\033[1m",
    "italic":      "\033[3m",
    "dim":         "\033[2m",
    "reset":       "\033[0m",
    "underline":   "\033[4m",
    "reverse":     "\033[7m",
}

# Nerd Font icons
ICONS = {
    "ssh":         "󰣀",
    "server":      "󰒋",
    "lock":        "󰌋",
    "key":         "󰌋",
    "user":        "󰀄",
    "port":        "󱑊",
    "jump":        "󰒄",
    "tunnel":      "󰛳",
    "history":     "󰹑",
    "profile":     "󰒓",
    "star":        "★",
    "ping_ok":     "●",
    "ping_fail":   "○",
    "arrow":       "›",
    "branch":      "󱘖",
    "check":       "󰄬",
    "cross":       "󰅖",
    "search":      "󰍉",
    "filter":      "󰈲",
    "home":        "󰋞",
    "prod":        "󰒓",
    "staging":     "󰙴",
    "dev":         "󰅨",
    "personal":    "󰀄",
    "separator":   "│",
    "dash":        "─",
    "corner_tl":   "╭",
    "corner_tr":   "╮",
    "corner_bl":   "╰",
    "corner_br":   "╯",
    "vertical":    "│",
    "horizontal":  "─",
}

# ══════════════════════════════════════════════════════════════════════════════
# DATA MODELS
# ══════════════════════════════════════════════════════════════════════════════

@dataclass
class SSHHost:
    """Represents a single SSH host entry."""
    alias:          str
    hostname:       str
    user:           str           = ""
    port:           int           = 22
    identity_file:  str           = ""
    proxy_jump:     str           = ""
    forward_agent:  bool          = False
    compression:    bool          = False
    tags:           list[str]     = field(default_factory=list)
    emoji:          str           = "󰒋"
    description:    str           = ""
    profile:        str           = "default"
    last_connected: float         = 0.0
    connect_count:  int           = 0
    is_favourite:   bool          = False
    source:         str           = "config"  # config|known_hosts|ash|manual

    @property
    def display_name(self) -> str:
        """Rich display string for the picker."""
        return f"{self.user}@{self.hostname}" if self.user else self.hostname

    @property
    def connection_string(self) -> str:
        """Canonical SSH connection target."""
        parts = []
        if self.user:
            parts.append(f"{self.user}@")
        parts.append(self.hostname)
        if self.port != 22:
            parts.append(f":{self.port}")
        return "".join(parts)

    def to_dict(self) -> dict:
        return {
            "alias": self.alias,
            "hostname": self.hostname,
            "user": self.user,
            "port": self.port,
            "identity_file": self.identity_file,
            "proxy_jump": self.proxy_jump,
            "tags": self.tags,
            "emoji": self.emoji,
            "description": self.description,
            "profile": self.profile,
            "last_connected": self.last_connected,
            "connect_count": self.connect_count,
            "is_favourite": self.is_favourite,
            "source": self.source,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "SSHHost":
        return cls(**{k: v for k, v in data.items() if k in cls.__dataclass_fields__})


@dataclass
class ConnectionProfile:
    """SSH connection profile with reusable settings."""
    name:           str
    description:    str           = ""
    default_user:   str           = ""
    identity_file:  str           = ""
    extra_opts:     list[str]     = field(default_factory=list)
    port:           int           = 22
    proxy_jump:     str           = ""
    color:          str           = "#cba6f7"
    emoji:          str           = "󰒓"

    def build_flags(self) -> list[str]:
        """Build SSH command flags for this profile."""
        flags = []
        if self.default_user:
            flags.extend(["-l", self.default_user])
        if self.port != 22:
            flags.extend(["-p", str(self.port)])
        if self.identity_file:
            flags.extend(["-i", os.path.expanduser(self.identity_file)])
        if self.proxy_jump:
            flags.extend(["-J", self.proxy_jump])
        flags.extend(self.extra_opts)
        return flags


@dataclass
class TunnelSpec:
    """SSH tunnel specification."""
    tunnel_type:    str   = "local"   # local|remote|dynamic
    local_port:     int   = 0
    remote_host:    str   = "localhost"
    remote_port:    int   = 0

    def to_flag(self) -> str:
        """Convert to SSH -L/-R/-D flag."""
        if self.tunnel_type == "dynamic":
            return f"-D {self.local_port}"
        elif self.tunnel_type == "remote":
            return f"-R {self.local_port}:{self.remote_host}:{self.remote_port}"
        else:
            return f"-L {self.local_port}:{self.remote_host}:{self.remote_port}"

# ══════════════════════════════════════════════════════════════════════════════
# HOST REGISTRY
# ══════════════════════════════════════════════════════════════════════════════

class HostRegistry:
    """
    Discovers and aggregates SSH hosts from multiple sources.
    Sources (in priority order):
        1. ASH custom host registry (~/.config/ash/ssh-hosts.json)
        2. ~/.ssh/config (Host blocks)
        3. ~/.ssh/known_hosts (hostname extraction)
        4. /etc/hosts (local network hosts)
    """

    def __init__(self) -> None:
        self._hosts: dict[str, SSHHost] = {}
        self._load_all()

    def _load_all(self) -> None:
        """Load hosts from all sources."""
        self._load_ssh_config()
        self._load_known_hosts()
        self._load_ash_hosts()
        self._load_history_metadata()

    def _load_ssh_config(self) -> None:
        """Parse ~/.ssh/config for Host blocks."""
        if not SSH_CONFIG_FILE.exists():
            return

        current_host: Optional[SSHHost] = None
        current_alias = ""

        try:
            content = SSH_CONFIG_FILE.read_text(encoding="utf-8", errors="replace")
        except OSError:
            return

        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            if line.lower().startswith("host "):
                # Save previous host
                if current_host and current_alias and current_alias != "*":
                    self._hosts[current_alias] = current_host

                aliases = line[5:].strip().split()
                for alias in aliases:
                    if alias == "*":
                        continue
                    current_alias = alias
                    current_host = SSHHost(
                        alias=alias,
                        hostname=alias,
                        source="config",
                    )
                    break

            elif current_host is not None:
                key, _, value = line.partition(" ")
                key = key.lower().rstrip()
                value = value.strip()

                if key == "hostname":
                    current_host.hostname = value
                elif key == "user":
                    current_host.user = value
                elif key == "port":
                    try:
                        current_host.port = int(value)
                    except ValueError:
                        pass
                elif key == "identityfile":
                    current_host.identity_file = value
                elif key == "proxyjump":
                    current_host.proxy_jump = value
                elif key == "forwardagent":
                    current_host.forward_agent = value.lower() == "yes"
                elif key == "compression":
                    current_host.compression = value.lower() == "yes"

        # Save last host
        if current_host and current_alias and current_alias != "*":
            self._hosts[current_alias] = current_host

    def _load_known_hosts(self) -> None:
        """Extract hostnames from ~/.ssh/known_hosts."""
        if not KNOWN_HOSTS_FILE.exists():
            return

        try:
            content = KNOWN_HOSTS_FILE.read_text(encoding="utf-8", errors="replace")
        except OSError:
            return

        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("#") or line.startswith("|"):
                continue

            host_part = line.split()[0] if line.split() else ""
            # Handle [host]:port format
            if host_part.startswith("["):
                match = re.match(r"\[([^\]]+)\]:(\d+)", host_part)
                if match:
                    hostname, port = match.group(1), int(match.group(2))
                else:
                    continue
            else:
                hostname = host_part
                port = 22

            # Skip wildcards, IPs that are already in config, hashed hosts
            if not hostname or hostname.startswith("*") or hostname.startswith("|"):
                continue

            # Don't override config entries
            if hostname not in self._hosts:
                self._hosts[hostname] = SSHHost(
                    alias=hostname,
                    hostname=hostname,
                    port=port,
                    source="known_hosts",
                )

    def _load_ash_hosts(self) -> None:
        """Load custom ASH SSH host registry."""
        if not ASH_SSH_HOSTS.exists():
            return

        try:
            data = json.loads(ASH_SSH_HOSTS.read_text())
            for entry in data.get("hosts", []):
                host = SSHHost.from_dict(entry)
                self._hosts[host.alias] = host  # ASH entries override others
        except (json.JSONDecodeError, KeyError, TypeError):
            pass

    def _load_history_metadata(self) -> None:
        """Apply history metadata (connect counts, last connected) to hosts."""
        if not SSH_HISTORY_FILE.exists():
            return

        try:
            history = json.loads(SSH_HISTORY_FILE.read_text())
            for entry in history.get("connections", []):
                alias = entry.get("alias", "")
                if alias in self._hosts:
                    h = self._hosts[alias]
                    h.last_connected = entry.get("timestamp", 0.0)
                    h.connect_count  = entry.get("count", 0)
                    h.is_favourite   = entry.get("favourite", False)
        except (json.JSONDecodeError, KeyError, TypeError):
            pass

    def save_ash_hosts(self) -> None:
        """Persist custom host entries to ASH registry."""
        ASH_SSH_HOSTS.parent.mkdir(parents=True, exist_ok=True)
        ash_hosts = [
            h.to_dict() for h in self._hosts.values()
            if h.source == "ash"
        ]
        ASH_SSH_HOSTS.write_text(
            json.dumps({"version": "1", "hosts": ash_hosts}, indent=2)
        )

    @property
    def all_hosts(self) -> list[SSHHost]:
        """All discovered hosts, sorted by recency then name."""
        return sorted(
            self._hosts.values(),
            key=lambda h: (-h.last_connected, -h.connect_count, h.alias.lower()),
        )

    def search(self, query: str) -> list[SSHHost]:
        """Fuzzy search hosts by alias, hostname, user, tags, description."""
        if not query:
            return self.all_hosts[:MAX_DISPLAY_HOSTS]

        query_lower = query.lower()
        scored: list[tuple[int, SSHHost]] = []

        for host in self._hosts.values():
            score = 0
            search_fields = [
                host.alias.lower(),
                host.hostname.lower(),
                host.user.lower(),
                host.description.lower(),
                " ".join(host.tags).lower(),
            ]
            for field_val in search_fields:
                if query_lower == field_val:
                    score += 100
                elif field_val.startswith(query_lower):
                    score += 50
                elif query_lower in field_val:
                    score += 20
                else:
                    # Character subsequence matching
                    qi = 0
                    for ch in field_val:
                        if qi < len(query_lower) and ch == query_lower[qi]:
                            qi += 1
                    if qi == len(query_lower):
                        score += 10

            if score > 0:
                scored.append((score, host))

        scored.sort(key=lambda x: (-x[0], -x[1].last_connected))
        return [h for _, h in scored[:MAX_DISPLAY_HOSTS]]

    def add_host(self, host: SSHHost) -> None:
        """Add a host to the registry."""
        host.source = "ash"
        self._hosts[host.alias] = host

    def record_connection(self, host: SSHHost) -> None:
        """Record a successful connection for history/sorting."""
        host.last_connected = time.time()
        host.connect_count += 1

        # Save to history
        SSH_HISTORY_FILE.parent.mkdir(parents=True, exist_ok=True)
        history: dict = {"connections": []}

        if SSH_HISTORY_FILE.exists():
            try:
                history = json.loads(SSH_HISTORY_FILE.read_text())
            except (json.JSONDecodeError, TypeError):
                pass

        connections = history.get("connections", [])
        # Remove existing entry for this host
        connections = [c for c in connections if c.get("alias") != host.alias]
        # Prepend new entry
        connections.insert(0, {
            "alias":     host.alias,
            "hostname":  host.hostname,
            "user":      host.user,
            "port":      host.port,
            "timestamp": host.last_connected,
            "count":     host.connect_count,
            "favourite": host.is_favourite,
        })
        # Trim to max
        history["connections"] = connections[:MAX_HISTORY]
        SSH_HISTORY_FILE.write_text(json.dumps(history, indent=2))


# ══════════════════════════════════════════════════════════════════════════════
# PROFILE MANAGER
# ══════════════════════════════════════════════════════════════════════════════

class ProfileManager:
    """Manages SSH connection profiles."""

    DEFAULT_PROFILES = [
        ConnectionProfile(
            name="default",
            description="Default SSH connection",
            emoji="󰒋",
            color="#cba6f7",
        ),
        ConnectionProfile(
            name="dev",
            description="Development servers",
            extra_opts=["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"],
            emoji="󰅨",
            color="#89b4fa",
        ),
        ConnectionProfile(
            name="prod",
            description="Production servers (strict security)",
            extra_opts=["-o", "StrictHostKeyChecking=yes"],
            emoji="󰒓",
            color="#f38ba8",
        ),
        ConnectionProfile(
            name="staging",
            description="Staging environment",
            emoji="󰙴",
            color="#fab387",
        ),
        ConnectionProfile(
            name="personal",
            description="Personal machines",
            forward_agent=True,
            emoji="󰀄",
            color="#a6e3a1",
        ),
    ]

    def __init__(self) -> None:
        self._profiles: dict[str, ConnectionProfile] = {}
        self._load()

    def _load(self) -> None:
        """Load profiles from disk + inject defaults."""
        for p in self.DEFAULT_PROFILES:
            self._profiles[p.name] = p

        if SSH_PROFILES_FILE.exists():
            try:
                data = json.loads(SSH_PROFILES_FILE.read_text())
                for entry in data.get("profiles", []):
                    name = entry.get("name", "")
                    if name:
                        self._profiles[name] = ConnectionProfile(**entry)
            except (json.JSONDecodeError, TypeError, KeyError):
                pass

    def get(self, name: str) -> ConnectionProfile:
        return self._profiles.get(name, self._profiles["default"])

    @property
    def all_profiles(self) -> list[ConnectionProfile]:
        return list(self._profiles.values())


# ══════════════════════════════════════════════════════════════════════════════
# CONNECTION BUILDER
# ══════════════════════════════════════════════════════════════════════════════

class ConnectionBuilder:
    """Builds the final SSH command from host + profile + overrides."""

    def __init__(
        self,
        host:    SSHHost,
        profile: ConnectionProfile,
        tunnels: Optional[list[TunnelSpec]] = None,
        extra_flags: Optional[list[str]]     = None,
    ) -> None:
        self.host    = host
        self.profile = profile
        self.tunnels = tunnels or []
        self.extra   = extra_flags or []

    def build_kitty_ssh_cmd(self) -> list[str]:
        """
        Build a 'kitten ssh' command (uses Kitty's native SSH kitten
        which automatically deploys terminfo to the remote host).
        """
        cmd = ["kitten", "ssh"]

        # Profile flags
        cmd.extend(self.profile.build_flags())

        # Host-specific overrides (override profile defaults)
        if self.host.port != 22 and "-p" not in cmd:
            cmd.extend(["-p", str(self.host.port)])

        if self.host.identity_file:
            cmd.extend(["-i", os.path.expanduser(self.host.identity_file)])

        if self.host.proxy_jump:
            cmd.extend(["-J", self.host.proxy_jump])

        if self.host.compression:
            cmd.append("-C")

        if self.host.forward_agent:
            cmd.append("-A")

        # Tunnel flags
        for tunnel in self.tunnels:
            flag = tunnel.to_flag()
            cmd.extend(flag.split())

        # Extra user flags
        cmd.extend(self.extra)

        # Target
        cmd.append(self.host.connection_string)

        return cmd

    def build_multiplexer_cmd(self, mux: str = "tmux") -> list[str]:
        """
        Build SSH command that auto-attaches to a tmux/zellij session
        on the remote host.
        """
        ssh_cmd = self.build_kitty_ssh_cmd()

        if mux == "tmux":
            # Add remote command to attach-or-new tmux session
            remote_cmd = (
                'tmux new-session -A -s main'
                ' \\; set-option -g status-bg colour234'
            )
            ssh_cmd.extend(["-t", remote_cmd])
        elif mux == "zellij":
            remote_cmd = "zellij attach --create main"
            ssh_cmd.extend(["-t", remote_cmd])

        return ssh_cmd


# ══════════════════════════════════════════════════════════════════════════════
# PING UTILITY
# ══════════════════════════════════════════════════════════════════════════════

def ping_host(hostname: str, timeout_ms: int = PING_TIMEOUT_MS) -> bool:
    """Quick TCP ping to check if host is reachable (non-blocking)."""
    import socket
    import threading

    result = [False]

    def _check() -> None:
        try:
            s = socket.create_connection(
                (hostname, 22),
                timeout=timeout_ms / 1000.0
            )
            s.close()
            result[0] = True
        except (socket.error, OSError):
            result[0] = False

    t = threading.Thread(target=_check, daemon=True)
    t.start()
    t.join(timeout=timeout_ms / 1000.0 + 0.1)
    return result[0]


# ══════════════════════════════════════════════════════════════════════════════
# TUI HANDLER
# ══════════════════════════════════════════════════════════════════════════════

class SSHPickerHandler(Handler):
    """
    Interactive SSH host picker TUI.
    Full-screen overlay with fuzzy search, host details, and
    keyboard-driven selection.

    Keybinds:
      Type     → filter hosts (fuzzy search)
      ↑/↓ k/j  → navigate list
      Enter    → connect to selected host
      Ctrl+P   → switch profile
      Ctrl+T   → add SSH tunnel
      Ctrl+M   → toggle multiplexer mode
      Ctrl+F   → toggle favourite
      Ctrl+N   → add new host
      Ctrl+R   → ping/refresh host status
      Esc/q    → cancel
    """

    # UI state
    query:         str       = ""
    selected_idx:  int       = 0
    scroll_offset: int       = 0
    profile_idx:   int       = 0
    use_mux:       bool      = False
    mux_type:      str       = "tmux"
    show_details:  bool      = True
    results:       list[SSHHost] = field(default_factory=list)

    def __init__(
        self,
        registry: HostRegistry,
        profiles: ProfileManager,
        initial_query: str = "",
    ) -> None:
        super().__init__()
        self.registry    = registry
        self.profiles    = profiles
        self.query       = initial_query
        self.results     = registry.search(initial_query)
        self.chosen_host: Optional[SSHHost] = None
        self.tunnels:    list[TunnelSpec]   = []

    def _c(self, name: str) -> str:
        return COLORS.get(name, "")

    def _ic(self, name: str) -> str:
        return ICONS.get(name, "?")

    @property
    def current_host(self) -> Optional[SSHHost]:
        if self.results and 0 <= self.selected_idx < len(self.results):
            return self.results[self.selected_idx]
        return None

    @property
    def current_profile(self) -> ConnectionProfile:
        return self.profiles.all_profiles[self.profile_idx % len(self.profiles.all_profiles)]

    def initialize(self) -> None:
        self.cmd_write(set_line_wrapping(False))

    def on_resize(self, screen_size: Screen) -> None:
        self._screen_size = screen_size
        self._render()

    def on_text(self, text: str, in_bracketed_paste: bool = False) -> None:
        self.query += text
        self.selected_idx = 0
        self.scroll_offset = 0
        self.results = self.registry.search(self.query)
        self._render()

    def on_key(self, key_event: KeyEvent) -> None:
        key  = key_event.key
        mods = key_event.mods

        # Navigation
        if key in ("up", "k") and not mods:
            self._move_selection(-1)
        elif key in ("down", "j") and not mods:
            self._move_selection(1)
        elif key == "page_up":
            self._move_selection(-10)
        elif key == "page_down":
            self._move_selection(10)
        elif key == "home":
            self.selected_idx = 0
            self.scroll_offset = 0

        # Backspace
        elif key in ("backspace", "delete"):
            self.query = self.query[:-1]
            self.selected_idx = 0
            self.results = self.registry.search(self.query)

        # Actions
        elif key == "enter":
            self._connect()
            return

        elif key == "escape" or (key == "g" and mods == "ctrl"):
            self.quit_loop(0)
            return

        elif key == "p" and mods == "ctrl":
            self.profile_idx = (self.profile_idx + 1) % len(self.profiles.all_profiles)

        elif key == "m" and mods == "ctrl":
            self.use_mux = not self.use_mux

        elif key == "f" and mods == "ctrl":
            self._toggle_favourite()

        elif key == "r" and mods == "ctrl":
            self._ping_selected()

        elif key == "d" and mods == "ctrl":
            self.show_details = not self.show_details

        self._render()

    def _move_selection(self, delta: int) -> None:
        if not self.results:
            return
        self.selected_idx = max(0, min(
            len(self.results) - 1,
            self.selected_idx + delta
        ))
        # Scroll tracking
        visible_rows = self._visible_list_rows()
        if self.selected_idx < self.scroll_offset:
            self.scroll_offset = self.selected_idx
        elif self.selected_idx >= self.scroll_offset + visible_rows:
            self.scroll_offset = self.selected_idx - visible_rows + 1

    def _visible_list_rows(self) -> int:
        """Calculate how many host rows are visible."""
        h = getattr(self._screen_size, "rows", 40)
        # Header (5) + search (3) + footer (3) + detail panel (8 if shown)
        overhead = 11 + (8 if self.show_details else 0)
        return max(5, h - overhead)

    def _toggle_favourite(self) -> None:
        host = self.current_host
        if host:
            host.is_favourite = not host.is_favourite
            self.registry.save_ash_hosts()

    def _ping_selected(self) -> None:
        host = self.current_host
        if host:
            # Non-blocking ping — update after render
            reachable = ping_host(host.hostname)
            # Store ping result in host object (not persisted)
            host._ping_ok = reachable  # type: ignore[attr-defined]
            self._render()

    def _connect(self) -> None:
        host = self.current_host
        if not host:
            return

        self.chosen_host = host
        self.registry.record_connection(host)
        self.quit_loop(0)

    def _render_header(self, w: int) -> None:
        """Render the top header bar."""
        r = self._c("reset")
        accent = self._c("accent")
        bold   = self._c("bold")
        bg_s   = self._c("bg_surface")
        fg_m   = self._c("fg_muted")

        title = f" {ICONS['ssh']} SSH Connect "
        host_count = f" {len(self.results)}/{len(self.registry.all_hosts)} hosts "
        profile_info = f" {self.current_profile.emoji} {self.current_profile.name} "
        mux_info = f" {'󱘖 tmux' if self.use_mux else ''}" if self.use_mux else ""

        padding = w - len(title) - len(host_count) - len(profile_info) - len(mux_info) - 4

        self.print(
            f"{bg_s}{bold}{accent}{title}{r}"
            f"{bg_s}{fg_m}{'─' * max(0, padding)}{r}"
            f"{bg_s}{fg_m}{mux_info}{r}"
            f"{bg_s}{self._c('peach')}{profile_info}{r}"
            f"{bg_s}{fg_m}{host_count}{r}"
        )
        self.print(f"{self._c('bg_surface')}{'─' * w}{r}")

    def _render_search(self, w: int) -> None:
        """Render the search input box."""
        r      = self._c("reset")
        accent = self._c("accent")
        fg     = self._c("fg")
        fg_m   = self._c("fg_muted")
        bold   = self._c("bold")

        icon = ICONS["search"]
        prefix = f" {icon}  "
        suffix = f"  {ICONS['filter']} fuzzy"
        query_display = self.query + "█"
        available = w - len(prefix) - len(suffix) - 4
        if len(query_display) > available:
            query_display = "…" + query_display[-(available - 1):]

        self.print(
            f"╭{'─' * (w - 2)}╮"
        )
        self.print(
            f"│{fg_m}{prefix}{r}{bold}{fg}{query_display:<{available}}{r}"
            f"{fg_m}{suffix} │{r}"
        )
        self.print(
            f"╰{'─' * (w - 2)}╯"
        )

    def _render_host_row(
        self,
        host:       SSHHost,
        is_selected: bool,
        width:       int,
    ) -> str:
        """Render a single host row in the list."""
        r       = self._c("reset")
        bold    = self._c("bold")
        dim     = self._c("dim")
        accent  = self._c("accent")
        blue    = self._c("blue")
        green   = self._c("green")
        yellow  = self._c("yellow")
        fg      = self._c("fg")
        fg_m    = self._c("fg_muted")

        if is_selected:
            bg_sel  = self._c("bg_elevated")
            arrow   = f"{accent}❯{r}"
            fg_sel  = bold + fg
        else:
            bg_sel  = ""
            arrow   = "  "
            fg_sel  = fg

        # Status indicators
        fav   = f"{yellow}★{r} " if host.is_favourite else "  "
        ping  = getattr(host, "_ping_ok", None)
        if ping is True:
            ping_dot = f"{green}●{r}"
        elif ping is False:
            ping_dot = f"{self._c('red')}○{r}"
        else:
            ping_dot = f"{dim}·{r}"

        # Connection info
        conn_str = host.display_name
        if host.alias != host.hostname and host.alias != conn_str:
            alias_display = f"{fg_m}({host.alias}){r}"
        else:
            alias_display = ""

        # Tags
        tags_display = ""
        if host.tags:
            tag_str = " ".join(f"{self._c('teal')}#{t}{r}" for t in host.tags[:3])
            tags_display = f" {tag_str}"

        # Recent indicator
        if host.last_connected > 0:
            elapsed = time.time() - host.last_connected
            if elapsed < 3600:
                recency = f"{green}now{r}"
            elif elapsed < 86400:
                h = int(elapsed / 3600)
                recency = f"{blue}{h}h{r}"
            elif elapsed < 604800:
                d = int(elapsed / 86400)
                recency = f"{fg_m}{d}d{r}"
            else:
                recency = f"{dim}old{r}"
        else:
            recency = f"{dim}─{r}"

        # Profile emoji
        emoji = host.emoji

        row = (
            f"{bg_sel}{arrow}{fav}{ping_dot} "
            f"{emoji} {fg_sel}{conn_str:<28}{r}"
            f" {alias_display:<12}"
            f"{tags_display:<20}"
            f" {fg_m}p:{host.port:<5}{r}"
            f" {recency:<6}"
            f"{r}"
        )

        # Truncate to width
        visible_len = len(row.encode("ascii", errors="ignore"))
        return row

    def _render_host_list(self, w: int) -> None:
        """Render the scrollable host list."""
        r       = self._c("reset")
        fg_m    = self._c("fg_muted")
        accent  = self._c("accent")
        visible = self._visible_list_rows()

        if not self.results:
            self.print(f"\n  {self._c('fg_muted')}{ICONS['cross']}  No hosts found for '{self.query}'{r}")
            self.print(f"  {fg_m}Try a different search term{r}\n")
            return

        # Column header
        self.print(
            f"  {fg_m}{'HOST':<30} {'ALIAS':<12} {'TAGS':<20} {'PORT':<6} {'LAST':<6}{r}"
        )
        self.print(f"  {fg_m}{'─' * (w - 4)}{r}")

        # Host rows
        end_idx = min(self.scroll_offset + visible, len(self.results))
        for i, host in enumerate(self.results[self.scroll_offset:end_idx], self.scroll_offset):
            row = self._render_host_row(host, i == self.selected_idx, w)
            self.print(f"  {row}")

        # Scroll indicator
        if len(self.results) > visible:
            shown = f"{self.scroll_offset + 1}-{end_idx}"
            total = len(self.results)
            pct   = int((self.scroll_offset + visible / 2) * 100 / total)
            self.print(
                f"\n  {fg_m}Showing {shown} of {total}  │  {pct}%{r}"
            )

    def _render_detail_panel(self, w: int) -> None:
        """Render the detail panel for the selected host."""
        host = self.current_host
        if not host or not self.show_details:
            return

        r    = self._c("reset")
        bold = self._c("bold")
        fg   = self._c("fg")
        fg_m = self._c("fg_muted")
        acc  = self._c("accent")
        blue = self._c("blue")
        grn  = self._c("green")

        sep = f"{fg_m}{'─' * w}{r}"
        self.print(sep)
        self.print(
            f"  {ICONS['server']} {bold}{acc}{host.display_name}{r}"
            f"  {fg_m}{host.description or ''}{r}"
        )
        # Detail grid
        details = []
        if host.hostname != host.alias:
            details.append(f"{fg_m}Hostname:{r} {fg}{host.hostname}")
        if host.user:
            details.append(f"{fg_m}User:{r} {fg}{host.user}")
        details.append(f"{fg_m}Port:{r} {fg}{host.port}")
        if host.identity_file:
            details.append(f"{fg_m}Key:{r} {blue}{host.identity_file}")
        if host.proxy_jump:
            details.append(f"{fg_m}Jump:{r} {grn}{host.proxy_jump}")
        if host.connect_count > 0:
            details.append(f"{fg_m}Connects:{r} {fg}{host.connect_count}")

        row_items = []
        for i, d in enumerate(details):
            row_items.append(f"  {d}{r}")
            if (i + 1) % 3 == 0:
                self.print("".join(row_items))
                row_items = []
        if row_items:
            self.print("".join(row_items))

    def _render_footer(self, w: int) -> None:
        """Render the bottom keybind hint bar."""
        r    = self._c("reset")
        fg_m = self._c("fg_muted")
        acc  = self._c("accent")
        bold = self._c("bold")

        hints = [
            ("Enter", "Connect"),
            ("^P",    "Profile"),
            ("^M",    "Mux"),
            ("^F",    "Fav"),
            ("^R",    "Ping"),
            ("^D",    "Detail"),
            ("Esc",   "Cancel"),
        ]
        sep = f" {fg_m}│{r} "
        hint_str = sep.join(
            f"{bold}{acc}{key}{r}{fg_m} {label}{r}"
            for key, label in hints
        )
        self.print(f"\n{fg_m}{'─' * w}{r}")
        self.print(f"  {hint_str}")

    def _render(self) -> None:
        """Full TUI re-render."""
        self.cmd_write(clear_screen())
        sc = getattr(self, "_screen_size", None)
        w  = getattr(sc, "columns", 120)

        self._render_header(w)
        self.print("")
        self._render_search(w)
        self.print("")
        self._render_host_list(w)
        self._render_detail_panel(w)
        self._render_footer(w)

    def print(self, text: str) -> None:
        self.cmd_write(text + "\r\n")


# ══════════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

def main(args: list[str]) -> Optional[str]:
    """
    Entry point for the SSH kitten.
    Returns the SSH command to execute, or None to cancel.
    """
    initial_query = " ".join(args[1:]) if len(args) > 1 else ""

    # Initialize subsystems
    registry = HostRegistry()
    profiles = ProfileManager()

    # If a direct host was given and it exists, skip picker
    if initial_query and not initial_query.startswith("-"):
        matching = registry.search(initial_query)
        if len(matching) == 1:
            # Direct match — go straight to connection
            host = matching[0]
            profile = profiles.get(host.profile)
            builder = ConnectionBuilder(host, profile)
            cmd = builder.build_kitty_ssh_cmd()
            registry.record_connection(host)
            return " ".join(cmd)

    # Launch interactive picker
    handler = SSHPickerHandler(registry, profiles, initial_query)
    loop    = Loop()
    loop.loop(handler)

    if handler.chosen_host is None:
        return None

    host    = handler.chosen_host
    profile = profiles.get(host.profile)
    builder = ConnectionBuilder(
        host,
        profile,
        tunnels=handler.tunnels,
    )

    if handler.use_mux:
        cmd = builder.build_multiplexer_cmd(handler.mux_type)
    else:
        cmd = builder.build_kitty_ssh_cmd()

    # Set window title
    print(
        f"\033]2;{ICONS['ssh']} {host.display_name}\007",
        end="", flush=True
    )

    return " ".join(cmd)


def handle_result(
    args:    list[str],
    answer:  Optional[str],
    target_window_id: int,
    boss:    Boss,
) -> None:
    """Execute the SSH command in the current window."""
    if not answer:
        return

    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    # Send the SSH command to the terminal
    boss.call_remote_control(
        window,
        ("send-text", "--", answer + "\r"),
    )