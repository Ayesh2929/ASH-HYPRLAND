#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — analytics command-stats                                  ║
# ║  Sourced by ash analytics dispatcher; defines analytics::command_stats.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_ANALYTICS_COMMAND_STATS_LOADED:-}" ]] && return 0
readonly _ASH_CMD_ANALYTICS_COMMAND_STATS_LOADED=1

analytics::command_stats::help() {
    cat <<'EOF'
ash analytics command-stats — command stats analytics

Usage:
  ash analytics command-stats [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

analytics::command_stats() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) analytics::command_stats::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash analytics command-stats: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "command-stats" in
        list|browse|search|trending)
            local reg_dir=""
            case "analytics" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"analytics","sub":"command-stats","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available analytics (command-stats):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "analytics command-stats: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash analytics command-stats: requires an ID — usage: ash analytics command-stats <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash analytics command-stats: placeholder — would install/create analytics item (not yet wired to store)" 
            ash_log_info "ash analytics command-stats: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash analytics command-stats: placeholder — would remove analytics item" 
            ;;
        *)
            echo "ash analytics command-stats: placeholder executed with args: $*" 
            ash_log_info "ash analytics command-stats $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analytics::command_stats "$@"
fi
