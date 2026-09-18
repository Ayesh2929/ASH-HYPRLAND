#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — plugin remove                                  ║
# ║  Sourced by ash plugin dispatcher; defines plugin::remove.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PLUGIN_REMOVE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PLUGIN_REMOVE_LOADED=1

plugin::remove::help() {
    cat <<'EOF'
ash plugin remove — remove plugin

Usage:
  ash plugin remove [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

plugin::remove() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) plugin::remove::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash plugin remove: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "remove" in
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
                    printf '{"group":"plugin","sub":"remove","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available plugin (remove):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "plugin remove: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash plugin remove: requires an ID — usage: ash plugin remove <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash plugin remove: placeholder — would install/create plugin item (not yet wired to store)" 
            ash_log_info "ash plugin remove: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash plugin remove: placeholder — would remove plugin item" 
            ;;
        *)
            echo "ash plugin remove: placeholder executed with args: $*" 
            ash_log_info "ash plugin remove $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin::remove "$@"
fi
