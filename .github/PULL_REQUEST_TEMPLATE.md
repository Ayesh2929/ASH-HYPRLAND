## 📋 Description
<!-- What does this PR do? Be specific. -->

## 🔗 Related Issues
<!-- Closes #NNN | Fixes #NNN | Related to #NNN -->

## 🧪 How I Tested This
<!-- Describe how you tested these changes -->

- [ ] Ran `ash reload` after changes
- [ ] Ran `ash doctor` — all checks pass
- [ ] Tested on real hardware
- [ ] Tested the specific component changed

## 📸 Screenshots/Demo
<!-- For visual changes, add Before/After screenshots -->

| Before | After |
|--------|-------|
| | |

## 📝 Type of Change
<!-- Check all that apply -->

- [ ] 🐛 Bug fix (`fix:`)
- [ ] ✨ New feature (`feat:`)
- [ ] 🌟 New unique feature
- [ ] 📚 Documentation (`docs:`)
- [ ] ⚡ Performance improvement (`perf:`)
- [ ] 🔧 Refactoring (`refactor:`)
- [ ] 🎨 Style/formatting (`style:`)
- [ ] 🔒 Security fix
- [ ] 🤖 CI/CD changes (`ci:`)

## 🎯 Component Affected
<!-- Which part of ASH does this affect? -->

- [ ] Theme Engine / Wallpaper
- [ ] Waybar
- [ ] Rofi
- [ ] Fish Shell
- [ ] Neovim
- [ ] Hyprlock / Hypridle
- [ ] Unique Features (music/score/workspace/smart/analytics/ai/context)
- [ ] ASH CLI
- [ ] Documentation
- [ ] CI/CD Pipeline
- [ ] Installation Scripts

## ✅ PR Checklist

### Required
- [ ] PR title follows [Conventional Commits](https://conventionalcommits.org)
- [ ] `UserOverrides/user.conf` NOT committed
- [ ] Generated theme files NOT committed
- [ ] All shell scripts have `set -euo pipefail`
- [ ] No hardcoded paths — use `${HOME}` not `/home/username`
- [ ] `ash doctor` passes locally

### If Adding Scripts
- [ ] Script has proper header comment block
- [ ] Script has logging to `${CACHE_DIR}/logs/`
- [ ] Script has graceful error handling
- [ ] Script has usage help in `*` case
- [ ] Script is executable (`chmod +x`)
- [ ] Script works with Fish shell variables

### If Adding Features
- [ ] Feature has documentation in `docs/`
- [ ] Feature is in the CHANGELOG
- [ ] Feature has proper `ash help` entry
- [ ] Tab completions added to `fish/completions/ash.fish`

### If Modifying Theme Engine
- [ ] All 13+ app generators still work
- [ ] Fallback palette still applies correctly
- [ ] Lock mechanism still in place
- [ ] History save still works

## 📊 Impact Assessment

| Area | Impact | Notes |
|------|--------|-------|
| Performance | Low/Med/High | |
| Breaking Change | Yes/No | |
| New Dependencies | Yes/No | |
| Documentation Needed | Yes/No | |

## 🤝 Contributors
<!-- Co-authors, inspiration, etc. -->