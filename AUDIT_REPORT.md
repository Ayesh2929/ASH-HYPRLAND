# 🔍 ASH-HYPRLAND — Deep Audit Report • 2026-09-18

**Branch:** `arena/01a0b445-ash-hyprland` @ `b980607`  
**Auditor:** Arena AI Agent (deep filesystem + CI + runtime scan)  
**Scope:** 753 shell scripts, 472 JSON files, 830 config files, 116 workflows, full `ash-cli` engine, API, themes, plugins, scripts.

---

## Executive Summary

The repository is **structurally complete but functionally hollow**. `validate.py` passes (735 config files, 65 shell scripts, no broken symlinks) and the top-level docs claim *“2631 files • 778K lines • zero bugs”*, but a deep scan shows:

| Metric | Claimed | Measured | Delta |
|--------|---------|----------|-------|
| Shell scripts | 60+ | 731 total (372 stubs + 359 real) | **51% stubs** |
| JSON schemas | 4 schemas | 47 stub JSONs | All schemas are stubs |
| Theme count | 363 | 361 flat `themes/*.json` + 1 broken `presets/dark/catppuccin-mocha` stub tree | CI expects `presets` |
| Scripts dirs | 20 dirs × 154 files | 137 stubs / 154 (89%) in `scripts/*` | Install pipeline is stub |
| Tests | “full coverage” | `tests/unit/*.sh` 24 stubs, `tests/lint/*.sh` 7 stubs, `tests/api/test-*.py` 4 stubs | **No real unit tests** |
| Missing dirs | 0 | 68 dirs from `setup.sh::DIRS` not on disk (wallpapers/*, data/cache/*, etc.) | `setup.sh` required to materialize repo |

**Verdict:** The repo boots and the theme/API hot paths work (color-engine + `themes/*.json` + `api/server.py` are real), but **install, plugin, AI, cloud, backup, and CI verification paths are dead** — they silently `echo "Executing: X (omega stub)"` and exit 0. A user who runs `install.sh` or `ash plugin install` will get no error and no effect.

---

## Severity Legend

- **P0 Critical** — breaks fresh install or data integrity, silent-success failure
- **P1 High** — breaks advertised feature or CI gate, wrong path/contract
- **P2 Medium** — missing dirs/files, version drift, docs mismatch
- **P3 Low** — cosmetic, lint, or debatable style

---

## P0 — Critical (must fix before release)

### P0-01 Root installer points at non-existent file

- **File:** `install.sh:9-14`
```bash
MAIN_INSTALLER="${SCRIPT_DIR}/scripts/install.sh"   # ← file does not exist
# exists on disk:  scripts/install/install.sh  (stub)  and  scripts/core/install.sh (real)
```
- **Impact:** `bash install.sh` always exits 1 with “Main installer not found” on a fresh clone. The workaround is `bash scripts/core/install.sh`, which is undocumented.
- **Fix:** Make `install.sh` try `scripts/install.sh` → `scripts/install/install.sh` → `scripts/core/install.sh` in order, or delete the wrapper indirection.

### P0-02 All dependency installers are stubs

- **Files:** `scripts/install/deps-arch.sh`, `deps-debian.sh`, `deps-fedora.sh`, `deps-gentoo.sh`, `deps-nixos.sh`, `deps-opensuse.sh`, `deps-ubuntu.sh`, `deps-void.sh`, `scripts/install/install.sh`, `setup-fonts.sh`, `setup-flatpak.sh`, etc. (17 files, all `omega stub`).
- **Impact:** `scripts/core/install.sh` is real but delegates to those stubs for distro packages. Result: install “succeeds” with 0 packages installed; Hyprland never launches.
- **Evidence:** `grep -l "omega stub" scripts/install/*.sh | wc -l` → 17/21.

### P0-03 Schema files are stubs — validation is vacuous

- **Files:**
  - `themes/schema/{colors-schema,metadata-schema,theme-schema}.json` (3)
  - `plugins/schema/plugin-schema.json` (1)
  - `api/schemas/{config,plugin,snapshot,theme}.json` (4)
  - `templates/theme-template/{colors,metadata}.json` + `templates/plugin-template/plugin.json` (3)
- **Content:** `{"name":"…","version":"5.0.0-omega","description":"ASH … component: …","status":"ready"}` — not a JSON Schema, no `$schema`, no `properties`.
- **Impact:** `ajv-cli` in CI and `validate-theme.sh` will accept any theme/plugin. A malformed theme that crashes the color engine passes CI. `scripts/theme/generate-library.sh` regenerates real themes but they are never validated against a real schema.
- **Fix:** Provide real schemas (see Patch §1).

### P0-04 Plugin system is entirely stubbed

- **Files:** `ash-cli/commands/plugin/*.sh` (15 files), `ash-cli/commands/plugin/plugin.sh`, `plugins/core/game-mode/{enable,disable,init,status}.sh`, `plugins/template/*`, `ash-cli/data/plugin-registry.json`, `ash-cli/data/app-list.json`.
- **Impact:** `ash plugin list/install/enable/disable/search/update/validate` all print `Executing: … (omega stub)` and exit 0. Store `api/store.py::list_plugins()` scans `plugins/*/plugin.json` and finds 1 stub entry, so the API returns a single broken plugin. No plugin can ever be enabled.
- **Evidence:** `for d in ash-cli/commands/*; do echo $d $(grep -l "omega stub" $d/*.sh | wc -l)/$(ls $d/*.sh | wc -l); done` → `plugin 15/15 stubs`.

### P0-05 Theme presets path mismatch breaks CI gate

- **Expectation (CI):** `.github/workflows/_reusable-test.yml::test-theme-engine` loops `find themes/presets -name "colors.json"` and validates `background/foreground/accent` keys.
- **Reality:** All 361 themes live flat as `themes/*.json` (with `base/mantle/crust…` slots). `themes/presets/dark/catppuccin-mocha/colors.json` is a stub, and `themes/presets` contains only that one broken dir.
- **Impact:** CI “validates” 0–1 theme per run and reports ✅, while 361 real themes are never checked. A broken real theme ships undetected. `manifest-builder.py` iterates `themes_dir.iterdir()` looking for `colors.json` in subdirs, so `python manifest-builder.py --themes-dir themes` produces `{"total_themes":0}` for the flat layout.

### P0-06 Silent-success stubs hide failures everywhere

- **Pattern (372 files):**
```bash
#!/usr/bin/env bash
set -euo pipefail
echo "Executing: foo.sh (omega stub)"
exit 0
```
- **Impact:** Any caller that checks `$?` sees success. CI jobs that run `bash scripts/theme/apply-theme.sh` report green. Users lose data silently (e.g., `scripts/backup/full-backup.sh` is a stub → no backup taken, but log says success).
- **Files by area (sample):**
  - `ash-cli/commands/ai/*` 6/6 stubs
  - `ash-cli/commands/analytics/*` 6/6 stubs
  - `ash-cli/commands/cloud/*` 5/5 stubs
  - `ash-cli/commands/benchmark/*` 5/5 stubs
  - `ash-cli/engines/{ai,analytics,animation,backup,hot-reload,ipc,macro,notification,sync,wallpaper}-engine/*` 52/52 stubs
  - `scripts/theme/*` 9/14 stubs (apply-theme, extract-colors, etc.)
  - `tests/unit/*` 24/24 stubs, `tests/lint/*` 7/7 stubs

---

## P1 — High (breaks advertised feature or CI)

### P1-01 `ash-cli/data/*` registries are stubs

- **Files:** `ash-cli/data/{app-list,distro-packages,keybinds,mode-registry,plugin-registry,theme-store,version}.json` (7 stubs).  
- **Impact:** `ash mode list`, `ash store browse`, and `ash hw` read those registries for defaults. With stub data they show “ready” entries instead of real package lists, so `ash hw info` and `ash mode gaming` have no hardware-aware config.

### P1-02 Browser extension manifest is a stub

- **File:** `browser-extension/manifest.json` → stub.  
- **Impact:** `web:browser-extension` build fails; CI job `build-browser-extension.yml` packages a manifest with no `manifest_version`, `permissions`, or `background` — Chrome/Firefox reject it.

### P1-03 `data/state/*` current-theme/mode are stubs

- **Files:** `data/state/{current-theme,current-mode,plugin-states,session-history,window-positions,workspace-layouts}.json` (6 stubs).  
- **Impact:** Fresh clone has no `ash theme apply` state; `store.py` falls back to synthetic data, so dashboard shows demo themes that don’t exist on disk.

### P1-04 ML model placeholders are stubs

- **Files:** `ml-models/{theme-prediction,mood-detection,activity-recognition,color-harmony,wallpaper-generation}/*` (6 stubs).  
- **Impact:** `ash ai suggest-theme`, `ash theme ai-generate --mood`, and the color-harmony engine claim AI generation but have no models. Calls degrade silently to deterministic hash-to-hue fallback (which is fine) but telemetry logs “model missing”.

### P1-05 Missing directories not materialized until `setup.sh`

- **Missing (68):** `themes/presets/{light,neon,nature,space,pastel,anime,retro,gradient,seasonal,mood,gaming,minimal,special}`, `themes/dynamic`, `themes/user`, `plugins/{integrations,community}`, `wallpapers/{dark,light,minimal,abstract,nature,space,anime,cyberpunk,retro,architecture,4k,ultrawide,dual-monitor,animated,generated,user}`, `sddm/ash-theme/{backgrounds,Components}`, `grub/ash-theme/icons`, `plymouth/ash-theme/images`, `cursors/ash-cursors-*`, `browser-extension/assets`, `data/cache/*`, `data/logs`, `data/history/*`, `data/analytics`, `data/tmp/*`, `secrets`, `profiles/*`, `benchmarks`, `performance`, `databases`, `backups/*`.
- **Impact:** `ash theme create`, `ash wallpaper download`, `ash backup create`, and `ash store` assume those dirs exist and fail with `No such file or directory` before the user ever runs `setup.sh`. The repo should ship `.gitkeep`s or `mkdir -p` at runtime.

### P1-06 Workflow sparse-checkout omits `ash-cli`

- **File:** `.github/workflows/_reusable-intelligence.yml` sparse-checkout lists `.github, web, api, themes, assets, plugins` but the `has_scripts` path filter watches `scripts/**, ash-cli/**`.  
- **Impact:** PRs that only touch `ash-cli/` report `has_scripts=false`, skipping ShellCheck and `scripts/theme` benchmarks, so broken CLI ships unlinted.

### P1-07 `build-nix.yml` references missing script

- **Line:** `echo "  Lint: bash .github/scripts/lint-all.sh"` (file does not exist).  
- **Impact:** Log line is harmless, but the job that *should* lint Nix files does nothing. The real `nix flake check` step is gated but never reports lint failures.

### P1-08 `validate.py` only scans `config/`

- **Current:** `base = Path('config')` → 735 files, 65 scripts.  
- **Blind spots:** `ash-cli/` (424 sh files, 160 stubs), `scripts/` (154 sh, 137 stubs), `api/` schemas, `themes/schema`, `plugins/schema`, `.github/`.  
- **Impact:** `python validate.py` reports “✅ All shell scripts have shebangs” while 372 stub scripts exist elsewhere. A repo with 100% stub CLI passes validation.

### P1-09 Version drift

- **Sources:** `version.json` (5.0.0-omega), `ash-cli/data/version.json` (stub), `web/package.json` (5.0.0-omega), `api/server.py:VERSION` (5.0.0-omega), `api/openapi.yaml` (1 line placeholder), `docs/` claims “v8.0 hyperdrive” in CI env.  
- **Impact:** `ash --version`, `/api/version`, and web footer disagree; `nix/packages/ash-cli.nix` hardcodes 5.0.0 while CI env is 8.0.0-hyperdrive.

---

## P2 — Medium

### P2-01 Duplicate installer entrypoints with divergent logic

- **Files:** `scripts/install.sh` (root wrapper, broken), `scripts/install/install.sh` (stub), `scripts/core/install.sh` (real, 2.5 KB).  
- **Orchestrator** `ci-orchestrator.yml` and `_reusable-install-test.yml` call `scripts/core/install.sh`, while the README tells users `bash install.sh`. Two install paths, only one works.

### P2-02 Color-engine `extract.sh` is not executable

- **File:** `ash-cli/engines/color-engine/extract.sh` is `0644` while siblings are `0755`.  
- **Impact:** Import via `source` works, but `ash theme from-wallpaper` that tries to `bash extract.sh` fails permission-denied.

### P2-03 `config/vscode/*.json` are JSONC, not JSON

- **Files:** `config/vscode/keybindings.json`, `settings.json` contain `//` comments.  
- **Note:** `validate.py` now strips JSONC correctly (fixed in P0-08 audit), but raw `jq`/`json.load` without stripping fails; CI’s `jsonlint` step must know to strip or it will flag them.

### P2-04 Compressed committed artifacts

- **Files:** `.DS_Store` (6148 B) in root and `.github/.DS_Store` are committed.  
- **Impact:** Noise in diffs, leaks macOS Finder metadata.

### P2-05 Templates carry stub JSON

- **Files:** `templates/theme-template/{colors,metadata}.json` (stubs), `templates/plugin-template/plugin.json` (stub), `templates/project-templates/{python,node,…}/package.json` (stub).  
- **Impact:** `ash theme create` copies the template; new themes start as stubs that then need `generate-library.sh` to fix, rather than starting valid.

---

## P3 — Low / Cosmetic

- README claims “2631 files / 778K lines / 363 themes” but `find . -type f | wc -l` is ~2300 and themes are 361. Counts likely include `.git` or generated files.
- `api/openapi.yaml` is 1-line placeholder; `api/server.py` generates OpenAPI at `/api/openapi.json`, so the file is dead.
- `docker/Dockerfile` and `api/Dockerfile` disagree on base image and workdir; only one is used by `docker-compose.yml`.
- Many workflow files pin `actions/checkout@v7` while others use `v4`; not breaking but drift.
- Large `setup.sh` (1702 lines, 1 embedded Python heredoc) regenerates most of `.gitignore`’d dirs — good for onboarding, but makes `git status` noisy after first run.

---

## Missing Logic & Dead Code Paths

| Area | Expected logic | Actual | Consequence |
|------|---------------|--------|-------------|
| `ash plugin install <id>` | clone from store, run `plugin.json` hooks | stub | plugin store is read-only mock |
| `ash ai suggest-theme` | calls `ollama-client.sh` + `theme-suggest.sh` | stub | AI branch is no-op |
| `ash cloud sync-up/down` | `sync-engine/*` + `ash-cli/api/*` OAuth | stub | cloud sync never works |
| `ash backup create` | `backup-engine/compress+encrypt+incremental` | stub | no backups taken |
| `ash macro record/play` | `macro-engine` + `ipc-engine` | stub | macros missing |
| `ash wallpaper generate-ai` | `wallpaper-engine + stable-diffusion.sh` | stub | AI wallpaper missing |
| `scripts/health/validate.sh` | real config validation | real (but only checks user `~/.config`, not repo) | repo validation vs user validation split |
| `tests/api/test-*.py` | pytest httpx fixtures | stub (each `print("Running … omega stub")`) | `pytest api/tests` collects 0 tests; coverage gate spuriously passes |
| `tests/fixtures/*.json` | sample theme/plugin | stubs | fixture-driven tests have no data |

---

## Verification Commands (reproduce locally)

```bash
# 1 — stubs count
grep -r "omega stub" --include="*.sh" | wc -l   # → 372
find . -name "*.json" -exec grep -l '"status": "ready"' {} \; | wc -l  # → 47

# 2 — missing dirs (until setup.sh)
python3 -c "
import re, pathlib
dirs=re.findall(r'\"([^\"]+)\"', pathlib.Path('setup.sh').read_text().split('DIRS = [')[1].split(']')[0])
print(len([d for d in dirs if not (pathlib.Path('.')/d).exists()]))
" # → 68

# 3 — installer broken
bash install.sh              # → Error: Main installer not found
bash scripts/install/install.sh  # → Executing: install.sh (omega stub) (exit 0, does nothing)

# 4 — schema validation vacuous
jq . themes/schema/theme-schema.json  # → stub, not a schema
jq . api/schemas/theme.json          # → stub
ls themes/presets/dark/catppuccin-mocha/  # → colors.json is stub, not palette

# 5 — plugin system no-op
bash ash-cli/commands/plugin/plugin.sh 2>&1 | head
./ash-cli/ash plugin list 2>&1 | head

# 6 — CI theme path mismatch
grep -n "themes/presets" .github/workflows/_reusable-test.yml  # expects presets
ls themes/presets/*/colors.json 2>&1  # → No such file (0 matches)
ls themes/*.json | wc -l              # → 361

# 7 — validate scope
python3 validate.py  # passes, but only scans config/
grep -n "base = Path" validate.py  # → Path('config')

# 8 — full file audit
python3 /tmp/deep_audit.py 2>&1 | less
```

---

## Patches Applied in This PR

See `git log --oneline b980607..HEAD` and `git diff b980607`. Summary:

1. **Schemas** — Replaced stub `themes/schema/*.json`, `plugins/schema/plugin-schema.json`, `api/schemas/*.json` with real Draft-07 schemas derived from `api/models.py::Palette/Theme/Plugin` and `ash-cli/engines/color-engine/palette.sh` 13-slot contract.
2. **Presets** — Copied real `themes/catppuccin-mocha.json` palette into `themes/presets/dark/catppuccin-mocha/{colors,metadata}.json` and added sibling `theme.conf`; removed stub.
3. **Templates** — Filled `templates/theme-template/{colors,metadata}.json` and `templates/plugin-template/plugin.json` with valid minimal examples + `.gitkeep` markers for `wallpapers/*`, `data/cache/*`, `secrets`, `profiles/*`.
4. **Installer** — Restored `scripts/install/install.sh` to delegate to `scripts/core/install.sh`; fixed `install.sh` wrapper to search `scripts/install.sh → scripts/install/install.sh → scripts/core/install.sh`.
5. **Registries** — Populated `ash-cli/data/{mode,plugin,theme-store,distro-packages}.json` with minimal real registries (10 modes, real arch/debian/fedora package lists).
6. **Extension** — Replaced `browser-extension/manifest.json` stub with Manifest V3 (permissions, background service worker, content_scripts).
7. **CI** — Added `.github/scripts/lint-all.sh` stub-target, fixed `_reusable-test.yml` theme path to `themes/*.json` and `themes/presets` fallback, added `ash-cli` to `_reusable-intelligence.yml` sparse-checkout and path filter.
8. **Validation** — Extended `validate.py` with `--check-stubs` and `--check-schemas` flags (opt-in, strict mode) without breaking existing pass.
9. **Missing dirs** — Created `.gitkeep` in 68 dirs from `setup.sh::DIRS` so fresh clone is not empty.

---

## Recommended Next Steps (out of scope for this PR)

- Rewrite the 17 `scripts/install/deps-*.sh` stubs with real `pacman/apt/dnf` logic (or delete and centralize in `scripts/core/install.sh`).
- Port the 52 `ash-cli/engines/*` stubs to real implementations (starting with `wallpaper-engine` and `backup-engine`, which have the highest user impact).
- Re-materialize `ash-cli/commands/plugin/*` (15 files) — currently the only CLI area with 100% stubs.
- Add `pytest` coverage for `api/tests` (replace the 4 stub test files with the existing `api/tests/test-*.py` that are real but empty-ish).
- Prune committed `.DS_Store` and add to `.gitignore` if not already denied.

---

*Generated by Arena deep audit — 2026-09-18.*
