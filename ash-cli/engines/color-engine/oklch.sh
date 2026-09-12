#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/oklch.sh                            ║
# ║                                                                               ║
# ║  Perceptually-uniform colour space conversions.                               ║
# ║                                                                               ║
# ║  WHY OKLCH AND NOT HSL                                                       ║
# ║  HSL lightness lies. hsl(60 100% 50%) (yellow) and hsl(240 100% 50%) (blue)  ║
# ║  both report 50% lightness, but yellow is roughly ten times more luminous.    ║
# ║  A nine-step ramp built in HSL therefore produces a theme whose "dark" and    ║
# ║  "light" variants have wildly different contrast, and text that passes AA     ║
# ║  in one hue fails in another. OKLCH is perceptually uniform, so a fixed       ║
# ║  lightness step is a fixed *perceived* step in every hue. That property is    ║
# ║  what makes generated themes reliably readable.                              ║
# ║                                                                               ║
# ║  Reference: Björn Ottosson, "A perceptual color space for image processing"   ║
# ║  https://bottosson.github.io/posts/oklab/                                     ║
# ║                                                                               ║
# ║  Sourceable library — no side effects on import.                             ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ── Guard against double-sourcing ────────────────────────────────────────────
[[ -n "${ASH_OKLCH_LOADED:-}" ]] && return 0
ASH_OKLCH_LOADED=1

# ═══════════════════════════════════════════════════════════════════════════════
# § 1  MATH CORE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Bash arithmetic is integer-only, so every conversion is handed to awk, which
# every POSIX system ships and which carries IEEE-754 doubles. awk is used
# *instead of* python3 deliberately: python3 is an optional dependency of this
# project, and a colour engine that stops working without it would take the
# whole theming system down with it.
#
# cbrt() is not in POSIX awk, and `x ^ (1/3)` returns nan for negative x, which
# OKLab produces for out-of-gamut colours. _ash_ok_awk injects a sign-correct
# cube root that all the conversions below share.

_ASH_OK_MATH='
function cbrt(x)      { return (x < 0) ? -((-x) ^ (1/3)) : (x ^ (1/3)) }
function clamp(x, lo, hi) { return (x < lo) ? lo : ((x > hi) ? hi : x) }

# sRGB transfer function, both directions.
function to_linear(c) { c = c / 255; return (c <= 0.04045) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
function to_gamma(c)  { return (c <= 0.0031308) ? 12.92 * c : 1.055 * (c ^ (1/2.4)) - 0.055 }

# ── sRGB → OKLab ─────────────────────────────────────────────────────────────
function rgb_to_oklab(r, g, b,   l, m, s) {
    r = to_linear(r); g = to_linear(g); b = to_linear(b)

    l = cbrt(0.4122214708*r + 0.5363325363*g + 0.0514459929*b)
    m = cbrt(0.2119034982*r + 0.6806995451*g + 0.1073969566*b)
    s = cbrt(0.0883024619*r + 0.2817188376*g + 0.6299787005*b)

    return sprintf("%.10f %.10f %.10f",
        0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
        1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
        0.0259040371*l + 0.7827717662*m - 0.8086757660*s)
}

# ── OKLab → sRGB (0-255, clamped to gamut) ───────────────────────────────────
function oklab_to_rgb(L, A, B,   l, m, s) {
    l = (L + 0.3963377774*A + 0.2158037573*B) ^ 3
    m = (L - 0.1055613458*A - 0.0638541728*B) ^ 3
    s = (L - 0.0894841775*A - 1.2914855480*B) ^ 3

    return sprintf("%.4f %.4f %.4f",
        clamp(to_gamma( 4.0767416621*l - 3.3077115913*m + 0.2309699292*s) * 255, 0, 255),
        clamp(to_gamma(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s) * 255, 0, 255),
        clamp(to_gamma(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s) * 255, 0, 255))
}
'

#: Inject `_ASH_OK_MATH` plus the body, and run it.
_ash_ok_awk() {
    awk "$_ASH_OK_MATH
$1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 2  HEX PARSING
# ═══════════════════════════════════════════════════════════════════════════════

# ash_ok_normalize_hex <hex>
#   "#ABC" → "#aabbcc"; "#AABBCCDD" → "#aabbcc" (alpha dropped);
#   "#aabbcc" → "#aabbcc". Echoes "" when the input is not a colour.
ash_ok_normalize_hex() {
    local hex="${1:-}"
    hex="${hex#"${hex%%[![:space:]]*}"}"        # ltrim
    hex="${hex%"${hex##*[![:space:]]}"}"        # rtrim
    hex="${hex#\#}"                             # drop the leading #

    # 0x / rgb() / bare words are all rejected rather than guessed at.
    [[ "$hex" =~ ^[0-9a-fA-F]+$ ]] || { printf ''; return 1; }

    case "${#hex}" in
        3) hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}" ;;
        6) : ;;
        8) hex="${hex:0:6}" ;;                  # #rrggbbaa — alpha is ignored
        *) printf ''; return 1 ;;
    esac

    printf '#%s' "${hex,,}"
}

# ash_ok_hex_to_rgb <hex> → "R G B" (0-255, integers)
ash_ok_hex_to_rgb() {
    local hex
    hex="$(ash_ok_normalize_hex "$1")" || return 1
    [[ -n "$hex" ]] || return 1
    hex="${hex#\#}"
    printf '%d %d %d' "$((16#${hex:0:2}))" "$((16#${hex:2:2}))" "$((16#${hex:4:2}))"
}

# ash_ok_rgb_to_hex <r> <g> <b> → "#rrggbb"
ash_ok_rgb_to_hex() {
    local r="${1%.*}" g="${2%.*}" b="${3%.*}"
    (( r < 0 )) && r=0; (( r > 255 )) && r=255
    (( g < 0 )) && g=0; (( g > 255 )) && g=255
    (( b < 0 )) && b=0; (( b > 255 )) && b=255
    printf '#%02x%02x%02x' "$r" "$g" "$b"
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 3  CONVERSIONS
# ═══════════════════════════════════════════════════════════════════════════════

# ash_ok_from_hex <hex> → "L C H"  (L 0-1, C 0-~0.4, H 0-360 degrees)
ash_ok_from_hex() {
    local rgb
    rgb="$(ash_ok_hex_to_rgb "$1")" || return 1
    _ash_ok_awk "
    BEGIN {
        split(\"$rgb\", p, \" \")
        split(rgb_to_oklab(p[1], p[2], p[3]), lab, \" \")
        L = lab[1]; A = lab[2]; B = lab[3]
        C = sqrt(A*A + B*B)
        H = atan2(B, A) * 180 / 3.141592653589793
        if (H < 0) H += 360
        printf \"%.6f %.6f %.4f\", L, C, H
    }"
}

# ash_ok_to_hex <L> <C> <H> → "#rrggbb"
#   Out-of-gamut values are clamped per channel rather than rejected, because
#   a caller building a ramp should get the nearest displayable colour, not an
#   empty string it has to handle.
ash_ok_to_hex() {
    _ash_ok_awk "
    BEGIN {
        L = $1 + 0; C = $2 + 0; H = $3 + 0
        H = H * 3.141592653589793 / 180
        split(oklab_to_rgb(L, C * cos(H), C * sin(H)), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1] + 0.5), int(rgb[2] + 0.5), int(rgb[3] + 0.5)
    }"
}

# ash_ok_l / _c / _h <hex> → a single channel of the OKLCH representation.
ash_ok_l() { ash_ok_from_hex "$1" | cut -d' ' -f1; }
ash_ok_c() { ash_ok_from_hex "$1" | cut -d' ' -f2; }
ash_ok_h() { ash_ok_from_hex "$1" | cut -d' ' -f3; }

# ash_ok_component <hex> <index 1-3>
ash_ok_component() {
    ash_ok_from_hex "$1" | cut -d' ' -f"$2"
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 4  PERCEPTUAL OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════════

# ash_ok_adjust <hex> [--l DELTA] [--c MULT] [--h DELTA]
#   Adjust lightness by an absolute amount, chroma by a multiplier, and hue by
#   a rotation. Chroma is multiplicative because it is a magnitude; lightness
#   is additive because it is bounded and callers think in "a bit lighter".
ash_ok_adjust() {
    local hex="$1"; shift
    local dl=0 cm=1 dh=0

    while (( $# )); do
        case "$1" in
            --l|-l) dl="${2:-0}"; shift 2 ;;
            --c|-c) cm="${2:-1}"; shift 2 ;;
            --h|-h) dh="${2:-0}"; shift 2 ;;
            *) shift ;;
        esac
    done

    local lch
    lch="$(ash_ok_from_hex "$hex")" || return 1

    _ash_ok_awk "
    BEGIN {
        split(\"$lch\", lch, \" \")
        L = clamp(lch[1] + ($dl), 0, 1)
        C = lch[2] * ($cm)
        if (C < 0) C = 0
        H = lch[3] + ($dh)
        while (H < 0)   H += 360
        while (H >= 360) H -= 360

        rad = H * 3.141592653589793 / 180
        split(oklab_to_rgb(L, C * cos(rad), C * sin(rad)), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1] + 0.5), int(rgb[2] + 0.5), int(rgb[3] + 0.5)
    }"
}

# ash_ok_lighten <hex> <amount 0-1>
ash_ok_lighten() { ash_ok_adjust "$1" --l "${2:-0.1}"; }

# ash_ok_darken <hex> <amount 0-1>
ash_ok_darken() { ash_ok_adjust "$1" --l "-${2:-0.1}"; }

# ash_ok_saturate <hex> <multiplier>  (1.2 = 20% more chroma)
ash_ok_saturate() { ash_ok_adjust "$1" --c "${2:-1.2}"; }

# ash_ok_desaturate <hex> <multiplier 0-1>
ash_ok_desaturate() { ash_ok_adjust "$1" --c "${2:-0.8}"; }

# ash_ok_rotate <hex> <degrees>
ash_ok_rotate() { ash_ok_adjust "$1" --h "${2:-0}"; }

# ash_ok_set_l <hex> <L>  — force lightness, keeping hue and chroma.
ash_ok_set_l() {
    local lch; lch="$(ash_ok_from_hex "$1")" || return 1
    _ash_ok_awk "
    BEGIN {
        split(\"$lch\", lch, \" \")
        L = clamp($2 + 0, 0, 1)
        H = lch[3] * 3.141592653589793 / 180
        split(oklab_to_rgb(L, lch[2] * cos(H), lch[2] * sin(H)), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1] + 0.5), int(rgb[2] + 0.5), int(rgb[3] + 0.5)
    }"
}

# ash_ok_set_h <hex> <degrees>
ash_ok_set_h() {
    local lch; lch="$(ash_ok_from_hex "$1")" || return 1
    _ash_ok_awk "
    BEGIN {
        split(\"$lch\", lch, \" \")
        H = ($2 + 0) * 3.141592653589793 / 180
        split(oklab_to_rgb(lch[1], lch[2] * cos(H), lch[2] * sin(H)), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1] + 0.5), int(rgb[2] + 0.5), int(rgb[3] + 0.5)
    }"
}

# ash_ok_mix <hex1> <hex2> [t 0-1]
#   Interpolates in OKLab rather than sRGB, so the midpoint of blue and yellow
#   is a muted green-grey instead of the muddy slate that naive channel
#   averaging produces.
ash_ok_mix() {
    local a="$1" b="$2" t="${3:-0.5}"
    local c1 c2
    c1="$(ash_ok_from_hex "$a")" || return 1
    c2="$(ash_ok_from_hex "$b")" || return 1

    _ash_ok_awk "
    BEGIN {
        split(\"$c1\", A, \" \"); split(\"$c2\", B, \" \")
        t = $t

        # Hue is circular: interpolating 350° and 10° the short way gives 0°,
        # not 180°. Take the shorter arc.
        dh = B[3] - A[3]
        if (dh >  180) dh -= 360
        if (dh < -180) dh += 360
        H = A[3] + dh * t
        while (H < 0)    H += 360
        while (H >= 360) H -= 360

        L = A[1] + (B[1] - A[1]) * t
        C = A[2] + (B[2] - A[2]) * t

        rad = H * 3.141592653589793 / 180
        split(oklab_to_rgb(L, C * cos(rad), C * sin(rad)), rgb, \" \")
        printf \"#%02x%02x%02x\", int(rgb[1] + 0.5), int(rgb[2] + 0.5), int(rgb[3] + 0.5)
    }"
}

# ash_ok_mix_many <t> <hex>...  — blend any number of colours evenly.
ash_ok_mix_many() {
    local t="$1"; shift
    local -a items=("$@")
    (( ${#items[@]} == 0 )) && { printf ''; return 1; }
    (( ${#items[@]} == 1 )) && { printf '%s' "${items[0]}"; return 0; }

    local span
    span="$(_ash_ok_awk "BEGIN { printf \"%.10f\", $t * (${#items[@]} - 1) }")"

    local idx="${span%.*}"
    local frac="${span#"$idx"}"
    frac="${frac:-0}"

    (( idx >= ${#items[@]} - 1 )) && { printf '%s' "${items[${#items[@]}-1]}"; return 0; }

    ash_ok_mix "${items[idx]}" "${items[idx + 1]}" "${frac#.}" 2>/dev/null \
        || ash_ok_mix "${items[idx]}" "${items[idx + 1]}" "0.$frac"
}

# ash_ok_distance <hex1> <hex2>
#   Perceptual distance (ΔE in OKLab). Roughly: <0.02 indistinguishable,
#   <0.1 related shades, >0.3 obviously different colours.
ash_ok_distance() {
    local c1 c2
    c1="$(ash_ok_from_hex "$1")" || return 1
    c2="$(ash_ok_from_hex "$2")" || return 1
    _ash_ok_awk "
    BEGIN {
        split(\"$c1\", A, \" \"); split(\"$c2\", B, \" \")
        r1 = A[3] * 3.141592653589793 / 180
        r2 = B[3] * 3.141592653589793 / 180
        ax1 = A[2]*cos(r1); ay1 = A[2]*sin(r1)
        ax2 = B[2]*cos(r2); ay2 = B[2]*sin(r2)
        printf \"%.6f\", sqrt((A[1]-B[1])^2 + (ax1-ax2)^2 + (ay1-ay2)^2)
    }"
}

# ash_ok_is_in_gamut <L> <C> <H> → exit 0 when fully displayable
#   OKLCH can express colours sRGB cannot. Detection matters when generating a
#   ramp: silently clamping produces two "different" steps that render the same.
ash_ok_is_in_gamut() {
    local L="$1" C="$2" H="$3"
    _ash_ok_awk "
    BEGIN {
        rad = ($H) * 3.141592653589793 / 180
        l = (($L) + 0.3963377774*($C)*cos(rad) + 0.2158037573*($C)*sin(rad)) ^ 3
        m = (($L) - 0.1055613458*($C)*cos(rad) - 0.0638541728*($C)*sin(rad)) ^ 3
        s = (($L) - 0.0894841775*($C)*cos(rad) - 1.2914855480*($C)*sin(rad)) ^ 3
        r =  4.0767416621*l - 3.3077115913*m + 0.2309699292*s
        g = -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
        b = -0.0041960863*l - 0.7034186147*m + 1.7076147010*s
        eps = 0.0005
        ok = (r >= -eps && r <= 1+eps && g >= -eps && g <= 1+eps && b >= -eps && b <= 1+eps)
        exit(ok ? 0 : 1)
    }"
}

# ash_ok_clamp_chroma <L> <C> <H> → the largest in-gamut chroma ≤ C
#   Binary search. 24 iterations resolve to well under a JND, and it is faster
#   than a linear scan of any useful precision.
ash_ok_clamp_chroma() {
    local L="$1" C="$2" H="$3"
    _ash_ok_awk "
    BEGIN {
        rad = ($H) * 3.141592653589793 / 180
        lo = 0; hi = ($C) + 0
        for (i = 0; i < 24; i++) {
            mid = (lo + hi) / 2
            l = (($L) + 0.3963377774*mid*cos(rad) + 0.2158037573*mid*sin(rad)) ^ 3
            m = (($L) - 0.1055613458*mid*cos(rad) - 0.0638541728*mid*sin(rad)) ^ 3
            s = (($L) - 0.0894841775*mid*cos(rad) - 1.2914855480*mid*sin(rad)) ^ 3
            r =  4.0767416621*l - 3.3077115913*m + 0.2309699292*s
            g = -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
            b = -0.0041960863*l - 0.7034186147*m + 1.7076147010*s
            eps = 0.0005
            if (r >= -eps && r <= 1+eps && g >= -eps && g <= 1+eps && b >= -eps && b <= 1+eps) lo = mid
            else hi = mid
        }
        printf \"%.6f\", lo
    }"
}

# ash_relative_luminance <hex> → 0-1
#   The WCAG 2.1 relative-luminance definition. It lives here rather than in
#   hsl.sh or contrast-check.sh because both of those need it, and a peer-to-
#   peer dependency between them would be a cycle waiting to happen.
ash_relative_luminance() {
    local rgb; rgb="$(ash_ok_hex_to_rgb "$1")" || return 1
    _ash_ok_awk "
    BEGIN {
        split(\"$rgb\", p, \" \")
        printf \"%.6f\", 0.2126*to_linear(p[1]) + 0.7152*to_linear(p[2]) + 0.0722*to_linear(p[3])
    }"
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 5  BATCH INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Rendering a full theme converts ~200 colours. Forking awk 200 times costs
# roughly 400 ms; one awk process reading a request stream costs about 4 ms.
# `ash_ok_batch` therefore takes a file (or stdin) of "op arg arg ..." lines
# and answers each on its own line, preserving order.

# ash_ok_batch [file]   — reads stdin when no file is given
ash_ok_batch() {
    local src="${1:--}"
    _ash_ok_awk "
    function emit_hex(L, C, H,   rad) {
        if (C < 0) C = 0
        while (H < 0)    H += 360
        while (H >= 360) H -= 360
        rad = H * 3.141592653589793 / 180
        split(oklab_to_rgb(L, C * cos(rad), C * sin(rad)), rgb, \" \")
        return sprintf(\"#%02x%02x%02x\", int(rgb[1] + 0.5), int(rgb[2] + 0.5), int(rgb[3] + 0.5))
    }

    function parse_hex(h,   s, n,   i, out) {
        gsub(/^#/, \"\", h)
        n = length(h)
        if (n == 3) { out = \"\"; for (i = 1; i <= 3; i++) out = out substr(h,i,1) substr(h,i,1); h = out }
        else if (n == 8) h = substr(h, 1, 6)
        else if (n != 6) return \"\"
        return \"#\" tolower(h)
    }

    function to_lch(h,   rgb, lab, A) {
        h = parse_hex(h)
        if (h == \"\") return \"\"
        rgb = sprintf(\"%d %d %d\",
            strtonum_or_hex(substr(h,2,2)), strtonum_or_hex(substr(h,4,2)), strtonum_or_hex(substr(h,6,2)))
        split(rgb, p, \" \")
        split(rgb_to_oklab(p[1], p[2], p[3]), lab, \" \")
        C = sqrt(lab[2]*lab[2] + lab[3]*lab[3])
        H = atan2(lab[3], lab[2]) * 180 / 3.141592653589793
        if (H < 0) H += 360
        return sprintf(\"%.6f %.6f %.4f\", lab[1], C, H)
    }

    # awk has no hex integer literal; build it digit by digit.
    function strtonum_or_hex(s,   i, n, d, v) {
        n = length(s); v = 0
        for (i = 1; i <= n; i++) {
            d = hexval(substr(s, i, 1))
            v = v * 16 + d
        }
        return v
    }
    function hexval(c) {
        c = tolower(c)
        if (c >= \"0\" && c <= \"9\") return c + 0
        return index(\"abcdef\", c) + 9
    }

    {
        op = \$1
        if (op == \"from\")      { print to_lch(\$2) }
        else if (op == \"to\")   { print emit_hex(\$2+0, \$3+0, \$4+0) }
        else if (op == \"adjust\") {
            # adjust <hex> <dL> <cMul> <dH>
            split(to_lch(\$2), lch, \" \")
            print emit_hex(clamp(lch[1]+\$3+0,0,1), lch[2]*\$4, lch[3]+\$5+0)
        }
        else if (op == \"mix\")  {
            # mix <hex1> <hex2> <t>
            split(to_lch(\$2), A, \" \"); split(to_lch(\$3), B, \" \")
            t = \$4 + 0
            dh = B[3] - A[3]
            if (dh >  180) dh -= 360
            if (dh < -180) dh += 360
            H = A[3] + dh * t
            print emit_hex(A[1] + (B[1]-A[1])*t, A[2] + (B[2]-A[2])*t, H)
        }
        else if (op == \"dist\") {
            split(to_lch(\$2), A, \" \"); split(to_lch(\$3), B, \" \")
            r1 = A[3]*3.141592653589793/180; r2 = B[3]*3.141592653589793/180
            printf \"%.6f\n\", sqrt((A[1]-B[1])^2 + (A[2]*cos(r1)-B[2]*cos(r2))^2 + (A[2]*sin(r1)-B[2]*sin(r2))^2)
        }
        else if (op == \"gamut\") {
            split(to_lch(\$2), lch, \" \")
            printf \"%.6f\n\", clamp_chroma(lch[1], lch[2], lch[3])
        }
        else { print \"\" }
    }

    function clamp_chroma(L, C, H,   rad, lo, hi, mid, l, m, s, r, g, b, eps, i) {
        rad = H * 3.141592653589793 / 180
        lo = 0; hi = C
        for (i = 0; i < 24; i++) {
            mid = (lo + hi) / 2
            l = (L + 0.3963377774*mid*cos(rad) + 0.2158037573*mid*sin(rad)) ^ 3
            m = (L - 0.1055613458*mid*cos(rad) - 0.0638541728*mid*sin(rad)) ^ 3
            s = (L - 0.0894841775*mid*cos(rad) - 1.2914855480*mid*sin(rad)) ^ 3
            r =  4.0767416621*l - 3.3077115913*m + 0.2309699292*s
            g = -1.2684380046*l + 2.6097574011*m - 0.3413193965*s
            b = -0.0041960863*l - 0.7034186147*m + 1.7076147010*s
            eps = 0.0005
            if (r >= -eps && r <= 1+eps && g >= -eps && g <= 1+eps && b >= -eps && b <= 1+eps) lo = mid
            else hi = mid
        }
        return lo
    }
    " "$src"
}

# ═══════════════════════════════════════════════════════════════════════════════
# § 6  STANDALONE CLI
# ═══════════════════════════════════════════════════════════════════════════════

ash_oklch_usage() {
    cat <<'USAGE'
ash oklch — perceptual colour conversions

  ash oklch <hex>                    show L, C and H for a colour
  ash oklch from <hex>               the same, machine-readable
  ash oklch to <L> <C> <H>           build a colour from OKLCH
  ash oklch lighten <hex> [amount]   raise perceptual lightness (default 0.1)
  ash oklch darken  <hex> [amount]   lower perceptual lightness
  ash oklch saturate <hex> [mult]    multiply chroma (default 1.2)
  ash oklch desaturate <hex> [mult]  multiply chroma (default 0.8)
  ash oklch rotate <hex> <degrees>   rotate hue
  ash oklch mix <hex1> <hex2> [t]    blend in OKLab (default 0.5)
  ash oklch distance <hex1> <hex2>   perceptual ΔE
  ash oklch gamut <hex>              largest in-gamut chroma for its L and H
  ash oklch luminance <hex>          WCAG 2.1 relative luminance (0-1)

Every command prints a bare hex value on stdout so it composes in a pipeline:
  ash oklch mix "$(ash oklch rotate "#cba6f7" 180)" "#89dceb" 0.3
USAGE
}

ash_oklch_main() {
    case "${1:-}" in
        from)       ash_ok_from_hex "${2:?hex required}" ;;
        to)         ash_ok_to_hex "${2:?L required}" "${3:?C required}" "${4:?H required}" ;;

        lighten)    ash_ok_lighten "${2:?hex required}" "${3:-0.1}" ;;
        darken)     ash_ok_darken  "${2:?hex required}" "${3:-0.1}" ;;
        saturate)   ash_ok_saturate   "${2:?hex required}" "${3:-1.2}" ;;
        desaturate) ash_ok_desaturate "${2:?hex required}" "${3:-0.8}" ;;
        rotate)     ash_ok_rotate "${2:?hex required}" "${3:?degrees required}" ;;

        mix)        ash_ok_mix "${2:?first hex required}" "${3:?second hex required}" "${4:-0.5}" ;;
        distance)   ash_ok_distance "${2:?first hex required}" "${3:?second hex required}" ;;
        luminance|lum) ash_relative_luminance "${2:?hex required}" ;;
        gamut)      ash_ok_clamp_chroma "$(ash_ok_l "${2:?hex required}")" "$(ash_ok_c "$2")" "$(ash_ok_h "$2")" ;;

        ''|help|-h|--help) ash_oklch_usage ;;

        *)  # A bare colour is the common case: `ash oklch "#cba6f7"`.
            if [[ -n "$(ash_ok_normalize_hex "$1")" ]]; then
                local lch; lch="$(ash_ok_from_hex "$1")"
                printf 'L  %s\nC  %s\nH  %s°\n' \
                    "$(cut -d' ' -f1 <<<"$lch")" \
                    "$(cut -d' ' -f2 <<<"$lch")" \
                    "$(cut -d' ' -f3 <<<"$lch")"
            else
                printf 'ash oklch: not a colour: %s\n\n' "$1" >&2
                ash_oklch_usage >&2
                return 2
            fi
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_oklch_main "$@"
fi
