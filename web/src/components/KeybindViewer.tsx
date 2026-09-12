/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — keybind cheatsheet
 * ═══════════════════════════════════════════════════════════════════════════
 *  Renders the live Hyprland bind tree. Search is fuzzy on both the chord and
 *  the action, because people remember "the one that tiles" not "SUPER+J".
 */
import { useEffect, useMemo, useState } from 'react'
import type { Keybind } from '../lib/types'
import { api } from '../api/client'
import { cn } from '../lib/utils'
import { Badge, EmptyState, Input, Panel, SectionHeader, Skeleton } from './ui'

export default function KeybindViewer() {
  const [binds, setBinds] = useState<Keybind[] | null>(null)
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState<string | null>(null)

  useEffect(() => {
    let alive = true
    void api.keybinds().then((b) => { if (alive) setBinds(b) })
    return () => { alive = false }
  }, [])

  const categories = useMemo(
    () => [...new Set((binds ?? []).map((b) => b.category))].sort(),
    [binds],
  )

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    return (binds ?? []).filter((b) => {
      if (category && b.category !== category) return false
      if (!q) return true
      return (
        b.keys.join('+').toLowerCase().includes(q) ||
        b.action.toLowerCase().includes(q) ||
        b.description.toLowerCase().includes(q)
      )
    })
  }, [binds, query, category])

  return (
    <Panel>
      <SectionHeader
        icon="⌨️"
        title="Keybinds"
        subtitle={binds ? `${binds.length} bindings across ${categories.length} groups` : 'Reading the bind tree…'}
        action={<Badge tone="accent">hyprland.conf</Badge>}
      />

      <div className="mb-4 flex flex-wrap items-center gap-2.5">
        <div className="min-w-[14rem] flex-1">
          <Input prefix="🔍" placeholder="Search chords or actions…" value={query} onChange={(e) => setQuery(e.target.value)} />
        </div>
      </div>

      <div className="mb-4 flex flex-wrap gap-1.5">
        <button
          onClick={() => setCategory(null)}
          className={cn(
            'rounded-full border px-2.5 py-1 text-[11px] transition-all',
            !category ? 'border-accent/40 bg-accent/12 text-accent' : 'border-white/[0.07] text-subtext/60 hover:text-text',
          )}
        >
          all
        </button>
        {categories.map((c) => (
          <button
            key={c}
            onClick={() => setCategory(category === c ? null : c)}
            className={cn(
              'rounded-full border px-2.5 py-1 text-[11px] transition-all',
              category === c ? 'border-accent/40 bg-accent/12 text-accent' : 'border-white/[0.07] text-subtext/60 hover:text-text',
            )}
          >
            {c}
          </button>
        ))}
      </div>

      {!binds && (
        <div className="space-y-2">
          {Array.from({ length: 6 }, (_, i) => <Skeleton key={i} className="h-11" />)}
        </div>
      )}

      {binds && filtered.length === 0 && (
        <EmptyState emoji="🔍" title="No bindings match" hint="Try a different chord or clear the filters." />
      )}

      <ul className="grid gap-1.5 lg:grid-cols-2">
        {filtered.map((b, i) => (
          <li
            key={`${b.keys.join('+')}-${i}`}
            style={{ ['--i' as string]: i }}
            className="flex animate-fade-up items-center gap-3 rounded-lg border border-white/[0.05] bg-white/[0.02] px-3 py-2 transition-colors hover:border-white/15"
          >
            <span className="flex shrink-0 items-center gap-1">
              {b.keys.map((k, ki) => (
                <span key={k} className="flex items-center gap-1">
                  {ki > 0 && <span className="text-[9px] text-subtext/35">+</span>}
                  <kbd className="rounded-md border border-white/[0.12] bg-crust px-1.5 py-0.5 font-mono text-[10.5px] font-semibold text-text shadow-sm">
                    {k}
                  </kbd>
                </span>
              ))}
            </span>
            <span className="min-w-0 flex-1 truncate text-[12px] text-subtext">{b.description}</span>
            <code className="hidden shrink-0 font-mono text-[10px] text-accent/60 sm:block">{b.action}</code>
          </li>
        ))}
      </ul>
    </Panel>
  )
}
