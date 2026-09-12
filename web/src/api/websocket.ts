/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — websocket transport
 * ═══════════════════════════════════════════════════════════════════════════
 *  Re-exported from the client so a future dedicated socket layer (binary
 *  frames, compression) can land here without touching call sites.
 */
export { connectLive, isOffline, onConnectivityChange, type LiveClient } from './client'
