#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper history                                        ║
# ║  Browse history • re-apply • clean old entries • favorite management            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_HISTORY_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_HISTORY_LOADED=1

set -euo pipefail

declare -gr _HIST_FAV_FILE="${_WP_STATE}/favorites.txt"

_hist_parse_log() {
    [[ -f "$_WP_HISTORY_FILE" ]] || return 0
    # Output: "timestamp\tfile" sorted newest first
    sort -r "$_WP_HISTORY_FILE" 2>/dev/null
}

_hist_list_display() {
    local limit="${1:-50}"
    local count=0

    printf '\n  %s%-20s  %-40s  %s%s\n' \
        "$(_wdim)" "Time" "Filename" "Status" "$(_wr)"
    printf '  %s%s%s\n' "$(_wdim)" "$(printf '─%.0s' $(seq 1 70))" "$(_wr)"

    local current
    current="$(wp_get_current)"

    while IFS=$'\t' read -r ts file; do
        [[ -z "$ts" ]] || [[ -z "$file" ]] && continue
        (( count >= limit )) && break

        local bname
        bname="$(basename "$file")"
        local ts_short
        ts_short="${ts:0:16}"
        local status=""
        local status_color="$(_wdim)"

        if [[ "$file" == "$current" ]]; then
            status="★ current"
            status_color="$(_wgreen)"
        elif [[ ! -f "$file" ]]; then
            status="✗ missing"
            status_color="$(_wred)"
        fi

        # Favorite indicator
        local fav=""
        grep -qxF "$file" "$_HIST_FAV_FILE" 2>/dev/null && \
            fav="${_wyellow}♥${_wr} "

        printf '  %s%-20s%s  %s%s%-38s%s  %s%s%s\n' \
            "$(_wdim)" "$ts_short" "$(_wr)" \
            "$fav" "$(_wsky)" "${bname:0:37}" "$(_wr)" \
            "$status_color" "$status" "$(_wr)"

        (( count++ )) || true
    done < <(_hist_parse_log)

    printf '\n  %s%d entries shown%s\n' "$(_wdim)" "$count" "$(_wr)"
}

_hist_fzf_browse() {
    command -v fzf &>/dev/null || {
        _hist_list_display 30
        return 0
    }

    local current
    current="$(wp_get_current)"

    # Build unique file list from history (existing files only)
    local fzf_input
    fzf_input="$(while IFS=$'\t' read -r ts file; do
        [[ -f "$file" ]] || continue
        local bname
        bname="$(basename "$file")"
        local fav=""
        grep -qxF "$file" "$_HIST_FAV_FILE" 2>/dev/null && fav="♥ "
        local cur_mark=""
        [[ "$file" == "$current" ]] && cur_mark="★ "
        printf '%s%s%s\t%s\t%s\n' "$cur_mark" "$fav" "$bname" "${ts:0:16}" "$file"
    done < <(_hist_parse_log) | awk '!seen[$5]++' | head -200)"

    local preview_cmd='file {5}'
    command -v chafa &>/dev/null && \
        preview_cmd='chafa --size=$(( COLUMNS/2 ))x$(( LINES-4 )) {5} 2>/dev/null'

    local selected
    selected="$(printf '%s\n' "$fzf_input" | \
        fzf \
            --prompt "  🖼️   Wallpaper history: " \
            --header "↵=apply  ctrl-f=favorite  ctrl-d=remove  ESC=cancel" \
            --height=85% \
            --border=rounded \
            --delimiter='\t' \
            --with-nth='1,2' \
            --nth=1 \
            --preview="$preview_cmd" \
            --preview-window='right:55%:wrap' \
            --bind='ctrl-f:execute(echo {5} >> '"$_HIST_FAV_FILE"' && echo "Added to favorites")+refresh-preview' \
            --color="hl:$(printf '\033[38;2;203;166;247m' | sed 's/\033\[//;s/m//')" \
            2>/dev/null | awk -F'\t' '{print $5}' || echo '')"

    if [[ -n "$selected" ]] && [[ -f "$selected" ]]; then
        wp_step "Applying: $(basename "$selected")..."
        if wp_set_backend "$selected"; then
            wp_ok "Wallpaper set: $(basename "$selected")"
            wp_notify "⏪ Wallpaper Restored" "$(basename "$selected")" "$selected"
        else
            wp_fail "Failed to apply"
            return 1
        fi
    else
        wp_info "No selection"
    fi
}

_hist_manage_favorites() {
    wp_section "♥" "Favorites" "$(_wyellow)"

    if [[ ! -f "$_HIST_FAV_FILE" ]]; then
        wp_info "No favorites yet"
        wp_info "Add: ash wp history --favorite <file>"
        printf '\n'
        return 0
    fi

    local count=0
    while IFS= read -r fav; do
        [[ -z "$fav" ]] && continue
        (( count++ )) || true
        local exists_icon
        [[ -f "$fav" ]] && exists_icon="$(_wgreen)✓$(_wr)" || \
            exists_icon="$(_wred)✗$(_wr)"

        printf '  %s  %s%s%s\n' \
            "$exists_icon" \
            "$(_wsky)" "$(basename "$fav")" "$(_wr)"
    done < "$_HIST_FAV_FILE"

    printf '\n  %s%d favorite(s)%s\n' "$(_wdim)" "$count" "$(_wr)"
}

_hist_clean() {
    local keep="${1:-100}"

    wp_section "🗑️ " "Clean History" "$(_wred)"

    if [[ ! -f "$_WP_HISTORY_FILE" ]]; then
        wp_info "No history file found"
        return 0
    fi

    local total
    total="$(wc -l < "$_WP_HISTORY_FILE" 2>/dev/null || echo 0)"
    wp_kv "Total entries" "$total"
    wp_kv "Keeping"       "$keep most recent"

    if (( total <= keep )); then
        wp_ok "Already within limit (${total} ≤ ${keep})"
        return 0
    fi

    printf '  %sRemove %d old entries? [y/N] %s' \
        "$(_wyellow)" "$(( total - keep ))" "$(_wr)"
    local ans
    read -r ans

    if [[ "${ans,,}" == "y" ]]; then
        tail -"$keep" "$_WP_HISTORY_FILE" > "${_WP_HISTORY_FILE}.tmp" && \
            mv "${_WP_HISTORY_FILE}.tmp" "$_WP_HISTORY_FILE"
        wp_ok "Cleaned history: $(( total - keep )) entries removed"
    else
        wp_info "Cancelled"
    fi
}

ash_wp_history() {
    local action="browse"
    local limit=50
    local add_favorite=""
    local clean_keep=100

    for arg in "${@:-}"; do
        case "$arg" in
            browse|list|favorites|clean) action="$arg" ;;
            --limit=*|-n=*)   limit="${arg#*=}"        ;;
            --favorite=*)     add_favorite="${arg#*=}"; action="favorite" ;;
            --keep=*)         clean_keep="${arg#*=}"   ;;
            -l|--list)        action="list"            ;;
            -f|--favorites)   action="favorites"       ;;
        esac
    done

    wp_section "📜" "Wallpaper History" "$(_wlav)"

    case "$action" in
        browse)
            _hist_fzf_browse
            ;;

        list)
            _hist_list_display "$limit"
            ;;

        favorites)
            _hist_manage_favorites
            ;;

        favorite)
            if [[ -n "$add_favorite" ]]; then
                if grep -qxF "$add_favorite" "$_HIST_FAV_FILE" 2>/dev/null; then
                    wp_info "Already in favorites: $(basename "$add_favorite")"
                else
                    printf '%s\n' "$add_favorite" >> "$_HIST_FAV_FILE"
                    wp_ok "Added to favorites: $(basename "$add_favorite")"
                fi
            fi
            ;;

        clean)
            _hist_clean "$clean_keep"
            ;;
    esac

    printf '\n'
}
