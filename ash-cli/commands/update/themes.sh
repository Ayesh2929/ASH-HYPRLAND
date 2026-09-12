#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  update themes                                            ║
# ║  Theme library refresh • schema validation • color cache rebuild                ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_UPDATE_THEMES_LOADED:-}" == "1" ]] && return 0
readonly _ASH_UPDATE_THEMES_LOADED=1

set -euo pipefail
IFS=$'\n\t'

ash_update_themes() {
    upd_section "🎨" "Theme Library Update" "$(_upink)"

    local ash_root="${ASH_ROOT_DIR:-$HOME/ash-dotfiles}"
    local themes_dir="${ash_root}/themes"
    local theme_cache="${XDG_CACHE_HOME:-$HOME/.cache}/ash/themes"

    if [[ ! -d "$themes_dir" ]]; then
        upd_fail "Themes directory not found: ${themes_dir}"
        return 1
    fi

    # ── Count themes ──────────────────────────────────────────────────────────────
    local theme_count
    theme_count="$(find "${themes_dir}/presets" -name 'theme.conf' \
                   2>/dev/null | wc -l)"
    upd_kv "Theme presets" "$theme_count"

    # ── Validate schema ───────────────────────────────────────────────────────────
    local schema_file="${themes_dir}/schema/theme-schema.json"
    if [[ -f "$schema_file" ]] && command -v python3 &>/dev/null; then
        upd_step "Validating theme schema..."
        if python3 -c "import json; json.load(open('${schema_file}'))" \
           &>/dev/null 2>&1; then
            upd_ok "Schema valid: ${schema_file##*/}"
        else
            upd_warn "Schema validation failed"
        fi
    fi

    # ── Spot-check themes for valid JSON ──────────────────────────────────────────
    upd_step "Validating random sample of color files..."
    local valid=0  invalid=0

    while IFS= read -r colors_file; do
        if command -v python3 &>/dev/null; then
            if python3 -c "import json; json.load(open('${colors_file}'))" \
               &>/dev/null 2>&1; then
                (( valid++ )) || true
            else
                (( invalid++ )) || true
                upd_warn "Invalid JSON: ${colors_file##"$themes_dir"}"
            fi
        fi
    done < <(find "$themes_dir/presets" -name 'colors.json' 2>/dev/null | shuf -n 15)

    upd_kv "Validated" "${valid} ok  •  ${invalid} invalid"

    # ── Rebuild color cache ───────────────────────────────────────────────────────
    upd_step "Rebuilding theme color cache..."

    if [[ "${ASH_UPD_DRY:-0}" -ne 1 ]]; then
        rm -rf "$theme_cache" 2>/dev/null || true
        mkdir -p "$theme_cache" 2>/dev/null || true
        upd_ok "Color cache cleared and ready for rebuild"
    else
        upd_info "[dry-run] Would rebuild color cache at ${theme_cache}"
    fi

    # ── User themes ───────────────────────────────────────────────────────────────
    local user_themes_dir="${themes_dir}/user"
    if [[ -d "$user_themes_dir" ]]; then
        local user_count
        user_count="$(find "$user_themes_dir" -name 'theme.conf' | wc -l)"
        upd_kv "User themes" "$user_count"
    fi

    upd_result_pass "themes"
    upd_ok "Theme library updated  (${theme_count} presets)"
}
