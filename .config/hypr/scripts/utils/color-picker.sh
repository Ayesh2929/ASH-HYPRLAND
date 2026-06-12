#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — COLOR PICKER                                 ║
# ║           Screen color picker with history and format conversion           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly HISTORY_FILE="${CACHE_DIR}/colors/picked-history.txt"
readonly LOG_FILE="${CACHE_DIR}/logs/color-picker.log"
readonly MAX_HISTORY=50

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 COLOR CONVERSION
# ═══════════════════════════════════════════════════════════════════════════════

hex_to_rgb() {
    local hex="${1#\#}"
    local r g b
    r=$(( 16#${hex:0:2} ))
    g=$(( 16#${hex:2:2} ))
    b=$(( 16#${hex:4:2} ))
    echo "${r} ${g} ${b}"
}

hex_to_hsl() {
    local hex="${1#\#}"
    python3 -c "
import colorsys
r, g, b = int('${hex:0:2}', 16)/255, int('${hex:2:2}', 16)/255, int('${hex:4:2}', 16)/255
h, l, s = colorsys.rgb_to_hls(r, g, b)
print(f'{h*360:.0f}°, {s*100:.0f}%, {l*100:.0f}%')
" 2>/dev/null || echo "N/A"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 PICK COLOR
# ═══════════════════════════════════════════════════════════════════════════════

pick_color() {
    local format="${1:-hex}"

    if ! command -v hyprpicker &>/dev/null; then
        notify-send "🎨 Color Picker" \
            "hyprpicker not installed\nparu -S hyprpicker" \
            --app-name="ASH Color" \
            --urgency=normal \
            2>/dev/null || true
        exit 1
    fi

    # Pick color
    local color
    color=$(hyprpicker --autocopy --format=hex 2>/dev/null) || {
        log "INFO" "Color pick cancelled"
        exit 0
    }

    if [[ -z "${color}" ]]; then
        exit 0
    fi

    # Store based on format
    local output="${color}"
    local display_text="${color}"

    case "${format}" in
        hex)
            output="${color}"
            ;;
        rgb)
            local r g b
            read -r r g b <<< "$(hex_to_rgb "${color}")"
            output="rgb(${r}, ${g}, ${b})"
            display_text="${output}"
            ;;
        hsl)
            local hsl
            hsl=$(hex_to_hsl "${color}")
            output="hsl(${hsl})"
            display_text="${output}"
            ;;
        rgba)
            local r g b
            read -r r g b <<< "$(hex_to_rgb "${color}")"
            output="rgba(${r}, ${g}, ${b}, 1.0)"
            display_text="${output}"
            ;;
        all)
            # Show all formats
            local r g b hsl_val
            read -r r g b <<< "$(hex_to_rgb "${color}")"
            hsl_val=$(hex_to_hsl "${color}")
            display_text="HEX:  ${color}\nRGB:  rgb(${r}, ${g}, ${b})\nHSL:  hsl(${hsl_val})\nRGBA: rgba(${r}, ${g}, ${b}, 1.0)"

            # Show picker for format selection
            local chosen_format
            chosen_format=$(printf "HEX: %s\nRGB: rgb(%s, %s, %s)\nHSL: hsl(%s)\nRGBA: rgba(%s, %s, %s, 1.0)" \
                "${color}" "${r}" "${g}" "${b}" "${hsl_val}" "${r}" "${g}" "${b}" \
                | rofi \
                    -dmenu \
                    -i \
                    -p "🎨 Select Format" \
                    -theme-str 'window { width: 480px; } listview { lines: 4; }' \
                    2>/dev/null) || {
                # Default to hex
                echo -n "${color}" | wl-copy 2>/dev/null || true
                log "INFO" "Color: ${color} (hex)"
                return 0
            }

            output=$(echo "${chosen_format}" | awk -F': ' '{print $2}')
            ;;
    esac

    # Copy to clipboard
    echo -n "${output}" | wl-copy 2>/dev/null || true

    # Save to history
    mkdir -p "${CACHE_DIR}/colors"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} ${color} ${output}" >> "${HISTORY_FILE}" 2>/dev/null || true

    # Keep limited history
    if [[ -f "${HISTORY_FILE}" ]]; then
        tail -"${MAX_HISTORY}" "${HISTORY_FILE}" > "${HISTORY_FILE}.tmp" 2>/dev/null
        mv "${HISTORY_FILE}.tmp" "${HISTORY_FILE}" 2>/dev/null || true
    fi

    # Show notification with color preview
    local r g b
    read -r r g b <<< "$(hex_to_rgb "${color}")"

    notify-send "🎨 Color Picked" \
        "${output} (copied to clipboard)" \
        --app-name="ASH Color Picker" \
        --expire-time=3000 \
        2>/dev/null || true

    log "INFO" "Color picked: ${color} → ${output}"
    echo "${output}"
}

show_history() {
    if [[ ! -f "${HISTORY_FILE}" ]] || [[ ! -s "${HISTORY_FILE}" ]]; then
        notify-send "🎨 Color History" \
            "No colors in history yet\nPick a color first!" \
            --app-name="ASH Color" \
            --expire-time=3000 \
            2>/dev/null || true
        return 0
    fi

    local selected
    selected=$(tac "${HISTORY_FILE}" 2>/dev/null | rofi \
        -dmenu \
        -i \
        -p "🎨 Color History" \
        -theme-str '
            window { width: 560px; }
            listview { columns: 1; lines: 12; }
            element { font-family: "JetBrainsMono Nerd Font"; font-size: 12px; }
        ' \
        2>/dev/null) || {
        log "INFO" "Color history cancelled"
        return 0
    }

    # Extract the color value (last field)
    local color
    color=$(echo "${selected}" | awk '{print $NF}')

    if [[ -n "${color}" ]]; then
        echo -n "${color}" | wl-copy 2>/dev/null || true
        notify-send "🎨 Color Copied" \
            "${color}" \
            --app-name="ASH Color" \
            --expire-time=2000 \
            2>/dev/null || true
        log "INFO" "History copy: ${color}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-pick}"
    local format="${2:-hex}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        pick | "")      pick_color "${format}" ;;
        history | h)   show_history ;;
        hex)            pick_color "hex" ;;
        rgb)            pick_color "rgb" ;;
        hsl)            pick_color "hsl" ;;
        rgba)           pick_color "rgba" ;;
        all)            pick_color "all" ;;
        clear)
            rm -f "${HISTORY_FILE}"
            notify-send "🎨 Color History" "Cleared" --app-name="ASH Color" \
                --expire-time=2000 2>/dev/null || true
            ;;
        *)
            echo "Usage: color-picker.sh [pick|history|hex|rgb|hsl|rgba|all|clear]"
            exit 1
            ;;
    esac
}

main "$@"