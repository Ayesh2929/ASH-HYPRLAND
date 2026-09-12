/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — mode selector
 * ═══════════════════════════════════════════════════════════════════════════
 *  Mirrors the `desktop_mode` state machine in ash-cli/lib/state-machine.sh.
 *  Selecting a mode animates the card, shows the effects it will apply, and
 *  only then commits — the confirmation step exists because switching to
 *  "gaming" mid-meeting is a real mistake users make.
 */
import { useState } from 'react'
import type { Mode } from '../lib/types'
import { useConfigStore } from '../store/configStore'
import { cn } from '../lib/utils'
import { Badge, Button, Modal, Panel, SectionHeader, Toggle, useToast } from './ui'

const PROFILE_TONE = {
  'power-saver': 'mint',
  balanced: 'sky',
  performance: 'rose',
} as const

export default function ModeSelector({ compact = false }: { compact?: boolean }) {
  const modes = useConfigStore((s) => s.modes)
  const setMode = useConfigStore((s) => s.setMode)
  const toast = useToast()

  const [pending, setPending] = useState<Mode | null>(null)
  const [confirmEach, setConfirmEach] = useState(false)

  const commit = async (mode: Mode) => {
    await setMode(mode.id)
    toast.success(`${mode.name} mode active`, mode.effects.join(' · '))
    setPending(null)
  }

  const choose = (mode: Mode) => {
    if (mode.active) return
    if (confirmEach) setPending(mode)
    else void commit(mode)
  }

  const list = compact ? modes.slice(0, 6) : modes

  return (
    <Panel>
      <SectionHeader
        icon="🎛️"
        title="Desktop mode"
        subtitle="Each mode is a validated state transition — the compositor, power profile and notification policy move together."
        action={
          <label className="flex shrink-0 cursor-pointer items-center gap-2 text-[11px] text-subtext/60">
            Confirm
            <Toggle size="sm" checked={confirmEach} onChange={setConfirmEach} label="Confirm mode switches" />
          </label>
        }
      />

      <div className={cn('grid gap-2.5', compact ? 'sm:grid-cols-3' : 'sm:grid-cols-2 xl:grid-cols-3')}>
        {list.map((m, i) => (
          <button
            key={m.id}
            onClick={() => choose(m)}
            aria-pressed={m.active}
            style={{ ['--i' as string]: i }}
            className={cn(
              'group relative overflow-hidden rounded-xl border p-3.5 text-left',
              'animate-fade-up transition-all duration-300 active:scale-[.98] hover:-translate-y-0.5',
              m.active
                ? 'border-transparent bg-white/[0.07] shadow-lift'
                : 'border-white/[0.07] bg-white/[0.02] hover:border-white/20',
            )}
          >
            {/* The mode's own accent, painted as a soft wash when active. */}
            <span
              className={cn(
                'pointer-events-none absolute inset-0 transition-opacity duration-500',
                m.active ? 'opacity-100' : 'opacity-0 group-hover:opacity-40',
              )}
              style={{ background: `radial-gradient(120% 100% at 0% 0%, ${m.accent}22, transparent 70%)` }}
              aria-hidden
            />
            {m.active && (
              <span
                className="absolute inset-x-0 top-0 h-[2px] animate-fade-in"
                style={{ background: `linear-gradient(90deg, transparent, ${m.accent}, transparent)` }}
                aria-hidden
              />
            )}

            <div className="relative flex items-start gap-3">
              <span
                className="grid h-9 w-9 shrink-0 place-items-center rounded-lg text-lg transition-transform duration-300 group-hover:scale-110"
                style={{ background: `${m.accent}1f` }}
                aria-hidden
              >
                {m.emoji}
              </span>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <p className="truncate text-[13px] font-semibold text-text">{m.name}</p>
                  {m.active && <Badge tone="mint" dot>active</Badge>}
                </div>
                <p className="mt-0.5 line-clamp-2 text-[11px] leading-relaxed text-subtext/65">
                  {m.description}
                </p>
                <div className="mt-2 flex flex-wrap items-center gap-1.5">
                  <Badge tone={PROFILE_TONE[m.powerProfile]}>{m.powerProfile}</Badge>
                  {m.effects.length > 0 && (
                    <span className="text-[10px] text-subtext/45">+{m.effects.length} effects</span>
                  )}
                </div>
              </div>
            </div>
          </button>
        ))}
      </div>

      <Modal
        open={pending !== null}
        onClose={() => setPending(null)}
        title={pending ? `Switch to ${pending.name} mode?` : ''}
        subtitle="These settings will be applied immediately."
        footer={
          <>
            <Button onClick={() => setPending(null)}>Cancel</Button>
            <Button variant="primary" icon={pending?.emoji} onClick={() => pending && void commit(pending)}>
              Apply {pending?.name}
            </Button>
          </>
        }
      >
        <ul className="space-y-2">
          {pending?.effects.map((e) => (
            <li key={e} className="flex items-center gap-2.5 rounded-lg border border-white/[0.06] bg-white/[0.02] px-3 py-2 text-[12px] text-subtext">
              <span className="text-mint" aria-hidden>✓</span>
              {e}
            </li>
          ))}
        </ul>
      </Modal>
    </Panel>
  )
}
