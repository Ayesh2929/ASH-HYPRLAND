#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — store trending                                  ║
# ║  Sourced by ash store dispatcher; defines store::trending.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_STORE_TRENDING_LOADED:-}" ]] && return 0
readonly _ASH_CMD_STORE_TRENDING_LOADED=1

store::trending::help() {
    cat <<'EOF'
ash store trending — trending store

Usage:
  ash store trending [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

store::trending() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) store::trending::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash store trending: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "trending" in
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
                    printf '{"group":"store","sub":"trending","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available store (trending):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "store trending: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash store trending: requires an ID — usage: ash store trending <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash store trending: placeholder — would install/create store item (not yet wired to store)" 
            ash_log_info "ash store trending: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash store trending: placeholder — would remove store item" 
            ;;
        *)
            echo "ash store trending: placeholder executed with args: $*" 
            ash_log_info "ash store trending $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    store::trending "$@"
fi
