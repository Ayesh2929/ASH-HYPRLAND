<!-- ╔══════════════════════════════════════════════════════════════════════╗ -->
<!-- ║  🔒 ASH DOTFILES v5.0 OMEGA — SECURITY POLICY                      ║ -->
<!-- ╚══════════════════════════════════════════════════════════════════════╝ -->

<div align="center">
╔═══════════════════════════════════════════════════════════════════════════╗
║ ║
║ ██████╗ ███████╗ ██████╗██╗ ██╗██████╗ ██╗████████╗██╗ ██╗ ║
║ ██╔════╝██╔════╝██╔════╝██║ ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝ ║
║ ╚█████╗ █████╗ ██║ ██║ ██║██████╔╝██║ ██║ ╚████╔╝ ║
║ ╚═══██╗██╔══╝ ██║ ██║ ██║██╔══██╗██║ ██║ ╚██╔╝ ║
║ ██████╔╝███████╗╚██████╗╚██████╔╝██║ ██║██║ ██║ ██║ ║
║ ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝ ╚═╝╚═╝ ╚═╝ ╚═╝ ║
║ ║
║ 🔒 ASH DOTFILES v5.0 OMEGA — SECURITY POLICY ║
║ Protecting the most advanced dotfiles repository in existence ║
║ ║
╚═══════════════════════════════════════════════════════════════════════════╝

text


[![Security Rating](https://img.shields.io/badge/Security_Rating-A%2B-brightgreen?style=for-the-badge&logo=shield&logoColor=white)](https://github.com/ash-dotfiles/ash-dotfiles/security)
[![Responsible Disclosure](https://img.shields.io/badge/Disclosure-Responsible-blue?style=for-the-badge&logo=lock&logoColor=white)](#reporting)
[![Bug Bounty](https://img.shields.io/badge/Bug_Bounty-Active-gold?style=for-the-badge&logo=hackerone&logoColor=white)](#bug-bounty)
[![Response SLA](https://img.shields.io/badge/Response_SLA-24h-purple?style=for-the-badge&logo=clockify&logoColor=white)](#response-times)
[![Encryption](https://img.shields.io/badge/Reports-GPG_Encrypted-red?style=for-the-badge&logo=gnuprivacyguard&logoColor=white)](#pgp-key)

</div>

---

## 📋 Table of Contents

| # | Section | Description |
|---|---------|-------------|
| 1 | [🛡️ Supported Versions](#-supported-versions) | Which versions receive security updates |
| 2 | [🎯 Scope](#-scope) | What is and isn't in scope |
| 3 | [📢 Reporting a Vulnerability](#-reporting-a-vulnerability) | How to report safely |
| 4 | [⏱️ Response Times](#️-response-times) | Our commitment to you |
| 5 | [🔐 Encryption](#-encryption) | GPG key for encrypted reports |
| 6 | [💰 Bug Bounty](#-bug-bounty) | Rewards for responsible disclosure |
| 7 | [🔬 Vulnerability Classes](#-vulnerability-classes) | Types of vulnerabilities we care about |
| 8 | [📊 Severity Ratings](#-severity-ratings) | How we classify severity |
| 9 | [🛠️ Security Measures](#️-security-measures) | Our defense-in-depth approach |
| 10 | [📜 Disclosure Policy](#-disclosure-policy) | Our coordinated disclosure process |
| 11 | [🏆 Hall of Fame](#-hall-of-fame) | Recognizing security researchers |
| 12 | [📚 Security Resources](#-security-resources) | Learning more about secure usage |

---

## 🛡️ Supported Versions

> We follow a **rolling support model** — only the latest major version receives
> full security support. Older versions receive critical patches for 6 months
> after a new major release.
┌─────────────────────────────────────────────────────────────────────────┐
│ VERSION SUPPORT MATRIX │
├──────────────┬──────────────────┬───────────────┬───────────────────────┤
│ Version │ Release Date │ Status │ Security Support │
├──────────────┼──────────────────┼───────────────┼───────────────────────┤
│ 🏆 v5.0.x │ 2024-12 │ ✅ CURRENT │ Full — all patches │
│ ⚠️ v4.0.x │ 2024-06 │ ⚠️ LTS │ Critical only │
│ 🔶 v3.0.x │ 2024-01 │ 🔶 EOL Soon │ Until 2025-06 │
│ ❌ v2.0.x │ 2023-07 │ ❌ EOL │ None │
│ ❌ v1.0.x │ 2023-01 │ ❌ EOL │ None │
└──────────────┴──────────────────┴───────────────┴───────────────────────┘

text


> [!IMPORTANT]
> If you are running an EOL version, **upgrade immediately**.
> Security vulnerabilities in EOL versions will not receive patches.

---

## 🎯 Scope

### ✅ In Scope

These components are fully in scope for security research:
┌─────────────────────────────────────────────────────────────────────────┐
│ IN SCOPE COMPONENTS │
├────────────────────────────┬────────────────────────────────────────────┤
│ Component │ Attack Surface │
├────────────────────────────┼────────────────────────────────────────────┤
│ 🖥️ ASH CLI Engine │ Command injection, privilege escalation │
│ 🌐 REST API Server │ Auth bypass, injection, data exposure │
│ 🔌 Plugin System │ Malicious plugin execution, escapes │
│ 🎨 Theme Engine │ File write, path traversal │
│ 📜 Install Scripts │ Code execution, supply chain │
│ 🪝 Git Hooks │ Hook injection, code execution │
│ 🤖 AI Engine │ Prompt injection, data leakage │
│ ☁️ Cloud Sync │ Credential exposure, data exfiltration │
│ 🔒 Secrets Management │ Secret exposure, weak encryption │
│ 🖥️ Web Dashboard │ XSS, CSRF, auth bypass │
│ 📱 Mobile App │ Insecure storage, API exposure │
│ 🧩 Browser Extension │ Permission abuse, data theft │
│ ⏱️ Systemd Services │ Privilege escalation, service abuse │
│ 🔐 Hyprlock │ Lock screen bypass │
│ 📦 Dependencies │ Supply chain attacks │
└────────────────────────────┴────────────────────────────────────────────┘

text


### ❌ Out of Scope

The following are **not** in scope and will not receive rewards:

- 🚫 Vulnerabilities in third-party applications we integrate with
  (Hyprland, Waybar, Rofi — report to their respective projects)
- 🚫 Social engineering attacks against maintainers
- 🚫 Physical access attacks
- 🚫 DoS/DDoS attacks against hosted services
- 🚫 Automated scanner results without proof-of-concept
- 🚫 Theoretical vulnerabilities without demonstrated impact
- 🚫 Issues in EOL versions (v2.x and below)
- 🚫 Missing security headers on documentation sites
- 🚫 Vulnerabilities requiring compromised system access to exploit
- 🚫 Self-XSS or vulnerabilities requiring victim interaction via social engineering
- 🚫 Rate limiting issues on public endpoints
- 🚫 Username enumeration via timing

---

## 📢 Reporting a Vulnerability

> [!WARNING]
> **NEVER** open a public GitHub issue for security vulnerabilities.
> This puts all users at immediate risk.

### 🥇 Preferred: GitHub Private Security Advisory

1. Navigate to the **[Security Advisories](https://github.com/ash-dotfiles/ash-dotfiles/security/advisories/new)** page
2. Click **"Report a vulnerability"**
3. Fill in all fields with as much detail as possible
4. Submit — only maintainers can see this report

### 🥈 Alternative: Encrypted Email

Send encrypted reports to: **`security@ash-dotfiles.dev`**

Encrypt with our **[PGP key](#-encryption)** — unencrypted emails for
security issues will be discarded.

### 🥉 Emergency: Signal

For critical zero-days requiring immediate response:
**Signal**: `ash-security.01` *(only for P0/P1 critical issues)*

---

### 📝 Report Template

Please include as much of the following as possible:

```markdown
## Vulnerability Report

### Summary
[One paragraph describing the vulnerability]

### Affected Component
- [ ] ASH CLI Engine
- [ ] REST API
- [ ] Plugin System
- [ ] Theme Engine
- [ ] Install Scripts
- [ ] Web Dashboard
- [ ] Mobile App
- [ ] Browser Extension
- [ ] Other: ___________

### Affected Versions
- Confirmed vulnerable: v_._._
- Confirmed fixed: N/A

### Severity Assessment
- [ ] 🔴 Critical (CVSS 9.0–10.0)
- [ ] 🟠 High     (CVSS 7.0–8.9)
- [ ] 🟡 Medium   (CVSS 4.0–6.9)
- [ ] 🟢 Low      (CVSS 0.1–3.9)

### Attack Vector
- [ ] Network (remote)
- [ ] Local (requires login)
- [ ] Physical

### Prerequisites
[What does an attacker need? Authenticated? Local access? Specific config?]

### Steps to Reproduce
1. [First step]
2. [Second step]
3. [...]

### Proof of Concept
```bash
# PoC code here
Impact
[Describe the full impact if exploited — data theft? RCE? Privilege escalation?]

Suggested Fix
[Optional: your suggested remediation approach]

Researcher Information
Name/Handle: [for Hall of Fame credit]
Contact: [how to reach you for follow-up]
CVE Request: [ ] Yes / [ ] No
text


---

## ⏱️ Response Times

We take security seriously and commit to the following SLAs:
┌─────────────────────────────────────────────────────────────────────────┐
│ RESPONSE TIME COMMITMENTS │
├───────────────┬─────────────┬────────────────┬──────────────────────────┤
│ Severity │ Initial │ Triage │ Fix Target │
│ │ Response │ Complete │ │
├───────────────┼─────────────┼────────────────┼──────────────────────────┤
│ 🔴 Critical │ < 4 hours │ < 24 hours │ Emergency patch: 48h │
│ 🟠 High │ < 24 hours │ < 48 hours │ 7 days │
│ 🟡 Medium │ < 48 hours │ < 7 days │ 30 days │
│ 🟢 Low │ < 7 days │ < 14 days │ 90 days / next release │
│ ℹ️ Info │ < 14 days │ < 30 days │ Best effort │
└───────────────┴─────────────┴────────────────┴──────────────────────────┘

text


> [!NOTE]
> Response times are measured in **calendar days** and apply during
> normal operations. Holidays may extend these by up to 48 hours.
> You will always receive an acknowledgment within the stated window.

**What happens after you report:**
Report Received
│
▼
📧 Acknowledgment (within SLA)
│
▼
🔬 Triage & Severity Assessment
│
├──► 🔴 Critical → Emergency response team activated
│
├──► 🟠 High → Security team sprint prioritization
│
└──► 🟡🟢 Medium/Low → Scheduled fix cycle
│
▼
🛠️ Fix Development (private branch)
│
▼
🧪 Testing & Verification
│
▼
📢 Coordinated Disclosure (with researcher)
│
▼
🚀 Patch Release + CVE Assignment
│
▼
🏆 Hall of Fame Credit

text


---

## 🔐 Encryption

### PGP Public Key

**Key ID:** `0xASH5EC0MEGA2024`
**Fingerprint:** `A5H D0TF 1LES 0MEG A202 4SEC URIT YK3Y 0000 0001`
**Key Server:** `keys.openpgp.org`
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: ASH Dotfiles Security Team
Comment: security@ash-dotfiles.dev

[Full PGP public key block would be here in production]
[This is a placeholder — replace with actual key]

xsBNBGRASHKEYBCAD...
[key data]
...ASH DOTFILES SECURITY=
=XXXX
-----END PGP PUBLIC KEY BLOCK-----

text


**Import the key:**

```bash
# Via keyserver
gpg --keyserver keys.openpgp.org --recv-keys 0xASH5EC0MEGA2024

# Via curl
curl -fsSL https://ash-dotfiles.dev/security/pubkey.asc | gpg --import

# Verify fingerprint
gpg --fingerprint security@ash-dotfiles.dev
Encrypt your report:

Bash

gpg --armor \
    --encrypt \
    --recipient security@ash-dotfiles.dev \
    --output report.asc \
    your-report.md
💰 Bug Bounty
We reward responsible security researchers with:

text

┌─────────────────────────────────────────────────────────────────────────┐
│  BUG BOUNTY REWARDS                                                      │
├───────────────┬──────────────┬──────────────────────────────────────────┤
│  Severity     │  Reward      │  Examples                                │
├───────────────┼──────────────┼──────────────────────────────────────────┤
│  🔴 Critical  │  $500–$2000  │  RCE, auth bypass, data breach           │
│  🟠 High      │  $100–$500   │  Privilege escalation, significant leak  │
│  🟡 Medium    │  $25–$100    │  Limited data exposure, CSRF             │
│  🟢 Low       │  Swag + CoF  │  Minor info leak, best practice miss     │
│  ℹ️  Info     │  Hall of Fame│  Hardening suggestions                   │
└───────────────┴──────────────┴──────────────────────────────────────────┘
Payment methods: GitHub Sponsors • PayPal • Crypto (BTC/ETH/XMR)

Eligibility requirements:

✅ First to report the specific vulnerability
✅ Responsible disclosure (gave us time to patch before public)
✅ Did not exploit beyond proof-of-concept
✅ Did not access, modify, or destroy user data
✅ Provided enough detail for us to reproduce
✅ Not a current or former ASH Dotfiles contributor/employee
🔬 Vulnerability Classes
🔴 Critical Priority
text

• Remote Code Execution (RCE) — any vector
• Authentication/Authorization bypass in API or web dashboard
• Private key / credential exposure in public code
• Supply chain attacks (malicious code injection)
• Lock screen (hyprlock) bypass
• Plugin sandbox escape → host code execution
• SQL/Command/LDAP injection with full access
🟠 High Priority
text

• Privilege escalation (local → root)
• Sensitive data exfiltration (API keys, passwords, tokens)
• Path traversal enabling arbitrary file read/write
• Server-Side Request Forgery (SSRF) with internal access
• Insecure deserialization leading to code execution
• JWT algorithm confusion / token forgery
• Stored XSS in web dashboard
• Dependency confusion attacks
🟡 Medium Priority
text

• Reflected XSS (requires user interaction)
• CSRF on state-changing endpoints
• Insecure Direct Object References (IDOR)
• Information disclosure (stack traces, internal paths)
• Weak cryptography (MD5/SHA1 for security purposes)
• Open redirect vulnerabilities
• Missing authentication on non-critical endpoints
• Insecure file permissions on config files
🟢 Low Priority
text

• Missing security headers (HSTS, CSP, etc.)
• Verbose error messages (non-sensitive)
• Clickjacking on low-sensitivity pages
• Username enumeration (non-exploitable)
• Cookie without HttpOnly/Secure flags (low-impact)
• Best practice deviations without direct impact
📊 Severity Ratings
We use CVSS v3.1 for severity scoring:

text

┌─────────────────────────────────────────────────────────────────────────┐
│  CVSS v3.1 SCORING GUIDE                                                 │
├───────────────┬────────────────────────────────────────────────────────  │
│  Score Range  │  Severity    │  Color   │  SLA Target                   │
├───────────────┼─────────────────────────────────────────────────────────┤
│  9.0 – 10.0  │  Critical    │  🔴 Red    │  Emergency patch < 48h       │
│  7.0 – 8.9   │  High        │  🟠 Orange │  Fix within 7 days           │
│  4.0 – 6.9   │  Medium      │  🟡 Yellow │  Fix within 30 days          │
│  0.1 – 3.9   │  Low         │  🟢 Green  │  Fix in next release          │
│  0.0          │  None / Info │  ⚪ Gray   │  Best effort                 │
└───────────────┴────────────────────────────────────────────────────────  │
CVSS Calculator: https://www.first.org/cvss/calculator/3.1

🛠️ Security Measures
Defense in Depth
Our security architecture implements multiple layers of protection:

🔍 Static Analysis
text

• ShellCheck — all shell scripts scanned on every PR
• Semgrep — SAST rules for bash/python/typescript
• CodeQL — semantic code analysis (GitHub Actions)
• Gitleaks — secret detection pre-commit + CI
• Trivy — container image vulnerability scanning
• OWASP Dependency-Check — known CVE detection
🔒 Supply Chain Security
text

• All GitHub Actions pinned to full SHA commit hashes
• Dependabot — automated dependency update PRs
• npm audit / pip audit in CI pipeline
• SLSA Level 2 build provenance for releases
• Signed releases with GPG
• SBOM (Software Bill of Materials) for each release
🛡️ Runtime Security
text

• Secrets never logged (ASH_SECRET_* env var masking)
• API tokens stored in system keyring (not dotfiles)
• Encrypted backups (AES-256-GCM)
• Minimal sudo usage — privilege separation by design
• XDG-compliant config paths (no root-owned dotfiles)
• Systemd services with strict sandboxing:
    - NoNewPrivileges=true
    - ProtectSystem=strict
    - PrivateTmp=true
    - RestrictSUIDSGID=true
🔐 API Security (REST + WebSocket)
text

• JWT authentication with short expiry (15 min access / 7 day refresh)
• Rate limiting: 100 req/min authenticated, 10 req/min unauthenticated
• Input validation & sanitization on all endpoints
• CORS whitelist — localhost only in default config
• TLS 1.3 required, TLS 1.2 with strong ciphers allowed
• API keys hashed with bcrypt (cost factor 12) at rest
• Request/response logging with PII scrubbing
📦 Plugin Sandboxing
text

• Plugins run with reduced privileges
• Filesystem access restricted to ~/.config/ash/plugins/<name>/
• Network access requires explicit manifest declaration
• No exec() of arbitrary binaries without user confirmation
• Plugin signatures verified against registry public key
• Capability-based permission model (not all-or-nothing)
🔑 Secret Management
text

• Integration credentials use system keyring (libsecret/kwallet)
• No secrets in dotfiles — only references to keyring
• SSH keys protected with hardware tokens (YubiKey support)
• GPG agent integration for commit signing
• Environment variables cleared after use in scripts
📜 Disclosure Policy
We practice Coordinated Vulnerability Disclosure (CVD):

Timeline
text

Day 0:    Researcher reports vulnerability (private)
Day 0:    Acknowledgment sent to researcher
Day 1-3:  Triage, severity assessment, CVSS scoring
Day 3-7:  Development of fix begins (private branch)
Day N:    Fix complete, researcher notified for verification
Day N+3:  Patch tested on all supported distros
Day N+5:  CVE requested from MITRE (if applicable)
Day N+7:  Patch released (emergency releases may be faster)
Day N+14: Public security advisory published
Day N+14: Researcher credited in Hall of Fame
Researcher Rights
✅ You may publish your research after coordinated disclosure
✅ You will receive credit in our Hall of Fame and advisory
✅ You may request a CVE — we will assist
✅ You may live-stream/blog your research after disclosure
❌ You may not publish before the patch is released
❌ You may not sell the vulnerability to third parties
❌ You may not exploit beyond proof-of-concept
Safe Harbor
We commit that researchers acting in good faith under this policy:

Will not face legal action from us
Will be treated as security partners, not adversaries
Will receive our full support in CVE assignment
🏆 Hall of Fame
Recognizing the security researchers who make ASH Dotfiles safer:

Be the first to find a vulnerability and earn your place here!

Researcher	Severity	Component	Date	CVE
Your name here	🔴	—	—	—
To be listed, simply include your preferred name/handle in your report.

📚 Security Resources
For Users
Resource	Description
🔒 Security Setup Guide	Hardening ASH Dotfiles for your environment
🔐 Privacy Guide	Privacy-focused configuration
🛡️ VPN Integration	WireGuard VPN setup
🔑 GPG Setup	Commit signing configuration
🔥 Firewall Setup	nftables/ufw configuration
For Researchers
Resource	Link
📖 CVE Database	https://cve.mitre.org
🧮 CVSS Calculator	https://www.first.org/cvss/calculator/3.1
🔬 Semgrep Rules	https://semgrep.dev/r
🛡️ OWASP Top 10	https://owasp.org/www-project-top-ten
🔍 ShellCheck	https://www.shellcheck.net
📋 Responsible Disclosure	https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html
<div align="center">
🔒 Security is a shared responsibility

Thank you for helping keep ASH Dotfiles and its users safe.
Every vulnerability report, no matter how small, makes a difference.

Report Security Issue https://github.com/ash-dotfiles/ash-dotfiles/security/advisories/new
Security Email mailto:security@ash-dotfiles.dev
Bug Bounty https://arena.ai/c/019ec75f-9f10-7851-8f3c-c2fc5cd6874a#-bug-bounty

Last updated: 2024-12 • Policy version: 3.0.0

</div> ```