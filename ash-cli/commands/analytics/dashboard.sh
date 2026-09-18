#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — analytics dashboard                                  ║
# ║  Sourced by ash analytics dispatcher; defines analytics::dashboard.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_ANALYTICS_DASHBOARD_LOADED:-}" ]] && return 0
readonly _ASH_CMD_ANALYTICS_DASHBOARD_LOADED=1

analytics::dashboard::help() {
    cat <<'EOF'
ash analytics dashboard — dashboard analytics

Usage:
  ash analytics dashboard [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

analytics::dashboard() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) analytics::dashboard::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash analytics dashboard: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "dashboard" in
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
                    printf '{"group":"analytics","sub":"dashboard","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available analytics (dashboard):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "analytics dashboard: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash analytics dashboard: requires an ID — usage: ash analytics dashboard <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash analytics dashboard: placeholder — would install/create analytics item (not yet wired to store)" 
            ash_log_info "ash analytics dashboard: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash analytics dashboard: placeholder — would remove analytics item" 
            ;;
        *)
            echo "ash analytics dashboard: placeholder executed with args: $*" 
            ash_log_info "ash analytics dashboard $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analytics::dashboard "$@"
fi
