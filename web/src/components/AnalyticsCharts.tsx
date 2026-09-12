/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — charts
 * ═══════════════════════════════════════════════════════════════════════════
 *  All SVG, no charting library. Each chart is responsive via viewBox and
 *  animates on mount only, so streaming updates never re-trigger motion.
 */
import { useMemo } from 'react'
import { cn } from '../lib/utils'
import { Sparkline, type Tone } from './ui'

export function MultiMetricChart({
  series, height = 200, visible,
}: {
  series: Record<string, number[]>
  height?: number
  visible: string[]
}) {
  const colors: Record<string, { tone: Tone; stroke: string }> = {
    cpu:    { tone: 'accent', stroke: 'rgb(var(--ash-accent))' },
    memory: { tone: 'sky',    stroke: 'rgb(var(--ash-sky))' },
    gpu:    { tone: 'violet', stroke: 'rgb(var(--ash-violet))' },
    network:{ tone: 'mint',   stroke: 'rgb(var(--ash-mint))' },
    disk:   { tone: 'gold',   stroke: 'rgb(var(--ash-gold))' },
  }

  const width = 800
  const { paths, gridY } = useMemo(() => {
    const max = Math.max(
      100,
      ...visible.flatMap((k) => series[k] ?? []),
    )
    const result: Record<string, string> = {}

    for (const key of visible) {
      const data = series[key] ?? []
      if (data.length < 2) continue
      const stepX = width / (data.length - 1)
      let d = ''
      data.forEach((v, i) => {
        const x = i * stepX
        const y = height - (v / max) * (height - 12) - 6
        d += i === 0 ? `M${x.toFixed(1)},${y.toFixed(1)}` : ` L${x.toFixed(1)},${y.toFixed(1)}`
      })
      result[key] = d
    }

    // 0 / 50 / 100 guide lines
    const gy = [0, 0.5, 1].map((f) => height - f * (height - 12) - 6)
    return { paths: result, gridY: gy }
  }, [series, visible, height])

  return (
    <div className="relative w-full">
      <svg viewBox={`0 0 ${width} ${height}`} className="w-full" preserveAspectRatio="none" style={{ height }}>
        {gridY.map((y, i) => (
          <line key={i} x1="0" x2={width} y1={y} y2={y} stroke="rgb(255 255 255 / .05)" strokeWidth="1" strokeDasharray="4 6" />
        ))}

        {visible.map((key) => {
          const d = paths[key]
          if (!d) return null
          const c = colors[key]
          return (
            <g key={key}>
              <path d={d} fill="none" stroke={c?.stroke} strokeWidth="2" strokeLinejoin="round" strokeLinecap="round"
                    className="animate-draw-in" style={{ strokeDasharray: 3000, ['--dash' as string]: '3000' }} />
              {/* Latest-value dot, so the eye lands on "now". */}
              <circle
                cx={width}
                cy={height - ((series[key]?.at(-1) ?? 0) / Math.max(100, ...visible.flatMap((k) => series[k] ?? []))) * (height - 12) - 6}
                r="3.5"
                fill={c?.stroke}
                className="animate-fade-in"
              />
            </g>
          )
        })}
      </svg>

      <div className="mt-2 flex flex-wrap gap-3 text-[10.5px]">
        {visible.map((key) => (
          <span key={key} className="flex items-center gap-1.5 capitalize text-subtext/65">
            <span className="h-2 w-2 rounded-full" style={{ background: colors[key]?.stroke }} />
            {key}
            <span className="font-mono text-text">{series[key]?.at(-1)?.toFixed(0) ?? '—'}</span>
          </span>
        ))}
      </div>
    </div>
  )
}

export function MetricTile({
  label, emoji, values, tone, unit = '%',
}: { label: string; emoji: string; values: number[]; tone: Tone; unit?: string }) {
  const current = values.at(-1) ?? 0
  const avg = values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0
  const peak = values.length ? Math.max(...values) : 0

  return (
    <div className="group rounded-xl border border-white/[0.07] bg-white/[0.02] p-3.5 transition-all duration-300 hover:-translate-y-0.5 hover:border-white/15">
      <div className="mb-1 flex items-center justify-between">
        <span className="flex items-center gap-1.5 text-[11px] font-medium uppercase tracking-wider text-subtext/55">
          <span aria-hidden>{emoji}</span>
          {label}
        </span>
      </div>
      <div className="flex items-end justify-between gap-2">
        <span className="font-mono text-2xl font-semibold tabular-nums text-text">
          {current.toFixed(unit === '%' ? 0 : 1)}
          <span className="ml-0.5 text-[13px] text-subtext/50">{unit}</span>
        </span>
        <Sparkline data={values.slice(-40)} width={92} height={30} tone={tone} fill={false} animate={false} />
      </div>
      <div className="mt-1.5 flex gap-3 text-[10px] text-subtext/45">
        <span>avg <span className="font-mono text-subtext/70">{avg.toFixed(1)}</span></span>
        <span>peak <span className="font-mono text-subtext/70">{peak.toFixed(1)}</span></span>
      </div>
    </div>
  )
}

export function LogDistribution({ byLevel, total }: { byLevel: Record<string, number>; total: number }) {
  const order = ['trace', 'debug', 'info', 'warn', 'error', 'fatal'] as const
  const bar: Record<string, string> = {
    trace: 'bg-subtext/30', debug: 'bg-sky/60', info: 'bg-mint/70',
    warn: 'bg-gold/80', error: 'bg-rose/80', fatal: 'bg-rose',
  }

  if (!total) return <p className="py-6 text-center text-[12px] text-subtext/50">No log entries yet.</p>

  return (
    <div>
      <div className="flex h-3 w-full overflow-hidden rounded-full bg-white/[0.05]">
        {order.map((level) => {
          const n = byLevel[level] ?? 0
          if (!n) return null
          return (
            <div
              key={level}
              className={cn('h-full origin-left animate-grow transition-all duration-500', bar[level])}
              style={{ width: `${(n / total) * 100}%` }}
              title={`${level}: ${n}`}
            />
          )
        })}
      </div>
      <div className="mt-2.5 flex flex-wrap gap-3 text-[10.5px]">
        {order.map((level) => (
          <span key={level} className="flex items-center gap-1.5 capitalize text-subtext/60">
            <span className={cn('h-2 w-2 rounded-full', bar[level])} />
            {level}
            <span className="font-mono text-text/80">{byLevel[level] ?? 0}</span>
          </span>
        ))}
      </div>
    </div>
  )
}

export function EventRateChart({ rate }: { rate: number[] }) {
  return (
    <div>
      <div className="flex h-24 items-end gap-[3px]">
        {rate.map((v, i) => {
          const max = Math.max(...rate, 1)
          return (
            <div
              key={i}
              className="flex-1 origin-bottom animate-grow rounded-sm bg-gradient-to-t from-accent/70 to-accent/20 transition-colors hover:from-accent hover:to-accent/40"
              style={{ height: `${Math.max(3, (v / max) * 100)}%`, animationDelay: `${i * 18}ms` }}
              title={`${v} events`}
            />
          )
        })}
      </div>
      <div className="mt-1.5 flex justify-between text-[10px] text-subtext/40">
        <span>30m ago</span>
        <span>15m</span>
        <span>now</span>
      </div>
    </div>
  )
}
