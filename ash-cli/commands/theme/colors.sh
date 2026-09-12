#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — colors.sh                                                       ║
# ║  Show one palette: every slot, its hex, and its contrast summary             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

theme::colors::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme colors${RST} <name> [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--json${RST}      Emit the palette as JSON
  ${ASH_MUTED}--kv${RST}        Emit key=value lines
  ${ASH_MUTED}--no-contrast${RST}  Skip the contrast summary
EOF
}

theme::colors() {
    local want="" json=0 kv=0 contrast=1
    [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]] && json=1

    while (( $# )); do
        case "$1" in
            --json)        json=1; shift ;;
            --kv)          kv=1; shift ;;
            --no-contrast) contrast=0; shift ;;
            --help|-h)     theme::colors::help; return 0 ;;
            *)             want="${want:-$1}"; shift ;;
        esac
    done

    [[ -n "$want" ]] || { theme::colors::help >&2; return 2; }

    local file
    file="$(theme::resolve "$want")" || {
        ash_log_error "No such theme: ${want}"
        ash_log_info  "Run 'ash theme list' to see the catalogue"
        return 1
    }

    local -A pal=()
    theme::load "$file" pal

    # Machine-readable forms come first and print nothing else, so the output
    # stays parseable.
    if (( json )); then
        ash_palette_render_json pal
        return 0
    fi
    if (( kv )); then
        ash_palette_render_kv pal
        return 0
    fi

    local name slug variant family seed
    name="$(jq -r '.name    // "?"' "$file" 2>/dev/null)"
    slug="$(jq -r '.slug    // "?"' "$file" 2>/dev/null)"
    variant="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"
    family="$(jq -r '.family  // "other"' "$file" 2>/dev/null)"
    seed="$(jq -r '.seed    // ""' "$file" 2>/dev/null)"

    ash_banner "🎨 ${name}" "${slug} · ${variant} · ${family}" "80"

    local slot hex
    printf '\n'
    for slot in "${THEME_SLOT_ORDER[@]}"; do
        hex="${pal[$slot]:-}"
        [[ -n "$hex" ]] || continue
        printf '    %-10s %s%s%s  %s\n' \
            "$slot" "${ASH_MUTED}" "$hex" "${RST}" "$(theme::swatch "$hex" 16)"
    done

    if (( contrast )) && declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local -A copy=()
        for slot in "${!pal[@]}"; do copy["$slot"]="${pal[$slot]}"; done

        # --quiet returns the failure count WITHOUT printing a report. Without
        # it the report text is captured instead of the number.
        local fails
        set +e
        fails="$(ash_wcag_check_palette copy --quiet 2>/dev/null)"
        set -e
        [[ "$fails" =~ ^[0-9]+$ ]] || fails=0

        printf '\n    %s%s%s\n' "${BOLD}${ASH_PRIMARY}" "CONTRAST" "${RST}"
        if (( fails == 0 )); then
            printf '    %s%s%s %s\n' "$ASH_SUCCESS" "${ICO_SUCCESS}" "${RST}" \
                "All WCAG checks pass"
        else
            printf '    %s%s%s %s\n' "$ASH_ERROR" "${ICO_ERROR}" "${RST}" \
                "$(theme::plural "$fails" check) failing"
            printf '    %s↳ ash theme wcag %s --fix%s\n' "${ASH_MUTED}" "$slug" "${RST}"
        fi
    fi

    printf '\n    %s%s%s\n\n' "${ASH_MUTED}" "$file" "${RST}"
}
