/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — theme editor
 * ═══════════════════════════════════════════════════════════════════════════
 *  Edits a working copy, applies it live, and only persists on Save. Cancel
 *  restores the previously committed palette, so the editor is never
 *  destructive until you say so.
 */
import { useEffect, useMemo, useRef, useState } from 'react'
import type { Palette, Theme } from '../lib/types'
import { useThemeStore } from '../store/themeStore'
import { applyPaletteToDom } from '../store/themeStore'
import { contrastRatio, slugify } from '../lib/utils'
import ColorPicker from './ColorPicker'
import { Button, Input, Panel, SectionHeader, Tabs, useToast } from './ui'
import { themeApi } from '../api/theme'

const GROUPS: Record<string, Array<keyof Palette>> = {
  Backgrounds: ['base', 'mantle', 'crust', 'surface', 'overlay'],
  Foregrounds: ['text', 'subtext'],
  Accents: ['accent', 'mint', 'sky', 'gold', 'rose', 'violet'],
}

export default function ThemeEditor({ theme, onClose }: { theme: Theme; onClose: () => void }) {
  const save = useThemeStore((s) => s.save)
  const active = useThemeStore((s) => s.active)
  const apply = useThemeStore((s) => s.apply)
  const toast = useToast()

  const [draft, setDraft] = useState<Theme>(() => structuredClone(theme))
  const [group, setGroup] = useState<keyof typeof GROUPS>('Accents')
  const [exporting, setExporting] = useState(false)
  const dirty = useRef(false)

  // Live-apply the working copy; restore the committed theme on unmount.
  useEffect(() => {
    applyPaletteToDom(draft.colors, draft.variant)
    dirty.current = true
  }, [draft])

  useEffect(() => () => {
    if (dirty.current && active) applyPaletteToDom(active.colors, active.variant)
  }, [active])

  const audits = useMemo(() => ({
    text: contrastRatio(draft.colors.text, draft.colors.base),
    subtext: contrastRatio(draft.colors.subtext, draft.colors.base),
    accent: contrastRatio(draft.colors.accent, draft.colors.base),
  }), [draft])

  const score = Math.min(audits.text, audits.subtext, audits.accent)
  const verdict = score >= 7 ? { tone: 'text-mint', label: 'AAA — excellent' }
    : score >= 4.5 ? { tone: 'text-sky', label: 'AA — accessible' }
    : score >= 3 ? { tone: 'text-gold', label: 'AA Large only' }
    : { tone: 'text-rose', label: 'Fails WCAG — raise contrast' }

  const setColor = (key: keyof Palette, value: string) =>
    setDraft((d) => ({ ...d, colors: { ...d.colors, [key]: value } }))

  const onSave = async () => {
    const saved: Theme = { ...draft, id: draft.id || slugify(draft.name), contrast: score }
    await save(saved)
    await apply(saved.id)
    dirty.current = false
    toast.success('Theme saved', `${saved.name} is now the active palette.`)
    onClose()
  }

  const onCancel = () => {
    dirty.current = false
    if (active) applyPaletteToDom(active.colors, active.variant)
    onClose()
  }

  const download = async (kind: 'json' | 'conf') => {
    const body = kind === 'json' ? themeApi.toCliJson(draft) : themeApi.toConf(draft)
    const blob = new Blob([body], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${slugify(draft.name)}.${kind === 'json' ? 'json' : 'conf'}`
    a.click()
    URL.revokeObjectURL(url)
    setExporting(false)
    toast.info('Exported', `${a.download} — import with \`ash theme import\`.`)
  }

  return (
    <Panel className="animate-fade-up">
      <SectionHeader
        icon="✏️"
        title={`Edit · ${theme.name}`}
        subtitle="Changes preview instantly. Nothing is written until you save."
        action={
          <div className="flex gap-2">
            <Button onClick={onCancel}>Cancel</Button>
            <Button variant="primary" icon="💾" onClick={() => void onSave()}>Save theme</Button>
          </div>
        }
      />

      <div className="grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <div>
          <div className="mb-3 grid gap-3 sm:grid-cols-2">
            <Input
              label="Name"
              value={draft.name}
              onChange={(e) => setDraft({ ...draft, name: e.target.value })}
            />
            <Input
              label="Author"
              value={draft.author}
              onChange={(e) => setDraft({ ...draft, author: e.target.value })}
            />
          </div>

          <Tabs
            className="mb-3"
            value={group}
            onChange={setGroup}
            tabs={Object.keys(GROUPS).map((g) => ({ id: g, label: g }))}
          />

          <div className="grid gap-2.5 sm:grid-cols-2">
            {(GROUPS[group] ?? []).map((key) => (
              <ColorPicker
                key={key}
                label={key}
                value={draft.colors[key]}
                background={draft.colors.base}
                onChange={(hex) => setColor(key, hex)}
              />
            ))}
          </div>
        </div>

        {/* ── Live specimen + audit ───────────────────────────────────── */}
        <div className="space-y-4">
          <div className="overflow-hidden rounded-xl border border-white/[0.08]">
            <div className="flex items-center gap-1.5 border-b px-3 py-2"
                 style={{ background: draft.colors.mantle, borderColor: `${draft.colors.surface}88` }}>
              {['#f38ba8', '#f9e2af', '#a6e3a1'].map((c, i) => (
                <span key={i} className="h-2.5 w-2.5 rounded-full" style={{ background: c }} />
              ))}
              <span className="ml-2 font-mono text-[10px]" style={{ color: draft.colors.subtext }}>
                ash — zsh
              </span>
            </div>
            <div className="space-y-1 p-3 font-mono text-[11px]" style={{ background: draft.colors.base }}>
              <p style={{ color: draft.colors.mint }}>
                ➜ <span style={{ color: draft.colors.accent }}>~/dotfiles</span>
                <span style={{ color: draft.colors.text }}> ash doctor</span>
              </p>
              <p style={{ color: draft.colors.subtext }}>✔ 14 checks passed</p>
              <p style={{ color: draft.colors.gold }}>⚠ shadow radius exceeds recommendation</p>
              <p style={{ color: draft.colors.rose }}>✕ module nvidia is unsigned</p>
              <p style={{ color: draft.colors.sky }}>ℹ snapshot created in 1.2s</p>
            </div>
            <div className="flex gap-1 p-2" style={{ background: draft.colors.mantle }}>
              {(['accent', 'mint', 'sky', 'gold', 'rose', 'violet'] as const).map((k) => (
                <span key={k} className="h-5 flex-1 rounded" style={{ background: draft.colors[k] }} />
              ))}
            </div>
          </div>

          <div className="rounded-xl border border-white/[0.07] bg-white/[0.02] p-3.5">
            <p className="mb-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-subtext/40">
              WCAG audit
            </p>
            <ul className="space-y-1.5 text-[12px]">
              {Object.entries(audits).map(([k, v]) => (
                <li key={k} className="flex items-center justify-between">
                  <span className="text-subtext/70">{k} on base</span>
                  <span className={v >= 4.5 ? 'font-mono text-mint' : 'font-mono text-rose'}>
                    {v.toFixed(2)}:1
                  </span>
                </li>
              ))}
            </ul>
            <div className="ash-divider my-3" />
            <p className={`text-[12px] font-semibold ${verdict.tone}`}>{verdict.label}</p>
          </div>

          <div className="flex gap-2">
            <Button icon="⬇️" onClick={() => setExporting((v) => !v)}>Export</Button>
            {exporting && (
              <>
                <Button onClick={() => void download('json')}>.json</Button>
                <Button onClick={() => void download('conf')}>.conf</Button>
              </>
            )}
          </div>
        </div>
      </div>
    </Panel>
  )
}
