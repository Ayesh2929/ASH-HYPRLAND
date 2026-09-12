#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  📦 ASH PROGRESS-BAR ENGINE — Progress bar utilities for the ASH ecosystem     ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# A sourced library must not mutate the caller's shell options.
# `set -e` inside a sourced file silently aborts the *parent* script
# on the next non-zero test, which is a nightmare to debug.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

readonly ASH_PROGRESS_BAR_VERSION="5.0.0"

# Progress bar utilities
ash_progress_bar() {
    local current="${1:-0}"
    local total="${2:-100}"
    local width="${3:-50}"
    local style="${4:-dots}"
    local fill_char="${5:-█}"
    local empty_char="${6:-░}"

    if (( current > total )); then
        current="${total}"
    fi

    local percentage=$(( current * 100 / total ))
    local filled=$(( width * current / total ))
    local empty=$(( width - filled ))

    case "${style}" in
        dots)
            for (( i=1; i<=width; i++ )); do
                if (( i <= filled )); then
                    echo -n "${fill_char}"
                else
                    echo -n "."
                fi
            done
            ;;
        line)
            for (( i=1; i<=width; i++ )); do
                if (( i <= filled )); then
                    echo -n "${fill_char}"
                else
                    echo -n "-"
                fi
            done
            ;;
        circle)
            for (( i=1; i<=width; i++ )); do
                if (( i <= filled )); then
                    echo -n "○"
                else
                    echo -n "·"
                fi
            done
            ;;
        bounce)
            local bounce_offset=$(( (current * 2) % (width + 4) ))
            for (( i=1; i<=width; i++ )); do
                if (( i == bounce_offset )); then
                    echo -n "⚪"
                elif (( i <= filled )); then
                    echo -n "${fill_char}"
                else
                    echo -n "${empty_char}"
                fi
            done
            ;;
        *)
            for (( i=1; i<=filled; i++ )); do
                echo -n "${fill_char}"
            done
            for (( i=1; i<=empty; i++ )); do
                echo -n "${empty_char}"
            done
            ;;
    esac

    echo -n " ${percentage}%"
}

ash_progress_bar_indeterminate() {
    local width="${1:-50}"
    local style="${2:-dots}"

    case "${style}" in
        dots)
            while true; do
                echo -n "."
                sleep 0.1
                echo -n "\r"
                sleep 0.1
            done
            ;;
        line)
            while true; do
                echo -n "-"
                sleep 0.1
                echo -n "\r"
                sleep 0.1
            done
            ;;
        circle)
            while true; do
                echo -n "○"
                sleep 0.1
                echo -n "\r"
                sleep 0.1
            done
            ;;
        bounce)
            while true; do
                echo -n "⚪"
                sleep 0.1
                echo -n "\r"
                sleep 0.1
            done
            ;;
        *)
            while true; do
                echo -n "■"
                sleep 0.1
                echo -n "\r"
                sleep 0.1
            done
            ;;
    esac
}

ash_progress_bar_multi() {
    local width="${1:-60}"
    local items="${2}"
    local style="${3:-bars}"

    local item_count=0
    local i=0
    for item in ${items}; do
        (( item_count += 1 ))
    done

    local index=0
    while (( index < item_count )); do
        local completed=0
        local total=0

        # Extract completed/total from item (format: completed/total)
        local item="${!items}[${index}]"
        if [[ "${item}" =~ ^([0-9]+)/([0-9]+)$ ]]; then
            completed="${BASH_REMATCH[1]}"
            total="${BASH_REMATCH[2]}"
        else
            completed="0"
            total="1"
        fi

        echo -n " ${item} "
        if (( total > 0 )); then
            local percentage=$(( completed * 100 / total ))
            local filled=$(( width * completed / total ))
            local empty=$(( width - filled ))

            case "${style}" in
                bars)
                    for (( i=1; i<=filled; i++ )); do
                        echo -n "█"
                    done
                    for (( i=1; i<=empty; i++ )); do
                        echo -n "░"
                    done
                    ;;
                blocks)
                    for (( i=1; i<=filled/2; i++ )); do
                        echo -n "▓"
                    done
                    for (( i=1; i<=(empty+1)/2; i++ )); do
                        echo -n "░"
                    done
                    ;;
                minimal)
                    echo -n "[${filled}/${total}]"
                    ;;
                *)
                    echo -n " ${percentage}%"
                    ;;
            esac

            echo -n " "
        fi
        echo

        (( index += 1 ))
    done
}

ash_progress_bar_animated() {
    local current="${1:-0}"
    local total="${2:-100}"
    local width="${3:-50}"
    local animation="${4:-none}"
    local style="${5:-dots}"

    local percentage=$(( current * 100 / total ))
    local filled=$(( width * current / total ))

    echo -n "\r"
    case "${animation}" in
        rainbow)
            for (( i=1; i<=filled; i++ )); do
                local hue=$(( (i * 360 / filled) % 360 ))
                echo -n "\033[38;2 ${hue} 100 100m▄\033[0m"
            done
            for (( i=1; i<=(width - filled); i++ )); do
                echo -n "▄"
            done
            ;;
        gradient)
            for (( i=1; i<=width; i++ )); do
                local hue=$(( (i * 360 / width) % 360 ))
                if (( i <= filled )); then
                    echo -n "\033[38;2 ${hue} 100 100m█\033[0m"
                else
                    echo -n "\033[38;2 50 50 50m░\033[0m"
                fi
            done
            ;;
        sparkles)
            for (( i=1; i<=filled; i++ )); do
                if (( RANDOM % 5 == 0 )); then
                    echo -n "✨"
                else
                    echo -n "█"
                fi
            done
            for (( i=1; i<=(width - filled); i++ )); do
                if (( RANDOM % 10 == 0 )); then
                    echo -n "*"
                else
                    echo -n "░"
                fi
            done
            ;;
        *)
            ash_progress_bar "${current}" "${total}" "${width}" "${style}"
            ;;
    esac

    echo -n " ${percentage}%"
    echo -n "\r"
}

ash_progress_bar_spinner() {
    local current="${1:-0}"
    local total="${2:-100}"
    local width="${3:-50}"
    local style="${4:-dots}"
    local message="${5:-}"

    local spinner=("⠋" "⠋" "⠊" "⠊" "⠡" "⠡" "⠇" "⠇" "⠋" "⠋")

    echo -n "\r"
    if [[ -n "${message}" ]]; then
        echo -n "${message} "
    fi

    ash_progress_bar "${current}" "${total}" "${width}" "${style}"
    echo -n " "
    echo -n "${spinner[$(( (current * 10) % ${#spinner[@]} ))]}"

    if (( current >= total )); then
        echo
    fi
}

ash_progress_bar_status() {
    local current="${1:-0}"
    local total="${2:-100}"
    local width="${3:-50}"
    local message="${4:-Progress}"

    local percentage=$(( current * 100 / total ))
    local elapsed=0
    local eta=0

    echo -n "\r"
    echo -n "${message} "
    ash_progress_bar "${current}" "${total}" "${width}"
    echo -n " ${current}/${total} ("
    if (( current > 0 && total > 0 )); then
        eta=$(( (total - current) * (elapsed + 1) / current ))
    fi
    echo -n "ETA: ${eta}s)"
    echo -n "\r"
}

ash_progress_bar_counter() {
    local current="${1:-0}"
    local total="${2:-100}"
    local width="${3:-50}"
    local message="${4:-Counting}"
    local step="${5:-1}"

    while (( current <= total )); do
        echo -n "\r${message} "
        ash_progress_bar "${current}" "${total}" "${width}"
        echo -n " ${current}/${total}"
        sleep 0.1
        current=$(( current + step ))
    done
    echo
}

# Main entry point for progress-bar library
ash_progress_bar_main() {
    case "${1:-}" in
        init)
            echo "ASH Progress Bar Engine v${ASH_PROGRESS_BAR_VERSION} initialized"
            ;;
        status)
            echo "ASH Progress Bar Engine v${ASH_PROGRESS_BAR_VERSION}"
            echo "Functions: progress_bar, progress_bar_indeterminate, progress_bar_multi, progress_bar_animated, progress_bar_spinner, progress_bar_status, progress_bar_counter"
            ;;
        *)
            echo "Usage: ash_progress_bar <command>"
            echo "Commands: init, status"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_progress_bar_main "$@"
fi
