#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Screenshot Menu Script                           ║
# ║                                                                              ║
# ║  Full-featured screenshot management via Rofi custom mode.                 ║
# ║  Backend: grimblast (grim+slurp), swappy, tesseract, ffmpeg, wf-recorder   ║
# ║                                                                              ║
# ║  Modes:                                                                      ║
# ║  Capture: fullscreen, region, window, monitor, timed, scrolling             ║
# ║  Actions: annotate, copy, save, upload, OCR, share, set-wallpaper           ║
# ║  Record:  screen recording, GIF, history browser                            ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    screenshot.sh                    — launch menu                           ║
# ║    screenshot.sh --fullscreen       — direct capture                        ║
# ║    screenshot.sh --region           — direct region selection               ║
# ║    screenshot.sh --window           — direct window capture                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
readonly RECORDING_DIR="${HOME}/Videos/Recordings"
readonly TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
readonly SCREENSHOT_FILE="${SCREENSHOT_DIR}/screenshot_${TIMESTAMP}.png"
readonly RECORDING_FILE="${RECORDING_DIR}/recording_${TIMESTAMP}.mp4"
readonly GIF_FILE="${RECORDING_DIR}/gif_${TIMESTAMP}.gif"

readonly SOUND_SHUTTER="${HOME}/.config/ash-dotfiles/assets/sounds/screenshot.ogg"
readonly SOUND_RECORD_START="${HOME}/.config/ash-dotfiles/assets/sounds/screen-record-start.ogg"
readonly SOUND_RECORD_STOP="${HOME}/.config/ash-dotfiles/assets/sounds/screen-record-stop.ogg"

readonly UPLOAD_SERVICE="0x0.st"         # Free temporary file hosting
readonly TIMER_DEFAULT=3                  # Default timer delay (seconds)

# ══════════════════════════════════════════════════════════════════════════════
# §02  MENU ENTRY DEFINITIONS
#      Format: "ICON  LABEL\0info\x1fACTION_ID\x1fmeta\x1fSUBLABEL"
# ══════════════════════════════════════════════════════════════════════════════

build_capture_entries() {
    # ── CAPTURE section header ─────────────────────────────────────────────────
    printf '─── CAPTURE ──────────────────────────\0nonselectable\x1ftrue\n'

    # Fullscreen
    printf '󰹑  Fullscreen\0info\x1ffullscreen\n'
    # Region selection
    printf '󱂬  Region / Area\0info\x1fregion\n'
    # Active window
    printf '󰖯  Active Window\0info\x1fwindow\n'
    # Specific monitor
    printf '󰍹  Current Monitor\0info\x1fmonitor\n'
    # Timed captures
    printf '⏱  Timed — 3 seconds\0info\x1ftimer-3\n'
    printf '⏱  Timed — 5 seconds\0info\x1ftimer-5\n'
    printf '⏱  Timed — 10 seconds\0info\x1ftimer-10\n'
}

build_action_entries() {
    printf '─── AFTER CAPTURE ────────────────────\0nonselectable\x1ftrue\n'

    # Annotate with swappy
    printf '✏  Capture + Annotate\0info\x1fannotate\n'
    # Copy to clipboard directly
    printf '󰆏  Capture + Copy to Clipboard\0info\x1fcopy\n'
    # Save to file (default)
    printf '󰏉  Capture + Save to File\0info\x1fsave\n'
    # Upload to file host
    printf '󰒔  Capture + Upload to %s\0info\x1fupload\n' "$UPLOAD_SERVICE"
    # OCR text extraction
    printf '󰯂  Capture + Extract Text (OCR)\0info\x1focr\n'
    # Set as wallpaper
    printf '󰸉  Capture + Set as Wallpaper\0info\x1fwallpaper\n'
}

build_recording_entries() {
    printf '─── RECORDING ────────────────────────\0nonselectable\x1ftrue\n'

    # Screen recording
    if pgrep -x wf-recorder &>/dev/null; then
        printf '⏹  Stop Current Recording\0info\x1frecord-stop\n'
    else
        printf '󰑊  Record Screen (Full)\0info\x1frecord-full\n'
        printf '󰑊  Record Screen (Region)\0info\x1frecord-region\n'
    fi

    # GIF recording
    printf '󰴒  Record GIF (Region)\0info\x1frecord-gif\n'
    # Color picker
    printf '󰌁  Color Picker\0info\x1fcolor-pick\n'
}

build_history_entries() {
    printf '─── HISTORY ──────────────────────────\0nonselectable\x1ftrue\n'
    printf '󰉋  Browse Screenshot History\0info\x1fhistory\n'
    printf '󰈦  Open Screenshots Folder\0info\x1fopen-dir\n'
    # Last screenshot quick-copy
    local LAST
    LAST=$(ls -t "${SCREENSHOT_DIR}"/*.png 2>/dev/null | head -1 || echo "")
    if [[ -n "$LAST" ]]; then
        printf '󰆏  Copy Last Screenshot\0info\x1fcopy-last\n'
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  UTILITY FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

ensure_dirs() {
    mkdir -p "$SCREENSHOT_DIR" "$RECORDING_DIR"
}

play_sound() {
    local file="${1:-$SOUND_SHUTTER}"
    [[ -f "$file" ]] && paplay "$file" &>/dev/null & disown || true
}

notify_screenshot() {
    local title="$1" msg="$2" file="${3:-}"
    local args=(
        "$title" "$msg"
        --app-name="ASH Screenshot"
        --icon="${file:-camera-photo}"
        --urgency=low
        --expire-time=4000
        --hint=string:x-dunst-stack-tag:screenshot
    )
    [[ -n "$file" ]] && args+=(--action="open:Open" --action="folder:Folder")
    notify-send "${args[@]}" 2>/dev/null || true
}

notify_error() {
    notify-send \
        "Screenshot Error" "$1" \
        --urgency=critical \
        --expire-time=5000 \
        --hint=string:x-dunst-stack-tag:screenshot \
        2>/dev/null || true
}

wl_copy_image() {
    local file="$1"
    wl-copy --type image/png < "$file" 2>/dev/null && return 0
    cat "$file" | xclip -sel clip -target image/png 2>/dev/null && return 0
    return 1
}

upload_file() {
    local file="$1"
    local url
    url=$(curl -sf --max-time 30 \
        -F "file=@${file}" \
        "https://${UPLOAD_SERVICE}" 2>/dev/null)
    if [[ -n "$url" ]]; then
        echo -n "$url" | wl-copy 2>/dev/null || true
        echo "$url"
    fi
}

timer_countdown() {
    local secs="$1"
    for i in $(seq "$secs" -1 1); do
        notify-send "📸 Screenshot in ${i}s" "" \
            --urgency=normal \
            --expire-time=950 \
            --hint=string:x-dunst-stack-tag:sc-timer \
            2>/dev/null || true
        sleep 1
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  CAPTURE FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

capture_fullscreen() {
    local file="${1:-$SCREENSHOT_FILE}"
    ensure_dirs
    play_sound
    if command -v grimblast &>/dev/null; then
        grimblast --notify copy screen
        grimblast save screen "$file"
    elif command -v grim &>/dev/null; then
        grim "$file"
    else
        notify_error "grimblast or grim not found"
        return 1
    fi
    echo "$file"
}

capture_region() {
    local file="${1:-$SCREENSHOT_FILE}"
    ensure_dirs
    if command -v grimblast &>/dev/null; then
        grimblast save area "$file" && \
            wl_copy_image "$file"
    elif command -v grim &>/dev/null && command -v slurp &>/dev/null; then
        grim -g "$(slurp)" "$file"
    else
        notify_error "grimblast/grim+slurp not found"
        return 1
    fi
    play_sound
    echo "$file"
}

capture_window() {
    local file="${1:-$SCREENSHOT_FILE}"
    ensure_dirs
    if command -v grimblast &>/dev/null; then
        grimblast save active "$file" && \
            wl_copy_image "$file"
    else
        # Fallback: get active window geometry from hyprctl
        local geom
        geom=$(hyprctl -j activewindow 2>/dev/null | \
            jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null || echo "")
        [[ -n "$geom" ]] && grim -g "$geom" "$file" || {
            notify_error "Cannot determine window geometry"
            return 1
        }
    fi
    play_sound
    echo "$file"
}

capture_monitor() {
    local file="${1:-$SCREENSHOT_FILE}"
    ensure_dirs
    # Get focused monitor
    local monitor
    monitor=$(hyprctl -j monitors 2>/dev/null | \
        jq -r '.[] | select(.focused) | .name' 2>/dev/null | head -1 || echo "")

    if command -v grimblast &>/dev/null; then
        grimblast save output "$file"
    elif command -v grim &>/dev/null && [[ -n "$monitor" ]]; then
        grim -o "$monitor" "$file"
    else
        capture_fullscreen "$file"
    fi
    play_sound
    echo "$file"
}

capture_timed() {
    local delay="$1"
    local file="${2:-$SCREENSHOT_FILE}"
    ensure_dirs
    timer_countdown "$delay"
    capture_fullscreen "$file"
}

capture_annotate() {
    local file="${1:-$SCREENSHOT_FILE}"
    ensure_dirs

    if command -v grimblast &>/dev/null; then
        grimblast --notify save area - | swappy -f - -o "$file"
    else
        notify_error "grimblast and swappy required for annotation"
        return 1
    fi
    play_sound
    echo "$file"
}

capture_copy() {
    ensure_dirs
    if command -v grimblast &>/dev/null; then
        grimblast --notify copy area
    else
        local tmp="/tmp/sc_copy_$$.png"
        capture_region "$tmp" && wl_copy_image "$tmp" && rm -f "$tmp"
    fi
    play_sound
    notify_screenshot "📋 Copied to clipboard" "Region screenshot copied"
}

capture_ocr() {
    ensure_dirs
    local tmp="/tmp/sc_ocr_$$.png"

    if command -v grimblast &>/dev/null; then
        grimblast save area "$tmp" 2>/dev/null || return 1
    else
        capture_region "$tmp" || return 1
    fi

    if command -v tesseract &>/dev/null; then
        local text
        text=$(tesseract "$tmp" stdout -l eng quiet 2>/dev/null | tr -s ' \n')
        echo -n "$text" | wl-copy 2>/dev/null || true
        notify_screenshot \
            "📋 OCR Complete" \
            "Extracted ${#text} characters\nCopied to clipboard"
    else
        notify_error "tesseract not installed (sudo pacman -S tesseract tesseract-data-eng)"
    fi
    rm -f "$tmp"
}

capture_wallpaper() {
    local tmp="/tmp/sc_wallpaper_$$.png"
    local file

    if command -v grimblast &>/dev/null; then
        grimblast save active "$tmp" 2>/dev/null || \
        grimblast save area "$tmp" 2>/dev/null || return 1
    else
        capture_window "$tmp" || return 1
    fi

    if command -v swww &>/dev/null; then
        swww img "$tmp" \
            --transition-type fade \
            --transition-duration 0.8 && \
            notify_screenshot "🖼 Wallpaper set" "Window screenshot applied as wallpaper"
    else
        notify_error "swww not installed"
    fi
    rm -f "$tmp"
}

capture_upload() {
    local file="${1:-$SCREENSHOT_FILE}"
    ensure_dirs

    if command -v grimblast &>/dev/null; then
        grimblast save area "$file" 2>/dev/null || return 1
    else
        capture_region "$file" || return 1
    fi

    play_sound
    notify_screenshot "📤 Uploading…" "Uploading to ${UPLOAD_SERVICE}"

    local url
    url=$(upload_file "$file")
    if [[ -n "$url" ]]; then
        notify_screenshot "📤 Upload complete!" "$url" "$file"
    else
        notify_error "Upload failed — check internet connection"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  RECORDING FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

record_screen_full() {
    ensure_dirs
    if pgrep -x wf-recorder &>/dev/null; then
        notify_error "Recording already in progress — stop it first"
        return 1
    fi
    play_sound "$SOUND_RECORD_START"
    notify_screenshot "🔴 Recording started" "Full screen — click again to stop"
    wf-recorder \
        --audio \
        --codec libx264 \
        --codec-param crf=23 \
        --codec-param preset=fast \
        --filename "$RECORDING_FILE" &
    disown
}

record_screen_region() {
    ensure_dirs
    if pgrep -x wf-recorder &>/dev/null; then
        notify_error "Recording already in progress"
        return 1
    fi
    local region
    region=$(slurp 2>/dev/null) || return 1
    play_sound "$SOUND_RECORD_START"
    notify_screenshot "🔴 Recording started" "Region selected"
    wf-recorder \
        --audio \
        --geometry "$region" \
        --codec libx264 \
        --codec-param crf=23 \
        --filename "$RECORDING_FILE" &
    disown
}

record_stop() {
    if pgrep -x wf-recorder &>/dev/null; then
        pkill --signal SIGINT wf-recorder
        sleep 0.5
        local LATEST
        LATEST=$(ls -t "${RECORDING_DIR}"/*.mp4 2>/dev/null | head -1 || echo "")
        play_sound "$SOUND_RECORD_STOP"
        notify_screenshot "⏹ Recording stopped" "${LATEST:-Recording saved}"
    else
        notify_error "No active recording to stop"
    fi
}

record_gif() {
    ensure_dirs
    local region
    region=$(slurp 2>/dev/null) || return 1

    local raw_file="/tmp/ash_gif_raw_$$.mp4"
    notify_screenshot "🔴 GIF Recording" "Region captured — recording…"
    wf-recorder \
        --geometry "$region" \
        --codec libx264 \
        --codec-param crf=18 \
        --filename "$raw_file" &
    local rec_pid=$!
    disown

    # Wait for user to stop via notification action
    sleep 10    # Auto-stop after 10s for GIF (configurable)
    kill -SIGINT $rec_pid 2>/dev/null || true
    sleep 0.5

    # Convert to GIF
    if [[ -f "$raw_file" ]]; then
        notify_screenshot "⚙ Converting" "GIF: converting…"
        ffmpeg -i "$raw_file" \
            -vf "fps=15,scale=720:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
            -loop 0 \
            "$GIF_FILE" \
            -y &>/dev/null
        rm -f "$raw_file"
        wl-copy < "$GIF_FILE" 2>/dev/null || true
        notify_screenshot "🎞 GIF saved" "$GIF_FILE"
    fi
}

pick_color() {
    if ! command -v hyprpicker &>/dev/null; then
        notify_error "hyprpicker not installed"
        return 1
    fi
    local color
    color=$(hyprpicker --autocopy 2>/dev/null)
    [[ -n "$color" ]] && notify_screenshot \
        "🎨 Color picked" \
        "$color\nCopied to clipboard"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  HISTORY / NAVIGATION
# ══════════════════════════════════════════════════════════════════════════════

browse_history() {
    local selected
    selected=$(ls -t "${SCREENSHOT_DIR}"/*.{png,jpg,webp} 2>/dev/null | \
        rofi -dmenu \
            -p "📸 Screenshot History" \
            -theme-str 'window {width: 60%; height: 70%;}' \
            2>/dev/null || echo "")
    [[ -n "$selected" ]] && xdg-open "$selected" &>/dev/null & disown
}

open_directory() {
    ensure_dirs
    if command -v thunar &>/dev/null; then
        thunar "$SCREENSHOT_DIR" &>/dev/null & disown
    elif command -v xdg-open &>/dev/null; then
        xdg-open "$SCREENSHOT_DIR" &>/dev/null & disown
    fi
}

copy_last() {
    local LAST
    LAST=$(ls -t "${SCREENSHOT_DIR}"/*.png 2>/dev/null | head -1 || echo "")
    if [[ -n "$LAST" ]]; then
        wl_copy_image "$LAST"
        notify_screenshot "📋 Copied" "Last screenshot copied to clipboard"
    else
        notify_error "No screenshots found in ${SCREENSHOT_DIR}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  ACTION DISPATCHER
# ══════════════════════════════════════════════════════════════════════════════

dispatch_action() {
    local action="$1"

    case "$action" in
        # ── Capture modes ──────────────────────────────────────────────────────
        fullscreen)     capture_fullscreen && \
                            notify_screenshot "📸 Fullscreen captured" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;
        region)         capture_region && \
                            notify_screenshot "📸 Region captured" "Copied to clipboard" ;;
        window)         capture_window && \
                            notify_screenshot "📸 Window captured" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;
        monitor)        capture_monitor && \
                            notify_screenshot "📸 Monitor captured" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;
        timer-3)        capture_timed 3 && \
                            notify_screenshot "📸 Timed capture" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;
        timer-5)        capture_timed 5 && \
                            notify_screenshot "📸 Timed capture" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;
        timer-10)       capture_timed 10 && \
                            notify_screenshot "📸 Timed capture" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;

        # ── Post-capture actions ───────────────────────────────────────────────
        annotate)       capture_annotate "$SCREENSHOT_FILE" && \
                            notify_screenshot "✏ Annotated" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;
        copy)           capture_copy ;;
        save)           capture_region "$SCREENSHOT_FILE" && \
                            notify_screenshot "💾 Saved" "$SCREENSHOT_FILE" "$SCREENSHOT_FILE" ;;
        upload)         capture_upload "$SCREENSHOT_FILE" ;;
        ocr)            capture_ocr ;;
        wallpaper)      capture_wallpaper ;;

        # ── Recording ──────────────────────────────────────────────────────────
        record-full)    record_screen_full ;;
        record-region)  record_screen_region ;;
        record-stop)    record_stop ;;
        record-gif)     record_gif ;;
        color-pick)     pick_color ;;

        # ── History ────────────────────────────────────────────────────────────
        history)        browse_history ;;
        open-dir)       open_directory ;;
        copy-last)      copy_last ;;

        # ── Unknown ────────────────────────────────────────────────────────────
        *)
            notify_error "Unknown action: $action"
            return 1
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  DIRECT CLI INVOCATION (bypass Rofi)
# ══════════════════════════════════════════════════════════════════════════════

handle_direct_args() {
    case "${1:-}" in
        --fullscreen)       dispatch_action "fullscreen" ;;
        --region)           dispatch_action "region"     ;;
        --window)           dispatch_action "window"     ;;
        --monitor)          dispatch_action "monitor"    ;;
        --annotate)         dispatch_action "annotate"   ;;
        --copy)             dispatch_action "copy"       ;;
        --ocr)              dispatch_action "ocr"        ;;
        --timer)            dispatch_action "timer-${2:-3}" ;;
        --upload)           dispatch_action "upload"     ;;
        --record)           dispatch_action "record-full" ;;
        --record-region)    dispatch_action "record-region" ;;
        --stop)             dispatch_action "record-stop" ;;
        --gif)              dispatch_action "record-gif" ;;
        --color)            dispatch_action "color-pick" ;;
        --history)          dispatch_action "history"    ;;
        --wallpaper)        dispatch_action "wallpaper"  ;;
        --help|-h)
            cat << 'HELP'
ASH Screenshot Script v5.0

Usage: screenshot.sh [OPTION]

Direct capture (no menu):
  --fullscreen     Capture full screen
  --region         Select region to capture
  --window         Capture active window
  --monitor        Capture current monitor
  --annotate       Capture region + annotate with swappy
  --copy           Capture region + copy to clipboard
  --ocr            Capture region + extract text
  --upload         Capture region + upload to 0x0.st
  --wallpaper      Capture window + set as wallpaper
  --timer [N]      Timed capture (N seconds, default 3)

Recording:
  --record         Start full-screen recording
  --record-region  Start region recording
  --stop           Stop active recording
  --gif            Record GIF (10s auto-stop)
  --color          Open color picker

History:
  --history        Browse screenshot history

No args: Launch Rofi screenshot menu
HELP
            exit 0
            ;;
        "")
            return 1    # No direct args — fall through to Rofi mode
            ;;
    esac
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  ROFI CUSTOM MODE PROTOCOL
# ══════════════════════════════════════════════════════════════════════════════

# ── Case 1: Direct CLI invocation (no Rofi environment) ───────────────────────
if [[ -z "${ROFI_RETV:-}" ]]; then
    # Check for direct args
    handle_direct_args "${1:-}" "${2:-}" 2>/dev/null || true

    # Launch rofi screenshot menu
    rofi \
        -show sc \
        -modi "sc:${BASH_SOURCE[0]}" \
        -config "${HOME}/.config/rofi/menus/screenshot/screenshot.rasi" \
        2>/dev/null
    exit 0
fi

# ── Case 2: Rofi initialization (ROFI_RETV=0) ─────────────────────────────────
if [[ "${ROFI_RETV}" -eq 0 ]]; then
    build_capture_entries
    build_action_entries
    build_recording_entries
    build_history_entries
    exit 0
fi

# ── Case 3: Entry selected (ROFI_RETV=1) ──────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 1 ]]; then
    selected_action="${ROFI_INFO:-}"

    # Skip section headers
    [[ "$selected_action" == "true" ]] && exit 0
    [[ -z "$selected_action" ]] && exit 0

    dispatch_action "$selected_action"
    exit 0
fi

# ── Case 4: Custom input / re-filter ──────────────────────────────────────────
if [[ "${ROFI_RETV}" -eq 2 ]]; then
    build_capture_entries
    build_action_entries
    build_recording_entries
    build_history_entries
    exit 0
fi