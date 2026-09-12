#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/extract.sh                          ║
# ║                                                                               ║
# ║  Pull a usable palette out of an image, or out of an existing theme.          ║
# ║                                                                               ║
# ║  Used by `ash theme from-wallpaper`, and by the theme editor's "pick colours  ║
# ║  from a picture" button.                                                      ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_EXTRACT_LOADED:-}" ]] && return 0
ASH_EXTRACT_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" ]]    && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
[[ -z "${ASH_PALETTE_LOADED:-}" ]]  && source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"
[[ -z "${ASH_CONTRAST_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/contrast-check.sh"

# ash_extract_backend — echo the tool that will read images, or "" when none is
# available. Checked at call time rather than import time so a library user who
# installs ImageMagick mid-session does not need to restart.
ash_extract_backend() {
    if command -v magick >/dev/null 2>&1; then printf 'magick'
    elif command -v convert >/dev/null 2>&1; then printf 'convert'
    fi
}

# ash_extract_colors <image> [count]
#   Echoes up to <count> hex colours, most frequent first.
#
#   The image is downscaled to a small square before quantising. Two reasons:
#   quantising a 4K wallpaper directly takes tens of seconds for no accuracy
#   gain, and averaging over a small thumbnail suppresses JPEG noise, which
#   otherwise produces a long tail of near-identical muddy colours that crowd
#   out the real ones.
ash_extract_colors() {
    local image="$1" count="${2:-16}"
    [[ -r "$image" ]] || { printf 'ash extract: cannot read %s\n' "$image" >&2; return 1; }

    local backend; backend="$(ash_extract_backend)"
    if [[ -z "$backend" ]]; then
        printf 'ash extract: needs ImageMagick (install imagemagick)\n' >&2
        return 1
    fi

    # `-colors N` uses median-cut; `-format %c histogram:info:-` prints one row
    # per colour as "<count>: (r,g,b) #rrggbb srgb(...)".
    "$backend" "$image" \
        -resize 200x200^ -gravity center -extent 200x200 \
        -colors "$count" \
        -depth 8 \
        -format %c histogram:info:- 2>/dev/null \
    | awk -F'#' '
        NF < 2 { next }
        {
            # The hex is the first field after the #, up to whitespace.
            split($2, parts, " ")
            hex = parts[1]
            if (length(hex) < 6) next
            hex = "#" tolower(substr(hex, 1, 6))

            # The count is everything before the colon on the left of the #.
            left = $1
            sub(/[^0-9]*/, "", left)
            sub(/[^0-9].*/, "", left)
            if (left == "") left = 0
            printf "%08d %s\n", left, hex
        }
    ' \
    | sort -rn \
    | awk '{ print $2 }' \
    | awk '!seen[$0]++'      # dedupe: quantiser can repeat a colour
}

# ash_extract_rank <image> [count]
#   The same list, but scored for *usefulness as a theme seed* rather than
#   frequency.
#
#   The most common colour in a wallpaper is usually the background — often a
#   near-black or near-white that produces a flat, lifeless theme. Ranked
#   instead by chroma, weighted down for extremes of lightness, so a vivid
#   mid-tone wins.
ash_extract_rank() {
    local image="$1" count="${2:-16}"
    local colors
    colors="$(ash_extract_colors "$image" "$(( count * 3 ))")" || return 1
    [[ -z "$colors" ]] && return 1

    local hex lch L C H score
    while IFS= read -r hex; do
        [[ -n "$hex" ]] || continue
        lch="$(ash_ok_from_hex "$hex")" || continue
        L="$(cut -d' ' -f1 <<<"$lch")"
        C="$(cut -d' ' -f2 <<<"$lch")"
        H="$(cut -d' ' -f3 <<<"$lch")"

        # Score = chroma, damped for lightness extremes. A colour at L=0.5
        # keeps full weight; one at L=0.05 or L=0.97 keeps about a third.
        local shape
        shape="$(_ash_ok_awk "BEGIN {
            l = $L
            d = (l - 0.5); if (d < 0) d = -d
            printf \"%.6f\", 1 - 0.65 * (d / 0.5)
        }")"
        score="$(_ash_ok_awk "BEGIN { printf \"%.6f\", $C * $shape }")"
        printf '%s %s %s\n' "$score" "$hex" "$H"
    done <<<"$colors" \
    | sort -rn \
    | head -n "$count" \
    | awk '{ print $2 }'
}

# ash_extract_dominant_hue <image>
#   The seed hue for a generated theme. Uses a chroma-weighted circular mean,
#   not the most frequent hue: a wallpaper with a big grey sky and a small
#   orange sunset should produce an orange theme.
ash_extract_dominant_hue() {
    local image="$1"
    local colors
    colors="$(ash_extract_colors "$image" 32)" || return 1
    [[ -z "$colors" ]] && { printf '268'; return 0; }

    # Circular mean: sum unit vectors scaled by chroma, then atan2. Averaging
    # hue angles directly would put the mean of 350 and 10 at 180.
    local sum_x=0 sum_y=0
    local hex lch C H rad x y
    while IFS= read -r hex; do
        [[ -n "$hex" ]] || continue
        lch="$(ash_ok_from_hex "$hex")" || continue
        C="$(cut -d' ' -f2 <<<"$lch")"
        H="$(cut -d' ' -f3 <<<"$lch")"

        read -r x y < <(_ash_ok_awk "BEGIN {
            rad = $H * 3.141592653589793 / 180
            # Weight by chroma squared: a barely-tinted grey should not drag the
            # mean away from a strongly saturated accent.
            w = $C * $C
            printf \"%.10f %.10f\", w * cos(rad), w * sin(rad)
        }")
        sum_x="$(_ash_ok_awk "BEGIN { printf \"%.10f\", $sum_x + $x }")"
        sum_y="$(_ash_ok_awk "BEGIN { printf \"%.10f\", $sum_y + $y }")"
    done <<<"$colors"

    _ash_ok_awk "BEGIN {
        if ($sum_x == 0 && $sum_y == 0) { print 268; exit }
        h = atan2($sum_y, $sum_x) * 180 / 3.141592653589793
        while (h < 0) h += 360
        printf \"%.4f\", h
    }"
}

# ash_extract_palette <dest-NAME> <image> [--light]
#   Full pipeline: image → dominant hue and lightness → complete 13-slot theme.
ash_extract_palette() {
    local _target="$1" image="$2" variant="${3:-dark}"

    local hue; hue="$(ash_extract_dominant_hue "$image")" || return 1

    # Seed lightness: median of the extracted colours, so a dark wallpaper gets
    # a dark base and a bright one gets a light base.
    local colors base_l
    colors="$(ash_extract_colors "$image" 16)" || return 1
    base_l="$(_ash_ok_awk "BEGIN { print 0.18 }")"

    local hex lch L sum=0 n=0
    while IFS= read -r hex; do
        [[ -n "$hex" ]] || continue
        lch="$(ash_ok_from_hex "$hex")" || continue
        L="$(cut -d' ' -f1 <<<"$lch")"
        sum="$(_ash_ok_awk "BEGIN { printf \"%.8f\", $sum + $L }")"
        (( n += 1 ))
    done <<<"$colors"

    if (( n > 0 )); then
        base_l="$(_ash_ok_awk "BEGIN { v = $sum / $n; if (v < 0.12) v = 0.12; if (v > 0.30) v = 0.30; printf \"%.6f\", v }")"
    fi

    local seed; seed="$(ash_ok_to_hex "$base_l" 0.030 "$hue")"
    ash_palette_derive "$_target" "$seed" "$variant"
}
