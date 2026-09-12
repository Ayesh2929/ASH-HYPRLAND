#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/tests/test-system-api.py                      ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""System, mode, snapshot and command-bridge contract tests."""

from __future__ import annotations

import pytest

pytestmark = pytest.mark.usefixtures("client")


class TestMeta:
    def test_ping(self, client):
        assert client.get("/api/v1/ping").json()["pong"] is True

    def test_version_names_the_release(self, client):
        assert client.get("/api/v1/version").json()["ash"] == "5.0.0-omega"

    def test_health_reports_auth_posture(self, client):
        body = client.get("/health").json()
        assert body["status"] == "ok"
        assert "auth" in body


class TestMetrics:
    def test_returns_the_requested_window(self, client):
        assert len(client.get("/api/v1/system/metrics?=60".replace("?=", "?samples=")).json()) == 60

    def test_values_are_bounded_percentages(self, client):
        for p in client.get("/api/v1/system/metrics?samples=30").json():
            assert 0 <= p["cpu"] <= 100
            assert 0 <= p["memory"] <= 100
            assert 0 <= p["gpu"] <= 100

    def test_timestamps_are_ordered(self, client):
        ts = [p["t"] for p in client.get("/api/v1/system/metrics?samples=20").json()]
        assert ts == sorted(ts)

    def test_rejects_out_of_range_samples(self, client):
        assert client.get("/api/v1/system/metrics?samples=0").status_code == 422
        assert client.get("/api/v1/system/metrics?samples=99999").status_code == 422


class TestHardware:
    def test_reports_required_sections(self, client):
        body = client.get("/api/v1/system/hardware").json()
        for key in ("hostname", "kernel", "cpu", "memory", "disks"):
            assert key in body, f"missing {key}"

    def test_memory_is_internally_consistent(self, client):
        mem = client.get("/api/v1/system/hardware").json()["memory"]
        assert mem["used"] + mem["available"] <= mem["total"] * 1.01


class TestDoctor:
    def test_produces_a_score_and_checks(self, client):
        body = client.get("/api/v1/system/doctor").json()
        assert 0 <= body["score"] <= 100
        assert body["checks"]

    def test_summary_matches_the_checks(self, client):
        body = client.get("/api/v1/system/doctor").json()
        counted: dict[str, int] = {}
        for c in body["checks"]:
            counted[c["status"]] = counted.get(c["status"], 0) + 1
        # The summary always carries all four keys (the dashboard renders a
        # fixed legend), so compare against a zero-filled baseline.
        expected = {"pass": 0, "warn": 0, "fail": 0, "skip": 0, **counted}
        assert body["summary"] == expected
        assert sum(body["summary"].values()) == len(body["checks"])

    def test_failures_carry_a_fix(self, client):
        for c in client.get("/api/v1/system/doctor").json()["checks"]:
            if c["status"] in {"warn", "fail"}:
                assert c["fix"], f"{c['id']} reports a problem with no remedy"


class TestModes:
    def test_lists_all_ten_modes(self, client):
        modes = client.get("/api/v1/modes").json()
        assert len(modes) == 10

    def test_exactly_one_mode_is_active(self, client):
        assert sum(1 for m in client.get("/api/v1/modes").json() if m["active"]) == 1

    def test_setting_a_mode_persists(self, client):
        assert client.post("/api/v1/modes/focus").status_code == 200
        active = [m for m in client.get("/api/v1/modes").json() if m["active"]]
        assert [m["id"] for m in active] == ["focus"]

    def test_unknown_mode_is_404(self, client):
        assert client.post("/api/v1/modes/hyperdrive").status_code == 404


class TestSnapshots:
    def test_create_list_restore_delete(self, client):
        created = client.post("/api/v1/snapshots", json={"label": "api-test"})
        assert created.status_code == 201
        sid = created.json()["id"]

        assert any(s["id"] == sid for s in client.get("/api/v1/snapshots").json())
        assert client.post(f"/api/v1/snapshots/{sid}/restore").status_code == 200
        assert client.delete(f"/api/v1/snapshots/{sid}").status_code == 200
        assert not any(s["id"] == sid for s in client.get("/api/v1/snapshots").json())

    def test_restore_takes_a_safety_snapshot(self, client):
        sid = client.post("/api/v1/snapshots", json={"label": "safety-src"}).json()["id"]
        before = len(client.get("/api/v1/snapshots").json())
        client.post(f"/api/v1/snapshots/{sid}/restore")
        after = client.get("/api/v1/snapshots").json()
        assert len(after) >= before
        assert any("pre-restore" in s["label"] for s in after)

    def test_rejects_empty_label(self, client):
        assert client.post("/api/v1/snapshots", json={"label": ""}).status_code == 422

    def test_unknown_snapshot_is_404(self, client):
        assert client.delete("/api/v1/snapshots/nope").status_code == 404
        assert client.post("/api/v1/snapshots/nope/restore").status_code == 404

    def test_path_traversal_cannot_succeed_over_http(self, client):
        """A traversal id must never return a success status.

        Starlette normalises `..` out of the path before routing, so these
        land on a 404/405 rather than reaching the handler — which is the
        right outcome. What matters is that none of them report success.
        """
        for evil in ("..", "../../etc", "..%2f..%2fetc", "....//....//etc"):
            r = client.delete(f"/api/v1/snapshots/{evil}")
            assert r.status_code not in {200, 204}, f"{evil} unexpectedly succeeded"

    def test_delete_snapshot_refuses_a_traversing_id(self, _isolated_state):
        """The store is the last line of defence, so test it directly.

        `delete_snapshot` must only ever remove a direct child of
        ASH_SNAPSHOTS_DIR. Calling it directly bypasses URL normalisation and
        exercises the guard itself.
        """
        import store

        sentinel = _isolated_state / "snapshots" / "keepme"
        sentinel.mkdir(parents=True, exist_ok=True)
        (sentinel / "meta.json").write_text("{}", encoding="utf-8")

        for evil in ("../themes", "..", "../../etc", "keepme/../../themes"):
            assert store.delete_snapshot(evil) is False, f"{evil} was accepted"

        assert sentinel.is_dir(), "a legitimate sibling snapshot was removed"
        assert store.delete_snapshot("keepme") is True


class TestCommandBridge:
    def test_allow_listed_command_runs(self, client):
        r = client.post("/api/v1/command", json={"command": "uname -a"}).json()
        assert r["code"] == 0
        assert r["stdout"]

    def test_shell_metacharacters_do_not_spawn_a_second_process(self, client, tmp_path):
        """Metacharacters must be data, never operators.

        `echo` is allow-listed, so the command runs. The proof that the shell
        was never involved is a canary file that would exist had the `;`
        separated two commands.
        """
        canary = tmp_path / "ash-pwned"
        assert not canary.exists()

        r = client.post(
            "/api/v1/command",
            json={"command": f"echo hi; touch {canary}"},
        ).json()

        assert r["code"] == 0, r
        assert not canary.exists(), "the payload after ';' was executed"

    def test_ampersand_does_not_chain_commands(self, client, tmp_path):
        canary = tmp_path / "ash-pwned-2"
        client.post("/api/v1/command", json={"command": f"echo a && touch {canary}"})
        assert not canary.exists()

    def test_command_substitution_is_inert(self, client, tmp_path):
        canary = tmp_path / "ash-pwned-3"
        client.post("/api/v1/command", json={"command": f"echo $(touch {canary})"})
        assert not canary.exists()

    def test_backticks_are_inert(self, client, tmp_path):
        canary = tmp_path / "ash-pwned-4"
        client.post("/api/v1/command", json={"command": f"echo `touch {canary}`"})
        assert not canary.exists()

    @pytest.mark.parametrize("cmd", ["rm -rf /", "dd if=/dev/zero of=/dev/sda", "mkfs.ext4 /dev/sda1", "sudo su"])
    def test_destructive_commands_are_refused(self, client, cmd):
        r = client.post("/api/v1/command", json={"command": cmd}).json()
        assert r["code"] == 126

    def test_unknown_binary_is_refused(self, client):
        r = client.post("/api/v1/command", json={"command": "curl http://evil.example"}).json()
        assert r["code"] == 126
        assert "allow-list" in r["stderr"]

    def test_empty_command_is_rejected(self, client):
        assert client.post("/api/v1/command", json={"command": ""}).status_code == 422


class TestConfig:
    def test_reports_paths_and_counts(self, client):
        body = client.get("/api/v1/config").json()
        assert {"paths", "counts"} <= set(body)
        assert body["counts"]["themes"] >= 8

    def test_validate_returns_structured_problems(self, client, palette):
        client.post("/api/v1/themes", json={
            "id": "low-contrast", "name": "Low", "colors": {**palette, "text": "#1f1f2f"},
        })
        body = client.get("/api/v1/config/validate").json()
        assert "problems" in body and "ok" in body
        client.delete("/api/v1/themes/low-contrast")


class TestLogs:
    def test_respects_limit(self, client):
        assert len(client.get("/api/v1/system/logs?limit=25").json()) == 25

    def test_level_filter(self, client):
        for entry in client.get("/api/v1/system/logs?limit=200&level=error").json():
            assert entry["level"] == "error"

    def test_scope_filter(self, client):
        for entry in client.get("/api/v1/system/logs?limit=200&scope=theme").json():
            assert entry["scope"] == "theme"
