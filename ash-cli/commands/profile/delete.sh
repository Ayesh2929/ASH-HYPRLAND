#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — profile delete                                  ║
# ║  Sourced by ash profile dispatcher; defines profile::delete.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PROFILE_DELETE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PROFILE_DELETE_LOADED=1

profile::delete::help() {
    cat <<'EOF'
ash profile delete — delete profile

Usage:
  ash profile delete [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

profile::delete() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) profile::delete::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash profile delete: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "delete" in
        list|browse|search|trending)
            local reg_dir=""
            case "profile" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"profile","sub":"delete","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available profile (delete):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "profile delete: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash profile delete: requires an ID — usage: ash profile delete <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash profile delete: placeholder — would install/create profile item (not yet wired to store)" 
            ash_log_info "ash profile delete: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash profile delete: placeholder — would remove profile item" 
            ;;
        *)
            echo "ash profile delete: placeholder executed with args: $*" 
            ash_log_info "ash profile delete $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    profile::delete "$@"
fi
