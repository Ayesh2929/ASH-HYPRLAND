#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — plugin install                                  ║
# ║  Sourced by ash plugin dispatcher; defines plugin::install.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PLUGIN_INSTALL_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PLUGIN_INSTALL_LOADED=1

plugin::install::help() {
    cat <<'EOF'
ash plugin install — install plugin

Usage:
  ash plugin install [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

plugin::install() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) plugin::install::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash plugin install: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "install" in
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
                    printf '{"group":"plugin","sub":"install","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available plugin (install):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "plugin install: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash plugin install: requires an ID — usage: ash plugin install <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash plugin install: placeholder — would install/create plugin item (not yet wired to store)" 
            ash_log_info "ash plugin install: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash plugin install: placeholder — would remove plugin item" 
            ;;
        *)
            echo "ash plugin install: placeholder executed with args: $*" 
            ash_log_info "ash plugin install $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    plugin::install "$@"
fi
