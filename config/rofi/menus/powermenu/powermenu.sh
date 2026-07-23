#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Power Menu Script                                 ║
# ║                                                                              ║
# ║  Full-featured system power management via Rofi custom mode.               ║
# ║  Features: ASH snapshot before action, confirmation dialog, countdown,     ║
# ║  session info display, systemd integration and graceful app closing.        ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    ~/.config/rofi/menus/powermenu/powermenu.sh                             ║
# ║    rofi -show p -modi "p:PATH/powermenu.sh" -config PATH/powermenu.rasi    ║
# ║                                                                              ║
# ║  Environment:                                                                ║
# ║    ROFI_RETV   — Rofi return value (0=init, 1=selected, 2=custom)          ║
# ║    ROFI_INFO   — Info field from selected entry                             ║
# ║    ROFI_DATA   — Persistent data across calls                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

# ── Countdown before action (seconds, 0 = immediate) ──────────────────────────
readonly COUNTDOWN_SECS=3

# ── Create ASH snapshot before destructive actions ────────────────────────────
readonly SNAPSHOT_BEFORE=true

# ── Confirm destructive actions (shutdown, reboot, hibernate) ─────────────────
readonly CONFIRM_DESTRUCTIVE=true

# ── Session info display ──────────────────────────────────────────────────────
readonly SHOW_SESSION_INFO=true

# ── Notification sound (path or empty to disable) ─────────────────────────────
readonly SOUND_FILE="${HOME}/.config/ash-dotfiles/assets/sounds/shutdown.ogg"

# ══════════════════════════════════════════════════════════════════════════════
# §02  ACTION DEFINITIONS
#      Format: "ICON LABEL\0info\x1fACTION_ID"
#      Icon + label displayed, ACTION_ID used internally for dispatch
# ══════════════════════════════════════════════════════════════════════════════

# ── Action entries with nerd font icons ───────────────────────────────────────
declare -A ACTIONS=(
    ["shutdown"]="⏻\nShutdown"
    ["reboot"]="↺\nReboot"
    ["hibernate"]="󰤄\nHibernate"
    ["suspend"]="󰒲\nSuspend"
    ["logout"]="󰍃\nLogout"
    ["lock"]="󰌾\nLock"
)

# Action display order
declare -a ACTION_ORDER=("shutdown" "reboot" "hibernate" "suspend" "logout" "lock")

# ── Destructive actions requiring confirmation ─────────────────────────────────
declare -a DESTRUCTIVE_ACTIONS=("shutdown" "reboot" "hibernate")

# ══════════════════════════════════════════════════════════════════════════════
# §03  SESSION INFORMATION
# ══════════════════════════════════════════════════════════════════════════════

get_username() {
    echo "${USER:-$(whoami 2>/dev/null || echo "user")}"
}

get_hostname() {
    hostname 2>/dev/null || echo "localhost"
}

get_datetime() {
    date '+%a %d %b  ·  %H:%M' 2>/dev/null || echo "Unknown"
}

get_uptime() {
    if command -v uptime &>/dev/null; then
        uptime -p 2>/dev/null | sed 's/up //' | sed 's/ hours*/h/; s/ minutes*/m/; s/ days*/d/; s/,//g'
    else
        echo "unknown"
    fi
}

get_battery() {
    local bat_path
    for bat_path in /sys/class/power_supply/BAT*/; do
        if [[ -f "${bat_path}capacity" ]]; then
            local pct status
            pct=$(cat "${bat_path}capacity" 2>/dev/null || echo "?")
            status=$(cat "${bat_path}status" 2>/dev/null || echo "")
            local icon="🔋"
            [[ "$status" == "Charging" ]] && icon="⚡"
            [[ "${pct:-0}" -le 20 ]] && icon="🪫"
            echo "${icon} ${pct}%"
            return 0
        fi
    done
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  UTILITY FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

is_destructive() {
    local action="$1"
    for d in "${DESTRUCTIVE_ACTIONS[@]}"; do
        [[ "$d" == "$action" ]] && return 0
    done
    return 1
}

notify() {
    local title="$1" msg="$2" urgency="${3:-normal}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Power Menu" \
        --urgency="$urgency" \
        --expire-time=5000 \
        --hint=string:x-dunst-stack-tag:powermenu \
        2>/dev/null || true
}

play_sound() {
    [[ -f "$SOUND_FILE" ]] && \
        paplay "$SOUND_FILE" &>/dev/null & disown || true
}

create_snapshot() {
    if [[ "$SNAPSHOT_BEFORE" == "true" ]] && command -v ash &>/dev/null; then
        notify "ASH" "Creating config snapshot before action…" "low"
        ash snapshot create --tag "pre-power-$(date +%H%M%S)" &>/dev/null && \
            notify "ASH" "Snapshot created  — proceeding with action" "low" || true
    fi
}

countdown() {
    local action="$1"
    local secs="${COUNTDOWN_SECS}"
    [[ "$secs" -le 0 ]] && return 0

    for i in $(seq "$secs" -1 1); do
        notify "⚡ ASH Power Menu" "$(echo "$action" | sed 's/.*/\u&/') in ${i}s…\n\nPress Cancel to abort" "normal"
        sleep 1
    done
}

close_apps_gracefully() {
    # Send WM_DELETE_WINDOW to all applications before logout
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exit 2>/dev/null || true
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  ACTION EXECUTORS
# ══════════════════════════════════════════════════════════════════════════════

exec_shutdown() {
    notify "⏻ Shutting down" "System will power off in ${COUNTDOWN_SECS}s…" "critical"
    play_sound
    create_snapshot
    countdown "Shutdown"
    sync
    systemctl poweroff
}

exec_reboot() {
    notify "↺ Rebooting" "System will restart in ${COUNTDOWN_SECS}s…" "critical"
    play_sound
    create_snapshot
    countdown "Reboot"
    sync
    systemctl reboot
}

exec_hibernate() {
    notify "󰤄 Hibernating" "Saving system state…" "normal"
    create_snapshot
    sleep 0.5
    systemctl hibernate
}

exec_suspend() {
    notify "󰒲 Suspending" "System entering sleep mode" "low"
    hyprlock --immediate &>/dev/null &
    sleep 0.5
    systemctl suspend
}

exec_logout() {
    notify "󰍃 Logging out" "Closing session…" "normal"
    create_snapshot
    sleep 0.5
    # Hyprland: dispatch exit
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch exit
    # Sway fallback
    elif command -v swaymsg &>/dev/null; then
        swaymsg exit
    # systemd session fallback
    else
        loginctl terminate-user "${USER:-$LOGNAME}"
    fi
}

exec_lock() {
    notify "󰌾 Locking screen" "" "low"
    hyprlock --immediate &>/dev/null &
}

dispatch_action() {
    local action="$1"
    case "$action" in
        shutdown)  exec_shutdown  ;;
        reboot)    exec_reboot    ;;
        hibernate) exec_hibernate ;;
        suspend)   exec_suspend   ;;
        logout)    exec_logout    ;;
        lock)      exec_lock      ;;
        *)
            notify "ASH Power Menu" "Unknown action: $action" "critical"
            exit 1
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  CONFIRMATION DIALOG
# ══════════════════════════════════════════════════════════════════════════════

show_confirmation() {
    local action="$1"
    local action_label
    action_label="$(echo "$action" | sed 's/.*/\u&/')"

    local confirm_choice
    confirm_choice=$(printf "Yes, %s\nNo, cancel" "$action_label" | \
        rofi \
            -dmenu \
            -p "Confirm ${action_label}?" \
            -mesg "<b>${action_label}</b> will affect your session.\n\nAre you sure?" \
            -config "${HOME}/.config/rofi/menus/powermenu/powermenu.rasi" \
            -theme-str \
                "window { width: 320px; height: 0px; }
                 listview { lines: 2; columns: 1; }
                 element { padding: 10px 16px; border-radius: 8px; }
                 element selected.normal { background-color: #f38ba8; text-color: #1e1e2e; }" \
            2>/dev/null || echo "")

    [[ "$confirm_choice" == "Yes, ${action_label}" ]]
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  ROFI CUSTOM MODE PROTOCOL
#      Rofi calls this script repeatedly:
#      - ROFI_RETV=0: initialization (print menu entries)
#      - ROFI_RETV=1: entry selected (execute action)
#      - ROFI_RETV=2: custom input
# ══════════════════════════════════════════════════════════════════════════════

# ── Helper: build session info prompt ─────────────────────────────────────────
build_prompt() {
    local USER_LINE HOST_LINE DT_LINE UP_LINE BAT_LINE
    USER_LINE="$(get_username)"
    HOST_LINE="@$(get_hostname)"
    DT_LINE="$(get_datetime)"
    UP_LINE="⏱ $(get_uptime)"
    BAT_LINE="$(get_battery)"

    # Rofi prompt (shown in inputbar area — hidden in powermenu)
    echo -en "${USER_LINE}${HOST_LINE}  ·  ${DT_LINE}"
}

# ── Helper: build menu entries ─────────────────────────────────────────────────
build_entries() {
    for action in "${ACTION_ORDER[@]}"; do
        case "$action" in
            shutdown)  echo -en "⏻\nShutdown\0info\x1fshutdown\n"  ;;
            reboot)    echo -en "↺\nReboot\0info\x1freboot\n"      ;;
            hibernate) echo -en "󰤄\nHibernate\0info\x1fhibernate\n" ;;
            suspend)   echo -en "󰒲\nSuspend\0info\x1fsuspend\n"    ;;
            logout)    echo -en "󰍃\nLogout\0info\x1flogout\n"      ;;
            lock)      echo -en "󰌾\nLock\0info\x1flock\n"          ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  MAIN EXECUTION
# ══════════════════════════════════════════════════════════════════════════════

main() {
    # ── Case 1: Direct invocation (not from Rofi) ──────────────────────────────
    if [[ -z "${ROFI_RETV:-}" ]]; then
        # Launch rofi with this script as the custom mode
        rofi \
            -show p \
            -modi "p:${BASH_SOURCE[0]}" \
            -config "${HOME}/.config/rofi/menus/powermenu/powermenu.rasi" \
            -p "$(build_prompt)" \
            2>/dev/null
        exit 0
    fi

    # ── Case 2: Rofi initialization (ROFI_RETV=0) ─────────────────────────────
    if [[ "$ROFI_RETV" -eq 0 ]]; then
        # Output all menu entries
        build_entries
        exit 0
    fi

    # ── Case 3: Entry selected (ROFI_RETV=1) ──────────────────────────────────
    if [[ "$ROFI_RETV" -eq 1 ]]; then
        local selected_action="${ROFI_INFO:-}"

        # Validate action
        if [[ -z "$selected_action" ]]; then
            # Try to extract from stdin (selected text)
            local selected_text="${1:-}"
            case "${selected_text,,}" in
                *shutdown*)  selected_action="shutdown"  ;;
                *reboot*)    selected_action="reboot"    ;;
                *hibernate*) selected_action="hibernate" ;;
                *suspend*)   selected_action="suspend"   ;;
                *logout*)    selected_action="logout"    ;;
                *lock*)      selected_action="lock"      ;;
                *)           exit 0                      ;;
            esac
        fi

        # Confirmation for destructive actions
        if [[ "$CONFIRM_DESTRUCTIVE" == "true" ]] && is_destructive "$selected_action"; then
            if ! show_confirmation "$selected_action"; then
                notify "ASH" "Action cancelled" "low"
                exit 0
            fi
        fi

        # Execute action
        dispatch_action "$selected_action"
        exit 0
    fi

    # ── Case 4: Custom input (ROFI_RETV=2) ────────────────────────────────────
    if [[ "$ROFI_RETV" -eq 2 ]]; then
        # Re-output entries (user typed something, re-filter)
        build_entries
        exit 0
    fi
}

main "$@"