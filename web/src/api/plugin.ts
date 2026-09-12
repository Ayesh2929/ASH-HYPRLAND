/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — plugin endpoints
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { api } from './client'
import type { Plugin } from '../lib/types'

export const pluginApi = {
  list: (): Promise<Plugin[]> => api.plugins(),
  enable: (id: string) => api.togglePlugin(id, true),
  disable: (id: string) => api.togglePlugin(id, false),
  install: (id: string) => api.installPlugin(id),
  remove: (id: string) => api.removePlugin(id),
}

/** Groups plugins by category, preserving a stable category order. */
export function groupByCategory(plugins: Plugin[]): Array<[string, Plugin[]]> {
  const order = ['system', 'appearance', 'productivity', 'integration', 'security', 'fun']
  const map = new Map<string, Plugin[]>()
  for (const p of plugins) {
    const arr = map.get(p.category) ?? []
    arr.push(p)
    map.set(p.category, arr)
  }
  return [...map.entries()].sort((a, b) => order.indexOf(a[0]) - order.indexOf(b[0]))
}
