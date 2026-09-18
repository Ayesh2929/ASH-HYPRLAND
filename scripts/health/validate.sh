#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v5.0-omega — CONFIG VALIDATOR                          ║
# ║           Verifies the config tree in the checkout and, optionally,           ║
# ║           the copy that is installed under ~/.config                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   scripts/health/validate.sh                 # repo (or checkout) + installed copy
#   scripts/health/validate.sh --repo          # only the checkout under config/
#   scripts/health/validate.sh --installed     # only ~/.config
#   scripts/health/validate.sh --quiet         # one line per failure
#
# Exit status: 0 when every required file exists, 1 otherwise.

set -euo pipefail

readonly CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/validate.log"

# ── Locate the checkout ───────────────────────────────────────────────────────
detect_checkout() {
    local candidate
    for candidate in \
        "${ASH_DOTFILES_DIR:-}" \
        "${HOME}/.local/share/ash-dotfiles" \
        "${HOME}/.dotfiles" \
        "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"; do
        [[ -n "$candidate" && -d "${candidate}/config/hypr" ]] || continue
        printf '%s' "$candidate"
        return 0
    done
    return 1
}

CHECKOUT="$(detect_checkout || true)"

# ── Colours ───────────────────────────────────────────────────────────────────
readonly R=$'\033[0m'
readonly B=$'\033[1m'
readonly G=$'\033[92m'
readonly Y=$'\033[93m'
readonly RED=$'\033[91m'
readonly C=$'\033[96m'
readonly M=$'\033[95m'
readonly DIM=$'\033[2m'

declare -i PASS=0 FAIL=0 WARN=0 SKIP=0
declare -a MISSING=()
declare -a NON_EXEC=()

QUIET=0
log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ── Result helpers ────────────────────────────────────────────────────────────
pass() { ((PASS++)) || true; ((QUIET)) || printf '  %s✓%s %s\n' "${G}" "${R}" "$1"; }

fail() {
    local name="$1" fix="${2:-}"
    ((FAIL++)) || true
    MISSING+=("${name}")
    printf '  %s✗%s %s' "${RED}" "${R}" "${name}"
    [[ -n "${fix}" ]] && printf '  %s→ %s%s' "${DIM}" "${fix}" "${R}"
    printf '\n'
}

warn() {
    ((WARN++)) || true
    ((QUIET)) || printf '  %s⚠%s %s\n' "${Y}" "${R}" "$1"
}

skip() { ((SKIP++)) || true; ((QUIET)) || printf '  %s─%s %s\n' "${DIM}" "${R}" "$1"; }
section() { ((QUIET)) || { echo ""; printf '  %s%s━━━ %s ━━━%s\n' "${B}" "${M}" "$1" "${R}"; }; }

# check_file <name> <path> [required|optional] [executable]
check_file() {
    local name="$1" path="$2" required="${3:-required}" want_exec="${4:-false}"

    if [[ ! -f "${path}" ]]; then
        if [[ "${required}" == "required" ]]; then
            fail "${name}" "missing: ${path/$HOME/~}"
        else
            warn "${name} ${DIM}(optional, not installed)${R}"
        fi
        return 1
    fi

    if [[ "${want_exec}" == "true" && ! -x "${path}" ]]; then
        NON_EXEC+=("${path}")
        fail "${name}" "not executable — chmod +x ${path/$HOME/~}"
        return 1
    fi

    pass "${name}"
    return 0
}

check_dir() {
    local name="$1" path="$2" required="${3:-required}"
    if [[ ! -d "${path}" ]]; then
        [[ "${required}" == "required" ]] && fail "${name}" "missing dir: ${path/$HOME/~}" || warn "${name}"
        return 1
    fi
    pass "${name}"
    return 0
}

json_ok() {
    local file="$1"
    command -v python3 >/dev/null 2>&1 || return 0
    python3 - "$file" <<'PYCODE' >/dev/null 2>&1
import sys, json, re, pathlib

text = pathlib.Path(sys.argv[1]).read_text(errors='replace')

# JSONC -> JSON: strip // and /* */ comments outside strings and drop trailing
# commas — both of which waybar/swaync (jsoncpp) accept but json.loads does not.
out, i, n, in_str, esc = [], 0, len(text), False, False
while i < n:
    ch = text[i]
    if in_str:
        out.append(ch)
        if esc:
            esc = False
        elif ch == '\\':
            esc = True
        elif ch == '"':
            in_str = False
        i += 1
        continue
    if ch == '"':
        in_str = True
        out.append(ch)
        i += 1
        continue
    if ch == '/' and i + 1 < n and text[i + 1] == '/':
        while i < n and text[i] != '\n':
            i += 1
        continue
    if ch == '/' and i + 1 < n and text[i + 1] == '*':
        end = text.find('*/', i + 2)
        i = n if end == -1 else end + 2
        continue
    out.append(ch)
    i += 1

cleaned = ''.join(out)
prev = None
while prev != cleaned:
    prev = cleaned
    cleaned = re.sub(r',(\s*[}\]])', r'\1', cleaned)

json.loads(cleaned)
PYCODE
}

# ── Manifests: paths relative to a config root (checkout config/ or ~/.config)
readonly -a CORE_FILES=(
    "hypr/hyprland.conf"
    "hypr/env.conf"
    "hypr/monitors.conf"
    "hypr/input.conf"
    "hypr/misc.conf"
    "hypr/decorations.conf"
    "hypr/windowrules.conf"
    "hypr/workspacerules.conf"
    "hypr/autostart.conf"
    "hypr/animations/default.conf"
    "hypr/themes/colors.conf"
    "hypr/keybinds/default.conf"
    "hypr/keybinds/custom.conf"
)

readonly -a DESKTOP_FILES=(
    "waybar/config.jsonc"
    "waybar/style.css"
    "waybar/colors.css"
    "rofi/config.rasi"
    "hyprlock/hyprlock.conf"
    "hyprlock/colors.conf"
    "hypridle/hypridle.conf"
    "dunst/dunstrc"
    "dunst/colors.conf"
    "swaync/config.json"
)

readonly -a TERMINAL_FILES=(
    "kitty/kitty.conf"
    "fish/config.fish"
    "starship/starship.toml"
    "wezterm/wezterm.lua"
    "alacritty/alacritty.toml"
    "tmux/tmux.conf"
    "zellij/config.kdl"
    "btop/btop.conf"
    "fastfetch/config.jsonc"
)

readonly -a EDITOR_FILES=(
    "nvim/init.lua"
    "helix/config.toml"
)

readonly -a MEDIA_FILES=(
    "mpv/mpv.conf"
    "mpd/mpd.conf"
    "cava/config"
)

readonly -a SHELL_DIRS=(
    "fish/functions"
    "fish/conf.d"
)

readonly -a SCRIPT_DIRS=(
    "hypr/scripts"
    "hyprlock/scripts"
    "swaync/scripts"
    "dunst/scripts"
    "waybar/scripts"
)

# ── Validators ────────────────────────────────────────────────────────────────
validate_tree() {
    local root="$1" label="$2"
    local rel path

    printf '\n%s%sChecking %s%s %s(%s)%s\n' "${B}" "${C}" "${label}" "${R}" "${DIM}" "${root/$HOME/~}" "${R}"

    section "🪟 Hyprland"
    for rel in "${CORE_FILES[@]}"; do
        check_file "${rel}" "${root}/${rel}" required || true
    done

    section "🖥  Desktop shell"
    for rel in "${DESKTOP_FILES[@]}"; do
        check_file "${rel}" "${root}/${rel}" required || true
    done

    section "💻 Terminals & shells"
    for rel in "${TERMINAL_FILES[@]}"; do
        case "${rel}" in
            kitty/kitty.conf|fish/config.fish|tmux/tmux.conf|btop/btop.conf)
                check_file "${rel}" "${root}/${rel}" required || true
                ;;
            *)
                check_file "${rel}" "${root}/${rel}" optional || true
                ;;
        esac
    done

    section "📝 Editors & media"
    for rel in "${EDITOR_FILES[@]}" "${MEDIA_FILES[@]}"; do
        case "${rel}" in
            nvim/init.lua) check_file "${rel}" "${root}/${rel}" required || true ;;
            *)             check_file "${rel}" "${root}/${rel}" optional || true ;;
        esac
    done

    section "📁 Shell integration directories"
    for rel in "${SHELL_DIRS[@]}"; do
        check_dir "${rel}" "${root}/${rel}" required || true
    done

    section "🧩 Helper script directories"
    for rel in "${SCRIPT_DIRS[@]}"; do
        if check_dir "${rel}" "${root}/${rel}" required; then
            local script
            local -i bad=0
            while IFS= read -r script; do
                [[ -x "${script}" ]] || { NON_EXEC+=("${script}"); bad+=1; }
            done < <(find "${root}/${rel}" -maxdepth 1 -name '*.sh' 2>/dev/null)
            if (( bad > 0 )); then
                fail "${rel}: ${bad} script(s) not executable" "chmod +x ${rel}/*.sh"
            else
                pass "${rel} scripts executable"
            fi
        fi
    done

    section "🧾 JSON / JSONC syntax"
    local -i json_bad=0 json_total=0
    for path in $(find "${root}/waybar" "${root}/swaync" "${root}/rofi" -maxdepth 2 \
                      \( -name '*.json' -o -name '*.jsonc' \) 2>/dev/null | sort); do
        ((json_total++)) || true
        if ! json_ok "${path}"; then
            ((json_bad++)) || true
            fail "${path#${root}/}" "invalid JSON/JSONC"
        fi
    done
    (( json_bad == 0 )) && pass "${json_total} JSON/JSONC file(s) parse cleanly"

    section "🚫 Stub detection"
    local -i stubs=0
    if [[ -d "${root}/hypr" ]]; then
        stubs="$(grep -rl "omega stub" "${root}" 2>/dev/null | wc -l || true)"
    fi
    if (( stubs == 0 )); then
        pass "No omega stub files"
    else
        warn "${stubs} file(s) still contain the omega stub marker"
    fi
}

validate_scripts_tree() {
    local root="$1"
    [[ -d "${root}/scripts" ]] || return 0

    section "🛠  Dotfiles scripts"
    local rel path
    local -a required_scripts=(
        "scripts/core/install.sh"
        "scripts/core/update.sh"
        "scripts/core/backup.sh"
        "scripts/core/restore.sh"
        "scripts/health/doctor.sh"
        "scripts/health/validate.sh"
        "scripts/install/uninstall.sh"
        "scripts/hooks/pre-mode-change.sh"
        "scripts/hooks/post-theme-change.sh"
    )
    for rel in "${required_scripts[@]}"; do
        check_file "${rel}" "${root}/${rel}" required true || true
    done

    local exec_ok=0 exec_bad=0
    for path in "${root}"/scripts/*/*.sh; do
        [[ -f "${path}" ]] || continue
        if [[ -x "${path}" ]]; then ((exec_ok++)) || true; else ((exec_bad++)) || true; NON_EXEC+=("${path}"); fi
    done
    if (( exec_bad == 0 )); then
        pass "All ${exec_ok} dotfiles scripts are executable"
    else
        fail "${exec_bad} dotfiles script(s) not executable" "find scripts -name '*.sh' -exec chmod +x {} \\;"
    fi
}

print_report() {
    section "📊 Report"
    printf '  %sPassed   :%s %d\n' "${G}" "${R}" "${PASS}"
    printf '  %sWarnings :%s %d\n' "${Y}" "${R}" "${WARN}"
    printf '  %sFailed   :%s %d\n' "${RED}" "${R}" "${FAIL}"
    printf '  %sSkipped  :%s %d\n' "${DIM}" "${R}" "${SKIP}"

    if (( FAIL > 0 )); then
        echo ""
        printf '  %sProblems found:%s\n' "${B}" "${R}"
        local item
        for item in "${MISSING[@]}"; do printf '    %s•%s %s\n' "${RED}" "${R}" "${item}"; done
    fi

    if (( ${#NON_EXEC[@]} > 0 )); then
        echo ""
        printf '  %sNot executable:%s\n' "${B}" "${R}"
        local item
        for item in "${NON_EXEC[@]}"; do printf '    %s•%s %s\n' "${Y}" "${R}" "${item/$HOME/~}"; done
    fi

    if (( FAIL == 0 )); then
        echo ""
        printf '  %s%s✓ Validation passed%s\n' "${B}" "${G}" "${R}"
    else
        echo ""
        printf '  %s%s✗ Validation failed — %d problem(s)%s\n' "${B}" "${RED}" "${FAIL}" "${R}"
    fi
}

verify_file_count() {
    local root="$1"
    [[ -n "${root}" ]] || return 0

    local config_files scripts_total
    config_files=$(find "${root}/config" -type f 2>/dev/null | wc -l)
    scripts_total=$(find "${root}/scripts" -type f -name '*.sh' 2>/dev/null | wc -l)

    echo ""
    printf '  %s📦 Checkout contents%s\n' "${B}" "${R}"
    printf '    Config files : %d\n' "${config_files}"
    printf '    Scripts      : %d\n' "${scripts_total}"

    if (( config_files >= 400 )); then
        printf '    %s✓ config tree looks complete%s\n' "${G}" "${R}"
    else
        printf '    %s⚠ only %d config files — expected 400+%s\n' "${Y}" "${config_files}" "${R}"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    local mode="auto"
    while (( $# )); do
        case "$1" in
            --repo|--checkout)  mode="repo" ;;
            --installed)        mode="installed" ;;
            --quiet|-q)         QUIET=1 ;;
            --help|-h)
                sed -n '9,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
                exit 0
                ;;
            *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
        esac
        shift
    done

    mkdir -p "${CACHE_DIR}/logs" 2>/dev/null || true
    log "validate start (mode=${mode}, checkout=${CHECKOUT:-none})"

    echo ""
    printf '  %s%s🔍 ASH Dotfiles v5.0-omega — Config Validator%s\n' "${B}" "${M}" "${R}"
    printf '  %s%s%s\n' "${DIM}" "$(date '+%Y-%m-%d %H:%M:%S')" "${R}"

    if [[ "${mode}" == "repo" || "${mode}" == "auto" ]]; then
        if [[ -n "${CHECKOUT}" ]]; then
            validate_tree "${CHECKOUT}/config" "checkout"
            validate_scripts_tree "${CHECKOUT}"
        elif [[ "${mode}" == "repo" ]]; then
            fail "checkout" "no ASH checkout found (set ASH_DOTFILES_DIR)"
        fi
    fi

    if [[ "${mode}" == "installed" || "${mode}" == "auto" ]]; then
        if [[ -d "${CONFIG_DIR}/hypr" ]]; then
            validate_tree "${CONFIG_DIR}" "installed config"
        elif [[ "${mode}" == "installed" ]]; then
            fail "${CONFIG_DIR}/hypr" "ASH does not appear to be installed"
        else
            skip "Installed config not found at ${CONFIG_DIR} — run the installer first"
        fi
    fi

    print_report
    [[ -n "${CHECKOUT}" ]] && verify_file_count "${CHECKOUT}"

    log "validate done: pass=${PASS} warn=${WARN} fail=${FAIL}"
    exit $(( FAIL > 0 ? 1 : 0 ))
}

main "$@"
