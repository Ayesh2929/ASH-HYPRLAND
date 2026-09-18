#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — profile list                                  ║
# ║  Sourced by ash profile dispatcher; defines profile::list.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PROFILE_LIST_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PROFILE_LIST_LOADED=1

profile::list::help() {
    cat <<'EOF'
ash profile list — list profile

Usage:
  ash profile list [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

profile::list() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) profile::list::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash profile list: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "list" in
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
                    printf '{"group":"profile","sub":"list","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available profile (list):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "profile list: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash profile list: requires an ID — usage: ash profile list <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash profile list: placeholder — would install/create profile item (not yet wired to store)" 
            ash_log_info "ash profile list: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash profile list: placeholder — would remove profile item" 
            ;;
        *)
            echo "ash profile list: placeholder executed with args: $*" 
            ash_log_info "ash profile list $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    profile::list "$@"
fi
