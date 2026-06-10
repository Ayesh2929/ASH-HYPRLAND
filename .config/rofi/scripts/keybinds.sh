#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI KEYBIND VIEWER                          ║
# ║           Interactive keybind reference viewer                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"
readonly CONFIG_DIR="${HOME}/.config"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 KEYBIND CATEGORIES
# ═══════════════════════════════════════════════════════════════════════════════

declare -A KEYBINDS

# ── System ────────────────────────────────────────────────────────────────────
KEYBINDS["🖥️  System"]="
SUPER + Return            →  Terminal (Kitty)
SUPER + SHIFT + Return    →  Floating Terminal
SUPER + Q                 →  Close Window
SUPER + SHIFT + Q         →  Force Kill Window
SUPER + Escape            →  Power Menu
SUPER + SHIFT + Escape    →  Exit Hyprland
SUPER + SHIFT + L         →  Lock Screen
SUPER + SHIFT + R         →  Reload Config
CTRL + ALT + L            →  Lock Screen (alt)
"

# ── Launchers ─────────────────────────────────────────────────────────────────
KEYBINDS["🚀  Launchers"]="
SUPER + Space             →  App Launcher
SUPER + SHIFT + Space     →  Full Launcher
SUPER + R                 →  Run Command
SUPER + Tab               →  Window Switcher
SUPER + ALT + S           →  SSH Launcher
SUPER + ALT + E           →  Emoji Picker
SUPER + ALT + C           →  Calculator
SUPER + ALT + M           →  Man Pages
SUPER + ALT + F           →  File Picker
SUPER + ALT + T           →  Translator
SUPER + SHIFT + /         →  Keybind Viewer
"

# ── Theme ─────────────────────────────────────────────────────────────────────
KEYBINDS["🎨  Theme"]="
SUPER + ALT + W           →  Wallpaper Picker
SUPER + SHIFT + W         →  Random Wallpaper
SUPER + CTRL + W          →  Previous Wallpaper
SUPER + ALT + A           →  Re-apply Theme
SUPER + ALT + K           →  Color Picker
SUPER + ALT + G           →  Cycle Screen Shader
"

# ── Screenshots ───────────────────────────────────────────────────────────────
KEYBINDS["📸  Screenshots"]="
Print                     →  Full Screen
SHIFT + Print             →  Area Selection
ALT + Print               →  Active Window
CTRL + Print              →  Monitor
SUPER + Print             →  Edit (swappy)
SUPER + SHIFT + Print     →  OCR Text Extract
SUPER + CTRL + Print      →  Color from Screen
SUPER + ALT + Print       →  Delayed (3s)
"

# ── Recording ─────────────────────────────────────────────────────────────────
KEYBINDS["🎬  Recording"]="
SUPER + F10               →  Toggle Recording
SUPER + SHIFT + F10       →  Record Area
SUPER + CTRL + F10        →  Record with Audio
SUPER + ALT + F10         →  Stop Recording
"

# ── Windows ───────────────────────────────────────────────────────────────────
KEYBINDS["🪟  Windows"]="
SUPER + F                 →  Toggle Floating
SUPER + F11               →  Toggle Fullscreen
SUPER + SHIFT + F         →  Toggle Maximize
SUPER + P                 →  Toggle Pseudo-tile
SUPER + J                 →  Toggle Split (dwindle)
SUPER + C                 →  Center Window
SUPER + SHIFT + P         →  Pin Window
SUPER + G                 →  Toggle Group
"

# ── Focus ─────────────────────────────────────────────────────────────────────
KEYBINDS["🔍  Focus"]="
SUPER + H / ←             →  Focus Left
SUPER + J / ↓             →  Focus Down
SUPER + K / ↑             →  Focus Up
SUPER + L / →             →  Focus Right
ALT + Tab                 →  Cycle Forward
ALT + SHIFT + Tab         →  Cycle Backward
"

# ── Move ──────────────────────────────────────────────────────────────────────
KEYBINDS["📦  Move Windows"]="
SUPER + SHIFT + HJKL      →  Move Window
SUPER + ALT + HJKL        →  Move Floating (fine)
SUPER + CTRL + HJKL       →  Resize Window
SUPER + LMB drag          →  Move with Mouse
SUPER + RMB drag          →  Resize with Mouse
"

# ── Workspaces ────────────────────────────────────────────────────────────────
KEYBINDS["🗂️  Workspaces"]="
SUPER + 1-0               →  Switch Workspace 1-10
SUPER + [                 →  Previous Workspace
SUPER + ]                 →  Next Workspace
SUPER + \\                →  Toggle Last
SUPER + N                 →  Empty Workspace
SUPER + SHIFT + 1-0       →  Move to Workspace
SUPER + -                 →  Magic Scratchpad
SUPER + M                 →  Music Scratchpad
"

# ── Audio ─────────────────────────────────────────────────────────────────────
KEYBINDS["🔊  Audio"]="
XF86AudioRaiseVolume      →  Volume Up 5%
XF86AudioLowerVolume      →  Volume Down 5%
XF86AudioMute             →  Toggle Mute
XF86AudioMicMute          →  Toggle Mic
XF86AudioPlay             →  Play/Pause
XF86AudioNext             →  Next Track
XF86AudioPrev             →  Previous Track
"

# ── Brightness ────────────────────────────────────────────────────────────────
KEYBINDS["☀️  Brightness"]="
XF86MonBrightnessUp       →  Brightness +5%
XF86MonBrightnessDown     →  Brightness -5%
SUPER + F5                →  Toggle Night Light
"

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 DISPLAY
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    # Build category list
    local categories=()
    local display_list=""

    for category in "🖥️  System" "🚀  Launchers" "🎨  Theme" "📸  Screenshots" \
                    "🎬  Recording" "🪟  Windows" "🔍  Focus" "📦  Move Windows" \
                    "🗂️  Workspaces" "🔊  Audio" "☀️  Brightness"; do
        categories+=("${category}")
        display_list+="${category}\n"
    done

    # Show category picker
    local selected_cat
    selected_cat=$(echo -e "${display_list}" | rofi \
        -dmenu \
        -i \
        -p "⌨️ Keybind Category" \
        -theme-str '
            window { width: 500px; }
            listview { lines: 12; }
            element { padding: 10px 14px; font-size: 13px; }
        ' \
        2>/dev/null) || {
        log "INFO" "Keybind viewer cancelled"
        exit 0
    }

    # Show keybinds for selected category
    local binds="${KEYBINDS["${selected_cat}"]:-}"
    if [[ -z "${binds}" ]]; then
        exit 0
    fi

    # Display keybinds
    local action
    action=$(echo -e "${binds}" | grep -v "^$" | rofi \
        -dmenu \
        -i \
        -p "⌨️  ${selected_cat}" \
        -theme-str '
            window { width: 700px; }
            listview { lines: 15; }
            element { padding: 8px 12px; font-size: 12px; font-family: "JetBrainsMono Nerd Font"; }
            entry { enabled: false; }
        ' \
        -no-custom \
        2>/dev/null) || exit 0

    log "INFO" "Keybind viewed: ${selected_cat} — ${action}"
}

main "$@"