/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — settings
 * ═══════════════════════════════════════════════════════════════════════════
 *  Preferences persist to localStorage and are mirrored into the daemon's
 *  config overlay when one is attached. Each control explains its effect —
 *  a setting nobody understands is a setting nobody uses.
 */
import { useEffect, useState } from 'react'
import { useThemeStore } from '../store/themeStore'
import { cn } from '../lib/utils'
import { Badge, Button, Input, Panel, SectionHeader, Slider, Tabs, Toggle, useToast } from './ui'

export interface Preferences {
  animations: boolean
  reduceMotion: boolean
  highContrast: boolean
  telemetry: boolean
  autoSnapshot: boolean
  autoUpdate: boolean
  notifications: boolean
  compactMode: boolean
  metricInterval: number
  snapshotRetention: number
  logLevel: 'trace' | 'debug' | 'info' | 'warn' | 'error'
  accentOverride: string
}

const DEFAULTS: Preferences = {
  animations: true,
  reduceMotion: false,
  highContrast: false,
  telemetry: false,
  autoSnapshot: true,
  autoUpdate: false,
  notifications: true,
  compactMode: false,
  metricInterval: 2,
  snapshotRetention: 14,
  logLevel: 'info',
  accentOverride: '',
}

const KEY = 'ash-preferences'

export function loadPreferences(): Preferences {
  try {
    const raw = localStorage.getItem(KEY)
    return raw ? { ...DEFAULTS, ...(JSON.parse(raw) as Partial<Preferences>) } : DEFAULTS
  } catch {
    return DEFAULTS
  }
}

export default function SettingsPanel() {
  const [prefs, setPrefs] = useState<Preferences>(loadPreferences)
  const [tab, setTab] = useState<'general' | 'appearance' | 'advanced'>('general')
  const theme = useThemeStore((s) => s.active)
  const toast = useToast()

  useEffect(() => {
    localStorage.setItem(KEY, JSON.stringify(prefs))
    // Mirror the motion + contrast choices onto <html> so CSS can respond.
    document.documentElement.classList.toggle('reduce-motion', prefs.reduceMotion || !prefs.animations)
    document.documentElement.classList.toggle('high-contrast', prefs.highContrast)
    document.documentElement.classList.toggle('compact', prefs.compactMode)
    if (prefs.accentOverride && /^#[0-9a-fA-F]{6}$/.test(prefs.accentOverride)) {
      const h = prefs.accentOverride.slice(1)
      document.documentElement.style.setProperty(
        '--ash-accent',
        `${parseInt(h.slice(0, 2), 16)} ${parseInt(h.slice(2, 4), 16)} ${parseInt(h.slice(4, 6), 16)}`,
      )
    }
  }, [prefs])

  const set = <K extends keyof Preferences>(k: K, v: Preferences[K]) =>
    setPrefs((p) => ({ ...p, [k]: v }))

  const reset = () => {
    setPrefs(DEFAULTS)
    toast.info('Settings reset', 'All preferences restored to defaults.')
  }

  return (
    <Panel>
      <SectionHeader
        icon="⚙️"
        title="Preferences"
        subtitle="Stored locally and applied immediately. Nothing leaves this machine."
        action={
          <Tabs
            value={tab}
            onChange={setTab}
            tabs={[
              { id: 'general', label: 'General' },
              { id: 'appearance', label: 'Appearance' },
              { id: 'advanced', label: 'Advanced' },
            ]}
          />
        }
      />

      {tab === 'general' && (
        <div className="space-y-1">
          <Row
            title="Automatic snapshots"
            hint="Take a restore point before every theme change, mode switch and update."
          >
            <Toggle checked={prefs.autoSnapshot} onChange={(v) => set('autoSnapshot', v)} label="Automatic snapshots" />
          </Row>

          <Row title="Check for updates" hint="Poll the release channel daily. A snapshot is taken before applying.">
            <Toggle checked={prefs.autoUpdate} onChange={(v) => set('autoUpdate', v)} label="Check for updates" />
          </Row>

          <Row title="Desktop notifications" hint="Let ASH post to the system notification daemon.">
            <Toggle checked={prefs.notifications} onChange={(v) => set('notifications', v)} label="Desktop notifications" />
          </Row>

          <Row title="Anonymous telemetry" hint="Local-only counters used by `ash telemetry report`. Never uploaded; disabled by default.">
            <Toggle checked={prefs.telemetry} onChange={(v) => set('telemetry', v)} label="Telemetry" />
          </Row>

          <div className="pt-4">
            <Slider
              label="Snapshot retention (most recent kept)"
              value={prefs.snapshotRetention}
              min={3}
              max={60}
              onChange={(v) => set('snapshotRetention', v)}
              unit=" snapshots"
            />
          </div>
        </div>
      )}

      {tab === 'appearance' && (
        <div className="space-y-1">
          <Row title="Animations" hint="Entrance transitions, charts and the aurora backdrop.">
            <Toggle checked={prefs.animations} onChange={(v) => set('animations', v)} label="Animations" />
          </Row>

          <Row title="Reduce motion" hint="Force every transition to complete instantly. Also honoured from your OS setting.">
            <Toggle checked={prefs.reduceMotion} onChange={(v) => set('reduceMotion', v)} label="Reduce motion" />
          </Row>

          <Row title="High contrast" hint="Raise border and text contrast to meet WCAG AAA at the cost of subtlety.">
            <Toggle checked={prefs.highContrast} onChange={(v) => set('highContrast', v)} label="High contrast" />
          </Row>

          <Row title="Compact density" hint="Tighter padding and smaller rows for small displays.">
            <Toggle checked={prefs.compactMode} onChange={(v) => set('compactMode', v)} label="Compact mode" />
          </Row>

          <div className="pt-4">
            <Input
              label="Accent override"
              placeholder={theme?.colors.accent ?? '#cba6f7'}
              value={prefs.accentOverride}
              onChange={(e) => set('accentOverride', e.target.value)}
              hint="Leave empty to follow the active theme."
              error={prefs.accentOverride && !/^#[0-9a-fA-F]{6}$/.test(prefs.accentOverride) ? 'Use a 6-digit hex value like #cba6f7' : undefined}
            />
          </div>
        </div>
      )}

      {tab === 'advanced' && (
        <div className="space-y-1">
          <div className="pt-2">
            <Slider
              label="Metrics polling interval"
              value={prefs.metricInterval}
              min={1}
              max={10}
              onChange={(v) => set('metricInterval', v)}
              unit="s"
            />
          </div>

          <div className="pt-5">
            <p className="mb-1.5 text-[12px] font-medium text-subtext">Daemon log level</p>
            <p className="mb-2.5 text-[11px] text-subtext/55">
              Lower levels are more verbose. `trace` writes every IPC round trip.
            </p>
            <div className="flex flex-wrap gap-1.5">
              {(['trace', 'debug', 'info', 'warn', 'error'] as const).map((l) => (
                <button
                  key={l}
                  onClick={() => set('logLevel', l)}
                  className={cn(
                    'rounded-lg border px-3 py-1.5 font-mono text-[11px] transition-all active:scale-95',
                    prefs.logLevel === l
                      ? 'border-accent/45 bg-accent/12 text-accent'
                      : 'border-white/[0.07] text-subtext/60 hover:border-white/20 hover:text-text',
                  )}
                >
                  {l}
                </button>
              ))}
            </div>
          </div>

          <div className="pt-6">
            <div className="rounded-xl border border-warn/20 bg-gold/[0.06] p-3.5">
              <p className="flex items-center gap-2 text-[12px] font-semibold text-gold">
                <span aria-hidden>⚠️</span> Danger zone
              </p>
              <p className="mt-1 text-[11.5px] text-subtext/70">
                Resetting clears every local preference. Your themes, plugins and snapshots are untouched.
              </p>
              <div className="mt-3 flex flex-wrap gap-2">
                <Button variant="danger" icon="↩️" onClick={reset}>Reset preferences</Button>
                <Button
                  icon="📤"
                  onClick={() => {
                    const blob = new Blob([JSON.stringify(prefs, null, 2)], { type: 'application/json' })
                    const a = document.createElement('a')
                    a.href = URL.createObjectURL(blob)
                    a.download = 'ash-preferences.json'
                    a.click()
                    URL.revokeObjectURL(a.href)
                    toast.success('Preferences exported')
                  }}
                >
                  Export JSON
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="mt-5 flex items-center justify-between">
        <Badge tone="mint" dot>saved automatically</Badge>
        <span className="font-mono text-[10.5px] text-subtext/40">localStorage · ash-preferences</span>
      </div>
    </Panel>
  )
}

function Row({ title, hint, children }: { title: string; hint: string; children: React.ReactNode }) {
  return (
    <div className="flex items-start justify-between gap-6 border-b border-white/[0.04] py-3.5 last:border-0">
      <div className="min-w-0">
        <p className="text-[12.5px] font-medium text-text">{title}</p>
        <p className="mt-0.5 text-[11.5px] leading-relaxed text-subtext/55">{hint}</p>
      </div>
      <div className="shrink-0 pt-0.5">{children}</div>
    </div>
  )
}
