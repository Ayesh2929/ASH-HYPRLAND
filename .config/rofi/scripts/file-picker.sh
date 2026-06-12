#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI FILE PICKER                             ║
# ║           FZF-powered file browser with preview                            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🗂️ FILE BROWSER
# ═══════════════════════════════════════════════════════════════════════════════

get_icon() {
    local file="$1"
    local ext="${file##*.}"

    case "${ext,,}" in
        jpg|jpeg|png|gif|webp|bmp|avif|svg) echo "🖼️" ;;
        mp4|mkv|avi|mov|webm|flv|wmv)       echo "🎬" ;;
        mp3|flac|ogg|wav|aac|opus)           echo "🎵" ;;
        pdf)                                  echo "📄" ;;
        doc|docx|odt)                         echo "📝" ;;
        xls|xlsx|ods)                         echo "📊" ;;
        ppt|pptx|odp)                         echo "📊" ;;
        zip|tar|gz|bz2|xz|rar|7z)           echo "📦" ;;
        sh|bash|fish|zsh)                     echo "📜" ;;
        py)                                   echo "🐍" ;;
        js|ts|jsx|tsx)                        echo "🟨" ;;
        rs)                                   echo "🦀" ;;
        go)                                   echo "🐹" ;;
        lua)                                  echo "🌙" ;;
        json|yaml|toml|ini|conf)             echo "⚙️" ;;
        md|rst|txt)                           echo "📝" ;;
        html|css|scss)                        echo "🌐" ;;
        *)                                    echo "📄" ;;
    esac
}

browse_files() {
    local search_dir="${1:-${HOME}}"
    local search_type="${2:-all}"  # all, files, dirs

    # Build find command
    local find_args=("--hidden" "--follow" "--exclude" ".git" "--exclude" "node_modules")

    case "${search_type}" in
        files) find_args+=("--type" "f") ;;
        dirs)  find_args+=("--type" "d") ;;
        *)     ;; # all
    esac

    # Run fd or find
    local results=""
    if command -v fd &>/dev/null; then
        results=$(fd "${find_args[@]}" . "${search_dir}" 2>/dev/null)
    else
        results=$(find "${search_dir}" \
            -maxdepth 5 \
            -not -path "*/.git/*" \
            -not -path "*/node_modules/*" \
            2>/dev/null)
    fi

    echo "${results}"
}

open_file() {
    local file="$1"

    if [[ -d "${file}" ]]; then
        nemo "${file}" 2>/dev/null & disown
    elif [[ -f "${file}" ]]; then
        xdg-open "${file}" 2>/dev/null & disown
    fi
}

main() {
    mkdir -p "${CACHE_DIR}/logs"

    # Choose search mode
    local mode
    mode=$(echo -e "📁 Browse Home\n🔍 Search Files\n📂 Recent Files\n🗂️ Common Locations" \
        | rofi \
            -dmenu \
            -i \
            -p "📁 File Picker" \
            -theme-str 'window { width: 420px; } listview { lines: 4; }' \
            2>/dev/null) || exit 0

    local search_dir="${HOME}"
    case "${mode}" in
        "📁 Browse Home")  search_dir="${HOME}" ;;
        "🔍 Search Files")
            local query
            query=$(rofi \
                -dmenu \
                -p "🔍 Search" \
                -theme-str 'window { width: 400px; } listview { lines: 0; }' \
                < /dev/null 2>/dev/null) || exit 0
            ;;
        "📂 Recent Files")
            # Use recently used files
            if command -v python3 &>/dev/null; then
                local recent
                recent=$(python3 -c "
import xml.etree.ElementTree as ET
import os
f = os.path.expanduser('~/.local/share/recently-used.xbel')
if not os.path.exists(f):
    exit()
tree = ET.parse(f)
root = tree.getroot()
for bookmark in list(root)[:20]:
    href = bookmark.get('href', '')
    if href.startswith('file://'):
        path = href[7:].replace('%20', ' ')
        if os.path.exists(path):
            print(path)
" 2>/dev/null)
                if [[ -n "${recent}" ]]; then
                    local selected
                    selected=$(echo "${recent}" | rofi \
                        -dmenu \
                        -i \
                        -p "📂 Recent" \
                        -theme-str 'window { width: 700px; } listview { lines: 15; }' \
                        2>/dev/null) || exit 0
                    [[ -n "${selected}" ]] && open_file "${selected}"
                    exit 0
                fi
            fi
            ;;
        "🗂️ Common Locations")
            local location
            location=$(echo -e \
                "🏠 Home ($HOME)\n" \
                "📥 Downloads ($HOME/Downloads)\n" \
                "🖼️ Pictures ($HOME/Pictures)\n" \
                "🎬 Videos ($HOME/Videos)\n" \
                "🎵 Music ($HOME/Music)\n" \
                "📁 Documents ($HOME/Documents)\n" \
                "⚙️ Config ($HOME/.config)\n" \
                "🔧 Dotfiles ($HOME/.dotfiles)" \
                | rofi \
                    -dmenu \
                    -i \
                    -p "📍 Location" \
                    -theme-str 'window { width: 450px; } listview { lines: 8; }' \
                    2>/dev/null) || exit 0
            search_dir=$(echo "${location}" | grep -oP '\(.*\)' | tr -d '()' | envsubst)
            ;;
    esac

    # Browse files with preview
    local selected
    selected=$(browse_files "${search_dir}" "all" | \
        while IFS= read -r file; do
            local icon
            icon=$(get_icon "${file}")
            echo "${icon} ${file}"
        done | \
        rofi \
            -dmenu \
            -i \
            -p "📁 Select File" \
            -theme-str '
                window { width: 750px; }
                listview { lines: 16; }
                element { font-family: "JetBrainsMono Nerd Font"; font-size: 12px; }
            ' \
            2>/dev/null) || {
        log "INFO" "File picker cancelled"
        exit 0
    }

    # Strip icon
    local file_path
    file_path=$(echo "${selected}" | sed 's/^[^ ]* //')

    if [[ -n "${file_path}" ]]; then
        # Show action menu
        local action
        action=$(echo -e "🔓 Open\n📋 Copy Path\n🔍 Open Terminal Here\n📁 Open Parent Folder" \
            | rofi \
                -dmenu \
                -i \
                -p "📁 Action for: $(basename "${file_path}")" \
                -theme-str 'window { width: 420px; } listview { lines: 4; }' \
                2>/dev/null) || exit 0

        case "${action}" in
            "🔓 Open")
                open_file "${file_path}"
                ;;
            "📋 Copy Path")
                echo -n "${file_path}" | wl-copy 2>/dev/null
                notify-send "📋 Copied" "${file_path}" --app-name="ASH Files" \
                    --expire-time=2000 2>/dev/null || true
                ;;
            "🔍 Open Terminal Here")
                local dir
                dir=$(dirname "${file_path}")
                kitty --working-directory "${dir}" 2>/dev/null &
                disown
                ;;
            "📁 Open Parent Folder")
                local dir
                dir=$(dirname "${file_path}")
                nemo "${dir}" 2>/dev/null &
                disown
                ;;
        esac
        log "INFO" "File picked: ${file_path} → ${action}"
    fi
}

main "$@"