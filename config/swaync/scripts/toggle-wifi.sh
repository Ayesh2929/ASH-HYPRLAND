#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — SwayNC Ultra Wi-Fi Toggle Script                ║
# ║  Premium wireless controller with network scanner, hotspot management,      ║
# ║  DNS switching, traffic monitoring, VPN awareness, and QR code sharing      ║
# ║                                                                              ║
# ║  Author  : ash-dotfiles                                                      ║
# ║  Version : 5.0.0                                                             ║
# ║  License : MIT                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONSTANTS & PATHS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly SCRIPT_NAME="ash-wifi-toggle"
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"

# State files
readonly WIFI_STATE_FILE="${CACHE_DIR}/wifi.state"
readonly WIFI_LOCK_FILE="${RUNTIME_DIR}/wifi.lock"
readonly WIFI_LOG_FILE="${CACHE_DIR}/logs/wifi.log"
readonly WIFI_HISTORY_FILE="${DATA_DIR}/wifi-history.json"
readonly WIFI_STATS_FILE="${CACHE_DIR}/wifi-stats.json"
readonly WIFI_DNS_FILE="${CONFIG_DIR}/wifi-dns.conf"
readonly WIFI_PROFILES_FILE="${CONFIG_DIR}/wifi-profiles.json"
readonly NETWORK_CACHE_FILE="${CACHE_DIR}/networks.json"
readonly HOTSPOT_STATE_FILE="${CACHE_DIR}/hotspot.state"
readonly TRAFFIC_FILE="${CACHE_DIR}/wifi-traffic.json"

# Sound files
readonly SOUND_CONNECT="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/network-connect.ogg"
readonly SOUND_DISCONNECT="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/network-disconnect.ogg"
readonly SOUND_ERROR="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/error.ogg"

# Icons
readonly ICON_WIFI_ON="󰤨"
readonly ICON_WIFI_OFF="󰤭"
readonly ICON_WIFI_SCANNING="󰤫"
readonly ICON_WIFI_CONNECTED="󰤨"
readonly ICON_WIFI_WEAK="󰤟"
readonly ICON_WIFI_FAIR="󰤢"
readonly ICON_WIFI_GOOD="󰤥"
readonly ICON_HOTSPOT="󱛁"
readonly ICON_SECURED="󰌾"
readonly ICON_OPEN="󰦻"
readonly ICON_QR="󰄌"
readonly ICON_DNS="󰖟"
readonly ICON_SPEED="󰓅"
readonly ICON_ERROR="󰅙"
readonly ICON_SUCCESS="󰄬"
readonly ICON_INFO="󰋼"
readonly ICON_ASH="󱎫"
readonly ICON_VPN="󰌾"

# Signal thresholds
readonly SIG_EXCELLENT=75
readonly SIG_GOOD=55
readonly SIG_FAIR=30
readonly SIG_WEAK=1

# Colors
readonly CLR_RESET='\033[0m'
readonly CLR_BOLD='\033[1m'
readonly CLR_RED='\033[0;31m'
readonly CLR_GREEN='\033[0;32m'
readonly CLR_YELLOW='\033[0;33m'
readonly CLR_BLUE='\033[0;34m'
readonly CLR_MAGENTA='\033[0;35m'
readonly CLR_CYAN='\033[0;36m'
readonly CLR_WHITE='\033[0;37m'
readonly CLR_GRAY='\033[0;90m'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR" "$STATE_DIR" "$DATA_DIR"
        "$CONFIG_DIR" "$RUNTIME_DIR"
        "${CACHE_DIR}/logs"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOGGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "[$timestamp] [$level] $message" >> "$WIFI_LOG_FILE" 2>/dev/null || true

    # Log rotation: 512KB
    if [[ -f "$WIFI_LOG_FILE" ]]; then
        local sz
        sz="$(stat -c%s "$WIFI_LOG_FILE" 2>/dev/null || echo 0)"
        (( sz > 524288 )) && mv "$WIFI_LOG_FILE" "${WIFI_LOG_FILE}.old"
    fi

    [[ ! -t 2 ]] && return 0
    case "$level" in
        ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[ERROR]${CLR_RESET} $message" >&2 ;;
        WARN)    echo -e "${CLR_YELLOW}[WARN]${CLR_RESET}  $message" >&2 ;;
        INFO)    echo -e "${CLR_CYAN}[INFO]${CLR_RESET}  $message" >&2 ;;
        DEBUG)   [[ "${ASH_DEBUG:-0}" == "1" ]] && \
                 echo -e "${CLR_GRAY}[DEBUG] $message${CLR_RESET}" >&2 ;;
        SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[OK]${CLR_RESET}   $message" >&2 ;;
    esac
}

log_info()    { _log "INFO"    "$*"; }
log_warn()    { _log "WARN"    "$*"; }
log_error()   { _log "ERROR"   "$*"; }
log_debug()   { _log "DEBUG"   "$*"; }
log_success() { _log "SUCCESS" "$*"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOCK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_acquire_lock() {
    local max_wait=5 waited=0
    while [[ -f "$WIFI_LOCK_FILE" ]]; do
        local pid
        pid="$(cat "$WIFI_LOCK_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$WIFI_LOCK_FILE"; break
        fi
        (( waited >= max_wait )) && return 1
        sleep 0.2; (( waited++ )) || true
    done
    echo "$$" > "$WIFI_LOCK_FILE"
}

_release_lock() { rm -f "$WIFI_LOCK_FILE"; }

trap '_release_lock' EXIT INT TERM

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEPENDENCY CHECKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_deps() {
    local required=("nmcli" "notify-send" "jq")
    local missing=()

    for cmd in "${required[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "Missing required deps: ${missing[*]}"
        notify-send -u critical "${ICON_ERROR} ASH WiFi" \
            "Missing deps: ${missing[*]}" 2>/dev/null || true
        exit 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SOUND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_play_sound() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0
    if command -v pw-play &>/dev/null; then
        pw-play --volume=0.4 "$file" &>/dev/null &
    elif command -v paplay &>/dev/null; then
        paplay --volume=26214 "$file" &>/dev/null &
    elif command -v ogg123 &>/dev/null; then
        ogg123 -q "$file" &>/dev/null &
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NOTIFICATION ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_notify() {
    local title="$1"
    local body="${2:-}"
    local urgency="${3:-normal}"
    local expire="${4:-4000}"

    notify-send \
        --urgency="$urgency" \
        --expire-time="$expire" \
        --app-name="ASH WiFi" \
        "$title" "$body" 2>/dev/null || true
}

_notify_connect() {
    local ssid="$1"
    local signal="${2:-?}"
    local security="${3:-}"
    local freq="${4:-}"

    local icon
    icon="$(_signal_icon "$signal")"

    local body="${icon}  ${ssid}"
    [[ -n "$freq" ]]     && body+="  •  ${freq} GHz"
    [[ -n "$security" ]] && body+="  •  ${ICON_SECURED} ${security}"
    body+="  •  ${signal}%"

    _notify \
        "${ICON_WIFI_CONNECTED}  Connected" \
        "$body" \
        "low" \
        "4000"

    _play_sound "$SOUND_CONNECT"
}

_notify_disconnect() {
    local ssid="${1:-Unknown}"

    _notify \
        "${ICON_WIFI_OFF}  Disconnected" \
        "Disconnected from ${ssid}" \
        "normal" \
        "3500"

    _play_sound "$SOUND_DISCONNECT"
}

_notify_wifi_on() {
    _notify \
        "${ICON_WIFI_ON}  Wi-Fi Enabled" \
        "Scanning for networks…" \
        "low" \
        "3000"
}

_notify_wifi_off() {
    _notify \
        "${ICON_WIFI_OFF}  Wi-Fi Disabled" \
        "Wireless adapter turned off" \
        "low" \
        "3000"
}

_notify_hotspot() {
    local state="$1"
    local ssid="${2:-}"
    local password="${3:-}"

    if [[ "$state" == "on" ]]; then
        local body="${ICON_HOTSPOT}  SSID: ${ssid}"
        [[ -n "$password" ]] && body+="\n${ICON_SECURED}  Pass: ${password}"
        _notify \
            "${ICON_HOTSPOT}  Hotspot Active" \
            "$(echo -e "$body")" \
            "normal" \
            "8000"
    else
        _notify \
            "${ICON_HOTSPOT}  Hotspot Stopped" \
            "Mobile hotspot deactivated" \
            "low" \
            "3000"
    fi
}

_notify_error() {
    local msg="$1"
    _notify \
        "${ICON_ERROR}  WiFi Error" \
        "$msg" \
        "critical" \
        "6000"
    _play_sound "$SOUND_ERROR"
}

_notify_captive_portal() {
    notify-send \
        --urgency=normal \
        --expire-time=0 \
        --app-name="ASH WiFi" \
        --action="Open=xdg-open http://captive.apple.com" \
        "${ICON_INFO}  Sign-in Required" \
        "This network requires authentication" \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NETWORK INTERFACE DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_wifi_device() {
    # Returns active wifi device name (e.g., wlan0, wlp3s0)
    nmcli -t -f DEVICE,TYPE dev 2>/dev/null \
        | grep ':wifi$' \
        | head -1 \
        | cut -d: -f1
}

_get_wifi_state() {
    # Returns: on | off | disabled
    local radio_state
    radio_state="$(nmcli radio wifi 2>/dev/null || echo 'disabled')"

    case "$radio_state" in
        enabled)  echo "on"  ;;
        disabled) echo "off" ;;
        *)        echo "off" ;;
    esac
}

_get_connection_state() {
    # Returns: connected:<ssid> | disconnected | connecting | unavailable
    local device
    device="$(_get_wifi_device)"
    [[ -z "$device" ]] && echo "unavailable" && return

    local state
    state="$(nmcli -t -f DEVICE,STATE dev 2>/dev/null \
        | grep "^${device}:" \
        | cut -d: -f2 || echo 'unknown')"

    case "$state" in
        connected)
            local ssid
            ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null \
                | grep '^yes:' \
                | cut -d: -f2 | head -1 || echo '')"
            echo "connected:${ssid}"
            ;;
        connecting*|config|ip-config|ip-check|secondaries)
            echo "connecting"
            ;;
        disconnected|unavailable|unmanaged)
            echo "disconnected"
            ;;
        *)
            echo "disconnected"
            ;;
    esac
}

_get_signal_strength() {
    local signal
    signal="$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null \
        | grep '^yes:' \
        | cut -d: -f2 \
        | head -1 || echo '0')"
    echo "${signal:-0}"
}

_get_active_ssid() {
    nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null \
        | grep '^yes:' \
        | cut -d: -f2 \
        | head -1 || echo ''
}

_get_active_freq() {
    local freq
    freq="$(nmcli -t -f ACTIVE,FREQ dev wifi 2>/dev/null \
        | grep '^yes:' \
        | cut -d: -f2 \
        | head -1 || echo '')"

    # Convert MHz to GHz band
    if [[ "$freq" =~ ^[0-9]+\ MHz$ ]]; then
        local mhz
        mhz="${freq%% MHz}"
        if (( mhz >= 5000 )); then
            echo "5"
        elif (( mhz >= 6000 )); then
            echo "6"
        else
            echo "2.4"
        fi
    else
        echo "?"
    fi
}

_get_active_security() {
    nmcli -t -f ACTIVE,SECURITY dev wifi 2>/dev/null \
        | grep '^yes:' \
        | cut -d: -f2 \
        | head -1 || echo ''
}

_get_active_bssid() {
    nmcli -t -f ACTIVE,BSSID dev wifi 2>/dev/null \
        | grep '^yes:' \
        | cut -d: -f2- \
        | head -1 || echo ''
}

_get_ip_address() {
    local device
    device="$(_get_wifi_device)"
    [[ -z "$device" ]] && return
    ip -4 addr show "$device" 2>/dev/null \
        | grep 'inet ' \
        | awk '{print $2}' \
        | head -1 || echo ''
}

_get_gateway() {
    ip route 2>/dev/null \
        | grep '^default' \
        | awk '{print $3}' \
        | head -1 || echo ''
}

_get_dns_servers() {
    local device
    device="$(_get_wifi_device)"
    resolvectl status "$device" 2>/dev/null \
        | grep 'DNS Servers' \
        | awk '{$1=$2=""; print $0}' \
        | xargs || echo ''
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SIGNAL UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_icon() {
    local signal="${1:-0}"
    if   (( signal >= SIG_EXCELLENT )); then echo "${ICON_WIFI_CONNECTED}"
    elif (( signal >= SIG_GOOD      )); then echo "${ICON_WIFI_GOOD}"
    elif (( signal >= SIG_FAIR      )); then echo "${ICON_WIFI_FAIR}"
    elif (( signal >= SIG_WEAK      )); then echo "${ICON_WIFI_WEAK}"
    else                                    echo "󰤯"
    fi
}

_signal_quality() {
    local signal="${1:-0}"
    if   (( signal >= SIG_EXCELLENT )); then echo "Excellent"
    elif (( signal >= SIG_GOOD      )); then echo "Good"
    elif (( signal >= SIG_FAIR      )); then echo "Fair"
    elif (( signal >= SIG_WEAK      )); then echo "Weak"
    else                                    echo "None"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAYBAR SIGNAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_waybar() {
    pkill -SIGRTMIN+5 waybar 2>/dev/null || true
    log_debug "Waybar signaled (SIGRTMIN+5)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANALYTICS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_record_event() {
    local event="$1"
    local metadata="${2:-{}}"
    local timestamp
    timestamp="$(date -Iseconds)"

    [[ ! -f "$WIFI_HISTORY_FILE" ]] && \
        echo '{"events":[]}' > "$WIFI_HISTORY_FILE"

    local updated
    updated="$(jq \
        --arg  event "$event" \
        --arg  ts    "$timestamp" \
        --argjson meta "$metadata" \
        '.events += [{"event":$event,"timestamp":$ts,"metadata":$meta}] |
         .events = .events[-500:]' \
        "$WIFI_HISTORY_FILE" 2>/dev/null)" || return 0

    echo "$updated" > "$WIFI_HISTORY_FILE"
}

_update_traffic_baseline() {
    local device
    device="$(_get_wifi_device)"
    [[ -z "$device" ]] && return

    local rx tx
    rx="$(cat "/sys/class/net/${device}/statistics/rx_bytes" 2>/dev/null || echo 0)"
    tx="$(cat "/sys/class/net/${device}/statistics/tx_bytes" 2>/dev/null || echo 0)"

    jq -n \
        --argjson rx "$rx" \
        --argjson tx "$tx" \
        --arg ts "$(date -Iseconds)" \
        '{"rx_bytes":$rx,"tx_bytes":$tx,"timestamp":$ts}' \
        > "$TRAFFIC_FILE"
}

_format_bytes() {
    local bytes="$1"
    if (( bytes >= 1073741824 )); then
        printf "%.1f GB" "$(echo "scale=1; $bytes/1073741824" | bc)"
    elif (( bytes >= 1048576 )); then
        printf "%.1f MB" "$(echo "scale=1; $bytes/1048576" | bc)"
    elif (( bytes >= 1024 )); then
        printf "%.1f KB" "$(echo "scale=1; $bytes/1024" | bc)"
    else
        printf "%d B" "$bytes"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CAPTIVE PORTAL DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_captive_portal() {
    # Quick check against a known endpoint
    local test_urls=(
        "http://detectportal.firefox.com/canonical.html"
        "http://connectivity-check.ubuntu.com"
        "http://www.gstatic.com/generate_204"
    )

    for url in "${test_urls[@]}"; do
        local http_code
        http_code="$(curl -s -o /dev/null -w '%{http_code}' \
            --max-time 3 --connect-timeout 2 "$url" 2>/dev/null || echo '0')"

        case "$http_code" in
            200|204) return 1 ;;   # No captive portal
            301|302|200)           # Possible redirect = captive portal
                if [[ "$http_code" == "200" ]]; then
                    local content_len
                    content_len="$(curl -s --max-time 3 "$url" 2>/dev/null | wc -c)"
                    (( content_len > 50 )) && return 0
                fi
                return 0
                ;;
        esac
    done
    return 1
}

_check_internet() {
    # Returns 0 if internet is reachable
    curl -s --max-time 3 --connect-timeout 2 \
        -o /dev/null "https://1.1.1.1" &>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WIFI ENABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wifi_enable() {
    local notify=true
    local auto_connect=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-notify)    notify=false     ;;
            --no-auto)      auto_connect=false ;;
        esac
        shift
    done

    log_info "Enabling Wi-Fi…"

    nmcli radio wifi on 2>/dev/null || {
        log_error "nmcli radio wifi on — failed"
        _notify_error "Failed to enable Wi-Fi"
        return 1
    }

    echo "on" > "$WIFI_STATE_FILE"
    _signal_waybar
    _record_event "wifi_on" "{}"

    [[ "$notify" == "true" ]] && _notify_wifi_on

    # Wait for adapter ready then auto-reconnect
    if [[ "$auto_connect" == "true" ]]; then
        (
            sleep 2
            local conn_state
            conn_state="$(_get_connection_state)"
            if [[ "$conn_state" == "disconnected" ]]; then
                log_debug "Auto-connecting to last known network…"
                nmcli dev wifi connect \
                    "$(nmcli -t -f NAME,TYPE con show \
                        | grep ':802-11-wireless' \
                        | head -1 \
                        | cut -d: -f1)" \
                    &>/dev/null || true
            fi
        ) &
    fi

    log_success "Wi-Fi enabled"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WIFI DISABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wifi_disable() {
    local notify=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-notify) notify=false ;;
        esac
        shift
    done

    log_info "Disabling Wi-Fi…"

    # Get current SSID for disconnect notification
    local current_ssid
    current_ssid="$(_get_active_ssid)"

    # Stop hotspot if running
    if [[ -f "$HOTSPOT_STATE_FILE" ]] && \
       [[ "$(cat "$HOTSPOT_STATE_FILE" 2>/dev/null)" == "on" ]]; then
        _hotspot_stop --silent
    fi

    nmcli radio wifi off 2>/dev/null || {
        log_error "nmcli radio wifi off — failed"
        _notify_error "Failed to disable Wi-Fi"
        return 1
    }

    echo "off" > "$WIFI_STATE_FILE"
    _signal_waybar
    _record_event "wifi_off" "{\"ssid\": \"$current_ssid\"}"

    if [[ "$notify" == "true" ]]; then
        if [[ -n "$current_ssid" ]]; then
            _notify_disconnect "$current_ssid"
        else
            _notify_wifi_off
        fi
    fi

    log_success "Wi-Fi disabled"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONNECT TO NETWORK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wifi_connect() {
    local ssid="$1"
    local password="${2:-}"
    local hidden="${3:-false}"
    local notify=true

    [[ -z "$ssid" ]] && {
        log_error "SSID required for connect"
        return 1
    }

    log_info "Connecting to: $ssid"

    _notify \
        "${ICON_WIFI_SCANNING}  Connecting…" \
        "Connecting to ${ssid}" \
        "low" "2000"

    local connect_args=()
    [[ "$hidden" == "true" ]] && connect_args+=(hidden yes)

    if [[ -n "$password" ]]; then
        nmcli dev wifi connect "$ssid" \
            password "$password" \
            "${connect_args[@]}" &>/dev/null
    else
        nmcli dev wifi connect "$ssid" \
            "${connect_args[@]}" &>/dev/null
    fi

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        # Wait for IP assignment
        local retries=10
        while (( retries-- > 0 )); do
            local ip
            ip="$(_get_ip_address)"
            [[ -n "$ip" ]] && break
            sleep 1
        done

        local signal freq security
        signal="$(_get_signal_strength)"
        freq="$(_get_active_freq)"
        security="$(_get_active_security)"

        _record_event "connected" "$(jq -n \
            --arg ssid "$ssid" \
            --argjson sig "$signal" \
            --arg freq "$freq" \
            '{
                "ssid":     $ssid,
                "signal":   $sig,
                "frequency":$freq
            }')"

        _update_traffic_baseline
        _signal_waybar
        _notify_connect "$ssid" "$signal" "$security" "$freq"

        # Run hook
        local hook="${CONFIG_DIR}/hooks/on-network-connect.sh"
        [[ -f "$hook" && -x "$hook" ]] && \
            WIFI_SSID="$ssid" WIFI_SIGNAL="$signal" "$hook" & true

        # Check for captive portal in background
        (
            sleep 3
            if _check_captive_portal; then
                log_warn "Captive portal detected on $ssid"
                _notify_captive_portal
            fi
        ) &

        log_success "Connected to $ssid (signal=${signal}% freq=${freq}GHz)"
        return 0
    else
        log_error "Failed to connect to $ssid (exit=$exit_code)"
        _notify_error "Failed to connect to ${ssid}"
        _record_event "connect_failed" \
            "{\"ssid\": \"$ssid\", \"exit_code\": $exit_code}"
        return 1
    fi
}

_wifi_disconnect() {
    local ssid
    ssid="$(_get_active_ssid)"

    log_info "Disconnecting from: ${ssid:-current network}"

    local device
    device="$(_get_wifi_device)"

    nmcli dev disconnect "$device" &>/dev/null || {
        log_error "Disconnect failed"
        return 1
    }

    _record_event "disconnected" "{\"ssid\": \"$ssid\"}"
    _signal_waybar
    _notify_disconnect "$ssid"
    log_success "Disconnected from $ssid"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NETWORK SCANNER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_wifi_scan() {
    local rescan="${1:-false}"
    local format="${2:-json}"
    local filter="${3:-}"

    log_info "Scanning networks (rescan=$rescan)…"

    local scan_flag=""
    [[ "$rescan" == "true" ]] && scan_flag="--rescan yes"

    # Scan with full field set
    local raw_output
    raw_output="$(nmcli -t \
        -f IN-USE,SSID,SIGNAL,SECURITY,FREQ,BSSID,RATE \
        dev wifi list $scan_flag 2>/dev/null)" || {
        log_error "Network scan failed"
        return 1
    }

    # Build JSON array
    local networks_json='[]'
    local active_ssid
    active_ssid="$(_get_active_ssid)"

    while IFS=: read -r in_use ssid signal security freq bssid rate; do
        # Skip empty SSIDs
        [[ -z "$ssid" ]] && continue

        # Apply filter
        [[ -n "$filter" ]] && \
            [[ "$ssid" != *"$filter"* ]] && continue

        local is_connected=false
        [[ "$in_use" == "*" ]] && is_connected=true

        local is_secured=true
        [[ -z "$security" || "$security" == "--" ]] && is_secured=false

        local freq_band="2.4"
        [[ "$freq" =~ ^5[0-9]{3} ]] && freq_band="5"
        [[ "$freq" =~ ^6[0-9]{3} ]] && freq_band="6"

        local sig_icon
        sig_icon="$(_signal_icon "${signal:-0}")"
        local sig_quality
        sig_quality="$(_signal_quality "${signal:-0}")"

        # Check if saved
        local is_saved=false
        nmcli -t -f NAME con show 2>/dev/null | \
            grep -qF "$ssid" && is_saved=true

        networks_json="$(echo "$networks_json" | jq \
            --arg     ssid      "$ssid" \
            --argjson signal    "${signal:-0}" \
            --arg     security  "${security:---}" \
            --arg     freq      "$freq_band" \
            --arg     bssid     "$bssid" \
            --arg     rate      "${rate:---}" \
            --argjson connected "$is_connected" \
            --argjson secured   "$is_secured" \
            --argjson saved     "$is_saved" \
            --arg     icon      "$sig_icon" \
            --arg     quality   "$sig_quality" \
            '. += [{
                "ssid":      $ssid,
                "signal":    $signal,
                "security":  $security,
                "frequency": $freq,
                "bssid":     $bssid,
                "rate":      $rate,
                "connected": $connected,
                "secured":   $secured,
                "saved":     $saved,
                "icon":      $icon,
                "quality":   $quality
            }]' 2>/dev/null)"
    done <<< "$raw_output"

    # Sort by signal strength desc, connected first
    networks_json="$(echo "$networks_json" | jq \
        'sort_by(-(.signal)) |
         sort_by(if .connected then 0 else 1 end)' \
        2>/dev/null)"

    # Cache the scan results
    jq -n \
        --argjson networks "$networks_json" \
        --arg ts "$(date -Iseconds)" \
        '{"networks":$networks,"scanned_at":$ts}' \
        > "$NETWORK_CACHE_FILE"

    case "$format" in
        json)
            echo "$networks_json"
            ;;
        table|human)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_WIFI_SCANNING}  Available Networks${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            printf "${CLR_BOLD}%-3s %-32s %-5s %-6s %-8s %-6s${CLR_RESET}\n" \
                "" "SSID" "SIG%" "FREQ" "SECURITY" "SAVED"
            echo -e "${CLR_GRAY}──────────────────────────────────────────────────${CLR_RESET}"

            echo "$networks_json" | jq -r '.[] |
                [.icon, .ssid, (.signal|tostring)+"%",
                 .frequency+"G", .security,
                 (if .saved then "✓" else "" end)] |
                @tsv' 2>/dev/null | \
            while IFS=$'\t' read -r icon ssid sig freq sec saved; do
                local color=""
                [[ "$saved" == "✓" ]] && color="$CLR_GREEN"
                printf "${color}%-3s %-32s %-5s %-6s %-8s %-6s${CLR_RESET}\n" \
                    "$icon" "$ssid" "$sig" "$freq" "$sec" "$saved"
            done
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
        count)
            echo "$networks_json" | jq 'length' 2>/dev/null
            ;;
    esac

    log_debug "Scan complete"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HOTSPOT MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hotspot_start() {
    local ssid="${1:-$(hostname)-Hotspot}"
    local password="${2:-}"
    local band="${3:-bg}"   # bg = 2.4GHz, a = 5GHz
    local silent=false

    [[ "$1" == "--silent" ]] && { silent=true; shift; }

    log_info "Starting hotspot: $ssid"

    # Generate password if not provided
    if [[ -z "$password" ]]; then
        password="$(tr -dc 'A-Za-z0-9!@#$' < /dev/urandom | head -c 12)"
    fi

    # Start hotspot via nmcli
    nmcli dev wifi hotspot \
        ssid "$ssid" \
        password "$password" \
        band "$band" \
        &>/dev/null || {
        log_error "Failed to start hotspot"
        _notify_error "Hotspot failed to start"
        return 1
    }

    echo "on" > "$HOTSPOT_STATE_FILE"
    jq -n \
        --arg ssid "$ssid" \
        --arg pass "$password" \
        --arg band "$band" \
        --arg ts "$(date -Iseconds)" \
        '{"ssid":$ssid,"password":$pass,"band":$band,"started_at":$ts}' \
        > "${CACHE_DIR}/hotspot-info.json"

    _signal_waybar
    _record_event "hotspot_on" "{\"ssid\":\"$ssid\"}"

    [[ "$silent" == "false" ]] && \
        _notify_hotspot "on" "$ssid" "$password"

    log_success "Hotspot active: $ssid"

    # Generate QR code in background
    _hotspot_qr "$ssid" "$password" &

    echo "ssid=$ssid password=$password"
}

_hotspot_stop() {
    local silent=false
    [[ "${1:-}" == "--silent" ]] && silent=true

    log_info "Stopping hotspot…"

    nmcli con delete "$(nmcli -t -f NAME con show --active \
        | grep -i hotspot | head -1 | cut -d: -f1)" \
        &>/dev/null || true

    echo "off" > "$HOTSPOT_STATE_FILE"
    rm -f "${CACHE_DIR}/hotspot-info.json"

    _signal_waybar
    _record_event "hotspot_off" "{}"

    [[ "$silent" == "false" ]] && _notify_hotspot "off"
    log_success "Hotspot stopped"
}

_hotspot_status() {
    if [[ -f "$HOTSPOT_STATE_FILE" ]] && \
       [[ "$(cat "$HOTSPOT_STATE_FILE" 2>/dev/null)" == "on" ]]; then
        local info
        info="$(cat "${CACHE_DIR}/hotspot-info.json" 2>/dev/null || echo '{}')"
        echo "active"
        echo "$info"
    else
        echo "inactive"
    fi
}

_hotspot_qr() {
    local ssid="$1"
    local password="${2:-}"

    command -v qrencode &>/dev/null || return 0

    local wifi_string="WIFI:T:WPA;S:${ssid};P:${password};;"
    local qr_file="${CACHE_DIR}/hotspot-qr.png"

    qrencode -o "$qr_file" -s 8 -l H "$wifi_string" 2>/dev/null || return 0

    # Display QR in notification if possible
    notify-send \
        --urgency=normal \
        --expire-time=30000 \
        --icon="$qr_file" \
        "${ICON_QR}  Hotspot QR Code" \
        "Scan to connect to ${ssid}" \
        2>/dev/null || true

    log_debug "QR code generated: $qr_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DNS SWITCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -A DNS_PRESETS=(
    ["cloudflare"]="1.1.1.1 1.0.0.1"
    ["cloudflare-doh"]="1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com"
    ["google"]="8.8.8.8 8.8.4.4"
    ["quad9"]="9.9.9.9 149.112.112.112"
    ["quad9-secure"]="9.9.9.11 149.112.112.11"
    ["opendns"]="208.67.222.222 208.67.220.220"
    ["adguard"]="94.140.14.14 94.140.15.15"
    ["nextdns"]="45.90.28.0 45.90.30.0"
    ["auto"]="auto"
)

_dns_switch() {
    local preset="${1:-cloudflare}"
    local connection
    connection="$(nmcli -t -f NAME,TYPE con show --active \
        | grep ':802-11-wireless' \
        | cut -d: -f1 | head -1)"

    [[ -z "$connection" ]] && {
        log_error "No active Wi-Fi connection"
        return 1
    }

    if [[ "$preset" == "auto" ]]; then
        nmcli con mod "$connection" \
            ipv4.ignore-auto-dns no \
            ipv4.dns "" \
            &>/dev/null
        log_success "DNS reset to auto (DHCP)"
    elif [[ -n "${DNS_PRESETS[$preset]:-}" ]]; then
        local servers="${DNS_PRESETS[$preset]}"
        nmcli con mod "$connection" \
            ipv4.ignore-auto-dns yes \
            ipv4.dns "$servers" \
            &>/dev/null
        log_success "DNS set to $preset: $servers"
    else
        # Treat as raw DNS address
        nmcli con mod "$connection" \
            ipv4.ignore-auto-dns yes \
            ipv4.dns "$preset" \
            &>/dev/null
        log_success "DNS set to custom: $preset"
    fi

    # Apply changes
    nmcli con up "$connection" &>/dev/null || true

    _notify \
        "${ICON_DNS}  DNS Changed" \
        "DNS set to: $preset" \
        "low" "3000"

    echo "dns_preset=$preset"
}

_dns_test() {
    local servers=("1.1.1.1" "8.8.8.8" "9.9.9.9")
    local test_domain="example.com"

    echo -e "${CLR_BOLD}${ICON_DNS}  DNS Speed Test${CLR_RESET}"
    echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

    for server in "${servers[@]}"; do
        local start_ms end_ms latency
        start_ms="$(date +%s%N)"
        dig "@${server}" "$test_domain" +time=3 +tries=1 \
            &>/dev/null
        end_ms="$(date +%s%N)"
        latency=$(( (end_ms - start_ms) / 1000000 ))

        local color="$CLR_GREEN"
        (( latency > 100 )) && color="$CLR_YELLOW"
        (( latency > 300 )) && color="$CLR_RED"

        printf "  %-18s ${color}%4dms${CLR_RESET}\n" "$server" "$latency"
    done
    echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PING & LATENCY TEST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ping_test() {
    local host="${1:-8.8.8.8}"
    local count="${2:-5}"

    log_info "Ping test to $host ($count packets)"

    local result
    result="$(ping -c "$count" -W 3 "$host" 2>/dev/null)"

    if [[ $? -eq 0 ]]; then
        local avg
        avg="$(echo "$result" | tail -1 | awk -F/ '{printf "%.0f", $5}')"
        local packet_loss
        packet_loss="$(echo "$result" | \
            grep 'packet loss' | \
            awk '{print $6}')"

        echo -e "${CLR_GREEN}${ICON_SUCCESS}  Ping to $host${CLR_RESET}"
        echo -e "  Average: ${CLR_BOLD}${avg}ms${CLR_RESET}"
        echo -e "  Loss:    ${CLR_BOLD}${packet_loss}${CLR_RESET}"

        _notify \
            "${ICON_INFO}  Ping: ${host}" \
            "Avg: ${avg}ms  •  Loss: ${packet_loss}" \
            "low" "4000"
    else
        echo -e "${CLR_RED}${ICON_ERROR}  Ping failed: $host${CLR_RESET}"
        _notify_error "Ping failed: $host"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATUS DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_status() {
    local format="${1:-human}"

    local wifi_state
    wifi_state="$(_get_wifi_state)"
    local conn_state
    conn_state="$(_get_connection_state)"
    local ssid="" signal=0 freq="" security="" ip="" gateway=""

    if [[ "$conn_state" == connected:* ]]; then
        ssid="${conn_state#connected:}"
        signal="$(_get_signal_strength)"
        freq="$(_get_active_freq)"
        security="$(_get_active_security)"
        ip="$(_get_ip_address)"
        gateway="$(_get_gateway)"
    fi

    local sig_icon
    sig_icon="$(_signal_icon "$signal")"
    local sig_quality
    sig_quality="$(_signal_quality "$signal")"

    local is_connected=false
    [[ "$conn_state" == connected:* ]] && is_connected=true

    local hotspot_active=false
    [[ -f "$HOTSPOT_STATE_FILE" ]] && \
        [[ "$(cat "$HOTSPOT_STATE_FILE")" == "on" ]] && \
        hotspot_active=true

    case "$format" in
        json)
            jq -n \
                --arg  state     "$wifi_state" \
                --arg  conn      "$conn_state" \
                --argjson online "$is_connected" \
                --arg  ssid      "$ssid" \
                --argjson sig    "$signal" \
                --arg  freq      "$freq" \
                --arg  security  "$security" \
                --arg  ip        "$ip" \
                --arg  gateway   "$gateway" \
                --arg  sig_icon  "$sig_icon" \
                --arg  sig_qual  "$sig_quality" \
                --argjson hotspot "$hotspot_active" \
                '{
                    "enabled":    ($state == "on"),
                    "state":      $state,
                    "connected":  $online,
                    "ssid":       $ssid,
                    "signal":     $sig,
                    "signal_icon":$sig_icon,
                    "quality":    $sig_qual,
                    "frequency":  $freq,
                    "security":   $security,
                    "ip_address": $ip,
                    "gateway":    $gateway,
                    "hotspot":    $hotspot
                }'
            ;;

        waybar)
            local text tooltip class

            if [[ "$wifi_state" == "off" ]]; then
                text="${ICON_WIFI_OFF}"
                tooltip="Wi-Fi disabled"
                class="wifi-off"
            elif [[ "$is_connected" == "true" ]]; then
                text="${sig_icon}  ${ssid}"
                tooltip="${ssid}  •  ${signal}%  •  ${freq}GHz\n${ip}"
                class="wifi-connected wifi-signal-$(
                    if   (( signal >= SIG_EXCELLENT )); then echo 4
                    elif (( signal >= SIG_GOOD      )); then echo 3
                    elif (( signal >= SIG_FAIR      )); then echo 2
                    else                                    echo 1
                    fi
                )"
            else
                text="${ICON_WIFI_OFF}"
                tooltip="Wi-Fi on — not connected"
                class="wifi-disconnected"
            fi

            [[ "$hotspot_active" == "true" ]] && {
                text="${ICON_HOTSPOT}  Hotspot"
                class="wifi-hotspot"
            }

            jq -n \
                --arg text    "$text" \
                --arg tooltip "$(echo -e "$tooltip")" \
                --arg class   "$class" \
                '{"text":$text,"tooltip":$tooltip,"class":$class}'
            ;;

        short)
            if [[ "$wifi_state" == "off" ]]; then
                echo "${ICON_WIFI_OFF}  Off"
            elif [[ "$is_connected" == "true" ]]; then
                echo "${sig_icon}  ${ssid}  •  ${signal}%"
            else
                echo "${ICON_WIFI_OFF}  Disconnected"
            fi
            ;;

        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH Wi-Fi Status${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            if [[ "$wifi_state" == "on" ]]; then
                echo -e "  Radio    : ${CLR_GREEN}${CLR_BOLD}${ICON_WIFI_ON}  Enabled${CLR_RESET}"
            else
                echo -e "  Radio    : ${CLR_GRAY}${ICON_WIFI_OFF}  Disabled${CLR_RESET}"
            fi

            if [[ "$is_connected" == "true" ]]; then
                echo -e "  SSID     : ${CLR_WHITE}${CLR_BOLD}${ssid}${CLR_RESET}"
                echo -e "  Signal   : ${CLR_GREEN}${sig_icon} ${signal}% (${sig_quality})${CLR_RESET}"
                echo -e "  Band     : ${CLR_CYAN}${freq} GHz${CLR_RESET}"
                [[ -n "$security" ]] && \
                    echo -e "  Security : ${CLR_YELLOW}${ICON_SECURED} ${security}${CLR_RESET}"
                [[ -n "$ip" ]] && \
                    echo -e "  IP       : ${CLR_MAGENTA}${ip}${CLR_RESET}"
                [[ -n "$gateway" ]] && \
                    echo -e "  Gateway  : ${CLR_BLUE}${gateway}${CLR_RESET}"
            else
                echo -e "  Network  : ${CLR_GRAY}Not connected${CLR_RESET}"
            fi

            if [[ "$hotspot_active" == "true" ]]; then
                local hs_ssid
                hs_ssid="$(jq -r '.ssid // "Hotspot"' \
                    "${CACHE_DIR}/hotspot-info.json" 2>/dev/null || echo 'Hotspot')"
                echo -e "  Hotspot  : ${CLR_GREEN}${ICON_HOTSPOT}  ${hs_ssid}${CLR_RESET}"
            fi

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FLUSH DNS CACHE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dns_flush() {
    local flushed=false

    if command -v resolvectl &>/dev/null; then
        resolvectl flush-caches 2>/dev/null && flushed=true
    fi

    if command -v systemd-resolve &>/dev/null; then
        systemd-resolve --flush-caches 2>/dev/null && flushed=true
    fi

    if [[ "$flushed" == "true" ]]; then
        _notify "${ICON_DNS}  DNS Flushed" \
            "DNS cache cleared successfully" "low" "3000"
        log_success "DNS cache flushed"
    else
        log_warn "No supported DNS flush method found"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# USAGE / HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH Wi-Fi Toggle v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [COMMAND] [OPTIONS]

${CLR_BOLD}COMMANDS${CLR_RESET}
  ${CLR_GREEN}(no args)${CLR_RESET}              Toggle Wi-Fi on/off
  ${CLR_GREEN}--on${CLR_RESET}                   Enable Wi-Fi
  ${CLR_GREEN}--off${CLR_RESET}                  Disable Wi-Fi
  ${CLR_GREEN}--toggle${CLR_RESET}               Toggle state

${CLR_BOLD}CONNECTION${CLR_RESET}
  ${CLR_YELLOW}--connect SSID${CLR_RESET}         Connect to network
  ${CLR_YELLOW}--connect SSID PASS${CLR_RESET}    Connect with password
  ${CLR_YELLOW}--connect-hidden SSID${CLR_RESET}  Connect to hidden network
  ${CLR_YELLOW}--disconnect${CLR_RESET}           Disconnect current network
  ${CLR_YELLOW}--forget SSID${CLR_RESET}          Forget saved network

${CLR_BOLD}SCANNING${CLR_RESET}
  ${CLR_CYAN}--scan${CLR_RESET}                 Scan (from cache)
  ${CLR_CYAN}--scan-fresh${CLR_RESET}           Force rescan
  ${CLR_CYAN}--scan-table${CLR_RESET}           Human-readable table

${CLR_BOLD}HOTSPOT${CLR_RESET}
  ${CLR_BLUE}--hotspot-on${CLR_RESET}           Start hotspot (auto SSID/pass)
  ${CLR_BLUE}--hotspot-on SSID PASS${CLR_RESET} Start hotspot (custom)
  ${CLR_BLUE}--hotspot-off${CLR_RESET}          Stop hotspot
  ${CLR_BLUE}--hotspot-status${CLR_RESET}       Show hotspot info
  ${CLR_BLUE}--hotspot-qr${CLR_RESET}           Show QR code

${CLR_BOLD}DNS${CLR_RESET}
  ${CLR_MAGENTA}--dns cloudflare${CLR_RESET}      Switch to Cloudflare DNS
  ${CLR_MAGENTA}--dns google${CLR_RESET}          Switch to Google DNS
  ${CLR_MAGENTA}--dns quad9${CLR_RESET}           Switch to Quad9 DNS
  ${CLR_MAGENTA}--dns adguard${CLR_RESET}         Switch to AdGuard DNS
  ${CLR_MAGENTA}--dns auto${CLR_RESET}            Reset to DHCP DNS
  ${CLR_MAGENTA}--dns-test${CLR_RESET}            Latency test all presets
  ${CLR_MAGENTA}--dns-flush${CLR_RESET}           Flush DNS cache

${CLR_BOLD}STATUS${CLR_RESET}
  ${CLR_WHITE}--status${CLR_RESET}               Human-readable status
  ${CLR_WHITE}--status=json${CLR_RESET}           JSON status
  ${CLR_WHITE}--status=waybar${CLR_RESET}         Waybar module JSON
  ${CLR_WHITE}--status=short${CLR_RESET}          Compact one-liner
  ${CLR_WHITE}--ping [host]${CLR_RESET}           Ping test
  ${CLR_WHITE}--internet${CLR_RESET}              Check internet access
  ${CLR_WHITE}--version${CLR_RESET}               Show version
  ${CLR_WHITE}--help${CLR_RESET}                  Show help

${CLR_BOLD}EXAMPLES${CLR_RESET}
  $(basename "$0")                        # Toggle
  $(basename "$0") --connect "MyWiFi" "p4ss" # Connect
  $(basename "$0") --hotspot-on           # Start hotspot
  $(basename "$0") --dns cloudflare       # Switch DNS
  $(basename "$0") --status=json          # JSON status
  $(basename "$0") --scan-fresh           # Scan networks

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN ENTRYPOINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    _ensure_dirs
    _check_deps
    _acquire_lock || { log_error "Another instance running"; exit 1; }

    case "${1:-}" in
        # ── Core toggle ──────────────────────────────────────────────────
        "" | --toggle | -t)
            local state
            state="$(_get_wifi_state)"
            if [[ "$state" == "on" ]]; then
                _wifi_disable
            else
                _wifi_enable
            fi
            ;;

        --on | on | enable)
            shift
            _wifi_enable "$@"
            ;;

        --off | off | disable)
            shift
            _wifi_disable "$@"
            ;;

        # ── Connection ───────────────────────────────────────────────────
        --connect | -c)
            shift
            local ssid="${1:-}"
            local pass="${2:-}"
            [[ -z "$ssid" ]] && { log_error "SSID required"; exit 1; }
            _wifi_connect "$ssid" "$pass"
            ;;

        --connect-hidden)
            shift
            local ssid="${1:-}"
            local pass="${2:-}"
            _wifi_connect "$ssid" "$pass" "true"
            ;;

        --disconnect)
            _wifi_disconnect
            ;;

        --forget)
            shift
            local ssid="${1:-}"
            [[ -z "$ssid" ]] && { log_error "SSID required"; exit 1; }
            nmcli con delete "$ssid" &>/dev/null && \
                log_success "Forgotten: $ssid" || \
                log_error "Failed to forget: $ssid"
            ;;

        # ── Scanning ─────────────────────────────────────────────────────
        --scan)
            _wifi_scan false json
            ;;

        --scan-fresh)
            _wifi_scan true json
            ;;

        --scan-table | --list)
            _wifi_scan true table
            ;;

        --scan-count)
            _wifi_scan false count
            ;;

        # ── Hotspot ──────────────────────────────────────────────────────
        --hotspot-on | --hotspot)
            shift
            _hotspot_start "${1:-}" "${2:-}" "${3:-bg}"
            ;;

        --hotspot-off | --hotspot-stop)
            _hotspot_stop
            ;;

        --hotspot-status)
            _hotspot_status
            ;;

        --hotspot-qr)
            if [[ -f "${CACHE_DIR}/hotspot-info.json" ]]; then
                local ssid pass
                ssid="$(jq -r '.ssid     // ""' \
                    "${CACHE_DIR}/hotspot-info.json")"
                pass="$(jq -r '.password // ""' \
                    "${CACHE_DIR}/hotspot-info.json")"
                _hotspot_qr "$ssid" "$pass"
            else
                log_error "No active hotspot"
            fi
            ;;

        # ── DNS ───────────────────────────────────────────────────────────
        --dns)
            shift
            _dns_switch "${1:-cloudflare}"
            ;;

        --dns=*)
            _dns_switch "${1#--dns=}"
            ;;

        --dns-test)
            _dns_test
            ;;

        --dns-flush)
            _dns_flush
            ;;

        # ── Status ────────────────────────────────────────────────────────
        --status | -s | status)
            local fmt="${2:-human}"
            [[ "$1" == --status=* ]] && fmt="${1#--status=}"
            _show_status "$fmt"
            ;;

        --status=*)
            _show_status "${1#--status=}"
            ;;

        --ping)
            shift
            _ping_test "${1:-8.8.8.8}" "${2:-5}"
            ;;

        --internet)
            if _check_internet; then
                echo -e "${CLR_GREEN}${ICON_SUCCESS}  Internet: reachable${CLR_RESET}"
                exit 0
            else
                echo -e "${CLR_RED}${ICON_ERROR}  Internet: unreachable${CLR_RESET}"
                exit 1
            fi
            ;;

        --captive-check)
            if _check_captive_portal; then
                log_warn "Captive portal detected"
                _notify_captive_portal
                exit 1
            else
                log_info "No captive portal detected"
                exit 0
            fi
            ;;

        # ── Misc ─────────────────────────────────────────────────────────
        --version)
            echo "$SCRIPT_NAME v$SCRIPT_VERSION"
            ;;

        --help | -h | help)
            _show_help
            ;;

        *)
            log_error "Unknown command: ${1}"
            _show_help
            exit 1
            ;;
    esac

    exit 0
}

main "$@"