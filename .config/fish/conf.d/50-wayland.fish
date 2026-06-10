# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — FISH WAYLAND ENVIRONMENT                     ║
# ║           Wayland-specific exports and fixes                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# Only apply in Wayland sessions
if not set -q WAYLAND_DISPLAY
    exit 0
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🌊 WAYLAND CORE
# ═══════════════════════════════════════════════════════════════════════════════

set -gx WAYLAND_DISPLAY     $WAYLAND_DISPLAY
set -gx XDG_SESSION_TYPE    wayland
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx XDG_SESSION_DESKTOP Hyprland

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 TOOLKIT BACKENDS
# ═══════════════════════════════════════════════════════════════════════════════

# GTK
set -gx GDK_BACKEND         "wayland,x11"

# Qt
set -gx QT_QPA_PLATFORM     "wayland;xcb"
set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1
set -gx QT_AUTO_SCREEN_SCALE_FACTOR 1

# SDL
set -gx SDL_VIDEODRIVER     wayland

# Clutter
set -gx CLUTTER_BACKEND     wayland

# Firefox
set -gx MOZ_ENABLE_WAYLAND  1
set -gx MOZ_WAYLAND_USE_VAAPI 1

# Electron
set -gx ELECTRON_OZONE_PLATFORM_HINT auto

# Java (fix blank window)
set -gx _JAVA_AWT_WM_NONREPARENTING 1

# ═══════════════════════════════════════════════════════════════════════════════
# 🖼️ WAYLAND-SPECIFIC ALIASES
# ═══════════════════════════════════════════════════════════════════════════════

# Use wayland-native tools
if command -q wl-copy
    abbr -a xclip  'wl-copy'
    abbr -a xsel   'wl-copy'
    abbr -a pbcopy 'wl-copy'
    abbr -a pbpaste 'wl-paste'
end

# Screenshot
if command -q grim
    abbr -a scrot  'grim'
end

# Screen recording
if command -q wf-recorder
    function record
        wf-recorder -f ~/Pictures/Recordings/recording-(date +%Y%m%d_%H%M%S).mp4 $argv
    end
end

# Wayland clipboard functions
function copy
    if test (count $argv) -gt 0
        echo $argv | wl-copy
    else
        wl-copy
    end
end

function paste
    wl-paste
end

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 WAYLAND DEBUGGING
# ═══════════════════════════════════════════════════════════════════════════════

function hypr-log
    # Tail Hyprland log
    tail -f /tmp/hypr/(ls -t /tmp/hypr/ | head -1)/hyprland.log 2>/dev/null
end

function hypr-reload
    hyprctl reload && echo "✓ Hyprland reloaded"
end

function wl-info
    echo "Wayland Display: $WAYLAND_DISPLAY"
    echo "XDG Runtime Dir: $XDG_RUNTIME_DIR"
    echo "Session Type:    $XDG_SESSION_TYPE"
    echo ""
    hyprctl version 2>/dev/null | head -2 || echo "Hyprland not running"
end