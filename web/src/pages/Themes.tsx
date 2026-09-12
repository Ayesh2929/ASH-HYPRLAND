/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — themes route
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { useState } from 'react'
import type { Theme } from '../lib/types'
import ThemeGallery from '../components/ThemeGallery'
import ThemeEditor from '../components/ThemeEditor'
import ThemeManager from '../components/ThemeManager'
import WallpaperPicker from '../components/WallpaperPicker'

export default function Themes() {
  const [editing, setEditing] = useState<Theme | null>(null)

  return (
    <div className="space-y-4">
      {editing ? (
        <ThemeEditor theme={editing} onClose={() => setEditing(null)} />
      ) : (
        <ThemeGallery onEdit={setEditing} />
      )}
      <div className="grid gap-4 xl:grid-cols-2">
        <ThemeManager />
        <WallpaperPicker />
      </div>
    </div>
  )
}
