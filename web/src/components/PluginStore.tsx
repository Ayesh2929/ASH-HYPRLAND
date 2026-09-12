/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — plugin store
 * ═══════════════════════════════════════════════════════════════════════════
 *  Discovers not-yet-installed plugins and installs them with a progress
 *  affordance. Sorted by category so the list reads as a catalogue.
 */
import { useMemo } from 'react'
import { usePluginStore } from '../store/pluginStore'
import { groupByCategory } from '../api/plugin'
import { formatBytes } from '../lib/utils'
import { Badge, Button, EmptyState, Panel, SectionHeader, Skeleton, useToast } from './ui'

export default function PluginStore() {
  const plugins = usePluginStore((s) => s.plugins)
  const install = usePluginStore((s) => s.install)
  const busy = usePluginStore((s) => s.busy)
  const loading = usePluginStore((s) => s.loading)
  const toast = useToast()

  const available = useMemo(() => plugins.filter((p) => !p.installed), [plugins])
  const grouped = useMemo(() => groupByCategory(available), [available])

  const onInstall = async (id: string, name: string) => {
    await install(id)
    toast.success(`${name} installed`, 'Enable it from the Installed tab.')
  }

  return (
    <Panel>
      <SectionHeader
        icon="🏪"
        title="Plugin store"
        subtitle={`${available.length} plugins available · curated and signature-checked`}
      />

      {loading && plugins.length === 0 && (
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 6 }, (_, i) => <Skeleton key={i} className="h-36" />)}
        </div>
      )}

      {!loading && available.length === 0 && (
        <EmptyState
          emoji="🎉"
          title="Everything is installed"
          hint="You have every plugin in this build. Nice."
        />
      )}

      <div className="space-y-6">
        {grouped.map(([category, items]) => (
          <section key={category}>
            <h3 className="mb-2.5 flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.14em] text-subtext/45">
              {category}
              <span className="rounded-full bg-white/[0.06] px-1.5 py-px font-mono text-[10px] text-subtext/60">
                {items.length}
              </span>
            </h3>
            <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
              {items.map((p, i) => (
                <article
                  key={p.id}
                  style={{ ['--i' as string]: i }}
                  className="group flex animate-fade-up flex-col rounded-xl border border-white/[0.07] bg-white/[0.02] p-3.5 transition-all duration-300 hover:-translate-y-1 hover:border-accent/30 hover:shadow-lift"
                >
                  <div className="mb-2 flex items-start justify-between gap-2">
                    <h4 className="text-[13px] font-semibold text-text">{p.name}</h4>
                    {p.official && <Badge tone="sky">verified</Badge>}
                  </div>
                  <p className="mb-3 flex-1 text-[11.5px] leading-relaxed text-subtext/65">{p.description}</p>
                  <div className="mb-3 flex items-center gap-3 font-mono text-[10px] text-subtext/45">
                    <span>v{p.version}</span>
                    <span>{formatBytes(p.size)}</span>
                    <span>by {p.author}</span>
                  </div>
                  <Button
                    variant="primary"
                    icon="⬇️"
                    loading={busy[p.id]}
                    onClick={() => void onInstall(p.id, p.name)}
                  >
                    Install
                  </Button>
                </article>
              ))}
            </div>
          </section>
        ))}
      </div>
    </Panel>
  )
}
