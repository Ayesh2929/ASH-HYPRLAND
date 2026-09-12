/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — wallpaper picker
 * ═══════════════════════════════════════════════════════════════════════════
 *  Thumbnails are generated from each wallpaper's extracted palette, so the
 *  grid renders instantly with no image payload — and it doubles as a preview
 *  of what the theme generator would produce from that image.
 */
import { useEffect, useMemo, useState } from 'react'
import type { Wallpaper } from '../lib/types'
import { api } from '../api/client'
import { useThemeStore } from '../store/themeStore'
import { cn, formatBytes } from '../lib/utils'
import { Badge, Button, Panel, SectionHeader, Skeleton, useToast } from './ui'

export default function WallpaperPicker() {
  const [items, setItems] = useState<Wallpaper[] | null>(null)
  const [selected, setSelected] = useState<string | null>(null)
  const [category, setCategory] = useState<string | null>(null)
  const theme = useThemeStore((s) => s.active)
  const toast = useToast()

  useEffect(() => {
    let alive = true
    void api.wallpapers().then((w) => { if (alive) setItems(w) })
    return () => { alive = false }
  }, [])

  const categories = useMemo(() => [...new Set((items ?? []).map((w) => w.category))].sort(), [items])

  const filtered = useMemo(
    () => (items ?? []).filter((w) => !category || w.category === category),
    [items, category],
  )

  const apply = (w: Wallpaper) => {
    setSelected(w.id)
    toast.success(`Wallpaper set`, `${w.name} · ${w.resolution}`)
  }

  return (
    <Panel>
      <SectionHeader
        icon="🖼️"
        title="Wallpapers"
        subtitle={items ? `${items.length} images · palette-matched to the active theme` : 'Loading library…'}
        action={theme && <Badge tone="accent">{theme.name}</Badge>}
      />

      <div className="mb-4 flex flex-wrap gap-1.5">
        <button
          onClick={() => setCategory(null)}
          className={cn(
            'rounded-full border px-2.5 py-1 text-[11px] capitalize transition-all',
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
              'rounded-full border px-2.5 py-1 text-[11px] capitalize transition-all',
              category === c ? 'border-accent/40 bg-accent/12 text-accent' : 'border-white/[0.07] text-subtext/60 hover:text-text',
            )}
          >
            {c}
          </button>
        ))}
      </div>

      {!items && (
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 6 }, (_, i) => <Skeleton key={i} className="h-36" />)}
        </div>
      )}

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {filtered.map((w, i) => (
          <button
            key={w.id}
            onClick={() => apply(w)}
            style={{ ['--i' as string]: i }}
            className={cn(
              'group animate-fade-up overflow-hidden rounded-xl border text-left transition-all duration-300',
              'hover:-translate-y-1 hover:shadow-lift',
              selected === w.id ? 'border-accent/45 shadow-glow' : 'border-white/[0.07] hover:border-white/20',
            )}
          >
            <div
              className="relative h-28"
              style={{
                background: `linear-gradient(135deg, ${w.colors[0]} 0%, ${w.colors[2]} 50%, ${w.colors[4]} 100%)`,
              }}
            >
              {/* Soft "mountains" so each tile reads as a distinct image. */}
              <svg viewBox="0 0 100 60" className="absolute inset-0 h-full w-full opacity-35" preserveAspectRatio="none" aria-hidden>
                <polygon points={`0,60 ${22 + (i % 3) * 6},${22 + (i % 4) * 5} ${45},60`} fill={w.dominant} />
                <polygon points={`30,60 ${58 - (i % 3) * 5},${14 + (i % 5) * 6} ${88},60`} fill={w.colors[3]} />
                <circle cx={78} cy={16} r={7} fill={w.colors[1]} />
              </svg>
              {w.animated && (
                <span className="absolute right-2 top-2 animate-pulse rounded-full bg-black/40 px-2 py-0.5 text-[10px] font-semibold text-white backdrop-blur-sm">
                  ● LIVE
                </span>
              )}
              {selected === w.id && (
                <span className="absolute left-2 top-2 animate-scale-in rounded-full bg-mint px-2 py-0.5 text-[10px] font-bold text-crust">
                  ✓ SET
                </span>
              )}
            </div>
            <div className="flex items-center justify-between gap-2 bg-mantle/60 p-2.5">
              <div className="min-w-0">
                <p className="truncate text-[12px] font-medium text-text">{w.name}</p>
                <p className="font-mono text-[10px] text-subtext/45">
                  {w.resolution} · {formatBytes(w.size)}
                </p>
              </div>
              <span className="flex shrink-0 gap-0.5" aria-hidden>
                {w.colors.slice(0, 4).map((c) => (
                  <span key={c} className="h-3 w-3 rounded-full ring-1 ring-inset ring-black/20" style={{ background: c }} />
                ))}
              </span>
            </div>
          </button>
        ))}
      </div>

      {items && items.length > 0 && (
        <div className="mt-4 flex justify-end">
          <Button icon="🎲" onClick={() => {
            const pick = items[Math.floor(Math.random() * items.length)]
            if (pick) apply(pick)
          }}>
            Surprise me
          </Button>
        </div>
      )}
    </Panel>
  )
}
