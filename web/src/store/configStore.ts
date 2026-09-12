/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — config & system store
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { create } from 'zustand'
import type { HardwareInfo, MetricPoint, Mode, Snapshot } from '../lib/types'
import { api, connectLive, type LiveClient } from '../api/client'

interface ConfigState {
  hardware: HardwareInfo | null
  metrics: MetricPoint[]
  modes: Mode[]
  snapshots: Snapshot[]
  loading: boolean
  /** false until the first metrics frame lands. */
  live: boolean
  liveClient: LiveClient | null
  commandHistory: Array<{ cmd: string; out: string; code: number; ts: number }>

  bootstrap: () => Promise<void>
  startLive: () => void
  stopLive: () => void
  setMode: (id: string) => Promise<void>
  refreshSnapshots: () => Promise<void>
  createSnapshot: (label: string) => Promise<void>
  restoreSnapshot: (id: string) => Promise<void>
  deleteSnapshot: (id: string) => Promise<void>
  runCommand: (cmd: string) => Promise<void>
}

export const useConfigStore = create<ConfigState>((set, get) => ({
  hardware: null,
  metrics: [],
  modes: [],
  snapshots: [],
  loading: true,
  live: false,
  liveClient: null,
  commandHistory: [],

  async bootstrap() {
    set({ loading: true })
    const [hardware, metrics, modes, snapshots] = await Promise.all([
      api.hardware(), api.metrics(), api.modes(), api.snapshots(),
    ])
    set({ hardware, metrics, modes, snapshots, loading: false })
  },

  startLive() {
    if (get().liveClient) return
    const client = connectLive((msg) => {
      if (msg.type === 'metrics') {
        // The simulator streams full arrays, a real daemon streams points.
        const payload = msg.payload as MetricPoint[] | MetricPoint
        const next = Array.isArray(payload)
          ? payload
          : [...get().metrics.slice(-59), payload]
        set({ metrics: next, live: true })
      }
    })
    set({ liveClient: client })
  },

  stopLive() {
    get().liveClient?.close()
    set({ liveClient: null, live: false })
  },

  async setMode(id) {
    const before = get().modes
    set({ modes: before.map((m) => ({ ...m, active: m.id === id })) })
    try {
      await api.setMode(id)
    } catch {
      set({ modes: before })
    }
  },

  async refreshSnapshots() {
    set({ snapshots: await api.snapshots() })
  },

  async createSnapshot(label) {
    const snap = await api.createSnapshot(label)
    set({ snapshots: [snap, ...get().snapshots] })
  },

  async restoreSnapshot(id) {
    await api.restoreSnapshot(id)
  },

  async deleteSnapshot(id) {
    const before = get().snapshots
    set({ snapshots: before.filter((s) => s.id !== id) })
    try {
      await api.deleteSnapshot(id)
    } catch {
      set({ snapshots: before })
    }
  },

  async runCommand(cmd) {
    const res = await api.runCommand(cmd)
    const out = [res.stdout, res.stderr].filter(Boolean).join('')
    set({
      commandHistory: [
        ...get().commandHistory.slice(-99),
        { cmd, out, code: res.code, ts: Date.now() },
      ],
    })
  },
}))
