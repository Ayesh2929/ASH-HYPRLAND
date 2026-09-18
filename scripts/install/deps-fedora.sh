#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — deps-fedora.sh                                            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail
IFS=$'\n\t'
# Minimal dep installer — lists packages that would be installed.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CORE="${ROOT}/scripts/core/install.sh"
if [[ -f "${CORE}" ]]; then
  if bash "${CORE}" --help 2>&1 | grep -q "dry-run"; then
    exec bash "${CORE}" --dry-run --distro fedora "$@"
  fi
fi
echo "ASH deps (fedora): would install base packages for fedora"
PACKAGES=(hyprland waybar rofi kitty fish jq python3)
printf '  - %s\n' "${PACKAGES[@]}"
exit 0
