#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/tests/test-theme-api.py                       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Theme endpoint contract tests."""

from __future__ import annotations

import pytest

pytestmark = pytest.mark.usefixtures("client")


class TestThemeList:
    def test_returns_builtins(self, client):
        r = client.get("/api/v1/themes")
        assert r.status_code == 200
        assert len(r.json()) >= 8

    def test_every_theme_carries_derived_metrics(self, client):
        for t in client.get("/api/v1/themes").json():
            assert t["contrast"] > 0, f"{t['id']} has no contrast"
            assert 0 <= t["hue"] < 360, f"{t['id']} has an out-of-range hue"

    def test_variant_filter(self, client):
        r = client.get("/api/v1/themes?variant=light")
        assert r.status_code == 200
        assert r.json(), "expected at least one light theme"
        assert all(t["variant"] == "light" for t in r.json())

    def test_contrast_filter_excludes_low_contrast(self, client):
        r = client.get("/api/v1/themes?min_contrast_ratio=7")
        assert r.status_code == 200
        assert all(t["contrast"] >= 7 for t in r.json())

    def test_rejects_out_of_range_contrast(self, client):
        assert client.get("/api/v1/themes?min_contrast_ratio=99").status_code == 422

    def test_rejects_unknown_variant(self, client):
        assert client.get("/api/v1/themes?variant=neon").status_code == 422


class TestThemeRead:
    def test_get_by_id(self, client):
        r = client.get("/api/v1/themes/catppuccin-mocha")
        assert r.status_code == 200
        assert r.json()["name"] == "Catppuccin Mocha"

    def test_unknown_id_is_404(self, client):
        assert client.get("/api/v1/themes/does-not-exist").status_code == 404


class TestThemeAudit:
    def test_reports_ratios_and_grade(self, client):
        r = client.get("/api/v1/themes/nord/audit")
        assert r.status_code == 200
        body = r.json()
        assert body["minimum"] > 1
        assert body["grade"] in {"AAA", "AA", "AA-large", "fail"}
        assert body["passes_aa"] is (body["minimum"] >= 4.5)

    def test_audit_404s_for_unknown(self, client):
        assert client.get("/api/v1/themes/ghost/audit").status_code == 404


class TestThemeGenerate:
    def test_generates_a_palette(self, client):
        r = client.post("/api/v1/themes/generate", json={"prompt": "warm autumn dusk"})
        assert r.status_code == 200
        assert set(r.json()["colors"]) == {
            "base", "mantle", "crust", "surface", "overlay", "text", "subtext",
            "accent", "mint", "sky", "gold", "rose", "violet",
        }

    def test_is_deterministic(self, client):
        a = client.post("/api/v1/themes/generate", json={"prompt": "ocean depth"}).json()
        b = client.post("/api/v1/themes/generate", json={"prompt": "ocean depth"}).json()
        assert a["colors"] == b["colors"]
        assert a["id"] == b["id"]

    def test_different_prompts_differ(self, client):
        a = client.post("/api/v1/themes/generate", json={"prompt": "ocean depth"}).json()
        b = client.post("/api/v1/themes/generate", json={"prompt": "desert noon"}).json()
        assert a["colors"] != b["colors"]

    def test_generated_theme_meets_wcag_aa(self, client):
        r = client.post("/api/v1/themes/generate", json={"prompt": "muted moss"})
        assert r.json()["contrast"] >= 4.5

    def test_rejects_empty_prompt(self, client):
        assert client.post("/api/v1/themes/generate", json={"prompt": ""}).status_code == 422

    def test_rejects_overlong_prompt(self, client):
        r = client.post("/api/v1/themes/generate", json={"prompt": "x" * 500})
        assert r.status_code == 422


class TestThemeWrite:
    def test_create_then_read_then_delete(self, client, palette):
        r = client.post("/api/v1/themes", json={"id": "crud-test", "name": "CRUD", "colors": palette})
        assert r.status_code == 201
        assert client.get("/api/v1/themes/crud-test").status_code == 200
        assert client.delete("/api/v1/themes/crud-test").status_code == 200
        assert client.get("/api/v1/themes/crud-test").status_code == 404

    def test_rejects_malformed_hex(self, client, palette):
        bad = {**palette, "accent": "not-a-colour"}
        r = client.post("/api/v1/themes", json={"name": "Bad", "colors": bad})
        assert r.status_code == 422

    def test_rejects_incomplete_palette(self, client, palette):
        partial = {k: v for k, v in palette.items() if k != "violet"}
        r = client.post("/api/v1/themes", json={"name": "Partial", "colors": partial})
        assert r.status_code == 422

    def test_builtins_cannot_be_deleted(self, client):
        assert client.delete("/api/v1/themes/nord").status_code == 404

    def test_apply_records_the_selection(self, client):
        r = client.post("/api/v1/themes/gruvbox/apply")
        assert r.status_code == 200
        assert r.json()["theme"] == "gruvbox"

    def test_apply_404s_for_unknown(self, client):
        assert client.post("/api/v1/themes/nonexistent/apply").status_code == 404
