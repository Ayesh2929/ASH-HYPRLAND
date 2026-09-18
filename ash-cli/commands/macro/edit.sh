#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — macro edit                                  ║
# ║  Sourced by ash macro dispatcher; defines macro::edit.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_MACRO_EDIT_LOADED:-}" ]] && return 0
readonly _ASH_CMD_MACRO_EDIT_LOADED=1

macro::edit::help() {
    cat <<'EOF'
ash macro edit — edit macro

Usage:
  ash macro edit [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

macro::edit() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) macro::edit::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash macro edit: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "edit" in
        list|browse|search|trending)
            local reg_dir=""
            case "macro" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"macro","sub":"edit","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available macro (edit):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "macro edit: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash macro edit: requires an ID — usage: ash macro edit <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash macro edit: placeholder — would install/create macro item (not yet wired to store)" 
            ash_log_info "ash macro edit: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash macro edit: placeholder — would remove macro item" 
            ;;
        *)
            echo "ash macro edit: placeholder executed with args: $*" 
            ash_log_info "ash macro edit $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    macro::edit "$@"
fi
