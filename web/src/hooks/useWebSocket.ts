/**
 * ═══════════════════════════════════════════════════════════════════════════
 *  🌐 ASH OMEGA — live socket hook
 * ═══════════════════════════════════════════════════════════════════════════
 *  Manages one socket for the lifetime of the component and exposes the most
 *  recent frame per message type.
 */
import { useEffect, useRef, useState } from 'react'
import { connectLive, type LiveClient } from '../api/client'
import type { WSMessage } from '../lib/types'

export function useWebSocket(enabled = true) {
  const [last, setLast] = useState<WSMessage | null>(null)
  const [connected, setConnected] = useState(false)
  const clientRef = useRef<LiveClient | null>(null)

  useEffect(() => {
    if (!enabled) return
    const client = connectLive((msg) => {
      setLast(msg)
      setConnected(true)
    })
    clientRef.current = client
    return () => {
      client.close()
      clientRef.current = null
      setConnected(false)
    }
  }, [enabled])

  return {
    last,
    connected,
    send: (m: unknown) => clientRef.current?.send(m),
  }
}
