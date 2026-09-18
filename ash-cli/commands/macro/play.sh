#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — macro play                                  ║
# ║  Sourced by ash macro dispatcher; defines macro::play.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_MACRO_PLAY_LOADED:-}" ]] && return 0
readonly _ASH_CMD_MACRO_PLAY_LOADED=1

macro::play::help() {
    cat <<'EOF'
ash macro play — play macro

Usage:
  ash macro play [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

macro::play() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) macro::play::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash macro play: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "play" in
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
                    printf '{"group":"macro","sub":"play","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available macro (play):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "macro play: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash macro play: requires an ID — usage: ash macro play <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash macro play: placeholder — would install/create macro item (not yet wired to store)" 
            ash_log_info "ash macro play: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash macro play: placeholder — would remove macro item" 
            ;;
        *)
            echo "ash macro play: placeholder executed with args: $*" 
            ash_log_info "ash macro play $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    macro::play "$@"
fi
