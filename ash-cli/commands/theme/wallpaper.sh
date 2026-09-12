#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — wallpaper.sh                                                     ║
# ║  Build a theme from an image                                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::wallpaper::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme wallpaper${RST} <image> [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Extracts the dominant hue from an image and derives a full palette around it,
  then optionally applies the result. The image is never modified, and the
  generated theme is written to your own theme directory.

  Extraction needs a backend — magick, convert, or python3 with Pillow. Run
  ${ASH_MUTED}--backends${RST} to see which are present.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--name NAME${RST}        Theme name (default: the file's name)
  ${ASH_MUTED}--slug SLUG${RST}        Theme slug
  ${ASH_MUTED}--variant dark|light${RST}
  ${ASH_MUTED}--apply${RST}            Apply the theme after generating it
  ${ASH_MUTED}--force, -f${RST}        Overwrite an existing theme
  ${ASH_MUTED}--backends${RST}         List the available extraction backends
  ${ASH_MUTED}--dry-run, -n${RST}      Show the palette, write nothing
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme wallpaper ~/Pictures/wall.png${RST}
  ${ASH_MUTED}ash theme wallpaper ~/Pictures/wall.png --name "Wall" --apply${RST}
EOF
}

theme::wallpaper::backends() {
    local -a found=()
    local c
    for c in magick convert; do
        command -v "$c" >/dev/null 2>&1 && found+=("$c")
    done
    if command -v python3 >/dev/null 2>&1 && \
       python3 -c 'import PIL' >/dev/null 2>&1; then
        found+=("python3+Pillow")
    fi
    printf '%s\n' "${found[@]:-}"
}

# Dominant hue, via the engine if it can, else through the best available tool.
theme::wallpaper::hue() {
    local img="$1"

    if declare -f ash_extract_dominant_hue >/dev/null 2>&1; then
        local h
        h="$(ash_extract_dominant_hue "$img" 2>/dev/null || printf '')"
        if [[ -n "$h" ]]; then printf '%s' "$h"; return 0; fi
    fi

    local size="64x64"
    if command -v magick >/dev/null 2>&1; then
        # Shrink first: a full-resolution histogram is dominated by whichever
        # region happens to have the most pixels, usually a flat sky.
        magick "$img" -resize "$size^" -gravity center -extent "$size" \
            -colors 8 -format %c histogram:info:- 2>/dev/null \
            | sort -rn | head -1 | grep -oE '#[0-9A-Fa-f]{6}' | head -1
    elif command -v convert >/dev/null 2>&1; then
        convert "$img" -resize "$size^" -gravity center -extent "$size" \
            -colors 8 -format %c histogram:info:- 2>/dev/null \
            | sort -rn | head -1 | grep -oE '#[0-9A-Fa-f]{6}' | head -1
    elif command -v python3 >/dev/null 2>&1 && python3 -c 'import PIL' >/dev/null 2>&1; then
        python3 - "$img" <<'PY' 2>/dev/null
import sys
from collections import Counter
try:
    from PIL import Image
    im = Image.open(sys.argv[1]).convert("RGB")
    im.thumbnail((64, 64))
    # Quantise so near-identical pixels group together.
    q = im.quantize(colors=8)
    palette = q.getpalette()
    counts = Counter(q.getdata())
    idx, _ = counts.most_common(1)[0]
    r, g, b = palette[idx * 3: idx * 3 + 3]
    print(f"#{r:02x}{g:02x}{b:02x}")
except Exception:
    sys.exit(1)
PY
    else
        return 1
    fi
}

theme::wallpaper() {
    local img="" name="" slug="" variant="dark" apply=0 force=0 dry=0 json=0 backends=0

    while (( $# )); do
        case "$1" in
            --name)      name="${2:-}"; shift 2 ;;
            --slug)      slug="${2:-}"; shift 2 ;;
            --variant)   variant="${2:-}"; shift 2 ;;
            --apply)     apply=1; shift ;;
            --force|-f)  force=1; shift ;;
            --backends)  backends=1; shift ;;
            --dry-run|-n) dry=1; shift ;;
            --json)      json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)   theme::wallpaper::help; return 0 ;;
            -*)          ash_log_error "Unknown option: $1"; theme::wallpaper::help; return 2 ;;
            *)           img="$1"; shift ;;
        esac
    done

    if (( backends )); then
        local -a found=()
        mapfile -t found < <(theme::wallpaper::backends)
        if (( json )); then
            jq -n --argjson b "$(printf '%s\n' "${found[@]:-}" | jq -Rn '[inputs|select(length>0)]')" \
                  '{backends: $b, available: (($b|length) > 0)}'
        else
            printf '\n  %sExtraction backends%s\n' "${BOLD}${ASH_PRIMARY}" "${RST}"
            if (( ${#found[@]} )); then
                local b
                for b in "${found[@]}"; do [[ -n "$b" ]] && printf '    %s✓%s %s\n' "${ASH_SUCCESS}" "${RST}" "$b"; done
            else
                printf '    %snone — install imagemagick or python3-pillow%s\n' "${ASH_MUTED}" "${RST}"
            fi
            printf '\n'
        fi
        return 0
    fi

    [[ -n "$img" ]] || { ash_log_error "Which image?"; theme::wallpaper::help; return 2; }
    [[ -f "$img" ]] || { ash_log_error "No such file: $img"; return 1; }
    [[ "$variant" == "dark" || "$variant" == "light" ]] || {
        ash_log_error "--variant must be dark or light (got: $variant)"; return 2; }

    local -a found=()
    mapfile -t found < <(theme::wallpaper::backends)
    local usable=()
    local b
    for b in "${found[@]}"; do [[ -n "$b" ]] && usable+=("$b"); done
    if (( ${#usable[@]} == 0 )); then
        ash_log_error "No image extraction backend is installed."
        printf '  %sInstall one of: imagemagick, python3-pillow%s\n' "${ASH_MUTED}" "${RST}" >&2
        printf '  %sOr pick a theme by hand: ash theme search <hue word>%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        return 1
    fi

    local seed
    if ! seed="$(theme::wallpaper::hue "$img")"; then
        ash_log_error "Could not read any colour out of $(basename "$img")"
        return 1
    fi
    [[ "$seed" =~ ^#[0-9a-fA-F]{6}$ ]] || { ash_log_error "Extraction returned '$seed', not a colour"; return 1; }
    seed="$(tr 'A-F' 'a-f' <<<"$seed")"

    [[ -n "$name" ]] || name="$(basename "$img")"
    name="${name%.*}"; name="${name//[-_]/ }"
    name="$(awk '{ for (i=1;i<=NF;i++) printf "%s%s", (i>1?" ":""), toupper(substr($i,1,1)) substr($i,2) }' <<<"$name")"
    [[ -n "$name" ]] || name="Wallpaper"
    [[ -n "$slug" ]] || slug="$(ash_generate_slug "$name" 2>/dev/null || printf 'wallpaper')"
    [[ -n "$slug" ]] || slug="wallpaper-$RANDOM"

    local dest="${THEME_USER_DIR}/${slug}.json"
    if [[ -f "$dest" && "$force" -eq 0 && "$dry" -eq 0 ]]; then
        ash_log_error "User theme '$slug' already exists."
        printf '  %sPass --force to overwrite, or --slug for another name.%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        return 1
    fi

    local -A pal=()
    if ! declare -f ash_palette_derive >/dev/null 2>&1; then
        ash_log_error "The colour engine is not loaded."
        return 1
    fi
    if ! ash_palette_derive pal "$seed" "$variant"; then
        ash_log_error "Could not derive a palette from $seed"
        return 1
    fi

    local wcag=0
    if declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local r
        r="$(ash_wcag_check_palette pal --quiet 2>/dev/null || true)"
        [[ "$r" =~ ^[0-9]+$ ]] && wcag="$r"
    fi

    if (( json )); then
        local colors_json
        colors_json="$(ash_palette_render_json pal 2>/dev/null || printf '{}')"
        jq -n --arg slug "$slug" --arg name "$name" --arg variant "$variant" \
              --arg image "$img" --arg seed "$seed" --arg file "$dest" \
              --argjson dry "$dry" --argjson applied 0 --argjson wcag "$wcag" \
              --argjson colors "$colors_json" \
              '{slug: $slug, name: $name, variant: $variant, image: $image,
                seed: $seed, file: $file, dry_run: ($dry == 1),
                wcag_failures: $wcag, applied: false, colors: $colors}'
        if (( dry )); then return 0; fi
        # Fall through to write, but suppress the human output.
    fi

    if (( dry )); then
        printf '\n  %sDry run — nothing written.%s\n' "${ASH_MUTED}" "${RST}"
        printf '    image  %s\n    seed   %s%s%s\n\n' "$(basename "$img")" "${ASH_ACCENT}" "$seed" "${RST}"
        local slot
        for slot in "${THEME_SLOT_ORDER[@]}"; do
            [[ -n "${pal[$slot]:-}" ]] && printf '    %-9s %s  %s\n' \
                "$slot" "${pal[$slot]}" "$(theme::swatch "${pal[$slot]}" 10)"
        done
        printf '\n'
        return 0
    fi

    theme::save "$dest" pal "slug=$slug" "name=$name" "variant=$variant" \
        "family=wallpaper" "seed=$seed" "wallpaper=$img" || {
        ash_log_error "Could not write $dest"; return 1; }

    theme::record "$slug" wallpaper

    if [[ "$json" != "1" ]]; then
        printf '\n  %s🎨 Generated%s %s%s%s from %s%s%s\n' \
            "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" \
            "${ASH_MUTED}" "$(basename "$img")" "${RST}"
        printf '  %s   seed %s · %s%s\n' "${ASH_MUTED}" "$seed" "$dest" "${RST}"
        if (( wcag )); then
            printf '  %s⚠  %s below the 4.5:1 minimum — ash theme wcag %s --fix%s\n' \
                "${ASH_WARNING:-$ASH_MUTED}" "$(theme::plural "$wcag" "pair")" "$slug" "${RST}"
        fi
        printf '\n'
    fi

    if (( apply )); then
        theme::source_sub apply || return 1
        theme::apply "$slug" || return $?
        if (( json )); then
            jq -n --arg slug "$slug" --arg image "$img" \
                  '{slug: $slug, image: $image, applied: true}'
        fi
    elif [[ "$json" != "1" ]]; then
        printf '  %sApply it:  ash theme apply %s%s\n\n' "${ASH_MUTED}" "$slug" "${RST}"
    fi
}
