/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║  🌐 ASH DOTFILES v5.0 OMEGA — offline fixture generator                   ║
 * ║                                                                           ║
 * ║  Every value is derived from a seeded PRNG, so the dashboard looks        ║
 * ║  identical on every reload. Numbers that a real daemon would report are   ║
 * ║  shaped exactly like the daemon's output — this is a stand-in, not a      ║
 * ║  second source of truth.                                                  ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
import type {
  DoctorCheck, DoctorReport, HardwareInfo, Keybind, LogEntry, MetricPoint,
  Mode, Palette, Plugin, Snapshot, Theme, Wallpaper,
} from './types'
import { contrastRatio, rgbToHex, seededRandom, themeContrast, toOklch } from './utils'

const rnd = seededRandom(0xa5a5_1e1e)

/* ═══════════════════════════════════════════════════════════════════════════
   § 1  THEME FIXTURES
   ═══════════════════════════════════════════════════════════════════════════ */

export const PALETTES: Record<string, Palette> = {
  mocha: {
    base: '#1e1e2e', mantle: '#181825', crust: '#11111b', surface: '#313244',
    overlay: '#45475a', text: '#cdd6f4', subtext: '#a6adc8', accent: '#cba6f7',
    mint: '#a6e3a1', sky: '#89dceb', gold: '#f9e2af', rose: '#f38ba8', violet: '#b4befe',
  },
  macchiato: {
    base: '#24273a', mantle: '#1e2030', crust: '#181926', surface: '#363a4f',
    overlay: '#494d64', text: '#cad3f5', subtext: '#a5adcb', accent: '#c6a0f6',
    mint: '#a6da95', sky: '#91d7e3', gold: '#eed49f', rose: '#ed8796', violet: '#b7bdf8',
  },
  frappe: {
    base: '#303446', mantle: '#292c3c', crust: '#232634', surface: '#414559',
    overlay: '#51576d', text: '#c6d0f5', subtext: '#a5adce', accent: '#ca9ee6',
    mint: '#a6d189', sky: '#99d1db', gold: '#e5c890', rose: '#e78284', violet: '#babbf1',
  },
  latte: {
    base: '#eff1f5', mantle: '#e6e9ef', crust: '#dce0e8', surface: '#ccd0da',
    overlay: '#9ca0b0', text: '#4c4f69', subtext: '#5c5f77', accent: '#8839ef',
    mint: '#40a02b', sky: '#04a5e5', gold: '#df8e1d', rose: '#d20f39', violet: '#7287fd',
  },
  nord: {
    base: '#2e3440', mantle: '#292e39', crust: '#242933', surface: '#3b4252',
    overlay: '#434c5e', text: '#eceff4', subtext: '#d8dee9', accent: '#88c0d0',
    mint: '#a3be8c', sky: '#81a1c1', gold: '#ebcb8b', rose: '#bf616a', violet: '#b48ead',
  },
  gruvbox: {
    base: '#282828', mantle: '#1d2021', crust: '#141617', surface: '#3c3836',
    overlay: '#504945', text: '#ebdbb2', subtext: '#d5c4a1', accent: '#d79921',
    mint: '#b8bb26', sky: '#83a598', gold: '#fabd2f', rose: '#fb4934', violet: '#d3869b',
  },
  tokyonight: {
    base: '#1a1b26', mantle: '#16161e', crust: '#101014', surface: '#292e42',
    overlay: '#3b4261', text: '#c0caf5', subtext: '#a9b1d6', accent: '#bb9af7',
    mint: '#9ece6a', sky: '#7dcfff', gold: '#e0af68', rose: '#f7768e', violet: '#7aa2f7',
  },
  dracula: {
    base: '#282a36', mantle: '#21222c', crust: '#191a21', surface: '#44475a',
    overlay: '#6272a4', text: '#f8f8f2', subtext: '#bfbfbf', accent: '#bd93f9',
    mint: '#50fa7b', sky: '#8be9fd', gold: '#f1fa8c', rose: '#ff5555', violet: '#ff79c6',
  },
  rosepine: {
    base: '#191724', mantle: '#1f1d2e', crust: '#16141f', surface: '#26233a',
    overlay: '#403d52', text: '#e0def4', subtext: '#908caa', accent: '#c4a7e7',
    mint: '#9ccfd8', sky: '#31748f', gold: '#f6c177', rose: '#eb6f92', violet: '#ebbcba',
  },
  everforest: {
    base: '#2d353b', mantle: '#272e33', crust: '#232a2e', surface: '#343f44',
    overlay: '#475258', text: '#d3c6aa', subtext: '#9da9a0', accent: '#a7c080',
    mint: '#83c092', sky: '#7fbbb3', gold: '#dbbc7f', rose: '#e67e80', violet: '#d699b6',
  },
  kanagawa: {
    base: '#1f1f28', mantle: '#1a1a22', crust: '#16161d', surface: '#2a2a37',
    overlay: '#363646', text: '#dcd7ba', subtext: '#c8c093', accent: '#7e9cd8',
    mint: '#98bb6c', sky: '#7fb4ca', gold: '#e6c384', rose: '#e82424', violet: '#957fb8',
  },
  onedark: {
    base: '#282c34', mantle: '#22262e', crust: '#1b1f23', surface: '#3e4451',
    overlay: '#4b5263', text: '#abb2bf', subtext: '#828997', accent: '#61afef',
    mint: '#98c379', sky: '#56b6c2', gold: '#e5c07b', rose: '#e06c75', violet: '#c678dd',
  },
  catppuccin_amber: {
    base: '#1e1e2e', mantle: '#181825', crust: '#11111b', surface: '#313244',
    overlay: '#45475a', text: '#cdd6f4', subtext: '#a6adc8', accent: '#fab387',
    mint: '#a6e3a1', sky: '#89dceb', gold: '#f9e2af', rose: '#eba0ac', violet: '#f5c2e7',
  },
  catppuccin_teal: {
    base: '#1e1e2e', mantle: '#181825', crust: '#11111b', surface: '#313244',
    overlay: '#45475a', text: '#cdd6f4', subtext: '#a6adc8', accent: '#94e2d5',
    mint: '#a6e3a1', sky: '#89dceb', gold: '#f9e2af', rose: '#f38ba8', violet: '#89b4fa',
  },
}

const THEME_META: Array<[keyof typeof PALETTES, string, string, string[], 'dark' | 'light']> = [
  ['mocha', 'Catppuccin Mocha', 'catppuccin', ['dark', 'pastel', 'popular'], 'dark'],
  ['macchiato', 'Catppuccin Macchiato', 'catppuccin', ['dark', 'pastel'], 'dark'],
  ['frappe', 'Catppuccin Frappé', 'catppuccin', ['dark', 'pastel'], 'dark'],
  ['latte', 'Catppuccin Latte', 'catppuccin', ['light', 'pastel'], 'light'],
  ['nord', 'Nord', 'arcticicestudio', ['dark', 'cold', 'minimal'], 'dark'],
  ['gruvbox', 'Gruvbox Dark', 'morhetz', ['dark', 'retro', 'warm', 'popular'], 'dark'],
  ['tokyonight', 'Tokyo Night', 'enkia', ['dark', 'neon', 'popular'], 'dark'],
  ['dracula', 'Dracula', 'zenorocha', ['dark', 'purple', 'popular'], 'dark'],
  ['rosepine', 'Rosé Pine', 'rose-pine', ['dark', 'muted', 'elegant'], 'dark'],
  ['everforest', 'Everforest', 'sainnhe', ['dark', 'green', 'natural'], 'dark'],
  ['kanagawa', 'Kanagawa', 'rebelot', ['dark', 'japanese', 'muted'], 'dark'],
  ['onedark', 'One Dark', 'atom', ['dark', 'classic', 'balanced'], 'dark'],
  ['catppuccin_amber', 'Mocha Amber', 'ash', ['dark', 'warm', 'generated'], 'dark'],
  ['catppuccin_teal', 'Mocha Teal', 'ash', ['dark', 'cool', 'generated'], 'dark'],
]

/** Builds one theme record from palette + metadata, computing real contrast. */
function makeTheme(
  key: keyof typeof PALETTES, name: string, author: string,
  tags: string[], variant: 'dark' | 'light',
): Theme {
  const colors = PALETTES[key] as Palette
  const base: Theme = {
    id: key.replace(/_/g, '-'),
    name,
    author,
    version: '1.0.0',
    description: `${name} — ${variant} palette with ${tags.slice(0, 2).join(', ')} character.`,
    source: author === 'ash' ? 'generated' : 'builtin',
    variant,
    colors,
    tags,
    contrast: 0,
    hue: toOklch(colors.accent).h,
    downloads: Math.floor(rnd() * 48000) + 400,
    rating: Number((4.2 + rnd() * 0.79).toFixed(2)),
    installedAt: new Date(Date.now() - rnd() * 90 * 864e5).toISOString(),
  }
  base.contrast = Number(themeContrast(base).toFixed(2))
  return base
}

export const themes = (): Theme[] => THEME_META.map((m) => makeTheme(...m))

export function theme(id: string): Theme | undefined {
  return themes().find((t) => t.id === id)
}

/** Deterministic "AI" theme synthesis — hashes the prompt into a hue. */
export function generatedTheme(prompt: string): Theme {
  let h = 2166136261
  for (let i = 0; i < prompt.length; i++) {
    h ^= prompt.charCodeAt(i)
    h = Math.imul(h, 16777619) >>> 0
  }
  const hue = h % 360
  const hx = (l: number, c: number, hh: number) => oklchToHex(l, c, hh)

  const colors: Palette = {
    base: hx(0.18, 0.022, hue), mantle: hx(0.15, 0.024, hue), crust: hx(0.12, 0.026, hue),
    surface: hx(0.28, 0.028, hue), overlay: hx(0.38, 0.03, hue),
    text: hx(0.93, 0.02, hue), subtext: hx(0.76, 0.025, hue),
    accent: hx(0.78, 0.15, hue), mint: hx(0.83, 0.14, (hue + 130) % 360),
    sky: hx(0.84, 0.11, (hue + 190) % 360), gold: hx(0.88, 0.12, (hue + 60) % 360),
    rose: hx(0.75, 0.16, (hue + 330) % 360),
    violet: hx(0.79, 0.13, (hue + 280) % 360),
  }

  const t: Theme = {
    id: `gen-${hue.toString(36)}-${Date.now().toString(36)}`,
    name: prompt.slice(0, 40) || 'Generated',
    author: 'ash · AI engine',
    version: '1.0.0',
    description: `Synthesised from "${prompt}" — OKLCH hue ${hue}°, WCAG-checked.`,
    source: 'generated',
    variant: 'dark',
    colors,
    tags: ['generated', 'ai'],
    contrast: 0,
    hue,
  }
  t.contrast = Number(themeContrast(t).toFixed(2))
  return t
}

/** Minimal OKLCH → sRGB conversion, used only by the generator above. */
function oklchToHex(L: number, C: number, hDeg: number): string {
  const h = (hDeg * Math.PI) / 180
  const a = C * Math.cos(h)
  const b = C * Math.sin(h)

  const l_ = L + 0.3963377774 * a + 0.2158037573 * b
  const m_ = L - 0.1055613458 * a - 0.0638541728 * b
  const s_ = L - 0.0894841775 * a - 1.291485548 * b

  const l = l_ ** 3, m = m_ ** 3, s = s_ ** 3

  const lr = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
  const lg = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
  const lb = -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s

  const gamma = (v: number) => (v <= 0.0031308 ? 12.92 * v : 1.055 * v ** (1 / 2.4) - 0.055)
  return rgbToHex(gamma(lr) * 255, gamma(lg) * 255, gamma(lb) * 255)
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 2  PLUGINS
   ═══════════════════════════════════════════════════════════════════════════ */

const PLUGIN_SEED: Array<[string, Plugin['category'], string, boolean]> = [
  ['game-mode', 'system', 'Per-game Hyprland rules, GPU governor and notification suppression.', true],
  ['auto-theme', 'appearance', 'Switches theme by time of day with a smooth 12-step crossfade.', true],
  ['wallpaper-sync', 'appearance', 'Rotates wallpapers per workspace and matches the palette to each image.', true],
  ['clipboard-history', 'productivity', 'Searchable clipboard ring with pinning and regex filters.', true],
  ['power-tuner', 'system', 'Per-profile CPU governor and EPP tuning wired to the mode machine.', true],
  ['media-controls', 'integration', 'MPRIS bindings for playerctl across every running player.', true],
  ['focus-timer', 'productivity', 'Pomodoro state machine that drives the focus mode and DND.', false],
  ['git-status', 'integration', 'Repo status in the bar with worktree and ahead/behind counts.', false],
  ['weather-widget', 'integration', 'Waybar module with animated conditions and 15-minute cache.', false],
  ['screenshot-suite', 'system', 'Region/window/full capture with annotation and OCR.', true],
  ['emoji-picker', 'fun', 'Rofi-based emoji and kaomoji picker with recents.', true],
  ['night-light', 'appearance', 'Colour-temperature ramp tied to sunset and sunrise.', false],
  ['audio-visualizer', 'fun', 'cava-driven bars rendered into the Waybar custom module.', false],
  ['backup-guard', 'security', 'Checks snapshot integrity on a timer and alerts on drift.', false],
  ['keybind-cheatsheet', 'productivity', 'Overlay cheatsheet generated from the live Hyprland bind tree.', true],
  ['session-restore', 'system', 'Reopens windows per workspace after a reboot.', false],
  ['vpn-indicator', 'security', 'Tunnel state in the bar with one-key connect.', false],
  ['disk-analyzer', 'system', 'Treemap of the biggest directories with safe-clean actions.', false],
  ['ai-assistant', 'fun', 'Local LLM panel for config questions and natural-language edits.', false],
  ['docker-watch', 'integration', 'Container health, logs and quick actions from the dashboard.', false],
  ['ssh-vault', 'security', 'Encrypted SSH key inventory with agent lifetime control.', false],
  ['music-theme', 'appearance', 'Extracts album art colours and re-themes the desktop live.', false],
  ['brightness-curve', 'system', 'Non-linear backlight curve that follows ambient light.', false],
  ['window-tiler', 'system', 'Adds master-stack and spiral layouts to the compositor.', false],
  ['notification-filter', 'productivity', 'Mutes and re-routes notifications by app and content regex.', false],
  ['systemd-cockpit', 'system', 'Units, timers and journal tail in one panel.', false],
  ['wallpaper-shuffle', 'appearance', 'Weighted random rotation with per-monitor sets.', false],
  ['theme-marketplace', 'appearance', 'Browse and one-click install community themes.', false],
  ['locale-switcher', 'system', 'Quick language and keyboard-layout switching.', false],
  ['battery-health', 'system', 'Charge-limit control and cycle-count history.', false],
]

export const plugins = (): Plugin[] =>
  PLUGIN_SEED.map(([id, category, description, enabled], i) => {
    const r = seededRandom(i * 7919 + 13)
    return {
      id,
      name: id.split('-').map((w) => w[0]!.toUpperCase() + w.slice(1)).join(' '),
      version: `${Math.floor(r() * 2) + 1}.${Math.floor(r() * 9)}.${Math.floor(r() * 9)}`,
      author: i % 4 === 0 ? 'ash-core' : ['community', 'ash-core', 'kossmos', 'northstar'][i % 4]!,
      description,
      category,
      enabled,
      installed: i < 24,
      official: i % 4 === 0,
      requires: i % 5 === 0 ? '>=5.0.0' : '>=4.6.0',
      dependencies: i % 7 === 0 ? ['jq>=1.6', 'playerctl>=2.4'] : [],
      hooks: ['pre_theme', 'post_apply'].slice(0, (i % 3)),
      size: Math.floor(r() * 4_000_000) + 24_000,
      updatedAt: new Date(Date.now() - r() * 200 * 864e5).toISOString(),
      homepage: `https://github.com/ash-dotfiles/plugin-${id}`,
    }
  })

/* ═══════════════════════════════════════════════════════════════════════════
   § 3  SNAPSHOTS / MODES / SYSTEM
   ═══════════════════════════════════════════════════════════════════════════ */

export const snapshots = (): Snapshot[] =>
  Array.from({ length: 14 }, (_, i) => {
    const r = seededRandom(i * 104729 + 7)
    const age = r() * 30 * 864e5
    const triggers: Snapshot['trigger'][] = ['manual', 'auto', 'pre-update', 'pre-rollback']
    return {
      id: `snap-${(Date.now() - age).toString(36)}-${i}`,
      label: ['pre-theme-swap', 'weekly-baseline', 'before-nvim-refactor', 'auto-rotate', 'post-install'][i % 5]!,
      createdAt: new Date(Date.now() - age).toISOString(),
      size: Math.floor(r() * 900_000_000) + 12_000_000,
      files: Math.floor(r() * 4000) + 800,
      trigger: triggers[i % 4]!,
      compressed: r() > 0.25,
      checksum: Array.from({ length: 12 }, () => '0123456789abcdef'[Math.floor(r() * 16)]).join(''),
      restorable: i < 12,
    }
  }).sort((a, b) => +new Date(b.createdAt) - +new Date(a.createdAt))

export const newSnapshot = (label: string): Snapshot => ({
  id: `snap-${Date.now().toString(36)}-new`,
  label: label || 'manual-snapshot',
  createdAt: new Date().toISOString(),
  size: 148_000_000,
  files: 2248,
  trigger: 'manual',
  compressed: true,
  checksum: 'a1b2c3d4e5f6',
  restorable: true,
})

export const modes = (): Mode[] => [
  { id: 'default', name: 'Default', emoji: '🏠', description: 'Balanced daily driver.', accent: '#89b4fa', active: true, powerProfile: 'balanced', effects: ['Standard keybinds', '20 min idle lock'] },
  { id: 'gaming', name: 'Gaming', emoji: '🎮', description: 'Maximum frame pacing, notifications silenced.', accent: '#f38ba8', active: false, powerProfile: 'performance', effects: ['Tearing allowed', 'Compositor vfr off', 'DND on', 'GameMode daemon'] },
  { id: 'work', name: 'Work', emoji: '💼', description: 'Focus on comms and terminals.', accent: '#a6e3a1', active: false, powerProfile: 'balanced', effects: ['Workspace layout 2-5 dev', 'Calendar widget'] },
  { id: 'focus', name: 'Focus', emoji: '🎯', description: 'Deep-work: distractions blocked.', accent: '#cba6f7', active: false, powerProfile: 'balanced', effects: ['DND on', 'Site blocker', 'Pomodoro 50/10'] },
  { id: 'cinema', name: 'Cinema', emoji: '🍿', description: 'Media playback with dimming.', accent: '#f9e2af', active: false, powerProfile: 'balanced', effects: ['Idle inhibit', 'Display dim', 'Ambient bias light'] },
  { id: 'presentation', name: 'Presentation', emoji: '📊', description: 'External display, notifications off.', accent: '#fab387', active: false, powerProfile: 'balanced', effects: ['Mirror output', 'DND on', 'Cursor highlight'] },
  { id: 'streaming', name: 'Streaming', emoji: '📡', description: 'OBS scene links and chat overlay.', accent: '#f5c2e7', active: false, powerProfile: 'performance', effects: ['Scene hotkeys', 'Mic ducking'] },
  { id: 'battery', name: 'Battery', emoji: '🔋', description: 'Aggressive power saving.', accent: '#94e2d5', active: false, powerProfile: 'power-saver', effects: ['30fps cap', 'Blur off', 'Wi-Fi power save'] },
  { id: 'privacy', name: 'Privacy', emoji: '🛡️', description: 'Camera/mic hard-blocked, VPN on.', accent: '#f38ba8', active: false, powerProfile: 'balanced', effects: ['Sensors blocked', 'VPN required'] },
  { id: 'accessibility', name: 'Accessibility', emoji: '♿', description: 'High contrast, larger cursor, sticky keys.', accent: '#89dceb', active: false, powerProfile: 'balanced', effects: ['High contrast', 'Sticky keys', 'Screen reader'] },
]

export const hardware = (): HardwareInfo => {
  const r = seededRandom(4242)
  return {
    hostname: 'ash-omega',
    distro: 'Arch Linux',
    kernel: '6.11.6-arch1-1',
    compositor: 'Hyprland',
    compositorVersion: '0.44.1',
    cpu: { model: 'AMD Ryzen 9 7940HS', cores: 8, threads: 16, usage: 12 + r() * 20, temp: 42 + r() * 14 },
    memory: { total: 32 * 1024 ** 3, used: (9 + r() * 6) * 1024 ** 3, available: (17 - r() * 4) * 1024 ** 3, swapUsed: r() * 512 * 1024 ** 2 },
    gpu: { vendor: 'AMD', model: 'Radeon 780M', driver: 'amdgpu 6.11.6', usage: 8 + r() * 45, vram: 512 * 1024 ** 2 },
    disks: [
      { mount: '/', fs: 'btrfs', total: 953 * 1024 ** 3, used: 412 * 1024 ** 3 },
      { mount: '/home', fs: 'btrfs', total: 1863 * 1024 ** 3, used: 1214 * 1024 ** 3 },
    ],
    battery: { percent: 78, charging: false, health: 94.2, timeRemaining: 15480 },
    displays: [
      { name: 'eDP-1', resolution: '2560x1600', refresh: 165, scale: 1.5 },
      { name: 'DP-3', resolution: '3440x1440', refresh: 100, scale: 1 },
    ],
  }
}

export const metrics = (): MetricPoint[] => {
  const r = seededRandom(99)
  const now = Date.now()
  return Array.from({ length: 60 }, (_, i) => ({
    t: now - (59 - i) * 2000,
    cpu: 10 + r() * 45,
    memory: 40 + r() * 25,
    gpu: 5 + r() * 40,
    network: r() * 900,
    disk: r() * 120,
  }))
}

/** Advances the metric series by one point — the live simulator's tick. */
export function stepMetrics(series: MetricPoint[]): MetricPoint[] {
  const last = series[series.length - 1] ?? { cpu: 20, memory: 50, gpu: 20, network: 100, disk: 30, t: Date.now() }
  const drift = (v: number, target: number, k = 0.18) => v + (target - v) * k + (Math.random() - 0.5) * 6
  return [
    ...series.slice(-59),
    {
      t: Date.now(),
      cpu: Math.max(1, Math.min(100, drift(last.cpu, 14 + Math.random() * 40))),
      memory: Math.max(5, Math.min(100, drift(last.memory, 55, 0.05))),
      gpu: Math.max(0, Math.min(100, drift(last.gpu, Math.random() * 45))),
      network: Math.max(0, drift(last.network, Math.random() * 800, 0.3)),
      disk: Math.max(0, drift(last.disk, Math.random() * 90, 0.3)),
    },
  ]
}

export const doctor = (): DoctorReport => {
  const checks: DoctorCheck[] = [
    ['hyprland', 'Compositor', 'Hyprland is running and reachable via IPC', 'pass', '0.44.1 responding on $XDG_RUNTIME_DIR/hypr'],
    ['waybar', 'Desktop', 'Waybar process is active', 'pass', '2 bars, 41 modules loaded'],
    ['notifications', 'Desktop', 'Dunst/Mako notification daemon registered', 'pass', 'org.freedesktop.Notifications owned by mako'],
    ['fonts', 'Typography', 'All 14 required Nerd Font glyph ranges present', 'pass', 'JetBrainsMono Nerd Font 3.2.1'],
    ['python', 'Runtime', 'Python >= 3.10 with required wheels', 'pass', '3.12.7 at /usr/bin/python3'],
    ['shaders', 'Performance', 'Blur and shadow pipelines compile without error', 'warn', 'Shadow radius 24px exceeds the recommended 16px on iGPU'],
    ['themes', 'Theming', 'All installed themes pass WCAG AA for body text', 'pass', '14 themes checked, minimum ratio 7.4'],
    ['plugins', 'Extensibility', 'No plugin reports a missing dependency', 'pass', '24 installed, 0 broken'],
    ['snapshots', 'Recovery', 'A restorable snapshot exists in the last 7 days', 'pass', 'weekly-baseline is 2 days old'],
    ['disk', 'Storage', '/home has more than 15% free space', 'warn', '/home at 65% — 649 GiB free'],
    ['gpu', 'Hardware', 'Hardware video acceleration is enabled', 'pass', 'VA-API on amdgpu'],
    ['secureboot', 'Security', 'Secure Boot state matches the enrolled keys', 'fail', 'Module nvidia is unsigned and blocked by lockdown'],
    ['firewall', 'Security', 'A firewall is active on all interfaces', 'pass', 'nftables, default drop inbound'],
    ['updates', 'Maintenance', 'No pending package upgrades older than 30 days', 'skip', 'pacman db is 2 hours old'],
  ].map(([id, category, title, status, message]) => ({
    id: id as string, category: category as string, title: title as string,
    status: status as DoctorCheck['status'], message: message as string,
    fix: status === 'fail' || status === 'warn'
      ? `ash doctor --fix ${id}`
      : undefined,
  }))

  const summary = { pass: 0, warn: 0, fail: 0, skip: 0 }
  checks.forEach((c) => { summary[c.status]++ })
  const score = Math.round(((summary.pass + summary.warn * 0.5) / checks.length) * 100)
  return { generatedAt: new Date().toISOString(), score, checks, summary }
}

const LOG_LEVELS: LogEntry['level'][] = ['trace', 'debug', 'info', 'warn', 'error', 'fatal']
const LOG_SCOPES = ['core', 'theme', 'plugin', 'hypr', 'waybar', 'snapshot', 'ipc', 'doctor', 'update']
const LOG_MESSAGES = [
  'theme applied', 'plugin hook completed', 'socket reconnect', 'config reloaded',
  'wallpaper rotated', 'snapshot verified', 'dependency resolved', 'cache evicted',
  'mode transition', 'notification dispatched', 'timer scheduled', 'lock acquired',
]

export function logs(limit = 300): LogEntry[] {
  const r = seededRandom(1337)
  return Array.from({ length: limit }, (_, i) => {
    const level = LOG_LEVELS[Math.floor(r() ** 2 * LOG_LEVELS.length)]!
    return {
      ts: new Date(Date.now() - (limit - i) * 3400 * (0.4 + r())).toISOString(),
      level,
      scope: LOG_SCOPES[Math.floor(r() * LOG_SCOPES.length)]!,
      message: LOG_MESSAGES[Math.floor(r() * LOG_MESSAGES.length)]!,
      fields: { pid: Math.floor(r() * 30000) + 1000, dur: Number((r() * 240).toFixed(1)) },
    }
  })
}

export function randomLog(): LogEntry {
  return {
    ts: new Date().toISOString(),
    level: LOG_LEVELS[Math.floor(Math.random() * 4)]!,
    scope: LOG_SCOPES[Math.floor(Math.random() * LOG_SCOPES.length)]!,
    message: LOG_MESSAGES[Math.floor(Math.random() * LOG_MESSAGES.length)]!,
    fields: { pid: Math.floor(Math.random() * 30000) + 1000, dur: Number((Math.random() * 240).toFixed(1)) },
  }
}

export const wallpapers = (): Wallpaper[] =>
  ['aurora-drift', 'monolith', 'koi-pond', 'neon-alley', 'paper-texture', 'mountain-dusk',
   'circuit-glow', 'ink-wash', 'solar-flare', 'deep-field', 'glass-shards', 'forest-fog']
    .map((name, i) => {
      const r = seededRandom(i * 6151 + 5)
      const hue = Math.floor(r() * 360)
      const colors = Array.from({ length: 5 }, (_, k) => oklchToHex(0.25 + k * 0.14, 0.06 + r() * 0.1, (hue + k * 24) % 360))
      const cats = ['abstract', 'nature', 'city', 'minimal', 'space']
      return {
        id: `wp-${i + 1}`,
        name: name.replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
        category: cats[i % cats.length]!,
        resolution: ['3840x2160', '2560x1600', '3440x1440', '5120x2880'][i % 4]!,
        size: Math.floor(r() * 12_000_000) + 900_000,
        colors,
        dominant: colors[2]!,
        animated: i % 5 === 0,
      }
    })

export const keybinds = (): Keybind[] => [
  { keys: ['SUPER', 'RETURN'], action: 'exec', category: 'Launcher', description: 'Open terminal (kitty)' },
  { keys: ['SUPER', 'D'], action: 'exec', category: 'Launcher', description: 'Application launcher (rofi)' },
  { keys: ['SUPER', 'Q'], action: 'killactive', category: 'Window', description: 'Close focused window' },
  { keys: ['SUPER', 'F'], action: 'fullscreen', category: 'Window', description: 'Toggle fullscreen' },
  { keys: ['SUPER', 'V'], action: 'togglefloating', category: 'Window', description: 'Toggle floating' },
  { keys: ['SUPER', '1..9'], action: 'workspace', category: 'Workspace', description: 'Switch workspace 1–9' },
  { keys: ['SUPER', 'SHIFT', '1..9'], action: 'movetoworkspace', category: 'Workspace', description: 'Move window to workspace' },
  { keys: ['SUPER', 'H/J/K/L'], action: 'movefocus', category: 'Focus', description: 'Vim-style directional focus' },
  { keys: ['SUPER', 'SHIFT', 'H/J/K/L'], action: 'swapwindow', category: 'Focus', description: 'Swap window in direction' },
  { keys: ['SUPER', 'TAB'], action: 'cyclenext', category: 'Focus', description: 'Cycle windows' },
  { keys: ['SUPER', 'S'], action: 'togglespecialworkspace', category: 'Workspace', description: 'Scratchpad' },
  { keys: ['SUPER', 'P'], action: 'pseudo', category: 'Layout', description: 'Toggle pseudo-tiling' },
  { keys: ['SUPER', 'J'], action: 'togglesplit', category: 'Layout', description: 'Toggle split direction' },
  { keys: ['SUPER', 'SLASH'], action: 'exec', category: 'System', description: 'Keybind cheatsheet overlay' },
  { keys: ['SUPER', 'SHIFT', 'T'], action: 'exec', category: 'Theme', description: 'Cycle theme forward' },
  { keys: ['SUPER', 'SHIFT', 'W'], action: 'exec', category: 'Theme', description: 'Next wallpaper' },
  { keys: ['SUPER', 'L'], action: 'exec', category: 'System', description: 'Lock session (hyprlock)' },
  { keys: ['SUPER', 'SHIFT', 'S'], action: 'exec', category: 'System', description: 'Region screenshot' },
  { keys: ['SUPER', 'SHIFT', 'B'], action: 'exec', category: 'System', description: 'Restart waybar' },
  { keys: ['SUPER', 'SHIFT', 'R'], action: 'exec', category: 'System', description: 'Reload Hyprland config' },
  { keys: ['XF86AudioPlay'], action: 'exec', category: 'Media', description: 'Play/pause' },
  { keys: ['XF86AudioRaiseVolume'], action: 'exec', category: 'Media', description: 'Volume up' },
  { keys: ['XF86MonBrightnessUp'], action: 'exec', category: 'Media', description: 'Brightness up' },
  { keys: ['SUPER', 'ESCAPE'], action: 'exec', category: 'System', description: 'Power menu' },
]

export const health = () => ({ status: 'ok', version: '5.0.0-omega', uptime: 361_400 })

const COMMAND_TABLE: Record<string, string> = {
  'ash --version': 'ash 5.0.0-omega (bash 5.2.15)',
  'ash doctor': '✔ 14 checks · 11 pass · 2 warn · 1 fail · score 82%',
  'ash theme list': 'mocha, macchiato, frappe, latte, nord, gruvbox, tokyonight, dracula (8)',
  'ash plugin list': '30 plugins · 24 installed · 6 available',
  'ash snapshot list': '14 snapshots · newest 2d ago · 1.9 GiB total',
  'ash mode': 'default',
  'uname -a': 'Linux ash-omega 6.11.6-arch1-1 #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux',
  'hyprctl version': 'Hyprland, built from branch main at commit 0f7e3f2 (0.44.1)',
  'wpctl status': 'PipeWire 1.2.5 · 4 sinks · 6 sources',
}

export function fakeCommand(cmd: string): { stdout: string; stderr: string; code: number } {
  const key = cmd.trim()
  if (key in COMMAND_TABLE) return { stdout: COMMAND_TABLE[key]!, stderr: '', code: 0 }
  if (/^(rm|dd|mkfs|shutdown|reboot|poweroff)\b/.test(key)) {
    return { stdout: '', stderr: `ash: refusing to run destructive command in demo mode: ${key}\n`, code: 126 }
  }
  if (key.startsWith('ash ')) {
    return { stdout: `ash: ${key.slice(4)} — demo mode, no daemon attached.\n`, stderr: '', code: 0 }
  }
  return { stdout: `demo shell: ${key}\n`, stderr: '', code: 0 }
}

/* ── exports used by the Home page hero counters ─────────────────────────── */
export const STATS = {
  files: 2248,
  lines: 725_976,
  themes: 14,
  plugins: 30,
  keybinds: 24,
  commands: 115,
}

export { contrastRatio }
