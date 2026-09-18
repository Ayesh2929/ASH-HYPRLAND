#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — store browse                                  ║
# ║  Sourced by ash store dispatcher; defines store::browse.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_STORE_BROWSE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_STORE_BROWSE_LOADED=1

store::browse::help() {
    cat <<'EOF'
ash store browse — browse store

Usage:
  ash store browse [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

store::browse() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) store::browse::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash store browse: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "browse" in
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
                    printf '{"group":"store","sub":"browse","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available store (browse):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "store browse: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash store browse: requires an ID — usage: ash store browse <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash store browse: placeholder — would install/create store item (not yet wired to store)" 
            ash_log_info "ash store browse: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash store browse: placeholder — would remove store item" 
            ;;
        *)
            echo "ash store browse: placeholder executed with args: $*" 
            ash_log_info "ash store browse $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    store::browse "$@"
fi
