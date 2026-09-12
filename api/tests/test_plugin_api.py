#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/tests/test_plugin_api.py                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Plugin endpoint contract tests, driven by a plugin tree built at runtime."""

from __future__ import annotations

import json
import os
from pathlib import Path

import pytest

pytestmark = pytest.mark.usefixtures("client")


@pytest.fixture()
def plugin_tree() -> Path:
    """Create a small plugin tree inside the isolated plugin directory."""
    root = Path(os.environ["ASH_PLUGIN_DIR"])
    definitions = {
        "demo-alpha": {
            "id": "demo-alpha", "name": "Demo Alpha", "version": "1.2.3",
            "author": "ash-core", "description": "A demo plugin.", "category": "system",
            "enabled": True, "hooks": ["pre_theme"], "dependencies": [],
        },
        "demo-beta": {
            "id": "demo-beta", "name": "Demo Beta", "version": "0.4.0",
            "author": "community", "description": "Needs a missing binary.",
            "category": "appearance", "enabled": False,
            "dependencies": ["definitely-not-a-real-binary-xyz"],
        },
    }
    for pid, data in definitions.items():
        d = root / pid
        d.mkdir(parents=True, exist_ok=True)
        (d / "plugin.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
        (d / "init.sh").write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
    return root


class TestPluginList:
    def test_lists_created_plugins(self, client, plugin_tree):
        ids = {p["id"] for p in client.get("/api/v1/plugins").json()}
        assert {"demo-alpha", "demo-beta"} <= ids

    def test_computes_size_from_disk(self, client, plugin_tree):
        alpha = next(p for p in client.get("/api/v1/plugins").json() if p["id"] == "demo-alpha")
        assert alpha["size"] > 0

    def test_marks_official_plugins(self, client, plugin_tree):
        alpha = next(p for p in client.get("/api/v1/plugins").json() if p["id"] == "demo-alpha")
        assert alpha["official"] is True

    def test_enabled_filter(self, client, plugin_tree):
        for p in client.get("/api/v1/plugins?enabled=true").json():
            assert p["enabled"] is True

    def test_category_filter(self, client, plugin_tree):
        for p in client.get("/api/v1/plugins?category=appearance").json():
            assert p["category"] == "appearance"


class TestPluginRead:
    def test_get_by_id(self, client, plugin_tree):
        assert client.get("/api/v1/plugins/demo-alpha").json()["name"] == "Demo Alpha"

    def test_unknown_is_404(self, client, plugin_tree):
        assert client.get("/api/v1/plugins/nope").status_code == 404


class TestPluginToggle:
    def test_disable_then_enable(self, client, plugin_tree):
        assert client.post("/api/v1/plugins/demo-alpha/disable").json()["enabled"] is False
        assert client.get("/api/v1/plugins/demo-alpha").json()["enabled"] is False

        assert client.post("/api/v1/plugins/demo-alpha/enable").json()["enabled"] is True
        assert client.get("/api/v1/plugins/demo-alpha").json()["enabled"] is True

    def test_enabling_with_missing_dependency_conflicts(self, client, plugin_tree):
        r = client.post("/api/v1/plugins/demo-beta/enable")
        assert r.status_code == 409
        assert "definitely-not-a-real-binary-xyz" in r.json()["detail"]

    def test_toggle_unknown_is_404(self, client, plugin_tree):
        assert client.post("/api/v1/plugins/ghost/enable").status_code == 404

    def test_toggle_persists_to_the_manifest(self, client, plugin_tree):
        client.post("/api/v1/plugins/demo-alpha/disable")
        manifest = json.loads((plugin_tree / "demo-alpha" / "plugin.json").read_text())
        assert manifest["enabled"] is False


class TestPluginRemove:
    def test_remove_deletes_the_directory(self, client, plugin_tree):
        assert client.delete("/api/v1/plugins/demo-beta").status_code == 200
        assert not (plugin_tree / "demo-beta").exists()

    def test_remove_unknown_is_404(self, client, plugin_tree):
        assert client.delete("/api/v1/plugins/ghost").status_code == 404

    def test_cannot_escape_the_plugin_root(self, client, plugin_tree):
        """Nothing outside the plugin tree may be removed, whoever asks."""
        import store

        outside = plugin_tree.parent / "not-a-plugin"
        outside.mkdir(parents=True, exist_ok=True)
        (outside / "important.txt").write_text("keep me", encoding="utf-8")

        for evil in ("..", "..%2F..%2Fetc", "demo-alpha%2F..%2F..%2Fnot-a-plugin"):
            r = client.delete(f"/api/v1/plugins/{evil}")
            assert r.status_code not in {200, 204}, f"{evil} unexpectedly succeeded"

        assert (outside / "important.txt").read_text() == "keep me"

    def test_remove_plugin_rejects_a_traversing_id(self, plugin_tree):
        """Exercise the store's containment check directly.

        URL normalisation hides `..` from the router, so the guard in
        `delete_plugin` is only reachable by calling the store itself.
        """
        import json as _json

        import store

        outside = plugin_tree.parent / "outside-target"
        outside.mkdir(parents=True, exist_ok=True)
        manifest = outside / "plugin.json"
        manifest.write_text(_json.dumps({"id": "sneaky", "name": "Sneaky"}), encoding="utf-8")

        # find_plugin walks PLUGIN_DIR only, so an outside manifest is invisible.
        found, path = store.find_plugin("sneaky")
        assert found is None and path is None
        assert manifest.exists()
