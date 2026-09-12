/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — plugins route
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { useState } from 'react'
import PluginManager from '../components/PluginManager'
import PluginStore from '../components/PluginStore'
import { Tabs } from '../components/ui'
import KeybindViewer from '../components/KeybindViewer'

export default function Plugins() {
  const [tab, setTab] = useState<'installed' | 'store'>('installed')

  return (
    <div className="space-y-4">
      <Tabs
        value={tab}
        onChange={setTab}
        tabs={[
          { id: 'installed', label: 'Installed', icon: '🧩' },
          { id: 'store', label: 'Store', icon: '🏪' },
        ]}
      />
      {tab === 'installed' ? <PluginManager /> : <PluginStore />}
      {tab === 'installed' && <KeybindViewer />}
    </div>
  )
}
