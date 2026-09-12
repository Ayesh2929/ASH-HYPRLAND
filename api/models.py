#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/models.py                                    ║
# ║                                                                               ║
# ║  Pydantic contracts shared by every route. These are the single source of     ║
# ║  truth for the wire format — api/openapi.yaml is generated from them, and     ║
# ║  web/src/lib/types.ts mirrors them field for field.                          ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Request/response models for the ASH REST API."""

from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

HEX_RE = re.compile(r"^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$")


def _now() -> datetime:
    return datetime.now(timezone.utc)


# ═══════════════════════════════════════════════════════════════════════════════
# § 1  THEME
# ═══════════════════════════════════════════════════════════════════════════════

class Palette(BaseModel):
    """The 13-slot colour contract every theme must satisfy.

    Slots are validated as hex so a malformed theme is rejected at the edge
    rather than producing an unreadable desktop three layers deeper.
    """

    model_config = ConfigDict(extra="forbid")

    base: str
    mantle: str
    crust: str
    surface: str
    overlay: str
    text: str
    subtext: str
    accent: str
    mint: str
    sky: str
    gold: str
    rose: str
    violet: str

    @field_validator("*")
    @classmethod
    def _check_hex(cls, v: str) -> str:
        if not HEX_RE.match(v):
            raise ValueError(f"not a hex colour: {v!r}")
        return v.lower()


class Theme(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    name: str
    author: str = "unknown"
    version: str = "1.0.0"
    description: str = ""
    source: Literal["builtin", "generated", "imported", "marketplace"] = "builtin"
    variant: Literal["dark", "light"] = "dark"
    colors: Palette
    tags: list[str] = Field(default_factory=list)
    contrast: float = 0.0
    hue: float = 0.0
    downloads: int | None = None
    rating: float | None = None
    installedAt: datetime | None = None  # noqa: N815 — matches the TS client

    @field_validator("version")
    @classmethod
    def _check_version(cls, v: str) -> str:
        if not SEMVER_RE.match(v):
            raise ValueError(f"not a semver version: {v!r}")
        return v

    @model_validator(mode="after")
    def _fill_derived(self) -> "Theme":
        """Fill contrast/hue when the caller did not supply them.

        Theme files on disk only carry colours; deriving the metrics here keeps
        them off the authoring surface and guarantees they are consistent with
        whatever the palette actually is.
        """
        if not self.contrast:
            self.contrast = round(min_contrast(self.colors), 2)
        if not self.hue:
            self.hue = round(oklch(self.colors.accent)[2], 1)
        return self


class ThemeCreate(BaseModel):
    """Body for POST /themes."""

    model_config = ConfigDict(extra="ignore")

    id: str | None = None
    name: str
    author: str = "user"
    version: str = "1.0.0"
    description: str = ""
    variant: Literal["dark", "light"] = "dark"
    colors: Palette
    tags: list[str] = Field(default_factory=list)


class ThemeGenerate(BaseModel):
    prompt: str = Field(min_length=1, max_length=400)
    variant: Literal["dark", "light"] = "dark"


# ═══════════════════════════════════════════════════════════════════════════════
# § 2  PLUGIN
# ═══════════════════════════════════════════════════════════════════════════════

PluginCategory = Literal["productivity", "appearance", "system", "integration", "fun", "security"]


class PluginDependency(BaseModel):
    name: str
    version: str = ">=0.0.0"
    optional: bool = False


class Plugin(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    name: str
    version: str = "1.0.0"
    author: str = "unknown"
    description: str = ""
    category: PluginCategory = "system"
    enabled: bool = False
    installed: bool = False
    official: bool = False
    requires: str | None = None
    dependencies: list[str] = Field(default_factory=list)
    hooks: list[str] = Field(default_factory=list)
    size: int = 0
    updatedAt: datetime = Field(default_factory=_now)  # noqa: N815
    homepage: str | None = None


# ═══════════════════════════════════════════════════════════════════════════════
# § 3  SNAPSHOT
# ═══════════════════════════════════════════════════════════════════════════════

class Snapshot(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    label: str
    createdAt: datetime  # noqa: N815
    size: int = 0
    files: int = 0
    trigger: Literal["manual", "auto", "pre-update", "pre-rollback"] = "manual"
    compressed: bool = False
    checksum: str = ""
    restorable: bool = True
    #: True when this API created the record itself, i.e. it is a metadata
    #: restore point rather than one materialised by the ash CLI. Restoring a
    #: managed snapshot must not fail just because the CLI is unavailable.
    managed: bool = False


class SnapshotCreate(BaseModel):
    label: str = Field(min_length=1, max_length=120)


# ═══════════════════════════════════════════════════════════════════════════════
# § 4  MODE
# ═══════════════════════════════════════════════════════════════════════════════

ModeId = Literal[
    "default", "gaming", "work", "focus", "cinema",
    "presentation", "streaming", "battery", "privacy", "accessibility",
]


class Mode(BaseModel):
    id: ModeId
    name: str
    emoji: str = "🏠"
    description: str = ""
    accent: str = "#89b4fa"
    active: bool = False
    effects: list[str] = Field(default_factory=list)
    powerProfile: Literal["power-saver", "balanced", "performance"] = "balanced"  # noqa: N815


# ═══════════════════════════════════════════════════════════════════════════════
# § 5  SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

class MetricPoint(BaseModel):
    t: int
    cpu: float
    memory: float
    gpu: float
    network: float
    disk: float


class DoctorCheck(BaseModel):
    id: str
    category: str
    title: str
    status: Literal["pass", "warn", "fail", "skip"]
    message: str
    fix: str | None = None


class DoctorReport(BaseModel):
    generatedAt: datetime = Field(default_factory=_now)  # noqa: N815
    score: int = 0
    checks: list[DoctorCheck] = Field(default_factory=list)
    summary: dict[str, int] = Field(default_factory=dict)


class LogEntry(BaseModel):
    ts: datetime = Field(default_factory=_now)
    level: Literal["trace", "debug", "info", "warn", "error", "fatal"] = "info"
    scope: str = "core"
    message: str = ""
    fields: dict[str, Any] | None = None


class CommandRequest(BaseModel):
    """Body for POST /command.

    `command` is the only field, and the server allow-lists the leading verb —
    a REST endpoint that runs arbitrary shell is a remote code execution
    service, not an API.
    """

    command: str = Field(min_length=1, max_length=512)


class CommandResult(BaseModel):
    stdout: str = ""
    stderr: str = ""
    code: int = 0


# ═══════════════════════════════════════════════════════════════════════════════
# § 6  COLOUR MATHS
# ═══════════════════════════════════════════════════════════════════════════════

def hex_to_rgb(value: str) -> tuple[int, int, int]:
    """Parse #rgb / #rrggbb / #rrggbbaa into an (r, g, b) tuple."""
    h = value.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) == 8:
        h = h[:6]
    if len(h) != 6:
        raise ValueError(f"bad hex colour: {value!r}")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def _linearise(channel: int) -> float:
    s = channel / 255
    return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4


def luminance(value: str) -> float:
    """WCAG 2.1 relative luminance."""
    r, g, b = hex_to_rgb(value)
    return 0.2126 * _linearise(r) + 0.7152 * _linearise(g) + 0.0722 * _linearise(b)


def contrast_ratio(a: str, b: str) -> float:
    """WCAG 2.1 contrast ratio, 1.0 → 21.0."""
    la, lb = luminance(a), luminance(b)
    hi, lo = (la, lb) if la > lb else (lb, la)
    return (hi + 0.05) / (lo + 0.05)


def min_contrast(palette: Palette) -> float:
    """Worst text-on-background ratio in a palette.

    Reporting the minimum rather than the mean means a theme cannot pass by
    averaging away one unreadable label.
    """
    return min(
        contrast_ratio(palette.text, palette.base),
        contrast_ratio(palette.subtext, palette.base),
        contrast_ratio(palette.accent, palette.base),
    )


def oklch(value: str) -> tuple[float, float, float]:
    """Convert sRGB hex to OKLCH (L, C, h°)."""
    import math

    def lin(c: int) -> float:
        s = c / 255
        return s / 12.92 if s <= 0.04045 else ((s + 0.055) / 1.055) ** 2.4

    r, g, b = (lin(c) for c in hex_to_rgb(value))

    l_ = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m_ = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)

    ll = 0.2104542553 * l_ + 0.793617785 * m_ - 0.0040720468 * s_
    aa = 1.9779984951 * l_ - 2.428592205 * m_ + 0.4505937099 * s_
    bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.808675766 * s_

    c = math.hypot(aa, bb)
    h = math.degrees(math.atan2(bb, aa)) % 360
    return ll, c, h
