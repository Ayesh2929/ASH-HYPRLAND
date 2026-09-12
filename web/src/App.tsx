/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║  🌐 ASH DOTFILES v5.0 OMEGA — application shell                           ║
 * ║                                                                           ║
 * ║  Layout, routing and the global keyboard layer. Every page is lazy-loaded ║
 * ║  so the first paint ships only the shell plus the active route.           ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
import { Suspense, lazy, useCallback, useEffect, useState } from 'react'
import { Navigate, Route, Routes, useLocation } from 'react-router-dom'

import Navbar from './components/Navbar'
import Sidebar from './components/Sidebar'
import CommandPalette from './components/CommandPalette'
import { Spinner, ToastProvider, useHotkey } from './components/ui'

import { useConfigStore } from './store/configStore'
import { useThemeStore } from './store/themeStore'
import { usePluginStore } from './store/pluginStore'
import { useAnalyticsStore } from './store/analyticsStore'
import { onConnectivityChange } from './api/client'
import { cn } from './lib/utils'

const Home = lazy(() => import('./pages/Home'))
const Themes = lazy(() => import('./pages/Themes'))
const Plugins = lazy(() => import('./pages/Plugins'))
const Snapshots = lazy(() => import('./pages/Snapshots'))
const Settings = lazy(() => import('./pages/Settings'))
const AnalyticsPage = lazy(() => import('./pages/Analytics'))
const About = lazy(() => import('./pages/About'))

function RouteFallback() {
  return (
    <div className="grid h-[60vh] place-items-center">
      <div className="flex flex-col items-center gap-3 text-subtext">
        <Spinner size={26} />
        <p className="animate-pulse text-[12px] tracking-wide">loading module…</p>
      </div>
    </div>
  )
}

/** Animated aurora backdrop. Pure CSS, no canvas, no rAF loop. */
function Aurora() {
  return (
    <div className="ash-aurora" aria-hidden>
      <span className="left-[-10%] top-[-12%] h-[38rem] w-[38rem] bg-accent/40" />
      <span className="right-[-14%] top-[6%] h-[32rem] w-[32rem] bg-sky/30" style={{ animationDelay: '-7s' }} />
      <span className="bottom-[-18%] left-[28%] h-[34rem] w-[34rem] bg-violet/25" style={{ animationDelay: '-14s' }} />
    </div>
  )
}

function Shell() {
  const location = useLocation()
  const [paletteOpen, setPaletteOpen] = useState(false)
  const [collapsed, setCollapsed] = useState(false)
  const [offline, setOffline] = useState(false)

  const bootstrap = useConfigStore((s) => s.bootstrap)
  const startLive = useConfigStore((s) => s.startLive)
  const stopLive = useConfigStore((s) => s.stopLive)
  const live = useConfigStore((s) => s.live)
  const loadThemes = useThemeStore((s) => s.load)
  const loadPlugins = usePluginStore((s) => s.load)
  const loadLogs = useAnalyticsStore((s) => s.loadLogs)

  useEffect(() => {
    void loadThemes()
    void loadPlugins()
    void bootstrap()
    void loadLogs(200)
    startLive()
    return () => stopLive()
  }, [bootstrap, startLive, stopLive, loadThemes, loadPlugins, loadLogs])

  useEffect(() => onConnectivityChange(setOffline), [])

  const openPalette = useCallback(() => setPaletteOpen(true), [])
  useHotkey('k', openPalette)
  useHotkey('b', () => setCollapsed((c) => !c))

  return (
    <ToastProvider>
      <Aurora />

      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-[300]
                   focus:rounded-lg focus:bg-accent focus:px-4 focus:py-2 focus:text-crust"
      >
        Skip to content
      </a>

      <div className="flex min-h-screen">
        <Sidebar
          collapsed={collapsed}
          onToggle={() => setCollapsed((c) => !c)}
          onOpenPalette={openPalette}
        />

        <div className="flex min-w-0 flex-1 flex-col">
          <Navbar onOpenPalette={openPalette} offline={offline} live={live} />

          <main
            id="main"
            key={location.pathname}
            className={cn('flex-1 animate-fade-up px-5 py-6 lg:px-8 lg:py-8')}
          >
            <div className="mx-auto w-full max-w-[1600px]">
              <Suspense fallback={<RouteFallback />}>
                <Routes>
                  <Route path="/" element={<Home />} />
                  <Route path="/themes" element={<Themes />} />
                  <Route path="/plugins" element={<Plugins />} />
                  <Route path="/snapshots" element={<Snapshots />} />
                  <Route path="/analytics" element={<AnalyticsPage />} />
                  <Route path="/settings" element={<Settings />} />
                  <Route path="/about" element={<About />} />
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </Suspense>
            </div>
          </main>

          <footer className="border-t border-white/[0.05] px-5 py-4 lg:px-8">
            <div className="mx-auto flex w-full max-w-[1600px] flex-wrap items-center justify-between gap-2 text-[11px] text-subtext/45">
              <span className="font-mono">
                ASH DOTFILES <span className="text-accent/70">v5.0.0-omega</span>
              </span>
              <span className="flex items-center gap-3">
                <span>115 commands</span>
                <span className="opacity-40">·</span>
                <span>2,248 files</span>
                <span className="opacity-40">·</span>
                <kbd className="rounded border border-white/10 bg-white/[0.04] px-1.5 py-0.5 font-mono">⌘K</kbd>
              </span>
            </div>
          </footer>
        </div>
      </div>

      <CommandPalette open={paletteOpen} onClose={() => setPaletteOpen(false)} />
    </ToastProvider>
  )
}

export default function App() {
  return <Shell />
}
