#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — session save                                  ║
# ║  Sourced by ash session dispatcher; defines session::save.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_SESSION_SAVE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_SESSION_SAVE_LOADED=1

session::save::help() {
    cat <<'EOF'
ash session save — save session

Usage:
  ash session save [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

session::save() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) session::save::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash session save: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "save" in
        list|browse|search|trending)
            local reg_dir=""
            case "session" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"session","sub":"save","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available session (save):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "session save: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash session save: requires an ID — usage: ash session save <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash session save: placeholder — would install/create session item (not yet wired to store)" 
            ash_log_info "ash session save: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash session save: placeholder — would remove session item" 
            ;;
        *)
            echo "ash session save: placeholder executed with args: $*" 
            ash_log_info "ash session save $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    session::save "$@"
fi
