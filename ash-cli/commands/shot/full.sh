#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  shot full                                                ║
# ║  Full-screen capture of all monitors with grim / scrot / import fallback        ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_SHOT_FULL_LOADED:-}" == "1" ]] && return 0
readonly _ASH_SHOT_FULL_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_shot_full() {
    local delay="${ASH_SHOT_DELAY:-0}"
    local fmt="${ASH_SHOT_FORMAT:-png}"
    local quality="${ASH_SHOT_QUALITY:-95}"

    shot_section "📸" "Full Screen Capture" "$(_spink)"

    shot_check_wayland || return 1

    # Validate format
    case "${fmt,,}" in
        png|jpg|jpeg|webp) ;;
        *) shot_warn "Unknown format '${fmt}' — defaulting to png"; fmt="png" ;;
    esac

    local output_file
    output_file="$(shot_filename "full" "$fmt")"

    shot_kv "Output" "$output_file"
    shot_kv "Format" "${fmt^^}"
    [[ "$delay" -gt 0 ]] && shot_kv "Delay"  "${delay}s"

    # Countdown animation
    if [[ "$delay" -gt 0 ]]; then
        printf '\n'
        for (( i=delay; i>0; i-- )); do
            printf '\r  %s📷  Capturing in %s%d%s second(s)...%s  ' \
                "$(_syellow)" "$(_sbold)" "$i" "$(_sr)$(_syellow)" "$(_sr)"
            sleep 1
        done
        printf '\r  %-50s\n' ""
    fi

    shot_step "Capturing full screen..."

    local exit_code=0

    # Backend selection (priority: grim → scrot → import)
    if command -v grim &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        # grim on Wayland
        local grim_args=( "grim" )
        if [[ "${fmt,,}" == "jpg" ]] || [[ "${fmt,,}" == "jpeg" ]]; then
            grim_args+=( "-t" "jpeg" "-q" "$quality" )
        elif [[ "${fmt,,}" == "webp" ]]; then
            grim_args+=( "-t" "webp" )
        fi
        grim_args+=( "$output_file" )
        "${grim_args[@]}" 2>/dev/null || exit_code=$?

    elif command -v scrot &>/dev/null; then
        scrot "$output_file" 2>/dev/null || exit_code=$?

    elif command -v import &>/dev/null; then
        import -window root "$output_file" 2>/dev/null || exit_code=$?

    else
        shot_fail "No screenshot backend found"
        shot_info "Install: paru -S grim  (Wayland)  or  paru -S scrot  (X11)"
        return 1
    fi

    if [[ $exit_code -ne 0 ]] || [[ ! -f "$output_file" ]]; then
        shot_fail "Capture failed  (exit: ${exit_code})"
        return 1
    fi

    # File info
    local size dims
    size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
    dims="$(command -v identify &>/dev/null && \
            identify -format '%wx%h' "$output_file" 2>/dev/null || echo '?')"

    shot_ok "Screenshot saved"
    shot_kv "File"       "$output_file"
    shot_kv "Size"       "$size"
    [[ "$dims" != "?" ]] && shot_kv "Dimensions" "$dims px"

    # Post-capture actions
    [[ "${ASH_SHOT_CLIPBOARD:-0}" -eq 1 ]] && shot_copy_to_clipboard "$output_file"
    [[ "${ASH_SHOT_ANNOTATE:-0}" -eq 1 ]]  && ash_shot_annotate "$output_file"
    [[ "${ASH_SHOT_UPLOAD:-0}" -eq 1 ]]    && ash_shot_upload "$output_file"

    shot_log "$output_file" "full"
    shot_notify "📸 Screenshot" "Full screen captured  •  ${size}" "$output_file"

    printf '\n'
}
