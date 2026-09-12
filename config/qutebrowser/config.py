# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔥 ASH DOTFILES v5.0 OMEGA — QUTEBROWSER CONFIG ULTRA                     ║
# ║  ⌨️  Vim-native • Privacy-first • ASH-integrated • Blazing fast             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

import json
import os
import re
import subprocess
from pathlib import Path

# ── Prevent config.py from being overwritten by :set
config.load_autoconfig(False)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🎨  HELPERS — ASH THEME INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def _ash_color(var: str, fallback: str) -> str:
    """Read ASH theme color from environment, fallback to default."""
    return os.environ.get(var, fallback)


def _hex_to_rgba(hex_color: str, alpha: float) -> str:
    """Convert a #rrggbb hex color to an rgba() string."""
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return f"rgba({r}, {g}, {b}, {alpha})"


def _mix(color1: str, color2: str, ratio: float) -> str:
    """Blend color1 toward color2 by ratio (0.0–1.0), returning #rrggbb."""
    def _ch(ch: str) -> int:
        return int(ch, 16)

    c1, c2 = color1.lstrip("#"), color2.lstrip("#")
    channels = []
    for i in (0, 2, 4):
        v1, v2 = _ch(c1[i:i + 2]), _ch(c2[i:i + 2])
        v = round(v1 + (v2 - v1) * ratio)
        channels.append(f"{v:02x}")
    return f"#{''.join(channels)}"


def _darken(hex_color: str, amount: float) -> str:
    """Darken a hex color by blending toward black by amount."""
    return _mix(hex_color, "#000000", amount)


# ── Load colors ────────────────────────────────────────
_c = {}
_state_json = Path.home() / ".local/share/ash-dotfiles/state/current-theme.json"
_fallback = {
    "rosewater": "#f5e0dc", "flamingo": "#f2cdcd", "pink": "#f5c2e7",
    "mauve": "#cba6f7", "red": "#f38ba8", "maroon": "#eba0ac",
    "peach": "#fab387", "yellow": "#f9e2af", "green": "#a6e3a1",
    "teal": "#94e2d5", "sky": "#89dceb", "sapphire": "#74c7ec",
    "blue": "#89b4fa", "lavender": "#b4befe",
    "text": "#cdd6f4", "subtext1": "#bac2de", "subtext0": "#a6adc8",
    "overlay2": "#9399b2", "overlay1": "#7f849c", "overlay0": "#6c7086",
    "surface2": "#585b70", "surface1": "#45475a", "surface0": "#313244",
    "base": "#1e1e2e", "mantle": "#181825", "crust": "#11111b",
}
try:
    if _state_json.exists():
        _loaded = json.loads(_state_json.read_text(encoding="utf-8"))
        if isinstance(_loaded, dict):
            _c = {**_fallback, **(_loaded.get("colors") or _loaded)}
        else:
            _c = dict(_fallback)
    else:
        _c = dict(_fallback)
except Exception:
    _c = dict(_fallback)

# Env vars take final precedence
for _prefix in ("ASH_COLOR_ROSEWATER", "ASH_COLOR_FLAMINGO", "ASH_COLOR_PINK",
                "ASH_COLOR_MAUVE", "ASH_COLOR_RED", "ASH_COLOR_MAROON",
                "ASH_COLOR_PEACH", "ASH_COLOR_YELLOW", "ASH_COLOR_GREEN",
                "ASH_COLOR_TEAL", "ASH_COLOR_SKY", "ASH_COLOR_SAPPHIRE",
                "ASH_COLOR_BLUE", "ASH_COLOR_LAVENDER", "ASH_COLOR_TEXT",
                "ASH_COLOR_SUBTEXT1", "ASH_COLOR_SUBTEXT0", "ASH_COLOR_OVERLAY2",
                "ASH_COLOR_OVERLAY1", "ASH_COLOR_OVERLAY0", "ASH_COLOR_SURFACE2",
                "ASH_COLOR_SURFACE1", "ASH_COLOR_SURFACE0", "ASH_COLOR_BASE",
                "ASH_COLOR_MANTLE", "ASH_COLOR_CRUST"):
    _env_name = _prefix.lower().replace("ash_color_", "")
    _val = os.environ.get(_prefix)
    if _val is not None:
        _c[_env_name] = _val

ROSEWATER = _c["rosewater"]
FLAMINGO  = _c["flamingo"]
PINK      = _c["pink"]
MAUVE     = _c["mauve"]
RED       = _c["red"]
MAROON    = _c["maroon"]
PEACH     = _c["peach"]
YELLOW    = _c["yellow"]
GREEN     = _c["green"]
TEAL      = _c["teal"]
SKY       = _c["sky"]
SAPPHIRE  = _c["sapphire"]
BLUE      = _c["blue"]
LAVENDER  = _c["lavender"]
TEXT      = _c["text"]
SUBTEXT1  = _c["subtext1"]
SUBTEXT0  = _c["subtext0"]
OVERLAY2  = _c["overlay2"]
OVERLAY1  = _c["overlay1"]
OVERLAY0  = _c["overlay0"]
SURFACE2  = _c["surface2"]
SURFACE1  = _c["surface1"]
SURFACE0  = _c["surface0"]
BASE      = _c["base"]
MANTLE    = _c["mantle"]
CRUST     = _c["crust"]

# Semantic aliases
ACCENT    = MAUVE
BG        = BASE
BG_ALT    = MANTLE
BG_DARK   = CRUST
FG        = TEXT
FG_DIM    = SUBTEXT0
BORDER    = SURFACE0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🔧  GENERAL SETTINGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Backend ──────────────────────────────────────────
c.backend = "webengine"

# ── Session ──────────────────────────────────────────
c.auto_save.session     = True
c.session.lazy_restore  = True
c.session.default_name  = "ash-session"

# ── Startup ───────────────────────────────────────────
c.url.start_pages       = ["about:blank"]
c.url.default_page      = "about:blank"
c.url.open_base_url     = True

# ── Search engines ────────────────────────────────────
c.url.searchengines = {
    "DEFAULT":  "https://search.brave.com/search?q={}",
    "b":        "https://search.brave.com/search?q={}",
    "g":        "https://www.google.com/search?q={}",
    "d":        "https://duckduckgo.com/?q={}",
    "ddg":      "https://duckduckgo.com/?q={}",
    "sp":       "https://www.startpage.com/search?q={}",
    "yt":       "https://www.youtube.com/results?search_query={}",
    "gh":       "https://github.com/search?q={}",
    "ghr":      "https://github.com/{}",
    "aur":      "https://aur.archlinux.org/packages/?K={}",
    "arch":     "https://wiki.archlinux.org/index.php?search={}",
    "npm":      "https://www.npmjs.com/search?q={}",
    "crates":   "https://crates.io/search?q={}",
    "pypi":     "https://pypi.org/search/?q={}",
    "mdn":      "https://developer.mozilla.org/en-US/search?q={}",
    "wiki":     "https://en.wikipedia.org/wiki/{}",
    "maps":     "https://www.openstreetmap.org/search?query={}",
    "wa":       "https://www.wolframalpha.com/input?i={}",
    "translate": "https://translate.google.com/?text={}&sl=auto&tl=en",
    "reddit":   "https://www.reddit.com/search/?q={}",
    "ml":       "https://lib.rs/search?q={}",
    "pkgs":     "https://search.nixos.org/packages?query={}",
    "nix":      "https://nixos.wiki/index.php?search={}",
    "docker":   "https://hub.docker.com/search?q={}",
    "k8s":      "https://kubernetes.io/search/?q={}",
}

# ── Completion ────────────────────────────────────────
c.completion.height                             = "40%"
c.completion.quick                              = True
c.completion.scrollbar.padding                  = 2
c.completion.scrollbar.width                    = 4
c.completion.show                               = "auto"
c.completion.shrink                             = True
c.completion.timestamp_format                   = "%d %b %Y"
c.completion.use_best_match                     = True
c.completion.web_history.exclude                = []
c.completion.web_history.max_items              = 1000

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🔒  PRIVACY & SECURITY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Content blocking ──────────────────────────────────
c.content.blocking.enabled                      = True
c.content.blocking.method                       = "both"
c.content.blocking.adblock.lists               = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://easylist.to/easylist/fanboy-annoyance.txt",
    "https://easylist-downloads.adblockplus.org/antiadblockfilters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/annoyances-cookies.txt",
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
    "https://raw.githubusercontent.com/nicehash/NiceHashQuickMiner/master/nhqm/filters.txt",
]
c.content.blocking.hosts.lists                 = [
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
    "https://raw.githubusercontent.com/nicehash/NiceHashQuickMiner/master/nhqm/filters.txt",
]

# ── Cookies ───────────────────────────────────────────
c.content.cookies.accept                        = "no-3rdparty"
c.content.cookies.store                         = True

# ── JavaScript ────────────────────────────────────────
c.content.javascript.enabled                    = True
c.content.javascript.clipboard                  = "none"
c.content.javascript.can_open_tabs_automatically = False
c.content.javascript.can_close_tabs             = False
c.content.javascript.log                        = {
    "unknown": "debug",
    "info":    "debug",
    "warning": "debug",
    "error":   "debug",
}

# ── Permissions ───────────────────────────────────────
c.content.geolocation                           = False
c.content.notifications.enabled                 = False
c.content.desktop_capture                       = False
c.content.media.audio_capture                   = False
c.content.media.video_capture                   = False
c.content.media.audio_video_capture             = False
c.content.mouse_lock                            = "ask"
c.content.autoplay                              = False

# ── TLS / HTTPS ────────────────────────────────────────
c.content.tls.certificate_errors                = "ask-block-thirdparty"

# ── Headers ────────────────────────────────────────────
c.content.headers.do_not_track                  = True
c.content.headers.referer                       = "same-domain"
c.content.headers.custom                        = {
    "Sec-GPC": "1",
}
c.content.headers.accept_language               = ""
c.content.headers.user_agent                    = (
    "Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0"
)

# ── Fingerprinting ────────────────────────────────────
c.content.canvas_reading                        = False
c.content.webgl                                 = True
c.content.hyperlink_auditing                    = False

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🚀  PERFORMANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Cache ─────────────────────────────────────────────
c.content.cache.size                            = 0  # unlimited
c.content.cache.maximum_pages                   = 0  # unlimited

# ── Prefetch / Preload ────────────────────────────────
c.content.dns_prefetch                          = True

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🖥️  DISPLAY & UI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Window ───────────────────────────────────────────
c.window.title_format                           = "{private}{perc}{current_title} — Qutebrowser 🦊"
c.window.transparent                            = False

# ── Zoom ─────────────────────────────────────────────
c.zoom.default                                  = "100%"
c.zoom.levels = [
    "25%", "33%", "50%", "67%", "75%", "90%",
    "100%", "110%", "125%", "150%", "175%", "200%",
    "250%", "300%", "400%", "500%",
]

# ── Scrolling ─────────────────────────────────────────
c.scrolling.smooth                              = True
c.scrolling.bar                                 = "overlay"

# ── Status bar ────────────────────────────────────────
c.statusbar.show                                = "in-mode"
c.statusbar.position                            = "bottom"
c.statusbar.padding                             = {"top": 3, "bottom": 3, "left": 6, "right": 6}
c.statusbar.widgets                             = [
    "keypress",
    "url",
    "scroll",
    "history",
    "tabs",
    "progress",
]

# ── Tab bar ───────────────────────────────────────────
c.tabs.show                                     = "multiple"
c.tabs.show_switching_delay                     = 800
c.tabs.position                                 = "top"
c.tabs.padding                                  = {"top": 4, "bottom": 4, "left": 8, "right": 8}
c.tabs.width                                    = "20%"
c.tabs.min_width                                = 80
c.tabs.max_width                                = 250
c.tabs.indicator.width                          = 2
c.tabs.indicator.padding                        = {"top": 0, "bottom": 0, "left": 0, "right": 4}
c.tabs.favicons.show                            = "always"
c.tabs.favicons.scale                           = 1.0
c.tabs.last_close                               = "default-page"
c.tabs.mousewheel_switching                     = True
c.tabs.select_on_remove                         = "next"
c.tabs.undo_stack_size                          = 100
c.tabs.title.format                             = "{audio}{current_title}"
c.tabs.title.format_pinned                      = "{audio}"
c.tabs.close_mouse_button                       = "middle"
c.tabs.new_position.related                     = "next"
c.tabs.new_position.unrelated                   = "last"
c.tabs.wrap                                     = True
c.tabs.mode_on_change                           = "restore"
c.tabs.background                               = True

# ── Downloads ─────────────────────────────────────────
c.downloads.location.directory                  = "~/Downloads"
c.downloads.location.prompt                     = True
c.downloads.location.remember                   = True
c.downloads.location.suggestion                 = "both"
c.downloads.open_dispatcher                     = "xdg-open {}"
c.downloads.position                            = "top"
c.downloads.prevent_mixed_content               = True
c.downloads.remove_finished                     = 5000

# ── Hints ─────────────────────────────────────────────
c.hints.mode                                    = "letter"
c.hints.chars                                   = "asdfghjklqwertyuiopzxcvbnm"
c.hints.min_chars                               = 1
c.hints.scatter                                 = True
c.hints.uppercase                               = False
c.hints.radius                                  = 4
c.hints.padding                                 = {"top": 1, "bottom": 1, "left": 4, "right": 4}
c.hints.border                                  = f"1px solid {ACCENT}"
c.hints.dictionary                              = "/usr/share/dict/words"

# ── Input ─────────────────────────────────────────────
c.input.insert_mode.auto_enter                  = True
c.input.insert_mode.auto_leave                  = True
c.input.insert_mode.auto_load                   = False
c.input.insert_mode.plugins                     = False
c.input.insert_mode.leave_on_load               = True
c.input.partial_timeout                         = 5000
c.input.mouse.rocker_gestures                   = False
c.input.mouse.back_forward_buttons              = True

# ── Spellcheck ────────────────────────────────────────
c.spellcheck.languages                          = ["en-US"]

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🔤  FONTS (sourced from ASH config)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_font_ui   = os.environ.get("ASH_FONT_UI",   "Inter")
_font_mono = os.environ.get("ASH_FONT_MONO", "JetBrainsMono Nerd Font")
_font_size = os.environ.get("ASH_FONT_SIZE", "12")

c.fonts.default_family                           = [_font_ui, "Noto Sans", "sans-serif"]
c.fonts.default_size                             = f"{_font_size}pt"
c.fonts.completion.entry                         = f"{_font_size}pt '{_font_ui}'"
c.fonts.completion.category                      = f"bold {_font_size}pt '{_font_ui}'"
c.fonts.contextmenu                              = f"{_font_size}pt '{_font_ui}'"
c.fonts.debug_console                            = f"{_font_size}pt '{_font_mono}'"
c.fonts.downloads                                = f"{_font_size}pt '{_font_ui}'"
c.fonts.hints                                    = f"bold 11pt '{_font_ui}'"
c.fonts.keyhint                                  = f"{_font_size}pt '{_font_ui}'"
c.fonts.messages.error                           = f"{_font_size}pt '{_font_ui}'"
c.fonts.messages.info                            = f"{_font_size}pt '{_font_ui}'"
c.fonts.messages.warning                         = f"{_font_size}pt '{_font_ui}'"
c.fonts.prompts                                  = f"{_font_size}pt '{_font_ui}'"
c.fonts.statusbar                                = f"{_font_size}pt '{_font_ui}'"
c.fonts.tabs.selected                            = f"{_font_size}pt '{_font_ui}'"
c.fonts.tabs.unselected                          = f"{_font_size}pt '{_font_ui}'"
c.fonts.tooltip                                  = f"{_font_size}pt '{_font_ui}'"

# Web fonts
c.fonts.web.family.fixed                        = _font_mono
c.fonts.web.family.sans_serif                   = _font_ui
c.fonts.web.family.standard                     = _font_ui

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🎨  COLORS — ASH DYNAMIC THEME
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Completion widget ─────────────────────────────────
c.colors.completion.fg                           = [TEXT, SUBTEXT0, SUBTEXT0]
c.colors.completion.odd.bg                       = MANTLE
c.colors.completion.even.bg                      = BASE
c.colors.completion.category.fg                  = ACCENT
c.colors.completion.category.bg                  = CRUST
c.colors.completion.category.border.top          = CRUST
c.colors.completion.category.border.bottom       = SURFACE0
c.colors.completion.item.selected.fg             = TEXT
c.colors.completion.item.selected.bg             = SURFACE0
c.colors.completion.item.selected.border.top     = SURFACE0
c.colors.completion.item.selected.border.bottom  = SURFACE0
c.colors.completion.item.selected.match.fg       = ACCENT
c.colors.completion.match.fg                     = ACCENT
c.colors.completion.scrollbar.fg                 = SURFACE2
c.colors.completion.scrollbar.bg                 = MANTLE

# ── Context menu ──────────────────────────────────────
c.colors.contextmenu.disabled.bg                 = MANTLE
c.colors.contextmenu.disabled.fg                 = OVERLAY0
c.colors.contextmenu.menu.bg                     = MANTLE
c.colors.contextmenu.menu.fg                     = TEXT
c.colors.contextmenu.selected.bg                 = SURFACE0
c.colors.contextmenu.selected.fg                 = TEXT

# ── Downloads ─────────────────────────────────────────
c.colors.downloads.bar.bg                        = CRUST
c.colors.downloads.start.fg                      = CRUST
c.colors.downloads.start.bg                      = BLUE
c.colors.downloads.stop.fg                       = CRUST
c.colors.downloads.stop.bg                       = GREEN
c.colors.downloads.error.fg                      = RED

# ── Hints ─────────────────────────────────────────────
c.colors.hints.fg                                = CRUST
c.colors.hints.bg                                = YELLOW
c.colors.hints.match.fg                          = PEACH

# ── Keyhint ───────────────────────────────────────────
c.colors.keyhint.fg                              = TEXT
c.colors.keyhint.bg                              = _hex_to_rgba(MANTLE, 0.92)
c.colors.keyhint.suffix.fg                       = ACCENT

# ── Messages ──────────────────────────────────────────
c.colors.messages.error.fg                       = CRUST
c.colors.messages.error.bg                       = RED
c.colors.messages.error.border                   = _darken(RED, 0.1)
c.colors.messages.warning.fg                     = CRUST
c.colors.messages.warning.bg                     = YELLOW
c.colors.messages.warning.border                 = _darken(YELLOW, 0.1)
c.colors.messages.info.fg                        = TEXT
c.colors.messages.info.bg                        = MANTLE
c.colors.messages.info.border                    = SURFACE0

# ── Prompts ───────────────────────────────────────────
c.colors.prompts.fg                              = TEXT
c.colors.prompts.bg                              = MANTLE
c.colors.prompts.border                          = f"1px solid {SURFACE0}"
c.colors.prompts.selected.fg                     = TEXT
c.colors.prompts.selected.bg                     = SURFACE0

# ── Status bar ────────────────────────────────────────
c.colors.statusbar.normal.fg                     = SUBTEXT0
c.colors.statusbar.normal.bg                     = CRUST
c.colors.statusbar.insert.fg                     = GREEN
c.colors.statusbar.insert.bg                     = CRUST
c.colors.statusbar.passthrough.fg                = BLUE
c.colors.statusbar.passthrough.bg                = CRUST
c.colors.statusbar.private.fg                    = PINK
c.colors.statusbar.private.bg                    = _mix(CRUST, PINK, 0.08)
c.colors.statusbar.command.fg                    = TEXT
c.colors.statusbar.command.bg                    = MANTLE
c.colors.statusbar.command.private.fg            = PINK
c.colors.statusbar.command.private.bg            = _mix(MANTLE, PINK, 0.08)
c.colors.statusbar.caret.fg                      = MAUVE
c.colors.statusbar.caret.bg                      = CRUST
c.colors.statusbar.caret.selection.fg            = LAVENDER
c.colors.statusbar.caret.selection.bg            = CRUST
c.colors.statusbar.progress.bg                   = ACCENT
c.colors.statusbar.url.fg                        = SUBTEXT0
c.colors.statusbar.url.error.fg                  = RED
c.colors.statusbar.url.hover.fg                  = BLUE
c.colors.statusbar.url.success.http.fg           = YELLOW
c.colors.statusbar.url.success.https.fg          = GREEN
c.colors.statusbar.url.warn.fg                   = YELLOW

# ── Tab bar ───────────────────────────────────────────
c.colors.tabs.bar.bg                             = CRUST
c.colors.tabs.indicator.start                    = BLUE
c.colors.tabs.indicator.stop                     = GREEN
c.colors.tabs.indicator.error                    = RED
c.colors.tabs.indicator.system                   = "rgb"
c.colors.tabs.odd.fg                             = OVERLAY1
c.colors.tabs.odd.bg                             = MANTLE
c.colors.tabs.even.fg                            = OVERLAY1
c.colors.tabs.even.bg                            = MANTLE
c.colors.tabs.selected.odd.fg                    = TEXT
c.colors.tabs.selected.odd.bg                    = BASE
c.colors.tabs.selected.even.fg                   = TEXT
c.colors.tabs.selected.even.bg                   = BASE
c.colors.tabs.pinned.odd.fg                      = SUBTEXT0
c.colors.tabs.pinned.odd.bg                      = SURFACE0
c.colors.tabs.pinned.even.fg                     = SUBTEXT0
c.colors.tabs.pinned.even.bg                     = SURFACE0
c.colors.tabs.pinned.selected.odd.fg             = ACCENT
c.colors.tabs.pinned.selected.odd.bg             = BASE
c.colors.tabs.pinned.selected.even.fg            = ACCENT
c.colors.tabs.pinned.selected.even.bg            = BASE

# ── Tooltip ───────────────────────────────────────────
c.colors.tooltip.fg                              = TEXT
c.colors.tooltip.bg                              = SURFACE0

# ── Webpage dark mode ─────────────────────────────────
c.colors.webpage.bg                              = BASE
c.colors.webpage.preferred_color_scheme          = "dark"
c.colors.webpage.darkmode.enabled                = True
c.colors.webpage.darkmode.algorithm              = "lightness-cielab"
c.colors.webpage.darkmode.contrast               = 0.0
c.colors.webpage.darkmode.grayscale.all          = False
c.colors.webpage.darkmode.grayscale.images       = 0.0
c.colors.webpage.darkmode.policy.images          = "smart"
c.colors.webpage.darkmode.policy.page            = "smart"
c.colors.webpage.darkmode.threshold.background   = 100
c.colors.webpage.darkmode.threshold.text         = 150

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ⌨️  KEYBINDINGS — VIM ULTRA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Unbind conflicting defaults ────────────────────────
config.unbind("d",  mode="normal")
config.unbind("D",  mode="normal")
config.unbind("<Ctrl-q>", mode="normal")

# ── NORMAL MODE ────────────────────────────────────────

# Navigation
config.bind("H",          "back",                              mode="normal")
config.bind("L",          "forward",                           mode="normal")
config.bind("J",          "tab-prev",                          mode="normal")
config.bind("K",          "tab-next",                          mode="normal")
config.bind("r",          "reload",                            mode="normal")
config.bind("R",          "reload -f",                         mode="normal")
config.bind("gh",         "home",                              mode="normal")
config.bind("gH",         "home -t",                           mode="normal")
config.bind("gu",         "navigate up",                       mode="normal")
config.bind("gU",         "navigate up -t",                    mode="normal")

# Tab management
config.bind("<Ctrl-t>",   "open -t",                           mode="normal")
config.bind("<Ctrl-w>",   "tab-close",                         mode="normal")
config.bind("<Ctrl-Tab>", "tab-next",                          mode="normal")
config.bind("<Ctrl-Shift-Tab>", "tab-prev",                    mode="normal")
config.bind("d",          "tab-close",                         mode="normal")
config.bind("D",          "tab-close -o",                      mode="normal")
config.bind("u",          "undo",                              mode="normal")
config.bind("gt",         "tab-focus",                         mode="normal")
config.bind("<Alt-1>",    "tab-focus 1",                       mode="normal")
config.bind("<Alt-2>",    "tab-focus 2",                       mode="normal")
config.bind("<Alt-3>",    "tab-focus 3",                       mode="normal")
config.bind("<Alt-4>",    "tab-focus 4",                       mode="normal")
config.bind("<Alt-5>",    "tab-focus 5",                       mode="normal")
config.bind("<Alt-6>",    "tab-focus 6",                       mode="normal")
config.bind("<Alt-7>",    "tab-focus 7",                       mode="normal")
config.bind("<Alt-8>",    "tab-focus 8",                       mode="normal")
config.bind("<Alt-9>",    "tab-focus -1",                      mode="normal")
config.bind("th",         "tab-move -",                        mode="normal")
config.bind("tl",         "tab-move +",                        mode="normal")
config.bind("tp",         "tab-pin",                           mode="normal")
config.bind("tm",         "tab-mute",                          mode="normal")
config.bind("tD",         "tab-clone",                         mode="normal")

# URL / Open
config.bind("o",          "set-cmd-text -s :open",             mode="normal")
config.bind("O",          "set-cmd-text -s :open -t",          mode="normal")
config.bind("go",         "set-cmd-text -s :open {url}",       mode="normal")
config.bind("gO",         "set-cmd-text -s :open -t {url}",    mode="normal")
config.bind("xo",         "set-cmd-text -s :open -w",          mode="normal")
config.bind("xO",         "set-cmd-text -s :open -pw",         mode="normal")
config.bind("yy",         "yank url",                          mode="normal")
config.bind("yt",         "yank title",                        mode="normal")
config.bind("yp",         "yank pretty-url",                   mode="normal")
config.bind("pp",         "open -- {clipboard}",               mode="normal")
config.bind("pP",         "open -t -- {clipboard}",            mode="normal")
config.bind("Pp",         "open -- {primary}",                 mode="normal")
config.bind("PP",         "open -t -- {primary}",              mode="normal")

# Scrolling
config.bind("j",          "scroll down",                       mode="normal")
config.bind("k",          "scroll up",                         mode="normal")
config.bind("h",          "scroll left",                       mode="normal")
config.bind("l",          "scroll right",                      mode="normal")
config.bind("<Ctrl-d>",   "scroll-page 0 0.5",                 mode="normal")
config.bind("<Ctrl-u>",   "scroll-page 0 -0.5",                mode="normal")
config.bind("<Ctrl-f>",   "scroll-page 0 1",                   mode="normal")
config.bind("<Ctrl-b>",   "scroll-page 0 -1",                  mode="normal")
config.bind("gg",         "scroll-to-perc 0",                  mode="normal")
config.bind("G",          "scroll-to-perc",                    mode="normal")
config.bind("zz",         "scroll-to-perc 50",                 mode="normal")
config.bind("zt",         "scroll-to-anchor top",              mode="normal")
config.bind("zb",         "scroll-to-anchor bottom",           mode="normal")

# Zoom
config.bind("+",          "zoom-in",                           mode="normal")
config.bind("-",          "zoom-out",                          mode="normal")
config.bind("=",          "zoom",                              mode="normal")
config.bind("<Ctrl-=>",   "zoom-in",                           mode="normal")
config.bind("<Ctrl-->",   "zoom-out",                          mode="normal")
config.bind("<Ctrl-0>",   "zoom",                              mode="normal")

# Find
config.bind("/",          "set-cmd-text /",                    mode="normal")
config.bind("?",          "set-cmd-text ?",                    mode="normal")
config.bind("n",          "search-next",                       mode="normal")
config.bind("N",          "search-prev",                       mode="normal")

# Hints
config.bind("f",          "hint",                              mode="normal")
config.bind("F",          "hint all tab",                      mode="normal")
config.bind(";f",         "hint all tab-fg",                   mode="normal")
config.bind(";b",         "hint all tab-bg",                   mode="normal")
config.bind(";d",         "hint all download",                 mode="normal")
config.bind(";y",         "hint all yank",                     mode="normal")
config.bind(";Y",         "hint all yank-primary",             mode="normal")
config.bind(";r",         "hint --rapid all tab-bg",           mode="normal")
config.bind(";i",         "hint images",                       mode="normal")
config.bind(";I",         "hint images tab",                   mode="normal")

# Selection / Caret
config.bind("v",          "mode-enter caret",                  mode="normal")
config.bind("V",          "mode-enter caret ;; selection-toggle --line", mode="normal")

# Edit / Input
config.bind("I",          "mode-enter insert",                 mode="normal")
config.bind("i",          "mode-enter insert",                 mode="normal")
config.bind("<Ctrl-i>",   "mode-enter insert",                 mode="normal")

# Dev tools
config.bind("<F12>",      "devtools",                          mode="normal")
config.bind("<Ctrl-F12>", "devtools window",                   mode="normal")

# View source
config.bind("gf",         "view-source",                       mode="normal")
config.bind("gF",         "view-source --pygments",            mode="normal")

# Print / Save
config.bind("<Ctrl-p>",   "print",                             mode="normal")
config.bind("<Ctrl-s>",   "download",                          mode="normal")

# History
config.bind("<Ctrl-h>",   "open qute://history/",              mode="normal")
config.bind("<Ctrl-b>",   "open qute://bookmarks/",            mode="normal")

# Settings / Config
config.bind("<Ctrl-,>",   "set-cmd-text -s :set ",             mode="normal")
config.bind("ss",         "set-cmd-text -s :set ",             mode="normal")
config.bind("sk",         "set-cmd-text -s :bind ",            mode="normal")
config.bind("sl",         "config-list-default-mode",          mode="normal")
config.bind("se",         "config-edit",                       mode="normal")
config.bind("sc",         "config-clear --save",               mode="normal")

# ASH integration
config.bind("<Space>at",  "set-cmd-text :spawn ash theme apply ", mode="normal")
config.bind("<Space>as",  "spawn ash snapshot create",         mode="normal")
config.bind("<Space>am",  "set-cmd-text :spawn ash mode ",     mode="normal")

# Misc
config.bind("<Ctrl-q>",   "quit",                              mode="normal")
config.bind("Q",          "quit --save",                       mode="normal")
config.bind("<Ctrl-r>",   "config-source",                     mode="normal")
config.bind("wq",         "quit --save",                       mode="normal")
config.bind("<Space>b",   "set-cmd-text -s :bookmark-add",     mode="normal")
config.bind("B",          "bookmark-list",                     mode="normal")
config.bind("q",          "macro-record",                      mode="normal")
config.bind("@",          "macro-run",                         mode="normal")
config.bind(".",          "repeat-command",                    mode="normal")
config.bind("Tff",        "set content.javascript.enabled false ;; reload", mode="normal")
config.bind("Tft",        "set content.javascript.enabled true  ;; reload", mode="normal")

# ── INSERT MODE ────────────────────────────────────────
config.bind("<Escape>",   "mode-leave",                        mode="insert")
config.bind("jk",         "mode-leave",                        mode="insert")
config.bind("<Ctrl-e>",   "open-editor",                       mode="insert")
config.bind("<Ctrl-a>",   "edit-text",                         mode="insert")

# ── CARET MODE ─────────────────────────────────────────
config.bind("v",          "selection-toggle",                  mode="caret")
config.bind("V",          "selection-toggle --line",           mode="caret")
config.bind("y",          "yank selection",                    mode="caret")
config.bind("<Escape>",   "mode-leave",                        mode="caret")

# ── COMMAND MODE ──────────────────────────────────────
config.bind("<Ctrl-j>",   "completion-item-focus --history-forward", mode="command")
config.bind("<Ctrl-k>",   "completion-item-focus --history-backward", mode="command")
config.bind("<Ctrl-n>",   "completion-item-focus next",        mode="command")
config.bind("<Ctrl-p>",   "completion-item-focus prev",        mode="command")
config.bind("<Tab>",      "completion-item-focus next",        mode="command")
config.bind("<Shift-Tab>","completion-item-focus prev",        mode="command")
config.bind("<Ctrl-d>",   "completion-item-del",               mode="command")
config.bind("<Ctrl-c>",   "mode-leave",                        mode="command")

# ── HINT MODE ─────────────────────────────────────────
config.bind("<Escape>",   "mode-leave",                        mode="hint")
config.bind("<Ctrl-g>",   "mode-leave",                        mode="hint")
config.bind("<Return>",   "hint-follow",                       mode="hint")

# ── PROMPT MODE ───────────────────────────────────────
config.bind("<Ctrl-y>",   "prompt-yes",                        mode="prompt")
config.bind("<Alt-y>",    "prompt-yes",                        mode="prompt")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🛠️  EXTERNAL TOOLS — ASH INTEGRATED
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

c.editor.command                                = ["kitty", "--class", "qb-editor", "-e",
                                                   "nvim", "+{line}", "{file}"]
c.editor.encoding                           = "utf-8"

# File manager for downloads
c.fileselect.handler                        = "external"
c.fileselect.folder.command                 = ["kitty", "-e", "yazi", "--chooser-file={}"]
c.fileselect.single_file.command            = ["kitty", "-e", "yazi", "--chooser-file={}"]
c.fileselect.multiple_files.command         = ["kitty", "-e", "yazi", "--chooser-file={}"]

# Terminal
c.terminal.emulator                             = "kitty"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🔊  NOTIFICATIONS (via dunst)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

c.messages.timeout                              = 3000

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🎨  CUSTOM CSS INJECTION (per-site styling)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Scrollbar styling injected into all pages
_scrollbar_css = f"""
::-webkit-scrollbar {{
    width: 6px !important;
    height: 6px !important;
    background: transparent !important;
}}
::-webkit-scrollbar-thumb {{
    background-color: {SURFACE2} !important;
    border-radius: 9999px !important;
}}
::-webkit-scrollbar-thumb:hover {{
    background-color: {OVERLAY0} !important;
}}
::-webkit-scrollbar-track {{
    background: transparent !important;
}}
::-webkit-scrollbar-corner {{
    background: transparent !important;
}}
::selection {{
    background-color: {_hex_to_rgba(ACCENT, 0.35)} !important;
    color: {TEXT} !important;
}}
"""

# Focus ring styling
_focus_css = f"""
:focus-visible {{
    outline: 2px solid {_hex_to_rgba(ACCENT, 0.8)} !important;
    outline-offset: 2px !important;
}}
:focus:not(:focus-visible) {{
    outline: none !important;
}}
"""

# Write CSS to temp file and inject
_css_dir = Path.home()  / ".local/share/ash-dotfiles/qutebrowser"
_css_dir.mkdir(parents=True, exist_ok=True)
_css_file = _css_dir / "ash-inject.css"

_combined_css = _scrollbar_css + "\n" + _focus_css

try:
    _css_file.write_text(_combined_css, encoding="utf-8")
    c.content.user_stylesheets = [str(_css_file)]
except OSError:
    pass

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  ✅  THEME METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_theme_name    = os.environ.get("ASH_THEME_NAME",    "catppuccin-mocha")
_theme_variant = os.environ.get("ASH_THEME_VARIANT", "dark")
_theme_version = os.environ.get("ASH_VERSION",       "5.0")

# Log theme info to qutebrowser messages (visible via :messages)
# message.info(
#     f"🎨 ASH Theme: {_theme_name} ({_theme_variant}) v{_theme_version} loaded"
# )