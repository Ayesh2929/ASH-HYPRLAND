/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — analytics hook
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { useMemo } from 'react'
import { rollup, useAnalyticsStore } from '../store/analyticsStore'
import { useConfigStore } from '../store/configStore'

export function useAnalytics() {
  const metrics = useConfigStore((s) => s.metrics)
  const logs = useAnalyticsStore((s) => s.logs)
  const loadingLogs = useAnalyticsStore((s) => s.loadingLogs)
  const loadLogs = useAnalyticsStore((s) => s.loadLogs)

  const series = useMemo(() => ({
    cpu: metrics.map((m) => m.cpu),
    memory: metrics.map((m) => m.memory),
    gpu: metrics.map((m) => m.gpu),
    network: metrics.map((m) => m.network),
    disk: metrics.map((m) => m.disk),
  }), [metrics])

  const stats = useMemo(() => ({
    cpu: rollup(series.cpu),
    memory: rollup(series.memory),
    gpu: rollup(series.gpu),
    network: rollup(series.network),
    disk: rollup(series.disk),
  }), [series])

  /** Log lines bucketed by level, for the distribution bar. */
  const byLevel = useMemo(() => {
    const counts: Record<string, number> = {}
    for (const l of logs) counts[l.level] = (counts[l.level] ?? 0) + 1
    return counts
  }, [logs])

  /** Event rate per minute over the last 30 minutes. */
  const rate = useMemo(() => {
    const buckets = new Array(30).fill(0) as number[]
    const now = Date.now()
    for (const l of logs) {
      const age = Math.floor((now - new Date(l.ts).getTime()) / 60000)
      if (age >= 0 && age < 30) buckets[29 - age] = (buckets[29 - age] ?? 0) + 1
    }
    return buckets
  }, [logs])

  return { series, stats, logs, loadingLogs, loadLogs, byLevel, rate }
}
