#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — analytics export-report                                  ║
# ║  Sourced by ash analytics dispatcher; defines analytics::export_report.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_ANALYTICS_EXPORT_REPORT_LOADED:-}" ]] && return 0
readonly _ASH_CMD_ANALYTICS_EXPORT_REPORT_LOADED=1

analytics::export_report::help() {
    cat <<'EOF'
ash analytics export-report — export report analytics

Usage:
  ash analytics export-report [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

analytics::export_report() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) analytics::export_report::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash analytics export-report: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "export-report" in
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
                    printf '{"group":"analytics","sub":"export-report","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available analytics (export-report):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "analytics export-report: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash analytics export-report: requires an ID — usage: ash analytics export-report <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash analytics export-report: placeholder — would install/create analytics item (not yet wired to store)" 
            ash_log_info "ash analytics export-report: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash analytics export-report: placeholder — would remove analytics item" 
            ;;
        *)
            echo "ash analytics export-report: placeholder executed with args: $*" 
            ash_log_info "ash analytics export-report $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    analytics::export_report "$@"
fi
