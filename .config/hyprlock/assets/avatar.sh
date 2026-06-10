#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — AVATAR GENERATOR                             ║
# ║           Generate or set the lock screen avatar                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly AVATAR_PATH="${HOME}/.face"
readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/avatar.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🖼️ AVATAR SOURCES
# ═══════════════════════════════════════════════════════════════════════════════

find_avatar() {
    local sources=(
        "${HOME}/.face"
        "${HOME}/.face.icon"
        "${HOME}/.config/user-avatar.png"
        "${HOME}/.local/share/pixmaps/faces/user.png"
        "/var/lib/AccountsService/icons/${USER}"
    )

    for src in "${sources[@]}"; do
        if [[ -f "${src}" ]]; then
            echo "${src}"
            return 0
        fi
    done

    return 1
}

generate_avatar() {
    local size="${1:-256}"
    local output="${2:-${AVATAR_PATH}}"

    if ! command -v convert &>/dev/null; then
        echo "ImageMagick required to generate avatar"
        return 1
    fi

    # Load ASH colors
    local primary="#cba6f7"
    local base="#1e1e2e"
    local colors_sh="${CACHE_DIR}/colors/current.sh"

    if [[ -f "${colors_sh}" ]]; then
        # shellcheck source=/dev/null
        source "${colors_sh}" 2>/dev/null || true
        primary="#${ASH_PRIMARY:-cba6f7}"
        base="#${ASH_BASE:-1e1e2e}"
    fi

    # Generate initial-based avatar
    local initial="${USER:0:1}"
    initial="${initial^^}"

    convert \
        -size "${size}x${size}" \
        "gradient:${primary}-${base}" \
        -gravity center \
        -font "JetBrainsMono-Bold" \
        -pointsize "$(( size / 2 ))" \
        -fill "#cdd6f4" \
        -annotate 0 "${initial}" \
        -blur 0x2 \
        "${output}" \
        2>/dev/null && {
        echo "Avatar generated: ${output}"
        log "INFO" "Avatar generated: ${output}"
    } || {
        echo "Avatar generation failed"
        log "ERROR" "Avatar generation failed"
        return 1
    }
}

set_avatar() {
    local source="$1"

    if [[ ! -f "${source}" ]]; then
        echo "Source file not found: ${source}"
        return 1
    fi

    # Convert and resize to standard avatar size
    convert "${source}" \
        -resize "256x256^" \
        -gravity center \
        -extent "256x256" \
        -strip \
        "${AVATAR_PATH}" \
        2>/dev/null && {
        echo "Avatar set from: ${source}"
        log "INFO" "Avatar set: ${source} → ${AVATAR_PATH}"
    } || {
        # Fallback: simple copy
        cp "${source}" "${AVATAR_PATH}"
        echo "Avatar copied from: ${source}"
        log "INFO" "Avatar copied: ${source}"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-auto}"
    local arg2="${2:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        auto | "")
            # Try to find existing avatar
            local existing
            if existing=$(find_avatar 2>/dev/null); then
                if [[ "${existing}" != "${AVATAR_PATH}" ]]; then
                    set_avatar "${existing}"
                else
                    echo "Avatar already set: ${AVATAR_PATH}"
                fi
            else
                # Generate one
                echo "No avatar found — generating initial-based avatar"
                generate_avatar 256 "${AVATAR_PATH}"
            fi
            ;;

        generate | gen)
            generate_avatar "${arg2:-256}" "${AVATAR_PATH}"
            ;;

        set)
            if [[ -z "${arg2}" ]]; then
                echo "Usage: avatar.sh set <image-path>"
                exit 1
            fi
            set_avatar "${arg2}"
            ;;

        path)
            find_avatar 2>/dev/null || echo "${AVATAR_PATH} (not found)"
            ;;

        check)
            if find_avatar &>/dev/null; then
                echo "Avatar found: $(find_avatar)"
            else
                echo "No avatar found"
                exit 1
            fi
            ;;

        *)
            echo "Usage: avatar.sh [auto|generate|set PATH|path|check]"
            exit 1
            ;;
    esac
}

main "$@"