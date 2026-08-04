#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA ◆ DOCTOR REPORT                                              ║
# ║  Rich diagnostic report generation — JSON | HTML | Markdown | terminal               ║
# ╚══════════════════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

doctor::report::help() {
    local w; w=$(tput cols 2>/dev/null || echo 80)
    ash_banner "📋  ASH DOCTOR REPORT" \
        "Generate rich diagnostic reports in multiple formats" "${w}"
    cat <<EOF
${BOLD}${ASH_PRIMARY}USAGE${RST}
  ash doctor report [options]

${BOLD}${ASH_PRIMARY}OPTIONS${RST}
  ${ASH_MUTED}--format, -F FORMAT${RST}   Output format: terminal|json|html|markdown (default: terminal)
  ${ASH_MUTED}--output, -o PATH${RST}     Write to file (default: stdout)
  ${ASH_MUTED}--from-last${RST}           Use last saved doctor run (no re-scan)
  ${ASH_MUTED}--full${RST}                Run full audit before generating report
  ${ASH_MUTED}--category,  -c CAT${RST}  Include only this category
  ${ASH_MUTED}--issues-only${RST}         Include only failed/warning items
  ${ASH_MUTED}--include-pass${RST}        Include all passed checks (verbose)
  ${ASH_MUTED}--open${RST}               Open generated report in browser (HTML only)
  ${ASH_MUTED}--quiet,     -q${RST}       Suppress progress output
  ${ASH_MUTED}--help,      -h${RST}        Show this help

${BOLD}${ASH_PRIMARY}FORMATS${RST}
  ${ASH_ACCENT}terminal${RST}   Rich colored terminal output (default)
  ${ASH_ACCENT}json${RST}       Machine-readable JSON with full metadata
  ${ASH_ACCENT}html${RST}       Self-contained HTML with CSS styling & charts
  ${ASH_ACCENT}markdown${RST}   GitHub-flavored Markdown

${BOLD}${ASH_PRIMARY}EXAMPLES${RST}
  ash doctor report
  ash doctor report --format json --output ~/ash-health.json
  ash doctor report --format html --output ~/ash-health.html --open
  ash doctor report --format markdown --from-last
  ash doctor report --full --format json > /tmp/full-audit.json
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# § RENDERERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Terminal ───────────────────────────────────────────────────────────────────
_report::terminal() {
    local issues_only="$1" cat_filter="$2" include_pass="$3"

    local mode="full"
    [[ "${issues_only}" == "true" ]]  && mode="issues-only"
    [[ "${include_pass}" == "true" ]] && mode="full"

    doc::render_results "${mode}" "${cat_filter}"
    doc::render_summary "$(cat "${DOC_STATE_DIR}/.elapsed" 2>/dev/null || echo 0)"
}

# ── JSON ───────────────────────────────────────────────────────────────────────
_report::json() {
    local issues_only="$1" cat_filter="$2"

    # Use persisted results
    if [[ -f "${DOC_LAST_RUN_FILE}" ]]; then
        if [[ -n "${cat_filter}" ]] || [[ "${issues_only}" == "true" ]]; then
            local jq_filter='.results[]'
            [[ -n "${cat_filter}" ]] && \
                jq_filter+=" | select(.category == \"${cat_filter}\")"
            [[ "${issues_only}" == "true" ]] && \
                jq_filter+=' | select(.severity == "WARN" or .severity == "FAIL" or .severity == "CRIT")'

            local meta; meta=$(jq '{timestamp,score,grade,hostname,ash_version,summary}' \
                "${DOC_LAST_RUN_FILE}" 2>/dev/null)
            local filtered; filtered=$(jq -c "[${jq_filter}]" "${DOC_LAST_RUN_FILE}" 2>/dev/null)

            printf '%s\n' "${meta}" | jq --argjson r "${filtered}" '. + {results: $r}'
        else
            jq '.' "${DOC_LAST_RUN_FILE}"
        fi
    else
        # Build from current DOC_RESULTS
        doc::save_results
        cat "${DOC_LAST_RUN_FILE}"
    fi
}

# ── Markdown ───────────────────────────────────────────────────────────────────
_report::markdown() {
    local issues_only="$1" cat_filter="$2"
    local score; score=$(doc::health_score)
    local grade; grade=$(doc::health_grade "${score}")
    local now; now=$(date '+%Y-%m-%d %H:%M:%S')
    local host; host=$(hostname -s 2>/dev/null || echo unknown)

    printf '# 🩺 ASH Dotfiles Health Report\n\n'
    printf '**Generated:** %s  \n' "${now}"
    printf '**Host:** %s  \n' "${host}"
    printf '**ASH Version:** %s  \n\n' "${DOC_VERSION}"

    printf '## 📊 Health Score\n\n'
    printf '| Metric | Value |\n'
    printf '|--------|-------|\n'
    printf '| Score | **%d / 100** |\n' "${score}"
    printf '| Grade | **%s** |\n' "${grade}"
    printf '| ✓ Passed | %d |\n' "${DOC_PASS_COUNT}"
    printf '| ⚠ Warnings | %d |\n' "${DOC_WARN_COUNT}"
    printf '| ✗ Failed | %d |\n' "${DOC_FAIL_COUNT}"
    printf '| ☠ Critical | %d |\n' "${DOC_CRIT_COUNT}"
    printf '| ─ Skipped | %d |\n\n' "${DOC_SKIP_COUNT}"

    local prev_cat=""
    for entry in "${DOC_RESULTS[@]}"; do
        IFS='|' read -r sev cat id title msg fix <<< "${entry}"
        [[ -n "${cat_filter}" ]] && [[ "${cat}" != "${cat_filter}" ]] && continue
        if [[ "${issues_only}" == "true" ]]; then
            [[ "${sev}" == "${SEV_PASS}" ]] && continue
            [[ "${sev}" == "${SEV_INFO}" ]] && continue
            [[ "${sev}" == "${SEV_SKIP}" ]] && continue
        fi

        if [[ "${cat}" != "${prev_cat}" ]]; then
            prev_cat="${cat}"
            local cat_label=""
            for cdef in "${DOC_CATEGORIES[@]}"; do
                local ck="${cdef%%:*}" cl="${cdef#*:}"
                [[ "${ck}" == "${cat}" ]] && { cat_label="${cl}"; break; }
            done
            printf '\n## %s\n\n' "${cat_label:-${cat}}"
            printf '| Status | Check | Message | Fix |\n'
            printf '|--------|-------|---------|-----|\n'
        fi

        local badge
        case "${sev}" in
            PASS) badge="✅" ;; INFO) badge="ℹ️" ;;
            WARN) badge="⚠️" ;; FAIL) badge="❌" ;;
            CRIT) badge="☠️" ;; SKIP) badge="➖" ;;
        esac

        printf '| %s %s | %s | %s | `%s` |\n' \
            "${badge}" "${sev}" "${title}" "${msg}" "${fix:-—}"
    done

    printf '\n---\n'
    printf '_Generated by ASH Dotfiles v%s Doctor System_\n' "${DOC_VERSION}"
}

# ── HTML ───────────────────────────────────────────────────────────────────────
_report::html() {
    local issues_only="$1" cat_filter="$2"
    local score; score=$(doc::health_score)
    local grade; grade=$(doc::health_grade "${score}")
    local now; now=$(date '+%Y-%m-%d %H:%M:%S')
    local host; host=$(hostname -s 2>/dev/null || echo unknown)

    # Score colour
    local score_hex
    if   (( score >= 90 )); then score_hex="#a6e3a1"
    elif (( score >= 70 )); then score_hex="#f9e2af"
    elif (( score >= 50 )); then score_hex="#fab387"
    else                         score_hex="#f38ba8"
    fi

    # Collect category data for chart
    local chart_data=""
    for cdef in "${DOC_CATEGORIES[@]}"; do
        local ck="${cdef%%:*}"
        local cat_pass=0 cat_warn=0 cat_fail=0
        for entry in "${DOC_RESULTS[@]}"; do
            IFS='|' read -r sev cat _ _ _ _ <<< "${entry}"
            [[ "${cat}" != "${ck}" ]] && continue
            case "${sev}" in
                PASS) (( cat_pass++ )) ;;
                WARN) (( cat_warn++ )) ;;
                FAIL|CRIT) (( cat_fail++ )) ;;
            esac
        done
        (( cat_pass + cat_warn + cat_fail > 0 )) && \
            chart_data+="[\"${ck}\",${cat_pass},${cat_warn},${cat_fail}],"
    done
    chart_data="${chart_data%,}"

    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ASH Doctor Report — ${host}</title>
  <style>
    :root {
      --bg:       #1e1e2e;
      --surface:  #313244;
      --overlay:  #45475a;
      --text:     #cdd6f4;
      --subtext:  #a6adc8;
      --blue:     #89b4fa;
      --mauve:    #cba6f7;
      --green:    #a6e3a1;
      --yellow:   #f9e2af;
      --peach:    #fab387;
      --red:      #f38ba8;
      --teal:     #94e2d5;
      --lavender: #b4befe;
      --radius:   12px;
      --shadow:   0 4px 24px rgba(0,0,0,0.4);
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'JetBrains Mono', 'Cascadia Code', monospace;
      font-size: 14px;
      line-height: 1.6;
      padding: 2rem;
    }
    h1, h2, h3 { font-weight: 700; }
    a { color: var(--blue); text-decoration: none; }

    /* ── Header ─────────────────────────────────────── */
    .header {
      background: linear-gradient(135deg, var(--surface) 0%, var(--overlay) 100%);
      border-radius: var(--radius);
      padding: 2rem;
      margin-bottom: 2rem;
      border: 1px solid var(--overlay);
      box-shadow: var(--shadow);
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 1rem;
    }
    .header h1 { font-size: 1.8rem; color: var(--blue); }
    .header .meta { color: var(--subtext); font-size: 0.85rem; }

    /* ── Score gauge ────────────────────────────────── */
    .score-card {
      background: var(--surface);
      border-radius: var(--radius);
      padding: 1.5rem;
      margin-bottom: 2rem;
      display: flex;
      align-items: center;
      gap: 2rem;
      border: 1px solid var(--overlay);
      box-shadow: var(--shadow);
    }
    .gauge-ring {
      position: relative;
      width: 120px;
      height: 120px;
      flex-shrink: 0;
    }
    .gauge-ring svg { width: 120px; height: 120px; transform: rotate(-90deg); }
    .gauge-ring .track { fill: none; stroke: var(--overlay); stroke-width: 10; }
    .gauge-ring .fill  { fill: none; stroke: ${score_hex}; stroke-width: 10;
                         stroke-linecap: round;
                         stroke-dasharray: calc(${score} * 3.14159 * 2) 999;
                         transition: stroke-dasharray 1s ease; }
    .gauge-center {
      position: absolute; inset: 0;
      display: flex; flex-direction: column;
      align-items: center; justify-content: center;
    }
    .gauge-score { font-size: 1.8rem; font-weight: 900; color: ${score_hex}; }
    .gauge-grade { font-size: 0.9rem; color: var(--subtext); }
    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(80px, 1fr)); gap: 1rem; flex: 1; }
    .stat-item { text-align: center; }
    .stat-num  { font-size: 1.5rem; font-weight: 700; }
    .stat-lbl  { font-size: 0.75rem; color: var(--subtext); }
    .s-pass  { color: var(--green); }
    .s-info  { color: var(--teal); }
    .s-warn  { color: var(--yellow); }
    .s-fail  { color: var(--peach); }
    .s-crit  { color: var(--red); }
    .s-skip  { color: var(--overlay); }

    /* ── Category sections ──────────────────────────── */
    .category { margin-bottom: 1.5rem; }
    .cat-header {
      background: var(--surface);
      border-left: 4px solid var(--blue);
      border-radius: 0 var(--radius) var(--radius) 0;
      padding: 0.6rem 1rem;
      margin-bottom: 0.5rem;
      font-weight: 700;
      color: var(--blue);
    }
    .check-table { width: 100%; border-collapse: collapse; }
    .check-table th {
      background: var(--surface); padding: 0.5rem 0.75rem;
      text-align: left; color: var(--subtext); font-size: 0.8rem;
      text-transform: uppercase; letter-spacing: 0.05em;
    }
    .check-table td { padding: 0.5rem 0.75rem; border-bottom: 1px solid var(--surface); }
    .check-table tr:last-child td { border-bottom: none; }
    .check-table tr:hover td { background: rgba(255,255,255,0.03); }
    .badge {
      display: inline-block; padding: 0.15rem 0.5rem;
      border-radius: 4px; font-size: 0.75rem; font-weight: 700;
      font-variant-numeric: tabular-nums;
    }
    .badge-PASS { background: rgba(166,227,161,0.15); color: var(--green); }
    .badge-INFO { background: rgba(148,226,213,0.15); color: var(--teal); }
    .badge-WARN { background: rgba(249,226,175,0.15); color: var(--yellow); }
    .badge-FAIL { background: rgba(250,179,135,0.15); color: var(--peach); }
    .badge-CRIT { background: rgba(243,139,168,0.15); color: var(--red); }
    .badge-SKIP { background: rgba(69,71,90,0.4);      color: var(--subtext); }
    .fix-cmd {
      font-size: 0.8rem; color: var(--mauve);
      background: rgba(203,166,247,0.1);
      padding: 0.1rem 0.4rem; border-radius: 4px;
    }

    /* ── Footer ─────────────────────────────────────── */
    .footer { margin-top: 3rem; text-align: center; color: var(--subtext); font-size: 0.8rem; }

    /* ── Animations ─────────────────────────────────── */
    @keyframes fadeIn { from { opacity:0; transform:translateY(10px); } to { opacity:1; transform:none; } }
    .category { animation: fadeIn 0.3s ease both; }
    .category:nth-child(2) { animation-delay: 0.05s; }
    .category:nth-child(3) { animation-delay: 0.10s; }
    .category:nth-child(4) { animation-delay: 0.15s; }
  </style>
</head>
<body>

<div class="header">
  <div>
    <h1>🩺 ASH Health Report</h1>
    <p class="meta">Host: ${host} &nbsp;•&nbsp; Generated: ${now} &nbsp;•&nbsp; ASH v${DOC_VERSION}</p>
  </div>
</div>

<div class="score-card">
  <div class="gauge-ring">
    <svg viewBox="0 0 36 36">
      <circle class="track" cx="18" cy="18" r="15.9"/>
      <circle class="fill"  cx="18" cy="18" r="15.9"/>
    </svg>
    <div class="gauge-center">
      <span class="gauge-score">${score}</span>
      <span class="gauge-grade">${grade}</span>
    </div>
  </div>
  <div class="stats-grid">
    <div class="stat-item"><div class="stat-num s-pass">${DOC_PASS_COUNT}</div><div class="stat-lbl">PASSED</div></div>
    <div class="stat-item"><div class="stat-num s-info">${DOC_INFO_COUNT}</div><div class="stat-lbl">INFO</div></div>
    <div class="stat-item"><div class="stat-num s-warn">${DOC_WARN_COUNT}</div><div class="stat-lbl">WARNINGS</div></div>
    <div class="stat-item"><div class="stat-num s-fail">${DOC_FAIL_COUNT}</div><div class="stat-lbl">FAILED</div></div>
    <div class="stat-item"><div class="stat-num s-crit">${DOC_CRIT_COUNT}</div><div class="stat-lbl">CRITICAL</div></div>
    <div class="stat-item"><div class="stat-num s-skip">${DOC_SKIP_COUNT}</div><div class="stat-lbl">SKIPPED</div></div>
  </div>
</div>

EOF

    # ── Check table by category ────────────────────────────────────────────────
    local prev_cat=""
    local first_cat=true

    for entry in "${DOC_RESULTS[@]}"; do
        IFS='|' read -r sev cat id title msg fix <<< "${entry}"

        [[ -n "${cat_filter}" ]] && [[ "${cat}" != "${cat_filter}" ]] && continue
        if [[ "${issues_only}" == "true" ]]; then
            [[ "${sev}" == "${SEV_PASS}" ]] && continue
            [[ "${sev}" == "${SEV_INFO}" ]] && continue
            [[ "${sev}" == "${SEV_SKIP}" ]] && continue
        fi

        if [[ "${cat}" != "${prev_cat}" ]]; then
            # Close previous category
            [[ "${first_cat}" == "false" ]] && printf '    </tbody>\n  </table>\n</div>\n'
            first_cat=false
            prev_cat="${cat}"

            local cat_label=""
            for cdef in "${DOC_CATEGORIES[@]}"; do
                local ck="${cdef%%:*}" cl="${cdef#*:}"
                [[ "${ck}" == "${cat}" ]] && { cat_label="${cl}"; break; }
            done

            cat <<EOF
<div class="category">
  <div class="cat-header">${cat_label:-${cat}}</div>
  <table class="check-table">
    <thead>
      <tr>
        <th style="width:90px">Status</th>
        <th>Check</th>
        <th>Message</th>
        <th>Fix</th>
      </tr>
    </thead>
    <tbody>
EOF
        fi

        local fix_html=""
        [[ -n "${fix}" ]] && \
            fix_html="<code class=\"fix-cmd\">${fix}</code>"

        printf '      <tr>\n'
        printf '        <td><span class="badge badge-%s">%s</span></td>\n' "${sev}" "${sev}"
        printf '        <td>%s</td>\n' "${title}"
        printf '        <td>%s</td>\n' "${msg}"
        printf '        <td>%s</td>\n' "${fix_html}"
        printf '      </tr>\n'
    done

    [[ "${first_cat}" == "false" ]] && \
        printf '    </tbody>\n  </table>\n</div>\n'

    cat <<EOF

<div class="footer">
  Generated by <strong>ASH Dotfiles v${DOC_VERSION}</strong> Doctor System &nbsp;•&nbsp;
  <a href="https://github.com/ash-dotfiles">github.com/ash-dotfiles</a>
</div>

</body>
</html>
EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
doctor::report() {
    local format="terminal" output="" cat_filter=""
    local from_last=false full_scan=false
    local issues_only=false include_pass=false
    local open_browser=false quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)         doctor::report::help; return 0 ;;
            --format|-F)       format="${2:?'--format requires FORMAT'}"; shift 2 ;;
            --output|-o)       output="${2:?'--output requires PATH'}"; shift 2 ;;
            --category|-c)     cat_filter="${2:?'--category requires value'}"; shift 2 ;;
            --from-last)       from_last=true; shift ;;
            --full)            full_scan=true; shift ;;
            --issues-only)     issues_only=true; shift ;;
            --include-pass)    include_pass=true; shift ;;
            --open)            open_browser=true; shift ;;
            --quiet|-q)        quiet=true; shift ;;
            -*)                log::error "Unknown option: $1"; return 1 ;;
            *)                 shift ;;
        esac
    done

    # ── Populate DOC_RESULTS ───────────────────────────────────────────────────
    if [[ "${from_last}" == "true" ]]; then
        # Rebuild from JSON
        if [[ ! -f "${DOC_LAST_RUN_FILE}" ]]; then
            log::error "No last doctor run found."
            return 1
        fi
        while IFS= read -r entry; do
            local sev cat id title msg fix
            sev=$(printf '%s' "${entry}"   | jq -r '.severity')
            cat=$(printf '%s' "${entry}"   | jq -r '.category')
            id=$(printf '%s' "${entry}"    | jq -r '.id')
            title=$(printf '%s' "${entry}" | jq -r '.title')
            msg=$(printf '%s' "${entry}"   | jq -r '.message')
            fix=$(printf '%s' "${entry}"   | jq -r '.fix // ""')
            doc::result "${sev}" "${cat}" "${id}" "${title}" "${msg}" "${fix}"
        done < <(jq -c '.results[]' "${DOC_LAST_RUN_FILE}" 2>/dev/null)
    else
        # Run appropriate scan
        if [[ "${full_scan}" == "true" ]]; then
            [[ "${quiet}" == "false" ]] && log::info "Running full audit…"
            DOC_CATEGORY_FILTER="${cat_filter}"
            source "${_DOC_DIR}/full.sh"
            doctor::full --no-summary --compact >/dev/null 2>&1 || true
        else
            [[ "${quiet}" == "false" ]] && log::info "Running quick scan…"
            DOC_CATEGORY_FILTER="${cat_filter}"
            source "${_DOC_DIR}/quick.sh"
            doctor::quick --no-summary --compact >/dev/null 2>&1 || true
        fi
    fi

    # ── Generate report ────────────────────────────────────────────────────────
    local rendered=""
    case "${format,,}" in
        terminal|term)
            if [[ -n "${output}" ]]; then
                # Strip ANSI for file output
                rendered=$(_report::terminal "${issues_only}" "${cat_filter}" \
                    "${include_pass}" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
            else
                _report::terminal "${issues_only}" "${cat_filter}" "${include_pass}"
                return 0
            fi
            ;;
        json)
            rendered=$(_report::json "${issues_only}" "${cat_filter}")
            ;;
        html)
            rendered=$(_report::html "${issues_only}" "${cat_filter}")
            ;;
        markdown|md)
            rendered=$(_report::markdown "${issues_only}" "${cat_filter}")
            ;;
        *)
            log::error "Unknown format: '${format}'"
            log::info  "Supported: terminal json html markdown"
            return 1
            ;;
    esac

    # ── Output ────────────────────────────────────────────────────────────────
    if [[ -n "${output}" ]]; then
        mkdir -p "$(dirname "${output}")"
        printf '%s\n' "${rendered}" > "${output}"
        local size; size=$(du -sh "${output}" 2>/dev/null | awk '{print $1}')
        local score; score=$(doc::health_score)
        local grade; grade=$(doc::health_grade "${score}")

        [[ "${quiet}" == "false" ]] && {
            log::blank
            log::success "Report generated"
            printf '  %s%-12s%s %s%s%s\n'  "${ASH_MUTED}" "File"   "${RST}" "${ASH_ACCENT}" "${output}"  "${RST}"
            printf '  %s%-12s%s %s%s%s\n'  "${ASH_MUTED}" "Format" "${RST}" "${SNAP_COLOR_NAME}" "${format}" "${RST}"
            printf '  %s%-12s%s %s%s%s\n'  "${ASH_MUTED}" "Size"   "${RST}" "${SNAP_COLOR_SIZE}" "${size}"   "${RST}"
            printf '  %s%-12s%s %s%d/100 (%s)%s\n' \
                "${ASH_MUTED}" "Score"  "${RST}" \
                "$(doc::score_color "${score}")" "${score}" "${grade}" "${RST}"
            log::blank
        }

        # Open in browser
        if [[ "${open_browser}" == "true" ]] && [[ "${format,,}" == "html" ]]; then
            local opener="xdg-open"
            command -v "${opener}" &>/dev/null && \
                "${opener}" "${output}" 2>/dev/null || \
                log::warn "Could not open browser — open manually: ${output}"
        fi
    else
        printf '%s\n' "${rendered}"
    fi

    doc::save_results
}
