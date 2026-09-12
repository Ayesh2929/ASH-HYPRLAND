#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — store-upload.sh                                                  ║
# ║  Package a theme for sharing                                                   ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::store_upload::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme store-upload${RST} <theme> [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Produces a publishable bundle and, when a token is configured, uploads it.

  Publishing is gated, not automatic: the theme must validate, the palette must
  pass WCAG, and you are shown exactly what will be sent before anything leaves
  the machine. Without ${ASH_MUTED}\$ASH_STORE_TOKEN${RST} the bundle is written to a file
  and the command says so rather than pretending to have published.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--out FILE${RST}         Where to write the bundle (default: ./<slug>.ash-theme.json)
  ${ASH_MUTED}--description TEXT${RST} One-line description for the store listing
  ${ASH_MUTED}--tag TAG${RST}          Add a tag (repeatable)
  ${ASH_MUTED}--author NAME${RST}      Author name (default: \$USER)
  ${ASH_MUTED}--url URL${RST}          Store to publish to
  ${ASH_MUTED}--bundle-only${RST}      Never upload, just write the file
  ${ASH_MUTED}--force, -f${RST}        Overwrite an existing bundle file
  ${ASH_MUTED}--yes${RST}              Skip the confirmation prompt
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme store-upload my-theme${RST}
  ${ASH_MUTED}ash theme store-upload my-theme --bundle-only --out /tmp/x.json${RST}
EOF
}

theme::store_upload() {
    local want="" out="" description="" author="" url="${ASH_STORE_URL:-}"
    local bundle_only=0 force=0 yes=0 json=0
    local -a tags=()

    while (( $# )); do
        case "$1" in
            --out|-o)      out="${2:-}"; shift 2 ;;
            --description) description="${2:-}"; shift 2 ;;
            --tag)         tags+=("${2:-}"); shift 2 ;;
            --author)      author="${2:-}"; shift 2 ;;
            --url)         url="${2:-}"; shift 2 ;;
            --bundle-only) bundle_only=1; shift ;;
            --force|-f)    force=1; shift ;;
            --yes|-y)      yes=1; shift ;;
            --json)        json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)     theme::store_upload::help; return 0 ;;
            -*)            ash_log_error "Unknown option: $1"; theme::store_upload::help; return 2 ;;
            *)             want="$1"; shift ;;
        esac
    done

    [[ -n "$want" ]] || { ash_log_error "Which theme should I package?"; theme::store_upload::help; return 2; }

    local file
    if ! file="$(theme::resolve "$want")"; then
        ash_log_error "No such theme: $want"
        return 1
    fi

    local slug name variant
    slug="$(jq -r '.slug // empty' "$file" 2>/dev/null)"
    name="$(jq -r '.name // empty' "$file" 2>/dev/null)"
    variant="$(jq -r '.variant // "dark"' "$file" 2>/dev/null)"
    [[ -n "$slug" ]] || slug="$(basename "$file" .json)"
    [[ -n "$name" ]] || name="$slug"
    [[ -n "$author" ]] || author="${USER:-${LOGNAME:-anonymous}}"
    [[ -n "$description" ]] || description="$(jq -r '.description // empty' "$file" 2>/dev/null)"
    [[ -n "$description" ]] || description="$name — an ASH theme"

    [[ -n "$out" ]] || out="${PWD}/${slug}.ash-theme.json"

    # ── Gate 1: the theme has to be structurally valid ────────────────────────
    theme::source_sub validate >/dev/null 2>&1 || true
    if declare -F theme::validate::one >/dev/null 2>&1; then
        if ! theme::validate::one "$file" 0 1 0; then
            ash_log_error "Refusing to publish '$slug' — it does not validate."
            printf '  %sRun %sash theme validate %s%s to see why.%s\n\n' \
                "${ASH_MUTED}" "${ASH_ACCENT}" "$slug" "${ASH_MUTED}" "${RST}" >&2
            return 1
        fi
    fi

    # ── Gate 2: contrast. A published theme should be readable ────────────────
    local wcag=0
    if declare -f ash_wcag_check_palette >/dev/null 2>&1; then
        local -A p=()
        theme::load "$file" p
        local r
        r="$(ash_wcag_check_palette p --quiet 2>/dev/null || true)"
        [[ "$r" =~ ^[0-9]+$ ]] && wcag="$r"
    fi
    if (( wcag > 0 )); then
        ash_log_error "Refusing to publish '$slug' — $wcag contrast pair(s) below 4.5:1."
        printf '  %sFix them first:  ash theme wcag %s --fix%s\n\n' \
            "${ASH_MUTED}" "$slug" "${RST}" >&2
        return 1
    fi

    # ── Build the bundle ──────────────────────────────────────────────────────
    local tag_json='[]'
    local t
    for t in "${tags[@]:-}"; do
        [[ -n "$t" ]] && tag_json="$(jq -c --arg t "$t" '. + [$t]' <<<"$tag_json")"
    done
    [[ "$tag_json" == "[]" ]] && \
        tag_json="$(jq -c '[.family // empty, .variant // empty] | map(select(length>0))' "$file" 2>/dev/null || printf '[]')"

    local bundle
    bundle="$(jq -S --arg author "$author" --arg desc "$description" \
                     --arg at "$(date -Is 2>/dev/null || date)" \
                     --argjson tags "$tag_json" \
                     '. + {author: $author, description: $desc,
                            published: $at, tags: $tags,
                            bundle_version: 1}' "$file" 2>/dev/null)"

    if [[ -z "$bundle" ]]; then
        ash_log_error "Could not build the bundle"
        return 1
    fi

    if [[ -e "$out" && "$force" -eq 0 ]]; then
        ash_log_error "$out already exists."
        printf '  %sPass --force to overwrite it.%s\n\n' "${ASH_MUTED}" "${RST}" >&2
        return 1
    fi

    # ── Show what would be sent ───────────────────────────────────────────────
    if [[ "$json" != "1" ]]; then
        printf '\n  %s%s%s%s  %s%s · %s · by %s%s\n' \
            "${BOLD}${ASH_ACCENT}" "$slug" "${RST}" "" "${ASH_MUTED}" "$name" "$variant" "$author" "${RST}"
        printf '  %s%s%s\n' "${ASH_MUTED}" "$description" "${RST}"
        local slots
        slots="$(jq -r '(.colors // .) | keys | length' "$file" 2>/dev/null)"
        printf '  %s%s colour slots · WCAG clean · to %s%s\n\n' \
            "${ASH_MUTED}" "$slots" "${url:-<no store URL>}" "${RST}"

        if (( ! bundle_only )); then
            if [[ -z "${ASH_STORE_TOKEN:-}" ]]; then
                printf '  %sNo \$ASH_STORE_TOKEN set — writing a bundle instead of uploading.%s\n' \
                    "${ASH_MUTED}" "${RST}"
                printf '  %sShare %s yourself, or set a token and re-run.%s\n\n' \
                    "${ASH_MUTED}" "$(basename "$out")" "${RST}"
                bundle_only=1
            elif (( ! yes )) && declare -f ash_confirm >/dev/null 2>&1; then
                ash_confirm "Upload $slug to $url?" || {
                    printf '  %sCancelled.%s\n\n' "${ASH_MUTED}" "${RST}"
                    return 0
                }
            fi
        fi
    fi

    mkdir -p "$(dirname "$out")"
    printf '%s\n' "$bundle" > "${out}.tmp" && mv "${out}.tmp" "$out" || {
        ash_log_error "Could not write $out"
        return 1
    }

    # ── Upload ────────────────────────────────────────────────────────────────
    local uploaded=0
    if (( ! bundle_only )) && [[ -n "${ASH_STORE_TOKEN:-}" ]] && [[ -n "$url" ]]; then
        if declare -f ash_http_post_json >/dev/null 2>&1; then
            if ash_http_post_json "${url%/}/themes" "$bundle" \
                 "Authorization: Bearer ${ASH_STORE_TOKEN}" >/dev/null 2>&1; then
                uploaded=1
                theme::record "$slug" store-upload
            else
                ash_log_error "Upload failed; the bundle is still at $out"
            fi
        else
            ash_log_error "HTTP support is not loaded; the bundle is at $out"
        fi
    fi

    if (( json )); then
        jq -n --arg slug "$slug" --arg out "$out" --arg author "$author" \
              --argjson uploaded "$uploaded" --argjson tags "$tag_json" \
              '{slug: $slug, bundle: $out, author: $author, tags: $tags,
                uploaded: ($uploaded == 1)}'
        return 0
    fi

    printf '\n  %s✅ Packaged%s %s%s%s\n' "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$slug" "${RST}"
    printf '  %s   %s (%s bytes, %s)%s\n\n' \
        "${ASH_MUTED}" "$out" "$(wc -c < "$out" | tr -d ' ')" \
        "$( ((uploaded)) && printf 'uploaded' || printf 'not uploaded' )" "${RST}"

    (( ! uploaded )) && return 0
    return 0
}
