#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI TRANSLATOR                              ║
# ║           Quick text translation via multiple backends                     ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly TRANSLATE_HISTORY="${CACHE_DIR}/translate-history.txt"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🌐 LANGUAGE PAIRS
# ═══════════════════════════════════════════════════════════════════════════════

readonly -a LANG_PAIRS=(
    "en→es  (English → Spanish)"
    "en→fr  (English → French)"
    "en→de  (English → German)"
    "en→ja  (English → Japanese)"
    "en→zh  (English → Chinese)"
    "en→ar  (English → Arabic)"
    "en→pt  (English → Portuguese)"
    "en→ru  (English → Russian)"
    "en→it  (English → Italian)"
    "en→ko  (English → Korean)"
    "auto→en (Auto-detect → English)"
)

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 TRANSLATION BACKENDS
# ═══════════════════════════════════════════════════════════════════════════════

translate_with_curl() {
    local text="$1"
    local source="${2:-auto}"
    local target="${3:-en}"

    # URL encode text
    local encoded
    encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${text}'''))" 2>/dev/null)

    # Use Google Translate API (free tier)
    local result
    result=$(curl -sL \
        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=${source}&tl=${target}&dt=t&q=${encoded}" \
        2>/dev/null \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    result = ''.join([item[0] for item in data[0] if item[0]])
    print(result)
except:
    print('')
" 2>/dev/null)

    echo "${result}"
}

translate_with_trans() {
    local text="$1"
    local target="${2:-en}"

    if command -v trans &>/dev/null; then
        trans -brief :"${target}" "${text}" 2>/dev/null
    else
        echo ""
    fi
}

translate_text() {
    local text="$1"
    local source="${2:-auto}"
    local target="${3:-en}"

    # Try trans first (more reliable)
    local result
    result=$(translate_with_trans "${text}" "${target}")

    # Fallback to curl-based
    if [[ -z "${result}" ]]; then
        result=$(translate_with_curl "${text}" "${source}" "${target}")
    fi

    echo "${result}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 💾 HISTORY
# ═══════════════════════════════════════════════════════════════════════════════

save_history() {
    local entry="$1"
    mkdir -p "${CACHE_DIR}"
    echo "${entry}" >> "${TRANSLATE_HISTORY}" 2>/dev/null || true
    tail -30 "${TRANSLATE_HISTORY}" > "${TRANSLATE_HISTORY}.tmp" 2>/dev/null
    mv "${TRANSLATE_HISTORY}.tmp" "${TRANSLATE_HISTORY}" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "${CACHE_DIR}/logs"

    # Step 1: Select language pair
    local lang_pair
    lang_pair=$(printf '%s\n' "${LANG_PAIRS[@]}" | rofi \
        -dmenu \
        -i \
        -p "🌐 Language" \
        -theme-str '
            window { width: 480px; }
            listview { lines: 12; }
        ' \
        2>/dev/null) || {
        log "INFO" "Translate cancelled (lang select)"
        exit 0
    }

    # Parse language pair
    local src_lang tgt_lang
    src_lang=$(echo "${lang_pair}" | cut -d'→' -f1 | tr -d ' ')
    tgt_lang=$(echo "${lang_pair}" | cut -d'→' -f2 | awk '{print $1}' | tr -d ' ()')

    # Step 2: Get clipboard content as default
    local clipboard_text=""
    clipboard_text=$(wl-paste --no-newline 2>/dev/null | head -c 500 || echo "")

    # Step 3: Input text
    local input_text
    input_text=$(echo "${clipboard_text}" | rofi \
        -dmenu \
        -p "✍️  Text to translate" \
        -theme-str '
            window { width: 600px; }
            listview { lines: 0; }
        ' \
        2>/dev/null) || {
        log "INFO" "Translate cancelled (text input)"
        exit 0
    }

    if [[ -z "${input_text}" ]]; then
        exit 0
    fi

    # Step 4: Translate
    notify-send "🌐 Translating..." \
        "${input_text:0:50}..." \
        --app-name="ASH Translate" \
        --expire-time=2000 \
        2>/dev/null || true

    local result
    result=$(translate_text "${input_text}" "${src_lang}" "${tgt_lang}")

    if [[ -z "${result}" ]]; then
        notify-send "🌐 Translation Failed" \
            "Could not translate text. Check internet connection." \
            --app-name="ASH Translate" \
            --urgency=normal \
            2>/dev/null || true
        exit 1
    fi

    # Step 5: Show result
    local entry="${input_text} → ${result}"
    save_history "${entry}"

    local action
    action=$(echo -e "📋 ${result}\n──────────\nOriginal: ${input_text}\nLang: ${src_lang} → ${tgt_lang}\n──────────\n📋 Copy translation\n🔄 Translate again\n❌ Close" \
        | rofi \
            -dmenu \
            -p "🌐 Translation" \
            -theme-str '
                window { width: 600px; }
                listview { lines: 8; }
            ' \
            2>/dev/null) || exit 0

    case "${action}" in
        "📋 Copy"*) echo -n "${result}" | wl-copy 2>/dev/null || true ;;
        "🔄 "*) main ;;
    esac

    log "INFO" "Translate: ${src_lang}→${tgt_lang} '${input_text:0:30}' = '${result:0:30}'"
}

main "$@"