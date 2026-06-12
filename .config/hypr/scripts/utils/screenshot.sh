#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SCREENSHOT SYSTEM                             ║
# ║           8 capture modes with editing, OCR, clipboard support              ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: screenshot.sh [MODE] [OPTIONS]
#
# MODES:
#   full     — Capture entire screen
#   area     — Interactive area selection (slurp)
#   window   — Capture active/selected window
#   monitor  — Capture specific monitor
#   edit     — Area screenshot → open in swappy editor
#   ocr      — Area screenshot → extract text (tesseract)
#   color    — Pick color from screen (hyprpicker)
#   delay N  — Delayed screenshot (N seconds)

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# 📌 CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SAVE_DIR="${HOME}/Pictures/Screenshots"
readonly EDIT_DIR="${HOME}/Pictures/Edited"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/screenshot.log"

# File naming
readonly TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
readonly FILENAME_PREFIX="screenshot"

# Colors for OSD
readonly GREEN='\033[92m'
readonly CYAN='\033[96m'
readonly YELLOW='\033[93m'
readonly RED='\033[91m'
readonly RESET='\033[0m'

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

init() {
    mkdir -p "${SAVE_DIR}" "${EDIT_DIR}" "${CACHE_DIR}/logs"
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true
}

notify_success() {
    local file="$1"
    local mode="${2:-screenshot}"
    local basename
    basename=$(basename "${file}")

    notify-send "📸 Screenshot" \
        "${mode^}: ${basename}" \
        --icon="${file}" \
        --app-name="ASH Screenshot" \
        --expire-time=4000 \
        --action="open:Open" \
        --action="edit:Edit" \
        2>/dev/null || true

    # Copy to clipboard
    wl-copy < "${file}" 2>/dev/null || true
    log "OK" "Screenshot saved: ${file}"
}

notify_error() {
    notify-send "📸 Screenshot Failed" \
        "$*" \
        --icon=dialog-error \
        --app-name="ASH Screenshot" \
        --urgency=critical \
        2>/dev/null || true
    log "ERROR" "$*"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ✅ DEPENDENCY CHECK
# ═══════════════════════════════════════════════════════════════════════════════

check_deps() {
    local missing=()

    command -v grim    &>/dev/null || missing+=("grim")
    command -v slurp   &>/dev/null || missing+=("slurp")

    if (( ${#missing[@]} > 0 )); then
        notify_error "Missing: ${missing[*]}"
        echo -e "${RED}Missing dependencies: ${missing[*]}${RESET}" >&2
        echo "Install: sudo pacman -S ${missing[*]}"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📸 CAPTURE MODES
# ═══════════════════════════════════════════════════════════════════════════════

# Full screen capture
capture_full() {
    local output="${SAVE_DIR}/${FILENAME_PREFIX}_full_${TIMESTAMP}.png"

    grim "${output}" 2>/dev/null || {
        notify_error "Full capture failed"
        return 1
    }

    notify_success "${output}" "Full screen"
    echo "${output}"
}

# Interactive area selection
capture_area() {
    local output="${SAVE_DIR}/${FILENAME_PREFIX}_area_${TIMESTAMP}.png"

    # Get geometry from slurp
    local geometry
    geometry=$(slurp \
        -d \
        -b "1e1e2eaa" \
        -c "cba6f7ff" \
        -s "cba6f71a" \
        -w 2 \
        -f "%x %y %w %h" \
        2>/dev/null) || {
        log "INFO" "Area selection cancelled"
        return 0
    }

    grim -g "${geometry}" "${output}" 2>/dev/null || {
        notify_error "Area capture failed"
        return 1
    }

    notify_success "${output}" "Area"
    echo "${output}"
}

# Active window capture
capture_window() {
    local output="${SAVE_DIR}/${FILENAME_PREFIX}_window_${TIMESTAMP}.png"

    # Get active window geometry from Hyprland
    local window_data
    window_data=$(hyprctl activewindow -j 2>/dev/null)

    if [[ -z "${window_data}" ]]; then
        notify_error "No active window found"
        return 1
    fi

    local x y w h
    x=$(echo "${window_data}" | jq '.at[0]')
    y=$(echo "${window_data}" | jq '.at[1]')
    w=$(echo "${window_data}" | jq '.size[0]')
    h=$(echo "${window_data}" | jq '.size[1]')

    grim -g "${x},${y} ${w}x${h}" "${output}" 2>/dev/null || {
        notify_error "Window capture failed"
        return 1
    }

    notify_success "${output}" "Window"
    echo "${output}"
}

# Monitor capture
capture_monitor() {
    local output="${SAVE_DIR}/${FILENAME_PREFIX}_monitor_${TIMESTAMP}.png"

    # Get active monitor
    local monitor
    monitor=$(hyprctl monitors -j 2>/dev/null \
        | jq -r '.[] | select(.focused == true) | .name' \
        2>/dev/null)

    if [[ -z "${monitor}" ]]; then
        # Fallback: capture all monitors
        grim "${output}" 2>/dev/null || {
            notify_error "Monitor capture failed"
            return 1
        }
    else
        grim -o "${monitor}" "${output}" 2>/dev/null || {
            notify_error "Monitor capture failed"
            return 1
        }
    fi

    notify_success "${output}" "Monitor: ${monitor:-all}"
    echo "${output}"
}

# Area screenshot → edit in swappy
capture_edit() {
    local output="${EDIT_DIR}/${FILENAME_PREFIX}_edit_${TIMESTAMP}.png"

    local geometry
    geometry=$(slurp \
        -d \
        -b "1e1e2eaa" \
        -c "cba6f7ff" \
        -s "cba6f71a" \
        -w 2 \
        2>/dev/null) || {
        log "INFO" "Edit selection cancelled"
        return 0
    }

    if command -v swappy &>/dev/null; then
        grim -g "${geometry}" - | swappy -f - -o "${output}" 2>/dev/null || {
            log "INFO" "Swappy edit cancelled or failed"
            return 0
        }
        notify_success "${output}" "Edited"
    elif command -v satty &>/dev/null; then
        grim -g "${geometry}" - | satty --filename - --output-filename "${output}" 2>/dev/null
        notify_success "${output}" "Edited"
    else
        # Fallback: just capture
        grim -g "${geometry}" "${output}" 2>/dev/null
        notify_success "${output}" "Area (no editor)"
    fi

    echo "${output}"
}

# OCR screenshot — extract text
capture_ocr() {
    if ! command -v tesseract &>/dev/null; then
        notify_error "tesseract not installed (paru -S tesseract tesseract-data-eng)"
        return 1
    fi

    local tmp_img
    tmp_img=$(mktemp /tmp/ash-ocr-XXXXXX.png)
    trap "rm -f ${tmp_img} ${tmp_img%.png}.txt" EXIT

    local geometry
    geometry=$(slurp \
        -d \
        -b "1e1e2eaa" \
        -c "89b4faff" \
        -s "89b4fa1a" \
        -w 2 \
        2>/dev/null) || {
        log "INFO" "OCR selection cancelled"
        return 0
    }

    grim -g "${geometry}" "${tmp_img}" 2>/dev/null || {
        notify_error "OCR capture failed"
        return 1
    }

    # Run OCR
    tesseract "${tmp_img}" "${tmp_img%.png}" \
        -l eng \
        --oem 3 \
        --psm 3 \
        2>/dev/null || {
        notify_error "OCR processing failed"
        return 1
    }

    local text_file="${tmp_img%.png}.txt"
    if [[ -f "${text_file}" ]]; then
        local extracted
        extracted=$(cat "${text_file}")

        if [[ -n "${extracted}" ]]; then
            # Copy to clipboard
            echo "${extracted}" | wl-copy 2>/dev/null

            notify-send "🔍 OCR Complete" \
                "Text copied to clipboard:\n${extracted:0:100}..." \
                --app-name="ASH Screenshot" \
                --expire-time=6000 \
                2>/dev/null || true

            log "INFO" "OCR extracted: ${extracted:0:50}"
        else
            notify_error "OCR found no text"
        fi
    fi
}

# Color picker from screen
capture_color() {
    if ! command -v hyprpicker &>/dev/null; then
        notify_error "hyprpicker not installed (paru -S hyprpicker)"
        return 1
    fi

    # Pick color
    local color
    color=$(hyprpicker --autocopy --format=hex 2>/dev/null) || {
        log "INFO" "Color pick cancelled"
        return 0
    }

    if [[ -n "${color}" ]]; then
        # Copy to clipboard
        echo "${color}" | wl-copy 2>/dev/null

        # Save to history
        local history_file="${HOME}/.cache/ash-dots/colors/picked-history.txt"
        mkdir -p "$(dirname "${history_file}")"
        echo "$(date '+%Y-%m-%d %H:%M:%S') ${color}" >> "${history_file}"

        # Show notification with color preview
        notify-send "🎨 Color Picked" \
            "Copied to clipboard: ${color}" \
            --app-name="ASH Screenshot" \
            --expire-time=3000 \
            2>/dev/null || true

        echo "${color}"
        log "INFO" "Color picked: ${color}"
    fi
}

# Delayed screenshot
capture_delay() {
    local delay="${1:-3}"
    local mode="${2:-full}"

    notify-send "📸 Screenshot" \
        "Taking ${mode} screenshot in ${delay} seconds..." \
        --app-name="ASH Screenshot" \
        --expire-time=$(( delay * 1000 )) \
        2>/dev/null || true

    # Countdown
    for (( i=delay; i>0; i-- )); do
        echo -e "  ${YELLOW}📸 ${i}...${RESET}"
        sleep 1
    done

    case "${mode}" in
        area)    capture_area ;;
        window)  capture_window ;;
        monitor) capture_monitor ;;
        *)       capture_full ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local mode="${1:-area}"
    shift || true

    init
    check_deps

    log "INFO" "Screenshot mode: ${mode}"

    case "${mode}" in
        full)    capture_full ;;
        area)    capture_area ;;
        window)  capture_window ;;
        monitor) capture_monitor ;;
        edit)    capture_edit ;;
        ocr)     capture_ocr ;;
        color)   capture_color ;;
        delay)   capture_delay "${1:-3}" "${2:-full}" ;;
        *)
            echo "Usage: screenshot.sh [full|area|window|monitor|edit|ocr|color|delay]"
            exit 1
            ;;
    esac
}

main "$@"