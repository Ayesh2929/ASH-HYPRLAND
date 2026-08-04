#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  hw monitor                                              ║
# ║  Connected displays • resolutions • refresh rates • HDR • VRR • positions       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_HW_MONITOR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_HW_MONITOR_LOADED=1

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MONITOR DATA VIA MULTIPLE BACKENDS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mon_via_hyprctl() {
    [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && return 1
    command -v hyprctl &>/dev/null || return 1

    local monitors_json
    monitors_json="$(hyprctl monitors -j 2>/dev/null || echo '[]')"

    if ! command -v python3 &>/dev/null; then
        return 1
    fi

    python3 - << PYEOF
import json, sys

monitors = json.loads('''${monitors_json}''')
for m in monitors:
    name   = m.get('name','?')
    model  = m.get('description','?').split('(')[0].strip()
    width  = m.get('width', 0)
    height = m.get('height', 0)
    hz     = m.get('refreshRate', 0)
    scale  = m.get('scale', 1)
    x      = m.get('x', 0)
    y      = m.get('y', 0)
    vrr    = m.get('vrr', False)
    hdr    = m.get('hdrEnabled', False)
    active = not m.get('disabled', False)

    print(f"name={name}")
    print(f"model={model}")
    print(f"resolution={width}x{height}")
    print(f"refresh={hz:.3f}")
    print(f"scale={scale}")
    print(f"position={x},{y}")
    print(f"vrr={'yes' if vrr else 'no'}")
    print(f"hdr={'yes' if hdr else 'no'}")
    print(f"active={'yes' if active else 'no'}")
    print("---")
PYEOF
}

_mon_via_wlr_randr() {
    command -v wlr-randr &>/dev/null || return 1
    wlr-randr 2>/dev/null
}

_mon_via_xrandr() {
    command -v xrandr &>/dev/null || return 1
    [[ -n "${DISPLAY:-}" ]] || return 1
    xrandr 2>/dev/null | grep ' connected'
}

_mon_via_sysfs() {
    # Enumerate DRM connectors
    for conn_dir in /sys/class/drm/card*-*/; do
        [[ -d "$conn_dir" ]] || continue
        local conn_name
        conn_name="$(basename "$conn_dir")"
        conn_name="${conn_name#card*-}"

        local status
        status="$(cat "${conn_dir}status" 2>/dev/null || echo 'disconnected')"
        [[ "$status" == "connected" ]] || continue

        # EDID → resolution (if edid-decode available)
        local modes
        modes="$(cat "${conn_dir}modes" 2>/dev/null | head -5 | tr '\n' ' ')"

        # Check VRR capability
        local vrr_capable=0
        [[ -f "${conn_dir}vrr_capable" ]] && \
            vrr_capable="$(cat "${conn_dir}vrr_capable" 2>/dev/null || echo 0)"

        printf 'name=%s\n' "$conn_name"
        printf 'status=connected\n'
        printf 'modes=%s\n' "${modes:-unknown}"
        printf 'vrr_capable=%s\n' "$vrr_capable"
        printf 'hdr=%s\n' \
            "$([ -f "${conn_dir}hdr_output_metadata" ] && echo 'capable' || echo 'no')"
        printf -- '---\n'
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  RENDER MONITOR BLOCK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_mon_render_from_hyprctl() {
    local monitor_data
    monitor_data="$(_mon_via_hyprctl 2>/dev/null || echo '')"

    [[ -z "$monitor_data" ]] && return 1

    local -A cur=()
    local mon_count=0

    while IFS='=' read -r key val; do
        key="${key// /}"
        if [[ "$key" == "---" ]]; then
            if [[ ${#cur[@]} -gt 0 ]]; then
                (( mon_count++ )) || true
                local name="${cur[name]:-?}"
                local model="${cur[model]:-Unknown}"
                local res="${cur[resolution]:-?}"
                local hz="${cur[refresh]:-?}"
                local scale="${cur[scale]:-1}"
                local pos="${cur[position]:-0,0}"
                local vrr="${cur[vrr]:-no}"
                local hdr="${cur[hdr]:-no}"
                local active="${cur[active]:-yes}"

                local mon_color
                [[ "$active" == "yes" ]] && mon_color="$(_hw_green)" || \
                    mon_color="$(_hw_dim)"

                printf '\n  %s%s%s  %s%s%s\n' \
                    "$mon_color" "$(_hw_bold)" "🖥️ " \
                    "$(_hw_sky)$(_hw_bold)" "$name" "$(_hw_r)"

                hw_kv "Model"       "$model"
                hw_kv "Resolution"  "$res"
                hw_kv "Refresh"     "${hz}Hz"
                hw_kv "Scale"       "${scale}x"
                hw_kv "Position"    "${pos}  (X,Y)"
                hw_kv "VRR"         "$vrr"
                hw_kv "HDR"         "$hdr"
                hw_kv "Active"      "$active"
            fi
            cur=()
        elif [[ -n "$key" ]]; then
            cur["$key"]="$val"
        fi
    done <<< "$monitor_data"

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔷  MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ash_hw_monitor() {
    local short=0
    for arg in "${@:-}"; do
        [[ "$arg" == "--short" ]] && short=1
    done

    hw_section "🖥️ " "Monitors / Displays" "$(_hw_lavender)"

    # Try backends in order of preference
    if _mon_render_from_hyprctl; then
        printf '\n  %ssource: hyprctl%s\n' "$(_hw_dim)" "$(_hw_r)"

    elif _mon_via_wlr_randr &>/dev/null; then
        hw_section "📐" "wlr-randr" "$(_hw_blue)"
        _mon_via_wlr_randr 2>/dev/null | while IFS= read -r line; do
            printf '  %s%s%s\n' "$(_hw_sky)" "$line" "$(_hw_r)"
        done
        printf '\n  %ssource: wlr-randr%s\n' "$(_hw_dim)" "$(_hw_r)"

    elif _mon_via_xrandr &>/dev/null; then
        hw_section "📐" "xrandr (X11)" "$(_hw_blue)"
        _mon_via_xrandr 2>/dev/null | while IFS= read -r line; do
            printf '  %s%s%s\n' "$(_hw_sky)" "$line" "$(_hw_r)"
        done

    else
        hw_section "📋" "DRM sysfs" "$(_hw_peach)"
        local -A cur=()

        while IFS='=' read -r key val; do
            key="${key// /}"
            if [[ "$key" == "---" ]]; then
                if [[ ${#cur[@]} -gt 0 ]]; then
                    printf '\n  %s🖥️  %s%s\n' "$(_hw_sky)$(_hw_bold)" \
                        "${cur[name]:-?}" "$(_hw_r)"
                    hw_kv "Status"       "connected"
                    hw_kv "Modes"        "${cur[modes]:-?}"
                    hw_kv "VRR capable"  "${cur[vrr_capable]:-?}"
                    hw_kv "HDR"          "${cur[hdr]:-?}"
                fi
                cur=()
            elif [[ -n "$key" ]]; then
                cur["$key"]="$val"
            fi
        done < <(_mon_via_sysfs 2>/dev/null)

        printf '\n  %ssource: /sys/class/drm%s\n' "$(_hw_dim)" "$(_hw_r)"
    fi

    hw_divider
}
