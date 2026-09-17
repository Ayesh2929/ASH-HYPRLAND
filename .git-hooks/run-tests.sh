#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🧪 ASH DOTFILES v5.0 OMEGA — ULTRA TEST RUNNER                            ║
# ║  Intelligent test execution — runs only what's needed, beautifully         ║
# ║  Unit · Integration · Schema · Lint · Performance · Security               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ── ANSI PALETTE ──────────────────────────────────────────────────────────────
readonly ESC=$'\033'
readonly R="${ESC}[0m";   readonly B="${ESC}[1m";   readonly D="${ESC}[2m"
readonly RED="${ESC}[31m";           readonly GREEN="${ESC}[32m"
readonly YELLOW="${ESC}[33m";        readonly CYAN="${ESC}[36m"
readonly WHITE="${ESC}[37m";         readonly ORANGE="${ESC}[38;5;208m"
readonly PURPLE="${ESC}[38;5;135m";  readonly LIME="${ESC}[38;5;154m"
readonly GOLD="${ESC}[38;5;220m";    readonly LAVENDER="${ESC}[38;5;183m"
readonly MINT="${ESC}[38;5;121m";    readonly PEACH="${ESC}[38;5;217m"
readonly ROSE="${ESC}[38;5;211m";    readonly TEAL="${ESC}[38;5;43m"
readonly CORAL="${ESC}[38;5;203m";   readonly CREAM="${ESC}[38;5;230m"
readonly SLATE="${ESC}[38;5;245m";   readonly AMBER="${ESC}[38;5;214m"
readonly EMERALD="${ESC}[38;5;120m"; readonly VIOLET="${ESC}[38;5;177m"
readonly CRIMSON="${ESC}[38;5;161m"; readonly INDIGO="${ESC}[38;5;105m"
readonly SKY="${ESC}[38;5;117m";     readonly OCEAN="${ESC}[38;5;38m"
readonly BG_MIDNIGHT="${ESC}[48;5;16m"
readonly BG_DARK="${ESC}[48;5;235m"
readonly BG_GREEN="${ESC}[48;5;22m"
readonly BG_RED="${ESC}[48;5;88m"

# ── CONSTANTS ─────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0-omega"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly TESTS_DIR="${REPO_ROOT}/tests"
readonly TERM_WIDTH="$(tput cols 2>/dev/null || echo 80)"
readonly SCRIPT_START_MS="$(date +%s%3N)"
readonly LOG_DIR="${TMPDIR:-/tmp}/ash-tests"
readonly LOG_FILE="${LOG_DIR}/run-$(date +%s).log"
readonly RESULTS_FILE="${LOG_DIR}/results-$(date +%s).json"

# Test timeouts
readonly UNIT_TIMEOUT=60
readonly INTEGRATION_TIMEOUT=180
readonly SCHEMA_TIMEOUT=30
readonly SECURITY_TIMEOUT=60

# ── STATE ─────────────────────────────────────────────────────────────────────
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TESTS_ERRORED=0
SUITES_RUN=0
SUITES_PASSED=0
SUITES_FAILED=0
declare -A SUITE_RESULTS=()
declare -A SUITE_TIMES=()
declare -a FAILED_TESTS=()
declare -a CHANGED_COMPONENTS=()
RUN_FULL=false
RUN_UNIT=true
RUN_INTEGRATION=false
RUN_SCHEMA=true
RUN_SECURITY=false
RUN_PERFORMANCE=false

# ── INIT ──────────────────────────────────────────────────────────────────────
init() {
    mkdir -p "$LOG_DIR"
    : > "$LOG_FILE"
    printf '{"version":"%s","start":"%s","suites":[]}' \
        "$SCRIPT_VERSION" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        > "$RESULTS_FILE"
}

now_ms()     { date +%s%3N; }
elapsed_ms() { echo $(( $(now_ms) - SCRIPT_START_MS )); }
format_dur() {
    local ms="$1"
    if   [[ $ms -lt 1000 ]];  then printf "%dms" "$ms"
    elif [[ $ms -lt 60000 ]]; then printf "%.1fs" "$(echo "scale=1; $ms/1000" | bc 2>/dev/null || echo "$((ms/1000))")"
    else                           printf "%.1fm" "$(echo "scale=1; $ms/60000" | bc 2>/dev/null || echo "$((ms/60000))")"
    fi
}

# ── RENDERING ─────────────────────────────────────────────────────────────────
hr() { printf "%s%s%s\n" "${1:-$D$SLATE}" \
    "$(printf '%*s' "${2:-$TERM_WIDTH}" '' | tr ' ' "${3:-─}")" "$R" >&2; }
box_t()  { printf "%s%s  ╔%s╗  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_d()  { printf "%s%s  ╠%s╣  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_td() { printf "%s%s  ╟%s╢  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '─')" "$R" >&2; }
box_b()  { printf "%s%s  ╚%s╝  %s\n" "$BG_MIDNIGHT" "$GOLD" \
    "$(printf '%*s' $(( TERM_WIDTH-4 )) '' | tr ' ' '═')" "$R" >&2; }
box_l()  {
    local c="$1"; local cl; cl="$(echo "$c" | sed 's/\x1b\[[0-9;]*m//g')"
    local p=$(( TERM_WIDTH-4-${#cl} )); [[ $p -lt 0 ]] && p=0
    printf "%s  ║ %s%*s║  %s\n" "$BG_MIDNIGHT$GOLD" "$c" "$p" "" "$R" >&2; }

section() {
    printf "\n" >&2; hr "${D}${SLATE}"
    printf "  %s %s%s%s\n" "$1" "${3:-$CYAN}${B}" "$2" "$R" >&2
    hr "${D}${SLATE}"
}

# ── TEST RESULT RENDERERS ──────────────────────────────────────────────────────
render_test() {
    local status="$1"    # pass|fail|skip|error
    local name="$2"
    local detail="${3:-}"
    local duration="${4:-}"

    local icon color label
    case "$status" in
        pass)  icon="✓" color="${GREEN}${B}"   label="PASS"  TESTS_PASSED=$((TESTS_PASSED + 1)) ;;
        fail)  icon="✗" color="${RED}${B}"     label="FAIL"  TESTS_FAILED=$((TESTS_FAILED + 1))
               FAILED_TESTS+=("${name}: ${detail}") ;;
        skip)  icon="↷" color="${SLATE}${D}"   label="SKIP"  TESTS_SKIPPED=$((TESTS_SKIPPED + 1)) ;;
        error) icon="!" color="${CRIMSON}${B}" label="ERROR" TESTS_ERRORED=$((TESTS_ERRORED + 1))
               FAILED_TESTS+=("${name}: ERROR: ${detail}") ;;
    esac

    TESTS_RUN=$((TESTS_RUN + 1))

    printf "    %s%s%s %-50s %s%-6s%s %s%s%s\n" \
        "${color}" "$icon " "$R" \
        "${D}${WHITE}${name}${R}" \
        "${color}" "$label" "$R" \
        "${D}${SLATE}" "${duration:+[$duration]}" "$R" >&2

    if [[ "$status" == "fail" ]] || [[ "$status" == "error" ]]; then
        if [[ -n "$detail" ]]; then
            echo "$detail" | head -5 | while IFS= read -r line; do
                printf "         %s│%s %s%s%s\n" \
                    "${color}${D}" "$R" "${D}" "$line" "$R" >&2
            done
        fi
    fi
}

# ── SUITE RUNNER ──────────────────────────────────────────────────────────────
run_suite() {
    local suite_name="$1"
    local suite_icon="$2"
    local suite_fn="$3"
    local suite_color="${4:-$CYAN}"

    ((SUITES_RUN++)) || true
    local t_start; t_start="$(now_ms)"

    printf "\n  %s %s%s%s\n" \
        "$suite_icon" "${suite_color}${B}" "$suite_name" "$R" >&2
    hr "${D}${SLATE}" $(( TERM_WIDTH - 4 ))

    local before_pass=$TESTS_PASSED
    local before_fail=$TESTS_FAILED
    local before_skip=$TESTS_SKIPPED

    local suite_exit=0
    "$suite_fn" || suite_exit=$?

    local after_pass=$(( TESTS_PASSED - before_pass ))
    local after_fail=$(( TESTS_FAILED - before_fail ))
    local after_skip=$(( TESTS_SKIPPED - before_skip ))
    local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"

    SUITE_TIMES["$suite_name"]="$dur"

    if [[ $after_fail -eq 0 ]] && [[ $suite_exit -eq 0 ]]; then
        ((SUITES_PASSED++)) || true
        SUITE_RESULTS["$suite_name"]="PASS"
        printf "\n    %s✓%s %s%-40s%s %s+%d -%d ↷%d%s %s[%s]%s\n" \
            "${GREEN}${B}" "$R" \
            "${suite_color}${B}" "$suite_name" "$R" \
            "${GREEN}" "$after_pass" "$after_fail" "$after_skip" "$R" \
            "${D}${SLATE}" "$dur" "$R" >&2
    else
        ((SUITES_FAILED++)) || true
        SUITE_RESULTS["$suite_name"]="FAIL"
        printf "\n    %s✗%s %s%-40s%s %s+%d -%d ↷%d%s %s[%s]%s\n" \
            "${RED}${B}" "$R" \
            "${suite_color}${B}" "$suite_name" "$R" \
            "${RED}" "$after_pass" "$after_fail" "$after_skip" "$R" \
            "${D}${SLATE}" "$dur" "$R" >&2
    fi
}

# ── CHANGE DETECTION ──────────────────────────────────────────────────────────
detect_changed_components() {
    section "🔍" "Detecting Changed Components" "$CYAN"

    local staged_files
    staged_files="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || \
                    git diff --name-only HEAD~1..HEAD 2>/dev/null || true)"

    [[ -z "$staged_files" ]] && { printf "  %sNo changed files detected%s\n" "$D" "$R" >&2; return 0; }

    # Component detection
    echo "$staged_files" | grep -qE '^ash-cli/'          && CHANGED_COMPONENTS+=("cli")
    echo "$staged_files" | grep -qE '^themes/'            && CHANGED_COMPONENTS+=("themes")
    echo "$staged_files" | grep -qE '^plugins/'           && CHANGED_COMPONENTS+=("plugins")
    echo "$staged_files" | grep -qE '^config/nvim/'       && CHANGED_COMPONENTS+=("neovim")
    echo "$staged_files" | grep -qE '^config/hypr/'       && CHANGED_COMPONENTS+=("hyprland")
    echo "$staged_files" | grep -qE '^config/fish/'       && CHANGED_COMPONENTS+=("fish")
    echo "$staged_files" | grep -qE '^config/waybar/'     && CHANGED_COMPONENTS+=("waybar")
    echo "$staged_files" | grep -qE '^api/'               && CHANGED_COMPONENTS+=("api")
    echo "$staged_files" | grep -qE '^web/'               && CHANGED_COMPONENTS+=("web")
    echo "$staged_files" | grep -qE '^mobile/'            && CHANGED_COMPONENTS+=("mobile")
    echo "$staged_files" | grep -qE '^scripts/(install|system|security)/' && \
        CHANGED_COMPONENTS+=("system-scripts")
    echo "$staged_files" | grep -qE '\.sh$'               && CHANGED_COMPONENTS+=("shell")
    echo "$staged_files" | grep -qE '\.lua$'              && CHANGED_COMPONENTS+=("lua")
    echo "$staged_files" | grep -qE '\.json$'             && CHANGED_COMPONENTS+=("json")
    echo "$staged_files" | grep -qE '\.ya?ml$'            && CHANGED_COMPONENTS+=("yaml")

    # Enable integration tests for core changes
    for comp in cli api themes plugins system-scripts; do
        if printf '%s\n' "${CHANGED_COMPONENTS[@]}" | grep -q "^${comp}$"; then
            RUN_INTEGRATION=true
            break
        fi
    done

    # Display detected components
    if [[ ${#CHANGED_COMPONENTS[@]} -gt 0 ]]; then
        printf "\n  %s%sChanged components:%s " "$B" "$LAVENDER" "$R" >&2
        for comp in "${CHANGED_COMPONENTS[@]}"; do
            printf "%s[%s]%s " "${CYAN}${B}" "$comp" "$R" >&2
        done
        printf "\n" >&2
    fi

    printf "  %sIntegration tests:%s %s\n" \
        "${D}" "$R" \
        "$([[ "$RUN_INTEGRATION" == "true" ]] && \
           echo "${AMBER}${B}ENABLED${R}" || \
           echo "${D}disabled${R}")" >&2
}

# ── UNIT TEST SUITE ───────────────────────────────────────────────────────────
suite_unit_tests() {
    local test_dir="${TESTS_DIR}/unit"

    if [[ ! -d "$test_dir" ]]; then
        render_test "skip" "Unit test directory" "not found: $test_dir"
        return 0
    fi

    local -a test_files=()

    # Filter tests to only relevant ones based on changes
    while IFS= read -r -d '' f; do
        local should_run=true

        # Smart filtering by component
        if [[ ${#CHANGED_COMPONENTS[@]} -gt 0 ]]; then
            local file_base; file_base="$(basename "$f" .sh)"
            local runs_for_change=false

            for comp in "${CHANGED_COMPONENTS[@]}"; do
                case "$comp" in
                    cli)     [[ "$file_base" == *cli* ]] || [[ "$file_base" == *core* ]] && runs_for_change=true ;;
                    themes)  [[ "$file_base" == *theme* ]] || [[ "$file_base" == *color* ]] && runs_for_change=true ;;
                    plugins) [[ "$file_base" == *plugin* ]] && runs_for_change=true ;;
                    shell)   [[ "$file_base" == *utils* ]] || [[ "$file_base" == *logger* ]] && runs_for_change=true ;;
                    *)       runs_for_change=true ;;
                esac
            done

            # If no specific match, still run core tests
            if [[ "$runs_for_change" != "true" ]]; then
                [[ "$file_base" == *core* ]] || [[ "$file_base" == *utils* ]] && \
                    runs_for_change=true
            fi

            [[ "$runs_for_change" != "true" ]] && should_run=false
        fi

        [[ "$should_run" == "true" ]] && test_files+=("$f")
    done < <(find "$test_dir" -name "test-*.sh" -print0 2>/dev/null | sort -z)

    if [[ ${#test_files[@]} -eq 0 ]]; then
        render_test "skip" "Unit tests" "no matching test files"
        return 0
    fi

    for test_file in "${test_files[@]}"; do
        local test_name; test_name="$(basename "$test_file" .sh | sed 's/^test-//')"
        local t_start; t_start="$(now_ms)"

        local output exit_code=0
        output="$(timeout "$UNIT_TIMEOUT" bash "$test_file" 2>&1)" || exit_code=$?
        local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"

        case $exit_code in
            0)   render_test "pass"  "$test_name" ""        "$dur" ;;
            124) render_test "error" "$test_name" "TIMEOUT after ${UNIT_TIMEOUT}s" "$dur" ;;
            *)
                local summary
                summary="$(echo "$output" | grep -P '(FAIL|ERROR|assert)' | head -3 | \
                    tr '\n' '|' | sed 's/|$//')"
                render_test "fail" "$test_name" "${summary:-exit code: $exit_code}" "$dur"
                ;;
        esac
    done
}

# ── INTEGRATION TEST SUITE ─────────────────────────────────────────────────────
suite_integration_tests() {
    if [[ "$RUN_INTEGRATION" != "true" ]]; then
        render_test "skip" "Integration tests" "not triggered by changes"
        return 0
    fi

    local test_dir="${TESTS_DIR}/integration"
    if [[ ! -d "$test_dir" ]]; then
        render_test "skip" "Integration tests" "directory not found"
        return 0
    fi

    # Only run integration tests relevant to changed components
    local -A COMP_TESTS=(
        ["cli"]="test-full-install.sh test-theme-workflow.sh"
        ["themes"]="test-theme-workflow.sh test-color-pipeline.sh"
        ["plugins"]="test-plugin-lifecycle.sh"
        ["api"]="test-api-endpoints.sh"
    )

    local run_tests=()
    for comp in "${CHANGED_COMPONENTS[@]}"; do
        if [[ -n "${COMP_TESTS[$comp]:-}" ]]; then
            for t in ${COMP_TESTS[$comp]}; do
                local test_path="${test_dir}/${t}"
                if [[ -f "$test_path" ]]; then
                    # Dedup
                    local already=false
                    for existing in "${run_tests[@]:-}"; do
                        [[ "$existing" == "$test_path" ]] && { already=true; break; }
                    done
                    [[ "$already" == "false" ]] && run_tests+=("$test_path")
                fi
            done
        fi
    done

    if [[ ${#run_tests[@]} -eq 0 ]]; then
        render_test "skip" "Integration tests" "no matching tests for changed components"
        return 0
    fi

    for test_file in "${run_tests[@]}"; do
        local test_name; test_name="$(basename "$test_file" .sh | sed 's/^test-//')"
        local t_start; t_start="$(now_ms)"

        local output exit_code=0
        output="$(timeout "$INTEGRATION_TIMEOUT" bash "$test_file" 2>&1)" || exit_code=$?
        local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"

        case $exit_code in
            0)   render_test "pass"  "$test_name" ""   "$dur" ;;
            124) render_test "error" "$test_name" "TIMEOUT after ${INTEGRATION_TIMEOUT}s" "$dur" ;;
            *)   render_test "fail"  "$test_name" "exit: $exit_code" "$dur" ;;
        esac
    done
}

# ── SCHEMA VALIDATION SUITE ───────────────────────────────────────────────────
suite_schema_tests() {
    local staged_files
    staged_files="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"

    # Theme schema
    local theme_files
    theme_files="$(echo "$staged_files" | grep -E '^themes/.+/colors\.json$' || true)"

    if [[ -n "$theme_files" ]]; then
        while IFS= read -r theme; do
            [[ -z "$theme" ]] || [[ ! -f "$theme" ]] && continue
            local t_start; t_start="$(now_ms)"
            local theme_name; theme_name="$(basename "$(dirname "$theme")")"
            local output exit_code=0

            local validator="${REPO_ROOT}/.git-hooks/validate-theme.sh"
            if [[ -f "$validator" ]]; then
                output="$(timeout "$SCHEMA_TIMEOUT" \
                    bash "$validator" "$theme" --no-wcag 2>&1)" || exit_code=$?
            else
                # Basic validation fallback
                if command -v jq &>/dev/null; then
                    output="$(jq empty < "$theme" 2>&1)" || exit_code=$?
                fi
            fi

            local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"
            if [[ $exit_code -eq 0 ]]; then
                render_test "pass" "theme: ${theme_name}" "" "$dur"
            else
                render_test "fail" "theme: ${theme_name}" \
                    "$(echo "$output" | head -2 | tr '\n' ' ')" "$dur"
            fi
        done <<< "$theme_files"
    else
        render_test "skip" "Theme schema" "no theme files staged"
    fi

    # Plugin schema
    local plugin_files
    plugin_files="$(echo "$staged_files" | grep -E '^plugins/.+/plugin\.json$' || true)"

    if [[ -n "$plugin_files" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] || [[ ! -f "$plugin" ]] && continue
            local t_start; t_start="$(now_ms)"
            local plugin_name; plugin_name="$(basename "$(dirname "$plugin")")"
            local exit_code=0

            local validator="${REPO_ROOT}/.git-hooks/validate-plugin.sh"
            local output=""
            if [[ -f "$validator" ]]; then
                output="$(timeout "$SCHEMA_TIMEOUT" \
                    bash "$validator" "$plugin" 2>&1)" || exit_code=$?
            else
                output="$(jq -r '.name,.version,.author,.description,.entry | select(. == null) | "missing"' \
                    "$plugin" 2>&1 | grep -c 'missing')" || exit_code=$?
                [[ "${output:-0}" -gt 0 ]] && exit_code=1
            fi

            local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"
            if [[ $exit_code -eq 0 ]]; then
                render_test "pass" "plugin: ${plugin_name}" "" "$dur"
            else
                render_test "fail" "plugin: ${plugin_name}" \
                    "$(echo "$output" | head -2 | tr '\n' ' ')" "$dur"
            fi
        done <<< "$plugin_files"
    else
        render_test "skip" "Plugin schema" "no plugin files staged"
    fi

    # JSON schema validation
    local json_files
    json_files="$(echo "$staged_files" | grep '\.json$' || true)"
    local invalid_json=0 valid_json=0

    if [[ -n "$json_files" ]] && command -v jq &>/dev/null; then
        while IFS= read -r jf; do
            [[ -z "$jf" ]] || [[ ! -f "$jf" ]] && continue
            if jq empty < "$jf" &>/dev/null; then
                ((valid_json++)) || true
            else
                ((invalid_json++)) || true
            fi
        done <<< "$json_files"

        local total_json=$(( valid_json + invalid_json ))
        if [[ $invalid_json -eq 0 ]]; then
            render_test "pass" "JSON syntax (${total_json} files)" "" ""
        else
            render_test "fail" "JSON syntax" "${invalid_json} invalid files" ""
        fi
    fi

    # YAML validation
    local yaml_files
    yaml_files="$(echo "$staged_files" | grep -E '\.ya?ml$' || true)"
    if [[ -n "$yaml_files" ]] && command -v python3 &>/dev/null; then
        local invalid_yaml=0 valid_yaml=0
        while IFS= read -r yf; do
            [[ -z "$yf" ]] || [[ ! -f "$yf" ]] && continue
            if python3 -c "import yaml; yaml.safe_load(open('$yf'))" &>/dev/null; then
                ((valid_yaml++)) || true
            else
                ((invalid_yaml++)) || true
            fi
        done <<< "$yaml_files"

        local total_yaml=$(( valid_yaml + invalid_yaml ))
        if [[ $invalid_yaml -eq 0 ]]; then
            render_test "pass" "YAML syntax (${total_yaml} files)" "" ""
        else
            render_test "fail" "YAML syntax" "${invalid_yaml} invalid files" ""
        fi
    fi
}

# ── SHELL LINT SUITE ──────────────────────────────────────────────────────────
suite_shell_lint() {
    if ! command -v shellcheck &>/dev/null; then
        render_test "skip" "ShellCheck" "not installed"
        return 0
    fi

    local staged_files
    staged_files="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
    local sh_files
    sh_files="$(echo "$staged_files" | grep '\.sh$' || true)"

    if [[ -z "$sh_files" ]]; then
        render_test "skip" "ShellCheck" "no shell files staged"
        return 0
    fi

    local pass_count=0 fail_count=0

    while IFS= read -r f; do
        [[ -z "$f" ]] || [[ ! -f "$f" ]] && continue
        local t_start; t_start="$(now_ms)"
        local output exit_code=0
        output="$(shellcheck \
            --severity=error \
            --format=compact \
            --shell=bash \
            "$f" 2>&1)" || exit_code=$?

        local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"
        local short_name; short_name="${f#"$REPO_ROOT"/}"

        if [[ $exit_code -eq 0 ]]; then
            ((pass_count++)) || true
            render_test "pass" "shellcheck: ${short_name}" "" "$dur"
        else
            ((fail_count++)) || true
            local err_count; err_count="$(echo "$output" | wc -l | tr -d ' ')"
            render_test "fail" "shellcheck: ${short_name}" \
                "${err_count} error(s)" "$dur"
        fi
    done <<< "$sh_files"

    return $fail_count
}

# ── LUA LINT SUITE ────────────────────────────────────────────────────────────
suite_lua_lint() {
    if ! command -v luacheck &>/dev/null; then
        render_test "skip" "LuaCheck" "not installed"
        return 0
    fi

    local staged_files
    staged_files="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
    local lua_files
    lua_files="$(echo "$staged_files" | grep '\.lua$' || true)"

    if [[ -z "$lua_files" ]]; then
        render_test "skip" "LuaCheck" "no Lua files staged"
        return 0
    fi

    local lua_arr=()
    while IFS= read -r f; do
        [[ -f "$f" ]] && lua_arr+=("$f")
    done <<< "$lua_files"

    local t_start; t_start="$(now_ms)"
    local output exit_code=0
    output="$(luacheck --no-color --codes "${lua_arr[@]}" 2>&1)" || exit_code=$?
    local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"

    if [[ $exit_code -eq 0 ]]; then
        render_test "pass" "LuaCheck (${#lua_arr[@]} files)" "all clean" "$dur"
    else
        local warn_count; warn_count="$(echo "$output" | grep -cP '(warning|error)' || echo '?')"
        render_test "fail" "LuaCheck (${#lua_arr[@]} files)" "${warn_count} issue(s)" "$dur"
    fi
}

# ── SECURITY QUICK SCAN ───────────────────────────────────────────────────────
suite_security_quick() {
    if [[ "$RUN_SECURITY" != "true" ]]; then
        render_test "skip" "Security scan" "not enabled (use --security)"
        return 0
    fi

    local scanner="${REPO_ROOT}/.git-hooks/check-secrets.sh"
    if [[ ! -f "$scanner" ]]; then
        render_test "skip" "Secret scan" "scanner not found"
        return 0
    fi

    local t_start; t_start="$(now_ms)"
    local output exit_code=0
    output="$(timeout "$SECURITY_TIMEOUT" bash "$scanner" staged 2>&1)" || exit_code=$?
    local dur; dur="$(format_dur "$(( $(now_ms) - t_start ))")"

    if [[ $exit_code -eq 0 ]]; then
        render_test "pass" "Secret scan" "no secrets detected" "$dur"
    else
        local finding_count; finding_count="$(echo "$output" | grep -cP 'CRITICAL|HIGH|MEDIUM' || echo '?')"
        render_test "fail" "Secret scan" "${finding_count} finding(s)" "$dur"
    fi
}

# ── PERFORMANCE BENCHMARK ──────────────────────────────────────────────────────
suite_performance() {
    if [[ "$RUN_PERFORMANCE" != "true" ]]; then
        render_test "skip" "Performance benchmarks" "not enabled (use --perf)"
        return 0
    fi

    # Quick startup benchmark
    local t_start; t_start="$(now_ms)"
    local ash_bin="${REPO_ROOT}/ash-cli/ash"
    if [[ ! -f "$ash_bin" ]]; then
        render_test "skip" "Startup benchmark" "ash binary not found"
        return 0
    fi

    local startup_ms
    startup_ms="$(bash -c "t=\$(date +%s%3N); bash '${ash_bin}' --version &>/dev/null; echo \$(( \$(date +%s%3N) - t ))")"
    local dur; dur="$(format_dur "$startup_ms")"

    if [[ $startup_ms -lt 500 ]]; then
        render_test "pass" "Startup time" "${startup_ms}ms < 500ms target" "$dur"
    elif [[ $startup_ms -lt 1000 ]]; then
        render_test "warn" "Startup time" "${startup_ms}ms — slightly slow" "$dur"
    else
        render_test "fail" "Startup time" "${startup_ms}ms > 1000ms threshold" "$dur"
    fi
}

# ── HELPER TESTS (in-place mini framework) ────────────────────────────────────
run_inline_tests() {
    section "🔬" "Inline Validation Tests" "$EMERALD"

    # Test 1: version.json valid
    local version_file="${REPO_ROOT}/version.json"
    if [[ -f "$version_file" ]] && command -v jq &>/dev/null; then
        local ver; ver="$(jq -r '.version // empty' "$version_file" 2>/dev/null || true)"
        if [[ -n "$ver" ]]; then
            render_test "pass" "version.json" "version: $ver"
        else
            render_test "fail" "version.json" "missing .version field"
        fi
    else
        render_test "skip" "version.json" "file not found or jq unavailable"
    fi

    # Test 2: CODEOWNERS exists and is non-empty
    local codeowners="${REPO_ROOT}/.github/CODEOWNERS"
    if [[ -f "$codeowners" ]] && [[ -s "$codeowners" ]]; then
        local line_count; line_count="$(wc -l < "$codeowners" | tr -d ' ')"
        render_test "pass" "CODEOWNERS" "${line_count} lines"
    else
        render_test "warn" "CODEOWNERS" "missing or empty"
    fi

    # Test 3: ash-cli/ash is executable
    local ash_bin="${REPO_ROOT}/ash-cli/ash"
    if [[ -f "$ash_bin" ]]; then
        if [[ -x "$ash_bin" ]]; then
            render_test "pass" "ash binary executable" ""
        else
            render_test "fail" "ash binary executable" "not executable (run: chmod +x)"
        fi
    else
        render_test "skip" "ash binary" "not found"
    fi

    # Test 4: No broken symlinks in config/
    local broken=0
    while IFS= read -r -d '' link; do
        [[ -e "$link" ]] || { ((broken++)) || true; }
    done < <(find "${REPO_ROOT}/config" -maxdepth 3 -type l -print0 2>/dev/null || true)

    if [[ $broken -eq 0 ]]; then
        render_test "pass" "No broken symlinks" ""
    else
        render_test "warn" "Broken symlinks" "${broken} found in config/"
    fi

    # Test 5: Git config has user identity
    local git_name; git_name="$(git config --get user.name 2>/dev/null || true)"
    local git_email; git_email="$(git config --get user.email 2>/dev/null || true)"
    if [[ -n "$git_name" ]] && [[ -n "$git_email" ]]; then
        render_test "pass" "Git identity" "${git_name} <${git_email}>"
    else
        render_test "warn" "Git identity" "user.name or user.email not set"
    fi

    # Test 6: No merge conflict markers anywhere staged
    local staged_files
    staged_files="$(git diff --cached --name-only 2>/dev/null || true)"
    local conflict_files=0

    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        if grep -qP '^(<{7}|>{7}|={7})' "$f" 2>/dev/null; then
            ((conflict_files++)) || true
        fi
    done <<< "$staged_files"

    if [[ $conflict_files -eq 0 ]]; then
        render_test "pass" "No conflict markers" ""
    else
        render_test "fail" "Conflict markers" "${conflict_files} file(s) have conflict markers"
    fi
}

# ── BANNER ────────────────────────────────────────────────────────────────────
print_banner() {
    printf "\n" >&2
    box_t
    box_l "${B}${EMERALD}  🧪 ASH DOTFILES v5.0 OMEGA — ULTRA TEST RUNNER${R}${BG_MIDNIGHT}${GOLD}"
    box_l "${D}${CREAM}  Intelligent · Fast · Beautiful · Comprehensive${R}${BG_MIDNIGHT}${GOLD}"
    box_d
    box_l "$(printf "  %s%-18s%s %s%s%s" "${CYAN}${B}" "Mode:" "$R$BG_MIDNIGHT$GOLD" \
        "${LAVENDER}" "$([[ "$RUN_FULL" == "true" ]] && echo "FULL" || echo "SMART (changed files only)")" \
        "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%s%s" "${CYAN}${B}" "Integration:" "$R$BG_MIDNIGHT$GOLD" \
        "${AMBER}" "$([[ "$RUN_INTEGRATION" == "true" ]] && echo "enabled" || echo "auto-detect")" \
        "$R$BG_MIDNIGHT$GOLD")"
    box_l "$(printf "  %s%-18s%s %s%s%s" "${CYAN}${B}" "Tests Dir:" "$R$BG_MIDNIGHT$GOLD" \
        "${D}${SLATE}" "$TESTS_DIR" "$R$BG_MIDNIGHT$GOLD")"
    box_b
    printf "\n" >&2
}

# ── TEST RESULTS HEATMAP ──────────────────────────────────────────────────────
print_suite_heatmap() {
    if [[ ${#SUITE_RESULTS[@]} -eq 0 ]]; then return; fi

    section "🗺️" "Suite Heatmap" "$GOLD"
    printf "\n" >&2

    local col=0
    for suite in "${!SUITE_RESULTS[@]}"; do
        local result="${SUITE_RESULTS[$suite]}"
        local dur="${SUITE_TIMES[$suite]:-?}"
        local color
        [[ "$result" == "PASS" ]] && color="${GREEN}${B}" || color="${RED}${B}"

        printf "  %s%-28s%s%s%-6s%s %s%s%s  " \
            "${D}${WHITE}" "${suite:0:28}" "$R" \
            "${color}" "$result" "$R" \
            "${D}${SLATE}" "$dur" "$R" >&2

        ((col++)) || true
        # `[[ … ]] && cmd` yields 1 when the test is false; without the trailing
        # `|| true` that becomes the loop's — and then the function's — exit
        # status, and `set -e` aborts the run before print_summary ever fires.
        [[ $((col % 2)) -eq 0 ]] && printf "\n" >&2 || true
    done
    [[ $((col % 2)) -ne 0 ]] && printf "\n" >&2 || true
}

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print_summary() {
    local dur; dur="$(format_dur "$(elapsed_ms)")"

    # Test score
    local score_pct=0
    [[ $TESTS_RUN -gt 0 ]] && score_pct=$(( TESTS_PASSED * 100 / TESTS_RUN ))

    local bar_filled=$(( score_pct * 40 / 100 ))
    local bar_empty=$(( 40 - bar_filled ))
    local bar_color
    if   [[ $TESTS_FAILED -eq 0 ]];  then bar_color="${GREEN}${B}"
    elif [[ $TESTS_FAILED -lt 3 ]];  then bar_color="${YELLOW}${B}"
    else                                   bar_color="${RED}${B}"
    fi

    printf "\n" >&2
    box_t

    # Status line
    local status_msg
    if [[ $TESTS_FAILED -eq 0 ]] && [[ $TESTS_ERRORED -eq 0 ]]; then
        status_msg="${GREEN}${B}  ✓ ALL TESTS PASSED${R}${BG_MIDNIGHT}${GOLD}"
    else
        status_msg="${RED}${B}  ✗ TESTS FAILED — $(( TESTS_FAILED + TESTS_ERRORED )) failure(s)${R}${BG_MIDNIGHT}${GOLD}"
    fi
    box_l "$status_msg"
    box_td

    # Score bar
    box_l "$(printf "  %s%s%s%s%s  %s%d%%%s  %s%d/%d tests%s" \
        "${bar_color}" \
        "$(printf '%*s' "$bar_filled" '' | tr ' ' '█')" \
        "${D}${SLATE}" \
        "$(printf '%*s' "$bar_empty"  '' | tr ' ' '░')" \
        "$R$BG_MIDNIGHT$GOLD" \
        "${bar_color}" "$score_pct" "$R$BG_MIDNIGHT$GOLD" \
        "${D}${SLATE}" "$TESTS_PASSED" "$TESTS_RUN" "$R$BG_MIDNIGHT$GOLD")"

    box_td
    box_l "$(printf "  %s✓ %-4s%s passed   %s✗ %-4s%s failed   %s! %-4s%s errors   %s↷ %-4s%s skipped   %s⏱ %s%s" \
        "${GREEN}${B}"  "$TESTS_PASSED"  "$R$BG_MIDNIGHT$GOLD" \
        "${RED}${B}"    "$TESTS_FAILED"  "$R$BG_MIDNIGHT$GOLD" \
        "${CRIMSON}${B}" "$TESTS_ERRORED" "$R$BG_MIDNIGHT$GOLD" \
        "${SLATE}${D}"  "$TESTS_SKIPPED" "$R$BG_MIDNIGHT$GOLD" \
        "${CYAN}${D}"   "$dur"           "$R$BG_MIDNIGHT$GOLD")"

    box_l "$(printf "  %s▣ %-4s%s suites   %s✓ %-4s%s passed   %s✗ %-4s%s failed" \
        "${GOLD}${B}"   "$SUITES_RUN"    "$R$BG_MIDNIGHT$GOLD" \
        "${GREEN}${B}"  "$SUITES_PASSED" "$R$BG_MIDNIGHT$GOLD" \
        "${RED}${B}"    "$SUITES_FAILED" "$R$BG_MIDNIGHT$GOLD")"

    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        box_td
        box_l "${RED}${B}  FAILED TESTS:${R}${BG_MIDNIGHT}${GOLD}"
        for ft in "${FAILED_TESTS[@]:0:10}"; do
            box_l "  ${RED}  ✗ ${ft:0:$(( TERM_WIDTH-14 ))}${R}${BG_MIDNIGHT}${GOLD}"
        done
        box_td
        box_l "  ${D}Fix failing tests, then re-commit${R}${BG_MIDNIGHT}${GOLD}"
        box_l "  ${D}Log: ${LOG_FILE}${R}${BG_MIDNIGHT}${GOLD}"
    fi

    box_b
    printf "\n" >&2
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)        RUN_FULL=true; RUN_INTEGRATION=true; RUN_SECURITY=true ;;
            --integration) RUN_INTEGRATION=true ;;
            --security)    RUN_SECURITY=true ;;
            --perf)        RUN_PERFORMANCE=true ;;
            --no-unit)     RUN_UNIT=false ;;
            *) echo "Unknown flag: $1" >&2 ;;
        esac
        shift
    done

    [[ "${ASH_SKIP_HOOKS:-}" == "true" ]] && exit 0

    init
    print_banner
    detect_changed_components

    section "🧪" "Test Suites" "$EMERALD"

    # Core test suites
    [[ "$RUN_UNIT" == "true" ]] && \
        run_suite "Unit Tests"            "🔬" suite_unit_tests       "$MINT"
    run_suite "Integration Tests"     "🔗" suite_integration_tests "$TEAL"
    run_suite "Schema Validation"     "📐" suite_schema_tests       "$INDIGO"
    run_suite "Shell Lint"            "🐚" suite_shell_lint         "$LIME"
    run_suite "Lua Lint"              "🌙" suite_lua_lint           "$VIOLET"
    run_suite "Inline Validation"     "⚡" run_inline_tests          "$AMBER"
    run_suite "Security Quick Scan"   "🔒" suite_security_quick     "$CRIMSON"
    run_suite "Performance"           "⚡" suite_performance         "$GOLD"

    print_suite_heatmap
    print_summary

    # Exit code based on failures
    local total_failures=$(( TESTS_FAILED + TESTS_ERRORED + SUITES_FAILED ))
    [[ $total_failures -gt 0 ]] && exit 1
    exit 0
}

main "$@"