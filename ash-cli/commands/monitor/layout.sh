#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  monitor layout                                           ║
# ║  Save, restore, and apply monitor spatial layouts with presets                   ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_MON_LAYOUT_LOADED:-}" == "1" ]] && return 0
readonly _ASH_MON_LAYOUT_LOADED=1

set -euo pipefail
IFS=$'\n\t'

declare -gr _LAYOUT_STORE="${_MON_STATE_DIR}/layouts"

_layout_save() {
    local name="${1:-default}"
    mkdir -p "$_LAYOUT_STORE" 2>/dev/null || true

    local layout_file="${_LAYOUT_STORE}/${name}.json"

    mon_step "Saving layout '${name}'..."
    mon_get_monitors_json > "$layout_file"

    local mon_count
    mon_count="$(python3 -c "import json,sys; print(len(json.load(sys.stdin)))" \
                 < "$layout_file" 2>/dev/null || echo '?')"

    mon_ok "Layout saved: ${layout_file}  (${mon_count} monitors)"
}

_layout_list() {
    mkdir -p "$_LAYOUT_STORE" 2>/dev/null || true
    local -a layouts=()
    mapfile -t layouts < <(find "$_LAYOUT_STORE" -name '*.json' 2>/dev/null | sort)

    if [[ ${#layouts[@]} -eq 0 ]]; then
        mon_info "No saved layouts found"
        mon_info "Save one with: ash mon layout --save <name>"
        return 0
    fi

    printf '\n  %sSaved layouts:%s\n' "$(_mdim)" "$(_mr)"
    printf '  %s%-20s  %-10s  %s%s\n' "$(_mdim)" "Name" "Monitors" "Date" "$(_mr)"
    printf '  %s%s%s\n' "$(_mdim)" "$(printf '─%.0s' $(seq 1 50))" "$(_mr)"

    for lf in "${layouts[@]}"; do
        local lname="${lf##*/}"  lname="${lname%.json}"
        local lcount ldate
        lcount="$(python3 -c "import json; print(len(json.load(open('${lf}'))))" \
                  2>/dev/null || echo '?')"
        ldate="$(stat -c '%y' "$lf" 2>/dev/null | cut -c1-16)"

        printf '  %s%-20s%s  %s%-10s%s  %s%s%s\n' \
            "$(_msky)" "$lname" "$(_mr)" \
            "$(_mgreen)" "$lcount monitors" "$(_mr)" \
            "$(_mdim)" "$ldate" "$(_mr)"
    done
}

_layout_restore() {
    local name="${1:-default}"
    local layout_file="${_LAYOUT_STORE}/${name}.json"

    if [[ ! -f "$layout_file" ]]; then
        mon_fail "Layout not found: ${name}"
        _layout_list
        return 1
    fi

    mon_step "Restoring layout: ${name}..."

    python3 - "$layout_file" << 'PYEOF' | while IFS='|' read -r mon_name w h hz x y scale; do
import json, sys

data = json.load(open(sys.argv[1]))
for m in data:
    if m.get('disabled'):
        print(f"{m['name']}|disabled|0|0|0|0|1")
    else:
        print(
            m['name'], m.get('width',1920), m.get('height',1080),
            m.get('refreshRate',60), m.get('x',0), m.get('y',0),
            m.get('scale',1),
            sep='|'
        )
PYEOF
        if [[ "$w" == "disabled" ]]; then
            mon_info "Skipping disabled: ${mon_name}"
            continue
        fi
        mon_apply "$mon_name" "$w" "$h" "$hz" "$x" "$y" "$scale"
    done

    mon_ok "Layout '${name}' restored"
    [[ "${ASH_MON_SAVE:-0}" -eq 1 ]] && mon_save_config
    mon_notify "🗺️  Layout Restored" "${name}"
}

_layout_delete() {
    local name="${1:-}"
    [[ -z "$name" ]] && { mon_fail "Specify layout name to delete"; return 1; }
    local layout_file="${_LAYOUT_STORE}/${name}.json"
    [[ ! -f "$layout_file" ]] && { mon_fail "Layout not found: ${name}"; return 1; }

    rm -f "$layout_file"
    mon_ok "Layout deleted: ${name}"
}

ash_monitor_layout() {
    local action="list"
    local layout_name="default"

    for arg in "${@:-}"; do
        case "$arg" in
            --save|-s)       action="save"    ;;
            --restore|-r)    action="restore" ;;
            --list|-l)       action="list"    ;;
            --delete|-d)     action="delete"  ;;
            --name=*)        layout_name="${arg#*=}" ;;
            *)  [[ "$action" == "list" ]] || layout_name="$arg" ;;
        esac
    done

    mon_section "🗺️ " "Monitor Layout" "$(_mpink)"
    mon_kv "Backend" "$MON_BACKEND"

    case "$action" in
        save)    _layout_save    "$layout_name" ;;
        restore) _layout_restore "$layout_name" ;;
        list)    _layout_list                   ;;
        delete)  _layout_delete  "$layout_name" ;;
    esac

    printf '\n'
}
