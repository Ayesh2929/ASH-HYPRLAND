import type { Config } from 'tailwindcss'

/**
 * Design tokens are declared as CSS custom properties in styles/globals.css and
 * referenced here, so a theme swap at runtime repaints the whole dashboard
 * without Tailwind needing to recompile.
 */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        base:    'rgb(var(--ash-base) / <alpha-value>)',
        mantle:  'rgb(var(--ash-mantle) / <alpha-value>)',
        crust:   'rgb(var(--ash-crust) / <alpha-value>)',
        surface: 'rgb(var(--ash-surface) / <alpha-value>)',
        overlay: 'rgb(var(--ash-overlay) / <alpha-value>)',
        text:    'rgb(var(--ash-text) / <alpha-value>)',
        subtext: 'rgb(var(--ash-subtext) / <alpha-value>)',
        accent:  'rgb(var(--ash-accent) / <alpha-value>)',
        mint:    'rgb(var(--ash-mint) / <alpha-value>)',
        sky:     'rgb(var(--ash-sky) / <alpha-value>)',
        gold:    'rgb(var(--ash-gold) / <alpha-value>)',
        rose:    'rgb(var(--ash-rose) / <alpha-value>)',
        violet:  'rgb(var(--ash-violet) / <alpha-value>)',
      },
      fontFamily: {
        sans: ['Inter var', 'Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'ui-monospace', 'monospace'],
      },
      borderRadius: { xl: '0.875rem', '2xl': '1.125rem', '3xl': '1.5rem' },
      boxShadow: {
        glow: '0 0 0 1px rgb(var(--ash-accent) / 0.28), 0 8px 32px -8px rgb(var(--ash-accent) / 0.45)',
        panel: '0 1px 0 0 rgb(255 255 255 / 0.04) inset, 0 12px 40px -12px rgb(0 0 0 / 0.65)',
        lift: '0 20px 60px -20px rgb(0 0 0 / 0.8)',
      },
      keyframes: {
        'fade-up':   { from: { opacity: '0', transform: 'translateY(10px)' }, to: { opacity: '1', transform: 'none' } },
        'fade-in':   { from: { opacity: '0' }, to: { opacity: '1' } },
        'scale-in':  { from: { opacity: '0', transform: 'scale(.95)' }, to: { opacity: '1', transform: 'none' } },
        'slide-in':  { from: { transform: 'translateX(-100%)' }, to: { transform: 'translateX(0)' } },
        shimmer:     { '100%': { transform: 'translateX(100%)' } },
        aurora: {
          '0%,100%': { transform: 'translate3d(0,0,0) scale(1)' },
          '33%':     { transform: 'translate3d(4%,-6%,0) scale(1.12)' },
          '66%':     { transform: 'translate3d(-5%,4%,0) scale(1.06)' },
        },
        float:       { '0%,100%': { transform: 'translateY(0)' }, '50%': { transform: 'translateY(-6px)' } },
        'pulse-ring': {
          '0%':   { transform: 'scale(.8)', opacity: '0.7' },
          '100%': { transform: 'scale(2.2)', opacity: '0' },
        },
        'spin-slow': { to: { transform: 'rotate(360deg)' } },
        'draw-in':   { from: { strokeDashoffset: 'var(--dash, 1000)' }, to: { strokeDashoffset: '0' } },
        grow:        { from: { transform: 'scaleX(0)' }, to: { transform: 'scaleX(1)' } },
      },
      animation: {
        'fade-up':   'fade-up .45s cubic-bezier(.22,1,.36,1) both',
        'fade-in':   'fade-in .30s ease both',
        'scale-in':  'scale-in .25s cubic-bezier(.22,1,.36,1) both',
        'slide-in':  'slide-in .35s cubic-bezier(.22,1,.36,1) both',
        shimmer:     'shimmer 1.6s infinite',
        aurora:      'aurora 22s ease-in-out infinite',
        float:       'float 5s ease-in-out infinite',
        'pulse-ring':'pulse-ring 2.4s ease-out infinite',
        'spin-slow': 'spin-slow 14s linear infinite',
        'draw-in':   'draw-in 1.2s cubic-bezier(.22,1,.36,1) both',
        grow:        'grow .9s cubic-bezier(.22,1,.36,1) both',
      },
      transitionTimingFunction: { swift: 'cubic-bezier(.22,1,.36,1)' },
    },
  },
  plugins: [],
} satisfies Config
