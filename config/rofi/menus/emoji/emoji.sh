#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Emoji & Symbol Picker Script                      ║
# ║                                                                              ║
# ║  Full Unicode emoji picker with category filtering, skin tone variants,    ║
# ║  shortcode lookup, recent history, symbol browser and type/copy actions.    ║
# ║                                                                              ║
# ║  Actions on selection:                                                       ║
# ║  Enter     → copy to clipboard + type into focused window                  ║
# ║  Ctrl+C    → copy to clipboard only                                         ║
# ║  Ctrl+T    → type into window only (no clipboard)                           ║
# ║  Ctrl+R    → show recently used emoji                                       ║
# ║  Ctrl+S    → cycle skin tone (1-5 Fitzpatrick scale)                       ║
# ║  Ctrl+Y    → switch to symbol browser                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly EMOJI_DATA="${HOME}/.config/rofi/menus/emoji/emoji-data.txt"
readonly RECENT_FILE="${HOME}/.local/share/ash-dotfiles/emoji-recent.txt"
readonly SKIN_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-emoji-skin"
readonly MAX_RECENT=30
readonly MAX_DISPLAY=200          # Max emoji shown at once
readonly DISPLAY_COL_WIDTH=45    # Name column width
readonly CODE_COL_WIDTH=14       # Shortcode column width

# ── Skin tone modifiers (Fitzpatrick scale) ────────────────────────────────────
declare -A SKIN_TONES=(
    [0]=""          # Default (yellow)
    [1]="🏻"        # Light (type 1-2)
    [2]="🏼"        # Medium-light (type 3)
    [3]="🏽"        # Medium (type 4)
    [4]="🏾"        # Medium-dark (type 5)
    [5]="🏿"        # Dark (type 6)
)

declare -A SKIN_LABELS=(
    [0]="Default 🟡"
    [1]="Light 🟤 Type 1"
    [2]="Medium-Light Type 2"
    [3]="Medium Type 3"
    [4]="Medium-Dark Type 4"
    [5]="Dark Type 5"
)

# ══════════════════════════════════════════════════════════════════════════════
# §02  STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

get_skin_tone() {
    cat "$SKIN_FILE" 2>/dev/null || echo "0"
}

set_skin_tone() {
    echo "$1" > "$SKIN_FILE"
}

cycle_skin_tone() {
    local current
    current=$(get_skin_tone)
    local next=$(( (current + 1) % 6 ))
    set_skin_tone "$next"
    local label="${SKIN_LABELS[$next]}"
    notify_emoji "Skin tone: $label" "" "low"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  RECENT EMOJI MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

ensure_recent_file() {
    mkdir -p "$(dirname "$RECENT_FILE")"
    touch "$RECENT_FILE" 2>/dev/null || true
}

add_to_recent() {
    local emoji="$1" name="${2:-}"
    ensure_recent_file

    # Remove existing occurrence (dedup)
    local tmp
    tmp=$(mktemp)
    grep -vF "${emoji}	" "$RECENT_FILE" > "$tmp" 2>/dev/null || true

    # Prepend new entry
    echo "${emoji}	${name}	$(date +%s)" | cat - "$tmp" > "$RECENT_FILE"
    rm -f "$tmp"

    # Keep only MAX_RECENT entries
    local tmp2
    tmp2=$(mktemp)
    head -"$MAX_RECENT" "$RECENT_FILE" > "$tmp2"
    mv "$tmp2" "$RECENT_FILE"
}

get_recent_entries() {
    ensure_recent_file
    cat "$RECENT_FILE" 2>/dev/null | head -"$MAX_RECENT" || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_emoji() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Emoji" \
        --icon=emoji-symbolic \
        --urgency="$urgency" \
        --expire-time=2000 \
        --hint=string:x-dunst-stack-tag:emoji \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  EMOJI TYPE / PASTE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

copy_emoji() {
    local emoji="$1"
    echo -n "$emoji" | wl-copy 2>/dev/null && \
        notify_emoji "${emoji} Copied" "Emoji copied to clipboard" "low"
}

type_emoji() {
    local emoji="$1"
    if command -v ydotool &>/dev/null; then
        sleep 0.15
        ydotool type --delay 50 "$emoji" &>/dev/null || true
    elif command -v xdotool &>/dev/null; then
        sleep 0.15
        xdotool type --clearmodifiers "$emoji" &>/dev/null || true
    else
        # Fallback: paste from clipboard
        echo -n "$emoji" | wl-copy 2>/dev/null || true
        notify_emoji "${emoji} Copied" "ydotool not found — copied instead" "low"
        return
    fi
}

copy_and_type() {
    local emoji="$1" name="${2:-}"
    copy_emoji "$emoji"
    type_emoji "$emoji"
    add_to_recent "$emoji" "$name"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  SKIN TONE APPLICATION
# ══════════════════════════════════════════════════════════════════════════════

apply_skin_tone() {
    local emoji="$1"
    local tone_idx
    tone_idx=$(get_skin_tone)
    local tone="${SKIN_TONES[$tone_idx]}"

    # Only apply to supported emoji (single person emoji with hand/person)
    # Check if emoji supports skin tones by checking for modifier base
    if [[ -n "$tone" ]]; then
        # Try appending modifier
        local modified="${emoji}${tone}"
        echo "$modified"
    else
        echo "$emoji"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_recent_entries() {
    local entries
    entries=$(get_recent_entries)

    if [[ -z "$entries" ]]; then
        printf '🕐  No recent emoji\0nonselectable\x1ftrue\n'
        return
    fi

    printf '─── RECENTLY USED ────────────────────\0nonselectable\x1ftrue\n'

    while IFS=$'\t' read -r emoji name timestamp; do
        [[ -z "$emoji" ]] && continue

        local display
        display=$(printf '%s  %-40s  %s' \
            "$emoji" \
            "${name:0:38}" \
            "recent")

        printf '%s\0info\x1fcopy-type\x1fmeta\x1f%s|%s\n' \
            "$display" "$emoji" "$name"
    done <<< "$entries"

    printf '─────────────────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰩹  Clear Recent History\0info\x1fclear-recent\n'
}

build_emoji_entries() {
    local filter_cat="${1:-all}"

    if [[ ! -f "$EMOJI_DATA" ]]; then
        printf '❌  Emoji data not found\0nonselectable\x1ftrue\n'
        printf '  Path: %s\0info\x1fnone\n' "$EMOJI_DATA"
        return
    fi

    local tone_idx
    tone_idx=$(get_skin_tone)
    local current_section=""
    local count=0

    while IFS='|' read -r emoji name category shortcode codepoint; do
        [[ -z "$emoji" ]] && continue
        [[ "$emoji" =~ ^# ]] && continue  # Skip comments

        # Category filter
        if [[ "$filter_cat" != "all" ]]; then
            [[ "${category,,}" != "${filter_cat,,}" ]] && continue
        fi

        # Section header
        if [[ "$category" != "$current_section" ]]; then
            current_section="$category"
            printf '─── %s ─────────────\0nonselectable\x1ftrue\n' \
                "$(echo "$category" | tr '[:lower:]' '[:upper:]')"
        fi

        # Apply skin tone if applicable
        local display_emoji="$emoji"
        if [[ "$tone_idx" -gt 0 ]] && \
            [[ "$category" =~ people|hand|person|family ]]; then
            local tone="${SKIN_TONES[$tone_idx]}"
            display_emoji="${emoji}${tone}"
        fi

        # Format: emoji  name (padded)  shortcode  codepoint
        local display
        display=$(printf '%s  %-40s  %-14s  %s' \
            "$display_emoji" \
            "${name:0:38}" \
            "${shortcode:0:12}" \
            "${codepoint:-}")

        printf '%s\0info\x1fcopy-type\x1fmeta\x1f%s|%s\n' \
            "$display" "$display_emoji" "$name"

        (( count++ )) || true
        [[ $count -ge $MAX_DISPLAY ]] && break

    done < "$EMOJI_DATA"

    if [[ $count -eq 0 ]]; then
        printf '😶  No emoji found in category: %s\0nonselectable\x1ftrue\n' \
            "$filter_cat"
    fi
}

build_symbol_entries() {
    printf '─── ARROWS ───────────────────────────\0nonselectable\x1ftrue\n'
    printf '←  leftwards arrow\0info\x1fcopy-type\x1fmeta\x1f←|leftwards arrow\n'
    printf '→  rightwards arrow\0info\x1fcopy-type\x1fmeta\x1f→|rightwards arrow\n'
    printf '↑  upwards arrow\0info\x1fcopy-type\x1fmeta\x1f↑|upwards arrow\n'
    printf '↓  downwards arrow\0info\x1fcopy-type\x1fmeta\x1f↓|downwards arrow\n'
    printf '↔  left right arrow\0info\x1fcopy-type\x1fmeta\x1f↔|left right arrow\n'
    printf '⇐  leftwards double arrow\0info\x1fcopy-type\x1fmeta\x1f⇐|leftwards double\n'
    printf '⇒  rightwards double arrow\0info\x1fcopy-type\x1fmeta\x1f⇒|rightwards double\n'
    printf '⟸  long leftwards double arrow\0info\x1fcopy-type\x1fmeta\x1f⟸|long leftwards double\n'
    printf '⟹  long rightwards double arrow\0info\x1fcopy-type\x1fmeta\x1f⟹|long rightwards double\n'

    printf '─── MATH ─────────────────────────────\0nonselectable\x1ftrue\n'
    printf '±  plus-minus\0info\x1fcopy-type\x1fmeta\x1f±|plus-minus\n'
    printf '×  multiplication sign\0info\x1fcopy-type\x1fmeta\x1f×|multiplication\n'
    printf '÷  division sign\0info\x1fcopy-type\x1fmeta\x1f÷|division\n'
    printf '∞  infinity\0info\x1fcopy-type\x1fmeta\x1f∞|infinity\n'
    printf '∑  summation\0info\x1fcopy-type\x1fmeta\x1f∑|summation\n'
    printf '∏  product\0info\x1fcopy-type\x1fmeta\x1f∏|product\n'
    printf '√  square root\0info\x1fcopy-type\x1fmeta\x1f√|square root\n'
    printf '∫  integral\0info\x1fcopy-type\x1fmeta\x1f∫|integral\n'
    printf '≈  almost equal\0info\x1fcopy-type\x1fmeta\x1f≈|almost equal\n'
    printf '≠  not equal\0info\x1fcopy-type\x1fmeta\x1f≠|not equal\n'
    printf '≤  less than or equal\0info\x1fcopy-type\x1fmeta\x1f≤|less or equal\n'
    printf '≥  greater than or equal\0info\x1fcopy-type\x1fmeta\x1f≥|greater or equal\n'
    printf 'π  pi\0info\x1fcopy-type\x1fmeta\x1fπ|pi\n'
    printf 'λ  lambda\0info\x1fcopy-type\x1fmeta\x1fλ|lambda\n'
    printf 'Δ  delta\0info\x1fcopy-type\x1fmeta\x1fΔ|delta\n'
    printf 'Ω  omega\0info\x1fcopy-type\x1fmeta\x1fΩ|omega\n'

    printf '─── PUNCTUATION ──────────────────────\0nonselectable\x1ftrue\n'
    printf '"  left double quotation\0info\x1fcopy-type\x1fmeta\x1f"|left double quote\n'
    printf '"  right double quotation\0info\x1fcopy-type\x1fmeta\x1f"|right double quote\n'
    printf "'  left single quotation\0info\x1fcopy-type\x1fmeta\x1f'|left single quote\n"
    printf "'  right single quotation\0info\x1fcopy-type\x1fmeta\x1f'|right single quote\n"
    printf '…  horizontal ellipsis\0info\x1fcopy-type\x1fmeta\x1f…|ellipsis\n'
    printf '—  em dash\0info\x1fcopy-type\x1fmeta\x1f—|em dash\n'
    printf '–  en dash\0info\x1fcopy-type\x1fmeta\x1f–|en dash\n'
    printf '·  middle dot\0info\x1fcopy-type\x1fmeta\x1f·|middle dot\n'
    printf '•  bullet\0info\x1fcopy-type\x1fmeta\x1f•|bullet\n'
    printf '★  black star\0info\x1fcopy-type\x1fmeta\x1f★|black star\n'
    printf '☆  white star\0info\x1fcopy-type\x1fmeta\x1f☆|white star\n'
    printf '©  copyright\0info\x1fcopy-type\x1fmeta\x1f©|copyright\n'
    printf '®  registered\0info\x1fcopy-type\x1fmeta\x1f®|registered\n'
    printf '™  trade mark\0info\x1fcopy-type\x1fmeta\x1f™|trade mark\n'
    printf '§  section sign\0info\x1fcopy-type\x1fmeta\x1f§|section\n'
    printf '¶  pilcrow\0info\x1fcopy-type\x1fmeta\x1f¶|pilcrow\n'

    printf '─── CURRENCY ─────────────────────────\0nonselectable\x1ftrue\n'
    printf '€  euro sign\0info\x1fcopy-type\x1fmeta\x1f€|euro\n'
    printf '£  pound sign\0info\x1fcopy-type\x1fmeta\x1f£|pound\n'
    printf '¥  yen sign\0info\x1fcopy-type\x1fmeta\x1f¥|yen\n'
    printf '₿  bitcoin sign\0info\x1fcopy-type\x1fmeta\x1f₿|bitcoin\n'
    printf '₹  rupee sign\0info\x1fcopy-type\x1fmeta\x1f₹|rupee\n'
    printf '₩  won sign\0info\x1fcopy-type\x1fmeta\x1f₩|won\n'
    printf '₣  franc sign\0info\x1fcopy-type\x1fmeta\x1f₣|franc\n'

    printf '─── BOX DRAWING ──────────────────────\0nonselectable\x1ftrue\n'
    printf '─  horizontal line\0info\x1fcopy-type\x1fmeta\x1f─|h-line\n'
    printf '│  vertical line\0info\x1fcopy-type\x1fmeta\x1f│|v-line\n'
    printf '┼  cross\0info\x1fcopy-type\x1fmeta\x1f┼|cross\n'
    printf '╔  top-left corner\0info\x1fcopy-type\x1fmeta\x1f╔|tl-corner\n'
    printf '╗  top-right corner\0info\x1fcopy-type\x1fmeta\x1f╗|tr-corner\n'
    printf '╚  bottom-left corner\0info\x1fcopy-type\x1fmeta\x1f╚|bl-corner\n'
    printf '╝  bottom-right corner\0info\x1fcopy-type\x1fmeta\x1f╝|br-corner\n'
    printf '═  double horizontal\0info\x1fcopy-type\x1fmeta\x1f═|dh-line\n'
    printf '║  double vertical\0info\x1fcopy-type\x1fmeta\x1f║|dv-line\n'
}

build_skin_tone_selector() {
    printf '─── SKIN TONE ────────────────────────\0nonselectable\x1ftrue\n'
    for i in 0 1 2 3 4 5; do
        local label="${SKIN_LABELS[$i]}"
        local tone="${SKIN_TONES[$i]}"
        local current=""
        [[ "$(get_skin_tone)" == "$i" ]] && current=" ✓"

        printf '✋%s  %s%s\0info\x1fset-skin\x1fmeta\x1f%s\n' \
            "$tone" "$label" "$current" "$i"
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        copy-type)
            IFS='|' read -r emoji name <<< "$meta"
            [[ -n "$emoji" ]] && copy_and_type "$emoji" "$name"
            ;;
        copy-only)
            IFS='|' read -r emoji name <<< "$meta"
            [[ -n "$emoji" ]] && copy_emoji "$emoji"
            ;;
        type-only)
            IFS='|' read -r emoji name <<< "$meta"
            [[ -n "$emoji" ]] && {
                type_emoji "$emoji"
                add_to_recent "$emoji" "$name"
            }
            ;;
        set-skin)
            [[ -n "$meta" ]] && {
                set_skin_tone "$meta"
                notify_emoji "Skin tone: ${SKIN_LABELS[$meta]}" "" "low"
            }
            ;;
        clear-recent)
            true > "$RECENT_FILE" 2>/dev/null && \
                notify_emoji "Recent cleared" "" "low"
            ;;
        none|"")
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --recent)   build_recent_entries ;;
        --symbols)  build_symbol_entries ;;
        --skin)     cycle_skin_tone      ;;
        --clear)    true > "$RECENT_FILE" && notify_emoji "Recent cleared" "" ;;
        --search)
            local query="${2:-}"
            [[ -n "$query" ]] && grep -i "$query" "$EMOJI_DATA" | head -20
            ;;
        --help|-h)
            echo "ASH Emoji Picker v5.0"
            echo ""
            echo "Usage: emoji.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --recent     Show recent emoji"
            echo "  --symbols    Show symbol browser"
            echo "  --skin       Cycle skin tone"
            echo "  --clear      Clear recent history"
            echo "  --search Q   Search emoji data"
            echo ""
            echo "No args: Launch Rofi emoji picker"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    rofi \
        -show emoji \
        -modi "emoji:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/emoji/emoji.rasi" \
        2>/dev/null
    exit 0
fi

# State from ROFI_DATA
CURRENT_MODE="${ROFI_DATA:-emoji}"

if [[ "${ROFI_RETV}" -eq 0 ]]; then
    ensure_recent_file

    case "$CURRENT_MODE" in
        recent)   build_recent_entries  ;;
        symbols)  build_symbol_entries  ;;
        skin)     build_skin_tone_selector ;;
        *)        build_recent_entries; build_emoji_entries "all" ;;
    esac
    exit 0
fi

if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# Ctrl+C: Copy only
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    action="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$action"
    meta_value="${parts[2]:-}"
    IFS='|' read -r emoji name <<< "$meta_value"
    [[ -n "$emoji" ]] && copy_emoji "$emoji" && add_to_recent "$emoji" "${name:-}"
    exit 0
fi

# Ctrl+T: Type only
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    action="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$action"
    meta_value="${parts[2]:-}"
    IFS='|' read -r emoji name <<< "$meta_value"
    [[ -n "$emoji" ]] && type_emoji "$emoji" && add_to_recent "$emoji" "${name:-}"
    exit 0
fi

# Ctrl+R: Recent
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    build_recent_entries
    exit 0
fi

# Ctrl+S: Skin tone cycle
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    cycle_skin_tone
    build_emoji_entries "all"
    exit 0
fi

# Ctrl+Y: Symbols
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    build_symbol_entries
    exit 0
fi

# Re-filter
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_recent_entries
    build_emoji_entries "all"
    exit 0
fi