/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║  🌐 ASH DOTFILES v5.0 OMEGA — formatting & colour utilities               ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
import type { Palette, Theme } from './types'

/* ── class names ─────────────────────────────────────────────────────────── */
export type ClassValue = string | false | null | undefined | ClassValue[] | Record<string, boolean>

/** Tiny `clsx`: joins the truthy entries without pulling in a dependency. */
export function cn(...inputs: ClassValue[]): string {
  const out: string[] = []
  const walk = (v: ClassValue): void => {
    if (!v) return
    if (typeof v === 'string') { out.push(v); return }
    if (Array.isArray(v)) { v.forEach(walk); return }
    for (const [k, on] of Object.entries(v)) if (on) out.push(k)
  }
  inputs.forEach(walk)
  return out.join(' ')
}

/* ── numbers & sizes ─────────────────────────────────────────────────────── */
export function formatBytes(bytes: number, decimals = 1): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return '0 B'
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'] as const
  const i = Math.min(Math.floor(Math.log2(bytes) / 10), units.length - 1)
  return `${(bytes / 2 ** (i * 10)).toFixed(i === 0 ? 0 : decimals)} ${units[i]}`
}

export function formatNumber(n: number): string {
  if (Math.abs(n) < 1000) return String(Math.round(n))
  return new Intl.NumberFormat('en', { notation: 'compact', maximumFractionDigits: 1 }).format(n)
}

export function formatPercent(n: number, decimals = 0): string {
  return `${n.toFixed(decimals)}%`
}

export function formatDuration(seconds: number): string {
  if (seconds < 60) return `${Math.round(seconds)}s`
  const d = Math.floor(seconds / 86400)
  const h = Math.floor((seconds % 86400) / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  if (d) return `${d}d ${h}h`
  if (h) return `${h}h ${m}m`
  return `${m}m`
}

/* ── dates ───────────────────────────────────────────────────────────────── */
const RTF = new Intl.RelativeTimeFormat('en', { numeric: 'auto' })

export function timeAgo(iso: string): string {
  const then = new Date(iso).getTime()
  if (Number.isNaN(then)) return '—'
  const diff = (then - Date.now()) / 1000
  const table: Array<[Intl.RelativeTimeFormatUnit, number]> = [
    ['year', 31536000], ['month', 2592000], ['week', 604800],
    ['day', 86400], ['hour', 3600], ['minute', 60], ['second', 1],
  ]
  for (const [unit, secs] of table) {
    if (Math.abs(diff) >= secs || unit === 'second') return RTF.format(Math.round(diff / secs), unit)
  }
  return 'just now'
}

export function formatTime(ts: string | number, withSeconds = true): string {
  const d = new Date(ts)
  if (Number.isNaN(d.getTime())) return '—'
  return d.toLocaleTimeString('en-GB', {
    hour: '2-digit', minute: '2-digit',
    ...(withSeconds ? { second: '2-digit' as const } : {}),
  })
}

/* ── colour ──────────────────────────────────────────────────────────────── */
export function hexToRgb(hex: string): [number, number, number] {
  let h = hex.replace('#', '').trim()
  if (h.length === 3) h = h.split('').map((c) => c + c).join('')
  // 8-digit hex carries alpha in the last byte — ignore it for RGB maths.
  if (h.length === 8) h = h.slice(0, 6)
  if (h.length !== 6) return [0, 0, 0]
  return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)]
}

export function rgbToHex(r: number, g: number, b: number): string {
  const c = (v: number) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0')
  return `#${c(r)}${c(g)}${c(b)}`
}

export function withAlpha(hex: string, alpha: number): string {
  const [r, g, b] = hexToRgb(hex)
  const a = Math.max(0, Math.min(1, alpha))
  return `rgba(${r}, ${g}, ${b}, ${a})`
}

/** WCAG 2.1 relative luminance. */
export function luminance(hex: string): number {
  const lin = (c: number) => {
    const s = c / 255
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4
  }
  const [r, g, b] = hexToRgb(hex)
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
}

/** WCAG contrast ratio, 1 → 21. */
export function contrastRatio(a: string, b: string): number {
  const la = luminance(a)
  const lb = luminance(b)
  const [hi, lo] = la > lb ? [la, lb] : [lb, la]
  return (hi + 0.05) / (lo + 0.05)
}

/** sRGB → OKLCH. Used to sort themes, not to render them. */
export function toOklch(hex: string): { l: number; c: number; h: number } {
  const lin = (v: number) => {
    const s = v / 255
    return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4
  }
  const [r8, g8, b8] = hexToRgb(hex)
  const r = lin(r8), g = lin(g8), b = lin(b8)

  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)

  const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s
  const A = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s
  const B = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s

  const c = Math.hypot(A, B)
  let h = (Math.atan2(B, A) * 180) / Math.PI
  if (h < 0) h += 360
  return { l: L, c, h }
}

/** Picks black or white for maximum contrast against `bg`. */
export function readableOn(bg: string): '#000000' | '#ffffff' {
  return contrastRatio(bg, '#ffffff') >= contrastRatio(bg, '#000000') ? '#ffffff' : '#000000'
}

export function themeContrast(theme: Theme): number {
  const c = theme.colors
  // The three pairs a user actually reads text in.
  return Math.min(
    contrastRatio(c.text, c.base),
    contrastRatio(c.subtext, c.base),
    contrastRatio(c.accent, c.base),
  )
}

export const PALETTE_KEYS: ReadonlyArray<keyof Palette> = [
  'base', 'mantle', 'crust', 'surface', 'overlay',
  'text', 'subtext', 'accent', 'mint', 'sky', 'gold', 'rose', 'violet',
]

/* ── misc ────────────────────────────────────────────────────────────────── */
export function clamp(v: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, v))
}

export function debounce<A extends unknown[]>(fn: (...a: A) => void, ms = 250) {
  let t: ReturnType<typeof setTimeout> | undefined
  return (...a: A) => {
    if (t) clearTimeout(t)
    t = setTimeout(() => fn(...a), ms)
  }
}

/** Deterministic id, avoids crypto.randomUUID's secure-context requirement. */
export function uid(prefix = 'id'): string {
  return `${prefix}_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`
}

export function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
}

/**
 * Mulberry32 — a small, fast, *seeded* PRNG.
 * The mock data layer uses this so the dashboard renders identically on every
 * reload instead of shuffling numbers on each paint.
 */
export function seededRandom(seed: number): () => number {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
