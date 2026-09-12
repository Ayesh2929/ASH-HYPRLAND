/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — analytics route
 * ═══════════════════════════════════════════════════════════════════════════
 */
import AnalyticsConsole from '../components/Analytics'
import Terminal from '../components/Terminal'
import NotificationCenter from '../components/NotificationCenter'
import AIChatAssistant from '../components/AIChatAssistant'

export default function Analytics() {
  return (
    <div className="space-y-4">
      <AnalyticsConsole />
      <div className="grid gap-4 xl:grid-cols-2">
        <Terminal />
        <AIChatAssistant />
      </div>
      <NotificationCenter />
    </div>
  )
}
