#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI CALCULATOR                              ║
# ║           Multi-backend calculator with history and unit conversion        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly CALC_HISTORY="${CACHE_DIR}/calc-history.txt"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"
readonly MAX_HISTORY=50

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🧮 CALCULATION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

detect_calc_backend() {
    if command -v qalc &>/dev/null; then echo "qalc"
    elif command -v bc &>/dev/null; then echo "bc"
    elif command -v python3 &>/dev/null; then echo "python3"
    else echo "none"
    fi
}

calculate() {
    local expr="$1"
    local backend
    backend=$(detect_calc_backend)

    case "${backend}" in
        qalc)
            # qalculate — most powerful, handles units, currencies, functions
            local result
            result=$(qalc -t "${expr}" 2>/dev/null \
                | tail -1 \
                | sed 's/^[[:space:]]*//')
            echo "${result}"
            ;;

        bc)
            # bc — standard, handles math
            local result
            result=$(echo "scale=10; ${expr}" | bc -l 2>/dev/null)
            if [[ -n "${result}" ]]; then
                # Remove trailing zeros
                echo "${result}" | sed 's/\.0*$//' | sed 's/\(\.[0-9]*[1-9]\)0*/\1/'
            fi
            ;;

        python3)
            # Python — fallback, handles most math
            local result
            result=$(python3 -c "
import math
from math import *
try:
    result = eval('${expr}')
    if isinstance(result, float) and result == int(result):
        print(int(result))
    elif isinstance(result, float):
        print(f'{result:.10g}')
    else:
        print(result)
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
            echo "${result}"
            ;;

        none)
            echo "No calculator backend found"
            echo "Install: qalculate-gtk (paru -S qalculate-gtk) or bc"
            ;;
    esac
}

save_history() {
    local expr="$1"
    local result="$2"
    mkdir -p "${CACHE_DIR}"

    local entry="${expr} = ${result}"
    echo "${entry}" >> "${CALC_HISTORY}" 2>/dev/null || true

    # Keep limited history
    if [[ -f "${CALC_HISTORY}" ]]; then
        tail -"${MAX_HISTORY}" "${CALC_HISTORY}" > "${CALC_HISTORY}.tmp"
        mv "${CALC_HISTORY}.tmp" "${CALC_HISTORY}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════

build_prompt() {
    local backend
    backend=$(detect_calc_backend)
    local prompt="🧮 Calc (${backend})"

    # Include history items
    local history_entries=""
    if [[ -f "${CALC_HISTORY}" ]]; then
        history_entries=$(tac "${CALC_HISTORY}" | head -10 | while IFS= read -r line; do
            echo "📜 ${line}"
        done)
    fi

    echo "${history_entries}"
}

main() {
    mkdir -p "${CACHE_DIR}/logs"

    local backend
    backend=$(detect_calc_backend)

    # Build history for display
    local history_items
    history_items=$(build_prompt)

    # Show Rofi with history
    local input
    input=$(echo "${history_items}" | rofi \
        -dmenu \
        -i \
        -p "🧮 Calculate" \
        -theme-str '
            window { width: 550px; }
            listview { lines: 10; }
            inputbar { children: [prompt, entry]; }
        ' \
        -mesg "Backend: ${backend} | Enter expression or pick from history" \
        2>/dev/null) || {
        log "INFO" "Calculator cancelled"
        exit 0
    }

    # Strip history prefix
    local expr
    expr=$(echo "${input}" | sed 's/^📜 //' | sed 's/ = .*//')

    if [[ -z "${expr}" ]]; then
        exit 0
    fi

    # Calculate
    local result
    result=$(calculate "${expr}")

    if [[ -z "${result}" ]]; then
        notify-send "🧮 Calculator" "No result for: ${expr}" \
            --app-name="ASH Calc" --expire-time=3000 2>/dev/null || true
        exit 0
    fi

    # Save to history
    save_history "${expr}" "${result}"

    # Copy to clipboard
    echo -n "${result}" | wl-copy 2>/dev/null || true

    # Show result
    local display="${expr} = ${result}"

    local action
    action=$(echo -e "✅ ${display}\n📋 Copy only\n🔄 Continue calculating\n❌ Dismiss" \
        | rofi \
            -dmenu \
            -i \
            -p "🧮 Result" \
            -theme-str '
                window { width: 500px; }
                listview { lines: 4; }
            ' \
            2>/dev/null) || exit 0

    case "${action}" in
        "✅ "*) echo -n "${result}" | wl-copy 2>/dev/null && \
            notify-send "🧮 Copied" "${display}" --app-name="ASH Calc" --expire-time=2000 2>/dev/null || true ;;
        "📋 Copy only") echo -n "${result}" | wl-copy 2>/dev/null || true ;;
        "🔄 Continue"*) main ;;
    esac

    log "INFO" "Calc: ${expr} = ${result}"
}

main "$@"