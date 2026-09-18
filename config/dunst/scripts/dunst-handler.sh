#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔔 ASH DOTFILES v5.0 OMEGA — DUNST HANDLER SCRIPT                         ║
# ║  Ultra-smart notification action dispatcher                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 📁 Location  : ~/.config/dunst/scripts/dunst-handler.sh
# 📦 Requires  : bash ≥ 5.0, dunst, notify-send, jq, paplay (optional)
# 🔗 Called by : dunstrc → script = dunst-handler.sh
# 🎯 Purpose   : Central handler for all critical notification actions
#                Routes events to appropriate system responses
#
# Environment Variables (set by dunst):
#   DUNST_APP_NAME    — application name
#   DUNST_SUMMARY     — notification summary
#   DUNST_BODY        — notification body
#   DUNST_ICON_PATH   — icon path
#   DUNST_URGENCY     — LOW / NORMAL / CRITICAL
#   DUNST_ID          — notification ID
#   DUNST_PROGRESS    — progress value (-1 if none)
#   DUNST_TIMEOUT     — timeout in milliseconds
#   DUNST_TIMESTAMP   — unix timestamp
#   DUNST_STACK_TAG   — stack tag
#   DUNST_URLS        — URLs in notification
#
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────────────────────────────────
# 📁  PATHS & CONSTANTS
# ──────────────────────────────────────────────────────────────────────────────

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ASH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly ASH_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly ASH_LOG_DIR="${ASH_DATA}/logs"
readonly ASH_STATE_DIR="${ASH_DATA}/state"
readonly DUNST_LOG="${ASH_LOG_DIR}/dunst-handler.log"
readonly SOUND_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dunst/sounds"
readonly ASH_SOUNDS="${XDG_CONFIG_HOME:-$HOME/.config}/dunst/../../../assets/sounds"

# Dunst environment (with safe defaults)
readonly APP="${DUNST_APP_NAME:-unknown}"
readonly SUMMARY="${DUNST_SUMMARY:-}"
readonly BODY="${DUNST_BODY:-}"
readonly URGENCY="${DUNST_URGENCY:-NORMAL}"
readonly NOTIF_ID="${DUNST_ID:-0}"
readonly TIMESTAMP="${DUNST_TIMESTAMP:-$(date +%s)}"

# ──────────────────────────────────────────────────────────────────────────────
# 🎨  COLORS (for log output)
# ──────────────────────────────────────────────────────────────────────────────

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly MAGENTA=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RESET=$'\033[0m'

# ──────────────────────────────────────────────────────────────────────────────
# 📝  LOGGING
# ──────────────────────────────────────────────────────────────────────────────

_ensure_dirs() {
    mkdir -p \
        "${ASH_LOG_DIR}" \
        "${ASH_STATE_DIR}" \
        2>/dev/null || true
}

_log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    local color="${RESET}"
    case "${level}" in
        DEBUG)   color="${DIM}" ;;
        INFO)    color="${CYAN}" ;;
        WARN)    color="${YELLOW}" ;;
        ERROR)   color="${RED}" ;;
        CRITICAL) color="${BOLD}${RED}" ;;
        SUCCESS) color="${GREEN}" ;;
        ACTION)  color="${MAGENTA}" ;;
    esac

    # Console output (only if terminal attached)
    if [[ -t 2 ]]; then
        printf "${color}[%s] [%-8s] %s${RESET}\n" \
            "${timestamp}" "${level}" "${message}" >&2
    fi

    # File output
    printf '[%s] [%-8s] [app=%s] [urgency=%s] %s\n' \
        "${timestamp}" "${level}" "${APP}" "${URGENCY}" "${message}" \
        >> "${DUNST_LOG}" 2>/dev/null || true
}

_log_event() {
    _log "INFO" "Handling: app='${APP}' summary='${SUMMARY}' body='${BODY}'"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔊  SOUND PLAYER
# ──────────────────────────────────────────────────────────────────────────────

_play_sound() {
    local sound_name="${1:-notification}"
    local sound_file=""

    # Sound search priority
    local search_dirs=(
        "${SOUND_DIR}"
        "${ASH_SOUNDS}"
        "/usr/share/sounds/freedesktop/stereo"
        "/usr/share/sounds"
    )

    local extensions=("ogg" "wav" "mp3" "flac")

    for dir in "${search_dirs[@]}"; do
        for ext in "${extensions[@]}"; do
            local candidate="${dir}/${sound_name}.${ext}"
            if [[ -f "${candidate}" ]]; then
                sound_file="${candidate}"
                break 2
            fi
        done
    done

    if [[ -z "${sound_file}" ]]; then
        _log "DEBUG" "Sound not found: ${sound_name}"
        return 0
    fi

    # Play with first available player (non-blocking)
    if command -v paplay &>/dev/null; then
        paplay "${sound_file}" &>/dev/null &
    elif command -v pw-play &>/dev/null; then
        pw-play "${sound_file}" &>/dev/null &
    elif command -v aplay &>/dev/null; then
        aplay "${sound_file}" &>/dev/null &
    elif command -v ffplay &>/dev/null; then
        ffplay -nodisp -autoexit "${sound_file}" &>/dev/null &
    fi

    _log "DEBUG" "Playing sound: ${sound_file}"
}

# ──────────────────────────────────────────────────────────────────────────────
# 📢  NOTIFICATION HELPERS
# ──────────────────────────────────────────────────────────────────────────────

_notify() {
    local summary="${1:-ASH}"
    local body="${2:-}"
    local urgency="${3:-normal}"
    local icon="${4:-dialog-information}"
    local timeout="${5:-5000}"

    notify-send \
        --app-name="ash-handler" \
        --urgency="${urgency}" \
        --icon="${icon}" \
        --expire-time="${timeout}" \
        "${summary}" \
        "${body}" \
        2>/dev/null || true
}

_notify_critical() {
    local summary="${1:-Critical Alert}"
    local body="${2:-}"
    _notify "${summary}" "${body}" "critical" "dialog-error" "0"
}

_notify_success() {
    local summary="${1:-Success}"
    local body="${2:-}"
    _notify "${summary}" "${body}" "low" "dialog-information" "4000"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🖥️  HYPRLAND IPC
# ──────────────────────────────────────────────────────────────────────────────

_hypr_dispatch() {
    local command="${1:-}"
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch "${command}" &>/dev/null || true
    fi
}

_hypr_keyword() {
    local keyword="${1:-}"
    local value="${2:-}"
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword "${keyword}" "${value}" &>/dev/null || true
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🧰  SYSTEM UTILITIES
# ──────────────────────────────────────────────────────────────────────────────

_open_url() {
    local url="${1:-}"
    if [[ -n "${url}" ]]; then
        xdg-open "${url}" &>/dev/null &
    fi
}

_run_async() {
    local cmd=("$@")
    "${cmd[@]}" &>/dev/null &
    disown
}

_run_terminal() {
    local cmd="${1:-}"
    if command -v kitty &>/dev/null; then
        kitty --title="ASH Handler" -e bash -c "${cmd}; read -p 'Press Enter...'" &
    elif command -v foot &>/dev/null; then
        foot --title="ASH Handler" bash -c "${cmd}; read -p 'Press Enter...'" &
    elif command -v alacritty &>/dev/null; then
        alacritty --title "ASH Handler" -e bash -c "${cmd}; read -p 'Press Enter...'" &
    fi
}

_write_state() {
    local key="${1:-}"
    local value="${2:-}"
    if [[ -n "${key}" ]]; then
        printf '%s\n' "${value}" > "${ASH_STATE_DIR}/${key}" 2>/dev/null || true
    fi
}

_read_state() {
    local key="${1:-}"
    local default="${2:-}"
    local state_file="${ASH_STATE_DIR}/${key}"
    if [[ -f "${state_file}" ]]; then
        cat "${state_file}"
    else
        printf '%s' "${default}"
    fi
}

_increment_counter() {
    local counter_name="${1:-}"
    local current
    current="$(_read_state "${counter_name}" "0")"
    _write_state "${counter_name}" "$(( current + 1 ))"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔋  BATTERY HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_battery_critical() {
    _log "CRITICAL" "Battery critical — triggering emergency actions"
    _play_sound "battery-critical"

    # Increment alert counter
    _increment_counter "battery_critical_count"

    local count
    count="$(_read_state "battery_critical_count" "1")"

    # Save work signal
    _write_state "battery_emergency" "$(date +%s)"

    # Progressive response based on alert count
    case "${count}" in
        1)
            _log "ACTION" "Battery critical (1st alert) — warning user"
            _notify_critical \
                "🔴 Battery Critical!" \
                "Plug in charger immediately\nSystem will shutdown soon"
            ;;
        2)
            _log "ACTION" "Battery critical (2nd alert) — aggressive warning"
            # Flash screen border red
            _hypr_keyword "general:col.active_border" "rgba(f38ba8ff)"
            _notify_critical \
                "🔴 Battery EMERGENCY" \
                "Saving state — plug in NOW"
            ;;
        3|*)
            _log "ACTION" "Battery critical (3rd+ alert) — emergency suspend"
            # Auto-suspend to prevent data loss
            _notify_critical \
                "💀 Suspending System" \
                "Battery exhausted — suspending to prevent data loss"
            sleep 3
            systemctl suspend 2>/dev/null || \
                loginctl suspend 2>/dev/null || true
            ;;
    esac
}

_handle_battery_low() {
    _log "WARN" "Battery low — notifying user"
    _play_sound "battery-low"
    _write_state "battery_low_time" "$(date +%s)"

    # Switch to power saver mode automatically
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set power-saver 2>/dev/null && \
            _log "ACTION" "Switched to power-saver profile"
    fi

    # Notify ASH battery mode
    if command -v ash &>/dev/null; then
        ash mode battery 2>/dev/null & true
    fi
}

_handle_battery_charging() {
    # Reset counters when charging
    _write_state "battery_critical_count" "0"
    _write_state "battery_emergency" ""
    _log "SUCCESS" "Battery charging — reset alert counters"

    # Restore normal mode if was in battery saver
    local prev_mode
    prev_mode="$(_read_state "pre_battery_mode" "")"
    if [[ -n "${prev_mode}" && "${prev_mode}" != "battery" ]]; then
        if command -v ash &>/dev/null; then
            ash mode "${prev_mode}" 2>/dev/null & true
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🌡️  HARDWARE TEMPERATURE HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_thermal_critical() {
    _log "CRITICAL" "Thermal emergency: ${SUMMARY}"
    _play_sound "error"

    # Immediate CPU throttle
    if command -v cpupower &>/dev/null; then
        cpupower frequency-set --max 800MHz 2>/dev/null && \
            _log "ACTION" "CPU throttled to 800MHz"
    fi

    # Kill GPU-intensive processes if nvidia
    if command -v nvidia-smi &>/dev/null; then
        _log "ACTION" "Checking GPU load"
    fi

    # Record thermal event
    _write_state "last_thermal_critical" "$(date +%s)"
    _increment_counter "thermal_critical_count"

    # Switch to power saver
    powerprofilesctl set power-saver 2>/dev/null || true

    # Notify
    _notify_critical \
        "🔥 Thermal Emergency!" \
        "${SUMMARY}\n${BODY}\nCPU throttled to reduce heat"
}

_handle_thermal_warning() {
    _log "WARN" "Thermal warning: ${SUMMARY}"

    # Switch to balanced mode
    powerprofilesctl set balanced 2>/dev/null || true

    # Disable turbo boost
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo \
            &>/dev/null || true
        _log "ACTION" "Intel turbo boost disabled"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 💾  STORAGE HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_disk_critical() {
    _log "CRITICAL" "Disk critical: ${SUMMARY}"
    _play_sound "error"

    # Open disk usage tool
    if command -v baobab &>/dev/null; then
        _run_async baobab
    elif command -v ncdu &>/dev/null; then
        _run_terminal "ncdu $HOME"
    fi

    # Auto-clean Docker if available
    if command -v docker &>/dev/null; then
        _log "ACTION" "Cleaning Docker artifacts"
        docker system prune -f &>/dev/null & true
    fi

    # Clean package cache
    if command -v paccache &>/dev/null; then
        paccache -rk1 &>/dev/null & true
        _log "ACTION" "Cleaned pacman cache"
    fi

    # Clean ash cache
    if [[ -d "${ASH_DATA}/cache" ]]; then
        find "${ASH_DATA}/cache" \
            -type f \
            -atime +7 \
            -delete \
            2>/dev/null && \
            _log "ACTION" "Cleaned ASH cache (files older than 7 days)"
    fi
}

_handle_smart_failure() {
    _log "CRITICAL" "SMART failure: ${SUMMARY}"
    _play_sound "error"

    # Emergency backup trigger
    _write_state "smart_failure_detected" "$(date +%s)"

    # Auto-trigger backup if configured
    if command -v ash &>/dev/null; then
        ash backup create --emergency 2>/dev/null & true
        _log "ACTION" "Emergency backup triggered"
    fi

    _notify_critical \
        "💀 Drive Failure Imminent!" \
        "BACKUP ALL DATA NOW\n${BODY}"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔐  SECURITY HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_auth_failure() {
    _log "WARN" "Auth failure: ${SUMMARY}"
    _play_sound "error"
    _increment_counter "auth_failure_count"

    local count
    count="$(_read_state "auth_failure_count" "1")"

    # After 5 failures, lock screen
    if (( count >= 5 )); then
        _log "ACTION" "Multiple auth failures — locking screen"
        if command -v hyprlock &>/dev/null; then
            hyprlock &>/dev/null &
        elif command -v swaylock &>/dev/null; then
            swaylock &>/dev/null &
        fi
        _write_state "auth_failure_count" "0"
    fi

    _write_state "last_auth_failure" "$(date +%s)"
}

_handle_security_breach() {
    _log "CRITICAL" "Security breach: ${SUMMARY}"
    _play_sound "error"

    # Write security event log
    cat >> "${ASH_LOG_DIR}/security-events.log" <<EOF
$(date '+%Y-%m-%d %H:%M:%S') BREACH: ${SUMMARY} — ${BODY}
EOF

    # Activate privacy mode
    if command -v ash &>/dev/null; then
        ash mode privacy 2>/dev/null & true
        _log "ACTION" "Privacy mode activated"
    fi

    # Optionally kill network
    local severity="${BODY}"
    if [[ "${severity}" == *"firewall"* ]] || \
       [[ "${SUMMARY}" == *"intrusion"* ]]; then
        _log "ACTION" "Blocking network interfaces"
        # nmcli networking off &>/dev/null || true
    fi

    _write_state "last_security_breach" "$(date +%s)"
}

_handle_vpn_kill_switch() {
    _log "CRITICAL" "VPN kill switch active: ${SUMMARY}"
    _play_sound "warning"

    _write_state "vpn_kill_switch" "active"

    # Notify with recovery instructions
    _notify_critical \
        "⛔ Network Blocked — Kill Switch" \
        "VPN disconnected. No internet until restored.\nRun: ash net vpn connect"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🌐  NETWORK HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_network_loss() {
    _log "WARN" "Network loss: ${SUMMARY}"
    _play_sound "network-disconnect"

    _write_state "network_offline_since" "$(date +%s)"

    # Pause bandwidth-intensive services
    if command -v systemctl &>/dev/null; then
        systemctl --user stop \
            ash-cloud-sync.service \
            &>/dev/null || true
    fi
}

_handle_dns_failure() {
    _log "CRITICAL" "DNS failure: ${SUMMARY}"
    _play_sound "error"

    # Try fallback DNS
    if command -v resolvectl &>/dev/null; then
        _log "ACTION" "Setting fallback DNS"
        local interfaces
        interfaces="$(resolvectl status --no-pager 2>/dev/null | \
            grep 'Link' | awk '{print $2}' | tr -d '()' | head -3)"

        for iface in ${interfaces}; do
            resolvectl dns "${iface}" 1.1.1.1 8.8.8.8 &>/dev/null || true
        done
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🐳  DOCKER HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_docker_crash() {
    _log "CRITICAL" "Docker daemon crash: ${SUMMARY}"
    _play_sound "error"

    _write_state "docker_crashed_at" "$(date +%s)"

    # Attempt restart
    _log "ACTION" "Attempting Docker daemon restart"
    systemctl restart docker &>/dev/null & true

    sleep 3

    # Verify restart
    if docker info &>/dev/null; then
        _log "SUCCESS" "Docker daemon restarted successfully"
        _notify_success "🐳 Docker Restarted" "Daemon recovered automatically"
    else
        _log "ERROR" "Docker daemon failed to restart"
        _notify_critical \
            "🐳 Docker Failed to Restart" \
            "Manual intervention required\nCheck: journalctl -u docker"
    fi
}

_handle_docker_oom() {
    _log "CRITICAL" "Container OOM: ${SUMMARY}"
    _play_sound "error"

    # Get container name from body
    local container_name="${BODY%%:*}"

    _write_state "last_container_oom" "${container_name}:$(date +%s)"

    # Log to Docker event log
    cat >> "${ASH_LOG_DIR}/docker-events.log" <<EOF
$(date '+%Y-%m-%d %H:%M:%S') OOM_KILLED: ${SUMMARY} — ${BODY}
EOF
}

# ──────────────────────────────────────────────────────────────────────────────
# 🎨  ASH THEME HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_theme_error() {
    _log "ERROR" "Theme error: ${SUMMARY}"
    _play_sound "error"

    _write_state "last_theme_error" "$(date +%s)"

    # Auto-restore last good snapshot
    if command -v ash &>/dev/null; then
        local last_good
        last_good="$(_read_state "last_good_theme_snapshot" "")"

        if [[ -n "${last_good}" ]]; then
            _log "ACTION" "Restoring last good theme snapshot: ${last_good}"
            ash snapshot restore "${last_good}" 2>/dev/null & true
        else
            _log "ACTION" "Resetting to default theme"
            ash theme reset 2>/dev/null & true
        fi
    fi
}

_handle_theme_applied() {
    _log "SUCCESS" "Theme applied: ${SUMMARY}"

    # Save as last good state
    if command -v ash &>/dev/null; then
        local snapshot_id
        snapshot_id="$(ash snapshot create \
            --name "pre-theme-$(date +%Y%m%d%H%M%S)" \
            --quiet 2>/dev/null)" || true

        if [[ -n "${snapshot_id}" ]]; then
            _write_state "last_good_theme_snapshot" "${snapshot_id}"
        fi
    fi

    # Update waybar
    if command -v pkill &>/dev/null; then
        pkill -SIGUSR2 waybar &>/dev/null || true
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 💾  SNAPSHOT HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_snapshot_corrupt() {
    _log "CRITICAL" "Snapshot corrupted: ${SUMMARY}"
    _play_sound "error"

    _write_state "snapshot_corrupt_detected" "$(date +%s)"

    # List remaining valid snapshots
    if command -v ash &>/dev/null; then
        local valid_count
        valid_count="$(ash snapshot list --valid-only --count 2>/dev/null || echo 0)"
        _log "INFO" "Valid snapshots remaining: ${valid_count}"
    fi
}

_handle_snapshot_failed() {
    _log "ERROR" "Snapshot failed: ${SUMMARY}"
    _play_sound "error"

    _increment_counter "snapshot_fail_count"

    local count
    count="$(_read_state "snapshot_fail_count" "1")"

    if (( count >= 3 )); then
        _log "ACTION" "Multiple snapshot failures — checking disk space"
        local disk_usage
        disk_usage="$(df -h "${HOME}" | awk 'NR==2 {print $5}' | tr -d '%')"

        if (( disk_usage > 90 )); then
            _notify_critical \
                "💾 Disk Nearly Full!" \
                "Cannot create snapshots\nDisk usage: ${disk_usage}%\nRun: ash snapshot clean"
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🏠  HOME ASSISTANT HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_home_emergency() {
    _log "CRITICAL" "Home emergency: ${SUMMARY}"
    _play_sound "error"

    # Flash all windows red (visual alarm)
    _hypr_keyword "general:col.active_border" "rgba(f38ba8ff)"
    _hypr_keyword "general:col.inactive_border" "rgba(f38ba8aa)"

    # Write emergency log
    cat >> "${ASH_LOG_DIR}/home-alerts.log" <<EOF
$(date '+%Y-%m-%d %H:%M:%S') EMERGENCY: ${SUMMARY} — ${BODY}
EOF

    # Maximum volume for audible alert
    if command -v pamixer &>/dev/null; then
        pamixer --unmute --set-volume 100 &>/dev/null || true
    fi

    # Repeat sound 3 times
    for _ in 1 2 3; do
        _play_sound "notification-critical"
        sleep 1
    done
}

# ──────────────────────────────────────────────────────────────────────────────
# ⚙️  SYSTEMD SERVICE HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_service_failed() {
    _log "CRITICAL" "Service failed: ${SUMMARY}"
    _play_sound "error"

    # Extract service name
    local service_name
    service_name="$(printf '%s' "${BODY}" | grep -oP '[\w\-]+\.service' | head -1)"

    if [[ -n "${service_name}" ]]; then
        _write_state "failed_service_${service_name}" "$(date +%s)"

        # Log service failure details
        {
            printf '=%.0s' {1..60}
            echo
            echo "$(date '+%Y-%m-%d %H:%M:%S') SERVICE FAILED: ${service_name}"
            systemctl --user status "${service_name}" 2>/dev/null | tail -20
            journalctl --user -u "${service_name}" -n 20 --no-pager 2>/dev/null
            printf '=%.0s' {1..60}
            echo
        } >> "${ASH_LOG_DIR}/service-failures.log" 2>/dev/null || true
    fi
}

_handle_core_dump() {
    _log "CRITICAL" "Core dump detected: ${SUMMARY}"
    _play_sound "error"

    _write_state "last_core_dump" "$(date +%s)"

    # Log core dump
    cat >> "${ASH_LOG_DIR}/crashes.log" <<EOF
$(date '+%Y-%m-%d %H:%M:%S') CORE_DUMP: ${SUMMARY} — ${BODY}
EOF
}

# ──────────────────────────────────────────────────────────────────────────────
# 📸  SCREENSHOT HANDLERS
# ──────────────────────────────────────────────────────────────────────────────

_handle_screenshot_saved() {
    _log "SUCCESS" "Screenshot saved: ${BODY}"
    _play_sound "screenshot"

    # Extract file path from body
    local file_path="${BODY}"

    if [[ -f "${file_path}" ]]; then
        # Copy to clipboard
        if command -v wl-copy &>/dev/null; then
            wl-copy < "${file_path}" &>/dev/null & true
            _log "ACTION" "Screenshot copied to clipboard"
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🚨  OOM KERNEL HANDLER
# ──────────────────────────────────────────────────────────────────────────────

_handle_oom_killer() {
    _log "CRITICAL" "OOM killer triggered: ${SUMMARY}"
    _play_sound "error"

    _write_state "last_oom_event" "$(date +%s)"
    _increment_counter "oom_count"

    # Log memory snapshot
    {
        echo "$(date '+%Y-%m-%d %H:%M:%S') OOM EVENT:"
        echo "Summary: ${SUMMARY}"
        echo "Body: ${BODY}"
        echo "Memory info:"
        free -h 2>/dev/null
        echo "Top processes:"
        ps aux --sort=-%mem 2>/dev/null | head -20
    } >> "${ASH_LOG_DIR}/oom-events.log" 2>/dev/null || true
}

# ──────────────────────────────────────────────────────────────────────────────
# 🎯  MAIN DISPATCH ROUTER
# ──────────────────────────────────────────────────────────────────────────────

_dispatch() {
    local app="${APP,,}"      # lowercase
    local summary_lower="${SUMMARY,,}"
    local urgency_lower="${URGENCY,,}"

    _log "INFO" "Dispatching: app='${app}' urgency='${urgency_lower}'"

    # ── Battery ────────────────────────────────────────────────────────────
    if [[ "${app}" == "battery" ]]; then
        case "${summary_lower}" in
            *"critical"*|*"2%"*|*"3%"*|*"4%"*|*"5%"*)
                _handle_battery_critical ;;
            *"low"*|*"15%"*|*"20%"*)
                _handle_battery_low ;;
            *"charging"*|*"plugged"*)
                _handle_battery_charging ;;
            *"overheat"*|*"thermal"*)
                _handle_thermal_critical ;;
        esac
        return
    fi

    # ── Hardware / Temperature ─────────────────────────────────────────────
    if [[ "${app}" == "ash-hw" ]]; then
        case "${summary_lower}" in
            *"critical"*)
                _handle_thermal_critical ;;
            *"warning"*|*"warm"*)
                _handle_thermal_warning ;;
            *"disk error"*|*"smart"*"fail"*)
                _handle_smart_failure ;;
            *"disk full"*|*"no space"*)
                _handle_disk_critical ;;
            *"oom"*|*"memory"*"critical"*)
                _handle_oom_killer ;;
        esac
        return
    fi

    # ── Security ───────────────────────────────────────────────────────────
    if [[ "${app}" == "ash-security" || \
          "${app}" == "ash-firewall" ]]; then
        case "${summary_lower}" in
            *"breach"*|*"intrusion"*)
                _handle_security_breach ;;
            *"firewall"*)
                _handle_security_breach ;;
            *"auth"*"fail"*|*"authentication"*"failed"*)
                _handle_auth_failure ;;
        esac
        return
    fi

    if [[ "${app}" == "polkit"* || "${app}" == "sudo" ]]; then
        _handle_auth_failure
        return
    fi

    if [[ "${app}" == "sshd" ]] && \
       [[ "${summary_lower}" == *"failed"* ]]; then
        _handle_auth_failure
        return
    fi

    # ── VPN ────────────────────────────────────────────────────────────────
    if [[ "${app}" == "vpn" ]]; then
        case "${summary_lower}" in
            *"kill switch"*)
                _handle_vpn_kill_switch ;;
            *"server"*"down"*)
                _log "WARN" "VPN server down — recording event"
                _write_state "vpn_server_down" "$(date +%s)" ;;
        esac
        return
    fi

    # ── Network ────────────────────────────────────────────────────────────
    if [[ "${app}" == "network" || \
          "${app}" == "ash-net" ]]; then
        case "${summary_lower}" in
            *"no network"*|*"total loss"*)
                _handle_network_loss ;;
            *"dns"*"fail"*)
                _handle_dns_failure ;;
        esac
        return
    fi

    # ── Docker ─────────────────────────────────────────────────────────────
    if [[ "${app}" == "docker" || "${app}" == "podman" ]]; then
        case "${summary_lower}" in
            *"daemon"*"down"*|*"daemon"*"crash"*)
                _handle_docker_crash ;;
            *"oom"*|*"killed"*)
                _handle_docker_oom ;;
            *"crash"*"loop"*)
                _log "CRITICAL" "Container crash loop: ${BODY}"
                _play_sound "error" ;;
            *"vulnerability"*)
                _log "CRITICAL" "Docker vulnerability: ${BODY}"
                _play_sound "warning" ;;
        esac
        return
    fi

    # ── ASH Theme ──────────────────────────────────────────────────────────
    if [[ "${app}" == "ash-theme" ]]; then
        case "${summary_lower}" in
            *"error"*|*"corrupt"*)
                _handle_theme_error ;;
            *"applied"*)
                _handle_theme_applied ;;
        esac
        return
    fi

    # ── ASH Snapshot ───────────────────────────────────────────────────────
    if [[ "${app}" == "ash-snapshot" ]]; then
        case "${summary_lower}" in
            *"corrupt"*|*"invalid"*|*"tamper"*)
                _handle_snapshot_corrupt ;;
            *"failed"*)
                _handle_snapshot_failed ;;
        esac
        return
    fi

    # ── Home Assistant ─────────────────────────────────────────────────────
    if [[ "${app}" == "home-assistant" ]]; then
        case "${summary_lower}" in
            *"smoke"*|*"fire"*|*"co2"*|*"flood"*|*"intrusion"*)
                _handle_home_emergency ;;
        esac
        return
    fi

    # ── Systemd ────────────────────────────────────────────────────────────
    if [[ "${app}" == "systemd" ]]; then
        case "${summary_lower}" in
            *"failed"*)
                _handle_service_failed ;;
            *"core dump"*)
                _handle_core_dump ;;
        esac
        return
    fi

    # ── Screenshot ─────────────────────────────────────────────────────────
    if [[ "${app}" == "screenshot" ]]; then
        case "${summary_lower}" in
            *"saved"*)
                _handle_screenshot_saved ;;
        esac
        return
    fi

    # ── Kernel / OOM ───────────────────────────────────────────────────────
    if [[ "${app}" == "kernel" ]]; then
        if [[ "${summary_lower}" == *"oom"* ]]; then
            _handle_oom_killer
        fi
        return
    fi

    # ── Generic Critical Fallback ──────────────────────────────────────────
    if [[ "${urgency_lower}" == "critical" ]]; then
        _log "WARN" "Unhandled critical notification — generic handler"
        _play_sound "notification-critical"
        _write_state "last_critical_notif" \
            "$(date +%s):${APP}:${SUMMARY}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🚀  MAIN ENTRY POINT
# ──────────────────────────────────────────────────────────────────────────────

main() {
    _ensure_dirs
    _log_event
    _dispatch

    # Rotate log if too large (> 10MB)
    if [[ -f "${DUNST_LOG}" ]]; then
        local log_size
        log_size="$(stat -c%s "${DUNST_LOG}" 2>/dev/null || echo 0)"
        if (( log_size > 10485760 )); then
            mv "${DUNST_LOG}" "${DUNST_LOG}.1"
            _log "INFO" "Log rotated (was > 10MB)"
        fi
    fi
}

main "$@"