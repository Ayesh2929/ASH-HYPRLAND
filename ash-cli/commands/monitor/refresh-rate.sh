#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — monitor refresh-rate                                  ║
# ║  Sourced by ash monitor dispatcher; defines monitor::refresh_rate.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_MONITOR_REFRESH_RATE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_MONITOR_REFRESH_RATE_LOADED=1

monitor::refresh_rate::help() {
    cat <<'EOF'
ash monitor refresh-rate — refresh rate monitor

Usage:
  ash monitor refresh-rate [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

monitor::refresh_rate() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) monitor::refresh_rate::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash monitor refresh-rate: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "refresh-rate" in
        list|browse|search|trending)
            local reg_dir=""
            case "monitor" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"monitor","sub":"refresh-rate","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available monitor (refresh-rate):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "monitor refresh-rate: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash monitor refresh-rate: requires an ID — usage: ash monitor refresh-rate <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash monitor refresh-rate: placeholder — would install/create monitor item (not yet wired to store)" 
            ash_log_info "ash monitor refresh-rate: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash monitor refresh-rate: placeholder — would remove monitor item" 
            ;;
        *)
            echo "ash monitor refresh-rate: placeholder executed with args: $*" 
            ash_log_info "ash monitor refresh-rate $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    monitor::refresh_rate "$@"
fi
