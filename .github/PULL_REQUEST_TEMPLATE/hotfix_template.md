Markdown

<!--
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║      🚨 ASH DOTFILES v5.0 OMEGA — HOTFIX PULL REQUEST TEMPLATE                        ║
║      Ultra-Premium Emergency Response System • Zero-Downtime • War Room Protocol      ║
║      Blast Radius Analysis • Rollback Architecture • 5-Stage Verification Pipeline    ║
║      CVE-Ready • Coordinated Release • Post-Mortem Framework • SLA Enforcement        ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝

⚠️  HOTFIX PR — EXPEDITED REVIEW PROCESS ⚠️
This template is for CRITICAL fixes only. Using it inappropriately
slows response to real emergencies. Regular bugs → use pull_request_template.md
-->

<div align="center">
██╗ ██╗ ██████╗ ████████╗███████╗██╗██╗ ██╗
██║ ██║██╔═══██╗╚══██╔══╝██╔════╝██║╚██╗██╔╝
███████║██║ ██║ ██║ █████╗ ██║ ╚███╔╝
██╔══██║██║ ██║ ██║ ██╔══╝ ██║ ██╔██╗
██║ ██║╚██████╔╝ ██║ ██║ ██║██╔╝ ██╗
╚═╝ ╚═╝ ╚═════╝ ╚═╝ ╚═╝ ╚═╝╚═╝ ╚═╝

██████╗ ██████╗ ██╗███████╗ ██████╗████████╗
██╔══██╗██╔══██╗ ██╔╝██╔════╝██╔════╝╚══██╔══╝
██████╔╝██████╔╝ ██╔╝ █████╗ ██║ ██║
██╔═══╝ ██╔══██╗ ██╔╝ ██╔══╝ ██║ ██║
██║ ██║ ██║ ██╔╝ ███████╗╚██████╗ ██║
╚═╝ ╚═╝ ╚═╝╚═╝ ╚══════╝ ╚═════╝ ╚═╝

text


# 🚨 HOTFIX PR — ASH Dotfiles v5.0 OMEGA

<table>
<tr>
<td align="center">
┌─────────────────────────────────────────────┐
│ │
│ 🔴 EMERGENCY RESPONSE ACTIVE 🔴 │
│ │
│ Severity: [ CRITICAL / HIGH / MEDIUM ] │
│ Timer: ⏱️ HH:MM since detection │
│ Patch: v5.0.X-hotfix-N │
│ Status: 🔨 In Progress │
│ │
└─────────────────────────────────────────────┘

text


</td>
</tr>
</table>

</div>

---

> [!CAUTION]
> ## 🚨 HOTFIX ELIGIBILITY — Read Before Proceeding
>
> This template is **ONLY** for issues meeting ALL of these criteria:
>
> | Criterion | Required |
> |-----------|----------|
> | 🔴 Active user impact | **Production users affected RIGHT NOW** |
> | ⚡ Cannot wait | **Next regular release is too slow** |
> | 🎯 Narrow scope | **Minimal change, surgical fix only** |
> | ✅ Known fix | **Root cause identified and solution verified** |
> | 🧪 Testable | **Can be verified within hours** |
>
> **If ANY criterion is not met → use `pull_request_template.md` instead.**
>
> Hotfix misuse delays real emergency responses and is subject to contributor warnings.

> [!TIP]
> **Hotfix fast-track commands:**
> ```bash
> # Create hotfix branch from latest release tag:
> git checkout -b hotfix/v5.0.X-[issue-slug] v5.0.X
>
> # After fix is applied — run accelerated test suite:
> bash tests/run-unit-tests.sh --fast
> bash tests/run-integration-tests.sh --critical-only
>
> # Verify fix resolves the reported issue:
> ash doctor --full --check [affected-component]
>
> # Build release candidate:
> ash benchmark --quick && git tag v5.0.X-rc1
> ```

---

## 🚨 SECTION 01 — INCIDENT CLASSIFICATION

### Severity Level

<!--
Select ONE severity. This determines response SLA and reviewer requirements.
Wrong severity = re-classification by maintainers, which delays response.
-->

- [ ] 🔴 **SEV-1 CRITICAL** — System crash / data loss / security breach / 0-day
  - *Response SLA: 2 hours | Patch SLA: 4 hours | Requires: 2 senior reviewers*
- [ ] 🟠 **SEV-2 HIGH** — Core feature broken for majority of users / major regression
  - *Response SLA: 4 hours | Patch SLA: 12 hours | Requires: 1 senior reviewer*
- [ ] 🟡 **SEV-3 MEDIUM** — Significant feature broken with no workaround for many users
  - *Response SLA: 24 hours | Patch SLA: 48 hours | Requires: 1 reviewer*

### Incident Type

- [ ] 🔒 **Security Vulnerability** — CVE / data exposure / privilege escalation
- [ ] 💥 **System Crash** — ASH, Hyprland, or desktop crashes affecting users
- [ ] 📉 **Critical Regression** — Feature worked in previous version, broken in latest
- [ ] 🔗 **Dependency Break** — External dependency change broke ASH functionality
- [ ] 💾 **Data Loss** — User configuration, themes, or data being corrupted/lost
- [ ] 🌐 **API Outage** — REST API or WebSocket completely non-functional
- [ ] 📱 **Mobile Blocked** — Mobile app completely unable to connect or function
- [ ] 🎨 **Theme Corruption** — Theme system destroying user configurations
- [ ] 📦 **Install Failure** — Installation script broken on a Tier-1 distribution
- [ ] 🔄 **Update Break** — `ash update` causing system instability

---

## ⏱️ SECTION 02 — INCIDENT TIMELINE

<!--
Precise timeline is essential for post-mortem analysis and SLA verification.
All times in UTC.
-->
╔══════════════════════════════════════════════════════════════════════════╗
║ 🕐 INCIDENT TIMELINE (UTC) ║
╠══════════════════════════════════════════════════════════════════════════╣
║ ║
║ 📍 DETECTED: YYYY-MM-DD HH:MM UTC ║
║ └── How: [ ] User report [ ] CI alert [ ] Monitoring [ ] Self ║
║ ║
║ 🔍 DIAGNOSED: YYYY-MM-DD HH:MM UTC (+XX min from detection) ║
║ └── Root cause identified by: @[github-handle] ║
║ ║
║ 🔨 FIX STARTED: YYYY-MM-DD HH:MM UTC (+XX min from diagnosis) ║
║ └── Fix author: @[github-handle] ║
║ ║
║ ✅ PR OPENED: YYYY-MM-DD HH:MM UTC (+XX min from fix start) ║
║ ║
║ 🎯 TARGET MERGE: YYYY-MM-DD HH:MM UTC (within SLA window) ║
║ ║
║ 📣 USER NOTIFY: [ ] Pre-patch warning [ ] Post-patch announcement ║
║ ║
╚══════════════════════════════════════════════════════════════════════════╝

text


### Time-to-Patch Progress
Detection → Diagnosis → Fix → Review → Merge → Release → Monitor
✅ ✅ ✅ 🔄 ⏳ ⏳ ⏳
+0 min +Xmin +Xmin NOW TARGET +Xmin +1hr

text


---

## 🎯 SECTION 03 — VULNERABILITY / ISSUE IDENTIFICATION

### Root Cause Analysis
╔══════════════════════════════════════════════════════════════════════════╗
║ 🔍 ROOT CAUSE ANALYSIS ║
╠══════════════════════════════════════════════════════════════════════════╣
║ ║
║ WHAT: [One sentence describing the technical root cause] ║
║ ║
║ WHERE: [Exact file:line or component containing the defect] ║
║ ║
║ WHY: [Why did this defect exist / why wasn't it caught by tests] ║
║ ║
║ HOW: [How is the defect triggered / exploit chain if security] ║
║ ║
║ SINCE: [Which commit/version introduced this] ║
║ ║
╚══════════════════════════════════════════════════════════════════════════╝

text


### Affected Versions

| Version | Affected | Evidence |
|---------|----------|----------|
| v5.0.2 (latest) | <!-- 🔴 YES / ✅ NO --> | |
| v5.0.1 | <!-- 🔴 YES / ✅ NO --> | |
| v5.0.0 | <!-- 🔴 YES / ✅ NO --> | |
| v4.x.x | <!-- 🔴 YES / ✅ NO / ❓ Unknown --> | |

**First affected version:** `v5.0.X` (introduced in commit `abc1234`)
**Last known good version:** `v5.0.Y`

### CVE Information (Security Issues Only)
CVE ID: CVE-YYYY-XXXXX (requested / assigned / N/A)
CVSS Score: X.X (Critical/High/Medium/Low)
CVSS Vector: CVSS:3.1/AV:?/AC:?/PR:?/UI:?/S:?/C:?/I:?/A:?
CWE: CWE-XXX ([CWE Name])
Public Disclosure: [Date — must be AFTER patch release]
Reporter: [Name / Anonymous / Internal]
Bounty Eligible: YES / NO

text


---

## 💥 SECTION 04 — BLAST RADIUS ANALYSIS

<!--
Critical for understanding scope and prioritization.
Be honest — underreporting blast radius delays appropriate response.
-->

### User Impact Assessment
╔══════════════════════════════════════════════════════════════════════╗
║ 💥 BLAST RADIUS ║
╠══════════════════════════════════════════════════════════════════════╣
║ ║
║ Users affected: [ ] All [ ] ~75% [ ] ~50% [ ] ~25% [ ] <10% ║
║ Estimated count: ~X,XXX users impacted ║
║ Impact severity: [ ] Cannot use ASH [ ] Feature broken ║
║ [ ] Degraded perf [ ] Cosmetic ║
║ ║
╠══════════════════════════════════════════════════════════════════════╣
║ AFFECTED PLATFORMS: ║
║ 🐧 All distros: YES / NO ║
║ 🏔️ Arch Linux: YES / NO ║
║ 🌀 Fedora: YES / NO ║
║ ❄️ NixOS: YES / NO ║
║ 🐧 Others: YES / NO ║
╠══════════════════════════════════════════════════════════════════════╣
║ AFFECTED HARDWARE: ║
║ 🎮 NVIDIA users: YES / NO (driver version: XXX) ║
║ 🎮 AMD users: YES / NO ║
║ 🎮 Intel users: YES / NO ║
║ 💻 Laptop users: YES / NO ║
╠══════════════════════════════════════════════════════════════════════╣
║ AFFECTED COMPONENTS: ║
║ ⚡ ASH CLI: YES / NO ║
║ 🎨 Theme Engine: YES / NO ║
║ 🔌 Plugin System: YES / NO ║
║ 📊 Waybar: YES / NO ║
║ 🪟 Hyprland: YES / NO ║
║ 🌐 REST API: YES / NO ║
║ 📱 Mobile App: YES / NO ║
╚══════════════════════════════════════════════════════════════════════╝

text


### Secondary Effects

<!--
What else breaks as a consequence of this issue?
What does NOT break (to reassure users)?
-->

**Also broken (cascading failures):**
- [ ] [Secondary effect 1]
- [ ] [Secondary effect 2]

**Confirmed NOT affected (safe to use):**
- ✅ [Component verified safe]
- ✅ [Component verified safe]

### Evidence from Reports
Community reports as of YYYY-MM-DD HH:MM UTC:
┌─────────────────────────────────────────────────────┐
│ GitHub Issues: X reports (issue #XXX, #YYY) │
│ Discord #bug-reports: X reports in last X hours │
│ Reddit mentions: X posts │
│ Direct emails: X reports to security@... │
│ Error rate spike: +X% in monitoring dashboard │
└─────────────────────────────────────────────────────┘

text


---

## 🔬 SECTION 05 — THE FIX (SURGICAL PRECISION)

### Fix Philosophy

<!--
Hotfixes must be MINIMAL. No refactoring. No new features.
No "while I'm here" cleanup. Laser-focused on the defect only.
-->

**Fix strategy:**
- [ ] 🎯 **Surgical** — Minimum viable change, touches ≤ 5 lines
- [ ] 📏 **Contained** — Touches 1-2 files maximum
- [ ] ↩️ **Reversible** — Can be rolled back in < 5 minutes
- [ ] 🔒 **No side effects** — Zero behavior change outside fix scope

**Lines changed:** `+X / -Y` (target: < 20 total)
**Files changed:** `X` (target: ≤ 3)

### The Defective Code

```diff
# File: ash-cli/commands/[component]/[file].sh
# Line: XXX
# Commit that introduced bug: abc1234

- [EXACT DEFECTIVE CODE — paste the broken line(s)]
- [with context showing why it's wrong]
The Fix
Diff

# File: ash-cli/commands/[component]/[file].sh
# Line: XXX
# Fix explanation: [one sentence — what this line now does correctly]

+ [EXACT FIX — paste the corrected line(s)]
+ [with context showing the correction]
Fix Explanation
text

WHY THIS FIX IS CORRECT:
  [Technical explanation of why the fixed code produces correct behavior]

WHY THIS FIX IS SAFE:
  [Explain why this won't break anything else]

WHY THIS IS THE MINIMAL FIX:
  [Explain why you didn't do more — proper fix belongs in regular PR #XXX]
Alternative Fixes Considered & Rejected
Alternative	Why Rejected
[Alt 1]	[Too risky / too broad / doesn't fix root cause]
[Alt 2]	[Requires refactor — belongs in regular PR]
🛡️ SECTION 06 — VERIFICATION & PROOF
Reproduction + Verification Protocol
Bash

# ════════════════════════════════════════════════════════
# STEP 1: Reproduce on UNPATCHED system
# ════════════════════════════════════════════════════════
$ git checkout v5.0.X  # Last release tag before fix

# Trigger the issue:
$ [exact command that triggers the bug]
# Expected (broken): [what the broken behavior looks like]
# ✅ Confirmed: Bug reproduces on unpatched v5.0.X

# ════════════════════════════════════════════════════════
# STEP 2: Verify fix on PATCHED system
# ════════════════════════════════════════════════════════
$ git checkout hotfix/v5.0.X-[slug]  # This PR's branch

# Run same trigger:
$ [exact same command]
# Expected (fixed): [what correct behavior looks like]
# ✅ Confirmed: Bug does NOT reproduce on patched version

# ════════════════════════════════════════════════════════
# STEP 3: Verify no regressions
# ════════════════════════════════════════════════════════
$ bash tests/run-unit-tests.sh --fast
# Result: XX/XX passed ✅

$ bash tests/run-integration-tests.sh --critical-only
# Result: XX/XX passed ✅

$ ash doctor --full
# Result: All checks passed ✅
Verification Evidence
Before patch (screenshot/output showing the bug):

<!-- [DRAG SCREENSHOT/OUTPUT OF BUG HERE] -->
text

[Paste terminal output showing the bug]
After patch (screenshot/output showing the fix):

<!-- [DRAG SCREENSHOT/OUTPUT OF FIX HERE] -->
text

[Paste terminal output showing correct behavior after fix]
Test Results
Test Suite	Before Fix	After Fix
Unit tests	X/Y passed	<!-- X/Y passed ✅ -->
Integration (critical)	X/Y passed	<!-- X/Y passed ✅ -->
Manual regression	FAIL	<!-- PASS ✅ -->
ShellCheck	<!-- X warnings -->	<!-- 0 warnings ✅ -->
Regression Test Added
Bash

# New regression test to prevent future recurrence:
# File: tests/unit/test-[component]-regression.sh

test_regression_[issue_number]_[short_description]() {
  # Regression test for: https://github.com/ash-dotfiles/ash-dotfiles/issues/XXX
  # Fixed in: hotfix/v5.0.X-[slug]

  # Setup
  [setup code]

  # Trigger the previously-broken scenario
  result=$([trigger command])

  # Assert correct behavior
  assert_equals "expected" "${result}" \
    "Regression: issue #XXX must not recur"

  echo "✅ Regression test #XXX: PASS"
}
🔄 SECTION 07 — ROLLBACK ARCHITECTURE
<!-- Every hotfix MUST have a tested rollback plan. The rollback must be executable in under 5 minutes. -->
Rollback Trigger Conditions
text

ROLLBACK if ANY of these occur post-merge:
┌──────────────────────────────────────────────────────────────┐
│  ❌ New crash reports increase vs baseline                    │
│  ❌ New bug introduced (visible within 1 hour of release)     │
│  ❌ Performance regression > 20% from baseline               │
│  ❌ Any data loss reported post-patch                        │
│  ❌ Patch breaks a previously-working Tier-1 distro           │
└──────────────────────────────────────────────────────────────┘
Rollback Procedure (< 5 minutes)
Bash

# ════════════════════════════════════════════════════════════════
# ROLLBACK PLAN — Execute if patch causes new issues
# Estimated time: 3-5 minutes from decision to user recovery
# ════════════════════════════════════════════════════════════════

# MAINTAINER STEPS:
# Step 1: Revert the merge (30 seconds)
git revert --mainline 1 [merge-commit-sha]
git push origin main --force-with-lease

# Step 2: Remove hotfix tag (30 seconds)
git tag -d v5.0.X-hotfix-N
git push origin :refs/tags/v5.0.X-hotfix-N

# Step 3: Publish rollback notice (2 minutes)
# → Discord #announcements: "Hotfix v5.0.X rolled back — investigating"
# → GitHub Issue: Comment on tracked issue
# → AUR: Re-push previous PKGBUILD

# USER SELF-ROLLBACK:
# Option A: Snapshot restore (recommended — 30 seconds)
ash snapshot restore --latest-stable

# Option B: Version pin (60 seconds)
ash update --version v5.0.Y  # Last known good

# Option C: Manual git rollback (90 seconds)
cd ~/.config/ash-dotfiles
git checkout v5.0.Y
ash reload --all
Rollback Verification
Bash

# Verify rollback successful:
ash --version                    # Should show v5.0.Y
ash doctor --full                # Should show all green
ash theme apply catppuccin-mocha # Core functionality test
📢 SECTION 08 — COMMUNICATION PLAN
Pre-Release User Notification
Status page update: Required / Not required
Discord announcement: Required timing: [X hours before / simultaneous / after]

Markdown

<!-- Discord #announcements draft: -->

🚨 **ASH Dotfiles Hotfix — v5.0.X** 🚨

**Severity:** 🔴 Critical / 🟠 High / 🟡 Medium
**Affected:** [Who is affected]
**Issue:** [One sentence description]
**Status:** ✅ Patch available now

**Update immediately:**
```bash
ash update --force
# Verify:
ash --version  # Should show v5.0.X
If you've experienced data loss / crashes:
→ Run: ash snapshot restore --latest-pre-[date]
→ Report in: #incident-reports

ETA for update propagation: ~15 minutes

text


### Post-Release Monitoring Plan
T+0: Hotfix merged and tagged
T+15m: Monitor Discord #bug-reports for new reports
T+30m: Check CI dashboard for unexpected failures
T+1h: Review any new GitHub issues opened
T+4h: Declare incident resolved (or escalate)
T+24h: Post-mortem document begins (assigned to: @[handle])
T+72h: Post-mortem published

text


---

## 📊 SECTION 09 — POST-MORTEM FRAMEWORK

<!--
ALL SEV-1 and SEV-2 hotfixes require a post-mortem within 72 hours.
Start filling this now — complete after resolution.
-->

<details>
<summary>📋 Post-Mortem Template (fill within 72 hours of resolution)</summary>

```markdown
# Post-Mortem: [Issue Title]
**Date:** YYYY-MM-DD
**Severity:** SEV-X
**Duration:** X hours from detection to resolution
**Author:** @[github-handle]
**Status:** Draft / Review / Published

## Executive Summary
[2-3 sentences: what happened, what impact was, how it was resolved]

## Timeline
[Complete timeline from detection to full resolution]

## Root Cause
[Technical root cause — 5 Whys analysis]

Why #1: [symptom]
Why #2: [direct cause]
Why #3: [contributing factor]
Why #4: [process gap]
Why #5: [systemic issue]

**Root cause:** [The fundamental systemic issue]

## Contributing Factors
- [Factor 1]
- [Factor 2]

## What Went Well ✅
- [Thing that worked well in the response]
- [Another thing]

## What Went Poorly ❌
- [Thing that could have been better]
- [Another thing]

## Action Items
| Action | Owner | Priority | Due Date | Status |
|--------|-------|----------|----------|--------|
| Add regression test | @[handle] | P0 | [date] | ✅ Done (in this PR) |
| Fix detection gap | @[handle] | P1 | [date] | 🔜 Pending |
| Update runbook | @[handle] | P2 | [date] | 🔜 Pending |
| CI check to prevent | @[handle] | P1 | [date] | 🔜 Pending |

## Prevention
[What changes will prevent this class of issue from recurring]
</details>
🔒 SECTION 10 — SECURITY VERIFICATION
<!-- Mandatory even for non-security hotfixes — hotfixes are high-value targets. -->
Fix Security Properties
 🔍 Fix introduces no new code paths that could be exploited
 💉 All inputs remain validated through the fix
 🔑 Fix does not weaken authentication or authorization
 📁 Fix does not open new file system access vectors
 🌐 Fix does not add network calls or change existing ones
 📝 Fix contains zero hardcoded credentials or secrets
 🧹 Fix does not use eval or dynamic code execution
For Security Fixes Specifically
text

CVE Response Compliance:
[ ] Private disclosure honored (no public details before patch)
[ ] CVSS score calculated and documented above
[ ] Affected versions documented and communicated
[ ] Reporter credited (or anonymized per their request)
[ ] Security advisory drafted (publish after merge)
[ ] Bug bounty processed (if eligible)
✅ SECTION 11 — HOTFIX PR CHECKLIST
Eligibility Verification (Block merge if ANY unchecked)
 🚨 This is a genuine emergency meeting all hotfix criteria above
 🎯 Fix is surgical — only the minimum necessary change
 📏 Touches ≤ 3 files and < 20 lines total (or justified below)
 🔬 Root cause is definitively identified (not guessing)
 ✅ Fix is verified on a real system (not just "should work")
Quality Gates (All must pass before merge)
 🧪 Unit tests pass: bash tests/run-unit-tests.sh --fast ✅
 🔗 Critical integration tests pass ✅
 🔒 ShellCheck: zero errors, zero warnings ✅
 📉 No performance regression vs baseline ✅
 ↩️ Rollback plan documented and executable ✅
 📝 Regression test added to prevent recurrence ✅
 📋 CHANGELOG entry added (hotfix section) ✅
Release Requirements
 🏷️ Version bumped: 5.0.X → 5.0.X+1 (patch increment)
 📝 CHANGELOG.md updated with ## [5.0.X] — HOTFIX section
 🌿 Branched from correct base: main (or v5.0.X tag for older versions)
 📢 Communication plan acknowledged by @ash-maintainers
Reviewer Requirements
SEV-1: Requires 2 senior maintainer approvals before merge
SEV-2: Requires 1 senior maintainer approval before merge
SEV-3: Requires 1 maintainer approval before merge

Requested reviewers (tag them):

Primary: @ <!-- e.g., @maintainer1 -->
Secondary (SEV-1 only): @ <!-- e.g., @maintainer2 -->
<div align="center">
🚨 HOTFIX RESPONSE SLAs
text

SEV-1 CRITICAL:  Detect → Merge → Release → Monitor
                   NOW    +4hr    +4.5hr     +5hr
                   ████████████████████████████████ 4 hour window

SEV-2 HIGH:      Detect → Merge → Release → Monitor
                   NOW    +12hr   +12.5hr   +24hr
                   ████████████████████████ 12 hour window

SEV-3 MEDIUM:    Detect → Merge → Release → Monitor
                   NOW    +48hr   +48.5hr   +72hr
                   ████████████ 48 hour window
🔴 Need immediate maintainer attention?

Ping the on-call maintainer via:

📱 Discord: @ash-core-team in #incidents
📧 Email: oncall@ash-dotfiles.dev
🚨 PagerDuty: ash-dotfiles-oncall (SEV-1 only)
— The ASH Dotfiles Incident Response Team 🚨

</div> ```