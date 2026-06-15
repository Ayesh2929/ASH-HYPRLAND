Markdown

<!--
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║      🔗 ASH DOTFILES v5.0 OMEGA — INTEGRATION PULL REQUEST TEMPLATE                   ║
║      Ultra-Premium Third-Party Integration Delivery System • API Contract Audit        ║
║      OAuth Flow Verification • Rate Limit Strategy • Privacy Impact Assessment        ║
║      ToS Compliance • Webhook Security • SDK Documentation • Graceful Degradation     ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
-->

<div align="center">
██╗███╗ ██╗████████╗███████╗ ██████╗ ██████╗ █████╗ ████████╗██╗ ██████╗ ███╗ ██╗
██║████╗ ██║╚══██╔══╝██╔════╝██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗ ██║
██║██╔██╗ ██║ ██║ █████╗ ██║ ███╗██████╔╝███████║ ██║ ██║██║ ██║██╔██╗ ██║
██║██║╚██╗██║ ██║ ██╔══╝ ██║ ██║██╔══██╗██╔══██║ ██║ ██║██║ ██║██║╚██╗██║
██║██║ ╚████║ ██║ ███████╗╚██████╔╝██║ ██║██║ ██║ ██║ ██║╚██████╔╝██║ ╚████║
╚═╝╚═╝ ╚═══╝ ╚═╝ ╚══════╝ ╚═════╝ ╚═╝ ╚═╝╚═╝ ╚═╝ ╚═╝ ╚═╝ ╚═════╝ ╚═╝ ╚═══╝

██████╗ ██████╗
██╔══██╗██╔══██╗
██████╔╝██████╔╝
██╔═══╝ ██╔══██╗
██║ ██║ ██║
╚═╝ ╚═╝ ╚═╝

text


# 🔗 Integration PR — ASH Dotfiles v5.0 OMEGA

> *"Great integrations make foreign systems feel native"*

</div>

---

> [!IMPORTANT]
> **Integration PRs have additional requirements beyond standard PRs.**
> ALL integrations must pass:
> ```bash
> # Complete integration validation suite:
> ash plugin validate --strict --security --integration ./integration/
>
> # Verify no undisclosed network calls:
> strace -e trace=network bash enable.sh 2>&1 | grep "connect\|send\|recv"
>
> # ToS compliance check (manual):
> # Review: [Service ToS URL] — confirm redistribution permitted
>
> # Rate limit stress test:
> bash tests/integration/test-rate-limits.sh --service [name]
>
> # Offline graceful degradation test:
> bash tests/integration/test-offline-mode.sh --service [name]
>
> # Privacy data audit:
> bash tests/security/test-data-exfiltration.sh --integration [name]
> ```

---

## 🔗 SECTION 01 — INTEGRATION IDENTITY

### Service Profile Card
╔══════════════════════════════════════════════════════════════════════════╗
║ 🔗 INTEGRATION: [Service Name] ║
║ 🌐 WEBSITE: [https://service.example.com] ║
║ 📡 API TYPE: REST / GraphQL / WebSocket / gRPC / SDK / CLI ║
║ 🔑 AUTH METHOD: OAuth 2.0 / API Key / Bearer / None ║
║ 🌍 NETWORK: Local Only / Internet Required / Both ║
║ 💰 COST: Free / Freemium / Paid (Plan: ___) / Self-Hosted ║
║ 📜 LICENSE: [Service API License / ToS URL] ║
╚══════════════════════════════════════════════════════════════════════════╝

text


### Integration Classification

| Property | Value |
|----------|-------|
| **Integration ID** | <!-- e.g., obsidian-local / discord-rpc / home-assistant --> |
| **Plugin Category** | <!-- integrations / productivity / smart-home / etc. --> |
| **Direction** | <!-- Read-only / Write-only / Bidirectional --> |
| **Frequency** | <!-- Real-time / Polling (interval) / On-demand / Webhook --> |
| **Delivery Method** | <!-- Core plugin / Community plugin / Both --> |
| **Requires Account** | <!-- Yes (free) / Yes (paid) / No (self-hosted) --> |
| **Min ASH Version** | <!-- v5.0.0 --> |

---

## 🎯 SECTION 02 — INTEGRATION VALUE STATEMENT

### Problem & Solution
╔══════════════════════════════════════════════════════════════════════════╗
║ 😤 WITHOUT THIS INTEGRATION ║
╠══════════════════════════════════════════════════════════════════════════╣
║ ║
║ [Describe the exact workflow pain in concrete terms] ║
║ [How many steps? How much time? How much friction?] ║
║ ║
╠══════════════════════════════════════════════════════════════════════════╣
║ ✨ WITH THIS INTEGRATION ║
╠══════════════════════════════════════════════════════════════════════════╣
║ ║
║ [Describe the improved workflow — specific, concrete benefits] ║
║ [Quantify: saves X minutes/day, reduces X steps to Y steps] ║
║ ║
╚══════════════════════════════════════════════════════════════════════════╝

text


### ASH-Specific Integration Value

<!--
Why does this integration specifically benefit from being in ASH?
What ASH systems does it leverage?
-->

| ASH System Leveraged | How Used | User Benefit |
|---------------------|----------|-------------|
| 🎭 Mode System | <!-- e.g., Auto-enables Focus Mode when [service] enters study mode --> | |
| 🎨 Theme Engine | <!-- e.g., Syncs theme to [service] accent color --> | |
| 🪝 Hook System | <!-- e.g., [Service] events trigger ASH hooks --> | |
| 📊 Analytics | <!-- e.g., [Service] usage tracked in ASH analytics --> | |
| 🔔 Notifications | <!-- e.g., [Service] events become themed ASH notifications --> | |
| 📊 Waybar | <!-- e.g., [Service] status shown in status bar --> | |
| 🚀 Rofi | <!-- e.g., [Service] controlled via Rofi menus --> | |
| ⌨️ Keybinds | <!-- e.g., Global hotkeys control [service] --> | |

---

## 📡 SECTION 03 — API CONTRACT DOCUMENTATION

<!--
REQUIRED: Complete and accurate API documentation.
This is audited for security and rate limit compliance.
-->

### API Overview

```yaml
# Service API Contract Summary
service: "[Service Name]"
api_version: "v[X]"
api_docs: "[URL to API documentation]"
openapi_spec: "[URL to OpenAPI spec or 'Not available']"

base_url: "[https://api.service.com/v1 OR http://localhost:PORT]"
protocol: "[HTTPS / HTTP (local only) / WebSocket]"

rate_limits:
  requests_per_minute: [X or "unlimited"]
  requests_per_hour: [X or "unlimited"]
  requests_per_day: [X or "unlimited"]
  burst_limit: [X or "N/A"]
  rate_limit_headers: "[X-RateLimit-Remaining / X-Rate-Limit / None]"

pagination:
  supported: [true / false]
  type: "[cursor / offset / page / N/A]"
  default_page_size: [X or "N/A"]

webhooks:
  supported: [true / false]
  type: "[push / polling-only]"
  signature_verification: "[HMAC-SHA256 / None / N/A]"
Endpoints Used
<!-- Document EVERY endpoint this integration calls. Undisclosed endpoints = immediate PR rejection. -->
Method	Endpoint	Purpose	Auth	Rate Limited?	Data Sent
GET	/v1/[resource]	[Purpose]	Bearer	Yes (60/min)	[None / query params]
POST	/v1/[resource]	[Purpose]	Bearer	Yes (10/min)	[Body: {field: value}]
WS	/ws/v1/events	[Purpose]	Header	No	[Subscribe message]
Request/Response Examples
Bash

# Example 1: [Most important API call]
curl -s \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json" \
  "https://api.service.com/v1/[resource]"

# Response (200 OK):
{
  "id": "abc123",
  "field1": "value1",
  "field2": 42,
  "created_at": "2024-01-15T14:32:00Z"
}

# Example 2: [Second important call]
curl -s -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}' \
  "https://api.service.com/v1/[resource]"
Error Handling
Bash

# How this integration handles each HTTP error code:

handle_api_error() {
  local http_code="${1}"
  local response_body="${2}"

  case "${http_code}" in
    200|201|204)
      # Success — process response
      ;;
    400)
      # Bad request — log error, show user-friendly message
      ash::log "error" "Bad request to [service] API: ${response_body}"
      ash::notification::send "error" "[Service]" "Invalid request — check your configuration"
      ;;
    401)
      # Unauthorized — token invalid or expired
      ash::log "warn" "[Service] token rejected — may need re-authentication"
      ash::notification::send "warn" "[Service]" "Authentication failed — run: ash plugin configure [id]"
      ;;
    403)
      # Forbidden — insufficient permissions
      ash::log "error" "[Service] insufficient permissions for: ${endpoint}"
      ;;
    404)
      # Resource not found — graceful handling
      ash::log "debug" "[Service] resource not found: ${endpoint}"
      ;;
    429)
      # Rate limited — backoff and retry
      local retry_after="${3:-60}"
      ash::log "warn" "[Service] rate limited — waiting ${retry_after}s"
      sleep "${retry_after}"
      return 1  # Signal caller to retry
      ;;
    5*)
      # Server error — retry with exponential backoff
      ash::log "error" "[Service] server error ${http_code} — will retry"
      ;;
    *)
      ash::log "error" "[Service] unexpected error ${http_code}"
      ;;
  esac
}
🔑 SECTION 04 — AUTHENTICATION ARCHITECTURE
<!-- Security-critical section. Complete with exact implementation details. -->
Authentication Method
 🔑 API Key (static, Bearer token in header)
 🔐 OAuth 2.0 Authorization Code (user delegates access)
 🔐 OAuth 2.0 Client Credentials (service-to-service)
 🔐 OAuth 2.0 Device Flow (headless/CLI-friendly)
 📧 Basic Auth (username + password)
 🏠 Local Only (no auth needed — same machine)
 🔒 mTLS (mutual TLS certificates)
Token Management Implementation
Bash

# ══════════════════════════════════════════════════════════════
# TOKEN SETUP — First-time configuration
# ══════════════════════════════════════════════════════════════

configure_auth() {
  # Guided setup wizard — never stores token in plaintext
  ash::log "info" "Configuring [service] authentication"

  # For OAuth 2.0 Device Flow (most CLI-friendly):
  local device_code_response
  device_code_response="$(curl -s -X POST \
    -d "client_id=${CLIENT_ID}" \
    "https://[service].com/oauth/device/code")"

  local user_code verification_url
  user_code="$(echo "${device_code_response}" | jq -r '.user_code')"
  verification_url="$(echo "${device_code_response}" | jq -r '.verification_uri')"

  echo ""
  echo "  Visit: ${verification_url}"
  echo "  Code:  ${user_code}"
  echo ""
  echo "  Waiting for authorization..."

  # Poll for token
  local token=""
  while [[ -z "${token}" ]]; do
    sleep 5
    local poll_response
    poll_response="$(curl -s -X POST \
      -d "client_id=${CLIENT_ID}&device_code=${device_code}" \
      "https://[service].com/oauth/token")"

    token="$(echo "${poll_response}" | jq -r '.access_token // empty')"
  done

  # Store securely — NEVER in plaintext config
  ash::secrets::store "plugin.[id].access_token" "${token}"
  ash::log "success" "[Service] authentication configured successfully"
}

# ══════════════════════════════════════════════════════════════
# TOKEN RETRIEVAL — Runtime usage
# ══════════════════════════════════════════════════════════════

get_auth_header() {
  local token
  # Token retrieved from encrypted store — NEVER from env vars or files
  token="$(ash::secrets::get "plugin.[id].access_token")"

  if [[ -z "${token}" ]]; then
    ash::log "error" "[Service] not authenticated — run: ash plugin configure [id]"
    return 1
  fi

  echo "Authorization: Bearer ${token}"
}

# ══════════════════════════════════════════════════════════════
# TOKEN REFRESH — For OAuth with expiring tokens
# ══════════════════════════════════════════════════════════════

refresh_token_if_needed() {
  local expiry
  expiry="$(ash::secrets::get "plugin.[id].token_expiry" || echo 0)"

  if [[ $(date +%s) -gt $((expiry - 300)) ]]; then  # Refresh 5 min early
    ash::log "debug" "[Service] refreshing expired token"
    # [Refresh implementation]
    ash::secrets::store "plugin.[id].access_token" "${new_token}"
    ash::secrets::store "plugin.[id].token_expiry" "${new_expiry}"
  fi
}
Credential Security Properties
 🔐 Tokens stored ONLY via ash::secrets::store (encrypted at rest)
 🚫 Tokens NEVER written to: config files, log files, environment, CLI args
 🔄 Token refresh implemented (for expiring tokens)
 🗑️ Token revocation on ash plugin remove --purge
 📋 Minimal OAuth scopes requested (principle of least privilege)
 🔍 Token validity checked before each API session
Required OAuth Scopes
text

Scopes requested (justify each):
┌─────────────────────────────────────────────────────────────────┐
│  scope:read:profile    — Required to display username in status │
│  scope:read:content    — Required to fetch [resource] for widget │
│  scope:write:content   — Required to [write action]             │
│                                                                 │
│  NOT requested (but available):                                 │
│  scope:admin           — Not needed                             │
│  scope:delete:account  — Not needed                             │
│  scope:billing         — Not needed                             │
└─────────────────────────────────────────────────────────────────┘
🛡️ SECTION 05 — PRIVACY & TERMS OF SERVICE AUDIT
<!-- Non-negotiable compliance section. Incomplete = PR blocked. -->
Terms of Service Review
text

╔══════════════════════════════════════════════════════════════════════════╗
║  📜 ToS COMPLIANCE AUDIT — [Service Name]                               ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  ToS URL:    [https://service.com/terms]                                 ║
║  API ToS:    [https://service.com/api-terms]                             ║
║  Reviewed:   [YYYY-MM-DD] by @[github-handle]                            ║
║                                                                          ║
╠══════════════════════════════════════════════════════════════════════════╣
║  PERMITTED USES (confirmed in ToS):                                      ║
║  ✅ Third-party API clients allowed                                      ║
║  ✅ Redistribution of integration code allowed                          ║
║  ✅ Automated API access allowed (within rate limits)                   ║
║  ✅ Commercial use of API allowed / N/A (open source)                   ║
╠══════════════════════════════════════════════════════════════════════════╣
║  RESTRICTIONS RESPECTED:                                                 ║
║  ✅ Rate limits will NOT be exceeded                                     ║
║  ✅ User data will NOT be scraped beyond stated purpose                  ║
║  ✅ Service branding used only where appropriate                         ║
║  ✅ No circumvention of paywalls or access controls                      ║
╠══════════════════════════════════════════════════════════════════════════╣
║  GRAY AREAS (requires maintainer judgment):                              ║
║  ❓ [Any ToS ambiguity] — [How we interpret it]                          ║
╚══════════════════════════════════════════════════════════════════════════╝
Data Privacy Impact Assessment
text

DATA COLLECTED BY THIS INTEGRATION:

┌─────────────────────────────────────────────────────────────────────┐
│  FROM [SERVICE] → ASH DESKTOP                                       │
├──────────────────┬────────────┬──────────────┬──────────────────────┤
│  Data            │ Sensitivity│ Stored?      │ Retention            │
├──────────────────┼────────────┼──────────────┼──────────────────────┤
│ [Data item 1]    │ Low/Med/Hi │ No/Yes-local │ Never/Session/Config │
│ [Data item 2]    │ Low/Med/Hi │ No/Yes-local │ Never/Session/Config │
│ Auth token       │ HIGH       │ Encrypted    │ Until removed/revoked│
└──────────────────┴────────────┴──────────────┴──────────────────────┘

FROM ASH DESKTOP → [SERVICE]:
┌─────────────────────────────────────────────────────────────────────┐
│  Data            │ Purpose    │ User Consent │ Can Opt Out?         │
├──────────────────┼────────────┼──────────────┼──────────────────────┤
│ [Data sent]      │ [Purpose]  │ Implicit/    │ Yes - disable plugin │
│                  │            │ Explicit     │                      │
└──────────────────┴────────────┴──────────────┴──────────────────────┘

TO EXTERNAL NETWORKS (summary):
  External internet calls: YES / NO
  If yes — disclosed endpoints: [list all]
  Data leaving user machine: [list all data points or "NONE"]
  GDPR implications: [None / User data stays local / See notes]
Privacy Controls Provided
Bash

# Users can inspect what data is stored:
$ ash plugin data-audit [integration-id]
[Lists all stored data with location and purpose]

# Users can delete all stored data:
$ ash plugin remove [integration-id] --purge
[Removes all data, tokens, cache, logs]

# Users can see what data is sent to [service]:
$ ash plugin [integration-id] --show-data-flows
[Explains all API calls and data transmitted]
⚡ SECTION 06 — RATE LIMIT STRATEGY
<!-- Rate limit handling is a hard requirement for all internet integrations. A misbehaving integration can get ASH users banned from services. -->
Rate Limit Configuration
Bash

# Rate limit constants (from [service] API docs):
readonly SERVICE_RATE_LIMIT_PER_MIN=60
readonly SERVICE_RATE_LIMIT_PER_HOUR=1000
readonly SERVICE_RATE_LIMIT_DAILY=10000
readonly SERVICE_RETRY_AFTER_HEADER="Retry-After"  # or X-RateLimit-Reset

# ASH integration polling intervals (conservative — well under limits):
readonly POLL_INTERVAL_NORMAL=60      # 60 seconds (1/min vs 60/min limit)
readonly POLL_INTERVAL_BACKGROUND=300  # 5 minutes for background data
readonly POLL_INTERVAL_RATE_LIMITED=0  # Dynamic: read from Retry-After header
Rate Limit Implementation
Bash

# Robust rate limit handler with exponential backoff:
make_api_request() {
  local endpoint="${1}"
  local method="${2:-GET}"
  local body="${3:-}"
  local max_retries=3
  local attempt=0
  local backoff=1

  while [[ ${attempt} -lt ${max_retries} ]]; do
    local response http_code
    response="$(curl -s -w "\n%{http_code}" \
      -X "${method}" \
      -H "$(get_auth_header)" \
      -H "Content-Type: application/json" \
      ${body:+-d "${body}"} \
      "https://api.[service].com${endpoint}")"

    http_code="$(echo "${response}" | tail -1)"
    local body_response
    body_response="$(echo "${response}" | head -n -1)"

    case "${http_code}" in
      200|201|204)
        echo "${body_response}"
        return 0
        ;;
      429)
        # Rate limited — respect Retry-After header
        local retry_after
        retry_after="$(curl -sI \
          -H "$(get_auth_header)" \
          "https://api.[service].com${endpoint}" \
          | grep -i 'retry-after:' \
          | awk '{print $2}' \
          | tr -d '\r')"
        retry_after="${retry_after:-${backoff}}"
        ash::log "warn" "[Service] rate limited — waiting ${retry_after}s (attempt ${attempt})"
        sleep "${retry_after}"
        ;;
      5*)
        # Server error — exponential backoff
        ash::log "warn" "[Service] server error ${http_code} — waiting ${backoff}s"
        sleep "${backoff}"
        backoff=$((backoff * 2))
        ;;
      *)
        handle_api_error "${http_code}" "${body_response}"
        return 1
        ;;
    esac
    ((attempt++))
  done

  ash::log "error" "[Service] max retries exceeded for ${endpoint}"
  return 1
}
Rate Usage Estimate
text

Daily API budget analysis:
┌─────────────────────────────────────────────────────────────────┐
│  Operation          │ Frequency  │ Calls/day │ % of Daily Limit  │
├─────────────────────┼────────────┼───────────┼───────────────────┤
│ Status poll         │ 1/min      │ 1,440     │ 14.4% of 10,000   │
│ Background refresh  │ 1/5min     │ 288       │ 2.9%              │
│ User actions        │ ~10/day    │ 10        │ 0.1%              │
│ Webhook verify      │ On event   │ ~20       │ 0.2%              │
├─────────────────────┼────────────┼───────────┼───────────────────┤
│ TOTAL ESTIMATED     │            │ ~1,758    │ ~17.6% of limit   │
│ SAFETY MARGIN       │            │           │ 82.4% headroom ✅  │
└─────────────────────────────────────────────────────────────────┘
🔌 SECTION 07 — GRACEFUL DEGRADATION
<!-- Every integration MUST work gracefully when the external service is unavailable. The user's desktop must never become unusable due to an offline service. -->
Degradation Levels
text

Service State → ASH Integration Behavior:

ONLINE ────────────────────────────────────────────────────────────
✅ All features working
✅ Waybar module shows live data
✅ Full real-time synchronization

SLOW / DEGRADED ────────────────────────────────────────────────────
⚠️  API calls have extended timeout (5s → 10s)
⚠️  Waybar shows cached data with staleness indicator: "📡 [data] (cached)"
⚠️  Non-critical features silently skipped
⚠️  Retry with exponential backoff

OFFLINE / UNREACHABLE ──────────────────────────────────────────────
🔴 Waybar module hidden OR shows offline indicator: "⚫ [service] offline"
🔴 All API calls skipped (no hanging, no errors shown to user)
🔴 Cached data used where safe and appropriate
🔴 Zero impact on ASH core functionality

AUTHENTICATION EXPIRED ─────────────────────────────────────────────
🔑 Waybar module shows auth icon: "🔑 Re-auth needed"
🔑 One notification per session: "[Service] needs re-authentication"
🔑 Graceful fallback to cached last-known state
🔑 No repeated notification spam

SERVICE REMOVED / API BREAKING ─────────────────────────────────────
⚠️  Plugin disables itself with clear error message
⚠️  User notified: "[Service] API changed — update plugin or disable"
⚠️  No crashes, no loops, no zombie processes
Offline Mode Implementation
Bash

# Graceful offline handling pattern:

is_service_reachable() {
  local timeout=3  # Short timeout — don't block the desktop
  curl -s --max-time "${timeout}" \
    --connect-timeout "${timeout}" \
    -o /dev/null -w "%{http_code}" \
    "https://api.[service].com/health" 2>/dev/null | grep -q "^2"
}

get_data_with_fallback() {
  # Try live data first
  if is_service_reachable; then
    local live_data
    if live_data="$(fetch_live_data)"; then
      # Cache successful result
      echo "${live_data}" > "${CACHE_FILE}"
      echo "${live_data}"
      return 0
    fi
  fi

  # Fall back to cache
  if [[ -f "${CACHE_FILE}" ]]; then
    local cache_age
    cache_age=$(( $(date +%s) - $(stat -c %Y "${CACHE_FILE}") ))
    ash::log "debug" "[Service] using cached data (${cache_age}s old)"
    cat "${CACHE_FILE}"
    return 0
  fi

  # No data available — return empty/default state
  echo '{"status": "offline", "data": null}'
  return 0  # Never return error — desktop must keep working
}
🧪 SECTION 08 — INTEGRATION TEST SUITE
Test Architecture
Bash

# Complete integration test structure:
tests/integration/
├── test-[service]-connection.sh     # Connection establishment
├── test-[service]-auth.sh           # Authentication flows
├── test-[service]-api.sh            # All API endpoints
├── test-[service]-rate-limits.sh    # Rate limit handling
├── test-[service]-offline.sh        # Offline degradation
├── test-[service]-webhook.sh        # Webhook handling (if applicable)
├── test-[service]-data-flow.sh      # Data privacy verification
├── test-[service]-lifecycle.sh      # Enable/disable/reinstall
└── mock/
    ├── mock-[service]-api.sh        # Local API mock server
    └── mock-responses/              # Fixture response files
        ├── success.json
        ├── rate-limited.json
        ├── server-error.json
        └── auth-expired.json
Mock API Server for CI
Bash

# Mock server — allows CI to test without real API credentials:
# tests/integration/mock/mock-[service]-api.sh

start_mock_server() {
  local port="${MOCK_API_PORT:-18080}"

  # Serve mock responses using Python's built-in HTTP server:
  python3 -m http.server "${port}" --directory ./mock-responses &
  MOCK_PID=$!

  # Override API base URL in tests:
  export SERVICE_API_BASE="http://localhost:${port}"

  ash::log "debug" "Mock [service] API started on port ${port} (PID: ${MOCK_PID})"
}

stop_mock_server() {
  if [[ -n "${MOCK_PID}" ]]; then
    kill "${MOCK_PID}" 2>/dev/null || true
  fi
}

# Register cleanup:
trap stop_mock_server EXIT
Test Results
Bash

$ bash tests/integration/run-all-[service]-tests.sh --mock

🧪 [Service] Integration — Full Test Suite
════════════════════════════════════════════════════════

Connection Tests:
  ✅ test_connection_success         (mock, 23ms)
  ✅ test_connection_timeout         (mock, 3042ms)
  ✅ test_connection_refused         (mock, 12ms)
  ✅ test_tls_certificate_valid      (mock, 45ms)

Authentication Tests:
  ✅ test_oauth_device_flow          (mock, 156ms)
  ✅ test_token_storage_encrypted    (45ms)
  ✅ test_token_retrieval            (12ms)
  ✅ test_token_refresh              (mock, 234ms)
  ✅ test_token_revocation_on_remove (89ms)
  ✅ test_invalid_token_handling     (mock, 34ms)

API Tests:
  ✅ test_get_[resource]_success     (mock, 45ms)
  ✅ test_post_[resource]_success    (mock, 67ms)
  ✅ test_api_error_400_handling     (mock, 23ms)
  ✅ test_api_error_401_handling     (mock, 23ms)
  ✅ test_api_error_403_handling     (mock, 23ms)
  ✅ test_api_error_404_handling     (mock, 23ms)

Rate Limit Tests:
  ✅ test_rate_limit_429_backoff     (mock, 5034ms)
  ✅ test_exponential_backoff        (mock, 7234ms)
  ✅ test_retry_after_header_read    (mock, 45ms)
  ✅ test_max_retries_exceeded       (mock, 15678ms)

Offline Tests:
  ✅ test_offline_graceful_fallback  (23ms)
  ✅ test_cached_data_used_offline   (45ms)
  ✅ test_waybar_offline_indicator   (67ms)
  ✅ test_no_crash_when_offline      (89ms)
  ✅ test_recovery_when_online       (mock, 456ms)

Data Privacy Tests:
  ✅ test_no_undisclosed_calls       (strace, 234ms)
  ✅ test_token_not_in_logs          (89ms)
  ✅ test_data_purge_on_remove       (45ms)

════════════════════════════════════════════════════════
Results: XX/XX tests PASSED ✅
📸 SECTION 09 — INTEGRATION SHOWCASE
Feature Demonstration
<table> <tr> <th align="center">📊 Waybar Status Widget</th> <th align="center">🚀 Rofi Control Menu</th> </tr> <tr> <td align="center"><!-- [DRAG WAYBAR SCREENSHOT — showing live data from service] --></td> <td align="center"><!-- [DRAG ROFI MENU SCREENSHOT — showing service controls] --></td> </tr> <tr> <th align="center">🔔 Event Notification</th> <th align="center">🎭 Mode Integration</th> </tr> <tr> <td align="center"><!-- [DRAG NOTIFICATION SCREENSHOT — themed with ASH colors] --></td> <td align="center"><!-- [DRAG MODE SYNC SCREENSHOT — showing desktop state change] --></td> </tr> </table>
🎬 Workflow Demo
<!-- [DRAG GIF showing: connection setup → data display → action taken → result] -->
Setup Experience Demo
Bash

# Show the complete first-time setup flow:
$ ash plugin install [integration-id]
✅ Downloading [integration-id] v1.0.0...
✅ Verifying integrity (SHA256)...
✅ Installing dependencies (curl, jq)...
✅ Installing Fish functions...
✅ Registering Waybar module...

$ ash plugin configure [integration-id]
╔══════════════════════════════════════════════════════════╗
║  🔗 [Service Name] Setup Wizard                         ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  1. Visit: https://[service].com/authorize               ║
║  2. Enter code: ABCD-1234                                ║
║                                                          ║
║  ⏳ Waiting for authorization...                         ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

✅ Authorization successful!
✅ Token stored securely (encrypted)
✅ Connection verified: [Service] v2.1.0

$ ash plugin enable [integration-id]
✅ [Service] integration enabled
✅ Waybar module active: "📡 [service data]"
✅ Hooks registered: on-mode-change, on-theme-change
✅ SECTION 10 — INTEGRATION PR CHECKLIST
API & Network (Hard Requirements)
 📡 ALL endpoints disclosed in plugin.json permissions.network
 📜 ToS compliance verified and documented above (with date + reviewer)
 ⚡ Rate limits respected — never exceed documented limits
 🔄 Retry logic with exponential backoff implemented
 🛡️ Graceful offline — desktop NEVER crashes when service unavailable
 🧪 Mock API tests — CI tests without real credentials via mock server
Authentication & Security (Hard Requirements)
 🔐 Credentials stored ONLY via ash::secrets::* (never plaintext)
 🔍 Minimal scopes — only request what's absolutely needed
 🔄 Token refresh implemented (for expiring OAuth tokens)
 🗑️ Token revocation on ash plugin remove --purge
 🌐 TLS enforced for all external calls (no HTTP to external services)
 📝 No credentials in logs — confirmed with log inspection
Privacy (Hard Requirements)
 📊 Data flow documented — every piece of data leaving the machine listed
 🗑️ Data deletion — --purge removes ALL stored data
 👁️ Transparency — users can inspect what data is stored
 🔒 GDPR compliant — no unauthorized PII retention
Quality (Required for Acceptance)
 🧪 All integration tests pass — including offline and rate limit tests
 ⚡ Rate usage < 25% of service daily limit in normal operation
 🔄 Clean lifecycle — enable/disable fully reversible
 📖 Setup guide with screenshots included in docs
 🔗 API version pinned — behavior won't break on API update
Contributor Agreement
 📜 I have read and will comply with [Service]'s Terms of Service
 🔒 I commit to security issue response within 72 hours
 🔄 I commit to updating this integration if the service's API changes
 📖 I agree to the Code of Conduct
<div align="center">
🔗 Integration Review Pipeline
text

Submit PR → ToS Review → Security Audit → API Audit → Privacy Review → Merge
   now       1-2 days     2-3 days        1-2 days     1 day          instant
📊 Integration Review Criteria
Criteria	Weight	Focus
🔒 Security & Privacy	35%	No data leaks, encrypted tokens, minimal scopes
📜 ToS Compliance	25%	Legal to distribute, rate limits respected
🛡️ Resilience	20%	Offline graceful, retry logic, no crashes
🧪 Test Coverage	10%	Mock server, all failure modes tested
✨ User Experience	10%	Easy setup, clear status, useful features
🌟 Integration Hall of Fame
Accepted integrations are featured in:

🔌 ash plugin browse --category integrations
🌐 Integration Gallery
💬 Discord #new-integrations spotlight channel
Need help? The #plugin-dev channel
has specialists for OAuth flows, rate limiting patterns, and API design!

— The ASH Dotfiles Integration Review Team 🔗

</div> 