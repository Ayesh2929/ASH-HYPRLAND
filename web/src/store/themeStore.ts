/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — theme store
 * ═══════════════════════════════════════════════════════════════════════════
 *  Owns the theme list, the active theme, and the live preview. Applying a
 *  theme writes CSS custom properties onto <html> so every Tailwind colour
 *  utility repaints without a recompile.
 */
import { create } from 'zustand'
import type { Palette, Theme } from '../lib/types'
import { api } from '../api/client'
import { PALETTE_KEYS } from '../lib/utils'

const STORAGE_KEY = 'ash-theme'

/** Writes the palette into CSS custom properties consumed by globals.css. */
export function applyPaletteToDom(colors: Palette, variant: 'dark' | 'light'): void {
  const root = document.documentElement
  for (const key of PALETTE_KEYS) {
    const hex = colors[key]
    if (!hex) continue
    const [r, g, b] = toTriplet(hex)
    root.style.setProperty(`--ash-${key}`, `${r} ${g} ${b}`)
  }
  root.dataset.theme = variant === 'light' ? 'latte' : 'mocha'
  root.classList.toggle('dark', variant !== 'light')
}

function toTriplet(hex: string): [number, number, number] {
  let h = hex.replace('#', '')
  if (h.length === 3) h = h.split('').map((c) => c + c).join('')
  if (h.length === 8) h = h.slice(0, 6)
  return [
    parseInt(h.slice(0, 2), 16) || 0,
    parseInt(h.slice(2, 4), 16) || 0,
    parseInt(h.slice(4, 6), 16) || 0,
  ]
}

interface ThemeState {
  themes: Theme[]
  active: Theme | null
  /** Non-null while the user is hovering a card — previewed without saving. */
  preview: Theme | null
  loading: boolean
  error: string | null
  filter: { query: string; tag: string | null; variant: 'all' | 'dark' | 'light' }
  load: () => Promise<void>
  apply: (id: string) => Promise<void>
  previewTheme: (t: Theme | null) => void
  setFilter: (patch: Partial<ThemeState['filter']>) => void
  updateActiveColor: (key: keyof Palette, value: string) => void
  save: (t: Theme) => Promise<void>
  remove: (id: string) => Promise<void>
  generate: (prompt: string) => Promise<Theme | null>
}

export const useThemeStore = create<ThemeState>((set, get) => ({
  themes: [],
  active: null,
  preview: null,
  loading: false,
  error: null,
  filter: { query: '', tag: null, variant: 'all' },

  async load() {
    set({ loading: true, error: null })
    try {
      const themes = await api.themes()
      const savedId = localStorage.getItem(STORAGE_KEY)
      const active = themes.find((t) => t.id === savedId) ?? themes[0] ?? null
      if (active) applyPaletteToDom(active.colors, active.variant)
      set({ themes, active, loading: false })
    } catch (err) {
      set({ error: (err as Error).message, loading: false })
    }
  },

  async apply(id) {
    const theme = get().themes.find((t) => t.id === id)
    if (!theme) return
    applyPaletteToDom(theme.colors, theme.variant)
    localStorage.setItem(STORAGE_KEY, id)
    set({ active: theme, preview: null })
    // Fire-and-forget: the UI must not block on the daemon acknowledging.
    void api.applyTheme(id).catch(() => undefined)
  },

  previewTheme(t) {
    set({ preview: t })
    if (t) applyPaletteToDom(t.colors, t.variant)
    else {
      const active = get().active
      if (active) applyPaletteToDom(active.colors, active.variant)
    }
  },

  setFilter(patch) {
    set({ filter: { ...get().filter, ...patch } })
  },

  updateActiveColor(key, value) {
    const active = get().active
    if (!active) return
    const next: Theme = { ...active, colors: { ...active.colors, [key]: value } }
    applyPaletteToDom(next.colors, next.variant)
    set({ active: next })
  },

  async save(theme) {
    const saved = await api.saveTheme(theme)
    set({ themes: [...get().themes.filter((t) => t.id !== saved.id), saved] })
  },

  async remove(id) {
    await api.deleteTheme(id)
    const themes = get().themes.filter((t) => t.id !== id)
    set({ themes })
    if (get().active?.id === id) {
      const fallback = themes[0]
      if (fallback) await get().apply(fallback.id)
    }
  },

  async generate(prompt) {
    try {
      const t = await api.generateTheme(prompt)
      set({ themes: [t, ...get().themes] })
      return t
    } catch {
      return null
    }
  },
}))
