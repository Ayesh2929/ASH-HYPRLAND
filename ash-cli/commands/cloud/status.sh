#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — cloud status                                  ║
# ║  Sourced by ash cloud dispatcher; defines cloud::status.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_CLOUD_STATUS_LOADED:-}" ]] && return 0
readonly _ASH_CMD_CLOUD_STATUS_LOADED=1

cloud::status::help() {
    cat <<'EOF'
ash cloud status — status cloud

Usage:
  ash cloud status [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

cloud::status() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) cloud::status::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash cloud status: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "status" in
        list|browse|search|trending)
            local reg_dir=""
            case "cloud" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"cloud","sub":"status","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available cloud (status):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "cloud status: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash cloud status: requires an ID — usage: ash cloud status <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash cloud status: placeholder — would install/create cloud item (not yet wired to store)" 
            ash_log_info "ash cloud status: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash cloud status: placeholder — would remove cloud item" 
            ;;
        *)
            echo "ash cloud status: placeholder executed with args: $*" 
            ash_log_info "ash cloud status $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cloud::status "$@"
fi
