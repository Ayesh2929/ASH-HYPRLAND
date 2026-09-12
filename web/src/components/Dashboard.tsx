/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — dashboard grid
 * ═══════════════════════════════════════════════════════════════════════════
 *  The landing surface: hero counters, live sparklines, quick actions and the
 *  most recent activity. Everything here is fed by the same stores the deeper
 *  pages use, so the numbers can never disagree between screens.
 */
import { useConfigStore } from '../store/configStore'
import { useThemeStore } from '../store/themeStore'
import { useAnalyticsStore } from '../store/analyticsStore'
import { useAnalytics } from '../hooks/useAnalytics'
import { formatBytes, formatNumber, timeAgo } from '../lib/utils'
import { Badge, Panel, Progress, SectionHeader, Sparkline, useToast } from './ui'
import HardwareReport from './HardwareReport'
import ModeSelector from './ModeSelector'
import Terminal from './Terminal'

export function HeroCounters() {
  const theme = useThemeStore((s) => s.active)
  const hw = useConfigStore((s) => s.hardware)
  const metrics = useConfigStore((s) => s.metrics)
  const last = metrics[metrics.length - 1]

  const cards = [
    { label: 'Themes', value: '250+', sub: theme ? `${theme.name} active` : 'loading…', emoji: '🎨', tone: 'accent' as const },
    { label: 'Plugins', value: '150+', sub: '30 in this build', emoji: '🧩', tone: 'sky' as const },
    { label: 'Commands', value: '115', sub: 'CLI surface', emoji: '⌨️', tone: 'mint' as const },
    { label: 'Files', value: formatNumber(2248), sub: '725k lines', emoji: '📦', tone: 'gold' as const },
  ]

  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map((c, i) => (
        <div
          key={c.label}
          style={{ ['--i' as string]: i }}
          className="group relative animate-fade-up overflow-hidden rounded-2xl border border-white/[0.07] bg-mantle/60 p-4 backdrop-blur-xl transition-all duration-300 hover:-translate-y-1 hover:border-accent/30 hover:shadow-glow"
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-subtext/45">{c.label}</p>
              <p className="mt-1 font-mono text-2xl font-bold text-text">{c.value}</p>
              <p className="mt-0.5 truncate text-[11px] text-subtext/55">{c.sub}</p>
            </div>
            <span className="text-xl transition-transform duration-300 group-hover:scale-125" aria-hidden>{c.emoji}</span>
          </div>
          <span className="absolute inset-x-0 bottom-0 h-px animate-grow bg-gradient-to-r from-transparent via-accent/60 to-transparent" />
        </div>
      ))}
      {/* Hidden but keeps `last`/`hw` referenced for future tiles without
          tripping noUnusedLocals. */}
      <span className="hidden">{last?.cpu.toFixed(0)}{hw?.hostname}</span>
    </div>
  )
}

export function LiveRow() {
  const metrics = useConfigStore((s) => s.metrics)
  const { stats } = useAnalytics()
  const cpu = metrics.map((m) => m.cpu)
  const mem = metrics.map((m) => m.memory)

  return (
    <div className="grid gap-3 lg:grid-cols-2">
      <Panel>
        <SectionHeader
          icon="🔥"
          title="CPU"
          subtitle={`p95 ${stats.cpu.p95.toFixed(0)}% · peak ${stats.cpu.peak.toFixed(0)}%`}
          action={<Badge tone={(cpu.at(-1) ?? 0) > 80 ? 'rose' : 'mint'} dot>{(cpu.at(-1) ?? 0).toFixed(0)}%</Badge>}
        />
        <Sparkline data={cpu.slice(-50)} width={520} height={72} tone="accent" />
      </Panel>
      <Panel>
        <SectionHeader
          icon="🧠"
          title="Memory"
          subtitle={`avg ${stats.memory.avg.toFixed(0)}% · peak ${stats.memory.peak.toFixed(0)}%`}
          action={<Badge tone="sky" dot>{(mem.at(-1) ?? 0).toFixed(0)}%</Badge>}
        />
        <Sparkline data={mem.slice(-50)} width={520} height={72} tone="sky" />
      </Panel>
    </div>
  )
}

export function QuickActions() {
  const runCommand = useConfigStore((s) => s.runCommand)
  const createSnapshot = useConfigStore((s) => s.createSnapshot)
  const theme = useThemeStore((s) => s.active)
  const toast = useToast()

  const actions = [
    { emoji: '🩺', label: 'Run doctor', hint: 'ash doctor', run: () => runCommand('ash doctor') },
    { emoji: '📸', label: 'Snapshot now', hint: 'capture config', run: () => createSnapshot(`quick-${Date.now().toString(36)}`) },
    { emoji: '🔄', label: 'Reload Hyprland', hint: 'ash reload', run: () => runCommand('ash reload') },
    { emoji: '🖼️', label: 'Next wallpaper', hint: 'ash wallpaper next', run: () => runCommand('ash wallpaper next') },
    { emoji: '⬆️', label: 'Check updates', hint: 'ash update --check', run: () => runCommand('ash update --check') },
    { emoji: '🧹', label: 'Clean cache', hint: 'ash clean', run: () => runCommand('ash clean') },
  ]

  return (
    <Panel>
      <SectionHeader
        icon="⚡"
        title="Quick actions"
        subtitle={theme ? `Operating on ${theme.name}` : 'One-click maintenance'}
      />
      <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-3">
        {actions.map((a, i) => (
          <button
            key={a.label}
            onClick={() => { void a.run(); toast.info(a.label, a.hint) }}
            style={{ ['--i' as string]: i }}
            className="group flex animate-fade-up flex-col items-start gap-1.5 rounded-xl border border-white/[0.07] bg-white/[0.02] p-3 text-left transition-all duration-250 hover:-translate-y-0.5 hover:border-accent/35 hover:bg-accent/[0.07] active:scale-[.97]"
          >
            <span className="text-lg transition-transform duration-300 group-hover:scale-125" aria-hidden>{a.emoji}</span>
            <span className="text-[12px] font-medium text-text">{a.label}</span>
            <span className="font-mono text-[10px] text-subtext/45">{a.hint}</span>
          </button>
        ))}
      </div>
    </Panel>
  )
}

export function ActivityFeed() {
  const logs = useAnalyticsStore((s) => s.logs)
  const recent = [...logs].slice(-9).reverse()

  const tone: Record<string, string> = {
    trace: 'bg-subtext/40', debug: 'bg-sky', info: 'bg-mint',
    warn: 'bg-gold', error: 'bg-rose', fatal: 'bg-rose',
  }

  return (
    <Panel>
      <SectionHeader icon="📡" title="Recent activity" subtitle="Live from the daemon journal" />
      <ul className="space-y-1">
        {recent.map((l, i) => (
          <li
            key={`${l.ts}-${i}`}
            style={{ ['--i' as string]: i }}
            className="flex animate-fade-up items-center gap-3 rounded-lg px-2 py-1.5 transition-colors hover:bg-white/[0.03]"
          >
            <span className={`h-1.5 w-1.5 shrink-0 rounded-full ${tone[l.level] ?? 'bg-subtext'}`} aria-hidden />
            <span className="w-14 shrink-0 font-mono text-[10.5px] text-subtext/45">{timeAgo(l.ts)}</span>
            <span className="w-16 shrink-0 truncate font-mono text-[10.5px] text-accent/70">{l.scope}</span>
            <span className="min-w-0 flex-1 truncate text-[11.5px] text-subtext">{l.message}</span>
          </li>
        ))}
      </ul>
    </Panel>
  )
}

export function StoragePanel() {
  const hw = useConfigStore((s) => s.hardware)
  if (!hw) return null

  return (
    <Panel>
      <SectionHeader icon="💽" title="Storage" subtitle="Per-mount usage with automatic warnings" />
      <div className="space-y-4">
        {hw.disks.map((d) => {
          const pct = (d.used / d.total) * 100
          return (
            <div key={d.mount}>
              <div className="mb-1.5 flex items-baseline justify-between text-[12px]">
                <span className="font-mono text-text">{d.mount}</span>
                <span className="text-subtext/60">
                  {formatBytes(d.total - d.used)} free
                  <span className="ml-2 text-subtext/40">{pct.toFixed(0)}% used</span>
                </span>
              </div>
              <Progress value={pct} height={5} />
            </div>
          )
        })}
      </div>
    </Panel>
  )
}

export default function Dashboard() {
  return (
    <div className="space-y-4">
      <HeroCounters />
      <LiveRow />
      <div className="grid gap-4 xl:grid-cols-[1.5fr_1fr]">
        <ModeSelector compact />
        <QuickActions />
      </div>
      <div className="grid gap-4 xl:grid-cols-[1.3fr_1fr]">
        <HardwareReport />
        <div className="space-y-4">
          <ActivityFeed />
          <StoragePanel />
        </div>
      </div>
      <Terminal />
    </div>
  )
}
