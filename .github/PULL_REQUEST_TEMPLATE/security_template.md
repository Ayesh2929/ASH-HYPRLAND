Markdown

<!--
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║      🔒 ASH DOTFILES v5.0 OMEGA — SECURITY PULL REQUEST TEMPLATE                      ║
║                                                                                          ║
║      Ultra-Premium Security Contribution System                                         ║
║      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║      CVE Lifecycle Management    • CVSS v3.1 Scoring    • CWE Classification           ║
║      Threat Model Documentation  • Exploit Chain Analysis • MITRE ATT&CK Mapping       ║
║      Coordinated Disclosure      • Patch Verification   • Regression Prevention        ║
║      Supply Chain Security       • Cryptographic Audit  • Compliance Framework         ║
║      Security Advisory Drafting  • Bug Bounty Processing • Hall of Fame Credit         ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝

⚠️  SECURITY PR — SPECIAL HANDLING REQUIRED ⚠️

This template is for security fixes, hardening improvements, and
vulnerability patches. Sensitive details should NEVER be publicly
disclosed before the coordinated patch release. If you are reporting
a new vulnerability rather than submitting a fix, please use:
→ https://github.com/ash-dotfiles/ash-dotfiles/security/advisories/new
-->

<div align="center">
░██████╗███████╗░█████╗░██╗░░░██╗██████╗░██╗████████╗██╗░░░██╗
██╔════╝██╔════╝██╔══██╗██║░░░██║██╔══██╗██║╚══██╔══╝╚██╗░██╔╝
╚█████╗░█████╗░░██║░░╚═╝██║░░░██║██████╔╝██║░░░██║░░░░╚████╔╝░
░╚═══██╗██╔══╝░░██║░░██╗██║░░░██║██╔══██╗██║░░░██║░░░░░╚██╔╝░░
██████╔╝███████╗╚█████╔╝╚██████╔╝██║░░██║██║░░░██║░░░░░░██║░░░
╚═════╝░╚══════╝░╚════╝░░╚═════╝░╚═╝░░╚═╝╚═╝░░░╚═╝░░░░░░╚═╝░░░

██████╗░██████╗░
██╔══██╗██╔══██╗
██████╔╝██████╔╝
██╔═══╝░██╔══██╗
██║░░░░░██║░░██║
╚═╝░░░░░╚═╝░░╚═╝

text


<table>
<tr>
<td align="center" width="200">
┌─────────────────┐
│ │
│ 🔒 SECURITY │
│ PATCH ACTIVE │
│ │
│ Classification │
│ ───────────── │
│ [ PRIVATE ] │
│ │
└─────────────────┘

text


</td>
<td align="center" width="400">

# 🔒 Security PR — ASH Dotfiles v5.0 OMEGA

**Coordinated Disclosure Protocol Active**

Every line of this PR is subject to security review.
Thank you for protecting ASH Dotfiles users. 🛡️

</td>
<td align="center" width="200">
┌─────────────────┐
│ │
│ CVSS Score │
│ ─────────── │
│ │
│ [ X.X ] │
│ │
│ [SEVERITY] │
│ │
└─────────────────┘

text


</td>
</tr>
</table>

</div>

---

> [!CAUTION]
> ## 🚨 CRITICAL: DISCLOSURE PROTOCOL
>
> **Before merging this PR, ALL of the following MUST be confirmed:**
>
> | Gate | Requirement | Owner | Status |
> |------|-------------|-------|--------|
> | 🔒 **Private** | No exploit details publicly exposed | Author | <!-- ✅/❌ --> |
> | 📋 **Advisory** | GitHub Security Advisory drafted | Author | <!-- ✅/❌ --> |
> | 🧪 **Verified** | Fix confirmed effective on all affected versions | Author | <!-- ✅/❌ --> |
> | 📢 **Comms** | User notification plan approved | Maintainer | <!-- ✅/❌ --> |
> | 🏷️ **CVE** | CVE ID requested/assigned (if applicable) | Maintainer | <!-- ✅/❌ --> |
> | 🚀 **Release** | Patch release plan confirmed | Maintainer | <!-- ✅/❌ --> |
> | 👤 **Credit** | Reporter attribution confirmed | Author | <!-- ✅/❌ --> |
>
> **Embargo ends:** `YYYY-MM-DD` (90 days from initial report OR when all gates clear)

> [!TIP]
> **Security PR validation suite:**
> ```bash
> # Run complete security validation pipeline:
> bash tests/security/run-security-tests.sh --full --pr-mode
>
> # Verify fix effectiveness (no regression to vulnerable state):
> bash tests/security/test-[cve-or-issue]-regression.sh
>
> # Confirm no new vulnerabilities introduced by the fix:
> shellcheck --severity=warning --enable=all $(find . -name "*.sh" -newer HEAD~1)
> gitleaks detect --source . --verbose --log-opts="HEAD~1..HEAD"
>
> # Static analysis on changed files:
> ash security-scan --changed-files --strict
>
> # Validate permissions on new/modified files:
> bash tests/security/test-permissions.sh --changed-only
>
> # Run full security test suite:
> bash tests/security/test-injection.sh
> bash tests/security/test-path-traversal.sh
> bash tests/security/test-privilege-escalation.sh
> bash tests/security/test-secrets-exposure.sh
> ```

---

## 🔒 SECTION 01 — SECURITY CLASSIFICATION

### Patch Classification Matrix

<!--
Select the PRIMARY patch type. This drives reviewer requirements,
disclosure timeline, and release urgency.
-->
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎯 PATCH TYPE CLASSIFICATION ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ║
║ Select ONE primary type (check with [x]): ║
║ ║
║ VULNERABILITY PATCHES: ║
║ [ ] 🔴 Critical Vulnerability — RCE / root escalation / 0-day ║
║ [ ] 🟠 High Vulnerability — Data exposure / significant privilege gain ║
║ [ ] 🟡 Medium Vulnerability — Limited scope exploit / requires local ║
║ [ ] 🟢 Low Vulnerability — Edge case / minimal realistic impact ║
║ ║
║ HARDENING (non-exploitable weaknesses): ║
║ [ ] 🛡️ Security Hardening — Defense-in-depth improvement ║
║ [ ] 🔐 Cryptographic — Weak crypto / insecure randomness ║
║ [ ] 📁 Path Security — Traversal prevention / symlink hardening ║
║ [ ] 💉 Input Validation — Injection prevention / sanitization ║
║ [ ] 🔑 Authentication — Auth hardening / session management ║
║ [ ] 🌐 Network Security — TLS enforcement / SSRF prevention ║
║ [ ] 📦 Supply Chain — Dependency security / update verification ║
║ [ ] 🔏 Secrets Management — Credential storage hardening ║
║ [ ] ⚙️ Configuration — Secure defaults / permission hardening ║
║ [ ] 🧹 Code Quality Security — Remove dangerous patterns / eval elimination║
║ [ ] ♿ Privacy — Data minimization / retention reduction ║
║ [ ] 🔍 Audit / Logging — Security event logging improvement ║
║ ║
╚══════════════════════════════════════════════════════════════════════════════╝

text


### Embargo & Disclosure Status
╔══════════════════════════════════════════════════════════════════════════════╗
║ 📋 DISCLOSURE TIMELINE ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ║
║ Initial Report: YYYY-MM-DD (by @[reporter-handle] / Internal) ║
║ Acknowledgment: YYYY-MM-DD (+XX hours — SLA: <24h) ║
║ Root Cause ID: YYYY-MM-DD (+XX days) ║
║ Fix Developed: YYYY-MM-DD (+XX days) ║
║ PR Opened (now): YYYY-MM-DD ║
║ Target Merge: YYYY-MM-DD ║
║ Patch Release: YYYY-MM-DD (v5.0.X) ║
║ Advisory Published: YYYY-MM-DD (embargo lifts post-patch) ║
║ Public Disclosure: YYYY-MM-DD (≤90 days from initial report) ║
║ ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Embargo Status: 🔒 ACTIVE until YYYY-MM-DD ║
║ Days Remaining: XX days ║
║ Extension Needed: YES / NO / TBD ║
╚══════════════════════════════════════════════════════════════════════════════╝

text


---

## 📊 SECTION 02 — VULNERABILITY SCORING

### CVSS v3.1 Complete Vector

<!--
Fill in ALL 8 base metric values. Use the CVSS calculator:
https://www.first.org/cvss/calculator/3.1
-->
╔══════════════════════════════════════════════════════════════════════════════╗
║ 📊 CVSS v3.1 SCORING ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ║
║ BASE METRICS: ║
║ ║
║ Attack Vector (AV): [ ] N Network [ ] A Adjacent ║
║ [ ] L Local [ ] P Physical ║
║ ║
║ Attack Complexity (AC): [ ] L Low [ ] H High ║
║ ║
║ Privileges Required (PR):[ ] N None [ ] L Low [ ] H High ║
║ ║
║ User Interaction (UI): [ ] N None [ ] R Required ║
║ ║
║ Scope (S): [ ] U Unchanged [ ] C Changed ║
║ ║
║ Confidentiality (C): [ ] N None [ ] L Low [ ] H High ║
║ ║
║ Integrity (I): [ ] N None [ ] L Low [ ] H High ║
║ ║
║ Availability (A): [ ] N None [ ] L Low [ ] H High ║
║ ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ║
║ CVSS Vector String: ║
║ CVSS:3.1/AV:?/AC:?/PR:?/UI:?/S:?/C:?/I:?/A:? ║
║ ║
║ Base Score: X.X ████████░░ [NONE/LOW/MEDIUM/HIGH/CRITICAL] ║
║ ║
║ Calculated at: https://www.first.org/cvss/calculator/3.1 ║
║ ║
╚══════════════════════════════════════════════════════════════════════════════╝

text


### Temporal & Environmental Modifiers

<details>
<summary>📐 Temporal & Environmental Scores (click to expand)</summary>
TEMPORAL METRICS (adjust base score for exploit maturity):

Exploit Code Maturity (E):
[ ] X Not Defined [ ] U Unproven [ ] P Proof-of-Concept
[ ] F Functional [ ] H High

Remediation Level (RL):
[ ] X Not Defined [ ] O Official Fix [ ] T Temporary Fix
[ ] W Workaround [ ] U Unavailable

Report Confidence (RC):
[ ] X Not Defined [ ] U Unknown [ ] R Reasonable
[ ] C Confirmed

Temporal Score: X.X (adjusted from base X.X)

─────────────────────────────────────────────────────────────────

ENVIRONMENTAL METRICS (ASH Dotfiles specific context):

Modified Attack Vector (MAV): [ ] N [ ] A [ ] L [ ] P [ ] X
Modified Attack Complexity (MAC): [ ] L [ ] H [ ] X
Modified Privileges Required: [ ] N [ ] L [ ] H [ ] X
Modified User Interaction: [ ] N [ ] R [ ] X
Modified Scope: [ ] U [ ] C [ ] X
Modified Confidentiality: [ ] N [ ] L [ ] H [ ] X
Modified Integrity: [ ] N [ ] L [ ] H [ ] X
Modified Availability: [ ] N [ ] L [ ] H [ ] X

Confidentiality Requirement: [ ] L Low [ ] M Medium [ ] H High [ ] X
Integrity Requirement: [ ] L Low [ ] M Medium [ ] H High [ ] X
Availability Requirement: [ ] L Low [ ] M Medium [ ] H High [ ] X

Environmental Score: X.X

text


</details>

### CWE Classification
Primary CWE:
┌──────────────────────────────────────────────────────────────────────────┐
│ CWE-XXX: [CWE Name] │
│ URL: https://cwe.mitre.org/data/definitions/XXX.html │
│ Category: [Injection / Path Traversal / Auth / Crypto / etc.] │
└──────────────────────────────────────────────────────────────────────────┘

Related CWEs (if applicable):
CWE-XXX: [Name] — [Relationship: parent / child / peer]
CWE-XXX: [Name] — [Relationship]

Common Weakness Enumeration Categories:
[ ] CWE-20: Improper Input Validation
[ ] CWE-22: Path Traversal
[ ] CWE-78: OS Command Injection
[ ] CWE-79: Cross-site Scripting
[ ] CWE-89: SQL Injection
[ ] CWE-94: Code Injection
[ ] CWE-119: Buffer Overflow
[ ] CWE-125: Out-of-bounds Read
[ ] CWE-190: Integer Overflow
[ ] CWE-200: Information Exposure
[ ] CWE-269: Improper Privilege Management
[ ] CWE-276: Incorrect Default Permissions
[ ] CWE-295: Improper Certificate Validation
[ ] CWE-306: Missing Authentication
[ ] CWE-307: Brute Force Protection Missing
[ ] CWE-310: Cryptographic Issues
[ ] CWE-326: Inadequate Encryption Strength
[ ] CWE-327: Use of Broken Algorithm
[ ] CWE-330: Insufficient Randomness
[ ] CWE-338: PRNG Not Suitable for Security
[ ] CWE-352: CSRF
[ ] CWE-362: Race Condition
[ ] CWE-377: Insecure Temp File
[ ] CWE-400: Resource Exhaustion
[ ] CWE-416: Use After Free
[ ] CWE-426: Untrusted Search Path
[ ] CWE-434: Unrestricted File Upload
[ ] CWE-476: NULL Pointer Dereference
[ ] CWE-502: Deserialization of Untrusted Data
[ ] CWE-521: Weak Password Requirements
[ ] CWE-522: Insufficiently Protected Credentials
[ ] CWE-601: Open Redirect
[ ] CWE-611: XXE Injection
[ ] CWE-676: Use of Dangerous Function
[ ] CWE-732: Incorrect Permission Assignment
[ ] CWE-787: Out-of-bounds Write
[ ] CWE-798: Hardcoded Credentials
[ ] CWE-862: Missing Authorization
[ ] CWE-863: Incorrect Authorization
[ ] CWE-915: Mass Assignment
[ ] CWE-918: SSRF
[ ] CWE-XXX: Other: ______________________

text


### MITRE ATT&CK Mapping
ATT&CK Tactic(s):
[ ] TA0001: Initial Access
[ ] TA0002: Execution
[ ] TA0003: Persistence
[ ] TA0004: Privilege Escalation
[ ] TA0005: Defense Evasion
[ ] TA0006: Credential Access
[ ] TA0007: Discovery
[ ] TA0008: Lateral Movement
[ ] TA0009: Collection
[ ] TA0010: Exfiltration
[ ] TA0011: Command and Control
[ ] TA0040: Impact
[ ] N/A : Not applicable (hardening only)

ATT&CK Technique(s):
Primary: T[XXXX]: [Technique Name]
Secondary: T[XXXX]: [Technique Name] (if applicable)

ATT&CK URL: https://attack.mitre.org/techniques/T[XXXX]/

text


---

## 🔍 SECTION 03 — VULNERABILITY ANALYSIS

### CVE Information
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🏷️ CVE RECORD ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ║
║ CVE ID: CVE-YYYY-NNNNN ║
║ [ ] Requested from MITRE Date: YYYY-MM-DD ║
║ [ ] Assigned by GitHub Date: YYYY-MM-DD ║
║ [ ] Not requested (CVSS < 4.0 / hardening only) ║
║ ║
║ NVD Entry: https://nvd.nist.gov/vuln/detail/CVE-YYYY-NNNNN ║
║ [ ] Submitted [ ] Published [ ] N/A ║
║ ║
║ GitHub Advisory: GHSA-XXXX-XXXX-XXXX ║
║ [ ] Drafted [ ] Under review [ ] Published ║
║ Advisory URL: https://github.com/ash-dotfiles/ash-dotfiles/ ║
║ security/advisories/GHSA-XXXX-XXXX-XXXX ║
║ ║
╚══════════════════════════════════════════════════════════════════════════════╝

text


### Root Cause Technical Analysis
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🔬 TECHNICAL ROOT CAUSE ANALYSIS ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ║
║ VULNERABILITY CLASS: ║
║ [e.g., Unsanitized user input passed to shell command via eval] ║
║ ║
║ VULNERABLE CODE LOCATION: ║
║ File: ash-cli/commands/[component]/[file].sh ║
║ Lines: L[start]-L[end] ║
║ Function: function_name ║
║ Commit: abc1234def (introduced YYYY-MM-DD) ║
║ ║
║ ROOT CAUSE (one sentence): ║
║ [The exact technical defect — e.g., "User-controlled theme name is ║
║ interpolated directly into a shell command without validation, ║
║ allowing metacharacter injection via specially crafted theme names"] ║
║ ║
║ WHY IT WASN'T CAUGHT: ║
║ [ ] No test coverage for this input path ║
║ [ ] Code review missed the security implication ║
║ [ ] ShellCheck does not catch this pattern ║
║ [ ] Appeared safe due to incorrect assumption about input source ║
║ [ ] Regression from a refactor that changed input handling ║
║ [ ] New feature introduced without security review ║
║ [ ] Dependency update changed behavior ║
║ [ ] Other: ___________________________________________ ║
║ ║
╚══════════════════════════════════════════════════════════════════════════════╝

text


### Exploit Chain Analysis

<!--
Document the complete attack chain. This MUST be included for
vulnerability patches but should NOT include working exploit code.
Describe the attack conceptually — enough to understand and test the fix,
not enough to be a ready-to-use exploit.
-->

<details>
<summary>⛓️ Exploit Chain (Conceptual — No Working Exploit Code)</summary>
ATTACK CHAIN ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PREREQUISITES:
Required: [What the attacker must have/control]
Helpful: [What makes exploitation easier]
Not needed: [Common assumptions that DON'T apply]

ATTACK STAGES:
┌─────────────────────────────────────────────────────────┐
│ Stage 1: INITIAL ACCESS │
│ ───────────────────────────────────────────────────── │
│ Attacker [action] to reach [vulnerable component] │
│ Prerequisite: [what attacker needs] │
└────────────────────────────┬────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────┐
│ Stage 2: TRIGGER │
│ ───────────────────────────────────────────────────── │
│ Attacker [trigger action] causing [vulnerable code] │
│ to [process malicious input] without [missing check] │
└────────────────────────────┬────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────┐
│ Stage 3: EXPLOITATION │
│ ───────────────────────────────────────────────────── │
│ Vulnerable code [processes/executes] attacker's │
│ [payload type] resulting in [impact] │
└────────────────────────────┬────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────┐
│ Stage 4: IMPACT │
│ ───────────────────────────────────────────────────── │
│ Attacker achieves: [concrete impact] │
│ Affected data: [what is exposed/modified/lost] │
│ Affected systems: [scope of impact] │
└─────────────────────────────────────────────────────────┘

REALISTIC ATTACK SCENARIOS:
Most Likely: [How a real attacker would most probably exploit this]
Most Severe: [Worst-case exploitation scenario]
Least Likely: [Theoretical but requires significant attacker capability]

BARRIERS TO EXPLOITATION:
[What makes this harder to exploit than the CVSS score alone suggests]

EXPLOIT COMPLEXITY ASSESSMENT:
Script Kiddie: [ ] Trivial [ ] Easy [ ] Hard [ ] Impossible
Skilled Attacker:[ ] Trivial [ ] Easy [ ] Hard [ ] Impossible
Nation State: [ ] Trivial [ ] Easy [ ] Hard [ ] Impossible

EVIDENCE OF ACTIVE EXPLOITATION:
[ ] None detected — no evidence of exploitation in the wild
[ ] Suspected — [evidence description]
[ ] Confirmed — [PoC / exploit kit / incident reports]

text


</details>

### Affected Versions Matrix
VERSION IMPACT ANALYSIS:
┌──────────────┬────────────────┬──────────────────────────────────────────┐
│ Version │ Vulnerable? │ Notes │
├──────────────┼────────────────┼──────────────────────────────────────────┤
│ v5.0.2 │ 🔴 YES │ Current latest — primary target │
│ v5.0.1 │ 🔴 YES │ Introduced in this version │
│ v5.0.0 │ ✅ NO │ Predates vulnerable code │
│ v4.x.x │ ✅ NO │ Different architecture │
│ v3.x.x │ ✅ NO │ Feature not present │
├──────────────┼────────────────┼──────────────────────────────────────────┤
│ Git HEAD │ ✅ PATCHED │ This PR │
│ NixOS pkg │ 🔴 YES │ Mirrors v5.0.2 — needs flake update │
│ AUR pkg │ 🔴 YES │ Mirrors v5.0.2 — needs PKGBUILD update │
│ Flatpak │ 🔴 YES │ Mirrors v5.0.2 — needs manifest update │
│ Docker img │ 🔴 YES │ ash-dotfiles:5.0.2 is vulnerable │
└──────────────┴────────────────┴──────────────────────────────────────────┘

First vulnerable commit: abc1234 — "feat: add theme name validation"
Last vulnerable commit: def5678 — (HEAD before this fix)
Fix commit: [this PR — assigned after merge]

text


### Blast Radius Assessment
USER POPULATION IMPACT:
┌────────────────────────────────────────────────────────────────────────┐
│ Total potentially affected: ~50,000 users (all v5.0.1+ installs) │
│ Realistically exploitable: ~5,000 users (community plugin users) │
│ Actively exploited: 0 confirmed (as of YYYY-MM-DD) │
├────────────────────────────────────────────────────────────────────────┤
│ PLATFORM BREAKDOWN: │
│ 🏔️ Arch Linux: ~35,000 (70%) — Most exposed (AUR package) │
│ 🌀 Fedora: ~7,500 (15%) — Exposed via COPR │
│ ❄️ NixOS: ~5,000 (10%) — Exposed via flake │
│ 🐧 Others: ~2,500 (5%) — Various install methods │
├────────────────────────────────────────────────────────────────────────┤
│ EXPLOITATION REQUIREMENT: Community plugin registry must be enabled │
│ Default state: ENABLED (makes this higher priority) │
│ Opt-out: ash config set plugin.registry.community.enabled false │
└────────────────────────────────────────────────────────────────────────┘

text


---

## 🔨 SECTION 04 — THE SECURITY FIX

### Vulnerable Code (Exact Defect)

```diff
# ════════════════════════════════════════════════════════════════════
# FILE: ash-cli/commands/plugin/install.sh
# FUNCTION: extract_plugin_archive()
# LINES: 143-151
# INTRODUCED: commit abc1234 (YYYY-MM-DD)
# ════════════════════════════════════════════════════════════════════
#
# DEFECT: tar extraction without path traversal validation.
# An attacker-controlled archive can contain filenames with
# "../" sequences, writing files outside the plugin directory.

  extract_plugin_archive() {
    local archive="${1}"
    local install_dir="${2}"

-   # VULNERABLE: No path validation before extraction
-   tar -xzf "${archive}" -C "${install_dir}"
-   # An archive containing "../../.ssh/authorized_keys" will
-   # write outside the intended install_dir boundary.
  }
Security Fix (Complete Implementation)
Diff

# ════════════════════════════════════════════════════════════════════
# THE FIX: Validate ALL archive members before extraction
# Defense: Reject archives containing path traversal sequences
# Defense: Use --strip-components for additional protection
# Defense: Verify final extraction stayed within bounds
# ════════════════════════════════════════════════════════════════════

+ # Security: Validate archive contents before extraction
+ # Prevents CWE-22 (Path Traversal) via malicious plugin archives
+ validate_archive_members() {
+   local archive="${1}"
+   local install_dir="${2}"
+   local real_install_dir
+
+   # Resolve canonical path — prevent symlink-based bypass
+   real_install_dir="$(realpath -m "${install_dir}")"
+
+   # Inspect every archive member before touching the filesystem
+   while IFS= read -r member; do
+     # Strip leading / and ./ for consistent normalization
+     local clean_member="${member#./}"
+     clean_member="${clean_member#/}"
+
+     # Resolve what the full extraction path would be
+     local full_path
+     full_path="$(realpath -m "${real_install_dir}/${clean_member}")"
+
+     # CRITICAL CHECK: Verify path stays within install_dir
+     if [[ "${full_path}" != "${real_install_dir}"/* ]] && \
+        [[ "${full_path}" != "${real_install_dir}" ]]; then
+       ash::log "error" \
+         "SECURITY: Archive path traversal detected: '${member}'"
+       ash::log "error" \
+         "Resolved to '${full_path}' — outside '${real_install_dir}'"
+       ash::notification::send \
+         "security" \
+         "⚠️ Plugin Rejected — Security Threat" \
+         "Archive contains path traversal attempt. Installation blocked."
+       return 1  # REJECT the entire archive
+     fi
+   done < <(tar -tzf "${archive}" 2>/dev/null)
+
+   return 0  # All members validated — safe to extract
+ }
+
  extract_plugin_archive() {
    local archive="${1}"
    local install_dir="${2}"

+   # STEP 1: Validate all archive members (prevents path traversal)
+   if ! validate_archive_members "${archive}" "${install_dir}"; then
+     ash::log "error" "Plugin installation BLOCKED — malicious archive"
+     return 1
+   fi
+
+   # STEP 2: Extract with additional OS-level protections
-   tar -xzf "${archive}" -C "${install_dir}"
+   tar -xzf "${archive}" \
+     -C "${install_dir}" \
+     --strip-components=1 \
+     --no-same-owner \
+     --no-same-permissions \
+     --no-overwrite-dir \
+     2>/dev/null
+
+   # STEP 3: Post-extraction boundary verification
+   # Belt-and-suspenders: verify no files escaped the sandbox
+   while IFS= read -r -d '' extracted_file; do
+     local real_extracted
+     real_extracted="$(realpath "${extracted_file}")"
+     local real_install
+     real_install="$(realpath "${install_dir}")"
+
+     if [[ "${real_extracted}" != "${real_install}"/* ]]; then
+       ash::log "error" \
+         "SECURITY: Post-extraction escape detected: ${extracted_file}"
+       # Emergency cleanup — remove entire plugin dir
+       rm -rf "${install_dir}"
+       return 1
+     fi
+   done < <(find "${install_dir}" -print0)
+
+   ash::log "info" "Archive extracted safely to ${install_dir}"
  }
Fix Design Principles
text

SECURITY FIX DESIGN ANALYSIS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Defense in Depth — Three Independent Validation Layers:
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: PRE-EXTRACTION VALIDATION                             │
│  Inspect every archive member path before touching filesystem.  │
│  Any path traversal → reject ENTIRE archive, no extraction.     │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: EXTRACTION HARDENING                                  │
│  tar flags: --no-same-owner --no-same-permissions               │
│  Prevents SUID/SGID preservation from malicious archives.       │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: POST-EXTRACTION AUDIT                                 │
│  Verify every extracted file is within plugin boundary.         │
│  Emergency cleanup if any escape detected.                      │
└─────────────────────────────────────────────────────────────────┘

Why realpath -m (not realpath alone):
  realpath alone fails if the path doesn't exist yet.
  realpath -m handles non-existent paths safely — critical for
  pre-extraction validation where files don't exist yet.

Why reject the ENTIRE archive (not just bad files):
  An attacker who includes one malicious member likely has
  multiple. Partial extraction creates inconsistent state.
  Full rejection is simpler, safer, and easier to reason about.

Symlink Attack Prevention:
  realpath resolves symlinks before comparison.
  An archive containing: plugin-dir -> /tmp/../../home/user
  would be resolved to the actual target before boundary check.
Additional Hardening (Defense-in-Depth)
Diff

# ════════════════════════════════════════════════════════════════════
# ADDITIONAL: Plugin sandbox directory setup
# Ensure plugin directory is owned by user, not world-writable
# ════════════════════════════════════════════════════════════════════

  setup_plugin_directory() {
    local plugin_dir="${1}"
    mkdir -p "${plugin_dir}"
+
+   # Security: Set restrictive permissions on plugin directory
+   # Prevents other users from reading plugin state/logs
+   chmod 700 "${plugin_dir}"
+
+   # Security: Verify ownership is current user
+   local dir_owner
+   dir_owner="$(stat -c '%U' "${plugin_dir}")"
+   if [[ "${dir_owner}" != "$(whoami)" ]]; then
+     ash::log "error" \
+       "SECURITY: Plugin directory owned by wrong user: ${dir_owner}"
+     return 1
+   fi
  }
Diff

# ════════════════════════════════════════════════════════════════════
# ADDITIONAL: Archive integrity verification (supply chain hardening)
# Verify SHA256 checksum before attempting extraction
# ════════════════════════════════════════════════════════════════════

+ verify_archive_integrity() {
+   local archive="${1}"
+   local expected_hash="${2}"
+   local actual_hash
+
+   actual_hash="$(sha256sum "${archive}" | awk '{print $1}')"
+
+   if [[ "${actual_hash}" != "${expected_hash}" ]]; then
+     ash::log "error" \
+       "SECURITY: Archive integrity check FAILED"
+     ash::log "error" \
+       "Expected: ${expected_hash}"
+     ash::log "error" \
+       "Actual:   ${actual_hash}"
+     ash::notification::send \
+       "security" \
+       "⚠️ Plugin Rejected — Integrity Check Failed" \
+       "Archive SHA256 mismatch. Download may be corrupted or tampered."
+     return 1
+   fi
+
+   ash::log "debug" "Archive integrity verified: ${actual_hash}"
+   return 0
+ }
🧪 SECTION 05 — SECURITY VERIFICATION
Vulnerability Reproduction (Pre-Fix)
Bash

# ════════════════════════════════════════════════════════════════════
# STEP 1: Confirm vulnerability EXISTS on unpatched version
# Run on: git checkout v5.0.2 (before this fix)
# ════════════════════════════════════════════════════════════════════

# Create a test archive with path traversal (sanitized PoC):
create_traversal_test_archive() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Create indicator file — written to SAFE location for testing
  # (Real exploit would target ~/.ssh/authorized_keys etc.)
  mkdir -p "${tmp_dir}/plugin-files"
  echo "PATH_TRAVERSAL_POSSIBLE" > "${tmp_dir}/plugin-files/test.txt"

  # Package with path traversal entry (sanitized — points to /tmp):
  cd "${tmp_dir}"
  tar -czf traversal-test.tar.gz \
    --transform 's|plugin-files|plugin-files/../../../tmp/ash-vuln-test|' \
    plugin-files/test.txt

  echo "${tmp_dir}/traversal-test.tar.gz"
}

# On UNPATCHED v5.0.2:
archive="$(create_traversal_test_archive)"
ash plugin install --local "${archive}" 2>/dev/null

# Verify extraction escaped plugin directory:
if [[ -f "/tmp/ash-vuln-test/test.txt" ]]; then
  echo "🔴 VULNERABLE: Path traversal confirmed on $(ash --version)"
else
  echo "✅ NOT VULNERABLE: Path traversal blocked"
fi
Fix Verification (Post-Fix)
Bash

# ════════════════════════════════════════════════════════════════════
# STEP 2: Confirm fix BLOCKS the attack
# Run on: git checkout hotfix/[this-pr-branch]
# ════════════════════════════════════════════════════════════════════

# Remove any artifacts from pre-fix test:
rm -f /tmp/ash-vuln-test/test.txt

# Attempt same attack on patched version:
archive="$(create_traversal_test_archive)"
ash plugin install --local "${archive}" 2>&1

# Expected output (patched behavior):
# [ERROR] SECURITY: Archive path traversal detected: 'plugin-files/../../../tmp/ash-vuln-test/test.txt'
# [ERROR] Resolved to '/tmp/ash-vuln-test/test.txt' — outside '/home/user/.local/share/ash/plugins/...'
# [ERROR] Plugin installation BLOCKED — malicious archive
# 📱 Notification: "⚠️ Plugin Rejected — Security Threat"

# Verify attack was blocked:
if [[ -f "/tmp/ash-vuln-test/test.txt" ]]; then
  echo "🔴 FIX FAILED: Path traversal still possible"
  exit 1
else
  echo "✅ FIX VERIFIED: Path traversal blocked on $(ash --version)"
fi

# Also verify legitimate plugins still install correctly:
ash plugin install focus-timer 2>&1
ash plugin status focus-timer | grep "enabled"
echo "✅ REGRESSION CHECK: Legitimate plugin install still works"
Regression Test Suite
Bash

# ════════════════════════════════════════════════════════════════════
# REGRESSION TESTS — Added to test suite permanently
# File: tests/security/test-plugin-path-traversal.sh
# ════════════════════════════════════════════════════════════════════

#!/usr/bin/env bash
# Regression tests for CVE-YYYY-NNNNN / Issue #XXX
# These tests MUST continue to pass on every future commit.

source tests/helpers/test-framework.sh
source tests/helpers/assertions.sh

# ─── Test 1: Basic path traversal rejected ────────────────────────
test_basic_path_traversal_rejected() {
  local archive
  archive="$(create_test_archive_with_traversal "../../../tmp/evil")"

  run ash plugin install --local "${archive}"

  assert_exit_code_nonzero "${?}" \
    "Plugin with path traversal must be rejected"
  assert_file_not_exists "/tmp/evil" \
    "Path traversal file must not be created"
  assert_log_contains "SECURITY: Archive path traversal detected" \
    "Security error must be logged"
}

# ─── Test 2: Absolute paths rejected ──────────────────────────────
test_absolute_path_in_archive_rejected() {
  local archive
  archive="$(create_test_archive_with_member "/etc/crontab")"

  run ash plugin install --local "${archive}"

  assert_exit_code_nonzero "${?}" \
    "Archive with absolute paths must be rejected"
}

# ─── Test 3: Symlink escape rejected ──────────────────────────────
test_symlink_escape_rejected() {
  local archive
  archive="$(create_test_archive_with_symlink "escape" "/tmp")"

  run ash plugin install --local "${archive}"

  assert_exit_code_nonzero "${?}" \
    "Archive with symlink escape must be rejected"
}

# ─── Test 4: Deeply nested traversal rejected ─────────────────────
test_deeply_nested_traversal_rejected() {
  local archive
  archive="$(create_test_archive_with_traversal \
    "a/b/c/d/e/../../../../../../../../tmp/deep-evil")"

  run ash plugin install --local "${archive}"

  assert_exit_code_nonzero "${?}" \
    "Deep nested path traversal must be rejected"
  assert_file_not_exists "/tmp/deep-evil" \
    "Deep traversal file must not be created"
}

# ─── Test 5: Legitimate archive still installs ────────────────────
test_legitimate_archive_accepted() {
  local archive
  archive="$(create_legitimate_test_archive)"

  run ash plugin install --local "${archive}"

  assert_exit_code_zero "${?}" \
    "Legitimate plugin archive must install successfully"
  assert_directory_exists \
    "${HOME}/.local/share/ash/plugins/test-plugin" \
    "Plugin directory must be created"
}

# ─── Test 6: Integrity check blocks tampered archive ──────────────
test_tampered_archive_rejected() {
  local archive expected_hash
  archive="$(create_legitimate_test_archive)"
  expected_hash="0000000000000000000000000000000000000000000000000000000000000000"

  run ash plugin install --local "${archive}" \
    --expected-hash "${expected_hash}"

  assert_exit_code_nonzero "${?}" \
    "Tampered archive must be rejected"
  assert_log_contains "integrity check FAILED" \
    "Integrity failure must be logged"
}

run_all_tests
Security Audit Trail
text

SECURITY VERIFICATION LOG:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[YYYY-MM-DD HH:MM UTC] Vulnerability reported by @[reporter]
[YYYY-MM-DD HH:MM UTC] Acknowledged by @[maintainer]
[YYYY-MM-DD HH:MM UTC] Reproduced on v5.0.2 by @[author]
[YYYY-MM-DD HH:MM UTC] Root cause identified: [description]
[YYYY-MM-DD HH:MM UTC] Fix developed by @[author]
[YYYY-MM-DD HH:MM UTC] Fix verified by @[author] on Arch Linux
[YYYY-MM-DD HH:MM UTC] Fix verified by @[reviewer1] on Fedora 39
[YYYY-MM-DD HH:MM UTC] Fix verified by @[reviewer2] on NixOS 23.11
[YYYY-MM-DD HH:MM UTC] Security test suite added (6 regression tests)
[YYYY-MM-DD HH:MM UTC] ShellCheck: 0 errors on all changed files
[YYYY-MM-DD HH:MM UTC] gitleaks: 0 secrets detected
[YYYY-MM-DD HH:MM UTC] Peer security review by @[security-reviewer]
[YYYY-MM-DD HH:MM UTC] PR opened — embargo maintained
[YYYY-MM-DD HH:MM UTC] Advisory drafted: GHSA-XXXX-XXXX-XXXX
[YYYY-MM-DD HH:MM UTC] CVE ID requested: CVE-YYYY-NNNNN
🛡️ SECTION 06 — SECURITY TESTING EVIDENCE
Automated Security Scans
Bash

# ShellCheck — Static analysis on all changed files:
$ shellcheck --severity=warning --enable=all \
    ash-cli/commands/plugin/install.sh \
    ash-cli/lib/archive-utils.sh

# Result:
In ash-cli/commands/plugin/install.sh line 143:
  [No issues detected]

In ash-cli/lib/archive-utils.sh line 23:
  [No issues detected]

✅ ShellCheck: 0 errors, 0 warnings on changed files
Bash

# gitleaks — Secret detection on this PR's changes:
$ gitleaks detect --source . \
    --log-opts="origin/main..HEAD" \
    --verbose

  ○
  │╲
  │ ○
  ○ ░
  ░░░

  INFO[YYYY-MM-DDTHH:MM:SS] scan completed in Xs
  INFO[YYYY-MM-DDTHH:MM:SS] no leaks found

✅ gitleaks: 0 secrets detected in this PR
Bash

# Permission audit on new/modified files:
$ bash tests/security/test-permissions.sh --changed-only

Checking permissions on changed files:
  ash-cli/commands/plugin/install.sh    750 ✅ (executable, not world-writable)
  ash-cli/lib/archive-utils.sh          640 ✅ (library, not executable, not world-readable... wait)
  tests/security/test-path-traversal.sh 750 ✅ (test, executable)

✅ Permission check: All files have correct permissions
Bash

# Injection test — verify fix blocks all traversal patterns:
$ bash tests/security/test-injection.sh --plugin-archive

Testing path traversal patterns:
  Pattern "../../../tmp/evil"                → BLOCKED ✅
  Pattern "..%2F..%2F..%2Ftmp%2Fevil"       → BLOCKED ✅
  Pattern "....//....//tmp//evil"            → BLOCKED ✅
  Pattern "/absolute/path/evil"              → BLOCKED ✅
  Pattern "a/b/../../../../tmp/evil"         → BLOCKED ✅
  Pattern "./../../tmp/evil"                 → BLOCKED ✅
  Pattern "safe-path/../../../tmp/evil"      → BLOCKED ✅
  Pattern "plugin/../../../.ssh/evil"        → BLOCKED ✅
  Pattern "symlink-to-/tmp"                  → BLOCKED ✅
  Pattern "null-byte\x00/tmp/evil"           → BLOCKED ✅

  Legitimate paths:
  Pattern "lib/timer.sh"                     → ALLOWED ✅
  Pattern "init.sh"                          → ALLOWED ✅
  Pattern "fish/functions/timer.fish"        → ALLOWED ✅
  Pattern "tests/test-timer.sh"              → ALLOWED ✅

✅ Injection tests: 10/10 malicious patterns BLOCKED, 4/4 legitimate ALLOWED
Platform Verification Matrix
text

FIX VERIFICATION ACROSS PLATFORMS:
┌────────────────┬─────────────┬────────────┬────────────────────────────┐
│  Platform      │  Verified   │  Verifier  │  Notes                     │
├────────────────┼─────────────┼────────────┼────────────────────────────┤
│  Arch Linux    │  ✅ PASS    │  @author   │  Primary test platform     │
│  Fedora 39     │  ✅ PASS    │  @reviewer1│  GNU tar 1.35              │
│  NixOS 23.11   │  ✅ PASS    │  @reviewer2│  GNU tar in nix store      │
│  Ubuntu 22.04  │  ✅ PASS    │  @reviewer3│  GNU tar 1.34              │
│  openSUSE TW   │  ⏳ PENDING │  —         │  Expected before merge     │
│  Void Linux    │  ⏳ PENDING │  —         │  Expected before merge     │
│  Gentoo        │  ❓ NEEDED  │  —         │  Different tar flags?      │
├────────────────┼─────────────┼────────────┼────────────────────────────┤
│  busybox tar   │  ⚠️ PARTIAL │  @author   │  --strip-components N/A    │
│                │             │            │  Fallback path added       │
│  bsdtar (macOS)│  ❓ N/A     │  —         │  ASH is Linux-only         │
└────────────────┴─────────────┴────────────┴────────────────────────────┘

busybox tar fallback (for Alpine/minimal systems):
  busybox tar does not support --strip-components
  Added fallback: detect busybox tar and use alternative approach
  Tested on: Alpine Linux 3.19 with busybox 1.36.1
📋 SECTION 07 — SECURITY ADVISORY DRAFT
<!-- Draft the GitHub Security Advisory that will be published after patching. This is edited by maintainers before publication but having a draft dramatically speeds up the disclosure process. --><details> <summary>📋 GitHub Security Advisory Draft (internal — published after merge)</summary>
Markdown

---
# GitHub Security Advisory Draft
# GHSA-XXXX-XXXX-XXXX
# Published: AFTER patch release (embargo: YYYY-MM-DD)
---

## Summary

A path traversal vulnerability in ASH Dotfiles' plugin installation system
allows a malicious plugin archive to extract files outside the intended
plugin directory, potentially writing to arbitrary filesystem locations
accessible by the current user.

## Severity

**CVSS Score:** X.X (HIGH)
**CVSS Vector:** CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N
**CWE:** CWE-22 (Improper Limitation of a Pathname to a Restricted Directory)

## Affected Versions

| Version | Affected |
|---------|----------|
| >= 5.0.1, < 5.0.3 | **Yes** |
| < 5.0.1 | No |

## Patched Versions

**5.0.3** — Released YYYY-MM-DD

## Description

The `ash plugin install` command uses `tar` to extract plugin archives
into the user's plugin directory (`~/.local/share/ash/plugins/[id]/`).

Prior to version 5.0.3, the extraction was performed without validating
archive member paths for path traversal sequences. A specially crafted
plugin archive containing filenames with `../` sequences could extract
files to arbitrary locations within the user's home directory.

**Impact:**
- Arbitrary file write to any path accessible by the current user
- Potential for persistence via `~/.config/fish/config.fish` injection
- Potential credential theft via `~/.ssh/` or `~/.aws/` overwrite
- NOT a privilege escalation to root (requires existing user access)

**Exploitation Requires:**
1. User installs a malicious plugin archive (via community registry
   or `--url`/`--local` flags)
2. The archive contains path traversal sequences in member names

## Mitigation (Before Patching)

Disable the community plugin registry until you can update:
```bash
ash config set plugin.registry.community.enabled false
Only install plugins from the official registry or from sources you
have personally reviewed and trust.

Fix
Version 5.0.3 adds three layers of protection:

Pre-extraction validation: All archive members are inspected
before any filesystem writes occur. Any path traversal sequence
causes the entire archive to be rejected.

Extraction hardening: Additional tar flags prevent SUID/SGID
preservation and permission copying from archives.

Post-extraction audit: After extraction, all files are verified
to reside within the expected plugin directory boundary.

Update Instructions
Bash

ash update --force
# Verify:
ash --version  # Should show v5.0.3 or later
Credits
This vulnerability was discovered and responsibly disclosed by
[Reporter Name] (@[github-handle]).

We thank [Reporter Name] for their responsible disclosure and for
working with us to protect ASH Dotfiles users.

[Reporter Name] is eligible for our bug bounty program.
Bounty: $[amount] (Category: HIGH severity)

References
Fix PR: https://github.com/ash-dotfiles/ash-dotfiles/pull/XXX
Similar: CVE-2021-32804 (npm tar path traversal)
CWE-22: https://cwe.mitre.org/data/definitions/22.html
CVSS Calculator: https://www.first.org/cvss/calculator/3.1#CVSS:3.1/...
text


</details>

---

## 👤 SECTION 08 — REPORTER ATTRIBUTION & BOUNTY

### Reporter Information
╔══════════════════════════════════════════════════════════════════════════════╗
║ 👤 SECURITY REPORTER RECORD ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ║
║ Reporter Name: [Name / "Anonymous" / "Internal Discovery"] ║
║ GitHub Handle: @[handle] / [Not provided] ║
║ Contact: [Email / Discord / Signal / "Prefers anonymous"] ║
║ Organization: [Company / "Independent Researcher" / N/A] ║
║ Affiliation: [Security team / Bug bounty hunter / Academic / etc.] ║
║ ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ATTRIBUTION PREFERENCE: ║
║ [ ] Full public credit: "[Name] (@[handle]) of [Organization]" ║
║ [ ] Handle only: "@[github-handle]" ║
║ [ ] Anonymous: "An anonymous security researcher" ║
║ [ ] No mention: Omit from advisory entirely ║
║ ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ HALL OF FAME: ║
║ [ ] Include in Security Hall of Fame page ║
║ [ ] Exclude from Hall of Fame ║
║ ║
╚══════════════════════════════════════════════════════════════════════════════╝

text


### Bug Bounty Processing
BUG BOUNTY ASSESSMENT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Bounty Program URL: https://ash-dotfiles.github.io/security/bounty

Eligibility Check:
[ ] ✅ New vulnerability (not previously known/reported)
[ ] ✅ Affects a supported version (v5.0.x)
[ ] ✅ Reporter followed responsible disclosure
[ ] ✅ Reproducible with provided information
[ ] ✅ Has security impact (not just QA/functional bug)

CVSS-Based Bounty Range:
🔴 CRITICAL (9.0-10.0): $200 - $500
🟠 HIGH (7.0-8.9): $50 - $200
🟡 MEDIUM (4.0-6.9): $10 - $50
🟢 LOW (0.1-3.9): Swag + Hall of Fame

This Report:
CVSS Score: X.X ([CRITICAL/HIGH/MEDIUM/LOW])
Bounty Amount: $[amount] USD
Payment Via: [ ] GitHub Sponsors [ ] PayPal [ ] Crypto [ ] Swag
Status: [ ] Approved [ ] Pending board review [ ] N/A

text


---

## 🔄 SECTION 09 — POST-PATCH PROCESS

### Release Coordination
PATCH RELEASE CHECKLIST:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRE-RELEASE (complete before merge):
[ ] Security advisory drafted: GHSA-XXXX-XXXX-XXXX
[ ] CVE ID requested/assigned: CVE-YYYY-NNNNN
[ ] All verification tests passing on ≥3 platforms
[ ] CHANGELOG.md security section updated
[ ] Version bumped: 5.0.2 → 5.0.3
[ ] AUR PKGBUILD ready for update
[ ] NixOS flake.lock update prepared
[ ] Docker image rebuild queued
[ ] Flatpak manifest update prepared

RELEASE (merge + tag):
[ ] PR merged to main
[ ] Tag created: v5.0.3
[ ] GitHub Release published (with changelog)
[ ] AUR PKGBUILD updated
[ ] Docker image pushed: ash-dotfiles:5.0.3 + :latest
[ ] NixOS flake updated

POST-RELEASE (within 1 hour of release):
[ ] GitHub Security Advisory published
[ ] Discord #announcements: security update notice
[ ] Discord #security: vulnerability details (post-disclosure)
[ ] Twitter/Mastodon: security update notice
[ ] Mailing list: security@ash-dotfiles.dev notification
[ ] NVD: CVE details submitted (if CVE assigned)

MONITORING (24-72 hours post-release):
[ ] Monitor Discord for user issues post-patch
[ ] Monitor GitHub Issues for regression reports
[ ] Confirm update propagated to AUR/Nix/Docker
[ ] Verify NVD entry is accurate (if CVE)
[ ] Close original security advisory report

text


### User Communication Templates

```markdown
<!-- Discord #announcements template: -->

🔒 **Security Update — ASH Dotfiles v5.0.3**

A security vulnerability (CVE-YYYY-NNNNN) has been patched in
ASH Dotfiles v5.0.3. We recommend all users update immediately.

**Severity:** 🟠 HIGH (CVSS X.X)
**Impact:** [One-line description without exploit details]

**Update now:**
```bash
ash update --force
ash --version  # Verify: v5.0.3
If you cannot update immediately:

Bash

# Temporary mitigation:
ash config set plugin.registry.community.enabled false
Full details in the Security Advisory:
https://github.com/ash-dotfiles/ash-dotfiles/security/advisories/GHSA-XXXX-XXXX-XXXX

Thank you to @[reporter] for responsible disclosure. 🙏

text


---

## ✅ SECTION 10 — SECURITY PR MASTER CHECKLIST

### Disclosure Compliance (Hard Gates — ALL must be ✅ before merge)

- [ ] 🔒 **Embargo honored** — No exploit details publicly exposed before patch
- [ ] 📋 **Advisory drafted** — GHSA draft created and under maintainer review
- [ ] 👁️ **Private review** — Core security team has reviewed this PR privately
- [ ] 📢 **Comms approved** — Post-release communication plan approved
- [ ] 🏷️ **CVE coordinated** — CVE assignment coordinated with maintainers
- [ ] 👤 **Attribution confirmed** — Reporter attribution preference documented

### Fix Quality (All must be ✅)

- [ ] 🔬 **Root cause fixed** — Not just symptoms — underlying defect is corrected
- [ ] 🛡️ **Defense in depth** — Multiple independent protection layers implemented
- [ ] 🔄 **No new vulnerabilities** — Fix does not introduce new security issues
- [ ] ✅ **Verified effective** — Fix confirmed blocking the attack on all platforms
- [ ] 🔁 **Regression tests** — New tests added that will catch future regressions
- [ ] 🌐 **All versions patched** — All vulnerable versions addressed or EOL-noted

### Code Quality (All must be ✅)

- [ ] 🔍 **ShellCheck clean** — 0 errors, 0 warnings on all changed files
- [ ] 🕵️ **gitleaks clean** — 0 secrets detected in PR commits
- [ ] 📁 **Permissions correct** — File permissions verified with security test
- [ ] 💉 **Injection tested** — All injection/traversal patterns confirmed blocked
- [ ] 📝 **Documented** — Security comments explain WHY each check is necessary
- [ ] 🧹 **Minimal change** — Only security-necessary changes in this PR

### Release Readiness (All must be ✅)

- [ ] 📦 **Version bumped** — Patch version incremented
- [ ] 📝 **CHANGELOG updated** — Security section added
- [ ] 🚀 **Release plan** — AUR/Nix/Docker/Flatpak update plan confirmed
- [ ] 📊 **Blast radius** — Affected user population documented

### Reviewer Requirements
Security PRs require sign-off from:

🔴 CRITICAL / HIGH vulnerabilities:
Required: Lead Maintainer + Security Team Lead + 1 Senior Contributor
Timeline: Prioritized — review within 4 hours

🟡 MEDIUM vulnerabilities:
Required: Lead Maintainer + 1 Senior Contributor
Timeline: Review within 24 hours

🟢 LOW / Hardening:
Required: 1 Senior Contributor + 1 Maintainer
Timeline: Review within 72 hours

Requested Reviewers:
@<!-- maintainer-1 --> (Lead Maintainer)
@<!-- security-lead --> (Security Team Lead)
@<!-- senior-contributor --> (Domain Expert)

text


---

<div align="center">

---

### 🔒 Security PR Response SLAs
CRITICAL: Report → Patch → Release → Advisory
now +4hr +6hr +post-release
████████████████████████████████████

HIGH: Report → Patch → Release → Advisory
now +24hr +48hr +post-release
████████████████████████

MEDIUM: Report → Patch → Release → Advisory
now +1wk +1wk +post-release
████████████

LOW/HARD: Report → Patch → Release → Advisory
now +2wk +2wk +post-release
████████

text


### 🛡️ Security Resources

| Resource | Link |
|----------|------|
| 📋 Security Policy | [SECURITY.md](https://github.com/ash-dotfiles/ash-dotfiles/blob/main/SECURITY.md) |
| 🔒 Private Report | [GitHub Security Advisory](https://github.com/ash-dotfiles/ash-dotfiles/security/advisories/new) |
| 🏆 Hall of Fame | [Security Contributors](https://ash-dotfiles.github.io/security/hall-of-fame) |
| 💰 Bug Bounty | [Bounty Program](https://ash-dotfiles.github.io/security/bounty) |
| 📧 Security Email | security@ash-dotfiles.dev |
| 🔑 PGP Key | [Download](https://ash-dotfiles.github.io/pgp-key.asc) |
| 💬 Discord | [#security-private](https://discord.gg/ash-dotfiles) |

### 🙏 Thank You for Protecting ASH Users

Every security contribution — from a 0-day report to a hardening improvement —
makes the desktop experience safer for thousands of users worldwide.

Your work is appreciated, credited, and rewarded. 🛡️

*— The ASH Dotfiles Security Team* 🔒

</div>
