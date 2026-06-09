#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — MONITOR LAYOUT MANAGER                       ║
# ║           Auto-detect, Rofi picker, common layout presets                  ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: monitor-layout.sh [ACTION]
#
# ACTIONS:
#   (none)    — Rofi layout picker
#   auto      — Auto-configure detected monitors
#   single    — Use only primary monitor
#   extend    — Extend desktop to all monitors
#   mirror    — Mirror all monitors
#   list      — List connected monitors
#   rotate    — Rotate active monitor 90°
#   info      — Show monitor info

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/monitors.log"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ MONITOR DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

get_monitors() {
    hyprctl monitors -j 2>/dev/null \
        | jq -r '.[] | .name' \
        2>/dev/null
}

get_monitor_count() {
    get_monitors | wc -l
}

get_monitor_info() {
    hyprctl monitors -j 2>/dev/null \
        | jq -r '.[] | "\(.name) \(.width)x\(.height)@\(.refreshRate) pos:\(.x),\(.y) scale:\(.scale)"' \
        2>/dev/null
}

get_primary_monitor() {
    hyprctl monitors -j 2>/dev/null \
        | jq -r '.[] | select(.focused == true) | .name' \
        2>/dev/null \
        | head -1
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📐 LAYOUT PRESETS
# ═══════════════════════════════════════════════════════════════════════════════

layout_auto() {
    info "Auto-configuring monitors..."

    local monitors=()
    while IFS= read -r mon; do
        monitors+=("${mon}")
    done < <(get_monitors)

    local count=${#monitors[@]}
    info "Found ${count} monitor(s): ${monitors[*]}"

    case "${count}" in
        0)
            warn "No monitors detected"
            ;;
        1)
            info "Single monitor setup"
            hyprctl keyword monitor "${monitors[0]},preferred,0x0,1" 2>/dev/null
            ;;
        2)
            info "Dual monitor setup — extending right"
            hyprctl keyword monitor "${monitors[0]},preferred,0x0,1" 2>/dev/null
            hyprctl keyword monitor "${monitors[1]},preferred,auto,1" 2>/dev/null
            ;;
        3)
            info "Triple monitor setup"
            hyprctl keyword monitor "${monitors[0]},preferred,0x0,1" 2>/dev/null
            hyprctl keyword monitor "${monitors[1]},preferred,auto,1" 2>/dev/null
            hyprctl keyword monitor "${monitors[2]},preferred,auto,1" 2>/dev/null
            ;;
        *)
            info "Multi-monitor: using auto-detect"
            for mon in "${monitors[@]}"; do
                hyprctl keyword monitor "${mon},preferred,auto,1" 2>/dev/null
            done
            ;;
    esac

    notify-send "🖥️ Monitor Layout" \
        "Auto-configured ${count} monitor(s)" \
        --app-name="ASH Display" \
        --expire-time=2000 \
        2>/dev/null || true

    ok "Auto-configuration complete"
    log "INFO" "Auto-configured ${count} monitors"
}

layout_single() {
    info "Single monitor mode..."
    local primary
    primary=$(get_primary_monitor)

    local monitors=()
    while IFS= read -r mon; do
        monitors+=("${mon}")
    done < <(get_monitors)

    for mon in "${monitors[@]}"; do
        if [[ "${mon}" == "${primary}" ]]; then
            hyprctl keyword monitor "${mon},preferred,0x0,1" 2>/dev/null
        else
            hyprctl keyword monitor "${mon},disable" 2>/dev/null
        fi
    done

    notify-send "🖥️ Single Monitor" \
        "Using: ${primary}" \
        --app-name="ASH Display" --expire-time=2000 2>/dev/null || true

    ok "Single monitor: ${primary}"
    log "INFO" "Single monitor: ${primary}"
}

layout_extend() {
    info "Extending to all monitors..."

    local monitors=()
    while IFS= read -r mon; do
        monitors+=("${mon}")
    done < <(get_monitors)

    local x_offset=0
    for mon in "${monitors[@]}"; do
        local res
        res=$(hyprctl monitors -j 2>/dev/null \
            | jq -r --arg n "${mon}" '.[] | select(.name == $n) | "\(.width)x\(.height)@\(.refreshRate)"' \
            | head -1)

        hyprctl keyword monitor "${mon},${res:-preferred},${x_offset}x0,1" 2>/dev/null
        local width
        width=$(echo "${res}" | grep -oP '^\d+')
        x_offset=$(( x_offset + ${width:-1920} ))
    done

    notify-send "🖥️ Extended Display" \
        "${#monitors[@]} monitors side by side" \
        --app-name="ASH Display" --expire-time=2000 2>/dev/null || true

    ok "Extended to ${#monitors[@]} monitors"
    log "INFO" "Extended: ${monitors[*]}"
}

layout_mirror() {
    info "Mirroring all monitors..."

    local monitors=()
    while IFS= read -r mon; do
        monitors+=("${mon}")
    done < <(get_monitors)

    local primary="${monitors[0]}"
    hyprctl keyword monitor "${primary},preferred,0x0,1" 2>/dev/null

    for (( i=1; i<${#monitors[@]}; i++ )); do
        hyprctl keyword monitor "${monitors[$i]},preferred,0x0,1,mirror,${primary}" 2>/dev/null
    done

    notify-send "🖥️ Mirror Mode" \
        "All monitors mirroring ${primary}" \
        --app-name="ASH Display" --expire-time=2000 2>/dev/null || true

    ok "Mirror mode: ${primary}"
    log "INFO" "Mirror: ${monitors[*]}"
}

rotate_monitor() {
    local mon="${1:-}"
    [[ -z "${mon}" ]] && mon=$(get_primary_monitor)

    # Get current transform
    local current_transform
    current_transform=$(hyprctl monitors -j 2>/dev/null \
        | jq -r --arg n "${mon}" '.[] | select(.name == $n) | .transform' \
        | head -1)

    # Cycle through: 0 (normal) → 1 (90°) → 2 (180°) → 3 (270°) → 0
    local new_transform=$(( (${current_transform:-0} + 1) % 4 ))

    hyprctl keyword monitor "${mon},transform,${new_transform}" 2>/dev/null

    local rotation_name
    case "${new_transform}" in
        0) rotation_name="Normal (0°)" ;;
        1) rotation_name="90° CW" ;;
        2) rotation_name="180°" ;;
        3) rotation_name="270° CW" ;;
    esac

    notify-send "🖥️ Monitor Rotated" \
        "${mon}: ${rotation_name}" \
        --app-name="ASH Display" --expire-time=2000 2>/dev/null || true

    ok "Rotated ${mon} to ${rotation_name}"
    log "INFO" "Rotated ${mon}: transform ${new_transform}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ROFI LAYOUT PICKER
# ═══════════════════════════════════════════════════════════════════════════════

rofi_picker() {
    local count
    count=$(get_monitor_count)

    local options=(
        "🤖 Auto-Configure  — Detect and set optimal layout"
        "🖥️ Single Monitor  — Use only primary display"
        "🔀 Extend Desktop  — All monitors side by side"
        "📺 Mirror Displays — Clone to all monitors"
        "🔄 Rotate Monitor  — Rotate active display 90°"
        "📊 Monitor Info    — Show display details"
        "📁 Open in nwg-displays — Advanced configuration"
    )

    local selected
    selected=$(printf '%s\n' "${options[@]}" | rofi \
        -dmenu \
        -i \
        -p "🖥️ Monitor Layout (${count} connected)" \
        -theme-str 'window { width: 550px; }' \
        -theme-str 'listview { lines: 7; }' \
        2>/dev/null) || {
        info "Picker cancelled"
        return 0
    }

    case "${selected}" in
        *Auto*)    layout_auto ;;
        *Single*)  layout_single ;;
        *Extend*)  layout_extend ;;
        *Mirror*)  layout_mirror ;;
        *Rotate*)  rotate_monitor ;;
        *Info*)    show_info ;;
        *nwg*)     nwg-displays 2>/dev/null & disown ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# ℹ️ MONITOR INFO
# ═══════════════════════════════════════════════════════════════════════════════

show_info() {
    local info_text
    info_text=$(get_monitor_info)

    echo ""
    echo "  🖥️ Connected Monitors"
    echo "  ─────────────────────────────"
    echo "${info_text}" | while IFS= read -r line; do
        echo "  ${line}"
    done
    echo ""

    notify-send "🖥️ Monitor Info" \
        "${info_text}" \
        --app-name="ASH Display" \
        --expire-time=6000 \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-picker}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        picker | "")  rofi_picker ;;
        auto)      layout_auto ;;
        single)    layout_single ;;
        extend)    layout_extend ;;
        mirror)    layout_mirror ;;
        rotate)    rotate_monitor "${2:-}" ;;
        list)
            echo "Connected monitors:"
            get_monitors
            ;;
        info)      show_info ;;
        count)     get_monitor_count ;;
        *)
            echo "Usage: monitor-layout.sh [picker|auto|single|extend|mirror|rotate|list|info]"
            exit 1
            ;;
    esac
}

main "$@"