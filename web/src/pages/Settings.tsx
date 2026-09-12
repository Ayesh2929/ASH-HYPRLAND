/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — settings route
 * ═══════════════════════════════════════════════════════════════════════════
 */
import SettingsPanel from '../components/Settings'
import HardwareReport from '../components/HardwareReport'
import ModeSelector from '../components/ModeSelector'

export default function Settings() {
  return (
    <div className="space-y-4">
      <SettingsPanel />
      <div className="grid gap-4 xl:grid-cols-2">
        <HardwareReport />
        <ModeSelector />
      </div>
    </div>
  )
}
