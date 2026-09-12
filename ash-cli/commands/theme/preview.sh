#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — preview.sh                                                       ║
# ║  Render a theme before you commit to it: swatches, contrast, mock desktop      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::preview::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme preview${RST} <theme> [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Draws a theme without applying it. The swatch column is the colour itself, so
  a terminal that renders 24-bit colour shows you the real palette; a terminal
  that does not still gets the hex values.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--mock${RST}          Draw a mock bar and window in the theme
  ${ASH_MUTED}--gradient${RST}      Also render a 32-step gradient from the accents
  ${ASH_MUTED}--contrast, -c${RST}  Include the full WCAG pair report
  ${ASH_MUTED}--width, -w N${RST}   Swatch width (default 14)
  ${ASH_MUTED}--no-color${RST}      Hex values only
  ${ASH_MUTED}--json${RST}          Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme preview nord${RST}
  ${ASH_MUTED}ash theme preview nord --mock --gradient${RST}
EOF
}

# A run of text drawn on a background colour, with a foreground chosen for
# legibility rather than assumed. When colour is off the text is returned
# unchanged, so the caller's column widths survive.
_theme_preview_seg() {
    local bg="$1" fg="$2" text="$3"
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 1 || ! -t 1 ]]; then printf '%s' "$text"; return 0; fi
    local r g b
    r=$(( 16#${bg:1:2} )); g=$(( 16#${bg:3:2} )); b=$(( 16#${bg:5:2} ))
    if [[ -n "$fg" ]]; then
        printf '\033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm%s\033[0m' \
            "$r" "$g" "$b" \
            "$(( 16#${fg:1:2} ))" "$(( 16#${fg:3:2} ))" "$(( 16#${fg:5:2} ))" "$text"
    else
        printf '\033[48;2;%d;%d;%dm%s\033[0m' "$r" "$g" "$b" "$text"
    fi
}

# Best foreground for a background, via the contrast engine when it is loaded.
_theme_preview_fg_for() {
    local bg="$1" text="${2:-}" light="${3:-}"
    if declare -f ash_contrast_best_fg >/dev/null 2>&1; then
        ash_contrast_best_fg "$bg" 2>/dev/null && return 0
    fi
    printf '%s' "${text:-${light:-#ffffff}}"
}

# Draw a bar and a window so the palette can be judged as a UI and not as a
# list. Everything here is decorative; nothing is measured from it.
_theme_preview_mock() {
    local -n _pv="$1"
    local base="${_pv[base]}" mantle="${_pv[mantle]}" surface="${_pv[surface]}"
    local overlay="${_pv[overlay]}" text="${_pv[text]}" sub="${_pv[subtext]}"
    local accent="${_pv[accent]}" mint="${_pv[mint]}" rose="${_pv[rose]}"

    local fg_bar fg_acc fg_txt fg_sub
    fg_bar="$(_theme_preview_fg_for "$base" "$text")"
    fg_txt="$(_theme_preview_fg_for "$surface" "$text")"
    fg_sub="$(_theme_preview_fg_for "$overlay" "$sub")"
    fg_acc="$(_theme_preview_fg_for "$accent" "$base")"

    local w=64 seg pad
    pad="$(printf '%*s' "$(( w - 20 ))" '')"

    printf '\n  %s%s\n' "${BOLD}${ASH_PRIMARY}" "Mock desktop" "${RST}"
    printf '  '
    _theme_preview_seg "$base" "$fg_bar" "  ◉ 1 "
    _theme_preview_seg "$accent" "$fg_acc" " 2 "
    _theme_preview_seg "$base" "$fg_bar" "  3     ✦  "
    _theme_preview_seg "$base" "$fg_bar" "$pad"
    _theme_preview_seg "$mint" "$fg_bar" "   "
    _theme_preview_seg "$base" "$fg_bar" "    "
    _theme_preview_seg "$rose" "$fg_bar" "   "
    _theme_preview_seg "$base" "$fg_bar" " 20:14 "
    printf '\n  '

    # Window: title bar on mantle, body on surface, a dock strip on overlay.
    _theme_preview_seg "$mantle" "$fg_bar" " ● ● ● "
    _theme_preview_seg "$mantle" "$fg_bar" "  ashtop                        "
    printf '\n  '
    _theme_preview_seg "$surface" "$fg_txt" "  ACTIVE THEME                        CPU  12%   "
    printf '\n  '
    _theme_preview_seg "$surface" "$fg_txt" "  $(printf '▁▂▃▅▇█▇▅▃▂▁▂▃▅▇█▇▅▃▂▁' | cut -c1-$(( w - 8 )))"
    printf '\n  '
    _theme_preview_seg "$overlay" "$fg_sub" "  ▏$pad▏ "
    printf '\n\n'
}

# A gradient is the honest test of a palette: if the slots do not belong to one
# family the seams show up as banding.
_theme_preview_gradient() {
    local -n _pv="$1"
    local width="${2:-64}"

    # With colour off a wall of blank spaces tells you nothing, so print the
    # ramp as hex instead — the same information in a form that survives a pipe.
    if [[ "${ASH_FLAG_NO_COLOR:-0}" -eq 1 || ! -t 1 ]]; then
        printf '\n  %s%s\n  ' "${BOLD}${ASH_PRIMARY}" "Gradient" "${RST}"
        local -a hexes=()
        if declare -f ash_gradient_from_palette >/dev/null 2>&1; then
            mapfile -t hexes < <(ash_gradient_from_palette _pv "$width" 2>/dev/null) || true
        fi
        if (( ${#hexes[@]} == 0 )); then
            hexes=("${_pv[accent]:-}" "${_pv[mint]:-}" "${_pv[sky]:-}" "${_pv[gold]:-}" "${_pv[rose]:-}" "${_pv[violet]:-}")
        fi
        local h n=0
        for h in "${hexes[@]}"; do
            [[ "$h" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
            printf '%s ' "$h"
            (( n++ )) || true
        done
        printf '\n  %s%s stops%s\n\n' "${ASH_MUTED}" "$n" "${RST}"
        return 0
    fi

    if declare -f ash_gradient_from_palette >/dev/null 2>&1; then
        local -a ramp=()
        mapfile -t ramp < <(ash_gradient_from_palette _pv "$width" 2>/dev/null) || true
        if (( ${#ramp[@]} )); then
            printf '\n  %s%s\n  ' "${BOLD}${ASH_PRIMARY}" "Gradient" "${RST}"
            local c
            for c in "${ramp[@]}"; do
                [[ -n "$c" ]] && _theme_preview_seg "$c" "" " "
            done
            printf '\n\n'
            return 0
        fi
    fi

    # Fallback: interpolate between the accent slots directly.
    local -a stops=("${_pv[accent]}" "${_pv[mint]}" "${_pv[sky]}" "${_pv[gold]}" "${_pv[rose]}" "${_pv[violet]}")
    printf '\n  %s%s\n  ' "${BOLD}${ASH_PRIMARY}" "Gradient" "${RST}"
    local i steps=$(( width / 5 )) s
    for s in "${stops[@]:0:5}"; do
        [[ "$s" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
        for (( i = 0; i < steps; i++ )); do _theme_preview_seg "$s" "" " "; done
    done
    printf '\n\n'
}

theme::preview() {
    local want="" width=14 mock=0 gradient=0 contrast=0
    local -a args=("$@")

    while (( $# )); do
        case "$1" in
            --mock)              mock=1; shift ;;
            --gradient)          gradient=1; shift ;;
            --contrast|-c)       contrast=1; shift ;;
            --width|-w)          width="${2:-14}"; shift 2 ;;
            --no-color)          export ASH_FLAG_NO_COLOR=1; shift ;;
            --json)              export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)           theme::preview::help; return 0 ;;
            -*)                  ash_log_error "Unknown option: $1"; theme::preview::help; return 2 ;;
            *)                   want="$1"; shift ;;
        esac
    done

    [[ -n "$want" ]] || { ash_log_error "Which theme?"; theme::preview::help; return 2; }
    [[ "$width" =~ ^[0-9]+$ ]] || width=14

    local file
    if ! file="$(theme::resolve "$want")"; then
        ash_log_error "No such theme: $want"
        return 1
    fi

    local -A pal=()
    theme::load "$file" pal

    local slug name variant family seed
    slug="$(jq -r '.slug // empty' "$file" 2>/dev/null)"
    name="$(jq -r '.name // empty' "$file" 2>/dev/null)"
    variant="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"
    family="$(jq -r '.family // "other"' "$file" 2>/dev/null)"
    seed="$(jq -r '.seed // empty' "$file" 2>/dev/null)"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        local colors_json
        colors_json="$(ash_palette_render_json pal 2>/dev/null || printf '{}')"
        jq -n --arg slug "$slug" --arg name "$name" --arg variant "$variant" \
              --arg family "$family" --arg seed "$seed" --arg file "$file" \
              --argjson colors "$colors_json" \
              '{slug: $slug, name: $name, variant: $variant, family: $family,
                seed: $seed, file: $file, colors: $colors}'
        return 0
    fi

    ash_banner "🎨 ${name:-$slug}" "${slug} · ${variant} · ${family}" 80

    local group slot hex
    local -a group_slots=()
    for group in "Surfaces:crust mantle base surface overlay" \
                 "Foregrounds:text subtext" \
                 "Accents:accent mint sky gold rose violet"; do
        printf '\n  %s%s%s\n' "${BOLD}${ASH_PRIMARY}" "${group%%:*}" "${RST}"
        # IFS is \n\t here, inherited from the dispatcher, so an unquoted word
        # list would not split on spaces. Set IFS for this read only.
        IFS=' ' read -r -a group_slots <<<"${group#*:}"
        for slot in "${group_slots[@]}"; do
            hex="${pal[$slot]:-}"
            if [[ -z "$hex" ]]; then
                printf '    %-9s %s%s%s\n' "$slot" "${ASH_MUTED}" "— not set —" "${RST}"
                continue
            fi
            printf '    %-9s %s  %s\n' "$slot" "$hex" "$(theme::swatch "$hex" "$width")"
        done
    done

    if (( contrast )); then
        if declare -f ash_contrast_report >/dev/null 2>&1; then
            printf '\n'
            ash_contrast_report pal 2>/dev/null || true
        elif declare -f ash_wcag_check_palette >/dev/null 2>&1; then
            printf '\n'
            ash_wcag_check_palette pal || true
        fi
    elif declare -f ash_wcag_check_palette >/dev/null 2>&1 && [[ "${ASH_FLAG_NO_COLOR:-0}" -ne 1 ]]; then
        # One-line summary is worth more than a full report here; `--contrast`
        # exists for the full table.
        local report fails
        report="$(ash_wcag_check_palette pal --quiet 2>/dev/null || true)"
        if [[ "$report" =~ ^[0-9]+$ ]] && (( report > 0 )); then
            printf '\n  %sℹ %s under the 4.5:1 minimum — use %s--contrast%s to see which%s\n' \
                "${ASH_MUTED}" "$(theme::plural "$report" "pair")" \
                "${ASH_ACCENT}" "${ASH_MUTED}" "${RST}"
        fi
    fi

    (( gradient )) && _theme_preview_gradient pal 64
    (( mock ))     && _theme_preview_mock pal

    printf '  %s%s%s\n\n' "${ASH_MUTED}" "Apply it with: ash theme apply ${slug:-$want}" "${RST}"
}
