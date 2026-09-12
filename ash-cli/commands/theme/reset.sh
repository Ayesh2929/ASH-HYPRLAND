#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — reset.sh                                                         ║
# ║  Go back to the default theme                                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::reset::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme reset${RST} [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Re-applies the default theme and repoints the default at it. The default is
  ${ASH_MUTED}\$ASH_THEME${RST}, falling back to catppuccin-mocha and then to the first
  theme in the catalogue, so this works on a machine where the configured
  default has been deleted.

  Resetting is an ordinary apply — the previous theme is not destroyed, and
  ${ASH_MUTED}ash theme history${RST} keeps the record. ${ASH_MUTED}--undo${RST} steps back to whatever was
  applied before the reset.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--theme NAME${RST}      Reset to this theme instead of the default
  ${ASH_MUTED}--set-default NAME${RST} Change the configured default, apply nothing
  ${ASH_MUTED}--show${RST}            Print the default without applying it
  ${ASH_MUTED}--undo${RST}            Apply the theme that preceded the current one
  ${ASH_MUTED}--dry-run, -n${RST}     Show what would be applied
  ${ASH_MUTED}--json${RST}            Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme reset${RST}
  ${ASH_MUTED}ash theme reset --undo${RST}
  ${ASH_MUTED}ash theme reset --set-default gruvbox${RST}
EOF
}

# The configured default, or the first catalogue theme that actually exists.
theme::reset::default() {
    local cand="${ASH_THEME:-}"

    if [[ -n "$cand" ]] && theme::resolve "$cand" >/dev/null 2>&1; then
        printf '%s' "$cand"; return 0
    fi

    for cand in catppuccin-mocha catppuccin-macchiato nord; do
        theme::resolve "$cand" >/dev/null 2>&1 && { printf '%s' "$cand"; return 0; }
    done

    # Last resort: whatever the catalogue has first, so reset never fails
    # outright on a stripped-down install.
    local slug
    while IFS=$'\t' read -r slug _rest; do
        [[ -n "$slug" ]] || continue
        printf '%s' "$slug"; return 0
    done < <(theme::index)

    return 1
}

# The theme applied before the current one, from the history log.
theme::reset::previous() {
    [[ -s "$THEME_HISTORY_FILE" ]] || return 1

    local current
    current="$(theme::current 2>/dev/null || true)"

    # Walk backwards for the most recent apply of a different slug.
    local slug action
    while IFS=$'\t' read -r action slug; do
        [[ "$action" == "apply" ]] || continue
        [[ "$slug" == "$current" ]] && continue
        [[ -n "$slug" ]] || continue
        printf '%s' "$slug"; return 0
    done < <(jq -rs '[.[] | select(.action == "apply")] | reverse | .[] | "\(.action)\t\(.slug)"' \
                "$THEME_HISTORY_FILE" 2>/dev/null)

    return 1
}

theme::reset() {
    local want="" set_default="" show=0 undo=0 dry=0 json=0

    while (( $# )); do
        case "$1" in
            --theme)        want="${2:-}"; shift 2 ;;
            --set-default)  set_default="${2:-}"; shift 2 ;;
            --show)         show=1; shift ;;
            --undo)         undo=1; shift ;;
            --dry-run|-n)   dry=1; shift ;;
            --json)         json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)      theme::reset::help; return 0 ;;
            -*)             ash_log_error "Unknown option: $1"; theme::reset::help; return 2 ;;
            *)              ash_log_error "Unexpected argument: $1"; theme::reset::help; return 2 ;;
        esac
    done

    # ── Change the configured default ─────────────────────────────────────────
    if [[ -n "$set_default" ]]; then
        if ! theme::resolve "$set_default" >/dev/null 2>&1; then
            ash_log_error "No such theme: $set_default"
            return 1
        fi

        local slug
        slug="$(theme::resolve "$set_default" | xargs -r jq -r '.slug // empty' 2>/dev/null)"
        [[ -n "$slug" ]] || slug="$set_default"

        if declare -f ash_config_set >/dev/null 2>&1; then
            ash_config_set "theme.default" "$slug" >/dev/null 2>&1 \
                || ash_config_set "ASH_THEME" "$slug" >/dev/null 2>&1 || true
        fi

        if [[ "$json" == "1" ]]; then
            jq -n --arg slug "$slug" '{default: $slug, applied: false}'
        else
            printf '\n  %s✅ Default theme is now %s.%s\n' "${ASH_SUCCESS}" "$slug" "${RST}"
            printf '  %s   Apply it with: ash theme reset%s\n\n' "${ASH_MUTED}" "${RST}"
        fi
        return 0
    fi

    [[ -n "$want" ]] || want="$(theme::reset::default)" || {
        ash_log_error "No default theme could be determined."
        return 1
    }

    if (( show )); then
        if [[ "$json" == "1" ]]; then
            jq -n --arg slug "$want" '{default: $slug}'
        else
            printf '%s\n' "$want"
        fi
        return 0
    fi

    if (( undo )); then
        local prev
        if ! prev="$(theme::reset::previous)"; then
            ash_log_error "No previous theme in the history to undo to."
            printf '  %sApply a theme first; the log lives in %s%s\n\n' \
                "${ASH_MUTED}" "$THEME_HISTORY_FILE" "${RST}" >&2
            return 1
        fi
        want="$prev"
    fi

    if (( dry )); then
        local file
        file="$(theme::resolve "$want")" || return 1
        if [[ "$json" == "1" ]]; then
            jq -n --arg slug "$want" --arg file "$file" --argjson undo "$undo" \
                  '{slug: $slug, file: $file, undo: ($undo == 1), dry_run: true}'
        else
            printf '\n  %sDry run — nothing applied.%s\n' "${ASH_MUTED}" "${RST}"
            printf '    would apply  %s%s%s\n' "${BOLD}${ASH_ACCENT}" "$want" "${RST}"
            printf '    from         %s\n\n' "$file"
        fi
        return 0
    fi

    theme::source_sub apply || return 1
    theme::apply "$want" || return $?

    if [[ "$json" == "1" ]]; then
        jq -n --arg slug "$want" --argjson undo "$undo" \
              '{slug: $slug, undo: ($undo == 1), applied: true}'
        return 0
    fi

    if (( undo )); then
        printf '  %s↩ Reverted to %s%s\n\n' "${ASH_MUTED}" "$want" "${RST}"
    else
        printf '  %s↺ Back to the default (%s)%s\n\n' "${ASH_MUTED}" "$want" "${RST}"
    fi
}
