/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║  🌐 ASH DOTFILES v5.0 OMEGA — UI primitives                               ║
 * ║                                                                           ║
 * ║  Every control the dashboard uses is defined once, here. All of them are  ║
 * ║  keyboard-accessible, animated with transform/opacity only (so they stay  ║
 * ║  on the compositor), and honour prefers-reduced-motion via globals.css.   ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
import React, {
  createContext, useCallback, useContext, useEffect, useId, useMemo,
  useRef, useState, type ReactNode,
} from 'react'
import { cn } from '../../lib/utils'

/* ═══════════════════════════════════════════════════════════════════════════
   § 1  LAYOUT PRIMITIVES
   ═══════════════════════════════════════════════════════════════════════════ */

export function Panel({
  className, glow = false, children, ...rest
}: React.HTMLAttributes<HTMLDivElement> & { glow?: boolean }) {
  if (glow) {
    return (
      <div className={cn('ash-panel-glow', 'gpu', className)} {...rest}>
        <div className="p-5">{children}</div>
      </div>
    )
  }
  return <div className={cn('ash-panel p-5', 'gpu', className)} {...rest}>{children}</div>
}

export function SectionHeader({
  title, subtitle, icon, action,
}: { title: string; subtitle?: string; icon?: ReactNode; action?: ReactNode }) {
  return (
    <div className="mb-5 flex items-start justify-between gap-4">
      <div className="flex items-start gap-3">
        {icon && (
          <div className="mt-0.5 grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-accent/12 text-lg ring-1 ring-inset ring-accent/20">
            {icon}
          </div>
        )}
        <div>
          <h2 className="text-base font-semibold tracking-tight text-text">{title}</h2>
          {subtitle && <p className="mt-0.5 text-[13px] leading-relaxed text-subtext/75">{subtitle}</p>}
        </div>
      </div>
      {action}
    </div>
  )
}

export function EmptyState({
  emoji = '🗂️', title, hint, action,
}: { emoji?: string; title: string; hint?: string; action?: ReactNode }) {
  return (
    <div className="flex animate-fade-up flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-white/10 px-6 py-14 text-center">
      <div className="animate-float text-4xl" aria-hidden>{emoji}</div>
      <p className="text-sm font-medium text-text">{title}</p>
      {hint && <p className="max-w-sm text-[13px] text-subtext/70">{hint}</p>}
      {action && <div className="mt-1">{action}</div>}
    </div>
  )
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 2  BUTTONS & INPUTS
   ═══════════════════════════════════════════════════════════════════════════ */

type ButtonVariant = 'primary' | 'ghost' | 'danger' | 'subtle'

export function Button({
  variant = 'ghost', icon, loading = false, className, children, disabled, ...rest
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant; icon?: ReactNode; loading?: boolean
}) {
  const styles: Record<ButtonVariant, string> = {
    primary: 'ash-btn-primary',
    ghost: 'ash-btn-ghost',
    danger: 'ash-btn-danger',
    subtle: 'ash-btn text-subtext hover:bg-white/5 hover:text-text',
  }
  return (
    <button
      className={cn(styles[variant], className)}
      disabled={disabled || loading}
      aria-busy={loading}
      {...rest}
    >
      {loading
        ? <Spinner size={14} />
        : icon && <span className="text-[15px] leading-none" aria-hidden>{icon}</span>}
      {children}
    </button>
  )
}

export function IconButton({
  label, icon, active = false, className, ...rest
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { label: string; icon: ReactNode; active?: boolean }) {
  return (
    <button
      aria-label={label}
      title={label}
      className={cn(
        'grid h-9 w-9 place-items-center rounded-xl border text-[15px] transition-all duration-200',
        'active:scale-90 hover:-translate-y-px',
        active
          ? 'border-accent/45 bg-accent/15 text-accent shadow-glow'
          : 'border-white/[0.07] bg-white/[0.02] text-subtext hover:border-accent/30 hover:bg-accent/10 hover:text-text',
        className,
      )}
      {...rest}
    >
      {icon}
    </button>
  )
}

export function Input({
  label, hint, error, prefix, className, ...rest
}: React.InputHTMLAttributes<HTMLInputElement> & {
  label?: string; hint?: string; error?: string; prefix?: ReactNode
}) {
  const id = useId()
  return (
    <div className="w-full">
      {label && (
        <label htmlFor={id} className="mb-1.5 block text-[12px] font-medium tracking-wide text-subtext">
          {label}
        </label>
      )}
      <div className="relative flex items-center">
        {prefix && <span className="pointer-events-none absolute left-3 text-subtext/60">{prefix}</span>}
        <input
          id={id}
          aria-invalid={Boolean(error)}
          aria-describedby={error ? `${id}-err` : hint ? `${id}-hint` : undefined}
          className={cn('ash-input', prefix && 'pl-9', error && 'border-rose/60', className)}
          {...rest}
        />
      </div>
      {error
        ? <p id={`${id}-err`} className="mt-1.5 text-[12px] text-rose">{error}</p>
        : hint && <p id={`${id}-hint`} className="mt-1.5 text-[12px] text-subtext/60">{hint}</p>}
    </div>
  )
}

export function Toggle({
  checked, onChange, label, size = 'md',
}: { checked: boolean; onChange: (v: boolean) => void; label?: string; size?: 'sm' | 'md' }) {
  const dims = size === 'sm'
    ? { track: 'h-5 w-9', knob: 'h-3.5 w-3.5', move: 'translate-x-4' }
    : { track: 'h-6 w-11', knob: 'h-4.5 w-4.5', move: 'translate-x-5' }

  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange(!checked)}
      className={cn(
        'relative shrink-0 rounded-full border transition-colors duration-300',
        dims.track,
        checked ? 'border-accent/50 bg-accent/80' : 'border-white/10 bg-white/[0.06]',
      )}
    >
      <span
        className={cn(
          'absolute left-0.5 top-0.5 rounded-full bg-white shadow-sm transition-transform duration-300',
          'motion-reduce:transition-none',
          dims.knob,
          checked && dims.move,
        )}
        style={{ transitionTimingFunction: 'var(--ash-ease-spring)' }}
      />
    </button>
  )
}

export function Slider({
  value, min = 0, max = 100, step = 1, onChange, label, unit = '',
}: {
  value: number; min?: number; max?: number; step?: number
  onChange: (v: number) => void; label?: string; unit?: string
}) {
  const pct = ((value - min) / (max - min)) * 100
  return (
    <div className="w-full">
      {label && (
        <div className="mb-2 flex items-center justify-between text-[12px]">
          <span className="font-medium text-subtext">{label}</span>
          <span className="font-mono text-accent">{value}{unit}</span>
        </div>
      )}
      <input
        type="range"
        min={min} max={max} step={step} value={value}
        aria-label={label}
        onChange={(e) => onChange(Number(e.target.value))}
        className="h-1.5 w-full cursor-pointer appearance-none rounded-full outline-none
                   [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:w-4
                   [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:rounded-full
                   [&::-webkit-slider-thumb]:bg-accent [&::-webkit-slider-thumb]:shadow-glow
                   [&::-webkit-slider-thumb]:transition-transform hover:[&::-webkit-slider-thumb]:scale-125"
        style={{ background: `linear-gradient(90deg, rgb(var(--ash-accent)) ${pct}%, rgb(255 255 255 / .08) ${pct}%)` }}
      />
    </div>
  )
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 3  FEEDBACK: badges, spinners, progress, skeletons
   ═══════════════════════════════════════════════════════════════════════════ */

export type Tone = 'accent' | 'mint' | 'sky' | 'gold' | 'rose' | 'violet' | 'neutral'

const TONE_CLASS: Record<Tone, string> = {
  accent:  'border-accent/30 bg-accent/12 text-accent',
  mint:    'border-mint/30 bg-mint/12 text-mint',
  sky:     'border-sky/30 bg-sky/12 text-sky',
  gold:    'border-gold/30 bg-gold/12 text-gold',
  rose:    'border-rose/30 bg-rose/12 text-rose',
  violet:  'border-violet/30 bg-violet/12 text-violet',
  neutral: 'border-white/10 bg-white/[0.05] text-subtext',
}

export function Badge({
  tone = 'neutral', children, className, dot = false,
}: { tone?: Tone; children: ReactNode; className?: string; dot?: boolean }) {
  return (
    <span className={cn('ash-chip', TONE_CLASS[tone], className)}>
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current" />}
      {children}
    </span>
  )
}

export function Spinner({ size = 18, className }: { size?: number; className?: string }) {
  return (
    <svg
      width={size} height={size} viewBox="0 0 24 24" className={cn('animate-spin', className)}
      role="status" aria-label="Loading"
    >
      <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeOpacity="0.18" strokeWidth="3" />
      <path d="M21 12a9 9 0 0 0-9-9" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
    </svg>
  )
}

export function Progress({
  value, max = 100, tone, showLabel = false, height = 6,
}: { value: number; max?: number; tone?: Tone; showLabel?: boolean; height?: number }) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100))
  // Without an explicit tone the bar warns on its own thresholds, which is
  // what an operator actually wants from a capacity meter.
  const auto: Tone = pct >= 90 ? 'rose' : pct >= 72 ? 'gold' : 'mint'
  const t = tone ?? auto

  const fill: Record<Tone, string> = {
    accent: 'from-accent to-violet', mint: 'from-mint to-sky', sky: 'from-sky to-accent',
    gold: 'from-gold to-rose', rose: 'from-rose to-violet', violet: 'from-violet to-accent',
    neutral: 'from-subtext to-overlay',
  }

  return (
    <div className="w-full">
      <div className="relative w-full overflow-hidden rounded-full bg-white/[0.06]" style={{ height }}>
        <div
          className={cn('h-full origin-left rounded-full bg-gradient-to-r animate-grow', fill[t])}
          style={{ width: `${pct}%` }}
          role="progressbar"
          aria-valuenow={Math.round(pct)}
          aria-valuemin={0}
          aria-valuemax={100}
        />
      </div>
      {showLabel && (
        <div className="mt-1 text-right font-mono text-[11px] text-subtext/70">{pct.toFixed(0)}%</div>
      )}
    </div>
  )
}

export function Skeleton({ className }: { className?: string }) {
  return <div className={cn('ash-skeleton', className)} />
}

export function SkeletonCard() {
  return (
    <div className="ash-panel space-y-3 p-5">
      <Skeleton className="h-4 w-1/3" />
      <Skeleton className="h-3 w-2/3" />
      <Skeleton className="h-24 w-full" />
    </div>
  )
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 4  OVERLAYS: tooltip, modal, drawer
   ═══════════════════════════════════════════════════════════════════════════ */

export function Tooltip({ text, children }: { text: string; children: ReactNode }) {
  return <span className="ash-tip" data-tip={text} tabIndex={0}>{children}</span>
}

/** Locks body scroll and closes on Escape — the two things a modal must do. */
export function Modal({
  open, onClose, title, subtitle, children, footer, width = 'max-w-lg',
}: {
  open: boolean; onClose: () => void; title: string; subtitle?: string
  children: ReactNode; footer?: ReactNode; width?: string
}) {
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    document.addEventListener('keydown', onKey)
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    // Focus the dialog so Escape works before the user clicks anything.
    const t = setTimeout(() => ref.current?.focus(), 30)
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = prev
      clearTimeout(t)
    }
  }, [open, onClose])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
      <div
        className="absolute inset-0 animate-fade-in bg-crust/75 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden
      />
      <div
        ref={ref}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        className={cn(
          'relative z-10 w-full animate-scale-in overflow-hidden rounded-2xl border border-white/10',
          'bg-mantle/95 shadow-lift backdrop-blur-2xl outline-none', width,
        )}
      >
        <div className="flex items-start justify-between gap-4 border-b border-white/[0.06] px-5 py-4">
          <div>
            <h3 className="text-[15px] font-semibold text-text">{title}</h3>
            {subtitle && <p className="mt-0.5 text-[12px] text-subtext/70">{subtitle}</p>}
          </div>
          <IconButton label="Close dialog" icon="✕" onClick={onClose} />
        </div>
        <div className="max-h-[65vh] overflow-y-auto px-5 py-4">{children}</div>
        {footer && (
          <div className="flex items-center justify-end gap-2 border-t border-white/[0.06] px-5 py-3.5">
            {footer}
          </div>
        )}
      </div>
    </div>
  )
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 5  TABS
   ═══════════════════════════════════════════════════════════════════════════ */

export function Tabs<T extends string>({
  tabs, value, onChange, className,
}: {
  tabs: ReadonlyArray<{ id: T; label: string; icon?: string; count?: number }>
  value: T; onChange: (v: T) => void; className?: string
}) {
  return (
    <div
      role="tablist"
      className={cn('no-scrollbar flex gap-1 overflow-x-auto rounded-xl border border-white/[0.06] bg-crust/60 p-1', className)}
    >
      {tabs.map((t) => {
        const active = t.id === value
        return (
          <button
            key={t.id}
            role="tab"
            aria-selected={active}
            onClick={() => onChange(t.id)}
            className={cn(
              'relative flex shrink-0 items-center gap-2 rounded-lg px-3.5 py-2 text-[13px] font-medium',
              'transition-all duration-200 active:scale-[.97]',
              active ? 'bg-accent/15 text-accent shadow-glow' : 'text-subtext hover:bg-white/5 hover:text-text',
            )}
          >
            {t.icon && <span aria-hidden>{t.icon}</span>}
            {t.label}
            {t.count !== undefined && (
              <span className={cn(
                'rounded-full px-1.5 py-px font-mono text-[10px]',
                active ? 'bg-accent/25 text-accent' : 'bg-white/[0.07] text-subtext/70',
              )}>
                {t.count}
              </span>
            )}
          </button>
        )
      })}
    </div>
  )
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 6  CHARTS — hand-rolled SVG so there is no charting dependency to audit
   ═══════════════════════════════════════════════════════════════════════════ */

export function Sparkline({
  data, width = 260, height = 54, tone = 'accent', fill = true, animate = true,
}: {
  data: number[]; width?: number; height?: number; tone?: Tone; fill?: boolean; animate?: boolean
}) {
  const { path, area } = useMemo(() => {
    if (data.length < 2) return { path: '', area: '' }
    const min = Math.min(...data)
    const max = Math.max(...data)
    const span = max - min || 1
    const stepX = width / (data.length - 1)
    // 6% padding keeps the stroke off the clip edge.
    const y = (v: number) => height - ((v - min) / span) * (height * 0.88) - height * 0.06

    let d = ''
    data.forEach((v, i) => {
      const x = i * stepX
      if (i === 0) { d += `M${x.toFixed(2)},${y(v).toFixed(2)}`; return }
      // Catmull-Rom-ish smoothing via midpoint quadratics — cheap and clean.
      const px = (i - 1) * stepX
      const cx = (px + x) / 2
      d += ` Q${cx.toFixed(2)},${y(data[i - 1]!).toFixed(2)} ${x.toFixed(2)},${y(v).toFixed(2)}`
    })
    return { path: d, area: `${d} L${width},${height} L0,${height} Z` }
  }, [data, width, height])

  const stroke: Record<Tone, string> = {
    accent: 'stroke-accent', mint: 'stroke-mint', sky: 'stroke-sky',
    gold: 'stroke-gold', rose: 'stroke-rose', violet: 'stroke-violet', neutral: 'stroke-subtext',
  }
  const gradId = `spark-${tone}`

  if (!path) return <div className="ash-skeleton" style={{ width, height }} />

  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} className="overflow-visible">
      <defs>
        <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" className={stroke[tone]} stopOpacity="0.30" />
          <stop offset="100%" className={stroke[tone]} stopOpacity="0" />
        </linearGradient>
      </defs>
      {fill && <path d={area} fill={`url(#${gradId})`} className="animate-fade-in" />}
      <path
        d={path}
        fill="none"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className={cn(stroke[tone], animate && 'animate-draw-in')}
        style={{ strokeDasharray: 1400, ['--dash' as string]: '1400' }}
        vectorEffect="non-scaling-stroke"
      />
    </svg>
  )
}

export function Donut({
  value, size = 108, thickness = 10, tone = 'accent', label, sublabel,
}: {
  value: number; size?: number; thickness?: number; tone?: Tone
  label?: string; sublabel?: string
}) {
  const r = (size - thickness) / 2
  const circ = 2 * Math.PI * r
  const pct = Math.max(0, Math.min(100, value))
  const toneColor: Record<Tone, string> = {
    accent: 'rgb(var(--ash-accent))', mint: 'rgb(var(--ash-mint))', sky: 'rgb(var(--ash-sky))',
    gold: 'rgb(var(--ash-gold))', rose: 'rgb(var(--ash-rose))', violet: 'rgb(var(--ash-violet))',
    neutral: 'rgb(var(--ash-subtext))',
  }

  return (
    <div className="relative grid place-items-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgb(255 255 255 / .07)" strokeWidth={thickness} />
        <circle
          cx={size / 2} cy={size / 2} r={r} fill="none"
          stroke={toneColor[tone]} strokeWidth={thickness} strokeLinecap="round"
          strokeDasharray={circ}
          strokeDashoffset={circ - (pct / 100) * circ}
          style={{ transition: 'stroke-dashoffset 900ms cubic-bezier(.22,1,.36,1)' }}
        />
      </svg>
      <div className="absolute text-center">
        <div className="font-mono text-lg font-semibold text-text">{label ?? `${pct.toFixed(0)}%`}</div>
        {sublabel && <div className="text-[10px] uppercase tracking-wider text-subtext/60">{sublabel}</div>}
      </div>
    </div>
  )
}

export function BarChart({
  data, height = 120, tone = 'accent', labelEvery = 1,
}: { data: Array<{ label: string; value: number }>; height?: number; tone?: Tone; labelEvery?: number }) {
  const max = Math.max(...data.map((d) => d.value), 1)
  const fill: Record<Tone, string> = {
    accent: 'from-accent/80 to-accent/25', mint: 'from-mint/80 to-mint/25',
    sky: 'from-sky/80 to-sky/25', gold: 'from-gold/80 to-gold/25',
    rose: 'from-rose/80 to-rose/25', violet: 'from-violet/80 to-violet/25',
    neutral: 'from-subtext/70 to-subtext/20',
  }

  return (
    <div className="flex items-end gap-1.5" style={{ height }}>
      {data.map((d, i) => (
        <div key={d.label + i} className="group flex h-full flex-1 flex-col items-center justify-end gap-1.5">
          <span className="font-mono text-[10px] text-subtext/0 transition-colors group-hover:text-subtext">
            {d.value}
          </span>
          <div
            className={cn('w-full origin-bottom animate-grow rounded-t-md bg-gradient-to-t', fill[tone])}
            style={{ height: `${(d.value / max) * 100}%`, animationDelay: `${i * 40}ms` }}
            title={`${d.label}: ${d.value}`}
          />
          {i % labelEvery === 0 && (
            <span className="truncate text-[10px] text-subtext/55">{d.label}</span>
          )}
        </div>
      ))}
    </div>
  )
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 7  TOASTS
   ═══════════════════════════════════════════════════════════════════════════ */

interface Toast {
  id: string
  title: string
  message?: string
  tone: Tone
  emoji?: string
}

interface ToastApi {
  push: (t: Omit<Toast, 'id'>) => void
  success: (title: string, message?: string) => void
  error: (title: string, message?: string) => void
  info: (title: string, message?: string) => void
}

const ToastCtx = createContext<ToastApi | null>(null)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const remove = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  const push = useCallback<ToastApi['push']>((t) => {
    const id = `t${Date.now()}${Math.random().toString(36).slice(2, 6)}`
    setToasts((prev) => [...prev.slice(-4), { ...t, id }])
    setTimeout(() => remove(id), t.tone === 'rose' ? 7000 : 4200)
  }, [remove])

  const api = useMemo<ToastApi>(() => ({
    push,
    success: (title, message) => push({ title, message, tone: 'mint', emoji: '✅' }),
    error: (title, message) => push({ title, message, tone: 'rose', emoji: '⛔' }),
    info: (title, message) => push({ title, message, tone: 'sky', emoji: '💡' }),
  }), [push])

  return (
    <ToastCtx.Provider value={api}>
      {children}
      <div
        className="pointer-events-none fixed bottom-5 right-5 z-[200] flex w-[min(92vw,22rem)] flex-col gap-2.5"
        role="region"
        aria-label="Notifications"
      >
        {toasts.map((t, i) => (
          <div
            key={t.id}
            role="status"
            className={cn(
              'pointer-events-auto flex animate-fade-up items-start gap-3 rounded-xl border px-4 py-3',
              'bg-mantle/95 shadow-lift backdrop-blur-xl',
              TONE_CLASS[t.tone],
            )}
            style={{ animationDelay: `${i * 40}ms` }}
          >
            <span className="text-base leading-none" aria-hidden>{t.emoji ?? 'ℹ️'}</span>
            <div className="min-w-0 flex-1">
              <p className="text-[13px] font-semibold text-text">{t.title}</p>
              {t.message && <p className="mt-0.5 break-words text-[12px] text-subtext/80">{t.message}</p>}
            </div>
            <button
              onClick={() => remove(t.id)}
              aria-label="Dismiss"
              className="text-subtext/50 transition-colors hover:text-text"
            >
              ✕
            </button>
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  )
}

export function useToast(): ToastApi {
  const ctx = useContext(ToastCtx)
  if (!ctx) throw new Error('useToast must be used inside <ToastProvider>')
  return ctx
}

/* ═══════════════════════════════════════════════════════════════════════════
   § 8  KEYBOARD SHORTCUT HOOK
   ═══════════════════════════════════════════════════════════════════════════ */

/** Fires `handler` on ⌘/Ctrl+<key> while the page is mounted. */
export function useHotkey(key: string, handler: (e: KeyboardEvent) => void): void {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === key.toLowerCase()) {
        e.preventDefault()
        handler(e)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [key, handler])
}

/** True while the viewport is at least `px` wide. Used for responsive layout. */
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() =>
    typeof window !== 'undefined' ? window.matchMedia(query).matches : false)

  useEffect(() => {
    const mq = window.matchMedia(query)
    const handler = () => setMatches(mq.matches)
    handler()
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [query])

  return matches
}

export { cn }
