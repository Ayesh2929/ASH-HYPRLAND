#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot history                                             ║
# ║  Browse screenshot history • fzf preview • delete • re-upload • stats          ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_HISTORY_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_HISTORY_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_hist_file_icon() {
    local file="$1"
    case "${file##*.}" in
        png|jpg|jpeg|webp) printf '📷' ;;
        mp4|mkv|webm)      printf '🎬' ;;
        gif)               printf '🎞️ ' ;;
        txt)               printf '📄' ;;
        *)                 printf '📁' ;;
    esac
}

_hist_format_size() {
    local bytes="${1:-0}"
    if   (( bytes >= 1073741824 )); then printf '%.1f GB' "$(echo "scale=1;$bytes/1073741824"|bc -l 2>/dev/null||echo 0)"
    elif (( bytes >= 1048576    )); then printf '%.1f MB' "$(echo "scale=1;$bytes/1048576"   |bc -l 2>/dev/null||echo 0)"
    elif (( bytes >= 1024       )); then printf '%.1f KB' "$(echo "scale=1;$bytes/1024"      |bc -l 2>/dev/null||echo 0)"
    else printf '%d B' "$bytes"
    fi
}

_hist_stats() {
    shot_section "📊" "Screenshot Statistics" "$(_smauve)"

    local total_files total_size
    total_files="$(find "$_SHOT_DIR" \( -name '*.png' -o -name '*.jpg' \
                   -o -name '*.gif' -o -name '*.mp4' \) 2>/dev/null | wc -l)"

    local total_bytes
    total_bytes="$(find "$_SHOT_DIR" -type f 2>/dev/null | \
                   xargs du -sb 2>/dev/null | awk '{sum+=$1}END{print sum+0}')"
    total_size="$(_hist_format_size "$total_bytes")"

    shot_kv "Directory"    "$_SHOT_DIR"
    shot_kv "Total files"  "$total_files"
    shot_kv "Total size"   "$total_size"

    # Count by type
    for ext in png jpg gif mp4 txt; do
        local ext_count
        ext_count="$(find "$_SHOT_DIR" -name "*.${ext}" 2>/dev/null | wc -l)"
        (( ext_count > 0 )) && \
            shot_kv "  .${ext}" "$ext_count files"
    done

    # Log file stats
    if [[ -f "$_SHOT_HISTORY" ]]; then
        local log_lines
        log_lines="$(wc -l < "$_SHOT_HISTORY" 2>/dev/null || echo 0)"
        shot_kv "History entries" "$log_lines"

        # Mode breakdown
        printf '\n  %sBy capture mode:%s\n' "$(_sdim)" "$(_sr)"
        awk -F'\t' '{print $2}' "$_SHOT_HISTORY" 2>/dev/null | \
            sort | uniq -c | sort -rn | head -8 | \
        while IFS= read -r line; do
            local count mode
            count="$(printf '%s' "$line" | awk '{print $1}')"
            mode="$(  printf '%s' "$line" | awk '{print $2}')"
            printf '    %s%-12s%s %s%d%s\n' \
                "$(_ssky)" "$mode" "$(_sr)" "$(_sdim)" "$count" "$(_sr)"
        done
    fi
}

_hist_list() {
    local limit="${1:-50}"

    shot_section "📋" "Recent Screenshots" "$(_steal)"

    printf '\n  %s%-35s %-10s %-10s %s%s\n' \
        "$(_sdim)" "Filename" "Size" "Mode" "Date" "$(_sr)"
    printf '  %s%s%s\n' "$(_sdim)" "$(printf '─%.0s' $(seq 1 70))" "$(_sr)"

    local count=0

    find "$_SHOT_DIR" -type f \( -name '*.png' -o -name '*.jpg' \
        -o -name '*.gif' -o -name '*.mp4' \) 2>/dev/null | \
    sort -r | head "$limit" | \
    while IFS= read -r file; do
        local fname size_bytes size mode date_str icon
        fname="$(basename "$file")"
        size_bytes="$(stat -c '%s' "$file" 2>/dev/null || echo 0)"
        size="$(_hist_format_size "$size_bytes")"
        date_str="$(stat -c '%y' "$file" 2>/dev/null | cut -d'.' -f1 | cut -c1-16)"
        icon="$(_hist_file_icon "$file")"

        # Try to get mode from history log
        mode="$(grep -F "$file" "$_SHOT_HISTORY" 2>/dev/null | \
                cut -f2 | tail -1 || echo '?')"

        printf '  %s  %s%-33s%s %-10s %-10s %s%s%s\n' \
            "$icon" \
            "$(_ssky)" "${fname:0:32}" "$(_sr)" \
            "$size" "${mode:0:9}" \
            "$(_sdim)" "$date_str" "$(_sr)"

        (( count++ )) || true
    done

    printf '\n  %s%s files shown%s\n' "$(_sdim)" "$count" "$(_sr)"
}

_hist_browse_fzf() {
    shot_section "🔍" "Interactive Browser" "$(_speach)"

    if ! command -v fzf &>/dev/null; then
        shot_info "fzf not found — install for interactive browser"
        shot_info "paru -S fzf"
        _hist_list 30
        return 0
    fi

    local -a files=()
    mapfile -t files < <(
        find "$_SHOT_DIR" -type f \( -name '*.png' -o -name '*.jpg' \
            -o -name '*.gif' -o -name '*.mp4' -o -name '*.webp' \) \
            2>/dev/null | sort -r | head 200
    )

    if [[ ${#files[@]} -eq 0 ]]; then
        shot_info "No screenshots found in ${_SHOT_DIR}"
        return 0
    fi

    # Build display list with sizes
    local -a display=()
    for f in "${files[@]}"; do
        local fname sz ts
        fname="$(basename "$f")"
        sz="$(du -sh "$f" 2>/dev/null | cut -f1)"
        ts="$(stat -c '%y' "$f" 2>/dev/null | cut -d'.' -f1 | cut -c1-16)"
        display+=("${fname}  │  ${sz}  │  ${ts}  │  ${f}")
    done

    # fzf with image preview (if chafa available)
    local preview_cmd='echo {4}'
    if command -v chafa &>/dev/null; then
        preview_cmd='chafa --size=60x25 {4} 2>/dev/null || file {4}'
    elif command -v kitty &>/dev/null; then
        preview_cmd='kitty +kitten icat --clear 2>/dev/null; kitty +kitten icat {4} 2>/dev/null || file {4}'
    fi

    local selected
    selected="$(printf '%s\n' "${display[@]}" | \
        fzf --prompt "  📷  Select screenshot: " \
            --height=80% \
            --border=rounded \
            --delimiter='  │  ' \
            --with-nth='1,2,3' \
            --nth=1 \
            --preview="$preview_cmd" \
            --preview-window='right:60%:wrap' \
            --header="Enter=open  d=delete  c=copy  u=upload  ESC=quit" \
            --bind="ctrl-d:execute(rm -f {4} && echo 'Deleted: {4}')+abort" \
            --bind="ctrl-c:execute(wl-copy < {4} 2>/dev/null && echo 'Copied to clipboard')" \
            --color="hl:$(printf '%s' "$(_smauve)" | sed 's/\x1b\[//;s/m//')" \
            2>/dev/null | awk -F'  │  ' '{print $4}' || echo '')"

    if [[ -n "$selected" ]]; then
        shot_ok "Selected: ${selected##*/}"

        printf '\n  %sActions:%s\n' "$(_sbold)" "$(_sr)"
        printf '    %s[o]%s Open  %s[c]%s Copy  %s[u]%s Upload  %s[d]%s Delete  %s[q]%s Quit\n' \
            "$(_ssky)" "$(_sr)" "$(_steal)" "$(_sr)" \
            "$(_sblue)" "$(_sr)" "$(_sred)" "$(_sr)" \
            "$(_sdim)" "$(_sr)"

        printf '  %sAction: %s' "$(_syellow)" "$(_sr)"
        local action
        read -r action

        case "${action,,}" in
            o|open)
                xdg-open "$selected" &>/dev/null &
                ;;
            c|copy)
                shot_copy_to_clipboard "$selected"
                ;;
            u|upload)
                _shot_load_sub upload 2>/dev/null
                ash_shot_upload "$selected"
                ;;
            d|delete)
                printf '  %sDelete %s? [y/N] %s' \
                    "$(_sred)" "${selected##*/}" "$(_sr)"
                local confirm
                read -r confirm
                if [[ "${confirm,,}" == "y" ]]; then
                    rm -f "$selected" && shot_ok "Deleted" || shot_fail "Delete failed"
                fi
                ;;
            q|*)
                shot_info "No action taken"
                ;;
        esac
    fi
}

_hist_clean() {
    local days="${1:-30}"

    shot_section "🗑️ " "Clean Old Screenshots" "$(_sred)"
    shot_kv "Older than" "${days} days"

    local -a old_files=()
    mapfile -t old_files < <(
        find "$_SHOT_DIR" -type f \( -name '*.png' -o -name '*.jpg' \
            -o -name '*.gif' -o -name '*.mp4' \) \
            -mtime "+${days}" 2>/dev/null | sort
    )

    if [[ ${#old_files[@]} -eq 0 ]]; then
        shot_ok "No files older than ${days} days"
        return 0
    fi

    local total_size=0
    for f in "${old_files[@]}"; do
        local s
        s="$(stat -c '%s' "$f" 2>/dev/null || echo 0)"
        (( total_size += s )) || true
    done

    shot_kv "Files to remove" "${#old_files[@]}"
    shot_kv "Space to free"   "$(_hist_format_size "$total_size")"

    printf '\n  %sDelete these %d file(s)? [y/N] %s' \
        "$(_syellow)" "${#old_files[@]}" "$(_sr)"
    local ans
    read -r ans

    if [[ "${ans,,}" == "y" ]]; then
        local deleted=0
        for f in "${old_files[@]}"; do
            rm -f "$f" && (( deleted++ )) || true
        done
        shot_ok "Deleted ${deleted} file(s)"
    else
        shot_info "Cleanup cancelled"
    fi
}

ash_shot_history() {
    local action="browse"   # browse | list | stats | clean
    local limit=50
    local clean_days=30

    for arg in "${@:-}"; do
        case "$arg" in
            browse|interactive) action="browse" ;;
            list|-l)            action="list"   ;;
            stats|-s)           action="stats"  ;;
            clean|prune)        action="clean"  ;;
            --limit=*)          limit="${arg#*=}" ;;
            --days=*)           clean_days="${arg#*=}" ;;
        esac
    done

    shot_section "📋" "Screenshot History" "$(_slav)"

    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]] && [[ -t 1 ]]; then
        printf '\033[1;38;2;180;190;254m'
        printf '  ╔══════════════════════════════════════════════════════════╗\n'
        printf '  ║  📷  Screenshot Archive  •  %s%-28s║\n' \
            "$(_sdim)" "$_SHOT_DIR"
        printf '  ╚══════════════════════════════════════════════════════════╝\033[0m\n'
    fi

    case "$action" in
        browse)    _hist_browse_fzf               ;;
        list)      _hist_list "$limit"             ;;
        stats)     _hist_stats                     ;;
        clean)     _hist_clean "$clean_days"       ;;
    esac

    printf '\n'
}
