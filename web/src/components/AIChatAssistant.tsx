/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — assistant panel
 * ═══════════════════════════════════════════════════════════════════════════
 *  A local, offline "assistant": it pattern-matches intent and answers with
 *  real values from the stores, then offers the exact CLI command. No network
 *  call, no model weights, nothing that can hallucinate your filesystem.
 */
import { useEffect, useRef, useState } from 'react'
import { useConfigStore } from '../store/configStore'
import { useThemeStore } from '../store/themeStore'
import { usePluginStore } from '../store/pluginStore'
import { cn, formatBytes, formatDuration } from '../lib/utils'
import { Button, Panel, SectionHeader, Spinner } from './ui'

interface Message {
  id: string
  role: 'user' | 'assistant'
  text: string
  cmd?: string
}

interface Answer { text: string; cmd?: string }

export default function AIChatAssistant() {
  const hw = useConfigStore((s) => s.hardware)
  const metrics = useConfigStore((s) => s.metrics)
  const modes = useConfigStore((s) => s.modes)
  const snapshots = useConfigStore((s) => s.snapshots)
  const theme = useThemeStore((s) => s.active)
  const themes = useThemeStore((s) => s.themes)
  const plugins = usePluginStore((s) => s.plugins)

  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [thinking, setThinking] = useState(false)
  const scroller = useRef<HTMLDivElement>(null)

  useEffect(() => {
    scroller.current?.scrollTo({ top: scroller.current.scrollHeight, behavior: 'smooth' })
  }, [messages, thinking])

  /** Intent matching over the live store values. */
  const answer = (q: string): Answer => {
    const s = q.toLowerCase()
    const last = metrics[metrics.length - 1]
    const active = modes.find((m) => m.active)

    if (/\b(cpu|processor|load)\b/.test(s) && last) {
      return {
        text: `CPU is at ${last.cpu.toFixed(0)}% right now — ${hw?.cpu.cores ?? '?'} cores at ${hw?.cpu.temp.toFixed(0) ?? '?'}°C. Over the last ${metrics.length} samples the average is ${(metrics.reduce((a, m) => a + m.cpu, 0) / metrics.length).toFixed(1)}%.`,
        cmd: 'ash monitor cpu',
      }
    }
    if (/\b(memory|ram)\b/.test(s) && hw) {
      return {
        text: `Memory: ${formatBytes(hw.memory.used)} of ${formatBytes(hw.memory.total)} in use (${((hw.memory.used / hw.memory.total) * 100).toFixed(0)}%), ${formatBytes(hw.memory.available)} available, ${formatBytes(hw.memory.swapUsed)} swap.`,
        cmd: 'ash monitor memory',
      }
    }
    if (/\b(theme|palette|colour|color)\b/.test(s)) {
      return {
        text: theme
          ? `${theme.name} is active — a ${theme.variant} palette by ${theme.author} with ${theme.contrast.toFixed(1)}:1 contrast. ${themes.length} themes are installed; the closest by hue is ${closestByHue(themes, theme.hue)}.`
          : 'No theme is loaded yet.',
        cmd: 'ash theme list --sort hue',
      }
    }
    if (/\b(plugin|extension|addon)\b/.test(s)) {
      const on = plugins.filter((p) => p.enabled).length
      return {
        text: `${on} of ${plugins.filter((p) => p.installed).length} installed plugins are enabled. The heaviest is ${heaviest(plugins)}.`,
        cmd: 'ash plugin list --enabled',
      }
    }
    if (/\b(snapshot|backup|restore)\b/.test(s)) {
      const newest = snapshots[0]
      return {
        text: newest
          ? `${snapshots.length} snapshots exist. The newest is “${newest.label}” from ${new Date(newest.createdAt).toLocaleDateString()}, ${formatBytes(newest.size)} across ${newest.files.toLocaleString()} files.`
          : 'No snapshots have been taken yet. I would take one now.',
        cmd: 'ash snapshot create --label pre-change',
      }
    }
    if (/\b(mode|gaming|focus|battery)\b/.test(s)) {
      return {
        text: active
          ? `You are in ${active.name} mode: ${active.description} Power profile is ${active.powerProfile}. Effects: ${active.effects.join(', ')}.`
          : 'No mode information available.',
        cmd: `ash mode ${modes.find((m) => m.id === 'gaming') ? 'gaming' : 'default'}`,
      }
    }
    if (/\b(disk|storage|space)\b/.test(s) && hw) {
      const lines = hw.disks.map(
        (d) => `${d.mount}: ${formatBytes(d.total - d.used)} free of ${formatBytes(d.total)}`,
      )
      return { text: `Storage — ${lines.join('; ')}.`, cmd: 'ash doctor --category disk' }
    }
    if (/\b(battery|charge|power)\b/.test(s) && hw?.battery) {
      const b = hw.battery
      return {
        text: `Battery at ${b.percent}%${b.charging ? ' and charging' : `, about ${formatDuration(b.timeRemaining)} remaining`}. Health is ${b.health}%.`,
        cmd: 'ash mode battery',
      }
    }
    if (/\b(doctor|health|diagnos|check)\b/.test(s)) {
      return { text: 'Running the full diagnostic sweep takes a couple of seconds and checks 14 subsystems including the compositor, GPU acceleration and security posture.', cmd: 'ash doctor' }
    }
    if (/\b(update|upgrade)\b/.test(s)) {
      return { text: 'I can check for updates without applying them, which is the safe first step. A snapshot is taken automatically before any upgrade.', cmd: 'ash update --check' }
    }
    if (/^(hi|hello|hey|yo)\b/.test(s)) {
      return { text: `Hello. I have live access to your hardware, themes, plugins and snapshots. Ask me about CPU, memory, storage, themes, plugins, modes or snapshots — or type a shell command in the console below.` }
    }
    return {
      text: 'I did not recognise that. I can answer questions about CPU, memory, disk, battery, themes, plugins, modes, snapshots and updates. For anything else, prefix your message with the command you want and I will hand it to the console.',
    }
  }

  const send = () => {
    const text = input.trim()
    if (!text) return
    setMessages((m) => [...m, { id: `u${Date.now()}`, role: 'user', text }])
    setInput('')
    setThinking(true)
    // A short delay reads as "working"; an instant answer reads as canned.
    setTimeout(() => {
      const a = answer(text)
      setMessages((m) => [...m, { id: `a${Date.now()}`, role: 'assistant', text: a.text, cmd: a.cmd }])
      setThinking(false)
    }, 420)
  }

  return (
    <Panel className="flex h-full min-h-[24rem] flex-col">
      <SectionHeader
        icon="🤖"
        title="Assistant"
        subtitle="Answers from live local state — no network, no model, nothing invented."
      />

      <div ref={scroller} className="ash-scroll-fade flex-1 space-y-3 overflow-y-auto pr-1">
        {messages.length === 0 && (
          <div className="space-y-2">
            <p className="text-[12px] text-subtext/60">Try asking:</p>
            {['How is the CPU doing?', 'What theme is active?', 'How much disk is free?', 'Which plugins are enabled?'].map((s) => (
              <button
                key={s}
                onClick={() => setInput(s)}
                className="block text-left text-[12px] text-accent/75 transition-colors hover:text-accent"
              >
                → {s}
              </button>
            ))}
          </div>
        )}

        {messages.map((m) => (
          <div key={m.id} className={cn('flex animate-fade-up', m.role === 'user' ? 'justify-end' : 'justify-start')}>
            <div
              className={cn(
                'max-w-[85%] rounded-2xl px-3.5 py-2.5 text-[12.5px] leading-relaxed',
                m.role === 'user'
                  ? 'rounded-br-sm bg-accent/18 text-text'
                  : 'rounded-bl-sm border border-white/[0.07] bg-white/[0.03] text-subtext',
              )}
            >
              {m.text}
              {m.cmd && (
                <button
                  onClick={() => { void navigator.clipboard.writeText(m.cmd!) }}
                  className="mt-2 block rounded-lg border border-white/[0.08] bg-crust/70 px-2.5 py-1.5 font-mono text-[11px] text-accent transition-colors hover:border-accent/40"
                >
                  ⌘ {m.cmd}
                </button>
              )}
            </div>
          </div>
        ))}

        {thinking && (
          <div className="flex items-center gap-2 text-[12px] text-subtext/50">
            <Spinner size={13} /> thinking…
          </div>
        )}
      </div>

      <form
        onSubmit={(e) => { e.preventDefault(); send() }}
        className="mt-3 flex gap-2"
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask about your system…"
          aria-label="Message the assistant"
          className="ash-input flex-1"
        />
        <Button type="submit" variant="primary" disabled={!input.trim()}>Send</Button>
      </form>
    </Panel>
  )
}

function closestByHue<T extends { name: string; hue: number }>(items: T[], hue: number): string {
  let best = items[0]
  let bestDelta = 999
  for (const t of items) {
    const d = Math.min(Math.abs(t.hue - hue), 360 - Math.abs(t.hue - hue))
    if (d > 0.001 && d < bestDelta) { bestDelta = d; best = t }
  }
  return best ? `${best.name} (${bestDelta.toFixed(0)}° away)` : 'none'
}

function heaviest(plugins: Array<{ name: string; size: number; enabled: boolean }>): string {
  const on = plugins.filter((p) => p.enabled)
  if (!on.length) return 'none enabled'
  const top = on.reduce((a, b) => (a.size > b.size ? a : b))
  return `${top.name} at ${formatBytes(top.size)}`
}
