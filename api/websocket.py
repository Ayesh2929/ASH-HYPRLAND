#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║  ⚡ ASH DOTFILES v5.0 OMEGA — api/websocket.py                                  ║
# ║                                                                               ║
# ║  Live telemetry socket. Streams metric samples, journal entries and          ║
# ║  notifications to every connected dashboard.                                  ║
# ║                                                                               ║
# ║  Design notes:                                                                ║
# ║   • One sampling loop feeds all clients — N clients do not mean N× the        ║
# ║     work, which matters on a laptop where this runs next to a compositor.    ║
# ║   • Slow clients are dropped, never awaited: a stalled browser tab must       ║
# ║     not back-pressure the sampler.                                            ║
# ║   • Each connection has a bounded queue. Memory cannot grow without limit.    ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
"""WebSocket transport for live metrics and events."""

from __future__ import annotations

import asyncio
import contextlib
import json
import logging
import time
from typing import Any

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

import store

ws_router = APIRouter()
log = logging.getLogger("ash.api.ws")

#: Per-connection backlog. Beyond this, the oldest frame is discarded — for
#: telemetry, fresh data beats complete data.
MAX_QUEUE = 32

#: Sampling cadence in seconds.
SAMPLE_INTERVAL = 2.0

#: How often a log line is emitted alongside metrics (fraction of samples).
LOG_EVERY = 3


class Hub:
    """Fan-out broker: one producer, many consumers, no shared event loop work."""

    def __init__(self) -> None:
        self._clients: set[asyncio.Queue[dict[str, Any]]] = set()
        self._task: asyncio.Task[None] | None = None
        self._lock = asyncio.Lock()
        self._log_counter = 0

    async def subscribe(self) -> asyncio.Queue[dict[str, Any]]:
        queue: asyncio.Queue[dict[str, Any]] = asyncio.Queue(maxsize=MAX_QUEUE)
        async with self._lock:
            self._clients.add(queue)
            if self._task is None or self._task.done():
                self._task = asyncio.create_task(self._run())
                log.info("telemetry sampler started (%d clients)", len(self._clients))
        return queue

    async def unsubscribe(self, queue: asyncio.Queue[dict[str, Any]]) -> None:
        async with self._lock:
            self._clients.discard(queue)
            if not self._clients and self._task is not None:
                # Stop sampling when nobody is listening — the dashesboard is
                # often closed while this process keeps running.
                self._task.cancel()
                self._task = None
                log.info("telemetry sampler stopped (no clients)")

    def _broadcast(self, message: dict[str, Any]) -> None:
        """Non-blocking fan-out. A full queue loses its oldest frame."""
        for queue in self._clients:
            if queue.full():
                with contextlib.suppress(asyncio.QueueEmpty):
                    queue.get_nowait()
            with contextlib.suppress(asyncio.QueueFull):
                queue.put_nowait(message)

    async def _run(self) -> None:
        """Sample system state and broadcast, forever (until cancelled)."""
        try:
            while True:
                metrics = store.current_metrics(samples=2)
                point = metrics[-1].model_dump()
                self._broadcast({"type": "metrics", "ts": int(time.time() * 1000), "payload": point})

                self._log_counter += 1
                if self._log_counter % LOG_EVERY == 0:
                    entries = store.recent_logs(1)
                    if entries:
                        self._broadcast({
                            "type": "log",
                            "ts": int(time.time() * 1000),
                            "payload": entries[-1].model_dump(mode="json"),
                        })

                await asyncio.sleep(SAMPLE_INTERVAL)
        except asyncio.CancelledError:
            raise
        except Exception:  # noqa: BLE001
            log.exception("telemetry sampler crashed; it will restart on next subscribe")


hub = Hub()


@ws_router.websocket("/ws")
async def telemetry_socket(websocket: WebSocket) -> None:
    """Bidirectional telemetry channel.

    The client may send `{"type":"ping"}` for a liveness check or
    `{"type":"subscribe","topics":[...]}` to narrow what it receives. Every
    frame received is validated; malformed frames get an error reply rather
    than closing the socket, so a buggy client can self-correct.
    """
    await websocket.accept()
    queue = await hub.subscribe()

    await websocket.send_text(json.dumps({
        "type": "hello",
        "ts": int(time.time() * 1000),
        "payload": {
            "version": "5.0.0-omega",
            "interval": SAMPLE_INTERVAL,
            "topics": ["metrics", "log", "notification"],
        },
    }))

    topics: set[str] | None = None

    async def pump_out() -> None:
        """Forward queued frames to the socket."""
        while True:
            message = await queue.get()
            if topics is not None and message.get("type") not in topics:
                continue
            await websocket.send_text(json.dumps(message, default=str))

    async def pump_in() -> None:
        """Handle client frames until the socket closes."""
        nonlocal topics
        while True:
            raw = await websocket.receive_text()
            try:
                frame = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error", "ts": int(time.time() * 1000),
                    "payload": {"detail": "frames must be JSON"},
                }))
                continue

            kind = frame.get("type")
            if kind == "ping":
                await websocket.send_text(json.dumps({
                    "type": "pong", "ts": int(time.time() * 1000), "payload": frame.get("payload"),
                }))
            elif kind == "subscribe":
                requested = frame.get("topics")
                valid = {"metrics", "log", "notification", "plugin", "theme", "snapshot"}
                if isinstance(requested, list) and all(t in valid for t in requested):
                    topics = set(requested) or None
                    await websocket.send_text(json.dumps({
                        "type": "subscribed", "ts": int(time.time() * 1000),
                        "payload": {"topics": sorted(topics) if topics else sorted(valid)},
                    }))
                else:
                    await websocket.send_text(json.dumps({
                        "type": "error", "ts": int(time.time() * 1000),
                        "payload": {"detail": f"invalid topics; expected a subset of {sorted(valid)}"},
                    }))
            else:
                await websocket.send_text(json.dumps({
                    "type": "error", "ts": int(time.time() * 1000),
                    "payload": {"detail": f"unknown frame type: {kind!r}"},
                }))

    out_task = asyncio.create_task(pump_out())
    in_task = asyncio.create_task(pump_in())

    try:
        done, pending = await asyncio.wait(
            {out_task, in_task}, return_when=asyncio.FIRST_COMPLETED
        )
        for task in pending:
            task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await task
        # Surface a genuine failure rather than swallowing it.
        for task in done:
            exc = task.exception()
            if exc and not isinstance(exc, (WebSocketDisconnect, asyncio.CancelledError)):
                raise exc
    except WebSocketDisconnect:
        pass
    finally:
        out_task.cancel()
        in_task.cancel()
        await hub.unsubscribe(queue)
        with contextlib.suppress(RuntimeError):
            await websocket.close()


__all__ = ["ws_router", "hub"]
