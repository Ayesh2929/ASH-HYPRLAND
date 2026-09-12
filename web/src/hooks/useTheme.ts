/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — theme hook
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { useMemo } from 'react'
import { useThemeStore } from '../store/themeStore'
import type { Theme } from '../lib/types'

export function useTheme() {
  const themes = useThemeStore((s) => s.themes)
  const active = useThemeStore((s) => s.active)
  const filter = useThemeStore((s) => s.filter)
  const setFilter = useThemeStore((s) => s.setFilter)

  const filtered = useMemo(() => {
    const q = filter.query.trim().toLowerCase()
    return themes.filter((t) => {
      if (filter.variant !== 'all' && t.variant !== filter.variant) return false
      if (filter.tag && !t.tags.includes(filter.tag)) return false
      if (!q) return true
      return (
        t.name.toLowerCase().includes(q) ||
        t.author.toLowerCase().includes(q) ||
        t.tags.some((tag) => tag.includes(q))
      )
    })
  }, [themes, filter])

  /** Every tag in use, with counts — drives the filter chips. */
  const tags = useMemo(() => {
    const counts = new Map<string, number>()
    for (const t of themes) for (const tag of t.tags) counts.set(tag, (counts.get(tag) ?? 0) + 1)
    return [...counts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
  }, [themes])

  return { themes, filtered, active, tags, filter, setFilter }
}

export function useThemePreview(): {
  onEnter: (t: Theme) => void
  onLeave: () => void
} {
  const preview = useThemeStore((s) => s.previewTheme)
  return {
    onEnter: (t: Theme) => preview(t),
    onLeave: () => preview(null),
  }
}
