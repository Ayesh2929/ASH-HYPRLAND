#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — profile switch                                  ║
# ║  Sourced by ash profile dispatcher; defines profile::switch.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PROFILE_SWITCH_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PROFILE_SWITCH_LOADED=1

profile::switch::help() {
    cat <<'EOF'
ash profile switch — switch profile

Usage:
  ash profile switch [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

profile::switch() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) profile::switch::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash profile switch: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "switch" in
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
                    printf '{"group":"profile","sub":"switch","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available profile (switch):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "profile switch: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash profile switch: requires an ID — usage: ash profile switch <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash profile switch: placeholder — would install/create profile item (not yet wired to store)" 
            ash_log_info "ash profile switch: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash profile switch: placeholder — would remove profile item" 
            ;;
        *)
            echo "ash profile switch: placeholder executed with args: $*" 
            ash_log_info "ash profile switch $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    profile::switch "$@"
fi
