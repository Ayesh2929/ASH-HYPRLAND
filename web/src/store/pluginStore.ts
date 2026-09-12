/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — plugin store
 * ═══════════════════════════════════════════════════════════════════════════
 *  Optimistic enable/disable: the switch flips immediately and rolls back if
 *  the daemon rejects the change. Users toggle these often; waiting on a round
 *  trip feels broken.
 */
import { create } from 'zustand'
import type { Plugin } from '../lib/types'
import { api } from '../api/client'

interface PluginState {
  plugins: Plugin[]
  loading: boolean
  error: string | null
  busy: Record<string, boolean>
  category: string | null
  query: string
  load: () => Promise<void>
  toggle: (id: string, enabled: boolean) => Promise<void>
  install: (id: string) => Promise<void>
  remove: (id: string) => Promise<void>
  setCategory: (c: string | null) => void
  setQuery: (q: string) => void
}

export const usePluginStore = create<PluginState>((set, get) => ({
  plugins: [],
  loading: false,
  error: null,
  busy: {},
  category: null,
  query: '',

  async load() {
    set({ loading: true, error: null })
    try {
      set({ plugins: await api.plugins(), loading: false })
    } catch (err) {
      set({ error: (err as Error).message, loading: false })
    }
  },

  async toggle(id, enabled) {
    const before = get().plugins
    set({
      plugins: before.map((p) => (p.id === id ? { ...p, enabled } : p)),
      busy: { ...get().busy, [id]: true },
    })
    try {
      await api.togglePlugin(id, enabled)
    } catch {
      set({ plugins: before })   // roll back — the daemon said no
    } finally {
      const busy = { ...get().busy }
      delete busy[id]
      set({ busy })
    }
  },

  async install(id) {
    set({ busy: { ...get().busy, [id]: true } })
    try {
      await api.installPlugin(id)
      set({ plugins: get().plugins.map((p) => (p.id === id ? { ...p, installed: true } : p)) })
    } finally {
      const busy = { ...get().busy }
      delete busy[id]
      set({ busy })
    }
  },

  async remove(id) {
    const before = get().plugins
    set({ plugins: before.filter((p) => p.id !== id) })
    try {
      await api.removePlugin(id)
    } catch {
      set({ plugins: before })
    }
  },

  setCategory(c) { set({ category: c }) },
  setQuery(q) { set({ query: q }) },
}))
