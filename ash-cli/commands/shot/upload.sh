#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot upload                                              ║
# ║  Upload to image hosts: 0x0.st • catbox.moe • litterbox • imgbb • custom       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_UPLOAD_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_UPLOAD_LOADED=1

set -euo pipefail
IFS=$'\n\t'

declare -gA _UPLOAD_HOSTS=(
    ["0x0"]="https://0x0.st"
    ["catbox"]="https://catbox.moe/user/api.php"
    ["litterbox"]="https://litterbox.catbox.moe/resources/internals/api.php"
    ["imgbb"]="https://api.imgbb.com/1/upload"
)

_upload_0x0() {
    local file="$1"
    local url
    url="$(curl -fsSL \
        --max-time 60 \
        -F "file=@${file}" \
        "https://0x0.st" 2>/dev/null | tr -d '\n')"
    printf '%s' "$url"
}

_upload_catbox() {
    local file="$1"
    curl -fsSL \
        --max-time 60 \
        -F "reqtype=fileupload" \
        -F "fileToUpload=@${file}" \
        "https://catbox.moe/user/api.php" 2>/dev/null | tr -d '\n'
}

_upload_litterbox() {
    local file="$1"  expire="${2:-1h}"
    curl -fsSL \
        --max-time 60 \
        -F "reqtype=fileupload" \
        -F "time=${expire}" \
        -F "fileToUpload=@${file}" \
        "https://litterbox.catbox.moe/resources/internals/api.php" \
        2>/dev/null | tr -d '\n'
}

_upload_imgbb() {
    local file="$1"  api_key="${IMGBB_API_KEY:-}"
    [[ -z "$api_key" ]] && {
        shot_fail "IMGBB_API_KEY not set"
        return 1
    }
    local b64
    b64="$(base64 -w 0 < "$file" 2>/dev/null)"
    curl -fsSL \
        --max-time 60 \
        -F "key=${api_key}" \
        -F "image=${b64}" \
        "https://api.imgbb.com/1/upload" 2>/dev/null | \
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d['data']['url'])" \
    2>/dev/null
}

_upload_spinner() {
    local msg="$1"
    local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    local i=0
    while true; do
        printf '\r  %s%s%s  %s' "$(_steal)" "${frames[$i]}" "$(_sr)" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.08
    done
}

ash_shot_upload() {
    local input_file="${1:-}"
    local host="0x0"
    local expire="1h"     # for litterbox
    local open_browser=0

    for arg in "${@:2}"; do
        case "$arg" in
            --host=*)    host="${arg#*=}"    ;;
            --expire=*)  expire="${arg#*=}"  ;;
            --open|-o)   open_browser=1      ;;
            0x0|catbox|litterbox|imgbb) host="$arg" ;;
        esac
    done

    shot_section "☁️ " "Screenshot Upload" "$(_sblue)"

    shot_require curl curl || return 1

    # File selection
    if [[ -z "$input_file" ]]; then
        local latest
        latest="$(find "$_SHOT_DIR" \( -name '*.png' -o -name '*.jpg' \) \
                 2>/dev/null | sort -r | head -1)"
        if [[ -n "$latest" ]]; then
            input_file="$latest"
            shot_info "Using latest screenshot: ${latest##*/}"
        else
            shot_fail "No screenshot found"
            return 1
        fi
    fi

    [[ ! -f "$input_file" ]] && {
        shot_fail "File not found: ${input_file}"
        return 1
    }

    local size
    size="$(du -sh "$input_file" 2>/dev/null | cut -f1)"
    shot_kv "File" "${input_file##*/}"
    shot_kv "Size" "$size"
    shot_kv "Host" "$host"

    printf '\n'

    # Spinner while uploading
    _upload_spinner "Uploading to ${host}..." &
    local spinner_pid=$!
    trap 'kill "$spinner_pid" 2>/dev/null' EXIT INT TERM

    local url=""
    local exit_code=0

    case "$host" in
        0x0)         url="$(_upload_0x0 "$input_file")"              || exit_code=$? ;;
        catbox)      url="$(_upload_catbox "$input_file")"            || exit_code=$? ;;
        litterbox)   url="$(_upload_litterbox "$input_file" "$expire")" || exit_code=$? ;;
        imgbb)       url="$(_upload_imgbb "$input_file")"             || exit_code=$? ;;
        *)
            kill "$spinner_pid" 2>/dev/null
            shot_fail "Unknown host: ${host}"
            shot_info "Valid hosts: ${!_UPLOAD_HOSTS[*]}"
            return 1
            ;;
    esac

    kill "$spinner_pid" 2>/dev/null
    trap - EXIT INT TERM

    printf '\r  %-60s\n' ""

    if [[ $exit_code -ne 0 ]] || [[ -z "$url" ]] || \
       ! printf '%s' "$url" | grep -qE '^https?://'; then
        shot_fail "Upload failed  (exit: ${exit_code})"
        shot_info "Check your internet connection"
        return 1
    fi

    shot_ok "Upload successful!"
    shot_kv "URL" "$url"

    # Copy URL to clipboard
    if command -v wl-copy &>/dev/null; then
        printf '%s' "$url" | wl-copy 2>/dev/null
        shot_ok "URL copied to clipboard"
    fi

    # Save to upload cache
    mkdir -p "$_SHOT_UPLOAD_CACHE" 2>/dev/null
    printf '%s\t%s\t%s\t%s\n' \
        "$(date -Iseconds)" "$host" "$url" "${input_file##*/}" \
        >> "${_SHOT_UPLOAD_CACHE}/history.log" 2>/dev/null

    # Open in browser
    if [[ $open_browser -eq 1 ]]; then
        if command -v xdg-open &>/dev/null; then
            xdg-open "$url" &>/dev/null &
        elif command -v firefox &>/dev/null; then
            firefox "$url" &>/dev/null &
        fi
    fi

    shot_notify "☁️  Uploaded" "$url" ""

    printf '\n'
}
