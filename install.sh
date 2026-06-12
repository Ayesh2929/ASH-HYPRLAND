#!/bin/bash
set -euo pipefail

# ASH Dotfiles - Root Install Wrapper
# Delegates to the main installer at scripts/install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_INSTALLER="${SCRIPT_DIR}/scripts/install.sh"

if [[ ! -f "${MAIN_INSTALLER}" ]]; then
    echo "Error: Main installer not found at ${MAIN_INSTALLER}" >&2
    exit 1
fi

exec bash "${MAIN_INSTALLER}" "$@"