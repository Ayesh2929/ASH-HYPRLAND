/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — snapshot manager
 * ═══════════════════════════════════════════════════════════════════════════
 *  Create, restore and prune configuration snapshots. Restore is gated behind
 *  a confirmation modal that spells out what will be overwritten — the only
 *  destructive action in the dashboard, so it asks properly.
 */
import { useMemo, useState } from 'react'
import type { Snapshot } from '../lib/types'
import { useConfigStore } from '../store/configStore'
import { formatBytes, timeAgo } from '../lib/utils'
import { Badge, Button, EmptyState, Input, Modal, Panel, SectionHeader, Skeleton, Tabs, useToast } from './ui'

const TRIGGER_TONE = {
  manual: 'accent', auto: 'sky', 'pre-update': 'gold', 'pre-rollback': 'rose',
} as const

export default function SnapshotManager() {
  const snapshots = useConfigStore((s) => s.snapshots)
  const loading = useConfigStore((s) => s.loading)
  const create = useConfigStore((s) => s.createSnapshot)
  const restore = useConfigStore((s) => s.restoreSnapshot)
  const remove = useConfigStore((s) => s.deleteSnapshot)
  const toast = useToast()

  const [filter, setFilter] = useState<'all' | Snapshot['trigger']>('all')
  const [label, setLabel] = useState('')
  const [creating, setCreating] = useState(false)
  const [confirmRestore, setConfirmRestore] = useState<Snapshot | null>(null)
  const [confirmDelete, setConfirmDelete] = useState<Snapshot | null>(null)

  const filtered = useMemo(
    () => (filter === 'all' ? snapshots : snapshots.filter((s) => s.trigger === filter)),
    [snapshots, filter],
  )

  const totals = useMemo(() => ({
    count: snapshots.length,
    size: snapshots.reduce((a, s) => a + s.size, 0),
    files: snapshots.reduce((a, s) => a + s.files, 0),
  }), [snapshots])

  const onCreate = async () => {
    setCreating(true)
    try {
      await create(label || `manual-${new Date().toISOString().slice(0, 16)}`)
      toast.success('Snapshot created', 'Restore point saved and checksummed.')
      setLabel('')
    } finally {
      setCreating(false)
    }
  }

  const doRestore = async (s: Snapshot) => {
    setConfirmRestore(null)
    await restore(s.id)
    toast.success('Snapshot restored', `Rolled back to “${s.label}”.`)
  }

  const doDelete = async (s: Snapshot) => {
    setConfirmDelete(null)
    await remove(s.id)
    toast.info('Snapshot deleted', s.label)
  }

  return (
    <Panel>
      <SectionHeader
        icon="💾"
        title="Snapshots"
        subtitle={`${totals.count} restore points · ${formatBytes(totals.size)} · ${totals.files.toLocaleString()} files tracked`}
      />

      <div className="mb-4 flex flex-wrap items-center gap-2.5">
        <div className="min-w-[13rem] flex-1">
          <Input
            prefix="🏷️"
            placeholder="Label for the new snapshot…"
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') void onCreate() }}
          />
        </div>
        <Button variant="primary" icon="📸" loading={creating} onClick={() => void onCreate()}>
          Create snapshot
        </Button>
      </div>

      <Tabs
        className="mb-4"
        value={filter}
        onChange={setFilter}
        tabs={[
          { id: 'all', label: 'All', count: snapshots.length },
          { id: 'manual', label: 'Manual', count: snapshots.filter((s) => s.trigger === 'manual').length },
          { id: 'auto', label: 'Automatic', count: snapshots.filter((s) => s.trigger === 'auto').length },
          { id: 'pre-update', label: 'Pre-update', count: snapshots.filter((s) => s.trigger === 'pre-update').length },
        ]}
      />

      {loading && snapshots.length === 0 && (
        <div className="space-y-2">
          {Array.from({ length: 5 }, (_, i) => <Skeleton key={i} className="h-16" />)}
        </div>
      )}

      {!loading && filtered.length === 0 && (
        <EmptyState emoji="💾" title="No snapshots here yet" hint="Create one before your next big config change." />
      )}

      <ul className="space-y-2">
        {filtered.map((s, i) => (
          <li
            key={s.id}
            style={{ ['--i' as string]: Math.min(i, 14) }}
            className="flex animate-fade-up flex-wrap items-center gap-3 rounded-xl border border-white/[0.07] bg-white/[0.02] p-3.5 transition-all duration-200 hover:-translate-y-0.5 hover:border-white/15"
          >
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-white/[0.05] text-lg" aria-hidden>
              {s.trigger === 'auto' ? '🤖' : s.trigger === 'pre-update' ? '⬆️' : s.trigger === 'pre-rollback' ? '⏪' : '📸'}
            </span>

            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <span className="truncate text-[13px] font-semibold text-text">{s.label}</span>
                <Badge tone={TRIGGER_TONE[s.trigger]}>{s.trigger}</Badge>
                {s.compressed && <Badge tone="neutral">zstd</Badge>}
                {!s.restorable && <Badge tone="rose">corrupt</Badge>}
              </div>
              <p className="mt-0.5 flex flex-wrap items-center gap-x-3 gap-y-0.5 font-mono text-[10.5px] text-subtext/50">
                <span>{timeAgo(s.createdAt)}</span>
                <span>{formatBytes(s.size)}</span>
                <span>{s.files.toLocaleString()} files</span>
                <span className="text-subtext/35">sha:{s.checksum}</span>
              </p>
            </div>

            <div className="flex shrink-0 gap-2">
              <Button
                icon="⏪"
                disabled={!s.restorable}
                onClick={() => setConfirmRestore(s)}
              >
                Restore
              </Button>
              <Button variant="danger" icon="🗑️" onClick={() => setConfirmDelete(s)} aria-label={`Delete ${s.label}`} />
            </div>
          </li>
        ))}
      </ul>

      {/* ── Restore confirmation ──────────────────────────────────────── */}
      <Modal
        open={confirmRestore !== null}
        onClose={() => setConfirmRestore(null)}
        title="Restore this snapshot?"
        subtitle="Your current configuration will be snapshotted first, so this is reversible."
        footer={
          <>
            <Button onClick={() => setConfirmRestore(null)}>Cancel</Button>
            <Button variant="primary" icon="⏪" onClick={() => confirmRestore && void doRestore(confirmRestore)}>
              Restore now
            </Button>
          </>
        }
      >
        {confirmRestore && (
          <div className="space-y-3">
            <div className="rounded-xl border border-gold/25 bg-gold/[0.07] p-3.5 text-[12px] text-gold">
              ⚠️ Files changed since this snapshot will be overwritten.
            </div>
            <dl className="space-y-2 text-[12px]">
              <div className="flex justify-between"><dt className="text-subtext/60">Label</dt><dd className="text-text">{confirmRestore.label}</dd></div>
              <div className="flex justify-between"><dt className="text-subtext/60">Taken</dt><dd className="text-text">{new Date(confirmRestore.createdAt).toLocaleString()}</dd></div>
              <div className="flex justify-between"><dt className="text-subtext/60">Size</dt><dd className="font-mono text-text">{formatBytes(confirmRestore.size)}</dd></div>
              <div className="flex justify-between"><dt className="text-subtext/60">Files</dt><dd className="font-mono text-text">{confirmRestore.files.toLocaleString()}</dd></div>
            </dl>
          </div>
        )}
      </Modal>

      {/* ── Delete confirmation ───────────────────────────────────────── */}
      <Modal
        open={confirmDelete !== null}
        onClose={() => setConfirmDelete(null)}
        title="Delete this snapshot?"
        subtitle="This cannot be undone."
        width="max-w-md"
        footer={
          <>
            <Button onClick={() => setConfirmDelete(null)}>Keep it</Button>
            <Button variant="danger" icon="🗑️" onClick={() => confirmDelete && void doDelete(confirmDelete)}>
              Delete permanently
            </Button>
          </>
        }
      >
        <p className="text-[12.5px] text-subtext">
          <span className="font-semibold text-text">{confirmDelete?.label}</span> will be removed and{' '}
          {confirmDelete && formatBytes(confirmDelete.size)} reclaimed.
        </p>
      </Modal>
    </Panel>
  )
}
