#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/server.py                                    ║
# ║                                                                               ║
# ║  FastAPI application factory and ASGI entrypoint for the REST + WebSocket     ║
# ║  bridge that the web dashboard talks to.                                      ║
# ║                                                                               ║
# ║  Run:  python3 api/server.py            (dev, binds 0.0.0.0:8787)             ║
# ║        uvicorn api.server:app --host 0.0.0.0 --port 8787                      ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""ASH REST API — application factory, middleware and entrypoint."""

from __future__ import annotations

import logging
import os
import sys
import time
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, AsyncIterator

# Allow `python3 api/server.py` to resolve the sibling modules without the
# caller having to set PYTHONPATH or install the package.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fastapi import FastAPI, Request, status  # noqa: E402
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402
from fastapi.responses import JSONResponse, FileResponse  # noqa: E402
from fastapi.staticfiles import StaticFiles  # noqa: E402

import auth  # noqa: E402
import store  # noqa: E402
from routes import api_router  # noqa: E402
from websocket import ws_router  # noqa: E402

VERSION = "5.0.0-omega"
STARTED_AT = time.time()

log = logging.getLogger("ash.api")


# ═══════════════════════════════════════════════════════════════════════════════
# § 1  LIFESPAN
# ═══════════════════════════════════════════════════════════════════════════════

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Prepare directories and log the token posture before serving.

    Printing the auth mode at boot means a misconfigured deployment is visible
    in the logs rather than discovered by whoever finds the open port.
    """
    store.STATE_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=os.environ.get("ASH_LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s  %(levelname)-7s %(name)s  %(message)s",
        datefmt="%H:%M:%S",
    )
    log.info("ASH API %s starting", VERSION)
    log.info("auth: %s", auth.describe_mode())
    log.info("themes: %s", store.THEME_DIR)
    log.info("plugins: %s", store.PLUGIN_DIR)
    log.info("snapshots: %s", store.SNAPSHOT_DIR)
    yield
    log.info("ASH API stopping")


# ═══════════════════════════════════════════════════════════════════════════════
# § 2  APP
# ═══════════════════════════════════════════════════════════════════════════════

def create_app() -> FastAPI:
    app = FastAPI(
        title="ASH Dotfiles API",
        description=(
            "Control surface for the ASH desktop environment. Exposes themes, "
            "plugins, snapshots, modes and live telemetry to the web dashboard "
            "and to third-party integrations."
        ),
        version=VERSION,
        lifespan=lifespan,
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json",
    )

    # ── CORS ─────────────────────────────────────────────────────────────
    # The dashboard proxies /api through Vite, so in practice requests are
    # same-origin. These origins cover direct/dev access. A wildcard is
    # deliberately NOT used: the API mutates state.
    origins = os.environ.get(
        "ASH_CORS_ORIGINS",
        "http://localhost:5173,http://127.0.0.1:5173,"
        "http://localhost:4173,http://127.0.0.1:4173,"
        "http://localhost:8787,http://127.0.0.1:8787",
    ).split(",")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=[o.strip() for o in origins if o.strip()],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "X-ASH-Token"],
    )

    # ── Timing header ────────────────────────────────────────────────────
    @app.middleware("http")
    async def add_timing(request: Request, call_next: Any) -> Any:
        """Attach a server-timing header so slow routes are visible in devtools."""
        start = time.perf_counter()
        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000
        response.headers["Server-Timing"] = f"app;dur={elapsed_ms:.1f}"
        response.headers["X-ASH-Version"] = VERSION
        return response

    # ── Auth ─────────────────────────────────────────────────────────────
    @app.middleware("http")
    async def enforce_auth(request: Request, call_next: Any) -> Any:
        """Reject unauthenticated mutations, and any request when a token is set.

        Reads stay open when no token is configured — that is what makes the
        dashboard work out of the box on a workstation. The moment
        ASH_API_TOKEN is set, every route is protected.
        """
        path = request.url.path
        if path.startswith(("/api/docs", "/api/redoc", "/api/openapi.json")) or path == "/health":
            return await call_next(request)

        if not auth.is_configured():
            # No token: allow reads, refuse writes. An unauthenticated LAN
            # listener must not be able to delete snapshots.
            if request.method not in {"GET", "HEAD", "OPTIONS"} and not auth.is_safe_post(path):
                return JSONResponse(
                    status_code=status.HTTP_403_FORBIDDEN,
                    content={
                        "detail": (
                            "Mutations require authentication. Set ASH_API_TOKEN to "
                            "enable them, then send it as 'Authorization: Bearer <token>'."
                        )
                    },
                )
            return await call_next(request)

        token = auth.extract_token(request)
        if not auth.verify(token):
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"detail": "invalid or missing API token"},
                headers={"WWW-Authenticate": "Bearer"},
            )
        return await call_next(request)

    # ── Error shape ──────────────────────────────────────────────────────
    @app.exception_handler(Exception)
    async def unhandled(request: Request, exc: Exception) -> JSONResponse:
        """One error envelope for every failure, so clients parse one shape.

        `exc` is logged but never returned: stack traces leak paths and
        library versions to whoever is probing the port.
        """
        log.exception("unhandled error on %s %s", request.method, request.url.path)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "detail": "internal server error",
                "type": exc.__class__.__name__,
                "path": request.url.path,
            },
        )

    # ── Routes ───────────────────────────────────────────────────────────
    app.include_router(api_router, prefix="/api/v1")
    app.include_router(ws_router, prefix="/api/v1")

    @app.get("/health", tags=["meta"], summary="Liveness probe")
    async def health() -> dict[str, Any]:
        return {
            "status": "ok",
            "version": VERSION,
            "uptime": int(time.time() - STARTED_AT),
            "auth": auth.describe_mode(),
        }

    # ── Dashboard static hosting ─────────────────────────────────────────
    # When `npm run build` has produced web/dist we serve it directly, which
    # makes a single `python3 api/server.py` enough to run the whole product.
    dist = Path(__file__).resolve().parent.parent / "web" / "dist"
    if dist.is_dir():
        app.mount("/assets", StaticFiles(directory=dist / "assets"), name="assets")

        @app.get("/{full_path:path}", include_in_schema=False)
        async def serve_dashboard(full_path: str) -> Any:
            """Serve the built SPA, falling back to index.html for client routes."""
            candidate = (dist / full_path).resolve()
            # Containment check: a crafted path must not escape dist/.
            if full_path and candidate.is_file() and dist.resolve() in candidate.parents:
                return FileResponse(candidate)
            return FileResponse(dist / "index.html")

    return app


app = create_app()


# ═══════════════════════════════════════════════════════════════════════════════
# § 3  ENTRYPOINT
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> int:
    try:
        import uvicorn
    except ImportError:
        print(
            "uvicorn is required to run the API server.\n"
            "  python3 -m venv .venv && .venv/bin/pip install -r api/requirements.txt",
            file=sys.stderr,
        )
        return 1

    host = os.environ.get("ASH_HOST", "0.0.0.0")
    port = int(os.environ.get("ASH_PORT", "8787"))

    print(f"⚡ ASH API {VERSION}  →  http://{host}:{port}")
    print(f"   docs  →  http://{host}:{port}/api/docs")
    print(f"   auth  →  {auth.describe_mode()}")

    uvicorn.run(
        "server:app",
        host=host,
        port=port,
        reload=os.environ.get("ASH_RELOAD", "0") == "1",
        log_level=os.environ.get("ASH_LOG_LEVEL", "info").lower(),
        access_log=os.environ.get("ASH_ACCESS_LOG", "1") == "1",
        # The bundled CLI shells out to subprocesses; a worker count above one
        # would race on the state directory.
        workers=1,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
