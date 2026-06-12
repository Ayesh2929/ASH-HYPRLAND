#!/bin/bash
set -euo pipefail

cd "${HOME}/.config/hypr" || exit 1
git pull
echo "Updated dotfiles"