/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — snapshots route
 * ═══════════════════════════════════════════════════════════════════════════
 */
import SnapshotManager from '../components/SnapshotManager'
import DoctorReportPanel from '../components/DoctorReport'
import { StoragePanel } from '../components/Dashboard'

export default function Snapshots() {
  return (
    <div className="space-y-4">
      <SnapshotManager />
      <div className="grid gap-4 xl:grid-cols-[1.4fr_1fr]">
        <DoctorReportPanel />
        <StoragePanel />
      </div>
    </div>
  )
}
