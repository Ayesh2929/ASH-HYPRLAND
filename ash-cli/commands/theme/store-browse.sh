#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — store-browse.sh                                                  ║
# ║  Look through the community themes                                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::store_browse::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme store-browse${RST} [query] [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Lists themes published to ${ASH_MUTED}\$ASH_STORE_URL${RST}. The index is cached under
  ${ASH_MUTED}\$ASH_STORE_CACHE${RST} and re-fetched when it is older than the cache age,
  so browsing works offline against the last index you saw.

  ${ASH_MUTED}--local${RST} browses what you already have instead, which is the same view
  ${ASH_MUTED}ash theme list${RST} gives you with different filters.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--refresh${RST}          Re-fetch the index even if it is fresh
  ${ASH_MUTED}--local${RST}            Browse installed themes, no network
  ${ASH_MUTED}--tag TAG${RST}          Filter by tag
  ${ASH_MUTED}--author NAME${RST}      Filter by author
  ${ASH_MUTED}--limit, -n N${RST}      Show at most N
  ${ASH_MUTED}--url URL${RST}          Use a different store
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme store-browse${RST}
  ${ASH_MUTED}ash theme store-browse gruvbox${RST}
  ${ASH_MUTED}ash theme store-browse --tag light --limit 10${RST}
EOF
}

theme::store_browse::index_file() {
    local cache="${ASH_STORE_CACHE:-${ASH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/ash}/store}"
    printf '%s/index.json' "$cache"
}

# Fetch the index unless the cached copy is fresh. Prints the path on success.
theme::store_browse::ensure_index() {
    local url="$1" refresh="$2"
    local idx
    idx="$(theme::store_browse::index_file)"

    if [[ -s "$idx" && "$refresh" -eq 0 ]]; then
        local age max_age=86400 now mtime
        now="$(date +%s 2>/dev/null || printf '0')"
        mtime="$(date -r "$idx" +%s 2>/dev/null || printf '0')"
        age=$(( now - mtime ))
        (( age < max_age )) && { printf '%s' "$idx"; return 0; }
    fi

    if ! declare -f ash_http_get >/dev/null 2>&1; then
        [[ -s "$idx" ]] && { printf '%s' "$idx"; return 0; }
        return 1
    fi

    local tmp
    tmp="$(mktemp -t ash-store.XXXXXX)" || return 1
    if ash_http_get "${url%/}/index.json" > "$tmp" 2>/dev/null && \
       jq -e . "$tmp" >/dev/null 2>&1; then
        mkdir -p "$(dirname "$idx")"
        mv "$tmp" "$idx"
        printf '%s' "$idx"
        return 0
    fi
    rm -f "$tmp"

    # A stale cache beats no result at all, but the caller needs to know.
    [[ -s "$idx" ]] && { printf '%s' "$idx"; return 2; }
    return 1
}

theme::store_browse() {
    local query="" tag="" author="" limit="" url="${ASH_STORE_URL:-}" refresh=0 local_only=0 json=0

    while (( $# )); do
        case "$1" in
            --refresh)    refresh=1; shift ;;
            --local)      local_only=1; shift ;;
            --tag)        tag="${2:-}"; shift 2 ;;
            --author)     author="${2:-}"; shift 2 ;;
            --limit|-n)   limit="${2:-}"; shift 2 ;;
            --url)        url="${2:-}"; shift 2 ;;
            --json)       json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)    theme::store_browse::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::store_browse::help; return 2 ;;
            *)            query="${query:+$query }$1"; shift ;;
        esac
    done

    [[ -z "$limit" || "$limit" =~ ^[0-9]+$ ]] || { ash_log_error "--limit takes a number"; return 2; }

    # ── Local: the installed catalogue ────────────────────────────────────────
    if (( local_only )); then
        local rows='[]' slug name variant family seed path n=0
        while IFS=$'\t' read -r slug name variant family seed path; do
            [[ -n "$slug" ]] || continue
            if [[ -n "$query" && "$(tr '[:upper:]' '[:lower:]' <<<"$slug $name $family")" != *"${query,,}"* ]]; then
                continue
            fi
            rows="$(jq -c --arg s "$slug" --arg n "$name" --arg v "$variant" \
                     --arg f "$family" --arg sd "$seed" \
                     '. + [{slug:$s, name:$n, variant:$v, family:$f, seed:$sd}]' <<<"$rows")"
            (( n++ )) || true
            [[ -n "$limit" ]] && (( n >= limit )) && break
        done < <(theme::index)

        if (( json )); then
            jq -n --argjson n "$n" --arg q "$query" --argjson t "$rows" \
                  '{source: "local", query: $q, total: $n, themes: $t}'
            return 0
        fi

        ash_banner "🏬 INSTALLED THEMES" "${n} matching '${query:-*}'" 80
        local r
        while IFS= read -r r; do
            printf '    %-30s %s%s  %s%s%s\n' \
                "$(jq -r '.slug' <<<"$r")" "${ASH_MUTED}" "$(jq -r '.variant' <<<"$r")" \
                "$(jq -r '.name' <<<"$r")" "${RST}" ""
        done < <(jq -c '.[]' <<<"$rows" 2>/dev/null)
        printf '\n'
        return 0
    fi

    # ── Remote ────────────────────────────────────────────────────────────────
    if [[ -z "$url" ]]; then
        ash_log_error "No store URL configured (ASH_STORE_URL is empty)."
        printf '  %sBrowse what you have instead:  ash theme store-browse --local%s\n\n' \
            "${ASH_MUTED}" "${RST}" >&2
        return 1
    fi

    local idx stale=0
    if idx="$(theme::store_browse::ensure_index "$url" "$refresh")"; then
        :
    else
        stale=$?
        if [[ ! -s "${idx:-}" ]]; then
            ash_log_error "Could not reach the store at $url"
            printf '  %sNo cached index to fall back on. Try --local.%s\n\n' \
                "${ASH_MUTED}" "${RST}" >&2
            return 1
        fi
    fi
    [[ -s "$idx" ]] || { ash_log_error "The store index is empty"; return 1; }

    # The index may be {themes:[…]} or a bare array; accept both.
    local filter='.'
    local -a jqargs=(--arg q "$query" --arg tag "$tag" --arg author "$author")
    local rows
    rows="$(jq -c "${jqargs[@]}" '
        (.themes // .)
        | map(select(
            ($q == "" or ((.slug // "") + " " + (.name // "") + " " + (.description // "")) | ascii_downcase | contains($q | ascii_downcase))
            and ($tag == "" or ((.tags // []) | index($tag) != null))
            and ($author == "" or (.author // "") == $author)
          ))
    ' "$idx" 2>/dev/null)" || rows='[]'

    local total
    total="$(jq -r 'length' <<<"$rows" 2>/dev/null || printf '0')"

    if [[ -n "$limit" ]]; then
        rows="$(jq -c --argjson n "$limit" '.[0:$n]' <<<"$rows" 2>/dev/null || printf '[]')"
    fi

    if (( json )); then
        jq -n --arg url "$url" --arg q "$query" --argjson n "$total" \
              --argjson stale "$([[ $stale -eq 2 ]] && echo 1 || echo 0)" \
              --argjson themes "$rows" \
              '{source: "store", url: $url, query: $q, total: $n,
                from_cache: ($stale == 1), themes: $themes}'
        return 0
    fi

    ash_banner "🏬 THEME STORE" "${total} theme(s)${query:+ matching '$query'}" 80
    (( stale == 2 )) && printf '\n  %s⚠  Showing a cached index — the store is unreachable.%s\n' \
        "${ASH_WARNING:-$ASH_MUTED}" "${RST}"

    if (( total == 0 )); then
        printf '\n  %sNothing matches.%s\n\n' "${ASH_MUTED}" "${RST}"
        return 1
    fi

    local r
    while IFS= read -r r; do
        [[ -n "$r" ]] || continue
        local slug name author_c variant desc
        slug="$(jq -r '.slug // "?"' <<<"$r")"
        name="$(jq -r '.name // .slug // "?"' <<<"$r")"
        author_c="$(jq -r '.author // "unknown"' <<<"$r")"
        variant="$(jq -r '.variant // "dark"' <<<"$r")"
        desc="$(jq -r '.description // ""' <<<"$r")"
        printf '    %s%-26s%s %s%s%s  %s%s%s\n' \
            "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" \
            "${ASH_MUTED}" "$variant" "${RST}" \
            "${ASH_MUTED}" "${name}${author_c:+ · by $author_c}" "${RST}"
        [[ -n "$desc" ]] && printf '      %s%s%s\n' "${ASH_MUTED}" "${desc:0:72}" "${RST}"
    done < <(jq -c '.[]' <<<"$rows" 2>/dev/null)

    printf '\n  %sInstall one:  ash theme store-download <slug>%s\n\n' "${ASH_MUTED}" "${RST}"
}
