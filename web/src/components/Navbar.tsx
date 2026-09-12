/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — top bar
 * ═══════════════════════════════════════════════════════════════════════════
 *  Shows route context, a live connection pulse, and the mode switcher.
 */
import { useLocation } from 'react-router-dom'
import { cn, formatTime } from '../lib/utils'
import { Badge, IconButton, Tooltip } from './ui'
import { useConfigStore } from '../store/configStore'
import { useThemeStore } from '../store/themeStore'
import { useEffect, useState } from 'react'

const TITLES: Record<string, { title: string; emoji: string }> = {
  '/':          { title: 'Dashboard',  emoji: '🏠' },
  '/themes':    { title: 'Themes',     emoji: '🎨' },
  '/plugins':   { title: 'Plugins',    emoji: '🧩' },
  '/snapshots': { title: 'Snapshots',  emoji: '💾' },
  '/analytics': { title: 'Analytics',  emoji: '📊' },
  '/settings':  { title: 'Settings',   emoji: '⚙️' },
  '/about':     { title: 'About',      emoji: 'ℹ️' },
}

export default function Navbar({
  onOpenPalette, offline, live,
}: { onOpenPalette: () => void; offline: boolean; live: boolean }) {
  const { pathname } = useLocation()
  const meta = TITLES[pathname] ?? { title: 'ASH', emoji: '⚡' }

  const modes = useConfigStore((s) => s.modes)
  const setMode = useConfigStore((s) => s.setMode)
  const theme = useThemeStore((s) => s.active)

  const [clock, setClock] = useState(() => new Date())
  useEffect(() => {
    const t = setInterval(() => setClock(new Date()), 1000)
    return () => clearInterval(t)
  }, [])

  return (
    <header className="sticky top-0 z-30 border-b border-white/[0.06] bg-mantle/60 backdrop-blur-2xl">
      <div className="flex items-center gap-3 px-5 py-3 lg:px-8">
        <span className="text-xl lg:hidden" aria-hidden>{meta.emoji}</span>

        <div className="min-w-0 flex-1">
          <h1 className="flex items-center gap-2 truncate text-[15px] font-semibold tracking-tight text-text">
            <span className="hidden lg:inline" aria-hidden>{meta.emoji}</span>
            {meta.title}
          </h1>
        </div>

        {/* ── Mode switcher ──────────────────────────────────────────── */}
        <div className="no-scrollbar hidden max-w-[46%] items-center gap-1.5 overflow-x-auto xl:flex">
          {modes.slice(0, 6).map((m) => (
            <button
              key={m.id}
              onClick={() => void setMode(m.id)}
              title={m.description}
              aria-pressed={m.active}
              className={cn(
                'flex shrink-0 items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-[11px] font-medium',
                'transition-all duration-200 active:scale-95',
                m.active
                  ? 'border-transparent bg-white/[0.09] text-text shadow-glow'
                  : 'border-white/[0.06] text-subtext/60 hover:border-white/15 hover:text-text',
              )}
            >
              <span aria-hidden>{m.emoji}</span>
              {m.name}
            </button>
          ))}
        </div>

        {/* ── Connection state ───────────────────────────────────────── */}
        <Tooltip text={offline ? 'Daemon unreachable — showing cached data' : live ? 'Live socket connected' : 'Connecting…'}>
          <Badge tone={offline ? 'gold' : live ? 'mint' : 'neutral'} dot>
            {offline ? 'offline' : live ? 'live' : 'idle'}
          </Badge>
        </Tooltip>

        {theme && (
          <Tooltip text={`Active theme: ${theme.name}`}>
            <span className="hidden items-center gap-2 rounded-lg border border-white/[0.07] bg-white/[0.02] px-2.5 py-1.5 sm:flex">
              <span className="flex gap-0.5" aria-hidden>
                {[theme.colors.accent, theme.colors.sky, theme.colors.mint].map((c) => (
                  <span key={c} className="h-2.5 w-2.5 rounded-full" style={{ background: c }} />
                ))}
              </span>
              <span className="max-w-[9rem] truncate text-[11px] text-subtext/75">{theme.name}</span>
            </span>
          </Tooltip>
        )}

        <span className="hidden font-mono text-[12px] tabular-nums text-subtext/55 md:inline">
          {formatTime(clock.getTime())}
        </span>

        <IconButton label="Open command palette" icon="⌘" onClick={onOpenPalette} />
      </div>
    </header>
  )
}
