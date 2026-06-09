#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WALLPAPER PICKER                             ║
# ║           Rofi image picker with thumbnail generation                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: wallpaper-picker.sh [MODE]
#
# MODES:
#   (none)   — Interactive Rofi picker
#   random   — Pick random wallpaper
#   next     — Next wallpaper in sorted list
#   prev     — Previous wallpaper in sorted list
#   restore  — Restore last wallpaper
#   list     — List all wallpapers
#   add PATH — Add wallpaper from path/URL

set -euo pipefail

readonly WALL_DIR="${HOME}/Pictures/Wallpapers"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly THUMB_DIR="${CACHE_DIR}/thumbnails"
readonly LAST_WALL="${CACHE_DIR}/wallpaper/last"
readonly HISTORY_FILE="${CACHE_DIR}/wallpaper/history"
readonly INDEX_FILE="${CACHE_DIR}/wallpaper/index"
readonly LOG_FILE="${CACHE_DIR}/logs/wallpaper.log"
readonly THEME_ENGINE="${HOME}/.config/hypr/scripts/theme/theme-engine.sh"

# Thumbnail settings
readonly THUMB_SIZE="400x225"
readonly THUMB_FORMAT="jpg"
readonly THUMB_QUALITY=85

# Supported image formats
readonly -a IMAGE_EXTS=("jpg" "jpeg" "png" "webp" "gif" "bmp" "tiff" "avif" "heic")

# Colors
readonly RESET='\033[0m'
readonly CYAN='\033[96m'
readonly GREEN='\033[92m'
readonly YELLOW='\033[93m'
readonly RED='\033[91m'
readonly BOLD='\033[1m'

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  ${CYAN}→${RESET} $*"; }
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET} $*" >&2; }
err()  { echo -e "  ${RED}✗${RESET} $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🗂️ INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

init() {
    mkdir -p \
        "${WALL_DIR}" \
        "${THUMB_DIR}" \
        "${CACHE_DIR}/wallpaper" \
        "${CACHE_DIR}/logs"

    # Create subdirectory structure
    local subdirs=("dark" "light" "anime" "abstract" "cyberpunk" "nature"
                   "landscapes" "space" "minimal" "gradient")
    for sub in "${subdirs[@]}"; do
        mkdir -p "${WALL_DIR}/${sub}"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 WALLPAPER DISCOVERY
# ═══════════════════════════════════════════════════════════════════════════════

find_wallpapers() {
    local dir="${1:-${WALL_DIR}}"
    local walls=()

    # Build find expression for all supported formats
    local find_args=()
    for ext in "${IMAGE_EXTS[@]}"; do
        find_args+=(-o -iname "*.${ext}")
    done
    # Remove leading -o
    find_args=("${find_args[@]:1}")

    while IFS= read -r file; do
        walls+=("${file}")
    done < <(find "${dir}" -type f \( "${find_args[@]}" \) 2>/dev/null | sort)

    printf '%s\n' "${walls[@]}"
}

count_wallpapers() {
    find_wallpapers | wc -l
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖼️ THUMBNAIL GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

get_thumb_path() {
    local wall="$1"
    local hash
    hash=$(echo "${wall}" | md5sum | cut -d' ' -f1)
    echo "${THUMB_DIR}/${hash}.${THUMB_FORMAT}"
}

generate_thumbnail() {
    local wall="$1"
    local thumb
    thumb=$(get_thumb_path "${wall}")

    if [[ -f "${thumb}" ]]; then
        # Check if source is newer than thumbnail
        if [[ "${wall}" -nt "${thumb}" ]]; then
            rm -f "${thumb}"
        else
            echo "${thumb}"
            return 0
        fi
    fi

    if ! command -v convert &>/dev/null; then
        echo "${wall}"
        return 0
    fi

    convert "${wall}" \
        -auto-orient \
        -thumbnail "${THUMB_SIZE}^" \
        -gravity center \
        -extent "${THUMB_SIZE}" \
        -quality "${THUMB_QUALITY}" \
        "${thumb}" \
        2>/dev/null || {
        echo "${wall}"
        return 0
    }

    echo "${thumb}"
}

# Generate all thumbnails with progress
generate_all_thumbnails() {
    local walls=()
    while IFS= read -r wall; do
        walls+=("${wall}")
    done < <(find_wallpapers)

    local total=${#walls[@]}
    local done=0

    info "Generating ${total} thumbnails..."

    for wall in "${walls[@]}"; do
        generate_thumbnail "${wall}" > /dev/null
        ((done++)) || true

        # Progress every 10 items
        if (( done % 10 == 0 )) || (( done == total )); then
            printf "\r  ${CYAN}→${RESET} %d/%d thumbnails..." "${done}" "${total}"
        fi
    done
    echo ""
    ok "Thumbnails generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 WALLPAPER APPLICATION
# ═══════════════════════════════════════════════════════════════════════════════

apply_wallpaper() {
    local wall="$1"

    if [[ ! -f "${wall}" ]]; then
        err "Wallpaper not found: ${wall}"
        return 1
    fi

    info "Applying: $(basename "${wall}")"

    # Start swww daemon if not running
    if ! pgrep -x swww-daemon &>/dev/null; then
        swww-daemon --format xrgb &>/dev/null &
        sleep 0.5
    fi

    # Apply wallpaper with transition
    if command -v swww &>/dev/null && pgrep -x swww-daemon &>/dev/null; then
        swww img "${wall}" \
            --transition-type grow \
            --transition-pos "0.5,0.5" \
            --transition-duration 2.5 \
            --transition-fps 60 \
            --transition-bezier "0.34,1.56,0.64,1.0" \
            2>/dev/null || warn "swww apply failed"
    elif command -v swaybg &>/dev/null; then
        pkill swaybg 2>/dev/null || true
        swaybg -i "${wall}" -m fill &
        disown
    elif command -v feh &>/dev/null; then
        feh --bg-scale "${wall}"
    fi

    # Save to history
    echo "${wall}" > "${LAST_WALL}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${wall}" >> "${HISTORY_FILE}"

    # Keep history to last 100
    if [[ -f "${HISTORY_FILE}" ]]; then
        tail -100 "${HISTORY_FILE}" > "${HISTORY_FILE}.tmp" \
            && mv "${HISTORY_FILE}.tmp" "${HISTORY_FILE}" || true
    fi

    # Run theme engine
    if [[ -x "${THEME_ENGINE}" ]]; then
        "${THEME_ENGINE}" "${wall}" "apply" &
        disown
    fi

    ok "Wallpaper applied: $(basename "${wall}")"
    log "INFO" "Applied: ${wall}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 ROFI INTERACTIVE PICKER
# ═══════════════════════════════════════════════════════════════════════════════

rofi_picker() {
    # Find all wallpapers
    local walls=()
    while IFS= read -r wall; do
        walls+=("${wall}")
    done < <(find_wallpapers)

    if (( ${#walls[@]} == 0 )); then
        notify-send "🖼️ Wallpaper Picker" \
            "No wallpapers found in:\n${WALL_DIR}\n\nAdd images to get started!" \
            --app-name="ASH Wallpaper" \
            --expire-time=5000 \
            2>/dev/null || true
        err "No wallpapers found in ${WALL_DIR}"
        return 1
    fi

    info "Found ${#walls[@]} wallpapers"

    # Build Rofi input
    local rofi_input=""
    local current_wall=""
    [[ -f "${LAST_WALL}" ]] && current_wall=$(cat "${LAST_WALL}")

    for wall in "${walls[@]}"; do
        local thumb
        thumb=$(generate_thumbnail "${wall}")
        local name
        name=$(basename "${wall}")
        local dir
        dir=$(basename "$(dirname "${wall}")")

        # Mark current wallpaper
        local prefix=""
        [[ "${wall}" == "${current_wall}" ]] && prefix="★ "

        rofi_input+="${prefix}${dir}/${name}\0icon\x1f${thumb}\n"
    done

    # Show Rofi
    local selected
    selected=$(echo -e "${rofi_input}" | rofi \
        -dmenu \
        -i \
        -p "🖼️ Wallpaper" \
        -theme-str 'window { width: 900px; }' \
        -theme-str 'listview { columns: 3; lines: 4; }' \
        -theme-str 'element { padding: 8px; }' \
        -theme-str 'element-icon { size: 120px; }' \
        -show-icons \
        -format 'i' \
        2>/dev/null) || {
        info "Picker cancelled"
        return 0
    }

    # Get selected wallpaper by index
    local idx="${selected}"
    local chosen="${walls[${idx}]}"

    if [[ -n "${chosen}" ]]; then
        apply_wallpaper "${chosen}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎲 RANDOM WALLPAPER
# ═══════════════════════════════════════════════════════════════════════════════

random_wallpaper() {
    local subdir="${1:-}"
    local search_dir="${WALL_DIR}"

    # Search specific subdirectory
    if [[ -n "${subdir}" ]] && [[ -d "${WALL_DIR}/${subdir}" ]]; then
        search_dir="${WALL_DIR}/${subdir}"
    fi

    local walls=()
    while IFS= read -r wall; do
        walls+=("${wall}")
    done < <(find_wallpapers "${search_dir}")

    if (( ${#walls[@]} == 0 )); then
        err "No wallpapers found in ${search_dir}"
        return 1
    fi

    # Avoid repeating the last wallpaper
    local current=""
    [[ -f "${LAST_WALL}" ]] && current=$(cat "${LAST_WALL}")

    local selected
    local attempts=0
    while (( attempts < 10 )); do
        local idx=$(( RANDOM % ${#walls[@]} ))
        selected="${walls[${idx}]}"
        [[ "${selected}" != "${current}" ]] && break
        ((attempts++)) || true
    done

    apply_wallpaper "${selected}"
    notify-send "🎲 Random Wallpaper" \
        "$(basename "${selected}")" \
        --app-name="ASH Wallpaper" \
        --expire-time=2500 \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ⏭️ NEXT / PREVIOUS
# ═══════════════════════════════════════════════════════════════════════════════

next_wallpaper() {
    local direction="${1:-next}"

    local walls=()
    while IFS= read -r wall; do
        walls+=("${wall}")
    done < <(find_wallpapers)

    if (( ${#walls[@]} == 0 )); then
        err "No wallpapers found"
        return 1
    fi

    local current=""
    [[ -f "${LAST_WALL}" ]] && current=$(cat "${LAST_WALL}")

    local current_idx=-1
    for i in "${!walls[@]}"; do
        if [[ "${walls[$i]}" == "${current}" ]]; then
            current_idx=$i
            break
        fi
    done

    local new_idx
    if [[ "${direction}" == "next" ]]; then
        new_idx=$(( (current_idx + 1) % ${#walls[@]} ))
    else
        new_idx=$(( (current_idx - 1 + ${#walls[@]}) % ${#walls[@]} ))
    fi

    apply_wallpaper "${walls[${new_idx}]}"
    notify-send "🖼️ Wallpaper" \
        "$(basename "${walls[${new_idx}]}")" \
        --app-name="ASH Wallpaper" \
        --expire-time=2000 \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# ➕ ADD WALLPAPER
# ═══════════════════════════════════════════════════════════════════════════════

add_wallpaper() {
    local source="$1"
    local dest_dir="${2:-${WALL_DIR}/dark}"

    if [[ "${source}" =~ ^https?:// ]]; then
        # Download from URL
        local filename
        filename=$(basename "${source%%\?*}")
        local dest="${dest_dir}/${filename}"

        info "Downloading: ${source}"
        curl -L --progress-bar -o "${dest}" "${source}" || {
            err "Download failed: ${source}"
            return 1
        }
        ok "Downloaded: ${dest}"
        apply_wallpaper "${dest}"

    elif [[ -f "${source}" ]]; then
        # Copy local file
        local dest="${dest_dir}/$(basename "${source}")"
        cp "${source}" "${dest}"
        ok "Added: ${dest}"
        apply_wallpaper "${dest}"

    else
        err "Source not found: ${source}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📋 LIST WALLPAPERS
# ═══════════════════════════════════════════════════════════════════════════════

list_wallpapers() {
    local walls=()
    while IFS= read -r wall; do
        walls+=("${wall}")
    done < <(find_wallpapers)

    local current=""
    [[ -f "${LAST_WALL}" ]] && current=$(cat "${LAST_WALL}")

    echo ""
    echo -e "  ${BOLD}🖼️ Wallpapers (${#walls[@]} total)${RESET}"
    echo -e "  $(printf '─%.0s' {1..50})"
    echo ""

    for wall in "${walls[@]}"; do
        local marker=" "
        [[ "${wall}" == "${current}" ]] && marker="★"
        echo -e "  ${CYAN}${marker}${RESET} ${wall}"
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local mode="${1:-picker}"
    shift || true

    init

    case "${mode}" in
        picker | "")
            rofi_picker
            ;;

        random)
            random_wallpaper "${1:-}"
            ;;

        next)
            next_wallpaper "next"
            ;;

        prev | previous)
            next_wallpaper "prev"
            ;;

        restore)
            if [[ -f "${LAST_WALL}" ]]; then
                local last
                last=$(cat "${LAST_WALL}")
                if [[ -f "${last}" ]]; then
                    apply_wallpaper "${last}"
                    ok "Restored: $(basename "${last}")"
                else
                    warn "Last wallpaper not found: ${last}"
                fi
            else
                warn "No wallpaper history found"
            fi
            ;;

        add)
            add_wallpaper "${1:-}" "${2:-}"
            ;;

        list)
            list_wallpapers
            ;;

        thumbs | thumbnails)
            generate_all_thumbnails
            ;;

        apply)
            apply_wallpaper "${1:-}"
            ;;

        count)
            echo "Wallpapers: $(count_wallpapers)"
            ;;

        *)
            # Try to apply as direct path
            if [[ -f "${mode}" ]]; then
                apply_wallpaper "${mode}"
            else
                echo "Usage: wallpaper-picker.sh [picker|random|next|prev|restore|add|list|apply PATH]"
                exit 1
            fi
            ;;
    esac
}

main "$@"