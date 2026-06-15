Markdown

<!--
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║      ✨ ASH DOTFILES v5.0 OMEGA — FEATURE PULL REQUEST TEMPLATE                       ║
║      Ultra-Premium Feature Delivery System • RFC Framework • Design Review            ║
║      User Story Mapping • Acceptance Criteria • Feature Flag • A/B Testing           ║
║      Accessibility Audit • Performance Budget • API Versioning • Rollout Strategy    ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
-->

<div align="center">
███████╗███████╗ █████╗ ████████╗██╗ ██╗██████╗ ███████╗
██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║ ██║██╔══██╗██╔════╝
█████╗ █████╗ ███████║ ██║ ██║ ██║██████╔╝█████╗
██╔══╝ ██╔══╝ ██╔══██║ ██║ ██║ ██║██╔══██╗██╔══╝
██║ ███████╗██║ ██║ ██║ ╚██████╔╝██║ ██║███████╗
╚═╝ ╚══════╝╚═╝ ╚═╝ ╚═╝ ╚═════╝ ╚═╝ ╚═╝╚══════╝

██████╗ ██████╗
██╔══██╗██╔══██╗
██████╔╝██████╔╝
██╔═══╝ ██╔══██╗
██║ ██║ ██║
╚═╝ ╚═╝ ╚═╝

text


# ✨ Feature PR — ASH Dotfiles v5.0 OMEGA

> *"Features that delight users, architectures that last decades"*

</div>

---

> [!NOTE]
> **Feature PR best practices:**
> - 🗣️ Discuss in an issue or RFC first — prevents wasted effort on rejected directions
> - 🌿 Feature branches should be rebased on `main` before opening PR
> - 📦 Large features should be broken into reviewable chunks (< 500 LOC per PR ideally)
> - 🏁 Feature flags allow merging incomplete work safely
> - 🧪 Test coverage is non-negotiable — features without tests will not be merged

> [!TIP]
> **Feature readiness check:**
> ```bash
> # Verify branch is current with main:
> git fetch origin && git rebase origin/main
>
> # Run full test suite:
> bash tests/run-all-tests.sh
>
> # Check performance impact:
> ash benchmark --compare main..HEAD
>
> # Verify accessibility (for UI features):
> ash theme validate --accessibility ./affected-files/
>
> # Self-review checklist:
> gh pr diff | wc -l  # Should ideally be < 1000 lines
> ```

---

## ✨ SECTION 01 — FEATURE IDENTITY

### Feature Summary Card
╔══════════════════════════════════════════════════════════════════════════╗
║ ✨ FEATURE: [Feature Name — max 60 chars] ║
║ 🏷️ VERSION: Targeting ASH v[X.Y.Z] ║
║ 📅 STARTED: [YYYY-MM-DD] ║
║ ⏱️ EFFORT: [Actual time spent: X days] ║
║ 📏 SCOPE: +XXX / -YYY lines | X files changed ║
║ 🎯 AUDIENCE: [Who benefits: all users / power users / devs / etc.] ║
╚══════════════════════════════════════════════════════════════════════════╝

text


### Related Planning Documents

| Document | Link | Status |
|----------|------|--------|
| Feature Request Issue | <!-- #XXX --> | <!-- Open / Closed --> |
| RFC / Design Doc | <!-- Link or N/A --> | <!-- Approved / Pending --> |
| Roadmap Entry | <!-- Link or N/A --> | <!-- v5.X milestone --> |
| Discord Discussion | <!-- Link --> | <!-- X upvotes --> |
| Community Survey | <!-- Rank or N/A --> | <!-- #X most requested --> |

---

## 📖 SECTION 02 — USER STORY & VALUE

### 🎯 User Stories

<!--
Write from the user's perspective. Each story should be independently valuable.
Format: "As a [user type], I want [goal], so that [benefit]."
-->

**Primary Story:**
> As a **[user type]**,
> I want **[specific capability]**,
> so that **[concrete benefit / time saved / pain eliminated]**.

**Supporting Stories:**
> As a **[user type]**, I want **[goal]** so that **[benefit]**.

> As a **[user type]**, I want **[goal]** so that **[benefit]**.

### 📊 Quantified Value Proposition

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Time for [task] | Xmin | Xsec | X% faster |
| Steps to [action] | X steps | Y steps | -X steps |
| Commands to [goal] | X cmds | Y cmds | -X cmds |
| Manual work eliminated | X mins/day | 0 | 100% |
| Features unlocked | X | Y | +Z new |

### 🌍 User Impact by Persona

| Persona | Impact | Frequency of Benefit |
|---------|--------|---------------------|
| 🆕 New User | [Impact] | Once (onboarding) |
| 💪 Power User | [Impact] | Daily |
| 🔌 Plugin Developer | [Impact] | Per plugin |
| 🎨 Theme Creator | [Impact] | Per theme |
| 🐧 Distro Maintainer | [Impact] | Per release |

---

## 🏗️ SECTION 03 — DESIGN DOCUMENT

### Architecture Overview

<!--
Explain the design at a high level. Include diagrams where helpful.
ASCII diagrams are strongly preferred for inline readability.
-->
┌─────────────────────────────────────────────────────────────────────┐
│ FEATURE ARCHITECTURE │
│ │
│ [Draw your component diagram here using ASCII art] │
│ │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │
│ │ Component A │─────▶│ Component B │─────▶│ Output / UI │ │
│ │ │ │ │ │ │ │
│ │ [describe] │ │ [describe] │ │ [describe] │ │
│ └──────────────┘ └──────────────┘ └──────────────────┘ │
│ │ ▲ │
│ └────────────────────┘ │
│ [data flow description] │
└─────────────────────────────────────────────────────────────────────┘

text


### Data Flow

```bash
# Input → Processing → Output pipeline:

# User triggers feature:
[trigger mechanism]  →  [processing steps]  →  [output/effect]

# Example for a theme scheduling feature:
ash theme schedule --from sunset --theme nord
    ↓
ash-cli/commands/theme/schedule.sh::create_schedule()
    ↓
~/.local/share/ash/state/schedules.json (persisted)
    ↓
ash-theme-scheduler.service (systemd watches & triggers)
    ↓
ash theme apply nord  (executed at sunset)
    ↓
All ASH components reload with new theme
Key Design Decisions
Decision	Options Considered	Choice Made	Rationale
[Decision 1]	A vs B vs C	A	[Why]
[Decision 2]	X vs Y	Y	[Why]
[Decision 3]	P vs Q	P	[Why]
Files Changed & Architecture Impact
text

ash-cli/
├── commands/
│   └── [new-command]/
│       ├── [new-command].sh     [NEW] Main command dispatcher
│       ├── create.sh            [NEW] Create subcommand
│       ├── list.sh              [NEW] List subcommand
│       └── delete.sh            [NEW] Delete subcommand
├── engines/
│   └── [new-engine]/            [NEW] Core engine logic
│       ├── [engine].sh
│       └── [helper].sh
├── lib/
│   └── [new-lib].sh             [MODIFIED] Added helper functions
systemd/user/
└── ash-[feature].service        [NEW] Background service
config/
└── [feature]/                   [NEW] Default configuration
tests/
└── unit/test-[feature].sh       [NEW] Unit tests
docs/
└── guides/[feature]-guide.md    [NEW] User documentation
🎨 SECTION 04 — USER INTERFACE DESIGN
<!-- For any feature with user-facing output, define the exact UI/UX. Consistency with existing ASH aesthetics is required. -->
CLI Interface Design
Bash

# ══════════════════════════════════════════════════════════
# COMMAND SYNTAX
# ══════════════════════════════════════════════════════════

USAGE:
    ash [command] [subcommand] [OPTIONS] [ARGUMENTS]

SUBCOMMANDS:
    create    [description of create]
    list      [description of list]
    delete    [description of delete]
    status    [description of status]

OPTIONS:
    -n, --name <NAME>         [Description, required]
    -t, --type <TYPE>         [Description: option1|option2|option3]
    -f, --force               [Description, optional flag]
    -v, --verbose             [Verbose output]
    -q, --quiet               [Suppress all output]
    -j, --json                [JSON output for scripting]
    -h, --help                [Show this help]

EXAMPLES:
    # Basic usage:
    ash [command] create --name "my-name"

    # Advanced usage:
    ash [command] create --name "my-name" --type advanced --force

    # Scripting (JSON output):
    ash [command] list --json | jq '.[] | .name'

ALIASES:
    [short] → ash [command] [subcommand]
Terminal Output Design
text

╔══════════════════════════════════════════════════════════════════╗
║  ✨ [Feature Name] — [Action]                                   ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Status:      [Status with icon]                                 ║
║  Created:     [Value]                                            ║
║  Next run:    [Value]                                            ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  ✅ [Step 1 completed]                                           ║
║  ✅ [Step 2 completed]                                           ║
║  🔄 [Step 3 in progress]...                                      ║
║  ⏳ [Step 4 pending]                                             ║
╚══════════════════════════════════════════════════════════════════╝
Error Message Design
Bash

# Error messages follow ASH standard format:
# [ERROR] component: message
# └── Suggestion: how to fix

# Example errors your feature should produce:

[ERROR] ash [command]: [what went wrong]
└── [Specific actionable suggestion]
└── Run 'ash [command] --help' for usage

[WARN]  ash [command]: [non-fatal issue]
└── Continuing with [fallback behavior]

[INFO]  ash [command]: [informational message]
Waybar Module (if applicable)
jsonc

// custom/ash-[feature]
"custom/ash-[feature]": {
  "exec": "~/.local/share/ash/plugins/.../waybar.sh",
  "interval": 60,
  "format": "{icon} {}",
  "format-icons": {
    "active":   "✨",
    "inactive": "○",
    "error":    "⚠️"
  },
  "tooltip": true,
  "tooltip-format": "{alt}",
  "return-type": "json",
  "on-click": "ash [command] --toggle",
  "on-click-right": "ash [command] --rofi-menu"
}
Rofi Menu (if applicable)
text

╔══════════════════════════════════════════════╗
║  ✨ [Feature Name]                 [search]  ║
╠══════════════════════════════════════════════╣
║  ► [Option 1]                    [kbd hint]  ║
║    [Option 2]                    [kbd hint]  ║
║    [Option 3]                    [kbd hint]  ║
║  ─────────────────────────────────────────   ║
║    [Settings]                    [kbd hint]  ║
║    [Help]                        [kbd hint]  ║
╚══════════════════════════════════════════════╝
Notification Design
Bash

# Success notification:
ash::notification::send \
  "[feature-category]" \
  "✨ [Feature Name]" \
  "[What was accomplished] — [next action hint]" \
  --icon "${ASH_ICONS}/[feature-icon].svg" \
  --urgency normal \
  --expire 5000 \
  --action "Open" "ash [command] status"

# Error notification:
ash::notification::send \
  "[feature-category]" \
  "⚠️ [Feature Name] Error" \
  "[What failed]: [brief reason]" \
  --urgency critical \
  --action "Fix" "ash doctor --fix [component]"
📋 SECTION 05 — ACCEPTANCE CRITERIA
<!-- Define EXACTLY what "done" looks like. Each criterion should be independently verifiable. -->
Functional Requirements
 ✅ AC-01: ash [command] create --name X creates a new [thing] named X
Verified by: ash [command] list | grep X
 ✅ AC-02: [Feature] persists across system restarts
Verified by: Reboot test + ash [command] list
 ✅ AC-03: [Feature] respects ASH's mode system
Verified by: ash mode game disables [feature] appropriately
 ✅ AC-04: [Feature] integrates with ASH analytics
Verified by: ash analytics dashboard shows [feature] metrics
 ✅ AC-05: [Feature] triggers ASH hooks at correct lifecycle points
Verified by: Hook integration test passing
 ✅ AC-06: ash [command] --json outputs valid JSON (for scripting)
Verified by: ash [command] list --json | jq '.' exits 0
 ✅ AC-07: ash [command] --help shows accurate documentation
Verified by: Manual review of help text
Non-Functional Requirements
 ⚡ NFR-01: ash [command] responds in < Xms (measured: Yms) ✅
 💾 NFR-02: Feature uses < XMB RAM at idle (measured: YMB) ✅
 ♿ NFR-03: All UI elements have proper accessibility labels ✅
 🌍 NFR-04: All user-visible strings are i18n-ready ✅
 🔒 NFR-05: Feature passes all security checks ✅
 🧪 NFR-06: Test coverage ≥ 80% for new code ✅
Edge Cases Handled
Edge Case	Expected Behavior	Tested?
[Feature] called with no arguments	Shows help text, exit 0	<!-- ✅/❌ -->
[Feature] called when already active	Idempotent or clear error	<!-- ✅/❌ -->
Invalid argument type provided	Clear error + suggestion	<!-- ✅/❌ -->
Network unavailable (if network feature)	Graceful offline mode	<!-- ✅/❌ -->
Disk full	Clear error, no corruption	<!-- ✅/❌ -->
Permission denied	Clear error + ash doctor link	<!-- ✅/❌ -->
Interrupted mid-execution (Ctrl+C)	Clean state, no corruption	<!-- ✅/❌ -->
Concurrent invocation	Safe locking or queuing	<!-- ✅/❌ -->
Unicode in arguments	Handled correctly	<!-- ✅/❌ -->
Very long argument values	Truncated/rejected gracefully	<!-- ✅/❌ -->
🚀 SECTION 06 — FEATURE FLAG & ROLLOUT
<!-- Feature flags allow safe deployment of incomplete or risky features. All major features MUST use a feature flag for initial rollout. -->
Feature Flag Configuration
Bash

# Feature flag in ASH config:
ash config set feature.[feature-name].enabled true    # Enable
ash config set feature.[feature-name].enabled false   # Disable (default)

# Runtime check in code:
if ! ash::feature::enabled "[feature-name]"; then
  ash::log "debug" "Feature '[feature-name]' is disabled — skipping"
  return 0
fi

# Flag location: ~/.config/ash/ash.conf
# Default: false (opt-in during beta, true after stable release)
Rollout Strategy
text

Phase 1: Beta (Week 1-2)
  ├── Flag: feature.[name].enabled = false (default)
  ├── Enable via: ash config set feature.[name].enabled true
  ├── Audience: Opt-in users who want to test
  ├── Monitoring: Discord feedback + GitHub issues
  └── Success criteria: < 5 bug reports, positive feedback

Phase 2: Soft Launch (Week 3-4)
  ├── Flag: feature.[name].enabled = false (default)
  ├── Enable via: ash update --enable-features [name]
  ├── Audience: Users who run --enable-features
  ├── Monitoring: Analytics dashboard + issue tracker
  └── Success criteria: No regressions, performance within budget

Phase 3: General Availability (Week 5+)
  ├── Flag: feature.[name].enabled = true (default)
  ├── Action: Default flip in next minor release
  ├── Audience: All users on next update
  └── Success criteria: Normal issue rate, positive reception

Phase 4: Flag Removal (2 releases later)
  └── Remove the flag entirely — feature is permanent
Canary Testing Plan
Bash

# CI canary test — runs on every PR to main:
# tests/canary/test-[feature].sh

# Load tests the feature under realistic conditions:
# 1. Enable feature
# 2. Run typical user workflow
# 3. Measure performance
# 4. Disable feature
# 5. Verify system returns to baseline state
🧪 SECTION 07 — COMPREHENSIVE TESTING
Test Coverage Map
text

Feature: [Feature Name]
Coverage target: ≥ 80% (measured: X%)

tests/
├── unit/
│   └── test-[feature].sh            ← Core logic unit tests
│       ├── test_create_basic()       ✅ Written
│       ├── test_create_duplicate()   ✅ Written
│       ├── test_create_invalid()     ✅ Written
│       ├── test_list_empty()         ✅ Written
│       ├── test_list_populated()     ✅ Written
│       ├── test_delete_existing()    ✅ Written
│       ├── test_delete_missing()     ✅ Written
│       ├── test_persistence()        ✅ Written
│       └── test_json_output()        ✅ Written
│
├── integration/
│   └── test-[feature]-workflow.sh   ← End-to-end workflow
│       ├── test_full_lifecycle()     ✅ Written
│       ├── test_mode_integration()   ✅ Written
│       ├── test_hook_integration()   ✅ Written
│       └── test_analytics_track()   ✅ Written
│
├── e2e/
│   └── test-[feature]-e2e.sh        ← Desktop session test
│       └── test_desktop_behavior()  ✅ Written
│
└── benchmark/
    └── bench-[feature].sh           ← Performance tests
        ├── bench_create_time()      ✅ Written
        └── bench_list_time()        ✅ Written
Test Results
Bash

$ bash tests/run-all-tests.sh --suite [feature]

🧪 ASH [Feature Name] — Full Test Suite
════════════════════════════════════════════════════════

Unit Tests (tests/unit/test-[feature].sh):
  ✅ test_create_basic          (12ms)
  ✅ test_create_duplicate      (8ms)
  ✅ test_create_invalid        (9ms)
  ✅ test_list_empty            (5ms)
  ✅ test_list_populated        (11ms)
  ✅ test_delete_existing       (7ms)
  ✅ test_delete_missing        (6ms)
  ✅ test_persistence           (45ms)
  ✅ test_json_output           (8ms)

Integration Tests:
  ✅ test_full_lifecycle        (287ms)
  ✅ test_mode_integration      (312ms)
  ✅ test_hook_integration      (198ms)
  ✅ test_analytics_track       (89ms)

Edge Case Tests:
  ✅ test_no_args_shows_help    (12ms)
  ✅ test_ctrl_c_clean_exit     (95ms)
  ✅ test_concurrent_safe       (156ms)
  ✅ test_unicode_args          (14ms)

Performance Benchmarks:
  ✅ bench_create: 43ms (SLA: <100ms) 🟢
  ✅ bench_list:   12ms (SLA: <50ms)  🟢

════════════════════════════════════════════════════════
Results: XX/XX tests PASSED ✅
Coverage: X% (target: ≥80%) ✅
⚡ SECTION 08 — PERFORMANCE BUDGET
<!-- Every feature has a performance budget. Stay within it. Budget violations require explicit maintainer approval. -->
Performance Budget
text

Feature Performance Budget:
╔══════════════════════════════════════════════════════════════╗
║  OPERATION              BUDGET        MEASURED    STATUS     ║
╠══════════════════════════════════════════════════════════════╣
║  Primary command        < 100ms       Xms         ✅ / ❌   ║
║  List/status command    < 50ms        Xms         ✅ / ❌   ║
║  Background work        < 2% CPU avg  X%          ✅ / ❌   ║
║  Memory footprint       < 25MB        XMB         ✅ / ❌   ║
║  Disk writes per op     < 10MB        XMB         ✅ / ❌   ║
╠══════════════════════════════════════════════════════════════╣
║  ASH STARTUP OVERHEAD:  +0ms          +Xms        ✅ / ❌   ║
║  FISH STARTUP OVERHEAD: +5ms max      +Xms        ✅ / ❌   ║
╚══════════════════════════════════════════════════════════════╝
Benchmark Comparison (main vs this PR)
Bash

$ ash benchmark --compare main..HEAD --suite [feature]

Comparing: main (abc1234) → feature/[name] (def5678)

METRIC                    MAIN        THIS PR     DELTA
──────────────────────────────────────────────────────────
ash startup time          87ms        89ms        +2ms ✅ (< 10ms budget)
theme apply time          1.23s       1.24s       +10ms ✅ (< 50ms budget)
fish shell startup        42ms        43ms        +1ms ✅ (< 5ms budget)
total memory (Waybar)     145MB       147MB       +2MB ✅ (< 10MB budget)

Overall: 🟢 All within performance budget
🔒 SECTION 09 — SECURITY & PRIVACY REVIEW
Security Impact Assessment
Security Domain	Impact	Mitigation
Input validation	[New attack surface?]	[How inputs are validated]
File system	[New paths accessed?]	[Bounded to permitted dirs]
Network	[New endpoints?]	[Disclosed + encrypted]
Authentication	[Changes to auth?]	[No weakening]
Secrets	[Handles credentials?]	[ash::secrets::* only]
Privilege	[Needs elevation?]	[No / justified]
Privacy Impact Assessment
Data Category	Collected?	Stored Where?	Retention	User Control
User content	<!-- Yes/No -->	<!-- Location -->	<!-- Duration -->	<!-- How to delete -->
Usage patterns	<!-- Yes/No -->	<!-- Location -->	<!-- Duration -->	<!-- Opt-out cmd -->
System info	<!-- Yes/No -->	<!-- Location -->	<!-- Duration -->	<!-- How to view -->
Network traffic	<!-- Yes/No -->	<!-- None/Local -->	<!-- N/A -->	<!-- N/A -->
Security Checklist
 🔍 Threat-modeled the new attack surface
 💉 All user inputs validated with type + range + format checks
 📁 File paths canonicalized and bounded to permitted directories
 🔑 No new sudo requirements
 🌐 All network calls documented + encrypted
 📝 No sensitive data in logs
 🧹 Temp files use mktemp + cleanup traps
 🚫 No eval or dynamic execution of external input
♿ SECTION 10 — ACCESSIBILITY AUDIT
<!-- ASH Dotfiles must be usable by everyone. This is non-negotiable. Complete for any feature with visual output. -->
Terminal Accessibility
Requirement	Implementation	Status
Color is not sole differentiator	Icons + text also used	<!-- ✅/❌ -->
Error messages are descriptive	Not just "Error" — explains what + how to fix	<!-- ✅/❌ -->
Progress is communicated textually	Not just spinner animation	<!-- ✅/❌ -->
Output is screen-reader compatible	No cursor tricks or ANSI abuse	<!-- ✅/❌ -->
--no-color flag respected	Works with monochrome output	<!-- ✅/❌ -->
--quiet flag respected	Minimal output when requested	<!-- ✅/❌ -->
Visual Accessibility (Desktop UI elements)
WCAG Criterion	Requirement	Status
1.4.3 Contrast (AA)	≥ 4.5:1 for text	<!-- ✅/❌/N/A -->
1.4.1 Use of Color	Not color-only	<!-- ✅/❌/N/A -->
2.1.1 Keyboard	Full keyboard access	<!-- ✅/❌/N/A -->
2.4.3 Focus Order	Logical focus order	<!-- ✅/❌/N/A -->
4.1.2 Name/Role/Value	ARIA or equivalent	<!-- ✅/❌/N/A -->
Motor Accessibility
 🎹 Feature fully operable via keyboard (no mouse required)
 ⌨️ Default keybinds are comfortable / not conflict-prone
 🔄 Alternative input methods work (voice control, switch access)
 ⏱️ No time-sensitive interactions that could fail for slow users
📖 SECTION 11 — DOCUMENTATION DELIVERABLES
Documentation Produced
<table> <tr> <th>Document</th> <th>Status</th> <th>Location</th> <th>Approx. Words</th> </tr> <tr> <td>User Guide</td> <td><!-- ✅ Complete / 🔄 Draft / 🔜 Planned --></td> <td><code>docs/guides/[feature]-guide.md</code></td> <td><!-- ~XXX words --></td> </tr> <tr> <td>CLI Reference</td> <td><!-- ✅ Complete / 🔄 Draft / 🔜 Planned --></td> <td><code>docs/reference/ash-cli-reference.md</code></td> <td><!-- ~XXX words --></td> </tr> <tr> <td>Configuration Ref</td> <td><!-- ✅ Complete / 🔄 Draft / 🔜 Planned --></td> <td><code>docs/reference/config-reference.md</code></td> <td><!-- ~XXX words --></td> </tr> <tr> <td>--help text</td> <td><!-- ✅ Complete --></td> <td><code>ash-cli/commands/[cmd]/[cmd].sh</code></td> <td><!-- inline --></td> </tr> <tr> <td>CHANGELOG entry</td> <td><!-- ✅ Complete --></td> <td><code>CHANGELOG.md</code></td> <td><!-- ~50 words --></td> </tr> <tr> <td>Fish completions</td> <td><!-- ✅ Complete / N/A --></td> <td><code>config/fish/completions/</code></td> <td><!-- N/A --></td> </tr> </table>
Documentation Preview
<details> <summary>📖 User Guide Preview (click to expand)</summary>
Markdown

# [Feature Name] Guide

## Overview
[What this feature does and when to use it]

## Prerequisites
- ASH Dotfiles v5.X.0 or later
- [Other prerequisites]

## Quick Start
```bash
# Enable the feature (if behind a flag):
ash config set feature.[name].enabled true

# Basic usage:
ash [command] [subcommand]

# Verify it's working:
ash [command] status
Configuration
Option	Default	Description
[option]	[default]	[Description]
Examples
[Practical examples covering common use cases]

Troubleshooting
Problem	Solution
[Common issue 1]	[Fix 1]
text


</details>

---

## ✅ SECTION 12 — FEATURE PR CHECKLIST

### Design & Architecture
- [ ] 🏗️ Design reviewed or discussed in linked issue/RFC
- [ ] 🎯 Feature is appropriately scoped (not too broad, not too narrow)
- [ ] 🔌 Integrates with ASH mode system, hooks, and analytics where appropriate
- [ ] 🏁 Feature flag implemented for gradual rollout
- [ ] ♻️ Code is modular and follows ASH conventions
- [ ] 📐 Architecture consistent with existing ASH patterns

### Implementation Quality
- [ ] ✨ All acceptance criteria met and verified
- [ ] 🎨 UI/UX follows ASH design language (output format, colors, icons)
- [ ] ♿ Accessibility requirements implemented and verified
- [ ] 🌍 User-visible strings are i18n-ready
- [ ] 📏 No function exceeds 50 lines (refactor if needed)
- [ ] 💬 Complex logic has clear inline comments
- [ ] 🧹 No dead code, unused variables, or debug artifacts

### Testing & Quality
- [ ] 🧪 Test coverage ≥ 80% for all new code
- [ ] 🔄 All edge cases from acceptance criteria tested
- [ ] ⚡ Performance within budget (benchmarks attached)
- [ ] 🔒 Security audit complete (all items checked above)
- [ ] 🐧 Tested on at least Arch Linux + one other distro

### Documentation & Release
- [ ] 📖 User guide written and included in this PR
- [ ] 📋 CLI --help text accurate and complete
- [ ] 📝 CHANGELOG.md updated with user-facing description
- [ ] 🏷️ Feature flag defaults to `false` (opt-in for initial release)
- [ ] 🗺️ Rollout strategy documented above
- [ ] 📣 Ready for Discord announcement after merge

---

<div align="center">

---

### ✨ Feature PR Review Timeline
PR Open → Design Review → Code Review → QA → Approval → Merge → Release
now 1-2 days 3-5 days 1-2d instant auto next ver

text


| Review Stage | Reviewer | Focus |
|-------------|----------|-------|
| Design Review | Lead architect | Architecture, scope, consistency |
| Code Review | Domain expert | Implementation correctness |
| Security Review | Security team | Threat model, input validation |
| UX Review | UX contributor | Usability, accessibility |
| Final Approval | Senior maintainer | Overall quality gate |

**Thank you for building ASH Dotfiles!** ✨

*— The ASH Dotfiles Feature Review Team* ✨

</div>
