#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "ASH lint-all: checking shell, python, nix"
if command -v shellcheck &>/dev/null; then
  find "${ROOT}" -type f -name "*.sh" ! -path "*/.git/*" -print0 | xargs -0 shellcheck --severity=warning --exclude=SC1091,SC2034,SC2155 2>&1 | head -n 200 || true
fi
if [[ -d "${ROOT}/api" ]] && command -v ruff &>/dev/null; then
  (cd "${ROOT}/api" && ruff check . 2>&1 | head -n 100 || true)
fi
if command -v nixpkgs-fmt &>/dev/null; then
  find "${ROOT}" -name "*.nix" ! -path "*/.git/*" -exec nixpkgs-fmt --check {} \; 2>&1 | head -n 50 || true
fi
echo "lint-all: done"
