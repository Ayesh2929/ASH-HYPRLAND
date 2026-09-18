#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — remote apply-theme                                  ║
# ║  Sourced by ash remote dispatcher; defines remote::apply_theme.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_REMOTE_APPLY_THEME_LOADED:-}" ]] && return 0
readonly _ASH_CMD_REMOTE_APPLY_THEME_LOADED=1

remote::apply_theme::help() {
    cat <<'EOF'
ash remote apply-theme — apply theme remote

Usage:
  ash remote apply-theme [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

remote::apply_theme() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) remote::apply_theme::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash remote apply-theme: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "apply-theme" in
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
                    printf '{"group":"remote","sub":"apply-theme","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available remote (apply-theme):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "remote apply-theme: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash remote apply-theme: requires an ID — usage: ash remote apply-theme <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash remote apply-theme: placeholder — would install/create remote item (not yet wired to store)" 
            ash_log_info "ash remote apply-theme: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash remote apply-theme: placeholder — would remove remote item" 
            ;;
        *)
            echo "ash remote apply-theme: placeholder executed with args: $*" 
            ash_log_info "ash remote apply-theme $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    remote::apply_theme "$@"
fi
