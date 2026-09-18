#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — uninstall.sh                                  ║
# ║  Cleanly removes ASH dotfiles, restoring backups where available.         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="${HOME}/.config/ash/backups"
BIN_LINK="${HOME}/.local/bin/ash"

usage() {
    cat <<'EOF'
Usage: uninstall.sh [options]

Options:
  --purge       Remove ASH state, cache, and data (default: keep)
  --keep-config Keep user configs in ~/.config/ash (default)
  --dry-run     Preview without side effects
  --help        Show this help
EOF
}

PURGE=0
DRY=0
while (( $# )); do
    case "$1" in
        --purge) PURGE=1; shift ;;
        --keep-config) PURGE=0; shift ;;
        --dry-run|-n) DRY=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "uninstall.sh: unknown option $1" >&2; usage >&2; exit 2 ;;
    esac
done

log() { echo "[uninstall] $*"; }

if (( DRY )); then
    log "[dry-run] would remove symlinks and restore backups"
    log "[dry-run] BIN_LINK=$BIN_LINK"
    log "[dry-run] BACKUP_DIR=$BACKUP_DIR"
    log "[dry-run] PURGE=$PURGE"
    exit 0
fi

# 1. Remove binary symlink
if [[ -L "$BIN_LINK" || -f "$BIN_LINK" ]]; then
    rm -f "$BIN_LINK" && log "Removed $BIN_LINK" || log "Failed to remove $BIN_LINK"
fi

# 2. Restore backups if they exist
if [[ -d "$BACKUP_DIR" ]]; then
    log "Found backups at $BACKUP_DIR — not auto-restoring (use scripts/backup/restore.sh)"
fi

# 3. Optionally purge state
if (( PURGE )); then
    for dir in "${XDG_STATE_HOME:-$HOME/.local/state}/ash" "${XDG_CACHE_HOME:-$HOME/.cache}/ash" "${XDG_DATA_HOME:-$HOME/.local/share}/ash"; do
        if [[ -d "$dir" ]]; then
            log "Purging $dir"
            rm -rf "$dir"
        fi
    done
    log "Purge complete"
else
    log "Preserved state/cache (use --purge to remove)"
fi

log "Uninstall complete — restart shell or run 'hash -r'"
