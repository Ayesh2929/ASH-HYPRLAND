#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Wallpaper Picker Script                           ║
# ║                                                                              ║
# ║  Full-featured wallpaper management via Rofi custom mode.                  ║
# ║  Features: library browse, category filter, online download,               ║
# ║  AI generation, transition selection, slideshow control, multi-monitor.    ║
# ║                                                                              ║
# ║  Backend: swww (transitions), curl (download), fzf (filter)               ║
# ║  Sources: local library, Unsplash, Wallhaven, Reddit                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly WALLPAPER_DIR="${HOME}/.local/share/ash-dotfiles/wallpapers"
readonly CACHE_DIR="${HOME}/.cache/ash-dotfiles/wallpapers"
readonly STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/ash-wallpaper.state"
readonly HISTORY_FILE="${HOME}/.local/state/ash-dotfiles/wallpaper-history.log"
readonly CURRENT_FILE="${HOME}/.cache/ash-dotfiles/current-wallpaper.jpg"

# ── Transition configuration ──────────────────────────────────────────────────
readonly TRANSITION_TYPE="${ASH_WP_TRANSITION:-fade}"
readonly TRANSITION_DURATION="${ASH_WP_DURATION:-0.8}"
readonly TRANSITION_FPS="${ASH_WP_FPS:-60}"
readonly TRANSITION_BEZIER="${ASH_WP_BEZIER:-0.16,1.00,0.30,1.00}"

# ── File extensions to show ───────────────────────────────────────────────────
readonly EXTENSIONS="jpg|jpeg|png|webp|gif"

# ── Download configuration ────────────────────────────────────────────────────
readonly UNSPLASH_URL="https://source.unsplash.com/3840x2160"
readonly WALLHAVEN_API="https://wallhaven.cc/api/v1/search"
readonly DOWNLOAD_TIMEOUT=30

# ══════════════════════════════════════════════════════════════════════════════
# §02  CATEGORY DEFINITIONS
# ══════════════════════════════════════════════════════════════════════════════

declare -A CATEGORIES=(
    ["all"]="All"
    ["dark"]="Dark"
    ["light"]="Light"
    ["anime"]="Anime"
    ["space"]="Space"
    ["nature"]="Nature"
    ["abstract"]="Abstract"
    ["minimal"]="Minimal"
    ["cyberpunk"]="Cyber"
    ["retro"]="Retro"
)

declare -a CATEGORY_ORDER=(
    "all" "dark" "light" "nature" "space" "anime" "abstract" "minimal" "cyberpunk" "retro"
)

# ══════════════════════════════════════════════════════════════════════════════
# §03  TRANSITION TYPES
# ══════════════════════════════════════════════════════════════════════════════

declare -a TRANSITIONS=(
    "fade"
    "wipe"
    "grow"
    "wave"
    "outer"
    "left"
    "right"
    "top"
    "bottom"
    "center"
    "any"
    "none"
)

# ══════════════════════════════════════════════════════════════════════════════
# §04  UTILITY FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

ensure_dirs() {
    mkdir -p "$WALLPAPER_DIR" "$CACHE_DIR" \
        "${WALLPAPER_DIR}/dark" \
        "${WALLPAPER_DIR}/light" \
        "${WALLPAPER_DIR}/nature" \
        "${WALLPAPER_DIR}/space" \
        "${WALLPAPER_DIR}/anime" \
        "${WALLPAPER_DIR}/abstract" \
        "${WALLPAPER_DIR}/minimal" \
        "${WALLPAPER_DIR}/cyberpunk" \
        "${WALLPAPER_DIR}/retro" \
        "${WALLPAPER_DIR}/generated"
}

notify_wp() {
    local title="$1" msg="$2" urgency="${3:-low}"
    notify-send \
        "$title" "$msg" \
        --app-name="ASH Wallpaper" \
        --icon=image-x-generic \
        --urgency="$urgency" \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:wallpaper \
        2>/dev/null || true
}

log_history() {
    local file="$1"
    echo "$(date -Iseconds) $(basename "$file") | $file" \
        >> "$HISTORY_FILE" 2>/dev/null || true
}

get_image_dimensions() {
    local file="$1"
    if command -v identify &>/dev/null; then
        identify -format "%wx%h" "$file" 2>/dev/null || echo "?×?"
    elif command -v ffprobe &>/dev/null; then
        ffprobe -v quiet -select_streams v:0 \
            -show_entries stream=width,height \
            -of csv=p=0 "$file" 2>/dev/null | tr ',' '×' || echo "?×?"
    else
        echo "?×?"
    fi
}

get_image_size() {
    local file="$1"
    du -sh "$file" 2>/dev/null | cut -f1 || echo "?"
}

detect_category() {
    local file="$1"
    local dir
    dir=$(dirname "$file")
    local dirname_base
    dirname_base=$(basename "$dir")

    # Check if file is in a category subdirectory
    for cat in "${CATEGORY_ORDER[@]}"; do
        [[ "$dirname_base" == "$cat" ]] && echo "$cat" && return
    done

    # Fallback: guess from filename
    local filename="${file,,}"
    if   [[ "$filename" =~ anime|manga|waifu ]];  then echo "anime"
    elif [[ "$filename" =~ space|nebula|galaxy ]]; then echo "space"
    elif [[ "$filename" =~ nature|forest|ocean ]]; then echo "nature"
    elif [[ "$filename" =~ dark|night|mocha ]];    then echo "dark"
    elif [[ "$filename" =~ light|day|white ]];     then echo "light"
    elif [[ "$filename" =~ neon|cyber|punk ]];     then echo "cyberpunk"
    elif [[ "$filename" =~ retro|vintage|vhs ]];   then echo "retro"
    elif [[ "$filename" =~ abstract|art|wave ]];   then echo "abstract"
    elif [[ "$filename" =~ minimal|clean|plain ]]; then echo "minimal"
    else echo "dark"
    fi
}

get_category_icon() {
    local cat="$1"
    case "$cat" in
        dark)       echo "🌙" ;;
        light)      echo "☀" ;;
        anime)      echo "🎌" ;;
        space)      echo "🌌" ;;
        nature)     echo "🌿" ;;
        abstract)   echo "🎨" ;;
        minimal)    echo "◻" ;;
        cyberpunk)  echo "🤖" ;;
        retro)      echo "📼" ;;
        generated)  echo "🤖" ;;
        *)          echo "🖼" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  WALLPAPER APPLICATION
# ══════════════════════════════════════════════════════════════════════════════

apply_wallpaper() {
    local file="$1"
    local transition="${2:-$TRANSITION_TYPE}"
    local duration="${3:-$TRANSITION_DURATION}"
    local monitor="${4:-}"

    # Validate file exists
    if [[ ! -f "$file" ]]; then
        notify_wp "Wallpaper Error" "File not found: $(basename "$file")" "critical"
        return 1
    fi

    # Apply via swww
    if command -v swww &>/dev/null; then
        # Ensure swww daemon is running
        if ! pgrep -x swww-daemon &>/dev/null; then
            swww-daemon --format xrgb &>/dev/null &
            sleep 0.5
        fi

        local swww_args=(
            img "$file"
            --transition-type "$transition"
            --transition-duration "$duration"
            --transition-fps "$TRANSITION_FPS"
            --transition-bezier "$TRANSITION_BEZIER"
        )

        # Per-monitor
        [[ -n "$monitor" ]] && swww_args+=(--outputs "$monitor")

        swww "${swww_args[@]}" &>/dev/null && {
            # Update tracking files
            echo "$file" > "$CURRENT_FILE"
            log_history "$file"

            # Notify
            local basename
            basename=$(basename "$file")
            local dims
            dims=$(get_image_dimensions "$file")
            notify_wp \
                "🖼 Wallpaper set" \
                "${basename}\n${dims}"

            # Reload blur cache for hyprlock
            generate_blur_cache "$file" &

            return 0
        } || {
            notify_wp "Wallpaper Error" "swww failed to set wallpaper" "critical"
            return 1
        }
    else
        notify_wp "Error" "swww not installed (paru -S swww)" "critical"
        return 1
    fi
}

generate_blur_cache() {
    local file="$1"
    local blur_file="${CACHE_DIR}/blurred-current.png"

    if command -v convert &>/dev/null; then
        convert "$file" \
            -resize 1920x1080 \
            -blur "0x20" \
            "$blur_file" \
            &>/dev/null
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  ONLINE DOWNLOAD
# ══════════════════════════════════════════════════════════════════════════════

download_unsplash() {
    local query="${1:-nature minimal dark}"
    local save_dir="${WALLPAPER_DIR}/downloaded"
    mkdir -p "$save_dir"

    local timestamp
    timestamp=$(date +%s)
    local save_file="${save_dir}/unsplash_${timestamp}.jpg"

    notify_wp "󰇚 Downloading" "Fetching from Unsplash…" "low"

    if curl -sfL --max-time "$DOWNLOAD_TIMEOUT" \
        -o "$save_file" \
        "${UNSPLASH_URL}/?${query// /,}" 2>/dev/null; then
        apply_wallpaper "$save_file"
        notify_wp "󰇚 Downloaded" "$(basename "$save_file")"
    else
        notify_wp "Download failed" "Cannot connect to Unsplash" "critical"
        rm -f "$save_file"
    fi
}

download_wallhaven() {
    local query="${1:-landscape}"
    local save_dir="${WALLPAPER_DIR}/downloaded"
    mkdir -p "$save_dir"

    notify_wp "󰇚 Downloading" "Searching Wallhaven…" "low"

    local result_url
    result_url=$(curl -sf --max-time "$DOWNLOAD_TIMEOUT" \
        "${WALLHAVEN_API}?q=${query// /+}&categories=111&purity=100&atleast=1920x1080&sorting=random&order=desc" \
        2>/dev/null | \
        jq -r '.data[0].path' 2>/dev/null || echo "")

    if [[ -n "$result_url" && "$result_url" != "null" ]]; then
        local timestamp filename save_file
        timestamp=$(date +%s)
        filename=$(basename "$result_url")
        save_file="${save_dir}/wallhaven_${timestamp}_${filename}"

        curl -sfL --max-time "$DOWNLOAD_TIMEOUT" \
            -o "$save_file" "$result_url" 2>/dev/null && \
            apply_wallpaper "$save_file"
    else
        notify_wp "Download failed" "No results from Wallhaven" "critical"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  AI GENERATION
# ══════════════════════════════════════════════════════════════════════════════

generate_ai_wallpaper() {
    local prompt="${1:-dark abstract minimal desktop wallpaper 4k}"

    # Try local Stable Diffusion first
    if curl -sf http://localhost:7860/sdapi/v1/txt2img &>/dev/null; then
        notify_wp "󰚩 AI Generating" "Stable Diffusion running…" "low"

        local save_file="${WALLPAPER_DIR}/generated/sd_$(date +%s).png"
        mkdir -p "${WALLPAPER_DIR}/generated"

        local payload
        payload=$(cat << JSON
{
    "prompt": "${prompt}, 4k, wallpaper, high quality, detailed",
    "negative_prompt": "low quality, blurry, text, watermark",
    "width": 1920,
    "height": 1080,
    "steps": 30,
    "cfg_scale": 7.5,
    "sampler_name": "DPM++ 2M Karras"
}
JSON
        )

        local result
        result=$(curl -sf \
            -X POST "http://localhost:7860/sdapi/v1/txt2img" \
            -H "Content-Type: application/json" \
            -d "$payload" 2>/dev/null)

        if [[ -n "$result" ]]; then
            echo "$result" | jq -r '.images[0]' | base64 -d > "$save_file" 2>/dev/null
            apply_wallpaper "$save_file"
            notify_wp "󰚩 AI Generated" "Wallpaper created successfully"
        else
            notify_wp "AI Generation failed" "Stable Diffusion error" "critical"
        fi
    else
        notify_wp "AI Unavailable" "Start Stable Diffusion WebUI at localhost:7860" "normal"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  SLIDESHOW CONTROL
# ══════════════════════════════════════════════════════════════════════════════

toggle_slideshow() {
    local timer_file="${XDG_RUNTIME_DIR:-/tmp}/ash-slideshow.timer"

    if [[ -f "$timer_file" ]]; then
        # Stop slideshow
        local pid
        pid=$(cat "$timer_file" 2>/dev/null || echo "")
        [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
        rm -f "$timer_file"
        notify_wp "⏸ Slideshow stopped" "Manual wallpaper control active"
    else
        # Start slideshow (every 5 minutes)
        local interval=300
        (
            while true; do
                sleep "$interval"
                local walls=()
                while IFS= read -r -d '' wall; do
                    walls+=("$wall")
                done < <(find "$WALLPAPER_DIR" -type f \
                    \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) \
                    -print0 2>/dev/null)

                if [[ ${#walls[@]} -gt 0 ]]; then
                    local random_wall="${walls[$RANDOM % ${#walls[@]}]}"
                    apply_wallpaper "$random_wall" "any" 1.5 &>/dev/null
                fi
            done
        ) &
        echo $! > "$timer_file"
        disown
        notify_wp "▶ Slideshow started" "Changing every 5 minutes"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  MENU ENTRY BUILDERS
# ══════════════════════════════════════════════════════════════════════════════

get_active_category() {
    cat "$STATE_FILE" 2>/dev/null | \
        grep "^category=" | cut -d= -f2 || echo "all"
}

set_active_category() {
    local cat="$1"
    local tmp
    tmp=$(grep -v "^category=" "$STATE_FILE" 2>/dev/null || true)
    echo "$tmp" > "$STATE_FILE" 2>/dev/null || true
    echo "category=$cat" >> "$STATE_FILE"
}

build_wallpaper_entries() {
    local active_cat
    active_cat=$(get_active_category)

    # Find wallpapers
    local -a walls=()
    local find_args=(-type f)
    find_args+=(\()
    for ext in jpg jpeg png webp gif; do
        find_args+=(-name "*.${ext}" -o)
    done
    find_args[-1]=")"    # Remove last -o

    # Apply category filter
    if [[ "$active_cat" == "all" ]]; then
        while IFS= read -r -d '' wall; do
            walls+=("$wall")
        done < <(find "$WALLPAPER_DIR" "${find_args[@]}" -print0 2>/dev/null | sort -z)
    else
        while IFS= read -r -d '' wall; do
            walls+=("$wall")
        done < <(find "${WALLPAPER_DIR}/${active_cat}" "${find_args[@]}" -print0 2>/dev/null | sort -z 2>/dev/null)
    fi

    if [[ ${#walls[@]} -eq 0 ]]; then
        printf '󰸉  No wallpapers found in category: %s\0info\x1fnone\n' "$active_cat"
        printf '─── ADD WALLPAPERS ──────────────────\0nonselectable\x1ftrue\n'
        printf '󰇚  Download from Unsplash\0info\x1fdownload-unsplash\n'
        printf '󰇚  Download from Wallhaven\0info\x1fdownload-wallhaven\n'
        printf '󰚩  Generate with AI\0info\x1fai-generate\n'
        return
    fi

    # Current wallpaper for indicator
    local current_wp
    current_wp=$(cat "$CURRENT_FILE" 2>/dev/null || echo "")

    # Build entries
    for wall in "${walls[@]}"; do
        local basename
        basename=$(basename "$wall")
        local name="${basename%.*}"
        local ext="${basename##*.}"
        local cat
        cat=$(detect_category "$wall")
        local icon
        icon=$(get_category_icon "$cat")
        local dims
        dims=$(get_image_dimensions "$wall" 2>/dev/null || echo "?×?")

        # Current wallpaper indicator
        local current_marker=""
        [[ "$wall" == "$current_wp" ]] && current_marker="✓ "

        # Format: "ICON  NAME                    DIMS   CAT"
        local display
        display=$(printf '%s  %s%-40s  %-12s  %s' \
            "$icon" \
            "$current_marker" \
            "${name:0:38}" \
            "$dims" \
            "$cat")

        printf '%s\0info\x1fapply\x1fmeta\x1f%s\n' "$display" "$wall"
    done

    # ── Online section ─────────────────────────────────────────────────────────
    printf '─── ONLINE ──────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰇚  Download: Unsplash (random)\0info\x1fdownload-unsplash\n'
    printf '󰇚  Download: Wallhaven (search)\0info\x1fdownload-wallhaven\n'
    printf '󰚩  Generate: AI Wallpaper\0info\x1fai-generate\n'

    # ── Controls section ───────────────────────────────────────────────────────
    printf '─── CONTROLS ────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰒓  Toggle Slideshow\0info\x1fslideshow\n'
    printf '󰈁  Open Wallpaper Folder\0info\x1fopen-folder\n'
    printf '󰊢  Random Wallpaper\0info\x1frandom\n'
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"
    local meta="${2:-}"

    case "$action" in
        # ── Apply specific wallpaper ───────────────────────────────────────────
        apply)
            [[ -n "$meta" ]] && apply_wallpaper "$meta"
            ;;

        # ── Random wallpaper ──────────────────────────────────────────────────
        random)
            local -a walls=()
            while IFS= read -r -d '' wall; do
                walls+=("$wall")
            done < <(find "$WALLPAPER_DIR" -type f \
                \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) \
                -print0 2>/dev/null)
            if [[ ${#walls[@]} -gt 0 ]]; then
                apply_wallpaper "${walls[$RANDOM % ${#walls[@]}]}" "any"
            else
                notify_wp "Error" "No wallpapers found in library"
            fi
            ;;

        # ── Online downloads ───────────────────────────────────────────────────
        download-unsplash)
            local query
            query=$(rofi -dmenu \
                -p "Unsplash query" \
                -theme-str 'window {width: 400px;} listview {lines: 0;}' \
                2>/dev/null || echo "nature 4k wallpaper")
            download_unsplash "${query:-nature dark minimal}"
            ;;

        download-wallhaven)
            local query
            query=$(rofi -dmenu \
                -p "Wallhaven search" \
                -theme-str 'window {width: 400px;} listview {lines: 0;}' \
                2>/dev/null || echo "landscape")
            download_wallhaven "${query:-dark wallpaper}"
            ;;

        # ── AI generation ──────────────────────────────────────────────────────
        ai-generate)
            local prompt
            prompt=$(rofi -dmenu \
                -p "AI prompt" \
                -filter "dark abstract minimal desktop wallpaper 4k" \
                -theme-str 'window {width: 500px;} listview {lines: 0;}' \
                2>/dev/null || echo "")
            [[ -n "$prompt" ]] && generate_ai_wallpaper "$prompt"
            ;;

        # ── Slideshow ──────────────────────────────────────────────────────────
        slideshow)
            toggle_slideshow
            ;;

        # ── Open folder ───────────────────────────────────────────────────────
        open-folder)
            ensure_dirs
            if command -v thunar &>/dev/null; then
                thunar "$WALLPAPER_DIR" &>/dev/null & disown
            else
                xdg-open "$WALLPAPER_DIR" &>/dev/null & disown
            fi
            ;;

        # ── Section headers (ignore) ───────────────────────────────────────────
        none|"")
            return 0
            ;;

        *)
            return 0
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  DIRECT CLI INVOCATION
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --set)          [[ -n "${2:-}" ]] && apply_wallpaper "$2" ;;
        --random)       dispatch_action "random" ;;
        --slideshow)    toggle_slideshow ;;
        --download)     download_unsplash "${2:-nature dark}" ;;
        --wallhaven)    download_wallhaven "${2:-landscape}" ;;
        --ai)           generate_ai_wallpaper "${2:-dark abstract wallpaper 4k}" ;;
        --list)
            find "$WALLPAPER_DIR" -type f \
                \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) \
                2>/dev/null | sort
            ;;
        --current)
            cat "$CURRENT_FILE" 2>/dev/null || echo "No wallpaper set"
            ;;
        --help|-h)
            echo "ASH Wallpaper Script v5.0"
            echo ""
            echo "Usage: wallpaper.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  --set FILE       Set specific wallpaper"
            echo "  --random         Apply random wallpaper"
            echo "  --slideshow      Toggle slideshow mode"
            echo "  --download QUERY Download from Unsplash"
            echo "  --wallhaven Q    Download from Wallhaven"
            echo "  --ai PROMPT      Generate with AI"
            echo "  --list           List all wallpapers"
            echo "  --current        Show current wallpaper"
            echo ""
            echo "No args: Launch Rofi wallpaper menu"
            exit 0
            ;;
        "")
            return 1    # No direct args
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

# ── Direct invocation (no Rofi) ───────────────────────────────────────────────
if [[ -z "${ROFI_RETV:-}" ]]; then
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    ensure_dirs

    rofi \
        -show wp \
        -modi "wp:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/wallpaper/wallpaper.rasi" \
        2>/dev/null
    exit 0
fi

# ── Rofi initialization ───────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 0 ]]; then
    ensure_dirs
    build_wallpaper_entries
    exit 0
fi

# ── Entry selected ────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 1 ]]; then
    action="${ROFI_INFO:-}"

    # Skip section headers
    [[ "$action" == "true" ]] && exit 0
    [[ -z "$action" ]] && exit 0

    # Parse action and meta
    IFS=$'\x1f' read -ra parts <<< "$action"
    local_action="${parts[0]:-}"
    meta_value="${parts[2]:-}"     # parts[1] = "meta", parts[2] = path

    dispatch_action "$local_action" "$meta_value"
    exit 0
fi

# ── Re-filter ─────────────────────────────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    ensure_dirs
    build_wallpaper_entries
    exit 0
fi