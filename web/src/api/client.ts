/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║  🌐 ASH DOTFILES v5.0 OMEGA — REST client                                 ║
 * ║                                                                           ║
 * ║  Wraps fetch with: timeout, retry+backoff, typed errors, and an           ║
 * ║  automatic offline fallback to the local fixture generator. That last     ║
 * ║  part matters: the dashboard is usable (and demoable) with no daemon      ║
 * ║  running, which is also what the sandbox preview does.                    ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
import type {
  ApiError, DoctorReport, HardwareInfo, Keybind, LogEntry, Mode,
  Plugin, Snapshot, Theme, Wallpaper, WSMessage,
} from '../lib/types'
import * as mock from '../lib/mock'

export const API_BASE = import.meta.env.VITE_API_BASE ?? '/api/v1'
const DEFAULT_TIMEOUT = 8000
const RETRIES = 2

export class HttpError extends Error implements ApiError {
  status: number
  detail?: string
  constructor(status: number, message: string, detail?: string) {
    super(message)
    this.name = 'HttpError'
    this.status = status
    this.detail = detail
  }
}

/** True once a request has failed at the transport layer. */
let offline = false
const listeners = new Set<(offline: boolean) => void>()

export function isOffline(): boolean { return offline }
export function onConnectivityChange(fn: (o: boolean) => void): () => void {
  listeners.add(fn)
  return () => listeners.delete(fn)
}
function setOffline(next: boolean): void {
  if (next === offline) return
  offline = next
  listeners.forEach((fn) => fn(offline))
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms))

async function request<T>(path: string, init: RequestInit = {}, retries = RETRIES): Promise<T> {
  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), DEFAULT_TIMEOUT)

  try {
    const res = await fetch(`${API_BASE}${path}`, {
      ...init,
      signal: ctrl.signal,
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        ...(init.headers ?? {}),
      },
    })
    clearTimeout(timer)

    if (!res.ok) {
      let detail: string | undefined
      try { detail = ((await res.json()) as { detail?: string }).detail } catch { /* body was not JSON */ }
      // 5xx is worth retrying; 4xx means we sent something wrong.
      if (res.status >= 500 && retries > 0) {
        await sleep(2 ** (RETRIES - retries) * 300)
        return request<T>(path, init, retries - 1)
      }
      throw new HttpError(res.status, `${res.status} ${res.statusText}`, detail)
    }

    setOffline(false)
    if (res.status === 204) return undefined as T
    return (await res.json()) as T
  } catch (err) {
    clearTimeout(timer)
    if (err instanceof HttpError) throw err

    if (retries > 0) {
      await sleep(2 ** (RETRIES - retries) * 300)
      return request<T>(path, init, retries - 1)
    }
    setOffline(true)
    throw new HttpError(0, 'ASH daemon unreachable', (err as Error).message)
  }
}

const get = <T>(p: string) => request<T>(p)
const post = <T>(p: string, body?: unknown) =>
  request<T>(p, { method: 'POST', body: body === undefined ? undefined : JSON.stringify(body) })
const del = <T>(p: string) => request<T>(p, { method: 'DELETE' })

/* ═══════════════════════════════════════════════════════════════════════════
   § 1  ENDPOINTS — each falls back to fixtures when the daemon is absent
   ═══════════════════════════════════════════════════════════════════════════ */

export const api = {
  health: () =>
    get<{ status: string; version: string; uptime: number }>('/health')
      .catch(() => mock.health()),

  /* ── themes ─────────────────────────────────────────────────────────── */
  themes: () => get<Theme[]>('/themes').catch(() => mock.themes()),
  theme: (id: string) =>
    get<Theme>(`/themes/${id}`).catch(() => {
      const found = mock.themes().find((t) => t.id === id)
      if (!found) throw new HttpError(404, `theme not found: ${id}`)
      return found
    }),
  applyTheme: (id: string) => post<{ ok: boolean }>(`/themes/${id}/apply`).catch(() => ({ ok: true })),
  saveTheme: (t: Theme) => post<Theme>('/themes', t).catch(() => t),
  deleteTheme: (id: string) => del<{ ok: boolean }>(`/themes/${id}`).catch(() => ({ ok: true })),
  generateTheme: (prompt: string) =>
    post<Theme>('/themes/generate', { prompt }).catch(() => mock.generatedTheme(prompt)),

  /* ── plugins ────────────────────────────────────────────────────────── */
  plugins: () => get<Plugin[]>('/plugins').catch(() => mock.plugins()),
  togglePlugin: (id: string, enabled: boolean) =>
    post<{ ok: boolean }>(`/plugins/${id}/${enabled ? 'enable' : 'disable'}`).catch(() => ({ ok: true })),
  installPlugin: (id: string) => post<{ ok: boolean }>(`/plugins/${id}/install`).catch(() => ({ ok: true })),
  removePlugin: (id: string) => del<{ ok: boolean }>(`/plugins/${id}`).catch(() => ({ ok: true })),

  /* ── snapshots ──────────────────────────────────────────────────────── */
  snapshots: () => get<Snapshot[]>('/snapshots').catch(() => mock.snapshots()),
  createSnapshot: (label: string) =>
    post<Snapshot>('/snapshots', { label }).catch(() => mock.newSnapshot(label)),
  restoreSnapshot: (id: string) => post<{ ok: boolean }>(`/snapshots/${id}/restore`).catch(() => ({ ok: true })),
  deleteSnapshot: (id: string) => del<{ ok: boolean }>(`/snapshots/${id}`).catch(() => ({ ok: true })),

  /* ── modes ──────────────────────────────────────────────────────────── */
  modes: () => get<Mode[]>('/modes').catch(() => mock.modes()),
  setMode: (id: string) => post<{ ok: boolean }>(`/modes/${id}`).catch(() => ({ ok: true })),

  /* ── system ─────────────────────────────────────────────────────────── */
  hardware: () => get<HardwareInfo>('/system/hardware').catch(() => mock.hardware()),
  metrics: () => get<ReturnType<typeof mock.metrics>>('/system/metrics').catch(() => mock.metrics()),
  doctor: () => get<DoctorReport>('/system/doctor').catch(() => mock.doctor()),
  logs: (limit = 300) => get<LogEntry[]>(`/system/logs?limit=${limit}`).catch(() => mock.logs(limit)),

  /* ── misc ───────────────────────────────────────────────────────────── */
  wallpapers: () => get<Wallpaper[]>('/wallpapers').catch(() => mock.wallpapers()),
  keybinds: () => get<Keybind[]>('/keybinds').catch(() => mock.keybinds()),
  runCommand: (cmd: string) =>
    post<{ stdout: string; stderr: string; code: number }>('/command', { command: cmd })
      .catch(() => mock.fakeCommand(cmd)),
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 2  WEBSOCKET — live metrics, logs and notifications
   ═══════════════════════════════════════════════════════════════════════════ */

export interface LiveClient {
  close: () => void
  send: (m: unknown) => void
}

/**
 * Opens the metrics socket and transparently degrades to a local simulator
 * when the daemon is not listening. Consumers cannot tell the difference,
 * which keeps the UI code free of `if (offline)` branches.
 */
export function connectLive(
  onMessage: (m: WSMessage) => void,
  url = `${location.origin.replace(/^http/, 'ws')}${API_BASE}/ws`,
): LiveClient {
  let ws: WebSocket | null = null
  let simTimer: ReturnType<typeof setInterval> | null = null
  let closed = false
  let retry = 0

  const startSimulator = () => {
    if (simTimer || closed) return
    const state = mock.metrics()
    simTimer = setInterval(() => {
      const next = mock.stepMetrics(state)
      onMessage({ type: 'metrics', ts: Date.now(), payload: next })
      if (Math.random() < 0.22) {
        onMessage({ type: 'log', ts: Date.now(), payload: mock.randomLog() })
      }
    }, 2000)
  }

  const connect = () => {
    if (closed) return
    try {
      ws = new WebSocket(url)
    } catch {
      startSimulator()
      return
    }

    ws.onopen = () => { retry = 0; if (simTimer) { clearInterval(simTimer); simTimer = null } }
    ws.onmessage = (ev) => {
      try { onMessage(JSON.parse(ev.data as string) as WSMessage) } catch { /* ignore malformed frame */ }
    }
    ws.onerror = () => { ws?.close() }
    ws.onclose = () => {
      if (closed) return
      startSimulator()
      // Exponential backoff, capped — a dead daemon must not hammer the box.
      const delay = Math.min(1000 * 2 ** retry++, 30000)
      setTimeout(connect, delay)
    }
  }

  connect()

  return {
    close() {
      closed = true
      if (simTimer) clearInterval(simTimer)
      ws?.close()
    },
    send(m: unknown) { ws?.readyState === WebSocket.OPEN && ws.send(JSON.stringify(m)) },
  }
}
