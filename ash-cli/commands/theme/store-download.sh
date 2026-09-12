#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — store-download.sh                                                ║
# ║  Install a theme from the store or a URL                                       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::store_download::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme store-download${RST} <slug|url>…

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Fetches a theme and installs it into your own theme directory. Accepts a store
  slug, a direct URL to a JSON theme, or a local path.

  Anything downloaded is validated before it is installed: a theme that would
  fail ${ASH_MUTED}ash theme validate${RST} is written to a temporary file and refused,
  rather than being added to a catalogue that is supposed to be trustworthy.
  The destination is your user directory, never the catalogue.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--as SLUG${RST}          Install under this slug instead
  ${ASH_MUTED}--force, -f${RST}        Overwrite an existing theme
  ${ASH_MUTED}--url URL${RST}          Use a different store
  ${ASH_MUTED}--no-verify${RST}        Skip the validation step (not advised)
  ${ASH_MUTED}--dry-run, -n${RST}      Fetch and validate, install nothing
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme store-download nord-aurora${RST}
  ${ASH_MUTED}ash theme store-download https://example.com/theme.json${RST}
  ${ASH_MUTED}ash theme store-download https://example.com/t.json --as my-theme${RST}
EOF
}

# Resolve a store slug to a download URL, using the cached index when present.
theme::store_download::resolve_url() {
    local slug="$1" url="$2"

    theme::source_sub store-browse >/dev/null 2>&1 || true

    local idx=""
    if declare -F theme::store_browse::ensure_index >/dev/null 2>&1; then
        idx="$(theme::store_browse::ensure_index "$url" 0 2>/dev/null || printf '')"
    fi

    if [[ -s "$idx" ]]; then
        local found
        found="$(jq -r --arg s "$slug" '
            (.themes // .)
            | map(select((.slug // "") == $s))
            | (.[0].download // .[0].url // .[0].file // empty)
        ' "$idx" 2>/dev/null)"
        if [[ -n "$found" ]]; then
            # A relative path in the index is relative to the store root.
            case "$found" in
                http://*|https://*) printf '%s' "$found" ;;
                *) printf '%s/%s' "${url%/}" "${found#/}" ;;
            esac
            return 0
        fi
    fi

    # No index entry: guess the conventional path. Better than failing on a
    # store whose index is unavailable.
    printf '%s/themes/%s.json' "${url%/}" "$slug"
}

theme::store_download() {
    local as_slug="" force=0 url="${ASH_STORE_URL:-}" verify=1 dry=0 json=0
    local -a targets=()

    while (( $# )); do
        case "$1" in
            --as)         as_slug="${2:-}"; shift 2 ;;
            --force|-f)   force=1; shift ;;
            --url)        url="${2:-}"; shift 2 ;;
            --no-verify)  verify=0; shift ;;
            --dry-run|-n) dry=1; shift ;;
            --json)       json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)    theme::store_download::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::store_download::help; return 2 ;;
            *)            targets+=("$1"); shift ;;
        esac
    done

    if (( ${#targets[@]} == 0 )); then
        ash_log_error "Which theme should I download?"
        theme::store_download::help
        return 2
    fi

    if [[ "${#targets[@]}" -gt 1 && -n "$as_slug" ]]; then
        ash_log_error "--as only makes sense with a single theme"
        return 2
    fi

    mkdir -p "$THEME_USER_DIR"

    local -a installed=() refused=()
    local target

    for target in "${targets[@]}"; do
        local src_url=""
        case "$target" in
            http://*|https://*) src_url="$target" ;;
            /*|./*|../*|*/*.json)
                # A filesystem path: install it directly, no network.
                if [[ -f "$target" ]]; then src_url="file://$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
                else
                    ash_log_error "No such file: $target"; refused+=("$target"); continue
                fi ;;
            *)
                if [[ -z "$url" ]]; then
                    ash_log_error "No store URL configured for '$target'"
                    refused+=("$target"); continue
                fi
                if ! declare -f ash_http_download >/dev/null 2>&1; then
                    ash_log_error "HTTP support is not loaded"; refused+=("$target"); continue
                fi
                src_url="$(theme::store_download::resolve_url "$target" "$url")"
                ;;
        esac

        local tmp
        tmp="$(mktemp -t ash-store-dl.XXXXXX)" || { refused+=("$target"); continue; }

        local got=0
        case "$src_url" in
            file://*)
                cp "${src_url#file://}" "$tmp" 2>/dev/null && got=1 ;;
            *)
                if declare -f ash_http_download >/dev/null 2>&1; then
                    ash_http_download "$src_url" "$tmp" >/dev/null 2>&1 && got=1
                fi ;;
        esac

        if (( ! got )); then
            ash_log_error "Download failed: $src_url"
            rm -f "$tmp"
            refused+=("$target")
            continue
        fi

        if ! jq -e . "$tmp" >/dev/null 2>&1; then
            ash_log_error "$target did not return JSON — refusing to install it"
            rm -f "$tmp"
            refused+=("$target")
            continue
        fi

        local slug name variant
        slug="$(jq -r '.slug // empty' "$tmp" 2>/dev/null)"
        name="$(jq -r '.name // empty' "$tmp" 2>/dev/null)"
        variant="$(jq -r '.variant // "dark"' "$tmp" 2>/dev/null)"
        [[ -n "$slug" ]] || slug="$(basename "${target%.json}")"
        [[ -n "$slug" ]] || slug="downloaded-$RANDOM"
        [[ -n "$as_slug" ]] && slug="$as_slug"
        slug="$(ash_generate_slug "$slug" 2>/dev/null || printf '%s' "$slug")"
        [[ -n "$name" ]] || name="$slug"

        local dest="${THEME_USER_DIR}/${slug}.json"

        if [[ -f "$dest" && "$force" -eq 0 && "$dry" -eq 0 ]]; then
            ash_log_error "User theme '$slug' already exists — pass --force to replace it"
            rm -f "$tmp"
            refused+=("$target")
            continue
        fi

        # ── Validate before installing ────────────────────────────────────────
        local ok=1 reason=""
        if (( verify )); then
            theme::source_sub validate >/dev/null 2>&1 || true
            if declare -F theme::validate::one >/dev/null 2>&1; then
                theme::validate::one "$tmp" 0 1 0 || { ok=0; reason="failed theme validation"; }
            else
                # Minimal inline check when the validate module is unavailable:
                # the slots and a hex value for each are non-negotiable.
                local -A p=()
                theme::load "$tmp" p
                if (( ${#p[@]} < ${#THEME_SLOT_ORDER[@]} )); then
                    ok=0; reason="only ${#p[@]} of ${#THEME_SLOT_ORDER[@]} slots present"
                fi
            fi
        fi

        if (( ! ok )); then
            ash_log_error "'$target' was refused: $reason"
            rm -f "$tmp"
            refused+=("$target")
            continue
        fi

        if (( dry )); then
            installed+=("$slug")
            rm -f "$tmp"
            continue
        fi

        # Rewrite the identity so the file is consistent with where it lives.
        jq -S --arg slug "$slug" --arg name "$name" --arg from "$src_url" \
              '.slug = $slug | .name = $name | .source = $from' \
              "$tmp" > "${dest}.tmp" 2>/dev/null && mv "${dest}.tmp" "$dest" || {
            ash_log_error "Could not write $dest"
            rm -f "$tmp"
            refused+=("$target")
            continue
        }
        rm -f "$tmp"

        theme::record "$slug" store-download
        installed+=("$slug")
    done

    if (( json )); then
        jq -n --argjson dry "$dry" \
              --argjson installed "$(printf '%s\n' "${installed[@]:-}" | jq -Rn '[inputs|select(length>0)]')" \
              --argjson refused "$(printf '%s\n' "${refused[@]:-}" | jq -Rn '[inputs|select(length>0)]')" \
              '{installed: $installed, refused: $refused, dry_run: ($dry == 1)}'
        (( ${#refused[@]} )) && return 1
        return 0
    fi

    printf '\n'
    (( dry )) && printf '  %sDry run — nothing installed.%s\n' "${ASH_MUTED}" "${RST}"

    local s
    for s in "${installed[@]:-}"; do
        [[ -n "$s" ]] && printf '  %s✅ Installed%s %s%s%s\n' \
            "${ASH_SUCCESS}" "${RST}" "${BOLD}${ASH_ACCENT}" "$s" "${RST}"
    done
    for s in "${refused[@]:-}"; do
        [[ -n "$s" ]] && printf '  %s✗ Refused%s %s\n' "${ASH_ERROR}" "${RST}" "$s"
    done
    printf '\n'

    (( ${#refused[@]} )) && return 1

    if (( ! dry )) && (( ${#installed[@]} == 1 )); then
        printf '  %sPreview it:  ash theme preview %s --mock%s\n\n' \
            "${ASH_MUTED}" "${installed[0]}" "${RST}"
    fi
    return 0
}
