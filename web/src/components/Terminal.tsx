/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — command console
 * ═══════════════════════════════════════════════════════════════════════════
 *  Runs `ash` subcommands over the REST bridge and keeps a scrollback.
 *  Destructive verbs are refused client-side as well as server-side — defence
 *  in depth, and it gives the user a clear refusal instead of a 403.
 */
import { useEffect, useRef, useState } from 'react'
import { useConfigStore } from '../store/configStore'
import { cn } from '../lib/utils'
import { Button, Panel, SectionHeader } from './ui'

const DENY = /^(rm|dd|mkfs|shutdown|reboot|poweroff|mv\s+\/|chmod\s+-R\s+777)/

const SUGGESTIONS = [
  'ash doctor',
  'ash theme list',
  'ash plugin list',
  'ash snapshot list',
  'ash mode',
  'ash update --check',
  'uname -a',
]

export default function Terminal() {
  const history = useConfigStore((s) => s.commandHistory)
  const runCommand = useConfigStore((s) => s.runCommand)
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)
  const [histIdx, setHistIdx] = useState(-1)
  const scroller = useRef<HTMLDivElement>(null)

  useEffect(() => {
    scroller.current?.scrollTo({ top: scroller.current.scrollHeight, behavior: 'smooth' })
  }, [history.length, busy])

  const submit = async (cmd: string) => {
    const trimmed = cmd.trim()
    if (!trimmed) return
    if (DENY.test(trimmed)) {
      setInput('')
      // Surface the refusal as a synthetic history entry so it is visible.
      await runCommand(`echo "ash: refused destructive command: ${trimmed.replace(/"/g, '')}"`)
      return
    }
    setBusy(true)
    setInput('')
    setHistIdx(-1)
    try {
      await runCommand(trimmed)
    } finally {
      setBusy(false)
    }
  }

  const entries = history.slice(-60)

  return (
    <Panel className="flex h-full min-h-[22rem] flex-col">
      <SectionHeader
        icon="⌨️"
        title="Command console"
        subtitle="Runs against the local ash daemon. Destructive verbs are blocked."
        action={
          <Button
            icon="🧹"
            onClick={() => useConfigStore.setState({ commandHistory: [] })}
            disabled={history.length === 0}
          >
            Clear
          </Button>
        }
      />

      <div
        ref={scroller}
        className="ash-scroll-fade flex-1 overflow-y-auto rounded-xl border border-white/[0.06] bg-crust/70 p-3 font-mono text-[12px] leading-relaxed"
      >
        {entries.length === 0 && !busy && (
          <div className="space-y-1.5 text-subtext/50">
            <p>ASH OMEGA command console · v5.0.0</p>
            <p>Try one of these:</p>
            {SUGGESTIONS.map((s) => (
              <button
                key={s}
                onClick={() => setInput(s)}
                className="block text-left text-accent/80 transition-colors hover:text-accent"
              >
                ➜ {s}
              </button>
            ))}
          </div>
        )}

        {entries.map((e, i) => (
          <div key={`${e.ts}-${i}`} className="mb-2 animate-fade-up">
            <p className="text-mint">
              <span className="text-accent">➜</span> <span className="text-sky">~</span> {e.cmd}
            </p>
            {e.out && (
              <pre className={cn('whitespace-pre-wrap break-words', e.code === 0 ? 'text-subtext' : 'text-rose')}>
                {e.out}
              </pre>
            )}
          </div>
        ))}

        {busy && (
          <p className="animate-pulse text-accent/70">
            <span className="text-accent">➜</span> running…
          </p>
        )}
      </div>

      <form
        onSubmit={(e) => { e.preventDefault(); void submit(input) }}
        className="mt-3 flex items-center gap-2 rounded-xl border border-white/[0.08] bg-crust/70 px-3 py-1.5 transition-colors focus-within:border-accent/50"
      >
        <span className="font-mono text-[13px] text-mint" aria-hidden>➜</span>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'ArrowUp') {
              e.preventDefault()
              const next = Math.min(histIdx + 1, history.length - 1)
              setHistIdx(next)
              const cmd = history[history.length - 1 - next]?.cmd
              if (cmd) setInput(cmd)
            } else if (e.key === 'ArrowDown') {
              e.preventDefault()
              const next = Math.max(histIdx - 1, -1)
              setHistIdx(next)
              setInput(next === -1 ? '' : history[history.length - 1 - next]?.cmd ?? '')
            }
          }}
          spellCheck={false}
          autoComplete="off"
          placeholder="ash doctor"
          aria-label="Command input"
          className="flex-1 bg-transparent py-1.5 font-mono text-[12.5px] text-text outline-none placeholder:text-subtext/35"
        />
        <Button type="submit" variant="primary" loading={busy} disabled={!input.trim()}>Run</Button>
      </form>
    </Panel>
  )
}
