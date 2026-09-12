#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/tests/conftest.py                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Shared fixtures for the API test suite.

Each test run gets its own state directory, so tests never read or write the
developer's real themes, plugins or snapshots.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

API_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(API_DIR))

# Redirect all mutable state into a temp tree *before* store is imported —
# store resolves its paths at import time.
_TMP_STATE = Path(os.environ.get("PYTEST_TMP_STATE", "/tmp/ash-api-tests"))


@pytest.fixture(scope="session", autouse=True)
def _isolated_state() -> Path:
    state = _TMP_STATE
    for sub in ("themes", "plugins", "snapshots", "state"):
        (state / sub).mkdir(parents=True, exist_ok=True)
    os.environ["ASH_THEME_DIR"] = str(state / "themes")
    os.environ["ASH_PLUGIN_DIR"] = str(state / "plugins")
    os.environ["ASH_SNAPSHOTS_DIR"] = str(state / "snapshots")
    os.environ["ASH_STATE_DIR"] = str(state / "state")
    return state


@pytest.fixture()
def client(_isolated_state: Path):
    """A TestClient with authentication enabled.

    Mutations require a token by design, so the default client authenticates —
    tests that specifically cover the unauthenticated posture use `anon_client`.
    """
    from fastapi.testclient import TestClient

    os.environ["ASH_API_TOKEN"] = "test-token-" + "x" * 24
    import server

    with TestClient(server.app, raise_server_exceptions=False) as c:
        c.headers.update({"Authorization": f"Bearer {os.environ['ASH_API_TOKEN']}"})
        yield c


@pytest.fixture()
def anon_client(_isolated_state: Path):
    """A TestClient with no token configured — the open-read posture."""
    from fastapi.testclient import TestClient

    os.environ.pop("ASH_API_TOKEN", None)
    import server

    with TestClient(server.app, raise_server_exceptions=False) as c:
        yield c


@pytest.fixture()
def palette() -> dict[str, str]:
    """A known-good palette for request bodies."""
    return {
        "base": "#1e1e2e", "mantle": "#181825", "crust": "#11111b", "surface": "#313244",
        "overlay": "#45475a", "text": "#cdd6f4", "subtext": "#a6adc8", "accent": "#cba6f7",
        "mint": "#a6e3a1", "sky": "#89dceb", "gold": "#f9e2af", "rose": "#f38ba8", "violet": "#b4befe",
    }
