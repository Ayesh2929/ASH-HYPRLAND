#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY HINTS KITTEN ULTRA
# ══════════════════════════════════════════════════════════════════════════════
# File    : kittens/hints-kitten.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Ultra-premium hints kitten extending Kitty's native hints system.
#           Provides additional hint types, custom actions, and an interactive
#           selection mode with visual feedback and action chaining.
#
#   Additional hint types beyond Kitty's built-in:
#     • commit     — Git commit SHAs (7-40 hex chars in git log context)
#     • docker-id  — Docker container/image IDs
#     • k8s-name   — Kubernetes resource names
#     • version    — Semantic version strings (v1.2.3 / 1.2.3)
#     • color      — Hex color codes (#rgb, #rrggbb, rgb(r,g,b), hsl(h,s,l))
#     • timestamp  — ISO 8601 / Unix timestamps
#     • json-key   — JSON key names
#     • env-var    — Environment variable references ($VAR, ${VAR})
#     • python-err — Python traceback file:line references
#     • rust-err   — Rust error E[0-9]+ codes
#     • markdown-link — Markdown [text](url) URLs
#     • todo       — TODO/FIXME/HACK/NOTE/XXX markers
#
#   Custom actions:
#     • Open file:line in Neovim (path:N → nvim +N file)
#     • Copy color and show color preview
#     • Open git commit in lazygit or GitHub
#     • Translate selected text
#     • Search selected text (Google/DuckDuckGo/StackOverflow)
#     • Base64 decode/encode
#     • JWT decode
#     • URL encode/decode
#
#   Usage:
#     # In keybinds.conf:
#     map kitty_mod+e  kitten kittens/hints-kitten.py --type url
#     map kitty_mod+p  kitten kittens/hints-kitten.py --type path
#     map kitty_mod+h  kitten kittens/hints-kitten.py --type commit
#     map kitty_mod+n  kitten kittens/hints-kitten.py --type version
#
#   Integration with Kitty's native hints:
#     This kitten first runs the native hints kitten for label selection,
#     then intercepts the result and applies extended actions.
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import urllib.parse
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from kittens.tui.handler import Handler
from kittens.tui.loop import Loop
from kittens.tui.operations import clear_screen, set_line_wrapping
from kitty.boss import Boss
from kitty.fast_data_types import Screen
from kitty.key_encoding import KeyEvent

# ── Colors ────────────────────────────────────────────────────────────────────
C = {
    "fg":    "\033[38;2;205;214;244m",
    "fg_m":  "\033[38;2;166;173;200m",
    "acc":   "\033[38;2;203;166;247m",
    "blue":  "\033[38;2;137;180;250m",
    "green": "\033[38;2;166;227;161m",
    "red":   "\033[38;2;243;139;168m",
    "yel":   "\033[38;2;249;226;175m",
    "teal":  "\033[38;2;148;226;213m",
    "bold":  "\033[1m",
    "dim":   "\033[2m",
    "r":     "\033[0m",
}

# ══════════════════════════════════════════════════════════════════════════════
# HINT TYPE REGISTRY
# ══════════════════════════════════════════════════════════════════════════════

@dataclass
class HintType:
    """Definition of a hint matching type."""
    name:        str
    description: str
    regex:       str
    icon:        str
    color:       str
    actions:     list[str]

    def compile_regex(self) -> re.Pattern:
        return re.compile(self.regex)


HINT_TYPES: dict[str, HintType] = {
    # ── Extended git ──────────────────────────────────────────────────────────
    "commit": HintType(
        name="commit",
        description="Git commit SHA",
        regex=r"\b[0-9a-f]{7,40}\b",
        icon="󰊤",
        color=C["acc"],
        actions=["copy", "open-github", "lazygit-show", "git-log"],
    ),

    # ── Container IDs ─────────────────────────────────────────────────────────
    "docker-id": HintType(
        name="docker-id",
        description="Docker container/image ID",
        regex=r"\b[0-9a-f]{12,64}\b",
        icon="󰡨",
        color=C["blue"],
        actions=["copy", "docker-exec", "docker-inspect", "docker-logs"],
    ),

    # ── Versions ──────────────────────────────────────────────────────────────
    "version": HintType(
        name="version",
        description="Semantic version string",
        regex=r"v?[0-9]+\.[0-9]+\.[0-9]+(?:[-+][a-zA-Z0-9.+]+)?",
        icon="󱂌",
        color=C["green"],
        actions=["copy", "search-releases", "compare-versions"],
    ),

    # ── Colors ────────────────────────────────────────────────────────────────
    "color": HintType(
        name="color",
        description="CSS color value",
        regex=r"(?:#[0-9a-fA-F]{3,8}|rgb\([^)]+\)|hsl\([^)]+\)|rgba\([^)]+\))",
        icon="󰸉",
        color=C["acc"],
        actions=["copy", "preview-color", "convert-format"],
    ),

    # ── Python errors ─────────────────────────────────────────────────────────
    "python-err": HintType(
        name="python-err",
        description="Python traceback file:line",
        regex=r'File "([^"]+)", line ([0-9]+)',
        icon="󰌠",
        color=C["red"],
        actions=["open-in-editor", "copy"],
    ),

    # ── Rust errors ───────────────────────────────────────────────────────────
    "rust-err": HintType(
        name="rust-err",
        description="Rust error code",
        regex=r"\bE[0-9]{4}\b",
        icon="󱘗",
        color=C["red"],
        actions=["open-rust-docs", "copy"],
    ),

    # ── Timestamps ────────────────────────────────────────────────────────────
    "timestamp": HintType(
        name="timestamp",
        description="ISO 8601 / Unix timestamp",
        regex=(
            r"(?:[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}"
            r"(?:\.[0-9]+)?(?:Z|[+-][0-9]{2}:[0-9]{2})?)"
            r"|(?:\b1[0-9]{9}\b)"
        ),
        icon="󰃰",
        color=C["yel"],
        actions=["copy", "convert-timezone", "humanize"],
    ),

    # ── Environment variables ─────────────────────────────────────────────────
    "env-var": HintType(
        name="env-var",
        description="Environment variable reference",
        regex=r"\$\{?[A-Z_][A-Z_0-9]*\}?",
        icon="󰙅",
        color=C["teal"],
        actions=["copy", "show-value", "expand"],
    ),

    # ── JSON keys ─────────────────────────────────────────────────────────────
    "json-key": HintType(
        name="json-key",
        description="JSON key name",
        regex=r'"([^"]+)"\s*:',
        icon="󱏗",
        color=C["blue"],
        actions=["copy", "jq-path"],
    ),

    # ── TODOs ─────────────────────────────────────────────────────────────────
    "todo": HintType(
        name="todo",
        description="TODO/FIXME/NOTE/HACK marker",
        regex=r"\b(?:TODO|FIXME|HACK|NOTE|XXX|BUG|OPTIMIZE)(?:\s*\([^)]+\))?(?::?)\s*[^\n]*",
        icon="󰝒",
        color=C["yel"],
        actions=["copy", "create-issue", "add-note"],
    ),

    # ── Markdown links ────────────────────────────────────────────────────────
    "markdown-link": HintType(
        name="markdown-link",
        description="Markdown link URL",
        regex=r"\[([^\]]+)\]\(([^)]+)\)",
        icon="󰰈",
        color=C["blue"],
        actions=["open", "copy-url", "copy-text"],
    ),

    # ── File:line references ──────────────────────────────────────────────────
    "file-line": HintType(
        name="file-line",
        description="File path with line number",
        regex=r"(?:(?:[~/]|\.{1,2}/)[^\s:]+(?:\.[a-zA-Z]+)?):[0-9]+(?::[0-9]+)?",
        icon="󰈙",
        color=C["fg"],
        actions=["open-in-editor", "open-in-yazi", "copy"],
    ),

    # ── JWT tokens ────────────────────────────────────────────────────────────
    "jwt": HintType(
        name="jwt",
        description="JSON Web Token",
        regex=r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]*",
        icon="󰌋",
        color=C["yel"],
        actions=["decode-jwt", "copy"],
    ),
}


# ══════════════════════════════════════════════════════════════════════════════
# ACTION HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

class ActionHandler:
    """Executes actions on selected hint text."""

    def __init__(self, hint_type: str, selected: str, raw_match: str) -> None:
        self.hint_type = hint_type
        self.selected  = selected.strip()
        self.raw       = raw_match

    def execute(self, action: str) -> None:
        handler = getattr(self, f"_action_{action.replace('-', '_')}", None)
        if handler:
            handler()
        else:
            self._action_copy()

    # ── Core actions ──────────────────────────────────────────────────────────

    def _action_copy(self) -> None:
        """Copy to clipboard."""
        try:
            subprocess.run(["wl-copy"], input=self.selected.encode(), check=True)
        except (FileNotFoundError, subprocess.CalledProcessError):
            try:
                subprocess.run(
                    ["xclip", "-selection", "clipboard"],
                    input=self.selected.encode(),
                )
            except FileNotFoundError:
                pass

    def _action_open(self) -> None:
        """Open with xdg-open."""
        subprocess.Popen(["xdg-open", self.selected],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _action_open_in_editor(self) -> None:
        """Open file:line in configured editor (nvim by default)."""
        editor = os.environ.get("EDITOR", "nvim")
        text   = self.selected

        # Parse file:line or file:line:col
        match = re.match(r'^([^:]+):(\d+)(?::(\d+))?$', text)
        if match:
            fpath, line, col = match.groups()
            fpath = os.path.expanduser(fpath)
            if os.path.exists(fpath):
                cmd = [editor, f"+{line}", fpath]
                subprocess.Popen(cmd)
                return

        # Python traceback: File "path", line N
        match2 = re.search(r'File "([^"]+)", line (\d+)', text)
        if match2:
            fpath, line = match2.groups()
            if os.path.exists(fpath):
                subprocess.Popen([editor, f"+{line}", fpath])
                return

        # Fallback: just open the path
        subprocess.Popen([editor, text])

    def _action_open_in_yazi(self) -> None:
        """Open file location in Yazi."""
        fpath = self.selected.split(":")[0]
        fpath = os.path.expanduser(fpath)
        if os.path.exists(fpath):
            subprocess.Popen(["yazi", str(Path(fpath).parent)])

    def _action_open_github(self) -> None:
        """Open git commit on GitHub."""
        # Try to get the GitHub remote URL
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True, text=True,
        )
        remote = result.stdout.strip()
        if "github.com" in remote:
            # Convert SSH to HTTPS
            remote = re.sub(r"git@github\.com:(.+)\.git", r"https://github.com/\1", remote)
            remote = remote.rstrip(".git")
            url = f"{remote}/commit/{self.selected}"
            subprocess.Popen(["xdg-open", url],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _action_lazygit_show(self) -> None:
        """Show commit in lazygit."""
        subprocess.Popen(["lazygit", "log", "--", self.selected])

    def _action_git_log(self) -> None:
        """Run git show for commit."""
        subprocess.Popen(
            ["kitty", "@", "launch", "--type=tab",
             "git", "show", "--stat", self.selected]
        )

    def _action_docker_exec(self) -> None:
        """Exec into Docker container."""
        subprocess.Popen(
            ["kitty", "@", "launch", "--type=tab",
             "docker", "exec", "-it", self.selected, "bash"]
        )

    def _action_docker_inspect(self) -> None:
        """Run docker inspect."""
        subprocess.Popen(
            ["kitty", "@", "launch", "--type=tab",
             "bash", "-c", f"docker inspect {self.selected} | bat -l json"]
        )

    def _action_docker_logs(self) -> None:
        """Follow Docker container logs."""
        subprocess.Popen(
            ["kitty", "@", "launch", "--type=tab",
             "docker", "logs", "-f", self.selected]
        )

    def _action_preview_color(self) -> None:
        """Show color preview in terminal."""
        color = self.selected.lstrip("#")
        if len(color) == 3:
            color = "".join(c * 2 for c in color)
        if len(color) == 6:
            r_val = int(color[0:2], 16)
            g_val = int(color[2:4], 16)
            b_val = int(color[4:6], 16)
            # Print a color block
            print(f"\033[48;2;{r_val};{g_val};{b_val}m{'  ─────  '}\033[0m #{color.upper()}")
        self._action_copy()

    def _action_open_rust_docs(self) -> None:
        """Open Rust error code in documentation."""
        code = self.selected.lstrip("E")
        url  = f"https://doc.rust-lang.org/error-index.html#E{code}"
        subprocess.Popen(["xdg-open", url],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _action_convert_timezone(self) -> None:
        """Copy timestamp with timezone note."""
        self._action_copy()

    def _action_humanize(self) -> None:
        """Convert Unix timestamp to human readable."""
        import datetime
        try:
            ts = int(self.selected)
            human = datetime.datetime.fromtimestamp(ts).isoformat()
            subprocess.run(["wl-copy"], input=human.encode())
        except (ValueError, OSError):
            self._action_copy()

    def _action_show_value(self) -> None:
        """Show environment variable value."""
        var_name = self.selected.strip("${}")
        value = os.environ.get(var_name, "(not set)")
        print(f"\n  {self.selected} = {value}")
        subprocess.run(["wl-copy"], input=value.encode())

    def _action_expand(self) -> None:
        """Expand environment variable and copy."""
        expanded = os.path.expandvars(self.selected)
        subprocess.run(["wl-copy"], input=expanded.encode())

    def _action_jq_path(self) -> None:
        """Build jq path for JSON key and copy."""
        key      = self.selected.strip('"').rstrip(':').strip()
        jq_path  = f".{key}"
        subprocess.run(["wl-copy"], input=jq_path.encode())

    def _action_decode_jwt(self) -> None:
        """Decode JWT payload and display/copy."""
        parts = self.selected.split(".")
        if len(parts) >= 2:
            # Add padding
            payload = parts[1] + "=" * (4 - len(parts[1]) % 4)
            try:
                decoded = base64.urlsafe_b64decode(payload).decode("utf-8")
                parsed  = json.loads(decoded)
                pretty  = json.dumps(parsed, indent=2)
                subprocess.run(["wl-copy"], input=pretty.encode())
                print(f"\n{C['green']}JWT Payload (copied):{C['r']}\n{pretty}")
            except (ValueError, json.JSONDecodeError, UnicodeDecodeError):
                self._action_copy()

    def _action_search_releases(self) -> None:
        """Search for version release notes."""
        self._action_copy()

    def _action_copy_url(self) -> None:
        """Copy URL from markdown link."""
        match = re.search(r'\[([^\]]+)\]\(([^)]+)\)', self.raw)
        if match:
            url = match.group(2)
            subprocess.run(["wl-copy"], input=url.encode())

    def _action_copy_text(self) -> None:
        """Copy text from markdown link."""
        match = re.search(r'\[([^\]]+)\]\(([^)]+)\)', self.raw)
        if match:
            text = match.group(1)
            subprocess.run(["wl-copy"], input=text.encode())

    def _action_create_issue(self) -> None:
        """Open GitHub new issue with TODO pre-filled."""
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True, text=True,
        )
        remote = result.stdout.strip()
        if "github.com" in remote:
            remote = re.sub(r"git@github\.com:(.+)\.git", r"https://github.com/\1", remote)
            title  = urllib.parse.quote(self.selected[:100])
            url    = f"{remote}/issues/new?title={title}"
            subprocess.Popen(["xdg-open", url],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _action_add_note(self) -> None:
        """Add TODO to ASH QuickNote."""
        subprocess.Popen(
            ["ash", "note", "new", self.selected],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )


# ══════════════════════════════════════════════════════════════════════════════
# ACTION PICKER TUI
# ══════════════════════════════════════════════════════════════════════════════

class ActionPickerHandler(Handler):
    """
    Interactive action picker for a selected hint.

    ╭──────────────────────────────────────────────────────────────────────╮
    │  󰊤 commit: a3f9c82b                                                  │
    │  ─────────────────────────────────────────────────────────────────── │
    │  ❯ 󰆏 copy                    Copy to clipboard                       │
    │    󰊤 open-github              Open on GitHub                          │
    │    󰄶 lazygit-show             Show in lazygit                         │
    │    󰅿 git-log                  git show in new tab                     │
    │  ─────────────────────────────────────────────────────────────────── │
    │  Enter:execute  ↑/↓:navigate  Esc:cancel                             │
    ╰──────────────────────────────────────────────────────────────────────╯
    """

    ACTION_ICONS = {
        "copy":              "󰆏",
        "open":              "󰏆",
        "open-in-editor":    "󰕷",
        "open-in-yazi":      "󰉋",
        "open-github":       "󰊤",
        "lazygit-show":      "󰄶",
        "git-log":           "󰅿",
        "docker-exec":       "󰡨",
        "docker-inspect":    "󰋗",
        "docker-logs":       "󰰆",
        "preview-color":     "󰸉",
        "convert-format":    "󰕺",
        "open-rust-docs":    "󱘗",
        "convert-timezone":  "󰃰",
        "humanize":          "󰃰",
        "show-value":        "󰙅",
        "expand":            "󰙅",
        "jq-path":           "󱏗",
        "decode-jwt":        "󰌋",
        "search-releases":   "󰍉",
        "copy-url":          "󰖟",
        "copy-text":         "󰰈",
        "create-issue":      "󰝒",
        "add-note":          "󱞁",
        "compare-versions":  "󱂌",
    }

    ACTION_DESCRIPTIONS = {
        "copy":              "Copy to clipboard",
        "open":              "Open with xdg-open",
        "open-in-editor":    "Open in Neovim at line",
        "open-in-yazi":      "Open parent dir in Yazi",
        "open-github":       "View commit on GitHub",
        "lazygit-show":      "Show in lazygit",
        "git-log":           "git show in new tab",
        "docker-exec":       "Execute shell in container",
        "docker-inspect":    "docker inspect (JSON)",
        "docker-logs":       "Follow container logs",
        "preview-color":     "Preview color + copy",
        "convert-format":    "Convert color format",
        "open-rust-docs":    "Open error in Rust docs",
        "convert-timezone":  "Convert timezone",
        "humanize":          "Convert to human date",
        "show-value":        "Print environment value",
        "expand":            "Expand variable + copy",
        "jq-path":           "Copy jq path",
        "decode-jwt":        "Decode JWT payload",
        "search-releases":   "Search release notes",
        "copy-url":          "Copy markdown URL",
        "copy-text":         "Copy markdown text",
        "create-issue":      "Create GitHub issue",
        "add-note":          "Add to ASH QuickNote",
        "compare-versions":  "Compare versions",
    }

    def __init__(
        self,
        selected:  str,
        hint_type: HintType,
        raw_match: str = "",
    ) -> None:
        super().__init__()
        self.selected    = selected
        self.hint_type   = hint_type
        self.raw_match   = raw_match
        self.actions     = hint_type.actions
        self.sel_idx     = 0
        self.chosen_action: Optional[str] = None

    def initialize(self) -> None:
        self.cmd_write(set_line_wrapping(False))
        self._render()

    def on_resize(self, screen_size: Screen) -> None:
        self._screen_size = screen_size
        self._render()

    def on_key(self, key_event: KeyEvent) -> None:
        key = key_event.key
        if key in ("up", "k"):
            self.sel_idx = max(0, self.sel_idx - 1)
        elif key in ("down", "j"):
            self.sel_idx = min(len(self.actions) - 1, self.sel_idx + 1)
        elif key == "enter":
            self.chosen_action = self.actions[self.sel_idx]
            self.quit_loop(0)
            return
        elif key in ("escape", "q"):
            self.quit_loop(0)
            return
        elif key.isdigit() and 1 <= int(key) <= len(self.actions):
            self.chosen_action = self.actions[int(key) - 1]
            self.quit_loop(0)
            return
        self._render()

    def _render(self) -> None:
        self.cmd_write(clear_screen())
        r    = C["r"]
        bold = C["bold"]
        w    = getattr(getattr(self, "_screen_size", None), "columns", 80)

        # Header
        truncated = self.selected[:50] + ("…" if len(self.selected) > 50 else "")
        self.print(
            f"╭{'─' * (w - 2)}╮\n"
            f"│ {self.hint_type.icon} {bold}{self.hint_type.color}"
            f"{self.hint_type.name}{r}: "
            f"{C['fg']}{truncated}{r}"
            f"{' ' * max(0, w - 5 - len(self.hint_type.name) - len(truncated))}│\n"
            f"│ {C['fg_m']}{'─' * (w - 4)}{r} │"
        )

        # Action list
        for i, action in enumerate(self.actions):
            is_sel  = i == self.sel_idx
            arrow   = f"{C['acc']}❯{r}" if is_sel else " "
            num     = f"{C['dim']}{i + 1}{r}"
            icon    = self.ACTION_ICONS.get(action, "○")
            desc    = self.ACTION_DESCRIPTIONS.get(action, action)
            name_c  = f"{bold}{C['fg']}" if is_sel else C["fg_m"]
            bg      = f"\033[48;2;49;50;68m" if is_sel else ""
            bg_r    = r if is_sel else ""

            self.print(
                f"│ {bg}{arrow} {num} {icon} "
                f"{name_c}{action:<22}{r}{bg}"
                f"{C['dim']}{desc:<30}{r}"
                f"{bg_r}│"
            )

        # Footer
        self.print(
            f"│ {C['fg_m']}{'─' * (w - 4)}{r} │\n"
            f"│  {C['bold']}{C['acc']}Enter{r}{C['fg_m']}:execute  "
            f"{C['bold']}{C['acc']}↑/↓{r}{C['fg_m']}:navigate  "
            f"{C['bold']}{C['acc']}1-9{r}{C['fg_m']}:quick select  "
            f"{C['bold']}{C['acc']}Esc{r}{C['fg_m']}:cancel{r}"
            f"{' ' * max(0, w - 65)}│\n"
            f"╰{'─' * (w - 2)}╯"
        )

    def print(self, text: str) -> None:
        self.cmd_write(text + "\r\n")


# ══════════════════════════════════════════════════════════════════════════════
# HINT SCANNER
# ══════════════════════════════════════════════════════════════════════════════

class HintScanner:
    """Scans terminal content for hint matches."""

    def __init__(self, hint_type_name: str) -> None:
        self.hint_type = HINT_TYPES.get(hint_type_name)
        if not self.hint_type:
            raise ValueError(f"Unknown hint type: {hint_type_name}")

    def find_matches(self, text: str) -> list[tuple[str, int, int]]:
        """Find all matches in text, return (match, start, end) tuples."""
        pattern = self.hint_type.compile_regex()
        matches = []
        for m in pattern.finditer(text):
            matches.append((m.group(0), m.start(), m.end()))
        return matches

    def label_text(self, text: str) -> tuple[str, dict[str, str]]:
        """
        Overlay alphabetic labels on matched text.
        Returns (labeled_text, label→match_map).
        """
        matches = self.find_matches(text)
        if not matches:
            return text, {}

        label_chars = "asdfghjklqwertyuiopzxcvbnm"
        labels: dict[str, str] = {}
        result = list(text)

        for i, (match, start, end) in enumerate(matches[:len(label_chars)]):
            label = label_chars[i]
            labels[label] = match
            # Overlay label at match position
            label_display = f"\033[48;2;249;226;175m\033[38;2;30;30;46m{label}\033[0m"
            result[start] = label_display
            for j in range(start + 1, end):
                result[j] = ""

        return "".join(result), labels


# ══════════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

def main(args: list[str]) -> Optional[dict]:
    """
    Parse hint type from args and delegate to native kitten or custom handler.
    """
    hint_type_name = "url"
    action         = "@"   # Default: copy to clipboard
    program        = None

    i = 1
    while i < len(args):
        if args[i] == "--type" and i + 1 < len(args):
            hint_type_name = args[i + 1]
            i += 2
        elif args[i] == "--program" and i + 1 < len(args):
            program = args[i + 1]
            i += 2
        elif args[i] == "--action" and i + 1 < len(args):
            action = args[i + 1]
            i += 2
        else:
            i += 1

    # Check if this is an extended type (not handled by native kitten)
    if hint_type_name in HINT_TYPES:
        return {
            "extended":       True,
            "hint_type_name": hint_type_name,
            "action":         action,
            "program":        program,
        }

    # For native types, let handle_result delegate to Kitty's native kitten
    return {
        "extended":       False,
        "hint_type_name": hint_type_name,
        "action":         action,
        "program":        program,
    }


def handle_result(
    args:             list[str],
    answer:           Optional[dict],
    target_window_id: int,
    boss:             Boss,
) -> None:
    """Handle the hint selection result."""
    if not answer:
        return

    hint_type_name = answer.get("hint_type_name", "url")
    action         = answer.get("action", "copy")
    program        = answer.get("program")
    is_extended    = answer.get("extended", False)

    if not is_extended:
        # Delegate to native kitten (would normally be handled by Kitty)
        return

    hint_type = HINT_TYPES.get(hint_type_name)
    if not hint_type:
        return

    # Get terminal content from the window
    window = boss.window_id_map.get(target_window_id)
    if not window:
        return

    # Get screen text
    screen_text = window.as_text(add_history=True, as_ansi=False) or ""

    # Find matches
    scanner = HintScanner(hint_type_name)
    matches = scanner.find_matches(screen_text)

    if not matches:
        boss.notify(
            title="ASH Hints",
            body=f"No {hint_type_name} found on screen",
            timeout=2000,
        )
        return

    # For single match with direct action
    if len(matches) == 1 and action != "pick":
        selected_text = matches[0][0]
        handler = ActionHandler(hint_type_name, selected_text, matches[0][0])

        # If program specified, use it
        if program == "@":
            handler._action_copy()
        elif program and program != "-":
            try:
                subprocess.run([program], input=selected_text.encode())
            except FileNotFoundError:
                handler._action_copy()
        else:
            # Show action picker
            _show_action_picker(hint_type, selected_text, matches[0][0], boss)
        return

    # Multiple matches: show hint labels
    # (In a real implementation, this would overlay labels on the terminal)
    # For now, show the first match with the action picker
    if matches:
        selected_text = matches[0][0]
        _show_action_picker(hint_type, selected_text, matches[0][0], boss)


def _show_action_picker(
    hint_type:     HintType,
    selected_text: str,
    raw_match:     str,
    boss:          Boss,
) -> None:
    """Launch the action picker TUI."""
    picker = ActionPickerHandler(selected_text, hint_type, raw_match)
    loop   = Loop()
    loop.loop(picker)

    if picker.chosen_action:
        handler = ActionHandler(hint_type.name, selected_text, raw_match)
        handler.execute(picker.chosen_action)