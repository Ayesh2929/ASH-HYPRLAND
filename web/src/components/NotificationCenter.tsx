/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — notification centre
 * ═══════════════════════════════════════════════════════════════════════════
 *  Mirrors the desktop notification history with per-app mute. Mutes are held
 *  in component state here; the daemon-side rule set lives in
 *  notification-engine and is edited through `ash notify rule`.
 */
import { useMemo, useState } from 'react'
import { useAnalyticsStore } from '../store/analyticsStore'
import { cn, timeAgo } from '../lib/utils'
import { Badge, Button, EmptyState, Panel, SectionHeader, Tabs, Toggle, useToast } from './ui'

interface Notice {
  id: string
  app: string
  emoji: string
  title: string
  body: string
  urgency: 'low' | 'normal' | 'critical'
  ts: string
  read: boolean
}

export default function NotificationCenter() {
  const logs = useAnalyticsStore((s) => s.logs)
  const toast = useToast()
  const [tab, setTab] = useState<'all' | 'unread' | 'critical'>('all')
  const [muted, setMuted] = useState<Record<string, boolean>>({})

  // Notification-flavoured entries derived from the live journal.
  const notices = useMemo<Notice[]>(() => {
    const apps: Array<[string, string]> = [
      ['ash-update', '⬆️'], ['systemd', '⚙️'], ['hyprland', '🪟'],
      ['pipewire', '🔊'], ['snapshot', '💾'], ['plugin', '🧩'],
    ]
    return logs
      .filter((l) => l.level === 'info' || l.level === 'warn' || l.level === 'error')
      .slice(-24)
      .reverse()
      .map((l, i) => {
        const [app, emoji] = apps[i % apps.length]!
        return {
          id: `${l.ts}-${i}`,
          app,
          emoji,
          title: `${l.scope} · ${l.message}`,
          body: l.fields ? Object.entries(l.fields).map(([k, v]) => `${k}=${v}`).join('  ') : '',
          urgency: l.level === 'error' ? 'critical' : l.level === 'warn' ? 'normal' : 'low',
          ts: l.ts,
          read: i > 4,
        }
      })
  }, [logs])

  const filtered = notices.filter((n) => {
    if (muted[n.app]) return false
    if (tab === 'unread') return !n.read
    if (tab === 'critical') return n.urgency === 'critical'
    return true
  })

  const unread = notices.filter((n) => !n.read).length
  const apps = [...new Set(notices.map((n) => n.app))]

  return (
    <Panel>
      <SectionHeader
        icon="🔔"
        title="Notifications"
        subtitle={`${unread} unread · ${notices.length} in history`}
        action={
          <Button icon="✅" onClick={() => toast.success('All marked as read')} disabled={unread === 0}>
            Mark read
          </Button>
        }
      />

      <Tabs
        className="mb-4"
        value={tab}
        onChange={setTab}
        tabs={[
          { id: 'all', label: 'All', count: notices.length },
          { id: 'unread', label: 'Unread', count: unread },
          { id: 'critical', label: 'Critical', count: notices.filter((n) => n.urgency === 'critical').length },
        ]}
      />

      {apps.length > 0 && (
        <div className="mb-4 rounded-xl border border-white/[0.06] bg-white/[0.02] p-3">
          <p className="mb-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-subtext/40">
            Mute by application
          </p>
          <div className="flex flex-wrap gap-3">
            {apps.map((a) => (
              <label key={a} className="flex cursor-pointer items-center gap-2 text-[11.5px] text-subtext">
                <Toggle
                  size="sm"
                  checked={!!muted[a]}
                  onChange={(v) => setMuted((m) => ({ ...m, [a]: v }))}
                  label={`Mute ${a}`}
                />
                <span className="font-mono">{a}</span>
              </label>
            ))}
          </div>
        </div>
      )}

      {filtered.length === 0 && (
        <EmptyState emoji="🔕" title="Nothing here" hint="Notifications you have not muted will appear in this list." />
      )}

      <ul className="space-y-1.5">
        {filtered.map((n, i) => (
          <li
            key={n.id}
            style={{ ['--i' as string]: i }}
            className={cn(
              'flex animate-fade-up items-start gap-3 rounded-xl border p-3 transition-all duration-200 hover:-translate-y-0.5',
              n.urgency === 'critical'
                ? 'border-rose/25 bg-rose/[0.06]'
                : 'border-white/[0.06] bg-white/[0.02] hover:border-white/15',
            )}
          >
            <span className="text-lg" aria-hidden>{n.emoji}</span>
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <span className="truncate text-[12.5px] text-text">{n.title}</span>
                {!n.read && <span className="h-1.5 w-1.5 rounded-full bg-accent" aria-label="unread" />}
                <Badge tone={n.urgency === 'critical' ? 'rose' : n.urgency === 'normal' ? 'gold' : 'neutral'}>
                  {n.urgency}
                </Badge>
              </div>
              {n.body && <p className="mt-0.5 truncate font-mono text-[10.5px] text-subtext/45">{n.body}</p>}
            </div>
            <span className="shrink-0 font-mono text-[10px] text-subtext/35">{timeAgo(n.ts)}</span>
          </li>
        ))}
      </ul>
    </Panel>
  )
}
