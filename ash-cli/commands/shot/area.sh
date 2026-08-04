#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot area                                                ║
# ║  Interactive area selection with slurp/xrectsel + visual crosshair overlay      ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_AREA_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_AREA_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_shot_area() {
    local fmt="${ASH_SHOT_FORMAT:-png}"
    local quality="${ASH_SHOT_QUALITY:-95}"

    shot_section "✂️ " "Area Selection Capture" "$(_ssapph)"

    shot_check_wayland || return 1

    local geometry=""
    local selector_tool=""

    # Detect geometry selector
    if command -v slurp &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        selector_tool="slurp"
    elif command -v xrectsel &>/dev/null; then
        selector_tool="xrectsel"
    elif command -v hacksaw &>/dev/null; then
        selector_tool="hacksaw"
    else
        shot_fail "No area selector found"
        shot_info "Install: paru -S slurp  (Wayland)  or  paru -S xrectsel  (X11)"
        return 1
    fi

    shot_info "Draw a rectangle on screen to capture..."

    # Get geometry
    case "$selector_tool" in
        slurp)
            local slurp_args=(
                "slurp"
                "-b" "1e1e2eCC"   # base bg
                "-c" "cba6f7FF"   # mauve border
                "-s" "cba6f740"   # selection fill
                "-w" "2"          # border width
            )
            geometry="$("${slurp_args[@]}" 2>/dev/null)" || {
                shot_info "Selection cancelled"
                return 0
            }
            ;;
        xrectsel)
            geometry="$(xrectsel 2>/dev/null)" || {
                shot_info "Selection cancelled"
                return 0
            }
            ;;
        hacksaw)
            geometry="$(hacksaw -f '%x %y %w %h' 2>/dev/null)" || {
                shot_info "Selection cancelled"
                return 0
            }
            ;;
    esac

    [[ -z "$geometry" ]] && { shot_info "No area selected"; return 0; }

    local output_file
    output_file="$(shot_filename "area" "$fmt")"

    shot_kv "Geometry" "$geometry"
    shot_kv "Output"   "$output_file"

    local exit_code=0

    if command -v grim &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        local grim_args=( "grim" "-g" "$geometry" )
        [[ "${fmt,,}" == "jpg" ]] && grim_args+=( "-t" "jpeg" "-q" "$quality" )
        grim_args+=( "$output_file" )
        "${grim_args[@]}" 2>/dev/null || exit_code=$?
    elif command -v import &>/dev/null; then
        import -crop "$geometry" root "$output_file" 2>/dev/null || exit_code=$?
    else
        shot_fail "No capture backend found"
        return 1
    fi

    if [[ $exit_code -ne 0 ]] || [[ ! -f "$output_file" ]]; then
        shot_fail "Capture failed"
        return 1
    fi

    local size
    size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
    shot_ok "Area screenshot saved"
    shot_kv "File" "$output_file"
    shot_kv "Size" "$size"

    [[ "${ASH_SHOT_CLIPBOARD:-0}" -eq 1 ]] && shot_copy_to_clipboard "$output_file"
    [[ "${ASH_SHOT_ANNOTATE:-0}" -eq 1 ]]  && ash_shot_annotate "$output_file"
    [[ "${ASH_SHOT_UPLOAD:-0}" -eq 1 ]]    && ash_shot_upload "$output_file"

    shot_log "$output_file" "area" "$geometry"
    shot_notify "✂️  Area Captured" "$geometry  •  ${size}" "$output_file"

    printf '\n'
}
