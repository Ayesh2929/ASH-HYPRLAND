#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — list.sh                                                         ║
# ║  Browse the catalogue, filtered and optionally as JSON                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::list::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme list${RST} [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--family, -f NAME${RST}    Only this family (nord, catppuccin, generated…)
  ${ASH_MUTED}--variant, -v dark|light${RST}
  ${ASH_MUTED}--user${RST}              Only themes you created or imported
  ${ASH_MUTED}--json${RST}              Machine-readable output
  ${ASH_MUTED}--no-color${RST}          No seed swatches
EOF
}

theme::list() {
    local family="" variant="" user_only=0 json=0

    # --json is consumed by the ash dispatcher as a global flag (it sets
    # ASH_FLAG_JSON_OUTPUT and removes it from argv), so the subcommand only
    # sees it when called directly. Both routes have to be honoured.
    [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]] && json=1

    while (( $# )); do
        case "$1" in
            --family|-f)  family="${2:-}";  shift 2 ;;
            --variant|-v) variant="${2:-}"; shift 2 ;;
            --user|-u)    user_only=1; shift ;;
            --json)       json=1; shift ;;
            --no-color)   ASH_FLAG_NO_COLOR=1; shift ;;
            --help|-h)    theme::list::help; return 0 ;;
            *) printf 'ash theme list: unknown option %s\n' "$1" >&2; return 2 ;;
        esac
    done

    local rows
    rows="$(theme::index)"

    if (( user_only )); then
        rows="$(awk -F'\t' -v d="$THEME_USER_DIR" 'index($6, d) == 1' <<<"$rows")"
    fi
    [[ -n "$family"  ]] && rows="$(awk -F'\t' -v f="$family"  '$4 == f' <<<"$rows")"
    [[ -n "$variant" ]] && rows="$(awk -F'\t' -v v="$variant" '$3 == v' <<<"$rows")"

    local total
    total="$(grep -c . <<<"$rows" 2>/dev/null || printf 0)"

    if [[ "$total" == "0" ]]; then
        ash_log_error "No themes match those filters"
        ash_log_info  "Built-in catalogue: ${THEME_CATALOGUE_DIR}"
        return 1
    fi

    if (( json )); then
        jq -n --argjson n "$total" --arg fam "$family" --arg var "$variant" \
              --arg json_rows "$rows" \
              '{total: $n, family: $fam, variant: $var,
                themes: ($json_rows | split("\n") | map(select(length > 0)
                        | split("\t") | {slug: .[0], name: .[1], variant: .[2],
                                           family: .[3], seed: .[4]}))}'
        return 0
    fi

    ash_banner "🎨 THEME CATALOGUE" \
        "$(theme::plural "$total" theme)" "80"

    local n=0 last_family="" slug name var family_c seed seed_hex
    while IFS=$'\t' read -r slug name var family_c seed _path; do
        [[ -n "$slug" ]] || continue
        if [[ "$family_c" != "$last_family" ]]; then
            printf '\n  %s%s%s\n' "${BOLD}${ASH_PRIMARY}" "$family_c" "${RST}"
            last_family="$family_c"
        fi
        seed_hex="$(ash_ok_normalize_hex "${seed:-#000000}" 2>/dev/null || printf '#000000')"
        printf '    %s %-24s %s%-20s%s %s%s%s\n' \
            "$(theme::swatch "$seed_hex" 2)" \
            "$slug" \
            "${ASH_MUTED}" "$name" "${RST}" \
            "${ASH_MUTED}" "$var" "${RST}"
        (( n++ )) || true
    done <<<"$rows"

    local fam_n
    fam_n="$(awk -F'\t' 'NF { seen[$4] = 1 } END { print length(seen) + 0 }' <<<"$rows")"
    printf '\n  %s%s%s\n\n' "${ASH_MUTED}" \
        "$(theme::plural "$n" theme) across $(theme::plural "$fam_n" family)" "${RST}"
}
