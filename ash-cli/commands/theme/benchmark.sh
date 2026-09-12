#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH THEME — benchmark.sh                                                     ║
# ║  Measure where time actually goes when a theme is applied                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
# Sourced by theme.sh; defines only.

theme::benchmark::help() {
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ${ASH_ACCENT}ash theme benchmark${RST} [theme] [options]

${BOLD}${ASH_PRIMARY}DESCRIPTION${RST}
  Times the stages of an apply separately, because they fail for different
  reasons and only one of them is worth optimising:

    ${ASH_MUTED}resolve${RST}    finding the theme (a case-insensitive miss walks every file)
    ${ASH_MUTED}load${RST}       reading the palette
    ${ASH_MUTED}derive${RST}     regenerating a palette from a seed, if asked
    ${ASH_MUTED}render${RST}     substituting the 25 config templates
    ${ASH_MUTED}write${RST}      writing the fragments and their backups

  Each stage is run --repeat times; the fastest run is reported, not the mean,
  because a mean is dominated by scheduling noise on a busy desktop.

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--repeat, -r N${RST}     Runs per stage (default 5)
  ${ASH_MUTED}--all${RST}              Benchmark a sample of the catalogue instead
  ${ASH_MUTED}--sample N${RST}         How many themes for --all (default 25)
  ${ASH_MUTED}--derive${RST}           Include the palette-derivation stage
  ${ASH_MUTED}--json${RST}             Machine-readable output

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ${ASH_MUTED}ash theme benchmark nord${RST}
  ${ASH_MUTED}ash theme benchmark nord -r 20 --derive${RST}
  ${ASH_MUTED}ash theme benchmark --all --sample 50${RST}
EOF
}

# Milliseconds since the epoch. `date +%s%N` is GNU; on a system without
# nanosecond support the value ends in literal "N", so fall back to seconds.
theme::benchmark::now_ms() {
    local n
    n="$(date +%s%N 2>/dev/null || printf '')"
    if [[ "$n" =~ ^[0-9]+$ && ${#n} -gt 10 ]]; then
        printf '%s' "$(( n / 1000000 ))"
    else
        printf '%s000' "$(date +%s 2>/dev/null || printf '0')"
    fi
}

theme::benchmark() {
    local want="" repeat=5 all=0 sample=25 derive=0 json=0

    while (( $# )); do
        case "$1" in
            --repeat|-r)  repeat="${2:-5}"; shift 2 ;;
            --all)        all=1; shift ;;
            --sample)     sample="${2:-25}"; shift 2 ;;
            --derive)     derive=1; shift ;;
            --json)       json=1; export ASH_FLAG_JSON_OUTPUT=1; shift ;;
            -h|--help)    theme::benchmark::help; return 0 ;;
            -*)           ash_log_error "Unknown option: $1"; theme::benchmark::help; return 2 ;;
            *)            want="$1"; shift ;;
        esac
    done

    [[ "$repeat" =~ ^[0-9]+$ ]] && (( repeat > 0 )) || {
        ash_log_error "--repeat takes a positive number"; return 2; }
    [[ "$sample" =~ ^[0-9]+$ ]] || { ash_log_error "--sample takes a number"; return 2; }

    # ── Collect the themes to measure ─────────────────────────────────────────
    local -a targets=()
    if (( all )); then
        local slug
        while IFS=$'\t' read -r slug _rest; do
            [[ -n "$slug" ]] || continue
            targets+=("$slug")
            (( ${#targets[@]} >= sample )) && break
        done < <(theme::index)
        (( ${#targets[@]} )) || { ash_log_error "No themes found"; return 1; }
    else
        [[ -n "$want" ]] || want="$(theme::current 2>/dev/null || true)"
        if [[ -z "$want" ]]; then
            # The default lives in reset.sh, which may not be loaded yet.
            theme::source_sub reset >/dev/null 2>&1 || true
            if declare -F theme::reset::default >/dev/null 2>&1; then
                want="$(theme::reset::default 2>/dev/null || true)"
            fi
        fi
        [[ -n "$want" ]] || { ash_log_error "Which theme should I benchmark?"; theme::benchmark::help; return 2; }
        theme::resolve "$want" >/dev/null 2>&1 || { ash_log_error "No such theme: $want"; return 1; }
        targets=("$want")
    fi

    # ── Timing helper ─────────────────────────────────────────────────────────
    # Usage: _t <label> <command…>. Records the FASTEST of $repeat runs.
    local -A timings=()
    local -a order=()

    _bench() {
        local label="$1"; shift
        local best="" i t0 t1 dt
        for (( i = 0; i < repeat; i++ )); do
            t0="$(theme::benchmark::now_ms)"
            "$@" >/dev/null 2>&1 || true
            t1="$(theme::benchmark::now_ms)"
            dt=$(( t1 - t0 ))
            (( dt < 0 )) && dt=0
            if [[ -z "$best" ]] || (( dt < best )); then best="$dt"; fi
        done
        timings["$label"]="$best"
    }

    local file
    file="$(theme::resolve "${targets[0]}")"
    local -A pal=()

    _bench resolve theme::resolve "${targets[0]}"
    order+=(resolve)

    _bench load theme::load "$file" pal
    order+=(load)

    if (( derive )) && declare -f ash_palette_derive >/dev/null 2>&1; then
        local seed
        seed="$(jq -r '.seed // (.colors.accent // .accent) // "#8fbcbb"' "$file" 2>/dev/null)"
        [[ -n "$seed" ]] && _bench derive ash_palette_derive pal "$seed" dark
        order+=(derive)
    fi

    # ── Render and write, measured with the real engine ───────────────────────
    theme::load "$file" pal
    local -a tpl_files=()
    local t
    for t in "$THEME_TEMPLATE_DIR"/*.template; do [[ -f "$t" ]] && tpl_files+=("$t"); done

    if (( ${#tpl_files[@]} )); then
        local render_one
        render_one() {
            ash_tpl_reset 2>/dev/null || true
            local k
            for k in "${!pal[@]}"; do ash_tpl_set "$k" "${pal[$k]}" 2>/dev/null || true; done
            local f
            for f in "${tpl_files[@]}"; do ash_tpl_render_file "$f" >/dev/null 2>&1 || true; done
        }
        _bench render render_one
        order+=(render)
    fi

    local out
    out="$(mktemp -d -t ash-bench.XXXXXX)"
    local write_one
    write_one() {
        local f
        for f in "${tpl_files[@]}"; do
            ash_tpl_render_to "$f" "$out/$(basename "${f%.template}")" >/dev/null 2>&1 || true
        done
    }
    if declare -f ash_tpl_render_to >/dev/null 2>&1 && (( ${#tpl_files[@]} )); then
        _bench write write_one
        order+=(write)
    fi
    rm -rf "$out"

    local dist
    dist="$(theme::index | wc -l | tr -d ' ')"
    _bench index theme::index
    order+=(index)

    if [[ "$json" == "1" ]]; then
        local obj='{}'
        local k
        for k in "${order[@]}"; do
            obj="$(jq -c --arg k "$k" --argjson v "${timings[$k]:-0}" '. + {($k): $v}' <<<"$obj")"
        done
        jq -n --argjson stages "$obj" --argjson repeat "$repeat" \
              --argjson themes "${#targets[@]}" --argjson catalogue "$dist" \
              --arg theme "${targets[0]}" \
              '{theme: $theme, repeats: $repeat, themes_measured: $themes,
                catalogue_size: $catalogue, stages_ms: $stages,
                total_ms: ($stages | to_entries | map(.value) | add // 0)}'
        return 0
    fi

    ash_banner "⏱  THEME BENCHMARK" "${#targets[@]} theme(s), best of ${repeat}" 80

    local total=0 k v
    for k in "${order[@]}"; do
        v="${timings[$k]:-0}"
        total=$(( total + v ))
    done

    local max=1
    for k in "${order[@]}"; do (( ${timings[$k]:-0} > max )) && max="${timings[$k]}"; done

    for k in "${order[@]}"; do
        v="${timings[$k]:-0}"
        local width=$(( v * 30 / max ))
        (( width < 1 && v > 0 )) && width=1
        local bar=""
        local i
        for (( i = 0; i < width; i++ )); do bar+='▇'; done
        printf '    %-9s %s%5d ms%s  %s%s%s\n' "$k" "${ASH_ACCENT}" "$v" "${RST}" "${ASH_MUTED}" "$bar" "${RST}"
    done

    printf '\n    %s%-9s %5d ms%s\n' "${BOLD}" "total" "$total" "${RST}"
    printf '  %sCatalogue sweep of %s: %s ms%s\n\n' \
        "${ASH_MUTED}" "$(theme::plural "$dist" theme)" "${timings[index]:-0}" "${RST}"
}
