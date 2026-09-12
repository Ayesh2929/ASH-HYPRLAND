/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║  🌐 ASH DOTFILES v5.0 OMEGA — application entrypoint                      ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App'
import './styles/globals.css'
import './styles/themes.css'

const container = document.getElementById('root')
if (!container) throw new Error('#root missing from index.html')

ReactDOM.createRoot(container).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>,
)
