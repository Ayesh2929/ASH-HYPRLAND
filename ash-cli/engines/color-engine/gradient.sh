#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/gradient.sh                         ║
# ║                                                                               ║
# ║  Multi-stop gradients for wallpapers, bars and splash screens.                 ║
# ║                                                                               ║
# ║  Interpolation is always in OKLab. An sRGB gradient from blue to yellow passes ║
# ║  through grey — the hue rotates the long way round and desaturates in the      ║
# ║  middle. In OKLab the same gradient sweeps cleanly through green.             ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_GRADIENT_LOADED:-}" ]] && return 0
ASH_GRADIENT_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" ]]   && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
[[ -z "${ASH_PALETTE_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"
[[ -z "${ASH_CONTRAST_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/contrast-check.sh"

# `ash_grad_interp` is the workhorse: one colour at position t between two stops.
# Defined in awk so a 1000-colour interpolation is one process, not a thousand.
# clamp(), cbrt(), to_linear() and to_gamma() come from _ASH_OK_MATH, which
# _ash_grad_awk prepends. Redefining any of them here makes awk abort with
# "redefinition of ..." before it runs a single line.
_ASH_GRAD_AWK='

# Parsed stop storage: gL[], gC[], gH[], gT[] (t is the normalised position).
function to_lch(hex,   i, n, d, out, r, g, b, lab, A, B, C, H, c) {
    gsub(/^#/, "", hex); n = length(hex)
    if (n == 3) { out = ""; for (i = 1; i <= 3; i++) out = out substr(hex,i,1) substr(hex,i,1); hex = out }
    else if (n == 8) hex = substr(hex, 1, 6)
    else if (n != 6) return 0

    # Every character must be a hex digit. Without this, "#zzzzzz" parsed as a
    # colour because hex_int falls back to 9 for unknown characters, so a typo
    # produced a plausible-looking gradient instead of an error.
    for (i = 1; i <= 6; i++) {
        c = tolower(substr(hex, i, 1))
        if (!((c >= "0" && c <= "9") || (c >= "a" && c <= "f"))) return 0
    }

    r = hex_int(substr(hex,1,2)) / 255
    g = hex_int(substr(hex,3,2)) / 255
    b = hex_int(substr(hex,5,2)) / 255

    r = (r <= 0.04045) ? r/12.92 : ((r+0.055)/1.055)^2.4
    g = (g <= 0.04045) ? g/12.92 : ((g+0.055)/1.055)^2.4
    b = (b <= 0.04045) ? b/12.92 : ((b+0.055)/1.055)^2.4

    l = cbrt(0.4122214708*r + 0.5363325363*g + 0.0514459929*b)
    m = cbrt(0.2119034982*r + 0.6806995451*g + 0.1073969566*b)
    s = cbrt(0.0883024619*r + 0.2817188376*g + 0.6299787005*b)

    A = 1.9779984951*l - 2.4285922050*m + 0.4505937099*s
    B = 0.0259040371*l + 0.7827717662*m - 0.8086757660*s
    # discard_l = 0.2104542553*l + 0.7936177850*m - 0.0040720468*s

    gL[g_n] = 0.2104542553*l + 0.7936177850*m - 0.0040720468*s
    gC[g_n] = sqrt(A*A + B*B)
    H = atan2(B, A) * 180 / 3.141592653589793
    if (H < 0) H += 360
    gH[g_n] = H
    return 1
}

function hex_int(s,   i, n, c, v, d) {
    n = length(s); v = 0
    for (i = 1; i <= n; i++) {
        c = tolower(substr(s, i, 1))
        if (c >= "0" && c <= "9") {
            d = c + 0
        } else {
            # index() is 1-based, so "a" is 1 and must become 10. The earlier
            # attempt at this used `- 1`, which mapped "f" to 5 and then tripped
            # the range guard below, rejecting every colour containing a letter.
            d = index("abcdef", c)
            if (d == 0) return -1        # not a hex digit at all
            d = d + 9
        }
        v = v * 16 + d
    }
    return v
}

function emit(L, C, H,   rad, l, m, s, r, g, b, gr) {
    rad = H * 3.141592653589793 / 180
    l = (L + 0.3963377774*C*cos(rad) + 0.2158037573*C*sin(rad)) ^ 3
    m = (L - 0.1055613458*C*cos(rad) - 0.0638541728*C*sin(rad)) ^ 3
    s = (L - 0.0894841775*C*cos(rad) - 1.2914855480*C*sin(rad)) ^ 3

    r = clamp( 4.0767416621*l - 3.3077115913*m + 0.2309699292*s, 0, 1)
    g = clamp(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s, 0, 1)
    b = clamp(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s, 0, 1)

    r = (r <= 0.0031308) ? 12.92*r : 1.055*(r^(1/2.4)) - 0.055
    g = (g <= 0.0031308) ? 12.92*g : 1.055*(g^(1/2.4)) - 0.055
    b = (b <= 0.0031308) ? 12.92*b : 1.055*(b^(1/2.4)) - 0.055

    return sprintf("#%02x%02x%02x", int(clamp(r,0,1)*255+0.5), int(clamp(g,0,1)*255+0.5), int(clamp(b,0,1)*255+0.5))
}
'

_ash_grad_awk() {
    local -a opts=()
    while (( $# )) && [[ "$1" == "-v" || "$1" == "-F" ]]; do opts+=("$1" "${2:-}"); shift 2; done
    awk "${opts[@]}" "$_ASH_GRAD_AWK
$_ASH_OK_MATH
$1"
}

# ash_gradient_stops <count> <t> <stop:t>... → one hex per line
#   `t` is the position in [0,1] expressed as a string ("0.5") so this can run
#   inside an awk BEGIN block via interpolation.
ash_gradient_render() {
    local count="$1" position="$2"; shift 2
    [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )) || { printf 'ash gradient: count must be a positive integer\n' >&2; return 2; }

    # Stops are stored at the index awk itself is about to use (g_n), so the
    # position array and the colour arrays can never drift apart.
    local script=""
    local stop
    for stop in "$@"; do
        script+="gT[g_n] = ${stop##*:}; "
        script+="if (!to_lch(\"${stop%%:*}\")) { print \"bad-stop\"; exit 1 } "
        script+="g_n++; "
    done

    _ash_grad_awk "
    BEGIN {
        g_n = 0
        $script

        if (g_n < 2) { print \"need-at-least-two-stops\"; exit 1 }

        # Ensure stops are ordered; a caller passing them out of order would
        # otherwise get a gradient that jumps backwards at the break.
        for (a = 0; a < g_n; a++)
            for (b = a + 1; b < g_n; b++)
                if (gT[b] < gT[a]) {
                    t = gT[a]; gT[a] = gT[b]; gT[b] = t
                    t = gL[a]; gL[a] = gL[b]; gL[b] = t
                    t = gC[a]; gC[a] = gC[b]; gC[b] = t
                    t = gH[a]; gH[a] = gH[b]; gH[b] = t
                }

        t = $position
        if (t < 0) t = 0
        if (t > 1) t = 1

        # Locate the bracketing pair.
        idx = 0
        while (idx < g_n - 2 && t > gT[idx + 1]) idx++

        t0 = gT[idx]; t1 = gT[idx + 1]
        f = (t1 > t0) ? (t - t0) / (t1 - t0) : 0
        if (f < 0) f = 0
        if (f > 1) f = 1

        # Shortest-arc hue interpolation: 350 to 10 goes through 0, not 180.
        dh = gH[idx + 1] - gH[idx]
        while (dh >  180) dh -= 360
        while (dh < -180) dh += 360

        L = gL[idx] + (gL[idx + 1] - gL[idx]) * f
        C = gC[idx] + (gC[idx + 1] - gC[idx]) * f
        H = gH[idx] + dh * f

        # Clamp chroma at the interpolated lightness. Without this, a gradient
        # that interpolates through a dark midpoint can ask for chroma sRGB
        # cannot hold there, and the per-channel clamp turns it muddy grey.
        C = clamp_chroma(L, C, H)

        print emit(L, C, H)
    }

    function clamp_chroma(L, C, H,   rad, lo, hi, mid, i, l, m, s, r, g, b, eps) {
        rad = H * 3.141592653589793 / 180
        lo = 0; hi = C
        for (i = 0; i < 20; i++) {
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
    "
}

# ash_gradient_ramp <count> <stop:t>...
#   The whole gradient, sampled <count> times, as a newline-separated list.
ash_gradient_ramp() {
    local count="$1"; shift

    local script=""
    local stop
    for stop in "$@"; do
        script+="gT[g_n] = ${stop##*:}; if (!to_lch(\"${stop%%:*}\")) { print \"bad-stop\"; exit 1 } g_n++; "
    done

    _ash_grad_awk "
    BEGIN {
        g_n = 0; $script
        if (g_n < 2) { print \"need-at-least-two-stops\"; exit 1 }

        for (a = 0; a < g_n; a++)
            for (b = a + 1; b < g_n; b++)
                if (gT[b] < gT[a]) {
                    t=gT[a]; gT[a]=gT[b]; gT[b]=t
                    t=gL[a]; gL[a]=gL[b]; gL[b]=t
                    t=gC[a]; gC[a]=gC[b]; gC[b]=t
                    t=gH[a]; gH[a]=gH[b]; gH[b]=t
                }

        N = $count
        for (k = 0; k < N; k++) {
            t = (N == 1) ? 0 : k / (N - 1)

            idx = 0
            while (idx < g_n - 2 && t > gT[idx + 1]) idx++

            t0 = gT[idx]; t1 = gT[idx + 1]
            f = (t1 > t0) ? (t - t0) / (t1 - t0) : 0
            if (f < 0) f = 0
            if (f > 1) f = 1

            dh = gH[idx + 1] - gH[idx]
            while (dh >  180) dh -= 360
            while (dh < -180) dh += 360

            L = gL[idx] + (gL[idx + 1] - gL[idx]) * f
            C = gC[idx] + (gC[idx + 1] - gC[idx]) * f
            H = gH[idx] + dh * f

            C = clamp_chroma(L, C, H)
            print emit(L, C, H)
        }
    }

    function clamp_chroma(L, C, H,   rad, lo, hi, mid, i, l, m, s, r, g, b, eps) {
        rad = H * 3.141592653589793 / 180
        lo = 0; hi = C
        for (i = 0; i < 20; i++) {
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
    "
}

# ash_gradient_css <angle> <stop:t>...  → a CSS gradient value
ash_gradient_css() {
    local angle="$1"; shift
    local -a parts=()
    local stop
    for stop in "$@"; do
        parts+=("${stop%%:*} $(_ash_ok_awk "BEGIN { printf \"%.4g%%\", ${stop##*:} * 100 }")")
    done
    local IFS=', '
    printf 'linear-gradient(%sdeg, %s)' "$angle" "${parts[*]}"
}

# ash_gradient_from_palette <name> [count]
#   A harmonious gradient straight from a palette: crust → base → accent, which
#   is what the dashboard wallpaper preview uses.
ash_gradient_from_palette() {
    local -n _p="$1"
    local count="${2:-16}"
    ash_gradient_ramp "$count" \
        "${_p[crust]:-${_p[base]}}:0" \
        "${_p[base]}:0.45" \
        "${_p[surface]:-${_p[base]}}:0.75" \
        "${_p[accent]}:1"
}

# ash_gradient_quality <stop:t>...
#   Reports the perceptual-size uniformity of a gradient by measuring the
#   distance between adjacent samples. A gradient that "bands" has large gaps
#   between some neighbours and tiny ones between others; the ratio of worst to
#   best is the score. Used by the wallpaper engine to reject banded ramps.
ash_gradient_quality() {
    local samples
    samples="$(ash_gradient_ramp 33 "$@")" || return 1

    local line prev="" min=999 max=0 d
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ -n "$prev" ]]; then
            d="$(ash_ok_distance "$prev" "$line")"
            _ash_ok_awk "BEGIN { exit(($d < $min) ? 0 : 1) }" && min="$d"
            _ash_ok_awk "BEGIN { exit(($d > $max) ? 0 : 1) }" && max="$d"
        fi
        prev="$line"
    done <<<"$samples"

    if _ash_ok_awk "BEGIN { exit(($min <= 0) ? 0 : 1) }"; then
        printf '1.0'   # degenerate: a single flat colour
        return 0
    fi
    _ash_ok_awk "BEGIN { printf \"%.4f\", $min / $max }"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        ramp)
            shift
            ash_gradient_ramp "$@"
            ;;
        css)
            shift
            ash_gradient_css "$@"
            ;;
        quality)
            shift
            ash_gradient_quality "$@"
            ;;
        *)
            cat <<'USAGE'
usage: gradient.sh ramp <count> <hex:t>...
       gradient.sh css  <angle> <hex:t>...
       gradient.sh quality <hex:t>...
USAGE
            exit 2
            ;;
    esac
fi
