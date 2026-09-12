#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper pick                                           ║
# ║  Interactive fzf picker with chafa/kitty image preview                          ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_PICK_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_PICK_LOADED=1

set -euo pipefail

_pick_build_preview_cmd() {
    # Build best available preview command for fzf
    if command -v chafa &>/dev/null; then
        printf 'chafa --size=$(( COLUMNS/2 ))x$(( LINES-4 )) --symbols=block,border,vhalf "%s" 2>/dev/null'
    elif [[ "${TERM:-}" == "xterm-kitty" ]] && command -v kitty &>/dev/null; then
        printf 'kitty +kitten icat --clear 2>/dev/null; kitty +kitten icat --place $(( COLUMNS/2 ))x$(( LINES-4 ))@0x0 "%s" 2>/dev/null'
    elif command -v feh &>/dev/null; then
        printf 'feh --borderless --scale-down --geometry 400x300 "%s" 2>/dev/null &'
    else
        printf 'file "%s"; echo; stat --printf="Size: %%s bytes\n" "%s"'
    fi
}

_pick_display_gallery() {
    # Text-based gallery if fzf not available
    local -a files=("$@")
    local cols=4  col=0

    printf '\n'
    for f in "${files[@]}"; do
        local basename
        basename="$(basename "$f" | cut -c1-18)"

        if command -v chafa &>/dev/null; then
            chafa --size=18x8 --symbols=block "$f" 2>/dev/null | \
            while IFS= read -r line; do
                printf '  %s\n' "$line"
            done
        fi

        printf '  %s%s%s\n' "$(_wdim)" "$basename" "$(_wr)"
        (( col++ )) || true
    done
}

ash_wp_pick() {
    local category=""
    local sort_by="name"    # name | date | size | random

    for arg in "${@:-}"; do
        case "$arg" in
            --category=*|-c=*) category="${arg#*=}"  ;;
            --sort=*)           sort_by="${arg#*=}"  ;;
            --random|-r)        sort_by="random"     ;;
            --by-date)          sort_by="date"       ;;
        esac
    done

    wp_section "🔍" "Wallpaper Picker" "$(_wblue)"

    wp_kv "Backend"    "$WP_BACKEND"
    wp_kv "Library"    "$_WP_LIB_DIR"

    # ── Collect files ─────────────────────────────────────────────────────────────
    local -a all_files=()
    mapfile -t all_files < <(wp_find_all)

    if [[ -n "$category" ]]; then
        local filtered=()
        for f in "${all_files[@]}"; do
            [[ "$f" =~ /${category}/ ]] && filtered+=("$f")
        done
        all_files=("${filtered[@]:-}")
    fi

    if [[ ${#all_files[@]} -eq 0 ]]; then
        wp_fail "No wallpapers found"
        wp_info "Library: ${_WP_LIB_DIR}"
        wp_info "Download: ash wp download"
        return 1
    fi

    # Sort
    local sort_cmd
    case "$sort_by" in
        date)   sort_cmd="sort -r"   ;;  # newest first (relies on path structure)
        size)   sort_cmd="sort"      ;;
        random) sort_cmd="shuf"      ;;
        name|*) sort_cmd="sort"      ;;
    esac

    local -a sorted_files=()
    mapfile -t sorted_files < <(printf '%s\n' "${all_files[@]}" | $sort_cmd)

    wp_kv "Found"   "${#sorted_files[@]} wallpapers"
    wp_kv "Sort"    "$sort_by"
    printf '\n'

    # ── fzf interactive picker ────────────────────────────────────────────────────
    if ! command -v fzf &>/dev/null; then
        wp_warn "fzf not found — falling back to numbered list"
        wp_info "Install for interactive picking: paru -S fzf"

        # Numbered list fallback
        local i=0
        for f in "${sorted_files[@]:0:20}"; do
            (( i++ )) || true
            printf '  %s%3d%s  %s%s%s\n' \
                "$(_wpeach)" "$i" "$(_wr)" \
                "$(_wsky)" "$(basename "$f")" "$(_wr)"
        done

        printf '\n  %sEnter number (1-%d): %s' "$(_wyellow)" "${#sorted_files[@]}" "$(_wr)"
        local choice
        read -r choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && \
           (( choice >= 1 )) && (( choice <= ${#sorted_files[@]} )); then
            local selected="${sorted_files[$((choice-1))]}"
            wp_step "Applying: $(basename "$selected")..."
            wp_set_backend "$selected" && \
                wp_ok "Wallpaper set: $(basename "$selected")" && \
                wp_notify "🖼️  Wallpaper Set" "$(basename "$selected")" "$selected"
        else
            wp_info "No valid selection"
        fi

        printf '\n'
        return 0
    fi

    # ── Build fzf display list ────────────────────────────────────────────────────
    local preview_cmd
    preview_cmd="$(_pick_build_preview_cmd)"

    # Format: "DISPLAY_NAME\tFILL_PATH"
    local fzf_list
    fzf_list="$(for f in "${sorted_files[@]}"; do
        local bname dir_name rel_path size
        bname="$(basename "$f")"
        dir_name="$(basename "$(dirname "$f")")"
        size="$(du -sh "$f" 2>/dev/null | cut -f1)"
        printf '%s/%s\t%s\t%s\n' "$dir_name" "$bname" "$size" "$f"
    done)"

    local selected_line
    selected_line="$(printf '%s\n' "$fzf_list" | \
        fzf \
            --prompt "  🖼️   Select wallpaper: " \
            --header "↵=apply  ctrl-p=preview  ctrl-d=delete  ESC=cancel" \
            --height=85% \
            --border=rounded \
            --delimiter='\t' \
            --with-nth='1,2' \
            --nth=1 \
            --preview="$(printf '%s' "$preview_cmd" | \
                         sed 's|%s|{4}|g')" \
            --preview-window='right:55%:wrap' \
            --color="hl:$(printf '\033[38;2;203;166;247m' | sed 's/\033\[//;s/m//')" \
            --color="hl+:$(printf '\033[38;2;245;194;231m' | sed 's/\033\[//;s/m//')" \
            --bind='ctrl-p:preview-page-down' \
            --bind='ctrl-u:preview-page-up' \
            2>/dev/null || echo '')"

    if [[ -z "$selected_line" ]]; then
        wp_info "No wallpaper selected"
        printf '\n'
        return 0
    fi

    local selected_file
    selected_file="$(printf '%s' "$selected_line" | awk -F'\t' '{print $4}')"

    [[ -z "$selected_file" ]] || [[ ! -f "$selected_file" ]] && {
        wp_fail "Invalid selection"
        return 1
    }

    wp_kv "Selected" "$(basename "$selected_file")"
    wp_step "Applying wallpaper..."

    if wp_set_backend "$selected_file"; then
        wp_ok "Wallpaper applied: $(basename "$selected_file")"
        wp_notify "🖼️  Wallpaper Set" "$(basename "$selected_file")" "$selected_file"
    else
        wp_fail "Failed to apply wallpaper"
        return 1
    fi

    printf '\n'
}
