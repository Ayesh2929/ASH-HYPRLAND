#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/routes.py                                     ║
# ║                                                                               ║
# ║  Every REST endpoint, in one auditable file. Handlers stay thin: they          ║
# ║  validate input, delegate to api/store.py, and translate the domain result     ║
# ║  into an HTTP status. Business logic lives in the store.                      ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""ASH API v1 route definitions."""

from __future__ import annotations

import time
from typing import Annotated, Any

from fastapi import APIRouter, HTTPException, Path as PathParam, Query, status

import store
from models import (
    CommandRequest, CommandResult, DoctorReport, LogEntry, MetricPoint, Mode,
    Plugin, Snapshot, SnapshotCreate, Theme, ThemeCreate, ThemeGenerate,
    min_contrast,
)

api_router = APIRouter()

STARTED_AT = time.time()


# ═══════════════════════════════════════════════════════════════════════════════
# § 1  META
# ═══════════════════════════════════════════════════════════════════════════════

@api_router.get("/ping", tags=["meta"], summary="Round-trip check")
async def ping() -> dict[str, Any]:
    return {"pong": True, "ts": int(time.time() * 1000), "uptime": int(time.time() - STARTED_AT)}


@api_router.get("/version", tags=["meta"], summary="Component versions")
async def version() -> dict[str, Any]:
    import platform

    return {
        "ash": "5.0.0-omega",
        "api": "1.0.0",
        "python": platform.python_version(),
        "platform": platform.platform(),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# § 2  THEMES
# ═══════════════════════════════════════════════════════════════════════════════

@api_router.get(
    "/themes",
    tags=["themes"],
    response_model=list[Theme],
    summary="List every installed theme",
)
async def list_themes(
    variant: Annotated[str | None, Query(pattern="^(dark|light)$")] = None,
    tag: str | None = None,
    min_contrast_ratio: Annotated[float, Query(ge=1.0, le=21.0)] = 1.0,
) -> list[Theme]:
    """Filter server-side so a large theme library does not bloat the response."""
    themes = store.list_themes()
    if variant:
        themes = [t for t in themes if t.variant == variant]
    if tag:
        themes = [t for t in themes if tag in t.tags]
    if min_contrast_ratio > 1.0:
        themes = [t for t in themes if t.contrast >= min_contrast_ratio]
    return themes


@api_router.get("/themes/{theme_id}", tags=["themes"], response_model=Theme)
async def get_theme(theme_id: str) -> Theme:
    theme = store.get_theme(theme_id)
    if not theme:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no theme with id {theme_id!r}")
    return theme


@api_router.post(
    "/themes",
    tags=["themes"],
    response_model=Theme,
    status_code=status.HTTP_201_CREATED,
    summary="Create or replace a theme",
)
async def create_theme(body: ThemeCreate) -> Theme:
    return store.save_theme(body.model_dump())


@api_router.delete("/themes/{theme_id}", tags=["themes"], summary="Delete a user theme")
async def delete_theme(theme_id: str) -> dict[str, bool]:
    if not store.delete_theme(theme_id):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            f"{theme_id!r} is not a user theme (built-ins cannot be deleted)",
        )
    return {"ok": True}


@api_router.post(
    "/themes/generate",
    tags=["themes"],
    response_model=Theme,
    summary="Synthesise a palette from a text prompt",
)
async def generate_theme(body: ThemeGenerate) -> Theme:
    return store.generate_theme(body.prompt, body.variant)


@api_router.post("/themes/{theme_id}/apply", tags=["themes"], summary="Apply a theme to the desktop")
async def apply_theme(theme_id: str) -> dict[str, Any]:
    """Apply via the CLI when it is present, otherwise record the selection.

    Either way the call succeeds and the active theme is updated, because the
    API's contract is "this theme is now selected" — how the desktop is told is
    an implementation detail.
    """
    theme = store.get_theme(theme_id)
    if not theme:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no theme with id {theme_id!r}")

    store._ensure_dirs()  # noqa: SLF001 — intentional: single internal helper
    (store.STATE_DIR / "theme").write_text(theme_id + "\n", encoding="utf-8")

    stdout, stderr, code = store.run_ash(["theme", "apply", theme_id], timeout=30)
    return {
        "ok": True,
        "theme": theme.id,
        "contrast": theme.contrast,
        "cli": {"code": code, "stdout": stdout[:2000], "stderr": stderr[:2000]},
    }


@api_router.get("/themes/{theme_id}/audit", tags=["themes"], summary="WCAG audit for one theme")
async def audit_theme(theme_id: str) -> dict[str, Any]:
    theme = store.get_theme(theme_id)
    if not theme:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no theme with id {theme_id!r}")

    c = theme.colors
    pairs = {
        "text/base": (c.text, c.base),
        "subtext/base": (c.subtext, c.base),
        "accent/base": (c.accent, c.base),
        "text/surface": (c.text, c.surface),
        "mint/base": (c.mint, c.base),
        "rose/base": (c.rose, c.base),
    }
    ratios = {name: round(store.contrast_ratio(fg, bg), 2) for name, (fg, bg) in pairs.items()}
    worst = min(ratios.values())

    return {
        "theme": theme.id,
        "ratios": ratios,
        "minimum": worst,
        "grade": "AAA" if worst >= 7 else "AA" if worst >= 4.5 else "AA-large" if worst >= 3 else "fail",
        "passes_aa": worst >= 4.5,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# § 3  PLUGINS
# ═══════════════════════════════════════════════════════════════════════════════

@api_router.get("/plugins", tags=["plugins"], response_model=list[Plugin])
async def list_plugins(
    installed: bool | None = None,
    enabled: bool | None = None,
    category: str | None = None,
) -> list[Plugin]:
    plugins = store.list_plugins()
    if installed is not None:
        plugins = [p for p in plugins if p.installed == installed]
    if enabled is not None:
        plugins = [p for p in plugins if p.enabled == enabled]
    if category:
        plugins = [p for p in plugins if p.category == category]
    return plugins


@api_router.get("/plugins/{plugin_id}", tags=["plugins"], response_model=Plugin)
async def get_plugin(plugin_id: str) -> Plugin:
    plugin, _ = store.find_plugin(plugin_id)
    if not plugin:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no plugin with id {plugin_id!r}")
    return plugin


@api_router.post("/plugins/{plugin_id}/enable", tags=["plugins"])
async def enable_plugin(plugin_id: str) -> dict[str, Any]:
    return _toggle_plugin(plugin_id, True)


@api_router.post("/plugins/{plugin_id}/disable", tags=["plugins"])
async def disable_plugin(plugin_id: str) -> dict[str, Any]:
    return _toggle_plugin(plugin_id, False)


def _toggle_plugin(plugin_id: str, enabled: bool) -> dict[str, Any]:
    plugin, manifest = store.find_plugin(plugin_id)
    if not plugin or not manifest:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no plugin with id {plugin_id!r}")

    # Refuse to enable a plugin whose declared dependencies are unmet.
    missing = _missing_dependencies(plugin.dependencies)
    if enabled and missing:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"cannot enable {plugin_id}: missing {', '.join(missing)}",
        )

    # The manifest is the source of truth; the CLI hook is best-effort.
    ok = store.set_plugin_enabled(plugin_id, enabled)
    stdout, stderr, code = store.run_ash(
        ["plugin", "enable" if enabled else "disable", plugin_id], timeout=30
    )
    return {
        "ok": ok,
        "plugin": plugin_id,
        "enabled": enabled,
        "missing_dependencies": missing,
        "cli": {"code": code, "stdout": stdout[:2000], "stderr": stderr[:2000]},
    }


def _missing_dependencies(dependencies: list[str]) -> list[str]:
    """Return the subset of `name>=x.y.z` specs that cannot be satisfied."""
    import re
    import shutil

    missing: list[str] = []
    for spec in dependencies:
        name = re.split(r"[<>=!~]", spec, maxsplit=1)[0].strip()
        if not name:
            continue
        # A dependency is a command on PATH, a python module, or a plugin id.
        found = (
            shutil.which(name) is not None
            or (store.PLUGIN_DIR / name).exists()
            or (store.PLUGIN_DIR / name / "plugin.json").exists()
        )
        if not found:
            missing.append(name)
    return missing


@api_router.delete("/plugins/{plugin_id}", tags=["plugins"])
async def remove_plugin(plugin_id: str) -> dict[str, bool]:
    _, manifest = store.find_plugin(plugin_id)
    if not manifest:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no plugin with id {plugin_id!r}")

    # Refuse to delete anything outside the plugin tree, whatever the id says.
    plug_root = store.PLUGIN_DIR.resolve()
    target = manifest.parent.resolve()
    if plug_root not in target.parents:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "plugin path escapes the plugin directory")

    import shutil

    shutil.rmtree(target, ignore_errors=True)
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════════
# § 4  SNAPSHOTS
# ═══════════════════════════════════════════════════════════════════════════════

@api_router.get("/snapshots", tags=["snapshots"], response_model=list[Snapshot])
async def list_snapshots(limit: Annotated[int, Query(ge=1, le=500)] = 100) -> list[Snapshot]:
    return store.list_snapshots()[:limit]


@api_router.post(
    "/snapshots",
    tags=["snapshots"],
    response_model=Snapshot,
    status_code=status.HTTP_201_CREATED,
)
async def create_snapshot(body: SnapshotCreate) -> Snapshot:
    return store.create_snapshot(body.label)


@api_router.post("/snapshots/{snapshot_id}/restore", tags=["snapshots"])
async def restore_snapshot(snapshot_id: str) -> dict[str, Any]:
    snap = next((s for s in store.list_snapshots() if s.id == snapshot_id), None)
    if not snap:
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no snapshot with id {snapshot_id!r}")
    if not snap.restorable:
        raise HTTPException(status.HTTP_409_CONFLICT, f"snapshot {snapshot_id!r} is not restorable")

    # Take a safety net first: restoring is the one irreversible-looking action
    # in the API, and an operator who restores the wrong snapshot needs a way
    # back out.
    store.create_snapshot(f"pre-restore-{snapshot_id}", trigger="pre-rollback")

    stdout, stderr, code = store.run_ash(["snapshot", "restore", snapshot_id], timeout=300)

    # A record this API created is a metadata restore point: it carries no
    # config payload for the CLI to replay, so a CLI failure is not a failure
    # to restore. For CLI-owned snapshots the exit code is the real answer.
    if not snap.managed and code not in (0, 127):
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            f"restore failed (exit {code}): {stderr.strip()[:400]}",
        )

    if snap.managed:
        store._ensure_dirs()  # noqa: SLF001
        (store.STATE_DIR / "restored").write_text(snapshot_id + "\n", encoding="utf-8")

    return {
        "ok": True,
        "snapshot": snapshot_id,
        "managed": snap.managed,
        "cli_code": code,
    }


@api_router.delete("/snapshots/{snapshot_id}", tags=["snapshots"])
async def delete_snapshot(snapshot_id: str) -> dict[str, bool]:
    if not store.delete_snapshot(snapshot_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, f"no snapshot with id {snapshot_id!r}")
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════════
# § 5  MODES
# ═══════════════════════════════════════════════════════════════════════════════

@api_router.get("/modes", tags=["modes"], response_model=list[Mode])
async def list_modes() -> list[Mode]:
    return store.list_modes()


@api_router.post("/modes/{mode_id}", tags=["modes"])
async def set_mode(mode_id: str) -> dict[str, Any]:
    if not store.set_mode(mode_id):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            f"unknown mode {mode_id!r}; valid modes: {', '.join(m['id'] for m in store.MODES)}",
        )
    return {"ok": True, "mode": mode_id}


# ═══════════════════════════════════════════════════════════════════════════════
# § 6  SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

@api_router.get("/system/hardware", tags=["system"])
async def hardware() -> dict[str, Any]:
    return store.hardware_info()


@api_router.get("/system/metrics", tags=["system"], response_model=list[MetricPoint])
async def metrics(samples: Annotated[int, Query(ge=2, le=600)] = 60) -> list[MetricPoint]:
    return store.current_metrics(samples)


@api_router.get("/system/doctor", tags=["system"], response_model=DoctorReport)
async def doctor() -> DoctorReport:
    return store.doctor_report()


@api_router.get("/system/logs", tags=["system"], response_model=list[LogEntry])
async def logs(
    limit: Annotated[int, Query(ge=1, le=2000)] = 300,
    level: str | None = None,
    scope: str | None = None,
) -> list[LogEntry]:
    entries = store.recent_logs(limit)
    if level:
        entries = [e for e in entries if e.level == level]
    if scope:
        entries = [e for e in entries if e.scope == scope]
    return entries


@api_router.post("/command", tags=["system"], response_model=CommandResult)
async def run_command(body: CommandRequest) -> CommandResult:
    """Execute an allow-listed command. See store.run_command for the policy."""
    stdout, stderr, code = store.run_command(body.command)
    return CommandResult(stdout=stdout, stderr=stderr, code=code)


# ═══════════════════════════════════════════════════════════════════════════════
# § 7  CONFIG
# ═══════════════════════════════════════════════════════════════════════════════

@api_router.get("/config", tags=["config"], summary="Effective configuration")
async def get_config() -> dict[str, Any]:
    return {
        "paths": {
            "root": str(store.ROOT),
            "themes": str(store.THEME_DIR),
            "plugins": str(store.PLUGIN_DIR),
            "snapshots": str(store.SNAPSHOT_DIR),
            "state": str(store.STATE_DIR),
        },
        "counts": {
            "themes": len(store.list_themes()),
            "plugins": len(store.list_plugins()),
            "snapshots": len(store.list_snapshots()),
        },
    }


@api_router.get("/config/validate", tags=["config"], summary="Validate the configuration tree")
async def validate_config() -> dict[str, Any]:
    """Report structural problems rather than raising — callers want a list."""
    problems: list[dict[str, str]] = []

    for theme in store.list_themes():
        try:
            ratio = min_contrast(theme.colors)
        except ValueError as exc:
            problems.append({"kind": "theme", "id": theme.id, "detail": str(exc)})
            continue
        if ratio < 4.5:
            problems.append({
                "kind": "theme", "id": theme.id,
                "detail": f"contrast {ratio:.2f}:1 is below the WCAG AA threshold of 4.5:1",
            })

    for plugin in store.list_plugins():
        missing = _missing_dependencies(plugin.dependencies)
        if missing and plugin.enabled:
            problems.append({
                "kind": "plugin", "id": plugin.id,
                "detail": f"enabled but missing {', '.join(missing)}",
            })

    return {"ok": not problems, "checked": len(store.list_themes()) + len(store.list_plugins()), "problems": problems}
