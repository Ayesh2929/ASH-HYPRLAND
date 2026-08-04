#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper set                                            ║
# ║  Set a specific wallpaper with transition animation and metadata                 ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_SET_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_SET_LOADED=1

set -euo pipefail

ash_wp_set() {
    local target_file=""
    local monitor=""
    local show_preview=0

    for arg in "${@:-}"; do
        case "$arg" in
            --monitor=*|-m=*)  monitor="${arg#*=}"   ;;
            --preview|-p)      show_preview=1        ;;
            *)
                if [[ -z "$target_file" ]]; then
                    target_file="$arg"
                fi
                ;;
        esac
    done

    wp_section "🖼️ " "Set Wallpaper" "$(_wpink)"

    # ── File resolution ───────────────────────────────────────────────────────────
    if [[ -z "$target_file" ]]; then
        wp_fail "No wallpaper file specified"
        wp_info "Usage: ash wp set <file>"
        return 1
    fi

    # Expand tilde
    target_file="${target_file/#\~/$HOME}"

    # Resolve relative paths
    [[ "${target_file:0:1}" != "/" ]] && target_file="$(pwd)/${target_file}"

    if [[ ! -f "$target_file" ]]; then
        wp_fail "File not found: ${target_file}"
        return 1
    fi

    # ── Validate image format ─────────────────────────────────────────────────────
    local mime
    mime="$(file --mime-type -b "$target_file" 2>/dev/null || echo 'unknown')"

    case "$mime" in
        image/jpeg|image/png|image/webp|image/gif|image/bmp|image/tiff|video/mp4)
            ;;
        *)
            wp_warn "Unusual file type: ${mime}"
            wp_info "Continuing anyway..."
            ;;
    esac

    # ── File metadata ─────────────────────────────────────────────────────────────
    local basename size dims
    basename="$(basename "$target_file")"
    size="$(du -sh "$target_file" 2>/dev/null | cut -f1)"

    if command -v identify &>/dev/null; then
        dims="$(identify -format '%wx%h' "$target_file" 2>/dev/null || echo '?')"
    elif command -v ffprobe &>/dev/null; then
        dims="$(ffprobe -v quiet -print_format json -show_streams "$target_file" \
                2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
s=next((s for s in d.get('streams',[]) if s.get('codec_type')=='video'), {})
print(f\"{s.get('width','?')}x{s.get('height','?')}\")
" 2>/dev/null || echo '?')"
    else
        dims="?"
    fi

    wp_kv "Backend"    "$WP_BACKEND"
    wp_kv "File"       "$basename"
    wp_kv "Path"       "${target_file/#$HOME/~}"
    wp_kv "Type"       "$mime"
    wp_kv "Size"       "$size"
    [[ "$dims" != "?" ]] && wp_kv "Dimensions" "${dims} px"
    wp_kv "Transition" "${WP_TRANSITION}  @${WP_TRANSITION_FPS}fps"
    wp_kv "Fill mode"  "$WP_FILL_MODE"
    [[ -n "$monitor"  ]] && wp_kv "Monitor"   "$monitor"

    # ── chafa preview in terminal ─────────────────────────────────────────────────
    if [[ $show_preview -eq 1 ]] || [[ "${ASH_WP_PREVIEW:-0}" -eq 1 ]]; then
        if command -v chafa &>/dev/null; then
            printf '\n'
            chafa --size=60x20 --symbols=block "$target_file" 2>/dev/null | \
                sed 's/^/  /'
            printf '\n'
        fi
    fi

    # ── Apply wallpaper ───────────────────────────────────────────────────────────
    wp_step "Applying wallpaper via ${WP_BACKEND}..."

    if wp_set_backend "$target_file"; then
        wp_ok "Wallpaper applied: ${basename}"
        wp_notify "🖼️  Wallpaper Set" "${basename}  •  ${dims}" "$target_file"
    else
        wp_fail "Failed to apply wallpaper"
        return 1
    fi

    printf '\n'
}
