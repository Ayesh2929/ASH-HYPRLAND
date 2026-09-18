#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — plugin validate                                  ║
# ║  Sourced by ash plugin dispatcher; defines plugin::validate.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PLUGIN_VALIDATE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PLUGIN_VALIDATE_LOADED=1

plugin::validate::help() {
    cat <<'EOF'
ash plugin validate — validate plugin

Usage:
  ash plugin validate [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

plugin::validate() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) plugin::validate::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash plugin validate: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "validate" in
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
                    printf '{"group":"plugin","sub":"validate","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available plugin (validate):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "plugin validate: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash plugin validate: requires an ID — usage: ash plugin validate <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash plugin validate: placeholder — would install/create plugin item (not yet wired to store)" 
            ash_log_info "ash plugin validate: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash plugin validate: placeholder — would remove plugin item" 
            ;;
        *)
            echo "ash plugin validate: placeholder executed with args: $*" 
            ash_log_info "ash plugin validate $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin::validate "$@"
fi
