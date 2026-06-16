#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
# ║                                                                                           ║
# ║  🔔 ASH DOTFILES v5.0 OMEGA — DISCORD NOTIFICATION ENGINE                                ║
# ║                                                                                           ║
# ║  ███╗   ██╗ ██████╗ ████████╗██╗███████╗██╗   ██╗    ███████╗██╗  ██╗                    ║
# ║  ████╗  ██║██╔═══██╗╚══██╔══╝██║██╔════╝╚██╗ ██╔╝    ██╔════╝██║  ██║                    ║
# ║  ██╔██╗ ██║██║   ██║   ██║   ██║█████╗   ╚████╔╝     ███████╗███████║                    ║
# ║  ██║╚██╗██║██║   ██║   ██║   ██║██╔══╝    ╚██╔╝      ╚════██║██╔══██║                    ║
# ║  ██║ ╚████║╚██████╔╝   ██║   ██║██║        ██║        ███████║██║  ██║                    ║
# ║  ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝╚═╝        ╚═╝        ╚══════╝╚═╝  ╚═╝                    ║
# ║                                                                                           ║
# ║  Version:    5.0.0-omega                                                                 ║
# ║  Engine:     Pure Bash + Python hybrid                                                   ║
# ║  Pipeline:   validate → template → build-payload → fields → compress →                  ║
# ║              deliver-multi → retry → track → report                                     ║
# ║                                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
readonly NOTIFY_VERSION="5.0.0-omega"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly START_NS=$(date +%s%N 2>/dev/null || echo "0")
readonly START_MS=$(( START_NS / 1000000 ))
readonly DISCORD_API_BASE="https://discord.com/api/webhooks"
readonly DISCORD_MAX_PAYLOAD=6000    # Discord's 6000 char limit
readonly DISCORD_MAX_FIELDS=25
readonly DISCORD_MAX_EMBEDS=10

# ─────────────────────────────────────────────────────────────────────────────
# ENVIRONMENT (all injected from action.yml env block)
# ─────────────────────────────────────────────────────────────────────────────
TEMPLATE="${TEMPLATE:-custom}"
CONTENT="${CONTENT:-}"
BOT_USERNAME="${BOT_USERNAME:-}"
AVATAR_URL="${AVATAR_URL:-}"
TTS="${TTS:-false}"
EMBED_TITLE="${EMBED_TITLE:-}"
EMBED_DESC="${EMBED_DESC:-}"
EMBED_URL="${EMBED_URL:-}"
EMBED_COLOR="${EMBED_COLOR:-mauve}"
EMBED_TIMESTAMP="${EMBED_TIMESTAMP:-now}"
AUTHOR_NAME="${AUTHOR_NAME:-}"
AUTHOR_URL="${AUTHOR_URL:-}"
AUTHOR_ICON="${AUTHOR_ICON:-}"
THUMBNAIL_URL="${THUMBNAIL_URL:-}"
IMAGE_URL="${IMAGE_URL:-}"
FIELDS_JSON="${FIELDS_JSON:-}"
FOOTER_TEXT="${FOOTER_TEXT:-}"
FOOTER_ICON="${FOOTER_ICON:-}"
MENTION="${MENTION:-}"
MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_DELAY="${RETRY_DELAY:-2}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-15}"
FAIL_ON_ERROR="${FAIL_ON_ERROR:-false}"
PAYLOAD_FILE="${PAYLOAD_FILE:-}"
INCLUDE_GITHUB="${INCLUDE_GITHUB:-true}"
INCLUDE_RUN_LINK="${INCLUDE_RUN_LINK:-true}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
DEBUG_PAYLOAD="${DEBUG_PAYLOAD:-false}"
GITHUB_REPO="${GITHUB_REPO:-}"
GITHUB_SHA_SHORT="${GITHUB_SHA_SHORT:-}"
GITHUB_REF_NAME="${GITHUB_REF_NAME:-}"
GITHUB_ACTOR="${GITHUB_ACTOR:-}"
GITHUB_EVENT="${GITHUB_EVENT:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
GITHUB_SERVER="${GITHUB_SERVER:-https://github.com}"
GITHUB_WORKFLOW="${GITHUB_WORKFLOW:-}"
WEBHOOK_COUNT="${WEBHOOK_COUNT:-0}"

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA — COMPLETE 26-COLOR ANSI PALETTE
# ─────────────────────────────────────────────────────────────────────────────
C_RST='\033[0m'    C_BLD='\033[1m'    C_DIM='\033[2m'
C_MAUVE='\033[38;2;203;166;247m'   C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'   C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'  C_PEACH='\033[38;2;250;179;135m'
C_TEAL='\033[38;2;148;226;213m'    C_SAP='\033[38;2;116;199;236m'
C_SKY='\033[38;2;137;220;235m'     C_LAV='\033[38;2;180;190;254m'
C_TEXT='\033[38;2;205;214;244m'    C_SUB='\033[38;2;166;173;200m'
C_OVR='\033[38;2;108;112;134m'     C_PINK='\033[38;2;245;194;231m'
C_MAR='\033[38;2;235;160;172m'     C_RW='\033[38;2;245;224;220m'
C_FL='\033[38;2;242;205;205m'      C_SURF='\033[38;2;49;50;68m'

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING ENGINE
# ─────────────────────────────────────────────────────────────────────────────
_log() {
  local icon="$1" color="$2"; shift 2
  local ts; ts=$(date '+%H:%M:%S.%3N' 2>/dev/null || date '+%H:%M:%S')
  local elapsed_ms=$(( ($(date +%s%N 2>/dev/null || echo "0") / 1000000) - START_MS ))
  printf "${color}${icon}${C_RST} ${C_DIM}[%s +%dms]${C_RST} ${C_TEXT}%s${C_RST}\n" \
    "${ts}" "${elapsed_ms}" "$*"
}

log_send()    { _log "📡" "${C_MAUVE}"   "$@"; }
log_pass()    { _log "✅" "${C_GREEN}"   "$@"; }
log_fail()    { _log "❌" "${C_RED}"     "$@"; }
log_warn()    { _log "⚠️ " "${C_YELLOW}"  "$@"; }
log_info()    { _log "ℹ️ " "${C_BLUE}"    "$@"; }
log_retry()   { _log "🔄" "${C_PEACH}"   "$@"; }
log_build()   { _log "🏗️ " "${C_SAP}"     "$@"; }
log_tpl()     { _log "🏷️ " "${C_PINK}"    "$@"; }
log_dry()     { _log "🔍" "${C_LAV}"     "$@"; }
log_webhook() { _log "🔗" "${C_TEAL}"    "$@"; }
log_metric()  { _log "📊" "${C_RW}"      "$@"; }
log_debug()   { [[ "${VERBOSE}" == "true" ]] && _log "🔎" "${C_OVR}" "$@" || true; }

# ─────────────────────────────────────────────────────────────────────────────
# CATPPUCCIN MOCHA → DISCORD DECIMAL COLOR MAP
# ─────────────────────────────────────────────────────────────────────────────
declare -A COLOR_MAP=(
  # Catppuccin Mocha named colors
  ["rosewater"]="16113884"   # #f5e0dc
  ["flamingo"]="15912141"    # #f2cdcd
  ["pink"]="16073959"        # #f5c2e7
  ["mauve"]="13279991"       # #cba6f7
  ["red"]="15960232"         # #f38ba8
  ["maroon"]="15384748"      # #eba0ac
  ["peach"]="16431751"       # #fab387
  ["yellow"]="16319151"      # #f9e2af
  ["green"]="10993313"       # #a6e3a1
  ["teal"]="9756373"         # #94e2d5
  ["sky"]="8966379"          # #89dceb
  ["sapphire"]="7651308"     # #74c7ec
  ["blue"]="9019642"         # #89b4fa
  ["lavender"]="11857150"    # #b4befe
  # Semantic aliases
  ["success"]="10993313"     # green
  ["warning"]="16319151"     # yellow
  ["error"]="15960232"       # red
  ["critical"]="15384748"    # maroon
  ["info"]="9019642"         # blue
  ["neutral"]="4540506"      # surface1 (#45475a)
  # Template presets
  ["release"]="13279991"     # mauve
  ["deployment"]="9019642"   # blue
  ["ci-success"]="10993313"  # green
  ["ci-failure"]="15960232"  # red
  ["security"]="15384748"    # maroon
  ["benchmark"]="9756373"    # teal
  ["docs"]="11857150"        # lavender
  ["theme-drop"]="13279991"  # mauve
  ["plugin-drop"]="9019642"  # blue
  ["contributor"]="10993313" # green
  ["maintenance"]="16319151" # yellow
  ["regression"]="16431751"  # peach
)

resolve_color() {
  local input="$1"
  # Already decimal
  if [[ "${input}" =~ ^[0-9]+$ ]]; then
    echo "${input}"
    return
  fi
  # Hex with #
  if [[ "${input}" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    printf '%d' "0x${input#\#}"
    return
  fi
  # Named color
  local color="${COLOR_MAP[$input]:-}"
  [[ -n "${color}" ]] && echo "${color}" && return
  # Template name used as color
  color="${COLOR_MAP[$TEMPLATE]:-}"
  [[ -n "${color}" ]] && echo "${color}" && return
  # Default mauve
  echo "${COLOR_MAP["mauve"]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# WEBHOOK COLLECTION
# ─────────────────────────────────────────────────────────────────────────────
collect_webhooks() {
  declare -ga WEBHOOKS=()
  for var in \
    "${WEBHOOK_PRIMARY:-}" \
    "${WEBHOOK_2:-}" \
    "${WEBHOOK_3:-}" \
    "${WEBHOOK_4:-}" \
    "${WEBHOOK_5:-}"; do
    [[ -n "${var}" ]] && WEBHOOKS+=("${var}")
  done
  log_debug "webhooks" "Collected ${#WEBHOOKS[@]} webhook(s)"
}

# ─────────────────────────────────────────────────────────────────────────────
# TEMPLATE ENGINE — 12 built-in templates
# ─────────────────────────────────────────────────────────────────────────────
apply_template() {
  local tpl="${TEMPLATE}"
  local REPO_URL="${GITHUB_SERVER}/${GITHUB_REPO}"
  local RUN_URL="${REPO_URL}/actions/runs/${GITHUB_RUN_ID}"
  local SHA_SHORT="${GITHUB_SHA_SHORT:0:8}"

  log_tpl "template" "Applying: ${tpl}"

  case "${tpl}" in

    release)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="🚀 New Release: ${GITHUB_REF_NAME}"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="A new version of **ASH Dotfiles** has been released!\n\nInstall with:\n\`\`\`bash\nbash <(curl -fsSL https://ash.dev/install)\n\`\`\`"
      [[ -z "${THUMBNAIL_URL}" ]] && THUMBNAIL_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/assets/brand/logos/ash-logo-256.png"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles v5.0 OMEGA · Release Engine"
      [[ -z "${AUTHOR_NAME}" ]] && AUTHOR_NAME="@${GITHUB_ACTOR}"
      [[ -z "${AUTHOR_ICON}" ]] && AUTHOR_ICON="https://github.com/${GITHUB_ACTOR}.png?size=64"
      ;;

    deployment)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="🚀 Deployment: ${GITHUB_REF_NAME}"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="Deployment to production initiated by **@${GITHUB_ACTOR}**"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Deployment Engine"
      ;;

    ci-success)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="✅ CI Passed: ${GITHUB_WORKFLOW}"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="All checks passed for \`${GITHUB_REF_NAME}\` — commit \`${SHA_SHORT}\`"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · CI Engine"
      ;;

    ci-failure)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="❌ CI Failed: ${GITHUB_WORKFLOW}"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="Workflow **${GITHUB_WORKFLOW}** failed on \`${GITHUB_REF_NAME}\`\n\nCommit: \`${SHA_SHORT}\` by @${GITHUB_ACTOR}"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · CI Engine"
      ;;

    security)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="🔒 Security Advisory"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="⚠️ **A security issue has been identified** and requires immediate attention.\n\nReview the [Security Advisory](${REPO_URL}/security/advisories) for details."
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Security Team"
      ;;

    benchmark)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="⚡ Benchmark Results"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="Performance benchmark suite completed for \`${GITHUB_REF_NAME}\`"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles v5.0 OMEGA · Benchmark Runner"
      ;;

    docs)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="📖 Documentation Updated"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="Documentation has been rebuilt and deployed for \`${GITHUB_REF_NAME}\`\n\n[View Documentation](https://ash-dotfiles.dev)"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Documentation Engine"
      ;;

    theme-drop)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="🎨 New Themes Available!"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="Fresh themes have been added to the ASH theme library!\n\n\`ash theme pick\` to browse all 250+ themes"
      [[ -z "${THUMBNAIL_URL}" ]] && THUMBNAIL_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/assets/brand/logos/ash-logo-256.png"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Theme Engine"
      ;;

    plugin-drop)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="🔌 New Plugins Available!"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="New plugins have been added to the ASH ecosystem!\n\n\`ash plugin browse\` to explore 150+ plugins"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Plugin System"
      ;;

    contributor)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="🎉 New Contributor: @${GITHUB_ACTOR}"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="Welcome **@${GITHUB_ACTOR}** to the ASH Dotfiles community! 🙏\n\nThank you for your contribution!"
      [[ -z "${AUTHOR_NAME}" ]] && AUTHOR_NAME="@${GITHUB_ACTOR}"
      [[ -z "${AUTHOR_ICON}" ]] && AUTHOR_ICON="https://github.com/${GITHUB_ACTOR}.png?size=64"
      [[ -z "${AUTHOR_URL}" ]]  && AUTHOR_URL="https://github.com/${GITHUB_ACTOR}"
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Community"
      ;;

    maintenance)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="🔧 Maintenance Window"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="⚠️ ASH Dotfiles services are entering a **maintenance window**.\n\nExpected downtime: minimal. We'll notify when complete."
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Operations"
      ;;

    regression)
      [[ -z "${EMBED_TITLE}" ]]  && EMBED_TITLE="⚠️ Performance Regression Detected"
      [[ -z "${EMBED_DESC}" ]]   && EMBED_DESC="A performance regression has been detected in \`${GITHUB_REF_NAME}\`.\n\nImmediate investigation recommended."
      [[ -z "${FOOTER_TEXT}" ]] && FOOTER_TEXT="ASH Dotfiles · Benchmark Guard"
      ;;

    custom|*)
      log_debug "template" "Custom template — no auto-fill"
      ;;
  esac

  # Auto-set footer to ASH branding if completely empty
  if [[ -z "${FOOTER_TEXT}" ]]; then
    FOOTER_TEXT="ASH Dotfiles v5.0 OMEGA"
  fi
  if [[ -z "${FOOTER_ICON}" ]]; then
    FOOTER_ICON="https://raw.githubusercontent.com/${GITHUB_REPO}/main/assets/brand/logos/ash-logo-256.png"
  fi

  # Auto-thumbnail
  if [[ "${THUMBNAIL_URL}" == "auto" ]] || \
     [[ -z "${THUMBNAIL_URL}" && "${TEMPLATE}" != "custom" ]]; then
    THUMBNAIL_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/assets/brand/logos/ash-logo-256.png"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# MENTION RESOLVER
# ─────────────────────────────────────────────────────────────────────────────
resolve_mention() {
  local mention="${MENTION}"
  case "${mention}" in
    "@everyone")  echo "@everyone" ;;
    "@here")      echo "@here" ;;
    @role:*)
      local role_id="${mention#@role:}"
      echo "<@&${role_id}>"
      ;;
    @user:*)
      local user_id="${mention#@user:}"
      echo "<@${user_id}>"
      ;;
    ""|none)      echo "" ;;
    *)            echo "${mention}" ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# TIMESTAMP RESOLVER
# ─────────────────────────────────────────────────────────────────────────────
resolve_timestamp() {
  local ts="${EMBED_TIMESTAMP}"
  case "${ts}" in
    now|"true")  date -u +%Y-%m-%dT%H:%M:%SZ ;;
    ""|"false")  echo "" ;;
    *)           echo "${ts}" ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# FIELD BUILDER — Merge quick fields + JSON fields
# ─────────────────────────────────────────────────────────────────────────────
build_fields() {
  python3 << 'FIELDS_PY'
import json
import os
import sys

fields = []

# Load from JSON input
FIELDS_JSON = os.environ.get("FIELDS_JSON","").strip()
if FIELDS_JSON:
    try:
        parsed = json.loads(FIELDS_JSON)
        if isinstance(parsed, list):
            for f in parsed:
                if isinstance(f,dict) and f.get("name") and f.get("value"):
                    fields.append({
                        "name":   str(f["name"])[:256],
                        "value":  str(f["value"])[:1024],
                        "inline": bool(f.get("inline",True)),
                    })
    except json.JSONDecodeError as e:
        print(f"  ⚠️ FIELDS_JSON parse error: {e}", file=sys.stderr)

# Quick field shortcuts (F1_NAME .. F5_NAME)
for i in range(1, 6):
    name  = os.environ.get(f"F{i}_NAME","").strip()
    value = os.environ.get(f"F{i}_VALUE","").strip()
    if name and value:
        inline_raw = os.environ.get(f"F{i}_INLINE","true").lower()
        inline = inline_raw in ("true","1","yes","on")
        fields.append({
            "name":   name[:256],
            "value":  value[:1024],
            "inline": inline,
        })

# GitHub context fields (auto)
if os.environ.get("INCLUDE_GITHUB","true") == "true":
    ctx_fields = []
    repo       = os.environ.get("GITHUB_REPO","")
    ref        = os.environ.get("GITHUB_REF_NAME","")
    sha        = os.environ.get("GITHUB_SHA_SHORT","")[:8]
    actor      = os.environ.get("GITHUB_ACTOR","")
    event      = os.environ.get("GITHUB_EVENT","")
    run_id     = os.environ.get("GITHUB_RUN_ID","")
    server     = os.environ.get("GITHUB_SERVER","https://github.com")

    if repo:
        ctx_fields.append({"name":"📦 Repository","value":f"[{repo}]({server}/{repo})","inline":True})
    if ref:
        ctx_fields.append({"name":"🌿 Branch","value":f"`{ref}`","inline":True})
    if sha:
        ctx_fields.append({"name":"🔑 Commit","value":f"`{sha}`","inline":True})
    if actor:
        ctx_fields.append({"name":"👤 Actor","value":f"@{actor}","inline":True})
    if event:
        ctx_fields.append({"name":"📋 Event","value":f"`{event}`","inline":True})

    include_run = os.environ.get("INCLUDE_RUN_LINK","true") == "true"
    if include_run and run_id and repo:
        run_url = f"{server}/{repo}/actions/runs/{run_id}"
        ctx_fields.append({"name":"🔗 Run","value":f"[View Run]({run_url})","inline":True})

    # Insert at end (max 25 total fields)
    available = 25 - len(fields)
    fields.extend(ctx_fields[:available])

# Enforce Discord limits
fields = fields[:25]
print(json.dumps(fields))
FIELDS_PY
}

# ─────────────────────────────────────────────────────────────────────────────
# PAYLOAD BUILDER — Construct Discord webhook JSON
# ─────────────────────────────────────────────────────────────────────────────
build_payload() {
  local COLOR_DECIMAL
  COLOR_DECIMAL=$(resolve_color "${EMBED_COLOR}")
  local TIMESTAMP
  TIMESTAMP=$(resolve_timestamp)
  local MENTION_RESOLVED
  MENTION_RESOLVED=$(resolve_mention)
  local FIELDS_ARRAY
  FIELDS_ARRAY=$(build_fields)

  python3 << PAYLOAD_PY
import json
import os
import sys

COLOR          = int("${COLOR_DECIMAL}")
TIMESTAMP      = "${TIMESTAMP}"
MENTION_STR    = "${MENTION_RESOLVED}"
FIELDS_JSON_IN = '${FIELDS_ARRAY}'
TEMPLATE       = "${TEMPLATE}"
REPO           = os.environ.get("GITHUB_REPO","ash/dotfiles")
VERSION        = "${NOTIFY_VERSION}"

# ── Message content ────────────────────────────────────────────────────────────
content_parts = []
if MENTION_STR:
    content_parts.append(MENTION_STR)
raw_content = "${CONTENT}".strip()
if raw_content:
    content_parts.append(raw_content)
content = " ".join(content_parts)[:2000] if content_parts else None

# ── Embed construction ─────────────────────────────────────────────────────────
embed = {"color": COLOR}

title = "${EMBED_TITLE}".strip()
if title:
    embed["title"] = title[:256]

desc = "${EMBED_DESC}".strip().replace("\\n","\n")
if desc:
    embed["description"] = desc[:4096]

url = "${EMBED_URL}".strip()
if url:
    embed["url"] = url

if TIMESTAMP:
    embed["timestamp"] = TIMESTAMP

# Author
author_name = "${AUTHOR_NAME}".strip()
if author_name:
    author = {"name": author_name[:256]}
    author_url = "${AUTHOR_URL}".strip()
    if author_url: author["url"] = author_url
    author_icon = "${AUTHOR_ICON}".strip()
    if author_icon: author["icon_url"] = author_icon
    embed["author"] = author

# Thumbnail
thumb = "${THUMBNAIL_URL}".strip()
if thumb:
    embed["thumbnail"] = {"url": thumb}

# Large image
img = "${IMAGE_URL}".strip()
if img:
    embed["image"] = {"url": img}

# Fields
try:
    fields = json.loads(FIELDS_JSON_IN) if FIELDS_JSON_IN.strip() else []
    if fields:
        embed["fields"] = fields
except Exception as e:
    print(f"  ⚠️ Fields parse: {e}", file=sys.stderr)

# Footer
footer_text = "${FOOTER_TEXT}".strip()
if footer_text:
    footer = {"text": footer_text[:2048]}
    footer_icon = "${FOOTER_ICON}".strip()
    if footer_icon: footer["icon_url"] = footer_icon
    embed["footer"] = footer

# ── Top-level payload ──────────────────────────────────────────────────────────
payload = {}

username = "${BOT_USERNAME}".strip()
if username:
    payload["username"] = username[:80]

avatar = "${AVATAR_URL}".strip()
if avatar:
    payload["avatar_url"] = avatar

tts_val = "${TTS}".lower() in ("true","1","yes")
if tts_val:
    payload["tts"] = True

if content:
    payload["content"] = content

# Only include embed if it has meaningful content
has_content = any(k in embed for k in ["title","description","fields","author","image","thumbnail"])
if has_content:
    payload["embeds"] = [embed]

# ── Validate payload size ──────────────────────────────────────────────────────
payload_str = json.dumps(payload, ensure_ascii=False)
size = len(payload_str)
max_size = ${DISCORD_MAX_PAYLOAD}

if size > max_size:
    # Truncate description first
    if "embeds" in payload and payload["embeds"]:
        em = payload["embeds"][0]
        if "description" in em:
            excess = size - max_size + 100
            em["description"] = em["description"][:-excess] + "\n*[truncated]*"
        payload_str = json.dumps(payload, ensure_ascii=False)
        size = len(payload_str)

# Final validation: must have some content
if not content and not has_content:
    print(json.dumps({
        "username": username or "ASH Notifier",
        "content": "📡 ASH Dotfiles notification"
    }))
else:
    print(payload_str)

# Write size to tmp
with open("/tmp/ash-notify-payload-size.txt","w") as f:
    f.write(str(size))
PAYLOAD_PY
}

# ─────────────────────────────────────────────────────────────────────────────
# SINGLE WEBHOOK DELIVERY — with retry & exponential backoff
# ─────────────────────────────────────────────────────────────────────────────
deliver_webhook() {
  local webhook_url="$1"
  local payload="$2"
  local webhook_idx="${3:-1}"

  # Mask webhook URL in logs
  local masked_url
  masked_url=$(echo "${webhook_url}" | sed 's|/webhooks/[^/]*/[^?]*|/webhooks/***MASKED***|g')

  log_webhook "deliver" "[${webhook_idx}] → ${masked_url}"

  # Add thread_id if specified
  local full_url="${webhook_url}"
  if [[ -n "${THREAD_ID:-}" ]]; then
    full_url="${webhook_url}?thread_id=${THREAD_ID}&wait=true"
  else
    full_url="${webhook_url}?wait=true"
  fi

  local attempt=0
  local DELIVERED=false
  local RESPONSE_CODE=0
  local MESSAGE_ID=""

  while [[ "${attempt}" -lt "${MAX_RETRIES}" ]] && [[ "${DELIVERED}" == "false" ]]; do
    ((attempt++)) || true
    log_debug "deliver" "Attempt ${attempt}/${MAX_RETRIES}"

    # Execute HTTP request
    local HTTP_RESPONSE
    HTTP_RESPONSE=$(curl \
      --silent \
      --show-error \
      --write-out "\n%{http_code}" \
      --max-time "${TIMEOUT_SECONDS}" \
      --connect-timeout 10 \
      --retry 0 \
      -X POST \
      -H "Content-Type: application/json; charset=UTF-8" \
      -H "User-Agent: ASH-Dotfiles-Notifier/${NOTIFY_VERSION}" \
      -H "X-ASH-Session: ${SESSION_ID:-unknown}" \
      --data-binary "${payload}" \
      "${full_url}" \
      2>&1)

    # Extract HTTP status code (last line)
    RESPONSE_CODE=$(echo "${HTTP_RESPONSE}" | tail -1)
    local RESPONSE_BODY
    RESPONSE_BODY=$(echo "${HTTP_RESPONSE}" | head -n -1)

    log_debug "deliver" "HTTP ${RESPONSE_CODE}"

    case "${RESPONSE_CODE}" in
      204)
        # Success (no content)
        DELIVERED=true
        MESSAGE_ID="delivered-${webhook_idx}"
        log_pass "deliver" "[${webhook_idx}] Delivered (HTTP 204)"
        ;;
      200)
        # Success (with message ID)
        DELIVERED=true
        MESSAGE_ID=$(echo "${RESPONSE_BODY}" | python3 -c \
          "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" \
          2>/dev/null || echo "ok")
        log_pass "deliver" "[${webhook_idx}] Delivered (HTTP 200, msg=${MESSAGE_ID})"
        ;;
      429)
        # Rate limited — respect retry_after
        local RETRY_AFTER
        RETRY_AFTER=$(echo "${RESPONSE_BODY}" | python3 -c \
          "import sys,json; d=json.load(sys.stdin); print(d.get('retry_after',2))" \
          2>/dev/null || echo "${RETRY_DELAY}")
        log_retry "deliver" "[${webhook_idx}] Rate limited — waiting ${RETRY_AFTER}s"
        sleep "${RETRY_AFTER}"
        ;;
      400)
        # Bad request — don't retry
        local ERROR_MSG
        ERROR_MSG=$(echo "${RESPONSE_BODY}" | python3 -c \
          "import sys,json; d=json.load(sys.stdin); print(d.get('message','Bad Request'))" \
          2>/dev/null || echo "Bad Request")
        log_fail "deliver" "[${webhook_idx}] Bad Request: ${ERROR_MSG}"
        break  # Don't retry 400s
        ;;
      401|403)
        log_fail "deliver" "[${webhook_idx}] Auth failed (HTTP ${RESPONSE_CODE}) — check webhook URL"
        break  # Don't retry auth failures
        ;;
      404)
        log_fail "deliver" "[${webhook_idx}] Webhook not found (HTTP 404) — webhook may be deleted"
        break  # Don't retry 404s
        ;;
      000)
        # Connection failure
        log_warn "deliver" "[${webhook_idx}] Connection failed (attempt ${attempt})"
        ;;
      *)
        log_warn "deliver" "[${webhook_idx}] Unexpected response: HTTP ${RESPONSE_CODE}"
        ;;
    esac

    # Retry delay (exponential backoff: 2, 4, 8, ... max 30s)
    if [[ "${DELIVERED}" == "false" && "${attempt}" -lt "${MAX_RETRIES}" ]]; then
      local BACKOFF=$(( RETRY_DELAY * (2 ** (attempt - 1)) ))
      [[ "${BACKOFF}" -gt 30 ]] && BACKOFF=30
      log_retry "deliver" "Waiting ${BACKOFF}s before retry..."
      sleep "${BACKOFF}"
    fi
  done

  # Report result
  if [[ "${DELIVERED}" == "true" ]]; then
    echo "success:${MESSAGE_ID}"
    return 0
  else
    echo "failure:HTTP_${RESPONSE_CODE}"
    return 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
print_banner() {
  echo ""
  echo -e "${C_MAUVE}${C_BLD}"
  cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════════════╗
  ║  🔔 ASH Discord Notification Engine v5.0.0-omega                 ║
  ╚══════════════════════════════════════════════════════════════════╝
BANNER
  echo -e "${C_RST}"
  printf "  ${C_TEXT}Template:  ${C_MAUVE}%-45s${C_RST}\n" "${TEMPLATE}"
  printf "  ${C_TEXT}Webhooks:  ${C_TEAL}%-45s${C_RST}\n" "${WEBHOOK_COUNT} target(s)"
  printf "  ${C_TEXT}Title:     ${C_SAP}%-45s${C_RST}\n" "${EMBED_TITLE:0:45}"
  printf "  ${C_TEXT}Color:     ${C_LAV}%-45s${C_RST}\n" "${EMBED_COLOR}"
  printf "  ${C_TEXT}Dry Run:   ${C_YELLOW}%-45s${C_RST}\n" "${DRY_RUN}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
main() {
  print_banner

  # ── Collect webhooks ──────────────────────────────────────────────────────
  collect_webhooks
  local TOTAL_WEBHOOKS="${#WEBHOOKS[@]}"

  # ── Apply template ────────────────────────────────────────────────────────
  apply_template

  # ── Build or load payload ─────────────────────────────────────────────────
  local PAYLOAD=""
  local PAYLOAD_SIZE=0

  if [[ -n "${PAYLOAD_FILE}" && -f "${PAYLOAD_FILE}" ]]; then
    log_build "payload" "Loading from file: ${PAYLOAD_FILE}"
    PAYLOAD=$(cat "${PAYLOAD_FILE}")
    PAYLOAD_SIZE=$(wc -c < "${PAYLOAD_FILE}" 2>/dev/null || echo 0)
  else
    log_build "payload" "Building payload from configuration..."
    PAYLOAD=$(build_payload)
    PAYLOAD_SIZE=$(cat /tmp/ash-notify-payload-size.txt 2>/dev/null || \
      echo "${#PAYLOAD}")
  fi

  # ── Validate payload ──────────────────────────────────────────────────────
  if ! echo "${PAYLOAD}" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    log_fail "validate" "Payload is not valid JSON"
    {
      echo "delivered=false"
      echo "status=failed"
      echo "delivery_count=0"
      echo "failed_count=1"
    } >> "${GITHUB_OUTPUT:-/dev/null}"
    exit 1
  fi

  log_info "payload" "Size: ${PAYLOAD_SIZE} bytes / ${DISCORD_MAX_PAYLOAD} max"

  # ── Debug payload display ──────────────────────────────────────────────────
  if [[ "${DEBUG_PAYLOAD}" == "true" || "${VERBOSE}" == "true" ]]; then
    echo ""
    echo -e "  ${C_OVR}── Payload Preview ──────────────────────────────────────${C_RST}"
    # Mask any webhook URLs in payload
    echo "${PAYLOAD}" | sed 's|/api/webhooks/[^"]*|/api/webhooks/***MASKED***|g' | \
      python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin),indent=2))" \
      2>/dev/null | head -60 | sed 's/^/  /'
    echo -e "  ${C_OVR}────────────────────────────────────────────────────────${C_RST}"
    echo ""
  fi

  # ── Dry run ────────────────────────────────────────────────────────────────
  if [[ "${DRY_RUN}" == "true" ]]; then
    log_dry "dry-run" "Dry run — payload validated, not sending"
    echo ""
    echo -e "  ${C_LAV}${C_BLD}📋 Dry Run Summary:${C_RST}"
    echo -e "  ${C_TEXT}Template:  ${C_MAUVE}${TEMPLATE}${C_RST}"
    echo -e "  ${C_TEXT}Title:     ${C_SAP}${EMBED_TITLE:0:60}${C_RST}"
    echo -e "  ${C_TEXT}Color:     ${C_LAV}${EMBED_COLOR} → $(resolve_color "${EMBED_COLOR}")${C_RST}"
    echo -e "  ${C_TEXT}Payload:   ${C_PEACH}${PAYLOAD_SIZE} bytes${C_RST}"
    echo -e "  ${C_TEXT}Webhooks:  ${C_TEAL}${TOTAL_WEBHOOKS} target(s)${C_RST}"
    echo ""
    {
      echo "delivered=false"
      echo "status=dry-run"
      echo "delivery_count=0"
      echo "failed_count=0"
      echo "retry_count=0"
      echo "message_id="
      echo "payload_size=${PAYLOAD_SIZE}"
      echo "duration_ms=0"
    } >> "${GITHUB_OUTPUT:-/dev/null}"
    exit 0
  fi

  # ── Multi-webhook delivery ────────────────────────────────────────────────
  if [[ "${TOTAL_WEBHOOKS}" -eq 0 ]]; then
    log_warn "deliver" "No webhooks to deliver to — skipping"
    {
      echo "delivered=false"
      echo "status=skipped"
      echo "delivery_count=0"
      echo "failed_count=0"
      echo "retry_count=0"
      echo "message_id="
      echo "payload_size=${PAYLOAD_SIZE}"
      echo "duration_ms=0"
    } >> "${GITHUB_OUTPUT:-/dev/null}"
    exit 0
  fi

  echo ""
  echo -e "  ${C_SAP}${C_BLD}━━━ Delivering to ${TOTAL_WEBHOOKS} webhook(s) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RST}"

  declare -a DELIVERED_IDS=()
  declare -a FAILED_WEBHOOKS=()
  local TOTAL_RETRIES=0
  local WEBHOOK_IDX=0

  for webhook_url in "${WEBHOOKS[@]}"; do
    ((WEBHOOK_IDX++)) || true

    local RESULT
    RESULT=$(deliver_webhook "${webhook_url}" "${PAYLOAD}" "${WEBHOOK_IDX}" 2>&1 || echo "failure:error")

    # Parse result
    local RESULT_STATUS="${RESULT%%:*}"
    local RESULT_DETAIL="${RESULT#*:}"

    if [[ "${RESULT_STATUS}" == "success" ]]; then
      DELIVERED_IDS+=("${RESULT_DETAIL}")
    else
      FAILED_WEBHOOKS+=("${WEBHOOK_IDX}")
      log_fail "deliver" "[${WEBHOOK_IDX}] Failed: ${RESULT_DETAIL}"
    fi

    # Small delay between webhooks to avoid burst rate limits
    [[ "${WEBHOOK_IDX}" -lt "${TOTAL_WEBHOOKS}" ]] && sleep 0.5
  done

  # ── Compute delivery metrics ──────────────────────────────────────────────
  local END_NS; END_NS=$(date +%s%N 2>/dev/null || echo "0")
  local DURATION_MS=$(( (END_NS / 1000000) - START_MS ))
  local DELIVERY_COUNT="${#DELIVERED_IDS[@]}"
  local FAILED_COUNT="${#FAILED_WEBHOOKS[@]}"
  local MESSAGE_IDS
  MESSAGE_IDS=$(IFS=,; echo "${DELIVERED_IDS[*]:-}")

  # Determine overall status
  local OVERALL_STATUS="failed"
  if [[ "${DELIVERY_COUNT}" -eq "${TOTAL_WEBHOOKS}" ]]; then
    OVERALL_STATUS="success"
  elif [[ "${DELIVERY_COUNT}" -gt 0 ]]; then
    OVERALL_STATUS="partial"
  fi

  # ── Final dashboard ────────────────────────────────────────────────────────
  local STATUS_COLOR="${C_GREEN}"
  [[ "${OVERALL_STATUS}" == "partial" ]] && STATUS_COLOR="${C_YELLOW}"
  [[ "${OVERALL_STATUS}" == "failed"  ]] && STATUS_COLOR="${C_RED}"

  echo ""
  echo -e "  ${C_MAUVE}${C_BLD}╔══════════════════════════════════════════════════════════════╗${C_RST}"
  echo -e "  ${C_MAUVE}${C_BLD}║  📡 DELIVERY COMPLETE                                         ║${C_RST}"
  echo -e "  ${C_MAUVE}${C_BLD}╠══════════════════════════════════════════════════════════════╣${C_RST}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Status:   ${STATUS_COLOR}${C_BLD}%-50s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${OVERALL_STATUS^^}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Delivered:${C_GREEN} %-5s${C_RST}   ${C_TEXT}Failed:  ${C_RED}%-5s${C_RST}  ${C_TEXT}Duration: ${C_SAP}%-10s${C_RST}  ${C_MAUVE}${C_BLD}║${C_RST}\n" \
    "${DELIVERY_COUNT}/${TOTAL_WEBHOOKS}" "${FAILED_COUNT}" "${DURATION_MS}ms"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Template: ${C_PINK}%-50s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${TEMPLATE}"
  printf  "  ${C_MAUVE}${C_BLD}║${C_RST}  ${C_TEXT}Payload:  ${C_PEACH}%-50s${C_RST}${C_MAUVE}${C_BLD}║${C_RST}\n" "${PAYLOAD_SIZE} bytes"
  echo -e "  ${C_MAUVE}${C_BLD}╚══════════════════════════════════════════════════════════════╝${C_RST}"
  echo ""

  # ── Emit GitHub outputs ────────────────────────────────────────────────────
  {
    echo "delivered=$([[ "${DELIVERY_COUNT}" -gt 0 ]] && echo true || echo false)"
    echo "delivery_count=${DELIVERY_COUNT}"
    echo "failed_count=${FAILED_COUNT}"
    echo "retry_count=${TOTAL_RETRIES}"
    echo "message_id=${MESSAGE_IDS}"
    echo "payload_size=${PAYLOAD_SIZE}"
    echo "duration_ms=${DURATION_MS}"
    echo "status=${OVERALL_STATUS}"
  } >> "${GITHUB_OUTPUT:-/dev/null}"

  # ── Fail gate ──────────────────────────────────────────────────────────────
  if [[ "${FAIL_ON_ERROR}" == "true" && "${OVERALL_STATUS}" == "failed" ]]; then
    log_fail "gate" "All webhook deliveries failed and fail_on_error=true"
    exit 1
  fi

  [[ "${OVERALL_STATUS}" == "success" ]] && \
    log_pass "complete" "All ${DELIVERY_COUNT} notification(s) delivered ✨" || \
    log_warn "complete" "${DELIVERY_COUNT}/${TOTAL_WEBHOOKS} delivered (${FAILED_COUNT} failed)"
}

# ─────────────────────────────────────────────────────────────────────────────
# TRAP
# ─────────────────────────────────────────────────────────────────────────────
trap 'EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  log_fail "notify" "Engine failed (exit=${EXIT_CODE})"
  {
    echo "delivered=false"
    echo "status=error"
    echo "delivery_count=0"
    echo "failed_count=${WEBHOOK_COUNT:-0}"
    echo "duration_ms=$(( ($(date +%s%N 2>/dev/null || echo 0) / 1000000) - START_MS ))"
  } >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
fi
# Cleanup
rm -f /tmp/ash-notify-payload-size.txt 2>/dev/null || true
' EXIT

# ─────────────────────────────────────────────────────────────────────────────
# ENTRY
# ─────────────────────────────────────────────────────────────────────────────
main "$@"