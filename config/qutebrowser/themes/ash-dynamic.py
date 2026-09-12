# ASH Dotfiles v5.0 — qutebrowser theme (dynamic)
import json
import os
import pathlib

BASE = pathlib.Path.home() / ".local/share/ash-dotfiles/state"
THEME_FILE = BASE / "current-theme.json"

def _env(name: str, default: str) -> str:
    return os.environ.get(f"ASH_COLOR_{name.upper()}", default)

def _load() -> dict:
    colors = {
        "bg":      _env("bg", "#1e1e2e"),
        "surface": _env("surface", "#181825"),
        "text":    _env("text", "#cdd6f4"),
        "muted":   _env("muted", "#6c7086"),
        "accent":  _env("accent", "#cba6f7"),
        "red":     _env("red", "#f38ba8"),
        "green":   _env("green", "#a6e3a1"),
        "yellow":  _env("yellow", "#f9e2af"),
        "blue":    _env("blue", "#89b4fa"),
        "magenta": _env("magenta", "#f5c2e7"),
        "cyan":    _env("cyan", "#94e2d5"),
    }
    try:
        if THEME_FILE.exists():
            with open(THEME_FILE) as f:
                theme = json.load(f)
            for key, value in theme.items():
                if key in colors:
                    colors[key] = value
    except Exception:
        pass
    return colors

_T = _load()

# ---- Palette ---------------------------------------------------------------
bg      = _T["bg"]
surface = _T["surface"]
text    = _T["text"]
muted   = _T["muted"]
accent  = _T["accent"]
red     = _T["red"]
green   = _T["green"]
yellow  = _T["yellow"]
blue    = _T["blue"]
magenta = _T["magenta"]
cyan    = _T["cyan"]

# ---- Base colors -----------------------------------------------------------
c.colors.completion.category.border.top = bg
c.colors.completion.category.border.bottom = bg
c.colors.completion.category.bg = surface
c.colors.completion.category.fg = accent
c.colors.completion.category.fg.active = text
c.colors.completion.fg = text
c.colors.completion.odd.bg = bg
c.colors.completion.even.bg = surface
c.colors.completion.match.fg = accent
c.colors.completion.item.selected.bg = accent
c.colors.completion.item.selected.fg = bg
c.colors.completion.item.selected.match.fg = bg

c.colors.downloads.bar.bg = bg
c.colors.downloads.start.bg = green
c.colors.downloads.start.fg = bg
c.colors.downloads.stop.bg = blue
c.colors.downloads.stop.fg = bg
c.colors.downloads.error.bg = red
c.colors.downloads.error.fg = bg

c.colors.hints.bg = accent
c.colors.hints.fg = bg
c.colors.hints.match.fg = text

c.colors.messages.error.bg = red
c.colors.messages.error.fg = bg
c.colors.messages.info.bg = surface
c.colors.messages.info.fg = text
c.colors.messages.warning.bg = yellow
c.colors.messages.warning.fg = bg

c.colors.prompts.bg = surface
c.colors.prompts.fg = text
c.colors.prompts.selected.bg = accent
c.colors.prompts.selected.fg = bg

c.colors.statusbar.caret.bg = surface
c.colors.statusbar.caret.fg = accent
c.colors.statusbar.caret.selection.bg = accent
c.colors.statusbar.caret.selection.fg = bg
c.colors.statusbar.command.bg = surface
c.colors.statusbar.command.fg = text
c.colors.statusbar.command.private.bg = surface
c.colors.statusbar.command.private.fg = text
c.colors.statusbar.insert.bg = surface
c.colors.statusbar.insert.fg = green
c.colors.statusbar.normal.bg = bg
c.colors.statusbar.normal.fg = text
c.colors.statusbar.passthrough.bg = surface
c.colors.statusbar.passthrough.fg = yellow
c.colors.statusbar.private.bg = bg
c.colors.statusbar.private.fg = text
c.colors.statusbar.progress.bg = accent
c.colors.statusbar.url.error.fg = red
c.colors.statusbar.url.fg = text
c.colors.statusbar.url.hover.fg = accent
c.colors.statusbar.url.success.http.fg = blue
c.colors.statusbar.url.success.https.fg = green
c.colors.statusbar.url.warn.fg = yellow

c.colors.tabs.bar.bg = bg
c.colors.tabs.indicator.error = red
c.colors.tabs.indicator.start = accent
c.colors.tabs.indicator.stop = blue
c.colors.tabs.pinned.even.bg = surface
c.colors.tabs.pinned.even.fg = muted
c.colors.tabs.pinned.selected.even.bg = accent
c.colors.tabs.pinned.selected.even.fg = bg
c.colors.tabs.pinned.selected.odd.bg = accent
c.colors.tabs.pinned.selected.odd.fg = bg
c.colors.tabs.pinned.odd.bg = surface
c.colors.tabs.pinned.odd.fg = muted
c.colors.tabs.selected.even.bg = accent
c.colors.tabs.selected.even.fg = bg
c.colors.tabs.selected.odd.bg = accent
c.colors.tabs.selected.odd.fg = bg
c.colors.tabs.even.bg = surface
c.colors.tabs.even.fg = text
c.colors.tabs.odd.bg = bg
c.colors.tabs.odd.fg = text

c.colors.webpage.bg = bg
