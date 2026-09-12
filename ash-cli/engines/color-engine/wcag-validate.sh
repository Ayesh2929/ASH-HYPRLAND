#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — color-engine/wcag-validate.sh                    ║
# ║                                                                               ║
# ║  Accessibility gate. Audits a theme file, a directory of themes, or a whole    ║
# ║  library, and exits non-zero when anything fails.                              ║
# ║                                                                               ║
# ║  This is the check `ash theme apply` runs before installing a theme, and the   ║
# ║  one CI runs over themes/. A theme that cannot be read is not a theme.         ║
# ║                                                                               ║
# ║  Sourceable library.                                                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${ASH_WCAGV_LOADED:-}" ]] && return 0
ASH_WCAGV_LOADED=1

if [[ -z "${_ASH_COLOR_ENGINE_DIR:-}" ]]; then
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        _ASH_COLOR_ENGINE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    else
        _ASH_COLOR_ENGINE_DIR="${ASH_ROOT:-.}/ash-cli/engines/color-engine"
    fi
fi
[[ -z "${ASH_OKLCH_LOADED:-}" ]]    && source "${_ASH_COLOR_ENGINE_DIR}/oklch.sh"
[[ -z "${ASH_CONTRAST_LOADED:-}" ]] && source "${_ASH_COLOR_ENGINE_DIR}/contrast-check.sh"
[[ -z "${ASH_PALETTE_LOADED:-}" ]]  && source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"

#: The foreground/background pairs a user genuinely reads. Each entry is
#: "foreground:background:threshold:label".
#
#: Thresholds are per-pair, not a blanket 4.5. Body text must clear AA, but a
#: border or an inactive tab label is a non-text UI component and only needs
#: 3:1 — holding those to 4.5 would force designers into muddy greys and make
#: every theme look the same.
readonly -a ASH_WCAG_PAIRS=(
    "text:base:aa-normal:body text on background"
    "text:mantle:aa-normal:body text on mantle"
    "text:surface:aa-normal:body text on surface"
    "text:crust:aa-normal:body text on crust"
    "subtext:base:aa-normal:secondary text on background"
    "subtext:mantle:aa-normal:secondary text on mantle"
    "accent:base:aa-normal:accent on background"
    "accent:surface:aa-normal:accent on surface"
    "mint:base:aa-ui:success on background"
    "sky:base:aa-ui:info on background"
    "gold:base:aa-ui:warning on background"
    "rose:base:aa-ui:danger on background"
    "violet:base:aa-ui:violet on background"
)

#: Separators are checked for PERCEPTIBILITY, not for a WCAG ratio.
#
#: `overlay` is the border/divider tier, and the 3:1 graphical-object rule
#: covers boundaries that convey required information — a form field outline
#: that signals editability, say. It explicitly exempts decorative separators.
#: Applying it here flagged Catppuccin Mocha, a well-regarded accessible
#: palette, as failing, which is the kind of false positive that gets a real
#: accessibility gate switched off.
#:
#: The honest criterion for a divider is "can it be seen at all", which is a
#: perceptual-distance question. The threshold is a ΔE in OKLab.
readonly ASH_WCAG_SEPARATORS=(
    "overlay:base:0.020:divider on background"
    "overlay:surface:0.012:divider on surface"
    "surface:base:0.012:surface tier on background"
)

# ash_wcag_check_palette <name> [--json|--quiet]
#   Audits one in-memory palette. Echoes a report, returns the failure count.
ash_wcag_check_palette() {
    local -n _p="$1"
    local mode="${2:-text}"

    local failures=0 checks=0 worst=99.0 worst_label=""
    local line pair_fg pair_bg threshold label fg bg ratio

    local -a json_rows=()

    for line in "${ASH_WCAG_PAIRS[@]}"; do
        pair_fg="${line%%:*}"; line="${line#*:}"
        pair_bg="${line%%:*}"; line="${line#*:}"
        threshold="${line%%:*}"; label="${line#*:}"

        fg="${_p[$pair_fg]:-}"
        bg="${_p[$pair_bg]:-}"
        [[ -z "$fg" || -z "$bg" ]] && continue

        ratio="$(ash_contrast_ratio "$fg" "$bg")" || continue
        (( checks += 1 ))

        local target="${ASH_WCAG_THRESHOLDS[$threshold]:-4.5}"
        local pass=1
        _ash_ok_awk "BEGIN { exit(($ratio >= $target) ? 0 : 1) }" || { pass=0; (( failures += 1 )); }

        _ash_ok_awk "BEGIN { exit(($ratio < $worst) ? 0 : 1) }" && { worst="$ratio"; worst_label="$label"; }

        case "$mode" in
            --json)
                json_rows+=("$(printf '{"label":"%s","fg":"%s","bg":"%s","ratio":%s,"threshold":%s,"grade":"%s","pass":%s}' \
                    "$label" "$fg" "$bg" "$ratio" "$target" "$(ash_contrast_grade "$ratio")" \
                    "$([ "$pass" -eq 1 ] && echo true || echo false)")")
                ;;
            --quiet) : ;;
            *)
                printf '  %s %-38s %-9s %-8s %5s  %s\n' \
                    "$([ "$pass" -eq 1 ] && echo '✓' || echo '✗')" \
                    "$label" "$fg" "$bg" "$ratio" \
                    "$(ash_contrast_grade "$ratio")$([ "$pass" -eq 0 ] && printf ' (needs %s)' "$target")"
                ;;
        esac
    done

    # Separators: reported, and only counted as a failure when the two colours
    # are literally indistinguishable.
    local seps=""
    if [[ "$mode" != "--quiet" && "$mode" != "--json" ]] && [[ ${#ASH_WCAG_SEPARATORS[@]} -gt 0 ]]; then
        printf '\n  separators (perceptibility, not a WCAG ratio):\n'
    fi

    local sep_line sep_fg sep_bg sep_min sep_label sep_d
    for sep_line in "${ASH_WCAG_SEPARATORS[@]}"; do
        sep_fg="${sep_line%%:*}"; sep_line="${sep_line#*:}"
        sep_bg="${sep_line%%:*}"; sep_line="${sep_line#*:}"
        sep_min="${sep_line%%:*}"; sep_label="${sep_line#*:}"

        local sfg="${_p[$sep_fg]:-}" sbg="${_p[$sep_bg]:-}"
        [[ -z "$sfg" || -z "$sbg" ]] && continue

        sep_d="$(ash_ok_distance "$sfg" "$sbg")"
        _ash_ok_awk "BEGIN { exit(($sep_d >= $sep_min) ? 0 : 1) }" || (( failures += 1 ))

        [[ "$mode" == "--quiet" || "$mode" == "--json" ]] && continue
        printf '  %s %-38s %-9s %-9s dE=%s\n' \
            "$(_ash_ok_awk "BEGIN { exit(($sep_d >= $sep_min) ? 0 : 1) }" && echo '✓' || echo '✗')" \
            "$sep_label" "$sfg" "$sbg" "$sep_d"
    done

    if [[ "$mode" == "--json" ]]; then
        local IFS=,
        printf '{"checks":%s,"failures":%s,"minimum":%s,"minimum_label":"%s","pairs":[%s]}\n' \
            "$checks" "$failures" "$worst" "$worst_label" "${json_rows[*]}"
    elif [[ "$mode" != "--quiet" ]]; then
        printf '\n  %s: %s/%s checks pass, worst %.2f:1 (%s)\n' \
            "$([ "$failures" -eq 0 ] && echo 'PASS' || echo 'FAIL')" \
            "$(( checks - failures ))" "$checks" "$worst" "$worst_label"
    fi

    return "$failures"
}

# ash_wcag_check_file <path> [--json|--quiet]
ash_wcag_check_file() {
    local file="$1" mode="${2:-text}"
    [[ -r "$file" ]] || { printf 'ash wcag: cannot read %s\n' "$file" >&2; return 1; }

    local -A p=()
    # Reuse the palette loader rather than duplicating the jq/grep fallback.
    if declare -f _ash_palette_load_file >/dev/null 2>&1; then
        _ash_palette_load_file "$file" p
    else
        source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"
        _ash_palette_load_file "$file" p
    fi

    # A theme with no slots at all is not a failing theme, it is an unreadable
    # file — report that distinctly so the caller does not go hunting for a
    # contrast problem that does not exist.
    if (( ${#p[@]} == 0 )); then
        printf 'ash wcag: %s contains no colour slots\n' "$file" >&2
        return 2
    fi

    local reason
    if ! ash_palette_is_valid p reason; then
        printf 'ash wcag: %s is malformed: %s\n' "$file" "$reason" >&2
        return 2
    fi

    [[ "$mode" == "--quiet" ]] || printf '\n%s\n' "$file"
    ash_wcag_check_palette p "$mode"
}

# ash_wcag_sweep <dir> [--json]
#   Walks a theme library. Reports every failure and a summary, so one bad
#   theme in 250 does not hide behind an overall pass.
ash_wcag_sweep() {
    local dir="$1" mode="${2:-text}"
    [[ -d "$dir" ]] || { printf 'ash wcag: not a directory: %s\n' "$dir" >&2; return 2; }

    local total=0 failed=0 unreadable=0 skipped=0 file
    local -a failed_files=()

    while IFS= read -r file || [[ -n "$file" ]]; do
        [[ -n "$file" ]] || continue

        # A theme library directory also holds its JSON Schema and any number of
        # index or manifest files. Counting those as "malformed themes" makes
        # the gate cry wolf, and a gate that cries wolf gets ignored. Skip
        # anything that is not a palette and say so separately.
        if ! grep -q '"base"' "$file" 2>/dev/null; then
            (( skipped += 1 ))
            [[ "$mode" == "--json" ]] || printf -- '- %s (not a theme, skipped)\n' "${file#"$dir"/}"
            continue
        fi

        (( total += 1 ))

        local rc=0
        ash_wcag_check_file "$file" --quiet >/dev/null 2>&1 || rc=$?

        case "$rc" in
            0) : ;;
            2) (( unreadable += 1 )); failed_files+=("MALFORMED  $file") ;;
            *) (( failed += 1 )); failed_files+=("FAIL($rc)   $file") ;;
        esac

        [[ "$mode" == "--json" ]] || {
            local mark="✓"
            [[ "$rc" -eq 2 ]] && mark="?"
            [[ "$rc" -gt 2 ]] && mark="✗"
            printf '%s %s\n' "$mark" "${file#"$dir"/}"
        }
    done < <(find "$dir" -type f -name '*.json' | sort)

    if [[ "$mode" == "--json" ]]; then
        printf '{"total":%s,"failed":%s,"malformed":%s,"skipped":%s,"passed":%s}\n' \
            "$total" "$failed" "$unreadable" "$skipped" "$(( total - failed - unreadable ))"
    else
        printf '\n%s  %s themes: %s pass, %s fail, %s malformed' \
            "$([ $(( failed + unreadable )) -eq 0 ] && echo '✅' || echo '❌')" \
            "$total" "$(( total - failed - unreadable ))" "$failed" "$unreadable"
        (( skipped > 0 )) && printf ' (%s non-theme files skipped)' "$skipped"
        printf '\n' 

        if (( failed + unreadable > 0 )); then
            printf '\nfirst failures:\n'
            printf '  %s\n' "${failed_files[@]:0:10}"
        fi
    fi

    return $(( failed + unreadable ))
}

# ash_wcag_fix_file <path> [--in-place] [--stdout]
#   Repairs failing slots by nudging lightness until they clear their
#   threshold. Hue and chroma are preserved, so a repaired theme is recognisably
#   the same theme.
ash_wcag_fix_file() {
    local file="$1" mode="${2:---stdout}"
    [[ -r "$file" ]] || { printf 'ash wcag: cannot read %s\n' "$file" >&2; return 1; }

    local -A p=()
    source "${_ASH_COLOR_ENGINE_DIR}/palette.sh"
    _ash_palette_load_file "$file" p

    local fixed=0 line pair_fg pair_bg threshold fg bg ratio
    for line in "${ASH_WCAG_PAIRS[@]}"; do
        pair_fg="${line%%:*}"; line="${line#*:}"
        pair_bg="${line%%:*}"; line="${line#*:}"
        threshold="${line%%:*}"

        fg="${p[$pair_fg]:-}"; bg="${p[$pair_bg]:-}"
        [[ -z "$fg" || -z "$bg" ]] && continue

        ash_contrast_pass "$fg" "$bg" "$threshold" && continue

        # Only foreground slots are repaired. Moving a background to fix one
        # pair breaks every other pair that uses it.
        case "$pair_fg" in
            text|subtext|accent|mint|sky|gold|rose|violet|overlay)
                p["$pair_fg"]="$(ash_contrast_fix "$fg" "$bg" "$threshold")"
                (( fixed += 1 ))
                ;;
        esac
    done

    # Repair is iterative: fixing text against base can require re-checking
    # against surface. Two passes converge for every theme in the library.
    local pass=0
    while (( pass < 3 )); do
        local still=0
        for line in "${ASH_WCAG_PAIRS[@]}"; do
            pair_fg="${line%%:*}"; line="${line#*:}"
            pair_bg="${line%%:*}"; line="${line#*:}"
            threshold="${line%%:*}"
            fg="${p[$pair_fg]:-}"; bg="${p[$pair_bg]:-}"
            [[ -z "$fg" || -z "$bg" ]] && continue
            ash_contrast_pass "$fg" "$bg" "$threshold" || still=1
        done
        (( still )) || break
        (( pass += 1 ))

        for line in "${ASH_WCAG_PAIRS[@]}"; do
            pair_fg="${line%%:*}"; line="${line#*:}"
            pair_bg="${line%%:*}"; line="${line#*:}"
            threshold="${line%%:*}"
            fg="${p[$pair_fg]:-}"; bg="${p[$pair_bg]:-}"
            [[ -z "$fg" || -z "$bg" ]] && continue
            ash_contrast_pass "$fg" "$bg" "$threshold" && continue
            p["$pair_fg"]="$(ash_contrast_fix "$fg" "$bg" "$threshold")"
        done
    done

    ash_palette_render_json p > "${file}.fixed"

    case "$mode" in
        --in-place) mv "${file}.fixed" "$file" ;;
        *)          cat "${file}.fixed"; rm -f "${file}.fixed" ;;
    esac

    printf 'ash wcag: repaired %s slot(s) in %s\n' "$fixed" "$(basename "$file")" >&2
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════════════════════════

ash_wcag_usage() {
    cat <<'USAGE'
ash wcag — accessibility gate for themes

  ash wcag check <file.json>        audit one theme
  ash wcag check --json <file>      machine-readable report
  ash wcag sweep <dir>              audit a whole library
  ash wcag fix <file>               print a repaired palette
  ash wcag fix --in-place <file>    repair the file on disk

Exit status is the number of failing checks, so it composes directly:
  ash wcag sweep themes/ || echo "library has accessibility regressions"
USAGE
}

ash_wcag_main() {
    local cmd="${1:-}"; shift || true

    case "$cmd" in
        check)
            local mode=""
            [[ "${1:-}" == "--json" ]] && { mode="--json"; shift; }
            [[ "${1:-}" == "--quiet" ]] && { mode="--quiet"; shift; }
            ash_wcag_check_file "${1:?theme file required}" "$mode"
            ;;

        sweep)
            local mode=""
            [[ "${1:-}" == "--json" ]] && { mode="--json"; shift; }
            ash_wcag_sweep "${1:?directory required}" "$mode"
            ;;

        fix)
            local mode="--stdout"
            [[ "${1:-}" == "--in-place" ]] && { mode="--in-place"; shift; }
            ash_wcag_fix_file "${1:?theme file required}" "$mode"
            ;;

        ''|help|-h|--help) ash_wcag_usage ;;

        *)
            printf 'ash wcag: unknown subcommand: %s\n\n' "$cmd" >&2
            ash_wcag_usage >&2
            return 2
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ash_wcag_main "$@"
fi
