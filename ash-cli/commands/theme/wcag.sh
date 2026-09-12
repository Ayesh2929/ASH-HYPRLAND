#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — wcag.sh                                                          ║
# ║  Contrast validation: one theme, or the whole catalogue                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.
#
# Also reachable as `ash wcag`, which is why the entry point is a plain
# theme::wcag rather than living inside the dispatcher.

theme::wcag::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme wcag${RST} [<theme>] [options]
  ${ASH_ACCENT}ash wcag${RST} [<theme>] [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Measures every foreground/background pair a theme defines against WCAG 2.2 —
  4.5:1 for body text, 3:1 for large text and UI boundaries — and the three
  decorative separators against an OKLab ΔE threshold, because a 3:1 ratio is
  the wrong test for a separator that only has to be *visible*.

  With no argument this sweeps the whole catalogue. Nothing is written unless
  you ask for --fix.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--sweep, -s${RST}     Check every theme (the default with no argument)
  ${ASH_MUTED}--fix${RST}           Repair failing slots in place
  ${ASH_MUTED}--json${RST}          Machine-readable output
  ${ASH_MUTED}--quiet, -q${RST}     Only the summary line

${BOLD}${ASH_PRIMARY}EXIT STATUS${RST}
  ${ASH_MUTED}0${RST}   everything passes
  ${ASH_MUTED}1${RST}   at least one pair fails
  ${ASH_MUTED}2${RST}   a theme file could not be read

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme wcag nord${RST}
  ${ASH_MUTED}ash wcag --sweep${RST}
  ${ASH_MUTED}ash theme wcag my-theme --fix${RST}
EOF
}

# Repair every theme the catalogue sweep flags.
#
# The engine's sweep only reports, so the repair loop lives here: sweep with
# --json, pull out the files that failed, repair each, then re-sweep so the
# summary reflects the state on disk rather than the state we hoped for.
theme::wcag::fix_catalogue() {
    local json="${1:-0}"

    local report
    report="$(ash_wcag_main sweep --json "$THEME_CATALOGUE_DIR" 2>/dev/null)" || true

    local -a failing=()
    mapfile -t failing < <(
        jq -r '(.themes // .results // .files // [])
               | .[]
               | select((.pass // .ok // .passed // true) | not)
               | (.file // .path // empty)' <<<"$report" 2>/dev/null
    ) || true

    # Fall back to a filename scan if the report shape is unexpected.
    if (( ${#failing[@]} == 0 )); then
        mapfile -t failing < <(
            jq -r '.. | objects | select(has("file") and ((.pass // true) | not)) | .file' \
                <<<"$report" 2>/dev/null
        ) || true
    fi

    if (( ${#failing[@]} == 0 )); then
        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
            jq -n '{repaired: 0, failed: 0, files: []}'
        else
            printf '  %s✅ Every theme in the catalogue already passes — nothing to repair.%s\n\n' \
                "${ASH_SUCCESS}" "${RST}"
        fi
        return 0
    fi

    local -a repaired=() broke=()
    local f
    for f in "${failing[@]}"; do
        [[ -f "$f" ]] || continue
        local before after
        before="$(jq -cS '.colors // .' "$f" 2>/dev/null || printf '')"
        if ash_wcag_fix_file "$f" --in-place >/dev/null 2>&1; then
            after="$(jq -cS '.colors // .' "$f" 2>/dev/null || printf '')"
            [[ "$before" != "$after" ]] && repaired+=("$f") || true
        else
            broke+=("$f")
        fi
    done

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        printf '%s\n' "${repaired[@]:-}" | jq -Rs --argjson n "${#repaired[@]}" \
            --argjson bad "${#broke[@]}" \
            '{repaired: $n, failed: $bad, files: (split("\n") | map(select(length>0)))}'
        return 0
    fi

    printf '\n  %s✅ Repaired %s%s\n' "${ASH_SUCCESS}" \
        "$(theme::plural "${#repaired[@]}" theme)" "${RST}"
    (( ${#broke[@]} )) && printf '  %s⚠  %s could not be repaired%s\n' \
        "${ASH_WARNING:-$ASH_MUTED}" "$(theme::plural "${#broke[@]}" theme)" "${RST}"
    printf '\n'

    # Show the state the user is actually left in.
    ash_wcag_main sweep "$THEME_CATALOGUE_DIR" 2>/dev/null | tail -1
}

theme::wcag() {
    local want="" sweep=0 json=0 fix=0 quiet=0
    local -a passthrough=()

    while (( $# )); do
        case "$1" in
            --sweep|-s)   sweep=1; shift ;;
            --fix)        fix=1; shift ;;
            --json)       json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            --quiet|-q)   quiet=1; shift ;;
            -h|--help)    theme::wcag::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::wcag::help; return 2 ;;
            *)            want="$1"; shift ;;
        esac
    done

    if ! declare -f ash_wcag_main >/dev/null 2>&1; then
        ash_log_error "The contrast engine is not loaded (wcag-validate.sh)"
        return 1
    fi

    # ── Whole catalogue ───────────────────────────────────────────────────────
    if (( sweep )) || [[ -z "$want" ]]; then
        # ash_wcag_main reads its mode flag BEFORE the path, and `sweep` accepts
        # only --json — passing --fix or --quiet there made them look like the
        # directory argument.
        if (( fix )); then
            theme::wcag::fix_catalogue "$json"
            return $?
        fi

        local -a sargs=(sweep)
        (( json )) && sargs+=(--json)
        sargs+=("$THEME_CATALOGUE_DIR")

        if (( quiet )) && (( ! json )); then
            # Keep the engine's exit status: piping straight into tail would
            # report tail's success instead.
            local tmp rc
            tmp="$(mktemp -t ash-wcag.XXXXXX)"
            ash_wcag_main "${sargs[@]}" > "$tmp" 2>&1
            rc=$?
            tail -1 "$tmp"
            rm -f "$tmp"
            return $rc
        fi

        ash_wcag_main "${sargs[@]}"
        return $?
    fi

    # ── One theme ─────────────────────────────────────────────────────────────
    local file
    if ! file="$(theme::resolve "$want")"; then
        ash_log_error "No such theme: $want"
        return 1
    fi

    if (( fix )); then
        # A repair that reports success without changing anything is worse than
        # no report at all, so diff the palette either side of the write and say
        # which of the two happened.
        local before after
        before="$(jq -cS '.colors // .' "$file" 2>/dev/null || printf '')"

        if ! ash_wcag_fix_file "$file" --in-place >/dev/null 2>&1; then
            ash_log_error "Could not repair $(basename "$file")"
            return 1
        fi

        after="$(jq -cS '.colors // .' "$file" 2>/dev/null || printf '')"

        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 || $json -eq 1 ]]; then
            jq -n --arg file "$file" --argjson changed "$([[ "$before" != "$after" ]] && echo true || echo false)" \
                  '{file: $file, repaired: $changed, before: $before, after: $after}'
            return 0
        fi

        if [[ "$before" == "$after" ]]; then
            printf '  %s%s%s %s\n' "${ASH_INFO:-$ASH_MUTED}" "ℹ" "${RST}" \
                "$(basename "$file") already passes — nothing to repair"
        else
            theme::record "$(basename "$file" .json)" wcag-fix
            printf '  %s%s%s %s\n' "${ASH_SUCCESS}" "✅" "${RST}" \
                "Repaired contrast in $(basename "$file")"
        fi
        return 0
    fi

    # Mode flag first: ash_wcag_main only inspects $1 after `check`.
    local -a cargs=(check)
    (( json ))  && cargs+=(--json)
    (( quiet )) && cargs+=(--quiet)
    cargs+=("$file")
    ash_wcag_main "${cargs[@]}"
}
