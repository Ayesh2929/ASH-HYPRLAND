# ASH-HYPRLAND — Bug Report

**Scope:** full repository (`Ayesh2929/ASH-HYPRLAND`), commit `762142c`
**Date:** 2026-09-17
**Method:** static analysis + dynamic execution (see [Methodology](#methodology))

Every finding below was **reproduced** — either by executing the code or by a minimal
reproduction of the exact construct. Findings that turned out to be linter artefacts are
listed separately in [False positives](#false-positives--not-bugs) so they don't get "fixed" by mistake.

---

## Executive summary

| # | Severity | Issue | Impact |
|---|----------|-------|--------|
| 1 | 🔴 Critical | Bash **syntax error** in `.husky/pre-push` | Whole pre-push hook is dead |
| 2 | 🔴 Critical | Competing stdin redirects in `crypto.sh` | Encrypt/decrypt processes the **wrong data** |
| 3 | 🔴 Critical | `log::*` namespace undefined (**368 call sites**) | Errors/successes silently lost |
| 4 | 🔴 Critical | `ash_truncate` undefined (26 call sites) | `ash doctor` spews errors, columns break |
| 5 | 🟠 High | 8 more undefined `ash_*` helpers (**92 calls**) | Spinners, rules, centering, plugin hooks dead |
| 6 | 🟠 High | `cmd \| python3 - << HEREDOC` (**3 sites**) | Entire `ash monitor` family crashes |
| 7 | 🟠 High | `${$(( … ))}` in `power.sh:317` | `ash power` snapshot crashes |
| 8 | 🟠 High | `-z` used as arithmetic in `prompt.sh:106` | Required-field validation **never fails** |
| 9 | 🟠 High | `ash_plugin_exec` vs `_ash_plugin_exec` typo | All plugin lifecycle hooks no-op |
| 10 | 🟡 Medium | `${_func}` used as variable (54 sites) | Colour/reset codes silently dropped |
| 11 | 🟡 Medium | `.git-hooks/validate-plugin.sh` `((x++=0))` | Arithmetic error printed on every check |
| 12 | 🟡 Medium | `validate.py` rejects valid JSONC | CI fails on `config/vscode`, `config/zed` |
| 13 | 🟡 Medium | Invalid action `superfly/flyctl-actions@v1.5.1` | Deploy/rollback workflows fail to resolve |
| 14 | 🟡 Medium | `themes/presets/.../colors.json` has no colors | `test / 🎨 Theme Engine Tests` can **never** pass |
| 15 | 🟢 Low | Duplicate function definitions | Buggy copy silently shadowed |
| 16 | 🟢 Low | `tr` + multibyte in score bar | Mojibake under non-UTF-8 locales |

**Clean:** all 46 Python files, all 183 Lua files, all 165 YAML files, and 471/472 JSON
files pass. Only **one** of 769 shell scripts has a genuine syntax error.

---

## Methodology

| Check | Tool / approach | Files | Result |
|-------|-----------------|-------|--------|
| Shell parse | `bash -n` (ground truth) | 769 | **1 real error** |
| Shell lint | ShellCheck 0.8.0 (`--severity=warning`) | 769 | 492 findings |
| Undefined functions | tokeniser + `grep` verification | 769 | **~490 bad call sites** |
| Python syntax | `python3 -m py_compile` | 46 | 0 errors |
| Lua compile | `fengari` (real Lua 5.4 compiler) | 183 | 0 errors |
| YAML parse | `PyYAML` | 165 | 0 errors |
| JSON/JSONC | strict + comment-stripping parser | 472 | 1 (intentional fixture) |
| Action refs | GitHub API (`gh api`) | 81 | **1 invalid** |
| Runtime | executed `ash` CLI subcommands | — | multiple failures |

---

## 🔴 Critical

### 1. Bash syntax error in `.husky/pre-push` — the hook cannot run

**File:** `.husky/pre-push:184` (and the sibling `case` arms at lines 185–188)

```bash
PASS) icon="✓" color="${GREEN}${B}"  label="PASS"  ((CHECKS_PASSED++))  || true ;;
```

`(( … ))` is a *compound command*. It cannot follow another command in the same list
without a `;` or newline separator — bash parses `label="PASS" ((CHECKS_PASSED++))` as an
assignment followed by an unexpected `(`.

**Evidence**

```
$ bash -n .husky/pre-push
.husky/pre-push: line 184: syntax error near unexpected token `('
```

This is a **parse-time** error, so the *entire file* fails to execute. Out of all 769
shell scripts in the repo, this is the **only** genuine syntax error — every other file
parses cleanly.

**Impact:** the pre-push guard (tests, secret scan, size checks, branch policy) never runs.
Depending on how git invokes it, pushes either break outright or all validation is skipped.

**Fix** — add a separator (repeat for the `FAIL`/`WARN`/`SKIP` arms):

```bash
PASS) icon="✓" color="${GREEN}${B}"  label="PASS";  ((CHECKS_PASSED++))  || true ;;
```

> Note: `.husky/pre-push` and `post-merge` are mode `0755`, but `commit-msg` and
> `pre-commit` are `0644` (not executable) — git will skip non-executable hooks.
> `core.hooksPath` is also unset, so hook installation depends entirely on Husky.

---

### 2. Competing stdin redirections in `crypto.sh` — wrong data is encrypted

**File:** `ash-cli/lib/crypto.sh:270, 277, 365, 366`

```bash
# line 270 — encrypt
age -p -e -a < "$in" > "$out" 2>/dev/null <<< "$(cat "$passfile")" || \
    { rc=1; }

# line 277 — encrypt (fifo fallback)
age -p -e -a < "$in" > "$out" < "$fifo" 2>/dev/null || rc=1

# lines 365/366 — decrypt
age -d -i /dev/null < "$in" > "$target" < "$fifo" 2>/dev/null || \
    age -d < "$in" > "$target" < "$fifo" 2>/dev/null || rc=1
```

Bash applies redirections **left to right**, and the last one wins. Each of these lines
redirects stdin twice, so `age` never receives `"$in"` — it receives the passphrase (or
the FIFO) instead.

**Evidence**

```
$ printf 'FILE_CONTENT\n' > file.txt; printf 'PASSPHRASE\n' > pass.txt
$ cat < file.txt <<< "$(cat pass.txt)"
PASSPHRASE
$ cat < file.txt < pass.txt
PASSPHRASE
```

**Impact:** the age backend encrypts the *passphrase text* rather than the user's file.
The output is not a valid encryption of the input, and decryption yields the passphrase —
**silent data loss** if the user deletes the original after "encrypting" it.
The `<<<` variant also can't work by design: `age -p` reads the passphrase from the
controlling TTY, not stdin (the code comment on line 271 even acknowledges this).

ShellCheck agrees: 8 × `SC2261` (severity *error*) in this file.

**Fix:** pass the input as a filename and let `age` read it directly, e.g.
`age -p -e -a -o "$out" "$in"`, and supply the passphrase via `AGE_PASSPHRASE`/`--passphrase-file`
(or `expect`) rather than stdin.

---

### 3. The entire `log::*` namespace is undefined — 368 call sites

**Files:** 35 files call `log::*`; nothing defines it at runtime.

| Function | Call sites | Defined? |
|----------|-----------|----------|
| `log::blank` | 95 | ❌ never defined anywhere |
| `log::success` | 32 | ❌ never defined anywhere |
| `log::section` | 12 | ❌ never defined anywhere |
| `log::error` / `info` / `warn` / `debug` / `die` / `ok` / `step` | 229 | ⚠️ only in an unsourced template |

The only definitions live in **`config/nvim/templates/bash.sh:77–103`** — a Neovim snippet
that is *never sourced* by the CLI:

```
$ grep -rn 'nvim/templates/bash.sh' --include='*.sh' .
(no output)
```

The CLI's real logger is `ash-cli/lib/logger.sh`, which exposes a **different API**:
`ash_log_error`, `ash_log_info`, `ash_log_success`, `ash_log_section`, … (82 files use it).

**Evidence (runtime)**

```
$ bash ash-cli/ash snapshot list
…/snapshot/list.sh: line 192: log::blank: command not found
…/snapshot/list.sh: line 194: log::blank: command not found
…/snapshot/list.sh: line 197: log::blank: command not found

$ bash ash-cli/ash config get
…/config/get.sh: line 82: log::error: command not found
USAGE
  ash config get <key> [options]
```

`log::error` is *also* undefined at runtime, so error and success messages are swallowed —
the user sees a bare `USAGE` block with no explanation. Some call sites add `2>/dev/null`,
hiding it further.

**Fix:** define the missing `log::*` shims (delegating to `ash_log_*`), or rename the 368
call sites to the existing `ash_log_*` API.

---

### 4. `ash_truncate` is called 26 times but never defined

```
$ grep -rn "ash_truncate()" --include='*.sh' .
(no output)
$ grep -rc "ash_truncate" --include='*.sh' -r . | grep -v ':0' | wc -l
…26 call sites
```

**Evidence (runtime)**

```
$ bash ash-cli/ash doctor
…/doctor/doctor.sh: line 330: ash_truncate: command not found
…/doctor/doctor.sh: line 330: ash_truncate: command not found   ← repeated per check
```

**Impact:** every affected row renders with an empty label column, so the health report is
misaligned and unreadable. Affects `ash doctor`, `doctor full/quick/fix`,
`config list/validate/import`, `snapshot clean/diff/history` and
`doctor/checks/check-system.sh`.

The intended implementation clearly exists under another name —
`ash_table_truncate` in `ash-cli/lib/table-renderer.sh:102` (signature
`(string, max_len, ellipsis?)`, matching these `ash_truncate "$str" 50` calls).

---

## 🟠 High

### 5. Eight further undefined `ash_*` helpers (92 call sites)

All verified `defs=0`:

| Function | Calls | Example location |
|----------|-------|------------------|
| `ash_spinner_stop` | 30 | `ash-cli/commands/config/import.sh:149` |
| `ash_hr` | 24 | `ash-cli/commands/config/import.sh:190` |
| `ash_spinner_start` | 21 | `ash-cli/commands/config/import.sh:147` |
| `ash_die` | 6 | `ash-cli/commands/mode/create.sh:259` |
| `ash_center` | 4 | `ash-cli/commands/snapshot/history.sh:278` |
| `ash_progress` | 4 | `ash-cli/commands/doctor/full.sh:684` |
| `ash_print_info` / `ash_print_error` / `ash_mode_status_brief` | 3 | `ash-cli/commands/mode/mode.sh:564` |

Runtime confirmation:

```
$ bash ash-cli/ash snapshot list
…/snapshot/list.sh: line 193: ash_center: command not found
```

Additionally, `ash-cli/commands/mode/mode.sh` calls **15 `ash_*_set_*` /
`ash_*_prepare` helpers that don't exist** (lines 731–858), e.g.
`ash_pipewire_noise_cancel`, `ash_dunst_set_timeout`, `ash_display_set_gamma`,
`ash_waybar_set_layout`, `ash_fish_set_theme`, `ash_cursor_set_theme`,
`ash_font_set_scale`, `ash_keyboard_set_repeat`, `ash_vpn_connect`,
`ash_vpn_disconnect`, `ash_firewall_set`, `ash_cliphist_set_enabled`,
`ash_screenrecord_prepare`, `ash_hypridle_set_timeout`,
`ash_hypridle_set_lock_timeout` — i.e. large parts of the **desktop-mode apply path**.

---

### 6. `cmd | python3 - << HEREDOC` — the pipe is discarded, entire `ash monitor` family crashes

**Files:** `ash-cli/commands/monitor/refresh_rate.sh:22`,
`ash-cli/commands/monitor/extend.sh:16`, `ash-cli/commands/monitor/monitor.sh:323`

```bash
hyprctl monitors -j 2>/dev/null | python3 - << PYEOF
import json, sys
mons = json.load(sys.stdin)      # ← expects the piped JSON
…
PYEOF
```

`python3 -` reads its **program from stdin**, and `<< PYEOF` *also* redirects stdin — so the
heredoc wins and the piped `hyprctl` output is thrown away. The script then reads nothing.

**Evidence (minimal reproduction of the exact construct)**

```
$ cat mons.json | python3 - << 'PYEOF'
import json, sys
mons = json.load(sys.stdin)
print("parsed OK:", mons)
PYEOF
Traceback (most recent call last):
  File "<stdin>", line 2, in <module>
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
exit=1
```

**Impact:** `ash monitor refresh-rate`, `ash monitor extend` and the monitor-layout writer in
`monitor.sh` all abort with a Python traceback and produce no output. ShellCheck flags these
as `SC2259` (severity *error*).

**Fix:** pass the JSON as a file argument instead of a pipe
(`hyprctl monitors -j > "$tmp" && python3 script.py "$tmp"`), or feed the program with
`python3 -c '…'`.

---

### 7. `${$(( … ))}` — invalid parameter expansion crashes `ash power`

**File:** `ash-cli/commands/power/power.sh:317`

```bash
pwr_kv "Memory" "${mem_pct}%  ($(( mem_used / 1024 ))/${$(( mem_total / 1024 ))}MB)"
```

`${$( … )}` is not valid expansion syntax.

**Evidence**

```
$ bash -n power.sh      → SYNTAX OK      (bash -n cannot catch this)
$ bash power.sh
line 5: ${mem_pct}%  ($(( mem_used / 1024 ))/${$(( mem_total / 1024 ))}MB): bad substitution
exit=1
```

Note this is a **runtime-only** failure: it passes `bash -n`, so it is invisible to syntax
checking and only catches shellcheck (`SC2082`).

**Fix:** `${$(( mem_total / 1024 ))}` → `$(( mem_total / 1024 ))`.

---

### 8. `-z` inside arithmetic — required-field validation never fails

**File:** `ash-cli/lib/prompt.sh:106`

```bash
if ! _ash_prompt_interactive; then
    printf '%s' "$default"
    return $(( required == 1 && -z "$default" ? 1 : 0 ))
fi
```

`-z` is a *test* operator, not arithmetic. Bash parses `-z` as unary minus applied to the
variable `z` (unset → `0`), so the condition is always false and the function always
returns 0.

**Evidence**

```
$ required=1; default=""; echo $(( required == 1 && -z "$default" ? 1 : 0 ))
0
```

Expected `1` (validation failure). In non-interactive mode `--required` with an empty
default **silently succeeds**. ShellCheck flags it as `SC2284` + `SC1102`.

**Fix:** `if (( required == 1 )) && [[ -z "$default" ]]; then return 1; fi; return 0`

---

### 9. `ash_plugin_exec` ≠ `_ash_plugin_exec` — plugin hooks never run

**File:** `ash-cli/lib/plugin-loader.sh`

```bash
207: _ash_plugin_exec() {                        # ← defined WITH underscore
258:     ash_plugin_exec "$name" "init.sh"    2>/dev/null || rc=$?
277:     ash_plugin_exec "$name" "enable.sh"  2>/dev/null || rc=$?
301:     ash_plugin_exec "$name" "disable.sh" 2>/dev/null || rc=$?
```

A one-character typo (missing leading `_`), and `2>/dev/null` hides the
`command not found` error. **Every plugin `init.sh` / `enable.sh` / `disable.sh` hook is a
silent no-op.**

---

## 🟡 Medium

### 10. `${_func}` used as a variable where functions are defined — 54 sites

The TUI colour helpers are **shell functions**, not variables:

```bash
# ash-cli/commands/net/vpn.sh:36–47
_vr()     { _v '\033[0m'; }
_vgreen() { _v '\033[38;2;166;227;161m'; }
```

but 54 places expand them as *variables*, e.g. `ash-cli/commands/net/vpn.sh:130`:

```bash
marker="${_vgreen}●  (active)${_vr}"     # ← expands unset vars → empty strings
```

The correct form is used **2208 times** as `$(_vgreen)`, so the intent is unambiguous.
`${_vgreen}` expands to nothing, so colour and reset codes are silently dropped (unstyled
text, and terminal colour state not reset).

Most affected: `bar/switch.sh` (`${_br}` ×6), `net/ports.sh` (`${_pr}` ×3),
`net/vpn.sh`, `net/monitor.sh`, `theme/theme.sh`, `audio/volume.sh`,
`audio/audio.sh`, `wallpaper/history.sh`, `shot/timer.sh`, `monitor/resolution.sh`.

> This is also the **root cause** of most of the 50 ShellCheck `SC2154`
> "referenced but not assigned" warnings — they are missing *function calls*, not missing
> variables. The other 13 are nameref false positives (see below).

### 11. `((CHECKS_TOTAL++=0))` — arithmetic error on every check

**File:** `.git-hooks/validate-plugin.sh:173`

```bash
((MAX_SCORE += points)) || true; ((CHECKS_TOTAL++=0)) || true
```

**Evidence**

```
$ x=5; ((x++=0)); echo $x
bash: ((: x++=0: attempted assignment to non-variable (error token is "=0")
6
```

The `|| true` keeps the script alive, but an error line is printed on **every** `check()`
call. (The counter does still increment, so scores aren't wrong — it's error spam plus a
clear typo.) Intended: `((CHECKS_TOTAL++))`.

### 12. `validate.py` rejects valid JSONC → CI red

`validate.py` uses `json.load()`, but VS Code and Zed configs legitimately allow `//`
comments. All five failures are comment-only:

```
$ python3 validate.py
  ❌ Invalid JSON in config/vscode/keybindings.json
  ❌ Invalid JSON in config/vscode/settings.json
  ❌ Invalid JSON in config/zed/keymap.json
  ❌ Invalid JSON in config/zed/settings.json
  ❌ Invalid JSON in config/zed/themes/ash-dynamic.json
  Errors: 5            → exit 1
```

Verified with a comment-stripping parser: **all five are valid JSONC**; the only genuinely
malformed file in the repo is `tests/fixtures/malformed-json.json` (an intentional fixture,
which the script does *not* report because it only scans `config/`).

**Fix:** parse with a JSONC-aware strip, or skip files with a `//` header / add them to an
ignore list. As written, the validator reports **5 false errors and misses the 1 real one**.

### 13. Invalid GitHub Action reference

**Files:** `.github/workflows/_reusable-deploy.yml:87`, `.github/workflows/_reusable-rollback.yml:78`

```yaml
- uses: superfly/flyctl-actions/setup-flyctl@v1.5.1
```

Verified against the GitHub API — that tag does not exist:

```
tags: v1.4, v1, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 1
$ gh api repos/superfly/flyctl-actions/git/ref/tags/v1.5.1  → 404
```

The step fails with *"Unable to resolve action"*, breaking **deploy and rollback**.

I checked all **81** distinct action refs: every other one resolves (several are branches,
e.g. `marocchino/sticky-pull-request-comment@v2`/`@v3` — valid).

> Related inconsistency (not a bug): `actions/checkout@v7` ×305 vs `@v4` ×27;
> `upload-artifact@v6`/`@v7`/`@v4`; `setup-node@v7`/`@v4`. Worth pinning to one major each.

> `ash-cli/commands/power/logout.sh:38` has `2>/dev/null … 2>/dev/null` (SC2261). Both point
> at `/dev/null`, so this one is **harmless** — just redundant.

---

### 14. The only theme preset has no colour data — its CI job can never pass

**File:** `themes/presets/dark/catppuccin-mocha/colors.json`

```json
{
  "name": "colors.json",
  "version": "5.0.0-omega",
  "description": "ASH Dotfiles OMEGA component: colors.json",
  "status": "ready"
}
```

The file is a metadata stub — it contains **no colour values at all**. It is also the
**only** `colors.json` in the repository:

```
$ find themes -name "colors.json" | wc -l
1
```

The CI job `test-theme-engine` (`.github/workflows/_reusable-test.yml:50`) requires
`background`, `foreground` and `accent` and then `exit 1`s on any error:

```
❌ catppuccin-mocha: Missing required key 'background'
❌ catppuccin-mocha: Missing required key 'foreground'
❌ catppuccin-mocha: Missing required key 'accent'
Tested 1 themes, 3 errors      → exit 1
```

**Impact:** `test / 🎨 Theme Engine Tests` is **permanently red** — it cannot pass on any
commit, and because it's the only data file it scans, the check carries no signal. Verified
present on `main` at `762142c` as well (unrelated to any docs change).

**Fix:** populate real `background` / `foreground` / `accent` values, or point the job at
the actual theme colour schema (`themes/**/theme.json` etc.) and drop the stub. The job also
pins `actions/checkout@v4` / `actions/setup-python@v4` while the rest of the repo is on
`@v7`.

---

## 🟢 Low

### 15. Duplicate function definitions (later silently shadows earlier)

| File | Line | Function |
|------|------|----------|
| `.git-hooks/validate-plugin.sh` | 156 & 163 | `section` |
| `.github/actions/benchmark-runner/run-benchmarks.sh` | 438 & 1251 | `print` |

The **first** `section()` in `validate-plugin.sh` is buggy — it prints the header twice and
uses `$2` where `$3` was intended:

```bash
section() {
    printf "\n" >&2; hr "${D}${SLATE}"; \
    printf "  %s %s%s%s\n" "$1" "${2:-$CYAN}${B}" "$2" "$R" >&2
    # shellcheck disable=SC2086
    printf "  %s %s%s%s\n" "$1" "${3:-$CYAN}${B}" "$2" "$R" >&2   # duplicate + wrong var
    hr "${D}${SLATE}"; }
```

It is dead code today, but it will resurface if the (correct) second definition is ever
removed.

### 16. `tr` + multibyte in the health score bar

**File:** `ash-cli/commands/doctor/doctor.sh:168` (`doc::score_bar`)

```bash
printf '%*s' "${filled}" '' | tr ' ' '█'
```

`tr` is byte-oriented in this coreutils build: it emits only the first byte of `█`
(`0xE2`) for each space, producing invalid UTF-8.

```
$ printf '%*s' 5 '' | tr ' ' '█' | od -An -tx1
 e2 e2 e2 e2 e2          # not e2 96 88 …
```

Observed live — `ash doctor` prints `Health Score  D  55/100  ������������`.
This is locale/coreutils-dependent (some builds handle the multibyte set correctly), so it
is worth making robust:
`printf '█%.0s' $(seq 1 "$filled")` or `awk`.

---

## Companion report: missing files

A separate pass looked for **files that are referenced but do not exist**. Findings are in
[`MISSING_FILES.md`](MISSING_FILES.md): **93 missing referenced files** (68 of them
`config/swaync/scripts/`), **47 present-but-empty JSON stubs**, and 9 files shipped with the
wrong mode. Headline items:

- `config/hypr/render.conf` — the only one of 34 Hyprland `source =` targets that is absent.
- `config/waybar/scripts/do-not-disturb.sh` — runs on a 5-second interval.
- `themes/schema/*.json`, `plugins/schema/plugin-schema.json` — empty stubs, so schema
  validation is a silent no-op.
- `.local/bin/*` — all nine tracked non-executable (`100644`).

---

## False positives — *not* bugs

These were flagged by tooling but are correct code. **Do not "fix" them.**

| Reported | Reality |
|----------|---------|
| `ash-cli/lib/template-engine.sh:104` `SC1073/SC1020` — "Couldn't parse" | `[[ "$line" == \[*\] ]]` is **valid bash** and works (`bash -n` passes; verified it matches `[section]`). ShellCheck 0.8.0 parser limitation. |
| `ash-cli/lib/prompt.sh:106` `SC2284` — "Use [ x = y ]" | Misleading message; the *real* bug there is #8, not a test-expression syntax problem. |
| `config/mpv/scripts/quality-menu.lua`, `config/nvim/.../lspconfig.lua` — "`continue` keyword" | These use `goto continue` + `::continue::` (Lua 5.2+, and the label is the last statement of the block). **Compiles clean** under a real Lua VM. |
| `monitor/list.sh` `print()` ×3, `run-benchmarks.sh` `print()` | Matches inside **embedded Python heredocs**, not bash functions. |
| `engines/color-engine/material-you.sh` — 13 × `SC2154` ("`base` is referenced but not assigned") | `_out` is a **nameref** (`local -n _out="$1"`, line 64/86) bound to a caller's *associative* array, so `_out[base]=…` uses the literal key `"base"`. ShellCheck cannot resolve nameref types and assumes an indexed array (arithmetic subscript). **Correct as written.** |

---

## What is clean ✅

- **Python** — all 46 files compile (`py_compile`).
- **Lua** — all 183 files compile with a real Lua 5.4 compiler (`fengari`), 0 errors.
- **YAML** — all 165 `.yml`/`.yaml` files parse (`PyYAML`), 0 errors.
- **JSON** — 471/472 valid; the exception is the deliberate `tests/fixtures/malformed-json.json`.
- **Shell syntax** — only `.husky/pre-push` fails among 769 scripts.

### ShellCheck breakdown (492 findings, 769 scripts)

`SC2155` 235 · `SC2154` 50 · `SC2088` 37 · `SC2120` 17 · `SC2046` 16 · `SC2024` 16 ·
`SC2178` 15 · `SC2183` 14 · `SC2261` 10 · `SC2221/2222` 20 · `SC2227` 6 · `SC2010` 6 ·
`SC1083` 6 · `SC2188` 5 · `SC2038` 5 · plus ~30 singletons.

Severity **error** (highest signal, all covered above):

```
8×  ash-cli/lib/crypto.sh              SC2261  competing stdin redirects   → #2
2×  ash-cli/commands/power/logout.sh   SC2261  duplicate stderr redirect (harmless)
1×  ash-cli/commands/power/power.sh    SC2082  bad substitution            → #7
1×  ash-cli/lib/prompt.sh              SC2284  arithmetic misuse           → #8
3×  ash-cli/commands/monitor/*.sh      SC2259  pipe overridden by heredoc → #6
3×  .husky/pre-push                    SC1073/SC1036/SC1072               → #1
2×  ash-cli/lib/template-engine.sh     SC1073/SC1020  (false positive)
```

---

## Suggested fix order

1. `.husky/pre-push:184` — one `;` unblocks the entire hook. **Highest value/effort ratio.**
2. `crypto.sh` redirects (#2) — silent data loss.
3. `log::*` (#3) + `ash_truncate` (#4) + the `ash_*` helpers (#5) — add the missing
   definitions or rename call sites; this clears ~490 broken call sites and fixes the
   visible output of `ash doctor`, `ash snapshot`, `ash config`, and mode-switching.
4. `monitor/*` heredoc pipes (#6) — restores the whole `ash monitor` family.
5. `power.sh:317` and `prompt.sh:106` — two one-line correctness fixes.
6. `_ash_plugin_exec` typo, `validate.py` JSONC, `flyctl-actions@v1.5.1`.
7. The 54 `${_func}` sites and the low-severity items.

---

*Report generated by static + dynamic analysis. Reproductions for all findings are in the
sections above; no repository files were modified.*
