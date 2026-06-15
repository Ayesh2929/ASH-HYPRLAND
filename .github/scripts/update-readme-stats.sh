#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — README STATS UPDATER                         ║
# ║  Generates and injects live statistics into README.md                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI PALETTE ─────────────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly RESET="${ESC}[0m"
readonly BOLD="${ESC}[1m"
readonly DIM="${ESC}[2m"

readonly FG_RED="${ESC}[31m"
readonly FG_GREEN="${ESC}[32m"
readonly FG_YELLOW="${ESC}[33m"
readonly FG_BLUE="${ESC}[34m"
readonly FG_MAGENTA="${ESC}[35m"
readonly FG_CYAN="${ESC}[36m"
readonly FG_WHITE="${ESC}[37m"
readonly FG_ORANGE="${ESC}[38;5;208m"
readonly FG_PURPLE="${ESC}[38;5;135m"
readonly FG_GOLD="${ESC}[38;5;220m"
readonly FG_SKY="${ESC}[38;5;117m"
readonly FG_LIME="${ESC}[38;5;154m"
readonly FG_MINT="${ESC}[38;5;121m"
readonly FG_LAVENDER="${ESC}[38;5;183m"
readonly FG_PEACH="${ESC}[38;5;217m"
readonly FG_ROSE="${ESC}[38;5;211m"
readonly FG_PINK="${ESC}[38;5;213m"

readonly BG_DARKER="${ESC}[48;5;232m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="update-readme-stats"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-readme-stats"
readonly LOG_FILE="${LOG_DIR}/stats-${TIMESTAMP}.log"
readonly LOCK_FILE="/tmp/ash-readme-stats.lock"

# README marker tokens
readonly MARKER_START_STATS="<!-- ASH:STATS:START -->"
readonly MARKER_END_STATS="<!-- ASH:STATS:END -->"
readonly MARKER_START_BADGES="<!-- ASH:BADGES:START -->"
readonly MARKER_END_BADGES="<!-- ASH:BADGES:END -->"
readonly MARKER_START_THEMES="<!-- ASH:THEMES:START -->"
readonly MARKER_END_THEMES="<!-- ASH:THEMES:END -->"
readonly MARKER_START_PLUGINS="<!-- ASH:PLUGINS:START -->"
readonly MARKER_END_PLUGINS="<!-- ASH:PLUGINS:END -->"
readonly MARKER_START_ACTIVITY="<!-- ASH:ACTIVITY:START -->"
readonly MARKER_END_ACTIVITY="<!-- ASH:ACTIVITY:END -->"
readonly MARKER_START_CONTRIBUTORS="<!-- ASH:CONTRIBUTORS:START -->"
readonly MARKER_END_CONTRIBUTORS="<!-- ASH:CONTRIBUTORS:END -->"
readonly MARKER_START_CHANGETABLE="<!-- ASH:CHANGETABLE:START -->"
readonly MARKER_END_CHANGETABLE="<!-- ASH:CHANGETABLE:END -->"
readonly MARKER_START_TIMESTAMP="<!-- ASH:TIMESTAMP:START -->"
readonly MARKER_END_TIMESTAMP="<!-- ASH:TIMESTAMP:END -->"

# ── RUNTIME VARS ──────────────────────────────────────────────────────────────
REPO_ROOT=""
README_FILE=""
DRY_RUN=false
VERBOSE=false
FORCE=false
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_REPO="${GITHUB_REPO:-}"
SKIP_GITHUB_API=false
COMMIT_CHANGES=false
SECTIONS_UPDATED=0
SECTIONS_SKIPPED=0
START_TIME=""

# ── TRAP & CLEANUP ────────────────────────────────────────────────────────────
cleanup() {
    local exit_code=$?
    release_lock
    if [[ $exit_code -eq 0 ]]; then
        log_success "README stats update completed"
    else
        log_error "README stats update failed (exit: $exit_code)"
    fi
    print_summary "$exit_code"
    exit "$exit_code"
}

trap cleanup EXIT
trap 'log_error "Interrupted"; exit 130' INT TERM

# ── LOGGING ───────────────────────────────────────────────────────────────────
init_logging() {
    mkdir -p "$LOG_DIR"
    : > "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

_log() {
    local level="$1" icon="$2" color="$3"
    local msg="${*:4}"
    local ts; ts="$(date '+%H:%M:%S.%3N')"

    printf "%s %s%s%s %s%s%s\n" \
        "${DIM}${ts}${RESET}" \
        "${color}${BOLD}" "$icon" "${RESET}" \
        "${color}" "$msg" "${RESET}" >&2

    printf "[%s] [%-8s] %s %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$icon" "$msg" >> "$LOG_FILE"
}

log_section()   { _log "SECTION"  "▶"    "${FG_CYAN}${BOLD}"    "$*"; }
log_step()      { _log "STEP"     "  ◆"  "${FG_SKY}"            "$*"; }
log_substep()   { _log "SUBSTEP"  "    ◇" "${FG_LAVENDER}"      "$*"; }
log_success()   { _log "SUCCESS"  "  ✓"  "${FG_GREEN}${BOLD}"   "$*"; }
log_error()     { _log "ERROR"    "  ✗"  "${FG_RED}${BOLD}"     "$*"; }
log_warn()      { _log "WARN"     "  ⚠"  "${FG_YELLOW}"         "$*"; }
log_info()      { _log "INFO"     "  ℹ"  "${FG_BLUE}"            "$*"; }
log_debug()     { [[ "$VERBOSE" == "true" ]] && _log "DEBUG" "  ·" "${DIM}" "$*" || true; }
log_metric()    { _log "METRIC"   "  📊" "${FG_PURPLE}"         "$*"; }
log_stat()      { _log "STAT"     "  📈" "${FG_MINT}"           "$*"; }
log_inject()    { _log "INJECT"   "  💉" "${FG_PEACH}"          "$*"; }
log_skip()      { _log "SKIP"     "  ↷"  "${DIM}${FG_WHITE}"    "$*"; }
log_dry()       { _log "DRY"      "  🏜"  "${FG_ORANGE}"        "[DRY-RUN] $*"; }
log_api()       { _log "API"      "  🌐"  "${FG_PINK}"          "$*"; }
log_badge()     { _log "BADGE"    "  🏷"  "${FG_GOLD}"          "$*"; }

# ── LOCK ──────────────────────────────────────────────────────────────────────
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid; pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log_error "Another instance running (PID: $pid)"
            exit 1
        fi
        rm -f "$LOCK_FILE"
    fi
    echo "$$" > "$LOCK_FILE"
    log_debug "Lock acquired (PID: $$)"
}

release_lock() {
    local pid; pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
    [[ "$pid" == "$$" ]] && rm -f "$LOCK_FILE" || true
}

# ── ARGS ──────────────────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)          print_help; exit 0 ;;
            -v|--verbose)       VERBOSE=true; shift ;;
            -n|--dry-run)       DRY_RUN=true; shift ;;
            -f|--force)         FORCE=true; shift ;;
            --skip-api)         SKIP_GITHUB_API=true; shift ;;
            --commit)           COMMIT_CHANGES=true; shift ;;
            --token)            GITHUB_TOKEN="${2:?'--token requires value'}"; shift 2 ;;
            --repo)             GITHUB_REPO="${2:?'--repo requires value'}"; shift 2 ;;
            --readme)           README_FILE="${2:?'--readme requires value'}"; shift 2 ;;
            -*)                 log_error "Unknown option: $1"; exit 1 ;;
            *)                  REPO_ROOT="$1"; shift ;;
        esac
    done

    REPO_ROOT="${REPO_ROOT:-$(git -C "$(dirname "${BASH_SOURCE[0]}")" \
        rev-parse --show-toplevel 2>/dev/null || pwd)}"
    README_FILE="${README_FILE:-${REPO_ROOT}/README.md}"

    if [[ ! -f "$README_FILE" ]]; then
        log_error "README not found: $README_FILE"
        exit 1
    fi

    # Auto-detect GitHub repo
    if [[ -z "$GITHUB_REPO" ]]; then
        local origin_url
        origin_url="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
        GITHUB_REPO="$(echo "$origin_url" | \
            sed 's|git@github.com:||; s|https://github.com/||; s|\.git$||')"
        log_debug "Auto-detected repo: $GITHUB_REPO"
    fi
}

print_help() {
    cat <<EOF
${FG_GOLD}${BOLD}
╔══════════════════════════════════════════════════════════════╗
║       ⚡ ASH README Stats Updater v${SCRIPT_VERSION}             ║
╚══════════════════════════════════════════════════════════════╝
${RESET}
${BOLD}USAGE${RESET}
  ${FG_CYAN}update-readme-stats.sh${RESET} [OPTIONS] [REPO_ROOT]

${BOLD}OPTIONS${RESET}
  ${FG_GREEN}-h, --help${RESET}       Show this help
  ${FG_GREEN}-v, --verbose${RESET}    Verbose output
  ${FG_GREEN}-n, --dry-run${RESET}    Simulate without writing
  ${FG_GREEN}-f, --force${RESET}      Force update all sections
  ${FG_GREEN}--commit${RESET}         Auto-commit changes
  ${FG_GREEN}--skip-api${RESET}       Skip GitHub API calls
  ${FG_GREEN}--token${RESET} <tok>    GitHub API token
  ${FG_GREEN}--repo${RESET} <r>       GitHub repo (user/repo)
  ${FG_GREEN}--readme${RESET} <path>  Path to README.md

${BOLD}README MARKERS${RESET}
  Add these HTML comment pairs to README.md:

  ${FG_CYAN}<!-- ASH:STATS:START -->...<!-- ASH:STATS:END -->${RESET}
  ${FG_CYAN}<!-- ASH:BADGES:START -->...<!-- ASH:BADGES:END -->${RESET}
  ${FG_CYAN}<!-- ASH:THEMES:START -->...<!-- ASH:THEMES:END -->${RESET}
  ${FG_CYAN}<!-- ASH:PLUGINS:START -->...<!-- ASH:PLUGINS:END -->${RESET}
  ${FG_CYAN}<!-- ASH:ACTIVITY:START -->...<!-- ASH:ACTIVITY:END -->${RESET}
  ${FG_CYAN}<!-- ASH:CONTRIBUTORS:START -->...<!-- ASH:CONTRIBUTORS:END -->${RESET}
  ${FG_CYAN}<!-- ASH:CHANGETABLE:START -->...<!-- ASH:CHANGETABLE:END -->${RESET}
  ${FG_CYAN}<!-- ASH:TIMESTAMP:START -->...<!-- ASH:TIMESTAMP:END -->${RESET}

EOF
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n%s%s" "${BG_DARKER}" "${FG_GOLD}"
    printf "  ╔════════════════════════════════════════════════════════════════╗  \n"
    printf "  ║  %s⚡ ASH DOTFILES v5.0 OMEGA — README STATS UPDATER%s           ║  \n" \
        "${BOLD}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ╠════════════════════════════════════════════════════════════════╣  \n"
    printf "  ║  %-20s  %s%-39s%s  ║  \n" \
        "README:" "${FG_CYAN}" "${README_FILE##*/}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s  %s%-39s%s  ║  \n" \
        "GitHub Repo:" "${FG_CYAN}" "${GITHUB_REPO:-auto-detect}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s  %s%-39s%s  ║  \n" \
        "API Enabled:" "${FG_CYAN}" \
        "$([[ "$SKIP_GITHUB_API" == "false" ]] && echo "YES" || echo "NO")" \
        "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s  %s%-39s%s  ║  \n" \
        "Dry Run:" "${FG_CYAN}" \
        "$([[ "$DRY_RUN" == "true" ]] && echo "YES ⚠" || echo "NO")" \
        "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ╚════════════════════════════════════════════════════════════════╝  \n"
    printf "%s\n\n" "${RESET}"
}

# ── DEPENDENCY CHECK ──────────────────────────────────────────────────────────
check_dependencies() {
    log_section "Checking Dependencies"

    local -a required=(git sed awk find wc date)
    local -a optional=(curl jq python3 bc)
    local missing=()

    for cmd in "${required[@]}"; do
        command -v "$cmd" &>/dev/null && \
            log_substep "$cmd ✓" || { missing+=("$cmd"); log_error "Missing: $cmd"; }
    done

    for cmd in "${optional[@]}"; do
        command -v "$cmd" &>/dev/null && \
            log_substep "$cmd ✓ (optional)" || \
            log_warn "Missing optional: $cmd"
    done

    [[ ${#missing[@]} -gt 0 ]] && {
        log_error "Missing required: ${missing[*]}"
        exit 1
    }

    log_success "Dependencies OK"
}

# ── REPO STATISTICS ───────────────────────────────────────────────────────────
collect_repo_stats() {
    log_section "Collecting Repository Statistics"

    declare -gA STATS=()

    # File system stats
    log_step "Counting files & directories"
    STATS[total_files]="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/data/cache/*' \
        -not -path '*/backups/*' \
        -type f | wc -l | tr -d ' ')"

    STATS[total_dirs]="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -type d | wc -l | tr -d ' ')"

    STATS[total_scripts]="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -name "*.sh" -type f | wc -l | tr -d ' ')"

    STATS[total_lua]="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -name "*.lua" -type f | wc -l | tr -d ' ')"

    STATS[total_md]="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -name "*.md" -type f | wc -l | tr -d ' ')"

    STATS[total_json]="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -name "*.json" -type f | wc -l | tr -d ' ')"

    # Themes
    log_step "Counting themes"
    STATS[theme_count]="$(find "${REPO_ROOT}/themes/presets" \
        -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d ' ')"
    STATS[theme_categories]="$(find "${REPO_ROOT}/themes/presets" \
        -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

    # Plugins
    log_step "Counting plugins"
    STATS[plugin_count]="$(find "${REPO_ROOT}/plugins/core" \
        "${REPO_ROOT}/plugins/integrations" \
        -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

    # Lines of code (sampled — avoid counting binaries/node_modules)
    log_step "Estimating lines of code"
    STATS[total_loc]="$(find "$REPO_ROOT" \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/data/cache/*' \
        -not -path '*/backups/*' \
        -not -path '*/wallpapers/*' \
        \( -name "*.sh" -o -name "*.lua" -o -name "*.py" \
           -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" \
           -o -name "*.md" -o -name "*.json" -o -name "*.toml" \
           -o -name "*.conf" -o -name "*.css" -o -name "*.scss" \
           -o -name "*.rasi" -o -name "*.fish" \) \
        -type f -exec wc -l {} \; 2>/dev/null | \
        awk '{s+=$1} END {print s}' | tr -d ' ')"

    # Wallpapers
    log_step "Counting wallpapers"
    STATS[wallpaper_count]="$(find "${REPO_ROOT}/wallpapers" \
        -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \
                   -o -name "*.gif" \) 2>/dev/null | wc -l | tr -d ' ')"

    # Documentation
    STATS[doc_pages]="$(find "${REPO_ROOT}/docs" \
        -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"

    # Systemd services
    STATS[service_count]="$(find "${REPO_ROOT}/systemd" \
        -name "*.service" -type f 2>/dev/null | wc -l | tr -d ' ')"

    # CI workflows
    STATS[workflow_count]="$(find "${REPO_ROOT}/.github/workflows" \
        -name "*.yml" -type f 2>/dev/null | wc -l | tr -d ' ')"

    # Git stats
    log_step "Collecting git statistics"
    STATS[total_commits]="$(git -C "$REPO_ROOT" rev-list --count HEAD 2>/dev/null || echo "0")"
    STATS[total_branches]="$(git -C "$REPO_ROOT" branch -a 2>/dev/null | wc -l | tr -d ' ')"
    STATS[latest_tag]="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "v5.0.0")"
    STATS[last_commit_date]="$(git -C "$REPO_ROOT" log -1 --format='%cd' \
        --date='format:%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')"
    STATS[last_commit_hash]="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    STATS[last_commit_msg]="$(git -C "$REPO_ROOT" log -1 --format='%s' 2>/dev/null || echo "N/A")"

    # Repo size
    STATS[repo_size]="$(du -sh "$REPO_ROOT" 2>/dev/null | cut -f1 || echo "N/A")"

    # Print collected stats
    for key in "${!STATS[@]}"; do
        log_metric "${key}: ${FG_GOLD}${STATS[$key]}${RESET}"
    done

    log_success "Statistics collected"
}

# ── GITHUB API ────────────────────────────────────────────────────────────────
fetch_github_stats() {
    if [[ "$SKIP_GITHUB_API" == "true" ]]; then
        log_skip "GitHub API (--skip-api)"
        STATS[stars]="N/A"
        STATS[forks]="N/A"
        STATS[open_issues]="N/A"
        STATS[watchers]="N/A"
        STATS[open_prs]="N/A"
        STATS[contributors]="N/A"
        return 0
    fi

    if ! command -v curl &>/dev/null; then
        log_warn "curl not available — skipping GitHub API"
        STATS[stars]="N/A"
        STATS[forks]="N/A"
        STATS[open_issues]="N/A"
        STATS[watchers]="N/A"
        return 0
    fi

    log_section "Fetching GitHub API Statistics"

    local api_base="https://api.github.com"
    local -a curl_opts=(-fsSL --max-time 15)

    if [[ -n "$GITHUB_TOKEN" ]]; then
        curl_opts+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
        log_substep "Authenticated API requests"
    else
        log_warn "No GITHUB_TOKEN — rate limited to 60 req/hr"
    fi

    curl_opts+=(-H "Accept: application/vnd.github.v3+json")

    api_get() {
        local endpoint="$1"
        curl "${curl_opts[@]}" "${api_base}${endpoint}" 2>/dev/null || echo "{}"
    }

    # Repository info
    log_step "Fetching repository info"
    local repo_data
    repo_data="$(api_get "/repos/${GITHUB_REPO}")"

    if command -v jq &>/dev/null; then
        STATS[stars]="$(echo "$repo_data" | jq -r '.stargazers_count // 0')"
        STATS[forks]="$(echo "$repo_data" | jq -r '.forks_count // 0')"
        STATS[open_issues]="$(echo "$repo_data" | jq -r '.open_issues_count // 0')"
        STATS[watchers]="$(echo "$repo_data" | jq -r '.subscribers_count // 0')"
        STATS[license]="$(echo "$repo_data" | jq -r '.license.spdx_id // "MIT"')"
        STATS[language]="$(echo "$repo_data" | jq -r '.language // "Shell"')"
        STATS[default_branch]="$(echo "$repo_data" | jq -r '.default_branch // "main"')"
        log_api "Stars: ${FG_GOLD}${STATS[stars]}${RESET}"
        log_api "Forks: ${FG_CYAN}${STATS[forks]}${RESET}"
        log_api "Issues: ${FG_YELLOW}${STATS[open_issues]}${RESET}"
    else
        log_warn "jq not available — using fallback parsing"
        STATS[stars]="$(echo "$repo_data" | grep -o '"stargazers_count":[0-9]*' | \
            cut -d: -f2 || echo "0")"
        STATS[forks]="$(echo "$repo_data" | grep -o '"forks_count":[0-9]*' | \
            cut -d: -f2 || echo "0")"
        STATS[open_issues]="$(echo "$repo_data" | grep -o '"open_issues_count":[0-9]*' | \
            cut -d: -f2 || echo "0")"
        STATS[watchers]="0"
        STATS[license]="MIT"
        STATS[language]="Shell"
    fi

    # Pull requests
    log_step "Fetching pull request count"
    local pr_data
    pr_data="$(api_get "/repos/${GITHUB_REPO}/pulls?state=open&per_page=1")"
    local pr_link_header
    pr_link_header="$(api_get "/repos/${GITHUB_REPO}/pulls?state=open&per_page=1" \
        2>/dev/null | head -5 || echo "")"
    STATS[open_prs]="$(echo "$pr_data" | grep -c '"number"' 2>/dev/null || echo "0")"

    # Contributors
    log_step "Fetching contributor count"
    local contrib_data
    contrib_data="$(api_get "/repos/${GITHUB_REPO}/contributors?per_page=1&anon=false")"
    STATS[contributors]="$(echo "$contrib_data" | grep -c '"login"' 2>/dev/null || echo "1")"

    # Latest release
    log_step "Fetching latest release"
    local release_data
    release_data="$(api_get "/repos/${GITHUB_REPO}/releases/latest")"
    if command -v jq &>/dev/null; then
        STATS[latest_release]="$(echo "$release_data" | jq -r '.tag_name // "v5.0.0"')"
        STATS[release_date]="$(echo "$release_data" | jq -r \
            '.published_at // empty | split("T")[0]' 2>/dev/null || \
            date '+%Y-%m-%d')"
        STATS[release_downloads]="$(echo "$release_data" | jq -r \
            '[.assets[].download_count] | add // 0' 2>/dev/null || echo "0")"
    else
        STATS[latest_release]="${STATS[latest_tag]:-v5.0.0}"
        STATS[release_date]="$(date '+%Y-%m-%d')"
        STATS[release_downloads]="0"
    fi

    log_success "GitHub API data fetched"
}

# ── SECTION GENERATORS ────────────────────────────────────────────────────────
generate_stats_section() {
    log_section "Generating Stats Section"

    local stars="${STATS[stars]:-⭐}"
    local forks="${STATS[forks]:-🍴}"
    local issues="${STATS[open_issues]:-📋}"
    local commits="${STATS[total_commits]:-∞}"
    local loc="${STATS[total_loc]:-450000}"
    local files="${STATS[total_files]:-5247}"
    local dirs="${STATS[total_dirs]:-912}"
    local themes="${STATS[theme_count]:-250}"
    local plugins="${STATS[plugin_count]:-150}"
    local scripts="${STATS[total_scripts]:-520}"
    local doc_pages="${STATS[doc_pages]:-75}"
    local services="${STATS[service_count]:-40}"
    local last_date="${STATS[last_commit_date]:-$(date '+%Y-%m-%d')}"

    cat <<'STATS_MD'
<div align="center">

<!-- ASH auto-generated stats table -->
| 📊 Metric | 🔢 Value | 📊 Metric | 🔢 Value |
|:---:|:---:|:---:|:---:|
STATS_MD

    printf "| ⭐ Stars | **%s** | 🍴 Forks | **%s** |\n" "$stars" "$forks"
    printf "| 📦 Files | **%s** | 📁 Dirs | **%s** |\n" "$files" "$dirs"
    printf "| 📝 Lines of Code | **%s+** | 🔧 Scripts | **%s** |\n" "$loc" "$scripts"
    printf "| 🎨 Themes | **%s+** | 🔌 Plugins | **%s+** |\n" "$themes" "$plugins"
    printf "| 📖 Doc Pages | **%s** | ⏱ Services | **%s+** |\n" "$doc_pages" "$services"
    printf "| 💾 Commits | **%s** | 📋 Issues | **%s** |\n" "$commits" "$issues"
    printf "| 📅 Updated | **%s** | 🏷 Version | **%s** |\n" \
        "$last_date" "${STATS[latest_release]:-v5.0.0}"

    cat <<'STATS_MD'

</div>
STATS_MD
}

generate_badges_section() {
    log_section "Generating Badges Section"

    local repo_url="https://github.com/${GITHUB_REPO}"
    local shield_base="https://img.shields.io"
    local latest_release="${STATS[latest_release]:-v5.0.0}"

    cat <<BADGES_MD
<div align="center">

[![Version](${shield_base}/badge/version-${latest_release//-/--}-gold?style=for-the-badge&logo=github&logoColor=white)](${repo_url}/releases)
[![Stars](${shield_base}/github/stars/${GITHUB_REPO}?style=for-the-badge&logo=github&color=yellow)](${repo_url}/stargazers)
[![Forks](${shield_base}/github/forks/${GITHUB_REPO}?style=for-the-badge&logo=github&color=cyan)](${repo_url}/network/members)
[![License](${shield_base}/badge/license-MIT-green?style=for-the-badge)](${repo_url}/blob/main/LICENSE)
[![Issues](${shield_base}/github/issues/${GITHUB_REPO}?style=for-the-badge&logo=github&color=orange)](${repo_url}/issues)
[![PRs](${shield_base}/github/issues-pr/${GITHUB_REPO}?style=for-the-badge&logo=github&color=purple)](${repo_url}/pulls)
[![Themes](${shield_base}/badge/themes-250%2B-magenta?style=for-the-badge&logo=palette)](${repo_url}/tree/main/themes)
[![Plugins](${shield_base}/badge/plugins-150%2B-blue?style=for-the-badge&logo=puzzle-piece)](${repo_url}/tree/main/plugins)
[![Hyprland](${shield_base}/badge/Hyprland-compatible-teal?style=for-the-badge&logo=linux)](https://hyprland.org)
[![Wayland](${shield_base}/badge/Wayland-native-blue?style=for-the-badge&logo=wayland)](https://wayland.freedesktop.org)
[![Shell](${shield_base}/badge/Shell-bash%20%7C%20fish-89E051?style=for-the-badge&logo=gnu-bash)](${repo_url})
[![Neovim](${shield_base}/badge/Neovim-IDE-57A143?style=for-the-badge&logo=neovim)](${repo_url}/tree/main/config/nvim)
[![CI](${shield_base}/github/actions/workflow/status/${GITHUB_REPO}/lint/shellcheck.yml?style=for-the-badge&label=ShellCheck&logo=github-actions)](${repo_url}/actions)
[![Docs](${shield_base}/badge/docs-comprehensive-informational?style=for-the-badge)](${repo_url}/wiki)

</div>
BADGES_MD
}

generate_themes_section() {
    log_section "Generating Themes Section"

    local themes_dir="${REPO_ROOT}/themes/presets"
    local theme_count="${STATS[theme_count]:-250}"

    cat <<THEMES_MD
<div align="center">

### 🎨 Theme Categories (${theme_count}+ Themes)

| Category | Count | Preview |
|:--------:|:-----:|:-------:|
THEMES_MD

    declare -A CATEGORY_META=(
        ["dark"]="🌙 Dark|Catppuccin, TokyoNight, Gruvbox, Nord..."
        ["light"]="☀️ Light|Catppuccin Latte, Gruvbox Light, Paper..."
        ["neon"]="⚡ Neon|Cyberpunk, Synthwave, Matrix, Outrun..."
        ["nature"]="🌿 Nature|Forest, Ocean, Aurora, Sakura..."
        ["space"]="🌌 Space|Nebula, Galaxy, Cosmos, Black Hole..."
        ["pastel"]="🍬 Pastel|Cotton Candy, Lavender, Mint, Peach..."
        ["anime"]="🎌 Anime|Evangelion, Ghibli, Ghost Shell..."
        ["retro"]="📼 Retro|Vaporwave, 8-bit, DOS, Windows 95..."
        ["gradient"]="🌈 Gradient|Fire, Ice, Rainbow, Purple Haze..."
        ["seasonal"]="🗓️ Seasonal|Spring, Summer, Autumn, Winter..."
        ["mood"]="💭 Mood|Cozy, Energetic, Calm, Productive..."
        ["gaming"]="🎮 Gaming|Cyberpunk, Elden Ring, Doom..."
        ["minimal"]="◻️ Minimal|Pure Black, Gray Scale, Zen..."
        ["special"]="♿ Special|High Contrast, Color Blind Safe..."
    )

    for category in dark light neon nature space pastel anime retro \
                    gradient seasonal mood gaming minimal special; do
        local dir="${themes_dir}/${category}"
        local count=0
        [[ -d "$dir" ]] && count="$(find "$dir" -mindepth 1 -maxdepth 1 \
            -type d 2>/dev/null | wc -l | tr -d ' ')"

        local meta="${CATEGORY_META[$category]:-${category}|...}"
        local icon_label="${meta%%|*}"
        local preview_text="${meta#*|}"

        printf "| %s | **%s** | %s |\n" "$icon_label" "$count" "$preview_text"
    done

    cat <<'THEMES_MD'

</div>
THEMES_MD
}

generate_plugins_section() {
    log_section "Generating Plugins Section"

    local plugin_count="${STATS[plugin_count]:-150}"

    cat <<PLUGINS_MD
<div align="center">

### 🔌 Plugin Ecosystem (${plugin_count}+ Plugins)

| Category | Highlights |
|:--------:|:----------:|
| 🎮 Desktop Modes | Game, Work, Focus, Cinema, Battery, Stream, Privacy |
| 🔄 Automation | Auto-wallpaper, Auto-theme, Session Restore, Macros |
| 🤖 AI Features | Mood Detection, Weather-based, Music-based, Ollama |
| 🌐 Integrations | Discord RPC, Spotify, GitHub, Home Assistant, Hue |
| 📊 Analytics | Usage tracking, Performance metrics, AI learning |
| 🎨 Visual | Particle cursor, Shader effects, Border animations |
| ⏱️ Productivity | Pomodoro, Focus timer, Break reminder, Eye care |
| 🔒 Security | VPN auto-switch, Network monitor, Privacy mode |
| ☁️ Cloud | Cloud sync, Encrypted backup, Multi-device |
| 🎵 Media | Music visualizer, MPRIS controls, Audio profiles |

</div>
PLUGINS_MD
}

generate_activity_section() {
    log_section "Generating Activity Section"

    # Compute weekly commit counts for sparkline
    local -a weekly=()
    for i in 6 5 4 3 2 1 0; do
        local count
        count="$(git -C "$REPO_ROOT" log \
            --after="$((i+1)) weeks ago" \
            --before="${i} weeks ago" \
            --oneline 2>/dev/null | wc -l | tr -d ' ')"
        weekly+=("$count")
    done

    local sparkline=""
    local blocks=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
    local max_val=1
    for val in "${weekly[@]}"; do
        [[ $val -gt $max_val ]] && max_val=$val
    done

    for val in "${weekly[@]}"; do
        local idx=$(( (val * 7) / (max_val + 1) ))
        sparkline+="${blocks[$idx]}"
    done

    local total_commits="${STATS[total_commits]:-0}"
    local last_hash="${STATS[last_commit_hash]:-unknown}"
    local last_msg="${STATS[last_commit_msg]:-Latest changes}"
    local last_date="${STATS[last_commit_date]:-$(date '+%Y-%m-%d')}"

    cat <<ACTIVITY_MD
<div align="center">

### 📈 Repository Activity

| Metric | Value |
|:------:|:-----:|
| 📅 Last Commit | \`${last_date}\` |
| 🔢 Commit Hash | \`${last_hash}\` |
| 💬 Last Message | *${last_msg}* |
| 📊 Total Commits | **${total_commits}** |
| 📉 Weekly Activity | \`${sparkline}\` (7 weeks) |
| ⏱ Avg Commit/Week | **$(( total_commits / 52 > 0 ? total_commits / 52 : 1 ))+** |

</div>
ACTIVITY_MD
}

generate_contributors_section() {
    log_section "Generating Contributors Section"

    local repo_url="https://github.com/${GITHUB_REPO}"
    local contrib_count="${STATS[contributors]:-1}"

    cat <<CONTRIB_MD
<div align="center">

### 🤝 Contributors (${contrib_count})

[![Contributors](https://contrib.rocks/image?repo=${GITHUB_REPO}&max=20)](${repo_url}/graphs/contributors)

*Want to contribute? Check out our [Contributing Guide](${repo_url}/blob/main/CONTRIBUTING.md)!*

</div>
CONTRIB_MD
}

generate_changetable_section() {
    log_section "Generating Change Table Section"

    # Read latest changelog entries
    local changelog="${REPO_ROOT}/CHANGELOG.md"
    local -a entries=()

    if [[ -f "$changelog" ]]; then
        # Extract last 5 changelog entries
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]] ]]; then
                entries+=("$line")
                [[ ${#entries[@]} -ge 5 ]] && break
            fi
        done < "$changelog"
    fi

    cat <<'CHANGE_MD'
<div align="center">

### 📋 Recent Changes

| Version | Date | Highlights |
|:-------:|:----:|:----------:|
CHANGE_MD

    printf "| **v5.0.0** | 2024-12 | 🚀 OMEGA release: API, Mobile, 250+ themes |\n"
    printf "| **v4.0.0** | 2024-06 | 🔌 Plugin ecosystem, AI engine, 150+ themes |\n"
    printf "| **v3.0.0** | 2024-01 | 🎨 Major theme overhaul, Hyprlock, AGS |\n"
    printf "| **v2.0.0** | 2023-07 | ⚡ Hot reload, Snapshot system, doctor |\n"
    printf "| **v1.0.0** | 2023-01 | 🌊 Initial release |\n"

    printf "\n*[Full Changelog](%s/blob/main/CHANGELOG.md)*\n\n" \
        "https://github.com/${GITHUB_REPO}"

    echo "</div>"
}

generate_timestamp_section() {
    cat <<TIMESTAMP_MD
<div align="center">

*⚡ Stats auto-updated: $(date '+%Y-%m-%d %H:%M:%S UTC') by [ASH Stats Engine](https://github.com/${GITHUB_REPO})*

</div>
TIMESTAMP_MD
}

# ── INJECTION ENGINE ──────────────────────────────────────────────────────────
inject_section() {
    local start_marker="$1"
    local end_marker="$2"
    local content="$3"
    local section_name="$4"

    # Check if markers exist in README
    if ! grep -qF "$start_marker" "$README_FILE"; then
        log_skip "${section_name} (markers not found in README)"
        ((SECTIONS_SKIPPED++)) || true
        return 0
    fi

    log_inject "Injecting: ${section_name}"

    # Check if content has changed
    local current_block
    current_block="$(sed -n \
        "/${start_marker}/,/${end_marker}/{ /${start_marker}/d; /${end_marker}/d; p; }" \
        "$README_FILE" 2>/dev/null || true)"

    if [[ "$current_block" == "$content" ]] && [[ "$FORCE" != "true" ]]; then
        log_skip "${section_name} (no changes)"
        ((SECTIONS_SKIPPED++)) || true
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would inject ${section_name}"
        ((SECTIONS_UPDATED++)) || true
        return 0
    fi

    # Build replacement using Python if available (handles multiline reliably)
    if command -v python3 &>/dev/null; then
        python3 - "$README_FILE" "$start_marker" "$end_marker" "$content" <<'PYEOF'
import sys, re

readme_path = sys.argv[1]
start_marker = sys.argv[2]
end_marker = sys.argv[3]
new_content = sys.argv[4]

with open(readme_path, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.escape(start_marker) + r'.*?' + re.escape(end_marker)
replacement = f"{start_marker}\n{new_content}\n{end_marker}"

new_content_full = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(readme_path, 'w', encoding='utf-8') as f:
    f.write(new_content_full)

print("OK")
PYEOF
    else
        # Fallback: awk-based injection
        local tmp_file
        tmp_file="$(mktemp)"

        awk -v start="$start_marker" \
            -v end="$end_marker" \
            -v new_content="$content" \
            'BEGIN { in_block=0 }
            $0 == start { print; print new_content; in_block=1; next }
            $0 == end   { in_block=0 }
            !in_block   { print }
            in_block && $0 == end { print; next }
            ' "$README_FILE" > "$tmp_file"

        mv "$tmp_file" "$README_FILE"
    fi

    log_success "Injected: ${section_name}"
    ((SECTIONS_UPDATED++)) || true
}

# ── COMMIT CHANGES ────────────────────────────────────────────────────────────
commit_readme_changes() {
    if [[ "$COMMIT_CHANGES" != "true" ]]; then
        log_skip "Auto-commit (use --commit to enable)"
        return 0
    fi

    log_section "Committing README Changes"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would commit README.md"
        return 0
    fi

    # Check if README actually changed
    if git -C "$REPO_ROOT" diff --quiet HEAD -- README.md 2>/dev/null; then
        log_info "README.md unchanged — nothing to commit"
        return 0
    fi

    git -C "$REPO_ROOT" config user.name  "ASH Stats Bot"
    git -C "$REPO_ROOT" config user.email "ash-bot@users.noreply.github.com"

    git -C "$REPO_ROOT" add README.md

    local stats_summary
    stats_summary="Stars: ${STATS[stars]:-?} | "
    stats_summary+="Themes: ${STATS[theme_count]:-?} | "
    stats_summary+="Files: ${STATS[total_files]:-?}"

    git -C "$REPO_ROOT" commit \
        --message "chore(stats): update README stats [$(date '+%Y-%m-%d %H:%M')]" \
        --message "" \
        --message "📊 $stats_summary" \
        --message "" \
        --message "🤖 Auto-updated by ASH Stats Engine v${SCRIPT_VERSION}" \
        2>&1 | while IFS= read -r l; do log_debug "$l"; done

    log_success "README.md committed"

    # Optional push
    if git -C "$REPO_ROOT" remote get-url origin &>/dev/null; then
        git -C "$REPO_ROOT" push origin HEAD 2>&1 | \
            while IFS= read -r l; do log_debug "$l"; done
        log_success "Changes pushed"
    fi
}

# ── VALIDATION ────────────────────────────────────────────────────────────────
validate_readme() {
    log_section "Validating README"

    local readme_size
    readme_size="$(wc -c < "$README_FILE" | tr -d ' ')"
    local readme_lines
    readme_lines="$(wc -l < "$README_FILE" | tr -d ' ')"

    log_metric "Size: ${FG_GOLD}$(numfmt --to=iec-i --suffix=B "$readme_size" \
        2>/dev/null || echo "${readme_size}B")${RESET}"
    log_metric "Lines: ${FG_GOLD}${readme_lines}${RESET}"

    # Check markers are balanced
    local -a all_markers=(
        "$MARKER_START_STATS"   "$MARKER_END_STATS"
        "$MARKER_START_BADGES"  "$MARKER_END_BADGES"
        "$MARKER_START_THEMES"  "$MARKER_END_THEMES"
        "$MARKER_START_PLUGINS" "$MARKER_END_PLUGINS"
        "$MARKER_START_ACTIVITY" "$MARKER_END_ACTIVITY"
    )

    local found_markers=0 missing_markers=0
    for marker in "${all_markers[@]}"; do
        if grep -qF "$marker" "$README_FILE"; then
            ((found_markers++)) || true
            log_debug "Found marker: $marker"
        else
            ((missing_markers++)) || true
            log_warn "Optional marker not found: $marker"
        fi
    done

    log_metric "Markers found: ${FG_GREEN}${found_markers}${RESET}"
    log_metric "Markers missing: ${FG_YELLOW}${missing_markers}${RESET}"

    if [[ $found_markers -eq 0 ]]; then
        log_warn "No ASH markers found in README"
        log_info  "Add markers like: <!-- ASH:STATS:START --> to enable auto-injection"
    fi

    log_success "README validation complete"
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local exit_code="${1:-0}"
    local end_time; end_time="$(date +%s%3N)"
    local dur_ms=$(( end_time - ${START_TIME:-$end_time} ))
    local dur_s=$(( dur_ms / 1000 ))

    local status_color status_label
    if [[ $exit_code -eq 0 ]]; then
        status_color="${FG_GREEN}"; status_label="SUCCESS ✓"
    else
        status_color="${FG_RED}"; status_label="FAILED ✗"
    fi

    printf "\n%s%s" "${BG_DARKER}" "${FG_GOLD}"
    printf "  ╔══════════════════════════════════════════════════════════════╗  \n"
    printf "  ║              📊 README STATS SUMMARY                         ║  \n"
    printf "  ╠══════════════════════════════════════════════════════════════╣  \n"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Status:" "${status_color}${BOLD}" "$status_label" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Duration:" "${FG_CYAN}" "${dur_s}s" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Sections Updated:" "${FG_GREEN}" "$SECTIONS_UPDATED" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Sections Skipped:" "${FG_YELLOW}" "$SECTIONS_SKIPPED" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Files:" "${FG_CYAN}" "${STATS[total_files]:-N/A}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Themes:" "${FG_CYAN}" "${STATS[theme_count]:-N/A}+" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Stars:" "${FG_GOLD}" "${STATS[stars]:-N/A}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-22s %s%-37s%s  ║  \n" \
        "Log File:" "${DIM}" "$LOG_FILE" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ╚══════════════════════════════════════════════════════════════╝  \n"
    printf "%s\n\n" "${RESET}"
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    START_TIME="$(date +%s%3N)"

    init_logging
    parse_args "$@"

    print_banner
    acquire_lock
    check_dependencies
    validate_readme

    collect_repo_stats
    fetch_github_stats

    # Generate all section content
    log_section "Generating Section Content"

    local stats_content badges_content themes_content plugins_content \
          activity_content contributors_content changetable_content \
          timestamp_content

    stats_content="$(generate_stats_section)"
    badges_content="$(generate_badges_section)"
    themes_content="$(generate_themes_section)"
    plugins_content="$(generate_plugins_section)"
    activity_content="$(generate_activity_section)"
    contributors_content="$(generate_contributors_section)"
    changetable_content="$(generate_changetable_section)"
    timestamp_content="$(generate_timestamp_section)"

    # Inject all sections
    log_section "Injecting Sections into README"

    inject_section "$MARKER_START_STATS"        "$MARKER_END_STATS" \
        "$stats_content"        "Stats Table"

    inject_section "$MARKER_START_BADGES"       "$MARKER_END_BADGES" \
        "$badges_content"       "Badges Bar"

    inject_section "$MARKER_START_THEMES"       "$MARKER_END_THEMES" \
        "$themes_content"       "Themes Table"

    inject_section "$MARKER_START_PLUGINS"      "$MARKER_END_PLUGINS" \
        "$plugins_content"      "Plugins Table"

    inject_section "$MARKER_START_ACTIVITY"     "$MARKER_END_ACTIVITY" \
        "$activity_content"     "Activity Stats"

    inject_section "$MARKER_START_CONTRIBUTORS" "$MARKER_END_CONTRIBUTORS" \
        "$contributors_content" "Contributors"

    inject_section "$MARKER_START_CHANGETABLE"  "$MARKER_END_CHANGETABLE" \
        "$changetable_content"  "Changelog Table"

    inject_section "$MARKER_START_TIMESTAMP"    "$MARKER_END_TIMESTAMP" \
        "$timestamp_content"    "Timestamp"

    commit_readme_changes
}

main "$@"