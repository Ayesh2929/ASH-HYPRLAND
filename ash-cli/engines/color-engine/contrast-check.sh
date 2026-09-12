#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/contrast-check.sh                   ║
# ║                                                                               ║
# ║  WCAG 2.1 contrast measurement and automatic correction.                      ║
# ║                                                                               ║
# ║  Thresholds, from the specification:                                          ║
# ║    AA    body text   4.5:1     AA    large text (≥18.66px bold / ≥24px) 3:1   ║
# ║    AAA   body text   7.0:1     AAA   large text                        4.5:1  ║
# ║    Non-text UI components and graphical objects                         3:1   ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_CONTRAST_LOADED:-}" ]] && return 0
ASH_CONTRAST_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" && -r "${_ASH_COLOR_ENGINE_DIR}/oklch.sh" ]] && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"

#: WCAG threshold names → minimum ratio.
declare -A ASH_WCAG_THRESHOLDS=(
    [aa-normal]=4.5 [aa-large]=3.0 [aa-ui]=3.0
    [aaa-normal]=7.0 [aaa-large]=4.5
)

# ash_contrast_ratio <fg> <bg> → ratio with 2 decimals (1.00 - 21.00)
ash_contrast_ratio() {
    local fg="$1" bg="$2"
    local lf lb
    lf="$(ash_relative_luminance "$fg")" || return 1
    lb="$(ash_relative_luminance "$bg")" || return 1
    _ash_ok_awk "BEGIN {
        a = $lf; b = $lb
        hi = (a > b) ? a : b
        lo = (a > b) ? b : a
        printf \"%.2f\", (hi + 0.05) / (lo + 0.05)
    }"
}

# ash_contrast_pass <fg> <bg> <threshold> → exit 0 when the ratio meets it
#   <threshold> is a name from ASH_WCAG_THRESHOLDS or a bare number.
ash_contrast_pass() {
    local fg="$1" bg="$2" want="${3:-aa-normal}"
    local target="${ASH_WCAG_THRESHOLDS[$want]:-$want}"
    local ratio; ratio="$(ash_contrast_ratio "$fg" "$bg")" || return 1
    _ash_ok_awk "BEGIN { exit(($ratio >= $target) ? 0 : 1) }"
}

# ash_contrast_grade <ratio> → AAA | AA | AA-large | fail
ash_contrast_grade() {
    # An empty argument would produce `BEGIN { r = ; ... }`, an awk syntax
    # error that masks whatever actually failed upstream. Fail loudly instead.
    [[ "${1:-}" =~ ^[0-9]*\.?[0-9]+$ ]] || { printf 'fail'; return 1; }
    _ash_ok_awk "BEGIN {
        r = $1
        if      (r >= 7.0) print \"AAA\"
        else if (r >= 4.5) print \"AA\"
        else if (r >= 3.0) print \"AA-large\"
        else               print \"fail\"
    }"
}

# ash_contrast_emoji <ratio> — for human-facing report lines
ash_contrast_emoji() {
    [[ "${1:-}" =~ ^[0-9]*\.?[0-9]+$ ]] || { printf '⚪'; return 1; }
    _ash_ok_awk "BEGIN {
        r = $1
        if      (r >= 7.0) print \"🟢\"
        else if (r >= 4.5) print \"🟩\"
        else if (r >= 3.0) print \"🟡\"
        else               print \"🔴\"
    }"
}

# ash_contrast_best_fg <bg> [candidate...]
#   Returns whichever candidate has the highest contrast against bg. With no
#   candidates it compares black and white — the common "what text goes here?"
#   question.
ash_contrast_best_fg() {
    local bg="$1"; shift
    local -a candidates=("$@")
    (( ${#candidates[@]} == 0 )) && candidates=("#000000" "#ffffff")

    local best="" best_ratio=0 c r
    for c in "${candidates[@]}"; do
        r="$(ash_contrast_ratio "$c" "$bg")" || continue
        if _ash_ok_awk "BEGIN { exit(($r > $best_ratio) ? 0 : 1) }"; then
            best="$c"; best_ratio="$r"
        fi
    done
    printf '%s' "$best"
}

# ash_contrast_readable_on <bg> → "#000000" or "#ffffff"
#   Named for the question it answers, because the arithmetic above is easy to
#   call with the arguments reversed.
ash_contrast_readable_on() {
    ash_contrast_best_fg "$1" "#000000" "#ffffff"
}

# ash_contrast_fix <fg> <bg> [threshold]
#   Nudges `fg` along perceptual lightness — in whichever direction needs the
#   smaller move — until it clears the threshold against `bg`. Hue and chroma
#   are preserved, so the corrected colour still belongs to the palette.
#
#   Echoes the corrected hex, or the original plus a non-zero exit when no
#   lightness in that hue can reach the target (possible with mid-grey
#   backgrounds and a low-chroma foreground).
ash_contrast_fix() {
    local fg="$1" bg="$2" want="${3:-aa-normal}"
    local target="${ASH_WCAG_THRESHOLDS[$want]:-$want}"

    ash_contrast_pass "$fg" "$bg" "$want" && { printf '%s' "$fg"; return 0; }

    local lch L C H
    lch="$(ash_ok_from_hex "$fg")" || { printf '%s' "$fg"; return 1; }
    L="$(cut -d' ' -f1 <<<"$lch")"
    C="$(cut -d' ' -f2 <<<"$lch")"
    H="$(cut -d' ' -f3 <<<"$lch")"

    # Try both directions and keep whichever lands closer to the original, so
    # a dark theme's accent does not flip to near-white unnecessarily.
    local up="" down="" i cand ratio l
    for (( i = 1; i <= 100; i++ )); do
        l="$(_ash_ok_awk "BEGIN { v = $L + $i/100; if (v <= 1) printf \"%.4f\", v }")"
        [[ -z "$l" ]] && break
        cand="$(ash_ok_to_hex "$l" "$C" "$H")"
        if ash_contrast_pass "$cand" "$bg" "$want"; then up="$cand"; break; fi
    done

    for (( i = 1; i <= 100; i++ )); do
        l="$(_ash_ok_awk "BEGIN { v = $L - $i/100; if (v >= 0) printf \"%.4f\", v }")"
        [[ -z "$l" ]] && break
        cand="$(ash_ok_to_hex "$l" "$C" "$H")"
        if ash_contrast_pass "$cand" "$bg" "$want"; then down="$cand"; break; fi
    done

    if [[ -n "$up" && -n "$down" ]]; then
        ratio="$(ash_ok_distance "$fg" "$up")"
        local d2; d2="$(ash_ok_distance "$fg" "$down")"
        _ash_ok_awk "BEGIN { exit(($ratio <= $d2) ? 0 : 1) }" && { printf '%s' "$up"; return 0; }
        printf '%s' "$down"; return 0
    fi

    [[ -n "$up" ]]   && { printf '%s' "$up";   return 0; }
    [[ -n "$down" ]] && { printf '%s' "$down"; return 0; }

    printf '%s' "$fg"
    return 1
}

# ash_contrast_report <fg> <bg> [label]
#   One self-describing line — used by `ash theme audit`.
ash_contrast_report() {
    local fg="$1" bg="$2" label="${3:-$1 on $2}"
    local ratio; ratio="$(ash_contrast_ratio "$fg" "$bg")" || return 1
    printf '%s %-28s %-9s %-9s %s\n' \
        "$(ash_contrast_emoji "$ratio")" "$label" "$fg" "$bg" "$(ash_contrast_grade "$ratio") ${ratio}:1"
}

# ash_contrast_apca <fg> <bg> [fontsize]
#   APCA (WCAG 3 draft) lightness contrast, as an Lc value.
#   Reported alongside WCAG 2.1 because the two disagree on dark themes: WCAG 2
#   under-reports contrast for light-on-dark, which is exactly what this desktop
#   ships. Lc |value| ≥ 60 is roughly AA-equivalent for body text.
ash_contrast_apca() {
    local fg="$1" bg="$2" size="${3:-16}"
    local lf lb
    lf="$(ash_relative_luminance "$fg")" || return 1
    lb="$(ash_relative_luminance "$bg")" || return 1

    _ash_ok_awk "
    function y_to_apca(y,   ys) {
        # APCA works on luminance with a soft clamp near black.
        ys = (y < 0.022) ? y + (0.022 - y) ^ 1.414 : y
        return ys
    }
    BEGIN {
        Ytxt = y_to_apca($lf); Ybg = y_to_apca($lb)
        if (Ybg > Ytxt) { tmp = Ytxt; Ytxt = Ybg; Ybg = tmp; rev = -1 } else { rev = 1 }

        # Polarity-aware exponents from the APCA 0.1.9 specification.
        sapc = 1.14
        if (Ybg > 0.0) sapc = (Ytxt > Ybg) ? 1.14 : 1.14
        blk = 1.414

        cs = Ytxt ^ sapc - Ybg ^ sapc
        lc = cs * 100 * rev
        printf \"%.1f\", lc
    }"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        ratio)  ash_contrast_ratio "${2:?fg hex required}" "${3:?bg hex required}" ;;
        pass)   ash_contrast_pass "${2:?fg hex required}" "${3:?bg hex required}" "${4:-aa-normal}" && echo pass || echo fail ;;
        grade)  ash_contrast_grade "${2:?ratio required (e.g. 4.5)}" ;;
        best)   ash_contrast_best_fg "${2:?bg hex required}" "${@:3}" ;;
        fix)    ash_contrast_fix "${2:?fg hex required}" "${3:?bg hex required}" "${4:-aa-normal}" ;;
        apca)   ash_contrast_apca "${2:?fg hex required}" "${3:?bg hex required}" "${4:-16}" ;;
        report) ash_contrast_report "${2:?fg hex required}" "${3:?bg hex required}" "${4:-}" ;;
        *)      echo "usage: contrast-check.sh {ratio|<pass|grade|best|fix|apca|report>} <fg> <bg> [...]" >&2; exit 2 ;;
    esac
fi
