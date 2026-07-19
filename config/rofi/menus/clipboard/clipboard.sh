#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Clipboard History Manager Script                  ║
# ║                                                                              ║
# ║  Full clipboard history management via cliphist (Wayland native).           ║
# ║  Features: content type detection, pinning, deletion, search,              ║
# ║  preview, copy without paste, edit before paste, privacy mode.             ║
# ║                                                                              ║
# ║  Dependencies: cliphist, wl-copy, wl-paste, rofi                           ║
# ║  Optional: xdg-open (URL open), file (MIME detection)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly MAX_DISPLAY_LEN=65         # Max chars shown per entry
readonly MAX_ENTRIES=200            # Max history entries to show
readonly PINS_FILE="${HOME}/.local/share/ash-dotfiles/clipboard-pins.txt"
readonly HISTORY_FILE="${HOME}/.local/state/ash-dotfiles/clipboard.log"
readonly PREVIEW_MAXLEN=300         # Max chars in preview
readonly SENSITIVE_MASK="●●●●●●●●●●●●●●●●"  # Mask for passwords

# ══════════════════════════════════════════════════════════════════════════════
# §02  CONTENT TYPE DETECTION
# ══════════════════════════════════════════════════════════════════════════════

detect_content_type() {
    local content="$1"

    # URL
    if [[ "$content" =~ ^https?://|^ftp://|^ssh:// ]]; then
        echo "url"
        return
    fi

    # Email
    if [[ "$content" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "email"
        return
    fi

    # File path
    if [[ "$content" =~ ^(/|~/)([a-zA-Z0-9_.-]+/?){1,} ]]; then
        echo "path"
        return
    fi

    # JSON
    if [[ "$content" =~ ^\{|\[.*\]$ ]] && \
        echo "$content" | python3 -m json.tool &>/dev/null 2>&1; then
        echo "json"
        return
    fi

    # Code (heuristic: contains braces/semicolons/function keywords)
    local code_pat='[{\}].*;'
    if [[ "$content" =~ (function|def |class |const |import |require)[[:space:]] ]] || \
       [[ "$content" =~ $code_pat ]]; then
        echo "code"
        return
    fi

    # Password/secret (high entropy, short, mixed chars)
    local len="${#content}"
    if [[ $len -ge 8 && $len -le 64 ]] && \
       [[ "$content" =~ [A-Z] && "$content" =~ [a-z] && \
          "$content" =~ [0-9] && "$content" =~ [^a-zA-Z0-9] ]]; then
        echo "password"
        return
    fi

    # Binary / image (non-printable characters)
    if echo "$content" | grep -qP '[^\x09\x0a\x0d\x20-\x7e]'; then
        echo "binary"
        return
    fi

    # Large text block
    if [[ ${#content} -gt 200 ]]; then
        echo "large-text"
        return
    fi

    echo "text"
}

content_type_to_icon() {
    local type="$1"
    case "$type" in
        url)        echo "󰆏" ;;    # Link
        email)      echo "󰻊" ;;    # Email
        path)       echo "󰕯" ;;    # File path
        json)       echo "󰒓" ;;    # JSON/config
        code)       echo "󰙀" ;;    # Code
        password)   echo "󰌋" ;;    # Lock/secret
        binary)     echo "󰋩" ;;    # Image/binary
        large-text) echo "󰈦" ;;    # Long text
        text)       echo "󰅌" ;;    # Text
        *)          echo "󰅌" ;;    # Default
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  PIN MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

ensure_pins_file() {
    mkdir -p "$(dirname "$PINS_FILE")"
    touch "$PINS_FILE" 2>/dev/null || true
}

is_pinned() {
    local hash="$1"
    ensure_pins_file
    grep -qF "$hash" "$PINS_FILE" 2>/dev/null
}

pin_entry() {
    local hash="$1" content="$2"
    ensure_pins_file
    if ! is_pinned "$hash"; then
        echo "${hash}|${content}" >> "$PINS_FILE"
    fi
}

unpin_entry() {
    local hash="$1"
    ensure_pins_file
    local tmp
    tmp=$(mktemp)
    grep -vF "$hash" "$PINS_FILE" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$PINS_FILE"
}

get_pinned_entries() {
    ensure_pins_file
    cat "$PINS_FILE" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  TIME FORMATTING
# ══════════════════════════════════════════════════════════════════════════════

format_time_ago() {
    local timestamp="${1:-$(date +%s)}"
    local now
    now=$(date +%s)
    local diff=$(( now - timestamp ))

    if   [[ $diff -lt 60 ]];        then echo "just now"
    elif [[ $diff -lt 3600 ]];      then echo "$((diff/60))m ago"
    elif [[ $diff -lt 86400 ]];     then echo "$((diff/3600))h ago"
    elif [[ $diff -lt 604800 ]];    then echo "$((diff/86400))d ago"
    else                                 echo "$((diff/604800))w ago"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  CONTENT PROCESSING
# ══════════════════════════════════════════════════════════════════════════════

truncate_content() {
    local content="$1"
    local maxlen="${2:-$MAX_DISPLAY_LEN}"

    # Remove leading/trailing whitespace and newlines
    content=$(echo "$content" | tr '\n\r\t' '   ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    if [[ ${#content} -gt $maxlen ]]; then
        echo "${content:0:$((maxlen-1))}…"
    else
        echo "$content"
    fi
}

mask_sensitive() {
    local content="$1" type="$2"
    if [[ "$type" == "password" ]]; then
        echo "$SENSITIVE_MASK"
    else
        echo "$content"
    fi
}

content_hash() {
    local content="$1"
    echo "$content" | sha256sum | cut -c1-16
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

notify_cb() {
    local title="$1" msg="${2:-}" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Clipboard" \
        --icon=edit-paste \
        --urgency="$urgency" \
        --expire-time=2500 \
        --hint=string:x-dunst-stack-tag:clipboard \
        2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

build_entries() {
    # Check cliphist is available and has entries
    if ! command -v cliphist &>/dev/null; then
        printf '󰅌  cliphist not installed\0nonselectable\x1ftrue\n'
        printf '  Install: paru -S cliphist\0info\x1fnone\n'
        return
    fi

    local raw_history
    raw_history=$(cliphist list 2>/dev/null | head -"$MAX_ENTRIES" || true)

    if [[ -z "$raw_history" ]]; then
        printf '󰅌  Clipboard history is empty\0nonselectable\x1ftrue\n'
        printf '  Copy something to populate history\0info\x1fnone\n'
        return
    fi

    # ── Pinned entries first ───────────────────────────────────────────────────
    local pinned_data
    pinned_data=$(get_pinned_entries)

    if [[ -n "$pinned_data" ]]; then
        printf '─── PINNED ───────────────────────────\0nonselectable\x1ftrue\n'

        while IFS='|' read -r pin_hash pin_content; do
            [[ -z "$pin_hash" ]] && continue

            local content_type icon display_content
            content_type=$(detect_content_type "$pin_content")
            icon=$(content_type_to_icon "$content_type")
            display_content=$(mask_sensitive "$pin_content" "$content_type")
            display_content=$(truncate_content "$display_content")

            # Right-align type label
            local type_label
            type_label=$(printf '%-10s' "$content_type")

            local display
            display=$(printf '📌 %s  %-50s  %s  pinned' \
                "$icon" \
                "$display_content" \
                "$type_label")

            printf '%s\0info\x1fpaste\x1fmeta\x1f%s\n' "$display" "$pin_hash"

        done <<< "$pinned_data"
    fi

    # ── Recent clipboard history ───────────────────────────────────────────────
    printf '─── RECENT ───────────────────────────\0nonselectable\x1ftrue\n'

    local entry_count=0
    while IFS=$'\t' read -r entry_id content_raw; do
        [[ -z "$entry_id" ]] && continue

        # Remove non-printable chars for display
        local content
        content=$(echo "$content_raw" | tr -d '\000-\010\013\014\016-\037\177' 2>/dev/null || echo "$content_raw")

        local content_type icon hash
        content_type=$(detect_content_type "$content")
        icon=$(content_type_to_icon "$content_type")
        hash=$(content_hash "$content")

        # Skip if pinned (already shown)
        is_pinned "$hash" && continue

        local display_content
        display_content=$(mask_sensitive "$content" "$content_type")
        display_content=$(truncate_content "$display_content")

        # Type label right-padded
        local type_label
        type_label=$(printf '%-10s' "$content_type")

        # Age (use entry_id as timestamp if available, else "recent")
        local age="recent"

        local display
        display=$(printf '%s  %-50s  %s  %s' \
            "$icon" \
            "$display_content" \
            "$type_label" \
            "$age")

        # Store entry_id for actual paste operation
        printf '%s\0info\x1fpaste-id\x1fmeta\x1f%s\n' "$display" "$entry_id"

        (( entry_count++ )) || true
    done <<< "$raw_history"

    # ── Actions ────────────────────────────────────────────────────────────────
    printf '─── ACTIONS ──────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰩹  Clear All History  (Ctrl+A)\0info\x1fclear-all\n'
    printf '󰋩  Show Image Entries Only\0info\x1ffilter-images\n'
    printf '󰆏  Show URLs Only\0info\x1ffilter-urls\n'
    printf '  Sync to Clipboard File\0info\x1fsync\n'
}

build_stats_line() {
    local count
    count=$(cliphist list 2>/dev/null | wc -l || echo 0)
    local pinned_count
    pinned_count=$(wc -l < "$PINS_FILE" 2>/dev/null || echo 0)
    echo "${count} entries • ${pinned_count} pinned"
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  PASTE ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

paste_by_id() {
    local entry_id="$1"

    # Use cliphist decode to get the actual content
    if echo "$entry_id" | cliphist decode 2>/dev/null | wl-copy 2>/dev/null; then
        # Trigger paste with xdotool or ydotool
        if command -v ydotool &>/dev/null; then
            sleep 0.1
            ydotool key ctrl+v &>/dev/null || true
        elif command -v xdotool &>/dev/null; then
            sleep 0.1
            xdotool key ctrl+v &>/dev/null || true
        fi
        notify_cb "󰅌 Pasted" "" "low"
    else
        notify_cb "Paste failed" "Could not decode entry" "critical"
    fi
}

paste_by_hash() {
    local hash="$1"
    local pinned
    pinned=$(grep "^${hash}|" "$PINS_FILE" 2>/dev/null | cut -d'|' -f2- | head -1 || echo "")

    if [[ -n "$pinned" ]]; then
        echo -n "$pinned" | wl-copy 2>/dev/null && \
            notify_cb "📌 Pasted pinned" "" "low"
    fi
}

copy_only_by_id() {
    local entry_id="$1"
    echo "$entry_id" | cliphist decode 2>/dev/null | wl-copy 2>/dev/null && \
        notify_cb "󰆏 Copied" "Entry copied to clipboard (not pasted)" "low"
}

edit_before_paste() {
    local entry_id="$1"

    # Get content
    local content
    content=$(echo "$entry_id" | cliphist decode 2>/dev/null || echo "")
    [[ -z "$content" ]] && return

    # Open edit dialog
    local edited
    edited=$(echo "$content" | \
        rofi \
            -dmenu \
            -p "󰅌 Edit before paste" \
            -filter "$content" \
            -theme-str "
                window { width: 600px; height: 0px; }
                listview { lines: 0; }
                inputbar { padding: 12px 18px; }
                entry { font: JetBrainsMono Nerd Font 12; }
            " \
            2>/dev/null || echo "")

    if [[ -n "$edited" ]]; then
        echo -n "$edited" | wl-copy 2>/dev/null && \
            notify_cb "󰅌 Pasted (edited)" "" "low"
    fi
}

delete_entry() {
    local entry_id="$1"

    if echo "$entry_id" | cliphist delete &>/dev/null; then
        notify_cb "󰩹 Deleted" "Entry removed from history" "low"
    else
        notify_cb "Delete failed" "" "critical"
    fi
}

toggle_pin() {
    local entry_id="$1"

    local content
    content=$(echo "$entry_id" | cliphist decode 2>/dev/null || echo "")
    [[ -z "$content" ]] && return

    local hash
    hash=$(content_hash "$content")

    if is_pinned "$hash"; then
        unpin_entry "$hash"
        notify_cb "📌 Unpinned" "" "low"
    else
        pin_entry "$hash" "$content"
        notify_cb "📌 Pinned" "Entry pinned to top" "low"
    fi
}

clear_all_history() {
    # Confirm before clearing
    local confirm
    confirm=$(printf "Yes, clear everything\nNo, keep history" | \
        rofi -dmenu \
            -p "Clear all clipboard history?" \
            -mesg "This will permanently delete <b>all</b> ${count:-?} entries\n\nPinned entries will NOT be cleared" \
            -theme-str "
                window { width: 360px; }
                listview { lines: 2; }
                element { padding: 10px 16px; border-radius: 8px; }
                element selected.normal {
                    background-color: #f38ba8;
                    text-color: #1e1e2e;
                }
            " \
            2>/dev/null || echo "No, keep history")

    if [[ "$confirm" == "Yes, clear everything" ]]; then
        cliphist wipe 2>/dev/null || true
        wl-copy --clear 2>/dev/null || true
        notify_cb "󰩹 Cleared" "Clipboard history cleared" "normal"
    fi
}

open_url() {
    local entry_id="$1"
    local content
    content=$(echo "$entry_id" | cliphist decode 2>/dev/null | head -1 | tr -d '[:space:]' || echo "")

    if [[ "$content" =~ ^https?:// ]]; then
        xdg-open "$content" &>/dev/null & disown
        notify_cb "󰆏 Opening URL" "$content" "low"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        paste-id)       paste_by_id     "$meta" ;;
        paste)          paste_by_hash   "$meta" ;;
        copy-id)        copy_only_by_id "$meta" ;;
        edit)           edit_before_paste "$meta" ;;
        delete)         delete_entry    "$meta" ;;
        pin)            toggle_pin      "$meta" ;;
        open-url)       open_url        "$meta" ;;
        clear-all)      clear_all_history ;;
        filter-images)  notify_cb "Filter" "Image filtering not yet implemented" "low" ;;
        filter-urls)    notify_cb "Filter" "URL filtering not yet implemented" "low" ;;
        sync)
            cliphist list 2>/dev/null > "${HOME}/.cache/ash-dotfiles/clipboard-export.txt" && \
                notify_cb "  Synced" "Clipboard exported to file" "low"
            ;;
        none|"")
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --paste)
            cliphist list 2>/dev/null | \
                rofi -dmenu -p "󰅌 Clipboard" | \
                cliphist decode 2>/dev/null | \
                wl-copy 2>/dev/null
            ;;
        --clear)
            cliphist wipe 2>/dev/null && \
                notify_cb "󰩹 Cleared" "Clipboard history cleared"
            ;;
        --list)
            cliphist list 2>/dev/null | head -20
            ;;
        --count)
            cliphist list 2>/dev/null | wc -l
            ;;
        --copy-last)
            cliphist list 2>/dev/null | head -1 | \
                cliphist decode 2>/dev/null | wl-copy 2>/dev/null && \
                notify_cb "Copied" "Last entry copied" "low"
            ;;
        --help|-h)
            echo "ASH Clipboard Manager v5.0"
            echo ""
            echo "Usage: clipboard.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --paste      Show picker and paste selected"
            echo "  --clear      Clear all clipboard history"
            echo "  --list       List last 20 entries"
            echo "  --count      Show entry count"
            echo "  --copy-last  Copy most recent entry"
            echo ""
            echo "No args: Launch Rofi clipboard manager"
            exit 0
            ;;
        "")
            return 1
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" 2>/dev/null || true

    rofi \
        -show cb \
        -modi "cb:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/clipboard/clipboard.rasi" \
        2>/dev/null
    exit 0
fi

# ── Initialization ────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 0 ]]; then
    ensure_pins_file
    build_entries
    exit 0
fi

# ── Entry selected ────────────────────────────────────────────────────────────
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

# ── Ctrl+P: Pin/unpin ─────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 10 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && dispatch_action "pin" "$meta_value"
    build_entries
    exit 0
fi

# ── Ctrl+A: Clear all ─────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 11 ]]; then
    clear_all_history
    build_entries
    exit 0
fi

# ── Ctrl+C: Copy only ─────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 12 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"
    [[ "$local_action" == "paste-id" && -n "$meta_value" ]] && \
        copy_only_by_id "$meta_value"
    build_entries
    exit 0
fi

# ── Ctrl+E: Edit before paste ─────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 13 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && edit_before_paste "$meta_value"
    exit 0
fi

# ── Delete key ────────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 14 ]]; then
    meta="${ROFI_INFO:-}"
    IFS=$'\x1f' read -ra parts <<< "$meta"
    meta_value="${parts[2]:-}"
    [[ -n "$meta_value" ]] && delete_entry "$meta_value"
    build_entries
    exit 0
fi

# ── Re-filter ─────────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_entries
    exit 0
fi