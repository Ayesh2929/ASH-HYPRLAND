/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — command palette (⌘K)
 * ═══════════════════════════════════════════════════════════════════════════
 *  Fuzzy-matches pages, themes, plugins and shell commands in one list.
 *  Arrow keys move a virtual cursor; the cursor is scrolled into view so it
 *  never disappears below the fold.
 */
import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { cn } from '../lib/utils'
import { useConfigStore } from '../store/configStore'
import { useThemeStore } from '../store/themeStore'
import { usePluginStore } from '../store/pluginStore'
import { useToast } from './ui'

interface Command {
  id: string
  label: string
  hint: string
  group: string
  emoji: string
  run: () => void | Promise<void>
}

/**
 * Subsequence matcher with a contiguity bonus — "thm" finds "Themes" and
 * "Tokyo Night" ranks above "Catppuccin Mocha" for "tn". Returns null when
 * the query is not a subsequence at all.
 */
function fuzzyScore(text: string, query: string): number | null {
  if (!query) return 0
  const t = text.toLowerCase()
  const q = query.toLowerCase()
  let ti = 0
  let score = 0
  let streak = 0

  for (const ch of q) {
    const found = t.indexOf(ch, ti)
    if (found === -1) return null
    streak = found === ti && ti > 0 ? streak + 1 : 0
    score += 10 - Math.min(9, found - ti) + streak * 4
    if (found === 0) score += 8
    ti = found + 1
  }
  return score - t.length * 0.05
}

export default function CommandPalette({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [query, setQuery] = useState('')
  const [cursor, setCursor] = useState(0)
  const listRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const navigate = useNavigate()
  const toast = useToast()
  const themes = useThemeStore((s) => s.themes)
  const applyTheme = useThemeStore((s) => s.apply)
  const plugins = usePluginStore((s) => s.plugins)
  const togglePlugin = usePluginStore((s) => s.toggle)
  const modes = useConfigStore((s) => s.modes)
  const setMode = useConfigStore((s) => s.setMode)
  const runCommand = useConfigStore((s) => s.runCommand)
  const metrics = useConfigStore((s) => s.metrics)

  const go = (to: string) => { navigate(to); onClose() }

  const commands = useMemo<Command[]>(() => {
    const list: Command[] = [
      { id: 'nav-home',      label: 'Go to Dashboard',  hint: 'pages',  group: 'Navigate', emoji: '🏠', run: () => go('/') },
      { id: 'nav-themes',    label: 'Go to Themes',     hint: 'pages',  group: 'Navigate', emoji: '🎨', run: () => go('/themes') },
      { id: 'nav-plugins',   label: 'Go to Plugins',    hint: 'pages',  group: 'Navigate', emoji: '🧩', run: () => go('/plugins') },
      { id: 'nav-snapshots', label: 'Go to Snapshots',  hint: 'pages',  group: 'Navigate', emoji: '💾', run: () => go('/snapshots') },
      { id: 'nav-analytics', label: 'Go to Analytics',  hint: 'pages',  group: 'Navigate', emoji: '📊', run: () => go('/analytics') },
      { id: 'nav-settings',  label: 'Go to Settings',   hint: 'pages',  group: 'Navigate', emoji: '⚙️', run: () => go('/settings') },
      { id: 'nav-about',     label: 'Go to About',      hint: 'pages',  group: 'Navigate', emoji: 'ℹ️', run: () => go('/about') },

      { id: 'cmd-doctor',  label: 'ash doctor',            hint: 'diagnose the desktop', group: 'Commands', emoji: '🩺', run: () => runCommand('ash doctor') },
      { id: 'cmd-update',  label: 'ash update',            hint: 'pull the latest release', group: 'Commands', emoji: '⬆️', run: () => runCommand('ash update') },
      { id: 'cmd-backup',  label: 'ash snapshot create',   hint: 'snapshot current config', group: 'Commands', emoji: '💾', run: () => runCommand('ash snapshot create') },
      { id: 'cmd-reload',  label: 'ash reload',            hint: 'reload Hyprland config', group: 'Commands', emoji: '🔄', run: () => runCommand('ash reload') },
      { id: 'cmd-wall',    label: 'ash wallpaper next',    hint: 'rotate wallpaper', group: 'Commands', emoji: '🖼️', run: () => runCommand('ash wallpaper next') },
      { id: 'cmd-hw',      label: 'uname -a',              hint: 'kernel and host', group: 'Commands', emoji: '🐧', run: () => runCommand('uname -a') },
    ]

    for (const m of modes) {
      list.push({
        id: `mode-${m.id}`, label: `Switch to ${m.name} mode`, hint: m.description,
        group: 'Modes', emoji: m.emoji,
        run: async () => { await setMode(m.id); toast.success(`${m.name} mode active`, m.description) },
      })
    }

    for (const t of themes.slice(0, 40)) {
      list.push({
        id: `theme-${t.id}`, label: `Apply theme · ${t.name}`, hint: `${t.variant} · ${t.author}`,
        group: 'Themes', emoji: '🎨',
        run: async () => { await applyTheme(t.id); toast.success(`Theme applied`, t.name) },
      })
    }

    for (const p of plugins.filter((x) => x.installed)) {
      list.push({
        id: `plug-${p.id}`, label: `${p.enabled ? 'Disable' : 'Enable'} ${p.name}`,
        hint: p.category, group: 'Plugins', emoji: p.enabled ? '🔴' : '🟢',
        run: async () => {
          await togglePlugin(p.id, !p.enabled)
          toast.info(`${p.name} ${p.enabled ? 'disabled' : 'enabled'}`)
        },
      })
    }

    // Live metrics are searchable too — "cpu" jumps straight to the reading.
    const last = metrics[metrics.length - 1]
    if (last) {
      list.push({
        id: 'info-cpu', label: `CPU at ${last.cpu.toFixed(0)}%`, hint: 'current reading',
        group: 'Live', emoji: '📈', run: () => go('/analytics'),
      })
      list.push({
        id: 'info-mem', label: `Memory at ${last.memory.toFixed(0)}%`, hint: 'current reading',
        group: 'Live', emoji: '🧠', run: () => go('/analytics'),
      })
    }

    if (query.trim().startsWith('!')) {
      const shellCmd = query.trim().slice(1)
      list.unshift({
        id: 'shell-run', label: `Run in shell: ${shellCmd}`, hint: 'press ↵ to execute',
        group: 'Shell', emoji: '⌨️',
        run: async () => { await runCommand(shellCmd); go('/analytics') },
      })
    }

    return list
    // `go`, `toast` and the stores are stable enough for this menu's lifetime.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [themes, plugins, modes, metrics, query, runCommand, setMode, applyTheme, togglePlugin])

  const results = useMemo(() => {
    const q = query.trim().replace(/^!/, '')
    if (!q) return commands.slice(0, 40)
    return commands
      .map((c) => ({ c, s: fuzzyScore(`${c.label} ${c.hint} ${c.group}`, q) }))
      .filter((r): r is { c: Command; s: number } => r.s !== null)
      .sort((a, b) => b.s - a.s)
      .slice(0, 40)
      .map((r) => r.c)
  }, [commands, query])

  const grouped = useMemo(() => {
    const map = new Map<string, Command[]>()
    for (const c of results) {
      const arr = map.get(c.group) ?? []
      arr.push(c)
      map.set(c.group, arr)
    }
    return [...map.entries()]
  }, [results])

  useEffect(() => setCursor(0), [query])
  useEffect(() => {
    if (!open) { setQuery(''); setCursor(0); return }
    const t = setTimeout(() => inputRef.current?.focus(), 40)
    return () => clearTimeout(t)
  }, [open])

  // Keep the highlighted row inside the scroll viewport.
  useEffect(() => {
    listRef.current?.querySelector<HTMLElement>('[data-cursor="true"]')
      ?.scrollIntoView({ block: 'nearest' })
  }, [cursor, results])

  if (!open) return null

  const onKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setCursor((c) => Math.min(c + 1, results.length - 1))
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setCursor((c) => Math.max(c - 1, 0))
    } else if (e.key === 'Enter') {
      e.preventDefault()
      void results[cursor]?.run()
      onClose()
    } else if (e.key === 'Escape') {
      e.preventDefault()
      onClose()
    }
  }

  let flat = -1

  return (
    <div className="fixed inset-0 z-[150] flex items-start justify-center p-4 pt-[12vh]" onKeyDown={onKeyDown}>
      <div className="absolute inset-0 animate-fade-in bg-crust/70 backdrop-blur-sm" onClick={onClose} aria-hidden />

      <div
        role="dialog"
        aria-modal="true"
        aria-label="Command palette"
        className="relative z-10 w-full max-w-2xl animate-scale-in overflow-hidden rounded-2xl border border-white/10 bg-mantle/95 shadow-lift backdrop-blur-2xl"
      >
        <div className="flex items-center gap-3 border-b border-white/[0.07] px-4">
          <span className="text-subtext/50" aria-hidden>🔍</span>
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search pages, themes, plugins…  (prefix ! to run a shell command)"
            aria-label="Search commands"
            className="flex-1 bg-transparent py-4 text-[14px] text-text outline-none placeholder:text-subtext/40"
          />
          <kbd className="rounded border border-white/10 bg-white/[0.05] px-1.5 py-0.5 font-mono text-[10px] text-subtext/60">
            ESC
          </kbd>
        </div>

        <div ref={listRef} className="max-h-[52vh] overflow-y-auto p-2">
          {results.length === 0 && (
            <div className="px-4 py-12 text-center">
              <p className="text-3xl" aria-hidden>🫥</p>
              <p className="mt-2 text-[13px] text-subtext">Nothing matches “{query}”.</p>
            </div>
          )}

          {grouped.map(([group, items]) => (
            <div key={group} className="mb-1">
              <p className="px-3 py-1.5 text-[10px] font-semibold uppercase tracking-[0.14em] text-subtext/40">
                {group}
              </p>
              {items.map((c) => {
                flat += 1
                const idx = flat
                const active = idx === cursor
                return (
                  <button
                    key={c.id}
                    data-cursor={active}
                    onMouseEnter={() => setCursor(idx)}
                    onClick={() => { void c.run(); onClose() }}
                    className={cn(
                      'flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-colors duration-150',
                      active ? 'bg-accent/12 text-text' : 'text-subtext hover:bg-white/[0.04]',
                    )}
                  >
                    <span className="text-[15px]" aria-hidden>{c.emoji}</span>
                    <span className="min-w-0 flex-1 truncate text-[13px]">{c.label}</span>
                    <span className="truncate text-[11px] text-subtext/45">{c.hint}</span>
                    {active && (
                      <kbd className="rounded border border-white/10 bg-white/[0.05] px-1.5 py-0.5 font-mono text-[10px]">
                        ↵
                      </kbd>
                    )}
                  </button>
                )
              })}
            </div>
          ))}
        </div>

        <div className="flex items-center justify-between border-t border-white/[0.07] px-4 py-2.5 text-[10px] text-subtext/45">
          <span className="flex items-center gap-3">
            <span><kbd className="font-mono">↑↓</kbd> navigate</span>
            <span><kbd className="font-mono">↵</kbd> select</span>
          </span>
          <span>{results.length} result{results.length === 1 ? '' : 's'}</span>
        </div>
      </div>
    </div>
  )
}
