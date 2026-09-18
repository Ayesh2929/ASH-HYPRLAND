#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — remote sync-config                                  ║
# ║  Sourced by ash remote dispatcher; defines remote::sync_config.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_REMOTE_SYNC_CONFIG_LOADED:-}" ]] && return 0
readonly _ASH_CMD_REMOTE_SYNC_CONFIG_LOADED=1

remote::sync_config::help() {
    cat <<'EOF'
ash remote sync-config — sync config remote

Usage:
  ash remote sync-config [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

remote::sync_config() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) remote::sync_config::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash remote sync-config: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "sync-config" in
        list|browse|search|trending)
            local reg_dir=""
            case "remote" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"remote","sub":"sync-config","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available remote (sync-config):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "remote sync-config: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash remote sync-config: requires an ID — usage: ash remote sync-config <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash remote sync-config: placeholder — would install/create remote item (not yet wired to store)" 
            ash_log_info "ash remote sync-config: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash remote sync-config: placeholder — would remove remote item" 
            ;;
        *)
            echo "ash remote sync-config: placeholder executed with args: $*" 
            ash_log_info "ash remote sync-config $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    remote::sync_config "$@"
fi
