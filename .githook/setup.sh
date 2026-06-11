#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.1.0 — GIT HOOKS INSTALLER                        ║
# ║           Sets up all git hooks for the project                            ║
# ║           Run once: bash .githooks/setup.sh                                ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="$(cd "${HOOKS_DIR}/.." && pwd)"
readonly GIT_HOOKS_DIR="${REPO_DIR}/.git/hooks"

# Colors
readonly R='\033[0m' B='\033[1m' G='\033[92m' Y='\033[93m'
readonly C='\033[96m' M='\033[95m' RED='\033[91m'

echo ""
echo -e "${B}${M}🪝 ASH Dotfiles — Git Hooks Setup${R}"
echo ""

# Method 1: Use git config (preferred — Git 2.9+)
GIT_VERSION=$(git version | grep -oP '\d+\.\d+' | head -1)
GIT_MAJOR=$(echo "${GIT_VERSION}" | cut -d. -f1)
GIT_MINOR=$(echo "${GIT_VERSION}" | cut -d. -f2)

if (( GIT_MAJOR > 2 )) || (( GIT_MAJOR == 2 && GIT_MINOR >= 9 )); then
    echo -e "  ${C}→${R} Using git config hooksPath (Git ${GIT_VERSION})"
    git config core.hooksPath .githooks
    echo -e "  ${G}✓${R} Hooks configured via core.hooksPath"
else
    # Method 2: Symlink hooks (older Git)
    echo -e "  ${C}→${R} Symlinking hooks (Git ${GIT_VERSION} < 2.9)"

    mkdir -p "${GIT_HOOKS_DIR}"

    for hook_file in "${HOOKS_DIR}"/*; do
        local hook_name
        hook_name=$(basename "${hook_file}")

        # Skip non-hook files
        [[ "${hook_name}" == "setup.sh" ]] && continue
        [[ "${hook_name}" == "*.md" ]] && continue
        [[ "${hook_name}" == "README" ]] && continue

        # Symlink
        ln -sf "${hook_file}" "${GIT_HOOKS_DIR}/${hook_name}"
        echo -e "  ${G}✓${R} Linked: ${hook_name}"
    done
fi

# Make all hooks executable
chmod +x "${HOOKS_DIR}"/pre-commit 2>/dev/null || true
chmod +x "${HOOKS_DIR}"/commit-msg 2>/dev/null || true
chmod +x "${HOOKS_DIR}"/prepare-commit-msg 2>/dev/null || true
chmod +x "${HOOKS_DIR}"/post-commit 2>/dev/null || true
chmod +x "${HOOKS_DIR}"/pre-push 2>/dev/null || true
chmod +x "${HOOKS_DIR}"/post-merge 2>/dev/null || true
chmod +x "${HOOKS_DIR}"/post-checkout 2>/dev/null || true
chmod +x "${HOOKS_DIR}"/pre-rebase 2>/dev/null || true

echo ""
echo -e "${G}${B}✅ Git hooks installed successfully!${R}"
echo ""
echo -e "  ${C}Hooks active:${R}"

for hook_file in "${HOOKS_DIR}"/*; do
    local name
    name=$(basename "${hook_file}")
    [[ "${name}" == "setup.sh" ]] && continue
    [[ "${name}" == *.md ]] && continue
    [[ "${name}" == README ]] && continue
    echo -e "    ${G}●${R} ${name}"
done

echo ""
echo -e "  ${Y}To disable hooks temporarily:${R}"
echo -e "    git commit --no-verify"
echo -e "    git push --no-verify"
echo ""
echo -e "  ${Y}To remove hooks:${R}"
echo -e "    git config --unset core.hooksPath"
echo ""