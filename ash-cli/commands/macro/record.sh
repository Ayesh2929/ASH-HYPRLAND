#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — macro record                                  ║
# ║  Sourced by ash macro dispatcher; defines macro::record.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_MACRO_RECORD_LOADED:-}" ]] && return 0
readonly _ASH_CMD_MACRO_RECORD_LOADED=1

macro::record::help() {
    cat <<'EOF'
ash macro record — record macro

Usage:
  ash macro record [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

macro::record() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) macro::record::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash macro record: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "record" in
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
                    printf '{"group":"macro","sub":"record","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available macro (record):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "macro record: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash macro record: requires an ID — usage: ash macro record <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash macro record: placeholder — would install/create macro item (not yet wired to store)" 
            ash_log_info "ash macro record: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash macro record: placeholder — would remove macro item" 
            ;;
        *)
            echo "ash macro record: placeholder executed with args: $*" 
            ash_log_info "ash macro record $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    macro::record "$@"
fi
