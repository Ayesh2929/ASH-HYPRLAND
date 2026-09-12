#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/auth.py                                      ║
# ║                                                                               ║
# ║  Bearer-token authentication. Tokens are compared with a constant-time       ║
# ║  comparison so the endpoint cannot be used as a timing oracle, and the       ║
# ║  configured token is never logged or echoed back.                            ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Token authentication for the ASH API."""

from __future__ import annotations

import hmac
import os
import secrets
from pathlib import Path
from typing import Final

from fastapi import Request

#: Name of the environment variable holding the shared secret. A file of the
#: same name (plus a `.token` suffix) is accepted so the secret can live in a
#: 0600 file instead of the process environment.
TOKEN_ENV: Final[str] = "ASH_API_TOKEN"
TOKEN_FILE: Final[Path] = Path(
    os.environ.get("ASH_TOKEN_FILE", Path.home() / ".config" / "ash" / "api.token")
)

#: Minimum length before a configured token is accepted. A four-character
#: secret is worse than no secret, because it produces false confidence.
MIN_TOKEN_LENGTH: Final[int] = 16


def _configured_token() -> str:
    """Resolve the active token from env, then file, then nothing."""
    from_env = os.environ.get(TOKEN_ENV, "").strip()
    if from_env:
        return from_env

    try:
        if TOKEN_FILE.is_file():
            # Refuse a world-readable secret file outright rather than warning:
            # a token someone else can read is not a token.
            mode = TOKEN_FILE.stat().st_mode & 0o077
            if mode:
                import logging

                logging.getLogger("ash.api").warning(
                    "ignoring %s: permissions are %o, expected 600", TOKEN_FILE, mode
                )
                return ""
            return TOKEN_FILE.read_text(encoding="utf-8").strip()
    except OSError:
        return ""

    return ""


#: POST routes that do not mutate state — they are pure computations
#: expressed as POST because they take a body. Auth gates *changes*, so these
#: must stay reachable when no token is configured, or the dashboard's theme
#: generator would silently break on a workstation with auth unset.
#:
#: This is an allow-list, not a heuristic: a new POST route is gated by
#: default and has to be added here deliberately, with the reasoning written
#: down. Getting that order wrong is how write endpoints end up public.
SAFE_POST_PATHS: Final[tuple[str, ...]] = (
    "/api/v1/themes/generate",
)


def is_safe_post(path: str) -> bool:
    """True when a POST to `path` performs no write."""
    # Trailing slashes are equivalent for FastAPI; normalise before matching.
    return path.rstrip("/") in SAFE_POST_PATHS


def is_configured() -> bool:
    """True when a usable token is present."""
    return len(_configured_token()) >= MIN_TOKEN_LENGTH


def describe_mode() -> str:
    """Human-readable auth posture, safe to expose publicly."""
    token = _configured_token()
    if len(token) >= MIN_TOKEN_LENGTH:
        source = "environment" if os.environ.get(TOKEN_ENV) else f"file ({TOKEN_FILE})"
        return f"token required ({source})"
    if token:
        return f"token configured but too short (< {MIN_TOKEN_LENGTH} chars) — ignored"
    return "open for reads, mutations refused"


def extract_token(request: Request) -> str:
    """Pull a bearer token from the Authorization header or X-ASH-Token."""
    header = request.headers.get("authorization", "")
    if header.lower().startswith("bearer "):
        return header[7:].strip()
    return request.headers.get("x-ash-token", "").strip()


def verify(candidate: str | None) -> bool:
    """Constant-time token check.

    `hmac.compare_digest` runs in time independent of how many leading
    characters match, so an attacker cannot recover the token byte by byte by
    measuring response latency.
    """
    if not candidate:
        return False

    expected = _configured_token()
    if len(expected) < MIN_TOKEN_LENGTH:
        return False

    return hmac.compare_digest(candidate, expected)


def generate_token() -> str:
    """Create a 32-byte URL-safe token, suitable for `ash api init`."""
    return secrets.token_urlsafe(32)


def write_token_file(token: str, path: Path = TOKEN_FILE) -> Path:
    """Persist a token with 0600 permissions.

    `os.open` with O_CREAT|O_EXCL and an explicit mode avoids the race where a
    file is briefly world-readable between creation and chmod.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(token + "\n")
    except Exception:
        try:
            path.unlink()
        except OSError:
            pass
        raise
    return path


__all__ = [
    "TOKEN_ENV", "TOKEN_FILE", "MIN_TOKEN_LENGTH", "SAFE_POST_PATHS",
    "is_configured", "is_safe_post", "describe_mode", "extract_token", "verify",
    "generate_token", "write_token_file",
]
