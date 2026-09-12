/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — plugin manager
 * ═══════════════════════════════════════════════════════════════════════════
 *  Installed plugins with optimistic toggles, dependency surfacing and a
 *  category filter. Rows expand to show hooks and requirements.
 */
import { useState } from 'react'
import type { Plugin } from '../lib/types'
import { usePluginStore } from '../store/pluginStore'
import { usePlugins } from '../hooks/usePlugin'
import { cn, formatBytes, timeAgo } from '../lib/utils'
import { Badge, Button, EmptyState, Input, Panel, SectionHeader, Skeleton, Toggle, useToast } from './ui'

const CATEGORY_EMOJI: Record<Plugin['category'], string> = {
  productivity: '⚡', appearance: '🎨', system: '⚙️',
  integration: '🔌', fun: '🎉', security: '🛡️',
}

export default function PluginManager() {
  const { filtered, stats, category, query, setCategory, setQuery } = usePlugins()
  const plugins = usePluginStore((s) => s.plugins)
  const loading = usePluginStore((s) => s.loading)
  const toggle = usePluginStore((s) => s.toggle)
  const remove = usePluginStore((s) => s.remove)
  const busy = usePluginStore((s) => s.busy)
  const toast = useToast()

  const [expanded, setExpanded] = useState<string | null>(null)
  const installed = filtered.filter((p) => p.installed)

  const onToggle = async (p: Plugin, enabled: boolean) => {
    await toggle(p.id, enabled)
    toast.info(`${p.name} ${enabled ? 'enabled' : 'disabled'}`, enabled ? p.hooks.join(', ') || 'No hooks' : undefined)
  }

  const onRemove = async (p: Plugin) => {
    await remove(p.id)
    toast.success(`${p.name} removed`)
  }

  return (
    <Panel>
      <SectionHeader
        icon="🧩"
        title="Installed plugins"
        subtitle={`${stats.enabled} of ${stats.installed} enabled · ${stats.available} available in the store`}
      />

      <div className="mb-4 flex flex-wrap items-center gap-2.5">
        <div className="min-w-[14rem] flex-1">
          <Input
            prefix="🔍"
            placeholder="Search plugins…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        <div className="no-scrollbar flex gap-1.5 overflow-x-auto">
          <Chip active={category === null} onClick={() => setCategory(null)}>All</Chip>
          {(Object.keys(CATEGORY_EMOJI) as Array<Plugin['category']>).map((c) => (
            <Chip key={c} active={category === c} onClick={() => setCategory(category === c ? null : c)}>
              {CATEGORY_EMOJI[c]} {c}
            </Chip>
          ))}
        </div>
      </div>

      {loading && plugins.length === 0 && (
        <div className="space-y-2">
          {Array.from({ length: 5 }, (_, i) => <Skeleton key={i} className="h-16" />)}
        </div>
      )}

      {!loading && installed.length === 0 && (
        <EmptyState emoji="🧩" title="No installed plugins match" hint="Adjust the search or category filter." />
      )}

      <ul className="space-y-2">
        {installed.map((p, i) => {
          const open = expanded === p.id
          const isBusy = busy[p.id]
          return (
            <li
              key={p.id}
              style={{ ['--i' as string]: Math.min(i, 14) }}
              className="animate-fade-up overflow-hidden rounded-xl border border-white/[0.07] bg-white/[0.02] transition-colors hover:border-white/15"
            >
              <div className="flex items-center gap-3 p-3.5">
                <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-white/[0.05] text-lg" aria-hidden>
                  {CATEGORY_EMOJI[p.category]}
                </span>

                <button
                  onClick={() => setExpanded(open ? null : p.id)}
                  aria-expanded={open}
                  className="min-w-0 flex-1 text-left"
                >
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="truncate text-[13px] font-semibold text-text">{p.name}</span>
                    <span className="font-mono text-[10px] text-subtext/45">v{p.version}</span>
                    {p.official && <Badge tone="sky">official</Badge>}
                    {p.dependencies.length > 0 && <Badge tone="gold">{p.dependencies.length} deps</Badge>}
                  </div>
                  <p className="mt-0.5 line-clamp-1 text-[11.5px] text-subtext/60">{p.description}</p>
                </button>

                <div className="hidden shrink-0 text-right sm:block">
                  <p className="font-mono text-[11px] text-subtext/55">{formatBytes(p.size)}</p>
                  <p className="text-[10px] text-subtext/40">{timeAgo(p.updatedAt)}</p>
                </div>

                <Toggle
                  checked={p.enabled}
                  onChange={(v) => void onToggle(p, v)}
                  label={`${p.enabled ? 'Disable' : 'Enable'} ${p.name}`}
                />
              </div>

              {open && (
                <div className="animate-fade-up space-y-3 border-t border-white/[0.05] px-3.5 py-3">
                  <dl className="grid gap-2 text-[11.5px] sm:grid-cols-2">
                    <Field label="Author" value={p.author} />
                    <Field label="Category" value={p.category} />
                    <Field label="Requires" value={p.requires ?? 'any'} />
                    <Field label="Hooks" value={p.hooks.length ? p.hooks.join(', ') : 'none registered'} />
                  </dl>

                  {p.dependencies.length > 0 && (
                    <div>
                      <p className="mb-1.5 text-[11px] text-subtext/55">Dependencies</p>
                      <div className="flex flex-wrap gap-1.5">
                        {p.dependencies.map((d) => (
                          <code key={d} className="rounded border border-white/[0.08] bg-crust/60 px-2 py-0.5 font-mono text-[10.5px] text-accent">
                            {d}
                          </code>
                        ))}
                      </div>
                    </div>
                  )}

                  <div className="flex gap-2 pt-0.5">
                    <Button icon="🔗" onClick={() => p.homepage && window.open(p.homepage, '_blank', 'noopener')}>
                      Homepage
                    </Button>
                    <Button icon="⌨️" onClick={() => { void navigator.clipboard.writeText(`ash plugin status ${p.id}`); toast.info('Copied', 'ash plugin status ' + p.id) }}>
                      CLI
                    </Button>
                    <Button variant="danger" icon="🗑️" loading={isBusy} onClick={() => void onRemove(p)}>
                      Remove
                    </Button>
                  </div>
                </div>
              )}
            </li>
          )
        })}
      </ul>
    </Panel>
  )
}

function Chip({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'shrink-0 rounded-full border px-2.5 py-1 text-[11px] capitalize transition-all duration-200 active:scale-95',
        active
          ? 'border-accent/40 bg-accent/12 text-accent'
          : 'border-white/[0.07] text-subtext/60 hover:border-white/20 hover:text-text',
      )}
    >
      {children}
    </button>
  )
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline gap-2">
      <dt className="shrink-0 text-subtext/45">{label}</dt>
      <dd className="min-w-0 truncate text-text capitalize">{value}</dd>
    </div>
  )
}
