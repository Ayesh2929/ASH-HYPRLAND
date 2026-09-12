#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — validate.sh                                                      ║
# ║  Check theme files against the schema, slot and contrast rules                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::validate::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme validate${RST} <theme|file>…
  ${ASH_ACCENT}ash theme validate${RST} --all

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Four independent checks, reported separately because they fail for different
  reasons and only the first is fatal:

    ${ASH_MUTED}shape${RST}     valid JSON, and the metadata the catalogue needs
    ${ASH_MUTED}slots${RST}     all 13 slots present and each a hex colour
    ${ASH_MUTED}values${RST}    slots that are distinct and in a sane lightness range
    ${ASH_MUTED}contrast${RST}  WCAG pairs, reported as a warning

  A theme that fails shape or slots cannot be applied. A theme that fails only
  contrast still works — it is just harder to read.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--all, -a${RST}        Validate every theme in the catalogue
  ${ASH_MUTED}--strict${RST}         Treat contrast failures as fatal
  ${ASH_MUTED}--quiet, -q${RST}      Only report failures
  ${ASH_MUTED}--json${RST}           Machine-readable output

${BOLD}${ASH_PRIMARY}EXIT STATUS${RST}
  ${ASH_MUTED}0${RST}  valid (or valid with warnings, unless --strict)
  ${ASH_MUTED}1${RST}  invalid

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme validate my-theme${RST}
  ${ASH_MUTED}ash theme validate --all --strict${RST}
EOF
}

# Per-file validation. Prints nothing in quiet mode unless something is wrong;
# appends one JSON object per file when asked.
theme::validate::one() {
    set +e
    local file="$1" json="$2" quiet="$3" strict="$4"
    local -a problems=() warnings=()

    # ── shape ────────────────────────────────────────────────────────────────
    if ! jq -e 'type == "object"' "$file" >/dev/null 2>&1; then
        problems+=("not a JSON object")
    else
        local miss=""
        local k
        for k in slug name variant; do
            [[ -n "$(jq -r --arg k "$k" '.[$k] // empty' "$file" 2>/dev/null)" ]] || miss+=" $k"
        done
        [[ -n "$miss" ]] && warnings+=("missing metadata:$miss")
        local v
        v="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"
        case "$v" in dark|light|neon|custom) : ;; *) problems+=("variant '$v' is not dark/light/neon/custom") ;; esac
    fi

    # ── slots ────────────────────────────────────────────────────────────────
    local -A pal=()
    theme::load "$file" pal

    local slot
    local -a absent=() badhex=()
    for slot in "${THEME_SLOT_ORDER[@]}"; do
        local val="${pal[$slot]:-}"
        if [[ -z "$val" ]]; then absent+=("$slot"); continue; fi
        [[ "$val" =~ ^#[0-9a-fA-F]{6}$ ]] || badhex+=("$slot")
    done
    (( ${#absent[@]} )) && problems+=("missing slots: ${absent[*]}")
    (( ${#badhex[@]} )) && problems+=("not hex: ${badhex[*]}")

    # ── values ───────────────────────────────────────────────────────────────
    # Identical surfaces collapse the interface into one flat colour; identical
    # accents make the four semantic colours indistinguishable.
    if (( ${#absent[@]} == 0 && ${#badhex[@]} == 0 )); then
        local a b
        for a in base surface; do
            for b in mantle crust; do
                [[ "${pal[$a]}" == "${pal[$b]}" ]] && warnings+=("$a and $b are identical (${pal[$a]})")
            done
        done

        local -A seen=()
        for slot in accent mint sky gold rose violet; do
            if [[ -n "${seen[${pal[$slot],,}]:-}" ]]; then
                warnings+=("$slot duplicates ${seen[${pal[$slot],,}]} (${pal[$slot]})")
            else
                seen["${pal[$slot],,}"]="$slot"
            fi
        done

        # A background that is lighter than the text it must sit behind is a
        # light theme wearing a dark variant's label.
        if declare -f ash_ok_l >/dev/null 2>&1; then
            local lb lt
            lb="$(ash_ok_l "${pal[base]}" 2>/dev/null || printf '')"
            lt="$(ash_ok_l "${pal[text]}" 2>/dev/null || printf '')"
            if [[ -n "$lb" && -n "$lt" ]]; then
                local lv
                lv="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"
                if awk -v b="$lb" -v t="$lt" 'BEGIN { exit !(b > t) }'; then
                    [[ "$lv" == "light" ]] || warnings+=("base is lighter than text but variant is '$lv'")
                else
                    [[ "$lv" == "light" ]] && warnings+=("variant is 'light' but base is darker than text")
                fi
            fi
        fi
    fi

    # ── contrast ─────────────────────────────────────────────────────────────
    local fails=0
    if (( ${#absent[@]} == 0 )) && declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local r
        r="$(ash_wcag_check_palette pal --quiet 2>/dev/null || true)"
        [[ "$r" =~ ^[0-9]+$ ]] && fails="$r"
        if (( fails > 0 )); then
            if (( strict )); then
                problems+=("$fails contrast pair(s) below threshold")
            else
                warnings+=("$fails contrast pair(s) below threshold")
            fi
        fi
    fi

    local name
    name="$(jq -r '.name // empty' "$file" 2>/dev/null)"
    [[ -n "$name" ]] || name="$(basename "$file" .json)"

    if [[ "$json" == "1" ]]; then
        printf '%s\n' "$(jq -cn --arg file "$file" --arg name "$name" \
            --argjson problems "$(printf '%s\n' "${problems[@]:-}" | jq -Rn '[inputs|select(length>0)]')" \
            --argjson warnings "$(printf '%s\n' "${warnings[@]:-}" | jq -Rn '[inputs|select(length>0)]')" \
            --argjson contrast "$fails" \
            '{file: $file, name: $name, ok: (($problems|length)==0),
              errors: $problems, warnings: $warnings, contrast_failures: $contrast}')"
    elif (( ${#problems[@]} )) || { (( ${#warnings[@]} )) && [[ "$quiet" != "1" ]]; }; then
        if (( ${#problems[@]} )); then
            printf '  %s✗%s %-28s %s%s%s\n' "${ASH_ERROR}" "${RST}" "$name" "${ASH_ERROR}" "${problems[*]}" "${RST}"
        else
            printf '  %s⚠%s %-28s %s%s%s\n' "${ASH_WARNING:-$ASH_MUTED}" "${RST}" "$name" "${ASH_MUTED}" "${warnings[*]}" "${RST}"
        fi
    elif [[ "$quiet" != "1" ]]; then
        printf '  %s✓%s %-28s %s%s%s\n' "${ASH_SUCCESS}" "${RST}" "$name" "${ASH_MUTED}" "$(basename "$file")" "${RST}"
    fi

    (( ${#problems[@]} == 0 ))
}

theme::validate() {
    local all=0 strict=0 quiet=0 json=0
    local -a targets=()

    while (( $# )); do
        case "$1" in
            --all|-a)     all=1; shift ;;
            --strict)     strict=1; shift ;;
            --quiet|-q)   quiet=1; shift ;;
            --json)       json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)    theme::validate::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::validate::help; return 2 ;;
            *)            targets+=("$1"); shift ;;
        esac
    done

    if (( all )); then
        local f
        while IFS= read -r f; do targets+=("$f"); done < <(theme::files)
    elif (( ${#targets[@]} == 0 )); then
        ash_log_error "Nothing to validate."
        printf '  %sPass a theme name, a file path, or --all.%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        theme::validate::help
        return 2
    fi

    local -a files=()
    local t
    for t in "${targets[@]}"; do
        local f
        if f="$(theme::resolve "$t")"; then
            files+=("$f")
        else
            ash_log_error "No such theme or file: $t"
        fi
    done

    (( ${#files[@]} )) || return 1

    [[ "$json" == "1" ]] || ash_banner "✅ THEME VALIDATION" "$(theme::plural "${#files[@]}" theme)" 80

    local ok=0 bad=0 warn=0 f
    for f in "${files[@]}"; do
        if theme::validate::one "$f" "$json" "$quiet" "$strict"; then
            (( ok++ )) || true
        else
            (( bad++ )) || true
        fi
    done

    if [[ "$json" == "1" ]]; then return $(( bad > 0 ? 1 : 0 )); fi

    printf '\n  %s%s ok%s' "${ASH_SUCCESS}" "$ok" "${RST}"
    (( bad ))  && printf '  %s%s invalid%s' "${ASH_ERROR}" "$bad" "${RST}"
    printf '\n\n'
    (( bad > 0 )) && return 1
    return 0
}
