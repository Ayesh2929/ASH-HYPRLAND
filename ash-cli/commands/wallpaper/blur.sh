#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper blur                                           ║
# ║  Apply blur, vignette, dim, and overlay effects to current wallpaper            ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_BLUR_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_BLUR_LOADED=1

set -euo pipefail

_blur_require_magick() {
    if command -v magick &>/dev/null; then printf 'magick'
    elif command -v convert &>/dev/null; then printf 'convert'
    else
        wp_fail "ImageMagick required for blur effects"
        wp_info "Install: paru -S imagemagick"
        return 1
    fi
}

_blur_preview() {
    local file="$1"
    if command -v chafa &>/dev/null; then
        printf '\n'
        chafa --size=50x15 "$file" 2>/dev/null | sed 's/^/  /'
        printf '\n'
    fi
}

ash_wp_blur() {
    local radius=20
    local sigma=10
    local dim_pct=0          # 0-100 darken overlay
    local vignette=0
    local effect="gaussian"  # gaussian | radial | motion | lens
    local overlay_color=""   # hex color for tint overlay
    local overlay_opacity=0  # 0-100
    local set_after=1
    local source_file=""

    for arg in "${@:-}"; do
        case "$arg" in
            --radius=*)     radius="${arg#*=}"         ;;
            --sigma=*)      sigma="${arg#*=}"          ;;
            --dim=*)        dim_pct="${arg#*=}"        ;;
            --vignette)     vignette=1                 ;;
            --effect=*)     effect="${arg#*=}"         ;;
            --color=*)      overlay_color="${arg#*=}"  ;;
            --opacity=*)    overlay_opacity="${arg#*=}" ;;
            --no-set)       set_after=0                ;;
            --file=*)       source_file="${arg#*=}"    ;;
        esac
    done

    wp_section "💧" "Wallpaper Blur Effect" "$(_wblue)"

    local magick_cmd
    magick_cmd="$(_blur_require_magick)" || return 1

    # Get source file
    if [[ -z "$source_file" ]]; then
        source_file="$(wp_get_current)"
    fi

    if [[ -z "$source_file" ]] || [[ ! -f "$source_file" ]]; then
        wp_fail "No current wallpaper found"
        wp_info "Set a wallpaper first: ash wp set <file>"
        return 1
    fi

    wp_kv "Source"   "$(basename "$source_file")"
    wp_kv "Effect"   "$effect"
    wp_kv "Radius"   "$radius"
    wp_kv "Sigma"    "$sigma"
    [[ $dim_pct -gt 0  ]] && wp_kv "Dim"      "${dim_pct}%"
    [[ $vignette -eq 1 ]] && wp_kv "Vignette" "enabled"
    [[ -n "$overlay_color" ]] && \
        wp_kv "Overlay" "${overlay_color}  @${overlay_opacity}%"

    local output_file
    output_file="${_WP_CACHE}/blurred-$(basename "$source_file")-$(date +%s).png"
    mkdir -p "$_WP_CACHE" 2>/dev/null || true

    wp_step "Applying ${effect} blur  (radius=${radius}, sigma=${sigma})..."

    # Build ImageMagick command chain
    local -a cmd=( "$magick_cmd" "$source_file" )

    # Blur effect
    case "$effect" in
        gaussian)
            cmd+=( -blur "${radius}x${sigma}" )
            ;;
        radial|spin)
            cmd+=( -radial-blur "${radius}" )
            ;;
        motion)
            cmd+=( -motion-blur "${radius}x${sigma}+${radius}" )
            ;;
        lens|focus)
            # Simulate lens blur: sharp center, blurred edges
            cmd+=(
                \(
                    -clone 0
                    -blur "${radius}x${sigma}"
                \)
                \(
                    -size "$(identify -format '%wx%h' "$source_file" 2>/dev/null || echo '1920x1080')"
                    "radial-gradient:white-black"
                \)
                -compose Over -composite
            )
            ;;
    esac

    # Dim overlay
    if (( dim_pct > 0 )); then
        local dim_alpha=$(( 255 * dim_pct / 100 ))
        cmd+=(
            \( -clone 0
               -fill "rgba(0,0,0,$(echo "scale=2;$dim_pct/100" | bc -l 2>/dev/null || echo '0.3'))"
               -colorize 100
            \)
            -composite
        )
    fi

    # Color overlay/tint
    if [[ -n "$overlay_color" ]] && (( overlay_opacity > 0 )); then
        cmd+=(
            \( +clone
               -fill "${overlay_color}"
               -colorize "${overlay_opacity}"
            \)
            -composite
        )
    fi

    # Vignette
    if [[ $vignette -eq 1 ]]; then
        cmd+=( -vignette 0x"${sigma}"+10+10 )
    fi

    cmd+=( "$output_file" )

    # Execute
    if "${cmd[@]}" 2>/dev/null; then
        local size
        size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
        wp_ok "Blur effect applied"
        wp_kv "Output" "${output_file/#$HOME/~}"
        wp_kv "Size"   "$size"

        _blur_preview "$output_file"

        if [[ $set_after -eq 1 ]]; then
            wp_step "Applying blurred wallpaper..."
            wp_set_backend "$output_file" && \
                wp_notify "💧 Wallpaper Blurred" \
                    "${effect}  radius=${radius}" "$output_file"
        fi
    else
        wp_fail "Blur effect failed"
        return 1
    fi

    printf '\n'
}
