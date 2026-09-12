#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper download                                       ║
# ║  Download from URL • Wallhaven • Unsplash • Reddit • Pixabay                   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_DOWNLOAD_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_DOWNLOAD_LOADED=1

set -euo pipefail

declare -gr _DL_USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"

_dl_spinner() {
    local msg="$1"
    local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    local i=0
    while true; do
        printf '\r  %s%s%s  %s' "$(_wteal)" "${frames[$i]}" "$(_wr)" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.08
    done
}

_dl_url() {
    local url="$1"  dest_dir="$2"  set_after="${3:-1}"

    wp_step "Downloading: ${url##*/}..."

    local filename
    filename="$(basename "$url" | sed 's/[?#].*//')"
    [[ -z "${filename##*.}" ]] || [[ "${filename##*.}" == "$filename" ]] && \
        filename="${filename}.jpg"

    local dest_file="${dest_dir}/${filename}"

    _dl_spinner "Downloading..." &
    local spin_pid=$!
    trap 'kill "$spin_pid" 2>/dev/null' EXIT INT TERM

    local exit_code=0
    curl -fsSL \
        --user-agent "$_DL_USER_AGENT" \
        --max-time 60 \
        --connect-timeout 10 \
        -o "$dest_file" \
        "$url" 2>/dev/null || exit_code=$?

    kill "$spin_pid" 2>/dev/null
    trap - EXIT INT TERM
    printf '\r  %-60s\n' ""

    if [[ $exit_code -ne 0 ]] || [[ ! -f "$dest_file" ]]; then
        wp_fail "Download failed  (exit: ${exit_code})"
        return 1
    fi

    local size
    size="$(du -sh "$dest_file" 2>/dev/null | cut -f1)"
    wp_ok "Downloaded: ${filename}  (${size})"
    wp_kv "Saved to" "${dest_file/#$HOME/~}"

    if [[ "$set_after" -eq 1 ]]; then
        wp_step "Applying downloaded wallpaper..."
        wp_set_backend "$dest_file" && \
            wp_notify "⬇️  Wallpaper Downloaded" "${filename}  •  ${size}" "$dest_file"
    fi
}

_dl_wallhaven() {
    local query="$1"  resolution="${2:-1920x1080}"  category="${3:-general}"
    local api_key="${WALLHAVEN_API_KEY:-}"

    wp_step "Searching Wallhaven: '${query}'  (${resolution})..."

    # Build API URL
    local api_url="https://wallhaven.cc/api/v1/search"
    local params="q=${query}&sorting=random&resolutions=${resolution}"
    [[ -n "$api_key" ]] && params+="&apikey=${api_key}"
    case "$category" in
        anime)   params+="&categories=010" ;;
        people)  params+="&categories=001" ;;
        general) params+="&categories=100" ;;
        all)     params+="&categories=111" ;;
    esac

    local response
    response="$(curl -fsSL --max-time 15 \
        "${api_url}?${params}" 2>/dev/null || echo '{}')"

    if ! command -v python3 &>/dev/null; then
        wp_fail "python3 required for Wallhaven API parsing"
        return 1
    fi

    local img_url
    img_url="$(printf '%s' "$response" | python3 -c "
import json, sys, random
d = json.load(sys.stdin)
data = d.get('data', [])
if not data:
    sys.exit(1)
wall = random.choice(data[:10])
print(wall.get('path', ''))
" 2>/dev/null || echo '')"

    if [[ -z "$img_url" ]]; then
        wp_fail "No results found for: ${query}"
        wp_info "Try different search terms or check your API key"
        return 1
    fi

    wp_kv "Found" "$img_url"
    _dl_url "$img_url" "$_WP_USER_DIR"
}

_dl_unsplash() {
    local query="$1"  orientation="${2:-landscape}"
    local api_key="${UNSPLASH_ACCESS_KEY:-}"

    if [[ -z "$api_key" ]]; then
        # Use source.unsplash.com (no API key, limited)
        local width=1920  height=1080
        local url="https://source.unsplash.com/${width}x${height}/?${query}"
        wp_info "No UNSPLASH_ACCESS_KEY — using public endpoint"
        _dl_url "$url" "$_WP_USER_DIR"
        return
    fi

    local response
    response="$(curl -fsSL --max-time 15 \
        "https://api.unsplash.com/photos/random?query=${query}&orientation=${orientation}&client_id=${api_key}" \
        2>/dev/null || echo '{}')"

    local img_url
    img_url="$(printf '%s' "$response" | python3 -c "
import json, sys
d = json.load(sys.stdin)
urls = d.get('urls', {})
print(urls.get('full', urls.get('regular', '')))
" 2>/dev/null || echo '')"

    [[ -z "$img_url" ]] && { wp_fail "No Unsplash result"; return 1; }
    _dl_url "$img_url" "$_WP_USER_DIR"
}

ash_wp_download() {
    local source="url"
    local url=""
    local query="nature"
    local resolution="1920x1080"
    local category="general"
    local orientation="landscape"
    local set_after=1

    for arg in "${@:-}"; do
        case "$arg" in
            --source=*)       source="${arg#*=}"       ;;
            --url=*)          url="${arg#*=}"          ;;
            --query=*|-q=*)   query="${arg#*=}"        ;;
            --resolution=*)   resolution="${arg#*=}"   ;;
            --category=*-c=*) category="${arg#*=}"     ;;
            --orientation=*)  orientation="${arg#*=}"  ;;
            --no-set)         set_after=0              ;;
            http://*|https://*) url="$arg"             ;;
            wallhaven|unsplash|pixabay|reddit) source="$arg" ;;
        esac
    done

    wp_section "⬇️ " "Download Wallpaper" "$(_wsapph)"

    wp_kv "Source"     "$source"
    wp_kv "Dest dir"   "${_WP_USER_DIR/#$HOME/~}"

    mkdir -p "$_WP_USER_DIR" 2>/dev/null || true

    case "$source" in
        url|direct)
            [[ -z "$url" ]] && {
                wp_fail "No URL provided"
                wp_info "Usage: ash wp download --url=https://..."
                return 1
            }
            _dl_url "$url" "$_WP_USER_DIR" "$set_after"
            ;;
        wallhaven)
            wp_kv "Query"      "$query"
            wp_kv "Resolution" "$resolution"
            wp_kv "Category"   "$category"
            _dl_wallhaven "$query" "$resolution" "$category"
            ;;
        unsplash)
            wp_kv "Query"       "$query"
            wp_kv "Orientation" "$orientation"
            _dl_unsplash "$query" "$orientation"
            ;;
        *)
            wp_fail "Unknown source: ${source}"
            wp_info "Valid sources: url wallhaven unsplash"
            return 1
            ;;
    esac

    printf '\n'
}
