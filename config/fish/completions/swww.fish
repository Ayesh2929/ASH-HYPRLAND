# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🖼   SWWW — FISH COMPLETIONS v5.0 OMEGA                                   ║
# ║  Ultra Premium • Smart Wallpaper • Transitions • Dynamic Cache • Live State ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
#  GUARDS & HELPERS
# ══════════════════════════════════════════════════════════════════════════════

function __swww_no_subcommand
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            img kill query init clear restore \
            -h --help -V --version
            return 1
        end
    end
    return 0
end

function __swww_sub_is --argument-names sub
    contains -- "$sub" (commandline -poc)
end

function __swww_seen_flag --argument-names flag
    contains -- "$flag" (commandline -poc)
end

function __swww_daemon_running
    pgrep -x swww-daemon &>/dev/null; \
        or pgrep -f 'swww init' &>/dev/null
end

# ══════════════════════════════════════════════════════════════════════════════
#  DYNAMIC DATA SOURCES
# ══════════════════════════════════════════════════════════════════════════════

# ── Active monitors (from Hyprland / wlr-randr / wayland-info) ────────────────
function __swww_monitors
    # Try Hyprland first (most common)
    if command -q hyprctl
        hyprctl monitors -j 2>/dev/null | \
            python3 -c '
import json, sys
try:
    mons = json.load(sys.stdin)
    for m in mons:
        name = m.get("name", "")
        w    = m.get("width", 0)
        h    = m.get("height", 0)
        desc = m.get("description", "")
        print(name + "\t" + str(w) + "x" + str(h) + " — " + desc)
except:
    pass
' 2>/dev/null
        return
    end
    # wlr-randr fallback
    if command -q wlr-randr
        wlr-randr 2>/dev/null | awk '/^[A-Z]/{gsub(/"/, ""); printf "%s\t", $1} /Enabled/{print "Enabled"}' | \
            string match -rv '^\s'
        return
    end
    # swaymsg fallback
    if command -q swaymsg
        swaymsg -t get_outputs 2>/dev/null | \
            python3 -c '
import json, sys
try:
    outs = json.load(sys.stdin)
    for o in outs:
        name = o.get("name","")
        w    = o.get("current_mode",{}).get("width",0)
        h    = o.get("current_mode",{}).get("height",0)
        print(name + "\t" + str(w) + "x" + str(h))
except:
    pass
' 2>/dev/null
        return
    end
    # Fallback: common monitor names
    printf '%s\t%s\n' \
        DP-1       "DisplayPort 1" \
        DP-2       "DisplayPort 2" \
        HDMI-A-1   "HDMI Port 1" \
        HDMI-A-2   "HDMI Port 2" \
        eDP-1      "Embedded Display (laptop)" \
        all        "All monitors"
end

# ── Current wallpaper from swww query ─────────────────────────────────────────
function __swww_current_wallpapers
    if not __swww_daemon_running; return; end
    swww query 2>/dev/null | \
        awk -F'currently displaying: image: ' '{if($2) print $2}' | \
        string trim
end

# ── Image files (comprehensive search) ────────────────────────────────────────
function __swww_images
    # Current directory and common wallpaper locations
    set -l search_dirs \
        "." \
        "$HOME/Pictures" \
        "$HOME/Pictures/Wallpapers" \
        "$HOME/Pictures/wallpapers" \
        "$HOME/.local/share/wallpapers" \
        "$HOME/.config/wallpapers" \
        "/usr/share/wallpapers" \
        "/usr/share/backgrounds"

    for d in $search_dirs
        if test -d "$d"
            find "$d" -maxdepth 3 -type f \
                \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
                   -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.avif" \
                   -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.tif" \
                   -o -iname "*.pnm" -o -iname "*.pgm" -o -iname "*.ppm" \
                   -o -iname "*.pam" -o -iname "*.farbfeld" \) \
                2>/dev/null | \
                while read -l f
                    set -l size (du -h "$f" 2>/dev/null | cut -f1)
                    set -l ext (string replace -r '^.*\.' '' "$f" | string upper)
                    printf "%s\t%s %s\n" "$f" "$ext" "$size"
                end
            break  # Use first found directory
        end
    end
    # Always include current dir files
    find . -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
           -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.avif" \) \
        2>/dev/null | \
        while read -l f
            printf "%s\tImage\n" "$f"
        end
end

# ── Transition types ───────────────────────────────────────────────────────────
function __swww_transitions
    printf '%s\t%s\n' \
        none          "🚫 No transition — instant change" \
        simple        "⚡ Simple cross-fade" \
        fade          "🌫️  Full fade to black/white" \
        left          "⬅️  Slide from right to left" \
        right         "➡️  Slide from left to right" \
        top           "⬆️  Slide from bottom to top" \
        bottom        "⬇️  Slide from top to bottom" \
        center        "🎯 Grow from center outward" \
        outer         "🔲 Shrink from edges to center" \
        any           "🎲 Random direction wipe" \
        wave          "🌊 Wave distortion wipe" \
        wipe          "💫 Directional color wipe" \
        grow          "🌱 Grow from a point" \
        random        "🎰 Random transition each time"
end

# ── Transition FPS ────────────────────────────────────────────────────────────
function __swww_fps_values
    printf '%s\t%s\n' \
        15   "15 fps — smooth low power" \
        20   "20 fps — balanced" \
        24   "24 fps — cinematic" \
        30   "30 fps — smooth (default)" \
        45   "45 fps — very smooth" \
        60   "60 fps — buttery smooth" \
        90   "90 fps — high refresh" \
        120  "120 fps — ultra high refresh" \
        144  "144 fps — gaming monitor" \
        165  "165 fps — high-end gaming" \
        240  "240 fps — maximum"
end

# ── Transition duration ───────────────────────────────────────────────────────
function __swww_durations
    printf '%s\t%s\n' \
        0.1  "0.1s — ultra fast" \
        0.2  "0.2s — very fast" \
        0.3  "0.3s — fast (default-ish)" \
        0.5  "0.5s — medium fast" \
        0.7  "0.7s — medium" \
        1.0  "1.0s — smooth" \
        1.5  "1.5s — slow" \
        2.0  "2.0s — very slow" \
        3.0  "3.0s — cinematic" \
        5.0  "5.0s — ultra slow"
end

# ── Transition step sizes ──────────────────────────────────────────────────────
function __swww_step_sizes
    printf '%s\t%s\n' \
        1    "1 — maximum detail (slowest)" \
        2    "2 — very fine" \
        5    "5 — fine" \
        20   "20 — default balance" \
        30   "30 — faster" \
        45   "45 — quick" \
        90   "90 — fastest" \
        255  "255 — instant (single frame)"
end

# ── Bezier easing curves ──────────────────────────────────────────────────────
function __swww_beziers
    printf '%s\t%s\n' \
        "0.0,0.0,1.0,1.0"    "linear — no easing" \
        "0.25,0.1,0.25,1.0"  "ease — standard CSS ease" \
        "0.42,0.0,1.0,1.0"   "ease-in — slow start" \
        "0.0,0.0,0.58,1.0"   "ease-out — slow end" \
        "0.42,0.0,0.58,1.0"  "ease-in-out — slow both" \
        "0.34,1.56,0.64,1.0" "back — slight overshoot" \
        "0.36,0.07,0.19,0.97" "elastic — spring effect" \
        "0.87,-0.41,0.19,1.44" "bounce — bouncy" \
        "0.0,0.0,0.2,1.0"    "decelerate — Material Design" \
        "0.4,0.0,1.0,1.0"    "accelerate — Material Design"
end

# ── Resize modes ──────────────────────────────────────────────────────────────
function __swww_resize_modes
    printf '%s\t%s\n' \
        no      "🚫 No resize — original size" \
        crop    "✂️  Crop to fill (no black bars)" \
        fit     "📐 Fit within screen (may have bars)" \
        stretch "🔍 Stretch to fill (may distort)"
end

# ── Fill colors (for padding in fit mode) ─────────────────────────────────────
function __swww_fill_colors
    printf '%s\t%s\n' \
        "000000ff"  "⬛ Black (fully opaque)" \
        "ffffffff"  "⬜ White (fully opaque)" \
        "00000000"  "🔲 Transparent" \
        "1e1e2eff"  "🌑 Catppuccin Mocha Base" \
        "181825ff"  "🌑 Catppuccin Mocha Mantle" \
        "11111bff"  "🌑 Catppuccin Mocha Crust" \
        "282828ff"  "🌑 Gruvbox Dark Background" \
        "002b36ff"  "🌑 Solarized Dark Background" \
        "1a1b26ff"  "🌑 Tokyo Night Background" \
        "191724ff"  "🌑 Rosé Pine Background" \
        "1f2335ff"  "🌑 Tokyo Night Storm" \
        "2e3440ff"  "🌑 Nord Polar Night"
end

# ── Wave dimensions ───────────────────────────────────────────────────────────
function __swww_wave_sizes
    printf '%s\t%s\n' \
        "20,20"    "20×20 — fine wave" \
        "50,30"    "50×30 — default wave" \
        "100,50"   "100×50 — large wave" \
        "200,100"  "200×100 — very large wave" \
        "50,50"    "50×50 — uniform wave" \
        "20,80"    "20×80 — tall narrow wave" \
        "80,20"    "80×20 — wide flat wave"
end

# ── Angle values ──────────────────────────────────────────────────────────────
function __swww_angles
    printf '%s\t%s\n' \
        0    "0°   — left to right" \
        45   "45°  — diagonal top-left to bottom-right" \
        90   "90°  — top to bottom" \
        135  "135° — diagonal top-right to bottom-left" \
        180  "180° — right to left" \
        225  "225° — diagonal bottom-right to top-left" \
        270  "270° — bottom to top" \
        315  "315° — diagonal bottom-left to top-right"
end

# ── Invert Y options ──────────────────────────────────────────────────────────
function __swww_invert_y
    printf '%s\t%s\n' \
        false  "Normal Y axis (default)" \
        true   "Invert Y axis (flip direction)"
end

# ── Transition pos (grow/outer origin point) ───────────────────────────────────
function __swww_positions
    printf '%s\t%s\n' \
        "center"      "🎯 Center of screen" \
        "top-left"    "↖️  Top-left corner" \
        "top-right"   "↗️  Top-right corner" \
        "bottom-left" "↙️  Bottom-left corner" \
        "bottom-right" "↘️ Bottom-right corner" \
        "top"         "⬆️  Top center" \
        "bottom"      "⬇️  Bottom center" \
        "left"        "⬅️  Left center" \
        "right"       "➡️  Right center"
end

# ── Filter types for image scaling ────────────────────────────────────────────
function __swww_filters
    printf '%s\t%s\n' \
        Nearest   "🔲 Nearest neighbor — pixelated/fast" \
        Bilinear  "📐 Bilinear — smooth (default)" \
        CatmullRom "🎨 Catmull-Rom — high quality bicubic" \
        Mitchell  "🖼️  Mitchell — sharp high quality" \
        Lanczos3  "🔬 Lanczos3 — best quality (slowest)"
end

# ── Socket path ───────────────────────────────────────────────────────────────
function __swww_socket_path
    set -l runtime_dir "$XDG_RUNTIME_DIR"
    if test -z "$runtime_dir"
        set runtime_dir "/run/user/$UID"
    end
    echo "$runtime_dir/swww-$WAYLAND_DISPLAY.socket"
end

# ══════════════════════════════════════════════════════════════════════════════
#  TOP-LEVEL SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l swww_commands \
    "img\t🖼️  Set wallpaper image with transition" \
    "init\t🚀 Start swww-daemon" \
    "kill\t💀 Kill swww-daemon" \
    "query\t📊 Query current wallpaper state" \
    "clear\t🧹 Clear wallpaper (solid color)" \
    "restore\t↩️  Restore last set wallpaper" \
    "clear-cache\t🗑️  Clear swww image cache" \

complete -c swww -f -n __swww_no_subcommand -a "$swww_commands"

# ── Global flags ───────────────────────────────────────────────────────────────
complete -c swww -l help    -s h -d "Show help"                              -f
complete -c swww -l version -s V -d "Show swww version"                     -f

# ══════════════════════════════════════════════════════════════════════════════
#  IMG — The main powerhouse command
# ══════════════════════════════════════════════════════════════════════════════

# Positional: image path
complete -c swww -n "__swww_sub_is img" \
    -F -a "(__swww_images)" -d "Image file"

# ── Monitor selection ─────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l outputs -s o         -d "Target monitor(s)"                          -f \
    -a "(__swww_monitors)"

# ── Transition type ───────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l transition-type -s t -d "Transition animation type"                  -f \
    -a "(__swww_transitions)"

# ── Transition fps ────────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l transition-fps       -d "Frames per second for transition"           -f \
    -a "(__swww_fps_values)"

# ── Transition duration ───────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l transition-duration  -d "Total transition duration in seconds"       -f \
    -a "(__swww_durations)"

# ── Transition step ───────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l transition-step      -d "Animation step size (1–255)"               -f \
    -a "(__swww_step_sizes)"

# ── Transition angle ─────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img; and __swww_seen_flag --transition-type wipe left right top bottom any" \
    -l transition-angle     -d "Wipe angle in degrees (0–360)"             -f \
    -a "(__swww_angles)"

# ── Transition position (grow/outer center point) ─────────────────────────────
complete -c swww -n "__swww_sub_is img; and __swww_seen_flag --transition-type grow outer center" \
    -l transition-pos       -d "Origin position (x,y or named)"            -f \
    -a "(__swww_positions)"

# ── Bezier easing ─────────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l transition-bezier    -d "Bezier curve for easing (x1,y1,x2,y2)"     -f \
    -a "(__swww_beziers)"

# ── Wave size (wave transition) ────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l transition-wave      -d "Wave dimensions (width,height)"            -f \
    -a "(__swww_wave_sizes)"

# ── Invert Y for wave/wipe ────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l invert-y             -d "Invert Y axis for transition"              -f \
    -a "(__swww_invert_y)"

# ── Resize mode ───────────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l resize               -d "How to resize image to fit screen"         -f \
    -a "(__swww_resize_modes)"

# ── Fill color (for fit mode padding) ─────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l fill-color           -d "Padding color in RRGGBBAA hex"             -f \
    -a "(__swww_fill_colors)"

# ── Filter quality ────────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l filter               -d "Scaling filter algorithm"                  -f \
    -a "(__swww_filters)"

# ── No cache ──────────────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l no-resize            -d "Don't resize image at all"                 -f

# ── Synchronization ───────────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l sync                 -d "Sync transitions across monitors"          -f

# ── Socket path override ──────────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img" \
    -l socket               -d "Path to swww socket"                        -F \
    -a "(__swww_socket_path)"

# ══════════════════════════════════════════════════════════════════════════════
#  INIT
# ══════════════════════════════════════════════════════════════════════════════

complete -c swww -n "__swww_sub_is init" \
    -l no-cache             -d "Don't load wallpapers from cache"           -f
complete -c swww -n "__swww_sub_is init" \
    -l format               -d "Request specific pixel format from daemon" -f \
    -a "xrgb\tRGB no alpha xbgr\tBGR no alpha rgb\tRGB with alpha bgr\tBGR with alpha"
complete -c swww -n "__swww_sub_is init" \
    -l socket               -d "Socket path override"                       -F \
    -a "(__swww_socket_path)"

# ══════════════════════════════════════════════════════════════════════════════
#  KILL
# ══════════════════════════════════════════════════════════════════════════════

complete -c swww -n "__swww_sub_is kill" \
    -l socket               -d "Socket path"                                -F \
    -a "(__swww_socket_path)"

# ══════════════════════════════════════════════════════════════════════════════
#  QUERY
# ══════════════════════════════════════════════════════════════════════════════

complete -c swww -n "__swww_sub_is query" \
    -l socket               -d "Socket path"                                -F \
    -a "(__swww_socket_path)"

# ══════════════════════════════════════════════════════════════════════════════
#  CLEAR
# ══════════════════════════════════════════════════════════════════════════════

# clear <color> [outputs...]
complete -c swww -n "__swww_sub_is clear; and test (count (commandline -poc)) -le 2" \
    -f -a "(__swww_fill_colors)" -d "Fill color (RRGGBBAA)"

complete -c swww -n "__swww_sub_is clear; and test (count (commandline -poc)) -ge 3" \
    -f -a "(__swww_monitors)" -d "Target monitor"

complete -c swww -n "__swww_sub_is clear" \
    -l socket               -d "Socket path"                                -F \
    -a "(__swww_socket_path)"

# ══════════════════════════════════════════════════════════════════════════════
#  RESTORE
# ══════════════════════════════════════════════════════════════════════════════

complete -c swww -n "__swww_sub_is restore" \
    -l socket               -d "Socket path"                                -F \
    -a "(__swww_socket_path)"

# ══════════════════════════════════════════════════════════════════════════════
#  CLEAR-CACHE
# ══════════════════════════════════════════════════════════════════════════════

complete -c swww -n "__swww_sub_is clear-cache" \
    -l socket               -d "Socket path"                                -F \
    -a "(__swww_socket_path)"

# ══════════════════════════════════════════════════════════════════════════════
#  SWWW-DAEMON (separate binary completions)
# ══════════════════════════════════════════════════════════════════════════════

complete -c swww-daemon \
    -l help    -s h         -d "Show help"                                  -f
complete -c swww-daemon \
    -l version -s V         -d "Show version"                               -f
complete -c swww-daemon \
    -l format               -d "Pixel format" -f \
    -a "xrgb\tRGB (no alpha) xbgr\tBGR (no alpha) rgb\tRGBA bgr\tBGRA"
complete -c swww-daemon \
    -l no-cache             -d "Don't restore from cache on startup"        -f
complete -c swww-daemon \
    -l socket               -d "Socket path override"                       -F

# ══════════════════════════════════════════════════════════════════════════════
#  SMART CONTEXTUAL COMPLETIONS
#  (transition-specific flags only appear for relevant transition types)
# ══════════════════════════════════════════════════════════════════════════════

# angle only makes sense for directional transitions
function __swww_needs_angle
    __swww_sub_is img
    and set -l tokens (commandline -poc)
    and contains -- "--transition-type" $tokens
    and set -l idx (contains -i -- "--transition-type" $tokens)
    and set -l ttype "$tokens[(math $idx + 1)]"
    and contains -- "$ttype" wipe left right top bottom any
end

# position only makes sense for grow/outer
function __swww_needs_position
    __swww_sub_is img
    and set -l tokens (commandline -poc)
    and contains -- "--transition-type" $tokens
    and set -l idx (contains -i -- "--transition-type" $tokens)
    and set -l ttype "$tokens[(math $idx + 1)]"
    and contains -- "$ttype" grow outer center
end

# wave size only for wave transition
function __swww_needs_wave
    __swww_sub_is img
    and set -l tokens (commandline -poc)
    and contains -- "--transition-type" $tokens
    and set -l idx (contains -i -- "--transition-type" $tokens)
    and set -l ttype "$tokens[(math $idx + 1)]"
    and test "$ttype" = "wave"
end

# ── Contextual: transition angle (wipe/directional) ────────────────────────────
complete -c swww -n "__swww_sub_is img; and __swww_needs_angle" \
    -l transition-angle     -d "🧭 Wipe direction angle (0°=left→right, 90°=top→bottom)" -f \
    -a "(__swww_angles)"

# ── Contextual: transition position (grow/outer) ───────────────────────────────
complete -c swww -n "__swww_sub_is img; and __swww_needs_position" \
    -l transition-pos       -d "🎯 Grow/shrink origin point"                -f \
    -a "(__swww_positions)"

# ── Contextual: wave dimensions ────────────────────────────────────────────────
complete -c swww -n "__swww_sub_is img; and __swww_needs_wave" \
    -l transition-wave      -d "🌊 Wave size (width,height pixels)"         -f \
    -a "(__swww_wave_sizes)"

# ══════════════════════════════════════════════════════════════════════════════
#  PRESET TRANSITION COMBOS
#  (smart completions that suggest full transition configurations)
# ══════════════════════════════════════════════════════════════════════════════

function __swww_presets
    printf '%s\t%s\n' \
        "--transition-type=fade --transition-duration=0.5 --transition-fps=60" \
            "🌫️  Smooth fade (0.5s, 60fps)" \
        "--transition-type=wipe --transition-angle=90 --transition-duration=0.7 --transition-fps=60" \
            "💫 Downward wipe (0.7s)" \
        "--transition-type=grow --transition-pos=center --transition-duration=0.6 --transition-fps=60" \
            "🎯 Grow from center (0.6s)" \
        "--transition-type=wave --transition-wave=50,30 --transition-duration=0.8 --transition-fps=60" \
            "🌊 Wave distortion (0.8s)" \
        "--transition-type=left --transition-duration=0.4 --transition-fps=60" \
            "⬅️  Slide left (0.4s)" \
        "--transition-type=random --transition-duration=0.5 --transition-fps=60" \
            "🎲 Random transition (0.5s)" \
        "--transition-type=none" \
            "⚡ Instant (no animation)" \
        "--transition-type=outer --transition-pos=top-left --transition-duration=1.0 --transition-fps=60" \
            "🔲 Shrink from top-left (1.0s)" \
        "--transition-type=simple --transition-step=90 --transition-fps=60" \
            "✨ Simple fast fade" \
        "--transition-type=fade --transition-duration=2.0 --transition-fps=30" \
            "🎬 Cinematic fade (2.0s)"
end

# ══════════════════════════════════════════════════════════════════════════════
#  FISH ABBREVIATIONS FOR SWWW POWER USERS
#  (registered as completions for the 'abbr' suggestion system)
# ══════════════════════════════════════════════════════════════════════════════

# These are provided as informational completions
# Actual abbreviations should go in fish/conf.d/ files

function __swww_abbr_suggestions
    printf '%s\t%s\n' \
        "swww img --transition-type=none"           "⚡ Set wallpaper instantly" \
        "swww img --transition-type=fade"           "🌫️  Fade transition" \
        "swww img --transition-type=grow"           "🌱 Grow from center" \
        "swww img --transition-type=wave"           "🌊 Wave transition" \
        "swww img --transition-type=random"         "🎲 Random transition" \
        "swww query"                                "📊 Check current wallpaper" \
        "swww kill && swww init"                    "🔄 Restart daemon" \
        "swww clear 000000ff"                       "⬛ Clear to black" \
        "swww restore"                              "↩️  Restore last wallpaper"
end
