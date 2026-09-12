/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — hardware & resource panel
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { Badge, Donut, Panel, Progress, SectionHeader, Skeleton } from './ui'
import { useConfigStore } from '../store/configStore'
import { formatBytes, formatDuration } from '../lib/utils'

export default function HardwareReport() {
  const hw = useConfigStore((s) => s.hardware)
  const metrics = useConfigStore((s) => s.metrics)

  if (!hw) {
    return (
      <Panel>
        <Skeleton className="h-5 w-40" />
        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <Skeleton className="h-28" />
          <Skeleton className="h-28" />
        </div>
      </Panel>
    )
  }

  const last = metrics[metrics.length - 1]
  const memPct = (hw.memory.used / hw.memory.total) * 100
  const cpuPct = last?.cpu ?? hw.cpu.usage
  const gpuPct = last?.gpu ?? hw.gpu.usage

  return (
    <Panel>
      <SectionHeader
        icon="🖥️"
        title="Hardware"
        subtitle={`${hw.hostname} · ${hw.distro} · kernel ${hw.kernel}`}
        action={<Badge tone="accent">{hw.compositor} {hw.compositorVersion}</Badge>}
      />

      <div className="mb-5 grid grid-cols-3 gap-3">
        <MeterDonut value={cpuPct} label="CPU" tone="accent" />
        <MeterDonut value={memPct} label="RAM" tone="sky" />
        <MeterDonut value={gpuPct} label="GPU" tone="violet" />
      </div>

      <dl className="space-y-3 text-[12px]">
        <Row label="Processor" value={`${hw.cpu.model} · ${hw.cpu.cores}c/${hw.cpu.threads}t`} extra={`${hw.cpu.temp.toFixed(0)}°C`} />
        <Row
          label="Memory"
          value={`${formatBytes(hw.memory.used)} / ${formatBytes(hw.memory.total)}`}
          extra={`${formatBytes(hw.memory.swapUsed)} swap`}
        />
        <Row label="Graphics" value={`${hw.gpu.vendor} ${hw.gpu.model}`} extra={hw.gpu.driver} />

        {hw.battery && (
          <Row
            label="Battery"
            value={`${hw.battery.percent}%${hw.battery.charging ? ' · charging' : ''}`}
            extra={`${formatDuration(hw.battery.timeRemaining)} · ${hw.battery.health}% health`}
          />
        )}

        {hw.disks.map((d) => (
          <div key={d.mount} className="space-y-1.5">
            <div className="flex items-center justify-between">
              <dt className="text-subtext/70">
                <span className="font-mono text-text">{d.mount}</span>
                <span className="ml-2 text-subtext/45">{d.fs}</span>
              </dt>
              <dd className="font-mono text-subtext">
                {formatBytes(d.used)} / {formatBytes(d.total)}
              </dd>
            </div>
            <Progress value={(d.used / d.total) * 100} height={4} />
          </div>
        ))}

        <div className="pt-1">
          <dt className="mb-2 text-subtext/70">Displays</dt>
          <div className="flex flex-wrap gap-2">
            {hw.displays.map((d) => (
              <span
                key={d.name}
                className="flex items-center gap-2 rounded-lg border border-white/[0.07] bg-white/[0.02] px-2.5 py-1.5 font-mono text-[11px] text-subtext"
              >
                <span className="text-text">{d.name}</span>
                {d.resolution}
                <span className="text-subtext/45">{d.refresh}Hz</span>
                {d.scale !== 1 && <span className="text-accent/70">@{d.scale}×</span>}
              </span>
            ))}
          </div>
        </div>
      </dl>
    </Panel>
  )
}

function MeterDonut({ value, label, tone }: { value: number; label: string; tone: 'accent' | 'sky' | 'violet' }) {
  return (
    <div className="flex flex-col items-center gap-1.5">
      <Donut value={value} size={84} thickness={8} tone={tone} sublabel={label} />
    </div>
  )
}

function Row({ label, value, extra }: { label: string; value: string; extra?: string }) {
  return (
    <div className="flex items-baseline justify-between gap-3 border-b border-white/[0.04] pb-2 last:border-0">
      <dt className="shrink-0 text-subtext/70">{label}</dt>
      <dd className="min-w-0 truncate text-right text-text" title={value}>
        {value}
        {extra && <span className="ml-2 text-[11px] text-subtext/45">{extra}</span>}
      </dd>
    </div>
  )
}
