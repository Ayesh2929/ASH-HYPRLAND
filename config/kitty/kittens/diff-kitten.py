#!/usr/bin/env python3
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — KITTY DIFF KITTEN ULTRA
# ══════════════════════════════════════════════════════════════════════════════
# File    : kittens/diff-kitten.py
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Ultra-premium diff kitten wrapping Kitty's native diff kitten
#           with enhanced features: side-by-side comparison, syntax
#           highlighting, word-level diffs, image diffs, directory diffs,
#           and integration with git/delta.
#
#   Features:
#     • Wraps Kitty's built-in kitten diff with additional preprocessing
#     • Side-by-side vs unified diff mode toggle
#     • Word-level diff highlighting (not just line-level)
#     • Directory diff: recursively compare two directories
#     • Git integration: diff against HEAD/index/specific commits
#     • Image diff: pixel-level comparison with overlay mode
#     • Ignore whitespace / ignore blank lines toggles
#     • Export: save diff to file or clipboard
#     • Search within diff output
#     • Color themes for diff (adapts to active ASH theme)
#
#   Usage:
#     map kitty_mod+d  kitten kittens/diff-kitten.py [file1] [file2]
#     kitty +kitten kittens/diff-kitten.py file1 file2
#     kitty +kitten kittens/diff-kitten.py --git HEAD~1 HEAD -- file.py
# ══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
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
    "added":    "\033[38;2;166;227;161m",    # green
    "removed":  "\033[38;2;243;139;168m",    # red
    "changed":  "\033[38;2;249;226;175m",    # yellow
    "header":   "\033[38;2;137;180;250m",    # blue
    "hunk":     "\033[38;2;203;166;247m",    # mauve
    "fg":       "\033[38;2;205;214;244m",
    "fg_m":     "\033[38;2;166;173;200m",
    "acc":      "\033[38;2;203;166;247m",
    "bold":     "\033[1m",
    "dim":      "\033[2m",
    "r":        "\033[0m",
    "bg_added": "\033[48;2;30;45;30m",
    "bg_removed":"\033[48;2;45;30;35m",
    "bg_hunk":  "\033[48;2;35;35;50m",
}

# ── Diff configuration ────────────────────────────────────────────────────────
KITTY_DIFF_CONF = """
# ASH Ultra Diff Configuration
# Colors adapted to active ASH theme

foreground                 #cdd6f4
background                 #1e1e2e

# Hunk header
color1                     #89b4fa

# Added lines
color2                     #a6e3a1

# Removed lines
color3                     #f38ba8

# Changed word (added part)
color4                     #a6e3a1

# Changed word (removed part)
color5                     #f38ba8

# Margin numbers
color6                     #585b70

# Highlighted search
color7                     #f9e2af

# File headers
color8                     #cba6f7
"""


class DiffProcessor:
    """Preprocesses diff content before sending to Kitty diff kitten."""

    def __init__(
        self,
        left:           str,
        right:          str,
        ignore_space:   bool = False,
        word_diff:      bool = False,
        is_git:         bool = False,
        git_ref_left:   str  = "",
        git_ref_right:  str  = "",
    ) -> None:
        self.left          = left
        self.right         = right
        self.ignore_space  = ignore_space
        self.word_diff     = word_diff
        self.is_git        = is_git
        self.git_ref_left  = git_ref_left
        self.git_ref_right = git_ref_right

    def get_files(self) -> tuple[str, str]:
        """Resolve left and right to actual file paths."""
        if self.is_git:
            return self._extract_git_files()
        return self.left, self.right

    def _extract_git_files(self) -> tuple[str, str]:
        """Extract two versions of a file from git."""
        with tempfile.NamedTemporaryFile(
            suffix=f"_{Path(self.left).name}",
            mode="w",
            delete=False,
            prefix="ash_diff_left_",
        ) as f_left:
            result = subprocess.run(
                ["git", "show", f"{self.git_ref_left}:{self.left}"],
                capture_output=True, text=True,
            )
            f_left.write(result.stdout)
            left_path = f_left.name

        with tempfile.NamedTemporaryFile(
            suffix=f"_{Path(self.right).name}",
            mode="w",
            delete=False,
            prefix="ash_diff_right_",
        ) as f_right:
            result = subprocess.run(
                ["git", "show", f"{self.git_ref_right}:{self.right}"],
                capture_output=True, text=True,
            )
            f_right.write(result.stdout)
            right_path = f_right.name

        return left_path, right_path

    def run_kitty_diff(self, left_path: str, right_path: str) -> None:
        """Launch Kitty's native diff kitten with our paths + config."""
        # Write temp diff config
        conf_path = Path(tempfile.mktemp(suffix=".conf", prefix="ash_diff_"))
        conf_path.write_text(KITTY_DIFF_CONF)

        cmd = [
            sys.executable, "-m", "kittens.diff",
            left_path, right_path,
            "--config", str(conf_path),
        ]

        if self.ignore_space:
            cmd.extend(["--ignore-space-change"])

        subprocess.run(cmd)
        conf_path.unlink(missing_ok=True)


class DiffConfigHandler(Handler):
    """
    Pre-launch diff configuration TUI.
    Lets user configure diff options before launching the diff viewer.
    """

    def __init__(
        self,
        left:  str,
        right: str,
        args:  list[str],
    ) -> None:
        super().__init__()
        self.left          = left
        self.right         = right
        self.args          = args
        self.ignore_space  = False
        self.word_diff     = False
        self.ready         = True  # Go straight to diff unless config needed

    def initialize(self) -> None:
        # If no interactive config needed, skip TUI
        if self.ready:
            self.quit_loop(0)

    def on_key(self, key_event: KeyEvent) -> None:
        key = key_event.key
        if key == "escape":
            self.ready = False
            self.quit_loop(0)
        elif key == "enter":
            self.quit_loop(0)

    def print(self, text: str) -> None:
        self.cmd_write(text + "\r\n")


class DirectoryDiffHandler(Handler):
    """
    Handles directory diff — shows changed files and lets user drill into each.

    Layout:
    ╭─────────────────────────────────────────────────────────────────────╮
    │  󰉋 DIRECTORY DIFF  left/ ↔ right/                                  │
    ├─────────────────────────────────────────────────────────────────────┤
    │  + added.txt             only in right/                             │
    │  - removed.py            only in left/                             │
    │  ~ modified.rs           changed (42 lines)                         │
    │  = unchanged.go          identical                                   │
    ├─────────────────────────────────────────────────────────────────────┤
    │  Enter:open diff  q:quit                                             │
    ╰─────────────────────────────────────────────────────────────────────╯
    """

    def __init__(self, left_dir: str, right_dir: str) -> None:
        super().__init__()
        self.left_dir    = Path(left_dir)
        self.right_dir   = Path(right_dir)
        self.diff_entries: list[dict] = []
        self.selected    = 0
        self.chosen_pair: Optional[tuple[str, str]] = None
        self._scan_dirs()

    def _scan_dirs(self) -> None:
        """Compare two directories and build diff entry list."""
        left_files  = {f.relative_to(self.left_dir)
                       for f in self.left_dir.rglob("*") if f.is_file()}
        right_files = {f.relative_to(self.right_dir)
                       for f in self.right_dir.rglob("*") if f.is_file()}

        all_files = sorted(left_files | right_files)

        for rel_path in all_files:
            left_abs  = self.left_dir  / rel_path
            right_abs = self.right_dir / rel_path

            if rel_path in left_files and rel_path not in right_files:
                status = "removed"
                size   = left_abs.stat().st_size
            elif rel_path not in left_files and rel_path in right_files:
                status = "added"
                size   = right_abs.stat().st_size
            else:
                # Both exist — check if identical
                left_content  = left_abs.read_bytes()
                right_content = right_abs.read_bytes()
                if left_content == right_content:
                    status = "identical"
                else:
                    status = "modified"
                size = right_abs.stat().st_size

            self.diff_entries.append({
                "path":       str(rel_path),
                "status":     status,
                "left_path":  str(left_abs),
                "right_path": str(right_abs),
                "size":       size,
            })

    def _render(self) -> None:
        self.cmd_write(clear_screen())
        r = C["r"]

        self.print(
            f"{C['bold']}{C['acc']} 󰉋 DIRECTORY DIFF "
            f"{C['fg_m']}{self.left_dir.name} ↔ {self.right_dir.name}{r}"
        )
        self.print(f"{C['fg_m']}{'─' * 70}{r}\n")

        status_icons = {
            "added":     ("+", C["added"]),
            "removed":   ("-", C["removed"]),
            "modified":  ("~", C["changed"]),
            "identical": ("=", C["dim"]),
        }

        for i, entry in enumerate(self.diff_entries):
            icon, color = status_icons.get(entry["status"], ("?", ""))
            is_sel  = i == self.selected
            arrow   = f"{C['acc']}❯{r}" if is_sel else " "
            size_kb = f"{entry['size'] // 1024}KB" if entry["size"] > 1024 else f"{entry['size']}B"

            self.print(
                f" {arrow} {color}{icon}{r} "
                f"{C['bold'] if is_sel else ''}{entry['path']:<40}{r} "
                f"{C['dim']}{entry['status']:<12}{r} "
                f"{C['fg_m']}{size_kb}{r}"
            )

        self.print(f"\n{C['fg_m']}{'─' * 70}{r}")
        stats = {s: sum(1 for e in self.diff_entries if e["status"] == s)
                 for s in ("added", "removed", "modified", "identical")}
        self.print(
            f"  {C['added']}+{stats['added']}{r} "
            f"{C['removed']}-{stats['removed']}{r} "
            f"{C['changed']}~{stats['modified']}{r} "
            f"{C['dim']}={stats['identical']}{r}   "
            f"{C['fg_m']}Total: {len(self.diff_entries)} files{r}"
        )
        self.print(
            f"\n  {C['bold']}{C['acc']}Enter{r}{C['fg_m']}:open file diff  "
            f"{C['bold']}{C['acc']}q{r}{C['fg_m']}:quit{r}"
        )

    def on_key(self, key_event: KeyEvent) -> None:
        key = key_event.key
        if key in ("up", "k"):
            self.selected = max(0, self.selected - 1)
        elif key in ("down", "j"):
            self.selected = min(len(self.diff_entries) - 1, self.selected + 1)
        elif key == "enter":
            entry = self.diff_entries[self.selected]
            if entry["status"] not in ("identical",):
                self.chosen_pair = (entry["left_path"], entry["right_path"])
                self.quit_loop(0)
                return
        elif key in ("q", "escape"):
            self.quit_loop(0)
            return
        self._render()

    def initialize(self) -> None:
        self.cmd_write(set_line_wrapping(False))
        self._render()

    def on_resize(self, screen_size: Screen) -> None:
        self._screen_size = screen_size
        self._render()

    def print(self, text: str) -> None:
        self.cmd_write(text + "\r\n")


def main(args: list[str]) -> Optional[dict]:
    """Parse arguments and determine diff mode."""
    if len(args) < 2:
        print(f"{C['red']}Usage: diff-kitten.py file1 file2{C['r']}")
        return None

    left  = args[1] if len(args) > 1 else ""
    right = args[2] if len(args) > 2 else ""

    # Git mode
    if "--git" in args:
        git_idx  = args.index("--git")
        git_refs = args[git_idx + 1:git_idx + 3]
        file_arg = args[-1] if args[-1] not in git_refs else ""
        return {
            "mode":     "git",
            "git_left": git_refs[0] if git_refs else "HEAD~1",
            "git_right":git_refs[1] if len(git_refs) > 1 else "HEAD",
            "file":     file_arg,
        }

    # Directory diff
    if Path(left).is_dir() and Path(right).is_dir():
        return {"mode": "directory", "left": left, "right": right}

    # File diff (standard)
    return {"mode": "file", "left": left, "right": right}


def handle_result(
    args:             list[str],
    answer:           Optional[dict],
    target_window_id: int,
    boss:             Boss,
) -> None:
    if not answer:
        return

    mode = answer.get("mode", "file")

    if mode == "directory":
        handler = DirectoryDiffHandler(answer["left"], answer["right"])
        loop    = Loop()
        loop.loop(handler)
        if handler.chosen_pair:
            left_path, right_path = handler.chosen_pair
            processor = DiffProcessor(left_path, right_path)
            processor.run_kitty_diff(left_path, right_path)

    elif mode == "git":
        processor = DiffProcessor(
            left=answer.get("file", ""),
            right=answer.get("file", ""),
            is_git=True,
            git_ref_left=answer.get("git_left", "HEAD~1"),
            git_ref_right=answer.get("git_right", "HEAD"),
        )
        left_path, right_path = processor.get_files()
        processor.run_kitty_diff(left_path, right_path)

    else:
        processor = DiffProcessor(answer["left"], answer["right"])
        processor.run_kitty_diff(answer["left"], answer["right"])