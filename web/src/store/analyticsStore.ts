/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — analytics store
 * ═══════════════════════════════════════════════════════════════════════════
 *  Derives rollups from the raw metric ring buffer rather than querying the
 *  daemon a second time — one source, no drift between what the chart and the
 *  counter claim.
 */
import { create } from 'zustand'
import type { LogEntry } from '../lib/types'
import { api } from '../api/client'

export interface Rollup {
  avg: number
  peak: number
  min: number
  p95: number
  samples: number
}

/** Percentile via nearest-rank on a sorted copy. */
function percentile(sorted: number[], p: number): number {
  if (!sorted.length) return 0
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1))
  return sorted[idx]!
}

export function rollup(values: number[]): Rollup {
  if (!values.length) return { avg: 0, peak: 0, min: 0, p95: 0, samples: 0 }
  const sorted = [...values].sort((a, b) => a - b)
  return {
    avg: values.reduce((a, b) => a + b, 0) / values.length,
    peak: sorted[sorted.length - 1]!,
    min: sorted[0]!,
    p95: percentile(sorted, 95),
    samples: values.length,
  }
}

interface AnalyticsState {
  logs: LogEntry[]
  loadingLogs: boolean
  /** Rolling counter of events seen since mount, for the activity ticker. */
  eventCount: number
  loadLogs: (limit?: number) => Promise<void>
  pushLog: (entry: LogEntry) => void
  bumpEvents: (n?: number) => void
}

export const useAnalyticsStore = create<AnalyticsState>((set, get) => ({
  logs: [],
  loadingLogs: false,
  eventCount: 0,

  async loadLogs(limit = 300) {
    set({ loadingLogs: true })
    try {
      set({ logs: await api.logs(limit), loadingLogs: false })
    } catch {
      set({ loadingLogs: false })
    }
  },

  pushLog(entry) {
    set({ logs: [...get().logs.slice(-500), entry] })
  },

  bumpEvents(n = 1) {
    set({ eventCount: get().eventCount + n })
  },
}))
