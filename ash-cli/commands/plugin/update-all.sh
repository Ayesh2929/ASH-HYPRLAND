#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — plugin update-all                                  ║
# ║  Sourced by ash plugin dispatcher; defines plugin::update_all.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PLUGIN_UPDATE_ALL_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PLUGIN_UPDATE_ALL_LOADED=1

plugin::update_all::help() {
    cat <<'EOF'
ash plugin update-all — update all plugin

Usage:
  ash plugin update-all [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

plugin::update_all() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) plugin::update_all::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash plugin update-all: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "update-all" in
        list|browse|search|trending)
            local reg_dir=""
            case "plugin" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"plugin","sub":"update-all","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available plugin (update-all):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "plugin update-all: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash plugin update-all: requires an ID — usage: ash plugin update-all <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash plugin update-all: placeholder — would install/create plugin item (not yet wired to store)" 
            ash_log_info "ash plugin update-all: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash plugin update-all: placeholder — would remove plugin item" 
            ;;
        *)
            echo "ash plugin update-all: placeholder executed with args: $*" 
            ash_log_info "ash plugin update-all $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin::update_all "$@"
fi
