/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — contrast helpers
 * ═══════════════════════════════════════════════════════════════════════════
 *  Kept in its own module so both the store and the components can import it
 *  without creating a cycle through utils.
 */
import type { Theme } from './types'
import { contrastRatio } from './utils'

/**
 * The three text-on-background pairs a user actually reads, reduced to the
 * worst of them. Reporting the minimum rather than the average means a theme
 * cannot look "accessible on average" while one label is unreadable.
 */
export function cv(theme: Theme): number {
  const c = theme.colors
  return Math.min(
    contrastRatio(c.text, c.base),
    contrastRatio(c.subtext, c.base),
    contrastRatio(c.accent, c.base),
  )
}

export function grade(ratio: number): { label: string; tone: 'mint' | 'sky' | 'gold' | 'rose' } {
  if (ratio >= 7) return { label: 'AAA', tone: 'mint' }
  if (ratio >= 4.5) return { label: 'AA', tone: 'sky' }
  if (ratio >= 3) return { label: 'AA-large', tone: 'gold' }
  return { label: 'fail', tone: 'rose' }
}
