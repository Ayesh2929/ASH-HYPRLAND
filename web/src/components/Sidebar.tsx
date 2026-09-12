/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — sidebar navigation
 * ═══════════════════════════════════════════════════════════════════════════
 *  Rail is 68px collapsed and 264px expanded. The width transition is on
 *  `width` (a layout property) only because a transform-based alternative
 *  would clip the labels; the *content* fades on opacity so nothing reflows
 *  visibly while the rail slides.
 */
import { NavLink } from 'react-router-dom'
import { cn } from '../lib/utils'
import { Badge, IconButton, Tooltip } from './ui'
import { useConfigStore } from '../store/configStore'

interface NavItem {
  to: string
  label: string
  emoji: string
  hint: string
  badge?: string
}

const PRIMARY: NavItem[] = [
  { to: '/',          label: 'Dashboard',  emoji: '🏠', hint: 'Live system overview' },
  { to: '/themes',    label: 'Themes',     emoji: '🎨', hint: 'Browse, edit and generate palettes' },
  { to: '/plugins',   label: 'Plugins',    emoji: '🧩', hint: 'Extend the desktop' },
  { to: '/snapshots', label: 'Snapshots',  emoji: '💾', hint: 'Backup and restore config state' },
  { to: '/analytics', label: 'Analytics',  emoji: '📊', hint: 'Metrics, logs and trends' },
]

const SECONDARY: NavItem[] = [
  { to: '/settings', label: 'Settings', emoji: '⚙️', hint: 'Preferences and integrations' },
  { to: '/about',    label: 'About',    emoji: 'ℹ️', hint: 'Version and credits' },
]

export default function Sidebar({
  collapsed, onToggle, onOpenPalette,
}: { collapsed: boolean; onToggle: () => void; onOpenPalette: () => void }) {
  const modes = useConfigStore((s) => s.modes)
  const active = modes.find((m) => m.active)

  return (
    <aside
      className={cn(
        'sticky top-0 z-40 hidden h-screen shrink-0 flex-col border-r border-white/[0.06]',
        'bg-mantle/55 backdrop-blur-2xl transition-[width] duration-300 lg:flex',
        'motion-reduce:transition-none',
        collapsed ? 'w-[72px]' : 'w-[264px]',
      )}
      style={{ transitionTimingFunction: 'var(--ash-ease-swift)' }}
    >
      {/* ── Brand ──────────────────────────────────────────────────────── */}
      <div className={cn('flex items-center gap-3 px-4 py-5', collapsed && 'justify-center px-2')}>
        <div className="relative grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-gradient-to-br from-accent to-violet shadow-glow">
          <span className="font-mono text-[15px] font-black text-crust">A</span>
          <span className="absolute inset-0 animate-pulse-ring rounded-xl border border-accent/60" aria-hidden />
        </div>
        {!collapsed && (
          <div className="min-w-0 animate-fade-in">
            <p className="truncate text-[13px] font-bold tracking-tight text-text">ASH OMEGA</p>
            <p className="truncate font-mono text-[10px] text-subtext/55">v5.0.0-omega</p>
          </div>
        )}
      </div>

      {/* ── Command palette trigger ────────────────────────────────────── */}
      <div className={cn('px-3 pb-4', collapsed && 'px-2')}>
        {collapsed ? (
          <Tooltip text="Search · ⌘K">
            <IconButton label="Open command palette" icon="🔍" onClick={onOpenPalette} className="w-full" />
          </Tooltip>
        ) : (
          <button
            onClick={onOpenPalette}
            className="flex w-full items-center gap-2.5 rounded-xl border border-white/[0.07] bg-crust/50
                       px-3 py-2.5 text-left text-[12px] text-subtext/60 transition-all duration-200
                       hover:border-accent/35 hover:bg-accent/[0.07] hover:text-subtext"
          >
            <span aria-hidden>🔍</span>
            <span className="flex-1">Search or run a command…</span>
            <kbd className="rounded border border-white/10 bg-white/[0.05] px-1.5 py-0.5 font-mono text-[10px]">⌘K</kbd>
          </button>
        )}
      </div>

      {/* ── Navigation ─────────────────────────────────────────────────── */}
      <nav className="flex-1 space-y-1 overflow-y-auto px-3 pb-4" aria-label="Main">
        {!collapsed && (
          <p className="px-3 pb-1.5 pt-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-subtext/40">
            Workspace
          </p>
        )}
        {PRIMARY.map((item) => <NavRow key={item.to} item={item} collapsed={collapsed} />)}

        {!collapsed && (
          <p className="px-3 pb-1.5 pt-4 text-[10px] font-semibold uppercase tracking-[0.14em] text-subtext/40">
            System
          </p>
        )}
        {SECONDARY.map((item) => <NavRow key={item.to} item={item} collapsed={collapsed} />)}
      </nav>

      {/* ── Active mode pill ───────────────────────────────────────────── */}
      {active && !collapsed && (
        <div className="mx-3 mb-4 animate-fade-up rounded-xl border border-white/[0.07] bg-gradient-to-br from-white/[0.045] to-transparent p-3">
          <p className="mb-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-subtext/40">
            Active mode
          </p>
          <div className="flex items-center gap-2.5">
            <span className="text-lg" aria-hidden>{active.emoji}</span>
            <div className="min-w-0">
              <p className="truncate text-[12px] font-semibold text-text">{active.name}</p>
              <p className="truncate text-[10px] capitalize text-subtext/55">{active.powerProfile}</p>
            </div>
          </div>
        </div>
      )}

      {/* ── Collapse control ───────────────────────────────────────────── */}
      <div className={cn('border-t border-white/[0.06] p-3', collapsed && 'px-2')}>
        <Tooltip text={collapsed ? 'Expand · ⌘B' : 'Collapse · ⌘B'}>
          <button
            onClick={onToggle}
            aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            className={cn(
              'flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-[12px] text-subtext/60',
              'transition-all duration-200 hover:bg-white/5 hover:text-text',
              collapsed && 'justify-center px-2',
            )}
          >
            <span aria-hidden className={cn('transition-transform duration-300', collapsed && 'rotate-180')}>
              ◀
            </span>
            {!collapsed && <span>Collapse</span>}
          </button>
        </Tooltip>
      </div>
    </aside>
  )
}

function NavRow({ item, collapsed }: { item: NavItem; collapsed: boolean }) {
  const link = (
    <NavLink
      to={item.to}
      end={item.to === '/'}
      className={({ isActive }) => cn(
        'group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-[13px] font-medium',
        'transition-all duration-200 active:scale-[.98]',
        collapsed && 'justify-center px-2',
        isActive
          ? 'bg-accent/12 text-accent'
          : 'text-subtext/75 hover:bg-white/[0.05] hover:text-text',
      )}
    >
      {({ isActive }) => (
        <>
          {/* Active rail marker — scales in rather than appearing abruptly. */}
          <span
            className={cn(
              'absolute left-0 top-1/2 h-6 w-[3px] -translate-y-1/2 rounded-r-full bg-accent',
              'origin-center transition-transform duration-300',
              isActive ? 'scale-y-100' : 'scale-y-0',
            )}
            aria-hidden
          />
          <span className="text-[16px] leading-none" aria-hidden>{item.emoji}</span>
          {!collapsed && (
            <>
              <span className="flex-1 truncate">{item.label}</span>
              {item.badge && <Badge tone="accent">{item.badge}</Badge>}
            </>
          )}
        </>
      )}
    </NavLink>
  )

  return collapsed ? <Tooltip text={item.hint}>{link}</Tooltip> : link
}
