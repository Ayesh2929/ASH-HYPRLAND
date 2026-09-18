#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  hw battery                                              ║
# ║  Charge level • health • cycles • capacity • power draw • time remaining        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_BATTERY_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_BATTERY_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BATTERY DISCOVERY & DATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bat_find_all() {
    find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -type l 2>/dev/null | sort
}

_bat_ac_online() {
    # Check if AC adapter is connected
    for ac in /sys/class/power_supply/AC*/online \
              /sys/class/power_supply/ADP*/online \
              /sys/class/power_supply/ACAD/online; do
        [[ -r "$ac" ]] && cat "$ac" 2>/dev/null && return
    done
    echo '?'
}

_bat_read() {
    local bat_dir="$1"
    local file="$2"
    cat "${bat_dir}/${file}" 2>/dev/null || echo ''
}

_bat_read_int() {
    local val
    val="$(_bat_read "$1" "$2")"
    printf '%d' "${val:-0}" 2>/dev/null || echo 0
}

# Calculate battery health percentage
_bat_health_pct() {
    local bat_dir="$1"
    local capacity_design
    local capacity_full
    capacity_design="$(_bat_read_int "$bat_dir" "energy_full_design")"
    capacity_full="$(_bat_read_int "$bat_dir" "energy_full")"

    if (( capacity_design > 0 )) && (( capacity_full > 0 )); then
        printf '%d' "$(( capacity_full * 100 / capacity_design ))"
    else
        # Try charge-based
        capacity_design="$(_bat_read_int "$bat_dir" "charge_full_design")"
        capacity_full="$(_bat_read_int "$bat_dir" "charge_full")"
        if (( capacity_design > 0 )) && (( capacity_full > 0 )); then
            printf '%d' "$(( capacity_full * 100 / capacity_design ))"
        else
            printf '?'
        fi
    fi
}

# Time remaining in minutes
_bat_time_remaining() {
    local bat_dir="$1"
    local status
    status="$(_bat_read "$bat_dir" "status")"

    # Try power_now and energy_now
    local energy_now power_now
    energy_now="$(_bat_read_int "$bat_dir" "energy_now")"
    power_now="$(  _bat_read_int "$bat_dir" "power_now")"

    if (( power_now > 0 )) && (( energy_now > 0 )); then
        case "$status" in
            Discharging)
                printf '%d' "$(( energy_now * 60 / power_now ))"
                return ;;
            Charging)
                local energy_full
                energy_full="$(_bat_read_int "$bat_dir" "energy_full")"
                local remaining=$(( energy_full - energy_now ))
                (( remaining > 0 )) && \
                    printf '%d' "$(( remaining * 60 / power_now ))" || \
                    printf '0'
                return ;;
        esac
    fi

    printf '?'
}

_bat_format_time() {
    local mins="$1"
    [[ "$mins" == "?" ]] && { printf '?'; return; }
    [[ "$mins" =~ ^[0-9]+$ ]] || { printf '?'; return; }
    local h=$(( mins / 60 ))
    local m=$(( mins % 60 ))
    printf '%dh %02dm' "$h" "$m"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  BATTERY GAUGE RENDERER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bat_gauge() {
    local pct="$1"
    local status="$2"
    local width=30

    local filled=$(( pct * width / 100 ))
    (( filled > width )) && filled=$width
    local empty=$(( width - filled ))

    local bat_color bat_icon
    if   (( pct <= 10 )); then
        bat_color="$(_hw_red)";    bat_icon="🔴"
    elif (( pct <= 20 )); then
        bat_color="$(_hw_red)";    bat_icon="🟠"
    elif (( pct <= 40 )); then
        bat_color="$(_hw_yellow)"; bat_icon="🟡"
    elif (( pct <= 80 )); then
        bat_color="$(_hw_green)";  bat_icon="🟢"
    else
        bat_color="$(_hw_green)";  bat_icon="✅"
    fi

    # Charging animation character
    local charge_char="█"
    [[ "$status" == "Charging" ]] && charge_char="▶"

    printf '\n  %s' "$bat_icon"
    printf '  ['
    printf '%s%s%s' "$bat_color" "$(printf "${charge_char}%.0s" $(seq 1 "$filled"))" "$(_hw_r)"
    printf '%s%s%s' "$(_hw_dim)" "$(printf '░%.0s'             $(seq 1 "$empty"))"  "$(_hw_r)"
    printf ']'
    printf '  %s%s%d%%%s\n\n' "$(_hw_bold)" "$bat_color" "$pct" "$(_hw_r)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  UPOWER DETAILS (if available)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bat_upower_info() {
    command -v upower &>/dev/null || return 1

    local upower_path
    upower_path="$(upower -e 2>/dev/null | grep -i battery | head -1)"
    [[ -z "$upower_path" ]] && return 1

    upower -i "$upower_path" 2>/dev/null | \
        grep -E 'vendor:|model:|serial:|technology:|capacity:|energy-full:|energy:|charge-cycles:|state:|time to' | \
        sed 's/^\s*//'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_battery() {
    local short=0
    for arg in "${@:-}"; do
        [[ "$arg" == "--short" ]] && short=1
    done

    hw_section "🔋" "Battery" "$(_hw_green)"

    # AC adapter status
    local ac_online
    ac_online="$(_bat_ac_online)"

    if [[ "$ac_online" == "1" ]]; then
        printf '  %s⚡  AC Adapter: CONNECTED%s\n' "$(_hw_green)" "$(_hw_r)"
    elif [[ "$ac_online" == "0" ]]; then
        printf '  %s🔋  AC Adapter: DISCONNECTED  (on battery)%s\n' \
            "$(_hw_yellow)" "$(_hw_r)"
    fi

    # Find batteries
    local -a bat_dirs=()
    mapfile -t bat_dirs < <(_bat_find_all)

    if [[ ${#bat_dirs[@]} -eq 0 ]]; then
        printf '\n  %sNo battery detected  (desktop system?)%s\n' \
            "$(_hw_dim)" "$(_hw_r)"
        hw_divider
        return 0
    fi

    for bat_dir in "${bat_dirs[@]}"; do
        local bat_name
        bat_name="$(basename "$bat_dir")"

        local pct status manufacturer model technology
        local cycle_count energy_now energy_full power_now

        pct="$(           _bat_read_int "$bat_dir" "capacity")"
        status="$(        _bat_read     "$bat_dir" "status")"
        manufacturer="$(  _bat_read     "$bat_dir" "manufacturer")"
        model="$(         _bat_read     "$bat_dir" "model_name")"
        technology="$(    _bat_read     "$bat_dir" "technology")"
        cycle_count="$(   _bat_read     "$bat_dir" "cycle_count")"
        energy_now="$(    _bat_read_int "$bat_dir" "energy_now")"
        energy_full="$(   _bat_read_int "$bat_dir" "energy_full")"
        power_now="$(     _bat_read_int "$bat_dir" "power_now")"

        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
            printf '{\n'
            printf '  "name": "%s",\n'      "$bat_name"
            printf '  "percent": %s,\n'     "$pct"
            printf '  "status": "%s",\n'    "$status"
            printf '  "manufacturer": "%s",\n' "$manufacturer"
            printf '  "model": "%s",\n'     "$model"
            printf '  "technology": "%s",\n' "$technology"
            printf '  "cycles": "%s"\n'     "$cycle_count"
            printf '}\n'
            return 0
        fi

        printf '\n  %s%s%s\n' "$(_hw_bold)$(_hw_teal)" "$bat_name" "$(_hw_r)"

        _bat_gauge "$pct" "$status"

        hw_kv "Status"       "$status"
        hw_kv "Manufacturer" "${manufacturer:-unknown}"
        hw_kv "Model"        "${model:-unknown}"
        hw_kv "Technology"   "${technology:-unknown}"

        if [[ -n "$cycle_count" ]]; then
            local health_pct
            health_pct="$(_bat_health_pct "$bat_dir")"

            hw_kv "Charge cycles" "$cycle_count"
            hw_kv "Health"        "${health_pct}%"

            # Health indicator
            if [[ "$health_pct" =~ ^[0-9]+$ ]]; then
                if (( health_pct >= 80 )); then
                    printf '  %s  ✓ Battery health: GOOD%s\n' \
                        "$(_hw_green)" "$(_hw_r)"
                elif (( health_pct >= 60 )); then
                    printf '  %s  ⚠ Battery health: DEGRADED%s\n' \
                        "$(_hw_yellow)" "$(_hw_r)"
                else
                    printf '  %s  ✗ Battery health: POOR  (consider replacement)%s\n' \
                        "$(_hw_red)" "$(_hw_r)"
                fi
            fi
        fi

        # Energy
        if (( energy_full > 0 )); then
            hw_kv "Energy now"  "$(printf '%s Wh' "$(hw_div "$energy_now" 1000000 1)")"
            hw_kv "Energy full" "$(printf '%s Wh' "$(hw_div "$energy_full" 1000000 1)")"
        fi

        # Power draw
        if (( power_now > 0 )); then
            hw_kv "Power draw" \
                "$(printf '%s W' "$(hw_div "$power_now" 1000000 2)")"
        fi

        # Time remaining
        local time_mins
        time_mins="$(_bat_time_remaining "$bat_dir")"
        if [[ "$time_mins" != "?" ]] && [[ "$time_mins" =~ ^[0-9]+$ ]]; then
            case "$status" in
                Discharging) hw_kv "Time remaining" "$(_bat_format_time "$time_mins")" ;;
                Charging)    hw_kv "Time to full"   "$(_bat_format_time "$time_mins")" ;;
            esac
        fi

        # UPower extended info
        if [[ $short -eq 0 ]]; then
            local upower_out
            upower_out="$(_bat_upower_info 2>/dev/null || echo '')"
            if [[ -n "$upower_out" ]]; then
                printf '\n  %supower extended info:%s\n' "$(_hw_dim)" "$(_hw_r)"
                while IFS= read -r uline; do
                    [[ -z "$uline" ]] && continue
                    printf '  %s%s%s\n' "$(_hw_dim)" "$uline" "$(_hw_r)"
                done <<< "$upower_out"
            fi
        fi
    done

    hw_divider
}
