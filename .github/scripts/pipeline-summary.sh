#!/usr/bin/env bash
set -euo pipefail

# This script generates a rich GitHub Job Summary
# Assumes env vars or arguments are provided for job statuses

OUTPUT_FILE="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

OVERALL="${1:-success}"
BRANCH="${GITHUB_REF_NAME:-unknown}"
COMMIT="${GITHUB_SHA:-unknown}"
SHORT_SHA="${COMMIT:0:7}"
ACTOR="${GITHUB_ACTOR:-unknown}"
RUN_ID="${GITHUB_RUN_ID:-unknown}"
REPO="${GITHUB_REPOSITORY:-unknown}"
SERVER="${GITHUB_SERVER_URL:-https://github.com}"
EVENT="${GITHUB_EVENT_NAME:-unknown}"

RUN_URL="${SERVER}/${REPO}/actions/runs/${RUN_ID}"

LABEL="✅ PASSED"
if [[ "$OVERALL" != "success" ]]; then
    LABEL="❌ FAILED"
fi

cat >> "$OUTPUT_FILE" << MDEOF
# 🚀 ASH Dotfiles — Pipeline Summary

## ${LABEL}

| | |
|---|---|
| **Branch** | \`${BRANCH}\` |
| **Commit** | \`${SHORT_SHA}\` |
| **Trigger** | ${EVENT} by @${ACTOR} |
| **Run** | [${RUN_ID}](${RUN_URL}) |

---

## 🔒 Security

| Job | Status |
|-----|--------|
| Secret Scanning   | ${SEC_SECRETS:-❓} |
| Dependency Audit  | ${SEC_DEPS:-❓} |
| CodeQL Analysis   | ${SEC_CODEQL:-❓} |
| Permissions Audit | ${SEC_PERMS:-❓} |

## ✅ Linting

| Job | Status |
|-----|--------|
| ShellCheck    | ${LINT_SH:-❓} |
| Luacheck      | ${LINT_LUA:-❓} |
| JSON/YAML/TOML| ${LINT_CFG:-❓} |
| TypeScript    | ${LINT_TS:-❓} |
| Python (Ruff) | ${LINT_PY:-❓} |
| Hyprland Conf | ${LINT_HYPR:-❓} |
| Fish Shell    | ${LINT_FISH:-❓} |

## 🧪 Tests

| Job | Status |
|-----|--------|
| Shell Unit Tests    | ${TEST_SH:-❓} |
| Theme Engine        | ${TEST_THEME:-❓} |
| Plugin System       | ${TEST_PLUGIN:-❓} |

## 🏗️ Build

| Job | Status |
|-----|--------|
| Web Dashboard | ${BUILD_WEB:-❓} |
| Docker Image  | ${BUILD_DOCKER:-❓} |

---
MDEOF
