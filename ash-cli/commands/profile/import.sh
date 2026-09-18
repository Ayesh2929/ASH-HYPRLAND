#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — profile import                                  ║
# ║  Sourced by ash profile dispatcher; defines profile::import.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_PROFILE_IMPORT_LOADED:-}" ]] && return 0
readonly _ASH_CMD_PROFILE_IMPORT_LOADED=1

profile::import::help() {
    cat <<'EOF'
ash profile import — import profile

Usage:
  ash profile import [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

profile::import() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) profile::import::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash profile import: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "import" in
        list|browse|search|trending)
            local reg_dir=""
            case "profile" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"profile","sub":"import","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available profile (import):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "profile import: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash profile import: requires an ID — usage: ash profile import <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash profile import: placeholder — would install/create profile item (not yet wired to store)" 
            ash_log_info "ash profile import: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash profile import: placeholder — would remove profile item" 
            ;;
        *)
            echo "ash profile import: placeholder executed with args: $*" 
            ash_log_info "ash profile import $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    profile::import "$@"
fi
