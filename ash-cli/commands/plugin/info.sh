#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — plugin info                                  ║
# ║  Sourced by ash plugin dispatcher; defines plugin::info.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PLUGIN_INFO_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PLUGIN_INFO_LOADED=1

plugin::info::help() {
    cat <<'EOF'
ash plugin info — info plugin

Usage:
  ash plugin info [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

plugin::info() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) plugin::info::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash plugin info: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "info" in
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
                    printf '{"group":"plugin","sub":"info","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available plugin (info):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "plugin info: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash plugin info: requires an ID — usage: ash plugin info <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash plugin info: placeholder — would install/create plugin item (not yet wired to store)" 
            ash_log_info "ash plugin info: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash plugin info: placeholder — would remove plugin item" 
            ;;
        *)
            echo "ash plugin info: placeholder executed with args: $*" 
            ash_log_info "ash plugin info $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin::info "$@"
fi
