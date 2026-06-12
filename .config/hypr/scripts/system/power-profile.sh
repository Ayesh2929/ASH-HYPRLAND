#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — POWER PROFILE MANAGER                        ║
# ║           Auto-switch AC/battery + Rofi picker + OSD                       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: power-profile.sh [ACTION]
#
# ACTIONS:
#   picker      — Rofi profile selection menu
#   auto        — Auto-switch based on AC/battery
#   performance — Set performance profile
#   balanced    — Set balanced profile (default)
#   saver       — Set power saver profile
#   status      — Show current profile JSON
#   get         — Print current profile name
#   watch       — Watch AC state and auto-switch

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/power-profile.log"
readonly STATE_FILE="${CACHE_DIR}/power-profile-state"
readonly WAYBAR_SIGNAL=11

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔋 BACKEND DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_backend() {
    if command -v powerprofilesctl &>/dev/null; then
        echo "powerprofilesctl"
    elif command -v tuned-adm &>/dev/null; then
        echo "tuned"
    elif command -v cpupower &>/dev/null; then
        echo "cpupower"
    elif [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        echo "sysfs"
    else
        echo "none"
    fi
}

readonly BACKEND=$(detect_backend)

# ═══════════════════════════════════════════════════════════════════════════════
# 🔋 AC STATE DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

is_on_ac() {
    # Check multiple AC adapter paths
    local ac_paths=(
        "/sys/class/power_supply/AC/online"
        "/sys/class/power_supply/AC0/online"
        "/sys/class/power_supply/ACAD/online"
        "/sys/class/power_supply/ADP1/online"
    )

    for path in "${ac_paths[@]}"; do
        if [[ -f "${path}" ]]; then
            local state
            state=$(cat "${path}" 2>/dev/null || echo "0")
            [[ "${state}" == "1" ]] && return 0
        fi
    done

    return 1
}

get_battery_pct() {
    local bat_paths=(
        "/sys/class/power_supply/BAT0"
        "/sys/class/power_supply/BAT1"
        "/sys/class/power_supply/BATT"
    )

    for path in "${bat_paths[@]}"; do
        if [[ -f "${path}/capacity" ]]; then
            cat "${path}/capacity"
            return 0
        fi
    done

    echo "100"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ⚡ PROFILE OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════════

get_current_profile() {
    case "${BACKEND}" in
        powerprofilesctl)
            powerprofilesctl get 2>/dev/null || echo "balanced"
            ;;
        tuned)
            tuned-adm active 2>/dev/null | grep -oP 'profile: \K\S+' || echo "balanced"
            ;;
        cpupower)
            cpupower frequency-info -p 2>/dev/null \
                | grep -oP 'governor "\K[^"]+' | head -1 || echo "powersave"
            ;;
        sysfs)
            cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null \
                || echo "powersave"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

set_profile() {
    local profile="$1"

    case "${BACKEND}" in
        powerprofilesctl)
            powerprofilesctl set "${profile}" 2>/dev/null
            ;;
        tuned)
            case "${profile}" in
                performance) tuned-adm profile throughput-performance 2>/dev/null ;;
                balanced)    tuned-adm profile balanced 2>/dev/null ;;
                power-saver) tuned-adm profile powersave 2>/dev/null ;;
            esac
            ;;
        cpupower)
            case "${profile}" in
                performance) local gov="performance" ;;
                balanced)    local gov="schedutil" ;;
                power-saver) local gov="powersave" ;;
                *)           local gov="schedutil" ;;
            esac
            sudo cpupower frequency-set -g "${gov}" 2>/dev/null || true
            ;;
        sysfs)
            local gov
            case "${profile}" in
                performance) gov="performance" ;;
                balanced)    gov="schedutil" ;;
                power-saver) gov="powersave" ;;
                *)           gov="schedutil" ;;
            esac
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                echo "${gov}" | sudo tee "${cpu}" > /dev/null 2>&1 || true
            done
            ;;
    esac

    echo "${profile}" > "${STATE_FILE}"
    log "INFO" "Profile set: ${profile} via ${BACKEND}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 AUTO PROFILE
# ═══════════════════════════════════════════════════════════════════════════════

auto_profile() {
    local battery_pct
    battery_pct=$(get_battery_pct)

    if is_on_ac; then
        set_profile "performance"
        info "AC connected → Performance mode"
    elif (( battery_pct <= 20 )); then
        set_profile "power-saver"
        info "Battery low (${battery_pct}%) → Power Saver mode"
        notify-send "🔋 Power Saver" \
            "Battery at ${battery_pct}% — Power Saver enabled" \
            --app-name="ASH Power" \
            --urgency=normal \
            --expire-time=4000 \
            2>/dev/null || true
    elif (( battery_pct <= 50 )); then
        set_profile "balanced"
        info "Battery ${battery_pct}% → Balanced mode"
    else
        set_profile "balanced"
        info "Battery ${battery_pct}% → Balanced mode"
    fi

    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ROFI PICKER
# ═══════════════════════════════════════════════════════════════════════════════

rofi_picker() {
    local current
    current=$(get_current_profile)
    local battery_pct
    battery_pct=$(get_battery_pct)
    local ac_status
    is_on_ac && ac_status="⚡ AC" || ac_status="🔋 Battery (${battery_pct}%)"

    local profiles=(
        "⚡ Performance\0info\x1fMaximum performance, highest power usage"
        "⚖️ Balanced\0info\x1fOptimal balance of performance and efficiency"
        "🌱 Power Saver\0info\x1fMinimum power usage, extends battery life"
    )

    local prompt="🔋 Power Profile — ${ac_status} — Current: ${current}"

    local selected
    selected=$(printf '%s\n' "${profiles[@]}" | rofi \
        -dmenu \
        -i \
        -p "${prompt}" \
        -theme-str 'window { width: 500px; }' \
        -theme-str 'listview { lines: 3; }' \
        2>/dev/null) || {
        info "Picker cancelled"
        return 0
    }

    case "${selected}" in
        *Performance*)
            set_profile "performance"
            notify-send "⚡ Performance Mode" \
                "Maximum performance enabled" \
                --app-name="ASH Power" --expire-time=3000 2>/dev/null || true
            ;;
        *Balanced*)
            set_profile "balanced"
            notify-send "⚖️ Balanced Mode" \
                "Balanced profile enabled" \
                --app-name="ASH Power" --expire-time=3000 2>/dev/null || true
            ;;
        *Saver* | *saver*)
            set_profile "power-saver"
            notify-send "🌱 Power Saver" \
                "Power saver enabled" \
                --app-name="ASH Power" --expire-time=3000 2>/dev/null || true
            ;;
    esac

    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 👁️ AC WATCHER DAEMON
# ═══════════════════════════════════════════════════════════════════════════════

watch_ac() {
    info "Watching AC state (Ctrl+C to stop)..."

    local last_ac_state=""

    while true; do
        local current_state
        is_on_ac && current_state="ac" || current_state="battery"

        if [[ "${current_state}" != "${last_ac_state}" ]]; then
            log "INFO" "AC state changed: ${last_ac_state} → ${current_state}"
            auto_profile
            last_ac_state="${current_state}"
        fi

        sleep 10
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 STATUS JSON
# ═══════════════════════════════════════════════════════════════════════════════

status_json() {
    local profile
    profile=$(get_current_profile)
    local battery_pct
    battery_pct=$(get_battery_pct)
    local ac
    is_on_ac && ac="true" || ac="false"

    local icon class
    case "${profile}" in
        performance)
            icon="⚡"
            class="performance"
            ;;
        balanced)
            icon="⚖️"
            class="balanced"
            ;;
        power-saver)
            icon="🌱"
            class="saver"
            ;;
        *)
            icon="❓"
            class="unknown"
            ;;
    esac

    printf '{"text": "%s %s", "tooltip": "Profile: %s\nBattery: %s%%\nAC: %s\nBackend: %s", "class": "%s"}\n' \
        "${icon}" "${profile^}" "${profile}" "${battery_pct}" "${ac}" "${BACKEND}" "${class}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        picker)
            rofi_picker
            ;;

        auto)
            auto_profile
            ;;

        performance)
            set_profile "performance"
            ok "Performance mode enabled"
            notify-send "⚡ Performance" "Performance profile active" \
                --app-name="ASH Power" --expire-time=2000 2>/dev/null || true
            pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
            ;;

        balanced)
            set_profile "balanced"
            ok "Balanced mode enabled"
            notify-send "⚖️ Balanced" "Balanced profile active" \
                --app-name="ASH Power" --expire-time=2000 2>/dev/null || true
            pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
            ;;

        saver | power-saver)
            set_profile "power-saver"
            ok "Power saver enabled"
            notify-send "🌱 Power Saver" "Power saver profile active" \
                --app-name="ASH Power" --expire-time=2000 2>/dev/null || true
            pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
            ;;

        get)
            get_current_profile
            ;;

        status)
            status_json
            ;;

        watch)
            watch_ac
            ;;

        battery)
            echo "$(get_battery_pct)%"
            ;;

        ac)
            is_on_ac && echo "plugged" || echo "unplugged"
            ;;

        backend)
            echo "${BACKEND}"
            ;;

        *)
            echo "Usage: power-profile.sh [picker|auto|performance|balanced|saver|get|status|watch]"
            exit 1
            ;;
    esac
}

main "$@"