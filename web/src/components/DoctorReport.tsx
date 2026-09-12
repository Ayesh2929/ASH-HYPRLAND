/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — doctor diagnostics
 * ═══════════════════════════════════════════════════════════════════════════
 *  Renders `ash doctor --json`. Every warn/fail carries the exact fix command,
 *  copyable in one click — a diagnostic that does not tell you what to do next
 *  is just an accusation.
 */
import { useCallback, useEffect, useState } from 'react'
import type { CheckStatus, DoctorReport as Report } from '../lib/types'
import { api } from '../api/client'
import { cn } from '../lib/utils'
import { Badge, Button, Panel, SectionHeader, Skeleton, useToast, type Tone } from './ui'

const STATUS: Record<CheckStatus, { tone: Tone; emoji: string; label: string }> = {
  pass: { tone: 'mint', emoji: '✓', label: 'Pass' },
  warn: { tone: 'gold', emoji: '!', label: 'Warn' },
  fail: { tone: 'rose', emoji: '✕', label: 'Fail' },
  skip: { tone: 'neutral', emoji: '–', label: 'Skip' },
}

export default function DoctorReportPanel() {
  const [report, setReport] = useState<Report | null>(null)
  const [running, setRunning] = useState(false)
  const [open, setOpen] = useState<string | null>(null)
  const toast = useToast()

  const run = useCallback(async () => {
    setRunning(true)
    try {
      setReport(await api.doctor())
    } finally {
      setRunning(false)
    }
  }, [])

  useEffect(() => { void run() }, [run])

  const copyFix = async (fix: string) => {
    try {
      await navigator.clipboard.writeText(fix)
      toast.success('Fix command copied', fix)
    } catch {
      toast.error('Clipboard unavailable', 'Copy the command manually.')
    }
  }

  if (!report) {
    return (
      <Panel>
        <Skeleton className="h-5 w-36" />
        <div className="mt-4 space-y-2">
          {Array.from({ length: 5 }, (_, i) => <Skeleton key={i} className="h-11" />)}
        </div>
      </Panel>
    )
  }

  const scoreTone: Tone = report.score >= 90 ? 'mint' : report.score >= 70 ? 'gold' : 'rose'

  return (
    <Panel>
      <SectionHeader
        icon="🩺"
        title="System doctor"
        subtitle={`${report.checks.length} checks · last run ${new Date(report.generatedAt).toLocaleTimeString()}`}
        action={
          <div className="flex items-center gap-2">
            <Badge tone={scoreTone}>score {report.score}%</Badge>
            <Button icon="🔄" loading={running} onClick={() => void run()}>Re-run</Button>
          </div>
        }
      />

      <div className="mb-4 flex flex-wrap gap-2">
        {(Object.entries(report.summary) as Array<[CheckStatus, number]>).map(([status, n]) => (
          <span
            key={status}
            className={cn(
              'flex items-center gap-1.5 rounded-lg border px-2.5 py-1 text-[11px]',
              status === 'pass' ? 'border-mint/25 bg-mint/10 text-mint' :
              status === 'warn' ? 'border-gold/25 bg-gold/10 text-gold' :
              status === 'fail' ? 'border-rose/25 bg-rose/10 text-rose' :
              'border-white/10 bg-white/[0.03] text-subtext',
            )}
          >
            <span aria-hidden>{STATUS[status].emoji}</span>
            <span className="font-mono">{n}</span>
            {STATUS[status].label}
          </span>
        ))}
      </div>

      <ul className="space-y-1.5">
        {report.checks.map((c, i) => {
          const s = STATUS[c.status]
          const expanded = open === c.id
          return (
            <li
              key={c.id}
              style={{ ['--i' as string]: i }}
              className="animate-fade-up overflow-hidden rounded-xl border border-white/[0.06] bg-white/[0.02]"
            >
              <button
                onClick={() => setOpen(expanded ? null : c.id)}
                aria-expanded={expanded}
                className="flex w-full items-center gap-3 px-3 py-2.5 text-left transition-colors hover:bg-white/[0.03]"
              >
                <span
                  className={cn(
                    'grid h-6 w-6 shrink-0 place-items-center rounded-full text-[11px] font-bold',
                    c.status === 'pass' ? 'bg-mint/15 text-mint' :
                    c.status === 'warn' ? 'bg-gold/15 text-gold' :
                    c.status === 'fail' ? 'bg-rose/15 text-rose' :
                    'bg-white/[0.06] text-subtext',
                  )}
                  aria-hidden
                >
                  {s.emoji}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-[12.5px] text-text">{c.title}</span>
                  <span className="block truncate text-[11px] text-subtext/55">{c.message}</span>
                </span>
                <Badge tone="neutral">{c.category}</Badge>
                <span className={cn('text-subtext/40 transition-transform duration-200', expanded && 'rotate-90')} aria-hidden>
                  ›
                </span>
              </button>

              {expanded && (
                <div className="animate-fade-up border-t border-white/[0.05] px-3 py-2.5">
                  <p className="text-[11.5px] leading-relaxed text-subtext/75">{c.message}</p>
                  {c.fix && (
                    <div className="mt-2 flex items-center gap-2">
                      <code className="flex-1 truncate rounded-lg border border-white/[0.07] bg-crust/70 px-2.5 py-1.5 font-mono text-[11px] text-accent">
                        {c.fix}
                      </code>
                      <Button icon="📋" onClick={() => void copyFix(c.fix!)}>Copy</Button>
                    </div>
                  )}
                </div>
              )}
            </li>
          )
        })}
      </ul>
    </Panel>
  )
}
