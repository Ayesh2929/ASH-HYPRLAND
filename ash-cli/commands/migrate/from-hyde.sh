#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — migrate from-hyde                                  ║
# ║  Sourced by ash migrate dispatcher; defines migrate::from_hyde.               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

[[ -n "${_ASH_CMD_MIGRATE_FROM_HYDE_LOADED:-}" ]] && return 0
readonly _ASH_CMD_MIGRATE_FROM_HYDE_LOADED=1

migrate::from_hyde::help() {
    cat <<'EOF'
ash migrate from-hyde — from hyde migrate

Usage:
  ash migrate from-hyde [options]

Options:
  --help, -h    Show this help
  --json        Machine-readable output

EOF
}

migrate::from_hyde() {
    local json=0
    while (( $# )); do
        case "$1" in
            --help|-h) migrate::from_hyde::help; return 0 ;;
            --json) json=1; shift ;;
            --) shift; break ;;
            -*) echo "ash migrate from-hyde: unknown option $1" >&2; return 2 ;;
            *) break ;;
        esac
    done
    case "from-hyde" in
        list|browse|search|trending)
            local reg_dir=""
            case "migrate" in
                plugin)  reg_dir="${ROOT_DIR:-.}/plugins" ;;
                store)   reg_dir="${ROOT_DIR:-.}/themes" ;;
                profile) reg_dir="${ASH_PROFILES_DIR:-$HOME/.config/ash/profiles}" ;;
                *)       reg_dir="." ;;
            esac
            if [[ -d "$reg_dir" ]]; then
                if (( json )); then
                    printf '{"group":"migrate","sub":"from-hyde","items":['
                    local first=1
                    for f in "$reg_dir"/*; do
                        [[ -e "$f" ]] || continue
                        (( first )) && first=0 || printf ','
                        printf '%s' "$(printf '%s' "$(basename "$f")" | jq -Rs . 2>/dev/null || printf '"%s"' "$(basename "$f")")"
                    done
                    printf ']}\n'
                else
                    echo "Available migrate (from-hyde):"
                    for f in "$reg_dir"/*; do [[ -e "$f" ]] && echo "  - $(basename "$f")"; done
                fi
            else
                echo "migrate from-hyde: registry not found at $reg_dir" >&2
                return 0
            fi
            ;;
        info|show)
            echo "ash migrate from-hyde: requires an ID — usage: ash migrate from-hyde <id>" >&2
            return 2
            ;;
        install|create|add)
            echo "ash migrate from-hyde: placeholder — would install/create migrate item (not yet wired to store)" 
            ash_log_info "ash migrate from-hyde: $@ — placeholder success" 2>/dev/null || true
            ;;
        remove|delete|uninstall)
            echo "ash migrate from-hyde: placeholder — would remove migrate item" 
            ;;
        *)
            echo "ash migrate from-hyde: placeholder executed with args: $*" 
            ash_log_info "ash migrate from-hyde $* — shim" 2>/dev/null || true
            ;;
    esac
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    migrate::from_hyde "$@"
fi
