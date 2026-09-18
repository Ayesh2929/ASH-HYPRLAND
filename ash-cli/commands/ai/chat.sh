#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — ai chat                                  ║
# ║  Sourced by ash ai dispatcher; defines ai::chat.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_AI_CHAT_LOADED:-}" ]] && return 0
readonly _ASH_CMD_AI_CHAT_LOADED=1

ai::chat::help() {
    cat <<'EOF'
ash ai chat — chat ai

Usage:
  ash ai chat [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

ai::chat() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) ai::chat::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash ai chat: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "chat" in
        list|browse|search|trending)
            local reg_dir=""
            case "ai" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"ai","sub":"chat","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available ai (chat):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "ai chat: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash ai chat: requires an ID — usage: ash ai chat <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash ai chat: placeholder — would install/create ai item (not yet wired to store)" 
            ash_log_info "ash ai chat: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash ai chat: placeholder — would remove ai item" 
            ;;
        *)
            echo "ash ai chat: placeholder executed with args: $*" 
            ash_log_info "ash ai chat $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ai::chat "$@"
fi
