#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/tests/test-auth.py                            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Authentication, and the read/write posture when no token is set."""

from __future__ import annotations

import os

import pytest


class TestNoTokenConfigured:
    """With no token: reads are open, writes are refused."""

    def test_reads_are_allowed(self, anon_client):
        assert anon_client.get("/api/v1/themes").status_code == 200
        assert anon_client.get("/api/v1/modes").status_code == 200
        assert anon_client.get("/api/v1/system/hardware").status_code == 200

    def test_writes_are_refused(self, anon_client):
        r = anon_client.post("/api/v1/modes/gaming")
        assert r.status_code == 403
        assert "ASH_API_TOKEN" in r.json()["detail"]

    def test_destructive_writes_are_refused(self, anon_client):
        assert anon_client.post("/api/v1/snapshots", json={"label": "x"}).status_code == 403
        assert anon_client.delete("/api/v1/themes/nord").status_code == 403

    def test_pure_computation_post_is_allowed(self, anon_client):
        # Generating a palette writes nothing, so it must not need a token.
        r = anon_client.post("/api/v1/themes/generate", json={"prompt": "quiet"})
        assert r.status_code == 200

    def test_mode_description_is_honest(self, anon_client):
        import auth

        assert "open for reads" in auth.describe_mode()

    def test_health_is_always_reachable(self, anon_client):
        assert anon_client.get("/health").status_code == 200


class TestTokenConfigured:
    def test_missing_token_is_401(self, client):
        r = client.get("/api/v1/themes", headers={"Authorization": ""})
        assert r.status_code == 401
        assert r.headers.get("www-authenticate") == "Bearer"

    def test_wrong_token_is_401(self, client):
        r = client.get("/api/v1/themes", headers={"Authorization": "Bearer wrong"})
        assert r.status_code == 401

    def test_correct_bearer_token_works(self, client):
        r = client.get(
            "/api/v1/themes",
            headers={"Authorization": f"Bearer {os.environ['ASH_API_TOKEN']}"},
        )
        assert r.status_code == 200

    def test_alternate_header_works(self, client):
        r = client.get("/api/v1/themes", headers={"X-ASH-Token": os.environ["ASH_API_TOKEN"]})
        assert r.status_code == 200

    def test_bearer_prefix_is_case_insensitive(self, client):
        r = client.get(
            "/api/v1/themes",
            headers={"Authorization": f"bearer {os.environ['ASH_API_TOKEN']}"},
        )
        assert r.status_code == 200


class TestTokenPolicy:
    def test_short_token_is_ignored(self, monkeypatch):
        import auth

        monkeypatch.setenv("ASH_API_TOKEN", "short")
        assert not auth.is_configured()
        assert "too short" in auth.describe_mode()

    def test_long_token_activates_auth(self, monkeypatch):
        import auth

        monkeypatch.setenv("ASH_API_TOKEN", "y" * 40)
        assert auth.is_configured()

    def test_verify_is_constant_time_and_strict(self, monkeypatch):
        import auth

        monkeypatch.setenv("ASH_API_TOKEN", "z" * 32)
        assert auth.verify("z" * 32) is True
        # A prefix must not pass.
        assert auth.verify("z" * 31) is False
        assert auth.verify("") is False
        assert auth.verify(None) is False

    def test_generate_token_is_long_and_unique(self):
        import auth

        tokens = {auth.generate_token() for _ in range(20)}
        assert len(tokens) == 20
        assert all(len(t) >= 32 for t in tokens)

    def test_safe_post_allow_list_normalises_trailing_slash(self):
        import auth

        assert auth.is_safe_post("/api/v1/themes/generate")
        assert auth.is_safe_post("/api/v1/themes/generate/")
        # A write route must not be considered safe.
        assert not auth.is_safe_post("/api/v1/snapshots")
