import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { fileURLToPath, URL } from 'node:url'

/**
 * The dashboard is served inside a sandboxed preview iframe, so HMR has to
 * reach a host that is not localhost. `allowedHosts: true` keeps Vite from
 * rejecting those proxied requests (Vite 5.4+ validates the Host header),
 * and binding to 0.0.0.0 makes the port reachable from outside the container.
 */
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: false,
    allowedHosts: true,
    // The REST API normally lives on 8787. Proxying keeps every browser
    // request same-origin, which sidesteps CORS entirely.
    proxy: {
      '/api': {
        target: process.env.ASH_API_URL ?? 'http://127.0.0.1:8787',
        changeOrigin: true,
        ws: true,
      },
    },
  },
  preview: { host: '0.0.0.0', port: 4173, allowedHosts: true },
  build: {
    target: 'es2022',
    sourcemap: false,
    chunkSizeWarningLimit: 900,
    rollupOptions: {
      output: {
        manualChunks: {
          react: ['react', 'react-dom', 'react-router-dom'],
        },
      },
    },
  },
})
