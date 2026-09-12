/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — analytics console
 * ═══════════════════════════════════════════════════════════════════════════
 *  Live metrics, the event-rate histogram, log-level distribution and a
 *  filterable log table with virtual-friendly rendering (caps at 500 rows).
 */
import { useMemo, useState } from 'react'
import { useAnalytics } from '../hooks/useAnalytics'
import { cn, formatTime } from '../lib/utils'
import {
  Badge, Button, EmptyState, Panel, SectionHeader, Skeleton, Tabs, Input,
} from './ui'
import { EventRateChart, LogDistribution, MetricTile, MultiMetricChart } from './AnalyticsCharts'
import type { LogEntry } from '../lib/types'

type MetricKey = 'cpu' | 'memory' | 'gpu' | 'network' | 'disk'

const LEVEL_TONE: Record<LogEntry['level'], string> = {
  trace: 'text-subtext/50', debug: 'text-sky', info: 'text-mint',
  warn: 'text-gold', error: 'text-rose', fatal: 'text-rose font-bold',
}

export default function AnalyticsConsole() {
  const { series, stats, logs, loadingLogs, loadLogs, byLevel, rate } = useAnalytics()
  const [visible, setVisible] = useState<MetricKey[]>(['cpu', 'memory'])
  const [level, setLevel] = useState<'all' | LogEntry['level']>('all')
  const [query, setQuery] = useState('')
  const [paused, setPaused] = useState(false)

  // Freezing the series is what makes a moving chart readable; without it
  // you cannot hover a number that keeps changing.
  const frozen = useMemo(() => series, [paused, series]) // eslint-disable-line react-hooks/exhaustive-deps

  const filteredLogs = useMemo(() => {
    const q = query.trim().toLowerCase()
    return logs
      .filter((l) => (level === 'all' ? true : l.level === level))
      .filter((l) => (!q ? true : l.message.toLowerCase().includes(q) || l.scope.includes(q)))
      .slice(-500)
      .reverse()
  }, [logs, level, query])

  const toggleMetric = (k: MetricKey) =>
    setVisible((v) => (v.includes(k) ? (v.length > 1 ? v.filter((x) => x !== k) : v) : [...v, k]))

  return (
    <div className="space-y-4">
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <MetricTile label="CPU"     emoji="🔥" values={frozen.cpu}     tone="accent" />
        <MetricTile label="Memory"  emoji="🧠" values={frozen.memory}  tone="sky" />
        <MetricTile label="GPU"     emoji="🎮" values={frozen.gpu}     tone="violet" />
        <MetricTile label="Network" emoji="🌐" values={frozen.network} tone="mint" unit=" Mb/s" />
        <MetricTile label="Disk"    emoji="💿" values={frozen.disk}    tone="gold" unit=" MB/s" />
      </div>

      <Panel>
        <SectionHeader
          icon="📈"
          title="Live telemetry"
          subtitle={`${series.cpu.length} samples · 2 s interval · p95 CPU ${stats.cpu.p95.toFixed(1)}%`}
          action={
            <div className="flex items-center gap-2">
              <Button icon={paused ? '▶️' : '⏸️'} onClick={() => setPaused((p) => !p)}>
                {paused ? 'Resume' : 'Pause'}
              </Button>
              <Button icon="🧹" onClick={() => loadLogs(200)}>Reload</Button>
            </div>
          }
        />

        <div className="mb-4 flex flex-wrap gap-1.5">
          {(['cpu', 'memory', 'gpu', 'network', 'disk'] as MetricKey[]).map((k) => (
            <button
              key={k}
              onClick={() => toggleMetric(k)}
              aria-pressed={visible.includes(k)}
              className={cn(
                'rounded-full border px-3 py-1 text-[11px] capitalize transition-all duration-200 active:scale-95',
                visible.includes(k)
                  ? 'border-accent/40 bg-accent/12 text-accent'
                  : 'border-white/[0.07] text-subtext/55 hover:border-white/20 hover:text-text',
              )}
            >
              {k}
            </button>
          ))}
        </div>

        <MultiMetricChart series={series} visible={visible} height={220} />
      </Panel>

      <div className="grid gap-4 lg:grid-cols-2">
        <Panel>
          <SectionHeader icon="⏱️" title="Event rate" subtitle="Log lines per minute, last 30 minutes" />
          <EventRateChart rate={rate} />
        </Panel>

        <Panel>
          <SectionHeader icon="🎚️" title="Log levels" subtitle={`${logs.length} entries in buffer`} />
          <LogDistribution byLevel={byLevel} total={logs.length} />
          <div className="ash-divider my-4" />
          <div className="grid grid-cols-3 gap-3 text-center">
            <Stat label="P95 CPU" value={`${stats.cpu.p95.toFixed(0)}%`} />
            <Stat label="Peak RAM" value={`${stats.memory.peak.toFixed(0)}%`} />
            <Stat label="Peak GPU" value={`${stats.gpu.peak.toFixed(0)}%`} />
          </div>
        </Panel>
      </div>

      <Panel>
        <SectionHeader
          icon="📜"
          title="Log stream"
          subtitle={`showing ${filteredLogs.length} of ${logs.length} entries`}
        />

        <div className="mb-4 flex flex-wrap items-center gap-2.5">
          <div className="min-w-[14rem] flex-1">
            <Input prefix="🔍" placeholder="Filter messages…" value={query} onChange={(e) => setQuery(e.target.value)} />
          </div>
          <Tabs
            value={level}
            onChange={setLevel}
            tabs={(['all', 'info', 'warn', 'error'] as const).map((l) => ({ id: l, label: l }))}
          />
        </div>

        {loadingLogs && logs.length === 0 && (
          <div className="space-y-1.5">
            {Array.from({ length: 8 }, (_, i) => <Skeleton key={i} className="h-7" />)}
          </div>
        )}

        {!loadingLogs && filteredLogs.length === 0 && (
          <EmptyState emoji="📭" title="No log entries match" hint="Loosen the level filter or clear the search." />
        )}

        {filteredLogs.length > 0 && (
          <div className="ash-scroll-fade max-h-[26rem] overflow-y-auto rounded-xl border border-white/[0.06] bg-crust/50 p-2">
            <table className="w-full border-collapse font-mono text-[11px]">
              <tbody>
                {filteredLogs.map((l, i) => (
                  <tr
                    key={`${l.ts}-${i}`}
                    className="group transition-colors hover:bg-white/[0.035]"
                  >
                    <td className="whitespace-nowrap px-2 py-1 align-top text-subtext/45">
                      {formatTime(l.ts)}
                    </td>
                    <td className={cn('whitespace-nowrap px-2 py-1 align-top uppercase', LEVEL_TONE[l.level])}>
                      {l.level}
                    </td>
                    <td className="whitespace-nowrap px-2 py-1 align-top text-accent/70">
                      {l.scope}
                    </td>
                    <td className="px-2 py-1 align-top text-subtext group-hover:text-text">
                      {l.message}
                      {l.fields && (
                        <span className="ml-2 text-subtext/35">
                          {Object.entries(l.fields).map(([k, v]) => `${k}=${v}`).join(' ')}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>
    </div>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] p-3">
      <p className="font-mono text-lg font-semibold text-text">{value}</p>
      <p className="text-[10px] uppercase tracking-wider text-subtext/45">{label}</p>
    </div>
  )
}

export { Badge }
