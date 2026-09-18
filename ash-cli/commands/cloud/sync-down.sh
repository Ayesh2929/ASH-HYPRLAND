#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — cloud sync-down                                  ║
# ║  Sourced by ash cloud dispatcher; defines cloud::sync_down.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_CLOUD_SYNC_DOWN_LOADED:-}" ]] && return 0
readonly _ASH_CMD_CLOUD_SYNC_DOWN_LOADED=1

cloud::sync_down::help() {
    cat <<'EOF'
ash cloud sync-down — sync down cloud

Usage:
  ash cloud sync-down [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

cloud::sync_down() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) cloud::sync_down::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash cloud sync-down: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "sync-down" in
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
                    printf '{"group":"cloud","sub":"sync-down","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available cloud (sync-down):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "cloud sync-down: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash cloud sync-down: requires an ID — usage: ash cloud sync-down <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash cloud sync-down: placeholder — would install/create cloud item (not yet wired to store)" 
            ash_log_info "ash cloud sync-down: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash cloud sync-down: placeholder — would remove cloud item" 
            ;;
        *)
            echo "ash cloud sync-down: placeholder executed with args: $*" 
            ash_log_info "ash cloud sync-down $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cloud::sync_down "$@"
fi
