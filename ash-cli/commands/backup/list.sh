#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  ASH CLI v5.0 OMEGA  ─  backup list                                              ║
# ║  Rich backup listing with timeline view, size bars, and metadata                ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝

[[ "${_ASH_BK_LIST_LOADED:-}" == "1" ]] && return 0
readonly _ASH_BK_LIST_LOADED=1

set -euo pipefail
IFS=$'\n\t'

_list_render() {
    local filter_type="${1:-}"

    python3 - "$filter_type" << PYEOF
import json, os, sys

no_color = os.environ.get('ASH_FLAG_NO_COLOR','0') == '1'
R      = '' if no_color else '\033[0m'
BOLD   = '' if no_color else '\033[1m'
DIM    = '' if no_color else '\033[38;2;108;112;134m'
SKY    = '' if no_color else '\033[38;2;137;220;235m'
GRN    = '' if no_color else '\033[38;2;166;227;161m'
MAUVE  = '' if no_color else '\033[1;38;2;203;166;247m'
BLUE   = '' if no_color else '\033[38;2;137;180;250m'
TEAL   = '' if no_color else '\033[38;2;148;226;213m'
PEACH  = '' if no_color else '\033[38;2;250;179;135m'
YELL   = '' if no_color else '\033[38;2;249;226;175m'
RED    = '' if no_color else '\033[38;2;243;139;168m'
DIM2   = '' if no_color else '\033[38;2;88;91;112m'

filter_type = sys.argv[1]

try:
    data = json.load(open('${_BK_INDEX_FILE}'))
except:
    print(f'  {DIM}No backup index found. Create a backup first: ash bk create{R}')
    sys.exit(0)

if filter_type:
    data = {k:v for k,v in data.items() if v.get('type') == filter_type}

if not data:
    print(f'  {DIM}No backups{"" if not filter_type else " of type: " + filter_type}{R}')
    sys.exit(0)

# Sort by date
items = sorted(data.items(), key=lambda x: x[1].get('created_at',''), reverse=True)

# Stats
total_size = sum(v.get('size_bytes',0) for _,v in items)
max_size   = max((v.get('size_bytes',0) for _,v in items), default=1)

def fmt_size(b):
    if b >= 1073741824: return f'{b/1073741824:.1f}GB'
    if b >= 1048576:    return f'{b/1048576:.1f}MB'
    if b >= 1024:       return f'{b/1024:.1f}KB'
    return f'{b}B'

def size_bar(size, max_sz, width=15):
    filled = int(size * width / max(max_sz, 1))
    empty  = width - filled
    return f'{BLUE}{"▇" * filled}{DIM2}{"░" * empty}{R}'

type_colors = {
    'full':          TEAL,
    'incremental':   PEACH,
    'differential':  YELL,
}

print(f'\n  {DIM}{"ID":<32} {"Created":<20} {"Type":<14} {"Size":<8} {"Enc"} {"Size Bar":<17} Status{R}')
print(f'  {DIM}{"─"*95}{R}')

for bk_id, entry in items:
    created   = entry.get('created_at','?')[:19]
    bk_type   = entry.get('type','?')
    size      = entry.get('size_bytes', 0)
    encrypted = f'{TEAL}🔐{R}' if entry.get('encrypted') else '  '
    status    = entry.get('status','ok')
    tags      = ','.join(entry.get('tags',[]))

    tc = type_colors.get(bk_type, DIM)
    sc = GRN if status == 'ok' else RED
    st = f'{sc}✓{R}' if status == 'ok' else f'{sc}✗{R}'

    print(f'  {SKY}{bk_id:<32}{R} {DIM}{created:<20}{R} '
          f'{tc}{bk_type:<14}{R} {DIM}{fmt_size(size):<8}{R} '
          f'{encrypted}  {size_bar(size, max_size)}  {st}'
          f'{" " + YELL + tags + R if tags else ""}')

total_sz = fmt_size(total_size)
print(f'\n  {DIM}Total: {SKY}{len(items)}{DIM} backup{"s" if len(items)!=1 else ""}  '
      f'•  {SKY}{total_sz}{DIM} used{R}')
PYEOF
}

_list_delete_interactive() {
    local bk_id="$1"
    local bk_path
    bk_path="$(bk_index_get "$bk_id" path)"

    printf '  %sDelete backup %s%s%s? [y/N] %s' \
        "$(_bkyellow)" "$(_bksky)" "$bk_id" "$(_bkyellow)" "$(_bkr)"
    local ans; read -r ans
    [[ "${ans,,}" != "y" ]] && { bk_info "Cancelled"; return 0; }

    [[ -n "$bk_path" ]] && [[ -f "$bk_path" ]] && \
        rm -f "$bk_path" && bk_ok "Archive deleted"

    local manifest="${_BK_MANIFEST_DIR}/${bk_id}.json"
    [[ -f "$manifest" ]] && rm -f "$manifest" && bk_ok "Manifest deleted"

    bk_index_remove "$bk_id"
    bk_ok "Index entry removed"
}

ash_backup_list() {
    local filter_type=""  action="list"  target_id=""
    local short=0

    for arg in "${@:-}"; do
        case "$arg" in
            --full|-f)         filter_type="full"         ;;
            --incremental|-i)  filter_type="incremental"  ;;
            --diff|-d)         filter_type="differential" ;;
            --short|-s)        short=1                    ;;
            --delete)          action="delete"            ;;
            ash-*)             target_id="$arg"           ;;
        esac
    done

    bk_section "📋" "Backup List" "$(_bklav)"

    if [[ "${ASH_FLAG_JSON_OUTPUT:-0}" -eq 1 ]]; then
        cat "$_BK_INDEX_FILE" 2>/dev/null || echo '{}'
        return 0
    fi

    case "$action" in
        list)
            _list_render "$filter_type"
            ;;
        delete)
            if [[ -z "$target_id" ]]; then
                bk_fail "Specify backup ID: ash bk list --delete ash-full-..."
                return 1
            fi
            _list_delete_interactive "$target_id"
            ;;
    esac

    bk_divider
    printf '\n'
}
