import React from 'react';
import { createRoot } from 'react-dom/client';

const Popup: React.FC = () => {
  return (
    <div style={{ width: 320, padding: 12 }}>
      <h2>ASH</h2>
      <p>Theme companion — sync with dashboard at localhost:8787</p>
      <button onClick={() => chrome.tabs.create({ url: 'http://localhost:8787' })}>Open Dashboard</button>
    </div>
  );
};
const el = document.getElementById('root');
if (el) createRoot(el).render(<Popup />);
export default Popup;
