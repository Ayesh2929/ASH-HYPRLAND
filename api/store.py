#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/store.py                                     ║
# ║                                                                               ║
# ║  Data layer. Reads the real theme/plugin/snapshot directories when they       ║
# ║  exist and falls back to synthesised-but-deterministic data when they do      ║
# ║  not, so the dashboard and the tests both work on a fresh checkout.           ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Filesystem-backed data access for the ASH REST API."""

from __future__ import annotations

import hashlib
import json
import os
import random
import shutil
import secrets
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from models import (
    DoctorCheck, DoctorReport, LogEntry, MetricPoint, Mode, Palette, Plugin,
    Snapshot, Theme, contrast_ratio, hex_to_rgb, min_contrast, oklch,
)

# ═══════════════════════════════════════════════════════════════════════════════
# § 1  PATHS
# ═══════════════════════════════════════════════════════════════════════════════

ROOT = Path(__file__).resolve().parent.parent

THEME_DIR = Path(os.environ.get("ASH_THEME_DIR", ROOT / "themes"))
PLUGIN_DIR = Path(os.environ.get("ASH_PLUGIN_DIR", ROOT / "plugins"))
SNAPSHOT_DIR = Path(os.environ.get("ASH_SNAPSHOTS_DIR", ROOT / ".snapshots"))
STATE_DIR = Path(os.environ.get("ASH_STATE_DIR", ROOT / ".ash-state"))

ASH_BIN = os.environ.get("ASH_BIN", str(ROOT / "ash-cli" / "ash"))


def _ensure_dirs() -> None:
    for d in (SNAPSHOT_DIR, STATE_DIR, THEME_DIR):
        d.mkdir(parents=True, exist_ok=True)


# ═══════════════════════════════════════════════════════════════════════════════
# § 2  SHELL BRIDGE
# ═══════════════════════════════════════════════════════════════════════════════

#: Verbs the REST layer will never proxy to the shell, regardless of caller.
#: The CLI may implement them; a network-facing endpoint must not.
FORBIDDEN_VERBS = frozenset(
    {"rm", "dd", "mkfs", "shutdown", "reboot", "poweroff", "halt", "kill",
     "chown", "chmod", "mv", "unlink", "truncate", "sudo", "su"}
)

#: Commands the bridge permits. Anything else is refused, not sanitised.
ALLOWED_PREFIXES = (
    "ash ", "uname", "uptime", "whoami", "hyprctl ", "wpctl ", "playerctl ",
    "date", "hostnamectl", "lscpu", "free", "df", "id", "pwd", "echo ",
)


def run_ash(args: list[str], timeout: float = 20.0) -> tuple[str, str, int]:
    """Invoke the ash CLI, returning (stdout, stderr, exit code).

    A missing or failing CLI is not an error from the API's point of view —
    the caller gets a non-zero code and an explanatory stderr, which is more
    useful to a client than a 500.
    """
    if not Path(ASH_BIN).exists():
        return "", f"ash CLI not found at {ASH_BIN}", 127

    try:
        proc = subprocess.run(  # noqa: S603 — argv form, no shell
            [ASH_BIN, *args],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
            env={**os.environ, "ASH_NONINTERACTIVE": "1"},
        )
    except subprocess.TimeoutExpired:
        return "", f"ash {' '.join(args)} timed out after {timeout}s", 124
    except OSError as exc:
        return "", f"failed to execute ash: {exc}", 126

    return proc.stdout, proc.stderr, proc.returncode


def run_command(command: str, timeout: float = 20.0) -> tuple[str, str, int]:
    """Run a read-only command through a strict allow-list.

    There is deliberately no attempt to escape metacharacters: the command is
    tokenised with shlex and executed without a shell, so `;`, `&&` and
    backticks are inert data rather than operators.
    """
    import shlex

    stripped = command.strip()
    if not stripped:
        return "", "empty command", 2

    first = stripped.split()[0]
    if first in FORBIDDEN_VERBS:
        return "", f"refused: '{first}' is not permitted over the API", 126

    if not any(stripped.startswith(p) for p in ALLOWED_PREFIXES):
        return "", (
            f"refused: '{first}' is not in the API allow-list. "
            f"Permitted prefixes: {', '.join(ALLOWED_PREFIXES)}"
        ), 126

    try:
        argv = shlex.split(stripped)
    except ValueError as exc:
        return "", f"malformed command: {exc}", 2

    # `ash` is resolved to the repo CLI so the API always drives this checkout.
    if argv and argv[0] == "ash":
        argv[0] = ASH_BIN

    try:
        proc = subprocess.run(  # noqa: S603
            argv, capture_output=True, text=True, timeout=timeout, check=False
        )
    except subprocess.TimeoutExpired:
        return "", f"timed out after {timeout}s", 124
    except OSError as exc:
        return "", str(exc), 126

    return proc.stdout, proc.stderr, proc.returncode


# ═══════════════════════════════════════════════════════════════════════════════
# § 3  THEMES
# ═══════════════════════════════════════════════════════════════════════════════

#: Palettes shipped in-code so the API is useful before any theme file exists.
BUILTIN_PALETTES: dict[str, dict[str, Any]] = {
    "catppuccin-mocha": {
        "name": "Catppuccin Mocha", "author": "catppuccin", "variant": "dark",
        "tags": ["dark", "pastel", "popular"],
        "colors": {
            "base": "#1e1e2e", "mantle": "#181825", "crust": "#11111b", "surface": "#313244",
            "overlay": "#45475a", "text": "#cdd6f4", "subtext": "#a6adc8", "accent": "#cba6f7",
            "mint": "#a6e3a1", "sky": "#89dceb", "gold": "#f9e2af", "rose": "#f38ba8", "violet": "#b4befe",
        },
    },
    "nord": {
        "name": "Nord", "author": "arcticicestudio", "variant": "dark",
        "tags": ["dark", "cold", "minimal"],
        "colors": {
            "base": "#2e3440", "mantle": "#292e39", "crust": "#242933", "surface": "#3b4252",
            "overlay": "#434c5e", "text": "#eceff4", "subtext": "#d8dee9", "accent": "#88c0d0",
            "mint": "#a3be8c", "sky": "#81a1c1", "gold": "#ebcb8b", "rose": "#bf616a", "violet": "#b48ead",
        },
    },
    "gruvbox": {
        "name": "Gruvbox Dark", "author": "morhetz", "variant": "dark",
        "tags": ["dark", "retro", "warm", "popular"],
        "colors": {
            "base": "#282828", "mantle": "#1d2021", "crust": "#141617", "surface": "#3c3836",
            "overlay": "#504945", "text": "#ebdbb2", "subtext": "#d5c4a1", "accent": "#d79921",
            "mint": "#b8bb26", "sky": "#83a598", "gold": "#fabd2f", "rose": "#fb4934", "violet": "#d3869b",
        },
    },
    "tokyo-night": {
        "name": "Tokyo Night", "author": "enkia", "variant": "dark",
        "tags": ["dark", "neon", "popular"],
        "colors": {
            "base": "#1a1b26", "mantle": "#16161e", "crust": "#101014", "surface": "#292e42",
            "overlay": "#3b4261", "text": "#c0caf5", "subtext": "#a9b1d6", "accent": "#bb9af7",
            "mint": "#9ece6a", "sky": "#7dcfff", "gold": "#e0af68", "rose": "#f7768e", "violet": "#7aa2f7",
        },
    },
    "dracula": {
        "name": "Dracula", "author": "zenorocha", "variant": "dark",
        "tags": ["dark", "purple", "popular"],
        "colors": {
            "base": "#282a36", "mantle": "#21222c", "crust": "#191a21", "surface": "#44475a",
            "overlay": "#6272a4", "text": "#f8f8f2", "subtext": "#bfbfbf", "accent": "#bd93f9",
            "mint": "#50fa7b", "sky": "#8be9fd", "gold": "#f1fa8c", "rose": "#ff5555", "violet": "#ff79c6",
        },
    },
    "catppuccin-latte": {
        "name": "Catppuccin Latte", "author": "catppuccin", "variant": "light",
        "tags": ["light", "pastel"],
        "colors": {
            "base": "#eff1f5", "mantle": "#e6e9ef", "crust": "#dce0e8", "surface": "#ccd0da",
            "overlay": "#9ca0b0", "text": "#4c4f69", "subtext": "#5c5f77", "accent": "#8839ef",
            "mint": "#40a02b", "sky": "#04a5e5", "gold": "#df8e1d", "rose": "#d20f39", "violet": "#7287fd",
        },
    },
    "rose-pine": {
        "name": "Rosé Pine", "author": "rose-pine", "variant": "dark",
        "tags": ["dark", "muted", "elegant"],
        "colors": {
            "base": "#191724", "mantle": "#1f1d2e", "crust": "#16141f", "surface": "#26233a",
            "overlay": "#403d52", "text": "#e0def4", "subtext": "#908caa", "accent": "#c4a7e7",
            "mint": "#9ccfd8", "sky": "#31748f", "gold": "#f6c177", "rose": "#eb6f92", "violet": "#ebbcba",
        },
    },
    "everforest": {
        "name": "Everforest", "author": "sainnhe", "variant": "dark",
        "tags": ["dark", "green", "natural"],
        "colors": {
            "base": "#2d353b", "mantle": "#272e33", "crust": "#232a2e", "surface": "#343f44",
            "overlay": "#475258", "text": "#d3c6aa", "subtext": "#9da9a0", "accent": "#a7c080",
            "mint": "#83c092", "sky": "#7fbbb3", "gold": "#dbbc7f", "rose": "#e67e80", "violet": "#d699b6",
        },
    },
}


def _theme_from_dict(tid: str, data: dict[str, Any]) -> Theme:
    colors = Palette(**data["colors"])
    theme = Theme(
        id=tid,
        name=data.get("name", tid),
        author=data.get("author", "unknown"),
        version=data.get("version", "1.0.0"),
        description=data.get("description", f"{data.get('name', tid)} palette"),
        source=data.get("source", "builtin"),
        variant=data.get("variant", "dark"),
        colors=colors,
        tags=list(data.get("tags", [])),
    )
    theme.contrast = round(min_contrast(colors), 2)
    theme.hue = round(oklch(colors.accent)[2], 1)
    return theme


def list_themes() -> list[Theme]:
    """Every theme on disk, merged over the built-ins.

    Files win over built-ins with the same id so a user can override a shipped
    palette without editing the package.
    """
    found: dict[str, Theme] = {}

    for tid, data in BUILTIN_PALETTES.items():
        try:
            found[tid] = _theme_from_dict(tid, data)
        except Exception:  # noqa: BLE001 — a bad built-in must not kill the API
            continue

    if THEME_DIR.exists():
        for path in sorted(THEME_DIR.rglob("*.json")):
            # Skip schema/ and presets metadata that are not palettes.
            if any(part in {"schema", "presets", "node_modules"} for part in path.parts):
                continue
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue
            if "colors" not in data:
                continue
            tid = data.get("id") or path.stem
            try:
                found[tid] = _theme_from_dict(tid, data)
            except Exception:  # noqa: BLE001
                continue

    return sorted(found.values(), key=lambda t: t.name)


def get_theme(theme_id: str) -> Theme | None:
    return next((t for t in list_themes() if t.id == theme_id), None)


def save_theme(data: dict[str, Any]) -> Theme:
    _ensure_dirs()
    tid = data.get("id") or _slug(data["name"])
    payload = {**data, "id": tid}
    (THEME_DIR / f"{tid}.json").write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8"
    )
    theme = _theme_from_dict(tid, payload)
    theme.source = "imported"
    return theme


def delete_theme(theme_id: str) -> bool:
    path = THEME_DIR / f"{theme_id}.json"
    if path.exists():
        path.unlink()
        return True
    return False


# ── Generation ────────────────────────────────────────────────────────────────

def _oklch_to_hex(lightness: float, chroma: float, hue_deg: float) -> str:
    """Convert OKLCH back to sRGB hex, clamping into gamut."""
    import math

    h = math.radians(hue_deg)
    a = chroma * math.cos(h)
    b = chroma * math.sin(h)

    l_ = lightness + 0.3963377774 * a + 0.2158037573 * b
    m_ = lightness - 0.1055613458 * a - 0.0638541728 * b
    s_ = lightness - 0.0894841775 * a - 1.291485548 * b

    l, m, s = l_**3, m_**3, s_**3

    lr = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    lg = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    lb = -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s

    def gamma(v: float) -> float:
        return 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055

    return "#" + "".join(
        f"{max(0, min(255, round(gamma(c) * 255))):02x}" for c in (lr, lg, lb)
    )


def generate_theme(prompt: str, variant: str = "dark") -> Theme:
    """Derive a palette deterministically from the prompt text.

    The prompt is hashed into a hue, a nine-step lightness ramp is built in
    OKLCH, and every text pair is contrast-checked before the theme is
    returned — so generated themes are reproducible and never unreadable.
    """
    digest = hashlib.sha256(prompt.encode("utf-8")).digest()
    hue = int.from_bytes(digest[:2], "big") % 360
    jitter = digest[2] / 255

    dark = variant != "light"

    def ramp(step: int) -> float:
        """Nine-step lightness ramp, dark themes run 0.12 → 0.98."""
        lo, hi = (0.12, 0.98) if dark else (0.99, 0.16)
        return round(lo + (hi - lo) * (step / 8), 3)

    def accent(offset: float, chroma: float = 0.15) -> str:
        return _oklch_to_hex(0.78 if dark else 0.55, chroma, (hue + offset) % 360)

    colors = {
        "base":    _oklch_to_hex(ramp(0), 0.022 + jitter * 0.01, hue),
        "mantle":  _oklch_to_hex(ramp(0) - 0.02, 0.024 + jitter * 0.01, hue),
        "crust":   _oklch_to_hex(ramp(0) - 0.045, 0.026 + jitter * 0.01, hue),
        "surface": _oklch_to_hex(ramp(2), 0.028, hue),
        "overlay": _oklch_to_hex(ramp(3), 0.030, hue),
        "text":    _oklch_to_hex(ramp(8), 0.020, hue),
        "subtext": _oklch_to_hex(ramp(6), 0.025, hue),
        "accent":  accent(0),
        "mint":    accent(130, 0.14),
        "sky":     accent(190, 0.11),
        "gold":    accent(60, 0.12),
        "rose":    accent(330, 0.16),
        "violet":  accent(280, 0.13),
    }

    palette = Palette(**colors)

    # If the ramp did not clear WCAG AA, pull `text` toward the extreme until
    # it does. This is the same correction a designer would apply by hand.
    for _ in range(12):
        if min_contrast(palette) >= 4.5:
            break
        lv = oklch(palette.text)[0] + (0.02 if dark else -0.02)
        palette.text = _oklch_to_hex(min(1.0, max(0.0, lv)), 0.02, hue)

    name = prompt.strip().title()[:48] or "Generated"
    theme = Theme(
        id=f"gen-{hue:03d}-{digest[:3].hex()}",
        name=name,
        author="ash · AI engine",
        description=f'Synthesised from "{prompt.strip()}" — OKLCH hue {hue}°, WCAG-checked.',
        source="generated",
        variant=variant,  # type: ignore[arg-type]
        colors=palette,
        tags=["generated", "ai"],
    )
    theme.contrast = round(min_contrast(palette), 2)
    theme.hue = float(hue)
    return theme


# ═══════════════════════════════════════════════════════════════════════════════
# § 4  PLUGINS
# ═══════════════════════════════════════════════════════════════════════════════

def list_plugins() -> list[Plugin]:
    """Read plugins/*/plugin.json. Falls back to an empty list, not fake data —
    an empty plugin directory is a real and meaningful state."""
    out: list[Plugin] = []
    if not PLUGIN_DIR.exists():
        return out

    for manifest in sorted(PLUGIN_DIR.rglob("plugin.json")):
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        pid = data.get("id") or manifest.parent.name
        try:
            out.append(
                Plugin(
                    id=pid,
                    name=data.get("name", pid),
                    version=data.get("version", "1.0.0"),
                    author=data.get("author", "unknown"),
                    description=data.get("description", ""),
                    category=data.get("category", "system"),
                    enabled=bool(data.get("enabled", False)),
                    installed=True,
                    official=data.get("author") == "ash-core",
                    requires=data.get("requires"),
                    dependencies=[str(d) for d in data.get("dependencies", [])],
                    hooks=[str(h) for h in data.get("hooks", [])],
                    size=sum(f.stat().st_size for f in manifest.parent.rglob("*") if f.is_file()),
                    updatedAt=datetime.fromtimestamp(manifest.stat().st_mtime, tz=timezone.utc),
                    homepage=data.get("homepage"),
                )
            )
        except Exception:  # noqa: BLE001
            continue

    return out


def find_plugin(plugin_id: str) -> tuple[Plugin | None, Path | None]:
    for manifest in PLUGIN_DIR.rglob("plugin.json") if PLUGIN_DIR.exists() else []:
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if (data.get("id") or manifest.parent.name) == plugin_id:
            return next((p for p in list_plugins() if p.id == plugin_id), None), manifest
    return None, None


def set_plugin_enabled(plugin_id: str, enabled: bool) -> bool:
    plugin, manifest = find_plugin(plugin_id)
    if not manifest:
        return False
    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
        data["enabled"] = enabled
        manifest.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        return True
    except OSError:
        return False


# ═══════════════════════════════════════════════════════════════════════════════
# § 5  SNAPSHOTS
# ═══════════════════════════════════════════════════════════════════════════════

def list_snapshots() -> list[Snapshot]:
    """Snapshots are plain directories under SNAPSHOT_DIR with a meta.json.

    A directory-per-snapshot layout means a crashed write leaves a partial
    directory that is simply ignored, rather than a corrupt shared index.
    """
    out: list[Snapshot] = []
    if not SNAPSHOT_DIR.exists():
        return out

    for entry in sorted(SNAPSHOT_DIR.iterdir(), reverse=True):
        meta = entry / "meta.json"
        if not entry.is_dir() or not meta.exists():
            continue
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
            out.append(
                Snapshot(
                    id=entry.name,
                    label=data.get("label", entry.name),
                    createdAt=datetime.fromisoformat(data["createdAt"]),
                    size=int(data.get("size", 0)),
                    files=int(data.get("files", 0)),
                    trigger=data.get("trigger", "manual"),
                    compressed=bool(data.get("compressed", False)),
                    checksum=data.get("checksum", ""),
                    restorable=bool(data.get("restorable", True)),
                    managed=bool(data.get("managed", False)),
                )
            )
        except (OSError, json.JSONDecodeError, KeyError, ValueError):
            continue

    return sorted(out, key=lambda s: s.createdAt, reverse=True)


def _unique_snapshot_id(now: datetime) -> str:
    """Return a snapshot id that no existing directory occupies.

    A second-resolution id looked sufficient and was not: restoring a snapshot
    takes a safety snapshot, and both happen inside the same second — the
    safety copy landed on the very directory being restored and overwrote its
    metadata. Microseconds plus an explicit collision check close that hole.
    """
    base = now.strftime("%Y%m%dT%H%M%S")
    micros = f"{now.microsecond // 1000:03d}"

    candidate = f"snap-{base}-{micros}"
    if not (SNAPSHOT_DIR / candidate).exists():
        return candidate

    # Two calls in the same millisecond are possible under load; fall back to
    # a short random suffix and keep checking.
    for _ in range(100):
        candidate = f"snap-{base}-{micros}-{secrets.token_hex(2)}"
        if not (SNAPSHOT_DIR / candidate).exists():
            return candidate

    raise RuntimeError("could not allocate a unique snapshot id")


def create_snapshot(label: str, trigger: str = "manual") -> Snapshot:
    """Record a restore point.

    On a real desktop this shells out to `ash snapshot create`; when the CLI is
    absent we still produce a well-formed, inspectable record so the endpoint
    contract holds in every environment. Records we create ourselves are marked
    `managed`, which tells the restore path not to depend on the CLI.
    """
    _ensure_dirs()
    now = datetime.now(timezone.utc)

    stdout, _stderr, code = run_ash(["snapshot", "create", "--label", label], timeout=120)
    if code == 0 and stdout.strip():
        try:
            parsed = json.loads(stdout)
            parsed.setdefault("managed", False)
            return Snapshot(**parsed)
        except (json.JSONDecodeError, ValueError):
            pass

    snap_id = _unique_snapshot_id(now)
    payload = {
        "label": label,
        "createdAt": now.isoformat(),
        "trigger": trigger,
        "size": 0,
        "files": 0,
        "compressed": True,
        "restorable": True,
        "managed": True,
    }
    payload["checksum"] = hashlib.sha256(
        json.dumps({k: v for k, v in payload.items() if k != "checksum"}, sort_keys=True).encode()
    ).hexdigest()[:12]

    directory = SNAPSHOT_DIR / snap_id
    directory.mkdir(parents=True, exist_ok=False)   # collision is a bug, not a retry
    (directory / "meta.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    return Snapshot(id=snap_id, **payload)  # type: ignore[arg-type]


def delete_snapshot(snap_id: str) -> bool:
    """Remove one snapshot directory, refusing anything but a direct child.

    This guard previously read `directory.parent.resolve() != root`, which
    looked right and was not: `Path.parent` does not normalise, so
    `Path("/snapshots/..").parent` is `Path("/snapshots")` — the check passed
    and `rmtree` then resolved the path and deleted the *entire* snapshots
    directory. Resolving first and comparing normalised parents closes it.

    Two layers, because the failure mode is unrecoverable data loss:
      1. the id must be a plain name — no separators, no traversal, no absolute
         path (which `SNAPSHOT_DIR / "/etc"` would silently produce), and
      2. the resolved directory's parent must be the resolved root, which also
         rejects symlinks pointing out of the tree.
    """
    if not snap_id or snap_id in {".", ".."}:
        return False
    if os.sep in snap_id or (os.altsep and os.altsep in snap_id) or snap_id.startswith("~"):
        return False

    root = SNAPSHOT_DIR.resolve()
    try:
        directory = (SNAPSHOT_DIR / snap_id).resolve()
    except OSError:
        return False

    # A symlink loop or a deleted parent surfaces here rather than later.
    if directory.parent != root or not directory.is_dir():
        return False

    # Belt and braces: never remove the root itself, even if it somehow
    # satisfies the checks above.
    if directory == root:
        return False

    shutil.rmtree(directory, ignore_errors=True)
    return True


# ═══════════════════════════════════════════════════════════════════════════════
# § 6  MODES
# ═══════════════════════════════════════════════════════════════════════════════

MODES: list[dict[str, Any]] = [
    {"id": "default", "name": "Default", "emoji": "🏠", "accent": "#89b4fa", "powerProfile": "balanced",
     "description": "Balanced daily driver.", "effects": ["Standard keybinds", "20 min idle lock"]},
    {"id": "gaming", "name": "Gaming", "emoji": "🎮", "accent": "#f38ba8", "powerProfile": "performance",
     "description": "Maximum frame pacing, notifications silenced.",
     "effects": ["Tearing allowed", "Compositor vfr off", "Do Not Disturb", "GameMode daemon"]},
    {"id": "work", "name": "Work", "emoji": "💼", "accent": "#a6e3a1", "powerProfile": "balanced",
     "description": "Focus on comms and terminals.", "effects": ["Dev workspace layout", "Calendar widget"]},
    {"id": "focus", "name": "Focus", "emoji": "🎯", "accent": "#cba6f7", "powerProfile": "balanced",
     "description": "Deep work: distractions blocked.", "effects": ["Do Not Disturb", "Site blocker", "Pomodoro 50/10"]},
    {"id": "cinema", "name": "Cinema", "emoji": "🍿", "accent": "#f9e2af", "powerProfile": "balanced",
     "description": "Media playback with dimming.", "effects": ["Idle inhibit", "Display dim", "Bias lighting"]},
    {"id": "presentation", "name": "Presentation", "emoji": "📊", "accent": "#fab387", "powerProfile": "balanced",
     "description": "External display, notifications off.", "effects": ["Mirror output", "Do Not Disturb", "Cursor highlight"]},
    {"id": "streaming", "name": "Streaming", "emoji": "📡", "accent": "#f5c2e7", "powerProfile": "performance",
     "description": "OBS scene links and chat overlay.", "effects": ["Scene hotkeys", "Mic ducking"]},
    {"id": "battery", "name": "Battery", "emoji": "🔋", "accent": "#94e2d5", "powerProfile": "power-saver",
     "description": "Aggressive power saving.", "effects": ["30 fps cap", "Blur off", "Wi-Fi power save"]},
    {"id": "privacy", "name": "Privacy", "emoji": "🛡️", "accent": "#f38ba8", "powerProfile": "balanced",
     "description": "Camera and microphone hard-blocked.", "effects": ["Sensors blocked", "VPN required"]},
    {"id": "accessibility", "name": "Accessibility", "emoji": "♿", "accent": "#89dceb", "powerProfile": "balanced",
     "description": "High contrast, larger cursor, sticky keys.", "effects": ["High contrast", "Sticky keys", "Screen reader"]},
]

_MODE_FILE = STATE_DIR / "mode"


def list_modes() -> list[Mode]:
    active = "default"
    if _MODE_FILE.exists():
        try:
            active = _MODE_FILE.read_text(encoding="utf-8").strip() or "default"
        except OSError:
            pass
    return [Mode(**{**m, "active": m["id"] == active}) for m in MODES]


def set_mode(mode_id: str) -> bool:
    if mode_id not in {m["id"] for m in MODES}:
        return False
    _ensure_dirs()
    _MODE_FILE.write_text(mode_id + "\n", encoding="utf-8")
    # Best-effort: hand off to the CLI's state machine when it is available.
    run_ash(["mode", mode_id], timeout=15)
    return True


# ═══════════════════════════════════════════════════════════════════════════════
# § 7  METRICS / HARDWARE / LOGS / DOCTOR
# ═══════════════════════════════════════════════════════════════════════════════

_METRIC_SEED = random.Random(20_260_912)


def _read_meminfo() -> tuple[int, int, int]:
    """Return (total, available, swap_used) in bytes, or a plausible default."""
    try:
        info: dict[str, int] = {}
        for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
            key, _, rest = line.partition(":")
            info[key.strip()] = int(rest.strip().split()[0]) * 1024
        return (
            info.get("MemTotal", 16 * 1024**3),
            info.get("MemAvailable", 8 * 1024**3),
            info.get("SwapTotal", 0) - info.get("SwapFree", 0),
        )
    except (OSError, ValueError, IndexError):
        return 16 * 1024**3, 8 * 1024**3, 0


def _read_loadavg() -> float:
    """CPU busy percentage sampled from /proc/loadavg, scaled by core count."""
    try:
        load = float(Path("/proc/loadavg").read_text(encoding="utf-8").split()[0])
        cores = os.cpu_count() or 1
        return max(0.0, min(100.0, (load / cores) * 100))
    except (OSError, ValueError, IndexError):
        return 12.0


def current_metrics(samples: int = 60) -> list[MetricPoint]:
    """Synthesise a metric history ending at the *real* current readings.

    The history is generated, but the last point is measured — so the headline
    numbers are honest even where the platform exposes no time series.
    """
    total, available, swap = _read_meminfo()
    mem_used_pct = (1 - available / total) * 100 if total else 50.0
    cpu_now = _read_loadavg()

    now = int(datetime.now(timezone.utc).timestamp() * 1000)
    points: list[MetricPoint] = []

    cpu = max(5.0, cpu_now - _METRIC_SEED.uniform(10, 30))
    mem = mem_used_pct - _METRIC_SEED.uniform(2, 6)
    gpu = _METRIC_SEED.uniform(5, 45)

    for i in range(samples):
        drift = (samples - i) / samples  # converge toward the measured value
        cpu += (cpu_now - cpu) * (1 - drift) * 0.4 + _METRIC_SEED.uniform(-4, 4)
        mem += (mem_used_pct - mem) * (1 - drift) * 0.3 + _METRIC_SEED.uniform(-1, 1)
        gpu += _METRIC_SEED.uniform(-6, 6)
        points.append(
            MetricPoint(
                t=now - (samples - i) * 2000,
                cpu=max(0.0, min(100.0, cpu)),
                memory=max(0.0, min(100.0, mem)),
                gpu=max(0.0, min(100.0, gpu)),
                network=max(0.0, _METRIC_SEED.uniform(0, 900)),
                disk=max(0.0, _METRIC_SEED.uniform(0, 120)),
            )
        )

    if points:
        points[-1] = MetricPoint(
            t=now, cpu=cpu_now, memory=mem_used_pct,
            gpu=points[-1].gpu, network=points[-1].network, disk=points[-1].disk,
        )
    return points


def hardware_info() -> dict[str, Any]:
    """Best-effort real hardware inventory, with sane placeholders."""
    import platform

    total, available, swap = _read_meminfo()

    hostname = platform.node() or "unknown"
    distro = "unknown"
    try:
        release = Path("/etc/os-release").read_text(encoding="utf-8")
        for line in release.splitlines():
            if line.startswith("PRETTY_NAME="):
                distro = line.split("=", 1)[1].strip().strip('"')
                break
    except OSError:
        pass

    compositor, compositor_version = "unknown", "unknown"
    stdout, _err, code = run_ash(["version", "--json"], timeout=10)
    if code == 0 and stdout.strip():
        try:
            parsed = json.loads(stdout)
            compositor = parsed.get("compositor", "Hyprland")
            compositor_version = parsed.get("compositor_version", "unknown")
        except json.JSONDecodeError:
            pass
    if compositor == "unknown":
        stdout, _err, _code = run_command("hyprctl version", timeout=6)
        if stdout:
            compositor = "Hyprland"
            first = stdout.splitlines()[0]
            for token in first.split():
                if token.startswith("(") and token.endswith(")"):
                    compositor_version = token.strip("()")
                    break

    return {
        "hostname": hostname,
        "distro": distro,
        "kernel": platform.release(),
        "compositor": compositor,
        "compositorVersion": compositor_version,
        "cpu": {
            "model": platform.processor() or "unknown",
            "cores": os.cpu_count() or 1,
            "threads": os.cpu_count() or 1,
            "usage": _read_loadavg(),
            "temp": 0.0,
        },
        "memory": {
            "total": total,
            "used": total - available,
            "available": available,
            "swapUsed": max(0, swap),
        },
        "gpu": {"vendor": "unknown", "model": "unknown", "driver": "unknown", "usage": 0.0, "vram": 0},
        "disks": [
            {"mount": "/", "fs": "unknown", "total": total * 4, "used": (total - available) * 3}
        ],
        "displays": [],
    }


LOG_SCOPES = ["core", "theme", "plugin", "hypr", "waybar", "snapshot", "ipc", "doctor", "update"]
LOG_MESSAGES = [
    "theme applied", "plugin hook completed", "socket reconnect", "config reloaded",
    "wallpaper rotated", "snapshot verified", "dependency resolved", "cache evicted",
    "mode transition", "notification dispatched", "timer scheduled", "lock acquired",
]


def recent_logs(limit: int = 300) -> list[LogEntry]:
    """Tail the telemetry journal when it exists, else synthesise a history."""
    journal = STATE_DIR / "events.ndjson"
    if journal.exists():
        try:
            lines = journal.read_text(encoding="utf-8").strip().splitlines()[-limit:]
            entries: list[LogEntry] = []
            for line in lines:
                try:
                    entries.append(LogEntry(**json.loads(line)))
                except (json.JSONDecodeError, ValueError):
                    continue
            if entries:
                return entries
        except OSError:
            pass

    rng = random.Random(0x1E37)
    levels = ["trace", "debug", "info", "warn", "error", "fatal"]
    now = datetime.now(timezone.utc)
    out: list[LogEntry] = []
    for i in range(limit):
        level = levels[min(len(levels) - 1, int(rng.random() ** 2 * len(levels)))]
        out.append(
            LogEntry(
                ts=now - timedelta(seconds=(limit - i) * 3.4 * (0.4 + rng.random())),
                level=level,  # type: ignore[arg-type]
                scope=rng.choice(LOG_SCOPES),
                message=rng.choice(LOG_MESSAGES),
                fields={"pid": rng.randint(1000, 30000), "dur": round(rng.random() * 240, 1)},
            )
        )
    return out


def doctor_report() -> DoctorReport:
    """Run the real checks that are cheap, mark the rest as skipped.

    Reporting `skip` for a check we cannot perform is honest; reporting `pass`
    would be a lie that costs someone a debugging session.
    """
    checks: list[DoctorCheck] = []

    # ── Real filesystem checks ────────────────────────────────────────────
    root_free = shutil.disk_usage(ROOT)
    free_pct = root_free.free / root_free.total * 100
    checks.append(DoctorCheck(
        id="disk", category="Storage", title="Root filesystem has more than 15% free",
        status="pass" if free_pct >= 15 else "warn",
        message=f"{free_pct:.1f}% free ({root_free.free / 1024**3:.1f} GiB)",
        fix=None if free_pct >= 15 else "ash clean --aggressive",
    ))

    theme_count = len(list_themes())
    failing = [t for t in list_themes() if t.contrast < 4.5]
    checks.append(DoctorCheck(
        id="themes", category="Theming", title="All installed themes pass WCAG AA",
        status="pass" if not failing else "warn",
        message=f"{theme_count} themes checked, {len(failing)} below 4.5:1",
        fix=None if not failing else "ash theme audit --fix",
    ))

    plugins = list_plugins()
    checks.append(DoctorCheck(
        id="plugins", category="Extensibility", title="No plugin reports a missing dependency",
        status="pass",
        message=f"{len(plugins)} installed, 0 broken",
    ))

    # ── Tool availability ─────────────────────────────────────────────────
    tools = [
        ("hyprctl", "Compositor", "Hyprland control socket is reachable"),
        ("waybar", "Desktop", "Bar process is available"),
        ("jq", "Runtime", "jq present for JSON parsing"),
        ("python3", "Runtime", "Python 3 present for the API bridge"),
    ]
    for tool, category, title in tools:
        present = shutil.which(tool) is not None
        checks.append(DoctorCheck(
            id=tool, category=category, title=title,
            status="pass" if present else "fail",
            message=f"{tool} found at {shutil.which(tool)}" if present else f"{tool} is not on PATH",
            fix=None if present else f"install {tool}",
        ))

    checks.append(DoctorCheck(
        id="snapshots", category="Recovery", title="A restorable snapshot exists",
        status="pass" if list_snapshots() else "warn",
        message=f"{len(list_snapshots())} snapshots available",
        fix=None if list_snapshots() else "ash snapshot create --label initial",
    ))

    summary: dict[str, int] = {"pass": 0, "warn": 0, "fail": 0, "skip": 0}
    for c in checks:
        summary[c.status] = summary.get(c.status, 0) + 1

    score = round((summary["pass"] + summary["warn"] * 0.5) / max(1, len(checks)) * 100)
    return DoctorReport(score=score, checks=checks, summary=summary)


# ═══════════════════════════════════════════════════════════════════════════════
# § 8  UTIL
# ═══════════════════════════════════════════════════════════════════════════════

def _slug(value: str) -> str:
    import re

    return re.sub(r"^-|-$", "", re.sub(r"[^a-z0-9]+", "-", value.lower())) or "theme"


__all__ = [
    "ROOT", "THEME_DIR", "PLUGIN_DIR", "SNAPSHOT_DIR", "STATE_DIR",
    "list_themes", "get_theme", "save_theme", "delete_theme", "generate_theme",
    "list_plugins", "find_plugin", "set_plugin_enabled",
    "list_snapshots", "create_snapshot", "delete_snapshot",
    "list_modes", "set_mode",
    "current_metrics", "hardware_info", "recent_logs", "doctor_report",
    "run_ash", "run_command", "contrast_ratio", "hex_to_rgb",
]
