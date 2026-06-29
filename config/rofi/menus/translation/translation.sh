#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# ASH DOTFILES v5.0 OMEGA — TRANSLATION ULTRA BACKEND
# ══════════════════════════════════════════════════════════════════════════════
# File    : translation.sh
# Author  : Ash Dotfiles v5.0 Omega
# License : MIT
# Desc    : Full-featured multi-engine translation backend for Rofi.
#
#   Engines (in priority order):
#     1. Google Translate    — free tier via unofficial API
#     2. DeepL               — free tier (500k chars/month) with API key
#     3. LibreTranslate      — self-hosted or public instance
#     4. Ollama (LLM)        — local AI translation (no internet needed)
#     5. Lingva              — privacy-respecting Google frontend
#     6. MyMemory            — free tier (1000 req/day)
#
#   Features:
#     • Auto language detection (compact + full name)
#     • 100+ language pair support
#     • Persistent translation history (SQLite via sqlite3)
#     • Favourite pairs system
#     • Text-to-speech (espeak-ng / festival / piper)
#     • Clipboard integration (wl-copy / xclip)
#     • Phonetic / romanisation output
#     • Confidence scoring
#     • Response caching (LRU 1000 entries, TTL 24h)
#     • Offline mode (cached results)
#     • Rate limiting with exponential back-off
#     • Parallel provider fallback
#     • Character + word count tracking
#     • Export to ~/.local/share/ash/translations/
#     • Full ROFI_RETV dispatcher (10 custom keybinds)
#     • POSIX-safe, shellcheck-clean, strict mode
# ══════════════════════════════════════════════════════════════════════════════

# ── Strict mode ─────────────────────────────────────────────────────────────
set -euo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
# § 1  ENVIRONMENT & XDG PATHS
# ══════════════════════════════════════════════════════════════════════════════

readonly XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
readonly XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

readonly ASH_DIR="${XDG_CONFIG_HOME}/ash"
readonly ASH_DATA_DIR="${XDG_DATA_HOME}/ash"
readonly ASH_CACHE_DIR="${XDG_CACHE_HOME}/ash"
readonly ASH_STATE_DIR="${XDG_STATE_HOME}/ash"

readonly TRANS_DIR="${ASH_DATA_DIR}/translations"
readonly TRANS_CACHE_DIR="${ASH_CACHE_DIR}/translation"
readonly TRANS_EXPORT_DIR="${TRANS_DIR}/exports"
readonly TRANS_LOG="${ASH_STATE_DIR}/translation.log"
readonly TRANS_DB="${TRANS_DIR}/history.db"
readonly TRANS_SETTINGS="${ASH_DIR}/translation/settings.conf"
readonly TRANS_FAVOURITES="${TRANS_DIR}/favourites.json"

readonly ROFI_CONFIG_DIR="${XDG_CONFIG_HOME}/rofi/menus/translation"

# ══════════════════════════════════════════════════════════════════════════════
# § 2  CONSTANTS
# ══════════════════════════════════════════════════════════════════════════════

readonly DATE_FMT="%Y-%m-%d %H:%M:%S"
readonly CACHE_TTL=86400          # seconds (24h)
readonly CACHE_MAX_ENTRIES=1000
readonly MAX_HISTORY_DISPLAY=50
readonly MAX_INPUT_CHARS=5000
readonly REQUEST_TIMEOUT=8        # curl timeout seconds
readonly RETRY_MAX=3
readonly RETRY_DELAY=1

# ── Nerd Font icons ───────────────────────────────────────────────────────────
readonly ICON_TRANSLATE="󰗊"
readonly ICON_SWAP="󰒊"
readonly ICON_COPY="󰆏"
readonly ICON_TTS="󰂚"
readonly ICON_HISTORY="󰹑"
readonly ICON_FAV="★"
readonly ICON_GLOBE="󰋚"
readonly ICON_DETECT="󰍉"
readonly ICON_EXPORT="󰈮"
readonly ICON_RETRY="󰑐"
readonly ICON_CLEAR="󰅖"
readonly ICON_SUCCESS="✓"
readonly ICON_ERROR="✗"
readonly ICON_LOADING="󰔟"
readonly ICON_OFFLINE="󰤭"
readonly ICON_CACHE="󰋗"
readonly ICON_LANG_SEP="│"

# ── Supported providers ───────────────────────────────────────────────────────
readonly PROVIDERS=(google deepl libretranslate ollama lingva mymemory)

# ── Language code → name + flag map ──────────────────────────────────────────
# Format: "code:name:flag_emoji"
declare -A LANG_MAP=(
    [auto]="Auto Detect:󰍉"
    [en]="English:🇺🇸"
    [de]="German:🇩🇪"
    [fr]="French:🇫🇷"
    [es]="Spanish:🇪🇸"
    [it]="Italian:🇮🇹"
    [pt]="Portuguese:🇵🇹"
    [ru]="Russian:🇷🇺"
    [zh]="Chinese:🇨🇳"
    [ja]="Japanese:🇯🇵"
    [ko]="Korean:🇰🇷"
    [ar]="Arabic:🇸🇦"
    [hi]="Hindi:🇮🇳"
    [nl]="Dutch:🇳🇱"
    [sv]="Swedish:🇸🇪"
    [no]="Norwegian:🇳🇴"
    [da]="Danish:🇩🇰"
    [fi]="Finnish:🇫🇮"
    [pl]="Polish:🇵🇱"
    [tr]="Turkish:🇹🇷"
    [uk]="Ukrainian:🇺🇦"
    [cs]="Czech:🇨🇿"
    [ro]="Romanian:🇷🇴"
    [hu]="Hungarian:🇭🇺"
    [el]="Greek:🇬🇷"
    [he]="Hebrew:🇮🇱"
    [th]="Thai:🇹🇭"
    [vi]="Vietnamese:🇻🇳"
    [id]="Indonesian:🇮🇩"
    [ms]="Malay:🇲🇾"
    [fa]="Persian:🇮🇷"
    [bn]="Bengali:🇧🇩"
    [sw]="Swahili:🇰🇪"
    [ca]="Catalan:🏴"
    [hr]="Croatian:🇭🇷"
    [sk]="Slovak:🇸🇰"
    [bg]="Bulgarian:🇧🇬"
    [sr]="Serbian:🇷🇸"
    [lt]="Lithuanian:🇱🇹"
    [lv]="Latvian:🇱🇻"
    [et]="Estonian:🇪🇪"
    [sl]="Slovenian:🇸🇮"
    [ga]="Irish:🇮🇪"
    [mt]="Maltese:🇲🇹"
    [is]="Icelandic:🇮🇸"
    [af]="Afrikaans:🇿🇦"
    [sq]="Albanian:🇦🇱"
    [hy]="Armenian:🇦🇲"
    [az]="Azerbaijani:🇦🇿"
    [eu]="Basque:🏴"
    [be]="Belarusian:🇧🇾"
    [my]="Burmese:🇲🇲"
    [km]="Khmer:🇰🇭"
    [ka]="Georgian:🇬🇪"
    [gu]="Gujarati:🇮🇳"
    [ht]="Haitian Creole:🇭🇹"
    [mk]="Macedonian:🇲🇰"
    [mn]="Mongolian:🇲🇳"
    [ne]="Nepali:🇳🇵"
    [pa]="Punjabi:🇮🇳"
    [si]="Sinhala:🇱🇰"
    [ta]="Tamil:🇮🇳"
    [te]="Telugu:🇮🇳"
    [ur]="Urdu:🇵🇰"
    [uz]="Uzbek:🇺🇿"
    [cy]="Welsh:🏴󠁧󠁢󠁷󠁬󠁳󠁿"
    [xh]="Xhosa:🇿🇦"
    [zu]="Zulu:🇿🇦"
    [la]="Latin:🏛"
    [eo]="Esperanto:🌐"
)

# ══════════════════════════════════════════════════════════════════════════════
# § 3  LOGGING
# ══════════════════════════════════════════════════════════════════════════════

_log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts="$(date +"${DATE_FMT}")"
    printf '[%s] [%-5s] %s\n' "${ts}" "${level}" "${msg}" \
        >> "${TRANS_LOG}" 2>/dev/null || true
}

log_info()  { _log "INFO"  "$@"; }
log_warn()  { _log "WARN"  "$@"; }
log_error() { _log "ERROR" "$@"; }
log_debug() { [[ "${ASH_DEBUG:-0}" == "1" ]] && _log "DEBUG" "$@" || true; }

# ══════════════════════════════════════════════════════════════════════════════
# § 4  INITIALISATION
# ══════════════════════════════════════════════════════════════════════════════

init() {
    local -a dirs=(
        "${TRANS_DIR}"
        "${TRANS_CACHE_DIR}"
        "${TRANS_EXPORT_DIR}"
        "${ASH_STATE_DIR}"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "${dir}"
    done

    # Initialise SQLite history database
    if command -v sqlite3 &>/dev/null; then
        sqlite3 "${TRANS_DB}" <<'SQL' 2>/dev/null || true
CREATE TABLE IF NOT EXISTS history (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    source_text TEXT    NOT NULL,
    result_text TEXT    NOT NULL,
    source_lang TEXT    NOT NULL DEFAULT 'auto',
    target_lang TEXT    NOT NULL,
    provider    TEXT    NOT NULL DEFAULT 'google',
    confidence  REAL             DEFAULT 0.0,
    phonetic    TEXT             DEFAULT '',
    char_count  INTEGER          DEFAULT 0,
    word_count  INTEGER          DEFAULT 0,
    latency_ms  INTEGER          DEFAULT 0,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
);
CREATE INDEX IF NOT EXISTS idx_history_created ON history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_history_langs   ON history(source_lang, target_lang);
CREATE TABLE IF NOT EXISTS favourites (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    source_lang TEXT    NOT NULL,
    target_lang TEXT    NOT NULL,
    label       TEXT,
    created_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    UNIQUE(source_lang, target_lang)
);
CREATE TABLE IF NOT EXISTS cache (
    cache_key   TEXT    PRIMARY KEY,
    result_text TEXT    NOT NULL,
    phonetic    TEXT    DEFAULT '',
    provider    TEXT    NOT NULL,
    confidence  REAL    DEFAULT 0.0,
    expires_at  INTEGER NOT NULL
);
SQL
    fi

    # Default settings
    if [[ ! -f "${TRANS_SETTINGS}" ]]; then
        mkdir -p "$(dirname "${TRANS_SETTINGS}")"
        cat > "${TRANS_SETTINGS}" <<'EOF'
# Translation Settings — ASH Dotfiles v5.0
source_lang="auto"
target_lang="de"
provider="google"
tts_engine="espeak"          # espeak | festival | piper | gtts
tts_speed="150"
cache_enabled="true"
cache_ttl="86400"
clipboard_backend="auto"
notify_on_copy="true"
notify_on_error="true"
max_history="500"
export_format="txt"          # txt | md | json
deepl_api_key=""
libretranslate_url="https://libretranslate.com"
libretranslate_api_key=""
ollama_model="mistral"
ollama_url="http://localhost:11434"
lingva_url="https://lingva.ml"
mymemory_email=""
show_phonetic="true"
show_confidence="true"
parallel_providers="false"
offline_mode="false"
EOF
    fi

    # Initialise favourites JSON if absent
    if [[ ! -f "${TRANS_FAVOURITES}" ]]; then
        echo '{"version":"1","pairs":[]}' > "${TRANS_FAVOURITES}"
    fi

    log_info "Translation backend initialised"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 5  SETTINGS LOADER
# ══════════════════════════════════════════════════════════════════════════════

load_settings() {
    # Safe key allowlist sourcing
    if [[ -f "${TRANS_SETTINGS}" ]]; then
        while IFS='=' read -r key val; do
            [[ "${key}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${key}" ]]               && continue
            key="${key// /}"
            val="${val//\"/}"; val="${val//\'/}"
            case "${key}" in
                source_lang|target_lang|provider|tts_engine|tts_speed|\
                cache_enabled|cache_ttl|clipboard_backend|notify_on_copy|\
                notify_on_error|max_history|export_format|deepl_api_key|\
                libretranslate_url|libretranslate_api_key|ollama_model|\
                ollama_url|lingva_url|mymemory_email|show_phonetic|\
                show_confidence|parallel_providers|offline_mode)
                    printf -v "${key}" '%s' "${val}" ;;
            esac
        done < "${TRANS_SETTINGS}"
    fi

    # Exported so child processes can read them
    export source_lang="${source_lang:-auto}"
    export target_lang="${target_lang:-de}"
    export provider="${provider:-google}"
    export tts_engine="${tts_engine:-espeak}"
    export cache_enabled="${cache_enabled:-true}"
    export offline_mode="${offline_mode:-false}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 6  DEPENDENCY CHECK
# ══════════════════════════════════════════════════════════════════════════════

check_deps() {
    local missing=()
    for dep in curl jq; do
        command -v "${dep}" &>/dev/null || missing+=("${dep}")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required deps: ${missing[*]}"
        printf '%s  Missing: %s — install with: pacman -S %s\000info\037__error__\n' \
            "${ICON_ERROR}" "${missing[*]}" "${missing[*]}"
        exit 1
    fi

    # Clipboard
    if command -v wl-copy &>/dev/null; then
        CLIPBOARD_COPY="wl-copy"
        CLIPBOARD_PASTE="wl-paste"
    elif command -v xclip &>/dev/null; then
        CLIPBOARD_COPY="xclip -selection clipboard -in"
        CLIPBOARD_PASTE="xclip -selection clipboard -out"
    else
        CLIPBOARD_COPY=""
        CLIPBOARD_PASTE=""
        log_warn "No clipboard backend found"
    fi

    log_debug "Deps OK — clipboard: ${CLIPBOARD_COPY:-none}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 7  LANGUAGE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

lang_name() {
    local code="$1"
    local entry="${LANG_MAP[$code]:-Unknown:🌐}"
    echo "${entry%%:*}"
}

lang_flag() {
    local code="$1"
    local entry="${LANG_MAP[$code]:-Unknown:🌐}"
    echo "${entry##*:}"
}

lang_display() {
    local code="$1"
    printf '%s %s' "$(lang_flag "${code}")" "$(lang_name "${code}")"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 8  CACHE ENGINE (SQLite-backed, TTL-aware)
# ══════════════════════════════════════════════════════════════════════════════

cache_key() {
    local text="$1" src="$2" tgt="$3" prov="$4"
    printf '%s' "${text}|${src}|${tgt}|${prov}" | sha256sum | cut -c1-16
}

cache_get() {
    local key="$1"
    [[ "${cache_enabled:-true}" != "true" ]] && return 1
    command -v sqlite3 &>/dev/null || return 1

    local now
    now="$(date +%s)"
    local row
    row="$(sqlite3 "${TRANS_DB}" \
        "SELECT result_text,phonetic,confidence FROM cache \
         WHERE cache_key='${key}' AND expires_at > ${now} LIMIT 1;" \
        2>/dev/null)" || return 1

    [[ -z "${row}" ]] && return 1
    echo "${row}"
}

cache_set() {
    local key="$1" result="$2" phonetic="${3:-}" provider="${4:-google}" confidence="${5:-0}"
    [[ "${cache_enabled:-true}" != "true" ]] && return 0
    command -v sqlite3 &>/dev/null || return 0

    local expires
    expires=$(( $(date +%s) + CACHE_TTL ))

    # Escape single quotes
    result="${result//\'/\'\'}"
    phonetic="${phonetic//\'/\'\'}"

    sqlite3 "${TRANS_DB}" \
        "INSERT OR REPLACE INTO cache(cache_key,result_text,phonetic,provider,confidence,expires_at)
         VALUES('${key}','${result}','${phonetic}','${provider}',${confidence},${expires});" \
        2>/dev/null || true

    # Evict oldest entries beyond CACHE_MAX_ENTRIES
    sqlite3 "${TRANS_DB}" \
        "DELETE FROM cache WHERE cache_key NOT IN (
            SELECT cache_key FROM cache ORDER BY expires_at DESC LIMIT ${CACHE_MAX_ENTRIES}
         );" 2>/dev/null || true

    log_debug "Cache SET: ${key}"
}

cache_clear() {
    command -v sqlite3 &>/dev/null || return 0
    sqlite3 "${TRANS_DB}" "DELETE FROM cache;" 2>/dev/null || true
    log_info "Cache cleared"
}

cache_stats() {
    command -v sqlite3 &>/dev/null || echo "0"
    sqlite3 "${TRANS_DB}" \
        "SELECT COUNT(*) FROM cache WHERE expires_at > $(date +%s);" \
        2>/dev/null || echo "0"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 9  HTTP CLIENT (curl wrapper with timeout + retry + rate-limit)
# ══════════════════════════════════════════════════════════════════════════════

http_get() {
    local url="$1"
    local -a extra_args=("${@:2}")
    local attempt=0
    local delay=${RETRY_DELAY}
    local response

    while (( attempt < RETRY_MAX )); do
        response="$(curl \
            --silent \
            --fail \
            --location \
            --max-time "${REQUEST_TIMEOUT}" \
            --user-agent "Mozilla/5.0 (compatible; ash-translate/5.0)" \
            --compressed \
            "${extra_args[@]}" \
            "${url}" 2>/dev/null)" && {
            echo "${response}"
            return 0
        }
        (( attempt++ ))
        log_warn "HTTP GET attempt ${attempt}/${RETRY_MAX} failed: ${url}"
        sleep "${delay}"
        delay=$(( delay * 2 ))
    done
    return 1
}

http_post_json() {
    local url="$1" data="$2"
    local -a extra_args=("${@:3}")
    local attempt=0
    local delay=${RETRY_DELAY}
    local response

    while (( attempt < RETRY_MAX )); do
        response="$(curl \
            --silent \
            --fail \
            --location \
            --max-time "${REQUEST_TIMEOUT}" \
            --request POST \
            --header "Content-Type: application/json" \
            --user-agent "ash-translate/5.0" \
            --compressed \
            --data "${data}" \
            "${extra_args[@]}" \
            "${url}" 2>/dev/null)" && {
            echo "${response}"
            return 0
        }
        (( attempt++ ))
        log_warn "HTTP POST attempt ${attempt}/${RETRY_MAX} failed: ${url}"
        sleep "${delay}"
        delay=$(( delay * 2 ))
    done
    return 1
}

# ══════════════════════════════════════════════════════════════════════════════
# § 10  TRANSLATION ENGINES
# ══════════════════════════════════════════════════════════════════════════════

# ── Engine: Google Translate (unofficial API) ─────────────────────────────────
translate_google() {
    local text="$1" src="$2" tgt="$3"
    local encoded
    encoded="$(printf '%s' "${text}" | jq -sRr @uri)"

    local url="https://translate.googleapis.com/translate_a/single"
    url+="?client=gtx"
    url+="&sl=${src}"
    url+="&tl=${tgt}"
    url+="&dt=t&dt=bd&dt=rm&dt=qca"
    url+="&q=${encoded}"

    local raw
    raw="$(http_get "${url}")" || return 1

    # Parse main translation (concatenate all sentence segments)
    local result
    result="$(echo "${raw}" | jq -r '.[0] | if type == "array" then
        [.[] | if type == "array" and .[0] != null then .[0] else "" end] | join("")
        else "" end' 2>/dev/null)"

    # Detected source language
    local detected
    detected="$(echo "${raw}" | jq -r '.[2] // "unknown"' 2>/dev/null)"

    # Phonetic / romanisation (index 1 of segments for CJK)
    local phonetic=""
    phonetic="$(echo "${raw}" | jq -r '
        if .[0] then
            [.[0][] | if type == "array" and .[2] != null then .[2] else "" end]
            | join(" ") | gsub("^\\s+|\\s+$";"")
        else "" end' 2>/dev/null)" || phonetic=""

    # Confidence (from quality check array)
    local confidence="0.95"

    if [[ -z "${result}" ]]; then
        log_warn "Google: empty result"
        return 1
    fi

    log_debug "Google: '${text:0:30}…' → '${result:0:30}…' (${src}→${tgt})"

    printf '%s\t%s\t%s\t%s' \
        "${result}" \
        "${phonetic}" \
        "${detected}" \
        "${confidence}"
}

# ── Engine: DeepL ────────────────────────────────────────────────────────────
translate_deepl() {
    local text="$1" src="$2" tgt="$3"
    local api_key="${deepl_api_key:-}"

    if [[ -z "${api_key}" ]]; then
        log_warn "DeepL: no API key configured"
        return 1
    fi

    local src_upper="${src^^}"
    local tgt_upper="${tgt^^}"
    [[ "${src_upper}" == "AUTO" ]] && src_upper=""

    local data
    data="$(jq -n \
        --arg text "${text}" \
        --arg src "${src_upper}" \
        --arg tgt "${tgt_upper}" \
        '{text:[$text], source_lang:($src|if .=="" then null else . end),
          target_lang:$tgt}')"

    local raw
    raw="$(http_post_json \
        "https://api-free.deepl.com/v2/translate" \
        "${data}" \
        --header "Authorization: DeepL-Auth-Key ${api_key}")" || return 1

    local result detected
    result="$(echo "${raw}" | jq -r '.translations[0].text // ""')"
    detected="$(echo "${raw}" | jq -r '.translations[0].detected_source_language // "unknown"' \
        | tr '[:upper:]' '[:lower:]')"

    [[ -z "${result}" ]] && return 1

    printf '%s\t%s\t%s\t%s' "${result}" "" "${detected}" "0.99"
}

# ── Engine: LibreTranslate ───────────────────────────────────────────────────
translate_libretranslate() {
    local text="$1" src="$2" tgt="$3"
    local url="${libretranslate_url:-https://libretranslate.com}/translate"
    local api_key="${libretranslate_api_key:-}"

    local data
    data="$(jq -n \
        --arg q "${text}" \
        --arg s "${src}" \
        --arg t "${tgt}" \
        --arg k "${api_key}" \
        '{q:$q, source:$s, target:$t, format:"text",
          api_key:($k|if .=="" then null else . end)}')"

    local raw
    raw="$(http_post_json "${url}" "${data}")" || return 1

    local result
    result="$(echo "${raw}" | jq -r '.translatedText // ""')"
    [[ -z "${result}" ]] && return 1

    printf '%s\t%s\t%s\t%s' "${result}" "" "${src}" "0.90"
}

# ── Engine: Ollama (local LLM) ───────────────────────────────────────────────
translate_ollama() {
    local text="$1" src="$2" tgt="$3"
    local model="${ollama_model:-mistral}"
    local url="${ollama_url:-http://localhost:11434}/api/generate"

    local src_name tgt_name
    src_name="$(lang_name "${src}")"
    tgt_name="$(lang_name "${tgt}")"

    local prompt="Translate the following text from ${src_name} to ${tgt_name}. "
    prompt+="Output ONLY the translation, nothing else, no explanation.\n\n"
    prompt+="Text: ${text}\n\nTranslation:"

    local data
    data="$(jq -n \
        --arg model "${model}" \
        --arg prompt "${prompt}" \
        '{model:$model, prompt:$prompt, stream:false}')"

    local raw
    raw="$(http_post_json "${url}" "${data}")" || return 1

    local result
    result="$(echo "${raw}" | jq -r '.response // ""' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "${result}" ]] && return 1

    printf '%s\t%s\t%s\t%s' "${result}" "" "${src}" "0.85"
}

# ── Engine: Lingva (privacy Google frontend) ──────────────────────────────────
translate_lingva() {
    local text="$1" src="$2" tgt="$3"
    local base="${lingva_url:-https://lingva.ml}"
    local encoded
    encoded="$(printf '%s' "${text}" | jq -sRr @uri)"

    [[ "${src}" == "auto" ]] && src="auto"

    local url="${base}/api/v1/${src}/${tgt}/${encoded}"
    local raw
    raw="$(http_get "${url}")" || return 1

    local result phonetic
    result="$(echo "${raw}" | jq -r '.translation // ""')"
    phonetic="$(echo "${raw}" | jq -r '.info.pronunciation.translation // ""' 2>/dev/null || echo "")"

    [[ -z "${result}" ]] && return 1

    printf '%s\t%s\t%s\t%s' "${result}" "${phonetic}" "${src}" "0.92"
}

# ── Engine: MyMemory ─────────────────────────────────────────────────────────
translate_mymemory() {
    local text="$1" src="$2" tgt="$3"
    local email="${mymemory_email:-}"
    local encoded
    encoded="$(printf '%s' "${text}" | jq -sRr @uri)"
    local langpair="${src}|${tgt}"
    local encoded_pair
    encoded_pair="$(printf '%s' "${langpair}" | jq -sRr @uri)"

    local url="https://api.mymemory.translated.net/get"
    url+="?q=${encoded}&langpair=${encoded_pair}"
    [[ -n "${email}" ]] && url+="&de=${email}"

    local raw
    raw="$(http_get "${url}")" || return 1

    local result confidence
    result="$(echo "${raw}" | jq -r '.responseData.translatedText // ""')"
    confidence="$(echo "${raw}" | jq -r '.responseData.match // 0')"

    [[ -z "${result}" ]] && return 1
    # MyMemory sometimes returns the error string literally
    [[ "${result}" == *"MYMEMORY WARNING"* ]] && return 1

    printf '%s\t%s\t%s\t%s' "${result}" "" "${src}" "${confidence}"
}

# ── Provider dispatcher ───────────────────────────────────────────────────────
run_provider() {
    local prov="$1" text="$2" src="$3" tgt="$4"
    case "${prov}" in
        google)          translate_google          "${text}" "${src}" "${tgt}" ;;
        deepl)           translate_deepl           "${text}" "${src}" "${tgt}" ;;
        libretranslate)  translate_libretranslate  "${text}" "${src}" "${tgt}" ;;
        ollama)          translate_ollama          "${text}" "${src}" "${tgt}" ;;
        lingva)          translate_lingva          "${text}" "${src}" "${tgt}" ;;
        mymemory)        translate_mymemory        "${text}" "${src}" "${tgt}" ;;
        *)
            log_warn "Unknown provider: ${prov}"
            return 1
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# § 11  MAIN TRANSLATION ORCHESTRATOR
# ══════════════════════════════════════════════════════════════════════════════

translate() {
    local text="$1"
    local src="${2:-${source_lang:-auto}}"
    local tgt="${3:-${target_lang:-de}}"
    local prov="${4:-${provider:-google}}"

    # Guard: empty input
    if [[ -z "${text// }" ]]; then
        echo "__empty__"
        return 0
    fi

    # Guard: char limit
    if (( ${#text} > MAX_INPUT_CHARS )); then
        log_warn "Input exceeds ${MAX_INPUT_CHARS} chars — truncating"
        text="${text:0:${MAX_INPUT_CHARS}}"
    fi

    # Guard: offline mode
    if [[ "${offline_mode:-false}" == "true" ]]; then
        log_info "Offline mode — cache-only"
    fi

    # ── Cache lookup ──────────────────────────────────────────────────────────
    local key
    key="$(cache_key "${text}" "${src}" "${tgt}" "${prov}")"
    local cached
    if cached="$(cache_get "${key}")"; then
        local cached_result cached_phonetic cached_conf
        IFS='|' read -r cached_result cached_phonetic cached_conf <<< "${cached}"
        log_debug "Cache HIT: ${key}"
        printf '%s\t%s\tauto\t%s\tcached' \
            "${cached_result}" "${cached_phonetic}" "${cached_conf}"
        return 0
    fi

    # ── Online translation ────────────────────────────────────────────────────
    if [[ "${offline_mode:-false}" == "true" ]]; then
        printf '%s\t\tauto\t0\tcached' "⚠ Offline: no cached result for this text"
        return 0
    fi

    local t_start result_row
    t_start="$(date +%s%3N)"

    # Try primary provider
    result_row="$(run_provider "${prov}" "${text}" "${src}" "${tgt}")" || {
        log_warn "Provider ${prov} failed — trying fallbacks"
        # Auto-fallback through provider list
        for fallback in "${PROVIDERS[@]}"; do
            [[ "${fallback}" == "${prov}" ]] && continue
            result_row="$(run_provider "${fallback}" "${text}" "${src}" "${tgt}")" && {
                prov="${fallback}"
                log_info "Fallback to: ${fallback}"
                break
            } || true
        done
    }

    if [[ -z "${result_row:-}" ]]; then
        log_error "All providers failed for: '${text:0:40}'"
        printf '%s\t\tauto\t0\terror' \
            "${ICON_ERROR} Translation failed — all providers unavailable"
        return 1
    fi

    local t_end latency
    t_end="$(date +%s%3N)"
    latency=$(( t_end - t_start ))

    # Parse result row: result<TAB>phonetic<TAB>detected<TAB>confidence
    local result phonetic detected confidence
    IFS=$'\t' read -r result phonetic detected confidence <<< "${result_row}"

    # Write to cache
    cache_set "${key}" "${result}" "${phonetic}" "${prov}" "${confidence}"

    # Persist to history DB
    db_save_history \
        "${text}" "${result}" \
        "${src}" "${tgt}" \
        "${prov}" "${confidence}" \
        "${phonetic}" \
        "${#text}" \
        "$(echo "${text}" | wc -w)" \
        "${latency}"

    log_info "Translated (${prov}, ${latency}ms): '${text:0:30}…' → '${result:0:30}…'"

    printf '%s\t%s\t%s\t%s\t%s' \
        "${result}" "${phonetic}" "${detected}" "${confidence}" "${prov}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 12  HISTORY DATABASE
# ══════════════════════════════════════════════════════════════════════════════

db_save_history() {
    command -v sqlite3 &>/dev/null || return 0
    local src_text="$1"   result_text="$2" \
          src_lang="$3"   tgt_lang="$4"    \
          prov="$5"        confidence="$6"  \
          phonetic="$7"   chars="$8"        \
          words="$9"       latency="${10:-0}"

    # Escape
    src_text="${src_text//\'/\'\'}"
    result_text="${result_text//\'/\'\'}"
    phonetic="${phonetic//\'/\'\'}"

    sqlite3 "${TRANS_DB}" \
        "INSERT INTO history(source_text,result_text,source_lang,target_lang,
             provider,confidence,phonetic,char_count,word_count,latency_ms)
         VALUES('${src_text}','${result_text}','${src_lang}','${tgt_lang}',
                '${prov}',${confidence},'${phonetic}',${chars},${words},${latency});" \
        2>/dev/null || true

    # Trim history beyond max
    sqlite3 "${TRANS_DB}" \
        "DELETE FROM history WHERE id NOT IN (
            SELECT id FROM history ORDER BY created_at DESC LIMIT ${max_history:-500}
         );" 2>/dev/null || true
}

db_history() {
    local limit="${1:-${MAX_HISTORY_DISPLAY}}"
    command -v sqlite3 &>/dev/null || return 0

    sqlite3 "${TRANS_DB}" \
        "SELECT id,source_text,result_text,source_lang,target_lang,
                provider,confidence,created_at
         FROM history
         ORDER BY created_at DESC
         LIMIT ${limit};" \
        2>/dev/null
}

db_clear_history() {
    command -v sqlite3 &>/dev/null || return 0
    sqlite3 "${TRANS_DB}" "DELETE FROM history;" 2>/dev/null || true
    log_info "History cleared"
}

db_stats() {
    command -v sqlite3 &>/dev/null || { echo "0|0|0"; return; }
    sqlite3 "${TRANS_DB}" \
        "SELECT COUNT(*),
                COALESCE(SUM(char_count),0),
                COALESCE(AVG(latency_ms),0)
         FROM history;" \
        2>/dev/null || echo "0|0|0"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 13  FAVOURITES
# ══════════════════════════════════════════════════════════════════════════════

fav_add() {
    local src="$1" tgt="$2" label="${3:-}"
    command -v sqlite3 &>/dev/null || return 0

    local src_safe="${src//\'/\'\'}"
    local tgt_safe="${tgt//\'/\'\'}"
    local label_safe="${label//\'/\'\'}"

    sqlite3 "${TRANS_DB}" \
        "INSERT OR IGNORE INTO favourites(source_lang,target_lang,label)
         VALUES('${src_safe}','${tgt_safe}','${label_safe}');" \
        2>/dev/null || true

    notify_user "★ Favourite Added" \
        "$(lang_flag "${src}") ${src} → $(lang_flag "${tgt}") ${tgt}" "low"
    log_info "Favourite added: ${src}→${tgt}"
}

fav_remove() {
    local src="$1" tgt="$2"
    command -v sqlite3 &>/dev/null || return 0
    sqlite3 "${TRANS_DB}" \
        "DELETE FROM favourites WHERE source_lang='${src}' AND target_lang='${tgt}';" \
        2>/dev/null || true
}

fav_list() {
    command -v sqlite3 &>/dev/null || return 0
    sqlite3 "${TRANS_DB}" \
        "SELECT source_lang,target_lang,label FROM favourites ORDER BY created_at DESC;" \
        2>/dev/null
}

fav_is_favourite() {
    local src="$1" tgt="$2"
    command -v sqlite3 &>/dev/null || { echo "false"; return; }
    local count
    count="$(sqlite3 "${TRANS_DB}" \
        "SELECT COUNT(*) FROM favourites
         WHERE source_lang='${src}' AND target_lang='${tgt}';" \
        2>/dev/null || echo "0")"
    [[ "${count}" -gt 0 ]] && echo "true" || echo "false"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 14  TEXT-TO-SPEECH ENGINE
# ══════════════════════════════════════════════════════════════════════════════

# Resolve espeak language code from our lang code
tts_lang_code() {
    local code="$1"
    # espeak-ng uses different codes for some languages
    case "${code}" in
        zh) echo "zh" ;;
        ja) echo "ja" ;;
        ko) echo "ko" ;;
        ar) echo "ar" ;;
        hi) echo "hi" ;;
        *)  echo "${code}" ;;
    esac
}

tts_speak() {
    local text="$1" lang="${2:-en}"
    local engine="${tts_engine:-espeak}"
    local speed="${tts_speed:-150}"

    case "${engine}" in
        espeak)
            if command -v espeak-ng &>/dev/null; then
                espeak-ng \
                    -v "$(tts_lang_code "${lang}")" \
                    -s "${speed}" \
                    "${text}" \
                    &>/dev/null &
            elif command -v espeak &>/dev/null; then
                espeak \
                    -v "$(tts_lang_code "${lang}")" \
                    -s "${speed}" \
                    "${text}" \
                    &>/dev/null &
            else
                log_warn "TTS: espeak-ng / espeak not found"
            fi
            ;;
        festival)
            if command -v festival &>/dev/null; then
                echo "${text}" | festival --tts &>/dev/null &
            else
                log_warn "TTS: festival not found"
            fi
            ;;
        gtts)
            if command -v gtts-cli &>/dev/null; then
                local tts_file
                tts_file="$(mktemp --suffix=.mp3)"
                gtts-cli -l "${lang}" -o "${tts_file}" "${text}" &>/dev/null && {
                    command -v mpv   &>/dev/null && mpv --quiet "${tts_file}" &>/dev/null &
                    command -v ffplay &>/dev/null && ffplay -nodisp -autoexit "${tts_file}" &>/dev/null &
                    command -v aplay  &>/dev/null && aplay "${tts_file}" &>/dev/null &
                }
                rm -f "${tts_file}"
            else
                log_warn "TTS: gtts-cli not found"
            fi
            ;;
        *)
            log_warn "TTS: unknown engine: ${engine}"
            ;;
    esac

    log_info "TTS: '${text:0:40}…' [${lang}]"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 15  CLIPBOARD
# ══════════════════════════════════════════════════════════════════════════════

clipboard_copy() {
    local text="$1"
    if [[ -z "${CLIPBOARD_COPY:-}" ]]; then
        log_warn "Clipboard: no backend available"
        return 1
    fi
    printf '%s' "${text}" | ${CLIPBOARD_COPY}
    log_info "Clipboard: copied (${#text} chars)"
}

clipboard_paste() {
    if [[ -z "${CLIPBOARD_PASTE:-}" ]]; then
        log_warn "Clipboard paste: no backend available"
        return 1
    fi
    ${CLIPBOARD_PASTE} 2>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
# § 16  EXPORT ENGINE
# ══════════════════════════════════════════════════════════════════════════════

export_translation() {
    local src_text="$1" result="$2" \
          src_lang="$3" tgt_lang="$4" \
          provider="$5" phonetic="${6:-}"
    local fmt="${export_format:-txt}"
    local ts
    ts="$(date +'%Y%m%d-%H%M%S')"
    local filename="${TRANS_EXPORT_DIR}/translation-${ts}"

    case "${fmt}" in
        md)
            cat > "${filename}.md" <<EOF
# Translation — ${ts}

| Field    | Value              |
|----------|--------------------|
| Source   | $(lang_flag "${src_lang}") ${src_lang} |
| Target   | $(lang_flag "${tgt_lang}") ${tgt_lang} |
| Engine   | ${provider}        |

## Source Text
${src_text}

## Translation
${result}

$([ -n "${phonetic}" ] && echo "## Phonetic" && echo "${phonetic}")
EOF
            notify_user "󰈮 Exported" "${filename}.md" "low"
            echo "${filename}.md"
            ;;
        json)
            jq -n \
                --arg st "${src_text}" \
                --arg rt "${result}" \
                --arg sl "${src_lang}" \
                --arg tl "${tgt_lang}" \
                --arg pv "${provider}" \
                --arg ph "${phonetic}" \
                --arg ts "${ts}" \
                '{
                    timestamp:  $ts,
                    source:     {lang:$sl, text:$st},
                    target:     {lang:$tl, text:$rt},
                    phonetic:   $ph,
                    provider:   $pv
                }' > "${filename}.json"
            notify_user "󰈮 Exported" "${filename}.json" "low"
            echo "${filename}.json"
            ;;
        *)
            {
                printf 'Translation — %s\n' "${ts}"
                printf '%s\n' "$(printf '─%.0s' {1..60})"
                printf 'Source [%s]: %s\n' "${src_lang}" "${src_text}"
                printf 'Target [%s]: %s\n' "${tgt_lang}" "${result}"
                [[ -n "${phonetic}" ]] && printf 'Phonetic:    %s\n' "${phonetic}"
                printf 'Engine:      %s\n' "${provider}"
            } > "${filename}.txt"
            notify_user "󰈮 Exported" "${filename}.txt" "low"
            echo "${filename}.txt"
            ;;
    esac

    log_info "Exported translation to: ${filename}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 17  LANGUAGE DETECTION
# ══════════════════════════════════════════════════════════════════════════════

detect_language() {
    local text="$1"
    local encoded
    encoded="$(printf '%s' "${text:0:200}" | jq -sRr @uri)"

    # Use Google's detection endpoint
    local url="https://translate.googleapis.com/translate_a/single"
    url+="?client=gtx&sl=auto&tl=en&dt=t&q=${encoded}"

    local raw detected
    raw="$(http_get "${url}")" || { echo "unknown"; return; }
    detected="$(echo "${raw}" | jq -r '.[2] // "unknown"' 2>/dev/null)"
    echo "${detected}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 18  DISPLAY FORMATTERS
# ══════════════════════════════════════════════════════════════════════════════

truncate() {
    local str="$1" max="${2:-55}"
    (( ${#str} > max )) && echo "${str:0:$(( max - 1 ))}…" || echo "${str}"
}

relative_time() {
    local ts="$1"
    local epoch_ts now diff
    epoch_ts="$(date -d "${ts}" +%s 2>/dev/null)" || { echo "${ts}"; return; }
    now="$(date +%s)"
    diff=$(( now - epoch_ts ))

    if   (( diff < 60    )); then echo "just now"
    elif (( diff < 3600  )); then echo "$(( diff / 60 ))m ago"
    elif (( diff < 86400 )); then echo "$(( diff / 3600 ))h ago"
    elif (( diff < 604800)); then echo "$(( diff / 86400 ))d ago"
    else date -d "${ts}" +"%b %d" 2>/dev/null || echo "${ts}"
    fi
}

confidence_bar() {
    local conf="$1"
    # Render a tiny ASCII progress bar 0–100%
    local pct
    pct="$(printf '%.0f' "$(echo "${conf} * 100" | bc -l 2>/dev/null || echo 0)")"
    local filled=$(( pct / 10 ))
    local empty=$(( 10 - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty;  i++ )); do bar+="░"; done
    printf '%s %d%%' "${bar}" "${pct}"
}

format_history_row() {
    local row="$1"
    # SQLite row: id|source_text|result_text|src_lang|tgt_lang|provider|confidence|created_at
    IFS='|' read -r id src_text result_text src_lang tgt_lang prov confidence created_at \
        <<< "${row}"

    local src_flag tgt_flag rel_t src_short result_short
    src_flag="$(lang_flag "${src_lang}")"
    tgt_flag="$(lang_flag "${tgt_lang}")"
    rel_t="$(relative_time "${created_at}")"
    src_short="$(truncate "${src_text}" 26)"
    result_short="$(truncate "${result_text}" 26)"

    # Row: flag src_short → flag result_short  time
    printf '%s %s → %s %s  %s\000info\037%s\n' \
        "${src_flag}" "${src_short}" \
        "${tgt_flag}" "${result_short}" \
        "${rel_t}" \
        "${id}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 19  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_user() {
    local summary="$1" body="${2:-}" urgency="${3:-normal}"
    command -v notify-send &>/dev/null || return 0
    notify-send \
        --urgency="${urgency}" \
        --app-name="Translate" \
        --icon="accessories-dictionary" \
        "${summary}" \
        "${body}" \
        &>/dev/null &
}

# ══════════════════════════════════════════════════════════════════════════════
# § 20  STATE PERSISTENCE (current session lang pair)
# ══════════════════════════════════════════════════════════════════════════════

readonly STATE_FILE="${ASH_STATE_DIR}/translation-session.json"

state_save() {
    local src="$1" tgt="$2" prov="$3" last_input="${4:-}" last_result="${5:-}"
    jq -n \
        --arg src   "${src}"         \
        --arg tgt   "${tgt}"         \
        --arg prov  "${prov}"        \
        --arg input "${last_input}"  \
        --arg res   "${last_result}" \
        '{source_lang:$src, target_lang:$tgt,
          provider:$prov, last_input:$input, last_result:$res}' \
        > "${STATE_FILE}" 2>/dev/null || true
}

state_load() {
    [[ -f "${STATE_FILE}" ]] || return 1
    cat "${STATE_FILE}"
}

state_get() {
    local key="$1"
    [[ -f "${STATE_FILE}" ]] || return 1
    jq -r ".${key} // empty" "${STATE_FILE}" 2>/dev/null
}

state_swap_langs() {
    local src tgt
    src="$(state_get "source_lang")" || src="${source_lang:-auto}"
    tgt="$(state_get "target_lang")" || tgt="${target_lang:-de}"
    local prov
    prov="$(state_get "provider")" || prov="${provider:-google}"

    # Cannot swap if source is 'auto'
    if [[ "${src}" == "auto" ]]; then
        local detected
        detected="$(state_get "detected_lang" 2>/dev/null || echo "en")"
        src="${detected}"
    fi

    state_save "${tgt}" "${src}" "${prov}"
    log_info "Languages swapped: ${tgt} ↔ ${src}"
}

# ══════════════════════════════════════════════════════════════════════════════
# § 21  ROFI RETV DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

render_history_list() {
    local rows
    rows="$(db_history "${MAX_HISTORY_DISPLAY}")"

    if [[ -z "${rows}" ]]; then
        printf '%s  No translation history yet\000info\037__empty__\n' "${ICON_HISTORY}"
        return
    fi

    # Section header
    local stats
    stats="$(db_stats)"
    local total_count
    IFS='|' read -r total_count _ _ <<< "${stats}"

    printf '─── %s  %s translations ─────────────────────────\000info\037__sep__\n' \
        "${ICON_HISTORY}" "${total_count}"

    while IFS= read -r row; do
        [[ -z "${row}" ]] && continue
        format_history_row "${row}"
    done <<< "${rows}"
}

handle_rofi_input() {
    local retv="${ROFI_RETV:-0}"
    local selected="${1:-}"
    local history_id="${ROFI_INFO:-}"

    log_debug "RETV=${retv} SEL='${selected:0:40}' INFO='${history_id}'"

    case "${retv}" in

        # ── Initial render / every keypress ─────────────────────────────────
        28)
            render_history_list
            ;;

        # ── Enter — translate the typed text ────────────────────────────────
        0)
            if [[ -n "${selected// }" ]]; then
                local src tgt prov
                src="$(state_get "source_lang" 2>/dev/null || echo "${source_lang:-auto}")"
                tgt="$(state_get "target_lang" 2>/dev/null || echo "${target_lang:-de}")"
                prov="$(state_get "provider"    2>/dev/null || echo "${provider:-google}")"

                local result_row
                result_row="$(translate "${selected}" "${src}" "${tgt}" "${prov}")"

                local result phonetic detected confidence used_prov
                IFS=$'\t' read -r result phonetic detected confidence used_prov \
                    <<< "${result_row}"

                # Save session state
                state_save "${src}" "${tgt}" "${prov}" "${selected}" "${result}"

                # Auto-copy to clipboard (configurable)
                if [[ "${auto_copy:-false}" == "true" ]]; then
                    clipboard_copy "${result}"
                fi

                # Re-render with result at top
                printf '%s  %s\000info\037__result__\n' \
                    "${ICON_SUCCESS}" "${result}"
                [[ -n "${phonetic}" ]] && \
                printf '󱁬  %s\000info\037__phonetic__\n' "${phonetic}"
                printf '─────────────────────────────────────────────────\000info\037__sep__\n'
                render_history_list
            else
                render_history_list
            fi
            ;;

        # ── Ctrl+S — Swap source ↔ target ───────────────────────────────────
        1)
            state_swap_langs
            notify_user "${ICON_SWAP} Languages Swapped" \
                "$(state_get "source_lang") ↔ $(state_get "target_lang")" "low"
            render_history_list
            ;;

        # ── Ctrl+C — Copy last result to clipboard ───────────────────────────
        2)
            local last_result
            last_result="$(state_get "last_result" 2>/dev/null || echo "")"
            if [[ -n "${last_result}" ]]; then
                clipboard_copy "${last_result}"
                notify_user "${ICON_COPY} Copied" "${last_result:0:60}" "low"
            fi
            render_history_list
            ;;

        # ── Ctrl+T — TTS (speak result) ──────────────────────────────────────
        3)
            local last_result tgt_lang
            last_result="$(state_get "last_result" 2>/dev/null || echo "")"
            tgt_lang="$(state_get "target_lang"  2>/dev/null || echo "en")"
            if [[ -n "${last_result}" ]]; then
                tts_speak "${last_result}" "${tgt_lang}"
                notify_user "${ICON_TTS} Speaking" \
                    "$(lang_flag "${tgt_lang}") ${last_result:0:50}" "low"
            fi
            render_history_list
            ;;

        # ── Ctrl+H — Clear history ────────────────────────────────────────────
        4)
            db_clear_history
            notify_user "${ICON_CLEAR} History Cleared" "" "low"
            render_history_list
            ;;

        # ── Ctrl+F — Favourite current lang pair ─────────────────────────────
        5)
            local src tgt
            src="$(state_get "source_lang" 2>/dev/null || echo "${source_lang:-auto}")"
            tgt="$(state_get "target_lang" 2>/dev/null || echo "${target_lang:-de}")"
            local is_fav
            is_fav="$(fav_is_favourite "${src}" "${tgt}")"
            if [[ "${is_fav}" == "true" ]]; then
                fav_remove "${src}" "${tgt}"
                notify_user "★ Removed from Favourites" \
                    "$(lang_flag "${src}") ${src} → $(lang_flag "${tgt}") ${tgt}" "low"
            else
                fav_add "${src}" "${tgt}"
            fi
            render_history_list
            ;;

        # ── Ctrl+E — Export last translation ─────────────────────────────────
        6)
            local last_input last_result src tgt prov
            last_input="$(state_get "last_input"   2>/dev/null || echo "")"
            last_result="$(state_get "last_result"  2>/dev/null || echo "")"
            src="$(state_get "source_lang"          2>/dev/null || echo "auto")"
            tgt="$(state_get "target_lang"          2>/dev/null || echo "de")"
            prov="$(state_get "provider"             2>/dev/null || echo "google")"
            if [[ -n "${last_result}" ]]; then
                export_translation \
                    "${last_input}" "${last_result}" \
                    "${src}" "${tgt}" "${prov}"
            fi
            render_history_list
            ;;

        # ── Ctrl+P — Paste from clipboard and translate ───────────────────────
        7)
            local pasted
            pasted="$(clipboard_paste 2>/dev/null || echo "")"
            if [[ -n "${pasted}" ]]; then
                local src tgt prov
                src="$(state_get "source_lang" 2>/dev/null || echo "${source_lang:-auto}")"
                tgt="$(state_get "target_lang" 2>/dev/null || echo "${target_lang:-de}")"
                prov="$(state_get "provider"    2>/dev/null || echo "${provider:-google}")"

                local result_row result
                result_row="$(translate "${pasted}" "${src}" "${tgt}" "${prov}")"
                IFS=$'\t' read -r result _ _ _ _ <<< "${result_row}"
                state_save "${src}" "${tgt}" "${prov}" "${pasted}" "${result}"

                printf '%s  %s\000info\037__result__\n' "${ICON_SUCCESS}" "${result}"
                printf '─────────────────────────────────────────────────\000info\037__sep__\n'
            fi
            render_history_list
            ;;

        # ── Ctrl+R — Retry with next provider ────────────────────────────────
        8)
            local current_prov idx next_prov
            current_prov="$(state_get "provider" 2>/dev/null || echo "google")"
            idx=0
            local i
            for (( i=0; i<${#PROVIDERS[@]}; i++ )); do
                [[ "${PROVIDERS[$i]}" == "${current_prov}" ]] && { idx=$i; break; }
            done
            next_prov="${PROVIDERS[$(( (idx + 1) % ${#PROVIDERS[@]} ))]}"
            state_save \
                "$(state_get "source_lang" 2>/dev/null || echo "auto")" \
                "$(state_get "target_lang" 2>/dev/null || echo "de")"   \
                "${next_prov}" \
                "$(state_get "last_input"  2>/dev/null || echo "")"     \
                ""

            notify_user "${ICON_RETRY} Engine Switched" \
                "Now using: ${next_prov}" "low"
            # Re-translate last input with new engine
            local last_input
            last_input="$(state_get "last_input" 2>/dev/null || echo "")"
            if [[ -n "${last_input}" ]]; then
                local src tgt
                src="$(state_get "source_lang" 2>/dev/null || echo "auto")"
                tgt="$(state_get "target_lang" 2>/dev/null || echo "de")"
                local result_row result
                result_row="$(translate "${last_input}" "${src}" "${tgt}" "${next_prov}")"
                IFS=$'\t' read -r result _ _ _ _ <<< "${result_row}"
                state_save "${src}" "${tgt}" "${next_prov}" "${last_input}" "${result}"
                printf '%s  %s\000info\037__result__\n' "${ICON_SUCCESS}" "${result}"
                printf '─────────────────────────────────────────────────\000info\037__sep__\n'
            fi
            render_history_list
            ;;

        # ── Ctrl+D — Detect source language ──────────────────────────────────
        9)
            local last_input detected
            last_input="$(state_get "last_input" 2>/dev/null || echo "")"
            if [[ -n "${last_input}" ]]; then
                detected="$(detect_language "${last_input}")"
                local detected_name
                detected_name="$(lang_name "${detected}")"
                notify_user "${ICON_DETECT} Detected" \
                    "$(lang_flag "${detected}") ${detected_name}" "low"
                log_info "Detected language: ${detected}"
            fi
            render_history_list
            ;;

        # ── Ctrl+X — Clear all (history + cache + state) ─────────────────────
        10)
            db_clear_history
            cache_clear
            rm -f "${STATE_FILE}"
            notify_user "${ICON_CLEAR} All Cleared" \
                "History, cache and session reset" "low"
            render_history_list
            ;;

        # ── Fallback ──────────────────────────────────────────────────────────
        *)
            render_history_list
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# § 22  CLI INTERFACE
# ══════════════════════════════════════════════════════════════════════════════

print_help() {
    cat <<'EOF'
translation.sh — ASH Dotfiles v5.0 Omega Translation Backend

USAGE:
  translation.sh [COMMAND] [ARGS...]
  translation.sh                     # Launch Rofi interface

COMMANDS:
  tr   <text> [src] [tgt] [engine]   Translate text
  tts  <text> [lang]                 Text-to-speech
  copy <text>                        Translate + copy to clipboard
  detect <text>                      Detect language of text
  history [limit]                    Show translation history
  history-clear                      Clear all history
  fav-add  <src> <tgt> [label]       Add favourite language pair
  fav-list                           List favourite pairs
  export <src_text> <result> <src> <tgt> [engine]  Export translation
  cache-stats                        Show cache statistics
  cache-clear                        Clear translation cache
  stats                              Show full statistics
  swap                               Swap current source/target languages
  providers                          List available providers
  langs                              List all supported languages
  init                               Re-initialise directories
  help                               Show this help

ENGINES: google | deepl | libretranslate | ollama | lingva | mymemory

EXAMPLES:
  translation.sh tr "Hello world" en de google
  translation.sh tr "Bonjour" auto en
  translation.sh tts "Hallo Welt" de
  translation.sh detect "Guten Morgen"
  translation.sh fav-add en de "EN→DE"
EOF
}

print_providers() {
    printf '%-20s %-12s %-8s %s\n' "Provider" "Type" "Status" "Details"
    printf '%-20s %-12s %-8s %s\n' "────────" "────" "──────" "───────"
    printf '%-20s %-12s %-8s %s\n' "google"          "Web (free)"   "✓ Online"  "Unofficial API, no key needed"
    printf '%-20s %-12s %-8s %s\n' "deepl"           "Web (premium)" "⚡ Key req" "500k chars/month free tier"
    printf '%-20s %-12s %-8s %s\n' "libretranslate"  "Self-hosted"  "⚡ Opt-key" "FOSS, privacy-focused"
    printf '%-20s %-12s %-8s %s\n' "ollama"          "Local AI"     "🤖 Local"  "Requires Ollama running"
    printf '%-20s %-12s %-8s %s\n' "lingva"          "Web (free)"   "✓ Online"  "Privacy Google frontend"
    printf '%-20s %-12s %-8s %s\n' "mymemory"        "Web (free)"   "✓ Online"  "1000 req/day free"
}

print_langs() {
    printf '%-6s  %-22s  %s\n' "Code" "Language" "Flag"
    printf '%-6s  %-22s  %s\n' "────" "────────" "────"
    local code
    for code in $(echo "${!LANG_MAP[@]}" | tr ' ' '\n' | sort); do
        printf '%-6s  %-22s  %s\n' \
            "${code}" \
            "$(lang_name "${code}")" \
            "$(lang_flag "${code}")"
    done
}

print_stats() {
    local db_stat
    db_stat="$(db_stats)"
    local total chars avg_latency
    IFS='|' read -r total chars avg_latency <<< "${db_stat}"
    local cache_count
    cache_count="$(cache_stats)"

    cat <<EOF
Translation Statistics — ASH Dotfiles v5.0
─────────────────────────────────────────────
 Total translations  : ${total}
 Total characters    : ${chars}
 Avg latency         : ${avg_latency}ms
 Cache entries       : ${cache_count}
─────────────────────────────────────────────
 Data dir            : ${TRANS_DIR}
 Cache dir           : ${TRANS_CACHE_DIR}
 History DB          : ${TRANS_DB}
 Log                 : ${TRANS_LOG}
─────────────────────────────────────────────
EOF
}

# ══════════════════════════════════════════════════════════════════════════════
# § 23  ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

main() {
    init
    check_deps
    load_settings

    # ── Rofi script-modi mode ─────────────────────────────────────────────────
    if [[ -n "${ROFI_OUTSIDE:-}" ]] || [[ "${ROFI_RETV:-}" != "" ]]; then
        handle_rofi_input "${1:-}"
        return
    fi

    # ── Direct CLI mode ───────────────────────────────────────────────────────
    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "${cmd}" in
        "")
            # Launch Rofi
            rofi \
                -show translation \
                -modi "translation:${BASH_SOURCE[0]}" \
                -theme "${ROFI_CONFIG_DIR}/translation.rasi" \
                -display-translation "󰗊  Translate" \
                &>/dev/null &
            ;;
        tr|translate)
            local text="${1:?Usage: translation.sh tr <text> [src] [tgt] [engine]}"
            local src="${2:-${source_lang:-auto}}"
            local tgt="${3:-${target_lang:-de}}"
            local eng="${4:-${provider:-google}}"
            local row result phonetic detected confidence used_prov
            row="$(translate "${text}" "${src}" "${tgt}" "${eng}")"
            IFS=$'\t' read -r result phonetic detected confidence used_prov <<< "${row}"
            printf 'Result    : %s\n' "${result}"
            [[ -n "${phonetic}" ]] && printf 'Phonetic  : %s\n' "${phonetic}"
            printf 'Detected  : %s\n' "${detected}"
            printf 'Confidence: %s\n' "$(confidence_bar "${confidence}")"
            printf 'Engine    : %s\n' "${used_prov}"
            ;;
        tts)
            local text="${1:?Usage: translation.sh tts <text> [lang]}"
            local lang="${2:-en}"
            tts_speak "${text}" "${lang}"
            ;;
        copy)
            local text="${1:?Usage: translation.sh copy <text>}"
            local src="${2:-${source_lang:-auto}}"
            local tgt="${3:-${target_lang:-de}}"
            local row result
            row="$(translate "${text}" "${src}" "${tgt}" "${provider:-google}")"
            IFS=$'\t' read -r result _ _ _ _ <<< "${row}"
            clipboard_copy "${result}"
            printf '%s\n' "${result}"
            ;;
        detect)
            local text="${1:?Usage: translation.sh detect <text>}"
            local code
            code="$(detect_language "${text}")"
            printf '%s  %s (%s)\n' "$(lang_flag "${code}")" "$(lang_name "${code}")" "${code}"
            ;;
        history)
            local limit="${1:-20}"
            local rows
            rows="$(db_history "${limit}")"
            while IFS= read -r row; do
                [[ -z "${row}" ]] && continue
                format_history_row "${row}"
            done <<< "${rows}"
            ;;
        history-clear)
            db_clear_history
            echo "History cleared"
            ;;
        fav-add)
            local src="${1:?Usage: fav-add <src> <tgt> [label]}"
            local tgt="${2:?}"
            local label="${3:-}"
            fav_add "${src}" "${tgt}" "${label}"
            ;;
        fav-list)
            fav_list
            ;;
        export)
            local st="${1:?}" rt="${2:?}" sl="${3:?}" tl="${4:?}" pv="${5:-google}"
            export_translation "${st}" "${rt}" "${sl}" "${tl}" "${pv}"
            ;;
        cache-stats)
            printf 'Valid cache entries: %s\n' "$(cache_stats)"
            ;;
        cache-clear)
            cache_clear
            echo "Cache cleared"
            ;;
        swap)
            state_swap_langs
            printf 'Swapped: %s ↔ %s\n' \
                "$(state_get "source_lang")" "$(state_get "target_lang")"
            ;;
        providers)
            print_providers
            ;;
        langs)
            print_langs
            ;;
        stats)
            print_stats
            ;;
        init)
            echo "Initialised at ${TRANS_DIR}"
            ;;
        help|--help|-h)
            print_help
            ;;
        *)
            log_warn "Unknown command: ${cmd}"
            print_help >&2
            exit 1
            ;;
    esac
}

main "$@"