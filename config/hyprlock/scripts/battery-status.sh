#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HYPRLOCK SCRIPT: BATTERY-STATUS                 ║
# ║  Intelligent power telemetry — multi-battery, UPS, health, time remaining  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │  DESCRIPTION                                                                 │
# │  Full power supply intelligence engine for hyprlock battery widgets.        │
# │  Reads /sys/class/power_supply directly — no external deps for core data.  │
# │  upower used optionally for time-remaining when available.                  │
# │                                                                              │
# │  USAGE                                                                       │
# │    battery-status.sh                Full status line (default)              │
# │    battery-status.sh --short        "94%" or "󰂄 94%" (compact)            │
# │    battery-status.sh --icon         Nerd Font icon glyph only               │
# │    battery-status.sh --pct          Bare integer percentage "94"            │
# │    battery-status.sh --bar          Unicode block progress bar              │
# │    battery-status.sh --time         Time remaining string only              │
# │    battery-status.sh --state        "charging" / "discharging" / "full"    │
# │    battery-status.sh --health       Battery health percentage               │
# │    battery-status.sh --panel        Multi-line dashboard panel              │
# │    battery-status.sh --ampm         AM/PM string (clock widget dual-use)   │
# │    battery-status.sh --ticker       Ultra-compact for ticker bars           │
# │    battery-status.sh --critical     Output only when ≤10% (alert mode)     │
# │    battery-status.sh --ac-status    AC adapter connection status            │
# │                                                                              │
# │  SYSFS DATA SOURCES                                                          │
# │    /sys/class/power_supply/BAT*/    Battery nodes                           │
# │    /sys/class/power_supply/AC*/     AC adapter nodes                        │
# │    /sys/class/power_supply/USB*/    USB-C PD nodes                          │
# │                                                                              │
# │  ICON TIER MAP (Nerd Font battery icons)                                     │
# │    100%     → 󰁹   Full                                                      │
# │    80–99%   → 󰂂   High                                                     │
# │    60–79%   → 󰂀   Medium-High                                              │
# │    40–59%   → 󰁾   Medium                                                   │
# │    20–39%   → 󰁼   Low                                                      │
# │    10–19%   → 󰂃   Very Low   [color: WARN]                                 │
# │    0–9%     → 󰁺   Critical   [color: ERROR + pulse]                        │
# │    Charging → 󰂄   Bolt overlay                                              │
# │    Full+AC  → 󰂆   Full+Plugged                                              │
# └─────────────────────────────────────────────────────────────────────────────┘

set -euo pipefail

readonly SCRIPT_NAME="battery-status"
readonly SCRIPT_VERSION="5.0.0"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 01 — CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Thresholds ────────────────────────────────────────────────────────────────
readonly THRESHOLD_CRITICAL=10    # ≤ this % → critical state, error color
readonly THRESHOLD_LOW=20         # ≤ this % → low state, warn color
readonly THRESHOLD_WARN=20        # Alias for widget color switching
readonly THRESHOLD_FULL=98        # ≥ this % → "full" display text

# ── Progress bar width ────────────────────────────────────────────────────────
readonly BAR_WIDTH=16             # Block characters in progress bar
readonly COMPACT_BAR_WIDTH=12     # For compact/ticker modes

# ── Pango color codes (no # prefix — used with ##$VAR in markup) ──────────────
readonly COLOR_SUCCESS="a6e3a1"   # Catppuccin green  (charging)
readonly COLOR_NORMAL="cdd6f4"    # Catppuccin text   (normal)
readonly COLOR_WARN="f9e2af"      # Catppuccin yellow (low battery)
readonly COLOR_ERROR="f38ba8"     # Catppuccin red    (critical)
readonly COLOR_MUTED="6c7086"     # Catppuccin overlay0 (subtle info)

# ── Power supply sysfs base path ─────────────────────────────────────────────
readonly SYSFS_POWER="/sys/class/power_supply"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 02 — UTILITY FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Safe integer read from sysfs ─────────────────────────────────────────────
# Returns 0 if file missing or unreadable — never fails.
_sysfs_int() {
    local path="${1:-}"
    local default="${2:-0}"
    if [[ -f "$path" && -r "$path" ]]; then
        local val
        val=$(cat "$path" 2>/dev/null | tr -d '[:space:]')
        # Validate: must be an integer (possibly negative)
        [[ "$val" =~ ^-?[0-9]+$ ]] && echo "$val" || echo "$default"
    else
        echo "$default"
    fi
}

# ── Safe string read from sysfs ───────────────────────────────────────────────
_sysfs_str() {
    local path="${1:-}"
    local default="${2:-}"
    if [[ -f "$path" && -r "$path" ]]; then
        cat "$path" 2>/dev/null | tr -d '[:space:]' || echo "$default"
    else
        echo "$default"
    fi
}

# ── Build unicode progress bar ────────────────────────────────────────────────
_make_bar() {
    local pct="${1:-0}"
    local width="${2:-$BAR_WIDTH}"
    [[ $pct -lt 0 ]] && pct=0
    [[ $pct -gt 100 ]] && pct=100
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar=""
    [[ $filled -gt 0 ]] && bar=$(printf "%${filled}s" | tr ' ' "█")
    local empty_str=""
    [[ $empty -gt 0 ]] && empty_str=$(printf "%${empty}s" | tr ' ' "░")
    echo "${bar}${empty_str}"
}

# ── Select battery icon based on percentage + state ──────────────────────────
# Returns: Nerd Font battery glyph
_battery_icon() {
    local pct="${1:-0}"
    local state="${2:-discharging}"

    # Charging states
    if [[ "$state" == "charging" ]]; then
        if [[ $pct -ge 100 ]]; then
            echo "󰂆"   # Full + plugged
        elif [[ $pct -ge 80 ]]; then
            echo "󰂅"   # Charging high
        elif [[ $pct -ge 60 ]]; then
            echo "󰂄"   # Charging medium-high
        elif [[ $pct -ge 40 ]]; then
            echo "󰂄"   # Charging medium
        elif [[ $pct -ge 20 ]]; then
            echo "󰂄"   # Charging low
        else
            echo "󰢜"   # Charging critical
        fi
        return 0
    fi

    # Full + AC
    if [[ "$state" == "full" ]]; then
        echo "󰂆"
        return 0
    fi

    # Discharging tiers
    if [[ $pct -ge 100 ]]; then
        echo "󰁹"
    elif [[ $pct -ge 80 ]]; then
        echo "󰂂"
    elif [[ $pct -ge 60 ]]; then
        echo "󰂀"
    elif [[ $pct -ge 40 ]]; then
        echo "󰁾"
    elif [[ $pct -ge 20 ]]; then
        echo "󰁼"
    elif [[ $pct -ge 10 ]]; then
        echo "󰂃"
    else
        echo "󰁺"
    fi
}

# ── Select color based on percentage + state ──────────────────────────────────
# Returns: hex color code (no #)
_battery_color() {
    local pct="${1:-0}"
    local state="${2:-discharging}"

    if [[ "$state" == "charging" || "$state" == "full" ]]; then
        echo "$COLOR_SUCCESS"
        return 0
    fi

    if [[ $pct -le $THRESHOLD_CRITICAL ]]; then
        echo "$COLOR_ERROR"
    elif [[ $pct -le $THRESHOLD_WARN ]]; then
        echo "$COLOR_WARN"
    else
        echo "$COLOR_NORMAL"
    fi
}

# ── Format time in minutes to Xh Ym display ───────────────────────────────────
# Input: minutes as integer
# Output: "3h 42m" or "42m" or "< 1m"
_format_time_remaining() {
    local minutes="${1:-0}"
    [[ $minutes -le 0 ]] && echo "" && return 0

    local hours=$(( minutes / 60 ))
    local mins=$(( minutes % 60 ))

    if [[ $hours -gt 0 && $mins -gt 0 ]]; then
        echo "${hours}h ${mins}m"
    elif [[ $hours -gt 0 ]]; then
        echo "${hours}h"
    elif [[ $mins -gt 0 ]]; then
        echo "${mins}m"
    else
        echo "< 1m"
    fi
}

# ── Check if command exists ───────────────────────────────────────────────────
_has_cmd() {
    command -v "$1" &>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 03 — POWER SUPPLY DETECTION & DATA ACQUISITION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Find primary battery node ─────────────────────────────────────────────────
# Priority: BAT0 > BAT1 > BATT > CMB0 (common naming conventions)
# Returns: sysfs path to battery dir, or empty string if no battery
_find_battery() {
    local candidates=("BAT0" "BAT1" "BAT2" "BATT" "CMB0" "CMB1")
    local name
    for name in "${candidates[@]}"; do
        local path="${SYSFS_POWER}/${name}"
        if [[ -d "$path" ]]; then
            # Verify it's actually a battery type
            local bat_type
            bat_type=$(_sysfs_str "${path}/type" "")
            if [[ "$bat_type" == "Battery" ]]; then
                echo "$path"
                return 0
            fi
        fi
    done

    # Fallback: scan all entries for Battery type
    local entry
    for entry in "${SYSFS_POWER}"/*/; do
        if [[ -d "$entry" ]]; then
            local ptype
            ptype=$(_sysfs_str "${entry}/type" "")
            if [[ "$ptype" == "Battery" ]]; then
                echo "${entry%/}"
                return 0
            fi
        fi
    done

    echo ""
}

# ── Find secondary battery (multi-battery systems) ────────────────────────────
_find_battery2() {
    local primary_path="${1:-}"
    local primary_name
    primary_name=$(basename "$primary_path")

    local candidates=("BAT0" "BAT1" "BAT2" "BATT" "CMB0" "CMB1")
    local name
    for name in "${candidates[@]}"; do
        [[ "$name" == "$primary_name" ]] && continue
        local path="${SYSFS_POWER}/${name}"
        if [[ -d "$path" ]]; then
            local bat_type
            bat_type=$(_sysfs_str "${path}/type" "")
            [[ "$bat_type" == "Battery" ]] && echo "$path" && return 0
        fi
    done

    echo ""
}

# ── Check if AC adapter is online ────────────────────────────────────────────
_ac_online() {
    local entry
    for entry in "${SYSFS_POWER}"/*/; do
        [[ ! -d "$entry" ]] && continue
        local ptype
        ptype=$(_sysfs_str "${entry}/type" "")
        if [[ "$ptype" == "Mains" || "$ptype" == "USB" ]]; then
            local online
            online=$(_sysfs_int "${entry}/online" 0)
            [[ $online -eq 1 ]] && echo "1" && return 0
        fi
    done
    echo "0"
}

# ── Read battery percentage ───────────────────────────────────────────────────
# Tries capacity file first (most common), falls back to charge calculation.
_read_capacity() {
    local bat_path="${1:-}"

    # Primary: capacity file (0–100 integer)
    local cap_file="${bat_path}/capacity"
    if [[ -f "$cap_file" ]]; then
        local pct
        pct=$(_sysfs_int "$cap_file" -1)
        if [[ $pct -ge 0 && $pct -le 100 ]]; then
            echo "$pct"
            return 0
        fi
    fi

    # Fallback 1: charge_now / charge_full (μAh)
    local charge_now charge_full
    charge_now=$(_sysfs_int "${bat_path}/charge_now" 0)
    charge_full=$(_sysfs_int "${bat_path}/charge_full" 0)
    if [[ $charge_full -gt 0 && $charge_now -ge 0 ]]; then
        local pct=$(( charge_now * 100 / charge_full ))
        [[ $pct -gt 100 ]] && pct=100
        echo "$pct"
        return 0
    fi

    # Fallback 2: energy_now / energy_full (μWh)
    local energy_now energy_full
    energy_now=$(_sysfs_int "${bat_path}/energy_now" 0)
    energy_full=$(_sysfs_int "${bat_path}/energy_full" 0)
    if [[ $energy_full -gt 0 && $energy_now -ge 0 ]]; then
        local pct=$(( energy_now * 100 / energy_full ))
        [[ $pct -gt 100 ]] && pct=100
        echo "$pct"
        return 0
    fi

    echo "0"
}

# ── Read battery status string ────────────────────────────────────────────────
# Normalizes sysfs status to lowercase: "charging" / "discharging" / "full" / "unknown"
_read_status() {
    local bat_path="${1:-}"
    local raw
    raw=$(_sysfs_str "${bat_path}/status" "Unknown")
    echo "${raw,,}"  # Bash lowercase conversion
}

# ── Calculate time remaining via upower ──────────────────────────────────────
# Returns: minutes as integer, or 0 if unavailable
_time_remaining_upower() {
    local bat_path="${1:-}"
    local bat_name
    bat_name=$(basename "$bat_path")

    if ! _has_cmd upower; then
        echo "0"
        return 0
    fi

    # Find upower device path matching battery name
    local upower_path
    upower_path=$(upower -e 2>/dev/null | grep -i "$bat_name" | head -1)
    [[ -z "$upower_path" ]] && upower_path=$(upower -e 2>/dev/null | grep -i "battery" | head -1)
    [[ -z "$upower_path" ]] && echo "0" && return 0

    # Parse "time to empty" or "time to full" from upower output
    local time_line
    time_line=$(upower -i "$upower_path" 2>/dev/null \
        | grep -E "time to (empty|full)" \
        | head -1 \
        | awk '{print $(NF-1), $NF}')

    if [[ -z "$time_line" ]]; then
        echo "0"
        return 0
    fi

    local val unit
    val=$(echo "$time_line" | awk '{print $1}')
    unit=$(echo "$time_line" | awk '{print $2}')

    # Convert to minutes
    local minutes=0
    case "$unit" in
        hours|hour)         minutes=$(printf "%.0f" "$(echo "$val * 60" | bc 2>/dev/null || echo 0)" ) ;;
        minutes|minute|min) minutes=$(printf "%.0f" "$val" 2>/dev/null || echo 0) ;;
        seconds|second|sec) minutes=$(( ${val%.*} / 60 )) ;;
    esac

    echo "${minutes:-0}"
}

# ── Calculate time remaining via rate (fallback) ──────────────────────────────
# Uses current discharge rate from sysfs power_now field.
# Less accurate than upower but works without it.
_time_remaining_rate() {
    local bat_path="${1:-}"
    local pct="${2:-0}"
    local state="${3:-discharging}"

    # power_now: current power draw in μW
    local power_now
    power_now=$(_sysfs_int "${bat_path}/power_now" 0)
    [[ $power_now -le 0 ]] && echo "0" && return 0

    # energy_now: remaining energy in μWh
    local energy_now
    energy_now=$(_sysfs_int "${bat_path}/energy_now" 0)

    # charge fallback: remaining charge in μAh
    local charge_now voltage_now
    if [[ $energy_now -le 0 ]]; then
        charge_now=$(_sysfs_int "${bat_path}/charge_now" 0)
        voltage_now=$(_sysfs_int "${bat_path}/voltage_now" 1000000)
        # Convert charge (μAh) × voltage (μV) / 1e12 = energy (μWh)
        energy_now=$(( charge_now * voltage_now / 1000000 ))
    fi

    [[ $energy_now -le 0 ]] && echo "0" && return 0

    if [[ "$state" == "charging" ]]; then
        # Time to full: (energy_full - energy_now) / power_now in hours → minutes
        local energy_full
        energy_full=$(_sysfs_int "${bat_path}/energy_full" 0)
        local remaining=$(( energy_full - energy_now ))
        [[ $remaining -le 0 ]] && echo "0" && return 0
        local hours_x100=$(( remaining * 100 / power_now ))
        echo $(( hours_x100 * 60 / 100 ))
    else
        # Time to empty: energy_now / power_now in hours → minutes
        local hours_x100=$(( energy_now * 100 / power_now ))
        echo $(( hours_x100 * 60 / 100 ))
    fi
}

# ── Get time remaining (upower preferred, rate fallback) ──────────────────────
_get_time_remaining() {
    local bat_path="${1:-}"
    local pct="${2:-0}"
    local state="${3:-discharging}"

    local minutes=0

    # Don't calculate time when full or unknown
    if [[ "$state" == "full" || "$state" == "unknown" ]]; then
        echo "0"
        return 0
    fi

    # Try upower first (most accurate)
    if _has_cmd upower; then
        minutes=$(_time_remaining_upower "$bat_path")
    fi

    # Fall back to rate calculation
    if [[ ${minutes:-0} -le 0 ]]; then
        minutes=$(_time_remaining_rate "$bat_path" "$pct" "$state")
    fi

    echo "${minutes:-0}"
}

# ── Calculate battery health percentage ───────────────────────────────────────
# Health = (charge_full / charge_full_design) * 100
# Returns: integer 0–100
_get_health() {
    local bat_path="${1:-}"

    # Try charge-based health
    local full full_design
    full=$(_sysfs_int "${bat_path}/charge_full" 0)
    full_design=$(_sysfs_int "${bat_path}/charge_full_design" 0)

    if [[ $full_design -gt 0 && $full -gt 0 ]]; then
        local health=$(( full * 100 / full_design ))
        [[ $health -gt 100 ]] && health=100
        echo "$health"
        return 0
    fi

    # Energy-based fallback
    local efull efull_design
    efull=$(_sysfs_int "${bat_path}/energy_full" 0)
    efull_design=$(_sysfs_int "${bat_path}/energy_full_design" 0)

    if [[ $efull_design -gt 0 && $efull -gt 0 ]]; then
        local health=$(( efull * 100 / efull_design ))
        [[ $health -gt 100 ]] && health=100
        echo "$health"
        return 0
    fi

    echo "100"
}

# ── Get battery cycle count ───────────────────────────────────────────────────
_get_cycle_count() {
    local bat_path="${1:-}"
    local cycles
    cycles=$(_sysfs_int "${bat_path}/cycle_count" -1)
    [[ $cycles -lt 0 ]] && echo "?" || echo "$cycles"
}

# ── Get battery technology ────────────────────────────────────────────────────
_get_technology() {
    local bat_path="${1:-}"
    _sysfs_str "${bat_path}/technology" "Li-ion"
}

# ── Get design capacity in mAh ────────────────────────────────────────────────
_get_design_capacity_mah() {
    local bat_path="${1:-}"
    local cap
    cap=$(_sysfs_int "${bat_path}/charge_full_design" 0)
    if [[ $cap -gt 0 ]]; then
        echo $(( cap / 1000 ))
        return 0
    fi
    # Energy fallback: assume 3.7V nominal
    local ecap
    ecap=$(_sysfs_int "${bat_path}/energy_full_design" 0)
    if [[ $ecap -gt 0 ]]; then
        echo $(( ecap / 3700 ))
        return 0
    fi
    echo "?"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 04 — OUTPUT FORMAT FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── DEFAULT: Full status line with Pango color markup ─────────────────────────
# Format (discharging): "󰁾  58%  2h 34m remaining"
# Format (charging):    "󰂄  67%  Charging  1h 12m to full"
# Format (full):        "󰂆  Full  (AC connected)"
# Format (desktop):     "" (empty — widget hides itself)
output_default() {
    local icon color time_remaining time_fmt=""

    icon=$(_battery_icon "$BATTERY_PCT" "$BATTERY_STATE")
    color=$(_battery_color "$BATTERY_PCT" "$BATTERY_STATE")

    case "$BATTERY_STATE" in
        full)
            echo "<span foreground=\"##${COLOR_SUCCESS}\">${icon}  Full  (AC connected)</span>"
            ;;
        charging)
            local mins
            mins=$(_get_time_remaining "$BATTERY_PATH" "$BATTERY_PCT" "charging")
            local mins_fmt
            mins_fmt=$(_format_time_remaining "$mins")
            if [[ -n "$mins_fmt" && $mins -gt 2 ]]; then
                echo "<span foreground=\"##${COLOR_SUCCESS}\">${icon}  ${BATTERY_PCT}%  Charging  ${mins_fmt} to full</span>"
            else
                echo "<span foreground=\"##${COLOR_SUCCESS}\">${icon}  ${BATTERY_PCT}%  Charging</span>"
            fi
            ;;
        discharging)
            local mins
            mins=$(_get_time_remaining "$BATTERY_PATH" "$BATTERY_PCT" "discharging")
            local mins_fmt
            mins_fmt=$(_format_time_remaining "$mins")
            if [[ -n "$mins_fmt" && $mins -gt 2 ]]; then
                echo "<span foreground=\"##${color}\">${icon}  ${BATTERY_PCT}%  ${mins_fmt} remaining</span>"
            else
                echo "<span foreground=\"##${color}\">${icon}  ${BATTERY_PCT}%</span>"
            fi
            ;;
        unknown)
            echo "<span foreground=\"##${COLOR_MUTED}\">󰂑  Status unknown</span>"
            ;;
    esac
}

# ── --short: Compact percentage with icon ────────────────────────────────────
# Format: "󰂄 94%" (charging) or "󰁾 58%" (discharging)
output_short() {
    local icon color
    icon=$(_battery_icon "$BATTERY_PCT" "$BATTERY_STATE")
    color=$(_battery_color "$BATTERY_PCT" "$BATTERY_STATE")
    echo "<span foreground=\"##${color}\">${icon} ${BATTERY_PCT}%</span>"
}

# ── --icon: Nerd Font glyph only ─────────────────────────────────────────────
output_icon() {
    local icon color
    icon=$(_battery_icon "$BATTERY_PCT" "$BATTERY_STATE")
    color=$(_battery_color "$BATTERY_PCT" "$BATTERY_STATE")
    echo "<span foreground=\"##${color}\">${icon}</span>"
}

# ── --pct: Bare integer percentage ────────────────────────────────────────────
output_pct() {
    echo "$BATTERY_PCT"
}

# ── --bar: Unicode block progress bar ────────────────────────────────────────
# Format: "[████████░░░░░░░░]"
# Color-coded: green (charging), yellow (low), red (critical), normal
output_bar() {
    local bar color
    bar=$(_make_bar "$BATTERY_PCT" "$BAR_WIDTH")
    color=$(_battery_color "$BATTERY_PCT" "$BATTERY_STATE")
    echo "<span foreground=\"##${color}\">[${bar}]</span>"
}

# ── --time: Time remaining string only ────────────────────────────────────────
# Returns: "2h 34m remaining" / "1h 12m to full" / "" if unknown/full
output_time() {
    case "$BATTERY_STATE" in
        full)      echo "Full" ;;
        charging)
            local mins
            mins=$(_get_time_remaining "$BATTERY_PATH" "$BATTERY_PCT" "charging")
            local fmt
            fmt=$(_format_time_remaining "$mins")
            [[ -n "$fmt" ]] && echo "${fmt} to full" || echo "Charging"
            ;;
        discharging)
            local mins
            mins=$(_get_time_remaining "$BATTERY_PATH" "$BATTERY_PCT" "discharging")
            local fmt
            fmt=$(_format_time_remaining "$mins")
            [[ -n "$fmt" ]] && echo "${fmt} remaining" || echo ""
            ;;
        *) echo "" ;;
    esac
}

# ── --state: Normalized state string ─────────────────────────────────────────
output_state() {
    echo "$BATTERY_STATE"
}

# ── --health: Battery health percentage ──────────────────────────────────────
# Format: "󰛞  Health: 87%  (Good)" with color-coded health bracket
output_health() {
    local health
    health=$(_get_health "$BATTERY_PATH")

    local health_label health_color
    if [[ $health -ge 85 ]]; then
        health_label="Excellent"; health_color="$COLOR_SUCCESS"
    elif [[ $health -ge 70 ]]; then
        health_label="Good";      health_color="$COLOR_SUCCESS"
    elif [[ $health -ge 50 ]]; then
        health_label="Fair";      health_color="$COLOR_WARN"
    elif [[ $health -ge 30 ]]; then
        health_label="Poor";      health_color="$COLOR_ERROR"
    else
        health_label="Replace";   health_color="$COLOR_ERROR"
    fi

    echo "<span foreground=\"##${health_color}\">󰛞  Health: ${health}%  (${health_label})</span>"
}

# ── --panel: Multi-line dashboard panel (for dual-monitor.conf) ───────────────
# Comprehensive display: state + bar + health + cycles + time + technology
output_panel() {
    local icon color health cycles tech cap_mah
    icon=$(_battery_icon "$BATTERY_PCT" "$BATTERY_STATE")
    color=$(_battery_color "$BATTERY_PCT" "$BATTERY_STATE")
    health=$(_get_health "$BATTERY_PATH")
    cycles=$(_get_cycle_count "$BATTERY_PATH")
    tech=$(_get_technology "$BATTERY_PATH")
    cap_mah=$(_get_design_capacity_mah "$BATTERY_PATH")

    local bar
    bar=$(_make_bar "$BATTERY_PCT" 20)

    # Time remaining
    local time_str=""
    case "$BATTERY_STATE" in
        charging)
            local mins
            mins=$(_get_time_remaining "$BATTERY_PATH" "$BATTERY_PCT" "charging")
            time_str=$(_format_time_remaining "$mins")
            [[ -n "$time_str" ]] && time_str="${time_str} to full"
            ;;
        discharging)
            local mins
            mins=$(_get_time_remaining "$BATTERY_PATH" "$BATTERY_PCT" "discharging")
            time_str=$(_format_time_remaining "$mins")
            [[ -n "$time_str" ]] && time_str="${time_str} remaining"
            ;;
        full)
            time_str="Fully charged"
            ;;
    esac

    # Health color
    local hcol
    if [[ $health -ge 80 ]]; then hcol="$COLOR_SUCCESS"
    elif [[ $health -ge 50 ]]; then hcol="$COLOR_WARN"
    else hcol="$COLOR_ERROR"; fi

    # Line 1: Icon + % + state
    local line1="<span foreground=\"##${color}\">${icon}  ${BATTERY_PCT}%  $(echo "$BATTERY_STATE" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')</span>"

    # Line 2: Progress bar
    local line2="<span foreground=\"##${color}\">[${bar}]</span>"

    # Line 3: Time remaining
    local line3=""
    [[ -n "$time_str" ]] && line3="󰔚  ${time_str}"

    # Line 4: Health + cycles
    local line4="<span foreground=\"##${hcol}\">󰛞  Health ${health}%</span>  •  Cycles: ${cycles}"

    # Line 5: Technology + capacity
    local line5="󰋊  ${tech}  •  ${cap_mah} mAh design"

    # Compose — skip empty lines
    local output="${line1}\n${line2}"
    [[ -n "$line3" ]] && output+="\n${line3}"
    output+="\n${line4}\n${line5}"

    printf "%b" "$output"
}

# ── --ampm: AM/PM string (shared with clock widget) ──────────────────────────
# This flag repurposes battery-status.sh as a dual-use script.
# When called with --ampm from the clock widget's AM/PM label,
# outputs AM or PM based on current time, respecting HL_CLOCK_FORMAT.
# Returns empty string when 24h mode is active.
output_ampm() {
    local clock_format="${HL_CLOCK_FORMAT:-24h}"
    if [[ "$clock_format" == "12h" ]]; then
        date +"%p"
    else
        echo ""
    fi
}

# ── --ticker: Ultra-compact single glyph + % (for ticker bars) ───────────────
# Format: "󰁾 58%" — shortest possible battery representation
output_ticker() {
    local icon
    icon=$(_battery_icon "$BATTERY_PCT" "$BATTERY_STATE")
    echo "${icon} ${BATTERY_PCT}%"
}

# ── --critical: Output only when battery ≤ threshold ─────────────────────────
# Returns: full status line when critical, empty string otherwise.
# Used by: ash-battery-monitor.service to trigger critical alert variant.
output_critical() {
    if [[ "$BATTERY_STATE" == "discharging" && $BATTERY_PCT -le $THRESHOLD_CRITICAL ]]; then
        output_default
    else
        echo ""
    fi
}

# ── --ac-status: AC adapter connection state ──────────────────────────────────
# Format: "󰚥  AC connected" or "󰂃  On battery"
output_ac_status() {
    local ac_online
    ac_online=$(_ac_online)
    if [[ "$ac_online" == "1" ]]; then
        echo "<span foreground=\"##${COLOR_SUCCESS}\">󰚥  AC connected</span>"
    else
        echo "<span foreground=\"##${COLOR_WARN}\">󰂃  On battery</span>"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION 05 — MAIN DISPATCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local mode="${1:-}"

    # ── AM/PM mode: bypass battery detection (shared clock use) ───────────────
    if [[ "$mode" == "--ampm" ]]; then
        output_ampm
        exit 0
    fi

    # ── Detect battery hardware ───────────────────────────────────────────────
    local bat_path
    bat_path=$(_find_battery)

    # ── No battery detected: desktop/AC-only system ───────────────────────────
    # All battery modes return empty string → widgets self-hide in hyprlock.
    if [[ -z "$bat_path" ]]; then
        # Special cases that make sense even without battery
        case "$mode" in
            --ac-status)   output_ac_status; exit 0 ;;
            --version)     echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"; exit 0 ;;
        esac
        # Everything else: empty = widget invisible
        echo ""
        exit 0
    fi

    # ── Populate global battery data ──────────────────────────────────────────
    BATTERY_PATH="$bat_path"
    BATTERY_PCT=$(_read_capacity "$bat_path")
    BATTERY_STATE=$(_read_status "$bat_path")

    # Normalize "not charging" → "full" when above threshold
    if [[ "$BATTERY_STATE" == "not charging" ]]; then
        [[ $BATTERY_PCT -ge $THRESHOLD_FULL ]] && BATTERY_STATE="full" || BATTERY_STATE="discharging"
    fi

    # Normalize "unknown" when AC is online + high % → "full"
    if [[ "$BATTERY_STATE" == "unknown" ]]; then
        local ac
        ac=$(_ac_online)
        [[ "$ac" == "1" && $BATTERY_PCT -ge $THRESHOLD_FULL ]] && BATTERY_STATE="full"
    fi

    # ── Route to output function ──────────────────────────────────────────────
    case "$mode" in
        "")             output_default   ;;
        --short)        output_short     ;;
        --icon)         output_icon      ;;
        --pct)          output_pct       ;;
        --bar)          output_bar       ;;
        --time)         output_time      ;;
        --state)        output_state     ;;
        --health)       output_health    ;;
        --panel)        output_panel     ;;
        --ticker)       output_ticker    ;;
        --critical)     output_critical  ;;
        --ac-status)    output_ac_status ;;
        --version)      echo "${SCRIPT_NAME} v${SCRIPT_VERSION}" ;;
        --help|-h)
            echo "Usage: battery-status.sh [--short|--icon|--pct|--bar|--time|--state|--health|--panel|--ticker|--critical|--ac-status|--ampm]"
            ;;
        *)
            echo "battery-status: unknown flag: $mode" >&2
            output_default
            ;;
    esac
}

main "$@"