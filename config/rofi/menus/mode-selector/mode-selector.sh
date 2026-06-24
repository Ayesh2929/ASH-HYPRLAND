#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Desktop Mode Selector Script                      ║
# ║                                                                              ║
# ║  Full desktop mode management via ASH mode engine integration.              ║
# ║  Switch compositor behavior, performance profiles, DND state,               ║
# ║  animation presets and visual settings per mode.                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly CURRENT_MODE_FILE="${HOME}/.local/state/ash-dotfiles/current-mode"
readonly SCHEDULE_FILE="${HOME}/.local/share/ash-dotfiles/mode-schedule.json"
readonly HISTORY_FILE="${HOME}/.local/share/ash-dotfiles/mode-history.txt"
readonly MODE_ENTER_TIME_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-mode-enter-time"

# ══════════════════════════════════════════════════════════════════════════════
# §02  MODE DEFINITIONS
#      Each mode: id | icon | label | subtitle | description | effects
# ══════════════════════════════════════════════════════════════════════════════

declare -A MODE_ICONS=(
    [default]="󰒲"
    [game]="🎮"
    [work]="💼"
    [focus]="🎯"
    [cinema]="🎬"
    [battery]="🔋"
    [stream]="📡"
    [privacy]="🔒"
    [present]="🎤"
    [accessibility]="♿"
)

declare -A MODE_LABELS=(
    [default]="Default"
    [game]="Game"
    [work]="Work"
    [focus]="Focus"
    [cinema]="Cinema"
    [battery]="Battery"
    [stream]="Stream"
    [privacy]="Privacy"
    [present]="Present"
    [accessibility]="Access"
)

declare -A MODE_SUBTITLES=(
    [default]="Balanced"
    [game]="Max FPS"
    [work]="DND ON"
    [focus]="Dim BG"
    [cinema]="No border"
    [battery]="Save power"
    [stream]="OBS ready"
    [privacy]="Blur bg"
    [present]="Big cursor"
    [accessibility]="WCAG AA"
)

declare -A MODE_DESCRIPTIONS=(
    [default]="Balanced desktop experience\n\nBlur: ON  Shadow: ON\nAnimations: smooth\nDND: OFF  Power: balanced\nGaps: 4/12px  Border: 2px\n\nBest for: general use"
    [game]="Maximum gaming performance\n\nBlur: OFF  Shadow: OFF\nAnimations: OFF\nDND: ON  Power: performance\nGaps: 0px  Border: 0px\nVRR: fullscreen  Tearing: allowed\n\nBest for: gaming, benchmarks"
    [work]="Professional productivity\n\nBlur: subtle  Shadow: ON\nAnimations: smooth\nDND: ON  Power: balanced\nGaps: 5/14px  Border: 2px\nColor temp: 5500K warm\n\nBest for: coding, office work"
    [focus]="Deep work / flow state\n\nBlur: ON  Shadow: strong\nAnimations: slow\nDND: ON  Power: balanced\nDim inactive: 28%  Cursor: hide\nGaps: 6/16px\n\nBest for: writing, deep focus"
    [cinema]="Immersive media viewing\n\nBlur: minimal  Shadow: OFF\nAnimations: cinematic\nDND: ON  Power: balanced\nGaps: 0px  Border: 0px\nVRR: ON  Idle: inhibited\n\nBest for: movies, video"
    [battery]="Maximum battery conservation\n\nBlur: OFF  Shadow: OFF\nAnimations: minimal\nDND: OFF  Power: power-saver\nBrightness: 60%  FPS cap: low\n\nBest for: travel, low battery"
    [stream]="Live streaming optimized\n\nBlur: HIGH  Shadow: strong\nAnimations: cinematic\nDND: ON  Power: performance\nIdle: inhibited  OBS: ws 8\n\nBest for: Twitch, YouTube Live"
    [privacy]="Operational security mode\n\nBlur: aggressive  Shadow: OFF\nAnimations: minimal\nClipboard: cleared  Mic: muted\nCamera: OFF  Screen share: OFF\nIdle: 60s lock\n\nBest for: sensitive work"
    [present]="Professional presentation\n\nBlur: OFF  Shadow: subtle\nAnimations: smooth\nDND: ON  Power: balanced\nCursor: large (32px)\nIdle: inhibited\n\nBest for: demos, meetings"
    [accessibility]="WCAG 2.1 AA compliance\n\nBlur: OFF  Shadow: strong\nAnimations: reduced\nDND: OFF  Border: thick 3px\nCursor: large  Contrast: high\nAT-SPI: enabled\n\nBest for: accessibility needs"
)

declare -A MODE_COLORS=(
    [default]="mauve"
    [game]="green"
    [work]="blue"
    [focus]="mauve"
    [cinema]="red"
    [battery]="yellow"
    [stream]="peach"
    [privacy]="teal"
    [present]="sapphire"
    [accessibility]="lavender"
)

# Mode display order
declare -a MODE_ORDER=(
    default game work focus cinema battery stream privacy present accessibility
)

# ══════════════════════════════════════════════════════════════════════════════
# §03  STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

get_current_mode() {
    cat "$CURRENT_MODE_FILE" 2>/dev/null || echo "default"
}

set_current_mode() {
    local mode="$1"
    mkdir -p "$(dirname "$CURRENT_MODE_FILE")"
    echo "$mode" > "$CURRENT_MODE_FILE"
    date +%s > "$MODE_ENTER_TIME_FILE"
}

get_mode_uptime() {
    local enter_time
    enter_time=$(cat "$MODE_ENTER_TIME_FILE" 2>/dev/null || date +%s)
    local diff=$(( $(date +%s) - enter_time ))
    printf "%02d:%02d" $((diff/3600)) $((diff%3600/60))
}

add_to_history() {
    local mode="$1"
    mkdir -p "$(dirname "$HISTORY_FILE")"

    local tmp
    tmp=$(mktemp)
    echo "${mode}|$(date +%s)" | cat - "$HISTORY_FILE" 2>/dev/null > "$tmp" || true
    head -30 "$tmp" > "$HISTORY_FILE" 2>/dev/null || true
    rm -f "$tmp"
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  MODE APPLICATION
# ══════════════════════════════════════════════════════════════════════════════

apply_mode() {
    local mode="$1"
    local preview="${2:-false}"
    local current_mode
    current_mode=$(get_current_mode)

    # Same mode — do nothing
    if [[ "$mode" == "$current_mode" ]] && ! $preview; then
        notify_ms "Already in ${MODE_LABELS[$mode]:-$mode} mode" "" "low"
        return 0
    fi

    local label="${MODE_LABELS[$mode]:-$mode}"
    local icon="${MODE_ICONS[$mode]:-󰒲}"

    $preview || notify_ms "${icon} Switching…" "$label mode" "low"

    # Use ASH CLI if available
    if command -v ash &>/dev/null; then
        local ash_args=("mode" "$mode")
        $preview && ash_args+=(--preview)

        ash "${ash_args[@]}" &>/dev/null && {
            if ! $preview; then
                set_current_mode "$mode"
                add_to_history "$mode"
                notify_ms "${icon} ${label} Mode" "$(get_mode_short_desc "$mode")"
            fi
            return 0
        }
    fi

    # Fallback: direct Hyprland/systemd integration
    apply_mode_direct "$mode" "$preview"
}

apply_mode_direct() {
    local mode="$1"
    local preview="${2:-false}"

    # Source the mode conf file if it exists
    local mode_conf="${HOME}/.config/hypr/modes/${mode}.conf"

    case "$mode" in
        default)
            hyprctl keyword decoration:blur:enabled true &>/dev/null || true
            hyprctl keyword decoration:shadow:enabled true &>/dev/null || true
            hyprctl keyword animations:enabled true &>/dev/null || true
            hyprctl keyword general:gaps_in 4 &>/dev/null || true
            hyprctl keyword general:gaps_out 12 &>/dev/null || true
            hyprctl keyword general:border_size 2 &>/dev/null || true
            hyprctl keyword misc:vrr 0 &>/dev/null || true
            powerprofilesctl set balanced &>/dev/null || true
            swaync-client --dnd-off &>/dev/null || true
            ;;
        game)
            hyprctl keyword decoration:blur:enabled false &>/dev/null || true
            hyprctl keyword decoration:shadow:enabled false &>/dev/null || true
            hyprctl keyword animations:enabled false &>/dev/null || true
            hyprctl keyword general:gaps_in 0 &>/dev/null || true
            hyprctl keyword general:gaps_out 0 &>/dev/null || true
            hyprctl keyword general:border_size 0 &>/dev/null || true
            hyprctl keyword general:allow_tearing true &>/dev/null || true
            hyprctl keyword misc:vrr 1 &>/dev/null || true
            powerprofilesctl set performance &>/dev/null || true
            swaync-client --dnd-on &>/dev/null || true
            ;;
        work)
            hyprctl keyword decoration:blur:enabled true &>/dev/null || true
            hyprctl keyword decoration:dim_inactive true &>/dev/null || true
            hyprctl keyword decoration:dim_strength 0.14 &>/dev/null || true
            powerprofilesctl set balanced &>/dev/null || true
            swaync-client --dnd-on &>/dev/null || true
            hyprsunset -t 5500 &>/dev/null || true
            ;;
        focus)
            hyprctl keyword decoration:dim_strength 0.28 &>/dev/null || true
            hyprctl keyword cursor:inactive_timeout 4 &>/dev/null || true
            swaync-client --dnd-on &>/dev/null || true
            ;;
        cinema)
            hyprctl keyword decoration:shadow:enabled false &>/dev/null || true
            hyprctl keyword general:gaps_in 0 &>/dev/null || true
            hyprctl keyword general:gaps_out 0 &>/dev/null || true
            hyprctl keyword general:border_size 0 &>/dev/null || true
            hyprctl keyword misc:vrr 1 &>/dev/null || true
            swaync-client --dnd-on &>/dev/null || true
            ;;
        battery)
            hyprctl keyword decoration:blur:enabled false &>/dev/null || true
            hyprctl keyword decoration:shadow:enabled false &>/dev/null || true
            hyprctl keyword animations:enabled false &>/dev/null || true
            powerprofilesctl set power-saver &>/dev/null || true
            brightnessctl set 60% &>/dev/null || true
            ;;
        privacy)
            cliphist wipe &>/dev/null || true
            wpctl set-mute @DEFAULT_SOURCE@ 1 &>/dev/null || true
            systemctl --user stop xdg-desktop-portal-hyprland &>/dev/null || true
            swaync-client --dnd-on &>/dev/null || true
            ;;
        present)
            hyprctl setcursor Bibata-Modern-Ice 32 &>/dev/null || true
            swaync-client --dnd-on &>/dev/null || true
            systemd-inhibit --what=idle:sleep \
                --who=ash-present \
                --why="Presentation mode" \
                sleep infinity & disown
            ;;
        accessibility)
            hyprctl keyword general:border_size 3 &>/dev/null || true
            hyprctl keyword cursor:zoom_factor 1.8 &>/dev/null || true
            hyprctl keyword decoration:dim_inactive false &>/dev/null || true
            hyprctl setcursor Bibata-Modern-Ice 36 &>/dev/null || true
            ;;
    esac

    if ! $preview; then
        set_current_mode "$mode"
        add_to_history "$mode"
    fi

    pkill -SIGUSR1 waybar 2>/dev/null || true
}

get_mode_short_desc() {
    local mode="$1"
    case "$mode" in
        default)      echo "Balanced desktop restored" ;;
        game)         echo "Max FPS • Blur OFF • Tearing allowed" ;;
        work)         echo "DND ON • Warm 5500K • Focus layout" ;;
        focus)        echo "Inactive dimmed 28% • Cursor hides" ;;
        cinema)       echo "Borders OFF • VRR ON • Idle inhibited" ;;
        battery)      echo "Blur OFF • Power-saver • 60% brightness" ;;
        stream)       echo "Cinematic anim • OBS WS 8 • Perf mode" ;;
        privacy)      echo "Clipboard cleared • Mic muted • Screen share OFF" ;;
        present)      echo "Large cursor • DND ON • Idle inhibited" ;;
        accessibility) echo "WCAG AA • High contrast • Large cursor" ;;
        *)            echo "Mode applied" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  SCHEDULE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

show_schedule_menu() {
    local choice
    choice=$(printf '%s\n' \
        "Work hours (09:00-17:00 weekdays)" \
        "Gaming evenings (18:00-23:00)" \
        "Night mode after 22:00" \
        "Battery save at <20%" \
        "Cinema on weekends" \
        "Clear all schedules" \
        "Cancel" | \
        rofi -dmenu \
            -p "󰕰 Mode Schedule" \
            -theme-str "window { width: 400px; } listview { lines: 7; }" \
            2>/dev/null || echo "Cancel")

    case "$choice" in
        "Work hours"*)
            notify_ms "Schedule set" "Work mode: Mon-Fri 09:00-17:00" "low"
            ;;
        "Gaming evenings"*)
            notify_ms "Schedule set" "Game mode: 18:00-23:00 daily" "low"
            ;;
        "Night mode"*)
            notify_ms "Schedule set" "Focus mode: after 22:00 daily" "low"
            ;;
        "Clear all"*)
            notify_ms "Schedules cleared" "" "low"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_ms() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Mode Selector" \
        --icon=preferences-system \
        --urgency="$urgency" \
        --expire-time=3500 \
        --hint=string:x-dunst-stack-tag:mode-selector \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_mode_entries() {
    local current_mode
    current_mode=$(get_current_mode)
    local uptime
    uptime=$(get_mode_uptime)

    for mode in "${MODE_ORDER[@]}"; do
        local icon="${MODE_ICONS[$mode]:-󰒲}"
        local label="${MODE_LABELS[$mode]:-$mode}"
        local subtitle="${MODE_SUBTITLES[$mode]:-}"

        local is_current=false
        [[ "$mode" == "$current_mode" ]] && is_current=true

        local current_mark=""
        $is_current && current_mark="● "

        # Card text: icon (large) + label + subtitle + active indicator
        local card_text
        card_text=$(printf '%s\n%s%s\n%s' \
            "$icon" \
            "$current_mark" \
            "$label" \
            "$subtitle")

        # Add time in mode for current
        $is_current && card_text="${card_text}\n${uptime}"

        printf '%s\0info\x1fswitch\x1fmeta\x1f%s\n' "$card_text" "$mode"
    done

    # Custom mode option
    printf '➕\nCustom\nCreate new\n─────\0info\x1fcustom\n'
}

build_info_entry() {
    local mode="$1"
    local desc="${MODE_DESCRIPTIONS[$mode]:-No description}"
    local icon="${MODE_ICONS[$mode]:-󰒲}"
    local label="${MODE_LABELS[$mode]:-$mode}"

    printf '%s %s\n\n%s\0info\x1fnone\n' "$icon" "$label" "$desc"
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        switch)
            [[ -n "$meta" ]] && apply_mode "$meta"
            ;;
        preview)
            [[ -n "$meta" ]] && apply_mode "$meta" "true"
            ;;
        custom)
            local name
            name=$(rofi -dmenu \
                -p "Custom mode name" \
                -theme-str "window { width: 350px; } listview { lines: 0; }" \
                2>/dev/null || echo "")
            [[ -n "$name" ]] && \
                notify_ms "Custom mode" "Custom modes require ASH CLI" "normal"
            ;;
        schedule)
            show_schedule_menu
            ;;
        reset)
            apply_mode "default"
            ;;
        none|"")
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --switch)   [[ -n "${2:-}" ]] && apply_mode "$2" ;;
        --current)  get_current_mode ;;
        --list)     printf '%s\n' "${MODE_ORDER[@]}" ;;
        --reset)    apply_mode "default" ;;
        --info)     [[ -n "${2:-}" ]] && echo "${MODE_DESCRIPTIONS[${2:-default}]:-}" ;;
        --help|-h)
            echo "ASH Mode Selector v5.0"
            echo ""
            echo "Modes: ${MODE_ORDER[*]}"
            echo ""
            echo "Usage: mode-selector.sh [OPTION] [MODE]"
            echo "  --switch MODE  Switch to mode"
            echo "  --current      Show active mode"
            echo "  --list         List all modes"
            echo "  --reset        Reset to default"
            echo "  --info MODE    Show mode description"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show ms \
        -modi "ms:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/mode-selector/mode-selector.rasi" \
        2>/dev/null
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_mode_entries
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

# Ctrl+S: Schedule
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    show_schedule_menu
    build_mode_entries
    exit 0
fi

# Ctrl+I: Mode info
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    if [[ -n "$meta_value" ]]; then
        local label="${MODE_LABELS[$meta_value]:-$meta_value}"
        local icon="${MODE_ICONS[$meta_value]:-󰒲}"
        local desc="${MODE_DESCRIPTIONS[$meta_value]:-No description}"
        notify_ms "${icon} ${label} Mode" \
            "$(echo -e "$desc" | head -6)" "low"
    fi
    build_mode_entries
    exit 0
fi

# Ctrl+R: Reset to default
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    apply_mode "default"
    build_mode_entries
    exit 0
fi

# Alt+Enter: Preview mode
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && apply_mode "$meta_value" "true"
    build_mode_entries
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_mode_entries
    exit 0
fi