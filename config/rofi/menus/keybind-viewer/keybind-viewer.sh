#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Keybind Viewer Script                             ║
# ║                                                                              ║
# ║  Interactive keybind reference pulled live from Hyprland IPC (hyprctl      ║
# ║  binds) merged with ASH keybind definitions. Search, copy, edit and        ║
# ║  export to multiple formats.                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly KEYBIND_DIRS=(
    "${HOME}/.config/hypr/keybinds"
)
readonly EXPORT_DIR="${HOME}/Documents/ash-keybinds"
readonly CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/ash-dotfiles/keybinds.cache"
readonly CACHE_AGE=30     # seconds

# ══════════════════════════════════════════════════════════════════════════════
# §02  MODIFIER KEY RENDERING
# ══════════════════════════════════════════════════════════════════════════════

# Bitmask → human-readable modifiers
modmask_to_string() {
    local mask="${1:-0}"
    local mods=""

    # Hyprland modifier bitmask:
    # 1=Shift 4=Control 8=Alt/Mod1 64=Super/Mod4 256=Mod2 1024=Mod5
    (( mask & 64  )) && mods+="Super+"
    (( mask & 4   )) && mods+="Ctrl+"
    (( mask & 8   )) && mods+="Alt+"
    (( mask & 1   )) && mods+="Shift+"
    (( mask & 256 )) && mods+="Mod2+"
    (( mask & 1024)) && mods+="Mod5+"
    (( mask & 2   )) && mods+="CapsLock+"

    echo "${mods%+}"   # Remove trailing +
}

# Format key symbol for display
format_key() {
    local key="${1:-}"
    local sym="${2:-}"

    # Use friendly names for special keys
    case "${key,,}" in
        return|kp_enter)    echo "↵"   ;;
        escape)             echo "Esc" ;;
        tab)                echo "⇥"   ;;
        space)              echo "␣"   ;;
        backspace)          echo "⌫"   ;;
        delete)             echo "Del" ;;
        left)               echo "←"   ;;
        right)              echo "→"   ;;
        up)                 echo "↑"   ;;
        down)               echo "↓"   ;;
        prior)              echo "PgUp";;
        next)               echo "PgDn";;
        home)               echo "Home";;
        end)                echo "End" ;;
        grave)              echo "\`"  ;;
        comma)              echo ","   ;;
        period)             echo "."   ;;
        slash)              echo "/"   ;;
        backslash)          echo "\\"  ;;
        bracketleft)        echo "["   ;;
        bracketright)       echo "]"   ;;
        semicolon)          echo ";"   ;;
        apostrophe)         echo "'"   ;;
        minus)              echo "-"   ;;
        equal)              echo "="   ;;
        mouse:272)          echo "LMB" ;;
        mouse:273)          echo "RMB" ;;
        mouse:274)          echo "MMB" ;;
        mouse_up)           echo "Scroll↑" ;;
        mouse_down)         echo "Scroll↓" ;;
        xf86audioraisevolume) echo "Vol+" ;;
        xf86audiolowervolume) echo "Vol-" ;;
        xf86audiomute)      echo "VolMute" ;;
        xf86audiomicmute)   echo "MicMute" ;;
        xf86monbrightnessup)   echo "Bright+" ;;
        xf86monbrightnessdown) echo "Bright-" ;;
        xf86audioplay)      echo "Play"  ;;
        xf86audionext)      echo "Next"  ;;
        xf86audioprev)      echo "Prev"  ;;
        xf86audiostop)      echo "Stop"  ;;
        *)
            [[ -n "$key" ]] && echo "${key^^}" || echo "${sym^^}"
            ;;
    esac
}

# Compose a clean keybind string like "Super+Shift+Q"
format_keybind() {
    local modmask="$1" key="$2" sym="$3"
    local mods
    mods=$(modmask_to_string "$modmask")
    local key_label
    key_label=$(format_key "$key" "$sym")

    if [[ -n "$mods" ]]; then
        echo "${mods}+${key_label}"
    else
        echo "$key_label"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  CATEGORY DETECTION
# ══════════════════════════════════════════════════════════════════════════════

categorize_bind() {
    local dispatcher="${1,,}" arg="${2,,}" desc="${3,,}"
    local combined="${dispatcher} ${arg} ${desc}"

    if   [[ "$combined" =~ killactive|closewindow|close|kill ]];            then echo "windows"
    elif [[ "$combined" =~ movefocus|movewindow|swapwindow|resize|float|fullscreen|pin|pseudo|center|group|changegroupactive ]]; then echo "windows"
    elif [[ "$combined" =~ workspace|moveto|movetoworkspace|togglespecial ]]; then echo "workspaces"
    elif [[ "$combined" =~ exec.*(rofi|wofi|launcher|dmenu) ]];             then echo "launchers"
    elif [[ "$combined" =~ exec.*(kitty|foot|alacritty|wezterm|terminal) ]]; then echo "apps"
    elif [[ "$combined" =~ exec.*(firefox|chromium|brave|browser) ]];       then echo "apps"
    elif [[ "$combined" =~ exec.*(screenshot|grim|grimblast|slurp) ]];      then echo "screenshot"
    elif [[ "$combined" =~ xf86audio|volume|wpctl|pactl|playerctl|mpc ]];   then echo "media"
    elif [[ "$combined" =~ xf86mon|brightness|bright ]];                    then echo "media"
    elif [[ "$combined" =~ exit|shutdown|reboot|suspend|hibernate|logout|lock|hyprlock ]]; then echo "power"
    elif [[ "$combined" =~ ash.*(mode|theme|snap|wall|plugin) ]];           then echo "modes"
    elif [[ "$combined" =~ submap ]];                                        then echo "submaps"
    elif [[ "$combined" =~ gamemode|steam|gaming|game ]];                   then echo "gaming"
    else                                                                          echo "other"
    fi
}

category_icon() {
    case "${1,,}" in
        windows)    echo "󰘴" ;;
        workspaces) echo "󰝪" ;;
        launchers)  echo "󰍜" ;;
        apps)       echo "󰙳" ;;
        screenshot) echo "󰹑" ;;
        media)      echo "󰎵" ;;
        power)      echo "󰐥" ;;
        modes)      echo "󱓋" ;;
        submaps)    echo "🔑" ;;
        gaming)     echo "🎮" ;;
        other)      echo "⚡" ;;
        all|*)      echo "󰘳" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  DISPATCHER → HUMAN DESCRIPTION
# ══════════════════════════════════════════════════════════════════════════════

dispatcher_to_desc() {
    local dispatcher="$1" arg="${2:-}"

    case "${dispatcher,,}" in
        exec)               echo "Run: $(echo "$arg" | sed 's/.*\///' | cut -c1-40)" ;;
        killactive)         echo "Close focused window" ;;
        closewindow)        echo "Close window: $arg" ;;
        togglefloating)     echo "Toggle float ↔ tile" ;;
        setfloating)        echo "Force float" ;;
        settiled)           echo "Force tile" ;;
        fullscreen)
            case "$arg" in
                0) echo "Real fullscreen" ;;
                1) echo "Maximize (bar visible)" ;;
                2) echo "Fullscreen no-bar" ;;
                *) echo "Toggle fullscreen" ;;
            esac ;;
        fakefullscreen)     echo "Fake fullscreen (window-contained)" ;;
        pseudo)             echo "Toggle pseudo-tile" ;;
        pin)                echo "Pin to all workspaces" ;;
        movefocus)          echo "Move focus → $arg" ;;
        movewindow)         echo "Move window → $arg" ;;
        swapwindow)         echo "Swap window → $arg" ;;
        resizeactive)       echo "Resize window $arg" ;;
        centerwindow)       echo "Center floating window" ;;
        workspace)          echo "Switch to workspace $arg" ;;
        movetoworkspace)    echo "Move window to WS $arg" ;;
        movetoworkspacesilent) echo "Send to WS $arg (silent)" ;;
        togglespecialworkspace) echo "Toggle scratchpad: $arg" ;;
        togglegroup)        echo "Toggle window group" ;;
        changegroupactive)  echo "Cycle group tabs →${arg}" ;;
        moveoutofgroup)     echo "Remove from group" ;;
        moveintogroup)      echo "Merge into group $arg" ;;
        movewindoworgroup)  echo "Move/merge → $arg" ;;
        lockgroups)         echo "Lock groups: $arg" ;;
        focuswindow)        echo "Focus window: $arg" ;;
        focusmonitor)       echo "Focus monitor: $arg" ;;
        movecurrentworkspacetomonitor) echo "Move WS to monitor $arg" ;;
        layoutmsg)          echo "Layout: $arg" ;;
        splitratio)         echo "Adjust split ratio $arg" ;;
        submap)             echo "Enter submap: $arg" ;;
        dpms)               echo "Display power: $arg" ;;
        exit)               echo "Exit Hyprland (logout)" ;;
        forcerendererreload) echo "Reload GPU shaders" ;;
        hyprexpo:expo)      echo "Workspace overview (hyprexpo)" ;;
        overview:toggle)    echo "Workspace overview toggle" ;;
        pass)               echo "Pass to window: $arg" ;;
        global)             echo "Global shortcut: $arg" ;;
        sendshortcut)       echo "Send shortcut to app" ;;
        moveactive)         echo "Move floating window $arg" ;;
        cyclenext)          echo "Cycle focus ${arg:-forward}" ;;
        focusurgent)        echo "Focus urgent window" ;;
        *)                  echo "${dispatcher}: ${arg}" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  LIVE HYPRCTL BIND FETCHER
# ══════════════════════════════════════════════════════════════════════════════

fetch_live_binds() {
    hyprctl -j binds 2>/dev/null || echo "[]"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  CONFLICT DETECTOR
# ══════════════════════════════════════════════════════════════════════════════

find_conflicts() {
    local binds="$1"
    local conflicts=()

    # Group binds by (modmask + key) and find duplicates
    local seen=()
    local bind_keys=()

    while IFS='|' read -r mask key submap; do
        local bind_id="${mask}+${key}+${submap}"
        if [[ " ${seen[*]} " =~ " ${bind_id} " ]]; then
            conflicts+=("$bind_id")
        fi
        seen+=("$bind_id")
    done <<< "$(echo "$binds" | jq -r '.[] | "\(.modmask)|\(.key)|\(.submap)"' 2>/dev/null || true)"

    echo "${#conflicts[@]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

# Format a single bind line for display
format_bind_entry() {
    local modmask="$1" key="$2" sym="$3" dispatcher="$4" arg="$5" submap="${6:-default}" repeat="${7:-false}" locked="${8:-false}"

    local keybind_str
    keybind_str=$(format_keybind "$modmask" "$key" "$sym")

    local desc
    desc=$(dispatcher_to_desc "$dispatcher" "$arg")

    local flags=""
    [[ "$repeat" == "true" ]] && flags+="e"    # binde (repeat while held)
    [[ "$locked" == "true" ]] && flags+="l"    # bindl (works on lock screen)
    [[ "$submap" != "default" && -n "$submap" ]] && flags+="[${submap}]"

    local flag_str=""
    [[ -n "$flags" ]] && flag_str=" <${flags}>"

    local category
    category=$(categorize_bind "$dispatcher" "$arg" "$desc")
    local cat_icon
    cat_icon=$(category_icon "$category")

    # Width-padded columns: icon  keybind  description  flags
    local display
    display=$(printf '%s  %-22s  %-45s  %s' \
        "$cat_icon" \
        "${keybind_str:0:20}" \
        "${desc:0:43}" \
        "$flag_str")

    echo "$display"
}

build_keybind_entries() {
    local filter_cat="${1:-all}"

    # Fetch from hyprctl
    local raw_binds
    raw_binds=$(fetch_live_binds)

    # Get current submap
    local current_submap
    current_submap=$(hyprctl -j activewindow 2>/dev/null | jq -r '.fullscreen' 2>/dev/null || echo "default")
    # Actually get submap
    current_submap=$(hyprctl submap 2>/dev/null || echo "default")
    [[ -z "$current_submap" || "$current_submap" == "reset" ]] && current_submap="default"

    local last_category=""
    local bind_count=0

    # Process binds from hyprctl JSON
    while IFS= read -r bind_json; do
        [[ -z "$bind_json" || "$bind_json" == "null" ]] && continue

        local modmask key sym dispatcher arg submap repeat locked
        modmask=$(   echo "$bind_json" | jq -r '.modmask   // 0'         2>/dev/null || echo "0")
        key=$(       echo "$bind_json" | jq -r '.key       // ""'        2>/dev/null || echo "")
        sym=$(       echo "$bind_json" | jq -r '.keycode   // ""'        2>/dev/null || echo "")
        dispatcher=$(echo "$bind_json" | jq -r '.dispatcher // ""'       2>/dev/null || echo "")
        arg=$(       echo "$bind_json" | jq -r '.arg       // ""'        2>/dev/null | head -c 60)
        submap=$(    echo "$bind_json" | jq -r '.submap    // "default"' 2>/dev/null || echo "default")
        repeat=$(    echo "$bind_json" | jq -r '.repeat    // false'     2>/dev/null || echo "false")
        locked=$(    echo "$bind_json" | jq -r '.locked    // false'     2>/dev/null || echo "false")

        [[ -z "$dispatcher" ]] && continue

        # Category filter
        local category
        category=$(categorize_bind "$dispatcher" "$arg" "")

        if [[ "$filter_cat" != "all" ]] && [[ "$category" != "$filter_cat" ]]; then
            continue
        fi

        # Category section headers
        if [[ "$category" != "$last_category" ]]; then
            last_category="$category"
            local cat_icon header_label
            cat_icon=$(category_icon "$category")
            header_label=$(echo "$category" | tr '[:lower:]' '[:upper:]')
            printf '─── %s %s ─────────────────────────\0nonselectable\x1ftrue\n' \
                "$cat_icon" "$header_label"
        fi

        # Format the entry
        local display
        display=$(format_bind_entry \
            "$modmask" "$key" "$sym" "$dispatcher" "$arg" \
            "$submap" "$repeat" "$locked")

        # Store full keybind string for copy action
        local keybind_str
        keybind_str=$(format_keybind "$modmask" "$key" "$sym")

        printf '%s\0info\x1fcopy\x1fmeta\x1f%s|%s|%s\n' \
            "$display" \
            "$keybind_str" \
            "$(dispatcher_to_desc "$dispatcher" "$arg")" \
            "$dispatcher"

        (( bind_count++ )) || true

    done < <(echo "$raw_binds" | jq -c '.[]' 2>/dev/null || true)

    if [[ $bind_count -eq 0 ]]; then
        printf '⚠  No keybinds found (Hyprland not running?)\0nonselectable\x1ftrue\n'
        printf '  Try: hyprctl binds\0info\x1fnone\n'
    fi

    # Footer actions
    printf '─── TOOLS ────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰈦  Export to Markdown\0info\x1fexport-md\n'
    printf '󰈦  Export to HTML cheatsheet\0info\x1fexport-html\n'
    printf '  Open keybind config editor\0info\x1fedit-config\n'
    printf '  Find conflicting binds\0info\x1ffind-conflicts\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  EXPORT FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

export_markdown() {
    mkdir -p "$EXPORT_DIR"
    local out="${EXPORT_DIR}/keybinds_$(date +%Y%m%d_%H%M%S).md"

    {
        echo "# ASH Dotfiles v5.0 — Keybind Reference"
        echo ""
        echo "> Generated: $(date '+%A, %B %d %Y at %H:%M')"
        echo ""

        local current_cat=""
        while IFS= read -r bind_json; do
            [[ -z "$bind_json" || "$bind_json" == "null" ]] && continue

            local modmask key sym dispatcher arg
            modmask=$(   echo "$bind_json" | jq -r '.modmask    // 0'  2>/dev/null || echo "0")
            key=$(       echo "$bind_json" | jq -r '.key        // ""' 2>/dev/null || echo "")
            sym=$(       echo "$bind_json" | jq -r '.keycode    // ""' 2>/dev/null || echo "")
            dispatcher=$(echo "$bind_json" | jq -r '.dispatcher // ""' 2>/dev/null || echo "")
            arg=$(       echo "$bind_json" | jq -r '.arg        // ""' 2>/dev/null | head -c 60)

            local category
            category=$(categorize_bind "$dispatcher" "$arg" "")

            if [[ "$category" != "$current_cat" ]]; then
                current_cat="$category"
                echo ""
                echo "## $(echo "$category" | tr '[:lower:]' '[:upper:]')"
                echo ""
                echo "| Keybind | Action |"
                echo "|---------|--------|"
            fi

            local keybind_str desc
            keybind_str=$(format_keybind "$modmask" "$key" "$sym")
            desc=$(dispatcher_to_desc "$dispatcher" "$arg")

            echo "| \`${keybind_str}\` | ${desc} |"

        done < <(fetch_live_binds | jq -c '.[]' 2>/dev/null || true)

    } > "$out"

    notify_kb "󰈦 Exported to Markdown" "$out" "low"
    echo "$out"
}

export_html() {
    mkdir -p "$EXPORT_DIR"
    local out="${EXPORT_DIR}/keybinds_$(date +%Y%m%d_%H%M%S).html"

    {
        cat << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ASH Dotfiles — Keybind Reference</title>
<style>
  :root { --bg: #1e1e2e; --surface: #313244; --accent: #cba4f7; --text: #cdd6f4; --muted: #6c7086; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font-family: 'JetBrains Mono', monospace; padding: 2rem; }
  h1 { color: var(--accent); margin-bottom: 1rem; }
  h2 { color: var(--accent); opacity: 0.8; margin: 1.5rem 0 0.5rem; font-size: 0.9rem; letter-spacing: 0.1em; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
  th { text-align: left; padding: 6px 12px; color: var(--muted); font-size: 0.8rem; border-bottom: 1px solid var(--surface); }
  td { padding: 6px 12px; border-bottom: 1px solid rgba(49,50,68,0.5); font-size: 0.85rem; }
  tr:hover td { background: rgba(203,164,247,0.05); }
  kbd { background: var(--surface); border-radius: 4px; padding: 2px 6px; color: var(--accent); font-size: 0.8rem; }
  .cat { opacity: 0.65; font-size: 0.75rem; }
  .generated { color: var(--muted); font-size: 0.75rem; margin-top: 2rem; }
</style>
</head>
<body>
<h1>🔑 ASH Dotfiles — Keybind Reference</h1>
HTMLHEAD

        local current_cat=""
        while IFS= read -r bind_json; do
            [[ -z "$bind_json" || "$bind_json" == "null" ]] && continue

            local modmask key sym dispatcher arg
            modmask=$(   echo "$bind_json" | jq -r '.modmask    // 0'  2>/dev/null || echo "0")
            key=$(       echo "$bind_json" | jq -r '.key        // ""' 2>/dev/null || echo "")
            sym=$(       echo "$bind_json" | jq -r '.keycode    // ""' 2>/dev/null || echo "")
            dispatcher=$(echo "$bind_json" | jq -r '.dispatcher // ""' 2>/dev/null || echo "")
            arg=$(       echo "$bind_json" | jq -r '.arg        // ""' 2>/dev/null | head -c 60)

            local category
            category=$(categorize_bind "$dispatcher" "$arg" "")

            if [[ "$category" != "$current_cat" ]]; then
                [[ -n "$current_cat" ]] && echo "</table>"
                current_cat="$category"
                local cat_icon
                cat_icon=$(category_icon "$category")
                echo "<h2>${cat_icon} $(echo "$category" | tr '[:lower:]' '[:upper:]')</h2>"
                echo "<table><tr><th>Keybind</th><th>Action</th></tr>"
            fi

            local keybind_str desc
            keybind_str=$(format_keybind "$modmask" "$key" "$sym")
            desc=$(dispatcher_to_desc "$dispatcher" "$arg")

            echo "<tr><td><kbd>${keybind_str}</kbd></td><td>${desc}</td></tr>"

        done < <(fetch_live_binds | jq -c '.[]' 2>/dev/null || true)

        echo "</table>"
        echo "<p class='generated'>Generated: $(date '+%A, %B %d %Y at %H:%M') — ASH v5.0</p>"
        echo "</body></html>"
    } > "$out"

    notify_kb "󰈦 Exported to HTML" "$out" "low"
    xdg-open "$out" &>/dev/null & disown
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_kb() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Keybinds" \
        --icon=input-keyboard \
        --urgency="$urgency" \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:keybind-viewer \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        copy)
            IFS='|' read -r keybind desc dispatcher <<< "$meta"
            if [[ -n "$keybind" ]]; then
                echo -n "$keybind" | wl-copy 2>/dev/null && \
                    notify_kb "🔑 Copied" "$keybind  —  $desc" "low"
            fi
            ;;
        edit-config)
            kitty --class float-term \
                -e nvim "${KEYBIND_DIRS[0]}/default.conf" \
                &>/dev/null & disown
            ;;
        export-md)
            export_markdown
            ;;
        export-html)
            export_html
            ;;
        find-conflicts)
            local binds
            binds=$(fetch_live_binds)
            local count
            count=$(find_conflicts "$binds")

            if [[ "$count" -eq 0 ]]; then
                notify_kb "✓ No conflicts" "All keybinds are unique" "low"
            else
                notify_kb "⚠ ${count} conflict(s)" "Multiple binds on same key" "normal"
            fi
            ;;
        none|"")
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --list)     fetch_live_binds | jq -r '.[] | "\(.modmask)\t\(.key)\t\(.dispatcher)\t\(.arg)"' 2>/dev/null ;;
        --count)    fetch_live_binds | jq 'length' 2>/dev/null ;;
        --search)
            local query="${2:-}"
            fetch_live_binds | jq -r ".[] | select(.dispatcher | test(\"$query\"; \"i\")) | \"\(.modmask)\t\(.key)\t\(.dispatcher)\t\(.arg)\"" 2>/dev/null
            ;;
        --export-md)   export_markdown ;;
        --export-html) export_html ;;
        --conflicts)
            local c
            c=$(find_conflicts "$(fetch_live_binds)")
            echo "Conflicts: $c"
            ;;
        --help|-h)
            echo "ASH Keybind Viewer v5.0"
            echo ""
            echo "Usage: keybind-viewer.sh [OPTION]"
            echo "  --list           List all keybinds"
            echo "  --count          Count keybinds"
            echo "  --search QUERY   Search by dispatcher"
            echo "  --export-md      Export to Markdown"
            echo "  --export-html    Export to HTML"
            echo "  --conflicts      Find conflicts"
            echo ""
            echo "No args: Launch Rofi keybind viewer"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show kb \
        -modi "kb:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/keybind-viewer/keybind-viewer.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_keybind_entries "all"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# Ctrl+E: Edit config
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    dispatch_action "edit-config"
    exit 0
fi

# Ctrl+R: Refresh
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    build_keybind_entries "all"
    exit 0
fi

# Ctrl+X: Export
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    export_markdown
    build_keybind_entries "all"
    exit 0
fi

# Ctrl+C: Copy focused keybind
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    dispatch_action "copy" "$meta_value"
    build_keybind_entries "all"
    exit 0
fi

# Ctrl+F: Find conflicts
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    dispatch_action "find-conflicts"
    build_keybind_entries "all"
    exit 0
fi

# Ctrl+L: Live view
if [[ "${ROFI_RETV}" -eq 15 ]]; then
    build_keybind_entries "all"
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_keybind_entries "all"
    exit 0
fi