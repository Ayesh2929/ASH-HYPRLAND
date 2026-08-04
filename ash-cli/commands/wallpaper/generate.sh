#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  wallpaper generate                                       ║
# ║  Generate wallpapers: gradients • patterns • solid colors • noise • fractals    ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_WP_GENERATE_LOADED:-}" == "1" ]] && return 0
readonly _ASH_WP_GENERATE_LOADED=1

set -euo pipefail

_gen_require_magick() {
    if command -v magick &>/dev/null; then
        printf 'magick'
    elif command -v convert &>/dev/null; then
        printf 'convert'
    else
        wp_fail "ImageMagick not found — required for generation"
        wp_info "Install: paru -S imagemagick"
        return 1
    fi
}

_gen_gradient() {
    local magick_cmd="$1"
    local colors="$2"    # comma-separated hex colors
    local output="$3"
    local width="${4:-1920}"  height="${5:-1080}"
    local direction="${6:-horizontal}"   # horizontal | vertical | diagonal | radial

    # Parse colors
    local -a color_arr=()
    IFS=',' read -ra color_arr <<< "$colors"

    if [[ ${#color_arr[@]} -lt 2 ]]; then
        color_arr+=("#89b4fa")  # add blue if only one color
    fi

    local c1="${color_arr[0]}"
    local c2="${color_arr[1]}"
    local c3="${color_arr[2]:-}"

    wp_step "Generating ${direction} gradient: ${c1} → ${c2}..."

    case "$direction" in
        horizontal)
            "$magick_cmd" -size "${width}x${height}" \
                "gradient:${c1}-${c2}" "$output" 2>/dev/null
            ;;
        vertical)
            "$magick_cmd" -size "${width}x${height}" \
                -rotate 90 "gradient:${c1}-${c2}" \
                -rotate -90 "$output" 2>/dev/null
            ;;
        diagonal)
            "$magick_cmd" -size "${width}x${height}" \
                "gradient:${c1}-${c2}" \
                -distort SRT '45' "$output" 2>/dev/null
            ;;
        radial)
            "$magick_cmd" -size "${width}x${height}" \
                "radial-gradient:${c1}-${c2}" "$output" 2>/dev/null
            ;;
        mesh|three-color)
            # Three-color mesh using xc layers
            "$magick_cmd" \
                -size "${width}x${height}" \
                "gradient:${c1}-${c2}" \
                \( -size "${width}x${height}" "gradient:${c2}-${c3:-$c1}" -rotate 90 \) \
                -compose Screen -composite \
                "$output" 2>/dev/null
            ;;
    esac
}

_gen_noise() {
    local magick_cmd="$1"  output="$2"
    local width="${3:-1920}"  height="${4:-1080}"
    local base_color="${5:-#1e1e2e}"  noise_type="${6:-gaussian}"

    wp_step "Generating ${noise_type} noise wallpaper..."

    "$magick_cmd" \
        -size "${width}x${height}" \
        xc:"${base_color}" \
        +noise "${noise_type^}" \
        -blur 0x0.5 \
        "$output" 2>/dev/null
}

_gen_pattern() {
    local magick_cmd="$1"  output="$2"
    local pattern="${3:-circles}"
    local fg="${4:-#cba6f7}"  bg="${5:-#1e1e2e}"
    local width="${6:-1920}"  height="${7:-1080}"

    wp_step "Generating ${pattern} pattern..."

    case "$pattern" in
        circles|dots)
            "$magick_cmd" \
                -size "${width}x${height}" \
                xc:"$bg" \
                -fill "$fg" \
                -draw "circle 100,100 100,130" \
                -tile -resize "${width}x${height}" \
                "$output" 2>/dev/null
            # Actually use built-in patterns
            "$magick_cmd" \
                -size "${width}x${height}" \
                pattern:circles \
                -fill "$fg" -colorize 50 \
                xc:"$bg" +swap -compose Multiply -composite \
                "$output" 2>/dev/null || \
            "$magick_cmd" -size "${width}x${height}" xc:"$bg" "$output" 2>/dev/null
            ;;
        grid|lines)
            "$magick_cmd" \
                -size "${width}x${height}" \
                xc:"$bg" \
                -stroke "$fg" -strokewidth 1 \
                -draw "line 0,0 ${width},${height}" \
                "$output" 2>/dev/null
            "$magick_cmd" -size "${width}x${height}" \
                pattern:grid -background "$bg" -fill "$fg" \
                "$output" 2>/dev/null || \
            "$magick_cmd" -size "${width}x${height}" xc:"$bg" "$output" 2>/dev/null
            ;;
        diagonal-lines|stripes)
            "$magick_cmd" -size "${width}x${height}" \
                pattern:HS_DIAGCROSS \
                -background "$bg" -fill "$fg" \
                "$output" 2>/dev/null
            ;;
        solid|flat)
            "$magick_cmd" -size "${width}x${height}" xc:"$fg" "$output" 2>/dev/null
            ;;
    esac
}

_gen_catppuccin() {
    local magick_cmd="$1"  output="$2"
    local variant="${3:-mocha}"
    local width="${4:-1920}"  height="${5:-1080}"

    declare -A palettes=(
        [mocha_base]="#1e1e2e"
        [mocha_mauve]="#cba6f7"
        [mocha_blue]="#89b4fa"
        [mocha_green]="#a6e3a1"
        [mocha_peach]="#fab387"
        [latte_base]="#eff1f5"
        [latte_mauve]="#8839ef"
        [latte_blue]="#1e66f5"
    )

    local base="${palettes[${variant}_base]:-#1e1e2e}"
    local c1="${palettes[${variant}_mauve]:-#cba6f7}"
    local c2="${palettes[${variant}_blue]:-#89b4fa}"
    local c3="${palettes[${variant}_peach]:-#fab387}"

    wp_step "Generating Catppuccin ${variant} wallpaper..."

    # Multi-color mesh gradient
    "$magick_cmd" \
        -size "${width}x${height}" \
        "gradient:${base}-${c1}" \
        \( -size "${width}x${height}" "radial-gradient:${c2}-${base}" \) \
        -compose Screen -composite \
        \( -size "${width}x${height}" xc:"${c3}" -alpha set -channel A -evaluate set 15% \) \
        -compose Over -composite \
        "$output" 2>/dev/null
}

ash_wp_generate() {
    local gen_type="gradient"
    local colors="#cba6f7,#89b4fa"
    local direction="horizontal"
    local pattern="dots"
    local width=1920  height=1080
    local base_color="#1e1e2e"
    local catppuccin_variant="mocha"
    local set_after=1

    for arg in "${@:-}"; do
        case "$arg" in
            --type=*)           gen_type="${arg#*=}"         ;;
            --colors=*)         colors="${arg#*=}"           ;;
            --direction=*)      direction="${arg#*=}"        ;;
            --pattern=*)        pattern="${arg#*=}"          ;;
            --width=*)          width="${arg#*=}"            ;;
            --height=*)         height="${arg#*=}"           ;;
            --base-color=*)     base_color="${arg#*=}"       ;;
            --variant=*)        catppuccin_variant="${arg#*=}" ;;
            --no-set)           set_after=0                  ;;
            gradient|noise|pattern|solid|catppuccin)
                gen_type="$arg"
                ;;
        esac
    done

    wp_section "✨" "Generate Wallpaper" "$(_wmauve)"

    local magick_cmd
    magick_cmd="$(_gen_require_magick)" || return 1

    wp_kv "Type"       "$gen_type"
    wp_kv "Backend"    "$magick_cmd"
    wp_kv "Resolution" "${width}x${height}"

    local output_file
    output_file="${_WP_USER_DIR}/generated-$(date +%Y%m%d-%H%M%S).png"

    case "$gen_type" in
        gradient)
            wp_kv "Colors"    "$colors"
            wp_kv "Direction" "$direction"
            _gen_gradient "$magick_cmd" "$colors" "$output_file" \
                "$width" "$height" "$direction"
            ;;
        noise)
            wp_kv "Base color" "$base_color"
            _gen_noise "$magick_cmd" "$output_file" "$width" "$height" "$base_color"
            ;;
        pattern)
            wp_kv "Pattern"   "$pattern"
            wp_kv "Colors"    "$colors"
            IFS=',' read -r fg bg <<< "${colors},${base_color}"
            _gen_pattern "$magick_cmd" "$output_file" "$pattern" \
                "$fg" "${bg:-$base_color}" "$width" "$height"
            ;;
        solid|flat)
            IFS=',' read -r fg _ <<< "$colors"
            wp_kv "Color" "$fg"
            "$magick_cmd" -size "${width}x${height}" xc:"$fg" \
                "$output_file" 2>/dev/null
            ;;
        catppuccin)
            wp_kv "Variant"  "$catppuccin_variant"
            _gen_catppuccin "$magick_cmd" "$output_file" \
                "$catppuccin_variant" "$width" "$height"
            ;;
        *)
            wp_fail "Unknown type: ${gen_type}"
            wp_info "Types: gradient noise pattern solid catppuccin"
            return 1
            ;;
    esac

    if [[ ! -f "$output_file" ]]; then
        wp_fail "Generation failed"
        return 1
    fi

    local size
    size="$(du -sh "$output_file" 2>/dev/null | cut -f1)"
    wp_ok "Wallpaper generated"
    wp_kv "Output" "${output_file/#$HOME/~}"
    wp_kv "Size"   "$size"

    if [[ $set_after -eq 1 ]]; then
        wp_step "Applying generated wallpaper..."
        wp_set_backend "$output_file" && \
            wp_notify "✨ Wallpaper Generated" "${gen_type}  •  ${width}x${height}" \
                "$output_file"
    fi

    printf '\n'
}
