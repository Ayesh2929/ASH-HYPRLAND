#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper random                                         ║
# ║  Pick random wallpaper with category filter and exclusion logic                  ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_RANDOM_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_RANDOM_LOADED=1

set -euo pipefail

ash_wp_random() {
    local category=""
    local exclude_current=1
    local tag_filter=""
    local count=1

    for arg in "${@:-}"; do
        case "$arg" in
            --category=*|-c=*)    category="${arg#*=}"       ;;
            --tag=*|-t=*)         tag_filter="${arg#*=}"     ;;
            --allow-repeat)       exclude_current=0          ;;
            --count=*)            count="${arg#*=}"          ;;
        esac
    done

    wp_section "🎲" "Random Wallpaper" "$(_wpeach)"

    wp_kv "Backend"    "$WP_BACKEND"
    wp_kv "Library"    "$_WP_LIB_DIR"
    [[ -n "$category" ]] && wp_kv "Category" "$category"
    [[ -n "$tag_filter" ]] && wp_kv "Tag" "$tag_filter"

    # ── Find candidates ───────────────────────────────────────────────────────────
    local current
    current="$(wp_get_current)"

    local -a candidates=()

    if [[ -n "$category" ]]; then
        # Search in specific category directory
        local cat_dir
        for search_base in "$_WP_LIB_DIR" "$_WP_USER_DIR"; do
            for possible in "${search_base}/${category}" "${search_base}/${category,,}"; do
                [[ -d "$possible" ]] && cat_dir="$possible" && break 2
            done
        done

        if [[ -n "${cat_dir:-}" ]]; then
            mapfile -t candidates < <(
                find "$cat_dir" \( -name '*.jpg' -o -name '*.png' \
                    -o -name '*.webp' -o -name '*.gif' \) 2>/dev/null | sort
            )
        else
            wp_warn "Category not found: ${category}"
            wp_info "Available categories:"
            find "$_WP_LIB_DIR" "$_WP_USER_DIR" -maxdepth 1 -mindepth 1 -type d \
                2>/dev/null | while IFS= read -r d; do
                    printf '    %s•%s  %s\n' "$(_wdim)" "$(_wr)" "$(basename "$d")"
                done
        fi
    else
        mapfile -t candidates < <(wp_find_all)
    fi

    if [[ ${#candidates[@]} -eq 0 ]]; then
        wp_fail "No wallpapers found"
        wp_info "Add wallpapers to: ${_WP_LIB_DIR}"
        wp_info "Or download: ash wp download"
        return 1
    fi

    wp_kv "Total available" "${#candidates[@]}"

    # Exclude current wallpaper
    if [[ $exclude_current -eq 1 ]] && [[ -n "$current" ]]; then
        local filtered=()
        for c in "${candidates[@]}"; do
            [[ "$c" != "$current" ]] && filtered+=("$c")
        done
        [[ ${#filtered[@]} -gt 0 ]] && candidates=("${filtered[@]}")
    fi

    # Shuffle and pick
    local chosen_files=()
    mapfile -t chosen_files < <(
        printf '%s\n' "${candidates[@]}" | shuf | head "$count"
    )

    if [[ ${#chosen_files[@]} -eq 0 ]]; then
        wp_fail "No wallpapers available after filtering"
        return 1
    fi

    # Apply (if count=1, apply directly; otherwise preview list)
    if [[ $count -eq 1 ]]; then
        local chosen="${chosen_files[0]}"
        wp_kv "Selected" "$(basename "$chosen")"
        wp_step "Setting wallpaper..."

        if wp_set_backend "$chosen"; then
            wp_ok "Wallpaper applied: $(basename "$chosen")"
            wp_notify "🎲 Random Wallpaper" "$(basename "$chosen")" "$chosen"
        else
            wp_fail "Failed to set wallpaper"
            return 1
        fi
    else
        wp_kv "Selected" "${count} wallpapers"
        printf '\n  %sSelected files:%s\n' "$(_wdim)" "$(_wr)"
        for f in "${chosen_files[@]}"; do
            printf '    %s•%s  %s\n' "$(_wdim)" "$(_wr)" "$(basename "$f")"
        done
        wp_info "Use: ash wp slideshow for rotation"
    fi

    printf '\n'
}
