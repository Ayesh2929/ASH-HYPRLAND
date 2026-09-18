#!/bin/bash
set -euo pipefail

# ASH Dotfiles - Root Install Wrapper
# Resolves the real installer in priority order:
#   1. scripts/install.sh          (legacy single-file)
#   2. scripts/install/install.sh  (new layout)
#   3. scripts/core/install.sh     (canonical)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANDIDATES=(
  "${SCRIPT_DIR}/scripts/install.sh"
  "${SCRIPT_DIR}/scripts/install/install.sh"
  "${SCRIPT_DIR}/scripts/core/install.sh"
)
MAIN_INSTALLER=""
for c in "${CANDIDATES[@]}"; do
  if [[ -f "$c" ]]; then MAIN_INSTALLER="$c"; break; fi
done

if [[ -z "${MAIN_INSTALLER}" ]]; then
  echo "Error: No installer found. Tried:" >&2
  printf '  - %s\n' "${CANDIDATES[@]}" >&2
  exit 1
fi

# If the chosen installer is a stub (contains omega-stub), prefer the canonical one
if grep -q "omega.*stub" "${MAIN_INSTALLER}" 2>/dev/null && [[ -f "${SCRIPT_DIR}/scripts/core/install.sh" ]] && ! grep -q "omega.*stub" "${SCRIPT_DIR}/scripts/core/install.sh" 2>/dev/null; then
  MAIN_INSTALLER="${SCRIPT_DIR}/scripts/core/install.sh"
fi

exec bash "${MAIN_INSTALLER}" "$@"
