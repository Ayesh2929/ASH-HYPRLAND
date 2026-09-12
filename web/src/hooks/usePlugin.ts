/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — plugin hook
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { useMemo } from 'react'
import { usePluginStore } from '../store/pluginStore'

export function usePlugins() {
  const plugins = usePluginStore((s) => s.plugins)
  const category = usePluginStore((s) => s.category)
  const query = usePluginStore((s) => s.query)
  const setCategory = usePluginStore((s) => s.setCategory)
  const setQuery = usePluginStore((s) => s.setQuery)

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    return plugins.filter((p) => {
      if (category && p.category !== category) return false
      if (!q) return true
      return p.name.toLowerCase().includes(q) || p.description.toLowerCase().includes(q)
    })
  }, [plugins, category, query])

  const stats = useMemo(() => ({
    total: plugins.length,
    installed: plugins.filter((p) => p.installed).length,
    enabled: plugins.filter((p) => p.enabled).length,
    available: plugins.filter((p) => !p.installed).length,
  }), [plugins])

  return { plugins, filtered, stats, category, query, setCategory, setQuery }
}
