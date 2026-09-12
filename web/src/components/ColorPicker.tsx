/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — colour picker
 * ═══════════════════════════════════════════════════════════════════════════
 *  Swatch grid + hex input + native picker, with a live contrast readout
 *  against the current background. Accessibility feedback while editing beats
 *  a warning after shipping.
 */
import { useEffect, useState } from 'react'
import { cn, contrastRatio, readableOn } from '../lib/utils'

export default function ColorPicker({
  label, value, background, onChange,
}: {
  label: string
  value: string
  /** Colour the swatch will sit on — used for the contrast badge. */
  background: string
  onChange: (hex: string) => void
}) {
  const [draft, setDraft] = useState(value)
  useEffect(() => setDraft(value), [value])

  const ratio = contrastRatio(value, background)
  const grade = ratio >= 7 ? 'AAA' : ratio >= 4.5 ? 'AA' : ratio >= 3 ? 'AA-large' : 'fail'
  const tone = ratio >= 7 ? 'text-mint' : ratio >= 4.5 ? 'text-sky' : ratio >= 3 ? 'text-gold' : 'text-rose'

  const commit = (hex: string) => {
    const clean = hex.startsWith('#') ? hex : `#${hex}`
    if (/^#?[0-9a-fA-F]{6}$/.test(clean)) {
      setDraft(clean.toLowerCase())
      onChange(clean.toLowerCase())
    }
  }

  // A compact ramp derived from the current value, so quick tweaks do not
  // require opening the OS colour dialog.
  const swatches = [0, 15, 30, 45, 60, 75, 90].map((pct) => shade(value, pct))

  return (
    <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] p-3">
      <div className="mb-2.5 flex items-center justify-between gap-2">
        <span className="text-[12px] font-medium capitalize text-subtext">{label}</span>
        <span className={cn('font-mono text-[10px] font-semibold', tone)}>{ratio.toFixed(1)}:1 {grade}</span>
      </div>

      <div className="flex items-center gap-2.5">
        <label className="relative h-9 w-9 shrink-0 cursor-pointer overflow-hidden rounded-lg ring-1 ring-inset ring-white/15">
          <span className="absolute inset-0" style={{ background: value }} />
          <span
            className="absolute inset-0 grid place-items-center text-[11px] font-bold opacity-0 transition-opacity hover:opacity-100"
            style={{ color: readableOn(value), background: `${value}cc` }}
            aria-hidden
          >
            ✎
          </span>
          <input
            type="color"
            value={value.slice(0, 7)}
            onChange={(e) => commit(e.target.value)}
            className="absolute inset-0 cursor-pointer opacity-0"
            aria-label={`Pick ${label} colour`}
          />
        </label>

        <input
          value={draft}
          onChange={(e) => { setDraft(e.target.value); commit(e.target.value) }}
          spellCheck={false}
          aria-label={`${label} hex value`}
          className="w-full rounded-lg border border-white/[0.08] bg-crust/70 px-2.5 py-1.5 font-mono text-[12px] text-text outline-none transition-colors focus:border-accent/50"
        />
      </div>

      <div className="mt-2 flex gap-1">
        {swatches.map((c, i) => (
          <button
            key={`${c}-${i}`}
            onClick={() => commit(c)}
            title={c}
            aria-label={`Set ${label} to ${c}`}
            className="h-4 flex-1 rounded-sm ring-1 ring-inset ring-white/10 transition-transform duration-150 hover:scale-y-125"
            style={{ background: c }}
          />
        ))}
      </div>
    </div>
  )
}

/** Lightens (pct > 0) or darkens (pct < 0) a hex colour. */
function shade(hex: string, amount: number): string {
  let h = hex.replace('#', '')
  if (h.length === 3) h = h.split('').map((c) => c + c).join('')
  const num = parseInt(h, 16)
  let r = (num >> 16) & 0xff
  let g = (num >> 8) & 0xff
  let b = num & 0xff
  const t = amount < 0 ? 0 : 255
  const p = Math.abs(amount) / 100
  r = Math.round((t - r) * p) + r
  g = Math.round((t - g) * p) + g
  b = Math.round((t - b) * p) + b
  return `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`
}
