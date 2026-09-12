#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper info                                           ║
# ║  Current wallpaper metadata • dominant colors • EXIF • system stats             ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_INFO_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_INFO_LOADED=1

set -euo pipefail

_info_dominant_colors() {
    local file="$1"  count="${2:-5}"

    if command -v magick &>/dev/null; then
        magick "$file" \
            -colors "$count" \
            -format '%c' histogram:info: 2>/dev/null | \
        grep -oP '#[0-9a-fA-F]{6}' | head "$count"
    elif command -v convert &>/dev/null; then
        convert "$file" \
            -colors "$count" \
            -format '%c' histogram:info: 2>/dev/null | \
        grep -oP '#[0-9a-fA-F]{6}' | head "$count"
    else
        echo "imagemagick required"
    fi
}

_info_color_swatch() {
    local hex="$1"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        local r g b
        r=$(( 16#${hex:1:2} ))
        g=$(( 16#${hex:3:2} ))
        b=$(( 16#${hex:5:2} ))
        printf '\033[48;2;%d;%d;%dm  \033[0m' "$r" "$g" "$b"
    fi
}

_info_exif() {
    local file="$1"
    if command -v exiftool &>/dev/null; then
        exiftool -s -CreateDate -Make -Model -Software \
            -ImageWidth -ImageHeight "$file" 2>/dev/null | \
        while IFS=' : ' read -r key val; do
            [[ -n "$val" ]] && wp_kv "  EXIF: ${key}" "$val"
        done
    fi
}

_info_library_stats() {
    wp_section "📊" "Wallpaper Library Statistics" "$(_wteal)"

    local total=0
    declare -A ext_counts=()
    declare -A dir_counts=()

    while IFS= read -r f; do
        (( total++ )) || true
        local ext="${f##*.}"
        ext_counts["${ext,,}"]=$(( ${ext_counts["${ext,,}"]:-0} + 1 ))
        local dir
        dir="$(basename "$(dirname "$f")")"
        dir_counts["$dir"]=$(( ${dir_counts["$dir"]:-0} + 1 ))
    done < <(wp_find_all)

    local total_size
    total_size="$(find "$_WP_LIB_DIR" "$_WP_USER_DIR" -type f \
                  \( -name '*.jpg' -o -name '*.png' -o -name '*.webp' \) \
                  2>/dev/null | xargs du -sb 2>/dev/null | \
                  awk '{sum+=$1}END{
                    if(sum>=1073741824) printf "%.1f GB", sum/1073741824
                    else if(sum>=1048576) printf "%.1f MB", sum/1048576
                    else printf "%.1f KB", sum/1024
                  }')"

    wp_kv "Total wallpapers" "$total"
    wp_kv "Total size"       "${total_size:-?}"
    wp_kv "Library path"     "${_WP_LIB_DIR/#$HOME/~}"
    wp_kv "User path"        "${_WP_USER_DIR/#$HOME/~}"

    # By extension
    printf '\n  %sBy format:%s\n' "$(_wdim)" "$(_wr)"
    for ext in "${!ext_counts[@]}"; do
        printf '    %s%-8s%s %s%d%s\n' \
            "$(_wsky)" ".${ext}" "$(_wr)" \
            "$(_wdim)" "${ext_counts[$ext]}" "$(_wr)"
    done | sort

    # Top categories
    printf '\n  %sTop categories:%s\n' "$(_wdim)" "$(_wr)"
    for dir in "${!dir_counts[@]}"; do
        printf '%d %s\n' "${dir_counts[$dir]}" "$dir"
    done | sort -rn | head -8 | \
    while IFS=' ' read -r cnt dir; do
        printf '    %s%-20s%s %s%d%s\n' \
            "$(_wpeach)" "$dir" "$(_wr)" \
            "$(_wdim)" "$cnt" "$(_wr)"
    done
}

ash_wp_info() {
    local show_colors=1
    local show_exif=0
    local show_stats=0
    local target_file=""

    for arg in "${@:-}"; do
        case "$arg" in
            --no-colors)   show_colors=0  ;;
            --exif|-e)     show_exif=1    ;;
            --stats|-s)    show_stats=1   ;;
            --all|-a)      show_colors=1; show_exif=1; show_stats=1 ;;
            *)             target_file="$arg" ;;
        esac
    done

    wp_section "📋" "Wallpaper Information" "$(_wlav)"

    # ── System / Backend ──────────────────────────────────────────────────────────
    wp_kv "Backend"       "$WP_BACKEND"
    wp_kv "Library"       "${_WP_LIB_DIR/#$HOME/~}"
    wp_kv "Total"         "$(wp_count_all) wallpapers"

    # swww query
    if [[ "$WP_BACKEND" == "swww" ]] && pgrep -x swww-daemon &>/dev/null; then
        local swww_info
        swww_info="$(swww query 2>/dev/null | head -3)"
        if [[ -n "$swww_info" ]]; then
            printf '\n  %sswww query:%s\n' "$(_wdim)" "$(_wr)"
            while IFS= read -r line; do
                printf '  %s%s%s\n' "$(_wdim)" "$line" "$(_wr)"
            done <<< "$swww_info"
        fi
    fi

    # ── Current wallpaper ─────────────────────────────────────────────────────────
    local current="${target_file:-$(wp_get_current)}"

    wp_section "🖼️ " "Current Wallpaper" "$(_wpink)"

    if [[ -z "$current" ]] || [[ ! -f "$current" ]]; then
        wp_info "No current wallpaper recorded"
        [[ $show_stats -eq 1 ]] && _info_library_stats
        printf '\n'
        return 0
    fi

    local basename size dims mime ctime
    basename="$(basename "$current")"
    size="$(du -sh "$current" 2>/dev/null | cut -f1)"
    mime="$(file --mime-type -b "$current" 2>/dev/null)"
    ctime="$(stat -c '%y' "$current" 2>/dev/null | cut -d'.' -f1)"

    if command -v identify &>/dev/null; then
        dims="$(identify -format '%wx%h' "$current" 2>/dev/null)"
        local depth
        depth="$(identify -format '%[bit-depth]' "$current" 2>/dev/null)"
    elif command -v ffprobe &>/dev/null; then
        dims="$(ffprobe -v quiet -select_streams v:0 \
            -show_entries stream=width,height -of csv=p=0 "$current" \
            2>/dev/null | head -1 | tr ',' 'x')"
    fi

    wp_kv "Filename"   "$basename"
    wp_kv "Path"       "${current/#$HOME/~}"
    wp_kv "Type"       "$mime"
    wp_kv "Size"       "$size"
    [[ -n "${dims:-}" ]] && wp_kv "Dimensions" "${dims} px"
    [[ -n "${depth:-}" ]] && wp_kv "Bit depth"  "$depth"
    wp_kv "Modified"   "$ctime"

    # ── Terminal preview ──────────────────────────────────────────────────────────
    if command -v chafa &>/dev/null && [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 0 ]]; then
        printf '\n'
        chafa --size=60x18 --symbols=block,border "$current" 2>/dev/null | \
            sed 's/^/  /'
        printf '\n'
    fi

    # ── Dominant colors ───────────────────────────────────────────────────────────
    if [[ $show_colors -eq 1 ]]; then
        wp_section "🎨" "Dominant Colors" "$(_wpeach)"
        printf '\n'
        local -a colors=()
        mapfile -t colors < <(_info_dominant_colors "$current" 6)

        if [[ ${#colors[@]} -gt 0 ]]; then
            printf '  '
            for hex in "${colors[@]}"; do
                [[ -z "$hex" ]] && continue
                printf '%s %s%s%s  ' \
                    "$(_info_color_swatch "$hex")" \
                    "$(_wdim)" "$hex" "$(_wr)"
            done
            printf '\n'
        else
            wp_info "Could not extract colors  (install imagemagick)"
        fi
    fi

    # ── EXIF ─────────────────────────────────────────────────────────────────────
    if [[ $show_exif -eq 1 ]]; then
        wp_section "📷" "EXIF Data" "$(_wsapph)"
        _info_exif "$current"
    fi

    # ── Library stats ─────────────────────────────────────────────────────────────
    [[ $show_stats -eq 1 ]] && _info_library_stats

    printf '\n'
}
