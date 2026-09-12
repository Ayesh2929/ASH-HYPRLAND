/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — theme endpoints
 * ═══════════════════════════════════════════════════════════════════════════
 *  Thin, typed façade over the shared client so feature code never builds
 *  URL strings by hand.
 */
import { api } from './client'
import type { Theme } from '../lib/types'

export const themeApi = {
  list: (): Promise<Theme[]> => api.themes(),
  get: (id: string): Promise<Theme> => api.theme(id),
  apply: (id: string) => api.applyTheme(id),
  save: (t: Theme) => api.saveTheme(t),
  remove: (id: string) => api.deleteTheme(id),
  generate: (prompt: string) => api.generateTheme(prompt),

  /** Exports a theme as the JSON the CLI's `ash theme import` expects. */
  toCliJson(t: Theme): string {
    return JSON.stringify(
      {
        name: t.name,
        author: t.author,
        version: t.version,
        variant: t.variant,
        tags: t.tags,
        colors: t.colors,
      },
      null,
      2,
    )
  },

  /** Serialises a palette to the `key=value` fragments used in .conf files. */
  toConf(t: Theme): string {
    return Object.entries(t.colors)
      .map(([k, v]) => `$${k} = rgb(${v.replace('#', '')})`)
      .join('\n')
  },
}
