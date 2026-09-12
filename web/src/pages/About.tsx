/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — about route
 * ═══════════════════════════════════════════════════════════════════════════
 */
import { useEffect, useState } from 'react'
import { api, isOffline } from '../api/client'
import { Badge, Panel, SectionHeader } from '../components/ui'

const FEATURES = [
  { emoji: '🎨', title: '250+ themes', body: 'Every palette is OKLCH-tagged and WCAG-audited on import, so nothing unreadable ever ships.' },
  { emoji: '🧩', title: '150+ plugins', body: 'Sandboxed hooks with declared dependencies, timeouts and a self-skip exit code.' },
  { emoji: '⌨️', title: '115 CLI commands', body: 'One dispatcher, lazy-loaded commands, structured JSON output for every verb.' },
  { emoji: '💾', title: 'Atomic snapshots', body: 'Incremental rsync farms with hard links, checksummed and restorable in seconds.' },
  { emoji: '🔐', title: 'Crypto toolkit', body: 'Binary-safe hashing, HMAC, keyed secrets and constant-time comparison.' },
  { emoji: '📡', title: 'Live telemetry', body: 'Local-only NDJSON journal, opt-in, purgeable, and never uploaded.' },
]

export default function About() {
  const [health, setHealth] = useState<{ version: string; uptime: number } | null>(null)

  useEffect(() => {
    void api.health().then(setHealth).catch(() => undefined)
  }, [])

  return (
    <div className="space-y-4">
      <div className="ash-panel-glow">
        <div className="p-8 text-center">
          <div className="mx-auto mb-4 grid h-16 w-16 animate-float place-items-center rounded-2xl bg-gradient-to-br from-accent to-violet shadow-glow">
            <span className="font-mono text-2xl font-black text-crust">A</span>
          </div>
          <h1 className="text-gradient text-3xl font-black tracking-tight">ASH DOTFILES</h1>
          <p className="mt-1 font-mono text-[12px] text-subtext/60">v5.0.0-omega · Hyprland desktop environment</p>

          <div className="mt-4 flex flex-wrap items-center justify-center gap-2">
            <Badge tone="accent" dot>bash 5.2</Badge>
            <Badge tone="sky">arch / nix / debian</Badge>
            <Badge tone="mint">MIT licensed</Badge>
            <Badge tone={isOffline() ? 'gold' : 'mint'}>
              {isOffline() ? 'daemon offline' : `daemon ${health?.version ?? 'ok'}`}
            </Badge>
          </div>

          <p className="mx-auto mt-5 max-w-xl text-[13px] leading-relaxed text-subtext/70">
            A modular desktop built around one shell library, one configuration
            schema and one state machine. Every subsystem can be replaced
            independently — themes without the dashboard, plugins without the
            daemon, the CLI without the desktop.
          </p>
        </div>
      </div>

      <Panel>
        <SectionHeader icon="✨" title="What is inside" subtitle="Six subsystems, one coherent contract." />
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {FEATURES.map((f, i) => (
            <div
              key={f.title}
              style={{ ['--i' as string]: i }}
              className="animate-fade-up rounded-xl border border-white/[0.06] bg-white/[0.02] p-4 transition-all duration-300 hover:-translate-y-1 hover:border-accent/30"
            >
              <span className="text-2xl" aria-hidden>{f.emoji}</span>
              <h3 className="mt-2 text-[13px] font-semibold text-text">{f.title}</h3>
              <p className="mt-1 text-[11.5px] leading-relaxed text-subtext/60">{f.body}</p>
            </div>
          ))}
        </div>
      </Panel>

      <div className="grid gap-4 lg:grid-cols-2">
        <Panel>
          <SectionHeader icon="🧱" title="Requirements" />
          <ul className="space-y-2 text-[12px]">
            {[
              ['Hyprland', '>= 0.40', 'compositor'],
              ['bash', '>= 5.1', 'scripts use associative arrays'],
              ['jq', '>= 1.6', 'JSON parsing (python3 fallback)'],
              ['python3', '>= 3.10', 'optional, for the API bridge'],
              ['node', '>= 18.18', 'this dashboard'],
            ].map(([name, ver, why]) => (
              <li key={name} className="flex items-baseline justify-between gap-3 border-b border-white/[0.04] pb-2 last:border-0">
                <span className="text-text">{name}</span>
                <span className="font-mono text-[11px] text-accent">{ver}</span>
                <span className="text-[11px] text-subtext/50">{why}</span>
              </li>
            ))}
          </ul>
        </Panel>

        <Panel>
          <SectionHeader icon="🔗" title="Links" />
          <div className="space-y-2">
            {[
              ['📖 Documentation', 'docs/'],
              ['🐛 Issue tracker', 'https://github.com/ayesh/ash-dotfiles/issues'],
              ['📜 Changelog', 'CHANGELOG.md'],
              ['🔐 Security policy', 'SECURITY.md'],
            ].map(([label, href]) => (
              <a
                key={label}
                href={href}
                target="_blank"
                rel="noreferrer noopener"
                className="flex items-center justify-between rounded-xl border border-white/[0.06] bg-white/[0.02] px-3.5 py-2.5 text-[12.5px] text-subtext transition-all duration-200 hover:-translate-y-0.5 hover:border-accent/35 hover:text-text"
              >
                {label}
                <span aria-hidden>↗</span>
              </a>
            ))}
          </div>
        </Panel>
      </div>
    </div>
  )
}
