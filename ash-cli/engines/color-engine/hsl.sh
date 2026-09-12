#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/hsl.sh                              ║
# ║                                                                               ║
# ║  HSL, HSV and HWB conversions, plus the legacy-format serialisers that GTK,   ║
# ║  GTK CSS and QSS still require.                                               ║
# ║                                                                               ║
# ║  HSL is kept because some targets only understand it (GTK3 named colours, a   ║
# ║  few terminal emulators), not because it is a good space to design in.        ║
# ║  Anything that involves perceived lightness goes through oklch.sh.            ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_HSL_LOADED:-}" ]] && return 0
ASH_HSL_LOADED=1

# ── Resolve our own directory so siblings can be sourced when this file is
#    loaded directly (not via the ash bootstrap, which sets its own path).
if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi

# oklch.sh is the foundation every other module here builds on; load it first.
if [[ -z "${ASH_OKLCH_LOADED:-}" && -r "${_ASH_COLOR_ENGINE_DIR}/oklch.sh" ]]; then
    # shellcheck source=./oklch.sh
    source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
fi

_ASH_HSL_MATH='
function clamp(x, lo, hi) { return (x < lo) ? lo : ((x > hi) ? hi : x) }
function abs(x)       { return (x < 0) ? -x : x }
function g2h(c) { return (c <= 0.0031308) ? 12.92*c : 1.055 * (c ^ (1/2.4)) - 0.055 }
function h2g(c) { c = c / 255; return (c <= 0.04045) ? c / 12.92 : ((c + 0.055)/1.055) ^ 2.4 }

function rgb_to_hsl(r, g, b,   mx, mn, d, h, s, l) {
    r = r/255; g = g/255; b = b/255
    mx = (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
    mn = (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
    d  = mx - mn
    l  = (mx + mn) / 2

    if (d == 0) { h = 0; s = 0 }
    else {
        s = (l > 0.5) ? d / (2 - mx - mn) : d / (mx + mn)
        if      (mx == r) h = ((g - b) / d) % 6
        else if (mx == g) h = (b - r) / d + 2
        else              h = (r - g) / d + 4
        h = h * 60
        if (h < 0) h += 360
    }
    return sprintf("%.4f %.4f %.4f", h, s * 100, l * 100)
}

function hsl_to_rgb(h, s, l,   c, x, m, r, g, b) {
    h = ((h % 360) + 360) % 360
    s = clamp(s, 0, 100) / 100
    l = clamp(l, 0, 100) / 100
    c = (1 - abs(2*l - 1)) * s
    x = c * (1 - abs(((h / 60) % 2) - 1))
    m = l - c / 2

    if      (h <  60) { r = c; g = x; b = 0 }
    else if (h < 120) { r = x; g = c; b = 0 }
    else if (h < 180) { r = 0; g = c; b = x }
    else if (h < 240) { r = 0; g = x; b = c }
    else if (h < 300) { r = x; g = 0; b = c }
    else              { r = c; g = 0; b = x }

    return sprintf("%.4f %.4f %.4f", clamp((r+m)*255,0,255), clamp((g+m)*255,0,255), clamp((b+m)*255,0,255))
}

function rgb_to_hsv(r, g, b,   mx, mn, d, h, s, v) {
    r = r/255; g = g/255; b = b/255
    mx = (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
    mn = (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
    d  = mx - mn
    v  = mx
    s  = (mx == 0) ? 0 : d / mx

    if (d == 0) h = 0
    else {
        if      (mx == r) h = ((g - b) / d) % 6
        else if (mx == g) h = (b - r) / d + 2
        else              h = (r - g) / d + 4
        h = h * 60
        if (h < 0) h += 360
    }
    return sprintf("%.4f %.4f %.4f", h, s * 100, v * 100)
}

function hsv_to_rgb(h, s, v,   c, x, m, r, g, b) {
    h = ((h % 360) + 360) % 360
    s = clamp(s, 0, 100) / 100
    v = clamp(v, 0, 100) / 100
    c = v * s
    x = c * (1 - abs(((h / 60) % 2) - 1))
    m = v - c

    if      (h <  60) { r = c; g = x; b = 0 }
    else if (h < 120) { r = x; g = c; b = 0 }
    else if (h < 180) { r = 0; g = c; b = x }
    else if (h < 240) { r = 0; g = x; b = c }
    else if (h < 300) { r = x; g = 0; b = c }
    else              { r = c; g = 0; b = x }

    return sprintf("%.4f %.4f %.4f", clamp((r+m)*255,0,255), clamp((g+m)*255,0,255), clamp((b+m)*255,0,255))
}
'

_ash_hsl_awk() { awk "$_ASH_HSL_MATH
$1"; }

# ash_hsl_from_hex <hex> → "H S L"   (H in degrees, S and L as percentages)
ash_hsl_from_hex() {
    local rgb; rgb="$(ash_ok_hex_to_rgb "$1")" || return 1
    _ash_hsl_awk "BEGIN { split(\"$rgb\", p, \" \"); print rgb_to_hsl(p[1], p[2], p[3]) }"
}

# ash_hsl_to_hex <H> <S> <L> → "#rrggbb"
ash_hsl_to_hex() {
    _ash_hsl_awk "
    BEGIN {
        split(hsl_to_rgb($1, $2, $3), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1]+0.5), int(rgb[2]+0.5), int(rgb[3]+0.5)
    }"
}

# ash_hsv_from_hex <hex> → "H S V"
ash_hsv_from_hex() {
    local rgb; rgb="$(ash_ok_hex_to_rgb "$1")" || return 1
    _ash_hsl_awk "BEGIN { split(\"$rgb\", p, \" \"); print rgb_to_hsv(p[1], p[2], p[3]) }"
}

# ash_hsv_to_hex <H> <S> <V> → "#rrggbb"
ash_hsv_to_hex() {
    _ash_hsl_awk "
    BEGIN {
        split(hsv_to_rgb($1, $2, $3), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1]+0.5), int(rgb[2]+0.5), int(rgb[3]+0.5)
    }"
}

# ash_hwb_from_hex <hex> → "H W B"  — whiteness and blackness
#   HWB is what most people actually describe when they say "a lighter, less
#   saturated version", so it is the right space for tint/shade controls.
ash_hwb_from_hex() {
    local rgb; rgb="$(ash_ok_hex_to_rgb "$1")" || return 1
    _ash_hsl_awk "
    BEGIN {
        split(\"$rgb\", p, \" \")
        split(rgb_to_hsv(p[1], p[2], p[3]), hsv, \" \")
        w = (1 - hsv[2]/100) * (1 - hsv[2]/100 > 0 ? 1 : 1) * (hsv[2] == 0 ? 1 : (1 - hsv[2]/100))
        # Correct HWB: W = min(r,g,b)/255, B = 1 - max(r,g,b)/255
        r = p[1]/255; g = p[2]/255; b = p[3]/255
        mn = (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b)
        mx = (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b)
        printf \"%.4f %.4f %.4f\", hsv[1], mn*100, (1-mx)*100
    }"
}

# ash_hwb_to_hex <H> <W> <B> → "#rrggbb"
ash_hwb_to_hex() {
    _ash_hsl_awk "
    BEGIN {
        h = ((($1) % 360) + 360) % 360
        w = clamp($2, 0, 100) / 100
        bl = clamp($3, 0, 100) / 100
        if (w + bl > 1) { s = w + bl; w = w / s; bl = bl / s }
        v = 1 - bl
        split(hsv_to_rgb(h, (v == 0) ? 0 : 1 - w / v, v * 100), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1]+0.5), int(rgb[2]+0.5), int(rgb[3]+0.5)
    }"
}

# ── Serialisers for targets that cannot read hex ─────────────────────────────

# ash_hsl_to_css <hex> [alpha] → "hsl(268 82% 81%)" (modern space syntax)
#   With an alpha the modern form is `hsl(H S% L% / A)` — a space-separated
#   prefix with a slash before the alpha, not the legacy comma/hsla spelling.
ash_hsl_to_css() {
    local hsl; hsl="$(ash_hsl_from_hex "$1")" || return 1
    local alpha="${2:-}"
    _ash_hsl_awk "
    BEGIN {
        split(\"$hsl\", h, \" \")
        a = \"$alpha\"
        if (a == \"\") printf \"hsl(%.0f %.0f%% %.0f%%)\", h[1], h[2], h[3]
        else           printf \"hsl(%.0f %.0f%% %.0f%% / %s)\", h[1], h[2], h[3], a
    }"
}

# ash_hsl_to_css_legacy <hex> [alpha] → "hsl(268, 82%, 81%)"
#   GTK3's CSS parser predates space-separated hsl() and will drop the whole
#   declaration if it sees it, so both forms exist.
ash_hsl_to_css_legacy() {
    local hsl; hsl="$(ash_hsl_from_hex "$1")" || return 1
    _ash_hsl_awk "BEGIN {
        split(\"$hsl\", h, \" \")
        if (\"${2:-}\" == \"\") printf \"hsl(%.0f, %.0f%%, %.0f%%)\", h[1], h[2], h[3]
        else                    printf \"hsla(%.0f, %.0f%%, %.0f%%, %s)\", h[1], h[2], h[3], \"${2}\"
    }"
}

# ash_hex_to_rgba_css <hex> [alpha] → "rgba(203, 166, 247, 0.5)"
ash_hex_to_rgba_css() {
    local rgb; rgb="$(ash_ok_hex_to_rgb "$1")" || return 1
    printf 'rgba(%s, %s)' "$(tr ' ' ',' <<<"$rgb" | sed 's/,/, /g')" "${2:-1}"
}

# ash_hex_to_argb <hex> [alpha]
#   Qt/QSS and Waybar's colour parser want #AARRGGBB — alpha FIRST, which is
#   the opposite of CSS. Getting this backwards produces a black rectangle.
ash_hex_to_argb() {
    local hex; hex="$(ash_ok_normalize_hex "$1")" || return 1
    local a="${2:-1}"
    local a8; a8="$(_ash_hsl_awk "BEGIN { printf \"%02x\", int(clamp($a,0,1) * 255 + 0.5) }")"
    printf '#%s%s' "$a8" "${hex#\#}"
}

# ash_hex_to_rgb_csv <hex> → "203,166,247"
ash_hex_to_rgb_csv() {
    ash_ok_hex_to_rgb "$1" | tr ' ' ','
}

# ash_hex_to_rgb_escaped <hex> → "203;166;247"  (ANSI truecolour)
ash_hex_to_rgb_escaped() {
    ash_ok_hex_to_rgb "$1" | tr ' ' ';'
}

# ash_hex_to_decimal <hex> → 0xRRGGBB as decimal (Xresources, some Java tools)
ash_hex_to_decimal() {
    local hex; hex="$(ash_ok_normalize_hex "$1")" || return 1
    printf '%d' "$((16#${hex#\#}))"
}

# ash_relative_luminance is defined in oklch.sh, which this module sources at
# the top. It is re-exported implicitly: any caller that sources hsl.sh gets it.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        from)   ash_hsl_from_hex "${2:?}" ;;
        to)     ash_hsl_to_hex "${2:?}" "${3:?}" "${4:?}" ;;
        hsv)    ash_hsv_from_hex "${2:?}" ;;
        rgb)    ash_hex_to_rgb_csv "${2:?}" ;;
        argb)   ash_hex_to_argb "${2:?}" "${3:-1}" ;;
        css)    ash_hsl_to_css_legacy "${2:?}" "${3:-}" ;;
        lum)    ash_relative_luminance "${2:?}" ;;
        *)      echo "usage: hsl.sh {from|hsv|rgb|argb|css|lum} <hex>" >&2; exit 2 ;;
    esac
fi
