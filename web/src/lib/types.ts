/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║  🌐 ASH DOTFILES v5.0 OMEGA — shared domain types                         ║
 * ║                                                                           ║
 * ║  These mirror api/schemas/*.json exactly; the API is the source of truth  ║
 * ║  and a change there must be reflected here.                              ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */

/** A colour scheme, as produced by ash-cli/lib/color-engine. */
export interface Palette {
  base: string
  mantle: string
  crust: string
  surface: string
  overlay: string
  text: string
  subtext: string
  accent: string
  mint: string
  sky: string
  gold: string
  rose: string
  violet: string
}

export type ThemeSource = 'builtin' | 'generated' | 'imported' | 'marketplace'

export interface Theme {
  id: string
  name: string
  author: string
  version: string
  description: string
  source: ThemeSource
  /** "dark" | "light" — drives the color-scheme and contrast checks. */
  variant: 'dark' | 'light'
  colors: Palette
  tags: string[]
  /** WCAG 2.1 minimum contrast ratio across text/background pairs, 1–21. */
  contrast: number
  /** OKLCH hue angle 0–360, useful for sorting visually. */
  hue: number
  downloads?: number
  rating?: number
  installedAt?: string
  preview?: string
}

export interface Plugin {
  id: string
  name: string
  version: string
  author: string
  description: string
  category: 'productivity' | 'appearance' | 'system' | 'integration' | 'fun' | 'security'
  enabled: boolean
  installed: boolean
  official: boolean
  /** Semver ranges this plugin needs from the host, e.g. ">=5.0.0". */
  requires?: string
  dependencies: string[]
  hooks: string[]
  size: number
  updatedAt: string
  homepage?: string
}

export interface Snapshot {
  id: string
  label: string
  createdAt: string
  size: number
  files: number
  /** "manual" | "auto" | "pre-update" | "pre-rollback" */
  trigger: 'manual' | 'auto' | 'pre-update' | 'pre-rollback'
  compressed: boolean
  checksum: string
  restorable: boolean
}

export type ModeId =
  | 'default' | 'gaming' | 'work' | 'focus' | 'cinema'
  | 'presentation' | 'streaming' | 'battery' | 'privacy' | 'accessibility'

export interface Mode {
  id: ModeId
  name: string
  emoji: string
  description: string
  accent: string
  active: boolean
  /** Populated from the state-machine guard list, shown as "what changes". */
  effects: string[]
  powerProfile: 'power-saver' | 'balanced' | 'performance'
}

export type CheckStatus = 'pass' | 'warn' | 'fail' | 'skip'

export interface DoctorCheck {
  id: string
  category: string
  title: string
  status: CheckStatus
  message: string
  /** Shell command that would resolve a warn/fail result. */
  fix?: string
}

export interface DoctorReport {
  generatedAt: string
  score: number
  checks: DoctorCheck[]
  summary: Record<CheckStatus, number>
}

export interface HardwareInfo {
  hostname: string
  distro: string
  kernel: string
  compositor: string
  compositorVersion: string
  cpu: { model: string; cores: number; threads: number; usage: number; temp: number }
  memory: { total: number; used: number; available: number; swapUsed: number }
  gpu: { vendor: string; model: string; driver: string; usage: number; vram: number }
  disks: Array<{ mount: string; fs: string; total: number; used: number }>
  battery?: { percent: number; charging: boolean; health: number; timeRemaining: number }
  displays: Array<{ name: string; resolution: string; refresh: number; scale: number }>
}

export interface LogEntry {
  ts: string
  level: 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'fatal'
  scope: string
  message: string
  fields?: Record<string, string | number>
}

export interface MetricPoint {
  t: number
  cpu: number
  memory: number
  gpu: number
  network: number
  disk: number
}

export interface Wallpaper {
  id: string
  name: string
  category: string
  resolution: string
  size: number
  colors: string[]
  dominant: string
  animated: boolean
}

export interface Keybind {
  keys: string[]
  action: string
  category: string
  description: string
}

export interface WSMessage<T = unknown> {
  type: 'metrics' | 'log' | 'notification' | 'plugin' | 'theme' | 'snapshot' | 'pong' | 'hello'
  ts: number
  payload: T
}

export interface ApiError {
  status: number
  message: string
  detail?: string
}
