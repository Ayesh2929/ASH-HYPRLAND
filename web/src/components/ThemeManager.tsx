/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — theme manager
 * ═══════════════════════════════════════════════════════════════════════════
 *  Import / export / generate. The generator writes a real OKLCH-derived
 *  palette from the prompt hash, so the same prompt always yields the same
 *  theme — reproducible, not random.
 */
import { useState } from 'react'
import { useThemeStore } from '../store/themeStore'
import { useTheme } from '../hooks/useTheme'
import { cv } from '../lib/contrast'
import { cn, slugify } from '../lib/utils'
import { Button, Input, Panel, SectionHeader, Tabs, useToast } from './ui'

export default function ThemeManager() {
  const { themes, active } = useTheme()
  const generate = useThemeStore((s) => s.generate)
  const apply = useThemeStore((s) => s.apply)
  const save = useThemeStore((s) => s.save)
  const remove = useThemeStore((s) => s.remove)
  const toast = useToast()

  const [tab, setTab] = useState<'generate' | 'import' | 'manage'>('generate')
  const [prompt, setPrompt] = useState('')
  const [working, setWorking] = useState(false)
  const [importText, setImportText] = useState('')

  const onGenerate = async () => {
    if (!prompt.trim()) return
    setWorking(true)
    try {
      const t = await generate(prompt.trim())
      if (t) {
        await apply(t.id)
        toast.success('Theme generated', `${t.name} · hue ${t.hue.toFixed(0)}° · ${t.contrast.toFixed(1)}:1`)
      } else {
        toast.error('Generation failed', 'The engine did not return a palette.')
      }
    } finally {
      setWorking(false)
    }
  }

  const onImport = async () => {
    try {
      const parsed = JSON.parse(importText) as {
        name?: string; author?: string; variant?: 'dark' | 'light'; colors?: Record<string, string>
      }
      if (!parsed.colors) throw new Error('missing "colors"')
      const id = slugify(parsed.name ?? `imported-${Date.now()}`)
      const base = themes.find((t) => t.id === active?.id) ?? themes[0]
      if (!base) throw new Error('no base theme loaded')

      const theme = {
        ...base,
        id,
        name: parsed.name ?? id,
        author: parsed.author ?? 'imported',
        variant: parsed.variant ?? 'dark',
        source: 'imported' as const,
        colors: { ...base.colors, ...parsed.colors },
        tags: [...new Set([...base.tags, 'imported'])],
      }
      await save(theme)
      await apply(theme.id)
      setImportText('')
      toast.success('Theme imported', `${theme.name} is now active.`)
    } catch (err) {
      toast.error('Import failed', (err as Error).message)
    }
  }

  const onFile = (file: File) => {
    const reader = new FileReader()
    reader.onload = () => setImportText(String(reader.result ?? ''))
    reader.readAsText(file)
  }

  return (
    <Panel>
      <SectionHeader
        icon="🛠️"
        title="Theme workshop"
        subtitle="Generate, import and manage palettes."
        action={
          <Tabs
            value={tab}
            onChange={setTab}
            tabs={[
              { id: 'generate', label: 'Generate' },
              { id: 'import', label: 'Import' },
              { id: 'manage', label: 'Manage' },
            ]}
          />
        }
      />

      {tab === 'generate' && (
        <div className="space-y-4">
          <Input
            label="Describe the mood"
            placeholder="warm autumn afternoon, low contrast, dusty oranges"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') void onGenerate() }}
            hint="The palette is derived deterministically from your words — the same prompt always produces the same theme."
          />

          <div className="flex flex-wrap gap-2">
            {['cyberpunk neon', 'forest at dawn', 'monochrome ink', 'desert twilight', 'deep ocean'].map((p) => (
              <button
                key={p}
                onClick={() => setPrompt(p)}
                className="rounded-full border border-white/[0.07] px-2.5 py-1 text-[11px] text-subtext/60 transition-all hover:border-accent/35 hover:text-accent"
              >
                {p}
              </button>
            ))}
          </div>

          <Button variant="primary" icon="✨" loading={working} disabled={!prompt.trim()} onClick={() => void onGenerate()}>
            Generate palette
          </Button>

          <p className="text-[11.5px] leading-relaxed text-subtext/55">
            The generator converts a seeded hue into the OKLCH colour space, builds a nine-step
            lightness ramp, then validates every text-on-background pair against WCAG 2.1 before
            handing the palette back. Themes that fail the AA threshold are still offered, but
            flagged in the gallery.
          </p>
        </div>
      )}

      {tab === 'import' && (
        <div className="space-y-4">
          <label className="flex cursor-pointer flex-col items-center gap-2 rounded-xl border border-dashed border-white/15 px-6 py-8 text-center transition-colors hover:border-accent/40 hover:bg-accent/[0.04]">
            <span className="text-3xl animate-float" aria-hidden>📥</span>
            <span className="text-[12.5px] text-text">Drop a theme JSON here, or click to browse</span>
            <span className="font-mono text-[11px] text-subtext/45">ash theme export {"{"}name{"}"} &gt; theme.json</span>
            <input
              type="file"
              accept=".json,application/json"
              className="hidden"
              onChange={(e) => { const f = e.target.files?.[0]; if (f) onFile(f) }}
            />
          </label>

          <textarea
            value={importText}
            onChange={(e) => setImportText(e.target.value)}
            placeholder={'{\n  "name": "My Theme",\n  "author": "me",\n  "variant": "dark",\n  "colors": { "accent": "#ff79c6" }\n}'}
            rows={10}
            spellCheck={false}
            aria-label="Theme JSON"
            className="ash-input resize-y font-mono text-[11.5px] leading-relaxed"
          />

          <Button variant="primary" icon="📥" disabled={!importText.trim()} onClick={() => void onImport()}>
            Import theme
          </Button>
        </div>
      )}

      {tab === 'manage' && (
        <div className="space-y-2">
          {themes.map((t) => (
            <div
              key={t.id}
              className={cn(
                'flex items-center gap-3 rounded-xl border p-3 transition-colors',
                t.id === active?.id ? 'border-accent/35 bg-accent/[0.06]' : 'border-white/[0.06] bg-white/[0.02]',
              )}
            >
              <span className="flex shrink-0 gap-0.5" aria-hidden>
                {[t.colors.accent, t.colors.sky, t.colors.mint, t.colors.gold].map((c) => (
                  <span key={c} className="h-6 w-2 rounded-sm" style={{ background: c }} />
                ))}
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-[12.5px] font-medium text-text">{t.name}</p>
                <p className="truncate text-[11px] text-subtext/50">
                  {t.author} · {t.variant} · contrast {cv(t).toFixed(1)}:1
                </p>
              </div>
              {t.id === active?.id && <span className="text-[10px] font-bold text-mint">ACTIVE</span>}
              <Button icon="🎯" onClick={() => void apply(t.id)} disabled={t.id === active?.id}>
                Apply
              </Button>
              <Button
                variant="danger"
                icon="🗑️"
                disabled={t.source === 'builtin'}
                onClick={() => { void remove(t.id); toast.info('Theme deleted', t.name) }}
                aria-label={`Delete ${t.name}`}
              />
            </div>
          ))}
        </div>
      )}
    </Panel>
  )
}
