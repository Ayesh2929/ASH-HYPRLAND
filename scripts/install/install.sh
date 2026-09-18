#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — install.sh (layout router)                   ║
# ║  Delegates to the canonical core installer.                                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CORE="${ROOT}/scripts/core/install.sh"
if [[ -f "${CORE}" ]] && ! grep -q "omega.*stub" "${CORE}" 2>/dev/null; then
  exec bash "${CORE}" "$@"
fi
echo "ASH install: core installer missing at ${CORE}" >&2
exit 1
