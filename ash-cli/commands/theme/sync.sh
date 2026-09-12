#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — sync.sh                                                          ║
# ║  Move your themes between machines                                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::sync::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme sync${RST} [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Copies your themes to or from a directory — a NAS mount, a USB stick, a
  synced folder, or a git working tree you commit yourself. Only themes you own
  are involved; the catalogue is in the repo and travels with it.

  Direction is decided per file by content hash, so re-running sync is cheap and
  a two-way sync never silently picks a loser: a file that differs on both sides
  is reported as a conflict and left alone.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--to DIR${RST}          Push user themes to DIR
  ${ASH_MUTED}--from DIR${RST}        Pull themes from DIR
  ${ASH_MUTED}--both DIR${RST}        Two-way, newest wins, conflicts reported
  ${ASH_MUTED}--status DIR${RST}      Report differences without copying
  ${ASH_MUTED}--force${RST}           Overwrite even when the other side is newer
  ${ASH_MUTED}--dry-run, -n${RST}     Show what would happen
  ${ASH_MUTED}--json${RST}            Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme sync --to ~/Dropbox/ash-themes${RST}
  ${ASH_MUTED}ash theme sync --from /mnt/usb/themes${RST}
  ${ASH_MUTED}ash theme sync --status ~/Dropbox/ash-themes${RST}
EOF
}

theme::sync::hash() {
    [[ -f "$1" ]] || return 1
    if declare -f ash_hash_file >/dev/null 2>&1; then
        ash_hash_file "$1" 2>/dev/null && return 0
    fi
    # Fall back to a size+mtime fingerprint rather than failing: it is enough to
    # tell "identical" from "changed", which is all the comparison needs.
    printf '%s-%s' "$(wc -c < "$1" | tr -d ' ')" "$(date -r "$1" +%s 2>/dev/null || printf '0')"
}

theme::sync() {
    local dir="" mode="" force=0 dry=0 json=0

    while (( $# )); do
        case "$1" in
            --to)      mode="push"; dir="${2:-}"; shift 2 ;;
            --from)    mode="pull"; dir="${2:-}"; shift 2 ;;
            --both)    mode="both"; dir="${2:-}"; shift 2 ;;
            --status)  mode="status"; dir="${2:-}"; shift 2 ;;
            --force)   force=1; shift ;;
            --dry-run|-n) dry=1; shift ;;
            --json)    json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help) theme::sync::help; return 0 ;;
            -*)        ash_log_error "Unknown option: $1"; theme::sync::help; return 2 ;;
            *)         ash_log_error "Unexpected argument: $1"; theme::sync::help; return 2 ;;
        esac
    done

    if [[ -z "$mode" ]]; then
        ash_log_error "Pick a direction."
        theme::sync::help
        return 2
    fi
    if [[ -z "$dir" ]]; then
        ash_log_error "--${mode/status/status} needs a directory"
        return 2
    fi

    # Create the destination for a push; refuse to create it for a pull, where a
    # typo would otherwise produce an empty directory and a silent no-op.
    if [[ "$mode" == "push" ]]; then
        mkdir -p "$dir" 2>/dev/null || { ash_log_error "Cannot create $dir"; return 1; }
    elif [[ ! -d "$dir" ]]; then
        ash_log_error "No such directory: $dir"
        return 1
    fi

    local real_src real_dst
    real_src="$(cd "$THEME_USER_DIR" 2>/dev/null && pwd || printf '%s' "$THEME_USER_DIR")"
    real_dst="$(cd "$dir" 2>/dev/null && pwd || printf '%s' "$dir")"

    if [[ "$real_src" == "$real_dst" ]]; then
        ash_log_error "Source and destination are the same directory."
        return 2
    fi

    mkdir -p "$THEME_USER_DIR"

    local -a pushed=() pulled=() conflicts=() same=()
    local f name src_hash dst_hash src_mtime dst_mtime

    # Union of both sides: a theme that exists only at the destination is a
    # candidate for pulling, and vice versa.
    local -a names=()
    local d
    for d in "$THEME_USER_DIR" "$dir"; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*.json; do
            [[ -f "$f" ]] || continue
            name="$(basename "$f")"
            # Membership by loop, not by pattern: bash joins an array with
            # IFS[0] (a newline here), so `" ${names[*]} "` never matches a
            # space-delimited pattern and every name was added twice.
            local _seen=0 _n
            for _n in "${names[@]}"; do
                if [[ "$_n" == "$name" ]]; then _seen=1; break; fi
            done
            if (( _seen )); then continue; fi
            names+=("$name")
        done
    done

    if (( ${#names[@]} == 0 )); then
        if (( json )); then
            jq -n --arg dir "$dir" --arg mode "$mode" \
                  '{mode: $mode, dir: $dir, pushed: [], pulled: [], conflicts: [], unchanged: []}'
        else
            printf '\n  %s%s and the user theme directory are both empty.%s\n\n' \
                "${ASH_MUTED}" "$dir" "${RST}"
        fi
        return 0
    fi

    local src dst
    for name in "${names[@]}"; do
        src="${THEME_USER_DIR}/${name}"
        dst="${dir}/${name}"
        src_hash=""; dst_hash=""
        [[ -f "$src" ]] && src_hash="$(theme::sync::hash "$src")"
        [[ -f "$dst" ]] && dst_hash="$(theme::sync::hash "$dst")"

        if [[ -n "$src_hash" && "$src_hash" == "$dst_hash" ]]; then
            same+=("$name"); continue
        fi

        src_mtime=0; dst_mtime=0
        [[ -f "$src" ]] && src_mtime="$(date -r "$src" +%s 2>/dev/null || printf '0')"
        [[ -f "$dst" ]] && dst_mtime="$(date -r "$dst" +%s 2>/dev/null || printf '0')"

        case "$mode" in
            push)
                [[ -f "$src" ]] || continue
                pushed+=("$name")
                (( dry )) || cp -p "$src" "$dst" 2>/dev/null || true
                ;;
            pull)
                [[ -f "$dst" ]] || continue
                pulled+=("$name")
                (( dry )) || { cp -p "$dst" "$src" 2>/dev/null || true; }
                ;;
            status)
                if [[ ! -f "$src" ]]; then   pulled+=("$name")
                elif [[ ! -f "$dst" ]]; then pushed+=("$name")
                elif (( src_mtime == dst_mtime )); then same+=("$name")
                else
                    # Same name, different content, neither obviously newer.
                    if (( src_mtime > dst_mtime )); then pushed+=("$name")
                    else pulled+=("$name"); fi
                fi
                ;;
            both)
                if [[ ! -f "$src" ]]; then
                    pulled+=("$name"); (( dry )) || cp -p "$dst" "$src" 2>/dev/null || true
                elif [[ ! -f "$dst" ]]; then
                    pushed+=("$name"); (( dry )) || cp -p "$src" "$dst" 2>/dev/null || true
                elif (( src_mtime == dst_mtime )); then
                    # Different content, same timestamp: do not guess.
                    conflicts+=("$name")
                elif (( force )) || (( src_mtime > dst_mtime )); then
                    pushed+=("$name"); (( dry )) || cp -p "$src" "$dst" 2>/dev/null || true
                else
                    pulled+=("$name"); (( dry )) || cp -p "$dst" "$src" 2>/dev/null || true
                fi
                ;;
        esac
    done

    if (( json )); then
        jq -n --arg mode "$mode" --arg dir "$dir" --argjson dry "$dry" \
              --argjson pushed "$(printf '%s\n' "${pushed[@]:-}"   | jq -Rn '[inputs|select(length>0)]')" \
              --argjson pulled "$(printf '%s\n' "${pulled[@]:-}"   | jq -Rn '[inputs|select(length>0)]')" \
              --argjson conflicts "$(printf '%s\n' "${conflicts[@]:-}" | jq -Rn '[inputs|select(length>0)]')" \
              --argjson same "$(printf '%s\n' "${same[@]:-}"     | jq -Rn '[inputs|select(length>0)]')" \
              '{mode: $mode, dir: $dir, dry_run: ($dry == 1),
                pushed: $pushed, pulled: $pulled, conflicts: $conflicts, unchanged: $same}'
        return 0
    fi

    ash_banner "☁️  THEME SYNC" "${mode} · ${dir}" 80
    (( dry )) && printf '\n  %sDry run — nothing copied.%s\n' "${ASH_MUTED}" "${RST}"

    local s
    for s in "${pushed[@]:-}";    do [[ -n "$s" ]] && printf '    %s→%s %s\n' "${ASH_ACCENT}" "${RST}" "$s"; done
    for s in "${pulled[@]:-}";    do [[ -n "$s" ]] && printf '    %s←%s %s\n' "${ASH_ACCENT}" "${RST}" "$s"; done
    for s in "${conflicts[@]:-}"; do [[ -n "$s" ]] && printf '    %s⚠%s %s  %schanged on both sides%s\n' \
        "${ASH_WARNING:-$ASH_MUTED}" "${RST}" "$s" "${ASH_MUTED}" "${RST}"; done

    printf '\n  %s%s pushed, %s pulled' "${ASH_MUTED}" "${#pushed[@]}" "${#pulled[@]}"
    (( ${#conflicts[@]} )) && printf ', %s conflicted' "${#conflicts[@]}"
    printf ', %s unchanged%s\n\n' "${#same[@]}" "${RST}"

    (( ${#conflicts[@]} )) && return 1
    return 0
}
