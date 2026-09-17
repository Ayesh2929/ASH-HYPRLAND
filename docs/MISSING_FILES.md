# ASH-HYPRLAND — Missing Files Report

**Scope:** full repository (`Ayesh2929/ASH-HYPRLAND`), commit `762142c`
**Date:** 2026-09-17
**Method:** reference extraction + existence verification (see [Methodology](#methodology))

Companion to [`BUG_REPORT.md`](BUG_REPORT.md). This document answers "what is referenced
but absent?" — **93 missing files** across 8 groups, plus **47 present-but-empty stubs** and
**9 files shipped with the wrong mode**.

Every entry was verified two ways: the reference exists at the cited `file:line`, *and* the
target is absent from `git ls-files` (not merely absent from the working tree).
Generated-at-CI-time paths are excluded — see [Not actually missing](#not-actually-missing).

---

## Executive summary

| # | Severity | Group | Missing |
|---|----------|-------|---------|
| 1 | 🔴 Critical | `config/swaync/scripts/` | **68** of 71 referenced scripts |
| 2 | 🔴 Critical | Present-but-empty JSON stubs | **47** files |
| 3 | 🟠 High | `config/hypr/render.conf` | 1 (Hyprland `source`) |
| 4 | 🟠 High | `config/waybar/scripts/` | 4 |
| 5 | 🟠 High | Packaging / build inputs | 8 |
| 6 | 🟡 Medium | `config/hypr/scripts/` + dunst | 4 |
| 7 | 🟡 Medium | Symlink sources for `ash doctor fix` | 3 |
| 8 | 🟢 Low | Comment-only references | 5 |
| 9 | 🟢 Low | `.local/bin/*` shipped non-executable | 9 files (mode) |

**Totals:** 68 + 1 + 4 + 8 + 4 + 3 + 5 = **93** referenced-but-absent files, plus 47 empty
stubs and 9 mode issues.

---

## Methodology

| Check | Approach | Result |
|-------|----------|--------|
| Broken symlinks | `find -type l` + `-e` test | 0 |
| Local action refs | `uses: ./…` → directory test | 16/16 resolve |
| `source` / `exec` targets | tokeniser over 769 shell scripts | 0 real (8 parser artefacts) |
| Config `source =` / `include` | parse + resolve relative to app dir | **1 missing** |
| `config/<app>/scripts/*.sh` refs | regex over all tracked files, verified vs `git ls-files` | **76 missing** |
| Workflow `scripts/**` refs | grep in `.github/` | 1 (guarded, benign) |
| Packaging inputs | manual trace of build workflows | **7 missing** |
| `require()` in nvim | 183 Lua files vs `lua/` tree | 0 missing |
| Stub detection | JSON with only metadata keys | **47 files** |
| Action refs | GitHub API | 1 invalid (see BUG_REPORT #13) |

---

## 1. 🔴 `config/swaync/scripts/` — 68 of 71 referenced scripts are missing

The directory contains **4** scripts:

```
config/swaync/scripts/
  clear-all.sh  toggle-bluetooth.sh  toggle-dnd.sh  toggle-wifi.sh
```

yet the swaync widgets and config reference **71 distinct scripts**, leaving **68 missing**.
Every one of these is an `on-click` / `exec` target in a notification-centre widget, so the
corresponding control is dead on click.

Referenced from: `config/swaync/config.json`, `config/swaync/widgets/*.json`
(calendar, colortemp-slider, dnd-toggle, gamemode-toggle, nightlight-toggle,
quick-settings, wifi-toggle, bluetooth-toggle, ash-mode-selector), and
`config/hypridle/hypridle.conf`.

<details>
<summary><b>Full list of the 68 missing scripts</b></summary>

```
  add-countdown.sh                  add-event.sh                      add-exception.sh                  add-game-profile.sh
  add-mode-rule.sh                  add-world-clock.sh                battery-critical.sh               blue-light-intensity.sh
  blue-light-off.sh                 blue-light-on.sh                  bt-discoverable.sh                bt-reconnect-audio.sh
  circadian-disable.sh              circadian-enable.sh               colortemp-down.sh                 colortemp-get.sh
  colortemp-input.sh                colortemp-up.sh                   cpu-boost.sh                      detect-games.sh
  discord-status.sh                 dnd-custom-duration.sh            dnd-schedule-add.sh               dns-custom.sh
  dns-set.sh                        dns-test.sh                       edit-event.sh                     exceptions.sh
  eye-care-start.sh                 eye-care-stop.sh                  game-launcher.sh                  gamescope-off.sh
  gamescope-on.sh                   geo-refresh.sh                    get-fps.sh                        gpu-lock.sh
  hotspot-off.sh                    hotspot-on.sh                     hotspot-qr.sh                     hotspot.sh
  mangohud-off.sh                   mangohud-on.sh                    metrics.sh                        net-qos-game.sh
  net-speed.sh                      night-light-intensity.sh          night-light-off.sh                night-light-on.sh
  night-light-preset.sh             night-light-state.sh              night-light-temp.sh               night-light-toggle-auto.sh
  on-snapshot.sh                    on-theme-change.sh                screen-time.sh                    screenshare.sh
  screenshot-action.sh              set-proton.sh                     show-queue.sh                     slack-status.sh
  snooze-event.sh                   toggle-night-light.sh             toggle-screenrecord.sh            traffic-session.sh
  wifi-connect.sh                   wifi-hidden.sh                    wifi-info.sh                      wifi-qr.sh
```
</details>

**Fix:** add the scripts, or strip the referencing widgets until they are implemented.
This is by far the largest gap: it is 62% of all missing files in this report.

---

## 2. 🔴 Present-but-empty JSON stubs — 47 files

These files **exist and parse**, so no checker flags them, but they carry no payload. Every
one has this identical body:

```json
{
  "name": "<filename>",
  "version": "5.0.0-omega",
  "description": "ASH Dotfiles OMEGA component: <filename>",
  "status": "ready"
}
```

This is scaffolding that was never filled in. 47 of the repo's 472 JSON files match.

### CI- and runtime-critical stubs

| File | Why it matters |
|------|----------------|
| `themes/schema/theme-schema.json` | JSON-Schema validation in `validate-theme.sh` / `schema-validation.yml` runs against a schema with **no `properties`** — it accepts everything, so theme validation is a no-op |
| `themes/schema/colors-schema.json`, `metadata-schema.json` | same |
| `plugins/schema/plugin-schema.json` | plugin manifest validation is a no-op |
| `api/schemas/theme.json`, `plugin.json`, `config.json`, `snapshot.json` | API response schemas empty |
| `browser-extension/manifest.json` | not a valid Chrome MV3 manifest (no `manifest_version`/`action`) — unloadable as committed. CI regenerates it, but the tracked file is misleading |
| `web/public/manifest.json` | PWA manifest is invalid (no `name`/`icons`/`start_url`) |
| `ash-cli/data/plugin-registry.json` | plugin registry empty → `ash plugin`/store listing has no data |
| `ash-cli/data/theme-store.json` | theme store empty |
| `ash-cli/data/mode-registry.json` | mode registry empty |
| `ash-cli/data/keybinds.json` | keybind registry empty |
| `ash-cli/data/app-list.json` | app list empty |
| `ash-cli/data/distro-packages.json` | package lists empty |
| `ash-cli/engines/ai-engine/models/*.json` (4) | AI "models" are stubs |
| `ml-models/**/model.json` (5) + `labels.json`, `prompts.json`, `training-data.json` | ML model artefacts are stubs |
| `plugins/core/game-mode/plugin.json`, `config.json` | plugin manifests empty |
| `templates/theme-template/colors.json`, `metadata.json` | theme template generates an empty theme |
| `data/state/*.json` (5), `data/favorites/*.json` (3) | runtime state seeds empty |

**Fix:** either populate them, or delete the stubs and let the code create them on demand —
a stub that parses is worse than a missing file, because nothing errors.

---

## 3. 🟠 `config/hypr/render.conf` — Hyprland `source` target missing

```
config/hypr/hyprland.conf:38:  source = ~/.config/hypr/render.conf
config/hypr/opengl.conf:310:   # Fix 3: Disable direct_scanout in render.conf
.github/ISSUE_TEMPLATE/hardware_issue.yml:820:  $ cat ~/.config/hypr/render.conf
```

The file is **not gitignored** and does not exist. Of the 34 `source =` targets in
`config/hypr/`, this is the only one absent — the other 33 all resolve.

Hyprland logs a config error at every start, and any render/`direct_scanout` tuning the
docs tell users to put there has nowhere to live. Two other files already document it as a
real file, so this is an omission rather than an intentional removal.

---

## 4. 🟠 `config/waybar/scripts/` — 4 module scripts missing

| Missing | Referenced by |
|---------|---------------|
| `do-not-disturb.sh` | `config.jsonc:435` — `exec` on a **5-second interval** |
| `gpu-intel.sh` | `custom-modules/gpu-intel.jsonc` |
| `task-count.sh` | `custom-modules/task-count.jsonc` |
| `updates-flatpak.sh` | `custom-modules/updates-flatpak.jsonc` |

16 of the 20 custom-module scripts do exist (`gpu-amd.sh`, `gpu-nvidia.sh`, `weather.sh`,
…) — the Intel GPU variant exists but its script does not, while the AMD and NVIDIA ones do.

`do-not-disturb.sh` is the worst of the four: it runs every 5 seconds, so Waybar produces a
recurring `command not found` and the DND icon never updates. Note the functionality
**already exists** at `config/dunst/scripts/do-not-disturb.sh`.

---

## 5. 🟠 Packaging / build inputs missing

| Missing | Referenced by | Effect |
|---------|---------------|--------|
| `packaging/flatpak/dev.ash_dotfiles.AshDotfiles.metainfo.xml` | `build-flatpak.yml:244` (`install -Dm644`) | Flatpak build fails |
| `packaging/flatpak/dev.ash_dotfiles.AshDotfiles.desktop` | `build-flatpak.yml:248` | Flatpak build fails |
| `assets/brand/logos/ash-logo-256.png` | `build-flatpak.yml:252` | Flatpak build fails (only `.svg`/`.ico` exist) |
| `assets/brand/logos/ash-logo-512.png` | `build-flatpak.yml:254` | Flatpak build fails |
| `docker/Dockerfile.full` | `publish-ghcr.yml:213` (matrix `full-desktop`) | GHCR job fails |
| `packaging/aur/ash-dotfiles/PKGBUILD` | `build-arch-pkg.yml:128` | AUR build fails |
| `packaging/aur/ash-dotfiles-git/PKGBUILD` | `build-arch-pkg.yml:320` | AUR build fails |
| `nix/packages/ash-dotfiles.nix` | `build-nix.yml:381` | Nix build fails (repo has `ash-cli.nix`, `ash-plugins.nix`, `ash-themes.nix`) |

Two naming mismatches are worth calling out:

- **Flatpak APP_ID drift.** `build-flatpak.yml:89` sets `APP_ID: "dev.ash_dotfiles.AshDotfiles"`,
  but the repo ships `packaging/flatpak/com.ash.dotfiles.yml`. Two different app IDs, and
  neither the `.metainfo.xml` nor the `.desktop` file exists.
- **Docker `Dockerfile.full`.** The `.api`, `.cli` and `.test` variants are all *generated* by
  the workflow when absent — `.full` is declared in the build matrix but **nothing ever
  creates it**, so the `full-desktop` image cannot build.

---

## 6. 🟡 `config/hypr/scripts/` + dunst — 4 missing

| Missing | Referenced by |
|---------|---------------|
| `config/hypr/scripts/vpn-auto.sh` | `config/hypr/autostart.conf` |
| `config/hypr/scripts/battery-monitor.sh` | `config/hypr/autostart.conf:105` |
| `config/hypr/scripts/screenshot.sh` | `config/hypr/env.conf:451` |
| `config/dunst/scripts/open-action.sh` | `config/dunst/rules/ash-snapshot.conf:302` |

`battery-monitor.sh` exists at a **different path** (`scripts/notification/battery-monitor.sh`),
so this looks like a path drift rather than unwritten functionality — the autostart entry
points at the config-local copy that was never created.

---

## 7. 🟡 Symlink sources used by `ash doctor fix` — 3 missing

`ash-cli/commands/doctor/fixers/fix-symlinks.sh` contains a table of symlinks to create.
Three sources do not exist:

```bash
"config/starship/starship.toml:${_FSL_CFG}/starship.toml"
"config/git/.gitconfig:${_FSL_CFG}/git/.gitconfig"
"config/git/.gitignore_global:${_FSL_CFG}/git/.gitignore_global"
```

The entire `config/git/` directory is absent, and none of the three is gitignored.

Because `_fsl_link` guards with `[[ ! -e "$src" ]]` and reports
`"source missing — skip"`, this fails **silently and repeatedly** — `ash doctor fix` reports
these as skipped rather than as errors, so the user never learns that their git and starship
configs are not being linked.

---

## 8. 🟢 Comment-only references — 5 missing

Referenced in comments but never present. These do not break execution, but they are
false promises that mislead contributors — particularly the first one, which claims
automated enforcement that does not exist:

| Missing | Referenced in |
|---------|---------------|
| `scripts/lint/nameref-cycle.sh` | `material-you.sh:239` — *"now checked automatically (see scripts/lint/nameref-cycle.sh)"* |
| `scripts/monitor-hotplug.sh` | `config/hypr/monitors.conf:224,228` |
| `scripts/notification/weather.sh` | `config/hyprlock/scripts/weather-lock.sh:12` |
| `scripts/install/generate-avatar-initials.sh` | `config/hyprlock/widgets/avatar.conf:241` |
| `scripts/install/setup-hyprlock-assets.sh` | `config/hyprlock/layouts/clock-center.conf:94` |

---

## 9. 🟢 `.local/bin/*` shipped non-executable — 9 files

All nine scripts under `.local/bin/` are tracked as mode `100644`:

```
100644  .local/bin/ash          100644  .local/bin/ash-shot
100644  .local/bin/ash-backup   100644  .local/bin/ash-theme
100644  .local/bin/ash-clean    100644  .local/bin/ash-update
100644  .local/bin/ash-doctor   100644  .local/bin/ash-wall
100644  .local/bin/ash-reset
```

Compare `bin/ash`, which is correctly `100755`. These are meant to be invoked directly as
`~/.local/bin/ash-*`, and systemd units depend on exactly that path
(`ExecStart=%h/.local/bin/ash theme schedule --now` in `theme/schedule.sh:173`, and
`backup/schedule.sh:45`). Nothing in `scripts/install.sh` or `setup.sh` chmods them.

The repo already knows this is a problem: `doctor/checks/check-permissions.sh:230` suggests
`chmod +x ~/.local/bin/*` as the fix — a fix that is only needed because of this.

**Fix:** `git update-index --chmod=+x .local/bin/*`

---

## Not actually missing

Verified as **generated or fetched at CI time**, so their absence from git is by design.
Listed so nobody "fixes" them:

| Path | Generated by |
|------|--------------|
| `docker/Dockerfile.api`, `.cli`, `.test` | `build-docker.yml:226/307/363`, `publish-ghcr.yml:256/333/405` |
| `browser-extension/package.json`, `vite.config.ts`, `manifest.json` | `build-browser-extension.yml:221/270/136` |
| `packaging/flatpak/<APP_ID>.yml` | `build-flatpak.yml:142-146` |
| `ash-cli/data/{ash-config,snapshot,analytics}-schema.json` | `schema-validation.yml` *"GENERATE-SCHEMAS — Create schemas if missing"* job |
| `tests/fixtures/sample-wallpaper.jpg` | `benchmark-memory.yml:266` (ImageMagick, with a `dd` fallback) |
| `api/openapi.json` | `deploy-api.yml:224/241` |
| `tests/helpers/bats-support`, `bats-assert` | `_reusable-test.yml:35-36` (`git clone`) |
| `scripts/install/uninstall.sh` | guarded by `if [[ -f … ]]` in `install-test-arch.yml:727` |
| `config/hypr/themes/*.conf`, `config/kitty/themes/current.conf`, `config/rofi/themes/ash-dynamic.rasi`, `config/waybar/styles/colors.css`, `config/swaync/style.css`, `config/gtk-*/gtk.css`, `config/hyprlock/hyprlock.conf` | listed in `.gitignore`, written by `ash theme apply` |

---

## What was verified present ✅

- **Broken symlinks:** 0
- **Local composite actions:** 16/16 `uses: ./…` targets resolve
- **`source`/`exec` in 769 shell scripts:** all resolve (8 regex artefacts inspected and dismissed)
- **Hyprland `source =`:** 33 of 34 resolve
- **Kitty `include`:** `colors.conf`, `fonts.conf` both present
- **nvim `require()`:** 0 unresolved local modules across 183 Lua files
- **`scripts/**` referenced from workflows:** all resolve (1 guarded miss)
- **systemd `ExecStart`:** all absolute system paths
- **Zsh/Bash/Fish completions:** `ash.bash`, `ash.zsh`, `ash.fish` all present

---

## Suggested fix order

1. **`config/hypr/render.conf`** — one file, removes a startup error.
2. **`config/waybar/scripts/do-not-disturb.sh`** — copy/symlink from `config/dunst/scripts/`; stops a 5-second error loop.
3. **`.local/bin/*` exec bits** — one command, `git update-index --chmod=+x`.
4. **The 4 packaging inputs** — unblocks the Flatpak build; fix the `APP_ID` drift.
5. **`config/swaync/scripts/`** — 68 scripts; scope this one deliberately rather than by accident.
6. **The 47 stubs** — decide per file: populate, or delete and generate on demand.

---

*Report generated by reference extraction and existence verification. No repository files
were modified.*
