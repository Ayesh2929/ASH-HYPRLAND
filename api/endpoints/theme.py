#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/endpoints/theme.py
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""Deprecated namespace for the theme endpoints.

The routes themselves live in api/routes.py; import from there. This module
exists only so that from api.endpoints.theme import theme_router keeps resolving
for integrations written against the pre-1.0 layout.
"""

from __future__ import annotations

from fastapi import APIRouter

#: Kept for backwards compatibility. Always empty — the real router is
#: api.routes.api_router, mounted by the application factory.
theme_router = APIRouter()

__all__ = ["theme_router"]
