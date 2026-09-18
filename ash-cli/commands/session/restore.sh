#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — session restore                                  ║
# ║  Sourced by ash session dispatcher; defines session::restore.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_SESSION_RESTORE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_SESSION_RESTORE_LOADED=1

session::restore::help() {
    cat <<'EOF'
ash session restore — restore session

Usage:
  ash session restore [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

session::restore() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) session::restore::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash session restore: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "restore" in
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
                    printf '{"group":"session","sub":"restore","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available session (restore):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "session restore: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash session restore: requires an ID — usage: ash session restore <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash session restore: placeholder — would install/create session item (not yet wired to store)" 
            ash_log_info "ash session restore: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash session restore: placeholder — would remove session item" 
            ;;
        *)
            echo "ash session restore: placeholder executed with args: $*" 
            ash_log_info "ash session restore $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    session::restore "$@"
fi
