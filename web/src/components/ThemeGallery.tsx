/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — theme gallery
 * ═══════════════════════════════════════════════════════════════════════════
 *  Hovering a card live-previews the palette across the whole dashboard and
 *  restores the committed theme on leave. Clicking commits it.
 */
import { useMemo, useState } from 'react'
import type { Theme } from '../lib/types'
import { useThemeStore } from '../store/themeStore'
import { useTheme } from '../hooks/useTheme'
import { cn, PALETTE_KEYS } from '../lib/utils'
import { Badge, Button, EmptyState, Input, Panel, SectionHeader, Skeleton, Tabs, useToast } from './ui'

type SortKey = 'name' | 'contrast' | 'hue' | 'downloads'

export default function ThemeGallery({ onEdit }: { onEdit?: (t: Theme) => void }) {
  const { filtered, loading } = useThemeState()
  const themes = useThemeStore((s) => s.themes)
  const active = useThemeStore((s) => s.active)
  const apply = useThemeStore((s) => s.apply)
  const previewTheme = useThemeStore((s) => s.previewTheme)
  const { filter, setFilter, tags } = useTheme()

  const [sort, setSort] = useState<SortKey>('name')
  const toast = useToast()

  const sorted = useMemo(() => {
    const copy = [...filtered]
    switch (sort) {
      case 'contrast': return copy.sort((a, b) => b.contrast - a.contrast)
      case 'hue':      return copy.sort((a, b) => a.hue - b.hue)
      case 'downloads':return copy.sort((a, b) => (b.downloads ?? 0) - (a.downloads ?? 0))
      default:         return copy.sort((a, b) => a.name.localeCompare(b.name))
    }
  }, [filtered, sort])

  const onApply = async (t: Theme) => {
    await apply(t.id)
    toast.success('Theme applied', `${t.name} · contrast ${t.contrast.toFixed(1)}:1`)
  }

  return (
    <Panel>
      <SectionHeader
        icon="🎨"
        title="Themes"
        subtitle={`${filtered.length} of ${themes.length} palettes · hover to preview, click to apply`}
        action={
          <Tabs
            value={sort}
            onChange={setSort}
            tabs={[
              { id: 'name', label: 'A–Z' },
              { id: 'contrast', label: 'Contrast' },
              { id: 'hue', label: 'Hue' },
              { id: 'downloads', label: 'Popular' },
            ]}
          />
        }
      />

      <div className="mb-4 flex flex-wrap items-center gap-2.5">
        <div className="min-w-[14rem] flex-1">
          <Input
            placeholder="Search by name, author or tag…"
            value={filter.query}
            onChange={(e) => setFilter({ query: e.target.value })}
            prefix="🔍"
          />
        </div>
        <Tabs
          value={filter.variant}
          onChange={(v) => setFilter({ variant: v })}
          tabs={[
            { id: 'all', label: 'All' },
            { id: 'dark', label: 'Dark' },
            { id: 'light', label: 'Light' },
          ]}
        />
      </div>

      {tags.length > 0 && (
        <div className="mb-5 flex flex-wrap gap-1.5">
          <button
            onClick={() => setFilter({ tag: null })}
            className={cn(
              'rounded-full border px-2.5 py-1 text-[11px] transition-all duration-200',
              !filter.tag ? 'border-accent/40 bg-accent/12 text-accent' : 'border-white/[0.07] text-subtext/60 hover:text-text',
            )}
          >
            all tags
          </button>
          {tags.slice(0, 12).map(([tag, count]) => (
            <button
              key={tag}
              onClick={() => setFilter({ tag: filter.tag === tag ? null : tag })}
              className={cn(
                'rounded-full border px-2.5 py-1 text-[11px] transition-all duration-200',
                filter.tag === tag
                  ? 'border-accent/40 bg-accent/12 text-accent'
                  : 'border-white/[0.07] text-subtext/60 hover:border-white/20 hover:text-text',
              )}
            >
              {tag} <span className="font-mono text-[10px] opacity-50">{count}</span>
            </button>
          ))}
        </div>
      )}

      {loading && themes.length === 0 && (
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 6 }, (_, i) => <Skeleton key={i} className="h-44" />)}
        </div>
      )}

      {!loading && sorted.length === 0 && (
        <EmptyState
          emoji="🔍"
          title="No themes match those filters"
          hint="Try clearing the search box or picking a different tag."
          action={<Button onClick={() => setFilter({ query: '', tag: null, variant: 'all' })}>Reset filters</Button>}
        />
      )}

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {sorted.map((t, i) => {
          const isActive = active?.id === t.id
          return (
            <article
              key={t.id}
              onMouseEnter={() => previewTheme(t)}
              onMouseLeave={() => previewTheme(null)}
              onFocus={() => previewTheme(t)}
              onBlur={() => previewTheme(null)}
              style={{ ['--i' as string]: Math.min(i, 12) }}
              className={cn(
                'group animate-fade-up overflow-hidden rounded-2xl border transition-all duration-300',
                'hover:-translate-y-1 hover:shadow-lift',
                isActive ? 'border-accent/45 shadow-glow' : 'border-white/[0.07] hover:border-white/20',
              )}
            >
              {/* ── Palette preview ──────────────────────────────────── */}
              <div className="relative h-24" style={{ background: t.colors.base }}>
                <div className="absolute inset-0 flex">
                  {PALETTE_KEYS.slice(0, 7).map((k) => (
                    <span key={k} className="flex-1 transition-all duration-500 group-hover:flex-[1.4]" style={{ background: t.colors[k] }} />
                  ))}
                </div>
                {/* A miniature terminal, so the preview shows the palette in use. */}
                <div className="absolute inset-x-3 bottom-2 rounded-lg p-2 font-mono text-[9px] leading-tight backdrop-blur-sm"
                     style={{ background: `${t.colors.base}dd`, color: t.colors.text }}>
                  <div><span style={{ color: t.colors.mint }}>➜</span> <span style={{ color: t.colors.accent }}>~/ash</span> theme apply</div>
                  <div style={{ color: t.colors.subtext }}>applied {(t.name.split(' ')[0] ?? t.name).toLowerCase()} ✓</div>
                </div>
                {isActive && (
                  <span className="absolute right-2 top-2 animate-scale-in rounded-full bg-mint/90 px-2 py-0.5 text-[10px] font-bold text-crust">
                    ACTIVE
                  </span>
                )}
              </div>

              <div className="space-y-2.5 p-3.5">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <h3 className="truncate text-[13px] font-semibold text-text">{t.name}</h3>
                    <p className="truncate text-[11px] text-subtext/55">by {t.author}</p>
                  </div>
                  <Badge tone={t.contrast >= 7 ? 'mint' : t.contrast >= 4.5 ? 'gold' : 'rose'}>
                    {t.contrast.toFixed(1)}:1
                  </Badge>
                </div>

                <div className="flex flex-wrap gap-1">
                  {t.tags.slice(0, 3).map((tag) => (
                    <span key={tag} className="rounded px-1.5 py-0.5 text-[10px] text-subtext/55" style={{ background: `${t.colors.surface}66` }}>
                      {tag}
                    </span>
                  ))}
                </div>

                <div className="flex gap-2 pt-0.5">
                  <Button
                    variant={isActive ? 'ghost' : 'primary'}
                    className="flex-1"
                    disabled={isActive}
                    onClick={() => void onApply(t)}
                  >
                    {isActive ? 'Applied' : 'Apply'}
                  </Button>
                  {onEdit && <Button icon="✏️" onClick={() => onEdit(t)} aria-label={`Edit ${t.name}`} />}
                </div>
              </div>
            </article>
          )
        })}
      </div>
    </Panel>
  )
}

/** Small adapter so the gallery can read loading state without a second store hook. */
function useThemeState() {
  const themes = useThemeStore((s) => s.themes)
  const loading = useThemeStore((s) => s.loading)
  const { filtered } = useTheme()
  return { filtered, loading: loading && themes.length === 0 }
}
