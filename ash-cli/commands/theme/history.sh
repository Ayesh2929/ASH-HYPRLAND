#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — history.sh                                                       ║
# ║  What was applied, when, and how often                                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::history::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme history${RST} [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Reads the append-only log written by every apply, create, clone, edit,
  import and delete. Newest first. Use ${ASH_MUTED}--stats${RST} to see which themes
  actually get used rather than which were merely tried once.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--limit, -n N${RST}      Show only the newest N entries (default 20)
  ${ASH_MUTED}--all, -a${RST}          Show everything
  ${ASH_MUTED}--action NAME${RST}      Only this action (apply, create, clone…)
  ${ASH_MUTED}--stats${RST}            Usage counts instead of a timeline
  ${ASH_MUTED}--clear${RST}            Empty the log
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme history${RST}
  ${ASH_MUTED}ash theme history --stats${RST}
  ${ASH_MUTED}ash theme history --action apply -n 5${RST}
EOF
}

theme::history() {
    local limit=20 all=0 action="" stats=0 clear=0 json=0

    while (( $# )); do
        case "$1" in
            --limit|-n)  limit="${2:-20}"; shift 2 ;;
            --all|-a)    all=1; shift ;;
            --action)    action="${2:-}"; shift 2 ;;
            --stats)     stats=1; shift ;;
            --clear)     clear=1; shift ;;
            --json)      json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)   theme::history::help; return 0 ;;
            -*)          ash_log_error "Unknown option: $1"; theme::history::help; return 2 ;;
            *)           ash_log_error "Unexpected argument: $1"; theme::history::help; return 2 ;;
        esac
    done

    [[ "$limit" =~ ^[0-9]+$ ]] || { ash_log_error "--limit takes a number"; return 2; }

    if (( clear )); then
        if [[ ! -f "$THEME_HISTORY_FILE" ]]; then
            printf '\n  %sHistory is already empty.%s\n\n' "${ASH_MUTED}" "${RST}"
            return 0
        fi
        local n
        n="$(wc -l < "$THEME_HISTORY_FILE" 2>/dev/null | tr -d ' ')"
        rm -f "$THEME_HISTORY_FILE"
        printf '\n  %s✅ Cleared %s.%s\n\n' \
            "${ASH_SUCCESS}" "$(theme::plural "${n:-0}" entry entries)" "${RST}"
        return 0
    fi

    if [[ ! -s "$THEME_HISTORY_FILE" ]]; then
        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
            jq -n '{count: 0, entries: []}'
        else
            printf '\n  %sNo history yet — apply a theme and it will show up here.%s\n\n' \
                "${ASH_MUTED}" "${RST}"
        fi
        return 0
    fi

    # One jq pass: a malformed line is skipped rather than aborting the read,
    # because the log is appended to by several commands and a partial write
    # should not cost the user their whole history.
    #
    # Slicing is done with `[length - n:]` rather than `.[-n:]`: jq rejects a
    # negated variable inside a slice (`.[-$n:]` is a parse error), and building
    # the filter by string interpolation also leaks shell escapes into the
    # program — `\\.` reached jq as an invalid character and the whole read
    # silently produced nothing.

    if (( stats )); then
        if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
            jq -s --arg a "$action" \
               '[.[] | select($a == "" or .action == $a)]
                | group_by(.slug)
                | map({slug: .[0].slug, uses: length,
                       last: (map(.at) | max)})
                | sort_by(-.uses)' "$THEME_HISTORY_FILE" 2>/dev/null \
                | jq '{themes: ., total: (map(.uses) | add // 0)}'
            return 0
        fi

        ash_banner "📊 THEME USAGE" "how often each theme was applied" 80

        local rows
        rows="$(jq -rs --arg a "$action" \
            '[.[] | select($a == "" or .action == $a)]
             | group_by(.slug) | map({slug: .[0].slug, uses: length}) | sort_by(-.uses)
             | .[] | "\(.uses)\t\(.slug)"' "$THEME_HISTORY_FILE" 2>/dev/null)"

        if [[ -z "$rows" ]]; then
            printf '\n  %sNo entries for that filter.%s\n\n' "${ASH_MUTED}" "${RST}"
            return 0
        fi

        local max=1 uses slug
        max="$(awk -F'\t' 'BEGIN{m=1} $1>m{m=$1} END{print m}' <<<"$rows")"
        while IFS=$'\t' read -r uses slug; do
            [[ -n "$slug" ]] || continue
            local bar width
            width=$(( uses * 24 / max ))
            (( width < 1 )) && width=1
            # Built with a loop rather than `tr`: tr is byte-wise in the C
            # locale and emitted only the first byte of the three-byte block
            # character, which then rendered as replacement characters.
            bar=""
            local _b
            for (( _b = 0; _b < width; _b++ )); do bar+='▇'; done
            printf '    %-28s %s%3d%s  %s%s%s\n' \
                "$slug" "${ASH_ACCENT}" "$uses" "${RST}" "${ASH_MUTED}" "$bar" "${RST}"
        done <<<"$rows"

        local total distinct
        total="$(wc -l < "$THEME_HISTORY_FILE" | tr -d ' ')"
        distinct="$(awk -F'\t' 'NF{seen[$2]=1} END{print length(seen)+0}' <<<"$rows")"
        printf '\n  %s%s over %s%s\n\n' \
            "${ASH_MUTED}" "$(theme::plural "${total:-0}" change)" \
            "$(theme::plural "$distinct" theme)" "${RST}"
        return 0
    fi

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        jq -s --arg a "$action" --argjson n "$limit" --argjson full "$all" '
            [.[] | select($a == "" or .action == $a)]
            | (if $full == 1 then .
               elif length > $n then .[length - $n:]
               else . end)
            | {count: length, entries: .}
        ' "$THEME_HISTORY_FILE" 2>/dev/null
        return 0
    fi

    ash_banner "🕐 THEME HISTORY" "newest first" 80

    # Passed as a jq variable rather than interpolated into the program: a
    # program built by string substitution needs its backslashes escaped for
    # the shell, and the escapes then reach jq as syntax errors.
    local lines
    lines="$(jq -rs --arg a "$action" --argjson n "$limit" --argjson full "$all" '
        [.[] | select($a == "" or .action == $a)]
        | (if $full == 1 then .
           elif length > $n then .[length - $n:]
           else . end)
        | .[] | "\(.at)\t\(.action)\t\(.slug)"
    ' "$THEME_HISTORY_FILE" 2>/dev/null)"

    if [[ -z "$lines" ]]; then
        printf '\n  %sNo entries for that filter.%s\n\n' "${ASH_MUTED}" "${RST}"
        return 0
    fi

    # Newest first.
    local at act slug
    while IFS=$'\t' read -r at act slug; do
        [[ -n "$slug" ]] || continue
        # Strip the timezone offset for display; it is the same one throughout.
        at="${at%+*}"
        printf '    %s%-19s%s  %s%-8s%s  %s\n' \
            "${ASH_MUTED}" "$at" "${RST}" \
            "${ASH_ACCENT}" "$act" "${RST}" "$slug"
    done < <(printf '%s\n' "$lines" | tac)

    local total
    total="$(wc -l < "$THEME_HISTORY_FILE" | tr -d ' ')"
    if (( ! all && total > limit )); then
        printf '\n  %s… %s older. Use --all or --limit N.%s\n' \
            "${ASH_MUTED}" "$(theme::plural "$(( total - limit ))" entry entries)" "${RST}"
    fi
    printf '\n'
}
