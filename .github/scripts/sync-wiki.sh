#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🌊 ASH DOTFILES v5.0 OMEGA — WIKI SYNC ENGINE                             ║
# ║  Syncs documentation to GitHub Wiki with full automation                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI PALETTE ─────────────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly RESET="${ESC}[0m"
readonly BOLD="${ESC}[1m"
readonly DIM="${ESC}[2m"
readonly ITALIC="${ESC}[3m"
readonly UNDERLINE="${ESC}[4m"
readonly BLINK="${ESC}[5m"

# Foreground
readonly FG_BLACK="${ESC}[30m"
readonly FG_RED="${ESC}[31m"
readonly FG_GREEN="${ESC}[32m"
readonly FG_YELLOW="${ESC}[33m"
readonly FG_BLUE="${ESC}[34m"
readonly FG_MAGENTA="${ESC}[35m"
readonly FG_CYAN="${ESC}[36m"
readonly FG_WHITE="${ESC}[37m"
readonly FG_ORANGE="${ESC}[38;5;208m"
readonly FG_PURPLE="${ESC}[38;5;135m"
readonly FG_PINK="${ESC}[38;5;213m"
readonly FG_LIME="${ESC}[38;5;154m"
readonly FG_GOLD="${ESC}[38;5;220m"
readonly FG_SKY="${ESC}[38;5;117m"
readonly FG_LAVENDER="${ESC}[38;5;183m"
readonly FG_PEACH="${ESC}[38;5;217m"
readonly FG_MINT="${ESC}[38;5;121m"
readonly FG_ROSE="${ESC}[38;5;211m"

# Background
readonly BG_BLACK="${ESC}[40m"
readonly BG_RED="${ESC}[41m"
readonly BG_GREEN="${ESC}[42m"
readonly BG_BLUE="${ESC}[44m"
readonly BG_MAGENTA="${ESC}[45m"
readonly BG_CYAN="${ESC}[46m"
readonly BG_WHITE="${ESC}[47m"
readonly BG_DARK="${ESC}[48;5;235m"
readonly BG_DARKER="${ESC}[48;5;232m"
readonly BG_NAVY="${ESC}[48;5;17m"
readonly BG_PURPLE="${ESC}[48;5;55m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly SCRIPT_NAME="sync-wiki"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-wiki-sync"
readonly LOG_FILE="${LOG_DIR}/sync-${TIMESTAMP}.log"
readonly LOCK_FILE="/tmp/ash-wiki-sync.lock"
readonly WIKI_CLONE_DIR="${TMPDIR:-/tmp}/ash-wiki-${TIMESTAMP}"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=5
readonly PARALLEL_JOBS=4

# ── RUNTIME VARS ──────────────────────────────────────────────────────────────
REPO_ROOT=""
WIKI_REPO=""
WIKI_BRANCH="master"
DRY_RUN=false
VERBOSE=false
FORCE=false
SKIP_VALIDATION=false
SKIP_INDEX=false
SKIP_SIDEBAR=false
SKIP_FOOTER=false
GENERATE_STATS=true
COMMIT_MESSAGE=""
PAGES_SYNCED=0
PAGES_SKIPPED=0
PAGES_FAILED=0
BYTES_TRANSFERRED=0
START_TIME=""
TEMP_DIRS=()
PIDS=()

# ── TRAP & CLEANUP ────────────────────────────────────────────────────────────
cleanup() {
    local exit_code=$?
    log_section "Cleanup"

    # Kill background jobs
    for pid in "${PIDS[@]:-}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            log_debug "Killed background PID: $pid"
        fi
    done

    # Remove temp directories
    for dir in "${TEMP_DIRS[@]:-}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log_debug "Removed temp dir: $dir"
        fi
    done

    # Remove wiki clone
    if [[ -d "$WIKI_CLONE_DIR" ]]; then
        rm -rf "$WIKI_CLONE_DIR"
        log_debug "Removed wiki clone: $WIKI_CLONE_DIR"
    fi

    # Release lock
    release_lock

    if [[ $exit_code -eq 0 ]]; then
        log_success "Wiki sync completed successfully"
    else
        log_error "Wiki sync failed with exit code: $exit_code"
    fi

    # Print summary
    print_summary "$exit_code"

    exit "$exit_code"
}

trap cleanup EXIT
trap 'log_error "Interrupted by user"; exit 130' INT TERM

# ── LOGGING ENGINE ────────────────────────────────────────────────────────────
init_logging() {
    mkdir -p "$LOG_DIR"
    : > "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

_log() {
    local level="$1"
    local icon="$2"
    local color="$3"
    local msg="${*:4}"
    local ts
    ts="$(date '+%H:%M:%S.%3N')"

    # Terminal output
    printf "%s %s%s%s %s%s%s\n" \
        "${DIM}${ts}${RESET}" \
        "${color}${BOLD}" \
        "$icon" \
        "${RESET}" \
        "${color}" \
        "$msg" \
        "${RESET}" >&2

    # File output (strip ANSI)
    printf "[%s] [%-7s] %s %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$level" \
        "$icon" \
        "$msg" >> "$LOG_FILE"
}

log_banner()    { _log "BANNER"  "$(get_random_sparkle)" "${FG_GOLD}${BOLD}"    "$*"; }
log_section()   { _log "SECTION" "▶" "${FG_CYAN}${BOLD}"    "$*"; }
log_step()      { _log "STEP"    "  ◆" "${FG_SKY}"          "$*"; }
log_substep()   { _log "SUBSTEP" "    ◇" "${FG_LAVENDER}"   "$*"; }
log_success()   { _log "SUCCESS" "  ✓" "${FG_GREEN}${BOLD}" "$*"; }
log_error()     { _log "ERROR"   "  ✗" "${FG_RED}${BOLD}"   "$*"; }
log_warn()      { _log "WARN"    "  ⚠" "${FG_YELLOW}"       "$*"; }
log_info()      { _log "INFO"    "  ℹ" "${FG_BLUE}"          "$*"; }
log_debug()     { [[ "$VERBOSE" == "true" ]] && _log "DEBUG" "  ·" "${DIM}" "$*" || true; }
log_metric()    { _log "METRIC"  "  📊" "${FG_PURPLE}"       "$*"; }
log_perf()      { _log "PERF"    "  ⚡" "${FG_LIME}"         "$*"; }
log_wiki()      { _log "WIKI"    "  📖" "${FG_MINT}"         "$*"; }
log_file()      { _log "FILE"    "  📄" "${FG_PEACH}"        "$*"; }
log_skip()      { _log "SKIP"    "  ↷" "${DIM}${FG_WHITE}"   "$*"; }
log_dry()       { _log "DRY"     "  🏜" "${FG_ORANGE}"       "[DRY-RUN] $*"; }

get_random_sparkle() {
    local sparkles=("✦" "✧" "★" "☆" "✨" "⚡" "🔥" "💫" "⭐" "🌟")
    echo "${sparkles[$((RANDOM % ${#sparkles[@]}))]}";
}

# ── LOCK MANAGEMENT ───────────────────────────────────────────────────────────
acquire_lock() {
    log_step "Acquiring process lock"

    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid
        lock_pid="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"

        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Another sync is running (PID: $lock_pid)"
            log_info  "Lock file: $LOCK_FILE"
            exit 1
        else
            log_warn "Stale lock found — removing"
            rm -f "$LOCK_FILE"
        fi
    fi

    echo "$$" > "$LOCK_FILE"
    log_success "Lock acquired (PID: $$)"
}

release_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local lock_pid
        lock_pid="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"
        if [[ "$lock_pid" == "$$" ]]; then
            rm -f "$LOCK_FILE"
            log_debug "Lock released"
        fi
    fi
}

# ── ARGUMENT PARSING ──────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)            print_help; exit 0 ;;
            -v|--verbose)         VERBOSE=true; shift ;;
            -n|--dry-run)         DRY_RUN=true; shift ;;
            -f|--force)           FORCE=true; shift ;;
            --skip-validation)    SKIP_VALIDATION=true; shift ;;
            --skip-index)         SKIP_INDEX=true; shift ;;
            --skip-sidebar)       SKIP_SIDEBAR=true; shift ;;
            --skip-footer)        SKIP_FOOTER=true; shift ;;
            --no-stats)           GENERATE_STATS=false; shift ;;
            --branch)             WIKI_BRANCH="${2:?'--branch requires a value'}"; shift 2 ;;
            --message|-m)         COMMIT_MESSAGE="${2:?'-m requires a value'}"; shift 2 ;;
            --repo)               WIKI_REPO="${2:?'--repo requires a value'}"; shift 2 ;;
            -*)                   log_error "Unknown option: $1"; print_help; exit 1 ;;
            *)                    REPO_ROOT="$1"; shift ;;
        esac
    done

    REPO_ROOT="${REPO_ROOT:-$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || pwd)}"

    if [[ -z "$WIKI_REPO" ]]; then
        # Auto-detect from git remote
        local origin_url
        origin_url="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
        if [[ -n "$origin_url" ]]; then
            # Transform: https://github.com/user/repo.git → https://github.com/user/repo.wiki.git
            WIKI_REPO="${origin_url%.git}.wiki.git"
            log_debug "Auto-detected wiki repo: $WIKI_REPO"
        fi
    fi

    if [[ -z "$WIKI_REPO" ]]; then
        log_error "Could not determine wiki repository URL"
        log_info  "Use --repo <url> to specify it manually"
        exit 1
    fi

    COMMIT_MESSAGE="${COMMIT_MESSAGE:-"docs: sync wiki $(date '+%Y-%m-%d %H:%M:%S') [automated]"}"
}

print_help() {
    cat <<EOF
${FG_GOLD}${BOLD}
╔══════════════════════════════════════════════════════════════╗
║          🌊 ASH Wiki Sync Engine v${SCRIPT_VERSION}              ║
╚══════════════════════════════════════════════════════════════╝
${RESET}
${BOLD}USAGE${RESET}
  ${FG_CYAN}sync-wiki.sh${RESET} [OPTIONS] [REPO_ROOT]

${BOLD}OPTIONS${RESET}
  ${FG_GREEN}-h, --help${RESET}           Show this help message
  ${FG_GREEN}-v, --verbose${RESET}        Enable verbose output
  ${FG_GREEN}-n, --dry-run${RESET}        Simulate without making changes
  ${FG_GREEN}-f, --force${RESET}          Force sync even if no changes detected
  ${FG_GREEN}-m, --message${RESET} <msg>  Custom commit message
  ${FG_GREEN}--repo${RESET} <url>         Wiki repository URL (auto-detected if omitted)
  ${FG_GREEN}--branch${RESET} <name>      Wiki branch (default: master)
  ${FG_GREEN}--skip-validation${RESET}    Skip markdown validation
  ${FG_GREEN}--skip-index${RESET}         Skip Home.md index generation
  ${FG_GREEN}--skip-sidebar${RESET}       Skip _Sidebar.md generation
  ${FG_GREEN}--skip-footer${RESET}        Skip _Footer.md generation
  ${FG_GREEN}--no-stats${RESET}           Skip stats page generation

${BOLD}EXAMPLES${RESET}
  ${DIM}# Basic sync${RESET}
  ${FG_CYAN}./sync-wiki.sh${RESET}

  ${DIM}# Dry run with verbose output${RESET}
  ${FG_CYAN}./sync-wiki.sh --dry-run --verbose${RESET}

  ${DIM}# Custom message and force sync${RESET}
  ${FG_CYAN}./sync-wiki.sh -m "docs: major update" --force${RESET}

  ${DIM}# Sync specific repo${RESET}
  ${FG_CYAN}./sync-wiki.sh --repo https://github.com/user/repo.wiki.git${RESET}

EOF
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n"
    printf "%s%s" "${BG_DARKER}" "${FG_GOLD}"
    printf "  ╔════════════════════════════════════════════════════════════════╗  \n"
    printf "  ║  %s🌊 ASH DOTFILES v5.0 OMEGA — WIKI SYNC ENGINE%s               ║  \n" \
        "${BOLD}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %s%s  %-60s%s  ║  \n" \
        "${DIM}" "${FG_LAVENDER}" "Intelligent Documentation Synchronization System" \
        "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ╠════════════════════════════════════════════════════════════════╣  \n"
    printf "  ║  %s%-20s%s %s%-41s%s  ║  \n" \
        "${FG_CYAN}" "Version:" "${RESET}${BG_DARKER}${FG_WHITE}" \
        "" "v${SCRIPT_VERSION}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %s%-20s%s %s%-41s%s  ║  \n" \
        "${FG_CYAN}" "Repository:" "${RESET}${BG_DARKER}${FG_WHITE}" \
        "" "${REPO_ROOT##*/}" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %s%-20s%s %s%-41s%s  ║  \n" \
        "${FG_CYAN}" "Wiki Branch:" "${RESET}${BG_DARKER}${FG_WHITE}" \
        "" "$WIKI_BRANCH" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %s%-20s%s %s%-41s%s  ║  \n" \
        "${FG_CYAN}" "Dry Run:" "${RESET}${BG_DARKER}${FG_WHITE}" \
        "" "$([[ "$DRY_RUN" == "true" ]] && echo "YES ⚠" || echo "NO")" \
        "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %s%-20s%s %s%-41s%s  ║  \n" \
        "${FG_CYAN}" "Started:" "${RESET}${BG_DARKER}${FG_WHITE}" \
        "" "$(date '+%Y-%m-%d %H:%M:%S')" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ╚════════════════════════════════════════════════════════════════╝  \n"
    printf "%s\n\n" "${RESET}"
}

# ── DEPENDENCY CHECKS ─────────────────────────────────────────────────────────
check_dependencies() {
    log_section "Checking Dependencies"

    local -a required=(git find sed awk date md5sum)
    local -a optional=(markdownlint prettier pandoc wc)
    local missing=()

    for cmd in "${required[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_substep "${cmd} $(command -v "$cmd")"
        else
            log_error "Missing required: $cmd"
            missing+=("$cmd")
        fi
    done

    for cmd in "${optional[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            log_substep "${cmd} ${DIM}(optional — available)${RESET}"
        else
            log_warn "Missing optional: $cmd"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        exit 1
    fi

    log_success "All required dependencies satisfied"
}

# ── GIT OPERATIONS ────────────────────────────────────────────────────────────
verify_git_repo() {
    log_section "Verifying Git Repository"

    if ! git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null; then
        log_error "Not a git repository: $REPO_ROOT"
        exit 1
    fi

    local current_branch dirty
    current_branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
    dirty="$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

    log_substep "Branch: ${FG_CYAN}${current_branch}${RESET}"
    log_substep "Dirty files: ${FG_YELLOW}${dirty}${RESET}"

    if [[ "$dirty" -gt 0 ]] && [[ "$FORCE" != "true" ]]; then
        log_warn "$dirty uncommitted changes detected"
        log_info  "Use --force to sync anyway"
    fi

    log_success "Repository verified: ${REPO_ROOT##*/}"
}

clone_wiki() {
    log_section "Cloning Wiki Repository"
    log_substep "URL: ${FG_CYAN}${WIKI_REPO}${RESET}"
    log_substep "Dir: ${FG_CYAN}${WIKI_CLONE_DIR}${RESET}"

    TEMP_DIRS+=("$WIKI_CLONE_DIR")

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would clone: $WIKI_REPO → $WIKI_CLONE_DIR"
        mkdir -p "$WIKI_CLONE_DIR"
        return 0
    fi

    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log_substep "Clone attempt ${attempt}/${MAX_RETRIES}"

        if git clone \
            --depth 1 \
            --branch "$WIKI_BRANCH" \
            --single-branch \
            "$WIKI_REPO" \
            "$WIKI_CLONE_DIR" \
            2>/dev/null; then
            log_success "Wiki cloned successfully"
            return 0
        fi

        log_warn "Clone attempt $attempt failed"

        if [[ $attempt -lt $MAX_RETRIES ]]; then
            log_info "Retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi

        ((attempt++))
    done

    # Wiki doesn't exist yet — initialize it
    log_warn "Wiki not found — initializing new wiki"
    mkdir -p "$WIKI_CLONE_DIR"
    git -C "$WIKI_CLONE_DIR" init -b "$WIKI_BRANCH"
    git -C "$WIKI_CLONE_DIR" remote add origin "$WIKI_REPO"
    log_success "Initialized fresh wiki repository"
}

# ── DOCS DISCOVERY ────────────────────────────────────────────────────────────
discover_docs() {
    log_section "Discovering Documentation"

    local docs_dir="${REPO_ROOT}/docs"

    if [[ ! -d "$docs_dir" ]]; then
        log_error "docs/ directory not found: $docs_dir"
        exit 1
    fi

    # Count files
    local total_md
    total_md="$(find "$docs_dir" -name "*.md" -type f | wc -l | tr -d ' ')"
    local total_size
    total_size="$(du -sh "$docs_dir" 2>/dev/null | cut -f1)"

    log_substep "Docs directory: ${FG_CYAN}${docs_dir}${RESET}"
    log_metric   "Markdown files: ${FG_GOLD}${total_md}${RESET}"
    log_metric   "Directory size: ${FG_GOLD}${total_size}${RESET}"

    log_success "Documentation discovered"
}

# ── MARKDOWN VALIDATION ───────────────────────────────────────────────────────
validate_markdown() {
    if [[ "$SKIP_VALIDATION" == "true" ]]; then
        log_skip "Markdown validation (--skip-validation)"
        return 0
    fi

    log_section "Validating Markdown"

    local docs_dir="${REPO_ROOT}/docs"
    local errors=0
    local warnings=0
    local checked=0

    while IFS= read -r -d '' file; do
        ((checked++)) || true
        local rel_path="${file#"$REPO_ROOT"/}"

        # Basic validation: check for broken internal links
        local broken_links=0
        while IFS= read -r link; do
            local target_file="${docs_dir}/${link%.md}.md"
            if [[ ! -f "$target_file" ]] && [[ "$link" != http* ]]; then
                log_debug "Potentially broken link in ${rel_path}: $link"
                ((broken_links++)) || true
                ((warnings++)) || true
            fi
        done < <(grep -oP '\[.+?\]\(\K[^)]+' "$file" 2>/dev/null || true)

        # Check for empty files
        if [[ ! -s "$file" ]]; then
            log_warn "Empty file: ${rel_path}"
            ((warnings++)) || true
        fi

        # Check for missing frontmatter (optional)
        if ! head -1 "$file" | grep -q '^#'; then
            log_debug "No H1 heading in: ${rel_path}"
        fi

        log_debug "Validated: $rel_path (broken_links=${broken_links})"
    done < <(find "$docs_dir" -name "*.md" -type f -print0)

    log_metric "Checked: ${FG_GOLD}${checked}${RESET} files"
    log_metric "Warnings: ${FG_YELLOW}${warnings}${RESET}"
    log_metric "Errors: ${FG_RED}${errors}${RESET}"

    if [[ $errors -gt 0 ]]; then
        log_error "Validation failed with $errors error(s)"
        exit 1
    fi

    if [[ $warnings -gt 0 ]]; then
        log_warn "$warnings warning(s) found — continuing"
    fi

    log_success "Markdown validation passed"
}

# ── WIKI PAGE PROCESSING ──────────────────────────────────────────────────────
process_page() {
    local src_file="$1"
    local docs_dir="${REPO_ROOT}/docs"
    local rel_path="${src_file#"$docs_dir"/}"

    # Flatten nested paths for GitHub Wiki (uses flat namespace)
    # docs/getting-started/installation.md → Getting-Started-Installation.md
    local wiki_name
    wiki_name="$(echo "${rel_path%.md}" | \
        sed 's|/|-|g' | \
        sed 's|-| |g' | \
        awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' | \
        sed 's| |-|g')"

    local wiki_file="${WIKI_CLONE_DIR}/${wiki_name}.md"

    log_debug "Processing: ${rel_path} → ${wiki_name}.md"

    # Compute checksum to detect changes
    local src_checksum
    src_checksum="$(md5sum "$src_file" 2>/dev/null | cut -d' ' -f1)"

    local existing_checksum=""
    if [[ -f "$wiki_file" ]]; then
        # Extract stored checksum from wiki footer comment
        existing_checksum="$(grep -oP '(?<=<!-- ash-checksum: )\w+(?= -->)' \
            "$wiki_file" 2>/dev/null || true)"
    fi

    if [[ "$src_checksum" == "$existing_checksum" ]] && [[ "$FORCE" != "true" ]]; then
        log_skip "${wiki_name}.md (unchanged)"
        ((PAGES_SKIPPED++)) || true
        echo "skipped"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would write: ${wiki_name}.md"
        ((PAGES_SYNCED++)) || true
        echo "synced"
        return 0
    fi

    # Transform content for GitHub Wiki format
    transform_page "$src_file" "$wiki_file" "$rel_path" "$wiki_name" "$src_checksum"

    ((PAGES_SYNCED++)) || true
    ((BYTES_TRANSFERRED += $(wc -c < "$wiki_file"))) || true

    log_file "Written: ${wiki_name}.md"
    echo "synced"
}

transform_page() {
    local src_file="$1"
    local dst_file="$2"
    local rel_path="$3"
    local wiki_name="$4"
    local checksum="$5"

    local content
    content="$(cat "$src_file")"

    # ── Transform internal links ──────────────────────────────────────────────
    # Convert [text](../other/page.md) → [[Other-Page|text]]
    content="$(echo "$content" | \
        sed -E 's|\[([^]]+)\]\(\.\.?/[^)]*?/([^/]+)\.md([^)]*)\)|\[[\2|\1\]\]|g' | \
        sed -E 's|\[([^]]+)\]\(([^/][^)]+)\.md([^)]*)\)|\[[\2|\1\]\]|g')"

    # Fix image paths — point to raw GitHub CDN
    local repo_url
    repo_url="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null | \
        sed 's|git@github.com:|https://github.com/|; s|\.git$||')"
    local raw_base="${repo_url/github.com/raw.githubusercontent.com}/main"

    content="$(echo "$content" | \
        sed -E "s|\!\[([^]]*)\]\(\.\./assets/([^)]+)\)|![\1](${raw_base}/assets/\2)|g")"

    # ── Add Wiki header ───────────────────────────────────────────────────────
    local header
    header="$(generate_page_header "$rel_path" "$wiki_name")"

    # ── Add Wiki footer ───────────────────────────────────────────────────────
    local footer
    footer="$(generate_page_footer "$checksum")"

    # ── Write transformed file ────────────────────────────────────────────────
    {
        echo "$header"
        echo ""
        echo "$content"
        echo ""
        echo "$footer"
    } > "$dst_file"
}

generate_page_header() {
    local rel_path="$1"
    local wiki_name="$2"
    local nav_breadcrumb
    nav_breadcrumb="$(generate_breadcrumb "$rel_path")"

    cat <<EOF
<!-- ash-wiki-header: auto-generated — do not edit manually -->
<div align="right">

${nav_breadcrumb}

</div>

---
EOF
}

generate_page_footer() {
    local checksum="$1"
    cat <<EOF

---

<div align="center">

*🌊 Auto-synced by [ASH Dotfiles Wiki Sync Engine](https://github.com) — v${SCRIPT_VERSION}*
*Last updated: $(date '+%Y-%m-%d %H:%M:%S UTC')*

</div>

<!-- ash-checksum: ${checksum} -->
<!-- ash-sync-version: ${SCRIPT_VERSION} -->
EOF
}

generate_breadcrumb() {
    local rel_path="$1"
    local parts
    IFS='/' read -ra parts <<< "${rel_path%.md}"

    local crumbs="[[Home]]"
    local accumulated=""

    for ((i = 0; i < ${#parts[@]} - 1; i++)); do
        local part="${parts[$i]}"
        accumulated="${accumulated:+${accumulated}-}$(echo "$part" | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' | \
            sed 's| |-|g')"
        local display
        display="$(echo "$part" | sed 's|-| |g' | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')"
        crumbs="${crumbs} » [[${accumulated}|${display}]]"
    done

    echo "$crumbs"
}

# ── SYNC DOCS ─────────────────────────────────────────────────────────────────
sync_docs() {
    log_section "Syncing Documentation Pages"

    local docs_dir="${REPO_ROOT}/docs"

    # Find all markdown files
    local -a md_files=()
    while IFS= read -r -d '' f; do
        md_files+=("$f")
    done < <(find "$docs_dir" -name "*.md" -type f -print0 | sort -z)

    local total="${#md_files[@]}"
    log_info "Found ${FG_GOLD}${total}${RESET} markdown files"

    local current=0
    for md_file in "${md_files[@]}"; do
        ((current++)) || true
        local pct=$(( (current * 100) / total ))
        print_progress "$current" "$total" "$pct" "${md_file##*/}"
        process_page "$md_file" > /dev/null
    done

    printf "\n"
    log_success "Documentation sync complete"
    log_metric   "Synced:  ${FG_GREEN}${PAGES_SYNCED}${RESET}"
    log_metric   "Skipped: ${FG_YELLOW}${PAGES_SKIPPED}${RESET}"
    log_metric   "Failed:  ${FG_RED}${PAGES_FAILED}${RESET}"
}

# ── PROGRESS BAR ──────────────────────────────────────────────────────────────
print_progress() {
    local current="$1"
    local total="$2"
    local pct="$3"
    local label="${4:-}"
    local bar_width=50
    local filled=$(( (pct * bar_width) / 100 ))
    local empty=$(( bar_width - filled ))

    local bar_filled bar_empty
    bar_filled="$(printf '%*s' "$filled" '' | tr ' ' '█')"
    bar_empty="$(printf '%*s' "$empty" '' | tr ' ' '░')"

    # Color gradient
    local color
    if [[ $pct -lt 33 ]]; then
        color="${FG_RED}"
    elif [[ $pct -lt 66 ]]; then
        color="${FG_YELLOW}"
    else
        color="${FG_GREEN}"
    fi

    printf "\r  %s%s%s%s%s %s%3d%%%s %s%s/%s%s %s%-30.30s%s" \
        "${color}${BOLD}" \
        "$bar_filled" \
        "${DIM}${FG_WHITE}" \
        "$bar_empty" \
        "${RESET}" \
        "${FG_GOLD}${BOLD}" \
        "$pct" \
        "${RESET}" \
        "${FG_CYAN}" \
        "$current" \
        "$total" \
        "${RESET}" \
        "${DIM}" \
        "$label" \
        "${RESET}" >&2
}

# ── SPECIAL WIKI PAGES ────────────────────────────────────────────────────────
generate_home_page() {
    if [[ "$SKIP_INDEX" == "true" ]]; then
        log_skip "Home page generation (--skip-index)"
        return 0
    fi

    log_section "Generating Home Page"

    local home_file="${WIKI_CLONE_DIR}/Home.md"
    local repo_name
    repo_name="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null | \
        sed 's|.*/||; s|\.git$||' || basename "$REPO_ROOT")"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would generate Home.md"
        return 0
    fi

    cat > "$home_file" <<EOF
<!-- ash-wiki-home: auto-generated — do not edit manually -->

<div align="center">

$(generate_ascii_art_md)

# 🌊 ${repo_name} Wiki

**The most comprehensive Hyprland dotfiles documentation**

[![Version](https://img.shields.io/badge/version-5.0.0--omega-gold?style=for-the-badge)](${WIKI_REPO%.wiki.git})
[![Themes](https://img.shields.io/badge/themes-250+-purple?style=for-the-badge)](Themes)
[![Plugins](https://img.shields.io/badge/plugins-150+-cyan?style=for-the-badge)](Plugins)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 🚀 Quick Navigation

| Section | Description |
|---------|-------------|
| [[Getting-Started-Installation\|⚡ Installation]] | Get up and running in minutes |
| [[Getting-Started-Quick-Start\|🎯 Quick Start]] | Essential commands and concepts |
| [[Guides-Theming-Deep-Dive\|🎨 Theming Guide]] | Deep dive into the theme engine |
| [[Reference-Ash-Cli-Reference\|📖 CLI Reference]] | Complete command reference |
| [[Guides-Plugin-Development\|🔌 Plugin Dev]] | Create your own plugins |
| [[Guides-Neovim-Ide-Guide\|📝 Neovim IDE]] | Full IDE configuration guide |
| [[Troubleshooting-Common-Issues\|🔧 Troubleshooting]] | Common issues and fixes |
| [[Contributing-Contributing\|🤝 Contributing]] | How to contribute |

---

## 📊 Repository Stats

$(generate_stats_table)

---

## 🗂️ Documentation Index

$(generate_toc_tree)

---

<div align="center">

*Auto-generated by ASH Wiki Sync Engine v${SCRIPT_VERSION}*
*$(date '+%Y-%m-%d %H:%M:%S UTC')*

</div>

<!-- ash-checksum: home-$(date +%s) -->
EOF

    log_success "Home.md generated"
}

generate_ascii_art_md() {
    cat <<'EOF'

    █████╗ ███████╗██╗ ██╗ ██████╗ ██████╗ ████████╗███████╗
██╔══██╗██╔════╝██║ ██║ ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝
███████║███████╗███████║ ██║ ██║██║ ██║ ██║ ███████╗
██╔══██║╚════██║██╔══██║ ██║ ██║██║ ██║ ██║ ╚════██║
██║ ██║███████║██║ ██║ ██████╔╝╚██████╔╝ ██║ ███████║
╚═╝ ╚═╝╚══════╝╚═╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝ ╚══════╝

text

EOF
}

generate_stats_table() {
    local docs_dir="${REPO_ROOT}/docs"
    local total_pages total_words total_size

    total_pages="$(find "$docs_dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
    total_words="$(find "$docs_dir" -name "*.md" -type f -exec cat {} \; 2>/dev/null | \
        wc -w | tr -d ' ')"
    total_size="$(du -sh "$docs_dir" 2>/dev/null | cut -f1)"

    cat <<EOF
| Metric | Value |
|--------|-------|
| 📄 Documentation Pages | ${total_pages} |
| 📝 Total Words | ${total_words} |
| 💾 Total Size | ${total_size} |
| 🎨 Themes | 250+ |
| 🔌 Plugins | 150+ |
| ⚡ CLI Commands | 115+ |
| 🌐 Distros Supported | 8 |
| 🤖 AI Features | 5 |
EOF
}

generate_toc_tree() {
    local docs_dir="${REPO_ROOT}/docs"
    local output=""
    local -A seen_dirs=()

    while IFS= read -r -d '' file; do
        local rel="${file#"$docs_dir"/}"
        local dir
        dir="$(dirname "$rel")"
        local base
        base="$(basename "$rel" .md)"

        # Emit directory header once
        if [[ "$dir" != "." ]] && [[ -z "${seen_dirs[$dir]+_}" ]]; then
            seen_dirs["$dir"]=1
            local dir_title
            dir_title="$(echo "$dir" | sed 's|-| |g; s|/| › |g' | \
                awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')"
            output+=$'\n'"### 📁 ${dir_title}"$'\n'
        fi

        # Wiki link
        local wiki_name
        wiki_name="$(echo "${rel%.md}" | \
            sed 's|/|-|g; s|-| |g' | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' | \
            sed 's| |-|g')"
        local display
        display="$(echo "$base" | sed 's|-| |g' | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')"

        output+="- [[${wiki_name}|${display}]]"$'\n'
    done < <(find "$docs_dir" -name "*.md" -type f -print0 | sort -z)

    echo "$output"
}

generate_sidebar() {
    if [[ "$SKIP_SIDEBAR" == "true" ]]; then
        log_skip "_Sidebar.md generation (--skip-sidebar)"
        return 0
    fi

    log_section "Generating Sidebar"

    local sidebar_file="${WIKI_CLONE_DIR}/_Sidebar.md"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would generate _Sidebar.md"
        return 0
    fi

    local docs_dir="${REPO_ROOT}/docs"

    cat > "$sidebar_file" <<EOF
<!-- ash-sidebar: auto-generated -->

## 🌊 ASH Dotfiles

**[[Home|🏠 Home]]**

---

### 🚀 Getting Started
$(generate_sidebar_section "$docs_dir/getting-started")

### 📚 Guides
$(generate_sidebar_section "$docs_dir/guides")

### 📖 Reference
$(generate_sidebar_section "$docs_dir/reference")

### 🔧 Troubleshooting
$(generate_sidebar_section "$docs_dir/troubleshooting")

### 🤝 Contributing
$(generate_sidebar_section "$docs_dir/contributing")

### 📋 Changelog
$(generate_sidebar_section "$docs_dir/changelog")

---

*[⭐ Star on GitHub](${WIKI_REPO%.wiki.git})*

EOF

    log_success "_Sidebar.md generated"
}

generate_sidebar_section() {
    local section_dir="$1"

    if [[ ! -d "$section_dir" ]]; then
        echo "*(no pages)*"
        return 0
    fi

    local output=""
    while IFS= read -r -d '' file; do
        local base
        base="$(basename "$file" .md)"
        local rel="${file#"${REPO_ROOT}/docs"/}"

        local wiki_name
        wiki_name="$(echo "${rel%.md}" | \
            sed 's|/|-|g; s|-| |g' | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' | \
            sed 's| |-|g')"
        local display
        display="$(echo "$base" | sed 's|-| |g' | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')"

        output+="- [[${wiki_name}|${display}]]"$'\n'
    done < <(find "$section_dir" -name "*.md" -type f -print0 | sort -z)

    echo "${output:-*(no pages)*}"
}

generate_footer() {
    if [[ "$SKIP_FOOTER" == "true" ]]; then
        log_skip "_Footer.md generation (--skip-footer)"
        return 0
    fi

    log_section "Generating Footer"

    local footer_file="${WIKI_CLONE_DIR}/_Footer.md"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would generate _Footer.md"
        return 0
    fi

    local repo_url
    repo_url="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null | \
        sed 's|git@github.com:|https://github.com/|; s|\.git$||' || true)"

    cat > "$footer_file" <<EOF
<!-- ash-footer: auto-generated -->

---

<div align="center">

**🌊 ASH Dotfiles v5.0 OMEGA** •
[GitHub](${repo_url}) •
[Issues](${repo_url}/issues) •
[Discussions](${repo_url}/discussions) •
[License](${repo_url}/blob/main/LICENSE)

*Built with ❤️ by the ASH community*

</div>
EOF

    log_success "_Footer.md generated"
}

generate_stats_page() {
    if [[ "$GENERATE_STATS" != "true" ]]; then
        log_skip "Stats page generation (--no-stats)"
        return 0
    fi

    log_section "Generating Stats Page"

    local stats_file="${WIKI_CLONE_DIR}/Stats.md"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would generate Stats.md"
        return 0
    fi

    local docs_dir="${REPO_ROOT}/docs"
    local total_files total_words total_lines largest_file

    total_files="$(find "$docs_dir" -name "*.md" -type f | wc -l | tr -d ' ')"
    total_words="$(find "$docs_dir" -name "*.md" -type f -exec cat {} \; 2>/dev/null | \
        wc -w | tr -d ' ')"
    total_lines="$(find "$docs_dir" -name "*.md" -type f -exec cat {} \; 2>/dev/null | \
        wc -l | tr -d ' ')"
    largest_file="$(find "$docs_dir" -name "*.md" -type f -exec wc -c {} \; 2>/dev/null | \
        sort -rn | head -1 | awk '{print $2}' | xargs basename 2>/dev/null || echo "N/A")"

    cat > "$stats_file" <<EOF
<!-- ash-stats: auto-generated -->

# 📊 Documentation Statistics

> Auto-generated: $(date '+%Y-%m-%d %H:%M:%S UTC')

## 📄 Content Metrics

| Metric | Value |
|--------|-------|
| Total Pages | **${total_files}** |
| Total Words | **${total_words}** |
| Total Lines | **${total_lines}** |
| Largest File | **${largest_file}** |
| Last Synced | **$(date '+%Y-%m-%d %H:%M:%S UTC')** |
| Sync Version | **v${SCRIPT_VERSION}** |

## 📈 Pages Synced This Run

| Status | Count |
|--------|-------|
| ✅ Synced | ${PAGES_SYNCED} |
| ⏭️ Skipped | ${PAGES_SKIPPED} |
| ❌ Failed | ${PAGES_FAILED} |

## 🗂️ Section Breakdown

$(generate_section_breakdown "$docs_dir")

EOF

    log_success "Stats.md generated"
}

generate_section_breakdown() {
    local docs_dir="$1"

    local output="| Section | Pages | Words |"$'\n'
    output+="| ------- | ----- | ----- |"$'\n'

    for section_dir in "$docs_dir"/*/; do
        [[ -d "$section_dir" ]] || continue
        local section_name
        section_name="$(basename "$section_dir" | sed 's|-| |g' | \
            awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')"
        local page_count
        page_count="$(find "$section_dir" -name "*.md" -type f | wc -l | tr -d ' ')"
        local word_count
        word_count="$(find "$section_dir" -name "*.md" -type f -exec cat {} \; 2>/dev/null | \
            wc -w | tr -d ' ')"

        output+="| ${section_name} | ${page_count} | ${word_count} |"$'\n'
    done

    echo "$output"
}

# ── GIT COMMIT & PUSH ─────────────────────────────────────────────────────────
commit_and_push() {
    log_section "Committing & Pushing Changes"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry "Would commit: \"$COMMIT_MESSAGE\""
        log_dry "Would push to: $WIKI_BRANCH"
        return 0
    fi

    local -g _git_author_name _git_author_email
    _git_author_name="ASH Wiki Sync Engine"
    _git_author_email="ash-bot@users.noreply.github.com"

    # Configure git identity for this repo
    git -C "$WIKI_CLONE_DIR" config user.name  "$_git_author_name"
    git -C "$WIKI_CLONE_DIR" config user.email "$_git_author_email"

    # Check if there are changes
    local status
    status="$(git -C "$WIKI_CLONE_DIR" status --porcelain 2>/dev/null)"

    if [[ -z "$status" ]] && [[ "$FORCE" != "true" ]]; then
        log_info "No changes detected in wiki — nothing to commit"
        return 0
    fi

    log_substep "Staging all changes"
    git -C "$WIKI_CLONE_DIR" add --all

    # Show diff stats
    local diff_stats
    diff_stats="$(git -C "$WIKI_CLONE_DIR" diff --cached --stat 2>/dev/null | tail -1 || true)"
    if [[ -n "$diff_stats" ]]; then
        log_metric "Changes: ${FG_GOLD}${diff_stats}${RESET}"
    fi

    log_substep "Creating commit"
    git -C "$WIKI_CLONE_DIR" commit \
        --message "$COMMIT_MESSAGE" \
        --message "" \
        --message "📊 Sync Stats:" \
        --message "  • Pages synced:  ${PAGES_SYNCED}" \
        --message "  • Pages skipped: ${PAGES_SKIPPED}" \
        --message "  • Sync engine:   v${SCRIPT_VERSION}" \
        --message "" \
        --message "🤖 Generated by ASH Wiki Sync Engine" \
        2>&1 | while IFS= read -r line; do
            log_debug "$line"
        done

    log_substep "Pushing to ${WIKI_BRANCH}"
    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        if git -C "$WIKI_CLONE_DIR" push origin "$WIKI_BRANCH" 2>&1 | \
            while IFS= read -r line; do log_debug "$line"; done; then
            log_success "Changes pushed successfully"
            return 0
        fi

        log_warn "Push attempt $attempt failed"
        if [[ $attempt -lt $MAX_RETRIES ]]; then
            log_info "Retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi
        ((attempt++))
    done

    log_error "Failed to push after $MAX_RETRIES attempts"
    exit 1
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local exit_code="${1:-0}"
    local end_time
    end_time="$(date +%s%3N)"
    local duration_ms=$(( end_time - ${START_TIME:-$end_time} ))
    local duration_s=$(( duration_ms / 1000 ))
    local duration_ms_rem=$(( duration_ms % 1000 ))

    local status_color
    local status_label
    if [[ $exit_code -eq 0 ]]; then
        status_color="${FG_GREEN}"
        status_label="SUCCESS ✓"
    else
        status_color="${FG_RED}"
        status_label="FAILED ✗"
    fi

    printf "\n"
    printf "%s%s" "${BG_DARKER}" "${FG_GOLD}"
    printf "  ╔══════════════════════════════════════════════════════════════╗  \n"
    printf "  ║              📊 WIKI SYNC SUMMARY                           ║  \n"
    printf "  ╠══════════════════════════════════════════════════════════════╣  \n"
    printf "  ║  %-20s %s%-39s%s  ║  \n" \
        "Status:" "${status_color}${BOLD}" "$status_label" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s %s%-39s%s  ║  \n" \
        "Duration:" "${FG_CYAN}" "${duration_s}.${duration_ms_rem}s" \
        "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s %s%-39s%s  ║  \n" \
        "Pages Synced:" "${FG_GREEN}" "$PAGES_SYNCED" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s %s%-39s%s  ║  \n" \
        "Pages Skipped:" "${FG_YELLOW}" "$PAGES_SKIPPED" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s %s%-39s%s  ║  \n" \
        "Pages Failed:" "${FG_RED}" "$PAGES_FAILED" "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s %s%-39s%s  ║  \n" \
        "Data Transferred:" "${FG_PURPLE}" \
        "$(numfmt --to=iec-i --suffix=B "$BYTES_TRANSFERRED" 2>/dev/null || echo "${BYTES_TRANSFERRED}B")" \
        "${RESET}${BG_DARKER}${FG_GOLD}"
    printf "  ║  %-20s %s%-39s%s  ║  \n" \
        "Log File:" "${DIM}${FG_WHITE}" "$LOG_FILE" "${RESET}${BG_DARKER}${FG_GOLD}"
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
    verify_git_repo
    discover_docs
    validate_markdown
    clone_wiki
    generate_home_page
    generate_sidebar
    generate_footer
    sync_docs
    generate_stats_page
    commit_and_push
}

main "$@"