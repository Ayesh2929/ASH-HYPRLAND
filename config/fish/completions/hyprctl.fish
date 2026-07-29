# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🪟  HYPRCTL — FISH COMPLETIONS v5.0 OMEGA                                 ║
# ║  Ultra Premium • Dynamic Windows • Live Workspaces • Full IPC Coverage     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Helpers ────────────────────────────────────────────────────────────────────

function __hypr_running
    pgrep -x Hyprland &>/dev/null
end

function __hypr_no_sub
    set -l tokens (commandline -poc)
    for t in $tokens[2..]
        if contains -- "$t" \
            dispatch keyword setcursor getoption getbezier output \
            switchxkblayout seterror notify dismissnotify plugin hyprpaper \
            rollinglog animationstyle setprop version monitors workspaces \
            activeworkspace workspacerules clients activewindow layers devices \
            binds animations instances splash reload kill hyprpaper \
            systeminfo globalshortcuts decorations
            return 1
        end
    end
    return 0
end

function __hypr_sub_is --argument-names sub
    set -l tokens (commandline -poc)
    contains -- "$sub" $tokens
end

# ── Live data from hyprctl ─────────────────────────────────────────────────────

function __hypr_workspaces
    if __hypr_running
        hyprctl workspaces -j 2>/dev/null | \
            python3 -c '
import json, sys
try:
    ws = json.load(sys.stdin)
    for w in ws:
        print(str(w["id"]) + "\t" + str(w["name"]) + " (" + str(w["windows"]) + " windows)")
except:
    for i in range(1, 11):
        print(i)
' 2>/dev/null
    else
        seq 1 10
    end
end

function __hypr_clients
    if __hypr_running
        hyprctl clients -j 2>/dev/null | \
            python3 -c '
import json, sys
try:
    clients = json.load(sys.stdin)
    for c in clients:
        addr  = c.get("address", "")
        cls   = c.get("class", "unknown")
        title = c.get("title", "")[:40]
        ws    = c.get("workspace", {}).get("id", "?")
        print(addr + "\t" + "[ws:" + str(ws) + "] " + cls + " — " + title)
except:
    pass
' 2>/dev/null
    end
end

function __hypr_monitors
    if __hypr_running
        hyprctl monitors -j 2>/dev/null | \
            python3 -c '
import json, sys
try:
    mons = json.load(sys.stdin)
    for m in mons:
        name = m.get("name", "")
        res  = str(m.get("width",0)) + "x" + str(m.get("height",0)) + "@" + str(int(m.get("refreshRate",0)))
        desc = m.get("description", "")
        print(name + "\t" + res + " — " + desc)
except:
    pass
' 2>/dev/null
    else
        printf 'DP-1\tPrimary\nHDMI-A-1\tSecondary\neDP-1\tLaptop'
    end
end

function __hypr_devices
    if __hypr_running
        hyprctl devices -j 2>/dev/null | \
            python3 -c '
import json, sys
try:
    devs = json.load(sys.stdin)
    for cat in ["keyboards", "mice", "tablets", "touch", "switches"]:
        for d in devs.get(cat, []):
            name = d.get("name", d.get("address", ""))
            print(name + "\t" + cat[:-1].capitalize())
except:
    pass
' 2>/dev/null
    end
end

function __hypr_active_window_addr
    if __hypr_running
        hyprctl activewindow -j 2>/dev/null | \
            python3 -c '
import json, sys
try:
    w = json.load(sys.stdin)
    print(w.get("address",""))
except:
    pass
' 2>/dev/null
    end
end

function __hypr_layouts
    printf '%s\t%s\n' \
        dwindle    "Dwindle (default spiral tiling)" \
        master     "Master-Stack layout" \
        hy3        "hy3 i3-style tiling (plugin)" \
        scroller    "Hyprscroller (plugin)" \
        hyprbento  "Hyprbento (plugin)"
end

function __hypr_dispatch_types
    printf '%s\t%s\n' \
        exec                    "Execute a program" \
        execr                   "Execute (no rules applied)" \
        pass                    "Pass keybind to window" \
        killactive              "Kill active window" \
        closewindow             "Close specific window" \
        workspace               "Switch to workspace" \
        movetoworkspace         "Move window to workspace" \
        movetoworkspacesilent   "Move window (no switch)" \
        togglefloating          "Toggle floating" \
        fullscreen              "Toggle fullscreen (0=real 1=max 2=maximize)" \
        fakefullscreen          "Fake fullscreen (client-side)" \
        dpms                    "Toggle DPMS (monitor power)" \
        pin                     "Pin/unpin window (visible on all workspaces)" \
        movefocus               "Move focus (l r u d)" \
        movewindow              "Move window (l r u d mon:NAME)" \
        resizeactive            "Resize active window (x y)" \
        moveactive              "Move active window (x y)" \
        cyclenext               "Cycle to next window" \
        cyclecursor             "Cycle cursor to next window" \
        swapnext                "Swap with next window" \
        swapactivewithprev      "Swap with previous window" \
        focuswindow             "Focus specific window (class or title)" \
        focusmonitor            "Focus a monitor" \
        splitratio              "Change split ratio (±0.x)" \
        toggleopaque            "Toggle window opacity" \
        movecursortocorner      "Move cursor to corner (0-3)" \
        movecursor              "Move cursor (x y)" \
        workspaceopt            "Set workspace option" \
        exit                    "Exit Hyprland" \
        forcerendererreload     "Force reload renderer" \
        changegroupactive       "Cycle active in group (f/b)" \
        global                  "Trigger global shortcut" \
        submap                  "Change submap" \
        movewindowpixel         "Move window by pixels" \
        resizewindowpixel       "Resize window by pixels" \
        togglegroup             "Toggle window group" \
        moveoutofgroup          "Move window out of group" \
        moveintogroup           "Move focused into group" \
        setignoregrouplock      "Set ignore group lock" \
        lockgroups              "Lock groups" \
        lockactivegroup         "Lock active group" \
        denywindowfromgroup     "Deny window from grouping" \
        setfloatingsize         "Set floating window size" \
        centerwindow            "Center floating window" \
        alterzoregion           "Alter zo region" \
        bringactivetotop        "Bring active to top of stack" \
        focusurgentorlast       "Focus urgent or last window" \
        togglespecialworkspace  "Toggle special workspace" \
        movetospecialworkspace  "Move window to special workspace" \
        focusspecialworkspace   "Focus special workspace" \
        swapactiveworkspaces    "Swap two workspaces between monitors" \
        renamesubmap            "Rename current submap" \
        eatmecookies            "Easter egg"
end

function __hypr_keywords
    printf '%s\t%s\n' \
        "general:border_size"                "Border width in pixels" \
        "general:no_border_on_floating"      "Disable border on floating" \
        "general:gaps_in"                    "Inner gaps (pixels)" \
        "general:gaps_out"                   "Outer gaps (pixels)" \
        "general:gaps_workspaces"            "Gaps between workspaces" \
        "general:col.active_border"          "Active border color" \
        "general:col.inactive_border"        "Inactive border color" \
        "general:col.nogroup_border"         "No-group border color" \
        "general:layout"                     "Default tiling layout" \
        "general:no_focus_fallback"          "Don't fall back focus" \
        "general:resize_on_border"           "Resize by dragging border" \
        "general:extend_border_grab_area"    "Extra grab area around border" \
        "general:hover_icon_on_border"       "Show icon when hovering border" \
        "decoration:rounding"                "Corner rounding radius" \
        "decoration:active_opacity"          "Active window opacity" \
        "decoration:inactive_opacity"        "Inactive window opacity" \
        "decoration:fullscreen_opacity"      "Fullscreen window opacity" \
        "decoration:drop_shadow"             "Enable drop shadows" \
        "decoration:shadow_range"            "Shadow range pixels" \
        "decoration:shadow_render_power"     "Shadow power (1-4)" \
        "decoration:col.shadow"              "Shadow color" \
        "decoration:col.shadow_inactive"     "Inactive shadow color" \
        "decoration:dim_inactive"            "Dim inactive windows" \
        "decoration:dim_strength"            "Dim strength (0.0-1.0)" \
        "decoration:blur:enabled"            "Enable blur" \
        "decoration:blur:size"               "Blur radius" \
        "decoration:blur:passes"             "Blur passes (quality)" \
        "decoration:blur:ignore_opacity"     "Blur ignores window opacity" \
        "decoration:blur:new_optimizations"  "Use optimized blur" \
        "decoration:blur:xray"               "Blur sees through groups" \
        "decoration:blur:noise"              "Blur noise amount" \
        "decoration:blur:contrast"           "Blur contrast" \
        "decoration:blur:brightness"         "Blur brightness" \
        "decoration:blur:vibrancy"           "Blur vibrancy (color pop)" \
        "animations:enabled"                 "Enable animations" \
        "animations:first_launch_animation"  "Play first launch animation" \
        "input:kb_layout"                    "Keyboard layout (e.g. us)" \
        "input:kb_variant"                   "Keyboard variant" \
        "input:kb_options"                   "Keyboard options" \
        "input:repeat_rate"                  "Key repeat rate" \
        "input:repeat_delay"                 "Key repeat delay (ms)" \
        "input:sensitivity"                  "Mouse sensitivity" \
        "input:accel_profile"                "Accel profile: flat adaptive custom" \
        "input:force_no_accel"               "Disable mouse accel" \
        "input:left_handed"                  "Left-handed mouse" \
        "input:scroll_method"                "Scroll method" \
        "input:scroll_factor"                "Scroll speed factor" \
        "input:natural_scroll"               "Natural scrolling" \
        "input:follow_mouse"                 "Focus follows mouse (0-3)" \
        "input:float_switch_override_focus"  "Override focus on float switch" \
        "input:touchpad:natural_scroll"      "Touchpad natural scroll" \
        "input:touchpad:disable_while_typing" "Disable touchpad while typing" \
        "input:touchpad:tap-to-click"        "Tap to click" \
        "input:touchpad:drag_lock"           "Touchpad drag lock" \
        "misc:disable_hyprland_logo"         "Disable startup logo" \
        "misc:disable_splash_rendering"      "Disable splash screen" \
        "misc:force_default_wallpaper"       "Force default wallpaper (-1/0/1/2)" \
        "misc:vfr"                           "Variable Frame Rate" \
        "misc:vrr"                           "Variable Refresh Rate" \
        "misc:animate_manual_resizes"        "Animate manual resizes" \
        "misc:focus_on_activate"             "Focus window on ACTIVATE request" \
        "misc:no_direct_scanout"             "Disable direct scanout" \
        "misc:cursor_zoom_factor"            "Cursor zoom level" \
        "misc:allow_session_lock_restore"    "Allow restoring session lock" \
        "cursor:no_hardware_cursors"         "Force software cursors" \
        "cursor:cursor_zoom_factor"          "Cursor zoom factor"
end

function __hypr_notify_icons
    printf '%s\t%s\n' \
        0  "No icon" \
        1  "⚠️  Warning" \
        2  "ℹ️  Info" \
        3  "✅ Hint" \
        4  "❌ Error" \
        5  "🔒 Confused" \
        6  "🆗 OK"
end

function __hypr_output_backends
    printf '%s\t%s\n' \
        wayland  "Nested Wayland output" \
        x11      "Nested X11 output" \
        headless "Headless virtual output"
end

function __hypr_roles
    printf '%s\t%s\n' \
        rounding        "Corner rounding override" \
        forceopaque     "Force opaque" \
        forceopaqueoverlay "Force opaque (include overlays)" \
        forcenoblur     "Disable blur" \
        forcenoborder   "Disable border" \
        forcenodim      "Disable dim" \
        forcenoshadow   "Disable shadow" \
        nomaxsize       "Ignore max size" \
        bordersize      "Border size override" \
        keepaspectratio "Keep aspect ratio on resize" \
        alphainactive   "Inactive alpha" \
        alphaactive     "Active alpha" \
        alphaborder     "Border alpha"
end

function __hypr_layers
    printf '%s\t%s\n' \
        background  "Background layer (lowest)" \
        bottom      "Bottom layer" \
        top         "Top layer" \
        overlay     "Overlay layer (highest)"
end

function __hypr_cursor_shapes
    printf '%s\n' \
        default pointer text crosshair move grab grabbing \
        n-resize s-resize e-resize w-resize \
        ne-resize nw-resize se-resize sw-resize \
        col-resize row-resize all-resize \
        zoom-in zoom-out help wait progress not-allowed
end

function __hypr_bezier_curves
    if __hypr_running
        hyprctl getbezier 2>/dev/null | awk '{print $1}'
    end
    printf '%s\n' \
        linear ease easeIn easeOut easeInOut \
        overshot bounce elastic spring wind
end

function __hypr_cursor_themes
    find /usr/share/icons ~/.local/share/icons ~/.icons -maxdepth 3 -path "*/cursors/default" 2>/dev/null | while read -l f
        basename (dirname (dirname "$f"))
    end
    printf '%s\n' Bibata-Modern-Classic Adwaita Breeze DMZ-Black Phinger-Cursors Nordzy-cursors
end

# ══════════════════════════════════════════════════════════════════════════════
#  TOP-LEVEL SUBCOMMANDS
# ══════════════════════════════════════════════════════════════════════════════

set -l hypr_commands \
    "dispatch\t⚡ Send a dispatch command" \
    "keyword\t⚙️  Set a keyword value live" \
    "setcursor\t🖱️  Set cursor theme & size" \
    "getoption\t🔍 Get a config option value" \
    "getbezier\t📈 Get bezier curve info" \
    "output\t🖥️  Manage virtual outputs" \
    "switchxkblayout\t⌨️  Switch keyboard layout" \
    "seterror\t❌ Set error message" \
    "notify\t🔔 Send a Hyprland notification" \
    "dismissnotify\t✖️  Dismiss notifications" \
    "plugin\t🔌 Plugin management" \
    "hyprpaper\t🖼️  Hyprpaper wallpaper control" \
    "rollinglog\t📜 Get rolling debug log" \
    "animationstyle\t🎬 Set animation style" \
    "setprop\t🎨 Set window property" \
    "kill\t💀 Enter kill cursor mode" \
    "reload\t🔄 Reload config" \
    "systeminfo\t💻 System info" \
    "version\t📌 Hyprland version" \
    "monitors\t🖥️  Monitor info" \
    "workspaces\t🗂️  Workspace info" \
    "activeworkspace\t📍 Active workspace" \
    "workspacerules\t📋 Workspace rules" \
    "clients\t🪟  Client windows info" \
    "activewindow\t🎯 Active window info" \
    "layers\t🗂️  Layer info" \
    "devices\t⌨️  Input devices" \
    "binds\t🎹 Keybinds list" \
    "animations\t🎬 Animation info" \
    "instances\t🔁 Running Hyprland instances" \
    "splash\t💬 Get splash text" \
    "globalshortcuts\t⌨️  Global shortcuts" \
    "decorations\t🎨 Window decorations info"

complete -c hyprctl -f -n __hypr_no_sub -a "$hypr_commands"

# ── Global flags ───────────────────────────────────────────────────────────────
complete -c hyprctl -l help    -s h -d "Show help"                   -f
complete -c hyprctl -l version -s v -d "Show hyprctl version"        -f
complete -c hyprctl -l json    -s j -d "Output as JSON"              -f
complete -c hyprctl -l instance -s i -d "Target Hyprland instance"   -f \
    -a "(hyprctl instances 2>/dev/null | awk '/instance/{print \$NF}')"
complete -c hyprctl -l batch   -s b -d "Batch mode (multiple cmds)"  -f
complete -c hyprctl -l socket  -s s -d "Specify socket path"         -F

# ══════════════════════════════════════════════════════════════════════════════
#  DISPATCH COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is dispatch; and test (count (commandline -poc)) -le 2" \
    -f -a "(__hypr_dispatch_types)"

# dispatch exec — complete with executables
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from exec execr" \
    -f -a "(__fish_complete_command)"

# dispatch workspace — workspace numbers + special
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from workspace" \
    -f -a "(__hypr_workspaces)
    +1\tNext workspace
    -1\tPrevious workspace
    e+1\tRelative next (existing)
    e-1\tRelative prev (existing)
    r+1\tRelative next (with wrapping)
    r-1\tRelative prev (with wrapping)
    m+1\tMonitor relative next
    m-1\tMonitor relative prev
    name:primary\tNamed workspace
    special\tSpecial workspace
    special:magic\tNamed special workspace
    previous\tPrevious workspace
    previous_per_monitor\tPrev workspace on this monitor
    empty\tFirst empty workspace
    emptym\tFirst empty on monitor"

# dispatch movetoworkspace / movetoworkspacesilent
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from movetoworkspace movetoworkspacesilent" \
    -f -a "(__hypr_workspaces)
    special\tSpecial workspace
    special:magic\tNamed special"

# dispatch movefocus / movewindow
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from movefocus movewindow" \
    -f -a "l\tLeft r\tRight u\tUp d\tDown"

# dispatch fullscreen
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from fullscreen" \
    -f -a "0\tReal fullscreen 1\tMaximize 2\tMaximize (keep gaps)"

# dispatch dpms
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from dpms" \
    -f -a "on\tTurn on off\tTurn off toggle\tToggle"

# dispatch focuswindow
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from focuswindow" \
    -f -a "(__hypr_clients)"

# dispatch focusmonitor / movewindow mon:
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from focusmonitor" \
    -f -a "(__hypr_monitors)"

# dispatch submap
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from submap" \
    -f -a "reset\tReset to global"

# dispatch changegroupactive
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from changegroupactive" \
    -f -a "f\tForward b\tBackward"

# dispatch movecursortocorner
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from movecursortocorner" \
    -f -a "0\tBottom-left 1\tBottom-right 2\tTop-left 3\tTop-right"

# dispatch cyclenext
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from cyclenext" \
    -f -a "prev\tPrevious floating\tFloating only tiled\tTiled only"

# dispatch closewindow
complete -c hyprctl \
    -n "__hypr_sub_is dispatch; and __fish_seen_subcommand_from closewindow" \
    -f -a "(__hypr_clients)"

# ══════════════════════════════════════════════════════════════════════════════
#  KEYWORD COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is keyword; and test (count (commandline -poc)) -eq 2" \
    -f -a "(__hypr_keywords)"

# keyword layout value
complete -c hyprctl \
    -n "__hypr_sub_is keyword; and __fish_seen_subcommand_from 'general:layout'" \
    -f -a "(__hypr_layouts)"

# keyword boolean values
complete -c hyprctl \
    -n "__hypr_sub_is keyword; and test (count (commandline -poc)) -eq 3" \
    -f -a "true\tEnable false\tDisable"

# ══════════════════════════════════════════════════════════════════════════════
#  SETCURSOR COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is setcursor; and test (count (commandline -poc)) -eq 2" \
    -f -a "(__hypr_cursor_themes)" -d "Cursor theme name"

complete -c hyprctl -n "__hypr_sub_is setcursor; and test (count (commandline -poc)) -eq 3" \
    -f -a "16 18 20 22 24 28 32 36 40 48 64 96 128" \
    -d "Cursor size in pixels"

# ══════════════════════════════════════════════════════════════════════════════
#  GETOPTION COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is getoption" \
    -f -a "(__hypr_keywords)"

# ══════════════════════════════════════════════════════════════════════════════
#  OUTPUT COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is output; and test (count (commandline -poc)) -eq 2" \
    -f -a "create\tCreate virtual output destroy\tDestroy virtual output"

complete -c hyprctl -n "__hypr_sub_is output; and __fish_seen_subcommand_from create" \
    -f -a "(__hypr_output_backends)"

complete -c hyprctl -n "__hypr_sub_is output; and __fish_seen_subcommand_from destroy" \
    -f -a "(__hypr_monitors)"

# ══════════════════════════════════════════════════════════════════════════════
#  SWITCHXKBLAYOUT COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is switchxkblayout; and test (count (commandline -poc)) -eq 2" \
    -f -a "(__hypr_devices)"

complete -c hyprctl -n "__hypr_sub_is switchxkblayout; and test (count (commandline -poc)) -eq 3" \
    -f -a "next\tNext layout prev\tPrevious layout"

# ══════════════════════════════════════════════════════════════════════════════
#  NOTIFY COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is notify; and test (count (commandline -poc)) -eq 2" \
    -f -a "(__hypr_notify_icons)" -d "Icon ID"

complete -c hyprctl -n "__hypr_sub_is notify; and test (count (commandline -poc)) -eq 3" \
    -f -a "3000\t3 seconds 5000\t5 seconds 10000\t10 seconds -1\tPermanent" \
    -d "Duration (ms)"

# notify color (4th arg)
complete -c hyprctl -n "__hypr_sub_is notify; and test (count (commandline -poc)) -eq 4" \
    -f -a "0xff11111b\tDark 0xffffffff\tWhite 0xffcba6f7\tMauve 0xff89dceb\tTeal" \
    -d "Color (ARGB hex)"

# ══════════════════════════════════════════════════════════════════════════════
#  SETPROP COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is setprop; and test (count (commandline -poc)) -eq 2" \
    -f -a "(__hypr_clients)" -d "Window address or class"

complete -c hyprctl -n "__hypr_sub_is setprop; and test (count (commandline -poc)) -eq 3" \
    -f -a "(__hypr_roles)" -d "Property name"

complete -c hyprctl -n "__hypr_sub_is setprop; and test (count (commandline -poc)) -eq 4" \
    -f -a "0\tFalse/0 1\tTrue/1 lock\tLock value"

# ══════════════════════════════════════════════════════════════════════════════
#  HYPRPAPER COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is hyprpaper; and test (count (commandline -poc)) -eq 2" \
    -f -a "wallpaper\tSet wallpaper preload\tPreload image unload\tUnload image listactive\tList active listloaded\tList loaded"

# hyprpaper wallpaper: monitor,path
complete -c hyprctl -n "__hypr_sub_is hyprpaper; and __fish_seen_subcommand_from wallpaper" \
    -f -a "(__hypr_monitors | awk '{print \$1}' | sed 's/\$/,/')" -d "Monitor (append path)"

# hyprpaper preload / unload: image path
complete -c hyprctl -n "__hypr_sub_is hyprpaper; and __fish_seen_subcommand_from preload" \
    -F

complete -c hyprctl -n "__hypr_sub_is hyprpaper; and __fish_seen_subcommand_from unload" \
    -f -a "(hyprctl hyprpaper listloaded 2>/dev/null)"

# ══════════════════════════════════════════════════════════════════════════════
#  PLUGIN COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is plugin; and test (count (commandline -poc)) -eq 2" \
    -f -a "load\tLoad plugin unload\tUnload plugin list\tList loaded plugins"

complete -c hyprctl -n "__hypr_sub_is plugin; and __fish_seen_subcommand_from load" \
    -f -a "(find /usr/lib/hyprland/plugins ~/.local/lib/hyprland/plugins -name '*.so' 2>/dev/null)" \
    -d "Plugin shared library"

complete -c hyprctl -n "__hypr_sub_is plugin; and __fish_seen_subcommand_from unload" \
    -f -a "(hyprctl plugin list 2>/dev/null | awk '/name:/{print \$NF}')"

# ══════════════════════════════════════════════════════════════════════════════
#  INFO COMMAND FLAGS (monitors, clients, etc.)
# ══════════════════════════════════════════════════════════════════════════════

for info_cmd in monitors workspaces clients layers devices binds animations
    complete -c hyprctl -n "__hypr_sub_is $info_cmd" \
        -s j -l json -d "Output as JSON" -f
end

# monitors: specific monitor
complete -c hyprctl -n "__hypr_sub_is monitors" \
    -f -a "(__hypr_monitors)" -d "Monitor name (or leave blank for all)"

# clients: filter by workspace
complete -c hyprctl -n "__hypr_sub_is clients" \
    -l workspace -d "Filter by workspace ID" -f -a "(__hypr_workspaces)"

# layers: filter by namespace
complete -c hyprctl -n "__hypr_sub_is layers" \
    -f -a "(__hypr_layers)"

# ══════════════════════════════════════════════════════════════════════════════
#  SETERROR COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is seterror; and test (count (commandline -poc)) -eq 2" \
    -f -a "disable\tClear error 0xffff0000\tRed 0xffff8800\tOrange 0xffffff00\tYellow" \
    -d "Color (ARGB) or 'disable'"

# ══════════════════════════════════════════════════════════════════════════════
#  ANIMATIONSTYLE COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is animationstyle; and test (count (commandline -poc)) -eq 2" \
    -f -a "slide\tSlide popin\tPop-in fade\tFade slidefade\tSlide+Fade" \
    -d "Animation style"

# ══════════════════════════════════════════════════════════════════════════════
#  GETBEZIER COMPLETIONS
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is getbezier" \
    -f -a "(__hypr_bezier_curves)" -d "Bezier curve name"

# ══════════════════════════════════════════════════════════════════════════════
#  DISMISSNOTIFY
# ══════════════════════════════════════════════════════════════════════════════

complete -c hyprctl -n "__hypr_sub_is dismissnotify" \
    -f -a "-1\tDismiss all 1\tDismiss 1 2\tDismiss 2 5\tDismiss 5"
