#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — store search                                  ║
# ║  Sourced by ash store dispatcher; defines store::search.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_STORE_SEARCH_LOADED:-}" ]] && return 0
readonly _ASH_CMD_STORE_SEARCH_LOADED=1

store::search::help() {
    cat <<'EOF'
ash store search — search store

Usage:
  ash store search [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

store::search() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) store::search::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash store search: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "search" in
        list|browse|search|trending)
            local reg_dir=""
            case "store" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"store","sub":"search","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available store (search):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "store search: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash store search: requires an ID — usage: ash store search <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash store search: placeholder — would install/create store item (not yet wired to store)" 
            ash_log_info "ash store search: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash store search: placeholder — would remove store item" 
            ;;
        *)
            echo "ash store search: placeholder executed with args: $*" 
            ash_log_info "ash store search $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    store::search "$@"
fi
